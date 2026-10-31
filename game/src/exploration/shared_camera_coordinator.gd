class_name SharedCameraCoordinator
extends Camera2D

const POSITION_RESPONSE: float = 5.0
const ZOOM_RESPONSE: float = 4.0
const REFERENCE_VIEWPORT: Vector2 = Vector2(960.0, 540.0)
const POLICY_INTERVAL_SECONDS: float = 0.10
const PRESENTATION_LAYER: int = 9
const MAX_ADAPTIVE_PANES: int = 4
const PANE_LABEL_HEIGHT: float = 28.0

var room_bounds: Rect2 = ExplorationRoom.BOUNDS
var target_position: Vector2
var target_zoom: float = 1.0
var separation_state: SharedCameraPolicy.SeparationState = SharedCameraPolicy.SeparationState.NORMAL
var reduced_motion: bool = false
var presentation_mode: int = AdaptivePresentationPolicy.Mode.SHARED
var presentation_snapshot: Dictionary = {}

var _presentation_policy := AdaptivePresentationPolicy.new()
var _policy_elapsed: float = 0.0
var _seat_signature: String = ""
var _overlay_layer: CanvasLayer
var _overlay_root: Control
var _pane_viewports: Array[SubViewport] = []
var _pane_cameras: Array[Camera2D] = []
var _pane_textures: Array[TextureRect] = []
var _pane_labels: Array[Label] = []


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
	var frame: Dictionary = SharedCameraPolicy.calculate_frame(
		positions, REFERENCE_VIEWPORT, room_bounds
	)
	target_position = frame.center
	target_zoom = frame.zoom
	separation_state = frame.separation
	_update_shared_camera(delta)
	_update_adaptive_presentation(pawns, delta)


func active_pane_count() -> int:
	var count: int = 0
	for texture: TextureRect in _pane_textures:
		if texture.visible:
			count += 1
	return count


static func calculate_pane_rects(
	mode: int, orientation: String, pane_count: int, viewport_size: Vector2 = REFERENCE_VIEWPORT
) -> Array[Rect2]:
	var result: Array[Rect2] = []
	if pane_count <= 0:
		return result
	match mode:
		AdaptivePresentationPolicy.Mode.SPLIT_2:
			var count: int = mini(pane_count, 2)
			if orientation == "horizontal":
				var pane_height: float = viewport_size.y * 0.5
				for index: int in count:
					(
						result
						. append(
							Rect2(
								Vector2(0.0, pane_height * index),
								Vector2(viewport_size.x, pane_height),
							)
						)
					)
			else:
				var pane_width: float = viewport_size.x * 0.5
				for index: int in count:
					(
						result
						. append(
							Rect2(
								Vector2(pane_width * index, 0.0),
								Vector2(pane_width, viewport_size.y),
							)
						)
					)
		AdaptivePresentationPolicy.Mode.SPLIT_4:
			var count: int = mini(pane_count, 4)
			var pane_size: Vector2 = viewport_size * 0.5
			for index: int in count:
				var column: int = index % 2
				var row: int = index / 2
				result.append(Rect2(Vector2(column, row) * pane_size, pane_size))
		_:
			result.append(Rect2(Vector2.ZERO, viewport_size))
	return result


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
		presentation_snapshot = _presentation_policy.update(
			players, REFERENCE_VIEWPORT, sample_delta, false
		)
		presentation_mode = presentation_snapshot.get(
			"mode", AdaptivePresentationPolicy.Mode.SHARED
		)
		_policy_elapsed = 0.0
		_seat_signature = signature
	_refresh_adaptive_panes(pawns, delta)


func _refresh_adaptive_panes(pawns: Array[PawnState], delta: float) -> void:
	var split_active: bool = (
		presentation_mode
		in [AdaptivePresentationPolicy.Mode.SPLIT_2, AdaptivePresentationPolicy.Mode.SPLIT_4]
	)
	enabled = not split_active
	_overlay_root.visible = split_active
	if not split_active:
		_disable_all_panes()
		return
	var clusters: Array = presentation_snapshot.get("clusters", [])
	var rects: Array[Rect2] = calculate_pane_rects(
		presentation_mode,
		str(presentation_snapshot.get("orientation", "vertical")),
		clusters.size(),
		REFERENCE_VIEWPORT,
	)
	for index: int in MAX_ADAPTIVE_PANES:
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
		_configure_pane(index, rect, seats, positions, delta)


func _configure_pane(
	index: int, rect: Rect2, seats: Array, positions: Array[Vector2], delta: float
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
	label.text = _format_seats(seats)
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
	for index: int in MAX_ADAPTIVE_PANES:
		var viewport := SubViewport.new()
		viewport.name = "AdaptivePaneViewport%d" % (index + 1)
		viewport.disable_3d = true
		viewport.size = Vector2i(480, 270)
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
		label.add_theme_font_size_override("font_size", 18)
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
		label.add_theme_constant_override("outline_size", 4)
		label.visible = false
		_overlay_root.add_child(label)
		_pane_labels.append(label)


func _disable_all_panes() -> void:
	for index: int in MAX_ADAPTIVE_PANES:
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


func _format_seats(seats: Array) -> String:
	var result := "SEATS "
	for index: int in seats.size():
		if index > 0:
			result += " · "
		result += str(int(seats[index]))
	return result
