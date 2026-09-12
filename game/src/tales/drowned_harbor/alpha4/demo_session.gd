class_name DrownedHarborDemoSession
extends RefCounted

signal changed(public_state: Dictionary)

const SAVE_VERSION: int = 4
const MAX_RECORDS: int = 256
const Content = preload("res://src/tales/drowned_harbor/alpha4/demo_content.gd")

var _authority: Authority
var _seed: int = 1
var _seats: PackedStringArray = []
var _mode: String = "cooperative"
var _records: Array[Dictionary] = []


func start(seed_value: int, seats: PackedStringArray, mode: String = "cooperative") -> Dictionary:
	if seed_value < 1 or seed_value > 2147483647 or seats.is_empty() or seats.size() > 8:
		return _reject("Choose a positive seed and between one and eight witnesses.")
	if not mode in ["cooperative", "hidden_betrayer", "outbreak"]:
		return _reject("That mode is unavailable.")
	for index: int in seats.size():
		if seats[index] != "seat_%02d" % (index + 1):
			return _reject("The stable witness roster is invalid.")
	var content_admission: Dictionary = Content.validate_content()
	if not content_admission.accepted:
		return _reject("The authored demo rules could not be validated.")
	var candidate: Dictionary = DrownedHarborAlpha3ScopedProvider.new().build_candidate()
	if not candidate.get("accepted", false):
		return _reject("The Drowned Harbor content could not be validated.")
	_authority = Authority.new(candidate, seed_value, seats, mode)
	_seed = seed_value
	_seats = seats.duplicate()
	_mode = mode
	_records.clear()
	changed.emit(public_view())
	return {"accepted": true, "reason": ""}


func choose(action_id: String, stable_seat: String) -> Dictionary:
	if _authority == null or _records.size() >= MAX_RECORDS:
		return _reject("No active Tale is available.")
	var current: Dictionary = public_view()
	if stable_seat != current.active_seat:
		return _reject("It is another witness's turn.")
	var found: bool = false
	for row: Dictionary in current.actions:
		if row.id == action_id:
			found = true
	if not found:
		return _reject("That action is no longer available. Choose a listed action.")
	var candidate: Authority = _authority.copy_authority()
	var result: Dictionary = candidate.submit_choice(action_id, stable_seat)
	if not result.get("accepted", false):
		return _reject("The action could not be committed. Your Tale is unchanged.")
	_authority = candidate
	_records.append({"kind": "choice", "action": action_id, "seat": stable_seat})
	changed.emit(public_view())
	return {"accepted": true, "reason": "", "revision": public_view().revision}


func public_view() -> Dictionary:
	if _authority == null:
		return {}
	var state: Dictionary = _authority.public_projection()
	var systems: Dictionary = state.systems
	var stage: String = systems.phase
	var names: Array = Content.STAGES[stage]
	var outcome: Dictionary = Content.outcome(systems.ending_id)
	var actions: Array[Dictionary] = _authority.player_menu()
	return {
		"stage": stage,
		"title": names[0],
		"instruction": names[1],
		"active_seat": _authority.active_player(),
		"actions": actions,
		"seats": Array(_seats),
		"mode": state.roles.effective_mode,
		"requested_mode": _mode,
		"fallback_reason": state.roles.fallback_reason,
		"revision": state.authoritative_revision,
		"terminal": stage == "complete",
		"board": state.route.board.duplicate(true),
		"resources": systems.resources,
		"inventory": systems.inventory,
		"cards": systems.hands,
		"roles": state.roles,
		"claim": systems.claim,
		"turn": systems.turn,
		"turn_limit": systems.turn_limit,
		"votes": systems.votes,
		"final_votes": systems.final_votes,
		"rescued_count": systems.rescued_count,
		"history": systems.choices,
		"outcome": outcome,
		"director": state.director,
		"director_note": systems.director_note,
		"hazards": systems.observed_hazards,
	}


