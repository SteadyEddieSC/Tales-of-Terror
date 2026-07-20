extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	_test_content_validation()
	_test_assignment_rng_and_fallback()
	_test_privacy_views_and_director_blindness()
	_test_director_signal_normalization()
	_test_legal_action_target_discovery()
	_test_transitions_and_actions()
	_test_reconnect_and_afterlife()
	_test_disconnected_action_boundaries()
	_test_outcomes_and_snapshots()
	_test_hud_and_diagnostics_contract()
	_test_generic_id_branch_guard()
	if _failures == 0:
		print("Roles, Factions & Afterlife tests passed")
	quit(_failures)


func _test_content_validation() -> void:
	var content := LanternHouseSocialContent.new()
	_expect(
		(
			content
			. validate(LanternHouseRulesContent.new(), LanternHouseBoardDefinition.new())
			. is_empty()
		),
		"accepts declarative Lantern House social content"
	)
	var faction_labels: Array[String] = []
	for faction: Dictionary in content.factions:
		faction_labels.append(faction.label)
	for expected: String in ["Living", "Betrayer", "Horror", "Changed", "Restless"]:
		_expect(faction_labels.has(expected), "represents %s through authored data" % expected)
	var duplicate := LanternHouseSocialContent.new()
	duplicate.factions.append(duplicate.factions[0].duplicate(true))
	_expect(_contains(duplicate.validate(), "duplicate faction"), "rejects duplicate faction IDs")
	var missing_faction := LanternHouseSocialContent.new()
	missing_faction.roles[0].starting_faction = "missing_faction"
	_expect(
		_contains(missing_faction.validate(), "no legal faction"),
		"rejects roles with no legal faction"
	)
	var unsafe_hidden := LanternHouseSocialContent.new()
	unsafe_hidden.roles[1].public_cover = {}
	_expect(
		_contains(unsafe_hidden.validate(), "safe public representation"),
		"rejects hidden roles without a safe public cover"
	)
	var arbitrary_script := LanternHouseSocialContent.new()
	arbitrary_script.actions[0].proposals = [{"type": "execute_script", "path": "res://bad.gd"}]
	_expect(
		_contains(arbitrary_script.validate(), "invalid action proposal"),
		"rejects arbitrary action scripting"
	)
	var missing_transition := LanternHouseSocialContent.new()
	missing_transition.transitions[0].target_form = "missing_form"
	_expect(
		_contains(missing_transition.validate(), "unknown transition target"),
		"rejects impossible transition targets"
	)
	var passive_afterlife := LanternHouseSocialContent.new()
	passive_afterlife.roles[4].action_refs = []
	_expect(
		(
			_contains(passive_afterlife.validate(), "afterlife")
			or _contains(passive_afterlife.validate(), "legal objective and action")
		),
		"rejects passive permanent afterlife"
	)
	var unbounded := LanternHouseSocialContent.new()
	unbounded.transitions[0].max_chain = 0
	_expect(
		_contains(unbounded.validate(), "unbounded transition"),
		"rejects unbounded transition chains"
	)
	var impossible_mode := LanternHouseSocialContent.new()
	impossible_mode.modes[1].assignment_pool[0].count = 9
	_expect(
		_contains(impossible_mode.validate(), "impossible assignment plan"),
		"rejects impossible scenario assignment plans during content validation"
	)


func _test_assignment_rng_and_fallback() -> void:
	var first := RoleSession.new(
		LanternHouseSocialContent.new(), "hidden_betrayer", 4706, [1, 2, 3, 4]
	)
	var second := RoleSession.new(
		LanternHouseSocialContent.new(), "hidden_betrayer", 4706, [1, 2, 3, 4]
	)
	_expect(
		first.initialization_errors.is_empty() and first.to_snapshot() == second.to_snapshot(),
		"reproduces randomized assignment with a dedicated role RNG"
	)
	_expect(first.rng.counter == 1, "consumes one bounded role draw for one hostile assignment")
	var cooperative := RoleSession.new(
		LanternHouseSocialContent.new(), "cooperative", 4706, [1, 2, 3, 4]
	)
	_expect(cooperative.rng.counter == 0, "fixed cooperative assignment consumes no random values")
	var board := BoardState.new(LanternHouseBoardDefinition.new())
	var rules := RulesSession.new(LanternHouseRulesContent.new(), board, 4706, [1, 2, 3, 4])
	var director := DirectorRuntime.new(
		LanternHouseDirectorContent.new(), "standard", 4706, rules.content, board.definition
	)
	var rules_rng_before: Dictionary = rules.rng.to_snapshot()
	var director_rng_before: Dictionary = director.rng.to_snapshot()
	RoleSession.new(LanternHouseSocialContent.new(), "hidden_betrayer", 4706, [1, 2, 3, 4])
	_expect(
		(
			rules.rng.to_snapshot() == rules_rng_before
			and director.rng.to_snapshot() == director_rng_before
		),
		"keeps role assignment isolated from RulesSession and Director RNG"
	)
	var stable: Dictionary = first.to_snapshot()
	var role_rng_before: Dictionary = first.rng.to_snapshot()
	_expect(
		(
			not first.assign_mode("missing_mode", [1, 2, 3, 4]).accepted
			and first.to_snapshot() == stable
			and first.rng.to_snapshot() == role_rng_before
		),
		"invalid assignment changes no role state and consumes no role RNG"
	)
	var fallback := RoleSession.new(LanternHouseSocialContent.new(), "hidden_betrayer", 99, [1])
	_expect(
		(
			fallback.fallback_applied
			and fallback.mode_id == "cooperative"
			and fallback.public_view().fallback_active
		),
		"selects an explicit authored no-secret fallback for unsupported one-seat betrayal"
	)
	_expect(
		fallback.rng.counter == 0 and fallback.seat_with_tag("secret") == 0,
		"safe fallback contains no hostile secret and consumes no role RNG"
	)
	var mortal := RoleSession.new(LanternHouseSocialContent.new(), "no_afterlife", 99, [1])
	_expect(
		(
			"WARNING BEFORE PLAY" in mortal.public_view().afterlife_notice
			and not mortal.request_transition_by_trigger(1, "defeat").accepted
		),
		"warns before play and rejects afterlife transitions when an authored mode disables afterlife"
	)


