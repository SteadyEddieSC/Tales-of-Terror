class_name VerticalSliceCoordinator
extends RefCounted

signal lifecycle_changed(public_state: Dictionary)
signal session_rejected(reason: String)

const SNAPSHOT_VERSION: int = 2
const DEFAULT_SEED: int = 4706
const DEFAULT_MODE: String = "hidden_betrayer"
const LIFECYCLES: PackedStringArray = [
	"boot_title",
	"lobby",
	"confirmation",
	"tale_library",
	"briefing",
	"active_tale",
	"terminal",
	"ending"
]
const SNAPSHOT_KEYS: PackedStringArray = [
	"snapshot_version",
	"manifest_version",
	"scenario_id",
	"scenario_version",
	"lifecycle",
	"stage_index",
	"operation_index",
	"seed",
	"requested_mode",
	"paused",
	"stage_history",
	"last_director_decision",
	"last_director_application",
	"stage_transaction",
	"seat_manager",
	"pawns",
	"board",
	"rules",
	"director",
	"roles",
]
const TRANSACTION_KEYS: PackedStringArray = [
	"transaction_version",
	"stage_index",
	"operation_index",
	"stage_history",
	"last_director_decision",
	"last_director_application",
	"seat_manager",
	"pawns",
	"board",
	"rules",
	"director",
	"roles",
]

var seat_manager := SeatManager.new()
var tale_package: Dictionary = {}
var tale_package_digest: String = ""
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
var seed: int = DEFAULT_SEED
var requested_mode: String = DEFAULT_MODE
var stage_history: Array[Dictionary] = []
var last_director_decision: Dictionary = {}
var last_director_application: Dictionary = {}
var last_rejection: String = ""
var paused: bool = false
var _stage_checkpoint: Dictionary = {}
var _selection: TaleSelectionState
var _tale_library_flow := TaleLibraryFlow.new()
var _player_interaction_flow := PlayerInteractionFlow.new()


func _init(
	p_catalog_path: String = TaleCatalog.PRODUCTION_PATH,
	p_provider_registry: TaleProviderRegistry = null,
	p_expected_catalog_digest: String = TaleCatalog.PRODUCTION_DIGEST,
) -> void:
	var registry: TaleProviderRegistry = (
		p_provider_registry if p_provider_registry != null else TaleProviderRegistry.new()
	)
	_selection = TaleSelectionState.new(p_catalog_path, registry, p_expected_catalog_digest)
	var result: Dictionary = _selection.load_default()
	if not result.get("accepted", false):
		_tale_library_flow.record_unavailable(
			self, "invalid_tale_catalog:%s" % result.get("reason", "rejected")
		)


func select_tale(tale_id: String) -> Dictionary:
	return _tale_library_flow.select(self, tale_id)


func enter_lobby() -> Dictionary:
	return _transition("boot_title", "lobby")


func confirm_roster() -> Dictionary:
	if lifecycle != "lobby" or active_seats().is_empty():
		return _reject("roster_not_ready")
	return _transition("lobby", "confirmation")


func navigate_tale_library(action: String, value: Variant = null) -> Dictionary:
	return _tale_library_flow.navigate(self, action, value)


func cancel_setup() -> Dictionary:
	if lifecycle == "confirmation":
		return _transition("confirmation", "lobby")
	if lifecycle != "lobby":
		return _reject("invalid_lifecycle_transition")
	if not active_seats().is_empty():
		return _reject("roster_still_assigned")
	_clear_session_authorities()
	lifecycle = "boot_title"
	last_rejection = ""
	_emit_state()
	return {"accepted": true, "lifecycle": lifecycle}


func initialize_session(
	p_seed: int = DEFAULT_SEED,
	p_requested_mode: String = DEFAULT_MODE,
) -> Dictionary:
	return _tale_library_flow.initialize_session(self, p_seed, p_requested_mode)


func _build_authorities(
	entry: Dictionary, p_seed: int, p_requested_mode: String, roster: Array[int]
) -> Dictionary:
	var provider_result: Dictionary = _selection.registry.build_candidate(entry)
	if not provider_result.get("accepted", false):
		return {
			"accepted": false,
			"reason": "invalid_tale_provider:%s" % provider_result.get("reason", "rejected"),
		}
	var candidate_board: BoardDefinition = provider_result.board_definition
	var candidate_rules: RulesContent = provider_result.rules_content
	var candidate_director: DirectorContent = provider_result.director_content
	var candidate_social: SocialContent = provider_result.social_content
	var candidate_manifest: Dictionary = provider_result.manifest
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
	var mode_authorization: Dictionary = VerticalSliceManifest.authorize_mode(
		candidate_manifest, candidate_social, p_requested_mode, roster.size()
	)
	if not mode_authorization.accepted:
		failures.append(mode_authorization.reason)
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
		"tale_package": provider_result.package,
		"tale_package_digest": provider_result.package_digest,
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
	tale_package = build.tale_package
	tale_package_digest = build.tale_package_digest
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
	_stage_checkpoint.clear()


