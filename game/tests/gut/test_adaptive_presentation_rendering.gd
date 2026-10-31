extends GutTest


func test_split_two_vertical_uses_two_half_width_render_targets() -> void:
	var rects: Array[Rect2] = SharedCameraCoordinator.calculate_pane_rects(
		AdaptivePresentationPolicy.Mode.SPLIT_2, "vertical", 2
	)
	assert_eq(rects.size(), 2)
	assert_eq(rects[0], Rect2(Vector2(0, 0), Vector2(480, 540)))
	assert_eq(rects[1], Rect2(Vector2(480, 0), Vector2(480, 540)))


func test_split_two_horizontal_uses_two_half_height_render_targets() -> void:
	var rects: Array[Rect2] = SharedCameraCoordinator.calculate_pane_rects(
		AdaptivePresentationPolicy.Mode.SPLIT_2, "horizontal", 2
	)
	assert_eq(rects.size(), 2)
	assert_eq(rects[0], Rect2(Vector2(0, 0), Vector2(960, 270)))
	assert_eq(rects[1], Rect2(Vector2(0, 270), Vector2(960, 270)))


func test_split_four_uses_quadrants_at_effective_pane_resolution() -> void:
	var rects: Array[Rect2] = SharedCameraCoordinator.calculate_pane_rects(
		AdaptivePresentationPolicy.Mode.SPLIT_4, "2x2", 4
	)
	assert_eq(rects.size(), 4)
	assert_eq(rects[0], Rect2(Vector2(0, 0), Vector2(480, 270)))
	assert_eq(rects[1], Rect2(Vector2(480, 0), Vector2(480, 270)))
	assert_eq(rects[2], Rect2(Vector2(0, 270), Vector2(480, 270)))
	assert_eq(rects[3], Rect2(Vector2(480, 270), Vector2(480, 270)))


func test_layout_only_allocates_rectangles_for_active_clusters() -> void:
	var rects: Array[Rect2] = SharedCameraCoordinator.calculate_pane_rects(
		AdaptivePresentationPolicy.Mode.SPLIT_4, "2x2", 3
	)
	assert_eq(rects.size(), 3)
	assert_eq(rects[2], Rect2(Vector2(0, 270), Vector2(480, 270)))


func test_grid_3x3_uses_all_outer_cells_and_reserves_center() -> void:
	var rects: Array[Rect2] = SharedCameraCoordinator.calculate_pane_rects(
		AdaptivePresentationPolicy.Mode.GRID_3X3, "3x3", 8
	)
	var expected: Array[Rect2] = [
		Rect2(Vector2(0, 0), Vector2(320, 180)),
		Rect2(Vector2(320, 0), Vector2(320, 180)),
		Rect2(Vector2(640, 0), Vector2(320, 180)),
		Rect2(Vector2(0, 180), Vector2(320, 180)),
		Rect2(Vector2(640, 180), Vector2(320, 180)),
		Rect2(Vector2(0, 360), Vector2(320, 180)),
		Rect2(Vector2(320, 360), Vector2(320, 180)),
		Rect2(Vector2(640, 360), Vector2(320, 180)),
	]
	assert_eq(rects, expected)
	var center: Rect2 = SharedCameraCoordinator.calculate_common_pane_rect()
	assert_eq(center, Rect2(Vector2(320, 180), Vector2(320, 180)))
	assert_false(rects.has(center), "player panes never occupy the common center cell")


func test_grid_only_allocates_outer_cells_for_active_clusters() -> void:
	var rects: Array[Rect2] = SharedCameraCoordinator.calculate_pane_rects(
		AdaptivePresentationPolicy.Mode.GRID_3X3, "3x3", 5
	)
	assert_eq(rects.size(), 5)
	assert_eq(rects[4], Rect2(Vector2(640, 180), Vector2(320, 180)))


func test_common_pane_states_are_explicit_and_distinct() -> void:
	assert_eq(
		SharedCameraCoordinator.common_pane_state_label(
			SharedCameraCoordinator.CommonPaneState.MAP_BOARD
		),
		"MAP / BOARD",
	)
	assert_eq(
		SharedCameraCoordinator.common_pane_state_label(
			SharedCameraCoordinator.CommonPaneState.OBJECTIVE_PHASE
		),
		"OBJECTIVE / PHASE",
	)
	assert_eq(
		SharedCameraCoordinator.common_pane_state_label(
			SharedCameraCoordinator.CommonPaneState.TERROR_EVENT
		),
		"TERROR EVENT",
	)


func test_gated_grid_activates_eight_panes_without_mutating_pawn_authority() -> void:
	var coordinator := SharedCameraCoordinator.new()
	add_child_autofree(coordinator)
	coordinator.set_grid_allowed(true)
	var positions: Array[Vector2] = [
		Vector2(0, 100),
		Vector2(600, 100),
		Vector2(1200, 100),
		Vector2(1800, 100),
		Vector2(0, 900),
		Vector2(600, 900),
		Vector2(1200, 900),
		Vector2(1800, 900),
	]
	var pawns: Array[PawnState] = []
	for index: int in positions.size():
		var pawn := PawnState.new(index + 1, index, "grid-%d" % index, positions[index])
		if index == 0:
			pawn.nearby_interactable = "clue_pedestal"
		pawns.append(pawn)
	var before: Array[Vector2] = []
	for pawn: PawnState in pawns:
		before.append(pawn.position)
	for _step: int in 4:
		coordinator.update_group(pawns, 0.40)
	assert_eq(coordinator.presentation_mode, AdaptivePresentationPolicy.Mode.GRID_3X3)
	assert_eq(coordinator.active_pane_count(), 8)
	for index: int in pawns.size():
		assert_eq(
			pawns[index].position, before[index], "presentation does not move pawn %d" % index
		)
