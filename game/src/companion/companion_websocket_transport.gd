class_name CompanionWebSocketTransport
extends RefCounted

signal connected
signal disconnected(code: int, reason: String)
signal envelope_received(envelope: Dictionary)
signal transport_error(code: String)

const MAX_INBOX: int = 32

var _peer := WebSocketPeer.new()
var _authentication: Dictionary = {}
var _sent_authentication: bool = false
var _inbox: Array[Dictionary] = []


func connect_to_room(url: String, authentication: Dictionary) -> Dictionary:
	if not _valid_url(url) or not CompanionProtocol.is_bounded_json(authentication):
		return {"accepted": false, "code": "malformed"}
	_authentication = authentication.duplicate(true)
	_sent_authentication = false
	var error: Error = _peer.connect_to_url(url)
	return {"accepted": error == OK, "code": "accepted" if error == OK else "transport_unavailable"}


func poll() -> void:
	_peer.poll()
	var state: WebSocketPeer.State = _peer.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN and not _sent_authentication:
		_peer.send_text(JSON.stringify(_authentication))
		_authentication.clear()
		_sent_authentication = true
		connected.emit()
	while state == WebSocketPeer.STATE_OPEN and _peer.get_available_packet_count() > 0:
		var raw: String = _peer.get_packet().get_string_from_utf8()
		var parsed: Dictionary = CompanionWireCodec.parse_wire_envelope(raw)
		if not parsed.accepted:
			transport_error.emit(parsed.code)
			continue
		_inbox.append(parsed.envelope.duplicate(true))
		while _inbox.size() > MAX_INBOX:
			_inbox.pop_front()
		envelope_received.emit(parsed.envelope.duplicate(true))
	if state == WebSocketPeer.STATE_CLOSED and _sent_authentication:
		var code: int = _peer.get_close_code()
		var reason: String = _peer.get_close_reason().left(64)
		_sent_authentication = false
		disconnected.emit(code, reason)


func send_envelope(envelope: Dictionary) -> Dictionary:
	var serialized: Dictionary = CompanionWireCodec.stringify_wire_envelope(envelope)
	if not serialized.accepted:
		return serialized
	if _peer.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return {"accepted": false, "code": "transport_unavailable"}
	var error: Error = _peer.send_text(serialized.raw)
	return {"accepted": error == OK, "code": "accepted" if error == OK else "transport_unavailable"}


func close() -> void:
	_authentication.clear()
	_peer.close(1000, "client_leave")


func sanitized_diagnostics() -> Dictionary:
	return {
		"transport": "websocket",
		"state": _peer.get_ready_state(),
		"inbox_depth": _inbox.size(),
		"authentication_buffered": not _authentication.is_empty(),
		"privacy": "AUTHENTICATION VALUES HIDDEN",
	}


func _valid_url(url: String) -> bool:
	if url.begins_with("wss://"):
		return true
	if not url.begins_with("ws://"):
		return false
	return url.begins_with("ws://127.0.0.1") or url.begins_with("ws://localhost")
