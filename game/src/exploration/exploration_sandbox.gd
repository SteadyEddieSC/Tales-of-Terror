class_name ExplorationSandbox
extends Node2D

const TOKENS: VisualTokens = preload("res://assets/theme/visual_tokens.tres")
const LAB_THEME: Theme = preload("res://assets/theme/terror_lab_theme.tres")
const HUD_EDGE_INSET: float = 10.0
const HUD_REGION_HEIGHT: float = 64.0
const HUD_REGION_GAP: float = 16.0
const RESET_REGION_WIDTH: float = 324.0
const HUD_CANVAS_LAYER: int = 10
const ACTIVE_CONTROLS_TEXT: String = (
	"MOVE: STICK / WASD  •  INTERACT: A / E\n" + "HELP: X / H  •  DIAGNOSTICS: T"
)

var pawn_registry := PawnRegistry.new()
var _pawn_nodes: Dictionary = {}
var _input_router: PlayerInputRouter
var _room: ExplorationRoom
var _board_definition: BoardDefinition
var _board_state: BoardState
var _board_overlay: BoardDebugOverlay
var _rules_content: LanternHouseRulesContent
var _rules_session: RulesSession
var _rules_hud: RulesHud
var _director_content: LanternHouseDirectorContent
var _director_runtime: DirectorRuntime
var _director_hud: DirectorHud
var _director_diagnostics: DirectorDiagnostics
var _director_decision: Dictionary = {}
var _social_content: LanternHouseSocialContent
var _role_session: RoleSession
var _role_hud: RoleHud
var _role_diagnostics: RoleDiagnostics
var _companion_bridge: CompanionBridge
var _companion_lab: CompanionRoomLab
var _social_showcase_active: bool = false
var _camera: SharedCameraCoordinator
var _interactions: InteractionCoordinator
var _diagnostics: ExplorationDiagnostics
var _title_label: Label
var _message_label: Label
var _separation_label: Label
var _reset_label: Label
var _status_panel: Panel
var _reset_panel: Panel
var _safe_overlay: SafeAreaOverlay
var _hud_root: Control
var _showcase_mode: bool = false
var _safe_margin: int = 24
var _session_coordinator: VerticalSliceCoordinator


func setup(
	input_router: PlayerInputRouter, session_coordinator: VerticalSliceCoordinator = null
) -> void:
	_input_router = input_router
	_session_coordinator = session_coordinator
	if _session_coordinator != null:
		pawn_registry = _session_coordinator.pawn_registry


func _ready() -> void:
	_room = ExplorationRoom.new()
	add_child(_room)
	if _session_coordinator == null:
		_board_definition = LanternHouseBoardDefinition.new()
		_board_state = BoardState.new(_board_definition)
	else:
		_board_definition = _session_coordinator.board_definition
		_board_state = _session_coordinator.board_state
		_rules_content = _session_coordinator.rules_content
		_rules_session = _session_coordinator.rules_session
		_director_content = _session_coordinator.director_content
		_director_runtime = _session_coordinator.director_runtime
		_social_content = _session_coordinator.social_content
		_role_session = _session_coordinator.role_session
		_companion_bridge = _session_coordinator.companion_bridge
	_board_state.state_changed.connect(_on_board_state_changed)
	_board_state.mutation_rejected.connect(_on_board_mutation_rejected)
	_board_overlay = BoardDebugOverlay.new()
	_board_overlay.setup(_board_definition, _board_state, TOKENS)
	_board_overlay.set_safe_margin(_safe_margin)
	_board_overlay.visible = false
	add_child(_board_overlay)
	_interactions = InteractionCoordinator.new()
	add_child(_interactions)
	_interactions.set_resolution_handler(_resolve_board_interaction)
	_interactions.interaction_resolved.connect(_on_interaction_resolved)
	_add_interactable("iron_gate", SandboxInteractable.Kind.DOOR, Vector2(910, 500))
	_add_interactable("clue_pedestal", SandboxInteractable.Kind.CLUE, Vector2(650, 585))
	_camera = SharedCameraCoordinator.new()
	add_child(_camera)
	_build_hud()
	if _session_coordinator != null:
		_session_coordinator.lifecycle_changed.connect(_on_session_state_changed)
		_on_session_state_changed(_session_coordinator.public_state())


func sync_seats(seats: Array[Dictionary]) -> void:
	pawn_registry.sync_seats(seats, ExplorationRoom.SPAWN_POINTS)
	var active_seats: Dictionary = {}
	for pawn: PawnState in pawn_registry.get_pawns():
		active_seats[pawn.seat_number] = true
		if not _pawn_nodes.has(pawn.seat_number):
			var pawn_node := ExplorationPawn.new()
			pawn_node.setup(pawn, TOKENS)
			add_child(pawn_node)
			_pawn_nodes[pawn.seat_number] = pawn_node
		(_pawn_nodes[pawn.seat_number] as ExplorationPawn).refresh_connection()
	for seat_number: int in _pawn_nodes.keys():
		if not active_seats.has(seat_number):
			(_pawn_nodes[seat_number] as ExplorationPawn).queue_free()
			_pawn_nodes.erase(seat_number)
	_board_state.sync_occupancy(pawn_registry.get_pawns())
	_sync_rules_seats()


