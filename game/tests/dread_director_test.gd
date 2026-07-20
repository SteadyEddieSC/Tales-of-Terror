extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	_test_content_validation()
	_test_telemetry_contract()
	_test_rng_and_determinism()
	_test_trajectories_and_scoring()
	_test_fairness_mercy_cooldowns_and_no_op()
	_test_proposal_authority_and_atomicity()
	_test_profiles_and_presentation()
	_test_snapshot_round_trip()
	_test_no_candidate_id_branching()
	if _failures == 0:
		print("Dread Director tests passed")
	quit(_failures)


func _test_content_validation() -> void:
	var content := LanternHouseDirectorContent.new()
	_expect(
		(
			content
			. validate(LanternHouseRulesContent.new(), LanternHouseBoardDefinition.new())
			. is_empty()
		),
		"accepts authored Lantern House Director content"
	)
	var duplicate := LanternHouseDirectorContent.new()
	duplicate.candidates.append(duplicate.candidates[0].duplicate(true))
	_expect(
		_contains(
			duplicate.validate(LanternHouseRulesContent.new(), LanternHouseBoardDefinition.new()),
			"duplicate director candidate"
		),
		"rejects duplicate candidate IDs"
	)
	var malformed_profile := LanternHouseDirectorContent.new()
	malformed_profile.profiles[1].pacing_curve[1].progress = 0
	_expect(
		_contains(
			malformed_profile.validate(
				LanternHouseRulesContent.new(), LanternHouseBoardDefinition.new()
			),
			"impossible pacing curve"
		),
		"rejects invalid pacing curves"
	)
	var impossible_budget := LanternHouseDirectorContent.new()
	impossible_budget.profiles[1].budgets.pressure = -1
	_expect(
		_contains(
			impossible_budget.validate(
				LanternHouseRulesContent.new(), LanternHouseBoardDefinition.new()
			),
			"impossible director budget"
		),
		"rejects negative budgets"
	)
	var bad_cooldown := LanternHouseDirectorContent.new()
	bad_cooldown.candidates[0].cooldown = -1
	_expect(
		_contains(
			bad_cooldown.validate(
				LanternHouseRulesContent.new(), LanternHouseBoardDefinition.new()
			),
			"invalid candidate limit"
		),
		"rejects negative candidate cooldowns"
	)
	var bad_condition := LanternHouseDirectorContent.new()
	bad_condition.candidates[0].conditions = [{"type": "read_camera"}]
	_expect(
		_contains(
			bad_condition.validate(
				LanternHouseRulesContent.new(), LanternHouseBoardDefinition.new()
			),
			"invalid candidate condition"
		),
		"rejects unbounded condition vocabulary"
	)
	var missing_reference := LanternHouseDirectorContent.new()
	missing_reference.candidates[5].payload.event_id = "missing_event"
	_expect(
		_contains(
			missing_reference.validate(
				LanternHouseRulesContent.new(), LanternHouseBoardDefinition.new()
			),
			"unknown candidate event reference"
		),
		"rejects unknown event references"
	)
	var no_fallback := LanternHouseDirectorContent.new()
	no_fallback.candidates = no_fallback.candidates.filter(
		func(candidate: Dictionary) -> bool: return candidate.category != "no_op"
	)
	_expect(
		_contains(
			no_fallback.validate(LanternHouseRulesContent.new(), LanternHouseBoardDefinition.new()),
			"missing legal no-op"
		),
		"requires a legal no-op fallback"
	)


func _test_telemetry_contract() -> void:
	var fixture: Dictionary = _fixture("stalled", 91)
	var telemetry: Dictionary = fixture.telemetry
	_expect(
		DirectorTelemetry.validate(telemetry).is_empty(),
		"builds a valid read-only telemetry snapshot"
	)
	_expect(
		JSON.parse_string(JSON.stringify(telemetry)) is Dictionary,
		"keeps telemetry JSON-compatible"
	)
	for metric: String in DirectorContent.VALID_METRICS:
		_expect(
			telemetry[metric] >= 0 and telemetry[metric] <= 100,
			"normalizes telemetry metric %s" % metric
		)
	var rules_before: Dictionary = fixture.rules.to_snapshot()
	var board_before: Dictionary = fixture.board.to_snapshot()
	DirectorTelemetry.build(fixture.rules, fixture.board)
	_expect(
		fixture.rules.to_snapshot() == rules_before and fixture.board.to_snapshot() == board_before,
		"derives telemetry without mutating authoritative state"
	)
	var missing: Dictionary = telemetry.duplicate(true)
	missing.erase("progress")
	_expect(
		_contains(DirectorTelemetry.validate(missing), "progress"),
		"rejects missing telemetry metrics deterministically"
	)
	_expect(
		(
			not telemetry.has("device_id")
			and not telemetry.has("identity")
			and not telemetry.has("account")
		),
		"contains no device, account, or personal identity data"
	)


