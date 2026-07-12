extends Control

const FOUNDATION_VERSION: String = "v0.0.1"

func _ready() -> void:
	print(
		ProjectSettings.get_setting("application/config/name"),
		" foundation loaded: ",
		FOUNDATION_VERSION
	)
