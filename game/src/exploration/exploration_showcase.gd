extends Node2D

const SCREEN_STAGE_PREFIX: String = "screen_"
const CAPTURE_FRAMES: int = 24


func _ready() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	var stage: String = _argument_value(arguments, "--evidence-stage=", "terminal")
	var evidence_output: String = _argument_value(arguments, "--evidence-output=", "")
	var evidence_metrics: String = _argument_value(arguments, "--evidence-metrics=", "")
	var sandbox := ExplorationSandbox.new()
	add_child(sandbox)
	var seats: Array[Dictionary] = []
	var active_count: int = SeatManager.MAX_SEATS if stage.begins_with(SCREEN_STAGE_PREFIX) else 4
	for index: int in SeatManager.MAX_SEATS:
		var state: int = (
			SeatManager.SeatState.ACTIVE
			if index < active_count
			else SeatManager.SeatState.UNASSIGNED
		)
		(
			seats
			. append(
				{
					"seat_number": index + 1,
					"state": state,
					"device_id": index,
					"identity": "showcase-%d" % index,
					"device_name": "Showcase",
					"last_action": "interact" if index < 2 else "move_right",
				}
			)
		)
	sandbox.sync_seats(seats)
	if stage.begins_with(SCREEN_STAGE_PREFIX):
		_configure_screen_stage(sandbox, stage)
	else:
		sandbox.enable_showcase(stage)
	if arguments.has("--diagnostics"):
		sandbox.toggle_diagnostics()
	if evidence_output.is_empty() and evidence_metrics.is_empty():
		return
	for _frame: int in CAPTURE_FRAMES:
		await RenderingServer.frame_post_draw
	var image: Image = get_viewport().get_texture().get_image()
	var image_result: Error = OK
	if not evidence_output.is_empty():
		image_result = image.save_png(evidence_output)
		print("Evidence capture %s: %s" % [evidence_output, error_string(image_result)])
	var metrics_result: Error = OK
	if not evidence_metrics.is_empty():
		metrics_result = _save_metrics(
			evidence_metrics, _capture_metrics(sandbox, stage, image.get_size())
		)
		print("Evidence metrics %s: %s" % [evidence_metrics, error_string(metrics_result)])
	get_tree().quit(0 if image_result == OK and metrics_result == OK else 1)


func _argument_value(arguments: PackedStringArray, prefix: String, fallback: String) -> String:
	for argument: String in arguments:
		if argument.begins_with(prefix):
			return argument.trim_prefix(prefix)
	return fallback


func _configure_screen_stage(sandbox: ExplorationSandbox, stage: String) -> void:
	sandbox.set("_showcase_mode", true)
	var pawns: Array[PawnState] = sandbox.pawn_registry.get_pawns()
	var positions: Array[Vector2] = _screen_positions(stage)
	var pawn_nodes: Dictionary = sandbox.get("_pawn_nodes")
	for index: int in mini(pawns.size(), positions.size()):
		var pawn: PawnState = pawns[index]
		pawn.position = positions[index]
		var pawn_node := pawn_nodes.get(pawn.seat_number) as ExplorationPawn
		if pawn_node != null:
			pawn_node.global_position = pawn.position
	var board_state := sandbox.get("_board_state") as BoardState
	if board_state != null:
		board_state.sync_occupancy(pawns)
	var camera := sandbox.get("_camera") as SharedCameraCoordinator
	camera.set_grid_allowed(stage.begins_with("screen_grid_"))
	match stage:
		"screen_grid_objective":
			(
				camera
				. set_common_pane(
					SharedCameraCoordinator.CommonPaneState.OBJECTIVE_PHASE,
					{"summary": "OBJECTIVE: RESTORE THE LANTERN\nPHASE 2 / 4 · 02:18 REMAINING"},
				)
			)
		"screen_grid_terror":
			(
				camera
				. set_common_pane(
					SharedCameraCoordinator.CommonPaneState.TERROR_EVENT,
					{"summary": "TERROR EVENT: HIGH WATER\nALL SEATS · GLOBAL HAZARD"},
				)
			)
		_:
			(
				camera
				. set_common_pane(
					SharedCameraCoordinator.CommonPaneState.MAP_BOARD,
					{"summary": "PLAYER PRESENCE · SHARED AREA OVERVIEW"},
				)
			)
	for _step: int in 4:
		camera.update_group(pawns, 0.40)
	var message_label := sandbox.get("_message_label") as Label
	if message_label != null:
		message_label.text = (
			"EVIDENCE: %s · PRESENTATION ONLY · ONE AUTHORITATIVE WORLD" % stage.to_upper()
		)
	var room := sandbox.get("_room") as ExplorationRoom
	if room != null:
		room.set_show_authored_headings(true)


