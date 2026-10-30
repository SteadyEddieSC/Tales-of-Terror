class_name AdaptivePresentationPolicy
extends RefCounted


enum Mode { SHARED, SPLIT_2, SPLIT_4, GRID_3X3 }

const REFERENCE_VIEWPORT: Vector2 = Vector2(960.0, 540.0)
const ENTER_MIN_ZOOM: float = 0.72
const EXIT_MIN_ZOOM: float = 0.82
const ESCALATE_DWELL_SECONDS: float = 0.35
const COLLAPSE_DWELL_SECONDS: float = 0.75
const CLUSTER_SWITCH_GAIN: float = 0.12

var mode: int = Mode.SHARED
var pending_mode: int = Mode.SHARED
var pending_seconds: float = 0.0
var _clusters: Array[Dictionary] = []


func update(
	players: Array[Dictionary], viewport_size: Vector2, delta: float, grid_allowed: bool = false
) -> Dictionary:
	var normalized: Array[Dictionary] = _sort_players_by_seat(players)
	var target: int = _next_target_mode(normalized, viewport_size, grid_allowed)
	_update_mode(target, delta)
	_clusters = _stable_clusters(normalized, _cluster_count_for_mode(mode))
	var layout: Dictionary = _evaluate_mode_layout(_clusters, viewport_size, mode)
	var shared_layout: Dictionary = _evaluate_mode_layout(
		_cluster_players(normalized, 1), viewport_size, Mode.SHARED
	)
	return {
		"mode": mode,
		"mode_label": mode_label(mode),
		"pending_mode": pending_mode,
		"pending_seconds": pending_seconds,
		"clusters": _public_clusters(_clusters),
		"pane_size": layout.pane_size,
		"orientation": layout.orientation,
		"worst_required_zoom": layout.worst_required_zoom,
		"shared_required_zoom": shared_layout.worst_required_zoom,
	}


func reset() -> void:
	mode = Mode.SHARED
	pending_mode = Mode.SHARED
	pending_seconds = 0.0
	_clusters.clear()


static func mode_label(value: int) -> String:
	var labels: Array[String] = ["SHARED", "SPLIT_2", "SPLIT_4", "GRID_3X3"]
	return labels[clampi(value, Mode.SHARED, Mode.GRID_3X3)]


static func required_zoom(positions: Array[Vector2], viewport_size: Vector2) -> float:
	if positions.is_empty():
		return 1.0
	var bounds := Rect2(positions[0], Vector2.ZERO)
	for position: Vector2 in positions:
		bounds = bounds.expand(position)
	var scale := Vector2(
		viewport_size.x / REFERENCE_VIEWPORT.x, viewport_size.y / REFERENCE_VIEWPORT.y
	)
	var padding := Vector2(
		SharedCameraPolicy.FRAME_PADDING.x * scale.x,
		SharedCameraPolicy.FRAME_PADDING.y * scale.y,
	)
	var required_size: Vector2 = bounds.size + padding
	return minf(
		viewport_size.x / maxf(required_size.x, 1.0),
		viewport_size.y / maxf(required_size.y, 1.0),
	)


func _next_target_mode(
	players: Array[Dictionary], viewport_size: Vector2, grid_allowed: bool
) -> int:
	var enter_target: int = _raw_target_mode(
		players, viewport_size, ENTER_MIN_ZOOM, grid_allowed
	)
	if enter_target > mode:
		return mini(mode + 1, enter_target)
	if enter_target < mode:
		var exit_target: int = _raw_target_mode(
			players, viewport_size, EXIT_MIN_ZOOM, grid_allowed
		)
		if exit_target < mode:
			return mode - 1
	return mode


func _raw_target_mode(
	players: Array[Dictionary], viewport_size: Vector2, threshold: float, grid_allowed: bool
) -> int:
	if players.is_empty():
		return Mode.SHARED
	var shared: Dictionary = _evaluate_mode_layout(
		_cluster_players(players, 1), viewport_size, Mode.SHARED
	)
	if shared.worst_required_zoom >= threshold:
		return Mode.SHARED
	var split_two: Dictionary = _evaluate_mode_layout(
		_cluster_players(players, mini(2, players.size())), viewport_size, Mode.SPLIT_2
	)
	if split_two.worst_required_zoom >= threshold:
		return Mode.SPLIT_2
	var split_four: Dictionary = _evaluate_mode_layout(
		_cluster_players(players, mini(4, players.size())), viewport_size, Mode.SPLIT_4
	)
	if split_four.worst_required_zoom >= threshold or not grid_allowed:
		return Mode.SPLIT_4
	return Mode.GRID_3X3


