class_name DirectorRuntime
extends RefCounted

const SNAPSHOT_VERSION: int = 1
const DECISION_VERSION: int = 1
const AUDIT_LIMIT: int = 48
const DIRECTOR_SALT: String = "dread_director_v1"

var content: DirectorContent
var profile: Dictionary = {}
var rng: DeterministicRng
var revision: int = 0
var evaluation_step: int = 0
var pacing_act: String = "arrival"
var target_tension: Array[int] = [20, 38]
var estimated_tension: int = 0
var pressure_momentum: int = 0
var relief_momentum: int = 0
var budgets: Dictionary = {}
var candidate_cooldowns: Dictionary = {}
var tag_cooldowns: Dictionary = {}
var target_history: Array[Dictionary] = []
var recent_decisions: Array[Dictionary] = []
var audit_history: Array[Dictionary] = []
var recovery_until_step: int = 0
var last_intervention_step: int = -999
var last_no_op_reason: String = "not_evaluated"
var last_application: Dictionary = {}


func _init(
	p_content: DirectorContent = null,
	profile_id: String = "standard",
	session_seed: int = 1,
	rules_content: RulesContent = null,
	board_definition: BoardDefinition = null
) -> void:
	if p_content != null:
		initialize(p_content, profile_id, session_seed, rules_content, board_definition)


func initialize(
	p_content: DirectorContent,
	profile_id: String,
	session_seed: int,
	rules_content: RulesContent,
	board_definition: BoardDefinition
) -> PackedStringArray:
	var failures: PackedStringArray = p_content.validate(rules_content, board_definition)
	var selected_profile: Dictionary = p_content.profile_by_id(profile_id)
	if selected_profile.is_empty():
		failures.append("unknown director profile")
	if not failures.is_empty():
		return failures
	content = p_content
	profile = selected_profile
	rng = DeterministicRng.new(derive_seed(session_seed, profile_id))
	budgets = profile.budgets.duplicate(true)
	return failures


static func derive_seed(session_seed: int, profile_id: String) -> int:
	var value: int = absi(session_seed) % DeterministicRng.MODULUS
	var salted: String = "%s:%s" % [DIRECTOR_SALT, profile_id]
	for index: int in salted.length():
		value = int((value * 131 + salted.unicode_at(index)) % DeterministicRng.MODULUS)
	return 1 if value == 0 else value


