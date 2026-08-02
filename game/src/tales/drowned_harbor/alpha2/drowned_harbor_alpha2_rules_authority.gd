class_name DrownedHarborAlpha2RulesAuthority
extends RefCounted

const SNAPSHOT_VERSION: int = 2
const STAGE_ORDER: PackedStringArray = [
	"low_tide_arrival_v1",
	"bellhouse_ledger_v1",
	"lighthouse_council_v1",
	"high_water_v1",
	"last_light_v1",
	"ending_resolution_v1",
	"epilogue_attribution_v1",
	"rematch_title_cleanup_v1",
]
const TRANSITION_ORDER: PackedStringArray = [
	"transition_low_tide_to_bellhouse",
	"transition_bellhouse_to_council",
	"transition_council_to_high_water",
	"transition_high_water_to_last_light",
	"transition_last_light_to_ending",
	"transition_ending_to_epilogue",
	"transition_epilogue_to_cleanup",
]
const EVENT_KEYS: PackedStringArray = [
	"low_tide_arrival_completed",
	"bellhouse_choice_committed",
	"council_resolved",
	"high_water_transformation_applied",
	"last_light_resolved",
	"ending_resolved",
	"epilogue_acknowledged",
	"drowned_harbor_session_cleared",
]
const INTENTS_BY_STAGE: Dictionary = {
	"low_tide_arrival_v1": ["move_to_landmark", "confirm_low_tide_arrival"],
	"bellhouse_ledger_v1":
	["inspect_ledger", "commit_bellhouse_choice", "recover_bellhouse_choice"],
	"lighthouse_council_v1": ["submit_council_commitment", "resolve_council_commitment"],
	"high_water_v1": ["acknowledge_high_water", "apply_high_water_transformation"],
	"last_light_v1": ["move_to_last_light_route", "commit_last_light_action", "resolve_last_light"],
	"ending_resolution_v1": ["resolve_ending"],
	"epilogue_attribution_v1": ["resolve_epilogue_attribution", "acknowledge_epilogue"],
	"rematch_title_cleanup_v1": ["request_rematch", "return_to_title"],
}

var _stage_index: int = 0
var _stage_state: Dictionary = {}
var _transition_history: Array[Dictionary] = []
var _public_history: Array[Dictionary] = []
var _council_commitment_id: String = ""
var _high_water_transformation_id: String = ""
var _ending_id: String = ""
var _accepted_action_count: int = 0


func _init() -> void:
	_stage_state = _new_stage_state(STAGE_ORDER[0])


func stage_id() -> String:
	return STAGE_ORDER[_stage_index]


func accepted_action_count() -> int:
	return _accepted_action_count


func council_commitment_id() -> String:
	return _council_commitment_id


func high_water_transformation_id() -> String:
	return _high_water_transformation_id


func public_history() -> Array[Dictionary]:
	return _public_history.duplicate(true)


func transition_history() -> Array[Dictionary]:
	return _transition_history.duplicate(true)


func legal_intents() -> PackedStringArray:
	return PackedStringArray(INTENTS_BY_STAGE[stage_id()])


func apply_intent(
	request: Dictionary,
	stable_seat_order: Array[String],
	connected_seats: Array[String],
	board: DrownedHarborAlpha2BoardAuthority,
	role: DrownedHarborAlpha2RoleAuthority,
	seed: int,
	revision: int
) -> Dictionary:
	if not legal_intents().has(request.intent):
		return _rejected("unsupported_intent_for_stage")
	if _accepted_action_count >= 96:
		return _rejected("accepted_action_bound_exceeded")
	var result: Dictionary
	match stage_id():
		"low_tide_arrival_v1":
			result = _apply_low_tide(request, stable_seat_order, connected_seats, board)
		"bellhouse_ledger_v1":
			result = _apply_bellhouse(request, connected_seats)
		"lighthouse_council_v1":
			result = _apply_council(request, stable_seat_order, connected_seats, seed, revision)
		"high_water_v1":
			result = _apply_high_water(request, connected_seats, board, role, seed, revision)
		"last_light_v1":
			result = _apply_last_light(request, stable_seat_order, connected_seats, board)
		"ending_resolution_v1":
			result = _apply_ending(request, connected_seats)
		"epilogue_attribution_v1":
			result = _apply_epilogue(request, connected_seats, role)
		_:
			result = _rejected("cleanup_owned_by_session_coordinator")
	if result.get("accepted", false):
		_accepted_action_count += 1
	return result


