class_name BoardState
extends RefCounted

signal state_changed(change: Dictionary)
signal mutation_rejected(reason: String)

const SNAPSHOT_VERSION: int = 1
const OUTSIDE_SPACE: String = "outside_board"
const HISTORY_LIMIT: int = 64

var definition: BoardDefinition
var revision: int = 0
var last_rejection: String = "—"

var _revealed: Dictionary = {}
var _hazards: Dictionary = {}
var _features: Dictionary = {}
var _blockers: Dictionary = {}
var _connector_states: Dictionary = {}
var _occupancy: Dictionary = {}
var _history: Array[Dictionary] = []

func _init(p_definition: BoardDefinition = null) -> void:
	if p_definition != null:
		initialize(p_definition)

func initialize(p_definition: BoardDefinition) -> PackedStringArray:
	var failures: PackedStringArray = p_definition.validate()
	if not failures.is_empty():
		return failures
	definition = p_definition
	revision = 0
	last_rejection = "—"
	_revealed.clear()
	_hazards.clear()
	_features.clear()
	_blockers.clear()
	_connector_states.clear()
	_occupancy.clear()
	_history.clear()
	for space: Dictionary in definition.spaces:
		var space_id: String = space.id
		_revealed[space_id] = space.get("initial_revealed", false)
		_hazards[space_id] = _sorted_strings(space.get("initial_hazards", []))
		_features[space_id] = _sorted_strings(space.get("initial_features", []))
		_blockers[space_id] = _sorted_strings(space.get("initial_blockers", []))
	for connector: Dictionary in definition.connectors:
		_connector_states[connector.id] = connector.initial_state
	return failures

func get_space_state(space_id: String) -> Dictionary:
	if not _revealed.has(space_id):
		return {}
	return {
		"revealed": _revealed[space_id],
		"hazards": (_hazards[space_id] as Array).duplicate(),
		"features": (_features[space_id] as Array).duplicate(),
		"blockers": (_blockers[space_id] as Array).duplicate(),
		"occupants": occupants_in(space_id),
	}

func get_connector_state(connector_id: String) -> String:
	return _connector_states.get(connector_id, "missing")

func get_connector_states() -> Dictionary:
	return _connector_states.duplicate(true)

func get_occupancy() -> Dictionary:
	return _occupancy.duplicate(true)

func get_history() -> Array[Dictionary]:
	return _history.duplicate(true)

func recent_history(limit: int = 5) -> Array[Dictionary]:
	var start: int = maxi(0, _history.size() - limit)
	return _history.slice(start, _history.size()).duplicate(true)

func occupants_in(space_id: String) -> Array[int]:
	var result: Array[int] = []
	for seat_value: Variant in _occupancy:
		var seat_number: int = seat_value
		if _occupancy[seat_number] == space_id:
			result.append(seat_number)
	result.sort()
	return result

func companion_public_view() -> Dictionary:
	var spaces: Array[Dictionary] = []
	for space: Dictionary in definition.spaces:
		var state: Dictionary = get_space_state(space.get("id", ""))
		spaces.append({
			"id": space.get("id", ""), "label": space.get("label", space.get("id", "").capitalize()),
			"revealed": state.get("revealed", false), "occupants": occupants_in(space.get("id", "")),
			"hazard_count": state.get("hazards", []).size(), "feature_count": state.get("features", []).size(),
		})
	return {"view_version": 1, "revision": revision, "spaces": spaces}

func space_for_seat(seat_number: int) -> String:
	return _occupancy.get(seat_number, OUTSIDE_SPACE)

func space_for_position(world_position: Vector2) -> String:
	if definition == null:
		return OUTSIDE_SPACE
	var candidates: Array[Dictionary] = []
	for space: Dictionary in definition.spaces:
		var total_area: float = 0.0
		var contains: bool = false
		for area_value: Variant in space.areas:
			var area: Rect2 = area_value
			total_area += area.size.x * area.size.y
			if _contains_inclusive(area, world_position):
				contains = true
		if contains:
			candidates.append({"id": space.id, "area": total_area})
	if candidates.is_empty():
		return OUTSIDE_SPACE
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if not is_equal_approx(a.area, b.area):
			return a.area < b.area
		return a.id < b.id
	)
	return candidates[0].id

