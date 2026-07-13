class_name RulesSession
extends RefCounted

signal presentation_requested(payload: Dictionary)
signal state_changed(change: Dictionary)
signal submission_rejected(reason: String)

const SNAPSHOT_VERSION: int = 1
const HISTORY_LIMIT: int = 128
const EVENT_CHAIN_LIMIT: int = 16

enum TerminalState { RUNNING, COMPLETED, FAILED, ABORTED }

var content: RulesContent
var board_state: BoardState
var session_id: String
var seed: int
var rng: DeterministicRng
var round_number: int = 1
var phase_index: int = 0
var phase_revision: int = 1
var terminal_state: TerminalState = TerminalState.RUNNING
var terminal_reason: String = ""
var participating_seats: Array[int] = []
var pending_late_seats: Array[int] = []
var seat_connection: Dictionary = {}
var ready_seats: Array[int] = []
var passed_seats: Array[int] = []
var pending_prompt: Dictionary = {}
var event_queue: Array[String] = []
var current_event_id: String = ""
var event_chain_steps: int = 0
var resolved_event_rounds: Dictionary = {}
var counters: Dictionary = {}
var flags: Dictionary = {}
var result_flags: Dictionary = {}
var draw_pile: Array[Dictionary] = []
var hands: Dictionary = {}
var discard_pile: Array[Dictionary] = []
var exhausted_pile: Array[Dictionary] = []
var removed_pile: Array[Dictionary] = []
var inventory: Dictionary = {}
var active_vote: Dictionary = {}
var recent_check: Dictionary = {}
var recent_effects: Array[Dictionary] = []
var last_rejection: String = "—"
var _history: Array[Dictionary] = []
var _history_sequence: int = 0
var _card_instance_sequence: int = 0

func _init(p_content: RulesContent = null, p_board_state: BoardState = null, p_seed: int = 1, seats: Array[int] = []) -> void:
	if p_content != null:
		initialize(p_content, p_board_state, p_seed, seats)

func initialize(p_content: RulesContent, p_board_state: BoardState, p_seed: int, seats: Array[int]) -> PackedStringArray:
	var failures: PackedStringArray = p_content.validate(p_board_state.definition if p_board_state != null else null)
	if seats.is_empty() or seats.size() > SeatManager.MAX_SEATS:
		failures.append("participating seats must contain 1–8 seats")
	var unique: Dictionary = {}
	for seat_number: int in seats:
		if seat_number < 1 or seat_number > SeatManager.MAX_SEATS or unique.has(seat_number):
			failures.append("invalid participating seat")
		unique[seat_number] = true
	if not failures.is_empty():
		return failures
	content = p_content
	board_state = p_board_state
	seed = p_seed
	rng = DeterministicRng.new(seed)
	session_id = "%s-%d-%d" % [content.scenario_id, content.scenario_version, rng.initial_seed]
	participating_seats = seats.duplicate()
	participating_seats.sort()
	for seat_number: int in participating_seats:
		seat_connection[seat_number] = true
		hands[seat_number] = []
		inventory[seat_number] = []
	_build_deck()
	_record("session_started", {"seats": participating_seats, "seed": rng.initial_seed})
	return failures

func current_phase() -> String:
	return content.phases[phase_index] if content != null and phase_index < content.phases.size() else ""

func authority_revision() -> int:
	return _history_sequence

func companion_public_view() -> Dictionary:
	var prompt_view: Dictionary = {}
	if not pending_prompt.is_empty():
		var response_status: Array[Dictionary] = []
		for seat_number: int in pending_prompt.get("eligible_seats", []):
			response_status.append({"seat": seat_number, "submitted": pending_prompt.get("responses", {}).has(seat_number)})
		if pending_prompt.get("scope", "all") == "single":
			prompt_view = {"active": true, "private": true, "response_status": response_status}
		else:
			var options: Array[Dictionary] = []
			for option: Dictionary in pending_prompt.get("options", []):
				options.append({"id": option.get("id", ""), "label": option.get("text", ""), "symbol": option.get("symbol", "")})
			prompt_view = {
				"id": pending_prompt.get("id", ""), "revision": pending_prompt.get("revision", 0),
				"options": options, "eligible_seats": pending_prompt.get("eligible_seats", []).duplicate(),
				"response_status": response_status, "allow_pass": pending_prompt.get("allow_pass", false),
			}
	return _normalize_json_numbers({
		"view_version": 1, "round": round_number, "phase": current_phase(), "phase_revision": phase_revision,
		"authority_revision": authority_revision(), "terminal": terminal_state != TerminalState.RUNNING,
		"terminal_reason": terminal_reason, "participating_seats": participating_seats.duplicate(),
		"connected_seats": participating_seats.filter(func(seat_number: int) -> bool: return seat_connection.get(seat_number, false)),
		"prompt": prompt_view,
	})

