class_name PrivateRevealFlow
extends RefCounted

const VIEW_VERSION: int = 1
const PHASE_IDLE: String = "idle"
const PHASE_SHIELD: String = "shield"
const PHASE_REVEAL: String = "reveal"
const PHASE_COMPLETE: String = "complete"
const VALID_ACTIONS: PackedStringArray = ["confirm", "cancel"]

var phase: String = PHASE_IDLE
var queue: Array[int] = []
var queue_index: int = 0
var revision: int = 0


func begin(session: RoleSession, seats: Array[int]) -> Dictionary:
	reset()
	if session == null:
		return {"accepted": false, "reason": "role_session_missing"}
	var normalized: Array[int] = seats.duplicate()
	normalized.sort()
	for seat_number: int in normalized:
		if (
			session.seat_states.has(seat_number)
			and not session.seat_states[seat_number].get("acknowledged", false)
		):
			queue.append(seat_number)
	phase = PHASE_SHIELD if not queue.is_empty() else PHASE_COMPLETE
	revision += 1
	return {"accepted": true, "reason": "", "phase": phase}


func reset() -> void:
	phase = PHASE_IDLE
	queue.clear()
	queue_index = 0
	revision += 1


func is_blocking() -> bool:
	return phase in [PHASE_SHIELD, PHASE_REVEAL]


func advance_player_stage(coordinator: Object) -> Dictionary:
	if coordinator.get("paused"):
		return coordinator.call("_reject", "session_paused")
	if phase != PHASE_COMPLETE:
		return coordinator.call("_reject", "private_reveal_incomplete")
	var stage_index: int = coordinator.get("stage_index")
	var manifest: Dictionary = coordinator.get("manifest")
	if (
		coordinator.get("lifecycle") != "active_tale"
		or stage_index < 0
		or stage_index >= manifest.stages.size()
	):
		return coordinator.call("_reject", "no_active_stage")
	return coordinator.call("_execute_stage", false)


func current_seat() -> int:
	if queue_index < 0 or queue_index >= queue.size():
		return 0
	return queue[queue_index]


func public_view(session: RoleSession) -> Dictionary:
	var authorized_seat: int = current_seat()
	var connected: bool = false
	if session != null and session.seat_states.has(authorized_seat):
		connected = session.seat_states[authorized_seat].get("connected", false)
	var pending: Array[int] = []
	for index: int in range(queue_index, queue.size()):
		pending.append(queue[index])
	return {
		"view_version": VIEW_VERSION,
		"phase": phase,
		"revision": revision,
		"authorized_seat": authorized_seat,
		"authorized_numeral": _numeral(authorized_seat),
		"authorized_connected": connected,
		"completed_count": mini(queue_index, queue.size()),
		"total_count": queue.size(),
		"pending_seats": pending,
		"instruction": _instruction(authorized_seat, connected),
		"controls": _controls(connected),
		"shared_screen_shielded": phase != PHASE_REVEAL,
	}


func private_view(session: RoleSession, requester_seat: int) -> Dictionary:
	if phase != PHASE_REVEAL or requester_seat != current_seat():
		return {
			"accepted": false,
			"reason": "private_reveal_not_authorized",
			"view_kind": "seat_private",
		}
	if session == null or not session.seat_states.has(requester_seat):
		return {
			"accepted": false,
			"reason": "seat_not_authorized",
			"view_kind": "seat_private",
		}
	if not session.seat_states[requester_seat].get("connected", false):
		return {
			"accepted": false,
			"reason": "authorized_seat_disconnected",
			"view_kind": "seat_private",
		}
	return session.seat_private_view(requester_seat)


func submit(session: RoleSession, seat_number: int, action: String) -> Dictionary:
	if not VALID_ACTIONS.has(action) or not is_blocking():
		return _result(false, false, "private_reveal_not_active")
	var authorized_seat: int = current_seat()
	if seat_number != authorized_seat:
		return _result(false, true, "private_reveal_wrong_seat")
	if session == null or not session.seat_states.has(seat_number):
		return _result(false, true, "seat_not_authorized")
	if not session.seat_states[seat_number].get("connected", false):
		return _result(false, true, "authorized_seat_disconnected")
	if phase == PHASE_SHIELD:
		return _submit_shield(action)
	return _submit_reveal(session, seat_number, action)


