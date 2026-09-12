extends SceneTree

const Demo = preload("res://src/tales/drowned_harbor/alpha4/demo_session.gd")
var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_choice_driven_endings()
	_test_matrix()
	_test_rejection_and_restore()
	_test_connections()
	_test_social_choices()
	_test_social_atomicity()
	_test_objective_boundary()
	_test_content_admission()
	if _failures.is_empty():
		print("Alpha.4 player session: %d checks passed." % _checks)
		quit(0)
	else:
		for failure: String in _failures:
			push_error(failure)
		quit(1)


func _test_choice_driven_endings() -> void:
	var sealed: Demo = _play(101, 1, "cooperative", "seal")
	var released: Demo = _play(101, 1, "cooperative", "release")
	var escaped: Demo = _play(101, 1, "cooperative", "escape")
	var restored: Demo = _play(101, 1, "cooperative", "restore")
	_check(
		sealed.public_view().outcome.get("id") == "harbor_sealed",
		"prepared sealing resolves from player actions"
	)
	_check(
		released.public_view().outcome.get("id") == "drowned_released",
		"records and rescue release the drowned"
	)
	_check(
		escaped.public_view().outcome.get("id") == "last_lifeboat",
		"reserved capacity permits escape"
	)
	_check(
		restored.public_view().outcome.get("id") == "light_comes_home", "oil permits restoration"
	)
	_check(
		sealed.public_view().outcome != released.public_view().outcome,
		"identical seed has different choice-driven endings"
	)


func _test_matrix() -> void:
	for mode: String in ["cooperative", "hidden_betrayer", "outbreak"]:
		var first: int = 1 if mode == "cooperative" else (3 if mode == "hidden_betrayer" else 2)
		for count: int in range(first, 9):
			var first_run: Demo = _play(3101, count, mode, "seal")
			var second_run: Demo = _play(3101, count, mode, "seal")
			_check(first_run.public_view().terminal, "%s/%d reaches terminal" % [mode, count])
			_check(
				first_run.snapshot() == second_run.snapshot(),
				"%s/%d exact deterministic replay" % [mode, count]
			)
			var public_text: String = JSON.stringify(first_run.public_view())
			for private_key: String in [
				"role_instance_id",
				"private_objective_id",
				"faction_objective_id",
				"social_rng",
				"role_assignment_id"
			]:
				_check(
					not public_text.contains(private_key),
					"public projection excludes %s" % private_key
				)


func _test_rejection_and_restore() -> void:
	var session := Demo.new()
	_check(session.start(42, PackedStringArray(["seat_01", "seat_02"])).accepted, "start accepted")
	var before: Dictionary = session.snapshot()
	_check(not session.choose("search_manifest", "seat_02").accepted, "wrong seat rejected")
	_check(not session.choose("invented", "seat_01").accepted, "unknown action rejected")
	_check(session.snapshot() == before, "invalid work leaves authority and RNG unchanged")
	_check(session.choose("search_manifest", "seat_01").accepted, "authored action accepted")
	var json_value: Dictionary = JSON.parse_string(JSON.stringify(session.snapshot()))
	var restored := Demo.new()
	_check(restored.restore(json_value).accepted, "JSON roundtrip save replay succeeds")
	_check(restored.snapshot() == session.snapshot(), "restore is exact")
	var corrupted: Dictionary = json_value.duplicate(true)
	corrupted.records[0].action = "shelter"
	var restored_before: Dictionary = restored.snapshot()
	_check(not restored.restore(corrupted).accepted, "changed record fails digest")
	_check(
		restored.snapshot() == restored_before, "failed restore leaves current session untouched"
	)
	corrupted = json_value.duplicate(true)
	corrupted.version = true
	_check(not restored.restore(corrupted).accepted, "boolean version is not a number")
	corrupted = json_value.duplicate(true)
	corrupted.records.append({"kind": "choice", "action": "search_manifest", "seat": "seat_01"})
	_check(
		not restored.restore(corrupted).accepted, "duplicate or wrong-owner saved choice rejected"
	)


func _test_connections() -> void:
	var session := Demo.new()
	session.start(9, PackedStringArray(["seat_01", "seat_02", "seat_03"]), "hidden_betrayer")
	var private_before: Dictionary = session.private_view("seat_01")
	_check(session.disconnect_seat("seat_01").accepted, "disconnect accepted")
	_check(session.private_view("seat_01").is_empty(), "disconnect shields secrets")
	_check(session.public_view().actions.is_empty(), "disconnected active seat cannot act")
	_check(session.assign_surrogate_control("seat_01").accepted, "surrogate accepted")
	_check(session.private_view("seat_01").is_empty(), "surrogate never receives secrets")
	_check(not session.public_view().actions.is_empty(), "surrogate permits public participation")
	_check(session.reconnect_seat("seat_01").accepted, "reconnect accepted")
	_check(
		session.private_view("seat_01") == private_before,
		"reconnect preserves original role and objective"
	)
	var restored := Demo.new()
	_check(
		restored.restore(JSON.parse_string(JSON.stringify(session.snapshot()))).accepted,
		"connection sequence restores"
	)
	_check(restored.snapshot() == session.snapshot(), "connections restore exact authority state")


