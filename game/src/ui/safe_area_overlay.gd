class_name SafeAreaOverlay
extends Control

var frame_color: Color = Color.WHITE
var frame_margin: int = 24
var frame_width: float = 2.0
var _lines: Array[ColorRect] = []

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_frame_margin(value: int) -> void:
	frame_margin = value
	_update_frame()

func _ready() -> void:
	for index: int in 4:
		var line := ColorRect.new()
		line.color = frame_color
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(line)
		_lines.append(line)
	_update_frame()

func _update_frame() -> void:
	if _lines.size() != 4:
		return
	var inset: float = float(frame_margin)
	var width: float = maxf(size.x - inset * 2.0, 0.0)
	var height: float = maxf(size.y - inset * 2.0, 0.0)
	_lines[0].position = Vector2(inset, inset)
	_lines[0].size = Vector2(width, frame_width)
	_lines[1].position = Vector2(inset, size.y - inset - frame_width)
	_lines[1].size = Vector2(width, frame_width)
	_lines[2].position = Vector2(inset, inset)
	_lines[2].size = Vector2(frame_width, height)
	_lines[3].position = Vector2(size.x - inset - frame_width, inset)
	_lines[3].size = Vector2(frame_width, height)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_frame()
