class_name DrownedHarborAlpha3RulesAuthority
extends RefCounted

const ITEMS: PackedStringArray = [
	"chapel_salt_censer",
	"cracked_lighthouse_lens",
	"dead_mans_compass",
	"glass_bell_clapper",
	"harbor_masters_seal",
	"ledger_knife",
	"lifeboat_flare",
	"missing_name_tablet",
	"oilskin_satchel",
	"salt_stiff_rope",
	"tin_lantern",
	"wreckers_hook",
]
const CARDS: PackedStringArray = [
	"a_name_remembered",
	"borrowed_breath",
	"cut_the_line",
	"hold_fast",
	"mark_the_door",
	"one_more_passenger",
	"salt_in_the_wound",
	"share_the_weight",
	"the_harbor_owes_me",
	"the_light_looks_back",
	"the_long_way_around",
	"wrong_bell",
]
const RESOURCES: PackedStringArray = [
	"bell_tokens",
	"dry_matches",
	"harbor_keys",
	"lamp_oil",
	"lifeboat_capacity",
	"memory_fragments",
	"rope",
	"salt_marks",
]
const HAZARDS: PackedStringArray = [
	"archive_collapse",
	"bell_shock",
	"drowned_patrol",
	"harbors_claim",
	"lamps_turn_seaward",
	"lifeboat_breaks_free",
	"light_answers",
	"missing_name",
	"returning_current",
	"salt_rot",
	"street_gives_way",
	"water_in_lungs",
]
const ENCOUNTERS_BY_STAGE: Dictionary = {
	"low_tide_arrival_v1":
	["empty_lifeboat", "harbor_office_manifest", "market_of_shadows", "mudflat_mile"],
	"bellhouse_ledger_v1":
	["bell_counts_wrong", "first_harbor_bargain", "missing_name_door", "names_beneath_names"],
	"lighthouse_council_v1": ["council_beneath_turning_light", "lens_shows_four_futures"],
	"high_water_v1":
	[
		"bell_rings_living_name",
		"drowned_archive_opens",
		"lifeboat_breaks_free_encounter",
		"one_more_passenger_encounter",
		"street_becomes_river",
		"tidebound_offer",
	],
	"last_light_v1": ["final_harbor_bargain", "last_seat_on_boat", "lighthouse_mechanism"],
}
const ENDINGS: PackedStringArray = [
	"drowned_released",
	"harbor_rises",
	"harbor_sealed",
	"last_lifeboat",
	"light_comes_home",
	"mixed_outcomes",
	"names_erased",
]
const OWNERSHIP_CLASSES: PackedStringArray = [
	"seat_owned", "shared_group", "board_owned", "public_quest_carried", "faction_private"
]
const SNAPSHOT_KEYS: PackedStringArray = [
	"items",
	"cards",
	"resources",
	"observed_hazards",
	"observed_encounters",
	"rescue_state",
	"ending_id",
	"ending_resolution_id",
	"content_history",
]

var _seed: int = 1
var _stable_seat_order: Array[String] = []
var _items: Dictionary = {}
var _cards: Dictionary = {}
var _resources: Dictionary = {}
var _observed_hazards: Array[String] = []
var _observed_encounters: Array[String] = []
var _rescue_state: Dictionary = {
	"unresolved": [], "rescued": [], "stranded": [], "replacement_route_available": true
}
var _ending_id: String = ""
var _ending_resolution_id: String = ""
var _content_history: Array[Dictionary] = []


func _init(seed: int = 1, stable_seat_ids: PackedStringArray = PackedStringArray()) -> void:
	_seed = seed
	for stable_seat_id: String in stable_seat_ids:
		_stable_seat_order.append(stable_seat_id)
	_initialize_content()


