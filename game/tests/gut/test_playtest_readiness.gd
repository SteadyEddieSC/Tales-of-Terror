extends GutTest


func test_help_open_close_is_authority_byte_equivalent() -> void:
	var coordinator := _coordinator()
	var before: Dictionary = coordinator.to_snapshot()
	var digest: String = coordinator.authority_digest()
	var help := GuidedSessionHelp.new()
	help._ready()
	help.open_help(coordinator.public_state(), coordinator.seat_manager.get_seats(), {}, false)
	help.handle_action("ui_navigate_right")
	help.handle_action("help_accessibility")
	assert_eq(coordinator.to_snapshot(), before)
	assert_eq(coordinator.authority_digest(), digest)
	help.free()


func test_report_filters_planted_private_values() -> void:
	var state: Dictionary = _coordinator().public_state()
	state["private_role"] = "never_report_role"
	state["client_id"] = "never_report_client"
	var report := PlaytestReport.new()
	report.begin(state, 4706, "2026-07-20T20:00:00Z", 0)
	report.finalize("reset", state, "2026-07-20T20:01:00Z", 60, "a".repeat(64), "b".repeat(64))
	assert_false("never_report_role" in report.to_json())
	assert_false("never_report_client" in report.to_json())
	assert_true(PlaytestReport.validate_schema(report.to_report()).accepted)


func test_export_uses_replaceable_writer_and_reports_failure() -> void:
	var state: Dictionary = _coordinator().public_state()
	var report := PlaytestReport.new()
	report.begin(state, 4706, "2026-07-20T20:00:00Z", 0)
	report.finalize("ending", state, "2026-07-20T20:01:00Z", 60, "a".repeat(64), "b".repeat(64))
	var writer := PlaytestMemoryWriter.new()
	assert_true(report.export_with(writer, "gut_fixture").accepted)
	writer.fail_writes = true
	assert_false(report.export_with(writer, "gut_failure").accepted)


func test_guidance_reports_public_prompt_progress_without_choices() -> void:
	var coordinator := _coordinator()
	assert_true(coordinator.advance_player_stage().waiting_for_players)
	var text: String = GuidedSessionHelp.guidance_for_state(
		coordinator.public_state(), coordinator.seat_manager.get_seats()
	)
	assert_true("Prompt progress 0/1" in text)
	assert_false("force" in text)
	assert_false("listen" in text)


func _coordinator() -> VerticalSliceCoordinator:
	var coordinator := VerticalSliceCoordinator.new()
	for index: int in 3:
		coordinator.seat_manager.join_device(index, "gut-pad-%d" % index, "Fixture Pad")
	coordinator.enter_lobby()
	coordinator.confirm_roster()
	coordinator.initialize_session(coordinator.MANIFEST_PATH, 4706)
	coordinator.begin_tale()
	return coordinator
