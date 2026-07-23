extends SceneTree

const FORBIDDEN_PUBLIC_TERMS: PackedStringArray = [
	"private_objective", "provider_id", "package_sha256", "source_ledger", "res://"
]

var _failures: int = 0


func _initialize() -> void:
	_test_player_owned_complete_route()
	_test_pause_and_invalid_seat_are_non_mutating()
	if _failures == 0:
		print("Player-owned interaction tests passed")
	quit(_failures)


func _test_player_owned_complete_route() -> void:
	var coordinator: VerticalSliceCoordinator = _active_coordinator(3)
	var threshold: Dictionary = coordinator._submit_player_interaction(1, "confirm")
	_expect(threshold.accepted and threshold.waiting_for_players, "opens the threshold choice")
	_expect(
		coordinator.public_state().interaction.kind == "choice",
		"projects the threshold as a shared choice",
	)
	_submit_first_option_for_every_eligible_seat(coordinator)
	_expect(
		coordinator._submit_player_interaction(1, "confirm").accepted,
		"resolves the completed threshold choice",
	)
	_expect(coordinator.stage_index == 1, "advances to the council stage")

	_expect(
		coordinator._submit_player_interaction(2, "confirm").waiting_for_players,
		"opens the council vote from an active seat",
	)
	var vote: Dictionary = coordinator.public_state().interaction
	_expect(vote.kind == "vote", "projects the council as a public vote")
	_expect(vote.pending_seats.size() == 3, "lists all pending council seats")
	_submit_alternating_vote(coordinator)
	_expect(
		coordinator._submit_player_interaction(1, "confirm").accepted,
		"resolves the council only after every seat commits",
	)
	_expect(coordinator.stage_index == 2, "advances to the reckoning stage")

	_expect(
		coordinator._submit_player_interaction(3, "confirm").waiting_for_players,
		"runs automatic setup and stops at player-owned card play",
	)
	var card: Dictionary = coordinator.public_state().interaction
	_expect(card.kind == "card_play" and card.owner_seat == 1, "assigns the card to Seat I")
	var before_wrong_card: String = coordinator.authority_digest()
	var wrong_card: Dictionary = coordinator._submit_player_interaction(2, "confirm")
	_expect(
		not wrong_card.accepted and wrong_card.consumed,
		"rejects another seat playing the card",
	)
	_expect(
		coordinator.authority_digest() == before_wrong_card,
		"wrong-seat card input mutates nothing",
	)
	_expect(coordinator._submit_player_interaction(1, "confirm").accepted, "Seat I plays the card")

	var check: Dictionary = coordinator.public_state().interaction
	_expect(check.kind == "check_attempt" and check.owner_seat == 1, "assigns the courage check")
	var before_wrong_check: String = coordinator.authority_digest()
	_expect(
		not coordinator._submit_player_interaction(3, "confirm").accepted,
		"rejects an unrelated seat attempting the check",
	)
	_expect(
		coordinator.authority_digest() == before_wrong_check,
		"wrong-seat check input mutates nothing",
	)
	_expect(coordinator._submit_player_interaction(1, "confirm").accepted, "Seat I attempts the check")
	_expect(not coordinator.rules_session.recent_check.is_empty(), "records the deterministic check")

	var director: Dictionary = coordinator.public_state().interaction
	_expect(director.kind == "director_acknowledgement", "pauses before the Director application")
	var director_before: Dictionary = coordinator.director_runtime.to_snapshot()
	_expect(
		not coordinator._submit_player_interaction(9, "confirm").accepted,
		"rejects a nonexistent Director acknowledgement seat",
	)
	_expect(
		coordinator.director_runtime.to_snapshot() == director_before,
		"invalid acknowledgement consumes no Director RNG",
	)
	_expect(coordinator._submit_player_interaction(2, "confirm").accepted, "an active seat continues")
	_expect(not coordinator.last_director_decision.is_empty(), "records one Director decision")
	_expect(coordinator.stage_index == 3, "advances to afterlife")

	_expect(
		coordinator._submit_player_interaction(1, "confirm").waiting_for_players,
		"applies defeat and stops at the Restless decision",
	)
	var afterlife: Dictionary = coordinator.public_state().interaction
	_expect(
		afterlife.kind == "afterlife_action" and afterlife.owner_seat > 0,
		"assigns afterlife work to the actual Restless seat",
	)
	var non_actor: int = 1 if afterlife.owner_seat != 1 else 2
	var before_wrong_afterlife: String = coordinator.authority_digest()
	_expect(
		not coordinator._submit_player_interaction(non_actor, "confirm").accepted,
		"rejects a living or otherwise ineligible afterlife actor",
	)
	_expect(
		coordinator.authority_digest() == before_wrong_afterlife,
		"wrong-seat afterlife input mutates nothing",
	)
	_expect(
		coordinator._submit_player_interaction(afterlife.owner_seat, "pass").accepted,
		"permits the authored afterlife pass",
	)
	_expect(coordinator.stage_index == 4, "advances to the ending stage")
	_expect(coordinator._submit_player_interaction(1, "confirm").accepted, "resolves the ending")
	_expect(coordinator.lifecycle == "terminal", "reaches the deterministic terminal result")

	var public_text: String = JSON.stringify(coordinator.public_state()).to_lower()
	for forbidden: String in FORBIDDEN_PUBLIC_TERMS:
		_expect(forbidden not in public_text, "public interaction excludes %s" % forbidden)


