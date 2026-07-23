extends Control

const RESET_HOLD_SECONDS: float = 1.5
const SLICE_CANVAS_LAYER: int = 20
const HELP_CANVAS_LAYER: int = 30
const SEMANTIC_ACTIONS: PackedStringArray = [
	"ui_navigate_up",
	"ui_navigate_down",
	"ui_navigate_left",
	"ui_navigate_right",
	"ui_confirm",
	"ui_cancel_action",
	"player_join",
	"pause_options",
	"help_accessibility",
	"diagnostic_test",
	"interact",
]

var _devices: DeviceRegistry
var _coordinator := VerticalSliceCoordinator.new()
var _seats: SeatManager
var _ui: InputDisplayLab
var _slice_layer: CanvasLayer
var _slice_view: VerticalSliceView
var _help_layer: CanvasLayer
var _help: GuidedSessionHelp
var _input_router: PlayerInputRouter
var _sandbox: ExplorationSandbox
var _reset_held: float = 0.0
var _safe_margin: int = 24
var _developer_lab: bool = false
var _active_report: PlaytestReport
var _last_report: PlaytestReport
var _report_writer: PlaytestReportWriter = LocalPlaytestReportWriter.new()
var _report_started_msec: int = 0
var _last_observed_rejection: String = ""


func _ready() -> void:
	_seats = _coordinator.seat_manager
	_devices = DeviceRegistry.new()
	add_child(_devices)
	_input_router = PlayerInputRouter.new()
	add_child(_input_router)
	_input_router.interact_requested.connect(_on_interact_requested)
	_input_router.diagnostics_requested.connect(_on_diagnostics_requested)
	_input_router.rules_navigation_requested.connect(_on_rules_navigation_requested)
	_ui = InputDisplayLab.new()
	add_child(_ui)
	_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_slice_layer = CanvasLayer.new()
	_slice_layer.layer = SLICE_CANVAS_LAYER
	add_child(_slice_layer)
	_slice_view = VerticalSliceView.new()
	_slice_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_slice_layer.add_child(_slice_view)
	_slice_view.set_safe_margin(_safe_margin)
	_help_layer = CanvasLayer.new()
	_help_layer.layer = HELP_CANVAS_LAYER
	add_child(_help_layer)
	_help = GuidedSessionHelp.new()
	_help_layer.add_child(_help)
	_help.set_safe_margin(_safe_margin)
	_help.export_requested.connect(_on_report_export_requested)
	_coordinator.lifecycle_changed.connect(_on_lifecycle_changed)
	_devices.devices_changed.connect(_on_devices_changed)
	_devices.device_connected.connect(_on_device_connected)
	_devices.device_disconnected.connect(_on_device_disconnected)
	_seats.seats_changed.connect(_on_seats_changed)
	_on_seats_changed(_seats.get_seats())
	_on_devices_changed(_devices.get_devices())
	_start_report()
	_refresh_slice_view()
	print(
		ProjectSettings.get_setting("application/config/name"),
		" vertical slice loaded: ",
		ProjectSettings.get_setting("application/config/version")
	)
	if OS.get_cmdline_user_args().has("--portable-build-smoke"):
		call_deferred("_run_portable_build_smoke")


func _process(delta: float) -> void:
	if Input.is_action_pressed("reset_seats"):
		_reset_held += delta
		_ui.present_reset_progress(minf(_reset_held / RESET_HOLD_SECONDS, 1.0))
		if is_instance_valid(_sandbox):
			_sandbox.present_reset_progress(minf(_reset_held / RESET_HOLD_SECONDS, 1.0))
		if _reset_held >= RESET_HOLD_SECONDS:
			_perform_protected_reset()
			_reset_held = 0.0
	else:
		if _reset_held > 0.0:
			_ui.present_reset_progress(0.0)
			if is_instance_valid(_sandbox):
				_sandbox.present_reset_progress(0.0)
		_reset_held = 0.0


