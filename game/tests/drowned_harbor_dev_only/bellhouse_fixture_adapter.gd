class_name DrownedHarborBellhouseFixtureAdapter
extends RefCounted

const FIXTURE_PATH: String = (
	"res://tests/drowned_harbor_dev_only/state_projection_fixtures_v1.json"
)
const DECISION_FIXTURE_ID: String = "DH-FIX-002"
const DECISION_TRACE_ID: String = "DH-IS-004"
const DECISION_STORYBOARD_ID: String = "DH-UI-004"
const DECISION_INTENT: String = "project_bellhouse_decision"
const RECOVERY_FIXTURE_ID: String = "DH-FIX-006"
const RECOVERY_TRACE_ID: String = "DH-IS-019"
const RECOVERY_STORYBOARD_ID: String = "DH-UI-019"
const RECOVERY_INTENT: String = "project_invalid_action_recovery"
const REQUEST_FIELDS: PackedStringArray = [
	"actor_kind",
	"fixture_id",
	"intent",
	"source_revision",
	"stable_seat_id",
]
const DECISION_PUBLIC_FIELDS: PackedStringArray = [
	"active_seat",
	"caption",
	"decision_options",
	"history_label",
	"ledger",
	"legal_actions",
	"objective",
	"public_consequence",
	"ring_state",
	"selected_option",
]
const RECOVERY_PUBLIC_FIELDS: PackedStringArray = [
	"active_seat",
	"caption",
	"focus_destination",
	"history_label",
	"legal_alternatives",
	"public_safe_reason",
	"rejected_action",
	"rng_changed",
	"state_changed",
]

var _decision_fixture: Dictionary = {}
var _recovery_fixture: Dictionary = {}
var _decision_fingerprint: String = ""
var _recovery_fingerprint: String = ""


func load_fixtures(path: String = FIXTURE_PATH) -> Dictionary:
	var code: String = ""
	var message: String = ""
	var package: Dictionary = {}
	if not FileAccess.file_exists(path):
		code = "missing_fixture_package"
		message = "fixture package does not exist"
	else:
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not parsed is Dictionary:
			code = "malformed_fixture_package"
			message = "fixture package root must be an object"
		else:
			package = parsed
	if code.is_empty() and not _package_is_authorized(package):
		code = "unauthorized_fixture_package"
		message = "fixture package identity is not approved"
	var fixtures: Variant = package.get("fixtures")
	if code.is_empty() and not fixtures is Array:
		code = "malformed_fixture_package"
		message = "fixture inventory must be an array"
	if code.is_empty():
		_decision_fixture = _find_fixture(fixtures, DECISION_FIXTURE_ID)
		_recovery_fixture = _find_fixture(fixtures, RECOVERY_FIXTURE_ID)
		if _decision_fixture.is_empty() or _recovery_fixture.is_empty():
			code = "missing_governed_fixture"
			message = "DH-FIX-002 and DH-FIX-006 are both required"
	if code.is_empty():
		var decision_validation: Dictionary = _validate_decision_fixture(_decision_fixture)
		var recovery_validation: Dictionary = _validate_recovery_fixture(_recovery_fixture)
		if not decision_validation.get("accepted", false):
			return decision_validation
		if not recovery_validation.get("accepted", false):
			return recovery_validation
		_decision_fixture = _decision_fixture.duplicate(true)
		_recovery_fixture = _recovery_fixture.duplicate(true)
		_decision_fingerprint = _fingerprint(_decision_fixture.get("source_state", {}))
		_recovery_fingerprint = _fingerprint(_recovery_fixture.get("source_state", {}))
		return {
			"accepted": true,
			"decision_fixture_id": DECISION_FIXTURE_ID,
			"decision_source_revision": decision_revision(),
			"recovery_fixture_id": RECOVERY_FIXTURE_ID,
			"recovery_source_revision": recovery_revision(),
		}
	return _rejected(code, message)


func default_decision_request() -> Dictionary:
	return _decision_fixture.get("projection_request", {}).duplicate(true)


func default_recovery_request() -> Dictionary:
	return _recovery_fixture.get("projection_request", {}).duplicate(true)


func project_decision(request: Dictionary) -> Dictionary:
	var validation: Dictionary = _validate_request(
		request,
		_decision_fixture,
		DECISION_FIXTURE_ID,
		DECISION_INTENT,
	)
	if not validation.get("accepted", false):
		return validation
	return _build_decision_result()


