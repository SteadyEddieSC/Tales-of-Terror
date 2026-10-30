extends SceneTree

const ROOM_BOUNDS := Rect2(0.0, 0.0, 1800.0, 1000.0)
const SPAWNS: Array[Vector2] = [
	Vector2(360, 420),
	Vector2(420, 420),
	Vector2(480, 420),
	Vector2(540, 420),
	Vector2(360, 480),
	Vector2(420, 480),
	Vector2(480, 480),
	Vector2(540, 480),
]

var _failures: int = 0


func _initialize() -> void:
	_test_pawn_creation_and_ownership()
	_test_movement_and_bounds()
	_test_camera_policy()
	_test_adaptive_presentation_policy()
	_test_interactions()
	_test_bottom_hud_layout()
	if _failures == 0:
		print("Exploration tests passed")
	quit(_failures)


func _test_pawn_creation_and_ownership() -> void:
	var registry := PawnRegistry.new()
	var seats: Array[Dictionary] = []
	for index: int in SeatManager.MAX_SEATS:
		seats.append(_seat(index + 1, SeatManager.SeatState.ACTIVE, index, "identity-%d" % index))
	registry.sync_seats(seats, SPAWNS)
	_expect(registry.get_pawns().size() == 8, "creates one pawn for each of eight active seats")
	for index: int in SeatManager.MAX_SEATS:
		_expect(
			registry.get_by_device(index).seat_number == index + 1,
			"maps device %d only to Seat %d" % [index, index + 1]
		)
	_expect(not registry.owns_device(99), "rejects an unassigned device")
	var retained: PawnState = registry.get_by_seat(3)
	seats[2] = _seat(3, SeatManager.SeatState.RESERVED, -99, "identity-2")
	registry.sync_seats(seats, SPAWNS)
	_expect(
		registry.get_by_seat(3) == retained and not retained.connected,
		"retains pawn while seat is reserved"
	)
	seats[2] = _seat(3, SeatManager.SeatState.ACTIVE, 12, "identity-2")
	registry.sync_seats(seats, SPAWNS)
	_expect(
		registry.get_by_seat(3) == retained and retained.device_id == 12 and retained.connected,
		"restores control to the reserved pawn after reconnect"
	)


func _test_movement_and_bounds() -> void:
	var pawn := PawnState.new(1, 0, "test", Vector2(100, 100))
	pawn.set_input(Vector2(1, 1))
	_expect(is_equal_approx(pawn.input_vector.length(), 1.0), "normalizes diagonal movement input")
	_expect(
		is_equal_approx(pawn.movement_delta(1.0).length(), PawnState.MOVE_SPEED),
		"keeps movement speed frame-rate independent"
	)
	pawn.position = Vector2(-100, 2000)
	pawn.clamp_to_bounds(ROOM_BOUNDS)
	_expect(
		(
			pawn.position.x >= PawnState.COLLISION_RADIUS
			and pawn.position.x <= ROOM_BOUNDS.end.x - PawnState.COLLISION_RADIUS
			and pawn.position.y >= PawnState.COLLISION_RADIUS
			and pawn.position.y <= ROOM_BOUNDS.end.y - PawnState.COLLISION_RADIUS
		),
		"clamps pawn center inside collision-safe world bounds"
	)


