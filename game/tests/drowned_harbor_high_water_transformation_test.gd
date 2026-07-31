extends SceneTree

const ADAPTER_SCRIPT: Script = preload(
	"res://tests/drowned_harbor_dev_only/high_water_fixture_adapter.gd"
)
const SHELL_SCRIPT: Script = preload(
	"res://tests/drowned_harbor_dev_only/high_water_transformation_shell.gd"
)
const FIXTURE_PATH: String = "res://tests/drowned_harbor_dev_only/state_projection_fixtures_v1.json"
const SCENE_PATH: String = (
	"res://tests/drowned_harbor_dev_only/" + "high_water_transformation_shell.tscn"
)
const PRIVATE_MARKER: String = "PRIVATE_"
const UID_CASES: Array[Dictionary] = [
	{
		"uid_path": "res://tests/drowned_harbor_dev_only/high_water_fixture_adapter.gd.uid",
		"resource_path": "res://tests/drowned_harbor_dev_only/high_water_fixture_adapter.gd",
	},
	{
		"uid_path": "res://tests/drowned_harbor_dev_only/high_water_transformation_shell.gd.uid",
		"resource_path": "res://tests/drowned_harbor_dev_only/high_water_transformation_shell.gd",
	},
	{
		"uid_path": "res://tests/drowned_harbor_high_water_transformation_test.gd.uid",
		"resource_path": "res://tests/drowned_harbor_high_water_transformation_test.gd",
	},
]

var _failures: int = 0


func _initialize() -> void:
	_test_canonical_uid_sidecars_round_trip_and_remain_test_only()
	_test_exact_fixture_load_and_identity()
	_test_complete_full_and_skip_are_byte_equivalent()
	_test_exactly_once_event_and_duplicate_reprojection()
	_test_duplicate_skip_acknowledgement_replay_and_recovery()
	_test_request_rejections_fail_closed()
	_test_precommit_projection_failure_and_recovery()
	_test_postcommit_projection_failure_reprojects_existing_result()
	_test_caption_interruptions_preserve_commit_boundary()
	_test_transcript_and_replay_unavailability_preserve_board()
	_test_replay_of_committed_summary_is_read_only()
	_test_persistent_summary_precedes_focus_return()
	_test_transformed_board_is_read_only_and_multichannel()
	_test_stable_seat_form_revision_rng_and_authority_invariance()
	_test_private_markers_never_enter_public_channels()
	_test_no_duplicate_outputs_or_signals()
	_test_repeated_projection_and_second_shell_are_deterministic()
	_test_gameplay_and_unsupported_inputs_fail_closed()
	_test_existing_semantic_input_mappings()
	_test_scene_is_export_excluded_and_instantiable()
	if _failures == 0:
		print("Drowned Harbor High Water deterministic transformation tests passed")
	quit(_failures)


func _test_canonical_uid_sidecars_round_trip_and_remain_test_only() -> void:
	var textual_uids: Dictionary = {}
	var numeric_uids: Dictionary = {}
	for uid_case: Dictionary in UID_CASES:
		var uid_path: String = uid_case.get("uid_path", "")
		var resource_path: String = uid_case.get("resource_path", "")
		var uid_text: String = FileAccess.get_file_as_string(uid_path).strip_edges()
		_expect(not uid_text.is_empty(), "%s contains one UID" % uid_path)
		var numeric_uid: int = ResourceUID.text_to_id(uid_text)
		_expect(numeric_uid != ResourceUID.INVALID_ID, "%s parses to a valid UID" % uid_path)
		_expect(
			ResourceUID.id_to_text(numeric_uid) == uid_text,
			"%s round-trips through Godot ResourceUID" % uid_path,
		)
		_expect(not textual_uids.has(uid_text), "%s textual UID is distinct" % uid_path)
		_expect(not numeric_uids.has(numeric_uid), "%s numeric UID is distinct" % uid_path)
		textual_uids[uid_text] = true
		numeric_uids[numeric_uid] = true
		var script_resource: Script = load(resource_path)
		_expect(script_resource != null, "%s associated script loads" % resource_path)
		_expect(
			ResourceUID.get_id_path(numeric_uid) == resource_path,
			"%s UID is registered only to its intended test script" % uid_path,
		)
	_expect(textual_uids.size() == 3, "three canonical textual UIDs are unique")
	_expect(numeric_uids.size() == 3, "three canonical numeric UIDs are unique")
	var packed: PackedScene = load(SCENE_PATH)
	_expect(packed != null, "canonical UID correction preserves High Water scene loading")
	if packed != null:
		var instance: Node = packed.instantiate()
		_expect(
			instance is DrownedHarborHighWaterTransformationShell,
			"canonical UID correction preserves the intended test-only shell",
		)
		instance.free()


