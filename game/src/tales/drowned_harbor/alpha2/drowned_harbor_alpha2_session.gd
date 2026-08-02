class_name DrownedHarborAlpha2Session
extends RefCounted

signal public_event_committed(event: Dictionary)

const SNAPSHOT_VERSION: int = 2
const REQUEST_KEYS: PackedStringArray = [
	"request_id", "event_id", "actor", "stable_seat_id", "source_revision", "intent", "payload"
]
const RNG_STREAMS: PackedStringArray = [
	"drowned_harbor_route_authority",
	"drowned_harbor_board_authority",
	"drowned_harbor_social_authority",
	"drowned_harbor_director_authority",
]
const MAX_REJECTIONS_BEFORE_DIAGNOSTIC: int = 8
const SNAPSHOT_KEYS: PackedStringArray = [
	"tale_id",
	"package_kind",
	"package_schema_version",
	"package_version",
	"provider_id",
	"snapshot_version",
	"scenario_id",
	"scenario_version",
	"seed",
	"authoritative_revision",
	"stage_id",
	"stable_seat_order",
	"rng_streams",
	"processed_request_ids",
	"processed_event_ids",
	"board",
	"rules",
	"role",
	"public_history",
	"replay",
	"transcript",
	"mirror",
	"checkpoints",
	"migration",
	"active",
	"cleanup_complete",
	"next_destination",
]

var _candidate: Dictionary = {}
var _seed: int = 1
var _revision: int = 0
var _stable_seat_order: Array[String] = []
var _rng_streams: Dictionary = {}
var _processed_request_ids: Array[String] = []
var _processed_event_ids: Array[String] = []
var _board: DrownedHarborAlpha2BoardAuthority
var _rules: DrownedHarborAlpha2RulesAuthority
var _role: DrownedHarborAlpha2RoleAuthority
var _public_history: Array[Dictionary] = []
var _replay: Array[Dictionary] = []
var _transcript: Array[Dictionary] = []
var _mirror: Array[Dictionary] = []
var _checkpoints: Array[Dictionary] = []
var _migration: Dictionary = {}
var _active: bool = true
var _cleanup_complete: bool = false
var _next_destination: String = ""
var _rejection_streak: int = 0


func _init(
	candidate: Dictionary = {},
	seed: int = 1,
	stable_seat_ids: PackedStringArray = PackedStringArray()
) -> void:
	_candidate = candidate.duplicate(false)
	_seed = seed
	for stable_seat_id: String in stable_seat_ids:
		_stable_seat_order.append(stable_seat_id)
	_board = DrownedHarborAlpha2BoardAuthority.new(stable_seat_ids)
	_rules = DrownedHarborAlpha2RulesAuthority.new()
	_role = DrownedHarborAlpha2RoleAuthority.new(stable_seat_ids)
	_initialize_rng_streams()
	_append_checkpoint("stage_entry_low_tide_arrival_v1")


func process_request(request: Dictionary) -> Dictionary:
	var before: Dictionary = to_snapshot()
	var rejection: String = _request_rejection(request)
	if not rejection.is_empty():
		return _no_op_rejection(rejection, before)
	var probe_result: Dictionary = _build_probe()
	if not probe_result.get("accepted", false):
		return _no_op_rejection(probe_result.reason, before)
	var probe: DrownedHarborAlpha2Session = probe_result.session
	var applied: Dictionary = probe._apply_valid_request(request)
	if not applied.get("accepted", false):
		return _no_op_rejection(applied.get("reason", "candidate_rejected"), before)
	var candidate_snapshot: Dictionary = probe.to_snapshot()
	var candidate_validation: Dictionary = validate_snapshot(_candidate, candidate_snapshot)
	if not candidate_validation.get("accepted", false):
		return _no_op_rejection("candidate_snapshot_invalid", before)
	var adoption: Dictionary = _adopt_snapshot(candidate_snapshot)
	if not adoption.get("accepted", false):
		return _no_op_rejection("candidate_commit_failed", before)
	_rejection_streak = 0
	if applied.has("public_event"):
		public_event_committed.emit(applied.public_event.duplicate(true))
	return applied


