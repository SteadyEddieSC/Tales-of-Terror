extends SceneTree

var _failures: int = 0

func _initialize() -> void:
	_test_definition_validation()
	_test_initial_state_and_mapping()
	_test_occupancy_and_reconnect()
	_test_traversal_queries()
	_test_mutations_and_atomicity()
	_test_arbitration()
	_test_snapshot_restore()
	_test_visual_contract()
	if _failures == 0:
		print("Living Board tests passed")
	quit(_failures)

func _test_definition_validation() -> void:
	var definition := LanternHouseBoardDefinition.new()
	_expect(definition.validate().is_empty(), "accepts the authored Lantern House board")
	var duplicate := LanternHouseBoardDefinition.new()
	duplicate.spaces.append(duplicate.spaces[0].duplicate(true))
	_expect(_contains_failure(duplicate.validate(), "duplicate space id"), "rejects duplicate space IDs")
	var missing_endpoint := LanternHouseBoardDefinition.new()
	missing_endpoint.connectors[0]["to"] = "missing_room"
	_expect(_contains_failure(missing_endpoint.validate(), "missing endpoint"), "rejects missing connector endpoints")
	var duplicate_connector := LanternHouseBoardDefinition.new()
	duplicate_connector.connectors.append(duplicate_connector.connectors[0].duplicate(true))
	_expect(_contains_failure(duplicate_connector.validate(), "duplicate connector id"), "rejects duplicate connector IDs")
	var invalid_connector := LanternHouseBoardDefinition.new()
	invalid_connector.connectors[0]["initial_state"] = "sideways"
	_expect(_contains_failure(invalid_connector.validate(), "invalid initial state"), "rejects malformed connector state")
	var malformed_id := LanternHouseBoardDefinition.new()
	malformed_id.spaces[0]["id"] = "Bad Space"
	_expect(_contains_failure(malformed_id.validate(), "malformed id"), "rejects malformed stable IDs")
	var invalid_geometry := LanternHouseBoardDefinition.new()
	invalid_geometry.spaces[0]["areas"] = [Rect2(0, 0, 0, 40)]
	_expect(_contains_failure(invalid_geometry.validate(), "invalid geometry"), "rejects non-positive space geometry")
	var unreachable := LanternHouseBoardDefinition.new()
	unreachable.connectors = [unreachable.connectors[0]]
	_expect(_contains_failure(unreachable.validate(), "unreachable"), "rejects unreachable required spaces")

func _test_initial_state_and_mapping() -> void:
	var state := BoardState.new(LanternHouseBoardDefinition.new())
	_expect(state.revision == 0 and state.get_history().is_empty(), "constructs initial runtime state without synthetic mutations")
	_expect(not state.get_space_state("sealed_archive").revealed, "constructs authored hidden state")
	_expect(state.get_space_state("flooded_vault").hazards.has("black_water"), "constructs authored hazard state")
	_expect(state.get_connector_state("hall_gate") == "closed", "constructs authored connector state")
	_expect(state.space_for_position(Vector2(400, 400)) == "lantern_hall", "maps a pawn inside the hall")
	_expect(state.space_for_position(Vector2(1100, 500)) == "gate_passage", "maps a pawn inside the threshold")
	_expect(state.space_for_position(Vector2(1300, 350)) == "sealed_archive", "resolves overlapping regions to the smallest authored area")
	_expect(state.space_for_position(Vector2(890, 500)) == "gate_passage", "resolves a shared boundary deterministically")
	_expect(state.space_for_position(Vector2(-20, -20)) == BoardState.OUTSIDE_SPACE, "uses an explicit outside-board state")

func _test_occupancy_and_reconnect() -> void:
	var state := BoardState.new(LanternHouseBoardDefinition.new())
	var pawn := PawnState.new(1, 4, "identity", Vector2(400, 400))
	var pawns: Array[PawnState] = [pawn]
	_expect(state.sync_occupancy(pawns), "records initial pawn occupancy")
	_expect(state.space_for_seat(1) == "lantern_hall" and state.occupants_in("lantern_hall") == [1], "indexes occupancy by seat and named space")
	var revision_before_disconnect: int = state.revision
	pawn.connected = false
	_expect(not state.sync_occupancy(pawns) and state.revision == revision_before_disconnect, "preserves occupancy through disconnect reservation")
	pawn.connected = true
	pawn.device_id = 9
	_expect(not state.sync_occupancy(pawns), "reconnects a new device without duplicating occupancy")
	pawn.position = Vector2(1050, 500)
	_expect(state.sync_occupancy(pawns) and state.space_for_seat(1) == "gate_passage", "records deterministic space exit and entry")
	_expect(state.occupants_in("gate_passage") == [1] and state.occupants_in("lantern_hall").is_empty(), "prevents duplicate occupancy entries")

func _test_traversal_queries() -> void:
	var state := BoardState.new(LanternHouseBoardDefinition.new())
	_expect(state.directly_connected("lantern_hall", "gate_passage"), "finds direct authored connections")
	_expect(not state.directly_connected("lantern_hall", "gate_passage", true), "treats a closed connector as non-traversable")
	_expect(state.crossing_is_blocked("lantern_hall", "gate_passage"), "detects attempts to cross a closed connector")
	_expect(state.reachable_spaces("lantern_hall") == PackedStringArray(["lantern_hall"]), "limits reachability at closed connectors")
	_expect(state.mutation_disconnects_required(BoardMutation.connector("hall_gate", "closed")), "reports a mutation that leaves required areas disconnected")
	_expect(state.apply_mutation(BoardMutation.connector("hall_gate", "open")).accepted, "opens a connector through controlled mutation")
	_expect(state.reachable_spaces("lantern_hall").has("narrow_gallery"), "computes deterministic reachable spaces")
	_expect(state.shortest_path("lantern_hall", "narrow_gallery") == PackedStringArray(["lantern_hall", "gate_passage", "narrow_gallery"]), "computes deterministic shortest path by connector count")
	_expect(state.shortest_path("flooded_vault", "sealed_archive").is_empty(), "respects one-way and locked connector direction")

