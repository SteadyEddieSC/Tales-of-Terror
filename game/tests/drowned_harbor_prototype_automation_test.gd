extends SceneTree

const PROFILE_PATH: String = (
	"res://tests/drowned_harbor_dev_only/" + "prototype_automation_profile_v1.json"
)
const MANIFEST_PATH: String = "res://tests/drowned_harbor_prototype_manifest_v1.json"
const FIXTURE_PATH: String = "res://tests/drowned_harbor_dev_only/state_projection_fixtures_v1.json"
const AUTOMATION_UID_PATH: String = "res://tests/drowned_harbor_prototype_automation_test.gd.uid"
const PROFILE_ID: String = "DH-AUTO-P019-V1"
const SUMMARY_PREFIX: String = "DROWNED_HARBOR_AUTOMATION_EVIDENCE:"
const EXPECTED_FIXTURES: PackedStringArray = [
	"DH-FIX-001",
	"DH-FIX-002",
	"DH-FIX-003",
	"DH-FIX-004",
	"DH-FIX-005",
	"DH-FIX-006",
	"DH-FIX-007",
]
const EXPECTED_SEQUENCES: PackedStringArray = [
	"canonical_forward",
	"reverse",
	"high_water_full_presentation",
	"high_water_semantic_skip",
	"controlled_private_unavailable_surface",
	"controlled_private_disconnect_interruption",
	"bellhouse_recovery_first",
	"stale_revision_rejection",
	"wrong_authority_wrong_seat_rejection",
	"duplicate_replay_idempotence",
	"repeated_fresh_shell_equivalence",
	"post_commit_reprojection",
]
const LOW_ADAPTER: Script = preload(
	"res://tests/drowned_harbor_dev_only/low_tide_fixture_adapter.gd"
)
const LOW_SHELL: Script = preload(
	"res://tests/drowned_harbor_dev_only/low_tide_shared_screen_shell.gd"
)
const BELL_ADAPTER: Script = preload(
	"res://tests/drowned_harbor_dev_only/bellhouse_fixture_adapter.gd"
)
const BELL_SHELL: Script = preload(
	"res://tests/drowned_harbor_dev_only/bellhouse_decision_shell.gd"
)
const PRIVATE_ADAPTER: Script = preload(
	"res://tests/drowned_harbor_dev_only/controlled_private_fixture_adapter.gd"
)
const PRIVATE_SHELL: Script = preload(
	"res://tests/drowned_harbor_dev_only/controlled_private_shield_shell.gd"
)
const HIGH_ADAPTER: Script = preload(
	"res://tests/drowned_harbor_dev_only/high_water_fixture_adapter.gd"
)
const HIGH_SHELL: Script = preload(
	"res://tests/drowned_harbor_dev_only/high_water_transformation_shell.gd"
)

var _failures: int = 0
var _deadlock_findings: int = 0
var _private_leak_findings: int = 0


func _initialize() -> void:
	var profile: Dictionary = _read_json(PROFILE_PATH)
	var manifest: Dictionary = _read_json(MANIFEST_PATH)
	var package: Dictionary = _read_json(FIXTURE_PATH)
	_validate_profile(profile)
	_validate_manifest_and_fixtures(manifest, package)
	_validate_canonical_uid()
	var first_runs: Array[Dictionary] = []
	var total_cases: int = 0
	var total_rejections: int = 0
	for sequence_id: String in EXPECTED_SEQUENCES:
		var first: Dictionary = _run_sequence(sequence_id)
		var second: Dictionary = _run_sequence(sequence_id)
		_expect(first.get("accepted", false), "%s first repetition completes" % sequence_id)
		_expect(second.get("accepted", false), "%s second repetition completes" % sequence_id)
		_expect(
			_canonical_bytes(first) == _canonical_bytes(second),
			"%s repetitions are byte-equivalent" % sequence_id,
		)
		first_runs.append(first)
		total_cases += int(first.get("governed_cases", 0))
		total_rejections += int(first.get("rejections", 0))
		_scan_public_evidence(first)
	_test_high_water_full_skip_equivalence()
	_test_fresh_family_isolation()
	var deterministic: bool = _failures == 0
	var summary: Dictionary = {
		"accepted": deterministic,
		"deadlock_findings": _deadlock_findings,
		"deterministic_equivalence": deterministic,
		"fail_closed_rejection_count": total_rejections,
		"fixture_package_digest": _digest_file(FIXTURE_PATH),
		"governed_case_count": total_cases,
		"human_evidence_claimed": false,
		"manifest_digest": _digest_file(MANIFEST_PATH),
		"private_leak_findings": _private_leak_findings,
		"production_authority_created": false,
		"profile_digest": _digest_file(PROFILE_PATH),
		"profile_id": PROFILE_ID,
		"repetition_count": 2,
		"sequence_count": first_runs.size(),
	}
	print(SUMMARY_PREFIX + JSON.stringify(summary, "", true))
	quit(_failures)


