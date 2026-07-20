class_name VerticalSliceCoordinator
extends RefCounted

signal lifecycle_changed(public_state: Dictionary)
signal session_rejected(reason: String)

const SNAPSHOT_VERSION: int = 1
const MANIFEST_PATH: String = "res://data/scenarios/lantern_house_vertical_slice_v1.json"
const LIFECYCLES: PackedStringArray = [
	"boot_title", "lobby", "confirmation", "briefing", "active_tale", "terminal", "ending"
]

var seat_manager := SeatManager.new()
var manifest: Dictionary = {}
var board_definition: BoardDefinition
var board_state: BoardState
var rules_content: RulesContent
var rules_session: RulesSession
var director_content: DirectorContent
var director_runtime: DirectorRuntime
var social_content: SocialContent
var role_session: RoleSession
var pawn_registry := PawnRegistry.new()
var companion_bridge: CompanionBridge
var lifecycle: String = "boot_title"
var stage_index: int = -1
var operation_index: int = 0
var seed: int = 4706
var requested_mode: String = "hidden_betrayer"
var stage_history: Array[Dictionary] = []
var last_director_decision: Dictionary = {}
var last_director_application: Dictionary = {}
var last_rejection: String = ""
var paused: bool = false


func enter_lobby() -> Dictionary:
	return _transition("boot_title", "lobby")


func confirm_roster() -> Dictionary:
	if lifecycle != "lobby" or active_seats().is_empty():
		return _reject("roster_not_ready")
	return _transition("lobby", "confirmation")


func cancel_setup() -> Dictionary:
	if not lifecycle in ["lobby", "confirmation"]:
		return _reject("invalid_lifecycle_transition")
	_clear_session_authorities()
	lifecycle = "boot_title"
	_emit_state()
	return {"accepted": true}


func initialize_session(
	p_manifest_path: String = MANIFEST_PATH,
	p_seed: int = 4706,
	p_requested_mode: String = "hidden_betrayer",
) -> Dictionary:
	if lifecycle != "confirmation":
		return _reject("invalid_lifecycle_transition")
	var roster: Array[int] = active_seats()
	if roster.is_empty():
		return _reject("empty_roster")
	var build: Dictionary = _build_authorities(p_manifest_path, p_seed, p_requested_mode, roster)
	if not build.accepted:
		return _reject(build.reason)
	_commit_authorities(build, p_seed, p_requested_mode)
	return _transition("confirmation", "briefing")


func _build_authorities(
	p_manifest_path: String, p_seed: int, p_requested_mode: String, roster: Array[int]
) -> Dictionary:
	var candidate_manifest: Dictionary = VerticalSliceManifest.load_file(p_manifest_path)
	var candidate_board := LanternHouseBoardDefinition.new()
	var candidate_rules := LanternHouseRulesContent.new()
	var candidate_director := LanternHouseDirectorContent.new()
	var candidate_social := LanternHouseSocialContent.new()
	var failures: PackedStringArray = (
		VerticalSliceManifest
		. validate(
			candidate_manifest,
			candidate_board,
			candidate_rules,
			candidate_director,
			candidate_social,
		)
	)
	failures.append_array(candidate_board.validate())
	failures.append_array(candidate_rules.validate(candidate_board))
	failures.append_array(candidate_director.validate(candidate_rules, candidate_board))
	failures.append_array(candidate_social.validate(candidate_rules, candidate_board))
	if not failures.is_empty():
		return {"accepted": false, "reason": "invalid_manifest_or_content: %s" % failures[0]}
	var candidate_board_state := BoardState.new(candidate_board)
	var candidate_rules_session := RulesSession.new(
		candidate_rules, candidate_board_state, p_seed, roster
	)
	if candidate_rules_session.content == null:
		return {"accepted": false, "reason": "rules_initialization_failed"}
	var candidate_director_runtime := (
		DirectorRuntime
		. new(
			candidate_director,
			candidate_manifest.director_profile,
			p_seed,
			candidate_rules,
			candidate_board,
		)
	)
	if candidate_director_runtime.profile.is_empty():
		return {"accepted": false, "reason": "director_initialization_failed"}
	var candidate_role_session := RoleSession.new()
	var social_result: Dictionary = candidate_role_session.initialize(
		candidate_social, p_requested_mode, p_seed, roster, candidate_rules, candidate_board
	)
	if not social_result.get("accepted", false):
		return {"accepted": false, "reason": "role_initialization_failed"}
	var candidate_bridge := (
		CompanionBridge
		. new(
			seat_manager,
			candidate_board_state,
			candidate_rules_session,
			candidate_director_runtime,
			candidate_role_session,
		)
	)
	var candidate_pawns := PawnRegistry.new()
	candidate_pawns.sync_seats(seat_manager.get_seats(), ExplorationRoom.SPAWN_POINTS)
	candidate_board_state.sync_occupancy(candidate_pawns.get_pawns())
	return {
		"accepted": true,
		"manifest": candidate_manifest,
		"board_definition": candidate_board,
		"board_state": candidate_board_state,
		"rules_content": candidate_rules,
		"rules_session": candidate_rules_session,
		"director_content": candidate_director,
		"director_runtime": candidate_director_runtime,
		"social_content": candidate_social,
		"role_session": candidate_role_session,
		"companion_bridge": candidate_bridge,
		"pawn_registry": candidate_pawns,
	}


