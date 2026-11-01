class_name SharedCameraCoordinator
extends Camera2D

enum CommonPaneState { MAP_BOARD, OBJECTIVE_PHASE, TERROR_EVENT }

const POSITION_RESPONSE: float = 5.0
const ZOOM_RESPONSE: float = 4.0
const REFERENCE_VIEWPORT: Vector2 = Vector2(960.0, 540.0)
const POLICY_INTERVAL_SECONDS: float = 0.10
const PRESENTATION_LAYER: int = 9
const MAX_PRESENTATION_PANES: int = 8
const PANE_LABEL_HEIGHT: float = 44.0
const COMMON_TITLE_HEIGHT: float = 24.0
const RESERVED_REGION_GAP: float = 12.0

var room_bounds: Rect2 = ExplorationRoom.BOUNDS
var target_position: Vector2
var target_zoom: float = 1.0
var separation_state: SharedCameraPolicy.SeparationState = SharedCameraPolicy.SeparationState.NORMAL
var reduced_motion: bool = false
var presentation_mode: int = AdaptivePresentationPolicy.Mode.SHARED
var presentation_snapshot: Dictionary = {}
var grid_allowed: bool = false
var common_pane_state: int = CommonPaneState.MAP_BOARD
var common_pane_payload: Dictionary = {}
var reserved_hud_rect: Rect2 = Rect2()

var _presentation_policy := AdaptivePresentationPolicy.new()
var _policy_elapsed: float = 0.0
var _seat_signature: String = ""
var _overlay_layer: CanvasLayer
var _overlay_root: Control
var _pane_viewports: Array[SubViewport] = []
var _pane_cameras: Array[Camera2D] = []
var _pane_textures: Array[TextureRect] = []
var _pane_labels: Array[Label] = []
var _common_panel: Panel
var _common_title: Label
var _common_body: Label
var _common_markers: Array[Label] = []


func _ready() -> void:
	enabled = true
	position = room_bounds.get_center()
	target_position = position
	zoom = Vector2.ONE
	_build_adaptive_presentation()


func update_group(pawns: Array[PawnState], delta: float) -> void:
	var positions: Array[Vector2] = []
	for pawn: PawnState in pawns:
		positions.append(pawn.position)
	var content_rect: Rect2 = calculate_content_rect(REFERENCE_VIEWPORT, reserved_hud_rect)
	var frame: Dictionary = SharedCameraPolicy.calculate_frame(
		positions, content_rect.size, room_bounds
	)
	var frame_center: Vector2 = frame.center
	frame_center.x += (REFERENCE_VIEWPORT.x * 0.5 - content_rect.get_center().x) / float(frame.zoom)
	target_position = frame_center
	target_zoom = frame.zoom
	separation_state = frame.separation
	_update_shared_camera(delta)
	_update_adaptive_presentation(pawns, delta)


func set_grid_allowed(value: bool) -> void:
	grid_allowed = value


func set_reserved_hud_rect(rect: Rect2) -> void:
	reserved_hud_rect = rect
	target_position = position
	_policy_elapsed = POLICY_INTERVAL_SECONDS


static func calculate_content_rect(
	viewport_size: Vector2, reserved_rect: Rect2, gap: float = RESERVED_REGION_GAP
) -> Rect2:
	if reserved_rect.size.x <= 0.0 or reserved_rect.size.y <= 0.0:
		return Rect2(Vector2.ZERO, viewport_size)
	var content_width: float = clampf(reserved_rect.position.x - gap, 1.0, viewport_size.x)
	return Rect2(Vector2.ZERO, Vector2(content_width, viewport_size.y))


func set_common_pane(state: int, payload: Dictionary = {}) -> void:
	common_pane_state = clampi(state, CommonPaneState.MAP_BOARD, CommonPaneState.TERROR_EVENT)
	common_pane_payload = payload.duplicate(true)
	_refresh_common_pane_content()


