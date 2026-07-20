class_name SocialContent
extends Resource

const VALID_VISIBILITIES: PackedStringArray = [
	"public", "seat_private", "faction_private", "diagnostics"
]
const VALID_REVEAL_POLICIES: PackedStringArray = ["public", "hidden", "revealable", "partial"]
const VALID_DISPOSITIONS: PackedStringArray = [
	"allied", "cooperative", "neutral", "wary", "hostile", "conditional"
]
const VALID_LIFECYCLES: PackedStringArray = [
	"active", "transformed", "defeated", "afterlife", "replacement", "escaped"
]
const VALID_TARGET_SCOPES: PackedStringArray = ["none", "self", "other", "any", "faction_other"]
const VALID_OBJECTIVE_SCOPES: PackedStringArray = ["shared", "faction", "individual", "afterlife"]
const VALID_OBJECTIVE_RESULTS: PackedStringArray = [
	"victory", "defeat", "escaped", "changed", "restless", "partial", "unresolved"
]
const VALID_CONDITION_TYPES: PackedStringArray = [
	"always",
	"rules_flag",
	"rules_counter_at_least",
	"board_feature",
	"faction_count_at_least",
	"seat_state",
	"action_used",
	"objective_complete",
]
const VALID_PROPOSAL_TYPES: PackedStringArray = [
	"rules_effects", "board_mutation", "role_transition", "presentation"
]
const VALID_ASSIGNMENT_POLICIES: PackedStringArray = ["fixed", "random_pool"]
const VALID_DIRECTOR_SIGNALS: PackedStringArray = [
	"revealed_faction_count",
	"public_hostility",
	"defeated_count",
	"restless_count",
	"public_conversion_pressure",
	"revealed_imbalance",
	"social_choice_pressure",
	"afterlife_support_available",
]


class SessionContract:
	extends RefCounted

	func public_view() -> Dictionary:
		return _contract_public_view()

	func seat_private_view(seat_number: int) -> Dictionary:
		return _contract_seat_private_view(seat_number)

	func faction_private_view(requester_seat: int) -> Dictionary:
		return _contract_faction_private_view(requester_seat)

	func diagnostics_view(spoilers_enabled: bool = false) -> Dictionary:
		return _contract_diagnostics_view(spoilers_enabled)

	func director_safe_signals() -> Dictionary:
		return _contract_director_safe_signals()

	func privacy_report() -> Dictionary:
		return _contract_privacy_report()

	func _contract_public_view() -> Dictionary:
		return {}

	func _contract_seat_private_view(_seat_number: int) -> Dictionary:
		return {}

	func _contract_faction_private_view(_requester_seat: int) -> Dictionary:
		return {}

	func _contract_diagnostics_view(_spoilers_enabled: bool = false) -> Dictionary:
		return {}

	func _contract_director_safe_signals() -> Dictionary:
		return {}

	func _contract_privacy_report() -> Dictionary:
		return {}

	func _accept() -> Dictionary:
		return {"accepted": true, "reason": ""}


