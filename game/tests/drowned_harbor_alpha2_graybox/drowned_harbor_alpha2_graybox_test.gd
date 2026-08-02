extends SceneTree

const SUMMARY_PREFIX: String = "DROWNED_HARBOR_ALPHA2_GRAYBOX_EVIDENCE:"
const SEMANTIC_PROJECTION_PREFIX: String = "DROWNED_HARBOR_ALPHA2_SEMANTIC_PROJECTION_EVIDENCE:"
const EXPECTED_PACKAGE_DIGEST: String = (
	"ee9e2f21b23f2b8f7ac8c8be1520c6e" + "bcb679807a5f0dbd0d23825824b2f90b7"
)
const EXPECTED_SCENARIO_DIGEST: String = (
	"5927dba92238512fdc74b10387ea7378" + "f00d74a462445749d6493a512b7d7a0d"
)
const EXPECTED_LOCALIZATION_DIGEST: String = (
	"137919b02a572fc1c844521c38633bf2" + "7ad49bcb9d1fe8a83147db2210d1a227"
)

var _failures: int = 0
var _checks: int = 0
var _request_sequence: int = 0
var _semantic_projection_evidence: Dictionary = {}


func _initialize() -> void:
	_test_candidate_identity_and_boundaries()
	_test_semantic_commitment_projection_privacy()
	_test_deterministic_safe_routes_for_seats_one_through_eight()
	_test_no_op_rejections_and_deadlock_diagnostic()
	_test_stage_boundary_restore_and_replay_equivalence()
	_test_disconnect_surrogate_and_reconnect_continuity()
	_test_interruption_projection_recovery_and_exactly_once()
	_test_alpha1_snapshot_migration_and_fail_closed_rejection()
	_test_rematch_rollback_and_title_cleanup()
	var summary: Dictionary = {
		"accepted": _failures == 0,
		"check_count": _checks,
		"seat_counts": range(1, 9),
		"stage_count": DrownedHarborAlpha2RulesAuthority.STAGE_ORDER.size(),
		"transition_count": DrownedHarborAlpha2RulesAuthority.TRANSITION_ORDER.size(),
		"package_digest": EXPECTED_PACKAGE_DIGEST,
		"scenario_digest": EXPECTED_SCENARIO_DIGEST,
		"localization_digest": EXPECTED_LOCALIZATION_DIGEST,
		"snapshot_version": 2,
		"human_evidence_claimed": false,
		"production_ready_claimed": false,
	}
	print(SEMANTIC_PROJECTION_PREFIX + JSON.stringify(_semantic_projection_evidence, "", true))
	print(SUMMARY_PREFIX + JSON.stringify(summary, "", true))
	quit(_failures)


func _test_candidate_identity_and_boundaries() -> void:
	var provider := DrownedHarborAlpha2ScopedProvider.new()
	var candidate: Dictionary = provider.build_candidate()
	_expect(candidate.get("accepted", false), "complete alpha.2 candidate validates")
	if not candidate.get("accepted", false):
		return
	_expect(candidate.package_digest == EXPECTED_PACKAGE_DIGEST, "package v2 canonical identity")
	_expect(
		FileAccess.get_sha256(provider.SCENARIO_PATH) == EXPECTED_SCENARIO_DIGEST,
		"scenario v2 raw identity",
	)
	_expect(
		FileAccess.get_sha256(provider.LOCALIZATION_PATH) == EXPECTED_LOCALIZATION_DIGEST,
		"localization v2 raw identity",
	)
	_expect(
		candidate.scenario.stage_order == Array(DrownedHarborAlpha2RulesAuthority.STAGE_ORDER),
		"exact eight-stage order",
	)
	_expect(candidate.scenario.transitions.size() == 7, "exact seven-transition inventory")
	_expect(candidate.board_definition is BoardDefinition, "BoardState definition authority")
	_expect(candidate.rules_authority is DrownedHarborAlpha2RulesAuthority, "RulesSession owner")
	_expect(candidate.role_authority is DrownedHarborAlpha2RoleAuthority, "RoleSession owner")
	var safe_input: Dictionary = {
		"authoritative_revision": 0,
		"connected_seat_count": 2,
		"stage_id": "low_tide_arrival_v1",
		"public_progress": 0,
		"public_pressure": 0,
		"public_recovery_count": 0,
	}
	_expect(
		candidate.director_content.accepts_input(safe_input), "Director accepts exact public input"
	)
	var private_input: Dictionary = safe_input.duplicate(true)
	private_input.seat_private = "PRIVATE_FORBIDDEN"
	_expect(
		not candidate.director_content.accepts_input(private_input),
		"Director rejects private input"
	)
	_expect(
		not provider.build_candidate("board").get("accepted", false),
		"incomplete candidate rejects before session commit",
	)
	var registry := TaleProviderRegistry.new()
	_expect(
		not registry.provider_ids().has(DrownedHarborAlpha2ScopedProvider.PROVIDER_ID),
		"central provider registry remains unchanged",
	)
	var catalog_result: Dictionary = TaleCatalog.load_validated(
		TaleCatalog.PRODUCTION_PATH, registry, TaleCatalog.PRODUCTION_DIGEST
	)
	_expect(catalog_result.get("accepted", false), "production catalog remains valid")
	_expect(catalog_result.catalog.entries.size() == 1, "normal Tale Library remains one entry")
	_expect(
		catalog_result.default_tale_id == "lantern_house_vertical_slice",
		"Lantern House remains the normal default",
	)


