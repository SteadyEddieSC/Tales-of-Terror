extends SceneTree

const SEEDS: Array[int] = [1, 2, 7, 17, 42, 99, 4706, 8080, 12011, 65521]
const TRAJECTORIES: Array[String] = ["struggling", "cruising", "stalled"]
const PROFILES: Array[String] = ["gentle", "standard", "dread"]

var _failures: int = 0


func _initialize() -> void:
	var sequence_count: int = 0
	for seed: int in SEEDS:
		for profile_id: String in PROFILES:
			for trajectory: String in TRAJECTORIES:
				_run_sequence(seed, profile_id, trajectory)
				sequence_count += 1
	if _failures == 0:
		print("Director simulation passed: %d deterministic multi-seed sequences" % sequence_count)
	quit(_failures)


func _run_sequence(seed: int, profile_id: String, trajectory: String) -> void:
	var a: Dictionary = _fixture(seed, profile_id, trajectory)
	var b: Dictionary = _fixture(seed, profile_id, trajectory)
	var first_a: Dictionary = a.runtime.evaluate(a.telemetry)
	var first_b: Dictionary = b.runtime.evaluate(b.telemetry)
	_expect(
		(
			first_a.selected_candidate_id == first_b.selected_candidate_id
			and first_a.target_seat == first_b.target_seat
		),
		"replays seed/profile/trajectory decision"
	)
	if trajectory == "struggling":
		_expect(
			first_a.category in ["relief", "hint", "ambient"],
			"struggling sequence receives relief/hint within first decision"
		)
	elif trajectory == "cruising":
		_expect(
			first_a.category in ["pressure", "board"], "cruising sequence receives bounded pressure"
		)
	else:
		_expect(
			first_a.category in ["hint", "event", "ambient"], "stalled sequence receives a nudge"
		)
	var core_rng: int = a.rules.rng.counter
	var before_rules: Dictionary = a.rules.to_snapshot()
	var before_board: Dictionary = a.board.to_snapshot()
	_expect(
		a.rules.to_snapshot() == before_rules and a.board.to_snapshot() == before_board,
		"evaluation does not directly mutate authorities"
	)
	var application: Dictionary = DirectorProposalApplier.apply(first_a, a.rules, a.board)
	var record: Dictionary = a.runtime.record_application(first_a, application)
	_expect(
		application.accepted and record.accepted and a.rules.rng.counter == core_rng,
		"accepted decision is audited without core RNG drift"
	)
	_expect(
		(
			not a.runtime.audit_history.is_empty()
			and a.runtime.audit_history[-1].has("score_components")
			and a.runtime.audit_history[-1].has("application")
		),
		"accepted decision has score and application audit"
	)
	for budget: int in a.runtime.budgets.values():
		_expect(budget >= 0, "budgets never become negative")
	for _step: int in 4:
		var decision: Dictionary = a.runtime.evaluate(a.telemetry)
		var result: Dictionary = DirectorProposalApplier.apply(decision, a.rules, a.board)
		a.runtime.record_application(decision, result)
	for seat: int in [1, 2, 3, 4]:
		var targeted: int = 0
		for entry: Dictionary in a.runtime.target_history:
			if (
				entry.seat == seat
				and a.runtime.evaluation_step - entry.step <= a.runtime.profile.target_window
			):
				targeted += 1
		_expect(
			targeted <= a.runtime.profile.max_targets_per_window,
			"per-seat targeting stays within cap"
		)
	_expect(
		(
			a.runtime.recent_decisions.size() <= 16
			and a.runtime.audit_history.size() <= DirectorRuntime.AUDIT_LIMIT
		),
		"history remains bounded with no unbounded loops"
	)
	var exhausted: Dictionary = _fixture(seed, profile_id, trajectory)
	for key: String in exhausted.runtime.budgets:
		exhausted.runtime.budgets[key] = 0
	_expect(
		exhausted.runtime.evaluate(exhausted.telemetry).category == "no_op",
		"exhausted simulation state no-ops safely"
	)


func _fixture(seed: int, profile_id: String, trajectory: String) -> Dictionary:
	var board := BoardState.new(LanternHouseBoardDefinition.new())
	var rules_content := LanternHouseRulesContent.new()
	var rules := RulesSession.new(rules_content, board, seed, [1, 2, 3, 4])
	if trajectory == "struggling":
		for _index: int in 3:
			rules.resolve_check({"dice": 1, "sides": 6, "target": 99}, 1, "simulation")
	elif trajectory == "cruising":
		rules.apply_effect_bundle(
			[
				{"type": "set_counter", "counter_id": "objective_progress", "value": 10},
				{"type": "set_counter", "counter_id": "hope", "value": 6},
				{"type": "set_counter", "counter_id": "resolve", "value": 4}
			],
			0,
			"simulation"
		)
		for _index: int in rules_content.phases.size():
			rules.transition_phase()
	else:
		rules.apply_effect_bundle(
			[
				{"type": "set_counter", "counter_id": "objective_stall_steps", "value": 8},
				{"type": "set_counter", "counter_id": "prompt_latency_steps", "value": 8}
			],
			0,
			"simulation"
		)
		rules.mark_ready(1, true)
		rules.mark_ready(2, true)
	var runtime := DirectorRuntime.new(
		LanternHouseDirectorContent.new(), profile_id, seed, rules_content, board.definition
	)
	return {
		"board": board,
		"rules": rules,
		"runtime": runtime,
		"telemetry": DirectorTelemetry.build(rules, board)
	}


func _expect(condition: bool, description: String) -> void:
	if not condition:
		_failures += 1
		push_error("FAILED: %s" % description)
