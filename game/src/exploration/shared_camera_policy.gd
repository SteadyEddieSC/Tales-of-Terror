class_name SharedCameraPolicy
extends RefCounted

enum SeparationState { NORMAL, WARNING, REGROUP }

const MIN_ZOOM: float = 0.60
const MAX_ZOOM: float = 1.35
const FRAME_PADDING: Vector2 = Vector2(260.0, 190.0)
const SOFT_SEPARATION: float = 620.0
const HARD_SEPARATION: float = 820.0
const OUTWARD_RESISTANCE: float = 0.35


static func calculate_frame(
	positions: Array[Vector2], viewport_size: Vector2, room_bounds: Rect2
) -> Dictionary:
	if positions.is_empty():
		return {
			"center": room_bounds.get_center(), "zoom": 1.0, "separation": SeparationState.NORMAL
		}
	var group_bounds := Rect2(positions[0], Vector2.ZERO)
	for position: Vector2 in positions:
		group_bounds = group_bounds.expand(position)
	var required_size: Vector2 = group_bounds.size + FRAME_PADDING
	var zoom: float = minf(
		viewport_size.x / maxf(required_size.x, 1.0), viewport_size.y / maxf(required_size.y, 1.0)
	)
	zoom = clampf(zoom, MIN_ZOOM, MAX_ZOOM)
	var half_view: Vector2 = viewport_size * 0.5 / zoom
	var center: Vector2 = group_bounds.get_center()
	center.x = clampf(
		center.x, room_bounds.position.x + half_view.x, room_bounds.end.x - half_view.x
	)
	center.y = clampf(
		center.y, room_bounds.position.y + half_view.y, room_bounds.end.y - half_view.y
	)
	return {"center": center, "zoom": zoom, "separation": separation_state(positions)}


static func separation_state(positions: Array[Vector2]) -> SeparationState:
	var maximum_distance: float = _maximum_pair_distance(positions)
	if maximum_distance > HARD_SEPARATION:
		return SeparationState.REGROUP
	if maximum_distance > SOFT_SEPARATION:
		return SeparationState.WARNING
	return SeparationState.NORMAL


static func movement_resistance(
	pawn_position: Vector2, input_vector: Vector2, group_center: Vector2
) -> float:
	var from_group: Vector2 = pawn_position - group_center
	if from_group.is_zero_approx() or input_vector.is_zero_approx():
		return 1.0
	var moving_outward: bool = input_vector.normalized().dot(from_group.normalized()) > 0.0
	if not moving_outward:
		return 1.0
	if from_group.length() > HARD_SEPARATION * 0.5:
		return 0.0
	if from_group.length() > SOFT_SEPARATION * 0.5:
		return OUTWARD_RESISTANCE
	return 1.0


static func state_label(state: SeparationState) -> String:
	return ["TOGETHER", "EDGE WARNING", "REGROUP — OUTWARD MOVE BLOCKED"][state]


static func _maximum_pair_distance(positions: Array[Vector2]) -> float:
	var maximum_distance: float = 0.0
	for first: int in positions.size():
		for second: int in range(first + 1, positions.size()):
			maximum_distance = maxf(
				maximum_distance, positions[first].distance_to(positions[second])
			)
	return maximum_distance
