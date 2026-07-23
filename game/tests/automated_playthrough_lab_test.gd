extends SceneTree

const SEEDS: Array[int] = [1, 17, 4706, 65521]
const STRATEGIES: Array[String] = [
	"cooperative",
	"cautious",
	"risk_seeking",
	"alternating",
	"delayed_reconnect",
]
const MAX_STEPS: int = 48
const IDLE_READS: int = 3
const FAILURE_KEYS: PackedStringArray = [
	"authority_digest",
	"interaction_id",
	"interaction_kind",
	"lifecycle",
	"operation_index",
	"public_history_digest",
	"reason",
	"seat_count",
	"seed",
	"stage_index",
	"step",
	"strategy",
]
const FORBIDDEN_PUBLIC_TERMS: PackedStringArray = [
	"private_objective",
	"provider_id",
	"package_sha256",
	"catalog_sha256",
	"source_ledger",
	"repository_path",
	"room_secret",
	"res://",
]

var _failures: int = 0
var _runs: int = 0


func _initialize() -> void:
	_test_failure_record_contract()
	for seat_count: int in range(1, SeatManager.MAX_SEATS + 1):
		for seed: int in SEEDS:
			for strategy: String in STRATEGIES:
				_run_replay_case(seat_count, seed, strategy)
	for seat_count: int in [1, 4, 8]:
		_test_rematch(seat_count)
		_test_reset(seat_count)
		_test_mid_prompt_restore(seat_count)
	if _failures == 0:
		print(
			(
				"Automated playthrough and deadlock lab passed: %d deterministic runs "
				+ "across %d replay configurations"
			)
			% [_runs, SeatManager.MAX_SEATS * SEEDS.size() * STRATEGIES.size()]
		)
	quit(_failures)


func _run_replay_case(seat_count: int, seed: int, strategy: String) -> void:
	var first: Dictionary = _run_session(seat_count, seed, strategy)
	if not first.get("accepted", false):
		_record_failure(null, seat_count, seed, strategy, first)
		return
	var second: Dictionary = _run_session(seat_count, seed, strategy)
	if not second.get("accepted", false):
		_record_failure(null, seat_count, seed, strategy, second)
		return
	var deterministic: bool = (
		first.terminal_reason == second.terminal_reason
		and first.authority_digest == second.authority_digest
		and first.public_history_digest == second.public_history_digest
		and first.steps == second.steps
	)
	if not deterministic:
		_record_failure(
			null,
			seat_count,
			seed,
			strategy,
			{
				"reason": "replay_digest_divergence",
				"step": maxi(first.get("steps", 0), second.get("steps", 0)),
				"authority_digest": first.get("authority_digest", ""),
				"public_history_digest": first.get("public_history_digest", ""),
			},
		)
		return
	_runs += 2


func _run_session(seat_count: int, seed: int, strategy: String) -> Dictionary:
	var setup: Dictionary = _new_session(seat_count, seed)
	if not setup.accepted:
		return setup
	var coordinator: VerticalSliceCoordinator = setup.coordinator
	var reveal: Dictionary = _complete_reveals(coordinator, strategy)
	if not reveal.accepted:
		return reveal
	var active: Dictionary = _drive_active_tale(coordinator, strategy, reveal.steps)
	if not active.accepted:
		return active
	if coordinator.lifecycle != "terminal":
		return _failed("terminal_not_reached", active.steps)
	return {
		"accepted": true,
		"reason": "",
		"steps": active.steps,
		"terminal_reason": coordinator.rules_session.terminal_reason,
		"authority_digest": coordinator.authority_digest(),
		"public_history_digest": coordinator.public_history_digest(),
	}


func _new_session(seat_count: int, seed: int) -> Dictionary:
	var coordinator := VerticalSliceCoordinator.new()
	for index: int in seat_count:
		var seat_index: int = coordinator.seat_manager.join_device(
			index, _identity(index + 1), "Virtual Lab Seat"
		)
		if seat_index != index:
			return _failed("stable_seat_assignment_failed", 0)
	var setup_steps: Array[Dictionary] = [
		coordinator.enter_lobby(),
		coordinator.confirm_roster(),
		coordinator.navigate_tale_library("open"),
		coordinator.initialize_session(seed),
		coordinator.begin_tale(),
	]
	for result: Dictionary in setup_steps:
		if not result.get("accepted", false):
			return _failed("session_setup_rejected:%s" % result.get("reason", "rejected"), 0)
	if coordinator.lifecycle != "active_tale" or coordinator.active_seats().size() != seat_count:
		return _failed("session_setup_state_invalid", 0)
	return {"accepted": true, "coordinator": coordinator}


