extends SceneTree

const ADAPTER_SCRIPT: Script = preload(
	"res://tests/drowned_harbor_dev_only/controlled_private_fixture_adapter.gd"
)
const SHELL_SCRIPT: Script = preload(
	"res://tests/drowned_harbor_dev_only/controlled_private_shield_shell.gd"
)
const SURFACE_SCRIPT: Script = preload(
	"res://tests/drowned_harbor_dev_only/controlled_private_surface.gd"
)
const SHELL_SCENE_PATH: String = (
	"res://tests/drowned_harbor_dev_only/" + "controlled_private_shield_shell.tscn"
)
const FIXTURE_PATH: String = "res://tests/drowned_harbor_dev_only/state_projection_fixtures_v1.json"
const MANIFEST_PATH: String = "res://tests/drowned_harbor_prototype_manifest_v1.json"
const CATALOG_PATH: String = "res://data/tales/tale_catalog_v1.json"
const PROVIDER_PATH: String = "res://src/session/tale_provider_registry.gd"
const EXPORT_PRESETS_PATH: String = "res://export_presets.cfg"
const PRIVATE_MARKER: String = "PRIVATE_"

var _failures: int = 0


func _initialize() -> void:
	_test_fixture_inventory_and_bindings()
	_test_neutral_shield_precedes_private_request()
	_test_bargain_authorized_reveal_and_acknowledgement()
	_test_inherited_state_authorized_reveal_and_acknowledgement()
	_test_shield_is_information_neutral_with_voice_disabled()
	_test_private_values_never_enter_public_outputs()
	_test_application_private_state_clears_before_public_restore()
	_test_deterministic_repeated_inputs_are_byte_equivalent()
	_test_presentation_and_help_consume_no_rng()
	_test_exactly_once_and_duplicate_acknowledgement()
	_test_fail_closed_request_matrix()
	_test_private_surface_unavailable_and_no_phone_fallback()
	_test_disconnect_and_reconnect_matrix()
	_test_cancellation_and_interruption_clear_state()
	_test_public_restoration_failure_recovers_deterministically()
	_test_new_handoff_requires_and_inherits_clear_state()
	_test_inherited_state_preserves_stable_seat_and_evolved_state()
	_test_controller_ownership_and_semantic_mappings()
	_test_production_and_export_boundaries()
	_test_scene_is_test_only_and_instantiable()
	if _failures == 0:
		print("Drowned Harbor controlled-private shield tests passed")
	quit(_failures)


func _test_fixture_inventory_and_bindings() -> void:
	var package: Dictionary = _read_json(FIXTURE_PATH)
	var ids: PackedStringArray = []
	for fixture: Dictionary in package.get("fixtures", []):
		ids.append(str(fixture.get("fixture_id", "")))
	_expect(
		(
			ids
			== PackedStringArray(
				[
					"DH-FIX-001",
					"DH-FIX-002",
					"DH-FIX-003",
					"DH-FIX-004",
					"DH-FIX-005",
					"DH-FIX-006",
					"DH-FIX-007",
				]
			)
		),
		"fixture inventory is exactly DH-FIX-001 through DH-FIX-007",
	)
	var bargain: Dictionary = _fixture(package, "DH-FIX-003")
	var inherited: Dictionary = _fixture(package, "DH-FIX-007")
	_expect(
		bargain.get("trace_id") == "DH-IS-007" and bargain.get("storyboard_id") == "DH-UI-007",
		"DH-FIX-003 retains the governed bargain binding",
	)
	_expect(
		inherited.get("trace_id") == "DH-IS-016" and inherited.get("storyboard_id") == "DH-UI-016",
		"DH-FIX-007 uses the authorized inherited-state binding",
	)


