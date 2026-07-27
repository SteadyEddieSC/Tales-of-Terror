extends SceneTree

const ADAPTER_SCRIPT: Script = preload(
	"res://tests/drowned_harbor_dev_only/bellhouse_fixture_adapter.gd"
)
const SHELL_SCRIPT: Script = preload(
	"res://tests/drowned_harbor_dev_only/bellhouse_decision_shell.gd"
)
const DEV_ONLY_SCENE_PATH: String = "res://tests/drowned_harbor_dev_only/"
const SHELL_SCENE_PATH: String = DEV_ONLY_SCENE_PATH + "bellhouse_decision_shell.tscn"
const PRIVATE_MARKER: String = "PRIVATE_"

var _failures: int = 0


func _initialize() -> void:
	_test_deterministic_decision_and_recovery_projection()
	_test_public_outputs_exclude_private_fixture_data()
	_test_adapter_rejects_malformed_and_unauthorized_requests()
	_test_bellhouse_presentation_and_voice_off_text()
	_test_preview_inspect_focus_and_cancel_are_non_mutating()
	_test_confirmation_commits_once_and_reprojects_idempotently()
	_test_confirmation_failures_restore_public_safe_focus()
	_test_independent_fixture_recovery_preserves_bellhouse_state()
	_test_transcript_and_replay_do_not_reexecute_commit()
	_test_controller_and_keyboard_fallback_mappings()
	_test_scene_is_test_only_and_instantiable()
	if _failures == 0:
		print("Drowned Harbor Bellhouse decision and recovery tests passed")
	quit(_failures)


func _test_deterministic_decision_and_recovery_projection() -> void:
	var adapter: DrownedHarborBellhouseFixtureAdapter = ADAPTER_SCRIPT.new()
	var loaded: Dictionary = adapter.load_fixtures()
	_expect(loaded.get("accepted", false), "DH-FIX-002 and DH-FIX-006 load together")
	if not loaded.get("accepted", false):
		return
	var decision_first: Dictionary = adapter.project_decision(adapter.default_decision_request())
	var decision_second: Dictionary = adapter.project_decision(adapter.default_decision_request())
	var recovery_first: Dictionary = adapter.project_recovery(adapter.default_recovery_request())
	var recovery_second: Dictionary = adapter.project_recovery(adapter.default_recovery_request())
	_expect(decision_first.get("accepted", false), "DH-FIX-002 projects")
	_expect(recovery_first.get("accepted", false), "DH-FIX-006 projects")
	_expect(
		JSON.stringify(decision_first, "", true) == JSON.stringify(decision_second, "", true),
		"Bellhouse reprojection is byte-equivalent",
	)
	_expect(
		JSON.stringify(recovery_first, "", true) == JSON.stringify(recovery_second, "", true),
		"recovery reprojection is byte-equivalent",
	)
	_expect(decision_first.get("source_revision") == 21, "Bellhouse source revision is 21")
	_expect(decision_first.get("result_revision") == 22, "Bellhouse result revision is 22")
	_expect(decision_first.get("rng_cursor") == 7, "Bellhouse projection consumes no RNG")
	_expect(decision_first.get("stable_seat_id") == "seat_02", "Bellhouse seat remains seat_02")
	_expect(recovery_first.get("source_revision") == 61, "recovery source revision is 61")
	_expect(recovery_first.get("result_revision") == 61, "recovery result revision is 61")
	_expect(recovery_first.get("rng_cursor") == 18, "recovery projection consumes no RNG")
	_expect(recovery_first.get("stable_seat_id") == "seat_06", "recovery seat remains seat_06")


func _test_public_outputs_exclude_private_fixture_data() -> void:
	var adapter: DrownedHarborBellhouseFixtureAdapter = ADAPTER_SCRIPT.new()
	adapter.load_fixtures()
	var decision: Dictionary = adapter.project_decision(adapter.default_decision_request())
	var recovery: Dictionary = adapter.project_recovery(adapter.default_recovery_request())
	_expect(
		PRIVATE_MARKER not in JSON.stringify(decision, "", true),
		"Bellhouse output excludes every private sentinel",
	)
	_expect(
		PRIVATE_MARKER not in JSON.stringify(recovery, "", true),
		"recovery output excludes every private sentinel",
	)
	_expect(
		decision.get("projection", {}).get("decision_options", []) == ["record_missing_position"],
		"only the governed synthetic Bellhouse priority is exposed",
	)
	_expect(
		recovery.get("projection", {}).get("focus_destination", "") == "move_to_bellhouse_roof",
		"recovery focus targets a governed legal alternative",
	)


