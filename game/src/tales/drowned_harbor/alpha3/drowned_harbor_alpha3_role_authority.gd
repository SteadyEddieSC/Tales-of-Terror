class_name DrownedHarborAlpha3RoleAuthority
extends RefCounted

const PRIVACY_CLASSES: PackedStringArray = [
	"public", "controlled_reveal_private", "seat_private", "faction_private"
]
const ROLE_ORDER: PackedStringArray = [
	"bellhouse_archivist",
	"fog_listener",
	"lantern_surveyor",
	"lifeboat_keeper",
	"tide_chapel_warden",
	"wreckers_heir",
]
const LIVING_OBJECTIVES: PackedStringArray = [
	"recover_the_truth",
	"preserve_escape_capacity",
	"protect_another_witness",
	"contain_the_harbor",
	"release_the_drowned",
	"carry_memory_safely",
]
const BELLMARKED_OBJECTIVES: PackedStringArray = [
	"preserve_signal",
	"keep_names_in_ledger",
	"carry_harbor_memory_out",
	"preserve_bell",
	"open_old_channel",
]
const TIDEBOUND_OBJECTIVES: PackedStringArray = [
	"preserve_harbor_memory",
	"seek_release",
	"propagate_memory",
	"complete_unfinished_obligation",
]
const OFFER_ORIGINS: PackedStringArray = [
	"authored_exposure", "authored_bargain", "defeat_transition"
]
const SNAPSHOT_KEYS: PackedStringArray = [
	"requested_mode",
	"effective_mode",
	"fallback_reason",
	"stable_seat_order",
	"seats",
	"role_assignment_id",
	"private_objective_assignment_id",
	"faction_assignment_id",
	"tidebound_conversion_id",
	"continuation_transition_id",
	"social_rng_seed",
	"social_rng_state",
	"ending_attribution",
]

var _seed: int = 1
var _requested_mode: String = "cooperative"
var _effective_mode: String = "cooperative"
var _fallback_reason: String = ""
var _stable_seat_order: Array[String] = []
var _seats: Dictionary = {}
var _role_assignment_id: String = ""
var _private_objective_assignment_id: String = ""
var _faction_assignment_id: String = ""
var _tidebound_conversion_id: String = ""
var _continuation_transition_id: String = ""
var _social_rng := RandomNumberGenerator.new()
var _ending_attribution: Dictionary = {}


func _init(
	seed: int = 1,
	stable_seat_ids: PackedStringArray = PackedStringArray(),
	requested_mode: String = "cooperative"
) -> void:
	_seed = seed
	_requested_mode = requested_mode
	for stable_seat_id: String in stable_seat_ids:
		_stable_seat_order.append(stable_seat_id)
	_resolve_mode()
	_social_rng.seed = seed + 3037
	_assign_roles_and_objectives()
	_assign_faction()


func public_view() -> Dictionary:
	var public_seats: Array[Dictionary] = []
	var living_count: int = 0
	var restless_count: int = 0
	var tidebound_count: int = 0
	var complete_count: int = 0
	for stable_seat_id: String in _stable_seat_order:
		var row: Dictionary = _seats[stable_seat_id]
		match row.public_form:
			"living":
				living_count += 1
			"tidebound":
				tidebound_count += 1
			_:
				restless_count += 1
		if row.objective_complete:
			complete_count += 1
		(
			public_seats
			. append(
				{
					"stable_seat_id": stable_seat_id,
					"public_form": row.public_form,
					"connected": row.connected,
					"control_source": "surrogate" if row.surrogate else "local_human",
					"objective_complete": row.objective_complete,
					"participation_active": row.participation_active,
				}
			)
		)
	return {
		"privacy_class": "public",
		"requested_mode": _requested_mode,
		"effective_mode": _effective_mode,
		"fallback_applied": not _fallback_reason.is_empty(),
		"fallback_reason": _fallback_reason,
		"assigned_seat_count": _stable_seat_order.size(),
		"objective_complete_count": complete_count,
		"living_count": living_count,
		"restless_count": restless_count,
		"tidebound_count": tidebound_count,
		"seats": public_seats,
	}