func advance_cleanup_transition(revision: int) -> Dictionary:
	if stage_id() != "epilogue_attribution_v1" or not _stage_state.get("acknowledged", false):
		return _rejected("epilogue_not_complete")
	return _complete_stage("epilogue_acknowledged", revision)


func complete_cleanup(next_destination: String, revision: int) -> Dictionary:
	if stage_id() != "rematch_title_cleanup_v1":
		return _rejected("cleanup_stage_unavailable")
	if _stage_state.cleanup_complete:
		return _rejected("cleanup_already_complete")
	if not next_destination in ["rematch", "normal_title"]:
		return _rejected("unsupported_cleanup_destination")
	_stage_state.cleanup_complete = true
	_stage_state.next_destination = next_destination
	_accepted_action_count += 1
	var event: Dictionary = {
		"event_key": "drowned_harbor_session_cleared",
		"revision": revision,
		"stage_id": stage_id(),
		"next_destination": next_destination,
	}
	_public_history.append(event.duplicate(true))
	return {"accepted": true, "reason": "", "public_event": event}


func _apply_low_tide(
	request: Dictionary,
	stable_seat_order: Array[String],
	connected_seats: Array[String],
	board: DrownedHarborAlpha2BoardAuthority
) -> Dictionary:
	if request.intent == "move_to_landmark":
		return _apply_low_tide_movement(request, board)
	if not _is_owner(request.stable_seat_id, connected_seats):
		return _rejected("wrong_action_owner")
	if _stage_state.moved_seats.size() != stable_seat_order.size():
		return _rejected("arrival_incomplete")
	return _complete_stage("low_tide_arrival_completed", request.source_revision + 1)


func _apply_low_tide_movement(
	request: Dictionary, board: DrownedHarborAlpha2BoardAuthority
) -> Dictionary:
	if request.payload != {"destination": "bellhouse"}:
		return _rejected("malformed_movement_request")
	if _stage_state.moved_seats.has(request.stable_seat_id):
		return _rejected("movement_already_completed")
	var moved: Dictionary = board.move_to(request.stable_seat_id, "bellhouse")
	if not moved.get("accepted", false):
		return moved
	_stage_state.moved_seats.append(request.stable_seat_id)
	return _accepted()


func _apply_bellhouse(request: Dictionary, connected_seats: Array[String]) -> Dictionary:
	if not _is_owner(request.stable_seat_id, connected_seats):
		return _rejected("wrong_action_owner")
	if request.intent == "inspect_ledger":
		return _inspect_bellhouse_ledger(request)
	return _commit_bellhouse_choice(request)


func _inspect_bellhouse_ledger(request: Dictionary) -> Dictionary:
	if not request.payload.is_empty():
		return _rejected("malformed_ledger_request")
	if _stage_state.inspected:
		return _rejected("ledger_already_inspected")
	_stage_state.inspected = true
	return _accepted()


func _commit_bellhouse_choice(request: Dictionary) -> Dictionary:
	if not _stage_state.inspected:
		return _rejected("ledger_not_inspected")
	if request.payload != {"choice_id": "preserve_public_ledger"}:
		return _rejected("malformed_bellhouse_choice")
	_stage_state.choice_id = request.payload.choice_id
	_stage_state.recovery_used = request.intent == "recover_bellhouse_choice"
	return _complete_stage("bellhouse_choice_committed", request.source_revision + 1)


func _apply_council(
	request: Dictionary,
	stable_seat_order: Array[String],
	connected_seats: Array[String],
	seed: int,
	revision: int
) -> Dictionary:
	if request.intent == "submit_council_commitment":
		return _submit_council_commitment(request)
	return _resolve_council(request, stable_seat_order, connected_seats, seed, revision)


func _submit_council_commitment(request: Dictionary) -> Dictionary:
	if request.payload != {"commitment": "hold_the_light"}:
		return _rejected("malformed_council_commitment")
	if _stage_state.commitments.has(request.stable_seat_id):
		return _rejected("council_seat_already_committed")
	_stage_state.commitments[request.stable_seat_id] = request.payload.commitment
	return _accepted()


