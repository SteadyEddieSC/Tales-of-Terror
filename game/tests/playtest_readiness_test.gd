extends SceneTree

const MAIN_SCRIPT: Script = preload("res://src/main/main.gd")
const PRIVATE_MARKERS: PackedStringArray = [
	"planted_role_secret",
	"planted_faction_secret",
	"planted_objective_secret",
	"planted_prompt_choice",
	"planted_join_code",
	"planted_client_id",
	"192.0.2.44",
	"private-machine-name",
	"C:/private/repository/path",
]

var _failures: int = 0


func _initialize() -> void:
	_test_guidance_every_lifecycle()
	_test_help_is_non_authoritative()
	_test_recovery_guidance_and_stable_seats()
	_test_protected_reset_from_observed_states()
	_test_report_schema_privacy_bounds_and_order()
	_test_export_seam_and_finalization()
	_test_observation_invariance_and_no_phone_route()
	_test_optional_companion_observation_is_non_authoritative()
	_test_reporting_source_has_no_network_path()
	if _failures == 0:
		print("Playtest readiness tests passed")
	quit(_failures)


func _test_guidance_every_lifecycle() -> void:
	var coordinator := VerticalSliceCoordinator.new()
	var states: PackedStringArray = [
		"boot_title", "lobby", "confirmation", "briefing", "active_tale", "terminal", "ending"
	]
	for lifecycle: String in states:
		var state: Dictionary = coordinator.public_state()
		state.lifecycle = lifecycle
		if lifecycle == "active_tale":
			state.stage = {"id": "threshold", "title": "The Threshold", "operations": []}
		var guidance: String = GuidedSessionHelp.guidance_for_state(state, [])
		_expect(not guidance.is_empty(), "guides the %s lifecycle" % lifecycle)
	var confirmation: Dictionary = coordinator.public_state()
	confirmation.lifecycle = "confirmation"
	var confirmation_help: Dictionary = GuidedSessionHelp.page_content(
		1, confirmation, [], {}, false
	)
	_expect(
		"B / Esc returns to lobby" in confirmation_help.body,
		"describes the coherent confirmation recovery route",
	)
	var ending: Dictionary = coordinator.public_state()
	ending.lifecycle = "ending"
	_expect(
		"Export" in GuidedSessionHelp.guidance_for_state(ending, []),
		"guides ending export and rematch choices",
	)


func _test_help_is_non_authoritative() -> void:
	var coordinator := _initialized_coordinator(3, 4706)
	var before: Dictionary = coordinator.to_snapshot()
	var authority_before: String = coordinator.authority_digest()
	var history_before: String = coordinator.public_history_digest()
	var help := GuidedSessionHelp.new()
	help._ready()
	help.open_help(coordinator.public_state(), coordinator.seat_manager.get_seats(), {}, false)
	_expect(
		help.visible and help.page_index() == 0, "opens controller help without authority access"
	)
	help.handle_action("ui_navigate_right")
	help.handle_action("ui_navigate_left")
	help.handle_action("help_accessibility")
	_expect(not help.visible, "closes help through the same controller action")
	_expect(
		coordinator.to_snapshot() == before,
		"keeps every authority and checkpoint byte-equivalent across help",
	)
	_expect(
		(
			coordinator.authority_digest() == authority_before
			and coordinator.public_history_digest() == history_before
		),
		"keeps deterministic digests unchanged across help",
	)
	var prompt_wait: Dictionary = coordinator.advance_player_stage()
	_expect(prompt_wait.get("waiting_for_players", false), "opens a retained prompt wait")
	before = coordinator.to_snapshot()
	help.open_help(coordinator.public_state(), coordinator.seat_manager.get_seats(), {}, false)
	help.close_help()
	_expect(coordinator.to_snapshot() == before, "keeps a prompt wait unchanged across help")
	_complete_stage_prompt(coordinator)
	var vote_wait: Dictionary = coordinator.advance_player_stage()
	_expect(vote_wait.get("waiting_for_players", false), "opens a retained vote wait")
	before = coordinator.to_snapshot()
	help.open_help(coordinator.public_state(), coordinator.seat_manager.get_seats(), {}, false)
	help.close_help()
	_expect(coordinator.to_snapshot() == before, "keeps a vote wait unchanged across help")
	help.free()


