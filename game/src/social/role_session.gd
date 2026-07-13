class_name RoleSession
extends RefCounted

signal public_state_changed(payload: Dictionary)
signal private_state_changed(seat_number: int, payload: Dictionary)
signal request_rejected(reason: String)

const SNAPSHOT_VERSION: int = 1
const VIEW_VERSION: int = 1
const AUDIT_LIMIT: int = 96
const PUBLIC_HISTORY_LIMIT: int = 32
const ROLE_RNG_SALT: String = "social_roles_v1"
const UNKNOWN_LABEL: String = "Unknown Allegiance"
const SEAT_NUMERALS: Array[String] = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII"]
const SEAT_SHAPES: Array[String] = ["Circle", "Triangle", "Square", "Diamond", "Pentagon", "Hexagon", "Star", "Crescent"]

var content: SocialContent
var requested_mode_id: String = ""
var mode_id: String = ""
var session_seed: int = 1
var rng: DeterministicRng = DeterministicRng.new(1)
var revision: int = 0
var assignment_count: int = 0
var seat_states: Dictionary = {}
var pending_late_seats: Array[int] = []
var audit_history: Array[Dictionary] = []
var public_history: Array[Dictionary] = []
var last_rejection: String = "—"
var initialization_errors := PackedStringArray()
var fallback_applied: bool = false
var fallback_message: String = ""
var resolved_outcome: Dictionary = {}
var last_host_payloads: Array[Dictionary] = []
var _audit_sequence: int = 0
var _action_step: int = 0
var _transition_counts: Dictionary = {}

func _init(p_content: SocialContent = null, p_mode_id: String = "", p_seed: int = 1, seats: Array[int] = []) -> void:
	if p_content != null:
		initialize(p_content, p_mode_id, p_seed, seats)

func initialize(p_content: SocialContent, p_mode_id: String, p_seed: int, seats: Array[int], rules_content: RulesContent = null, board_definition: BoardDefinition = null) -> Dictionary:
	content = p_content
	initialization_errors = content.validate(rules_content, board_definition)
	if not initialization_errors.is_empty():
		return _reject("invalid_social_content")
	session_seed = p_seed
	return assign_mode(p_mode_id, seats)

func assign_mode(p_mode_id: String, seats: Array[int]) -> Dictionary:
	if content == null:
		return _reject("social_content_missing")
	var normalized_seats: Array[int] = seats.duplicate()
	normalized_seats.sort()
	if normalized_seats.is_empty() or normalized_seats.size() > SeatManager.MAX_SEATS:
		return _reject("invalid_seat_roster")
	for index: int in normalized_seats.size():
		if normalized_seats[index] < 1 or normalized_seats[index] > SeatManager.MAX_SEATS or (index > 0 and normalized_seats[index] == normalized_seats[index - 1]):
			return _reject("invalid_seat_roster")
	var requested: Dictionary = content.mode_by_id(p_mode_id)
	if requested.is_empty():
		return _reject("unknown_social_mode")
	var selected: Dictionary = requested
	var used_fallback: bool = false
	if not selected.get("supported_player_counts", []).has(normalized_seats.size()):
		var fallback_id: String = selected.get("fallback_mode", "")
		selected = content.mode_by_id(fallback_id)
		if selected.is_empty() or not selected.get("supported_player_counts", []).has(normalized_seats.size()):
			return _reject("unsupported_player_count")
		used_fallback = true
	var probe := DeterministicRng.new(derive_seed(session_seed, selected.id))
	var plan_result: Dictionary = _build_assignment_plan(selected, normalized_seats, probe)
	if not plan_result.accepted:
		return _reject(plan_result.reason)
	var next_states: Dictionary = {}
	for seat: int in normalized_seats:
		var role_id: String = plan_result.plan.get(seat, "")
		var role: Dictionary = content.role_by_id(role_id)
		if role.is_empty():
			return _reject("impossible_assignment_plan")
		next_states[seat] = _new_seat_state(seat, role)
	requested_mode_id = p_mode_id
	mode_id = selected.id
	rng = probe
	seat_states = next_states
	pending_late_seats.clear()
	fallback_applied = used_fallback
	fallback_message = "Unsupported count selected authored no-secret fallback." if used_fallback else ""
	resolved_outcome.clear()
	_transition_counts.clear()
	_action_step = 0
	assignment_count += 1
	revision += 1
	_record("assignment", {
		"requested_mode_id": requested_mode_id, "mode_id": mode_id, "plan": plan_result.plan,
		"rng_before": plan_result.rng_before, "rng_after": rng.to_snapshot(), "fallback": fallback_applied,
	}, "Roles prepared for %d stable seat%s.%s" % [normalized_seats.size(), "" if normalized_seats.size() == 1 else "s", " Safe fallback active." if fallback_applied else ""])
	public_state_changed.emit(public_view())
	return {"accepted": true, "reason": "", "mode_id": mode_id, "fallback_applied": fallback_applied}

static func derive_seed(seed: int, selected_mode_id: String) -> int:
	var value: int = absi(seed) % DeterministicRng.MODULUS
	for character: String in "%s:%s" % [ROLE_RNG_SALT, selected_mode_id]:
		value = int((value * 131 + character.unicode_at(0)) % DeterministicRng.MODULUS)
	return 1 if value == 0 else value

func acknowledge_private_role(seat_number: int) -> Dictionary:
	if not seat_states.has(seat_number):
		return _reject("seat_not_participating")
	if seat_states[seat_number].acknowledged:
		return _reject("already_acknowledged")
	seat_states[seat_number].acknowledged = true
	revision += 1
	_record("private_acknowledgement", {"seat": seat_number}, "Seat %s completed a private acknowledgement." % _roman(seat_number))
	private_state_changed.emit(seat_number, seat_private_view(seat_number))
	return _accept()

