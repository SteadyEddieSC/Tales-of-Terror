class_name DrownedHarborScopedProvider
extends RefCounted

const PROVIDER_ID: String = "drowned_harbor_authorities_v1"
const PROVIDER_VERSION: int = 1
const TALE_ID: String = "drowned_harbor"
const PACKAGE_PATH: String = "res://data/tales/drowned_harbor/tale_package_v1.json"
const SCENARIO_PATH: String = "res://data/scenarios/drowned_harbor_scaffold_v1.json"
const LOCALIZATION_PATH: String = "res://data/tales/drowned_harbor/localization_en.json"
const EXPECTED_PACKAGE_DIGEST: String = (
	"17e5ed3b651424f4e292239d15258086" + "37babb7f91fb5134d018c644290b692f"
)
const EXPECTED_SCENARIO_DIGEST: String = (
	"d7cb1934f119bd2d94c514a8a5097581" + "15b894a79dc57e02fa8bda322bdd2168"
)
const EXPECTED_LOCALIZATION_DIGEST: String = (
	"c19bdaed5ad7b4e5169fcfeeb632b8c" + "8b39acf7a5edf39bf23374186de886fa3"
)
const PACKAGE_KEYS: PackedStringArray = [
	"package_kind",
	"schema_version",
	"tale_id",
	"package_version",
	"provider",
	"display",
	"compatibility",
	"content",
	"stage_graph",
	"fallbacks",
	"privacy",
	"localization",
	"inventory",
	"persistence",
	"source_ledger",
	"identity_policy",
]


func provider_spec() -> Dictionary:
	return {
		"provider_id": PROVIDER_ID,
		"provider_version": PROVIDER_VERSION,
		"board_reference": "drowned_harbor_scaffold_board",
		"rules_reference": "drowned_harbor_scaffold_rules",
		"director_reference": "drowned_harbor_scaffold_director",
		"social_reference": "drowned_harbor_scaffold_social",
	}


func build_candidate(missing_authority: String = "") -> Dictionary:
	if not missing_authority in ["", "board", "rules", "director", "social"]:
		return _rejected("malformed_candidate_probe", "#/candidate", "unsupported probe")
	var content_result := _build_content(missing_authority)
	if not content_result.get("accepted", false):
		return content_result
	return _load_candidate_data(content_result.value)


func _build_content(missing_authority: String) -> Dictionary:
	var content: Dictionary = {
		"board": DrownedHarborBoardDefinition.new(),
		"rules": DrownedHarborRulesContent.new(),
		"director": DrownedHarborDirectorContent.new(),
		"social": DrownedHarborSocialContent.new(),
	}
	if not missing_authority.is_empty():
		content[missing_authority] = null
	if not _complete_content(content):
		return _rejected(
			"incomplete_candidate",
			"#/candidate/%s" % missing_authority,
			"board, rules, Director, and social authorities are required",
		)
	return {"accepted": true, "value": content}


func _load_candidate_data(content: Dictionary) -> Dictionary:
	var package_result: Dictionary = _load_json(PACKAGE_PATH, "unresolved_package")
	if not package_result.get("accepted", false):
		return package_result
	var package: Dictionary = package_result.value
	var package_failure: Dictionary = _validate_package(package, content)
	if not package_failure.is_empty():
		return package_failure
	var scenario_result: Dictionary = _load_json(SCENARIO_PATH, "unresolved_scenario")
	if not scenario_result.get("accepted", false):
		return scenario_result
	var localization_result: Dictionary = _load_json(LOCALIZATION_PATH, "unresolved_localization")
	if not localization_result.get("accepted", false):
		return localization_result
	var reference_failure: Dictionary = _validate_references(
		package, scenario_result.value, localization_result.value, content
	)
	if not reference_failure.is_empty():
		return reference_failure
	return {
		"accepted": true,
		"diagnostics": [],
		"provider_id": PROVIDER_ID,
		"provider_spec": provider_spec(),
		"package": package.duplicate(true),
		"package_digest": TalePackage.package_digest(package),
		"scenario": scenario_result.value.duplicate(true),
		"localization": localization_result.value.duplicate(true),
		"board_definition": content.board,
		"rules_content": content.rules,
		"director_content": content.director,
		"social_content": content.social,
	}


func _validate_package(package: Dictionary, content: Dictionary) -> Dictionary:
	var identity_failure := _validate_package_identity(package)
	if not identity_failure.is_empty():
		return identity_failure
	var content_failure := _validate_content_authorities(content)
	if not content_failure.is_empty():
		return content_failure
	if package.get("inventory", {}) != _expected_inventory():
		return _rejected("inventory_mismatch", "#/inventory", "native inventory changed")
	return {}