class SessionData:
	extends RefCounted

	static func validate_snapshot(
		snapshot: Dictionary, content: SocialContent, snapshot_version: int
	) -> Dictionary:
		var reason: String = _snapshot_identity_rejection(snapshot, content, snapshot_version)
		if reason.is_empty():
			reason = _snapshot_scalar_rejection(snapshot)
		if reason.is_empty():
			reason = _snapshot_seat_rejection(snapshot, content)
		if reason.is_empty():
			reason = _snapshot_collection_rejection(snapshot)
		return {"accepted": reason.is_empty(), "reason": reason}

	static func _snapshot_identity_rejection(
		snapshot: Dictionary, content: SocialContent, snapshot_version: int
	) -> String:
		var reason: String = ""
		if snapshot.get("snapshot_version", -1) != snapshot_version:
			reason = "unsupported_snapshot_version"
		elif (
			snapshot.get("scenario_id", "") != content.scenario_id
			or snapshot.get("scenario_version", -1) != content.scenario_version
		):
			reason = "snapshot_content_mismatch"
		elif (
			content.mode_by_id(snapshot.get("mode_id", "")).is_empty()
			or content.mode_by_id(snapshot.get("requested_mode_id", "")).is_empty()
		):
			reason = "unknown_snapshot_content"
		return reason

	static func _snapshot_scalar_rejection(snapshot: Dictionary) -> String:
		var reason: String = ""
		for key: String in [
			"session_seed", "revision", "assignment_count", "audit_sequence", "action_step"
		]:
			if not snapshot.get(key) is int or snapshot.get(key, -1) < 0:
				reason = "malformed_snapshot"
				break
		if (
			reason.is_empty()
			and (not snapshot.get("rng") is Dictionary or not snapshot.get("seat_states") is Array)
		):
			reason = "malformed_snapshot"
		return reason

	static func _snapshot_seat_rejection(snapshot: Dictionary, content: SocialContent) -> String:
		var reason: String = ""
		var seats: Dictionary = {}
		for row: Variant in snapshot.seat_states:
			reason = _snapshot_seat_row_rejection(row, seats, content)
			if not reason.is_empty():
				break
			seats[row.seat] = true
		if reason.is_empty():
			var selected_mode: Dictionary = content.mode_by_id(snapshot.mode_id)
			if not selected_mode.get("supported_player_counts", []).has(seats.size()):
				reason = "impossible_snapshot_combination"
		return reason

	static func _snapshot_seat_row_rejection(
		row: Variant, seats: Dictionary, content: SocialContent
	) -> String:
		var reason: String = ""
		if (
			not row is Dictionary
			or not row.get("seat") is int
			or not row.get("state") is Dictionary
			or seats.has(row.seat)
		):
			return "malformed_snapshot"
		var state: Dictionary = row.state
		var form: Dictionary = content.role_by_id(state.get("form_id", ""))
		if (
			row.seat < 1
			or row.seat > SeatManager.MAX_SEATS
			or form.is_empty()
			or content.role_by_id(state.get("assigned_role_id", "")).is_empty()
			or content.faction_by_id(state.get("faction_id", "")).is_empty()
		):
			reason = "unknown_snapshot_content"
		elif not form.get("allowed_factions", []).has(state.get("faction_id", "")):
			reason = "impossible_snapshot_combination"
		elif (
			not VALID_LIFECYCLES.has(state.get("lifecycle", ""))
			or not state.get("objective_refs") is Array
		):
			reason = "malformed_snapshot"
		else:
			reason = _snapshot_seat_content_rejection(state, content)
		return reason

	static func _snapshot_seat_content_rejection(
		state: Dictionary, content: SocialContent
	) -> String:
		var reason: String = ""
		for objective_id: Variant in state.objective_refs:
			if not objective_id is String or content.objective_by_id(objective_id).is_empty():
				reason = "unknown_snapshot_content"
				break
		if reason.is_empty():
			for action_id: Variant in state.get("uses", {}).keys():
				if (
					not action_id is String
					or content.action_by_id(action_id).is_empty()
					or not state.uses[action_id] is int
					or state.uses[action_id] < 0
				):
					reason = "unknown_snapshot_content"
					break
		return reason

	static func _snapshot_collection_rejection(snapshot: Dictionary) -> String:
		var reason: String = ""
		for array_key: String in [
			"pending_late_seats", "audit_history", "public_history", "last_host_payloads"
		]:
			if not snapshot.get(array_key) is Array:
				reason = "malformed_snapshot"
				break
		if (
			reason.is_empty()
			and (
				not snapshot.get("transition_counts") is Dictionary
				or not snapshot.get("fallback_applied") is bool
				or not snapshot.get("fallback_message") is String
				or not snapshot.get("resolved_outcome") is Dictionary
			)
		):
			reason = "malformed_snapshot"
		return reason

	static func seat_state_rows(seat_states: Dictionary) -> Array[Dictionary]:
		var rows: Array[Dictionary] = []
		for seat_number: int in sorted_seats(seat_states):
			rows.append({"seat": seat_number, "state": seat_states[seat_number].duplicate(true)})
		return rows

	static func sorted_seats(seat_states: Dictionary) -> Array[int]:
		var result: Array[int] = []
		for key: Variant in seat_states.keys():
			result.append(int(key))
		result.sort()
		return result

	static func roman(seat_number: int, numerals: PackedStringArray) -> String:
		return numerals[clampi(seat_number - 1, 0, numerals.size() - 1)]

	static func json_copy(value: Variant) -> Variant:
		return _normalize_json_numbers(JSON.parse_string(JSON.stringify(value)))

	static func _normalize_json_numbers(value: Variant) -> Variant:
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

	static func int_array(values: Array) -> Array[int]:
		var result: Array[int] = []
		for value: Variant in values:
			result.append(int(value))
		return result

	static func dict_array(values: Array) -> Array[Dictionary]:
		var result: Array[Dictionary] = []
		for value: Variant in values:
			result.append(value.duplicate(true))
		return result