func _complete_reveals(coordinator: VerticalSliceCoordinator, strategy: String) -> Dictionary:
	var flow: PrivateRevealFlow = coordinator.get("_private_reveal_flow")
	var steps: int = 0
	var reconnect_injected: bool = false
	while flow.is_blocking():
		steps += 1
		if steps > SeatManager.MAX_SEATS * 3:
			return _failed("private_reveal_step_bound_exceeded", steps)
		var seat_number: int = flow.current_seat()
		if seat_number <= 0:
			return _failed("private_reveal_missing_authorized_seat", steps)
		var privacy: Dictionary = _assert_public_privacy(coordinator, steps)
		if not privacy.accepted:
			return privacy
		var idle: Dictionary = _idle_probe(coordinator)
		if not idle.accepted:
			return _failed(idle.reason, steps)
		var wrong_seat: int = _first_other_seat(coordinator.active_seats(), seat_number)
		if wrong_seat > 0:
			var wrong_before: Dictionary = coordinator.to_snapshot()
			var wrong: Dictionary = PrivateRevealFlow.submit_for(
				coordinator, wrong_seat, "confirm"
			)
			if wrong.accepted or coordinator.to_snapshot() != wrong_before:
				return _failed("private_reveal_wrong_seat_mutated", steps)
		var opened: Dictionary = PrivateRevealFlow.submit_for(coordinator, seat_number, "confirm")
		if not opened.accepted or flow.phase != PrivateRevealFlow.PHASE_REVEAL:
			return _failed("private_reveal_open_failed", steps)
		if strategy == "delayed_reconnect" and not reconnect_injected:
			var reconnect: Dictionary = _disconnect_reconnect(coordinator, flow, seat_number)
			if not reconnect.accepted:
				return _failed(reconnect.reason, steps)
			reconnect_injected = true
			opened = PrivateRevealFlow.submit_for(coordinator, seat_number, "confirm")
			if not opened.accepted or flow.phase != PrivateRevealFlow.PHASE_REVEAL:
				return _failed("private_reveal_reopen_failed", steps)
		var private_view: Dictionary = PrivateRevealFlow.private_view_for(coordinator, seat_number)
		if not private_view.get("accepted", false):
			return _failed("authorized_private_projection_rejected", steps)
		var acknowledged: Dictionary = PrivateRevealFlow.submit_for(
			coordinator, seat_number, "confirm"
		)
		if not acknowledged.accepted:
			return _failed("private_reveal_acknowledgement_failed", steps)
		var duplicate_before: Dictionary = coordinator.to_snapshot()
		var duplicate: Dictionary = PrivateRevealFlow.submit_for(
			coordinator, seat_number, "confirm"
		)
		if duplicate.accepted or coordinator.to_snapshot() != duplicate_before:
			return _failed("private_reveal_duplicate_mutated", steps)
	if flow.phase != PrivateRevealFlow.PHASE_COMPLETE:
		return _failed("private_reveal_queue_incomplete", steps)
	return {"accepted": true, "steps": steps}


func _disconnect_reconnect(
	coordinator: VerticalSliceCoordinator, flow: PrivateRevealFlow, seat_number: int
) -> Dictionary:
	var device_id: int = seat_number - 1
	var seat_index: int = coordinator.seat_manager.disconnect_device(device_id)
	if seat_index != seat_number - 1:
		return {"accepted": false, "reason": "disconnect_lost_stable_seat"}
	if not coordinator.role_session.set_seat_connected(seat_number, false).accepted:
		return {"accepted": false, "reason": "role_disconnect_rejected"}
	PrivateRevealFlow.connection_changed_for(coordinator, seat_number, false)
	if flow.phase != PrivateRevealFlow.PHASE_SHIELD or flow.current_seat() != seat_number:
		return {"accepted": false, "reason": "disconnect_did_not_fail_closed"}
	var disconnected_before: Dictionary = coordinator.to_snapshot()
	var blocked: Dictionary = PrivateRevealFlow.submit_for(coordinator, seat_number, "confirm")
	if blocked.accepted or coordinator.to_snapshot() != disconnected_before:
		return {"accepted": false, "reason": "disconnected_reveal_input_mutated"}
	var restored_index: int = coordinator.seat_manager.reconnect_device(
		device_id, _identity(seat_number), "Virtual Lab Seat"
	)
	if restored_index != seat_number - 1:
		return {"accepted": false, "reason": "reconnect_transferred_stable_seat"}
	if not coordinator.role_session.set_seat_connected(seat_number, true).accepted:
		return {"accepted": false, "reason": "role_reconnect_rejected"}
	PrivateRevealFlow.connection_changed_for(coordinator, seat_number, true)
	if flow.current_seat() != seat_number or flow.phase != PrivateRevealFlow.PHASE_SHIELD:
		return {"accepted": false, "reason": "reconnect_authorization_changed"}
	return {"accepted": true, "reason": ""}