func apply_content_turn(
	stage_id: String, sequence_index: int, stable_seat_id: String
) -> Dictionary:
	if not ENCOUNTERS_BY_STAGE.has(stage_id) or not _stable_seat_order.has(stable_seat_id):
		return _rejected("content_turn_unavailable")
	var encounter_pool: Array = ENCOUNTERS_BY_STAGE[stage_id]
	var item_id: String = ITEMS[sequence_index % ITEMS.size()]
	var card_id: String = CARDS[(sequence_index + 3) % CARDS.size()]
	var resource_index: int = (sequence_index + 5) % RESOURCES.size()
	var resource_id: String = RESOURCES[resource_index]
	for offset: int in RESOURCES.size():
		var bounded_id: String = RESOURCES[(resource_index + offset) % RESOURCES.size()]
		if _resources[bounded_id] > 0:
			resource_id = bounded_id
			break
	var hazard_id: String = HAZARDS[(sequence_index + 7) % HAZARDS.size()]
	var encounter_id: String = encounter_pool[sequence_index % encounter_pool.size()]
	var item: Dictionary = _items[item_id]
	var card: Dictionary = _cards[card_id]
	if card.charges <= 0 or _resources[resource_id] <= 0:
		return _rejected("content_turn_resource_unavailable")
	item.observed = true
	_items[item_id] = item
	card.observed = true
	card.charges -= 1
	_cards[card_id] = card
	_resources[resource_id] -= 1
	if not _observed_hazards.has(hazard_id):
		_observed_hazards.append(hazard_id)
	if not _observed_encounters.has(encounter_id):
		_observed_encounters.append(encounter_id)
	var public_item_id: String = (
		"private_item_observed" if item.ownership_class == "faction_private" else item_id
	)
	var row: Dictionary = {
		"stage_id": stage_id,
		"item_id": public_item_id,
		"card_id": card_id,
		"resource_id": resource_id,
		"hazard_id": hazard_id,
		"encounter_id": encounter_id,
	}
	_content_history.append(row)
	return {"accepted": true, "reason": "", "public_content": row.duplicate(true)}


func transfer_item(item_id: String, from_seat_id: String, to_seat_id: String) -> Dictionary:
	if (
		not _items.has(item_id)
		or not _stable_seat_order.has(from_seat_id)
		or not _stable_seat_order.has(to_seat_id)
		or from_seat_id == to_seat_id
	):
		return _rejected("invalid_item_transfer")
	var item: Dictionary = _items[item_id]
	if item.owner_id != from_seat_id or item.state in ["lost", "spent"]:
		return _rejected("item_transfer_unavailable")
	item.owner_id = to_seat_id
	_items[item_id] = item
	return {
		"accepted": true,
		"reason": "",
		"condition": item.state,
		"charges": item.charges,
		"ownership_identity": item.ownership_identity,
	}


func register_stranded_target(target_kind: String, target_id: String) -> Dictionary:
	if not target_kind in ["stable_seat", "authored_resident", "quest_object"]:
		return _rejected("unsupported_rescue_target")
	if target_id.is_empty() or _rescue_state.stranded.has(target_id):
		return _rejected("invalid_rescue_target")
	_rescue_state.stranded.append(target_id)
	_rescue_state.unresolved.append(target_id)
	return {"accepted": true, "reason": ""}


func attempt_rescue(target_id: String) -> Dictionary:
	if not _rescue_state.unresolved.has(target_id) or _resources.lifeboat_capacity <= 0:
		return _rejected("rescue_unavailable")
	_resources.lifeboat_capacity -= 1
	_rescue_state.unresolved.erase(target_id)
	_rescue_state.stranded.erase(target_id)
	_rescue_state.rescued.append(target_id)
	_rescue_state.replacement_route_available = _resources.lifeboat_capacity > 0
	return {"accepted": true, "reason": "", "rescued_count": _rescue_state.rescued.size()}


func consume_lifeboat_route() -> Dictionary:
	if _resources.lifeboat_capacity <= 0:
		return _rejected("lifeboat_route_unavailable")
	_resources.lifeboat_capacity = 0
	_rescue_state.replacement_route_available = false
	return {"accepted": true, "reason": ""}


func resolve_ending(sequence_index: int, revision: int) -> Dictionary:
	if not _ending_resolution_id.is_empty():
		return _rejected("ending_already_resolved")
	_ending_id = ENDINGS[sequence_index % ENDINGS.size()]
	_ending_resolution_id = (
		("drowned_harbor_alpha3|ending_resolution|%d|%s|%d" % [_seed, _ending_id, revision])
		. sha256_text()
	)
	return {
		"accepted": true,
		"reason": "",
		"ending_id": _ending_id,
		"ending_resolution_id": _ending_resolution_id,
	}


func public_view() -> Dictionary:
	var public_items: Array[String] = []
	for item_id: String in ITEMS:
		var row: Dictionary = _items[item_id]
		if row.observed and row.ownership_class != "faction_private":
			public_items.append(item_id)
	return {
		"privacy_class": "public",
		"observed_public_items": public_items,
		"observed_item_count": _observed_item_count(),
		"observed_card_count": _observed_card_count(),
		"observed_resource_count": _observed_resource_count(),
		"observed_hazards": _observed_hazards.duplicate(),
		"observed_encounters": _observed_encounters.duplicate(),
		"unresolved_rescue_count": _rescue_state.unresolved.size(),
		"rescued_count": _rescue_state.rescued.size(),
		"public_resource_pressure": _public_resource_pressure(),
		"ending_eligibility_count": ENDINGS.size(),
		"ending_resolved": not _ending_id.is_empty(),
		"ending_id": _ending_id,
	}