func _test_deterministic_safe_routes_for_seats_one_through_eight() -> void:
	for seat_count: int in range(1, 9):
		var first: Dictionary = _run_route(seat_count, 7000 + seat_count)
		var second: Dictionary = _run_route(seat_count, 7000 + seat_count)
		_expect(first.accepted and second.accepted, "%d-seat route completes" % seat_count)
		if not first.accepted or not second.accepted:
			continue
		_expect(
			_canonical(first.final_projection) == _canonical(second.final_projection),
			"%d-seat repeated route is byte-equivalent" % seat_count,
		)
		_expect(
			first.accepted_actions <= 96, "%d-seat route stays within action bound" % seat_count
		)
		_expect(first.signal_count == 8, "%d-seat route emits eight stage events" % seat_count)
		_expect(
			first.public_event_count == 8, "%d-seat route records eight public events" % seat_count
		)
		_expect(first.transition_count == 7, "%d-seat route records seven transitions" % seat_count)
		_expect(
			first.council_commitment_id.length() == 64,
			"%d-seat Council identity is persisted SHA-256" % seat_count,
		)
		_expect(
			first.high_water_transformation_id.length() == 64,
			"%d-seat High Water identity is persisted SHA-256" % seat_count,
		)
		_expect(
			first.rng_before == first.rng_after_route, "%d-seat route consumes no RNG" % seat_count
		)
		_expect(
			"PRIVATE_" not in _canonical(first.final_projection),
			"%d-seat public output excludes private markers" % seat_count,
		)