func _test_rng_and_determinism() -> void:
	var a: Dictionary = _fixture("cruising", 4706)
	var b: Dictionary = _fixture("cruising", 4706)
	var core_before: int = a.rules.rng.counter
	var decision_a: Dictionary = a.runtime.evaluate(a.telemetry)
	var decision_b: Dictionary = b.runtime.evaluate(b.telemetry)
	_expect(
		(
			decision_a.selected_candidate_id == decision_b.selected_candidate_id
			and decision_a.target_seat == decision_b.target_seat
			and decision_a.score_components == decision_b.score_components
		),
		"reproduces decisions for identical inputs and Director RNG state"
	)
	_expect(
		a.rules.rng.counter == core_before,
		"keeps Director evaluation isolated from the core rules RNG"
	)
	_expect(
		(
			a.runtime.rng.initial_seed == b.runtime.rng.initial_seed
			and a.runtime.rng.initial_seed != a.rules.rng.initial_seed
		),
		"derives a stable, separate salted Director RNG stream"
	)
	var invalid: Dictionary = a.telemetry.duplicate(true)
	invalid.progress = 999
	var director_counter: int = a.runtime.rng.counter
	_expect(
		(
			not a.runtime.evaluate(invalid).get("accepted", true)
			and a.runtime.rng.counter == director_counter
		),
		"invalid evaluation consumes no Director RNG"
	)


func _test_trajectories_and_scoring() -> void:
	var struggling: Dictionary = _fixture("struggling", 100)
	var cruising: Dictionary = _fixture("cruising", 100)
	var stalled: Dictionary = _fixture("stalled", 100)
	var struggle_decision: Dictionary = struggling.runtime.evaluate(struggling.telemetry)
	var cruise_decision: Dictionary = cruising.runtime.evaluate(cruising.telemetry)
	var stalled_decision: Dictionary = stalled.runtime.evaluate(stalled.telemetry)
	_expect(
		struggle_decision.category in ["relief", "hint", "ambient"],
		"favors recovery or breathing room for a struggling group"
	)
	_expect(
		cruise_decision.category in ["pressure", "board"],
		"allows bounded pressure for a cruising group"
	)
	_expect(
		stalled_decision.category in ["hint", "event", "ambient"],
		"favors a nudge instead of raw punishment for a stalled group"
	)
	_expect(
		(
			struggle_decision.selected_candidate_id != cruise_decision.selected_candidate_id
			and cruise_decision.selected_candidate_id != stalled_decision.selected_candidate_id
		),
		"produces visibly different trajectory decisions"
	)
	for decision: Dictionary in [struggle_decision, cruise_decision, stalled_decision]:
		var sum: int = 0
		for value: int in decision.score_components.values():
			sum += value
		_expect(
			maxi(0, sum) == decision.final_score,
			"records score components that add to the final score"
		)
		_expect(not decision.candidate_evaluations.is_empty(), "audits all candidate evaluations")
		_expect(
			decision.candidate_evaluations.any(_is_ineligible_candidate),
			"records ineligible-candidate reasons"
		)


