class_name InputDisplayLab
extends Control

const LAB_THEME: Theme = preload("res://assets/theme/terror_lab_theme.tres")
const TOKENS: VisualTokens = preload("res://assets/theme/visual_tokens.tres")
const MIN_SAFE_MARGIN: int = 0
const MAX_SAFE_MARGIN: int = 48
const SAFE_STEP: int = 8

var _seat_cards: Array[SeatCard] = []
var _devices_label: Label
var _safe_label: Label
var _safe_overlay: SafeAreaOverlay
var _reset_label: Label
var _safe_margin: int = 24

func _ready() -> void:
	theme = LAB_THEME
	_build_ui()
	set_safe_margin(_safe_margin)

func present_seats(seats: Array[Dictionary]) -> void:
	if _seat_cards.is_empty():
		return
	for index: int in mini(seats.size(), _seat_cards.size()):
		_seat_cards[index].present(seats[index])

func present_devices(devices: Array[Dictionary], seats: Array[Dictionary]) -> void:
	var lines: PackedStringArray = []
	if devices.is_empty():
		lines.append("No controllers detected")
		lines.append("Keyboard fallback: J to join")
	for device: Dictionary in devices:
		var assigned: String = "Awaiting a seat"
		for seat: Dictionary in seats:
			if seat.state == SeatManager.SeatState.ACTIVE and seat.device_id == device.device_id:
				assigned = "Bound to Seat %d" % seat.seat_number
		lines.append("◆ ID %d  %s" % [device.device_id, device.name])
		lines.append("   %s" % assigned)
	_devices_label.text = "\n".join(lines)

func adjust_safe_margin(delta: int) -> void:
	set_safe_margin(_safe_margin + delta * SAFE_STEP)

func set_safe_margin(value: int) -> void:
	_safe_margin = clampi(value, MIN_SAFE_MARGIN, MAX_SAFE_MARGIN)
	_safe_overlay.set_frame_margin(_safe_margin)
	_safe_label.text = "SAFE FRAME %d px   LB/RB or -/+" % _safe_margin

func present_reset_progress(progress: float) -> void:
	_reset_label.text = "Hold Y / R 1.5s to clear seats" if progress <= 0.0 else "BREAKING THE SEAL… %d%%" % roundi(progress * 100.0)

func _build_ui() -> void:
	var backdrop := LabBackdrop.new()
	backdrop.tokens = TOKENS
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 32)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)
	_build_header(root)
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 14)
	root.add_child(columns)
	var seats_panel := PanelContainer.new()
	seats_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(seats_panel)
	var seats_margin := MarginContainer.new()
	for side: String in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		seats_margin.add_theme_constant_override(side, 10)
	seats_panel.add_child(seats_margin)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 9)
	grid.add_theme_constant_override("v_separation", 8)
	seats_margin.add_child(grid)
	for index: int in SeatManager.MAX_SEATS:
		var card := SeatCard.new()
		card.setup(index + 1, TOKENS)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.size_flags_vertical = Control.SIZE_EXPAND_FILL
		grid.add_child(card)
		_seat_cards.append(card)
	var device_panel := PanelContainer.new()
	device_panel.custom_minimum_size.x = 250.0
	columns.add_child(device_panel)
	var device_margin := MarginContainer.new()
	for side: String in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		device_margin.add_theme_constant_override(side, 14)
	device_panel.add_child(device_margin)
	var device_stack := VBoxContainer.new()
	device_stack.add_theme_constant_override("separation", 8)
	device_margin.add_child(device_stack)
	var device_title := Label.new()
	device_title.text = "THE GATHERING"
	device_title.theme_type_variation = "SectionTitle"
	device_stack.add_child(device_title)
	_devices_label = Label.new()
	_devices_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_devices_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	device_stack.add_child(_devices_label)
	var key_hint := Label.new()
	key_hint.text = "A / J  JOIN\nX / T  TEST SIGNAL"
	key_hint.theme_type_variation = "SeatDetail"
	device_stack.add_child(key_hint)
	_build_footer(root)
	_safe_overlay = SafeAreaOverlay.new()
	_safe_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_safe_overlay.frame_color = TOKENS.warning
	_safe_overlay.frame_width = 2.0
	add_child(_safe_overlay)

func _build_header(root: VBoxContainer) -> void:
	var header := HBoxContainer.new()
	root.add_child(header)
	var title_stack := VBoxContainer.new()
	title_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_stack)
	var title := Label.new()
	title.text = "TERROR TURN"
	title.theme_type_variation = "LabTitle"
	title_stack.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "VISUAL LANGUAGE LAB  /  v0.0.3  /  PROVISIONAL MARK"
	subtitle.theme_type_variation = "SeatDetail"
	title_stack.add_child(subtitle)
	var callout := Label.new()
	callout.text = "PRESS A / J TO ENTER THE TALE"
	callout.theme_type_variation = "SectionTitle"
	callout.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(callout)

func _build_footer(root: VBoxContainer) -> void:
	var footer := PanelContainer.new()
	root.add_child(footer)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	footer.add_child(row)
	_safe_label = Label.new()
	_safe_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_safe_label)
	_reset_label = Label.new()
	row.add_child(_reset_label)
	present_reset_progress(0.0)
