class_name LanternHouseDirectorContent
extends DirectorContent

func _init() -> void:
	content_id = "lantern_house_director"
	content_version = 1
	var bounds: Dictionary = {}
	for metric: String in VALID_METRICS:
		bounds[metric] = [0, 100]
	profiles = [
		_profile("off", "Off / Authored Only", "off", 0, 0, 0, 0, true, bounds),
		_profile("gentle", "Story / Gentle", "adaptive", 6, 12, 2, 45, true, bounds),
		_profile("standard", "Standard", "adaptive", 10, 8, 4, 65, false, bounds),
		_profile("dread", "Relentless / Dread", "adaptive", 14, 5, 6, 82, false, bounds),
		_profile("fixed", "Fixed Test", "fixed", 8, 8, 4, 0, true, bounds),
	]
	candidates = [
		{
			"id": "quiet_lantern", "version": 1, "name": "A Quiet Lantern", "summary": "A steady flame gives the group room to recover.",
			"category": "relief", "tags": ["relief", "recovery", "light", "gentle"], "base_weight": 18,
			"conditions": [{"type": "metric_at_least", "metric": "resource_pressure", "value": 45}],
			"metric_affinities": {"resource_pressure": 45, "failure_pressure": 35}, "target_scope": "active_any",
			"budget_kind": "relief", "budget_cost": 2, "cooldown": 2, "repetition_window": 3,
			"pressure_impact": 0, "relief_impact": 18, "tension_impact": 12,
			"payload": {"type": "rules_effects", "effects": [{"type": "add_counter", "counter_id": "hope", "value": 1}]},
			"presentation": {"symbol": "◇", "pattern": "soft rings", "tone": "reassuring"},
		},
		{
			"id": "keeper_marks_the_way", "version": 1, "name": "The Keeper Marks the Way", "summary": "A clear environmental clue points toward unfinished work.",
			"category": "hint", "tags": ["clue", "nudge", "host", "gentle"], "base_weight": 16,
			"conditions": [{"type": "always"}], "metric_affinities": {"stalled_steps": 60, "prompt_latency": 35}, "target_scope": "none",
			"budget_kind": "clue", "budget_cost": 2, "cooldown": 2, "repetition_window": 3,
			"pressure_impact": 0, "relief_impact": 8, "tension_impact": 4,
			"payload": {"type": "presentation", "cue": "mark_unfinished_objective", "message": "A pale chalk mark circles the unfinished path.", "speaker_key": "scenario_host", "reduced_motion_safe": true},
			"presentation": {"symbol": "✧", "pattern": "chalk dashes", "tone": "guiding"},
		},
		{
			"id": "oil_in_the_larder", "version": 1, "name": "Oil in the Larder", "summary": "A bounded resource appears for the seat carrying the least momentum.",
			"category": "relief", "tags": ["relief", "recovery", "light"], "base_weight": 12,
			"conditions": [{"type": "metric_at_least", "metric": "failure_pressure", "value": 50}], "metric_affinities": {"failure_pressure": 45, "resource_pressure": 25}, "target_scope": "active_any",
			"budget_kind": "relief", "budget_cost": 3, "cooldown": 4, "repetition_window": 4,
			"pressure_impact": 0, "relief_impact": 22, "tension_impact": 14,
			"payload": {"type": "rules_effects", "effects": [{"type": "add_item", "item_id": "lantern_oil"}]},
			"presentation": {"symbol": "◉", "pattern": "radiant lines", "tone": "hopeful"},
		},
		{
			"id": "echoes_close_in", "version": 1, "name": "Echoes Close In", "summary": "The house answers confident progress with bounded pressure.",
			"category": "pressure", "tags": ["pressure", "scarcity", "sound", "dramatic"], "base_weight": 15,
			"conditions": [{"type": "metric_at_least", "metric": "progress", "value": 30}], "metric_affinities": {"progress": 55, "resource_pressure": -30, "failure_pressure": -40}, "target_scope": "active_negative",
			"budget_kind": "pressure", "budget_cost": 3, "cooldown": 2, "repetition_window": 3,
			"pressure_impact": 16, "relief_impact": 0, "tension_impact": 18,
			"payload": {"type": "rules_effects", "effects": [{"type": "add_counter", "counter_id": "dread", "value": 1}]},
			"presentation": {"symbol": "▲", "pattern": "closing chevrons", "tone": "urgent"},
		},
		{
			"id": "mist_crosses_the_gallery", "version": 1, "name": "Mist Crosses the Gallery", "summary": "A validated hazard request raises pressure without closing recovery paths.",
			"category": "board", "tags": ["pressure", "board", "hazard", "dramatic"], "base_weight": 13,
			"conditions": [{"type": "metric_at_least", "metric": "progress", "value": 35}, {"type": "board_hazard_below", "value": 70}], "metric_affinities": {"progress": 45, "hazard_pressure": -40, "failure_pressure": -45}, "target_scope": "none",
			"budget_kind": "pressure", "budget_cost": 4, "cooldown": 4, "repetition_window": 5,
			"pressure_impact": 22, "relief_impact": 0, "tension_impact": 24,
			"payload": {"type": "board_mutation", "mutation": {"type": "set_hazard", "space_id": "narrow_gallery", "value_id": "director_mist", "active": true}},
			"presentation": {"symbol": "▰", "pattern": "warning chevrons", "tone": "ominous"},
		},
		{
			"id": "house_recalls_the_council", "version": 1, "name": "The House Recalls the Council", "summary": "An eligible authored event is queued through the rules authority.",
			"category": "event", "tags": ["event", "nudge", "clue"], "base_weight": 9,
			"conditions": [{"type": "metric_at_least", "metric": "stalled_steps", "value": 40}], "metric_affinities": {"stalled_steps": 45, "prompt_latency": 20}, "target_scope": "none",
			"budget_kind": "intervention", "budget_cost": 2, "cooldown": 5, "repetition_window": 5,
			"pressure_impact": 2, "relief_impact": 2, "tension_impact": 8,
			"payload": {"type": "queue_event", "event_id": "gallery_council"},
			"presentation": {"symbol": "◈", "pattern": "concentric frame", "tone": "inviting"},
		},
		{
			"id": "candles_lean_east", "version": 1, "name": "The Candles Lean East", "summary": "A sensory-safe ambient omen changes presentation only.",
			"category": "ambient", "tags": ["ambient", "light", "sound", "nudge"], "base_weight": 8,
			"conditions": [{"type": "always"}], "metric_affinities": {"stalled_steps": 30, "progress": 10}, "target_scope": "none",
			"budget_kind": "ambient", "budget_cost": 1, "cooldown": 2, "repetition_window": 3,
			"pressure_impact": 0, "relief_impact": 0, "tension_impact": 6,
			"payload": {"type": "presentation", "cue": "candles_lean_east", "message": "Every candle leans toward the eastern passage.", "speaker_key": "scenario_host", "reduced_motion_safe": true},
			"presentation": {"symbol": "≋", "pattern": "eastward lines", "tone": "watchful"},
		},
		{
			"id": "hold_the_breath", "version": 1, "name": "Hold the Breath", "summary": "The Director deliberately leaves the authored state unchanged.",
			"category": "no_op", "tags": ["breath"], "base_weight": 0,
			"conditions": [{"type": "always"}], "metric_affinities": {}, "target_scope": "none",
			"budget_kind": "intervention", "budget_cost": 0, "cooldown": 0, "repetition_window": 0,
			"pressure_impact": 0, "relief_impact": 0, "tension_impact": 0,
			"payload": {"type": "no_op"},
			"presentation": {"symbol": "○", "pattern": "open ring", "tone": "quiet"},
		},
	]

