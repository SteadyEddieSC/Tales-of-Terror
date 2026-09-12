class_name DrownedHarborDemoContent
extends RefCounted

## Authored Alpha.4 policy. Costs and rewards are complete, validated bundles.
const PHASES: PackedStringArray = [
	"low_tide",
	"bellhouse",
	"council",
	"high_water",
	"flood",
	"last_light",
	"ending",
	"epilogue",
	"complete"
]
const STAGES: Dictionary = {
	"low_tide":
	[
		"The Harbor at Low Tide",
		"Explore before the water returns. Recover records, gather oil, and protect escape capacity."
	],
	"bellhouse":
	[
		"The Bellhouse Ledger",
		(
			"The Council wrecked a relief ship, then tried to erase its witnesses. Choose "
			+ "which truth to follow."
		)
	],
	"council":
	[
		"Council Beneath the Light",
		"Each witness chooses a course. The strongest mandate guides the ending; ties favor containment."
	],
	"high_water":
	[
		"The Terror Turn",
		(
			"The low road is drowning. Confirm when everyone is ready: High Water changes "
			+ "the routes and objective."
		)
	],
	"flood":
	[
		"High Water",
		(
			"Rescue the stranded, protect your supplies, or bargain with the Harbor. Every "
			+ "action spends remaining tide."
		)
	],
	"last_light":
	[
		"Last Light",
		(
			"Choose what the lighthouse will carry home. Your evidence, preparation, and "
			+ "final commitments decide the ending."
		)
	],
	"ending":
	[
		"The Harbor Remembers",
		"The last bell is waiting. Resolve the consequences of your crew's choices."
	],
	"epilogue":
	[
		"What Came Home",
		(
			"The Underteller records the public outcome. Your private account is available "
			+ "behind the shield."
		)
	],
	"complete":
	[
		"Until the Next Low Tide",
		"Your Tale is complete. Rematch with the same crew, or return to the title."
	],
}
const ACTIONS: Dictionary = {
	"refuse_bargain":
	{
		"label": "Refuse the Harbor's offer",
		"detail": "Keep your name. Gain 1 rope and lower claim by 1. Outbreak allows one refusal.",
		"phases": ["flood"],
		"gain": {"rope": 1},
		"claim": -1,
		"social": "refuse",
		"once_per_seat": true,
		"tag": "safety"
	},
	"declare_allegiance":
	{
		"label": "Declare your allegiance",
		"detail":
		"Publicly reveal your allegiance and gain 1 memory. This declaration cannot be hidden again.",
		"phases": ["flood"],
		"gain": {"memory_fragments": 1},
		"social": "reveal",
		"once_per_seat": true,
		"tag": "reveal"
	},
	"restless_warn":
	{
		"label": "Guide the crew from beyond",
		"detail":
		"Use your continuation: gain 1 memory and lower claim by 2. You remain in the Tale.",
		"phases": ["flood"],
		"gain": {"memory_fragments": 1},
		"claim": -2,
		"continuation": true,
		"tag": "continuation"
	},
	"search_manifest":
	{
		"label": "Search the harbor office",
		"detail": "Recover a record fragment and a compass. Costs 1 dry match.",
		"phases": ["low_tide"],
		"cost": {"dry_matches": 1},
		"gain": {"memory_fragments": 1},
		"item": "dead_mans_compass",
		"once": true,
		"destination": "low_tide_market",
		"tag": "evidence"
	},
	"search_wreck":
	{
		"label": "Search the wreckers' stall",
		"detail": "Recover a survivor's record and a hook. Costs 1 rope.",
		"phases": ["low_tide"],
		"cost": {"rope": 1},
		"gain": {"memory_fragments": 1},
		"item": "wreckers_hook",
		"once": true,
		"destination": "low_tide_market",
		"tag": "evidence"
	},
	"salvage_oil":
	{
		"label": "Salvage lamp oil",
		"detail":
		"Gain 2 lamp oil and a lantern. The drowned patrol raises the Harbor's claim by 1.",
		## Authored Alpha.4 policy. Costs and rewards are complete, validated bundles.
		"phases": ["low_tide", "flood"],
		"gain": {"lamp_oil": 2},
		"item": "tin_lantern",
		"claim": 1,
		"hazard": "drowned_patrol",
		"destination": "low_tide_market",
		"tag": "supply"
	},
	"secure_boat":
	{
		"label": "Secure the lifeboat",
		"detail": "Spend 1 rope to preserve 2 escape places. Gain Hold Fast.",
		"phases": ["low_tide", "flood"],
		"cost": {"rope": 1},
		"gain": {"lifeboat_capacity": 2},
		"card": "hold_fast",
		"destination": "bellhouse",
		"tag": "safety"
	},
	"shelter":
	{
		"label": "Shelter and bind ropes",
		"detail":
		"Gather 1 rope and steady the crew: Harbor claim falls by 1. You spend a tide action.",
		"phases": ["low_tide", "flood"],
		"gain": {"rope": 1},
		"claim": -1,
		"destination": "bellhouse",
		"tag": "safety"
	},
	"aid_resident":
	{
		"label": "Rescue a stranded resident",
		"detail":
		"Spend 1 escape place to rescue a resident. Gain a memory fragment and Share the Weight.",
		"phases": ["low_tide", "flood"],
		"rescue": true,
		"gain": {"memory_fragments": 1},
		"card": "share_the_weight",
		"destination": "bellhouse",
		"tag": "rescue"
	},
	"follow_names":
	{
		"label": "Follow the names",
		"detail":
		"Preserve the ledger and recover the missing name. Gain 2 memory fragments; strengthen release.",
		"phases": ["bellhouse"],
		"gain": {"memory_fragments": 2},
		"mandate": "release",
		"item": "missing_name_tablet",
		"tag": "evidence"
	},
	"follow_light":
	{
		"label": "Follow the light",
		"detail":
		"Recover the cracked lens and 2 lamp oil. Strengthen the signal that can guide the Harbor home.",
		"phases": ["bellhouse"],
		"gain": {"lamp_oil": 2},
		"mandate": "restore",
		"item": "cracked_lighthouse_lens",
		"tag": "supply"
	},
	"follow_missing":
	{
		"label": "Follow the missing",
		"detail":
		"Open an escape route and remember a survivor. Gain 2 escape places and 1 memory fragment.",
		"phases": ["bellhouse"],
		"gain": {"lifeboat_capacity": 2, "memory_fragments": 1},
		"mandate": "escape",
		"item": "oilskin_satchel",
		"tag": "rescue"
	},
	"vote_restore":
	{
		"label": "Restore the light",
		"detail":
		"Commit to bringing the light home. Final success needs lamp oil and living witnesses.",
		"phases": ["council"],
		"mandate": "restore",
		"tag": "council"
	},
	"vote_seal":
	{
		"label": "Extinguish and contain",
		"detail":
		"Commit to sealing the Harbor. Preserve salt and records for the final mechanism.",
		"phases": ["council"],
		"mandate": "seal",
		"tag": "council"
	},
	"vote_release":
	{
		"label": "Turn the light inland",
		"detail":
		"Commit to releasing the drowned. Find at least 3 memory fragments and rescue a resident.",
		"phases": ["council"],
		"mandate": "release",
		"tag": "council"
	},
	"vote_escape":
	{
		"label": "Preserve the escape route",
		"detail": "Commit to evacuating the living. Reserve one lifeboat place for each witness.",
		"phases": ["council"],
		"mandate": "escape",
		"tag": "council"
	},
	"raise_tide":
	{
		"label": "Face High Water",
		"detail": "Close the low road, open the submerged channel, and begin the last tide budget.",
		"phases": ["high_water"],
		"tag": "transition"
	},
	"search_archive":
	{
		"label": "Enter the drowned archive",
		"detail":
		"Gain 2 memory fragments and Borrowed Breath. The cold water raises Harbor claim by 2.",
		"phases": ["flood"],
		"gain": {"memory_fragments": 2},
		"card": "borrowed_breath",
		"claim": 2,
		"hazard": "water_in_lungs",
		"once": true,
		"destination": "high_water_channel",
		"tag": "evidence"
	},
	"salt_ward":
	{
		"label": "Raise a salt ward",
		"detail": "Spend 1 memory fragment for 2 salt marks. Lower Harbor claim by 1.",
		"phases": ["flood"],
		"cost": {"memory_fragments": 1},
		"gain": {"salt_marks": 2},
		"claim": -1,
		"destination": "lighthouse_council",
		"tag": "safety"
	},
	"harbor_bargain":
	{
		"label": "Accept a harbor bargain",
		"detail":
		"Gain 3 oil; claim rises by 3. In Outbreak, a bargain after your refusal makes you Tidebound.",
		"phases": ["flood"],
		"gain": {"lamp_oil": 3},
		"claim": 3,
		"social": "bargain",
		"destination": "high_water_channel",
		"tag": "bargain"
	},
	"spend_hold_fast":
	{
		"label": "Play Hold Fast",
		"detail": "Spend your card to gain 2 rope and lower Harbor claim by 2.",
		"phases": ["flood"],
		"spend_card": "hold_fast",
		"gain": {"rope": 2},
		"claim": -2,
		"tag": "card"
	},
	"spend_shared_weight":
	{
		"label": "Play Share the Weight",
		"detail":
		"Spend your card to gain 2 escape places and steady the crew: Harbor claim falls by 1.",
		"phases": ["flood"],
		"spend_card": "share_the_weight",
		"gain": {"lifeboat_capacity": 2},
		"claim": -1,
		"tag": "card"
	},
	"spend_breath":
	{
		"label": "Play Borrowed Breath",
		"detail":
		"Spend your card to retrieve 2 salt marks from beneath the water without further exposure.",
		"phases": ["flood"],
		"spend_card": "borrowed_breath",
		"gain": {"salt_marks": 2},
		"tag": "card"
	},
	"final_restore":
	{
		"label": "Carry the light home",
		"detail":
		"Final vote: restore the signal. Requires at least 3 oil and Harbor claim below 8.",
		"phases": ["last_light"],
		"mandate": "restore",
		"tag": "final"
	},
	"final_seal":
	{
		"label": "Seal the Harbor",
		"detail":
		"Final vote: contain the mechanism. Requires 2 salt marks and 2 memory fragments.",
		"phases": ["last_light"],
		"mandate": "seal",
		"tag": "final"
	},
	"final_release":
	{
		"label": "Release the drowned",
		"detail":
		"Final vote: give the dead their names. Requires 3 memory fragments and one rescued resident.",
		"phases": ["last_light"],
		"mandate": "release",
		"tag": "final"
	},
	"final_escape":
	{
		"label": "Launch the last lifeboat",
		"detail":
		"Final vote: escape with the witnesses. Requires one remaining escape place per stable seat.",
		"phases": ["last_light"],
		"mandate": "escape",
		"tag": "final"
	},
	"resolve":
	{
		"label": "Ring the last bell",
		"detail":
		"Resolve the ending from your final votes, records, supplies, rescues, and Harbor claim.",
		"phases": ["ending"],
		"tag": "ending"
	},
	"remember":
	{
		"label": "Remember what came home",
		"detail": "Complete the Tale. Private objectives remain behind each witness's shield.",
		"phases": ["epilogue"],
		"tag": "epilogue"
	},
}
const MENUS: Dictionary = {
	"low_tide":
	["search_manifest", "search_wreck", "salvage_oil", "secure_boat", "shelter", "aid_resident"],
	"bellhouse": ["follow_names", "follow_light", "follow_missing"],
	"council": ["vote_restore", "vote_seal", "vote_release", "vote_escape"],
	"high_water": ["raise_tide"],
	"flood":
	[
		"aid_resident",
		"search_archive",
		"salt_ward",
		"harbor_bargain",
		"refuse_bargain",
		"salvage_oil",
		"shelter",
		"declare_allegiance"
	],
	"last_light": ["final_restore", "final_seal", "final_release", "final_escape"],
	"ending": ["resolve"],
	"epilogue": ["remember"],
	"complete": [],
}
const OUTCOMES: Dictionary = {
	"drowned_released":
	[
		"The Drowned Released",
		(
			"You spoke the stolen names into the inland light. The dead left their "
			+ "unfinished streets, and the sea closed over an empty town."
		)
	],
	"harbor_sealed":
	[
		"The Harbor Sealed",
		(
			"Salt blackened the lens. You kept enough truth to seal the mechanism without "
			+ "forgetting its victims. The Harbor can no longer call new witnesses."
		)
	],
	"last_lifeboat":
	[
		"The Last Lifeboat",
		(
			"Every witness found a place aboard. Behind you, the bell continued counting. "
			+ "You escaped the Harbor, though the Harbor has not finished with remembrance."
		)
	],
	"light_comes_home":
	[
		"The Light Comes Home",
		(
			"You restored a signal that guides ships past the wrecks. The light crossed the "
			+ "water with your witnesses, carrying memory without repeating the Council's "
			+ "crime."
		)
	],
	"harbor_rises":
	[
		"The Harbor Rises",
		(
			"Too many bargains fed the light. Your signal gave the Harbor a destination. At "
			+ "dawn, unfamiliar wet streets appeared beyond the shore."
		)
	],
	"mixed_outcomes":
	[
		"What the Water Kept",
		(
			"Your preparations could not fulfill the final commitment. Some names reached "
			+ "safety; others remained in the bell. The survivors carry an unfinished "
			+ "obligation."
		)
	],
	"names_erased":
	[
		"The Names Erased",
		(
			"Without records or a safe passage, the final light repeated the Council's "
			+ "erasure. The sea became still. Somewhere, a ledger opened to a clean page."
		)
	],
}
const OBJECTIVES: Dictionary = {
	"recover_the_truth":
	"Recover at least 3 memory fragments so the Council's crime cannot be erased.",
	"preserve_escape_capacity": "Keep one lifeboat place for every witness through the final bell.",
	"protect_another_witness": "Rescue a stranded resident before the last light.",
	"contain_the_harbor": "Help achieve the Harbor Sealed ending.",
	"release_the_drowned": "Help achieve the Drowned Released ending.",
	"carry_memory_safely": "Finish with records and at least one safe route still available.",
}