func request_rules_navigation(device_id: int, direction: int, confirm: bool, cancel: bool) -> bool:
	if _social_showcase_active and _role_session != null and is_instance_valid(_role_hud):
		var social_pawn: PawnState = pawn_registry.get_by_device(device_id)
		if (
			social_pawn != null
			and _role_hud.handle_private_input(
				_role_session, social_pawn.seat_number, confirm, cancel
			)
		):
			return true
	if _rules_session == null or not is_instance_valid(_rules_hud):
		return false
	var pawn: PawnState = pawn_registry.get_by_device(device_id)
	if pawn == null:
		return false
	return _rules_hud.handle_navigation(pawn.seat_number, direction, confirm, cancel)


func request_private_reveal_input(device_id: int, confirm: bool, cancel: bool) -> bool:
	if _session_coordinator == null or (not confirm and not cancel):
		return false
	var reveal: Dictionary = _session_coordinator.public_state().get("private_reveal", {})
	if not (
		reveal.get("phase", "") in [PrivateRevealFlow.PHASE_SHIELD, PrivateRevealFlow.PHASE_REVEAL]
	):
		return false
	var pawn: PawnState = pawn_registry.get_by_device(device_id)
	if pawn == null:
		return true
	var result: Dictionary = PrivateRevealFlow.submit_for(
		_session_coordinator, pawn.seat_number, "cancel" if cancel else "confirm"
	)
	return result.get("consumed", false)


func shield_private_reveal_for_public_surface() -> void:
	if _session_coordinator == null:
		return
	PrivateRevealFlow.shield_for(_session_coordinator)
	if is_instance_valid(_role_hud):
		_role_hud.clear_private_cache()
	_sync_private_reveal(_session_coordinator.public_state())


func request_interaction(device_id: int) -> bool:
	return _interactions.request(pawn_registry.get_by_device(device_id))


func toggle_diagnostics() -> void:
	if _social_showcase_active and is_instance_valid(_role_diagnostics):
		_role_diagnostics.visible = not _role_diagnostics.visible
		if is_instance_valid(_role_hud):
			_role_hud.visible = not _role_diagnostics.visible
		return
	if is_instance_valid(_director_diagnostics) and not _director_decision.is_empty():
		_director_diagnostics.toggle()
		if is_instance_valid(_director_hud):
			_director_hud.visible = not _director_diagnostics.visible
		_diagnostics.visible = false
		_board_overlay.visible = false
		_room.set_show_authored_headings(true)
		return
	_diagnostics.toggle()
	_board_overlay.visible = _diagnostics.visible
	_room.set_show_authored_headings(not _board_overlay.visible)


func set_safe_margin(value: int) -> void:
	_safe_margin = clampi(value, 0, 48)
	_safe_overlay.set_frame_margin(_safe_margin)
	_board_overlay.set_safe_margin(_safe_margin)
	_diagnostics.set_safe_margin(_safe_margin)
	if is_instance_valid(_rules_hud):
		_rules_hud.set_safe_margin(_safe_margin)
	if is_instance_valid(_director_hud):
		_director_hud.set_safe_margin(_safe_margin)
	if is_instance_valid(_director_diagnostics):
		_director_diagnostics.set_safe_margin(_safe_margin)
	if is_instance_valid(_role_hud):
		_role_hud.set_safe_margin(_safe_margin)
	if is_instance_valid(_role_diagnostics):
		_role_diagnostics.set_safe_margin(_safe_margin)
	if is_instance_valid(_companion_lab):
		_companion_lab.set_safe_margin(_safe_margin)
	_layout_top_hud()
	_layout_bottom_hud()


func _on_session_state_changed(state: Dictionary) -> void:
	if not is_instance_valid(_message_label) or _showcase_mode:
		return
	_sync_private_reveal(state)
	var interaction: Dictionary = state.get("interaction", {})
	if interaction.is_empty():
		_message_label.text = ACTIVE_CONTROLS_TEXT
	else:
		_message_label.text = (
			"%s\n%s"
			% [
				interaction.get("instruction", "Continue the Tale."),
				interaction.get("controls", ACTIVE_CONTROLS_TEXT),
			]
		)
	var stage: Dictionary = state.get("stage", {})
	if not stage.is_empty():
		_title_label.text = (
			"LANTERN HOUSE  |  STAGE %d  |  %s"
			% [
				state.get("stage_index", 0) + 1,
				stage.get("title", "CURRENT TALE").to_upper(),
			]
		)
	if is_instance_valid(_rules_hud):
		_rules_hud.refresh()


