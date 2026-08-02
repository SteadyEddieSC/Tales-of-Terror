extends SceneTree

const EXPECTED_PACKAGE_DIGEST: String = (
	"17e5ed3b651424f4e292239d15258086" + "37babb7f91fb5134d018c644290b692f"
)
const EXPECTED_SCENARIO_DIGEST: String = (
	"d7cb1934f119bd2d94c514a8a5097581" + "15b894a79dc57e02fa8bda322bdd2168"
)
const EXPECTED_LOCALIZATION_DIGEST: String = (
	"c19bdaed5ad7b4e5169fcfeeb632b8c" + "8b39acf7a5edf39bf23374186de886fa3"
)
const SUMMARY_PREFIX: String = "DROWNED_HARBOR_PRODUCTION_SCAFFOLD_EVIDENCE:"

var _failures: int = 0
var _governed_cases: int = 0
var _rejections: int = 0


func _initialize() -> void:
	_test_canonical_uids()
	_test_native_candidate_and_identity()
	_test_explicit_admission_and_determinism()
	_test_state_and_rng_no_op_rejections()
	_test_snapshot_restore_and_exactly_once()
	_test_restore_failures_are_identity_first()
	_test_reset_exit_rematch_and_rollback()
	_test_normal_production_boundaries()
	var summary: Dictionary = {
		"accepted": _failures == 0,
		"governed_case_count": _governed_cases,
		"rejection_count": _rejections,
		"package_digest": EXPECTED_PACKAGE_DIGEST,
		"scenario_digest": EXPECTED_SCENARIO_DIGEST,
		"localization_digest": EXPECTED_LOCALIZATION_DIGEST,
		"provider_id": DrownedHarborScopedProvider.PROVIDER_ID,
		"deterministic": _failures == 0,
		"normal_default_tale": DrownedHarborDeveloperAdmissionGate.NORMAL_DEFAULT_TALE,
		"human_evidence_claimed": false,
		"production_readiness_claimed": false,
	}
	print(SUMMARY_PREFIX + JSON.stringify(summary, "", true))
	quit(_failures)


func _test_canonical_uids() -> void:
	var script_paths: Array[String] = [
		"res://src/tales/drowned_harbor/drowned_harbor_board_definition.gd",
		"res://src/tales/drowned_harbor/drowned_harbor_developer_admission_gate.gd",
		"res://src/tales/drowned_harbor/drowned_harbor_director_content.gd",
		"res://src/tales/drowned_harbor/drowned_harbor_rules_content.gd",
		"res://src/tales/drowned_harbor/drowned_harbor_scaffold_session.gd",
		"res://src/tales/drowned_harbor/drowned_harbor_scoped_provider.gd",
		"res://src/tales/drowned_harbor/drowned_harbor_social_content.gd",
		"res://tests/drowned_harbor_production_scaffold/drowned_harbor_production_scaffold_test.gd",
	]
	var textual_uids: Dictionary = {}
	var numeric_uids: Dictionary = {}
	for script_path: String in script_paths:
		var uid_path := script_path + ".uid"
		var uid_text := FileAccess.get_file_as_string(uid_path).strip_edges()
		var numeric_uid := ResourceUID.text_to_id(uid_text)
		_expect(numeric_uid != ResourceUID.INVALID_ID, "%s parses as a valid UID" % uid_path)
		_expect(
			ResourceUID.id_to_text(numeric_uid) == uid_text,
			"%s round-trips through Godot ResourceUID" % uid_path,
		)
		_expect(not textual_uids.has(uid_text), "%s textual UID is distinct" % uid_path)
		_expect(not numeric_uids.has(numeric_uid), "%s numeric UID is distinct" % uid_path)
		textual_uids[uid_text] = true
		numeric_uids[numeric_uid] = true
		var script_resource: Script = load(script_path)
		_expect(script_resource != null, "%s associated script loads" % script_path)
		_expect(
			ResourceUID.get_id_path(numeric_uid) == script_path,
			"%s UID is registered only to its intended scoped path" % uid_path,
		)
	_expect(textual_uids.size() == script_paths.size(), "all scaffold textual UIDs are unique")
	_expect(numeric_uids.size() == script_paths.size(), "all scaffold numeric UIDs are unique")


