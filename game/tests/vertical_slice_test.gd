extends SceneTree

const MANIFEST_PATH: String = "res://data/scenarios/lantern_house_vertical_slice_v1.json"

var _failures: int = 0


func _initialize() -> void:
	_test_manifest_validation()
	_test_manifest_reference_and_policy_negatives()
	_test_lifecycle_and_atomic_initialization()
	_test_supported_seats_and_fallback()
	_test_shared_screen_and_optional_companion()
	_test_complete_fixture_and_privacy()
	_test_snapshot_replay_and_rematch()
	_test_pre_session_snapshot_coherence()
	_test_exploration_snapshot_and_progression_rejection()
	_test_stage_transaction_rollback_across_wait()
	_test_atomic_rematch_and_restore_room_cleanup()
	if _failures == 0:
		print("Vertical slice tests passed")
	quit(_failures)


func _test_manifest_validation() -> void:
	var manifest: Dictionary = VerticalSliceManifest.load_file(MANIFEST_PATH)
	var failures: PackedStringArray = (
		VerticalSliceManifest
		. validate(
			manifest,
			LanternHouseBoardDefinition.new(),
			LanternHouseRulesContent.new(),
			LanternHouseDirectorContent.new(),
			LanternHouseSocialContent.new(),
		)
	)
	if not failures.is_empty():
		print("MANIFEST FAILURES: ", failures)
	_expect(failures.is_empty(), "accepts the versioned Lantern House manifest")
	var malformed: Dictionary = manifest.duplicate(true)
	malformed.board_reference = "unknown_board"
	_expect(
		not (
			VerticalSliceManifest
			. validate(
				malformed,
				LanternHouseBoardDefinition.new(),
				LanternHouseRulesContent.new(),
				LanternHouseDirectorContent.new(),
				LanternHouseSocialContent.new(),
			)
			. is_empty()
		),
		"rejects an unknown authority reference",
	)


func _test_lifecycle_and_atomic_initialization() -> void:
	var coordinator := _coordinator_with_seats(3)
	var initial: Dictionary = coordinator.to_snapshot()
	_expect(
		not coordinator.begin_tale().accepted and coordinator.lifecycle == "boot_title",
		"rejects invalid lifecycle transitions without mutation",
	)
	_expect(coordinator.enter_lobby().accepted, "enters the stable-seat lobby")
	_expect(coordinator.confirm_roster().accepted, "confirms a non-empty roster")
	var before_invalid: Dictionary = coordinator.to_snapshot()
	_expect(
		not coordinator.initialize_session("res://missing_manifest.json").accepted,
		"rejects a missing manifest",
	)
	_expect(
		coordinator.to_snapshot() == before_invalid,
		"keeps failed initialization atomic",
	)
	var initialized: Dictionary = coordinator.initialize_session(MANIFEST_PATH, 4706)
	if not initialized.accepted:
		print("INITIALIZATION FAILURE: ", initialized)
	_expect(initialized.accepted, "builds authorities")
	_expect(coordinator.begin_tale().accepted, "enters the active tale after briefing")
	_expect(
		coordinator.board_state.space_for_seat(1) == "lantern_hall",
		"maps initialized pawn occupancy through BoardState",
	)
	_expect(coordinator.toggle_pause().accepted and coordinator.paused, "pauses active play safely")
	_expect(not coordinator.run_current_stage().accepted, "rejects stage input while paused")
	_expect(coordinator.toggle_pause().accepted and not coordinator.paused, "resumes active play")
	var waiting: Dictionary = coordinator.advance_player_stage()
	_expect(waiting.accepted and waiting.waiting_for_players, "presents the authored prompt")
	var prompt_revision: int = coordinator.rules_session.pending_prompt.revision
	_expect(
		coordinator.rules_session.submit_response(1, ["force"], prompt_revision).accepted,
		"accepts a controller-selected public prompt option",
	)
	_expect(coordinator.advance_player_stage().accepted, "continues after the inspected choice")
	_expect(initial.seat_manager == coordinator.to_snapshot().seat_manager, "retains stable seats")