func _test_neutral_shield_precedes_private_request() -> void:
	var shell: DrownedHarborControlledPrivateShieldShell = _new_shell()
	var request: Dictionary = _request("DH-FIX-003")
	var begun: Dictionary = shell.begin_handoff(request)
	_expect(begun.get("accepted", false), "bargain handoff begins")
	var audit: Array[String] = shell._lifecycle_audit_snapshot()
	_expect(
		(
			audit.find("neutral_shield_entered_before_private_request")
			< audit.find("private_payload_requested")
		),
		"neutral shield commits before private payload request",
	)
	_expect(
		(
			audit.find("private_payload_requested")
			< audit.find("private_payload_revealed_on_authorized_surface")
		),
		"private request precedes authorized-surface reveal",
	)
	shell.free()


func _test_bargain_authorized_reveal_and_acknowledgement() -> void:
	var shell: DrownedHarborControlledPrivateShieldShell = _new_shell()
	var request: Dictionary = _request("DH-FIX-003")
	_expect(shell.begin_handoff(request).get("accepted", false), "DH-FIX-003 reveal succeeds")
	var private_snapshot: Dictionary = shell.private_surface_snapshot()
	_expect(
		PRIVATE_MARKER in JSON.stringify(private_snapshot, "", true),
		"authorized private abstraction receives exact bargain fixture terms",
	)
	_expect(
		private_snapshot.get("focus") == "private_surface_identity",
		"bargain default focus is not confirm",
	)
	_arm_acknowledgement(shell, 4)
	var acknowledged: Dictionary = shell.acknowledge(_ack_request(request))
	_expect(
		acknowledged.get("accepted", false), "explicit current bargain acknowledgement succeeds"
	)
	_expect(shell._prototype_commit_count() == 1, "bargain commits no more than once")
	_expect(shell.private_state_cleared(), "bargain payload clears before public restoration")
	_expect(shell.restore_public().get("accepted", false), "sanitized bargain resolution restores")
	_expect(shell._public_event_count_snapshot() == 1, "sanitized bargain public event emits once")
	shell.free()


func _test_inherited_state_authorized_reveal_and_acknowledgement() -> void:
	var shell: DrownedHarborControlledPrivateShieldShell = _new_shell()
	var request: Dictionary = _request("DH-FIX-007")
	_expect(shell.begin_handoff(request).get("accepted", false), "DH-FIX-007 reveal succeeds")
	var private_snapshot: Dictionary = shell.private_surface_snapshot()
	_expect(
		private_snapshot.get("focus") == "assigned_seat_identity",
		"inherited-state default focus is not acknowledgement",
	)
	var payload: Dictionary = private_snapshot.get("payload", {})
	for field: String in [
		"objective",
		"inventory",
		"condition",
		"surrogate_recap",
		"obligations",
	]:
		_expect(payload.has(field), "inherited private payload includes %s" % field)
	_arm_acknowledgement(shell, 6)
	var acknowledged: Dictionary = shell.acknowledge(_ack_request(request))
	_expect(
		acknowledged.get("accepted", false), "explicit inherited-state acknowledgement succeeds"
	)
	_expect(shell.private_state_cleared(), "inherited private state clears before transfer")
	_expect(shell.restore_public().get("accepted", false), "public takeover result restores")
	_expect(shell._prototype_commit_count() == 1, "takeover authorization commits once")
	shell.free()


func _test_shield_is_information_neutral_with_voice_disabled() -> void:
	var shell: DrownedHarborControlledPrivateShieldShell = _new_shell()
	shell.set_voice_enabled(false)
	shell.begin_handoff(_request("DH-FIX-007"))
	var snapshot: Dictionary = shell.public_snapshot()
	_expect(snapshot.get("public_text") == "PRIVATE REVIEW IN PROGRESS", "shield text is exact")
	_expect(snapshot.get("caption") == "PRIVATE REVIEW IN PROGRESS", "caption is neutral")
	_expect(snapshot.get("color") == "neutral_shield", "shield color is neutral")
	_expect(snapshot.get("icon") == "none", "shield uses no revealing icon")
	_expect(snapshot.get("animation") == "none", "shield uses no revealing animation")
	_expect(snapshot.get("seat_rail", []).is_empty(), "shield shows no seat emphasis")
	_expect(snapshot.get("focus") == "private_review_notice", "public focus is not confirm")
	_expect(snapshot.get("shared_audio_requests", []).is_empty(), "shield requests no shared audio")
	_expect(
		snapshot.get("timing") == "deterministic_fixture_state_only",
		"shield exposes no timing hint or wall-clock authority",
	)
	_expect(
		not snapshot.get("voice_enabled", true),
		"critical neutral guidance remains text-readable with voice disabled",
	)
	var lower: String = JSON.stringify(snapshot, "", true).to_lower()
	for hint: String in [
		"seat_07",
		"bargain",
		"objective",
		"inventory",
		"faction",
		"benefit",
		"cost",
		"accept",
		"result_revision",
	]:
		_expect(hint not in lower, "shield excludes %s hint" % hint)
	shell.free()