func _play(seed_value: int, count: int, mode: String, ending: String) -> Demo:
	var session := Demo.new()
	var seats: PackedStringArray = []
	for index: int in count:
		seats.append("seat_%02d" % (index + 1))
	_check(session.start(seed_value, seats, mode).accepted, "matrix session admitted")
	for step: int in 150:
		var state: Dictionary = session.public_view()
		if state.terminal:
			return session
		if state.actions.is_empty():
			_check(false, "no legal action at %s" % state.stage)
			return session
		var chosen: String = state.actions[0].id
		var priorities: Array[String] = [
			"search_manifest", "search_wreck", "aid_resident", "shelter"
		]
		if state.stage == "bellhouse":
			priorities = ["follow_names"]
		elif state.stage == "council":
			priorities = ["vote_" + ending]
		elif state.stage == "flood":
			priorities.assign(
				["salvage_oil", "shelter"] if ending == "restore" else ["salt_ward", "shelter"]
			)
		elif state.stage == "last_light":
			priorities = ["final_" + ending]
		for preferred: String in priorities:
			var found: bool = false
			for action: Dictionary in state.actions:
				if action.id == preferred:
					chosen = preferred
					found = true
					break
			if found:
				break
		var result: Dictionary = session.choose(chosen, state.active_seat)
		_check(
			result.accepted, "choice %s accepted at %s (%s/%d)" % [chosen, state.stage, mode, count]
		)
		if not result.accepted:
			return session
	_check(false, "bounded route did not complete")
	return session


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(label)


func _test_social_choices() -> void:
	var outbreak := Demo.new()
	outbreak.start(103, PackedStringArray(["seat_01", "seat_02"]), "outbreak")
	_reach_flood(outbreak)
	_check(outbreak.choose("refuse_bargain", "seat_01").accepted, "explicit Outbreak refusal")
	_check(outbreak.private_view("seat_01").refusal_used, "refusal belongs to original seat")
	_check(outbreak.choose("shelter", "seat_02").accepted, "other seat retains turn")
	_check(
		outbreak.choose("harbor_bargain", "seat_01").accepted, "later bargain is a player decision"
	)
	_check(
		outbreak.public_view().roles.tidebound_count == 1,
		"authored Outbreak conversion reaches public form"
	)
	var restless := Demo.new()
	restless.start(107, PackedStringArray(["seat_01"]), "cooperative")
	_reach_flood(restless, true)
	_check(restless.choose("harbor_bargain", "seat_01").accepted, "high-risk bargain committed")
	var view: Dictionary = restless.public_view()
	_check(
		view.actions.any(func(row: Dictionary) -> bool: return row.id == "restless_warn"),
		"defeated witness receives a meaningful continuation"
	)
	_check(restless.choose("restless_warn", "seat_01").accepted, "continuation is player-driven")
	var restored := Demo.new()
	_check(restored.restore(restless.snapshot()).accepted, "social and Director choices restore")


func _reach_flood(session: Demo, risky: bool = false) -> void:
	for step: int in 32:
		var state: Dictionary = session.public_view()
		if state.stage == "flood":
			return
		var choice: String = state.actions[0].id
		if state.stage == "low_tide":
			choice = "salvage_oil" if risky else "shelter"
		_check(
			session.choose(choice, state.active_seat).accepted, "setup uses legal public choices"
		)


