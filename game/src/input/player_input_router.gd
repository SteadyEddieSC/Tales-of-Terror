class_name PlayerInputRouter
extends Node

signal interact_requested(device_id: int)
signal diagnostics_requested(device_id: int)
signal rules_navigation_requested(device_id: int, direction: int, confirm: bool, cancel: bool)

const MOVEMENT_ACTIONS: PackedStringArray = ["move_left", "move_right", "move_up", "move_down"]
var _strengths: Dictionary = {}

func _input(event: InputEvent) -> void:
	var device_id: int = SeatManager.KEYBOARD_DEVICE_ID if event is InputEventKey else event.device
	for action: String in MOVEMENT_ACTIONS:
		if event.is_action(action):
			var device_state: Dictionary = _strengths.get_or_add(device_id, {})
			device_state[action] = event.get_action_strength(action) if event.is_pressed() else 0.0
	if event.is_action_pressed("interact"):
		interact_requested.emit(device_id)
	if event.is_action_pressed("diagnostic_test"):
		diagnostics_requested.emit(device_id)
	if event.is_action_pressed("ui_navigate_left"):
		rules_navigation_requested.emit(device_id, -1, false, false)
	elif event.is_action_pressed("ui_navigate_right"):
		rules_navigation_requested.emit(device_id, 1, false, false)
	elif event.is_action_pressed("ui_confirm"):
		rules_navigation_requested.emit(device_id, 0, true, false)
	elif event.is_action_pressed("ui_cancel_action"):
		rules_navigation_requested.emit(device_id, 0, false, true)

func get_movement_vector(device_id: int) -> Vector2:
	if not _strengths.has(device_id):
		return Vector2.ZERO
	var state: Dictionary = _strengths[device_id]
	return Vector2(
		float(state.get("move_right", 0.0)) - float(state.get("move_left", 0.0)),
		float(state.get("move_down", 0.0)) - float(state.get("move_up", 0.0))
	).limit_length(1.0)

func clear_device(device_id: int) -> void:
	_strengths.erase(device_id)