const VALID_FIXTURE_OPERATIONS: PackedStringArray = [
	"transition",
	"action",
	"connection_cycle",
	"rules_effects",
	"resolve_outcomes",
]

@export var scenario_id: String = ""
@export var scenario_version: int = 1
@export var factions: Array[Dictionary] = []
@export var roles: Array[Dictionary] = []
@export var objectives: Array[Dictionary] = []
@export var actions: Array[Dictionary] = []
@export var transitions: Array[Dictionary] = []
@export var modes: Array[Dictionary] = []
@export var fixtures: Array[Dictionary] = []


func validate(
	rules_content: RulesContent = null, board_definition: BoardDefinition = null
) -> PackedStringArray:
	var failures := PackedStringArray()
	if not _valid_id(scenario_id) or scenario_version < 1:
		failures.append("malformed social scenario identity")
	var faction_index := _index_definitions(factions, "faction", failures)
	var role_index := _index_definitions(roles, "role", failures)
	var objective_index := _index_definitions(objectives, "objective", failures)
	var action_index := _index_definitions(actions, "action", failures)
	var transition_index := _index_definitions(transitions, "transition", failures)
	var mode_index := _index_definitions(modes, "mode", failures)
	_index_definitions(fixtures, "fixture", failures)
	for faction: Dictionary in factions:
		_validate_faction(faction, faction_index, objective_index, transition_index, failures)
	for role: Dictionary in roles:
		_validate_role(
			role, faction_index, objective_index, action_index, transition_index, failures
		)
	for objective: Dictionary in objectives:
		_validate_objective(objective, failures)
	for action: Dictionary in actions:
		_validate_action(action, transition_index, rules_content, board_definition, failures)
	for transition: Dictionary in transitions:
		_validate_transition(transition, role_index, rules_content, board_definition, failures)
	for mode: Dictionary in modes:
		_validate_mode(mode, mode_index, role_index, objective_index, failures)
	for fixture: Dictionary in fixtures:
		_validate_fixture(fixture, mode_index, failures)
	_validate_transition_graph(transition_index, failures)
	_validate_afterlife_guarantees(role_index, action_index, objective_index, failures)
	return failures


func faction_by_id(stable_id: String) -> Dictionary:
	return _definition_by_id(factions, stable_id)


func role_by_id(stable_id: String) -> Dictionary:
	return _definition_by_id(roles, stable_id)


func objective_by_id(stable_id: String) -> Dictionary:
	return _definition_by_id(objectives, stable_id)


func action_by_id(stable_id: String) -> Dictionary:
	return _definition_by_id(actions, stable_id)


func transition_by_id(stable_id: String) -> Dictionary:
	return _definition_by_id(transitions, stable_id)


func mode_by_id(stable_id: String) -> Dictionary:
	return _definition_by_id(modes, stable_id)


func fixture_by_stage(stage: String) -> Dictionary:
	for fixture: Dictionary in fixtures:
		if fixture.get("evidence_stage", "") == stage:
			return fixture.duplicate(true)
	return {}


