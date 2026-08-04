class_name DrownedHarborAlpha3Session
extends RefCounted

signal public_event_committed(event: Dictionary)

const SNAPSHOT_VERSION: int = 3
const MAX_REJECTIONS_BEFORE_DIAGNOSTIC: int = 8
const REQUEST_KEYS: PackedStringArray = [
	"request_id", "event_id", "actor", "stable_seat_id", "source_revision", "intent", "payload"
]
const SNAPSHOT_KEYS: PackedStringArray = [
	"tale_id",
	"package_kind",
	"package_schema_version",
	"package_version",
	"provider_id",
	"provider_version",
	"snapshot_version",
	"scenario_id",
	"scenario_version",
	"seed",
	"authoritative_revision",
	"stable_seat_order",
	"processed_request_ids",
	"processed_event_ids",
	"route",
	"rules",
	"role",
	"director",
	"public_history",
	"replay",
	"transcript",
	"mirror",
	"checkpoints",
	"migration",
	"exactly_once_identities",
	"active",
	"cleanup_complete",
	"next_destination",
]
const ROUTE_INTENTS: PackedStringArray = [
	"move_to_landmark",
	"confirm_low_tide_arrival",
	"inspect_ledger",
	"commit_bellhouse_choice",
	"recover_bellhouse_choice",
	"submit_council_commitment",
	"resolve_council_commitment",
	"acknowledge_high_water",
	"apply_high_water_transformation",
	"move_to_last_light_route",
	"commit_last_light_action",
	"resolve_last_light",
	"resolve_ending",
	"resolve_epilogue_attribution",
	"acknowledge_epilogue",
	"request_rematch",
	"return_to_title",
]
const CONTENT_STAGE_OFFSETS: Dictionary = {
	"low_tide_arrival_v1": 0,
	"bellhouse_ledger_v1": 4,
	"lighthouse_council_v1": 8,
	"high_water_v1": 10,
	"last_light_v1": 16,
}
const DIRECTOR_CANDIDATES: PackedStringArray = [
	"harbor_pressure",
	"light_pressure",
	"memory_pressure",
	"rescue_pressure",
	"route_pressure",
]

var _candidate: Dictionary = {}
var _seed: int = 1
var _revision: int = 0
var _stable_seat_order: Array[String] = []
var _processed_request_ids: Array[String] = []
var _processed_event_ids: Array[String] = []
var _route: DrownedHarborAlpha2Session
var _rules: DrownedHarborAlpha3RulesAuthority
var _role: DrownedHarborAlpha3RoleAuthority
var _director: DrownedHarborAlpha3DirectorAuthority
var _public_history: Array[Dictionary] = []
var _replay: Array[Dictionary] = []
var _transcript: Array[Dictionary] = []
var _mirror: Array[Dictionary] = []
var _checkpoints: Array[Dictionary] = []
var _migration: Dictionary = {}
var _terminal_identities: Dictionary = {}
var _active: bool = true
var _cleanup_complete: bool = false
var _next_destination: String = ""
var _rejection_streak: int = 0


func _init(
	candidate: Dictionary = {},
	seed: int = 1,
	stable_seat_ids: PackedStringArray = PackedStringArray(),
	requested_mode: String = "cooperative"
) -> void:
	_candidate = candidate.duplicate(false)
	_seed = seed
	for stable_seat_id: String in stable_seat_ids:
		_stable_seat_order.append(stable_seat_id)
	_route = DrownedHarborAlpha2Session.new(
		candidate.get("alpha2_candidate", {}), seed, stable_seat_ids
	)
	_rules = DrownedHarborAlpha3RulesAuthority.new(seed, stable_seat_ids)
	_role = DrownedHarborAlpha3RoleAuthority.new(seed, stable_seat_ids, requested_mode)
	_director = DrownedHarborAlpha3DirectorAuthority.new(seed)
	_append_checkpoint("before_role_assignment")
	_append_checkpoint("after_role_assignment")
	_append_checkpoint("before_private_assignment")
	_append_checkpoint("after_private_assignment")


