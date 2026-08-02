class_name DrownedHarborScaffoldSession
extends RefCounted

const SNAPSHOT_VERSION: int = 1
const RNG_STREAM_NAME: String = "drowned_harbor_scaffold_authority"
const REQUEST_KEYS: PackedStringArray = [
	"request_id", "event_id", "actor", "stable_seat_id", "source_revision", "intent"
]
const SNAPSHOT_KEYS: PackedStringArray = [
	"tale_id",
	"package_kind",
	"package_schema_version",
	"package_version",
	"provider_id",
	"snapshot_version",
	"stage_id",
	"authoritative_revision",
	"stable_seats",
	"rng",
	"processed_request_ids",
	"processed_event_ids",
	"public_history",
	"active",
	"terminal",
]

var _candidate: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _seed: int = 0
var _stage_id: String = DrownedHarborRulesContent.ENTRY_STAGE_ID
var _revision: int = 0
var _stable_seats: Array[Dictionary] = []
var _processed_request_ids: Array[String] = []
var _processed_event_ids: Array[String] = []
var _public_history: Array[Dictionary] = []
var _active: bool = true
var _terminal: bool = false


func _init(
	candidate: Dictionary = {},
	seed: int = 1,
	stable_seat_ids: PackedStringArray = PackedStringArray()
) -> void:
	_candidate = candidate.duplicate(false)
	_seed = seed
	_rng.seed = seed
	for stable_seat_id: String in stable_seat_ids:
		(
			_stable_seats
			. append(
				{
					"stable_seat_id": stable_seat_id,
					"connected": true,
					"public_form": "scaffold_observer",
				}
			)
		)


func process_request(request: Dictionary) -> Dictionary:
	var before: Dictionary = to_snapshot()
	var rejection_reason := _request_rejection_reason(request)
	if not rejection_reason.is_empty():
		return _no_op_rejection(rejection_reason, before)
	_processed_request_ids.append(request.request_id)
	_processed_event_ids.append(request.event_id)
	_revision += 1
	_stage_id = DrownedHarborRulesContent.TERMINAL_STAGE_ID
	_terminal = true
	(
		_public_history
		. append(
			{
				"event_id": request.event_id,
				"event_key": "drowned_harbor_scaffold_completed",
				"revision": _revision,
				"stable_seat_id": request.stable_seat_id,
			}
		)
	)
	return {
		"accepted": true,
		"reason": "",
		"revision": _revision,
		"event_id": request.event_id,
		"terminal": true,
	}


func _request_rejection_reason(request: Dictionary) -> String:
	var reason := _request_shape_rejection(request)
	if reason.is_empty():
		reason = _request_identity_rejection(request)
	if reason.is_empty():
		reason = _request_state_rejection(request)
	return reason


func _request_shape_rejection(request: Dictionary) -> String:
	if not _has_exact_keys(request, REQUEST_KEYS):
		return "malformed_request"
	for key: String in REQUEST_KEYS:
		if key == "source_revision":
			if not request.get(key) is int:
				return "malformed_request"
		elif not request.get(key) is String or request.get(key, "").is_empty():
			return "malformed_request"
	return ""


func _request_identity_rejection(request: Dictionary) -> String:
	if _processed_request_ids.has(request.request_id):
		return "duplicate_request"
	if _processed_event_ids.has(request.event_id):
		return "duplicate_event"
	if not _active or _terminal:
		return "unavailable"
	if request.actor != "developer_scaffold_gate":
		return "unauthorized_actor"
	if not _has_stable_seat(request.stable_seat_id):
		return "wrong_stable_seat"
	return ""


func _request_state_rejection(request: Dictionary) -> String:
	if request.source_revision != _revision:
		return "stale_revision"
	if request.intent != DrownedHarborRulesContent.EXIT_INTENT:
		return "unsupported_intent"
	return ""


func to_snapshot() -> Dictionary:
	return {
		"tale_id": DrownedHarborScopedProvider.TALE_ID,
		"package_kind": "tale",
		"package_schema_version": 1,
		"package_version": 1,
		"provider_id": DrownedHarborScopedProvider.PROVIDER_ID,
		"snapshot_version": SNAPSHOT_VERSION,
		"stage_id": _stage_id,
		"authoritative_revision": _revision,
		"stable_seats": _stable_seats.duplicate(true),
		"rng": {"stream_name": RNG_STREAM_NAME, "seed": _seed, "state": _rng.state},
		"processed_request_ids": _processed_request_ids.duplicate(),
		"processed_event_ids": _processed_event_ids.duplicate(),
		"public_history": _public_history.duplicate(true),
		"active": _active,
		"terminal": _terminal,
	}


func public_projection() -> Dictionary:
	return {
		"tale_id": DrownedHarborScopedProvider.TALE_ID,
		"stage_id": _stage_id,
		"authoritative_revision": _revision,
		"stable_seats": _stable_seats.duplicate(true),
		"public_history": _public_history.duplicate(true),
		"terminal": _terminal,
	}


func director_safe_input() -> Dictionary:
	return {
		"authoritative_revision": _revision,
		"connected_seat_count": _stable_seats.size(),
		"stage_id": _stage_id,
	}