func sync_occupancy(pawns: Array[PawnState]) -> bool:
	var next_occupancy: Dictionary = {}
	var ordered_pawns: Array[PawnState] = pawns.duplicate()
	ordered_pawns.sort_custom(func(a: PawnState, b: PawnState) -> bool: return a.seat_number < b.seat_number)
	for pawn: PawnState in ordered_pawns:
		next_occupancy[pawn.seat_number] = space_for_position(pawn.position)
	if next_occupancy == _occupancy:
		return false
	var changes: Array[Dictionary] = []
	var all_seats: Array[int] = []
	for seat_value: Variant in _occupancy:
		all_seats.append(seat_value)
	for seat_value: Variant in next_occupancy:
		if not all_seats.has(seat_value):
			all_seats.append(seat_value)
	all_seats.sort()
	for seat_number: int in all_seats:
		var previous: String = _occupancy.get(seat_number, OUTSIDE_SPACE)
		var current: String = next_occupancy.get(seat_number, OUTSIDE_SPACE)
		if previous != current:
			changes.append({"seat_number": seat_number, "from": previous, "to": current})
	_occupancy = next_occupancy
	_commit("occupancy_update", {"changes": changes}, _occupancy_summary(changes))
	return true

func directly_connected(from_space: String, to_space: String, traversable_only: bool = false) -> bool:
	for connector: Dictionary in definition.connectors:
		var direction_matches: bool = connector.from == from_space and connector.to == to_space
		var reverse_matches: bool = not connector.get("one_way", false) and connector.from == to_space and connector.to == from_space
		if direction_matches or reverse_matches:
			if not traversable_only or is_connector_traversable(connector.id, from_space, to_space):
				return true
	return false

func is_connector_traversable(connector_id: String, from_space: String = "", to_space: String = "") -> bool:
	var connector: Dictionary = definition.get_connector(connector_id)
	if connector.is_empty() or _connector_states.get(connector_id, "missing") != "open":
		return false
	if from_space.is_empty() and to_space.is_empty():
		return true
	if connector.from == from_space and connector.to == to_space:
		return true
	return not connector.get("one_way", false) and connector.from == to_space and connector.to == from_space

func reachable_spaces(start_space: String) -> PackedStringArray:
	var result := PackedStringArray()
	if definition.get_space(start_space).is_empty():
		return result
	var visited: Dictionary = {start_space: true}
	var queue: Array[String] = [start_space]
	while not queue.is_empty():
		var current: String = queue.pop_front()
		for neighbor: String in _traversable_neighbors(current):
			if not visited.has(neighbor):
				visited[neighbor] = true
				queue.append(neighbor)
	for space_id: Variant in visited:
		result.append(space_id)
	result.sort()
	return result

func shortest_path(from_space: String, to_space: String) -> PackedStringArray:
	var empty := PackedStringArray()
	if definition.get_space(from_space).is_empty() or definition.get_space(to_space).is_empty():
		return empty
	var queue: Array[String] = [from_space]
	var previous: Dictionary = {from_space: ""}
	while not queue.is_empty():
		var current: String = queue.pop_front()
		if current == to_space:
			break
		for neighbor: String in _traversable_neighbors(current):
			if not previous.has(neighbor):
				previous[neighbor] = current
				queue.append(neighbor)
	if not previous.has(to_space):
		return empty
	var reverse_path := PackedStringArray()
	var cursor: String = to_space
	while not cursor.is_empty():
		reverse_path.append(cursor)
		cursor = previous[cursor]
	var path := PackedStringArray()
	for index: int in range(reverse_path.size() - 1, -1, -1):
		path.append(reverse_path[index])
	return path

func crossing_is_blocked(from_space: String, to_space: String) -> bool:
	return directly_connected(from_space, to_space, false) and not directly_connected(from_space, to_space, true)

func mutation_disconnects_required(mutation: Dictionary) -> bool:
	if mutation.get("type", "") != BoardMutation.SET_CONNECTOR_STATE:
		return false
	var connector_id: String = mutation.get("connector_id", "")
	var proposed_state: String = mutation.get("state", "")
	if not _connector_states.has(connector_id) or not BoardDefinition.VALID_CONNECTOR_STATES.has(proposed_state):
		return false
	var previous_state: String = _connector_states[connector_id]
	_connector_states[connector_id] = proposed_state
	var disconnected: bool = false
	if not definition.required_space_ids.is_empty():
		var reachable: PackedStringArray = reachable_spaces(definition.required_space_ids[0])
		for required_id: String in definition.required_space_ids:
			if not reachable.has(required_id):
				disconnected = true
				break
	_connector_states[connector_id] = previous_state
	return disconnected