func disconnect_seat(stable_seat_id: String) -> Dictionary:
	return _apply_connection_change(stable_seat_id, false, false, "disconnect")


func assign_surrogate_control(stable_seat_id: String) -> Dictionary:
	return _apply_connection_change(stable_seat_id, true, true, "surrogate_control")


func reconnect_seat(stable_seat_id: String) -> Dictionary:
	return _apply_connection_change(stable_seat_id, true, false, "reconnect")


func interrupt_presentation() -> Dictionary:
	var before: Dictionary = to_snapshot()
	var result: Dictionary = {
		"accepted": true,
		"reason": "",
		"authoritative_state_preserved": true,
		"public_recap": public_projection(),
	}
	assert(to_snapshot() == before)
	return result


func simulate_projection_failure() -> Dictionary:
	var before: Dictionary = to_snapshot()
	var result: Dictionary = {
		"accepted": false,
		"reason": "projection_unavailable",
		"state_and_rng_unchanged": true,
		"recovery": "restore_exact_checkpoint_or_reproject_committed_result",
	}
	assert(to_snapshot() == before)
	return result


func reproject_committed_result(identity_kind: String) -> Dictionary:
	var before: Dictionary = to_snapshot()
	var identity: String = ""
	match identity_kind:
		"council_commitment_id":
			identity = _rules.council_commitment_id()
		"high_water_transformation_id":
			identity = _rules.high_water_transformation_id()
		_:
			return _no_op_rejection("unsupported_reprojection_identity", before)
	if identity.is_empty():
		return _no_op_rejection("committed_result_unavailable", before)
	var result: Dictionary = {
		"accepted": true,
		"reason": "",
		"reprojected": true,
		"identity_kind": identity_kind,
		"identity": identity,
		"public_projection": public_projection(),
	}
	assert(to_snapshot() == before)
	return result


func public_projection() -> Dictionary:
	if _cleanup_complete:
		return {
			"tale_id": "drowned_harbor",
			"stage_id": "rematch_title_cleanup_v1",
			"authoritative_revision": _revision,
			"cleanup_complete": true,
			"next_destination": _next_destination,
			"public_history": _public_history.duplicate(true),
			"replay": _replay.duplicate(true),
			"transcript": _transcript.duplicate(true),
			"mirror": _mirror.duplicate(true),
		}
	return {
		"tale_id": "drowned_harbor",
		"stage_id": _rules.stage_id(),
		"authoritative_revision": _revision,
		"board": _board.public_view(),
		"rules": _rules.public_view(),
		"roles": _role.public_view(),
		"public_history": _public_history.duplicate(true),
		"replay": _replay.duplicate(true),
		"transcript": _transcript.duplicate(true),
		"mirror": _mirror.duplicate(true),
		"cleanup_complete": false,
		"next_destination": "",
	}


func seat_private_projection(stable_seat_id: String) -> Dictionary:
	if _cleanup_complete:
		return {}
	return _role.seat_private_view(stable_seat_id)


func director_safe_input() -> Dictionary:
	var connected: Array[String] = _connected_seats()
	var stage_index: int = (
		DrownedHarborAlpha2RulesAuthority.STAGE_ORDER.find(_rules.stage_id())
		if not _cleanup_complete
		else DrownedHarborAlpha2RulesAuthority.STAGE_ORDER.size() - 1
	)
	return {
		"authoritative_revision": _revision,
		"connected_seat_count": connected.size(),
		"stage_id": "rematch_title_cleanup_v1" if _cleanup_complete else _rules.stage_id(),
		"public_progress": stage_index,
		"public_pressure": 0,
		"public_recovery_count": 0,
	}


