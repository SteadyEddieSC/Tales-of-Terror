class_name DrownedHarborLowTideFixtureAdapter
extends RefCounted

const FIXTURE_PATH: String = (
	"res://tests/drowned_harbor_dev_only/state_projection_fixtures_v1.json"
)
const FIXTURE_ID: String = "DH-FIX-001"
const TRACE_ID: String = "DH-IS-003"
const STORYBOARD_ID: String = "DH-UI-003"
const REQUEST_INTENT: String = "project_low_tide_public_action"
const REQUEST_FIELDS: PackedStringArray = [
	"actor_kind",
	"fixture_id",
	"source_revision",
	"stable_seat_id",
	"intent",
]
const PUBLIC_FIELDS: PackedStringArray = [
	"active_seat",
	"caption",
	"history_label",
	"legal_actions",
	"objective",
	"resources",
	"routes",
	"stage",
	"tide_state",
]

var _fixture: Dictionary = {}
var _source_fingerprint: String = ""


func load_fixture(path: String = FIXTURE_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return _rejected("missing_fixture_package", "fixture package does not exist")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		return _rejected("malformed_fixture_package", "fixture package root must be an object")
	var package: Dictionary = parsed
	if (
		package.get("fixture_package_kind")
		!= "drowned_harbor_state_projection_fixtures"
		or package.get("schema_version") != 1
		or package.get("prototype_id") != "drowned_harbor_dev_only"
		or package.get("status") != "synthetic_test_only_export_excluded"
	):
		return _rejected("unauthorized_fixture_package", "fixture package identity is not approved")
	var fixtures: Variant = package.get("fixtures")
	if not fixtures is Array:
		return _rejected("malformed_fixture_package", "fixture inventory must be an array")
	for value: Variant in fixtures:
		if value is Dictionary and value.get("fixture_id") == FIXTURE_ID:
			return configure_fixture(value)
	return _rejected("unknown_fixture", "DH-FIX-001 is not present")


func configure_fixture(value: Dictionary) -> Dictionary:
	var validation: Dictionary = _validate_fixture(value)
	if not validation.get("accepted", false):
		return validation
	_fixture = value.duplicate(true)
	_source_fingerprint = _fingerprint(_fixture.get("source_state", {}))
	return {
		"accepted": true,
		"fixture_id": FIXTURE_ID,
		"source_revision": source_revision(),
		"source_fingerprint": _source_fingerprint,
	}


func default_request() -> Dictionary:
	if _fixture.is_empty():
		return {}
	return _fixture.get("projection_request", {}).duplicate(true)


func project(request: Dictionary) -> Dictionary:
	if _fixture.is_empty():
		return _rejected("fixture_not_loaded", "load DH-FIX-001 before projection")
	if not _has_exact_keys(request, REQUEST_FIELDS):
		return _rejected("malformed_request", "request fields are incomplete or unknown")
	if request.get("fixture_id") != FIXTURE_ID:
		return _rejected("unknown_fixture", "request fixture is not DH-FIX-001")
	if request.get("source_revision") != source_revision():
		return _rejected("stale_source_revision", "request revision is not current")
	if not _fixture.get("authorized_actor_kinds", []).has(request.get("actor_kind")):
		return _rejected("unauthorized_actor", "actor kind is not authorized")
	if request.get("stable_seat_id") != stable_seat_id():
		return _rejected("wrong_stable_seat", "request does not own the active stable seat")
	if request.get("intent") != REQUEST_INTENT:
		return _rejected("unauthorized_intent", "request intent is not approved")

	var source_state: Dictionary = _fixture.get("source_state", {})
	var public_state: Dictionary = source_state.get("public", {})
	var seat_public: Dictionary = source_state.get("seat_public", {})
	var projection: Dictionary = {
		"active_seat": seat_public.duplicate(true),
		"caption": public_state.get("caption", ""),
		"history_label": public_state.get("history_label", ""),
		"legal_actions": public_state.get("legal_actions", []).duplicate(true),
		"objective": public_state.get("objective", ""),
		"resources": public_state.get("resources", {}).duplicate(true),
		"routes": public_state.get("routes", {}).duplicate(true),
		"stage": public_state.get("stage", ""),
		"tide_state": public_state.get("tide_state", ""),
	}
	if not _has_exact_keys(projection, PUBLIC_FIELDS):
		return _rejected("malformed_public_projection", "public projection fields drifted")
	var event: Dictionary = {
		"classification": "public",
		"event_key": "low_tide_public_action_committed",
		"exactly_once": true,
		"payload": {
			"location": seat_public.get("location", ""),
			"result_revision": result_revision(),
			"seat_id": seat_public.get("seat_id", ""),
			"stage": public_state.get("stage", ""),
		},
	}
	var transcript: Array[String] = [
		str(public_state.get("objective", "")),
		str(public_state.get("caption", "")),
		"Active %s at %s"
		% [
			seat_public.get("seat_id", ""),
			seat_public.get("location", ""),
		],
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
		return _rejected("private_data_rejected", "public output contained a private marker")
	if _fingerprint(source_state) != _source_fingerprint:
		return _rejected("source_mutation_detected", "projection mutated fixture source state")
	return {
		"accepted": true,
		"diagnostics": [],
		"event": event,
		"fixture_id": FIXTURE_ID,
		"projection": projection,
		"replay": replay,
		"result_revision": result_revision(),
		"rng_cursor": rng_cursor(),
		"source_fingerprint": _source_fingerprint,
		"source_revision": source_revision(),
		"stable_seat_id": stable_seat_id(),
		"transcript": transcript,
	}


func source_revision() -> int:
	return int(_fixture.get("source_revision", -1))


func result_revision() -> int:
	return int(_fixture.get("result_revision", -1))


func rng_cursor() -> int:
	return int(_fixture.get("rng_cursor_before", -1))


func stable_seat_id() -> String:
	return str(_fixture.get("active_stable_seat_id", ""))


func source_fingerprint() -> String:
	return _source_fingerprint


func _validate_fixture(value: Dictionary) -> Dictionary:
	if (
		value.get("fixture_id") != FIXTURE_ID
		or value.get("trace_id") != TRACE_ID
		or value.get("storyboard_id") != STORYBOARD_ID
		or value.get("fixture_kind") != "public_commit_projection"
		or value.get("privacy_surface") != "public_shared"
		or value.get("status") != "synthetic_test_only"
	):
		return _rejected("unauthorized_fixture", "fixture identity or scope is not approved")
	if value.get("projection_request", {}).get("intent") != REQUEST_INTENT:
		return _rejected("unauthorized_fixture", "fixture request intent drifted")
	if value.get("source_revision") != 11 or value.get("result_revision") != 12:
		return _rejected("unauthorized_fixture", "fixture revisions drifted")
	if value.get("rng_cursor_before") != value.get("rng_cursor_after"):
		return _rejected("rng_mutation_detected", "fixture projection may not consume RNG")
	if (
		value.get("stable_seat_identity_before") != value.get("active_stable_seat_id")
		or value.get("stable_seat_identity_after") != value.get("active_stable_seat_id")
	):
		return _rejected("stable_seat_drift", "stable-seat identity is not preserved")
	var source_state: Variant = value.get("source_state")
	if not source_state is Dictionary:
		return _rejected("malformed_fixture", "source state must be an object")
	var public_state: Variant = source_state.get("public")
	var seat_public: Variant = source_state.get("seat_public")
	var private_state: Variant = source_state.get("private")
	if (
		not public_state is Dictionary
		or not seat_public is Dictionary
		or not private_state is Dictionary
	):
		return _rejected("malformed_fixture", "fixture domains are incomplete")
	if public_state.get("stage") != "low_tide_arrival":
		return _rejected("unauthorized_fixture", "fixture stage is not Low Tide Arrival")
	if public_state.get("legal_actions", []).is_empty():
		return _rejected("malformed_fixture", "fixture requires public legal actions")
	var projection_map: Dictionary = value.get("projection_map", {})
	if not projection_map.get("private", {}).is_empty():
		return _rejected("private_projection_rejected", "Low Tide shell may not map private data")
	return {"accepted": true, "diagnostics": []}


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
	var text: String = JSON.stringify(value, "", true)
	return (
		"PRIVATE_" in text
		or "bellmarked_candidate" in text
		or "archive_culvert" in text
	)


static func _rejected(code: String, message: String) -> Dictionary:
	return {
		"accepted": false,
		"diagnostics": [{"code": code, "message": message}],
		"reason": "%s:%s" % [code, message],
	}