func _validate_profile(profile: Dictionary) -> void:
	_expect(profile.get("profile_kind") == "drowned_harbor_prototype_automation", "profile kind")
	_expect(profile.get("schema_version") == 1, "profile schema")
	_expect(profile.get("profile_id") == PROFILE_ID, "profile identity")
	_expect(profile.get("godot_version") == "4.7.1-stable", "Godot identity")
	_expect(profile.get("prototype_manifest_path") == MANIFEST_PATH, "manifest binding")
	_expect(profile.get("fixture_package_path") == FIXTURE_PATH, "fixture binding")
	_expect(
		(
			profile.get("aggregate_test_entry_point")
			== "res://tests/drowned_harbor_prototype_automation_test.gd"
		),
		"aggregate entry point binding",
	)
	var families: Array = profile.get("feature_families", [])
	_expect(families.size() == 4, "exactly four implemented feature families")
	var implemented: PackedStringArray = []
	for family: Variant in families:
		if family is Dictionary:
			implemented.append(str(family.get("family_id", "")))
	_expect(
		(
			implemented
			== PackedStringArray(
				[
					"low_tide_public_action",
					"bellhouse_decision_and_recovery",
					"controlled_private_shield_and_handoff",
					"high_water_transformation",
				]
			)
		),
		"implemented family order",
	)
	var projection_only: Array = profile.get("projection_only_fixtures", [])
	_expect(
		(
			projection_only.size() == 1
			and projection_only[0].get("fixture_id") == "DH-FIX-005"
			and projection_only[0].get("runtime_shell") == false
		),
		"DH-FIX-005 projection-only boundary",
	)
	var determinism: Dictionary = profile.get("determinism", {})
	_expect(determinism.get("repetitions_per_sequence") == 2, "two deterministic repetitions")
	_expect(determinism.get("max_steps_per_case") == 32, "fixed 32-step bound")
	_expect(
		PackedStringArray(determinism.get("sequence_ids", [])) == EXPECTED_SEQUENCES,
		"closed sequence inventory",
	)
	var classification: Dictionary = profile.get("classification", {})
	_expect(
		(
			classification.get("automated") == true
			and classification.get("deterministic") == true
			and classification.get("headless") == true
			and classification.get("machine_evidence") == true
		),
		"machine evidence classification",
	)
	for field: String in [
		"human_playtest_evidence",
		"physical_controller_evidence",
		"television_evidence",
		"accessibility_compliance",
		"privacy_certification",
		"security_certification",
		"fun_evidence",
		"pacing_evidence",
		"fairness_evidence",
		"balance_evidence",
		"comprehension_evidence",
		"production_readiness_evidence",
	]:
		_expect(classification.get(field) == false, "%s remains denied" % field)


func _validate_manifest_and_fixtures(manifest: Dictionary, package: Dictionary) -> void:
	_expect(
		(
			PackedInt32Array(manifest.get("completed_work_issues", []))
			== PackedInt32Array([80, 81, 82, 83, 84, 85, 86])
		),
		"completed issue progression",
	)
	_expect(manifest.get("future_work_issues") == [], "future issue inventory is empty")
	_expect(manifest.get("prototype_components", []).size() == 13, "component inventory stays 13")
	_expect(manifest.get("allowed_entry_points", []).size() == 6, "entry-point inventory is six")
	_expect(
		manifest.get("automation_profiles") == [PROFILE_PATH],
		"automation profile registration",
	)
	var fixture_ids: PackedStringArray = []
	for fixture: Variant in package.get("fixtures", []):
		if fixture is Dictionary:
			fixture_ids.append(str(fixture.get("fixture_id", "")))
	_expect(fixture_ids == EXPECTED_FIXTURES, "fixture inventory remains DH-FIX-001 through 007")
	for fixture: Variant in package.get("fixtures", []):
		if not fixture is Dictionary:
			continue
		_expect(
			fixture.get("stable_seat_identity_before") == fixture.get("stable_seat_identity_after"),
			"%s preserves stable-seat identity" % fixture.get("fixture_id", "fixture"),
		)
		_expect(
			fixture.get("rng_cursor_before") == fixture.get("rng_cursor_after"),
			"%s preserves RNG cursor" % fixture.get("fixture_id", "fixture"),
		)


