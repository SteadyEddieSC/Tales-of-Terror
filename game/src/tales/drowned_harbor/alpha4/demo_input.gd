class_name DrownedHarborDemoInput
extends Node

signal command(action: String, stable_seat: String)
signal roster_changed(roster: Array[Dictionary])
signal connection_changed(stable_seat: String, connected: bool)

const ACTIONS: Dictionary = {
	"ui_navigate_up": "up",
	"ui_navigate_down": "down",
	"ui_navigate_left": "left",
	"ui_navigate_right": "right",
	"ui_confirm": "confirm",
	"ui_cancel_action": "back",
	"help_accessibility": "help",
	"pause_options": "pause",
	"demo_private": "private",
	"demo_cycle_seat": "cycle_seat",
	"demo_add_seat": "add_seat",
}

var active_seat: String = ""
var lobby_open: bool = true
var _seats := SeatManager.new()
var _registry: DeviceRegistry
var _keyboard_seat: String = ""
var _pending: Array[Dictionary] = []
var _held: Dictionary = {}
var _reclaim_seat: String = ""


func _ready() -> void:
	_install_actions()
	_registry = DeviceRegistry.new()
	_registry.device_connected.connect(_controller_connected)
	_registry.device_disconnected.connect(disconnect_device)
	add_child(_registry)


func _input(event: InputEvent) -> void:
	if not (
		event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion
	):
		return
	if event is InputEventKey and event.echo:
		return
	var device: int = SeatManager.KEYBOARD_DEVICE_ID if event is InputEventKey else event.device
	if not lobby_open and stable_seats().is_empty():
		for navigate: String in [
			"ui_navigate_up", "ui_navigate_down", "ui_navigate_left", "ui_navigate_right"
		]:
			if event.is_action_pressed(navigate):
				if device == SeatManager.KEYBOARD_DEVICE_ID:
					add_keyboard_seat()
				else:
					join_device(
						device, _registry.get_identity(device), _registry.get_display_name(device)
					)
	if (
		(event.is_action_pressed("player_join") or event.is_action_pressed("ui_confirm"))
		and _seat_for_device(device).is_empty()
	):
		if device >= 0 and not _reclaim_seat.is_empty():
			_reclaim_controller(device)
			get_viewport().set_input_as_handled()
			return
		if lobby_open or stable_seats().is_empty():
			var initial_title: bool = not lobby_open and stable_seats().is_empty()
			if device == SeatManager.KEYBOARD_DEVICE_ID:
				add_keyboard_seat()
			else:
				join_device(
					device, _registry.get_identity(device), _registry.get_display_name(device)
				)
			if initial_title:
				queue_command(device, "confirm")
			_held["%d:confirm" % device] = true
			get_viewport().set_input_as_handled()
			return
	for input_action: String in ACTIONS:
		if not event.is_action(input_action):
			continue
		var action: String = ACTIONS[input_action]
		var token: String = "%d:%s" % [device, action]
		var pressed: bool = event.is_action_pressed(input_action)
		if not pressed:
			_held.erase(token)
		elif not _held.has(token):
			_held[token] = true
			queue_command(device, action)
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	flush_commands()


func public_roster() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for row: Dictionary in _seats.get_seats():
		if row.state == SeatManager.SeatState.UNASSIGNED:
			continue
		(
			result
			. append(
				{
					"stable_seat_id": _stable_id(row.seat_number - 1),
					"seat_number": row.seat_number,
					"connected": row.state == SeatManager.SeatState.ACTIVE,
					"keyboard": row.identity.begins_with("demo-keyboard:"),
					"label": "Seat %d" % row.seat_number,
					"device_label": row.device_name,
				}
			)
		)
	return result


func stable_seats() -> PackedStringArray:
	var result := PackedStringArray()
	for row: Dictionary in public_roster():
		result.append(row.stable_seat_id)
	return result


func join_device(device_id: int, identity: String, display_name: String) -> String:
	if device_id < 0 or identity.is_empty():
		return ""
	var existing: int = _seats.find_seat_by_device(device_id)
	if existing >= 0:
		return _stable_id(existing)
	var index: int = _seats.reconnect_device(device_id, identity, display_name)
	if index < 0 and (lobby_open or stable_seats().is_empty()):
		index = _seats.join_device(device_id, identity, display_name)
	if index < 0:
		return ""
	var seat: String = _stable_id(index)
	_emit_roster()
	connection_changed.emit(seat, true)
	return seat


