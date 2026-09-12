class_name DemoNarrative
extends RefCounted
## Localizable presentation text. Call private role/objective helpers only on a shielded view.

const CATALOG_PATH := "res://assets/drowned_harbor_alpha4/narrative_en.json"
const ASSET_ROOT := "res://assets/drowned_harbor_alpha4/"

static var _catalog: Dictionary = {}


static func stage_text(stage_id: String, profile: String = "grim") -> Dictionary:
	return _entry("stages", stage_id, profile)


static func event_text(event_id: String, profile: String = "grim") -> Dictionary:
	return _entry("events", event_id, profile)


static func ending_text(ending_id: String, profile: String = "grim") -> Dictionary:
	return _entry("endings", ending_id, profile)


static func role_text(role_id: String) -> Dictionary:
	return _entry("roles", role_id, "grim")


static func objective_text(objective_id: String) -> Dictionary:
	return _entry("objectives", objective_id, "grim")


static func role_portrait_path(role_id: String) -> String:
	var row := role_text(role_id)
	return ASSET_ROOT + str(row.get("portrait", "witness_icon.svg"))


static func role_icon_path(role_id: String) -> String:
	var row := role_text(role_id)
	return ASSET_ROOT + str(row.get("icon", "witness_icon.svg"))


static func _entry(section: String, entry_id: String, profile: String) -> Dictionary:
	if _catalog.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
		if parsed is Dictionary:
			_catalog = parsed
	var aliases: Dictionary = _catalog.get("aliases", {}).get(section, {})
	var resolved_id := str(aliases.get(entry_id, entry_id))
	var row: Dictionary = _catalog.get(section, {}).get(resolved_id, {}).duplicate(true)
	if row.is_empty():
		return {}
	var variants: Dictionary = row.get("variants", {})
	row["text"] = str(variants.get(profile, row.get("text", "")))
	row["caption"] = str(row.get("caption", row.get("text", "")))
	row["speaker"] = str(row.get("speaker", "The Underteller"))
	row["objective"] = str(row.get("objective", ""))
	return row
