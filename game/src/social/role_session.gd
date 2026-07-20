class_name RoleSession
extends SocialContent.SessionContract

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
const SEAT_SHAPES: Array[String] = [
	"Circle", "Triangle", "Square", "Diamond", "Pentagon", "Hexagon", "Star", "Crescent"
]

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


func _init(
	p_content: SocialContent = null, p_mode_id: String = "", p_seed: int = 1, seats: Array[int] = []
) -> void:
	if p_content != null:
		initialize(p_content, p_mode_id, p_seed, seats)


func initialize(
	p_content: SocialContent,
	p_mode_id: String,
	p_seed: int,
	seats: Array[int],
	rules_content: RulesContent = null,
	board_definition: BoardDefinition = null
) -> Dictionary:
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
	if not _valid_seat_roster(normalized_seats):
		return _reject("invalid_seat_roster")
	var selection: Dictionary = _select_mode(p_mode_id, normalized_seats.size())
	if not selection.accepted:
		return _reject(selection.reason)
	var selected: Dictionary = selection.mode
	var used_fallback: bool = selection.fallback
	var probe := DeterministicRng.new(derive_seed(session_seed, selected.id))
	var plan_result: Dictionary = _build_assignment_plan(selected, normalized_seats, probe)
	if not plan_result.accepted:
		return _reject(plan_result.reason)
	var state_result: Dictionary = _build_seat_states(normalized_seats, plan_result.plan)
	if not state_result.accepted:
		return _reject(state_result.reason)
	requested_mode_id = p_mode_id
	mode_id = selected.id
	rng = probe
	seat_states = state_result.states
	pending_late_seats.clear()
	fallback_applied = used_fallback
	fallback_message = (
		"Unsupported count selected authored no-secret fallback." if used_fallback else ""
	)
	resolved_outcome.clear()
	_transition_counts.clear()
	_action_step = 0
	assignment_count += 1
	revision += 1
	_record(
		"assignment",
		{
			"requested_mode_id": requested_mode_id,
			"mode_id": mode_id,
			"plan": plan_result.plan,
			"rng_before": plan_result.rng_before,
			"rng_after": rng.to_snapshot(),
			"fallback": fallback_applied,
		},
		(
			"Roles prepared for %d stable seat%s.%s"
			% [
				normalized_seats.size(),
				"" if normalized_seats.size() == 1 else "s",
				" Safe fallback active." if fallback_applied else ""
			]
		)
	)
	public_state_changed.emit(public_view())
	return {
		"accepted": true, "reason": "", "mode_id": mode_id, "fallback_applied": fallback_applied
	}


func _valid_seat_roster(seats: Array[int]) -> bool:
	if seats.is_empty() or seats.size() > SeatManager.MAX_SEATS:
		return false
	for index: int in seats.size():
		if (
			seats[index] < 1
			or seats[index] > SeatManager.MAX_SEATS
			or (index > 0 and seats[index] == seats[index - 1])
		):
			return false
	return true


func _select_mode(selected_mode_id: String, seat_count: int) -> Dictionary:
	var selected: Dictionary = content.mode_by_id(selected_mode_id)
	if selected.is_empty():
		return {"accepted": false, "reason": "unknown_social_mode"}
	var used_fallback: bool = false
	if not selected.get("supported_player_counts", []).has(seat_count):
		selected = content.mode_by_id(selected.get("fallback_mode", ""))
		if selected.is_empty() or not selected.get("supported_player_counts", []).has(seat_count):
			return {"accepted": false, "reason": "unsupported_player_count"}
		used_fallback = true
	return {"accepted": true, "reason": "", "mode": selected, "fallback": used_fallback}


func _build_seat_states(seats: Array[int], plan: Dictionary) -> Dictionary:
	var states: Dictionary = {}
	for seat: int in seats:
		var role: Dictionary = content.role_by_id(plan.get(seat, ""))
		if role.is_empty():
			return {"accepted": false, "reason": "impossible_assignment_plan"}
		states[seat] = _new_seat_state(seat, role)
	return {"accepted": true, "reason": "", "states": states}


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
	_record(
		"private_acknowledgement",
		{"seat": seat_number},
		(
			"Seat %s completed a private acknowledgement."
			% SocialContent.SessionData.roman(seat_number, SEAT_NUMERALS)
		)
	)
	private_state_changed.emit(seat_number, seat_private_view(seat_number))
	return _accept()


