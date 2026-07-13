class_name BoardDefinition
extends Resource

const VALID_CONNECTOR_STATES: PackedStringArray = ["open", "closed", "locked", "collapsed"]
const VALID_CONNECTOR_TYPES: PackedStringArray = ["open_passage", "door", "locked_door", "collapsed_route", "one_way", "scenario_link"]

var board_id: String = ""
var board_version: int = 1
var spaces: Array[Dictionary] = []
var connectors: Array[Dictionary] = []
var required_space_ids: PackedStringArray = []

func validate() -> PackedStringArray:
	var failures := PackedStringArray()
	if not _valid_id(board_id):
		failures.append("board_id must be a lowercase stable identifier")
	if board_version < 1:
		failures.append("board_version must be positive")
	var space_ids: Dictionary = {}
	for space: Dictionary in spaces:
		_validate_space(space, space_ids, failures)
	var connector_ids: Dictionary = {}
	for connector: Dictionary in connectors:
		_validate_connector(connector, space_ids, connector_ids, failures)
	for required_id: String in required_space_ids:
		if not space_ids.has(required_id):
			failures.append("required space '%s' is missing" % required_id)
	if failures.is_empty():
		_validate_required_reachability(space_ids, failures)
	return failures

func get_space(space_id: String) -> Dictionary:
	for space: Dictionary in spaces:
		if space.get("id", "") == space_id:
			return space.duplicate(true)
	return {}

func get_connector(connector_id: String) -> Dictionary:
	for connector: Dictionary in connectors:
		if connector.get("id", "") == connector_id:
			return connector.duplicate(true)
	return {}

func space_ids() -> PackedStringArray:
	var result := PackedStringArray()
	for space: Dictionary in spaces:
		result.append(space.id)
	result.sort()
	return result

func connector_ids() -> PackedStringArray:
	var result := PackedStringArray()
	for connector: Dictionary in connectors:
		result.append(connector.id)
	result.sort()
	return result

func space_center(space_id: String) -> Vector2:
	var space: Dictionary = get_space(space_id)
	if space.is_empty():
		return Vector2.ZERO
	var areas: Array = space.areas
	var weighted_center := Vector2.ZERO
	var total_area: float = 0.0
	for area_value: Variant in areas:
		var area: Rect2 = area_value
		var weight: float = area.size.x * area.size.y
		weighted_center += area.get_center() * weight
		total_area += weight
	return weighted_center / total_area if total_area > 0.0 else Vector2.ZERO

func _validate_space(space: Dictionary, seen: Dictionary, failures: PackedStringArray) -> void:
	var space_id: Variant = space.get("id")
	if not _valid_id(space_id):
		failures.append("space has malformed id")
		return
	if seen.has(space_id):
		failures.append("duplicate space id '%s'" % space_id)
		return
	seen[space_id] = true
	if not space.get("name") is String or String(space.get("name")).strip_edges().is_empty():
		failures.append("space '%s' has no display name" % space_id)
	if not _valid_id(space.get("type")):
		failures.append("space '%s' has malformed type" % space_id)
	var areas_value: Variant = space.get("areas")
	if not areas_value is Array or (areas_value as Array).is_empty():
		failures.append("space '%s' has no geometry" % space_id)
	else:
		for area_value: Variant in areas_value:
			if typeof(area_value) != TYPE_RECT2:
				failures.append("space '%s' has non-Rect2 geometry" % space_id)
				continue
			var area: Rect2 = area_value
			if area.size.x <= 0.0 or area.size.y <= 0.0:
				failures.append("space '%s' has invalid geometry" % space_id)
	for key: String in ["tags", "initial_hazards", "initial_features", "initial_blockers"]:
		if not _is_string_collection(space.get(key, [])):
			failures.append("space '%s' has malformed %s" % [space_id, key])
	if not space.get("initial_revealed", false) is bool:
		failures.append("space '%s' has malformed reveal state" % space_id)
	if space.has("label_position") and typeof(space.label_position) != TYPE_VECTOR2:
		failures.append("space '%s' has malformed label position" % space_id)

func _validate_connector(connector: Dictionary, space_ids: Dictionary, seen: Dictionary, failures: PackedStringArray) -> void:
	var connector_id: Variant = connector.get("id")
	if not _valid_id(connector_id):
		failures.append("connector has malformed id")
		return
	if seen.has(connector_id):
		failures.append("duplicate connector id '%s'" % connector_id)
		return
	seen[connector_id] = true
	var from_id: String = connector.get("from", "")
	var to_id: String = connector.get("to", "")
	if from_id == to_id:
		failures.append("connector '%s' links a space to itself" % connector_id)
	if not space_ids.has(from_id):
		failures.append("connector '%s' has missing endpoint '%s'" % [connector_id, from_id])
	if not space_ids.has(to_id):
		failures.append("connector '%s' has missing endpoint '%s'" % [connector_id, to_id])
	if not VALID_CONNECTOR_TYPES.has(connector.get("type", "")):
		failures.append("connector '%s' has invalid type" % connector_id)
	if not VALID_CONNECTOR_STATES.has(connector.get("initial_state", "")):
		failures.append("connector '%s' has invalid initial state" % connector_id)
	if not connector.get("one_way", false) is bool:
		failures.append("connector '%s' has malformed direction state" % connector_id)

func _validate_required_reachability(space_ids: Dictionary, failures: PackedStringArray) -> void:
	if required_space_ids.size() < 2:
		return
	var visited: Dictionary = {required_space_ids[0]: true}
	var queue: Array[String] = [required_space_ids[0]]
	while not queue.is_empty():
		var current: String = queue.pop_front()
		var neighbors := PackedStringArray()
		for connector: Dictionary in connectors:
			if connector.from == current:
				neighbors.append(connector.to)
			if connector.to == current and not connector.get("one_way", false):
				neighbors.append(connector.from)
		neighbors.sort()
		for neighbor: String in neighbors:
			if space_ids.has(neighbor) and not visited.has(neighbor):
				visited[neighbor] = true
				queue.append(neighbor)
	for required_id: String in required_space_ids:
		if not visited.has(required_id):
			failures.append("required space '%s' is unreachable in authored topology" % required_id)

func _valid_id(value: Variant) -> bool:
	if not value is String:
		return false
	var text: String = value
	return not text.is_empty() and text == text.to_lower() and text.is_valid_identifier()

func _is_string_collection(value: Variant) -> bool:
	if not value is Array and not value is PackedStringArray:
		return false
	for entry: Variant in value:
		if not entry is String or String(entry).is_empty():
			return false
	return true