func to_snapshot() -> Dictionary:
	return {
		"tale_id": "drowned_harbor",
		"package_kind": "tale",
		"package_schema_version": 1,
		"package_version": 2,
		"provider_id": "drowned_harbor_authorities_v1",
		"snapshot_version": SNAPSHOT_VERSION,
		"scenario_id": "drowned_harbor_graybox_v2",
		"scenario_version": 2,
		"seed": _seed,
		"authoritative_revision": _revision,
		"stage_id": "rematch_title_cleanup_v1" if _cleanup_complete else _rules.stage_id(),
		"stable_seat_order": _stable_seat_order.duplicate(),
		"rng_streams": {} if _cleanup_complete else _rng_snapshot(),
		"processed_request_ids": _processed_request_ids.duplicate(),
		"processed_event_ids": _processed_event_ids.duplicate(),
		"board": {} if _cleanup_complete else _board.to_snapshot(),
		"rules": {} if _cleanup_complete else _rules.to_snapshot(),
		"role": {} if _cleanup_complete else _role.to_snapshot(),
		"public_history": _public_history.duplicate(true),
		"replay": _replay.duplicate(true),
		"transcript": _transcript.duplicate(true),
		"mirror": _mirror.duplicate(true),
		"checkpoints": _checkpoints.duplicate(true),
		"migration": _migration.duplicate(true),
		"active": _active,
		"cleanup_complete": _cleanup_complete,
		"next_destination": _next_destination,
	}


static func restore_candidate(candidate: Dictionary, snapshot: Dictionary) -> Dictionary:
	var validation: Dictionary = validate_snapshot(candidate, snapshot)
	if not validation.get("accepted", false):
		return validation
	var restored := DrownedHarborAlpha2Session.new(
		candidate, snapshot.seed, PackedStringArray(snapshot.stable_seat_order)
	)
	var adoption: Dictionary = restored._adopt_snapshot(snapshot)
	if not adoption.get("accepted", false):
		return adoption
	return {"accepted": true, "reason": "", "session": restored}


static func validate_snapshot(candidate: Dictionary, snapshot: Dictionary) -> Dictionary:
	for identity: Array in [
		["tale_id", "drowned_harbor", "unsupported_tale_identity"],
		["package_kind", "tale", "unsupported_package_kind"],
		["package_schema_version", 1, "unsupported_package_version"],
		["package_version", 2, "unsupported_package_version"],
		["provider_id", "drowned_harbor_authorities_v1", "unsupported_provider_identity"],
		["snapshot_version", SNAPSHOT_VERSION, "unsupported_snapshot_version"],
		["scenario_id", "drowned_harbor_graybox_v2", "unsupported_scenario_identity"],
		["scenario_version", 2, "unsupported_scenario_version"],
	]:
		if snapshot.get(identity[0]) != identity[1]:
			return _rejected_static(identity[2])
	if not _has_exact_keys(snapshot, SNAPSHOT_KEYS):
		return _rejected_static("malformed_snapshot")
	if (
		not snapshot.get("seed") is int
		or snapshot.get("seed", 0) < 1
		or not snapshot.get("authoritative_revision") is int
		or snapshot.get("authoritative_revision", -1) < 0
		or not snapshot.get("stable_seat_order") is Array
		or snapshot.stable_seat_order.is_empty()
		or snapshot.stable_seat_order.size() > SeatManager.MAX_SEATS
		or not _unique_strings(snapshot.stable_seat_order)
		or not snapshot.get("processed_request_ids") is Array
		or not snapshot.get("processed_event_ids") is Array
		or not _unique_strings(snapshot.processed_request_ids)
		or not _unique_strings(snapshot.processed_event_ids)
		or not snapshot.get("public_history") is Array
		or not snapshot.get("replay") is Array
		or not snapshot.get("transcript") is Array
		or not snapshot.get("mirror") is Array
		or not snapshot.get("checkpoints") is Array
		or not snapshot.get("migration") is Dictionary
		or not snapshot.get("active") is bool
		or not snapshot.get("cleanup_complete") is bool
		or not snapshot.get("next_destination") is String
	):
		return _rejected_static("malformed_snapshot")
	if (
		snapshot.public_history.size() != snapshot.replay.size()
		or snapshot.public_history.size() != snapshot.transcript.size()
		or snapshot.public_history.size() != snapshot.mirror.size()
	):
		return _rejected_static("public_evidence_cardinality_mismatch")
	if snapshot.cleanup_complete:
		if (
			snapshot.active
			or not snapshot.board.is_empty()
			or not snapshot.rules.is_empty()
			or not snapshot.role.is_empty()
			or not snapshot.rng_streams.is_empty()
			or not snapshot.next_destination in ["rematch", "normal_title"]
		):
			return _rejected_static("malformed_terminal_cleanup")
		return {"accepted": true, "reason": ""}
	if (
		not candidate.get("accepted", false)
		or not snapshot.active
		or not snapshot.get("board") is Dictionary
		or not snapshot.get("rules") is Dictionary
		or not snapshot.get("role") is Dictionary
		or not snapshot.get("rng_streams") is Dictionary
		or not _same_key_inventory(snapshot.rng_streams, Array(RNG_STREAMS))
		or not snapshot.get("stage_id") in Array(DrownedHarborAlpha2RulesAuthority.STAGE_ORDER)
	):
		return _rejected_static("malformed_snapshot")
	return {"accepted": true, "reason": ""}