func _test_private_values_never_enter_public_outputs() -> void:
	for fixture_id: String in ["DH-FIX-003", "DH-FIX-007"]:
		var shell: DrownedHarborControlledPrivateShieldShell = _new_shell()
		var request: Dictionary = _request(fixture_id)
		shell.begin_handoff(request)
		_arm_acknowledgement(shell, 4 if fixture_id == "DH-FIX-003" else 6)
		shell.acknowledge(_ack_request(request))
		shell.restore_public()
		var public_bundle: Dictionary = {
			"outputs": shell.privacy_outputs(),
			"snapshot": shell.public_snapshot(),
		}
		_expect(
			PRIVATE_MARKER not in JSON.stringify(public_bundle, "", true),
			"%s private payload stays outside all public channels" % fixture_id,
		)
		shell.free()


func _test_application_private_state_clears_before_public_restore() -> void:
	var shell: DrownedHarborControlledPrivateShieldShell = _new_shell()
	var request: Dictionary = _request("DH-FIX-007")
	shell.begin_handoff(request)
	_arm_acknowledgement(shell, 6)
	shell.acknowledge(_ack_request(request))
	var clearing: Dictionary = shell.clearing_snapshot()
	for field: String in clearing:
		_expect(clearing[field] == true, "clearing sequence empties %s" % field)
	_expect(shell.mode_name() == "restoring", "clearing completes before public restore")
	shell.free()


func _test_deterministic_repeated_inputs_are_byte_equivalent() -> void:
	var first: DrownedHarborControlledPrivateShieldShell = _new_shell()
	var second: DrownedHarborControlledPrivateShieldShell = _new_shell()
	var request: Dictionary = _request("DH-FIX-003")
	first.begin_handoff(request)
	second.begin_handoff(request)
	first.navigate_private(1)
	second.navigate_private(1)
	_expect(
		(
			JSON.stringify(first.public_snapshot(), "", true)
			== JSON.stringify(second.public_snapshot(), "", true)
		),
		"identical shield inputs produce byte-equivalent public output",
	)
	_expect(
		(
			JSON.stringify(first.private_surface_snapshot(), "", true)
			== JSON.stringify(second.private_surface_snapshot(), "", true)
		),
		"identical authorized inputs produce byte-equivalent private output",
	)
	first.free()
	second.free()


func _test_presentation_and_help_consume_no_rng() -> void:
	var shell: DrownedHarborControlledPrivateShieldShell = _new_shell()
	shell.begin_handoff(_request("DH-FIX-003"))
	var before: Dictionary = shell.fixture_signature()
	shell.navigate_private(1)
	shell.open_help()
	shell.navigate_private(-1)
	_expect(shell.fixture_signature() == before, "focus and Help consume no RNG or source state")
	_expect(before.get("rng_cursor") == 9, "bargain RNG cursor remains governed value 9")
	shell.free()


func _test_exactly_once_and_duplicate_acknowledgement() -> void:
	var shell: DrownedHarborControlledPrivateShieldShell = _new_shell()
	var request: Dictionary = _request("DH-FIX-003")
	shell.begin_handoff(request)
	_arm_acknowledgement(shell, 4)
	var ack: Dictionary = _ack_request(request)
	_expect(shell.acknowledge(ack).get("accepted", false), "first acknowledgement succeeds")
	var repeated: Dictionary = shell.acknowledge(ack)
	_expect(not repeated.get("accepted", true), "duplicate acknowledgement fails closed")
	_expect(shell._prototype_commit_count() == 1, "duplicate acknowledgement creates no commit")
	shell.restore_public()
	_expect(shell._public_event_count_snapshot() == 1, "public event remains exactly once")
	shell.free()


