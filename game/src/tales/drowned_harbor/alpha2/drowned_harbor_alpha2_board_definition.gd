class_name DrownedHarborAlpha2BoardDefinition
extends BoardDefinition


func _init() -> void:
	board_id = "drowned_harbor_graybox_board_v2"
	board_version = 2
	required_space_ids = PackedStringArray(
		[
			"harbor_gate",
			"low_tide_market",
			"bellhouse",
			"lighthouse_council",
			"high_water_channel",
			"last_light_beacon",
		]
	)
	spaces = [
		_space("harbor_gate", "Harbor Gate", "arrival", Rect2(40, 210, 120, 120)),
		_space("low_tide_market", "Low-Tide Market", "landmark", Rect2(190, 190, 130, 140)),
		_space("bellhouse", "Bellhouse", "decision", Rect2(350, 160, 120, 180)),
		_space("lighthouse_council", "Lighthouse Council", "council", Rect2(500, 100, 140, 160)),
		_space("high_water_channel", "High-Water Channel", "tide", Rect2(500, 310, 140, 150)),
		_space("last_light_beacon", "Last Light Beacon", "ending", Rect2(700, 170, 170, 200)),
	]
	spaces[0].initial_features = ["developer_gate_entry"]
	spaces[1].initial_features = ["low_tide_geography"]
	spaces[2].initial_features = ["public_ledger"]
	spaces[3].initial_features = ["public_council_table"]
	spaces[5].initial_features = ["unlit_last_light"]
	connectors = [
		_connector("gate_to_market", "harbor_gate", "low_tide_market"),
		_connector("market_to_bellhouse", "low_tide_market", "bellhouse"),
		_connector("bellhouse_to_council", "bellhouse", "lighthouse_council"),
		_connector("council_to_channel", "lighthouse_council", "high_water_channel"),
		_connector("channel_to_beacon", "high_water_channel", "last_light_beacon"),
	]


static func _space(
	space_id: String, display_name: String, space_type: String, area: Rect2
) -> Dictionary:
	return {
		"id": space_id,
		"name": display_name,
		"type": space_type,
		"tags": ["developer_only", "placeholder_geometry"],
		"areas": [area],
		"label_position": area.get_center(),
		"spawn_locations": [area.get_center()],
		"initial_revealed": true,
		"initial_hazards": [],
		"initial_features": [],
		"initial_blockers": [],
	}


static func _connector(connector_id: String, from_space: String, to_space: String) -> Dictionary:
	return {
		"id": connector_id,
		"from": from_space,
		"to": to_space,
		"type": "open_passage",
		"initial_state": "open",
		"one_way": false,
	}