func _validate_canonical_uid() -> void:
	var uid_text: String = FileAccess.get_file_as_string(AUTOMATION_UID_PATH).strip_edges()
	var numeric_uid: int = ResourceUID.text_to_id(uid_text)
	_expect(numeric_uid != ResourceUID.INVALID_ID, "automation UID parses")
	_expect(ResourceUID.id_to_text(numeric_uid) == uid_text, "automation UID round-trips")
	_expect(uid_text.length() == 19, "automation UID uses a 13-character payload")


func _run_sequence(sequence_id: String) -> Dictionary:
	var result: Dictionary = {"accepted": false, "governed_cases": 0, "rejections": 1}
	match sequence_id:
		"canonical_forward":
			result = _sequence_bundle(
				[_run_low(), _run_bellhouse(false), _run_private("DH-FIX-003"), _run_high(false)]
			)
		"reverse":
			result = _sequence_bundle(
				[_run_high(true), _run_private("DH-FIX-007"), _run_bellhouse(false), _run_low()]
			)
		"high_water_full_presentation":
			result = _sequence_bundle([_run_high(false)])
		"high_water_semantic_skip":
			result = _sequence_bundle([_run_high(true)])
		"controlled_private_unavailable_surface":
			result = _run_private_unavailable()
		"controlled_private_disconnect_interruption":
			result = _run_private_interruptions()
		"bellhouse_recovery_first":
			result = _run_bellhouse(true)
		"stale_revision_rejection":
			result = _sequence_bundle(
				[_run_rejections("stale"), _run_low_request_contract_rejections()]
			)
		"wrong_authority_wrong_seat_rejection":
			result = _run_rejections("authority")
		"duplicate_replay_idempotence":
			result = _run_duplicates()
		"repeated_fresh_shell_equivalence":
			result = _run_fresh_equivalence()
		"post_commit_reprojection":
			result = _run_high_reprojection()
	return result


func _run_low() -> Dictionary:
	var adapter: DrownedHarborLowTideFixtureAdapter = LOW_ADAPTER.new()
	var loaded: Dictionary = adapter.load_fixture()
	var projected: Dictionary = adapter.project(adapter.default_request())
	var shell: DrownedHarborLowTideSharedScreenShell = LOW_SHELL.new()
	var initialized: Dictionary = shell.initialize_from_fixture()
	var before: Dictionary = shell.state_signature()
	shell.open_transcript()
	shell.request_replay()
	shell.dispatch_semantic_action("ui_confirm")
	var confirmed: Dictionary = shell.confirm_pending(11, "seat_01")
	var after: Dictionary = shell.state_signature()
	var accepted: bool = (
		loaded.get("accepted", false)
		and projected.get("accepted", false)
		and initialized.get("accepted", false)
		and confirmed.get("accepted", false)
		and before == after
	)
	shell.free()
	return {
		"accepted": accepted,
		"event_key": projected.get("event", {}).get("event_key", ""),
		"fixture_id": projected.get("fixture_id", ""),
		"governed_cases": 1,
		"rejections": 0,
		"result_revision": projected.get("result_revision", -1),
		"rng_cursor": projected.get("rng_cursor", -1),
		"source_revision": projected.get("source_revision", -1),
		"stable_seat_id": projected.get("stable_seat_id", ""),
	}


