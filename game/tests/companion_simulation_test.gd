extends SceneTree

const SEEDS: Array[int] = [1, 7, 42, 4706, 8080]

var _failures: int = 0
var _sequence_count: int = 0

func _initialize() -> void:
	for seed: int in SEEDS:
		for seat_count: int in range(1, 9):
			_run_sequence(seed, seat_count)
	if _failures == 0:
		print("Companion simulation passed: %d deterministic 1–8 client sequences" % _sequence_count)
	quit(_failures)

func _run_sequence(seed: int, seat_count: int) -> void:
	var first: Dictionary = _fixture(seed, seat_count)
	var second: Dictionary = _fixture(seed, seat_count)
	_expect(first.bridge.create_room("room_sim", "GHST27").accepted and second.bridge.create_room("room_sim", "GHST27").accepted, "creates deterministic simulated rooms")
	for index: int in seat_count:
		var client_id: String = "client_%d" % (index + 1)
		first.transport.connect_client(client_id)
		second.transport.connect_client(client_id)
		first.transport.approve_client(client_id, index + 1)
		second.transport.approve_client(client_id, index + 1)
	_expect(first.bridge.public_view() == second.bridge.public_view(), "replays public view for seed/count")
	_expect(first.bridge.diagnostics() == second.bridge.diagnostics(), "replays sanitized diagnostics for seed/count")
	_expect(first.bridge.connected_client_count() == seat_count, "supports simulated client count")
	for index: int in seat_count:
		var client_id: String = "client_%d" % (index + 1)
		var private_first: Dictionary = first.bridge.seat_view_for_client(client_id)
		var private_second: Dictionary = second.bridge.seat_view_for_client(client_id)
		_expect(private_first == private_second and private_first.authorized_seat == index + 1, "replays stable-seat filtered view")
		first.transport.disconnect_client(client_id)
		_expect(first.transport.resume_client(client_id, index + 1).accepted, "reconnects only the same stable seat")
		_expect(first.bridge.seat_view_for_client(client_id).social_private == private_first.social_private, "preserves private state on reconnect")
	_expect(first.roles.privacy_report().passed, "passes recursive social privacy evaluation")
	_expect(not "capability" in JSON.stringify(first.bridge.diagnostics()).to_lower(), "keeps resume capabilities out of diagnostics")
	_sequence_count += 1

func _fixture(seed: int, seat_count: int) -> Dictionary:
	var seats := SeatManager.new()
	var seat_numbers: Array[int] = []
	for index: int in seat_count:
		seats.join_device(index, "simulation-%d" % index, "Simulation Pad")
		seat_numbers.append(index + 1)
	var board := BoardState.new(LanternHouseBoardDefinition.new())
	var rules_content := LanternHouseRulesContent.new()
	var rules := RulesSession.new(rules_content, board, seed, seat_numbers)
	var director := DirectorRuntime.new(LanternHouseDirectorContent.new(), "standard", seed, rules_content, board.definition)
	var mode_id: String = "hidden_betrayer" if seat_count >= 3 else "cooperative"
	var roles := RoleSession.new(LanternHouseSocialContent.new(), mode_id, seed, seat_numbers)
	var bridge := CompanionBridge.new(seats, board, rules, director, roles)
	return {"bridge": bridge, "transport": CompanionFakeTransport.new(bridge), "roles": roles}

func _expect(condition: bool, description: String) -> void:
	if not condition:
		_failures += 1
		push_error("FAILED: %s" % description)