func _input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	var device_id: int = event.device
	var claimed_seat_this_event: bool = false
	if event is InputEventKey:
		device_id = SeatManager.KEYBOARD_DEVICE_ID
	if is_instance_valid(_help) and _help.visible:
		for help_action: String in [
			"help_accessibility",
			"ui_cancel_action",
			"ui_navigate_left",
			"ui_navigate_right",
			"ui_confirm",
		]:
			if event.is_action_pressed(help_action):
				_help.handle_action(help_action)
				if not _help.visible:
					call_deferred("_release_help_input_block")
				get_viewport().set_input_as_handled()
				return
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("help_accessibility"):
		_open_help()
		get_viewport().set_input_as_handled()
		return
	var owns_active_seat: bool = _seats.find_seat_by_device(device_id) >= 0
	var join_lifecycle: bool = _coordinator.lifecycle in ["boot_title", "lobby"]
	if event.is_action_pressed("player_join") and join_lifecycle and not owns_active_seat:
		var joined_index: int = -1
		if device_id == SeatManager.KEYBOARD_DEVICE_ID:
			joined_index = _seats.join_device(
				device_id, SeatManager.KEYBOARD_IDENTITY, "Keyboard (development)"
			)
		elif _devices.has_device(device_id):
			joined_index = _seats.join_device(
				device_id, _devices.get_identity(device_id), _devices.get_display_name(device_id)
			)
		claimed_seat_this_event = joined_index >= 0
		if claimed_seat_this_event and _coordinator.lifecycle == "boot_title":
			_coordinator.enter_lobby()
	for action: String in SEMANTIC_ACTIONS:
		if event.is_action_pressed(action):
			_seats.record_action(device_id, action)
			break
	if _coordinator.lifecycle == "tale_library" and _event_can_navigate(event, owns_active_seat):
		var focus_direction: int = 0
		if event.is_action_pressed("ui_navigate_left") or event.is_action_pressed("ui_navigate_up"):
			focus_direction = -1
		elif (
			event.is_action_pressed("ui_navigate_right")
			or event.is_action_pressed("ui_navigate_down")
		):
			focus_direction = 1
		if focus_direction != 0:
			_coordinator.navigate_tale_library("focus", focus_direction)
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("safe_area_decrease"):
		_adjust_safe_margin(-1)
	elif event.is_action_pressed("safe_area_increase"):
		_adjust_safe_margin(1)
	if (
		event.is_action_pressed("ui_confirm")
		and not claimed_seat_this_event
		and _event_can_confirm(event, device_id)
	):
		_advance_player_flow()
	elif event.is_action_pressed("pause_options") and _coordinator.lifecycle == "active_tale":
		var pause_result: Dictionary = _coordinator.toggle_pause()
		if pause_result.accepted and is_instance_valid(_sandbox):
			_sandbox.process_mode = (
				Node.PROCESS_MODE_DISABLED if _coordinator.paused else Node.PROCESS_MODE_INHERIT
			)
	elif event.is_action_pressed("ui_cancel_action"):
		_cancel_player_flow(device_id)


func _ensure_sandbox() -> void:
	if is_instance_valid(_sandbox):
		return
	_sandbox = ExplorationSandbox.new()
	_sandbox.z_index = 10
	_sandbox.setup(_input_router, _coordinator if _coordinator.board_state != null else null)
	add_child(_sandbox)
	_sandbox.set_safe_margin(_safe_margin)
	_ui.visible = false
	_slice_view.visible = false


func _destroy_sandbox() -> void:
	if is_instance_valid(_sandbox):
		_sandbox.queue_free()
	_sandbox = null
	_ui.visible = _developer_lab
	_refresh_slice_view()


func _adjust_safe_margin(direction: int) -> void:
	_safe_margin = clampi(_safe_margin + direction * 8, 0, 48)
	_ui.set_safe_margin(_safe_margin)
	_slice_view.set_safe_margin(_safe_margin)
	if is_instance_valid(_help):
		_help.set_safe_margin(_safe_margin)
	if is_instance_valid(_sandbox):
		_sandbox.set_safe_margin(_safe_margin)


func _on_interact_requested(device_id: int) -> void:
	if is_instance_valid(_sandbox):
		_sandbox.request_interaction(device_id)


func _on_diagnostics_requested(_device_id: int) -> void:
	if is_instance_valid(_sandbox):
		_sandbox.toggle_diagnostics()
	else:
		_developer_lab = not _developer_lab
		_ui.visible = _developer_lab
		_refresh_slice_view()