func _test_semantic_commitment_projection_privacy() -> void:
	_request_sequence = 0
	var gate := DrownedHarborDeveloperAdmissionGate.new()
	_expect(gate.admit_alpha2(_admission_request(7100, 2)).accepted, "semantic session admits")
	var session: DrownedHarborAlpha2Session = gate.active_alpha2_session()
	_expect(_advance_low_tide(session, 2), "semantic route reaches Bellhouse")
	_expect(_advance_bellhouse(session), "semantic route reaches Council")
	_expect(session.to_snapshot().stage_id == "lighthouse_council_v1", "Council stage is live")
	_expect(
		_accept(session, "seat_01", "submit_council_commitment", {"commitment": "hold_the_light"}),
		"first Council commitment accepts",
	)
	var council_partial: Dictionary = session.public_projection().rules.stage_state
	_expect(not council_partial.has("commitments"), "Council partial projection omits commitments")
	_expect("seat_01" not in _canonical(council_partial), "Council partial has no seat mapping")
	_expect(council_partial.committed_seat_count == 1, "Council partial committed count")
	_expect(council_partial.required_seat_count == 2, "Council partial required count")
	_expect(not council_partial.commitments_complete, "Council partial remains incomplete")
	var shared_samples: Array[Variant] = _shared_projection_samples(session)
	_assert_semantic_commitment_terms_absent(shared_samples, "Council partial")
	_expect(
		_accept(session, "seat_02", "submit_council_commitment", {"commitment": "hold_the_light"}),
		"second Council commitment accepts",
	)
	var council_complete: Dictionary = session.public_projection().rules.stage_state
	_expect(
		not council_complete.has("commitments"), "Council complete projection omits commitments"
	)
	_expect("seat_02" not in _canonical(council_complete), "Council complete has no seat mapping")
	_expect(council_complete.committed_seat_count == 2, "Council complete committed count")
	_expect(council_complete.required_seat_count == 2, "Council complete required count")
	_expect(council_complete.commitments_complete, "Council completion is deterministic")
	shared_samples.append_array(_shared_projection_samples(session))
	_assert_semantic_commitment_terms_absent(shared_samples, "Council complete")
	_expect(
		_accept(session, "seat_01", "resolve_council_commitment", {}),
		"Council resolution accepts",
	)
	var council_reprojection: Dictionary = session.reproject_committed_result(
		"council_commitment_id"
	)
	_expect(council_reprojection.accepted, "Council committed result reprojects")
	_assert_semantic_commitment_terms_absent([council_reprojection], "Council reprojection")
	shared_samples.append(council_reprojection)
	_expect(_advance_high_water(session), "semantic route reaches Last Light")
	var high_water_reprojection: Dictionary = session.reproject_committed_result(
		"high_water_transformation_id"
	)
	_expect(high_water_reprojection.accepted, "High Water committed result reprojects")
	_assert_semantic_commitment_terms_absent([high_water_reprojection], "High Water reprojection")
	shared_samples.append(high_water_reprojection)
	_expect(
		_accept(
			session, "seat_01", "move_to_last_light_route", {"destination": "last_light_beacon"}
		),
		"first Last Light movement accepts",
	)
	_expect(
		_accept(session, "seat_01", "commit_last_light_action", {"commitment": "guard_last_light"}),
		"first Last Light commitment accepts",
	)
	var last_light_partial: Dictionary = session.public_projection().rules.stage_state
	_expect(not last_light_partial.has("commitments"), "Last Light partial omits commitments")
	_expect(
		"seat_01" not in _canonical(last_light_partial), "Last Light partial has no seat mapping"
	)
	_expect(last_light_partial.moved_seat_count == 1, "Last Light partial movement count")
	_expect(last_light_partial.committed_seat_count == 1, "Last Light partial commitment count")
	_expect(last_light_partial.required_seat_count == 2, "Last Light partial required count")
	_expect(not last_light_partial.movement_complete, "Last Light movement remains incomplete")
	_expect(not last_light_partial.commitments_complete, "Last Light commitments remain incomplete")
	_expect(not last_light_partial.resolution_complete, "Last Light remains unresolved")
	shared_samples.append_array(_shared_projection_samples(session))
	_assert_semantic_commitment_terms_absent(shared_samples, "Last Light partial")
	_expect(
		_accept(
			session, "seat_02", "move_to_last_light_route", {"destination": "last_light_beacon"}
		),
		"second Last Light movement accepts",
	)
	_expect(
		_accept(session, "seat_02", "commit_last_light_action", {"commitment": "guard_last_light"}),
		"second Last Light commitment accepts",
	)
	var last_light_complete: Dictionary = session.public_projection().rules.stage_state
	_expect(not last_light_complete.has("commitments"), "Last Light complete omits commitments")
	_expect(
		"seat_02" not in _canonical(last_light_complete), "Last Light complete has no seat mapping"
	)
	_expect(last_light_complete.moved_seat_count == 2, "Last Light complete movement count")
	_expect(last_light_complete.committed_seat_count == 2, "Last Light complete commitment count")
	_expect(last_light_complete.required_seat_count == 2, "Last Light complete required count")
	_expect(
		last_light_complete.movement_complete, "Last Light movement completion is deterministic"
	)
	_expect(
		last_light_complete.commitments_complete,
		"Last Light commitment completion is deterministic",
	)
	_expect(not last_light_complete.resolution_complete, "Last Light awaits public resolution")
	shared_samples.append_array(_shared_projection_samples(session))
	_assert_semantic_commitment_terms_absent(shared_samples, "Last Light complete")
	_expect(_accept(session, "seat_01", "resolve_last_light", {}), "Last Light resolution accepts")
	shared_samples.append_array(_shared_projection_samples(session))
	_assert_semantic_commitment_terms_absent(shared_samples, "Last Light resolved")
	var semantic_private_term_hit_count: int = _semantic_commitment_term_hit_count(shared_samples)
	_expect(
		semantic_private_term_hit_count == 0, "all shared channels have zero semantic term hits"
	)
	_semantic_projection_evidence = {
		"accepted": semantic_private_term_hit_count == 0,
		"council_partial": council_partial.duplicate(true),
		"council_complete": council_complete.duplicate(true),
		"last_light_partial": last_light_partial.duplicate(true),
		"last_light_complete": last_light_complete.duplicate(true),
		"semantic_private_term_hit_count": semantic_private_term_hit_count,
		"shared_channel_inventory":
		[
			"public_projection",
			"director_safe_input",
			"public_history",
			"replay",
			"transcript",
			"mirror",
			"interruption_recap",
			"committed_result_reprojection",
		],
		"human_evidence_claimed": false,
	}


