extends SceneTree

var _failures: int = 0

func _initialize() -> void:
	_test_content_validation()
	_test_assignment_rng_and_fallback()
	_test_privacy_views_and_director_blindness()
	_test_transitions_and_actions()
	_test_reconnect_and_afterlife()
	_test_outcomes_and_snapshots()
	_test_hud_and_diagnostics_contract()
	_test_generic_id_branch_guard()
	if _failures == 0:
		print("Roles, Factions & Afterlife tests passed")
	quit(_failures)

func _test_content_validation() -> void:
	var content := LanternHouseSocialContent.new()
	_expect(content.validate(LanternHouseRulesContent.new(), LanternHouseBoardDefinition.new()).is_empty(), "accepts declarative Lantern House social content")
	var faction_labels: Array[String] = []
	for faction: Dictionary in content.factions: faction_labels.append(faction.label)
	for expected: String in ["Living", "Betrayer", "Horror", "Changed", "Restless"]:
		_expect(faction_labels.has(expected), "represents %s through authored data" % expected)
	var duplicate := LanternHouseSocialContent.new()
	duplicate.factions.append(duplicate.factions[0].duplicate(true))
	_expect(_contains(duplicate.validate(), "duplicate faction"), "rejects duplicate faction IDs")
	var missing_faction := LanternHouseSocialContent.new()
	missing_faction.roles[0].starting_faction = "missing_faction"
	_expect(_contains(missing_faction.validate(), "no legal faction"), "rejects roles with no legal faction")
	var unsafe_hidden := LanternHouseSocialContent.new()
	unsafe_hidden.roles[1].public_cover = {}
	_expect(_contains(unsafe_hidden.validate(), "safe public representation"), "rejects hidden roles without a safe public cover")
	var arbitrary_script := LanternHouseSocialContent.new()
	arbitrary_script.actions[0].proposals = [{"type": "execute_script", "path": "res://bad.gd"}]
	_expect(_contains(arbitrary_script.validate(), "invalid action proposal"), "rejects arbitrary action scripting")
	var missing_transition := LanternHouseSocialContent.new()
	missing_transition.transitions[0].target_form = "missing_form"
	_expect(_contains(missing_transition.validate(), "unknown transition target"), "rejects impossible transition targets")
	var passive_afterlife := LanternHouseSocialContent.new()
	passive_afterlife.roles[4].action_refs = []
	_expect(_contains(passive_afterlife.validate(), "afterlife") or _contains(passive_afterlife.validate(), "legal objective and action"), "rejects passive permanent afterlife")
	var unbounded := LanternHouseSocialContent.new()
	unbounded.transitions[0].max_chain = 0
	_expect(_contains(unbounded.validate(), "unbounded transition"), "rejects unbounded transition chains")
	var impossible_mode := LanternHouseSocialContent.new()
	impossible_mode.modes[1].assignment_pool[0].count = 9
	_expect(_contains(impossible_mode.validate(), "impossible assignment plan"), "rejects impossible scenario assignment plans during content validation")

