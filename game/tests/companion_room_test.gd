extends SceneTree

var _failures: int = 0

func _initialize() -> void:
	_test_protocol_validation()
	_test_cross_runtime_wire_fixtures()
	_test_room_claim_and_private_views()
	_test_hidden_board_privacy_is_recursive()
	_test_intent_authority_and_idempotency()
	_test_invalid_requests_are_atomic_and_rng_free()
	_test_reconnect_and_local_input_policy()
	_test_room_close_and_expiry()
	_test_transport_and_diagnostics_contract()
	_test_generic_authority_guard()
	if _failures == 0:
		print("Companion Room tests passed")
	quit(_failures)

func _test_protocol_validation() -> void:
	var valid: Dictionary = CompanionProtocol.create_envelope("room_1", "prompt_choice_submit", "request_1", {"option_ids": ["listen"], "prompt_revision": 1}, 0, 2, 1)
	_expect(CompanionProtocol.validate_envelope(valid).accepted, "accepts a bounded versioned protocol envelope")
	var unsupported_version: Dictionary = valid.duplicate(true)
	unsupported_version.protocol_version = 99
	_expect(CompanionProtocol.validate_envelope(unsupported_version).code == "unsupported_version", "fails closed on unsupported protocol versions")
	var unsupported_type: Dictionary = valid.duplicate(true)
	unsupported_type.message_type = "mutate_board"
	_expect(CompanionProtocol.validate_envelope(unsupported_type).code == "unsupported_type", "fails closed on unknown message types")
	var too_large: Dictionary = valid.duplicate(true)
	too_large.payload = {"value": "x".repeat(CompanionProtocol.MAX_STRING_LENGTH + 1)}
	_expect(CompanionProtocol.validate_envelope(too_large).code == "malformed", "bounds string and payload sizes")
	_expect(CompanionProtocol.parse_envelope("{").code == "malformed", "keeps malformed JSON away from gameplay")
	_expect(CompanionProtocol.parse_envelope("x".repeat(CompanionProtocol.MAX_MESSAGE_BYTES + 1)).code == "body_too_large", "rejects oversized messages before JSON parsing")
	var unknown_field: Dictionary = valid.duplicate(true)
	unknown_field["roomId"] = "room_1"
	_expect(CompanionProtocol.validate_envelope(unknown_field).code == "malformed", "rejects mixed or unknown internal envelope fields")

func _test_cross_runtime_wire_fixtures() -> void:
	var fixture_value: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/companion_protocol_v1.json"))
	_expect(fixture_value is Dictionary, "loads the shared cross-runtime protocol fixture")
	if not fixture_value is Dictionary:
		return
	var fixture: Dictionary = fixture_value
	var parsed_typescript: Dictionary = CompanionWireCodec.from_wire_envelope(fixture.typescriptProducedWire)
	var normalized_typescript: Variant = JSON.parse_string(JSON.stringify(parsed_typescript.get("envelope", {})))
	_expect(parsed_typescript.accepted and normalized_typescript == fixture.typescriptExpectedInternal, "parses a TypeScript-produced camel-case envelope in Godot: %s" % JSON.stringify(parsed_typescript))
	var godot_internal: Dictionary = CompanionProtocol.create_envelope(
		"room_fixture", "acknowledgement", "typescript_choice_1",
		{"resulting_revision": 12, "applied_once": true, "authority_result": "accepted"},
		9, 12, 3, "accepted",
	)
	var produced_by_godot: Dictionary = CompanionWireCodec.to_wire_envelope(godot_internal)
	var normalized_godot_wire: Variant = JSON.parse_string(JSON.stringify(produced_by_godot.get("envelope", {})))
	_expect(produced_by_godot.accepted and normalized_godot_wire == fixture.godotProducedWire, "produces the TypeScript-valid camel-case fixture from Godot: %s" % JSON.stringify(produced_by_godot))
	var round_trip: Dictionary = CompanionWireCodec.from_wire_envelope(produced_by_godot.get("envelope", {}))
	_expect(round_trip.accepted and round_trip.envelope == godot_internal, "preserves intended values through the bidirectional wire conversion")
	for malformed: Variant in fixture.malformedMixedEnvelopes:
		_expect(CompanionWireCodec.from_wire_envelope(malformed).code == "malformed", "fails closed on a malformed or mixed wire schema")
	var mixed_nested: Dictionary = fixture.godotProducedWire.duplicate(true)
	mixed_nested.messageType = "public_view_update"
	mixed_nested.payload = {"board": {"viewVersion": 1, "view_version": 1, "revision": 0, "spaces": []}}
	_expect(CompanionWireCodec.from_wire_envelope(mixed_nested).code == "malformed", "fails closed on mixed nested protocol-owned view fields")