func _drive_active_tale(
	coordinator: VerticalSliceCoordinator, strategy: String, initial_steps: int
) -> Dictionary:
	var steps: int = initial_steps
	while coordinator.lifecycle == "active_tale":
		steps += 1
		if steps > MAX_STEPS:
			return _failed("active_tale_step_bound_exceeded", steps)
		var privacy: Dictionary = _assert_public_privacy(coordinator, steps)
		if not privacy.accepted:
			return privacy
		var state: Dictionary = coordinator.public_state().get("interaction", {})
		if state.is_empty():
			return _failed("active_tale_interaction_missing", steps)
		var eligible: Array[int] = _int_array(state.get("eligible_seats", []))
		if eligible.is_empty():
			return _failed("required_interaction_has_no_eligible_seat", steps)
		var idle: Dictionary = _idle_probe(coordinator)
		if not idle.accepted:
			return _failed(idle.reason, steps)
		var before: String = _progress_token(coordinator)
		var result: Dictionary = _resolve_interaction(coordinator, state, strategy, steps)
		if not result.get("accepted", false):
			return _failed(result.get("reason", "interaction_rejected"), steps)
		if coordinator.lifecycle == "active_tale" and _progress_token(coordinator) == before:
			return _failed("accepted_interaction_made_no_progress", steps)
	if coordinator.lifecycle != "terminal":
		return _failed("invalid_lifecycle_after_active_tale", steps)
	return {"accepted": true, "steps": steps}


func _resolve_interaction(
	coordinator: VerticalSliceCoordinator, state: Dictionary, strategy: String, step: int
) -> Dictionary:
	var kind: String = state.get("kind", "")
	if kind in ["choice", "vote"]:
		return _resolve_prompt(coordinator, state, strategy)
	var eligible: Array[int] = _int_array(state.get("eligible_seats", []))
	var actor: int = _actor_for(state, eligible, strategy, step)
	if actor <= 0 or not eligible.has(actor):
		return {"accepted": false, "reason": "strategy_selected_ineligible_actor"}
	var wrong_seat: int = _first_ineligible_active_seat(coordinator.active_seats(), eligible)
	if wrong_seat > 0:
		var wrong_before: Dictionary = coordinator.to_snapshot()
		var wrong: Dictionary = coordinator._submit_player_interaction(wrong_seat, "confirm")
		if wrong.accepted or coordinator.to_snapshot() != wrong_before:
			return {"accepted": false, "reason": "wrong_seat_interaction_mutated"}
	var unsupported_before: Dictionary = coordinator.to_snapshot()
	var unsupported: Dictionary = coordinator._submit_player_interaction(actor, "stale")
	if unsupported.accepted or coordinator.to_snapshot() != unsupported_before:
		return {"accepted": false, "reason": "unsupported_interaction_mutated"}
	var action: String = _action_for(state, strategy, step)
	return coordinator._submit_player_interaction(actor, action)