func _test_assignment_rng_and_fallback() -> void:
	var first := RoleSession.new(LanternHouseSocialContent.new(), "hidden_betrayer", 4706, [1, 2, 3, 4])
	var second := RoleSession.new(LanternHouseSocialContent.new(), "hidden_betrayer", 4706, [1, 2, 3, 4])
	_expect(first.initialization_errors.is_empty() and first.to_snapshot() == second.to_snapshot(), "reproduces randomized assignment with a dedicated role RNG")
	_expect(first.rng.counter == 1, "consumes one bounded role draw for one hostile assignment")
	var cooperative := RoleSession.new(LanternHouseSocialContent.new(), "cooperative", 4706, [1, 2, 3, 4])
	_expect(cooperative.rng.counter == 0, "fixed cooperative assignment consumes no random values")
	var board := BoardState.new(LanternHouseBoardDefinition.new())
	var rules := RulesSession.new(LanternHouseRulesContent.new(), board, 4706, [1, 2, 3, 4])
	var director := DirectorRuntime.new(LanternHouseDirectorContent.new(), "standard", 4706, rules.content, board.definition)
	var rules_rng_before: Dictionary = rules.rng.to_snapshot()
	var director_rng_before: Dictionary = director.rng.to_snapshot()
	RoleSession.new(LanternHouseSocialContent.new(), "hidden_betrayer", 4706, [1, 2, 3, 4])
	_expect(rules.rng.to_snapshot() == rules_rng_before and director.rng.to_snapshot() == director_rng_before, "keeps role assignment isolated from RulesSession and Director RNG")
	var stable: Dictionary = first.to_snapshot()
	var role_rng_before: Dictionary = first.rng.to_snapshot()
	_expect(not first.assign_mode("missing_mode", [1, 2, 3, 4]).accepted and first.to_snapshot() == stable and first.rng.to_snapshot() == role_rng_before, "invalid assignment changes no role state and consumes no role RNG")
	var fallback := RoleSession.new(LanternHouseSocialContent.new(), "hidden_betrayer", 99, [1])
	_expect(fallback.fallback_applied and fallback.mode_id == "cooperative" and fallback.public_view().fallback_active, "selects an explicit authored no-secret fallback for unsupported one-seat betrayal")
	_expect(fallback.rng.counter == 0 and fallback.seat_with_tag("secret") == 0, "safe fallback contains no hostile secret and consumes no role RNG")
	var mortal := RoleSession.new(LanternHouseSocialContent.new(), "no_afterlife", 99, [1])
	_expect("WARNING BEFORE PLAY" in mortal.public_view().afterlife_notice and not mortal.request_transition_by_trigger(1, "defeat").accepted, "warns before play and rejects afterlife transitions when an authored mode disables afterlife")

func _test_privacy_views_and_director_blindness() -> void:
	var session := RoleSession.new(LanternHouseSocialContent.new(), "hidden_betrayer", 8080, [1, 2, 3, 4])
	var secret_seat: int = session.seat_with_tag("secret")
	var secret_state: Dictionary = session.seat_states[secret_seat]
	var role: Dictionary = session.content.role_by_id(secret_state.form_id)
	var faction: Dictionary = session.content.faction_by_id(secret_state.faction_id)
	var secret_objective: Dictionary = session.content.objective_by_id(secret_state.objective_refs[0])
	var public_json: String = JSON.stringify(session.public_view())
	for secret: String in [role.id, faction.id, secret_objective.id, role.description, secret_objective.description]:
		_expect(not secret in public_json, "keeps hidden value out of recursive public view")
	var own_private: Dictionary = session.seat_private_view(secret_seat)
	_expect(own_private.accepted and own_private.private.role_id == role.id and own_private.shared_screen_warning.begins_with("OBSCURE"), "authorizes explicit obscured seat-private reveal")
	var other_seat: int = 1 if secret_seat != 1 else 2
	var other_private_json: String = JSON.stringify(session.seat_private_view(other_seat))
	_expect(not role.id in other_private_json and not secret_objective.description in other_private_json, "prevents one seat from inspecting another seat's secrets")
	_expect(not session.faction_private_view(secret_seat).accepted, "honors authored no-communication policy for the hidden opposition")
	_expect(session.faction_private_view(other_seat).accepted, "provides an explicit authorized faction-private view")
	_expect(session.privacy_report().passed, "recursively checks public, Director, and unauthorized-seat surfaces for secret leakage")
	var rejection: Dictionary = session.perform_action(secret_seat, "unknown_action", [])
	_expect(not role.id in JSON.stringify(rejection) and not secret_objective.description in JSON.stringify(rejection) and not role.id in session.last_rejection, "keeps rejection errors free of private identifiers and text")
	var board := BoardState.new(LanternHouseBoardDefinition.new())
	var rules := RulesSession.new(LanternHouseRulesContent.new(), board, 8080, [1, 2, 3, 4])
	var telemetry_before: Dictionary = DirectorTelemetry.build(rules, board, session)
	var alternate := RoleSession.new(LanternHouseSocialContent.new(), "hidden_betrayer", 99, [1, 2, 3, 4])
	var telemetry_alternate: Dictionary = DirectorTelemetry.build(rules, board, alternate)
	_expect(telemetry_before.social_signals == telemetry_alternate.social_signals and telemetry_before.future_balance_signal == telemetry_alternate.future_balance_signal, "keeps Director signals unchanged across unrevealed secret assignments")
	_expect(not JSON.stringify(telemetry_before).contains(role.id) and not JSON.stringify(telemetry_before).contains(secret_objective.id), "keeps role IDs and private objectives out of Director telemetry")
	var runtime_a := DirectorRuntime.new(LanternHouseDirectorContent.new(), "standard", 8080, rules.content, board.definition)
	var runtime_b := DirectorRuntime.new(LanternHouseDirectorContent.new(), "standard", 8080, rules.content, board.definition)
	var decision_a: Dictionary = runtime_a.evaluate(telemetry_before)
	var decision_b: Dictionary = runtime_b.evaluate(telemetry_alternate)
	_expect(decision_a.has("selected_candidate_id") and decision_b.has("selected_candidate_id"), "keeps authorized social telemetry valid for the Director")
	_expect(decision_a.get("selected_candidate_id", "") == decision_b.get("selected_candidate_id", ""), "prevents unrevealed private differences from changing Director decisions")
	session.request_transition_by_trigger(secret_seat, "reveal", rules, board)
	var revealed_telemetry: Dictionary = DirectorTelemetry.build(rules, board, session)
	_expect(revealed_telemetry.social_signals.revealed_faction_count > telemetry_before.social_signals.revealed_faction_count, "allows an authored public reveal to change aggregate Director-safe signals")

