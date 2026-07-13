class_name RulesHud
extends PanelContainer

const LAB_THEME: Theme = preload("res://assets/theme/terror_lab_theme.tres")
const PANEL_SIZE := Vector2(420, 344)
const MAX_PLAYER_LINES: int = 18
const SEAT_SHAPES: PackedStringArray = ["●", "▲", "◆", "■", "★", "⬟", "♥", "✦"]
const ROMAN_NUMERALS: PackedStringArray = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII"]

var _session: RulesSession
var _label: RichTextLabel
var _selection_by_seat: Dictionary = {}
var _selection_prompt_key: String = ""
var _last_presenter: Dictionary = {}

func setup(session: RulesSession) -> void:
	_session = session
	_session.state_changed.connect(_on_state_changed)
	_session.presentation_requested.connect(_on_presentation_requested)

func _ready() -> void:
	theme = LAB_THEME
	theme_type_variation = "PanelContainer"
	position = Vector2(516, 76)
	size = PANEL_SIZE
	grow_horizontal = Control.GROW_DIRECTION_END
	grow_vertical = Control.GROW_DIRECTION_END
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var margin := MarginContainer.new()
	for side: String in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 12)
	add_child(margin)
	_label = RichTextLabel.new()
	_label.bbcode_enabled = true
	_label.fit_content = false
	_label.scroll_active = false
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.clip_contents = true
	margin.add_child(_label)
	refresh()

func set_safe_margin(value: int) -> void:
	var panel_rect: Rect2 = calculate_panel_rect(Vector2(960, 540), clampi(value, 0, 48))
	position = panel_rect.position
	size = panel_rect.size

static func calculate_panel_rect(viewport_size: Vector2, safe_margin: int) -> Rect2:
	var safe: int = clampi(safe_margin, 0, 48)
	return Rect2(Vector2(viewport_size.x - safe - PANEL_SIZE.x - 10.0, safe + 52.0), PANEL_SIZE)

func handle_navigation(seat_number: int, direction: int, confirm: bool, cancel: bool) -> bool:
	if _session == null or _session.pending_prompt.is_empty() or not _session.pending_prompt.eligible_seats.has(seat_number):
		return false
	_sync_prompt_selections()
	if _session.pending_prompt.responses.has(seat_number):
		return false
	var options: Array = _session.pending_prompt.options
	var index: int = _selection_by_seat.get(seat_number, 0)
	if direction != 0:
		_selection_by_seat[seat_number] = posmod(index + direction, options.size())
		refresh()
		return true
	if cancel and _session.pending_prompt.get("allow_pass", false):
		var pass_result: Dictionary = _session.submit_response(seat_number, [], _session.pending_prompt.revision)
		refresh()
		return pass_result.accepted
	if confirm:
		var confirm_result: Dictionary = _session.submit_response(seat_number, [options[index].id], _session.pending_prompt.revision)
		refresh()
		return confirm_result.accepted
	return false

func get_view_model() -> Dictionary:
	if _session == null:
		return {}
	_sync_prompt_selections()
	var model: Dictionary = {
		"title": "Turn • Event • Card Engine",
		"round_label": "Round %d" % _session.round_number,
		"phase_label": friendly_label(_session.current_phase()),
		"terminal_label": _terminal_label(),
		"mode": "prompt" if not _session.pending_prompt.is_empty() else ("terminal" if _session.terminal_state != RulesSession.TerminalState.RUNNING else "summary"),
		"presenter": {},
		"prompt": {},
		"check": {},
		"cards": {},
		"result_label": friendly_label(_session.terminal_reason),
		"continuation_label": "ⓘ More details: Diagnostics (X / T)",
		"continuation_visible": true,
	}
	if not _last_presenter.is_empty():
		model.presenter = {"title": _last_presenter.get("title", "Event"), "body": _last_presenter.get("body", "")}
	if not _session.pending_prompt.is_empty():
		model.prompt = _prompt_view_model()
	elif not _session.recent_check.is_empty():
		model.check = {
			"label": _definition_display_name(_session.recent_check.get("source_id", "")),
			"total": _session.recent_check.get("total", 0),
			"modifier": _session.recent_check.get("modifier", 0),
			"outcome": friendly_label(_session.recent_check.get("outcome", "")),
		}
	if _session.pending_prompt.is_empty():
		model.cards = _card_view_model()
	model["essential_lines"] = _compose_player_lines(model).size()
	model["essential_content_fits"] = model.essential_lines <= MAX_PLAYER_LINES
	return model

func rendered_player_text() -> String:
	return "\n".join(_compose_player_lines(get_view_model()))

func refresh() -> void:
	if not is_instance_valid(_label) or _session == null:
		return
	_label.text = rendered_player_text()

static func friendly_label(stable_id: String) -> String:
	if stable_id.is_empty():
		return "—"
	var words: PackedStringArray = stable_id.replace("-", "_").split("_", false)
	for index: int in words.size():
		words[index] = words[index].capitalize()
	return " ".join(words)