func _resolve_prompt(
	coordinator: VerticalSliceCoordinator, state: Dictionary, strategy: String
) -> Dictionary:
	var prompt: Dictionary = coordinator.rules_session.pending_prompt
	if prompt.is_empty() or prompt.get("revision", 0) <= 0:
		return {"accepted": false, "reason": "rules_prompt_missing_revision"}
	var options: Array = prompt.get("options", [])
	if options.is_empty():
		return {"accepted": false, "reason": "rules_prompt_has_no_options"}
	for seat_number: int in _int_array(prompt.get("eligible_seats", [])):
		if prompt.get("responses", {}).has(seat_number):
			continue
		var option_id: String = _option_for(options, strategy, seat_number)
		var stale_before: Dictionary = coordinator.to_snapshot()
		var stale: Dictionary = coordinator.rules_session.submit_response(
			seat_number, [option_id], prompt.revision - 1
		)
		if stale.accepted or coordinator.to_snapshot() != stale_before:
			return {"accepted": false, "reason": "stale_prompt_response_mutated"}
		var response: Dictionary = coordinator.rules_session.submit_response(
			seat_number, [option_id], prompt.revision
		)
		if not response.accepted:
			return {"accepted": false, "reason": "legal_prompt_response_rejected"}
		var duplicate_before: Dictionary = coordinator.to_snapshot()
		var duplicate: Dictionary = coordinator.rules_session.submit_response(
			seat_number, [option_id], prompt.revision
		)
		if duplicate.accepted or coordinator.to_snapshot() != duplicate_before:
			return {"accepted": false, "reason": "duplicate_prompt_response_mutated"}
	var eligible: Array[int] = _int_array(state.get("eligible_seats", []))
	var actor: int = _actor_for(state, eligible, strategy, 0)
	return coordinator._submit_player_interaction(actor, "confirm")


func _actor_for(
	state: Dictionary, eligible: Array[int], strategy: String, step: int
) -> int:
	var owner: int = state.get("owner_seat", 0)
	if owner > 0:
		return owner
	if eligible.is_empty():
		return 0
	if strategy == "risk_seeking":
		return eligible[-1]
	if strategy == "alternating":
		return eligible[step % eligible.size()]
	return eligible[0]


func _action_for(state: Dictionary, strategy: String, step: int) -> String:
	var allow_pass: bool = state.get("allow_pass", false)
	if strategy == "cautious" and allow_pass:
		return "pass"
	if strategy == "alternating" and allow_pass and step % 2 == 1:
		return "pass"
	return "confirm"


func _option_for(options: Array, strategy: String, seat_number: int) -> String:
	var index: int = 0
	if strategy == "risk_seeking":
		index = options.size() - 1
	elif strategy == "alternating":
		index = (seat_number - 1) % options.size()
	elif strategy == "cautious" and options.size() > 1:
		index = 1
	var option: Dictionary = options[index]
	return option.get("id", "")


func _idle_probe(coordinator: VerticalSliceCoordinator) -> Dictionary:
	var authority: String = coordinator.authority_digest()
	var history: String = coordinator.public_history_digest()
	var public_projection: String = JSON.stringify(TalePackage.canonicalize(coordinator.public_state()))
	for _index: int in IDLE_READS:
		if (
			coordinator.authority_digest() != authority
			or coordinator.public_history_digest() != history
			or JSON.stringify(TalePackage.canonicalize(coordinator.public_state()))
			!= public_projection
		):
			return {"accepted": false, "reason": "idle_read_mutated_state"}
	return {"accepted": true, "reason": ""}


func _assert_public_privacy(coordinator: VerticalSliceCoordinator, step: int) -> Dictionary:
	var public_text: String = JSON.stringify(coordinator.public_state()).to_lower()
	for forbidden: String in FORBIDDEN_PUBLIC_TERMS:
		if forbidden in public_text:
			return _failed("public_projection_contains_forbidden_term", step)
	return {"accepted": true}


func _progress_token(coordinator: VerticalSliceCoordinator) -> String:
	var public_state: Dictionary = coordinator.public_state()
	var interaction: Dictionary = public_state.get("interaction", {})
	return JSON.stringify(
		TalePackage.canonicalize(
			{
				"lifecycle": coordinator.lifecycle,
				"stage_index": coordinator.stage_index,
				"operation_index": coordinator.operation_index,
				"interaction_id": interaction.get("interaction_id", ""),
				"interaction_kind": interaction.get("kind", ""),
				"committed_seats": interaction.get("committed_seats", []),
				"pending_seats": interaction.get("pending_seats", []),
				"authority_digest": coordinator.authority_digest(),
				"public_history_digest": coordinator.public_history_digest(),
			}
		)
	)


