class_name TaleProviderRegistry
extends RefCounted

const LANTERN_HOUSE_PROVIDER_ID: String = "lantern_house_authorities_v1"
const PROVIDER_VERSION: int = 1


func provider_ids() -> PackedStringArray:
	return PackedStringArray([LANTERN_HOUSE_PROVIDER_ID])


func allows_test_fixtures() -> bool:
	return false


func provider_spec(provider_id: String) -> Dictionary:
	if provider_id != LANTERN_HOUSE_PROVIDER_ID:
		return {}
	return {
		"provider_id": LANTERN_HOUSE_PROVIDER_ID,
		"provider_version": PROVIDER_VERSION,
		"board_reference": "lantern_house",
		"rules_reference": "lantern_house_rules_sandbox",
		"director_reference": "lantern_house_director",
		"social_reference": "lantern_house_social_lab",
	}


func build_candidate(entry: Dictionary) -> Dictionary:
	var provider: Dictionary = entry.get("provider", {})
	var provider_id: String = provider.get("provider_id", "")
	var spec: Dictionary = provider_spec(provider_id)
	if spec.is_empty():
		return _rejected(
			"unknown_provider",
			"#/provider/provider_id",
			"provider '%s' is not in the reviewed runtime allowlist" % provider_id,
		)
	if provider != spec:
		return _rejected(
			"provider_mismatch",
			"#/provider",
			"catalog provider declaration does not match the reviewed provider registry",
		)
	var content: Dictionary = _construct_content(provider_id)
	if not _complete_content(content):
		return _rejected(
			"incomplete_provider",
			"#/provider",
			"reviewed provider did not construct board, rules, Director, and social content",
		)
	var expected: Dictionary = {
		"package_kind": entry.get("package_kind", ""),
		"schema_version": entry.get("package_schema_version", 0),
		"tale_id": entry.get("tale_id", ""),
		"package_version": entry.get("package_version", 0),
		"sha256": entry.get("package_sha256", ""),
	}
	var package_result: Dictionary = (
		TalePackage
		. load_validated(
			entry.get("package_path", ""),
			content.board,
			content.rules,
			content.director,
			content.social,
			expected,
		)
	)
	if not package_result.get("accepted", false):
		return _rejected(
			"provider_package_rejected",
			"#/package_path",
			package_result.get("reason", "reviewed package validation failed"),
		)
	var package_content: Dictionary = package_result.package.get("content", {})
	if not _references_match(package_content, spec):
		return _rejected(
			"provider_reference_mismatch",
			"#/provider",
			"provider references do not match the package and scenario manifest",
		)
	return {
		"accepted": true,
		"diagnostics": [],
		"provider_id": provider_id,
		"provider_spec": spec.duplicate(true),
		"package": package_result.package,
		"package_digest": package_result.digest,
		"manifest": package_result.manifest,
		"inventory": package_result.inventory,
		"board_definition": content.board,
		"rules_content": content.rules,
		"director_content": content.director,
		"social_content": content.social,
	}


func _construct_content(provider_id: String) -> Dictionary:
	if provider_id != LANTERN_HOUSE_PROVIDER_ID:
		return {}
	return {
		"board": LanternHouseBoardDefinition.new(),
		"rules": LanternHouseRulesContent.new(),
		"director": LanternHouseDirectorContent.new(),
		"social": LanternHouseSocialContent.new(),
	}


static func _complete_content(content: Dictionary) -> bool:
	return (
		content.get("board") is BoardDefinition
		and content.get("rules") is RulesContent
		and content.get("director") is DirectorContent
		and content.get("social") is SocialContent
	)


static func _references_match(content: Dictionary, spec: Dictionary) -> bool:
	return (
		content.get("board_reference") == spec.board_reference
		and content.get("rules_reference") == spec.rules_reference
		and content.get("director_reference") == spec.director_reference
		and content.get("social_reference") == spec.social_reference
	)


static func _rejected(code: String, path: String, message: String) -> Dictionary:
	return {
		"accepted": false,
		"diagnostics": [{"code": code, "path": path, "message": message}],
		"reason": "%s:%s:%s" % [code, path, message],
	}