func seat_private_view(stable_seat_id: String) -> Dictionary:
	if not _seats.has(stable_seat_id):
		return {}
	var row: Dictionary = _seats[stable_seat_id]
	if not row.connected or row.surrogate:
		return {}
	var result: Dictionary = {
		"privacy_class": "seat_private",
		"stable_seat_id": stable_seat_id,
		"role_instance_id": row.role_instance_id,
		"role_id": row.role_id,
		"private_objective_id": row.private_objective_id,
		"generic_public_alternative": "standard_harbor_action",
		"public_form": row.public_form,
		"refusal_used": row.refusal_used,
	}
	if not row.tidebound_objective_id.is_empty():
		result.tidebound_objective_id = row.tidebound_objective_id
	if not row.pending_offer.is_empty():
		result.controlled_reveal = {
			"privacy_class": "controlled_reveal_private",
			"offer_origin": row.pending_offer,
			"resolution_required": row.refusal_used,
		}
	return result


func faction_private_view(stable_seat_id: String) -> Dictionary:
	if not _seats.has(stable_seat_id):
		return {}
	var row: Dictionary = _seats[stable_seat_id]
	if not row.connected or row.surrogate or row.private_faction_id.is_empty():
		return {}
	return {
		"privacy_class": "faction_private",
		"stable_seat_id": stable_seat_id,
		"faction_id": row.private_faction_id,
		"faction_objective_id": row.faction_objective_id,
		"revealed": row.faction_revealed,
	}


func set_connection(stable_seat_id: String, connected: bool, surrogate: bool) -> Dictionary:
	if not _seats.has(stable_seat_id) or surrogate and not connected:
		return _rejected("wrong_stable_seat")
	var row: Dictionary = _seats[stable_seat_id]
	row.connected = connected
	row.surrogate = surrogate
	_seats[stable_seat_id] = row
	return {"accepted": true, "reason": ""}


func offer_tidebound(stable_seat_id: String, origin: String, after_high_water: bool) -> Dictionary:
	if not after_high_water:
		return _rejected("tidebound_offer_before_high_water")
	if not OFFER_ORIGINS.has(origin) or not _seats.has(stable_seat_id):
		return _rejected("invalid_tidebound_offer")
	var row: Dictionary = _seats[stable_seat_id]
	if row.public_form == "tidebound" or not row.pending_offer.is_empty():
		return _rejected("tidebound_offer_unavailable")
	row.pending_offer = origin
	_seats[stable_seat_id] = row
	return {"accepted": true, "reason": "", "controlled_reveal_pending": true}


func refuse_tidebound(stable_seat_id: String) -> Dictionary:
	if not _seats.has(stable_seat_id):
		return _rejected("wrong_stable_seat")
	var row: Dictionary = _seats[stable_seat_id]
	if row.pending_offer.is_empty() or row.refusal_used:
		return _rejected("tidebound_refusal_unavailable")
	row.pending_offer = ""
	row.refusal_used = true
	_seats[stable_seat_id] = row
	return {"accepted": true, "reason": "", "refusal_persisted": true}


func resolve_tidebound(stable_seat_id: String, revision: int) -> Dictionary:
	if not _seats.has(stable_seat_id):
		return _rejected("wrong_stable_seat")
	var row: Dictionary = _seats[stable_seat_id]
	if (
		row.pending_offer.is_empty()
		or not row.refusal_used
		or row.public_form == "tidebound"
		or not _tidebound_conversion_id.is_empty()
	):
		return _rejected("tidebound_conversion_unavailable")
	var objective_index: int = _social_rng.randi_range(0, TIDEBOUND_OBJECTIVES.size() - 1)
	row.public_form = "tidebound"
	row.tidebound_objective_id = TIDEBOUND_OBJECTIVES[objective_index]
	row.pending_offer = ""
	_seats[stable_seat_id] = row
	_tidebound_conversion_id = _identity(
		"tidebound_conversion", "%s|%d" % [stable_seat_id, revision]
	)
	return {
		"accepted": true,
		"reason": "",
		"tidebound_conversion_id": _tidebound_conversion_id,
		"public_form": "tidebound",
	}


