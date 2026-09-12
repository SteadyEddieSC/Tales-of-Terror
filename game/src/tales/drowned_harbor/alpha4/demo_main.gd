class_name DrownedHarborDemoMain
extends Control

const MODES: Array[String] = ["cooperative", "hidden_betrayer", "outbreak"]
const MODE_LABELS: Array[String] = ["Cooperative", "Hidden Betrayer", "Outbreak"]
const PROFILES: Array[String] = ["Spooky", "Grim", "Gore & Dread"]
const SETTINGS_PATH: String = "user://drowned_harbor_demo_settings.cfg"

var session: DrownedHarborDemoSession
var input_adapter: DrownedHarborDemoInput
var _view: DrownedHarborDemoScreenView
var _audio: DemoAudio
var _store := DrownedHarborDemoSaveStore.new()
var _page: String = "title"
var _overlay_history: Array[String] = []
var _selected: int = 0
var _mode_index: int = 0
var _profile_index: int = 1
var _seed: int = 3101
var _reveal_index: int = 0
var _private_seat: String = ""
var _private_return: String = "game"
var _private_tab: int = 0
var _inventory_tab: int = 0
var _ceremony: bool = false
var _message: String = ""
var _caption: String = "The sea remembers what the town forgot."
var _last_stage: String = ""
var _last_director_note: String = ""
var _sound_caption: String = ""
var _reduced_motion: bool = false
var _large_text: bool = false
var _captions: bool = true
var _master_volume: float = 0.7
var _music_volume: float = 0.45
var _effects_volume: float = 0.65


func _ready() -> void:
	_load_settings()
	input_adapter = DrownedHarborDemoInput.new()
	input_adapter.lobby_open = false
	add_child(input_adapter)
	input_adapter.command.connect(handle_command)
	input_adapter.roster_changed.connect(_roster_changed)
	input_adapter.connection_changed.connect(_connection_changed)
	_view = DrownedHarborDemoScreenView.new()
	add_child(_view)
	_audio = DemoAudio.new()
	add_child(_audio)
	_audio.caption_requested.connect(func(value: String) -> void: _sound_caption = value)
	_apply_settings()
	_refresh()
	if OS.get_cmdline_user_args().has("--demo-smoke"):
		call_deferred("_run_export_smoke")


func _run_export_smoke() -> void:
	var candidate := DrownedHarborDemoSession.new()
	var admitted: Dictionary = candidate.start(3101, PackedStringArray(["seat_01"]))
	var valid: bool = admitted.get("accepted", false)
	valid = valid and not DemoNarrative.stage_text("low_tide").is_empty()
	valid = (
		valid
		and ResourceLoader.exists("res://assets/drowned_harbor_alpha4/harbor_board_texture.png")
	)
	valid = (
		valid and ResourceLoader.exists("res://assets/drowned_harbor_alpha4/harbor_wind_loop.tres")
	)
	if valid:
		print("DROWNED_HARBOR_DEMO_SMOKE_PASSED: native scene, content, art and audio loaded")
	else:
		push_error("DROWNED_HARBOR_DEMO_SMOKE_FAILED")
	get_tree().quit(0 if valid else 1)


func handle_command(action: String, stable_seat: String) -> void:
	if action == "help" or action == "pause":
		_open_overlay("help" if action == "help" else "pause")
	elif action == "back":
		if _page == "private":
			_show_page("shield")
		elif _page != "shield" or stable_seat == _private_seat:
			_back()
	elif action == "private" and _page in ["game", "results"]:
		if input_adapter.stable_seats().has(stable_seat):
			_private_return = _page
			_private_seat = stable_seat
			_ceremony = false
			_show_page("shield")
	elif action in ["up", "left", "down", "right"]:
		if _can_control(stable_seat):
			var choices: Array = _model().get("choices", [])
			if not choices.is_empty():
				_selected = posmod(
					_selected + (-1 if action in ["up", "left"] else 1), choices.size()
				)
				_refresh()
	elif action == "confirm" and _can_control(stable_seat):
		var choices: Array = _model().get("choices", [])
		if not choices.is_empty():
			_activate(choices[clampi(_selected, 0, choices.size() - 1)].id, stable_seat)


func _can_control(seat: String) -> bool:
	if _page in ["shield", "private"]:
		return seat == _private_seat
	if _page == "game" and session != null:
		return seat == session.public_view().get("active_seat", "")
	return true


