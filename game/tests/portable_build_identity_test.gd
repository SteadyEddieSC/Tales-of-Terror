extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_identity_and_support_page()
	_test_identity_validation()
	_test_platform_report_guidance()
	if _failures == 0:
		print("Portable build identity tests passed")
	quit(0 if _failures == 0 else 1)


func _test_identity_and_support_page() -> void:
	var coordinator := VerticalSliceCoordinator.new()
	coordinator.seat_manager.join_device(0, "support-fixture-pad", "Fixture Pad")
	coordinator.enter_lobby()
	coordinator.confirm_roster()
	var initialized: Dictionary = coordinator.initialize_session(4706)
	_expect(initialized.accepted, "initializes RNG-backed authority for support invariance")
	var companion_projection: Dictionary = {
		"available": true, "room_open": true, "connected_count": 1
	}
	var report := PlaytestReport.new()
	report.begin(coordinator.public_state(), coordinator.seed, "2026-07-21T00:00:00Z", 0)
	report.observe(coordinator.public_state(), [], companion_projection, 1)
	var snapshot_before: Dictionary = coordinator.to_snapshot()
	var authority_before: String = coordinator.authority_digest()
	var history_before: String = coordinator.public_history_digest()
	var rng_before: Dictionary = _rng_backed_state(snapshot_before)
	var report_before: String = report.to_json()
	var companion_before: String = JSON.stringify(companion_projection)
	var identity: Dictionary = InternalBuildIdentity.read_identity()
	_expect(identity.release == "v0.1.9", "uses the v0.1.9 project release identity")
	_expect(
		(
			InternalBuildIdentity
			. validate_identity(identity, identity.classification == "source_checkout")
			. accepted
		),
		"uses an exact internal identity or genuine editor source-checkout fallback",
	)
	var help := GuidedSessionHelp.new()
	help._ready()
	(
		help
		. open_help(
			coordinator.public_state(),
			coordinator.seat_manager.get_seats(),
			companion_projection,
			true,
		)
	)
	for _page: int in 3:
		help.handle_action("ui_navigate_right")
	var support: String = help.page_text()
	_expect(help.page_index() == 3, "opens the bounded Build & Support page")
	_expect("RELEASE   v0.1.9" in support, "renders the exact release")
	_expect(
		"BUILD ID   %s" % str(identity.source_commit).substr(0, 12) in support,
		"renders the short build ID",
	)
	_expect(
		"TARGET   %s / %s" % [identity.platform, identity.architecture] in support,
		"renders the current platform and architecture",
	)
	_expect(
		str(identity.classification) in support,
		"visibly renders the machine-readable build classification",
	)
	_expect(
		(
			"INTERNAL PLAYTEST" in support
			if identity.classification == "internal_playtest"
			else "SOURCE CHECKOUT" in support
		),
		"renders an understandable build classification label",
	)
	_expect(
		"Terror Turn (provisional working title)" in support,
		"retains provisional project-folder status",
	)
	_expect("lantern_house_vertical_slice v1" in support, "renders the scenario version")
	_expect("REPORT SCHEMA   v2" in support, "renders the report schema")
	_expect(
		InternalBuildIdentity.report_location_text(identity.platform) in support,
		"renders the actionable current-platform report location",
	)
	_expect("Hold Y / R 1.5s" in support, "renders protected reset guidance")
	_expect(
		"Include release, build ID, target, classification" in support,
		"renders bounded support-reporting guidance",
	)
	for forbidden: String in [
		"C:\\Users\\",
		"/home/",
		"Documents\\Codex",
		"Tales-of-Terror",
		"token=",
		"room_code=",
		"device_id=",
		"ip_address=",
	]:
		_expect(not forbidden in support, "omits private support value %s" % forbidden)
	help.handle_action("ui_navigate_right")
	help.handle_action("ui_navigate_left")
	help.close_help()
	_expect(snapshot_before == coordinator.to_snapshot(), "support presentation preserves snapshot")
	_expect(
		authority_before == coordinator.authority_digest(),
		"support presentation preserves authority",
	)
	_expect(
		history_before == coordinator.public_history_digest(),
		"support presentation preserves public history",
	)
	_expect(
		rng_before == _rng_backed_state(coordinator.to_snapshot()),
		"support presentation preserves RNG-backed state",
	)
	_expect(report_before == report.to_json(), "support presentation preserves the report")
	_expect(
		companion_before == JSON.stringify(companion_projection),
		"support presentation preserves companion projection",
	)
	help.free()