func _test_manifest_reference_and_policy_negatives() -> void:
	var cases: Array[Dictionary] = []
	var unknown_check: Dictionary = _manifest_copy()
	unknown_check.stages[2].operations[2].check_id = "unknown_check"
	cases.append({"manifest": unknown_check, "label": "unknown check"})
	var unknown_selector: Dictionary = _manifest_copy()
	unknown_selector.stages[3].operations[0].selector_tag = "unknown_role"
	cases.append({"manifest": unknown_selector, "label": "unknown role selector"})
	var unknown_trigger: Dictionary = _manifest_copy()
	unknown_trigger.stages[3].operations[0].trigger = "unknown_trigger"
	cases.append({"manifest": unknown_trigger, "label": "unknown transition trigger"})
	var incompatible_trigger: Dictionary = _manifest_copy()
	incompatible_trigger.stages[3].operations[0].selector_tag = "afterlife"
	cases.append({"manifest": incompatible_trigger, "label": "incompatible transition selector"})
	var unknown_action: Dictionary = _manifest_copy()
	unknown_action.stages[3].operations[1].action_tag = "unknown_action"
	cases.append({"manifest": unknown_action, "label": "unknown action tag"})
	var incompatible_action: Dictionary = _manifest_copy()
	incompatible_action.stages[3].operations[1].selector_tag = "living"
	cases.append({"manifest": incompatible_action, "label": "incompatible action selector"})
	var unknown_policy_key: Dictionary = _manifest_copy()
	unknown_policy_key.companion_policy["cloud"] = false
	cases.append({"manifest": unknown_policy_key, "label": "unknown policy key"})
	var unsupported_policy: Dictionary = _manifest_copy()
	unsupported_policy.companion_policy.authority = "cloud"
	cases.append({"manifest": unsupported_policy, "label": "non-native authority policy"})
	var malformed_seed: Dictionary = _manifest_copy()
	malformed_seed.fixture.seeds[0] = -1
	cases.append({"manifest": malformed_seed, "label": "malformed fixture seed"})
	var malformed_input: Dictionary = _manifest_copy()
	malformed_input.fixture.ordered_inputs[3] = "teleport"
	cases.append({"manifest": malformed_input, "label": "malformed fixture input"})
	var impossible_modes: Dictionary = _manifest_copy()
	impossible_modes.fallback_mode = "no_afterlife"
	cases.append({"manifest": impossible_modes, "label": "incoherent default fallback"})
	for test_case: Dictionary in cases:
		_expect(
			not _manifest_failures(test_case.manifest).is_empty(),
			"rejects %s before authority construction" % test_case.label,
		)
	var coordinator := _coordinator_with_seats(4)
	coordinator.enter_lobby()
	coordinator.confirm_roster()
	var before: Dictionary = coordinator.to_snapshot()
	_expect(
		not coordinator.initialize_session(MANIFEST_PATH, 4706, "hunted").accepted,
		"rejects an existing but undeclared social mode",
	)
	_expect(
		coordinator.to_snapshot() == before,
		"rejects an undeclared requested mode before session mutation",
	)


func _test_supported_seats_and_fallback() -> void:
	for seat_count: int in range(1, SeatManager.MAX_SEATS + 1):
		var coordinator := _initialized_coordinator(seat_count, 5000 + seat_count)
		_expect(coordinator.lifecycle == "active_tale", "supports %d stable seats" % seat_count)
		_expect(
			(
				coordinator.role_session.mode_id
				== ("cooperative" if seat_count < 3 else "hidden_betrayer")
			),
			"applies the authored safe mode policy for %d seats" % seat_count,
		)
		_expect(
			coordinator.role_session.fallback_applied == (seat_count < 3),
			"reports fallback use accurately for %d seats" % seat_count,
		)


