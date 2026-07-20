class_name SeatManager
extends RefCounted

signal seats_changed(seats: Array[Dictionary])

enum SeatState { UNASSIGNED, JOINING, ACTIVE, DISCONNECTED, RESERVED }
const MAX_SEATS: int = 8
const KEYBOARD_DEVICE_ID: int = -1
const KEYBOARD_IDENTITY: String = "keyboard-development"
var _seats: Array[Dictionary] = []


func _init() -> void:
	for index: int in MAX_SEATS:
		_seats.append(_new_seat(index))


func get_seats() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for seat: Dictionary in _seats:
		result.append(seat.duplicate())
	return result


func join_device(device_id: int, identity: String, display_name: String) -> int:
	var existing: int = find_seat_by_device(device_id)
	if existing >= 0:
		return existing
	var reserved: int = find_reserved_seat(identity, device_id)
	if reserved >= 0:
		_assign(reserved, device_id, identity, display_name)
		return reserved
	for index: int in MAX_SEATS:
		if _seats[index].state == SeatState.UNASSIGNED:
			_seats[index].state = SeatState.JOINING
			_assign(index, device_id, identity, display_name)
			return index
	return -1


func disconnect_device(device_id: int) -> int:
	var index: int = find_seat_by_device(device_id)
	if index < 0:
		return -1
	_seats[index].previous_device_id = device_id
	_seats[index].device_id = -99
	_seats[index].state = SeatState.DISCONNECTED
	_emit()
	_seats[index].state = SeatState.RESERVED
	_emit()
	return index


func reconnect_device(device_id: int, identity: String, display_name: String) -> int:
	var index: int = find_reserved_seat(identity, device_id)
	if index >= 0:
		_assign(index, device_id, identity, display_name)
	return index


func record_action(device_id: int, action_name: String) -> void:
	var index: int = find_seat_by_device(device_id)
	if index < 0:
		return
	_seats[index].last_action = action_name
	_emit()


func reset_all() -> void:
	for index: int in MAX_SEATS:
		_seats[index] = _new_seat(index)
	_emit()


func find_seat_by_device(device_id: int) -> int:
	for index: int in MAX_SEATS:
		if _seats[index].state == SeatState.ACTIVE and _seats[index].device_id == device_id:
			return index
	return -1


func find_reserved_seat(identity: String, device_id: int = -99) -> int:
	if identity.is_empty():
		return -1
	for index: int in MAX_SEATS:
		if (
			_seats[index].state == SeatState.RESERVED
			and _seats[index].identity == identity
			and _seats[index].previous_device_id == device_id
		):
			return index
	var identity_matches: Array[int] = []
	for index: int in MAX_SEATS:
		if _seats[index].state == SeatState.RESERVED and _seats[index].identity == identity:
			identity_matches.append(index)
	return identity_matches[0] if identity_matches.size() == 1 else -1


static func state_label(state: int) -> String:
	return ["UNASSIGNED", "JOINING", "ACTIVE", "DISCONNECTED", "RESERVED"][state]


func _assign(index: int, device_id: int, identity: String, display_name: String) -> void:
	_seats[index].device_id = device_id
	_seats[index].previous_device_id = device_id
	_seats[index].identity = identity
	_seats[index].device_name = display_name
	_seats[index].state = SeatState.ACTIVE
	_seats[index].last_action = "player_join"
	_emit()


func _new_seat(index: int) -> Dictionary:
	return {
		"seat_number": index + 1,
		"state": SeatState.UNASSIGNED,
		"device_id": -99,
		"previous_device_id": -99,
		"identity": "",
		"device_name": "—",
		"last_action": "—"
	}


func _emit() -> void:
	seats_changed.emit(get_seats())