func _test_recovery_guidance_and_stable_seats() -> void:
	var coordinator := _initialized_coordinator(2, 8111)
	var seats: SeatManager = coordinator.seat_manager
	var identity: String = seats.get_seats()[0].identity
	var previous_device: int = seats.get_seats()[0].device_id
	_expect(seats.disconnect_device(previous_device) == 0, "reserves a disconnected stable seat")
	var disconnected: String = GuidedSessionHelp.guidance_for_state(
		coordinator.public_state(), seats.get_seats()
	)
	_expect("reserved for reconnect" in disconnected, "identifies disconnect recovery publicly")
	_expect(
		seats.reconnect_device(previous_device, identity, "Reconnected Fixture Pad") == 0,
		"reconnects only to the same stable seat ownership",
	)
	_expect(seats.get_seats()[0].state == SeatManager.SeatState.ACTIVE, "restores active ownership")
	var privacy_page: Dictionary = (
		GuidedSessionHelp
		. page_content(
			2,
			coordinator.public_state(),
			seats.get_seats(),
			{"room_open": true, "connected_count": 1},
			false,
		)
	)
	_expect(
		"NO PHONE REQUIRED" in privacy_page.body and "non-authoritative" in privacy_page.body,
		"explains controlled reveal and optional companion boundaries",
	)


func _test_protected_reset_from_observed_states() -> void:
	var labels: PackedStringArray = ["help", "pause", "prompt", "vote", "developer_lab"]
	for label: String in labels:
		var coordinator := _initialized_coordinator(3, 9000 + labels.find(label))
		var help := GuidedSessionHelp.new()
		help._ready()
		if label == "help":
			help.open_help(
				coordinator.public_state(), coordinator.seat_manager.get_seats(), {}, false
			)
		elif label == "pause":
			coordinator.toggle_pause()
		elif label == "prompt":
			coordinator.advance_player_stage()
		elif label == "vote":
			coordinator.run_current_stage()
			coordinator.advance_player_stage()
		var old_bridge: CompanionBridge = coordinator.companion_bridge
		old_bridge.create_room("reset_fixture", "RSET3")
		coordinator.protected_reset_to_title()
		help.close_help()
		_expect(_is_clean_title(coordinator), "resets cleanly from %s presentation" % label)
		_expect(not old_bridge.room_open, "closes the old room during %s reset" % label)
		coordinator.seat_manager.join_device(7, "fresh-%s" % label, "Fresh Fixture Pad")
		_expect(coordinator.enter_lobby().accepted, "allows a fresh join after %s reset" % label)
		help.free()


func _test_report_schema_privacy_bounds_and_order() -> void:
	var state: Dictionary = _public_fixture()
	state["role"] = {"id": PRIVATE_MARKERS[0]}
	state["faction"] = PRIVATE_MARKERS[1]
	state["objective"] = PRIVATE_MARKERS[2]
	state.rules.prompt["responses"] = {1: [PRIVATE_MARKERS[3]]}
	state["companion"] = {
		"join_code": PRIVATE_MARKERS[4],
		"client_id": PRIVATE_MARKERS[5],
		"ip": PRIVATE_MARKERS[6],
	}
	state["machine"] = PRIVATE_MARKERS[7]
	state["path"] = PRIVATE_MARKERS[8]
	var report := PlaytestReport.new()
	var title_state: Dictionary = state.duplicate(true)
	title_state.scenario_version = 0
	report.begin(title_state, 4706, "2026-07-20T20:00:00Z", 0)
	var seats: Array[Dictionary] = [_seat(1, SeatManager.SeatState.ACTIVE, -1)]
	report.observe(state, seats, {"connected_count": 1}, 1)
	for index: int in 80:
		report.record_rejection("invalid_input_%d" % index, index + 2)
	report.finalize("ending", state, "2026-07-20T20:20:00Z", 1200, "a".repeat(64), "b".repeat(64))
	var value: Dictionary = report.to_report()
	_expect(PlaytestReport.validate_schema(value).accepted, "produces the exact version-2 schema")
	_expect(value.scenario.version == 1, "records the initialized exact scenario version")
	_expect(value.rejections.size() == PlaytestReport.MAX_REJECTIONS, "bounds rejection events")
	var ordered: bool = true
	for key: String in [
		"lifecycle_events", "seat_events", "recovery_events", "wait_progress", "rejections"
	]:
		var sequence: int = 0
		for event: Dictionary in value[key]:
			ordered = ordered and event.sequence > sequence
			sequence = event.sequence
	_expect(ordered, "retains deterministic report event ordering")
	var serialized: String = report.to_json()
	for marker: String in PRIVATE_MARKERS:
		_expect(not marker in serialized, "filters planted private value %s" % marker)
	var malformed: Dictionary = value.duplicate(true)
	malformed["private_role"] = "forbidden"
	_expect(not PlaytestReport.validate_schema(malformed).accepted, "rejects unknown report keys")