const ROUTE_ACTIONS: Dictionary = {
	"bellhouse":
	[
		{"intent": "inspect_ledger", "first_seat": true},
		{"intent": "commit_bellhouse_choice", "payload": {"choice_id": "preserve_public_ledger"}},
	],
	"council":
	[{"intent": "submit_council_commitment", "payload": {"commitment": "hold_the_light"}}],
	"high_water":
	[{"intent": "acknowledge_high_water"}, {"intent": "apply_high_water_transformation"}],
	"last_light":
	[
		{"intent": "move_to_last_light_route", "payload": {"destination": "last_light_beacon"}},
		{"intent": "commit_last_light_action", "payload": {"commitment": "guard_last_light"}},
	],
	"ending": [{"intent": "resolve_ending"}],
	"epilogue": [{"intent": "resolve_epilogue_attribution"}, {"intent": "acknowledge_epilogue"}],
}
const OBJECTIVE_CONDITIONS: Dictionary = {
	"recover_the_truth": [{"path": "resources.memory_fragments", "min": 3}],
	"preserve_escape_capacity":
	[{"path": "resources.lifeboat_capacity", "min_field": "seat_count"}],
	"protect_another_witness": [{"path": "rescued_count", "min": 1}],
	"contain_the_harbor": [{"path": "ending_id", "equal": "harbor_sealed"}],
	"release_the_drowned": [{"path": "ending_id", "equal": "drowned_released"}],
	"carry_memory_safely":
	[
		{"path": "resources.memory_fragments", "min": 1},
		{"path": "resources.lifeboat_capacity", "min": 1}
	],
}
const ENDING_POLICIES: Array[Dictionary] = [
	{"id": "harbor_rises", "conditions": [{"path": "claim", "min": 8}]},
	{
		"id": "drowned_released",
		"mandate": "release",
		"conditions":
		[{"path": "resources.memory_fragments", "min": 3}, {"path": "rescued_count", "min": 1}]
	},
	{
		"id": "harbor_sealed",
		"mandate": "seal",
		"conditions":
		[
			{"path": "resources.salt_marks", "min": 2},
			{"path": "resources.memory_fragments", "min": 2}
		]
	},
	{
		"id": "last_lifeboat",
		"mandate": "escape",
		"conditions": [{"path": "resources.lifeboat_capacity", "min_field": "seat_count"}]
	},
	{
		"id": "light_comes_home",
		"mandate": "restore",
		"conditions": [{"path": "resources.lamp_oil", "min": 3}]
	},
	{
		"id": "names_erased",
		"conditions":
		[
			{"path": "resources.memory_fragments", "equal": 0},
			{"path": "resources.lifeboat_capacity", "equal": 0}
		]
	},
	{"id": "mixed_outcomes", "conditions": []},
]