func set_seat_connected(seat_number: int, connected: bool) -> Dictionary:
	if not seat_states.has(seat_number):
		return _reject("seat_not_participating")
	if seat_states[seat_number].connected == connected:
		return _reject("connection_state_unchanged")
	seat_states[seat_number].connected = connected
	revision += 1
	_record(
		"connection",
		{"seat": seat_number, "connected": connected},
		(
			"Seat %s %s; stable secret ownership is reserved."
			% [
				SocialContent.SessionData.roman(seat_number, SEAT_NUMERALS),
				"reconnected" if connected else "disconnected",
			]
		)
	)
	public_state_changed.emit(public_view())
	return _accept()


func request_late_join(seat_number: int) -> Dictionary:
	if seat_number < 1 or seat_number > SeatManager.MAX_SEATS or seat_states.has(seat_number):
		return _reject("invalid_late_join")
	if pending_late_seats.has(seat_number):
		return _reject("late_join_already_deferred")
	pending_late_seats.append(seat_number)
	pending_late_seats.sort()
	_record(
		"late_join_deferred",
		{"seat": seat_number},
		"Late join deferred to an authored safe boundary."
	)
	return {"accepted": true, "reason": "", "policy": "deferred"}


func request_transition(
	seat_number: int,
	transition_id: String,
	trigger: String,
	rules: RulesSession = null,
	board: BoardState = null
) -> Dictionary:
	var validation: Dictionary = _validate_transition_request(
		seat_number, transition_id, trigger, seat_states
	)
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
	var public_message: String = (
		definition.get("presentation", {}).get("public_message", "A public social state changed.")
		if definition.visibility == "public"
		else "A private social state changed."
	)
	_record(
		"transition",
		{
			"seat": seat_number,
			"transition_id": transition_id,
			"trigger": trigger,
			"target_form": definition.target_form,
			"downstream": downstream_result,
		},
		public_message
	)
	public_state_changed.emit(public_view())
	private_state_changed.emit(seat_number, seat_private_view(seat_number))
	return {"accepted": true, "reason": "", "revision": revision, "downstream": downstream_result}


func request_transition_by_trigger(
	seat_number: int, trigger: String, rules: RulesSession = null, board: BoardState = null
) -> Dictionary:
	if not seat_states.has(seat_number):
		return _reject("seat_not_participating")
	var role: Dictionary = content.role_by_id(seat_states[seat_number].form_id)
	for transition_id: String in role.get("transition_refs", []):
		var definition: Dictionary = content.transition_by_id(transition_id)
		if definition.get("trigger", "") == trigger:
			return request_transition(seat_number, transition_id, trigger, rules, board)
	return _reject("transition_not_available")


func perform_action(
	actor_seat: int,
	action_id: String,
	targets: Array[int],
	rules: RulesSession = null,
	board: BoardState = null
) -> Dictionary:
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
				for effect: Dictionary in proposal.get("effects", []):
					effects.append(effect.duplicate(true))
			"board_mutation":
				effects.append(
					{
						"type": "board_mutation",
						"mutation": proposal.get("mutation", {}).duplicate(true)
					}
				)
			"role_transition":
				var target_seat: int = (
					actor_seat if proposal.get("target", "self") == "self" else targets[0]
				)
				var transition: Dictionary = _validate_transition_request(
					target_seat,
					proposal.get("transition_id", ""),
					content.transition_by_id(proposal.get("transition_id", "")).get("trigger", ""),
					seat_states
				)
				if not transition.accepted:
					return _reject("action_transition_rejected")
				planned_transitions.append(
					{"seat": target_seat, "definition": transition.definition}
				)
				for effect: Dictionary in transition.definition.get("downstream_effects", []):
					effects.append(effect.duplicate(true))
			"presentation":
				host_payloads.append(
					{
						"visibility": proposal.visibility,
						"message": proposal.message,
						"actor_seat": actor_seat
					}
				)
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
		_record(
			"transition",
			{
				"seat": planned.seat,
				"transition_id": planned.definition.id,
				"trigger": planned.definition.trigger,
				"target_form": planned.definition.target_form,
				"via_action": action_id,
			},
			(
				planned.definition.get("presentation", {}).get(
					"public_message", "A public social state changed."
				)
				if planned.definition.visibility == "public"
				else "A private social state changed."
			)
		)
	var public_message: String = (
		"A seat completed a private action; only its authored public consequence " + "is shown."
	)
	for payload: Dictionary in host_payloads:
		if payload.visibility == "public":
			public_message = payload.message
			break
	_record(
		"action",
		{
			"actor_seat": actor_seat,
			"action_id": action_id,
			"targets": targets,
			"downstream": downstream_result,
			"host_payloads": host_payloads
		},
		public_message
	)
	public_state_changed.emit(public_view())
	private_state_changed.emit(actor_seat, seat_private_view(actor_seat))
	return {
		"accepted": true,
		"reason": "",
		"revision": revision,
		"downstream": downstream_result,
		"public_payloads": last_host_payloads.duplicate(true)
	}