func _commit_authorities(build: Dictionary, p_seed: int, p_requested_mode: String) -> void:
	manifest = build.manifest
	board_definition = build.board_definition
	board_state = build.board_state
	rules_content = build.rules_content
	rules_session = build.rules_session
	director_content = build.director_content
	director_runtime = build.director_runtime
	social_content = build.social_content
	role_session = build.role_session
	companion_bridge = build.companion_bridge
	pawn_registry = build.pawn_registry
	seed = p_seed
	requested_mode = p_requested_mode
	stage_index = -1
	operation_index = 0
	stage_history.clear()
	paused = false
	last_director_decision.clear()
	last_director_application.clear()


func begin_tale() -> Dictionary:
	if lifecycle != "briefing" or manifest.is_empty():
		return _reject("session_not_briefed")
	var result: Dictionary = _transition("briefing", "active_tale")
	if result.accepted:
		stage_index = 0
		operation_index = 0
		_emit_state()
	return result


func run_current_stage() -> Dictionary:
	if paused:
		return _reject("session_paused")
	if lifecycle != "active_tale" or stage_index < 0 or stage_index >= manifest.stages.size():
		return _reject("no_active_stage")
	var before: Dictionary = _authority_snapshot()
	var stage: Dictionary = manifest.stages[stage_index]
	for operation: Dictionary in stage.operations:
		var result: Dictionary = _apply_operation(operation)
		if not result.get("accepted", false):
			_restore_authorities(before)
			return _reject(
				(
					"stage_operation_failed:%s:%s:%s"
					% [stage.id, operation.type, result.get("reason", "rejected")]
				)
			)
	return _finish_stage(stage)


func advance_player_stage() -> Dictionary:
	if paused:
		return _reject("session_paused")
	if lifecycle != "active_tale" or stage_index < 0 or stage_index >= manifest.stages.size():
		return _reject("no_active_stage")
	var stage: Dictionary = manifest.stages[stage_index]
	var before: Dictionary = _authority_snapshot()
	while operation_index < stage.operations.size():
		var operation: Dictionary = stage.operations[operation_index]
		if operation.type in ["submit_prompt", "submit_vote"]:
			operation_index += 1
			if not _pending_responses_complete():
				_emit_state()
				return {"accepted": true, "waiting_for_players": true, "stage_id": stage.id}
			continue
		if (
			operation.type in ["resolve_prompt", "resolve_vote"]
			and not _pending_responses_complete()
		):
			_emit_state()
			return {"accepted": true, "waiting_for_players": true, "stage_id": stage.id}
		var result: Dictionary = _apply_operation(operation)
		if not result.get("accepted", false):
			_restore_authorities(before)
			return _reject(
				(
					"player_stage_operation_failed:%s:%s:%s"
					% [stage.id, operation.type, result.get("reason", "rejected")]
				)
			)
		operation_index += 1
	return _finish_stage(stage)


func review_ending() -> Dictionary:
	return _transition("terminal", "ending")


func toggle_pause() -> Dictionary:
	if lifecycle != "active_tale":
		return _reject("pause_not_available")
	paused = not paused
	_emit_state()
	return {"accepted": true, "paused": paused}


func rematch() -> Dictionary:
	if lifecycle != "ending":
		return _reject("invalid_lifecycle_transition")
	var prior_seed: int = seed
	var prior_mode: String = requested_mode
	var transition: Dictionary = _transition("ending", "confirmation")
	if not transition.accepted:
		return transition
	return initialize_session(MANIFEST_PATH, prior_seed, prior_mode)


func return_to_title() -> Dictionary:
	if lifecycle != "ending":
		return _reject("invalid_lifecycle_transition")
	_close_companion_room()
	_clear_session_authorities()
	seat_manager.reset_all()
	lifecycle = "boot_title"
	_emit_state()
	return {"accepted": true}