func _run_bellhouse(recovery_first: bool) -> Dictionary:
	var shell: DrownedHarborBellhouseDecisionShell = BELL_SHELL.new()
	var initialized: Dictionary = shell.initialize_from_fixtures()
	var recovery_ok: bool = true
	if recovery_first:
		recovery_ok = shell.project_fixture_recovery().get("accepted", false)
		recovery_ok = recovery_ok and shell.return_to_decision().get("accepted", false)
	var requested: Dictionary = shell.request_confirmation()
	var committed: Dictionary = shell.confirm_pending(
		21, "seat_02", "active_stable_seat", shell.selected_option()
	)
	var duplicate: Dictionary = shell.confirm_pending(
		21, "seat_02", "active_stable_seat", shell.selected_option()
	)
	var signature: Dictionary = shell.fixture_signature()
	var event: Dictionary = shell.committed_event()
	var accepted: bool = (
		initialized.get("accepted", false)
		and recovery_ok
		and requested.get("accepted", false)
		and committed.get("accepted", false)
		and duplicate.get("accepted", false)
		and shell.prototype_commit_count() == 1
	)
	shell.free()
	return {
		"accepted": accepted,
		"event_key": event.get("event_key", ""),
		"fixture_id": "DH-FIX-002",
		"governed_cases": 2 if recovery_first else 1,
		"rejections": 0,
		"rng_cursor": signature.get("rng_cursor", -1),
		"source_revision": signature.get("source_revision", -1),
		"stable_seat_id": signature.get("stable_seat_id", ""),
	}


func _run_private(fixture_id: String) -> Dictionary:
	var shell: DrownedHarborControlledPrivateShieldShell = PRIVATE_SHELL.new()
	var request: Dictionary = DrownedHarborControlledPrivateFixtureAdapter.authorized_request_for(
		fixture_id
	)
	var begun: Dictionary = shell.begin_handoff(request)
	var armed: bool = _arm_private_acknowledgement(shell)
	var committed: Dictionary = shell.acknowledge(_ack_request(request)) if armed else {}
	var restored: Dictionary = shell.restore_public() if committed.get("accepted", false) else {}
	var public_snapshot: Dictionary = shell.public_snapshot()
	var counts: PackedInt32Array = shell._exactly_once_projection_evidence()
	var accepted: bool = (
		begun.get("accepted", false)
		and armed
		and committed.get("accepted", false)
		and restored.get("accepted", false)
		and shell.private_state_cleared()
		and counts == PackedInt32Array([1, 1, 1, 1, 1, 1, 1, 1])
	)
	_scan_public_evidence({"outputs": shell.privacy_outputs(), "snapshot": public_snapshot})
	var result: Dictionary = {
		"accepted": accepted,
		"fixture_id": fixture_id,
		"governed_cases": 1,
		"mode": shell.mode_name(),
		"private_state_cleared": shell.private_state_cleared(),
		"rejections": 0,
		"stable_seat_id": request.get("stable_seat_id", ""),
	}
	shell.free()
	return result


func _run_high(skip: bool) -> Dictionary:
	var shell: DrownedHarborHighWaterTransformationShell = HIGH_SHELL.new()
	var initialized: Dictionary = shell.initialize_from_fixture()
	var presented: Dictionary = shell.skip_presentation() if skip else shell.run_full_presentation()
	var acknowledged: Dictionary = shell.acknowledge_persistent_summary()
	var evidence: Dictionary = shell._evidence_snapshot()
	var equivalence: String = shell._equivalence_bytes()
	var accepted: bool = (
		initialized.get("accepted", false)
		and presented.get("accepted", false)
		and acknowledged.get("accepted", false)
		and evidence.get("commit_count") == 1
		and evidence.get("event_count") == 1
		and evidence.get("rng_cursor") == 12
		and evidence.get("stable_seat_ids") == ["seat_04"]
		and evidence.get("next_interaction_allowed") == true
	)
	_scan_public_evidence(shell._privacy_outputs())
	var result: Dictionary = {
		"accepted": accepted,
		"equivalence_digest": _sha256_text(equivalence),
		"event_count": evidence.get("event_count", -1),
		"fixture_id": "DH-FIX-004",
		"governed_cases": 1,
		"rejections": 0,
		"result_revision": evidence.get("result_revision", -1),
		"rng_cursor": evidence.get("rng_cursor", -1),
		"source_revision": evidence.get("source_revision", -1),
		"stable_seat_ids": evidence.get("stable_seat_ids", []),
	}
	shell.free()
	return result