func _test_camera_policy() -> void:
	var one: Array[Vector2] = [Vector2(500, 500)]
	var two: Array[Vector2] = [Vector2(400, 500), Vector2(700, 500)]
	var four: Array[Vector2] = [
		Vector2(300, 300), Vector2(700, 300), Vector2(300, 700), Vector2(700, 700)
	]
	var eight: Array[Vector2] = [
		Vector2(250, 250),
		Vector2(500, 250),
		Vector2(750, 250),
		Vector2(1000, 250),
		Vector2(250, 700),
		Vector2(500, 700),
		Vector2(750, 700),
		Vector2(1000, 700)
	]
	var one_frame: Dictionary = SharedCameraPolicy.calculate_frame(
		one, Vector2(960, 540), ROOM_BOUNDS
	)
	var two_frame: Dictionary = SharedCameraPolicy.calculate_frame(
		two, Vector2(960, 540), ROOM_BOUNDS
	)
	var four_frame: Dictionary = SharedCameraPolicy.calculate_frame(
		four, Vector2(960, 540), ROOM_BOUNDS
	)
	var eight_frame: Dictionary = SharedCameraPolicy.calculate_frame(
		eight, Vector2(960, 540), ROOM_BOUNDS
	)
	_expect(
		(
			one_frame.zoom >= two_frame.zoom
			and two_frame.zoom >= four_frame.zoom
			and four_frame.zoom >= eight_frame.zoom
		),
		"zooms out monotonically for one, two, four, and eight pawn spans"
	)
	for frame: Dictionary in [one_frame, two_frame, four_frame, eight_frame]:
		_expect(
			frame.zoom >= SharedCameraPolicy.MIN_ZOOM and frame.zoom <= SharedCameraPolicy.MAX_ZOOM,
			"keeps camera zoom within documented limits"
		)
		_expect(
			ROOM_BOUNDS.has_point(frame.center), "keeps camera target within authored room bounds"
		)
	var extreme: Array[Vector2] = [Vector2(300, 500), Vector2(1200, 500)]
	_expect(
		SharedCameraPolicy.separation_state(extreme) == SharedCameraPolicy.SeparationState.REGROUP,
		"flags extreme separation for presentation without changing gameplay authority"
	)
	_expect(
		is_equal_approx(
			SharedCameraPolicy.movement_resistance(
				Vector2(1080, 500), Vector2.RIGHT, Vector2(750, 500)
			),
			1.0
		),
		"does not throttle outward movement in the former soft-tether range"
	)
	_expect(
		is_equal_approx(
			SharedCameraPolicy.movement_resistance(
				Vector2(1200, 500), Vector2.RIGHT, Vector2(750, 500)
			),
			1.0
		),
		"does not block outward movement past the former hard tether"
	)
	_expect(
		is_equal_approx(
			SharedCameraPolicy.movement_resistance(
				Vector2(1200, 500), Vector2.LEFT, Vector2(750, 500)
			),
			1.0
		),
		"keeps regrouping movement at full authority"
	)
	_expect(
		not SharedCameraPolicy.state_label(SharedCameraPolicy.SeparationState.REGROUP).contains(
			"BLOCKED"
		),
		"reports wide separation as presentation state rather than a movement block"
	)


