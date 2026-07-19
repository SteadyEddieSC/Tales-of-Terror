class_name CompanionFakeTransport
extends RefCounted

var bridge: CompanionBridge
var _inboxes: Dictionary = {}
var _client_sequences: Dictionary = {}

func _init(p_bridge: CompanionBridge = null) -> void:
	if p_bridge != null:
		setup(p_bridge)

func setup(p_bridge: CompanionBridge) -> void:
	bridge = p_bridge
	bridge.outbound_envelope.connect(_on_outbound_envelope)

func connect_client(client_id: String) -> Dictionary:
	if not _inboxes.has(client_id):
		_inboxes[client_id] = []
		_client_sequences[client_id] = 0
	return bridge.request_join(client_id)

func approve_client(client_id: String, seat_number: int) -> Dictionary:
	return bridge.approve_claim(client_id, seat_number)

func deny_client(client_id: String) -> Dictionary:
	return bridge.deny_claim(client_id)

func disconnect_client(client_id: String) -> Dictionary:
	return bridge.disconnect_client(client_id)

func resume_client(client_id: String, seat_number: int) -> Dictionary:
	return bridge.resume_client(client_id, seat_number)

func send_intent(
	client_id: String,
	message_type: String,
	request_id: String,
	payload: Dictionary,
	seat_claim: int,
	authoritative_revision: int = -1,
) -> Dictionary:
	_client_sequences[client_id] = _client_sequences.get(client_id, 0) + 1
	var envelope: Dictionary = CompanionProtocol.create_envelope(
		bridge.room_id, message_type, request_id, payload, _client_sequences[client_id],
		bridge.authoritative_revision() if authoritative_revision < 0 else authoritative_revision,
		seat_claim,
	)
	return bridge.receive_client_envelope(client_id, envelope)

func send_raw(client_id: String, raw: String) -> Dictionary:
	var parsed: Dictionary = CompanionProtocol.parse_envelope(raw)
	return bridge.receive_client_envelope(client_id, parsed.get("envelope", raw))

func drain(client_id: String) -> Array[Dictionary]:
	if not _inboxes.has(client_id):
		return []
	var messages: Array[Dictionary] = []
	for message: Dictionary in _inboxes[client_id]:
		messages.append(message.duplicate(true))
	_inboxes[client_id].clear()
	return messages

func _on_outbound_envelope(client_id: String, envelope: Dictionary) -> void:
	if not _inboxes.has(client_id):
		_inboxes[client_id] = []
	_inboxes[client_id].append(envelope.duplicate(true))
