class_name ExplorationPawn
extends CharacterBody2D

const LAB_THEME: Theme = preload("res://assets/theme/terror_lab_theme.tres")

var pawn_state: PawnState
var _tokens: VisualTokens
var _symbol: Label
var _focused: bool = false

func setup(state: PawnState, tokens: VisualTokens) -> void:
	pawn_state = state
	_tokens = tokens
	global_position = state.position
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = PawnState.COLLISION_RADIUS
	collision.shape = shape
	add_child(collision)
	_symbol = Label.new()
	_symbol.theme = LAB_THEME
	_symbol.text = tokens.player_symbols[state.seat_number - 1]
	_symbol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_symbol.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_symbol.position = Vector2(-22, -14)
	_symbol.size = Vector2(44, 28)
	_symbol.add_theme_font_size_override("font_size", 14)
	add_child(_symbol)
	queue_redraw()

func apply_movement(raw_input: Vector2, resistance: float, _delta: float, room_bounds: Rect2) -> void:
	pawn_state.set_input(raw_input)
	velocity = pawn_state.input_vector * PawnState.MOVE_SPEED * resistance
	move_and_slide()
	global_position.x = clampf(global_position.x, room_bounds.position.x + PawnState.COLLISION_RADIUS, room_bounds.end.x - PawnState.COLLISION_RADIUS)
	global_position.y = clampf(global_position.y, room_bounds.position.y + PawnState.COLLISION_RADIUS, room_bounds.end.y - PawnState.COLLISION_RADIUS)
	pawn_state.position = global_position

func set_interaction_focus(focused: bool) -> void:
	if _focused == focused:
		return
	_focused = focused
	queue_redraw()

func refresh_connection() -> void:
	modulate.a = 1.0 if pawn_state.connected else 0.48
	queue_redraw()

func _draw() -> void:
	if pawn_state == null or _tokens == null:
		return
	var accent: Color = _tokens.player_colors[pawn_state.seat_number - 1]
	draw_circle(Vector2.ZERO, 22.0, Color("0b0910"))
	draw_circle(Vector2.ZERO, 19.0, accent)
	draw_circle(Vector2.ZERO, 14.0, Color("17111f"))
	var segment_count: int = pawn_state.seat_number
	for index: int in segment_count:
		var angle: float = TAU * float(index) / float(segment_count) - PI * 0.5
		var point: Vector2 = Vector2.from_angle(angle) * 19.0
		draw_circle(point, 2.4, Color("f0dfbd"))
	if _focused:
		draw_arc(Vector2.ZERO, 28.0, 0.0, TAU, 32, _tokens.warning, 3.0)
	if not pawn_state.connected:
		draw_line(Vector2(-14, -14), Vector2(14, 14), _tokens.danger, 4.0)
		draw_line(Vector2(14, -14), Vector2(-14, 14), _tokens.danger, 4.0)
