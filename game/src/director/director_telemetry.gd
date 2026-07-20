class_name DirectorTelemetry
extends RefCounted

const SNAPSHOT_VERSION: int = 1


static func build(rules: RulesSession, board: BoardState, social: RoleSession = null) -> Dictionary:
	var seats: Array[int] = rules.participating_seats.duplicate()
	var active_seats: Array[int] = []
	var disconnected_seats: Array[int] = []
	for seat: int in seats:
		if rules.seat_connection.get(seat, false):
			active_seats.append(seat)
		else:
			disconnected_seats.append(seat)
	var recent_outcomes := PackedStringArray()
	var participation: Dictionary = {}
	for seat: int in seats:
		participation[seat] = 0
	for entry: Dictionary in rules.history().slice(maxi(0, rules.history().size() - 32)):
		if entry.get("type", "") == "check_resolved":
			recent_outcomes.append(entry.get("outcome", "failure"))
		if entry.get("type", "") in ["prompt_response", "seat_ready", "seat_passed", "card_played"]:
			var seat: int = entry.get("seat", 0)
			if participation.has(seat):
				participation[seat] += 1
	var failure_count: int = 0
	for outcome: String in recent_outcomes.slice(maxi(0, recent_outcomes.size() - 4)):
		if outcome in ["failure", "partial"]:
			failure_count += 1
	var resource_units: int = rules.counters.get("hope", 0) + rules.counters.get("resolve", 0)
	for seat: int in seats:
		resource_units += (
			rules.hands.get(seat, []).size() + rules.inventory.get(seat, []).size() * 2
		)
	var hazard_units: int = 0
	var occupied_spaces: int = 0
	if board != null:
		for space_id: String in board.definition.space_ids():
			var state: Dictionary = board.get_space_state(space_id)
			hazard_units += state.hazards.size() + state.blockers.size()
			if not board.occupants_in(space_id).is_empty():
				occupied_spaces += 1
	var participation_values: Array = participation.values()
	var participation_span: int = 0
	if not participation_values.is_empty():
		participation_span = participation_values.max() - participation_values.min()
	var objective_progress: int = clampi(rules.counters.get("objective_progress", 0), 0, 10)
	var round_progress: int = clampi((rules.round_number - 1) * 12 + rules.phase_index * 2, 0, 70)
	var recent_tags := PackedStringArray()
	for effect: Dictionary in rules.recent_effects:
		var event: Dictionary = rules.content.event_by_id(effect.get("source_id", ""))
		for tag: String in event.get("tags", []):
			if not recent_tags.has(tag):
				recent_tags.append(tag)
	var social_signals: Dictionary = social.director_safe_signals() if social != null else {}
	var balance_signal: int = clampi(50 + int(social_signals.get("revealed_imbalance", 0)), 0, 100)
	var snapshot: Dictionary = {
		"snapshot_version": SNAPSHOT_VERSION,
		"round": rules.round_number,
		"phase": rules.current_phase(),
		"progress": clampi(round_progress + objective_progress * 3, 0, 100),
		"failure_pressure": clampi(failure_count * 25, 0, 100),
		"resource_pressure": clampi(85 - resource_units * 7, 0, 100),
		"hazard_pressure": clampi(hazard_units * 18, 0, 100),
		"group_spread": clampi(maxi(0, occupied_spaces - 1) * 25, 0, 100),
		"stalled_steps": clampi(rules.counters.get("objective_stall_steps", 0) * 12, 0, 100),
		"prompt_latency": clampi(rules.counters.get("prompt_latency_steps", 0) * 10, 0, 100),
		"pass_frequency":
		clampi(
			roundi(float(rules.passed_seats.size()) / float(maxi(1, active_seats.size())) * 100.0),
			0,
			100
		),
		"participation_imbalance": clampi(participation_span * 20, 0, 100),
		"rejected_actions": clampi(rules.counters.get("rejected_actions", 0) * 15, 0, 100),
		"objective_progress": objective_progress,
		"recent_check_outcomes": recent_outcomes,
		"recent_intervention_tags": recent_tags,
		"active_seats": active_seats,
		"disconnected_seats": disconnected_seats,
		"reserved_seat_count": disconnected_seats.size(),
		"future_balance_signal": balance_signal,
		"social_signals": social_signals,
		"rules_flags": rules.flags.duplicate(true),
	}
	return snapshot


static func validate(snapshot: Dictionary) -> PackedStringArray:
	var failures := PackedStringArray()
	if snapshot.get("snapshot_version") != SNAPSHOT_VERSION:
		failures.append("unsupported telemetry snapshot")
	for field: String in DirectorContent.VALID_METRICS:
		if (
			not snapshot.get(field) is int
			or snapshot.get(field, -1) < 0
			or snapshot.get(field, 101) > 100
		):
			failures.append("invalid telemetry metric %s" % field)
	for field: String in [
		"round", "objective_progress", "reserved_seat_count", "future_balance_signal"
	]:
		if not snapshot.get(field) is int or snapshot.get(field, -1) < 0:
			failures.append("invalid telemetry field %s" % field)
	if (
		not snapshot.get("phase") is String
		or not snapshot.get("active_seats") is Array
		or not snapshot.get("disconnected_seats") is Array
	):
		failures.append("malformed telemetry identity fields")
	if not snapshot.get("social_signals", {}) is Dictionary:
		failures.append("malformed authorized social signals")
	else:
		for signal_name: Variant in snapshot.get("social_signals", {}).keys():
			if (
				not signal_name is String
				or not SocialContent.VALID_DIRECTOR_SIGNALS.has(signal_name)
				or not snapshot.social_signals[signal_name] is int
				or snapshot.social_signals[signal_name] < 0
				or snapshot.social_signals[signal_name] > 100
			):
				failures.append("invalid authorized social signal")
	for seat_list: String in ["active_seats", "disconnected_seats"]:
		for seat: Variant in snapshot.get(seat_list, []):
			if not seat is int or seat < 1 or seat > SeatManager.MAX_SEATS:
				failures.append("invalid telemetry seat")
	return failures
