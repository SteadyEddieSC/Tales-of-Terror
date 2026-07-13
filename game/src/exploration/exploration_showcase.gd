extends Node2D

func _ready() -> void:
	var sandbox := ExplorationSandbox.new()
	add_child(sandbox)
	var seats: Array[Dictionary] = []
	for index: int in SeatManager.MAX_SEATS:
		var state: int = SeatManager.SeatState.ACTIVE if index < 4 else SeatManager.SeatState.UNASSIGNED
		seats.append({
			"seat_number": index + 1,
			"state": state,
			"device_id": index,
			"identity": "showcase-%d" % index,
			"device_name": "Showcase",
			"last_action": "interact" if index < 2 else "move_right",
		})
	sandbox.sync_seats(seats)
	var stage: String = "terminal"
	var evidence_output: String = ""
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--evidence-stage="):
			stage = argument.trim_prefix("--evidence-stage=")
		elif argument.begins_with("--evidence-output="):
			evidence_output = argument.trim_prefix("--evidence-output=")
	sandbox.enable_showcase(stage)
	if OS.get_cmdline_user_args().has("--diagnostics"):
		sandbox.toggle_diagnostics()
	if not evidence_output.is_empty():
		for _frame: int in 12:
			await RenderingServer.frame_post_draw
		var image: Image = get_viewport().get_texture().get_image()
		var result: Error = image.save_png(evidence_output)
		print("Evidence capture %s: %s" % [evidence_output, error_string(result)])
		get_tree().quit(0 if result == OK else 1)