func _test_privacy_views_and_director_blindness() -> void:
	var session := RoleSession.new(
		LanternHouseSocialContent.new(), "hidden_betrayer", 8080, [1, 2, 3, 4]
	)
	var secret_seat: int = session.seat_with_tag("secret")
	var secret_state: Dictionary = session.seat_states[secret_seat]
	var role: Dictionary = session.content.role_by_id(secret_state.form_id)
	var faction: Dictionary = session.content.faction_by_id(secret_state.faction_id)
	var secret_objective: Dictionary = session.content.objective_by_id(
		secret_state.objective_refs[0]
	)
	var public_json: String = JSON.stringify(session.public_view())
	for secret: String in [
		role.id, faction.id, secret_objective.id, role.description, secret_objective.description
	]:
		_expect(not secret in public_json, "keeps hidden value out of recursive public view")
	var own_private: Dictionary = session.seat_private_view(secret_seat)
	_expect(
		(
			own_private.accepted
			and own_private.private.role_id == role.id
			and own_private.shared_screen_warning.begins_with("OBSCURE")
		),
		"authorizes explicit obscured seat-private reveal"
	)
	var other_seat: int = 1 if secret_seat != 1 else 2
	var other_private_json: String = JSON.stringify(session.seat_private_view(other_seat))
	_expect(
		(
			not role.id in other_private_json
			and not secret_objective.description in other_private_json
		),
		"prevents one seat from inspecting another seat's secrets"
	)
	_expect(
		not session.faction_private_view(secret_seat).accepted,
		"honors authored no-communication policy for the hidden opposition"
	)
	_expect(
		session.faction_private_view(other_seat).accepted,
		"provides an explicit authorized faction-private view"
	)
	_expect(
		session.privacy_report().passed,
		"recursively checks public, Director, and unauthorized-seat surfaces for secret leakage"
	)
	var rejection: Dictionary = session.perform_action(secret_seat, "unknown_action", [])
	_expect(
		(
			not role.id in JSON.stringify(rejection)
			and not secret_objective.description in JSON.stringify(rejection)
			and not role.id in session.last_rejection
		),
		"keeps rejection errors free of private identifiers and text"
	)
	var board := BoardState.new(LanternHouseBoardDefinition.new())
	var rules := RulesSession.new(LanternHouseRulesContent.new(), board, 8080, [1, 2, 3, 4])
	var telemetry_before: Dictionary = DirectorTelemetry.build(rules, board, session)
	var alternate := RoleSession.new(
		LanternHouseSocialContent.new(), "hidden_betrayer", 99, [1, 2, 3, 4]
	)
	var telemetry_alternate: Dictionary = DirectorTelemetry.build(rules, board, alternate)
	_expect(
		(
			DirectorTelemetry.validate(telemetry_before).is_empty()
			and DirectorTelemetry.validate(telemetry_alternate).is_empty()
		),
		"keeps hidden-assignment Director telemetry within the strict validated domain"
	)
	_expect(
		(
			telemetry_before.social_signals == telemetry_alternate.social_signals
			and telemetry_before.future_balance_signal == telemetry_alternate.future_balance_signal
		),
		"keeps Director signals unchanged across unrevealed secret assignments"
	)
	_expect(
		(
			not JSON.stringify(telemetry_before).contains(role.id)
			and not JSON.stringify(telemetry_before).contains(secret_objective.id)
		),
		"keeps role IDs and private objectives out of Director telemetry"
	)
	var runtime_a := DirectorRuntime.new(
		LanternHouseDirectorContent.new(), "standard", 8080, rules.content, board.definition
	)
	var runtime_b := DirectorRuntime.new(
		LanternHouseDirectorContent.new(), "standard", 8080, rules.content, board.definition
	)
	var decision_a: Dictionary = runtime_a.evaluate(telemetry_before)
	var decision_b: Dictionary = runtime_b.evaluate(telemetry_alternate)
	_expect(
		decision_a.has("selected_candidate_id") and decision_b.has("selected_candidate_id"),
		"keeps authorized social telemetry valid for the Director"
	)
	_expect(
		decision_a.get("selected_candidate_id", "") == decision_b.get("selected_candidate_id", ""),
		"prevents unrevealed private differences from changing Director decisions"
	)
	session.request_transition_by_trigger(secret_seat, "reveal", rules, board)
	var revealed_telemetry: Dictionary = DirectorTelemetry.build(rules, board, session)
	_expect(
		(
			revealed_telemetry.social_signals.revealed_faction_count
			> telemetry_before.social_signals.revealed_faction_count
		),
		"allows an authored public reveal to change aggregate Director-safe signals"
	)
	_expect(
		DirectorTelemetry.validate(revealed_telemetry).is_empty(),
		"keeps authorized revealed telemetry valid without weakening Director validation"
	)


