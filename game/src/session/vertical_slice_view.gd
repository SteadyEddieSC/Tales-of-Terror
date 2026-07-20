class_name VerticalSliceView
extends Control

const LAB_THEME: Theme = preload("res://assets/theme/terror_lab_theme.tres")
const PANEL_SIZE := Vector2(820, 410)

var _title: Label
var _body: Label
var _footer: Label
var _safe_margin: int = 24


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = LAB_THEME
	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color("10121d")
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	var panel := Panel.new()
	panel.name = "VerticalSlicePanel"
	panel.theme_type_variation = "SeatCard"
	panel.size = PANEL_SIZE
	add_child(panel)
	_title = Label.new()
	_title.theme_type_variation = "HeroTitle"
	_title.position = Vector2(34, 28)
	_title.size = Vector2(752, 62)
	panel.add_child(_title)
	_body = Label.new()
	_body.position = Vector2(38, 108)
	_body.size = Vector2(744, 210)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	panel.add_child(_body)
	_footer = Label.new()
	_footer.position = Vector2(38, 338)
	_footer.size = Vector2(744, 42)
	_footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(_footer)
	_layout()


func present(state: Dictionary, seats: Array[Dictionary], developer_lab: bool = false) -> void:
	if developer_lab:
		visible = false
		return
	visible = state.lifecycle != "active_tale" or state.get("paused", false)
	var seat_count: int = _joined_seat_count(seats)
	match state.lifecycle:
		"boot_title":
			_title.text = "TERROR TURN"
			_body.text = (
				"FIRST VERTICAL SLICE  •  LANTERN HOUSE\n\n"
				+ "A controller-first shared-screen tale for 1–8 stable seats. "
				+ "Companion phones are optional; native Godot remains authoritative."
			)
			_footer.text = "PRESS A / ENTER TO JOIN  •  X / T OPENS DEVELOPER LABS"
		"lobby":
			_title.text = "LOCAL LOBBY  •  %d SEAT%s" % [seat_count, "" if seat_count == 1 else "S"]
			_body.text = (
				_seat_roster(seats)
				+ "\n\nJoin more controllers now. Stable seats survive reconnects."
			)
			_footer.text = "A / ENTER: JOIN  •  CONFIRM: LOCK ROSTER"
		"confirmation":
			_title.text = "LANTERN HOUSE  •  MODE CONFIRMATION"
			_body.text = (
				"Hidden Betrayer is selected for 3–8 seats. One or two seats use the "
				+ "authored no-secret cooperative fallback. No phone is required."
			)
			_footer.text = "CONFIRM: PREPARE THE TALE  •  CANCEL: RETURN TO LOBBY"
		"briefing":
			_title.text = "THE LANTERN HOUSE WAKES"
			_body.text = "%s\n\nOBJECTIVE\n%s" % [state.briefing, state.public_objective]
			_footer.text = "CONFIRM: BEGIN  •  MOVE: STICK / WASD  •  INTERACT: A / E"
		"active_tale":
			_title.text = "TALE PAUSED"
			_body.text = (
				"The native authorities are unchanged. Resume before submitting movement, "
				+ "interaction, prompt, or stage input."
			)
			_footer.text = "MENU / P: RESUME"
		"terminal", "ending":
			_title.text = "THE HOUSE REMEMBERS"
			_body.text = _ending_text(state.get("ending", {}))
			_footer.text = "CONFIRM: CLEAN REMATCH  •  CANCEL: RETURN TO TITLE"
		_:
			_title.text = "LANTERN HOUSE"
			_body.text = "Preparing the tale…"
			_footer.text = "PLEASE WAIT"


func set_safe_margin(value: int) -> void:
	_safe_margin = clampi(value, 0, 48)
	_layout()


func _layout() -> void:
	var panel: Panel = get_node_or_null("VerticalSlicePanel")
	if panel == null:
		return
	var available := Rect2(
		Vector2(_safe_margin, _safe_margin),
		Vector2(960 - _safe_margin * 2, 540 - _safe_margin * 2),
	)
	panel.position = available.get_center() - PANEL_SIZE * 0.5


func _joined_seat_count(seats: Array[Dictionary]) -> int:
	return (
		seats
		. filter(
			func(seat: Dictionary) -> bool: return seat.state != SeatManager.SeatState.UNASSIGNED
		)
		. size()
	)


func _seat_roster(seats: Array[Dictionary]) -> String:
	var rows := PackedStringArray()
	for seat: Dictionary in seats:
		if seat.state != SeatManager.SeatState.UNASSIGNED:
			rows.append(
				(
					"SEAT %s  ◆  %s  •  %s"
					% [
						_roman(seat.seat_number),
						seat.device_name,
						SeatManager.state_label(seat.state)
					]
				)
			)
	return "\n".join(rows)


func _ending_text(ending: Dictionary) -> String:
	return (
		"The Lantern House records a deterministic public outcome.\n\n"
		+ "RESULT: %s\n" % ending.get("terminal_reason", "The tale has ended.").capitalize()
		+ "Mixed faction and individual details remain filtered until their controlled reveal.\n\n"
		+ "Every session authority can now reset without stale seats, prompts, rooms, roles, "
		+ "or board mutations."
	)


func _roman(seat_number: int) -> String:
	return ["I", "II", "III", "IV", "V", "VI", "VII", "VIII"][seat_number - 1]