func evaluate(telemetry: Dictionary) -> Dictionary:
	if content == null or profile.is_empty() or rng == null:
		return _invalid_decision("director_not_initialized")
	var telemetry_failures: PackedStringArray = DirectorTelemetry.validate(telemetry)
	if not telemetry_failures.is_empty():
		return _invalid_decision("invalid_telemetry")
	evaluation_step += 1
	_update_pacing(telemetry)
	var rng_before: int = rng.counter
	var mercy_active: bool = telemetry.failure_pressure >= 50 or telemetry.resource_pressure >= 70
	var evaluations: Array[Dictionary] = []
	var eligible: Array[Dictionary] = []
	var ordered: Array[Dictionary] = content.candidates.duplicate(true)
	ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.id < b.id)
	for candidate: Dictionary in ordered:
		if candidate.category == "no_op":
			evaluations.append(
				{
					"candidate_id": candidate.id,
					"name": candidate.name,
					"category": "no_op",
					"eligible": true,
					"rejection_reasons": PackedStringArray(),
					"target_seat": 0,
					"components": {"fallback": 0},
					"final_score": 0
				}
			)
			continue
		var evaluation: Dictionary = _evaluate_candidate(candidate, telemetry, mercy_active)
		evaluations.append(evaluation)
		if evaluation.eligible and evaluation.final_score > 0:
			eligible.append(evaluation)
	var selected: Dictionary = {}
	var tie_break: Dictionary = {
		"method": "highest_score_then_director_rng", "contenders": [], "draw": -1
	}
	var no_op_reason: String = ""
	if profile.mode == "off":
		no_op_reason = "profile_off"
	elif profile.mode == "fixed":
		var fixed: Array[Dictionary] = eligible.filter(
			func(value: Dictionary) -> bool: return value.category == "ambient"
		)
		if not fixed.is_empty():
			selected = fixed[0]
		else:
			no_op_reason = "fixed_candidate_unavailable"
	elif eligible.is_empty():
		no_op_reason = "no_legal_positive_candidate"
	else:
		var high_score: int = eligible.reduce(
			func(best: int, value: Dictionary) -> int: return maxi(best, value.final_score), -1
		)
		var tied: Array[Dictionary] = eligible.filter(
			func(value: Dictionary) -> bool: return value.final_score == high_score
		)
		tie_break.contenders = tied.map(
			func(value: Dictionary) -> String: return value.candidate_id
		)
		if tied.size() == 1:
			selected = tied[0]
		else:
			var draw: int = rng.draw_range(0, tied.size() - 1)
			tie_break.draw = draw
			selected = tied[draw]
	if selected.is_empty():
		selected = _no_op_evaluation(no_op_reason)
		last_no_op_reason = no_op_reason
	var definition: Dictionary = content.candidate_by_id(selected.candidate_id)
	var decision: Dictionary = {
		"decision_version": DECISION_VERSION,
		"decision_key": "%d:%d:%s" % [revision, evaluation_step, selected.candidate_id],
		"evaluation_step": evaluation_step,
		"director_revision": revision,
		"profile_id": profile.id,
		"profile_name": profile.display_name,
		"pacing_act": pacing_act,
		"target_tension": target_tension.duplicate(),
		"estimated_tension": estimated_tension,
		"pressure_momentum": pressure_momentum,
		"relief_momentum": relief_momentum,
		"mercy_active": mercy_active,
		"rng_before": rng_before,
		"rng_after": rng.counter,
		"candidate_evaluations": evaluations,
		"selected_candidate_id": selected.candidate_id,
		"selected_name": definition.get("name", RulesHud.friendly_label(selected.candidate_id)),
		"selected_summary": definition.get("summary", ""),
		"category": selected.category,
		"tags": definition.get("tags", []).duplicate(),
		"target_seat": selected.target_seat,
		"final_score": selected.final_score,
		"score_components": selected.components.duplicate(true),
		"proposal": definition.get("payload", {"type": "no_op"}).duplicate(true),
		"presentation": definition.get("presentation", {}).duplicate(true),
		"rationale": _friendly_rationale(selected.category, telemetry, mercy_active),
		"tie_break": tie_break,
		"no_op_reason": no_op_reason,
	}
	return decision


func record_application(decision: Dictionary, result: Dictionary) -> Dictionary:
	if (
		decision.get("decision_version") != DECISION_VERSION
		or decision.get("evaluation_step") != evaluation_step
		or decision.get("director_revision") != revision
	):
		return {"accepted": false, "reason": "stale_or_malformed_decision"}
	var accepted: bool = result.get("accepted", false)
	var candidate: Dictionary = content.candidate_by_id(decision.get("selected_candidate_id", ""))
	if candidate.is_empty():
		return {"accepted": false, "reason": "unknown_decision_candidate"}
	if accepted:
		revision += 1
		var budget_kind: String = candidate.budget_kind
		budgets[budget_kind] = maxi(0, budgets.get(budget_kind, 0) - candidate.budget_cost)
		if budget_kind != "intervention":
			budgets.intervention = maxi(0, budgets.get("intervention", 0) - candidate.budget_cost)
		if candidate.category != "no_op":
			last_intervention_step = evaluation_step
			candidate_cooldowns[candidate.id] = (
				evaluation_step + candidate.cooldown + profile.global_cooldown
			)
			for tag: String in candidate.tags:
				tag_cooldowns[tag] = evaluation_step + profile.tag_cooldown
		if candidate.pressure_impact > 0:
			pressure_momentum = clampi(pressure_momentum + candidate.pressure_impact, 0, 100)
			relief_momentum = maxi(0, relief_momentum - candidate.pressure_impact / 2)
			if candidate.pressure_impact >= 20:
				recovery_until_step = evaluation_step + profile.recovery_window
		if candidate.relief_impact > 0:
			relief_momentum = clampi(relief_momentum + candidate.relief_impact, 0, 100)
			pressure_momentum = maxi(0, pressure_momentum - candidate.relief_impact / 2)
		if decision.target_seat > 0 and candidate.target_scope == "active_negative":
			target_history.append(
				{"step": evaluation_step, "seat": decision.target_seat, "negative": true}
			)
		recent_decisions.append(
			{
				"step": evaluation_step,
				"candidate_id": candidate.id,
				"tags": candidate.tags.duplicate(),
				"pressure_impact": candidate.pressure_impact
			}
		)
		_trim_runtime_history()
	last_application = {
		"accepted": accepted,
		"reason": result.get("reason", "accepted" if accepted else "rejected"),
		"authority": result.get("authority", "none"),
		"downstream_revision": result.get("downstream_revision", -1),
		"director_revision": revision,
		"evaluation_step": evaluation_step,
	}
	var audit: Dictionary = decision.duplicate(true)
	audit["application"] = last_application.duplicate(true)
	audit_history.append(audit)
	if audit_history.size() > AUDIT_LIMIT:
		audit_history.pop_front()
	return {
		"accepted": accepted,
		"director_revision": revision,
		"application": last_application.duplicate(true)
	}


