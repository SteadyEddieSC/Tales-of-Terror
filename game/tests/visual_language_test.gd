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
	for variation: String in ["SeatCard", "SeatCardActive", "SeatCardWarning", "SeatCardFocus"]:
		_expect(theme.has_stylebox("panel", variation), "defines %s panel primitive" % variation)
	for variation: String in ["StatusBadge", "StatusBadgeActive", "StatusBadgeWarning"]:
		_expect(theme.has_stylebox("panel", variation), "defines %s badge primitive" % variation)
	if _failures == 0:
		print("Visual language tests passed")
	quit(_failures)

func _expect(condition: bool, description: String) -> void:
	if not condition:
		_failures += 1
		push_error("FAILED: %s" % description)