func _activate(id: String, seat: String) -> void:
	_message = ""
	if _page == "game":
		var result: Dictionary = session.choose(id, seat)
		if result.get("accepted", false):
			_selected = 0
			_caption = DemoNarrative.event_text(id, _profile_id()).get("text", _caption)
			_after_choice(id)
		else:
			_message = "That action is no longer available. Choose again."
		_refresh()
		return
	match id:
		"new":
			if input_adapter.stable_seats().is_empty():
				input_adapter.add_keyboard_seat()
			_show_page("lobby")
		"continue":
			_restore_game()
		"add_seat":
			input_adapter.add_keyboard_seat()
			_refresh()
		"setup":
			_show_page("setup")
		"mode":
			_mode_index = (_mode_index + 1) % MODES.size()
			_refresh()
		"seed":
			_seed += 1
			_refresh()
		"begin":
			_start_game()
		"intro_done":
			_ceremony = true
			_reveal_index = 0
			_next_reveal()
		"open_private":
			_private_tab = 0
			_show_page("private")
		"close_private":
			_close_private()
		"resume":
			_back()
		"save":
			_save_game()
		"title":
			_return_to_title()
		"rematch":
			_start_game()
		"settings":
			_open_overlay("settings")
		"help":
			_open_overlay("help")
		"next_private":
			_private_tab = 1 - _private_tab
			_selected = 0
			_refresh()
		"inventory", "crew":
			_inventory_tab = 0
			_show_page(id)
		"next_inventory":
			_inventory_tab = (_inventory_tab + 1) % 3
			_refresh()
		"reclaim":
			_reclaim_active()
		"profile":
			_profile_index = (_profile_index + 1) % PROFILES.size()
			_setting_changed()
		"motion":
			_reduced_motion = not _reduced_motion
			_setting_changed()
		"text":
			_large_text = not _large_text
			_setting_changed()
		"captions":
			_captions = not _captions
			_setting_changed()
		"master", "music", "effects":
			_adjust_volume(id)
		"back":
			_back()
		"lantern_house":
			get_tree().change_scene_to_file("res://src/main/Main.tscn")
		"quit":
			get_tree().quit()


func _start_game() -> void:
	_overlay_history.clear()
	var candidate := DrownedHarborDemoSession.new()
	var result: Dictionary = candidate.start(
		_seed, input_adapter.stable_seats(), MODES[_mode_index]
	)
	if not result.get("accepted", false):
		_message = "This mode needs more seats. Cooperative: 1–8; Betrayer: 3–8; Outbreak: 2–8."
		_refresh()
		return
	session = candidate
	_mode_index = MODES.find(session.public_view().mode)
	if not session.public_view().get("fallback_reason", "").is_empty():
		_message = "This crew uses Cooperative play. Betrayer needs 3 seats; Outbreak needs 2."
	_last_stage = ""
	_last_director_note = ""
	_private_seat = ""
	input_adapter.lobby_open = false
	_show_page("intro")


func _after_choice(event_id: String = "") -> void:
	var state: Dictionary = session.public_view()
	var stage: String = state.get("stage", "")
	if stage != _last_stage:
		_last_stage = stage
		_caption = DemoNarrative.stage_text(stage, _profile_id()).get(
			"text", state.get("instruction", "")
		)
	var director_note: String = state.get("director_note", "")
	if not director_note.is_empty() and director_note != _last_director_note:
		_last_director_note = director_note
		_caption = director_note
	_sound_caption = ""
	_audio.present(stage, int(state.get("revision", 0)), event_id)
	if state.get("terminal", false):
		_show_page("results")
	input_adapter.set_active_seat(state.get("active_seat", ""))


func _next_reveal() -> void:
	var seats: PackedStringArray = input_adapter.stable_seats()
	if _reveal_index >= seats.size():
		_ceremony = false
		_private_seat = ""
		_show_page("game")
		_after_choice()
		_refresh()
	else:
		_private_seat = seats[_reveal_index]
		input_adapter.set_active_seat(_private_seat)
		_show_page("shield")


func _close_private() -> void:
	if _ceremony:
		_reveal_index += 1
		_next_reveal()
	else:
		_private_seat = ""
		_show_page(_private_return)


func _open_overlay(page: String) -> void:
	# Clear private payloads before showing any public overlay.
	if _page == page:
		_back()
	else:
		_overlay_history.append("shield" if _page in ["private", "shield"] else _page)
		_show_page(page)