func _test_transitions_and_actions() -> void:
	var board := BoardState.new(LanternHouseBoardDefinition.new())
	var rules := RulesSession.new(LanternHouseRulesContent.new(), board, 121, [1, 2, 3, 4])
	var hunted := RoleSession.new(LanternHouseSocialContent.new(), "hunted", 121, [1, 2, 3, 4])
	var rules_before: Dictionary = rules.to_snapshot()
	var board_before: Dictionary = board.to_snapshot()
	var transformed: Dictionary = hunted.request_transition_by_trigger(2, "transform", rules, board)
	_expect(transformed.accepted and hunted.role_tags_for_seat(2).has("horror") and hunted.seat_states[2].revealed, "transforms a Living seat into a public Horror generically")
	_expect(rules.to_snapshot() == rules_before and board.to_snapshot() == board_before, "transition without downstream proposals leaves other authorities unchanged")
	_expect(hunted.perform_action_by_tag(2, "pressure", [], rules, board).accepted and rules.counters.dread == 1, "routes a Horror action through RulesSession")
	var outbreak := RoleSession.new(LanternHouseSocialContent.new(), "outbreak", 99, [1, 2, 3, 4])
	var changed_seat: int = outbreak.seat_with_tag("changed")
	var living_seat: int = outbreak.seat_with_tag("living")
	var spread: Dictionary = outbreak.perform_action_by_tag(changed_seat, "spread", [living_seat], rules, board)
	_expect(spread.accepted and outbreak.role_tags_for_seat(living_seat).has("changed") and outbreak.seat_states[living_seat].revealed, "performs one bounded Changed spread transition")
	var spread_snapshot: Dictionary = outbreak.to_snapshot()
	_expect(not outbreak.perform_action_by_tag(changed_seat, "spread", [outbreak.seat_with_tag("living")], rules, board).accepted and outbreak.to_snapshot() == spread_snapshot, "enforces Changed spread use bounds atomically")
	var cured: Dictionary = outbreak.request_transition_by_trigger(living_seat, "cure", rules, board)
	_expect(cured.accepted and outbreak.role_tags_for_seat(living_seat).has("living"), "supports generic cure and allegiance restoration")
	var atomic := RoleSession.new(LanternHouseSocialContent.new(), "cooperative", 7, [1, 2])
	board.apply_mutation(BoardMutation.feature("lantern_hall", "restless_omen", true))
	atomic.request_transition_by_trigger(1, "defeat", rules, board)
	var role_before: Dictionary = atomic.to_snapshot()
	var downstream_rules_before: Dictionary = rules.to_snapshot()
	var downstream_board_before: Dictionary = board.to_snapshot()
	_expect(not atomic.perform_action_by_tag(1, "afterlife_support", [], rules, board).accepted, "rejects an invalid downstream board effect")
	_expect(atomic.to_snapshot() == role_before and rules.to_snapshot() == downstream_rules_before and board.to_snapshot() == downstream_board_before, "keeps role, rules, board, uses, histories, and revisions atomic on downstream rejection")
	var mismatch := RoleSession.new(LanternHouseSocialContent.new(), "cooperative", 8, [1])
	mismatch.request_transition_by_trigger(1, "defeat", rules, board)
	var mismatch_snapshot: Dictionary = mismatch.to_snapshot()
	_expect(not mismatch.perform_action_by_tag(1, "afterlife_support", [], rules, BoardState.new(LanternHouseBoardDefinition.new())).accepted and mismatch.to_snapshot() == mismatch_snapshot, "rejects mismatched downstream authorities without partial state")

