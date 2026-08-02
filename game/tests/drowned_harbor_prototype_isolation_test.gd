extends SceneTree

const MANIFEST_PATH: String = "res://tests/drowned_harbor_prototype_manifest_v1.json"
const PRODUCTION_CATALOG_PATH: String = "res://data/tales/tale_catalog_v1.json"
const PRODUCTION_PROVIDER_PATH: String = "res://src/session/tale_provider_registry.gd"
const EXPORT_PRESETS_PATH: String = "res://export_presets.cfg"
const PROJECT_PATH: String = "res://project.godot"
const AUTOMATION_PROFILE_PATH: String = (
	"res://tests/drowned_harbor_dev_only/" + "prototype_automation_profile_v1.json"
)
const DROWNED_HARBOR_PRODUCTION_PACKAGE: String = (
	"res://data/tales/drowned_harbor/" + "tale_package_v1.json"
)
const EXPECTED_ENTRY_POINTS: PackedStringArray = [
	"res://tests/drowned_harbor_low_tide_shell_test.gd",
	"res://tests/drowned_harbor_bellhouse_recovery_test.gd",
	"res://tests/drowned_harbor_controlled_private_shield_test.gd",
	"res://tests/drowned_harbor_high_water_transformation_test.gd",
	"res://tests/drowned_harbor_prototype_automation_test.gd",
	"res://tests/drowned_harbor_prototype_isolation_test.gd",
]
const EXPECTED_COMPONENTS: PackedStringArray = [
	"res://tests/drowned_harbor_dev_only/low_tide_fixture_adapter.gd",
	"res://tests/drowned_harbor_dev_only/low_tide_shared_screen_shell.gd",
	"res://tests/drowned_harbor_dev_only/low_tide_shared_screen_shell.tscn",
	"res://tests/drowned_harbor_dev_only/bellhouse_fixture_adapter.gd",
	"res://tests/drowned_harbor_dev_only/bellhouse_decision_shell.gd",
	"res://tests/drowned_harbor_dev_only/bellhouse_decision_shell.tscn",
	"res://tests/drowned_harbor_dev_only/controlled_private_fixture_adapter.gd",
	"res://tests/drowned_harbor_dev_only/controlled_private_surface.gd",
	"res://tests/drowned_harbor_dev_only/controlled_private_shield_shell.gd",
	"res://tests/drowned_harbor_dev_only/controlled_private_shield_shell.tscn",
	"res://tests/drowned_harbor_dev_only/high_water_fixture_adapter.gd",
	"res://tests/drowned_harbor_dev_only/high_water_transformation_shell.gd",
	"res://tests/drowned_harbor_dev_only/high_water_transformation_shell.tscn",
]

var _failures: int = 0


func _initialize() -> void:
	_test_development_manifest_is_fail_closed()
	_test_production_catalog_remains_lantern_house_only()
	_test_normal_runtime_has_no_drowned_harbor_registration()
	_test_windows_and_linux_exports_exclude_tests()
	if _failures == 0:
		print("Drowned Harbor prototype isolation tests passed")
	quit(_failures)


