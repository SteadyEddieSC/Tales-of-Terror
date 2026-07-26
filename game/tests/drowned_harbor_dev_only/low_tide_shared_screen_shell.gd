class_name DrownedHarborLowTideSharedScreenShell
extends Control

signal prototype_intent_emitted(payload: Dictionary)

enum SurfaceMode {
	BOARD,
	INSPECT,
	PREVIEW,
	CONFIRMATION,
	TRANSCRIPT,
	RECOVERY,
}

const SHELL_THEME: Theme = preload("res://assets/theme/terror_lab_theme.tres")
const ADAPTER_SCRIPT: Script = preload(
	"res://tests/drowned_harbor_dev_only/low_tide_fixture_adapter.gd"
)
const LANDMARKS: PackedStringArray = [
	"Damaged Causeway",
	"Bellhouse",
	"Salt Market",
	"Lifeboat Shed",
	"Distant Lighthouse",
]
const SUPPORTED_ACTIONS: PackedStringArray = [
	"diagnostic_test",
	"help_accessibility",
	"interact",
	"ui_cancel_action",
	"ui_confirm",
	"ui_navigate_down",
	"ui_navigate_left",
	"ui_navigate_right",
	"ui_navigate_up",
]

var _adapter: DrownedHarborLowTideFixtureAdapter = ADAPTER_SCRIPT.new()
var _projection_result: Dictionary = {}
var _focus_index: int = 0
var _mode: int = SurfaceMode.BOARD
var _pending_confirmation: Dictionary = {}
var _status_message: String = "Fixture ready. No authoritative action has been committed."
var _voice_enabled: bool = false
var _title_label: Label
var _objective_label: Label
var _board_label: Label
var _seat_label: Label
var _focus_label: Label
var _caption_label: Label
var _prompt_label: Label
var _status_label: Label


func _ready() -> void:
	theme = SHELL_THEME
	if _projection_result.is_empty():
		initialize_from_fixture()
	_build_ui()
	_refresh_ui()


func initialize_from_fixture(
	path: String = DrownedHarborLowTideFixtureAdapter.FIXTURE_PATH
) -> Dictionary:
	var loaded: Dictionary = _adapter.load_fixture(path)
	if not loaded.get("accepted", false):
		return _enter_recovery(str(loaded.get("reason", "fixture_load_failed")))
	var projected: Dictionary = _adapter.project(_adapter.default_request())
	if not projected.get("accepted", false):
		return _enter_recovery(str(projected.get("reason", "fixture_projection_failed")))
	_projection_result = projected
	_focus_index = 0
	_mode = SurfaceMode.BOARD
	_pending_confirmation.clear()
	_status_message = "Fixture ready. No authoritative action has been committed."
	_refresh_ui()
	return {"accepted": true, "snapshot": render_snapshot()}


func dispatch_semantic_action(action: String) -> Dictionary:
	if not SUPPORTED_ACTIONS.has(action):
		return _enter_recovery("unsupported_input")
	var result: Dictionary = {}
	match action:
		"ui_navigate_left", "ui_navigate_up":
			result = _move_focus(-1)
		"ui_navigate_right", "ui_navigate_down":
			result = _move_focus(1)
		"interact":
			result = _open_inspect()
		"ui_confirm":
			if _mode == SurfaceMode.CONFIRMATION:
				result = confirm_pending(
					_adapter.source_revision(),
					_adapter.stable_seat_id(),
				)
			else:
				result = _request_confirmation()
		"ui_cancel_action":
			result = cancel()
		"help_accessibility":
			result = open_transcript()
		"diagnostic_test":
			result = request_replay()
	return result


func cancel() -> Dictionary:
	_pending_confirmation.clear()
	_mode = SurfaceMode.BOARD
	_status_message = "Cancelled. Fixture state and RNG remain unchanged."
	_refresh_ui()
	return {
		"accepted": true,
		"intent": "cancel",
		"state_signature": state_signature(),
	}


func open_transcript() -> Dictionary:
	if _projection_result.is_empty():
		return _enter_recovery("fixture_not_ready")
	_mode = SurfaceMode.TRANSCRIPT
	_status_message = "Public transcript opened. No private fixture data is available."
	var payload: Dictionary = {
		"classification": "public",
		"event_key": "prototype_transcript_open_requested",
		"lines": _projection_result.get("transcript", []).duplicate(true),
		"source_revision": _adapter.source_revision(),
	}
	return _emit_public_intent(payload)


func request_replay() -> Dictionary:
	if _projection_result.is_empty():
		return _enter_recovery("fixture_not_ready")
	_mode = SurfaceMode.PREVIEW
	_status_message = "Public replay intent prepared. Authoritative state is unchanged."
	var payload: Dictionary = {
		"classification": "public",
		"event_key": "prototype_replay_requested",
		"replay": _projection_result.get("replay", {}).duplicate(true),
		"source_revision": _adapter.source_revision(),
	}
	return _emit_public_intent(payload)


