class_name VerticalSliceManifest
extends RefCounted

const MANIFEST_VERSION: int = 1
const REQUIRED_KEYS: PackedStringArray = [
	"manifest_version",
	"scenario_id",
	"scenario_version",
	"board_reference",
	"rules_reference",
	"director_reference",
	"director_profile",
	"social_reference",
	"default_mode",
	"fallback_mode",
	"supported_seats",
	"briefing",
	"public_objective",
	"stages",
	"terminal_policy",
	"ending",
	"rematch_policy",
	"companion_policy",
	"fixture",
]
const STAGE_KEYS: PackedStringArray = [
	"id", "title", "entry_condition", "completion_condition", "operations"
]
const OPERATION_TYPES: PackedStringArray = [
	"queue_event",
	"resolve_event",
	"submit_prompt",
	"resolve_prompt",
	"open_vote",
	"submit_vote",
	"resolve_vote",
	"resolve_check",
	"apply_effects",
	"play_card",
	"director_evaluate",
	"role_transition",
	"role_action",
	"resolve_outcomes",
	"complete_rules",
]
const OPERATION_KEYS: Dictionary = {
	"queue_event": ["type", "event_id"],
	"resolve_event": ["type"],
	"submit_prompt": ["type", "option_id"],
	"resolve_prompt": ["type"],
	"open_vote": ["type"],
	"submit_vote": ["type", "odd_option", "even_option"],
	"resolve_vote": ["type"],
	"resolve_check": ["type", "check_id"],
	"apply_effects": ["type", "fixture"],
	"play_card": ["type", "card_id"],
	"director_evaluate": ["type"],
	"role_transition": ["type", "selector_tag", "trigger"],
	"role_action": ["type", "selector_tag", "action_tag"],
	"resolve_outcomes": ["type"],
	"complete_rules": ["type", "result"],
}
const STAGE_CONDITIONS: PackedStringArray = [
	"briefing_acknowledged",
	"threshold_prompt_resolved",
	"archive_revealed",
	"public_vote_resolved",
	"council_resolved",
	"check_card_and_director_resolved",
	"reckoning_resolved",
	"afterlife_action_resolved",
	"afterlife_resolved",
	"terminal_result_committed",
]
const STAGE_ORDER: PackedStringArray = ["threshold", "council", "reckoning", "afterlife", "ending"]
const STAGE_CONDITION_POLICY: Dictionary = {
	"threshold": ["briefing_acknowledged", "threshold_prompt_resolved"],
	"council": ["archive_revealed", "public_vote_resolved"],
	"reckoning": ["council_resolved", "check_card_and_director_resolved"],
	"afterlife": ["reckoning_resolved", "afterlife_action_resolved"],
	"ending": ["afterlife_resolved", "terminal_result_committed"],
}
const STAGE_OPERATION_POLICY: Dictionary = {
	"threshold":
	[
		{"type": "queue_event", "event_id": "threshold_whisper"},
		{"type": "resolve_event"},
		{"type": "submit_prompt", "option_id": "listen"},
		{"type": "resolve_prompt"},
		{"type": "resolve_event"},
		{"type": "apply_effects", "fixture": "reveal_clue"},
	],
	"council":
	[
		{"type": "open_vote"},
		{"type": "submit_vote", "odd_option": "gallery", "even_option": "vault"},
		{"type": "resolve_vote"},
	],
	"reckoning":
	[
		{"type": "apply_effects", "fixture": "grant_flame_and_mist"},
		{"type": "play_card", "card_id": "steady_flame"},
		{"type": "resolve_check", "check_id": "courage"},
		{"type": "director_evaluate"},
	],
	"afterlife":
	[
		{"type": "role_transition", "selector_tag": "living", "trigger": "defeat"},
		{"type": "role_action", "selector_tag": "afterlife", "action_tag": "afterlife_support"},
	],
	"ending":
	[
		{"type": "apply_effects", "fixture": "secure_house"},
		{"type": "resolve_outcomes"},
	],
}
const RESUMABLE_BOUNDARY_POLICY: Dictionary = {
	"threshold":
	{
		"operation_index": 3,
		"submit_type": "submit_prompt",
		"resolve_type": "resolve_prompt",
		"kind": "prompt",
		"prompt_id": "choose_path",
		"source_id": "threshold_whisper",
	},
	"council":
	{
		"operation_index": 2,
		"submit_type": "submit_vote",
		"resolve_type": "resolve_vote",
		"kind": "vote",
		"prompt_id": "archive_route_vote",
		"source_id": "gallery_council",
	},
}
const CHECK_IDS: PackedStringArray = ["courage"]
const EFFECT_FIXTURES: PackedStringArray = ["reveal_clue", "grant_flame_and_mist", "secure_house"]
const FIXTURE_INPUTS: PackedStringArray = [
	"join", "confirm", "briefing", "threshold", "council", "reckoning", "afterlife", "ending"
]
const SUPPORTED_COMPLETE_RESULTS: PackedStringArray = ["lantern_house_secured"]
const TERMINAL_POLICY_KEYS: PackedStringArray = ["source", "deterministic"]
const ENDING_POLICY_KEYS: PackedStringArray = ["view", "private_details"]
const REMATCH_POLICY_KEYS: PackedStringArray = [
	"retain_stable_seats", "reset_all_session_authorities"
]
const COMPANION_POLICY_KEYS: PackedStringArray = ["available", "required", "authority"]
const FIXTURE_KEYS: PackedStringArray = ["seeds", "ordered_inputs"]
const SUPPORTED_SEAT_KEYS: PackedStringArray = ["minimum", "maximum"]


