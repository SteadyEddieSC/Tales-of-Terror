class_name DirectorHud
extends PanelContainer

const LAB_THEME: Theme = preload("res://assets/theme/terror_lab_theme.tres")
const PANEL_SIZE: Vector2 = Vector2(420, 250)
const MAX_PLAYER_LINES: int = 12

var _label: RichTextLabel
var _decision: Dictionary = {}
var _application: Dictionary = {}


func _ready() -> void:
	theme = LAB_THEME
	theme_type_variation = "PanelContainer"
	size = PANEL_SIZE
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
	visible = false


func present(decision: Dictionary, application: Dictionary) -> void:
	_decision = decision.duplicate(true)
	_application = application.duplicate(true)
	if is_instance_valid(_label):
		_label.text = rendered_player_text()
	visible = true


func rendered_player_text() -> String:
	if _decision.is_empty():
		return ""
	var presentation: Dictionary = _decision.get("presentation", {})
	var symbol: String = presentation.get("symbol", "◇")
	var pattern: String = presentation.get("pattern", "open ring")
	var lines := PackedStringArray(
		[
			"[font_size=20][b]DREAD DIRECTOR[/b][/font_size]",
			(
				"[b]%s[/b]  •  %s"
				% [_decision.profile_name, RulesHud.friendly_label(_decision.pacing_act)]
			),
			"%s  [b]%s[/b]" % [symbol, _decision.selected_name],
			"Pattern: %s" % pattern.capitalize(),
			_decision.selected_summary,
			"[b]WHY NOW[/b]  %s" % _decision.rationale,
		]
	)
	if _decision.target_seat > 0:
		lines.append(
			(
				"Target: Seat %s  %s"
				% [_roman(_decision.target_seat), "◆".repeat(_decision.target_seat)]
			)
		)
	var outcome: String = "Accepted" if _application.get("accepted", false) else "Held / No Change"
	if _decision.category == "no_op":
		outcome = "Intentional Hold — no state changed"
	lines.append("[b]OUTCOME[/b]  %s" % outcome)
	var proposal: Dictionary = _decision.get("proposal", {})
	if proposal.get("type", "") == "presentation":
		lines.append("HOST ◉ %s" % proposal.get("message", "The house offers an omen."))
	lines.append("ⓘ Scoring and raw telemetry: Diagnostics (X / T)")
	return "\n".join(lines.slice(0, MAX_PLAYER_LINES))


func get_view_model() -> Dictionary:
	return {
		"profile_name": _decision.get("profile_name", ""),
		"action_name": _decision.get("selected_name", ""),
		"rationale": _decision.get("rationale", ""),
		"target_seat": _decision.get("target_seat", 0),
		"line_count": rendered_player_text().split("\n").size(),
		"essential_content_fits": rendered_player_text().split("\n").size() <= MAX_PLAYER_LINES,
		"contains_raw_ids": _decision.get("selected_candidate_id", "") in rendered_player_text(),
	}


func set_safe_margin(value: int) -> void:
	var rect: Rect2 = calculate_panel_rect(Vector2(960, 540), value)
	position = rect.position
	size = rect.size


static func calculate_panel_rect(viewport_size: Vector2, safe_margin: int) -> Rect2:
	var safe: int = clampi(safe_margin, 0, 48)
	return Rect2(Vector2(viewport_size.x - safe - PANEL_SIZE.x - 10.0, safe + 60.0), PANEL_SIZE)


func _roman(seat: int) -> String:
	return RulesHud.ROMAN_NUMERALS[seat - 1]
