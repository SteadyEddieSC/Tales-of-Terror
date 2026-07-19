class_name CompanionRoomServiceHost
extends Node

signal room_ready(room_id: String, join_code: String)
signal pending_client_discovered(client_id: String, client_display: String)
signal claim_completed(client_id: String, seat_number: int, accepted: bool, code: String)
signal client_resumed(client_id: String, seat_number: int)
signal authoritative_intent_completed(client_id: String, request_id: String, accepted: bool, code: String)
signal outbound_delivery_completed(client_id: String, request_id: String, message_type: String, accepted: bool, code: String)
signal room_closed
signal service_state_changed(state: String)

const MAX_REQUEST_QUEUE: int = 64
const HEARTBEAT_INTERVAL_SECONDS: float = 5.0
const DRAIN_INTERVAL_SECONDS: float = 0.1

var bridge: CompanionBridge
var service_base_url: String = ""
var room_id: String = ""
var join_code: String = ""

var _http: HTTPRequest
var _host_capability: String = ""
var _request_queue: Array[Dictionary] = []
var _active_request: Dictionary = {}
var _client_seats: Dictionary = {}
var _pending_clients: Dictionary = {}
var _heartbeat_elapsed: float = 0.0
var _drain_elapsed: float = 0.0
var _heartbeat_queued: bool = false
var _drain_queued: bool = false
var _room_active: bool = false
var _service_state: String = "disabled"

func _ready() -> void:
	_http = HTTPRequest.new()
	_http.use_threads = true
	_http.timeout = 5.0
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)
	set_process(true)

func initialize(p_service_base_url: String, p_bridge: CompanionBridge) -> Dictionary:
	if p_bridge == null or not _valid_service_url(p_service_base_url):
		return {"accepted": false, "code": "malformed"}
	bridge = p_bridge
	service_base_url = p_service_base_url.trim_suffix("/")
	if not bridge.outbound_envelope.is_connected(_on_bridge_outbound_envelope):
		bridge.outbound_envelope.connect(_on_bridge_outbound_envelope)
	_set_service_state("ready")
	return {"accepted": true, "code": "accepted"}

func create_room() -> Dictionary:
	if bridge == null or _room_active or not is_instance_valid(_http):
		return {"accepted": false, "code": "transport_unavailable"}
	return _enqueue_request({"kind": "create", "path": "/v1/rooms", "body": {}})

func approve_client(client_id: String, seat_number: int) -> Dictionary:
	if not _room_active or not _pending_clients.has(client_id) or not bridge.can_approve_claim(client_id, seat_number):
		return {"accepted": false, "code": "unauthorized"}
	return _enqueue_host_operation("approve", {"clientId": client_id, "seatClaim": seat_number}, {
		"client_id": client_id, "seat_number": seat_number,
	})

func deny_client(client_id: String) -> Dictionary:
	if not _room_active or not _pending_clients.has(client_id):
		return {"accepted": false, "code": "unauthorized"}
	return _enqueue_host_operation("deny", {"clientId": client_id}, {"client_id": client_id})

func close_room() -> Dictionary:
	if not _room_active:
		return {"accepted": false, "code": "expired"}
	return _enqueue_host_operation("close", {}, {})

func sanitized_diagnostics() -> Dictionary:
	var claims: Array[Dictionary] = []
	for client_id: String in _client_seats:
		claims.append({
			"client_display": CompanionProtocol.request_display(client_id),
			"seat": _client_seats[client_id],
		})
	claims.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.seat < b.seat)
	return {
		"transport": "local_room_service_http", "service_state": _service_state,
		"room_active": _room_active, "room_id": room_id, "join_code": join_code,
		"pending_clients": _pending_clients.size(), "claims": claims,
		"request_queue_depth": _request_queue.size() + (0 if _active_request.is_empty() else 1),
		"privacy": "HOST AUTHORIZATION AND PAYLOAD VALUES HIDDEN",
	}

func _process(delta: float) -> void:
	if _room_active:
		_heartbeat_elapsed += delta
		_drain_elapsed += delta
		if _heartbeat_elapsed >= HEARTBEAT_INTERVAL_SECONDS and not _heartbeat_queued:
			_heartbeat_elapsed = 0.0
			_heartbeat_queued = true
			_enqueue_host_operation("heartbeat", {}, {})
		if _drain_elapsed >= DRAIN_INTERVAL_SECONDS and not _drain_queued:
			_drain_elapsed = 0.0
			_drain_queued = true
			_enqueue_host_operation("drain", {}, {})
	_start_next_request()