func _validate_faction(
	definition: Dictionary,
	faction_index: Dictionary,
	objective_index: Dictionary,
	transition_index: Dictionary,
	failures: PackedStringArray
) -> void:
	_validate_presentation(definition, "faction", failures)
	if not VALID_REVEAL_POLICIES.has(definition.get("membership_policy", "")):
		failures.append("invalid faction membership policy")
	var minimum: Variant = definition.get("minimum_seats")
	var maximum: Variant = definition.get("maximum_seats")
	if (
		not minimum is int
		or not maximum is int
		or minimum < 0
		or maximum < minimum
		or maximum > SeatManager.MAX_SEATS
	):
		failures.append("invalid faction seat bounds")
	for objective_id: Variant in definition.get("shared_objectives", []):
		if not objective_id is String or not objective_index.has(objective_id):
			failures.append("unknown faction objective")
	for transition_id: Variant in definition.get("transition_refs", []):
		if not transition_id is String or not transition_index.has(transition_id):
			failures.append("unknown faction transition")
	for target_id: Variant in definition.get("relationships", {}).keys():
		if not target_id is String or not faction_index.has(target_id):
			failures.append("unknown faction relationship")
		elif not VALID_DISPOSITIONS.has(definition.relationships[target_id]):
			failures.append("invalid faction relationship disposition")
	for signal_name: Variant in definition.get("director_signal_policy", []):
		if not signal_name is String or not VALID_DIRECTOR_SIGNALS.has(signal_name):
			failures.append("invalid faction Director signal")
	if (
		not definition.get("communication_allowed", false) is bool
		or not definition.get("result_group", "") is String
	):
		failures.append("malformed faction communication or result metadata")


func _validate_role(
	definition: Dictionary,
	faction_index: Dictionary,
	objective_index: Dictionary,
	action_index: Dictionary,
	transition_index: Dictionary,
	failures: PackedStringArray
) -> void:
	_validate_presentation(definition, "role", failures)
	if not faction_index.has(definition.get("starting_faction", "")):
		failures.append("role has no legal faction")
	if not VALID_REVEAL_POLICIES.has(definition.get("reveal_policy", "")):
		failures.append("invalid role reveal policy")
	if definition.get("reveal_policy", "") != "public":
		var cover: Variant = definition.get("public_cover")
		if (
			not cover is Dictionary
			or String(cover.get("label", "")).is_empty()
			or String(cover.get("symbol", "")).is_empty()
			or String(cover.get("pattern", "")).is_empty()
		):
			failures.append("hidden role has no safe public representation")
	var minimum: Variant = definition.get("minimum_players")
	var maximum: Variant = definition.get("maximum_players")
	if (
		not minimum is int
		or not maximum is int
		or minimum < 1
		or maximum < minimum
		or maximum > SeatManager.MAX_SEATS
	):
		failures.append("invalid role player bounds")
	for faction_id: Variant in definition.get("allowed_factions", []):
		if not faction_id is String or not faction_index.has(faction_id):
			failures.append("unknown role faction")
	for objective_id: Variant in definition.get("objective_refs", []):
		if not objective_id is String or not objective_index.has(objective_id):
			failures.append("unknown role objective")
	for action_id: Variant in definition.get("action_refs", []):
		if not action_id is String or not action_index.has(action_id):
			failures.append("unknown role action")
	for transition_id: Variant in definition.get("transition_refs", []):
		if not transition_id is String or not transition_index.has(transition_id):
			failures.append("unknown role transition")
	if (
		definition.get("objective_refs", []).is_empty()
		or definition.get("action_refs", []).is_empty()
	):
		failures.append("role cannot provide a legal objective and action")
	var afterlife_mapping: String = definition.get("afterlife_mapping", "")
	if not afterlife_mapping.is_empty() and not transition_index.has(afterlife_mapping):
		failures.append("unknown role afterlife mapping")
	if (
		not definition.get("tags", []) is Array
		or not definition.get("incompatibilities", []) is Array
	):
		failures.append("malformed role tags")
	var delay: Variant = definition.get("maximum_inactive_transition_delay", 0)
	if not delay is int or delay < 0:
		failures.append("invalid role inactive transition delay")


