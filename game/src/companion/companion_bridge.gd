class_name CompanionBridge
extends RefCounted

signal outbound_envelope(client_id: String, envelope: Dictionary)
signal pending_claim_changed(payload: Dictionary)

const BRIDGE_VERSION: String = "0.0.9"
const HISTORY_LIMIT: int = 48
const ACK_CACHE_LIMIT: int = 32

var room_id: String = ""
var join_code: String = ""
var room_open: bool = false
var _seat_manager: SeatManager
var _board_state: BoardState
var _rules_session: RulesSession
var _director_runtime: DirectorRuntime
var _role_session: RoleSession
var _view_builder: CompanionViewBuilder
var _pending_clients: Dictionary = {}
var _claims: Dictionary = {}
var _connected_clients: Dictionary = {}
var _last_client_sequences: Dictionary = {}
var _ack_cache: Dictionary = {}
var _ack_order: Array[String] = []
var _sequence: int = 0
var _history: Array[Dictionary] = []
var _last_revision: int = 0
var _counters: Dictionary = {
	"duplicate": 0, "stale": 0, "malformed": 0, "unauthorized": 0,
	"wrong_seat": 0, "unsupported_version": 0, "unsupported_type": 0,
}

func _init(
	seat_manager: SeatManager = null,
	board_state: BoardState = null,
	rules_session: RulesSession = null,
	director_runtime: DirectorRuntime = null,
	role_session: RoleSession = null,
) -> void:
	if seat_manager != null:
		initialize(seat_manager, board_state, rules_session, director_runtime, role_session)

func initialize(
	seat_manager: SeatManager,
	board_state: BoardState,
	rules_session: RulesSession,
	director_runtime: DirectorRuntime,
	role_session: RoleSession,
) -> Dictionary:
	if seat_manager == null or board_state == null or rules_session == null or director_runtime == null or role_session == null:
		return {"accepted": false, "reason": "missing_authority"}
	_seat_manager = seat_manager
	_board_state = board_state
	_rules_session = rules_session
	_director_runtime = director_runtime
	_role_session = role_session
	_view_builder = CompanionViewBuilder.new(seat_manager, board_state, rules_session, director_runtime, role_session)
	_last_revision = authoritative_revision()
	return {"accepted": true}

func create_room(p_room_id: String, p_join_code: String) -> Dictionary:
	if room_open or CompanionProtocol.create_envelope(p_room_id, "room_created", "create_room").is_empty() or not _valid_join_code(p_join_code):
		return _reject("malformed", "room_created", "create_room")
	room_id = p_room_id
	join_code = p_join_code
	room_open = true
	var envelope: Dictionary = _envelope("room_created", "create_room", {"join_code": join_code, "bridge_version": BRIDGE_VERSION})
	_record("room_created", "create_room", "accepted", 0)
	return {"accepted": true, "envelope": envelope}

func close_room() -> Dictionary:
	if not room_open:
		return _reject("expired", "room_closed", "close_room")
	var envelope: Dictionary = _envelope("room_closed", "close_room", {"reason": "host_closed"}, 0, "accepted")
	for client_id: String in _connected_clients:
		outbound_envelope.emit(client_id, envelope.duplicate(true))
	room_open = false
	_pending_clients.clear()
	_claims.clear()
	_connected_clients.clear()
	_ack_cache.clear()
	_ack_order.clear()
	_record("room_closed", "close_room", "accepted", 0)
	return {"accepted": true, "envelope": envelope}

func expire_room() -> Dictionary:
	if not room_open:
		return _reject("expired", "room_expired", "expire_room")
	var envelope: Dictionary = _envelope("room_expired", "expire_room", {"reason": "host_missing_or_inactive"}, 0, "expired")
	for client_id: String in _connected_clients:
		outbound_envelope.emit(client_id, envelope.duplicate(true))
	room_open = false
	_pending_clients.clear()
	_claims.clear()
	_connected_clients.clear()
	_ack_cache.clear()
	_ack_order.clear()
	_record("room_expired", "expire_room", "expired", 0)
	return {"accepted": true, "envelope": envelope}

