class_name DirectorProposalApplier
extends RefCounted

static func apply(decision: Dictionary, rules: RulesSession, board: BoardState) -> Dictionary:
	if decision.get("decision_version") != DirectorRuntime.DECISION_VERSION or not decision.get("proposal") is Dictionary:
		return {"accepted": false, "reason": "malformed_director_proposal", "authority": "none", "downstream_revision": -1}
	var proposal: Dictionary = decision.proposal
	var rules_before: Dictionary = rules.to_snapshot()
	var board_before: Dictionary = board.to_snapshot()
	var result: Dictionary
	var authority: String = "none"
	match proposal.get("type", ""):
		"no_op":
			result = {"accepted": true, "reason": "intentional_no_op"}
		"queue_event":
			authority = "RulesSession"
			result = rules.queue_event(proposal.get("event_id", ""))
		"rules_effects":
			authority = "RulesSession"
			var effects: Array = proposal.get("effects", []).duplicate(true)
			var target_seat: int = decision.get("target_seat", 0)
			for effect: Dictionary in effects:
				if target_seat > 0 and not effect.has("seat") and effect.get("type", "") in ["add_item", "remove_item", "draw_card", "grant_card"]:
					effect["seat"] = target_seat
			result = rules.apply_effect_bundle(effects, target_seat, "director_proposal")
		"board_mutation":
			authority = "BoardState"
			result = board.apply_mutation(proposal.get("mutation", {}), 0)
		"presentation":
			authority = "Presentation"
			result = {"accepted": true, "reason": "presentation_cue_accepted", "presentation": proposal.duplicate(true)}
		_:
			result = {"accepted": false, "reason": "unsupported_director_proposal"}
	if not result.get("accepted", false):
		if rules.to_snapshot() != rules_before or board.to_snapshot() != board_before:
			return {"accepted": false, "reason": "rejected_proposal_changed_state", "authority": authority, "downstream_revision": -1}
	return {
		"accepted": result.get("accepted", false),
		"reason": result.get("reason", "accepted" if result.get("accepted", false) else "rejected"),
		"authority": authority,
		"downstream_revision": board.revision if authority == "BoardState" else rules.history().size() if authority == "RulesSession" else -1,
		"presentation": result.get("presentation", {}),
		"core_rng_before": rules_before.rng.counter,
		"core_rng_after": rules.rng.counter,
	}