func _test_exact_fixture_load_and_identity() -> void:
	var package: Dictionary = _read_json(FIXTURE_PATH)
	var fixture: Dictionary = _fixture(package, "DH-FIX-004")
	_expect(package.get("fixtures", []).size() == 7, "fixture inventory remains seven entries")
	_expect(fixture.get("trace_id") == "DH-IS-008", "DH-FIX-004 binds DH-IS-008")
	_expect(fixture.get("storyboard_id") == "DH-UI-008", "DH-FIX-004 binds DH-UI-008")
	_expect(
		fixture.get("fixture_kind") == "once_only_public_transform_projection",
		"DH-FIX-004 retains its fixture kind",
	)
	_expect(fixture.get("seed") == 6108, "DH-FIX-004 seed remains 6108")
	_expect(fixture.get("source_revision") == 41, "source revision remains 41")
	_expect(fixture.get("result_revision") == 42, "result revision remains 42")
	_expect(fixture.get("rng_cursor_before") == 12, "RNG cursor begins at 12")
	_expect(fixture.get("rng_cursor_after") == 12, "RNG cursor ends at 12")
	_expect(
		(
			fixture.get("source_state", {}).get("public", {}).get("council_direction")
			== "synthetic_council_direction_fixture_004"
		),
		"bounded Council direction is plainly synthetic",
	)
	_expect(
		PRIVATE_MARKER in JSON.stringify(fixture.get("source_state", {}).get("private", {})),
		"private fixture sentinels remain present for leak regression",
	)
	var adapter: DrownedHarborHighWaterFixtureAdapter = ADAPTER_SCRIPT.new()
	var loaded: Dictionary = adapter.load_and_prepare(adapter.authorized_request())
	_expect(loaded.get("accepted", false), "exact DH-FIX-004 loads and prepares")
	var signature: Dictionary = adapter.state_signature()
	_expect(signature.get("fixture_id") == "DH-FIX-004", "adapter identity is exact")
	_expect(signature.get("stable_seat_id") == "seat_04", "adapter retains seat_04")
	_expect(signature.get("rng_cursor") == 12, "adapter consumes no RNG")
	_expect(
		loaded.get("prepared", {}).get("event_identity", "").length() == 64,
		"event identity is a deterministic SHA-256 digest",
	)


func _test_complete_full_and_skip_are_byte_equivalent() -> void:
	var full: DrownedHarborHighWaterTransformationShell = _new_shell()
	var skipped: DrownedHarborHighWaterTransformationShell = _new_shell()
	var full_result: Dictionary = full.run_full_presentation()
	var skip_result: Dictionary = skipped.skip_presentation()
	_expect(full_result.get("accepted", false), "full placeholder presentation completes")
	_expect(skip_result.get("accepted", false), "semantic skip presentation completes")
	_expect(
		full._equivalence_bytes() == skipped._equivalence_bytes(),
		"full and skipped paths produce byte-equivalent governed output",
	)
	var full_snapshot: Dictionary = full._equivalence_snapshot()
	var skip_snapshot: Dictionary = skipped._equivalence_snapshot()
	for field: String in [
		"authoritative_state",
		"result_revision",
		"event_identity",
		"event_payload",
		"public_history",
		"transformed_board_projection",
		"changed_categories",
		"caption",
		"transcript",
		"replay_summary",
		"mirrored_output",
		"stable_seat_positions",
		"public_form_state",
		"legal_inspection_actions",
		"persistent_summary",
	]:
		_expect(
			(
				JSON.stringify(full_snapshot.get(field), "", true)
				== JSON.stringify(skip_snapshot.get(field), "", true)
			),
			"full and skip %s bytes match" % field,
		)
	full.free()
	skipped.free()


