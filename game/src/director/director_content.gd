class_name DirectorContent
extends Resource

const VALID_METRICS: PackedStringArray = [
	"progress",
	"failure_pressure",
	"resource_pressure",
	"hazard_pressure",
	"group_spread",
	"stalled_steps",
	"prompt_latency",
	"pass_frequency",
	"participation_imbalance",
	"rejected_actions",
]
const VALID_CATEGORIES: PackedStringArray = [
	"pressure", "relief", "hint", "board", "event", "ambient", "no_op"
]
const VALID_CONDITIONS: PackedStringArray = [
	"metric_at_least", "metric_at_most", "rules_flag", "board_hazard_below", "always"
]
const VALID_TARGET_SCOPES: PackedStringArray = ["none", "active_any", "active_negative"]
const VALID_BUDGETS: PackedStringArray = [
	"pressure", "relief", "clue", "scarcity", "ambient", "intervention"
]
const VALID_PAYLOADS: PackedStringArray = [
	"queue_event", "rules_effects", "board_mutation", "presentation", "no_op"
]
const VALID_TAGS: PackedStringArray = [
	"pressure",
	"relief",
	"clue",
	"scarcity",
	"ambient",
	"board",
	"event",
	"recovery",
	"light",
	"hazard",
	"nudge",
	"breath",
	"host",
	"sound",
	"gentle",
	"dramatic",
]

@export var content_id: String = ""
@export var content_version: int = 1
@export var profiles: Array[Dictionary] = []
@export var candidates: Array[Dictionary] = []


func validate(
	rules_content: RulesContent = null, board_definition: BoardDefinition = null
) -> PackedStringArray:
	var failures := PackedStringArray()
	if not _valid_id(content_id) or content_version < 1:
		failures.append("malformed director content identity")
	var profile_ids: Dictionary = {}
	for profile: Dictionary in profiles:
		_validate_profile(profile, profile_ids, failures)
	var candidate_ids: Dictionary = {}
	var has_no_op: bool = false
	for candidate: Dictionary in candidates:
		_validate_candidate(candidate, candidate_ids, rules_content, board_definition, failures)
		if candidate.get("category", "") == "no_op":
			has_no_op = true
	if not has_no_op:
		failures.append("missing legal no-op fallback")
	for profile: Dictionary in profiles:
		var allowed: Array = profile.get("allow_tags", [])
		var denied: Array = profile.get("deny_tags", [])
		var legal_fallback: bool = false
		for candidate: Dictionary in candidates:
			if candidate.get("category", "") != "no_op":
				continue
			var tags: Array = candidate.get("tags", [])
			legal_fallback = (
				allowed.is_empty() or tags.any(func(tag: Variant) -> bool: return allowed.has(tag))
			)
			legal_fallback = (
				legal_fallback and not tags.any(func(tag: Variant) -> bool: return denied.has(tag))
			)
		if not legal_fallback:
			failures.append(
				"profile %s cannot select legal no-op fallback" % profile.get("id", "?")
			)
	return failures


func profile_by_id(profile_id: String) -> Dictionary:
	for profile: Dictionary in profiles:
		if profile.get("id", "") == profile_id:
			return profile.duplicate(true)
	return {}


func candidate_by_id(candidate_id: String) -> Dictionary:
	for candidate: Dictionary in candidates:
		if candidate.get("id", "") == candidate_id:
			return candidate.duplicate(true)
	return {}


func no_op_candidate() -> Dictionary:
	for candidate: Dictionary in candidates:
		if candidate.get("category", "") == "no_op":
			return candidate.duplicate(true)
	return {}


