extends GutTest


func test_invalid_board_mutation_has_no_partial_effect() -> void:
	var board := BoardState.new(LanternHouseBoardDefinition.new())
	var before: Dictionary = board.to_snapshot()
	var result: Dictionary = board.apply_mutation(
		BoardMutation.connector("missing_connector", "open")
	)
	assert_false(result.get("accepted", true), "invalid mutation is rejected")
	assert_eq(board.to_snapshot(), before, "rejected mutation preserves the full board snapshot")


func test_public_board_view_omits_unrevealed_archive_identity() -> void:
	var board := BoardState.new(LanternHouseBoardDefinition.new())
	var serialized: String = JSON.stringify(board.companion_public_view()).to_lower()
	for forbidden: String in [
		"sealed_archive",
		"sealed archive",
		"sealed_shelves",
		"archive_route",
		"archive_stairs",
	]:
		assert_false(forbidden in serialized, "public companion view omits %s" % forbidden)


func test_role_projection_split_preserves_privacy_and_diagnostics_contracts() -> void:
	var session := RoleSession.new(
		LanternHouseSocialContent.new(), "hidden_betrayer", 4706, [1, 2, 3, 4]
	)
	var public_view: Dictionary = session.public_view()
	var seat_view: Dictionary = session.seat_private_view(1)
	var diagnostics: Dictionary = session.diagnostics_view(true)
	assert_eq(public_view.get("view_kind", ""), "public_shared_screen")
	assert_eq(seat_view.get("view_kind", ""), "seat_private")
	assert_eq(diagnostics.get("seat_private_previews", []).size(), 4)
	assert_eq(diagnostics.get("transition_eligibility", []).size(), 4)
	assert_true(session.privacy_report().get("passed", false), "split views remain leak-free")
