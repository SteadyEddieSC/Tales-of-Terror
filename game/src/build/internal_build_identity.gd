class_name InternalBuildIdentity
extends RefCounted

const GENERATED_PATH: String = "res://build_identity.generated.json"
const SCHEMA_VERSION: int = 1
const EXACT_KEYS: PackedStringArray = [
	"schema_version", "release", "source_commit", "platform", "architecture", "classification"
]
const RELEASE: String = "v0.1.4"
const PROJECT_FOLDER: String = "Terror Turn"
const REPORT_LOCATION: String = "user://playtest_exports"
const WINDOWS_REPORT_LOCATION: String = (
	"%APPDATA%\\Godot\\app_userdata\\" + PROJECT_FOLDER + "\\playtest_exports"
)
const LINUX_REPORT_LOCATION: String = (
	"$XDG_DATA_HOME/godot/app_userdata/" + PROJECT_FOLDER + "/playtest_exports"
)
const LINUX_REPORT_FALLBACK: String = (
	"~/.local/share/godot/app_userdata/" + PROJECT_FOLDER + "/playtest_exports"
)


static func read_identity() -> Dictionary:
	var fallback: Dictionary = (
		_source_checkout_identity() if OS.has_feature("editor") else _invalid_export_identity()
	)
	if not FileAccess.file_exists(GENERATED_PATH):
		return fallback
	var file := FileAccess.open(GENERATED_PATH, FileAccess.READ)
	if file == null:
		return fallback
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if (
		parsed is not Dictionary
		or not validate_identity(parsed as Dictionary, false).get("accepted", false)
	):
		return fallback
	return (parsed as Dictionary).duplicate(true)


static func validate_identity(value: Dictionary, allow_source_checkout: bool = false) -> Dictionary:
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
	if value.classification == "internal_playtest":
		if value.release != RELEASE:
			return {"accepted": false, "reason": "invalid_build_identity_release"}
		if not _exact_source_commit(value.source_commit):
			return {"accepted": false, "reason": "invalid_build_identity_source"}
		if value.platform not in ["windows", "linux"]:
			return {"accepted": false, "reason": "invalid_build_identity_platform"}
		if value.architecture != "x86_64":
			return {"accepted": false, "reason": "invalid_build_identity_architecture"}
		return {"accepted": true, "reason": ""}
	if value.classification == "source_checkout" and allow_source_checkout:
		if (
			value.release == RELEASE
			and value.source_commit == "source-checkout"
			and _bounded(value.platform, 24)
			and value.architecture == "development"
		):
			return {"accepted": true, "reason": ""}
		return {"accepted": false, "reason": "invalid_source_checkout_identity"}
	if value.classification == "source_checkout":
		return {"accepted": false, "reason": "source_checkout_not_export_identity"}
	return {"accepted": false, "reason": "invalid_build_identity_classification"}


static func support_text(identity_override: Dictionary = {}) -> String:
	var identity: Dictionary = (
		read_identity() if identity_override.is_empty() else identity_override.duplicate(true)
	)
	var platform: String = str(identity.get("platform", OS.get_name().to_lower()))
	var classification: String = str(identity.get("classification", "invalid_export_identity"))
	return (
		(
			"RELEASE   %s\nBUILD ID   %s\nTARGET   %s / %s\n"
			+ "CLASSIFICATION   %s (%s)\n"
			+ "PROJECT FOLDER   %s (provisional working title)\n"
			+ "SCENARIO   lantern_house_vertical_slice v1\nREPORT SCHEMA   v%d\n\n"
			+ "%s\nRESET   Hold Y / R 1.5s to return to title.\n"
			+ "SUPPORT   Include release, build ID, target, classification, and the visible error. "
			+ "Never include report contents, room secrets, or player/device identities."
		)
		% [
			identity.get("release", RELEASE),
			_short_source(str(identity.get("source_commit", "unavailable"))),
			platform,
			identity.get("architecture", "unknown"),
			_classification_label(classification),
			classification,
			PROJECT_FOLDER,
			PlaytestReport.SCHEMA_VERSION,
			report_location_text(platform),
		]
	)


static func report_location_text(platform: String) -> String:
	match platform:
		"windows":
			return "REPORTS   %s" % WINDOWS_REPORT_LOCATION
		"linux":
			return (
				"REPORTS   %s\nDEFAULT   %s (when XDG_DATA_HOME is unset)"
				% [LINUX_REPORT_LOCATION, LINUX_REPORT_FALLBACK]
			)
		_:
			return "REPORTS   %s (source checkout)" % REPORT_LOCATION


static func _short_source(value: String) -> String:
	return value.substr(0, mini(value.length(), 12))


static func _classification_label(value: String) -> String:
	match value:
		"internal_playtest":
			return "INTERNAL PLAYTEST"
		"source_checkout":
			return "SOURCE CHECKOUT"
		_:
			return "INVALID EXPORTED IDENTITY"


static func _source_checkout_identity() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"release": RELEASE,
		"source_commit": "source-checkout",
		"platform": OS.get_name().to_lower(),
		"architecture": "development",
		"classification": "source_checkout",
	}


static func _invalid_export_identity() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"release": RELEASE,
		"source_commit": "unavailable",
		"platform": OS.get_name().to_lower(),
		"architecture": "unknown",
		"classification": "invalid_export_identity",
	}


static func _exact_source_commit(value: Variant) -> bool:
	if value is not String or (value as String).length() != 40:
		return false
	var source: String = value
	for character: String in source:
		if character not in "0123456789abcdef":
			return false
	return true


static func _bounded(value: Variant, limit: int) -> bool:
	return (
		value is String and not (value as String).is_empty() and (value as String).length() <= limit
	)