func perform_action_by_tag(
	actor_seat: int,
	action_tag: String,
	targets: Array[int],
	rules: RulesSession = null,
	board: BoardState = null
) -> Dictionary:
	if not seat_states.has(actor_seat):
		return _reject("seat_not_participating")
	var role: Dictionary = content.role_by_id(seat_states[actor_seat].form_id)
	for action_id: String in role.get("action_refs", []):
		var action: Dictionary = content.action_by_id(action_id)
		if action.get("tags", []).has(action_tag):
			return perform_action(actor_seat, action_id, targets, rules, board)
	return _reject("action_not_available")


func _projection() -> RoleDiagnostics.SessionProjection:
	return RoleDiagnostics.SessionProjection.new(
		self, VIEW_VERSION, SEAT_NUMERALS, SEAT_SHAPES, UNKNOWN_LABEL
	)


func _contract_public_view() -> Dictionary:
	return _projection().public_view()


func _contract_seat_private_view(seat_number: int) -> Dictionary:
	return _projection().seat_private_view(seat_number)


func _contract_faction_private_view(requester_seat: int) -> Dictionary:
	return _projection().faction_private_view(requester_seat)


func _contract_diagnostics_view(spoilers_enabled: bool = false) -> Dictionary:
	return _projection().diagnostics_view(spoilers_enabled)


func _contract_director_safe_signals() -> Dictionary:
	return _projection().director_safe_signals()


func evaluate_outcomes(rules: RulesSession = null, board: BoardState = null) -> Dictionary:
	return _projection().evaluate_outcomes(rules, board)


func resolve_outcomes(rules: RulesSession, board: BoardState = null) -> Dictionary:
	if not resolved_outcome.is_empty():
		return {
			"accepted": true,
			"reason": "",
			"idempotent": true,
			"outcome": resolved_outcome.duplicate(true)
		}
	var proposal: Dictionary = evaluate_outcomes(rules, board)
	var result_key: String = content.mode_by_id(mode_id).get("terminal_policy", {}).get(
		"result_key", "social_outcome"
	)
	var terminal: Dictionary = rules.complete(result_key)
	if not terminal.accepted:
		return _reject("terminal_result_rejected")
	resolved_outcome = proposal
	revision += 1
	_record(
		"outcome",
		{"outcome": resolved_outcome, "rules_terminal_reason": result_key},
		"Mixed faction and individual outcomes resolved."
	)
	public_state_changed.emit(public_view())
	return {
		"accepted": true,
		"reason": "",
		"idempotent": false,
		"outcome": resolved_outcome.duplicate(true)
	}


func _contract_privacy_report() -> Dictionary:
	return _projection().privacy_report()


func seat_with_tag(tag: String, excluded: Array[int] = []) -> int:
	for seat_number: int in SocialContent.SessionData.sorted_seats(seat_states):
		if excluded.has(seat_number):
			continue
		var role: Dictionary = content.role_by_id(seat_states[seat_number].form_id)
		if role.get("tags", []).has(tag):
			return seat_number
	return 0


func role_tags_for_seat(seat_number: int) -> Array[String]:
	if not seat_states.has(seat_number):
		return []
	var role: Dictionary = content.role_by_id(seat_states[seat_number].form_id)
	var result: Array[String] = []
	for tag: String in role.get("tags", []):
		result.append(tag)
	return result


func legal_actions(seat_number: int, rules: RulesSession = null) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not seat_states.has(seat_number):
		return result
	var state: Dictionary = seat_states[seat_number]
	if not state.get("connected", false):
		return result
	var role: Dictionary = content.role_by_id(state.form_id)
	for action_id: String in role.get("action_refs", []):
		var action: Dictionary = content.action_by_id(action_id)
		var target_search: Dictionary = _find_legal_action_targets(seat_number, action_id, rules)
		if target_search.found:
			result.append(
				{
					"action_id": action.id,
					"label": action.label,
					"description": action.description,
					"symbol": action.symbol,
					"pattern": action.pattern,
					"visibility": action.visibility
				}
			)
	return result