func process_request(request: Dictionary) -> Dictionary:
	var before: Dictionary = to_snapshot()
	var rejection: String = _request_rejection(request)
	if not rejection.is_empty():
		return _no_op_rejection(rejection, before)
	var result: Dictionary = _dispatch(request)
	if not result.get("accepted", false):
		assert(to_snapshot() == before)
		return _no_op_rejection(result.get("reason", "request_rejected"), before)
	_revision += 1
	_processed_request_ids.append(request.request_id)
	_processed_event_ids.append(request.event_id)
	_rejection_streak = 0
	result.authoritative_revision = _revision
	result.stage_id = stage_id()
	if result.has("event_key"):
		var event: Dictionary = _public_event(result)
		_append_public_evidence(event)
		result.public_event = event.duplicate(true)
		public_event_committed.emit(event.duplicate(true))
	if _route.to_snapshot().cleanup_complete and not _cleanup_complete:
		_terminal_identities = exactly_once_identities()
		_cleanup_complete = true
		_active = false
		_next_destination = _route.to_snapshot().next_destination
		_append_checkpoint("terminal_cleanup_complete")
		result.cleanup_complete = true
		result.next_destination = _next_destination
	return result


func disconnect_seat(stable_seat_id: String) -> Dictionary:
	return _apply_connection(stable_seat_id, "disconnect")


func assign_surrogate_control(stable_seat_id: String) -> Dictionary:
	return _apply_connection(stable_seat_id, "surrogate")


func reconnect_seat(stable_seat_id: String) -> Dictionary:
	return _apply_connection(stable_seat_id, "reconnect")


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
		"recovery": "restore_exact_checkpoint_or_reproject_existing_result",
	}
	assert(to_snapshot() == before)
	return result


func reproject_identity(identity_kind: String) -> Dictionary:
	var before: Dictionary = to_snapshot()
	var identities: Dictionary = exactly_once_identities()
	if not identities.has(identity_kind) or identities[identity_kind].is_empty():
		return _no_op_rejection("committed_identity_unavailable", before)
	var result: Dictionary = {
		"accepted": true,
		"reason": "",
		"identity_kind": identity_kind,
		"identity": identities[identity_kind],
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
		"stage_id": stage_id(),
		"authoritative_revision": _revision,
		"route": _route.public_projection(),
		"systems": _rules.public_view(),
		"roles": _role.public_view(),
		"director": _director.public_view(),
		"public_history": _public_history.duplicate(true),
		"replay": _replay.duplicate(true),
		"transcript": _transcript.duplicate(true),
		"mirror": _mirror.duplicate(true),
		"cleanup_complete": false,
		"next_destination": "",
	}


func seat_private_projection(stable_seat_id: String) -> Dictionary:
	return {} if _cleanup_complete else _role.seat_private_view(stable_seat_id)


func faction_private_projection(stable_seat_id: String) -> Dictionary:
	return {} if _cleanup_complete else _role.faction_private_view(stable_seat_id)


func director_safe_input() -> Dictionary:
	var role_public: Dictionary = _role.public_view()
	var systems_public: Dictionary = _rules.public_view()
	var route_public: Dictionary = _route.public_projection()
	return {
		"authoritative_revision": _revision,
		"connected_seat_count": _connected_seat_count(),
		"stage_id": stage_id(),
		"tide_state": route_public.get("board", {}).get("tide_state", "cleared"),
		"living_count": role_public.living_count,
		"restless_count": role_public.restless_count,
		"tidebound_count": role_public.tidebound_count,
		"unresolved_rescue_count": systems_public.unresolved_rescue_count,
		"public_resource_pressure": systems_public.public_resource_pressure,
		"recent_public_candidate_ids": _director.public_view().recent_public_candidate_ids,
		"ending_eligibility_count": systems_public.ending_eligibility_count,
	}


func exactly_once_identities() -> Dictionary:
	if _cleanup_complete and not _terminal_identities.is_empty():
		return _terminal_identities.duplicate(true)
	var route_snapshot: Dictionary = _route.to_snapshot()
	var route_rules: Dictionary = route_snapshot.get("rules", {})
	return {
		"council_commitment_id": route_rules.get("council_commitment_id", ""),
		"high_water_transformation_id": route_rules.get("high_water_transformation_id", ""),
		"role_assignment_id": _role.role_assignment_id(),
		"private_objective_assignment_id": _role.private_objective_assignment_id(),
		"faction_assignment_id": _role.faction_assignment_id(),
		"tidebound_conversion_id": _role.tidebound_conversion_id(),
		"continuation_transition_id": _role.continuation_transition_id(),
		"director_selection_id": _director.director_selection_id(),
		"ending_resolution_id": _rules.ending_resolution_id(),
	}