func apply_mutation(mutation: Dictionary, actor_seat: int = 0) -> Dictionary:
	var validation: Dictionary = _validate_mutation(mutation)
	if not validation.valid:
		return _reject(validation.reason)
	var mutation_type: String = mutation.type
	var no_change: bool = false
	match mutation_type:
		BoardMutation.REVEAL_SPACE:
			no_change = _revealed[mutation.space_id] == mutation.revealed
		BoardMutation.SET_CONNECTOR_STATE:
			no_change = _connector_states[mutation.connector_id] == mutation.state
		BoardMutation.SET_HAZARD:
			no_change = _collection_has(_hazards[mutation.space_id], mutation.value_id) == mutation.active
		BoardMutation.SET_FEATURE:
			no_change = _collection_has(_features[mutation.space_id], mutation.value_id) == mutation.active
		BoardMutation.SET_BLOCKER:
			no_change = _collection_has(_blockers[mutation.space_id], mutation.value_id) == mutation.active
	if no_change:
		return _reject("no_change")
	match mutation_type:
		BoardMutation.REVEAL_SPACE:
			_revealed[mutation.space_id] = mutation.revealed
		BoardMutation.SET_CONNECTOR_STATE:
			_connector_states[mutation.connector_id] = mutation.state
		BoardMutation.SET_HAZARD:
			_set_collection_value(_hazards, mutation.space_id, mutation.value_id, mutation.active)
		BoardMutation.SET_FEATURE:
			_set_collection_value(_features, mutation.space_id, mutation.value_id, mutation.active)
		BoardMutation.SET_BLOCKER:
			_set_collection_value(_blockers, mutation.space_id, mutation.value_id, mutation.active)
	var payload: Dictionary = mutation.duplicate(true)
	payload["actor_seat"] = actor_seat
	_commit(mutation_type, payload, _mutation_summary(mutation, actor_seat))
	return {"accepted": true, "changed": true, "reason": "", "revision": revision}

func apply_mutation_requests(requests: Array[Dictionary]) -> Array[Dictionary]:
	var ordered: Array[Dictionary] = requests.duplicate(true)
	ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_seat: int = a.get("seat_number", 0)
		var b_seat: int = b.get("seat_number", 0)
		if a_seat != b_seat:
			return a_seat < b_seat
		return BoardMutation.signature(a.get("mutation", {})) < BoardMutation.signature(b.get("mutation", {}))
	)
	var claimed: Dictionary = {}
	var results: Array[Dictionary] = []
	for request: Dictionary in ordered:
		var mutation: Dictionary = request.get("mutation", {})
		var key: String = BoardMutation.conflict_key(mutation)
		var result: Dictionary
		if claimed.has(key):
			result = _reject("conflict_won_by_seat_%d" % claimed[key], false)
		else:
			claimed[key] = request.get("seat_number", 0)
			result = apply_mutation(mutation, request.get("seat_number", 0))
		result["seat_number"] = request.get("seat_number", 0)
		result["conflict_key"] = key
		results.append(result)
	return results

func to_snapshot() -> Dictionary:
	var occupancy_rows: Array[Dictionary] = []
	var seats: Array[int] = []
	for seat_value: Variant in _occupancy:
		seats.append(seat_value)
	seats.sort()
	for seat_number: int in seats:
		occupancy_rows.append({"seat_number": seat_number, "space_id": _occupancy[seat_number]})
	return {
		"snapshot_version": SNAPSHOT_VERSION,
		"board_id": definition.board_id,
		"board_version": definition.board_version,
		"revision": revision,
		"revealed": _revealed.duplicate(true),
		"hazards": _hazards.duplicate(true),
		"features": _features.duplicate(true),
		"blockers": _blockers.duplicate(true),
		"connectors": _connector_states.duplicate(true),
		"occupancy": occupancy_rows,
		"history": _history.duplicate(true),
	}

func restore_snapshot(snapshot: Dictionary) -> Dictionary:
	var parsed: Dictionary = _parse_snapshot(snapshot)
	if not parsed.valid:
		return _reject(parsed.reason)
	_revealed = parsed.revealed
	_hazards = parsed.hazards
	_features = parsed.features
	_blockers = parsed.blockers
	_connector_states = parsed.connectors
	_occupancy = parsed.occupancy
	revision = parsed.revision
	_history = parsed.history
	last_rejection = "—"
	state_changed.emit({"type": "snapshot_restored", "revision": revision})
	return {"accepted": true, "changed": true, "reason": "", "revision": revision}