static func load_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var source: String = FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(source)
	var normalized: Variant = RulesContent.SessionData.normalize_json_numbers(parsed)
	return normalized if normalized is Dictionary else {}


static func validate(
	manifest: Dictionary,
	board: BoardDefinition,
	rules: RulesContent,
	director: DirectorContent,
	social: SocialContent,
) -> PackedStringArray:
	var failures := PackedStringArray()
	_validate_exact_keys(manifest, REQUIRED_KEYS, "manifest", failures)
	if manifest.get("manifest_version") != MANIFEST_VERSION:
		failures.append("unsupported manifest_version")
	if not _valid_id(manifest.get("scenario_id")):
		failures.append("scenario_id must be a lowercase stable identifier")
	if not manifest.get("scenario_version") is int or manifest.scenario_version < 1:
		failures.append("scenario_version must be positive")
	_validate_authority_references(manifest, board, rules, director, social, failures)
	_validate_seats_and_modes(manifest, social, failures)
	_validate_text(manifest, "briefing", failures)
	_validate_text(manifest, "public_objective", failures)
	_validate_stages(manifest.get("stages"), rules, social, failures)
	_validate_policies(manifest, failures)
	_validate_fixture(manifest.get("fixture"), failures)
	return failures


static func authorize_mode(
	manifest: Dictionary, social: SocialContent, requested_mode: String, seat_count: int
) -> Dictionary:
	if social == null or seat_count < 1 or seat_count > SeatManager.MAX_SEATS:
		return {"accepted": false, "reason": "invalid_mode_context"}
	var default_id: String = manifest.get("default_mode", "")
	var fallback_id: String = manifest.get("fallback_mode", "")
	if not requested_mode in [default_id, fallback_id]:
		return {"accepted": false, "reason": "requested_mode_not_permitted"}
	var default_mode: Dictionary = social.mode_by_id(default_id)
	var fallback_mode: Dictionary = social.mode_by_id(fallback_id)
	if default_mode.is_empty() or fallback_mode.is_empty():
		return {"accepted": false, "reason": "manifest_mode_missing"}
	var default_supported: bool = default_mode.supported_player_counts.has(seat_count)
	if requested_mode == fallback_id and default_supported:
		return {"accepted": false, "reason": "fallback_mode_not_allowed"}
	if (
		not default_supported
		and (
			default_mode.get("fallback_mode", "") != fallback_id
			or not fallback_mode.supported_player_counts.has(seat_count)
		)
	):
		return {"accepted": false, "reason": "unsupported_manifest_seat_policy"}
	return {"accepted": true, "reason": ""}