func project_recovery(request: Dictionary) -> Dictionary:
	var validation: Dictionary = _validate_request(
		request,
		_recovery_fixture,
		RECOVERY_FIXTURE_ID,
		RECOVERY_INTENT,
	)
	if not validation.get("accepted", false):
		return validation
	return _build_recovery_result()


func decision_revision() -> int:
	return int(_decision_fixture.get("source_revision", -1))


func decision_result_revision() -> int:
	return int(_decision_fixture.get("result_revision", -1))


func decision_rng_cursor() -> int:
	return int(_decision_fixture.get("rng_cursor_before", -1))


func decision_stable_seat_id() -> String:
	return str(_decision_fixture.get("active_stable_seat_id", ""))


func decision_fingerprint() -> String:
	return _decision_fingerprint


func recovery_revision() -> int:
	return int(_recovery_fixture.get("source_revision", -1))


func recovery_result_revision() -> int:
	return int(_recovery_fixture.get("result_revision", -1))


func recovery_rng_cursor() -> int:
	return int(_recovery_fixture.get("rng_cursor_before", -1))


func recovery_stable_seat_id() -> String:
	return str(_recovery_fixture.get("active_stable_seat_id", ""))


func recovery_fingerprint() -> String:
	return _recovery_fingerprint


func _build_decision_result() -> Dictionary:
	var source_state: Dictionary = _decision_fixture.get("source_state", {})
	var public_state: Dictionary = source_state.get("public", {})
	var seat_public: Dictionary = source_state.get("seat_public", {})
	var selected_option: String = str(public_state.get("selected_option", ""))
	var projection: Dictionary = {
		"active_seat": seat_public.duplicate(true),
		"caption": public_state.get("caption", ""),
		"decision_options": [selected_option],
		"history_label": public_state.get("history_label", ""),
		"ledger": public_state.get("ledger", {}).duplicate(true),
		"legal_actions": public_state.get("legal_actions", []).duplicate(true),
		"objective": public_state.get("objective", ""),
		"public_consequence": public_state.get("public_consequence", ""),
		"ring_state": public_state.get("ring_state", {}).duplicate(true),
		"selected_option": selected_option,
	}
	if not _has_exact_keys(projection, DECISION_PUBLIC_FIELDS):
		return _rejected("malformed_public_projection", "decision projection fields drifted")
	var event: Dictionary = {
		"classification": "public",
		"event_key": "bellhouse_decision_committed",
		"exactly_once": true,
		"payload": {
			"decision": selected_option,
			"result_revision": decision_result_revision(),
			"seat_id": seat_public.get("seat_id", ""),
			"unresolved_positions": public_state.get("ledger", {}).get(
				"unresolved_positions",
				-1,
			),
		},
	}
	var transcript: Array[String] = [
		str(public_state.get("objective", "")),
		str(public_state.get("caption", "")),
		str(public_state.get("public_consequence", "")),
	]
	var replay: Dictionary = {
		"classification": "public",
		"event_key": event.event_key,
		"history_label": public_state.get("history_label", ""),
		"payload": event.payload.duplicate(true),
	}
	var public_bundle: Dictionary = {
		"event": event,
		"projection": projection,
		"replay": replay,
		"transcript": transcript,
	}
	if _contains_private_marker(public_bundle):
		return _rejected("private_data_rejected", "decision output contained private data")
	if _fingerprint(source_state) != _decision_fingerprint:
		return _rejected("source_mutation_detected", "decision projection mutated source state")
	return {
		"accepted": true,
		"diagnostics": [],
		"event": event,
		"fixture_id": DECISION_FIXTURE_ID,
		"projection": projection,
		"replay": replay,
		"result_revision": decision_result_revision(),
		"rng_cursor": decision_rng_cursor(),
		"source_fingerprint": _decision_fingerprint,
		"source_revision": decision_revision(),
		"stable_seat_id": decision_stable_seat_id(),
		"transcript": transcript,
	}


