extends SceneTree

const ADAPTER_SCRIPT: Script = preload(
	"res://tests/drowned_harbor_dev_only/low_tide_fixture_adapter.gd"
)
const SHELL_SCRIPT: Script = preload(
	"res://tests/drowned_harbor_dev_only/low_tide_shared_screen_shell.gd"
)
const SHELL_SCENE_PATH: String = (
	"res://tests/drowned_harbor_dev_only/low_tide_shared_screen_shell.tscn"
)
const PRIVATE_MARKERS: PackedStringArray = [
	"PRIVATE_",
	"archive_culvert",
	"bellmarked_candidate",
]

var _failures: int = 0


func _initialize() -> void:
	_test_deterministic_public_projection()
	_test_public_outputs_reject_private_fixture_data()
	_test_focus_preview_cancel_and_stable_seat()
	_test_voice_off_persistent_information()
	_test_revision_bound_confirmation()
	_test_transcript_replay_and_recovery_are_public_safe()
	_test_controller_and_keyboard_fallback_mappings()
	_test_scene_is_test_only_and_instantiable()
	if _failures == 0:
		print("Drowned Harbor Low Tide shared-screen shell tests passed")
	quit(_failures)


func _test_deterministic_public_projection() -> void:
	var adapter: DrownedHarborLowTideFixtureAdapter = ADAPTER_SCRIPT.new()
	var loaded: Dictionary = adapter.load_fixture()
	_expect(loaded.get("accepted", false), "DH-FIX-001 loads through the test-only adapter")
	if not loaded.get("accepted", false):
		return
	var first: Dictionary = adapter.project(adapter.default_request())
	var second: Dictionary = adapter.project(adapter.default_request())
	_expect(first.get("accepted", false), "first DH-FIX-001 projection succeeds")
	_expect(second.get("accepted", false), "second DH-FIX-001 projection succeeds")
	_expect(
		JSON.stringify(first, "", true) == JSON.stringify(second, "", true),
		"reprojection is byte-equivalent",
	)
	_expect(first.get("source_revision") == 11, "source revision remains 11")
	_expect(first.get("result_revision") == 12, "projected result revision remains 12")
	_expect(first.get("rng_cursor") == 4, "projection consumes no RNG")
	_expect(first.get("stable_seat_id") == "seat_01", "stable seat remains seat_01")


func _test_public_outputs_reject_private_fixture_data() -> void:
	var adapter: DrownedHarborLowTideFixtureAdapter = ADAPTER_SCRIPT.new()
	adapter.load_fixture()
	var result: Dictionary = adapter.project(adapter.default_request())
	var text: String = JSON.stringify(result, "", true)
	for marker: String in PRIVATE_MARKERS:
		_expect(marker not in text, "public adapter output excludes %s" % marker)
	var projection: Dictionary = result.get("projection", {})
	_expect(
		projection.keys().size() == 9,
		"public projection contains only the approved nine fields",
	)
	_expect(not projection.has("private"), "public projection has no private domain")


func _test_focus_preview_cancel_and_stable_seat() -> void:
	var shell: DrownedHarborLowTideSharedScreenShell = SHELL_SCRIPT.new()
	var initialized: Dictionary = shell.initialize_from_fixture()
	_expect(initialized.get("accepted", false), "shell initializes from DH-FIX-001")
	var before: Dictionary = shell.state_signature()
	var focus_before: String = shell.render_snapshot().get("focus_label", "")
	var moved: Dictionary = shell.dispatch_semantic_action("ui_navigate_right")
	_expect(moved.get("accepted", false), "semantic focus movement succeeds")
	_expect(
		shell.render_snapshot().get("focus_label", "") != focus_before,
		"focus movement has a visible non-color text change",
	)
	_expect(shell.state_signature() == before, "focus movement does not mutate fixture state")
	var inspected: Dictionary = shell.dispatch_semantic_action("interact")
	_expect(inspected.get("accepted", false), "inspect seam succeeds")
	_expect(shell.mode_name() == "inspect", "inspect mode is explicit")
	_expect(shell.state_signature() == before, "inspect consumes no RNG and mutates nothing")
	var replayed: Dictionary = shell.request_replay()
	_expect(replayed.get("accepted", false), "preview/replay seam succeeds")
	_expect(shell.mode_name() == "preview", "preview mode is explicit")
	_expect(shell.state_signature() == before, "preview consumes no RNG and mutates nothing")
	var cancelled: Dictionary = shell.cancel()
	_expect(cancelled.get("accepted", false), "cancel succeeds")
	_expect(shell.mode_name() == "board", "cancel returns to board focus")
	_expect(shell.state_signature() == before, "cancel consumes no RNG and mutates nothing")
	_expect(
		"ACTIVE SEAT_01" in shell.render_snapshot().get("active_seat_label", ""),
		"active stable seat is visible in text",
	)