func _test_complete_fixture_and_privacy() -> void:
	var coordinator := _initialized_coordinator(4, 4706)
	var private_before: Dictionary = coordinator.role_session.seat_private_view(1)
	var public_before: String = JSON.stringify(coordinator.public_state())
	var private_role_id: String = private_before.get("role", {}).get("id", "")
	if not private_role_id.is_empty():
		_expect(
			not private_role_id in public_before, "keeps unrevealed role IDs out of public flow"
		)
	for _index: int in 6:
		if coordinator.lifecycle != "active_tale":
			break
		var result: Dictionary = coordinator.run_current_stage()
		if not result.accepted:
			print("STAGE FAILURE: ", result)
		_expect(result.accepted, "advances a bounded authored stage")
	_expect(coordinator.lifecycle == "terminal", "commits a deterministic terminal state")
	_expect(coordinator.review_ending().accepted, "opens the privacy-safe ending")
	var ending_text: String = JSON.stringify(coordinator.public_state().ending)
	_expect(not "assigned_role_id" in ending_text, "omits private assignments from the ending")
	var director_signals: String = JSON.stringify(coordinator.role_session.director_safe_signals())
	_expect(
		not "assigned_role_id" in director_signals,
		"feeds the Director only normalized public social signals",
	)
	_expect(
		coordinator.board_state.get_space_state("lantern_hall").features.has("restless_omen"),
		"keeps a defeated seat participating through an afterlife action",
	)


func _test_shared_screen_and_optional_companion() -> void:
	var coordinator := _initialized_coordinator(3, 6201)
	var secret_seat: int = coordinator.role_session.seat_with_tag("secret")
	_expect(secret_seat > 0, "assigns a private role only in a supported mode")
	_expect(
		coordinator.role_session.acknowledge_private_role(secret_seat).accepted,
		"supports controlled shared-screen private reveal without a phone",
	)
	var bridge: CompanionBridge = coordinator.companion_bridge
	var transport := CompanionFakeTransport.new(bridge)
	bridge.create_room("slice_room", "SLCE3A")
	transport.connect_client("slice_client")
	_expect(
		transport.approve_client("slice_client", secret_seat).accepted,
		"optionally binds a browser to an approved stable seat",
	)
	var prompt: Dictionary = coordinator.rules_content.events[0].prompts[0].duplicate(true)
	prompt.scope = "single"
	coordinator.rules_session.open_prompt(prompt, [secret_seat], "slice_companion_prompt")
	var before: int = coordinator.rules_session.history().size()
	var payload: Dictionary = {
		"option_ids": ["listen"],
		"prompt_revision": coordinator.rules_session.pending_prompt.revision,
	}
	var first: Dictionary = transport.send_intent(
		"slice_client", "prompt_choice_submit", "slice_choice_once", payload, secret_seat
	)
	var after_once: int = coordinator.rules_session.history().size()
	var duplicate: Dictionary = transport.send_intent(
		"slice_client", "prompt_choice_submit", "slice_choice_once", payload, secret_seat
	)
	_expect(
		first.accepted and first.envelope.payload.applied_once, "routes through native authority"
	)
	_expect(
		(
			duplicate.accepted
			and duplicate.idempotent
			and after_once == before + 1
			and coordinator.rules_session.history().size() == after_once
		),
		"applies an integrated companion intent exactly once",
	)


