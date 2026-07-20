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
	_validate_policy(manifest, "terminal_policy", failures)
	_validate_policy(manifest, "ending", failures)
	_validate_policy(manifest, "rematch_policy", failures)
	_validate_policy(manifest, "companion_policy", failures)
	_validate_fixture(manifest.get("fixture"), failures)
	return failures


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
	if not seats is Dictionary or seats.get("minimum") != 1 or seats.get("maximum") != 8:
		failures.append("supported_seats must cover exactly 1 through 8")
	for key: String in ["default_mode", "fallback_mode"]:
		var mode_id: Variant = manifest.get(key)
		if not mode_id is String or social == null or social.mode_by_id(mode_id).is_empty():
			failures.append("%s references an unknown social mode" % key)


static func _validate_stages(
	value: Variant, rules: RulesContent, social: SocialContent, failures: PackedStringArray
) -> void:
	if not value is Array or value.is_empty():
		failures.append("stages must be a non-empty array")
		return
	var seen: Dictionary = {}
	for stage_value: Variant in value:
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
		_validate_text(stage, "title", failures)
		for key: String in ["entry_condition", "completion_condition"]:
			if not stage.get(key) is String or not STAGE_CONDITIONS.has(stage.get(key)):
				failures.append("stage '%s' has malformed %s" % [stage_id, key])
		_validate_operations(stage.get("operations"), rules, social, failures)


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
			type == "apply_effects"
			and not ["reveal_clue", "grant_flame_and_mist", "secure_house"].has(
				operation.get("fixture", "")
			)
		):
			failures.append("operation references unknown effect fixture")
		elif type == "role_transition" and not operation.has("trigger"):
			failures.append("role_transition requires a trigger")
		elif type == "role_action" and not operation.has("action_tag"):
			failures.append("role_action requires an action_tag")
		elif type == "complete_rules" and not operation.has("result"):
			failures.append("complete_rules requires a result")
	if social == null:
		failures.append("operations require social content")


static func _validate_policy(
	manifest: Dictionary, key: String, failures: PackedStringArray
) -> void:
	var value: Variant = manifest.get(key)
	if not value is Dictionary or value.is_empty():
		failures.append("%s must be a non-empty bounded policy" % key)


static func _validate_fixture(value: Variant, failures: PackedStringArray) -> void:
	if not value is Dictionary:
		failures.append("fixture must be an object")
		return
	if not value.get("seeds") is Array or value.seeds.is_empty():
		failures.append("fixture must declare deterministic seeds")
	if not value.get("ordered_inputs") is Array or value.ordered_inputs.is_empty():
		failures.append("fixture must declare ordered inputs")


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


static func _valid_id(value: Variant) -> bool:
	return (
		value is String
		and not String(value).is_empty()
		and String(value) == String(value).to_lower()
		and String(value).is_valid_identifier()
	)
