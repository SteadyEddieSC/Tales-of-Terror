#!/usr/bin/env python3
from pathlib import Path
import sys

root = Path(sys.argv[1]).resolve()
path = root / "game/tests/playtest_main_route_test.gd"
text = path.read_text(encoding="utf-8")
old = '''func _run_active_tale(coordinator: VerticalSliceCoordinator) -> void:
	var guard: int = 0
	while coordinator.lifecycle == "active_tale" and guard < 8:
		var prompt: Dictionary = coordinator.rules_session.pending_prompt
		if not prompt.is_empty():
			var option_id: String = prompt.options[0].id
			for seat_number: int in prompt.eligible_seats:
				coordinator.rules_session.submit_response(seat_number, [option_id], prompt.revision)
		var result: Dictionary = coordinator.run_current_stage()
		_expect(result.accepted, "fixture advances authored active stage %d" % guard)
		guard += 1
		await process_frame
	_expect(guard < 8, "active route reaches terminal within the authored stage bound")
'''
new = '''func _run_active_tale(coordinator: VerticalSliceCoordinator) -> void:
	var guard: int = 0
	while coordinator.lifecycle == "active_tale" and guard < 24:
		var interaction: Dictionary = coordinator.public_state().get("interaction", {})
		_expect(not interaction.is_empty(), "active route publishes interaction %d" % guard)
		if interaction.is_empty():
			break
		if interaction.get("kind", "") in ["choice", "vote"]:
			for seat_number: int in interaction.get("pending_seats", []):
				await _press_button(seat_number - 1, BUTTON_A)
			interaction = coordinator.public_state().get("interaction", {})
			if interaction.get("kind", "") in ["choice", "vote"]:
				var eligible: Array = interaction.get("eligible_seats", [])
				if not eligible.is_empty():
					await _press_button(int(eligible[0]) - 1, BUTTON_A)
		else:
			var actor: int = int(interaction.get("owner_seat", 0))
			var eligible: Array = interaction.get("eligible_seats", [])
			if actor <= 0 and not eligible.is_empty():
				actor = int(eligible[0])
			_expect(actor > 0, "interaction %d has an eligible controller owner" % guard)
			if actor <= 0:
				break
			await _press_button(actor - 1, BUTTON_A)
		guard += 1
		await process_frame
	_expect(guard < 24, "active route reaches terminal within the interaction bound")
'''
count = text.count(old)
if count != 1:
    raise SystemExit(f"expected one legacy active-route helper, found {count}")
path.write_text(text.replace(old, new, 1), encoding="utf-8")