func companion_seat_view(seat_number: int) -> Dictionary:
	if not participating_seats.has(seat_number):
		return {"accepted": false, "reason": "seat_not_authorized"}
	var prompt_view: Dictionary = {}
	if not pending_prompt.is_empty() and pending_prompt.get("eligible_seats", []).has(seat_number):
		var options: Array[Dictionary] = []
		for option: Dictionary in pending_prompt.get("options", []):
			options.append({"id": option.get("id", ""), "label": option.get("text", ""), "symbol": option.get("symbol", "")})
		prompt_view = {
			"id": pending_prompt.get("id", ""), "revision": pending_prompt.get("revision", 0),
			"options": options, "allow_pass": pending_prompt.get("allow_pass", false),
			"submitted": pending_prompt.get("responses", {}).has(seat_number),
		}
	var hand_view: Array[Dictionary] = []
	for instance: Dictionary in hands.get(seat_number, []):
		var definition: Dictionary = content.card_by_id(instance.get("definition_id", ""))
		hand_view.append({
			"instance_id": instance.get("instance_id", ""), "label": definition.get("label", definition.get("name", "Card")),
			"description": definition.get("description", ""), "symbol": definition.get("symbol", ""),
		})
	var inventory_view: Array[Dictionary] = []
	for item_id: String in inventory.get(seat_number, []):
		var item: Dictionary = content.item_by_id(item_id)
		inventory_view.append({"id": item_id, "label": item.get("label", item.get("name", item_id.capitalize())), "symbol": item.get("symbol", "")})
	return _normalize_json_numbers({
		"accepted": true, "view_version": 1, "authorized_seat": seat_number, "prompt": prompt_view,
		"hand": hand_view, "inventory": inventory_view,
	})

func transition_phase(expected_revision: int = -1) -> Dictionary:
	if terminal_state != TerminalState.RUNNING:
		return _reject("session_terminal")
	if expected_revision >= 0 and expected_revision != phase_revision:
		return _reject("stale_phase_revision")
	if not pending_prompt.is_empty():
		return _reject("prompt_pending")
	phase_index += 1
	if phase_index >= content.phases.size():
		phase_index = 0
		round_number += 1
		_activate_late_seats()
	phase_revision += 1
	ready_seats.clear()
	passed_seats.clear()
	_record("phase_changed", {"round": round_number, "phase": current_phase(), "revision": phase_revision})
	return _accept()

func set_seat_connected(seat_number: int, connected: bool) -> Dictionary:
	if not participating_seats.has(seat_number):
		return _reject("seat_not_participating")
	seat_connection[seat_number] = connected
	_record("seat_connection", {"seat": seat_number, "connected": connected})
	return _accept()

func request_late_join(seat_number: int) -> Dictionary:
	if seat_number < 1 or seat_number > SeatManager.MAX_SEATS or participating_seats.has(seat_number) or pending_late_seats.has(seat_number):
		return _reject("invalid_late_join")
	pending_late_seats.append(seat_number)
	pending_late_seats.sort()
	_record("late_join_queued", {"seat": seat_number, "starts_round": round_number + 1})
	return _accept()

func mark_ready(seat_number: int, pass_turn: bool = false, expected_revision: int = -1) -> Dictionary:
	if expected_revision >= 0 and expected_revision != phase_revision:
		return _reject("stale_phase_revision")
	if not participating_seats.has(seat_number):
		return _reject("seat_not_participating")
	if ready_seats.has(seat_number):
		return _reject("duplicate_submission")
	ready_seats.append(seat_number)
	ready_seats.sort()
	if pass_turn:
		passed_seats.append(seat_number)
		passed_seats.sort()
	_record("seat_passed" if pass_turn else "seat_ready", {"seat": seat_number, "phase_revision": phase_revision})
	return _accept()

