class_name CompanionWireCodec
extends RefCounted

const WIRE_ENVELOPE_FIELDS: PackedStringArray = [
	"protocolVersion",
	"roomId",
	"messageType",
	"serverSequence",
	"authoritativeRevision",
	"requestId",
	"seatClaim",
	"payload",
	"acknowledgement",
]
const INTERNAL_ENVELOPE_FIELDS: PackedStringArray = [
	"protocol_version",
	"room_id",
	"message_type",
	"server_sequence",
	"authoritative_revision",
	"request_id",
	"seat_claim",
	"payload",
	"acknowledgement",
]

const WIRE_TO_INTERNAL_ENVELOPE: Dictionary = {
	"protocolVersion": "protocol_version",
	"roomId": "room_id",
	"messageType": "message_type",
	"serverSequence": "server_sequence",
	"authoritativeRevision": "authoritative_revision",
	"requestId": "request_id",
	"seatClaim": "seat_claim",
	"payload": "payload",
	"acknowledgement": "acknowledgement",
}
const INTERNAL_TO_WIRE_ENVELOPE: Dictionary = {
	"protocol_version": "protocolVersion",
	"room_id": "roomId",
	"message_type": "messageType",
	"server_sequence": "serverSequence",
	"authoritative_revision": "authoritativeRevision",
	"request_id": "requestId",
	"seat_claim": "seatClaim",
	"payload": "payload",
	"acknowledgement": "acknowledgement",
}

# Protocol-owned payload keys only. Authored rules, social, Director, and
# presentation dictionaries below explicit projection containers stay opaque.
const PAYLOAD_KEY_MAPS: Dictionary = {
	"room_created": {"join_code": "joinCode", "bridge_version": "bridgeVersion"},
	"client_joined": {"client_id": "clientId", "client_display": "clientDisplay"},
	"client_left": {"client_id": "clientId", "client_display": "clientDisplay"},
	"seat_claim_requested": {"client_id": "clientId", "client_display": "clientDisplay"},
	"seat_claim_approved":
	{"resume_capability": "resumeCapability", "seat_identity": "seatIdentity"},
	"public_view_update":
	{
		"view_version": "viewVersion",
		"view_kind": "viewKind",
		"room_id": "roomId",
		"room_status": "roomStatus",
		"connected_clients": "connectedClients",
	},
	"seat_private_view_update":
	{
		"view_version": "viewVersion",
		"view_kind": "viewKind",
		"room_id": "roomId",
		"authorized_seat": "authorizedSeat",
		"seat_identity": "seatIdentity",
		"rules_private": "rulesPrivate",
		"social_private": "socialPrivate",
		"legal_actions": "legalActions",
		"faction_private": "factionPrivate",
		"privacy_notice": "privacyNotice",
	},
	"faction_private_view_update":
	{
		"view_version": "viewVersion",
		"view_kind": "viewKind",
		"authorized_seat": "authorizedSeat",
		"faction_id": "factionId",
		"faction_label": "factionLabel",
	},
	"prompt_choice_submit": {"option_ids": "optionIds", "prompt_revision": "promptRevision"},
	"role_action_submit": {"action_id": "actionId"},
	"acknowledgement":
	{
		"relay_accepted": "relayAccepted",
		"resulting_revision": "resultingRevision",
		"applied_once": "appliedOnce",
		"authority_result": "authorityResult",
		"claim_approved": "claimApproved",
	},
	"rejection": {"refresh_required": "refreshRequired", "current_revision": "currentRevision"},
}

