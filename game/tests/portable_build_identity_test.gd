extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_identity_and_support_page()
	_test_identity_validation()
	if _failures == 0:
		print("Portable build identity tests passed")
	quit(0 if _failures == 0 else 1)


func _test_identity_and_support_page() -> void:
	var coordinator := VerticalSliceCoordinator.new()
	var snapshot_before: Dictionary = coordinator.to_snapshot()
	var authority_before: String = coordinator.authority_digest()
	var history_before: String = coordinator.public_history_digest()
	var identity: Dictionary = InternalBuildIdentity.read_identity()
	_expect(identity.release == "v0.1.2", "uses the v0.1.2 project release identity")
	_expect(
		identity.classification in ["source_checkout", "internal_playtest"],
		"bounds the build classification",
	)
	var help := GuidedSessionHelp.new()
	help._ready()
	help.open_help(coordinator.public_state(), [], {}, false)
	for _page: int in 3:
		help.handle_action("ui_navigate_right")
	var support: String = help.page_text()
	_expect(help.page_index() == 3, "opens the bounded Build & Support page")
	_expect("RELEASE   v0.1.2" in support, "renders the exact release")
	_expect("lantern_house_vertical_slice v1" in support, "renders the scenario version")
	_expect("REPORT SCHEMA   v2" in support, "renders the report schema")
	_expect(InternalBuildIdentity.REPORT_LOCATION in support, "renders local report guidance")
	_expect("Hold Y / R 1.5s" in support, "renders protected reset guidance")
	for forbidden: String in ["C:/", "C:\\", "token=", "room_code=", "device_id=", "ip_address="]:
		_expect(not forbidden in support, "omits private support value %s" % forbidden)
	help.close_help()
	_expect(snapshot_before == coordinator.to_snapshot(), "support presentation preserves snapshot")
	_expect(
		authority_before == coordinator.authority_digest(),
		"support presentation preserves authority"
	)
	_expect(
		history_before == coordinator.public_history_digest(),
		"support presentation preserves public history",
	)
	help.free()


func _test_identity_validation() -> void:
	var valid: Dictionary = {
		"schema_version": 1,
		"release": "v0.1.2",
		"source_commit": "a".repeat(40),
		"platform": "windows",
		"architecture": "x86_64",
		"classification": "internal_playtest",
	}
	_expect(
		InternalBuildIdentity.validate_identity(valid).accepted, "accepts the exact identity schema"
	)
	var extra: Dictionary = valid.duplicate(true)
	extra.username = "private-builder"
	_expect(
		not InternalBuildIdentity.validate_identity(extra).accepted,
		"rejects unknown private identity keys",
	)
	var invalid_class: Dictionary = valid.duplicate(true)
	invalid_class.classification = "public_release"
	_expect(
		not InternalBuildIdentity.validate_identity(invalid_class).accepted,
		"rejects public-release misclassification",
	)


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
		return
	_failures += 1
	push_error("FAILED: %s" % message)