func set_seat_connected(seat_number: int, connected: bool) -> Dictionary:
	if not seat_states.has(seat_number):
		return _reject("seat_not_participating")
	if seat_states[seat_number].connected == connected:
		return _reject("connection_state_unchanged")
	seat_states[seat_number].connected = connected
	revision += 1
	_record("connection", {"seat": seat_number, "connected": connected}, "Seat %s %s; stable secret ownership is reserved." % [_roman(seat_number), "reconnected" if connected else "disconnected"])
	public_state_changed.emit(public_view())
	return _accept()

func request_late_join(seat_number: int) -> Dictionary:
	if seat_number < 1 or seat_number > SeatManager.MAX_SEATS or seat_states.has(seat_number):
		return _reject("invalid_late_join")
	if pending_late_seats.has(seat_number):
		return _reject("late_join_already_deferred")
	pending_late_seats.append(seat_number)
	pending_late_seats.sort()
	_record("late_join_deferred", {"seat": seat_number}, "Late join deferred to an authored safe boundary.")
	return {"accepted": true, "reason": "", "policy": "deferred"}

func request_transition(seat_number: int, transition_id: String, trigger: String, rules: RulesSession = null, board: BoardState = null) -> Dictionary:
	var validation: Dictionary = _validate_transition_request(seat_number, transition_id, trigger, seat_states)
	if not validation.accepted:
		return _reject(validation.reason)
	var definition: Dictionary = validation.definition
	var effects: Array = definition.get("downstream_effects", []).duplicate(true)
	var preflight: Dictionary = _preflight_effects(effects, seat_number, rules, board)
	if not preflight.accepted:
		return _reject("downstream_rejected")
	var downstream_result: Dictionary = _commit_effects(effects, seat_number, rules)
	if not downstream_result.accepted:
		return _reject("downstream_rejected")
	_apply_transition_state(seat_number, definition)
	revision += 1
	var public_message: String = definition.get("presentation", {}).get("public_message", "A public social state changed.") if definition.visibility == "public" else "A private social state changed."
	_record("transition", {
		"seat": seat_number, "transition_id": transition_id, "trigger": trigger,
		"target_form": definition.target_form, "downstream": downstream_result,
	}, public_message)
	public_state_changed.emit(public_view())
	private_state_changed.emit(seat_number, seat_private_view(seat_number))
	return {"accepted": true, "reason": "", "revision": revision, "downstream": downstream_result}

func request_transition_by_trigger(seat_number: int, trigger: String, rules: RulesSession = null, board: BoardState = null) -> Dictionary:
	if not seat_states.has(seat_number):
		return _reject("seat_not_participating")
	var role: Dictionary = content.role_by_id(seat_states[seat_number].form_id)
	for transition_id: String in role.get("transition_refs", []):
		var definition: Dictionary = content.transition_by_id(transition_id)
		if definition.get("trigger", "") == trigger:
			return request_transition(seat_number, transition_id, trigger, rules, board)
	return _reject("transition_not_available")

func perform_action(actor_seat: int, action_id: String, targets: Array[int], rules: RulesSession = null, board: BoardState = null) -> Dictionary:
	var validation: Dictionary = _validate_action_request(actor_seat, action_id, targets, rules)
	if not validation.accepted:
		return _reject(validation.reason)
	var action: Dictionary = validation.action
	var effects: Array = []
	var planned_transitions: Array[Dictionary] = []
	var host_payloads: Array[Dictionary] = []
	for proposal: Dictionary in action.get("proposals", []):
		match proposal.type:
			"rules_effects":
				for effect: Dictionary in proposal.get("effects", []): effects.append(effect.duplicate(true))
			"board_mutation":
				effects.append({"type": "board_mutation", "mutation": proposal.get("mutation", {}).duplicate(true)})
			"role_transition":
				var target_seat: int = actor_seat if proposal.get("target", "self") == "self" else targets[0]
				var transition: Dictionary = _validate_transition_request(target_seat, proposal.get("transition_id", ""), content.transition_by_id(proposal.get("transition_id", "")).get("trigger", ""), seat_states)
				if not transition.accepted:
					return _reject("action_transition_rejected")
				planned_transitions.append({"seat": target_seat, "definition": transition.definition})
				for effect: Dictionary in transition.definition.get("downstream_effects", []): effects.append(effect.duplicate(true))
			"presentation":
				host_payloads.append({"visibility": proposal.visibility, "message": proposal.message, "actor_seat": actor_seat})
	var preflight: Dictionary = _preflight_effects(effects, actor_seat, rules, board)
	if not preflight.accepted:
		return _reject("downstream_rejected")
	var downstream_result: Dictionary = _commit_effects(effects, actor_seat, rules)
	if not downstream_result.accepted:
		return _reject("downstream_rejected")
	for planned: Dictionary in planned_transitions:
		_apply_transition_state(planned.seat, planned.definition)
	_action_step += 1
	seat_states[actor_seat].uses[action_id] = seat_states[actor_seat].uses.get(action_id, 0) + 1
	var round_number: int = rules.round_number if rules != null else _action_step
	seat_states[actor_seat].last_used_round[action_id] = round_number
	last_host_payloads.clear()
	for payload: Dictionary in host_payloads:
		if payload.visibility == "public":
			last_host_payloads.append(payload.duplicate(true))
	revision += 1
	for planned: Dictionary in planned_transitions:
		_record("transition", {
			"seat": planned.seat, "transition_id": planned.definition.id, "trigger": planned.definition.trigger,
			"target_form": planned.definition.target_form, "via_action": action_id,
		}, planned.definition.get("presentation", {}).get("public_message", "A public social state changed.") if planned.definition.visibility == "public" else "A private social state changed.")
	var public_message: String = "A seat completed a private action; only its authored public consequence is shown."
	for payload: Dictionary in host_payloads:
		if payload.visibility == "public":
			public_message = payload.message
			break
	_record("action", {"actor_seat": actor_seat, "action_id": action_id, "targets": targets, "downstream": downstream_result, "host_payloads": host_payloads}, public_message)
	public_state_changed.emit(public_view())
	private_state_changed.emit(actor_seat, seat_private_view(actor_seat))
	return {"accepted": true, "reason": "", "revision": revision, "downstream": downstream_result, "public_payloads": last_host_payloads.duplicate(true)}