func _test_director_signal_normalization() -> void:
	for seat_count: int in [6, 7, 8]:
		var seats: Array[int] = []
		for seat: int in range(1, seat_count + 1):
			seats.append(seat)
		var board := BoardState.new(LanternHouseBoardDefinition.new())
		var rules := RulesSession.new(
			LanternHouseRulesContent.new(), board, 6000 + seat_count, seats
		)
		var session := RoleSession.new(
			LanternHouseSocialContent.new(), "hunted", 6000 + seat_count, seats
		)
		var mirror := RoleSession.new(
			LanternHouseSocialContent.new(), "hunted", 6000 + seat_count, seats
		)
		for seat: int in seats:
			_expect(
				session.request_transition_by_trigger(seat, "transform", rules, board).accepted,
				(
					"reveals and transforms seat %d in the %d-seat telemetry boundary fixture"
					% [seat, seat_count]
				)
			)
			_expect(
				mirror.request_transition_by_trigger(seat, "transform", rules, board).accepted,
				(
					"replays transformed seat %d in the %d-seat telemetry boundary fixture"
					% [seat, seat_count]
				)
			)
		var telemetry: Dictionary = DirectorTelemetry.build(rules, board, session)
		var repeated: Dictionary = DirectorTelemetry.build(rules, board, session)
		var mirrored: Dictionary = DirectorTelemetry.build(rules, board, mirror)
		_expect(
			DirectorTelemetry.validate(telemetry).is_empty(),
			"validates Director telemetry with %d revealed/transformed seats" % seat_count
		)
		_expect(
			telemetry.social_signals.public_conversion_pressure == 100,
			"normalizes %d revealed transformations to the 0–100 domain" % seat_count
		)
		_expect(
			telemetry == repeated and telemetry == mirrored,
			"reproduces identical %d-seat social telemetry deterministically" % seat_count
		)
	var imbalance_seats: Array[int] = [1, 2, 3, 4, 5, 6, 7, 8]
	var imbalance_board := BoardState.new(LanternHouseBoardDefinition.new())
	var imbalance_rules := RulesSession.new(
		LanternHouseRulesContent.new(), imbalance_board, 7108, imbalance_seats
	)
	var imbalanced := RoleSession.new(
		LanternHouseSocialContent.new(), "hunted", 7108, imbalance_seats
	)
	for seat: int in range(1, 8):
		imbalanced.request_transition_by_trigger(
			seat, "transform", imbalance_rules, imbalance_board
		)
	var imbalance_telemetry: Dictionary = DirectorTelemetry.build(
		imbalance_rules, imbalance_board, imbalanced
	)
	_expect(
		(
			imbalance_telemetry.social_signals.revealed_imbalance == 75
			and imbalance_telemetry.social_signals.public_conversion_pressure == 88
		),
		"normalizes a revealed 7:1 faction distribution deterministically"
	)
	_expect(
		DirectorTelemetry.validate(imbalance_telemetry).is_empty(),
		"keeps highly imbalanced revealed telemetry inside the strict 0–100 contract"
	)
	for value: Variant in imbalance_telemetry.social_signals.values():
		_expect(
			value is int and value >= 0 and value <= 100,
			"bounds every authorized social signal without exposing identity data"
		)