func _test_native_candidate_and_identity() -> void:
	var provider := DrownedHarborScopedProvider.new()
	var candidate: Dictionary = provider.build_candidate()
	_expect(candidate.get("accepted", false), "complete native candidate validates")
	if not candidate.get("accepted", false):
		return
	_expect(candidate.provider_id == "drowned_harbor_authorities_v1", "provider identity")
	_expect(candidate.package.tale_id == "drowned_harbor", "Tale identity")
	_expect(candidate.package.package_kind == "tale", "package kind")
	_expect(candidate.package.schema_version == 1, "package schema")
	_expect(candidate.package.package_version == 1, "package version")
	_expect(candidate.package_digest == EXPECTED_PACKAGE_DIGEST, "package digest")
	_expect(
		(
			FileAccess.get_sha256(DrownedHarborScopedProvider.SCENARIO_PATH)
			== EXPECTED_SCENARIO_DIGEST
		),
		"scenario digest"
	)
	_expect(
		(
			FileAccess.get_sha256(DrownedHarborScopedProvider.LOCALIZATION_PATH)
			== EXPECTED_LOCALIZATION_DIGEST
		),
		"localization digest"
	)
	_expect(candidate.board_definition is BoardDefinition, "native board base type")
	_expect(candidate.rules_content is RulesContent, "native rules base type")
	_expect(candidate.director_content is DirectorContent, "native Director base type")
	_expect(candidate.social_content is SocialContent, "native social base type")
	_expect(candidate.board_definition.validate().is_empty(), "board authority validates")
	_expect(
		candidate.rules_content.validate(candidate.board_definition).is_empty(),
		"rules authority validates"
	)
	_expect(
		(
			candidate
			. director_content
			. validate(candidate.rules_content, candidate.board_definition)
			. is_empty()
		),
		"Director authority validates"
	)
	_expect(
		(
			candidate
			. social_content
			. validate(candidate.rules_content, candidate.board_definition)
			. is_empty()
		),
		"social authority validates"
	)
	_expect(
		(
			candidate.social_content.privacy_classes()
			== PackedStringArray(
				["public", "controlled_reveal_private", "seat_private", "faction_private"]
			)
		),
		"four privacy classes"
	)
	var safe_input: Dictionary = {
		"authoritative_revision": 0,
		"connected_seat_count": 2,
		"stage_id": "scaffold_entry",
	}
	_expect(
		candidate.director_content.accepts_input(safe_input),
		"Director accepts public aggregate input"
	)
	var unsafe_input: Dictionary = safe_input.duplicate(true)
	unsafe_input["seat_private"] = "forbidden"
	_expect(
		not candidate.director_content.accepts_input(unsafe_input), "Director rejects private input"
	)
	var incomplete: Dictionary = provider.build_candidate("director")
	_expect_rejection(incomplete, "incomplete_candidate", "partial candidate rejects")
	_governed_cases += 1


func _test_explicit_admission_and_determinism() -> void:
	var gate_a := DrownedHarborDeveloperAdmissionGate.new()
	var gate_b := DrownedHarborDeveloperAdmissionGate.new()
	var request: Dictionary = _admission_request(6100, ["seat_01", "seat_02"])
	var first: Dictionary = gate_a.admit(request)
	var second: Dictionary = gate_b.admit(request)
	_expect(first.get("accepted", false), "explicit developer admission accepts")
	_expect(second.get("accepted", false), "repeated explicit admission accepts")
	_expect(
		_canonical(first.session.to_snapshot()) == _canonical(second.session.to_snapshot()),
		"repeated initialization is byte-equivalent",
	)
	_expect(first.session.to_snapshot().stable_seats.size() == 2, "stable seats initialize")
	_expect(
		first.session.to_snapshot().rng.stream_name == "drowned_harbor_scaffold_authority",
		"named RNG ownership"
	)
	var ambiguous: Dictionary = request.duplicate(true)
	ambiguous.developer_mode = false
	var before: Dictionary = first.session.to_snapshot()
	_expect_rejection(
		gate_a.admit(ambiguous), "unauthorized_admission_identity", "ambiguous admission rejects"
	)
	_expect(
		gate_a.active_session().to_snapshot() == before,
		"admission rejection preserves existing session"
	)
	_governed_cases += 2


