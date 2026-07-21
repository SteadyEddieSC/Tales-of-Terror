extends SceneTree

const MAIN_SCENE: PackedScene = preload("res://src/main/Main.tscn")
const BUTTON_A: int = 0
const BUTTON_B: int = 1
const BUTTON_X: int = 2
const BUTTON_Y: int = 3
const DPAD_RIGHT: int = 14

var _failures: int = 0
var _current_main: Control


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await _test_controller_first_complete_route_and_rematch_report()
	await _test_integrated_return_to_title_report()
	await _test_integrated_protected_reset_report()
	await _test_keyboard_join_and_confirmation_fallback()
	await _test_rendered_guidance_and_action_map()
	if _failures == 0:
		print("Main-route controller, guidance, and report integration tests passed")
	quit(_failures)


func _test_controller_first_complete_route_and_rematch_report() -> void:
	var main: Control = await _new_main(2)
	var coordinator: VerticalSliceCoordinator = main.get("_coordinator")
	await _press_button(0, BUTTON_A)
	_expect(coordinator.lifecycle == "lobby", "first controller A enters the lobby")
	_expect(coordinator.active_seats().size() == 1, "first controller A claims one stable seat")
	_expect(
		coordinator.lifecycle != "confirmation",
		"initial join event never confirms the roster on the same event",
	)
	await _press_button(1, BUTTON_A)
	_expect(coordinator.lifecycle == "lobby", "unowned second controller joins before confirmation")
	_expect(coordinator.active_seats().size() == 2, "second controller owns a second stable seat")
	await _press_button(0, BUTTON_A)
	_expect(coordinator.lifecycle == "confirmation", "owned controller A confirms the roster")
	_expect(coordinator.active_seats().size() == 2, "confirmation retains the locked roster")
	await _press_button(0, BUTTON_A)
	_expect(coordinator.lifecycle == "briefing", "controller confirmation prepares the session")
	_expect(coordinator.rules_session != null, "prepared session has native rules authority")
	await _press_button(0, BUTTON_A)
	_expect(coordinator.lifecycle == "active_tale", "controller confirmation begins the tale")
	_expect(is_instance_valid(main.get("_sandbox")), "normal route composes ExplorationSandbox")
	await _run_active_tale(coordinator)
	_expect(coordinator.lifecycle == "terminal", "normal route reaches terminal")
	_expect(not is_instance_valid(main.get("_sandbox")), "terminal removes the active sandbox")
	await _press_button(0, BUTTON_A)
	_expect(coordinator.lifecycle == "ending", "owned controller A opens the ending")
	var ending_authority: String = coordinator.authority_digest()
	var ending_history: String = coordinator.public_history_digest()
	var report: PlaytestReport = main.get("_last_report")
	_expect(report != null and report.is_finalized(), "ending preserves an exportable report")
	_expect(
		report.to_report().session.completion_reason == "ending",
		"ending report records completion separately",
	)
	_expect(
		report.to_report().session.post_ending_disposition == "pending",
		"ending export honestly records a pending disposition",
	)
	var writer := PlaytestMemoryWriter.new()
	main.set("_report_writer", writer)
	await _press_button(0, BUTTON_X)
	for _page: int in 4:
		await _press_button(0, DPAD_RIGHT)
	await _press_button(0, BUTTON_A)
	_expect(not writer.json_text.is_empty(), "ending exports JSON through the actual help route")
	_expect(
		not writer.markdown_text.is_empty(), "ending exports Markdown through the actual help route"
	)
	_expect(
		coordinator.authority_digest() == ending_authority,
		"ending export leaves gameplay authority unchanged",
	)
	_expect(
		coordinator.public_history_digest() == ending_history,
		"ending export leaves public history unchanged",
	)
	_expect(_json_markdown_consistent(report), "ending JSON and Markdown are consistent")
	await _press_button(0, BUTTON_X)
	await _press_button(0, BUTTON_A)
	_expect(coordinator.lifecycle == "briefing", "ending controller A permits a clean rematch")
	_expect(
		report.to_report().session.post_ending_disposition == "rematch",
		"rematch updates only the bounded post-ending disposition",
	)
	_expect(main.get("_last_report") == report, "rematch does not replace the completed report")
	_expect(main.get("_active_report") != null, "rematch begins a distinct active report")
	_expect(
		_stored_digests_match(report, ending_authority, ending_history),
		"rematch preserves ending digests"
	)
	_expect(_json_markdown_consistent(report), "rematch disposition stays JSON/Markdown consistent")
	await _free_main(main)


