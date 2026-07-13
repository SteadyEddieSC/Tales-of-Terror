extends SceneTree

const SEEDS: Array[int] = [1, 7, 42, 4706, 8080]

var _failures: int = 0
var _sequence_count: int = 0

func _initialize() -> void:
	for seed: int in SEEDS:
		for seat_count: int in range(1, 9):
			_run_cooperative(seed, seat_count)
			_run_afterlife(seed, seat_count)
		for seat_count: int in range(3, 9):
			_run_hidden(seed, seat_count)
			_run_outbreak(seed, seat_count)
		for seat_count: int in [2, 4, 8]:
			_run_hunted(seed, seat_count)
	_run_mixed_outcome()
	_run_invalid_and_fallbacks()
	if _failures == 0:
		print("Social simulation passed: %d deterministic 1–8 player sequences" % _sequence_count)
	quit(_failures)

func _run_cooperative(seed: int, seat_count: int) -> void:
	var seats: Array[int] = _seats(seat_count)
	var a := RoleSession.new(LanternHouseSocialContent.new(), "cooperative", seed, seats)
	var b := RoleSession.new(LanternHouseSocialContent.new(), "cooperative", seed, seats)
	_expect(a.to_snapshot() == b.to_snapshot(), "replays cooperative assignment")
	_expect(a.rng.counter == 0 and a.seat_with_tag("secret") == 0, "keeps 1–8 cooperative assignment fixed and secret-free")
	for seat: int in seats:
		_expect(not a.seat_states[seat].objective_refs.is_empty() and not a.legal_actions(seat).is_empty(), "gives every cooperative seat an objective and action")
	_expect(a.privacy_report().passed, "keeps cooperative views recursively safe")
	var board := BoardState.new(LanternHouseBoardDefinition.new())
	var rules := RulesSession.new(LanternHouseRulesContent.new(), board, seed, seats)
	_expect(DirectorTelemetry.validate(DirectorTelemetry.build(rules, board, a)).is_empty(), "keeps 1–8 cooperative Director telemetry valid")
	_sequence_count += 1

func _run_hidden(seed: int, seat_count: int) -> void:
	var seats: Array[int] = _seats(seat_count)
	var board := BoardState.new(LanternHouseBoardDefinition.new())
	var rules := RulesSession.new(LanternHouseRulesContent.new(), board, seed, seats)
	var director := DirectorRuntime.new(LanternHouseDirectorContent.new(), "standard", seed, rules.content, board.definition)
	var rules_rng: Dictionary = rules.rng.to_snapshot()
	var director_rng: Dictionary = director.rng.to_snapshot()
	var a := RoleSession.new(LanternHouseSocialContent.new(), "hidden_betrayer", seed, seats)
	var b := RoleSession.new(LanternHouseSocialContent.new(), "hidden_betrayer", seed, seats)
	var secret_seat: int = a.seat_with_tag("secret")
	_expect(secret_seat > 0 and secret_seat == b.seat_with_tag("secret"), "assigns exactly one reproducible hidden opposition seat")
	_expect(rules.rng.to_snapshot() == rules_rng and director.rng.to_snapshot() == director_rng, "isolates role RNG from core and Director streams")
	_expect(a.privacy_report().passed and not a.content.role_by_id(a.seat_states[secret_seat].form_id).id in JSON.stringify(a.public_view()), "keeps hidden assignment, history, host, and Director surfaces safe")
	var private_before: Dictionary = a.seat_private_view(secret_seat).private
	a.set_seat_connected(secret_seat, false)
	a.set_seat_connected(secret_seat, true)
	_expect(a.seat_private_view(secret_seat).private == private_before and a.seat_with_tag("secret") == secret_seat, "retains stable-seat secret ownership through reconnect")
	var public_before: String = JSON.stringify(a.public_view())
	var telemetry_a: Dictionary = DirectorTelemetry.build(rules, board, a)
	var telemetry_b: Dictionary = DirectorTelemetry.build(rules, board, b)
	_expect(DirectorTelemetry.validate(telemetry_a).is_empty() and DirectorTelemetry.validate(telemetry_b).is_empty(), "keeps hidden social telemetry in the strict Director domain")
	_expect(telemetry_a.social_signals == telemetry_b.social_signals, "keeps Director blind to hidden seat selection")
	a.request_transition_by_trigger(secret_seat, "reveal", rules, board)
	_expect(public_before != JSON.stringify(a.public_view()) and a.seat_states[secret_seat].revealed, "replays an audited generic public reveal")
	_expect(DirectorTelemetry.validate(DirectorTelemetry.build(rules, board, a)).is_empty(), "keeps revealed Betrayer telemetry valid")
	_sequence_count += 1

