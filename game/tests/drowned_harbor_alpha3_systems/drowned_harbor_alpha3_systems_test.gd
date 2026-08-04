extends SceneTree

const SUMMARY_PREFIX: String = "DROWNED_HARBOR_ALPHA3_SYSTEMS_EVIDENCE:"
const MATRIX_SEEDS: PackedInt32Array = [3101, 3102, 3103]
const MODE_SEATS: Dictionary = {
	"cooperative": [1, 2, 3, 4, 5, 6, 7, 8],
	"hidden_betrayer": [3, 4, 5, 6, 7, 8],
	"outbreak": [2, 3, 4, 5, 6, 7, 8],
}
const PRIVATE_TERMS: PackedStringArray = [
	"bellhouse_archivist",
	"fog_listener",
	"lantern_surveyor",
	"lifeboat_keeper",
	"tide_chapel_warden",
	"wreckers_heir",
	"recover_the_truth",
	"preserve_signal",
	"preserve_harbor_memory",
	"bellmarked",
	"private_objective_id",
	"desirability_score",
]

var _failures: int = 0
var _checks: int = 0
var _request_sequence: int = 0
var _coverage: Dictionary = {
	"roles": {},
	"living_objectives": {},
	"bellmarked_objectives": {},
	"tidebound_objectives": {},
	"continuation_forms": {},
	"items": {},
	"cards": {},
	"resources": {},
	"hazards": {},
	"encounters": {},
	"endings": {},
}


func _initialize() -> void:
	_test_candidate_versions_and_product_boundaries()
	_test_mode_fallbacks_and_director_privacy()
	_test_no_op_rejections_and_deadlock_diagnostic()
	_test_item_rescue_connection_and_private_reprojection()
	_test_alpha2_migration_and_fail_closed_preservation()
	_test_repeated_session_matrix()
	_assert_complete_coverage()
	var summary: Dictionary = {
		"accepted": _failures == 0,
		"check_count": _checks,
		"matrix_run_count": 126,
		"seed_set": Array(MATRIX_SEEDS),
		"repeat_each_case": 2,
		"mode_seat_matrix": MODE_SEATS,
		"maximum_accepted_actions": 192,
		"content_counts":
		{
			"items": DrownedHarborAlpha3RulesAuthority.ITEMS.size(),
			"cards": DrownedHarborAlpha3RulesAuthority.CARDS.size(),
			"resources": DrownedHarborAlpha3RulesAuthority.RESOURCES.size(),
			"hazards": DrownedHarborAlpha3RulesAuthority.HAZARDS.size(),
			"encounters": _encounter_inventory().size(),
			"endings": DrownedHarborAlpha3RulesAuthority.ENDINGS.size(),
		},
		"coverage": _coverage,
		"privacy_term_hit_count": 0,
		"human_evidence_claimed": false,
		"production_ready_claimed": false,
	}
	print(SUMMARY_PREFIX + JSON.stringify(summary, "", true))
	quit(_failures)


func _test_candidate_versions_and_product_boundaries() -> void:
	var provider := DrownedHarborAlpha3ScopedProvider.new()
	var candidate: Dictionary = provider.build_candidate()
	_expect(candidate.get("accepted", false), "complete version-3 candidate validates")
	if not candidate.get("accepted", false):
		return
	_expect(candidate.package.package_version == 3, "package target is version 3")
	_expect(candidate.scenario.scenario_version == 3, "scenario target is version 3")
	_expect(candidate.localization.catalog_version == 3, "localization target is version 3")
	_expect(candidate.provider_version == 3, "provider target is version 3")
	_expect(not provider.build_candidate("rules").accepted, "incomplete candidate fails closed")
	_expect(
		(
			candidate.scenario.inherited_route.stage_order
			== Array(DrownedHarborAlpha2RulesAuthority.STAGE_ORDER)
		),
		"accepted eight-stage route remains exact",
	)
	_expect(
		(
			candidate.scenario.inherited_route.transition_order
			== Array(DrownedHarborAlpha2RulesAuthority.TRANSITION_ORDER)
		),
		"accepted seven-transition route remains exact",
	)
	var registry := TaleProviderRegistry.new()
	_expect(
		not registry.provider_ids().has(DrownedHarborAlpha3ScopedProvider.PROVIDER_ID),
		"central provider registry remains unchanged",
	)
	var catalog_result: Dictionary = TaleCatalog.load_validated(
		TaleCatalog.PRODUCTION_PATH, registry, TaleCatalog.PRODUCTION_DIGEST
	)
	_expect(catalog_result.accepted, "production catalog remains valid")
	_expect(catalog_result.catalog.entries.size() == 1, "normal Tale Library remains one entry")
	_expect(
		catalog_result.default_tale_id == "lantern_house_vertical_slice",
		"Lantern House remains the sole normal default",
	)


