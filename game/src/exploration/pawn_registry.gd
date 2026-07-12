class_name PawnRegistry
extends RefCounted

var _pawns: Dictionary = {}

func sync_seats(seats: Array[Dictionary], spawn_points: Array[Vector2]) -> void:
	for seat: Dictionary in seats:
		var seat_number: int = seat.seat_number
		var state: int = seat.state
		if state == SeatManager.SeatState.ACTIVE:
			if not _pawns.has(seat_number):
				var spawn_index: int = (seat_number - 1) % spawn_points.size()
				_pawns[seat_number] = PawnState.new(seat_number, seat.device_id, seat.identity, spawn_points[spawn_index])
			var pawn: PawnState = _pawns[seat_number]
			pawn.device_id = seat.device_id
			pawn.identity = seat.identity
			pawn.connected = true
		elif state == SeatManager.SeatState.DISCONNECTED or state == SeatManager.SeatState.RESERVED:
			if _pawns.has(seat_number):
				var reserved_pawn: PawnState = _pawns[seat_number]
				reserved_pawn.connected = false
				reserved_pawn.device_id = -99
		elif state == SeatManager.SeatState.UNASSIGNED:
			_pawns.erase(seat_number)

func get_pawns() -> Array[PawnState]:
	var result: Array[PawnState] = []
	for seat_number: int in _pawns:
		result.append(_pawns[seat_number])
	result.sort_custom(func(a: PawnState, b: PawnState) -> bool: return a.seat_number < b.seat_number)
	return result

func get_by_seat(seat_number: int) -> PawnState:
	return _pawns.get(seat_number) as PawnState

func get_by_device(device_id: int) -> PawnState:
	for pawn: PawnState in get_pawns():
		if pawn.connected and pawn.device_id == device_id:
			return pawn
	return null

func owns_device(device_id: int) -> bool:
	return get_by_device(device_id) != null

func clear() -> void:
	_pawns.clear()
