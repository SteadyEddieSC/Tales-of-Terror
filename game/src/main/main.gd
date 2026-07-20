extends Control

const LAB_VERSION: String = "v0.1.0"
const RESET_HOLD_SECONDS: float = 1.5
const SEMANTIC_ACTIONS: PackedStringArray = [
	"ui_navigate_up",
	"ui_navigate_down",
	"ui_navigate_left",
	"ui_navigate_right",
	"ui_confirm",
	"ui_cancel_action",
	"player_join",
	"pause_options",
	"diagnostic_test",
	"interact",
]

var _devices: DeviceRegistry
var _coordinator := VerticalSliceCoordinator.new()
var _seats: SeatManager
var _ui: InputDisplayLab
var _slice_view: VerticalSliceView
var _input_router: PlayerInputRouter
var _sandbox: ExplorationSandbox
var _reset_held: float = 0.0
var _safe_margin: int = 24
var _developer_lab: bool = false


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
	_slice_view = VerticalSliceView.new()
	add_child(_slice_view)
	_slice_view.set_safe_margin(_safe_margin)
	_coordinator.lifecycle_changed.connect(_on_lifecycle_changed)
	_devices.devices_changed.connect(_on_devices_changed)
	_devices.device_connected.connect(_on_device_connected)
	_devices.device_disconnected.connect(_on_device_disconnected)
	_seats.seats_changed.connect(_on_seats_changed)
	_on_seats_changed(_seats.get_seats())
	_on_devices_changed(_devices.get_devices())
	_refresh_slice_view()
	print(
		ProjectSettings.get_setting("application/config/name"),
		" vertical slice loaded: ",
		LAB_VERSION
	)


func _process(delta: float) -> void:
	if Input.is_action_pressed("reset_seats"):
		_reset_held += delta
		_ui.present_reset_progress(minf(_reset_held / RESET_HOLD_SECONDS, 1.0))
		if is_instance_valid(_sandbox):
			_sandbox.present_reset_progress(minf(_reset_held / RESET_HOLD_SECONDS, 1.0))
		if _reset_held >= RESET_HOLD_SECONDS:
			_seats.reset_all()
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
	var joined_this_event: bool = false
	if event is InputEventKey:
		device_id = SeatManager.KEYBOARD_DEVICE_ID
	if event.is_action_pressed("player_join"):
		if device_id == SeatManager.KEYBOARD_DEVICE_ID:
			_seats.join_device(device_id, SeatManager.KEYBOARD_IDENTITY, "Keyboard (development)")
		elif _devices.has_device(device_id):
			_seats.join_device(
				device_id, _devices.get_identity(device_id), _devices.get_display_name(device_id)
			)
		if _coordinator.lifecycle == "boot_title" and not _coordinator.active_seats().is_empty():
			_coordinator.enter_lobby()
		joined_this_event = true
	for action: String in SEMANTIC_ACTIONS:
		if event.is_action_pressed(action):
			_seats.record_action(device_id, action)
			break
	if event.is_action_pressed("safe_area_decrease"):
		_adjust_safe_margin(-1)
	elif event.is_action_pressed("safe_area_increase"):
		_adjust_safe_margin(1)
	if event.is_action_pressed("ui_confirm") and not joined_this_event:
		_advance_player_flow()
	elif event.is_action_pressed("pause_options") and _coordinator.lifecycle == "active_tale":
		var pause_result: Dictionary = _coordinator.toggle_pause()
		if pause_result.accepted and is_instance_valid(_sandbox):
			_sandbox.process_mode = (
				Node.PROCESS_MODE_DISABLED if _coordinator.paused else Node.PROCESS_MODE_INHERIT
			)
	elif event.is_action_pressed("ui_cancel_action") and _coordinator.lifecycle == "lobby":
		_seats.leave_device(device_id)
		if _coordinator.active_seats().is_empty():
			_coordinator.cancel_setup()
	elif event.is_action_pressed("ui_cancel_action") and _coordinator.lifecycle == "ending":
		_coordinator.return_to_title()


func _ensure_sandbox() -> void:
	if is_instance_valid(_sandbox):
		return
	_sandbox = ExplorationSandbox.new()
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


func _advance_player_flow() -> void:
	match _coordinator.lifecycle:
		"lobby":
			_coordinator.confirm_roster()
		"confirmation":
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
				_destroy_sandbox()
	_refresh_slice_view()


func _on_lifecycle_changed(_state: Dictionary) -> void:
	_refresh_slice_view()


func _refresh_slice_view() -> void:
	if not is_instance_valid(_slice_view):
		return
	_slice_view.present(_coordinator.public_state(), _seats.get_seats(), _developer_lab)
	if not is_instance_valid(_sandbox):
		_ui.visible = _developer_lab


func _seat_supports_pawn(seat: Dictionary) -> bool:
	return (
		seat.state
		in [
			SeatManager.SeatState.ACTIVE,
			SeatManager.SeatState.RESERVED,
			SeatManager.SeatState.DISCONNECTED,
		]
	)