func perform_action_by_tag(actor_seat: int, action_tag: String, targets: Array[int], rules: RulesSession = null, board: BoardState = null) -> Dictionary:
	if not seat_states.has(actor_seat):
		return _reject("seat_not_participating")
	var role: Dictionary = content.role_by_id(seat_states[actor_seat].form_id)
	for action_id: String in role.get("action_refs", []):
		var action: Dictionary = content.action_by_id(action_id)
		if action.get("tags", []).has(action_tag):
			return perform_action(actor_seat, action_id, targets, rules, board)
	return _reject("action_not_available")

func public_view() -> Dictionary:
	var selected_mode: Dictionary = content.mode_by_id(mode_id)
	var seats: Array[Dictionary] = []
	for seat_number: int in _sorted_seats():
		seats.append(_public_seat_view(seat_number))
	var view: Dictionary = {
		"view_version": VIEW_VERSION, "view_kind": "public_shared_screen", "scenario_label": "Lantern House Social Horror Lab",
		"mode_label": selected_mode.get("label", "Unavailable"), "revision": revision, "fallback_active": fallback_applied,
		"fallback_message": fallback_message, "privacy_notice": "PUBLIC TV VIEW — no panel on this screen is private.",
		"afterlife_notice": "Afterlife enabled: defeat preserves meaningful legal participation." if selected_mode.get("afterlife_enabled", true) else "WARNING BEFORE PLAY: afterlife is disabled by this authored mode.",
		"seats": seats, "public_history": public_history.duplicate(true), "host_payloads": last_host_payloads.duplicate(true),
		"outcome": resolved_outcome.get("public", {}).duplicate(true),
	}
	return _json_copy(view)

func seat_private_view(seat_number: int) -> Dictionary:
	if not seat_states.has(seat_number):
		return {"accepted": false, "reason": "seat_not_authorized", "view_kind": "seat_private"}
	var state: Dictionary = seat_states[seat_number]
	var role: Dictionary = content.role_by_id(state.form_id)
	var faction: Dictionary = content.faction_by_id(state.faction_id)
	var private_objectives: Array[Dictionary] = []
	for objective_id: String in state.objective_refs:
		var objective: Dictionary = content.objective_by_id(objective_id)
		private_objectives.append({"objective_id": objective.id, "label": objective.label, "description": objective.description, "visibility": objective.visibility})
	var private_actions: Array[Dictionary] = []
	for action_id: String in role.get("action_refs", []):
		var action: Dictionary = content.action_by_id(action_id)
		private_actions.append({"action_id": action.id, "label": action.label, "description": action.description, "symbol": action.symbol, "uses": state.uses.get(action.id, 0)})
	return _json_copy({
		"accepted": true, "view_version": VIEW_VERSION, "view_kind": "seat_private", "authorized_seat": seat_number,
		"shared_screen_warning": "OBSCURE THE SHARED SCREEN. Pass control only to Seat %s. Companion privacy is future work." % _roman(seat_number),
		"public": public_view(), "private": {
			"role_id": role.id, "role_label": role.label, "role_description": role.description, "form_id": state.form_id,
			"faction_id": faction.id, "faction_label": faction.label, "objectives": private_objectives, "actions": private_actions,
			"acknowledged": state.acknowledged, "pending_prompts": state.pending_private_prompts.duplicate(true),
		},
	})

func faction_private_view(requester_seat: int) -> Dictionary:
	if not seat_states.has(requester_seat):
		return {"accepted": false, "reason": "seat_not_authorized", "view_kind": "faction_private"}
	var requester: Dictionary = seat_states[requester_seat]
	var faction: Dictionary = content.faction_by_id(requester.faction_id)
	if not faction.get("communication_allowed", false):
		return {"accepted": false, "reason": "faction_view_not_authorized", "view_kind": "faction_private"}
	var members: Array[Dictionary] = []
	for seat_number: int in _sorted_seats():
		var state: Dictionary = seat_states[seat_number]
		if state.faction_id != requester.faction_id:
			continue
		var role: Dictionary = content.role_by_id(state.form_id)
		members.append({"seat": seat_number, "role_id": role.id, "role_label": role.label, "lifecycle": state.lifecycle})
	return _json_copy({
		"accepted": true, "view_version": VIEW_VERSION, "view_kind": "faction_private", "authorized_seat": requester_seat,
		"faction_id": faction.id, "faction_label": faction.label, "members": members,
		"policy": "Authored faction communication only; no unrelated seats are included.",
	})

func diagnostics_view(spoilers_enabled: bool = false) -> Dictionary:
	if not spoilers_enabled:
		return {"accepted": false, "reason": "spoiler_diagnostics_disabled", "view_kind": "diagnostics"}
	var private_previews: Array[Dictionary] = []
	var transition_eligibility: Array[Dictionary] = []
	for seat_number: int in _sorted_seats():
		private_previews.append({"seat": seat_number, "preview": seat_private_view(seat_number)})
		var available: Array[Dictionary] = []
		var state: Dictionary = seat_states[seat_number]
		var role: Dictionary = content.role_by_id(state.form_id)
		for transition_id: String in role.get("transition_refs", []):
			var transition: Dictionary = content.transition_by_id(transition_id)
			var eligibility: Dictionary = _validate_transition_request(seat_number, transition_id, transition.trigger, seat_states)
			available.append({"transition_id": transition.id, "label": transition.label, "trigger": transition.trigger, "eligible": eligibility.accepted, "reason": eligibility.get("reason", "")})
		transition_eligibility.append({"seat": seat_number, "transitions": available, "legal_actions": legal_actions(seat_number)})
	return _json_copy({
		"accepted": true, "view_version": VIEW_VERSION, "view_kind": "spoiler_diagnostics", "warning": "SPOILER DIAGNOSTICS — NEVER PLAYER-FACING",
		"scenario_id": content.scenario_id, "scenario_version": content.scenario_version, "requested_mode_id": requested_mode_id,
		"mode_id": mode_id, "revision": revision, "assignment_count": assignment_count, "rng": rng.to_snapshot(),
		"seat_states": _seat_state_rows(), "transition_counts": _transition_counts, "action_step": _action_step,
		"audit_history": audit_history, "last_rejection": last_rejection, "public_preview": public_view(), "seat_private_previews": private_previews,
		"transition_eligibility": transition_eligibility, "privacy_evaluation": privacy_report(),
		"director_safe_signals": director_safe_signals(), "resolved_outcome": resolved_outcome,
	})