func to_snapshot() -> Dictionary:
	return {
		"snapshot_version": SNAPSHOT_VERSION,
		"content_id": content.content_id,
		"content_version": content.content_version,
		"profile_id": profile.id,
		"profile_version": profile.version,
		"revision": revision,
		"evaluation_step": evaluation_step,
		"pacing_act": pacing_act,
		"target_tension": target_tension.duplicate(),
		"estimated_tension": estimated_tension,
		"pressure_momentum": pressure_momentum,
		"relief_momentum": relief_momentum,
		"budgets": budgets.duplicate(true),
		"candidate_cooldowns": candidate_cooldowns.duplicate(true),
		"tag_cooldowns": tag_cooldowns.duplicate(true),
		"target_history": target_history.duplicate(true),
		"recent_decisions": recent_decisions.duplicate(true),
		"recovery_until_step": recovery_until_step,
		"last_intervention_step": last_intervention_step,
		"last_no_op_reason": last_no_op_reason,
		"last_application": last_application.duplicate(true),
		"audit_history": audit_history.duplicate(true),
		"rng": rng.to_snapshot(),
	}


func restore_snapshot(snapshot: Dictionary) -> Dictionary:
	snapshot = _normalize_json_numbers(snapshot)
	var validation: Dictionary = _validate_snapshot(snapshot)
	if not validation.valid:
		return {"accepted": false, "reason": validation.reason}
	var rng_probe := DeterministicRng.new(1)
	if not rng_probe.restore(snapshot.rng):
		return {"accepted": false, "reason": "invalid_director_rng_snapshot"}
	revision = snapshot.revision
	evaluation_step = snapshot.evaluation_step
	pacing_act = snapshot.pacing_act
	target_tension = [snapshot.target_tension[0], snapshot.target_tension[1]]
	estimated_tension = snapshot.estimated_tension
	pressure_momentum = snapshot.pressure_momentum
	relief_momentum = snapshot.relief_momentum
	budgets = snapshot.budgets.duplicate(true)
	candidate_cooldowns = snapshot.candidate_cooldowns.duplicate(true)
	tag_cooldowns = snapshot.tag_cooldowns.duplicate(true)
	target_history = _dict_array(snapshot.target_history)
	recent_decisions = _dict_array(snapshot.recent_decisions)
	recovery_until_step = snapshot.recovery_until_step
	last_intervention_step = snapshot.last_intervention_step
	last_no_op_reason = snapshot.last_no_op_reason
	last_application = snapshot.last_application.duplicate(true)
	audit_history = _dict_array(snapshot.audit_history)
	rng = rng_probe
	return {"accepted": true}


func diagnostics_snapshot() -> Dictionary:
	return {
		"content": "%s v%d" % [content.content_id, content.content_version],
		"profile": profile.id,
		"profile_name": profile.display_name,
		"revision": revision,
		"rng_counter": rng.counter,
		"act": pacing_act,
		"target_tension": target_tension,
		"estimated_tension": estimated_tension,
		"pressure_momentum": pressure_momentum,
		"relief_momentum": relief_momentum,
		"budgets": budgets.duplicate(true),
		"candidate_cooldowns": candidate_cooldowns.duplicate(true),
		"tag_cooldowns": tag_cooldowns.duplicate(true),
		"target_ledger": target_history.duplicate(true),
		"recovery_until_step": recovery_until_step,
		"last_application": last_application.duplicate(true),
		"last_no_op_reason": last_no_op_reason,
		"audit_history": audit_history.duplicate(true),
	}


