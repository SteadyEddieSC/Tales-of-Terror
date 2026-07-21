class_name TaleCatalog
extends RefCounted

const CATALOG_KIND: String = "tale_catalog"
const SCHEMA_VERSION: int = 1
const CATALOG_VERSION: int = 1
const PRODUCTION_PATH: String = "res://data/tales/tale_catalog_v1.json"
const PRODUCTION_DIGEST: String = (
	"2b478fd0d11fa075c2050409193aa06e" + "6b9ca4dcf6efd4e4c550a9f3a5ff9db6"
)
const ROOT_KEYS: PackedStringArray = [
	"catalog_kind",
	"schema_version",
	"catalog_version",
	"default_tale_id",
	"entries",
	"source_ledger",
	"compatibility",
	"identity_policy",
]
const ENTRY_KEYS: PackedStringArray = [
	"tale_id",
	"package_path",
	"package_kind",
	"package_schema_version",
	"package_version",
	"package_sha256",
	"display",
	"provider",
]
const DISPLAY_KEYS: PackedStringArray = [
	"catalog_path", "catalog_sha256", "display_key", "briefing_key", "objective_key"
]
const PROVIDER_KEYS: PackedStringArray = [
	"provider_id",
	"provider_version",
	"board_reference",
	"rules_reference",
	"director_reference",
	"social_reference",
]
const LEDGER_KEYS: PackedStringArray = ["tale_id", "role", "path", "reference"]
const LEDGER_ROLES: PackedStringArray = ["governed_display", "provider_registry", "tale_package"]


static func load_validated(
	path: String, registry: TaleProviderRegistry, expected_digest: String
) -> Dictionary:
	if registry == null:
		return _rejected("unknown_provider", "#/provider", "provider registry is required")
	if not FileAccess.file_exists(path):
		return _rejected("unresolved_catalog", path, "Tale catalog file does not exist")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	var normalized: Variant = RulesContent.SessionData.normalize_json_numbers(parsed)
	if not normalized is Dictionary:
		return _rejected("unsupported_catalog_schema", path, "catalog root must be an object")
	var catalog: Dictionary = normalized
	var digest: String = catalog_digest(catalog)
	if digest != expected_digest:
		return _rejected(
			"unstable_catalog_identity",
			path,
			"catalog SHA-256 does not match the reviewed identity",
		)
	var diagnostic: Dictionary = _validate_shape(catalog, path)
	if not diagnostic.is_empty():
		return diagnostic
	var entries: Array = catalog.entries
	var ids: PackedStringArray = []
	var entry_inventory: Array[Dictionary] = []
	for index: int in entries.size():
		var entry: Dictionary = entries[index]
		var entry_path: String = "%s#/entries/%d" % [path, index]
		if not _has_exact_keys(entry, ENTRY_KEYS):
			return _rejected(
				"unsupported_catalog_schema",
				entry_path,
				"catalog entry fields are incomplete or unknown"
			)
		if (
			not _stable_id(entry.get("tale_id", ""))
			or entry.get("package_kind") != TalePackage.PACKAGE_KIND
			or entry.get("package_schema_version") != TalePackage.SCHEMA_VERSION
			or not entry.get("package_version") is int
			or entry.get("package_version", 0) < 1
			or not _sha256(entry.get("package_sha256", ""))
		):
			return _rejected(
				"unsupported_catalog_schema",
				entry_path,
				"catalog entry identity is malformed or unsupported"
			)
		if ids.has(entry.tale_id):
			return _rejected("duplicate_tale_id", entry_path, "catalog Tale IDs must be unique")
		ids.append(entry.tale_id)
		var path_failure: Dictionary = _validate_repository_path(
			entry.get("package_path", ""), entry_path + "/package_path", registry
		)
		if not path_failure.is_empty():
			return path_failure
		if not _has_exact_keys(entry.get("display", {}), DISPLAY_KEYS):
			return _rejected(
				"unsupported_catalog_schema",
				entry_path + "/display",
				"display fields are incomplete or unknown"
			)
		if not _has_exact_keys(entry.get("provider", {}), PROVIDER_KEYS):
			return _rejected(
				"unsupported_catalog_schema",
				entry_path + "/provider",
				"provider fields are incomplete or unknown"
			)
		var candidate: Dictionary = registry.build_candidate(entry)
		if not candidate.get("accepted", false):
			return _rejected(
				"catalog_entry_rejected",
				entry_path,
				candidate.get("reason", "provider rejected entry")
			)
		var display_result: Dictionary = _load_display(entry, candidate.package, registry)
		if not display_result.get("accepted", false):
			return _rejected(display_result.code, entry_path + "/display", display_result.message)
		(
			entry_inventory
			. append(
				{
					"tale_id": entry.tale_id,
					"package_sha256": candidate.package_digest,
					"provider_id": candidate.provider_id,
					"provider_version": candidate.provider_spec.provider_version,
				}
			)
		)
	if Array(ids) != _sorted_copy(Array(ids)):
		return _rejected(
			"unstable_catalog_ordering", path + "#/entries", "entries must be sorted by Tale ID"
		)
	if not ids.has(catalog.default_tale_id):
		return _rejected(
			"invalid_default_tale",
			path + "#/default_tale_id",
			"default Tale must resolve exactly once"
		)
	var ledger_failure: Dictionary = _validate_ledger(catalog.source_ledger, ids, path, registry)
	if not ledger_failure.is_empty():
		return ledger_failure
	return {
		"accepted": true,
		"diagnostics": [],
		"catalog": catalog.duplicate(true),
		"digest": digest,
		"default_tale_id": catalog.default_tale_id,
		"inventory": entry_inventory,
		"source_ledger": catalog.source_ledger.duplicate(true),
		"compatibility": catalog.compatibility.duplicate(true),
	}


