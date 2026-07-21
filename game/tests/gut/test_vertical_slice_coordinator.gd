extends GutTest

const MAIN_SCRIPT: Script = preload("res://src/main/main.gd")


func test_catalog_default_and_unknown_selection_are_atomic() -> void:
	var coordinator := VerticalSliceCoordinator.new()
	assert_eq(coordinator._selection.selected_tale_id(), TalePackage.LANTERN_HOUSE_ID)
	assert_eq(coordinator._selection.catalog_digest, TaleCatalog.PRODUCTION_DIGEST)
	var snapshot: Dictionary = coordinator.to_snapshot()
	var entry: Dictionary = coordinator._selection.entry.duplicate(true)
	assert_false(coordinator.select_tale("synthetic_unknown_tale").accepted)
	assert_eq(coordinator._selection.entry, entry)
	assert_eq(coordinator.to_snapshot(), snapshot)


func test_coordinator_rejects_out_of_order_lifecycle_without_mutation() -> void:
	var coordinator := VerticalSliceCoordinator.new()
	var before: Dictionary = coordinator.to_snapshot()
	var result: Dictionary = coordinator.begin_tale()
	assert_false(result.accepted)
	assert_eq(coordinator.to_snapshot(), before)


func test_no_phone_fixture_reaches_public_ending() -> void:
	var coordinator := VerticalSliceCoordinator.new()
	coordinator.seat_manager.join_device(-1, SeatManager.KEYBOARD_IDENTITY, "Keyboard")
	coordinator.enter_lobby()
	coordinator.confirm_roster()
	assert_true(coordinator.initialize_session().accepted)
	assert_true(coordinator.begin_tale().accepted)
	while coordinator.lifecycle == "active_tale":
		assert_true(coordinator.run_current_stage().accepted)
	assert_true(coordinator.review_ending().accepted)
	assert_eq(coordinator.lifecycle, "ending")
	assert_eq(
		coordinator.public_state().ending.privacy,
		"public_summary_only_private_details_require_controlled_reveal"
	)


func test_undeclared_existing_mode_is_rejected_atomically() -> void:
	var coordinator := VerticalSliceCoordinator.new()
	coordinator.seat_manager.join_device(-1, SeatManager.KEYBOARD_IDENTITY, "Keyboard")
	coordinator.enter_lobby()
	coordinator.confirm_roster()
	var before: Dictionary = coordinator.to_snapshot()
	assert_false(coordinator.initialize_session(4706, "hunted").accepted)
	assert_eq(coordinator.to_snapshot(), before)


func test_exploration_snapshot_preserves_pawn_and_occupancy() -> void:
	var coordinator := VerticalSliceCoordinator.new()
	coordinator.seat_manager.join_device(-1, SeatManager.KEYBOARD_IDENTITY, "Keyboard")
	coordinator.enter_lobby()
	coordinator.confirm_roster()
	assert_true(coordinator.initialize_session().accepted)
	assert_true(coordinator.begin_tale().accepted)
	var pawn: PawnState = coordinator.pawn_registry.get_by_seat(1)
	pawn.position = Vector2(1240.0, 500.0)
	coordinator.board_state.sync_occupancy(coordinator.pawn_registry.get_pawns())
	var restored := VerticalSliceCoordinator.new()
	assert_true(restored.restore_snapshot(coordinator.to_snapshot()).accepted)
	assert_eq(restored.pawn_registry.get_by_seat(1).position, pawn.position)
	assert_eq(restored.board_state.space_for_seat(1), "sealed_archive")
	assert_eq(restored.authority_digest(), coordinator.authority_digest())


func test_confirmation_cancel_retains_roster_and_can_retry() -> void:
	var coordinator := VerticalSliceCoordinator.new()
	coordinator.seat_manager.join_device(-1, SeatManager.KEYBOARD_IDENTITY, "Keyboard")
	assert_true(coordinator.enter_lobby().accepted)
	assert_true(coordinator.confirm_roster().accepted)
	var roster: Dictionary = coordinator.seat_manager.to_snapshot()
	assert_true(coordinator.cancel_setup().accepted)
	assert_eq(coordinator.lifecycle, "lobby")
	assert_eq(coordinator.seat_manager.to_snapshot(), roster)
	assert_null(coordinator.rules_session)
	assert_true(coordinator.confirm_roster().accepted)
	assert_true(coordinator.initialize_session().accepted)
	assert_eq(coordinator.lifecycle, "briefing")