func _test_fairness_mercy_cooldowns_and_no_op() -> void:
	var struggling: Dictionary = _fixture("struggling", 22)
	var struggle_decision: Dictionary = struggling.runtime.evaluate(struggling.telemetry)
	_expect(
		struggle_decision.mercy_active and struggle_decision.category != "pressure",
		"suppresses pressure while mercy conditions are active"
	)
	var cruising: Dictionary = _fixture("cruising", 33)
	cruising.rules.set_seat_connected(1, false)
	cruising.telemetry = DirectorTelemetry.build(cruising.rules, cruising.board)
	var decision: Dictionary = cruising.runtime.evaluate(cruising.telemetry)
	_expect(decision.target_seat != 1, "never targets a disconnected seat negatively")
	var application: Dictionary = DirectorProposalApplier.apply(
		decision, cruising.rules, cruising.board
	)
	cruising.runtime.record_application(decision, application)
	var next: Dictionary = cruising.runtime.evaluate(cruising.telemetry)
	var prior_record: Dictionary = _evaluation(next, decision.selected_candidate_id)
	_expect(
		(
			not prior_record.eligible
			and (
				"candidate_cooldown" in prior_record.rejection_reasons
				or "tag_cooldown" in prior_record.rejection_reasons
			)
		),
		"enforces candidate or equivalent-tag cooldowns"
	)
	var severe: Dictionary = _fixture("cruising", 34)
	var severe_probe: Dictionary = severe.runtime.evaluate(severe.telemetry)
	var severe_decision: Dictionary = severe_probe.duplicate(true)
	severe_decision.selected_candidate_id = "mist_crosses_the_gallery"
	severe_decision.target_seat = 0
	severe.runtime.record_application(
		severe_decision, {"accepted": true, "authority": "BoardState", "downstream_revision": 1}
	)
	var recovery_decision: Dictionary = severe.runtime.evaluate(severe.telemetry)
	_expect(
		recovery_decision.candidate_evaluations.any(_is_recovery_window_rejection),
		"suppresses further pressure during a recovery window"
	)
	var capped: Dictionary = _fixture("cruising", 35)
	capped.runtime.profile.max_pressure_per_window = 10
	var capped_decision: Dictionary = capped.runtime.evaluate(capped.telemetry)
	_expect(
		capped_decision.candidate_evaluations.any(_is_pressure_window_rejection),
		"enforces the rolling stacked-pressure cap"
	)
	var off: Dictionary = _fixture("cruising", 44, "off")
	var off_decision: Dictionary = off.runtime.evaluate(off.telemetry)
	_expect(
		off_decision.category == "no_op" and off_decision.no_op_reason == "profile_off",
		"off profile produces an intentional deterministic no-op"
	)
	var exhausted: Dictionary = _fixture("cruising", 55)
	for key: String in exhausted.runtime.budgets:
		exhausted.runtime.budgets[key] = 0
	var exhausted_decision: Dictionary = exhausted.runtime.evaluate(exhausted.telemetry)
	_expect(
		exhausted_decision.category == "no_op" and not exhausted_decision.no_op_reason.is_empty(),
		"empty legal candidate set falls back to a reasoned no-op"
	)


func _test_proposal_authority_and_atomicity() -> void:
	var fixture: Dictionary = _fixture("struggling", 67)
	var rules_before: Dictionary = fixture.rules.to_snapshot()
	var board_before: Dictionary = fixture.board.to_snapshot()
	var decision: Dictionary = fixture.runtime.evaluate(fixture.telemetry)
	_expect(
		fixture.rules.to_snapshot() == rules_before and fixture.board.to_snapshot() == board_before,
		"Director evaluation only creates a proposal"
	)
	var core_before: int = fixture.rules.rng.counter
	var applied: Dictionary = DirectorProposalApplier.apply(decision, fixture.rules, fixture.board)
	var recorded: Dictionary = fixture.runtime.record_application(decision, applied)
	_expect(
		(
			applied.accepted
			and recorded.director_revision == 1
			and fixture.rules.rng.counter == core_before
		),
		"routes accepted rules proposals through authority without consuming core RNG"
	)
	var board_decision: Dictionary = {
		"decision_version": DirectorRuntime.DECISION_VERSION,
		"proposal":
		{
			"type": "board_mutation",
			"mutation": BoardMutation.hazard("narrow_gallery", "test_director_mist", true)
		},
		"target_seat": 0,
	}
	var board_result: Dictionary = DirectorProposalApplier.apply(
		board_decision, fixture.rules, fixture.board
	)
	_expect(
		(
			board_result.accepted
			and fixture.board.get_space_state("narrow_gallery").hazards.has("test_director_mist")
		),
		"routes board proposals through BoardState"
	)
	var stable_rules: Dictionary = fixture.rules.to_snapshot()
	var stable_board: Dictionary = fixture.board.to_snapshot()
	var invalid: Dictionary = board_decision.duplicate(true)
	invalid.proposal.mutation.space_id = "missing_space"
	var rejected: Dictionary = DirectorProposalApplier.apply(invalid, fixture.rules, fixture.board)
	_expect(
		(
			not rejected.accepted
			and fixture.rules.to_snapshot() == stable_rules
			and fixture.board.to_snapshot() == stable_board
		),
		"keeps invalid downstream applications atomic"
	)
	var presentation: Dictionary = {
		"decision_version": DirectorRuntime.DECISION_VERSION,
		"proposal":
		{
			"type": "presentation",
			"cue": "safe_omen",
			"message": "The lantern bends.",
			"speaker_key": "replaceable_host",
			"reduced_motion_safe": true
		},
		"target_seat": 0,
	}
	var presentation_result: Dictionary = DirectorProposalApplier.apply(
		presentation, fixture.rules, fixture.board
	)
	_expect(
		(
			presentation_result.accepted
			and presentation_result.authority == "Presentation"
			and fixture.rules.to_snapshot() == stable_rules
			and fixture.board.to_snapshot() == stable_board
		),
		"emits host/ambient presentation without rules or board mutation"
	)