const DIRECTOR_EFFECTS: Dictionary = {
	"harbor_pressure":
	{"claim": 1, "text": "The patrol changes its route. Harbor claim rises by 1."},
	"light_pressure":
	{"resource": "lamp_oil", "delta": -1, "text": "A gust drinks a lantern's oil. Lose 1 oil."},
	"memory_pressure":
	{
		"resource": "memory_fragments",
		"delta": 1,
		"text": "A drowned witness leaves a record. Gain 1 memory."
	},
	"rescue_pressure":
	{"resource": "rope", "delta": 1, "text": "A coil catches on a bollard. Gain 1 rope."},
	"route_pressure":
	{
		"resource": "salt_marks",
		"delta": 1,
		"text": "The retreating spray leaves a ward. Gain 1 salt mark."
	},
}
const CONTINUATION_FORMS: PackedStringArray = [
	"bell_witness", "drowned_guide", "lighthouse_guardian", "lifeboat_survivor"
]


static func validate_content(
	actions: Dictionary = ACTIONS,
	menus: Dictionary = MENUS,
	policies: Array = ENDING_POLICIES,
	objectives: Dictionary = OBJECTIVE_CONDITIONS,
	director_effects: Dictionary = DIRECTOR_EFFECTS
) -> Dictionary:
	var valid: bool = actions.size() > 0 and actions.size() <= 64
	for phase_id: String in PHASES:
		valid = valid and STAGES.has(phase_id) and menus.get(phase_id) is Array
	for action_id: Variant in actions:
		valid = valid and action_id is String and actions[action_id] is Dictionary
		if actions[action_id] is Dictionary:
			valid = valid and _valid_action(actions[action_id])
	for phase_id: Variant in menus:
		valid = valid and phase_id is String and PHASES.has(phase_id)
		if not menus[phase_id] is Array:
			valid = false
			continue
		for action_id: Variant in menus[phase_id]:
			if not action_id is String or not actions.get(action_id) is Dictionary:
				valid = false
			else:
				valid = valid and actions[action_id].get("phases", []).has(phase_id)
	valid = valid and _valid_policies(policies, objectives, director_effects)
	return {"accepted": valid, "reason": "" if valid else "invalid_authored_demo_content"}