func _test_fail_closed_request_matrix() -> void:
	var cases: Array[Dictionary] = []
	var base: Dictionary = _request("DH-FIX-007")
	var stale: Dictionary = base.duplicate(true)
	stale.source_revision = 70
	cases.append({"code": "stale_source_revision", "request": stale})
	var wrong_seat: Dictionary = base.duplicate(true)
	wrong_seat.stable_seat_id = "seat_06"
	cases.append({"code": "wrong_stable_seat", "request": wrong_seat})
	var wrong_authority: Dictionary = base.duplicate(true)
	wrong_authority.controller_authority_id = "other_controller_authority"
	cases.append({"code": "wrong_controller_authority", "request": wrong_authority})
	var wrong_actor: Dictionary = base.duplicate(true)
	wrong_actor.actor_kind = "spectator"
	cases.append({"code": "wrong_controller_authority", "request": wrong_actor})
	var unknown: Dictionary = base.duplicate(true)
	unknown.handoff_id = "unknown_handoff"
	cases.append({"code": "unknown_handoff", "request": unknown})
	var malformed: Dictionary = base.duplicate(true)
	malformed.erase("trace_id")
	cases.append({"code": "malformed_handoff", "request": malformed})
	var expired: Dictionary = base.duplicate(true)
	expired.current_counter = 7
	cases.append({"code": "expired_handoff", "request": expired})
	for case: Dictionary in cases:
		var shell: DrownedHarborControlledPrivateShieldShell = _new_shell()
		var rejected: Dictionary = shell.begin_handoff(case.request)
		_expect(not rejected.get("accepted", true), "%s request fails closed" % case.code)
		_expect(rejected.get("code") == case.code, "%s code is explicit" % case.code)
		_expect(shell._prototype_commit_count() == 0, "%s commits nothing" % case.code)
		_expect(shell.private_state_cleared(), "%s retains no private payload" % case.code)
		shell.free()


func _test_private_surface_unavailable_and_no_phone_fallback() -> void:
	var shell: DrownedHarborControlledPrivateShieldShell = _new_shell()
	var rejected: Dictionary = shell.begin_handoff(_request("DH-FIX-003"), false)
	_expect(
		rejected.get("code") == "private_surface_unavailable", "unavailable surface fails closed"
	)
	_expect(
		shell.public_snapshot().get("public_text") == "PRIVATE REVIEW IN PROGRESS",
		"fallback remains neutral"
	)
	_expect(shell._prototype_commit_count() == 0, "no-phone fallback commits nothing")
	_expect(shell.private_surface_snapshot().is_empty(), "no-phone fallback exposes no terms")
	_expect(
		shell.cancel_or_defer().get("accepted", false), "no-phone fallback permits safe deferral"
	)
	shell.free()


func _test_disconnect_and_reconnect_matrix() -> void:
	var before: DrownedHarborControlledPrivateShieldShell = _new_shell()
	_expect(
		before.handle_disconnect().get("private_state_cleared", false),
		"disconnect before reveal is safe"
	)
	before.free()

	var during: DrownedHarborControlledPrivateShieldShell = _new_shell()
	var current: Dictionary = _request("DH-FIX-007")
	during.begin_handoff(current)
	_expect(
		during.handle_disconnect().get("private_state_cleared", false),
		"disconnect during reveal clears"
	)
	_expect(during.begin_handoff(current).get("accepted", false), "current handoff reconnects")
	during.handle_disconnect()
	var stale: Dictionary = current.duplicate(true)
	stale.handoff_revision = 0
	_expect(not during.begin_handoff(stale).get("accepted", true), "stale reconnect fails closed")
	during.free()

	var after: DrownedHarborControlledPrivateShieldShell = _new_shell()
	after.begin_handoff(current)
	_arm_acknowledgement(after, 6)
	after.acknowledge(_ack_request(current))
	_expect(
		after.handle_disconnect().get("private_state_cleared", false),
		"disconnect after ack stays clear"
	)
	_expect(after._prototype_commit_count() == 1, "post-ack disconnect does not recommit")
	_expect(
		after.restore_public().get("accepted", false),
		"post-ack reconnect restores sanitized result"
	)
	after.free()


