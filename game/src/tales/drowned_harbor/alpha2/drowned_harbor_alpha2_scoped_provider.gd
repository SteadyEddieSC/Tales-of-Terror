class_name DrownedHarborAlpha2ScopedProvider
extends RefCounted

const PROVIDER_ID: String = "drowned_harbor_authorities_v1"
const PROVIDER_VERSION: int = 2
const TALE_ID: String = "drowned_harbor"
const PACKAGE_PATH: String = "res://data/tales/drowned_harbor/tale_package_v2.json"
const SCENARIO_PATH: String = "res://data/scenarios/drowned_harbor_graybox_v2.json"
const LOCALIZATION_PATH: String = "res://data/tales/drowned_harbor/localization_graybox_en_v2.json"
const EXPECTED_PACKAGE_DIGEST: String = (
	"ee9e2f21b23f2b8f7ac8c8be1520c6e" + "bcb679807a5f0dbd0d23825824b2f90b7"
)
const EXPECTED_SCENARIO_DIGEST: String = (
	"5927dba92238512fdc74b10387ea7378" + "f00d74a462445749d6493a512b7d7a0d"
)
const EXPECTED_LOCALIZATION_DIGEST: String = (
	"137919b02a572fc1c844521c38633bf2" + "7ad49bcb9d1fe8a83147db2210d1a227"
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
		"board_reference": "drowned_harbor_graybox_board_v2",
		"rules_reference": "drowned_harbor_graybox_rules_v2",
		"director_reference": "drowned_harbor_graybox_director_v2",
		"social_reference": "drowned_harbor_graybox_social_v2",
	}


func build_candidate(missing_authority: String = "") -> Dictionary:
	if not missing_authority in ["", "board", "rules", "director", "social"]:
		return _rejected("malformed_candidate_probe")
	var board: DrownedHarborAlpha2BoardDefinition = (
		null if missing_authority == "board" else DrownedHarborAlpha2BoardDefinition.new()
	)
	var rules: DrownedHarborAlpha2RulesAuthority = (
		null if missing_authority == "rules" else DrownedHarborAlpha2RulesAuthority.new()
	)
	var director: DrownedHarborAlpha2DirectorContent = (
		null if missing_authority == "director" else DrownedHarborAlpha2DirectorContent.new()
	)
	var social: DrownedHarborAlpha2RoleAuthority = (
		null if missing_authority == "social" else DrownedHarborAlpha2RoleAuthority.new()
	)
	if board == null or rules == null or director == null or social == null:
		return _rejected("incomplete_candidate")
	if not board.validate().is_empty():
		return _rejected("invalid_board_authority")
	var package_result: Dictionary = _load_json(PACKAGE_PATH)
	var scenario_result: Dictionary = _load_json(SCENARIO_PATH)
	var localization_result: Dictionary = _load_json(LOCALIZATION_PATH)
	for result: Dictionary in [package_result, scenario_result, localization_result]:
		if not result.get("accepted", false):
			return result
	var package: Dictionary = package_result.value
	var scenario: Dictionary = scenario_result.value
	var localization: Dictionary = localization_result.value
	var validation: Dictionary = _validate_data(package, scenario, localization)
	if not validation.get("accepted", false):
		return validation
	return {
		"accepted": true,
		"reason": "",
		"provider_id": PROVIDER_ID,
		"provider_spec": provider_spec(),
		"package": package.duplicate(true),
		"package_digest": TalePackage.package_digest(package),
		"scenario": scenario.duplicate(true),
		"localization": localization.duplicate(true),
		"board_definition": board,
		"rules_authority": rules,
		"director_content": director,
		"role_authority": social,
	}


func _validate_data(
	package: Dictionary, scenario: Dictionary, localization: Dictionary
) -> Dictionary:
	var reason: String = _package_rejection(package)
	if reason.is_empty():
		reason = _scenario_rejection(package, scenario)
	if reason.is_empty():
		reason = _localization_rejection(package, localization)
	if reason.is_empty():
		reason = _privacy_rejection(package, scenario)
	return {"accepted": true, "reason": ""} if reason.is_empty() else _rejected(reason)