func _test_state_and_rng_no_op_rejections() -> void:
	var gate := DrownedHarborDeveloperAdmissionGate.new()
	_expect(
		gate.admit(_admission_request(6200, ["seat_01", "seat_02"])).accepted,
		"rejection test session admits"
	)
	var session: DrownedHarborScaffoldSession = gate.active_session()
	var requests: Array[Dictionary] = []
	var stale: Dictionary = _action_request("request_stale", "event_stale", "seat_01", 1)
	requests.append(stale)
	var wrong_actor: Dictionary = _action_request("request_actor", "event_actor", "seat_01", 0)
	wrong_actor.actor = "normal_navigation"
	requests.append(wrong_actor)
	var wrong_seat: Dictionary = _action_request("request_seat", "event_seat", "seat_99", 0)
	requests.append(wrong_seat)
	var unsupported: Dictionary = _action_request("request_intent", "event_intent", "seat_01", 0)
	unsupported.intent = "low_tide_action"
	requests.append(unsupported)
	var malformed: Dictionary = _action_request(
		"request_malformed", "event_malformed", "seat_01", 0
	)
	malformed.erase("intent")
	requests.append(malformed)
	var reasons := PackedStringArray(
		[
			"stale_revision",
			"unauthorized_actor",
			"wrong_stable_seat",
			"unsupported_intent",
			"malformed_request"
		]
	)
	for index: int in requests.size():
		var before: Dictionary = session.to_snapshot()
		var result: Dictionary = session.process_request(requests[index])
		_expect_rejection(result, reasons[index], "%s rejects" % reasons[index])
		_expect(result.get("state_and_rng_unchanged", false), "%s reports no-op" % reasons[index])
		_expect(session.to_snapshot() == before, "%s preserves state and RNG" % reasons[index])
		_governed_cases += 1


func _test_snapshot_restore_and_exactly_once() -> void:
	var gate := DrownedHarborDeveloperAdmissionGate.new()
	var admission: Dictionary = _admission_request(6300, ["seat_01", "seat_02"])
	_expect(gate.admit(admission).accepted, "snapshot session admits")
	var accepted_request: Dictionary = _action_request("request_once", "event_once", "seat_01", 0)
	var accepted: Dictionary = gate.active_session().process_request(accepted_request)
	_expect(accepted.get("accepted", false), "scaffold terminal request accepts exactly once")
	var snapshot: Dictionary = gate.active_session().to_snapshot()
	_expect(snapshot.stage_id == "scaffold_terminal", "terminal stage persists")
	_expect(snapshot.authoritative_revision == 1, "result revision persists")
	_expect(snapshot.processed_request_ids == ["request_once"], "request identity persists")
	_expect(snapshot.processed_event_ids == ["event_once"], "event identity persists")
	var restored_gate := DrownedHarborDeveloperAdmissionGate.new()
	var restored: Dictionary = restored_gate.restore(admission, snapshot)
	_expect(restored.get("accepted", false), "exact snapshot restores")
	_expect(restored.session.to_snapshot() == snapshot, "restored bytes equal committed snapshot")
	var before_duplicate: Dictionary = restored.session.to_snapshot()
	_expect_rejection(
		restored.session.process_request(accepted_request),
		"duplicate_request",
		"duplicate remains rejected after restore"
	)
	_expect(
		restored.session.to_snapshot() == before_duplicate,
		"duplicate after restore is state-and-RNG no-op"
	)
	_governed_cases += 2


func _test_restore_failures_are_identity_first() -> void:
	var source_gate := DrownedHarborDeveloperAdmissionGate.new()
	var admission: Dictionary = _admission_request(6400, ["seat_01"])
	_expect(source_gate.admit(admission).accepted, "restore source admits")
	var snapshot: Dictionary = source_gate.active_session().to_snapshot()
	var wrong_tale: Dictionary = snapshot.duplicate(true)
	wrong_tale.tale_id = "lantern_house_vertical_slice"
	wrong_tale.erase("rng")
	var target_gate := DrownedHarborDeveloperAdmissionGate.new()
	_expect_rejection(
		target_gate.restore(admission, wrong_tale),
		"unsupported_tale_identity",
		"identity rejects before malformed fields"
	)
	_expect(not target_gate.has_active_scaffold(), "identity rejection commits no session")
	var wrong_version: Dictionary = snapshot.duplicate(true)
	wrong_version.snapshot_version = 99
	_expect_rejection(
		target_gate.restore(admission, wrong_version),
		"unsupported_snapshot_version",
		"unsupported snapshot version rejects"
	)
	_expect(not target_gate.has_active_scaffold(), "version rejection commits no session")
	var unknown_field: Dictionary = snapshot.duplicate(true)
	unknown_field["best_effort_field"] = true
	_expect_rejection(
		target_gate.restore(admission, unknown_field),
		"malformed_snapshot",
		"best-effort field matching rejects"
	)
	_expect(not target_gate.has_active_scaffold(), "malformed restore remains atomic")
	_governed_cases += 3


