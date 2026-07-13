class_name LanternHouseRulesContent
extends RulesContent

func _init() -> void:
	scenario_id = "lantern_house_rules_sandbox"
	scenario_version = 1
	phases = ["round_start", "player_decision", "resolution", "event", "cleanup"]
	items = [
		{"id": "brass_key", "version": 1, "name": "Brass Key", "symbol": "◆"},
		{"id": "lantern_oil", "version": 1, "name": "Lantern Oil", "symbol": "◉"},
	]
	cards = [
		{"id": "steady_flame", "version": 1, "name": "Steady Flame", "body": "Clear the echo mist.", "tags": ["tool", "light"], "conditions": [{"type": "always"}], "target_count": 0, "policy": "discard", "effects": [{"type": "board_mutation", "mutation": BoardMutation.hazard("narrow_gallery", "echo_mist", false)}, {"type": "add_counter", "counter_id": "hope", "value": 1}]},
		{"id": "iron_resolve", "version": 1, "name": "Iron Resolve", "body": "Gain one resolve.", "tags": ["reaction"], "conditions": [{"type": "phase_is", "phase": "player_decision"}], "target_count": 0, "policy": "exhaust", "effects": [{"type": "add_counter", "counter_id": "resolve", "value": 1}]},
		{"id": "chalk_mark", "version": 1, "name": "Chalk Mark", "body": "Mark the safe route.", "tags": ["tool"], "conditions": [{"type": "always"}], "target_count": 0, "policy": "retain", "effects": [{"type": "set_flag", "flag_id": "route_marked", "value": true}]},
	]
	initial_deck = ["steady_flame", "iron_resolve", "chalk_mark", "steady_flame", "iron_resolve", "chalk_mark"]
	events = [
		{
			"id": "threshold_whisper", "version": 1, "title": "The Threshold Whispers", "body": "The iron gate answers in a voice like wet paper.", "tags": ["arrival"], "conditions": [{"type": "always"}],
			"prompts": [{"id": "choose_path", "scope": "single", "seat": 1, "title": "Choose the approach", "options": [{"id": "listen", "text": "Listen at the gate", "symbol": "◉"}, {"id": "force", "text": "Force it open", "symbol": "▲"}], "min_selections": 1, "max_selections": 1, "allow_pass": false}],
			"effects": [{"type": "board_mutation", "mutation": BoardMutation.connector("hall_gate", "open")}, {"type": "draw_card", "seat": 1, "count": 1}, {"type": "history", "text": "The threshold yields."}],
			"follow_ups": ["gallery_council"], "once": true,
			"presenter": {"speaker_key": "scenario_host", "mode": "story", "tone": "hushed", "portrait_cue": "host_silhouette", "audio_cue": "paper_whisper", "priority": 50, "interruption": "queue", "confirm": true},
		},
		{
			"id": "gallery_council", "version": 1, "title": "Council in the Gallery", "body": "Every shadow points toward a different door.", "tags": ["vote"], "conditions": [{"type": "always"}], "prompts": [],
			"effects": [{"type": "add_item", "seat": 1, "item_id": "brass_key"}, {"type": "board_mutation", "mutation": BoardMutation.reveal_space("sealed_archive")}, {"type": "set_flag", "flag_id": "council_called", "value": true}], "follow_ups": [], "repeatability": "cooldown_rounds", "cooldown": 2,
			"presenter": {"speaker_key": "scenario_host", "mode": "public_vote", "tone": "urgent", "priority": 60, "interruption": "queue", "confirm": true},
		},
		{
			"id": "vault_reckoning", "version": 1, "title": "The Vault Reckoning", "body": "The black water stills. Something below is counting.", "tags": ["check", "finale"], "conditions": [{"type": "flag_equals", "flag_id": "council_called", "value": true}], "prompts": [], "check": courage_check(), "acting_seat": 1, "outcome_effects": {"critical": [{"type": "add_counter", "counter_id": "hope", "value": 2}], "success": [{"type": "add_counter", "counter_id": "hope", "value": 1}], "partial": [{"type": "set_flag", "flag_id": "cost_paid", "value": true}], "failure": [{"type": "set_result", "result_id": "vault_danger", "value": true}]},
			"effects": [{"type": "set_result", "result_id": "vault_reached", "value": true}, {"type": "history", "text": "Lantern House remembers the living."}], "follow_ups": [],
			"presenter": {"speaker_key": "scenario_host", "mode": "check_result", "tone": "grave", "priority": 80, "interruption": "replace_lower", "confirm": true},
		},
	]

func vote_definition() -> Dictionary:
	return {"id": "archive_route_vote", "title": "Which route do we seal?", "options": [{"id": "gallery", "text": "Seal the Gallery", "symbol": "✕", "effects": [{"type": "board_mutation", "mutation": BoardMutation.connector("archive_route", "collapsed")}]}, {"id": "vault", "text": "Protect the Vault", "symbol": "◆", "effects": [{"type": "set_flag", "flag_id": "vault_protected", "value": true}]}], "allow_abstain": true, "rule": "plurality", "quorum": 1, "tie_policy": "stable_option_id", "source_id": "gallery_council"}

func courage_check() -> Dictionary:
	return {"dice": 2, "sides": 6, "modifier": 1, "modifier_counter": "resolve", "bands": {"critical": 12, "success": 8, "partial": 5}}
