class_name BoardDebugOverlay
extends Node2D

const SPACE_LABEL_SIZE: Vector2 = Vector2(340, 46)
const CONNECTOR_LABEL_SIZE: Vector2 = Vector2(190, 24)
const LABEL_EDGE_INSET: float = 10.0
const TOP_HUD_RESERVE: float = 58.0
const BOTTOM_HUD_RESERVE: float = 72.0

var _definition: BoardDefinition
var _state: BoardState
var _tokens: VisualTokens
var _safe_margin: int = 24


func setup(definition: BoardDefinition, state: BoardState, tokens: VisualTokens) -> void:
	_definition = definition
	_state = state
	_tokens = tokens
	_state.state_changed.connect(_on_state_changed)
	queue_redraw()


func set_safe_margin(value: int) -> void:
	_safe_margin = clampi(value, 0, 48)
	queue_redraw()


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	if _definition == null or _state == null or _tokens == null:
		return
	for space: Dictionary in _definition.spaces:
		_draw_space(space, _state.get_space_state(space.id))
	for connector: Dictionary in _definition.connectors:
		_draw_connector(connector, _state.get_connector_state(connector.id))


func _draw_space(space: Dictionary, state: Dictionary) -> void:
	var revealed: bool = state.revealed
	var hazards: Array = state.hazards
	var features: Array = state.features
	var blockers: Array = state.blockers
	var outline: Color = _tokens.warning if revealed else _tokens.muted_text
	for area_value: Variant in space.areas:
		var area: Rect2 = area_value
		draw_rect(area, Color(outline, 0.08), true)
		draw_rect(area, outline, false, 4.0)
		if not revealed:
			_draw_diagonal_hatch(area, Color(_tokens.muted_text, 0.5))
		if not hazards.is_empty():
			_draw_warning_chevrons(area, _tokens.danger)
		if not blockers.is_empty():
			draw_line(area.position + Vector2(8, 8), area.end - Vector2(8, 8), _tokens.danger, 6.0)
			draw_line(
				Vector2(area.end.x - 8, area.position.y + 8),
				Vector2(area.position.x + 8, area.end.y - 8),
				_tokens.danger,
				6.0
			)
	var authored_center: Vector2 = space.get("label_position", _definition.space_center(space.id))
	var center: Vector2 = _clamped_world_anchor(authored_center, SPACE_LABEL_SIZE)
	var label: String = (
		"%s  [%s]" % [space.name if revealed else "HIDDEN: %s" % space.name, space.id]
	)
	draw_string(
		ThemeDB.fallback_font,
		center + Vector2(-150, -28),
		label,
		HORIZONTAL_ALIGNMENT_CENTER,
		300,
		15,
		_tokens.parchment
	)
	var state_parts := PackedStringArray()
	if not hazards.is_empty():
		state_parts.append("HAZARD ! %s" % ",".join(hazards))
	if not features.is_empty():
		state_parts.append("FEATURE ◆ %s" % ",".join(features))
	if not blockers.is_empty():
		state_parts.append("BLOCKED × %s" % ",".join(blockers))
	var occupants: Array[int] = state.occupants
	if not occupants.is_empty():
		var symbols := PackedStringArray()
		for seat_number: int in occupants:
			symbols.append(_tokens.player_symbols[seat_number - 1])
		state_parts.append("OCCUPANCY ◉ %s" % ",".join(symbols))
	if space.tags.has("objective"):
		state_parts.append("OBJECTIVE ◆")
	if not state_parts.is_empty():
		draw_string(
			ThemeDB.fallback_font,
			center + Vector2(-170, -4),
			"  •  ".join(state_parts),
			HORIZONTAL_ALIGNMENT_CENTER,
			340,
			12,
			_tokens.parchment
		)


