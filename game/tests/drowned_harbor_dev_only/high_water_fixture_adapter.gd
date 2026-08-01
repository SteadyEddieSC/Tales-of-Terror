class_name DrownedHarborHighWaterFixtureAdapter
extends RefCounted

const FIXTURE_PATH: String = "res://tests/drowned_harbor_dev_only/state_projection_fixtures_v1.json"
const FIXTURE_ID: String = "DH-FIX-004"
const TRACE_ID: String = "DH-IS-008"
const STORYBOARD_ID: String = "DH-UI-008"
const FIXTURE_KIND: String = "once_only_public_transform_projection"
const INTENT: String = "project_high_water_transformation"
const EVENT_KEY: String = "high_water_transformation_committed"
const ONCE_ONLY_MARKER: String = "high_water_committed"
const SYNTHETIC_COUNCIL_DIRECTION: String = "synthetic_council_direction_fixture_004"
const SOURCE_REVISION: int = 41
const RESULT_REVISION: int = 42
const RNG_CURSOR: int = 12
const STABLE_SEAT_ID: String = "seat_04"
const REQUIRED_REQUEST_FIELDS: PackedStringArray = [
	"actor_kind",
	"fixture_id",
	"intent",
	"source_revision",
	"stable_seat_id",
]
const REQUIRED_ROUTE_STATES: PackedStringArray = [
	"open",
	"submerged",
	"flooded_passable",
	"water_route_only",
	"unstable",
	"collapsed",
]
const REQUIRED_PUBLIC_FIELDS: PackedStringArray = [
	"board_after",
	"board_before",
	"caption",
	"changed_categories",
	"council_direction",
	"history_label",
	"legal_inspection_actions",
	"objective_after",
	"objective_before",
	"once_only_marker",
	"persistent_summary",
	"public_hazards_after",
	"public_hazards_before",
	"public_mechanism_changes",
	"stage_after",
	"stage_before",
]
const REQUIRED_SEAT_FIELDS: PackedStringArray = [
	"condition",
	"control_source",
	"location_after",
	"location_before",
	"public_form",
	"public_form_after",
	"public_form_before",
	"seat_id",
]

var _package: Dictionary = {}
var _fixture: Dictionary = {}
var _source_fingerprint: String = ""
var _prepared: Dictionary = {}


static func authorized_request() -> Dictionary:
	return {
		"actor_kind": "system",
		"fixture_id": FIXTURE_ID,
		"intent": INTENT,
		"source_revision": SOURCE_REVISION,
		"stable_seat_id": STABLE_SEAT_ID,
	}


func load_and_prepare(
	request: Dictionary,
	already_committed: bool = false,
	path: String = FIXTURE_PATH,
) -> Dictionary:
	clear_loaded_fixture()
	var loaded: Dictionary = _load_authorized_package(already_committed, path)
	if not loaded.get("accepted", false):
		return loaded
	_fixture = _find_fixture(_package.get("fixtures", []), FIXTURE_ID)
	if _fixture.is_empty():
		return _rejected("missing_fixture", "DH-FIX-004 is unavailable")
	var fixture_validation: Dictionary = _validate_fixture()
	if not fixture_validation.get("accepted", false):
		clear_loaded_fixture()
		return fixture_validation
	var request_validation: Dictionary = _validate_request(request)
	if not request_validation.get("accepted", false):
		clear_loaded_fixture()
		return request_validation
	_source_fingerprint = _fingerprint(_fixture.get("source_state", {}))
	_prepared = _prepare_canonical_result()
	var prepared_validation: Dictionary = _validate_prepared_result()
	if not prepared_validation.get("accepted", false):
		clear_loaded_fixture()
		return prepared_validation
	return {
		"accepted": true,
		"fixture_id": FIXTURE_ID,
		"prepared": _prepared.duplicate(true),
		"source_fingerprint": _source_fingerprint,
	}


func _load_authorized_package(already_committed: bool, path: String) -> Dictionary:
	if already_committed:
		return _rejected("already_committed", "committed transformations must be reprojected")
	return _load_package(path)


func prepared_result() -> Dictionary:
	return _prepared.duplicate(true)