func test_protected_reset_clears_waiting_session() -> void:
	var coordinator := VerticalSliceCoordinator.new()
	coordinator.seat_manager.join_device(-1, SeatManager.KEYBOARD_IDENTITY, "Keyboard")
	coordinator.enter_lobby()
	coordinator.confirm_roster()
	assert_true(coordinator.initialize_session().accepted)
	assert_true(coordinator.begin_tale().accepted)
	assert_true(coordinator.advance_player_stage().waiting_for_players)
	assert_false(coordinator.to_snapshot().stage_transaction.is_empty())
	assert_true(coordinator.protected_reset_to_title().accepted)
	assert_eq(coordinator.lifecycle, "boot_title")
	assert_true(coordinator.active_seats().is_empty())
	assert_null(coordinator.rules_session)
	assert_null(coordinator.companion_bridge)
	assert_true(coordinator.to_snapshot().stage_transaction.is_empty())


func test_real_prompt_wait_restores_and_completes_once() -> void:
	var coordinator := VerticalSliceCoordinator.new()
	coordinator.seat_manager.join_device(-1, SeatManager.KEYBOARD_IDENTITY, "Keyboard")
	coordinator.enter_lobby()
	coordinator.confirm_roster()
	coordinator.initialize_session()
	coordinator.begin_tale()
	assert_true(coordinator.advance_player_stage().waiting_for_players)
	var restored := VerticalSliceCoordinator.new()
	assert_true(restored.restore_snapshot(coordinator.to_snapshot()).accepted)
	assert_true(
		(
			restored
			. rules_session
			. submit_response(1, ["listen"], restored.rules_session.pending_prompt.revision)
			. accepted
		)
	)
	assert_true(restored.advance_player_stage().accepted)
	assert_eq(restored.stage_index, 1)
	assert_eq(restored.stage_history.size(), 1)


func test_protected_reset_clears_developer_lab_presentation() -> void:
	var coordinator := VerticalSliceCoordinator.new()
	coordinator.seat_manager.join_device(-1, SeatManager.KEYBOARD_IDENTITY, "Keyboard")
	coordinator.enter_lobby()
	coordinator.confirm_roster()
	coordinator.initialize_session()
	coordinator.begin_tale()
	var main = MAIN_SCRIPT.new()
	var input_lab := InputDisplayLab.new()
	input_lab._ready()
	var view := VerticalSliceView.new()
	view._ready()
	main.set("_coordinator", coordinator)
	main.set("_seats", coordinator.seat_manager)
	main.set("_ui", input_lab)
	main.set("_slice_view", view)
	main.set("_developer_lab", true)
	input_lab.visible = true
	main.call("_perform_protected_reset")
	var title: Label = view.get("_title")
	assert_false(main.get("_developer_lab"))
	assert_false(input_lab.visible)
	assert_true(view.visible)
	assert_eq(title.text, "TERROR TURN")
	assert_eq(coordinator.lifecycle, "boot_title")
	assert_true(coordinator.active_seats().is_empty())
	assert_null(coordinator.rules_session)
	input_lab.free()
	view.free()
	main.free()


func test_resumable_prompt_requires_exact_authored_content() -> void:
	var coordinator := VerticalSliceCoordinator.new()
	coordinator.seat_manager.join_device(-1, SeatManager.KEYBOARD_IDENTITY, "Keyboard")
	coordinator.enter_lobby()
	coordinator.confirm_roster()
	coordinator.initialize_session()
	coordinator.begin_tale()
	assert_true(coordinator.advance_player_stage().waiting_for_players)
	var changed: Dictionary = coordinator.to_snapshot()
	changed.rules.pending_prompt.options[0].text = "Changed under the same option ID"
	var receiver := VerticalSliceCoordinator.new()
	var stable: Dictionary = receiver.to_snapshot()
	assert_false(receiver.restore_snapshot(changed).accepted)
	assert_eq(receiver.to_snapshot(), stable)


func test_manifest_v1_rejects_valid_but_wrong_operation_data() -> void:
	var manifest: Dictionary = VerticalSliceManifest.load_file(
		"res://data/scenarios/lantern_house_vertical_slice_v1.json"
	)
	manifest.stages[0].operations[0].event_id = "gallery_council"
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
	assert_false(failures.is_empty())