func _prompt_view_model() -> Dictionary:
	var prompt: Dictionary = _session.pending_prompt
	var options: Array[Dictionary] = []
	for option: Dictionary in prompt.options:
		options.append({"id": option.id, "label": option.get("text", friendly_label(option.id)), "symbol": option.get("symbol", "◇")})
	var seat_states: Array[Dictionary] = []
	for seat_number: int in _session.participating_seats:
		var eligible: bool = prompt.eligible_seats.has(seat_number)
		var state: String = "ineligible"
		var selected_id: String = ""
		var selected_label: String = "Not Eligible"
		if eligible:
			var response: Variant = prompt.responses.get(seat_number)
			if response is Array:
				if response.is_empty():
					state = "pass"
					selected_label = "Pass / Abstain"
				else:
					state = "locked"
					selected_id = response[0]
					selected_label = _option_label(options, selected_id)
			else:
				state = "unresolved"
				var index: int = _selection_by_seat.get(seat_number, 0)
				selected_id = options[index].id
				selected_label = options[index].label
		seat_states.append({
			"seat": seat_number,
			"numeral": ROMAN_NUMERALS[seat_number - 1],
			"symbol": SEAT_SHAPES[seat_number - 1],
			"pattern": "▰".repeat(seat_number),
			"eligible": eligible,
			"response_state": state,
			"current_option_id": selected_id,
			"current_option_label": selected_label,
			"status_symbol": {"unresolved": "○", "locked": "✓", "pass": "—", "ineligible": "×"}[state],
			"focus_symbol": "▶" if state == "unresolved" else "",
		})
	return {
		"title": prompt.get("title", friendly_label(prompt.get("id", "Choice"))),
		"kind_label": "Public Vote" if not _session.active_vote.is_empty() else "Choice",
		"options": options,
		"seat_states": seat_states,
	}

func _card_view_model() -> Dictionary:
	var seats: Array[Dictionary] = []
	for seat_number: int in _session.participating_seats.slice(0, 3):
		var item_names := PackedStringArray()
		for item_id: String in _session.inventory[seat_number]:
			var item: Dictionary = _session.content.item_by_id(item_id)
			item_names.append(item.get("name", friendly_label(item_id)))
		seats.append({"numeral": ROMAN_NUMERALS[seat_number - 1], "hand_count": _session.hands[seat_number].size(), "items": item_names})
	return {"deck_count": _session.draw_pile.size(), "discard_count": _session.discard_pile.size(), "exhaust_count": _session.exhausted_pile.size(), "seats": seats, "additional_seats": maxi(0, _session.participating_seats.size() - 3)}

func _compose_player_lines(model: Dictionary) -> PackedStringArray:
	if model.is_empty():
		return PackedStringArray()
	var lines := PackedStringArray([
		"[font_size=20][b]%s[/b][/font_size]" % model.title,
		"[b]%s  ◆  %s[/b]  •  %s" % [model.round_label, model.phase_label, model.terminal_label],
	])
	if model.mode == "prompt":
		if not model.presenter.is_empty():
			lines.append("[b]HOST ◉ %s[/b]" % model.presenter.title)
		lines.append("[b]%s ▲ %s[/b]" % [model.prompt.kind_label, model.prompt.title])
		for option: Dictionary in model.prompt.options.slice(0, 3):
			lines.append("%s  %s" % [option.symbol, option.label])
		if model.prompt.options.size() > 3:
			lines.append("+ %d options • use left / right" % (model.prompt.options.size() - 3))
		for seat: Dictionary in model.prompt.seat_states:
			var detail: String = "Not eligible"
			if seat.response_state == "unresolved": detail = "%s %s  •  choosing" % [seat.focus_symbol, seat.current_option_label]
			elif seat.response_state == "locked": detail = "%s  •  locked" % seat.current_option_label
			elif seat.response_state == "pass": detail = "Pass / Abstain  •  locked"
			lines.append("%s %s %s %s  %s" % [seat.status_symbol, seat.numeral, seat.symbol, seat.pattern, detail])
	else:
		if model.mode == "terminal":
			lines.append("[b]RESULT ◆ %s[/b]" % model.result_label)
		if not model.presenter.is_empty():
			lines.append("[b]HOST ◉ %s[/b]" % model.presenter.title)
			lines.append(model.presenter.body)
		if not model.check.is_empty():
			lines.append("[b]CHECK ⚄ %s[/b]  %d → %s" % [model.check.label, model.check.total, model.check.outcome])
		if not model.cards.is_empty():
			lines.append("[b]CARDS ◫[/b] deck %d  discard %d  exhaust %d" % [model.cards.deck_count, model.cards.discard_count, model.cards.exhaust_count])
			for seat: Dictionary in model.cards.seats:
				lines.append("Seat %s  hand %d  items: %s" % [seat.numeral, seat.hand_count, ", ".join(seat.items) if not seat.items.is_empty() else "None"])
			if model.cards.additional_seats > 0:
				lines.append("+ %d more seats • details in diagnostics" % model.cards.additional_seats)
	lines.append(model.continuation_label)
	return lines

func _sync_prompt_selections() -> void:
	if _session == null or _session.pending_prompt.is_empty():
		_selection_by_seat.clear()
		_selection_prompt_key = ""
		return
	var prompt_key: String = "%s:%d" % [_session.pending_prompt.get("id", ""), _session.pending_prompt.get("revision", 0)]
	if prompt_key != _selection_prompt_key:
		_selection_by_seat.clear()
		_selection_prompt_key = prompt_key
	for seat_number: int in _session.pending_prompt.eligible_seats:
		if not _selection_by_seat.has(seat_number):
			_selection_by_seat[seat_number] = 0

func _definition_display_name(stable_id: String) -> String:
	var event: Dictionary = _session.content.event_by_id(stable_id)
	if not event.is_empty(): return event.get("title", friendly_label(stable_id))
	var card: Dictionary = _session.content.card_by_id(stable_id)
	if not card.is_empty(): return card.get("name", friendly_label(stable_id))
	return friendly_label(stable_id)

func _option_label(options: Array[Dictionary], option_id: String) -> String:
	for option: Dictionary in options:
		if option.id == option_id: return option.label
	return friendly_label(option_id)

func _on_state_changed(_change: Dictionary) -> void:
	refresh()

func _on_presentation_requested(payload: Dictionary) -> void:
	_last_presenter = payload.duplicate(true)
	refresh()

func _terminal_label() -> String:
	return ["In Progress", "Completed", "Failed", "Aborted"][_session.terminal_state]
