class_name DrownedHarborControlledPrivateShieldShell
extends Control

signal prototype_private_commit_recorded(metadata: Dictionary)
signal prototype_public_event_emitted(payload: Dictionary)

enum SurfaceMode {
	PUBLIC_READY,
	NEUTRAL_SHIELD,
	PRIVATE_REVIEW,
	PRIVATE_CONFIRMATION,
	RESTORING,
	PUBLIC_RESTORED,
	RECOVERY,
}

const ADAPTER_SCRIPT: Script = preload(
	"res://tests/drowned_harbor_dev_only/controlled_private_fixture_adapter.gd"
)
const PRIVATE_SURFACE_SCRIPT: Script = preload(
	"res://tests/drowned_harbor_dev_only/controlled_private_surface.gd"
)
const NEUTRAL_SHIELD_TEXT: String = "PRIVATE REVIEW IN PROGRESS"
const NEUTRAL_SHIELD_FOCUS: String = "private_review_notice"
const NEUTRAL_SHIELD_COLOR: String = "neutral_shield"
const NEUTRAL_SHIELD_ICON: String = "none"
const NEUTRAL_SHIELD_ANIMATION: String = "none"
const SUPPORTED_ACTIONS: PackedStringArray = [
	"help_accessibility",
	"ui_cancel_action",
	"ui_confirm",
	"ui_navigate_down",
	"ui_navigate_left",
	"ui_navigate_right",
	"ui_navigate_up",
]

var _adapter: DrownedHarborControlledPrivateFixtureAdapter = ADAPTER_SCRIPT.new()
var _private_surface: DrownedHarborControlledPrivateSurface = PRIVATE_SURFACE_SCRIPT.new()
var _mode: int = SurfaceMode.PUBLIC_READY
var _private_projection_result: Dictionary = {}
var _pending_public_result: Dictionary = {}
var _public_history: Array[Dictionary] = []
var _public_replay: Array[Dictionary] = []
var _public_transcript: Array[String] = []
var _public_audio_requests: Array[String] = []
var _mirrored_output: Array[Dictionary] = []
var _diagnostics: Array[Dictionary] = []
var _lifecycle_audit: Array[String] = []
var _commit_count: int = 0
var _public_event_count: int = 0
var _help_open: bool = false
var _voice_enabled: bool = false
var _status: String = "Public fixture state ready."
var _title_label: Label
var _body_label: Label
var _prompt_label: Label


func _ready() -> void:
	_build_ui()
	_refresh_ui()


func begin_handoff(request: Dictionary, private_surface_available: bool = true) -> Dictionary:
	if not _private_surface.is_cleared() or not _private_projection_result.is_empty():
		return _fail_closed("uncleared_private_payload")
	if _mode == SurfaceMode.RESTORING:
		return _fail_closed("public_restoration_pending")
	_enter_neutral_shield()
	_private_surface.set_available(private_surface_available)
	if not private_surface_available:
		_lifecycle_audit.append("private_surface_unavailable")
		return _fail_closed("private_surface_unavailable", false)
	_lifecycle_audit.append("private_payload_requested")
	var projected: Dictionary = _adapter.load_and_project(request)
	if not projected.get("accepted", false):
		_adapter.clear_loaded_fixture()
		return _fail_closed(str(projected.get("code", "malformed_handoff")), false)
	var opened: Dictionary = _private_surface.open_handoff(projected, request)
	if not opened.get("accepted", false):
		_adapter.clear_loaded_fixture()
		return _fail_closed(str(opened.get("code", "private_surface_unavailable")), false)
	_private_projection_result = projected
	_mode = SurfaceMode.PRIVATE_REVIEW
	_status = NEUTRAL_SHIELD_TEXT
	_lifecycle_audit.append("private_payload_revealed_on_authorized_surface")
	_refresh_ui()
	return {
		"accepted": true,
		"mode": mode_name(),
		"public_snapshot": public_snapshot(),
	}


func navigate_private(delta: int) -> Dictionary:
	var before: Dictionary = fixture_signature()
	var result: Dictionary = _private_surface.navigate(delta)
	if result.get("accepted", false):
		_mode = SurfaceMode.PRIVATE_REVIEW
		_status = NEUTRAL_SHIELD_TEXT
		_refresh_ui()
	result["fixture_unchanged"] = fixture_signature() == before
	return result