func _validate_objective(definition: Dictionary, failures: PackedStringArray) -> void:
	_validate_presentation(definition, "objective", failures)
	if (
		not VALID_OBJECTIVE_SCOPES.has(definition.get("scope", ""))
		or not VALID_VISIBILITIES.has(definition.get("visibility", ""))
	):
		failures.append("invalid objective scope or visibility")
	if not VALID_OBJECTIVE_RESULTS.has(definition.get("result", "")):
		failures.append("invalid objective result")
	if not definition.get("priority") is int or definition.get("priority", -1) < 0:
		failures.append("invalid objective priority")
	_validate_conditions(definition.get("conditions", []), failures)
	_validate_conditions(definition.get("partial_conditions", []), failures)
	if (
		not definition.get("reveal_at_end", false) is bool
		or not definition.get("epilogue_tags", []) is Array
	):
		failures.append("malformed objective outcome metadata")


func _validate_action(
	definition: Dictionary,
	transition_index: Dictionary,
	rules_content: RulesContent,
	board_definition: BoardDefinition,
	failures: PackedStringArray
) -> void:
	_validate_presentation(definition, "action", failures)
	if (
		not VALID_VISIBILITIES.has(definition.get("visibility", ""))
		or not VALID_TARGET_SCOPES.has(definition.get("target_scope", ""))
	):
		failures.append("invalid action visibility or target scope")
	var minimum: Variant = definition.get("minimum_targets")
	var maximum: Variant = definition.get("maximum_targets")
	var use_limit: Variant = definition.get("use_limit")
	var per_round: Variant = definition.get("per_round_limit")
	var cooldown: Variant = definition.get("cooldown")
	if (
		not minimum is int
		or not maximum is int
		or minimum < 0
		or maximum < minimum
		or maximum > SeatManager.MAX_SEATS
	):
		failures.append("invalid action target bounds")
	elif definition.get("target_scope", "") == "none" and (minimum != 0 or maximum != 0):
		failures.append("targetless action has target bounds")
	elif definition.get("target_scope", "") == "self" and maximum > 1:
		failures.append("self action has impossible target bounds")
	if (
		not use_limit is int
		or not per_round is int
		or not cooldown is int
		or use_limit < 0
		or per_round < 0
		or cooldown < 0
	):
		failures.append("invalid action use limit or cooldown")
	for lifecycle: Variant in definition.get("allowed_lifecycles", []):
		if not lifecycle is String or not VALID_LIFECYCLES.has(lifecycle):
			failures.append("invalid action lifecycle")
	if definition.get("allowed_lifecycles", []).is_empty():
		failures.append("action has no legal lifecycle")
	for proposal: Variant in definition.get("proposals", []):
		if not proposal is Dictionary or not VALID_PROPOSAL_TYPES.has(proposal.get("type", "")):
			failures.append("invalid action proposal")
			continue
		_validate_proposal(proposal, transition_index, rules_content, board_definition, failures)


func _validate_transition(
	definition: Dictionary,
	role_index: Dictionary,
	rules_content: RulesContent,
	board_definition: BoardDefinition,
	failures: PackedStringArray
) -> void:
	if (
		String(definition.get("label", "")).is_empty()
		or not VALID_VISIBILITIES.has(definition.get("visibility", ""))
		or not _valid_id(definition.get("trigger", ""))
	):
		failures.append("malformed transition presentation")
	if not role_index.has(definition.get("target_form", "")):
		failures.append("unknown transition target form")
	if definition.get("source_forms", []).is_empty():
		failures.append("transition has no source form")
	for source_id: Variant in definition.get("source_forms", []):
		if not source_id is String or not role_index.has(source_id):
			failures.append("unknown transition source form")
	if (
		not definition.get("max_chain") is int
		or definition.get("max_chain", 0) < 1
		or definition.get("max_chain", 0) > 16
	):
		failures.append("unbounded transition chain")
	var patch: Variant = definition.get("state_patch")
	if not patch is Dictionary or not VALID_LIFECYCLES.has(patch.get("lifecycle", "active")):
		failures.append("invalid transition state patch")
	_validate_rules_effects(
		definition.get("downstream_effects", []), rules_content, board_definition, failures
	)