func director_safe_signals() -> Dictionary:
	var mode: Dictionary = content.mode_by_id(mode_id)
	var allowlist: Array = mode.get("director_signal_allowlist", [])
	var revealed_factions: Dictionary = {}
	var revealed_counts: Dictionary = {}
	var defeated_count: int = 0
	var restless_count: int = 0
	var conversion_count: int = 0
	var afterlife_support: int = 0
	for seat_number: int in _sorted_seats():
		var state: Dictionary = seat_states[seat_number]
		var role: Dictionary = content.role_by_id(state.form_id)
		if state.revealed:
			revealed_factions[state.faction_id] = true
			revealed_counts[state.faction_id] = revealed_counts.get(state.faction_id, 0) + 1
		if state.defeated: defeated_count += 1
		if role.get("tags", []).has("afterlife"):
			restless_count += 1
			for action_id: String in role.get("action_refs", []):
				if content.action_by_id(action_id).get("tags", []).has("afterlife_support"):
					afterlife_support += 1
		if state.revealed and state.transformed: conversion_count += 1
	var imbalance: int = 0
	if not revealed_counts.is_empty():
		var counts: Array = revealed_counts.values()
		imbalance = counts.max() - counts.min()
	var candidates: Dictionary = {
		"revealed_faction_count": revealed_factions.size(), "public_hostility": maxi(0, revealed_factions.size() - 1) * 20,
		"defeated_count": defeated_count, "restless_count": restless_count,
		"public_conversion_pressure": conversion_count * 20, "revealed_imbalance": imbalance * 20,
		"social_choice_pressure": 0, "afterlife_support_available": afterlife_support,
	}
	var result: Dictionary = {}
	for signal_name: String in allowlist:
		if candidates.has(signal_name): result[signal_name] = candidates[signal_name]
	return _json_copy(result)

func evaluate_outcomes(rules: RulesSession = null, board: BoardState = null) -> Dictionary:
	var seat_results: Array[Dictionary] = []
	var public_seats: Array[Dictionary] = []
	var faction_buckets: Dictionary = {}
	for seat_number: int in _sorted_seats():
		var state: Dictionary = seat_states[seat_number]
		var evaluations: Array[Dictionary] = []
		for objective_id: String in state.objective_refs:
			var objective: Dictionary = content.objective_by_id(objective_id)
			var complete: bool = _conditions_match(objective.get("conditions", []), seat_number, state.faction_id, rules, board)
			var partial: bool = not complete and not objective.get("partial_conditions", []).is_empty() and _conditions_match(objective.partial_conditions, seat_number, state.faction_id, rules, board)
			evaluations.append({"objective_id": objective.id, "label": objective.label, "visibility": objective.visibility, "complete": complete, "partial": partial, "result": objective.result, "priority": objective.priority, "reveal_at_end": objective.reveal_at_end, "epilogue_tags": objective.epilogue_tags})
		var result: String = "defeat"
		var winning_priority: int = -1
		for evaluation: Dictionary in evaluations:
			if evaluation.complete and evaluation.priority > winning_priority:
				result = evaluation.result
				winning_priority = evaluation.priority
			elif evaluation.partial and winning_priority < 0:
				result = "partial"
		var seat_record: Dictionary = {"seat": seat_number, "faction_id": state.faction_id, "form_id": state.form_id, "result": result, "objectives": evaluations}
		seat_results.append(seat_record)
		var public_objectives: Array[String] = []
		for evaluation: Dictionary in evaluations:
			if evaluation.visibility == "public" or evaluation.reveal_at_end:
				public_objectives.append("%s: %s" % [evaluation.label, "complete" if evaluation.complete else "partial" if evaluation.partial else "incomplete"])
		public_seats.append({"seat": seat_number, "numeral": _roman(seat_number), "result": result, "objectives": public_objectives})
		if not faction_buckets.has(state.faction_id): faction_buckets[state.faction_id] = []
		faction_buckets[state.faction_id].append(result)
	var faction_results: Array[Dictionary] = []
	var public_factions: Array[Dictionary] = []
	for faction_id: String in faction_buckets:
		var faction: Dictionary = content.faction_by_id(faction_id)
		var values: Array = faction_buckets[faction_id]
		var winners: int = values.count("victory") + values.count("changed") + values.count("restless") + values.count("escaped")
		var result: String = "victory" if winners > 0 else "partial" if values.has("partial") else "defeat"
		faction_results.append({"faction_id": faction_id, "label": faction.label, "result": result, "seat_results": values})
		public_factions.append({"label": faction.label, "symbol": faction.symbol, "pattern": faction.pattern, "result": result})
	return _json_copy({
		"outcome_version": 1, "policy": content.mode_by_id(mode_id).get("terminal_policy", {}),
		"private": {"seats": seat_results, "factions": faction_results},
		"public": {"summary": "Multiple faction and individual results resolved deterministically.", "seats": public_seats, "factions": public_factions},
	})

