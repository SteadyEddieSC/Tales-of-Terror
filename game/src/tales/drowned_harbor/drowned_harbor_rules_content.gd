class_name DrownedHarborRulesContent
extends RulesContent

const ENTRY_STAGE_ID: String = "scaffold_entry"
const TERMINAL_STAGE_ID: String = "scaffold_terminal"
const EXIT_INTENT: String = "acknowledge_scaffold_exit"


func _init() -> void:
	scenario_id = "drowned_harbor_scaffold_rules"
	scenario_version = 1
	phases = [ENTRY_STAGE_ID, TERMINAL_STAGE_ID]
	events = []
	cards = []
	items = []
	initial_deck = []


func supported_intents() -> PackedStringArray:
	return PackedStringArray([EXIT_INTENT])
