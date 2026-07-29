class_name DrownedHarborControlledPrivateSurface
extends RefCounted

enum Phase {
	EMPTY,
	REVEALED,
	ACKNOWLEDGEMENT_PENDING,
}

const ACKNOWLEDGEMENT_FIELDS: PackedStringArray = [
	"controller_authority_id",
	"current_counter",
	"handoff_id",
	"handoff_revision",
	"source_revision",
	"stable_seat_id",
	"trace_id",
]
const BARGAIN_FOCUS_ORDER: PackedStringArray = [
	"private_surface_identity",
	"benefit",
	"cost",
	"affected_seat_state",
	"confirm_private_bargain",
	"refuse_private_bargain",
]
const INHERITED_FOCUS_ORDER: PackedStringArray = [
	"assigned_seat_identity",
	"role_and_faction",
	"objective_and_conditions",
	"inventory_and_knowledge",
	"surrogate_recap",
	"legal_actions",
	"acknowledge_private_state",
]

var _available: bool = true
var _binding: Dictionary = {}
var _private_payload: Dictionary = {}
var _private_event: Dictionary = {}
var _focus_order: PackedStringArray = []
var _focus_index: int = 0
var _phase: int = Phase.EMPTY
var _pending_acknowledgement: Dictionary = {}
var _private_caption_request: String = ""
var _private_audio_requests: Array[String] = []


func set_available(available: bool) -> void:
	_available = available
	if not available:
		clear_private_state()


func open_handoff(projection: Dictionary, request: Dictionary) -> Dictionary:
	if not _available:
		return _rejected("private_surface_unavailable")
	if not is_cleared():
		return _rejected("uncleared_private_payload")
	if not projection.get("accepted", false):
		return _rejected("malformed_handoff")
	var fixture_id: String = str(projection.get("fixture_id", ""))
	if fixture_id == "DH-FIX-003":
		_focus_order = BARGAIN_FOCUS_ORDER.duplicate()
	elif fixture_id == "DH-FIX-007":
		_focus_order = INHERITED_FOCUS_ORDER.duplicate()
	else:
		return _rejected("unknown_handoff")
	_private_payload = projection.get("private_payload", {}).duplicate(true)
	_private_event = projection.get("private_event", {}).duplicate(true)
	if _private_payload.is_empty() or _private_event.is_empty():
		clear_private_state()
		return _rejected("malformed_handoff")
	_binding = {
		"controller_authority_id": request.get("controller_authority_id", ""),
		"handoff_id": request.get("handoff_id", ""),
		"handoff_revision": request.get("handoff_revision", -1),
		"source_revision": request.get("source_revision", -1),
		"stable_seat_id": request.get("stable_seat_id", ""),
		"trace_id": request.get("trace_id", ""),
		"valid_until_counter": projection.get("valid_until_counter", -1),
	}
	_focus_index = 0
	_phase = Phase.REVEALED
	_private_caption_request = "private_surface_only"
	_private_audio_requests = []
	return {
		"accepted": true,
		"focus": focused_item(),
		"phase": phase_name(),
	}


func navigate(delta: int) -> Dictionary:
	if _phase != Phase.REVEALED:
		return _rejected("private_handoff_not_active")
	_focus_index = clampi(_focus_index + delta, 0, _focus_order.size() - 1)
	return {"accepted": true, "focus": focused_item(), "phase": phase_name()}


func request_acknowledgement() -> Dictionary:
	if _phase != Phase.REVEALED:
		return _rejected("private_handoff_not_active")
	if focused_item() not in ["confirm_private_bargain", "acknowledge_private_state"]:
		return _rejected("acknowledgement_focus_required")
	_pending_acknowledgement = _binding.duplicate(true)
	_phase = Phase.ACKNOWLEDGEMENT_PENDING
	return {"accepted": true, "phase": phase_name()}


func refuse_private_bargain() -> Dictionary:
	if _phase != Phase.REVEALED:
		return _rejected("private_handoff_not_active")
	if focused_item() != "refuse_private_bargain":
		return _rejected("refusal_focus_required")
	clear_private_state()
	return {"accepted": true, "refused": true}


