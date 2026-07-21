class_name VerticalSliceSnapshotPolicy
extends RefCounted

const TRANSACTION_VERSION: int = 1

const HISTORY_KEYS: PackedStringArray = ["index", "stage_id", "authority_digest"]


static func validate_progression(
	snapshot: Dictionary, candidate_manifest: Dictionary, terminal_reason: String
) -> Dictionary:
	var history: Dictionary = validate_history(snapshot.stage_history, candidate_manifest)
	var reason: String = "" if history.accepted else history.reason
	if (
		reason.is_empty()
		and (
			snapshot.last_director_decision.is_empty()
			!= snapshot.last_director_application.is_empty()
		)
	):
		reason = "director_evidence_mismatch"
	if reason.is_empty() and snapshot.paused and snapshot.lifecycle != "active_tale":
		reason = "pause_lifecycle_mismatch"
	if reason.is_empty():
		reason = _lifecycle_rejection(snapshot, candidate_manifest, terminal_reason)
	return (
		{"accepted": true, "reason": ""}
		if reason.is_empty()
		else {"accepted": false, "reason": reason}
	)


static func validate_history(value: Array, candidate_manifest: Dictionary) -> Dictionary:
	if value.size() > candidate_manifest.stages.size():
		return {"accepted": false, "reason": "stage_history_too_large"}
	for index: int in value.size():
		var entry_value: Variant = value[index]
		if not entry_value is Dictionary or not _has_exact_keys(entry_value, HISTORY_KEYS):
			return {"accepted": false, "reason": "malformed_stage_history"}
		var entry: Dictionary = entry_value
		if (
			entry.index != index
			or entry.stage_id != candidate_manifest.stages[index].id
			or not entry.authority_digest is String
			or entry.authority_digest.length() != 64
			or not entry.authority_digest.is_valid_hex_number(false)
		):
			return {"accepted": false, "reason": "malformed_stage_history"}
	return {"accepted": true, "reason": ""}


static func stable_seat_snapshot_is_coherent(manager: SeatManager) -> bool:
	var identities: Dictionary = {}
	var devices: Dictionary = {}
	var coherent: bool = true
	for seat: Dictionary in manager.get_seats():
		if not coherent:
			break
		match seat.state:
			SeatManager.SeatState.UNASSIGNED:
				coherent = (
					seat.device_id == -99
					and seat.previous_device_id == -99
					and seat.identity.is_empty()
				)
			SeatManager.SeatState.ACTIVE:
				coherent = (
					seat.device_id != -99
					and seat.previous_device_id == seat.device_id
					and not seat.identity.is_empty()
					and not devices.has(seat.device_id)
					and not identities.has(seat.identity)
				)
				devices[seat.device_id] = true
				identities[seat.identity] = true
			SeatManager.SeatState.RESERVED:
				coherent = (
					seat.device_id == -99
					and seat.previous_device_id != -99
					and not seat.identity.is_empty()
					and not identities.has(seat.identity)
				)
				identities[seat.identity] = true
			_:
				coherent = false
	return coherent


static func validate_resumable_boundary(
	snapshot: Dictionary, candidate_manifest: Dictionary, session: RulesSession
) -> Dictionary:
	var reason: String = ""
	if snapshot.lifecycle != "active_tale" or snapshot.operation_index == 0:
		if not session.pending_prompt.is_empty() or not session.active_vote.is_empty():
			reason = "unexpected_pending_player_wait"
	else:
		var stage: Dictionary = candidate_manifest.stages[snapshot.stage_index]
		var boundary: Dictionary = VerticalSliceManifest.resumable_boundary(
			stage.id, snapshot.operation_index
		)
		if boundary.is_empty() or not _operation_pair_matches(stage, snapshot, boundary):
			reason = "operation_index_not_resumable"
		elif not _pending_wait_matches(boundary, session):
			reason = "pending_player_wait_mismatch"
	return (
		{"accepted": true, "reason": ""}
		if reason.is_empty()
		else {"accepted": false, "reason": reason}
	)


static func stage_start_authorities_are_clean(session: RulesSession) -> bool:
	return session.pending_prompt.is_empty() and session.active_vote.is_empty()