func _run_private_unavailable() -> Dictionary:
	var shell: DrownedHarborControlledPrivateShieldShell = PRIVATE_SHELL.new()
	var request: Dictionary = DrownedHarborControlledPrivateFixtureAdapter.authorized_request_for(
		"DH-FIX-003"
	)
	var rejected: Dictionary = shell.begin_handoff(request, false)
	var result: Dictionary = {
		"accepted": not rejected.get("accepted", true) and shell.private_state_cleared(),
		"code": rejected.get("code", ""),
		"governed_cases": 1,
		"rejections": 1,
	}
	shell.free()
	return result


func _run_private_interruptions() -> Dictionary:
	var disconnect_shell: DrownedHarborControlledPrivateShieldShell = PRIVATE_SHELL.new()
	var request: Dictionary = DrownedHarborControlledPrivateFixtureAdapter.authorized_request_for(
		"DH-FIX-003"
	)
	var begun: Dictionary = disconnect_shell.begin_handoff(request)
	var disconnected: Dictionary = disconnect_shell.handle_disconnect()
	var disconnect_ok: bool = (
		begun.get("accepted", false)
		and disconnected.get("accepted", false)
		and disconnect_shell.private_state_cleared()
	)
	disconnect_shell.free()
	var interrupt_shell: DrownedHarborControlledPrivateShieldShell = PRIVATE_SHELL.new()
	var begun_again: Dictionary = interrupt_shell.begin_handoff(request)
	var interrupted: Dictionary = interrupt_shell.interrupt_presentation()
	var interrupt_ok: bool = (
		begun_again.get("accepted", false)
		and interrupted.get("accepted", false)
		and interrupt_shell.private_state_cleared()
	)
	interrupt_shell.free()
	return {
		"accepted": disconnect_ok and interrupt_ok,
		"governed_cases": 2,
		"private_state_cleared": true,
		"rejections": 0,
	}


func _run_rejections(kind: String) -> Dictionary:
	var accepted: bool = true
	var codes: PackedStringArray = []
	var low: DrownedHarborLowTideFixtureAdapter = LOW_ADAPTER.new()
	low.load_fixture()
	var low_request: Dictionary = low.default_request()
	low_request["source_revision" if kind == "stale" else "stable_seat_id"] = (
		10 if kind == "stale" else "seat_99"
	)
	var low_rejected: Dictionary = low.project(low_request)
	accepted = accepted and not low_rejected.get("accepted", true)
	codes.append(str(low_rejected.get("reason", "")).get_slice(":", 0))
	var bell: DrownedHarborBellhouseFixtureAdapter = BELL_ADAPTER.new()
	bell.load_fixtures()
	var bell_request: Dictionary = bell.default_decision_request()
	bell_request["source_revision" if kind == "stale" else "actor_kind"] = (
		20 if kind == "stale" else "spectator"
	)
	var bell_rejected: Dictionary = bell.project_decision(bell_request)
	accepted = accepted and not bell_rejected.get("accepted", true)
	codes.append(str(bell_rejected.get("reason", "")).get_slice(":", 0))
	var private_adapter: DrownedHarborControlledPrivateFixtureAdapter = PRIVATE_ADAPTER.new()
	var private_request: Dictionary = (
		DrownedHarborControlledPrivateFixtureAdapter.authorized_request_for("DH-FIX-003")
	)
	private_request["source_revision" if kind == "stale" else "stable_seat_id"] = (
		30 if kind == "stale" else "seat_99"
	)
	var private_rejected: Dictionary = private_adapter.load_and_project(private_request)
	accepted = accepted and not private_rejected.get("accepted", true)
	codes.append(str(private_rejected.get("code", "")))
	var high: DrownedHarborHighWaterFixtureAdapter = HIGH_ADAPTER.new()
	var high_request: Dictionary = DrownedHarborHighWaterFixtureAdapter.authorized_request()
	high_request["source_revision" if kind == "stale" else "actor_kind"] = (
		40 if kind == "stale" else "spectator"
	)
	var high_rejected: Dictionary = high.load_and_prepare(high_request)
	accepted = accepted and not high_rejected.get("accepted", true)
	codes.append(str(high_rejected.get("code", "")))
	return {
		"accepted": accepted,
		"codes": codes,
		"governed_cases": 4,
		"rejections": 4,
	}


