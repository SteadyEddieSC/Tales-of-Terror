class_name SharedCameraCoordinator
extends Camera2D

const POSITION_RESPONSE: float = 5.0
const ZOOM_RESPONSE: float = 4.0

var room_bounds: Rect2 = ExplorationRoom.BOUNDS
var target_position: Vector2
var target_zoom: float = 1.0
var separation_state: SharedCameraPolicy.SeparationState = SharedCameraPolicy.SeparationState.NORMAL
var reduced_motion: bool = false


func _ready() -> void:
	enabled = true
	position = room_bounds.get_center()
	target_position = position
	zoom = Vector2.ONE


func update_group(pawns: Array[PawnState], delta: float) -> void:
	var positions: Array[Vector2] = []
	for pawn: PawnState in pawns:
		positions.append(pawn.position)
	var frame: Dictionary = SharedCameraPolicy.calculate_frame(
		positions, Vector2(960, 540), room_bounds
	)
	target_position = frame.center
	target_zoom = frame.zoom
	separation_state = frame.separation
	if reduced_motion:
		position = target_position
		zoom = Vector2.ONE * target_zoom
		return
	var position_weight: float = 1.0 - exp(-POSITION_RESPONSE * delta)
	var zoom_weight: float = 1.0 - exp(-ZOOM_RESPONSE * delta)
	position = position.lerp(target_position, position_weight)
	zoom = zoom.lerp(Vector2.ONE * target_zoom, zoom_weight)