func set_migration_receipt(receipt: Dictionary) -> void:
	_migration = receipt.duplicate(true)
	_append_checkpoint("alpha1_snapshot_v1_migrated")


func _apply_valid_request(request: Dictionary) -> Dictionary:
	var event_result: Dictionary
	if _rules.stage_id() == "rematch_title_cleanup_v1":
		if not request.payload.is_empty():
			return _rejected("malformed_cleanup_request")
		if request.stable_seat_id != _connected_seats()[0]:
			return _rejected("wrong_action_owner")
		var destination: String = (
			"rematch" if request.intent == "request_rematch" else "normal_title"
		)
		event_result = _rules.complete_cleanup(destination, _revision + 1)
	else:
		event_result = _rules.apply_intent(
			request, _stable_seat_order, _connected_seats(), _board, _role, _seed, _revision
		)
		if event_result.get("accepted", false) and request.intent == "acknowledge_epilogue":
			event_result = _rules.advance_cleanup_transition(_revision + 1)
	if not event_result.get("accepted", false):
		return event_result
	_revision += 1
	_processed_request_ids.append(request.request_id)
	_processed_event_ids.append(request.event_id)
	var result: Dictionary = {
		"accepted": true,
		"reason": "",
		"authoritative_revision": _revision,
		"stage_id": _rules.stage_id(),
	}
	if event_result.has("public_event"):
		var event: Dictionary = event_result.public_event.duplicate(true)
		event.revision = _revision
		event.event_identity = _public_event_identity(event)
		_append_public_evidence(event)
		_append_checkpoint("after_%s" % event.get("event_key", "event"))
		result.public_event = event.duplicate(true)
	if _rules.stage_id() == "rematch_title_cleanup_v1" and not _cleanup_complete:
		_append_checkpoint("stage_entry_rematch_title_cleanup_v1")
	if event_result.get("public_event", {}).get("event_key") == "drowned_harbor_session_cleared":
		_cleanup_complete = true
		_active = false
		_next_destination = event_result.public_event.next_destination
		_board.clear()
		_rules.clear()
		_role.clear()
		_rng_streams.clear()
		result.cleanup_complete = true
		result.next_destination = _next_destination
	return result


func _apply_connection_change(
	stable_seat_id: String, connected: bool, surrogate: bool, checkpoint_kind: String
) -> Dictionary:
	var before_rng: Dictionary = _rng_snapshot()
	if _cleanup_complete or not _stable_seat_order.has(stable_seat_id):
		return _rejected("wrong_stable_seat")
	var board_result: Dictionary = _board.set_connection(stable_seat_id, connected)
	var role_result: Dictionary = _role.set_connection(stable_seat_id, connected, surrogate)
	if not board_result.get("accepted", false) or not role_result.get("accepted", false):
		return _rejected("connection_change_rejected")
	_revision += 1
	_append_checkpoint("%s_%s" % [checkpoint_kind, stable_seat_id])
	assert(_rng_snapshot() == before_rng)
	return {
		"accepted": true,
		"reason": "",
		"stable_seat_id": stable_seat_id,
		"authoritative_revision": _revision,
	}


func _request_rejection(request: Dictionary) -> String:
	var reason: String = _request_shape_rejection(request)
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
		elif key == "payload":
			if not request.get(key) is Dictionary:
				return "malformed_request"
		elif not request.get(key) is String or request.get(key, "").is_empty():
			return "malformed_request"
	return ""