func _run_low_request_contract_rejections() -> Dictionary:
	var unknown_adapter: DrownedHarborLowTideFixtureAdapter = LOW_ADAPTER.new()
	var unknown_loaded: Dictionary = unknown_adapter.load_fixture()
	var unknown_before: Dictionary = _low_request_invariants(unknown_adapter)
	var unknown_request: Dictionary = unknown_adapter.default_request()
	unknown_request["intent"] = "unknown_fixture_intent"
	var unknown_rejected: Dictionary = unknown_adapter.project(unknown_request)
	var unknown_code: String = str(unknown_rejected.get("reason", "")).get_slice(":", 0)
	var unknown_ok: bool = (
		unknown_loaded.get("accepted", false)
		and not unknown_rejected.get("accepted", true)
		and unknown_code == "unauthorized_intent"
		and _low_request_invariants(unknown_adapter) == unknown_before
		and _low_rejection_is_public_safe(unknown_rejected)
	)
	_scan_public_evidence(unknown_rejected)

	var malformed_adapter: DrownedHarborLowTideFixtureAdapter = LOW_ADAPTER.new()
	var malformed_loaded: Dictionary = malformed_adapter.load_fixture()
	var malformed_before: Dictionary = _low_request_invariants(malformed_adapter)
	var malformed_request: Dictionary = malformed_adapter.default_request()
	malformed_request.erase("intent")
	var malformed_rejected: Dictionary = malformed_adapter.project(malformed_request)
	var malformed_code: String = str(malformed_rejected.get("reason", "")).get_slice(":", 0)
	var malformed_ok: bool = (
		malformed_loaded.get("accepted", false)
		and not malformed_rejected.get("accepted", true)
		and malformed_code == "malformed_request"
		and _low_request_invariants(malformed_adapter) == malformed_before
		and _low_rejection_is_public_safe(malformed_rejected)
	)
	_scan_public_evidence(malformed_rejected)

	return {
		"accepted": unknown_ok and malformed_ok,
		"governed_cases": 2,
		"rejection_identifiers": PackedStringArray([unknown_code, malformed_code]),
		"rejections": 2,
	}


func _low_request_invariants(adapter: DrownedHarborLowTideFixtureAdapter) -> Dictionary:
	return {
		"result_revision": adapter.result_revision(),
		"rng_cursor": adapter.rng_cursor(),
		"source_fingerprint": adapter.source_fingerprint(),
		"source_revision": adapter.source_revision(),
		"stable_seat_id": adapter.stable_seat_id(),
	}


func _low_rejection_is_public_safe(rejected: Dictionary) -> bool:
	var text: String = JSON.stringify(rejected, "", true)
	return (
		not "PRIVATE_" in text
		and not "archive_culvert" in text
		and not "bellmarked_candidate" in text
	)


func _run_duplicates() -> Dictionary:
	var bell: Dictionary = _run_bellhouse(false)
	var private_result: Dictionary = _run_private("DH-FIX-003")
	var high: DrownedHarborHighWaterTransformationShell = HIGH_SHELL.new()
	high.initialize_from_fixture()
	high.skip_presentation()
	high.acknowledge_persistent_summary()
	var before: Dictionary = high._evidence_snapshot()
	high.skip_presentation()
	high.acknowledge_persistent_summary()
	high.replay_committed_summary()
	high.reproject_existing_result()
	var after: Dictionary = high._evidence_snapshot()
	var high_ok: bool = (
		before.get("commit_count") == after.get("commit_count")
		and before.get("event_count") == after.get("event_count")
		and before.get("history_count") == after.get("history_count")
		and before.get("transcript_count") == after.get("transcript_count")
		and before.get("replay_count") == after.get("replay_count")
		and before.get("mirror_count") == after.get("mirror_count")
	)
	high.free()
	return {
		"accepted":
		bell.get("accepted", false) and private_result.get("accepted", false) and high_ok,
		"governed_cases": 3,
		"rejections": 0,
	}


func _run_fresh_equivalence() -> Dictionary:
	var low_a: Dictionary = _run_low()
	var low_b: Dictionary = _run_low()
	var bell_a: Dictionary = _run_bellhouse(false)
	var bell_b: Dictionary = _run_bellhouse(false)
	var private_a: Dictionary = _run_private("DH-FIX-007")
	var private_b: Dictionary = _run_private("DH-FIX-007")
	var high_a: Dictionary = _run_high(false)
	var high_b: Dictionary = _run_high(false)
	return {
		"accepted":
		(
			_canonical_bytes(low_a) == _canonical_bytes(low_b)
			and _canonical_bytes(bell_a) == _canonical_bytes(bell_b)
			and _canonical_bytes(private_a) == _canonical_bytes(private_b)
			and _canonical_bytes(high_a) == _canonical_bytes(high_b)
		),
		"governed_cases": 4,
		"rejections": 0,
	}