func _test_adapter_rejects_malformed_and_unauthorized_requests() -> void:
	var adapter: DrownedHarborBellhouseFixtureAdapter = ADAPTER_SCRIPT.new()
	var loaded: Dictionary = adapter.load_fixtures()
	_expect(loaded.get("accepted", false), "adapter loads before negative requests")
	if not loaded.get("accepted", false):
		return
	var baseline: String = adapter.decision_fingerprint()
	var default_request: Dictionary = adapter.default_decision_request()
	var missing: Dictionary = default_request.duplicate(true)
	missing.erase("intent")
	var extra: Dictionary = default_request.duplicate(true)
	extra["unexpected"] = true
	var unknown_fixture: Dictionary = default_request.duplicate(true)
	unknown_fixture["fixture_id"] = "DH-FIX-999"
	var stale: Dictionary = default_request.duplicate(true)
	stale["source_revision"] = 20
	var actor: Dictionary = default_request.duplicate(true)
	actor["actor_kind"] = "spectator"
	var seat: Dictionary = default_request.duplicate(true)
	seat["stable_seat_id"] = "seat_99"
	var intent: Dictionary = default_request.duplicate(true)
	intent["intent"] = "commit_final_ledger_rule"
	var cases: Array[Dictionary] = [
		{"code": "malformed_request", "request": missing},
		{"code": "malformed_request", "request": extra},
		{"code": "unknown_fixture", "request": unknown_fixture},
		{"code": "stale_source_revision", "request": stale},
		{"code": "unauthorized_actor", "request": actor},
		{"code": "wrong_stable_seat", "request": seat},
		{"code": "unauthorized_intent", "request": intent},
	]
	for case: Dictionary in cases:
		var rejected: Dictionary = adapter.project_decision(case.request)
		_expect(not rejected.get("accepted", true), "%s request fails closed" % case.code)
		_expect(
			str(rejected.get("reason", "")).begins_with("%s:" % case.code),
			"%s request reports the expected code" % case.code,
		)
		_expect(
			adapter.decision_fingerprint() == baseline,
			"%s request does not mutate Bellhouse state" % case.code,
		)


func _test_bellhouse_presentation_and_voice_off_text() -> void:
	var shell: DrownedHarborBellhouseDecisionShell = _new_shell()
	shell.set_voice_enabled(false)
	var snapshot: Dictionary = shell.render_snapshot()
	_expect(snapshot.get("stage") == "BELLHOUSE LEDGER", "Bellhouse stage is explicit")
	_expect(
		(
			"VISIBLE 5" in snapshot.get("ledger_summary", "")
			and "UNRESOLVED 1" in snapshot.get("ledger_summary", "")
		),
		"public Ledger count and unresolved position remain visible",
	)
	_expect(
		(
			"AUDIBLE 6" in snapshot.get("ring_summary", "")
			and "EXTRA RING UNRESOLVED" in snapshot.get("ring_summary", "")
		),
		"public ring evidence remains visible",
	)
	_expect(
		"ACTIVE SEAT_02" in snapshot.get("active_seat_label", ""),
		"active stable-seat authority is visible in text",
	)
	_expect(
		"RECORD MISSING POSITION" in snapshot.get("focus_label", ""),
		"focus is visible without relying on color",
	)
	_expect(
		snapshot.get("persistent_text_when_voice_off", false),
		"objective, caption, option, and consequence persist with voice off",
	)
	_expect(
		snapshot.get("board_geometry", {}).get("kind") == "placeholder_geometry_not_final",
		"Bellhouse geometry remains explicitly placeholder",
	)
	shell.free()


func _test_preview_inspect_focus_and_cancel_are_non_mutating() -> void:
	var shell: DrownedHarborBellhouseDecisionShell = _new_shell()
	var before: Dictionary = shell.fixture_signature()
	var inspected: Dictionary = shell.inspect_selected()
	_expect(inspected.get("accepted", false), "public Ledger inspect succeeds")
	_expect(shell.mode_name() == "inspect", "inspect mode is explicit")
	_expect(shell.fixture_signature() == before, "inspect mutates no fixture state")
	var previewed: Dictionary = shell.preview_selected()
	_expect(previewed.get("accepted", false), "Bellhouse consequence preview succeeds")
	_expect(shell.mode_name() == "preview", "preview mode is explicit")
	_expect(shell.fixture_signature() == before, "preview consumes no RNG")
	var moved: Dictionary = shell.dispatch_semantic_action("ui_navigate_right")
	_expect(moved.get("accepted", false), "deterministic focus movement succeeds")
	_expect(moved.get("focus_index") == 0, "single governed option retains deterministic focus")
	_expect(shell.fixture_signature() == before, "focus movement mutates nothing")
	shell.request_confirmation()
	var cancelled: Dictionary = shell.cancel()
	_expect(cancelled.get("accepted", false), "cancel succeeds")
	_expect(shell.mode_name() == "decision", "cancel restores the Bellhouse decision")
	_expect(shell.fixture_signature() == before, "cancel consumes no RNG")
	_expect(shell.prototype_commit_count() == 0, "cancel creates no prototype commit")
	shell.free()