func _draw_connector(connector: Dictionary, state: String) -> void:
	var from_center: Vector2 = _definition.space_center(connector.from)
	var to_center: Vector2 = _definition.space_center(connector.to)
	var color: Color = (
		_tokens.success
		if state == "open"
		else _tokens.danger if state in ["locked", "collapsed"] else _tokens.warning
	)
	if state == "collapsed":
		_draw_dashed(from_center, to_center, color, 7.0)
	else:
		draw_line(from_center, to_center, color, 7.0)
	if connector.get("one_way", false):
		var direction: Vector2 = (to_center - from_center).normalized()
		var midpoint: Vector2 = from_center.lerp(to_center, 0.5)
		draw_line(midpoint - direction.rotated(0.7) * 18.0, midpoint, color, 5.0)
		draw_line(midpoint - direction.rotated(-0.7) * 18.0, midpoint, color, 5.0)
	var label_center: Vector2 = _clamped_world_anchor(
		from_center.lerp(to_center, 0.5), CONNECTOR_LABEL_SIZE
	)
	var text_position: Vector2 = label_center + Vector2(-95, -8)
	draw_string(
		ThemeDB.fallback_font,
		text_position,
		"%s %s  %s" % [connector_symbol(state), connector.id, state.to_upper()],
		HORIZONTAL_ALIGNMENT_CENTER,
		190,
		12,
		_tokens.parchment
	)


func _draw_diagonal_hatch(area: Rect2, color: Color) -> void:
	var span: int = ceili(area.size.x + area.size.y)
	for offset: int in range(-ceili(area.size.y), span, 28):
		var start := Vector2(area.position.x + maxf(offset, 0), area.position.y + maxf(-offset, 0))
		var length: float = minf(area.end.x - start.x, area.end.y - start.y)
		if length > 0.0:
			draw_line(start, start + Vector2(length, length), color, 3.0)


func _draw_warning_chevrons(area: Rect2, color: Color) -> void:
	var y: float = area.position.y + 18.0
	for x: int in range(ceili(area.position.x) + 20, floori(area.end.x) - 20, 48):
		draw_polyline(
			PackedVector2Array([Vector2(x - 12, y), Vector2(x, y + 12), Vector2(x + 12, y)]),
			color,
			4.0
		)


func _draw_dashed(from: Vector2, to: Vector2, color: Color, width: float) -> void:
	var distance: float = from.distance_to(to)
	var direction: Vector2 = (to - from).normalized()
	var cursor: float = 0.0
	while cursor < distance:
		var segment_end: float = minf(cursor + 24.0, distance)
		draw_line(from + direction * cursor, from + direction * segment_end, color, width)
		cursor += 40.0


func _on_state_changed(_change: Dictionary) -> void:
	queue_redraw()


func _clamped_world_anchor(world_anchor: Vector2, label_size: Vector2) -> Vector2:
	var canvas_transform: Transform2D = get_viewport().get_canvas_transform()
	var screen_anchor: Vector2 = canvas_transform * world_anchor
	var clamped_screen: Vector2 = clamp_label_center(
		screen_anchor, label_size, Vector2(960, 540), _safe_margin
	)
	return canvas_transform.affine_inverse() * clamped_screen


static func label_region(viewport_size: Vector2, safe_margin: int) -> Rect2:
	var left: float = float(safe_margin) + LABEL_EDGE_INSET
	var top: float = float(safe_margin) + TOP_HUD_RESERVE
	var right: float = viewport_size.x - float(safe_margin) - LABEL_EDGE_INSET
	var bottom: float = viewport_size.y - float(safe_margin) - BOTTOM_HUD_RESERVE
	return Rect2(Vector2(left, top), Vector2(maxf(0.0, right - left), maxf(0.0, bottom - top)))


static func clamp_label_center(
	screen_anchor: Vector2, label_size: Vector2, viewport_size: Vector2, safe_margin: int
) -> Vector2:
	var region: Rect2 = label_region(viewport_size, safe_margin)
	var half_size: Vector2 = label_size * 0.5
	return Vector2(
		clampf(screen_anchor.x, region.position.x + half_size.x, region.end.x - half_size.x),
		clampf(screen_anchor.y, region.position.y + half_size.y, region.end.y - half_size.y)
	)


static func connector_symbol(state: String) -> String:
	return {"open": "↔", "closed": "║", "locked": "▣", "collapsed": "✕"}.get(state, "?")


static func space_pattern(state: String) -> String:
	return (
		{
			"hidden": "diagonal_hatch",
			"hazard": "warning_chevrons",
			"blocked": "cross_mark",
			"objective": "diamond"
		}
		. get(state, "solid_outline")
	)
