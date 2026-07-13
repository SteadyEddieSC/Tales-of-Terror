class_name LanternHouseSocialContent
extends SocialContent

func _init() -> void:
	scenario_id = "lantern_house_social_lab"
	scenario_version = 1
	factions = [
		_faction("living", "Living", "L", "upright lantern lines", "public", true, "survivors", ["public_hostility", "revealed_imbalance"]),
		_faction("betrayer", "Betrayer", "B", "broken diagonal", "hidden", false, "opposition", ["public_hostility", "revealed_imbalance"]),
		_faction("horror", "Horror", "H", "jagged crown", "public", false, "opposition", ["public_hostility", "revealed_imbalance"]),
		_faction("changed", "Changed", "C", "echo rings", "partial", true, "third_faction", ["public_conversion_pressure", "revealed_imbalance"]),
		_faction("restless", "Restless", "R", "mist bands", "public", true, "afterlife", ["defeated_count", "restless_count", "afterlife_support_available"]),
	]
	objectives = [
		_objective("secure_lantern_house", "Secure Lantern House", "Keep the last lantern lit and seal the house.", "shared", "public", "victory", 40, [{"type": "rules_flag", "flag_id": "house_secured", "value": true}], [], true, ["house_secured"]),
		_objective("survive_the_tale", "Survive the Tale", "Remain active when the final bell sounds.", "individual", "public", "victory", 20, [{"type": "seat_state", "key": "defeated", "value": false}], [], true, ["survivor"]),
		_objective("break_the_archive", "Break the Archive", "Let the archive fail while your cover remains useful.", "individual", "seat_private", "victory", 60, [{"type": "rules_flag", "flag_id": "archive_broken", "value": true}], [{"type": "rules_flag", "flag_id": "path_misdirected", "value": true}], true, ["betrayal"]),
		_objective("claim_the_house", "Claim the House", "Raise dread until Lantern House belongs to the Horror.", "faction", "public", "victory", 55, [{"type": "rules_flag", "flag_id": "horror_claimed", "value": true}], [{"type": "rules_counter_at_least", "counter_id": "dread", "value": 1}], true, ["horror_claim"]),
		_objective("form_the_chorus", "Form the Chorus", "End with at least two voices in the Changed chorus.", "faction", "faction_private", "changed", 50, [{"type": "faction_count_at_least", "value": 2}], [{"type": "faction_count_at_least", "value": 1}], true, ["changed_chorus"]),
		_objective("guide_from_beyond", "Guide From Beyond", "Spend an afterlife intervention that helps shape the public board.", "afterlife", "public", "restless", 45, [{"type": "action_used", "action_tag": "afterlife_support"}], [], true, ["restless_guide"]),
		_objective("guard_the_lantern", "Guard the Lantern", "Issue a bounded warning before the ending.", "afterlife", "public", "victory", 48, [{"type": "rules_flag", "flag_id": "guardian_warning", "value": true}], [], true, ["guardian"]),
		_objective("bear_witness", "Bear Witness", "Record one public testimony for the survivors.", "afterlife", "public", "partial", 35, [{"type": "rules_counter_at_least", "counter_id": "testimony", "value": 1}], [], true, ["witness"]),
		_objective("return_to_the_light", "Return to the Light", "Re-enter the investigation and help secure the house.", "individual", "public", "victory", 42, [{"type": "rules_flag", "flag_id": "house_secured", "value": true}], [{"type": "rules_counter_at_least", "counter_id": "objective_progress", "value": 1}], true, ["replacement"]),
		_objective("keep_the_token", "Keep the Token", "Carry one private memory through the final reversal.", "individual", "seat_private", "victory", 30, [{"type": "action_used", "action_tag": "investigation"}], [], true, ["individual_memory"]),
	]
	factions[0].shared_objectives = ["secure_lantern_house"]
	factions[1].shared_objectives = ["break_the_archive"]
	factions[2].shared_objectives = ["claim_the_house"]
	factions[3].shared_objectives = ["form_the_chorus"]
	factions[4].shared_objectives = ["guide_from_beyond"]
	for faction: Dictionary in factions:
		for other: Dictionary in factions:
			faction.relationships[other.id] = "allied" if faction.id == other.id else "wary"
	actions = [
		_action("investigate_clue", "Emphasize a Clue", "Mark a clue for everyone without moving a pawn.", "?", "double underline", "public", ["active", "replacement"], "none", 0, 0, 0, 1, 0, ["investigation", "living"], [
			{"type": "rules_effects", "effects": [{"type": "set_flag", "flag_id": "clue_emphasized", "value": true}]},
			{"type": "presentation", "visibility": "public", "message": "A clue is emphasized for every seat."},
		]),
		_action("misdirect_route", "Misdirect", "Quietly bend the route while exposing only its public consequence.", "~", "broken path", "seat_private", ["active"], "none", 0, 0, 1, 1, 0, ["opposition", "secret"], [
			{"type": "rules_effects", "effects": [{"type": "set_flag", "flag_id": "path_misdirected", "value": true}]},
			{"type": "presentation", "visibility": "public", "message": "A route marker turns. Its cause remains private."},
		]),
		_action("raise_dread", "Raise Dread", "Add one bounded point of public dread.", "!", "jagged pulse", "public", ["transformed", "active"], "none", 0, 0, 2, 1, 0, ["horror", "pressure"], [
			{"type": "rules_effects", "effects": [{"type": "add_counter", "counter_id": "dread", "value": 1}]},
			{"type": "presentation", "visibility": "public", "message": "The revealed threat raises public dread."},
		]),
		_action("spread_echo", "Spread the Echo", "Convert one eligible other seat through a bounded transition.", "O", "concentric rings", "faction_private", ["transformed", "active"], "other", 1, 1, 1, 1, 1, ["changed", "spread"], [
			{"type": "role_transition", "transition_id": "spread_to_changed", "target": "selected"},
			{"type": "presentation", "visibility": "public", "message": "The Changed chorus gains one revealed echo."},
		]),
		_action("place_restless_omen", "Place an Omen", "Place a public omen in Lantern Hall through BoardState.", "*", "mist spiral", "public", ["afterlife"], "none", 0, 0, 1, 1, 0, ["afterlife", "afterlife_support"], [
			{"type": "board_mutation", "mutation": BoardMutation.feature("lantern_hall", "restless_omen", true)},
			{"type": "presentation", "visibility": "public", "message": "A Restless seat places an omen in Lantern Hall."},
		]),
		_action("guardian_warning", "Guardian Warning", "Spend the guardian's warning on a public protective cue.", "^", "shield chevrons", "public", ["afterlife"], "none", 0, 0, 1, 1, 0, ["afterlife", "guardian"], [
			{"type": "rules_effects", "effects": [{"type": "set_flag", "flag_id": "guardian_warning", "value": true}]},
			{"type": "presentation", "visibility": "public", "message": "A guardian warns the table of approaching danger."},
		]),
		_action("witness_testimony", "Bear Witness", "Add one public testimony counter.", "=", "parallel witness lines", "public", ["afterlife"], "none", 0, 0, 2, 1, 0, ["afterlife", "witness"], [
			{"type": "rules_effects", "effects": [{"type": "add_counter", "counter_id": "testimony", "value": 1}]},
			{"type": "presentation", "visibility": "public", "message": "A Witness records what the house tried to hide."},
		]),
		_action("replacement_search", "Return to the Search", "Advance public objective progress after returning.", "+", "renewed lantern lines", "public", ["replacement", "active"], "none", 0, 0, 2, 1, 0, ["investigation", "replacement"], [
			{"type": "rules_effects", "effects": [{"type": "add_counter", "counter_id": "objective_progress", "value": 1}]},
			{"type": "presentation", "visibility": "public", "message": "A replacement investigator resumes the search."},
		]),
	]
	transitions = [
		_transition("reveal_opposition", "Reveal Allegiance", ["veiled_guest"], "veiled_guest", "reveal", "public", 1, {"lifecycle": "active", "revealed": true}),
		_transition("become_house_horror", "Become the Horror", ["lantern_investigator", "replacement_investigator"], "house_horror", "transform", "public", 1, {"lifecycle": "transformed", "revealed": true, "transformed": true}),
		_transition("convert_to_changed", "Become Changed", ["lantern_investigator", "replacement_investigator"], "echo_changed", "convert", "public", 2, {"lifecycle": "transformed", "revealed": true, "transformed": true}),
		_transition("spread_to_changed", "Echo Spreads", ["lantern_investigator", "replacement_investigator"], "echo_changed", "spread", "public", 2, {"lifecycle": "transformed", "revealed": true, "transformed": true}),
		_transition("fall_restless", "Enter the Afterlife", ["lantern_investigator", "replacement_investigator", "veiled_guest", "house_horror", "echo_changed"], "lantern_wraith", "defeat", "public", 1, {"lifecycle": "afterlife", "revealed": true, "defeated": true}),
		_transition("choose_guardian_path", "Become a Guardian", ["lantern_wraith"], "watchful_guardian", "guardian_path", "public", 1, {"lifecycle": "afterlife", "revealed": true, "defeated": true}),
		_transition("choose_witness_path", "Become a Witness", ["lantern_wraith"], "silent_witness", "witness_path", "public", 1, {"lifecycle": "afterlife", "revealed": true, "defeated": true}),
		_transition("receive_replacement", "Return as a Replacement", ["lantern_wraith", "watchful_guardian", "silent_witness"], "replacement_investigator", "replacement", "public", 1, {"lifecycle": "replacement", "revealed": true, "defeated": false}),
		_transition("cure_the_changed", "Cure the Change", ["echo_changed"], "lantern_investigator", "cure", "public", 2, {"lifecycle": "active", "revealed": true, "transformed": false}),
		_transition("escape_the_house", "Escape", ["lantern_investigator", "replacement_investigator"], "replacement_investigator", "escape", "public", 1, {"lifecycle": "escaped", "revealed": true, "escaped": true}),
	]
	roles = [
		_role("lantern_investigator", "Investigator", "Search Lantern House and protect the living tale.", "L", "upright lantern lines", "living", "public", ["living", "investigator"], ["secure_lantern_house", "survive_the_tale", "keep_the_token"], ["investigate_clue"], ["become_house_horror", "convert_to_changed", "spread_to_changed", "fall_restless", "escape_the_house"], "active"),
		_role("veiled_guest", "Veiled Betrayer", "Preserve your cover while the archive breaks.", "B", "broken diagonal", "betrayer", "hidden", ["opposition", "secret"], ["break_the_archive"], ["misdirect_route"], ["reveal_opposition", "fall_restless"], "active"),
		_role("house_horror", "House Horror", "Become the visible one-versus-many threat.", "H", "jagged crown", "horror", "public", ["horror", "opposition"], ["claim_the_house"], ["raise_dread"], ["fall_restless"], "transformed"),
		_role("echo_changed", "Echo Changed", "Join the third faction and spread one bounded echo.", "C", "echo rings", "changed", "revealable", ["changed", "third_faction"], ["form_the_chorus"], ["spread_echo"], ["fall_restless", "cure_the_changed"], "transformed"),
		_role("lantern_wraith", "Lantern Wraith", "Act from beyond by placing one public omen.", "R", "mist spiral", "restless", "public", ["afterlife", "restless"], ["guide_from_beyond"], ["place_restless_omen"], ["choose_guardian_path", "choose_witness_path", "receive_replacement"], "afterlife", 1),
		_role("watchful_guardian", "Watchful Guardian", "Protect the tale with one bounded warning.", "G", "shield chevrons", "restless", "public", ["afterlife", "guardian"], ["guard_the_lantern"], ["guardian_warning"], ["receive_replacement"], "afterlife", 1),
		_role("silent_witness", "Silent Witness", "Remain involved by recording public testimony.", "W", "parallel witness lines", "restless", "public", ["afterlife", "witness"], ["bear_witness"], ["witness_testimony"], ["receive_replacement"], "afterlife", 1),
		_role("replacement_investigator", "Replacement Investigator", "Return with a renewed public mandate.", "+", "renewed lantern lines", "living", "public", ["living", "replacement"], ["return_to_the_light"], ["replacement_search"], ["become_house_horror", "convert_to_changed", "spread_to_changed", "fall_restless", "escape_the_house"], "replacement"),
	]
	for role: Dictionary in roles:
		role["afterlife_mapping"] = ""
		for transition_id: String in role.transition_refs:
			var authored_transition: Dictionary = transition_by_id(transition_id)
			if authored_transition.get("trigger", "") == "defeat": role["afterlife_mapping"] = transition_id
			for faction: Dictionary in factions:
				if faction.id == role.starting_faction and not faction.transition_refs.has(transition_id): faction.transition_refs.append(transition_id)
	modes = [
		_mode("cooperative", "Pure Cooperative", range(1, 9), "fixed", "lantern_investigator", [], [], "", true),
		_mode("hidden_betrayer", "Hidden Betrayer", range(3, 9), "random_pool", "lantern_investigator", [{"role_id": "veiled_guest", "count": 1}], [], "cooperative", true),
		_mode("hunted", "Hunted", range(2, 9), "fixed", "lantern_investigator", [], [], "cooperative", true),
		_mode("outbreak", "Outbreak", range(3, 9), "random_pool", "lantern_investigator", [{"role_id": "echo_changed", "count": 1}], [], "cooperative", true),
		_mode("faction_teams", "Faction Teams", range(4, 9), "random_pool", "lantern_investigator", [{"role_id": "veiled_guest", "count": 1}, {"role_id": "echo_changed", "count": 1}], [], "cooperative", true),
		_mode("no_afterlife", "Mortal Cooperative", range(1, 9), "fixed", "lantern_investigator", [], [], "", false),
		_mode("mixed_fixture", "Mixed Ending", [4], "fixed", "lantern_investigator", [], [
			{"seat": 1, "role_id": "lantern_investigator"}, {"seat": 2, "role_id": "veiled_guest"},
			{"seat": 3, "role_id": "echo_changed"}, {"seat": 4, "role_id": "lantern_wraith"},
		], "cooperative", true),
	]
	fixtures = [
		_fixture("cooperative_state", "social_cooperative", "cooperative", 4, [], {"kind": "public", "title": "PURE COOPERATIVE"}),
		_fixture("hidden_private_state", "social_hidden_private", "hidden_betrayer", 4, [], {"kind": "seat_private", "selector_tag": "secret", "title": "CONTROLLED PRIVATE REVEAL"}),
		_fixture("betrayer_reveal_state", "social_betrayer_reveal", "hidden_betrayer", 4, [{"type": "transition", "selector_tag": "secret", "trigger": "reveal"}], {"kind": "public", "title": "BETRAYER REVEALED"}),
		_fixture("horror_transformation_state", "social_horror", "hunted", 4, [{"type": "transition", "seat": 2, "trigger": "transform"}, {"type": "action", "selector_tag": "horror", "action_tag": "pressure"}], {"kind": "public", "title": "HUNTED: HORROR TRANSFORMATION"}),
		_fixture("changed_conversion_state", "social_changed", "outbreak", 4, [{"type": "action", "selector_tag": "changed", "action_tag": "spread", "target_selector_tag": "living"}], {"kind": "public", "title": "OUTBREAK: BOUNDED CHANGED SPREAD"}),
		_fixture("restless_action_state", "social_restless", "cooperative", 4, [{"type": "transition", "seat": 1, "trigger": "defeat"}, {"type": "action", "selector_tag": "afterlife", "action_tag": "afterlife_support"}], {"kind": "public", "title": "DEFEAT TO MEANINGFUL RESTLESS ACTION"}),
		_fixture("guardian_path_state", "social_guardian", "cooperative", 4, [{"type": "transition", "seat": 1, "trigger": "defeat"}, {"type": "transition", "selector_tag": "restless", "trigger": "guardian_path"}, {"type": "action", "selector_tag": "guardian", "action_tag": "guardian"}], {"kind": "public", "title": "ALTERNATE GUARDIAN PATH"}),
		_fixture("reconnect_privacy_state", "social_reconnect", "hidden_betrayer", 4, [{"type": "connection_cycle", "selector_tag": "secret"}], {"kind": "public", "title": "RECONNECT: SECRET OWNERSHIP PRESERVED"}),
		_fixture("mixed_outcome_state", "social_mixed", "mixed_fixture", 4, [{"type": "rules_effects", "effects": [{"type": "set_flag", "flag_id": "house_secured", "value": true}, {"type": "set_flag", "flag_id": "archive_broken", "value": true}]}, {"type": "action", "selector_tag": "changed", "action_tag": "spread", "target_selector_tag": "living"}, {"type": "action", "selector_tag": "afterlife", "action_tag": "afterlife_support"}, {"type": "resolve_outcomes"}], {"kind": "outcome", "title": "MIXED FACTION + INDIVIDUAL ENDING"}),
		_fixture("spoiler_diagnostics_state", "social_diagnostics", "mixed_fixture", 4, [{"type": "rules_effects", "effects": [{"type": "set_flag", "flag_id": "house_secured", "value": true}, {"type": "set_flag", "flag_id": "archive_broken", "value": true}]}], {"kind": "diagnostics", "title": "SPOILER DIAGNOSTICS"}),
		_fixture("unsupported_count_fallback", "social_fallback", "hidden_betrayer", 1, [], {"kind": "public", "title": "SAFE FALLBACK: ONE-SEAT COOPERATIVE"}),
	]

