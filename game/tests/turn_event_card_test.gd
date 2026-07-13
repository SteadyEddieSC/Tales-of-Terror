extends SceneTree

var _failures: int = 0

func _initialize() -> void:
	_test_content_validation()
	_test_phase_and_seat_policy()
	_test_prompts_and_votes()
	_test_checks_and_rng()
	_test_events_and_atomic_effects()
	_test_cards_inventory_and_reconnect()
	_test_snapshots_and_history()
	_test_complete_sandbox()
	_test_no_event_id_branching()
	if _failures == 0:
		print("Turn, Event & Card Engine tests passed")
	quit(_failures)

func _test_content_validation() -> void:
	var content := LanternHouseRulesContent.new()
	_expect(content.validate(LanternHouseBoardDefinition.new()).is_empty(), "accepts the declarative Lantern House rules content")
	var duplicate := LanternHouseRulesContent.new()
	duplicate.events.append(duplicate.events[0].duplicate(true))
	_expect(_contains(duplicate.validate(LanternHouseBoardDefinition.new()), "duplicate event id"), "rejects duplicate event IDs")
	var missing := LanternHouseRulesContent.new()
	missing.events[0].follow_ups = ["missing_event"]
	_expect(_contains(missing.validate(LanternHouseBoardDefinition.new()), "invalid follow-up"), "rejects missing follow-up references")
	var unsupported := LanternHouseRulesContent.new()
	unsupported.events[0].effects = [{"type": "execute_script"}]
	_expect(_contains(unsupported.validate(LanternHouseBoardDefinition.new()), "unsupported effect"), "rejects effects outside the bounded vocabulary")
	var impossible := LanternHouseRulesContent.new()
	impossible.events[0].prompts[0].max_selections = 3
	_expect(_contains(impossible.validate(LanternHouseBoardDefinition.new()), "impossible selection rules"), "rejects impossible prompt rules")
	var recursive := LanternHouseRulesContent.new()
	recursive.events[1].follow_ups = ["threshold_whisper"]
	_expect(_contains(recursive.validate(LanternHouseBoardDefinition.new()), "recursive event loop"), "rejects obvious recursive event chains")
	for safe_margin: int in [0, 24, 48]:
		var safe_rect := Rect2(Vector2(safe_margin, safe_margin), Vector2(960 - safe_margin * 2, 540 - safe_margin * 2))
		_expect(safe_rect.encloses(RulesHud.calculate_panel_rect(Vector2(960, 540), safe_margin)), "keeps the rules HUD inside the %d px safe frame" % safe_margin)

func _test_phase_and_seat_policy() -> void:
	var session: RulesSession = _session([1, 2])
	_expect(_session([1, 2, 3, 4, 5, 6, 7, 8]).participating_seats.size() == 8, "supports all eight stable local seats")
	_expect(session.current_phase() == "round_start", "starts in the configured first phase")
	_expect(session.mark_ready(1, false, session.phase_revision).accepted, "accepts explicit readiness")
	_expect(not session.mark_ready(1).accepted, "rejects duplicate readiness")
	_expect(session.mark_ready(2, true).accepted and session.passed_seats == [2], "records explicit pass independently of readiness")
	var revision: int = session.phase_revision
	_expect(session.transition_phase(revision).accepted and session.current_phase() == "player_decision", "performs a legal configured transition")
	_expect(not session.transition_phase(revision).accepted, "rejects stale phase transitions")
	_expect(session.set_seat_connected(2, false).accepted and not session.seat_connection[2], "reserves a disconnected participating seat")
	_expect(session.set_seat_connected(2, true).accepted and session.seat_connection[2], "reconnects without transferring seat ownership")
	_expect(session.request_late_join(3).accepted and not session.participating_seats.has(3), "queues late joins until a round boundary")
	for _step: int in 4:
		session.transition_phase()
	_expect(session.round_number == 2 and session.participating_seats.has(3), "activates a late join deterministically at the next round")
	_expect(session.complete("done").accepted and not session.transition_phase().accepted, "supports terminal completion and rejects later transitions")