func _sync_private_reveal(state: Dictionary) -> void:
	if not is_instance_valid(_role_hud):
		return
	var reveal: Dictionary = state.get("private_reveal", {})
	var phase: String = reveal.get("phase", PrivateRevealFlow.PHASE_IDLE)
	if phase == PrivateRevealFlow.PHASE_IDLE and state.get("lifecycle", "") == "active_tale":
		PrivateRevealFlow.ensure_started(_session_coordinator)
		return
	if is_instance_valid(_rules_hud):
		_rules_hud.visible = (
			phase in [PrivateRevealFlow.PHASE_IDLE, PrivateRevealFlow.PHASE_COMPLETE]
		)
	match phase:
		PrivateRevealFlow.PHASE_SHIELD:
			_role_hud.present_shield(reveal)
		PrivateRevealFlow.PHASE_REVEAL:
			var seat_number: int = reveal.get("authorized_seat", 0)
			_role_hud.present_private_view(
				PrivateRevealFlow.private_view_for(_session_coordinator, seat_number),
				"CONTROLLED PRIVATE REVEAL"
			)
		_:
			_role_hud.clear_private_cache()


func _exit_tree() -> void:
	if is_instance_valid(_role_hud):
		_role_hud.clear_private_cache()


func present_reset_progress(progress: float) -> void:
	_reset_label.text = (
		"HOLD Y / R 1.5s TO RETURN TO TITLE"
		if progress <= 0.0
		else "RETURNING TO TITLE… %d%%" % roundi(progress * 100.0)
	)


func enable_showcase(stage: String = "terminal") -> void:
	_showcase_mode = true
	var showcase_positions: Array[Vector2] = [
		Vector2(250, 540), Vector2(1030, 500), Vector2(1300, 350), Vector2(1600, 630)
	]
	for index: int in mini(showcase_positions.size(), pawn_registry.get_pawns().size()):
		var pawn: PawnState = pawn_registry.get_pawns()[index]
		pawn.position = showcase_positions[index]
		(_pawn_nodes[pawn.seat_number] as ExplorationPawn).global_position = pawn.position
	_board_state.sync_occupancy(pawn_registry.get_pawns())
	_run_rules_showcase(stage)
	if (
		not stage.begins_with("director_")
		and not stage.begins_with("social_")
		and not stage.begins_with("companion_")
	):
		_message_label.text = (
			"EVIDENCE: %s  •  PROMPT ◉  •  CHECK ⚄  •  CARD ◫  •  VOTE ◈  •  BOARD r%d"
			% [stage.to_upper(), _board_state.revision]
		)
	_diagnostics.visible = false
	_board_overlay.visible = false
	_room.set_show_authored_headings(true)


func _physics_process(delta: float) -> void:
	var pawns: Array[PawnState] = pawn_registry.get_pawns()
	if pawns.is_empty() or _camera == null:
		return
	var group_center := Vector2.ZERO
	for pawn: PawnState in pawns:
		group_center += pawn.position
	group_center /= float(pawns.size())
	for pawn: PawnState in pawns:
		var raw_input := Vector2.ZERO
		if not _showcase_mode and pawn.connected and _input_router != null:
			raw_input = _input_router.get_movement_vector(pawn.device_id)
		var resistance: float = SharedCameraPolicy.movement_resistance(
			pawn.position, raw_input, group_center
		)
		(_pawn_nodes[pawn.seat_number] as ExplorationPawn).apply_movement(
			raw_input, resistance, delta, ExplorationRoom.BOUNDS
		)
	_board_state.sync_occupancy(pawns)
	_interactions.update_focus(pawns)
	for pawn: PawnState in pawns:
		(_pawn_nodes[pawn.seat_number] as ExplorationPawn).set_interaction_focus(
			pawn.nearby_interactable != "—"
		)
	_interactions.resolve_pending()
	_camera.update_group(pawns, delta)
	_separation_label.text = SharedCameraPolicy.state_label(_camera.separation_state)
	_separation_label.modulate = (
		TOKENS.danger
		if _camera.separation_state == SharedCameraPolicy.SeparationState.REGROUP
		else TOKENS.warning
	)
	_diagnostics.update_snapshot(pawns, _camera, _board_state, _rules_session)


