extends SceneTree

const PACKAGE_PATH: String = "res://data/tales/lantern_house/tale_package_v1.json"
const EXPECTED_DIGEST: String = "abb39d6bfbdf8d7de108379f08180c13efb99bbffa3e53f30eaaa8de7f459dee"

var _failures: int = 0


func _initialize() -> void:
	_test_valid_package_identity_inventory_and_sources()
	_test_runtime_fails_closed_atomically()
	if _failures == 0:
		print("Tale package runtime tests passed")
	quit(_failures)


func _test_valid_package_identity_inventory_and_sources() -> void:
	var result: Dictionary = (
		TalePackage
		. load_validated(
			PACKAGE_PATH,
			LanternHouseBoardDefinition.new(),
			LanternHouseRulesContent.new(),
			LanternHouseDirectorContent.new(),
			LanternHouseSocialContent.new(),
		)
	)
	_expect(result.accepted, "loads the reviewed supported Tale package")
	if not result.accepted:
		return
	_expect(result.digest == EXPECTED_DIGEST, "matches the cross-tool canonical SHA-256")
	_expect(result.package.package_kind == "tale", "uses the explicit Tale package kind")
	_expect(result.package.schema_version == 1, "uses the supported Tale schema")
	_expect(
		result.package.tale_id == "lantern_house_vertical_slice", "preserves the stable Tale ID"
	)
	_expect(result.manifest.scenario_version == 1, "preserves the accepted scenario version")
	_expect(result.inventory.stages.size() == 5, "inventories five accepted stages")
	_expect(result.inventory.events.size() == 3, "inventories three accepted events")
	_expect(result.inventory.roles.size() == 8, "inventories eight accepted roles")
	_expect(result.source_ledger.size() == 6, "publishes the bounded source ledger")
	_expect(
		result.compatibility.minimum_seats == 1 and result.compatibility.maximum_seats == 8,
		"declares the accepted 1-8 seat compatibility",
	)


func _test_runtime_fails_closed_atomically() -> void:
	var coordinator := VerticalSliceCoordinator.new()
	coordinator.seat_manager.join_device(0, "package-fixture", "Fixture Pad")
	coordinator.enter_lobby()
	coordinator.confirm_roster()
	var stable: Dictionary = coordinator.to_snapshot()
	var legacy: Dictionary = coordinator.initialize_session(VerticalSliceCoordinator.MANIFEST_PATH)
	_expect(not legacy.accepted, "rejects a legacy manifest that bypasses the Tale package")
	_expect(coordinator.to_snapshot() == stable, "keeps legacy-path rejection atomic")
	var package: Dictionary = VerticalSliceManifest.load_file(PACKAGE_PATH)
	package.package_version = 2
	var temporary_path: String = "user://synthetic_invalid_tale_package.json"
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		_expect(false, "creates the synthetic unsupported-identity probe")
		return
	file.store_string(JSON.stringify(package))
	file.close()
	var unsupported: Dictionary = coordinator.initialize_session(temporary_path)
	_expect(not unsupported.accepted, "rejects a non-allowlisted package identity")
	_expect(
		"unsupported_package_identity" in unsupported.get("reason", ""),
		"returns an actionable unsupported-identity diagnostic",
	)
	_expect(coordinator.to_snapshot() == stable, "keeps unsupported-package rejection atomic")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary_path))
	var initialized: Dictionary = coordinator.initialize_session(PACKAGE_PATH, 4706)
	_expect(initialized.accepted, "accepts the reviewed package after prior rejections")
	_expect(
		coordinator.tale_package_digest == EXPECTED_DIGEST,
		"retains presentation-only package identity"
	)


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
		return
	_failures += 1
	push_error("FAILED: %s" % message)
