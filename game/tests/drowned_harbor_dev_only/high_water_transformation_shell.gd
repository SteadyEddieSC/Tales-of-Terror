class_name DrownedHarborHighWaterTransformationShell
extends Control

signal prototype_high_water_event_emitted(payload: Dictionary)

enum SurfaceMode {
	ELIGIBLE,
	BEFORE_CAPTION,
	READY_TO_COMMIT,
	PRESENTING,
	PERSISTENT_RECAP,
	TRANSFORMED_BOARD,
	PRECOMMIT_RECOVERY,
	POSTCOMMIT_RECOVERY,
}

const ADAPTER_SCRIPT: Script = preload(
	"res://tests/drowned_harbor_dev_only/high_water_fixture_adapter.gd"
)
const EVENT_KEY: String = "high_water_transformation_committed"
const PRESENTATION_STEPS: int = 3
const SUPPORTED_ACTIONS: PackedStringArray = [
	"help_accessibility",
	"interact",
	"ui_cancel_action",
	"ui_confirm",
	"ui_navigate_down",
	"ui_navigate_left",
	"ui_navigate_right",
	"ui_navigate_up",
]
const BLOCKED_GAMEPLAY_ACTIONS: PackedStringArray = [
	"commit_transformed_board_action",
	"confirm_route",
	"encounter",
	"ending",
	"faction_action",
	"form_action",
	"hazard_action",
	"move",
	"rescue",
	"resource_action",
]

var _adapter: DrownedHarborHighWaterFixtureAdapter = ADAPTER_SCRIPT.new()
var _prepared: Dictionary = {}
var _committed_result: Dictionary = {}
var _public_event: Dictionary = {}
var _public_history: Array[Dictionary] = []
var _public_transcript: Array[String] = []
var _public_replay: Array[Dictionary] = []
var _mirrored_output: Array[Dictionary] = []
var _shared_audio_requests: Array[String] = []
var _diagnostics: Array[Dictionary] = []
var _lifecycle_audit: Array[String] = []
var _recorded_event_identities: Dictionary = {}
var _mode: int = SurfaceMode.ELIGIBLE
var _commit_count: int = 0
var _public_event_count: int = 0
var _signal_count: int = 0
var _presentation_step: int = 0
var _reprojection_count: int = 0
var _summary_available: bool = false
var _summary_acknowledged: bool = false
var _transcript_available: bool = true
var _replay_available: bool = true
var _voice_enabled: bool = false
var _focus_destination: String = "high_water_transition_status"
var _status: String = "High Water fixture is not initialized."
var _title_label: Label
var _stage_label: Label
var _board_label: Label
var _summary_label: Label
var _seat_label: Label
var _prompt_label: Label
var _status_label: Label


func _ready() -> void:
	_build_ui()
	_refresh_ui()


func initialize_from_fixture(
	request: Dictionary = DrownedHarborHighWaterFixtureAdapter.authorized_request(),
) -> Dictionary:
	if _commit_count != 0 or not _committed_result.is_empty():
		return _reject("already_committed", "initialize cannot replace a committed result")
	var loaded: Dictionary = _adapter.load_and_prepare(request)
	if not loaded.get("accepted", false):
		_mode = SurfaceMode.PRECOMMIT_RECOVERY
		_status = "The transformed board could not be prepared. Nothing committed."
		_focus_destination = "high_water_transition_status"
		_record_safe_diagnostic(str(loaded.get("code", "malformed_transform_input")))
		_refresh_ui()
		return loaded
	_prepared = loaded.get("prepared", {}).duplicate(true)
	if _prepared.is_empty():
		return _enter_precommit_recovery("incomplete_transform_input")
	_mode = SurfaceMode.BEFORE_CAPTION
	_focus_destination = "committed_council_direction"
	_status = "Council direction and final pre-transform state are ready."
	_lifecycle_audit.append("authoritative_result_prepared_before_presentation_branch")
	_refresh_ui()
	return {
		"accepted": true,
		"fixture_id": _prepared.get("authoritative_state", {}).get("fixture_id", ""),
		"mode": _mode_name(),
		"prepared_bytes": _prepared_result_bytes(),
	}


