class_name TalePackage
extends RefCounted

const PACKAGE_KIND: String = "tale"
const SCHEMA_VERSION: int = 1
const LANTERN_HOUSE_ID: String = "lantern_house_vertical_slice"
const LANTERN_HOUSE_VERSION: int = 1
const LANTERN_HOUSE_DIGEST: String = (
	"abb39d6bfbdf8d7de108379f08180c13" + "efb99bbffa3e53f30eaaa8de7f459dee"
)


static func load_validated(
	path: String,
	board: BoardDefinition,
	rules: RulesContent,
	director: DirectorContent,
	social: SocialContent,
	expected: Dictionary = {},
) -> Dictionary:
	var expected_identity: Dictionary = expected.duplicate(true)
	if expected_identity.is_empty():
		expected_identity = lantern_house_identity()
	if not FileAccess.file_exists(path):
		return _rejected("unresolved_package", path, "Tale package file does not exist")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	var package_value: Variant = RulesContent.SessionData.normalize_json_numbers(parsed)
	if not package_value is Dictionary:
		return _rejected("unsupported_schema", path, "Tale package root must be an object")
	var package: Dictionary = package_value
	var digest: String = package_digest(package)
	if digest != expected_identity.get("sha256", ""):
		return _rejected(
			"unsupported_package_identity",
			path,
			"package SHA-256 does not match the reviewed catalog identity",
		)
	if (
		package.get("package_kind") != expected_identity.get("package_kind")
		or package.get("schema_version") != expected_identity.get("schema_version")
		or package.get("tale_id") != expected_identity.get("tale_id")
		or package.get("package_version") != expected_identity.get("package_version")
	):
		return _rejected(
			"unsupported_schema", path, "package kind, schema, Tale ID, or version is unsupported"
		)
	var content: Dictionary = package.get("content", {})
	var manifest_path: String = content.get("scenario_manifest", "")
	if (
		manifest_path.is_empty()
		or FileAccess.get_sha256(manifest_path) != content.get("scenario_sha256", "")
	):
		return _rejected(
			"unresolved_reference",
			"%s#/content/scenario_manifest" % path,
			"scenario manifest is missing or differs from the reviewed source",
		)
	var localization: Dictionary = package.get("localization", {})
	var catalog_path: String = localization.get("catalog", "")
	if (
		catalog_path.is_empty()
		or FileAccess.get_sha256(catalog_path) != localization.get("catalog_sha256", "")
	):
		return _rejected(
			"unresolved_localization",
			"%s#/localization/catalog" % path,
			"localization catalog is missing or differs from the reviewed source",
		)
	var manifest: Dictionary = VerticalSliceManifest.load_file(manifest_path)
	if package.get("tale_id") != manifest.get("scenario_id"):
		return _rejected(
			"unresolved_reference",
			"%s#/tale_id" % path,
			"package Tale ID does not match the scenario manifest",
		)
	var manifest_failures: PackedStringArray = VerticalSliceManifest.validate(
		manifest, board, rules, director, social
	)
	if not manifest_failures.is_empty():
		return _rejected("invalid_scenario_manifest", manifest_path, manifest_failures[0])
	if not _references_match(package, manifest, board, rules, director, social):
		return _rejected(
			"unresolved_reference",
			"%s#/content" % path,
			"package authority references do not match reviewed content",
		)
	var actual_inventory: Dictionary = _inventory(manifest, board, rules, director, social)
	if package.get("inventory", {}) != actual_inventory:
		return _rejected(
			"inventory_mismatch",
			"%s#/inventory" % path,
			"package inventory differs from instantiated reviewed content",
		)
	return {
		"accepted": true,
		"diagnostics": [],
		"package": package.duplicate(true),
		"manifest": manifest.duplicate(true),
		"digest": digest,
		"inventory": actual_inventory,
		"source_ledger": package.get("source_ledger", []).duplicate(true),
		"compatibility": package.get("compatibility", {}).duplicate(true),
	}


static func lantern_house_identity() -> Dictionary:
	return {
		"package_kind": PACKAGE_KIND,
		"schema_version": SCHEMA_VERSION,
		"tale_id": LANTERN_HOUSE_ID,
		"package_version": LANTERN_HOUSE_VERSION,
		"sha256": LANTERN_HOUSE_DIGEST,
	}


static func package_digest(package: Dictionary) -> String:
	return JSON.stringify(canonicalize(package)).sha256_text()


static func canonicalize(value: Variant) -> Variant:
	if value is Array:
		var array: Array = []
		for item: Variant in value:
			array.append(canonicalize(item))
		return array
	if value is Dictionary:
		var dictionary: Dictionary = {}
		var keys: Array = value.keys()
		keys.sort_custom(func(a: Variant, b: Variant) -> bool: return String(a) < String(b))
		for key: Variant in keys:
			dictionary[String(key)] = canonicalize(value[key])
		return dictionary
	return value


static func _references_match(
	package: Dictionary,
	manifest: Dictionary,
	board: BoardDefinition,
	rules: RulesContent,
	director: DirectorContent,
	social: SocialContent,
) -> bool:
	var content: Dictionary = package.get("content", {})
	return (
		content.get("board_reference") == board.board_id
		and content.get("rules_reference") == rules.scenario_id
		and content.get("director_reference") == director.content_id
		and content.get("social_reference") == social.scenario_id
		and content.get("board_reference") == manifest.get("board_reference")
		and content.get("rules_reference") == manifest.get("rules_reference")
		and content.get("director_reference") == manifest.get("director_reference")
		and content.get("social_reference") == manifest.get("social_reference")
	)


static func _inventory(
	manifest: Dictionary,
	board: BoardDefinition,
	rules: RulesContent,
	director: DirectorContent,
	social: SocialContent,
) -> Dictionary:
	return {
		"actions": _ids(social.actions),
		"cards": _ids(rules.cards),
		"connectors": _ids(board.connectors),
		"director_candidates": _ids(director.candidates),
		"director_profiles": _ids(director.profiles),
		"events": _ids(rules.events),
		"factions": _ids(social.factions),
		"items": _ids(rules.items),
		"modes": _ids(social.modes),
		"objectives": _ids(social.objectives),
		"roles": _ids(social.roles),
		"spaces": _ids(board.spaces),
		"stages": _ids(manifest.get("stages", [])),
		"transitions": _ids(social.transitions),
	}


static func _ids(definitions: Variant) -> Array:
	var ids: Array = []
	for definition: Variant in definitions:
		if definition is Dictionary:
			ids.append(definition.get("id", ""))
	ids.sort()
	return ids


static func _rejected(code: String, path: String, message: String) -> Dictionary:
	return {
		"accepted": false,
		"diagnostics": [{"code": code, "path": path, "message": message}],
		"reason": "%s:%s:%s" % [code, path, message],
	}