static func _valid_action(row: Dictionary) -> bool:
	var allowed: PackedStringArray = [
		"label",
		"detail",
		"phases",
		"cost",
		"gain",
		"item",
		"once",
		"destination",
		"tag",
		"card",
		"claim",
		"hazard",
		"rescue",
		"mandate",
		"social",
		"spend_card",
		"once_per_seat",
		"continuation"
	]
	var valid: bool = row.get("label") is String and row.get("detail") is String
	valid = valid and row.get("phases") is Array and row.get("tag") is String
	if not valid:
		return false
	valid = row.label.length() > 0 and row.label.length() <= 40 and row.detail.length() <= 160
	for key: Variant in row:
		valid = valid and key is String and allowed.has(key)
	for phase_id: Variant in row.phases:
		valid = valid and phase_id is String and PHASES.has(phase_id)
	valid = valid and not row.phases.is_empty()
	for field: String in ["cost", "gain"]:
		valid = valid and _valid_resource_bundle(row.get(field, {}))
	for field: String in ["once", "once_per_seat", "rescue", "continuation"]:
		valid = valid and (not row.has(field) or row[field] is bool)
	valid = valid and (not row.has("claim") or row.claim is int and absi(row.claim) <= 20)
	var inventories: Dictionary = {
		"item": DrownedHarborAlpha3RulesAuthority.ITEMS,
		"card": DrownedHarborAlpha3RulesAuthority.CARDS,
		"spend_card": DrownedHarborAlpha3RulesAuthority.CARDS,
		"hazard": DrownedHarborAlpha3RulesAuthority.HAZARDS,
		"mandate": ["seal", "release", "escape", "restore"],
		"social": ["refuse", "reveal", "bargain"],
		"destination": ["low_tide_market", "bellhouse", "lighthouse_council", "high_water_channel"]
	}
	for field: String in inventories:
		valid = valid and (not row.has(field) or inventories[field].has(row[field]))
	return valid