func resolve_outcomes(rules: RulesSession, board: BoardState = null) -> Dictionary:
	if not resolved_outcome.is_empty():
		return {"accepted": true, "reason": "", "idempotent": true, "outcome": resolved_outcome.duplicate(true)}
	var proposal: Dictionary = evaluate_outcomes(rules, board)
	var result_key: String = content.mode_by_id(mode_id).get("terminal_policy", {}).get("result_key", "social_outcome")
	var terminal: Dictionary = rules.complete(result_key)
	if not terminal.accepted:
		return _reject("terminal_result_rejected")
	resolved_outcome = proposal
	revision += 1
	_record("outcome", {"outcome": resolved_outcome, "rules_terminal_reason": result_key}, "Mixed faction and individual outcomes resolved.")
	public_state_changed.emit(public_view())
	return {"accepted": true, "reason": "", "idempotent": false, "outcome": resolved_outcome.duplicate(true)}

func privacy_report() -> Dictionary:
	var public_json: String = JSON.stringify(public_view())
	var director_json: String = JSON.stringify(director_safe_signals())
	var leaked: Array[String] = []
	var unauthorized_private_leaks: Array[String] = []
	for owner_seat: int in _sorted_seats():
		var state: Dictionary = seat_states[owner_seat]
		if state.revealed:
			continue
		var role: Dictionary = content.role_by_id(state.form_id)
		var faction: Dictionary = content.faction_by_id(state.faction_id)
		var secrets: Array[String] = [role.id, state.form_id, faction.id, role.description]
		for objective_id: String in state.objective_refs:
			var objective: Dictionary = content.objective_by_id(objective_id)
			if objective.visibility != "public":
				secrets.append(objective.id); secrets.append(objective.description)
		for secret: String in secrets:
			if not secret.is_empty() and (secret in public_json or secret in director_json):
				leaked.append(secret)
			for viewer_seat: int in _sorted_seats():
				if viewer_seat == owner_seat: continue
				var viewer_json: String = JSON.stringify(seat_private_view(viewer_seat))
				if not secret.is_empty() and secret in viewer_json:
					unauthorized_private_leaks.append("seat_%d:%s" % [viewer_seat, secret])
	return {"passed": leaked.is_empty() and unauthorized_private_leaks.is_empty(), "public_or_director_leaks": leaked, "unauthorized_seat_leaks": unauthorized_private_leaks}

func seat_with_tag(tag: String, excluded: Array[int] = []) -> int:
	for seat_number: int in _sorted_seats():
		if excluded.has(seat_number): continue
		var role: Dictionary = content.role_by_id(seat_states[seat_number].form_id)
		if role.get("tags", []).has(tag): return seat_number
	return 0

func role_tags_for_seat(seat_number: int) -> Array[String]:
	if not seat_states.has(seat_number): return []
	var role: Dictionary = content.role_by_id(seat_states[seat_number].form_id)
	var result: Array[String] = []
	for tag: String in role.get("tags", []): result.append(tag)
	return result

func legal_actions(seat_number: int, rules: RulesSession = null) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not seat_states.has(seat_number): return result
	var state: Dictionary = seat_states[seat_number]
	var role: Dictionary = content.role_by_id(state.form_id)
	for action_id: String in role.get("action_refs", []):
		var action: Dictionary = content.action_by_id(action_id)
		var target_count: int = action.get("minimum_targets", 0)
		var placeholder_targets: Array[int] = []
		if target_count > 0:
			for candidate: int in _sorted_seats():
				if candidate != seat_number:
					placeholder_targets.append(candidate)
					if placeholder_targets.size() == target_count: break
		var validation: Dictionary = _validate_action_request(seat_number, action_id, placeholder_targets, rules)
		if validation.accepted:
			result.append({"action_id": action.id, "label": action.label, "description": action.description, "symbol": action.symbol, "pattern": action.pattern, "visibility": action.visibility})
	return result

func to_snapshot() -> Dictionary:
	return _json_copy({
		"snapshot_version": SNAPSHOT_VERSION, "scenario_id": content.scenario_id, "scenario_version": content.scenario_version,
		"requested_mode_id": requested_mode_id, "mode_id": mode_id, "session_seed": session_seed, "rng": rng.to_snapshot(),
		"revision": revision, "assignment_count": assignment_count, "seat_states": _seat_state_rows(), "pending_late_seats": pending_late_seats,
		"audit_history": audit_history, "public_history": public_history, "audit_sequence": _audit_sequence, "action_step": _action_step,
		"transition_counts": _transition_counts, "fallback_applied": fallback_applied, "fallback_message": fallback_message,
		"resolved_outcome": resolved_outcome, "last_host_payloads": last_host_payloads,
	})

func restore_snapshot(snapshot: Dictionary) -> Dictionary:
	snapshot = _normalize_json_numbers(snapshot)
	var validation: Dictionary = _validate_snapshot(snapshot)
	if not validation.accepted:
		return _reject(validation.reason)
	var rng_probe := DeterministicRng.new(1)
	if not rng_probe.restore(snapshot.rng):
		return _reject("invalid_role_rng_snapshot")
	var next_states: Dictionary = {}
	for row: Dictionary in snapshot.seat_states:
		next_states[row.seat] = row.state.duplicate(true)
	requested_mode_id = snapshot.requested_mode_id; mode_id = snapshot.mode_id; session_seed = snapshot.session_seed; rng = rng_probe
	revision = snapshot.revision; assignment_count = snapshot.assignment_count; seat_states = next_states
	pending_late_seats = _int_array(snapshot.pending_late_seats); audit_history = _dict_array(snapshot.audit_history); public_history = _dict_array(snapshot.public_history)
	_audit_sequence = snapshot.audit_sequence; _action_step = snapshot.action_step; _transition_counts = snapshot.transition_counts.duplicate(true)
	fallback_applied = snapshot.fallback_applied; fallback_message = snapshot.fallback_message; resolved_outcome = snapshot.resolved_outcome.duplicate(true)
	last_host_payloads = _dict_array(snapshot.last_host_payloads); last_rejection = "—"
	public_state_changed.emit(public_view())
	return _accept()