func active_pane_count() -> int:
	var count: int = 0
	for texture: TextureRect in _pane_textures:
		if texture.visible:
			count += 1
	return count


static func calculate_pane_rects(
	mode: int,
	orientation: String,
	pane_count: int,
	viewport_size: Vector2 = REFERENCE_VIEWPORT,
	content_rect: Rect2 = Rect2()
) -> Array[Rect2]:
	var result: Array[Rect2] = []
	if pane_count <= 0:
		return result
	var layout_rect: Rect2 = (
		content_rect
		if content_rect.size.x > 0.0 and content_rect.size.y > 0.0
		else Rect2(Vector2.ZERO, viewport_size)
	)
	var layout_size: Vector2 = layout_rect.size
	match mode:
		AdaptivePresentationPolicy.Mode.SPLIT_2:
			var count: int = mini(pane_count, 2)
			if orientation == "horizontal":
				var pane_height: float = layout_size.y * 0.5
				for index: int in count:
					(
						result
						. append(
							Rect2(
								layout_rect.position + Vector2(0.0, pane_height * index),
								Vector2(layout_size.x, pane_height),
							)
						)
					)
			else:
				var pane_width: float = layout_size.x * 0.5
				for index: int in count:
					(
						result
						. append(
							Rect2(
								layout_rect.position + Vector2(pane_width * index, 0.0),
								Vector2(pane_width, layout_size.y),
							)
						)
					)
		AdaptivePresentationPolicy.Mode.SPLIT_4:
			var count: int = mini(pane_count, 4)
			var pane_size: Vector2 = layout_size * 0.5
			for index: int in count:
				var column: int = index % 2
				var row: int = index / 2
				result.append(
					Rect2(layout_rect.position + Vector2(column, row) * pane_size, pane_size)
				)
		AdaptivePresentationPolicy.Mode.GRID_3X3:
			var count: int = mini(pane_count, 8)
			var cell_size: Vector2 = layout_size / 3.0
			var cells: Array[Vector2i] = _grid_outer_cells()
			for index: int in count:
				var cell: Vector2i = cells[index]
				result.append(
					Rect2(layout_rect.position + Vector2(cell.x, cell.y) * cell_size, cell_size)
				)
		_:
			result.append(layout_rect)
	return result


static func calculate_common_pane_rect(
	viewport_size: Vector2 = REFERENCE_VIEWPORT,
) -> Rect2:
	var cell_size: Vector2 = viewport_size / 3.0
	return Rect2(cell_size, cell_size)


static func common_pane_state_label(state: int) -> String:
	var labels: Array[String] = ["MAP / BOARD", "OBJECTIVE / PHASE", "TERROR EVENT"]
	return labels[clampi(state, CommonPaneState.MAP_BOARD, CommonPaneState.TERROR_EVENT)]


static func _grid_outer_cells() -> Array[Vector2i]:
	return [
		Vector2i(0, 0),
		Vector2i(1, 0),
		Vector2i(2, 0),
		Vector2i(0, 1),
		Vector2i(2, 1),
		Vector2i(0, 2),
		Vector2i(1, 2),
		Vector2i(2, 2),
	]


func _update_shared_camera(delta: float) -> void:
	if reduced_motion:
		position = target_position
		zoom = Vector2.ONE * target_zoom
		return
	var position_weight: float = 1.0 - exp(-POSITION_RESPONSE * delta)
	var zoom_weight: float = 1.0 - exp(-ZOOM_RESPONSE * delta)
	position = position.lerp(target_position, position_weight)
	zoom = zoom.lerp(Vector2.ONE * target_zoom, zoom_weight)