func _test_prompts_and_votes() -> void:
	var session: RulesSession = _session([1, 2, 3])
	var prompt: Dictionary = LanternHouseRulesContent.new().events[0].prompts[0].duplicate(true)
	prompt.scope = "all"
	_expect(session.open_prompt(prompt, [1, 2]).accepted, "opens a generic multi-seat prompt")
	var revision: int = session.pending_prompt.revision
	_expect(not session.submit_response(3, ["listen"], revision).accepted, "rejects unauthorized prompt responses")
	_expect(not session.submit_response(1, ["missing"], revision).accepted, "rejects unknown stable option IDs")
	_expect(session.submit_response(1, ["force"], revision).accepted, "accepts an eligible response")
	session.set_seat_connected(1, false)
	session.set_seat_connected(1, true)
	_expect(session.pending_prompt.responses[1] == ["force"], "retains an accepted response through disconnect and reconnect")
	_expect(not session.submit_response(1, ["listen"], revision).accepted, "rejects duplicate responses")
	_expect(not session.submit_response(2, ["listen"], revision - 1).accepted, "rejects stale prompt revisions")
	_expect(session.submit_response(2, ["listen"], revision).accepted, "accepts the remaining response")
	var resolved: Dictionary = session.resolve_prompt()
	_expect(resolved.accepted and resolved.tie and resolved.winner == "force", "resolves ties by stable option ID")
	var vote: Dictionary = LanternHouseRulesContent.new().vote_definition()
	_expect(session.open_vote(vote, [1, 2, 3]).accepted, "opens a reusable public vote")
	revision = session.pending_prompt.revision
	session.submit_response(1, ["vault"], revision)
	session.submit_response(2, ["gallery"], revision)
	session.submit_response(3, [], revision)
	var vote_result: Dictionary = session.resolve_vote()
	_expect(vote_result.accepted and vote_result.quorum_met and vote_result.winner == "gallery", "audits abstention, quorum, plurality, and deterministic tie policy")

func _test_checks_and_rng() -> void:
	var first: RulesSession = _session([1], 991)
	var second: RulesSession = _session([1], 991)
	var definition: Dictionary = LanternHouseRulesContent.new().courage_check()
	var a: Dictionary = first.resolve_check(definition, 1, "test").result
	var b: Dictionary = second.resolve_check(definition, 1, "test").result
	_expect(a == b, "reproduces seeded raw checks and outcomes")
	var counter_before: int = first.rng.counter
	_expect(not first.resolve_check({"dice": 0, "sides": 6}, 1).accepted and first.rng.counter == counter_before, "rejects malformed checks without consuming RNG")
	_expect(a.has("raw") and a.has("modifier") and a.has("outcome") and a.has("rng_before"), "records an auditable check contract")

func _test_events_and_atomic_effects() -> void:
	var board := BoardState.new(LanternHouseBoardDefinition.new())
	var session := RulesSession.new(LanternHouseRulesContent.new(), board, 17, [1, 2])
	_expect(session.queue_event("threshold_whisper").accepted and session.resolve_next_event().accepted, "queues and resolves the first declarative event")
	_expect(board.get_connector_state("hall_gate") == "open" and session.event_queue == ["gallery_council"], "applies board effects only through BoardState and preserves follow-up order")
	var before: Dictionary = board.to_snapshot()
	var invalid_bundle: Array = [{"type": "board_mutation", "mutation": BoardMutation.reveal_space("sealed_archive")}, {"type": "add_item", "seat": 1, "item_id": "missing_item"}]
	_expect(not session.apply_effect_bundle(invalid_bundle, 1, "atomic_test").accepted and board.to_snapshot() == before, "preflights a whole consequence bundle and leaves no partial board change")
	var limited: RulesSession = _session([1])
	for _index: int in RulesSession.EVENT_CHAIN_LIMIT + 1:
		limited.queue_event("vault_reckoning")
	limited.flags.council_called = true
	for _index: int in RulesSession.EVENT_CHAIN_LIMIT:
		_expect(limited.resolve_next_event().accepted, "resolves event within the documented chain limit")
	_expect(not limited.resolve_next_event().accepted and limited.last_rejection == "event_chain_limit", "halts event execution at the deterministic chain safeguard")

func _test_cards_inventory_and_reconnect() -> void:
	var first: RulesSession = _session([1, 2], 1234)
	var second: RulesSession = _session([1, 2], 1234)
	_expect(first.draw_pile == second.draw_pile, "reproduces seeded deck shuffle including stable duplicate instance IDs")
	var instance_ids: Dictionary = {}
	for instance: Dictionary in first.draw_pile:
		instance_ids[instance.instance_id] = true
	_expect(instance_ids.size() == first.draw_pile.size(), "assigns runtime identity to duplicate card definitions")
	first.apply_effect_bundle([{"type": "grant_card", "seat": 1, "card_id": "iron_resolve"}, {"type": "add_item", "seat": 1, "item_id": "brass_key"}], 1, "grant")
	var card: Dictionary = first.hands[1][-1]
	_expect(not first.play_card(2, card.instance_id).accepted, "rejects card control by another seat")
	_expect(not first.play_card(1, card.instance_id).accepted and first.hands[1].has(card), "rejects wrong-timing card play atomically")
	first.transition_phase()
	_expect(first.play_card(1, card.instance_id).accepted and first.exhausted_pile.has(card), "plays and exhausts a valid card through declarative effects")
	first.set_seat_connected(1, false)
	first.set_seat_connected(1, true)
	_expect(first.inventory[1] == ["brass_key"] and first.exhausted_pile.has(card), "preserves inventory and card zones across reconnect")

