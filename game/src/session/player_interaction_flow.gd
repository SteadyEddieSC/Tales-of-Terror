class_name PlayerInteractionFlow
extends RefCounted

const PLAYER_OPERATION_TYPES: PackedStringArray = [
	"play_card", "resolve_check", "director_evaluate", "role_action"
]
const VALID_ACTIONS: PackedStringArray = ["confirm", "pass"]


func public_state(coordinator: VerticalSliceCoordinator) -> Dictionary:
	if (
		coordinator.lifecycle != "active_tale"
		or coordinator.stage_index < 0
		or coordinator.stage_index >= coordinator.manifest.get("stages", []).size()
	):
		return {}
	if coordinator.paused:
		return {
			"interaction_id": "session:paused",
			"kind": "paused",
			"title": "Tale Paused",
			"instruction": "Resume before submitting a gameplay decision.",
			"controls": "MENU / P: RESUME  |  X / H: HELP  |  HOLD Y / R: RESET",
			"eligible_seats": [],
			"committed_seats": [],
			"pending_seats": [],
			"owner_seat": 0,
			"options": [],
			"allow_pass": false,
		}
	if coordinator.rules_session != null and not coordinator.rules_session.pending_prompt.is_empty():
		return _rules_prompt_state(coordinator)
	var stage: Dictionary = coordinator.manifest.stages[coordinator.stage_index]
	if coordinator.operation_index == 0 and coordinator._stage_checkpoint.is_empty():
		var stage_seats: Array[int] = _active_seats(coordinator)
		return {
			"interaction_id": "%s:continue" % stage.id,
			"kind": "stage_continue",
			"title": stage.get("title", "Continue the Tale"),
			"instruction": "Any active seat may continue into the next authored stage.",
			"controls": "A / ENTER: CONTINUE  |  X / H: HELP  |  HOLD Y / R: RESET",
			"eligible_seats": stage_seats,
			"committed_seats": [],
			"pending_seats": stage_seats,
			"owner_seat": 0,
			"options": [{"id": "confirm", "label": "Continue"}],
			"allow_pass": false,
		}
	if coordinator.operation_index >= stage.get("operations", []).size():
		return {}
	var operation: Dictionary = stage.operations[coordinator.operation_index]
	return _operation_state(coordinator, stage, operation)


func submit(
	coordinator: VerticalSliceCoordinator, seat_number: int, action: String
) -> Dictionary:
	var rejection: Dictionary = _submission_rejection(coordinator, seat_number, action)
	if not rejection.is_empty():
		return rejection
	return _commit_submission(coordinator, public_state(coordinator), action)


func _submission_rejection(
	coordinator: VerticalSliceCoordinator, seat_number: int, action: String
) -> Dictionary:
	if coordinator.lifecycle != "active_tale":
		return {"accepted": false, "consumed": false, "reason": "interaction_not_available"}
	if coordinator.paused:
		return {"accepted": false, "consumed": true, "reason": "session_paused"}
	if not VALID_ACTIONS.has(action):
		return {"accepted": false, "consumed": true, "reason": "unsupported_interaction_action"}
	var state: Dictionary = public_state(coordinator)
	if state.is_empty():
		return {"accepted": false, "consumed": false, "reason": "interaction_not_available"}
	if not state.get("eligible_seats", []).has(seat_number):
		return {"accepted": false, "consumed": true, "reason": "interaction_seat_not_eligible"}
	return {}


func _commit_submission(
	coordinator: VerticalSliceCoordinator, state: Dictionary, action: String
) -> Dictionary:
	match state.kind:
		"choice", "vote":
			if action != "confirm":
				return {"accepted": false, "consumed": true, "reason": "response_still_pending"}
			if not _responses_complete(coordinator):
				return {"accepted": false, "consumed": true, "reason": "responses_incomplete"}
			return _consumed(_advance(coordinator))
		"stage_continue":
			if action != "confirm":
				return {"accepted": false, "consumed": true, "reason": "stage_continue_required"}
			return _consumed(_advance(coordinator))
		"card_play", "check_attempt", "director_acknowledgement", "afterlife_action":
			return _submit_operation(coordinator, state, action)
		_:
			return {"accepted": false, "consumed": true, "reason": "interaction_not_committable"}