func _test_integrated_return_to_title_report() -> void:
	var main: Control = await _main_at_ending()
	var coordinator: VerticalSliceCoordinator = main.get("_coordinator")
	var ending_authority: String = coordinator.authority_digest()
	var ending_history: String = coordinator.public_history_digest()
	var report: PlaytestReport = main.get("_last_report")
	await _press_button(0, BUTTON_B)
	_expect(coordinator.lifecycle == "boot_title", "ending B returns to title")
	_expect(
		report.to_report().session.post_ending_disposition == "return_to_title",
		"return-to-title disposition is recorded on the completed ending report",
	)
	_expect(main.get("_last_report") == report, "return to title keeps the report available")
	_expect(main.get("_active_report") != null, "return to title starts a separate clean report")
	_expect(
		_stored_digests_match(report, ending_authority, ending_history),
		"return-to-title report retains the completed authority and history digests",
	)
	_expect(_json_markdown_consistent(report), "return-to-title JSON and Markdown are consistent")
	await _free_main(main)


func _test_integrated_protected_reset_report() -> void:
	var main: Control = await _new_main(1)
	var coordinator: VerticalSliceCoordinator = main.get("_coordinator")
	for _press: int in 4:
		await _press_button(0, BUTTON_A)
	_expect(
		coordinator.lifecycle == "active_tale",
		"reset fixture reaches the active tale by controller"
	)
	var active_authority: String = coordinator.authority_digest()
	var active_history: String = coordinator.public_history_digest()
	await _hold_reset_button(0)
	_expect(coordinator.lifecycle == "boot_title", "controller Y protected reset returns to title")
	var report: PlaytestReport = main.get("_last_report")
	_expect(
		report != null and report.is_finalized(),
		"protected reset keeps a finalized report available"
	)
	_expect(
		report.to_report().session.completion_reason == "reset",
		"protected reset records reset as the completion reason",
	)
	_expect(
		report.to_report().session.post_ending_disposition == "not_applicable",
		"pre-ending reset does not misclassify a post-ending disposition",
	)
	_expect(
		_stored_digests_match(report, active_authority, active_history),
		"protected reset report retains the pre-reset authority and history digests",
	)
	_expect(main.get("_active_report") != null, "protected reset starts a distinct clean report")
	_expect(_json_markdown_consistent(report), "protected-reset JSON and Markdown are consistent")
	await _free_main(main)


func _test_keyboard_join_and_confirmation_fallback() -> void:
	var main: Control = await _new_main(0)
	var coordinator: VerticalSliceCoordinator = main.get("_coordinator")
	await _press_key(KEY_ENTER)
	_expect(coordinator.lifecycle == "lobby", "first Enter claims the keyboard stable seat")
	_expect(coordinator.active_seats().size() == 1, "initial Enter does not double-advance")
	await _press_key(KEY_ENTER)
	_expect(coordinator.lifecycle == "confirmation", "owned keyboard Enter confirms the roster")
	await _press_key(KEY_SPACE)
	_expect(coordinator.lifecycle == "briefing", "Space remains the keyboard confirmation fallback")
	await _free_main(main)