func _test_legal_action_target_discovery() -> void:
	var content := LanternHouseSocialContent.new()
	var faction_action: Dictionary = _test_action(
		content.actions[0],
		"faction_target_probe",
		"Faction Signal",
		"faction_private",
		"faction_other",
		1,
		1
	)
	var self_action: Dictionary = _test_action(
		content.actions[0], "self_target_probe", "Steady Self", "seat_private", "self", 1, 1
	)
	var multi_action: Dictionary = _test_action(
		content.actions[0], "multi_target_probe", "Bounded Group", "seat_private", "other", 2, 3
	)
	content.actions.append(faction_action)
	content.actions.append(self_action)
	content.actions.append(multi_action)
	var living_role: Dictionary = content.roles[0]
	living_role.action_refs.append(faction_action.id)
	living_role.action_refs.append(self_action.id)
	living_role.action_refs.append(multi_action.id)
	content.roles[0] = living_role
	var secret_role: Dictionary = content.roles[1]
	secret_role.action_refs.append(faction_action.id)
	content.roles[1] = secret_role
	content.modes[6].fixed_assignments[2].role_id = living_role.id
	_expect(
		content.validate().is_empty(), "accepts deterministic target-discovery regression content"
	)
	var session := RoleSession.new(content, "mixed_fixture", 321, [1, 2, 3, 4])
	var snapshot_before: Dictionary = session.to_snapshot()
	var rng_before: Dictionary = session.rng.to_snapshot()
	var rejection_before: String = session.last_rejection
	var first_actions: Array[Dictionary] = session.legal_actions(1)
	var second_actions: Array[Dictionary] = session.legal_actions(1)
	var first_ids: Array[String] = _action_ids(first_actions)
	_expect(
		first_ids.has(faction_action.id),
		"lists faction_other when seat II is ineligible but later sorted seat III is an eligible ally"
	)
	_expect(
		first_ids.has(self_action.id),
		"lists a required self-target action using the actor as its deterministic target"
	)
	_expect(
		first_ids.has(multi_action.id),
		"finds a bounded deterministic combination for a multiple-target action"
	)
	_expect(
		not _action_ids(session.legal_actions(2)).has(faction_action.id),
		"omits a faction_other action when no connected allied target exists"
	)
	_expect(
		(
			first_actions == second_actions
			and session.to_snapshot() == snapshot_before
			and session.rng.to_snapshot() == rng_before
			and session.last_rejection == rejection_before
		),
		"keeps repeated legal-action discovery deterministic and side-effect free"
	)
	_expect(
		not faction_action.label in JSON.stringify(session.public_view()),
		"does not expose a private faction action or hidden faction membership through the public view"
	)


func _test_transitions_and_actions() -> void:
	var board := BoardState.new(LanternHouseBoardDefinition.new())
	var rules := RulesSession.new(LanternHouseRulesContent.new(), board, 121, [1, 2, 3, 4])
	var hunted := RoleSession.new(LanternHouseSocialContent.new(), "hunted", 121, [1, 2, 3, 4])
	var rules_before: Dictionary = rules.to_snapshot()
	var board_before: Dictionary = board.to_snapshot()
	var transformed: Dictionary = hunted.request_transition_by_trigger(2, "transform", rules, board)
	_expect(
		(
			transformed.accepted
			and hunted.role_tags_for_seat(2).has("horror")
			and hunted.seat_states[2].revealed
		),
		"transforms a Living seat into a public Horror generically"
	)
	_expect(
		rules.to_snapshot() == rules_before and board.to_snapshot() == board_before,
		"transition without downstream proposals leaves other authorities unchanged"
	)
	_expect(
		(
			hunted.perform_action_by_tag(2, "pressure", [], rules, board).accepted
			and rules.counters.dread == 1
		),
		"routes a Horror action through RulesSession"
	)
	var outbreak := RoleSession.new(LanternHouseSocialContent.new(), "outbreak", 99, [1, 2, 3, 4])
	var changed_seat: int = outbreak.seat_with_tag("changed")
	var living_seat: int = outbreak.seat_with_tag("living")
	var spread: Dictionary = outbreak.perform_action_by_tag(
		changed_seat, "spread", [living_seat], rules, board
	)
	_expect(
		(
			spread.accepted
			and outbreak.role_tags_for_seat(living_seat).has("changed")
			and outbreak.seat_states[living_seat].revealed
		),
		"performs one bounded Changed spread transition"
	)
	var spread_snapshot: Dictionary = outbreak.to_snapshot()
	_expect(
		(
			not (
				outbreak
				. perform_action_by_tag(
					changed_seat, "spread", [outbreak.seat_with_tag("living")], rules, board
				)
				. accepted
			)
			and outbreak.to_snapshot() == spread_snapshot
		),
		"enforces Changed spread use bounds atomically"
	)
	var cured: Dictionary = outbreak.request_transition_by_trigger(
		living_seat, "cure", rules, board
	)
	_expect(
		cured.accepted and outbreak.role_tags_for_seat(living_seat).has("living"),
		"supports generic cure and allegiance restoration"
	)
	var atomic := RoleSession.new(LanternHouseSocialContent.new(), "cooperative", 7, [1, 2])
	board.apply_mutation(BoardMutation.feature("lantern_hall", "restless_omen", true))
	atomic.request_transition_by_trigger(1, "defeat", rules, board)
	var role_before: Dictionary = atomic.to_snapshot()
	var downstream_rules_before: Dictionary = rules.to_snapshot()
	var downstream_board_before: Dictionary = board.to_snapshot()
	_expect(
		not atomic.perform_action_by_tag(1, "afterlife_support", [], rules, board).accepted,
		"rejects an invalid downstream board effect"
	)
	_expect(
		(
			atomic.to_snapshot() == role_before
			and rules.to_snapshot() == downstream_rules_before
			and board.to_snapshot() == downstream_board_before
		),
		"keeps role, rules, board, uses, histories, and revisions atomic on downstream rejection"
	)
	var mismatch := RoleSession.new(LanternHouseSocialContent.new(), "cooperative", 8, [1])
	mismatch.request_transition_by_trigger(1, "defeat", rules, board)
	var mismatch_snapshot: Dictionary = mismatch.to_snapshot()
	_expect(
		(
			not (
				mismatch
				. perform_action_by_tag(
					1,
					"afterlife_support",
					[],
					rules,
					BoardState.new(LanternHouseBoardDefinition.new())
				)
				. accepted
			)
			and mismatch.to_snapshot() == mismatch_snapshot
		),
		"rejects mismatched downstream authorities without partial state"
	)