func _test_no_op_rejections_and_deadlock_diagnostic() -> void:
	var gate := DrownedHarborDeveloperAdmissionGate.new()
	_expect(gate.admit_alpha2(_admission_request(7200, 2)).accepted, "rejection session admits")
	var session: DrownedHarborAlpha2Session = gate.active_alpha2_session()
	var malformed: Dictionary = _request(session, "seat_01", "move_to_landmark", {})
	malformed.erase("payload")
	var cases: Array[Dictionary] = [malformed]
	var stale: Dictionary = _request(
		session, "seat_01", "move_to_landmark", {"destination": "bellhouse"}
	)
	stale.source_revision = 99
	cases.append(stale)
	var actor: Dictionary = _request(
		session, "seat_01", "move_to_landmark", {"destination": "bellhouse"}
	)
	actor.actor = "director"
	cases.append(actor)
	var seat: Dictionary = _request(
		session, "seat_99", "move_to_landmark", {"destination": "bellhouse"}
	)
	cases.append(seat)
	var unsupported: Dictionary = _request(session, "seat_01", "resolve_ending", {})
	cases.append(unsupported)
	for request: Dictionary in cases:
		var before: Dictionary = session.to_snapshot()
		var result: Dictionary = session.process_request(request)
		_expect(not result.get("accepted", false), "invalid request rejects")
		_expect(result.get("state_and_rng_unchanged", false), "rejection reports state/RNG no-op")
		_expect(session.to_snapshot() == before, "rejection preserves complete snapshot")
	var diagnostic: Dictionary
	for index: int in 8:
		diagnostic = session.process_request(
			_request(session, "seat_01", "resolve_ending", {"attempt": index})
		)
	_expect(
		diagnostic.diagnostics.any(
			func(row: Dictionary) -> bool: return row.code == "bounded_progress_watchdog"
		),
		"eighth rejection returns actionable deadlock diagnostic",
	)
	_expect("PRIVATE_" not in _canonical(diagnostic), "diagnostics remain public-safe")


func _test_stage_boundary_restore_and_replay_equivalence() -> void:
	var evidence: Dictionary = _run_route(3, 7300, true)
	_expect(evidence.accepted, "checkpoint capture route completes")
	if not evidence.accepted:
		return
	var provider := DrownedHarborAlpha2ScopedProvider.new()
	var candidate: Dictionary = provider.build_candidate()
	for snapshot: Dictionary in evidence.stage_snapshots:
		var restored: Dictionary = DrownedHarborAlpha2Session.restore_candidate(candidate, snapshot)
		_expect(restored.get("accepted", false), "stage-boundary snapshot restores")
		if restored.get("accepted", false):
			_expect(restored.session.to_snapshot() == snapshot, "stage restore is byte-equivalent")
	var replay_a: Dictionary = _run_route(3, 7310)
	var replay_b: Dictionary = _run_route(3, 7310)
	_expect(
		(
			_canonical(replay_a.final_projection.replay)
			== _canonical(replay_b.final_projection.replay)
		),
		"equal inputs and seed produce replay-equivalent output",
	)
	_expect(
		(
			(
				replay_a.final_projection.public_history.size()
				== replay_a.final_projection.transcript.size()
			)
			and (
				replay_a.final_projection.public_history.size()
				== replay_a.final_projection.mirror.size()
			)
		),
		"public history, replay, transcript, and mirror cardinality agree",
	)