func _advance(coordinator: VerticalSliceCoordinator) -> Dictionary:
	if (
		coordinator.stage_index < 0
		or coordinator.stage_index >= coordinator.manifest.get("stages", []).size()
	):
		return {"accepted": false, "reason": "no_active_stage"}
	var stage: Dictionary = coordinator.manifest.stages[coordinator.stage_index]
	if coordinator._stage_checkpoint.is_empty():
		coordinator._stage_checkpoint = VerticalSliceSnapshotPolicy.transaction_snapshot(coordinator)
	while coordinator.operation_index < stage.operations.size():
		var operation: Dictionary = stage.operations[coordinator.operation_index]
		if operation.type in ["submit_prompt", "submit_vote"]:
			coordinator.operation_index += 1
			if not _responses_complete(coordinator):
				return _wait(coordinator, stage.id)
			continue
		if (
			operation.type in ["resolve_prompt", "resolve_vote"]
			and not _responses_complete(coordinator)
		):
			return _wait(coordinator, stage.id)
		if PLAYER_OPERATION_TYPES.has(operation.type):
			return _wait(coordinator, stage.id)
		var result: Dictionary = coordinator._apply_operation(operation)
		if not result.get("accepted", false):
			VerticalSliceSnapshotPolicy.rollback_stage_transaction(coordinator)
			return coordinator._reject(
				"stage_operation_failed:%s:%s:%s"
				% [stage.id, operation.type, result.get("reason", "rejected")]
			)
		coordinator.operation_index += 1
	return coordinator._finish_stage(stage)


func _submit_operation(
	coordinator: VerticalSliceCoordinator, state: Dictionary, action: String
) -> Dictionary:
	var stage: Dictionary = coordinator.manifest.stages[coordinator.stage_index]
	var operation: Dictionary = stage.operations[coordinator.operation_index]
	if action == "pass":
		if not state.get("allow_pass", false):
			return {"accepted": false, "consumed": true, "reason": "interaction_pass_not_allowed"}
		coordinator.operation_index += 1
		coordinator._emit_state()
		return _consumed(_advance(coordinator))
	var result: Dictionary = coordinator._apply_operation(operation)
	if not result.get("accepted", false):
		VerticalSliceSnapshotPolicy.rollback_stage_transaction(coordinator)
		return _consumed(
			coordinator._reject(
				"stage_operation_failed:%s:%s:%s"
				% [stage.id, operation.type, result.get("reason", "rejected")]
			)
		)
	coordinator.operation_index += 1
	coordinator._emit_state()
	return _consumed(_advance(coordinator))


func _rules_prompt_state(coordinator: VerticalSliceCoordinator) -> Dictionary:
	var prompt: Dictionary = coordinator.rules_session.pending_prompt
	var eligible: Array[int] = _int_array(prompt.get("eligible_seats", []))
	var responses: Dictionary = prompt.get("responses", {})
	var committed: Array[int] = []
	var pending: Array[int] = []
	for seat_number: int in eligible:
		if responses.has(seat_number):
			committed.append(seat_number)
		else:
			pending.append(seat_number)
	var options: Array[Dictionary] = []
	for option_value: Variant in prompt.get("options", []):
		if not option_value is Dictionary:
			continue
		var option: Dictionary = option_value
		options.append(
			{
				"id": option.get("id", ""),
				"label": option.get("text", _friendly(option.get("id", "Option"))),
				"symbol": option.get("symbol", "◇"),
			}
		)
	var is_vote: bool = not coordinator.rules_session.active_vote.is_empty()
	var allow_pass: bool = prompt.get("allow_pass", false)
	var controls: String = "LEFT / RIGHT: CHOOSE  |  A / ENTER: COMMIT  |  X / H: HELP"
	if allow_pass:
		controls = "LEFT / RIGHT: CHOOSE  |  A / ENTER: COMMIT  |  B / ESC: PASS"
	return {
		"interaction_id": "rules:%s:%d" % [prompt.get("id", "prompt"), prompt.get("revision", 0)],
		"kind": "vote" if is_vote else "choice",
		"title": prompt.get("title", "Public Vote" if is_vote else "Shared Choice"),
		"instruction": (
			"%d of %d eligible seats committed; waiting for %s."
			% [committed.size(), eligible.size(), _seat_list(pending)]
		),
		"controls": controls,
		"eligible_seats": eligible,
		"committed_seats": committed,
		"pending_seats": pending,
		"owner_seat": eligible[0] if eligible.size() == 1 else 0,
		"options": options,
		"allow_pass": allow_pass,
	}