func request_acknowledgement() -> Dictionary:
	var result: Dictionary = _private_surface.request_acknowledgement()
	if result.get("accepted", false):
		_mode = SurfaceMode.PRIVATE_CONFIRMATION
		_status = NEUTRAL_SHIELD_TEXT
		_lifecycle_audit.append("explicit_acknowledgement_requested")
		_refresh_ui()
	return result


func acknowledge(request: Dictionary) -> Dictionary:
	if _mode != SurfaceMode.PRIVATE_CONFIRMATION:
		return _fail_closed("private_handoff_not_active")
	var before: Dictionary = fixture_signature()
	var acknowledged: Dictionary = _private_surface.acknowledge(request)
	if not acknowledged.get("accepted", false):
		return _fail_closed(str(acknowledged.get("code", "malformed_handoff")))
	if _commit_count != 0:
		return _fail_closed("duplicate_acknowledgement")
	var private_event_key: String = str(acknowledged.get("private_event_key", ""))
	var public_event: Dictionary = _private_projection_result.get("public_event", {}).duplicate(
		true
	)
	var public_resolution: Dictionary = (
		_private_projection_result.get("public_resolution", {}).duplicate(true)
	)
	var source_revision: int = int(_private_projection_result.get("source_revision", -1))
	var result_revision: int = int(_private_projection_result.get("result_revision", -1))
	if private_event_key.is_empty() or public_event.is_empty() or public_resolution.is_empty():
		return _fail_closed("malformed_handoff")
	_pending_public_result = {
		"event":
		_build_sanitized_public_event(
			public_event,
			public_resolution,
			source_revision,
			result_revision,
		),
		"resolution": public_resolution,
		"result_revision": result_revision,
		"source_revision": source_revision,
	}
	_commit_count += 1
	(
		prototype_private_commit_recorded
		. emit(
			{
				"classification": "private",
				"event_key": private_event_key,
				"exactly_once": true,
				"payload_cleared": true,
				"production_authority": false,
			}
		)
	)
	_private_projection_result.clear()
	_adapter.clear_loaded_fixture()
	_mode = SurfaceMode.RESTORING
	_status = NEUTRAL_SHIELD_TEXT
	_lifecycle_audit.append("private_payload_cleared_before_public_restoration")
	_refresh_ui()
	return {
		"accepted": true,
		"commit_count": _commit_count,
		"fixture_unchanged": fixture_signature().is_empty() or fixture_signature() == before,
		"mode": mode_name(),
		"private_state_cleared": private_state_cleared(),
	}


func restore_public(succeeds: bool = true) -> Dictionary:
	if _mode not in [SurfaceMode.RESTORING, SurfaceMode.RECOVERY]:
		return _fail_closed("public_restoration_not_pending")
	if not private_state_cleared():
		return _fail_closed("private_payload_not_cleared")
	if _pending_public_result.is_empty():
		return _fail_closed("public_restoration_not_pending")
	if not succeeds:
		_mode = SurfaceMode.RECOVERY
		_status = NEUTRAL_SHIELD_TEXT
		_lifecycle_audit.append("public_restoration_failed_safe")
		_refresh_ui()
		return {
			"accepted": false,
			"code": "public_restoration_failed",
			"private_state_cleared": true,
		}
	var event: Dictionary = _pending_public_result.get("event", {}).duplicate(true)
	var resolution: Dictionary = _pending_public_result.get("resolution", {}).duplicate(true)
	if _contains_private_marker({"event": event, "resolution": resolution}):
		return _fail_closed("private_data_rejected")
	if _public_event_count == 0:
		_public_event_count = 1
		_public_history.append(event.duplicate(true))
		_public_replay.append(event.duplicate(true))
		_public_transcript.append(str(resolution.get("caption", "")))
		_mirrored_output.append(resolution.duplicate(true))
		prototype_public_event_emitted.emit(event.duplicate(true))
	_pending_public_result.clear()
	_mode = SurfaceMode.PUBLIC_RESTORED
	_status = str(resolution.get("public_resolution", ""))
	if _status.is_empty():
		_status = str(resolution.get("public_consequence", ""))
	_lifecycle_audit.append("public_projection_restored")
	_refresh_ui()
	return {
		"accepted": true,
		"commit_count": _commit_count,
		"mode": mode_name(),
		"public_event_count": _public_event_count,
		"public_snapshot": public_snapshot(),
	}