func _test_reconnect_and_afterlife() -> void:
	var board := BoardState.new(LanternHouseBoardDefinition.new())
	var rules := RulesSession.new(LanternHouseRulesContent.new(), board, 501, [1, 2, 3, 4])
	var hidden := RoleSession.new(
		LanternHouseSocialContent.new(), "hidden_betrayer", 501, [1, 2, 3, 4]
	)
	var secret_seat: int = hidden.seat_with_tag("secret")
	var private_before: Dictionary = hidden.seat_private_view(secret_seat).private
	_expect(
		(
			hidden.set_seat_connected(secret_seat, false).accepted
			and not hidden.seat_states[secret_seat].connected
		),
		"reserves a disconnected stable seat"
	)
	_expect(
		(
			hidden.set_seat_connected(secret_seat, true).accepted
			and hidden.seat_private_view(secret_seat).private == private_before
		),
		"restores the same role, faction, objectives, resources, and prompts after reconnect"
	)
	_expect(
		(
			hidden.privacy_report().passed
			and not (
				hidden.content.role_by_id(hidden.seat_states[secret_seat].form_id).id
				in JSON.stringify(hidden.public_view())
			)
		),
		"reconnect does not leak or reassign secret state"
	)
	_expect(
		(
			hidden.request_late_join(5).accepted
			and hidden.pending_late_seats == [5]
			and not hidden.seat_states.has(5)
		),
		"uses an explicit deferred late-join policy"
	)
	var afterlife := RoleSession.new(
		LanternHouseSocialContent.new(), "cooperative", 501, [1, 2, 3, 4]
	)
	_expect(
		(
			afterlife.request_transition_by_trigger(1, "defeat", rules, board).accepted
			and afterlife.role_tags_for_seat(1).has("afterlife")
		),
		"moves a defeated seat into authored Restless afterlife"
	)
	_expect(
		not afterlife.legal_actions(1, rules).is_empty(),
		"guarantees a defeated seat a meaningful legal action"
	)
	var omen: Dictionary = afterlife.perform_action_by_tag(1, "afterlife_support", [], rules, board)
	_expect(
		omen.accepted and board.get_space_state("lantern_hall").features.has("restless_omen"),
		"performs a meaningful Restless action through BoardState"
	)
	var guardian := RoleSession.new(LanternHouseSocialContent.new(), "cooperative", 502, [1, 2])
	guardian.request_transition_by_trigger(1, "defeat", rules, board)
	_expect(
		(
			guardian.request_transition_by_trigger(1, "guardian_path", rules, board).accepted
			and guardian.role_tags_for_seat(1).has("guardian")
		),
		"supports an alternate guardian afterlife path"
	)
	_expect(
		(
			guardian.perform_action_by_tag(1, "guardian", [], rules, board).accepted
			and rules.flags.guardian_warning
		),
		"gives the guardian a legal protective action"
	)
	var replacement := RoleSession.new(LanternHouseSocialContent.new(), "cooperative", 503, [1, 2])
	replacement.request_transition_by_trigger(1, "defeat", rules, board)
	_expect(
		(
			replacement.request_transition_by_trigger(1, "replacement", rules, board).accepted
			and replacement.seat_states[1].lifecycle == "replacement"
		),
		"supports a replacement investigator path"
	)
	_expect(
		replacement.perform_action_by_tag(1, "replacement", [], rules, board).accepted,
		"gives the replacement investigator a legal action"
	)
	_expect(
		(
			replacement.request_transition_by_trigger(1, "escape", rules, board).accepted
			and replacement.seat_states[1].escaped
		),
		"supports a generic escape transition"
	)