func _test_identity_validation() -> void:
	var valid: Dictionary = _valid_internal_identity("windows")
	_expect(
		InternalBuildIdentity.validate_identity(valid).accepted,
		"accepts the exact v0.1.9 internal Windows identity",
	)
	var valid_linux: Dictionary = _valid_internal_identity("linux")
	_expect(
		InternalBuildIdentity.validate_identity(valid_linux).accepted,
		"accepts the exact v0.1.9 internal Linux identity",
	)
	var invalid_cases: Array[Dictionary] = []
	var invalid_source: Dictionary = valid.duplicate(true)
	invalid_source.source_commit = "A".repeat(40)
	invalid_cases.append({"identity": invalid_source, "name": "uppercase source SHA"})
	var short_source: Dictionary = valid.duplicate(true)
	short_source.source_commit = "a".repeat(39)
	invalid_cases.append({"identity": short_source, "name": "short source SHA"})
	var invalid_release: Dictionary = valid.duplicate(true)
	invalid_release.release = "v0.1.2"
	invalid_cases.append({"identity": invalid_release, "name": "release"})
	var invalid_platform: Dictionary = valid.duplicate(true)
	invalid_platform.platform = "macos"
	invalid_cases.append({"identity": invalid_platform, "name": "platform"})
	var invalid_architecture: Dictionary = valid.duplicate(true)
	invalid_architecture.architecture = "arm64"
	invalid_cases.append({"identity": invalid_architecture, "name": "architecture"})
	var invalid_classification: Dictionary = valid.duplicate(true)
	invalid_classification.classification = "public_release"
	invalid_cases.append({"identity": invalid_classification, "name": "classification"})
	var extra: Dictionary = valid.duplicate(true)
	extra.username = "private-builder"
	invalid_cases.append({"identity": extra, "name": "extra key"})
	for invalid: Dictionary in invalid_cases:
		_expect(
			not InternalBuildIdentity.validate_identity(invalid.identity).accepted,
			"rejects invalid internal identity %s" % invalid.name,
		)
	var source_checkout: Dictionary = {
		"schema_version": 1,
		"release": "v0.1.9",
		"source_commit": "source-checkout",
		"platform": OS.get_name().to_lower(),
		"architecture": "development",
		"classification": "source_checkout",
	}
	_expect(
		not InternalBuildIdentity.validate_identity(source_checkout).accepted,
		"rejects source checkout as an exported identity",
	)
	_expect(
		InternalBuildIdentity.validate_identity(source_checkout, true).accepted,
		"accepts the exact source-checkout identity only with explicit editor fallback permission",
	)
	var source_support: String = InternalBuildIdentity.support_text(source_checkout)
	_expect(
		"SOURCE CHECKOUT (source_checkout)" in source_support,
		"renders source checkout distinctly from an internal artifact",
	)
	_expect(
		not "INTERNAL PLAYTEST" in source_support,
		"never labels source checkout as an internal artifact",
	)


func _test_platform_report_guidance() -> void:
	var windows_support: String = InternalBuildIdentity.support_text(
		_valid_internal_identity("windows")
	)
	_expect(
		InternalBuildIdentity.WINDOWS_REPORT_LOCATION in windows_support,
		"renders the exact Windows APPDATA path",
	)
	_expect(
		"%APPDATA%" in windows_support and not "C:\\Users\\" in windows_support,
		"keeps Windows guidance user-relative",
	)
	var linux_support: String = InternalBuildIdentity.support_text(
		_valid_internal_identity("linux")
	)
	_expect(
		InternalBuildIdentity.LINUX_REPORT_LOCATION in linux_support,
		"renders the exact Linux XDG path",
	)
	_expect(
		InternalBuildIdentity.LINUX_REPORT_FALLBACK in linux_support,
		"renders the usual Linux default fallback",
	)
	_expect(
		"when XDG_DATA_HOME is unset" in linux_support, "explains when the Linux fallback applies"
	)


func _valid_internal_identity(platform: String) -> Dictionary:
	return {
		"schema_version": 1,
		"release": "v0.1.9",
		"source_commit": "a".repeat(40),
		"platform": platform,
		"architecture": "x86_64",
		"classification": "internal_playtest",
	}


func _rng_backed_state(snapshot: Dictionary) -> Dictionary:
	var rules: Dictionary = snapshot.get("rules", {})
	var director: Dictionary = snapshot.get("director", {})
	var roles: Dictionary = snapshot.get("roles", {})
	return {
		"rules": rules.get("rng", {}),
		"director": director.get("rng", {}),
		"roles": roles.get("rng", {}),
	}


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
		return
	_failures += 1
	push_error("FAILED: %s" % message)