static func _lifecycle_rejection(
	snapshot: Dictionary, candidate_manifest: Dictionary, terminal_reason: String
) -> String:
	var stage_count: int = candidate_manifest.stages.size()
	match snapshot.lifecycle:
		"briefing":
			if (
				snapshot.stage_index != -1
				or snapshot.operation_index != 0
				or not snapshot.stage_history.is_empty()
			):
				return "briefing_progression_mismatch"
		"active_tale":
			return _active_rejection(snapshot, candidate_manifest, stage_count)
		"terminal", "ending":
			if (
				snapshot.stage_index != stage_count
				or snapshot.operation_index != 0
				or snapshot.stage_history.size() != stage_count
				or terminal_reason.is_empty()
				or snapshot.last_director_decision.is_empty()
			):
				return "terminal_progression_mismatch"
		_:
			return "unknown_snapshot_lifecycle"
	return ""


static func _operation_pair_matches(
	stage: Dictionary, snapshot: Dictionary, boundary: Dictionary
) -> bool:
	var operations: Array = stage.operations
	return (
		snapshot.operation_index > 0
		and snapshot.operation_index < operations.size()
		and operations[snapshot.operation_index - 1].get("type", "") == boundary.submit_type
		and operations[snapshot.operation_index].get("type", "") == boundary.resolve_type
	)


static func _pending_wait_matches(boundary: Dictionary, session: RulesSession) -> bool:
	var pending: Dictionary = session.pending_prompt
	if (
		pending.is_empty()
		or pending.get("id", "") != boundary.prompt_id
		or pending.get("source_id", "") != boundary.source_id
		or pending.get("revision") != session.phase_revision
	):
		return false
	var definition: Dictionary = _wait_definition(boundary, session)
	if definition.is_empty():
		return false
	var expected_eligible: Array[int] = _expected_eligible(boundary, session, definition)
	var expected_pending: Dictionary = _expected_pending(
		boundary, definition, session.phase_revision, expected_eligible, pending.get("responses")
	)
	if pending != expected_pending:
		return false
	if not _wait_kind_matches(boundary, session, definition):
		return false
	return _responses_are_coherent(pending, expected_eligible)


static func _expected_pending(
	boundary: Dictionary,
	definition: Dictionary,
	revision: int,
	eligible: Array[int],
	responses: Variant,
) -> Dictionary:
	var expected: Dictionary = definition.duplicate(true)
	if boundary.kind == "vote":
		expected["min_selections"] = 0 if definition.get("allow_abstain", false) else 1
		expected["max_selections"] = 1
		expected["allow_pass"] = definition.get("allow_abstain", false)
	expected["revision"] = revision
	expected["eligible_seats"] = eligible
	expected["responses"] = responses
	expected["source_id"] = boundary.source_id
	return expected


static func _wait_definition(boundary: Dictionary, session: RulesSession) -> Dictionary:
	if boundary.kind == "vote":
		return session.content.vote_definition()
	for event: Dictionary in session.content.events:
		if event.get("id", "") != boundary.source_id:
			continue
		for prompt: Dictionary in event.get("prompts", []):
			if prompt.get("id", "") == boundary.prompt_id:
				return prompt
	return {}


static func _wait_kind_matches(
	boundary: Dictionary, session: RulesSession, definition: Dictionary
) -> bool:
	if boundary.kind == "prompt":
		return session.active_vote.is_empty()
	var vote: Dictionary = session.active_vote
	var expected_vote: Dictionary = {
		"id": boundary.prompt_id,
		"rule": definition.get("rule", ""),
		"quorum": definition.get("quorum"),
		"tie_policy": definition.get("tie_policy", ""),
		"revision": session.phase_revision,
	}
	return boundary.kind == "vote" and vote == expected_vote


static func _expected_eligible(
	boundary: Dictionary, session: RulesSession, definition: Dictionary
) -> Array[int]:
	if boundary.kind == "prompt":
		return [definition.get("seat", 0)]
	var seats: Array[int] = session.participating_seats.duplicate()
	seats.sort()
	return seats