func _find_legal_action_targets(
	actor_seat: int, action_id: String, rules: RulesSession
) -> Dictionary:
	var action: Dictionary = content.action_by_id(action_id)
	var candidates: Array[int] = _action_target_candidates(actor_seat, action)
	var minimum_targets: int = action.get("minimum_targets", 0)
	var maximum_targets: int = mini(action.get("maximum_targets", 0), candidates.size())
	if minimum_targets == 0:
		var zero_target_validation: Dictionary = _validate_action_request(
			actor_seat, action_id, [], rules
		)
		if zero_target_validation.accepted:
			return {"found": true, "targets": []}
	if maximum_targets < maxi(1, minimum_targets):
		return {"found": false, "targets": []}
	for target_count: int in range(maxi(1, minimum_targets), maximum_targets + 1):
		var search: Dictionary = _search_action_target_combinations(
			actor_seat, action_id, rules, candidates, 0, target_count, []
		)
		if search.found:
			return search
	return {"found": false, "targets": []}


func _action_target_candidates(actor_seat: int, action: Dictionary) -> Array[int]:
	var candidates: Array[int] = []
	if not seat_states.has(actor_seat) or not seat_states[actor_seat].get("connected", false):
		return candidates
	var actor_state: Dictionary = seat_states[actor_seat]
	var target_scope: String = action.get("target_scope", "none")
	if target_scope == "none":
		return candidates
	for candidate_seat: int in SocialContent.SessionData.sorted_seats(seat_states):
		var candidate_state: Dictionary = seat_states[candidate_seat]
		if not candidate_state.get("connected", false):
			continue
		match target_scope:
			"self":
				if candidate_seat == actor_seat:
					candidates.append(candidate_seat)
			"other":
				if candidate_seat != actor_seat:
					candidates.append(candidate_seat)
			"faction_other":
				if (
					candidate_seat != actor_seat
					and candidate_state.faction_id == actor_state.faction_id
				):
					candidates.append(candidate_seat)
			"any":
				candidates.append(candidate_seat)
	return candidates


func _search_action_target_combinations(
	actor_seat: int,
	action_id: String,
	rules: RulesSession,
	candidates: Array[int],
	start_index: int,
	target_count: int,
	selected_targets: Array[int]
) -> Dictionary:
	if selected_targets.size() == target_count:
		var validation: Dictionary = _validate_action_request(
			actor_seat, action_id, selected_targets, rules
		)
		return {
			"found": validation.accepted,
			"targets": selected_targets.duplicate() if validation.accepted else []
		}
	var remaining: int = target_count - selected_targets.size()
	var final_start: int = candidates.size() - remaining
	for candidate_index: int in range(start_index, final_start + 1):
		var next_targets: Array[int] = selected_targets.duplicate()
		next_targets.append(candidates[candidate_index])
		var search: Dictionary = _search_action_target_combinations(
			actor_seat,
			action_id,
			rules,
			candidates,
			candidate_index + 1,
			target_count,
			next_targets
		)
		if search.found:
			return search
	return {"found": false, "targets": []}


func to_snapshot() -> Dictionary:
	return (
		SocialContent
		. SessionData
		. json_copy(
			{
				"snapshot_version": SNAPSHOT_VERSION,
				"scenario_id": content.scenario_id,
				"scenario_version": content.scenario_version,
				"requested_mode_id": requested_mode_id,
				"mode_id": mode_id,
				"session_seed": session_seed,
				"rng": rng.to_snapshot(),
				"revision": revision,
				"assignment_count": assignment_count,
				"seat_states": SocialContent.SessionData.seat_state_rows(seat_states),
				"pending_late_seats": pending_late_seats,
				"audit_history": audit_history,
				"public_history": public_history,
				"audit_sequence": _audit_sequence,
				"action_step": _action_step,
				"transition_counts": _transition_counts,
				"fallback_applied": fallback_applied,
				"fallback_message": fallback_message,
				"resolved_outcome": resolved_outcome,
				"last_host_payloads": last_host_payloads,
			}
		)
	)