func _test_disconnect_surrogate_and_reconnect_continuity() -> void:
	var gate := DrownedHarborDeveloperAdmissionGate.new()
	_expect(gate.admit_alpha2(_admission_request(7400, 4)).accepted, "continuity session admits")
	var session: DrownedHarborAlpha2Session = gate.active_alpha2_session()
	for seat_number: int in range(1, 5):
		_expect(
			(
				session
				. process_request(
					_request(
						session,
						"seat_%02d" % seat_number,
						"move_to_landmark",
						{"destination": "bellhouse"}
					)
				)
				. accepted
			),
			"seat movement before disconnect accepts",
		)
	var position_before: String = _seat_public(session, "seat_02").space_id
	var rng_before: Dictionary = session.to_snapshot().rng_streams
	_expect(session.disconnect_seat("seat_02").accepted, "disconnect accepts")
	_expect(session.assign_surrogate_control("seat_02").accepted, "surrogate control accepts")
	_expect(session.reconnect_seat("seat_02").accepted, "reconnect accepts")
	var seat_after: Dictionary = _seat_public(session, "seat_02")
	_expect(
		seat_after.space_id == position_before, "stable-seat position survives continuity cycle"
	)
	_expect(seat_after.public_form == "harbor_arrival", "public form survives continuity cycle")
	_expect(seat_after.control_source == "local_human", "human control returns to same stable seat")
	_expect(session.to_snapshot().rng_streams == rng_before, "continuity cycle consumes no RNG")
	var snapshot: Dictionary = session.to_snapshot()
	var restored: Dictionary = DrownedHarborAlpha2Session.restore_candidate(
		DrownedHarborAlpha2ScopedProvider.new().build_candidate(), snapshot
	)
	_expect(restored.get("accepted", false), "post-reconnect snapshot restores")
	_expect(restored.session.to_snapshot() == snapshot, "post-reconnect restore is exact")


func _test_interruption_projection_recovery_and_exactly_once() -> void:
	var gate := DrownedHarborDeveloperAdmissionGate.new()
	_expect(gate.admit_alpha2(_admission_request(7500, 1)).accepted, "recovery session admits")
	var session: DrownedHarborAlpha2Session = gate.active_alpha2_session()
	var failure_before: Dictionary = session.to_snapshot()
	_expect(
		not session.simulate_projection_failure().accepted, "pre-commit projection failure rejects"
	)
	_expect(session.to_snapshot() == failure_before, "pre-commit failure commits nothing")
	var interruption: Dictionary = session.interrupt_presentation()
	_expect(interruption.accepted, "pre-commit caption interruption is public-safe")
	_expect(session.to_snapshot() == failure_before, "pre-commit interruption commits nothing")
	var route: Dictionary = _advance_to_cleanup_stage(session, 1, true)
	_expect(route.accepted, "recovery route reaches cleanup stage")
	if not route.accepted:
		return
	var committed_before: Dictionary = session.to_snapshot()
	_expect(session.interrupt_presentation().accepted, "post-commit interruption returns recap")
	_expect(
		session.to_snapshot() == committed_before, "post-commit interruption preserves authority"
	)
	_expect(
		not session.simulate_projection_failure().accepted, "post-commit projection failure reports"
	)
	_expect(
		session.to_snapshot() == committed_before, "post-commit failure preserves committed result"
	)
	_expect(
		session.reproject_committed_result("council_commitment_id").accepted,
		"Council duplicate request reprojects existing identity",
	)
	_expect(
		session.reproject_committed_result("high_water_transformation_id").accepted,
		"High Water recovery reprojects existing identity",
	)
	_expect(session.to_snapshot() == committed_before, "reprojection adds no duplicate evidence")
	_expect(
		(
			committed_before.public_history.size() == 7
			and committed_before.replay.size() == 7
			and committed_before.transcript.size() == 7
			and committed_before.mirror.size() == 7
		),
		"seven pre-cleanup events remain exactly once",
	)
	_expect(
		(
			committed_before.rules.council_commitment_id.length() == 64
			and committed_before.rules.high_water_transformation_id.length() == 64
		),
		"Council and High Water identities survive all recovery paths",
	)
	_expect(
		"PRIVATE_" not in _canonical(session.public_projection()), "recap has no private marker"
	)


