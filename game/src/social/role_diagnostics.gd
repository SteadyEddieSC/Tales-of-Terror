class_name RoleDiagnostics
extends Control


class SessionProjection:
	extends RefCounted

	var content: SocialContent
	var seat_states: Dictionary
	var requested_mode_id: String
	var mode_id: String
	var revision: int
	var fallback_applied: bool
	var fallback_message: String
	var public_history: Array[Dictionary]
	var last_host_payloads: Array[Dictionary]
	var resolved_outcome: Dictionary
	var assignment_count: int
	var rng: DeterministicRng
	var transition_counts: Dictionary
	var action_step: int
	var audit_history: Array[Dictionary]
	var last_rejection: String
	var _source: Object
	var _view_version: int
	var _seat_numerals: PackedStringArray
	var _seat_shapes: PackedStringArray
	var _unknown_label: String

	func _init(
		source: Object,
		view_version: int,
		seat_numerals: PackedStringArray,
		seat_shapes: PackedStringArray,
		unknown_label: String
	) -> void:
		_source = source
		_view_version = view_version
		_seat_numerals = seat_numerals
		_seat_shapes = seat_shapes
		_unknown_label = unknown_label
		content = source.content
		seat_states = source.seat_states
		requested_mode_id = source.requested_mode_id
		mode_id = source.mode_id
		revision = source.revision
		fallback_applied = source.fallback_applied
		fallback_message = source.fallback_message
		public_history = source.public_history
		last_host_payloads = source.last_host_payloads
		resolved_outcome = source.resolved_outcome
		assignment_count = source.assignment_count
		rng = source.rng
		transition_counts = source._transition_counts
		action_step = source._action_step
		audit_history = source.audit_history
		last_rejection = source.last_rejection

	func public_view() -> Dictionary:
		var selected_mode: Dictionary = content.mode_by_id(mode_id)
		var seats: Array[Dictionary] = []
		for seat_number: int in sorted_seats():
			seats.append(_public_seat_view(seat_number))
		return json_copy(
			{
				"view_version": _view_version,
				"view_kind": "public_shared_screen",
				"scenario_label": "Lantern House Social Horror Lab",
				"mode_label": selected_mode.get("label", "Unavailable"),
				"revision": revision,
				"fallback_active": fallback_applied,
				"fallback_message": fallback_message,
				"privacy_notice": "PUBLIC TV VIEW â€” no panel on this screen is private.",
				"afterlife_notice":
				(
					"Afterlife enabled: defeat preserves meaningful legal participation."
					if selected_mode.get("afterlife_enabled", true)
					else "WARNING BEFORE PLAY: afterlife is disabled by this authored mode."
				),
				"seats": seats,
				"public_history": public_history.duplicate(true),
				"host_payloads": last_host_payloads.duplicate(true),
				"outcome": resolved_outcome.get("public", {}).duplicate(true),
			}
		)

	func seat_private_view(seat_number: int) -> Dictionary:
		if not seat_states.has(seat_number):
			return {"accepted": false, "reason": "seat_not_authorized", "view_kind": "seat_private"}
		var state: Dictionary = seat_states[seat_number]
		var role: Dictionary = content.role_by_id(state.form_id)
		var faction: Dictionary = content.faction_by_id(state.faction_id)
		var private_objectives: Array[Dictionary] = []
		for objective_id: String in state.objective_refs:
			var objective: Dictionary = content.objective_by_id(objective_id)
			(
				private_objectives
				. append(
					{
						"objective_id": objective.id,
						"label": objective.label,
						"description": objective.description,
						"visibility": objective.visibility,
					}
				)
			)
		var private_actions: Array[Dictionary] = []
		for action_id: String in role.get("action_refs", []):
			var action: Dictionary = content.action_by_id(action_id)
			(
				private_actions
				. append(
					{
						"action_id": action.id,
						"label": action.label,
						"description": action.description,
						"symbol": action.symbol,
						"uses": state.uses.get(action.id, 0),
					}
				)
			)
		return json_copy(
			{
				"accepted": true,
				"view_version": _view_version,
				"view_kind": "seat_private",
				"authorized_seat": seat_number,
				"shared_screen_warning":
				(
					(
						"OBSCURE THE SHARED SCREEN. Authorize only Seat %s. Companion views use "
						+ "the same stable-seat privacy boundary."
					)
					% roman(seat_number)
				),
				"public": public_view(),
				"private":
				{
					"role_id": role.id,
					"role_label": role.label,
					"role_description": role.description,
					"form_id": state.form_id,
					"faction_id": faction.id,
					"faction_label": faction.label,
					"objectives": private_objectives,
					"actions": private_actions,
					"acknowledged": state.acknowledged,
					"pending_prompts": state.pending_private_prompts.duplicate(true),
				},
			}
		)

	func faction_private_view(requester_seat: int) -> Dictionary:
		if not seat_states.has(requester_seat):
			return {
				"accepted": false,
				"reason": "seat_not_authorized",
				"view_kind": "faction_private",
			}
		var requester: Dictionary = seat_states[requester_seat]
		var faction: Dictionary = content.faction_by_id(requester.faction_id)
		if not faction.get("communication_allowed", false):
			return {
				"accepted": false,
				"reason": "faction_view_not_authorized",
				"view_kind": "faction_private",
			}
		var members: Array[Dictionary] = []
		for seat_number: int in sorted_seats():
			var state: Dictionary = seat_states[seat_number]
			if state.faction_id != requester.faction_id:
				continue
			var role: Dictionary = content.role_by_id(state.form_id)
			(
				members
				. append(
					{
						"seat": seat_number,
						"role_id": role.id,
						"role_label": role.label,
						"lifecycle": state.lifecycle,
					}
				)
			)
		return json_copy(
			{
				"accepted": true,
				"view_version": _view_version,
				"view_kind": "faction_private",
				"authorized_seat": requester_seat,
				"faction_id": faction.id,
				"faction_label": faction.label,
				"members": members,
				"policy": "Authored faction communication only; no unrelated seats are included.",
			}
		)

	func diagnostics_view(spoilers_enabled: bool = false) -> Dictionary:
		if not spoilers_enabled:
			return {
				"accepted": false,
				"reason": "spoiler_diagnostics_disabled",
				"view_kind": "diagnostics",
			}
		var private_previews: Array[Dictionary] = []
		var transition_eligibility: Array[Dictionary] = []
		for seat_number: int in sorted_seats():
			private_previews.append(
				{"seat": seat_number, "preview": seat_private_view(seat_number)}
			)
			var available: Array[Dictionary] = []
			var state: Dictionary = seat_states[seat_number]
			var role: Dictionary = content.role_by_id(state.form_id)
			for transition_id: String in role.get("transition_refs", []):
				var transition: Dictionary = content.transition_by_id(transition_id)
				var eligibility: Dictionary = _source.call(
					"_validate_transition_request",
					seat_number,
					transition_id,
					transition.trigger,
					seat_states
				)
				(
					available
					. append(
						{
							"transition_id": transition.id,
							"label": transition.label,
							"trigger": transition.trigger,
							"eligible": eligibility.accepted,
							"reason": eligibility.get("reason", ""),
						}
					)
				)
			(
				transition_eligibility
				. append(
					{
						"seat": seat_number,
						"transitions": available,
						"legal_actions": _source.call("legal_actions", seat_number),
					}
				)
			)
		return json_copy(
			{
				"accepted": true,
				"view_version": _view_version,
				"view_kind": "spoiler_diagnostics",
				"warning": "SPOILER DIAGNOSTICS â€” NEVER PLAYER-FACING",
				"scenario_id": content.scenario_id,
				"scenario_version": content.scenario_version,
				"requested_mode_id": requested_mode_id,
				"mode_id": mode_id,
				"revision": revision,
				"assignment_count": assignment_count,
				"rng": rng.to_snapshot(),
				"seat_states": seat_state_rows(),
				"transition_counts": transition_counts,
				"action_step": action_step,
				"audit_history": audit_history,
				"last_rejection": last_rejection,
				"public_preview": public_view(),
				"seat_private_previews": private_previews,
				"transition_eligibility": transition_eligibility,
				"privacy_evaluation": privacy_report(),
				"director_safe_signals": director_safe_signals(),
				"resolved_outcome": resolved_outcome,
			}
		)

	func director_safe_signals() -> Dictionary:
		var mode: Dictionary = content.mode_by_id(mode_id)
		var allowlist: Array = mode.get("director_signal_allowlist", [])
		var revealed_factions: Dictionary = {}
		var revealed_counts: Dictionary = {}
		var revealed_total: int = 0
		var defeated_count: int = 0
		var restless_count: int = 0
		var conversion_count: int = 0
		var afterlife_support: int = 0
		for seat_number: int in sorted_seats():
			var state: Dictionary = seat_states[seat_number]
			var role: Dictionary = content.role_by_id(state.form_id)
			if state.revealed:
				revealed_factions[state.faction_id] = true
				revealed_counts[state.faction_id] = revealed_counts.get(state.faction_id, 0) + 1
				revealed_total += 1
			if state.defeated:
				defeated_count += 1
			if role.get("tags", []).has("afterlife"):
				restless_count += 1
				if state.connected:
					for action_id: String in role.get("action_refs", []):
						if content.action_by_id(action_id).get("tags", []).has("afterlife_support"):
							afterlife_support += 1
			if state.revealed and state.transformed:
				conversion_count += 1
		var imbalance: int = 0
		if not revealed_counts.is_empty():
			var counts: Array = revealed_counts.values()
			imbalance = counts.max() - counts.min()
		var candidates: Dictionary = {
			"revealed_faction_count": revealed_factions.size(),
			"public_hostility": clampi(maxi(0, revealed_factions.size() - 1) * 20, 0, 100),
			"defeated_count": defeated_count,
			"restless_count": restless_count,
			"public_conversion_pressure":
			_normalized_percentage(conversion_count, seat_states.size()),
			"revealed_imbalance": _normalized_percentage(imbalance, revealed_total),
			"social_choice_pressure": 0,
			"afterlife_support_available": afterlife_support,
		}
		var result: Dictionary = {}
		for signal_name: String in allowlist:
			if candidates.has(signal_name):
				result[signal_name] = clampi(int(candidates[signal_name]), 0, 100)
		return json_copy(result)

	func privacy_report() -> Dictionary:
		var public_json: String = JSON.stringify(public_view())
		var director_json: String = JSON.stringify(director_safe_signals())
		var leaked: Array[String] = []
		var unauthorized_private_leaks: Array[String] = []
		for owner_seat: int in sorted_seats():
			var state: Dictionary = seat_states[owner_seat]
			if state.revealed:
				continue
			var role: Dictionary = content.role_by_id(state.form_id)
			var faction: Dictionary = content.faction_by_id(state.faction_id)
			var secrets: Array[String] = [role.id, state.form_id, faction.id, role.description]
			for objective_id: String in state.objective_refs:
				var objective: Dictionary = content.objective_by_id(objective_id)
				if objective.visibility != "public":
					secrets.append(objective.id)
					secrets.append(objective.description)
			for secret: String in secrets:
				if not secret.is_empty() and (secret in public_json or secret in director_json):
					leaked.append(secret)
				for viewer_seat: int in sorted_seats():
					if viewer_seat == owner_seat:
						continue
					var viewer_json: String = JSON.stringify(seat_private_view(viewer_seat))
					if not secret.is_empty() and secret in viewer_json:
						unauthorized_private_leaks.append("seat_%d:%s" % [viewer_seat, secret])
		return {
			"passed": leaked.is_empty() and unauthorized_private_leaks.is_empty(),
			"public_or_director_leaks": leaked,
			"unauthorized_seat_leaks": unauthorized_private_leaks,
		}

	func _normalized_percentage(numerator: int, denominator: int) -> int:
		if denominator <= 0:
			return 0
		return clampi(roundi(float(numerator) / float(denominator) * 100.0), 0, 100)

	func evaluate_outcomes(rules: RulesSession = null, board: BoardState = null) -> Dictionary:
		var seat_results: Array[Dictionary] = []
		var public_seats: Array[Dictionary] = []
		var faction_buckets: Dictionary = {}
		for seat_number: int in sorted_seats():
			var state: Dictionary = seat_states[seat_number]
			var evaluations: Array[Dictionary] = []
			for objective_id: String in state.objective_refs:
				var objective: Dictionary = content.objective_by_id(objective_id)
				var complete: bool = _source.call(
					"_conditions_match",
					objective.get("conditions", []),
					seat_number,
					state.faction_id,
					rules,
					board
				)
				var partial: bool = (
					not complete
					and not objective.get("partial_conditions", []).is_empty()
					and _source.call(
						"_conditions_match",
						objective.partial_conditions,
						seat_number,
						state.faction_id,
						rules,
						board
					)
				)
				(
					evaluations
					. append(
						{
							"objective_id": objective.id,
							"label": objective.label,
							"visibility": objective.visibility,
							"complete": complete,
							"partial": partial,
							"result": objective.result,
							"priority": objective.priority,
							"reveal_at_end": objective.reveal_at_end,
							"epilogue_tags": objective.epilogue_tags,
						}
					)
				)
			var result: String = "defeat"
			var winning_priority: int = -1
			for evaluation: Dictionary in evaluations:
				if evaluation.complete and evaluation.priority > winning_priority:
					result = evaluation.result
					winning_priority = evaluation.priority
				elif evaluation.partial and winning_priority < 0:
					result = "partial"
			var seat_record: Dictionary = {
				"seat": seat_number,
				"faction_id": state.faction_id,
				"form_id": state.form_id,
				"result": result,
				"objectives": evaluations,
			}
			seat_results.append(seat_record)
			var public_objectives: Array[String] = []
			for evaluation: Dictionary in evaluations:
				if evaluation.visibility == "public" or evaluation.reveal_at_end:
					(
						public_objectives
						. append(
							(
								"%s: %s"
								% [
									evaluation.label,
									(
										"complete"
										if evaluation.complete
										else "partial" if evaluation.partial else "incomplete"
									),
								]
							)
						)
					)
			(
				public_seats
				. append(
					{
						"seat": seat_number,
						"numeral": roman(seat_number),
						"result": result,
						"objectives": public_objectives,
					}
				)
			)
			if not faction_buckets.has(state.faction_id):
				faction_buckets[state.faction_id] = []
			faction_buckets[state.faction_id].append(result)
		var faction_results: Array[Dictionary] = []
		var public_factions: Array[Dictionary] = []
		for faction_id: String in faction_buckets:
			var faction: Dictionary = content.faction_by_id(faction_id)
			var values: Array = faction_buckets[faction_id]
			var winners: int = (
				values.count("victory")
				+ values.count("changed")
				+ values.count("restless")
				+ values.count("escaped")
			)
			var result: String = (
				"victory" if winners > 0 else "partial" if values.has("partial") else "defeat"
			)
			(
				faction_results
				. append(
					{
						"faction_id": faction_id,
						"label": faction.label,
						"result": result,
						"seat_results": values,
					}
				)
			)
			(
				public_factions
				. append(
					{
						"label": faction.label,
						"symbol": faction.symbol,
						"pattern": faction.pattern,
						"result": result,
					}
				)
			)
		return json_copy(
			{
				"outcome_version": 1,
				"policy": content.mode_by_id(mode_id).get("terminal_policy", {}),
				"private": {"seats": seat_results, "factions": faction_results},
				"public":
				{
					"summary":
					"Multiple faction and individual results resolved deterministically.",
					"seats": public_seats,
					"factions": public_factions,
				},
			}
		)

	func _public_seat_view(seat_number: int) -> Dictionary:
		var state: Dictionary = seat_states[seat_number]
		var role: Dictionary = content.role_by_id(state.form_id)
		var faction: Dictionary = content.faction_by_id(state.faction_id)
		var identity: Dictionary = {
			"label": role.label,
			"symbol": role.symbol,
			"pattern": role.pattern,
			"description": role.description,
		}
		if not state.revealed:
			identity = (
				role
				. get(
					"public_cover",
					{
						"label": "Unknown",
						"symbol": "?",
						"pattern": "closed crosshatch",
						"description": "Unknown",
					}
				)
				. duplicate(true)
			)
		var faction_public: bool = (
			state.revealed or faction.get("membership_policy", "hidden") == "public"
		)
		var objectives: Array[String] = []
		for objective_id: String in state.objective_refs:
			var objective: Dictionary = content.objective_by_id(objective_id)
			if objective.visibility == "public":
				objectives.append(objective.label)
		var actions: Array[String] = []
		var legal_action_values: Variant = _source.call("legal_actions", seat_number)
		for action: Dictionary in legal_action_values:
			if action.visibility == "public":
				actions.append("%s %s" % [action.symbol, action.label])
		return {
			"seat": seat_number,
			"numeral": roman(seat_number),
			"shape": _seat_shapes[seat_number - 1],
			"count_pattern": "mark x%d" % seat_number,
			"connection": "CONNECTED" if state.connected else "DISCONNECTED â€” RESERVED",
			"connection_symbol": "â—" if state.connected else "Ã—",
			"identity_label": identity.label,
			"identity_symbol": identity.symbol,
			"identity_pattern": identity.pattern,
			"faction_label": faction.label if faction_public else _unknown_label,
			"faction_symbol": faction.symbol if faction_public else "?",
			"lifecycle": state.lifecycle.capitalize(),
			"status": _public_status(state),
			"objectives": objectives,
			"legal_actions": actions,
		}

	func _public_status(state: Dictionary) -> String:
		var status: String = "UNKNOWN / HIDDEN"
		if not state.connected:
			status = "DISCONNECTED / RESERVED"
		elif state.lifecycle == "afterlife":
			status = "RESTLESS / ACTIVE AFTERLIFE"
		elif state.lifecycle == "defeated" or state.defeated:
			status = "DEFEATED"
		elif state.lifecycle == "transformed" or state.transformed:
			status = "TRANSFORMED"
		elif state.lifecycle == "replacement":
			status = "REPLACEMENT"
		elif state.lifecycle == "escaped" or state.escaped:
			status = "ESCAPED"
		elif state.revealed:
			status = "REVEALED"
		return status

	func seat_state_rows() -> Array[Dictionary]:
		var rows: Array[Dictionary] = []
		for seat_number: int in sorted_seats():
			rows.append({"seat": seat_number, "state": seat_states[seat_number].duplicate(true)})
		return rows

	func sorted_seats() -> Array[int]:
		var result: Array[int] = []
		for key: Variant in seat_states.keys():
			result.append(int(key))
		result.sort()
		return result

	func roman(seat_number: int) -> String:
		return _seat_numerals[clampi(seat_number - 1, 0, _seat_numerals.size() - 1)]

	static func public_history_type(type: String) -> String:
		var public_type: String = "social_update"
		match type:
			"assignment":
				public_type = "roles_prepared"
			"private_acknowledgement":
				public_type = "private_step_complete"
			"connection":
				public_type = "seat_connection"
			"transition":
				public_type = "social_transition"
			"action":
				public_type = "social_action"
			"outcome":
				public_type = "outcome_resolved"
		return public_type

	static func json_copy(value: Variant) -> Variant:
		return _normalize_json_numbers(JSON.parse_string(JSON.stringify(value)))

	static func _normalize_json_numbers(value: Variant) -> Variant:
		if value is float and is_equal_approx(value, round(value)):
			return int(value)
		if value is Array:
			var array: Array = []
			for item: Variant in value:
				array.append(_normalize_json_numbers(item))
			return array
		if value is Dictionary:
			var dictionary: Dictionary = {}
			for key: Variant in value:
				dictionary[key] = _normalize_json_numbers(value[key])
			return dictionary
		return value