func _back() -> void:
	match _page:
		"private":
			_show_page("shield")
		"shield":
			_close_private()
		"lobby":
			_show_page("title")
		"setup":
			_show_page("lobby")
		"game":
			_open_overlay("pause")
		"inventory", "crew":
			_show_page("pause")
		"pause", "help", "settings":
			var destination: String = "game" if session != null else "title"
			if not _overlay_history.is_empty():
				destination = _overlay_history.pop_back()
			_show_page(destination)
		_:
			_show_page("title")


func _show_page(page: String) -> void:
	_page = "title" if page == "game" and session == null else page
	_selected = 0
	input_adapter.lobby_open = page == "lobby"
	input_adapter.set_active_seat(_private_seat if page in ["shield", "private"] else "")
	_audio.set_controlled_reveal(page in ["shield", "private"])
	_refresh()


func _save_game() -> void:
	if session == null:
		_message = "Start a Tale before saving."
	else:
		var result: Dictionary = _store.write_save(session.snapshot())
		_message = (
			"Tale saved. Continue from the title screen."
			if result.get("accepted", false)
			else "Save failed. Your current Tale is still running."
		)
	_refresh()


func _restore_game() -> void:
	var saved: Dictionary = _store.read_save()
	if not saved.get("accepted", false):
		_message = "No readable save. Your current Tale has not changed."
	else:
		var candidate := DrownedHarborDemoSession.new()
		var restored: Dictionary = candidate.restore(saved.snapshot)
		if not restored.get("accepted", false):
			_message = "This save is invalid or from an unsupported version. Current Tale kept."
		else:
			session = candidate
			_seed = int(saved.snapshot.seed)
			_mode_index = MODES.find(saved.snapshot.mode)
			input_adapter.set_roster(session.public_view().get("seats", []))
			for owner: Dictionary in input_adapter.public_roster():
				if owner.connected:
					for saved_seat: Dictionary in session.public_view().roles.seats:
						if (
							saved_seat.stable_seat_id == owner.stable_seat_id
							and not saved_seat.connected
						):
							session.reconnect_seat(owner.stable_seat_id)
			input_adapter.begin_reclaim(session.public_view().get("active_seat", ""))
			_message = (
				"Restored. Reclaim disconnected seats from Pause."
				if not saved.get("recovered_backup", false)
				else "Recovered the last valid backup."
			)
			_ceremony = false
			_private_seat = ""
			_overlay_history.clear()
			_overlay_history.append("results" if session.public_view().terminal else "game")
			_show_page("pause")
	_refresh()


func _reclaim_active() -> void:
	if session != null:
		var seat: String = session.public_view().get("active_seat", "")
		if input_adapter.reclaim_with_keyboard(seat):
			session.reconnect_seat(seat)
			_message = (
				"Keyboard now controls " + _seat_label(seat) + ". Use Tab to pass the keyboard."
			)
	_refresh()


func _return_to_title() -> void:
	_overlay_history.clear()
	_private_seat = ""
	_ceremony = false
	session = null
	_audio.stop_all()
	input_adapter.reset_roster()
	_show_page("title")


func _roster_changed(_roster: Array[Dictionary]) -> void:
	if is_instance_valid(_view):
		_refresh()


func _connection_changed(seat: String, connected: bool) -> void:
	if session != null:
		if connected:
			session.reconnect_seat(seat)
		else:
			session.disconnect_seat(seat)
			if seat == _private_seat:
				_show_page("shield")
		_message = (
			_seat_label(seat)
			+ (" reconnected." if connected else " disconnected. Pause to reclaim.")
		)
	_refresh()


func _refresh() -> void:
	if is_instance_valid(_view):
		if session != null and _page in ["game", "pause"]:
			input_adapter.begin_reclaim(session.public_view().get("active_seat", ""))
		_view.present(_model())


func _model() -> Dictionary:
	var model: Dictionary = {"page": _page, "selected": _selected, "message": _message}
	if _page == "game":
		model.merge(_game_model(), true)
	elif _page in ["shield", "private"]:
		model.merge(_private_model(), true)
	else:
		model.merge(_menu_model(), true)
	var pending: String = input_adapter.pending_reclaim_seat()
	if not pending.is_empty() and _page in ["pause", "game"]:
		model.message = (
			_seat_label(pending)
			+ ": press A on your controller to reclaim. Pause also offers keyboard reclaim."
		)
	return model