func _add_interactable(id: String, kind: SandboxInteractable.Kind, world_position: Vector2) -> void:
	var interactable := SandboxInteractable.new()
	interactable.setup(id, kind, world_position, TOKENS)
	add_child(interactable)
	_interactions.register(interactable)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = HUD_CANVAS_LAYER
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = LAB_THEME
	layer.add_child(root)
	_hud_root = root
	_title_label = Label.new()
	_title_label.text = (
		"LANTERN HOUSE  •  FIRST VERTICAL SLICE  •  %s"
		% ProjectSettings.get_setting("application/config/version")
	)
	_title_label.theme_type_variation = "SectionTitle"
	_title_label.size = Vector2(540, 30)
	root.add_child(_title_label)
	_separation_label = Label.new()
	_separation_label.text = "TOGETHER"
	_separation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_separation_label.position = Vector2(650, 28)
	_separation_label.size = Vector2(276, 30)
	root.add_child(_separation_label)
	_status_panel = Panel.new()
	_status_panel.theme_type_variation = "StatusBadge"
	_status_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_status_panel)
	_message_label = Label.new()
	_message_label.text = ACTIVE_CONTROLS_TEXT
	_message_label.position = Vector2(12, 4)
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_message_label.max_lines_visible = 2
	_message_label.clip_text = true
	_message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_status_panel.add_child(_message_label)
	_reset_panel = Panel.new()
	_reset_panel.theme_type_variation = "StatusBadge"
	_reset_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_reset_panel)
	_reset_label = Label.new()
	_reset_label.position = Vector2(10, 4)
	_reset_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_reset_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_reset_label.clip_text = true
	_reset_panel.add_child(_reset_label)
	present_reset_progress(0.0)
	_diagnostics = ExplorationDiagnostics.new()
	root.add_child(_diagnostics)
	_diagnostics.set_safe_margin(_safe_margin)
	_director_hud = DirectorHud.new()
	root.add_child(_director_hud)
	_director_hud.set_safe_margin(_safe_margin)
	_director_diagnostics = DirectorDiagnostics.new()
	root.add_child(_director_diagnostics)
	_director_diagnostics.set_safe_margin(_safe_margin)
	_role_hud = RoleHud.new()
	_role_hud.z_index = 60
	root.add_child(_role_hud)
	_role_hud.set_safe_margin(_safe_margin)
	_role_diagnostics = RoleDiagnostics.new()
	root.add_child(_role_diagnostics)
	_role_diagnostics.set_safe_margin(_safe_margin)
	_companion_lab = CompanionRoomLab.new()
	root.add_child(_companion_lab)
	_companion_lab.set_safe_margin(_safe_margin)
	_safe_overlay = SafeAreaOverlay.new()
	_safe_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_safe_overlay.frame_color = TOKENS.warning
	root.add_child(_safe_overlay)
	_layout_top_hud()
	_layout_bottom_hud()
	_ensure_rules_hud()


func _sync_rules_seats() -> void:
	var current: Array[int] = []
	for pawn: PawnState in pawn_registry.get_pawns():
		current.append(pawn.seat_number)
	current.sort()
	if current.is_empty():
		return
	if _rules_session == null:
		_rules_content = LanternHouseRulesContent.new()
		_rules_session = RulesSession.new(_rules_content, _board_state, 4706, current)
		_director_content = LanternHouseDirectorContent.new()
		_director_runtime = DirectorRuntime.new(
			_director_content, "standard", _rules_session.seed, _rules_content, _board_definition
		)
		_social_content = LanternHouseSocialContent.new()
		_role_session = RoleSession.new(
			_social_content, "cooperative", _rules_session.seed, current
		)
		_ensure_rules_hud()
	else:
		for seat_number: int in _rules_session.participating_seats:
			var pawn: PawnState = pawn_registry.get_by_seat(seat_number)
			if pawn != null:
				_rules_session.seat_connection[seat_number] = pawn.connected
		for seat_number: int in current:
			if (
				not _rules_session.participating_seats.has(seat_number)
				and not _rules_session.pending_late_seats.has(seat_number)
			):
				_rules_session.request_late_join(seat_number)
			if _role_session != null and _role_session.seat_states.has(seat_number):
				var current_pawn: PawnState = pawn_registry.get_by_seat(seat_number)
				if (
					current_pawn != null
					and _role_session.seat_states[seat_number].connected != current_pawn.connected
				):
					_role_session.set_seat_connected(seat_number, current_pawn.connected)
	if is_instance_valid(_rules_hud):
		_rules_hud.refresh()


func _ensure_rules_hud() -> void:
	if _rules_session == null or not is_instance_valid(_hud_root) or is_instance_valid(_rules_hud):
		return
	_rules_hud = RulesHud.new()
	_rules_hud.setup(_rules_session)
	_hud_root.add_child(_rules_hud)
	_rules_hud.set_safe_margin(_safe_margin)


