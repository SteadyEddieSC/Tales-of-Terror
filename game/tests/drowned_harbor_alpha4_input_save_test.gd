extends SceneTree

const DemoInput = preload("res://src/tales/drowned_harbor/alpha4/demo_input.gd")
const SaveStore = preload("res://src/tales/drowned_harbor/alpha4/demo_save_store.gd")
var _failures: int = 0
var _commands: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_owned_input()
	_test_restore_ownership()
	await _test_semantic_events()
	_test_save_files()
	if _failures == 0:
		print("Alpha4 input and save boundaries passed")
	quit(_failures)


func _test_semantic_events() -> void:
	_commands.clear()
	var router = DemoInput.new()
	router.lobby_open = false
	root.add_child(router)
	await process_frame
	router.command.connect(
		func(action: String, seat: String) -> void: _commands.append("%s:%s" % [seat, action])
	)
	var enter := InputEventKey.new()
	enter.physical_keycode = KEY_ENTER
	enter.pressed = true
	Input.parse_input_event(enter)
	await process_frame
	await process_frame
	router.flush_commands()
	_expect(
		_commands == ["seat_01:confirm"],
		"initial title confirm claims keyboard and enters public menu"
	)
	Input.parse_input_event(enter.duplicate())
	var repeat: InputEventKey = enter.duplicate()
	repeat.echo = true
	Input.parse_input_event(repeat)
	await process_frame
	router.flush_commands()
	_expect(_commands.size() == 1, "held confirm and OS key repeat cannot double-activate menus")
	var release: InputEventKey = enter.duplicate()
	release.pressed = false
	Input.parse_input_event(release)
	await process_frame
	Input.parse_input_event(enter.duplicate())
	await process_frame
	router.flush_commands()
	_expect(_commands.size() == 2, "release rearms the confirm action")
	Input.parse_input_event(release.duplicate())
	await process_frame
	router.free()
	await process_frame


func _test_owned_input() -> void:
	var router = DemoInput.new()
	router.command.connect(
		func(action: String, seat: String) -> void: _commands.append("%s:%s" % [seat, action])
	)
	_expect(
		router.join_device(5, "pad-five", "Pad") == "seat_01", "first controller claims stable seat"
	)
	_expect(
		router.join_device(9, "pad-nine", "Pad") == "seat_02",
		"second controller claims distinct seat"
	)
	router.queue_command(9, "confirm")
	router.queue_command(5, "confirm")
	_expect(not router.queue_command(5, "confirm"), "duplicate same-frame confirm is suppressed")
	router.flush_commands()
	_expect(
		_commands == ["seat_01:confirm", "seat_02:confirm"],
		"same-frame commands use ascending seat arbitration"
	)
	_commands.clear()
	router.lobby_open = false
	router.set_active_seat("seat_02")
	_expect(
		not router.queue_command(5, "confirm"),
		"other seat cannot commit the active player's choice"
	)
	_expect(
		not router.queue_command(5, "private"),
		"other seat cannot open active player's private panel"
	)
	_expect(not router.queue_command(77, "confirm"), "unowned device has no gameplay authority")
	_expect(router.queue_command(9, "confirm"), "active owner can choose")
	router.disconnect_device(9)
	router.flush_commands()
	_expect(_commands.is_empty(), "disconnect clears an already queued choice")
	_expect(router.stable_seats().size() == 2, "disconnect reserves roster slot")
	_expect(
		router.join_device(19, "pad-nine", "Pad reconnected") == "seat_02",
		"reconnect preserves stable seat across device IDs"
	)
	_expect(router.queue_command(19, "confirm"), "reconnected owner regains authority")
	router.free()
	var twins = DemoInput.new()
	twins.join_device(1, "identical-guid", "Pad")
	twins.join_device(2, "identical-guid", "Pad")
	twins.disconnect_device(1)
	twins.disconnect_device(2)
	twins.lobby_open = false
	_expect(
		twins.join_device(8, "identical-guid", "Pad") == "",
		"ambiguous identical controllers cannot claim another seat"
	)
	_expect(
		twins.join_device(2, "identical-guid", "Pad") == "seat_02",
		"same-port identical controller reclaims its reservation"
	)
	twins.free()


