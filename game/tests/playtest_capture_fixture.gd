extends SceneTree

var _coordinator := VerticalSliceCoordinator.new()


func _initialize() -> void:
	_configure.call_deferred()


func _configure() -> void:
	var capture_state: String = OS.get_environment("PLAYTEST_CAPTURE_STATE")
	if not capture_state in ["lobby", "prompt", "help", "ending_export"]:
		push_error("Unsupported playtest capture state")
		quit(2)
		return
	for index: int in 3:
		_coordinator.seat_manager.join_device(
			index, "synthetic-capture-pad-%d" % index, "Fixture Controller %d" % (index + 1)
		)
	_coordinator.enter_lobby()
	if capture_state != "lobby":
		_coordinator.confirm_roster()
		_coordinator.initialize_session(_coordinator.MANIFEST_PATH, 4706)
		_coordinator.begin_tale()
	if capture_state in ["prompt", "help"]:
		_coordinator.advance_player_stage()
	elif capture_state == "ending_export":
		while _coordinator.lifecycle == "active_tale":
			_coordinator.run_current_stage()
		_coordinator.review_ending()
	var view := VerticalSliceView.new()
	root.add_child(view)
	await process_frame
	view.present(_coordinator.public_state(), _coordinator.seat_manager.get_seats())
	if capture_state in ["help", "ending_export"]:
		var help := GuidedSessionHelp.new()
		root.add_child(help)
		await process_frame
		(
			help
			. open_help(
				_coordinator.public_state(),
				_coordinator.seat_manager.get_seats(),
				{"room_open": false, "connected_count": 0},
				capture_state == "ending_export",
			)
		)
		if capture_state == "ending_export":
			for _index: int in 3:
				help.handle_action("ui_navigate_right")
			help.present_export_result({"accepted": true})
	await create_timer(1.0).timeout
	quit()
