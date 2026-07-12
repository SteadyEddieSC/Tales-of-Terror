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
	sandbox.enable_showcase()