func shield() -> Dictionary:
	if phase != PHASE_REVEAL:
		return _result(true, false, "")
	phase = PHASE_SHIELD
	revision += 1
	return _result(true, true, "")


func connection_changed(seat_number: int, connected: bool) -> Dictionary:
	if seat_number != current_seat() or connected or phase != PHASE_REVEAL:
		return _result(true, false, "")
	phase = PHASE_SHIELD
	revision += 1
	return _result(true, true, "")


static func ensure_started(coordinator: Object) -> void:
	var flow: PrivateRevealFlow = coordinator.get("_private_reveal_flow")
	if coordinator.get("lifecycle") != "active_tale" or flow.phase != PHASE_IDLE:
		return
	flow.begin(coordinator.get("role_session"), coordinator.call("active_seats"))
	coordinator.call("_emit_state")


static func submit_for(coordinator: Object, seat_number: int, action: String) -> Dictionary:
	var flow: PrivateRevealFlow = coordinator.get("_private_reveal_flow")
	var result: Dictionary = flow.submit(coordinator.get("role_session"), seat_number, action)
	if result.get("consumed", false):
		coordinator.call("_emit_state")
	return result


static func private_view_for(coordinator: Object, seat_number: int) -> Dictionary:
	var flow: PrivateRevealFlow = coordinator.get("_private_reveal_flow")
	return flow.private_view(coordinator.get("role_session"), seat_number)


static func shield_for(coordinator: Object) -> Dictionary:
	var flow: PrivateRevealFlow = coordinator.get("_private_reveal_flow")
	var result: Dictionary = flow.shield()
	if result.get("consumed", false):
		coordinator.call("_emit_state")
	return result


static func connection_changed_for(
	coordinator: Object, seat_number: int, connected: bool
) -> Dictionary:
	var flow: PrivateRevealFlow = coordinator.get("_private_reveal_flow")
	var result: Dictionary = flow.connection_changed(seat_number, connected)
	if result.get("consumed", false):
		coordinator.call("_emit_state")
	return result


func _submit_shield(action: String) -> Dictionary:
	if action == "cancel":
		return _result(true, true, "")
	phase = PHASE_REVEAL
	revision += 1
	return _result(true, true, "")


func _submit_reveal(session: RoleSession, seat_number: int, action: String) -> Dictionary:
	if action == "cancel":
		phase = PHASE_SHIELD
		revision += 1
		return _result(true, true, "")
	var acknowledgement: Dictionary = session.acknowledge_private_role(seat_number)
	if not acknowledgement.get("accepted", false):
		return _result(
			false, true, acknowledgement.get("reason", "private_acknowledgement_rejected")
		)
	queue_index += 1
	phase = PHASE_COMPLETE if queue_index >= queue.size() else PHASE_SHIELD
	revision += 1
	return _result(true, true, "")


func _instruction(authorized_seat: int, connected: bool) -> String:
	if phase == PHASE_IDLE:
		return "Private reveal ceremony is not active."
	if phase == PHASE_COMPLETE:
		return "All stable seats completed their controlled reveals."
	if not connected:
		return (
			"Seat %s disconnected. The shared screen remains safely shielded."
			% _numeral(authorized_seat)
		)
	if phase == PHASE_REVEAL:
		return (
			"Seat %s only: review the private role card, then acknowledge or close safely."
			% _numeral(authorized_seat)
		)
	return (
		"Shared screen shielded. Pass control to Seat %s before opening the private reveal."
		% _numeral(authorized_seat)
	)


func _controls(connected: bool) -> String:
	if phase == PHASE_COMPLETE:
		return "A / ENTER: BEGIN TALE  •  X / H: HELP"
	if not connected:
		return "RECONNECT THE SAME STABLE SEAT  •  X / H: HELP"
	if phase == PHASE_REVEAL:
		return "A / ENTER: ACKNOWLEDGE  •  B / ESC: CLOSE SAFELY"
	return "AUTHORIZED SEAT A / ENTER: OPEN  •  X / H: HELP"


func _result(accepted: bool, consumed: bool, reason: String) -> Dictionary:
	return {
		"accepted": accepted,
		"consumed": consumed,
		"reason": reason,
		"phase": phase,
		"revision": revision,
	}


func _numeral(seat_number: int) -> String:
	if seat_number < 1 or seat_number > RoleSession.SEAT_NUMERALS.size():
		return "—"
	return RoleSession.SEAT_NUMERALS[seat_number - 1]
