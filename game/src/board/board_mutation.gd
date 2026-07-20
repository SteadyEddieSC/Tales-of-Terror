class_name BoardMutation
extends RefCounted

const REVEAL_SPACE: String = "reveal_space"
const SET_CONNECTOR_STATE: String = "set_connector_state"
const SET_HAZARD: String = "set_hazard"
const SET_FEATURE: String = "set_feature"
const SET_BLOCKER: String = "set_blocker"
const VALID_TYPES: PackedStringArray = [
	REVEAL_SPACE, SET_CONNECTOR_STATE, SET_HAZARD, SET_FEATURE, SET_BLOCKER
]


class StateContract:
	extends RefCounted

	func get_history() -> Array[Dictionary]:
		return _contract_get_history()

	func recent_history(limit: int = 5) -> Array[Dictionary]:
		return _contract_recent_history(limit)

	func _contract_get_history() -> Array[Dictionary]:
		return []

	func _contract_recent_history(_limit: int = 5) -> Array[Dictionary]:
		return []


static func reveal_space(space_id: String, revealed: bool = true) -> Dictionary:
	return {"type": REVEAL_SPACE, "space_id": space_id, "revealed": revealed}


static func connector(connector_id: String, state: String) -> Dictionary:
	return {"type": SET_CONNECTOR_STATE, "connector_id": connector_id, "state": state}


static func hazard(space_id: String, hazard_id: String, active: bool) -> Dictionary:
	return {"type": SET_HAZARD, "space_id": space_id, "value_id": hazard_id, "active": active}


static func feature(space_id: String, feature_id: String, active: bool) -> Dictionary:
	return {"type": SET_FEATURE, "space_id": space_id, "value_id": feature_id, "active": active}


static func blocker(space_id: String, blocker_id: String, active: bool) -> Dictionary:
	return {"type": SET_BLOCKER, "space_id": space_id, "value_id": blocker_id, "active": active}


static func conflict_key(mutation: Dictionary) -> String:
	match mutation.get("type", ""):
		SET_CONNECTOR_STATE:
			return "connector:%s" % mutation.get("connector_id", "")
		REVEAL_SPACE:
			return "reveal:%s" % mutation.get("space_id", "")
		SET_HAZARD, SET_FEATURE, SET_BLOCKER:
			return (
				"%s:%s:%s"
				% [
					mutation.get("type", ""),
					mutation.get("space_id", ""),
					mutation.get("value_id", "")
				]
			)
		_:
			return "invalid:%s" % JSON.stringify(mutation)


static func signature(mutation: Dictionary) -> String:
	var keys: Array = mutation.keys()
	keys.sort()
	var parts := PackedStringArray()
	for key: Variant in keys:
		parts.append("%s=%s" % [key, mutation[key]])
	return "|".join(parts)
