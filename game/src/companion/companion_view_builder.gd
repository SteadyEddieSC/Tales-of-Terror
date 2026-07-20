class_name CompanionViewBuilder
extends RefCounted

const VIEW_VERSION: int = 1
const TOKENS: VisualTokens = preload("res://assets/theme/visual_tokens.tres")
const SEAT_SHAPES: PackedStringArray = [
	"circle", "diamond", "triangle", "square", "star", "hexagon", "moon", "lantern"
]
const SEAT_COLOR_NAMES: PackedStringArray = [
	"yellow", "blue", "orange", "ivory", "sky", "green", "plum", "amber"
]

var _seat_manager: SeatManager
var _board_state: BoardState
var _rules_session: RulesSession
var _director_runtime: DirectorRuntime
var _role_session: RoleSession


func _init(
	seat_manager: SeatManager,
	board_state: BoardState,
	rules_session: RulesSession,
	director_runtime: DirectorRuntime,
	role_session: RoleSession,
) -> void:
	_seat_manager = seat_manager
	_board_state = board_state
	_rules_session = rules_session
	_director_runtime = director_runtime
	_role_session = role_session


func public_payload(room_id: String, room_status: String, connected_clients: int) -> Dictionary:
	var seats: Array[Dictionary] = []
	for seat: Dictionary in _seat_manager.get_seats():
		if _rules_session.participating_seats.has(seat.seat_number):
			var identity: Dictionary = seat_identity(seat.seat_number)
			identity["connection"] = SeatManager.state_label(seat.state)
			seats.append(identity)
	return _json_copy(
		{
			"view_version": VIEW_VERSION,
			"view_kind": "public_companion",
			"room_id": room_id,
			"room_status": room_status,
			"connected_clients": connected_clients,
			"seats": seats,
			"rules": _rules_session.companion_public_view(),
			"board": _board_state.companion_public_view(),
			"social": _role_session.public_view(),
			"director": _director_runtime.companion_public_view(),
		}
	)


func seat_payload(room_id: String, seat_number: int) -> Dictionary:
	if not _rules_session.participating_seats.has(seat_number):
		return {"accepted": false, "reason": "seat_not_authorized"}
	var social_view: Dictionary = _role_session.seat_private_view(seat_number)
	var rules_view: Dictionary = _rules_session.companion_seat_view(seat_number)
	if not social_view.get("accepted", false) or not rules_view.get("accepted", false):
		return {"accepted": false, "reason": "seat_not_authorized"}
	var legal_actions: Array[Dictionary] = []
	for action: Dictionary in _role_session.legal_actions(seat_number, _rules_session):
		(
			legal_actions
			. append(
				{
					"action_id": action.get("action_id", ""),
					"label": action.get("label", ""),
					"description": action.get("description", ""),
					"symbol": action.get("symbol", ""),
				}
			)
		)
	var faction_view: Dictionary = _role_session.faction_private_view(seat_number)
	return _json_copy(
		{
			"accepted": true,
			"view_version": VIEW_VERSION,
			"view_kind": "seat_private_companion",
			"room_id": room_id,
			"authorized_seat": seat_number,
			"seat_identity": seat_identity(seat_number),
			"public": public_payload(room_id, "open", 0),
			"rules_private": rules_view,
			"social_private": social_view.get("private", {}).duplicate(true),
			"legal_actions": legal_actions,
			"faction_private": faction_view if faction_view.get("accepted", false) else {},
			"privacy_notice":
			"Private to the host-authorized stable seat. Obscure before sharing this browser.",
		}
	)


func seat_identity(seat_number: int) -> Dictionary:
	if seat_number < 1 or seat_number > SeatManager.MAX_SEATS:
		return {}
	var index: int = seat_number - 1
	return {
		"seat": seat_number,
		"numeral": TOKENS.player_symbols[index],
		"symbol": SEAT_SHAPES[index],
		"pattern": "%d segment%s" % [seat_number, "" if seat_number == 1 else "s"],
		"color_name": SEAT_COLOR_NAMES[index],
		"color_hex": TOKENS.player_colors[index].to_html(false),
	}


func _json_copy(value: Variant) -> Variant:
	return JSON.parse_string(JSON.stringify(value))