func capture_before_state_caption() -> Dictionary:
	if _mode == SurfaceMode.READY_TO_COMMIT:
		return {"accepted": true, "reprojected": true, "mode": _mode_name()}
	if _mode != SurfaceMode.BEFORE_CAPTION:
		return _reject("caption_not_available", "pre-transform caption is not current")
	_mode = SurfaceMode.READY_TO_COMMIT
	_focus_destination = "high_water_commit_status"
	_status = "Final pre-transform public state captured."
	_lifecycle_audit.append("final_pretransform_public_state_captured")
	_refresh_ui()
	return {"accepted": true, "mode": _mode_name()}


func commit_authoritative_transformation() -> Dictionary:
	if not _committed_result.is_empty():
		return reproject_existing_result()
	if _mode != SurfaceMode.READY_TO_COMMIT:
		return _reject("commit_not_ready", "final public before-state must be captured first")
	if _prepared.is_empty() or _adapter.state_signature().is_empty():
		return _enter_precommit_recovery("projection_data_invalid")
	var authoritative: Dictionary = _prepared.get("authoritative_state", {}).duplicate(true)
	var event_identity: String = str(_prepared.get("event_identity", ""))
	var event_payload: Dictionary = _prepared.get("event_payload", {}).duplicate(true)
	if authoritative.is_empty() or event_identity.is_empty() or event_payload.is_empty():
		return _enter_precommit_recovery("incomplete_transform_input")
	if _contains_private_marker({"state": authoritative, "event": event_payload}):
		return _enter_precommit_recovery("private_data_rejected")
	_committed_result = authoritative
	_commit_count += 1
	_mode = SurfaceMode.PRESENTING
	_status = "High Water committed. Placeholder presentation is in progress."
	_focus_destination = "high_water_presentation"
	_lifecycle_audit.append("authoritative_high_water_committed_once")
	_record_public_outputs_once(event_identity, event_payload)
	_refresh_ui()
	return {
		"accepted": true,
		"commit_count": _commit_count,
		"event_identity": event_identity,
		"public_event_count": _public_event_count,
		"result_revision": _committed_result.get("result_revision", -1),
		"rng_cursor": _committed_result.get("rng_cursor", -1),
	}


func run_full_presentation() -> Dictionary:
	if _mode == SurfaceMode.BEFORE_CAPTION:
		var captured: Dictionary = capture_before_state_caption()
		if not captured.get("accepted", false):
			return captured
	if _mode == SurfaceMode.READY_TO_COMMIT:
		var committed: Dictionary = commit_authoritative_transformation()
		if not committed.get("accepted", false):
			return committed
	while _mode == SurfaceMode.PRESENTING:
		var advanced: Dictionary = advance_placeholder_presentation()
		if not advanced.get("accepted", false):
			return advanced
	return {"accepted": true, "mode": _mode_name(), "snapshot": _equivalence_snapshot()}


func advance_placeholder_presentation() -> Dictionary:
	if _mode != SurfaceMode.PRESENTING:
		return _reject("presentation_not_active", "placeholder presentation is not active")
	_presentation_step += 1
	_lifecycle_audit.append("placeholder_step_%d" % _presentation_step)
	if _presentation_step >= PRESENTATION_STEPS:
		_settle_persistent_summary("full_presentation")
	else:
		_status = (
			"Deterministic placeholder step %d of %d." % [_presentation_step, PRESENTATION_STEPS]
		)
		_refresh_ui()
	return {
		"accepted": true,
		"mode": _mode_name(),
		"presentation_step": _presentation_step,
	}


func skip_presentation() -> Dictionary:
	if _summary_available:
		return {"accepted": true, "reprojected": true, "mode": _mode_name()}
	if _mode == SurfaceMode.BEFORE_CAPTION:
		var captured: Dictionary = capture_before_state_caption()
		if not captured.get("accepted", false):
			return captured
	if _mode == SurfaceMode.READY_TO_COMMIT:
		var committed: Dictionary = commit_authoritative_transformation()
		if not committed.get("accepted", false):
			return committed
	if _mode != SurfaceMode.PRESENTING:
		return _reject("skip_not_available", "semantic skip may affect presentation only")
	_presentation_step = PRESENTATION_STEPS
	_lifecycle_audit.append("semantic_skip_presentation_only")
	_settle_persistent_summary("semantic_skip")
	return {"accepted": true, "mode": _mode_name(), "snapshot": _equivalence_snapshot()}