func _test_confirmation_commits_once_and_reprojects_idempotently() -> void:
	var shell: DrownedHarborBellhouseDecisionShell = _new_shell()
	var emitted: Array[Dictionary] = []
	shell.prototype_intent_emitted.connect(
		func(payload: Dictionary) -> void: emitted.append(payload)
	)
	var before: Dictionary = shell.fixture_signature()
	var requested: Dictionary = shell.request_confirmation()
	_expect(requested.get("accepted", false), "first confirm opens a pending seam")
	_expect(shell.mode_name() == "confirmation", "confirmation state is explicit")
	_expect(shell.fixture_signature() == before, "confirmation request mutates nothing")
	var committed: Dictionary = (
		shell
		. confirm_pending(
			21,
			"seat_02",
			"active_stable_seat",
			"record_missing_position",
		)
	)
	_expect(committed.get("accepted", false), "valid current confirmation is accepted")
	_expect(not committed.get("reprojected", true), "first confirmation is not a replay")
	_expect(shell.prototype_commit_count() == 1, "prototype commit count becomes one")
	_expect(emitted.size() == 1, "governed public event is emitted once")
	_expect(
		emitted[0].get("event_key") == "bellhouse_decision_committed",
		"governed Bellhouse event key is used",
	)
	_expect(
		not emitted[0].get("production_authority", true),
		"prototype commit creates no production authority",
	)
	_expect(shell.fixture_signature() == before, "commit seam consumes no fixture RNG")
	var repeated: Dictionary = (
		shell
		. confirm_pending(
			21,
			"seat_02",
			"active_stable_seat",
			"record_missing_position",
		)
	)
	_expect(repeated.get("accepted", false), "same confirmation reprojects existing result")
	_expect(repeated.get("reprojected", false), "repeat is marked as reprojection")
	_expect(shell.prototype_commit_count() == 1, "repeat creates no second commit")
	_expect(emitted.size() == 1, "repeat emits no second governed event")
	shell.free()


func _test_confirmation_failures_restore_public_safe_focus() -> void:
	_assert_confirmation_failure(
		"stale_confirmation_revision",
		20,
		"seat_02",
		"active_stable_seat",
		"record_missing_position",
	)
	_assert_confirmation_failure(
		"wrong_confirmation_authority",
		21,
		"seat_99",
		"active_stable_seat",
		"record_missing_position",
	)
	_assert_confirmation_failure(
		"unauthorized_confirmation_actor",
		21,
		"seat_02",
		"spectator",
		"record_missing_position",
	)
	_assert_confirmation_failure(
		"unavailable_confirmation_option",
		21,
		"seat_02",
		"active_stable_seat",
		"unavailable_priority",
	)
	_assert_confirmation_failure(
		"changed_confirmation_option",
		21,
		"seat_02",
		"active_stable_seat",
		"alternate_public_priority",
		["record_missing_position", "alternate_public_priority"],
	)


func _test_independent_fixture_recovery_preserves_bellhouse_state() -> void:
	var shell: DrownedHarborBellhouseDecisionShell = _new_shell()
	var decision_before: Dictionary = shell.fixture_signature()
	var recovery_before: Dictionary = shell.recovery_fixture_signature()
	var recovered: Dictionary = shell.project_fixture_recovery()
	_expect(recovered.get("accepted", false), "DH-FIX-006 recovery projection succeeds")
	var snapshot: Dictionary = shell.render_snapshot()
	_expect(shell.mode_name() == "fixture_recovery", "recovery fixture mode is explicit")
	_expect(
		"ACTIVE SEAT_06" in snapshot.get("active_seat_label", ""),
		"independent recovery fixture retains seat_06",
	)
	_expect(
		snapshot.get("focus_destination") == "move_to_bellhouse_roof",
		"recovery restores deterministic legal focus",
	)
	_expect(
		snapshot.get("legal_alternatives", []).has("move_to_bellhouse_roof"),
		"recovery focus remains a current legal alternative",
	)
	_expect(not snapshot.get("state_changed", true), "recovery states that no state changed")
	_expect(not snapshot.get("rng_changed", true), "recovery states that no RNG changed")
	_expect(
		PRIVATE_MARKER not in JSON.stringify(snapshot, "", true),
		"recovery snapshot exposes no hidden legality cause",
	)
	_expect(shell.fixture_signature() == decision_before, "recovery does not contaminate seat_02")
	_expect(
		shell.recovery_fixture_signature() == recovery_before,
		"recovery fixture remains immutable",
	)
	shell.return_to_decision()
	_expect(
		"ACTIVE SEAT_02" in shell.render_snapshot().get("active_seat_label", ""),
		"return restores the preserved Bellhouse authority",
	)
	shell.free()


