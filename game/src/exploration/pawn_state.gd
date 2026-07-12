class_name PawnState
extends RefCounted

const MOVE_SPEED: float = 210.0
const COLLISION_RADIUS: float = 18.0

var seat_number: int
var device_id: int
var identity: String
var position: Vector2
var connected: bool
var input_vector: Vector2 = Vector2.ZERO
var nearby_interactable: String = "—"

func _init(p_seat_number: int, p_device_id: int, p_identity: String, spawn_position: Vector2) -> void:
	seat_number = p_seat_number
	device_id = p_device_id
	identity = p_identity
	position = spawn_position
	connected = true

func set_input(raw_input: Vector2) -> void:
	input_vector = raw_input.limit_length(1.0)

func movement_delta(delta: float, resistance: float = 1.0) -> Vector2:
	return input_vector * MOVE_SPEED * resistance * delta

func clamp_to_bounds(bounds: Rect2) -> void:
	position.x = clampf(position.x, bounds.position.x + COLLISION_RADIUS, bounds.end.x - COLLISION_RADIUS)
	position.y = clampf(position.y, bounds.position.y + COLLISION_RADIUS, bounds.end.y - COLLISION_RADIUS)
