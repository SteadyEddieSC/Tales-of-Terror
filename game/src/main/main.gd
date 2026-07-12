extends Control

const LAB_VERSION: String = "v0.0.2"
const RESET_HOLD_SECONDS: float = 1.5
const SEMANTIC_ACTIONS: PackedStringArray = ["ui_navigate_up", "ui_navigate_down", "ui_navigate_left", "ui_navigate_right", "ui_confirm", "ui_cancel_action", "player_join", "pause_options", "diagnostic_test"]
var _devices: DeviceRegistry
var _seats := SeatManager.new()
var _ui: InputDisplayLab
var _reset_held: float = 0.0

func _ready() -> void:
	_devices = DeviceRegistry.new()
	add_child(_devices)
	_ui = InputDisplayLab.new()
	add_child(_ui)
	_devices.devices_changed.connect(_on_devices_changed)
	_devices.device_connected.connect(_on_device_connected)
	_devices.device_disconnected.connect(_on_device_disconnected)
	_seats.seats_changed.connect(_on_seats_changed)
	_on_seats_changed(_seats.get_seats())
	_on_devices_changed(_devices.get_devices())
	print(ProjectSettings.get_setting("application/config/name"), " lab loaded: ", LAB_VERSION)

func _process(delta: float) -> void:
	if Input.is_action_pressed("reset_seats"):
		_reset_held += delta
		_ui.present_reset_progress(minf(_reset_held / RESET_HOLD_SECONDS, 1.0))
		if _reset_held >= RESET_HOLD_SECONDS:
			_seats.reset_all()
			_reset_held = 0.0
	else:
		if _reset_held > 0.0:
			_ui.present_reset_progress(0.0)
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
		_ui.adjust_safe_margin(-1)
	elif event.is_action_pressed("safe_area_increase"):
		_ui.adjust_safe_margin(1)

func _on_device_connected(device_id: int, identity: String) -> void:
	_seats.reconnect_device(device_id, identity, _devices.get_display_name(device_id))

func _on_device_disconnected(device_id: int) -> void:
	_seats.disconnect_device(device_id)

func _on_devices_changed(devices: Array[Dictionary]) -> void:
	_ui.present_devices(devices, _seats.get_seats())

func _on_seats_changed(seats: Array[Dictionary]) -> void:
	_ui.present_seats(seats)
	_ui.present_devices(_devices.get_devices() if is_instance_valid(_devices) else [], seats)
