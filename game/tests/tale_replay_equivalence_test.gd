extends SceneTree

const FIXTURE_PATH: String = "res://tests/fixtures/tale_replay_equivalence_v1.json"

var _failures: int = 0


func _initialize() -> void:
	var fixture: Dictionary = VerticalSliceManifest.load_file(FIXTURE_PATH)
	_expect(fixture.schema_version == 1, "loads the versioned replay-equivalence fixture")
	_expect(
		fixture.accepted_source_commit == "f455f6a0e723ca868b46c11e885c54fd250a4d43",
		"anchors equivalence to the accepted v0.1.3 source",
	)
	for test_case: Dictionary in fixture.cases:
		_run_case(test_case)
	if _failures == 0:
		print("Tale replay-equivalence matrix passed: %d/%d" % [fixture.cases.size(), 7])
	quit(_failures)


func _run_case(test_case: Dictionary) -> void:
	var coordinator: VerticalSliceCoordinator = _new_session(
		test_case.seats, test_case.seed, test_case.requested_mode
	)
	if coordinator.lifecycle != "active_tale":
		_expect(false, "%s initializes through the Tale package" % test_case.id)
		return
	_expect(
		coordinator.role_session.mode_id == test_case.expected_mode,
		"%s preserves mode" % test_case.id
	)
	_expect(
		coordinator.role_session.fallback_applied == test_case.fallback_applied,
		"%s preserves fallback classification" % test_case.id,
	)
	_complete(coordinator)
	var digest: String = coordinator.public_history_digest()
	_expect(
		digest == test_case.expected_history_digest,
		"%s matches golden semantic digest (actual %s)" % [test_case.id, digest],
	)
	match test_case.id:
		"role_afterlife_transition":
			_expect(
				coordinator.board_state.get_space_state("lantern_hall").features.has(
					"restless_omen"
				),
				"afterlife transition preserves meaningful public action",
			)
		"ending_resolution":
			_expect(
				(
					coordinator.lifecycle == "terminal"
					and not coordinator.public_state().ending.is_empty()
				),
				"ending resolution preserves the accepted public outcome",
			)
		"reset_and_rematch":
			_test_rematch(coordinator, digest)
		"report_identity_privacy":
			_test_report_boundary(coordinator)
		"companion_no_phone_authority":
			_test_companion_no_phone(test_case, coordinator)


func _test_rematch(coordinator: VerticalSliceCoordinator, first_digest: String) -> void:
	coordinator.review_ending()
	_expect(coordinator.rematch().accepted, "rematch reloads the validated package")
	_expect(coordinator.begin_tale().accepted, "rematch re-enters the Tale")
	_complete(coordinator)
	_expect(
		coordinator.public_history_digest() == first_digest, "rematch reproduces the same semantics"
	)


func _test_report_boundary(coordinator: VerticalSliceCoordinator) -> void:
	var report := PlaytestReport.new()
	report.begin(coordinator.public_state(), coordinator.seed, "2026-07-21T00:00:00Z", 0)
	(
		report
		. finalize(
			"ending",
			coordinator.public_state(),
			"2026-07-21T00:01:00Z",
			60,
			coordinator.authority_digest(),
			coordinator.public_history_digest(),
		)
	)
	var serialized: String = report.to_json()
	var report_value: Dictionary = report.to_report()
	_expect(report_value.schema_version == 2, "report schema remains v2")
	_expect(
		report_value.scenario.id == "lantern_house_vertical_slice",
		"report stable scenario ID is unchanged"
	)
	_expect(
		not TalePackage.LANTERN_HOUSE_DIGEST in serialized,
		"report excludes package provenance identity"
	)
	_expect(not "seat_private" in serialized, "report remains privacy-safe")
	_expect(
		not coordinator.to_snapshot().has("tale_package_digest"),
		"save snapshot excludes presentation provenance"
	)


func _test_companion_no_phone(test_case: Dictionary, no_phone: VerticalSliceCoordinator) -> void:
	var companion: VerticalSliceCoordinator = _new_session(
		test_case.seats, test_case.seed, test_case.requested_mode
	)
	_expect(
		companion.companion_bridge.create_room("replay_fixture", "RPLY3").accepted,
		"optional companion room opens without gaining authority",
	)
	_complete(companion)
	_expect(
		companion.authority_digest() == no_phone.authority_digest(),
		"companion availability preserves native authority",
	)
	_expect(
		companion.public_history_digest() == no_phone.public_history_digest(),
		"companion and no-phone routes preserve public history",
	)


func _new_session(seat_count: int, seed: int, requested_mode: String) -> VerticalSliceCoordinator:
	var coordinator := VerticalSliceCoordinator.new()
	for index: int in seat_count:
		coordinator.seat_manager.join_device(index, "sim-%d" % index, "Simulation Pad")
	coordinator.enter_lobby()
	coordinator.confirm_roster()
	coordinator.initialize_session(VerticalSliceCoordinator.TALE_PACKAGE_PATH, seed, requested_mode)
	coordinator.begin_tale()
	return coordinator


func _complete(coordinator: VerticalSliceCoordinator) -> void:
	while coordinator.lifecycle == "active_tale":
		var result: Dictionary = coordinator.run_current_stage()
		if not result.accepted:
			_expect(false, "fixture stage remains accepted")
			return


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
		return
	_failures += 1
	push_error("FAILED: %s" % message)