static func resumable_boundary(stage_id: String, operation_index: int) -> Dictionary:
	var policy: Dictionary = RESUMABLE_BOUNDARY_POLICY.get(stage_id, {})
	return policy.duplicate(true) if policy.get("operation_index", -1) == operation_index else {}


static func _validate_authority_references(
	manifest: Dictionary,
	board: BoardDefinition,
	rules: RulesContent,
	director: DirectorContent,
	social: SocialContent,
	failures: PackedStringArray,
) -> void:
	if board == null or manifest.get("board_reference") != board.board_id:
		failures.append("unknown board_reference")
	if rules == null or manifest.get("rules_reference") != rules.scenario_id:
		failures.append("unknown rules_reference")
	if director == null or manifest.get("director_reference") != director.content_id:
		failures.append("unknown director_reference")
	elif director.profile_by_id(manifest.get("director_profile", "")).is_empty():
		failures.append("unknown director_profile")
	if social == null or manifest.get("social_reference") != social.scenario_id:
		failures.append("unknown social_reference")


static func _validate_seats_and_modes(
	manifest: Dictionary, social: SocialContent, failures: PackedStringArray
) -> void:
	var seats: Variant = manifest.get("supported_seats")
	if (
		not seats is Dictionary
		or not _has_exact_keys(seats, SUPPORTED_SEAT_KEYS)
		or seats.get("minimum") != 1
		or seats.get("maximum") != 8
	):
		failures.append("supported_seats must cover exactly 1 through 8")
	for key: String in ["default_mode", "fallback_mode"]:
		var mode_id: Variant = manifest.get(key)
		if not mode_id is String or social == null or social.mode_by_id(mode_id).is_empty():
			failures.append("%s references an unknown social mode" % key)
	if social == null:
		return
	var default_mode: Dictionary = social.mode_by_id(manifest.get("default_mode", ""))
	var fallback_mode: Dictionary = social.mode_by_id(manifest.get("fallback_mode", ""))
	if default_mode.is_empty() or fallback_mode.is_empty() or default_mode == fallback_mode:
		failures.append("default/fallback mode policy is invalid")
		return
	if default_mode.get("fallback_mode", "") != fallback_mode.get("id", ""):
		failures.append("default mode does not declare the manifest fallback")
	for seat_count: int in range(1, SeatManager.MAX_SEATS + 1):
		if (
			not default_mode.supported_player_counts.has(seat_count)
			and not fallback_mode.supported_player_counts.has(seat_count)
		):
			failures.append("mode policy cannot support seat count %d" % seat_count)


static func _validate_stages(
	value: Variant, rules: RulesContent, social: SocialContent, failures: PackedStringArray
) -> void:
	if not value is Array or value.is_empty():
		failures.append("stages must be a non-empty array")
		return
	var seen: Dictionary = {}
	if value.size() != STAGE_ORDER.size():
		failures.append("stages must preserve the five-stage vertical-slice order")
	for stage_position: int in value.size():
		var stage_value: Variant = value[stage_position]
		if not stage_value is Dictionary:
			failures.append("stage must be an object")
			continue
		var stage: Dictionary = stage_value
		_validate_exact_keys(stage, STAGE_KEYS, "stage", failures)
		var stage_id: Variant = stage.get("id")
		if not _valid_id(stage_id) or seen.has(stage_id):
			failures.append("stage has malformed or duplicate id")
			continue
		seen[stage_id] = true
		if stage_position >= STAGE_ORDER.size() or stage_id != STAGE_ORDER[stage_position]:
			failures.append("stage order is not coherent")
		_validate_text(stage, "title", failures)
		for key: String in ["entry_condition", "completion_condition"]:
			if not stage.get(key) is String or not STAGE_CONDITIONS.has(stage.get(key)):
				failures.append("stage '%s' has malformed %s" % [stage_id, key])
		var condition_policy: Array = STAGE_CONDITION_POLICY.get(stage_id, [])
		if (
			condition_policy.size() != 2
			or stage.get("entry_condition") != condition_policy[0]
			or stage.get("completion_condition") != condition_policy[1]
		):
			failures.append("stage '%s' has incoherent entry/completion conditions" % stage_id)
		_validate_operations(stage.get("operations"), rules, social, failures)
		_validate_stage_operation_policy(stage_id, stage.get("operations"), failures)