func private_view(stable_seat: String) -> Dictionary:
	if _authority == null:
		return {}
	var result: Dictionary = _authority.seat_private_projection(stable_seat)
	if result.is_empty():
		return {}
	result.role_title = Content.title_for(result.role_id)
	result.objective_title = Content.title_for(result.private_objective_id)
	result.objective_text = Content.OBJECTIVES.get(
		result.private_objective_id, "Carry your witness through the final bell."
	)
	var faction: Dictionary = _authority.faction_private_projection(stable_seat)
	result.faction = faction
	result.faction_title = Content.title_for(faction.get("faction_id", "living_witness"))
	result.faction_text = (
		(
			"You believe forgetting the Harbor would destroy it again. Preserve its signal "
			+ "or memory; your public choices can serve that private purpose."
		)
		if not faction.is_empty()
		else "You owe no hidden allegiance. Decide what should come home with the crew."
	)
	result.objective_complete = _authority.objective_status(stable_seat)
	return result


func snapshot() -> Dictionary:
	if _authority == null:
		return {}
	return {
		"format": "terror_turn_drowned_harbor_demo",
		"version": SAVE_VERSION,
		"seed": _seed,
		"seats": Array(_seats),
		"mode": _mode,
		"records": _records.duplicate(true),
		"state_digest": _authority.digest(),
	}


func restore(value: Dictionary) -> Dictionary:
	var shape: Dictionary = _validate_save_shape(value)
	if not shape.accepted:
		return shape
	var pending := DrownedHarborDemoSession.new()
	var admitted: Dictionary = pending.start(
		int(value.seed), PackedStringArray(value.seats), value.mode
	)
	if not admitted.accepted:
		return admitted
	for record: Dictionary in value.records:
		var replayed: Dictionary = pending._replay_record(record)
		if not replayed.accepted:
			return _reject("Saved actions cannot be replayed. Your current Tale is unchanged.")
	if pending._authority.digest() != value.state_digest:
		return _reject("The save failed its integrity check. Your current Tale is unchanged.")
	_authority = pending._authority
	_seed = pending._seed
	_seats = pending._seats
	_mode = pending._mode
	_records = pending._records
	changed.emit(public_view())
	return {"accepted": true, "reason": ""}


func _replay_record(record: Dictionary) -> Dictionary:
	if record.kind == "choice":
		return choose(record.action, record.seat)
	if record.kind == "connection":
		return _connection(record.seat, record.action)
	return _reject("Unsupported saved event.")


func _validate_save_shape(value: Dictionary) -> Dictionary:
	var keys: Array = value.keys()
	keys.sort()
	if keys != ["format", "mode", "records", "seats", "seed", "state_digest", "version"]:
		return _reject("The save is incomplete or has unknown fields.")
	if value.format != "terror_turn_drowned_harbor_demo" or not _whole_number(value.version):
		return _reject("This save format is unsupported.")
	if int(value.version) != SAVE_VERSION or not _whole_number(value.seed):
		return _reject("This save version or seed is unsupported.")
	if not value.seats is Array or not value.mode is String or not value.records is Array:
		return _reject("The save contains invalid field types.")
	var valid: bool = value.state_digest is String and value.records.size() <= MAX_RECORDS
	valid = valid and str(value.state_digest).length() == 64
	for seat: Variant in value.seats:
		valid = valid and seat is String
	for raw: Variant in value.records:
		if not raw is Dictionary:
			valid = false
		else:
			valid = valid and raw.size() == 3 and raw.get("kind") is String
			valid = valid and raw.get("action") is String and raw.get("seat") is String
	return (
		{"accepted": true, "reason": ""} if valid else _reject("Invalid saved roster or history.")
	)


func disconnect_seat(stable_seat: String) -> Dictionary:
	return _connection(stable_seat, "disconnect")


func reconnect_seat(stable_seat: String) -> Dictionary:
	return _connection(stable_seat, "reconnect")


func assign_surrogate_control(stable_seat: String) -> Dictionary:
	return _connection(stable_seat, "surrogate")


func _connection(stable_seat: String, kind: String) -> Dictionary:
	if _authority == null or not _seats.has(stable_seat) or _records.size() >= MAX_RECORDS:
		return _reject("That witness is unavailable.")
	if not kind in ["disconnect", "reconnect", "surrogate"]:
		return _reject("That connection change is unavailable.")
	var candidate: Authority = _authority.copy_authority()
	var result: Dictionary = candidate.connection_change(stable_seat, kind)
	if not result.accepted:
		return _reject("The connection change could not be committed.")
	_authority = candidate
	_records.append({"kind": "connection", "action": kind, "seat": stable_seat})
	changed.emit(public_view())
	return {"accepted": true, "reason": ""}


