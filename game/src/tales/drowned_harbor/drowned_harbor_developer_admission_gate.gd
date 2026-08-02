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

var _provider := DrownedHarborScopedProvider.new()
var _session: DrownedHarborScaffoldSession = null
var _last_request: Dictionary = {}


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


func _clear_session() -> void:
	if _session != null:
		_session.deactivate()
	_session = null
	_last_request.clear()


func _validate_request(request: Dictionary) -> String:
	if not _has_exact_keys(request, REQUEST_KEYS):
		return "malformed_admission_request"
	if (
		request.get("request_kind") != "developer_only_explicit_launch"
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


func _has_exact_keys(value: Dictionary, expected: PackedStringArray) -> bool:
	if value.size() != expected.size():
		return false
	for key: Variant in value:
		if not key is String or not expected.has(key):
			return false
	return true


func _rejected(reason: String) -> Dictionary:
	return {"accepted": false, "reason": reason, "diagnostics": [{"code": reason}]}
