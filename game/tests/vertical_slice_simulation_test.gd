extends SceneTree

const SEEDS: Array[int] = [4706, 9017, 22031]

var _failures: int = 0
var _runs: int = 0


func _initialize() -> void:
	for seat_count: int in range(1, SeatManager.MAX_SEATS + 1):
		for seed: int in SEEDS:
			_run_fixture(seat_count, seed)
	if _failures == 0:
		print("Vertical slice simulation passed: %d/%d" % [_runs, 24])
	quit(_failures)


func _run_fixture(seat_count: int, seed: int) -> void:
	var first: VerticalSliceCoordinator = _new_session(seat_count, seed)
	var second: VerticalSliceCoordinator = _new_session(seat_count, seed)
	if first.lifecycle != "active_tale" or second.lifecycle != "active_tale":
		_fail("initialization", seat_count, seed)
		return
	for _index: int in 6:
		if first.lifecycle != "active_tale" or second.lifecycle != "active_tale":
			break
		var first_result: Dictionary = first.run_current_stage()
		var second_result: Dictionary = second.run_current_stage()
		if not first_result.accepted or not second_result.accepted:
			_fail("stage", seat_count, seed)
			return
	if (
		first.lifecycle != "terminal"
		or second.lifecycle != "terminal"
		or first.authority_digest() != second.authority_digest()
		or first.public_history_digest() != second.public_history_digest()
	):
		_fail("determinism", seat_count, seed)
		return
	_runs += 1
	print(
		(
			"VERTICAL seed=%d seats=%d terminal=%s digest=%s"
			% [seed, seat_count, first.rules_session.terminal_reason, first.public_history_digest()]
		)
	)


func _new_session(seat_count: int, seed: int) -> VerticalSliceCoordinator:
	var coordinator := VerticalSliceCoordinator.new()
	for index: int in seat_count:
		coordinator.seat_manager.join_device(index, "sim-%d" % index, "Simulation Pad")
	coordinator.enter_lobby()
	coordinator.confirm_roster()
	coordinator.initialize_session(seed)
	coordinator.begin_tale()
	return coordinator


func _fail(stage: String, seat_count: int, seed: int) -> void:
	_failures += 1
	push_error("FAILED: %s seats=%d seed=%d" % [stage, seat_count, seed])