func _test_reset_exit_rematch_and_rollback() -> void:
	var admission: Dictionary = _admission_request(6500, ["seat_01", "seat_02"])
	var gate := DrownedHarborDeveloperAdmissionGate.new()
	_expect(gate.admit(admission).accepted, "cleanup session admits")
	_expect(
		(
			gate
			. active_session()
			. process_request(_action_request("request_cleanup", "event_cleanup", "seat_01", 0))
			. accepted
		),
		"cleanup session reaches terminal"
	)
	var rematch: Dictionary = gate.rematch()
	_expect(rematch.get("accepted", false), "rematch rebuilds through provider")
	_expect(
		rematch.session.to_snapshot().authoritative_revision == 0, "rematch uses fresh authority"
	)
	_expect(
		rematch.session.to_snapshot().processed_event_ids.is_empty(),
		"rematch clears exactly-once history"
	)
	var exit: Dictionary = gate.exit_to_normal_default()
	_expect(exit.selected_tale_id == "lantern_house_vertical_slice", "exit returns normal default")
	_expect(not gate.has_active_scaffold(), "exit clears scaffold authority")
	_expect(gate.admit(admission).accepted, "reset session re-admits explicitly")
	_expect(
		gate.reset_to_normal_default().selected_tale_id == "lantern_house_vertical_slice",
		"reset returns normal default"
	)
	_expect(not gate.has_active_scaffold(), "reset clears scaffold authority")
	_expect(gate.admit(admission).accepted, "rollback session re-admits explicitly")
	_expect(
		gate.rollback().selected_tale_id == "lantern_house_vertical_slice",
		"rollback returns normal default"
	)
	_expect(not gate.has_active_scaffold(), "rollback clears scaffold authority")
	_governed_cases += 3


func _test_normal_production_boundaries() -> void:
	var registry := TaleProviderRegistry.new()
	_expect(
		not registry.provider_ids().has(DrownedHarborScopedProvider.PROVIDER_ID),
		"central registry excludes Drowned Harbor"
	)
	var catalog_result: Dictionary = TaleCatalog.load_validated(
		TaleCatalog.PRODUCTION_PATH, registry, TaleCatalog.PRODUCTION_DIGEST
	)
	_expect(catalog_result.get("accepted", false), "normal production catalog remains valid")
	_expect(catalog_result.catalog.entries.size() == 1, "normal catalog retains one entry")
	_expect(
		catalog_result.default_tale_id == "lantern_house_vertical_slice",
		"Lantern House remains default"
	)
	_expect(
		TaleCatalog.entry_by_id(catalog_result.catalog, "drowned_harbor").is_empty(),
		"Drowned Harbor absent from normal library inventory"
	)
	var gate := DrownedHarborDeveloperAdmissionGate.new()
	_expect(not gate.has_active_scaffold(), "scoped gate never auto-starts")
	_governed_cases += 1


func _admission_request(seed: int, stable_seat_ids: Array[String]) -> Dictionary:
	return {
		"request_kind": "developer_only_explicit_launch",
		"developer_mode": true,
		"tale_id": "drowned_harbor",
		"package_kind": "tale",
		"schema_version": 1,
		"package_version": 1,
		"provider_id": "drowned_harbor_authorities_v1",
		"seed": seed,
		"stable_seat_ids": stable_seat_ids,
	}


func _action_request(
	request_id: String, event_id: String, stable_seat_id: String, source_revision: int
) -> Dictionary:
	return {
		"request_id": request_id,
		"event_id": event_id,
		"actor": "developer_scaffold_gate",
		"stable_seat_id": stable_seat_id,
		"source_revision": source_revision,
		"intent": "acknowledge_scaffold_exit",
	}


func _canonical(value: Variant) -> String:
	return JSON.stringify(TalePackage.canonicalize(value))


func _expect_rejection(result: Dictionary, reason: String, message: String) -> void:
	_expect(not result.get("accepted", false) and result.get("reason", "") == reason, message)
	_rejections += 1


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
		return
	_failures += 1
	push_error("FAILED: %s" % message)
