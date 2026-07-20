class_name LabBackdrop
extends Control

@export var tokens: VisualTokens


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _draw() -> void:
	if tokens == null:
		return
	draw_rect(Rect2(Vector2.ZERO, size), tokens.backdrop_bottom)
	var bands: int = 12
	for index: int in bands:
		var ratio: float = float(index) / float(bands)
		var band_color: Color = tokens.backdrop_top.lerp(tokens.backdrop_bottom, ratio)
		draw_rect(Rect2(0.0, ratio * size.y, size.x, size.y / bands + 1.0), band_color)
	draw_circle(Vector2(size.x * 0.82, size.y * 0.18), 78.0, Color(tokens.moon_glow, 0.13))
	draw_circle(Vector2(size.x * 0.82, size.y * 0.18), 48.0, Color(tokens.parchment, 0.08))
	for index: int in 9:
		var x: float = float(index) * size.x / 8.0
		var height: float = 35.0 + float((index * 17) % 70)
		var points := PackedVector2Array(
			[
				Vector2(x - 70.0, size.y),
				Vector2(x - 52.0, size.y - height * 0.45),
				Vector2(x - 30.0, size.y - height),
				Vector2(x - 12.0, size.y - height * 0.55),
				Vector2(x + 10.0, size.y - height * 1.2),
				Vector2(x + 35.0, size.y - height * 0.4),
				Vector2(x + 70.0, size.y),
			]
		)
		draw_colored_polygon(points, Color(tokens.ink, 0.72))
	draw_line(
		Vector2(0.0, size.y - 3.0), Vector2(size.x, size.y - 3.0), Color(tokens.warning, 0.35), 3.0
	)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()