func _test_mutations_and_atomicity() -> void:
	var state := BoardState.new(LanternHouseBoardDefinition.new())
	var accepted: Array[Dictionary] = [
		BoardMutation.reveal_space("sealed_archive"),
		BoardMutation.connector("hall_gate", "open"),
		BoardMutation.connector("archive_route", "collapsed"),
		BoardMutation.hazard("narrow_gallery", "echo_mist", true),
		BoardMutation.feature("sealed_archive", "blood_key", true),
		BoardMutation.blocker("gate_passage", "fallen_beam", true),
	]
	for mutation: Dictionary in accepted:
		var before: int = state.revision
		var result: Dictionary = state.apply_mutation(mutation)
		_expect(result.accepted and state.revision == before + 1, "increments revision for accepted %s" % mutation.type)
	_expect(state.get_history().size() == accepted.size(), "records one auditable history entry per accepted mutation")
	var before_invalid: Dictionary = state.to_snapshot()
	var invalid: Dictionary = state.apply_mutation(BoardMutation.connector("missing", "open"))
	_expect(not invalid.accepted and state.to_snapshot() == before_invalid, "keeps invalid mutations atomic")
	var before_idempotent: Dictionary = state.to_snapshot()
	var idempotent: Dictionary = state.apply_mutation(BoardMutation.reveal_space("sealed_archive"))
	_expect(not idempotent.accepted and idempotent.reason == "no_change" and state.to_snapshot() == before_idempotent, "documents idempotent reapplication as an atomic no-change rejection")

func _test_arbitration() -> void:
	var state := BoardState.new(LanternHouseBoardDefinition.new())
	var results: Array[Dictionary] = state.apply_mutation_requests([
		{"seat_number": 5, "mutation": BoardMutation.connector("hall_gate", "open")},
		{"seat_number": 2, "mutation": BoardMutation.connector("hall_gate", "locked")},
		{"seat_number": 3, "mutation": BoardMutation.hazard("narrow_gallery", "bells", true)},
	])
	_expect(state.get_connector_state("hall_gate") == "locked", "resolves simultaneous target conflicts to the lowest seat")
	_expect(results.any(func(result: Dictionary) -> bool: return result.seat_number == 2 and result.accepted), "accepts the winning lowest-seat request")
	_expect(results.any(func(result: Dictionary) -> bool: return result.seat_number == 5 and result.reason.begins_with("conflict_won")), "rejects the losing conflict without mutation")
	_expect(state.get_space_state("narrow_gallery").hazards.has("bells"), "applies non-conflicting simultaneous requests independently")

func _test_snapshot_restore() -> void:
	var source := BoardState.new(LanternHouseBoardDefinition.new())
	source.apply_mutation(BoardMutation.connector("hall_gate", "open"))
	source.apply_mutation(BoardMutation.reveal_space("sealed_archive"))
	var pawn := PawnState.new(2, 7, "snapshot", Vector2(1300, 350))
	var pawns: Array[PawnState] = [pawn]
	source.sync_occupancy(pawns)
	var snapshot: Dictionary = source.to_snapshot()
	var json_round_trip: Variant = JSON.parse_string(JSON.stringify(snapshot))
	_expect(json_round_trip is Dictionary, "produces a JSON-compatible in-memory snapshot")
	var restored := BoardState.new(LanternHouseBoardDefinition.new())
	_expect(restored.restore_snapshot(snapshot).accepted and restored.to_snapshot() == snapshot, "round-trips equivalent state, revision, occupancy, and history")
	var stable: Dictionary = restored.to_snapshot()
	var unsupported: Dictionary = snapshot.duplicate(true)
	unsupported.snapshot_version = 99
	_expect(not restored.restore_snapshot(unsupported).accepted and restored.to_snapshot() == stable, "rejects unsupported snapshot versions atomically")
	var malformed: Dictionary = snapshot.duplicate(true)
	malformed.connectors = {"hall_gate": "sideways"}
	_expect(not restored.restore_snapshot(malformed).accepted and restored.to_snapshot() == stable, "rejects malformed snapshots atomically")
	var unknown_space: Dictionary = snapshot.duplicate(true)
	unknown_space.hazards["invented_room"] = ["mist"]
	_expect(not restored.restore_snapshot(unknown_space).accepted and restored.to_snapshot() == stable, "rejects snapshot state for unknown authored spaces")

func _test_visual_contract() -> void:
	_expect(BoardDebugOverlay.connector_symbol("open") != BoardDebugOverlay.connector_symbol("locked"), "uses distinct connector symbols beyond color")
	_expect(BoardDebugOverlay.connector_symbol("collapsed") != BoardDebugOverlay.connector_symbol("closed"), "represents collapsed and closed connectors with distinct text cues")
	_expect(BoardDebugOverlay.space_pattern("hidden") == "diagonal_hatch" and BoardDebugOverlay.space_pattern("hazard") == "warning_chevrons", "declares non-color space patterns for hidden and hazardous state")

func _contains_failure(failures: PackedStringArray, fragment: String) -> bool:
	for failure: String in failures:
		if fragment in failure:
			return true
	return false

func _expect(condition: bool, description: String) -> void:
	if not condition:
		_failures += 1
		push_error("FAILED: %s" % description)