func _update_adaptive_presentation(pawns: Array[PawnState], delta: float) -> void:
	_policy_elapsed += maxf(delta, 0.0)
	var signature: String = _build_seat_signature(pawns)
	var should_sample: bool = (
		presentation_snapshot.is_empty()
		or signature != _seat_signature
		or _policy_elapsed >= POLICY_INTERVAL_SECONDS
	)
	if should_sample:
		var players: Array[Dictionary] = []
		for pawn: PawnState in pawns:
			players.append({"seat_number": pawn.seat_number, "position": pawn.position})
		var sample_delta: float = 0.0 if presentation_snapshot.is_empty() else _policy_elapsed
		var content_rect: Rect2 = calculate_content_rect(REFERENCE_VIEWPORT, reserved_hud_rect)
		presentation_snapshot = _presentation_policy.update(
			players, content_rect.size, sample_delta, grid_allowed
		)
		presentation_mode = presentation_snapshot.get(
			"mode", AdaptivePresentationPolicy.Mode.SHARED
		)
		_policy_elapsed = 0.0
		_seat_signature = signature
	_refresh_adaptive_panes(pawns, delta)


func _refresh_adaptive_panes(pawns: Array[PawnState], delta: float) -> void:
	var adaptive_active: bool = (
		presentation_mode
		in [
			AdaptivePresentationPolicy.Mode.SPLIT_2,
			AdaptivePresentationPolicy.Mode.SPLIT_4,
			AdaptivePresentationPolicy.Mode.GRID_3X3,
		]
	)
	var grid_active: bool = presentation_mode == AdaptivePresentationPolicy.Mode.GRID_3X3
	enabled = not adaptive_active
	_overlay_root.visible = adaptive_active
	_common_panel.visible = grid_active
	if not adaptive_active:
		_disable_all_panes()
		_hide_common_markers()
		return
	var clusters: Array = presentation_snapshot.get("clusters", [])
	var rects: Array[Rect2] = calculate_pane_rects(
		presentation_mode,
		str(presentation_snapshot.get("orientation", "vertical")),
		clusters.size(),
		REFERENCE_VIEWPORT,
		calculate_content_rect(REFERENCE_VIEWPORT, reserved_hud_rect),
	)
	for index: int in MAX_PRESENTATION_PANES:
		var active: bool = index < clusters.size() and index < rects.size()
		if not active:
			_disable_pane(index)
			continue
		var cluster: Dictionary = clusters[index]
		var rect: Rect2 = rects[index]
		var positions: Array[Vector2] = []
		var seats: Array = cluster.get("seats", [])
		for seat_value: Variant in seats:
			var pawn: PawnState = _pawn_for_seat(pawns, int(seat_value))
			if pawn != null:
				positions.append(pawn.position)
		_configure_pane(index, rect, seats, positions, pawns, delta, grid_active)
	if grid_active:
		_configure_common_pane(pawns)
	else:
		_hide_common_markers()


func _configure_pane(
	index: int,
	rect: Rect2,
	seats: Array,
	positions: Array[Vector2],
	pawns: Array[PawnState],
	delta: float,
	grid_mode: bool,
) -> void:
	var viewport: SubViewport = _pane_viewports[index]
	var camera: Camera2D = _pane_cameras[index]
	var texture: TextureRect = _pane_textures[index]
	var label: Label = _pane_labels[index]
	var first_activation: bool = not camera.enabled
	viewport.size = Vector2i(
		maxi(2, roundi(rect.size.x)),
		maxi(2, roundi(rect.size.y)),
	)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	texture.position = rect.position
	texture.size = rect.size
	texture.visible = true
	label.position = rect.position + Vector2(8.0, 6.0)
	label.size = Vector2(maxf(120.0, rect.size.x - 16.0), PANE_LABEL_HEIGHT)
	label.text = _format_pane_label(seats, pawns, grid_mode)
	label.visible = true
	var frame: Dictionary = SharedCameraPolicy.calculate_frame(positions, rect.size, room_bounds)
	var next_position: Vector2 = frame.center
	var next_zoom: Vector2 = Vector2.ONE * float(frame.zoom)
	camera.enabled = true
	if first_activation or reduced_motion:
		camera.position = next_position
		camera.zoom = next_zoom
		return
	var position_weight: float = 1.0 - exp(-POSITION_RESPONSE * delta)
	var zoom_weight: float = 1.0 - exp(-ZOOM_RESPONSE * delta)
	camera.position = camera.position.lerp(next_position, position_weight)
	camera.zoom = camera.zoom.lerp(next_zoom, zoom_weight)