func _game_model() -> Dictionary:
	var state: Dictionary = session.public_view()
	var board: Dictionary = state.get("board", {}).duplicate(true)
	var resources: Dictionary = state.get("resources", {})
	board.summary = (
		"OIL %d   ROPE %d   NAMES %d   BOAT %d   CLAIM %d"
		% [
			resources.get("lamp_oil", 0),
			resources.get("rope", 0),
			resources.get("memory_fragments", 0),
			resources.get("lifeboat_capacity", 0),
			state.get("claim", 0)
		]
	)
	input_adapter.set_active_seat(state.get("active_seat", ""))
	return {
		"title": state.get("title", "THE HARBOR WAITS"),
		"kicker": MODE_LABELS[_mode_index] + "  /  " + PROFILES[_profile_index],
		"instruction":
		(
			_seat_label(state.get("active_seat", ""))
			+ " • "
			+ (
				"Choose an action\nTide action %d / %d"
				% [state.get("turn", 0) + 1, state.get("turn_limit", 1)]
			)
		),
		"choices": state.get("actions", []),
		"board": board,
		"seats": input_adapter.public_roster(),
		"active_seat": state.get("active_seat", ""),
		"caption": _caption if _captions else state.get("instruction", ""),
		"sound_caption": _sound_caption if _captions else "",
	}


func _private_model() -> Dictionary:
	if _page == "shield":
		return {
			"title": _seat_label(_private_seat).to_upper() + " — YOUR CONTROLLER",
			"subtitle":
			(
				"Everyone else: look away.\nPress confirm when the room is ready.\nYour role "
				+ "and objective stay behind this shield."
			),
			"choices": [_choice("open_private", "Open my private hand")],
		}
	var data: Dictionary = session.private_view(_private_seat)
	return {
		"title": data.get("role_title", data.get("role_name", "Your private hand")),
		"subtitle": _private_copy(data),
		"portrait": DemoNarrative.role_portrait_path(data.get("role_id", "")),
		"choices":
		[
			(
				_choice("next_private", "Read allegiance & account")
				if _private_tab == 0
				else _choice("close_private", "Shield and continue")
			),
			(
				_choice("close_private", "Shield and continue")
				if _private_tab == 0
				else _choice("next_private", "Return to role & objective")
			),
		],
	}


func _private_copy(data: Dictionary) -> String:
	if data.is_empty():
		return (
			"Private hand unavailable while this seat is disconnected.\n"
			+ "Reconnect its controller to continue."
		)
	if _private_tab == 1:
		var account: String = "Your account is still being written."
		if session.public_view().stage == "complete":
			account = (
				"Objective fulfilled."
				if data.get("objective_complete", false)
				else "Objective unfulfilled."
			)
		return "ALLEGIANCE\n%s\n\nYOUR ACCOUNT\n%s" % [data.get("faction_text", ""), account]
	return (
		"%s\n\nOBJECTIVE\n%s"
		% [
			DemoNarrative.role_text(data.get("role_id", "")).get(
				"text", "A witness in the Harbor."
			),
			data.get(
				"objective_text",
				data.get("objective_title", "Carry the crew through the returning tide.")
			),
		]
	)


