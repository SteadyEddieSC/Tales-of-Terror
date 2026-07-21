class_name PlaytestMemoryWriter
extends PlaytestReportWriter

var fail_writes: bool = false
var basename: String = ""
var json_text: String = ""
var markdown_text: String = ""


func write_report(p_basename: String, p_json_text: String, p_markdown_text: String) -> Dictionary:
	if fail_writes:
		return {"accepted": false, "reason": "fixture_write_failed"}
	basename = p_basename
	json_text = p_json_text
	markdown_text = p_markdown_text
	return {
		"accepted": true,
		"reason": "",
		"json_path": "memory://%s.json" % basename,
		"markdown_path": "memory://%s.md" % basename,
		"json_sha256": json_text.sha256_text(),
		"markdown_sha256": markdown_text.sha256_text(),
	}
