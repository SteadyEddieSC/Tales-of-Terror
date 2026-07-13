class_name ExplorationDiagnostics
extends PanelContainer

const LAB_THEME: Theme = preload("res://assets/theme/terror_lab_theme.tres")
const PANEL_SIZE: Vector2 = Vector2(610, 324)
const INNER_TEXT_WIDTH: float = 590.0
const DIAGNOSTIC_FONT_SIZE: int = 11
var _label: Label

func _ready() -> void:
	theme = LAB_THEME
	theme_type_variation = "PanelContainer"
	position = Vector2(34, 72)
	custom_minimum_size = PANEL_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	add_child(margin)
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", DIAGNOSTIC_FONT_SIZE)
	_label.custom_minimum_size.x = INNER_TEXT_WIDTH
	_label.clip_text = true
	margin.add_child(_label)
	visible = false

func update_snapshot(pawns: Array[PawnState], camera: SharedCameraCoordinator, board_state: BoardState = null, rules_session: RulesSession = null) -> void:
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
	if rules_session != null:
		var rules: Dictionary = rules_session.diagnostics_snapshot()
		lines.append("RULES %s  SEED %d/#%d  ROUND %d %s r%d" % [rules.session, rules.seed, rules.rng_counter, rules.round, rules.phase, rules.phase_revision])
		lines.append("READY %s PASS %s  EVENT %s  QUEUE %s" % [rules.ready, rules.passed, rules.current_event, rules.event_queue])
		lines.append("CARDS deck=%d discard=%d exhaust=%d  INVENTORY %s" % [rules.deck, rules.discard, rules.exhausted, rules.inventory])
		lines.append("PROMPT %s  VOTE %s  CHECK %s" % [rules.prompt.get("id", "—"), rules.vote.get("id", "—"), rules.check.get("outcome", "—")])
	_label.text = "\n".join(lines)

func toggle() -> void:
	visible = not visible

func set_safe_margin(value: int) -> void:
	position = calculate_panel_rect(Vector2(960, 540), value).position

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
		var line: String = "HISTORY r%d  %s" % [entry.revision, summary]
		lines.append(ellipsize_to_width(line, INNER_TEXT_WIDTH, ThemeDB.fallback_font, DIAGNOSTIC_FONT_SIZE))
	if lines.is_empty():
		lines.append("HISTORY  none")
	return lines

static func calculate_panel_rect(viewport_size: Vector2, safe_margin: int) -> Rect2:
	var position := Vector2(safe_margin + 10, safe_margin + 42)
	return Rect2(position, Vector2(minf(PANEL_SIZE.x, viewport_size.x - position.x - safe_margin - 10), PANEL_SIZE.y))

static func ellipsize_to_width(text: String, max_width: float, font: Font, font_size: int) -> String:
	if font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= max_width:
		return text
	const ELLIPSIS: String = "…"
	var candidate: String = text
	while not candidate.is_empty():
		candidate = candidate.left(candidate.length() - 1).rstrip(" ")
		var result: String = candidate + ELLIPSIS
		if font.get_string_size(result, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= max_width:
			return result
	return ELLIPSIS