func stage_id() -> String:
	return "rematch_title_cleanup_v1" if _cleanup_complete else _route.to_snapshot().stage_id


func coverage_sequence_index() -> int:
	var mode_base: int = 0
	match _role.effective_mode():
		"hidden_betrayer":
			mode_base = 8 + _stable_seat_order.size() - 3
		"outbreak":
			mode_base = 14 + _stable_seat_order.size() - 2
		_:
			mode_base = _stable_seat_order.size() - 1
	return maxi(0, _seed - 3101) * 21 + mode_base


func to_snapshot() -> Dictionary:
	return {
		"tale_id": "drowned_harbor",
		"package_kind": "tale",
		"package_schema_version": 1,
		"package_version": 3,
		"provider_id": "drowned_harbor_authorities_v1",
		"provider_version": 3,
		"snapshot_version": SNAPSHOT_VERSION,
		"scenario_id": "drowned_harbor_systems_v3",
		"scenario_version": 3,
		"seed": _seed,
		"authoritative_revision": _revision,
		"stable_seat_order": _stable_seat_order.duplicate(),
		"processed_request_ids": _processed_request_ids.duplicate(),
		"processed_event_ids": _processed_event_ids.duplicate(),
		"route": _route.to_snapshot(),
		"rules": {} if _cleanup_complete else _rules.to_snapshot(),
		"role": {} if _cleanup_complete else _role.to_snapshot(),
		"director": {} if _cleanup_complete else _director.to_snapshot(),
		"public_history": _public_history.duplicate(true),
		"replay": _replay.duplicate(true),
		"transcript": _transcript.duplicate(true),
		"mirror": _mirror.duplicate(true),
		"checkpoints": _checkpoints.duplicate(true),
		"migration": _migration.duplicate(true),
		"exactly_once_identities": exactly_once_identities(),
		"active": _active,
		"cleanup_complete": _cleanup_complete,
		"next_destination": _next_destination,
	}


static func restore_candidate(candidate: Dictionary, snapshot: Dictionary) -> Dictionary:
	var validation: Dictionary = validate_snapshot(candidate, snapshot)
	if not validation.get("accepted", false):
		return validation
	var restored := DrownedHarborAlpha3Session.new(
		candidate,
		snapshot.seed,
		PackedStringArray(snapshot.stable_seat_order),
		snapshot.get("role", {}).get("requested_mode", "cooperative")
	)
	var adoption: Dictionary = restored._adopt_snapshot(snapshot)
	if not adoption.get("accepted", false):
		return adoption
	return {"accepted": true, "reason": "", "session": restored}


static func migrate_alpha2_candidate(
	candidate: Dictionary, alpha2_snapshot: Dictionary, requested_mode: String
) -> Dictionary:
	if not candidate.get("accepted", false):
		return _rejected_static("alpha3_candidate_rejected")
	var source: Dictionary = DrownedHarborAlpha2Session.restore_candidate(
		candidate.alpha2_candidate, alpha2_snapshot
	)
	if not source.get("accepted", false):
		return _rejected_static("alpha2_snapshot_v2_rejected")
	if alpha2_snapshot.get("cleanup_complete", false) or not alpha2_snapshot.get("active", false):
		return _rejected_static("alpha2_terminal_snapshot_not_migratable")
	var pending := DrownedHarborAlpha3Session.new(
		candidate,
		alpha2_snapshot.seed,
		PackedStringArray(alpha2_snapshot.stable_seat_order),
		requested_mode
	)
	pending._route = source.session
	pending._migration = {
		"from_snapshot_version": 2,
		"to_snapshot_version": 3,
		"from_stage_id": alpha2_snapshot.stage_id,
		"to_stage_id": alpha2_snapshot.stage_id,
		"policy": "explicit_alpha2_snapshot_v2_to_alpha3_snapshot_v3_or_fail_closed",
	}
	pending._append_checkpoint("alpha2_snapshot_v2_migrated")
	return {"accepted": true, "reason": "", "session": pending, "migrated": true}