func _test_mode_fallbacks_and_director_privacy() -> void:
	for row: Dictionary in [
		{"mode": "hidden_betrayer", "seats": 2, "reason": "hidden_betrayer_requires_three_seats"},
		{"mode": "outbreak", "seats": 1, "reason": "outbreak_requires_two_seats"},
	]:
		var gate := DrownedHarborAlpha3DeveloperAdmission.new()
		_expect(
			gate.admit(_admission_request(3000 + row.seats, row.seats, row.mode)).accepted,
			"fallback admits"
		)
		var roles: Dictionary = gate.active_session().public_projection().roles
		_expect(roles.effective_mode == "cooperative", "unsupported seat plan falls back")
		_expect(roles.fallback_applied, "fallback is publicly recorded")
		_expect(roles.fallback_reason == row.reason, "fallback diagnostic is deterministic")
	var director := DrownedHarborAlpha3DirectorAuthority.new(3101)
	var safe_input: Dictionary = {
		"authoritative_revision": 0,
		"connected_seat_count": 3,
		"stage_id": "low_tide_arrival_v1",
		"tide_state": "low_tide",
		"living_count": 3,
		"restless_count": 0,
		"tidebound_count": 0,
		"unresolved_rescue_count": 0,
		"public_resource_pressure": 0,
		"recent_public_candidate_ids": [],
		"ending_eligibility_count": 7,
	}
	_expect(director.accepts_input(safe_input), "Director accepts exact public aggregate input")
	for forbidden: String in DrownedHarborAlpha3DirectorAuthority.FORBIDDEN_INPUTS:
		var private_input: Dictionary = safe_input.duplicate(true)
		private_input[forbidden] = "forbidden"
		_expect(not director.accepts_input(private_input), "Director rejects %s" % forbidden)
	var before: Dictionary = director.to_snapshot()
	_expect(
		not director.select_candidate(safe_input.merged({"role_id": "forbidden"}), ["a"]).accepted,
		"rejected Director work fails closed",
	)
	_expect(director.to_snapshot() == before, "rejected Director work consumes no RNG")


func _test_no_op_rejections_and_deadlock_diagnostic() -> void:
	var gate := DrownedHarborAlpha3DeveloperAdmission.new()
	_expect(
		gate.admit(_admission_request(3200, 2, "cooperative")).accepted, "rejection session admits"
	)
	var session: DrownedHarborAlpha3Session = gate.active_session()
	var stale: Dictionary = _request(session, "seat_01", "apply_content_turn", {})
	stale.source_revision = 999
	var malformed: Dictionary = _request(session, "seat_01", "apply_content_turn", {})
	malformed.erase("payload")
	var unauthorized: Dictionary = _request(session, "seat_01", "apply_content_turn", {})
	unauthorized.actor = "director"
	for request: Dictionary in [stale, malformed, unauthorized]:
		var before: Dictionary = session.to_snapshot()
		var result: Dictionary = session.process_request(request)
		_expect(not result.accepted, "invalid Alpha.3 request rejects")
		_expect(result.state_and_rng_unchanged, "rejection reports state/RNG no-op")
		_expect(session.to_snapshot() == before, "rejection preserves complete snapshot")
	var diagnostic: Dictionary = {}
	for index: int in 8:
		diagnostic = session.process_request(
			_request(session, "seat_01", "unsupported_system_intent", {"attempt": index})
		)
	_expect(
		diagnostic.diagnostics.any(
			func(row: Dictionary) -> bool: return row.code == "bounded_progress_watchdog"
		),
		"eighth rejection emits actionable bounded diagnostic",
	)
	_assert_shared_safe(diagnostic, "deadlock diagnostic")


