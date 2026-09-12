class_name DrownedHarborDemoScreenView
extends Control

const INK := Color("0c1620")
const PANEL := Color("142630")
const PAPER := Color("f3e2bf")
const MUTED := Color("b2c6c8")
const GOLD := Color("efbb70")

var reduced_motion: bool = false
var large_text: bool = false
var _surface: Control
var _board: DrownedHarborDemoBoardView
var _board_cache: Dictionary = {}
var _active_cache: String = ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_surface = Control.new()
	add_child(_surface)
	_board = DrownedHarborDemoBoardView.new()
	_board.position = Vector2(24, 114)
	_board.size = Vector2(550, 298)
	add_child(_board)


func present(model: Dictionary) -> void:
	# Immediate destruction is intentional: hidden private labels must not linger in the tree.
	if _board.get_parent() == _surface:
		_board.reparent(self)
	for child: Node in _surface.get_children():
		child.free()
	_board.visible = false
	_board.reduced_motion = reduced_motion
	_rect(_surface, Rect2(0, 0, 960, 540), INK)
	_board.reparent(_surface)
	var page: String = model.get("page", "title")
	if page in ["shield", "private"]:
		_private_page(model)
	elif page == "game":
		_game_page(model)
	elif page in ["inventory", "help", "crew"]:
		_detail_page(model)
	else:
		_menu_page(model)


func _detail_page(model: Dictionary) -> void:
	_panel(_surface, Rect2(24, 24, 912, 470), PANEL, Color("647779"))
	_label(_surface, model.get("title", "CREW RECORD"), Rect2(44, 45, 872, 48), 28, PAPER)
	_label(_surface, model.get("subtitle", ""), Rect2(44, 108, 872, 272), _body(), PAPER)
	_label(_surface, model.get("message", ""), Rect2(44, 363, 872, 67), 16, GOLD)
	_choices(model, Rect2(44, 436, 420, 50), 1)
	_footer("B / ESC  RETURN    A / ENTER  CONFIRM")


func _menu_page(model: Dictionary) -> void:
	_background_art()
	_rect(_surface, Rect2(0, 0, 565, 540), Color(0.04, 0.08, 0.12, 0.94))
	_label(
		_surface,
		model.get("kicker", "TERROR TURN  /  PLAYABLE ALPHA.4"),
		Rect2(40, 28, 880, 25),
		15,
		GOLD
	)
	_label(_surface, model.get("title", "DROWNED\nHARBOR"), Rect2(40, 67, 820, 94), 37, PAPER)
	_label(
		_surface,
		model.get("subtitle", "The sea remembers what the town forgot."),
		Rect2(42, 161, 485, 88),
		_body(),
		MUTED
	)
	if model.get("page") == "lobby":
		_seat_rail(model, 201)
	_choices(model, Rect2(40, 260, 482, 184), 4)
	_label(_surface, model.get("message", ""), Rect2(42, 447, 485, 54), 16, GOLD)
	_footer(model.get("controls", "↑↓ / D-pad  CHOOSE    A / ENTER  CONFIRM    B / ESC  BACK"))
	_label(
		_surface, "A TALE OF MEMORY, DEBT & THE RETURNING SEA", Rect2(585, 458, 338, 46), 15, PAPER
	)


func _game_page(model: Dictionary) -> void:
	_label(_surface, "DROWNED HARBOR", Rect2(24, 15, 270, 26), 18, GOLD)
	_label(
		_surface,
		model.get("kicker", ""),
		Rect2(620, 15, 316, 26),
		16,
		MUTED,
		HORIZONTAL_ALIGNMENT_RIGHT
	)
	_label(_surface, model.get("title", "LOW TIDE"), Rect2(24, 40, 910, 36), 27, PAPER)
	_seat_rail(model)
	_board.visible = true
	var board: Dictionary = model.get("board", {})
	var active: String = model.get("active_seat", "")
	if board != _board_cache or active != _active_cache:
		_board.present(board, active)
		_board_cache = board.duplicate(true)
		_active_cache = active
	_panel(_surface, Rect2(592, 114, 344, 298), PANEL, Color("647779"))
	_label(
		_surface,
		model.get("instruction", "Choose your next action."),
		Rect2(604, 123, 320, 53),
		_body(),
		PAPER
	)
	_choices(model, Rect2(604, 179, 320, 126), 3)
	var choices: Array = model.get("choices", [])
	var selected: int = int(model.get("selected", 0))
	if not choices.is_empty():
		_label(
			_surface,
			choices[clampi(selected, 0, choices.size() - 1)].get("detail", ""),
			Rect2(606, 311, 316, 94),
			15,
			MUTED
		)
	_panel(_surface, Rect2(24, 424, 912, 70), Color("1e2c33"), Color("82755f"))
	_label(_surface, "THE UNDERTELLER", Rect2(37, 431, 172, 18), 13, GOLD)
	_label(
		_surface,
		model.get("sound_caption", ""),
		Rect2(220, 431, 699, 18),
		13,
		MUTED,
		HORIZONTAL_ALIGNMENT_RIGHT
	)
	_label(
		_surface, model.get("caption", ""), Rect2(37, 451, 883, 39), 19 if large_text else 17, PAPER
	)
	_footer(
		model.get("controls", "↑↓  CHOOSE    A / ENTER  ACT    Y / V  PRIVATE    START / P  PAUSE")
	)
	if not model.get("message", "").is_empty():
		_panel(_surface, Rect2(48, 216, 864, 85), Color("292a32"), GOLD)
		_label(_surface, model.message, Rect2(64, 229, 832, 62), 20, PAPER)