func _enqueue_host_operation(operation: String, fields: Dictionary, context: Dictionary) -> Dictionary:
	if not _room_active or _host_capability.is_empty():
		return {"accepted": false, "code": "transport_unavailable"}
	var body: Dictionary = {"joinCode": join_code, "operation": operation}
	body.merge(fields, true)
	var request: Dictionary = {
		"kind": operation, "path": "/v1/rooms/host", "body": body,
		"authorized": true, "context": context.duplicate(true),
	}
	return _enqueue_request(request)

func _enqueue_request(request: Dictionary) -> Dictionary:
	if _request_queue.size() >= MAX_REQUEST_QUEUE:
		return {"accepted": false, "code": "rate_limited"}
	_request_queue.append(request.duplicate(true))
	_start_next_request()
	return {"accepted": true, "code": "accepted"}

func _start_next_request() -> void:
	if not is_instance_valid(_http) or not _active_request.is_empty() or _request_queue.is_empty():
		return
	_active_request = _request_queue.pop_front()
	var headers := PackedStringArray(["Content-Type: application/json", "Accept: application/json"])
	if _active_request.get("authorized", false):
		headers.append("Authorization: Bearer %s" % _host_capability)
	var error: Error = _http.request(
		service_base_url + _active_request.path,
		headers,
		HTTPClient.METHOD_POST,
		JSON.stringify(_active_request.get("body", {})),
	)
	if error != OK:
		var failed: Dictionary = _active_request
		_active_request = {}
		_request_failed(failed, "transport_unavailable")

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var request: Dictionary = _active_request
	_active_request = {}
	if request.is_empty():
		return
	if request.kind == "heartbeat":
		_heartbeat_queued = false
	elif request.kind == "drain":
		_drain_queued = false
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		_request_failed(request, "transport_unavailable" if response_code == 0 else _safe_service_code(body))
		return
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if not parsed is Dictionary:
		_request_failed(request, "malformed")
		return
	var response: Dictionary = parsed
	_handle_response(request, response)
	_start_next_request()

func _handle_response(request: Dictionary, response: Dictionary) -> void:
	match request.kind:
		"create":
			if not response.get("accepted", false) or not response.get("roomId") is String or not response.get("joinCode") is String or not response.get("hostCapability") is String:
				_request_failed(request, "malformed")
				return
			var created: Dictionary = bridge.create_room(response.roomId, response.joinCode)
			if not created.accepted:
				_request_failed(request, created.get("code", "malformed"))
				return
			room_id = response.roomId
			join_code = response.joinCode
			_host_capability = response.hostCapability
			_room_active = true
			_set_service_state("connected")
			room_ready.emit(room_id, join_code)
		"drain":
			if not response.get("accepted", false) or not response.get("messages") is Array:
				_request_failed(request, "malformed")
				return
			for message: Variant in response.messages:
				_process_host_message(message)
		"approve":
			var client_id: String = request.context.get("client_id", "")
			var seat_number: int = request.context.get("seat_number", 0)
			if response.get("accepted", false):
				var approved: Dictionary = bridge.approve_claim(client_id, seat_number)
				if approved.accepted:
					_pending_clients.erase(client_id)
					_client_seats[client_id] = seat_number
					claim_completed.emit(client_id, seat_number, true, "accepted")
				else:
					_enqueue_host_operation("revoke", {"clientId": client_id}, {"client_id": client_id})
					claim_completed.emit(client_id, seat_number, false, approved.get("code", "unauthorized"))
			else:
				claim_completed.emit(client_id, seat_number, false, String(response.get("code", "unauthorized")))
		"deny":
			var client_id: String = request.context.get("client_id", "")
			if response.get("accepted", false):
				bridge.deny_claim(client_id)
				_pending_clients.erase(client_id)
			claim_completed.emit(client_id, 0, response.get("accepted", false), String(response.get("code", "unauthorized")))
		"close":
			if not response.get("accepted", false):
				_request_failed(request, String(response.get("code", "unauthorized")))
				return
			bridge.close_room()
			_clear_room_state()
			_set_service_state("closed")
			room_closed.emit()
		"relay":
			var accepted: bool = response.get("accepted", false)
			outbound_delivery_completed.emit(
				String(request.context.get("client_id", "")),
				String(request.context.get("request_id", "")),
				String(request.context.get("message_type", "")),
				accepted, String(response.get("code", "unauthorized")),
			)
			if not accepted:
				_request_failed(request, String(response.get("code", "unauthorized")))
		"heartbeat", "revoke":
			if not response.get("accepted", false):
				_request_failed(request, String(response.get("code", "unauthorized")))