func acknowledge_persistent_summary() -> Dictionary:
	if not _summary_available:
		return _reject("persistent_summary_required", "control remains blocked until recap exists")
	if _summary_acknowledged:
		return {
			"accepted": true,
			"focus_destination": _focus_destination,
			"reprojected": true,
		}
	_summary_acknowledged = true
	_mode = SurfaceMode.TRANSFORMED_BOARD
	_focus_destination = str(_committed_result.get("stable_seat_ids", [""])[0])
	_status = "Read-only transformed-board inspection is available."
	_lifecycle_audit.append("persistent_summary_acknowledged_before_focus_return")
	_refresh_ui()
	return {
		"accepted": true,
		"focus_destination": _focus_destination,
		"mode": _mode_name(),
	}


func submit_transformation_request(request: Dictionary) -> Dictionary:
	if _committed_result.is_empty():
		return initialize_from_fixture(request)
	if request == DrownedHarborHighWaterFixtureAdapter.authorized_request():
		return reproject_existing_result()
	var probe: DrownedHarborHighWaterFixtureAdapter = ADAPTER_SCRIPT.new()
	var rejected: Dictionary = probe.load_and_prepare(request)
	if rejected.get("accepted", false):
		return _reject("already_committed", "only the existing result may be reprojected")
	_record_safe_diagnostic(str(rejected.get("code", "malformed_transform_request")))
	return rejected


func reproject_existing_result() -> Dictionary:
	if _committed_result.is_empty():
		return _reject("no_committed_result", "there is no High Water result to reproject")
	_reprojection_count += 1
	_lifecycle_audit.append("existing_authoritative_result_reprojected")
	if _mode == SurfaceMode.POSTCOMMIT_RECOVERY or not _summary_available:
		_settle_persistent_summary("deterministic_reprojection")
	return {
		"accepted": true,
		"commit_count": _commit_count,
		"event_identity": _prepared.get("event_identity", ""),
		"public_event_count": _public_event_count,
		"reprojected": true,
		"snapshot": _equivalence_snapshot(),
	}


func interrupt_caption_or_voice() -> Dictionary:
	if _committed_result.is_empty():
		return _enter_precommit_recovery("caption_interrupted_before_commit")
	_lifecycle_audit.append("caption_or_voice_interrupted_after_commit")
	_settle_persistent_summary("post_commit_interruption")
	return {
		"accepted": true,
		"commit_count": _commit_count,
		"mode": _mode_name(),
		"recovered_to_recap": true,
	}


func _fail_projection_before_commit() -> Dictionary:
	if not _committed_result.is_empty():
		return _reject("already_committed", "use post-commit projection recovery")
	_prepared.clear()
	_adapter.clear_loaded_fixture()
	return _enter_precommit_recovery("projection_failure_before_commit")


func _fail_projection_after_commit() -> Dictionary:
	if _committed_result.is_empty():
		return _enter_precommit_recovery("projection_failure_before_commit")
	_mode = SurfaceMode.POSTCOMMIT_RECOVERY
	_summary_available = false
	_summary_acknowledged = false
	_focus_destination = "high_water_public_recap"
	_status = "High Water remains authoritative. Reprojection is required."
	_lifecycle_audit.append("projection_failure_after_commit_preserved_result")
	_record_safe_diagnostic("projection_failure_after_commit")
	_refresh_ui()
	return {
		"accepted": false,
		"code": "projection_failure_after_commit",
		"commit_count": _commit_count,
		"result_preserved": true,
	}


func recover_projection(
	request: Dictionary = DrownedHarborHighWaterFixtureAdapter.authorized_request(),
) -> Dictionary:
	if not _committed_result.is_empty():
		return reproject_existing_result()
	if _mode != SurfaceMode.PRECOMMIT_RECOVERY:
		return _reject("recovery_not_required", "pre-commit recovery is not active")
	_mode = SurfaceMode.ELIGIBLE
	return initialize_from_fixture(request)


func _set_transcript_available(available: bool) -> void:
	_transcript_available = available


func _set_replay_available(available: bool) -> void:
	_replay_available = available


