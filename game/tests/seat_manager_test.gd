extends SceneTree

var _failures: int = 0

func _initialize() -> void:
	var seats := SeatManager.new()
	_expect(seats.get_seats().size() == 8, "represents eight seats")
	for device_id: int in 8:
		_expect(seats.join_device(device_id, "guid-%d" % device_id, "Pad %d" % device_id) == device_id, "assigns device %d" % device_id)
	_expect(seats.join_device(0, "guid-0", "Pad 0") == 0, "prevents duplicate assignment")
	_expect(seats.join_device(8, "guid-8", "Pad 8") == -1, "rejects a ninth seat")
	_expect(seats.disconnect_device(3) == 3, "disconnects assigned controller")
	var reserved: Dictionary = seats.get_seats()[3]
	_expect(reserved.state == SeatManager.SeatState.RESERVED, "reserves disconnected seat")
	_expect(seats.reconnect_device(12, "guid-3", "Pad 3 reconnected") == 3, "reclaims reservation by identity")
	var reclaimed: Dictionary = seats.get_seats()[3]
	_expect(reclaimed.device_id == 12 and reclaimed.state == SeatManager.SeatState.ACTIVE, "updates device ID without moving seat")
	var twins := SeatManager.new()
	twins.join_device(0, "shared-guid", "Twin Pad")
	twins.join_device(1, "shared-guid", "Twin Pad")
	twins.disconnect_device(0)
	twins.disconnect_device(1)
	_expect(twins.reconnect_device(7, "shared-guid", "Twin Pad") == -1, "does not guess between ambiguous reservations")
	_expect(twins.reconnect_device(1, "shared-guid", "Twin Pad") == 1, "prefers previous device ID for identical controllers")
	seats.record_action(12, "diagnostic_test")
	_expect(seats.get_seats()[3].last_action == "diagnostic_test", "records semantic action")
	seats.reset_all()
	_expect(seats.get_seats().all(func(seat: Dictionary) -> bool: return seat.state == SeatManager.SeatState.UNASSIGNED), "resets all seats")
	if _failures == 0:
		print("SeatManager tests passed")
	quit(_failures)

func _expect(condition: bool, description: String) -> void:
	if not condition:
		_failures += 1
		push_error("FAILED: %s" % description)
