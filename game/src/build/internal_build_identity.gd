class_name InternalBuildIdentity
extends RefCounted

const GENERATED_PATH: String = "res://build_identity.generated.json"
const SCHEMA_VERSION: int = 1
const EXACT_KEYS: PackedStringArray = [
	"schema_version", "release", "source_commit", "platform", "architecture", "classification"
]
const REPORT_LOCATION: String = "Godot user-data playtest_exports folder"


static func read_identity() -> Dictionary:
	var fallback: Dictionary = {
		"schema_version": SCHEMA_VERSION,
		"release": str(ProjectSettings.get_setting("application/config/version", "v0.1.2")),
		"source_commit": "source-checkout",
		"platform": OS.get_name().to_lower(),
		"architecture": "development",
		"classification": "source_checkout",
	}
	if not FileAccess.file_exists(GENERATED_PATH):
		return fallback
	var file := FileAccess.open(GENERATED_PATH, FileAccess.READ)
	if file == null:
		return fallback
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is not Dictionary or not validate_identity(parsed).get("accepted", false):
		return fallback
	return (parsed as Dictionary).duplicate(true)


static func validate_identity(value: Dictionary) -> Dictionary:
	var keys := PackedStringArray()
	for key: Variant in value.keys():
		keys.append(str(key))
	keys.sort()
	var expected := EXACT_KEYS.duplicate()
	expected.sort()
	if keys != expected:
		return {"accepted": false, "reason": "invalid_build_identity_keys"}
	if value.schema_version != SCHEMA_VERSION:
		return {"accepted": false, "reason": "invalid_build_identity_schema"}
	if not _bounded(value.release, 24) or not _bounded(value.source_commit, 64):
		return {"accepted": false, "reason": "invalid_build_identity_value"}
	if not _bounded(value.platform, 24) or not _bounded(value.architecture, 24):
		return {"accepted": false, "reason": "invalid_build_identity_target"}
	if value.classification not in ["internal_playtest", "source_checkout"]:
		return {"accepted": false, "reason": "invalid_build_identity_classification"}
	return {"accepted": true, "reason": ""}


static func support_text() -> String:
	var identity: Dictionary = read_identity()
	return (
		(
			"RELEASE   %s\nBUILD   %s  •  %s / %s\n"
			+ "SCENARIO   lantern_house_vertical_slice v1\nREPORT SCHEMA   v%d\n\n"
			+ "REPORTS   %s\nRESET   Hold Y / R 1.5s to return to title.\n\n"
			+ "When reporting a launch/runtime problem, include release, build, platform, "
			+ "and the visible error. Never include report contents, room secrets, or identities."
		)
		% [
			identity.release,
			_short_source(identity.source_commit),
			identity.platform,
			identity.architecture,
			PlaytestReport.SCHEMA_VERSION,
			REPORT_LOCATION,
		]
	)


static func _short_source(value: String) -> String:
	return value.substr(0, mini(value.length(), 12))


static func _bounded(value: Variant, limit: int) -> bool:
	return (
		value is String and not (value as String).is_empty() and (value as String).length() <= limit
	)