func open_prompt(definition: Dictionary, eligible_seats: Array[int], source_id: String = "") -> Dictionary:
	if not pending_prompt.is_empty():
		return _reject("prompt_already_pending")
	var failures := PackedStringArray()
	content._validate_prompt(definition, failures)
	if not failures.is_empty():
		return _reject("malformed_prompt")
	var eligible: Array[int] = eligible_seats.duplicate()
	eligible.sort()
	for seat_number: int in eligible:
		if not participating_seats.has(seat_number):
			return _reject("ineligible_prompt_seat")
	pending_prompt = definition.duplicate(true)
	pending_prompt.merge({"revision": phase_revision, "eligible_seats": eligible, "responses": {}, "source_id": source_id}, true)
	_record("prompt_opened", {"prompt_id": definition.id, "eligible_seats": eligible, "source_id": source_id})
	return _accept()

func submit_response(seat_number: int, option_ids: Array[String], prompt_revision: int) -> Dictionary:
	if pending_prompt.is_empty():
		return _reject("no_prompt_pending")
	if prompt_revision != pending_prompt.revision:
		return _reject("stale_prompt_revision")
	if not pending_prompt.eligible_seats.has(seat_number):
		return _reject("unauthorized_response")
	if pending_prompt.responses.has(seat_number):
		return _reject("duplicate_submission")
	if option_ids.is_empty() and pending_prompt.get("allow_pass", false):
		pass
	elif option_ids.size() < pending_prompt.min_selections or option_ids.size() > pending_prompt.max_selections:
		return _reject("selection_count_out_of_range")
	var valid_ids: Array[String] = []
	for option: Dictionary in pending_prompt.options:
		valid_ids.append(option.id)
	var unique: Dictionary = {}
	for option_id: String in option_ids:
		if not valid_ids.has(option_id) or unique.has(option_id):
			return _reject("invalid_prompt_option")
		unique[option_id] = true
	pending_prompt.responses[seat_number] = option_ids.duplicate()
	_record("prompt_response", {"prompt_id": pending_prompt.id, "seat": seat_number, "options": option_ids})
	return _accept()

func resolve_prompt() -> Dictionary:
	if pending_prompt.is_empty():
		return _reject("no_prompt_pending")
	if pending_prompt.responses.size() < pending_prompt.eligible_seats.size():
		return _reject("responses_incomplete")
	var counts: Dictionary = {}
	for seat_number: int in pending_prompt.eligible_seats:
		for option_id: String in pending_prompt.responses[seat_number]:
			counts[option_id] = counts.get(option_id, 0) + 1
	var winners: Array[String] = []
	var highest: int = -1
	for option: Dictionary in pending_prompt.options:
		var count: int = counts.get(option.id, 0)
		if count > highest:
			highest = count
			winners = [option.id]
		elif count == highest:
			winners.append(option.id)
	winners.sort()
	var result: Dictionary = {"accepted": true, "prompt_id": pending_prompt.id, "winner": winners[0] if not winners.is_empty() else "pass", "counts": counts, "tie": winners.size() > 1, "responses": pending_prompt.responses.duplicate(true)}
	if result.winner != "pass":
		for option: Dictionary in pending_prompt.options:
			if option.id == result.winner and not option.get("effects", []).is_empty():
				var effects_result: Dictionary = apply_effect_bundle(option.effects, 0, pending_prompt.source_id)
				if not effects_result.accepted:
					return effects_result
	_record("prompt_resolved", result)
	pending_prompt.clear()
	return result

func open_vote(definition: Dictionary, eligible_seats: Array[int]) -> Dictionary:
	var prompt: Dictionary = definition.duplicate(true)
	prompt["min_selections"] = 0 if prompt.get("allow_abstain", false) else 1
	prompt["max_selections"] = 1
	prompt["allow_pass"] = prompt.get("allow_abstain", false)
	var result: Dictionary = open_prompt(prompt, eligible_seats, prompt.get("source_id", "vote"))
	if result.accepted:
		active_vote = {"id": prompt.id, "rule": prompt.get("rule", "plurality"), "quorum": prompt.get("quorum", 1), "tie_policy": prompt.get("tie_policy", "stable_option_id"), "revision": phase_revision}
	return result

func resolve_vote() -> Dictionary:
	if active_vote.is_empty() or pending_prompt.is_empty():
		return _reject("no_vote_pending")
	var submitted: int = pending_prompt.responses.size()
	if submitted < active_vote.quorum:
		return _reject("vote_quorum_not_met")
	var result: Dictionary = resolve_prompt()
	if result.accepted:
		result["quorum_met"] = true
		result["rule"] = active_vote.rule
		result["tie_policy"] = active_vote.tie_policy
		_record("vote_resolved", result)
		active_vote.clear()
	return result