func active_seats() -> Array[int]:
	var seats: Array[int] = []
	for seat: Dictionary in seat_manager.get_seats():
		if seat.state in [SeatManager.SeatState.ACTIVE, SeatManager.SeatState.RESERVED]:
			seats.append(seat.seat_number)
	return seats


func public_state() -> Dictionary:
	var stage: Dictionary = {}
	if not manifest.is_empty() and stage_index >= 0 and stage_index < manifest.stages.size():
		stage = manifest.stages[stage_index].duplicate(true)
	return {
		"view_version": 1,
		"scenario_id": manifest.get("scenario_id", "lantern_house_vertical_slice"),
		"lifecycle": lifecycle,
		"stage_index": stage_index,
		"operation_index": operation_index,
		"stage": stage,
		"seat_count": active_seats().size(),
		"mode": role_session.mode_id if role_session != null else requested_mode,
		"fallback_applied": role_session.fallback_applied if role_session != null else false,
		"briefing": manifest.get("briefing", ""),
		"public_objective": manifest.get("public_objective", ""),
		"rules": rules_session.companion_public_view() if rules_session != null else {},
		"roles": role_session.public_view() if role_session != null else {},
		"director": director_runtime.companion_public_view() if director_runtime != null else {},
		"ending": _public_ending() if lifecycle in ["terminal", "ending"] else {},
		"last_rejection": last_rejection,
		"paused": paused,
	}


func to_snapshot() -> Dictionary:
	return {
		"snapshot_version": SNAPSHOT_VERSION,
		"manifest_version": manifest.get("manifest_version", 0),
		"scenario_id": manifest.get("scenario_id", ""),
		"scenario_version": manifest.get("scenario_version", 0),
		"lifecycle": lifecycle,
		"stage_index": stage_index,
		"operation_index": operation_index,
		"seed": seed,
		"requested_mode": requested_mode,
		"paused": paused,
		"stage_history": stage_history.duplicate(true),
		"seat_manager": seat_manager.to_snapshot(),
		"board": board_state.to_snapshot() if board_state != null else {},
		"rules": rules_session.to_snapshot() if rules_session != null else {},
		"director": director_runtime.to_snapshot() if director_runtime != null else {},
		"roles": role_session.to_snapshot() if role_session != null else {},
	}


func restore_snapshot(snapshot: Dictionary) -> Dictionary:
	var before: Dictionary = to_snapshot()
	var validation: Dictionary = _build_restore_candidate(snapshot)
	if not validation.accepted:
		return _reject(validation.reason)
	var seat_result: Dictionary = seat_manager.restore_snapshot(snapshot.seat_manager)
	if not seat_result.accepted:
		return _reject("seat_restore_failed")
	var candidate: VerticalSliceCoordinator = validation.candidate
	manifest = candidate.manifest
	board_definition = candidate.board_definition
	board_state = candidate.board_state
	rules_content = candidate.rules_content
	rules_session = candidate.rules_session
	director_content = candidate.director_content
	director_runtime = candidate.director_runtime
	social_content = candidate.social_content
	role_session = candidate.role_session
	companion_bridge = CompanionBridge.new(
		seat_manager, board_state, rules_session, director_runtime, role_session
	)
	lifecycle = snapshot.lifecycle
	stage_index = snapshot.stage_index
	operation_index = snapshot.operation_index
	seed = snapshot.seed
	requested_mode = snapshot.requested_mode
	paused = snapshot.get("paused", false)
	stage_history = snapshot.stage_history.duplicate(true)
	if before.is_empty():
		return _reject("restore_commit_failed")
	_emit_state()
	return {"accepted": true}


func authority_digest() -> String:
	return JSON.stringify(_canonicalize(_authority_snapshot())).sha256_text()


func public_history_digest() -> String:
	var history: Array[Dictionary] = []
	if rules_session != null:
		history = RulesContent.SessionData.dict_array(rules_session.to_snapshot().history)
	var evidence: Dictionary = {
		"stages": stage_history, "rules": history, "ending": _public_ending()
	}
	return JSON.stringify(_canonicalize(evidence)).sha256_text()


func _canonicalize(value: Variant) -> Variant:
	if value is Array:
		var array: Array = []
		for item: Variant in value:
			array.append(_canonicalize(item))
		return array
	if value is Dictionary:
		var dictionary: Dictionary = {}
		var keys: Array = value.keys()
		keys.sort_custom(func(a: Variant, b: Variant) -> bool: return String(a) < String(b))
		for key: Variant in keys:
			dictionary[String(key)] = _canonicalize(value[key])
		return dictionary
	return value