func _private_page(model: Dictionary) -> void:
	_panel(_surface, Rect2(32, 24, 896, 492), Color("111923"), Color("a6b4ba"))
	_label(
		_surface, "PRIVATE HANDOFF", Rect2(56, 45, 848, 25), 18, MUTED, HORIZONTAL_ALIGNMENT_CENTER
	)
	_label(
		_surface,
		model.get("title", "PASS THE CONTROLLER"),
		Rect2(64, 97, 832, 52),
		32,
		PAPER,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	if model.get("page") == "private":
		var portrait_path: String = model.get("portrait", "")
		if not portrait_path.is_empty() and ResourceLoader.exists(portrait_path):
			var portrait := TextureRect.new()
			portrait.texture = load(portrait_path) as Texture2D
			portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			portrait.position = Vector2(76, 172)
			portrait.size = Vector2(185, 218)
			_surface.add_child(portrait)
		_label(_surface, model.get("subtitle", ""), Rect2(280, 170, 580, 224), 20, PAPER)
	else:
		_label(
			_surface,
			model.get("subtitle", "Everyone else: look away.\nOpen only when the room is ready."),
			Rect2(120, 197, 720, 150),
			23,
			PAPER,
			HORIZONTAL_ALIGNMENT_CENTER
		)
	_choices(model, Rect2(248, 405, 464, 58), 1)
	_label(
		_surface,
		"B / ESC closes immediately  •  Help, pause or disconnect restores the shield",
		Rect2(64, 478, 832, 28),
		15,
		MUTED,
		HORIZONTAL_ALIGNMENT_CENTER
	)


func _seat_rail(model: Dictionary, top: float = 81) -> void:
	var seats: Array = model.get("seats", [])
	var width: float = (912.0 - maxi(0, seats.size() - 1) * 4) / maxi(1, seats.size())
	for index: int in seats.size():
		var row: Dictionary = seats[index]
		var active: bool = row.get("stable_seat_id") == model.get("active_seat")
		var color: Color = DrownedHarborDemoBoardView.COLORS[index % 8]
		var rect := Rect2(24 + index * (width + 4), top, width, 25)
		_panel(
			_surface,
			rect,
			Color("27353c") if active else Color("12232d"),
			GOLD if active else color
		)
		var symbol: String = DrownedHarborDemoBoardView.SYMBOLS[index % 8]
		var state: String = "  ACT" if active else ""
		if not row.get("connected", true):
			state = "  OFFLINE"
		_label(
			_surface,
			symbol + state,
			Rect2(rect.position + Vector2(7, 2), rect.size - Vector2(14, 2)),
			15,
			color,
			HORIZONTAL_ALIGNMENT_CENTER
		)


func _choices(model: Dictionary, area: Rect2, visible_count: int) -> void:
	var choices: Array = model.get("choices", [])
	var selected: int = clampi(int(model.get("selected", 0)), 0, maxi(0, choices.size() - 1))
	var first: int = maxi(0, selected - visible_count + 1)
	var row_height: float = minf(46, area.size.y / visible_count)
	for index: int in mini(visible_count, choices.size() - first):
		var at: int = first + index
		var choice: Dictionary = choices[at]
		var focused: bool = at == selected
		var rect := Rect2(
			area.position + Vector2(0, index * row_height), Vector2(area.size.x, row_height - 5)
		)
		_panel(
			_surface,
			rect,
			Color("384346") if focused else Color("172a33"),
			GOLD if focused else Color("374f58")
		)
		_label(
			_surface,
			("›  " if focused else "   ") + choice.get("label", "Continue"),
			Rect2(rect.position + Vector2(9, 4), rect.size - Vector2(17, 4)),
			19 if large_text else 18,
			PAPER if focused else MUTED
		)
	if choices.size() > visible_count:
		_label(
			_surface,
			"%d / %d" % [selected + 1, choices.size()],
			Rect2(area.end.x - 49, area.position.y - 20, 49, 20),
			13,
			GOLD,
			HORIZONTAL_ALIGNMENT_RIGHT
		)


func _background_art() -> void:
	var path: String = "res://assets/drowned_harbor_alpha4/harbor_board_texture.png"
	if ResourceLoader.exists(path):
		var art := TextureRect.new()
		art.texture = load(path) as Texture2D
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.size = Vector2(960, 540)
		art.modulate = Color("aac3c9")
		_surface.add_child(art)
	else:
		_rect(_surface, Rect2(565, 0, 395, 540), Color("173440"))
		for index: int in 9:
			_rect(_surface, Rect2(580 + index * 45, 190 - index % 3 * 22, 39, 250), Color("203d47"))


func _footer(value: String) -> void:
	_label(_surface, value, Rect2(24, 505, 912, 25), 15, MUTED)


func _body() -> int:
	return 20 if large_text else 18


func _label(
	parent: Node,
	value: String,
	rect: Rect2,
	font_size: int,
	color: Color,
	align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT
) -> void:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = value
	label.position = rect.position
	label.size = rect.size
	label.horizontal_alignment = align
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)


func _rect(parent: Node, rect: Rect2, color: Color) -> void:
	var region := ColorRect.new()
	region.position = rect.position
	region.size = rect.size
	region.color = color
	region.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(region)


func _panel(parent: Node, rect: Rect2, fill: Color, edge: Color) -> void:
	var panel := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", style)
	panel.position = rect.position
	panel.size = rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(panel)