func _test_snapshot_replay_and_rematch() -> void:
	var first := _initialized_coordinator(3, 9017)
	first.run_current_stage()
	first.run_current_stage()
	var snapshot: Dictionary = first.to_snapshot()
	var restored := VerticalSliceCoordinator.new()
	_expect(
		restored.restore_snapshot(snapshot).accepted, "round-trips a versioned session snapshot"
	)
	_expect(restored.authority_digest() == first.authority_digest(), "restores all authority state")
	var stable: Dictionary = restored.to_snapshot()
	var malformed: Dictionary = snapshot.duplicate(true)
	malformed.rules.snapshot_version = 99
	_expect(
		not restored.restore_snapshot(malformed).accepted, "rejects a malformed nested snapshot"
	)
	_expect(restored.to_snapshot() == stable, "rejects malformed restore atomically")
	_complete(first)
	_complete(restored)
	_expect(
		first.public_history_digest() == restored.public_history_digest(),
		"replays the same ordered input and seed deterministically",
	)
	var terminal_digest: String = first.public_history_digest()
	first.review_ending()
	_expect(first.rematch().accepted, "starts a clean rematch")
	_expect(
		first.lifecycle == "briefing" and first.stage_history.is_empty(), "clears prior stage state"
	)
	_expect(
		(
			first.board_state.space_for_seat(1) == "lantern_hall"
			and not first.board_state.get_space_state("lantern_hall").features.has("clue_revealed")
		),
		"clears prior board mutations while rebuilding initial occupancy",
	)
	_expect(not terminal_digest.is_empty(), "publishes a terminal replay digest")


func _test_pre_session_snapshot_coherence() -> void:
	var receiver := VerticalSliceCoordinator.new()
	var stable: Dictionary = receiver.to_snapshot()
	var empty_confirmation: Dictionary = stable.duplicate(true)
	empty_confirmation.lifecycle = "confirmation"
	_expect(
		not receiver.restore_snapshot(empty_confirmation).accepted,
		"rejects confirmation without a stable-seat roster",
	)
	_expect(receiver.to_snapshot() == stable, "keeps empty-confirmation rejection atomic")
	var seated_boot := _coordinator_with_seats(1)
	var seated_boot_snapshot: Dictionary = seated_boot.to_snapshot()
	_expect(
		not receiver.restore_snapshot(seated_boot_snapshot).accepted,
		"rejects boot/title state containing an assigned stable seat",
	)
	_expect(receiver.to_snapshot() == stable, "keeps seated-boot rejection atomic")
	seated_boot.enter_lobby()
	_expect(
		receiver.restore_snapshot(seated_boot.to_snapshot()).accepted,
		"accepts an assigned stable-seat roster in the lobby",
	)


func _test_exploration_snapshot_and_progression_rejection() -> void:
	var source := _initialized_coordinator(3, 9017)
	source.run_current_stage()
	var moved: PawnState = source.pawn_registry.get_by_seat(1)
	moved.position = Vector2(1240.0, 500.0)
	moved.input_vector = Vector2(0.5, -0.25)
	moved.nearby_interactable = "iron_gate"
	source.board_state.sync_occupancy(source.pawn_registry.get_pawns())
	var snapshot: Dictionary = source.to_snapshot()
	var restored := VerticalSliceCoordinator.new()
	_expect(restored.restore_snapshot(snapshot).accepted, "restores moved exploration state")
	var restored_pawn: PawnState = restored.pawn_registry.get_by_seat(1)
	_expect(restored_pawn.position == moved.position, "preserves the exact pawn position")
	_expect(
		(
			restored_pawn.device_id == moved.device_id
			and restored_pawn.identity == moved.identity
			and restored_pawn.connected == moved.connected
		),
		"preserves pawn seat and device ownership",
	)
	_expect(
		restored.board_state.get_occupancy() == source.board_state.get_occupancy(),
		"restores BoardState occupancy derived from pawn positions",
	)
	_expect(restored.authority_digest() == source.authority_digest(), "preserves authority digest")
	_expect(
		restored.public_history_digest() == source.public_history_digest(),
		"preserves public history digest",
	)
	var malformed_cases: Array[Dictionary] = []
	for bad_stage: int in [-2, 999]:
		var malformed: Dictionary = snapshot.duplicate(true)
		malformed.stage_index = bad_stage
		malformed_cases.append(malformed)
	for bad_operation: int in [-1, 999]:
		var malformed: Dictionary = snapshot.duplicate(true)
		malformed.operation_index = bad_operation
		malformed_cases.append(malformed)
	var impossible_history: Dictionary = snapshot.duplicate(true)
	impossible_history.stage_history.clear()
	malformed_cases.append(impossible_history)
	var paused_briefing: Dictionary = snapshot.duplicate(true)
	paused_briefing.lifecycle = "briefing"
	paused_briefing.paused = true
	paused_briefing.stage_index = -1
	paused_briefing.operation_index = 0
	paused_briefing.stage_history.clear()
	malformed_cases.append(paused_briefing)
	var pawn_outside: Dictionary = snapshot.duplicate(true)
	pawn_outside.pawns.pawns[0].position.x = -20.0
	malformed_cases.append(pawn_outside)
	var ownership_mismatch: Dictionary = snapshot.duplicate(true)
	ownership_mismatch.pawns.pawns[0].device_id = 777
	malformed_cases.append(ownership_mismatch)
	var occupancy_mismatch: Dictionary = snapshot.duplicate(true)
	var mismatched_board: Dictionary = occupancy_mismatch.board.duplicate(true)
	var mismatched_rows: Array = mismatched_board.occupancy.duplicate(true)
	var mismatched_row: Dictionary = mismatched_rows[0].duplicate(true)
	mismatched_row.space_id = "lantern_hall"
	mismatched_rows[0] = mismatched_row
	mismatched_board.occupancy = mismatched_rows
	occupancy_mismatch.board = mismatched_board
	malformed_cases.append(occupancy_mismatch)
	for malformed_index: int in malformed_cases.size():
		var malformed: Dictionary = malformed_cases[malformed_index]
		var stable: Dictionary = restored.to_snapshot()
		var malformed_result: Dictionary = restored.restore_snapshot(malformed)
		_expect(
			not malformed_result.accepted,
			"rejects impossible snapshot case %d" % malformed_index,
		)
		_expect(
			restored.to_snapshot() == stable,
			"leaves the receiving coordinator byte-equivalent after rejection",
		)


