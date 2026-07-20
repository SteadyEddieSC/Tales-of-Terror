extends GutTest


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