func _validate_package_identity(package: Dictionary) -> Dictionary:
	if not _has_exact_keys(package, PACKAGE_KEYS):
		return _rejected(
			"unsupported_package_schema", PACKAGE_PATH, "package field inventory is not closed"
		)
	if (
		package.get("package_kind") != "tale"
		or package.get("schema_version") != 1
		or package.get("tale_id") != TALE_ID
		or package.get("package_version") != 1
	):
		return _rejected(
			"unsupported_package_identity", PACKAGE_PATH, "package identity is unsupported"
		)
	if TalePackage.package_digest(package) != EXPECTED_PACKAGE_DIGEST:
		return _rejected(
			"unsupported_package_identity", PACKAGE_PATH, "canonical package digest changed"
		)
	if package.get("provider", {}) != provider_spec():
		return _rejected("provider_mismatch", "#/provider", "scoped provider identity changed")
	var compatibility: Dictionary = package.get("compatibility", {})
	if (
		compatibility.get("engine") != "godot_4_7_1"
		or compatibility.get("minimum_seats") != 1
		or compatibility.get("maximum_seats") != 8
		or compatibility.get("supported_modes") != ["scaffold_only"]
		or compatibility.get("admission_policy") != "developer_only_explicit_launch"
		or compatibility.get("unknown_field_policy") != "reject"
	):
		return _rejected(
			"unsupported_compatibility", "#/compatibility", "compatibility declaration changed"
		)
	return {}


func _validate_content_authorities(content: Dictionary) -> Dictionary:
	for validation_failure: String in content.board.validate():
		return _rejected("invalid_board_authority", "#/content", validation_failure)
	for validation_failure: String in content.rules.validate(content.board):
		return _rejected("invalid_rules_authority", "#/content", validation_failure)
	for validation_failure: String in content.director.validate(content.rules, content.board):
		return _rejected("invalid_director_authority", "#/content", validation_failure)
	for validation_failure: String in content.social.validate(content.rules, content.board):
		return _rejected("invalid_social_authority", "#/content", validation_failure)
	if content.director.authorized_input_keys() != DrownedHarborDirectorContent.PUBLIC_INPUT_KEYS:
		return _rejected(
			"private_director_input", "#/content/director", "Director input allowlist changed"
		)
	return {}


func _validate_references(
	package: Dictionary,
	scenario: Dictionary,
	localization: Dictionary,
	content: Dictionary,
) -> Dictionary:
	var package_content: Dictionary = package.get("content", {})
	if (
		package_content.get("scenario_path") != SCENARIO_PATH
		or package_content.get("scenario_id") != "drowned_harbor_scaffold_v1"
		or package_content.get("scenario_sha256") != EXPECTED_SCENARIO_DIGEST
		or FileAccess.get_sha256(SCENARIO_PATH) != EXPECTED_SCENARIO_DIGEST
	):
		return _rejected("scenario_identity_mismatch", "#/content", "scenario identity changed")
	if (
		package_content.get("board_reference") != content.board.board_id
		or package_content.get("rules_reference") != content.rules.scenario_id
		or package_content.get("director_reference") != content.director.content_id
		or package_content.get("social_reference") != content.social.scenario_id
	):
		return _rejected("authority_reference_mismatch", "#/content", "native references changed")
	if not _valid_scenario(scenario, package_content):
		return _rejected("invalid_scenario", SCENARIO_PATH, "scenario schema or policy changed")
	var package_localization: Dictionary = package.get("localization", {})
	if (
		package_localization.get("catalog_path") != LOCALIZATION_PATH
		or package_localization.get("catalog_id") != "drowned_harbor_placeholder_en_v1"
		or package_localization.get("catalog_sha256") != EXPECTED_LOCALIZATION_DIGEST
		or FileAccess.get_sha256(LOCALIZATION_PATH) != EXPECTED_LOCALIZATION_DIGEST
		or not _valid_localization(localization)
	):
		return _rejected(
			"localization_identity_mismatch", "#/localization", "localization identity changed"
		)
	if package.get("source_ledger", {}) != _expected_source_ledger():
		return _rejected("source_ledger_mismatch", "#/source_ledger", "source ledger changed")
	return {}