func _build_assignment_plan(mode: Dictionary, seats: Array[int], probe: DeterministicRng) -> Dictionary:
	var plan: Dictionary = {}
	var available: Array[int] = seats.duplicate()
	var rng_before: Dictionary = probe.to_snapshot()
	for assignment: Dictionary in mode.get("fixed_assignments", []):
		var seat: int = assignment.seat
		if not available.has(seat) or plan.has(seat):
			return {"accepted": false, "reason": "impossible_assignment_plan"}
		plan[seat] = assignment.role_id
		available.erase(seat)
	if mode.get("assignment_policy", "") == "random_pool":
		var required: int = 0
		for pool: Dictionary in mode.get("assignment_pool", []): required += pool.count
		if required > available.size():
			return {"accepted": false, "reason": "impossible_assignment_plan"}
		for pool: Dictionary in mode.get("assignment_pool", []):
			var role: Dictionary = content.role_by_id(pool.role_id)
			if seats.size() < role.minimum_players or seats.size() > role.maximum_players:
				return {"accepted": false, "reason": "impossible_assignment_plan"}
			for _index: int in pool.count:
				if available.is_empty(): return {"accepted": false, "reason": "impossible_assignment_plan"}
				var selected_index: int = probe.draw_range(0, available.size() - 1)
				var selected_seat: int = available[selected_index]
				plan[selected_seat] = pool.role_id
				available.remove_at(selected_index)
	var default_role: Dictionary = content.role_by_id(mode.get("default_role_id", ""))
	if default_role.is_empty() or seats.size() < default_role.minimum_players or seats.size() > default_role.maximum_players:
		return {"accepted": false, "reason": "impossible_assignment_plan"}
	for seat: int in available: plan[seat] = default_role.id
	if plan.size() != seats.size(): return {"accepted": false, "reason": "impossible_assignment_plan"}
	return {"accepted": true, "reason": "", "plan": plan, "rng_before": rng_before}

func _new_seat_state(seat_number: int, role: Dictionary) -> Dictionary:
	return {
		"seat": seat_number, "connected": true, "assigned_role_id": role.id, "form_id": role.id, "faction_id": role.starting_faction,
		"lifecycle": role.get("initial_lifecycle", "active"), "revealed": role.reveal_policy == "public", "acknowledged": false,
		"transformed": role.get("initial_lifecycle", "active") == "transformed", "defeated": role.get("initial_lifecycle", "active") == "afterlife",
		"escaped": false, "objective_refs": role.get("objective_refs", []).duplicate(), "uses": {}, "last_used_round": {},
		"resources": {}, "pending_private_prompts": [],
	}

func _validate_transition_request(seat_number: int, transition_id: String, trigger: String, states: Dictionary) -> Dictionary:
	if not states.has(seat_number): return {"accepted": false, "reason": "seat_not_participating"}
	var state: Dictionary = states[seat_number]
	var role: Dictionary = content.role_by_id(state.form_id)
	if not role.get("transition_refs", []).has(transition_id): return {"accepted": false, "reason": "transition_not_available"}
	var definition: Dictionary = content.transition_by_id(transition_id)
	if definition.is_empty() or definition.trigger != trigger or not definition.get("source_forms", []).has(state.form_id):
		return {"accepted": false, "reason": "transition_source_mismatch"}
	var count_key: String = "%d:%s" % [seat_number, transition_id]
	if _transition_counts.get(count_key, 0) >= definition.max_chain:
		return {"accepted": false, "reason": "transition_chain_limit"}
	var target_role: Dictionary = content.role_by_id(definition.target_form)
	if target_role.get("tags", []).has("afterlife") and not content.mode_by_id(mode_id).get("afterlife_enabled", true):
		return {"accepted": false, "reason": "afterlife_disabled_by_mode"}
	if target_role.is_empty() or target_role.get("objective_refs", []).is_empty() or target_role.get("action_refs", []).is_empty():
		return {"accepted": false, "reason": "transition_would_strand_seat"}
	return {"accepted": true, "reason": "", "definition": definition}

func _apply_transition_state(seat_number: int, definition: Dictionary) -> void:
	var state: Dictionary = seat_states[seat_number]
	var target_role: Dictionary = content.role_by_id(definition.target_form)
	state.form_id = target_role.id
	state.faction_id = target_role.starting_faction
	state.objective_refs = target_role.get("objective_refs", []).duplicate()
	var patch: Dictionary = definition.get("state_patch", {})
	for key: String in ["lifecycle", "revealed", "transformed", "defeated", "escaped"]:
		if patch.has(key): state[key] = patch[key]
	if target_role.reveal_policy == "public": state.revealed = true
	var count_key: String = "%d:%s" % [seat_number, definition.id]
	_transition_counts[count_key] = _transition_counts.get(count_key, 0) + 1

