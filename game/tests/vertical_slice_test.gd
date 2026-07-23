extends SceneTree

const MANIFEST_PATH: String = "res://data/scenarios/lantern_house_vertical_slice_v1.json"
const MAIN_SCRIPT: Script = preload("res://src/main/main.gd")

var _failures: int = 0


func _initialize() -> void:
	_test_manifest_validation()
	_test_manifest_reference_and_policy_negatives()
	_test_manifest_operation_sequence_negatives()
	_test_lifecycle_and_atomic_initialization()
	_test_confirmation_cancel_player_flow()
	_test_supported_seats_and_fallback()
	_test_shared_screen_and_optional_companion()
	_test_complete_fixture_and_privacy()
	_test_snapshot_replay_and_rematch()
	_test_pre_session_snapshot_coherence()
	_test_exploration_snapshot_and_progression_rejection()
	_test_stage_transaction_rollback_across_wait()
	_test_resumable_snapshot_boundaries()
	_test_protected_reset_paths()
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
		not coordinator.select_tale("synthetic_missing_tale").accepted,
		"rejects an unknown pre-session Tale",
	)
	_expect(
		coordinator.to_snapshot() == before_invalid,
		"keeps failed initialization atomic",
	)
	var initialized: Dictionary = coordinator.initialize_session(4706)
	if not initialized.accepted:
		print("INITIALIZATION FAILURE: ", initialized)
	_expect(initialized.accepted, "builds authorities")
	_expect(coordinator.begin_tale().accepted, "enters the active tale after briefing")
	_complete_private_reveals(coordinator)
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


func _test_confirmation_cancel_player_flow() -> void:
	var coordinator := VerticalSliceCoordinator.new()
	coordinator.seat_manager.join_device(0, "cancel-flow-pad", "Fixture Pad")
	coordinator.enter_lobby()
	coordinator.confirm_roster()
	var view := VerticalSliceView.new()
	view._ready()
	view.present(coordinator.public_state(), coordinator.seat_manager.get_seats())
	var footer: Label = view.get("_footer")
	_expect(
		footer.text.ends_with("B / ESC: RETURN TO LOBBY"),
		"advertises the implemented confirmation Cancel destination",
	)
	var retained_roster: Dictionary = coordinator.seat_manager.to_snapshot()
	coordinator.cancel_setup()
	_expect(
		(
			coordinator.lifecycle == "lobby"
			and coordinator.seat_manager.to_snapshot() == retained_roster
		),
		"routes controller Cancel from confirmation to the retained-roster lobby",
	)
	_expect(
		(
			coordinator.manifest.is_empty()
			and coordinator.board_state == null
			and coordinator.rules_session == null
			and coordinator.companion_bridge == null
		),
		"keeps session authorities absent after confirmation Cancel",
	)
	var coherence_probe := VerticalSliceCoordinator.new()
	_expect(
		coherence_probe.restore_snapshot(coordinator.to_snapshot()).accepted,
		"keeps the cancelled lobby snapshot coherent",
	)
	coordinator.confirm_roster()
	_expect(coordinator.lifecycle == "confirmation", "re-enters confirmation after Cancel")
	coordinator.initialize_session()
	_expect(
		coordinator.lifecycle == "briefing" and coordinator.rules_session != null,
		"initializes normally after the lobby-confirmation retry",
	)
	var empty_lobby := VerticalSliceCoordinator.new()
	empty_lobby.seat_manager.join_device(1, "last-lobby-pad", "Fixture Pad")
	empty_lobby.enter_lobby()
	empty_lobby.seat_manager.leave_device(1)
	_expect(
		empty_lobby.cancel_setup().accepted and empty_lobby.lifecycle == "boot_title",
		"returns an empty lobby to coherent boot/title",
	)
	_expect(
		VerticalSliceCoordinator.new().restore_snapshot(empty_lobby.to_snapshot()).accepted,
		"round-trips the empty-lobby title snapshot",
	)
	view.free()


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
		not coordinator.initialize_session(4706, "hunted").accepted,
		"rejects an existing but undeclared social mode",
	)
	_expect(
		coordinator.to_snapshot() == before,
		"rejects an undeclared requested mode before session mutation",
	)


