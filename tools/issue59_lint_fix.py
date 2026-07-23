#!/usr/bin/env python3
from pathlib import Path
import sys

root = Path(sys.argv[1]).resolve()


def replace_once(path: Path, old: str, new: str, label: str) -> None:
    text = path.read_text(encoding='utf-8')
    count = text.count(old)
    if count != 1:
        raise SystemExit(f'{label}: expected one match, found {count}')
    path.write_text(text.replace(old, new, 1), encoding='utf-8')


flow = root / 'game/src/session/player_interaction_flow.gd'
old_submit = '''func submit(
	coordinator: VerticalSliceCoordinator, seat_number: int, action: String
) -> Dictionary:
	if coordinator.lifecycle != "active_tale":
		return {"accepted": false, "consumed": false, "reason": "interaction_not_available"}
	if coordinator.paused:
		return {"accepted": false, "consumed": true, "reason": "session_paused"}
	if not VALID_ACTIONS.has(action):
		return {"accepted": false, "consumed": true, "reason": "unsupported_interaction_action"}
	var state: Dictionary = public_state(coordinator)
	if state.is_empty():
		return {"accepted": false, "consumed": false, "reason": "interaction_not_available"}
	if not state.get("eligible_seats", []).has(seat_number):
		return {"accepted": false, "consumed": true, "reason": "interaction_seat_not_eligible"}
	match state.kind:
		"choice", "vote":
			if action != "confirm":
				return {"accepted": false, "consumed": true, "reason": "response_still_pending"}
			if not coordinator._pending_responses_complete():
				return {"accepted": false, "consumed": true, "reason": "responses_incomplete"}
			return _consumed(_advance(coordinator))
		"stage_continue":
			if action != "confirm":
				return {"accepted": false, "consumed": true, "reason": "stage_continue_required"}
			return _consumed(_advance(coordinator))
		"card_play", "check_attempt", "director_acknowledgement", "afterlife_action":
			return _submit_operation(coordinator, state, action)
		_:
			return {"accepted": false, "consumed": true, "reason": "interaction_not_committable"}
'''
new_submit = '''func submit(
	coordinator: VerticalSliceCoordinator, seat_number: int, action: String
) -> Dictionary:
	var rejection: Dictionary = _submission_rejection(coordinator, seat_number, action)
	if not rejection.is_empty():
		return rejection
	return _commit_submission(coordinator, public_state(coordinator), action)


func _submission_rejection(
	coordinator: VerticalSliceCoordinator, seat_number: int, action: String
) -> Dictionary:
	if coordinator.lifecycle != "active_tale":
		return {"accepted": false, "consumed": false, "reason": "interaction_not_available"}
	if coordinator.paused:
		return {"accepted": false, "consumed": true, "reason": "session_paused"}
	if not VALID_ACTIONS.has(action):
		return {"accepted": false, "consumed": true, "reason": "unsupported_interaction_action"}
	var state: Dictionary = public_state(coordinator)
	if state.is_empty():
		return {"accepted": false, "consumed": false, "reason": "interaction_not_available"}
	if not state.get("eligible_seats", []).has(seat_number):
		return {"accepted": false, "consumed": true, "reason": "interaction_seat_not_eligible"}
	return {}


func _commit_submission(
	coordinator: VerticalSliceCoordinator, state: Dictionary, action: String
) -> Dictionary:
	match state.kind:
		"choice", "vote":
			if action != "confirm":
				return {"accepted": false, "consumed": true, "reason": "response_still_pending"}
			if not _responses_complete(coordinator):
				return {"accepted": false, "consumed": true, "reason": "responses_incomplete"}
			return _consumed(_advance(coordinator))
		"stage_continue":
			if action != "confirm":
				return {"accepted": false, "consumed": true, "reason": "stage_continue_required"}
			return _consumed(_advance(coordinator))
		"card_play", "check_attempt", "director_acknowledgement", "afterlife_action":
			return _submit_operation(coordinator, state, action)
		_:
			return {"accepted": false, "consumed": true, "reason": "interaction_not_committable"}
'''
replace_once(flow, old_submit, new_submit, 'submit refactor')
flow_text = flow.read_text(encoding='utf-8')
flow_text = flow_text.replace('coordinator._pending_responses_complete()', '_responses_complete(coordinator)')
helper_marker = '\n\nfunc _consumed(result: Dictionary) -> Dictionary:\n'
responses_helper = '''

func _responses_complete(coordinator: VerticalSliceCoordinator) -> bool:
	var prompt: Dictionary = coordinator.rules_session.pending_prompt
	if prompt.is_empty():
		return false
	var eligible: Array = prompt.get("eligible_seats", [])
	var responses: Dictionary = prompt.get("responses", {})
	return not eligible.is_empty() and responses.size() >= eligible.size()
'''
if flow_text.count(helper_marker) != 1:
    raise SystemExit('responses helper marker drifted')
