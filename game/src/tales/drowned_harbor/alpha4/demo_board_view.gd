class_name DrownedHarborDemoBoardView
extends Control

const POINTS: Dictionary = {
	"harbor_gate": Vector2(0.12, 0.69),
	"low_tide_market": Vector2(0.28, 0.43),
	"bellhouse": Vector2(0.46, 0.63),
	"lighthouse_council": Vector2(0.60, 0.29),
	"high_water_channel": Vector2(0.72, 0.70),
	"last_light_beacon": Vector2(0.87, 0.32),
}
const NAMES: Dictionary = {
	"harbor_gate": "HARBOR GATE",
	"low_tide_market": "TIDE MARKET",
	"bellhouse": "BELLHOUSE",
	"lighthouse_council": "COUNCIL",
	"high_water_channel": "CHANNEL",
	"last_light_beacon": "LAST LIGHT",
}
const LINKS: Array[Array] = [
	["gate_to_market", "harbor_gate", "low_tide_market"],
	["market_to_bellhouse", "low_tide_market", "bellhouse"],
	["bellhouse_to_council", "bellhouse", "lighthouse_council"],
	["council_to_channel", "lighthouse_council", "high_water_channel"],
	["channel_to_beacon", "high_water_channel", "last_light_beacon"],
]
const COLORS: Array[Color] = [
	Color("f4ba62"),
	Color("79c9ed"),
	Color("ef947f"),
	Color("82d3b1"),
	Color("dbc5f7"),
	Color("e5de87"),
	Color("f4b1d1"),
	Color("b0becd"),
]
const SYMBOLS: Array[String] = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII"]

var reduced_motion: bool = false
var _board: Dictionary = {}
var _active_seat: String = ""
var _phase: float = 0.0
var _water: float = 0.0
var _target_water: float = 0.0
var _texture: Texture2D
var _positions: Dictionary = {}
var _targets: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var asset: String = "res://assets/drowned_harbor_alpha4/harbor_board_texture.png"
	if ResourceLoader.exists(asset):
		_texture = load(asset) as Texture2D


func present(board: Dictionary, active_seat: String) -> void:
	_board = board.duplicate(true)
	_active_seat = active_seat
	_target_water = 1.0 if board.get("tide_state", "low_tide") == "high_water" else 0.0
	_targets.clear()
	for row: Dictionary in board.get("seats", []):
		var point: Vector2 = POINTS.get(row.get("space_id", ""), POINTS.harbor_gate)
		_targets[row.stable_seat_id] = point
		if not _positions.has(row.stable_seat_id):
			_positions[row.stable_seat_id] = point
	queue_redraw()


func _process(delta: float) -> void:
	if reduced_motion:
		_water = _target_water
		_positions = _targets.duplicate()
	else:
		_phase += delta
		_water = move_toward(_water, _target_water, delta * 0.65)
		for seat: String in _targets:
			_positions[seat] = (_positions[seat] as Vector2).lerp(
				_targets[seat], minf(1, delta * 7)
			)
	queue_redraw()


func _draw() -> void:
	draw_style_box(_frame(), Rect2(Vector2.ZERO, size))
	if _texture != null:
		draw_texture_rect(
			_texture, Rect2(2, 2, size.x - 4, size.y - 4), false, Color(0.64, 0.72, 0.75, 0.82)
		)
	else:
		_draw_harbor()
	draw_rect(
		Rect2(2, size.y * 0.63, size.x - 4, size.y * 0.37 - 2),
		Color(0.10, 0.34, 0.39, 0.15 + _water * 0.45)
	)
	_draw_water()
	for link: Array in LINKS:
		var from: Vector2 = (POINTS[link[1]] as Vector2) * size
		var to: Vector2 = (POINTS[link[2]] as Vector2) * size
		var closed: bool = _board.get("connector_states", {}).get(link[0], "open") == "closed"
		draw_line(from, to, Color("0d171f"), 9, true)
		draw_dashed_line(from, to, Color("df927d") if closed else Color("c4c5a5"), 3, 7)
		if closed:
			var middle: Vector2 = (from + to) * 0.5
			draw_line(middle - Vector2(7, 7), middle + Vector2(7, 7), Color("ffad8c"), 3)
			draw_line(middle + Vector2(-7, 7), middle + Vector2(7, -7), Color("ffad8c"), 3)
	for key: String in POINTS:
		_draw_landmark(key)
	_draw_seats()
	_text(
		"HIGH WATER  /  GATE ROUTE CLOSED" if _target_water > 0 else "LOW TIDE  /  ROUTES OPEN",
		Vector2(16, 25),
		14,
		Color("f2deb5")
	)
	_text(
		_board.get("summary", "I–VIII  CREW     •  LANDMARK     —  ROUTE"),
		Vector2(16, size.y - 12),
		13,
		Color("c5d0cf")
	)


func _draw_harbor() -> void:
	for index: int in 19:
		var x: float = 8 + index * size.x / 19
		var height: float = 38 + (index * 23 % 65)
		var base: float = size.y * 0.56
		var polygon := PackedVector2Array(
			[
				Vector2(x, base),
				Vector2(x, base - height),
				Vector2(x + 13, base - height - 17),
				Vector2(x + 28, base - height),
				Vector2(x + 28, base),
			]
		)
		draw_colored_polygon(polygon, Color("24393e"))
		draw_polyline(polygon, Color("101c25"), 3)
		draw_rect(Rect2(x + 9, base - height + 9, 5, 9), Color("d19d58"))


func _draw_water() -> void:
	for index: int in 12:
		var y: float = size.y * 0.62 + index * 9
		var shift: float = sin(_phase * 0.28 + index) * 12 if not reduced_motion else 0.0
		draw_line(
			Vector2(10 + shift, y),
			Vector2(size.x - 18 + shift, y),
			Color(0.47, 0.74, 0.75, 0.09 + _water * 0.10),
			1
		)


func _draw_landmark(key: String) -> void:
	var point: Vector2 = (POINTS[key] as Vector2) * size
	draw_circle(point, 16, Color("0c1b24"))
	draw_arc(point, 16, 0, TAU, 32, Color("d4c4a0"), 2, true)
	draw_circle(point, 5, Color("efbd68"))
	var title: String = NAMES[key]
	var font: Font = ThemeDB.fallback_font
	var extent: Vector2 = font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 13)
	var origin: Vector2 = point + Vector2(-extent.x * 0.5, 32)
	draw_rect(Rect2(origin - Vector2(4, 14), extent + Vector2(8, 4)), Color("111e29"))
	_text(title, origin, 13, Color("f4e3c6"))


func _draw_seats() -> void:
	var count: int = 0
	for row: Dictionary in _board.get("seats", []):
		var seat: String = row.stable_seat_id
		var point: Vector2 = (_positions.get(seat, POINTS.harbor_gate) as Vector2) * size
		point += Vector2((count % 4 - 1.5) * 17, -27 - floori(count / 4.0) * 20)
		var color: Color = COLORS[count % 8]
		if seat == _active_seat:
			draw_circle(point, 13, Color("ffedbb"))
		draw_circle(point, 10, Color("0b1520"))
		draw_arc(point, 10, 0, TAU, 24, color, 2, true)
		_text(SYMBOLS[count % 8], point + Vector2(-6, 4), 12, color)
		count += 1


func _text(value: String, at: Vector2, font_size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _frame() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("13252e")
	style.border_color = Color("677676")
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	return style