func _test_disconnected_action_boundaries() -> void:
	var board := BoardState.new(LanternHouseBoardDefinition.new())
	var rules := RulesSession.new(LanternHouseRulesContent.new(), board, 8501, [1, 2, 3, 4])
	var hidden := RoleSession.new(
		LanternHouseSocialContent.new(), "hidden_betrayer", 8501, [1, 2, 3, 4]
	)
	var actor: int = hidden.seat_with_tag("secret")
	var actor_state_before: Dictionary = hidden.seat_states[actor].duplicate(true)
	var actor_private_before: Dictionary = hidden.seat_private_view(actor).private
	var actor_rng_before: Dictionary = hidden.rng.to_snapshot()
	var actor_revision_before: int = hidden.revision
	var actor_audit_before: int = hidden.audit_history.size()
	var actor_public_history_before: int = hidden.public_history.size()
	_expect(
		hidden.set_seat_connected(actor, false).accepted,
		"reserves the disconnected actor without changing social ownership"
	)
	var reserved_snapshot: Dictionary = hidden.to_snapshot()
	var history_after_disconnect: Array[Dictionary] = hidden.public_history.duplicate(true)
	_expect(
		hidden.legal_actions(actor, rules).is_empty(),
		"returns no ordinary legal actions for a disconnected actor"
	)
	var actor_rejection: Dictionary = hidden.perform_action_by_tag(
		actor, "secret", [], rules, board
	)
	_expect(
		not actor_rejection.accepted and actor_rejection.reason == "action_actor_disconnected",
		"rejects an ordinary role action from a disconnected actor"
	)
	_expect(
		(
			hidden.to_snapshot() == reserved_snapshot
			and hidden.public_history == history_after_disconnect
		),
		"keeps disconnected actor rejection free of role/action revision or audit mutation"
	)
	_expect(
		hidden.set_seat_connected(actor, true).accepted, "reconnects the same stable-seat owner"
	)
	_expect(
		(
			hidden.seat_states[actor] == actor_state_before
			and hidden.seat_private_view(actor).private == actor_private_before
		),
		(
			"restores the same role, faction, objectives, resources, cooldowns, uses, "
			+ "prompts, and private view"
		)
	)
	_expect(
		not hidden.legal_actions(actor, rules).is_empty(),
		"restores the actor's legal actions after reconnect"
	)
	_expect(
		(
			hidden.rng.to_snapshot() == actor_rng_before
			and hidden.revision == actor_revision_before + 2
		),
		"consumes no RNG and records only the two documented connection revisions"
	)
	_expect(
		(
			hidden.audit_history.size() == actor_audit_before + 2
			and hidden.public_history.size() == actor_public_history_before + 2
		),
		"records only sanitized disconnect and reconnect events"
	)
	var actor_role: Dictionary = hidden.content.role_by_id(actor_state_before.form_id)
	var actor_objective: Dictionary = hidden.content.objective_by_id(
		actor_state_before.objective_refs[0]
	)
	var actor_public_json: String = JSON.stringify(hidden.public_view())
	_expect(
		(
			not actor_role.id in JSON.stringify(actor_rejection)
			and not actor_objective.description in JSON.stringify(actor_rejection)
			and not actor_role.id in actor_public_json
			and not actor_objective.description in actor_public_json
			and hidden.privacy_report().passed
		),
		"keeps disconnected rejection messages and public history free of secret values"
	)

	var target_board := BoardState.new(LanternHouseBoardDefinition.new())
	var target_rules := RulesSession.new(
		LanternHouseRulesContent.new(), target_board, 8502, [1, 2, 3, 4]
	)
	var outbreak := RoleSession.new(LanternHouseSocialContent.new(), "outbreak", 8502, [1, 2, 3, 4])
	var changed_actor: int = outbreak.seat_with_tag("changed")
	var disconnected_target: int = outbreak.seat_with_tag("living")
	var target_state_before: Dictionary = outbreak.seat_states[disconnected_target].duplicate(true)
	var target_private_before: Dictionary = outbreak.seat_private_view(disconnected_target).private
	var target_rng_before: Dictionary = outbreak.rng.to_snapshot()
	outbreak.set_seat_connected(disconnected_target, false)
	var target_reserved_snapshot: Dictionary = outbreak.to_snapshot()
	var target_history_after_disconnect: Array[Dictionary] = outbreak.public_history.duplicate(true)
	var target_rejection: Dictionary = outbreak.perform_action_by_tag(
		changed_actor, "spread", [disconnected_target], target_rules, target_board
	)
	_expect(
		not target_rejection.accepted and target_rejection.reason == "action_target_disconnected",
		"rejects a disconnected seat as an ordinary role-action target"
	)
	_expect(
		(
			outbreak.to_snapshot() == target_reserved_snapshot
			and outbreak.public_history == target_history_after_disconnect
			and outbreak.rng.to_snapshot() == target_rng_before
		),
		"keeps disconnected target rejection atomic and RNG-free"
	)
	outbreak.set_seat_connected(disconnected_target, true)
	_expect(
		(
			outbreak.seat_states[disconnected_target] == target_state_before
			and outbreak.seat_private_view(disconnected_target).private == target_private_before
		),
		"restores the targeted seat's exact private state on reconnect"
	)
	_expect(
		(
			outbreak.privacy_report().passed
			and not (
				outbreak.content.role_by_id(target_state_before.form_id).id
				in JSON.stringify(target_rejection)
			)
		),
		"keeps disconnected target rejection and reconnect history privacy-safe"
	)