func _test_rematch(seat_count: int) -> void:
	var setup: Dictionary = _new_session(seat_count, 4706)
	if not setup.accepted:
		_record_failure(null, seat_count, 4706, "rematch", setup)
		return
	var coordinator: VerticalSliceCoordinator = setup.coordinator
	var first: Dictionary = _finish_existing_session(coordinator, "cooperative")
	if not first.accepted:
		_record_failure(coordinator, seat_count, 4706, "rematch", first)
		return
	if not coordinator.review_ending().accepted or not coordinator.rematch().accepted:
		_record_failure(
			coordinator, seat_count, 4706, "rematch", _failed("rematch_transition_rejected", 0)
		)
		return
	if coordinator.lifecycle != "briefing" or not coordinator.begin_tale().accepted:
		_record_failure(
			coordinator, seat_count, 4706, "rematch", _failed("rematch_session_not_clean", 0)
		)
		return
	var second: Dictionary = _finish_existing_session(coordinator, "cooperative")
	if not second.accepted:
		_record_failure(coordinator, seat_count, 4706, "rematch", second)
		return
	if (
		first.terminal_reason != second.terminal_reason
		or first.authority_digest != second.authority_digest
		or first.public_history_digest != second.public_history_digest
	):
		_record_failure(
			coordinator, seat_count, 4706, "rematch", _failed("rematch_digest_divergence", 0)
		)
		return
	_runs += 2


func _finish_existing_session(
	coordinator: VerticalSliceCoordinator, strategy: String
) -> Dictionary:
	var reveal: Dictionary = _complete_reveals(coordinator, strategy)
	if not reveal.accepted:
		return reveal
	var active: Dictionary = _drive_active_tale(coordinator, strategy, reveal.steps)
	if not active.accepted:
		return active
	return {
		"accepted": true,
		"terminal_reason": coordinator.rules_session.terminal_reason,
		"authority_digest": coordinator.authority_digest(),
		"public_history_digest": coordinator.public_history_digest(),
	}


func _test_reset(seat_count: int) -> void:
	var setup: Dictionary = _new_session(seat_count, 17)
	if not setup.accepted:
		_record_failure(null, seat_count, 17, "reset", setup)
		return
	var coordinator: VerticalSliceCoordinator = setup.coordinator
	var reveal: Dictionary = _complete_reveals(coordinator, "cooperative")
	if not reveal.accepted:
		_record_failure(coordinator, seat_count, 17, "reset", reveal)
		return
	var first_state: Dictionary = coordinator.public_state().interaction
	var first_actor: int = _int_array(first_state.eligible_seats)[0]
	if not coordinator._submit_player_interaction(first_actor, "confirm").accepted:
		_record_failure(
			coordinator, seat_count, 17, "reset", _failed("reset_fixture_progress_failed", 1)
		)
		return
	if not coordinator.protected_reset_to_title().accepted:
		_record_failure(coordinator, seat_count, 17, "reset", _failed("reset_rejected", 2))
		return
	if (
		coordinator.lifecycle != "boot_title"
		or not coordinator.active_seats().is_empty()
		or coordinator.rules_session != null
		or coordinator.role_session != null
		or coordinator.director_runtime != null
		or coordinator.stage_index != -1
	):
		_record_failure(
			coordinator, seat_count, 17, "reset", _failed("reset_state_contaminated", 3)
		)
		return
	_runs += 1


func _test_mid_prompt_restore(seat_count: int) -> void:
	var setup: Dictionary = _new_session(seat_count, 4706)
	if not setup.accepted:
		_record_failure(null, seat_count, 4706, "restore", setup)
		return
	var coordinator: VerticalSliceCoordinator = setup.coordinator
	var reveal: Dictionary = _complete_reveals(coordinator, "cooperative")
	if not reveal.accepted:
		_record_failure(coordinator, seat_count, 4706, "restore", reveal)
		return
	var opening: Dictionary = coordinator.public_state().interaction
	var actor: int = _int_array(opening.eligible_seats)[0]
	if not coordinator._submit_player_interaction(actor, "confirm").accepted:
		_record_failure(
			coordinator, seat_count, 4706, "restore", _failed("restore_fixture_open_failed", 1)
		)
		return
	var prompt: Dictionary = coordinator.rules_session.pending_prompt
	var first_seat: int = _int_array(prompt.eligible_seats)[0]
	var option_id: String = prompt.options[0].id
	if not coordinator.rules_session.submit_response(
		first_seat, [option_id], prompt.revision
	).accepted:
		_record_failure(
			coordinator, seat_count, 4706, "restore", _failed("restore_fixture_response_failed", 2)
		)
		return
	var snapshot: Dictionary = coordinator.to_snapshot()
	var restored := VerticalSliceCoordinator.new()
	if not restored.restore_snapshot(snapshot).accepted:
		_record_failure(
			coordinator, seat_count, 4706, "restore", _failed("snapshot_restore_rejected", 3)
		)
		return
	var completed: Dictionary = _drive_active_tale(restored, "cooperative", 3)
	if not completed.accepted:
		_record_failure(restored, seat_count, 4706, "restore", completed)
		return
	var baseline: Dictionary = _run_session(seat_count, 4706, "cooperative")
	if (
		not baseline.accepted
		or restored.authority_digest() != baseline.authority_digest
		or restored.public_history_digest() != baseline.public_history_digest
	):
		_record_failure(
			restored, seat_count, 4706, "restore", _failed("restored_replay_divergence", 4)
		)
		return
	_runs += 2


