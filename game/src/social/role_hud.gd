class_name RoleHud
extends Control

const PANEL_SIZE := Vector2(820, 390)
const PRIVATE_PANEL_SIZE := Vector2(760, 360)
const MAX_PLAYER_LINES: int = 24

var _backdrop: ColorRect
var _panel: Panel
var _title: Label
var _body: Label
var _footer: Label
var _safe_margin: int = 24
var _rendered_text: String = ""
var _view_model: Dictionary = {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_backdrop = ColorRect.new()
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_backdrop.color = Color(0.015, 0.02, 0.035, 0.96)
	_backdrop.visible = false
	add_child(_backdrop)
	_panel = Panel.new()
	_panel.theme_type_variation = "SeatCardFocus"
	add_child(_panel)
	_title = Label.new()
	_title.position = Vector2(20, 14)
	_title.theme_type_variation = "SectionTitle"
	_title.size = Vector2(780, 32)
	_panel.add_child(_title)
	_body = Label.new()
	_body.position = Vector2(20, 54)
	_body.size = Vector2(780, 280)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_body.max_lines_visible = MAX_PLAYER_LINES
	_body.clip_text = true
	_panel.add_child(_body)
	_footer = Label.new()
	_footer.position = Vector2(20, 346)
	_footer.size = Vector2(780, 28)
	_footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_footer.modulate = Color(0.92, 0.82, 0.58)
	_panel.add_child(_footer)
	visible = false
	_layout()


func set_safe_margin(value: int) -> void:
	_safe_margin = clampi(value, 0, 48)
	_layout()


func present(session: RoleSession, view_spec: Dictionary) -> void:
	var kind: String = view_spec.get("kind", "public")
	var title: String = view_spec.get("title", "SOCIAL HORROR LAB")
	match kind:
		"seat_private":
			var seat: int = view_spec.get("seat", 0)
			_present_private(session.seat_private_view(seat), title)
		"outcome":
			_present_outcome(session.public_view(), title)
		_:
			_present_public(session.public_view(), title)
	visible = true
	_layout()


func get_view_model() -> Dictionary:
	return _view_model.duplicate(true)


func rendered_player_text() -> String:
	return _rendered_text


func handle_private_input(
	session: RoleSession, seat_number: int, confirm: bool, cancel: bool
) -> bool:
	if (
		_view_model.get("kind", "") != "seat_private"
		or _view_model.get("authorized_seat", 0) != seat_number
		or (not confirm and not cancel)
	):
		return false
	if confirm and not session.seat_states[seat_number].acknowledged:
		session.acknowledge_private_role(seat_number)
	_present_public(session.public_view(), "PRIVATE REVEAL CLOSED SAFELY")
	_layout()
	return true


func _present_public(view: Dictionary, title: String) -> void:
	_backdrop.color = Color(0.015, 0.02, 0.035, 0.90)
	_backdrop.visible = true
	_title.text = "%s  •  PUBLIC TV VIEW" % title
	var lines := PackedStringArray()
	lines.append(
		(
			"%s  •  r%d%s"
			% [
				view.mode_label,
				view.revision,
				"  •  AUTHORED SAFE FALLBACK" if view.fallback_active else ""
			]
		)
	)
	(
		lines
		. append(
			"Every row combines numeral, shape, count mark, symbol, pattern, text, and connection state."
		)
	)
	lines.append(view.afterlife_notice)
	for seat: Dictionary in view.seats:
		(
			lines
			. append(
				(
					"%s  %-9s  mark x%d  %s %s / %s  •  %s  •  %s"
					% [
						seat.numeral,
						seat.shape,
						seat.seat,
						seat.identity_symbol,
						seat.identity_label,
						seat.faction_label,
						seat.status,
						seat.connection,
					]
				)
			)
		)
		if not seat.legal_actions.is_empty():
			lines.append("    LEGAL: %s" % ", ".join(seat.legal_actions))
	if not view.get("fallback_message", "").is_empty():
		lines.append("SAFE FALLBACK: %s" % view.fallback_message)
	var history: Array = view.get("public_history", [])
	if not history.is_empty():
		lines.append("LATEST: %s" % history[-1].message)
	_rendered_text = "\n".join(lines)
	_body.text = _rendered_text
	_footer.text = (
		"PUBLIC CONTENT ONLY  •  Private reveals require an explicit obscured "
		+ "pass-and-play step"
	)
	_view_model = {
		"kind": "public",
		"essential_lines": lines.size(),
		"essential_content_fits": lines.size() <= MAX_PLAYER_LINES,
		"contains_private_ids": false,
		"safe_margin": _safe_margin
	}


func _present_private(view: Dictionary, title: String) -> void:
	_backdrop.color = Color(0.015, 0.02, 0.035, 0.98)
	_backdrop.visible = true
	_title.text = (
		"%s  •  SEAT %s ONLY" % [title, RoleSession.SEAT_NUMERALS[view.authorized_seat - 1]]
	)
	var private: Dictionary = view.private
	var lines := PackedStringArray()
	lines.append("SHARED SCREEN OBSCURED — PASS CONTROL TO THE AUTHORIZED SEAT")
	lines.append("ROLE: %s  •  FACTION: %s" % [private.role_label, private.faction_label])
	lines.append(private.role_description)
	lines.append("")
	lines.append("PRIVATE OBJECTIVES")
	for objective: Dictionary in private.objectives:
		lines.append("◇ %s — %s" % [objective.label, objective.description])
	lines.append("")
	lines.append("AUTHORIZED ACTIONS")
	for action: Dictionary in private.actions:
		lines.append("%s %s — %s" % [action.symbol, action.label, action.description])
	lines.append("")
	lines.append(
		"Acknowledge, close, then restore the public view. Companion devices remain future work."
	)
	_rendered_text = "\n".join(lines)
	_body.text = _rendered_text
	_footer.text = "PRIVATE REVEAL  •  A / SPACE ACKNOWLEDGE  •  B / ESC CLOSE SAFELY"
	_view_model = {
		"kind": "seat_private",
		"authorized_seat": view.authorized_seat,
		"essential_lines": lines.size(),
		"essential_content_fits": lines.size() <= MAX_PLAYER_LINES,
		"shared_screen_obscured": true,
		"safe_margin": _safe_margin
	}


func _present_outcome(view: Dictionary, title: String) -> void:
	_backdrop.color = Color(0.015, 0.02, 0.035, 0.90)
	_backdrop.visible = true
	_title.text = "%s  •  PUBLIC RESULT SUMMARY" % title
	var outcome: Dictionary = view.get("outcome", {})
	var lines := PackedStringArray()
	lines.append(outcome.get("summary", "Outcome not yet resolved."))
	lines.append("FACTIONS")
	for faction: Dictionary in outcome.get("factions", []):
		lines.append(
			(
				"%s %s  / %s  •  %s"
				% [faction.symbol, faction.label, faction.pattern, faction.result.to_upper()]
			)
		)
	lines.append("INDIVIDUAL SEATS")
	for seat: Dictionary in outcome.get("seats", []):
		lines.append(
			(
				"Seat %s  •  %s  •  %s"
				% [seat.numeral, seat.result.to_upper(), "; ".join(seat.objectives)]
			)
		)
	_rendered_text = "\n".join(lines)
	_body.text = _rendered_text
	_footer.text = "MULTIPLE WINNERS SUPPORTED  •  faction + individual + partial + mixed results"
	_view_model = {
		"kind": "outcome",
		"essential_lines": lines.size(),
		"essential_content_fits": lines.size() <= MAX_PLAYER_LINES,
		"safe_margin": _safe_margin
	}


func _layout() -> void:
	if not is_instance_valid(_panel):
		return
	var private_mode: bool = _view_model.get("kind", "") == "seat_private"
	var panel_rect: Rect2 = calculate_panel_rect(Vector2(960, 540), _safe_margin, private_mode)
	_panel.position = panel_rect.position
	_panel.size = panel_rect.size
	_title.size.x = panel_rect.size.x - 40.0
	_body.size = Vector2(panel_rect.size.x - 40.0, panel_rect.size.y - 110.0)
	_footer.position = Vector2(20, panel_rect.size.y - 38.0)
	_footer.size.x = panel_rect.size.x - 40.0


static func calculate_panel_rect(
	viewport_size: Vector2, safe_margin: int, private_mode: bool = false
) -> Rect2:
	var safe := Rect2(
		Vector2(safe_margin, safe_margin), viewport_size - Vector2(safe_margin, safe_margin) * 2.0
	)
	var desired: Vector2 = PRIVATE_PANEL_SIZE if private_mode else PANEL_SIZE
	desired.x = minf(desired.x, safe.size.x - 20.0)
	desired.y = minf(desired.y, safe.size.y - 20.0)
	return Rect2(safe.position + (safe.size - desired) * 0.5, desired)
