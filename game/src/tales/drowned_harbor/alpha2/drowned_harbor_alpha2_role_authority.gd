class_name DrownedHarborAlpha2RoleAuthority
extends RefCounted

const SNAPSHOT_VERSION: int = 2
const PRIVACY_CLASSES: PackedStringArray = [
	"public", "controlled_reveal_private", "seat_private", "faction_private"
]

var _seat_order: Array[String] = []
var _seat_states: Dictionary = {}
var _attribution_resolved: bool = false


func _init(stable_seat_ids: PackedStringArray = PackedStringArray()) -> void:
	for stable_seat_id: String in stable_seat_ids:
		_seat_order.append(stable_seat_id)
		_seat_states[stable_seat_id] = {
			"stable_seat_id": stable_seat_id,
			"connected": true,
			"control_source": "local_human",
			"public_form": "harbor_arrival",
			"private_objective": "PRIVATE_ALPHA2_OBJECTIVE_%s" % stable_seat_id,
			"private_faction": "PRIVATE_ALPHA2_FACTION_%s" % stable_seat_id,
			"private_ending_attribution": "",
		}


func set_connection(
	stable_seat_id: String, connected: bool, surrogate_control: bool = false
) -> Dictionary:
	if not _seat_states.has(stable_seat_id):
		return _rejected("wrong_stable_seat")
	var state: Dictionary = _seat_states[stable_seat_id]
	state.connected = connected
	state.control_source = "surrogate_local" if surrogate_control else "local_human"
	return {"accepted": true, "reason": ""}


func set_public_form(stable_seat_id: String, public_form: String) -> Dictionary:
	if not _seat_states.has(stable_seat_id):
		return _rejected("wrong_stable_seat")
	_seat_states[stable_seat_id].public_form = public_form
	return {"accepted": true, "reason": ""}


func apply_high_water_forms() -> Dictionary:
	for stable_seat_id: String in _seat_order:
		_seat_states[stable_seat_id].public_form = "high_water_survivor"
	return {"accepted": true, "reason": ""}


func resolve_epilogue(ending_id: String) -> Dictionary:
	if _attribution_resolved:
		return _rejected("epilogue_already_resolved")
	for stable_seat_id: String in _seat_order:
		_seat_states[stable_seat_id].private_ending_attribution = (
			"PRIVATE_ALPHA2_ATTRIBUTION_%s_%s" % [stable_seat_id, ending_id]
		)
	_attribution_resolved = true
	return {
		"accepted": true,
		"reason": "",
		"public_epilogue": "The crew completed the cooperative harbor route.",
	}


func public_view() -> Dictionary:
	var seats: Array[Dictionary] = []
	for stable_seat_id: String in _seat_order:
		var state: Dictionary = _seat_states[stable_seat_id]
		(
			seats
			. append(
				{
					"stable_seat_id": stable_seat_id,
					"connected": state.connected,
					"control_source": state.control_source,
					"public_form": state.public_form,
				}
			)
		)
	return {
		"classification": "public",
		"privacy_classes": Array(PRIVACY_CLASSES),
		"seats": seats,
		"epilogue_attribution_resolved": _attribution_resolved,
	}


func seat_private_view(stable_seat_id: String) -> Dictionary:
	if not _seat_states.has(stable_seat_id):
		return {}
	var state: Dictionary = _seat_states[stable_seat_id]
	return {
		"classification": "seat_private",
		"stable_seat_id": stable_seat_id,
		"private_objective": state.private_objective,
		"private_ending_attribution": state.private_ending_attribution,
	}


func to_snapshot() -> Dictionary:
	var seats: Array[Dictionary] = []
	for stable_seat_id: String in _seat_order:
		seats.append((_seat_states[stable_seat_id] as Dictionary).duplicate(true))
	return {
		"snapshot_version": SNAPSHOT_VERSION,
		"privacy_classes": Array(PRIVACY_CLASSES),
		"seat_order": _seat_order.duplicate(),
		"seat_states": seats,
		"attribution_resolved": _attribution_resolved,
	}


func restore_snapshot(snapshot: Dictionary) -> Dictionary:
	if (
		snapshot.keys().size() != 5
		or snapshot.get("snapshot_version") != SNAPSHOT_VERSION
		or snapshot.get("privacy_classes") != Array(PRIVACY_CLASSES)
		or not snapshot.get("seat_order") is Array
		or not snapshot.get("seat_states") is Array
		or not snapshot.get("attribution_resolved") is bool
	):
		return _rejected("malformed_role_snapshot")
	var next_order: Array[String] = []
	var next_states: Dictionary = {}
	for row_value: Variant in snapshot.seat_states:
		if not row_value is Dictionary:
			return _rejected("malformed_role_snapshot")
		var row: Dictionary = row_value
		var stable_seat_id: Variant = row.get("stable_seat_id")
		if (
			row.keys().size() != 7
			or not stable_seat_id is String
			or next_states.has(stable_seat_id)
			or not row.get("connected") is bool
			or not row.get("control_source") in ["local_human", "surrogate_local"]
			or not row.get("public_form") is String
			or not row.get("private_objective") is String
			or not row.get("private_faction") is String
			or not row.get("private_ending_attribution") is String
		):
			return _rejected("malformed_role_snapshot")
		next_order.append(stable_seat_id)
		next_states[stable_seat_id] = row.duplicate(true)
	if Array(snapshot.seat_order) != next_order:
		return _rejected("malformed_role_snapshot")
	_seat_order = next_order
	_seat_states = next_states
	_attribution_resolved = snapshot.attribution_resolved
	return {"accepted": true, "reason": ""}


func clear() -> void:
	_seat_order.clear()
	_seat_states.clear()
	_attribution_resolved = false


static func _rejected(reason: String) -> Dictionary:
	return {"accepted": false, "reason": reason}