func _build_recovery_result() -> Dictionary:
	var source_state: Dictionary = _recovery_fixture.get("source_state", {})
	var public_state: Dictionary = source_state.get("public", {})
	var seat_public: Dictionary = source_state.get("seat_public", {})
	var projection: Dictionary = {
		"active_seat": seat_public.duplicate(true),
		"caption": public_state.get("caption", ""),
		"focus_destination": public_state.get("focus_destination", ""),
		"history_label": public_state.get("history_label", ""),
		"legal_alternatives": public_state.get("legal_alternatives", []).duplicate(true),
		"public_safe_reason": public_state.get("public_safe_reason", ""),
		"rejected_action": public_state.get("rejected_action", ""),
		"rng_changed": public_state.get("rng_changed", true),
		"state_changed": public_state.get("state_changed", true),
	}
	if not _has_exact_keys(projection, RECOVERY_PUBLIC_FIELDS):
		return _rejected("malformed_public_projection", "recovery projection fields drifted")
	var event: Dictionary = {
		"classification": "diagnostic",
		"event_key": "invalid_action_recovery_projected",
		"exactly_once": false,
		"payload": {
			"reason": public_state.get("public_safe_reason", ""),
			"result_revision": recovery_result_revision(),
			"seat_id": seat_public.get("seat_id", ""),
			"source_revision": recovery_revision(),
		},
	}
	var transcript: Array[String] = [
		str(public_state.get("public_safe_reason", "")),
		str(public_state.get("caption", "")),
	]
	var replay: Dictionary = {
		"classification": "diagnostic",
		"event_key": event.event_key,
		"history_label": public_state.get("history_label", ""),
		"payload": event.payload.duplicate(true),
	}
	var public_bundle: Dictionary = {
		"event": event,
		"projection": projection,
		"replay": replay,
		"transcript": transcript,
	}
	if _contains_private_marker(public_bundle):
		return _rejected("private_data_rejected", "recovery output contained private data")
	if _fingerprint(source_state) != _recovery_fingerprint:
		return _rejected("source_mutation_detected", "recovery projection mutated source state")
	return {
		"accepted": true,
		"diagnostics": [],
		"event": event,
		"fixture_id": RECOVERY_FIXTURE_ID,
		"projection": projection,
		"replay": replay,
		"result_revision": recovery_result_revision(),
		"rng_cursor": recovery_rng_cursor(),
		"source_fingerprint": _recovery_fingerprint,
		"source_revision": recovery_revision(),
		"stable_seat_id": recovery_stable_seat_id(),
		"transcript": transcript,
	}


func _validate_request(
	request: Dictionary,
	fixture: Dictionary,
	fixture_id: String,
	intent: String,
) -> Dictionary:
	var code: String = ""
	var message: String = ""
	if fixture.is_empty():
		code = "fixture_not_loaded"
		message = "load governed fixtures before projection"
	elif not _has_exact_keys(request, REQUEST_FIELDS):
		code = "malformed_request"
		message = "request fields are incomplete or unknown"
	elif request.get("fixture_id") != fixture_id:
		code = "unknown_fixture"
		message = "request fixture is not authorized"
	elif request.get("source_revision") != fixture.get("source_revision"):
		code = "stale_source_revision"
		message = "request revision is not current"
	elif not fixture.get("authorized_actor_kinds", []).has(request.get("actor_kind")):
		code = "unauthorized_actor"
		message = "actor kind is not authorized"
	elif request.get("stable_seat_id") != fixture.get("active_stable_seat_id"):
		code = "wrong_stable_seat"
		message = "request does not own the active stable seat"
	elif request.get("intent") != intent:
		code = "unauthorized_intent"
		message = "request intent is not approved"
	if not code.is_empty():
		return _rejected(code, message)
	return {"accepted": true, "diagnostics": []}


func _validate_decision_fixture(value: Dictionary) -> Dictionary:
	var code: String = ""
	var message: String = ""
	var source_state: Variant = value.get("source_state")
	var public_state: Variant = {}
	if source_state is Dictionary:
		public_state = source_state.get("public")
	if (
		value.get("fixture_id") != DECISION_FIXTURE_ID
		or value.get("trace_id") != DECISION_TRACE_ID
		or value.get("storyboard_id") != DECISION_STORYBOARD_ID
		or value.get("fixture_kind") != "public_commit_projection"
		or value.get("privacy_surface") != "public_shared"
		or value.get("status") != "synthetic_test_only"
	):
		code = "unauthorized_fixture"
		message = "Bellhouse fixture identity or scope drifted"
	elif value.get("source_revision") != 21 or value.get("result_revision") != 22:
		code = "unauthorized_fixture"
		message = "Bellhouse fixture revisions drifted"
	elif value.get("rng_cursor_before") != value.get("rng_cursor_after"):
		code = "rng_mutation_detected"
		message = "Bellhouse fixture may not consume RNG"
	elif value.get("active_stable_seat_id") != "seat_02":
		code = "stable_seat_drift"
		message = "Bellhouse fixture stable seat drifted"
	elif not source_state is Dictionary or not public_state is Dictionary:
		code = "malformed_fixture"
		message = "Bellhouse public source state is required"
	elif public_state.get("stage") != "bellhouse_ledger":
		code = "unauthorized_fixture"
		message = "Bellhouse stage drifted"
	elif str(public_state.get("selected_option", "")).is_empty():
		code = "malformed_fixture"
		message = "Bellhouse selected option is required"
	elif public_state.get("legal_actions", []).is_empty():
		code = "malformed_fixture"
		message = "Bellhouse legal actions are required"
	elif not value.get("projection_map", {}).get("private", {}).is_empty():
		code = "private_projection_rejected"
		message = "Bellhouse public projection may not map private data"
	if not code.is_empty():
		return _rejected(code, message)
	return {"accepted": true, "diagnostics": []}