func _test_failure_record_contract() -> void:
	var record: Dictionary = _reproduction_record(
		null,
		3,
		4706,
		"cooperative",
		{
			"reason": "synthetic_contract_probe",
			"step": 7,
			"authority_digest": "a".repeat(64),
			"public_history_digest": "b".repeat(64),
		},
	)
	var keys := PackedStringArray()
	for key: Variant in record.keys():
		keys.append(str(key))
	keys.sort()
	var expected := FAILURE_KEYS.duplicate()
	expected.sort()
	if keys != expected:
		_failures += 1
		push_error("FAILED: reproduction record keys changed")
	var serialized: String = JSON.stringify(record).to_lower()
	for forbidden: String in FORBIDDEN_PUBLIC_TERMS:
		if forbidden in serialized:
			_failures += 1
			push_error("FAILED: reproduction record contains forbidden data")


func _record_failure(
	coordinator: VerticalSliceCoordinator,
	seat_count: int,
	seed: int,
	strategy: String,
	failure: Dictionary,
) -> void:
	_failures += 1
	push_error(
		"PLAYTHROUGH_FAILURE %s"
		% JSON.stringify(_reproduction_record(coordinator, seat_count, seed, strategy, failure))
	)


func _reproduction_record(
	coordinator: VerticalSliceCoordinator,
	seat_count: int,
	seed: int,
	strategy: String,
	failure: Dictionary,
) -> Dictionary:
	var interaction: Dictionary = (
		coordinator.public_state().get("interaction", {}) if coordinator != null else {}
	)
	return {
		"seed": seed,
		"seat_count": seat_count,
		"strategy": strategy.substr(0, 32),
		"step": clampi(failure.get("step", 0), 0, MAX_STEPS + 32),
		"lifecycle": coordinator.lifecycle if coordinator != null else "unavailable",
		"stage_index": coordinator.stage_index if coordinator != null else -1,
		"operation_index": coordinator.operation_index if coordinator != null else -1,
		"interaction_id": str(interaction.get("interaction_id", "")).substr(0, 64),
		"interaction_kind": str(interaction.get("kind", "")).substr(0, 32),
		"reason": _bounded_reason(failure.get("reason", "rejected")),
		"authority_digest": (
			coordinator.authority_digest()
			if coordinator != null
			else str(failure.get("authority_digest", "")).substr(0, 64)
		),
		"public_history_digest": (
			coordinator.public_history_digest()
			if coordinator != null
			else str(failure.get("public_history_digest", "")).substr(0, 64)
		),
	}


func _bounded_reason(value: Variant) -> String:
	var source: String = str(value).to_lower().substr(0, 96)
	var result: String = ""
	for character: String in source:
		result += character if character in "abcdefghijklmnopqrstuvwxyz0123456789_:-" else "_"
	return result


func _failed(reason: String, step: int) -> Dictionary:
	return {"accepted": false, "reason": reason, "step": step}


func _identity(seat_number: int) -> String:
	return "automated-lab-seat-%d" % seat_number


func _first_other_seat(seats: Array[int], seat_number: int) -> int:
	for candidate: int in seats:
		if candidate != seat_number:
			return candidate
	return 0


func _first_ineligible_active_seat(active: Array[int], eligible: Array[int]) -> int:
	for seat_number: int in active:
		if not eligible.has(seat_number):
			return seat_number
	return 0


func _int_array(values: Variant) -> Array[int]:
	var result: Array[int] = []
	if values is Array:
		for value: Variant in values:
			if value is int:
				result.append(value)
	return result