func _test_manifest_operation_sequence_negatives() -> void:
	var cases: Array[Dictionary] = []
	var resolve_before_queue: Dictionary = _manifest_copy()
	var first: Dictionary = resolve_before_queue.stages[0].operations[0]
	resolve_before_queue.stages[0].operations[0] = resolve_before_queue.stages[0].operations[1]
	resolve_before_queue.stages[0].operations[1] = first
	cases.append({"manifest": resolve_before_queue, "label": "resolve_event before queue_event"})
	var missing_queue: Dictionary = _manifest_copy()
	missing_queue.stages[0].operations.remove_at(0)
	cases.append({"manifest": missing_queue, "label": "missing queue_event"})
	var submit_vote_without_open: Dictionary = _manifest_copy()
	submit_vote_without_open.stages[1].operations.remove_at(0)
	cases.append({"manifest": submit_vote_without_open, "label": "submit_vote without open_vote"})
	var duplicate_resolve_vote: Dictionary = _manifest_copy()
	duplicate_resolve_vote.stages[1].operations.append({"type": "resolve_vote"})
	cases.append({"manifest": duplicate_resolve_vote, "label": "duplicate resolve_vote"})
	var missing_director: Dictionary = _manifest_copy()
	missing_director.stages[2].operations.remove_at(3)
	cases.append({"manifest": missing_director, "label": "omitted Director opportunity"})
	var action_before_transition: Dictionary = _manifest_copy()
	var transition: Dictionary = action_before_transition.stages[3].operations[0]
	action_before_transition.stages[3].operations[0] = (
		action_before_transition.stages[3].operations[1]
	)
	action_before_transition.stages[3].operations[1] = transition
	cases.append({"manifest": action_before_transition, "label": "role action before transition"})
	var outcome_outside_ending: Dictionary = _manifest_copy()
	outcome_outside_ending.stages[0].operations.append({"type": "resolve_outcomes"})
	cases.append({"manifest": outcome_outside_ending, "label": "outcome outside ending"})
	var wrong_threshold_event: Dictionary = _manifest_copy()
	wrong_threshold_event.stages[0].operations[0].event_id = "gallery_council"
	cases.append({"manifest": wrong_threshold_event, "label": "wrong valid Threshold event"})
	var wrong_prompt_option: Dictionary = _manifest_copy()
	wrong_prompt_option.stages[0].operations[2].option_id = "force"
	cases.append({"manifest": wrong_prompt_option, "label": "wrong valid Threshold option"})
	var wrong_threshold_fixture: Dictionary = _manifest_copy()
	wrong_threshold_fixture.stages[0].operations[5].fixture = "secure_house"
	cases.append({"manifest": wrong_threshold_fixture, "label": "wrong valid Threshold fixture"})
	var wrong_reckoning_fixture: Dictionary = _manifest_copy()
	wrong_reckoning_fixture.stages[2].operations[0].fixture = "reveal_clue"
	cases.append({"manifest": wrong_reckoning_fixture, "label": "wrong valid Reckoning fixture"})
	var wrong_reckoning_card: Dictionary = _manifest_copy()
	wrong_reckoning_card.stages[2].operations[1].card_id = "iron_resolve"
	cases.append({"manifest": wrong_reckoning_card, "label": "wrong valid Reckoning card"})
	var swapped_vote_options: Dictionary = _manifest_copy()
	swapped_vote_options.stages[1].operations[1].odd_option = "vault"
	swapped_vote_options.stages[1].operations[1].even_option = "gallery"
	cases.append({"manifest": swapped_vote_options, "label": "swapped valid vote options"})
	var wrong_afterlife_transition: Dictionary = _manifest_copy()
	wrong_afterlife_transition.stages[3].operations[0].selector_tag = "afterlife"
	wrong_afterlife_transition.stages[3].operations[0].trigger = "guardian_path"
	cases.append(
		{"manifest": wrong_afterlife_transition, "label": "wrong valid afterlife transition"}
	)
	var wrong_afterlife_action: Dictionary = _manifest_copy()
	wrong_afterlife_action.stages[3].operations[1].action_tag = "guardian"
	cases.append({"manifest": wrong_afterlife_action, "label": "wrong valid afterlife action"})
	var wrong_ending_fixture: Dictionary = _manifest_copy()
	wrong_ending_fixture.stages[4].operations[0].fixture = "reveal_clue"
	cases.append({"manifest": wrong_ending_fixture, "label": "wrong valid Ending fixture"})
	for test_case: Dictionary in cases:
		_expect(
			not _manifest_failures(test_case.manifest).is_empty(),
			"rejects %s under the manifest v1 stage-operation policy" % test_case.label,
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
	var reveal_flow: PrivateRevealFlow = coordinator.get("_private_reveal_flow")
	_expect(
		(
			reveal_flow.phase == PrivateRevealFlow.PHASE_COMPLETE
			and coordinator.role_session.seat_states[secret_seat].acknowledged
		),
		"completes controlled shared-screen private reveals without a phone",
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


func _test_resumable_snapshot_boundaries() -> void:
	var prompt_source := _initialized_coordinator(3, 4706)
	_expect(
		prompt_source.advance_player_stage().waiting_for_players,
		"creates a genuine prompt wait boundary",
	)
	var prompt_wait: Dictionary = prompt_source.to_snapshot()
	var vote_source := _initialized_coordinator(3, 4706)
	vote_source.run_current_stage()
	_expect(
		vote_source.advance_player_stage().waiting_for_players,
		"creates a genuine vote wait boundary",
	)
	var vote_wait: Dictionary = vote_source.to_snapshot()
	var cases: Array[Dictionary] = []
	var arbitrary_index: Dictionary = prompt_wait.duplicate(true)
	arbitrary_index.operation_index = 4
	cases.append({"snapshot": arbitrary_index, "label": "arbitrary synchronous operation index"})
	var prompt_without_pending: Dictionary = prompt_wait.duplicate(true)
	prompt_without_pending.rules.pending_prompt.clear()
	cases.append({"snapshot": prompt_without_pending, "label": "prompt wait without prompt"})
	var vote_with_prompt_state: Dictionary = vote_wait.duplicate(true)
	vote_with_prompt_state.rules.active_vote.clear()
	cases.append({"snapshot": vote_with_prompt_state, "label": "vote boundary with prompt state"})
	var prompt_with_vote_state: Dictionary = prompt_wait.duplicate(true)
	prompt_with_vote_state.rules.active_vote = vote_wait.rules.active_vote.duplicate(true)
	cases.append({"snapshot": prompt_with_vote_state, "label": "prompt boundary with vote state"})
	var mismatched_eligible: Dictionary = prompt_wait.duplicate(true)
	mismatched_eligible.rules.pending_prompt.eligible_seats = [2]
	cases.append({"snapshot": mismatched_eligible, "label": "mismatched eligible seats"})
	var malformed_response: Dictionary = prompt_wait.duplicate(true)
	malformed_response.rules.pending_prompt.responses = [{"seat": 1, "value": ["unknown"]}]
	cases.append({"snapshot": malformed_response, "label": "malformed wait response"})
	var mismatched_transaction: Dictionary = prompt_wait.duplicate(true)
	mismatched_transaction.stage_transaction.stage_index = 1
	cases.append({"snapshot": mismatched_transaction, "label": "mismatched stage transaction"})
	var transaction_at_zero: Dictionary = _initialized_coordinator(3, 4706).to_snapshot()
	transaction_at_zero.stage_transaction = prompt_wait.stage_transaction.duplicate(true)
	cases.append({"snapshot": transaction_at_zero, "label": "transaction at operation zero"})
	var pending_at_zero: Dictionary = _initialized_coordinator(3, 4706).to_snapshot()
	pending_at_zero.rules.pending_prompt = prompt_wait.rules.pending_prompt.duplicate(true)
	cases.append({"snapshot": pending_at_zero, "label": "pending wait at operation zero"})
	var changed_prompt_scope: Dictionary = prompt_wait.duplicate(true)
	changed_prompt_scope.rules.pending_prompt.scope = "all"
	cases.append({"snapshot": changed_prompt_scope, "label": "changed prompt scope"})
	var changed_prompt_title: Dictionary = prompt_wait.duplicate(true)
	changed_prompt_title.rules.pending_prompt.title = "A different authored title"
	cases.append({"snapshot": changed_prompt_title, "label": "changed prompt title"})
	var changed_prompt_text: Dictionary = prompt_wait.duplicate(true)
	changed_prompt_text.rules.pending_prompt.options[0].text = "A different choice"
	cases.append({"snapshot": changed_prompt_text, "label": "same-ID changed prompt text"})
	var changed_prompt_symbol: Dictionary = prompt_wait.duplicate(true)
	changed_prompt_symbol.rules.pending_prompt.options[0].symbol = "!"
	cases.append({"snapshot": changed_prompt_symbol, "label": "same-ID changed prompt symbol"})
	var injected_prompt_effect: Dictionary = prompt_wait.duplicate(true)
	injected_prompt_effect.rules.pending_prompt.options[0]["effects"] = [
		{"type": "set_flag", "flag_id": "injected_prompt_effect", "value": true}
	]
	cases.append({"snapshot": injected_prompt_effect, "label": "same-ID injected prompt effect"})
	var extra_prompt_key: Dictionary = prompt_wait.duplicate(true)
	extra_prompt_key.rules.pending_prompt["unreviewed"] = true
	cases.append({"snapshot": extra_prompt_key, "label": "unknown pending prompt key"})
	var changed_vote_effect: Dictionary = vote_wait.duplicate(true)
	changed_vote_effect.rules.pending_prompt.options[0].effects = [
		{"type": "set_flag", "flag_id": "wrong_vote_effect", "value": true}
	]
	cases.append({"snapshot": changed_vote_effect, "label": "same-ID changed vote effect"})
	var changed_vote_rule: Dictionary = vote_wait.duplicate(true)
	changed_vote_rule.rules.pending_prompt.rule = "majority"
	changed_vote_rule.rules.active_vote.rule = "majority"
	cases.append({"snapshot": changed_vote_rule, "label": "changed vote rule"})
	var changed_vote_quorum: Dictionary = vote_wait.duplicate(true)
	changed_vote_quorum.rules.pending_prompt.quorum = 2
	changed_vote_quorum.rules.active_vote.quorum = 2
	cases.append({"snapshot": changed_vote_quorum, "label": "changed vote quorum"})
	var changed_vote_tie: Dictionary = vote_wait.duplicate(true)
	changed_vote_tie.rules.pending_prompt.tie_policy = "first_submitted"
	changed_vote_tie.rules.active_vote.tie_policy = "first_submitted"
	cases.append({"snapshot": changed_vote_tie, "label": "changed vote tie policy"})
	var changed_vote_source: Dictionary = vote_wait.duplicate(true)
	changed_vote_source.rules.pending_prompt.source_id = "threshold_whisper"
	cases.append({"snapshot": changed_vote_source, "label": "changed vote source"})
	var receiver := VerticalSliceCoordinator.new()
	for test_case: Dictionary in cases:
		var stable: Dictionary = receiver.to_snapshot()
		_expect(
			not receiver.restore_snapshot(test_case.snapshot).accepted,
			"rejects %s before mutation" % test_case.label,
		)
		_expect(
			receiver.to_snapshot() == stable,
			"keeps receiver byte-equivalent after %s rejection" % test_case.label,
		)
	var resumed := VerticalSliceCoordinator.new()
	_expect(resumed.restore_snapshot(prompt_wait).accepted, "restores a real prompt wait")
	var revision: int = resumed.rules_session.pending_prompt.revision
	_expect(
		resumed.rules_session.submit_response(1, ["listen"], revision).accepted,
		"accepts the remaining response after wait restore",
	)
	_expect(resumed.advance_player_stage().accepted, "completes the restored stage")
	_expect(
		resumed.stage_index == 1 and resumed.stage_history.size() == 1,
		"completes the restored stage exactly once",
	)
	var resumed_vote := VerticalSliceCoordinator.new()
	_expect(resumed_vote.restore_snapshot(vote_wait).accepted, "restores a real vote wait")
	var vote_revision: int = resumed_vote.rules_session.pending_prompt.revision
	for seat: int in resumed_vote.active_seats():
		var option: String = "gallery" if seat % 2 == 1 else "vault"
		_expect(
			resumed_vote.rules_session.submit_response(seat, [option], vote_revision).accepted,
			"accepts vote response after wait restore for Seat %d" % seat,
		)
	_expect(resumed_vote.advance_player_stage().accepted, "completes the restored vote stage")
	_expect(
		resumed_vote.stage_index == 2 and resumed_vote.stage_history.size() == 2,
		"completes the restored vote stage exactly once",
	)


func _test_protected_reset_paths() -> void:
	var active := _initialized_coordinator(3, 9017)
	var old_rules: RulesSession = active.rules_session
	var old_roster: Array[int] = old_rules.participating_seats.duplicate()
	var reset_states: Array[Dictionary] = []
	active.lifecycle_changed.connect(
		func(state: Dictionary) -> void: reset_states.append(state.duplicate(true))
	)
	_expect(active.protected_reset_to_title().accepted, "resets ordinary active play")
	_expect(_is_clean_title(active), "clears every authority after active-play reset")
	_expect(
		(
			reset_states.size() == 1
			and reset_states[0].lifecycle == "boot_title"
			and reset_states[0].seat_count == 0
		),
		"emits one coherent final public reset state",
	)
	active.seat_manager.join_device(7, "fresh-reset-pad", "Fresh Fixture Pad")
	active.enter_lobby()
	_expect(
		(
			active.lifecycle == "lobby"
			and active.rules_session == null
			and old_rules.participating_seats == old_roster
		),
		"joins a fresh lobby without attaching the roster to old authority",
	)
	var waiting := _initialized_coordinator(3, 4706)
	_expect(waiting.advance_player_stage().waiting_for_players, "opens a reset probe prompt")
	_expect(
		not waiting.to_snapshot().stage_transaction.is_empty(),
		"retains a stage checkpoint before protected reset",
	)
	waiting.protected_reset_to_title()
	_expect(_is_clean_title(waiting), "clears an in-progress wait and checkpoint")
	var room := _initialized_coordinator(3, 6201, false)
	var old_bridge: CompanionBridge = room.companion_bridge
	_expect(old_bridge.create_room("reset_room", "RSET3").accepted, "opens reset probe room")
	var transport := CompanionFakeTransport.new(old_bridge)
	_expect(transport.connect_client("reset_claimed").accepted, "joins reset probe client")
	_expect(transport.approve_client("reset_claimed", 1).accepted, "approves reset claim")
	_expect(
		transport.send_intent("reset_claimed", "private_reveal_ack", "reset_ack", {}, 1).accepted,
		"populates reset acknowledgement cache",
	)
	room.protected_reset_to_title()
	_expect(_is_clean_title(room), "removes authorities and seats after room reset")
	_expect(_bridge_is_fully_discarded(old_bridge), "closes and clears the reset probe room")
	var slice_view := VerticalSliceView.new()
	slice_view._ready()
	slice_view.present(waiting.public_state(), waiting.seat_manager.get_seats())
	var title: Label = slice_view.get("_title")
	_expect(
		slice_view.visible and title.text == "TERROR TURN",
		"presents the title after the protected reset",
	)
	slice_view.free()
	var main = MAIN_SCRIPT.new()
	var integration := _initialized_coordinator(3, 9017)
	var input_lab := InputDisplayLab.new()
	input_lab._ready()
	var integration_view := VerticalSliceView.new()
	integration_view._ready()
	var sandbox := ExplorationSandbox.new()
	main.set("_coordinator", integration)
	main.set("_seats", integration.seat_manager)
	main.set("_ui", input_lab)
	main.set("_slice_view", integration_view)
	main.set("_sandbox", sandbox)
	main.set("_developer_lab", true)
	input_lab.visible = true
	integration_view.present(integration.public_state(), integration.seat_manager.get_seats(), true)
	main.call("_perform_protected_reset")
	var integration_title: Label = integration_view.get("_title")
	_expect(not main.get("_developer_lab"), "clears developer-lab mode during protected reset")
	_expect(not input_lab.visible, "hides InputDisplayLab during protected reset")
	_expect(main.get("_sandbox") == null, "destroys the sandbox during protected reset")
	_expect(
		integration_view.visible and integration_title.text == "TERROR TURN",
		"shows the normal title after resetting from developer-lab presentation",
	)
	_expect(_is_clean_title(integration), "keeps developer-lab reset authority state coherent")
	integration.seat_manager.join_device(8, "post-lab-reset-pad", "Fresh Fixture Pad")
	_expect(
		integration.enter_lobby().accepted and integration.lifecycle == "lobby",
		"starts a fresh lobby after developer-lab protected reset",
	)
	input_lab.free()
	integration_view.free()
	main.free()


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
	var accepted_entry: Dictionary = coordinator._selection.entry.duplicate(true)
	coordinator._selection.entry.package_sha256 = "0".repeat(64)
	_expect(
		not coordinator.rematch().accepted,
		"rejects a failed rematch candidate",
	)
	_expect(
		coordinator.to_snapshot() == before_failed and old_bridge.room_open,
		"leaves the ending session and open room untouched after failed rematch",
	)
	coordinator._selection.entry = accepted_entry
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
	_expect(
		restore_old_bridge.create_room("restore_room", "RSTR3").accepted,
		"opens the valid restore cleanup probe room",
	)
	var restore_transport := CompanionFakeTransport.new(restore_old_bridge)
	_expect(
		restore_transport.connect_client("restore_claimed").accepted,
		"adds a restore cleanup claim request",
	)
	_expect(
		restore_transport.approve_client("restore_claimed", 1).accepted,
		"approves the restore cleanup claim",
	)
	_expect(
		(
			restore_transport
			. send_intent("restore_claimed", "private_reveal_ack", "restore_cached_ack", {}, 1)
			. accepted
		),
		"populates the restore cleanup acknowledgement cache",
	)
	_expect(
		restore_transport.connect_client("restore_pending").accepted,
		"retains a pending restore cleanup client",
	)
	var restore_before: Dictionary = restore_old_bridge.diagnostics()
	_expect(
		(
			restore_old_bridge.room_open
			and restore_before.pending_clients > 0
			and not restore_before.seat_claims.is_empty()
			and restore_before.connected_client_records > 0
			and restore_before.client_sequence_entries > 0
			and restore_before.ack_cache_entries > 0
			and restore_before.ack_order_entries > 0
			and restore_before.sequence > 0
			and not restore_before.history.is_empty()
		),
		"proves the old room contains real transport and acknowledgement state",
	)
	_expect(coordinator.restore_snapshot(source_snapshot).accepted, "restores a detached candidate")
	_expect(
		_bridge_is_fully_discarded(restore_old_bridge),
		"closes and fully discards the old room before restored replacement",
	)
	var replacement: Dictionary = coordinator.companion_bridge.diagnostics()
	_expect(
		(
			replacement.room_state == "closed"
			and coordinator.companion_bridge.room_id.is_empty()
			and replacement.join_code.is_empty()
			and replacement.pending_clients == 0
			and replacement.seat_claims.is_empty()
			and replacement.connected_client_records == 0
			and replacement.client_sequence_entries == 0
			and replacement.ack_cache_entries == 0
			and replacement.ack_order_entries == 0
			and replacement.sequence == 0
			and replacement.history.is_empty()
		),
		"keeps the replacement companion bridge clean and optional",
	)


func _is_clean_title(coordinator: VerticalSliceCoordinator) -> bool:
	var snapshot: Dictionary = coordinator.to_snapshot()
	return (
		coordinator.lifecycle == "boot_title"
		and coordinator.active_seats().is_empty()
		and coordinator.manifest.is_empty()
		and coordinator.board_state == null
		and coordinator.rules_session == null
		and coordinator.director_runtime == null
		and coordinator.role_session == null
		and coordinator.companion_bridge == null
		and coordinator.pawn_registry.get_pawns().is_empty()
		and snapshot.stage_history.is_empty()
		and snapshot.stage_transaction.is_empty()
		and snapshot.operation_index == 0
		and snapshot.stage_index == -1
		and not snapshot.paused
		and snapshot.last_director_decision.is_empty()
		and snapshot.last_director_application.is_empty()
	)


func _bridge_is_fully_discarded(bridge: CompanionBridge) -> bool:
	var diagnostics: Dictionary = bridge.diagnostics()
	var counters_clear: bool = true
	for count: int in diagnostics.counters.values():
		counters_clear = counters_clear and count == 0
	return (
		not bridge.room_open
		and bridge.room_id.is_empty()
		and diagnostics.join_code.is_empty()
		and diagnostics.pending_clients == 0
		and diagnostics.seat_claims.is_empty()
		and diagnostics.connected_clients == 0
		and diagnostics.connected_client_records == 0
		and diagnostics.client_sequence_entries == 0
		and diagnostics.ack_cache_entries == 0
		and diagnostics.ack_order_entries == 0
		and diagnostics.sequence == 0
		and diagnostics.history.is_empty()
		and counters_clear
		and diagnostics.stored_revision == diagnostics.last_authoritative_revision
	)


func _coordinator_with_seats(seat_count: int) -> VerticalSliceCoordinator:
	var coordinator := VerticalSliceCoordinator.new()
	for index: int in seat_count:
		coordinator.seat_manager.join_device(index, "fixture-%d" % index, "Fixture Pad")
	return coordinator


func _initialized_coordinator(
	seat_count: int, seed: int, complete_reveals: bool = true
) -> VerticalSliceCoordinator:
	var coordinator := _coordinator_with_seats(seat_count)
	coordinator.enter_lobby()
	coordinator.confirm_roster()
	coordinator.initialize_session(seed)
	coordinator.begin_tale()
	if complete_reveals:
		_complete_private_reveals(coordinator)
	return coordinator


func _complete_private_reveals(coordinator: VerticalSliceCoordinator) -> void:
	var flow: PrivateRevealFlow = coordinator.get("_private_reveal_flow")
	for _index: int in coordinator.active_seats().size():
		var seat_number: int = flow.current_seat()
		var opened: Dictionary = flow.submit(coordinator.role_session, seat_number, "confirm")
		var acknowledged: Dictionary = flow.submit(coordinator.role_session, seat_number, "confirm")
		_expect(
			opened.accepted and acknowledged.accepted, "completes reveal for Seat %d" % seat_number
		)
	_expect(flow.phase == PrivateRevealFlow.PHASE_COMPLETE, "completes the private reveal queue")


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
