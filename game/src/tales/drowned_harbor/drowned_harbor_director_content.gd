class_name DrownedHarborDirectorContent
extends DirectorContent

const PUBLIC_INPUT_KEYS: PackedStringArray = [
	"authoritative_revision", "connected_seat_count", "stage_id"
]


func _init() -> void:
	content_id = "drowned_harbor_scaffold_director"
	content_version = 1
	var bounds: Dictionary = {}
	var weights: Dictionary = {}
	for metric: String in VALID_METRICS:
		bounds[metric] = [0, 100]
		weights[metric] = 0
	profiles = [
		{
			"id": "scaffold_off",
			"version": 1,
			"display_name": "Scaffold Off",
			"mode": "off",
			"pacing_curve": [{"progress": 0, "act": "scaffold", "low": 0, "high": 1}],
			"metric_weights": weights,
			"normalization_bounds": bounds,
			"tag_affinities": {},
			"budgets":
			{
				"pressure": 0,
				"relief": 0,
				"clue": 0,
				"scarcity": 0,
				"ambient": 0,
				"intervention": 0,
			},
			"global_cooldown": 0,
			"tag_cooldown": 0,
			"repetition_window": 1,
			"target_window": 1,
			"recovery_window": 1,
			"min_spacing": 0,
			"max_spacing": 1,
			"max_chain": 1,
			"max_retries": 1,
			"max_targets_per_window": 1,
			"pressure_window": 1,
			"max_pressure_per_window": 0,
			"volatility": 0,
			"allow_tags": [],
			"deny_tags": [],
			"reduced_volatility": true,
		},
	]
	candidates = [
		{
			"id": "scaffold_no_op",
			"version": 1,
			"name": "No Director Action",
			"summary": "The empty scaffold never applies Director pressure.",
			"category": "no_op",
			"tags": ["ambient"],
			"base_weight": 1,
			"conditions": [{"type": "always"}],
			"metric_affinities": {},
			"target_scope": "none",
			"budget_kind": "ambient",
			"budget_cost": 0,
			"cooldown": 0,
			"repetition_window": 1,
			"pressure_impact": 0,
			"relief_impact": 0,
			"tension_impact": 0,
			"payload": {"type": "no_op"},
			"presentation": {"symbol": "-", "pattern": "open ring", "tone": "neutral"},
		},
	]


func authorized_input_keys() -> PackedStringArray:
	return PUBLIC_INPUT_KEYS.duplicate()


func accepts_input(input: Dictionary) -> bool:
	for key: Variant in input:
		if not key is String or not PUBLIC_INPUT_KEYS.has(key):
			return false
	return input.size() == PUBLIC_INPUT_KEYS.size()