func _validate_mode(
	definition: Dictionary,
	mode_index: Dictionary,
	role_index: Dictionary,
	objective_index: Dictionary,
	failures: PackedStringArray
) -> void:
	if (
		String(definition.get("label", "")).is_empty()
		or not VALID_ASSIGNMENT_POLICIES.has(definition.get("assignment_policy", ""))
	):
		failures.append("malformed social mode")
	var counts: Variant = definition.get("supported_player_counts")
	if not counts is Array or counts.is_empty():
		failures.append("mode has no supported player counts")
	else:
		for count: Variant in counts:
			if not count is int or count < 1 or count > SeatManager.MAX_SEATS:
				failures.append("invalid mode player count")
	var fallback_id: String = definition.get("fallback_mode", "")
	if not fallback_id.is_empty() and not mode_index.has(fallback_id):
		failures.append("unknown mode fallback")
	elif fallback_id == definition.get("id", ""):
		failures.append("recursive mode fallback")
	if not role_index.has(definition.get("default_role_id", "")):
		failures.append("unknown default role")
	var pool_total: int = 0
	for assignment: Variant in definition.get("assignment_pool", []):
		if (
			not assignment is Dictionary
			or not role_index.has(assignment.get("role_id", ""))
			or not assignment.get("count") is int
			or assignment.get("count", 0) < 1
		):
			failures.append("malformed assignment pool")
		else:
			pool_total += assignment.count
	var fixed_seats: Dictionary = {}
	for assignment: Variant in definition.get("fixed_assignments", []):
		if (
			not assignment is Dictionary
			or not assignment.get("seat") is int
			or assignment.get("seat", 0) < 1
			or assignment.get("seat", 0) > SeatManager.MAX_SEATS
			or fixed_seats.has(assignment.get("seat"))
			or not role_index.has(assignment.get("role_id", ""))
		):
			failures.append("malformed fixed assignment")
		else:
			fixed_seats[assignment.seat] = true
	for count: Variant in definition.get("supported_player_counts", []):
		if (
			count is int
			and (
				pool_total > count
				or fixed_seats.keys().any(func(seat: Variant) -> bool: return seat > count)
			)
		):
			failures.append("impossible assignment plan")
	for combination_key: String in ["required_combinations", "forbidden_combinations"]:
		if not definition.get(combination_key, []) is Array:
			failures.append("malformed mode combination policy")
			continue
		for role_id: Variant in definition.get(combination_key, []):
			if not role_id is String or not role_index.has(role_id):
				failures.append("unknown mode combination role")
	for objective_id: Variant in definition.get("objective_refs", []):
		if not objective_id is String or not objective_index.has(objective_id):
			failures.append("unknown mode objective")
	for signal_name: Variant in definition.get("director_signal_allowlist", []):
		if not signal_name is String or not VALID_DIRECTOR_SIGNALS.has(signal_name):
			failures.append("invalid mode Director signal")
	for key: String in [
		"assignment_retry_limit", "transition_chain_limit", "maximum_inactive_transition_delay"
	]:
		if (
			not definition.get(key) is int
			or definition.get(key, 0) < 1
			or definition.get(key, 0) > 32
		):
			failures.append("invalid mode bound")
	if (
		not definition.get("privacy_policy") is Dictionary
		or not definition.get("terminal_policy") is Dictionary
		or not definition.get("afterlife_enabled") is bool
	):
		failures.append("malformed mode policy")


func _validate_fixture(
	definition: Dictionary, mode_index: Dictionary, failures: PackedStringArray
) -> void:
	if (
		not mode_index.has(definition.get("mode_id", ""))
		or String(definition.get("evidence_stage", "")).is_empty()
	):
		failures.append("malformed social fixture")
	if (
		not definition.get("seat_count") is int
		or definition.get("seat_count", 0) < 1
		or definition.get("seat_count", 0) > SeatManager.MAX_SEATS
	):
		failures.append("invalid fixture seat count")
	for operation: Variant in definition.get("operations", []):
		if (
			not operation is Dictionary
			or not VALID_FIXTURE_OPERATIONS.has(operation.get("type", ""))
		):
			failures.append("invalid fixture operation")
	if not definition.get("view") is Dictionary:
		failures.append("malformed fixture view")


