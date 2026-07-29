class_name DrownedHarborControlledPrivateFixtureAdapter
extends RefCounted

const FIXTURE_PATH: String = "res://tests/drowned_harbor_dev_only/state_projection_fixtures_v1.json"
const BARGAIN_FIXTURE_ID: String = "DH-FIX-003"
const INHERITED_FIXTURE_ID: String = "DH-FIX-007"
const REQUEST_FIELDS: PackedStringArray = [
	"actor_kind",
	"controller_authority_id",
	"current_counter",
	"fixture_id",
	"handoff_id",
	"handoff_revision",
	"intent",
	"neutral_shield_active",
	"privacy_surface",
	"source_revision",
	"stable_seat_id",
	"trace_id",
]
const FIXTURE_CONTRACTS: Dictionary = {
	BARGAIN_FIXTURE_ID:
	{
		"intent": "project_controlled_private_bargain",
		"private_event": "harbor_bargain_private_term_committed",
		"public_event": "harbor_bargain_public_resolution_projected",
		"storyboard_id": "DH-UI-007",
		"trace_id": "DH-IS-007",
	},
	INHERITED_FIXTURE_ID:
	{
		"intent": "project_inherited_private_state_handoff",
		"private_event": "inherited_private_state_acknowledged",
		"public_event": "stable_seat_human_takeover_committed",
		"storyboard_id": "DH-UI-016",
		"trace_id": "DH-IS-016",
	},
}

var _package: Dictionary = {}
var _fixture: Dictionary = {}
var _source_fingerprint: String = ""


static func authorized_request_for(fixture_id: String) -> Dictionary:
	if fixture_id == BARGAIN_FIXTURE_ID:
		return {
			"actor_kind": "active_stable_seat",
			"controller_authority_id": "controller_authority_03",
			"current_counter": 2,
			"fixture_id": BARGAIN_FIXTURE_ID,
			"handoff_id": "dh_private_bargain_handoff_003",
			"handoff_revision": 1,
			"intent": "project_controlled_private_bargain",
			"neutral_shield_active": true,
			"privacy_surface": "controlled_private_surface",
			"source_revision": 31,
			"stable_seat_id": "seat_03",
			"trace_id": "DH-IS-007",
		}
	if fixture_id == INHERITED_FIXTURE_ID:
		return {
			"actor_kind": "approved_takeover_controller",
			"controller_authority_id": "takeover_controller_authority_07",
			"current_counter": 3,
			"fixture_id": INHERITED_FIXTURE_ID,
			"handoff_id": "dh_inherited_state_handoff_007",
			"handoff_revision": 1,
			"intent": "project_inherited_private_state_handoff",
			"neutral_shield_active": true,
			"privacy_surface": "controlled_private_surface",
			"source_revision": 71,
			"stable_seat_id": "seat_07",
			"trace_id": "DH-IS-016",
		}
	return {}


func load_and_project(request: Dictionary, path: String = FIXTURE_PATH) -> Dictionary:
	_fixture.clear()
	_package.clear()
	_source_fingerprint = ""
	if not request.get("neutral_shield_active", false):
		return _rejected("neutral_shield_required", "enter the neutral shield before loading")
	var package_result: Dictionary = _load_package(path)
	if not package_result.get("accepted", false):
		return package_result
	_fixture = _find_fixture(_package.get("fixtures", []), str(request.get("fixture_id", "")))
	if _fixture.is_empty():
		return _rejected("unknown_handoff", "governed handoff fixture is unavailable")
	var validation: Dictionary = _validate_fixture_and_request(request)
	if not validation.get("accepted", false):
		_fixture.clear()
		_package.clear()
		return validation
	_source_fingerprint = _fingerprint(_fixture.get("source_state", {}))
	return _build_projection()


