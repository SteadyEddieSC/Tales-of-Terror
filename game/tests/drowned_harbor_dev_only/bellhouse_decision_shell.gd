class_name DrownedHarborBellhouseDecisionShell
extends Control

signal prototype_intent_emitted(payload: Dictionary)

enum SurfaceMode {
	DECISION,
	INSPECT,
	PREVIEW,
	CONFIRMATION,
	COMMITTED,
	TRANSCRIPT,
	RECOVERY,
	FIXTURE_RECOVERY,
}

const SHELL_THEME: Theme = preload("res://assets/theme/terror_lab_theme.tres")
const ADAPTER_SCRIPT: Script = preload(
	"res://tests/drowned_harbor_dev_only/bellhouse_fixture_adapter.gd"
)
const CONFIRM_ACTORS: PackedStringArray = ["active_stable_seat"]
const COMMITTED_STATUS: PackedStringArray = [
	"Prototype decision recorded once.",
	"No production gameplay authority was created.",
]
const CANCEL_STATUS: PackedStringArray = [
	"Cancelled.",
	"Fixture state, stable seat, RNG, and committed count are unchanged.",
]
const FIXTURE_RECOVERY_STATUS: PackedStringArray = [
	"Independent DH-FIX-006 recovery projection.",
	"Bellhouse fixture state is unchanged.",
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
const PRIVATE_MARKERS: PackedStringArray = ["PRIVATE_"]

var _adapter: DrownedHarborBellhouseFixtureAdapter = ADAPTER_SCRIPT.new()
var _decision_result: Dictionary = {}
var _fixture_recovery_result: Dictionary = {}
var _decision_recovery: Dictionary = {}
var _pending_confirmation: Dictionary = {}
var _committed_event: Dictionary = {}
var _commit_count: int = 0
var _focus_index: int = 0
var _mode: int = SurfaceMode.DECISION
var _voice_enabled: bool = false
var _status_message: String = "Bellhouse fixture ready. No prototype decision has committed."
var _title_label: Label
var _objective_label: Label
var _board_label: Label
var _decision_label: Label
var _seat_label: Label
var _focus_label: Label
var _caption_label: Label
var _prompt_label: Label
var _status_label: Label


func _ready() -> void:
	theme = SHELL_THEME
	if _decision_result.is_empty():
		initialize_from_fixtures()
	_build_ui()
	_refresh_ui()


func initialize_from_fixtures(
	path: String = DrownedHarborBellhouseFixtureAdapter.FIXTURE_PATH
) -> Dictionary:
	var loaded: Dictionary = _adapter.load_fixtures(path)
	if not loaded.get("accepted", false):
		return _enter_decision_recovery(
			"fixture_load_failed",
			str(loaded.get("reason", "fixture load failed")),
		)
	var projected: Dictionary = _adapter.project_decision(_adapter.default_decision_request())
	if not projected.get("accepted", false):
		return _enter_decision_recovery(
			"fixture_projection_failed",
			str(projected.get("reason", "fixture projection failed")),
		)
	_decision_result = projected
	_fixture_recovery_result.clear()
	_decision_recovery.clear()
	_pending_confirmation.clear()
	_committed_event.clear()
	_commit_count = 0
	_focus_index = 0
	_mode = SurfaceMode.DECISION
	_status_message = "Bellhouse fixture ready. No prototype decision has committed."
	_refresh_ui()
	return {"accepted": true, "snapshot": render_snapshot()}


func dispatch_semantic_action(action: String) -> Dictionary:
	if not SUPPORTED_ACTIONS.has(action):
		return _enter_decision_recovery(
			"unsupported_input",
			"That input is not available. The current Bellhouse option remains selected.",
		)
	var result: Dictionary = {}
	match action:
		"ui_navigate_left", "ui_navigate_up":
			result = _move_focus(-1)
		"ui_navigate_right", "ui_navigate_down":
			result = _move_focus(1)
		"interact":
			result = inspect_selected()
		"ui_confirm":
			if _mode == SurfaceMode.CONFIRMATION:
				result = confirm_pending(
					_adapter.decision_revision(),
					_adapter.decision_stable_seat_id(),
					"active_stable_seat",
					selected_option(),
				)
			else:
				result = request_confirmation()
		"ui_cancel_action":
			result = cancel()
		"help_accessibility":
			result = open_transcript()
		"diagnostic_test":
			result = request_replay()
	return result


func inspect_selected() -> Dictionary:
	if _decision_result.is_empty():
		return _enter_decision_recovery(
			"fixture_not_ready",
			"The Bellhouse decision is unavailable. No state changed.",
		)
	_mode = SurfaceMode.INSPECT
	_status_message = ("Inspecting public Ledger evidence and the selected public consequence.")
	_refresh_ui()
	return {
		"accepted": true,
		"intent": "inspect_public_record",
		"fixture_signature": fixture_signature(),
	}


func preview_selected() -> Dictionary:
	if _decision_result.is_empty():
		return _enter_decision_recovery(
			"fixture_not_ready",
			"The Bellhouse preview is unavailable. No state changed.",
		)
	_mode = SurfaceMode.PREVIEW
	_status_message = "Preview only. The public consequence has not committed."
	_refresh_ui()
	return {
		"accepted": true,
		"intent": "preview_bellhouse_priority",
		"option": selected_option(),
		"fixture_signature": fixture_signature(),
	}


func request_confirmation() -> Dictionary:
	if _commit_count > 0:
		return _committed_result(true)
	if _decision_result.is_empty():
		return _enter_decision_recovery(
			"fixture_not_ready",
			"The Bellhouse decision is unavailable. No state changed.",
		)
	_pending_confirmation = {
		"actor_kind": "active_stable_seat",
		"option": selected_option(),
		"source_revision": _adapter.decision_revision(),
		"stable_seat_id": _adapter.decision_stable_seat_id(),
	}
	_mode = SurfaceMode.CONFIRMATION
	_status_message = (
		"Confirm %s at revision %d? Confirm again or cancel."
		% [
			_action_label(str(_pending_confirmation.option)),
			_adapter.decision_revision(),
		]
	)
	_refresh_ui()
	return {
		"accepted": true,
		"intent": "confirmation_requested",
		"pending": _pending_confirmation.duplicate(true),
		"fixture_signature": fixture_signature(),
	}


func confirm_pending(
	current_revision: int,
	stable_seat_id: String,
	actor_kind: String,
	current_option: String,
	current_options: Array = [],
) -> Dictionary:
	var code: String = ""
	var message: String = ""
	var available_options: Array = (
		current_options.duplicate(true) if not current_options.is_empty() else decision_options()
	)
	if _commit_count > 0:
		if _commit_matches(
			current_revision,
			stable_seat_id,
			actor_kind,
			current_option,
		):
			return _committed_result(true)
		code = "committed_request_changed"
		message = "The committed Bellhouse result is unchanged. Current state is shown."
	elif _pending_confirmation.is_empty():
		code = "confirmation_not_pending"
		message = "Review the current public consequence before confirming."
	elif current_revision != _pending_confirmation.get("source_revision"):
		code = "stale_confirmation_revision"
		message = "The Bellhouse state changed. Current public information is shown."
	elif stable_seat_id != _pending_confirmation.get("stable_seat_id"):
		code = "wrong_confirmation_authority"
		message = "Action authority changed. The current owner and option remain visible."
	elif not CONFIRM_ACTORS.has(actor_kind):
		code = "unauthorized_confirmation_actor"
		message = "That authority cannot confirm this Bellhouse option."
	elif not available_options.has(current_option):
		code = "unavailable_confirmation_option"
		message = "That option is unavailable. Current legal options are shown."
	elif current_option != _pending_confirmation.get("option"):
		code = "changed_confirmation_option"
		message = "The selected option changed. Review the current public consequence."
	if not code.is_empty():
		return _enter_decision_recovery(code, message)
	_commit_count = 1
	_committed_event = _decision_result.get("event", {}).duplicate(true)
	_pending_confirmation.clear()
	_decision_recovery.clear()
	_mode = SurfaceMode.COMMITTED
	_status_message = " ".join(COMMITTED_STATUS)
	var payload: Dictionary = {
		"classification": "public",
		"event": _committed_event.duplicate(true),
		"event_key": "bellhouse_decision_committed",
		"production_authority": false,
		"prototype_commit": true,
		"result_revision": _adapter.decision_result_revision(),
		"source_revision": _adapter.decision_revision(),
		"stable_seat_id": _adapter.decision_stable_seat_id(),
	}
	var emitted: Dictionary = _emit_public_intent(payload)
	if not emitted.get("accepted", false):
		_commit_count = 0
		_committed_event.clear()
		return emitted
	_refresh_ui()
	return _committed_result(false)


func cancel() -> Dictionary:
	_pending_confirmation.clear()
	_decision_recovery.clear()
	_fixture_recovery_result.clear()
	_mode = SurfaceMode.COMMITTED if _commit_count > 0 else SurfaceMode.DECISION
	_status_message = " ".join(CANCEL_STATUS)
	_refresh_ui()
	return {
		"accepted": true,
		"intent": "cancel",
		"fixture_signature": fixture_signature(),
		"prototype_commit_count": _commit_count,
	}


func open_transcript() -> Dictionary:
	var source: Dictionary = _current_projection_result()
	if source.is_empty():
		return _enter_decision_recovery(
			"transcript_unavailable",
			"Public transcript is unavailable. The current decision remains unchanged.",
		)
	_mode = SurfaceMode.TRANSCRIPT
	_status_message = "Public transcript opened. Private fixture data is excluded."
	var payload: Dictionary = {
		"classification": "public",
		"event_key": "prototype_transcript_open_requested",
		"lines": source.get("transcript", []).duplicate(true),
		"source_revision": source.get("source_revision", -1),
	}
	return _emit_public_intent(payload)


func request_replay() -> Dictionary:
	var source: Dictionary = _current_projection_result()
	if source.is_empty():
		return _enter_decision_recovery(
			"replay_unavailable",
			"Public replay is unavailable. The current decision remains unchanged.",
		)
	_mode = SurfaceMode.PREVIEW
	_status_message = "Public replay prepared. No action re-executed and no RNG was used."
	var payload: Dictionary = {
		"classification": "public",
		"event_key": "prototype_replay_requested",
		"replay": source.get("replay", {}).duplicate(true),
		"source_revision": source.get("source_revision", -1),
	}
	return _emit_public_intent(payload)


func project_fixture_recovery() -> Dictionary:
	var projected: Dictionary = _adapter.project_recovery(_adapter.default_recovery_request())
	if not projected.get("accepted", false):
		return _enter_decision_recovery(
			"recovery_fixture_rejected",
			str(projected.get("reason", "Recovery fixture was rejected safely.")),
		)
	_fixture_recovery_result = projected
	_decision_recovery.clear()
	_pending_confirmation.clear()
	_mode = SurfaceMode.FIXTURE_RECOVERY
	_status_message = " ".join(FIXTURE_RECOVERY_STATUS)
	_refresh_ui()
	return {
		"accepted": true,
		"fixture_signature": fixture_signature(),
		"recovery_signature": recovery_fixture_signature(),
		"snapshot": render_snapshot(),
	}


func return_to_decision() -> Dictionary:
	_fixture_recovery_result.clear()
	_decision_recovery.clear()
	_pending_confirmation.clear()
	_mode = SurfaceMode.COMMITTED if _commit_count > 0 else SurfaceMode.DECISION
	_status_message = "Returned to the preserved Bellhouse decision."
	_refresh_ui()
	return {"accepted": true, "snapshot": render_snapshot()}


func set_voice_enabled(enabled: bool) -> void:
	_voice_enabled = enabled
	_refresh_ui()


func selected_option() -> String:
	var options: Array = decision_options()
	if options.is_empty():
		return ""
	return str(options[_focus_index])


func decision_options() -> Array:
	return _decision_result.get("projection", {}).get("decision_options", []).duplicate(true)


func fixture_signature() -> Dictionary:
	return {
		"rng_cursor": _adapter.decision_rng_cursor(),
		"source_fingerprint": _adapter.decision_fingerprint(),
		"source_revision": _adapter.decision_revision(),
		"stable_seat_id": _adapter.decision_stable_seat_id(),
	}


func recovery_fixture_signature() -> Dictionary:
	return {
		"rng_cursor": _adapter.recovery_rng_cursor(),
		"source_fingerprint": _adapter.recovery_fingerprint(),
		"source_revision": _adapter.recovery_revision(),
		"stable_seat_id": _adapter.recovery_stable_seat_id(),
	}


func prototype_commit_count() -> int:
	return _commit_count


func committed_event() -> Dictionary:
	return _committed_event.duplicate(true)


func mode_name() -> String:
	return str(SurfaceMode.keys()[_mode]).to_lower()


func render_snapshot() -> Dictionary:
	if _mode == SurfaceMode.FIXTURE_RECOVERY:
		return _render_fixture_recovery_snapshot()
	if _decision_result.is_empty():
		return {
			"accepted": false,
			"mode": mode_name(),
			"status": _status_message,
		}
	var projection: Dictionary = _decision_result.get("projection", {})
	var active_seat: Dictionary = projection.get("active_seat", {})
	var ledger: Dictionary = projection.get("ledger", {})
	var ring_state: Dictionary = projection.get("ring_state", {})
	var option: String = selected_option()
	return {
		"accepted": true,
		"active_seat_label":
		(
			"ACTIVE %s • %s • %s"
			% [
				str(active_seat.get("seat_id", "")).to_upper(),
				str(active_seat.get("control_source", "")).to_upper(),
				str(active_seat.get("location", "")).to_upper(),
			]
		),
		"board_geometry":
		{
			"bell": "one_large_bell_placeholder",
			"kind": "placeholder_geometry_not_final",
			"ledger": "public_ledger_placeholder",
			"ropes": "long_vertical_rope_placeholders",
		},
		"caption": projection.get("caption", ""),
		"confirmation_pending": not _pending_confirmation.is_empty(),
		"controller_prompts":
		(
			"D-PAD / WASD: FOCUS • A / SPACE: CONFIRM • "
			+ "B / ESC: CANCEL • X / H: TRANSCRIPT • T: REPLAY"
		),
		"decision_option": option,
		"focus_label":
		(
			"FOCUS 1 OF %d • %s"
			% [
				decision_options().size(),
				_action_label(option),
			]
		),
		"host_authority": "UNDERTELLER HOST AREA • PUBLIC FIXTURE PROJECTION ONLY",
		"ledger_summary":
		(
			"VISIBLE %d • ERASED %d • UNRESOLVED %d"
			% [
				int(ledger.get("visible_names", 0)),
				int(ledger.get("erased_positions", 0)),
				int(ledger.get("unresolved_positions", 0)),
			]
		),
		"legal_actions": projection.get("legal_actions", []).duplicate(true),
		"mode": mode_name(),
		"objective": projection.get("objective", ""),
		"persistent_text_when_voice_off":
		(
			not _voice_enabled
			and not str(projection.get("objective", "")).is_empty()
			and not str(projection.get("caption", "")).is_empty()
			and not option.is_empty()
		),
		"prototype_commit_count": _commit_count,
		"public_consequence": projection.get("public_consequence", ""),
		"recovery": _decision_recovery.duplicate(true),
		"ring_summary":
		(
			"VISIBLE %d • AUDIBLE %d • EXTRA RING %s"
			% [
				int(ring_state.get("visible_count", 0)),
				int(ring_state.get("audible_count", 0)),
				"UNRESOLVED" if ring_state.get("extra_ring_unresolved", false) else "NONE",
			]
		),
		"stage": "BELLHOUSE LEDGER",
		"status": _status_message,
		"voice_enabled": _voice_enabled,
	}


func _render_fixture_recovery_snapshot() -> Dictionary:
	if _fixture_recovery_result.is_empty():
		return {"accepted": false, "mode": mode_name(), "status": _status_message}
	var projection: Dictionary = _fixture_recovery_result.get("projection", {})
	var active_seat: Dictionary = projection.get("active_seat", {})
	return {
		"accepted": true,
		"active_seat_label":
		(
			"ACTIVE %s • %s • %s"
			% [
				str(active_seat.get("seat_id", "")).to_upper(),
				str(active_seat.get("control_source", "")).to_upper(),
				str(active_seat.get("location", "")).to_upper(),
			]
		),
		"caption": projection.get("caption", ""),
		"focus_destination": projection.get("focus_destination", ""),
		"legal_alternatives": projection.get("legal_alternatives", []).duplicate(true),
		"mode": mode_name(),
		"persistent_text_when_voice_off":
		(
			not _voice_enabled
			and not str(projection.get("public_safe_reason", "")).is_empty()
			and not projection.get("legal_alternatives", []).is_empty()
		),
		"public_safe_reason": projection.get("public_safe_reason", ""),
		"rejected_action": projection.get("rejected_action", ""),
		"rng_changed": projection.get("rng_changed", true),
		"stage": "INVALID ACTION RECOVERY • INDEPENDENT FIXTURE",
		"state_changed": projection.get("state_changed", true),
		"status": _status_message,
		"voice_enabled": _voice_enabled,
	}


func _unhandled_input(event: InputEvent) -> void:
	for action: String in SUPPORTED_ACTIONS:
		if event.is_action_pressed(action):
			dispatch_semantic_action(action)
			get_viewport().set_input_as_handled()
			return


func _move_focus(delta: int) -> Dictionary:
	var options: Array = decision_options()
	if options.is_empty():
		return _enter_decision_recovery(
			"no_legal_options",
			"No complete legal Bellhouse option is available. No state changed.",
		)
	_focus_index = posmod(_focus_index + delta, options.size())
	_mode = SurfaceMode.DECISION
	_status_message = "Focus moved deterministically. No fixture state or RNG changed."
	_refresh_ui()
	return {
		"accepted": true,
		"focus_index": _focus_index,
		"option": selected_option(),
		"fixture_signature": fixture_signature(),
	}


func _enter_decision_recovery(code: String, message: String) -> Dictionary:
	_pending_confirmation.clear()
	_fixture_recovery_result.clear()
	_focus_index = 0
	_mode = SurfaceMode.RECOVERY
	_decision_recovery = {
		"code": code,
		"focus_destination": selected_option(),
		"legal_alternatives": decision_options(),
		"public_safe_reason": message,
		"rng_changed": false,
		"stable_seat_reset": false,
		"state_changed": false,
	}
	_status_message = ("RECOVERY • %s No state, stable seat, or RNG changed." % message)
	_refresh_ui()
	return {
		"accepted": false,
		"code": code,
		"fixture_signature": fixture_signature(),
		"prototype_commit_count": _commit_count,
		"recovery": _decision_recovery.duplicate(true),
	}


func _committed_result(reprojected: bool) -> Dictionary:
	return {
		"accepted": true,
		"event": _committed_event.duplicate(true),
		"fixture_signature": fixture_signature(),
		"prototype_commit_count": _commit_count,
		"reprojected": reprojected,
	}


func _commit_matches(
	current_revision: int,
	stable_seat_id: String,
	actor_kind: String,
	current_option: String,
) -> bool:
	return (
		current_revision == _adapter.decision_revision()
		and stable_seat_id == _adapter.decision_stable_seat_id()
		and CONFIRM_ACTORS.has(actor_kind)
		and current_option == selected_option()
	)


func _current_projection_result() -> Dictionary:
	if _mode == SurfaceMode.FIXTURE_RECOVERY:
		return _fixture_recovery_result
	return _decision_result


func _emit_public_intent(payload: Dictionary) -> Dictionary:
	var serialized: String = JSON.stringify(payload, "", true)
	for marker: String in PRIVATE_MARKERS:
		if marker in serialized:
			return _enter_decision_recovery(
				"private_data_rejected",
				"Private fixture data was rejected before public presentation.",
			)
	prototype_intent_emitted.emit(payload.duplicate(true))
	_refresh_ui()
	return {
		"accepted": true,
		"payload": payload,
		"fixture_signature": fixture_signature(),
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

	var decision_panel := PanelContainer.new()
	decision_panel.custom_minimum_size.x = 390.0
	body.add_child(decision_panel)
	var decision_box := VBoxContainer.new()
	decision_box.add_theme_constant_override("separation", 7)
	decision_panel.add_child(decision_box)

	_objective_label = Label.new()
	_objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	decision_box.add_child(_objective_label)
	_seat_label = Label.new()
	decision_box.add_child(_seat_label)
	_decision_label = Label.new()
	_decision_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	decision_box.add_child(_decision_label)
	_focus_label = Label.new()
	_focus_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	decision_box.add_child(_focus_label)
	_caption_label = Label.new()
	_caption_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	decision_box.add_child(_caption_label)
	_prompt_label = Label.new()
	_prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	decision_box.add_child(_prompt_label)

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_status_label)


func _refresh_ui() -> void:
	if _title_label == null:
		return
	var snapshot: Dictionary = render_snapshot()
	_title_label.text = "DROWNED HARBOR • BELLHOUSE LEDGER • DEV-ONLY SHELL"
	_objective_label.text = "OBJECTIVE • %s" % snapshot.get("objective", "")
	_seat_label.text = (
		"%s\n%s"
		% [
			snapshot.get("host_authority", "PUBLIC RECOVERY PROJECTION"),
			snapshot.get("active_seat_label", ""),
		]
	)
	_decision_label.text = (
		"LEDGER • %s\nRINGS • %s\nCONSEQUENCE • %s"
		% [
			snapshot.get("ledger_summary", "RECOVERY FIXTURE"),
			snapshot.get("ring_summary", snapshot.get("public_safe_reason", "")),
			snapshot.get("public_consequence", ""),
		]
	)
	_focus_label.text = (
		"%s\nLEGAL • %s"
		% [
			snapshot.get("focus_label", snapshot.get("focus_destination", "")),
			(
				", "
				. join(
					PackedStringArray(
						(
							snapshot
							. get(
								"legal_actions",
								snapshot.get("legal_alternatives", []),
							)
						)
					)
				)
			),
		]
	)
	_caption_label.text = "CAPTION • %s" % snapshot.get("caption", "")
	_prompt_label.text = snapshot.get("controller_prompts", "")
	_status_label.text = "STATUS • %s" % snapshot.get("status", "")
	_board_label.text = (
		"ONE LARGE BELL\n"
		+ "       O\n"
		+ "      /|\\\n"
		+ "     / | \\\n"
		+ "LONG VERTICAL ROPES\n\n"
		+ "PUBLIC LEDGER\n"
		+ "[ VISIBLE • ERASED • UNRESOLVED ]\n\n"
		+ "PLACEHOLDER GEOMETRY • NOT FINAL"
	)


static func _action_label(action: String) -> String:
	return action.replace("_", " ").to_upper()