func _test_exactly_once_event_and_duplicate_reprojection() -> void:
	var shell: DrownedHarborHighWaterTransformationShell = _new_shell()
	var emitted: Array[Dictionary] = []
	shell.prototype_high_water_event_emitted.connect(
		func(payload: Dictionary) -> void: emitted.append(payload)
	)
	shell.run_full_presentation()
	var initial_bytes: String = shell._equivalence_bytes()
	var evidence: Dictionary = shell._evidence_snapshot()
	_expect(evidence.get("commit_count") == 1, "authoritative transformation commits once")
	_expect(evidence.get("event_count") == 1, "one public event is recorded")
	_expect(evidence.get("signal_count") == 1, "one public signal is emitted")
	_expect(emitted.size() == 1, "signal observer receives one event")
	_expect(
		emitted[0].get("event_key") == "high_water_transformation_committed",
		"governed event key is emitted",
	)
	var duplicate: Dictionary = shell.submit_transformation_request(
		DrownedHarborHighWaterFixtureAdapter.authorized_request()
	)
	_expect(duplicate.get("accepted", false), "duplicate request reprojects existing result")
	_expect(duplicate.get("reprojected", false), "duplicate is identified as reprojection")
	_expect(
		shell._equivalence_bytes() == initial_bytes, "duplicate reprojection preserves result bytes"
	)
	evidence = shell._evidence_snapshot()
	_expect(evidence.get("commit_count") == 1, "duplicate creates no second commit")
	_expect(evidence.get("event_count") == 1, "duplicate creates no second public event")
	_expect(emitted.size() == 1, "duplicate emits no second signal")
	shell.free()


func _test_duplicate_skip_acknowledgement_replay_and_recovery() -> void:
	var shell: DrownedHarborHighWaterTransformationShell = _new_shell()
	shell.skip_presentation()
	var before: String = JSON.stringify(shell._evidence_snapshot(), "", true)
	var skipped_again: Dictionary = shell.skip_presentation()
	_expect(skipped_again.get("accepted", false), "repeated skip is idempotent")
	_expect(skipped_again.get("reprojected", false), "repeated skip is presentation replay")
	var acknowledged: Dictionary = shell.acknowledge_persistent_summary()
	_expect(acknowledged.get("accepted", false), "persistent recap acknowledgement succeeds")
	var evidence_after_ack: Dictionary = shell._evidence_snapshot()
	var acknowledged_again: Dictionary = shell.acknowledge_persistent_summary()
	_expect(acknowledged_again.get("accepted", false), "repeated acknowledgement is idempotent")
	_expect(acknowledged_again.get("reprojected", false), "repeated acknowledgement reprojects")
	var replay_first: Dictionary = shell.replay_committed_summary()
	var replay_second: Dictionary = shell.replay_committed_summary()
	_expect(replay_first.get("accepted", false), "first replay reads committed summary")
	_expect(replay_second.get("accepted", false), "repeated replay reads same summary")
	shell.recover_projection()
	shell.recover_projection()
	var final_evidence: Dictionary = shell._evidence_snapshot()
	for field: String in [
		"commit_count",
		"event_count",
		"history_count",
		"mirror_count",
		"replay_count",
		"signal_count",
		"transcript_count",
	]:
		_expect(
			final_evidence.get(field) == evidence_after_ack.get(field),
			"repeated controls do not duplicate %s" % field,
		)
	_expect(not before.is_empty(), "pre-acknowledgement evidence was captured")
	shell.free()


