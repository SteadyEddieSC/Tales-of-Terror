class_name DrownedHarborSocialContent
extends SocialContent

const PRIVACY_CLASSES: PackedStringArray = [
	"public", "controlled_reveal_private", "seat_private", "faction_private"
]


func _init() -> void:
	scenario_id = "drowned_harbor_scaffold_social"
	scenario_version = 1
	objectives = [
		{
			"id": "exit_scaffold_safely",
			"version": 1,
			"label": "Exit the Scaffold",
			"description": "Acknowledge the structural scaffold and return to the normal default.",
			"symbol": "X",
			"pattern": "crossed placeholder lines",
			"scope": "shared",
			"visibility": "public",
			"result": "unresolved",
			"priority": 0,
			"conditions": [{"type": "always"}],
			"partial_conditions": [],
			"reveal_at_end": false,
			"epilogue_tags": ["scaffold_only"],
		}
	]
	actions = [
		{
			"id": "acknowledge_scaffold_exit",
			"version": 1,
			"label": "Acknowledge and Exit",
			"description": "Complete the empty scaffold without running gameplay reducers.",
			"symbol": ">",
			"pattern": "single exit line",
			"visibility": "public",
			"allowed_lifecycles": ["active"],
			"target_scope": "none",
			"minimum_targets": 0,
			"maximum_targets": 0,
			"use_limit": 1,
			"per_round_limit": 1,
			"cooldown": 0,
			"allowed_phases": ["scaffold_entry"],
			"tags": ["scaffold", "exit"],
			"proposals":
			[
				{
					"type": "presentation",
					"visibility": "public",
					"message": "The Drowned Harbor structural scaffold is complete.",
				}
			],
		}
	]
	factions = [
		{
			"id": "scaffold_participants",
			"version": 1,
			"label": "Scaffold Participants",
			"symbol": "S",
			"pattern": "parallel placeholder lines",
			"presentation_tags": ["scaffold_only"],
			"membership_policy": "public",
			"minimum_seats": 1,
			"maximum_seats": SeatManager.MAX_SEATS,
			"relationships": {"scaffold_participants": "allied"},
			"shared_objectives": ["exit_scaffold_safely"],
			"transition_refs": [],
			"communication_allowed": false,
			"result_group": "scaffold_only",
			"director_signal_policy": [],
			"presentation": {"tone": "temporary_internal"},
		}
	]
	roles = [
		{
			"id": "scaffold_observer",
			"version": 1,
			"label": "Scaffold Observer",
			"description": "A stable-seat placeholder with no authored role mechanics.",
			"symbol": "O",
			"pattern": "open placeholder ring",
			"starting_faction": "scaffold_participants",
			"allowed_factions": ["scaffold_participants"],
			"reveal_policy": "public",
			"public_cover": {},
			"minimum_players": 1,
			"maximum_players": SeatManager.MAX_SEATS,
			"objective_refs": ["exit_scaffold_safely"],
			"action_refs": ["acknowledge_scaffold_exit"],
			"transition_refs": [],
			"tags": ["scaffold"],
			"incompatibilities": [],
			"initial_lifecycle": "active",
			"maximum_inactive_transition_delay": 0,
			"afterlife_mapping": "",
			"result_metadata": {"epilogue_tags": ["scaffold_only"]},
			"private_view_metadata": {"contains_authored_private_terms": false},
		}
	]
	transitions = []
	modes = [
		{
			"id": "scaffold_only",
			"version": 1,
			"label": "Developer Scaffold",
			"supported_player_counts": range(1, SeatManager.MAX_SEATS + 1),
			"assignment_policy": "fixed",
			"default_role_id": "scaffold_observer",
			"assignment_pool": [],
			"fixed_assignments": [],
			"required_combinations": [],
			"forbidden_combinations": [],
			"fallback_mode": "",
			"objective_refs": ["exit_scaffold_safely"],
			"afterlife_enabled": false,
			"privacy_policy":
			{
				"classes": Array(PRIVACY_CLASSES),
				"private_content_implemented": false,
			},
			"terminal_policy": {"result_key": "scaffold_terminal"},
			"assignment_retry_limit": 1,
			"transition_chain_limit": 1,
			"maximum_inactive_transition_delay": 1,
			"director_signal_allowlist": [],
		}
	]
	fixtures = []


func privacy_classes() -> PackedStringArray:
	return PRIVACY_CLASSES.duplicate()


func empty_private_projection(stable_seat_id: String) -> Dictionary:
	return {
		"classification": "seat_private",
		"stable_seat_id": stable_seat_id,
		"values": [],
		"scaffold_only": true,
	}