func _test_alpha1_snapshot_migration_and_fail_closed_rejection() -> void:
	var alpha1_gate := DrownedHarborDeveloperAdmissionGate.new()
	var alpha1_request: Dictionary = _admission_request(7600, 2)
	alpha1_request.package_version = 1
	_expect(alpha1_gate.admit(alpha1_request).accepted, "alpha.1 source snapshot admits")
	var alpha1_snapshot: Dictionary = alpha1_gate.active_session().to_snapshot()
	var alpha2_gate := DrownedHarborDeveloperAdmissionGate.new()
	var migrated: Dictionary = alpha2_gate.migrate_alpha1_snapshot_to_alpha2(
		_admission_request(7600, 2), alpha1_snapshot
	)
	_expect(migrated.get("accepted", false), "supported alpha.1 snapshot migrates explicitly")
	if migrated.get("accepted", false):
		var snapshot: Dictionary = migrated.session.to_snapshot()
		_expect(snapshot.snapshot_version == 2, "migration targets snapshot v2")
		_expect(snapshot.migration.from_snapshot_version == 1, "migration receipt records v1")
		_expect(snapshot.stage_id == "low_tide_arrival_v1", "migration enters governed route")
	var malformed: Dictionary = alpha1_snapshot.duplicate(true)
	malformed.tale_id = "unknown_tale"
	var before_active: bool = alpha2_gate.has_active_alpha2()
	var rejected: Dictionary = alpha2_gate.migrate_alpha1_snapshot_to_alpha2(
		_admission_request(7600, 2), malformed
	)
	_expect(not rejected.get("accepted", false), "unsupported migration fails closed")
	_expect(
		alpha2_gate.has_active_alpha2() == before_active, "failed migration preserves prior session"
	)


func _test_rematch_rollback_and_title_cleanup() -> void:
	var rematch_gate := DrownedHarborDeveloperAdmissionGate.new()
	_expect(
		rematch_gate.admit_alpha2(_admission_request(7700, 1)).accepted, "rematch session admits"
	)
	var rematch_session: DrownedHarborAlpha2Session = rematch_gate.active_alpha2_session()
	_expect(_advance_to_cleanup_stage(rematch_session, 1).accepted, "rematch route reaches cleanup")
	var rematch_request: Dictionary = _request(rematch_session, "seat_01", "request_rematch", {})
	var rematch: Dictionary = rematch_gate.rematch_alpha2(rematch_request)
	_expect(rematch.get("accepted", false), "rematch rebuilds through scoped provider")
	if rematch.get("accepted", false):
		_expect(rematch.session.to_snapshot().authoritative_revision == 0, "rematch is fresh")
		_expect(
			rematch.session.to_snapshot().processed_request_ids.is_empty(), "rematch clears IDs"
		)
	_expect(
		rematch_gate.rollback_alpha2().selected_tale_id == "lantern_house_vertical_slice",
		"rollback returns normal default",
	)
	_expect(not rematch_gate.has_active_alpha2(), "rollback clears alpha.2 authority")
	var exit_gate := DrownedHarborDeveloperAdmissionGate.new()
	_expect(
		exit_gate.admit_alpha2(_admission_request(7710, 1)).accepted, "title-exit session admits"
	)
	var exit_session: DrownedHarborAlpha2Session = exit_gate.active_alpha2_session()
	_expect(_advance_to_cleanup_stage(exit_session, 1).accepted, "title-exit reaches cleanup")
	var exit_request: Dictionary = _request(exit_session, "seat_01", "return_to_title", {})
	var exit: Dictionary = exit_gate.exit_alpha2_to_normal_default(exit_request)
	_expect(exit.get("accepted", false), "title cleanup accepts")
	_expect(
		exit.selected_tale_id == "lantern_house_vertical_slice", "title exit selects normal default"
	)
	_expect(not exit_gate.has_active_alpha2(), "title exit clears all scoped authority")