func _on_rules_navigation_requested(
	device_id: int, direction: int, confirm: bool, cancel: bool
) -> void:
	if is_instance_valid(_sandbox):
		_sandbox.request_rules_navigation(device_id, direction, confirm, cancel)


func _on_device_connected(device_id: int, identity: String) -> void:
	_seats.reconnect_device(device_id, identity, _devices.get_display_name(device_id))


func _on_device_disconnected(device_id: int) -> void:
	_input_router.clear_device(device_id)
	_seats.disconnect_device(device_id)


func _on_devices_changed(devices: Array[Dictionary]) -> void:
	_ui.present_devices(devices, _seats.get_seats())


func _on_seats_changed(seats: Array[Dictionary]) -> void:
	_ui.present_seats(seats)
	_ui.present_devices(_devices.get_devices() if is_instance_valid(_devices) else [], seats)
	var has_pawns: bool = _coordinator.lifecycle == "active_tale" and seats.any(_seat_supports_pawn)
	if has_pawns:
		_ensure_sandbox()
		_sandbox.sync_seats(seats)
	else:
		_destroy_sandbox()
	_refresh_slice_view()
	_observe_report()


func _advance_player_flow() -> void:
	match _coordinator.lifecycle:
		"lobby":
			_coordinator.confirm_roster()
		"confirmation":
			_coordinator.navigate_tale_library("open")
		"tale_library":
			_coordinator.initialize_session()
		"briefing":
			if _coordinator.begin_tale().accepted:
				_ensure_sandbox()
				_sandbox.sync_seats(_seats.get_seats())
				_coordinator.advance_player_stage()
		"active_tale":
			var result: Dictionary = _coordinator.advance_player_stage()
			if result.accepted and _coordinator.lifecycle == "terminal":
				_destroy_sandbox()
		"terminal":
			_coordinator.review_ending()
		"ending":
			if _coordinator.rematch().accepted:
				_record_report_disposition("rematch")
				_destroy_sandbox()
				_start_report()
	_refresh_slice_view()


func _cancel_player_flow(device_id: int) -> void:
	match _coordinator.lifecycle:
		"confirmation":
			_coordinator.cancel_setup()
		"tale_library":
			_coordinator.navigate_tale_library("return_to_mode")
		"briefing":
			_coordinator.navigate_tale_library("return_from_briefing")
		"lobby":
			_seats.leave_device(device_id)
			if _coordinator.active_seats().is_empty():
				_coordinator.cancel_setup()
		"ending":
			if _coordinator.return_to_title().accepted:
				_record_report_disposition("return_to_title")
				_start_report()
	_refresh_slice_view()


func _perform_protected_reset() -> void:
	if _active_report != null:
		_finalize_report("reset")
	else:
		_record_report_disposition("reset")
	_developer_lab = false
	if is_instance_valid(_help):
		_help.close_help()
	if is_instance_valid(_input_router):
		_input_router.set_presentation_input_blocked(false)
	_ui.visible = false
	_coordinator.protected_reset_to_title()
	_reset_held = 0.0
	_ui.present_reset_progress(0.0)
	if is_instance_valid(_sandbox):
		_destroy_sandbox()
	else:
		_refresh_slice_view()
	_start_report()


func _on_lifecycle_changed(state: Dictionary) -> void:
	var lifecycle: String = state.get("lifecycle", "")
	if lifecycle == "ending":
		_finalize_report("ending")
	if lifecycle in ["terminal", "ending"] and is_instance_valid(_sandbox):
		_destroy_sandbox()
	_refresh_slice_view()
	_observe_report()


func _refresh_slice_view() -> void:
	if not is_instance_valid(_slice_view):
		return
	_slice_view.present(_coordinator.public_state(), _seats.get_seats(), _developer_lab)
	if not is_instance_valid(_sandbox):
		_ui.visible = _developer_lab
	if is_instance_valid(_help):
		(
			_help
			. update_context(
				_coordinator.public_state(),
				_seats.get_seats(),
				_companion_status(),
				_last_report != null and _last_report.is_finalized(),
			)
		)