const EXACT_PAYLOAD_FIELDS: Dictionary = {
	"prompt_choice_submit": ["option_ids", "prompt_revision"],
	"role_action_submit": ["action_id", "targets"],
	"private_reveal_ack": [],
}
const BOUNDED_PAYLOAD_FIELDS: Dictionary = {
	"room_created": ["join_code", "bridge_version"],
	"room_closed": ["reason"],
	"client_joined": ["client_id", "client_display"],
	"client_left": ["client_id", "client_display"],
	"seat_claim_requested": ["client_id", "client_display"],
	"seat_claim_approved": ["seat", "resume_capability", "seat_identity", "policy"],
	"seat_claim_rejected": ["revoked"],
	"reconnect_resume": ["restored"],
	"acknowledgement":
	["relay_accepted", "resulting_revision", "applied_once", "authority_result", "claim_approved"],
	"rejection": ["refresh_required", "current_revision"],
	"host_heartbeat": ["alive"],
	"room_expired": ["reason"],
	"public_view_update":
	[
		"accepted",
		"view_version",
		"view_kind",
		"room_id",
		"room_status",
		"connected_clients",
		"seats",
		"rules",
		"board",
		"social",
		"director",
	],
	"seat_private_view_update":
	[
		"accepted",
		"view_version",
		"view_kind",
		"room_id",
		"authorized_seat",
		"seat_identity",
		"public",
		"rules_private",
		"social_private",
		"legal_actions",
		"faction_private",
		"privacy_notice",
	],
	"faction_private_view_update":
	[
		"accepted",
		"view_version",
		"view_kind",
		"authorized_seat",
		"faction_id",
		"faction_label",
		"members",
		"policy",
	],
}
const SEAT_IDENTITY_KEYS: Dictionary = {"color_name": "colorName", "color_hex": "colorHex"}
const BOARD_VIEW_KEYS: Dictionary = {"view_version": "viewVersion"}
const BOARD_SPACE_KEYS: Dictionary = {
	"hazard_count": "hazardCount", "feature_count": "featureCount"
}
const LEGAL_ACTION_KEYS: Dictionary = {"action_id": "actionId"}
const FACTION_MEMBER_KEYS: Dictionary = {"role_id": "roleId", "role_label": "roleLabel"}
const SEAT_IDENTITY_FIELDS: Array = [
	"seat", "numeral", "symbol", "pattern", "color_name", "color_hex", "connection"
]
const BOARD_VIEW_FIELDS: Array = ["view_version", "revision", "spaces"]
const BOARD_SPACE_FIELDS: Array = [
	"id", "label", "revealed", "occupants", "hazard_count", "feature_count"
]
const LEGAL_ACTION_FIELDS: Array = ["action_id", "label", "description", "symbol"]
const FACTION_MEMBER_FIELDS: Array = ["seat", "role_id", "role_label", "lifecycle"]


static func parse_wire_envelope(raw: String) -> Dictionary:
	if raw.to_utf8_buffer().size() > CompanionProtocol.MAX_MESSAGE_BYTES:
		return {"accepted": false, "code": "body_too_large"}
	var parser := JSON.new()
	if parser.parse(raw) != OK:
		return {"accepted": false, "code": "malformed"}
	return from_wire_envelope(parser.data)


static func from_wire_envelope(value: Variant) -> Dictionary:
	if not _has_exact_keys(value, WIRE_ENVELOPE_FIELDS):
		return {"accepted": false, "code": "malformed"}
	var wire: Dictionary = value
	var message_type: Variant = wire.get("messageType")
	if not message_type is String:
		return {"accepted": false, "code": "unsupported_type"}
	var payload_result: Dictionary = _convert_payload(message_type, wire.get("payload"), false)
	if not payload_result.accepted:
		return payload_result
	var internal: Dictionary = {}
	for wire_key: String in WIRE_ENVELOPE_FIELDS:
		var internal_key: String = WIRE_TO_INTERNAL_ENVELOPE[wire_key]
		if wire_key == "payload":
			internal[internal_key] = payload_result.payload
		elif (
			wire_key in ["protocolVersion", "serverSequence", "authoritativeRevision", "seatClaim"]
		):
			var integer_value: Variant = _wire_integer(wire[wire_key])
			if integer_value == null:
				return {"accepted": false, "code": "malformed"}
			internal[internal_key] = integer_value
		else:
			internal[internal_key] = wire[wire_key]
	return CompanionProtocol.validate_envelope(internal)


static func to_wire_envelope(value: Variant) -> Dictionary:
	var validation: Dictionary = CompanionProtocol.validate_envelope(value)
	if not validation.accepted:
		return validation
	var internal: Dictionary = validation.envelope
	var payload_result: Dictionary = _convert_payload(internal.message_type, internal.payload, true)
	if not payload_result.accepted:
		return payload_result
	var wire: Dictionary = {}
	for internal_key: String in INTERNAL_ENVELOPE_FIELDS:
		var wire_key: String = INTERNAL_TO_WIRE_ENVELOPE[internal_key]
		wire[wire_key] = (
			payload_result.payload if internal_key == "payload" else internal[internal_key]
		)
	return {"accepted": true, "code": "accepted", "envelope": wire}