func _test_rendered_guidance_and_action_map() -> void:
	_expect(_action_has_joy_button("player_join", BUTTON_A), "player_join maps controller A")
	_expect(_action_has_joy_button("ui_confirm", BUTTON_A), "ui_confirm maps controller A")
	_expect(_action_has_key("player_join", KEY_ENTER), "player_join maps Enter")
	_expect(_action_has_key("ui_confirm", KEY_ENTER), "ui_confirm maps Enter")
	_expect(_action_has_key("ui_confirm", KEY_SPACE), "Space remains a confirmation fallback")
	_expect(_action_has_joy_button("help_accessibility", BUTTON_X), "controller X maps Help")
	_expect(_action_has_joy_button("interact", BUTTON_A), "interact maps every controller A")
	_expect(
		_action_has_joy_button("ui_navigate_right", DPAD_RIGHT),
		"navigation maps every controller D-pad",
	)
	_expect(_action_has_key("help_accessibility", KEY_H), "keyboard H maps Help")
	_expect(_action_has_key("diagnostic_test", KEY_T), "keyboard T maps diagnostics")
	_expect(
		not _action_has_joy_button("diagnostic_test", BUTTON_X),
		"controller X is never described or mapped as diagnostics",
	)
	var main: Control = await _new_main(1)
	var coordinator: VerticalSliceCoordinator = main.get("_coordinator")
	await _press_button(0, BUTTON_A)
	var view: VerticalSliceView = main.get("_slice_view")
	var footer: Label = view.get("_footer")
	_expect("OWNED SEAT CONFIRMS" in footer.text, "rendered lobby restores roster confirmation")
	_expect("SPACE: LOCK ROSTER" in footer.text, "rendered lobby shows keyboard roster lock")
	for _press: int in 3:
		await _press_button(0, BUTTON_A)
	var sandbox: ExplorationSandbox = main.get("_sandbox")
	var title: Label = sandbox.get("_title_label")
	var message: Label = sandbox.get("_message_label")
	var reset: Label = sandbox.get("_reset_label")
	_expect(
		PlaytestReport.release_id() in title.text, "sandbox uses the single v0.1.2 release source"
	)
	_expect("HELP: X / H" in message.text, "sandbox renders X as Help")
	_expect("DIAGNOSTICS: T" in message.text, "sandbox renders T-only diagnostics")
	_expect(not "DIAGNOSTICS: X" in message.text, "sandbox never renders X as diagnostics")
	_expect(
		"RETURN TO TITLE" in reset.text, "protected reset accurately names the title destination"
	)
	var active_rect: Rect2 = VerticalSliceView.active_panel_rect(Vector2(960, 540), 24)
	var top_layout: Dictionary = ExplorationSandbox.calculate_top_hud_layout(Vector2(960, 540), 24)
	var bottom_layout: Dictionary = ExplorationSandbox.calculate_bottom_hud_layout(
		Vector2(960, 540), 24
	)
	var rules_rect: Rect2 = RulesHud.calculate_panel_rect(Vector2(960, 540), 24)
	_expect(
		not active_rect.intersects(top_layout.title), "active guidance clears the sandbox title"
	)
	_expect(
		not active_rect.intersects(top_layout.separation), "active guidance clears regroup status"
	)
	_expect(
		not active_rect.intersects(bottom_layout.status), "active guidance clears active controls"
	)
	_expect(
		not active_rect.intersects(bottom_layout.reset), "active guidance clears protected reset"
	)
	_expect(not active_rect.intersects(rules_rect), "active guidance clears the prompt/vote HUD")
	var waiting_state: Dictionary = coordinator.public_state()
	waiting_state.operation_index = 1
	waiting_state.stage = {
		"operations": [{"type": "submit_vote"}], "id": "bounded_vote", "title": "Bounded Vote"
	}
	var statuses: Array[Dictionary] = []
	var seats: Array[Dictionary] = []
	for seat_number: int in range(1, 9):
		statuses.append({"seat": seat_number, "submitted": false})
		seats.append({"seat_number": seat_number, "state": SeatManager.SeatState.ACTIVE})
	waiting_state.rules = {"prompt": {"response_status": statuses}}
	var guidance: String = GuidedSessionHelp.guidance_for_state(waiting_state, seats)
	_expect("Vote progress 0/8" in guidance, "eight-seat vote progress remains explicit")
	_expect("Seat 1" in guidance and "Seat 8" in guidance, "1–8 waiting guidance remains complete")
	view.present(waiting_state, seats)
	var body: Label = view.get("_body")
	_expect(
		body.max_lines_visible == 3 and body.clip_text,
		"compact guidance uses a bounded three-line region"
	)
	var slice_layer: CanvasLayer = main.get("_slice_layer")
	var help_layer: CanvasLayer = main.get("_help_layer")
	_expect(
		slice_layer.layer > ExplorationSandbox.HUD_CANVAS_LAYER,
		"guidance renders above sandbox HUD",
	)
	_expect(help_layer.layer > slice_layer.layer, "help renders above normal guidance")
	await _free_main(main)