func _screen_positions(stage: String) -> Array[Vector2]:
	match stage:
		"screen_shared":
			return ExplorationRoom.SPAWN_POINTS.duplicate()
		"screen_split_2":
			return [
				Vector2(220, 300),
				Vector2(300, 300),
				Vector2(220, 500),
				Vector2(300, 500),
				Vector2(1500, 300),
				Vector2(1580, 300),
				Vector2(1500, 500),
				Vector2(1580, 500),
			]
		"screen_split_4":
			return [
				Vector2(200, 180),
				Vector2(260, 180),
				Vector2(1540, 180),
				Vector2(1600, 180),
				Vector2(200, 820),
				Vector2(260, 820),
				Vector2(1540, 820),
				Vector2(1600, 820),
			]
		_:
			return [
				Vector2(70, 100),
				Vector2(630, 100),
				Vector2(1190, 100),
				Vector2(1750, 100),
				Vector2(70, 900),
				Vector2(630, 900),
				Vector2(1190, 900),
				Vector2(1750, 900),
			]


func _capture_metrics(
	sandbox: ExplorationSandbox, stage: String, image_size: Vector2i
) -> Dictionary:
	var root_viewport: Viewport = get_viewport()
	var camera := sandbox.get("_camera") as SharedCameraCoordinator
	var pane_viewports: Array = camera.get("_pane_viewports")
	var pane_textures: Array = camera.get("_pane_textures")
	var pane_stats: Array[Dictionary] = []
	var pane_draw_calls_total: int = 0
	for index: int in pane_viewports.size():
		if index >= pane_textures.size() or not (pane_textures[index] as TextureRect).visible:
			continue
		var viewport := pane_viewports[index] as Viewport
		var stats: Dictionary = _canvas_render_stats(viewport)
		stats["pane_index"] = index
		pane_stats.append(stats)
		pane_draw_calls_total += int(stats.draw_calls)
	return {
		"stage": stage,
		"image_width": image_size.x,
		"image_height": image_size.y,
		"window_width": get_window().size.x,
		"window_height": get_window().size.y,
		"rendering_method": RenderingServer.get_current_rendering_method(),
		"rendering_driver": RenderingServer.get_current_rendering_driver_name(),
		"fps": Engine.get_frames_per_second(),
		"process_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		"physics_ms": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		"frame_setup_cpu_ms": RenderingServer.get_frame_setup_time_cpu(),
		"presentation_mode": AdaptivePresentationPolicy.mode_label(camera.presentation_mode),
		"active_player_panes": camera.active_pane_count(),
		"common_pane_state":
		SharedCameraCoordinator.common_pane_state_label(camera.common_pane_state),
		"root_canvas": _canvas_render_stats(root_viewport),
		"pane_canvas_draw_calls_total": pane_draw_calls_total,
		"pane_canvas": pane_stats,
	}


func _canvas_render_stats(viewport: Viewport) -> Dictionary:
	var viewport_rid: RID = viewport.get_viewport_rid()
	return {
		"objects":
		(
			RenderingServer
			. viewport_get_render_info(
				viewport_rid,
				RenderingServer.VIEWPORT_RENDER_INFO_TYPE_CANVAS,
				RenderingServer.VIEWPORT_RENDER_INFO_OBJECTS_IN_FRAME,
			)
		),
		"primitives":
		(
			RenderingServer
			. viewport_get_render_info(
				viewport_rid,
				RenderingServer.VIEWPORT_RENDER_INFO_TYPE_CANVAS,
				RenderingServer.VIEWPORT_RENDER_INFO_PRIMITIVES_IN_FRAME,
			)
		),
		"draw_calls":
		(
			RenderingServer
			. viewport_get_render_info(
				viewport_rid,
				RenderingServer.VIEWPORT_RENDER_INFO_TYPE_CANVAS,
				RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME,
			)
		),
	}


func _save_metrics(path: String, metrics: Dictionary) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(metrics, "\t"))
	return OK