func _set_voice_enabled(enabled: bool) -> void:
	_voice_enabled = enabled
	_refresh_ui()


func open_transcript() -> Dictionary:
	if not _transcript_available:
		_record_safe_diagnostic("transcript_unavailable")
		return _reject("transcript_unavailable", "the transformed board and recap remain available")
	return {
		"accepted": true,
		"entries": _public_transcript.duplicate(true),
		"fixture_unchanged": true,
	}


func replay_committed_summary() -> Dictionary:
	if not _replay_available:
		_record_safe_diagnostic("replay_unavailable")
		return _reject("replay_unavailable", "the transformed board and recap remain available")
	if _public_replay.is_empty():
		return _reject("replay_not_available", "no committed summary exists")
	return {
		"accepted": true,
		"entry": _public_replay[0].duplicate(true),
		"reexecuted_commit": false,
	}


func inspect_transformed_board(action: String) -> Dictionary:
	if _mode != SurfaceMode.TRANSFORMED_BOARD:
		return _reject("summary_acknowledgement_required", "read-only inspection is not focused")
	var legal: Array = _committed_result.get("legal_inspection_actions", [])
	if not legal.has(action):
		return _reject("unsupported_inspection", "inspection action is not fixture-declared")
	return {
		"accepted": true,
		"action": action,
		"authoritative_mutation": false,
		"projection": _prepared.get("transformed_projection", {}).duplicate(true),
		"read_only": true,
	}


func _attempt_transformed_board_action_commit(action: String) -> Dictionary:
	return _reject(
		"read_only_boundary",
		"transformed-board action commitment is prohibited in P0.18: %s" % action,
	)


func _attempt_gameplay_action(action: String) -> Dictionary:
	if BLOCKED_GAMEPLAY_ACTIONS.has(action):
		return _reject("gameplay_mutation_blocked", "gameplay reducers are disabled during proof")
	return _reject("unsupported_input", "unsupported input failed closed")


func _attempt_authority_transfer() -> Dictionary:
	return _reject("authority_transfer_prohibited", "system authority remains unchanged")


func open_help() -> Dictionary:
	return {
		"accepted": true,
		"authoritative_mutation": false,
		"text": "High Water recap and read-only inspection help.",
	}


func dispatch_semantic_action(action: String) -> Dictionary:
	if not SUPPORTED_ACTIONS.has(action):
		return _reject("unsupported_input", "unsupported semantic input failed closed")
	var result: Dictionary = {}
	match action:
		"help_accessibility":
			result = open_help()
		"ui_cancel_action":
			result = skip_presentation()
		"ui_confirm":
			result = _dispatch_confirm()
		"interact":
			result = _dispatch_interact()
		_:
			result = {
				"accepted": true,
				"authoritative_mutation": false,
				"focus_destination": _focus_destination,
			}
	return result


func _dispatch_confirm() -> Dictionary:
	if _mode == SurfaceMode.BEFORE_CAPTION:
		return capture_before_state_caption()
	if _mode == SurfaceMode.READY_TO_COMMIT:
		return commit_authoritative_transformation()
	if _mode == SurfaceMode.PERSISTENT_RECAP:
		return acknowledge_persistent_summary()
	return _reject("confirm_not_available", "confirm cannot change the committed result")


func _dispatch_interact() -> Dictionary:
	if _mode == SurfaceMode.TRANSFORMED_BOARD:
		return inspect_transformed_board(
			str(_committed_result.get("legal_inspection_actions", [""])[0])
		)
	return _reject("interaction_blocked", "persistent summary must settle and be acknowledged")


func _next_interaction_allowed() -> bool:
	return _summary_available and _summary_acknowledged and _mode == SurfaceMode.TRANSFORMED_BOARD


func _prepared_result_bytes() -> String:
	return JSON.stringify(_prepared, "", true)


func _equivalence_bytes() -> String:
	return JSON.stringify(_equivalence_snapshot(), "", true)