static func catalog_digest(catalog: Dictionary) -> String:
	return JSON.stringify(TalePackage.canonicalize(catalog)).sha256_text()


static func entry_by_id(catalog: Dictionary, tale_id: String) -> Dictionary:
	for entry: Dictionary in catalog.get("entries", []):
		if entry.get("tale_id", "") == tale_id:
			return entry.duplicate(true)
	return {}


static func selection_metadata(entry: Dictionary, registry: TaleProviderRegistry) -> Dictionary:
	var display_result: Dictionary = _load_display(entry, {}, registry)
	if not display_result.get("accepted", false):
		return {}
	return {
		"tale_id": entry.get("tale_id", ""),
		"display_name": display_result.values.get(entry.display.display_key, ""),
		"briefing": display_result.values.get(entry.display.briefing_key, ""),
		"public_objective": display_result.values.get(entry.display.objective_key, ""),
		"package_sha256": entry.get("package_sha256", ""),
		"provider_id": entry.get("provider", {}).get("provider_id", ""),
	}


static func _validate_shape(catalog: Dictionary, path: String) -> Dictionary:
	if not _has_exact_keys(catalog, ROOT_KEYS):
		return _rejected(
			"unsupported_catalog_schema", path, "catalog root fields are incomplete or unknown"
		)
	if (
		catalog.get("catalog_kind") != CATALOG_KIND
		or catalog.get("schema_version") != SCHEMA_VERSION
		or catalog.get("catalog_version") != CATALOG_VERSION
		or not _stable_id(catalog.get("default_tale_id", ""))
		or not catalog.get("entries") is Array
		or catalog.get("entries", []).is_empty()
		or not catalog.get("source_ledger") is Array
		or not catalog.get("compatibility") is Dictionary
		or not catalog.get("identity_policy") is Dictionary
	):
		return _rejected(
			"unsupported_catalog_schema",
			path,
			"catalog kind, schema, version, or required values are unsupported"
		)
	return {}


static func _load_display(
	entry: Dictionary, package: Dictionary, registry: TaleProviderRegistry
) -> Dictionary:
	var display: Dictionary = entry.get("display", {})
	var path_failure: Dictionary = _validate_repository_path(
		display.get("catalog_path", ""), "#/display/catalog_path", registry
	)
	if not path_failure.is_empty():
		return {
			"accepted": false,
			"code": path_failure.diagnostics[0].code,
			"message": path_failure.reason
		}
	var path: String = display.get("catalog_path", "")
	if FileAccess.get_sha256(path) != display.get("catalog_sha256", ""):
		return {
			"accepted": false,
			"code": "display_identity_mismatch",
			"message": "governed display catalog hash does not match",
		}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		return {
			"accepted": false,
			"code": "unresolved_catalog_display",
			"message": "governed display catalog is malformed",
		}
	var values: Dictionary = parsed
	for key_name: String in ["display_key", "briefing_key", "objective_key"]:
		var key: String = display.get(key_name, "")
		if key.is_empty() or not values.get(key) is String or values.get(key, "").is_empty():
			return {
				"accepted": false,
				"code": "unresolved_catalog_display",
				"message": "governed display key '%s' does not resolve" % key,
			}
	if not package.is_empty():
		var package_display: Dictionary = package.get("localization", {})
		if (
			package_display.get("catalog") != display.catalog_path
			or package_display.get("catalog_sha256") != display.catalog_sha256
			or package_display.get("display_key") != display.display_key
			or package_display.get("briefing_key") != display.briefing_key
			or package_display.get("objective_key") != display.objective_key
		):
			return {
				"accepted": false,
				"code": "display_reference_mismatch",
				"message": "catalog display references do not match the Tale package",
			}
	return {"accepted": true, "values": values.duplicate(true)}