func resolve_check(definition: Dictionary, acting_seat: int = 0, source_id: String = "") -> Dictionary:
	var validation: Dictionary = _validate_check(definition)
	if not validation.valid:
		return _reject(validation.reason)
	var counter_before: int = rng.counter
	var rolls: Array[int] = []
	for _index: int in definition.dice:
		rolls.append(rng.draw_range(1, definition.sides))
	rolls.sort()
	if definition.get("advantage", 0) != 0 and rolls.size() > 1:
		rolls = [rolls[-1] if definition.advantage > 0 else rolls[0]]
	var modifier: int = definition.get("modifier", 0) + counters.get(definition.get("modifier_counter", ""), 0)
	var total: int = rolls.reduce(func(sum: int, value: int) -> int: return sum + value, 0) + modifier
	var outcome: String = "failure"
	var bands: Dictionary = definition.get("bands", {"success": definition.get("target", 1)})
	var ordered: Array[String] = ["critical", "success", "partial"]
	for band: String in ordered:
		if bands.has(band) and total >= bands[band]:
			outcome = band
			break
	recent_check = {"source_id": source_id, "acting_seat": acting_seat, "raw": rolls, "modifier": modifier, "total": total, "outcome": outcome, "rng_before": counter_before, "rng_after": rng.counter}
	_record("check_resolved", recent_check)
	return {"accepted": true, "result": recent_check.duplicate(true)}

func queue_event(event_id: String) -> Dictionary:
	if content.event_by_id(event_id).is_empty():
		return _reject("unknown_event")
	event_queue.append(event_id)
	_record("event_queued", {"event_id": event_id, "position": event_queue.size() - 1})
	return _accept()

func resolve_next_event() -> Dictionary:
	if event_queue.is_empty():
		return _reject("event_queue_empty")
	if event_chain_steps >= EVENT_CHAIN_LIMIT:
		return _reject("event_chain_limit")
	current_event_id = event_queue.pop_front()
	var event: Dictionary = content.event_by_id(current_event_id)
	if event.get("once", false) and resolved_event_rounds.has(current_event_id):
		return _reject("event_already_resolved")
	if event.get("repeatability", "") == "cooldown_rounds" and resolved_event_rounds.has(current_event_id) and round_number - resolved_event_rounds[current_event_id] < event.get("cooldown", 0):
		return _reject("event_on_cooldown")
	if not _conditions_met(event.get("conditions", []), 0):
		return _reject("event_ineligible")
	event_chain_steps += 1
	var presenter: Dictionary = event.get("presenter", {}).duplicate(true)
	presenter.merge({"event_id": current_event_id, "title": event.get("title", ""), "body": event.get("body", "")}, true)
	presentation_requested.emit(presenter)
	_record("event_presented", presenter)
	if not event.get("effects", []).is_empty():
		var applied: Dictionary = apply_effect_bundle(event.effects, 0, current_event_id)
		if not applied.accepted:
			return applied
	if event.has("check"):
		var check_result: Dictionary = resolve_check(event.check, event.get("acting_seat", 0), current_event_id)
		if not check_result.accepted:
			return check_result
		var outcome_effects: Array = event.get("outcome_effects", {}).get(check_result.result.outcome, [])
		if not outcome_effects.is_empty():
			var outcome_applied: Dictionary = apply_effect_bundle(outcome_effects, event.get("acting_seat", 0), current_event_id)
			if not outcome_applied.accepted:
				return outcome_applied
	for follow_up: String in event.get("follow_ups", []):
		event_queue.append(follow_up)
	if not event.get("prompts", []).is_empty():
		var prompt: Dictionary = event.prompts[0]
		var eligible: Array[int] = participating_seats.duplicate()
		if prompt.get("scope", "all") == "single":
			eligible = [prompt.get("seat", participating_seats[0])]
		open_prompt(prompt, eligible, current_event_id)
	resolved_event_rounds[current_event_id] = round_number
	_record("event_resolved", {"event_id": current_event_id, "chain_step": event_chain_steps})
	return _accept()

func draw_card(seat_number: int, count: int = 1) -> Dictionary:
	if not participating_seats.has(seat_number) or count < 1 or draw_pile.size() < count:
		return _reject("invalid_draw")
	for _index: int in count:
		hands[seat_number].append(draw_pile.pop_back())
	_record("cards_drawn", {"seat": seat_number, "count": count})
	return _accept()