func _resolve_council(
	request: Dictionary,
	stable_seat_order: Array[String],
	connected_seats: Array[String],
	seed: int,
	revision: int
) -> Dictionary:
	if not _is_owner(request.stable_seat_id, connected_seats):
		return _rejected("wrong_action_owner")
	if _stage_state.commitments.size() != stable_seat_order.size():
		return _rejected("council_commitments_incomplete")
	if not _council_commitment_id.is_empty():
		return _rejected("council_already_resolved")
	_council_commitment_id = _identity(
		[
			"council_commitment_id",
			str(seed),
			str(revision),
			JSON.stringify(_stage_state.commitments, "", true),
		]
	)
	return _complete_stage("council_resolved", request.source_revision + 1)


func _apply_high_water(
	request: Dictionary,
	connected_seats: Array[String],
	board: DrownedHarborAlpha2BoardAuthority,
	role: DrownedHarborAlpha2RoleAuthority,
	seed: int,
	revision: int
) -> Dictionary:
	if not _is_owner(request.stable_seat_id, connected_seats):
		return _rejected("wrong_action_owner")
	if request.intent == "acknowledge_high_water":
		return _acknowledge_high_water(request)
	return _commit_high_water(request, board, role, seed, revision)


func _acknowledge_high_water(request: Dictionary) -> Dictionary:
	if not request.payload.is_empty():
		return _rejected("malformed_high_water_acknowledgement")
	if _stage_state.acknowledged:
		return _rejected("high_water_already_acknowledged")
	_stage_state.acknowledged = true
	return _accepted()


func _commit_high_water(
	request: Dictionary,
	board: DrownedHarborAlpha2BoardAuthority,
	role: DrownedHarborAlpha2RoleAuthority,
	seed: int,
	revision: int
) -> Dictionary:
	if not _stage_state.acknowledged:
		return _rejected("high_water_not_acknowledged")
	if not request.payload.is_empty():
		return _rejected("malformed_high_water_transformation")
	if not _high_water_transformation_id.is_empty():
		return _rejected("high_water_already_applied")
	var board_result: Dictionary = board.apply_high_water_atomic()
	if not board_result.get("accepted", false):
		return board_result
	var form_result: Dictionary = role.apply_high_water_forms()
	if not form_result.get("accepted", false):
		return form_result
	_high_water_transformation_id = _identity(
		[
			"high_water_transformation_id",
			str(seed),
			str(revision),
			_council_commitment_id,
			JSON.stringify(board_result.mutations, "", true),
		]
	)
	return _complete_stage("high_water_transformation_applied", request.source_revision + 1)


func _apply_last_light(
	request: Dictionary,
	stable_seat_order: Array[String],
	connected_seats: Array[String],
	board: DrownedHarborAlpha2BoardAuthority
) -> Dictionary:
	if request.intent == "move_to_last_light_route":
		return _move_to_last_light(request, board)
	if request.intent == "commit_last_light_action":
		return _commit_last_light_action(request)
	return _resolve_last_light(request, stable_seat_order, connected_seats)


func _move_to_last_light(
	request: Dictionary, board: DrownedHarborAlpha2BoardAuthority
) -> Dictionary:
	if request.payload != {"destination": "last_light_beacon"}:
		return _rejected("malformed_last_light_movement")
	if _stage_state.moved_seats.has(request.stable_seat_id):
		return _rejected("last_light_movement_already_completed")
	var moved: Dictionary = board.move_to(request.stable_seat_id, "last_light_beacon")
	if not moved.get("accepted", false):
		return moved
	_stage_state.moved_seats.append(request.stable_seat_id)
	return _accepted()


func _commit_last_light_action(request: Dictionary) -> Dictionary:
	if request.payload != {"commitment": "guard_last_light"}:
		return _rejected("malformed_last_light_commitment")
	if not _stage_state.moved_seats.has(request.stable_seat_id):
		return _rejected("seat_not_at_last_light")
	if _stage_state.commitments.has(request.stable_seat_id):
		return _rejected("last_light_seat_already_committed")
	_stage_state.commitments[request.stable_seat_id] = request.payload.commitment
	return _accepted()