func cancel_or_defer() -> Dictionary:
	_private_surface.cancel()
	_private_projection_result.clear()
	_pending_public_result.clear()
	_adapter.clear_loaded_fixture()
	_help_open = false
	_mode = SurfaceMode.PUBLIC_READY
	_status = "Public fixture state ready."
	_lifecycle_audit.append("private_handoff_cancelled_and_cleared")
	_refresh_ui()
	return {"accepted": true, "commit_count": _commit_count, "deferred": true}


func handle_disconnect() -> Dictionary:
	if _mode == SurfaceMode.RESTORING:
		_mode = SurfaceMode.RECOVERY
		_status = NEUTRAL_SHIELD_TEXT
		_lifecycle_audit.append("disconnect_after_acknowledgement_safe")
		_refresh_ui()
		return {"accepted": true, "private_state_cleared": private_state_cleared()}
	_private_surface.disconnect_surface()
	_private_projection_result.clear()
	_adapter.clear_loaded_fixture()
	_help_open = false
	_mode = SurfaceMode.NEUTRAL_SHIELD
	_status = NEUTRAL_SHIELD_TEXT
	_lifecycle_audit.append("disconnect_cleared_private_state")
	_refresh_ui()
	return {"accepted": true, "private_state_cleared": private_state_cleared()}


func interrupt_presentation() -> Dictionary:
	_private_surface.clear_private_state()
	_private_projection_result.clear()
	_adapter.clear_loaded_fixture()
	_help_open = false
	_mode = SurfaceMode.NEUTRAL_SHIELD
	_status = NEUTRAL_SHIELD_TEXT
	_lifecycle_audit.append("interruption_cleared_private_state")
	_refresh_ui()
	return {"accepted": true, "private_state_cleared": private_state_cleared()}


func open_help() -> Dictionary:
	_help_open = true
	_status = NEUTRAL_SHIELD_TEXT
	_refresh_ui()
	return {
		"accepted": true,
		"guidance": "Use the authorized private surface, or cancel and continue safely.",
		"public_snapshot": public_snapshot(),
	}


func dispatch_semantic_action(action: String) -> Dictionary:
	if not SUPPORTED_ACTIONS.has(action):
		return _fail_closed("unsupported_input")
	var result: Dictionary = {}
	match action:
		"ui_navigate_left", "ui_navigate_up":
			result = navigate_private(-1)
		"ui_navigate_right", "ui_navigate_down":
			result = navigate_private(1)
		"ui_confirm":
			result = request_acknowledgement()
		"ui_cancel_action":
			result = cancel_or_defer()
		"help_accessibility":
			result = open_help()
	if result.is_empty():
		return _fail_closed("unsupported_input")
	return result


func public_snapshot() -> Dictionary:
	if (
		_mode
		in [
			SurfaceMode.NEUTRAL_SHIELD,
			SurfaceMode.PRIVATE_REVIEW,
			SurfaceMode.PRIVATE_CONFIRMATION,
			SurfaceMode.RESTORING,
			SurfaceMode.RECOVERY,
		]
	):
		return {
			"animation": NEUTRAL_SHIELD_ANIMATION,
			"caption": NEUTRAL_SHIELD_TEXT,
			"color": NEUTRAL_SHIELD_COLOR,
			"controller_prompts": "B / ESC: CANCEL  |  X / H: HELP",
			"focus": NEUTRAL_SHIELD_FOCUS,
			"help_open": _help_open,
			"icon": NEUTRAL_SHIELD_ICON,
			"layout": "neutral_full_screen",
			"mode": "neutral_shield",
			"public_text": NEUTRAL_SHIELD_TEXT,
			"seat_rail": [],
			"shared_audio_requests": _public_audio_requests.duplicate(),
			"timing": "deterministic_fixture_state_only",
			"voice_enabled": _voice_enabled,
		}
	return {
		"caption": _status,
		"controller_prompts": "A / ENTER: CONTINUE  |  X / H: HELP",
		"mode": mode_name(),
		"public_history": _public_history.duplicate(true),
		"public_text": _status,
		"shared_audio_requests": _public_audio_requests.duplicate(),
		"voice_enabled": _voice_enabled,
	}