func _test_item_rescue_connection_and_private_reprojection() -> void:
	_request_sequence = 0
	var gate := DrownedHarborAlpha3DeveloperAdmission.new()
	_expect(
		gate.admit(_admission_request(3300, 2, "hidden_betrayer")).accepted,
		"continuity session admits"
	)
	var session: DrownedHarborAlpha3Session = gate.active_session()
	var private_before: Dictionary = session.seat_private_projection("seat_01")
	var faction_before: Dictionary = session.faction_private_projection("seat_01")
	var rng_before: Dictionary = {
		"role_seed": session.to_snapshot().role.social_rng_seed,
		"role_state": session.to_snapshot().role.social_rng_state,
		"director": session.to_snapshot().director.duplicate(true),
		"route": session.to_snapshot().route.rng_streams.duplicate(true),
	}
	_expect(session.disconnect_seat("seat_01").accepted, "disconnect accepts")
	_expect(
		session.seat_private_projection("seat_01").is_empty(),
		"disconnect has no private projection"
	)
	_expect(session.assign_surrogate_control("seat_01").accepted, "surrogate control accepts")
	_expect(
		session.seat_private_projection("seat_01").is_empty(),
		"surrogate receives no private projection"
	)
	_expect(session.reconnect_seat("seat_01").accepted, "reconnect accepts")
	_expect(
		session.seat_private_projection("seat_01") == private_before,
		"same stable seat receives same private view"
	)
	_expect(
		session.faction_private_projection("seat_01") == faction_before,
		"faction-private reprojection is stable"
	)
	var rng_after: Dictionary = {
		"role_seed": session.to_snapshot().role.social_rng_seed,
		"role_state": session.to_snapshot().role.social_rng_state,
		"director": session.to_snapshot().director.duplicate(true),
		"route": session.to_snapshot().route.rng_streams.duplicate(true),
	}
	_expect(rng_after == rng_before, "continuity cycle consumes no RNG")
	var transfer_before: Dictionary = (
		session.to_snapshot().rules.items.chapel_salt_censer.duplicate(true)
	)
	var transfer: Dictionary = session.process_request(
		_request(
			session,
			"seat_01",
			"transfer_item",
			{"item_id": "chapel_salt_censer", "to_stable_seat_id": "seat_02"}
		)
	)
	_expect(transfer.accepted, "valid item transfer accepts")
	var transfer_after: Dictionary = session.to_snapshot().rules.items.chapel_salt_censer
	_expect(transfer_after.state == transfer_before.state, "transfer preserves item condition")
	_expect(transfer_after.charges == transfer_before.charges, "transfer preserves item charges")
	_expect(
		transfer_after.ownership_identity == transfer_before.ownership_identity,
		"transfer preserves ownership identity",
	)
	var failed_rescue_before: Dictionary = session.to_snapshot()
	var failed_rescue: Dictionary = session.process_request(
		_request(session, "seat_01", "attempt_rescue", {"target_id": "missing_target"})
	)
	_expect(not failed_rescue.accepted, "unavailable rescue rejects")
	_expect(session.to_snapshot() == failed_rescue_before, "failed rescue is state/RNG no-op")
	var snapshot: Dictionary = session.to_snapshot()
	var restored: Dictionary = DrownedHarborAlpha3Session.restore_candidate(
		DrownedHarborAlpha3ScopedProvider.new().build_candidate(), snapshot
	)
	_expect(restored.accepted, "connection/content snapshot restores")
	if restored.accepted:
		_expect(restored.session.to_snapshot() == snapshot, "restored Alpha.3 snapshot is exact")