func _validate_proposal(
	proposal: Dictionary,
	transition_index: Dictionary,
	rules_content: RulesContent,
	board_definition: BoardDefinition,
	failures: PackedStringArray
) -> void:
	match proposal.get("type", ""):
		"rules_effects":
			_validate_rules_effects(
				proposal.get("effects", []), rules_content, board_definition, failures
			)
		"board_mutation":
			_validate_rules_effects(
				[{"type": "board_mutation", "mutation": proposal.get("mutation", {})}],
				rules_content,
				board_definition,
				failures
			)
		"role_transition":
			if (
				not transition_index.has(proposal.get("transition_id", ""))
				or not proposal.get("target", "") in ["self", "selected"]
			):
				failures.append("invalid action transition proposal")
		"presentation":
			if (
				not VALID_VISIBILITIES.has(proposal.get("visibility", ""))
				or String(proposal.get("message", "")).is_empty()
			):
				failures.append("invalid action presentation proposal")


func _validate_rules_effects(
	effects: Variant,
	rules_content: RulesContent,
	board_definition: BoardDefinition,
	failures: PackedStringArray
) -> void:
	if not effects is Array:
		failures.append("malformed downstream effects")
		return
	if rules_content != null:
		rules_content._validate_effects(effects, {}, board_definition, failures)


func _validate_conditions(conditions: Variant, failures: PackedStringArray) -> void:
	if not conditions is Array:
		failures.append("malformed objective conditions")
		return
	for condition: Variant in conditions:
		if not condition is Dictionary or not VALID_CONDITION_TYPES.has(condition.get("type", "")):
			failures.append("unsupported objective condition")


func _validate_transition_graph(transition_index: Dictionary, failures: PackedStringArray) -> void:
	var adjacency: Dictionary = {}
	for role: Dictionary in roles:
		adjacency[role.id] = []
	for transition: Dictionary in transitions:
		for source_id: String in transition.get("source_forms", []):
			if adjacency.has(source_id):
				adjacency[source_id].append(transition.target_form)
	for root_id: String in adjacency:
		if _graph_has_unbounded_cycle(root_id, root_id, adjacency, transition_index, {}):
			failures.append("circular transition graph without explicit bounds")


func _graph_has_unbounded_cycle(
	root_id: String,
	current_id: String,
	adjacency: Dictionary,
	transition_index: Dictionary,
	visited: Dictionary
) -> bool:
	if visited.has(current_id):
		return current_id == root_id and _transition_bounds_missing(transition_index)
	visited[current_id] = true
	for next_id: String in adjacency.get(current_id, []):
		if _graph_has_unbounded_cycle(
			root_id, next_id, adjacency, transition_index, visited.duplicate()
		):
			return true
	return false


func _transition_bounds_missing(transition_index: Dictionary) -> bool:
	for definition: Dictionary in transition_index.values():
		if definition.get("max_chain", 0) < 1:
			return true
	return false


func _validate_afterlife_guarantees(
	_role_index: Dictionary,
	action_index: Dictionary,
	objective_index: Dictionary,
	failures: PackedStringArray
) -> void:
	for role: Dictionary in roles:
		if not role.get("tags", []).has("afterlife"):
			continue
		var meaningful_action: bool = false
		for action_id: String in role.get("action_refs", []):
			var action: Dictionary = action_index.get(action_id, {})
			if not action.get("proposals", []).is_empty():
				meaningful_action = true
		var meaningful_objective: bool = false
		for objective_id: String in role.get("objective_refs", []):
			meaningful_objective = meaningful_objective or objective_index.has(objective_id)
		if (
			not meaningful_action
			or not meaningful_objective
			or role.get("maximum_inactive_transition_delay", 99) > 1
		):
			failures.append("afterlife mapping can lead to permanent inactivity")


func _validate_presentation(
	definition: Dictionary, kind: String, failures: PackedStringArray
) -> void:
	var label: Variant = definition.get("label")
	var symbol: Variant = definition.get("symbol")
	var pattern: Variant = definition.get("pattern")
	if (
		not label is String
		or label.is_empty()
		or not symbol is String
		or symbol.is_empty()
		or symbol.length() > 4
		or not pattern is String
		or pattern.is_empty()
	):
		failures.append("malformed %s presentation" % kind)