func private_surface_snapshot() -> Dictionary:
	return _private_surface.private_snapshot()


func privacy_outputs() -> Dictionary:
	return {
		"diagnostics": _diagnostics.duplicate(true),
		"mirrored_output": _mirrored_output.duplicate(true),
		"public_audio": _public_audio_requests.duplicate(),
		"public_history": _public_history.duplicate(true),
		"replay": _public_replay.duplicate(true),
		"transcript": _public_transcript.duplicate(),
	}


func private_state_cleared() -> bool:
	return _private_surface.is_cleared() and _private_projection_result.is_empty()


func clearing_snapshot() -> Dictionary:
	var snapshot: Dictionary = _private_surface.clearing_snapshot()
	snapshot["adapter_fixture_empty"] = fixture_signature().is_empty()
	snapshot["shell_private_projection_empty"] = _private_projection_result.is_empty()
	return snapshot


func fixture_signature() -> Dictionary:
	return _adapter.state_signature()


func _lifecycle_audit_snapshot() -> Array[String]:
	return _lifecycle_audit.duplicate()


func _prototype_commit_count() -> int:
	return _commit_count


func _public_event_count_snapshot() -> int:
	return _public_event_count


func mode_name() -> String:
	return str(SurfaceMode.keys()[_mode]).to_lower()


func set_voice_enabled(enabled: bool) -> void:
	_voice_enabled = enabled
	_refresh_ui()


func _unhandled_input(event: InputEvent) -> void:
	for action: String in SUPPORTED_ACTIONS:
		if event.is_action_pressed(action):
			dispatch_semantic_action(action)
			get_viewport().set_input_as_handled()
			return


func _enter_neutral_shield() -> void:
	_mode = SurfaceMode.NEUTRAL_SHIELD
	_status = NEUTRAL_SHIELD_TEXT
	_help_open = false
	_public_audio_requests.clear()
	_lifecycle_audit.append("neutral_shield_entered_before_private_request")
	_refresh_ui()


func _fail_closed(code: String, record_diagnostic: bool = true) -> Dictionary:
	if record_diagnostic:
		_diagnostics.append({"code": code, "private_payload": false})
	_status = NEUTRAL_SHIELD_TEXT
	if _mode not in [SurfaceMode.PUBLIC_READY, SurfaceMode.PUBLIC_RESTORED]:
		_mode = SurfaceMode.RECOVERY
	_refresh_ui()
	return {
		"accepted": false,
		"code": code,
		"commit_count": _commit_count,
		"private_state_cleared": private_state_cleared(),
	}


static func _build_sanitized_public_event(
	event: Dictionary,
	resolution: Dictionary,
	source_revision: int,
	result_revision: int,
) -> Dictionary:
	var sanitized_result: String = str(resolution.get("public_consequence", ""))
	if sanitized_result.is_empty():
		sanitized_result = str(resolution.get("public_resolution", ""))
	return {
		"classification": "public",
		"event_key": event.get("event_key", ""),
		"exactly_once": true,
		"payload":
		{
			"public_result": sanitized_result,
			"result_revision": result_revision,
			"source_revision": source_revision,
		},
	}


static func _contains_private_marker(value: Variant) -> bool:
	return "PRIVATE_" in JSON.stringify(value, "", true)


func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(root)
	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_title_label)
	_body_label = Label.new()
	_body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_body_label)
	_prompt_label = Label.new()
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_prompt_label)


func _refresh_ui() -> void:
	if _title_label == null:
		return
	var snapshot: Dictionary = public_snapshot()
	_title_label.text = str(snapshot.get("public_text", ""))
	_body_label.text = str(snapshot.get("caption", ""))
	_prompt_label.text = str(snapshot.get("controller_prompts", ""))