func apply_defeat_continuation(
	stable_seat_id: String,
	stage_id: String,
	lifeboat_route_available: bool,
	submerged_rescue_route_available: bool,
	revision: int
) -> Dictionary:
	if not _seats.has(stable_seat_id) or not _continuation_transition_id.is_empty():
		return _rejected("continuation_unavailable")
	var continuation_form: String = "bell_witness"
	if lifeboat_route_available:
		continuation_form = "lifeboat_survivor"
	elif stage_id == "last_light_v1":
		continuation_form = "lighthouse_guardian"
	elif submerged_rescue_route_available:
		continuation_form = "drowned_guide"
	var row: Dictionary = _seats[stable_seat_id]
	row.public_form = continuation_form
	row.continuation_form = continuation_form
	row.participation_active = true
	_seats[stable_seat_id] = row
	_continuation_transition_id = _identity(
		"continuation_transition", "%s|%s|%d" % [stable_seat_id, continuation_form, revision]
	)
	return {
		"accepted": true,
		"reason": "",
		"continuation_transition_id": _continuation_transition_id,
		"public_form": continuation_form,
	}


func resolve_private_ending_attribution(ending_id: String) -> Dictionary:
	if not _ending_attribution.is_empty():
		return _rejected("ending_attribution_already_resolved")
	var seats: Dictionary = {}
	var factions: Dictionary = {"living": "attributed"}
	for stable_seat_id: String in _stable_seat_order:
		var row: Dictionary = _seats[stable_seat_id]
		seats[stable_seat_id] = {
			"ending_id": ending_id,
			"private_outcome": "seat_outcome_%s" % row.public_form,
		}
		if not row.private_faction_id.is_empty():
			factions[row.private_faction_id] = "attributed"
		if row.public_form == "tidebound":
			factions.tidebound = "attributed"
		elif row.public_form != "living":
			factions.restless = "attributed"
	_ending_attribution = {"seats": seats, "factions": factions}
	return {"accepted": true, "reason": "", "attribution_complete": true}


func mark_objectives_complete() -> void:
	for stable_seat_id: String in _stable_seat_order:
		var row: Dictionary = _seats[stable_seat_id]
		row.objective_complete = true
		_seats[stable_seat_id] = row


func role_assignment_id() -> String:
	return _role_assignment_id


func private_objective_assignment_id() -> String:
	return _private_objective_assignment_id


func faction_assignment_id() -> String:
	return _faction_assignment_id


func tidebound_conversion_id() -> String:
	return _tidebound_conversion_id


func continuation_transition_id() -> String:
	return _continuation_transition_id


func effective_mode() -> String:
	return _effective_mode


func to_snapshot() -> Dictionary:
	return {
		"requested_mode": _requested_mode,
		"effective_mode": _effective_mode,
		"fallback_reason": _fallback_reason,
		"stable_seat_order": _stable_seat_order.duplicate(),
		"seats": _seats.duplicate(true),
		"role_assignment_id": _role_assignment_id,
		"private_objective_assignment_id": _private_objective_assignment_id,
		"faction_assignment_id": _faction_assignment_id,
		"tidebound_conversion_id": _tidebound_conversion_id,
		"continuation_transition_id": _continuation_transition_id,
		"social_rng_seed": _social_rng.seed,
		"social_rng_state": _social_rng.state,
		"ending_attribution": _ending_attribution.duplicate(true),
	}


func restore_snapshot(snapshot: Dictionary) -> Dictionary:
	if not _has_exact_keys(snapshot, SNAPSHOT_KEYS):
		return _rejected("malformed_role_snapshot")
	if (
		not snapshot.stable_seat_order is Array
		or snapshot.stable_seat_order != _stable_seat_order
		or not snapshot.seats is Dictionary
		or snapshot.seats.size() != _stable_seat_order.size()
		or not snapshot.social_rng_seed is int
		or not snapshot.social_rng_state is int
		or not snapshot.ending_attribution is Dictionary
	):
		return _rejected("malformed_role_snapshot")
	for identity_key: String in [
		"role_assignment_id", "private_objective_assignment_id", "faction_assignment_id"
	]:
		if not snapshot.get(identity_key) is String or snapshot.get(identity_key).length() != 64:
			return _rejected("malformed_role_snapshot")
	for optional_identity: String in ["tidebound_conversion_id", "continuation_transition_id"]:
		var value: Variant = snapshot.get(optional_identity)
		if not value is String or not value.is_empty() and value.length() != 64:
			return _rejected("malformed_role_snapshot")
	_requested_mode = snapshot.requested_mode
	_effective_mode = snapshot.effective_mode
	_fallback_reason = snapshot.fallback_reason
	_seats = snapshot.seats.duplicate(true)
	_role_assignment_id = snapshot.role_assignment_id
	_private_objective_assignment_id = snapshot.private_objective_assignment_id
	_faction_assignment_id = snapshot.faction_assignment_id
	_tidebound_conversion_id = snapshot.tidebound_conversion_id
	_continuation_transition_id = snapshot.continuation_transition_id
	_social_rng.seed = snapshot.social_rng_seed
	_social_rng.state = snapshot.social_rng_state
	_ending_attribution = snapshot.ending_attribution.duplicate(true)
	return {"accepted": true, "reason": ""}