func request_join(client_id: String) -> Dictionary:
	if not room_open:
		return _reject("expired", "seat_claim_requested", client_id)
	if not _valid_client_id(client_id):
		return _reject("malformed", "seat_claim_requested", client_id)
	if _pending_clients.has(client_id) or _claims.has(client_id):
		return _reject("duplicate", "seat_claim_requested", client_id)
	if _pending_clients.size() + _claims.size() >= SeatManager.MAX_SEATS:
		return _reject("room_full", "seat_claim_requested", client_id)
	_pending_clients[client_id] = {"client_display": CompanionProtocol.request_display(client_id)}
	_connected_clients[client_id] = true
	var payload: Dictionary = {"client_display": CompanionProtocol.request_display(client_id), "pending_count": _pending_clients.size()}
	pending_claim_changed.emit(payload.duplicate(true))
	_record("seat_claim_requested", client_id, "accepted", 0)
	return {"accepted": true, "pending": payload}

func approve_claim(client_id: String, seat_number: int) -> Dictionary:
	if not can_approve_claim(client_id, seat_number):
		return _reject("unauthorized", "seat_claim_approved", client_id)
	for claimed_client: String in _claims:
		if claimed_client != client_id and _claims[claimed_client] == seat_number:
			return _reject("wrong_seat", "seat_claim_approved", client_id)
	_pending_clients.erase(client_id)
	_claims[client_id] = seat_number
	_connected_clients[client_id] = true
	var envelope: Dictionary = _envelope(
		"seat_claim_approved", "claim_%s" % CompanionProtocol.request_display(client_id),
		{"seat_identity": _view_builder.seat_identity(seat_number), "policy": "stable_seat_with_local_and_companion_input_surfaces"},
		seat_number, "accepted",
	)
	outbound_envelope.emit(client_id, envelope.duplicate(true))
	_emit_views(client_id)
	pending_claim_changed.emit({"pending_count": _pending_clients.size()})
	_record("seat_claim_approved", envelope.request_id, "accepted", seat_number)
	return {"accepted": true, "seat": seat_number, "envelope": envelope}

func can_approve_claim(client_id: String, seat_number: int) -> bool:
	if not _pending_clients.has(client_id) or not _rules_session.participating_seats.has(seat_number):
		return false
	for claimed_client: String in _claims:
		if claimed_client != client_id and _claims[claimed_client] == seat_number:
			return false
	return true

func deny_claim(client_id: String) -> Dictionary:
	if not _pending_clients.has(client_id):
		return _reject("unauthorized", "seat_claim_rejected", client_id)
	_pending_clients.erase(client_id)
	_connected_clients.erase(client_id)
	var envelope: Dictionary = _envelope("seat_claim_rejected", "deny_%s" % CompanionProtocol.request_display(client_id), {}, 0, "unauthorized")
	outbound_envelope.emit(client_id, envelope.duplicate(true))
	_record("seat_claim_rejected", envelope.request_id, "accepted", 0)
	return {"accepted": true, "envelope": envelope}

func revoke_claim(client_id: String) -> Dictionary:
	if not _claims.has(client_id):
		return _reject("unauthorized", "seat_claim_rejected", client_id)
	var seat_number: int = _claims[client_id]
	_claims.erase(client_id)
	_connected_clients.erase(client_id)
	var envelope: Dictionary = _envelope("seat_claim_rejected", "revoke_%s" % CompanionProtocol.request_display(client_id), {"revoked": true}, 0, "revoked")
	outbound_envelope.emit(client_id, envelope.duplicate(true))
	_record("seat_claim_rejected", envelope.request_id, "revoked", seat_number)
	return {"accepted": true, "envelope": envelope}