func _test_cancellation_and_interruption_clear_state() -> void:
	var cancelled: DrownedHarborControlledPrivateShieldShell = _new_shell()
	cancelled.begin_handoff(_request("DH-FIX-003"))
	_expect(cancelled.cancel_or_defer().get("accepted", false), "cancellation succeeds")
	_expect(cancelled.private_state_cleared(), "cancellation clears private state")
	_expect(cancelled._prototype_commit_count() == 0, "cancellation commits nothing")
	cancelled.free()

	var interrupted: DrownedHarborControlledPrivateShieldShell = _new_shell()
	interrupted.begin_handoff(_request("DH-FIX-007"))
	_expect(interrupted.interrupt_presentation().get("accepted", false), "interruption is handled")
	_expect(interrupted.private_state_cleared(), "interruption clears private state")
	interrupted.free()


func _test_public_restoration_failure_recovers_deterministically() -> void:
	var shell: DrownedHarborControlledPrivateShieldShell = _new_shell()
	var request: Dictionary = _request("DH-FIX-003")
	shell.begin_handoff(request)
	_arm_acknowledgement(shell, 4)
	shell.acknowledge(_ack_request(request))
	var failed: Dictionary = shell.restore_public(false)
	_expect(failed.get("code") == "public_restoration_failed", "restore failure is explicit")
	_expect(failed.get("private_state_cleared", false), "restore failure retains clearing")
	_expect(shell.restore_public(true).get("accepted", false), "deterministic retry restores")
	_expect(shell._prototype_commit_count() == 1, "restore retry does not recommit")
	shell.free()


func _test_new_handoff_requires_and_inherits_clear_state() -> void:
	var shell: DrownedHarborControlledPrivateShieldShell = _new_shell()
	shell.begin_handoff(_request("DH-FIX-003"))
	var prior_term: String = str(
		shell.private_surface_snapshot().get("payload", {}).get("term_id", "")
	)
	var rejected: Dictionary = shell.begin_handoff(_request("DH-FIX-007"))
	_expect(
		rejected.get("code") == "uncleared_private_payload", "new handoff rejects uncleared payload"
	)
	shell.interrupt_presentation()
	_expect(
		shell.begin_handoff(_request("DH-FIX-007")).get("accepted", false),
		"cleared next handoff begins"
	)
	var next_payload: String = JSON.stringify(shell.private_surface_snapshot(), "", true)
	_expect(
		not prior_term.is_empty() and prior_term not in next_payload,
		"next handoff inherits no prior payload"
	)
	shell.free()


func _test_inherited_state_preserves_stable_seat_and_evolved_state() -> void:
	var adapter: DrownedHarborControlledPrivateFixtureAdapter = ADAPTER_SCRIPT.new()
	var request: Dictionary = _request("DH-FIX-007")
	var projected: Dictionary = adapter.load_and_project(request)
	_expect(projected.get("accepted", false), "inherited-state projection succeeds")
	var seat: Dictionary = projected.get("stable_seat_snapshot", {})
	_expect(seat.get("seat_id") == "seat_07", "stable seat remains seat_07")
	_expect(seat.get("condition") == "injured", "injury is not healed")
	_expect(seat.get("health") == 2, "health is not reset")
	_expect(seat.get("inventory_count") == 1, "inventory is not restored")
	_expect(seat.get("history_count") == 8, "history is not erased")
	_expect(
		seat.get("ending_identity") == "seat_07_existing_ending_identity",
		"ending identity is unchanged",
	)
	_expect(projected.get("rng_cursor") == 21, "takeover rerolls nothing")
	adapter.clear_loaded_fixture()


