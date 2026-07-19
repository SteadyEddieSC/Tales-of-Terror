extends GutTest


func test_wire_codec_round_trip_preserves_protocol_owned_fields() -> void:
	var internal: Dictionary = (
		CompanionProtocol
		. create_envelope(
			"room_gut",
			"acknowledgement",
			"request_gut_1",
			{
				"resulting_revision": 7,
				"applied_once": true,
				"authority_result": "accepted",
			},
			6,
			7,
			1,
			"accepted",
		)
	)
	var encoded: Dictionary = CompanionWireCodec.to_wire_envelope(internal)
	assert_true(encoded.get("accepted", false), "internal envelope encodes")
	var wire: Dictionary = encoded.get("envelope", {})
	assert_eq(wire.get("messageType", ""), "acknowledgement")
	assert_eq(wire.get("payload", {}).get("resultingRevision", -1), 7)
	assert_false(wire.has("message_type"), "mixed internal envelope keys stay off the wire")
	var decoded: Dictionary = CompanionWireCodec.from_wire_envelope(wire)
	assert_true(decoded.get("accepted", false), "wire envelope decodes")
	assert_eq(decoded.get("envelope", {}), internal, "round trip preserves intended values")


func test_mixed_schema_envelope_fails_closed() -> void:
	var mixed_wire: Dictionary = {
		"protocolVersion": 1,
		"messageType": "host_heartbeat",
		"message_type": "host_heartbeat",
		"roomId": "room_gut",
		"requestId": "request_gut_mixed",
		"sequence": 1,
		"payload": {},
	}
	var result: Dictionary = CompanionWireCodec.from_wire_envelope(mixed_wire)
	assert_false(result.get("accepted", true), "mixed schema is rejected")
	assert_eq(result.get("code", ""), "malformed")