func _load_package(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return _rejected("missing_fixture_package", "fixture package does not exist")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		return _rejected("malformed_fixture_package", "fixture package root must be an object")
	_package = parsed
	if not _package_is_authorized(_package):
		return _rejected("unauthorized_fixture_package", "fixture package identity drifted")
	return {"accepted": true}


func state_signature() -> Dictionary:
	if _fixture.is_empty():
		return {}
	return {
		"fixture_id": _fixture.get("fixture_id", ""),
		"rng_cursor": _fixture.get("rng_cursor_before", -1),
		"source_fingerprint": _source_fingerprint,
		"source_revision": _fixture.get("source_revision", -1),
		"stable_seat_id": _fixture.get("active_stable_seat_id", ""),
	}


func clear_loaded_fixture() -> void:
	_fixture.clear()
	_package.clear()
	_source_fingerprint = ""


func _validate_fixture_and_request(request: Dictionary) -> Dictionary:
	if not _has_exact_keys(request, REQUEST_FIELDS):
		return _rejected("malformed_handoff", "handoff request fields are incomplete or unknown")
	var fixture_id: String = str(_fixture.get("fixture_id", ""))
	var contract: Dictionary = FIXTURE_CONTRACTS.get(fixture_id, {})
	if contract.is_empty():
		return _rejected("unknown_handoff", "fixture is not authorized for P0.17")
	var fixture_validation: Dictionary = _validate_fixture_contract(contract)
	if not fixture_validation.get("accepted", false):
		return fixture_validation
	var diagnostic: Variant = _fixture.get("source_state", {}).get("diagnostic_nonplayer")
	if not diagnostic is Dictionary:
		return _rejected("malformed_handoff", "deterministic handoff metadata is missing")
	return _validate_request_binding(request, fixture_id, contract, diagnostic)


func _validate_fixture_contract(contract: Dictionary) -> Dictionary:
	if (
		_fixture.get("trace_id") != contract.get("trace_id")
		or _fixture.get("storyboard_id") != contract.get("storyboard_id")
		or _fixture.get("fixture_kind") != "controlled_private_commit_projection"
		or _fixture.get("privacy_surface") != "controlled_private_surface"
		or _fixture.get("status") != "synthetic_test_only"
	):
		return _rejected("malformed_handoff", "fixture identity or privacy scope drifted")
	if _fixture.get("rng_cursor_before") != _fixture.get("rng_cursor_after"):
		return _rejected("rng_mutation_detected", "controlled-private projection may not use RNG")
	if (
		_fixture.get("stable_seat_identity_before") != _fixture.get("active_stable_seat_id")
		or _fixture.get("stable_seat_identity_after") != _fixture.get("active_stable_seat_id")
	):
		return _rejected("stable_seat_drift", "controlled-private handoff replaced the stable seat")
	return {"accepted": true}


func _validate_request_binding(
	request: Dictionary, fixture_id: String, contract: Dictionary, diagnostic: Dictionary
) -> Dictionary:
	var authority: Dictionary = _validate_request_authority(request, fixture_id, contract)
	if not authority.get("accepted", false):
		return authority
	return _validate_handoff_metadata(request, diagnostic)


func _validate_request_authority(
	request: Dictionary, fixture_id: String, contract: Dictionary
) -> Dictionary:
	var identity: Dictionary = _validate_request_identity(request, fixture_id)
	if not identity.get("accepted", false):
		return identity
	if request.get("stable_seat_id") != _fixture.get("active_stable_seat_id"):
		return _rejected("wrong_stable_seat", "request does not own the stable seat")
	if request.get("intent") != contract.get("intent"):
		return _rejected("malformed_handoff", "request intent is not governed")
	if request.get("privacy_surface") != "controlled_private_surface":
		return _rejected("private_surface_required", "controlled private surface is required")
	return {"accepted": true}


func _validate_request_identity(request: Dictionary, fixture_id: String) -> Dictionary:
	if request.get("fixture_id") != fixture_id:
		return _rejected("unknown_handoff", "request fixture does not match")
	if request.get("source_revision") != _fixture.get("source_revision"):
		return _rejected("stale_source_revision", "request source revision is stale")
	if not _fixture.get("authorized_actor_kinds", []).has(request.get("actor_kind")):
		return _rejected("wrong_controller_authority", "actor kind is not authorized")
	return {"accepted": true}


func _validate_handoff_metadata(request: Dictionary, diagnostic: Dictionary) -> Dictionary:
	var identity: Dictionary = _validate_handoff_identity(request, diagnostic)
	if not identity.get("accepted", false):
		return identity
	if request.get("controller_authority_id") != diagnostic.get("controller_authority_id"):
		return _rejected("wrong_controller_authority", "controller authority is not current")
	if int(request.get("current_counter", -1)) < 0:
		return _rejected("malformed_handoff", "deterministic handoff counter is invalid")
	if int(request.get("current_counter", -1)) > int(diagnostic.get("valid_until_counter", -1)):
		return _rejected("expired_handoff", "deterministic handoff counter expired")
	return {"accepted": true, "diagnostics": []}


func _validate_handoff_identity(request: Dictionary, diagnostic: Dictionary) -> Dictionary:
	if request.get("trace_id") != diagnostic.get("expected_trace_id"):
		return _rejected("unknown_handoff", "interaction trace does not match the handoff")
	if request.get("handoff_id") != diagnostic.get("handoff_id"):
		return _rejected("unknown_handoff", "handoff identity is not current")
	if request.get("handoff_revision") != diagnostic.get("handoff_revision"):
		return _rejected("stale_handoff_revision", "handoff revision is stale")
	return {"accepted": true}


func _build_projection() -> Dictionary:
	var source_state: Dictionary = _fixture.get("source_state", {})
	var public_state: Dictionary = source_state.get("public", {})
	var seat_public: Dictionary = source_state.get("seat_public", {})
	var private_state: Dictionary = source_state.get("private", {})
	var events: Array = _fixture.get("expected_events", [])
	var private_event: Dictionary = {}
	var public_event: Dictionary = {}
	for value: Variant in events:
		if not value is Dictionary:
			continue
		if value.get("classification") == "private":
			private_event = value.duplicate(true)
		elif value.get("classification") == "public":
			public_event = value.duplicate(true)
	if private_event.is_empty() or public_event.is_empty():
		return _rejected("malformed_handoff", "governed private and public events are required")
	var result: Dictionary = {
		"accepted": true,
		"fixture_id": _fixture.get("fixture_id", ""),
		"private_event": private_event,
		"private_payload": private_state.duplicate(true),
		"public_event": public_event,
		"public_resolution":
		{
			"caption": public_state.get("caption", ""),
			"history_label": public_state.get("history_label", ""),
			"public_consequence": public_state.get("public_consequence", ""),
			"public_resolution": public_state.get("public_resolution", ""),
			"seat_id": seat_public.get("seat_id", ""),
		},
		"result_revision": _fixture.get("result_revision", -1),
		"rng_cursor": _fixture.get("rng_cursor_before", -1),
		"source_fingerprint": _source_fingerprint,
		"source_revision": _fixture.get("source_revision", -1),
		"stable_seat_snapshot": seat_public.duplicate(true),
		"valid_until_counter":
		int(source_state.get("diagnostic_nonplayer", {}).get("valid_until_counter", -1)),
	}
	if _fingerprint(source_state) != _source_fingerprint:
		return _rejected("source_mutation_detected", "projection changed fixture source")
	return result


static func _package_is_authorized(package: Dictionary) -> bool:
	return (
		package.get("fixture_package_kind") == "drowned_harbor_state_projection_fixtures"
		and package.get("schema_version") == 1
		and package.get("prototype_id") == "drowned_harbor_dev_only"
		and package.get("status") == "synthetic_test_only_export_excluded"
		and package.get("fixtures", []).size() == 7
	)


static func _find_fixture(fixtures: Variant, fixture_id: String) -> Dictionary:
	if not fixtures is Array:
		return {}
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


static func _rejected(code: String, message: String) -> Dictionary:
	return {
		"accepted": false,
		"code": code,
		"diagnostics": [{"code": code, "message": message}],
		"reason": "%s:%s" % [code, message],
	}