func _run_hunted(seed: int, seat_count: int) -> void:
	var seats: Array[int] = _seats(seat_count)
	var board := BoardState.new(LanternHouseBoardDefinition.new())
	var rules := RulesSession.new(LanternHouseRulesContent.new(), board, seed, seats)
	var session := RoleSession.new(LanternHouseSocialContent.new(), "hunted", seed, seats)
	var role_rng: Dictionary = session.rng.to_snapshot()
	var transition: Dictionary = session.request_transition_by_trigger(seats[-1], "transform", rules, board)
	_expect(transition.accepted and session.role_tags_for_seat(seats[-1]).has("horror"), "transforms one selected seat into the Horror")
	_expect(session.perform_action_by_tag(seats[-1], "pressure", [], rules, board).accepted, "gives transformed Horror a legal bounded action")
	_expect(session.rng.to_snapshot() == role_rng, "keeps deterministic transitions and actions from consuming assignment RNG")
	_expect(DirectorTelemetry.validate(DirectorTelemetry.build(rules, board, session)).is_empty(), "keeps transformed Horror telemetry valid")
	_sequence_count += 1

func _run_outbreak(seed: int, seat_count: int) -> void:
	var seats: Array[int] = _seats(seat_count)
	var board := BoardState.new(LanternHouseBoardDefinition.new())
	var rules := RulesSession.new(LanternHouseRulesContent.new(), board, seed, seats)
	var a := RoleSession.new(LanternHouseSocialContent.new(), "outbreak", seed, seats)
	var b := RoleSession.new(LanternHouseSocialContent.new(), "outbreak", seed, seats)
	var actor: int = a.seat_with_tag("changed")
	var target: int = a.seat_with_tag("living")
	var role_rng: Dictionary = a.rng.to_snapshot()
	_expect(actor == b.seat_with_tag("changed") and actor > 0 and target > 0, "replays randomized Changed origin assignment")
	var spread: Dictionary = a.perform_action_by_tag(actor, "spread", [target], rules, board)
	_expect(spread.accepted and a.role_tags_for_seat(target).has("changed"), "performs one bounded Changed spread")
	var stable: Dictionary = a.to_snapshot()
	var next_target: int = a.seat_with_tag("living")
	_expect(next_target == 0 or not a.perform_action_by_tag(actor, "spread", [next_target], rules, board).accepted, "prevents unbounded Changed spread")
	_expect(a.to_snapshot() == stable and a.rng.to_snapshot() == role_rng, "rejects repeated spread atomically without RNG drift")
	_expect(DirectorTelemetry.validate(DirectorTelemetry.build(rules, board, a)).is_empty(), "keeps Changed spread telemetry valid")
	_sequence_count += 1

func _run_afterlife(seed: int, seat_count: int) -> void:
	var seats: Array[int] = _seats(seat_count)
	var board := BoardState.new(LanternHouseBoardDefinition.new())
	var rules := RulesSession.new(LanternHouseRulesContent.new(), board, seed, seats)
	var session := RoleSession.new(LanternHouseSocialContent.new(), "cooperative", seed, seats)
	var transition: Dictionary = session.request_transition_by_trigger(1, "defeat", rules, board)
	_expect(transition.accepted and session.role_tags_for_seat(1).has("afterlife"), "moves defeated seat to Restless form")
	_expect(not session.legal_actions(1, rules).is_empty(), "prevents defeated seat from becoming an irrelevant spectator")
	var action: Dictionary = session.perform_action_by_tag(1, "afterlife_support", [], rules, board)
	_expect(action.accepted and board.get_space_state("lantern_hall").features.has("restless_omen"), "applies meaningful Restless board proposal")
	_expect(session.audit_history.any(func(entry: Dictionary) -> bool: return entry.type == "transition") and session.audit_history.any(func(entry: Dictionary) -> bool: return entry.type == "action"), "audits every accepted afterlife transition and action")
	_expect(DirectorTelemetry.validate(DirectorTelemetry.build(rules, board, session)).is_empty(), "keeps Restless telemetry valid")
	_sequence_count += 1