func _test_adaptive_presentation_policy() -> void:
	var viewport := Vector2(960, 540)
	var compact := _presentation_players(
		[
			Vector2(380, 400),
			Vector2(440, 400),
			Vector2(500, 400),
			Vector2(560, 400),
			Vector2(380, 460),
			Vector2(440, 460),
			Vector2(500, 460),
			Vector2(560, 460),
		]
	)
	var policy := AdaptivePresentationPolicy.new()
	var snapshot: Dictionary = policy.update(compact, viewport, 1.0, true)
	_expect_mode(snapshot, AdaptivePresentationPolicy.Mode.SHARED, "keeps compact eight shared")

	var two_groups := _presentation_players(
		[
			Vector2(160, 360),
			Vector2(220, 360),
			Vector2(160, 420),
			Vector2(220, 420),
			Vector2(1500, 360),
			Vector2(1560, 360),
			Vector2(1500, 420),
			Vector2(1560, 420),
		]
	)
	policy.reset()
	snapshot = policy.update(two_groups, viewport, 0.20)
	_expect_mode(snapshot, AdaptivePresentationPolicy.Mode.SHARED, "requires split dwell")
	snapshot = policy.update(two_groups, viewport, 0.20)
	_expect_mode(snapshot, AdaptivePresentationPolicy.Mode.SPLIT_2, "uses two panes")
	_expect(
		_presentation_cluster_signature(snapshot) == "01-02-03-04|05-06-07-08",
		"clusters two distant groups by world position"
	)

	var four_groups := _presentation_players(
		[
			Vector2(200, 200),
			Vector2(260, 200),
			Vector2(1500, 200),
			Vector2(1560, 200),
			Vector2(200, 800),
			Vector2(260, 800),
			Vector2(1500, 800),
			Vector2(1560, 800),
		]
	)
	policy.reset()
	snapshot = policy.update(four_groups, viewport, 0.40)
	_expect_mode(snapshot, AdaptivePresentationPolicy.Mode.SPLIT_2, "escalates through two panes")
	snapshot = policy.update(four_groups, viewport, 0.40)
	_expect_mode(snapshot, AdaptivePresentationPolicy.Mode.SPLIT_4, "uses four panes")
	var reordered: Array[Dictionary] = [
		four_groups[7],
		four_groups[2],
		four_groups[5],
		four_groups[0],
		four_groups[6],
		four_groups[1],
		four_groups[4],
		four_groups[3],
	]
	var reordered_policy := AdaptivePresentationPolicy.new()
	reordered_policy.update(reordered, viewport, 0.40)
	var reordered_snapshot: Dictionary = reordered_policy.update(reordered, viewport, 0.40)
	_expect(
		_presentation_cluster_signature(snapshot)
		== _presentation_cluster_signature(reordered_snapshot),
		"keeps clustering deterministic when input order changes"
	)

	var independent := _presentation_players(
		[
			Vector2(0, 100),
			Vector2(600, 100),
			Vector2(1200, 100),
			Vector2(1800, 100),
			Vector2(0, 900),
			Vector2(600, 900),
			Vector2(1200, 900),
			Vector2(1800, 900),
		]
	)
	policy.reset()
	policy.update(independent, viewport, 0.40, true)
	policy.update(independent, viewport, 0.40, true)
	snapshot = policy.update(independent, viewport, 0.40, true)
	_expect_mode(snapshot, AdaptivePresentationPolicy.Mode.GRID_3X3, "permits earned 3x3")
	policy.reset()
	policy.update(independent, viewport, 0.40, false)
	policy.update(independent, viewport, 0.40, false)
	snapshot = policy.update(independent, viewport, 0.40, false)
	_expect_mode(snapshot, AdaptivePresentationPolicy.Mode.SPLIT_4, "gates 3x3 by phase")

	var hysteresis := AdaptivePresentationPolicy.new()
	var far_pair := _presentation_players([Vector2(200, 500), Vector2(1600, 500)])
	snapshot = hysteresis.update(far_pair, viewport, 0.40)
	_expect_mode(snapshot, AdaptivePresentationPolicy.Mode.SPLIT_2, "splits unreadable pair")
	var borderline_pair := _presentation_players([Vector2(400, 500), Vector2(1400, 500)])
	snapshot = hysteresis.update(borderline_pair, viewport, 1.0)
	_expect_mode(snapshot, AdaptivePresentationPolicy.Mode.SPLIT_2, "holds split at border")
	var regrouped_pair := _presentation_players([Vector2(600, 500), Vector2(1200, 500)])
	snapshot = hysteresis.update(regrouped_pair, viewport, 0.40)
	_expect_mode(snapshot, AdaptivePresentationPolicy.Mode.SPLIT_2, "requires collapse dwell")
	snapshot = hysteresis.update(regrouped_pair, viewport, 0.40)
	_expect_mode(snapshot, AdaptivePresentationPolicy.Mode.SHARED, "collapses after regroup dwell")


