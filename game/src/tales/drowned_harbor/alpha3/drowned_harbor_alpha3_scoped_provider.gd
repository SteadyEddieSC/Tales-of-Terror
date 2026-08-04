class_name DrownedHarborAlpha3ScopedProvider
extends RefCounted

const PROVIDER_ID: String = "drowned_harbor_authorities_v1"
const PROVIDER_VERSION: int = 3
const TALE_ID: String = "drowned_harbor"
const PACKAGE_PATH: String = "res://data/tales/drowned_harbor/tale_package_v3.json"
const SCENARIO_PATH: String = "res://data/scenarios/drowned_harbor_systems_v3.json"
const LOCALIZATION_PATH: String = "res://data/tales/drowned_harbor/localization_systems_en_v3.json"
const EXPECTED_PACKAGE_DIGEST: String = (
	"5c0b8434c1d3a25558a7d8df334021bb0" + "5909008ae40fe0c9325338917b37123"
)
const EXPECTED_SCENARIO_DIGEST: String = (
	"0bdb6800525631406f8a0aa43b2cff71" + "15916928f81e5e35fba353b3a55710d2"
)
const EXPECTED_LOCALIZATION_DIGEST: String = (
	"f094c2364fe75f78f6bb0991fbe027c6" + "fad3023159261651763b3c323948fc73"
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
	"localization",
	"persistence",
	"privacy",
	"inventory",
	"source_ledger",
	"identity_policy",
]
const SCENARIO_KEYS: PackedStringArray = [
	"scenario_kind",
	"schema_version",
	"scenario_id",
	"scenario_version",
	"tale_id",
	"provider_version",
	"authority_references",
	"inherited_route",
	"mode_plans",
	"deferred_modes",
	"roles",
	"objectives",
	"factions",
	"transformations",
	"continuations",
	"content",
	"director",
	"endings",
	"persistence",
	"privacy",
	"replayability",
	"admission",
	"traceability",
]


func provider_spec() -> Dictionary:
	return {
		"provider_id": PROVIDER_ID,
		"provider_version": PROVIDER_VERSION,
		"board_reference": "drowned_harbor_graybox_board_v2",
		"rules_reference": "drowned_harbor_systems_rules_v3",
		"director_reference": "drowned_harbor_systems_director_v3",
		"social_reference": "drowned_harbor_systems_role_session_v3",
	}


func build_candidate(missing_authority: String = "") -> Dictionary:
	if not missing_authority in ["", "route", "rules", "director", "social"]:
		return _rejected("malformed_candidate_probe")
	if not missing_authority.is_empty():
		return _rejected("incomplete_candidate")
	var package_result: Dictionary = _load_json(PACKAGE_PATH)
	var scenario_result: Dictionary = _load_json(SCENARIO_PATH)
	var localization_result: Dictionary = _load_json(LOCALIZATION_PATH)
	for result: Dictionary in [package_result, scenario_result, localization_result]:
		if not result.get("accepted", false):
			return result
	var alpha2_candidate: Dictionary = DrownedHarborAlpha2ScopedProvider.new().build_candidate()
	if not alpha2_candidate.get("accepted", false):
		return _rejected("inherited_route_candidate_rejected")
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
		"provider_version": PROVIDER_VERSION,
		"provider_spec": provider_spec(),
		"package": package.duplicate(true),
		"package_digest": TalePackage.package_digest(package),
		"scenario": scenario.duplicate(true),
		"localization": localization.duplicate(true),
		"alpha2_candidate": alpha2_candidate,
		"authority_owners":
		{
			"route_board": "BoardState",
			"content_rules": "RulesSession",
			"private_projection": "RoleSession",
			"variation": "Director",
		},
	}


func _validate_data(
	package: Dictionary, scenario: Dictionary, localization: Dictionary
) -> Dictionary:
	var reason: String = ""
	if not _has_exact_keys(package, PACKAGE_KEYS):
		reason = "unsupported_package_schema"
	elif (
		package.package_kind != "tale"
		or package.schema_version != 1
		or package.tale_id != TALE_ID
		or package.package_version != 3
		or package.provider != provider_spec()
		or TalePackage.package_digest(package) != EXPECTED_PACKAGE_DIGEST
	):
		reason = "unsupported_package_identity"
	elif not _has_exact_keys(scenario, SCENARIO_KEYS):
		reason = "unsupported_scenario_schema"
	elif (
		FileAccess.get_sha256(SCENARIO_PATH) != EXPECTED_SCENARIO_DIGEST
		or package.content.scenario_sha256 != EXPECTED_SCENARIO_DIGEST
		or scenario.scenario_kind != "drowned_harbor_systems_replayability"
		or scenario.schema_version != 1
		or scenario.scenario_id != "drowned_harbor_systems_v3"
		or scenario.scenario_version != 3
		or scenario.provider_version != 3
		or scenario.tale_id != TALE_ID
	):
		reason = "scenario_identity_mismatch"
	elif (
		FileAccess.get_sha256(LOCALIZATION_PATH) != EXPECTED_LOCALIZATION_DIGEST
		or package.localization.catalog_sha256 != EXPECTED_LOCALIZATION_DIGEST
		or localization.get("catalog_id") != "drowned_harbor_systems_en_v3"
		or localization.get("catalog_version") != 3
		or localization.get("status") != "temporary_internal_placeholder"
	):
		reason = "localization_identity_mismatch"
	elif (
		scenario.inherited_route.stage_order != Array(DrownedHarborAlpha2RulesAuthority.STAGE_ORDER)
		or (
			scenario.inherited_route.transition_order
			!= Array(DrownedHarborAlpha2RulesAuthority.TRANSITION_ORDER)
		)
		or scenario.roles.archetype_order != Array(DrownedHarborAlpha3RoleAuthority.ROLE_ORDER)
		or scenario.content.items != Array(DrownedHarborAlpha3RulesAuthority.ITEMS)
		or scenario.content.cards != Array(DrownedHarborAlpha3RulesAuthority.CARDS)
		or scenario.content.resources != Array(DrownedHarborAlpha3RulesAuthority.RESOURCES)
		or scenario.content.hazards != Array(DrownedHarborAlpha3RulesAuthority.HAZARDS)
		or scenario.endings != Array(DrownedHarborAlpha3RulesAuthority.ENDINGS)
	):
		reason = "governed_inventory_mismatch"
	elif (
		scenario.privacy.classes != Array(DrownedHarborAlpha3RoleAuthority.PRIVACY_CLASSES)
		or (
			scenario.director.input_allowlist
			!= Array(DrownedHarborAlpha3DirectorAuthority.INPUT_ALLOWLIST)
		)
		or (
			scenario.director.private_inputs_forbidden
			!= Array(DrownedHarborAlpha3DirectorAuthority.FORBIDDEN_INPUTS)
		)
	):
		reason = "privacy_or_director_boundary_mismatch"
	if not reason.is_empty():
		return _rejected(reason)
	return {"accepted": true, "reason": ""}


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