static func _validate_operations(
	value: Variant, rules: RulesContent, social: SocialContent, failures: PackedStringArray
) -> void:
	if not value is Array or value.is_empty():
		failures.append("stage operations must be a non-empty array")
		return
	for operation_value: Variant in value:
		if not operation_value is Dictionary:
			failures.append("operation must be an object")
			continue
		var operation: Dictionary = operation_value
		var type: String = operation.get("type", "")
		if not OPERATION_TYPES.has(type):
			failures.append("unsupported bounded operation '%s'" % type)
			continue
		_validate_exact_keys(
			operation, PackedStringArray(OPERATION_KEYS[type]), "operation '%s'" % type, failures
		)
		if type == "queue_event" and rules.event_by_id(operation.get("event_id", "")).is_empty():
			failures.append("operation references unknown event")
		elif type == "play_card" and rules.card_by_id(operation.get("card_id", "")).is_empty():
			failures.append("operation references unknown card")
		elif (
			type == "resolve_check"
			and (
				not CHECK_IDS.has(operation.get("check_id", ""))
				or not rules is LanternHouseRulesContent
				or (rules as LanternHouseRulesContent).courage_check().is_empty()
			)
		):
			failures.append("operation references unknown check")
		elif type == "apply_effects" and not EFFECT_FIXTURES.has(operation.get("fixture", "")):
			failures.append("operation references unknown effect fixture")
		elif type == "role_transition" and not _valid_role_transition(operation, social):
			failures.append("role_transition selector and trigger are incompatible")
		elif type == "role_action" and not _valid_role_action(operation, social):
			failures.append("role_action selector and action tag are incompatible")
		elif (
			type == "complete_rules"
			and not SUPPORTED_COMPLETE_RESULTS.has(operation.get("result", ""))
		):
			failures.append("complete_rules references an unsupported result")
		elif (
			type == "submit_prompt"
			and not _rules_prompt_option_exists(rules, operation.get("option_id", ""))
		):
			failures.append("submit_prompt references an unknown option")
		elif type == "submit_vote" and not _vote_options_exist(rules, operation):
			failures.append("submit_vote references an unknown option")
	if social == null:
		failures.append("operations require social content")


static func _validate_stage_operation_policy(
	stage_id: String, value: Variant, failures: PackedStringArray
) -> void:
	if not value is Array or not STAGE_OPERATION_POLICY.has(stage_id):
		return
	var expected: Array = STAGE_OPERATION_POLICY[stage_id]
	if value != expected:
		failures.append("stage '%s' violates manifest v1 operation policy" % stage_id)


static func _validate_policies(manifest: Dictionary, failures: PackedStringArray) -> void:
	var terminal: Variant = manifest.get("terminal_policy")
	if (
		not terminal is Dictionary
		or not _has_exact_keys(terminal, TERMINAL_POLICY_KEYS)
		or terminal.get("source") != "rules_and_social_outcomes"
		or terminal.get("deterministic") != true
	):
		failures.append("terminal_policy is unsupported")
	var ending: Variant = manifest.get("ending")
	if (
		not ending is Dictionary
		or not _has_exact_keys(ending, ENDING_POLICY_KEYS)
		or ending.get("view") != "public_mixed_outcome"
		or ending.get("private_details") != "controlled_reveal_only"
	):
		failures.append("ending policy is unsupported")
	var rematch: Variant = manifest.get("rematch_policy")
	if (
		not rematch is Dictionary
		or not _has_exact_keys(rematch, REMATCH_POLICY_KEYS)
		or rematch.get("retain_stable_seats") != true
		or rematch.get("reset_all_session_authorities") != true
	):
		failures.append("rematch_policy is unsupported")
	var companion: Variant = manifest.get("companion_policy")
	if (
		not companion is Dictionary
		or not _has_exact_keys(companion, COMPANION_POLICY_KEYS)
		or not companion.get("available") is bool
		or companion.get("required") != false
		or companion.get("authority") != "native_godot"
	):
		failures.append("companion_policy is unsupported")