func _test_transcript_and_replay_do_not_reexecute_commit() -> void:
	var shell: DrownedHarborBellhouseDecisionShell = _new_shell()
	shell.request_confirmation()
	shell.confirm_pending(21, "seat_02", "active_stable_seat", "record_missing_position")
	var before: Dictionary = shell.fixture_signature()
	var transcript: Dictionary = shell.open_transcript()
	var replay: Dictionary = shell.request_replay()
	_expect(transcript.get("accepted", false), "public transcript intent succeeds")
	_expect(replay.get("accepted", false), "public replay intent succeeds")
	_expect(shell.prototype_commit_count() == 1, "history actions do not repeat commit")
	_expect(shell.fixture_signature() == before, "history actions consume no RNG")
	_expect(
		PRIVATE_MARKER not in JSON.stringify(transcript, "", true),
		"transcript remains public-only",
	)
	_expect(
		PRIVATE_MARKER not in JSON.stringify(replay, "", true),
		"replay remains public-only",
	)
	shell.free()


func _test_controller_and_keyboard_fallback_mappings() -> void:
	for action: String in [
		"ui_navigate_left",
		"ui_navigate_right",
		"ui_navigate_up",
		"ui_navigate_down",
		"ui_confirm",
		"ui_cancel_action",
		"interact",
	]:
		var has_key: bool = false
		var has_controller: bool = false
		for event: InputEvent in InputMap.action_get_events(action):
			has_key = has_key or event is InputEventKey
			has_controller = (
				has_controller or event is InputEventJoypadButton or event is InputEventJoypadMotion
			)
		_expect(has_key, "%s retains keyboard fallback" % action)
		_expect(has_controller, "%s retains controller mapping" % action)


func _test_scene_is_test_only_and_instantiable() -> void:
	_expect(
		SHELL_SCENE_PATH.begins_with("res://tests/"),
		"Bellhouse scene remains under the export-excluded test tree",
	)
	var packed: PackedScene = load(SHELL_SCENE_PATH)
	_expect(packed != null, "Bellhouse decision scene loads")
	if packed == null:
		return
	var instance: Node = packed.instantiate()
	_expect(
		instance is DrownedHarborBellhouseDecisionShell,
		"scene root uses the bounded Bellhouse shell script",
	)
	instance.free()


func _assert_confirmation_failure(
	expected_code: String,
	revision: int,
	seat_id: String,
	actor_kind: String,
	option: String,
	current_options: Array = [],
) -> void:
	var shell: DrownedHarborBellhouseDecisionShell = _new_shell()
	var before: Dictionary = shell.fixture_signature()
	shell.request_confirmation()
	var rejected: Dictionary = (
		shell
		. confirm_pending(
			revision,
			seat_id,
			actor_kind,
			option,
			current_options,
		)
	)
	_expect(not rejected.get("accepted", true), "%s fails closed" % expected_code)
	_expect(rejected.get("code") == expected_code, "%s code is explicit" % expected_code)
	_expect(shell.prototype_commit_count() == 0, "%s commits nothing" % expected_code)
	_expect(shell.fixture_signature() == before, "%s mutates no fixture state" % expected_code)
	var recovery: Dictionary = rejected.get("recovery", {})
	_expect(not recovery.get("state_changed", true), "%s reports no state change" % expected_code)
	_expect(not recovery.get("rng_changed", true), "%s reports no RNG change" % expected_code)
	_expect(
		recovery.get("focus_destination") == "record_missing_position",
		"%s restores the preserved Bellhouse option" % expected_code,
	)
	_expect(
		not recovery.get("stable_seat_reset", true),
		"%s preserves the stable seat" % expected_code,
	)
	_expect(
		PRIVATE_MARKER not in JSON.stringify(recovery, "", true),
		"%s recovery exposes no private data" % expected_code,
	)
	shell.free()


func _new_shell() -> DrownedHarborBellhouseDecisionShell:
	var shell: DrownedHarborBellhouseDecisionShell = SHELL_SCRIPT.new()
	var initialized: Dictionary = shell.initialize_from_fixtures()
	_expect(initialized.get("accepted", false), "Bellhouse shell initializes")
	return shell


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
		return
	_failures += 1
	push_error("FAILED: %s" % message)