func companion_public_view() -> Dictionary:
	return {
		"view_version": 1,
		"revision": revision,
		"profile_label": profile.get("display_name", "Director"),
		"pacing_act": pacing_act.capitalize(),
		"status": "Active" if profile.get("mode", "") != "off" else "Off",
	}


func _evaluate_candidate(
	candidate: Dictionary, telemetry: Dictionary, mercy_active: bool
) -> Dictionary:
	var reasons := PackedStringArray()
	var tags: Array = candidate.tags
	if (
		not profile.allow_tags.is_empty()
		and not tags.any(func(tag: Variant) -> bool: return profile.allow_tags.has(tag))
	):
		reasons.append("profile_allow_tags")
	if tags.any(func(tag: Variant) -> bool: return profile.deny_tags.has(tag)):
		reasons.append("profile_deny_tags")
	if candidate_cooldowns.get(candidate.id, 0) > evaluation_step:
		reasons.append("candidate_cooldown")
	if tags.any(func(tag: Variant) -> bool: return tag_cooldowns.get(tag, 0) > evaluation_step):
		reasons.append("tag_cooldown")
	if evaluation_step - last_intervention_step < profile.min_spacing:
		reasons.append("minimum_spacing")
	if (
		budgets.get(candidate.budget_kind, 0) < candidate.budget_cost
		or budgets.get("intervention", 0) < candidate.budget_cost
	):
		reasons.append("budget_exhausted")
	for condition: Dictionary in candidate.conditions:
		if not _condition_met(condition, telemetry):
			reasons.append("condition_%s" % condition.type)
	if mercy_active and candidate.pressure_impact > 0:
		reasons.append("mercy_pressure_suppression")
	if evaluation_step <= recovery_until_step and candidate.pressure_impact > 0:
		reasons.append("recovery_window")
	if (
		candidate.pressure_impact > 0
		and _recent_pressure() + candidate.pressure_impact > profile.max_pressure_per_window
	):
		reasons.append("pressure_window_cap")
	var target: Dictionary = _select_target(candidate, telemetry)
	if not target.valid:
		reasons.append(target.reason)
	var components: Dictionary = {
		"base_weight": candidate.base_weight,
		"pacing_curve_fit": 0,
		"tension_gap_fit": 0,
		"telemetry_affinities": 0,
		"profile_tag_affinity": 0,
		"repetition_penalty": 0,
		"fairness_penalty": 0,
		"mercy_or_recovery": 0,
		"volatility": 0,
		"scenario_constraints": 0,
	}
	if reasons.is_empty():
		var target_mid: int = (target_tension[0] + target_tension[1]) / 2
		var gap: int = target_mid - estimated_tension
		if candidate.pressure_impact > 0:
			components.tension_gap_fit = clampi(gap / 2, -30, 30)
			components.volatility = profile.volatility / 4
		elif candidate.relief_impact > 0:
			components.tension_gap_fit = clampi(-gap / 2, -30, 30)
		components.pacing_curve_fit = clampi(12 - absi(gap) / 5, -8, 12)
		for metric: String in candidate.metric_affinities:
			components.telemetry_affinities += roundi(
				(
					float(
						(
							telemetry.get(metric, 0)
							* candidate.metric_affinities[metric]
							* profile.metric_weights.get(metric, 1)
						)
					)
					/ 100.0
				)
			)
		for tag: String in tags:
			components.profile_tag_affinity += profile.tag_affinities.get(tag, 0)
		components.repetition_penalty = _repetition_penalty(candidate)
		if target.seat > 0:
			components.fairness_penalty = -10 * _target_count(target.seat)
		if mercy_active and candidate.category in ["relief", "hint", "ambient"]:
			components.mercy_or_recovery = 35
		if telemetry.stalled_steps >= 45 and candidate.category in ["hint", "event", "ambient"]:
			components.mercy_or_recovery += 25
		if evaluation_step - last_intervention_step >= profile.max_spacing:
			components.scenario_constraints += 15
	var final_score: int = 0
	for value: int in components.values():
		final_score += value
	final_score = maxi(0, final_score)
	return {
		"candidate_id": candidate.id,
		"name": candidate.name,
		"category": candidate.category,
		"eligible": reasons.is_empty(),
		"rejection_reasons": reasons,
		"target_seat": target.seat,
		"components": components,
		"final_score": final_score,
	}


