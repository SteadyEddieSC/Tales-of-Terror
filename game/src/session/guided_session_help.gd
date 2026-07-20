class_name GuidedSessionHelp
extends Control

signal export_requested

const LAB_THEME: Theme = preload("res://assets/theme/terror_lab_theme.tres")
const PAGE_COUNT: int = 4
const PANEL_SIZE := Vector2(820, 440)

var _page_index: int = 0
var _safe_margin: int = 24
var _state: Dictionary = {}
var _seats: Array[Dictionary] = []
var _companion_status: Dictionary = {}
var _report_available: bool = false
var _export_message: String = ""
var _panel: Panel
var _title: Label
var _body: Label
var _footer: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = LAB_THEME
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.02, 0.025, 0.05, 0.94)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)
	_panel = Panel.new()
	_panel.theme_type_variation = "SeatCard"
	_panel.size = PANEL_SIZE
	add_child(_panel)
	_title = Label.new()
	_title.theme_type_variation = "HeroTitle"
	_title.position = Vector2(34, 24)
	_title.size = Vector2(752, 58)
	_panel.add_child(_title)
	_body = Label.new()
	_body.position = Vector2(38, 92)
	_body.size = Vector2(744, 270)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_panel.add_child(_body)
	_footer = Label.new()
	_footer.position = Vector2(38, 374)
	_footer.size = Vector2(744, 44)
	_footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel.add_child(_footer)
	_layout()
	visible = false


func open_help(
	state: Dictionary,
	seats: Array[Dictionary],
	companion_status: Dictionary,
	report_available: bool
) -> void:
	_state = state.duplicate(true)
	_seats = seats.duplicate(true)
	_companion_status = companion_status.duplicate(true)
	_report_available = report_available
	_export_message = ""
	_page_index = 0
	visible = true
	_render()


func close_help() -> void:
	visible = false
	_export_message = ""


func update_context(
	state: Dictionary,
	seats: Array[Dictionary],
	companion_status: Dictionary,
	report_available: bool
) -> void:
	_state = state.duplicate(true)
	_seats = seats.duplicate(true)
	_companion_status = companion_status.duplicate(true)
	_report_available = report_available
	if visible:
		_render()


func handle_action(action: String) -> bool:
	if not visible:
		return false
	match action:
		"help_accessibility", "ui_cancel_action":
			close_help()
		"ui_navigate_left":
			_page_index = wrapi(_page_index - 1, 0, PAGE_COUNT)
			_render()
		"ui_navigate_right":
			_page_index = wrapi(_page_index + 1, 0, PAGE_COUNT)
			_render()
		"ui_confirm":
			if _page_index == PAGE_COUNT - 1 and _report_available:
				export_requested.emit()
			else:
				_page_index = wrapi(_page_index + 1, 0, PAGE_COUNT)
				_render()
		_:
			return false
	return true


func present_export_result(result: Dictionary) -> void:
	if result.get("accepted", false):
		_export_message = "EXPORT COMPLETE — JSON AND MARKDOWN SAVED LOCALLY"
	else:
		_export_message = "EXPORT FAILED — %s" % result.get("reason", "write_failed")
	_page_index = PAGE_COUNT - 1
	_render()


func set_safe_margin(value: int) -> void:
	_safe_margin = clampi(value, 0, 48)
	_layout()


func page_index() -> int:
	return _page_index


func page_text() -> String:
	return _body.text if is_instance_valid(_body) else ""


func _render() -> void:
	var page: Dictionary = page_content(
		_page_index, _state, _seats, _companion_status, _report_available
	)
	_title.text = "%s  •  %d/%d" % [page.title, _page_index + 1, PAGE_COUNT]
	_body.text = page.body
	if not _export_message.is_empty() and _page_index == PAGE_COUNT - 1:
		_body.text += "\n\n" + _export_message
	_footer.text = page.footer


func _layout() -> void:
	if not is_instance_valid(_panel):
		return
	var available := Rect2(
		Vector2(_safe_margin, _safe_margin),
		Vector2(960 - _safe_margin * 2, 540 - _safe_margin * 2),
	)
	_panel.position = available.get_center() - PANEL_SIZE * 0.5


static func page_content(
	page: int,
	state: Dictionary,
	seats: Array[Dictionary],
	companion_status: Dictionary,
	report_available: bool
) -> Dictionary:
	match clampi(page, 0, PAGE_COUNT - 1):
		0:
			return {
				"title": "HELP & CONTROLS",
				"body":
				(
					"CONTROLLER   A confirm/interact  •  B back/pass  •  Menu pause\n"
					+ "D-pad/stick move or choose  •  X help  •  Hold Y 1.5s reset\n\n"
					+ "KEYBOARD   Enter/Space confirm  •  Esc back  •  WASD move\n"
					+ "E interact  •  P pause  •  H help  •  Hold R 1.5s reset\n\n"
					+ "Controls use labels plus symbols and never require a mouse."
				),
				"footer": "LEFT/RIGHT: PAGE  •  A/ENTER: NEXT  •  B/ESC/X/H: CLOSE",
			}
		1:
			return _session_page(state, seats)
		2:
			return _privacy_page(companion_status)
		_:
			return {
				"title": "PLAYTEST REPORT",
				"body":
				(
					"The report contains public session progress and aggregate recovery events only. "
					+ "It never includes roles, objectives, private selections, room secrets, client "
					+ "identities, device IDs, network data, or machine details.\n\n"
					+ (
						(
							"Press A / Enter to export JSON and Markdown under the local user-data "
							+ "playtest_exports folder."
						)
						if report_available
						else "Finish or leave the tale before exporting its finalized report."
					)
				),
				"footer":
				(
					"A/ENTER: EXPORT LOCALLY  •  B/ESC/X/H: CLOSE"
					if report_available
					else "LEFT/RIGHT: PAGE  •  B/ESC/X/H: CLOSE"
				),
			}