flow.write_text(flow_text.replace(helper_marker, responses_helper + helper_marker, 1), encoding='utf-8')

coordinator = root / 'game/src/session/vertical_slice_coordinator.gd'
replace_once(
    coordinator,
    'func submit_player_interaction(seat_number: int, action: String) -> Dictionary:',
    'func _submit_player_interaction(seat_number: int, action: String) -> Dictionary:',
    'private interaction boundary',
)
response_method = '''

func _pending_responses_complete() -> bool:
	if rules_session.pending_prompt.is_empty():
		return false
	var eligible: Array = rules_session.pending_prompt.get("eligible_seats", [])
	var responses: Dictionary = rules_session.pending_prompt.get("responses", {})
	return not eligible.is_empty() and responses.size() >= eligible.size()
'''
replace_once(coordinator, response_method, '', 'move response completeness helper')
coordinator_text = coordinator.read_text(encoding='utf-8').replace(
    '_pending_responses_complete()',
    '_player_interaction_flow._responses_complete(self)',
)
coordinator.write_text(coordinator_text, encoding='utf-8')

for relative in ('game/src/main/main.gd', 'game/tests/player_owned_interaction_test.gd'):
    path = root / relative
    text = path.read_text(encoding='utf-8')
    if '.submit_player_interaction(' not in text:
        raise SystemExit(f'{relative}: interaction call marker drifted')
    path.write_text(text.replace('.submit_player_interaction(', '._submit_player_interaction('), encoding='utf-8')

test = root / 'game/tests/player_owned_interaction_test.gd'
replace_once(
    test,
    '\t_expect(not wrong_card.accepted and wrong_card.consumed, "rejects another seat playing the card")\n\t_expect(coordinator.authority_digest() == before_wrong_card, "wrong-seat card input mutates nothing")\n',
    '\t_expect(\n\t\tnot wrong_card.accepted and wrong_card.consumed,\n\t\t"rejects another seat playing the card",\n\t)\n\t_expect(\n\t\tcoordinator.authority_digest() == before_wrong_card,\n\t\t"wrong-seat card input mutates nothing",\n\t)\n',
    'wrap card assertions',
)
replace_once(
    test,
    '\t_expect(coordinator.authority_digest() == before_wrong_check, "wrong-seat check input mutates nothing")\n',
    '\t_expect(\n\t\tcoordinator.authority_digest() == before_wrong_check,\n\t\t"wrong-seat check input mutates nothing",\n\t)\n',
    'wrap check assertion',
)
replace_once(
    test,
    '\t_expect(not blocked.accepted and blocked.consumed, "consumes but rejects gameplay input while paused")\n',
    '\t_expect(\n\t\tnot blocked.accepted and blocked.consumed,\n\t\t"consumes but rejects gameplay input while paused",\n\t)\n',
    'wrap paused assertion',
)

if len(coordinator.read_text(encoding='utf-8').splitlines()) > 1000:
    raise SystemExit('coordinator remains above 1000 lines')
for path in (flow, coordinator, root / 'game/src/main/main.gd', test):
    for number, line in enumerate(path.read_text(encoding='utf-8').splitlines(), start=1):
        if len(line) > 100:
            raise SystemExit(f'{path.relative_to(root)}:{number}: line exceeds 100 characters')
        if line.endswith((' ', '\t')):
            raise SystemExit(f'{path.relative_to(root)}:{number}: trailing whitespace')