func _resolve_last_light(
	request: Dictionary, stable_seat_order: Array[String], connected_seats: Array[String]
) -> Dictionary:
	if not _is_owner(request.stable_seat_id, connected_seats):
		return _rejected("wrong_action_owner")
	if (
		_stage_state.moved_seats.size() != stable_seat_order.size()
		or _stage_state.commitments.size() != stable_seat_order.size()
	):
		return _rejected("last_light_incomplete")
	_stage_state.result = "last_light_held"
	return _complete_stage("last_light_resolved", request.source_revision + 1)


func _apply_ending(request: Dictionary, connected_seats: Array[String]) -> Dictionary:
	if not _is_owner(request.stable_seat_id, connected_seats):
		return _rejected("wrong_action_owner")
	if not request.payload.is_empty():
		return _rejected("malformed_ending_request")
	_ending_id = "harbor_held_cooperatively"
	return _complete_stage("ending_resolved", request.source_revision + 1)


func _apply_epilogue(
	request: Dictionary, connected_seats: Array[String], role: DrownedHarborAlpha2RoleAuthority
) -> Dictionary:
	if not _is_owner(request.stable_seat_id, connected_seats):
		return _rejected("wrong_action_owner")
	if request.intent == "resolve_epilogue_attribution":
		return _resolve_epilogue_attribution(request, role)
	return _acknowledge_epilogue(request)


func _resolve_epilogue_attribution(
	request: Dictionary, role: DrownedHarborAlpha2RoleAuthority
) -> Dictionary:
	if not request.payload.is_empty():
		return _rejected("malformed_epilogue_request")
	if _stage_state.resolved:
		return _rejected("epilogue_already_resolved")
	var result: Dictionary = role.resolve_epilogue(_ending_id)
	if not result.get("accepted", false):
		return result
	_stage_state.resolved = true
	_stage_state.public_epilogue = result.public_epilogue
	return _accepted()


func _acknowledge_epilogue(request: Dictionary) -> Dictionary:
	if not _stage_state.resolved:
		return _rejected("epilogue_not_resolved")
	if not request.payload.is_empty():
		return _rejected("malformed_epilogue_acknowledgement")
	_stage_state.acknowledged = true
	return _accepted()


func _complete_stage(event_key: String, revision: int) -> Dictionary:
	if _stage_index >= STAGE_ORDER.size() - 1:
		return _rejected("terminal_stage_has_no_transition")
	var from_stage: String = STAGE_ORDER[_stage_index]
	var transition_id: String = TRANSITION_ORDER[_stage_index]
	_stage_index += 1
	_stage_state = _new_stage_state(STAGE_ORDER[_stage_index])
	var event: Dictionary = {
		"event_key": event_key,
		"revision": revision,
		"from_stage": from_stage,
		"to_stage": STAGE_ORDER[_stage_index],
		"transition_id": transition_id,
	}
	if event_key == "council_resolved":
		event.council_commitment_id = _council_commitment_id
	elif event_key == "high_water_transformation_applied":
		event.high_water_transformation_id = _high_water_transformation_id
	(
		_transition_history
		. append(
			{
				"transition_id": transition_id,
				"from_stage": from_stage,
				"to_stage": STAGE_ORDER[_stage_index],
				"revision": revision,
			}
		)
	)
	_public_history.append(event.duplicate(true))
	return {"accepted": true, "reason": "", "public_event": event}


func public_view() -> Dictionary:
	return {
		"stage_id": stage_id(),
		"stage_index": _stage_index,
		"legal_intents": Array(legal_intents()),
		"stage_state": _public_stage_state(),
		"council_commitment_id": _council_commitment_id,
		"high_water_transformation_id": _high_water_transformation_id,
		"ending_id": _ending_id,
		"accepted_action_count": _accepted_action_count,
		"public_history": _public_history.duplicate(true),
		"transition_history": _transition_history.duplicate(true),
	}