func _validate_mutation(mutation: Dictionary) -> Dictionary:
	var mutation_type: Variant = mutation.get("type")
	if not mutation_type is String or not BoardMutation.VALID_TYPES.has(mutation_type):
		return {"valid": false, "reason": "unsupported_mutation_type"}
	match mutation_type:
		BoardMutation.REVEAL_SPACE:
			if not _revealed.has(mutation.get("space_id", "")) or not mutation.get("revealed") is bool:
				return {"valid": false, "reason": "malformed_reveal_mutation"}
		BoardMutation.SET_CONNECTOR_STATE:
			if not _connector_states.has(mutation.get("connector_id", "")) or not BoardDefinition.VALID_CONNECTOR_STATES.has(mutation.get("state", "")):
				return {"valid": false, "reason": "malformed_connector_mutation"}
		BoardMutation.SET_HAZARD, BoardMutation.SET_FEATURE, BoardMutation.SET_BLOCKER:
			if not _revealed.has(mutation.get("space_id", "")) or not _valid_value_id(mutation.get("value_id")) or not mutation.get("active") is bool:
				return {"valid": false, "reason": "malformed_space_value_mutation"}
	return {"valid": true, "reason": ""}

func _parse_snapshot(snapshot: Dictionary) -> Dictionary:
	if snapshot.get("snapshot_version", -1) != SNAPSHOT_VERSION:
		return {"valid": false, "reason": "unsupported_snapshot_version"}
	if snapshot.get("board_id", "") != definition.board_id or snapshot.get("board_version", -1) != definition.board_version:
		return {"valid": false, "reason": "snapshot_board_mismatch"}
	if not snapshot.get("revision") is int or snapshot.revision < 0:
		return {"valid": false, "reason": "malformed_snapshot_revision"}
	var parsed: Dictionary = {"valid": true, "reason": "", "revision": snapshot.revision}
	for key: String in ["revealed", "hazards", "features", "blockers", "connectors"]:
		if not snapshot.get(key) is Dictionary:
			return {"valid": false, "reason": "malformed_snapshot_%s" % key}
	var revealed: Dictionary = snapshot.revealed.duplicate(true)
	var hazards: Dictionary = snapshot.hazards.duplicate(true)
	var features: Dictionary = snapshot.features.duplicate(true)
	var blockers: Dictionary = snapshot.blockers.duplicate(true)
	var expected_spaces: PackedStringArray = definition.space_ids()
	for store: Dictionary in [revealed, hazards, features, blockers]:
		for stored_space: Variant in store:
			if not stored_space is String or not expected_spaces.has(stored_space):
				return {"valid": false, "reason": "malformed_snapshot_space_values"}
	for space_id: String in expected_spaces:
		if not revealed.has(space_id) or not revealed[space_id] is bool:
			return {"valid": false, "reason": "malformed_snapshot_revealed"}
		for collection: Dictionary in [hazards, features, blockers]:
			if not collection.has(space_id) or not _valid_string_array(collection[space_id]):
				return {"valid": false, "reason": "malformed_snapshot_space_values"}
	var connectors: Dictionary = snapshot.connectors.duplicate(true)
	var expected_connectors: PackedStringArray = definition.connector_ids()
	for stored_connector: Variant in connectors:
		if not stored_connector is String or not expected_connectors.has(stored_connector):
			return {"valid": false, "reason": "malformed_snapshot_connectors"}
	for connector_id: String in expected_connectors:
		if not connectors.has(connector_id) or not BoardDefinition.VALID_CONNECTOR_STATES.has(connectors[connector_id]):
			return {"valid": false, "reason": "malformed_snapshot_connectors"}
	if not snapshot.get("occupancy") is Array:
		return {"valid": false, "reason": "malformed_snapshot_occupancy"}
	var occupancy: Dictionary = {}
	for row_value: Variant in snapshot.occupancy:
		if not row_value is Dictionary:
			return {"valid": false, "reason": "malformed_snapshot_occupancy"}
		var row: Dictionary = row_value
		if not row.get("seat_number") is int or row.seat_number < 1 or row.seat_number > SeatManager.MAX_SEATS or occupancy.has(row.seat_number):
			return {"valid": false, "reason": "malformed_snapshot_occupancy"}
		var space_id: String = row.get("space_id", "")
		if space_id != OUTSIDE_SPACE and definition.get_space(space_id).is_empty():
			return {"valid": false, "reason": "malformed_snapshot_occupancy"}
		occupancy[row.seat_number] = space_id
	if not snapshot.get("history") is Array:
		return {"valid": false, "reason": "malformed_snapshot_history"}
	var history: Array[Dictionary] = []
	var previous_history_revision: int = -1
	for entry_value: Variant in snapshot.history:
		if not entry_value is Dictionary or not entry_value.get("revision") is int or not entry_value.get("type") is String:
			return {"valid": false, "reason": "malformed_snapshot_history"}
		if entry_value.revision <= previous_history_revision or entry_value.revision > snapshot.revision:
			return {"valid": false, "reason": "malformed_snapshot_history"}
		previous_history_revision = entry_value.revision
		history.append((entry_value as Dictionary).duplicate(true))
	parsed.merge({"revealed": revealed, "hazards": hazards, "features": features, "blockers": blockers, "connectors": connectors, "occupancy": occupancy, "history": history})
	return parsed

