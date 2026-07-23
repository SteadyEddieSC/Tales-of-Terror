extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_authorized_open_cancel_acknowledge()
	_test_disconnect_and_reconnect_fail_closed()
	_test_deterministic_one_to_eight_seat_queue()
	_test_privacy_canaries_and_rng_invariance()
	if _failures == 0:
		print("Controlled reveal and shared-screen privacy tests passed")
	quit(_failures)


func _test_authorized_open_cancel_acknowledge() -> void:
	var session := RoleSession.new(
		LanternHouseSocialContent.new(), "hidden_betrayer", 6108, [1, 2, 3, 4]
	)
	var flow := PrivateRevealFlow.new()
	_expect(flow.begin(session, [4, 2, 1, 3]).accepted, "starts a controlled reveal queue")
	var public: Dictionary = flow.public_view(session)
	_expect(
		(
			public.phase == PrivateRevealFlow.PHASE_SHIELD
			and public.authorized_seat == 1
			and public.pending_seats == [1, 2, 3, 4]
		),
		"sorts the stable-seat reveal queue and begins on a neutral shield",
	)
	_expect(
		not flow.private_view(session, 1).accepted,
		"does not expose private content before the authorized seat opens it",
	)
	var wrong: Dictionary = flow.submit(session, 2, "confirm")
	_expect(
		not wrong.accepted and wrong.consumed and flow.phase == PrivateRevealFlow.PHASE_SHIELD,
		"consumes wrong-seat input without opening or advancing the reveal",
	)
	_expect(flow.submit(session, 1, "confirm").accepted, "authorized seat opens its reveal")
	_expect(
		flow.private_view(session, 1).accepted and not flow.private_view(session, 2).accepted,
		"private projection is available only to the currently authorized seat",
	)
	var role_rng_before: Dictionary = session.rng.to_snapshot()
	_expect(flow.submit(session, 1, "cancel").accepted, "cancel closes safely to the shield")
	_expect(
		(
			not session.seat_states[1].acknowledged
			and flow.phase == PrivateRevealFlow.PHASE_SHIELD
			and session.rng.to_snapshot() == role_rng_before
		),
		"cancel neither acknowledges nor consumes role-assignment RNG",
	)
	flow.submit(session, 1, "confirm")
	_expect(flow.submit(session, 1, "confirm").accepted, "authorized seat acknowledges once")
	_expect(
		(
			session.seat_states[1].acknowledged
			and flow.current_seat() == 2
			and flow.phase == PrivateRevealFlow.PHASE_SHIELD
		),
		"acknowledgement clears the reveal and advances through a neutral shield",
	)
	_expect(
		not flow.submit(session, 1, "confirm").accepted,
		"late duplicate input from the prior seat cannot skip the next seat",
	)


func _test_disconnect_and_reconnect_fail_closed() -> void:
	var session := RoleSession.new(LanternHouseSocialContent.new(), "cooperative", 6110, [1, 2])
	var flow := PrivateRevealFlow.new()
	flow.begin(session, [1, 2])
	flow.submit(session, 1, "confirm")
	_expect(flow.phase == PrivateRevealFlow.PHASE_REVEAL, "fixture opens the first reveal")
	session.set_seat_connected(1, false)
	flow.connection_changed(1, false)
	_expect(
		flow.phase == PrivateRevealFlow.PHASE_SHIELD and not flow.private_view(session, 1).accepted,
		"disconnect clears the private projection and restores the shield",
	)
	_expect(
		not flow.submit(session, 2, "confirm").accepted,
		"disconnect never transfers authorization to another stable seat",
	)
	session.set_seat_connected(1, true)
	flow.connection_changed(1, true)
	_expect(
		flow.phase == PrivateRevealFlow.PHASE_SHIELD and flow.current_seat() == 1,
		"same-seat reconnect resumes only from the neutral shield",
	)


