class_name PawnRegistry
extends RefCounted

const SNAPSHOT_VERSION: int = 1
const SNAPSHOT_KEYS: PackedStringArray = ["snapshot_version", "pawns"]
const PAWN_KEYS: PackedStringArray = [
	"seat_number",
	"device_id",
	"identity",
	"connected",
	"position",
	"input_vector",
	"nearby_interactable",
]
const VECTOR_KEYS: PackedStringArray = ["x", "y"]

var _pawns: Dictionary = {}


func sync_seats(seats: Array[Dictionary], spawn_points: Array[Vector2]) -> void:
	for seat: Dictionary in seats:
		var seat_number: int = seat.seat_number
		var state: int = seat.state
		if (
			state
			in [
				SeatManager.SeatState.ACTIVE,
				SeatManager.SeatState.DISCONNECTED,
				SeatManager.SeatState.RESERVED,
			]
		):
			if not _pawns.has(seat_number):
				var spawn_index: int = (seat_number - 1) % spawn_points.size()
				_pawns[seat_number] = PawnState.new(
					seat_number, seat.device_id, seat.identity, spawn_points[spawn_index]
				)
			var pawn: PawnState = _pawns[seat_number]
			pawn.identity = seat.identity
			pawn.connected = state == SeatManager.SeatState.ACTIVE
			pawn.device_id = seat.device_id if pawn.connected else -99
		elif state == SeatManager.SeatState.UNASSIGNED:
			_pawns.erase(seat_number)


func get_pawns() -> Array[PawnState]:
	var result: Array[PawnState] = []
	for seat_number: int in _pawns:
		result.append(_pawns[seat_number])
	result.sort_custom(
		func(a: PawnState, b: PawnState) -> bool: return a.seat_number < b.seat_number
	)
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


func to_snapshot() -> Dictionary:
	var rows: Array[Dictionary] = []
	for pawn: PawnState in get_pawns():
		(
			rows
			. append(
				{
					"seat_number": pawn.seat_number,
					"device_id": pawn.device_id,
					"identity": pawn.identity,
					"connected": pawn.connected,
					"position": _vector_snapshot(pawn.position),
					"input_vector": _vector_snapshot(pawn.input_vector),
					"nearby_interactable": pawn.nearby_interactable,
				}
			)
		)
	return {"snapshot_version": SNAPSHOT_VERSION, "pawns": rows}


func restore_snapshot(snapshot: Dictionary, seats: Array[Dictionary], bounds: Rect2) -> Dictionary:
	var parsed: Dictionary = _parse_snapshot(snapshot, seats, bounds)
	if not parsed.accepted:
		return parsed
	_pawns = parsed.pawns
	return {"accepted": true, "reason": ""}


func clear() -> void:
	_pawns.clear()


func _parse_snapshot(snapshot: Dictionary, seats: Array[Dictionary], bounds: Rect2) -> Dictionary:
	if not _has_exact_keys(snapshot, SNAPSHOT_KEYS):
		return {"accepted": false, "reason": "malformed_pawn_snapshot"}
	if snapshot.snapshot_version != SNAPSHOT_VERSION or not snapshot.pawns is Array:
		return {"accepted": false, "reason": "unsupported_pawn_snapshot"}
	var roster: Dictionary = _parse_expected_roster(seats)
	if not roster.accepted:
		return roster
	var expected: Dictionary = roster.expected
	if snapshot.pawns.size() != expected.size() or snapshot.pawns.size() > SeatManager.MAX_SEATS:
		return {"accepted": false, "reason": "pawn_roster_mismatch"}
	var restored: Dictionary = {}
	for value: Variant in snapshot.pawns:
		var parsed_row: Dictionary = _parse_pawn_row(value, expected, restored, bounds)
		if not parsed_row.accepted:
			return parsed_row
		restored[parsed_row.seat_number] = parsed_row.pawn
	return {"accepted": true, "reason": "", "pawns": restored}


func _parse_expected_roster(seats: Array[Dictionary]) -> Dictionary:
	var expected: Dictionary = {}
	var active_devices: Dictionary = {}
	var reason: String = ""
	for seat: Dictionary in seats:
		if not _valid_seat_row(seat):
			reason = "malformed_pawn_roster"
			break
		if (
			seat.state
			in [
				SeatManager.SeatState.ACTIVE,
				SeatManager.SeatState.DISCONNECTED,
				SeatManager.SeatState.RESERVED,
			]
		):
			expected[seat.seat_number] = seat
			if seat.state == SeatManager.SeatState.ACTIVE:
				if active_devices.has(seat.device_id):
					reason = "duplicate_pawn_device"
					break
				active_devices[seat.device_id] = true
	return (
		{"accepted": true, "reason": "", "expected": expected}
		if reason.is_empty()
		else {"accepted": false, "reason": reason}
	)


