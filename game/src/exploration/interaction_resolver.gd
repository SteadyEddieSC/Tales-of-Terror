class_name InteractionResolver
extends RefCounted

const FOCUS_RADIUS: float = 86.0


static func nearest_interactable(
	pawn_position: Vector2, candidates: Array[Dictionary], radius: float = FOCUS_RADIUS
) -> String:
	var nearest_id: String = ""
	var nearest_distance: float = radius
	for candidate: Dictionary in candidates:
		if not candidate.get("enabled", true):
			continue
		var distance: float = pawn_position.distance_to(candidate.position)
		if (
			distance < nearest_distance
			or (is_equal_approx(distance, nearest_distance) and str(candidate.id) < nearest_id)
		):
			nearest_distance = distance
			nearest_id = candidate.id
	return nearest_id


static func resolve_requests(requests: Array[Dictionary]) -> Array[Dictionary]:
	var ordered: Array[Dictionary] = requests.duplicate(true)
	ordered.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			if a.interactable_id == b.interactable_id:
				return a.seat_number < b.seat_number
			return str(a.interactable_id) < str(b.interactable_id)
	)
	var winners: Array[Dictionary] = []
	var claimed: Dictionary = {}
	for request: Dictionary in ordered:
		if claimed.has(request.interactable_id):
			continue
		claimed[request.interactable_id] = true
		winners.append(request)
	return winners