func state_signature() -> Dictionary:
	if _fixture.is_empty():
		return {}
	return {
		"fixture_id": _fixture.get("fixture_id", ""),
		"result_revision": _fixture.get("result_revision", -1),
		"rng_cursor": _fixture.get("rng_cursor_before", -1),
		"source_fingerprint": _source_fingerprint,
		"source_revision": _fixture.get("source_revision", -1),
		"stable_seat_id": _fixture.get("active_stable_seat_id", ""),
	}


func clear_loaded_fixture() -> void:
	_package.clear()
	_fixture.clear()
	_prepared.clear()
	_source_fingerprint = ""


func _load_package(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return _rejected("missing_fixture_package", "fixture package does not exist")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		return _rejected("malformed_fixture_package", "fixture package root must be an object")
	_package = parsed
	var fixtures: Variant = _package.get("fixtures")
	if (
		_package.get("fixture_package_kind") != "drowned_harbor_state_projection_fixtures"
		or _package.get("prototype_id") != "drowned_harbor_dev_only"
		or _package.get("status") != "synthetic_test_only_export_excluded"
		or not fixtures is Array
		or fixtures.size() != 7
	):
		return _rejected("unauthorized_fixture_package", "fixture package identity drifted")
	var fixture_ids: PackedStringArray = []
	for value: Variant in fixtures:
		if value is Dictionary:
			fixture_ids.append(str(value.get("fixture_id", "")))
	if (
		fixture_ids
		!= PackedStringArray(
			[
				"DH-FIX-001",
				"DH-FIX-002",
				"DH-FIX-003",
				"DH-FIX-004",
				"DH-FIX-005",
				"DH-FIX-006",
				"DH-FIX-007",
			]
		)
	):
		return _rejected("unauthorized_fixture_package", "fixture inventory drifted")
	return {"accepted": true}


func _validate_fixture() -> Dictionary:
	if (
		_fixture.get("fixture_id") != FIXTURE_ID
		or _fixture.get("trace_id") != TRACE_ID
		or _fixture.get("storyboard_id") != STORYBOARD_ID
		or _fixture.get("fixture_kind") != FIXTURE_KIND
		or _fixture.get("privacy_surface") != "public_shared"
		or _fixture.get("status") != "synthetic_test_only"
		or not _fixture.get("authoritative_commit") is bool
		or not _fixture.get("authoritative_commit", false)
	):
		return _rejected("malformed_transform_input", "fixture identity or authority drifted")
	if (
		_fixture.get("seed") != 6108
		or _fixture.get("source_revision") != SOURCE_REVISION
		or _fixture.get("result_revision") != RESULT_REVISION
	):
		return _rejected("malformed_transform_input", "fixture revision identity drifted")
	if (
		_fixture.get("rng_cursor_before") != RNG_CURSOR
		or _fixture.get("rng_cursor_after") != RNG_CURSOR
	):
		return _rejected("rng_mutation_detected", "High Water transformation may not use RNG")
	if (
		_fixture.get("active_stable_seat_id") != STABLE_SEAT_ID
		or _fixture.get("stable_seat_identity_before") != STABLE_SEAT_ID
		or _fixture.get("stable_seat_identity_after") != STABLE_SEAT_ID
	):
		return _rejected("stable_seat_drift", "High Water replaced the stable seat")
	return _validate_transform_domains()


func _validate_transform_domains() -> Dictionary:
	var source_state: Variant = _fixture.get("source_state")
	if not source_state is Dictionary:
		return _rejected("incomplete_transform_input", "source state is missing")
	var public_state: Variant = source_state.get("public")
	var seat_public: Variant = source_state.get("seat_public")
	if not public_state is Dictionary or not seat_public is Dictionary:
		return _rejected("incomplete_transform_input", "public transform domains are missing")
	if not _has_exact_keys_or_more(public_state, REQUIRED_PUBLIC_FIELDS):
		return _rejected("incomplete_transform_input", "public transform categories are incomplete")
	if not _has_exact_keys_or_more(seat_public, REQUIRED_SEAT_FIELDS):
		return _rejected("incomplete_transform_input", "stable-seat transform data is incomplete")
	return _validate_public_contract(public_state, seat_public)


func _validate_public_contract(public_state: Dictionary, seat_public: Dictionary) -> Dictionary:
	if (
		public_state.get("council_direction") != SYNTHETIC_COUNCIL_DIRECTION
		or public_state.get("stage_before") != "lighthouse_council"
		or public_state.get("stage_after") != "high_water"
		or public_state.get("once_only_marker") != ONCE_ONLY_MARKER
	):
		return _rejected("malformed_transform_input", "governed public identity drifted")
	if (
		seat_public.get("seat_id") != STABLE_SEAT_ID
		or seat_public.get("public_form_before") != seat_public.get("public_form_after")
		or seat_public.get("public_form_after") != seat_public.get("public_form")
	):
		return _rejected("stable_seat_drift", "stable-seat form continuity drifted")
	return _validate_routes_and_event(public_state)


func _validate_routes_and_event(public_state: Dictionary) -> Dictionary:
	var before_routes: Variant = public_state.get("board_before")
	var after_routes: Variant = public_state.get("board_after")
	if not before_routes is Dictionary or not after_routes is Dictionary:
		return _rejected("incomplete_transform_input", "before and after routes are required")
	var before_route_ids: Array = before_routes.keys()
	var after_route_ids: Array = after_routes.keys()
	before_route_ids.sort()
	after_route_ids.sort()
	if before_route_ids != after_route_ids:
		return _rejected(
			"incomplete_transform_input", "route identity changed across transformation"
		)
	var route_states: PackedStringArray = []
	for state: Variant in before_routes.values() + after_routes.values():
		route_states.append(str(state))
	for state: String in REQUIRED_ROUTE_STATES:
		if not route_states.has(state):
			return _rejected(
				"incomplete_transform_input", "required route state is absent: %s" % state
			)
	var events: Variant = _fixture.get("expected_events")
	if not events is Array or events.size() != 1:
		return _rejected("malformed_transform_input", "one governed public event is required")
	var event: Variant = events[0]
	if (
		not event is Dictionary
		or event.get("event_key") != EVENT_KEY
		or event.get("classification") != "public"
		or not event.get("exactly_once", false)
	):
		return _rejected("malformed_transform_input", "public event contract drifted")
	return {"accepted": true}


func _validate_request(request: Dictionary) -> Dictionary:
	if not _has_exact_keys(request, REQUIRED_REQUEST_FIELDS):
		return _rejected("malformed_transform_request", "request fields are incomplete or unknown")
	if request.get("fixture_id") != FIXTURE_ID:
		return _rejected("wrong_fixture", "request fixture is not DH-FIX-004")
	if request.get("source_revision") != SOURCE_REVISION:
		return _rejected("stale_source_revision", "request source revision is stale")
	return _validate_request_authority(request)


func _validate_request_authority(request: Dictionary) -> Dictionary:
	if request.get("actor_kind") != "system":
		return _rejected("unauthorized_actor", "only system authority may transform High Water")
	if request.get("stable_seat_id") != STABLE_SEAT_ID:
		return _rejected("wrong_stable_seat", "request replaced the active stable seat")
	if request.get("intent") != INTENT:
		return _rejected("unauthorized_intent", "request intent is not governed")
	return {"accepted": true}


func _validate_prepared_result() -> Dictionary:
	if _prepared.is_empty():
		return _rejected("incomplete_transform_input", "canonical transform input is incomplete")
	if _contains_private_marker(_prepared):
		return _rejected(
			"private_data_rejected", "public transformation contained private fixture data"
		)
	if _fingerprint(_fixture.get("source_state", {})) != _source_fingerprint:
		return _rejected("source_mutation_detected", "preparation changed the fixture source")
	return {"accepted": true}


func _prepare_canonical_result() -> Dictionary:
	var source_state: Dictionary = _fixture.get("source_state", {})
	var public_state: Dictionary = source_state.get("public", {})
	var seat_public: Dictionary = source_state.get("seat_public", {})
	var event_identity: String = _build_event_identity()
	if event_identity.is_empty():
		return {}
	var authoritative_state: Dictionary = {
		"council_direction": public_state.get("council_direction", ""),
		"fixture_id": FIXTURE_ID,
		"legal_inspection_actions":
		public_state.get("legal_inspection_actions", []).duplicate(true),
		"objective": public_state.get("objective_after", ""),
		"once_only_marker": public_state.get("once_only_marker", ""),
		"public_forms": {STABLE_SEAT_ID: seat_public.get("public_form_after", "")},
		"public_hazards": public_state.get("public_hazards_after", []).duplicate(true),
		"public_mechanism_changes":
		public_state.get("public_mechanism_changes", []).duplicate(true),
		"result_revision": RESULT_REVISION,
		"rng_cursor": RNG_CURSOR,
		"routes": public_state.get("board_after", {}).duplicate(true),
		"seat_positions": {STABLE_SEAT_ID: seat_public.get("location_after", "")},
		"source_revision": SOURCE_REVISION,
		"stable_seat_ids": [STABLE_SEAT_ID],
		"stage": public_state.get("stage_after", ""),
	}
	var event_payload: Dictionary = {
		"changed_categories": public_state.get("changed_categories", []).duplicate(true),
		"council_direction": public_state.get("council_direction", ""),
		"event_key": EVENT_KEY,
		"fixture_id": FIXTURE_ID,
		"result_revision": RESULT_REVISION,
		"seat_id": STABLE_SEAT_ID,
		"source_revision": SOURCE_REVISION,
		"stage": public_state.get("stage_after", ""),
	}
	return {
		"authoritative_state": authoritative_state,
		"before_state":
		{
			"council_direction": public_state.get("council_direction", ""),
			"objective": public_state.get("objective_before", ""),
			"public_form": seat_public.get("public_form_before", ""),
			"public_hazards": public_state.get("public_hazards_before", []).duplicate(true),
			"routes": public_state.get("board_before", {}).duplicate(true),
			"seat_location": seat_public.get("location_before", ""),
			"stage": public_state.get("stage_before", ""),
		},
		"caption": public_state.get("caption", ""),
		"changed_categories": public_state.get("changed_categories", []).duplicate(true),
		"event_identity": event_identity,
		"event_payload": event_payload,
		"history_label": public_state.get("history_label", ""),
		"persistent_summary": public_state.get("persistent_summary", ""),
		"transformed_projection":
		{
			"geography_identity": "recognizable_low_tide_geography_under_high_water",
			"legal_inspection_actions":
			public_state.get("legal_inspection_actions", []).duplicate(true),
			"objective": public_state.get("objective_after", ""),
			"placeholder_geometry": true,
			"public_forms": {STABLE_SEAT_ID: seat_public.get("public_form_after", "")},
			"public_hazards": public_state.get("public_hazards_after", []).duplicate(true),
			"route_state_legend":
			{
				"collapsed": "X-shape / broken hatch",
				"damaged": "split outline / diagonal scar",
				"flooded_passable": "double line / shallow-wave pattern",
				"open": "solid line / OPEN label",
				"submerged": "dotted line / SUBMERGED label",
				"unstable": "zigzag line / UNSTABLE label",
				"water_only": "wave line / WATER ONLY label",
			},
			"routes": public_state.get("board_after", {}).duplicate(true),
			"seat_positions": {STABLE_SEAT_ID: seat_public.get("location_after", "")},
			"stage": public_state.get("stage_after", ""),
		},
	}


func _build_event_identity() -> String:
	return ("%s|%d|%d|%s" % [FIXTURE_ID, SOURCE_REVISION, RESULT_REVISION, EVENT_KEY]).sha256_text()


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


static func _has_exact_keys_or_more(value: Dictionary, required: PackedStringArray) -> bool:
	for key: String in required:
		if not value.has(key):
			return false
	return true


static func _fingerprint(value: Variant) -> String:
	return JSON.stringify(value, "", true).sha256_text()


static func _contains_private_marker(value: Variant) -> bool:
	return "PRIVATE_" in JSON.stringify(value, "", true)


static func _rejected(code: String, message: String) -> Dictionary:
	return {
		"accepted": false,
		"code": code,
		"diagnostics": [{"code": code, "message": message}],
		"reason": "%s:%s" % [code, message],
	}
