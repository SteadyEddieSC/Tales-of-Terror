extends GutTest


func test_gut_runs_on_pinned_godot_patch() -> void:
	var version: Dictionary = Engine.get_version_info()
	assert_eq(version.get("major", 0), 4, "Godot major version")
	assert_eq(version.get("minor", 0), 7, "Godot minor version")
	assert_eq(version.get("patch", 0), 1, "Godot maintenance version")
	assert_true(Engine.is_editor_hint() == false, "GUT CLI executes the runtime test boundary")