func _test_request_rejections_fail_closed() -> void:
	var baseline_shell: DrownedHarborHighWaterTransformationShell = _new_shell()
	var baseline: String = baseline_shell._prepared_result_bytes()
	var request: Dictionary = DrownedHarborHighWaterFixtureAdapter.authorized_request()
	var cases: Array[Dictionary] = []
	var stale: Dictionary = request.duplicate(true)
	stale["source_revision"] = 40
	cases.append({"code": "stale_source_revision", "request": stale})
	var actor: Dictionary = request.duplicate(true)
	actor["actor_kind"] = "active_stable_seat"
	cases.append({"code": "unauthorized_actor", "request": actor})
	var seat: Dictionary = request.duplicate(true)
	seat["stable_seat_id"] = "seat_99"
	cases.append({"code": "wrong_stable_seat", "request": seat})
	var fixture: Dictionary = request.duplicate(true)
	fixture["fixture_id"] = "DH-FIX-005"
	cases.append({"code": "wrong_fixture", "request": fixture})
	var intent: Dictionary = request.duplicate(true)
	intent["intent"] = "commit_high_water_gameplay"
	cases.append({"code": "unauthorized_intent", "request": intent})
	var missing: Dictionary = request.duplicate(true)
	missing.erase("intent")
	cases.append({"code": "malformed_transform_request", "request": missing})
	var extra: Dictionary = request.duplicate(true)
	extra["unexpected"] = true
	cases.append({"code": "malformed_transform_request", "request": extra})
	for case: Dictionary in cases:
		var adapter: DrownedHarborHighWaterFixtureAdapter = ADAPTER_SCRIPT.new()
		var rejected: Dictionary = adapter.load_and_prepare(case.request)
		_expect(not rejected.get("accepted", true), "%s request fails closed" % case.code)
		_expect(rejected.get("code") == case.code, "%s code is explicit" % case.code)
		_expect(adapter.state_signature().is_empty(), "%s retains no partial fixture" % case.code)
	_expect(
		baseline_shell._prepared_result_bytes() == baseline,
		"rejected probe requests do not mutate a prepared shell",
	)
	var already: DrownedHarborHighWaterFixtureAdapter = ADAPTER_SCRIPT.new()
	var already_result: Dictionary = already.load_and_prepare(request, true)
	_expect(
		already_result.get("code") == "already_committed", "already-committed adapter retry rejects"
	)
	baseline_shell.free()


func _test_precommit_projection_failure_and_recovery() -> void:
	var shell: DrownedHarborHighWaterTransformationShell = _new_shell()
	var failed: Dictionary = shell._fail_projection_before_commit()
	_expect(not failed.get("accepted", true), "pre-commit projection failure is explicit")
	_expect(failed.get("commit_count") == 0, "pre-commit failure commits nothing")
	_expect(failed.get("public_event_count") == 0, "pre-commit failure emits no event")
	_expect(shell._mode_name() == "precommit_recovery", "public-safe recovery mode is active")
	_expect(not shell._next_interaction_allowed(), "next interaction remains blocked")
	var recovered: Dictionary = shell.recover_projection()
	_expect(recovered.get("accepted", false), "pre-commit failure is restorable")
	_expect(shell.run_full_presentation().get("accepted", false), "recovered path can settle")
	_expect(shell._evidence_snapshot().get("commit_count") == 1, "recovery later commits once")
	shell.free()


func _test_postcommit_projection_failure_reprojects_existing_result() -> void:
	var shell: DrownedHarborHighWaterTransformationShell = _new_shell()
	shell.skip_presentation()
	var committed_bytes: String = shell._equivalence_bytes()
	var failed: Dictionary = shell._fail_projection_after_commit()
	_expect(failed.get("result_preserved", false), "post-commit failure preserves result")
	_expect(shell._mode_name() == "postcommit_recovery", "post-commit recovery mode is explicit")
	_expect(not shell._next_interaction_allowed(), "focus remains blocked during recovery")
	var recovered: Dictionary = shell.recover_projection()
	_expect(recovered.get("accepted", false), "post-commit recovery reprojects")
	_expect(recovered.get("reprojected", false), "post-commit recovery does not recompute")
	_expect(shell._equivalence_bytes() == committed_bytes, "recovery preserves exact result bytes")
	var evidence: Dictionary = shell._evidence_snapshot()
	_expect(evidence.get("commit_count") == 1, "post-commit recovery does not recommit")
	_expect(evidence.get("event_count") == 1, "post-commit recovery does not re-emit")
	shell.free()


func _test_caption_interruptions_preserve_commit_boundary() -> void:
	var before: DrownedHarborHighWaterTransformationShell = _new_shell()
	var interrupted_before: Dictionary = before.interrupt_caption_or_voice()
	_expect(
		not interrupted_before.get("accepted", true), "pre-commit caption interruption recovers"
	)
	_expect(
		before._evidence_snapshot().get("commit_count") == 0,
		"pre-commit interruption commits nothing"
	)
	_expect(
		before._evidence_snapshot().get("event_count") == 0, "pre-commit interruption emits nothing"
	)
	before.free()
	var after: DrownedHarborHighWaterTransformationShell = _new_shell()
	after.capture_before_state_caption()
	after.commit_authoritative_transformation()
	var committed: String = after._equivalence_bytes()
	var interrupted_after: Dictionary = after.interrupt_caption_or_voice()
	_expect(interrupted_after.get("accepted", false), "post-commit interruption reaches recap")
	_expect(interrupted_after.get("recovered_to_recap", false), "persistent recap replaces voice")
	_expect(
		after._equivalence_bytes() == committed, "interruption cannot roll back committed result"
	)
	_expect(
		after._evidence_snapshot().get("summary_available", false), "persistent summary survives"
	)
	after.free()