func add_keyboard_seat() -> String:
	if not lobby_open and not stable_seats().is_empty():
		return ""
	var rows: Array[Dictionary] = _seats.get_seats()
	for number: int in SeatManager.MAX_SEATS:
		var device: int = -100 - number
		if rows[number].state != SeatManager.SeatState.UNASSIGNED:
			continue
		var index: int = _seats.join_device(
			device, "demo-keyboard:%d" % number, "Keyboard pass-play"
		)
		if index < 0:
			return ""
		_keyboard_seat = _stable_id(index)
		_emit_roster()
		connection_changed.emit(_keyboard_seat, true)
		return _keyboard_seat
	return ""


func set_active_seat(seat: String) -> void:
	active_seat = seat
	for row: Dictionary in public_roster():
		if row.stable_seat_id == seat and row.keyboard and row.connected:
			_keyboard_seat = seat


func set_roster(seats: Variant) -> Dictionary:
	if not (seats is Array or seats is PackedStringArray) or seats.is_empty() or seats.size() > 8:
		return {"accepted": false, "reason": "invalid_roster"}
	var unique: Dictionary = {}
	for seat: Variant in seats:
		if not seat is String or _seat_index(seat) < 0 or unique.has(seat):
			return {"accepted": false, "reason": "invalid_roster"}
		unique[seat] = true
	var rows: Array[Dictionary] = _seats.get_seats()
	var empty := SeatManager.new()
	var clean_rows: Array[Dictionary] = empty.get_seats()
	for index: int in 8:
		var seat: String = _stable_id(index)
		if not unique.has(seat):
			rows[index] = clean_rows[index]
		elif rows[index].state == SeatManager.SeatState.UNASSIGNED:
			rows[index].state = SeatManager.SeatState.RESERVED
			rows[index].identity = "restore:%s" % seat
			rows[index].device_name = "Awaiting local reclaim"
	_seats.restore_snapshot({"snapshot_version": 1, "seats": rows})
	_pending.clear()
	_held.clear()
	_reclaim_seat = ""
	if not unique.has(_keyboard_seat):
		_keyboard_seat = ""
	_emit_roster()
	return {"accepted": true, "reason": ""}


func reclaim_with_keyboard(seat: String) -> bool:
	var index: int = _seat_index(seat)
	if index < 0:
		return false
	var rows: Array[Dictionary] = _seats.get_seats()
	if rows[index].state == SeatManager.SeatState.UNASSIGNED:
		return false
	if rows[index].state == SeatManager.SeatState.ACTIVE and rows[index].device_id >= 0:
		return false
	rows[index].state = SeatManager.SeatState.ACTIVE
	rows[index].device_id = -100 - index
	rows[index].previous_device_id = -100 - index
	rows[index].identity = "demo-keyboard:%d" % index
	rows[index].device_name = "Keyboard pass-play"
	_seats.restore_snapshot({"snapshot_version": 1, "seats": rows})
	_keyboard_seat = seat
	if _reclaim_seat == seat:
		_reclaim_seat = ""
	_emit_roster()
	connection_changed.emit(seat, true)
	return true


func begin_reclaim(seat: String) -> bool:
	_reclaim_seat = ""
	var index: int = _seat_index(seat)
	if index < 0:
		return false
	var row: Dictionary = _seats.get_seats()[index]
	if row.state != SeatManager.SeatState.RESERVED or not row.identity.begins_with("restore:"):
		return false
	_reclaim_seat = seat
	return true


func pending_reclaim_seat() -> String:
	return _reclaim_seat


func disconnect_device(device_id: int) -> void:
	var index: int = _seats.disconnect_device(device_id)
	if index < 0:
		return
	var seat: String = _stable_id(index)
	_pending = _pending.filter(func(row: Dictionary) -> bool: return row.seat != seat)
	for token: String in _held.keys():
		if token.begins_with("%d:" % device_id):
			_held.erase(token)
	_emit_roster()
	connection_changed.emit(seat, false)