static func _valid_resource_bundle(bundle: Variant) -> bool:
	if not bundle is Dictionary:
		return false
	var valid: bool = true
	for resource: Variant in bundle:
		valid = (
			valid
			and resource is String
			and DrownedHarborAlpha3RulesAuthority.RESOURCES.has(resource)
		)
		valid = (
			valid and bundle[resource] is int and bundle[resource] > 0 and bundle[resource] <= 64
		)
	return valid


static func _valid_policies(policies: Array, objectives: Dictionary, effects: Dictionary) -> bool:
	var seen: Array[String] = []
	var valid: bool = policies.size() == DrownedHarborAlpha3RulesAuthority.ENDINGS.size()
	for policy: Variant in policies:
		if not policy is Dictionary or not policy.get("id") is String:
			valid = false
			continue
		valid = valid and OUTCOMES.has(policy.id) and not seen.has(policy.id)
		valid = valid and _valid_conditions(policy.get("conditions"))
		seen.append(policy.id)
	for objective: String in DrownedHarborAlpha3RoleAuthority.LIVING_OBJECTIVES:
		valid = valid and _valid_conditions(objectives.get(objective))
	for candidate: String in DrownedHarborAlpha3Session.DIRECTOR_CANDIDATES:
		if not effects.get(candidate) is Dictionary:
			valid = false
			continue
		var row: Dictionary = effects[candidate]
		valid = valid and row.get("text") is String
		valid = valid and (not row.has("claim") or row.claim is int and absi(row.claim) <= 20)
		if row.has("resource"):
			valid = valid and DrownedHarborAlpha3RulesAuthority.RESOURCES.has(row.resource)
			valid = valid and row.get("delta") is int and absi(row.delta) <= 64
	return valid