func play_card(seat_number: int, instance_id: String, targets: Array[int] = []) -> Dictionary:
	if not participating_seats.has(seat_number):
		return _reject("card_wrong_owner")
	var card_instance: Dictionary = _card_in_hand(seat_number, instance_id)
	if card_instance.is_empty():
		return _reject("card_not_in_hand")
	var definition: Dictionary = content.card_by_id(card_instance.definition_id)
	if not _conditions_met(definition.get("conditions", []), seat_number):
		return _reject("card_wrong_timing")
	var target_count: int = definition.get("target_count", 0)
	if targets.size() != target_count or targets.any(func(target: int) -> bool: return not participating_seats.has(target)):
		return _reject("invalid_card_targets")
	var applied: Dictionary = apply_effect_bundle(definition.effects, seat_number, definition.id)
	if not applied.accepted:
		return applied
	if definition.policy != "retain":
		hands[seat_number].erase(card_instance)
		var zone: Array[Dictionary] = discard_pile
		if definition.policy == "exhaust": zone = exhausted_pile
		elif definition.policy == "remove": zone = removed_pile
		zone.append(card_instance)
	_record("card_played", {"seat": seat_number, "instance_id": instance_id, "card_id": definition.id, "targets": targets, "policy": definition.policy})
	return _accept()

func move_card_from_hand(seat_number: int, instance_id: String, destination: String) -> Dictionary:
	var card: Dictionary = _card_in_hand(seat_number, instance_id)
	if card.is_empty() or not ["discard", "exhausted", "removed"].has(destination):
		return _reject("invalid_card_zone_move")
	hands[seat_number].erase(card)
	if destination == "discard": discard_pile.append(card)
	elif destination == "exhausted": exhausted_pile.append(card)
	else: removed_pile.append(card)
	_record("card_zone_changed", {"seat": seat_number, "instance_id": instance_id, "destination": destination})
	return _accept()

func apply_effect_bundle(effects: Array, actor_seat: int = 0, source_id: String = "") -> Dictionary:
	var validation: Dictionary = _validate_effect_bundle(effects, actor_seat)
	if not validation.valid:
		return _reject(validation.reason)
	for effect: Dictionary in effects:
		_apply_effect(effect, actor_seat)
		recent_effects.append({"source_id": source_id, "actor_seat": actor_seat, "effect": effect.duplicate(true)})
		if recent_effects.size() > 12:
			recent_effects.pop_front()
	_record("effects_applied", {"source_id": source_id, "actor_seat": actor_seat, "count": effects.size()})
	return _accept()

func complete(result: String, failed: bool = false) -> Dictionary:
	if terminal_state != TerminalState.RUNNING:
		return _reject("session_terminal")
	terminal_state = TerminalState.FAILED if failed else TerminalState.COMPLETED
	terminal_reason = result
	_record("session_terminal", {"state": terminal_state, "reason": result})
	return _accept()

func history() -> Array[Dictionary]:
	return _history.duplicate(true)

func to_snapshot() -> Dictionary:
	var snapshot: Dictionary = {
		"snapshot_version": SNAPSHOT_VERSION, "scenario_id": content.scenario_id, "scenario_version": content.scenario_version,
		"session_id": session_id, "seed": seed, "rng": rng.to_snapshot(), "round": round_number, "phase_index": phase_index,
		"phase_revision": phase_revision, "terminal_state": terminal_state, "terminal_reason": terminal_reason,
		"participating_seats": participating_seats.duplicate(), "pending_late_seats": pending_late_seats.duplicate(), "seat_connection": _seat_value_rows(seat_connection),
		"ready_seats": ready_seats.duplicate(), "passed_seats": passed_seats.duplicate(), "pending_prompt": _prompt_snapshot(),
		"event_queue": event_queue.duplicate(), "current_event_id": current_event_id, "event_chain_steps": event_chain_steps, "resolved_event_rounds": resolved_event_rounds.duplicate(true),
		"counters": counters.duplicate(true), "flags": flags.duplicate(true), "result_flags": result_flags.duplicate(true),
		"draw_pile": draw_pile.duplicate(true), "hands": _seat_value_rows(hands), "discard": discard_pile.duplicate(true), "exhausted": exhausted_pile.duplicate(true), "removed": removed_pile.duplicate(true),
		"inventory": _seat_value_rows(inventory), "active_vote": active_vote.duplicate(true), "recent_check": recent_check.duplicate(true), "recent_effects": recent_effects.duplicate(true),
		"history": _history.duplicate(true), "history_sequence": _history_sequence, "card_instance_sequence": _card_instance_sequence,
		"board": board_state.to_snapshot() if board_state != null else {},
	}
	return _normalize_json_numbers(snapshot)