func _run_route(seat_count: int, seed: int, capture_snapshots: bool = false) -> Dictionary:
	_request_sequence = 0
	var gate := DrownedHarborDeveloperAdmissionGate.new()
	var admission: Dictionary = gate.admit_alpha2(_admission_request(seed, seat_count))
	if not admission.get("accepted", false):
		return {"accepted": false, "reason": admission.get("reason", "admission_failed")}
	var session: DrownedHarborAlpha2Session = gate.active_alpha2_session()
	var signal_counter: Dictionary = {"count": 0}
	session.public_event_committed.connect(
		func(_event: Dictionary) -> void: signal_counter.count += 1
	)
	var rng_before: Dictionary = session.to_snapshot().rng_streams
	var route: Dictionary = _advance_to_cleanup_stage(session, seat_count, capture_snapshots)
	if not route.get("accepted", false):
		return route
	var before_cleanup: Dictionary = session.to_snapshot()
	var cleanup: Dictionary = session.process_request(
		_request(session, "seat_01", "return_to_title", {})
	)
	if not cleanup.get("accepted", false):
		return {"accepted": false, "reason": cleanup.get("reason", "cleanup_failed")}
	var final_snapshot: Dictionary = session.to_snapshot()
	return {
		"accepted": true,
		"accepted_actions": before_cleanup.rules.accepted_action_count + 1,
		"signal_count": signal_counter.count,
		"public_event_count": final_snapshot.public_history.size(),
		"transition_count": before_cleanup.rules.transition_history.size(),
		"council_commitment_id": before_cleanup.rules.council_commitment_id,
		"high_water_transformation_id": before_cleanup.rules.high_water_transformation_id,
		"rng_before": rng_before,
		"rng_after_route": before_cleanup.rng_streams,
		"stage_snapshots": route.stage_snapshots,
		"final_projection": session.public_projection(),
	}


func _advance_to_cleanup_stage(
	session: DrownedHarborAlpha2Session, seat_count: int, capture_snapshots: bool = false
) -> Dictionary:
	var snapshots: Array[Dictionary] = []
	var stage_steps: Array[Callable] = [
		_advance_low_tide.bind(session, seat_count),
		_advance_bellhouse.bind(session),
		_advance_council.bind(session, seat_count),
		_advance_high_water.bind(session),
		_advance_last_light.bind(session, seat_count),
		_advance_ending.bind(session),
		_advance_epilogue.bind(session),
	]
	for stage_step: Callable in stage_steps:
		if not stage_step.call():
			return _route_failure(session)
		_capture(snapshots, session, capture_snapshots)
	return {"accepted": true, "stage_snapshots": snapshots}


func _advance_low_tide(session: DrownedHarborAlpha2Session, seat_count: int) -> bool:
	for seat_number: int in range(1, seat_count + 1):
		if not _accept(
			session, "seat_%02d" % seat_number, "move_to_landmark", {"destination": "bellhouse"}
		):
			return false
	return _accept(session, "seat_01", "confirm_low_tide_arrival", {})


func _advance_bellhouse(session: DrownedHarborAlpha2Session) -> bool:
	if not _accept(session, "seat_01", "inspect_ledger", {}):
		return false
	var failed_choice: Dictionary = _request(
		session, "seat_01", "commit_bellhouse_choice", {"choice_id": "unknown"}
	)
	var before_failed_choice: Dictionary = session.to_snapshot()
	var failed_result: Dictionary = session.process_request(failed_choice)
	if failed_result.get("accepted", false) or session.to_snapshot() != before_failed_choice:
		return false
	return _accept(
		session, "seat_01", "recover_bellhouse_choice", {"choice_id": "preserve_public_ledger"}
	)


func _advance_council(session: DrownedHarborAlpha2Session, seat_count: int) -> bool:
	for seat_number: int in range(1, seat_count + 1):
		if not _accept(
			session,
			"seat_%02d" % seat_number,
			"submit_council_commitment",
			{"commitment": "hold_the_light"}
		):
			return false
	var council_request: Dictionary = _request(session, "seat_01", "resolve_council_commitment", {})
	if not session.process_request(council_request).get("accepted", false):
		return false
	var after_council: Dictionary = session.to_snapshot()
	var duplicate_council: Dictionary = session.process_request(council_request)
	return not duplicate_council.get("accepted", false) and session.to_snapshot() == after_council


func _advance_high_water(session: DrownedHarborAlpha2Session) -> bool:
	if not _accept(session, "seat_01", "acknowledge_high_water", {}):
		return false
	var before_high_water: Dictionary = session.to_snapshot()
	if before_high_water.board.tide_state != "low_tide":
		return false
	var high_request: Dictionary = _request(
		session, "seat_01", "apply_high_water_transformation", {}
	)
	if not session.process_request(high_request).get("accepted", false):
		return false
	var after_high_water: Dictionary = session.to_snapshot()
	if after_high_water.board.tide_state != "high_water":
		return false
	var duplicate_high: Dictionary = session.process_request(high_request)
	return not duplicate_high.get("accepted", false) and session.to_snapshot() == after_high_water


