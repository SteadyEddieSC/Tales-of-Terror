class_name DrownedHarborDeveloperAdmissionGate
extends RefCounted

const REQUEST_KEYS: PackedStringArray = [
	"request_kind",
	"developer_mode",
	"tale_id",
	"package_kind",
	"schema_version",
	"package_version",
	"provider_id",
	"seed",
	"stable_seat_ids",
]
const NORMAL_DEFAULT_TALE: String = "lantern_house_vertical_slice"
const DEVELOPER_ADMISSION_REQUEST_KIND: String = "developer_only_explicit_launch"

var _provider := DrownedHarborScopedProvider.new()
var _session: DrownedHarborScaffoldSession = null
var _last_request: Dictionary = {}
var _alpha2_provider := DrownedHarborAlpha2ScopedProvider.new()
var _alpha2_session: DrownedHarborAlpha2Session = null
var _alpha2_last_request: Dictionary = {}


func admit(request: Dictionary) -> Dictionary:
	var rejection: String = _validate_request(request)
	if not rejection.is_empty():
		return _rejected(rejection)
	var candidate: Dictionary = _provider.build_candidate()
	if not candidate.get("accepted", false):
		return candidate
	var seat_ids := PackedStringArray(request.stable_seat_ids)
	var pending := DrownedHarborScaffoldSession.new(candidate, request.seed, seat_ids)
	_session = pending
	_last_request = request.duplicate(true)
	return {
		"accepted": true,
		"reason": "",
		"tale_id": DrownedHarborScopedProvider.TALE_ID,
		"provider_id": DrownedHarborScopedProvider.PROVIDER_ID,
		"session": _session,
	}


func restore(request: Dictionary, snapshot: Dictionary) -> Dictionary:
	var rejection: String = _validate_request(request)
	if not rejection.is_empty():
		return _rejected(rejection)
	var candidate: Dictionary = _provider.build_candidate()
	if not candidate.get("accepted", false):
		return candidate
	var restored: Dictionary = DrownedHarborScaffoldSession.restore_candidate(candidate, snapshot)
	if not restored.get("accepted", false):
		return restored
	if restored.session.to_snapshot().rng.seed != request.seed:
		return _rejected("restore_seed_mismatch")
	_session = restored.session
	_last_request = request.duplicate(true)
	return {"accepted": true, "reason": "", "session": _session}


func rematch() -> Dictionary:
	if _session == null or _last_request.is_empty():
		return _rejected("no_scaffold_session")
	var candidate: Dictionary = _provider.build_candidate()
	if not candidate.get("accepted", false):
		return candidate
	var pending := DrownedHarborScaffoldSession.new(
		candidate, _last_request.seed, PackedStringArray(_last_request.stable_seat_ids)
	)
	_session.deactivate()
	_session = pending
	return {"accepted": true, "reason": "", "session": _session}


func exit_to_normal_default() -> Dictionary:
	_clear_session()
	return {"accepted": true, "reason": "", "selected_tale_id": NORMAL_DEFAULT_TALE}


func reset_to_normal_default() -> Dictionary:
	return exit_to_normal_default()


func rollback() -> Dictionary:
	_clear_session()
	return {"accepted": true, "reason": "", "selected_tale_id": NORMAL_DEFAULT_TALE}


func active_session() -> DrownedHarborScaffoldSession:
	return _session


func has_active_scaffold() -> bool:
	return _session != null


func admit_alpha2(request: Dictionary) -> Dictionary:
	var rejection: String = _validate_alpha2_request(request)
	if not rejection.is_empty():
		return _rejected(rejection)
	var candidate: Dictionary = _alpha2_provider.build_candidate()
	if not candidate.get("accepted", false):
		return candidate
	var pending := DrownedHarborAlpha2Session.new(
		candidate, request.seed, PackedStringArray(request.stable_seat_ids)
	)
	_alpha2_session = pending
	_alpha2_last_request = request.duplicate(true)
	return {
		"accepted": true,
		"reason": "",
		"tale_id": DrownedHarborAlpha2ScopedProvider.TALE_ID,
		"provider_id": DrownedHarborAlpha2ScopedProvider.PROVIDER_ID,
		"session": _alpha2_session,
	}


