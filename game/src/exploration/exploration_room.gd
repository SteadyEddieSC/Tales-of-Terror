class_name ExplorationRoom
extends Node2D

const BOUNDS := Rect2(0.0, 0.0, 1800.0, 1000.0)
const SPAWN_POINTS: Array[Vector2] = [
	Vector2(310, 430),
	Vector2(380, 430),
	Vector2(450, 430),
	Vector2(520, 430),
	Vector2(310, 500),
	Vector2(380, 500),
	Vector2(450, 500),
	Vector2(520, 500),
]
const WALLS: Array[Rect2] = [
	Rect2(0, 0, 1800, 32),
	Rect2(0, 968, 1800, 32),
	Rect2(0, 0, 32, 1000),
	Rect2(1768, 0, 32, 1000),
	Rect2(890, 32, 38, 365),
	Rect2(890, 603, 38, 365),
	Rect2(220, 220, 220, 42),
	Rect2(570, 690, 240, 42),
	Rect2(1180, 220, 310, 42),
	Rect2(1160, 700, 42, 190),
	Rect2(1450, 520, 210, 42),
]

var _show_authored_headings: bool = true


func _ready() -> void:
	for wall: Rect2 in WALLS:
		_add_static_rect(wall)
	queue_redraw()


func _draw() -> void:
	draw_rect(BOUNDS, Color("100b16"))
	draw_rect(Rect2(32, 32, 858, 936), Color("1a1222"))
	draw_rect(Rect2(928, 32, 840, 936), Color("15101d"))
	for x: int in range(80, 1760, 80):
		draw_line(Vector2(x, 32), Vector2(x, 968), Color(0.25, 0.19, 0.29, 0.18), 2.0)
	for y: int in range(80, 960, 80):
		draw_line(Vector2(32, y), Vector2(1768, y), Color(0.25, 0.19, 0.29, 0.18), 2.0)
	draw_rect(Rect2(928, 397, 260, 206), Color("24162a"))
	if _show_authored_headings:
		draw_string(
			ThemeDB.fallback_font,
			Vector2(112, 100),
			"THE LANTERN HALL",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			24,
			Color("d7bd86")
		)
		draw_string(
			ThemeDB.fallback_font,
			Vector2(1040, 100),
			"THE NARROW",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			20,
			Color("a997ad")
		)
	for wall: Rect2 in WALLS:
		draw_rect(wall, Color("33273b"))
		draw_line(wall.position, Vector2(wall.end.x, wall.position.y), Color("6c5877"), 3.0)


func _add_static_rect(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.position = rect.get_center()
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	body.add_child(collision)
	add_child(body)


func set_show_authored_headings(value: bool) -> void:
	_show_authored_headings = value
	queue_redraw()
