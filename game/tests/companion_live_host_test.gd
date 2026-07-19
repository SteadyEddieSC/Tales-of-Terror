extends SceneTree

const TIMEOUT_SECONDS: float = 120.0

var _adapter: CompanionRoomServiceHost
var _bridge: CompanionBridge
var _rules: RulesSession
var _history_before: int = 0
var _elapsed: float = 0.0
var _result_path: String = ""
var _finished: bool = false
var _pending_evidence: Dictionary = {}

func _initialize() -> void:
	call_deferred("_start")

func _process(delta: float) -> bool:
	_elapsed += delta
	if not _finished and _elapsed >= TIMEOUT_SECONDS:
		_finish(false, "timeout_waiting_for_browser_authority_path")
	return false

func _start() -> void:
	var service_url: String = "http://127.0.0.1:8787"
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	for index: int in arguments.size():
		if arguments[index] == "--service-url" and index + 1 < arguments.size():
			service_url = arguments[index + 1]
		elif arguments[index] == "--result-path" and index + 1 < arguments.size():
			_result_path = arguments[index + 1]
	var seats := SeatManager.new()
	seats.join_device(0, "e2e-local-controller", "E2E Local Controller")
	var board := BoardState.new(LanternHouseBoardDefinition.new())
	var rules_content := LanternHouseRulesContent.new()
	var seat_numbers: Array[int] = [1]
	_rules = RulesSession.new(rules_content, board, 2309, seat_numbers)
	var director := DirectorRuntime.new(LanternHouseDirectorContent.new(), "standard", 2309, rules_content, board.definition)
	var roles := RoleSession.new(LanternHouseSocialContent.new(), "cooperative", 2309, seat_numbers)
	_bridge = CompanionBridge.new(seats, board, _rules, director, roles)
	var prompt: Dictionary = rules_content.events[0].prompts[0].duplicate(true)
	prompt.scope = "all"
	if not _rules.open_prompt(prompt, seat_numbers, "live_companion_e2e").accepted:
		_finish(false, "prompt_setup_failed")
		return
	_history_before = _rules.history().size()
	_adapter = CompanionRoomServiceHost.new()
	root.add_child(_adapter)
	if not _adapter.initialize(service_url, _bridge).accepted:
		_finish(false, "host_adapter_initialization_failed")
		return
	_adapter.room_ready.connect(_on_room_ready)
	_adapter.pending_client_discovered.connect(_on_pending_client)
	_adapter.client_resumed.connect(_on_client_resumed)
	_adapter.authoritative_intent_completed.connect(_on_authoritative_intent)
	_adapter.outbound_delivery_completed.connect(_on_outbound_delivery)
	_adapter.service_state_changed.connect(_on_service_state)
	if not _adapter.create_room().accepted:
		_finish(false, "room_creation_not_queued")

func _on_room_ready(room_id: String, join_code: String) -> void:
	print("COMPANION_E2E_ROOM:%s" % JSON.stringify({"roomId": room_id, "joinCode": join_code}))

func _on_pending_client(client_id: String, client_display: String) -> void:
	print("COMPANION_E2E_PENDING:%s" % JSON.stringify({"clientDisplay": client_display}))
	var queued: Dictionary = _adapter.approve_client(client_id, 1)
	if not queued.accepted:
		_finish(false, "host_seat_approval_not_queued")

func _on_client_resumed(client_id: String, seat_number: int) -> void:
	print("COMPANION_E2E_RECONNECT:%s" % JSON.stringify({
		"clientDisplay": CompanionProtocol.request_display(client_id), "seat": seat_number,
		"sameStableSeat": true,
	}))

func _on_authoritative_intent(_client_id: String, request_id: String, accepted: bool, code: String) -> void:
	if _finished:
		return
	var response: Variant = _rules.pending_prompt.get("responses", {}).get(1)
	var applied_once: bool = accepted and response == ["listen"] and _rules.history().size() == _history_before + 1
	if not applied_once:
		_finish(false, "authority_result_%s" % code)
		return
	_pending_evidence = {
		"accepted": true,
		"requestDisplay": CompanionProtocol.request_display(request_id),
		"seat": 1,
		"choice": "listen",
		"historyDelta": _rules.history().size() - _history_before,
		"appliedOnce": true,
		"authoritativeRevision": _bridge.authoritative_revision(),
		"path": "browser_to_service_to_native_bridge_to_rules_to_service_to_browser",
		"diagnostics": _adapter.sanitized_diagnostics(),
	}
	print("COMPANION_E2E_AUTHORITY:%s" % JSON.stringify(_pending_evidence))

func _on_outbound_delivery(_client_id: String, request_id: String, message_type: String, accepted: bool, code: String) -> void:
	if _finished or _pending_evidence.is_empty() or message_type != "acknowledgement":
		return
	if CompanionProtocol.request_display(request_id) != _pending_evidence.requestDisplay:
		return
	if not accepted:
		_finish(false, "authoritative_ack_delivery_%s" % code)
		return
	_pending_evidence["browserAcknowledgementDelivered"] = true
	print("COMPANION_E2E_DELIVERED:%s" % JSON.stringify({"requestDisplay": _pending_evidence.requestDisplay, "authoritative": true}))
	if not _result_path.is_empty():
		var file := FileAccess.open(_result_path, FileAccess.WRITE)
		if file != null:
			file.store_string(JSON.stringify(_pending_evidence, "  "))
	_finish(true, "accepted_once")

func _on_service_state(state: String) -> void:
	if not _finished and state == "unavailable":
		_finish(false, "service_unavailable_without_gameplay_mutation")

func _finish(success: bool, reason: String) -> void:
	if _finished:
		return
	_finished = true
	if is_instance_valid(_adapter) and _adapter.sanitized_diagnostics().get("room_active", false):
		_adapter.close_room()
	print("COMPANION_E2E_RESULT:%s" % JSON.stringify({"accepted": success, "reason": reason}))
	quit(0 if success else 1)
