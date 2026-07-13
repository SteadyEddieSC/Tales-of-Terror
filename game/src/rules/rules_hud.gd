class_name RulesHud
extends PanelContainer

const LAB_THEME: Theme = preload("res://assets/theme/terror_lab_theme.tres")
const PANEL_SIZE := Vector2(420, 344)

var _session: RulesSession
var _label: RichTextLabel
var _selection_by_seat: Dictionary = {}
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
	var safe: int = clampi(value, 0, 48)
	var panel_rect: Rect2 = calculate_panel_rect(Vector2(960, 540), safe)
	position = panel_rect.position
	size = panel_rect.size

static func calculate_panel_rect(viewport_size: Vector2, safe_margin: int) -> Rect2:
	var safe: int = clampi(safe_margin, 0, 48)
	return Rect2(Vector2(viewport_size.x - safe - PANEL_SIZE.x - 10.0, safe + 52.0), PANEL_SIZE)

func handle_navigation(seat_number: int, direction: int, confirm: bool, cancel: bool) -> bool:
	if _session.pending_prompt.is_empty() or not _session.pending_prompt.eligible_seats.has(seat_number):
		return false
	var options: Array = _session.pending_prompt.options
	var index: int = _selection_by_seat.get(seat_number, 0)
	if direction != 0:
		index = posmod(index + direction, options.size())
		_selection_by_seat[seat_number] = index
		refresh()
		return true
	if cancel and _session.pending_prompt.get("allow_pass", false):
		_session.submit_response(seat_number, [], _session.pending_prompt.revision)
		refresh()
		return true
	if confirm:
		_session.submit_response(seat_number, [options[index].id], _session.pending_prompt.revision)
		refresh()
		return true
	return false

func refresh() -> void:
	if not is_instance_valid(_label) or _session == null:
		return
	var d: Dictionary = _session.diagnostics_snapshot()
	var lines := PackedStringArray([
		"[font_size=20][b]TURN • EVENT • CARD ENGINE[/b][/font_size]",
		"[b]ROUND %d  ◆  %s  r%d[/b]" % [d.round, String(d.phase).to_upper(), d.phase_revision],
		"SEED %d  •  RNG #%d  •  %s" % [d.seed, d.rng_counter, _terminal_label()],
	])
	if not _last_presenter.is_empty():
		lines.append("\n[b]HOST ◉ %s[/b]" % _last_presenter.get("title", "EVENT"))
		lines.append(_last_presenter.get("body", ""))
	if not _session.pending_prompt.is_empty():
		lines.append("\n[b]CHOICE ▲ %s[/b]" % _session.pending_prompt.get("title", _session.pending_prompt.id))
		for option: Dictionary in _session.pending_prompt.options:
			lines.append("%s  %s — %s" % [option.get("symbol", "◇"), option.id, option.get("text", option.id)])
		lines.append("Eligible %s  •  Submitted %s" % [_seat_list(_session.pending_prompt.eligible_seats), _seat_list(_response_seats())])
	if not _session.recent_check.is_empty():
		lines.append("\n[b]CHECK ⚄ %s[/b]  raw %s %+d = %d  → %s" % [_session.recent_check.source_id, _session.recent_check.raw, _session.recent_check.modifier, _session.recent_check.total, String(_session.recent_check.outcome).to_upper()])
	lines.append("\n[b]CARDS ◫[/b] deck %d  discard %d  exhaust %d" % [_session.draw_pile.size(), _session.discard_pile.size(), _session.exhausted_pile.size()])
	for seat_number: int in _session.participating_seats.slice(0, 3):
		lines.append("Seat %s  hand %d  inventory %s" % [_roman(seat_number), _session.hands[seat_number].size(), _session.inventory[seat_number]])
	if _session.participating_seats.size() > 3:
		lines.append("+ %d more participating seats" % (_session.participating_seats.size() - 3))
	if not _session.active_vote.is_empty():
		lines.append("[b]VOTE ◈[/b] %s  quorum %d  tie: stable option ID" % [_session.active_vote.id, _session.active_vote.quorum])
	lines.append("\n[b]RECENT HISTORY[/b]")
	for entry: Dictionary in _session.history().slice(maxi(0, _session.history().size() - 4)):
		lines.append("#%03d %s" % [entry.sequence, entry.type])
	_label.text = "\n".join(lines)

func _on_state_changed(_change: Dictionary) -> void:
	refresh()

func _on_presentation_requested(payload: Dictionary) -> void:
	_last_presenter = payload.duplicate(true)
	refresh()

func _response_seats() -> Array[int]:
	var seats: Array[int] = []
	for seat: Variant in _session.pending_prompt.get("responses", {}): seats.append(seat)
	seats.sort()
	return seats

func _seat_list(seats: Array[int]) -> String:
	var labels := PackedStringArray()
	for seat: int in seats: labels.append(_roman(seat))
	return ",".join(labels) if not labels.is_empty() else "—"

func _roman(seat_number: int) -> String:
	return ["I", "II", "III", "IV", "V", "VI", "VII", "VIII"][seat_number - 1]

func _terminal_label() -> String:
	return ["RUNNING", "COMPLETED", "FAILED", "ABORTED"][_session.terminal_state]
