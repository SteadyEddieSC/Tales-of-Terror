class_name CompanionProtocol
extends RefCounted

const PROTOCOL_VERSION: int = 1
const MAX_MESSAGE_BYTES: int = 8192
const MAX_STRING_LENGTH: int = 256
const MAX_REQUEST_ID_LENGTH: int = 64
const MAX_COLLECTION_ITEMS: int = 64
const MAX_NESTING_DEPTH: int = 8
const MESSAGE_TYPES: PackedStringArray = [
	"room_created", "room_closed", "client_joined", "client_left",
	"seat_claim_requested", "seat_claim_approved", "seat_claim_rejected",
	"reconnect_resume", "public_view_update", "seat_private_view_update",
	"faction_private_view_update", "prompt_choice_submit", "role_action_submit",
	"private_reveal_ack", "acknowledgement", "rejection", "host_heartbeat", "room_expired",
]
const REJECTION_CODES: PackedStringArray = [
	"stale", "duplicate", "unauthorized", "malformed", "rate_limited",
	"unsupported_version", "unsupported_type", "expired", "room_full",
	"wrong_seat", "revoked", "host_missing", "body_too_large",
]

static func parse_envelope(raw: String) -> Dictionary:
	if raw.to_utf8_buffer().size() > MAX_MESSAGE_BYTES:
		return {"accepted": false, "code": "body_too_large"}
	var parser := JSON.new()
	if parser.parse(raw) != OK:
		return {"accepted": false, "code": "malformed"}
	return validate_envelope(parser.data)

static func validate_envelope(value: Variant) -> Dictionary:
	if not value is Dictionary:
		return {"accepted": false, "code": "malformed"}
	var envelope: Dictionary = value
	if not envelope.has("protocol_version") or not envelope.protocol_version is int or envelope.protocol_version != PROTOCOL_VERSION:
		return {"accepted": false, "code": "unsupported_version"}
	if not envelope.get("message_type") is String or not MESSAGE_TYPES.has(envelope.message_type):
		return {"accepted": false, "code": "unsupported_type"}
	if not _valid_id(envelope.get("room_id"), 64) or not _valid_id(envelope.get("request_id"), MAX_REQUEST_ID_LENGTH):
		return {"accepted": false, "code": "malformed"}
	for field: String in ["server_sequence", "authoritative_revision"]:
		if not envelope.get(field) is int or envelope[field] < 0:
			return {"accepted": false, "code": "malformed"}
	if not envelope.get("seat_claim") is int or envelope.seat_claim < 0 or envelope.seat_claim > SeatManager.MAX_SEATS:
		return {"accepted": false, "code": "malformed"}
	if not envelope.get("payload") is Dictionary or not is_bounded_json(envelope.payload):
		return {"accepted": false, "code": "malformed"}
	var acknowledgement: Variant = envelope.get("acknowledgement")
	if not acknowledgement is String or (acknowledgement != "" and acknowledgement != "accepted" and not REJECTION_CODES.has(acknowledgement)):
		return {"accepted": false, "code": "malformed"}
	return {"accepted": true, "code": "accepted", "envelope": envelope.duplicate(true)}

static func is_bounded_json(value: Variant, depth: int = 0) -> bool:
	if depth > MAX_NESTING_DEPTH:
		return false
	if value == null or value is bool or value is int:
		return true
	if value is float:
		return is_finite(value)
	if value is String:
		return value.length() <= MAX_STRING_LENGTH
	if value is Array:
		if value.size() > MAX_COLLECTION_ITEMS:
			return false
		for item: Variant in value:
			if not is_bounded_json(item, depth + 1):
				return false
		return true
	if value is Dictionary:
		if value.size() > MAX_COLLECTION_ITEMS:
			return false
		for key: Variant in value:
			if not key is String or key.length() > MAX_STRING_LENGTH or not is_bounded_json(value[key], depth + 1):
				return false
		return true
	return false

static func create_envelope(
	room_id: String,
	message_type: String,
	request_id: String,
	payload: Dictionary = {},
	server_sequence: int = 0,
	authoritative_revision: int = 0,
	seat_claim: int = 0,
	acknowledgement: String = "",
) -> Dictionary:
	var envelope: Dictionary = {
		"protocol_version": PROTOCOL_VERSION, "room_id": room_id, "message_type": message_type,
		"server_sequence": server_sequence, "authoritative_revision": authoritative_revision,
		"request_id": request_id, "seat_claim": seat_claim, "payload": payload.duplicate(true),
		"acknowledgement": acknowledgement,
	}
	var validation: Dictionary = validate_envelope(envelope)
	return envelope if validation.accepted else {}

static func request_display(request_id: String) -> String:
	var safe: String = ""
	for character: String in request_id:
		if character.to_lower() in "abcdefghijklmnopqrstuvwxyz0123456789_-":
			safe += character
		else:
			safe += "_"
		if safe.length() >= 8:
			break
	return safe if not safe.is_empty() else "-"

static func _valid_id(value: Variant, maximum: int) -> bool:
	if not value is String or value.is_empty() or value.length() > maximum:
		return false
	for character: String in value:
		if not character in "abcdefghijklmnopqrstuvwxyz0123456789_-":
			return false
	return value[0] in "abcdefghijklmnopqrstuvwxyz0123456789"
