class_name DrownedHarborAlpha3DirectorAuthority
extends RefCounted

const RNG_STREAM: String = "drowned_harbor_director_authority"
const ANTI_REPEAT_WINDOW: int = 3
const INPUT_ALLOWLIST: PackedStringArray = [
	"authoritative_revision",
	"connected_seat_count",
	"stage_id",
	"tide_state",
	"living_count",
	"restless_count",
	"tidebound_count",
	"unresolved_rescue_count",
	"public_resource_pressure",
	"recent_public_candidate_ids",
	"ending_eligibility_count",
]
const FORBIDDEN_INPUTS: PackedStringArray = [
	"role_id",
	"private_objective_id",
	"bellmarked_seat_ids",
	"unrevealed_faction_id",
	"private_item_marker",
	"desirability_score",
]
const SNAPSHOT_KEYS: PackedStringArray = [
	"rng_stream", "rng_seed", "rng_state", "recent_candidate_ids", "selection_ids"
]

var _seed: int = 1
var _rng := RandomNumberGenerator.new()
var _recent_candidate_ids: Array[String] = []
var _selection_ids: Array[String] = []


func _init(seed: int = 1) -> void:
	_seed = seed
	_rng.seed = seed + 4049


func select_candidate(public_input: Dictionary, candidate_ids: PackedStringArray) -> Dictionary:
	if not accepts_input(public_input):
		return _rejected("director_input_rejected")
	if candidate_ids.is_empty() or candidate_ids.size() > 32:
		return _rejected("director_candidate_inventory_unbounded")
	var filtered: Array[String] = []
	for candidate_id: String in candidate_ids:
		if candidate_id.is_empty() or filtered.has(candidate_id):
			return _rejected("director_candidate_inventory_invalid")
		if not _recent_candidate_ids.has(candidate_id):
			filtered.append(candidate_id)
	if filtered.is_empty():
		filtered = Array(candidate_ids)
	filtered.sort()
	var selected_index: int = _rng.randi_range(0, filtered.size() - 1)
	var selected_id: String = filtered[selected_index]
	_recent_candidate_ids.append(selected_id)
	while _recent_candidate_ids.size() > ANTI_REPEAT_WINDOW:
		_recent_candidate_ids.pop_front()
	var selection_id: String = (
		(
			"drowned_harbor_alpha3|director_selection|%d|%d|%s|%s"
			% [_seed, _selection_ids.size(), selected_id, public_input.stage_id]
		)
		. sha256_text()
	)
	_selection_ids.append(selection_id)
	return {
		"accepted": true,
		"reason": "",
		"candidate_id": selected_id,
		"director_selection_id": selection_id,
	}


func accepts_input(value: Dictionary) -> bool:
	if value.size() != INPUT_ALLOWLIST.size():
		return false
	for key: Variant in value:
		if not key is String or not INPUT_ALLOWLIST.has(key) or FORBIDDEN_INPUTS.has(key):
			return false
	return (
		value.authoritative_revision is int
		and value.connected_seat_count is int
		and value.stage_id is String
		and value.tide_state is String
		and value.living_count is int
		and value.restless_count is int
		and value.tidebound_count is int
		and value.unresolved_rescue_count is int
		and value.public_resource_pressure is int
		and value.recent_public_candidate_ids is Array
		and value.ending_eligibility_count is int
	)


func public_view() -> Dictionary:
	return {
		"privacy_class": "public",
		"selection_count": _selection_ids.size(),
		"recent_public_candidate_ids": _recent_candidate_ids.duplicate(),
		"anti_repeat_window": ANTI_REPEAT_WINDOW,
	}


func director_selection_id() -> String:
	return "" if _selection_ids.is_empty() else _selection_ids[-1]


func to_snapshot() -> Dictionary:
	return {
		"rng_stream": RNG_STREAM,
		"rng_seed": _rng.seed,
		"rng_state": _rng.state,
		"recent_candidate_ids": _recent_candidate_ids.duplicate(),
		"selection_ids": _selection_ids.duplicate(),
	}


func restore_snapshot(snapshot: Dictionary) -> Dictionary:
	if not _has_exact_keys(snapshot, SNAPSHOT_KEYS):
		return _rejected("malformed_director_snapshot")
	if (
		snapshot.rng_stream != RNG_STREAM
		or not snapshot.rng_seed is int
		or not snapshot.rng_state is int
		or not snapshot.recent_candidate_ids is Array
		or not snapshot.selection_ids is Array
		or snapshot.recent_candidate_ids.size() > ANTI_REPEAT_WINDOW
	):
		return _rejected("malformed_director_snapshot")
	var recent: Array[String] = _string_array(snapshot.recent_candidate_ids)
	var identities: Array[String] = _string_array(snapshot.selection_ids)
	if recent.size() != snapshot.recent_candidate_ids.size():
		return _rejected("malformed_director_snapshot")
	for identity: String in identities:
		if identity.length() != 64 or identities.count(identity) != 1:
			return _rejected("malformed_director_snapshot")
	_rng.seed = snapshot.rng_seed
	_rng.state = snapshot.rng_state
	_recent_candidate_ids = recent
	_selection_ids = identities
	return {"accepted": true, "reason": ""}


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


static func _rejected(reason: String) -> Dictionary:
	return {"accepted": false, "reason": reason}
