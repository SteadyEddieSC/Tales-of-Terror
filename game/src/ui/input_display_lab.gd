class_name InputDisplayLab
extends Control

const MIN_SAFE_MARGIN: int = 0
const MAX_SAFE_MARGIN: int = 48
const SAFE_STEP: int = 8
var _seat_labels: Array[Label] = []
var _devices_label: Label
var _safe_label: Label
var _safe_overlay: ReferenceRect
var _reset_label: Label
var _safe_margin: int = 24

func _ready() -> void:
	_build_ui()
	set_safe_margin(_safe_margin)

func present_seats(seats: Array[Dictionary]) -> void:
	if _seat_labels.is_empty():
		return
	for index: int in mini(seats.size(), _seat_labels.size()):
		var seat: Dictionary = seats[index]
		var state: String = SeatManager.state_label(seat.state)
		var guidance: String = " • Reconnect the same controller" if seat.state == SeatManager.SeatState.RESERVED else ""
		_seat_labels[index].text = "SEAT %d  %-10s  %s  •  Last: %s%s" % [seat.seat_number, state, seat.device_name, seat.last_action, guidance]

func present_devices(devices: Array[Dictionary], seats: Array[Dictionary]) -> void:
	var lines: PackedStringArray = ["CONNECTED DEVICES"]
	if devices.is_empty():
		lines.append("No controllers detected • Keyboard fallback: J to join")
	for device: Dictionary in devices:
		var assigned: String = "unassigned"
		for seat: Dictionary in seats:
			if seat.state == SeatManager.SeatState.ACTIVE and seat.device_id == device.device_id:
				assigned = "Seat %d" % seat.seat_number
		lines.append("ID %d • %s • %s" % [device.device_id, device.name, assigned])
	_devices_label.text = "\n".join(lines)

func adjust_safe_margin(delta: int) -> void:
	set_safe_margin(_safe_margin + delta * SAFE_STEP)

func set_safe_margin(value: int) -> void:
	_safe_margin = clampi(value, MIN_SAFE_MARGIN, MAX_SAFE_MARGIN)
	_safe_overlay.offset_left = _safe_margin
	_safe_overlay.offset_top = _safe_margin
	_safe_overlay.offset_right = -_safe_margin
	_safe_overlay.offset_bottom = -_safe_margin
	_safe_label.text = "SAFE AREA: %d px  •  LB/RB or -/+" % _safe_margin

func present_reset_progress(progress: float) -> void:
	_reset_label.text = "Hold Y / R for 1.5 seconds to reset all seats" if progress <= 0.0 else "RESETTING… %d%%" % roundi(progress * 100.0)

func _build_ui() -> void:
	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color("120d1c")
	add_child(background)
	_safe_overlay = ReferenceRect.new()
	_safe_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_safe_overlay.border_color = Color("d4a85b")
	_safe_overlay.border_width = 2.0
	_safe_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_safe_overlay)
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 32)
	root.add_theme_constant_override("separation", 7)
	add_child(root)
	var title := Label.new()
	title.text = "INPUT & DISPLAY LAB  •  v0.0.2"
	title.add_theme_font_size_override("font_size", 26)
	root.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Press A / J to join  •  Controller-first  •  960×540 logical viewport"
	subtitle.add_theme_font_size_override("font_size", 17)
	root.add_child(subtitle)
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 20)
	root.add_child(columns)
	var seats := VBoxContainer.new()
	seats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(seats)
	for index: int in SeatManager.MAX_SEATS:
		var label := Label.new()
		label.text = "SEAT %d  UNASSIGNED" % (index + 1)
		label.add_theme_font_size_override("font_size", 16)
		label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		seats.add_child(label)
		_seat_labels.append(label)
	_devices_label = Label.new()
	_devices_label.custom_minimum_size.x = 330
	_devices_label.add_theme_font_size_override("font_size", 15)
	_devices_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	columns.add_child(_devices_label)
	var footer := HBoxContainer.new()
	root.add_child(footer)
	_safe_label = Label.new()
	_safe_label.add_theme_font_size_override("font_size", 15)
	_safe_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(_safe_label)
	_reset_label = Label.new()
	_reset_label.add_theme_font_size_override("font_size", 15)
	footer.add_child(_reset_label)
	present_reset_progress(0.0)
