extends Control

const LAB_VERSION: String = "v0.0.9"
const RESET_HOLD_SECONDS: float = 1.5
const SEMANTIC_ACTIONS: PackedStringArray = [
	"ui_navigate_up", "ui_navigate_down", "ui_navigate_left", "ui_navigate_right",
	"ui_confirm", "ui_cancel_action", "player_join", "pause_options", "diagnostic_test", "interact",
]

var _devices: DeviceRegistry
var _seats := SeatManager.new()
var _ui: InputDisplayLab
var _input_router: PlayerInputRouter
var _sandbox: ExplorationSandbox
var _reset_held: float = 0.0
var _safe_margin: int = 24

func _ready() -> void:
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
	_devices.devices_changed.connect(_on_devices_changed)
	_devices.device_connected.connect(_on_device_connected)
	_devices.device_disconnected.connect(_on_device_disconnected)
	_seats.seats_changed.connect(_on_seats_changed)
	_on_seats_changed(_seats.get_seats())
	_on_devices_changed(_devices.get_devices())
	print(ProjectSettings.get_setting("application/config/name"), " exploration loaded: ", LAB_VERSION)

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
	if event is InputEventKey:
		device_id = SeatManager.KEYBOARD_DEVICE_ID
	if event.is_action_pressed("player_join"):
		if device_id == SeatManager.KEYBOARD_DEVICE_ID:
			_seats.join_device(device_id, SeatManager.KEYBOARD_IDENTITY, "Keyboard (development)")
		elif _devices.has_device(device_id):
			_seats.join_device(device_id, _devices.get_identity(device_id), _devices.get_display_name(device_id))
	for action: String in SEMANTIC_ACTIONS:
		if event.is_action_pressed(action):
			_seats.record_action(device_id, action)
			break
	if event.is_action_pressed("safe_area_decrease"):
		_adjust_safe_margin(-1)
	elif event.is_action_pressed("safe_area_increase"):
		_adjust_safe_margin(1)

func _ensure_sandbox() -> void:
	if is_instance_valid(_sandbox):
		return
	_sandbox = ExplorationSandbox.new()
	_sandbox.setup(_input_router)
	add_child(_sandbox)
	_sandbox.set_safe_margin(_safe_margin)
	_ui.visible = false

func _destroy_sandbox() -> void:
	if is_instance_valid(_sandbox):
		_sandbox.queue_free()
	_sandbox = null
	_ui.visible = true

func _adjust_safe_margin(direction: int) -> void:
	_safe_margin = clampi(_safe_margin + direction * 8, 0, 48)
	_ui.set_safe_margin(_safe_margin)
	if is_instance_valid(_sandbox):
		_sandbox.set_safe_margin(_safe_margin)

func _on_interact_requested(device_id: int) -> void:
	if is_instance_valid(_sandbox):
		_sandbox.request_interaction(device_id)

func _on_diagnostics_requested(_device_id: int) -> void:
	if is_instance_valid(_sandbox):
		_sandbox.toggle_diagnostics()

func _on_rules_navigation_requested(device_id: int, direction: int, confirm: bool, cancel: bool) -> void:
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
	var has_pawns: bool = seats.any(func(seat: Dictionary) -> bool: return seat.state == SeatManager.SeatState.ACTIVE or seat.state == SeatManager.SeatState.RESERVED or seat.state == SeatManager.SeatState.DISCONNECTED)
	if has_pawns:
		_ensure_sandbox()
		_sandbox.sync_seats(seats)
	else:
		_destroy_sandbox()