func _run_rules_showcase(stage: String = "terminal") -> void:
	if _rules_session == null:
		return
	if stage.begins_with("companion_"):
		_run_companion_showcase(stage)
		return
	if stage.begins_with("social_"):
		_run_social_showcase(stage)
		return
	if stage.begins_with("director_"):
		_run_director_showcase(stage.trim_prefix("director_"))
		return
	_rules_session.queue_event("threshold_whisper")
	_rules_session.resolve_next_event()
	if stage == "prompt":
		var prompt: Dictionary = _rules_session.pending_prompt.duplicate(true)
		_rules_session.submit_response(1, ["listen"], _rules_session.pending_prompt.revision)
		_rules_session.resolve_prompt()
		prompt["scope"] = "all"
		prompt["allow_pass"] = true
		_rules_session.open_prompt(prompt, _rules_session.participating_seats, "showcase_prompt")
		_rules_hud.handle_navigation(1, 1, false, false)
		_rules_hud.handle_navigation(2, 0, true, false)
		_rules_hud.handle_navigation(3, 0, false, true)
		return
	if not _rules_session.pending_prompt.is_empty():
		_rules_session.submit_response(1, ["listen"], _rules_session.pending_prompt.revision)
		_rules_session.resolve_prompt()
	_rules_session.resolve_next_event()
	_rules_session.open_vote(_rules_content.vote_definition(), _rules_session.participating_seats)
	if stage == "vote":
		_rules_hud.handle_navigation(1, 1, false, false)
		_rules_hud.handle_navigation(2, 0, true, false)
		_rules_hud.handle_navigation(3, 0, false, true)
		return
	for seat_number: int in _rules_session.participating_seats:
		var option: Array[String] = []
		option.append("gallery" if seat_number % 2 == 1 else "vault")
		_rules_session.submit_response(seat_number, option, _rules_session.pending_prompt.revision)
	_rules_session.resolve_vote()
	_rules_session.resolve_check(_rules_content.courage_check(), 1, "vault_reckoning")
	_rules_session.apply_effect_bundle(
		[
			{
				"type": "board_mutation",
				"mutation": BoardMutation.hazard("narrow_gallery", "echo_mist", true)
			},
			{"type": "grant_card", "seat": 1, "card_id": "steady_flame"}
		],
		1,
		"showcase_setup"
	)
	var steady_flame: Dictionary = _rules_session.hands[1][-1]
	_rules_session.play_card(1, steady_flame.instance_id)
	_rules_session.queue_event("vault_reckoning")
	_rules_session.resolve_next_event()
	_rules_session.complete("lantern_house_secured")