func _apply_operation(operation: Dictionary) -> Dictionary:
	var result: Dictionary
	match operation.type:
		"queue_event":
			result = rules_session.queue_event(operation.event_id)
		"resolve_event":
			result = rules_session.resolve_next_event()
		"submit_prompt":
			result = rules_session.submit_response(
				active_seats()[0], [operation.option_id], rules_session.pending_prompt.revision
			)
		"resolve_prompt":
			result = rules_session.resolve_prompt()
		"open_vote":
			result = rules_session.open_vote(
				(rules_content as LanternHouseRulesContent).vote_definition(), active_seats()
			)
		"submit_vote":
			result = _submit_fixture_votes(operation)
		"resolve_vote":
			result = rules_session.resolve_vote()
		"resolve_check":
			result = (
				rules_session
				. resolve_check(
					(rules_content as LanternHouseRulesContent).courage_check(),
					active_seats()[0],
					operation.check_id,
				)
			)
		"apply_effects":
			result = _apply_fixture_effects(operation.fixture)
		"play_card":
			result = _play_named_card(active_seats()[0], operation.card_id)
		"director_evaluate":
			result = _evaluate_director()
		"role_transition":
			result = _apply_role_transition(operation)
		"role_action":
			result = _apply_role_action(operation)
		"resolve_outcomes":
			result = role_session.resolve_outcomes(rules_session, board_state)
		"complete_rules":
			result = rules_session.complete(operation.result)
		_:
			result = {"accepted": false, "reason": "unsupported_operation"}
	return result


func _submit_fixture_votes(operation: Dictionary) -> Dictionary:
	for seat: int in active_seats():
		var option: String = operation.odd_option if seat % 2 == 1 else operation.even_option
		var result: Dictionary = rules_session.submit_response(
			seat, [option], rules_session.pending_prompt.revision
		)
		if not result.accepted:
			return result
	return {"accepted": true}


func _apply_fixture_effects(fixture: String) -> Dictionary:
	var effects: Array = []
	if fixture == "reveal_clue":
		effects = [
			{
				"type": "board_mutation",
				"mutation": BoardMutation.feature("lantern_hall", "clue_revealed", true),
			}
		]
	elif fixture == "grant_flame_and_mist":
		effects = [
			{
				"type": "board_mutation",
				"mutation": BoardMutation.hazard("narrow_gallery", "echo_mist", true)
			},
			{"type": "grant_card", "seat": active_seats()[0], "card_id": "steady_flame"},
		]
	elif fixture == "secure_house":
		effects = [
			{"type": "set_flag", "flag_id": "house_secured", "value": true},
			{"type": "set_counter", "counter_id": "objective_progress", "value": 1},
		]
	else:
		return {"accepted": false, "reason": "unknown_fixture"}
	return rules_session.apply_effect_bundle(effects, active_seats()[0], fixture)


func _play_named_card(seat: int, card_id: String) -> Dictionary:
	for card: Dictionary in rules_session.hands.get(seat, []):
		if card.definition_id == card_id:
			return rules_session.play_card(seat, card.instance_id)
	return {"accepted": false, "reason": "card_not_found"}


func _evaluate_director() -> Dictionary:
	var telemetry: Dictionary = DirectorTelemetry.build(rules_session, board_state, role_session)
	last_director_decision = director_runtime.evaluate(telemetry)
	last_director_application = DirectorProposalApplier.apply(
		last_director_decision, rules_session, board_state
	)
	var recorded: Dictionary = director_runtime.record_application(
		last_director_decision, last_director_application
	)
	return recorded if not recorded.get("accepted", false) else {"accepted": true}


func _apply_role_transition(operation: Dictionary) -> Dictionary:
	var seat: int = role_session.seat_with_tag(operation.get("selector_tag", ""))
	if seat <= 0:
		seat = active_seats()[0]
	return role_session.request_transition_by_trigger(
		seat, operation.trigger, rules_session, board_state
	)


func _apply_role_action(operation: Dictionary) -> Dictionary:
	var actor: int = role_session.seat_with_tag(operation.get("selector_tag", ""))
	if actor <= 0:
		return {"accepted": false, "reason": "role_actor_not_found"}
	return role_session.perform_action_by_tag(
		actor, operation.action_tag, [], rules_session, board_state
	)


func _authority_snapshot() -> Dictionary:
	return {
		"board": board_state.to_snapshot() if board_state != null else {},
		"rules": rules_session.to_snapshot() if rules_session != null else {},
		"director": director_runtime.to_snapshot() if director_runtime != null else {},
		"roles": role_session.to_snapshot() if role_session != null else {},
	}