static func stringify_wire_envelope(value: Variant) -> Dictionary:
	var converted: Dictionary = to_wire_envelope(value)
	if not converted.accepted:
		return converted
	var raw: String = JSON.stringify(converted.envelope)
	if raw.to_utf8_buffer().size() > CompanionProtocol.MAX_MESSAGE_BYTES:
		return {"accepted": false, "code": "body_too_large"}
	return {"accepted": true, "code": "accepted", "raw": raw}


static func _convert_payload(message_type: String, value: Variant, to_wire: bool) -> Dictionary:
	if not value is Dictionary or not CompanionProtocol.is_bounded_json(value):
		return {"accepted": false, "code": "malformed"}
	var source: Dictionary = value
	var key_map: Dictionary = PAYLOAD_KEY_MAPS.get(message_type, {})
	var reverse_map: Dictionary = {}
	for internal_key: String in key_map:
		reverse_map[key_map[internal_key]] = internal_key
	var result: Dictionary = {}
	for key: Variant in source:
		if not key is String:
			return {"accepted": false, "code": "malformed"}
		var output_key: String = key
		if to_wire and key_map.has(key):
			output_key = key_map[key]
		elif not to_wire and reverse_map.has(key):
			output_key = reverse_map[key]
		elif (to_wire and reverse_map.has(key)) or (not to_wire and key_map.has(key)):
			return {"accepted": false, "code": "malformed"}
		if result.has(output_key):
			return {"accepted": false, "code": "malformed"}
		result[output_key] = source[key]
	if EXACT_PAYLOAD_FIELDS.has(message_type):
		var expected: Array = EXACT_PAYLOAD_FIELDS[message_type]
		var internal_result: Dictionary = source if to_wire else result
		if not _dictionary_has_exact_keys(internal_result, expected):
			return {"accepted": false, "code": "malformed"}
	if BOUNDED_PAYLOAD_FIELDS.has(message_type):
		var allowed: Array = BOUNDED_PAYLOAD_FIELDS[message_type]
		var bounded_internal: Dictionary = source if to_wire else result
		for key: Variant in bounded_internal:
			if not key is String or not allowed.has(key):
				return {"accepted": false, "code": "malformed"}
	if not to_wire and message_type == "prompt_choice_submit":
		var prompt_revision: Variant = _wire_integer(result.get("prompt_revision"))
		if prompt_revision == null:
			return {"accepted": false, "code": "malformed"}
		result["prompt_revision"] = prompt_revision
	if not to_wire and message_type == "role_action_submit":
		var targets: Variant = result.get("targets")
		if not targets is Array:
			return {"accepted": false, "code": "malformed"}
		var normalized_targets: Array[int] = []
		for target: Variant in targets:
			var normalized: Variant = _wire_integer(target)
			if normalized == null:
				return {"accepted": false, "code": "malformed"}
				normalized_targets.append(normalized)
		result["targets"] = normalized_targets
	var nested_result: Dictionary = _convert_nested_payload(message_type, result, to_wire)
	if not nested_result.accepted:
		return nested_result
	result = nested_result.payload
	return {"accepted": true, "code": "accepted", "payload": result.duplicate(true)}


