extends SceneTree

const TEST_SEED: int = 4706
const REQUIRED_ACTIONS: PackedStringArray = [
	"ui_navigate_up",
	"ui_navigate_down",
	"ui_navigate_left",
	"ui_navigate_right",
	"ui_confirm",
	"ui_cancel_action",
	"player_join",
	"pause_options",
	"help_accessibility",
	"reset_seats",
	"move_left",
	"move_right",
	"move_up",
	"move_down",
	"interact",
]
const CONTROLLER_ACTIONS: PackedStringArray = REQUIRED_ACTIONS
const SCENE_LOAD_BUDGET_MSEC: int = 5000
const COORDINATOR_BUDGET_MSEC: int = 5000
const SNAPSHOT_BUDGET_MSEC: int = 1000

var _failures: int = 0
var _metrics: Dictionary = {}
var _failing_seed: int = TEST_SEED


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	seed(TEST_SEED)
	print("QUALITY_BASELINE_SEED: ", TEST_SEED)
	_test_input_map()
	await _test_all_production_scenes_load()
	_test_state_transitions_and_snapshots()
	_test_snapshot_rejection_is_atomic()
	_write_report()
	if _failures == 0:
		print("Quality baseline tests passed")
	else:
		print("QUALITY_BASELINE_FAILING_SEED: ", _failing_seed)
	quit(_failures)


func _test_input_map() -> void:
	for action: String in REQUIRED_ACTIONS:
		_expect(InputMap.has_action(action), "required input action exists: %s" % action)
		if not InputMap.has_action(action):
			continue
		var events: Array[InputEvent] = InputMap.action_get_events(action)
		_expect(not events.is_empty(), "required input action is bound: %s" % action)
		if action in CONTROLLER_ACTIONS:
			var has_controller: bool = events.any(
				func(event: InputEvent) -> bool:
					return event is InputEventJoypadButton or event is InputEventJoypadMotion
			)
			_expect(has_controller, "controller binding remains available: %s" % action)


func _test_all_production_scenes_load() -> void:
	var scenes: PackedStringArray = []
	_collect_scenes("res://", scenes)
	scenes.sort()
	_metrics.production_scenes = scenes
	_expect(not scenes.is_empty(), "discovers production scenes")
	var baseline_orphans: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	var scene_times: Dictionary = {}
	for scene_path: String in scenes:
		var started: int = Time.get_ticks_msec()
		var packed: PackedScene = load(scene_path)
		_expect(packed != null, "loads production scene resource: %s" % scene_path)
		if packed == null:
			continue
		var instance: Node = packed.instantiate()
		_expect(instance != null, "instantiates production scene: %s" % scene_path)
		if instance == null:
			continue
		root.add_child(instance)
		await process_frame
		var elapsed: int = Time.get_ticks_msec() - started
		scene_times[scene_path] = elapsed
		_expect(
			elapsed <= SCENE_LOAD_BUDGET_MSEC,
			"scene load stays within broad smoke budget: %s (%d ms)" % [scene_path, elapsed],
		)
		instance.queue_free()
		await process_frame
	_metrics.scene_load_ms = scene_times
	var final_orphans: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	_metrics.orphan_nodes_before = baseline_orphans
	_metrics.orphan_nodes_after = final_orphans
	_expect(
		final_orphans <= baseline_orphans + 2, "scene smoke loop does not grow orphan-node count"
	)


func _collect_scenes(path: String, output: PackedStringArray) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return
	directory.list_dir_begin()
	while true:
		var entry: String = directory.get_next()
		if entry.is_empty():
			break
		if entry.begins_with("."):
			continue
		var child: String = path.path_join(entry)
		if directory.current_is_dir():
			if child.begins_with("res://addons") or child.begins_with("res://tests"):
				continue
			_collect_scenes(child, output)
		elif entry.ends_with(".tscn"):
			output.append(child)
	directory.list_dir_end()


