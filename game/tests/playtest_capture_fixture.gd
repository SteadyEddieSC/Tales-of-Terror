extends SceneTree

const MAIN_SCENE: PackedScene = preload("res://src/main/Main.tscn")
const BUTTON_A: int = 0
const BUTTON_X: int = 2
const DPAD_RIGHT: int = 14


func _initialize() -> void:
	_configure.call_deferred()


func _configure() -> void:
	var capture_state: String = OS.get_environment("PLAYTEST_CAPTURE_STATE")
	if not capture_state in ["lobby", "prompt", "help", "ending_export"]:
		push_error("Unsupported playtest capture state")
		quit(2)
		return
	var width: int = OS.get_environment("PLAYTEST_CAPTURE_WIDTH").to_int()
	var height: int = OS.get_environment("PLAYTEST_CAPTURE_HEIGHT").to_int()
	if width <= 0 or height <= 0:
		push_error("Capture dimensions must be positive")
		quit(2)
		return
	root.size = Vector2i(width, height)
	var main: Control = MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	var device_count: int = 8 if capture_state == "prompt" else 3
	var registry: DeviceRegistry = main.get("_devices")
	var devices: Dictionary = {}
	for device_id: int in device_count:
		devices[device_id] = {
			"device_id": device_id,
			"name": "Synthetic Controller %d" % (device_id + 1),
			"guid": "synthetic-guid-%d" % device_id,
			"identity": "synthetic-identity-%d" % device_id,
		}
	registry.set("_devices", devices)
	registry.devices_changed.emit(registry.get_devices())
	for device_id: int in device_count:
		await _press_button(main, device_id, BUTTON_A)
	if capture_state != "lobby":
		await _press_button(main, 0, BUTTON_A)
		await _press_button(main, 0, BUTTON_A)
		await _press_button(main, 0, BUTTON_A)
		await _press_button(main, 0, BUTTON_A)
		if not is_instance_valid(main.get("_sandbox")):
			push_error("Full-route capture did not compose ExplorationSandbox")
			quit(4)
			return
	if capture_state == "prompt":
		var coordinator: VerticalSliceCoordinator = main.get("_coordinator")
		var pending: Dictionary = coordinator.rules_session.pending_prompt
		for seat_number: int in pending.eligible_seats:
			coordinator.rules_session.submit_response(
				seat_number, [pending.options[0].id], pending.revision
			)
		coordinator.run_current_stage()
		coordinator.advance_player_stage()
		await process_frame
	elif capture_state == "help":
		await _press_button(main, 0, BUTTON_X)
	elif capture_state == "ending_export":
		var coordinator: VerticalSliceCoordinator = main.get("_coordinator")
		var guard: int = 0
		while coordinator.lifecycle == "active_tale" and guard < 8:
			var pending: Dictionary = coordinator.rules_session.pending_prompt
			if not pending.is_empty():
				for seat_number: int in pending.eligible_seats:
					coordinator.rules_session.submit_response(
						seat_number, [pending.options[0].id], pending.revision
					)
			var result: Dictionary = coordinator.run_current_stage()
			if not result.accepted:
				push_error("Could not advance capture route: %s" % result.get("reason", ""))
				quit(4)
				return
			guard += 1
			await process_frame
		await _press_button(main, 0, BUTTON_A)
		main.set("_report_writer", PlaytestMemoryWriter.new())
		await _press_button(main, 0, BUTTON_X)
		for _page: int in 4:
			await _press_button(main, 0, DPAD_RIGHT)
		await _press_button(main, 0, BUTTON_A)
	await create_timer(0.75).timeout
	await process_frame
	var image: Image = root.get_viewport().get_texture().get_image()
	if image.get_width() != width or image.get_height() != height:
		image.resize(width, height, Image.INTERPOLATE_NEAREST)
	var output_path: String = OS.get_environment("PLAYTEST_CAPTURE_OUTPUT")
	var error: Error = image.save_png(output_path)
	if error != OK:
		push_error("Could not save playtest capture: %s" % error_string(error))
		quit(3)
		return
	print(
		(
			"PLAYTEST_CAPTURE state=%s dimensions=%dx%d output=%s"
			% [capture_state, image.get_width(), image.get_height(), output_path]
		)
	)
	quit()


func _press_button(main: Control, device_id: int, button_index: int) -> void:
	var pressed := InputEventJoypadButton.new()
	pressed.device = device_id
	pressed.button_index = button_index
	pressed.pressed = true
	main._input(pressed)
	await process_frame
	var released := InputEventJoypadButton.new()
	released.device = device_id
	released.button_index = button_index
	released.pressed = false
	main._input(released)
	await process_frame
