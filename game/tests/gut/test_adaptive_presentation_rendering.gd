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