static func _whole_number(value: Variant) -> bool:
	return value is int or value is float and is_finite(value) and value == floor(value)


static func _reject(reason: String) -> Dictionary:
	return {"accepted": false, "reason": reason}


class Route:
	extends DrownedHarborAlpha2Session

	func travel(seat: String, destination: String) -> Dictionary:
		if _board.position_for(seat) == destination:
			return {"accepted": true, "reason": ""}
		return _board.move_to(seat, destination)

	func adopt_trusted(value: Dictionary) -> void:
		var result: Dictionary = _adopt_snapshot(value)
		assert(result.accepted)


class Authority:
	extends DrownedHarborAlpha3Session

	func _init(
		candidate: Dictionary, seed_value: int, seats: PackedStringArray, mode: String
	) -> void:
		super(candidate, seed_value, seats, mode)
		_rules = Content.Rules.new(seed_value, seats)
		_route = Route.new(candidate.alpha2_candidate, seed_value, seats)
		_role = DemoRoles.new(seed_value, seats, mode)

	func copy_authority() -> Authority:
		var result := Authority.new(
			_candidate, _seed, PackedStringArray(_stable_seat_order), _role.effective_mode()
		)
		result.adopt_trusted(to_snapshot())
		return result

	func adopt_trusted(state: Dictionary) -> void:
		var adopted: Dictionary = _adopt_snapshot(state)
		assert(adopted.accepted)
		var route := Route.new(
			_candidate.alpha2_candidate, _seed, PackedStringArray(_stable_seat_order)
		)
		route.adopt_trusted(state.route)
		_route = route

	func digest() -> String:
		return JSON.stringify(to_snapshot(), "", true).sha256_text()

	func active_player() -> String:
		return (_rules as Content.Rules).active_seat()

	func player_menu() -> Array[Dictionary]:
		var form: String = "living"
		for seat: Dictionary in _role.public_view().seats:
			if seat.stable_seat_id == active_player():
				if not seat.connected:
					return []
				form = seat.public_form
		var result: Array[Dictionary] = (_rules as Content.Rules).menu()
		if Content.CONTINUATION_FORMS.has(form) and (_rules as Content.Rules).phase() == "flood":
			var row: Dictionary = Content.ACTIONS.restless_warn
			result.push_front({"id": "restless_warn", "label": row.label, "detail": row.detail})
		for row: Dictionary in result:
			if Content.ACTIONS[row.id].get("social", "") == "bargain":
				row.detail = _bargain_detail()
		return result

	func _bargain_detail() -> String:
		var rules: Content.Rules = _rules
		if _role.effective_mode() != "outbreak":
			return "Take supplies without changing form. Gain 3 oil; Harbor claim rises by 3."
		if not _role.tidebound_conversion_id().is_empty():
			return "The Harbor's one binding is spent. Take 3 oil; Harbor claim rises by 3."
		if rules.discovered.has("refuse_bargain:" + active_player()):
			return "Accept the binding you once refused: become Tidebound, gain 3 oil, and raise claim by 3."
		return (
			"Take 3 oil without changing form; claim rises by 3. "
			+ "Refusing first unlocks a later binding bargain."
		)

	func objective_status(seat: String) -> bool:
		var own: Dictionary = _role.seat_private_view(seat)
		if own.is_empty() or (_rules as Content.Rules).phase() != "complete":
			return false
		var state: Dictionary = _rules.public_view()
		state.seat_count = _stable_seat_order.size()
		return Content.conditions_met(
			state, Content.OBJECTIVE_CONDITIONS.get(own.private_objective_id, [])
		)

	func connection_change(seat: String, kind: String) -> Dictionary:
		match kind:
			"disconnect":
				return disconnect_seat(seat)
			"surrogate":
				return assign_surrogate_control(seat)
			_:
				return reconnect_seat(seat)

	func submit_choice(action: String, seat: String) -> Dictionary:
		return process_request(
			{
				"request_id": "demo_request_%d" % (_revision + 1),
				"event_id": "demo_event_%d" % (_revision + 1),
				"actor": "developer_alpha3_gate",
				"stable_seat_id": seat,
				"source_revision": _revision,
				"intent": "alpha4_choice",
				"payload": {"action": action}
			}
		)

	func _dispatch(request: Dictionary) -> Dictionary:
		var before: Dictionary = to_snapshot()
		var result: Dictionary = _dispatch_choice(request)
		if not result.get("accepted", false):
			adopt_trusted(before)
		return result

	func _dispatch_choice(request: Dictionary) -> Dictionary:
		if request.intent != "alpha4_choice" or request.payload.keys() != ["action"]:
			return {"accepted": false, "reason": "unsupported_demo_request"}
		var rules: Content.Rules = _rules
		var action: String = request.payload.action
		var seat: String = request.stable_seat_id
		if (
			not rules.available(action, seat)
			or not player_menu().any(func(option: Dictionary) -> bool: return option.id == action)
		):
			return {"accepted": false, "reason": "choice_unavailable"}
		var phase_before: String = rules.phase()
		var row: Dictionary = Content.ACTIONS[action]
		var prepared: Dictionary = _prepare_choice(row, action, seat, phase_before)
		if not prepared.accepted:
			return prepared
		var transition: Dictionary = _phase_transition(phase_before, rules.phase())
		if not transition.accepted:
			return transition
		var social_result: Dictionary = _apply_social_effects(seat, row, rules)
		if not social_result.accepted:
			return social_result
		if phase_before != rules.phase():
			_apply_director(rules)
		if rules.phase() == "complete":
			(_role as DemoRoles).evaluate_objectives(rules.public_view())
		return {
			"accepted": true,
			"reason": "",
			"event_key": "alpha4_choice_committed",
			"public_payload": {"label": row.label, "phase": phase_before, "seat": seat}
		}

	func _prepare_choice(
		row: Dictionary, action: String, seat: String, phase_before: String
	) -> Dictionary:
		var rules: Content.Rules = _rules
		if row.has("destination"):
			var destination: String = row.destination
			if phase_before == "low_tide" and destination == "bellhouse":
				destination = "low_tide_market"
			elif phase_before == "flood" and destination == "low_tide_market":
				destination = "high_water_channel"
			var travel: Dictionary = (_route as Route).travel(seat, destination)
			if not travel.accepted:
				return travel
		var route_result: Dictionary = _route_action(phase_before, seat)
		if not route_result.accepted:
			return route_result
		var committed: Dictionary = rules.apply_choice(action, seat)
		if not committed.accepted:
			return committed
		if row.get("rescue", false):
			var target: String = "resident_%d" % (_revision + 1)
			var registered: Dictionary = rules.register_stranded_target("authored_resident", target)
			if not registered.accepted:
				return registered
			var rescued: Dictionary = rules.attempt_rescue(target)
			if not rescued.accepted:
				return rescued
		return {"accepted": true, "reason": ""}

	func _route_action(phase: String, seat: String) -> Dictionary:
		for operation: Dictionary in Content.ROUTE_ACTIONS.get(phase, []):
			var actor: String = (
				_stable_seat_order[0] if operation.get("first_seat", false) else seat
			)
			var result: Dictionary = _route_request(
				operation.intent, operation.get("payload", {}), actor
			)
			if not result.accepted:
				return result
		return {"accepted": true, "reason": ""}

	func _phase_transition(before: String, after: String) -> Dictionary:
		if before == after:
			return {"accepted": true, "reason": ""}
		var owner: String = _stable_seat_order[0]
		match before:
			"low_tide":
				for seat: String in _stable_seat_order:
					var moved: Dictionary = _route_request(
						"move_to_landmark", {"destination": "bellhouse"}, seat
					)
					if not moved.accepted:
						return moved
				return _route_request("confirm_low_tide_arrival", {}, owner)
			"council":
				return _route_request("resolve_council_commitment", {}, owner)
			"last_light":
				return _route_request("resolve_last_light", {}, owner)
		return {"accepted": true, "reason": ""}

	func _route_request(intent: String, payload: Dictionary, seat: String) -> Dictionary:
		var route_revision: int = _route.to_snapshot().authoritative_revision
		return _forward_route_request(
			{
				"request_id": "demo_inner_%d_%d" % [_revision, route_revision],
				"event_id": "demo_inner_event_%d_%d" % [_revision, route_revision],
				"stable_seat_id": seat,
				"intent": intent,
				"payload": payload
			}
		)

	func _apply_director(rules: Content.Rules) -> void:
		if rules.phase() not in ["bellhouse", "high_water", "flood", "last_light"]:
			return
		var proposal := DrownedHarborAlpha3DirectorAuthority.new(_seed)
		if not proposal.restore_snapshot(_director.to_snapshot()).accepted:
			return
		var selected: Dictionary = proposal.select_candidate(
			director_safe_input(), DIRECTOR_CANDIDATES
		)
		if selected.accepted and rules.apply_director_candidate(selected.candidate_id).accepted:
			_director = proposal

	func _apply_social_effects(seat: String, row: Dictionary, rules: Content.Rules) -> Dictionary:
		var social: String = row.get("social", "")
		if social == "reveal":
			return (_role as DemoRoles).declare_allegiance(seat)
		if social in ["bargain", "refuse"] and _role.effective_mode() == "outbreak":
			var offer_result: Dictionary = _apply_offer_choice(seat, social, rules)
			if not offer_result.accepted:
				return offer_result
		var form: String = ""
		for public_seat: Dictionary in _role.public_view().seats:
			if public_seat.stable_seat_id == seat:
				form = public_seat.public_form
		if rules.phase() == "flood" and rules.claim >= 6 and form == "living":
			if _role.continuation_transition_id().is_empty():
				var registered: Dictionary = rules.register_stranded_target("stable_seat", seat)
				if not registered.accepted:
					return registered
				return _role.apply_defeat_continuation(
					seat, "high_water_v1", rules.replacement_route_available(), true, _revision + 1
				)
		return {"accepted": true, "reason": ""}

	func _apply_offer_choice(seat: String, social: String, rules: Content.Rules) -> Dictionary:
		# Public action history, not secret objectives or factions, determines the cadence.
		var refused: bool = rules.discovered.has("refuse_bargain:" + seat)
		var binding_available: bool = _role.tidebound_conversion_id().is_empty()
		if social == "bargain" and (not refused or not binding_available):
			return {"accepted": true, "reason": ""}
		if social == "refuse" and not binding_available:
			return {"accepted": true, "reason": ""}
		var offered: Dictionary = _role.offer_tidebound(seat, "authored_bargain", true)
		if not offered.accepted:
			return offered
		if social == "refuse":
			return _role.refuse_tidebound(seat)
		return _role.resolve_tidebound(seat, _revision + 1)


class DemoRoles:
	extends DrownedHarborAlpha3RoleAuthority

	func mark_objectives_complete() -> void:
		# Alpha.4 completion is evaluated from authored predicates at the epilogue boundary.
		pass

	func declare_allegiance(seat: String) -> Dictionary:
		if not _seats.has(seat) or not _seats[seat].connected:
			return {"accepted": false, "reason": "seat_unavailable"}
		_seats[seat].faction_revealed = true
		return {"accepted": true, "reason": ""}

	func evaluate_objectives(public_state: Dictionary) -> void:
		var state: Dictionary = public_state.duplicate(true)
		state.seat_count = _stable_seat_order.size()
		for seat: String in _stable_seat_order:
			var row: Dictionary = _seats[seat]
			var conditions: Array = Content.OBJECTIVE_CONDITIONS.get(row.private_objective_id, [])
			row.objective_complete = Content.conditions_met(state, conditions)

	func public_view() -> Dictionary:
		var result: Dictionary = super()
		for row: Dictionary in result.seats:
			var own: Dictionary = _seats[row.stable_seat_id]
			if own.faction_revealed:
				row.revealed_allegiance = (
					"Living"
					if own.private_faction_id.is_empty()
					else Content.title_for(own.private_faction_id)
				)
		return result