func restore_snapshot(snapshot: Dictionary) -> Dictionary:
	snapshot = SocialContent.SessionData.json_copy(snapshot)
	var validation: Dictionary = SocialContent.SessionData.validate_snapshot(
		snapshot, content, SNAPSHOT_VERSION
	)
	if not validation.accepted:
		return _reject(validation.reason)
	var rng_probe := DeterministicRng.new(1)
	if not rng_probe.restore(snapshot.rng):
		return _reject("invalid_role_rng_snapshot")
	var next_states: Dictionary = {}
	for row: Dictionary in snapshot.seat_states:
		next_states[row.seat] = row.state.duplicate(true)
	requested_mode_id = snapshot.requested_mode_id
	mode_id = snapshot.mode_id
	session_seed = snapshot.session_seed
	rng = rng_probe
	revision = snapshot.revision
	assignment_count = snapshot.assignment_count
	seat_states = next_states
	pending_late_seats = SocialContent.SessionData.int_array(snapshot.pending_late_seats)
	audit_history = SocialContent.SessionData.dict_array(snapshot.audit_history)
	public_history = SocialContent.SessionData.dict_array(snapshot.public_history)
	_audit_sequence = snapshot.audit_sequence
	_action_step = snapshot.action_step
	_transition_counts = snapshot.transition_counts.duplicate(true)
	fallback_applied = snapshot.fallback_applied
	fallback_message = snapshot.fallback_message
	resolved_outcome = snapshot.resolved_outcome.duplicate(true)
	last_host_payloads = SocialContent.SessionData.dict_array(snapshot.last_host_payloads)
	last_rejection = "—"
	public_state_changed.emit(public_view())
	return _accept()


func _build_assignment_plan(
	mode: Dictionary, seats: Array[int], probe: DeterministicRng
) -> Dictionary:
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
		var random_result: Dictionary = _fill_random_assignment_plan(
			mode, seats.size(), available, plan, probe
		)
		if not random_result.accepted:
			return random_result
	var default_role: Dictionary = content.role_by_id(mode.get("default_role_id", ""))
	if (
		default_role.is_empty()
		or seats.size() < default_role.minimum_players
		or seats.size() > default_role.maximum_players
	):
		return {"accepted": false, "reason": "impossible_assignment_plan"}
	for seat: int in available:
		plan[seat] = default_role.id
	if plan.size() != seats.size():
		return {"accepted": false, "reason": "impossible_assignment_plan"}
	return {"accepted": true, "reason": "", "plan": plan, "rng_before": rng_before}


func _fill_random_assignment_plan(
	mode: Dictionary,
	seat_count: int,
	available: Array[int],
	plan: Dictionary,
	probe: DeterministicRng
) -> Dictionary:
	var required: int = 0
	for pool: Dictionary in mode.get("assignment_pool", []):
		required += pool.count
	if required > available.size():
		return {"accepted": false, "reason": "impossible_assignment_plan"}
	for pool: Dictionary in mode.get("assignment_pool", []):
		var role: Dictionary = content.role_by_id(pool.role_id)
		if seat_count < role.minimum_players or seat_count > role.maximum_players:
			return {"accepted": false, "reason": "impossible_assignment_plan"}
		for _index: int in pool.count:
			if available.is_empty():
				return {"accepted": false, "reason": "impossible_assignment_plan"}
			var selected_index: int = probe.draw_range(0, available.size() - 1)
			var selected_seat: int = available[selected_index]
			plan[selected_seat] = pool.role_id
			available.remove_at(selected_index)
	return _accept()


func _new_seat_state(seat_number: int, role: Dictionary) -> Dictionary:
	return {
		"seat": seat_number,
		"connected": true,
		"assigned_role_id": role.id,
		"form_id": role.id,
		"faction_id": role.starting_faction,
		"lifecycle": role.get("initial_lifecycle", "active"),
		"revealed": role.reveal_policy == "public",
		"acknowledged": false,
		"transformed": role.get("initial_lifecycle", "active") == "transformed",
		"defeated": role.get("initial_lifecycle", "active") == "afterlife",
		"escaped": false,
		"objective_refs": role.get("objective_refs", []).duplicate(),
		"uses": {},
		"last_used_round": {},
		"resources": {},
		"pending_private_prompts": [],
	}