func _seat_supports_pawn(seat: Dictionary) -> bool:
	return (
		seat.state
		in [
			SeatManager.SeatState.ACTIVE,
			SeatManager.SeatState.RESERVED,
			SeatManager.SeatState.DISCONNECTED,
		]
	)


func _open_help() -> void:
	_input_router.set_presentation_input_blocked(true)
	if is_instance_valid(_sandbox):
		_sandbox.process_mode = Node.PROCESS_MODE_DISABLED
	(
		_help
		. open_help(
			_coordinator.public_state(),
			_seats.get_seats(),
			_companion_status(),
			_last_report != null and _last_report.is_finalized(),
		)
	)


func _release_help_input_block() -> void:
	if is_instance_valid(_input_router) and (not is_instance_valid(_help) or not _help.visible):
		_input_router.set_presentation_input_blocked(false)
		if is_instance_valid(_sandbox) and not _coordinator.paused:
			_sandbox.process_mode = Node.PROCESS_MODE_INHERIT


func _start_report() -> void:
	_active_report = PlaytestReport.new()
	_report_started_msec = Time.get_ticks_msec()
	_last_observed_rejection = ""
	(
		_active_report
		. begin(
			_coordinator.public_state(),
			_coordinator.seed,
			Time.get_datetime_string_from_system(true, true),
			0,
		)
	)
	_observe_report()


func _observe_report() -> void:
	if _active_report == null or _active_report.is_finalized():
		return
	var state: Dictionary = _coordinator.public_state()
	_active_report.observe(
		state, _public_seat_observations(), _companion_status(), _report_elapsed()
	)
	var rejection: String = state.get("last_rejection", "")
	if not rejection.is_empty() and rejection != _last_observed_rejection:
		_active_report.record_rejection(rejection, _report_elapsed())
	_last_observed_rejection = rejection


func _finalize_report(completion_reason: String) -> void:
	if _active_report == null or _active_report.is_finalized():
		return
	_observe_report()
	var finalized: Dictionary = (
		_active_report
		. finalize(
			completion_reason,
			_coordinator.public_state(),
			Time.get_datetime_string_from_system(true, true),
			_report_elapsed(),
			_coordinator.authority_digest(),
			_coordinator.public_history_digest(),
		)
	)
	if finalized.accepted:
		_last_report = _active_report
		_active_report = null


func _record_report_disposition(disposition: String) -> void:
	if _last_report == null or not _last_report.is_finalized():
		return
	_last_report.record_post_ending_disposition(disposition)


func _on_report_export_requested() -> void:
	if _last_report == null or not _last_report.is_finalized():
		_help.present_export_result({"accepted": false, "reason": "report_not_finalized"})
		return
	var release: String = str(ProjectSettings.get_setting("application/config/version"))
	var basename: String = (
		"lantern_house_internal_%s_%d"
		% [release.trim_prefix("v").replace(".", "_"), int(Time.get_unix_time_from_system())]
	)
	_help.present_export_result(_last_report.export_with(_report_writer, basename))


func _companion_status() -> Dictionary:
	var bridge: CompanionBridge = _coordinator.companion_bridge
	return {
		"available": bridge != null,
		"room_open": bridge != null and bridge.room_open,
		"connected_count": bridge.connected_client_count() if bridge != null else 0,
	}


func _public_seat_observations() -> Array[Dictionary]:
	var observations: Array[Dictionary] = []
	for seat: Dictionary in _seats.get_seats():
		(
			observations
			. append(
				{
					"seat_number": seat.seat_number,
					"state": seat.state,
					"input_kind":
					(
						"keyboard"
						if seat.device_id == SeatManager.KEYBOARD_DEVICE_ID
						else "controller"
					),
				}
			)
		)
	return observations


func _report_elapsed() -> int:
	return maxi((Time.get_ticks_msec() - _report_started_msec) / 1000, 0)


func _event_can_confirm(event: InputEvent, device_id: int) -> bool:
	if event is InputEventKey and (event as InputEventKey).physical_keycode == KEY_SPACE:
		return true
	return _seats.find_seat_by_device(device_id) >= 0


func _event_can_navigate(event: InputEvent, owns_active_seat: bool) -> bool:
	return owns_active_seat or event is InputEventKey


