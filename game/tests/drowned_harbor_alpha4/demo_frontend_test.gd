extends SceneTree

const DEMO_SCENE = preload("res://src/tales/drowned_harbor/alpha4/DemoMain.tscn")

var _demo: DrownedHarborDemoMain
var _failures: Array[String] = []
var _captures: bool = false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_captures = OS.get_cmdline_user_args().has("--capture")
	root.size = Vector2i(960, 540)
	for count: int in [1, 4, 8]:
		await _play_scene(count)
	await _test_controller_restore()
	if _failures.is_empty():
		print(
			(
				"Alpha.4 frontend: keyboard title/lobby/private/play/save/restore/ending/rematch "
				+ "passed at 1, 4, 8 seats."
			)
		)
		quit(0)
	else:
		for failure: String in _failures:
			push_error(failure)
		quit(1)


func _play_scene(count: int) -> void:
	_demo = DEMO_SCENE.instantiate()
	root.add_child(_demo)
	await process_frame
	await _capture("title", count)
	await _press(KEY_DOWN)
	await _press(KEY_UP)
	await _press(KEY_P)
	await _pick("settings")
	await _press(KEY_H)
	await _press(KEY_ESCAPE)
	_check(_demo._page == "settings", "nested help returns to settings")
	await _press(KEY_ESCAPE)
	_check(_demo._page == "pause", "settings returns to originating pause")
	await _pick("resume")
	_check(
		_demo._page == "title" and _demo.session == null, "title pause cannot enter an absent game"
	)
	await _press(KEY_ENTER)
	_check(_demo._page == "lobby", "first confirm enters lobby")
	for extra: int in count - 1:
		await _press(KEY_J)
	_check(_demo.input_adapter.stable_seats().size() == count, "keyboard seats joined")
	await _capture("lobby", count)
	await _pick("setup")
	await _pick("begin")
	_check(_demo._page == "intro", "setup starts intro")
	await _pick("intro_done")
	for index: int in count:
		_check(_demo._page == "shield", "private hand starts shielded")
		await _pick("open_private")
		_check(_demo._page == "private", "authorized input opens own private hand")
		await _capture("private", count)
		await _pick("next_private")
		_check(_demo._private_tab == 1, "private allegiance has a readable second page")
		await _capture("allegiance", count)
		if index == 0:
			await _press(KEY_P)
			await _pick("settings")
			await _press(KEY_ESCAPE)
			await _pick("resume")
			_check(
				_demo._page == "shield" and _demo._ceremony,
				"nested private overlays resume behind shield without skipping ceremony"
			)
			await _pick("open_private")
			await _pick("next_private")
			await _press(KEY_ESCAPE)
			_check(_demo._page == "shield", "back immediately shields private text")
			_check(
				_demo._view.find_children("*", "Label", true, false).all(
					func(label: Label) -> bool: return not label.text.contains("ALLEGIANCE")
				),
				"private labels are removed from the scene tree"
			)
			await _pick("open_private")
			await _pick("next_private")
		await _pick("close_private")
	_check(_demo._page == "game", "private ceremony reaches game")
	await _capture("low_tide", count)
	if count == 8:
		_demo._large_text = true
		_demo._apply_settings()
		_demo._refresh()
		await _capture("large_low_tide", count)
		_demo._large_text = false
		_demo._apply_settings()
		_demo._refresh()
	var captured: Dictionary = {}
	for step: int in 128:
		if _demo._page == "results":
			break
		if _demo.session == null:
			_check(false, "Tale unexpectedly missing")
			break
		var state: Dictionary = _demo.session.public_view()
		if not captured.has(state.stage):
			captured[state.stage] = true
			await _capture(state.stage, count)
		if state.stage == "epilogue":
			await _press(KEY_V)
			await _pick("open_private")
			await _pick("next_private")
			_check(
				_demo._model().subtitle.contains("Your account is still being written."),
				"epilogue keeps private objective pending until rules evaluate completion"
			)
			await _pick("close_private")
		if step == 2:
			await _save_restore()
		if state.actions.is_empty():
			_check(false, "UI has no legal action at " + state.stage)
			break
		var chosen: String = state.actions[0].id
		var priorities: Array[String] = [
			"search_manifest", "search_wreck", "aid_resident", "shelter"
		]
		if state.stage == "bellhouse":
			priorities = ["follow_names"]
		elif state.stage == "council":
			priorities = ["vote_seal"]
		elif state.stage == "flood":
			priorities = ["salt_ward", "shelter"]
		elif state.stage == "last_light":
			priorities = ["final_seal"]
		for preferred: String in priorities:
			if state.actions.any(func(row: Dictionary) -> bool: return row.id == preferred):
				chosen = preferred
				break
		await _pick(chosen)
		_check(_demo.session.public_view().revision > state.revision, "UI commits displayed action")
	_check(_demo._page == "results", "whole frontend route reaches results")
	await _capture("results", count)
	await _press(KEY_V)
	await _pick("open_private")
	await _pick("next_private")
	var own: Dictionary = _demo.session.private_view(_demo._private_seat)
	var objective_result: String = (
		"Objective fulfilled." if own.get("objective_complete", false) else "Objective unfulfilled."
	)
	_check(
		_demo._model().subtitle.contains(objective_result),
		"completed Tale displays the evaluated private objective result"
	)
	await _pick("close_private")
	await _pick("rematch")
	_check(_demo._page == "intro", "rematch returns to new intro")
	_check(_demo.session.public_view().revision == 0, "rematch clears prior decisions")
	_demo.free()
	await process_frame


