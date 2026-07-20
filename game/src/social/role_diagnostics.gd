class_name RoleDiagnostics
extends Control

const PAGE_COUNT: int = 3
const PANEL_SIZE := Vector2(840, 410)

var _panel: Panel
var _title: Label
var _body: Label
var _footer: Label
var _safe_margin: int = 24
var _page: int = 0
var _pages: Array[String] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.01, 0.01, 0.018, 0.94)
	add_child(backdrop)
	_panel = Panel.new()
	_panel.theme_type_variation = "SeatCardWarning"
	add_child(_panel)
	_title = Label.new()
	_title.position = Vector2(18, 12)
	_title.theme_type_variation = "SectionTitle"
	_panel.add_child(_title)
	_body = Label.new()
	_body.position = Vector2(18, 50)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.clip_text = true
	_body.max_lines_visible = 25
	_panel.add_child(_body)
	_footer = Label.new()
	_footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_footer.modulate = Color(1.0, 0.67, 0.45)
	_panel.add_child(_footer)
	visible = false
	_layout()


func set_safe_margin(value: int) -> void:
	_safe_margin = clampi(value, 0, 48)
	_layout()


func present(session: RoleSession, page: int = 0) -> void:
	var diagnostics: Dictionary = session.diagnostics_view(true)
	_pages = [_assignment_page(diagnostics), _seat_page(diagnostics), _privacy_page(diagnostics)]
	_page = posmod(page, PAGE_COUNT)
	_refresh()
	visible = true


func next_page(direction: int = 1) -> void:
	if _pages.is_empty():
		return
	_page = posmod(_page + direction, _pages.size())
	_refresh()


func rendered_text() -> String:
	return _body.text if is_instance_valid(_body) else ""


func _assignment_page(diagnostics: Dictionary) -> String:
	var lines := PackedStringArray(
		[
			(
				"CONTENT %s v%d  •  MODE %s  •  SNAPSHOT v%d"
				% [
					diagnostics.scenario_id,
					diagnostics.scenario_version,
					diagnostics.mode_id,
					RoleSession.SNAPSHOT_VERSION
				]
			),
			(
				"ROLE RNG seed=%d state=%d counter=%d  •  revision=%d"
				% [
					diagnostics.rng.initial_seed,
					diagnostics.rng.state,
					diagnostics.rng.counter,
					diagnostics.revision
				]
			),
			"Assignment plan and bounded audit are complete spoiler state.",
		]
	)
	for entry: Dictionary in diagnostics.audit_history.slice(
		maxi(0, diagnostics.audit_history.size() - 8)
	):
		lines.append(
			(
				"#%d r%d %s  %s"
				% [entry.sequence, entry.revision, entry.type, JSON.stringify(entry.private)]
			)
		)
	return "\n".join(lines)


func _seat_page(diagnostics: Dictionary) -> String:
	var lines := PackedStringArray(["COMPLETE SEAT ROLE / FACTION / FORM / OBJECTIVE / USE STATE"])
	for row: Dictionary in diagnostics.seat_states:
		var state: Dictionary = row.state
		lines.append(
			(
				"Seat %s  role=%s  form=%s  faction=%s"
				% [
					RoleSession.SEAT_NUMERALS[row.seat - 1],
					state.assigned_role_id,
					state.form_id,
					state.faction_id
				]
			)
		)
		lines.append(
			(
				"  life=%s reveal=%s defeat=%s connected=%s objectives=%s uses=%s"
				% [
					state.lifecycle,
					state.revealed,
					state.defeated,
					state.connected,
					state.objective_refs,
					state.uses
				]
			)
		)
	return "\n".join(lines)


func _privacy_page(diagnostics: Dictionary) -> String:
	var report: Dictionary = diagnostics.privacy_evaluation
	return (
		"\n"
		. join(
			PackedStringArray(
				[
					"PUBLIC / PRIVATE / DIRECTOR LEAK EVALUATION",
					(
						"passed=%s  public_or_director_leaks=%s"
						% [report.passed, report.public_or_director_leaks]
					),
					"unauthorized_seat_leaks=%s" % [report.unauthorized_seat_leaks],
					(
						"Director-safe allowlisted aggregate output: %s"
						% JSON.stringify(diagnostics.director_safe_signals)
					),
					"Public preview: %s" % JSON.stringify(diagnostics.public_preview),
					"Raw IDs, RNG, hidden objectives, causes, and private payloads stay on this spoiler-only surface.",
				]
			)
		)
	)


func _refresh() -> void:
	_title.text = "SPOILER DIAGNOSTICS — NOT PLAYER HUD  •  PAGE %d/%d" % [_page + 1, PAGE_COUNT]
	_body.text = _pages[_page]
	_footer.text = "DETERMINISTIC PAGING  •  LEFT/RIGHT CHANGE PAGE  •  X/T CLOSE"


func _layout() -> void:
	if not is_instance_valid(_panel):
		return
	var panel_rect: Rect2 = calculate_panel_rect(Vector2(960, 540), _safe_margin)
	_panel.position = panel_rect.position
	_panel.size = panel_rect.size
	_title.size = Vector2(panel_rect.size.x - 36.0, 30)
	_body.size = Vector2(panel_rect.size.x - 36.0, panel_rect.size.y - 104.0)
	_footer.position = Vector2(18, panel_rect.size.y - 38.0)
	_footer.size = Vector2(panel_rect.size.x - 36.0, 28)


static func calculate_panel_rect(viewport_size: Vector2, safe_margin: int) -> Rect2:
	var safe := Rect2(
		Vector2(safe_margin, safe_margin), viewport_size - Vector2(safe_margin, safe_margin) * 2.0
	)
	var desired := Vector2(
		minf(PANEL_SIZE.x, safe.size.x - 20.0), minf(PANEL_SIZE.y, safe.size.y - 20.0)
	)
	return Rect2(safe.position + (safe.size - desired) * 0.5, desired)