func _test_snapshots_and_history() -> void:
	var source: RulesSession = _session([1, 2], 8080)
	source.draw_card(1)
	source.request_late_join(3)
	var snapshot: Dictionary = source.to_snapshot()
	var json_snapshot: Variant = JSON.parse_string(JSON.stringify(snapshot))
	_expect(json_snapshot is Dictionary, "produces a versioned JSON-compatible in-memory snapshot")
	var restored: RulesSession = _session([1, 2], 1)
	_expect(restored.restore_snapshot(snapshot).accepted and restored.to_snapshot() == snapshot, "round-trips equivalent authoritative rules state")
	var json_restored: RulesSession = _session([1, 2], 2)
	_expect(json_restored.restore_snapshot(json_snapshot).accepted, "restores a JSON encoded/decoded rules snapshot")
	var before: Dictionary = restored.to_snapshot()
	var malformed: Dictionary = snapshot.duplicate(true)
	malformed.snapshot_version = 999
	_expect(not restored.restore_snapshot(malformed).accepted and restored.to_snapshot() == before, "rejects unsupported snapshots atomically")
	var unknown: Dictionary = snapshot.duplicate(true)
	unknown.draw_pile = snapshot.draw_pile.duplicate(true)
	unknown.draw_pile[0].definition_id = "unknown_card"
	_expect(not restored.restore_snapshot(unknown).accepted and restored.to_snapshot() == before, "rejects snapshots with unknown referenced content atomically")
	var history: Array[Dictionary] = source.history()
	for index: int in history.size():
		_expect(history[index].sequence == index + 1, "orders rules history monotonically")

func _test_complete_sandbox() -> void:
	var board := BoardState.new(LanternHouseBoardDefinition.new())
	var content := LanternHouseRulesContent.new()
	var session := RulesSession.new(content, board, 4706, [1, 2, 3, 4])
	for _phase: int in content.phases.size():
		session.transition_phase()
	_expect(session.round_number == 2, "runs the sandbox across multiple configured phases and rounds")
	session.queue_event("threshold_whisper")
	_expect(session.resolve_next_event().accepted, "runs sandbox arrival event")
	session.submit_response(1, ["listen"], session.pending_prompt.revision)
	session.resolve_prompt()
	_expect(session.resolve_next_event().accepted, "runs structurally different follow-up event")
	session.open_vote(content.vote_definition(), session.participating_seats)
	for seat: int in session.participating_seats:
		session.submit_response(seat, ["gallery" if seat < 3 else "vault"], session.pending_prompt.revision)
	_expect(session.resolve_vote().accepted, "runs sandbox public vote")
	_expect(session.resolve_check(content.courage_check(), 1, "vault_reckoning").accepted, "runs sandbox deterministic check")
	session.apply_effect_bundle([{"type": "board_mutation", "mutation": BoardMutation.hazard("narrow_gallery", "echo_mist", true)}, {"type": "grant_card", "seat": 1, "card_id": "steady_flame"}], 1, "setup")
	_expect(session.play_card(1, session.hands[1][-1].instance_id).accepted, "plays a sandbox card and applies its generic effect")
	session.queue_event("vault_reckoning")
	_expect(session.resolve_next_event().accepted and session.complete("lantern_house_secured").accepted, "reaches a visible terminal sandbox result")
	_expect(board.get_connector_state("hall_gate") == "open" and board.get_space_state("sealed_archive").revealed and session.inventory[1].has("brass_key"), "demonstrates two BoardState mutations and separate stable inventory")
	_expect(session.history().any(func(entry: Dictionary) -> bool: return entry.type == "prompt_response") and session.history().any(func(entry: Dictionary) -> bool: return entry.type == "card_played") and session.history().any(func(entry: Dictionary) -> bool: return entry.type == "vote_resolved"), "records every accepted rules action in ordered history")

func _test_no_event_id_branching() -> void:
	for path: String in ["res://src/rules/rules_session.gd", "res://src/rules/rules_hud.gd"]:
		var source: String = FileAccess.get_file_as_string(path)
		_expect(source.find("if event_id ==") == -1 and source.find("match event_id") == -1, "keeps generic engine and presentation free of event-ID-specific branches")

func _session(seats: Array[int], seed: int = 42) -> RulesSession:
	return RulesSession.new(LanternHouseRulesContent.new(), BoardState.new(LanternHouseBoardDefinition.new()), seed, seats)

func _contains(failures: PackedStringArray, fragment: String) -> bool:
	for failure: String in failures:
		if fragment in failure:
			return true
	return false

func _expect(condition: bool, description: String) -> void:
	if not condition:
		_failures += 1
		push_error("FAILED: %s" % description)