func _package_rejection(package: Dictionary) -> String:
	if not _has_exact_keys(package, PACKAGE_KEYS):
		return "unsupported_package_schema"
	if (
		package.get("package_kind") != "tale"
		or package.get("schema_version") != 1
		or package.get("tale_id") != TALE_ID
		or package.get("package_version") != 2
		or package.get("provider") != provider_spec()
		or TalePackage.package_digest(package) != EXPECTED_PACKAGE_DIGEST
	):
		return "unsupported_package_identity"
	return ""


func _scenario_rejection(package: Dictionary, scenario: Dictionary) -> String:
	if (
		FileAccess.get_sha256(SCENARIO_PATH) != EXPECTED_SCENARIO_DIGEST
		or package.get("content", {}).get("scenario_sha256") != EXPECTED_SCENARIO_DIGEST
		or scenario.get("scenario_kind") != "drowned_harbor_end_to_end_graybox"
		or scenario.get("schema_version") != 1
		or scenario.get("scenario_id") != "drowned_harbor_graybox_v2"
		or scenario.get("scenario_version") != 2
		or scenario.get("tale_id") != TALE_ID
	):
		return "scenario_identity_mismatch"
	if (
		scenario.get("stage_order") != Array(DrownedHarborAlpha2RulesAuthority.STAGE_ORDER)
		or (
			_transition_ids(scenario.get("transitions", []))
			!= Array(DrownedHarborAlpha2RulesAuthority.TRANSITION_ORDER)
		)
		or (
			package.get("stage_graph", {}).get("stage_order")
			!= Array(DrownedHarborAlpha2RulesAuthority.STAGE_ORDER)
		)
		or (
			package.get("stage_graph", {}).get("transition_order")
			!= Array(DrownedHarborAlpha2RulesAuthority.TRANSITION_ORDER)
		)
	):
		return "route_contract_mismatch"
	return ""


func _localization_rejection(package: Dictionary, localization: Dictionary) -> String:
	if (
		FileAccess.get_sha256(LOCALIZATION_PATH) != EXPECTED_LOCALIZATION_DIGEST
		or package.get("localization", {}).get("catalog_sha256") != EXPECTED_LOCALIZATION_DIGEST
		or localization.get("catalog_kind") != "governed_placeholder_localization"
		or localization.get("schema_version") != 1
		or localization.get("catalog_id") != "drowned_harbor_graybox_en_v2"
		or localization.get("catalog_version") != 2
		or localization.get("locale") != "en"
		or localization.get("status") != "temporary_internal_placeholder"
		or not localization.get("entries") is Dictionary
	):
		return "localization_identity_mismatch"
	return ""


func _privacy_rejection(package: Dictionary, scenario: Dictionary) -> String:
	if (
		package.get("privacy", {}).get("classes")
		!= Array(DrownedHarborAlpha2RoleAuthority.PRIVACY_CLASSES)
	):
		return "privacy_class_mismatch"
	if (
		scenario.get("privacy", {}).get("director_input_allowlist")
		!= Array(DrownedHarborAlpha2DirectorContent.PUBLIC_INPUT_KEYS)
	):
		return "director_allowlist_mismatch"
	return ""


static func _transition_ids(values: Array) -> Array[String]:
	var result: Array[String] = []
	for value: Variant in values:
		if value is Dictionary:
			result.append(value.get("id", ""))
	return result


static func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return _rejected("required_data_missing")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	var normalized: Variant = RulesContent.SessionData.normalize_json_numbers(parsed)
	if not normalized is Dictionary:
		return _rejected("required_data_malformed")
	return {"accepted": true, "reason": "", "value": normalized}


static func _has_exact_keys(value: Dictionary, expected: PackedStringArray) -> bool:
	if value.size() != expected.size():
		return false
	for key: Variant in value:
		if not key is String or not expected.has(key):
			return false
	return true


static func _rejected(reason: String) -> Dictionary:
	return {"accepted": false, "reason": reason, "diagnostics": [{"code": reason}]}