func _test_export_seam_and_finalization() -> void:
	for completion_reason: String in PlaytestReport.COMPLETION_REASONS:
		var report := _finalized_report(completion_reason)
		_expect(report.is_finalized(), "finalizes a report for %s" % completion_reason)
		_expect(
			report.to_report().session.completion_reason == completion_reason,
			"records %s completion" % completion_reason,
		)
	var reset_report := _finalized_report("reset")
	_expect(
		reset_report.to_report().session.post_ending_disposition == "not_applicable",
		"keeps pre-ending reset separate from post-ending disposition",
	)
	_expect(
		not reset_report.record_post_ending_disposition("rematch").accepted,
		"rejects disposition updates when the tale did not reach ending",
	)
	for disposition: String in ["rematch", "return_to_title", "reset"]:
		var disposed := _finalized_report("ending")
		_expect(
			disposed.record_post_ending_disposition(disposition).accepted,
			"records bounded %s disposition" % disposition,
		)
		_expect(
			disposed.to_report().session.post_ending_disposition == disposition,
			"retains exact %s disposition" % disposition,
		)
		_expect(
			not disposed.record_post_ending_disposition("reset").accepted,
			"never silently overwrites an existing disposition",
		)
	var exported := _finalized_report("ending")
	var writer := PlaytestMemoryWriter.new()
	var success: Dictionary = exported.export_with(writer, "fixture_report")
	_expect(success.accepted, "exports explicitly through the replaceable writer seam")
	_expect(
		JSON.parse_string(writer.json_text) is Dictionary,
		"exports machine-readable versioned JSON",
	)
	_expect(
		(
			"Authority digest" in writer.markdown_text
			and exported.to_report().outcome.authority_digest in writer.markdown_text
		),
		"keeps JSON and Markdown outcome evidence consistent",
	)
	var fixture_json: Variant = JSON.parse_string(
		FileAccess.get_file_as_string("res://tests/fixtures/playtest_report_v2.json")
	)
	var fixture_markdown: String = FileAccess.get_file_as_string(
		"res://tests/fixtures/playtest_report_v2.md"
	)
	_expect(
		fixture_json == JSON.parse_string(exported.to_json()),
		"keeps the committed JSON export fixture current",
	)
	_expect(fixture_markdown == exported.to_markdown(), "keeps the Markdown export fixture current")
	writer.fail_writes = true
	_expect(
		not exported.export_with(writer, "fixture_failure").accepted,
		"reports an explicit writer failure without gameplay mutation",
	)
	var local_writer := LocalPlaytestReportWriter.new()
	var local_result: Dictionary = exported.export_with(local_writer, "automated_fixture_report")
	_expect(local_result.accepted, "writes explicitly to the approved local user-data folder")
	_expect(
		not exported.export_with(local_writer, "automated_fixture_report").accepted,
		"rejects an existing export basename instead of silently overwriting it",
	)
	_expect(
		not exported.export_with(local_writer, "../arbitrary_path").accepted,
		"rejects arbitrary or traversing export paths",
	)
	if local_result.accepted:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(local_result.json_path))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(local_result.markdown_path))
	var local_source: String = FileAccess.get_file_as_string(
		"res://src/playtest/local_playtest_report_writer.gd"
	)
	_expect(
		"user://playtest_exports" in local_source and "absolute_path" not in local_source,
		"pins production export to the intentional user-data folder",
	)


func _test_observation_invariance_and_no_phone_route() -> void:
	var baseline := _initialized_coordinator(4, 12031)
	var observed := _initialized_coordinator(4, 12031)
	var report := PlaytestReport.new()
	report.begin(observed.public_state(), observed.seed, "2026-07-20T20:00:00Z", 0)
	var step: int = 0
	while baseline.lifecycle == "active_tale":
		_expect(baseline.run_current_stage().accepted, "advances baseline no-phone stage")
		_expect(observed.run_current_stage().accepted, "advances observed no-phone stage")
		step += 1
		report.observe(observed.public_state(), observed.seat_manager.get_seats(), {}, step)
	_expect(
		baseline.authority_digest() == observed.authority_digest(),
		"keeps authority digest identical with observation enabled",
	)
	_expect(
		baseline.public_history_digest() == observed.public_history_digest(),
		"keeps public outcome and history identical with observation enabled",
	)
	print(
		(
			"PLAYTEST_INVARIANCE seed=12031 authority=%s public_history=%s"
			% [observed.authority_digest(), observed.public_history_digest()]
		)
	)
	_expect(observed.review_ending().accepted, "completes the normal route without a phone")
	(
		report
		. finalize(
			"ending",
			observed.public_state(),
			"2026-07-20T20:20:00Z",
			1200,
			observed.authority_digest(),
			observed.public_history_digest(),
		)
	)
	_expect(
		not report.to_report().session.companion_used, "records complete no-phone play honestly"
	)