static func validate_snapshot(candidate: Dictionary, snapshot: Dictionary) -> Dictionary:
	if not candidate.get("accepted", false) or not _has_exact_keys(snapshot, SNAPSHOT_KEYS):
		return _rejected_static("malformed_snapshot")
	for identity: Array in [
		["tale_id", "drowned_harbor"],
		["package_kind", "tale"],
		["package_schema_version", 1],
		["package_version", 3],
		["provider_id", "drowned_harbor_authorities_v1"],
		["provider_version", 3],
		["snapshot_version", SNAPSHOT_VERSION],
		["scenario_id", "drowned_harbor_systems_v3"],
		["scenario_version", 3],
	]:
		if snapshot.get(identity[0]) != identity[1]:
			return _rejected_static("unsupported_snapshot_identity")
	if (
		not snapshot.seed is int
		or snapshot.seed < 1
		or not snapshot.authoritative_revision is int
		or snapshot.authoritative_revision < 0
		or not snapshot.stable_seat_order is Array
		or snapshot.stable_seat_order.is_empty()
		or snapshot.stable_seat_order.size() > SeatManager.MAX_SEATS
		or not snapshot.processed_request_ids is Array
		or not snapshot.processed_event_ids is Array
		or not snapshot.route is Dictionary
		or not snapshot.public_history is Array
		or not snapshot.replay is Array
		or not snapshot.transcript is Array
		or not snapshot.mirror is Array
		or not snapshot.checkpoints is Array
		or not snapshot.migration is Dictionary
		or not snapshot.exactly_once_identities is Dictionary
		or not snapshot.active is bool
		or not snapshot.cleanup_complete is bool
		or not snapshot.next_destination is String
	):
		return _rejected_static("malformed_snapshot")
	if (
		snapshot.public_history.size() != snapshot.replay.size()
		or snapshot.public_history.size() != snapshot.transcript.size()
		or snapshot.public_history.size() != snapshot.mirror.size()
	):
		return _rejected_static("public_evidence_cardinality_mismatch")
	var route_validation: Dictionary = DrownedHarborAlpha2Session.validate_snapshot(
		candidate.alpha2_candidate, snapshot.route
	)
	if not route_validation.get("accepted", false):
		return _rejected_static("inherited_route_snapshot_rejected")
	if snapshot.cleanup_complete:
		if (
			snapshot.active
			or not snapshot.rules.is_empty()
			or not snapshot.role.is_empty()
			or not snapshot.director.is_empty()
			or not snapshot.next_destination in ["rematch", "normal_title"]
		):
			return _rejected_static("malformed_terminal_cleanup")
		return {"accepted": true, "reason": ""}
	if (
		not snapshot.active
		or not snapshot.rules is Dictionary
		or not snapshot.role is Dictionary
		or not snapshot.director is Dictionary
	):
		return _rejected_static("malformed_snapshot")
	return {"accepted": true, "reason": ""}


func _dispatch(request: Dictionary) -> Dictionary:
	var result: Dictionary = _rejected("unsupported_intent")
	match request.intent:
		"apply_content_turn":
			result = _apply_content_turn(request)
		"transfer_item":
			result = _transfer_item(request)
		"register_stranded_target":
			result = _register_stranded_target(request)
		"attempt_rescue":
			result = _attempt_rescue(request)
		"consume_lifeboat_route":
			result = _consume_lifeboat_route(request)
		"select_director_candidate":
			result = _select_director(request)
		"offer_tidebound":
			result = _offer_tidebound(request)
		"refuse_tidebound":
			result = _refuse_tidebound(request)
		"resolve_tidebound":
			result = _resolve_tidebound(request)
		"apply_defeat_continuation":
			result = _apply_defeat_continuation(request)
		_:
			if ROUTE_INTENTS.has(request.intent):
				result = _forward_route_request(request)
	return result