func _test_stage_transaction_rollback_across_wait() -> void:
	var coordinator := _initialized_coordinator(3, 4706)
	var stage_start: Dictionary = coordinator.to_snapshot()
	var waiting: Dictionary = coordinator.advance_player_stage()
	_expect(waiting.accepted and waiting.waiting_for_players, "retains a stage checkpoint at wait")
	var waiting_snapshot: Dictionary = coordinator.to_snapshot()
	var waiting_restore := VerticalSliceCoordinator.new()
	_expect(
		waiting_restore.restore_snapshot(waiting_snapshot).accepted,
		"round-trips an in-progress stage transaction",
	)
	_expect(
		waiting_restore.to_snapshot() == waiting_snapshot,
		"preserves the original stage-start checkpoint across snapshot restore",
	)
	var revision: int = coordinator.rules_session.pending_prompt.revision
	coordinator.rules_session.submit_response(1, ["listen"], revision)
	coordinator.board_state.apply_mutation(
		BoardMutation.feature("lantern_hall", "clue_revealed", true), 1
	)
	var rejected: Dictionary = coordinator.advance_player_stage()
	_expect(not rejected.accepted, "surfaces a later bounded operation rejection")
	_expect(
		coordinator.to_snapshot() == stage_start,
		"rolls every authority and progression field back to stage start",
	)
	_expect(coordinator.rules_session.pending_prompt.is_empty(), "clears the rolled-back prompt")
	var retry_wait: Dictionary = coordinator.advance_player_stage()
	var retry_revision: int = coordinator.rules_session.pending_prompt.revision
	coordinator.rules_session.submit_response(1, ["listen"], retry_revision)
	var completed: Dictionary = coordinator.advance_player_stage()
	_expect(retry_wait.waiting_for_players and completed.accepted, "retries the valid stage route")
	_expect(
		coordinator.stage_index == 1 and coordinator.stage_history.size() == 1,
		"commits the retried stage exactly once",
	)