func _test_controller_ownership_and_semantic_mappings() -> void:
	var request: Dictionary = _request("DH-FIX-007")
	_expect(
		request.get("actor_kind") == "approved_takeover_controller",
		"inherited handoff uses governed takeover authority",
	)
	for action: String in [
		"ui_navigate_left",
		"ui_navigate_right",
		"ui_navigate_up",
		"ui_navigate_down",
		"ui_confirm",
		"ui_cancel_action",
	]:
		var has_key: bool = false
		var has_controller: bool = false
		for event: InputEvent in InputMap.action_get_events(action):
			has_key = has_key or event is InputEventKey
			has_controller = (
				has_controller or event is InputEventJoypadButton or event is InputEventJoypadMotion
			)
		_expect(has_key, "%s retains keyboard development fallback" % action)
		_expect(has_controller, "%s retains controller-first mapping" % action)


func _test_production_and_export_boundaries() -> void:
	var catalog: Dictionary = _read_json(CATALOG_PATH)
	_expect(catalog.get("entries", []).size() == 1, "production contains exactly one Tale")
	_expect(
		catalog.get("default_tale_id") == "lantern_house_vertical_slice",
		"Lantern House remains production default",
	)
	_expect(
		"drowned_harbor" not in JSON.stringify(catalog, "", true).to_lower(),
		"production catalog contains no Drowned Harbor entry",
	)
	_expect(
		"drowned_harbor" not in FileAccess.get_file_as_string(PROVIDER_PATH).to_lower(),
		"production provider contains no Drowned Harbor entry",
	)
	var presets: String = FileAccess.get_file_as_string(EXPORT_PRESETS_PATH)
	_expect(presets.count("tests/*") == 2, "ordinary Windows and Linux exports exclude tests")
	for filename: String in [
		"controlled_private_fixture_adapter.gd",
		"controlled_private_surface.gd",
		"controlled_private_shield_shell.gd",
		"controlled_private_shield_shell.tscn",
		"drowned_harbor_controlled_private_shield_test.gd",
	]:
		_expect(filename not in presets, "export presets do not include %s" % filename)
	var manifest: Dictionary = _read_json(MANIFEST_PATH)
	_expect(
		not manifest.get("playable_export_authorized", true),
		"prototype export remains unauthorized"
	)
	_expect(not manifest.get("human_evidence_claimed", true), "automation claims no human evidence")


func _test_scene_is_test_only_and_instantiable() -> void:
	_expect(SHELL_SCENE_PATH.begins_with("res://tests/"), "controlled-private scene is test-only")
	var packed: PackedScene = load(SHELL_SCENE_PATH)
	_expect(packed != null, "controlled-private shield scene loads")
	if packed == null:
		return
	var instance: Node = packed.instantiate()
	_expect(
		instance is DrownedHarborControlledPrivateShieldShell,
		"scene root uses the bounded controlled-private shell",
	)
	instance.free()


func _request(fixture_id: String) -> Dictionary:
	return DrownedHarborControlledPrivateFixtureAdapter.authorized_request_for(fixture_id)


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


func _arm_acknowledgement(
	shell: DrownedHarborControlledPrivateShieldShell,
	steps: int,
) -> void:
	for index: int in range(steps):
		var moved: Dictionary = shell.navigate_private(1)
		_expect(moved.get("accepted", false), "private focus step %d succeeds" % (index + 1))
	_expect(shell.request_acknowledgement().get("accepted", false), "explicit acknowledgement arms")


func _fixture(package: Dictionary, fixture_id: String) -> Dictionary:
	for value: Variant in package.get("fixtures", []):
		if value is Dictionary and value.get("fixture_id") == fixture_id:
			return value
	return {}


func _read_json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:
		return parsed
	return {}


func _new_shell() -> DrownedHarborControlledPrivateShieldShell:
	return SHELL_SCRIPT.new()


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
		return
	_failures += 1
	push_error("FAILED: %s" % message)