func _test_transcript_and_replay_unavailability_preserve_board() -> void:
	var transcript_shell: DrownedHarborHighWaterTransformationShell = SHELL_SCRIPT.new()
	transcript_shell._set_transcript_available(false)
	transcript_shell.initialize_from_fixture()
	transcript_shell.skip_presentation()
	var transcript_result: Dictionary = transcript_shell.open_transcript()
	_expect(
		transcript_result.get("code") == "transcript_unavailable", "transcript failure is explicit"
	)
	_expect(
		transcript_shell._evidence_snapshot().get("summary_available", false),
		"transcript failure preserves persistent recap",
	)
	_expect(
		not (
			transcript_shell
			. _equivalence_snapshot()
			. get("transformed_board_projection", {})
			. is_empty()
		),
		"transcript failure preserves transformed board",
	)
	transcript_shell.free()
	var replay_shell: DrownedHarborHighWaterTransformationShell = SHELL_SCRIPT.new()
	replay_shell._set_replay_available(false)
	replay_shell.initialize_from_fixture()
	replay_shell.skip_presentation()
	var replay_result: Dictionary = replay_shell.replay_committed_summary()
	_expect(replay_result.get("code") == "replay_unavailable", "replay failure is explicit")
	_expect(
		replay_shell._evidence_snapshot().get("commit_count") == 1,
		"replay failure preserves commit"
	)
	_expect(
		replay_shell._evidence_snapshot().get("event_count") == 1, "replay failure preserves event"
	)
	replay_shell.free()


func _test_replay_of_committed_summary_is_read_only() -> void:
	var shell: DrownedHarborHighWaterTransformationShell = _new_shell()
	shell.run_full_presentation()
	var before: String = shell._equivalence_bytes()
	var replay: Dictionary = shell.replay_committed_summary()
	_expect(replay.get("accepted", false), "committed public summary replays")
	_expect(not replay.get("reexecuted_commit", true), "replay does not reexecute transformation")
	_expect(shell._equivalence_bytes() == before, "replay preserves all governed bytes")
	shell.free()


func _test_persistent_summary_precedes_focus_return() -> void:
	var shell: DrownedHarborHighWaterTransformationShell = _new_shell()
	shell.capture_before_state_caption()
	shell.commit_authoritative_transformation()
	_expect(
		not shell._next_interaction_allowed(), "committed presentation still blocks interaction"
	)
	var premature: Dictionary = shell.acknowledge_persistent_summary()
	_expect(
		premature.get("code") == "persistent_summary_required", "premature focus return rejects"
	)
	shell.skip_presentation()
	var snapshot: Dictionary = shell._render_snapshot()
	_expect(
		not snapshot.get("persistent_summary", "").is_empty(), "changed-category text is persistent"
	)
	_expect(
		snapshot.get("focus_destination") == "high_water_public_recap",
		"focus remains on recap before acknowledgement",
	)
	_expect(not shell._next_interaction_allowed(), "recap alone does not return control")
	var acknowledged: Dictionary = shell.acknowledge_persistent_summary()
	_expect(
		acknowledged.get("focus_destination") == "seat_04", "seat_04 becomes deterministic focus"
	)
	_expect(
		shell._next_interaction_allowed(), "interaction opens only after summary acknowledgement"
	)
	shell.free()