func _test_alpha2_migration_and_fail_closed_preservation() -> void:
	var alpha2_gate := DrownedHarborDeveloperAdmissionGate.new()
	var alpha2_request: Dictionary = {
		"request_kind": "developer_only_explicit_launch",
		"developer_mode": true,
		"tale_id": "drowned_harbor",
		"package_kind": "tale",
		"schema_version": 1,
		"package_version": 2,
		"provider_id": "drowned_harbor_authorities_v1",
		"seed": 3400,
		"stable_seat_ids": ["seat_01"],
	}
	_expect(alpha2_gate.admit_alpha2(alpha2_request).accepted, "Alpha.2 migration source admits")
	var alpha2_session: DrownedHarborAlpha2Session = alpha2_gate.active_alpha2_session()
	var sequence: int = 0
	for step: Dictionary in [
		{"intent": "move_to_landmark", "payload": {"destination": "bellhouse"}},
		{"intent": "confirm_low_tide_arrival", "payload": {}},
		{"intent": "inspect_ledger", "payload": {}},
		{"intent": "commit_bellhouse_choice", "payload": {"choice_id": "preserve_public_ledger"}},
		{"intent": "submit_council_commitment", "payload": {"commitment": "hold_the_light"}},
		{"intent": "resolve_council_commitment", "payload": {}},
		{"intent": "acknowledge_high_water", "payload": {}},
		{"intent": "apply_high_water_transformation", "payload": {}},
	]:
		sequence += 1
		var request: Dictionary = {
			"request_id": "migration_alpha2_%d" % sequence,
			"event_id": "migration_alpha2_event_%d" % sequence,
			"actor": "developer_alpha2_gate",
			"stable_seat_id": "seat_01",
			"source_revision": alpha2_session.to_snapshot().authoritative_revision,
			"intent": step.intent,
			"payload": step.payload,
		}
		_expect(
			alpha2_session.process_request(request).accepted, "Alpha.2 migration route advances"
		)
	var source_snapshot: Dictionary = alpha2_session.to_snapshot()
	var alpha3_gate := DrownedHarborAlpha3DeveloperAdmission.new()
	var request_v3: Dictionary = _admission_request(3400, 1, "outbreak")
	var migrated: Dictionary = alpha3_gate.migrate_alpha2_snapshot(request_v3, source_snapshot)
	_expect(migrated.accepted, "supported Alpha.2 snapshot migrates explicitly")
	if migrated.accepted:
		var migrated_snapshot: Dictionary = migrated.session.to_snapshot()
		_expect(migrated_snapshot.snapshot_version == 3, "migration targets snapshot v3")
		_expect(
			migrated_snapshot.migration.from_snapshot_version == 2, "migration receipt records v2"
		)
		_expect(
			(
				migrated_snapshot.exactly_once_identities.council_commitment_id
				== source_snapshot.rules.council_commitment_id
			),
			"Council identity survives migration",
		)
		_expect(
			(
				migrated_snapshot.exactly_once_identities.high_water_transformation_id
				== source_snapshot.rules.high_water_transformation_id
			),
			"High Water identity survives migration",
		)
	var active_before: Dictionary = alpha3_gate.active_session().to_snapshot()
	var malformed: Dictionary = source_snapshot.duplicate(true)
	malformed.provider_id = "unsupported_provider"
	var rejected: Dictionary = alpha3_gate.migrate_alpha2_snapshot(request_v3, malformed)
	_expect(not rejected.accepted, "malformed migration fails closed")
	_expect(
		alpha3_gate.active_session().to_snapshot() == active_before,
		"failed migration preserves active session"
	)


func _test_repeated_session_matrix() -> void:
	var run_count: int = 0
	for seed: int in MATRIX_SEEDS:
		for mode_id: String in MODE_SEATS:
			for seat_count: int in MODE_SEATS[mode_id]:
				var first: Dictionary = _run_case(seed, mode_id, seat_count, true)
				var second: Dictionary = _run_case(seed, mode_id, seat_count, false)
				run_count += 2
				_expect(
					first.accepted and second.accepted,
					"%s %d-seat runs complete" % [mode_id, seat_count]
				)
				if not first.accepted or not second.accepted:
					continue
				_expect(
					(
						_canonical(first.pre_cleanup_snapshot)
						== _canonical(second.pre_cleanup_snapshot)
					),
					"repeated authoritative outcomes are byte-equivalent",
				)
				_expect(
					first.accepted_actions <= 192 and second.accepted_actions <= 192,
					"matrix run stays within 192 accepted actions",
				)
				_expect(
					first.terminal_cleanup and second.terminal_cleanup,
					"matrix run reaches terminal cleanup"
				)
				_expect(first.exact_restore, "governed boundary snapshot restores exactly")
				_expect(first.replay_equivalent, "public history and replay remain equivalent")
				_expect(first.private_term_hit_count == 0, "shared output has no private terms")
				_expect(first.duplicate_no_op, "duplicate delivery is an exact no-op")
	_expect(run_count == 126, "complete replayability matrix executes 126 runs")