func confirm_pending(current_revision: int, stable_seat_id: String) -> Dictionary:
	if _pending_confirmation.is_empty():
		return _enter_recovery("confirmation_not_pending")
	if current_revision != _pending_confirmation.get("source_revision"):
		return _enter_recovery("stale_confirmation_revision")
	if stable_seat_id != _pending_confirmation.get("stable_seat_id"):
		return _enter_recovery("wrong_confirmation_authority")
	var payload: Dictionary = {
		"action": _pending_confirmation.get("action", ""),
		"authoritative_commit": false,
		"classification": "public",
		"event_key": "prototype_confirmation_requested",
		"revision_bound": true,
		"source_revision": current_revision,
		"stable_seat_id": stable_seat_id,
	}
	_pending_confirmation.clear()
	_mode = SurfaceMode.PREVIEW
	_status_message = (
		"Confirmation seam emitted. Final movement and gameplay authority are not implemented."
	)
	return _emit_public_intent(payload)


func set_voice_enabled(enabled: bool) -> void:
	_voice_enabled = enabled
	_refresh_ui()


func render_snapshot() -> Dictionary:
	if _projection_result.is_empty():
		return {
			"accepted": false,
			"mode": mode_name(),
			"status": _status_message,
		}
	var projection: Dictionary = _projection_result.get("projection", {})
	var active_seat: Dictionary = projection.get("active_seat", {})
	var legal_actions: Array = projection.get("legal_actions", [])
	var focused_action: String = ""
	if not legal_actions.is_empty():
		focused_action = str(legal_actions[_focus_index])
	return {
		"accepted": true,
		"active_seat_label": (
			"ACTIVE %s • HUMAN • %s"
			% [
				str(active_seat.get("seat_id", "")).to_upper(),
				str(active_seat.get("location", "")).to_upper(),
			]
		),
		"board_geometry": {
			"kind": "placeholder_geometry_not_final",
			"landmarks": Array(LANDMARKS),
			"route_states": projection.get("routes", {}).duplicate(true),
		},
		"caption": projection.get("caption", ""),
		"controller_prompts": (
			"D-PAD / WASD: FOCUS  •  A / SPACE: CONFIRM  •  "
			+ "B / ESC: CANCEL  •  X / H: TRANSCRIPT  •  T: REPLAY"
		),
		"focus_label": (
			"FOCUS %d OF %d • %s"
			% [
				_focus_index + 1,
				legal_actions.size(),
				_action_label(focused_action),
			]
		),
		"focused_action": focused_action,
		"host_authority": "UNDERTELLER HOST AREA • PUBLIC FIXTURE PROJECTION ONLY",
		"legal_actions": legal_actions.duplicate(true),
		"mode": mode_name(),
		"objective": projection.get("objective", ""),
		"persistent_text_when_voice_off": (
			not _voice_enabled
			and not str(projection.get("objective", "")).is_empty()
			and not str(projection.get("caption", "")).is_empty()
			and not legal_actions.is_empty()
		),
		"stage": "LOW TIDE ARRIVAL",
		"status": _status_message,
		"tide_state": str(projection.get("tide_state", "")).replace("_", " ").to_upper(),
		"voice_enabled": _voice_enabled,
	}


func state_signature() -> Dictionary:
	return {
		"rng_cursor": _adapter.rng_cursor(),
		"source_fingerprint": _adapter.source_fingerprint(),
		"source_revision": _adapter.source_revision(),
		"stable_seat_id": _adapter.stable_seat_id(),
	}


func mode_name() -> String:
	return str(SurfaceMode.keys()[_mode]).to_lower()


func _unhandled_input(event: InputEvent) -> void:
	for action: String in SUPPORTED_ACTIONS:
		if event.is_action_pressed(action):
			dispatch_semantic_action(action)
			get_viewport().set_input_as_handled()
			return


func _move_focus(delta: int) -> Dictionary:
	var actions: Array = _projection_result.get("projection", {}).get("legal_actions", [])
	if actions.is_empty():
		return _enter_recovery("no_legal_actions")
	_focus_index = posmod(_focus_index + delta, actions.size())
	_mode = SurfaceMode.BOARD
	_status_message = "Focus moved. No fixture state or RNG was consumed."
	_refresh_ui()
	return {
		"accepted": true,
		"focus_index": _focus_index,
		"focused_action": actions[_focus_index],
		"state_signature": state_signature(),
	}