static func _session_page(state: Dictionary, seats: Array[Dictionary]) -> Dictionary:
	var lifecycle: String = state.get("lifecycle", "boot_title")
	var stage: Dictionary = state.get("stage", {})
	var stage_title: String = stage.get("title", "Lantern House")
	var objective: String = state.get("public_objective", "Confirm a stable roster to begin.")
	var wait: String = guidance_for_state(state, seats)
	return {
		"title": "CURRENT SESSION",
		"body":
		(
			"STATE   %s\nSTAGE   %s\n\nOBJECTIVE\n%s\n\nNOW\n%s"
			% [lifecycle.replace("_", " ").to_upper(), stage_title, objective, wait]
		),
		"footer": "LEFT/RIGHT: PAGE  •  A/ENTER: NEXT  •  B/ESC/X/H: CLOSE",
	}


static func _privacy_page(companion_status: Dictionary) -> Dictionary:
	var companion_text: String = "Optional companion room: closed"
	if companion_status.get("room_open", false):
		companion_text = (
			"Optional companion room: open • %d connected"
			% clampi(companion_status.get("connected_count", 0), 0, 8)
		)
	return {
		"title": "PRIVACY, ACCESS & RECOVERY",
		"body":
		(
			"NO PHONE REQUIRED   Pass the controller or use the shared-screen controlled "
			+ "reveal. Other players look away until the named seat confirms.\n\n"
			+ "%s. Phones remain optional and non-authoritative.\n\n" % companion_text
			+ "DISCONNECT   The stable seat is reserved. Reconnect the same controller to "
			+ "resume ownership; another seat cannot answer private input.\n\n"
			+ "RESET   Hold Y / R for 1.5 seconds. This closes the room and erases the current "
			+ "tale, seats, prompts, votes, and progress."
		),
		"footer": "HIGH CONTRAST • SAFE MARGINS • TEXT + SYMBOL SEAT CUES • NO FLASHING",
	}


static func guidance_for_state(state: Dictionary, seats: Array[Dictionary]) -> String:
	match state.get("lifecycle", "boot_title"):
		"boot_title":
			return "Press A / Enter to claim the first stable seat. H / X opens help."
		"lobby":
			return "Join or leave seats, then Confirm to lock the %d-seat roster." % _joined(seats)
		"confirmation":
			return "Review mode and fallback. Confirm prepares the tale; Cancel returns to lobby."
		"briefing":
			return "Read the public objective together, then Confirm to begin exploration."
		"active_tale":
			if state.get("paused", false):
				return "Paused. Menu / P resumes; help and protected reset remain available."
			return _active_guidance(state, seats)
		"terminal":
			return "The outcome is fixed. Confirm opens the privacy-safe ending."
		"ending":
			return "Export the report from help, then Confirm rematches or Cancel returns to title."
	return "Please wait for the public session state."


static func _active_guidance(state: Dictionary, seats: Array[Dictionary]) -> String:
	var prompt: Dictionary = state.get("rules", {}).get("prompt", {})
	if prompt.is_empty():
		var base: String = "Explore together. The active seat uses A / E; Confirm advances when ready."
		var reserved: int = _reserved_count(seats)
		if reserved > 0:
			base += (
				" %d stable seat%s reserved for reconnect."
				% [reserved, " is" if reserved == 1 else "s are"]
			)
		return base
	var statuses: Array = prompt.get("response_status", [])
	var submitted: int = (
		statuses
		. filter(func(status: Dictionary) -> bool: return status.get("submitted", false))
		. size()
	)
	var eligible: int = statuses.size()
	var waiting := PackedStringArray()
	for status: Dictionary in statuses:
		if not status.get("submitted", false):
			waiting.append("Seat %d" % status.get("seat", 0))
	var kind: String = _wait_kind(state).capitalize()
	var reconnect: int = _reserved_count(seats)
	var suffix: String = ""
	if reconnect > 0:
		suffix = " • %d seat%s reserved for reconnect" % [reconnect, "" if reconnect == 1 else "s"]
	return (
		"%s progress %d/%d • Waiting: %s%s"
		% [
			kind,
			submitted,
			eligible,
			", ".join(waiting) if not waiting.is_empty() else "resolution",
			suffix,
		]
	)


static func _joined(seats: Array[Dictionary]) -> int:
	var joined: int = 0
	for seat: Dictionary in seats:
		if seat.get("state") != SeatManager.SeatState.UNASSIGNED:
			joined += 1
	return joined


static func _wait_kind(state: Dictionary) -> String:
	var operation_index: int = state.get("operation_index", 0)
	var operations: Array = state.get("stage", {}).get("operations", [])
	if operation_index <= 0 or operation_index > operations.size():
		return "prompt"
	return "vote" if operations[operation_index - 1].get("type") == "submit_vote" else "prompt"


static func _reserved_count(seats: Array[Dictionary]) -> int:
	var count: int = 0
	for seat: Dictionary in seats:
		if (
			seat.get("state")
			in [SeatManager.SeatState.DISCONNECTED, SeatManager.SeatState.RESERVED]
		):
			count += 1
	return count