func _run_companion_showcase(stage: String) -> void:
	_separation_label.visible = false
	_companion_lab.z_index = 50
	_title_label.z_index = 51
	_status_panel.z_index = 51
	_reset_panel.z_index = 51
	_safe_overlay.z_index = 52
	var client_count: int = 4
	if stage in ["companion_diagnostics", "companion_scale_8"]:
		client_count = 8
	elif stage == "companion_scale_2":
		client_count = 2
	elif stage == "companion_scale_1":
		client_count = 1
	var seat_numbers: Array[int] = []
	var companion_seats := SeatManager.new()
	for index: int in client_count:
		companion_seats.join_device(index, "companion-showcase-%d" % index, "Local Controller")
		seat_numbers.append(index + 1)
	if _rules_session.participating_seats.size() != client_count:
		_rules_session = RulesSession.new(_rules_content, _board_state, 4706, seat_numbers)
		_director_runtime = DirectorRuntime.new(
			_director_content, "standard", 4706, _rules_content, _board_definition
		)
	_role_session = RoleSession.new(
		_social_content,
		"hidden_betrayer" if client_count >= 3 else "cooperative",
		4706,
		seat_numbers
	)
	_companion_bridge = CompanionBridge.new(
		companion_seats, _board_state, _rules_session, _director_runtime, _role_session
	)
	var transport := CompanionFakeTransport.new(_companion_bridge)
	_companion_bridge.create_room("room_lantern", "GHST27")
	var outcome: Dictionary = {
		"headline": "HOST ROOM OPEN  •  shared-screen play remains active without companions."
	}
	if stage == "companion_join":
		transport.connect_client("browser_guest")
		outcome = {
			"headline": "BROWSER JOIN RECEIVED  •  awaiting explicit host approval.",
			"detail": "No stable seat or private view was inferred from the browser identity."
		}
	elif stage.begins_with("companion_scale_"):
		for index: int in client_count:
			var scale_client: String = "browser_scale_%d" % (index + 1)
			transport.connect_client(scale_client)
			transport.approve_client(scale_client, index + 1)
		outcome = {
			"headline":
			(
				"%d SIMULATED COMPANIONS CONNECTED  •  deterministic stable-seat claims."
				% client_count
			),
			"detail":
			"The lab covers the required 1, 2, 4, and 8 client scales without changing gameplay ownership."
		}
	elif stage in ["companion_close", "companion_expiry"]:
		transport.connect_client("browser_lifecycle")
		transport.approve_client("browser_lifecycle", 1)
		var lifecycle_result: Dictionary = (
			_companion_bridge.expire_room()
			if stage == "companion_expiry"
			else _companion_bridge.close_room()
		)
		var resume_denied: Dictionary = transport.resume_client("browser_lifecycle", 1)
		outcome = {
			"headline":
			(
				"%s  •  COMPANIONS DISCONNECTED SAFELY"
				% ("ROOM EXPIRED" if stage == "companion_expiry" else "HOST CLOSED ROOM")
			),
			"detail":
			(
				"Lifecycle accepted: %s. Resume denied: %s. Local shared-screen play remains active."
				% [lifecycle_result.accepted, not resume_denied.accepted]
			)
		}
	elif stage in ["companion_private", "companion_reconnect"]:
		var secret_seat: int = _role_session.seat_with_tag("secret")
		transport.connect_client("browser_private")
		transport.approve_client("browser_private", secret_seat)
		if stage == "companion_reconnect":
			var private_before: Dictionary = (
				_companion_bridge.seat_view_for_client("browser_private").social_private
			)
			transport.disconnect_client("browser_private")
			var resumed: Dictionary = transport.resume_client("browser_private", secret_seat)
			var preserved: bool = (
				private_before
				== _companion_bridge.seat_view_for_client("browser_private").social_private
			)
			outcome = {
				"headline":
				(
					"RECONNECT ACCEPTED  •  SAME STABLE SEAT %s"
					% _companion_bridge.seat_identity(secret_seat).numeral
				),
				"detail":
				(
					"Private role/objective/action state preserved: %s. Wrong-seat resume fails closed."
					% ("YES" if resumed.accepted and preserved else "NO")
				)
			}
		else:
			outcome = {
				"headline": "AUTHORIZED PRIVATE VIEW DELIVERED ONLY TO ITS OWNING SEAT.",
				"detail":
				(
					"The public host withholds the secret payload. Recursive privacy evaluation: %s."
					% ("PASS" if _role_session.privacy_report().passed else "FAIL")
				)
			}
	elif stage == "companion_denial":
		transport.connect_client("browser_wrong")
		transport.approve_client("browser_wrong", 1)
		var denied: Dictionary = transport.send_intent(
			"browser_wrong", "private_reveal_ack", "wrong_seat", {}, 2
		)
		outcome = {
			"headline": "WRONG-SEAT REQUEST DENIED  •  %s" % denied.code.to_upper(),
			"detail":
			"No role, rules, board, Director, RNG, controller, pawn, or seat ownership mutation was applied."
		}
	elif stage == "companion_action":
		transport.connect_client("browser_action")
		transport.approve_client("browser_action", 1)
		var prompt: Dictionary = _rules_content.events[0].prompts[0].duplicate(true)
		prompt.scope = "all"
		_rules_session.open_prompt(prompt, seat_numbers, "companion_showcase")
		var accepted: Dictionary = transport.send_intent(
			"browser_action",
			"prompt_choice_submit",
			"accepted_action",
			{"option_ids": ["listen"], "prompt_revision": _rules_session.pending_prompt.revision},
			1
		)
		outcome = {
			"headline":
			"COMPANION ACTION ACCEPTED EXACTLY ONCE  •  AUTHORITY r%d" % accepted.after_revision,
			"detail":
			(
				"Bounded prompt intent crossed RulesSession validation; replay cache prevents "
				+ "duplicate mutation."
			)
		}
	elif stage == "companion_diagnostics":
		for index: int in client_count:
			var client_id: String = "browser_%d" % (index + 1)
			transport.connect_client(client_id)
			transport.approve_client(client_id, index + 1)
		outcome = {
			"headline": "EIGHT SIMULATED COMPANIONS  •  SANITIZED + BOUNDED",
			"detail":
			(
				"Capabilities, private payloads, storage contents, raw audits, and spoiler "
				+ "diagnostics are absent."
			)
		}
	for child: Node in get_children():
		if child is ExplorationRoom or child is ExplorationPawn or child is SandboxInteractable:
			(child as CanvasItem).visible = false
	if is_instance_valid(_rules_hud):
		_rules_hud.visible = false
	if is_instance_valid(_director_hud):
		_director_hud.visible = false
	if is_instance_valid(_director_diagnostics):
		_director_diagnostics.visible = false
	if is_instance_valid(_role_hud):
		_role_hud.visible = false
	if is_instance_valid(_role_diagnostics):
		_role_diagnostics.visible = false
	_companion_lab.present(_companion_bridge, stage, outcome)
	_message_label.text = (
		"EVIDENCE: COMPANION ROOM  •  OPTIONAL INPUT/PRESENTATION  •  " + "NATIVE GODOT AUTHORITY"
	)