func _test_room_claim_and_private_views() -> void:
	var fixture: Dictionary = _fixture(4, "hidden_betrayer", 8080)
	var bridge: CompanionBridge = fixture.bridge
	var transport: CompanionFakeTransport = fixture.transport
	_expect(bridge.create_room("room_lantern", "GHST27").accepted, "creates a transport-neutral host room")
	_expect(transport.connect_client("client_one").accepted and bridge.diagnostics().pending_clients == 1, "keeps a browser pending until host approval")
	var secret_seat: int = fixture.roles.seat_with_tag("secret")
	_expect(transport.approve_client("client_one", secret_seat).accepted, "host explicitly approves a stable seat")
	var private_view: Dictionary = bridge.seat_view_for_client("client_one")
	var secret_role: Dictionary = fixture.roles.content.role_by_id(fixture.roles.seat_states[secret_seat].form_id)
	_expect(private_view.accepted and private_view.authorized_seat == secret_seat, "builds the approved seat-private companion view")
	_expect(secret_role.label in JSON.stringify(private_view), "delivers hidden role information only to its owning companion")
	var public_json: String = JSON.stringify(bridge.public_view())
	_expect(not secret_role.id in public_json and fixture.roles.privacy_report().passed, "keeps public companion data recursively free of unrevealed secrets")
	transport.connect_client("client_two")
	var other_seat: int = 1 if secret_seat != 1 else 2
	transport.approve_client("client_two", other_seat)
	_expect(not secret_role.id in JSON.stringify(bridge.seat_view_for_client("client_two")), "prevents another approved seat from receiving the hidden role")
	_expect(bridge.seat_view_for_client("unknown_client").reason == "seat_not_authorized", "fails closed for unclaimed clients")
	var private_prompt: Dictionary = fixture.rules_content.events[0].prompts[0].duplicate(true)
	private_prompt.scope = "single"
	var private_eligible: Array[int] = [secret_seat]
	fixture.rules.open_prompt(private_prompt, private_eligible, "private_companion_test")
	_expect(not private_prompt.options[0].id in JSON.stringify(bridge.public_view()), "withholds single-seat prompt choices from the public companion view")
	_expect(private_prompt.options[0].id in JSON.stringify(bridge.seat_view_for_client("client_one").rules_private), "delivers a private prompt only to its eligible authorized seat")
	_expect(not private_prompt.options[0].id in JSON.stringify(bridge.seat_view_for_client("client_two").rules_private), "withholds a private prompt from another approved seat")

func _test_hidden_board_privacy_is_recursive() -> void:
	var fixture: Dictionary = _fixture(4, "hidden_betrayer", 2309)
	var bridge: CompanionBridge = fixture.bridge
	var transport: CompanionFakeTransport = fixture.transport
	bridge.create_room("room_hidden_board", "SEAL27")
	transport.connect_client("client_owner")
	transport.approve_client("client_owner", 1)
	transport.drain("client_owner")
	var forbidden: PackedStringArray = [
		"sealed_archive", "The Sealed Archive", "Sealed Archive", "sealed_shelves",
		"archive_route", "archive_stairs",
	]
	var payloads: Array[Variant] = [
		bridge.public_view(), bridge.seat_view_for_client("unknown_client"),
		bridge.seat_view_for_client("client_owner"), bridge.diagnostics(),
	]
	var wrong_seat: Dictionary = transport.send_intent(
		"client_owner", "private_reveal_ack", "hidden_wrong_seat", {}, 2,
	)
	payloads.append(wrong_seat)
	payloads.append(transport.drain("client_owner"))
	transport.disconnect_client("client_owner")
	payloads.append(transport.resume_client("client_owner", 1))
	payloads.append(transport.drain("client_owner"))
	var serialized: String = JSON.stringify(payloads)
	for secret: String in forbidden:
		_expect(not secret.to_lower() in serialized.to_lower(), "omits hidden board identifier or derived text %s from all companion paths" % secret)
	_expect(fixture.board.companion_public_view().spaces.size() == 4, "omits the unrevealed authored space instead of publishing a placeholder")