func _validate_profile(profile: Dictionary, seen: Dictionary, failures: PackedStringArray) -> void:
	var profile_id: String = profile.get("id", "")
	if (
		not _valid_id(profile_id)
		or not profile.get("version") is int
		or profile.get("version", 0) < 1
	):
		failures.append("malformed director profile identity")
		return
	if seen.has(profile_id):
		failures.append("duplicate director profile id %s" % profile_id)
		return
	seen[profile_id] = true
	if not ["off", "adaptive", "fixed"].has(profile.get("mode", "")):
		failures.append("invalid director mode %s" % profile_id)
	var curve: Variant = profile.get("pacing_curve")
	if not curve is Array or curve.is_empty():
		failures.append("invalid pacing curve %s" % profile_id)
	else:
		var prior_progress: int = -1
		for point: Variant in curve:
			if (
				not point is Dictionary
				or not point.get("progress") is int
				or not point.get("low") is int
				or not point.get("high") is int
				or not point.get("act") is String
			):
				failures.append("invalid pacing curve %s" % profile_id)
				break
			if (
				point.progress <= prior_progress
				or point.progress < 0
				or point.progress > 100
				or point.low < 0
				or point.high > 100
				or point.low > point.high
				or not _valid_id(point.act)
			):
				failures.append("impossible pacing curve %s" % profile_id)
				break
			prior_progress = point.progress
	var weights: Variant = profile.get("metric_weights")
	if not weights is Dictionary:
		failures.append("malformed metric weights %s" % profile_id)
	else:
		for metric: Variant in weights:
			if (
				not metric is String
				or not VALID_METRICS.has(metric)
				or not weights[metric] is int
				or absi(weights[metric]) > 20
			):
				failures.append("invalid metric weight %s" % profile_id)
	var bounds: Variant = profile.get("normalization_bounds")
	if not bounds is Dictionary:
		failures.append("malformed normalization bounds %s" % profile_id)
	else:
		for metric: String in VALID_METRICS:
			var bound: Variant = bounds.get(metric)
			if (
				not bound is Array
				or bound.size() != 2
				or not bound[0] is int
				or not bound[1] is int
				or bound[0] >= bound[1]
			):
				failures.append("invalid normalization bound %s:%s" % [profile_id, metric])
	var budgets: Variant = profile.get("budgets")
	if not budgets is Dictionary:
		failures.append("malformed director budgets %s" % profile_id)
	else:
		for budget: String in VALID_BUDGETS:
			if not budgets.get(budget) is int or budgets.get(budget, -1) < 0:
				failures.append("impossible director budget %s:%s" % [profile_id, budget])
	for field: String in [
		"global_cooldown",
		"tag_cooldown",
		"repetition_window",
		"target_window",
		"recovery_window",
		"min_spacing",
		"max_spacing",
		"max_chain",
		"max_retries",
		"max_targets_per_window",
		"pressure_window",
		"max_pressure_per_window"
	]:
		if not profile.get(field) is int or profile.get(field, -1) < 0:
			failures.append("invalid nonnegative profile field %s:%s" % [profile_id, field])
	if (
		profile.get("min_spacing", 0) > profile.get("max_spacing", 0)
		or profile.get("max_chain", 0) < 1
		or profile.get("max_retries", 0) < 1
	):
		failures.append("impossible spacing or retry limits %s" % profile_id)
	if (
		not profile.get("volatility") is int
		or profile.get("volatility", -1) < 0
		or profile.get("volatility", 101) > 100
	):
		failures.append("invalid volatility %s" % profile_id)
	for tag_field: String in ["allow_tags", "deny_tags"]:
		var tags: Variant = profile.get(tag_field, [])
		if (
			not tags is Array
			or tags.any(
				func(tag: Variant) -> bool: return not tag is String or not VALID_TAGS.has(tag)
			)
		):
			failures.append("unknown profile tag %s" % profile_id)
	var affinities: Variant = profile.get("tag_affinities", {})
	if not affinities is Dictionary:
		failures.append("malformed tag affinities %s" % profile_id)
	else:
		for tag: Variant in affinities:
			if not tag is String or not VALID_TAGS.has(tag) or not affinities[tag] is int:
				failures.append("unknown tag affinity %s" % profile_id)