static func _validate_fixture(value: Variant, failures: PackedStringArray) -> void:
	if not value is Dictionary or not _has_exact_keys(value, FIXTURE_KEYS):
		failures.append("fixture must be an object")
		return
	if not value.get("seeds") is Array or value.seeds.is_empty() or value.seeds.size() > 32:
		failures.append("fixture must declare deterministic seeds")
	else:
		var seen_seeds: Dictionary = {}
		for seed: Variant in value.seeds:
			if not seed is int or seed < 1 or seed > 2147483646 or seen_seeds.has(seed):
				failures.append("fixture contains malformed deterministic seed")
			else:
				seen_seeds[seed] = true
	if (
		not value.get("ordered_inputs") is Array
		or value.ordered_inputs.is_empty()
		or value.ordered_inputs.size() > FIXTURE_INPUTS.size()
	):
		failures.append("fixture must declare ordered inputs")
	else:
		for index: int in value.ordered_inputs.size():
			var input: Variant = value.ordered_inputs[index]
			if (
				not input is String
				or not FIXTURE_INPUTS.has(input)
				or index >= FIXTURE_INPUTS.size()
				or input != FIXTURE_INPUTS[index]
			):
				failures.append("fixture contains malformed ordered input")


static func _validate_text(source: Dictionary, key: String, failures: PackedStringArray) -> void:
	if not source.get(key) is String or String(source.get(key)).strip_edges().is_empty():
		failures.append("%s must be non-empty text" % key)


static func _validate_exact_keys(
	value: Dictionary, expected: PackedStringArray, label: String, failures: PackedStringArray
) -> void:
	for key: Variant in value:
		if not key is String or not expected.has(key):
			failures.append("%s contains unknown key '%s'" % [label, key])
	for key: String in expected:
		if not value.has(key):
			failures.append("%s is missing key '%s'" % [label, key])


static func _has_exact_keys(value: Dictionary, expected: PackedStringArray) -> bool:
	if value.size() != expected.size():
		return false
	for key: Variant in value:
		if not key is String or not expected.has(key):
			return false
	return true


static func _valid_role_transition(operation: Dictionary, social: SocialContent) -> bool:
	if social == null:
		return false
	var selector: String = operation.get("selector_tag", "")
	var trigger: String = operation.get("trigger", "")
	if not _valid_id(selector) or not _valid_id(trigger):
		return false
	for role: Dictionary in social.roles:
		if not role.get("tags", []).has(selector):
			continue
		for transition_id: String in role.get("transition_refs", []):
			if social.transition_by_id(transition_id).get("trigger", "") == trigger:
				return true
	return false


static func _valid_role_action(operation: Dictionary, social: SocialContent) -> bool:
	if social == null:
		return false
	var selector: String = operation.get("selector_tag", "")
	var action_tag: String = operation.get("action_tag", "")
	if not _valid_id(selector) or not _valid_id(action_tag):
		return false
	for role: Dictionary in social.roles:
		if not role.get("tags", []).has(selector):
			continue
		for action_id: String in role.get("action_refs", []):
			if social.action_by_id(action_id).get("tags", []).has(action_tag):
				return true
	return false


static func _rules_prompt_option_exists(rules: RulesContent, option_id: String) -> bool:
	if not _valid_id(option_id):
		return false
	for event: Dictionary in rules.events:
		for prompt: Dictionary in event.get("prompts", []):
			for option: Dictionary in prompt.get("options", []):
				if option.get("id", "") == option_id:
					return true
	return false


static func _vote_options_exist(rules: RulesContent, operation: Dictionary) -> bool:
	if not rules is LanternHouseRulesContent:
		return false
	var known: PackedStringArray = []
	for option: Dictionary in (rules as LanternHouseRulesContent).vote_definition().options:
		known.append(option.get("id", ""))
	return (
		known.has(operation.get("odd_option", "")) and known.has(operation.get("even_option", ""))
	)


static func _valid_id(value: Variant) -> bool:
	return (
		value is String
		and not String(value).is_empty()
		and String(value) == String(value).to_lower()
		and String(value).is_valid_identifier()
	)
