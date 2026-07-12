class_name ExplorationDiagnostics
extends PanelContainer

const LAB_THEME: Theme = preload("res://assets/theme/terror_lab_theme.tres")
var _label: Label

func _ready() -> void:
	theme = LAB_THEME
	theme_type_variation = "PanelContainer"
	position = Vector2(34, 72)
	custom_minimum_size = Vector2(390, 0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var margin := MarginContainer.new()
	for side: String in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 10)
	add_child(margin)
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 13)
	margin.add_child(_label)
	visible = false

func update_snapshot(pawns: Array[PawnState], camera: SharedCameraCoordinator) -> void:
	var lines: PackedStringArray = [
		"EXPLORATION DIAGNOSTICS",
		"Camera target %s  zoom %.2f  %s" % [camera.target_position.round(), camera.target_zoom, SharedCameraPolicy.state_label(camera.separation_state)],
	]
	for pawn: PawnState in pawns:
		lines.append("Seat %s → device %d  pos %s  input %s  focus %s  %s" % [
			_roman(pawn.seat_number), pawn.device_id, pawn.position.round(), pawn.input_vector,
			pawn.nearby_interactable, "CONNECTED" if pawn.connected else "RESERVED",
		])
	_label.text = "\n".join(lines)

func toggle() -> void:
	visible = not visible

func _roman(seat_number: int) -> String:
	return ["I", "II", "III", "IV", "V", "VI", "VII", "VIII"][seat_number - 1]