func _validate_action_request(actor_seat: int, action_id: String, targets: Array[int], rules: RulesSession) -> Dictionary:
	if not seat_states.has(actor_seat): return {"accepted": false, "reason": "seat_not_participating"}
	var state: Dictionary = seat_states[actor_seat]
	var role: Dictionary = content.role_by_id(state.form_id)
	if not role.get("action_refs", []).has(action_id): return {"accepted": false, "reason": "action_not_available"}
	var action: Dictionary = content.action_by_id(action_id)
	if not action.get("allowed_lifecycles", []).has(state.lifecycle): return {"accepted": false, "reason": "action_lifecycle_mismatch"}
	if targets.size() < action.minimum_targets or targets.size() > action.maximum_targets:
		return {"accepted": false, "reason": "invalid_action_targets"}
	var unique_targets: Dictionary = {}
	for target: int in targets:
		if not seat_states.has(target) or unique_targets.has(target): return {"accepted": false, "reason": "invalid_action_targets"}
		unique_targets[target] = true
		match action.target_scope:
			"self":
				if target != actor_seat: return {"accepted": false, "reason": "invalid_action_targets"}
			"other":
				if target == actor_seat: return {"accepted": false, "reason": "invalid_action_targets"}
			"faction_other":
				if target == actor_seat or seat_states[target].faction_id != state.faction_id: return {"accepted": false, "reason": "invalid_action_targets"}
	var use_limit: int = action.get("use_limit", 0)
	if use_limit > 0 and state.uses.get(action_id, 0) >= use_limit: return {"accepted": false, "reason": "action_use_limit"}
	var round_number: int = rules.round_number if rules != null else _action_step + 1
	var last_round: int = state.last_used_round.get(action_id, -999)
	if action.get("per_round_limit", 0) > 0 and last_round == round_number: return {"accepted": false, "reason": "action_round_limit"}
	if action.get("cooldown", 0) > 0 and round_number < last_round + action.cooldown: return {"accepted": false, "reason": "action_cooldown"}
	if rules != null and not action.get("allowed_phases", []).is_empty() and not action.allowed_phases.has(rules.current_phase()):
		return {"accepted": false, "reason": "action_phase_mismatch"}
	return {"accepted": true, "reason": "", "action": action}

func _preflight_effects(effects: Array, actor_seat: int, rules: RulesSession, board: BoardState) -> Dictionary:
	if effects.is_empty(): return _accept()
	if rules == null or board == null: return {"accepted": false, "reason": "authority_missing"}
	if rules.board_state != board: return {"accepted": false, "reason": "authority_mismatch"}
	var board_probe := BoardState.new(board.definition)
	if not board_probe.restore_snapshot(board.to_snapshot()).accepted: return {"accepted": false, "reason": "board_probe_failed"}
	var rules_probe := RulesSession.new(rules.content, board_probe, rules.seed, rules.participating_seats)
	if not rules_probe.restore_snapshot(rules.to_snapshot()).accepted: return {"accepted": false, "reason": "rules_probe_failed"}
	return rules_probe.apply_effect_bundle(effects, actor_seat, "social_preflight")

func _commit_effects(effects: Array, actor_seat: int, rules: RulesSession) -> Dictionary:
	if effects.is_empty(): return {"accepted": true, "reason": "", "authority": "none", "rules_revision": -1, "board_revision": -1}
	var result: Dictionary = rules.apply_effect_bundle(effects, actor_seat, "social_role")
	if not result.accepted: return result
	return {"accepted": true, "reason": "", "authority": "RulesSession/BoardState", "rules_history_sequence": rules.history().size(), "board_revision": rules.board_state.revision if rules.board_state != null else -1}

func _conditions_match(conditions: Array, seat_number: int, faction_id: String, rules: RulesSession, board: BoardState) -> bool:
	for condition: Dictionary in conditions:
		match condition.type:
			"always": pass
			"rules_flag":
				if rules == null or rules.flags.get(condition.flag_id) != condition.value: return false
			"rules_counter_at_least":
				if rules == null or rules.counters.get(condition.counter_id, 0) < condition.value: return false
			"board_feature":
				if board == null or not board.get_space_state(condition.space_id).get("features", []).has(condition.feature_id): return false
			"faction_count_at_least":
				var count: int = 0
				for state: Dictionary in seat_states.values():
					if state.faction_id == faction_id: count += 1
				if count < condition.value: return false
			"seat_state":
				if seat_states[seat_number].get(condition.key) != condition.value: return false
			"action_used":
				var used: bool = false
				for action_id: String in seat_states[seat_number].uses:
					if seat_states[seat_number].uses[action_id] > 0 and content.action_by_id(action_id).get("tags", []).has(condition.action_tag): used = true
				if not used: return false
			"objective_complete":
				return false
	return true

func _public_seat_view(seat_number: int) -> Dictionary:
	var state: Dictionary = seat_states[seat_number]
	var role: Dictionary = content.role_by_id(state.form_id)
	var faction: Dictionary = content.faction_by_id(state.faction_id)
	var identity: Dictionary = {"label": role.label, "symbol": role.symbol, "pattern": role.pattern, "description": role.description}
	if not state.revealed:
		identity = role.get("public_cover", {"label": "Unknown", "symbol": "?", "pattern": "closed crosshatch", "description": "Unknown"}).duplicate(true)
	var faction_public: bool = state.revealed or faction.get("membership_policy", "hidden") == "public"
	var objectives: Array[String] = []
	for objective_id: String in state.objective_refs:
		var objective: Dictionary = content.objective_by_id(objective_id)
		if objective.visibility == "public": objectives.append(objective.label)
	var actions: Array[String] = []
	for action: Dictionary in legal_actions(seat_number):
		if action.visibility == "public": actions.append("%s %s" % [action.symbol, action.label])
	return {
		"seat": seat_number, "numeral": _roman(seat_number), "shape": SEAT_SHAPES[seat_number - 1], "count_pattern": "mark x%d" % seat_number,
		"connection": "CONNECTED" if state.connected else "DISCONNECTED — RESERVED", "connection_symbol": "●" if state.connected else "×",
		"identity_label": identity.label, "identity_symbol": identity.symbol, "identity_pattern": identity.pattern,
		"faction_label": faction.label if faction_public else UNKNOWN_LABEL, "faction_symbol": faction.symbol if faction_public else "?",
		"lifecycle": state.lifecycle.capitalize(), "status": _public_status(state), "objectives": objectives, "legal_actions": actions,
	}

func _public_status(state: Dictionary) -> String:
	if not state.connected: return "DISCONNECTED / RESERVED"
	if state.lifecycle == "afterlife": return "RESTLESS / ACTIVE AFTERLIFE"
	if state.lifecycle == "defeated" or state.defeated: return "DEFEATED"
	if state.lifecycle == "transformed" or state.transformed: return "TRANSFORMED"
	if state.lifecycle == "replacement": return "REPLACEMENT"
	if state.lifecycle == "escaped" or state.escaped: return "ESCAPED"
	if state.revealed: return "REVEALED"
	return "UNKNOWN / HIDDEN"