func begin_tale() -> Dictionary:
	if lifecycle != "briefing" or manifest.is_empty():
		return _reject("session_not_briefed")
	var result: Dictionary = _transition("briefing", "active_tale")
	if result.accepted:
		_tale_library_flow.selection_locked = true
		stage_index = 0
		operation_index = 0
		_emit_state()
	return result


func run_current_stage() -> Dictionary:
	if paused:
		return _reject("session_paused")
	if lifecycle != "active_tale" or stage_index < 0 or stage_index >= manifest.stages.size():
		return _reject("no_active_stage")
	return _execute_stage(true)


func advance_player_stage() -> Dictionary:
	if paused:
		return _reject("session_paused")
	if lifecycle != "active_tale" or stage_index < 0 or stage_index >= manifest.stages.size():
		return _reject("no_active_stage")
	return _execute_stage(false)


func submit_player_interaction(seat_number: int, action: String) -> Dictionary:
	return _player_interaction_flow.submit(self, seat_number, action)


func _execute_stage(automated: bool) -> Dictionary:
	var stage: Dictionary = manifest.stages[stage_index]
	if _stage_checkpoint.is_empty():
		_stage_checkpoint = VerticalSliceSnapshotPolicy.transaction_snapshot(self)
	while operation_index < stage.operations.size():
		var operation: Dictionary = stage.operations[operation_index]
		if not automated and operation.type in ["submit_prompt", "submit_vote"]:
			operation_index += 1
			if not _pending_responses_complete():
				_emit_state()
				return {"accepted": true, "waiting_for_players": true, "stage_id": stage.id}
			continue
		if (
			not automated
			and operation.type in ["resolve_prompt", "resolve_vote"]
			and not _pending_responses_complete()
		):
			_emit_state()
			return {"accepted": true, "waiting_for_players": true, "stage_id": stage.id}
		var result: Dictionary = _apply_operation(operation)
		if not result.get("accepted", false):
			VerticalSliceSnapshotPolicy.rollback_stage_transaction(self)
			return _reject(
				(
					"stage_operation_failed:%s:%s:%s"
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
	var roster: Array[int] = active_seats()
	var build: Dictionary = _build_authorities(_selection.entry, seed, requested_mode, roster)
	if not build.accepted:
		return _reject(build.reason)
	_close_companion_room()
	_commit_authorities(build, seed, requested_mode)
	lifecycle = "briefing"
	last_rejection = ""
	_emit_state()
	return {"accepted": true, "lifecycle": lifecycle}


func return_to_title() -> Dictionary:
	if lifecycle != "ending":
		return _reject("invalid_lifecycle_transition")
	return protected_reset_to_title()


func protected_reset_to_title() -> Dictionary:
	_close_companion_room()
	_clear_session_authorities()
	lifecycle = "boot_title"
	seed = DEFAULT_SEED
	requested_mode = DEFAULT_MODE
	last_rejection = ""
	_tale_library_flow.clear_rejection()
	seat_manager.reset_all()
	var selected: Dictionary = _selection.select(_selection.catalog.get("default_tale_id", ""))
	if not selected.get("accepted", false):
		_tale_library_flow.record_unavailable(
			self, selected.get("reason", "default_tale_selection_failed")
		)
	_emit_state()
	return {"accepted": true, "lifecycle": lifecycle}


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
		"scenario_id": manifest.get("scenario_id", _selection.selected_tale_id()),
		"scenario_version": manifest.get("scenario_version", 0),
		"selected_tale_id": _selection.selected_tale_id(),
		"tale_display_name": _selection.metadata.get("display_name", ""),
		"tale_library": _tale_library_flow.public_state(_selection, last_rejection),
		"interaction": _player_interaction_flow.public_state(self),
		"lifecycle": lifecycle,
		"stage_index": stage_index,
		"operation_index": operation_index,
		"stage": stage,
		"seat_count": active_seats().size(),
		"mode": role_session.mode_id if role_session != null else requested_mode,
		"fallback_applied": role_session.fallback_applied if role_session != null else false,
		"briefing": manifest.get("briefing", _selection.metadata.get("briefing", "")),
		"public_objective":
		manifest.get("public_objective", _selection.metadata.get("public_objective", "")),
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
		"last_director_decision": last_director_decision.duplicate(true),
		"last_director_application": last_director_application.duplicate(true),
		"stage_transaction": _stage_checkpoint.duplicate(true),
		"seat_manager": seat_manager.to_snapshot(),
		"pawns": pawn_registry.to_snapshot(),
		"board": board_state.to_snapshot() if board_state != null else {},
		"rules": rules_session.to_snapshot() if rules_session != null else {},
		"director": director_runtime.to_snapshot() if director_runtime != null else {},
		"roles": role_session.to_snapshot() if role_session != null else {},
	}


func restore_snapshot(snapshot: Dictionary) -> Dictionary:
	var validation: Dictionary = _build_restore_candidate(snapshot)
	if not validation.accepted:
		return _reject(validation.reason)
	var candidate: VerticalSliceCoordinator = validation.candidate
	_close_companion_room()
	_adopt_candidate(candidate)
	_emit_state()
	return {"accepted": true}


func _adopt_candidate(candidate: VerticalSliceCoordinator) -> void:
	seat_manager = candidate.seat_manager
	_selection = candidate._selection
	_tale_library_flow = candidate._tale_library_flow
	tale_package = candidate.tale_package
	tale_package_digest = candidate.tale_package_digest
	manifest = candidate.manifest
	board_definition = candidate.board_definition
	board_state = candidate.board_state
	rules_content = candidate.rules_content
	rules_session = candidate.rules_session
	director_content = candidate.director_content
	director_runtime = candidate.director_runtime
	social_content = candidate.social_content
	role_session = candidate.role_session
	companion_bridge = candidate.companion_bridge
	pawn_registry = candidate.pawn_registry
	lifecycle = candidate.lifecycle
	stage_index = candidate.stage_index
	operation_index = candidate.operation_index
	seed = candidate.seed
	requested_mode = candidate.requested_mode
	paused = candidate.paused
	stage_history = candidate.stage_history.duplicate(true)
	last_director_decision = candidate.last_director_decision.duplicate(true)
	last_director_application = candidate.last_director_application.duplicate(true)
	last_rejection = candidate.last_rejection
	_stage_checkpoint = candidate._stage_checkpoint.duplicate(true)


func authority_digest() -> String:
	return JSON.stringify(TalePackage.canonicalize(_authority_snapshot())).sha256_text()


func public_history_digest() -> String:
	var history: Array[Dictionary] = []
	if rules_session != null:
		history = RulesContent.SessionData.dict_array(rules_session.to_snapshot().history)
	var evidence: Dictionary = {
		"stages": stage_history, "rules": history, "ending": _public_ending()
	}
	return JSON.stringify(TalePackage.canonicalize(evidence)).sha256_text()


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
			result = rules_session.open_vote(rules_content.vote_definition(), active_seats())
		"submit_vote":
			result = _submit_fixture_votes(operation)
		"resolve_vote":
			result = rules_session.resolve_vote()
		"resolve_check":
			result = (
				rules_session
				. resolve_check(
					rules_content.check_definition(operation.check_id),
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
		return {"accepted": false, "reason": "role_actor_not_found"}
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
		"seat_manager": seat_manager.to_snapshot(),
		"pawns": pawn_registry.to_snapshot(),
		"board": board_state.to_snapshot() if board_state != null else {},
		"rules": rules_session.to_snapshot() if rules_session != null else {},
		"director": director_runtime.to_snapshot() if director_runtime != null else {},
		"roles": role_session.to_snapshot() if role_session != null else {},
		"last_director_decision": last_director_decision.duplicate(true),
		"last_director_application": last_director_application.duplicate(true),
	}


func _restore_authorities(snapshot: Dictionary) -> bool:
	var accepted: bool = seat_manager.restore_snapshot(snapshot.seat_manager).accepted
	accepted = (
		(
			pawn_registry
			. restore_snapshot(snapshot.pawns, seat_manager.get_seats(), ExplorationRoom.BOUNDS)
			. accepted
		)
		and accepted
	)
	accepted = board_state.restore_snapshot(snapshot.board).accepted and accepted
	accepted = rules_session.restore_snapshot(snapshot.rules).accepted and accepted
	accepted = director_runtime.restore_snapshot(snapshot.director).accepted and accepted
	accepted = role_session.restore_snapshot(snapshot.roles).accepted and accepted
	last_director_decision = snapshot.last_director_decision.duplicate(true)
	last_director_application = snapshot.last_director_application.duplicate(true)
	return accepted


func _build_restore_candidate(snapshot: Dictionary) -> Dictionary:
	if not _snapshot_header_is_valid(snapshot):
		return {"accepted": false, "reason": "malformed_snapshot"}
	var candidate := VerticalSliceCoordinator.new(
		_selection.catalog_path, _selection.registry, _selection.expected_catalog_digest
	)
	if not candidate.seat_manager.restore_snapshot(snapshot.seat_manager).accepted:
		return {"accepted": false, "reason": "malformed_seat_snapshot"}
	if not VerticalSliceSnapshotPolicy.stable_seat_snapshot_is_coherent(candidate.seat_manager):
		return {"accepted": false, "reason": "incoherent_seat_snapshot"}
	if snapshot.lifecycle in ["briefing", "active_tale", "terminal", "ending"]:
		return _build_session_restore_candidate(snapshot, candidate)
	return _build_pre_session_restore_candidate(snapshot, candidate)


func _snapshot_header_is_valid(snapshot: Dictionary) -> bool:
	return (
		_has_exact_keys(snapshot, SNAPSHOT_KEYS)
		and snapshot.get("snapshot_version") == SNAPSHOT_VERSION
		and LIFECYCLES.has(snapshot.get("lifecycle", ""))
		and snapshot.get("stage_index") is int
		and snapshot.get("operation_index") is int
		and snapshot.get("seed") is int
		and snapshot.get("seed", 0) >= -2147483646
		and snapshot.get("seed", 0) <= 2147483646
		and snapshot.get("requested_mode") is String
		and snapshot.get("paused") is bool
		and snapshot.get("stage_history") is Array
		and snapshot.get("last_director_decision") is Dictionary
		and snapshot.get("last_director_application") is Dictionary
		and snapshot.get("stage_transaction") is Dictionary
		and snapshot.get("seat_manager") is Dictionary
		and snapshot.get("pawns") is Dictionary
		and snapshot.get("board") is Dictionary
		and snapshot.get("rules") is Dictionary
		and snapshot.get("director") is Dictionary
		and snapshot.get("roles") is Dictionary
	)


func _build_pre_session_restore_candidate(
	snapshot: Dictionary, candidate: VerticalSliceCoordinator
) -> Dictionary:
	if not _pre_session_snapshot_is_coherent(snapshot, candidate.seat_manager):
		return {"accepted": false, "reason": "incoherent_pre_session_snapshot"}
	candidate.lifecycle = snapshot.lifecycle
	candidate.seed = snapshot.seed
	candidate.requested_mode = snapshot.requested_mode
	return {"accepted": true, "candidate": candidate}


func _build_session_restore_candidate(
	snapshot: Dictionary, candidate: VerticalSliceCoordinator
) -> Dictionary:
	var reason: String = ""
	if active_seats_from(candidate.seat_manager).is_empty():
		reason = "empty_snapshot_roster"
	if reason.is_empty():
		candidate.lifecycle = "confirmation"
		if not candidate.select_tale(snapshot.scenario_id).accepted:
			reason = "snapshot_tale_selection_rejected"
	if reason.is_empty():
		var initialized: Dictionary = candidate.initialize_session(
			snapshot.seed, snapshot.requested_mode
		)
		if not initialized.accepted:
			reason = initialized.get("reason", "restore_failed")
	if reason.is_empty() and not _snapshot_manifest_matches(snapshot, candidate.manifest):
		reason = "snapshot_manifest_mismatch"
	if reason.is_empty() and not _restore_candidate_authorities(candidate, snapshot).accepted:
		reason = "authority_snapshot_rejected"
	if reason.is_empty():
		var progression: Dictionary = _validate_progression_snapshot(snapshot, candidate)
		if not progression.accepted:
			reason = progression.reason
	if reason.is_empty():
		var boundary: Dictionary = VerticalSliceSnapshotPolicy.validate_resumable_boundary(
			snapshot, candidate.manifest, candidate.rules_session
		)
		if not boundary.accepted:
			reason = boundary.reason
	if reason.is_empty():
		var transaction: Dictionary = _validate_stage_transaction(snapshot)
		if not transaction.accepted:
			reason = transaction.reason
	if not reason.is_empty():
		return {"accepted": false, "reason": reason}
	candidate.lifecycle = snapshot.lifecycle
	candidate.stage_index = snapshot.stage_index
	candidate.operation_index = snapshot.operation_index
	candidate.seed = snapshot.seed
	candidate.requested_mode = snapshot.requested_mode
	candidate.paused = snapshot.paused
	candidate.stage_history = RulesContent.SessionData.dict_array(snapshot.stage_history)
	candidate.last_director_decision = snapshot.last_director_decision.duplicate(true)
	candidate.last_director_application = snapshot.last_director_application.duplicate(true)
	candidate._stage_checkpoint = snapshot.stage_transaction.duplicate(true)
	candidate._tale_library_flow.lock_for_lifecycle(snapshot.lifecycle)
	return {"accepted": true, "candidate": candidate}


func _snapshot_manifest_matches(snapshot: Dictionary, candidate_manifest: Dictionary) -> bool:
	return (
		snapshot.get("manifest_version") == candidate_manifest.manifest_version
		and snapshot.get("scenario_id") == candidate_manifest.scenario_id
		and snapshot.get("scenario_version") == candidate_manifest.scenario_version
	)


static func active_seats_from(manager: SeatManager) -> Array[int]:
	var seats: Array[int] = []
	for seat: Dictionary in manager.get_seats():
		if seat.state in [SeatManager.SeatState.ACTIVE, SeatManager.SeatState.RESERVED]:
			seats.append(seat.seat_number)
	return seats


func _pre_session_snapshot_is_coherent(snapshot: Dictionary, manager: SeatManager) -> bool:
	var roster: Array[int] = active_seats_from(manager)
	var lifecycle_roster_is_valid: bool = true
	if snapshot.lifecycle == "boot_title":
		lifecycle_roster_is_valid = roster.is_empty()
		for seat: Dictionary in manager.get_seats():
			lifecycle_roster_is_valid = (
				lifecycle_roster_is_valid and seat.state == SeatManager.SeatState.UNASSIGNED
			)
	elif snapshot.lifecycle in ["confirmation", "tale_library"]:
		lifecycle_roster_is_valid = not roster.is_empty()
	return (
		lifecycle_roster_is_valid
		and snapshot.lifecycle in ["boot_title", "lobby", "confirmation", "tale_library"]
		and snapshot.stage_index == -1
		and snapshot.operation_index == 0
		and snapshot.stage_history.is_empty()
		and snapshot.stage_transaction.is_empty()
		and not snapshot.paused
		and snapshot.manifest_version == 0
		and snapshot.scenario_id == ""
		and snapshot.scenario_version == 0
		and snapshot.pawns == PawnRegistry.new().to_snapshot()
		and snapshot.board.is_empty()
		and snapshot.rules.is_empty()
		and snapshot.director.is_empty()
		and snapshot.roles.is_empty()
		and snapshot.last_director_decision.is_empty()
		and snapshot.last_director_application.is_empty()
	)


func _restore_candidate_authorities(
	candidate: VerticalSliceCoordinator, source: Dictionary
) -> Dictionary:
	if source.rules.get("board", {}) != source.board:
		return {"accepted": false, "reason": "authority_board_snapshot_mismatch"}
	if (
		not (
			candidate
			. pawn_registry
			. restore_snapshot(
				source.pawns, candidate.seat_manager.get_seats(), ExplorationRoom.BOUNDS
			)
			. accepted
		)
		or not candidate.board_state.restore_snapshot(source.board).accepted
		or not candidate.rules_session.restore_snapshot(source.rules).accepted
		or not candidate.director_runtime.restore_snapshot(source.director).accepted
		or not candidate.role_session.restore_snapshot(source.roles).accepted
	):
		return {"accepted": false, "reason": "authority_snapshot_rejected"}
	if not _occupancy_matches_pawns(candidate.board_state, candidate.pawn_registry):
		return {"accepted": false, "reason": "pawn_occupancy_mismatch"}
	if not _authority_rosters_match(candidate):
		return {"accepted": false, "reason": "authority_roster_mismatch"}
	return {"accepted": true, "reason": ""}


func _validate_progression_snapshot(
	snapshot: Dictionary, candidate: VerticalSliceCoordinator
) -> Dictionary:
	return VerticalSliceSnapshotPolicy.validate_progression(
		snapshot, candidate.manifest, candidate.rules_session.terminal_reason
	)


func _validate_stage_transaction(snapshot: Dictionary) -> Dictionary:
	var transaction: Dictionary = snapshot.stage_transaction
	if snapshot.lifecycle != "active_tale" or snapshot.operation_index == 0:
		return (
			{"accepted": true, "reason": ""}
			if transaction.is_empty()
			else {"accepted": false, "reason": "unexpected_stage_transaction"}
		)
	return _validate_active_stage_transaction(snapshot, transaction)


func _validate_active_stage_transaction(
	snapshot: Dictionary, transaction: Dictionary
) -> Dictionary:
	var reason: String = ""
	if not _has_exact_keys(transaction, TRANSACTION_KEYS):
		reason = "malformed_stage_transaction"
	if (
		reason.is_empty()
		and (
			transaction.transaction_version != VerticalSliceSnapshotPolicy.TRANSACTION_VERSION
			or transaction.stage_index != snapshot.stage_index
			or transaction.operation_index != 0
			or transaction.stage_history != snapshot.stage_history
			or transaction.last_director_decision != snapshot.last_director_decision
			or transaction.last_director_application != snapshot.last_director_application
		)
	):
		reason = "incoherent_stage_transaction"
	var checkpoint := VerticalSliceCoordinator.new(
		_selection.catalog_path, _selection.registry, _selection.expected_catalog_digest
	)
	if (
		reason.is_empty()
		and not checkpoint.seat_manager.restore_snapshot(transaction.seat_manager).accepted
	):
		reason = "transaction_seat_snapshot_rejected"
	if reason.is_empty() and checkpoint.seat_manager.to_snapshot() != snapshot.seat_manager:
		reason = "transaction_roster_mismatch"
	if reason.is_empty():
		checkpoint.lifecycle = "confirmation"
		if not checkpoint.select_tale(snapshot.scenario_id).accepted:
			reason = "transaction_tale_selection_rejected"
	if reason.is_empty():
		var initialized: Dictionary = checkpoint.initialize_session(
			snapshot.seed, snapshot.requested_mode
		)
		if (
			not initialized.accepted
			or not _restore_candidate_authorities(checkpoint, transaction).accepted
			or not VerticalSliceSnapshotPolicy.stage_start_authorities_are_clean(
				checkpoint.rules_session
			)
		):
			reason = "transaction_authority_snapshot_rejected"
	return (
		{"accepted": true, "reason": ""}
		if reason.is_empty()
		else {"accepted": false, "reason": reason}
	)


func _occupancy_matches_pawns(state: BoardState, registry: PawnRegistry) -> bool:
	var occupancy: Dictionary = state.get_occupancy()
	var pawns: Array[PawnState] = registry.get_pawns()
	if occupancy.size() != pawns.size():
		return false
	for pawn: PawnState in pawns:
		if occupancy.get(pawn.seat_number, "") != state.space_for_position(pawn.position):
			return false
	return true


func _authority_rosters_match(candidate: VerticalSliceCoordinator) -> bool:
	var expected: Array[int] = active_seats_from(candidate.seat_manager)
	var rules_seats: Array[int] = candidate.rules_session.participating_seats.duplicate()
	var role_seats: Array[int] = []
	var pawn_seats: Array[int] = []
	for value: Variant in candidate.role_session.seat_states:
		if not value is int:
			return false
		role_seats.append(value)
	for pawn: PawnState in candidate.pawn_registry.get_pawns():
		pawn_seats.append(pawn.seat_number)
	expected.sort()
	rules_seats.sort()
	role_seats.sort()
	pawn_seats.sort()
	return expected == rules_seats and expected == role_seats and expected == pawn_seats


func _has_exact_keys(value: Dictionary, expected: PackedStringArray) -> bool:
	if value.size() != expected.size():
		return false
	for key: Variant in value:
		if not key is String or not expected.has(key):
			return false
	return true


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
	_tale_library_flow.clear_rejection()
	_emit_state()
	return {"accepted": true, "lifecycle": lifecycle}


func _clear_session_authorities() -> void:
	tale_package.clear()
	tale_package_digest = ""
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
	last_director_decision.clear()
	last_director_application.clear()
	_stage_checkpoint.clear()
	_tale_library_flow.selection_locked = false


func _close_companion_room() -> void:
	if companion_bridge != null and companion_bridge.room_open:
		companion_bridge.close_room()


func _finish_stage(stage: Dictionary) -> Dictionary:
	stage_history.append(
		{"index": stage_index, "stage_id": stage.id, "authority_digest": authority_digest()}
	)
	stage_index += 1
	operation_index = 0
	_stage_checkpoint.clear()
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
	return _tale_library_flow.reject_internal(self, reason)


func _emit_state() -> void:
	lifecycle_changed.emit(public_state())