func _run_director_showcase(trajectory: String) -> void:
	if _director_runtime == null:
		return
	var fixture_effects: Array = []
	match trajectory:
		"struggling", "diagnostics":
			for _index: int in 3:
				_rules_session.resolve_check(
					{"dice": 1, "sides": 6, "target": 99}, 1, "director_fixture"
				)
		"cruising":
			fixture_effects = [
				{"type": "set_counter", "counter_id": "objective_progress", "value": 10},
				{"type": "set_counter", "counter_id": "hope", "value": 6},
				{"type": "set_counter", "counter_id": "resolve", "value": 4},
			]
			for _index: int in _rules_content.phases.size():
				_rules_session.transition_phase()
		"stalled":
			fixture_effects = [
				{"type": "set_counter", "counter_id": "objective_stall_steps", "value": 8},
				{"type": "set_counter", "counter_id": "prompt_latency_steps", "value": 8},
			]
			for seat: int in _rules_session.participating_seats.slice(0, 2):
				_rules_session.mark_ready(seat, true)
		_:
			trajectory = "struggling"
	if not fixture_effects.is_empty():
		_rules_session.apply_effect_bundle(fixture_effects, 0, "director_lab_fixture")
	var telemetry: Dictionary = DirectorTelemetry.build(_rules_session, _board_state)
	var core_rng_before: int = _rules_session.rng.counter
	_director_decision = _director_runtime.evaluate(telemetry)
	var application: Dictionary = DirectorProposalApplier.apply(
		_director_decision, _rules_session, _board_state
	)
	_director_runtime.record_application(_director_decision, application)
	application["core_rng_before"] = core_rng_before
	application["core_rng_after"] = _rules_session.rng.counter
	_director_hud.present(_director_decision, application)
	_director_diagnostics.present(_director_runtime, telemetry, _director_decision, application)
	if is_instance_valid(_rules_hud):
		_rules_hud.visible = false
	_director_diagnostics.visible = trajectory == "diagnostics"
	_director_hud.visible = trajectory != "diagnostics"
	_message_label.text = (
		"EVIDENCE: %s GROUP  •  LOCAL + DETERMINISTIC  •  CORE RNG #%d UNCHANGED"
		% [trajectory.to_upper(), core_rng_before]
	)


func _run_social_showcase(stage: String) -> void:
	if _social_content == null:
		_social_content = LanternHouseSocialContent.new()
	var fixture: Dictionary = _social_content.fixture_by_stage(stage)
	if fixture.is_empty():
		fixture = _social_content.fixtures[0].duplicate(true)
	var fixture_seats: Array[int] = []
	for seat_number: int in range(1, fixture.seat_count + 1):
		fixture_seats.append(seat_number)
	_role_session = RoleSession.new(
		_social_content, fixture.mode_id, _rules_session.seed, fixture_seats
	)
	for operation: Dictionary in fixture.get("operations", []):
		_apply_social_fixture_operation(operation)
	for child: Node in get_children():
		if child is ExplorationRoom or child is ExplorationPawn or child is SandboxInteractable:
			(child as CanvasItem).visible = false
	var view_spec: Dictionary = fixture.view.duplicate(true)
	if view_spec.get("kind", "") == "seat_private":
		view_spec["seat"] = _fixture_select_seat(view_spec.get("selector_tag", ""), 0, [])
	_social_showcase_active = true
	if is_instance_valid(_rules_hud):
		_rules_hud.visible = false
	if is_instance_valid(_director_hud):
		_director_hud.visible = false
	if is_instance_valid(_director_diagnostics):
		_director_diagnostics.visible = false
	if view_spec.get("kind", "") == "diagnostics":
		_role_hud.visible = false
		_role_diagnostics.present(_role_session)
	else:
		_role_diagnostics.visible = false
		_role_hud.present(_role_session, view_spec)
	_message_label.text = (
		"EVIDENCE: %s  •  DATA-DRIVEN SOCIAL AUTHORITY  •  ROLE RNG #%d  •  PUBLIC/PRIVATE CONTRACT"
		% [view_spec.get("title", "SOCIAL STATE"), _role_session.rng.counter]
	)


func _apply_social_fixture_operation(operation: Dictionary) -> void:
	match operation.get("type", ""):
		"transition":
			var seat: int = _fixture_select_seat(
				operation.get("selector_tag", ""), operation.get("seat", 0), []
			)
			if seat > 0:
				_role_session.request_transition_by_trigger(
					seat, operation.get("trigger", ""), _rules_session, _board_state
				)
		"action":
			var actor: int = _fixture_select_seat(
				operation.get("selector_tag", ""), operation.get("seat", 0), []
			)
			var targets: Array[int] = []
			var target_tag: String = operation.get("target_selector_tag", "")
			if not target_tag.is_empty():
				var target: int = _fixture_select_seat(
					target_tag, operation.get("target_seat", 0), [actor]
				)
				if target > 0:
					targets.append(target)
			if actor > 0:
				_role_session.perform_action_by_tag(
					actor, operation.get("action_tag", ""), targets, _rules_session, _board_state
				)
		"connection_cycle":
			var seat: int = _fixture_select_seat(
				operation.get("selector_tag", ""), operation.get("seat", 0), []
			)
			if seat > 0:
				_role_session.set_seat_connected(seat, false)
				_role_session.set_seat_connected(seat, true)
		"rules_effects":
			_rules_session.apply_effect_bundle(operation.get("effects", []), 0, "social_fixture")
		"resolve_outcomes":
			_role_session.resolve_outcomes(_rules_session, _board_state)