func _configure_common_pane(pawns: Array[PawnState]) -> void:
	var content_rect: Rect2 = calculate_content_rect(REFERENCE_VIEWPORT, reserved_hud_rect)
	var rect: Rect2 = calculate_common_pane_rect(content_rect.size)
	rect.position += content_rect.position
	_common_panel.position = rect.position
	_common_panel.size = rect.size
	_common_title.position = Vector2(8.0, 6.0)
	_common_title.size = Vector2(rect.size.x - 16.0, COMMON_TITLE_HEIGHT)
	_common_body.position = Vector2(8.0, 34.0)
	_common_body.size = Vector2(rect.size.x - 16.0, rect.size.y - 42.0)
	_refresh_common_pane_content()
	if common_pane_state == CommonPaneState.MAP_BOARD:
		_layout_common_markers(pawns, rect.size)
	else:
		_hide_common_markers()


func _refresh_common_pane_content() -> void:
	if not is_instance_valid(_common_title) or not is_instance_valid(_common_body):
		return
	_common_title.text = common_pane_state_label(common_pane_state)
	match common_pane_state:
		CommonPaneState.MAP_BOARD:
			_common_body.text = str(
				common_pane_payload.get("summary", "PLAYER PRESENCE · SHARED AREA OVERVIEW")
			)
		CommonPaneState.OBJECTIVE_PHASE:
			_common_body.text = str(
				common_pane_payload.get(
					"summary", "SYNTHETIC OBJECTIVE\nPHASE STATE / TIMER SURFACE"
				)
			)
		CommonPaneState.TERROR_EVENT:
			_common_body.text = str(
				common_pane_payload.get("summary", "SYNTHETIC HIGH WATER / GLOBAL HAZARD SURFACE")
			)


func _layout_common_markers(pawns: Array[PawnState], panel_size: Vector2) -> void:
	var map_rect := Rect2(Vector2(10.0, 66.0), panel_size - Vector2(20.0, 78.0))
	for index: int in _common_markers.size():
		var marker: Label = _common_markers[index]
		if index >= pawns.size():
			marker.visible = false
			continue
		var pawn: PawnState = pawns[index]
		var normalized := Vector2(
			inverse_lerp(room_bounds.position.x, room_bounds.end.x, pawn.position.x),
			inverse_lerp(room_bounds.position.y, room_bounds.end.y, pawn.position.y),
		)
		normalized.x = clampf(normalized.x, 0.0, 1.0)
		normalized.y = clampf(normalized.y, 0.0, 1.0)
		marker.position = Vector2(
			lerpf(map_rect.position.x, map_rect.end.x - marker.size.x, normalized.x),
			lerpf(map_rect.position.y, map_rect.end.y - marker.size.y, normalized.y),
		)
		marker.text = "%s%d" % ["●" if pawn.connected else "×", pawn.seat_number]
		marker.visible = true


func _hide_common_markers() -> void:
	for marker: Label in _common_markers:
		marker.visible = false