func _run_case(seed: int, mode_id: String, seat_count: int, collect_coverage: bool) -> Dictionary:
	_request_sequence = 0
	var gate := DrownedHarborAlpha3DeveloperAdmission.new()
	var admission: Dictionary = gate.admit(_admission_request(seed, seat_count, mode_id))
	if not admission.get("accepted", false):
		return {"accepted": false, "reason": admission.get("reason", "admission_failed")}
	var session: DrownedHarborAlpha3Session = gate.active_session()
	var signal_count: Dictionary = {"count": 0}
	session.public_event_committed.connect(
		func(_event: Dictionary) -> void: signal_count.count += 1
	)
	var sequence_index: int = session.coverage_sequence_index()
	var continuation_case: int = sequence_index % 4
	var steps: Array[Callable] = [
		func() -> String: return _drive_continuation_setup(session, continuation_case),
		func() -> String: return _drive_low_tide(session, seat_count),
		func() -> String: return _drive_bellhouse(session),
		func() -> String: return _drive_council(session, seat_count),
		func() -> String: return _drive_high_water(session, mode_id),
		func() -> String: return _drive_last_light(session, seat_count, continuation_case),
	]
	for step: Callable in steps:
		var failure_reason: String = step.call()
		if not failure_reason.is_empty():
			return _route_failure(session, failure_reason)
	var accepted_identity_request: Dictionary = _request(session, "seat_01", "resolve_ending", {})
	var ending_failure: String = _drive_ending(session, accepted_identity_request)
	if not ending_failure.is_empty():
		return _route_failure(session, ending_failure)
	var pre_cleanup: Dictionary = session.to_snapshot()
	var restore: Dictionary = DrownedHarborAlpha3Session.restore_candidate(
		DrownedHarborAlpha3ScopedProvider.new().build_candidate(), pre_cleanup
	)
	var exact_restore: bool = (
		restore.get("accepted", false) and restore.session.to_snapshot() == pre_cleanup
	)
	var duplicate_before: Dictionary = session.to_snapshot()
	var duplicate: Dictionary = session.process_request(accepted_identity_request)
	var duplicate_no_op: bool = not duplicate.accepted and session.to_snapshot() == duplicate_before
	var shared: Dictionary = session.public_projection()
	var private_term_hit_count: int = _private_term_hit_count(
		[
			shared,
			session.director_safe_input(),
			session.interrupt_presentation(),
			session.reproject_identity("ending_resolution_id")
		]
	)
	var replay_equivalent: bool = (
		pre_cleanup.public_history.size() == pre_cleanup.replay.size()
		and pre_cleanup.public_history.size() == pre_cleanup.transcript.size()
		and pre_cleanup.public_history.size() == pre_cleanup.mirror.size()
	)
	if collect_coverage:
		_collect_coverage(pre_cleanup)
	var accepted_actions: int = pre_cleanup.processed_request_ids.size()
	if not _accept(session, "seat_01", "return_to_title", {}):
		return _route_failure(session, "terminal cleanup failed")
	var terminal_snapshot: Dictionary = session.to_snapshot()
	return {
		"accepted": true,
		"accepted_actions": accepted_actions,
		"pre_cleanup_snapshot": pre_cleanup,
		"terminal_cleanup": terminal_snapshot.cleanup_complete and not terminal_snapshot.active,
		"exact_restore": exact_restore,
		"replay_equivalent": replay_equivalent,
		"private_term_hit_count": private_term_hit_count,
		"duplicate_no_op": duplicate_no_op,
		"signal_count": signal_count.count,
	}