func _test_outcomes_and_snapshots() -> void:
	var board := BoardState.new(LanternHouseBoardDefinition.new())
	var rules := RulesSession.new(LanternHouseRulesContent.new(), board, 700, [1, 2, 3, 4])
	var mixed := RoleSession.new(
		LanternHouseSocialContent.new(), "mixed_fixture", 700, [1, 2, 3, 4]
	)
	rules.apply_effect_bundle(
		[
			{"type": "set_flag", "flag_id": "house_secured", "value": true},
			{"type": "set_flag", "flag_id": "archive_broken", "value": true}
		],
		0,
		"mixed_test"
	)
	mixed.perform_action_by_tag(
		mixed.seat_with_tag("changed"), "spread", [mixed.seat_with_tag("living")], rules, board
	)
	mixed.perform_action_by_tag(
		mixed.seat_with_tag("afterlife"), "afterlife_support", [], rules, board
	)
	var rules_before: Dictionary = rules.to_snapshot()
	var board_before: Dictionary = board.to_snapshot()
	var proposal: Dictionary = mixed.evaluate_outcomes(rules, board)
	_expect(
		(
			rules.to_snapshot() == rules_before
			and board.to_snapshot() == board_before
			and mixed.resolved_outcome.is_empty()
		),
		"evaluates objectives deterministically without side effects"
	)
	var winning_results: Array[String] = []
	for seat: Dictionary in proposal.public.seats:
		winning_results.append(seat.result)
	_expect(
		(
			winning_results.has("victory")
			and winning_results.count("changed") >= 2
			and winning_results.has("restless")
		),
		"supports multiple faction, individual, Changed, Restless, and mixed winners"
	)
	var resolution: Dictionary = mixed.resolve_outcomes(rules, board)
	_expect(
		(
			resolution.accepted
			and rules.terminal_reason == "social_outcome"
			and not mixed.public_view().outcome.is_empty()
		),
		"submits one terminal result with per-seat and per-faction summaries"
	)
	var revision_after: int = mixed.revision
	_expect(
		mixed.resolve_outcomes(rules, board).idempotent and mixed.revision == revision_after,
		"keeps terminal outcome resolution idempotent"
	)
	var source := RoleSession.new(LanternHouseSocialContent.new(), "outbreak", 12345, [1, 2, 3, 4])
	var snapshot: Dictionary = source.to_snapshot()
	var json_snapshot: Variant = JSON.parse_string(JSON.stringify(snapshot))
	var restored := RoleSession.new(LanternHouseSocialContent.new(), "cooperative", 1, [1])
	_expect(
		restored.restore_snapshot(json_snapshot).accepted and restored.to_snapshot() == snapshot,
		"round-trips a versioned JSON-compatible full role snapshot"
	)
	var actor: int = source.seat_with_tag("changed")
	var target: int = source.seat_with_tag("living")
	var source_rules := RulesSession.new(
		LanternHouseRulesContent.new(),
		BoardState.new(LanternHouseBoardDefinition.new()),
		12345,
		[1, 2, 3, 4]
	)
	var restored_rules := RulesSession.new(
		LanternHouseRulesContent.new(),
		BoardState.new(LanternHouseBoardDefinition.new()),
		12345,
		[1, 2, 3, 4]
	)
	source.perform_action_by_tag(actor, "spread", [target], source_rules, source_rules.board_state)
	restored.perform_action_by_tag(
		actor, "spread", [target], restored_rules, restored_rules.board_state
	)
	_expect(
		source.to_snapshot() == restored.to_snapshot(),
		"snapshot restore reproduces the next valid transition/action decision"
	)
	var stable: Dictionary = restored.to_snapshot()
	var malformed: Dictionary = snapshot.duplicate(true)
	malformed.seat_states[0].state.form_id = "unknown_form"
	_expect(
		not restored.restore_snapshot(malformed).accepted and restored.to_snapshot() == stable,
		"rejects malformed unknown-form snapshots atomically"
	)
	var impossible: Dictionary = snapshot.duplicate(true)
	impossible.seat_states[0].state.faction_id = "restless"
	_expect(
		not restored.restore_snapshot(impossible).accepted and restored.to_snapshot() == stable,
		"rejects impossible role/faction snapshot combinations atomically"
	)