func _update_mode(target: int, delta: float) -> void:
	if target == mode:
		pending_mode = mode
		pending_seconds = 0.0
		return
	if pending_mode != target:
		pending_mode = target
		pending_seconds = 0.0
	pending_seconds += maxf(delta, 0.0)
	var dwell: float = (
		ESCALATE_DWELL_SECONDS if target > mode else COLLAPSE_DWELL_SECONDS
	)
	if pending_seconds < dwell:
		return
	mode = target
	pending_mode = mode
	pending_seconds = 0.0
	_clusters.clear()


func _cluster_count_for_mode(value: int) -> int:
	match value:
		Mode.SPLIT_2:
			return 2
		Mode.SPLIT_4:
			return 4
		Mode.GRID_3X3:
			return 8
		_:
			return 1


func _stable_clusters(players: Array[Dictionary], requested_count: int) -> Array[Dictionary]:
	if players.is_empty():
		return []
	var count: int = mini(requested_count, players.size())
	var candidate: Array[Dictionary] = _cluster_players(players, count)
	var result: Array[Dictionary] = candidate
	if _clusters.size() == count:
		var previous: Array[Dictionary] = _rebuild_previous_clusters(_clusters, players)
		if (
			previous.size() == count
			and _partition_key(previous) != _partition_key(candidate)
		):
			var previous_score: float = _partition_score(previous)
			var candidate_score: float = _partition_score(candidate)
			if (
				previous_score > 0.0
				and candidate_score >= previous_score * (1.0 - CLUSTER_SWITCH_GAIN)
			):
				result = previous
	return result


func _cluster_players(players: Array[Dictionary], requested_count: int) -> Array[Dictionary]:
	if players.is_empty():
		return []
	var clusters: Array[Dictionary] = []
	for player: Dictionary in _sort_players_by_seat(players):
		var members: Array[Dictionary] = [player]
		clusters.append(_cluster_from_members(members))
	var count: int = clampi(requested_count, 1, clusters.size())
	while clusters.size() > count:
		var best_first: int = 0
		var best_second: int = 1
		var best_distance: float = INF
		var best_key: String = ""
		for first: int in clusters.size():
			for second: int in range(first + 1, clusters.size()):
				var distance: float = (
					(clusters[first].centroid as Vector2).distance_squared_to(
						clusters[second].centroid as Vector2
					)
				)
				var pair_key := "%s|%s" % [clusters[first].key, clusters[second].key]
				if (
					distance < best_distance
					or (is_equal_approx(distance, best_distance) and pair_key < best_key)
				):
					best_first = first
					best_second = second
					best_distance = distance
					best_key = pair_key
		var merged_members: Array[Dictionary] = []
		for member: Dictionary in clusters[best_first].members:
			merged_members.append(member)
		for member: Dictionary in clusters[best_second].members:
			merged_members.append(member)
		clusters[best_first] = _cluster_from_members(merged_members)
		clusters.remove_at(best_second)
		clusters = _sort_clusters(clusters)
	return clusters


func _cluster_from_members(members: Array[Dictionary]) -> Dictionary:
	var sorted: Array[Dictionary] = _sort_players_by_seat(members)
	var center := Vector2.ZERO
	var seats: Array[int] = []
	for member: Dictionary in sorted:
		center += member.position as Vector2
		seats.append(int(member.seat_number))
	center /= float(sorted.size())
	return {
		"members": sorted,
		"seats": seats,
		"centroid": center,
		"key": _seat_key(seats),
	}