func restore_snapshot(snapshot: Dictionary) -> Dictionary:
	snapshot = _normalize_json_numbers(snapshot)
	var parsed: Dictionary = _validate_snapshot(snapshot)
	if not parsed.valid:
		return _reject(parsed.reason)
	var board_probe: BoardState
	if board_state != null:
		board_probe = BoardState.new(board_state.definition)
		var board_result: Dictionary = board_probe.restore_snapshot(snapshot.board)
		if not board_result.accepted:
			return _reject("invalid_board_snapshot")
	var rng_probe := DeterministicRng.new(1)
	if not rng_probe.restore(snapshot.rng):
		return _reject("invalid_rng_snapshot")
	rng = rng_probe
	session_id = snapshot.session_id
	seed = snapshot.seed
	round_number = snapshot.round; phase_index = snapshot.phase_index; phase_revision = snapshot.phase_revision
	terminal_state = snapshot.terminal_state; terminal_reason = snapshot.terminal_reason
	participating_seats = _int_array(snapshot.participating_seats); pending_late_seats = _int_array(snapshot.pending_late_seats)
	seat_connection = _seat_values_from_rows(snapshot.seat_connection); ready_seats = _int_array(snapshot.ready_seats); passed_seats = _int_array(snapshot.passed_seats)
	pending_prompt = _prompt_from_snapshot(snapshot.pending_prompt); event_queue = _string_array(snapshot.event_queue); current_event_id = snapshot.current_event_id; event_chain_steps = snapshot.event_chain_steps; resolved_event_rounds = snapshot.resolved_event_rounds.duplicate(true)
	counters = snapshot.counters.duplicate(true); flags = snapshot.flags.duplicate(true); result_flags = snapshot.result_flags.duplicate(true)
	draw_pile = _dict_array(snapshot.draw_pile); hands = _seat_values_from_rows(snapshot.hands); discard_pile = _dict_array(snapshot.discard); exhausted_pile = _dict_array(snapshot.exhausted); removed_pile = _dict_array(snapshot.removed)
	inventory = _seat_values_from_rows(snapshot.inventory); active_vote = snapshot.active_vote.duplicate(true); recent_check = snapshot.recent_check.duplicate(true); recent_effects = _dict_array(snapshot.recent_effects)
	_history = _dict_array(snapshot.history); _history_sequence = snapshot.history_sequence; _card_instance_sequence = snapshot.card_instance_sequence
	if board_state != null:
		board_state.restore_snapshot(snapshot.board)
	last_rejection = "—"
	state_changed.emit({"type": "snapshot_restored"})
	return _accept()

func diagnostics_snapshot() -> Dictionary:
	return {"session": session_id, "seed": seed, "rng_counter": rng.counter, "round": round_number, "phase": current_phase(), "phase_revision": phase_revision, "seats": participating_seats, "ready": ready_seats, "passed": passed_seats, "prompt": pending_prompt, "event_queue": event_queue, "current_event": current_event_id, "deck": draw_pile.size(), "hands": hands, "discard": discard_pile.size(), "exhausted": exhausted_pile.size(), "inventory": inventory, "vote": active_vote, "check": recent_check, "effects": recent_effects, "history": history(), "last_rejection": last_rejection}

func _validate_check(definition: Dictionary) -> Dictionary:
	if not definition.get("dice") is int or definition.dice < 1 or definition.dice > 20 or not definition.get("sides") is int or definition.sides < 2 or definition.sides > 100:
		return {"valid": false, "reason": "malformed_check_definition"}
	if not definition.get("modifier", 0) is int or not definition.get("advantage", 0) is int or absi(definition.get("advantage", 0)) > 1:
		return {"valid": false, "reason": "malformed_check_definition"}
	var bands: Variant = definition.get("bands", {"success": definition.get("target")})
	if not bands is Dictionary or bands.is_empty():
		return {"valid": false, "reason": "malformed_check_definition"}
	for value: Variant in bands.values():
		if not value is int:
			return {"valid": false, "reason": "malformed_check_definition"}
	return {"valid": true, "reason": ""}