func _test_hud_and_diagnostics_contract() -> void:
	var session := RoleSession.new(
		LanternHouseSocialContent.new(), "hidden_betrayer", 900, [1, 2, 3, 4, 5, 6, 7, 8]
	)
	var hud := RoleHud.new()
	root.add_child(hud)
	await process_frame
	hud.present(session, {"kind": "public", "title": "PUBLIC TEST"})
	_expect(
		(
			hud.get_view_model().essential_content_fits
			and not hud.get_view_model().contains_private_ids
		),
		"keeps the eight-seat public HUD bounded and private-ID free"
	)
	var secret_seat: int = session.seat_with_tag("secret")
	hud.present(session, {"kind": "seat_private", "seat": secret_seat, "title": "PRIVATE TEST"})
	_expect(
		(
			hud.get_view_model().shared_screen_obscured
			and "SHARED SCREEN OBSCURED" in hud.rendered_player_text()
		),
		"never pretends ordinary shared-screen content is private"
	)
	_expect(
		not hud.handle_private_input(session, 1 if secret_seat != 1 else 2, true, false),
		"rejects private acknowledgement from an unauthorized seat"
	)
	_expect(
		(
			hud.handle_private_input(session, secret_seat, true, false)
			and hud.get_view_model().kind == "public"
			and session.seat_states[secret_seat].acknowledged
		),
		"acknowledges and closes a seat-private reveal safely"
	)
	var diagnostics := RoleDiagnostics.new()
	root.add_child(diagnostics)
	await process_frame
	diagnostics.present(session, 0)
	_expect(
		"SPOILER" in diagnostics._title.text and "ROLE RNG" in diagnostics.rendered_text(),
		"separates and labels spoiler diagnostics"
	)
	diagnostics.next_page(1)
	diagnostics.next_page(1)
	_expect(
		"LEAK EVALUATION" in diagnostics.rendered_text(), "pages long diagnostics deterministically"
	)
	for margin: int in [0, 24, 48]:
		var safe := Rect2(Vector2(margin, margin), Vector2(960 - margin * 2, 540 - margin * 2))
		_expect(
			safe.encloses(RoleHud.calculate_panel_rect(Vector2(960, 540), margin)),
			"keeps role HUD inside %d px safe frame" % margin
		)
		_expect(
			safe.encloses(RoleHud.calculate_panel_rect(Vector2(960, 540), margin, true)),
			"keeps private reveal inside %d px safe frame" % margin
		)
		_expect(
			safe.encloses(RoleDiagnostics.calculate_panel_rect(Vector2(960, 540), margin)),
			"keeps spoiler diagnostics inside %d px safe frame" % margin
		)
	for viewport: Vector2 in [Vector2(1280, 720), Vector2(1920, 1080), Vector2(3840, 2160)]:
		var safe := Rect2(Vector2(48, 48), viewport - Vector2(96, 96))
		_expect(
			(
				safe.encloses(RoleHud.calculate_panel_rect(viewport, 48))
				and safe.encloses(RoleDiagnostics.calculate_panel_rect(viewport, 48))
			),
			"keeps social presentation inside 48 px safe frame at %dx%d" % [viewport.x, viewport.y]
		)
	hud.free()
	diagnostics.free()


func _test_generic_id_branch_guard() -> void:
	var authored := LanternHouseSocialContent.new()
	var generic_paths: Array[String] = [
		"res://src/social/social_content.gd",
		"res://src/social/role_session.gd",
		"res://src/social/role_hud.gd",
		"res://src/social/role_diagnostics.gd",
	]
	var forbidden: Array[String] = []
	for definition_set: Array[Dictionary] in [
		authored.factions, authored.roles, authored.objectives, authored.fixtures
	]:
		for definition: Dictionary in definition_set:
			forbidden.append(definition.id)
	for path: String in generic_paths:
		var source: String = FileAccess.get_file_as_string(path)
		for stable_id: String in forbidden:
			_expect(
				(
					not ('if role_id == "%s"' % stable_id) in source
					and not ('if faction_id == "%s"' % stable_id) in source
					and not ('if form_id == "%s"' % stable_id) in source
					and not ('match "%s"' % stable_id) in source
				),
				(
					"keeps literal authored ID %s out of generic runtime/presentation branches"
					% stable_id
				)
			)
	var runtime_source: String = FileAccess.get_file_as_string("res://src/social/role_session.gd")
	_expect(
		(
			not "rules.flags[" in runtime_source
			and not "board._" in runtime_source
			and not "rules.counters[" in runtime_source
		),
		"keeps direct RulesSession and BoardState dictionary mutation out of RoleSession"
	)


func _contains(failures: PackedStringArray, fragment: String) -> bool:
	return Array(failures).any(func(failure: String) -> bool: return fragment in failure)


func _test_action(
	base_action: Dictionary,
	stable_id: String,
	friendly_label: String,
	visibility: String,
	target_scope: String,
	minimum_targets: int,
	maximum_targets: int
) -> Dictionary:
	var action: Dictionary = base_action.duplicate(true)
	action.id = stable_id
	action.label = friendly_label
	action.description = "Deterministic target-discovery regression action."
	action.visibility = visibility
	action.target_scope = target_scope
	action.minimum_targets = minimum_targets
	action.maximum_targets = maximum_targets
	action.use_limit = 0
	action.per_round_limit = 0
	action.cooldown = 0
	action.tags = ["target_discovery_probe"]
	action.proposals = []
	return action


func _action_ids(actions: Array[Dictionary]) -> Array[String]:
	var ids: Array[String] = []
	for action: Dictionary in actions:
		ids.append(action.action_id)
	return ids


func _expect(condition: bool, description: String) -> void:
	if not condition:
		_failures += 1
		push_error("FAILED: %s" % description)