func _test_reconnect_and_afterlife() -> void:
	var board := BoardState.new(LanternHouseBoardDefinition.new())
	var rules := RulesSession.new(LanternHouseRulesContent.new(), board, 501, [1, 2, 3, 4])
	var hidden := RoleSession.new(LanternHouseSocialContent.new(), "hidden_betrayer", 501, [1, 2, 3, 4])
	var secret_seat: int = hidden.seat_with_tag("secret")
	var private_before: Dictionary = hidden.seat_private_view(secret_seat).private
	_expect(hidden.set_seat_connected(secret_seat, false).accepted and not hidden.seat_states[secret_seat].connected, "reserves a disconnected stable seat")
	_expect(hidden.set_seat_connected(secret_seat, true).accepted and hidden.seat_private_view(secret_seat).private == private_before, "restores the same role, faction, objectives, resources, and prompts after reconnect")
	_expect(hidden.privacy_report().passed and not hidden.content.role_by_id(hidden.seat_states[secret_seat].form_id).id in JSON.stringify(hidden.public_view()), "reconnect does not leak or reassign secret state")
	_expect(hidden.request_late_join(5).accepted and hidden.pending_late_seats == [5] and not hidden.seat_states.has(5), "uses an explicit deferred late-join policy")
	var afterlife := RoleSession.new(LanternHouseSocialContent.new(), "cooperative", 501, [1, 2, 3, 4])
	_expect(afterlife.request_transition_by_trigger(1, "defeat", rules, board).accepted and afterlife.role_tags_for_seat(1).has("afterlife"), "moves a defeated seat into authored Restless afterlife")
	_expect(not afterlife.legal_actions(1, rules).is_empty(), "guarantees a defeated seat a meaningful legal action")
	var omen: Dictionary = afterlife.perform_action_by_tag(1, "afterlife_support", [], rules, board)
	_expect(omen.accepted and board.get_space_state("lantern_hall").features.has("restless_omen"), "performs a meaningful Restless action through BoardState")
	var guardian := RoleSession.new(LanternHouseSocialContent.new(), "cooperative", 502, [1, 2])
	guardian.request_transition_by_trigger(1, "defeat", rules, board)
	_expect(guardian.request_transition_by_trigger(1, "guardian_path", rules, board).accepted and guardian.role_tags_for_seat(1).has("guardian"), "supports an alternate guardian afterlife path")
	_expect(guardian.perform_action_by_tag(1, "guardian", [], rules, board).accepted and rules.flags.guardian_warning, "gives the guardian a legal protective action")
	var replacement := RoleSession.new(LanternHouseSocialContent.new(), "cooperative", 503, [1, 2])
	replacement.request_transition_by_trigger(1, "defeat", rules, board)
	_expect(replacement.request_transition_by_trigger(1, "replacement", rules, board).accepted and replacement.seat_states[1].lifecycle == "replacement", "supports a replacement investigator path")
	_expect(replacement.perform_action_by_tag(1, "replacement", [], rules, board).accepted, "gives the replacement investigator a legal action")
	_expect(replacement.request_transition_by_trigger(1, "escape", rules, board).accepted and replacement.seat_states[1].escaped, "supports a generic escape transition")