func _equivalence_snapshot() -> Dictionary:
	var projection: Dictionary = _prepared.get("transformed_projection", {}).duplicate(true)
	return {
		"authoritative_state": _committed_result.duplicate(true),
		"caption": _prepared.get("caption", ""),
		"changed_categories": _prepared.get("changed_categories", []).duplicate(true),
		"event_identity": _prepared.get("event_identity", ""),
		"event_payload": _prepared.get("event_payload", {}).duplicate(true),
		"legal_inspection_actions": projection.get("legal_inspection_actions", []).duplicate(true),
		"mirrored_output": _mirrored_output.duplicate(true),
		"persistent_summary": _prepared.get("persistent_summary", ""),
		"public_form_state": projection.get("public_forms", {}).duplicate(true),
		"public_history": _public_history.duplicate(true),
		"replay_summary": _public_replay.duplicate(true),
		"result_revision": _committed_result.get("result_revision", -1),
		"stable_seat_positions": projection.get("seat_positions", {}).duplicate(true),
		"transcript": _public_transcript.duplicate(true),
		"transformed_board_projection": projection,
	}


func _evidence_snapshot() -> Dictionary:
	return {
		"commit_count": _commit_count,
		"event_count": _public_event_count,
		"event_identity_count": _recorded_event_identities.size(),
		"focus_destination": _focus_destination,
		"history_count": _public_history.size(),
		"lifecycle": _lifecycle_audit.duplicate(),
		"mirror_count": _mirrored_output.size(),
		"mode": _mode_name(),
		"next_interaction_allowed": _next_interaction_allowed(),
		"replay_count": _public_replay.size(),
		"reprojection_count": _reprojection_count,
		"result_revision": _committed_result.get("result_revision", -1),
		"rng_cursor": _committed_result.get("rng_cursor", -1),
		"signal_count": _signal_count,
		"source_revision": _committed_result.get("source_revision", -1),
		"stable_seat_ids": _committed_result.get("stable_seat_ids", []).duplicate(true),
		"summary_acknowledged": _summary_acknowledged,
		"summary_available": _summary_available,
		"transcript_count": _public_transcript.size(),
	}


func _privacy_outputs() -> Dictionary:
	return {
		"caption": _prepared.get("caption", ""),
		"diagnostics": _diagnostics.duplicate(true),
		"history": _public_history.duplicate(true),
		"mirror": _mirrored_output.duplicate(true),
		"projection": _prepared.get("transformed_projection", {}).duplicate(true),
		"replay": _public_replay.duplicate(true),
		"shared_audio": _shared_audio_requests.duplicate(true),
		"transcript": _public_transcript.duplicate(true),
	}


func _render_snapshot() -> Dictionary:
	var before: Dictionary = _prepared.get("before_state", {})
	var transformed: Dictionary = _prepared.get("transformed_projection", {})
	return {
		"before_state": before.duplicate(true),
		"board": transformed.duplicate(true),
		"caption": _prepared.get("caption", ""),
		"focus_destination": _focus_destination,
		"persistent_summary": _prepared.get("persistent_summary", "") if _summary_available else "",
		"prompts": _controller_prompts(),
		"stage": _committed_result.get("stage", before.get("stage", "")),
		"status": _status,
		"voice_enabled": _voice_enabled,
	}


func _mode_name() -> String:
	return SurfaceMode.keys()[_mode].to_lower()


func _setttle_guard() -> bool:
	return not _committed_result.is_empty()


func _settle_persistent_summary(reason: String) -> void:
	if not _setttle_guard():
		return
	_summary_available = true
	_mode = SurfaceMode.PERSISTENT_RECAP
	_focus_destination = "high_water_public_recap"
	_status = "Persistent High Water recap is available; acknowledgement is required."
	_lifecycle_audit.append("persistent_summary_settled:%s" % reason)
	_refresh_ui()


func _record_public_outputs_once(event_identity: String, event_payload: Dictionary) -> void:
	if _recorded_event_identities.has(event_identity):
		return
	var event: Dictionary = {
		"classification": "public",
		"event_identity": event_identity,
		"event_key": EVENT_KEY,
		"payload": event_payload.duplicate(true),
	}
	if _contains_private_marker(event):
		return
	_recorded_event_identities[event_identity] = true
	_public_event = event.duplicate(true)
	_public_event_count += 1
	_public_history.append(event.duplicate(true))
	var summary_entry: Dictionary = {
		"event_identity": event_identity,
		"summary": _prepared.get("persistent_summary", ""),
	}
	if _transcript_available:
		_public_transcript.append(str(summary_entry.get("summary", "")))
	if _replay_available:
		_public_replay.append(summary_entry.duplicate(true))
	_mirrored_output.append(summary_entry.duplicate(true))
	_shared_audio_requests.append(str(_prepared.get("caption", "")))
	prototype_high_water_event_emitted.emit(event.duplicate(true))
	_signal_count += 1