func _test_deterministic_one_to_eight_seat_queue() -> void:
	for seat_count: int in range(1, 9):
		var seats: Array[int] = []
		for seat_number: int in range(1, seat_count + 1):
			seats.append(seat_number)
		var session := RoleSession.new(
			LanternHouseSocialContent.new(), "cooperative", 6200 + seat_count, seats
		)
		var flow := PrivateRevealFlow.new()
		_expect(flow.begin(session, seats).accepted, "starts %d-seat reveal queue" % seat_count)
		var guard: int = 0
		while flow.phase != PrivateRevealFlow.PHASE_COMPLETE and guard < 20:
			var authorized: int = flow.current_seat()
			flow.submit(session, authorized, "confirm")
			flow.submit(session, authorized, "confirm")
			guard += 1
		_expect(
			(
				flow.phase == PrivateRevealFlow.PHASE_COMPLETE
				and guard == seat_count
				and flow.public_view(session).pending_seats.is_empty()
			),
			"completes the deterministic %d-seat reveal queue exactly once" % seat_count,
		)


func _test_privacy_canaries_and_rng_invariance() -> void:
	var content := LanternHouseSocialContent.new()
	var session := RoleSession.new(content, "hidden_betrayer", 6308, [1, 2, 3, 4])
	var secret_seat: int = session.seat_with_tag("secret")
	var state: Dictionary = session.seat_states[secret_seat]
	var role: Dictionary = content.role_by_id(state.form_id)
	var objective: Dictionary = content.objective_by_id(state.objective_refs[0])
	var action: Dictionary = content.action_by_id(role.action_refs[0])
	for role_definition: Dictionary in content.roles:
		if role_definition.id == role.id:
			role_definition.description = "CANARY_ROLE_DESCRIPTION_61"
	for objective_definition: Dictionary in content.objectives:
		if objective_definition.id == objective.id:
			objective_definition.description = "CANARY_OBJECTIVE_DESCRIPTION_61"
	for action_definition: Dictionary in content.actions:
		if action_definition.id == action.id:
			action_definition.description = "CANARY_ACTION_DESCRIPTION_61"
	state.pending_private_prompts = ["CANARY_PRIVATE_TARGET_61"]
	var canaries: PackedStringArray = [
		"CANARY_ROLE_DESCRIPTION_61",
		"CANARY_OBJECTIVE_DESCRIPTION_61",
		"CANARY_ACTION_DESCRIPTION_61",
		"CANARY_PRIVATE_TARGET_61",
	]
	var flow := PrivateRevealFlow.new()
	var rng_before: Dictionary = session.rng.to_snapshot()
	var snapshot_before: Dictionary = session.to_snapshot()
	flow.begin(session, [1, 2, 3, 4])
	var public_json: String = JSON.stringify(flow.public_view(session))
	for canary: String in canaries:
		_expect(not canary in public_json, "keeps %s out of the television shield" % canary)
	_expect(
		session.rng.to_snapshot() == rng_before and session.to_snapshot() == snapshot_before,
		"shield setup changes no role authority or role-assignment RNG",
	)
	var board := BoardState.new(LanternHouseBoardDefinition.new())
	var rules := (
		RulesSession
		. new(
			LanternHouseRulesContent.new(),
			board,
			6308,
			[1, 2, 3, 4],
		)
	)
	var telemetry_json: String = JSON.stringify(DirectorTelemetry.build(rules, board, session))
	var report := PlaytestReport.new()
	var state_view: Dictionary = {
		"scenario_id": "lantern_house_vertical_slice",
		"scenario_version": 1,
		"lifecycle": "briefing",
		"stage": {},
		"seat_count": 4,
		"mode": session.mode_id,
		"fallback_applied": false,
		"paused": false,
		"rules": {},
		"private_reveal": flow.public_view(session),
	}
	report.begin(state_view, 6308, "2026-07-23T00:00:00Z", 0)
	var report_json: String = JSON.stringify(report.to_report())
	for canary: String in canaries:
		_expect(
			not canary in telemetry_json and not canary in report_json,
			"keeps %s out of Director telemetry and privacy-safe report" % canary,
		)
	while flow.current_seat() != secret_seat:
		var seat_number: int = flow.current_seat()
		flow.submit(session, seat_number, "confirm")
		flow.submit(session, seat_number, "confirm")
	flow.submit(session, secret_seat, "confirm")
	var private_json: String = JSON.stringify(flow.private_view(session, secret_seat))
	for canary: String in canaries:
		_expect(canary in private_json, "authorized private reveal retains %s" % canary)
	_expect(
		not flow.private_view(session, 1 if secret_seat != 1 else 2).accepted,
		"unauthorized seat cannot inspect the planted private canaries",
	)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("FAILED: %s" % message)