func _drive_continuation_setup(
	session: DrownedHarborAlpha3Session, continuation_case: int
) -> String:
	if continuation_case in [1, 2, 3]:
		if not _accept(session, "seat_01", "consume_lifeboat_route", {}):
			return "lifeboat route consumption failed"
	if continuation_case == 2:
		if not _accept(
			session,
			"seat_01",
			"register_stranded_target",
			{"target_kind": "stable_seat", "target_id": "seat_01"}
		):
			return "stranded target failed"
	if continuation_case != 3:
		if not _accept(session, "seat_01", "apply_defeat_continuation", {}):
			return "continuation failed"
	return ""


func _drive_low_tide(session: DrownedHarborAlpha3Session, seat_count: int) -> String:
	if not _content_and_director(session, "low_tide_arrival_v1", 4):
		return "low-tide systems failed"
	for seat_number: int in range(1, seat_count + 1):
		if not _accept(
			session, "seat_%02d" % seat_number, "move_to_landmark", {"destination": "bellhouse"}
		):
			return "low-tide movement failed"
	if not _accept(session, "seat_01", "confirm_low_tide_arrival", {}):
		return "low-tide completion failed"
	return ""


func _drive_bellhouse(session: DrownedHarborAlpha3Session) -> String:
	if not _content_and_director(session, "bellhouse_ledger_v1", 1):
		return "Bellhouse systems failed"
	if not _accept(session, "seat_01", "inspect_ledger", {}):
		return "ledger inspection failed"
	var failed_choice_before: Dictionary = session.to_snapshot()
	var failed_choice: Dictionary = session.process_request(
		_request(session, "seat_01", "commit_bellhouse_choice", {"choice_id": "unsupported_choice"})
	)
	if failed_choice.get("accepted", false) or session.to_snapshot() != failed_choice_before:
		return "Bellhouse invalid-action recovery mutated"
	if not _accept(
		session, "seat_01", "recover_bellhouse_choice", {"choice_id": "preserve_public_ledger"}
	):
		return "Bellhouse recovery failed"
	return ""


func _drive_council(session: DrownedHarborAlpha3Session, seat_count: int) -> String:
	if not _content_and_director(session, "lighthouse_council_v1", 1):
		return "Council systems failed"
	for seat_number: int in range(1, seat_count + 1):
		if not _accept(
			session,
			"seat_%02d" % seat_number,
			"submit_council_commitment",
			{"commitment": "hold_the_light"}
		):
			return "Council commitment failed"
	if not _accept(session, "seat_01", "resolve_council_commitment", {}):
		return "Council resolution failed"
	return ""


func _drive_high_water(session: DrownedHarborAlpha3Session, mode_id: String) -> String:
	if not _content_and_director(session, "high_water_v1", 1):
		return "High Water systems failed"
	if not _accept(session, "seat_01", "acknowledge_high_water", {}):
		return "High Water acknowledgement failed"
	if not _accept(session, "seat_01", "apply_high_water_transformation", {}):
		return "High Water transformation failed"
	if mode_id == "outbreak" and not _advance_tidebound_conversion(session):
		return "Tidebound conversion failed"
	return ""


func _drive_last_light(
	session: DrownedHarborAlpha3Session, seat_count: int, continuation_case: int
) -> String:
	if not _content_and_director(session, "last_light_v1", 1):
		return "Last Light systems failed"
	if continuation_case == 3:
		if not _accept(session, "seat_01", "apply_defeat_continuation", {}):
			return "Last Light continuation failed"
	for seat_number: int in range(1, seat_count + 1):
		var stable_seat_id: String = "seat_%02d" % seat_number
		if not _accept(
			session,
			stable_seat_id,
			"move_to_last_light_route",
			{"destination": "last_light_beacon"}
		):
			return "Last Light movement failed"
		if not _accept(
			session, stable_seat_id, "commit_last_light_action", {"commitment": "guard_last_light"}
		):
			return "Last Light commitment failed"
	if not _accept(session, "seat_01", "resolve_last_light", {}):
		return "Last Light resolution failed"
	return ""