func _advance_last_light(session: DrownedHarborAlpha2Session, seat_count: int) -> bool:
	for seat_number: int in range(1, seat_count + 1):
		var stable_seat_id: String = "seat_%02d" % seat_number
		if not _accept(
			session,
			stable_seat_id,
			"move_to_last_light_route",
			{"destination": "last_light_beacon"}
		):
			return false
		if not _accept(
			session, stable_seat_id, "commit_last_light_action", {"commitment": "guard_last_light"}
		):
			return false
	return _accept(session, "seat_01", "resolve_last_light", {})


func _advance_ending(session: DrownedHarborAlpha2Session) -> bool:
	return _accept(session, "seat_01", "resolve_ending", {})


func _advance_epilogue(session: DrownedHarborAlpha2Session) -> bool:
	if not _accept(session, "seat_01", "resolve_epilogue_attribution", {}):
		return false
	return _accept(session, "seat_01", "acknowledge_epilogue", {})


func _accept(
	session: DrownedHarborAlpha2Session, stable_seat_id: String, intent: String, payload: Dictionary
) -> bool:
	return session.process_request(_request(session, stable_seat_id, intent, payload)).get(
		"accepted", false
	)


func _request(
	session: DrownedHarborAlpha2Session, stable_seat_id: String, intent: String, payload: Dictionary
) -> Dictionary:
	_request_sequence += 1
	return {
		"request_id": "alpha2_request_%06d" % _request_sequence,
		"event_id": "alpha2_delivery_%06d" % _request_sequence,
		"actor": "developer_alpha2_gate",
		"stable_seat_id": stable_seat_id,
		"source_revision": session.to_snapshot().authoritative_revision,
		"intent": intent,
		"payload": payload.duplicate(true),
	}


func _admission_request(seed: int, seat_count: int) -> Dictionary:
	var seats: Array[String] = []
	for seat_number: int in range(1, seat_count + 1):
		seats.append("seat_%02d" % seat_number)
	return {
		"request_kind": "developer_only_explicit_launch",
		"developer_mode": true,
		"tale_id": "drowned_harbor",
		"package_kind": "tale",
		"schema_version": 1,
		"package_version": 2,
		"provider_id": "drowned_harbor_authorities_v1",
		"seed": seed,
		"stable_seat_ids": seats,
	}


func _seat_public(session: DrownedHarborAlpha2Session, stable_seat_id: String) -> Dictionary:
	var board_row: Dictionary = {}
	for row: Dictionary in session.public_projection().board.seats:
		if row.stable_seat_id == stable_seat_id:
			board_row = row.duplicate(true)
			break
	for row: Dictionary in session.public_projection().roles.seats:
		if row.stable_seat_id == stable_seat_id:
			board_row.merge(row, true)
			break
	return board_row


func _capture(
	snapshots: Array[Dictionary], session: DrownedHarborAlpha2Session, enabled: bool
) -> void:
	if enabled:
		snapshots.append(session.to_snapshot())


func _route_failure(session: DrownedHarborAlpha2Session) -> Dictionary:
	return {
		"accepted": false,
		"reason": "route_action_rejected",
		"stage_id": session.to_snapshot().stage_id,
		"revision": session.to_snapshot().authoritative_revision,
	}


func _shared_projection_samples(session: DrownedHarborAlpha2Session) -> Array[Variant]:
	var projection: Dictionary = session.public_projection()
	var interruption: Dictionary = session.interrupt_presentation()
	return [
		projection,
		session.director_safe_input(),
		projection.get("public_history", []),
		projection.get("replay", []),
		projection.get("transcript", []),
		projection.get("mirror", []),
		interruption.get("public_recap", {}),
	]


func _assert_semantic_commitment_terms_absent(samples: Array, label: String) -> void:
	var serialized: String = _canonical(samples)
	_expect("hold_the_light" not in serialized, "%s excludes Council commitment term" % label)
	_expect("guard_last_light" not in serialized, "%s excludes Last Light commitment term" % label)


func _semantic_commitment_term_hit_count(samples: Array) -> int:
	var serialized: String = _canonical(samples)
	var result: int = 0
	if "hold_the_light" in serialized:
		result += 1
	if "guard_last_light" in serialized:
		result += 1
	return result


func _canonical(value: Variant) -> String:
	return JSON.stringify(TalePackage.canonicalize(value))


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("PASS: ", message)
		return
	_failures += 1
	push_error("FAILED: %s" % message)