func _apply_content_turn(request: Dictionary) -> Dictionary:
	if not request.payload.is_empty() or not CONTENT_STAGE_OFFSETS.has(stage_id()):
		return _rejected("malformed_content_turn")
	var sequence: int = coverage_sequence_index() + int(CONTENT_STAGE_OFFSETS[stage_id()])
	var result: Dictionary = _rules.apply_content_turn(stage_id(), sequence, request.stable_seat_id)
	if result.get("accepted", false):
		_append_checkpoint("before_item_card_resource_commit")
		_append_checkpoint("after_item_card_resource_commit")
		result.event_key = "alpha3_content_turn_committed"
		result.public_payload = result.public_content
	return result


func _transfer_item(request: Dictionary) -> Dictionary:
	if request.payload.keys().size() != 2:
		return _rejected("malformed_item_transfer")
	var result: Dictionary = _rules.transfer_item(
		request.payload.get("item_id", ""),
		request.stable_seat_id,
		request.payload.get("to_stable_seat_id", "")
	)
	if result.get("accepted", false):
		result.event_key = "alpha3_item_transferred"
		result.public_payload = {"transfer_complete": true}
	return result


func _register_stranded_target(request: Dictionary) -> Dictionary:
	if request.payload.keys().size() != 2:
		return _rejected("malformed_rescue_target")
	var result: Dictionary = _rules.register_stranded_target(
		request.payload.get("target_kind", ""), request.payload.get("target_id", "")
	)
	if result.get("accepted", false):
		result.event_key = "alpha3_stranded_target_registered"
		result.public_payload = {"unresolved_rescue_count": _rules.unresolved_rescue_count()}
	return result


func _attempt_rescue(request: Dictionary) -> Dictionary:
	if request.payload.keys() != ["target_id"]:
		return _rejected("malformed_rescue_request")
	var result: Dictionary = _rules.attempt_rescue(request.payload.target_id)
	if result.get("accepted", false):
		result.event_key = "alpha3_rescue_committed"
		result.public_payload = {"rescued_count": result.rescued_count}
	return result


func _consume_lifeboat_route(request: Dictionary) -> Dictionary:
	if not request.payload.is_empty():
		return _rejected("malformed_lifeboat_request")
	var result: Dictionary = _rules.consume_lifeboat_route()
	if result.get("accepted", false):
		result.event_key = "alpha3_lifeboat_capacity_committed"
		result.public_payload = {"replacement_route_available": false}
	return result


func _select_director(request: Dictionary) -> Dictionary:
	if not request.payload.is_empty():
		return _rejected("malformed_director_request")
	var result: Dictionary = _director.select_candidate(director_safe_input(), DIRECTOR_CANDIDATES)
	if result.get("accepted", false):
		_append_checkpoint("before_director_selection")
		_append_checkpoint("after_director_selection")
		result.event_key = "alpha3_director_candidate_selected"
		result.public_payload = {"candidate_id": result.candidate_id}
	return result


func _offer_tidebound(request: Dictionary) -> Dictionary:
	if request.payload.keys() != ["origin"]:
		return _rejected("malformed_tidebound_offer")
	var after_high_water: bool = (
		DrownedHarborAlpha2RulesAuthority.STAGE_ORDER.find(stage_id())
		> DrownedHarborAlpha2RulesAuthority.STAGE_ORDER.find("high_water_v1")
	)
	var result: Dictionary = _role.offer_tidebound(
		request.stable_seat_id, request.payload.origin, after_high_water
	)
	if result.get("accepted", false):
		_append_checkpoint("before_tidebound_offer")
		_append_checkpoint("after_tidebound_offer")
		result.event_key = "alpha3_tidebound_offer_presented"
		result.public_payload = {"controlled_reveal_pending": true}
	return result


func _refuse_tidebound(request: Dictionary) -> Dictionary:
	if not request.payload.is_empty():
		return _rejected("malformed_tidebound_refusal")
	var result: Dictionary = _role.refuse_tidebound(request.stable_seat_id)
	if result.get("accepted", false):
		_append_checkpoint("before_tidebound_refusal")
		_append_checkpoint("after_tidebound_refusal")
		result.event_key = "alpha3_tidebound_refusal_persisted"
		result.public_payload = {"refusal_persisted": true}
	return result