func _valid_scenario(scenario: Dictionary, content: Dictionary) -> bool:
	var keys := PackedStringArray(
		[
			"scenario_kind",
			"schema_version",
			"scenario_id",
			"scenario_version",
			"tale_id",
			"authority_references",
			"stages",
			"terminal_behavior",
			"determinism",
			"privacy",
			"identity_policy",
		]
	)
	return (
		_has_exact_keys(scenario, keys)
		and scenario.get("scenario_kind") == "drowned_harbor_production_scaffold"
		and scenario.get("schema_version") == 1
		and scenario.get("scenario_id") == content.get("scenario_id")
		and scenario.get("scenario_version") == 1
		and scenario.get("tale_id") == TALE_ID
		and (
			scenario.get("authority_references")
			== {
				"board": content.get("board_reference"),
				"director": content.get("director_reference"),
				"rules": content.get("rules_reference"),
				"social": content.get("social_reference"),
			}
		)
		and (
			scenario.get("stages")
			== [
				{
					"id": DrownedHarborRulesContent.ENTRY_STAGE_ID,
					"operations": [DrownedHarborRulesContent.EXIT_INTENT],
					"terminal_on_completion": true,
				}
			]
		)
		and (
			scenario.get("terminal_behavior", {}).get("stage_id")
			== DrownedHarborRulesContent.TERMINAL_STAGE_ID
		)
	)


func _valid_localization(localization: Dictionary) -> bool:
	var keys := PackedStringArray(
		["catalog_kind", "schema_version", "catalog_id", "locale", "status", "entries"]
	)
	var entries: Dictionary = localization.get("entries", {})
	return (
		_has_exact_keys(localization, keys)
		and localization.get("catalog_kind") == "governed_placeholder_localization"
		and localization.get("schema_version") == 1
		and localization.get("catalog_id") == "drowned_harbor_placeholder_en_v1"
		and localization.get("locale") == "en"
		and localization.get("status") == "temporary_internal_placeholder"
		and entries.keys().size() == 4
		and entries.keys().all(func(key: Variant) -> bool: return key is String)
		and entries.values().all(
			func(value: Variant) -> bool: return value is String and not value.is_empty()
		)
	)


func _expected_inventory() -> Dictionary:
	return {
		"actions": ["acknowledge_scaffold_exit"],
		"cards": [],
		"connectors": [],
		"director_candidates": ["scaffold_no_op"],
		"director_profiles": ["scaffold_off"],
		"events": [],
		"factions": ["scaffold_participants"],
		"items": [],
		"modes": ["scaffold_only"],
		"objectives": ["exit_scaffold_safely"],
		"privacy_classes": Array(DrownedHarborSocialContent.PRIVACY_CLASSES),
		"roles": ["scaffold_observer"],
		"spaces": ["scaffold_harbor"],
		"stages": ["scaffold_entry"],
		"transitions": [],
	}


func _expected_source_ledger() -> Array:
	return [
		{
			"role": "board_authority",
			"path": "game/src/tales/drowned_harbor/drowned_harbor_board_definition.gd",
			"reference": "drowned_harbor_scaffold_board",
		},
		{
			"role": "director_content",
			"path": "game/src/tales/drowned_harbor/drowned_harbor_director_content.gd",
			"reference": "drowned_harbor_scaffold_director",
		},
		{
			"role": "localization_catalog",
			"path": "game/data/tales/drowned_harbor/localization_en.json",
			"reference": "drowned_harbor_placeholder_en_v1",
		},
		{
			"role": "rules_content",
			"path": "game/src/tales/drowned_harbor/drowned_harbor_rules_content.gd",
			"reference": "drowned_harbor_scaffold_rules",
		},
		{
			"role": "scenario_manifest",
			"path": "game/data/scenarios/drowned_harbor_scaffold_v1.json",
			"reference": "drowned_harbor_scaffold_v1",
		},
		{
			"role": "scoped_provider",
			"path": "game/src/tales/drowned_harbor/drowned_harbor_scoped_provider.gd",
			"reference": PROVIDER_ID,
		},
		{
			"role": "social_content",
			"path": "game/src/tales/drowned_harbor/drowned_harbor_social_content.gd",
			"reference": "drowned_harbor_scaffold_social",
		},
	]


func _load_json(path: String, code: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return _rejected(code, path, "required reviewed JSON is missing")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	var normalized: Variant = RulesContent.SessionData.normalize_json_numbers(parsed)
	if not normalized is Dictionary:
		return _rejected(code, path, "required reviewed JSON is malformed")
	return {"accepted": true, "value": normalized}


func _complete_content(content: Dictionary) -> bool:
	return (
		content.get("board") is DrownedHarborBoardDefinition
		and content.get("rules") is DrownedHarborRulesContent
		and content.get("director") is DrownedHarborDirectorContent
		and content.get("social") is DrownedHarborSocialContent
	)


func _has_exact_keys(value: Dictionary, expected: PackedStringArray) -> bool:
	if value.size() != expected.size():
		return false
	for key: Variant in value:
		if not key is String or not expected.has(key):
			return false
	return true


func _rejected(code: String, path: String, message: String) -> Dictionary:
	return {
		"accepted": false,
		"diagnostics": [{"code": code, "path": path, "message": message}],
		"reason": code,
	}