func disconnect_client(client_id: String) -> Dictionary:
	if not _connected_clients.has(client_id):
		return _reject("unauthorized", "client_left", client_id)
	_connected_clients[client_id] = false
	_record("client_left", client_id, "accepted", _claims.get(client_id, 0))
	return {"accepted": true, "seat": _claims.get(client_id, 0)}

func resume_client(client_id: String, seat_number: int) -> Dictionary:
	if not room_open:
		return _reject("expired", "reconnect_resume", client_id)
	if not _claims.has(client_id):
		return _reject("unauthorized", "reconnect_resume", client_id)
	if _claims[client_id] != seat_number:
		return _reject("wrong_seat", "reconnect_resume", client_id)
	_connected_clients[client_id] = true
	var envelope: Dictionary = _envelope("reconnect_resume", "resume_%s" % CompanionProtocol.request_display(client_id), {"restored": true}, seat_number, "accepted")
	outbound_envelope.emit(client_id, envelope.duplicate(true))
	_emit_views(client_id)
	_record("reconnect_resume", envelope.request_id, "accepted", seat_number)
	return {"accepted": true, "envelope": envelope}

func receive_client_envelope(client_id: String, value: Variant) -> Dictionary:
	var validation: Dictionary = CompanionProtocol.validate_envelope(value)
	if not validation.accepted:
		return _reject(validation.code, "rejection", "invalid")
	var envelope: Dictionary = validation.envelope
	var cache_key: String = "%s|%s" % [client_id, envelope.request_id]
	if _ack_cache.has(cache_key):
		_counters.duplicate += 1
		_record(envelope.message_type, envelope.request_id, "duplicate", _claims.get(client_id, 0))
		return {"accepted": true, "idempotent": true, "envelope": _ack_cache[cache_key].duplicate(true)}
	if not room_open:
		return _cache_rejection(cache_key, client_id, envelope, "expired")
	if envelope.room_id != room_id:
		return _cache_rejection(cache_key, client_id, envelope, "unauthorized")
	if not _claims.has(client_id) or not _connected_clients.get(client_id, false):
		return _cache_rejection(cache_key, client_id, envelope, "unauthorized")
	var authorized_seat: int = _claims[client_id]
	if envelope.seat_claim != authorized_seat:
		return _cache_rejection(cache_key, client_id, envelope, "wrong_seat")
	var last_sequence: int = _last_client_sequences.get(client_id, 0)
	if envelope.server_sequence > 0 and envelope.server_sequence <= last_sequence:
		return _cache_rejection(cache_key, client_id, envelope, "stale")
	if envelope.authoritative_revision != authoritative_revision():
		return _cache_rejection(cache_key, client_id, envelope, "stale")
	if not ["prompt_choice_submit", "role_action_submit", "private_reveal_ack"].has(envelope.message_type):
		return _cache_rejection(cache_key, client_id, envelope, "unsupported_type")
	if envelope.server_sequence > 0:
		_last_client_sequences[client_id] = envelope.server_sequence
	var before_revision: int = authoritative_revision()
	var result: Dictionary = _apply_intent(authorized_seat, envelope)
	if not result.get("accepted", false):
		var code: String = _authority_rejection_code(result.get("reason", ""))
		return _cache_rejection(cache_key, client_id, envelope, code)
	var after_revision: int = authoritative_revision()
	var acknowledgement: Dictionary = _envelope(
		"acknowledgement", envelope.request_id,
		{"resulting_revision": after_revision, "applied_once": true, "authority_result": "accepted"},
		authorized_seat, "accepted", after_revision,
	)
	_cache(cache_key, acknowledgement)
	outbound_envelope.emit(client_id, acknowledgement.duplicate(true))
	_emit_views(client_id)
	_last_revision = after_revision
	_record(envelope.message_type, envelope.request_id, "accepted", authorized_seat, before_revision, after_revision)
	return {"accepted": true, "envelope": acknowledgement, "before_revision": before_revision, "after_revision": after_revision}