func _restore_authorities(snapshot: Dictionary) -> bool:
	return (
		board_state.restore_snapshot(snapshot.board).accepted
		and rules_session.restore_snapshot(snapshot.rules).accepted
		and director_runtime.restore_snapshot(snapshot.director).accepted
		and role_session.restore_snapshot(snapshot.roles).accepted
	)


func _build_restore_candidate(snapshot: Dictionary) -> Dictionary:
	if (
		snapshot.get("snapshot_version") != SNAPSHOT_VERSION
		or not LIFECYCLES.has(snapshot.get("lifecycle", ""))
		or not snapshot.get("stage_index") is int
		or not snapshot.get("operation_index") is int
		or not snapshot.get("seed") is int
		or not snapshot.get("requested_mode") is String
		or not snapshot.get("paused", false) is bool
		or not snapshot.get("stage_history") is Array
		or not snapshot.get("seat_manager") is Dictionary
	):
		return {"accepted": false, "reason": "malformed_snapshot"}
	var candidate := VerticalSliceCoordinator.new()
	if not candidate.seat_manager.restore_snapshot(snapshot.seat_manager).accepted:
		return {"accepted": false, "reason": "malformed_seat_snapshot"}
	candidate.lifecycle = "confirmation"
	var initialized: Dictionary = candidate.initialize_session(
		MANIFEST_PATH, snapshot.seed, snapshot.requested_mode
	)
	if not initialized.accepted:
		return {"accepted": false, "reason": initialized.get("reason", "restore_failed")}
	if (
		snapshot.get("manifest_version") != candidate.manifest.manifest_version
		or snapshot.get("scenario_id") != candidate.manifest.scenario_id
		or snapshot.get("scenario_version") != candidate.manifest.scenario_version
	):
		return {"accepted": false, "reason": "snapshot_manifest_mismatch"}
	if (
		not candidate.board_state.restore_snapshot(snapshot.get("board", {})).accepted
		or not candidate.rules_session.restore_snapshot(snapshot.get("rules", {})).accepted
		or not candidate.director_runtime.restore_snapshot(snapshot.get("director", {})).accepted
		or not candidate.role_session.restore_snapshot(snapshot.get("roles", {})).accepted
	):
		return {"accepted": false, "reason": "authority_snapshot_rejected"}
	return {"accepted": true, "candidate": candidate}


func _public_ending() -> Dictionary:
	if rules_session == null or role_session == null:
		return {}
	var social: Dictionary = role_session.public_view()
	return {
		"title": manifest.get("ending", {}).get("view", "The House Remembers"),
		"terminal_reason": rules_session.terminal_reason,
		"public_outcome": social.get("outcome", {}),
		"privacy": "public_summary_only_private_details_require_controlled_reveal",
	}


func _transition(expected: String, next: String) -> Dictionary:
	if lifecycle != expected or not LIFECYCLES.has(next):
		return _reject("invalid_lifecycle_transition")
	lifecycle = next
	last_rejection = ""
	_emit_state()
	return {"accepted": true, "lifecycle": lifecycle}


func _clear_session_authorities() -> void:
	manifest.clear()
	board_definition = null
	board_state = null
	rules_content = null
	rules_session = null
	director_content = null
	director_runtime = null
	social_content = null
	role_session = null
	companion_bridge = null
	pawn_registry.clear()
	stage_index = -1
	operation_index = 0
	stage_history.clear()
	paused = false


func _close_companion_room() -> void:
	if companion_bridge != null and companion_bridge.room_open:
		companion_bridge.close_room()


func _finish_stage(stage: Dictionary) -> Dictionary:
	stage_history.append(
		{"index": stage_index, "stage_id": stage.id, "authority_digest": authority_digest()}
	)
	stage_index += 1
	operation_index = 0
	if stage_index >= manifest.stages.size():
		_transition("active_tale", "terminal")
	_emit_state()
	return {"accepted": true, "stage_id": stage.id, "lifecycle": lifecycle}


func _pending_responses_complete() -> bool:
	if rules_session.pending_prompt.is_empty():
		return false
	var eligible: Array = rules_session.pending_prompt.get("eligible_seats", [])
	var responses: Dictionary = rules_session.pending_prompt.get("responses", {})
	return not eligible.is_empty() and responses.size() >= eligible.size()


func _reject(reason: String) -> Dictionary:
	last_rejection = reason
	session_rejected.emit(reason)
	return {"accepted": false, "reason": reason}


func _emit_state() -> void:
	lifecycle_changed.emit(public_state())
