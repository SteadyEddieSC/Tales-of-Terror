class_name DrownedHarborAlpha3DeveloperAdmission
extends RefCounted

const REQUEST_KEYS: PackedStringArray = [
	"request_kind",
	"developer_mode",
	"tale_id",
	"package_kind",
	"schema_version",
	"package_version",
	"provider_id",
	"provider_version",
	"mode_id",
	"seed",
	"stable_seat_ids",
]
const DEVELOPER_ADMISSION_REQUEST_KIND: String = "developer_only_explicit_launch"
const NORMAL_DEFAULT_TALE: String = "lantern_house_vertical_slice"

var _provider := DrownedHarborAlpha3ScopedProvider.new()
var _session: DrownedHarborAlpha3Session = null
var _last_request: Dictionary = {}


func admit(request: Dictionary) -> Dictionary:
	var rejection: String = _validate_request(request)
	if not rejection.is_empty():
		return _rejected(rejection)
	var candidate: Dictionary = _provider.build_candidate()
	if not candidate.get("accepted", false):
		return candidate
	var pending := DrownedHarborAlpha3Session.new(
		candidate, request.seed, PackedStringArray(request.stable_seat_ids), request.mode_id
	)
	_session = pending
	_last_request = request.duplicate(true)
	return {
		"accepted": true,
		"reason": "",
		"tale_id": DrownedHarborAlpha3ScopedProvider.TALE_ID,
		"provider_id": DrownedHarborAlpha3ScopedProvider.PROVIDER_ID,
		"provider_version": DrownedHarborAlpha3ScopedProvider.PROVIDER_VERSION,
		"session": _session,
	}


func restore(request: Dictionary, snapshot: Dictionary) -> Dictionary:
	var rejection: String = _validate_request(request)
	if not rejection.is_empty():
		return _rejected(rejection)
	var candidate: Dictionary = _provider.build_candidate()
	if not candidate.get("accepted", false):
		return candidate
	var restored: Dictionary = DrownedHarborAlpha3Session.restore_candidate(candidate, snapshot)
	if not restored.get("accepted", false):
		return restored
	if (
		restored.session.to_snapshot().seed != request.seed
		or restored.session.to_snapshot().stable_seat_order != request.stable_seat_ids
	):
		return _rejected("restore_admission_mismatch")
	_session = restored.session
	_last_request = request.duplicate(true)
	return {"accepted": true, "reason": "", "session": _session}


func migrate_alpha2_snapshot(request: Dictionary, alpha2_snapshot: Dictionary) -> Dictionary:
	var rejection: String = _validate_request(request)
	if not rejection.is_empty():
		return _rejected(rejection)
	if (
		alpha2_snapshot.get("seed") != request.seed
		or alpha2_snapshot.get("stable_seat_order") != request.stable_seat_ids
	):
		return _rejected("migration_admission_mismatch")
	var candidate: Dictionary = _provider.build_candidate()
	if not candidate.get("accepted", false):
		return candidate
	var migrated: Dictionary = DrownedHarborAlpha3Session.migrate_alpha2_candidate(
		candidate, alpha2_snapshot, request.mode_id
	)
	if not migrated.get("accepted", false):
		return migrated
	_session = migrated.session
	_last_request = request.duplicate(true)
	return migrated


func rematch(cleanup_request: Dictionary) -> Dictionary:
	if _session == null or _last_request.is_empty():
		return _rejected("no_alpha3_session")
	var cleanup: Dictionary = _session.process_request(cleanup_request)
	if not cleanup.get("accepted", false) or cleanup.get("next_destination") != "rematch":
		return cleanup
	var candidate: Dictionary = _provider.build_candidate()
	if not candidate.get("accepted", false):
		return candidate
	_session = DrownedHarborAlpha3Session.new(
		candidate,
		_last_request.seed,
		PackedStringArray(_last_request.stable_seat_ids),
		_last_request.mode_id
	)
	return {"accepted": true, "reason": "", "session": _session}


func exit_to_normal_default(cleanup_request: Dictionary) -> Dictionary:
	if _session == null:
		return _rejected("no_alpha3_session")
	var cleanup: Dictionary = _session.process_request(cleanup_request)
	if not cleanup.get("accepted", false) or cleanup.get("next_destination") != "normal_title":
		return cleanup
	_clear_session()
	return {"accepted": true, "reason": "", "selected_tale_id": NORMAL_DEFAULT_TALE}


func rollback() -> Dictionary:
	_clear_session()
	return {"accepted": true, "reason": "", "selected_tale_id": NORMAL_DEFAULT_TALE}


func active_session() -> DrownedHarborAlpha3Session:
	return _session


func has_active_session() -> bool:
	return _session != null


func _clear_session() -> void:
	_session = null
	_last_request.clear()


func _validate_request(request: Dictionary) -> String:
	if not _has_exact_keys(request, REQUEST_KEYS):
		return "malformed_admission_request"
	if (
		request.request_kind != DEVELOPER_ADMISSION_REQUEST_KIND
		or request.developer_mode != true
		or request.tale_id != DrownedHarborAlpha3ScopedProvider.TALE_ID
		or request.package_kind != "tale"
		or request.schema_version != 1
		or request.package_version != 3
		or request.provider_id != DrownedHarborAlpha3ScopedProvider.PROVIDER_ID
		or request.provider_version != DrownedHarborAlpha3ScopedProvider.PROVIDER_VERSION
		or not request.mode_id in ["cooperative", "hidden_betrayer", "outbreak"]
		or not request.seed is int
		or request.seed < 1
	):
		return "unauthorized_admission_identity"
	if (
		not request.stable_seat_ids is Array
		or request.stable_seat_ids.is_empty()
		or request.stable_seat_ids.size() > SeatManager.MAX_SEATS
	):
		return "malformed_stable_seats"
	var seen: Dictionary = {}
	for stable_seat_id: Variant in request.stable_seat_ids:
		if (
			not stable_seat_id is String
			or not String(stable_seat_id).begins_with("seat_")
			or seen.has(stable_seat_id)
		):
			return "malformed_stable_seats"
		seen[stable_seat_id] = true
	return ""


static func _has_exact_keys(value: Dictionary, expected: PackedStringArray) -> bool:
	if value.size() != expected.size():
		return false
	for key: Variant in value:
		if not key is String or not expected.has(key):
			return false
	return true


static func _rejected(reason: String) -> Dictionary:
	return {"accepted": false, "reason": reason, "diagnostics": [{"code": reason}]}