func _validate_effect_bundle(effects: Array, actor_seat: int) -> Dictionary:
	var failures := PackedStringArray()
	content._validate_effects(effects, {}, board_state.definition if board_state != null else null, failures)
	if not failures.is_empty():
		return {"valid": false, "reason": "invalid_effect_bundle"}
	var inventory_probe: Dictionary = inventory.duplicate(true)
	var board_probe: BoardState
	if board_state != null:
		board_probe = BoardState.new(board_state.definition)
		board_probe.restore_snapshot(board_state.to_snapshot())
	for effect: Dictionary in effects:
		match effect.type:
			"board_mutation":
				if board_probe == null or not board_probe.apply_mutation(effect.get("mutation", {}), actor_seat).accepted:
					return {"valid": false, "reason": "invalid_board_effect"}
			"add_item":
				var seat: int = effect.get("seat", actor_seat)
				if not participating_seats.has(seat) or not content.has_item(effect.get("item_id", "")) or inventory_probe[seat].has(effect.item_id):
					return {"valid": false, "reason": "invalid_inventory_effect"}
				inventory_probe[seat].append(effect.item_id)
			"remove_item":
				var seat: int = effect.get("seat", actor_seat)
				if not participating_seats.has(seat) or not inventory_probe[seat].has(effect.get("item_id", "")):
					return {"valid": false, "reason": "invalid_inventory_effect"}
				inventory_probe[seat].erase(effect.item_id)
			"draw_card":
				if draw_pile.size() < effect.get("count", 1): return {"valid": false, "reason": "invalid_draw_effect"}
			"queue_event":
				if content.event_by_id(effect.get("event_id", "")).is_empty(): return {"valid": false, "reason": "unknown_event_effect"}
			"discard_card", "exhaust_card", "remove_card":
				if _card_in_hand(effect.get("seat", actor_seat), effect.get("instance_id", "")).is_empty(): return {"valid": false, "reason": "invalid_card_zone_effect"}
	return {"valid": true, "reason": ""}

func _apply_effect(effect: Dictionary, actor_seat: int) -> void:
	match effect.type:
		"board_mutation": board_state.apply_mutation(effect.mutation, actor_seat)
		"set_counter": counters[effect.counter_id] = effect.value
		"add_counter": counters[effect.counter_id] = counters.get(effect.counter_id, 0) + effect.value
		"set_flag": flags[effect.flag_id] = effect.value
		"set_result": result_flags[effect.result_id] = effect.value
		"draw_card": draw_card(effect.get("seat", actor_seat), effect.get("count", 1))
		"grant_card": _grant_card(effect.get("seat", actor_seat), effect.card_id)
		"discard_card": move_card_from_hand(effect.get("seat", actor_seat), effect.instance_id, "discard")
		"exhaust_card": move_card_from_hand(effect.get("seat", actor_seat), effect.instance_id, "exhausted")
		"remove_card": move_card_from_hand(effect.get("seat", actor_seat), effect.instance_id, "removed")
		"add_item": inventory[effect.get("seat", actor_seat)].append(effect.item_id)
		"remove_item": inventory[effect.get("seat", actor_seat)].erase(effect.item_id)
		"queue_event": event_queue.append(effect.event_id)
		"history": _record("narrative", {"text": effect.get("text", "")})

func _conditions_met(conditions: Array, seat_number: int) -> bool:
	for condition: Dictionary in conditions:
		match condition.type:
			"always": pass
			"flag_equals":
				if flags.get(condition.flag_id) != condition.value: return false
			"counter_at_least":
				if counters.get(condition.counter_id, 0) < condition.value: return false
			"seat_has_item":
				if not inventory.get(seat_number, []).has(condition.item_id): return false
			"phase_is":
				if current_phase() != condition.phase: return false
	return true

func _build_deck() -> void:
	var instances: Array = []
	for card_id: String in content.initial_deck:
		instances.append(_new_card_instance(card_id))
	draw_pile = _dict_array(rng.shuffle(instances))
	_record("deck_shuffled", {"count": draw_pile.size(), "rng_counter": rng.counter})

func _grant_card(seat_number: int, card_id: String) -> void:
	hands[seat_number].append(_new_card_instance(card_id))

func _new_card_instance(card_id: String) -> Dictionary:
	_card_instance_sequence += 1
	return {"instance_id": "card_%04d" % _card_instance_sequence, "definition_id": card_id}

func _card_in_hand(seat_number: int, instance_id: String) -> Dictionary:
	for card: Dictionary in hands.get(seat_number, []):
		if card.instance_id == instance_id: return card
	return {}

func _activate_late_seats() -> void:
	for seat_number: int in pending_late_seats:
		participating_seats.append(seat_number); seat_connection[seat_number] = true; hands[seat_number] = []; inventory[seat_number] = []
	participating_seats.sort(); pending_late_seats.clear()