func _request_identity_rejection(request: Dictionary) -> String:
	var reason: String = ""
	if _processed_request_ids.has(request.request_id):
		reason = "duplicate_request"
	elif _processed_event_ids.has(request.event_id):
		reason = "duplicate_event"
	elif not _active or _cleanup_complete:
		reason = "unavailable"
	elif request.actor != "developer_alpha2_gate":
		reason = "unauthorized_actor"
	elif not _stable_seat_order.has(request.stable_seat_id):
		reason = "wrong_stable_seat"
	elif not _connected_seats().has(request.stable_seat_id):
		reason = "seat_control_unavailable"
	return reason


func _request_state_rejection(request: Dictionary) -> String:
	if request.source_revision != _revision:
		return "stale_revision"
	return ""


func _build_probe() -> Dictionary:
	var probe := DrownedHarborAlpha2Session.new(
		_candidate, _seed, PackedStringArray(_stable_seat_order)
	)
	var restored: Dictionary = probe._adopt_snapshot(to_snapshot())
	if not restored.get("accepted", false):
		return _rejected("probe_restore_failed")
	return {"accepted": true, "reason": "", "session": probe}


func _adopt_snapshot(snapshot: Dictionary) -> Dictionary:
	var validation: Dictionary = validate_snapshot(_candidate, snapshot)
	if not validation.get("accepted", false):
		return validation
	_seed = snapshot.seed
	_revision = snapshot.authoritative_revision
	_stable_seat_order = _string_array(snapshot.stable_seat_order)
	_processed_request_ids = _string_array(snapshot.processed_request_ids)
	_processed_event_ids = _string_array(snapshot.processed_event_ids)
	_public_history = _dictionary_array(snapshot.public_history)
	_replay = _dictionary_array(snapshot.replay)
	_transcript = _dictionary_array(snapshot.transcript)
	_mirror = _dictionary_array(snapshot.mirror)
	_checkpoints = _dictionary_array(snapshot.checkpoints)
	_migration = snapshot.migration.duplicate(true)
	_active = snapshot.active
	_cleanup_complete = snapshot.cleanup_complete
	_next_destination = snapshot.next_destination
	if _cleanup_complete:
		_board.clear()
		_rules.clear()
		_role.clear()
		_rng_streams.clear()
		return {"accepted": true, "reason": ""}
	var board_result: Dictionary = _board.restore_snapshot(snapshot.board)
	var rules_result: Dictionary = _rules.restore_snapshot(snapshot.rules)
	var role_result: Dictionary = _role.restore_snapshot(snapshot.role)
	if (
		not board_result.get("accepted", false)
		or not rules_result.get("accepted", false)
		or not role_result.get("accepted", false)
	):
		return _rejected("authority_snapshot_restore_failed")
	var rng_result: Dictionary = _restore_rng(snapshot.rng_streams)
	if not rng_result.get("accepted", false):
		return rng_result
	return {"accepted": true, "reason": ""}


func _initialize_rng_streams() -> void:
	_rng_streams.clear()
	for index: int in RNG_STREAMS.size():
		var generator := RandomNumberGenerator.new()
		generator.seed = _seed + (index + 1) * 1009
		_rng_streams[RNG_STREAMS[index]] = generator


func _rng_snapshot() -> Dictionary:
	var result: Dictionary = {}
	for stream_name: String in RNG_STREAMS:
		var generator: RandomNumberGenerator = _rng_streams[stream_name]
		result[stream_name] = {"seed": generator.seed, "state": generator.state}
	return result


func _restore_rng(snapshot: Dictionary) -> Dictionary:
	if not _same_key_inventory(snapshot, Array(RNG_STREAMS)):
		return _rejected("malformed_rng_snapshot")
	var next_streams: Dictionary = {}
	for stream_name: String in RNG_STREAMS:
		var row: Variant = snapshot.get(stream_name)
		if (
			not row is Dictionary
			or row.keys().size() != 2
			or not row.get("seed") is int
			or not row.get("state") is int
		):
			return _rejected("malformed_rng_snapshot")
		var generator := RandomNumberGenerator.new()
		generator.seed = row.seed
		generator.state = row.state
		next_streams[stream_name] = generator
	_rng_streams = next_streams
	return {"accepted": true, "reason": ""}


