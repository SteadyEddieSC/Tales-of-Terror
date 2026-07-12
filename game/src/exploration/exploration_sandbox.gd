class_name ExplorationSandbox
extends Node2D

const TOKENS: VisualTokens = preload("res://assets/theme/visual_tokens.tres")
const LAB_THEME: Theme = preload("res://assets/theme/terror_lab_theme.tres")
const HUD_EDGE_INSET: float = 10.0
const HUD_REGION_HEIGHT: float = 52.0
const HUD_REGION_GAP: float = 16.0
const RESET_REGION_WIDTH: float = 324.0

var pawn_registry := PawnRegistry.new()
var _pawn_nodes: Dictionary = {}
var _input_router: PlayerInputRouter
var _room: ExplorationRoom
var _camera: SharedCameraCoordinator
var _interactions: InteractionCoordinator
var _diagnostics: ExplorationDiagnostics
var _message_label: Label
var _separation_label: Label
var _reset_label: Label
var _status_panel: Panel
var _reset_panel: Panel
var _safe_overlay: SafeAreaOverlay
var _showcase_mode: bool = false
var _safe_margin: int = 24

func setup(input_router: PlayerInputRouter) -> void:
	_input_router = input_router

func _ready() -> void:
	_room = ExplorationRoom.new()
	add_child(_room)
	_interactions = InteractionCoordinator.new()
	add_child(_interactions)
	_interactions.interaction_resolved.connect(_on_interaction_resolved)
	_add_interactable("iron_gate", SandboxInteractable.Kind.DOOR, Vector2(910, 500))
	_add_interactable("clue_pedestal", SandboxInteractable.Kind.CLUE, Vector2(650, 585))
	_camera = SharedCameraCoordinator.new()
	add_child(_camera)
	_build_hud()

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

func request_interaction(device_id: int) -> bool:
	return _interactions.request(pawn_registry.get_by_device(device_id))

func toggle_diagnostics() -> void:
	_diagnostics.toggle()

func set_safe_margin(value: int) -> void:
	_safe_margin = clampi(value, 0, 48)
	_safe_overlay.set_frame_margin(_safe_margin)
	_layout_bottom_hud()

func present_reset_progress(progress: float) -> void:
	_reset_label.text = "HOLD Y / R 1.5s TO RETURN TO LAB" if progress <= 0.0 else "RETURNING TO LAB… %d%%" % roundi(progress * 100.0)

func enable_showcase() -> void:
	_showcase_mode = true
	var showcase_positions: Array[Vector2] = [Vector2(600, 540), Vector2(680, 520), Vector2(850, 490), Vector2(1200, 500)]
	for index: int in mini(showcase_positions.size(), pawn_registry.get_pawns().size()):
		var pawn: PawnState = pawn_registry.get_pawns()[index]
		pawn.position = showcase_positions[index]
		(_pawn_nodes[pawn.seat_number] as ExplorationPawn).global_position = pawn.position
	_interactions.get_interactable("iron_gate").interact(2)
	_interactions.get_interactable("clue_pedestal").interact(1)
	_message_label.text = "CLUE REVEALED • IRON GATE OPEN • LOWEST SEAT WINS CONFLICTS"
	_diagnostics.visible = true

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
		var resistance: float = SharedCameraPolicy.movement_resistance(pawn.position, raw_input, group_center)
		(_pawn_nodes[pawn.seat_number] as ExplorationPawn).apply_movement(raw_input, resistance, delta, ExplorationRoom.BOUNDS)
	_interactions.update_focus(pawns)
	for pawn: PawnState in pawns:
		(_pawn_nodes[pawn.seat_number] as ExplorationPawn).set_interaction_focus(pawn.nearby_interactable != "—")
	_interactions.resolve_pending()
	_camera.update_group(pawns, delta)
	_separation_label.text = SharedCameraPolicy.state_label(_camera.separation_state)
	_separation_label.modulate = TOKENS.danger if _camera.separation_state == SharedCameraPolicy.SeparationState.REGROUP else TOKENS.warning
	_diagnostics.update_snapshot(pawns, _camera)

func _add_interactable(id: String, kind: SandboxInteractable.Kind, world_position: Vector2) -> void:
	var interactable := SandboxInteractable.new()
	interactable.setup(id, kind, world_position, TOKENS)
	add_child(interactable)
	_interactions.register(interactable)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = LAB_THEME
	layer.add_child(root)
	var title := Label.new()
	title.text = "SHARED EXPLORATION SANDBOX  •  v0.0.4"
	title.theme_type_variation = "SectionTitle"
	title.position = Vector2(34, 28)
	root.add_child(title)
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
	_message_label.text = "MOVE: LEFT STICK / WASD  •  INTERACT: A / E  •  DIAGNOSTICS: X / T"
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
	_safe_overlay = SafeAreaOverlay.new()
	_safe_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_safe_overlay.frame_color = TOKENS.warning
	root.add_child(_safe_overlay)
	_layout_bottom_hud()

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
		"safe": Rect2(Vector2(safe_margin, safe_margin), viewport_size - Vector2(safe_margin, safe_margin) * 2.0),
		"status": Rect2(Vector2(inset, region_y), Vector2(status_width, HUD_REGION_HEIGHT)),
		"reset": Rect2(Vector2(inset + status_width + HUD_REGION_GAP, region_y), Vector2(RESET_REGION_WIDTH, HUD_REGION_HEIGHT)),
	}

func _on_interaction_resolved(message: String) -> void:
	_message_label.text = message