func _test_voice_off_persistent_information() -> void:
	var shell: DrownedHarborLowTideSharedScreenShell = SHELL_SCRIPT.new()
	shell.initialize_from_fixture()
	shell.set_voice_enabled(false)
	var snapshot: Dictionary = shell.render_snapshot()
	_expect(not snapshot.get("voice_enabled", true), "voice can be disabled")
	_expect(
		snapshot.get("persistent_text_when_voice_off", false),
		"objective, caption, and legal actions persist when voice is off",
	)
	_expect(not snapshot.get("objective", "").is_empty(), "objective remains visible")
	_expect(not snapshot.get("caption", "").is_empty(), "caption remains visible")
	_expect(not snapshot.get("legal_actions", []).is_empty(), "legal actions remain visible")
	_expect(
		"D-PAD / WASD" in snapshot.get("controller_prompts", ""),
		"controller and keyboard prompts remain visible",
	)


func _test_revision_bound_confirmation() -> void:
	var shell: DrownedHarborLowTideSharedScreenShell = SHELL_SCRIPT.new()
	shell.initialize_from_fixture()
	var before: Dictionary = shell.state_signature()
	var requested: Dictionary = shell.dispatch_semantic_action("ui_confirm")
	_expect(requested.get("accepted", false), "first confirm opens an explicit seam")
	_expect(shell.mode_name() == "confirmation", "confirmation mode is explicit")
	_expect(shell.state_signature() == before, "confirmation request mutates nothing")
	var confirmed: Dictionary = shell.confirm_pending(11, "seat_01")
	_expect(confirmed.get("accepted", false), "current-revision confirmation is accepted")
	_expect(
		not confirmed.get("payload", {}).get("authoritative_commit", true),
		"prototype confirmation creates no final gameplay commit",
	)
	_expect(
		confirmed.get("payload", {}).get("revision_bound", false),
		"confirmation is explicitly revision-bound",
	)
	_expect(shell.state_signature() == before, "confirmation seam consumes no RNG")

	var stale_shell: DrownedHarborLowTideSharedScreenShell = SHELL_SCRIPT.new()
	stale_shell.initialize_from_fixture()
	var stale_before: Dictionary = stale_shell.state_signature()
	stale_shell.dispatch_semantic_action("ui_confirm")
	var stale: Dictionary = stale_shell.confirm_pending(10, "seat_01")
	_expect(not stale.get("accepted", true), "stale confirmation fails closed")
	_expect(stale.get("code") == "stale_confirmation_revision", "stale code is explicit")
	_expect(stale_shell.mode_name() == "recovery", "stale request enters recovery")
	_expect(stale_shell.state_signature() == stale_before, "stale request mutates nothing")


func _test_transcript_replay_and_recovery_are_public_safe() -> void:
	var shell: DrownedHarborLowTideSharedScreenShell = SHELL_SCRIPT.new()
	shell.initialize_from_fixture()
	var transcript: Dictionary = shell.open_transcript()
	var replay: Dictionary = shell.request_replay()
	var unknown: Dictionary = shell.dispatch_semantic_action("unknown_action")
	_expect(transcript.get("accepted", false), "transcript-open intent succeeds")
	_expect(replay.get("accepted", false), "replay intent succeeds")
	_expect(not unknown.get("accepted", true), "unknown input fails closed")
	_expect(unknown.get("code") == "unsupported_input", "unknown input code is explicit")
	for value: Dictionary in [transcript, replay, unknown]:
		var text: String = JSON.stringify(value, "", true)
		for marker: String in PRIVATE_MARKERS:
			_expect(marker not in text, "public-safe output excludes %s" % marker)
	_expect(
		"No state, seat, or RNG change occurred."
		in shell.render_snapshot().get("status", ""),
		"recovery message states the no-mutation boundary",
	)


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
				has_controller
				or event is InputEventJoypadButton
				or event is InputEventJoypadMotion
			)
		_expect(has_key, "%s retains keyboard fallback" % action)
		_expect(has_controller, "%s retains controller mapping" % action)


func _test_scene_is_test_only_and_instantiable() -> void:
	_expect(
		SHELL_SCENE_PATH.begins_with("res://tests/"),
		"shell scene remains under the export-excluded test tree",
	)
	var packed: PackedScene = load(SHELL_SCENE_PATH)
	_expect(packed != null, "Low Tide shell scene loads")
	if packed == null:
		return
	var instance: Node = packed.instantiate()
	_expect(
		instance is DrownedHarborLowTideSharedScreenShell,
		"scene root uses the bounded Low Tide shell script",
	)
	instance.free()


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
		return
	_failures += 1
	push_error("FAILED: %s" % message)