func _test_atomic_rematch_and_restore_room_cleanup() -> void:
	var coordinator := _initialized_coordinator(3, 22031)
	_complete(coordinator)
	coordinator.review_ending()
	var old_bridge: CompanionBridge = coordinator.companion_bridge
	old_bridge.create_room("rematch_room", "RMATCH")
	var old_transport := CompanionFakeTransport.new(old_bridge)
	old_transport.connect_client("claimed_client")
	old_transport.approve_client("claimed_client", 1)
	old_transport.send_intent("claimed_client", "private_reveal_ack", "cached_ack", {}, 1)
	old_transport.connect_client("pending_client")
	var before_failed: Dictionary = coordinator.to_snapshot()
	_expect(
		not coordinator.rematch_with_manifest("res://missing_rematch_manifest.json").accepted,
		"rejects a failed rematch candidate",
	)
	_expect(
		coordinator.to_snapshot() == before_failed and old_bridge.room_open,
		"leaves the ending session and open room untouched after failed rematch",
	)
	var retained_seats: Dictionary = coordinator.seat_manager.to_snapshot()
	_expect(coordinator.rematch().accepted, "commits a fully validated rematch candidate")
	_expect(not old_bridge.room_open, "closes the former companion room before replacement")
	_expect(
		coordinator.seat_manager.to_snapshot() == retained_seats,
		"retains exactly the stable seats required by rematch policy",
	)
	var clean: Dictionary = coordinator.companion_bridge.diagnostics()
	_expect(
		(
			coordinator.lifecycle == "briefing"
			and clean.room_state == "closed"
			and clean.pending_clients == 0
			and clean.seat_claims.is_empty()
			and clean.history.is_empty()
			and clean.sequence == 0
			and coordinator.stage_history.is_empty()
			and coordinator.rules_session.pending_prompt.is_empty()
			and coordinator.director_runtime.audit_history.is_empty()
			and coordinator.director_runtime.target_history.is_empty()
		),
		"starts the replacement session without stale companion or authority state",
	)
	var source := _initialized_coordinator(2, 4706)
	var source_snapshot: Dictionary = source.to_snapshot()
	var restore_old_bridge: CompanionBridge = coordinator.companion_bridge
	restore_old_bridge.create_room("restore_room", "RSTORE")
	restore_old_bridge.request_join("restore_pending")
	_expect(coordinator.restore_snapshot(source_snapshot).accepted, "restores a detached candidate")
	_expect(not restore_old_bridge.room_open, "closes the old room before restored replacement")
	_expect(
		coordinator.companion_bridge.diagnostics().pending_clients == 0,
		"keeps the replacement companion bridge clean and optional",
	)


func _coordinator_with_seats(seat_count: int) -> VerticalSliceCoordinator:
	var coordinator := VerticalSliceCoordinator.new()
	for index: int in seat_count:
		coordinator.seat_manager.join_device(index, "fixture-%d" % index, "Fixture Pad")
	return coordinator


func _initialized_coordinator(seat_count: int, seed: int) -> VerticalSliceCoordinator:
	var coordinator := _coordinator_with_seats(seat_count)
	coordinator.enter_lobby()
	coordinator.confirm_roster()
	coordinator.initialize_session(MANIFEST_PATH, seed)
	coordinator.begin_tale()
	return coordinator


func _complete(coordinator: VerticalSliceCoordinator) -> void:
	for _index: int in 6:
		if coordinator.lifecycle != "active_tale":
			break
		var result: Dictionary = coordinator.run_current_stage()
		if not result.accepted:
			print("COMPLETE FAILURE: ", result)
			break


func _manifest_copy() -> Dictionary:
	return VerticalSliceManifest.load_file(MANIFEST_PATH).duplicate(true)


func _manifest_failures(value: Dictionary) -> PackedStringArray:
	return (
		VerticalSliceManifest
		. validate(
			value,
			LanternHouseBoardDefinition.new(),
			LanternHouseRulesContent.new(),
			LanternHouseDirectorContent.new(),
			LanternHouseSocialContent.new(),
		)
	)


func _expect(condition: bool, description: String) -> void:
	if not condition:
		_failures += 1
		push_error("FAILED: %s" % description)