func _faction(stable_id: String, friendly_label: String, symbol: String, pattern: String, membership_policy: String, communication_allowed: bool, result_group: String, director_signals: Array[String]) -> Dictionary:
	return {
		"id": stable_id, "version": 1, "label": friendly_label, "symbol": symbol, "pattern": pattern,
		"presentation_tags": [result_group], "membership_policy": membership_policy, "minimum_seats": 0,
		"maximum_seats": SeatManager.MAX_SEATS, "relationships": {}, "shared_objectives": [], "transition_refs": [],
		"communication_allowed": communication_allowed, "result_group": result_group,
		"director_signal_policy": director_signals, "presentation": {"tone": result_group},
	}

func _role(stable_id: String, friendly_label: String, description: String, symbol: String, pattern: String, starting_faction: String, reveal_policy: String, tags: Array[String], objective_refs: Array[String], action_refs: Array[String], transition_refs: Array[String], initial_lifecycle: String, inactive_delay: int = 0) -> Dictionary:
	return {
		"id": stable_id, "version": 1, "label": friendly_label, "description": description, "symbol": symbol, "pattern": pattern,
		"starting_faction": starting_faction, "allowed_factions": [starting_faction], "reveal_policy": reveal_policy,
		"public_cover": {"label": "Investigator", "description": "Public identity unknown.", "symbol": "?", "pattern": "closed crosshatch"},
		"minimum_players": 1, "maximum_players": SeatManager.MAX_SEATS, "objective_refs": objective_refs,
		"action_refs": action_refs, "transition_refs": transition_refs, "tags": tags, "incompatibilities": [],
		"initial_lifecycle": initial_lifecycle, "maximum_inactive_transition_delay": inactive_delay, "afterlife_mapping": "",
		"result_metadata": {"epilogue_tags": tags}, "private_view_metadata": {"future_companion_ready": true},
	}

