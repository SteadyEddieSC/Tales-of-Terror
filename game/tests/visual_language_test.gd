extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	var theme: Theme = load("res://assets/theme/terror_lab_theme.tres")
	var tokens: VisualTokens = load("res://assets/theme/visual_tokens.tres")
	_expect(theme != null, "loads reusable Theme resource")
	_expect(tokens != null, "loads visual token resource")
	_expect(theme.default_font_size >= 15, "keeps essential default text readable")
	_expect(tokens.player_colors.size() == SeatManager.MAX_SEATS, "defines one color per seat")
	_expect(tokens.player_symbols.size() == SeatManager.MAX_SEATS, "defines one symbol per seat")
	var neighboring_pairs: Array[Vector2i] = [
		Vector2i(0, 1),
		Vector2i(0, 2),
		Vector2i(1, 3),
		Vector2i(2, 3),
		Vector2i(2, 4),
		Vector2i(3, 5),
		Vector2i(4, 5),
		Vector2i(4, 6),
		Vector2i(5, 7),
		Vector2i(6, 7),
	]
	for pair: Vector2i in neighboring_pairs:
		var luminance_delta: float = absf(
			(
				tokens.player_colors[pair.x].get_luminance()
				- tokens.player_colors[pair.y].get_luminance()
			)
		)
		_expect(
			luminance_delta >= 0.12,
			"separates neighboring seats %d and %d by value" % [pair.x + 1, pair.y + 1]
		)
	for variation: String in ["SeatCard", "SeatCardActive", "SeatCardWarning", "SeatCardFocus"]:
		_expect(theme.has_stylebox("panel", variation), "defines %s panel primitive" % variation)
	for variation: String in ["StatusBadge", "StatusBadgeActive", "StatusBadgeWarning"]:
		_expect(theme.has_stylebox("panel", variation), "defines %s badge primitive" % variation)
	var safe_overlay := SafeAreaOverlay.new()
	root.add_child(safe_overlay)
	_expect(
		safe_overlay.mouse_filter == Control.MOUSE_FILTER_IGNORE,
		"keeps the safe-area frame input-transparent"
	)
	safe_overlay.queue_free()
	if _failures == 0:
		print("Visual language tests passed")
	quit(_failures)


func _expect(condition: bool, description: String) -> void:
	if not condition:
		_failures += 1
		push_error("FAILED: %s" % description)