func _drive_ending(
	session: DrownedHarborAlpha3Session, accepted_identity_request: Dictionary
) -> String:
	if not session.process_request(accepted_identity_request).get("accepted", false):
		return "ending resolution failed"
	if not _accept(session, "seat_01", "resolve_epilogue_attribution", {}):
		return "private attribution failed"
	if not _accept(session, "seat_01", "acknowledge_epilogue", {}):
		return "epilogue acknowledgement failed"
	return ""


func _content_and_director(
	session: DrownedHarborAlpha3Session, expected_stage: String, director_count: int
) -> bool:
	if session.stage_id() != expected_stage:
		return false
	if not _accept(session, "seat_01", "apply_content_turn", {}):
		return false
	for _index: int in director_count:
		if not _accept(session, "seat_01", "select_director_candidate", {}):
			return false
	return true


func _advance_tidebound_conversion(session: DrownedHarborAlpha3Session) -> bool:
	if not _accept(session, "seat_01", "offer_tidebound", {"origin": "authored_exposure"}):
		return false
	if not _accept(session, "seat_01", "refuse_tidebound", {}):
		return false
	if not _accept(session, "seat_01", "offer_tidebound", {"origin": "authored_bargain"}):
		return false
	var conversion_request: Dictionary = _request(session, "seat_01", "resolve_tidebound", {})
	if not session.process_request(conversion_request).accepted:
		return false
	var after: Dictionary = session.to_snapshot()
	var duplicate: Dictionary = session.process_request(conversion_request)
	return not duplicate.accepted and session.to_snapshot() == after


func _collect_coverage(snapshot: Dictionary) -> void:
	for row: Dictionary in snapshot.role.seats.values():
		_coverage.roles[row.role_id] = true
		_coverage.living_objectives[row.private_objective_id] = true
		if not row.faction_objective_id.is_empty():
			_coverage.bellmarked_objectives[row.faction_objective_id] = true
		if not row.tidebound_objective_id.is_empty():
			_coverage.tidebound_objectives[row.tidebound_objective_id] = true
		if not row.continuation_form.is_empty():
			_coverage.continuation_forms[row.continuation_form] = true
	for item_id: String in snapshot.rules.items:
		if snapshot.rules.items[item_id].observed:
			_coverage.items[item_id] = true
	for card_id: String in snapshot.rules.cards:
		if snapshot.rules.cards[card_id].observed:
			_coverage.cards[card_id] = true
	for resource_id: String in snapshot.rules.resources:
		if snapshot.rules.resources[resource_id] < 8:
			_coverage.resources[resource_id] = true
	for hazard_id: String in snapshot.rules.observed_hazards:
		_coverage.hazards[hazard_id] = true
	for encounter_id: String in snapshot.rules.observed_encounters:
		_coverage.encounters[encounter_id] = true
	_coverage.endings[snapshot.rules.ending_id] = true


