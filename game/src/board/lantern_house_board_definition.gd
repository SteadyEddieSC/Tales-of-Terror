class_name LanternHouseBoardDefinition
extends BoardDefinition


func _init() -> void:
	board_id = "lantern_house"
	board_version = 1
	required_space_ids = PackedStringArray(["lantern_hall", "gate_passage", "narrow_gallery"])
	spaces = [
		_space(
			"lantern_hall",
			"The Lantern Hall",
			"room",
			["safe", "spawn"],
			[Rect2(32, 32, 858, 936)],
			Vector2(520, 330),
			true,
			[],
			["hearth"],
			[]
		),
		_space(
			"gate_passage",
			"The Iron Threshold",
			"corridor",
			["special"],
			[Rect2(890, 397, 298, 206)],
			Vector2(1038, 450),
			true,
			[],
			[],
			[]
		),
		_space(
			"narrow_gallery",
			"The Narrow Gallery",
			"room",
			["dangerous"],
			[
				Rect2(928, 32, 840, 230),
				Rect2(928, 262, 274, 306),
				Rect2(1448, 262, 320, 300),
				Rect2(928, 568, 274, 400),
				Rect2(1660, 562, 108, 406),
				Rect2(1202, 700, 458, 268),
			],
			Vector2(1450, 820),
			true,
			[],
			[],
			[]
		),
		_space(
			"sealed_archive",
			"The Sealed Archive",
			"objective",
			["objective", "special"],
			[Rect2(1202, 262, 246, 300)],
			Vector2(1325, 340),
			false,
			[],
			["sealed_shelves"],
			[]
		),
		_space(
			"flooded_vault",
			"The Flooded Vault",
			"room",
			["dangerous", "special"],
			[Rect2(1202, 562, 458, 138)],
			Vector2(1430, 605),
			true,
			["black_water"],
			[],
			["flooded_floor"]
		),
	]
	connectors = [
		_connector("hall_gate", "lantern_hall", "gate_passage", "door", "closed"),
		_connector("gate_to_narrow", "gate_passage", "narrow_gallery", "open_passage", "open"),
		_connector("archive_route", "narrow_gallery", "sealed_archive", "scenario_link", "open"),
		_connector("vault_lock", "narrow_gallery", "flooded_vault", "locked_door", "locked"),
		_connector("archive_stairs", "sealed_archive", "flooded_vault", "one_way", "open", true),
	]


func _space(
	id: String,
	display_name: String,
	type: String,
	tags: Array[String],
	areas: Array[Rect2],
	label_position: Vector2,
	revealed: bool,
	hazards: Array[String],
	features: Array[String],
	blockers: Array[String]
) -> Dictionary:
	return {
		"id": id,
		"name": display_name,
		"type": type,
		"tags": tags,
		"areas": areas,
		"label_position": label_position,
		"spawn_locations":
		(
			[
				Vector2(310, 430),
				Vector2(380, 430),
				Vector2(450, 430),
				Vector2(520, 430),
				Vector2(310, 500),
				Vector2(380, 500),
				Vector2(450, 500),
				Vector2(520, 500),
			]
			if id == "lantern_hall"
			else []
		),
		"initial_revealed": revealed,
		"initial_hazards": hazards,
		"initial_features": features,
		"initial_blockers": blockers,
	}


func _connector(
	id: String, from_id: String, to_id: String, type: String, state: String, one_way: bool = false
) -> Dictionary:
	return {
		"id": id,
		"from": from_id,
		"to": to_id,
		"type": type,
		"initial_state": state,
		"one_way": one_way
	}