func _save_restore() -> void:
	var before: Dictionary = _demo.session.snapshot()
	await _press(KEY_P)
	_check(_demo._page == "pause", "pause opens")
	await _capture("pause", 1)
	await _pick("save")
	await _pick("inventory")
	await _capture("inventory", 1)
	await _pick("next_inventory")
	_check(_demo._inventory_tab == 1, "inventory provides a separate readable card page")
	await _pick("next_inventory")
	await _capture("threats", 1)
	await _press(KEY_ESCAPE)
	await _pick("crew")
	await _capture("crew", 1)
	await _press(KEY_ESCAPE)
	await _pick("title")
	await _pick("continue")
	_check(_demo.session != null, "continue loads valid save")
	if _demo.session == null:
		return
	_check(_demo.session.snapshot() == before, "disk restore preserves exact gameplay")
	for seat: String in _demo.input_adapter.stable_seats():
		# Reclaim explicitly via ownership adapter; replay does not persist controller capabilities.
		_demo.input_adapter.reclaim_with_keyboard(seat)
	await _pick("resume")
	_check(_demo._page == "game", "resumed saved Tale")
	_demo._message = ""
	_demo._refresh()


func _test_controller_restore() -> void:
	_demo = DEMO_SCENE.instantiate()
	root.add_child(_demo)
	await process_frame
	_demo.session = DrownedHarborDemoSession.new()
	_demo.session.start(3101, PackedStringArray(["seat_01", "seat_02"]))
	_demo.session.choose("search_manifest", "seat_01")
	_demo.session.disconnect_seat("seat_01")
	_check(
		_demo._store.write_save(_demo.session.snapshot()).accepted,
		"controller restore fixture saved"
	)
	_demo._return_to_title()
	# Supply simulated discovery metadata; buttons use Godot's real semantic input path.
	_virtual_pad(14)
	await _pad(14, JOY_BUTTON_DPAD_DOWN)
	await _pad(14, JOY_BUTTON_A)
	_check(_demo._page == "pause", "controller can select Continue from fresh title")
	_check(
		_demo.session.public_view().roles.seats[0].connected,
		"locally owned title controller reconnects its saved disconnected seat"
	)
	_check(
		_demo.input_adapter.pending_reclaim_seat() == "seat_02",
		"restore prompts the unowned active seat"
	)
	await _capture("controller_reclaim", 2)
	_virtual_pad(15)
	await _pad(15, JOY_BUTTON_A)
	_check(
		_demo.input_adapter.public_roster()[1].connected,
		"second controller reclaims through a real confirm event"
	)
	await _pad(14, JOY_BUTTON_A)
	_check(_demo._page == "game", "controller resumes restored Tale")
	var revision: int = _demo.session.public_view().revision
	await _pad(15, JOY_BUTTON_A)
	_check(
		_demo.session.public_view().revision > revision,
		"reclaimed controller can commit the next displayed choice"
	)
	_demo.free()
	await process_frame


func _virtual_pad(device: int) -> void:
	_demo.input_adapter._registry._devices[device] = {
		"device_id": device,
		"name": "QA virtual controller",
		"guid": "qa-%d" % device,
		"identity": "qa-%d" % device
	}


func _pad(device: int, button: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.device = device
	event.button_index = button
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	await process_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame


func _pick(id: String) -> void:
	var choices: Array = _demo._model().get("choices", [])
	var target: int = -1
	for index: int in choices.size():
		if choices[index].id == id:
			target = index
	if target < 0:
		_check(false, "missing displayed action " + id + " on " + _demo._page)
		return
	for index: int in posmod(target - _demo._selected, choices.size()):
		await _press(KEY_DOWN)
	await _press(KEY_ENTER)


func _press(key: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	await process_frame
	event = InputEventKey.new()
	event.physical_keycode = key
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame


func _capture(label: String, count: int) -> void:
	if not _captures:
		return
	await RenderingServer.frame_post_draw
	var screenshot: Image = root.get_texture().get_image()
	var directory: String = ProjectSettings.globalize_path("res://test-results/alpha4-screenshots")
	DirAccess.make_dir_recursive_absolute(directory)
	_check(
		screenshot.save_png(directory.path_join("%s_%d.png" % [label, count])) == OK,
		"saved rendered frame"
	)


func _check(condition: bool, label: String) -> void:
	if not condition:
		_failures.append(label)