func restore_alpha2(request: Dictionary, snapshot: Dictionary) -> Dictionary:
	var rejection: String = _validate_alpha2_request(request)
	if not rejection.is_empty():
		return _rejected(rejection)
	var candidate: Dictionary = _alpha2_provider.build_candidate()
	if not candidate.get("accepted", false):
		return candidate
	var restored: Dictionary = DrownedHarborAlpha2Session.restore_candidate(candidate, snapshot)
	if not restored.get("accepted", false):
		return restored
	if (
		restored.session.to_snapshot().seed != request.seed
		or restored.session.to_snapshot().stable_seat_order != request.stable_seat_ids
	):
		return _rejected("restore_admission_mismatch")
	_alpha2_session = restored.session
	_alpha2_last_request = request.duplicate(true)
	return {"accepted": true, "reason": "", "session": _alpha2_session}


func migrate_alpha1_snapshot_to_alpha2(
	request: Dictionary, alpha1_snapshot: Dictionary
) -> Dictionary:
	var rejection: String = _validate_alpha2_request(request)
	if not rejection.is_empty():
		return _rejected(rejection)
	var source_validation: Dictionary = _validated_alpha1_migration_source(request, alpha1_snapshot)
	if not source_validation.get("accepted", false):
		return source_validation
	var candidate: Dictionary = _alpha2_provider.build_candidate()
	if not candidate.get("accepted", false):
		return candidate
	var pending := DrownedHarborAlpha2Session.new(
		candidate, request.seed, PackedStringArray(request.stable_seat_ids)
	)
	(
		pending
		. set_migration_receipt(
			{
				"from_snapshot_version": 1,
				"to_snapshot_version": 2,
				"from_stage_id": alpha1_snapshot.stage_id,
				"to_stage_id": "low_tide_arrival_v1",
				"policy": "explicit_identity_first_migration",
			}
		)
	)
	_alpha2_session = pending
	_alpha2_last_request = request.duplicate(true)
	return {"accepted": true, "reason": "", "session": _alpha2_session, "migrated": true}


func _validated_alpha1_migration_source(
	request: Dictionary, alpha1_snapshot: Dictionary
) -> Dictionary:
	var alpha1_candidate: Dictionary = _provider.build_candidate()
	if not alpha1_candidate.get("accepted", false):
		return alpha1_candidate
	var restored_alpha1: Dictionary = DrownedHarborScaffoldSession.restore_candidate(
		alpha1_candidate, alpha1_snapshot
	)
	if not restored_alpha1.get("accepted", false):
		return _rejected("alpha1_snapshot_v1_rejected")
	if alpha1_snapshot.get("terminal", false) or not alpha1_snapshot.get("active", false):
		return _rejected("alpha1_terminal_snapshot_not_migratable")
	var alpha1_seats: Array[String] = []
	for row: Dictionary in alpha1_snapshot.stable_seats:
		alpha1_seats.append(row.stable_seat_id)
	if (
		alpha1_seats != request.stable_seat_ids
		or alpha1_snapshot.get("rng", {}).get("seed") != request.seed
	):
		return _rejected("migration_admission_mismatch")
	return {"accepted": true, "reason": ""}


func rematch_alpha2(cleanup_request: Dictionary) -> Dictionary:
	if _alpha2_session == null or _alpha2_last_request.is_empty():
		return _rejected("no_alpha2_session")
	var cleanup: Dictionary = _alpha2_session.process_request(cleanup_request)
	if not cleanup.get("accepted", false) or cleanup.get("next_destination") != "rematch":
		return cleanup
	var candidate: Dictionary = _alpha2_provider.build_candidate()
	if not candidate.get("accepted", false):
		return candidate
	_alpha2_session = DrownedHarborAlpha2Session.new(
		candidate,
		_alpha2_last_request.seed,
		PackedStringArray(_alpha2_last_request.stable_seat_ids)
	)
	return {"accepted": true, "reason": "", "session": _alpha2_session}