func _test_profiles_and_presentation() -> void:
	var content := LanternHouseDirectorContent.new()
	for profile_id: String in ["off", "gentle", "standard", "dread", "fixed"]:
		_expect(
			not content.profile_by_id(profile_id).is_empty(),
			"authors %s Director profile" % profile_id
		)
	_expect(
		content.profile_by_id("gentle").reduced_volatility,
		"supports a reduced-volatility authored profile"
	)
	var fixed: Dictionary = _fixture("cruising", 70, "fixed")
	_expect(
		fixed.runtime.evaluate(fixed.telemetry).category in ["ambient", "no_op"],
		"fixed profile ignores adaptive pressure scoring"
	)
	var display: Dictionary = _fixture("stalled", 71)
	var decision: Dictionary = display.runtime.evaluate(display.telemetry)
	var application: Dictionary = DirectorProposalApplier.apply(
		decision, display.rules, display.board
	)
	var hud := DirectorHud.new()
	root.add_child(hud)
	hud.present(decision, application)
	_expect(
		hud.get_view_model().essential_content_fits and not hud.get_view_model().contains_raw_ids,
		"keeps player Director presentation friendly and bounded"
	)
	_expect(
		(
			"score" not in hud.rendered_player_text().to_lower()
			and "rng" not in hud.rendered_player_text().to_lower()
		),
		"separates raw scoring and RNG diagnostics from the player HUD"
	)
	for margin: int in [0, 24, 48]:
		var safe := Rect2(Vector2(margin, margin), Vector2(960 - margin * 2, 540 - margin * 2))
		_expect(
			safe.encloses(DirectorHud.calculate_panel_rect(Vector2(960, 540), margin)),
			"keeps Director HUD inside %d px safe frame" % margin
		)
		_expect(
			safe.encloses(DirectorDiagnostics.calculate_panel_rect(Vector2(960, 540), margin)),
			"keeps Director diagnostics inside %d px safe frame" % margin
		)
	hud.free()


func _test_snapshot_round_trip() -> void:
	var fixture: Dictionary = _fixture("cruising", 808)
	var first: Dictionary = fixture.runtime.evaluate(fixture.telemetry)
	var applied: Dictionary = DirectorProposalApplier.apply(first, fixture.rules, fixture.board)
	fixture.runtime.record_application(first, applied)
	var snapshot: Dictionary = fixture.runtime.to_snapshot()
	var json_snapshot: Variant = JSON.parse_string(JSON.stringify(snapshot))
	_expect(json_snapshot is Dictionary, "produces a versioned JSON-compatible Director snapshot")
	var restored := DirectorRuntime.new(
		LanternHouseDirectorContent.new(),
		"standard",
		1,
		LanternHouseRulesContent.new(),
		LanternHouseBoardDefinition.new()
	)
	_expect(restored.restore_snapshot(snapshot).accepted, "restores a valid Director snapshot")
	var json_restored := DirectorRuntime.new(
		LanternHouseDirectorContent.new(),
		"standard",
		2,
		LanternHouseRulesContent.new(),
		LanternHouseBoardDefinition.new()
	)
	_expect(
		json_restored.restore_snapshot(json_snapshot).accepted,
		"restores a JSON encoded/decoded Director snapshot"
	)
	var next_a: Dictionary = fixture.runtime.evaluate(fixture.telemetry)
	var next_b: Dictionary = restored.evaluate(fixture.telemetry)
	_expect(
		(
			next_a.selected_candidate_id == next_b.selected_candidate_id
			and next_a.target_seat == next_b.target_seat
			and next_a.rng_after == next_b.rng_after
		),
		"snapshot round-trip reproduces the next decision"
	)
	var stable: Dictionary = restored.to_snapshot()
	var malformed: Dictionary = snapshot.duplicate(true)
	malformed.snapshot_version = 999
	_expect(
		not restored.restore_snapshot(malformed).accepted and restored.to_snapshot() == stable,
		"rejects malformed snapshots atomically"
	)
	var unknown: Dictionary = snapshot.duplicate(true)
	unknown.candidate_cooldowns = {"invented_candidate": 8}
	_expect(
		not restored.restore_snapshot(unknown).accepted and restored.to_snapshot() == stable,
		"rejects unknown-candidate snapshots atomically"
	)
	var mismatch := DirectorRuntime.new(
		LanternHouseDirectorContent.new(),
		"gentle",
		1,
		LanternHouseRulesContent.new(),
		LanternHouseBoardDefinition.new()
	)
	_expect(
		not mismatch.restore_snapshot(snapshot).accepted, "rejects profile-mismatched snapshots"
	)


