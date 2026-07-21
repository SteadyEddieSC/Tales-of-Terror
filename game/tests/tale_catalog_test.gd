extends SceneTree

const SYNTHETIC_CATALOG_PATH: String = (
	"res://tests/fixtures/" + "synthetic_two_entry_tale_catalog_v1.json"
)
const SYNTHETIC_CATALOG_DIGEST: String = (
	"06a1f9968fa255aa9bad1cf09fe30ec2" + "553e64599c3f8995d20aaa1610cc31c1"
)

var _failures: int = 0


func _initialize() -> void:
	_test_production_catalog_and_provider_identity()
	_test_default_explicit_and_atomic_selection()
	_test_synthetic_two_entry_selection()
	_test_runtime_provider_and_package_fail_closed()
	_test_provenance_exclusion_and_non_shipment()
	if _failures == 0:
		print("Tale catalog, selection, and provider tests passed")
	quit(_failures)


func _test_production_catalog_and_provider_identity() -> void:
	var registry := TaleProviderRegistry.new()
	var result: Dictionary = TaleCatalog.load_validated(
		TaleCatalog.PRODUCTION_PATH, registry, TaleCatalog.PRODUCTION_DIGEST
	)
	_expect(result.accepted, "accepts the one-entry production Tale catalog")
	if not result.accepted:
		return
	_expect(result.catalog.catalog_kind == "tale_catalog", "uses the closed catalog kind")
	_expect(result.catalog.schema_version == 1, "uses catalog schema v1")
	_expect(result.catalog.catalog_version == 1, "uses catalog content version 1")
	_expect(result.digest == TaleCatalog.PRODUCTION_DIGEST, "matches canonical catalog SHA-256")
	_expect(
		result.default_tale_id == TalePackage.LANTERN_HOUSE_ID,
		"defaults to the accepted Lantern House stable ID",
	)
	_expect(result.inventory.size() == 1, "ships exactly one production Tale entry")
	_expect(
		result.inventory[0].package_sha256 == TalePackage.LANTERN_HOUSE_DIGEST,
		"catalog resolves the exact accepted Lantern House package",
	)
	_expect(
		registry.provider_ids() == PackedStringArray(["lantern_house_authorities_v1"]),
		"production registry exposes one static reviewed provider",
	)
	var entry: Dictionary = TaleCatalog.entry_by_id(result.catalog, result.default_tale_id)
	var candidate: Dictionary = registry.build_candidate(entry)
	_expect(candidate.accepted, "provider constructs one complete validated content candidate")
	_expect(
		candidate.package_digest == TalePackage.LANTERN_HOUSE_DIGEST,
		"provider candidate retains exact package identity",
	)


func _test_default_explicit_and_atomic_selection() -> void:
	var coordinator := VerticalSliceCoordinator.new()
	_expect(
		coordinator._selection.selected_tale_id() == TalePackage.LANTERN_HOUSE_ID,
		"coordinator receives its default through the catalog",
	)
	_expect(coordinator.tale_package.is_empty(), "selection constructs no session authority")
	var before: Dictionary = coordinator.to_snapshot()
	var explicit: Dictionary = coordinator.select_tale(TalePackage.LANTERN_HOUSE_ID)
	_expect(explicit.accepted, "accepts explicit stable-ID pre-session selection")
	_expect(
		coordinator.to_snapshot() == before, "valid selection consumes no gameplay state or RNG"
	)
	var selected_before: Dictionary = coordinator._selection.entry.duplicate(true)
	var unknown: Dictionary = coordinator.select_tale("synthetic_unknown_tale")
	_expect(not unknown.accepted, "rejects an unknown stable-ID selection")
	_expect(
		coordinator._selection.entry == selected_before,
		"unknown selection atomically retains the prior valid selection",
	)
	_expect(coordinator.to_snapshot() == before, "unknown selection creates no authority mutation")
	coordinator.seat_manager.join_device(0, "catalog-fixture", "Fixture Pad")
	coordinator.enter_lobby()
	coordinator.confirm_roster()
	_expect(
		coordinator.initialize_session(4706).accepted, "initializes through selected catalog entry"
	)
	var initialized: Dictionary = coordinator.to_snapshot()
	_expect(
		not coordinator.select_tale(TalePackage.LANTERN_HOUSE_ID).accepted,
		"rejects selection after session authority initialization",
	)
	_expect(
		coordinator.to_snapshot() == initialized, "late selection preserves initialized authority"
	)