func authoritative_revision() -> int:
	if _rules_session == null:
		return 0
	return _rules_session.authority_revision() + _board_state.revision + _role_session.revision + _director_runtime.revision

func public_view() -> Dictionary:
	return _view_builder.public_payload(room_id, "open" if room_open else "closed", connected_client_count())

func seat_view_for_client(client_id: String) -> Dictionary:
	if not _claims.has(client_id) or not _connected_clients.get(client_id, false):
		return {"accepted": false, "reason": "seat_not_authorized"}
	return _view_builder.seat_payload(room_id, _claims[client_id])

func seat_identity(seat_number: int) -> Dictionary:
	return _view_builder.seat_identity(seat_number)

func connected_client_count() -> int:
	var count: int = 0
	for connected: bool in _connected_clients.values():
		if connected:
			count += 1
	return count

func diagnostics() -> Dictionary:
	var claims: Array[Dictionary] = []
	for client_id: String in _claims:
		claims.append({
			"client_display": CompanionProtocol.request_display(client_id), "seat": _claims[client_id],
			"connected": _connected_clients.get(client_id, false),
		})
	claims.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.seat < b.seat)
	return {
		"protocol_version": CompanionProtocol.PROTOCOL_VERSION, "bridge_version": BRIDGE_VERSION,
		"room_state": "open" if room_open else "closed", "join_code": join_code,
		"connected_clients": connected_client_count(), "pending_clients": _pending_clients.size(),
		"seat_claims": claims, "sequence": _sequence, "queue_depth": 0,
		"last_authoritative_revision": authoritative_revision(), "counters": _counters.duplicate(true),
		"history": _history.duplicate(true), "privacy": "NO CAPABILITIES OR PRIVATE PAYLOADS",
	}

func _apply_intent(seat_number: int, envelope: Dictionary) -> Dictionary:
	match envelope.message_type:
		"prompt_choice_submit":
			if not _payload_has_exact_keys(envelope.payload, PackedStringArray(["option_ids", "prompt_revision"])):
				return {"accepted": false, "reason": "malformed_intent"}
			var option_values: Variant = envelope.payload.get("option_ids")
			if not option_values is Array or option_values.size() > 8:
				return {"accepted": false, "reason": "malformed_intent"}
			var option_ids: Array[String] = []
			for value: Variant in option_values:
				if not value is String:
					return {"accepted": false, "reason": "malformed_intent"}
				option_ids.append(value)
			var prompt_revision: Variant = envelope.payload.get("prompt_revision")
			if not prompt_revision is int:
				return {"accepted": false, "reason": "malformed_intent"}
			return _rules_session.submit_response(seat_number, option_ids, prompt_revision)
		"role_action_submit":
			if not _payload_has_exact_keys(envelope.payload, PackedStringArray(["action_id", "targets"])):
				return {"accepted": false, "reason": "malformed_intent"}
			var action_id: Variant = envelope.payload.get("action_id")
			var target_values: Variant = envelope.payload.get("targets", [])
			if not action_id is String or not target_values is Array or target_values.size() > SeatManager.MAX_SEATS:
				return {"accepted": false, "reason": "malformed_intent"}
			var targets: Array[int] = []
			for value: Variant in target_values:
				if not value is int:
					return {"accepted": false, "reason": "malformed_intent"}
				targets.append(value)
			return _role_session.perform_action(seat_number, action_id, targets, _rules_session, _board_state)
		"private_reveal_ack":
			if not envelope.payload.is_empty():
				return {"accepted": false, "reason": "malformed_intent"}
			return _role_session.acknowledge_private_role(seat_number)
	return {"accepted": false, "reason": "unsupported_intent"}