func _test_intent_authority_and_idempotency() -> void:
	var fixture: Dictionary = _fixture(4, "cooperative", 4706)
	var bridge: CompanionBridge = fixture.bridge
	var transport: CompanionFakeTransport = fixture.transport
	bridge.create_room("room_action", "DREAD8")
	transport.connect_client("client_one")
	transport.approve_client("client_one", 1)
	var prompt: Dictionary = fixture.rules_content.events[0].prompts[0].duplicate(true)
	prompt.scope = "all"
	var eligible: Array[int] = [1, 2, 3, 4]
	fixture.rules.open_prompt(prompt, eligible, "companion_test")
	var before_history: int = fixture.rules.history().size()
	var result: Dictionary = transport.send_intent("client_one", "prompt_choice_submit", "choice_once", {
		"option_ids": ["listen"], "prompt_revision": fixture.rules.pending_prompt.revision,
	}, 1)
	_expect(result.accepted and fixture.rules.pending_prompt.responses[1] == ["listen"], "routes one valid prompt choice through RulesSession")
	var after_once: int = fixture.rules.history().size()
	var duplicate: Dictionary = transport.send_intent("client_one", "prompt_choice_submit", "choice_once", {
		"option_ids": ["listen"], "prompt_revision": fixture.rules.pending_prompt.revision,
	}, 1)
	_expect(duplicate.accepted and duplicate.idempotent and fixture.rules.history().size() == after_once, "acknowledges duplicate request IDs without applying twice")
	_expect(after_once == before_history + 1 and result.envelope.payload.applied_once, "records exactly one authoritative mutation for the accepted intent")
	_expect(result.envelope.authoritative_revision == bridge.authoritative_revision(), "returns the resulting authoritative revision")

func _test_invalid_requests_are_atomic_and_rng_free() -> void:
	var fixture: Dictionary = _fixture(4, "hidden_betrayer", 991)
	var bridge: CompanionBridge = fixture.bridge
	var transport: CompanionFakeTransport = fixture.transport
	bridge.create_room("room_atomic", "NGHT28")
	transport.connect_client("client_one")
	transport.approve_client("client_one", 1)
	var prompt: Dictionary = fixture.rules_content.events[0].prompts[0].duplicate(true)
	prompt.scope = "all"
	var eligible: Array[int] = [1, 2, 3, 4]
	fixture.rules.open_prompt(prompt, eligible, "atomic_test")
	var stable: Dictionary = _authority_state(fixture)
	var wrong_seat: Dictionary = transport.send_intent("client_one", "prompt_choice_submit", "wrong_seat", {"option_ids": ["listen"], "prompt_revision": fixture.rules.pending_prompt.revision}, 2)
	_expect(not wrong_seat.accepted and wrong_seat.code == "wrong_seat", "denies a cross-seat request")
	_expect(_authority_state(fixture) == stable, "wrong-seat denial changes no gameplay authority or RNG")
	var stale: Dictionary = transport.send_intent("client_one", "prompt_choice_submit", "stale_request", {"option_ids": ["listen"], "prompt_revision": fixture.rules.pending_prompt.revision}, 1, bridge.authoritative_revision() - 1)
	_expect(not stale.accepted and stale.code == "stale" and _authority_state(fixture) == stable, "rejects stale intents without partial mutation")
	var tampered: Dictionary = transport.send_intent("client_one", "prompt_choice_submit", "tampered", {"option_ids": [17], "prompt_revision": fixture.rules.pending_prompt.revision}, 1)
	_expect(not tampered.accepted and tampered.code == "malformed" and _authority_state(fixture) == stable, "rejects tampered payloads before authority mutation")
	var unsupported: Dictionary = transport.send_intent("client_one", "host_heartbeat", "unsupported", {}, 1)
	_expect(not unsupported.accepted and unsupported.code == "unsupported_type" and _authority_state(fixture) == stable, "rejects unsupported client work without gameplay mutation")
	var malformed: Dictionary = transport.send_raw("client_one", "{")
	_expect(not malformed.accepted and malformed.code == "malformed" and _authority_state(fixture) == stable, "rejects malformed raw JSON without gameplay RNG or state changes")
	var diagnostics_json: String = JSON.stringify(bridge.diagnostics())
	var private_view: Dictionary = fixture.roles.seat_private_view(fixture.roles.seat_with_tag("secret"))
	var private_objective: String = private_view.private.objectives[0].description
	_expect(not private_objective in diagnostics_json, "keeps rejection diagnostics free of private payload data")