func _record(type: String, private_payload: Dictionary, public_message: String) -> void:
	_audit_sequence += 1
	var entry: Dictionary = {"sequence": _audit_sequence, "revision": revision, "type": type, "private": private_payload.duplicate(true)}
	audit_history.append(_json_copy(entry))
	if audit_history.size() > AUDIT_LIMIT: audit_history.pop_front()
	public_history.append({"sequence": _audit_sequence, "revision": revision, "type": _public_history_type(type), "message": public_message})
	if public_history.size() > PUBLIC_HISTORY_LIMIT: public_history.pop_front()
	last_rejection = "—"

func _public_history_type(type: String) -> String:
	match type:
		"assignment": return "roles_prepared"
		"private_acknowledgement": return "private_step_complete"
		"connection": return "seat_connection"
		"transition": return "social_transition"
		"action": return "social_action"
		"outcome": return "outcome_resolved"
		_: return "social_update"

func _validate_snapshot(snapshot: Dictionary) -> Dictionary:
	if snapshot.get("snapshot_version", -1) != SNAPSHOT_VERSION: return {"accepted": false, "reason": "unsupported_snapshot_version"}
	if snapshot.get("scenario_id", "") != content.scenario_id or snapshot.get("scenario_version", -1) != content.scenario_version: return {"accepted": false, "reason": "snapshot_content_mismatch"}
	if content.mode_by_id(snapshot.get("mode_id", "")).is_empty() or content.mode_by_id(snapshot.get("requested_mode_id", "")).is_empty(): return {"accepted": false, "reason": "unknown_snapshot_content"}
	for key: String in ["session_seed", "revision", "assignment_count", "audit_sequence", "action_step"]:
		if not snapshot.get(key) is int or snapshot.get(key, -1) < 0: return {"accepted": false, "reason": "malformed_snapshot"}
	if not snapshot.get("rng") is Dictionary or not snapshot.get("seat_states") is Array: return {"accepted": false, "reason": "malformed_snapshot"}
	var seats: Dictionary = {}
	for row: Variant in snapshot.seat_states:
		if not row is Dictionary or not row.get("seat") is int or not row.get("state") is Dictionary or seats.has(row.seat): return {"accepted": false, "reason": "malformed_snapshot"}
		var state: Dictionary = row.state
		var form: Dictionary = content.role_by_id(state.get("form_id", ""))
		if row.seat < 1 or row.seat > SeatManager.MAX_SEATS or form.is_empty() or content.role_by_id(state.get("assigned_role_id", "")).is_empty() or content.faction_by_id(state.get("faction_id", "")).is_empty():
			return {"accepted": false, "reason": "unknown_snapshot_content"}
		if not form.get("allowed_factions", []).has(state.get("faction_id", "")): return {"accepted": false, "reason": "impossible_snapshot_combination"}
		if not SocialContent.VALID_LIFECYCLES.has(state.get("lifecycle", "")) or not state.get("objective_refs") is Array: return {"accepted": false, "reason": "malformed_snapshot"}
		for objective_id: Variant in state.objective_refs:
			if not objective_id is String or content.objective_by_id(objective_id).is_empty(): return {"accepted": false, "reason": "unknown_snapshot_content"}
		for action_id: Variant in state.get("uses", {}).keys():
			if not action_id is String or content.action_by_id(action_id).is_empty() or not state.uses[action_id] is int or state.uses[action_id] < 0: return {"accepted": false, "reason": "unknown_snapshot_content"}
		seats[row.seat] = true
	var selected_mode: Dictionary = content.mode_by_id(snapshot.mode_id)
	if not selected_mode.get("supported_player_counts", []).has(seats.size()): return {"accepted": false, "reason": "impossible_snapshot_combination"}
	for array_key: String in ["pending_late_seats", "audit_history", "public_history", "last_host_payloads"]:
		if not snapshot.get(array_key) is Array: return {"accepted": false, "reason": "malformed_snapshot"}
	if not snapshot.get("transition_counts") is Dictionary or not snapshot.get("fallback_applied") is bool or not snapshot.get("fallback_message") is String or not snapshot.get("resolved_outcome") is Dictionary:
		return {"accepted": false, "reason": "malformed_snapshot"}
	return {"accepted": true, "reason": ""}

func _seat_state_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for seat_number: int in _sorted_seats(): rows.append({"seat": seat_number, "state": seat_states[seat_number].duplicate(true)})
	return rows

func _sorted_seats() -> Array[int]:
	var result: Array[int] = []
	for key: Variant in seat_states.keys(): result.append(int(key))
	result.sort()
	return result

func _roman(seat_number: int) -> String:
	return SEAT_NUMERALS[clampi(seat_number - 1, 0, SEAT_NUMERALS.size() - 1)]

func _reject(reason: String) -> Dictionary:
	last_rejection = reason
	request_rejected.emit(reason)
	return {"accepted": false, "reason": reason}

func _accept() -> Dictionary:
	return {"accepted": true, "reason": ""}

func _json_copy(value: Variant) -> Variant:
	return _normalize_json_numbers(JSON.parse_string(JSON.stringify(value)))

func _normalize_json_numbers(value: Variant) -> Variant:
	if value is float and is_equal_approx(value, round(value)): return int(value)
	if value is Array:
		var array: Array = []
		for item: Variant in value: array.append(_normalize_json_numbers(item))
		return array
	if value is Dictionary:
		var dictionary: Dictionary = {}
		for key: Variant in value: dictionary[key] = _normalize_json_numbers(value[key])
		return dictionary
	return value

func _int_array(values: Array) -> Array[int]:
	var result: Array[int] = []
	for value: Variant in values: result.append(int(value))
	return result

func _dict_array(values: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value: Variant in values: result.append(value.duplicate(true))
	return result
