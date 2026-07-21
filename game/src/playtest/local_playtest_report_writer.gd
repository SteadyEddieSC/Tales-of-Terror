class_name LocalPlaytestReportWriter
extends PlaytestReportWriter

const EXPORT_FOLDER: String = "user://playtest_exports"


func write_report(basename: String, json_text: String, markdown_text: String) -> Dictionary:
	if not _valid_basename(basename) or json_text.is_empty() or markdown_text.is_empty():
		return {"accepted": false, "reason": "invalid_export_request"}
	var folder_error: Error = DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(EXPORT_FOLDER)
	)
	if folder_error != OK:
		return {"accepted": false, "reason": "export_folder_unavailable"}
	var json_path: String = "%s/%s.json" % [EXPORT_FOLDER, basename]
	var markdown_path: String = "%s/%s.md" % [EXPORT_FOLDER, basename]
	if FileAccess.file_exists(json_path) or FileAccess.file_exists(markdown_path):
		return {"accepted": false, "reason": "export_already_exists"}
	var json_result: Dictionary = _write_file(json_path, json_text)
	if not json_result.accepted:
		return json_result
	var markdown_result: Dictionary = _write_file(markdown_path, markdown_text)
	if not markdown_result.accepted:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(json_path))
		return markdown_result
	return {
		"accepted": true,
		"reason": "",
		"json_path": json_path,
		"markdown_path": markdown_path,
		"json_sha256": json_text.sha256_text(),
		"markdown_sha256": markdown_text.sha256_text(),
	}


func _write_file(path: String, content: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return {"accepted": false, "reason": "export_write_failed"}
	file.store_string(content)
	file.close()
	return {"accepted": true, "reason": ""}


func _valid_basename(value: String) -> bool:
	if value.is_empty() or value.length() > 80 or value.contains(".."):
		return false
	for character: String in value:
		if not character.to_lower() in "abcdefghijklmnopqrstuvwxyz0123456789_-":
			return false
	return true