func _test_outcomes_and_snapshots() -> void:
	var board := BoardState.new(LanternHouseBoardDefinition.new())
	var rules := RulesSession.new(LanternHouseRulesContent.new(), board, 700, [1, 2, 3, 4])
	var mixed := RoleSession.new(LanternHouseSocialContent.new(), "mixed_fixture", 700, [1, 2, 3, 4])
	rules.apply_effect_bundle([{"type": "set_flag", "flag_id": "house_secured", "value": true}, {"type": "set_flag", "flag_id": "archive_broken", "value": true}], 0, "mixed_test")
	mixed.perform_action_by_tag(mixed.seat_with_tag("changed"), "spread", [mixed.seat_with_tag("living")], rules, board)
	mixed.perform_action_by_tag(mixed.seat_with_tag("afterlife"), "afterlife_support", [], rules, board)
	var rules_before: Dictionary = rules.to_snapshot()
	var board_before: Dictionary = board.to_snapshot()
	var proposal: Dictionary = mixed.evaluate_outcomes(rules, board)
	_expect(rules.to_snapshot() == rules_before and board.to_snapshot() == board_before and mixed.resolved_outcome.is_empty(), "evaluates objectives deterministically without side effects")
	var winning_results: Array[String] = []
	for seat: Dictionary in proposal.public.seats: winning_results.append(seat.result)
	_expect(winning_results.has("victory") and winning_results.count("changed") >= 2 and winning_results.has("restless"), "supports multiple faction, individual, Changed, Restless, and mixed winners")
	var resolution: Dictionary = mixed.resolve_outcomes(rules, board)
	_expect(resolution.accepted and rules.terminal_reason == "social_outcome" and not mixed.public_view().outcome.is_empty(), "submits one terminal result with per-seat and per-faction summaries")
	var revision_after: int = mixed.revision
	_expect(mixed.resolve_outcomes(rules, board).idempotent and mixed.revision == revision_after, "keeps terminal outcome resolution idempotent")
	var source := RoleSession.new(LanternHouseSocialContent.new(), "outbreak", 12345, [1, 2, 3, 4])
	var snapshot: Dictionary = source.to_snapshot()
	var json_snapshot: Variant = JSON.parse_string(JSON.stringify(snapshot))
	var restored := RoleSession.new(LanternHouseSocialContent.new(), "cooperative", 1, [1])
	_expect(restored.restore_snapshot(json_snapshot).accepted and restored.to_snapshot() == snapshot, "round-trips a versioned JSON-compatible full role snapshot")
	var actor: int = source.seat_with_tag("changed")
	var target: int = source.seat_with_tag("living")
	var source_rules := RulesSession.new(LanternHouseRulesContent.new(), BoardState.new(LanternHouseBoardDefinition.new()), 12345, [1, 2, 3, 4])
	var restored_rules := RulesSession.new(LanternHouseRulesContent.new(), BoardState.new(LanternHouseBoardDefinition.new()), 12345, [1, 2, 3, 4])
	source.perform_action_by_tag(actor, "spread", [target], source_rules, source_rules.board_state)
	restored.perform_action_by_tag(actor, "spread", [target], restored_rules, restored_rules.board_state)
	_expect(source.to_snapshot() == restored.to_snapshot(), "snapshot restore reproduces the next valid transition/action decision")
	var stable: Dictionary = restored.to_snapshot()
	var malformed: Dictionary = snapshot.duplicate(true)
	malformed.seat_states[0].state.form_id = "unknown_form"
	_expect(not restored.restore_snapshot(malformed).accepted and restored.to_snapshot() == stable, "rejects malformed unknown-form snapshots atomically")
	var impossible: Dictionary = snapshot.duplicate(true)
	impossible.seat_states[0].state.faction_id = "restless"
	_expect(not restored.restore_snapshot(impossible).accepted and restored.to_snapshot() == stable, "rejects impossible role/faction snapshot combinations atomically")