func reset_roster() -> void:
	_seats.reset_all()
	_keyboard_seat = ""
	active_seat = ""
	_pending.clear()
	_held.clear()
	_reclaim_seat = ""
	_emit_roster()


func queue_command(device_id: int, action: String) -> bool:
	if not ACTIONS.values().has(action):
		return false
	if device_id == SeatManager.KEYBOARD_DEVICE_ID and action in ["add_seat", "cycle_seat"]:
		if action == "cycle_seat":
			_cycle_keyboard()
			return true
		return not add_keyboard_seat().is_empty()
	var seat: String = _seat_for_device(device_id)
	if seat.is_empty():
		return false
	if not lobby_open and not active_seat.is_empty() and seat != active_seat:
		if action not in ["help", "pause"]:
			return false
	var duplicate: bool = false
	for pending: Dictionary in _pending:
		duplicate = duplicate or pending.seat == seat and pending.action == action
	if not duplicate:
		_pending.append({"seat": seat, "action": action, "sequence": _pending.size()})
	return not duplicate


func flush_commands() -> void:
	# Each frame is a batch: ascending stable seat, then arrival order within that seat.
	var pending: Array[Dictionary] = _pending
	_pending = []
	pending.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			return a.sequence < b.sequence if a.seat == b.seat else a.seat < b.seat
	)
	for row: Dictionary in pending:
		command.emit(row.action, row.seat)


func _seat_for_device(device_id: int) -> String:
	if device_id == SeatManager.KEYBOARD_DEVICE_ID:
		return _keyboard_seat
	var index: int = _seats.find_seat_by_device(device_id)
	return _stable_id(index) if index >= 0 else ""


func _cycle_keyboard() -> void:
	var owned: Array[String] = []
	for row: Dictionary in public_roster():
		if row.keyboard and row.connected:
			owned.append(row.stable_seat_id)
	if owned.is_empty():
		return
	_keyboard_seat = owned[(owned.find(_keyboard_seat) + 1) % owned.size()]
	command.emit("seat_changed", _keyboard_seat)


func _controller_connected(device_id: int, identity: String) -> void:
	if _seats.find_reserved_seat(identity, device_id) >= 0:
		join_device(device_id, identity, _registry.get_display_name(device_id))


func _reclaim_controller(device_id: int) -> void:
	var index: int = _seat_index(_reclaim_seat)
	if index < 0:
		return
	var rows: Array[Dictionary] = _seats.get_seats()
	if (
		rows[index].state != SeatManager.SeatState.RESERVED
		or not rows[index].identity.begins_with("restore:")
	):
		_reclaim_seat = ""
		return
	if _registry.get_identity(device_id).is_empty():
		return
	rows[index].state = SeatManager.SeatState.ACTIVE
	rows[index].device_id = device_id
	rows[index].previous_device_id = device_id
	rows[index].identity = _registry.get_identity(device_id)
	rows[index].device_name = _registry.get_display_name(device_id)
	_seats.restore_snapshot({"snapshot_version": 1, "seats": rows})
	var seat: String = _reclaim_seat
	_reclaim_seat = ""
	_emit_roster()
	connection_changed.emit(seat, true)


func _emit_roster() -> void:
	roster_changed.emit(public_roster())


static func _stable_id(index: int) -> String:
	return "seat_%02d" % (index + 1)


static func _seat_index(seat: String) -> int:
	for index: int in 8:
		if seat == _stable_id(index):
			return index
	return -1


static func _install_actions() -> void:
	for row: Array in [
		["demo_private", KEY_V, JOY_BUTTON_Y],
		["demo_cycle_seat", KEY_TAB, -1],
		["demo_add_seat", KEY_J, -1]
	]:
		if InputMap.has_action(row[0]):
			continue
		InputMap.add_action(row[0])
		var key := InputEventKey.new()
		key.physical_keycode = row[1]
		InputMap.action_add_event(row[0], key)
		if row[2] >= 0:
			var button := InputEventJoypadButton.new()
			button.device = -1
			button.button_index = row[2]
			InputMap.action_add_event(row[0], button)
