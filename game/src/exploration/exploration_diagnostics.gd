class_name ExplorationDiagnostics
extends PanelContainer

const LAB_THEME: Theme = preload("res://assets/theme/terror_lab_theme.tres")
var _label: Label

func _ready() -> void:
	theme = LAB_THEME
	theme_type_variation = "PanelContainer"
	position = Vector2(34, 72)
	custom_minimum_size = Vector2(610, 0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var margin := MarginContainer.new()
	for side: String in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 10)
	add_child(margin)
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 12)
	_label.clip_text = true
	margin.add_child(_label)
	visible = false

func update_snapshot(pawns: Array[PawnState], camera: SharedCameraCoordinator, board_state: BoardState = null) -> void:
	var lines: PackedStringArray = [
		"EXPLORATION DIAGNOSTICS",
		"Camera target %s  zoom %.2f  %s" % [camera.target_position.round(), camera.target_zoom, SharedCameraPolicy.state_label(camera.separation_state)],
	]
	for pawn: PawnState in pawns:
		var board_space: String = board_state.space_for_seat(pawn.seat_number) if board_state != null else "—"
		lines.append("Seat %s → dev %d  pos %s  input %s  space %s  focus %s  %s" % [
			_roman(pawn.seat_number), pawn.device_id, pawn.position.round(), pawn.input_vector,
			board_space, pawn.nearby_interactable, "CONNECTED" if pawn.connected else "RESERVED",
		])
	if board_state != null:
		lines.append("BOARD %s v%d  REVISION %d" % [board_state.definition.board_id, board_state.definition.board_version, board_state.revision])
		lines.append("OCCUPANCY  %s" % _occupancy_summary(board_state))
		for connector_line: String in _connector_summary(board_state):
			lines.append(connector_line)
		for state_line: String in _space_value_summary(board_state):
			lines.append(state_line)
		for history_line: String in _history_summary(board_state):
			lines.append(history_line)
		lines.append("LAST REJECTION  %s" % board_state.last_rejection)
	_label.text = "\n".join(lines)

func toggle() -> void:
	visible = not visible

func set_safe_margin(value: int) -> void:
	position = Vector2(value + 10, value + 42)

func _roman(seat_number: int) -> String:
	return ["I", "II", "III", "IV", "V", "VI", "VII", "VIII"][seat_number - 1]

func _occupancy_summary(board_state: BoardState) -> String:
	var parts := PackedStringArray()
	for space_id: String in board_state.definition.space_ids():
		var occupants: Array[int] = board_state.occupants_in(space_id)
		if occupants.is_empty():
			continue
		var symbols := PackedStringArray()
		for seat_number: int in occupants:
			symbols.append(_roman(seat_number))
		parts.append("%s[%s]" % [space_id, ",".join(symbols)])
	return "none" if parts.is_empty() else " | ".join(parts)

func _connector_summary(board_state: BoardState) -> PackedStringArray:
	var first := PackedStringArray()
	var second := PackedStringArray()
	var index: int = 0
	for connector_id: String in board_state.definition.connector_ids():
		var target: PackedStringArray = first if index < 3 else second
		target.append("%s=%s" % [connector_id, board_state.get_connector_state(connector_id)])
		index += 1
	return PackedStringArray(["CONNECTORS A  " + " | ".join(first), "CONNECTORS B  " + " | ".join(second)])

func _space_value_summary(board_state: BoardState) -> PackedStringArray:
	var hazards := PackedStringArray()
	var features := PackedStringArray()
	for space_id: String in board_state.definition.space_ids():
		var state: Dictionary = board_state.get_space_state(space_id)
		if not state.hazards.is_empty():
			hazards.append("%s!%s" % [space_id, ",".join(state.hazards)])
		if not state.features.is_empty():
			features.append("%s◆%s" % [space_id, ",".join(state.features)])
	return PackedStringArray(["HAZARDS  " + ("none" if hazards.is_empty() else " | ".join(hazards)), "FEATURES  " + ("none" if features.is_empty() else " | ".join(features))])

func _history_summary(board_state: BoardState) -> PackedStringArray:
	var lines := PackedStringArray()
	for entry: Dictionary in board_state.recent_history(3):
		var summary: String = entry.summary
		lines.append("HISTORY r%d  %s" % [entry.revision, summary.left(68)])
	if lines.is_empty():
		lines.append("HISTORY  none")
	return lines
