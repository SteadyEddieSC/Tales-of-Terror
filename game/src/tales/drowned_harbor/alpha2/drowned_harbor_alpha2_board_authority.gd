class_name DrownedHarborAlpha2BoardAuthority
extends RefCounted

const SNAPSHOT_VERSION: int = 2
const START_SPACE: String = "harbor_gate"
const HIGH_WATER_MUTATIONS: Array[Dictionary] = [
	{"type": "set_connector_state", "connector_id": "gate_to_market", "state": "closed"},
	{
		"type": "set_hazard",
		"space_id": "high_water_channel",
		"value_id": "high_water_surge",
		"active": true,
	},
	{
		"type": "set_feature",
		"space_id": "last_light_beacon",
		"value_id": "last_light_active",
		"active": true,
	},
]

var _definition := DrownedHarborAlpha2BoardDefinition.new()
var _state := BoardState.new(_definition)
var _pawns: Dictionary = {}
var _stable_seat_order: Array[String] = []
var _tide_state: String = "low_tide"


func _init(stable_seat_ids: PackedStringArray = PackedStringArray()) -> void:
	for index: int in stable_seat_ids.size():
		var stable_seat_id: String = stable_seat_ids[index]
		var pawn := PawnState.new(
			index + 1, -1, stable_seat_id, _definition.space_center(START_SPACE)
		)
		_pawns[stable_seat_id] = pawn
		_stable_seat_order.append(stable_seat_id)
	_sync_occupancy()


func move_to(stable_seat_id: String, destination: String) -> Dictionary:
	if not _pawns.has(stable_seat_id):
		return _rejected("wrong_stable_seat")
	if _definition.get_space(destination).is_empty():
		return _rejected("unknown_destination")
	var pawn: PawnState = _pawns[stable_seat_id]
	var current: String = _state.space_for_seat(pawn.seat_number)
	if current == destination:
		return _rejected("already_at_destination")
	if _state.shortest_path(current, destination).is_empty():
		return _rejected("destination_unreachable")
	pawn.position = _definition.space_center(destination)
	_sync_occupancy()
	return {"accepted": true, "reason": "", "from": current, "to": destination}


func apply_high_water_atomic() -> Dictionary:
	if _tide_state == "high_water":
		return _rejected("high_water_already_applied")
	var probe := BoardState.new(_definition)
	var restored: Dictionary = probe.restore_snapshot(_state.to_snapshot())
	if not restored.get("accepted", false):
		return _rejected("board_probe_restore_failed")
	for mutation: Dictionary in HIGH_WATER_MUTATIONS:
		var probe_result: Dictionary = probe.apply_mutation(mutation)
		if not probe_result.get("accepted", false):
			return _rejected("high_water_candidate_invalid")
	for mutation: Dictionary in HIGH_WATER_MUTATIONS:
		var committed: Dictionary = _state.apply_mutation(mutation)
		if not committed.get("accepted", false):
			return _rejected("high_water_commit_failed")
	_tide_state = "high_water"
	return {
		"accepted": true,
		"reason": "",
		"tide_state": _tide_state,
		"mutations": HIGH_WATER_MUTATIONS.duplicate(true),
	}


func set_connection(stable_seat_id: String, connected: bool) -> Dictionary:
	if not _pawns.has(stable_seat_id):
		return _rejected("wrong_stable_seat")
	var pawn: PawnState = _pawns[stable_seat_id]
	pawn.connected = connected
	return {"accepted": true, "reason": "", "stable_seat_id": stable_seat_id}


func position_for(stable_seat_id: String) -> String:
	if not _pawns.has(stable_seat_id):
		return BoardState.OUTSIDE_SPACE
	return _state.space_for_seat((_pawns[stable_seat_id] as PawnState).seat_number)


func public_view() -> Dictionary:
	var seats: Array[Dictionary] = []
	for stable_seat_id: String in _stable_seat_order:
		var pawn: PawnState = _pawns[stable_seat_id]
		(
			seats
			. append(
				{
					"stable_seat_id": stable_seat_id,
					"space_id": _state.space_for_seat(pawn.seat_number),
					"connected": pawn.connected,
				}
			)
		)
	return {
		"board_id": _definition.board_id,
		"board_version": _definition.board_version,
		"tide_state": _tide_state,
		"connector_states": _state.get_connector_states(),
		"spaces": _state.companion_public_view().spaces,
		"seats": seats,
	}