func _assert_complete_coverage() -> void:
	_expect(
		(
			_sorted_keys(_coverage.roles)
			== _sorted_packed(DrownedHarborAlpha3RoleAuthority.ROLE_ORDER)
		),
		"all six role archetypes are assigned",
	)
	_expect(
		(
			_sorted_keys(_coverage.living_objectives)
			== _sorted_packed(DrownedHarborAlpha3RoleAuthority.LIVING_OBJECTIVES)
		),
		"all Living objective families are assigned",
	)
	_expect(
		(
			_sorted_keys(_coverage.bellmarked_objectives)
			== _sorted_packed(DrownedHarborAlpha3RoleAuthority.BELLMARKED_OBJECTIVES)
		),
		"all Bellmarked objective families are assigned",
	)
	_expect(
		(
			_sorted_keys(_coverage.tidebound_objectives)
			== _sorted_packed(DrownedHarborAlpha3RoleAuthority.TIDEBOUND_OBJECTIVES)
		),
		"all Tidebound objective families are assigned",
	)
	_expect(
		(
			_sorted_keys(_coverage.continuation_forms)
			== ["bell_witness", "drowned_guide", "lifeboat_survivor", "lighthouse_guardian"]
		),
		"all continuation forms are reached through authority",
	)
	_expect(
		_sorted_keys(_coverage.items) == _sorted_packed(DrownedHarborAlpha3RulesAuthority.ITEMS),
		"all twelve items are observed",
	)
	_expect(
		_sorted_keys(_coverage.cards) == _sorted_packed(DrownedHarborAlpha3RulesAuthority.CARDS),
		"all twelve cards are observed",
	)
	_expect(
		(
			_sorted_keys(_coverage.resources)
			== _sorted_packed(DrownedHarborAlpha3RulesAuthority.RESOURCES)
		),
		"all eight resources are exercised",
	)
	_expect(
		(
			_sorted_keys(_coverage.hazards)
			== _sorted_packed(DrownedHarborAlpha3RulesAuthority.HAZARDS)
		),
		"all twelve hazards are observed",
	)
	_expect(
		_sorted_keys(_coverage.encounters) == _encounter_inventory(),
		"all nineteen encounters are observed",
	)
	_expect(
		(
			_sorted_keys(_coverage.endings)
			== _sorted_packed(DrownedHarborAlpha3RulesAuthority.ENDINGS)
		),
		"all seven endings are reached",
	)


func _accept(
	session: DrownedHarborAlpha3Session, stable_seat_id: String, intent: String, payload: Dictionary
) -> bool:
	return session.process_request(_request(session, stable_seat_id, intent, payload)).get(
		"accepted", false
	)


func _request(
	session: DrownedHarborAlpha3Session, stable_seat_id: String, intent: String, payload: Dictionary
) -> Dictionary:
	_request_sequence += 1
	return {
		"request_id": "alpha3_request_%08d" % _request_sequence,
		"event_id": "alpha3_event_%08d" % _request_sequence,
		"actor": "developer_alpha3_gate",
		"stable_seat_id": stable_seat_id,
		"source_revision": session.to_snapshot().authoritative_revision,
		"intent": intent,
		"payload": payload.duplicate(true),
	}


func _admission_request(seed: int, seat_count: int, mode_id: String) -> Dictionary:
	var seats: Array[String] = []
	for seat_number: int in range(1, seat_count + 1):
		seats.append("seat_%02d" % seat_number)
	return {
		"request_kind": "developer_only_explicit_launch",
		"developer_mode": true,
		"tale_id": "drowned_harbor",
		"package_kind": "tale",
		"schema_version": 1,
		"package_version": 3,
		"provider_id": "drowned_harbor_authorities_v1",
		"provider_version": 3,
		"mode_id": mode_id,
		"seed": seed,
		"stable_seat_ids": seats,
	}


func _assert_shared_safe(value: Variant, label: String) -> void:
	_expect(_private_term_hit_count([value]) == 0, "%s contains no private term" % label)


func _private_term_hit_count(values: Array) -> int:
	var serialized: String = _canonical(values).to_lower()
	var result: int = 0
	for term: String in PRIVATE_TERMS:
		if term.to_lower() in serialized:
			result += 1
	return result


func _encounter_inventory() -> Array:
	var result: Array = []
	for stage_id: String in DrownedHarborAlpha3RulesAuthority.ENCOUNTERS_BY_STAGE:
		result.append_array(DrownedHarborAlpha3RulesAuthority.ENCOUNTERS_BY_STAGE[stage_id])
	result.sort()
	return result


func _sorted_keys(value: Dictionary) -> Array:
	var result: Array = value.keys()
	result.sort()
	return result


func _sorted_packed(value: PackedStringArray) -> Array:
	var result: Array = Array(value)
	result.sort()
	return result


func _route_failure(session: DrownedHarborAlpha3Session, reason: String) -> Dictionary:
	return {
		"accepted": false,
		"reason": reason,
		"stage_id": session.stage_id(),
		"revision": session.to_snapshot().authoritative_revision,
	}


func _canonical(value: Variant) -> String:
	return JSON.stringify(TalePackage.canonicalize(value))


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("PASS: ", message)
		return
	_failures += 1
	push_error("FAILED: %s" % message)