func _test_optional_companion_observation_is_non_authoritative() -> void:
	var coordinator := _initialized_coordinator(3, 12032)
	var bridge: CompanionBridge = coordinator.companion_bridge
	bridge.create_room("observation_fixture", "BSTR3")
	var before: Dictionary = bridge.diagnostics()
	var authority_before: String = coordinator.authority_digest()
	var report := PlaytestReport.new()
	report.begin(coordinator.public_state(), coordinator.seed, "2026-07-20T20:00:00Z", 0)
	(
		report
		. observe(
			coordinator.public_state(),
			[],
			{"room_open": true, "connected_count": 1},
			1,
		)
	)
	_expect(bridge.diagnostics() == before, "does not mutate optional companion authority")
	_expect(
		coordinator.authority_digest() == authority_before,
		"keeps native gameplay authority unchanged while observing companion status",
	)
	_expect(report.to_report().session.companion_used, "records only aggregate companion use")


func _test_reporting_source_has_no_network_path() -> void:
	var combined: String = ""
	for path: String in [
		"res://src/playtest/playtest_report.gd",
		"res://src/playtest/playtest_report_writer.gd",
		"res://src/playtest/local_playtest_report_writer.gd",
	]:
		combined += FileAccess.get_file_as_string(path)
	for forbidden: String in [
		"HTTPClient", "HTTPRequest", "WebSocketPeer", "PacketPeerUDP", "StreamPeerTCP"
	]:
		_expect(not forbidden in combined, "keeps reporting free of %s" % forbidden)


func _public_fixture() -> Dictionary:
	return {
		"scenario_id": "lantern_house_vertical_slice",
		"scenario_version": 1,
		"lifecycle": "active_tale",
		"stage_index": 0,
		"operation_index": 3,
		"stage":
		{
			"id": "threshold",
			"title": "The Threshold",
			"operations":
			[
				{"type": "queue_event"},
				{"type": "resolve_event"},
				{"type": "submit_prompt"},
				{"type": "resolve_prompt"},
			],
		},
		"seat_count": 1,
		"mode": "cooperative",
		"fallback_applied": true,
		"public_objective": "Secure the Lantern House before it closes around you.",
		"rules":
		{
			"prompt":
			{
				"response_status": [{"seat": 1, "submitted": false}],
			}
		},
		"ending": {"terminal_reason": "lantern_house_secured"},
		"paused": false,
	}


func _seat(number: int, state: int, device_id: int) -> Dictionary:
	return {
		"seat_number": number,
		"state": state,
		"input_kind": "keyboard" if device_id == SeatManager.KEYBOARD_DEVICE_ID else "controller",
	}


func _finalized_report(reason: String) -> PlaytestReport:
	var state: Dictionary = _public_fixture()
	var report := PlaytestReport.new()
	report.begin(state, 4706, "2026-07-20T20:00:00Z", 0)
	report.finalize(reason, state, "2026-07-20T20:20:00Z", 1200, "a".repeat(64), "b".repeat(64))
	return report


func _initialized_coordinator(seat_count: int, seed: int) -> VerticalSliceCoordinator:
	var coordinator := VerticalSliceCoordinator.new()
	for index: int in seat_count:
		coordinator.seat_manager.join_device(index, "fixture-pad-%d" % index, "Fixture Pad")
	coordinator.enter_lobby()
	coordinator.confirm_roster()
	coordinator.initialize_session(seed)
	coordinator.begin_tale()
	return coordinator


func _complete_stage_prompt(coordinator: VerticalSliceCoordinator) -> void:
	var prompt: Dictionary = coordinator.rules_session.pending_prompt
	for seat_number: int in prompt.eligible_seats:
		coordinator.rules_session.submit_response(seat_number, ["force"], prompt.revision)
	coordinator.advance_player_stage()


func _is_clean_title(coordinator: VerticalSliceCoordinator) -> bool:
	return (
		coordinator.lifecycle == "boot_title"
		and coordinator.active_seats().is_empty()
		and coordinator.manifest.is_empty()
		and coordinator.board_state == null
		and coordinator.rules_session == null
		and coordinator.director_runtime == null
		and coordinator.role_session == null
		and coordinator.companion_bridge == null
		and coordinator.to_snapshot().stage_transaction.is_empty()
	)


func _expect(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		_failures += 1
		push_error("FAIL: " + description)
