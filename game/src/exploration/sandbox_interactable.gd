class_name SandboxInteractable
extends Node2D

enum Kind { DOOR, CLUE }

var interaction_id: String
var kind: Kind
var active: bool = false
var focused_seat: int = 0
var last_actor: int = 0
var _tokens: VisualTokens
var _door_body: StaticBody2D
var _door_collision: CollisionShape2D

func setup(p_id: String, p_kind: Kind, p_position: Vector2, tokens: VisualTokens) -> void:
	interaction_id = p_id
	kind = p_kind
	position = p_position
	_tokens = tokens
	if kind == Kind.DOOR:
		_door_body = StaticBody2D.new()
		_door_collision = CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(28, 150)
		_door_collision.shape = shape
		_door_body.add_child(_door_collision)
		add_child(_door_body)
	queue_redraw()

func descriptor() -> Dictionary:
	return {"id": interaction_id, "position": global_position, "enabled": true}

func set_focused(seat_number: int) -> void:
	focused_seat = seat_number
	queue_redraw()

func interact(seat_number: int) -> String:
	set_active(not active)
	last_actor = seat_number
	if kind == Kind.DOOR:
		return "IRON GATE %s BY SEAT %s" % ["OPENED" if active else "CLOSED", _roman(seat_number)]
	return "CLUE %s BY SEAT %s" % ["REVEALED" if active else "VEILED", _roman(seat_number)]

func set_active(value: bool) -> void:
	active = value
	if _door_collision != null:
		_door_collision.set_deferred("disabled", active)
	queue_redraw()

func _draw() -> void:
	if _tokens == null:
		return
	if kind == Kind.DOOR:
		var door_color: Color = _tokens.success if active else _tokens.danger
		if active:
			draw_rect(Rect2(-72, -14, 144, 28), Color(door_color, 0.7))
		else:
			draw_rect(Rect2(-14, -75, 28, 150), door_color)
			for y: int in range(-62, 70, 24):
				draw_line(Vector2(-10, y), Vector2(10, y), Color("29131a"), 3.0)
	else:
		draw_rect(Rect2(-28, 5, 56, 44), Color("352a3e"))
		draw_circle(Vector2(0, -8), 22.0, _tokens.warning if active else Color("756581"))
		draw_circle(Vector2(0, -8), 12.0, Color("f2dd9b") if active else Color("1b1521"))
	if focused_seat > 0:
		draw_arc(Vector2.ZERO, 46.0, 0.0, TAU, 32, _tokens.warning, 4.0)

func _roman(seat_number: int) -> String:
	return _tokens.player_symbols[seat_number - 1]