func _parse_pawn_row(
	value: Variant, expected: Dictionary, restored: Dictionary, bounds: Rect2
) -> Dictionary:
	var reason: String = ""
	var seat_number: int = 0
	var pawn: PawnState
	if not value is Dictionary or not _has_exact_keys(value, PAWN_KEYS):
		reason = "malformed_pawn_row"
	else:
		var row: Dictionary = value
		var seat_value: Variant = row.get("seat_number")
		if not seat_value is int or not expected.has(seat_value) or restored.has(seat_value):
			reason = "unknown_or_duplicate_pawn"
		else:
			seat_number = seat_value
			var position_result: Dictionary = _parse_vector(row.position)
			var input_result: Dictionary = _parse_vector(row.input_vector)
			if not _row_matches_seat(row, expected[seat_number]):
				reason = "pawn_ownership_mismatch"
			elif not position_result.accepted or not input_result.accepted:
				reason = "malformed_pawn_vector"
			elif (
				not _position_allowed(position_result.value, bounds)
				or (input_result.value as Vector2).length_squared() > 1.000001
			):
				reason = "pawn_vector_out_of_bounds"
			elif not row.nearby_interactable is String or row.nearby_interactable.length() > 64:
				reason = "malformed_pawn_interaction"
			else:
				pawn = PawnState.new(
					seat_number, row.device_id, row.identity, position_result.value
				)
				pawn.connected = row.connected
				pawn.input_vector = input_result.value
				pawn.nearby_interactable = row.nearby_interactable
	return (
		{"accepted": true, "reason": "", "seat_number": seat_number, "pawn": pawn}
		if reason.is_empty()
		else {"accepted": false, "reason": reason}
	)


func _valid_seat_row(seat: Dictionary) -> bool:
	return (
		seat.get("seat_number") is int
		and seat.seat_number >= 1
		and seat.seat_number <= SeatManager.MAX_SEATS
		and seat.get("state") is int
		and seat.state >= SeatManager.SeatState.UNASSIGNED
		and seat.state <= SeatManager.SeatState.RESERVED
		and seat.get("device_id") is int
		and seat.get("identity") is String
	)


func _row_matches_seat(row: Dictionary, seat: Dictionary) -> bool:
	var should_connect: bool = seat.state == SeatManager.SeatState.ACTIVE
	return (
		row.get("device_id") is int
		and row.get("identity") is String
		and row.get("connected") is bool
		and row.identity == seat.identity
		and row.connected == should_connect
		and row.device_id == (seat.device_id if should_connect else -99)
	)


func _parse_vector(value: Variant) -> Dictionary:
	if not value is Dictionary or not _has_exact_keys(value, VECTOR_KEYS):
		return {"accepted": false}
	var x: Variant = value.get("x")
	var y: Variant = value.get("y")
	if not (x is float or x is int) or not (y is float or y is int):
		return {"accepted": false}
	if not is_finite(float(x)) or not is_finite(float(y)):
		return {"accepted": false}
	return {"accepted": true, "value": Vector2(float(x), float(y))}


func _position_allowed(position: Vector2, bounds: Rect2) -> bool:
	var minimum: Vector2 = bounds.position + Vector2.ONE * PawnState.COLLISION_RADIUS
	var maximum: Vector2 = bounds.end - Vector2.ONE * PawnState.COLLISION_RADIUS
	var inside_bounds: bool = (
		position.x >= minimum.x
		and position.y >= minimum.y
		and position.x <= maximum.x
		and position.y <= maximum.y
	)
	if not inside_bounds:
		return false
	for wall: Rect2 in ExplorationRoom.WALLS:
		if wall.grow(PawnState.COLLISION_RADIUS).has_point(position):
			return false
	return true


func _has_exact_keys(value: Dictionary, expected: PackedStringArray) -> bool:
	if value.size() != expected.size():
		return false
	for key: Variant in value:
		if not key is String or not expected.has(key):
			return false
	return true


func _vector_snapshot(value: Vector2) -> Dictionary:
	return {"x": value.x, "y": value.y}