func _select_target(candidate: Dictionary, telemetry: Dictionary) -> Dictionary:
	if candidate.target_scope == "none":
		return {"valid": true, "seat": 0, "reason": ""}
	var active: Array = telemetry.active_seats.duplicate()
	active.sort()
	if active.is_empty():
		return {"valid": false, "seat": 0, "reason": "no_active_target"}
	var best_seat: int = 0
	var best_count: int = 999
	for seat: int in active:
		var count: int = _target_count(seat)
		if candidate.target_scope == "active_negative" and count >= profile.max_targets_per_window:
			continue
		if count < best_count:
			best_count = count
			best_seat = seat
	if best_seat == 0:
		return {"valid": false, "seat": 0, "reason": "target_fairness_cap"}
	return {"valid": true, "seat": best_seat, "reason": ""}


func _condition_met(condition: Dictionary, telemetry: Dictionary) -> bool:
	match condition.type:
		"always":
			return true
		"metric_at_least":
			return telemetry.get(condition.metric, 0) >= condition.value
		"metric_at_most":
			return telemetry.get(condition.metric, 0) <= condition.value
		"rules_flag":
			return (
				telemetry.get("rules_flags", {}).get(condition.get("flag_id", ""), false)
				== condition.get("value", true)
			)
		"board_hazard_below":
			return telemetry.hazard_pressure < condition.value
	return false


func _update_pacing(telemetry: Dictionary) -> void:
	var selected: Dictionary = profile.pacing_curve[0]
	for point: Dictionary in profile.pacing_curve:
		if telemetry.progress >= point.progress:
			selected = point
	pacing_act = selected.act
	target_tension = [selected.low, selected.high]
	estimated_tension = clampi(
		roundi(
			(
				telemetry.failure_pressure * 0.28
				+ telemetry.resource_pressure * 0.22
				+ telemetry.hazard_pressure * 0.22
				+ telemetry.group_spread * 0.08
				+ telemetry.stalled_steps * 0.08
				+ pressure_momentum * 0.12
				- relief_momentum * 0.10
			)
		),
		0,
		100
	)


func _recent_pressure() -> int:
	var total: int = 0
	for record: Dictionary in recent_decisions:
		if evaluation_step - record.step <= profile.pressure_window:
			total += record.get("pressure_impact", 0)
	return total


func _repetition_penalty(candidate: Dictionary) -> int:
	var penalty: int = 0
	for record: Dictionary in recent_decisions:
		var age: int = evaluation_step - record.step
		if age <= maxi(profile.repetition_window, candidate.repetition_window):
			if record.candidate_id == candidate.id:
				penalty -= 30
			for tag: String in candidate.tags:
				if record.tags.has(tag):
					penalty -= 4
	return maxi(penalty, -60)


func _target_count(seat: int) -> int:
	var count: int = 0
	for record: Dictionary in target_history:
		if record.seat == seat and evaluation_step - record.step <= profile.target_window:
			count += 1
	return count


func _friendly_rationale(category: String, telemetry: Dictionary, mercy_active: bool) -> String:
	if category == "no_op":
		return "The fair choice is to hold this beat and leave play unchanged."
	if telemetry.stalled_steps >= 45 and category in ["hint", "event", "ambient"]:
		return "Progress has paused, so the house offers a nudge instead of punishment."
	if mercy_active and category in ["relief", "hint", "ambient"]:
		return "The group needs recovery space, so pressure is being held back."
	if category in ["pressure", "board"]:
		return "The group has momentum; a bounded omen restores dramatic tension."
	if category == "relief":
		return "Resources are thin, so a bounded recovery beat is available."
	if category == "hint":
		return "An authored clue keeps a legal route visible."
	if category == "event":
		return "An authored pacing event can move the tale forward."
	return "A presentation-only omen supports the current pacing beat."


func _no_op_evaluation(reason: String) -> Dictionary:
	var candidate: Dictionary = content.no_op_candidate()
	return {
		"candidate_id": candidate.get("id", ""),
		"category": "no_op",
		"target_seat": 0,
		"final_score": 0,
		"components": {"fallback": 0},
		"reason": reason
	}