const PAGE_COUNT: int = 3
const PANEL_SIZE := Vector2(840, 410)
const ROLE_SNAPSHOT_VERSION: int = 1
const SEAT_NUMERALS: PackedStringArray = ["I", "II", "III", "IV"]

var _panel: Panel
var _title: Label
var _body: Label
var _footer: Label
var _safe_margin: int = 24
var _page: int = 0
var _pages: Array[String] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.01, 0.01, 0.018, 0.94)
	add_child(backdrop)
	_panel = Panel.new()
	_panel.theme_type_variation = "SeatCardWarning"
	add_child(_panel)
	_title = Label.new()
	_title.position = Vector2(18, 12)
	_title.theme_type_variation = "SectionTitle"
	_panel.add_child(_title)
	_body = Label.new()
	_body.position = Vector2(18, 50)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.clip_text = true
	_body.max_lines_visible = 25
	_panel.add_child(_body)
	_footer = Label.new()
	_footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_footer.modulate = Color(1.0, 0.67, 0.45)
	_panel.add_child(_footer)
	visible = false
	_layout()


func set_safe_margin(value: int) -> void:
	_safe_margin = clampi(value, 0, 48)
	_layout()


func present(session: SocialContent.SessionContract, page: int = 0) -> void:
	var diagnostics: Dictionary = session.diagnostics_view(true)
	_pages = [_assignment_page(diagnostics), _seat_page(diagnostics), _privacy_page(diagnostics)]
	_page = posmod(page, PAGE_COUNT)
	_refresh()
	visible = true


