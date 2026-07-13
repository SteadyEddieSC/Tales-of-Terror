class_name DirectorDiagnostics
extends PanelContainer

const LAB_THEME: Theme = preload("res://assets/theme/terror_lab_theme.tres")
const MAX_LINES: int = 25
const PAGE_COUNT: int = 2

var _label: RichTextLabel
var _runtime: DirectorRuntime
var _telemetry: Dictionary = {}
var _decision: Dictionary = {}
var _application: Dictionary = {}
var _page: int = 0

func _ready() -> void:
	theme = LAB_THEME
	theme_type_variation = "PanelContainer"
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var margin := MarginContainer.new()
	for side: String in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 10)
	add_child(margin)
	_label = RichTextLabel.new()
	_label.bbcode_enabled = true
	_label.fit_content = false
	_label.scroll_active = false
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_font_size_override("normal_font_size", 11)
	_label.clip_contents = true
	margin.add_child(_label)
	visible = false

func present(runtime: DirectorRuntime, telemetry: Dictionary, decision: Dictionary, application: Dictionary) -> void:
	_runtime = runtime
	_telemetry = telemetry.duplicate(true)
	_decision = decision.duplicate(true)
	_application = application.duplicate(true)
	refresh()

func toggle() -> void:
	visible = not visible

func next_page(direction: int = 1) -> void:
	_page = posmod(_page + direction, PAGE_COUNT)
	refresh()

func refresh() -> void:
	if not is_instance_valid(_label):
		return
	_label.text = rendered_text()

func rendered_text() -> String:
	if _runtime == null or _decision.is_empty():
		return "DIRECTOR DIAGNOSTICS — no decision"
	var lines := PackedStringArray([
		"[font_size=17][b]DIRECTOR DIAGNOSTICS  •  PAGE %d/%d[/b][/font_size]" % [_page + 1, PAGE_COUNT],
		"Profile %s  content %s v%d  revision %d  RNG #%d→#%d" % [_decision.profile_id, _runtime.content.content_id, _runtime.content.content_version, _runtime.revision, _decision.rng_before, _decision.rng_after],
		"Act %s  target %s  estimated %d  momentum pressure=%d relief=%d" % [_decision.pacing_act, _decision.target_tension, _decision.estimated_tension, _decision.pressure_momentum, _decision.relief_momentum],
	])
	if _page == 0:
		lines.append("[b]NORMALIZED TELEMETRY[/b]")
		lines.append("progress=%d failure=%d resources=%d hazards=%d spread=%d stalled=%d latency=%d pass=%d imbalance=%d rejected=%d" % [
			_telemetry.progress, _telemetry.failure_pressure, _telemetry.resource_pressure, _telemetry.hazard_pressure, _telemetry.group_spread,
			_telemetry.stalled_steps, _telemetry.prompt_latency, _telemetry.pass_frequency, _telemetry.participation_imbalance, _telemetry.rejected_actions,
		])
		lines.append("Active seats %s  disconnected %s  mercy=%s" % [_telemetry.active_seats, _telemetry.disconnected_seats, _decision.mercy_active])
		lines.append("[b]SELECTED[/b]  %s  id=%s  category=%s  target=%s  score=%d" % [_decision.selected_name, _decision.selected_candidate_id, _decision.category, _decision.target_seat, _decision.final_score])
		var component_parts := PackedStringArray()
		for key: String in _decision.score_components:
			component_parts.append("%s=%s" % [key, _decision.score_components[key]])
		lines.append("BREAKDOWN  " + " | ".join(component_parts))
		lines.append("Tie break %s  contenders=%s  draw=%s" % [_decision.tie_break.method, _decision.tie_break.contenders, _decision.tie_break.draw])
		lines.append("Application accepted=%s authority=%s downstream=%s core_rng=%s→%s" % [_application.get("accepted", false), _application.get("authority", "none"), _application.get("downstream_revision", -1), _application.get("core_rng_before", -1), _application.get("core_rng_after", -1)])
		lines.append("[b]CANDIDATE EVALUATIONS[/b]")
		for evaluation: Dictionary in _decision.candidate_evaluations:
			var status: String = "eligible" if evaluation.eligible else "rejected:" + ",".join(evaluation.rejection_reasons)
			lines.append("%s  score=%d target=%d  %s" % [evaluation.candidate_id, evaluation.final_score, evaluation.target_seat, status])
	else:
		var diagnostics: Dictionary = _runtime.diagnostics_snapshot()
		lines.append("[b]RUNTIME STATE[/b]")
		lines.append("Budgets %s" % diagnostics.budgets)
		lines.append("Candidate cooldowns %s" % diagnostics.candidate_cooldowns)
		lines.append("Tag cooldowns %s" % diagnostics.tag_cooldowns)
		lines.append("Recovery until step %d  last no-op %s" % [diagnostics.recovery_until_step, diagnostics.last_no_op_reason])
		lines.append("Target ledger %s" % diagnostics.target_ledger)
		lines.append("Last application %s" % diagnostics.last_application)
		lines.append("Audit entries %d/%d" % [diagnostics.audit_history.size(), DirectorRuntime.AUDIT_LIMIT])
		for audit: Dictionary in diagnostics.audit_history.slice(maxi(0, diagnostics.audit_history.size() - 8)):
			lines.append("step=%s selected=%s target=%s score=%s accepted=%s" % [audit.get("evaluation_step", -1), audit.get("selected_candidate_id", "—"), audit.get("target_seat", 0), audit.get("final_score", 0), audit.get("application", {}).get("accepted", false)])
	if lines.size() > MAX_LINES:
		lines = lines.slice(0, MAX_LINES - 1)
		lines.append("… continued on the next diagnostics page")
	else:
		lines.append("Page %d/%d  •  intentional paging; no silent overflow" % [_page + 1, PAGE_COUNT])
	return "\n".join(lines)

func set_safe_margin(value: int) -> void:
	var rect: Rect2 = calculate_panel_rect(Vector2(960, 540), value)
	position = rect.position
	size = rect.size

static func calculate_panel_rect(viewport_size: Vector2, safe_margin: int) -> Rect2:
	var safe: int = clampi(safe_margin, 0, 48)
	var inset: float = 10.0
	return Rect2(Vector2(safe + inset, safe + 48.0), Vector2(viewport_size.x - safe * 2.0 - inset * 2.0, viewport_size.y - safe * 2.0 - 106.0))