func replacement_route_available() -> bool:
	return _rescue_state.replacement_route_available and _resources.lifeboat_capacity > 0


func submerged_rescue_route_available() -> bool:
	return _observed_hazards.has("returning_current") or not _rescue_state.unresolved.is_empty()


func ending_id() -> String:
	return _ending_id


func ending_resolution_id() -> String:
	return _ending_resolution_id


func public_resource_pressure() -> int:
	return _public_resource_pressure()


func unresolved_rescue_count() -> int:
	return _rescue_state.unresolved.size()


func authoritative_inventory() -> Dictionary:
	return {
		"items": _items.duplicate(true),
		"cards": _cards.duplicate(true),
		"resources": _resources.duplicate(true),
		"observed_hazards": _observed_hazards.duplicate(),
		"observed_encounters": _observed_encounters.duplicate(),
		"rescue_state": _rescue_state.duplicate(true),
	}


func to_snapshot() -> Dictionary:
	return {
		"items": _items.duplicate(true),
		"cards": _cards.duplicate(true),
		"resources": _resources.duplicate(true),
		"observed_hazards": _observed_hazards.duplicate(),
		"observed_encounters": _observed_encounters.duplicate(),
		"rescue_state": _rescue_state.duplicate(true),
		"ending_id": _ending_id,
		"ending_resolution_id": _ending_resolution_id,
		"content_history": _content_history.duplicate(true),
	}


func restore_snapshot(snapshot: Dictionary) -> Dictionary:
	if not _has_exact_keys(snapshot, SNAPSHOT_KEYS):
		return _rejected("malformed_rules_snapshot")
	if (
		not snapshot.items is Dictionary
		or not snapshot.cards is Dictionary
		or not snapshot.resources is Dictionary
		or not snapshot.observed_hazards is Array
		or not snapshot.observed_encounters is Array
		or not snapshot.rescue_state is Dictionary
		or not snapshot.ending_id is String
		or not snapshot.ending_resolution_id is String
		or not snapshot.content_history is Array
		or not _same_keys(snapshot.items, Array(ITEMS))
		or not _same_keys(snapshot.cards, Array(CARDS))
		or not _same_keys(snapshot.resources, Array(RESOURCES))
	):
		return _rejected("malformed_rules_snapshot")
	if (
		not snapshot.ending_resolution_id.is_empty()
		and snapshot.ending_resolution_id.length() != 64
	):
		return _rejected("malformed_rules_snapshot")
	_items = snapshot.items.duplicate(true)
	_cards = snapshot.cards.duplicate(true)
	_resources = snapshot.resources.duplicate(true)
	_observed_hazards = _string_array(snapshot.observed_hazards)
	_observed_encounters = _string_array(snapshot.observed_encounters)
	_rescue_state = snapshot.rescue_state.duplicate(true)
	_ending_id = snapshot.ending_id
	_ending_resolution_id = snapshot.ending_resolution_id
	_content_history = _dictionary_array(snapshot.content_history)
	return {"accepted": true, "reason": ""}


func _initialize_content() -> void:
	for index: int in ITEMS.size():
		var owner_class: String = OWNERSHIP_CLASSES[index % OWNERSHIP_CLASSES.size()]
		var owner_id: String = owner_class
		if owner_class == "seat_owned":
			owner_id = _stable_seat_order[index % _stable_seat_order.size()]
		_items[ITEMS[index]] = {
			"state": "intact",
			"charges": 2,
			"ownership_class": owner_class,
			"owner_id": owner_id,
			"ownership_identity":
			("drowned_harbor_alpha3|item|%s|%s" % [ITEMS[index], owner_id]).sha256_text(),
			"observed": false,
		}
	for card_id: String in CARDS:
		_cards[card_id] = {"charges": 8, "observed": false}
	for resource_id: String in RESOURCES:
		_resources[resource_id] = 8
	_resources.lifeboat_capacity = 8


func _observed_item_count() -> int:
	var result: int = 0
	for row: Dictionary in _items.values():
		if row.observed:
			result += 1
	return result


func _observed_card_count() -> int:
	var result: int = 0
	for row: Dictionary in _cards.values():
		if row.observed:
			result += 1
	return result


func _observed_resource_count() -> int:
	var result: int = 0
	for resource_id: String in RESOURCES:
		if _resources[resource_id] < 8:
			result += 1
	return result


func _public_resource_pressure() -> int:
	var pressure: int = 0
	for resource_id: String in RESOURCES:
		pressure += 8 - int(_resources[resource_id])
	return pressure


static func _same_keys(value: Dictionary, expected: Array) -> bool:
	var actual: Array = value.keys()
	actual.sort()
	expected.sort()
	return actual == expected


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
