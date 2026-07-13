class_name InteractionCoordinator
extends Node

signal interaction_resolved(message: String)

var _interactables: Dictionary = {}
var _pending: Array[Dictionary] = []
var _resolution_handler: Callable

func set_resolution_handler(handler: Callable) -> void:
	_resolution_handler = handler

func register(interactable: SandboxInteractable) -> void:
	_interactables[interactable.interaction_id] = interactable

func update_focus(pawns: Array[PawnState]) -> void:
	var descriptors: Array[Dictionary] = []
	for interactable: SandboxInteractable in _interactables.values():
		interactable.set_focused(0)
		descriptors.append(interactable.descriptor())
	var focus_owners: Dictionary = {}
	for pawn: PawnState in pawns:
		if not pawn.connected:
			pawn.nearby_interactable = "—"
			continue
		var nearest: String = InteractionResolver.nearest_interactable(pawn.position, descriptors)
		pawn.nearby_interactable = nearest if not nearest.is_empty() else "—"
		if not nearest.is_empty() and (not focus_owners.has(nearest) or pawn.seat_number < focus_owners[nearest]):
			focus_owners[nearest] = pawn.seat_number
	for interactable_id: String in focus_owners:
		(_interactables[interactable_id] as SandboxInteractable).set_focused(focus_owners[interactable_id])

func request(pawn: PawnState) -> bool:
	if pawn == null or not pawn.connected or pawn.nearby_interactable == "—":
		return false
	_pending.append({"seat_number": pawn.seat_number, "interactable_id": pawn.nearby_interactable})
	return true

func resolve_pending() -> void:
	if _pending.is_empty():
		return
	for winner: Dictionary in InteractionResolver.resolve_requests(_pending):
		var interactable: SandboxInteractable = _interactables.get(winner.interactable_id) as SandboxInteractable
		if interactable != null:
			var message: String = ""
			if _resolution_handler.is_valid():
				message = _resolution_handler.call(winner.interactable_id, winner.seat_number)
			if message.is_empty():
				message = interactable.interact(winner.seat_number)
			interaction_resolved.emit(message)
	_pending.clear()

func get_interactable(interactable_id: String) -> SandboxInteractable:
	return _interactables.get(interactable_id) as SandboxInteractable