func to_snapshot() -> Dictionary:
	var pawns: Array[Dictionary] = []
	for stable_seat_id: String in _stable_seat_order:
		var pawn: PawnState = _pawns[stable_seat_id]
		(
			pawns
			. append(
				{
					"stable_seat_id": stable_seat_id,
					"seat_number": pawn.seat_number,
					"space_id": _state.space_for_seat(pawn.seat_number),
					"connected": pawn.connected,
				}
			)
		)
	return {
		"snapshot_version": SNAPSHOT_VERSION,
		"tide_state": _tide_state,
		"stable_seat_order": _stable_seat_order.duplicate(),
		"pawns": pawns,
		"board_state": _state.to_snapshot(),
	}


func restore_snapshot(snapshot: Dictionary) -> Dictionary:
	if (
		snapshot.keys().size() != 5
		or snapshot.get("snapshot_version") != SNAPSHOT_VERSION
		or not snapshot.get("stable_seat_order") is Array
		or not snapshot.get("pawns") is Array
		or not snapshot.get("board_state") is Dictionary
		or not snapshot.get("tide_state") in ["low_tide", "high_water"]
	):
		return _rejected("malformed_board_snapshot")
	var parsed_pawns: Dictionary = _parse_pawn_rows(snapshot.pawns)
	if not parsed_pawns.get("accepted", false):
		return parsed_pawns
	var next_order: Array[String] = parsed_pawns.order
	var next_pawns: Dictionary = parsed_pawns.pawns
	if Array(snapshot.stable_seat_order) != next_order:
		return _rejected("malformed_board_snapshot")
	var probe := BoardState.new(_definition)
	var state_result: Dictionary = probe.restore_snapshot(snapshot.board_state)
	if not state_result.get("accepted", false):
		return _rejected("malformed_board_snapshot")
	for stable_seat_id: String in next_order:
		var pawn: PawnState = next_pawns[stable_seat_id]
		if probe.space_for_seat(pawn.seat_number) != snapshot.pawns[pawn.seat_number - 1].space_id:
			return _rejected("malformed_board_snapshot")
	_stable_seat_order = next_order
	_pawns = next_pawns
	_state = probe
	_tide_state = snapshot.tide_state
	return {"accepted": true, "reason": ""}


func _parse_pawn_rows(values: Array) -> Dictionary:
	var next_order: Array[String] = []
	var next_pawns: Dictionary = {}
	for row_value: Variant in values:
		if not row_value is Dictionary:
			return _rejected("malformed_board_snapshot")
		var row: Dictionary = row_value
		if (
			row.keys().size() != 4
			or not row.get("stable_seat_id") is String
			or not row.get("seat_number") is int
			or not row.get("space_id") is String
			or not row.get("connected") is bool
			or next_pawns.has(row.get("stable_seat_id"))
			or _definition.get_space(row.get("space_id", "")).is_empty()
		):
			return _rejected("malformed_board_snapshot")
		var pawn := PawnState.new(
			row.seat_number, -1, row.stable_seat_id, _definition.space_center(row.space_id)
		)
		pawn.connected = row.connected
		next_order.append(row.stable_seat_id)
		next_pawns[row.stable_seat_id] = pawn
	return {"accepted": true, "reason": "", "order": next_order, "pawns": next_pawns}


func clear() -> void:
	_pawns.clear()
	_stable_seat_order.clear()
	_state = BoardState.new(_definition)
	_tide_state = "low_tide"


func _sync_occupancy() -> void:
	var pawns: Array[PawnState] = []
	for stable_seat_id: String in _stable_seat_order:
		pawns.append(_pawns[stable_seat_id])
	_state.sync_occupancy(pawns)


static func _rejected(reason: String) -> Dictionary:
	return {"accepted": false, "reason": reason}