func _test_social_atomicity() -> void:
	var outbreak := Demo.new()
	outbreak.start(109, PackedStringArray(["seat_01", "seat_02"]), "outbreak")
	_reach_flood(outbreak)
	_check(outbreak.choose("refuse_bargain", "seat_01").accepted, "first refusal accepted")
	outbreak.choose("refuse_bargain", "seat_02")
	var before: Dictionary = outbreak.snapshot()
	_check(
		not outbreak.choose("refuse_bargain", "seat_01").accepted,
		"repeat refusal cannot grant supplies"
	)
	_check(outbreak.snapshot() == before, "repeat refusal preserves state and role RNG")
	_check(outbreak.choose("harbor_bargain", "seat_01").accepted, "explicit later binding accepted")
	_check(outbreak.public_view().roles.tidebound_count == 1, "one public binding committed")
	_check(
		outbreak.choose("harbor_bargain", "seat_02").accepted,
		"spent binding permits labeled supply-only bargain"
	)
	_check(outbreak.public_view().roles.tidebound_count == 1, "binding budget cannot be bypassed")
	_check(
		not outbreak.private_view("seat_02").has("controlled_reveal"),
		"supply-only bargain leaves no orphan offer"
	)
	var supplies := Demo.new()
	supplies.start(113, PackedStringArray(["seat_01", "seat_02"]), "outbreak")
	_reach_flood(supplies)
	_check(
		supplies.choose("harbor_bargain", "seat_01").accepted,
		"pre-refusal bargain is explicitly supply-only"
	)
	_check(
		not supplies.private_view("seat_01").has("controlled_reveal"),
		"supply bargain opens no private pending offer"
	)
	supplies.choose("shelter", "seat_02")
	_check(
		supplies.choose("refuse_bargain", "seat_01").accepted,
		"explicit refusal remains available after supplies"
	)
	_check(supplies.private_view("seat_01").refusal_used, "role authority records explicit refusal")
	var rollback := Demo.new()
	rollback.start(117, PackedStringArray(["seat_01", "seat_02"]))
	for seat: String in ["seat_01", "seat_02", "seat_01"]:
		rollback.choose("shelter", seat)
	rollback.disconnect_seat("seat_01")
	before = rollback.snapshot()
	_check(
		not rollback.choose("shelter", "seat_02").accepted,
		"phase transition waits for disconnected witness"
	)
	_check(
		rollback.snapshot() == before,
		"whole rejected transition rolls back resource and board work"
	)
	rollback.assign_surrogate_control("seat_01")
	_check(rollback.choose("shelter", "seat_02").accepted, "surrogate restores forward progress")


func _test_objective_boundary() -> void:
	var session := Demo.new()
	session.start(127, PackedStringArray(["seat_01"]))
	for step: int in 40:
		var state: Dictionary = session.public_view()
		if state.stage == "epilogue":
			break
		var choice: String = state.actions[0].id
		if state.stage in ["low_tide", "flood"]:
			choice = "shelter"
		_check(
			session.choose(choice, state.active_seat).accepted,
			"objective test advances through public choices"
		)
	_check(session.public_view().stage == "epilogue", "objective test reaches epilogue")
	_check(
		session.public_view().roles.objective_complete_count == 0,
		"ending does not falsely mark every objective complete"
	)
	_check(session.choose("remember", "seat_01").accepted, "epilogue evaluates actual objectives")
	var own: Dictionary = session.private_view("seat_01")
	var state: Dictionary = session.public_view()
	state.seat_count = 1
	state.ending_id = state.outcome.id
	var expected: bool = DrownedHarborDemoContent.conditions_met(
		state, DrownedHarborDemoContent.OBJECTIVE_CONDITIONS[own.private_objective_id]
	)
	_check(own.objective_complete == expected, "private objective matches authored predicate")


func _test_content_admission() -> void:
	var content = DrownedHarborDemoContent
	_check(content.validate_content().accepted, "complete authored content admitted")
	var actions: Dictionary = content.ACTIONS.duplicate(true)
	actions.search_manifest.cost.dry_matches = -1
	_check(not content.validate_content(actions).accepted, "negative cost fails admission")
	actions = content.ACTIONS.duplicate(true)
	actions.shelter.gain.unknown_resource = 1
	_check(not content.validate_content(actions).accepted, "unknown resource fails admission")
	actions = content.ACTIONS.duplicate(true)
	actions.harbor_bargain.social = "unknown_social_action"
	_check(
		not content.validate_content(actions).accepted, "unsupported social action fails admission"
	)
	actions = content.ACTIONS.duplicate(true)
	actions.refuse_bargain.once_per_seat = 1
	_check(not content.validate_content(actions).accepted, "numeric boolean fails admission")
	var menus: Dictionary = content.MENUS.duplicate(true)
	menus.low_tide.append("missing_action")
	_check(
		not content.validate_content(content.ACTIONS, menus).accepted,
		"unknown menu action fails admission"
	)
	var policies: Array = content.ENDING_POLICIES.duplicate(true)
	policies[0].conditions[0].path = "private_faction_id"
	_check(
		not content.validate_content(content.ACTIONS, content.MENUS, policies).accepted,
		"private ending predicate fails admission"
	)
	var objective_rows: Dictionary = content.OBJECTIVE_CONDITIONS.duplicate(true)
	objective_rows.erase("recover_the_truth")
	_check(
		not (
			content
			. validate_content(
				content.ACTIONS, content.MENUS, content.ENDING_POLICIES, objective_rows
			)
			. accepted
		),
		"missing objective predicate fails admission"
	)