func _test_no_candidate_id_branching() -> void:
	for path: String in [
		"res://src/director/director_runtime.gd",
		"res://src/director/director_proposal_applier.gd",
		"res://src/director/director_hud.gd",
		"res://src/director/director_diagnostics.gd"
	]:
		var source: String = FileAccess.get_file_as_string(path)
		_expect(
			source.find("if candidate_id ==") == -1 and source.find("match candidate_id") == -1,
			"keeps generic Director paths free of candidate-ID branches"
		)
		for candidate: Dictionary in LanternHouseDirectorContent.new().candidates:
			_expect(
				source.find(candidate.id) == -1,
				"keeps literal candidate %s out of generic runtime/presentation" % candidate.id
			)
	var runtime_source: String = FileAccess.get_file_as_string(
		"res://src/director/director_runtime.gd"
	)
	_expect(
		(
			"apply_mutation(" not in runtime_source
			and "apply_effect_bundle(" not in runtime_source
			and "queue_event(" not in runtime_source
		),
		"keeps authoritative application calls out of Director runtime"
	)


func _fixture(trajectory: String, seed: int, profile_id: String = "standard") -> Dictionary:
	var board := BoardState.new(LanternHouseBoardDefinition.new())
	var rules_content := LanternHouseRulesContent.new()
	var rules := RulesSession.new(rules_content, board, seed, [1, 2, 3, 4])
	match trajectory:
		"struggling":
			for _index: int in 3:
				rules.resolve_check({"dice": 1, "sides": 6, "target": 99}, 1, "fixture")
		"cruising":
			rules.apply_effect_bundle(
				[
					{"type": "set_counter", "counter_id": "objective_progress", "value": 10},
					{"type": "set_counter", "counter_id": "hope", "value": 6},
					{"type": "set_counter", "counter_id": "resolve", "value": 4}
				],
				0,
				"fixture"
			)
			for _index: int in rules_content.phases.size():
				rules.transition_phase()
		"stalled":
			rules.apply_effect_bundle(
				[
					{"type": "set_counter", "counter_id": "objective_stall_steps", "value": 8},
					{"type": "set_counter", "counter_id": "prompt_latency_steps", "value": 8}
				],
				0,
				"fixture"
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


func _evaluation(decision: Dictionary, candidate_id: String) -> Dictionary:
	for evaluation: Dictionary in decision.candidate_evaluations:
		if evaluation.candidate_id == candidate_id:
			return evaluation
	return {}


func _is_ineligible_candidate(record: Dictionary) -> bool:
	return not record.eligible and not record.rejection_reasons.is_empty()


func _is_recovery_window_rejection(record: Dictionary) -> bool:
	return not record.eligible and "recovery_window" in record.rejection_reasons


func _is_pressure_window_rejection(record: Dictionary) -> bool:
	return not record.eligible and "pressure_window_cap" in record.rejection_reasons


func _contains(failures: PackedStringArray, fragment: String) -> bool:
	for failure: String in failures:
		if fragment in failure:
			return true
	return false


func _expect(condition: bool, description: String) -> void:
	if not condition:
		_failures += 1
		push_error("FAILED: %s" % description)
