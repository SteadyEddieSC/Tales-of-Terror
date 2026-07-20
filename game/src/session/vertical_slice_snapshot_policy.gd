class_name VerticalSliceSnapshotPolicy
extends RefCounted

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