func _process_host_message(value: Variant) -> void:
	var converted: Dictionary = CompanionWireCodec.from_wire_envelope(value)
	if not converted.accepted:
		_set_service_state("protocol_rejected")
		return
	var envelope: Dictionary = converted.envelope
	match envelope.message_type:
		"seat_claim_requested":
			var client_id: Variant = envelope.payload.get("client_id")
			if not client_id is String or not bridge.request_join(client_id).accepted:
				return
			_pending_clients[client_id] = true
			pending_client_discovered.emit(client_id, String(envelope.payload.get("client_display", CompanionProtocol.request_display(client_id))))
		"client_left":
			var client_id: Variant = envelope.payload.get("client_id")
			if client_id is String:
				bridge.disconnect_client(client_id)
		"reconnect_resume":
			var client_id: String = _client_for_seat(envelope.seat_claim)
			if not client_id.is_empty():
				var resumed: Dictionary = bridge.resume_client(client_id, envelope.seat_claim)
				if resumed.accepted:
					client_resumed.emit(client_id, envelope.seat_claim)
		"prompt_choice_submit", "role_action_submit", "private_reveal_ack":
			var client_id: String = _client_for_seat(envelope.seat_claim)
			if client_id.is_empty():
				return
			var result: Dictionary = bridge.receive_client_envelope(client_id, envelope)
			authoritative_intent_completed.emit(
				client_id, envelope.request_id, result.accepted,
				"accepted" if result.accepted else String(result.get("code", "malformed")),
			)

func _on_bridge_outbound_envelope(client_id: String, envelope: Dictionary) -> void:
	if not _room_active or not [
		"public_view_update", "seat_private_view_update", "faction_private_view_update",
		"acknowledgement", "rejection",
	].has(envelope.get("message_type", "")):
		return
	var serialized: Dictionary = CompanionWireCodec.stringify_wire_envelope(envelope)
	if not serialized.accepted:
		_set_service_state("protocol_rejected")
		return
	_enqueue_host_operation("relay", {
		"clientId": client_id, "envelope": serialized.raw,
	}, {
		"client_id": client_id, "request_id": envelope.get("request_id", ""),
		"message_type": envelope.get("message_type", ""),
	})

func _request_failed(request: Dictionary, code: String) -> void:
	if request.get("kind") == "heartbeat":
		_heartbeat_queued = false
	elif request.get("kind") == "drain":
		_drain_queued = false
	_set_service_state("unavailable" if code == "transport_unavailable" else "rejected_%s" % code)
	_start_next_request()

func _safe_service_code(body: PackedByteArray) -> String:
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if parsed is Dictionary and parsed.get("code") is String:
		var code: String = parsed.code
		if CompanionProtocol.REJECTION_CODES.has(code):
			return code
	return "transport_unavailable"

func _client_for_seat(seat_number: int) -> String:
	for client_id: String in _client_seats:
		if _client_seats[client_id] == seat_number:
			return client_id
	return ""

func _clear_room_state() -> void:
	_host_capability = ""
	room_id = ""
	join_code = ""
	_room_active = false
	_pending_clients.clear()
	_client_seats.clear()
	_request_queue.clear()
	_heartbeat_queued = false
	_drain_queued = false

func _set_service_state(value: String) -> void:
	if value == _service_state:
		return
	_service_state = value
	service_state_changed.emit(value)

func _valid_service_url(value: String) -> bool:
	if value.begins_with("https://"):
		return true
	return value.begins_with("http://127.0.0.1") or value.begins_with("http://localhost")