func _run_mixed_outcome() -> void:
	var board := BoardState.new(LanternHouseBoardDefinition.new())
	var rules := RulesSession.new(LanternHouseRulesContent.new(), board, 123, [1, 2, 3, 4])
	var session := RoleSession.new(LanternHouseSocialContent.new(), "mixed_fixture", 123, [1, 2, 3, 4])
	rules.apply_effect_bundle([{"type": "set_flag", "flag_id": "house_secured", "value": true}, {"type": "set_flag", "flag_id": "archive_broken", "value": true}], 0, "simulation")
	session.perform_action_by_tag(session.seat_with_tag("changed"), "spread", [session.seat_with_tag("living")], rules, board)
	session.perform_action_by_tag(session.seat_with_tag("afterlife"), "afterlife_support", [], rules, board)
	var evaluation: Dictionary = session.evaluate_outcomes(rules, board)
	var results: Array[String] = []
	for row: Dictionary in evaluation.public.seats: results.append(row.result)
	_expect(results.has("victory") and results.has("changed") and results.has("restless"), "resolves compatible faction and individual mixed outcomes")
	_expect(session.resolve_outcomes(rules, board).accepted and session.resolve_outcomes(rules, board).idempotent, "commits terminal outcome once and remains idempotent")
	_expect(DirectorTelemetry.validate(DirectorTelemetry.build(rules, board, session)).is_empty(), "keeps mixed-outcome telemetry valid")
	_sequence_count += 1

func _run_invalid_and_fallbacks() -> void:
	var fallback := RoleSession.new(LanternHouseSocialContent.new(), "hidden_betrayer", 44, [1])
	_expect(fallback.fallback_applied and fallback.mode_id == "cooperative" and fallback.privacy_report().passed, "uses explicit safe one-seat fallback")
	var fallback_board := BoardState.new(LanternHouseBoardDefinition.new())
	var fallback_rules := RulesSession.new(LanternHouseRulesContent.new(), fallback_board, 44, [1])
	_expect(DirectorTelemetry.validate(DirectorTelemetry.build(fallback_rules, fallback_board, fallback)).is_empty(), "keeps one-seat fallback telemetry valid")
	var session := RoleSession.new(LanternHouseSocialContent.new(), "outbreak", 44, [1, 2, 3, 4])
	var snapshot: Dictionary = session.to_snapshot()
	var rng_before: Dictionary = session.rng.to_snapshot()
	_expect(not session.assign_mode("unknown", [1, 2, 3, 4]).accepted and session.to_snapshot() == snapshot and session.rng.to_snapshot() == rng_before, "rejects invalid assignment atomically")
	var restored := RoleSession.new(LanternHouseSocialContent.new(), "cooperative", 1, [1])
	_expect(restored.restore_snapshot(JSON.parse_string(JSON.stringify(snapshot))).accepted, "restores JSON snapshot")
	var malformed: Dictionary = snapshot.duplicate(true)
	malformed.snapshot_version = 999
	var stable: Dictionary = restored.to_snapshot()
	_expect(not restored.restore_snapshot(malformed).accepted and restored.to_snapshot() == stable, "rejects malformed restore atomically")
	_sequence_count += 1

func _seats(count: int) -> Array[int]:
	var result: Array[int] = []
	for seat: int in range(1, count + 1): result.append(seat)
	return result

func _expect(condition: bool, description: String) -> void:
	if not condition:
		_failures += 1
		push_error("FAILED: %s" % description)