func _open_inspect() -> Dictionary:
	var snapshot: Dictionary = render_snapshot()
	if not snapshot.get("accepted", false):
		return _enter_recovery("fixture_not_ready")
	_mode = SurfaceMode.INSPECT
	_status_message = (
		"Inspecting %s. Placeholder geography only; no final board geometry."
		% snapshot.get("focus_label", "")
	)
	_refresh_ui()
	return {
		"accepted": true,
		"intent": "inspect",
		"state_signature": state_signature(),
	}


func _request_confirmation() -> Dictionary:
	var snapshot: Dictionary = render_snapshot()
	if not snapshot.get("accepted", false):
		return _enter_recovery("fixture_not_ready")
	_pending_confirmation = {
		"action": snapshot.get("focused_action", ""),
		"source_revision": _adapter.source_revision(),
		"stable_seat_id": _adapter.stable_seat_id(),
	}
	_mode = SurfaceMode.CONFIRMATION
	_status_message = (
		"Confirm %s at revision %d? Press confirm again or cancel."
		% [
			_action_label(str(_pending_confirmation.action)),
			_adapter.source_revision(),
		]
	)
	_refresh_ui()
	return {
		"accepted": true,
		"intent": "confirmation_requested",
		"pending": _pending_confirmation.duplicate(true),
		"state_signature": state_signature(),
	}


func _emit_public_intent(payload: Dictionary) -> Dictionary:
	var serialized: String = JSON.stringify(payload, "", true)
	if (
		"PRIVATE_" in serialized
		or "bellmarked_candidate" in serialized
		or "archive_culvert" in serialized
	):
		return _enter_recovery("private_data_rejected")
	prototype_intent_emitted.emit(payload.duplicate(true))
	_refresh_ui()
	return {
		"accepted": true,
		"payload": payload,
		"state_signature": state_signature(),
	}


func _enter_recovery(code: String) -> Dictionary:
	_pending_confirmation.clear()
	_mode = SurfaceMode.RECOVERY
	_status_message = (
		"RECOVERY • Request rejected safely (%s). "
		+ "No state, seat, or RNG change occurred."
	) % code
	_refresh_ui()
	return {
		"accepted": false,
		"code": code,
		"state_signature": state_signature(),
	}


func _build_ui() -> void:
	if _title_label != null:
		return
	var backdrop := ColorRect.new()
	backdrop.color = Color("08151f")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 24)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)

	_title_label = Label.new()
	_title_label.theme_type_variation = "LabTitle"
	root.add_child(_title_label)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	root.add_child(body)

	var board_panel := PanelContainer.new()
	board_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(board_panel)
	_board_label = Label.new()
	_board_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_board_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_board_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	board_panel.add_child(_board_label)

	var info_panel := PanelContainer.new()
	info_panel.custom_minimum_size.x = 340.0
	body.add_child(info_panel)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 7)
	info_panel.add_child(info)

	_objective_label = Label.new()
	_objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(_objective_label)
	_seat_label = Label.new()
	info.add_child(_seat_label)
	_focus_label = Label.new()
	_focus_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(_focus_label)
	_caption_label = Label.new()
	_caption_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(_caption_label)
	_prompt_label = Label.new()
	_prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(_prompt_label)

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_status_label)


func _refresh_ui() -> void:
	if _title_label == null:
		return
	var snapshot: Dictionary = render_snapshot()
	_title_label.text = "DROWNED HARBOR • LOW TIDE ARRIVAL • DEV-ONLY SHELL"
	_objective_label.text = "OBJECTIVE • %s" % snapshot.get("objective", "")
	_seat_label.text = "%s\n%s" % [
		snapshot.get("host_authority", ""),
		snapshot.get("active_seat_label", ""),
	]
	_focus_label.text = "%s\nLEGAL • %s" % [
		snapshot.get("focus_label", ""),
		", ".join(PackedStringArray(snapshot.get("legal_actions", []))),
	]
	_caption_label.text = "CAPTION • %s" % snapshot.get("caption", "")
	_prompt_label.text = snapshot.get("controller_prompts", "")
	_status_label.text = "STATUS • %s" % snapshot.get("status", "")
	_board_label.text = (
		"DISTANT LIGHTHOUSE\n"
		+ "          △\n\n"
		+ "BELLHOUSE ◉ ───── SALT MARKET ⛺\n"
		+ "       ╲               ╱\n"
		+ "        ╲  BLACK MUD  ╱\n"
		+ "DAMAGED CAUSEWAY ═══ ACTIVE SEAT\n"
		+ "             ╲\n"
		+ "          LIFEBOAT SHED\n\n"
		+ "PLACEHOLDER GEOMETRY • NOT FINAL"
	)


static func _action_label(action: String) -> String:
	return action.replace("_", " ").to_upper()