func _menu_model() -> Dictionary:
	var result: Dictionary = {}
	match _page:
		"title":
			result = {
				"title": "DROWNED\nHARBOR",
				"choices":
				[
					_choice("new", "Play Drowned Harbor"),
					_choice("continue", "Continue saved Tale"),
					_choice("settings", "Presentation & accessibility"),
					_choice("lantern_house", "Play Lantern House"),
					_choice("quit", "Quit"),
				]
			}
		"lobby":
			result = _lobby_model()
		"setup":
			result = {
				"title": "BEFORE THE BELL",
				"subtitle":
				"Cooperative: 1–8 seats. Hidden Betrayer: 3–8. Outbreak: 2–8. The tide advances when you act.",
				"choices":
				[
					_choice("mode", "Mode: " + MODE_LABELS[_mode_index]),
					_choice("seed", "Tale seed: %d" % _seed),
					_choice("begin", "Enter the harbor"),
					_choice("back", "Back to crew")
				]
			}
		"intro":
			result = {
				"title": "ONE RING TOO MANY",
				"subtitle":
				(
					"The bell rings for every one of you. Then once more.\nFind the ledger. Face "
					+ "the Council. Decide what the lighthouse will guide home."
				),
				"choices": [_choice("intro_done", "Receive your private hand")]
			}
		"pause":
			result = {
				"title": "THE TIDE CAN WAIT",
				"subtitle":
				"Paused. No decisions, hazards or tide changes happen while this menu is open.",
				"choices":
				[
					_choice("resume", "Return to the Tale"),
					_choice("inventory", "Crew inventory & resources"),
					_choice("crew", "Witnesses & revealed allegiances"),
					_choice("save", "Save this Tale"),
					_choice("reclaim", "Reclaim active seat with keyboard"),
					_choice("settings", "Presentation & accessibility"),
					_choice("help", "Controls & how to play"),
					_choice("title", "Return to title (unsaved progress lost)")
				]
			}
		"settings":
			result = _settings_model()
		"help":
			result = {
				"title": "KEEP THE CREW TOGETHER",
				"subtitle":
				(
					"D-pad / stick / arrows choose. A / Enter acts. B / Esc goes back. Y / V opens "
					+ "your private hand. Start / P pauses.\nKeyboard: J joins; Tab passes between "
					+ "keyboard seats."
				),
				"choices": [_choice("back", "Return")],
				"message":
				(
					"One highlighted seat acts at a time. Choices advance the tide; defeat opens a "
					+ "continuation. Phones are optional; this demo uses local private handoffs."
				)
			}
		"inventory":
			result = {
				"title":
				["WHAT YOU CARRY", "CARDS IN HAND", "THE HARBOR'S ATTENTION"][_inventory_tab],
				"subtitle": _inventory_copy(),
				"choices": [_choice("next_inventory", "Next page (%d / 3)" % (_inventory_tab + 1))],
				"message":
				"Cards appear as playable choices during High Water. B / Escape returns to Pause."
			}
		"crew":
			result = {
				"title": "THE WITNESSES",
				"subtitle": _crew_copy(),
				"choices": [_choice("back", "Return")],
				"message":
				"Private roles, objectives and undeclared allegiances remain behind each witness's shield."
			}
		"results":
			var outcome: Dictionary = session.public_view().get("outcome", {})
			result = {
				"title": outcome.get("title", "THE SEA KEEPS ITS RECORD"),
				"subtitle": outcome.get("text", "Your choices have become part of the harbor."),
				"choices":
				[_choice("rematch", "Rematch with this crew"), _choice("title", "Return to title")],
				"message": "A new Tale clears roles, items, choices and private handoffs."
			}
	return result


func _lobby_model() -> Dictionary:
	var rows: Array[Dictionary] = input_adapter.public_roster()
	var connected: int = 0
	for row: Dictionary in rows:
		if row.get("connected", false):
			connected += 1
	return {
		"title": "GATHER YOUR CREW",
		"subtitle": "%d / 8 seats • %d ready" % [rows.size(), connected],
		"seats": rows,
		"choices":
		[
			_choice("setup", "Crew ready — choose the Tale mode"),
			_choice("add_seat", "Add a keyboard pass-and-play seat"),
			_choice("back", "Back")
		],
		"message":
		(
			"Press A on each controller to join. J adds a keyboard seat. Stable seats stay "
			+ "yours after reconnect."
		)
	}


func _settings_model() -> Dictionary:
	return {
		"title": "SET THE ATMOSPHERE",
		"subtitle":
		(
			"Profiles change presentation, with identical rules. Captions remain available "
			+ "for every important beat."
		),
		"choices":
		[
			_choice("profile", "Profile: " + PROFILES[_profile_index]),
			_choice("motion", "Reduced motion: " + _on_off(_reduced_motion)),
			_choice("text", "Large text: " + _on_off(_large_text)),
			_choice("captions", "Underteller captions: " + _on_off(_captions)),
			_choice("master", "Master volume: %d%%" % roundi(_master_volume * 100)),
			_choice("music", "Music volume: %d%%" % roundi(_music_volume * 100)),
			_choice("effects", "Effects volume: %d%%" % roundi(_effects_volume * 100)),
			_choice("back", "Done")
		],
		"message": "Settings are saved on this device. Volume confirm cycles 0–100%."
	}