func _test_transformed_board_is_read_only_and_multichannel() -> void:
	var shell: DrownedHarborHighWaterTransformationShell = _settled_shell()
	var projection: Dictionary = shell._equivalence_snapshot().get(
		"transformed_board_projection", {}
	)
	_expect(
		projection.get("placeholder_geometry", false), "transformed board uses placeholder geometry"
	)
	_expect(
		projection.get("geography_identity") == "recognizable_low_tide_geography_under_high_water",
		"Low-Tide geography remains recognizable",
	)
	var legend: Dictionary = projection.get("route_state_legend", {})
	for state: String in [
		"open",
		"submerged",
		"flooded_passable",
		"water_only",
		"unstable",
		"damaged",
		"collapsed",
	]:
		_expect(legend.has(state), "%s has a text/shape/pattern legend" % state)
	for action: Variant in projection.get("legal_inspection_actions", []):
		var inspected: Dictionary = shell.inspect_transformed_board(str(action))
		_expect(inspected.get("accepted", false), "%s inspection is legal" % action)
		_expect(inspected.get("read_only", false), "%s remains read-only" % action)
		_expect(not inspected.get("authoritative_mutation", true), "%s mutates nothing" % action)
	var rejected: Dictionary = shell._attempt_transformed_board_action_commit("select_legal_action")
	_expect(
		rejected.get("code") == "read_only_boundary", "transformed action commitment is disabled"
	)
	shell.free()


func _test_stable_seat_form_revision_rng_and_authority_invariance() -> void:
	var shell: DrownedHarborHighWaterTransformationShell = _new_shell()
	shell.skip_presentation()
	var snapshot: Dictionary = shell._equivalence_snapshot()
	var state: Dictionary = snapshot.get("authoritative_state", {})
	_expect(state.get("stable_seat_ids") == ["seat_04"], "stable-seat identity is preserved")
	_expect(
		snapshot.get("stable_seat_positions") == {"seat_04": "salt_market_platform"},
		"governed seat relocation is deterministic",
	)
	_expect(snapshot.get("public_form_state") == {"seat_04": "living"}, "public form is continuous")
	_expect(state.get("source_revision") == 41, "committed source revision remains 41")
	_expect(state.get("result_revision") == 42, "committed result revision remains 42")
	_expect(state.get("rng_cursor") == 12, "committed result consumes no RNG")
	var authority: Dictionary = shell._attempt_authority_transfer()
	_expect(
		authority.get("code") == "authority_transfer_prohibited", "authority transfer is rejected"
	)
	_expect(
		shell._evidence_snapshot().get("stable_seat_ids") == ["seat_04"], "rejection preserves seat"
	)
	shell.free()


func _test_private_markers_never_enter_public_channels() -> void:
	var shell: DrownedHarborHighWaterTransformationShell = _settled_shell()
	var public_bytes: String = JSON.stringify(shell._privacy_outputs(), "", true)
	_expect(
		PRIVATE_MARKER not in public_bytes, "private markers are absent from every public channel"
	)
	for prohibited: String in [
		"TIDEBOUND_PENDING",
		"CARRY_NAME_TO_LIGHTHOUSE",
		"PRIVATE_SEAT_04",
		"desirable",
		"preferred",
	]:
		_expect(prohibited not in public_bytes, "%s is absent from public evidence" % prohibited)
	shell.free()


func _test_no_duplicate_outputs_or_signals() -> void:
	var shell: DrownedHarborHighWaterTransformationShell = _new_shell()
	var emitted: Array[Dictionary] = []
	shell.prototype_high_water_event_emitted.connect(
		func(payload: Dictionary) -> void: emitted.append(payload)
	)
	shell.skip_presentation()
	shell.acknowledge_persistent_summary()
	for ignored: int in range(3):
		shell.skip_presentation()
		shell.acknowledge_persistent_summary()
		shell.replay_committed_summary()
		shell.open_transcript()
		shell.recover_projection()
		shell.submit_transformation_request(
			DrownedHarborHighWaterFixtureAdapter.authorized_request()
		)
	var evidence: Dictionary = shell._evidence_snapshot()
	_expect(evidence.get("commit_count") == 1, "repetition leaves one commit")
	_expect(evidence.get("event_count") == 1, "repetition leaves one event")
	_expect(evidence.get("history_count") == 1, "repetition leaves one history entry")
	_expect(evidence.get("transcript_count") == 1, "repetition leaves one transcript entry")
	_expect(evidence.get("replay_count") == 1, "repetition leaves one replay entry")
	_expect(evidence.get("mirror_count") == 1, "repetition leaves one mirror entry")
	_expect(evidence.get("signal_count") == 1, "repetition leaves one emitted signal")
	_expect(emitted.size() == 1, "signal observer sees no duplicate")
	shell.free()