func _resolve_tidebound(request: Dictionary) -> Dictionary:
	if not request.payload.is_empty():
		return _rejected("malformed_tidebound_resolution")
	var result: Dictionary = _role.resolve_tidebound(request.stable_seat_id, _revision + 1)
	if result.get("accepted", false):
		_append_checkpoint("before_tidebound_transformation")
		_append_checkpoint("after_tidebound_transformation")
		result.event_key = "alpha3_tidebound_conversion_committed"
		result.public_payload = {"public_form": result.public_form}
	return result


func _apply_defeat_continuation(request: Dictionary) -> Dictionary:
	if not request.payload.is_empty():
		return _rejected("malformed_continuation_request")
	var result: Dictionary = _role.apply_defeat_continuation(
		request.stable_seat_id,
		stage_id(),
		_rules.replacement_route_available(),
		_rules.submerged_rescue_route_available(),
		_revision + 1
	)
	if result.get("accepted", false):
		_append_checkpoint("before_continuation_transition")
		_append_checkpoint("after_continuation_transition")
		result.event_key = "alpha3_continuation_committed"
		result.public_payload = {"public_form": result.public_form}
	return result


func _forward_route_request(request: Dictionary) -> Dictionary:
	var route_request: Dictionary = {
		"request_id": "alpha3_inner_%s" % request.request_id,
		"event_id": "alpha3_inner_%s" % request.event_id,
		"actor": "developer_alpha2_gate",
		"stable_seat_id": request.stable_seat_id,
		"source_revision": _route.to_snapshot().authoritative_revision,
		"intent": request.intent,
		"payload": request.payload.duplicate(true),
	}
	var route_result: Dictionary = _route.process_request(route_request)
	if not route_result.get("accepted", false):
		return _rejected(route_result.get("reason", "route_request_rejected"))
	if request.intent == "resolve_ending":
		var ending: Dictionary = _rules.resolve_ending(coverage_sequence_index(), _revision + 1)
		if not ending.get("accepted", false):
			return _rejected(ending.get("reason", "ending_resolution_rejected"))
		_append_checkpoint("before_ending_resolution")
		_append_checkpoint("after_ending_resolution")
		_role.mark_objectives_complete()
	elif request.intent == "resolve_epilogue_attribution":
		var attribution: Dictionary = _role.resolve_private_ending_attribution(_rules.ending_id())
		if not attribution.get("accepted", false):
			return _rejected(attribution.get("reason", "attribution_rejected"))
	var result: Dictionary = {"accepted": true, "reason": ""}
	if route_result.has("public_event"):
		result.event_key = route_result.public_event.event_key
		result.public_payload = _closed_route_payload(route_result.public_event.event_key)
	return result


func _closed_route_payload(event_key: String) -> Dictionary:
	match event_key:
		"council_resolved":
			return {"commitment_status": "all_stable_seats_committed"}
		"high_water_transformation_applied":
			return {"transformation_status": "committed_atomically"}
		"ending_resolved":
			return {"ending_id": _rules.ending_id()}
		"epilogue_acknowledged":
			return {"acknowledged": true}
		"drowned_harbor_session_cleared":
			return {
				"cleanup_complete": true, "next_destination": _route.to_snapshot().next_destination
			}
		_:
			return {"status": "committed"}


func _public_event(result: Dictionary) -> Dictionary:
	var payload: Dictionary = result.get("public_payload", {}).duplicate(true)
	var event: Dictionary = {
		"event_key": result.event_key,
		"revision": _revision,
		"stage_id": stage_id(),
		"payload": payload,
	}
	event.event_identity = (
		(
			"drowned_harbor_alpha3|public_event|%d|%d|%s|%s"
			% [_seed, _revision, event.event_key, JSON.stringify(payload, "", true)]
		)
		. sha256_text()
	)
	return event


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
				"caption": event.event_key.replace("_", " ").capitalize(),
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
	var route_digest: String = ""
	if _route != null:
		route_digest = JSON.stringify(_route.to_snapshot(), "", true).sha256_text()
	(
		_checkpoints
		. append(
			{
				"checkpoint_id": checkpoint_id,
				"authoritative_revision": _revision,
				"stage_id": stage_id() if _route != null else "initializing",
				"route_digest": route_digest,
			}
		)
	)