func _validate_candidate(
	candidate: Dictionary,
	seen: Dictionary,
	rules_content: RulesContent,
	board_definition: BoardDefinition,
	failures: PackedStringArray
) -> void:
	var candidate_id: String = candidate.get("id", "")
	if (
		not _valid_id(candidate_id)
		or not candidate.get("version") is int
		or candidate.get("version", 0) < 1
	):
		failures.append("malformed director candidate identity")
		return
	if seen.has(candidate_id):
		failures.append("duplicate director candidate id %s" % candidate_id)
		return
	seen[candidate_id] = true
	if not VALID_CATEGORIES.has(candidate.get("category", "")):
		failures.append("invalid candidate category %s" % candidate_id)
	if not candidate.get("base_weight") is int or candidate.get("base_weight", -1) < 0:
		failures.append("invalid candidate base weight %s" % candidate_id)
	var tags: Variant = candidate.get("tags")
	if (
		not tags is Array
		or tags.is_empty()
		or tags.any(func(tag: Variant) -> bool: return not tag is String or not VALID_TAGS.has(tag))
	):
		failures.append("unknown candidate tag %s" % candidate_id)
	var conditions: Variant = candidate.get("conditions", [])
	if not conditions is Array:
		failures.append("malformed candidate conditions %s" % candidate_id)
	else:
		for condition: Variant in conditions:
			if not condition is Dictionary or not VALID_CONDITIONS.has(condition.get("type", "")):
				failures.append("invalid candidate condition %s" % candidate_id)
				continue
			if (
				condition.type.begins_with("metric_")
				and (
					not VALID_METRICS.has(condition.get("metric", ""))
					or not condition.get("value") is int
					or condition.value < 0
					or condition.value > 100
				)
			):
				failures.append("invalid metric condition %s" % candidate_id)
	var affinities: Variant = candidate.get("metric_affinities", {})
	if not affinities is Dictionary:
		failures.append("malformed candidate affinities %s" % candidate_id)
	else:
		for metric: Variant in affinities:
			if (
				not metric is String
				or not VALID_METRICS.has(metric)
				or not affinities[metric] is int
				or absi(affinities[metric]) > 100
			):
				failures.append("invalid candidate affinity %s" % candidate_id)
	if not VALID_TARGET_SCOPES.has(candidate.get("target_scope", "")):
		failures.append("invalid candidate target scope %s" % candidate_id)
	if (
		not VALID_BUDGETS.has(candidate.get("budget_kind", ""))
		or not candidate.get("budget_cost") is int
		or candidate.get("budget_cost", -1) < 0
	):
		failures.append("invalid candidate budget %s" % candidate_id)
	for field: String in [
		"cooldown", "repetition_window", "pressure_impact", "relief_impact", "tension_impact"
	]:
		if not candidate.get(field) is int or candidate.get(field, -1) < 0:
			failures.append("invalid candidate limit %s:%s" % [candidate_id, field])
	var payload: Variant = candidate.get("payload")
	if not payload is Dictionary or not VALID_PAYLOADS.has(payload.get("type", "")):
		failures.append("invalid candidate payload %s" % candidate_id)
		return
	match payload.type:
		"queue_event":
			if (
				rules_content == null
				or rules_content.event_by_id(payload.get("event_id", "")).is_empty()
			):
				failures.append("unknown candidate event reference %s" % candidate_id)
		"rules_effects":
			var effect_failures := PackedStringArray()
			if rules_content == null:
				failures.append("missing rules content for candidate %s" % candidate_id)
			else:
				rules_content._validate_effects(
					payload.get("effects", []), {}, board_definition, effect_failures
				)
				for failure: String in effect_failures:
					failures.append("candidate %s: %s" % [candidate_id, failure])
		"board_mutation":
			if board_definition == null or not payload.get("mutation") is Dictionary:
				failures.append("invalid candidate board reference %s" % candidate_id)
			else:
				var probe := BoardState.new(board_definition)
				if not probe._validate_mutation(payload.mutation).valid:
					failures.append("invalid candidate board reference %s" % candidate_id)
		"presentation":
			if (
				not payload.get("cue") is String
				or payload.get("cue", "").is_empty()
				or not payload.get("reduced_motion_safe", false) is bool
			):
				failures.append("invalid presentation payload %s" % candidate_id)
		"no_op":
			if candidate.get("category", "") != "no_op":
				failures.append("no-op payload/category mismatch %s" % candidate_id)


func _valid_id(value: Variant) -> bool:
	return (
		value is String
		and not value.is_empty()
		and value == value.to_lower()
		and value.is_valid_identifier()
	)
