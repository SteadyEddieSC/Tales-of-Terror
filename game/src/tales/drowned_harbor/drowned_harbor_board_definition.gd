class_name DrownedHarborBoardDefinition
extends BoardDefinition


func _init() -> void:
	board_id = "drowned_harbor_scaffold_board"
	board_version = 1
	required_space_ids = PackedStringArray(["scaffold_harbor"])
	spaces = [
		{
			"id": "scaffold_harbor",
			"name": "Drowned Harbor Scaffold",
			"type": "scaffold",
			"tags": ["developer_only", "placeholder"],
			"areas": [Rect2(0, 0, 960, 540)],
			"label_position": Vector2(480, 270),
			"spawn_locations": [Vector2(480, 320)],
			"initial_revealed": true,
			"initial_hazards": [],
			"initial_features": ["structural_scaffold_only"],
			"initial_blockers": [],
		}
	]
	connectors = []