func _apply_connection(stable_seat_id: String, kind: String) -> Dictionary:
	var before: Dictionary = to_snapshot()
	if _cleanup_complete or not _stable_seat_order.has(stable_seat_id):
		return _no_op_rejection("wrong_stable_seat", before)
	var route_result: Dictionary
	var role_result: Dictionary
	match kind:
		"disconnect":
			route_result = _route.disconnect_seat(stable_seat_id)
			role_result = _role.set_connection(stable_seat_id, false, false)
		"surrogate":
			route_result = _route.assign_surrogate_control(stable_seat_id)
			role_result = _role.set_connection(stable_seat_id, true, true)
		_:
			route_result = _route.reconnect_seat(stable_seat_id)
			role_result = _role.set_connection(stable_seat_id, true, false)
	if not route_result.get("accepted", false) or not role_result.get("accepted", false):
		return _no_op_rejection("connection_change_rejected", before)
	_revision += 1
	_append_checkpoint("%s_%s" % [kind, stable_seat_id])
	return {"accepted": true, "reason": "", "authoritative_revision": _revision}


func _request_rejection(request: Dictionary) -> String:
	var reason: String = ""
	if not _has_exact_keys(request, REQUEST_KEYS):
		reason = "malformed_request"
	else:
		for key: String in REQUEST_KEYS:
			if key == "source_revision" and not request.get(key) is int:
				reason = "malformed_request"
			elif key == "payload" and not request.get(key) is Dictionary:
				reason = "malformed_request"
			elif (
				key not in ["source_revision", "payload"]
				and (not request.get(key) is String or request.get(key, "").is_empty())
			):
				reason = "malformed_request"
			if not reason.is_empty():
				break
	if reason.is_empty() and _processed_request_ids.has(request.request_id):
		reason = "duplicate_request"
	elif reason.is_empty() and _processed_event_ids.has(request.event_id):
		reason = "duplicate_event"
	elif reason.is_empty() and (not _active or _cleanup_complete):
		reason = "unavailable"
	elif reason.is_empty() and request.actor != "developer_alpha3_gate":
		reason = "unauthorized_actor"
	elif reason.is_empty() and not _stable_seat_order.has(request.stable_seat_id):
		reason = "wrong_stable_seat"
	elif reason.is_empty() and request.source_revision != _revision:
		reason = "stale_revision"
	return reason


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
	_terminal_identities = snapshot.exactly_once_identities.duplicate(true)
	_active = snapshot.active
	_cleanup_complete = snapshot.cleanup_complete
	_next_destination = snapshot.next_destination
	var route_result: Dictionary = DrownedHarborAlpha2Session.restore_candidate(
		_candidate.alpha2_candidate, snapshot.route
	)
	if not route_result.get("accepted", false):
		return _rejected("inherited_route_restore_failed")
	_route = route_result.session
	if _cleanup_complete:
		return {"accepted": true, "reason": ""}
	var rules_result: Dictionary = _rules.restore_snapshot(snapshot.rules)
	var role_result: Dictionary = _role.restore_snapshot(snapshot.role)
	var director_result: Dictionary = _director.restore_snapshot(snapshot.director)
	if (
		not rules_result.get("accepted", false)
		or not role_result.get("accepted", false)
		or not director_result.get("accepted", false)
	):
		return _rejected("alpha3_authority_restore_failed")
	return {"accepted": true, "reason": ""}


func _connected_seat_count() -> int:
	var count: int = 0
	for row: Dictionary in _role.public_view().seats:
		if row.connected:
			count += 1
	return count


func _no_op_rejection(reason: String, before: Dictionary) -> Dictionary:
	_rejection_streak += 1
	var diagnostics: Array[Dictionary] = [
		{
			"code": reason,
			"stage_id": before.get("route", {}).get("stage_id", "unavailable"),
			"retry": "refresh the authoritative revision and inspect the public action list",
		}
	]
	if _rejection_streak >= MAX_REJECTIONS_BEFORE_DIAGNOSTIC:
		(
			diagnostics
			. append(
				{
					"code": "bounded_progress_watchdog",
					"stage_id": before.get("route", {}).get("stage_id", "unavailable"),
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


static func _has_exact_keys(value: Dictionary, expected: PackedStringArray) -> bool:
	if value.size() != expected.size():
		return false
	for key: Variant in value:
		if not key is String or not expected.has(key):
			return false
	return true


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