func exit_alpha2_to_normal_default(cleanup_request: Dictionary) -> Dictionary:
	if _alpha2_session == null:
		return _rejected("no_alpha2_session")
	var cleanup: Dictionary = _alpha2_session.process_request(cleanup_request)
	if not cleanup.get("accepted", false) or cleanup.get("next_destination") != "normal_title":
		return cleanup
	_clear_alpha2_session()
	return {"accepted": true, "reason": "", "selected_tale_id": NORMAL_DEFAULT_TALE}


func rollback_alpha2() -> Dictionary:
	_clear_alpha2_session()
	return {"accepted": true, "reason": "", "selected_tale_id": NORMAL_DEFAULT_TALE}


func active_alpha2_session() -> DrownedHarborAlpha2Session:
	return _alpha2_session


func has_active_alpha2() -> bool:
	return _alpha2_session != null


func _clear_session() -> void:
	if _session != null:
		_session.deactivate()
	_session = null
	_last_request.clear()


func _clear_alpha2_session() -> void:
	_alpha2_session = (null)
	_alpha2_last_request.clear()


func _validate_request(request: Dictionary) -> String:
	if not _has_exact_keys(request, REQUEST_KEYS):
		return "malformed_admission_request"
	if (
		request.get("request_kind") != DEVELOPER_ADMISSION_REQUEST_KIND
		or request.get("developer_mode") != true
		or request.get("tale_id") != DrownedHarborScopedProvider.TALE_ID
		or request.get("package_kind") != "tale"
		or request.get("schema_version") != 1
		or request.get("package_version") != 1
		or request.get("provider_id") != DrownedHarborScopedProvider.PROVIDER_ID
		or not request.get("seed") is int
		or request.get("seed", 0) < 1
	):
		return "unauthorized_admission_identity"
	var seats: Variant = request.get("stable_seat_ids")
	if not seats is Array or seats.is_empty() or seats.size() > SeatManager.MAX_SEATS:
		return "malformed_stable_seats"
	var seen: Dictionary = {}
	for stable_seat_id: Variant in seats:
		if (
			not stable_seat_id is String
			or not String(stable_seat_id).begins_with("seat_")
			or seen.has(stable_seat_id)
		):
			return "malformed_stable_seats"
		seen[stable_seat_id] = true
	return ""


func _validate_alpha2_request(request: Dictionary) -> String:
	if not _has_exact_keys(request, REQUEST_KEYS):
		return "malformed_admission_request"
	if (
		request.get("request_kind") != DEVELOPER_ADMISSION_REQUEST_KIND
		or request.get("developer_mode") != true
		or request.get("tale_id") != DrownedHarborAlpha2ScopedProvider.TALE_ID
		or request.get("package_kind") != "tale"
		or request.get("schema_version") != 1
		or request.get("package_version") != 2
		or request.get("provider_id") != DrownedHarborAlpha2ScopedProvider.PROVIDER_ID
		or not request.get("seed") is int
		or request.get("seed", 0) < 1
	):
		return "unauthorized_admission_identity"
	var seats: Variant = request.get("stable_seat_ids")
	if not seats is Array or seats.is_empty() or seats.size() > SeatManager.MAX_SEATS:
		return "malformed_stable_seats"
	var seen: Dictionary = {}
	for stable_seat_id: Variant in seats:
		if (
			not stable_seat_id is String
			or not String(stable_seat_id).begins_with("seat_")
			or seen.has(stable_seat_id)
		):
			return "malformed_stable_seats"
		seen[stable_seat_id] = true
	return ""


func _has_exact_keys(value: Dictionary, expected: PackedStringArray) -> bool:
	if value.size() != expected.size():
		return false
	for key: Variant in value:
		if not key is String or not expected.has(key):
			return false
	return true


func _rejected(reason: String) -> Dictionary:
	return {"accepted": false, "reason": reason, "diagnostics": [{"code": reason}]}