func _validate_transition_request(
	seat_number: int, transition_id: String, trigger: String, states: Dictionary
) -> Dictionary:
	var reason: String = ""
	var state: Dictionary = states.get(seat_number, {})
	var role: Dictionary = content.role_by_id(state.get("form_id", ""))
	var definition: Dictionary = content.transition_by_id(transition_id)
	var target_role: Dictionary = content.role_by_id(definition.get("target_form", ""))
	var count_key: String = "%d:%s" % [seat_number, transition_id]
	if state.is_empty():
		reason = "seat_not_participating"
	elif not role.get("transition_refs", []).has(transition_id):
		reason = "transition_not_available"
	elif (
		definition.is_empty()
		or definition.get("trigger", "") != trigger
		or not definition.get("source_forms", []).has(state.form_id)
	):
		reason = "transition_source_mismatch"
	elif _transition_counts.get(count_key, 0) >= definition.max_chain:
		reason = "transition_chain_limit"
	elif (
		target_role.get("tags", []).has("afterlife")
		and not content.mode_by_id(mode_id).get("afterlife_enabled", true)
	):
		reason = "afterlife_disabled_by_mode"
	elif (
		target_role.is_empty()
		or target_role.get("objective_refs", []).is_empty()
		or target_role.get("action_refs", []).is_empty()
	):
		reason = "transition_would_strand_seat"
	if not reason.is_empty():
		return {"accepted": false, "reason": reason}
	return {"accepted": true, "reason": "", "definition": definition}


func _apply_transition_state(seat_number: int, definition: Dictionary) -> void:
	var state: Dictionary = seat_states[seat_number]
	var target_role: Dictionary = content.role_by_id(definition.target_form)
	state.form_id = target_role.id
	state.faction_id = target_role.starting_faction
	state.objective_refs = target_role.get("objective_refs", []).duplicate()
	var patch: Dictionary = definition.get("state_patch", {})
	for key: String in ["lifecycle", "revealed", "transformed", "defeated", "escaped"]:
		if patch.has(key):
			state[key] = patch[key]
	if target_role.reveal_policy == "public":
		state.revealed = true
	var count_key: String = "%d:%s" % [seat_number, definition.id]
	_transition_counts[count_key] = _transition_counts.get(count_key, 0) + 1


func _validate_action_request(
	actor_seat: int, action_id: String, targets: Array[int], rules: RulesSession
) -> Dictionary:
	var state: Dictionary = seat_states.get(actor_seat, {})
	var role: Dictionary = content.role_by_id(state.get("form_id", ""))
	var action: Dictionary = content.action_by_id(action_id)
	var reason: String = ""
	if state.is_empty():
		reason = "seat_not_participating"
	elif not state.get("connected", false):
		reason = "action_actor_disconnected"
	elif not role.get("action_refs", []).has(action_id):
		reason = "action_not_available"
	elif not action.get("allowed_lifecycles", []).has(state.lifecycle):
		reason = "action_lifecycle_mismatch"
	elif targets.size() < action.minimum_targets or targets.size() > action.maximum_targets:
		reason = "invalid_action_targets"
	else:
		reason = _action_target_rejection(actor_seat, state, action, targets)
	var use_limit: int = action.get("use_limit", 0)
	var round_number: int = rules.round_number if rules != null else _action_step + 1
	var last_round: int = state.get("last_used_round", {}).get(action_id, -999)
	if reason.is_empty() and use_limit > 0 and state.get("uses", {}).get(action_id, 0) >= use_limit:
		reason = "action_use_limit"
	elif reason.is_empty() and action.get("per_round_limit", 0) > 0 and last_round == round_number:
		reason = "action_round_limit"
	elif (
		reason.is_empty()
		and action.get("cooldown", 0) > 0
		and round_number < last_round + action.cooldown
	):
		reason = "action_cooldown"
	elif (
		reason.is_empty()
		and rules != null
		and not action.get("allowed_phases", []).is_empty()
		and not action.allowed_phases.has(rules.current_phase())
	):
		reason = "action_phase_mismatch"
	if not reason.is_empty():
		return {"accepted": false, "reason": reason}
	return {"accepted": true, "reason": "", "action": action}