func _traversable_neighbors(space_id: String) -> PackedStringArray:
	var neighbors := PackedStringArray()
	for connector: Dictionary in definition.connectors:
		if connector.from == space_id and is_connector_traversable(connector.id, connector.from, connector.to):
			neighbors.append(connector.to)
		if connector.to == space_id and is_connector_traversable(connector.id, connector.to, connector.from):
			neighbors.append(connector.from)
	neighbors.sort()
	return neighbors

func _commit(type: String, payload: Dictionary, summary: String) -> void:
	revision += 1
	var entry: Dictionary = {"revision": revision, "type": type, "summary": summary, "payload": payload.duplicate(true)}
	_history.append(entry)
	if _history.size() > HISTORY_LIMIT:
		_history.pop_front()
	last_rejection = "—"
	state_changed.emit(entry.duplicate(true))

func _reject(reason: String, emit_signal: bool = true) -> Dictionary:
	last_rejection = reason
	if emit_signal:
		mutation_rejected.emit(reason)
	return {"accepted": false, "changed": false, "reason": reason, "revision": revision}

func _set_collection_value(store: Dictionary, space_id: String, value_id: String, active: bool) -> void:
	var values: Array = (store[space_id] as Array).duplicate()
	if active and not values.has(value_id):
		values.append(value_id)
	elif not active:
		values.erase(value_id)
	values.sort()
	store[space_id] = values

func _collection_has(values: Array, value_id: String) -> bool:
	return values.has(value_id)

func _contains_inclusive(area: Rect2, point: Vector2) -> bool:
	return point.x >= area.position.x and point.y >= area.position.y and point.x <= area.end.x and point.y <= area.end.y

func _sorted_strings(values: Variant) -> Array[String]:
	var result: Array[String] = []
	for value: Variant in values:
		result.append(value)
	result.sort()
	return result

func _valid_string_array(values: Variant) -> bool:
	if not values is Array:
		return false
	for value: Variant in values:
		if not value is String or not _valid_value_id(value):
			return false
	return true

func _valid_value_id(value: Variant) -> bool:
	return value is String and not String(value).is_empty() and String(value) == String(value).to_lower() and String(value).is_valid_identifier()

func _mutation_summary(mutation: Dictionary, actor_seat: int) -> String:
	var actor: String = "system" if actor_seat <= 0 else "seat_%d" % actor_seat
	match mutation.type:
		BoardMutation.REVEAL_SPACE:
			return "%s %s %s" % [actor, "revealed" if mutation.revealed else "hid", mutation.space_id]
		BoardMutation.SET_CONNECTOR_STATE:
			return "%s set %s %s" % [actor, mutation.connector_id, mutation.state]
		BoardMutation.SET_HAZARD, BoardMutation.SET_FEATURE, BoardMutation.SET_BLOCKER:
			return "%s %s %s/%s" % [actor, "activated" if mutation.active else "cleared", mutation.space_id, mutation.value_id]
	return "%s mutation" % actor

func _occupancy_summary(changes: Array[Dictionary]) -> String:
	var parts := PackedStringArray()
	for change: Dictionary in changes:
		parts.append("seat_%d:%s>%s" % [change.seat_number, change.from, change.to])
	return "occupancy " + ",".join(parts)