func _invalid_decision(reason: String) -> Dictionary:
	return {
		"decision_version": DECISION_VERSION,
		"accepted": false,
		"reason": reason,
		"rng_before": rng.counter if rng != null else 0,
		"rng_after": rng.counter if rng != null else 0
	}


func _trim_runtime_history() -> void:
	while recent_decisions.size() > 16:
		recent_decisions.pop_front()
	while target_history.size() > 32:
		target_history.pop_front()


func _validate_snapshot(snapshot: Dictionary) -> Dictionary:
	if (
		snapshot.get("snapshot_version") != SNAPSHOT_VERSION
		or snapshot.get("content_id") != content.content_id
		or snapshot.get("content_version") != content.content_version
	):
		return {"valid": false, "reason": "director_snapshot_identity_mismatch"}
	if (
		snapshot.get("profile_id") != profile.id
		or snapshot.get("profile_version") != profile.version
	):
		return {"valid": false, "reason": "director_snapshot_profile_mismatch"}
	for field: String in [
		"revision",
		"evaluation_step",
		"estimated_tension",
		"pressure_momentum",
		"relief_momentum",
		"recovery_until_step"
	]:
		if not snapshot.get(field) is int or snapshot.get(field, -1) < 0:
			return {"valid": false, "reason": "malformed_director_snapshot"}
	if (
		not snapshot.get("last_intervention_step") is int
		or not snapshot.get("target_tension") is Array
		or snapshot.target_tension.size() != 2
	):
		return {"valid": false, "reason": "malformed_director_snapshot"}
	if (
		not snapshot.get("budgets") is Dictionary
		or not snapshot.get("candidate_cooldowns") is Dictionary
		or not snapshot.get("tag_cooldowns") is Dictionary
	):
		return {"valid": false, "reason": "malformed_director_snapshot"}
	for budget: String in DirectorContent.VALID_BUDGETS:
		if not snapshot.budgets.get(budget) is int or snapshot.budgets.get(budget, -1) < 0:
			return {"valid": false, "reason": "malformed_director_budget_snapshot"}
	for candidate_id: Variant in snapshot.candidate_cooldowns:
		if not candidate_id is String or content.candidate_by_id(candidate_id).is_empty():
			return {"valid": false, "reason": "unknown_snapshot_candidate"}
	for tag: Variant in snapshot.tag_cooldowns:
		if not tag is String or not DirectorContent.VALID_TAGS.has(tag):
			return {"valid": false, "reason": "unknown_snapshot_tag"}
	for field: String in ["target_history", "recent_decisions", "audit_history"]:
		if not snapshot.get(field) is Array:
			return {"valid": false, "reason": "malformed_director_snapshot"}
	for record: Variant in snapshot.recent_decisions:
		if (
			not record is Dictionary
			or content.candidate_by_id(record.get("candidate_id", "")).is_empty()
		):
			return {"valid": false, "reason": "unknown_snapshot_candidate"}
	for record: Variant in snapshot.audit_history:
		if (
			not record is Dictionary
			or content.candidate_by_id(record.get("selected_candidate_id", "")).is_empty()
		):
			return {"valid": false, "reason": "unknown_snapshot_candidate"}
	for record: Variant in snapshot.target_history:
		if (
			not record is Dictionary
			or not record.get("seat") is int
			or record.get("seat", 0) < 1
			or record.get("seat", 0) > SeatManager.MAX_SEATS
		):
			return {"valid": false, "reason": "malformed_target_ledger"}
	if (
		not snapshot.get("rng") is Dictionary
		or not snapshot.get("last_application", {}) is Dictionary
		or not snapshot.get("last_no_op_reason") is String
	):
		return {"valid": false, "reason": "malformed_director_snapshot"}
	return {"valid": true, "reason": ""}


func _dict_array(values: Array) -> Array[Dictionary]:
	var typed: Array[Dictionary] = []
	for value: Dictionary in values:
		typed.append(value.duplicate(true))
	return typed


func _normalize_json_numbers(value: Variant) -> Variant:
	if value is float and is_equal_approx(value, round(value)):
		return int(value)
	if value is Array:
		var array: Array = []
		for item: Variant in value:
			array.append(_normalize_json_numbers(item))
		return array
	if value is Dictionary:
		var dictionary: Dictionary = {}
		for key: Variant in value:
			dictionary[key] = _normalize_json_numbers(value[key])
		return dictionary
	return value