func _test_state_transitions_and_snapshots() -> void:
	var started: int = Time.get_ticks_msec()
	var coordinator := VerticalSliceCoordinator.new()
	coordinator.seat_manager.join_device(0, "quality-fixture-pad", "Quality Fixture Pad")
	_expect(coordinator.enter_lobby().accepted, "title enters lobby")
	_expect(coordinator.confirm_roster().accepted, "lobby confirms roster")
	_expect(
		coordinator.initialize_session(TEST_SEED).accepted,
		"confirmation initializes deterministic session",
	)
	_expect(coordinator.begin_tale().accepted, "briefing enters active Tale")
	var initialize_elapsed: int = Time.get_ticks_msec() - started
	_metrics.coordinator_initialization_ms = initialize_elapsed
	_expect(
		initialize_elapsed <= COORDINATOR_BUDGET_MSEC,
		"coordinator initialization stays within broad smoke budget",
	)
	var snapshot_started: int = Time.get_ticks_msec()
	var snapshot: Dictionary = coordinator.to_snapshot()
	var encoded_once: String = JSON.stringify(snapshot)
	var encoded_twice: String = JSON.stringify(coordinator.to_snapshot())
	_expect(
		encoded_once == encoded_twice, "snapshot serialization is deterministic without mutation"
	)
	var restored := VerticalSliceCoordinator.new()
	var restore_result: Dictionary = restored.restore_snapshot(snapshot)
	_expect(restore_result.accepted, "current snapshot restores")
	_expect(
		restored.to_snapshot() == snapshot,
		"snapshot round trip preserves gameplay-critical state",
	)
	var snapshot_elapsed: int = Time.get_ticks_msec() - snapshot_started
	_metrics.snapshot_round_trip_ms = snapshot_elapsed
	_expect(
		snapshot_elapsed <= SNAPSHOT_BUDGET_MSEC,
		"snapshot round trip stays within broad smoke budget",
	)
	var invalid_before: Dictionary = restored.to_snapshot()
	_expect(not restored.enter_lobby().accepted, "invalid state transition is rejected")
	_expect(restored.to_snapshot() == invalid_before, "invalid transition does not mutate state")


func _test_snapshot_rejection_is_atomic() -> void:
	var source := VerticalSliceCoordinator.new()
	source.seat_manager.join_device(0, "snapshot-fixture-pad", "Snapshot Fixture Pad")
	source.enter_lobby()
	source.confirm_roster()
	source.initialize_session(TEST_SEED)
	var current: Dictionary = source.to_snapshot()
	var targets: Array[Dictionary] = []
	var future: Dictionary = current.duplicate(true)
	future.snapshot_version = 99
	targets.append({"label": "future version", "snapshot": future})
	var missing: Dictionary = current.duplicate(true)
	missing.erase("lifecycle")
	targets.append({"label": "missing required field", "snapshot": missing})
	var unknown: Dictionary = current.duplicate(true)
	unknown.unexpected_future_field = "must_not_be_silently_discarded"
	targets.append({"label": "unknown field", "snapshot": unknown})
	for target: Dictionary in targets:
		var receiver := VerticalSliceCoordinator.new()
		var before: Dictionary = receiver.to_snapshot()
		var result: Dictionary = receiver.restore_snapshot(target.snapshot)
		_expect(not result.accepted, "rejects %s snapshot" % target.label)
		_expect(receiver.to_snapshot() == before, "%s rejection is atomic" % target.label)


func _write_report() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-results"))
	var report := {
		"schema_version": 1,
		"seed": TEST_SEED,
		"failures": _failures,
		"metrics": _metrics,
		"performance_scope": "broad CI smoke thresholds; not representative player hardware",
	}
	var file := FileAccess.open("res://test-results/quality-baseline.json", FileAccess.WRITE)
	if file == null:
		_failures += 1
		print("FAIL: could not write quality baseline report")
		return
	file.store_string(JSON.stringify(report, "  ") + "\n")


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	print("FAIL: ", message)