func _record(type: String, payload: Dictionary) -> void:
	_history_sequence += 1
	var normalized_payload: Variant = JSON.parse_string(JSON.stringify(payload))
	var entry: Dictionary = {"sequence": _history_sequence, "type": type, "round": round_number, "phase": current_phase(), "payload": normalized_payload}
	_history.append(entry)
	if _history.size() > HISTORY_LIMIT: _history.pop_front()
	last_rejection = "—"
	state_changed.emit(entry.duplicate(true))

func _reject(reason: String) -> Dictionary:
	last_rejection = reason
	submission_rejected.emit(reason)
	return {"accepted": false, "reason": reason}

func _accept() -> Dictionary:
	return {"accepted": true, "reason": ""}

func _validate_snapshot(snapshot: Dictionary) -> Dictionary:
	if snapshot.get("snapshot_version", -1) != SNAPSHOT_VERSION: return {"valid": false, "reason": "unsupported_snapshot_version"}
	if snapshot.get("scenario_id", "") != content.scenario_id or snapshot.get("scenario_version", -1) != content.scenario_version: return {"valid": false, "reason": "snapshot_content_mismatch"}
	if not snapshot.get("session_id") is String or not snapshot.get("seed") is int or not snapshot.get("rng") is Dictionary: return {"valid": false, "reason": "malformed_snapshot"}
	for key: String in ["round", "phase_index", "phase_revision", "terminal_state", "event_chain_steps", "history_sequence", "card_instance_sequence"]:
		if not snapshot.get(key) is int: return {"valid": false, "reason": "malformed_snapshot"}
	if snapshot.round < 1 or snapshot.phase_index < 0 or snapshot.phase_index >= content.phases.size() or snapshot.event_chain_steps < 0 or snapshot.event_chain_steps > EVENT_CHAIN_LIMIT: return {"valid": false, "reason": "malformed_snapshot"}
	for event_id: Variant in snapshot.get("event_queue", []):
		if not event_id is String or content.event_by_id(event_id).is_empty(): return {"valid": false, "reason": "unknown_snapshot_content"}
	for zone_key: String in ["draw_pile", "discard", "exhausted", "removed"]:
		if not snapshot.get(zone_key) is Array: return {"valid": false, "reason": "malformed_snapshot"}
		for card: Variant in snapshot[zone_key]:
			if not card is Dictionary or content.card_by_id(card.get("definition_id", "")).is_empty(): return {"valid": false, "reason": "unknown_snapshot_content"}
	for rows_key: String in ["seat_connection", "hands", "inventory"]:
		if not snapshot.get(rows_key) is Array: return {"valid": false, "reason": "malformed_snapshot"}
	if not snapshot.get("resolved_event_rounds") is Dictionary: return {"valid": false, "reason": "malformed_snapshot"}
	return {"valid": true, "reason": ""}

func _int_array(values: Array) -> Array[int]:
	var result: Array[int] = []
	for value: int in values: result.append(value)
	return result

func _string_array(values: Array) -> Array[String]:
	var result: Array[String] = []
	for value: String in values: result.append(value)
	return result

func _dict_array(values: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value: Dictionary in values: result.append(value.duplicate(true))
	return result

func _seat_value_rows(values: Dictionary) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var seats: Array[int] = []
	for seat: Variant in values: seats.append(seat)
	seats.sort()
	for seat: int in seats: rows.append({"seat": seat, "value": values[seat]})
	return rows

func _seat_values_from_rows(rows: Array) -> Dictionary:
	var values: Dictionary = {}
	for row: Dictionary in rows: values[int(row.seat)] = row.value
	return values

func _prompt_snapshot() -> Dictionary:
	if pending_prompt.is_empty(): return {}
	var snapshot: Dictionary = pending_prompt.duplicate(true)
	snapshot.responses = _seat_value_rows(pending_prompt.responses)
	return snapshot

func _prompt_from_snapshot(snapshot: Dictionary) -> Dictionary:
	if snapshot.is_empty(): return {}
	var prompt: Dictionary = snapshot.duplicate(true)
	prompt.responses = _seat_values_from_rows(snapshot.responses)
	return prompt

func _normalize_json_numbers(value: Variant) -> Variant:
	if value is float and is_equal_approx(value, roundf(value)):
		return int(value)
	if value is Array:
		var normalized_array: Array = []
		for item: Variant in value: normalized_array.append(_normalize_json_numbers(item))
		return normalized_array
	if value is Dictionary:
		var normalized_dictionary: Dictionary = {}
		for key: Variant in value: normalized_dictionary[key] = _normalize_json_numbers(value[key])
		return normalized_dictionary
	return value