static func _convert_nested_payload(
	message_type: String, payload: Dictionary, to_wire: bool
) -> Dictionary:
	var result: Dictionary = payload.duplicate(true)
	if message_type == "seat_claim_approved":
		var claim_identity_key: String = "seatIdentity" if to_wire else "seat_identity"
		if result.get(claim_identity_key) is Dictionary:
			var converted_claim_identity: Dictionary = _convert_record(
				result[claim_identity_key], SEAT_IDENTITY_KEYS, SEAT_IDENTITY_FIELDS, to_wire
			)
			if not converted_claim_identity.accepted:
				return converted_claim_identity
			result[claim_identity_key] = converted_claim_identity.payload
	elif message_type == "public_view_update":
		var seats_key: String = "seats"
		if result.get(seats_key) is Array:
			var seats: Array[Dictionary] = []
			for seat: Variant in result[seats_key]:
				var converted_seat: Dictionary = _convert_record(
					seat, SEAT_IDENTITY_KEYS, SEAT_IDENTITY_FIELDS, to_wire
				)
				if not converted_seat.accepted:
					return converted_seat
				seats.append(converted_seat.payload)
			result[seats_key] = seats
		var board_key: String = "board"
		if result.get(board_key) is Dictionary:
			var converted_board: Dictionary = _convert_record(
				result[board_key], BOARD_VIEW_KEYS, BOARD_VIEW_FIELDS, to_wire
			)
			if not converted_board.accepted:
				return converted_board
			var board: Dictionary = converted_board.payload
			if board.get("spaces") is Array:
				var spaces: Array[Dictionary] = []
				for space: Variant in board.spaces:
					var converted_space: Dictionary = _convert_record(
						space, BOARD_SPACE_KEYS, BOARD_SPACE_FIELDS, to_wire
					)
					if not converted_space.accepted:
						return converted_space
					spaces.append(converted_space.payload)
				board["spaces"] = spaces
			result[board_key] = board
	elif message_type == "seat_private_view_update":
		var identity_key: String = "seatIdentity" if to_wire else "seat_identity"
		if result.get(identity_key) is Dictionary:
			var converted_identity: Dictionary = _convert_record(
				result[identity_key], SEAT_IDENTITY_KEYS, SEAT_IDENTITY_FIELDS, to_wire
			)
			if not converted_identity.accepted:
				return converted_identity
			result[identity_key] = converted_identity.payload
		var actions_key: String = "legalActions" if to_wire else "legal_actions"
		if result.get(actions_key) is Array:
			var actions: Array[Dictionary] = []
			for action: Variant in result[actions_key]:
				var converted_action: Dictionary = _convert_record(
					action, LEGAL_ACTION_KEYS, LEGAL_ACTION_FIELDS, to_wire
				)
				if not converted_action.accepted:
					return converted_action
				actions.append(converted_action.payload)
			result[actions_key] = actions
		if result.get("public") is Dictionary:
			var converted_public: Dictionary = _convert_payload(
				"public_view_update", result.public, to_wire
			)
			if not converted_public.accepted:
				return converted_public
			result["public"] = converted_public.payload
		var faction_key: String = "factionPrivate" if to_wire else "faction_private"
		if (
			result.get(faction_key) is Dictionary
			and not (result[faction_key] as Dictionary).is_empty()
		):
			var converted_faction: Dictionary = _convert_payload(
				"faction_private_view_update", result[faction_key], to_wire
			)
			if not converted_faction.accepted:
				return converted_faction
			result[faction_key] = converted_faction.payload
	elif message_type == "faction_private_view_update" and result.get("members") is Array:
		var members: Array[Dictionary] = []
		for member: Variant in result.members:
			var converted_member: Dictionary = _convert_record(
				member, FACTION_MEMBER_KEYS, FACTION_MEMBER_FIELDS, to_wire
			)
			if not converted_member.accepted:
				return converted_member
			members.append(converted_member.payload)
		result["members"] = members
	return {"accepted": true, "code": "accepted", "payload": result}


static func _convert_record(
	value: Variant, key_map: Dictionary, allowed_internal: Array, to_wire: bool
) -> Dictionary:
	if not value is Dictionary:
		return {"accepted": false, "code": "malformed"}
	var reverse_map: Dictionary = {}
	for internal_key: String in key_map:
		reverse_map[key_map[internal_key]] = internal_key
	var result: Dictionary = {}
	for key: Variant in value:
		if not key is String:
			return {"accepted": false, "code": "malformed"}
		var output_key: String = key
		if to_wire and key_map.has(key):
			output_key = key_map[key]
		elif not to_wire and reverse_map.has(key):
			output_key = reverse_map[key]
		elif (to_wire and reverse_map.has(key)) or (not to_wire and key_map.has(key)):
			return {"accepted": false, "code": "malformed"}
		if result.has(output_key):
			return {"accepted": false, "code": "malformed"}
		result[output_key] = value[key]
	var internal_record: Dictionary = value if to_wire else result
	for key: Variant in internal_record:
		if not key is String or not allowed_internal.has(key):
			return {"accepted": false, "code": "malformed"}
	return {"accepted": true, "code": "accepted", "payload": result}


static func _has_exact_keys(value: Variant, expected: Variant) -> bool:
	return value is Dictionary and _dictionary_has_exact_keys(value, expected)


static func _dictionary_has_exact_keys(value: Dictionary, expected: Variant) -> bool:
	if value.size() != expected.size():
		return false
	for key: Variant in value:
		if not key is String or not expected.has(key):
			return false
	return true


static func _wire_integer(value: Variant) -> Variant:
	if value is int and value >= 0:
		return value
	if value is float and is_finite(value) and value >= 0.0 and value == floorf(value):
		return int(value)
	return null
