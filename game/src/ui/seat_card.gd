class_name SeatCard
extends PanelContainer

var _seat_number: int
var _tokens: VisualTokens
var _indicator: SeatAccent
var _symbol: Label
var _title: Label
var _badge_panel: PanelContainer
var _badge: Label
var _detail: Label
var _last_action: Label

func setup(seat_number: int, tokens: VisualTokens) -> void:
	_seat_number = seat_number
	_tokens = tokens
	custom_minimum_size = Vector2(250.0, 78.0)
	theme_type_variation = "SeatCard"
	_build()

func present(seat: Dictionary) -> void:
	var state: int = seat.state
	_indicator.configure(_tokens.player_colors[_seat_number - 1], _seat_number)
	_symbol.text = _tokens.player_symbols[_seat_number - 1]
	_title.text = "SEAT %d" % _seat_number
	_badge.text = SeatManager.state_label(state)
	_detail.text = str(seat.device_name)
	_last_action.text = "Last signal: %s" % str(seat.last_action)
	match state:
		SeatManager.SeatState.ACTIVE:
			theme_type_variation = "SeatCardActive"
			_badge_panel.theme_type_variation = "StatusBadgeActive"
		SeatManager.SeatState.DISCONNECTED, SeatManager.SeatState.RESERVED:
			theme_type_variation = "SeatCardWarning"
			_badge_panel.theme_type_variation = "StatusBadgeWarning"
			_detail.text = "Reconnect the same controller"
		SeatManager.SeatState.JOINING:
			theme_type_variation = "SeatCardFocus"
			_badge_panel.theme_type_variation = "StatusBadge"
		_:
			theme_type_variation = "SeatCard"
			_badge_panel.theme_type_variation = "StatusBadge"

func _build() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	add_child(row)
	_indicator = SeatAccent.new()
	_indicator.custom_minimum_size = Vector2(8.0, 0.0)
	row.add_child(_indicator)
	var symbol_panel := PanelContainer.new()
	symbol_panel.custom_minimum_size = Vector2(35.0, 35.0)
	row.add_child(symbol_panel)
	_symbol = Label.new()
	_symbol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_symbol.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_symbol.add_theme_font_size_override("font_size", 14)
	symbol_panel.add_child(_symbol)
	var text_stack := VBoxContainer.new()
	text_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_stack.add_theme_constant_override("separation", 1)
	row.add_child(text_stack)
	var heading := HBoxContainer.new()
	text_stack.add_child(heading)
	_title = Label.new()
	_title.theme_type_variation = "SeatTitle"
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(_title)
	_badge_panel = PanelContainer.new()
	_badge_panel.theme_type_variation = "StatusBadge"
	heading.add_child(_badge_panel)
	_badge = Label.new()
	_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_badge_panel.add_child(_badge)
	_detail = Label.new()
	_detail.theme_type_variation = "SeatDetail"
	_detail.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	text_stack.add_child(_detail)
	_last_action = Label.new()
	_last_action.theme_type_variation = "SeatDetail"
	_last_action.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	text_stack.add_child(_last_action)