func _enter_precommit_recovery(code: String) -> Dictionary:
	_mode = SurfaceMode.PRECOMMIT_RECOVERY
	_summary_available = false
	_summary_acknowledged = false
	_focus_destination = "high_water_transition_status"
	_status = "The transformed board cannot be projected completely. Nothing committed."
	_lifecycle_audit.append("precommit_recovery:%s" % code)
	_record_safe_diagnostic(code)
	_refresh_ui()
	return {
		"accepted": false,
		"code": code,
		"commit_count": _commit_count,
		"public_event_count": _public_event_count,
		"recovery_available": true,
	}


func _record_safe_diagnostic(code: String) -> void:
	var diagnostic: Dictionary = {
		"code": code,
		"message": "Public-safe High Water proof recovery is available.",
	}
	if not _diagnostics.has(diagnostic):
		_diagnostics.append(diagnostic)


func _reject(code: String, message: String) -> Dictionary:
	return {
		"accepted": false,
		"code": code,
		"reason": "%s:%s" % [code, message],
	}


static func _contains_private_marker(value: Variant) -> bool:
	return "PRIVATE_" in JSON.stringify(value, "", true)


func _controller_prompts() -> String:
	if _mode == SurfaceMode.PRESENTING:
		return "B / ESC: SKIP PRESENTATION  |  X / H: HELP"
	if _mode == SurfaceMode.PERSISTENT_RECAP:
		return "A / SPACE: ACKNOWLEDGE  |  X / H: HELP"
	if _mode == SurfaceMode.TRANSFORMED_BOARD:
		return "A / E: READ-ONLY INSPECT  |  X / H: HELP"
	return "A / SPACE: CONTINUE  |  X / H: HELP"


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	for action: String in SUPPORTED_ACTIONS:
		if event.is_action_pressed(action):
			dispatch_semantic_action(action)
			get_viewport().set_input_as_handled()
			return


func _build_ui() -> void:
	if _title_label != null:
		return
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color("111820")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)
	_title_label = Label.new()
	root.add_child(_title_label)
	_stage_label = Label.new()
	root.add_child(_stage_label)
	_board_label = Label.new()
	_board_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_board_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_board_label)
	_summary_label = Label.new()
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_summary_label)
	_seat_label = Label.new()
	root.add_child(_seat_label)
	_prompt_label = Label.new()
	root.add_child(_prompt_label)
	_status_label = Label.new()
	root.add_child(_status_label)


func _refresh_ui() -> void:
	if _title_label == null:
		return
	var snapshot: Dictionary = _render_snapshot()
	var board: Dictionary = snapshot.get("board", {})
	_title_label.text = "DROWNED HARBOR • HIGH WATER • DEV-ONLY PLACEHOLDER"
	_stage_label.text = "STAGE • %s" % str(snapshot.get("stage", "")).to_upper()
	_board_label.text = (
		"LOW-TIDE GEOGRAPHY RETAINED\n"
		+ "[BELLHOUSE] -- CAUSEWAY -- [SALT MARKET PLATFORM]\n"
		+ "       \\ WATER-ONLY / COLLAPSED // [ARCHIVE]\n\n"
		+ (
			"ROUTES • %s\nHAZARDS • %s\nLEGEND • OPEN | SUBMERGED | FLOODED-PASSABLE | "
			% [
				JSON.stringify(board.get("routes", {})),
				JSON.stringify(board.get("public_hazards", []))
			]
		)
		+ "WATER-ONLY | UNSTABLE | DAMAGED | COLLAPSED\n"
		+ "Shapes and patterns accompany every state; color is not authoritative."
	)
	_summary_label.text = "RECAP • %s" % snapshot.get("persistent_summary", "Pending")
	_seat_label.text = "FOCUS • %s" % snapshot.get("focus_destination", "")
	_prompt_label.text = snapshot.get("prompts", "")
	_status_label.text = "STATUS • %s" % snapshot.get("status", "")