func deactivate() -> void:
	_active = false


static func restore_candidate(candidate: Dictionary, snapshot: Dictionary) -> Dictionary:
	var identity_rejection: String = _snapshot_identity_rejection(snapshot)
	if not identity_rejection.is_empty():
		return _rejected(identity_rejection)
	if not _has_exact_keys(snapshot, SNAPSHOT_KEYS):
		return _rejected("malformed_snapshot")
	var scalar_rejection: String = _snapshot_scalar_rejection(snapshot)
	if not scalar_rejection.is_empty():
		return _rejected(scalar_rejection)
	var seat_ids := PackedStringArray()
	var seen_seats: Dictionary = {}
	for row: Variant in snapshot.stable_seats:
		if (
			not row is Dictionary
			or row.keys().size() != 3
			or not row.get("stable_seat_id") is String
			or not row.get("connected") is bool
			or row.get("public_form") != "scaffold_observer"
			or seen_seats.has(row.get("stable_seat_id"))
		):
			return _rejected("malformed_snapshot")
		seen_seats[row.stable_seat_id] = true
		seat_ids.append(row.stable_seat_id)
	if seat_ids.is_empty() or seat_ids.size() > SeatManager.MAX_SEATS:
		return _rejected("malformed_snapshot")
	var restored := DrownedHarborScaffoldSession.new(candidate, snapshot.rng.seed, seat_ids)
	restored._stage_id = snapshot.stage_id
	restored._revision = snapshot.authoritative_revision
	restored._stable_seats = snapshot.stable_seats.duplicate(true)
	restored._rng.state = snapshot.rng.state
	restored._processed_request_ids = _string_array(snapshot.processed_request_ids)
	restored._processed_event_ids = _string_array(snapshot.processed_event_ids)
	restored._public_history = _dictionary_array(snapshot.public_history)
	restored._active = snapshot.active
	restored._terminal = snapshot.terminal
	return {"accepted": true, "reason": "", "session": restored}


static func _snapshot_identity_rejection(snapshot: Dictionary) -> String:
	if snapshot.get("tale_id") != DrownedHarborScopedProvider.TALE_ID:
		return "unsupported_tale_identity"
	if snapshot.get("package_kind") != "tale":
		return "unsupported_package_kind"
	if snapshot.get("package_schema_version") != 1 or snapshot.get("package_version") != 1:
		return "unsupported_package_version"
	if snapshot.get("provider_id") != DrownedHarborScopedProvider.PROVIDER_ID:
		return "unsupported_provider_identity"
	if snapshot.get("snapshot_version") != SNAPSHOT_VERSION:
		return "unsupported_snapshot_version"
	return ""


static func _snapshot_scalar_rejection(snapshot: Dictionary) -> String:
	if (
		not snapshot.get("authoritative_revision") is int
		or snapshot.get("authoritative_revision", -1) < 0
		or not snapshot.get("stable_seats") is Array
		or not snapshot.get("processed_request_ids") is Array
		or not snapshot.get("processed_event_ids") is Array
		or not snapshot.get("public_history") is Array
		or not snapshot.get("active") is bool
		or not snapshot.get("terminal") is bool
	):
		return "malformed_snapshot"
	if not (
		snapshot.get("stage_id")
		in [DrownedHarborRulesContent.ENTRY_STAGE_ID, DrownedHarborRulesContent.TERMINAL_STAGE_ID]
	):
		return "unsupported_stage_identity"
	var rng: Variant = snapshot.get("rng")
	if (
		not rng is Dictionary
		or rng.keys().size() != 3
		or rng.get("stream_name") != RNG_STREAM_NAME
		or not rng.get("seed") is int
		or not rng.get("state") is int
	):
		return "malformed_snapshot"
	if not _unique_strings(snapshot.processed_request_ids):
		return "malformed_snapshot"
	if not _unique_strings(snapshot.processed_event_ids):
		return "malformed_snapshot"
	return ""


static func _unique_strings(values: Array) -> bool:
	var seen: Dictionary = {}
	for value: Variant in values:
		if not value is String or value.is_empty() or seen.has(value):
			return false
		seen[value] = true
	return true


static func _string_array(values: Array) -> Array[String]:
	var result: Array[String] = []
	for value: String in values:
		result.append(value)
	return result


static func _dictionary_array(values: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value: Dictionary in values:
		result.append(value.duplicate(true))
	return result


func _has_stable_seat(stable_seat_id: String) -> bool:
	return _stable_seats.any(
		func(row: Dictionary) -> bool: return row.stable_seat_id == stable_seat_id
	)


func _no_op_rejection(reason: String, before: Dictionary) -> Dictionary:
	assert(to_snapshot() == before)
	return {"accepted": false, "reason": reason, "state_and_rng_unchanged": true}


static func _has_exact_keys(value: Dictionary, expected: PackedStringArray) -> bool:
	if value.size() != expected.size():
		return false
	for key: Variant in value:
		if not key is String or not expected.has(key):
			return false
	return true


static func _rejected(reason: String) -> Dictionary:
	return {"accepted": false, "reason": reason, "diagnostics": [{"code": reason}]}