func _index_definitions(
	definitions: Array[Dictionary], kind: String, failures: PackedStringArray
) -> Dictionary:
	var index: Dictionary = {}
	for definition: Dictionary in definitions:
		var stable_id: String = definition.get("id", "")
		if (
			not _valid_id(stable_id)
			or not definition.get("version") is int
			or definition.get("version", 0) < 1
		):
			failures.append("malformed %s identity" % kind)
		elif index.has(stable_id):
			failures.append("duplicate %s id" % kind)
		else:
			index[stable_id] = definition
	return index


func _definition_by_id(definitions: Array[Dictionary], stable_id: String) -> Dictionary:
	for definition: Dictionary in definitions:
		if definition.get("id", "") == stable_id:
			return definition.duplicate(true)
	return {}


func _valid_id(value: Variant) -> bool:
	if not value is String or value.is_empty() or value[0] == "_" or value[-1] == "_":
		return false
	for character: String in value:
		if not character in "abcdefghijklmnopqrstuvwxyz0123456789_":
			return false
	return true


func _faction(
	stable_id: String,
	friendly_label: String,
	symbol: String,
	pattern: String,
	membership_policy: String,
	communication_allowed: bool,
	result_group: String,
	director_signals: Array[String]
) -> Dictionary:
	return {
		"id": stable_id,
		"version": 1,
		"label": friendly_label,
		"symbol": symbol,
		"pattern": pattern,
		"presentation_tags": [result_group],
		"membership_policy": membership_policy,
		"minimum_seats": 0,
		"maximum_seats": SeatManager.MAX_SEATS,
		"relationships": {},
		"shared_objectives": [],
		"transition_refs": [],
		"communication_allowed": communication_allowed,
		"result_group": result_group,
		"director_signal_policy": director_signals,
		"presentation": {"tone": result_group},
	}


func _transition(
	stable_id: String,
	friendly_label: String,
	source_forms: Array[String],
	target_form: String,
	trigger: String,
	visibility: String,
	max_chain: int,
	state_patch: Dictionary
) -> Dictionary:
	return {
		"id": stable_id,
		"version": 1,
		"label": friendly_label,
		"source_forms": source_forms,
		"target_form": target_form,
		"trigger": trigger,
		"visibility": visibility,
		"max_chain": max_chain,
		"state_patch": state_patch,
		"downstream_effects": [],
		"presentation": {"public_message": "%s." % friendly_label},
	}


func _mode(
	stable_id: String,
	friendly_label: String,
	supported_counts: Array,
	policy: String,
	default_role_id: String,
	pool: Array[Dictionary],
	fixed: Array[Dictionary],
	fallback: String,
	afterlife_enabled: bool
) -> Dictionary:
	return {
		"id": stable_id,
		"version": 1,
		"label": friendly_label,
		"supported_player_counts": supported_counts,
		"assignment_policy": policy,
		"default_role_id": default_role_id,
		"assignment_pool": pool,
		"fixed_assignments": fixed,
		"required_combinations": [],
		"forbidden_combinations": [],
		"fallback_mode": fallback,
		"objective_refs": ["secure_lantern_house"],
		"afterlife_enabled": afterlife_enabled,
		"privacy_policy":
		{
			"public_shared_screen": true,
			"seat_private_requires_obscure": true,
			"late_join": "deferred"
		},
		"terminal_policy": {"tie": "compatible_highest_priority", "result_key": "social_outcome"},
		"assignment_retry_limit": 8,
		"transition_chain_limit": 8,
		"maximum_inactive_transition_delay": 1,
		"director_signal_allowlist": VALID_DIRECTOR_SIGNALS.duplicate(),
	}


func _fixture(
	stable_id: String,
	evidence_stage: String,
	mode_id: String,
	seat_count: int,
	operations: Array[Dictionary],
	view: Dictionary
) -> Dictionary:
	return {
		"id": stable_id,
		"version": 1,
		"evidence_stage": evidence_stage,
		"mode_id": mode_id,
		"seat_count": seat_count,
		"operations": operations,
		"view": view,
	}