func _crew_copy() -> String:
	if session == null:
		return "Gather your crew to begin."
	var lines: PackedStringArray = []
	for witness: Dictionary in session.public_view().roles.seats:
		var line: String = _seat_label(witness.stable_seat_id) + " — "
		line += str(witness.get("public_form", "living")).replace("_", " ").capitalize()
		if not witness.get("connected", true):
			line += " • disconnected"
		if witness.has("revealed_allegiance"):
			line += " • declared: " + witness.revealed_allegiance
		lines.append(line)
	return "\n".join(lines)


func _inventory_copy() -> String:
	if session == null:
		return "Start a Tale to gather resources."
	var state: Dictionary = session.public_view()
	if _inventory_tab == 1:
		var lines: PackedStringArray = []
		for seat: String in state.get("cards", {}):
			var counts: Dictionary = {}
			for card: String in state.cards[seat]:
				counts[card] = int(counts.get(card, 0)) + 1
			var titles: PackedStringArray = []
			for card: String in counts:
				titles.append(card.replace("_", " ").capitalize() + " ×%d" % counts[card])
			lines.append(
				(
					_seat_label(seat)
					+ ": "
					+ (" • ".join(titles) if not titles.is_empty() else "No cards")
				)
			)
		return "\n".join(lines)
	if _inventory_tab == 2:
		var hazards: PackedStringArray = []
		for hazard: String in state.get("hazards", []):
			hazards.append(hazard.replace("_", " ").capitalize())
		var note: String = state.get("director_note", "")
		if note.is_empty():
			note = "The Harbor is watching."
		return (
			note
			+ "\n\nOBSERVED THREATS\n"
			+ (" • ".join(hazards) if not hazards.is_empty() else "None encountered yet.")
		)
	var resources: PackedStringArray = []
	for key: String in state.get("resources", {}):
		resources.append(key.replace("_", " ").capitalize() + ": " + str(state.resources[key]))
	var items: PackedStringArray = []
	for item: Dictionary in state.get("inventory", []):
		items.append(item.name + " (" + _seat_label(item.owner) + ")")
	return (
		" • ".join(resources)
		+ "\n\n"
		+ (" / ".join(items) if not items.is_empty() else "No equipment collected yet.")
	)


func _adjust_volume(id: String) -> void:
	match id:
		"master":
			_master_volume = float((floori(_master_volume * 4) + 1) % 5) / 4.0
		"music":
			_music_volume = float((floori(_music_volume * 4) + 1) % 5) / 4.0
		"effects":
			_effects_volume = float((floori(_effects_volume * 4) + 1) % 5) / 4.0
	_setting_changed()


func _setting_changed() -> void:
	_apply_settings()
	var config := ConfigFile.new()
	for key: String in ["profile", "motion", "text", "captions", "master", "music", "effects"]:
		config.set_value("presentation", key, _settings_values()[key])
	if config.save(SETTINGS_PATH) != OK:
		_message = "Settings apply now, but could not be saved on this device."
	_refresh()


func _settings_values() -> Dictionary:
	return {
		"profile": _profile_index,
		"motion": _reduced_motion,
		"text": _large_text,
		"captions": _captions,
		"master": _master_volume,
		"music": _music_volume,
		"effects": _effects_volume
	}


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	_profile_index = clampi(int(config.get_value("presentation", "profile", 1)), 0, 2)
	_reduced_motion = bool(config.get_value("presentation", "motion", false))
	_large_text = bool(config.get_value("presentation", "text", false))
	_captions = bool(config.get_value("presentation", "captions", true))
	_master_volume = clampf(float(config.get_value("presentation", "master", 0.7)), 0, 1)
	_music_volume = clampf(float(config.get_value("presentation", "music", 0.45)), 0, 1)
	_effects_volume = clampf(float(config.get_value("presentation", "effects", 0.65)), 0, 1)


func _apply_settings() -> void:
	_view.reduced_motion = _reduced_motion
	_view.large_text = _large_text
	_audio.set_levels(_master_volume, _music_volume, _effects_volume)
	if session != null:
		_caption = (
			DemoNarrative
			. stage_text(session.public_view().get("stage", ""), _profile_id())
			. get("text", _caption)
		)


func _profile_id() -> String:
	return ["spooky", "grim", "gore_dread"][_profile_index]


static func _choice(id: String, label: String) -> Dictionary:
	return {"id": id, "label": label, "detail": ""}


static func _seat_label(seat: String) -> String:
	return "Seat " + str(int(seat.trim_prefix("seat_"))) if not seat.is_empty() else "Crew"


static func _on_off(value: bool) -> String:
	return "On" if value else "Off"