func next_page(direction: int = 1) -> void:
	if _pages.is_empty():
		return
	_page = posmod(_page + direction, _pages.size())
	_refresh()


func rendered_text() -> String:
	return _body.text if is_instance_valid(_body) else ""


func _assignment_page(diagnostics: Dictionary) -> String:
	var lines := PackedStringArray(
		[
			(
				"CONTENT %s v%d  •  MODE %s  •  SNAPSHOT v%d"
				% [
					diagnostics.scenario_id,
					diagnostics.scenario_version,
					diagnostics.mode_id,
					ROLE_SNAPSHOT_VERSION
				]
			),
			(
				"ROLE RNG seed=%d state=%d counter=%d  •  revision=%d"
				% [
					diagnostics.rng.initial_seed,
					diagnostics.rng.state,
					diagnostics.rng.counter,
					diagnostics.revision
				]
			),
			"Assignment plan and bounded audit are complete spoiler state.",
		]
	)
	for entry: Dictionary in diagnostics.audit_history.slice(
		maxi(0, diagnostics.audit_history.size() - 8)
	):
		lines.append(
			(
				"#%d r%d %s  %s"
				% [entry.sequence, entry.revision, entry.type, JSON.stringify(entry.private)]
			)
		)
	return "\n".join(lines)


func _seat_page(diagnostics: Dictionary) -> String:
	var lines := PackedStringArray(["COMPLETE SEAT ROLE / FACTION / FORM / OBJECTIVE / USE STATE"])
	for row: Dictionary in diagnostics.seat_states:
		var state: Dictionary = row.state
		lines.append(
			(
				"Seat %s  role=%s  form=%s  faction=%s"
				% [
					SEAT_NUMERALS[row.seat - 1],
					state.assigned_role_id,
					state.form_id,
					state.faction_id
				]
			)
		)
		lines.append(
			(
				"  life=%s reveal=%s defeat=%s connected=%s objectives=%s uses=%s"
				% [
					state.lifecycle,
					state.revealed,
					state.defeated,
					state.connected,
					state.objective_refs,
					state.uses
				]
			)
		)
	return "\n".join(lines)


