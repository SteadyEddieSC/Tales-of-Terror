class_name SeatAccent
extends Control

var _accent_color: Color = Color.WHITE
var _segment_count: int = 1


func configure(accent_color: Color, segment_count: int) -> void:
	_accent_color = accent_color
	_segment_count = maxi(segment_count, 1)
	queue_redraw()


func _draw() -> void:
	var gap: float = 2.0
	var available_height: float = size.y - gap * float(_segment_count - 1)
	var segment_height: float = maxf(available_height / float(_segment_count), 1.0)
	for index: int in _segment_count:
		var y: float = float(index) * (segment_height + gap)
		draw_rect(Rect2(0.0, y, size.x, segment_height), _accent_color)
		draw_line(
			Vector2(size.x - 1.0, y),
			Vector2(size.x - 1.0, y + segment_height),
			_accent_color.lightened(0.25),
			1.0
		)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()