func _test_repeated_projection_and_second_shell_are_deterministic() -> void:
	var shell: DrownedHarborHighWaterTransformationShell = _new_shell()
	var prepared_first: String = shell._prepared_result_bytes()
	var prepared_second: String = shell._prepared_result_bytes()
	_expect(prepared_first == prepared_second, "one shell prepares deterministic bytes repeatedly")
	shell.run_full_presentation()
	var committed_first: String = shell._equivalence_bytes()
	shell.reproject_existing_result()
	var committed_second: String = shell._equivalence_bytes()
	_expect(
		committed_first == committed_second, "one shell reprojects byte-equivalent committed output"
	)
	var second_shell: DrownedHarborHighWaterTransformationShell = _new_shell()
	second_shell.run_full_presentation()
	_expect(
		shell._equivalence_bytes() == second_shell._equivalence_bytes(),
		"second shell produces byte-equivalent output from DH-FIX-004",
	)
	shell.free()
	second_shell.free()


func _test_gameplay_and_unsupported_inputs_fail_closed() -> void:
	var shell: DrownedHarborHighWaterTransformationShell = _new_shell()
	var before: String = shell._prepared_result_bytes()
	for action: String in [
		"move",
		"encounter",
		"rescue",
		"hazard_action",
		"faction_action",
		"form_action",
		"resource_action",
		"ending",
	]:
		var rejected: Dictionary = shell._attempt_gameplay_action(action)
		_expect(rejected.get("code") == "gameplay_mutation_blocked", "%s is blocked" % action)
	_expect(
		(
			shell.dispatch_semantic_action("unmapped_high_water_action").get("code")
			== "unsupported_input"
		),
		"unsupported input fails closed",
	)
	_expect(shell._prepared_result_bytes() == before, "blocked work cannot alter prepared result")
	_expect(shell._evidence_snapshot().get("commit_count") == 0, "blocked work commits nothing")
	shell.free()


func _test_existing_semantic_input_mappings() -> void:
	for action: String in [
		"ui_navigate_left",
		"ui_navigate_right",
		"ui_navigate_up",
		"ui_navigate_down",
		"ui_confirm",
		"ui_cancel_action",
		"interact",
		"help_accessibility",
	]:
		var has_keyboard: bool = false
		var has_controller: bool = false
		for event: InputEvent in InputMap.action_get_events(action):
			has_keyboard = has_keyboard or event is InputEventKey
			has_controller = (
				has_controller or event is InputEventJoypadButton or event is InputEventJoypadMotion
			)
		_expect(has_keyboard, "%s retains keyboard fallback" % action)
		_expect(has_controller, "%s retains controller mapping" % action)


func _test_scene_is_export_excluded_and_instantiable() -> void:
	_expect(SCENE_PATH.begins_with("res://tests/"), "High Water scene remains under tests")
	var packed: PackedScene = load(SCENE_PATH)
	_expect(packed != null, "High Water scene loads")
	if packed == null:
		return
	var instance: Node = packed.instantiate()
	_expect(
		instance is DrownedHarborHighWaterTransformationShell,
		"scene root uses bounded High Water shell",
	)
	instance.free()
	for generated_path: String in [
		"res://p018-high-water-transformation-evidence",
		"res://artifacts/p018-python",
		"res://artifacts/p018-godot",
	]:
		_expect(
			not FileAccess.file_exists(generated_path),
			"no tracked generated evidence at %s" % generated_path
		)


func _new_shell() -> DrownedHarborHighWaterTransformationShell:
	var shell: DrownedHarborHighWaterTransformationShell = SHELL_SCRIPT.new()
	var initialized: Dictionary = shell.initialize_from_fixture()
	_expect(initialized.get("accepted", false), "High Water shell initializes from exact fixture")
	return shell


func _settled_shell() -> DrownedHarborHighWaterTransformationShell:
	var shell: DrownedHarborHighWaterTransformationShell = _new_shell()
	shell.skip_presentation()
	shell.acknowledge_persistent_summary()
	return shell


func _fixture(package: Dictionary, fixture_id: String) -> Dictionary:
	for value: Variant in package.get("fixtures", []):
		if value is Dictionary and value.get("fixture_id") == fixture_id:
			return value
	return {}


func _read_json(path: String) -> Dictionary:
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if value is Dictionary:
		return value
	return {}


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
		return
	_failures += 1
	push_error("FAILED: %s" % message)