func _operation_state(
	coordinator: VerticalSliceCoordinator, stage: Dictionary, operation: Dictionary
) -> Dictionary:
	var active: Array[int] = _active_seats(coordinator)
	var base: Dictionary = {
		"interaction_id": "%s:%d:%s" % [stage.id, coordinator.operation_index, operation.type],
		"title": stage.get("title", "Lantern House"),
		"committed_seats": [],
		"options": [],
		"allow_pass": false,
	}
	match operation.type:
		"play_card":
			var card_owner: int = active[0] if not active.is_empty() else 0
			base.merge(
				{
					"kind": "card_play",
					"instruction": "Seat %s may play %s or preserve it for later."
					% [_roman(card_owner), _friendly(operation.get("card_id", "card"))],
					"controls": "A / ENTER: PLAY CARD  |  B / ESC: PASS  |  X / H: HELP",
					"eligible_seats": [card_owner],
					"pending_seats": [card_owner],
					"owner_seat": card_owner,
					"options": [
						{"id": "confirm", "label": "Play Card"},
						{"id": "pass", "label": "Keep Card"},
					],
					"allow_pass": true,
				},
				true,
			)
		"resolve_check":
			var check_owner: int = active[0] if not active.is_empty() else 0
			base.merge(
				{
					"kind": "check_attempt",
					"instruction": "Seat %s must attempt the %s check."
					% [_roman(check_owner), _friendly(operation.get("check_id", "check"))],
					"controls": "A / ENTER: ATTEMPT CHECK  |  X / H: HELP",
					"eligible_seats": [check_owner],
					"pending_seats": [check_owner],
					"owner_seat": check_owner,
					"options": [{"id": "confirm", "label": "Attempt Check"}],
				},
				true,
			)
		"director_evaluate":
			base.merge(
				{
					"kind": "director_acknowledgement",
					"instruction": "The House is ready to react. Any active seat may continue.",
					"controls": "A / ENTER: LET THE HOUSE RESPOND  |  X / H: HELP",
					"eligible_seats": active,
					"pending_seats": active,
					"owner_seat": 0,
					"options": [{"id": "confirm", "label": "Continue"}],
				},
				true,
			)
		"role_action":
			var actor: int = (
				coordinator.role_session.seat_with_tag(operation.get("selector_tag", ""))
				if coordinator.role_session != null
				else 0
			)
			base.merge(
				{
					"kind": "afterlife_action",
					"instruction": "Seat %s may use a Restless action or pass."
					% _roman(actor),
					"controls": "A / ENTER: ACT  |  B / ESC: PASS  |  X / H: HELP",
					"eligible_seats": [actor] if actor > 0 else [],
					"pending_seats": [actor] if actor > 0 else [],
					"owner_seat": actor,
					"options": [
						{"id": "confirm", "label": "Use Restless Action"},
						{"id": "pass", "label": "Pass"},
					],
					"allow_pass": true,
				},
				true,
			)
		_:
			base.merge(
				{
					"kind": "automatic_consequence",
					"instruction": "The Tale is resolving an authored consequence.",
					"controls": "PLEASE WAIT",
					"eligible_seats": [],
					"pending_seats": [],
					"owner_seat": 0,
				},
				true,
			)
	return base


func _wait(coordinator: VerticalSliceCoordinator, stage_id: String) -> Dictionary:
	coordinator._emit_state()
	return {
		"accepted": true,
		"consumed": true,
		"waiting_for_players": true,
		"stage_id": stage_id,
	}


func _responses_complete(coordinator: VerticalSliceCoordinator) -> bool:
	var prompt: Dictionary = coordinator.rules_session.pending_prompt
	if prompt.is_empty():
		return false
	var eligible: Array = prompt.get("eligible_seats", [])
	var responses: Dictionary = prompt.get("responses", {})
	return not eligible.is_empty() and responses.size() >= eligible.size()


func _consumed(result: Dictionary) -> Dictionary:
	var consumed: Dictionary = result.duplicate(true)
	consumed["consumed"] = true
	return consumed


func _active_seats(coordinator: VerticalSliceCoordinator) -> Array[int]:
	var seats: Array[int] = coordinator.active_seats()
	seats.sort()
	return seats


func _int_array(values: Variant) -> Array[int]:
	var result: Array[int] = []
	if not values is Array:
		return result
	for value: Variant in values:
		if value is int:
			result.append(value)
	result.sort()
	return result


func _seat_list(seats: Array[int]) -> String:
	if seats.is_empty():
		return "no seats"
	var labels := PackedStringArray()
	for seat_number: int in seats:
		labels.append(_roman(seat_number))
	return ", ".join(labels)


func _roman(seat_number: int) -> String:
	const ROMAN: PackedStringArray = ["—", "I", "II", "III", "IV", "V", "VI", "VII", "VIII"]
	return ROMAN[seat_number] if seat_number >= 1 and seat_number <= 8 else "—"


func _friendly(stable_id: String) -> String:
	if stable_id.is_empty():
		return "—"
	var words: PackedStringArray = stable_id.replace("-", "_").split("_", false)
	for index: int in words.size():
		words[index] = words[index].capitalize()
	return " ".join(words)