func acknowledge(request: Dictionary) -> Dictionary:
	if _phase != Phase.ACKNOWLEDGEMENT_PENDING:
		return _rejected("private_handoff_not_active")
	var request_validation: Dictionary = _validate_acknowledgement_request(request)
	if not request_validation.get("accepted", false):
		return request_validation
	var event_key: String = str(_private_event.get("event_key", ""))
	var private_event_committed: bool = (
		_private_event.get("classification") == "private"
		and _private_event.get("exactly_once") == true
		and not event_key.is_empty()
	)
	if not private_event_committed:
		return _rejected("malformed_handoff")
	var sanitized: Dictionary = {
		"accepted": true,
		"private_event_validated": true,
		"private_event_key": event_key,
	}
	return sanitized


func complete_acknowledgement() -> Dictionary:
	if _phase != Phase.ACKNOWLEDGEMENT_PENDING:
		return _rejected("private_handoff_not_active")
	clear_private_state()
	return {"accepted": true, "cleared": true}


func _validate_acknowledgement_request(request: Dictionary) -> Dictionary:
	if not _has_exact_keys(request, ACKNOWLEDGEMENT_FIELDS):
		return _rejected("malformed_handoff")
	for key: String in [
		"controller_authority_id",
		"handoff_id",
		"handoff_revision",
		"source_revision",
		"stable_seat_id",
		"trace_id",
	]:
		if request.get(key) != _pending_acknowledgement.get(key):
			return _rejected(_binding_error_for(key))
	if int(request.get("current_counter", -1)) < 0:
		return _rejected("malformed_handoff")
	if int(request.get("current_counter", -1)) > int(_binding.get("valid_until_counter", -1)):
		return _rejected("expired_handoff")
	return {"accepted": true}


func cancel() -> Dictionary:
	clear_private_state()
	return {"accepted": true, "cancelled": true}


func disconnect_surface() -> Dictionary:
	clear_private_state()
	return {"accepted": true, "cleared": true}


func clear_private_state() -> void:
	_private_payload.clear()
	_private_event.clear()
	_binding.clear()
	_pending_acknowledgement.clear()
	_focus_order = []
	_focus_index = 0
	_private_caption_request = ""
	_private_audio_requests.clear()
	_phase = Phase.EMPTY


func private_snapshot() -> Dictionary:
	if _phase == Phase.EMPTY:
		return {}
	return {
		"caption_request": _private_caption_request,
		"focus": focused_item(),
		"focus_order": Array(_focus_order),
		"payload": _private_payload.duplicate(true),
		"phase": phase_name(),
		"shared_audio_requests": _private_audio_requests.duplicate(),
	}


func clearing_snapshot() -> Dictionary:
	return {
		"binding_empty": _binding.is_empty(),
		"caption_request_empty": _private_caption_request.is_empty(),
		"focus_empty": _focus_order.is_empty(),
		"payload_empty": _private_payload.is_empty(),
		"pending_acknowledgement_empty": _pending_acknowledgement.is_empty(),
		"private_audio_requests_empty": _private_audio_requests.is_empty(),
		"private_event_empty": _private_event.is_empty(),
	}


func is_cleared() -> bool:
	var snapshot: Dictionary = clearing_snapshot()
	for value: Variant in snapshot.values():
		if value != true:
			return false
	return _phase == Phase.EMPTY


func focused_item() -> String:
	if _focus_order.is_empty():
		return ""
	return _focus_order[_focus_index]


func phase_name() -> String:
	return str(Phase.keys()[_phase]).to_lower()


static func _binding_error_for(key: String) -> String:
	match key:
		"stable_seat_id":
			return "wrong_stable_seat"
		"controller_authority_id":
			return "wrong_controller_authority"
		"source_revision":
			return "stale_source_revision"
		"handoff_revision":
			return "stale_handoff_revision"
		"handoff_id", "trace_id":
			return "unknown_handoff"
	return "malformed_handoff"


static func _has_exact_keys(value: Dictionary, expected: PackedStringArray) -> bool:
	var actual: PackedStringArray = []
	for key: Variant in value.keys():
		actual.append(str(key))
	actual.sort()
	var wanted: PackedStringArray = expected.duplicate()
	wanted.sort()
	return actual == wanted


static func _rejected(code: String) -> Dictionary:
	return {
		"accepted": false,
		"code": code,
		"reason": code,
	}