func _run_high_reprojection() -> Dictionary:
	var shell: DrownedHarborHighWaterTransformationShell = HIGH_SHELL.new()
	shell.initialize_from_fixture()
	shell.skip_presentation()
	var before: String = shell._equivalence_bytes()
	var failed: Dictionary = shell._fail_projection_after_commit()
	var recovered: Dictionary = shell.recover_projection()
	var after: String = shell._equivalence_bytes()
	var evidence: Dictionary = shell._evidence_snapshot()
	var result: Dictionary = {
		"accepted":
		(
			not failed.get("accepted", true)
			and recovered.get("accepted", false)
			and before == after
			and evidence.get("commit_count") == 1
			and evidence.get("event_count") == 1
		),
		"governed_cases": 1,
		"rejections": 1,
	}
	shell.free()
	return result


func _test_high_water_full_skip_equivalence() -> void:
	var full: Dictionary = _run_high(false)
	var skipped: Dictionary = _run_high(true)
	_expect(
		full.get("equivalence_digest") == skipped.get("equivalence_digest"),
		"High Water full and semantic-skip evidence is byte-equivalent",
	)


func _test_fresh_family_isolation() -> void:
	var family_results: Array[Dictionary] = [
		_run_low(),
		_run_bellhouse(false),
		_run_private("DH-FIX-003"),
		_run_private("DH-FIX-007"),
		_run_high(false),
	]
	var fixture_ids: PackedStringArray = []
	for result: Dictionary in family_results:
		_expect(result.get("accepted", false), "fresh family run completes")
		fixture_ids.append(str(result.get("fixture_id", "")))
	_expect(
		(
			fixture_ids
			== PackedStringArray(
				["DH-FIX-001", "DH-FIX-002", "DH-FIX-003", "DH-FIX-007", "DH-FIX-004"]
			)
		),
		"fresh shell instances retain fixture isolation",
	)


func _sequence_bundle(cases: Array[Dictionary]) -> Dictionary:
	var accepted: bool = true
	var governed_cases: int = 0
	var rejections: int = 0
	for value: Dictionary in cases:
		accepted = accepted and value.get("accepted", false)
		governed_cases += int(value.get("governed_cases", 0))
		rejections += int(value.get("rejections", 0))
	return {
		"accepted": accepted,
		"cases": cases,
		"governed_cases": governed_cases,
		"rejections": rejections,
	}


func _arm_private_acknowledgement(shell: DrownedHarborControlledPrivateShieldShell) -> bool:
	for step: int in range(8):
		var armed: Dictionary = shell.request_acknowledgement()
		if armed.get("accepted", false):
			return true
		shell.navigate_private(1)
	_deadlock_findings += 1
	return false


func _ack_request(request: Dictionary) -> Dictionary:
	return {
		"controller_authority_id": request.get("controller_authority_id", ""),
		"current_counter": request.get("current_counter", -1),
		"handoff_id": request.get("handoff_id", ""),
		"handoff_revision": request.get("handoff_revision", -1),
		"source_revision": request.get("source_revision", -1),
		"stable_seat_id": request.get("stable_seat_id", ""),
		"trace_id": request.get("trace_id", ""),
	}


func _scan_public_evidence(value: Variant) -> void:
	var text: String = JSON.stringify(value, "", true)
	if "PRIVATE_" in text:
		_private_leak_findings += 1
		_expect(false, "public automation evidence excludes private markers")


func _canonical_bytes(value: Variant) -> String:
	return JSON.stringify(value, "", true)


func _digest_file(path: String) -> String:
	var context: HashingContext = HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(FileAccess.get_file_as_bytes(path))
	return context.finish().hex_encode()


func _sha256_text(value: String) -> String:
	var context: HashingContext = HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(value.to_utf8_buffer())
	return context.finish().hex_encode()


func _read_json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:
		return parsed
	_expect(false, "required JSON parses: %s" % path.get_file())
	return {}


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("Drowned Harbor automation failure: %s" % message)