func _emit_views(client_id: String) -> void:
	if not _claims.has(client_id):
		return
	var seat_number: int = _claims[client_id]
	var public_envelope: Dictionary = _envelope("public_view_update", "public_%d" % _sequence, public_view(), 0, "", authoritative_revision())
	var private_payload: Dictionary = _view_builder.seat_payload(room_id, seat_number)
	var private_envelope: Dictionary = _envelope("seat_private_view_update", "private_%d" % _sequence, private_payload, seat_number, "", authoritative_revision())
	outbound_envelope.emit(client_id, public_envelope)
	outbound_envelope.emit(client_id, private_envelope)
	if not private_payload.get("faction_private", {}).is_empty():
		outbound_envelope.emit(client_id, _envelope("faction_private_view_update", "faction_%d" % _sequence, private_payload.faction_private, seat_number, "", authoritative_revision()))

func _cache_rejection(cache_key: String, client_id: String, request: Dictionary, code: String) -> Dictionary:
	var envelope: Dictionary = _envelope(
		"rejection", request.get("request_id", "rejected"),
		{"refresh_required": code == "stale", "current_revision": authoritative_revision()},
		_claims.get(client_id, 0), code, authoritative_revision(),
	)
	_cache(cache_key, envelope)
	outbound_envelope.emit(client_id, envelope.duplicate(true))
	return _reject(code, request.get("message_type", "rejection"), request.get("request_id", "rejected"), _claims.get(client_id, 0), true, envelope)

func _cache(cache_key: String, envelope: Dictionary) -> void:
	_ack_cache[cache_key] = envelope.duplicate(true)
	_ack_order.append(cache_key)
	while _ack_order.size() > ACK_CACHE_LIMIT:
		_ack_cache.erase(_ack_order.pop_front())

func _envelope(
	message_type: String,
	request_id: String,
	payload: Dictionary,
	seat_claim: int = 0,
	acknowledgement: String = "",
	revision: int = -1,
) -> Dictionary:
	_sequence += 1
	return CompanionProtocol.create_envelope(
		room_id, message_type, _safe_request_id(request_id), payload, _sequence,
		authoritative_revision() if revision < 0 else revision, seat_claim, acknowledgement,
	)

func _record(message_type: String, request_id: String, result: String, seat_number: int, before_revision: int = -1, after_revision: int = -1) -> void:
	_history.append({
		"message_type": message_type, "request_display": CompanionProtocol.request_display(request_id),
		"result": result, "seat": seat_number, "before_revision": before_revision,
		"after_revision": after_revision,
	})
	while _history.size() > HISTORY_LIMIT:
		_history.pop_front()

func _reject(
	code: String,
	message_type: String,
	request_id: String,
	seat_number: int = 0,
	count: bool = true,
	envelope: Dictionary = {},
) -> Dictionary:
	if count and _counters.has(code):
		_counters[code] += 1
	_record(message_type, request_id, code, seat_number)
	return {"accepted": false, "code": code, "envelope": envelope}

func _authority_rejection_code(reason: String) -> String:
	if "stale" in reason:
		return "stale"
	if "duplicate" in reason or "already" in reason:
		return "duplicate"
	if "unauthorized" in reason or "wrong_owner" in reason or "not_available" in reason or "disconnected" in reason:
		return "unauthorized"
	return "malformed"

func _valid_client_id(client_id: String) -> bool:
	return not CompanionProtocol.create_envelope("room", "client_joined", client_id).is_empty()

func _valid_join_code(value: String) -> bool:
	if value.length() < 4 or value.length() > 8:
		return false
	for character: String in value:
		if not character in "ABCDEFGHJKLMNPQRSTUVWXYZ23456789":
			return false
	return true

func _safe_request_id(value: String) -> String:
	var safe: String = ""
	for character: String in value.to_lower():
		safe += character if character in "abcdefghijklmnopqrstuvwxyz0123456789_-" else "_"
		if safe.length() >= CompanionProtocol.MAX_REQUEST_ID_LENGTH:
			break
	return safe if not safe.is_empty() else "request"

func _payload_has_exact_keys(payload: Dictionary, expected: PackedStringArray) -> bool:
	if payload.size() != expected.size():
		return false
	for key: Variant in payload:
		if not key is String or not expected.has(key):
			return false
	return true
