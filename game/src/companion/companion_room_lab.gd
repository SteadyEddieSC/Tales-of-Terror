class_name CompanionRoomLab
extends PanelContainer

const TOKENS: VisualTokens = preload("res://assets/theme/visual_tokens.tres")
const LAB_THEME: Theme = preload("res://assets/theme/terror_lab_theme.tres")

var _title: Label
var _status: Label
var _claims: Label
var _result: Label
var _footer: Label
var _combined: Label
var _safe_margin: int = 24


func _ready() -> void:
	theme = LAB_THEME
	theme_type_variation = "SeatCard"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	add_child(content)
	_title = Label.new()
	_title.theme_type_variation = "SectionTitle"
	content.add_child(_title)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_status)
	content.add_child(HSeparator.new())
	_claims = Label.new()
	_claims.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_claims)
	_result = Label.new()
	_result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_result.add_theme_color_override("font_color", TOKENS.parchment)
	content.add_child(_result)
	_footer = Label.new()
	_footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_footer.add_theme_color_override("font_color", TOKENS.muted_text)
	content.add_child(_footer)
	content.visible = false
	_combined = Label.new()
	_combined.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_combined.add_theme_font_size_override("font_size", 16)
	_combined.add_theme_constant_override("line_spacing", -2)
	add_child(_combined)
	set_safe_margin(_safe_margin)
	visible = false


func present(bridge: CompanionBridge, stage: String, outcome: Dictionary = {}) -> void:
	var diagnostics: Dictionary = bridge.diagnostics()
	_title.text = (
		"COMPANION ROOM LAB  •  %s" % stage.trim_prefix("companion_").replace("_", " ").to_upper()
	)
	_status.text = (
		"ROOM %s  •  IN-PROCESS FAKE TRANSPORT  •  PROTOCOL v%d / BRIDGE %s\nJOIN CODE  %s  •  CLIENTS %d / 8  •  PENDING %d  •  AUTHORITY r%d"
		% [
			diagnostics.room_state.to_upper(),
			diagnostics.protocol_version,
			diagnostics.bridge_version,
			diagnostics.join_code,
			diagnostics.connected_clients,
			diagnostics.pending_clients,
			diagnostics.last_authoritative_revision,
		]
	)
	var claim_lines: Array[String] = []
	for claim: Dictionary in diagnostics.seat_claims:
		var identity: Dictionary = bridge.seat_identity(claim.seat)
		(
			claim_lines
			. append(
				(
					"%s  SEAT %s  %s  %s  •  %s"
					% [
						identity.symbol.to_upper(),
						identity.numeral,
						identity.pattern.to_upper(),
						identity.color_name.to_upper(),
						"CONNECTED" if claim.connected else "RESERVED FOR RESUME",
					]
				)
			)
		)
	_claims.text = (
		"STABLE-SEAT CLAIMS\n%s"
		% ("No approved companion claims." if claim_lines.is_empty() else "\n".join(claim_lines))
	)
	_result.text = outcome.get("headline", "Host room is ready for explicit seat approval.")
	if outcome.has("detail"):
		_result.text += "\n" + outcome.detail
	_footer.text = (
		"SANITIZED DIAGNOSTICS  •  %s  •  DUP %d  STALE %d  MALFORMED %d  UNAUTHORIZED %d\nNative Godot remains authoritative. The relay owns no rules. Local controller play remains available."
		% [
			diagnostics.privacy,
			diagnostics.counters.duplicate,
			diagnostics.counters.stale,
			diagnostics.counters.malformed,
			diagnostics.counters.unauthorized,
		]
	)
	_combined.text = "\n".join(
		[_title.text, _status.text, "", _claims.text, "", _result.text, "", _footer.text]
	)
	visible = true


func set_safe_margin(value: int) -> void:
	_safe_margin = clampi(value, 0, 48)
	var rect: Rect2 = calculate_panel_rect(Vector2(960, 540), _safe_margin)
	position = rect.position
	size = rect.size


func rendered_text() -> String:
	return _combined.text if is_instance_valid(_combined) else ""


static func calculate_panel_rect(viewport_size: Vector2, safe_margin: int) -> Rect2:
	var safe := Rect2(
		Vector2(safe_margin, safe_margin), viewport_size - Vector2(safe_margin * 2, safe_margin * 2)
	)
	var width: float = minf(820.0, safe.size.x)
	var height: float = minf(396.0, safe.size.y - 46.0)
	return Rect2(
		Vector2(safe.get_center().x - width * 0.5, safe.position.y + 40.0), Vector2(width, height)
	)