func _action_target_rejection(
	actor_seat: int, actor_state: Dictionary, action: Dictionary, targets: Array[int]
) -> String:
	var reason: String = ""
	var unique_targets: Dictionary = {}
	for target: int in targets:
		if not seat_states.has(target) or unique_targets.has(target):
			reason = "invalid_action_targets"
		else:
			unique_targets[target] = true
			if not seat_states[target].get("connected", false):
				reason = "action_target_disconnected"
			elif action.target_scope == "none":
				reason = "invalid_action_targets"
			elif action.target_scope == "self" and target != actor_seat:
				reason = "invalid_action_targets"
			elif action.target_scope == "other" and target == actor_seat:
				reason = "invalid_action_targets"
			elif (
				action.target_scope == "faction_other"
				and (
					target == actor_seat or seat_states[target].faction_id != actor_state.faction_id
				)
			):
				reason = "invalid_action_targets"
		if not reason.is_empty():
			break
	return reason


func _preflight_effects(
	effects: Array, actor_seat: int, rules: RulesSession, board: BoardState
) -> Dictionary:
	if effects.is_empty():
		return _accept()
	if rules == null or board == null:
		return {"accepted": false, "reason": "authority_missing"}
	if rules.board_state != board:
		return {"accepted": false, "reason": "authority_mismatch"}
	var board_probe := BoardState.new(board.definition)
	if not board_probe.restore_snapshot(board.to_snapshot()).accepted:
		return {"accepted": false, "reason": "board_probe_failed"}
	var rules_probe := RulesSession.new(
		rules.content, board_probe, rules.seed, rules.participating_seats
	)
	if not rules_probe.restore_snapshot(rules.to_snapshot()).accepted:
		return {"accepted": false, "reason": "rules_probe_failed"}
	return rules_probe.apply_effect_bundle(effects, actor_seat, "social_preflight")


func _commit_effects(effects: Array, actor_seat: int, rules: RulesSession) -> Dictionary:
	if effects.is_empty():
		return {
			"accepted": true,
			"reason": "",
			"authority": "none",
			"rules_revision": -1,
			"board_revision": -1
		}
	var result: Dictionary = rules.apply_effect_bundle(effects, actor_seat, "social_role")
	if not result.accepted:
		return result
	return {
		"accepted": true,
		"reason": "",
		"authority": "RulesSession/BoardState",
		"rules_history_sequence": rules.history().size(),
		"board_revision": rules.board_state.revision if rules.board_state != null else -1
	}


func _conditions_match(
	conditions: Array, seat_number: int, faction_id: String, rules: RulesSession, board: BoardState
) -> bool:
	var matches: bool = true
	for condition: Dictionary in conditions:
		match condition.type:
			"always":
				pass
			"rules_flag":
				if rules == null or rules.flags.get(condition.flag_id) != condition.value:
					matches = false
			"rules_counter_at_least":
				if rules == null or rules.counters.get(condition.counter_id, 0) < condition.value:
					matches = false
			"board_feature":
				if (
					board == null
					or not board.get_space_state(condition.space_id).get("features", []).has(
						condition.feature_id
					)
				):
					matches = false
			"faction_count_at_least":
				var count: int = 0
				for state: Dictionary in seat_states.values():
					if state.faction_id == faction_id:
						count += 1
				if count < condition.value:
					matches = false
			"seat_state":
				if seat_states[seat_number].get(condition.key) != condition.value:
					matches = false
			"action_used":
				var used: bool = false
				for action_id: String in seat_states[seat_number].uses:
					if (
						seat_states[seat_number].uses[action_id] > 0
						and content.action_by_id(action_id).get("tags", []).has(
							condition.action_tag
						)
					):
						used = true
				if not used:
					matches = false
			"objective_complete":
				matches = false
		if not matches:
			break
	return matches


func _record(type: String, private_payload: Dictionary, public_message: String) -> void:
	_audit_sequence += 1
	var entry: Dictionary = {
		"sequence": _audit_sequence,
		"revision": revision,
		"type": type,
		"private": private_payload.duplicate(true)
	}
	audit_history.append(SocialContent.SessionData.json_copy(entry))
	if audit_history.size() > AUDIT_LIMIT:
		audit_history.pop_front()
	public_history.append(
		{
			"sequence": _audit_sequence,
			"revision": revision,
			"type": RoleDiagnostics.SessionProjection.public_history_type(type),
			"message": public_message
		}
	)
	if public_history.size() > PUBLIC_HISTORY_LIMIT:
		public_history.pop_front()
	last_rejection = "—"


func _reject(reason: String) -> Dictionary:
	last_rejection = reason
	request_rejected.emit(reason)
	return {"accepted": false, "reason": reason}