static func _validate_ledger(
	ledger: Array, tale_ids: PackedStringArray, path: String, registry: TaleProviderRegistry
) -> Dictionary:
	var seen: Dictionary = {}
	var ordering: PackedStringArray = []
	for index: int in ledger.size():
		var record_value: Variant = ledger[index]
		var record_path: String = "%s#/source_ledger/%d" % [path, index]
		if not record_value is Dictionary or not _has_exact_keys(record_value, LEDGER_KEYS):
			return _rejected(
				"incomplete_source_ledger",
				record_path,
				"ledger record fields are incomplete or unknown"
			)
		var record: Dictionary = record_value
		if (
			not tale_ids.has(record.get("tale_id", ""))
			or not LEDGER_ROLES.has(record.get("role", ""))
		):
			return _rejected(
				"incomplete_source_ledger", record_path, "ledger Tale ID or role is not consumed"
			)
		var identity: String = "%s:%s" % [record.tale_id, record.role]
		if seen.has(identity):
			return _rejected(
				"duplicate_source_role", record_path, "ledger Tale roles must be unique"
			)
		seen[identity] = true
		ordering.append("%s:%s:%s" % [record.tale_id, record.role, record.path])
		var path_failure: Dictionary = _validate_repository_path(
			record.get("path", ""), record_path + "/path", registry, true
		)
		if not path_failure.is_empty():
			return path_failure
	if Array(ordering) != _sorted_copy(Array(ordering)):
		return _rejected(
			"unstable_catalog_ordering",
			path + "#/source_ledger",
			"source ledger must be stably sorted"
		)
	for tale_id: String in tale_ids:
		for role: String in LEDGER_ROLES:
			if not seen.has("%s:%s" % [tale_id, role]):
				return _rejected(
					"incomplete_source_ledger",
					path + "#/source_ledger",
					"every Tale requires governed display, provider registry, and package sources",
				)
	return {}


static func _validate_repository_path(
	value: String, path: String, registry: TaleProviderRegistry, allow_script_source: bool = false
) -> Dictionary:
	var normalized: String = value.to_lower().replace("\\", "/")
	if (
		not value.begins_with("res://") and not value.begins_with("game/")
		or value.contains(":\\")
		or value.begins_with("/")
		or normalized.begins_with("http://")
		or normalized.begins_with("https://")
		or normalized.begins_with("ws://")
		or normalized.begins_with("wss://")
	):
		return _rejected(
			"prohibited_catalog_path", path, "path must be repository-relative and offline"
		)
	if (
		(
			"/tests/" in normalized
			or "/.godot/" in normalized
			or "/builds/" in normalized
			or "/cache/" in normalized
			or "/test-results/" in normalized
		)
		and not registry.allows_test_fixtures()
	):
		return _rejected(
			"prohibited_catalog_path",
			path,
			"test, generated, build, and cache paths are prohibited"
		)
	var resource_path: String = value
	if value.begins_with("game/"):
		resource_path = "res://" + value.trim_prefix("game/")
	var exists: bool = FileAccess.file_exists(resource_path)
	if allow_script_source and normalized.ends_with(".gd"):
		exists = ResourceLoader.exists(resource_path)
	if not exists:
		return _rejected("unresolved_catalog_reference", path, "catalog source does not resolve")
	if not allow_script_source and normalized.ends_with(".gd"):
		return _rejected(
			"prohibited_catalog_path", path, "catalog data cannot name runtime scripts"
		)
	return {}


static func _has_exact_keys(value: Dictionary, expected: PackedStringArray) -> bool:
	if value.size() != expected.size():
		return false
	for key: Variant in value:
		if not key is String or not expected.has(key):
			return false
	return true


static func _stable_id(value: Variant) -> bool:
	return (
		value is String
		and not String(value).is_empty()
		and String(value) == String(value).to_lower()
		and String(value).is_valid_identifier()
	)


static func _sha256(value: Variant) -> bool:
	if not value is String or String(value).length() != 64:
		return false
	for character: String in String(value):
		if character not in "0123456789abcdef":
			return false
	return true


static func _sorted_copy(values: Array) -> Array:
	var sorted: Array = values.duplicate()
	sorted.sort()
	return sorted


static func _rejected(code: String, path: String, message: String) -> Dictionary:
	return {
		"accepted": false,
		"diagnostics": [{"code": code, "path": path, "message": message}],
		"reason": "%s:%s:%s" % [code, path, message],
	}
