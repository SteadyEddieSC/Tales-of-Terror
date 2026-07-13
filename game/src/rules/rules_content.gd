class_name RulesContent
extends Resource

const VALID_EFFECTS: PackedStringArray = [
	"board_mutation", "set_counter", "add_counter", "set_flag", "draw_card", "grant_card",
	"discard_card", "exhaust_card", "remove_card", "add_item", "remove_item", "queue_event",
	"history", "set_result",
]
const VALID_CONDITIONS: PackedStringArray = ["always", "flag_equals", "counter_at_least", "seat_has_item", "phase_is"]
const VALID_CARD_POLICIES: PackedStringArray = ["discard", "exhaust", "retain", "remove"]

@export var scenario_id: String = ""
@export var scenario_version: int = 1
@export var phases: Array[String] = []
@export var events: Array[Dictionary] = []
@export var cards: Array[Dictionary] = []
@export var items: Array[Dictionary] = []
@export var initial_deck: Array[String] = []

func validate(board_definition: BoardDefinition = null) -> PackedStringArray:
	var failures := PackedStringArray()
	if not _valid_id(scenario_id) or scenario_version < 1:
		failures.append("malformed scenario identity")
	if phases.is_empty() or phases.any(func(value: String) -> bool: return not _valid_id(value)):
		failures.append("malformed phase definition")
	var event_ids: Dictionary = {}
	var card_ids: Dictionary = {}
	var item_ids: Dictionary = {}
	for event: Dictionary in events:
		_validate_definition_identity(event, event_ids, "event", failures)
	for card: Dictionary in cards:
		_validate_definition_identity(card, card_ids, "card", failures)
	for item: Dictionary in items:
		_validate_definition_identity(item, item_ids, "item", failures)
	for event: Dictionary in events:
		_validate_event(event, event_ids, board_definition, failures)
	for card: Dictionary in cards:
		_validate_card(card, board_definition, failures)
	for card_id: String in initial_deck:
		if not card_ids.has(card_id):
			failures.append("missing deck card %s" % card_id)
	_validate_follow_up_graph(event_ids, failures)
	return failures

func event_by_id(event_id: String) -> Dictionary:
	for event: Dictionary in events:
		if event.get("id", "") == event_id:
			return event.duplicate(true)
	return {}

func card_by_id(card_id: String) -> Dictionary:
	for card: Dictionary in cards:
		if card.get("id", "") == card_id:
			return card.duplicate(true)
	return {}

func has_item(item_id: String) -> bool:
	return items.any(func(item: Dictionary) -> bool: return item.get("id", "") == item_id)

func _validate_definition_identity(definition: Dictionary, seen: Dictionary, kind: String, failures: PackedStringArray) -> void:
	var stable_id: String = definition.get("id", "")
	if not _valid_id(stable_id) or not definition.get("version") is int or definition.get("version", 0) < 1:
		failures.append("malformed %s identity" % kind)
	elif seen.has(stable_id):
		failures.append("duplicate %s id %s" % [kind, stable_id])
	else:
		seen[stable_id] = definition

func _validate_event(event: Dictionary, event_ids: Dictionary, board_definition: BoardDefinition, failures: PackedStringArray) -> void:
	if not event.get("conditions", []) is Array or not event.get("prompts", []) is Array or not event.get("effects", []) is Array:
		failures.append("malformed event %s" % event.get("id", "?"))
		return
	_validate_conditions(event.get("conditions", []), failures)
	for prompt: Dictionary in event.get("prompts", []):
		_validate_prompt(prompt, failures)
		for option: Dictionary in prompt.get("options", []):
			_validate_effects(option.get("effects", []), event_ids, board_definition, failures)
	_validate_effects(event.get("effects", []), event_ids, board_definition, failures)
	if event.has("check"):
		if not event.check is Dictionary:
			failures.append("malformed event check")
		if not event.get("outcome_effects", {}) is Dictionary:
			failures.append("malformed outcome effects")
		else:
			for outcome_effects: Variant in event.outcome_effects.values():
				_validate_effects(outcome_effects, event_ids, board_definition, failures)
	for follow_up: Variant in event.get("follow_ups", []):
		if not follow_up is String or not event_ids.has(follow_up):
			failures.append("invalid follow-up in %s" % event.get("id", "?"))

func _validate_card(card: Dictionary, board_definition: BoardDefinition, failures: PackedStringArray) -> void:
	if not VALID_CARD_POLICIES.has(card.get("policy", "")):
		failures.append("invalid card policy %s" % card.get("id", "?"))
	_validate_conditions(card.get("conditions", []), failures)
	_validate_effects(card.get("effects", []), {}, board_definition, failures)

func _validate_prompt(prompt: Dictionary, failures: PackedStringArray) -> void:
	var options: Variant = prompt.get("options")
	var minimum: Variant = prompt.get("min_selections")
	var maximum: Variant = prompt.get("max_selections")
	if not _valid_id(prompt.get("id", "")) or not options is Array or options.is_empty() or not minimum is int or not maximum is int or minimum < 0 or maximum < minimum or maximum > options.size():
		failures.append("impossible selection rules")
		return
	var option_ids: Dictionary = {}
	for option: Variant in options:
		if not option is Dictionary or not _valid_id(option.get("id", "")) or option_ids.has(option.get("id", "")):
			failures.append("malformed prompt option")
		else:
			option_ids[option.id] = true

func _validate_conditions(conditions: Variant, failures: PackedStringArray) -> void:
	if not conditions is Array:
		failures.append("malformed conditions")
		return
	for condition: Variant in conditions:
		if not condition is Dictionary or not VALID_CONDITIONS.has(condition.get("type", "")):
			failures.append("unsupported condition")

func _validate_effects(effects: Variant, event_ids: Dictionary, board_definition: BoardDefinition, failures: PackedStringArray) -> void:
	if not effects is Array:
		failures.append("malformed effects")
		return
	for effect: Variant in effects:
		if not effect is Dictionary or not VALID_EFFECTS.has(effect.get("type", "")):
			failures.append("unsupported effect")
			continue
		if effect.type == "queue_event" and not event_ids.is_empty() and not event_ids.has(effect.get("event_id", "")):
			failures.append("missing queued event")
		if effect.type == "board_mutation" and board_definition != null:
			var mutation: Dictionary = effect.get("mutation", {})
			if mutation.get("type", "") == BoardMutation.SET_CONNECTOR_STATE and board_definition.get_connector(mutation.get("connector_id", "")).is_empty():
				failures.append("missing board connector")

func _validate_follow_up_graph(event_ids: Dictionary, failures: PackedStringArray) -> void:
	for event_id: String in event_ids:
		if _has_cycle(event_id, event_id, event_ids, {}):
			failures.append("recursive event loop %s" % event_id)

func _has_cycle(root_id: String, current_id: String, event_ids: Dictionary, visited: Dictionary) -> bool:
	if visited.has(current_id):
		return current_id == root_id
	visited[current_id] = true
	var definition: Dictionary = event_ids[current_id]
	var next_ids: Array = definition.get("follow_ups", []).duplicate()
	for effect: Dictionary in definition.get("effects", []):
		if effect.get("type", "") == "queue_event":
			next_ids.append(effect.get("event_id", ""))
	for next_id: String in next_ids:
		if event_ids.has(next_id) and _has_cycle(root_id, next_id, event_ids, visited.duplicate()):
			return true
	return false

func _valid_id(value: Variant) -> bool:
	return value is String and not value.is_empty() and value == value.to_lower() and value.is_valid_identifier()