func _test_development_manifest_is_fail_closed() -> void:
	_expect(
		FileAccess.file_exists(MANIFEST_PATH),
		"development manifest exists only as a test fixture",
	)
	if not FileAccess.file_exists(MANIFEST_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	_expect(
		typeof(parsed) == TYPE_DICTIONARY,
		"development manifest parses as an object",
	)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var manifest: Dictionary = parsed
	_expect(
		manifest.get("prototype_kind") == "isolated_tale_prototype",
		"uses isolated prototype kind",
	)
	_expect(manifest.get("schema_version") == 1, "uses prototype schema v1")
	_expect(
		manifest.get("prototype_id") == "drowned_harbor_dev_only",
		"uses unmistakable dev-only identity",
	)
	_expect(
		manifest.get("tale_id") == "drowned_harbor",
		"retains the stable design Tale ID",
	)
	_expect(
		manifest.get("status") == "development_only_export_excluded",
		"declares development-only export-excluded status",
	)
	_expect(
		manifest.get("launch_policy") == "explicit_test_script_only",
		"requires an explicit test-only entry path",
	)
	var entry_points: Array = manifest.get("allowed_entry_points", [])
	_expect(
		PackedStringArray(entry_points) == EXPECTED_ENTRY_POINTS,
		"declares the exact six bounded test entry points",
	)
	for entry_point: Variant in entry_points:
		_expect(
			str(entry_point).begins_with("res://tests/"),
			"keeps every prototype entry point under res://tests/",
		)
		_expect(
			FileAccess.file_exists(str(entry_point)),
			"every prototype entry point exists",
		)
	var components: Array = manifest.get("prototype_components", [])
	_expect(
		PackedStringArray(components) == EXPECTED_COMPONENTS,
		"declares the exact thirteen prototype component paths",
	)
	for component: Variant in components:
		_expect(
			str(component).begins_with("res://tests/"),
			"keeps every prototype component under res://tests/",
		)
		_expect(FileAccess.file_exists(str(component)), "every prototype component exists")
	_expect(
		not manifest.get("production_catalog_registered", true),
		"does not register a production catalog entry",
	)
	_expect(
		not manifest.get("production_provider_registered", true),
		"does not register a production provider",
	)
	_expect(
		not manifest.get("normal_tale_library_visible", true),
		"does not appear in the normal Tale Library",
	)
	_expect(
		not manifest.get("playable_export_authorized", true),
		"does not authorize a playable export",
	)
	_expect(
		not manifest.get("runtime_authority_created", true),
		"creates no production runtime authority",
	)
	var dependencies: Dictionary = manifest.get("dependencies", {})
	for dependency: String in [
		"network",
		"companion",
		"credentials",
		"telemetry",
		"cloud",
		"production_assets",
	]:
		_expect(
			not dependencies.get(dependency, true),
			"declares no %s dependency" % dependency,
		)
	_expect(
		(
			PackedInt32Array(manifest.get("completed_work_issues", []))
			== PackedInt32Array([80, 81, 82, 83, 84, 85, 86])
		),
		"records issues #80 through #86 as completed bounded packages",
	)
	_expect(
		PackedInt32Array(manifest.get("future_work_issues", [])).is_empty(),
		"keeps the future-work issue inventory empty",
	)
	_expect(
		(
			"docs/technical/Drowned_Harbor_High_Water_Deterministic_Transformation_v1.md"
			in manifest.get("source_authorities", [])
		),
		"registers the P0.18 technical authority",
	)
	_expect(
		(
			"docs/technical/Drowned_Harbor_Prototype_Automation_Export_Exclusion_v1.md"
			in manifest.get("source_authorities", [])
		),
		"registers the P0.19 technical authority",
	)
	_expect(
		manifest.get("automation_profiles") == [AUTOMATION_PROFILE_PATH],
		"registers exactly one test-only automation profile",
	)
	_expect(FileAccess.file_exists(AUTOMATION_PROFILE_PATH), "automation profile exists")
	_expect(
		AUTOMATION_PROFILE_PATH.begins_with("res://tests/"),
		"automation profile stays under the test tree",
	)
	_expect(
		manifest.get("human_validation_required") == true,
		"retains future human-validation requirement",
	)
	_expect(
		not manifest.get("human_evidence_claimed", true),
		"claims no human evidence",
	)


func _test_production_catalog_remains_lantern_house_only() -> void:
	var registry := TaleProviderRegistry.new()
	var result: Dictionary = (
		TaleCatalog
		. load_validated(
			TaleCatalog.PRODUCTION_PATH,
			registry,
			TaleCatalog.PRODUCTION_DIGEST,
		)
	)
	_expect(result.accepted, "production Tale catalog still validates")
	if not result.accepted:
		return
	_expect(
		result.inventory.size() == 1,
		"production catalog still contains exactly one Tale",
	)
	_expect(
		result.default_tale_id == TalePackage.LANTERN_HOUSE_ID,
		"production default remains Lantern House",
	)
	_expect(
		result.inventory[0].tale_id == TalePackage.LANTERN_HOUSE_ID,
		"only production inventory entry remains Lantern House",
	)
	var production_text: String = FileAccess.get_file_as_string(PRODUCTION_CATALOG_PATH).to_lower()
	_expect(
		"drowned_harbor" not in production_text,
		"production catalog contains no Drowned Harbor entry",
	)
	_expect(
		"res://tests/" not in production_text,
		"production catalog contains no test-only path",
	)


func _test_normal_runtime_has_no_drowned_harbor_registration() -> void:
	_expect(
		FileAccess.file_exists(DROWNED_HARBOR_PRODUCTION_PACKAGE),
		"exact issue #100 Drowned Harbor scaffold package exists",
	)
	var scoped_provider := DrownedHarborScopedProvider.new()
	var candidate: Dictionary = scoped_provider.build_candidate()
	_expect(candidate.get("accepted", false), "exact issue #100 scoped candidate validates")
	if candidate.get("accepted", false):
		_expect(
			candidate.package.tale_id == "drowned_harbor",
			"scoped candidate has the exact Drowned Harbor Tale identity",
		)
		_expect(
			candidate.provider_id == "drowned_harbor_authorities_v1",
			"scoped candidate has the exact alpha.1 provider identity",
		)
		_expect(
			candidate.scenario.scenario_id == "drowned_harbor_scaffold_v1",
			"scoped candidate has the exact alpha.1 scenario identity",
		)
		_expect(
			candidate.localization.catalog_id == "drowned_harbor_placeholder_en_v1",
			"scoped candidate has the exact placeholder-localization identity",
		)
	var gate := DrownedHarborDeveloperAdmissionGate.new()
	var ambiguous: Dictionary = gate.admit({})
	_expect(
		(
			not ambiguous.get("accepted", false)
			and ambiguous.get("reason", "") == "malformed_admission_request"
		),
		"scoped scaffold rejects non-explicit normal admission",
	)
	_expect(
		not gate.has_active_scaffold(), "rejected normal admission commits no scaffold authority"
	)
	var provider_text: String = FileAccess.get_file_as_string(PRODUCTION_PROVIDER_PATH).to_lower()
	_expect(
		"drowned_harbor" not in provider_text,
		"production provider registry contains no Drowned Harbor provider",
	)
	var registry := TaleProviderRegistry.new()
	_expect(
		registry.provider_ids() == PackedStringArray(["lantern_house_authorities_v1"]),
		"production provider allowlist remains Lantern House only",
	)
	var project_text: String = FileAccess.get_file_as_string(PROJECT_PATH)
	_expect(
		'run/main_scene="res://src/main/Main.tscn"' in project_text,
		"production startup remains the reviewed Main scene",
	)
	_expect(
		"drowned_harbor_prototype_automation" not in project_text,
		"aggregate automation is not production-startup reachable",
	)
	_expect(
		"prototype_automation_profile_v1.json" not in project_text,
		"automation profile is not production-startup reachable",
	)


func _test_windows_and_linux_exports_exclude_tests() -> void:
	var preset_text: String = FileAccess.get_file_as_string(EXPORT_PRESETS_PATH)
	_expect(
		preset_text.count('exclude_filter="') == 2,
		"both export presets declare exclusions",
	)
	_expect(
		preset_text.count("tests/*") == 2,
		"both export presets exclude the test tree",
	)
	for filename: String in [
		"drowned_harbor_prototype_manifest_v1.json",
		"drowned_harbor_prototype_isolation_test.gd",
		"drowned_harbor_low_tide_shell_test.gd",
		"drowned_harbor_bellhouse_recovery_test.gd",
		"drowned_harbor_controlled_private_shield_test.gd",
		"drowned_harbor_high_water_transformation_test.gd",
		"drowned_harbor_prototype_automation_test.gd",
		"prototype_automation_profile_v1.json",
		"low_tide_fixture_adapter.gd",
		"low_tide_shared_screen_shell.gd",
		"low_tide_shared_screen_shell.tscn",
		"bellhouse_fixture_adapter.gd",
		"bellhouse_decision_shell.gd",
		"bellhouse_decision_shell.tscn",
		"controlled_private_fixture_adapter.gd",
		"controlled_private_surface.gd",
		"controlled_private_shield_shell.gd",
		"controlled_private_shield_shell.tscn",
	]:
		_expect(
			filename not in preset_text,
			"no export include rule names %s" % filename,
		)


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
		return
	_failures += 1
	push_error("FAILED: %s" % message)