func _test_restore_ownership() -> void:
	var router = DemoInput.new()
	router.join_device(3, "pad", "Pad")
	_expect(
		router.add_keyboard_seat() == "seat_02", "keyboard fallback coexists with a physical owner"
	)
	router.disconnect_device(3)
	_expect(
		router.reclaim_with_keyboard("seat_01"),
		"explicit pass-play reclaim restores a disconnected seat"
	)
	router.set_active_seat("seat_01")
	router.lobby_open = false
	_expect(router.queue_command(-1, "confirm"), "keyboard controls reclaimed active seat")
	router.flush_commands()
	router.set_active_seat("seat_02")
	_expect(router.queue_command(-1, "confirm"), "keyboard can pass to next owned seat")
	var before: Array[Dictionary] = router.public_roster()
	_expect(
		not router.set_roster(["seat_01", "seat_01"]).accepted,
		"duplicate restored roster is rejected"
	)
	_expect(router.public_roster() == before, "invalid roster cannot partially change ownership")
	router.reset_roster()
	_expect(
		router.set_roster(PackedStringArray(["seat_01", "seat_02"])).accepted,
		"stable roster can be restored without devices"
	)
	_expect(
		router.public_roster().all(func(row: Dictionary) -> bool: return not row.connected),
		"save does not fabricate device ownership"
	)
	_expect(
		not router.queue_command(-1, "private"), "restored secrets need explicit local ownership"
	)
	_expect(router.begin_reclaim("seat_02"), "restored seat offers explicit controller reclaim")
	_expect(
		router.pending_reclaim_seat() == "seat_02", "public reclaim prompt identifies only its seat"
	)
	_expect(not router.begin_reclaim("invalid"), "invalid reclaim request is rejected")
	_expect(router.pending_reclaim_seat().is_empty(), "invalid reclaim request clears stale target")
	_expect(router.begin_reclaim("seat_02"), "valid reclaim target can be armed again")
	_expect(
		router.reclaim_with_keyboard("seat_01"),
		"restored seat supports explicit keyboard pass-play"
	)
	_expect(
		router.pending_reclaim_seat() == "seat_02", "claiming another seat preserves pending target"
	)
	_expect(router.reclaim_with_keyboard("seat_02"), "keyboard may claim the pending target")
	_expect(router.pending_reclaim_seat().is_empty(), "keyboard claim cancels controller reclaim")
	_expect(not router.begin_reclaim("seat_02"), "an active owner cannot be offered for reclaim")
	var keyboard_owned: Array[Dictionary] = router.public_roster()
	router._reclaim_controller(29)
	_expect(
		router.public_roster() == keyboard_owned, "late controller cannot replace keyboard owner"
	)
	router.reset_roster()
	router.set_roster(PackedStringArray(["seat_01", "seat_02"]))
	_expect(router.begin_reclaim("seat_02"), "fresh reservation can await a controller")
	_expect(
		router.join_device(29, "restore:seat_02", "Reconnected controller") == "seat_02",
		"reconnection can resolve ownership while a reclaim prompt is pending"
	)
	var controller_owned: Array[Dictionary] = router.public_roster()
	router._reclaim_controller(31)
	_expect(
		router.public_roster() == controller_owned,
		"controller reclaim revalidates reservation before assigning a late controller"
	)
	_expect(router.pending_reclaim_seat().is_empty(), "stale controller target is disarmed")
	router.free()
	var full = DemoInput.new()
	for index: int in 8:
		_expect(
			full.add_keyboard_seat() == "seat_%02d" % (index + 1),
			"keyboard supports seat %d" % (index + 1)
		)
	_expect(full.add_keyboard_seat().is_empty(), "ninth player cannot overrun roster")
	full.free()


func _test_save_files() -> void:
	var path: String = "user://alpha4_boundary_test_%d.dat" % OS.get_process_id()
	var store = SaveStore.new(path)
	_expect(not store.has_save(), "fresh slot has no save")
	var seats: Array[String] = ["seat_01", "seat_02"]
	var original: Dictionary = {
		"snapshot_version": 4,
		"revision": 9223372036854770000,
		"seats": seats,
		"history": [{"number": 3, "private": "test-only-private"}],
	}
	_expect(store.write_save(original).accepted, "real file save succeeds")
	var read: Dictionary = store.read_save()
	_expect(
		read.get("accepted", false) and read.get("snapshot") == original,
		"typed snapshot round-trips exact values"
	)
	if read.get("accepted", false):
		_expect(
			read.snapshot.revision is int and read.snapshot.seats.is_typed(),
			"large integers and typed arrays survive disk transport"
		)
	var newer: Dictionary = original.duplicate(true)
	newer.revision = 42
	_expect(
		store.write_save(newer).accepted, "second save commits with previous checkpoint retained"
	)
	var file: FileAccess = FileAccess.open(path, FileAccess.READ_WRITE)
	if file != null:
		file.seek(file.get_length() - 1)
		file.store_8(127)
		file.close()
	else:
		_expect(false, "test can corrupt its own save")
	var recovery: Dictionary = store.read_save()
	_expect(
		recovery.get("recovered_backup", false) and recovery.get("snapshot") == original,
		"checksum corruption recovers previous validated checkpoint"
	)
	var private_object := RefCounted.new()
	_expect(
		not store.write_save({"object": private_object}).accepted,
		"object serialization is prohibited"
	)
	_expect(
		store.read_save().get("snapshot") == original, "failed write preserves recoverable save"
	)
	_expect(store.write_save(newer).accepted, "save can recover after corrupt primary")
	_expect(store.read_save().get("snapshot") == newer, "replacement primary is readable")
	if FileAccess.file_exists(path + ".bak"):
		DirAccess.remove_absolute(path + ".bak")
	file = FileAccess.open(path, FileAccess.READ_WRITE)
	if file != null:
		file.seek(8)
		file.store_32(999)
		file.close()
	var unsupported: Dictionary = store.read_save()
	_expect(
		not unsupported.get("accepted", false) and unsupported.reason == "save_version_unsupported",
		"future disk envelope fails clearly without a backup"
	)
	_expect(
		not unsupported.has("snapshot"),
		"failed reads do not expose partially decoded private payload"
	)
	_expect(
		not SaveStore.new("user://../outside.dat").write_save(original).accepted,
		"save path cannot escape bounded local slot"
	)
	for suffix: String in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)


func _expect(condition: bool, description: String) -> void:
	if not condition:
		_failures += 1
		push_error("FAILED: %s" % description)