static func _valid_conditions(value: Variant) -> bool:
	if not value is Array:
		return false
	var valid: bool = value.size() <= 8
	for row: Variant in value:
		if not row is Dictionary or not row.get("path") is String:
			valid = false
			continue
		var path: String = row.path
		var known: bool = path in ["claim", "rescued_count", "ending_id"]
		if path.begins_with("resources."):
			known = DrownedHarborAlpha3RulesAuthority.RESOURCES.has(path.trim_prefix("resources."))
		valid = valid and known and row.size() == 2
		var comparator: bool = row.has("min") and row.min is int and row.min >= 0
		comparator = comparator or row.has("min_field") and row.min_field == "seat_count"
		comparator = comparator or row.has("equal") and (row.equal is int or row.equal is String)
		valid = valid and comparator
	return valid


static func conditions_met(state: Dictionary, conditions: Array) -> bool:
	for condition: Dictionary in conditions:
		var value: Variant = state
		for segment: String in str(condition.path).split("."):
			if not value is Dictionary or not value.has(segment):
				return false
			value = value[segment]
		if condition.has("equal") and value != condition.equal:
			return false
		if condition.has("min") and int(value) < int(condition.min):
			return false
		if condition.has("min_field") and int(value) < int(state[condition.min_field]):
			return false
	return true


static func title_for(value: String) -> String:
	return value.replace("_", " ").capitalize()


static func outcome(value: String) -> Dictionary:
	if not OUTCOMES.has(value):
		return {}
	return {"id": value, "title": OUTCOMES[value][0], "text": OUTCOMES[value][1]}


