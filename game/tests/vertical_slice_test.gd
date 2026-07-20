extends SceneTree

const MANIFEST_PATH: String = "res://data/scenarios/lantern_house_vertical_slice_v1.json"

var _failures: int = 0


func _initialize() -> void:
	_test_manifest_validation()
	_test_lifecycle_and_atomic_initialization()
	_test_supported_seats_and_fallback()
	_test_shared_screen_and_optional_companion()
	_test_complete_fixture_and_privacy()
	_test_snapshot_replay_and_rematch()
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
	_expect(initial.seat_manager == coordinator.to_snapshot().seat_manager, "retains stable seats")


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


func _expect(condition: bool, description: String) -> void:
	if not condition:
		_failures += 1
		push_error("FAILED: %s" % description)