func _objective(stable_id: String, friendly_label: String, description: String, scope: String, visibility: String, result: String, priority: int, conditions: Array[Dictionary], partial_conditions: Array[Dictionary], reveal_at_end: bool, epilogue_tags: Array[String]) -> Dictionary:
	return {
		"id": stable_id, "version": 1, "label": friendly_label, "description": description, "symbol": "◇", "pattern": "objective lines",
		"scope": scope, "visibility": visibility, "result": result, "priority": priority, "conditions": conditions,
		"partial_conditions": partial_conditions, "reveal_at_end": reveal_at_end, "epilogue_tags": epilogue_tags,
	}

func _action(stable_id: String, friendly_label: String, description: String, symbol: String, pattern: String, visibility: String, lifecycles: Array[String], target_scope: String, minimum_targets: int, maximum_targets: int, use_limit: int, per_round_limit: int, cooldown: int, tags: Array[String], proposals: Array[Dictionary]) -> Dictionary:
	return {
		"id": stable_id, "version": 1, "label": friendly_label, "description": description, "symbol": symbol, "pattern": pattern,
		"visibility": visibility, "allowed_lifecycles": lifecycles, "target_scope": target_scope,
		"minimum_targets": minimum_targets, "maximum_targets": maximum_targets, "use_limit": use_limit,
		"per_round_limit": per_round_limit, "cooldown": cooldown, "allowed_phases": [], "tags": tags, "proposals": proposals,
	}

