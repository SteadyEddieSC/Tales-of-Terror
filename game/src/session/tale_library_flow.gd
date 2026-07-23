class_name TaleLibraryFlow
extends RefCounted

const ACTIONS: PackedStringArray = ["open", "focus", "return_to_mode", "return_from_briefing"]

var internal_rejection: String = ""
var selection_locked: bool = false


func select(coordinator: VerticalSliceCoordinator, tale_id: String) -> Dictionary:
	if (
		selection_locked
		or coordinator.lifecycle not in ["boot_title", "lobby", "confirmation", "tale_library"]
		or not coordinator.tale_package.is_empty()
	):
		return coordinator._reject("tale_selection_not_available")
	var selected: Dictionary = coordinator._selection.select(tale_id)
	if not selected.get("accepted", false):
		return reject(
			coordinator,
			selected.get("reason", "tale_selection_rejected"),
			"tale_selection_unavailable",
		)
	coordinator.last_rejection = ""
	clear_rejection()
	coordinator._emit_state()
	return {
		"accepted": true,
		"selected_tale_id": coordinator._selection.selected_tale_id(),
		"catalog_digest": coordinator._selection.catalog_digest,
	}


func navigate(
	coordinator: VerticalSliceCoordinator, action: String, value: Variant = null
) -> Dictionary:
	if not ACTIONS.has(action):
		return coordinator._reject("unsupported_tale_library_action")
	match action:
		"open":
			return _open(coordinator, str(value) if value != null else coordinator.DEFAULT_MODE)
		"focus":
			return _move_focus(coordinator, int(value))
		"return_to_mode":
			return _return_to_mode(coordinator)
		_:
			return _return_from_briefing(coordinator)


func initialize_session(
	coordinator: VerticalSliceCoordinator, session_seed: int, requested_mode: String
) -> Dictionary:
	var started_in_confirmation: bool = coordinator.lifecycle == "confirmation"
	if not started_in_confirmation and coordinator.lifecycle != "tale_library":
		return coordinator._reject("invalid_lifecycle_transition")
	var roster: Array[int] = coordinator.active_seats()
	if roster.is_empty():
		return coordinator._reject("empty_roster")
	var prepared: Dictionary
	if coordinator._selection.focused_tale_id == coordinator._selection.selected_tale_id():
		prepared = coordinator._selection.prepare_entry(coordinator._selection.entry)
	else:
		prepared = coordinator._selection.prepare(coordinator._selection.focused_tale_id)
	if not prepared.get("accepted", false):
		return reject(
			coordinator,
			prepared.get("reason", "no_valid_tale_selection"),
			"tale_selection_unavailable",
		)
	var build: Dictionary = coordinator._build_authorities(
		prepared.entry, session_seed, requested_mode, roster
	)
	if not build.get("accepted", false):
		return reject(coordinator, build.reason, "tale_preparation_unavailable")
	coordinator._selection.commit_prepared(prepared, true)
	coordinator._commit_authorities(build, session_seed, requested_mode)
	if started_in_confirmation:
		coordinator.lifecycle = "tale_library"
	return coordinator._transition("tale_library", "briefing")


func public_state(selection: TaleSelectionState, public_rejection: String) -> Dictionary:
	var entries: Array[Dictionary] = selection.library_entries()
	var catalog_count: int = selection.catalog.get("entries", []).size()
	var unavailable: bool = catalog_count == 0 or entries.size() != catalog_count
	return {
		"available_count": catalog_count if not unavailable else 0,
		"entries": entries if not unavailable else [],
		"focused_tale_id": selection.focused_tale_id if not unavailable else "",
		"selected_tale_id": selection.selected_tale_id() if not unavailable else "",
		"confirmed_tale_id": selection.confirmed_tale_id if not unavailable else "",
		"notice": "tale_library_unavailable" if unavailable else public_rejection,
	}


func reject(
	coordinator: VerticalSliceCoordinator, internal_reason: String, public_reason: String
) -> Dictionary:
	internal_rejection = internal_reason
	coordinator.last_rejection = public_reason
	coordinator.session_rejected.emit(internal_reason)
	coordinator._emit_state()
	return {"accepted": false, "reason": internal_reason, "public_reason": public_reason}


func clear_rejection() -> void:
	internal_rejection = ""


func lock_for_lifecycle(lifecycle: String) -> void:
	selection_locked = lifecycle in ["active_tale", "terminal", "ending"]


func record_unavailable(coordinator: VerticalSliceCoordinator, reason: String) -> void:
	coordinator.last_rejection = "tale_library_unavailable"
	internal_rejection = reason


func reject_internal(coordinator: VerticalSliceCoordinator, reason: String) -> Dictionary:
	coordinator.last_rejection = reason
	internal_rejection = reason
	coordinator.session_rejected.emit(reason)
	return {"accepted": false, "reason": reason}


func _open(coordinator: VerticalSliceCoordinator, requested_mode: String) -> Dictionary:
	if coordinator.lifecycle != "confirmation" or coordinator.active_seats().is_empty():
		return coordinator._reject("invalid_lifecycle_transition")
	coordinator.requested_mode = requested_mode
	return coordinator._transition("confirmation", "tale_library")


func _move_focus(coordinator: VerticalSliceCoordinator, direction: int) -> Dictionary:
	if coordinator.lifecycle != "tale_library" or selection_locked:
		return coordinator._reject("tale_focus_not_available")
	var focused: Dictionary = coordinator._selection.move_focus(direction)
	if not focused.get("accepted", false):
		return reject(
			coordinator,
			focused.get("reason", "tale_focus_rejected"),
			"tale_library_unavailable",
		)
	coordinator.last_rejection = ""
	clear_rejection()
	coordinator._emit_state()
	return focused


func _return_to_mode(coordinator: VerticalSliceCoordinator) -> Dictionary:
	if coordinator.lifecycle != "tale_library" or not coordinator.tale_package.is_empty():
		return coordinator._reject("invalid_lifecycle_transition")
	return coordinator._transition("tale_library", "confirmation")


func _return_from_briefing(coordinator: VerticalSliceCoordinator) -> Dictionary:
	if coordinator.lifecycle != "briefing" or selection_locked:
		return coordinator._reject("invalid_lifecycle_transition")
	coordinator._close_companion_room()
	coordinator._clear_session_authorities()
	coordinator.lifecycle = "tale_library"
	coordinator.last_rejection = ""
	clear_rejection()
	coordinator._emit_state()
	return {"accepted": true, "lifecycle": coordinator.lifecycle}