func _rebuild_previous_clusters(
	previous: Array[Dictionary], players: Array[Dictionary]
) -> Array[Dictionary]:
	var by_seat: Dictionary = {}
	for player: Dictionary in players:
		by_seat[int(player.seat_number)] = player
	var rebuilt: Array[Dictionary] = []
	var member_count: int = 0
	for cluster: Dictionary in previous:
		var members: Array[Dictionary] = []
		for seat: int in cluster.seats:
			if not by_seat.has(seat):
				return []
			members.append(by_seat[seat] as Dictionary)
			member_count += 1
		rebuilt.append(_cluster_from_members(members))
	if member_count != players.size():
		return []
	return _sort_clusters(rebuilt)


func _evaluate_mode_layout(
	clusters: Array[Dictionary], viewport_size: Vector2, value: int
) -> Dictionary:
	match value:
		Mode.SPLIT_2:
			var vertical := _evaluate_layout(
				clusters, Vector2(viewport_size.x * 0.5, viewport_size.y), "vertical"
			)
			var horizontal := _evaluate_layout(
				clusters, Vector2(viewport_size.x, viewport_size.y * 0.5), "horizontal"
			)
			return horizontal if horizontal.worst_required_zoom > vertical.worst_required_zoom else vertical
		Mode.SPLIT_4:
			return _evaluate_layout(clusters, viewport_size * 0.5, "2x2")
		Mode.GRID_3X3:
			return _evaluate_layout(clusters, viewport_size / 3.0, "3x3")
		_:
			return _evaluate_layout(clusters, viewport_size, "shared")


func _evaluate_layout(
	clusters: Array[Dictionary], pane_size: Vector2, orientation: String
) -> Dictionary:
	var worst_zoom: float = INF
	if clusters.is_empty():
		worst_zoom = 1.0
	for cluster: Dictionary in clusters:
		var positions: Array[Vector2] = []
		for member: Dictionary in cluster.members:
			positions.append(member.position as Vector2)
		worst_zoom = minf(worst_zoom, required_zoom(positions, pane_size))
	return {
		"pane_size": pane_size,
		"orientation": orientation,
		"worst_required_zoom": worst_zoom,
	}


func _partition_score(clusters: Array[Dictionary]) -> float:
	var score: float = 0.0
	for cluster: Dictionary in clusters:
		var members: Array = cluster.members
		var maximum: float = 0.0
		for first: int in members.size():
			for second: int in range(first + 1, members.size()):
				maximum = maxf(
					maximum,
					(members[first].position as Vector2).distance_squared_to(
						members[second].position as Vector2
					),
				)
		score += maximum
	return score


func _partition_key(clusters: Array[Dictionary]) -> String:
	var sorted: Array[Dictionary] = _sort_clusters(clusters)
	var value := ""
	for index: int in sorted.size():
		if index > 0:
			value += "|"
		value += str(sorted[index].key)
	return value


func _public_clusters(clusters: Array[Dictionary]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for cluster: Dictionary in clusters:
		result.append(
			{
				"seats": (cluster.seats as Array).duplicate(),
				"center": cluster.centroid,
				"key": cluster.key,
			}
		)
	return result


func _sort_players_by_seat(players: Array[Dictionary]) -> Array[Dictionary]:
	var sorted: Array[Dictionary] = []
	for player: Dictionary in players:
		sorted.append(player)
	for index: int in range(1, sorted.size()):
		var current: Dictionary = sorted[index]
		var cursor: int = index - 1
		while cursor >= 0 and int(sorted[cursor].seat_number) > int(current.seat_number):
			sorted[cursor + 1] = sorted[cursor]
			cursor -= 1
		sorted[cursor + 1] = current
	return sorted


func _sort_clusters(clusters: Array[Dictionary]) -> Array[Dictionary]:
	var sorted: Array[Dictionary] = []
	for cluster: Dictionary in clusters:
		sorted.append(cluster)
	for index: int in range(1, sorted.size()):
		var current: Dictionary = sorted[index]
		var cursor: int = index - 1
		while cursor >= 0 and str(sorted[cursor].key) > str(current.key):
			sorted[cursor + 1] = sorted[cursor]
			cursor -= 1
		sorted[cursor + 1] = current
	return sorted


static func _seat_key(seats: Array[int]) -> String:
	var value := ""
	for index: int in seats.size():
		if index > 0:
			value += "-"
		value += "%02d" % seats[index]
	return value