func _append_public_evidence(event: Dictionary) -> void:
	_public_history.append(event.duplicate(true))
	(
		_replay
		. append(
			{
				"event_identity": event.event_identity,
				"event_key": event.event_key,
				"revision": event.revision,
			}
		)
	)
	(
		_transcript
		. append(
			{
				"event_identity": event.event_identity,
				"caption": _caption_for_event(event.event_key),
				"revision": event.revision,
			}
		)
	)
	(
		_mirror
		. append(
			{
				"event_identity": event.event_identity,
				"event_key": event.event_key,
				"classification": "public",
			}
		)
	)


func _append_checkpoint(checkpoint_id: String) -> void:
	(
		_checkpoints
		. append(
			{
				"checkpoint_id": checkpoint_id,
				"stage_id": "rematch_title_cleanup_v1" if _cleanup_complete else _rules.stage_id(),
				"authoritative_revision": _revision,
				"rng_digest": JSON.stringify(_rng_snapshot(), "", true).sha256_text(),
			}
		)
	)


func _connected_seats() -> Array[String]:
	var result: Array[String] = []
	if _cleanup_complete:
		return result
	var public_roles: Dictionary = _role.public_view()
	for stable_seat_id: String in _stable_seat_order:
		for row: Dictionary in public_roles.seats:
			if row.stable_seat_id == stable_seat_id and row.connected:
				result.append(stable_seat_id)
				break
	return result


func _public_event_identity(event: Dictionary) -> String:
	var identity_component: String = event.get(
		"council_commitment_id", event.get("high_water_transformation_id", "")
	)
	return (
		("drowned_harbor|%s|%d|%d|%s" % [event.event_key, _seed, _revision, identity_component])
		. sha256_text()
	)


func _no_op_rejection(reason: String, before: Dictionary) -> Dictionary:
	_rejection_streak += 1
	var diagnostics: Array[Dictionary] = [
		{
			"code": reason,
			"stage_id": before.stage_id,
			"retry": "refresh authoritative revision and inspect the governed public action list",
		}
	]
	if _rejection_streak >= MAX_REJECTIONS_BEFORE_DIAGNOSTIC:
		(
			diagnostics
			. append(
				{
					"code": "bounded_progress_watchdog",
					"stage_id": before.stage_id,
					"recovery":
					"restore the most recent exact checkpoint or choose a listed public intent",
				}
			)
		)
	assert(to_snapshot() == before)
	return {
		"accepted": false,
		"reason": reason,
		"state_and_rng_unchanged": true,
		"diagnostics": diagnostics,
	}


static func _caption_for_event(event_key: String) -> String:
	match event_key:
		"high_water_transformation_applied":
			return "High Water is committed. The harbor route changed atomically."
		"epilogue_acknowledged":
			return "The crew completed the cooperative harbor route."
		"drowned_harbor_session_cleared":
			return "Drowned Harbor authority cleared before title return."
		_:
			return event_key.replace("_", " ").capitalize()


static func _has_exact_keys(value: Dictionary, expected: PackedStringArray) -> bool:
	if value.size() != expected.size():
		return false
	for key: Variant in value:
		if not key is String or not expected.has(key):
			return false
	return true


static func _unique_strings(values: Array) -> bool:
	var seen: Dictionary = {}
	for value: Variant in values:
		if not value is String or value.is_empty() or seen.has(value):
			return false
		seen[value] = true
	return true


static func _same_key_inventory(value: Dictionary, expected: Array) -> bool:
	var actual_keys: Array = value.keys()
	var expected_keys: Array = expected.duplicate()
	actual_keys.sort()
	expected_keys.sort()
	return actual_keys == expected_keys


static func _string_array(values: Array) -> Array[String]:
	var result: Array[String] = []
	for value: Variant in values:
		if value is String:
			result.append(value)
	return result


static func _dictionary_array(values: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value: Variant in values:
		if value is Dictionary:
			result.append((value as Dictionary).duplicate(true))
	return result


static func _rejected(reason: String) -> Dictionary:
	return {"accepted": false, "reason": reason}


static func _rejected_static(reason: String) -> Dictionary:
	return {"accepted": false, "reason": reason, "diagnostics": [{"code": reason}]}