func _fixture_select_seat(selector_tag: String, explicit_seat: int, excluded: Array[int]) -> int:
	if (
		explicit_seat > 0
		and _role_session.seat_states.has(explicit_seat)
		and not excluded.has(explicit_seat)
	):
		return explicit_seat
	return _role_session.seat_with_tag(selector_tag, excluded)


func _layout_top_hud() -> void:
	if not is_instance_valid(_title_label) or not is_instance_valid(_separation_label):
		return
	var layout: Dictionary = calculate_top_hud_layout(Vector2(960, 540), _safe_margin)
	_title_label.position = (layout.title as Rect2).position
	_separation_label.position = (layout.separation as Rect2).position


static func calculate_top_hud_layout(viewport_size: Vector2, safe_margin: int) -> Dictionary:
	var left: float = float(safe_margin) + HUD_EDGE_INSET
	var top: float = float(safe_margin) + 4.0
	return {
		"safe":
		Rect2(
			Vector2(safe_margin, safe_margin),
			viewport_size - Vector2(safe_margin, safe_margin) * 2.0
		),
		"title": Rect2(Vector2(left, top), Vector2(540, 30)),
		"separation": Rect2(Vector2(viewport_size.x - left - 276.0, top), Vector2(276, 30)),
	}


func _layout_bottom_hud() -> void:
	if not is_instance_valid(_status_panel) or not is_instance_valid(_reset_panel):
		return
	var layout: Dictionary = calculate_bottom_hud_layout(Vector2(960, 540), _safe_margin)
	var status_rect: Rect2 = layout.status
	var reset_rect: Rect2 = layout.reset
	_status_panel.position = status_rect.position
	_status_panel.size = status_rect.size
	_message_label.size = status_rect.size - Vector2(24, 8)
	_reset_panel.position = reset_rect.position
	_reset_panel.size = reset_rect.size
	_reset_label.size = reset_rect.size - Vector2(20, 8)


static func calculate_bottom_hud_layout(viewport_size: Vector2, safe_margin: int) -> Dictionary:
	var inset: float = float(safe_margin) + HUD_EDGE_INSET
	var available_width: float = viewport_size.x - inset * 2.0
	var status_width: float = available_width - RESET_REGION_WIDTH - HUD_REGION_GAP
	var region_y: float = viewport_size.y - float(safe_margin) - HUD_EDGE_INSET - HUD_REGION_HEIGHT
	return {
		"safe":
		Rect2(
			Vector2(safe_margin, safe_margin),
			viewport_size - Vector2(safe_margin, safe_margin) * 2.0
		),
		"status": Rect2(Vector2(inset, region_y), Vector2(status_width, HUD_REGION_HEIGHT)),
		"reset":
		Rect2(
			Vector2(inset + status_width + HUD_REGION_GAP, region_y),
			Vector2(RESET_REGION_WIDTH, HUD_REGION_HEIGHT)
		),
	}


func _on_interaction_resolved(message: String) -> void:
	_message_label.text = message


func _resolve_board_interaction(interactable_id: String, seat_number: int) -> String:
	var mutation: Dictionary
	if interactable_id == "iron_gate":
		var next_state: String = (
			"closed" if _board_state.get_connector_state("hall_gate") == "open" else "open"
		)
		mutation = BoardMutation.connector("hall_gate", next_state)
	elif interactable_id == "clue_pedestal":
		var clue_active: bool = _board_state.get_space_state("lantern_hall").features.has(
			"clue_revealed"
		)
		mutation = BoardMutation.feature("lantern_hall", "clue_revealed", not clue_active)
	else:
		return ""
	var result: Dictionary = _board_state.apply_mutation(mutation, seat_number)
	if not result.accepted:
		return "BOARD MUTATION REJECTED: %s" % result.reason
	return (
		"BOARD r%d  •  %s"
		% [_board_state.revision, _board_state.get_history()[-1].summary.to_upper()]
	)


func _on_board_state_changed(_change: Dictionary) -> void:
	if not is_instance_valid(_interactions):
		return
	var gate: SandboxInteractable = _interactions.get_interactable("iron_gate")
	if gate != null:
		gate.set_active(_board_state.get_connector_state("hall_gate") == "open")
	var clue: SandboxInteractable = _interactions.get_interactable("clue_pedestal")
	if clue != null:
		clue.set_active(_board_state.get_space_state("lantern_hall").features.has("clue_revealed"))


func _on_board_mutation_rejected(reason: String) -> void:
	_message_label.text = "BOARD MUTATION REJECTED  •  %s" % reason.to_upper()