func _test_interactions() -> void:
	var candidates: Array[Dictionary] = [
		{"id": "door", "position": Vector2(100, 0), "enabled": true},
		{"id": "clue", "position": Vector2(40, 0), "enabled": true},
	]
	_expect(
		InteractionResolver.nearest_interactable(Vector2.ZERO, candidates) == "clue",
		"focuses the nearest available interactable"
	)
	var requests: Array[Dictionary] = [
		{"seat_number": 4, "interactable_id": "door"},
		{"seat_number": 2, "interactable_id": "door"},
		{"seat_number": 3, "interactable_id": "clue"},
	]
	var winners: Array[Dictionary] = InteractionResolver.resolve_requests(requests)
	_expect(winners.size() == 2, "resolves at most one action per interactable per physics tick")
	_expect(
		winners.any(_is_winning_door_request),
		"resolves simultaneous conflicts to the lowest seat number"
	)


func _test_bottom_hud_layout() -> void:
	_expect(
		ExplorationSandbox.HUD_CANVAS_LAYER >= 10, "keeps the HUD above pawn and board presentation"
	)
	for safe_margin: int in [0, 24, 48]:
		var top_layout: Dictionary = ExplorationSandbox.calculate_top_hud_layout(
			Vector2(960, 540), safe_margin
		)
		_expect(
			(top_layout.safe as Rect2).encloses(top_layout.title),
			"keeps the title inside the %d px safe frame" % safe_margin
		)
		_expect(
			(top_layout.safe as Rect2).encloses(top_layout.separation),
			"keeps the separation status inside the %d px safe frame" % safe_margin
		)
		var layout: Dictionary = ExplorationSandbox.calculate_bottom_hud_layout(
			Vector2(960, 540), safe_margin
		)
		var safe_rect: Rect2 = layout.safe
		var status_rect: Rect2 = layout.status
		var reset_rect: Rect2 = layout.reset
		_expect(
			safe_rect.encloses(status_rect),
			"keeps the status region inside the %d px safe frame" % safe_margin
		)
		_expect(
			safe_rect.encloses(reset_rect),
			"keeps the reset region inside the %d px safe frame" % safe_margin
		)
		_expect(
			not status_rect.intersects(reset_rect),
			"keeps status and reset regions separate at a %d px safe margin" % safe_margin
		)
		_expect(
			status_rect.size.x >= 500.0 and status_rect.size.y >= 48.0,
			"reserves a readable wrapped status region at a %d px safe margin" % safe_margin
		)
		var diagnostics_rect: Rect2 = ExplorationDiagnostics.calculate_panel_rect(
			Vector2(960, 540), safe_margin
		)
		_expect(
			safe_rect.encloses(diagnostics_rect),
			"keeps expanded diagnostics inside the %d px safe frame" % safe_margin
		)
		_expect(
			(
				not diagnostics_rect.intersects(status_rect)
				and not diagnostics_rect.intersects(reset_rect)
			),
			"keeps diagnostics separate from bottom HUD at a %d px safe margin" % safe_margin
		)


func _presentation_players(positions: Array[Vector2]) -> Array[Dictionary]:
	var players: Array[Dictionary] = []
	for index: int in positions.size():
		players.append({"seat_number": index + 1, "position": positions[index]})
	return players


func _presentation_cluster_signature(snapshot: Dictionary) -> String:
	var value := ""
	var clusters: Array = snapshot.clusters
	for index: int in clusters.size():
		if index > 0:
			value += "|"
		value += str(clusters[index].key)
	return value


func _expect_mode(snapshot: Dictionary, expected: int, description: String) -> void:
	_expect(int(snapshot.mode) == expected, description)


func _seat(number: int, state: int, device_id: int, identity: String) -> Dictionary:
	return {
		"seat_number": number,
		"state": state,
		"device_id": device_id,
		"identity": identity,
		"device_name": "Test",
		"last_action": "—"
	}


func _is_winning_door_request(request: Dictionary) -> bool:
	return request.interactable_id == "door" and request.seat_number == 2


func _expect(condition: bool, description: String) -> void:
	if not condition:
		_failures += 1
		push_error("FAILED: %s" % description)