func _test_synthetic_two_entry_selection() -> void:
	var registry := SyntheticTaleProviderRegistry.new()
	var coordinator := VerticalSliceCoordinator.new(
		SYNTHETIC_CATALOG_PATH, registry, SYNTHETIC_CATALOG_DIGEST
	)
	_expect(
		coordinator._selection.catalog.get("entries", []).size() == 2,
		"loads two sorted unmistakably synthetic test-only entries",
	)
	_expect(
		coordinator._selection.selected_tale_id() == TalePackage.LANTERN_HOUSE_ID,
		"synthetic catalog preserves its declared default",
	)
	var before: Dictionary = coordinator.to_snapshot()
	var selected: Dictionary = coordinator.select_tale("synthetic_fixture_tale")
	_expect(selected.accepted, "selects the non-default synthetic fixture by stable ID")
	_expect(
		coordinator._selection.selected_tale_id() == "synthetic_fixture_tale",
		"retains the explicit non-default synthetic selection",
	)
	_expect(
		coordinator._selection.metadata.display_name == "Synthetic Test Tale — Not Shipped",
		"reads governed synthetic presentation only in the test fixture",
	)
	_expect(coordinator.to_snapshot() == before, "synthetic selection remains non-authoritative")
	_expect(
		coordinator.select_tale(TalePackage.LANTERN_HOUSE_ID).accepted, "reselects default fixture"
	)
	registry.reject_synthetic = true
	var stable_entry: Dictionary = coordinator._selection.entry.duplicate(true)
	var rejected: Dictionary = coordinator.select_tale("synthetic_fixture_tale")
	_expect(not rejected.accepted, "rejects a provider failure during non-default selection")
	_expect(
		coordinator._selection.entry == stable_entry,
		"provider failure atomically retains the prior valid selection",
	)
	_expect(coordinator.to_snapshot() == before, "provider failure creates no gameplay authority")


func _test_runtime_provider_and_package_fail_closed() -> void:
	var registry := TaleProviderRegistry.new()
	var catalog_result: Dictionary = TaleCatalog.load_validated(
		TaleCatalog.PRODUCTION_PATH, registry, TaleCatalog.PRODUCTION_DIGEST
	)
	var entry: Dictionary = catalog_result.catalog.entries[0].duplicate(true)
	entry.provider.provider_id = "synthetic_unknown_provider"
	var unknown: Dictionary = registry.build_candidate(entry)
	_expect(not unknown.accepted, "runtime rejects a provider outside the static allowlist")
	_expect("unknown_provider" in unknown.reason, "unknown-provider diagnostic is actionable")
	entry = catalog_result.catalog.entries[0].duplicate(true)
	entry.provider.board_reference = "synthetic_mismatch"
	var mismatch: Dictionary = registry.build_candidate(entry)
	_expect(not mismatch.accepted, "runtime rejects provider reference mismatch")
	_expect("provider_mismatch" in mismatch.reason, "provider mismatch diagnostic is actionable")
	entry = catalog_result.catalog.entries[0].duplicate(true)
	entry.package_sha256 = "0".repeat(64)
	var changed: Dictionary = registry.build_candidate(entry)
	_expect(not changed.accepted, "runtime rejects changed package identity")
	_expect(
		"unsupported_package_identity" in changed.reason,
		"package identity mismatch diagnostic is actionable",
	)
	var wrong_digest: Dictionary = TaleCatalog.load_validated(
		TaleCatalog.PRODUCTION_PATH, registry, "0".repeat(64)
	)
	_expect(not wrong_digest.accepted, "runtime rejects a changed catalog identity")


func _test_provenance_exclusion_and_non_shipment() -> void:
	var coordinator := VerticalSliceCoordinator.new()
	var snapshot_text: String = JSON.stringify(coordinator.to_snapshot())
	_expect("catalog" not in snapshot_text, "catalog provenance remains outside gameplay snapshots")
	_expect(
		TalePackage.LANTERN_HOUSE_DIGEST not in snapshot_text,
		"package provenance remains outside gameplay snapshots",
	)
	var production_text: String = FileAccess.get_file_as_string(TaleCatalog.PRODUCTION_PATH)
	_expect(
		"synthetic" not in production_text.to_lower(),
		"production catalog contains no synthetic entry"
	)
	_expect(
		"res://tests/" not in production_text, "production catalog contains no test fixture path"
	)


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
		return
	_failures += 1
	push_error("FAILED: %s" % message)