func _transition(stable_id: String, friendly_label: String, source_forms: Array[String], target_form: String, trigger: String, visibility: String, max_chain: int, state_patch: Dictionary) -> Dictionary:
	return {
		"id": stable_id, "version": 1, "label": friendly_label, "source_forms": source_forms, "target_form": target_form,
		"trigger": trigger, "visibility": visibility, "max_chain": max_chain, "state_patch": state_patch,
		"downstream_effects": [], "presentation": {"public_message": "%s." % friendly_label},
	}

func _mode(stable_id: String, friendly_label: String, supported_counts: Array, policy: String, default_role_id: String, pool: Array[Dictionary], fixed: Array[Dictionary], fallback: String, afterlife_enabled: bool) -> Dictionary:
	return {
		"id": stable_id, "version": 1, "label": friendly_label, "supported_player_counts": supported_counts,
		"assignment_policy": policy, "default_role_id": default_role_id, "assignment_pool": pool, "fixed_assignments": fixed,
		"required_combinations": [], "forbidden_combinations": [], "fallback_mode": fallback,
		"objective_refs": ["secure_lantern_house"], "afterlife_enabled": afterlife_enabled,
		"privacy_policy": {"public_shared_screen": true, "seat_private_requires_obscure": true, "late_join": "deferred"},
		"terminal_policy": {"tie": "compatible_highest_priority", "result_key": "social_outcome"},
		"assignment_retry_limit": 8, "transition_chain_limit": 8, "maximum_inactive_transition_delay": 1,
		"director_signal_allowlist": SocialContent.VALID_DIRECTOR_SIGNALS.duplicate(),
	}

func _fixture(stable_id: String, evidence_stage: String, mode_id: String, seat_count: int, operations: Array[Dictionary], view: Dictionary) -> Dictionary:
	return {
		"id": stable_id, "version": 1, "evidence_stage": evidence_stage, "mode_id": mode_id,
		"seat_count": seat_count, "operations": operations, "view": view,
	}