func _validate_recovery_fixture(value: Dictionary) -> Dictionary:
	var code: String = ""
	var message: String = ""
	var source_state: Variant = value.get("source_state")
	var public_state: Variant = {}
	if source_state is Dictionary:
		public_state = source_state.get("public")
	if (
		value.get("fixture_id") != RECOVERY_FIXTURE_ID
		or value.get("trace_id") != RECOVERY_TRACE_ID
		or value.get("storyboard_id") != RECOVERY_STORYBOARD_ID
		or value.get("fixture_kind") != "public_recovery_projection"
		or value.get("privacy_surface") != "public_shared"
		or value.get("status") != "synthetic_test_only"
	):
		code = "unauthorized_fixture"
		message = "recovery fixture identity or scope drifted"
	elif value.get("source_revision") != 61 or value.get("result_revision") != 61:
		code = "unauthorized_fixture"
		message = "recovery fixture revisions drifted"
	elif value.get("authoritative_commit") is not false:
		code = "unauthorized_fixture"
		message = "recovery fixture may not commit authoritative state"
	elif value.get("rng_cursor_before") != value.get("rng_cursor_after"):
		code = "rng_mutation_detected"
		message = "recovery fixture may not consume RNG"
	elif value.get("active_stable_seat_id") != "seat_06":
		code = "stable_seat_drift"
		message = "recovery fixture stable seat drifted"
	elif not source_state is Dictionary or not public_state is Dictionary:
		code = "malformed_fixture"
		message = "recovery public source state is required"
	elif public_state.get("state_changed") is not false:
		code = "state_mutation_detected"
		message = "recovery fixture must preserve authoritative state"
	elif public_state.get("rng_changed") is not false:
		code = "rng_mutation_detected"
		message = "recovery fixture must preserve RNG"
	elif not public_state.get("legal_alternatives", []).has(
		public_state.get("focus_destination")
	):
		code = "invalid_focus_destination"
		message = "recovery focus must target a legal alternative"
	elif not value.get("projection_map", {}).get("private", {}).is_empty():
		code = "private_projection_rejected"
		message = "recovery public projection may not map private data"
	if not code.is_empty():
		return _rejected(code, message)
	return {"accepted": true, "diagnostics": []}


static func _package_is_authorized(package: Dictionary) -> bool:
	return (
		package.get("fixture_package_kind")
		== "drowned_harbor_state_projection_fixtures"
		and package.get("schema_version") == 1
		and package.get("prototype_id") == "drowned_harbor_dev_only"
		and package.get("status") == "synthetic_test_only_export_excluded"
	)


static func _find_fixture(fixtures: Array, fixture_id: String) -> Dictionary:
	for value: Variant in fixtures:
		if value is Dictionary and value.get("fixture_id") == fixture_id:
			return value
	return {}


static func _has_exact_keys(value: Dictionary, expected: PackedStringArray) -> bool:
	var actual: PackedStringArray = []
	for key: Variant in value.keys():
		actual.append(str(key))
	actual.sort()
	var wanted: PackedStringArray = expected.duplicate()
	wanted.sort()
	return actual == wanted


static func _fingerprint(value: Variant) -> String:
	return JSON.stringify(value, "", true).sha256_text()


static func _contains_private_marker(value: Variant) -> bool:
	return "PRIVATE_" in JSON.stringify(value, "", true)


static func _rejected(code: String, message: String) -> Dictionary:
	return {
		"accepted": false,
		"diagnostics": [{"code": code, "message": message}],
		"reason": "%s:%s" % [code, message],
	}