func _test_pause_and_invalid_seat_are_non_mutating() -> void:
	var coordinator: VerticalSliceCoordinator = _active_coordinator(2)
	coordinator._submit_player_interaction(1, "confirm")
	var before_pause: Dictionary = coordinator.to_snapshot()
	coordinator.toggle_pause()
	var paused_before_input: Dictionary = coordinator.to_snapshot()
	var blocked: Dictionary = coordinator._submit_player_interaction(1, "confirm")
	_expect(
		not blocked.accepted and blocked.consumed,
		"consumes but rejects gameplay input while paused",
	)
	_expect(coordinator.to_snapshot() == paused_before_input, "paused input changes no authority")
	coordinator.toggle_pause()
	_expect(
		coordinator.to_snapshot().stage_index == before_pause.stage_index,
		"pause and resume retain the interaction boundary",
	)
	var invalid_before: Dictionary = coordinator.to_snapshot()
	var invalid: Dictionary = coordinator._submit_player_interaction(8, "confirm")
	_expect(not invalid.accepted and invalid.consumed, "consumes an ineligible-seat attempt")
	_expect(coordinator.to_snapshot() == invalid_before, "ineligible-seat attempt changes no snapshot")


func _active_coordinator(seat_count: int) -> VerticalSliceCoordinator:
	var coordinator := VerticalSliceCoordinator.new()
	for index: int in seat_count:
		coordinator.seat_manager.join_device(index, "player-owned-pad-%d" % index, "Fixture Pad")
	coordinator.enter_lobby()
	coordinator.confirm_roster()
	coordinator.navigate_tale_library("open")
	coordinator.initialize_session(4706)
	coordinator.begin_tale()
	return coordinator


func _submit_first_option_for_every_eligible_seat(
	coordinator: VerticalSliceCoordinator
) -> void:
	var prompt: Dictionary = coordinator.rules_session.pending_prompt
	var option_id: String = prompt.options[0].id
	for seat_number: int in prompt.eligible_seats:
		_expect(
			coordinator.rules_session.submit_response(seat_number, [option_id], prompt.revision).accepted,
			"accepts Seat %d threshold response" % seat_number,
		)


func _submit_alternating_vote(coordinator: VerticalSliceCoordinator) -> void:
	var prompt: Dictionary = coordinator.rules_session.pending_prompt
	for seat_number: int in prompt.eligible_seats:
		var option_id: String = "gallery" if seat_number % 2 == 1 else "vault"
		_expect(
			coordinator.rules_session.submit_response(seat_number, [option_id], prompt.revision).accepted,
			"accepts Seat %d council vote" % seat_number,
		)


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
		return
	_failures += 1
	push_error("FAILED: %s" % message)