func _profile(profile_id: String, display_name: String, mode: String, pressure: int, relief: int, volatility: int, pressure_limit: int, reduced: bool, bounds: Dictionary) -> Dictionary:
	var weights: Dictionary = {}
	for metric: String in VALID_METRICS:
		weights[metric] = 1
	return {
		"id": profile_id, "version": 1, "display_name": display_name, "mode": mode,
		"pacing_curve": [
			{"progress": 0, "act": "arrival", "low": 20, "high": 38},
			{"progress": 35, "act": "deepening", "low": 38, "high": 62},
			{"progress": 70, "act": "reckoning", "low": 58, "high": 82},
		],
		"metric_weights": weights, "normalization_bounds": bounds.duplicate(true),
		"tag_affinities": {"pressure": pressure, "relief": relief, "clue": relief, "ambient": 2},
		"budgets": {"pressure": pressure_limit, "relief": 30, "clue": 24, "scarcity": 18, "ambient": 20, "intervention": 30},
		"global_cooldown": 0, "tag_cooldown": 1, "repetition_window": 4,
		"target_window": 5, "max_targets_per_window": 2, "recovery_window": 2,
		"min_spacing": 0, "max_spacing": 5, "volatility": volatility,
		"max_chain": 3, "max_retries": 2, "pressure_window": 4, "max_pressure_per_window": pressure_limit,
		"allow_tags": [], "deny_tags": [], "reduced_volatility": reduced,
	}