func _test_hud_and_diagnostics_contract() -> void:
	var session := RoleSession.new(LanternHouseSocialContent.new(), "hidden_betrayer", 900, [1, 2, 3, 4, 5, 6, 7, 8])
	var hud := RoleHud.new()
	root.add_child(hud)
	await process_frame
	hud.present(session, {"kind": "public", "title": "PUBLIC TEST"})
	_expect(hud.get_view_model().essential_content_fits and not hud.get_view_model().contains_private_ids, "keeps the eight-seat public HUD bounded and private-ID free")
	var secret_seat: int = session.seat_with_tag("secret")
	hud.present(session, {"kind": "seat_private", "seat": secret_seat, "title": "PRIVATE TEST"})
	_expect(hud.get_view_model().shared_screen_obscured and "SHARED SCREEN OBSCURED" in hud.rendered_player_text(), "never pretends ordinary shared-screen content is private")
	_expect(not hud.handle_private_input(session, 1 if secret_seat != 1 else 2, true, false), "rejects private acknowledgement from an unauthorized seat")
	_expect(hud.handle_private_input(session, secret_seat, true, false) and hud.get_view_model().kind == "public" and session.seat_states[secret_seat].acknowledged, "acknowledges and closes a seat-private reveal safely")
	var diagnostics := RoleDiagnostics.new()
	root.add_child(diagnostics)
	await process_frame
	diagnostics.present(session, 0)
	_expect("SPOILER" in diagnostics._title.text and "ROLE RNG" in diagnostics.rendered_text(), "separates and labels spoiler diagnostics")
	var diagnostic_view: Dictionary = session.diagnostics_view(true)
	_expect(diagnostic_view.seat_private_previews.size() == 8 and diagnostic_view.transition_eligibility.size() == 8 and diagnostic_view.has("last_rejection"), "exposes independent private previews, eligibility, legal actions, and rejection diagnostics only in spoiler mode")
	diagnostics.next_page(1); diagnostics.next_page(1)
	_expect("LEAK EVALUATION" in diagnostics.rendered_text(), "pages long diagnostics deterministically")
	for margin: int in [0, 24, 48]:
		var safe := Rect2(Vector2(margin, margin), Vector2(960 - margin * 2, 540 - margin * 2))
		_expect(safe.encloses(RoleHud.calculate_panel_rect(Vector2(960, 540), margin)), "keeps role HUD inside %d px safe frame" % margin)
		_expect(safe.encloses(RoleHud.calculate_panel_rect(Vector2(960, 540), margin, true)), "keeps private reveal inside %d px safe frame" % margin)
		_expect(safe.encloses(RoleDiagnostics.calculate_panel_rect(Vector2(960, 540), margin)), "keeps spoiler diagnostics inside %d px safe frame" % margin)
	for viewport: Vector2 in [Vector2(1280, 720), Vector2(1920, 1080), Vector2(3840, 2160)]:
		var safe := Rect2(Vector2(48, 48), viewport - Vector2(96, 96))
		_expect(safe.encloses(RoleHud.calculate_panel_rect(viewport, 48)) and safe.encloses(RoleDiagnostics.calculate_panel_rect(viewport, 48)), "keeps social presentation inside 48 px safe frame at %dx%d" % [viewport.x, viewport.y])
	hud.free(); diagnostics.free()

func _test_generic_id_branch_guard() -> void:
	var authored := LanternHouseSocialContent.new()
	var generic_paths: Array[String] = [
		"res://src/social/social_content.gd", "res://src/social/role_session.gd",
		"res://src/social/role_hud.gd", "res://src/social/role_diagnostics.gd",
	]
	var forbidden: Array[String] = []
	for definition_set: Array[Dictionary] in [authored.factions, authored.roles, authored.objectives, authored.fixtures]:
		for definition: Dictionary in definition_set: forbidden.append(definition.id)
	for path: String in generic_paths:
		var source: String = FileAccess.get_file_as_string(path)
		for stable_id: String in forbidden:
			_expect(not ("if role_id == \"%s\"" % stable_id) in source and not ("if faction_id == \"%s\"" % stable_id) in source and not ("if form_id == \"%s\"" % stable_id) in source and not ("match \"%s\"" % stable_id) in source, "keeps literal authored ID %s out of generic runtime/presentation branches" % stable_id)
	var runtime_source: String = FileAccess.get_file_as_string("res://src/social/role_session.gd")
	_expect(not "rules.flags[" in runtime_source and not "board._" in runtime_source and not "rules.counters[" in runtime_source, "keeps direct RulesSession and BoardState dictionary mutation out of RoleSession")

func _contains(failures: PackedStringArray, fragment: String) -> bool:
	for failure: String in failures:
		if fragment in failure: return true
	return false

func _expect(condition: bool, description: String) -> void:
	if not condition:
		_failures += 1
		push_error("FAILED: %s" % description)