func _run_portable_build_smoke() -> void:
	var snapshot_before: Dictionary = _coordinator.to_snapshot()
	var before: String = JSON.stringify(snapshot_before)
	var authority_before: String = _coordinator.authority_digest()
	var history_before: String = _coordinator.public_history_digest()
	var report_before: String = _active_report.to_json()
	var companion_before: String = JSON.stringify(_companion_status())
	var rng_before: String = JSON.stringify(_rng_backed_state(snapshot_before))
	_open_help()
	for _page: int in 3:
		_help.handle_action("ui_navigate_right")
	var support: String = _help.page_text()
	var identity: Dictionary = InternalBuildIdentity.read_identity()
	var identity_valid: bool = InternalBuildIdentity.validate_identity(identity, false).accepted
	var report_guidance: String = InternalBuildIdentity.report_location_text(identity.platform)
	var registry := TaleProviderRegistry.new()
	var catalog_result: Dictionary = TaleCatalog.load_validated(
		TaleCatalog.PRODUCTION_PATH, registry, TaleCatalog.PRODUCTION_DIGEST
	)
	var package_result: Dictionary = registry.build_candidate(
		TaleCatalog.entry_by_id(
			catalog_result.get("catalog", {}), catalog_result.get("default_tale_id", "")
		)
	)
	var passed: bool = (
		_help.visible
		and _help.page_index() == 3
		and identity_valid
		and identity.classification == "internal_playtest"
		and catalog_result.get("digest", "") == TaleCatalog.PRODUCTION_DIGEST
		and package_result.get("package_digest", "") == TalePackage.LANTERN_HOUSE_DIGEST
		and "INTERNAL PLAYTEST (internal_playtest)" in support
		and str(identity.release) in support
		and str(identity.source_commit).substr(0, 12) in support
		and report_guidance in support
		and before == JSON.stringify(_coordinator.to_snapshot())
		and authority_before == _coordinator.authority_digest()
		and history_before == _coordinator.public_history_digest()
		and report_before == _active_report.to_json()
		and companion_before == JSON.stringify(_companion_status())
		and rng_before == JSON.stringify(_rng_backed_state(_coordinator.to_snapshot()))
	)
	print(
		"PORTABLE_BUILD_SMOKE:",
		(
			JSON
			. stringify(
				{
					"accepted": passed,
					"lifecycle": _coordinator.lifecycle,
					"release": identity.release,
					"source_commit": identity.source_commit,
					"platform": identity.platform,
					"architecture": identity.architecture,
					"classification": identity.classification,
					"catalog_kind": catalog_result.get("catalog", {}).get("catalog_kind", ""),
					"catalog_schema": catalog_result.get("catalog", {}).get("schema_version", 0),
					"catalog_digest": catalog_result.get("digest", ""),
					"selected_tale_id": catalog_result.get("default_tale_id", ""),
					"tale_package_kind": package_result.get("package", {}).get("package_kind", ""),
					"tale_package_schema":
					package_result.get("package", {}).get("schema_version", 0),
					"tale_package_digest": package_result.get("package_digest", ""),
					"help_page": _help.page_index() + 1,
					"classification_rendered": "INTERNAL PLAYTEST (internal_playtest)" in support,
					"report_location_guidance": report_guidance in support,
					"authority_unchanged": before == JSON.stringify(_coordinator.to_snapshot()),
					"authority_digest_unchanged":
					authority_before == _coordinator.authority_digest(),
					"public_history_digest_unchanged":
					history_before == _coordinator.public_history_digest(),
					"report_unchanged": report_before == _active_report.to_json(),
					"rng_backed_state_unchanged":
					rng_before == JSON.stringify(_rng_backed_state(_coordinator.to_snapshot())),
					"companion_projection_unchanged":
					companion_before == JSON.stringify(_companion_status()),
				}
			)
		)
	)
	get_tree().quit(0 if passed else 1)


func _rng_backed_state(snapshot: Dictionary) -> Dictionary:
	var rules: Dictionary = snapshot.get("rules", {})
	var director: Dictionary = snapshot.get("director", {})
	var roles: Dictionary = snapshot.get("roles", {})
	return {
		"rules": rules.get("rng", {}),
		"director": director.get("rng", {}),
		"roles": roles.get("rng", {}),
	}