func _main_at_ending() -> Control:
	var main: Control = await _new_main(1)
	for _press: int in 4:
		await _press_button(0, BUTTON_A)
	var coordinator: VerticalSliceCoordinator = main.get("_coordinator")
	await _run_active_tale(coordinator)
	await _press_button(0, BUTTON_A)
	_expect(
		coordinator.lifecycle == "ending", "report fixture reaches ending through controller input"
	)
	return main


func _new_main(device_count: int) -> Control:
	var main: Control = MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	_current_main = main
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
	await process_frame
	return main


func _run_active_tale(coordinator: VerticalSliceCoordinator) -> void:
	var guard: int = 0
	while coordinator.lifecycle == "active_tale" and guard < 8:
		var prompt: Dictionary = coordinator.rules_session.pending_prompt
		if not prompt.is_empty():
			var option_id: String = prompt.options[0].id
			for seat_number: int in prompt.eligible_seats:
				coordinator.rules_session.submit_response(seat_number, [option_id], prompt.revision)
		var result: Dictionary = coordinator.run_current_stage()
		_expect(result.accepted, "fixture advances authored active stage %d" % guard)
		guard += 1
		await process_frame
	_expect(guard < 8, "active route reaches terminal within the authored stage bound")


func _press_button(device_id: int, button_index: int) -> void:
	var pressed := InputEventJoypadButton.new()
	pressed.device = device_id
	pressed.button_index = button_index
	pressed.pressed = true
	_current_main._input(pressed)
	await process_frame
	var released := InputEventJoypadButton.new()
	released.device = device_id
	released.button_index = button_index
	released.pressed = false
	_current_main._input(released)
	await process_frame


func _hold_reset_button(device_id: int) -> void:
	var pressed := InputEventJoypadButton.new()
	pressed.device = device_id
	pressed.button_index = BUTTON_Y
	pressed.pressed = true
	Input.parse_input_event(pressed)
	await create_timer(1.7).timeout
	var released := InputEventJoypadButton.new()
	released.device = device_id
	released.button_index = BUTTON_Y
	released.pressed = false
	Input.parse_input_event(released)
	await process_frame


func _press_key(physical_keycode: Key) -> void:
	var pressed := InputEventKey.new()
	pressed.physical_keycode = physical_keycode
	pressed.pressed = true
	_current_main._input(pressed)
	await process_frame
	var released := InputEventKey.new()
	released.physical_keycode = physical_keycode
	released.pressed = false
	_current_main._input(released)
	await process_frame


func _action_has_joy_button(action: StringName, button_index: int) -> bool:
	for event: InputEvent in InputMap.action_get_events(action):
		if (
			event is InputEventJoypadButton
			and event.device == -1
			and event.button_index == button_index
		):
			return true
	return false


func _action_has_key(action: StringName, physical_keycode: Key) -> bool:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey and event.physical_keycode == physical_keycode:
			return true
	return false


func _stored_digests_match(
	report: PlaytestReport, authority_digest: String, public_history_digest: String
) -> bool:
	var outcome: Dictionary = report.to_report().outcome
	return (
		outcome.authority_digest == authority_digest
		and outcome.public_history_digest == public_history_digest
	)


func _json_markdown_consistent(report: PlaytestReport) -> bool:
	var value: Variant = JSON.parse_string(report.to_json())
	if not value is Dictionary:
		return false
	var session: Dictionary = value.session
	var outcome: Dictionary = value.outcome
	var markdown: String = report.to_markdown()
	return (
		("- Schema: %d" % value.schema_version) in markdown
		and ("- Completion: %s" % session.completion_reason) in markdown
		and ("- Post-ending disposition: %s" % session.post_ending_disposition) in markdown
		and outcome.authority_digest in markdown
		and outcome.public_history_digest in markdown
		and PlaytestReport.validate_schema(report.to_report()).accepted
	)


func _free_main(main: Control) -> void:
	main.queue_free()
	await process_frame
	_current_main = null


func _expect(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		_failures += 1
		push_error("FAIL: " + description)
