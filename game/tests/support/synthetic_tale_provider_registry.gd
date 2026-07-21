class_name SyntheticTaleProviderRegistry
extends TaleProviderRegistry

const SYNTHETIC_PROVIDER_ID: String = "synthetic_fixture_authorities_v1"
const SYNTHETIC_PACKAGE_DIGEST: String = (
	"f2fd9156e4ecdde2396aacd647caff5d" + "64107ee47a911eca19dc67eb06f08e01"
)

var reject_synthetic: bool = false


func provider_ids() -> PackedStringArray:
	return PackedStringArray([LANTERN_HOUSE_PROVIDER_ID, SYNTHETIC_PROVIDER_ID])


func allows_test_fixtures() -> bool:
	return true


func provider_spec(provider_id: String) -> Dictionary:
	if provider_id != SYNTHETIC_PROVIDER_ID:
		return super.provider_spec(provider_id)
	return {
		"provider_id": SYNTHETIC_PROVIDER_ID,
		"provider_version": 1,
		"board_reference": "synthetic_fixture_board",
		"rules_reference": "synthetic_fixture_rules",
		"director_reference": "synthetic_fixture_director",
		"social_reference": "synthetic_fixture_social",
	}


func build_candidate(entry: Dictionary) -> Dictionary:
	if entry.get("provider", {}).get("provider_id", "") != SYNTHETIC_PROVIDER_ID:
		return super.build_candidate(entry)
	var reason: String = _synthetic_rejection_reason(entry)
	if not reason.is_empty():
		return _synthetic_rejected(reason)
	var path: String = entry.get("package_path", "")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	var package: Dictionary = RulesContent.SessionData.normalize_json_numbers(parsed)
	var digest: String = TalePackage.package_digest(package)
	if (
		package.get("fixture_kind") != "synthetic_tale_package_not_shipped_content"
		or package.get("package_kind") != entry.get("package_kind")
		or package.get("schema_version") != entry.get("package_schema_version")
		or package.get("tale_id") != entry.get("tale_id")
		or package.get("package_version") != entry.get("package_version")
		or digest != entry.get("package_sha256")
		or digest != SYNTHETIC_PACKAGE_DIGEST
	):
		return _synthetic_rejected("synthetic_package_identity_mismatch")
	var content: Dictionary = super._construct_content(LANTERN_HOUSE_PROVIDER_ID)
	return {
		"accepted": true,
		"diagnostics": [],
		"provider_id": SYNTHETIC_PROVIDER_ID,
		"provider_spec": provider_spec(SYNTHETIC_PROVIDER_ID),
		"package": package,
		"package_digest": digest,
		"manifest": {},
		"inventory": {},
		"board_definition": content.board,
		"rules_content": content.rules,
		"director_content": content.director,
		"social_content": content.social,
	}


func _synthetic_rejection_reason(entry: Dictionary) -> String:
	if reject_synthetic:
		return "synthetic_provider_forced_rejection"
	if entry.get("provider", {}) != provider_spec(SYNTHETIC_PROVIDER_ID):
		return "synthetic_provider_mismatch"
	var path: String = entry.get("package_path", "")
	if not FileAccess.file_exists(path):
		return "synthetic_package_missing"
	if not JSON.parse_string(FileAccess.get_file_as_string(path)) is Dictionary:
		return "synthetic_package_malformed"
	return ""


static func _synthetic_rejected(reason: String) -> Dictionary:
	return {
		"accepted": false,
		"diagnostics":
		[
			{
				"code": "synthetic_fixture_rejected",
				"path": "#/provider",
				"message": reason,
			}
		],
		"reason": reason,
	}