func _test_reconnect_and_local_input_policy() -> void:
	var fixture: Dictionary = _fixture(4, "hidden_betrayer", 501)
	var bridge: CompanionBridge = fixture.bridge
	var transport: CompanionFakeTransport = fixture.transport
	bridge.create_room("room_resume", "WRATH7")
	var secret_seat: int = fixture.roles.seat_with_tag("secret")
	transport.connect_client("client_secret")
	transport.approve_client("client_secret", secret_seat)
	var private_before: Dictionary = bridge.seat_view_for_client("client_secret")
	transport.disconnect_client("client_secret")
	_expect(not transport.resume_client("client_secret", 1 if secret_seat != 1 else 2).accepted, "denies reconnect to a different stable seat")
	var resume_result: Dictionary = transport.resume_client("client_secret", secret_seat)
	_expect(resume_result.accepted, "resumes the host-authorized stable seat")
	_expect(bridge.seat_view_for_client("client_secret").social_private == private_before.social_private, "restores the same private role, objective, action, and prompt state")
	var prompt: Dictionary = fixture.rules_content.events[0].prompts[0].duplicate(true)
	prompt.scope = "all"
	var eligible: Array[int] = [1, 2, 3, 4]
	fixture.rules.open_prompt(prompt, eligible, "surface_policy")
	var local_choice: Array[String] = ["listen"]
	fixture.rules.submit_response(secret_seat, local_choice, fixture.rules.pending_prompt.revision)
	var history_after_local: int = fixture.rules.history().size()
	var companion_duplicate: Dictionary = transport.send_intent("client_secret", "prompt_choice_submit", "local_duplicate", {"option_ids": ["force"], "prompt_revision": fixture.rules.pending_prompt.revision}, secret_seat)
	_expect(not companion_duplicate.accepted and companion_duplicate.code == "duplicate", "uses one stable seat with deterministic local/companion duplicate protection")
	_expect(fixture.rules.history().size() == history_after_local, "does not create duplicate ownership or a second mutation")

func _test_transport_and_diagnostics_contract() -> void:
	var fixture: Dictionary = _fixture(1, "cooperative", 42)
	var bridge: CompanionBridge = fixture.bridge
	bridge.create_room("room_diag", "GLM267")
	fixture.transport.connect_client("client_one")
	fixture.transport.approve_client("client_one", 1)
	var diagnostics: Dictionary = bridge.diagnostics()
	_expect(diagnostics.protocol_version == 1 and diagnostics.bridge_version == "0.0.9", "versions sanitized transport diagnostics")
	_expect(diagnostics.privacy == "NO CAPABILITIES OR PRIVATE PAYLOADS" and not "payload" in JSON.stringify(diagnostics), "bounds diagnostics to metadata without capabilities or payloads")
	_expect(diagnostics.history.size() <= CompanionBridge.HISTORY_LIMIT, "keeps transport history bounded")
	var websocket := CompanionWebSocketTransport.new()
	_expect(not websocket.connect_to_room("ws://example.com/socket", {}).accepted, "allows non-TLS WebSockets only for local development")
	_expect(websocket.connect_to_room("ws://127.0.0.1:8787/v1/rooms/GLM267/socket", {"operation": "join", "clientId": "synthetic"}).accepted, "supports the local WebSocket prototype without credentials")
	websocket.close()
	_expect(not websocket.sanitized_diagnostics().has("authentication"), "never exposes authentication values in transport diagnostics")