static func _option_ids(value: Variant) -> Array[String]:
	var ids: Array[String] = []
	if not value is Array:
		return ids
	for option: Variant in value:
		if not option is Dictionary or not option.get("id") is String:
			return []
		ids.append(option.id)
	return ids


static func _responses_are_coherent(pending: Dictionary, eligible: Array[int]) -> bool:
	var responses: Variant = pending.get("responses")
	var minimum: Variant = pending.get("min_selections")
	var maximum: Variant = pending.get("max_selections")
	if not responses is Dictionary or not minimum is int or not maximum is int:
		return false
	if responses.size() > eligible.size() or minimum < 0 or maximum < minimum:
		return false
	var allowed: Array[String] = _option_ids(pending.get("options", []))
	for seat: Variant in responses:
		if not seat is int or not eligible.has(seat):
			return false
		var selections: Variant = responses[seat]
		if (
			not selections is Array
			or not _selections_are_coherent(
				selections, allowed, minimum, maximum, pending.get("allow_pass", false)
			)
		):
			return false
	return true


static func _selections_are_coherent(
	selections: Array, allowed: Array[String], minimum: int, maximum: int, allow_pass: bool
) -> bool:
	if selections.is_empty():
		return allow_pass
	if selections.size() < minimum or selections.size() > maximum:
		return false
	var seen: Dictionary = {}
	for selection: Variant in selections:
		if not selection is String or not allowed.has(selection) or seen.has(selection):
			return false
		seen[selection] = true
	return true


static func _active_rejection(
	snapshot: Dictionary, candidate_manifest: Dictionary, stage_count: int
) -> String:
	if snapshot.stage_index < 0 or snapshot.stage_index >= stage_count:
		return "active_stage_index_out_of_bounds"
	var operation_count: int = candidate_manifest.stages[snapshot.stage_index].operations.size()
	if snapshot.operation_index < 0 or snapshot.operation_index >= operation_count:
		return "active_operation_index_out_of_bounds"
	if snapshot.stage_history.size() != snapshot.stage_index:
		return "active_stage_history_mismatch"
	if (
		(snapshot.stage_index <= 2 and not snapshot.last_director_decision.is_empty())
		or (snapshot.stage_index >= 3 and snapshot.last_director_decision.is_empty())
	):
		return "director_evidence_progression_mismatch"
	return ""


static func _has_exact_keys(value: Dictionary, expected: PackedStringArray) -> bool:
	if value.size() != expected.size():
		return false
	for key: Variant in value:
		if not key is String or not expected.has(key):
			return false
	return true


static func transaction_snapshot(coordinator: VerticalSliceCoordinator) -> Dictionary:
	return {
		"transaction_version": TRANSACTION_VERSION,
		"stage_index": coordinator.stage_index,
		"operation_index": coordinator.operation_index,
		"stage_history": coordinator.stage_history.duplicate(true),
		"last_director_decision": coordinator.last_director_decision.duplicate(true),
		"last_director_application": coordinator.last_director_application.duplicate(true),
		"seat_manager": coordinator.seat_manager.to_snapshot(),
		"pawns": coordinator.pawn_registry.to_snapshot(),
		"board": coordinator.board_state.to_snapshot(),
		"rules": coordinator.rules_session.to_snapshot(),
		"director": coordinator.director_runtime.to_snapshot(),
		"roles": coordinator.role_session.to_snapshot(),
	}


static func rollback_stage_transaction(coordinator: VerticalSliceCoordinator) -> void:
	if coordinator._stage_checkpoint.is_empty():
		return
	var checkpoint: Dictionary = coordinator._stage_checkpoint.duplicate(true)
	coordinator._restore_authorities(checkpoint)
	coordinator.stage_index = checkpoint.stage_index
	coordinator.operation_index = checkpoint.operation_index
	coordinator.stage_history = RulesContent.SessionData.dict_array(checkpoint.stage_history)
	coordinator.last_director_decision = checkpoint.last_director_decision.duplicate(true)
	coordinator.last_director_application = checkpoint.last_director_application.duplicate(true)
	coordinator._stage_checkpoint.clear()