func _privacy_page(diagnostics: Dictionary) -> String:
	var report: Dictionary = diagnostics.privacy_evaluation
	return (
		"\n"
		. join(
			PackedStringArray(
				[
					"PUBLIC / PRIVATE / DIRECTOR LEAK EVALUATION",
					(
						"passed=%s  public_or_director_leaks=%s"
						% [report.passed, report.public_or_director_leaks]
					),
					"unauthorized_seat_leaks=%s" % [report.unauthorized_seat_leaks],
					(
						"Director-safe allowlisted aggregate output: %s"
						% JSON.stringify(diagnostics.director_safe_signals)
					),
					"Public preview: %s" % JSON.stringify(diagnostics.public_preview),
					(
						"Raw IDs, RNG, hidden objectives, causes, and private payloads stay on "
						+ "this spoiler-only surface."
					),
				]
			)
		)
	)


func _refresh() -> void:
	_title.text = "SPOILER DIAGNOSTICS — NOT PLAYER HUD  •  PAGE %d/%d" % [_page + 1, PAGE_COUNT]
	_body.text = _pages[_page]
	_footer.text = "DETERMINISTIC PAGING  •  LEFT/RIGHT CHANGE PAGE  •  T CLOSE"


func _layout() -> void:
	if not is_instance_valid(_panel):
		return
	var panel_rect: Rect2 = calculate_panel_rect(Vector2(960, 540), _safe_margin)
	_panel.position = panel_rect.position
	_panel.size = panel_rect.size
	_title.size = Vector2(panel_rect.size.x - 36.0, 30)
	_body.size = Vector2(panel_rect.size.x - 36.0, panel_rect.size.y - 104.0)
	_footer.position = Vector2(18, panel_rect.size.y - 38.0)
	_footer.size = Vector2(panel_rect.size.x - 36.0, 28)


static func calculate_panel_rect(viewport_size: Vector2, safe_margin: int) -> Rect2:
	var safe := Rect2(
		Vector2(safe_margin, safe_margin), viewport_size - Vector2(safe_margin, safe_margin) * 2.0
	)
	var desired := Vector2(
		minf(PANEL_SIZE.x, safe.size.x - 20.0), minf(PANEL_SIZE.y, safe.size.y - 20.0)
	)
	return Rect2(safe.position + (safe.size - desired) * 0.5, desired)