func _test_room_close_and_expiry() -> void:
	for should_expire: bool in [false, true]:
		var fixture: Dictionary = _fixture(1, "cooperative", 616)
		var bridge: CompanionBridge = fixture.bridge
		bridge.create_room("room_lifecycle", "FABLE7")
		fixture.transport.connect_client("client_one")
		fixture.transport.approve_client("client_one", 1)
		var lifecycle: Dictionary = bridge.expire_room() if should_expire else bridge.close_room()
		_expect(lifecycle.accepted and not bridge.room_open, "destroys ephemeral membership on room %s" % ("expiry" if should_expire else "close"))
		_expect(not fixture.transport.resume_client("client_one", 1).accepted and bridge.diagnostics().connected_clients == 0, "fails reconnect closed after room %s" % ("expiry" if should_expire else "close"))

func _test_generic_authority_guard() -> void:
	var bridge_source: String = FileAccess.get_file_as_string("res://src/companion/companion_bridge.gd")
	var host_source: String = FileAccess.get_file_as_string("res://src/companion/companion_room_service_host.gd")
	_expect(not "board_state.apply_mutation" in bridge_source and not "rules_session.apply_effect_bundle" in bridge_source and not "seat_manager.join_device" in bridge_source, "keeps direct board/rules/seat mutations out of the bridge")
	_expect(not "RulesSession" in host_source and not "RoleSession" in host_source and not "BoardState" in host_source and not "print(" in host_source, "keeps gameplay authorities and sensitive logging out of the native room-service adapter")
	for forbidden: String in ["betrayer", "living", "restless", "changed", "threshold_whisper"]:
		_expect(not ("if action_id == \"%s\"" % forbidden) in bridge_source and not ("match \"%s\"" % forbidden) in bridge_source, "keeps literal authored ID %s out of generic companion routing" % forbidden)

func _fixture(seat_count: int, mode_id: String, seed: int) -> Dictionary:
	var seats := SeatManager.new()
	var seat_numbers: Array[int] = []
	for index: int in seat_count:
		seats.join_device(index, "synthetic-%d" % index, "Synthetic Pad")
		seat_numbers.append(index + 1)
	var board := BoardState.new(LanternHouseBoardDefinition.new())
	var rules_content := LanternHouseRulesContent.new()
	var rules := RulesSession.new(rules_content, board, seed, seat_numbers)
	var director := DirectorRuntime.new(LanternHouseDirectorContent.new(), "standard", seed, rules_content, board.definition)
	var roles := RoleSession.new(LanternHouseSocialContent.new(), mode_id, seed, seat_numbers)
	var bridge := CompanionBridge.new(seats, board, rules, director, roles)
	var transport := CompanionFakeTransport.new(bridge)
	return {"seats": seats, "board": board, "rules_content": rules_content, "rules": rules, "director": director, "roles": roles, "bridge": bridge, "transport": transport}

func _authority_state(fixture: Dictionary) -> Dictionary:
	return {
		"seats": fixture.seats.get_seats(), "board": fixture.board.to_snapshot(), "rules": fixture.rules.to_snapshot(),
		"roles": fixture.roles.to_snapshot(), "director": fixture.director.to_snapshot(),
	}

func _expect(condition: bool, description: String) -> void:
	if not condition:
		_failures += 1
		push_error("FAILED: %s" % description)