func to_snapshot() -> Dictionary:
	return {
		"snapshot_version": SNAPSHOT_VERSION,
		"stage_order": Array(STAGE_ORDER),
		"transition_order": Array(TRANSITION_ORDER),
		"stage_index": _stage_index,
		"stage_state": _stage_state.duplicate(true),
		"transition_history": _transition_history.duplicate(true),
		"public_history": _public_history.duplicate(true),
		"council_commitment_id": _council_commitment_id,
		"high_water_transformation_id": _high_water_transformation_id,
		"ending_id": _ending_id,
		"accepted_action_count": _accepted_action_count,
	}


func restore_snapshot(snapshot: Dictionary) -> Dictionary:
	if (
		snapshot.keys().size() != 11
		or snapshot.get("snapshot_version") != SNAPSHOT_VERSION
		or snapshot.get("stage_order") != Array(STAGE_ORDER)
		or snapshot.get("transition_order") != Array(TRANSITION_ORDER)
		or not snapshot.get("stage_index") is int
		or snapshot.get("stage_index", -1) < 0
		or snapshot.get("stage_index", -1) >= STAGE_ORDER.size()
		or not snapshot.get("stage_state") is Dictionary
		or not snapshot.get("transition_history") is Array
		or not snapshot.get("public_history") is Array
		or not snapshot.get("council_commitment_id") is String
		or not snapshot.get("high_water_transformation_id") is String
		or not snapshot.get("ending_id") is String
		or not snapshot.get("accepted_action_count") is int
		or snapshot.get("accepted_action_count", -1) < 0
		or snapshot.get("accepted_action_count", 97) > 96
	):
		return _rejected("malformed_rules_snapshot")
	var expected_state: Dictionary = _new_stage_state(STAGE_ORDER[snapshot.stage_index])
	if not _same_keys(snapshot.stage_state, expected_state):
		return _rejected("malformed_rules_snapshot")
	_stage_index = snapshot.stage_index
	_stage_state = snapshot.stage_state.duplicate(true)
	_transition_history = _dictionary_array(snapshot.transition_history)
	_public_history = _dictionary_array(snapshot.public_history)
	_council_commitment_id = snapshot.council_commitment_id
	_high_water_transformation_id = snapshot.high_water_transformation_id
	_ending_id = snapshot.ending_id
	_accepted_action_count = snapshot.accepted_action_count
	return {"accepted": true, "reason": ""}


func clear() -> void:
	_stage_index = STAGE_ORDER.size() - 1
	_stage_state = _new_stage_state(STAGE_ORDER[_stage_index])
	_transition_history.clear()
	_public_history.clear()
	_council_commitment_id = ""
	_high_water_transformation_id = ""
	_ending_id = ""
	_accepted_action_count = 0


func _public_stage_state() -> Dictionary:
	var result: Dictionary = _stage_state.duplicate(true)
	return result


static func _new_stage_state(value: String) -> Dictionary:
	match value:
		"low_tide_arrival_v1":
			return {"moved_seats": []}
		"bellhouse_ledger_v1":
			return {"inspected": false, "choice_id": "", "recovery_used": false}
		"lighthouse_council_v1":
			return {"commitments": {}}
		"high_water_v1":
			return {"acknowledged": false}
		"last_light_v1":
			return {"moved_seats": [], "commitments": {}, "result": ""}
		"ending_resolution_v1":
			return {"resolved": false}
		"epilogue_attribution_v1":
			return {"resolved": false, "public_epilogue": "", "acknowledged": false}
		_:
			return {"cleanup_complete": false, "next_destination": ""}


static func _is_owner(stable_seat_id: String, connected_seats: Array[String]) -> bool:
	return not connected_seats.is_empty() and stable_seat_id == connected_seats[0]


static func _identity(parts: Array[String]) -> String:
	return "|".join(parts).sha256_text()


static func _dictionary_array(values: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value: Variant in values:
		if value is Dictionary:
			result.append((value as Dictionary).duplicate(true))
	return result


static func _same_keys(first: Dictionary, second: Dictionary) -> bool:
	var first_keys: Array = first.keys()
	var second_keys: Array = second.keys()
	first_keys.sort()
	second_keys.sort()
	return first_keys == second_keys


static func _accepted() -> Dictionary:
	return {"accepted": true, "reason": ""}


static func _rejected(reason: String) -> Dictionary:
	return {"accepted": false, "reason": reason}