class Rules:
	extends DrownedHarborAlpha3RulesAuthority

	var phase_index: int = 0
	var phase_turn: int = 0
	var claim: int = 0
	var discovered: Array[String] = []
	var votes: Dictionary = {"restore": 0, "seal": 0, "release": 0, "escape": 0}
	var final_votes: Dictionary = {"restore": 0, "seal": 0, "release": 0, "escape": 0}
	var hands: Dictionary = {}
	var choices: Array[Dictionary] = []
	var bargains: Dictionary = {}
	var director_note: String = ""

	func _init(seed: int, seats: PackedStringArray) -> void:
		super(seed, seats)
		_resources = {
			"bell_tokens": 0,
			"dry_matches": 3,
			"harbor_keys": 1,
			"lamp_oil": 2 + seats.size(),
			"lifeboat_capacity": mini(8, seats.size() + 2),
			"memory_fragments": 0,
			"rope": 3,
			"salt_marks": 2
		}
		for seat: String in seats:
			hands[seat] = []
			bargains[seat] = 0

	func phase() -> String:
		return DrownedHarborDemoContent.PHASES[phase_index]

	func active_seat() -> String:
		return _stable_seat_order[phase_turn % _stable_seat_order.size()]

	func phase_limit() -> int:
		match phase():
			"low_tide":
				return maxi(4, _stable_seat_order.size() * 2)
			"flood":
				return maxi(3, _stable_seat_order.size() * 2)
			"council", "last_light":
				return _stable_seat_order.size()
			_:
				return 1

	func available(action_id: String, seat: String) -> bool:
		if seat != active_seat() or not DrownedHarborDemoContent.ACTIONS.has(action_id):
			return false
		var row: Dictionary = DrownedHarborDemoContent.ACTIONS[action_id]
		if not row.phases.has(phase()) or row.get("once", false) and discovered.has(action_id):
			return false
		if row.get("once_per_seat", false) and discovered.has(action_id + ":" + seat):
			return false
		for resource: String in row.get("cost", {}):
			if int(_resources[resource]) < int(row.cost[resource]):
				return false
		if row.get("rescue", false) and int(_resources.lifeboat_capacity) <= 0:
			return false
		return not row.has("spend_card") or hands[seat].has(row.spend_card)

	func menu() -> Array[Dictionary]:
		var result: Array[Dictionary] = []
		var ids: Array = DrownedHarborDemoContent.MENUS[phase()].duplicate()
		if phase() == "flood":
			for card_action: String in ["spend_hold_fast", "spend_shared_weight", "spend_breath"]:
				if available(card_action, active_seat()):
					ids.push_front(card_action)
		for action_id: String in ids:
			if not available(action_id, active_seat()):
				continue
			var row: Dictionary = DrownedHarborDemoContent.ACTIONS[action_id]
			result.append({"id": action_id, "label": row.label, "detail": row.detail})
		return result

	func apply_choice(action_id: String, seat: String) -> Dictionary:
		if not available(action_id, seat):
			return {"accepted": false, "reason": "choice_unavailable"}
		var row: Dictionary = DrownedHarborDemoContent.ACTIONS[action_id]
		for resource: String in row.get("cost", {}):
			_resources[resource] -= int(row.cost[resource])
		for resource: String in row.get("gain", {}):
			_resources[resource] = mini(64, int(_resources[resource]) + int(row.gain[resource]))
		claim = clampi(claim + int(row.get("claim", 0)), 0, 20)
		if row.has("item"):
			var item: Dictionary = _items[row.item]
			if not _items[row.item].observed:
				item.owner_id = seat
			item.observed = true
			item.ownership_class = "seat_owned"
			_items[row.item] = item
		if row.has("card"):
			hands[seat].append(row.card)
			_cards[row.card].observed = true
		if row.has("spend_card"):
			hands[seat].erase(row.spend_card)
		if row.has("hazard") and not _observed_hazards.has(row.hazard):
			_observed_hazards.append(row.hazard)
		if row.has("mandate"):
			var tally: Dictionary = final_votes if phase() == "last_light" else votes
			tally[row.mandate] += 1
		if row.get("social", "") == "bargain":
			bargains[seat] += 1
		discovered.append(action_id)
		if row.get("once_per_seat", false):
			discovered.append(action_id + ":" + seat)
		choices.append({"action": action_id, "seat": seat, "phase": phase(), "tag": row.tag})
		phase_turn += 1
		if phase_turn >= phase_limit():
			phase_index += 1
			phase_turn = 0
		return {"accepted": true, "reason": ""}

	func resolve_ending(_sequence_index: int, revision: int) -> Dictionary:
		var mandate: String = "seal"
		for option: String in ["seal", "release", "escape", "restore"]:
			if (
				final_votes[option] > final_votes[mandate]
				or (final_votes[option] == final_votes[mandate] and votes[option] > votes[mandate])
			):
				mandate = option
		var state: Dictionary = public_view()
		state.seat_count = _stable_seat_order.size()
		for policy: Dictionary in DrownedHarborDemoContent.ENDING_POLICIES:
			if policy.has("mandate") and policy.mandate != mandate:
				continue
			if DrownedHarborDemoContent.conditions_met(state, policy.conditions):
				return super(ENDINGS.find(policy.id), revision)
		return {"accepted": false, "reason": "ending_policy_missing"}

	func apply_director_candidate(candidate_id: String) -> Dictionary:
		if not DrownedHarborDemoContent.DIRECTOR_EFFECTS.has(candidate_id):
			return {"accepted": false, "reason": "unknown_director_proposal"}
		var row: Dictionary = DrownedHarborDemoContent.DIRECTOR_EFFECTS[candidate_id]
		if row.has("resource"):
			var next: int = int(_resources[row.resource]) + int(row.delta)
			if next < 0 or next > 64:
				return {"accepted": false, "reason": "director_resource_bound"}
			_resources[row.resource] = next
		claim = clampi(claim + int(row.get("claim", 0)), 0, 20)
		director_note = row.text
		return {"accepted": true, "reason": ""}

	func public_view() -> Dictionary:
		var result: Dictionary = super()
		result.resources = _resources.duplicate(true)
		result.claim = claim
		result.director_note = director_note
		result.phase = phase()
		result.turn = phase_turn
		result.turn_limit = phase_limit()
		result.votes = votes.duplicate(true)
		result.final_votes = final_votes.duplicate(true)
		result.choices = choices.duplicate(true)
		result.hands = hands.duplicate(true)
		result.inventory = []
		for item_id: String in ITEMS:
			var row: Dictionary = _items[item_id]
			if row.observed and row.ownership_class != "faction_private":
				result.inventory.append(
					{
						"id": item_id,
						"owner": row.owner_id,
						"name": DrownedHarborDemoContent.title_for(item_id),
						"charges": row.charges
					}
				)
		return result

	func to_snapshot() -> Dictionary:
		var result: Dictionary = super()
		result.alpha4 = {
			"phase_index": phase_index,
			"phase_turn": phase_turn,
			"claim": claim,
			"discovered": discovered.duplicate(),
			"votes": votes.duplicate(true),
			"final_votes": final_votes.duplicate(true),
			"hands": hands.duplicate(true),
			"choices": choices.duplicate(true),
			"bargains": bargains.duplicate(true),
			"director_note": director_note
		}
		return result

	func restore_snapshot(value: Dictionary) -> Dictionary:
		if not value.get("alpha4") is Dictionary:
			return {"accepted": false, "reason": "alpha4_rules_required"}
		var base: Dictionary = value.duplicate(true)
		base.erase("alpha4")
		var result: Dictionary = super(base)
		if not result.accepted:
			return result
		var state: Dictionary = value.alpha4
		phase_index = state.phase_index
		phase_turn = state.phase_turn
		claim = state.claim
		discovered.assign(state.discovered)
		votes = state.votes.duplicate(true)
		final_votes = state.final_votes.duplicate(true)
		hands = state.hands.duplicate(true)
		choices.assign(state.choices)
		bargains = state.bargains.duplicate(true)
		director_note = state.director_note
		return result
