class_name DeviceRegistry
extends Node

signal devices_changed(devices: Array[Dictionary])
signal device_connected(device_id: int, identity: String)
signal device_disconnected(device_id: int)

var _devices: Dictionary = {}

func _ready() -> void:
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	for device_id: int in Input.get_connected_joypads():
		_register_device(device_id)
	_emit_snapshot()

func get_devices() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for device_id: int in _devices:
		result.append((_devices[device_id] as Dictionary).duplicate())
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.device_id < b.device_id)
	return result

func get_identity(device_id: int) -> String:
	if not _devices.has(device_id):
		return ""
	return str((_devices[device_id] as Dictionary).identity)

func get_display_name(device_id: int) -> String:
	if not _devices.has(device_id):
		return "Controller %d" % device_id
	return str((_devices[device_id] as Dictionary).name)

func has_device(device_id: int) -> bool:
	return _devices.has(device_id)

func _on_joy_connection_changed(device_id: int, connected: bool) -> void:
	if connected:
		_register_device(device_id)
		device_connected.emit(device_id, get_identity(device_id))
	else:
		_devices.erase(device_id)
		device_disconnected.emit(device_id)
	_emit_snapshot()

func _register_device(device_id: int) -> void:
	var guid: String = Input.get_joy_guid(device_id)
	var name: String = Input.get_joy_name(device_id)
	var identity: String = guid if not guid.is_empty() else "name:%s" % name
	_devices[device_id] = {"device_id": device_id, "name": name if not name.is_empty() else "Unknown controller", "guid": guid, "identity": identity}

func _emit_snapshot() -> void:
	devices_changed.emit(get_devices())