func _resolve_mode() -> void:
	_effective_mode = _requested_mode
	if _requested_mode == "hidden_betrayer" and _stable_seat_order.size() < 3:
		_effective_mode = "cooperative"
		_fallback_reason = "hidden_betrayer_requires_three_seats"
	elif _requested_mode == "outbreak" and _stable_seat_order.size() < 2:
		_effective_mode = "cooperative"
		_fallback_reason = "outbreak_requires_two_seats"
	elif not _requested_mode in ["cooperative", "hidden_betrayer", "outbreak"]:
		_effective_mode = "cooperative"
		_fallback_reason = "unsupported_mode"


func _assign_roles_and_objectives() -> void:
	var remaining: Array[String] = []
	for objective_id: String in LIVING_OBJECTIVES:
		remaining.append(objective_id)
	var assignment_parts: Array[String] = []
	var objective_parts: Array[String] = []
	for index: int in _stable_seat_order.size():
		if remaining.is_empty():
			for objective_id: String in LIVING_OBJECTIVES:
				remaining.append(objective_id)
		var objective_index: int = _social_rng.randi_range(0, remaining.size() - 1)
		var stable_seat_id: String = _stable_seat_order[index]
		var role_id: String = ROLE_ORDER[index % ROLE_ORDER.size()]
		var objective_id: String = remaining.pop_at(objective_index)
		var role_instance_id: String = _identity(
			"role_instance", "%s|%s|%d" % [stable_seat_id, role_id, index]
		)
		_seats[stable_seat_id] = {
			"role_instance_id": role_instance_id,
			"role_id": role_id,
			"private_objective_id": objective_id,
			"private_faction_id": "",
			"faction_objective_id": "",
			"faction_revealed": false,
			"public_form": "living",
			"continuation_form": "",
			"tidebound_objective_id": "",
			"connected": true,
			"surrogate": false,
			"refusal_used": false,
			"pending_offer": "",
			"objective_complete": false,
			"participation_active": true,
		}
		assignment_parts.append("%s:%s:%s" % [stable_seat_id, role_id, role_instance_id])
		objective_parts.append("%s:%s" % [stable_seat_id, objective_id])
	_role_assignment_id = _identity("role_assignment", "|".join(assignment_parts))
	_private_objective_assignment_id = _identity(
		"private_objective_assignment", "|".join(objective_parts)
	)


func _assign_faction() -> void:
	var assignment: String = "none"
	if _effective_mode == "hidden_betrayer":
		var seat_index: int = _social_rng.randi_range(0, _stable_seat_order.size() - 1)
		var objective_index: int = _social_rng.randi_range(0, BELLMARKED_OBJECTIVES.size() - 1)
		var stable_seat_id: String = _stable_seat_order[seat_index]
		var row: Dictionary = _seats[stable_seat_id]
		row.private_faction_id = "bellmarked"
		row.faction_objective_id = BELLMARKED_OBJECTIVES[objective_index]
		_seats[stable_seat_id] = row
		assignment = "%s:%s" % [stable_seat_id, row.faction_objective_id]
	_faction_assignment_id = _identity(
		"faction_assignment", "%s|%s" % [_effective_mode, assignment]
	)


func _identity(kind: String, payload: String) -> String:
	return ("drowned_harbor_alpha3|%s|%d|%s" % [kind, _seed, payload]).sha256_text()


static func _has_exact_keys(value: Dictionary, expected: PackedStringArray) -> bool:
	if value.size() != expected.size():
		return false
	for key: Variant in value:
		if not key is String or not expected.has(key):
			return false
	return true


static func _rejected(reason: String) -> Dictionary:
	return {"accepted": false, "reason": reason}