func _build_adaptive_presentation() -> void:
	_overlay_layer = CanvasLayer.new()
	_overlay_layer.layer = PRESENTATION_LAYER
	add_child(_overlay_layer)
	_overlay_root = Control.new()
	_overlay_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay_root.visible = false
	_overlay_layer.add_child(_overlay_root)
	var shared_world: World2D = get_viewport().world_2d
	for index: int in MAX_PRESENTATION_PANES:
		var viewport := SubViewport.new()
		viewport.name = "AdaptivePaneViewport%d" % (index + 1)
		viewport.disable_3d = true
		viewport.size = Vector2i(320, 180)
		viewport.world_2d = shared_world
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		add_child(viewport)
		_pane_viewports.append(viewport)
		var pane_camera := Camera2D.new()
		pane_camera.name = "AdaptivePaneCamera%d" % (index + 1)
		pane_camera.enabled = false
		pane_camera.position = room_bounds.get_center()
		viewport.add_child(pane_camera)
		_pane_cameras.append(pane_camera)
		var texture := TextureRect.new()
		texture.name = "AdaptivePaneTexture%d" % (index + 1)
		texture.texture = viewport.get_texture()
		texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		texture.stretch_mode = TextureRect.STRETCH_SCALE
		texture.visible = false
		_overlay_root.add_child(texture)
		_pane_textures.append(texture)
		var label := Label.new()
		label.name = "AdaptivePaneLabel%d" % (index + 1)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.clip_text = true
		label.add_theme_font_size_override("font_size", 16)
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
		label.add_theme_constant_override("outline_size", 4)
		label.visible = false
		_overlay_root.add_child(label)
		_pane_labels.append(label)
	_build_common_pane()


func _build_common_pane() -> void:
	_common_panel = Panel.new()
	_common_panel.name = "AdaptiveCommonPane"
	_common_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_common_panel.visible = false
	_overlay_root.add_child(_common_panel)
	_common_title = Label.new()
	_common_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_common_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_common_title.add_theme_font_size_override("font_size", 18)
	_common_title.add_theme_color_override("font_color", Color.WHITE)
	_common_panel.add_child(_common_title)
	_common_body = Label.new()
	_common_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_common_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_common_body.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_common_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_common_body.add_theme_font_size_override("font_size", 14)
	_common_body.add_theme_color_override("font_color", Color.WHITE)
	_common_panel.add_child(_common_body)
	for index: int in MAX_PRESENTATION_PANES:
		var marker := Label.new()
		marker.name = "CommonMapSeat%d" % (index + 1)
		marker.size = Vector2(34.0, 22.0)
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		marker.add_theme_font_size_override("font_size", 14)
		marker.add_theme_color_override("font_color", Color.WHITE)
		marker.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
		marker.add_theme_constant_override("outline_size", 3)
		marker.visible = false
		_common_panel.add_child(marker)
		_common_markers.append(marker)
	_refresh_common_pane_content()


func _disable_all_panes() -> void:
	for index: int in MAX_PRESENTATION_PANES:
		_disable_pane(index)


func _disable_pane(index: int) -> void:
	_pane_viewports[index].render_target_update_mode = SubViewport.UPDATE_DISABLED
	_pane_cameras[index].enabled = false
	_pane_textures[index].visible = false
	_pane_labels[index].visible = false


func _pawn_for_seat(pawns: Array[PawnState], seat_number: int) -> PawnState:
	for pawn: PawnState in pawns:
		if pawn.seat_number == seat_number:
			return pawn
	return null


func _build_seat_signature(pawns: Array[PawnState]) -> String:
	var seats: Array[int] = []
	for pawn: PawnState in pawns:
		seats.append(pawn.seat_number)
	seats.sort()
	var result := ""
	for index: int in seats.size():
		if index > 0:
			result += "-"
		result += str(seats[index])
	return result


func _format_pane_label(seats: Array, pawns: Array[PawnState], grid_mode: bool) -> String:
	if not grid_mode or seats.size() != 1:
		return _format_seats(seats)
	var seat_number: int = int(seats[0])
	var pawn: PawnState = _pawn_for_seat(pawns, seat_number)
	if pawn == null:
		return "SEAT %d · DISCONNECTED\nFOCUS —" % seat_number
	var connection: String = "CONNECTED" if pawn.connected else "DISCONNECTED"
	var focus: String = "—"
	if pawn.nearby_interactable != "—":
		focus = pawn.nearby_interactable.to_upper().replace("_", " ")
	return "SEAT %d · %s\nFOCUS %s" % [seat_number, connection, focus]


func _format_seats(seats: Array) -> String:
	var result := "SEATS "
	for index: int in seats.size():
		if index > 0:
			result += " · "
		result += str(int(seats[index]))
	return result
