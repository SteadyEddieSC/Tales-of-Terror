class_name PlaytestReport
extends RefCounted

const SCHEMA_VERSION: int = 2
const MAX_LIFECYCLE_EVENTS: int = 64
const MAX_SEAT_EVENTS: int = 64
const MAX_RECOVERY_EVENTS: int = 64
const MAX_WAIT_EVENTS: int = 64
const MAX_REJECTIONS: int = 32
const MAX_STAGE_DURATIONS: int = 8
const MAX_FEEDBACK_NOTES: int = 1000
const REPORT_KEYS: PackedStringArray = [
	"schema_version",
	"release",
	"scenario",
	"session",
	"lifecycle_events",
	"seat_events",
	"recovery_events",
	"wait_progress",
	"rejections",
	"stage_durations",
	"outcome",
	"tester_feedback",
]
const SCENARIO_KEYS: PackedStringArray = ["id", "version"]
const SESSION_KEYS: PackedStringArray = [
	"seed",
	"seat_count",
	"mode",
	"fallback_applied",
	"companion_used",
	"started_at_utc",
	"ended_at_utc",
	"completion_reason",
	"post_ending_disposition",
]
const OUTCOME_KEYS: PackedStringArray = [
	"terminal_reason", "authority_digest", "public_history_digest"
]
const FEEDBACK_KEYS: PackedStringArray = ["rating", "notes"]
const COMPLETION_REASONS: PackedStringArray = ["ending", "reset"]
const POST_ENDING_DISPOSITIONS: PackedStringArray = [
	"pending", "rematch", "return_to_title", "reset", "not_applicable"
]
const LIFECYCLES: PackedStringArray = [
	"boot_title", "lobby", "confirmation", "briefing", "active_tale", "terminal", "ending"
]
const SEAT_EVENT_TYPES: PackedStringArray = ["join", "disconnect", "reconnect", "leave"]
const RECOVERY_EVENT_TYPES: PackedStringArray = ["pause", "resume", "companion_connected"]
const REJECTION_CATEGORIES: PackedStringArray = [
	"lifecycle", "authorization", "input", "manifest", "authority", "unknown"
]

var _report: Dictionary = {}
var _last_lifecycle: String = ""
var _last_stage_id: String = ""
var _last_stage_started: int = 0
var _last_wait_signature: String = ""
var _last_paused: bool = false
var _previous_seats: Dictionary = {}
var _sequence: int = 0
var _finalized: bool = false


func begin(
	public_state: Dictionary, seed: int, started_at_utc: String, elapsed_seconds: int
) -> void:
	_report = {
		"schema_version": SCHEMA_VERSION,
		"release": release_id(),
		"scenario":
		{
			"id": _bounded(public_state.get("scenario_id", "unknown"), 80),
			"version": maxi(public_state.get("scenario_version", 0), 0),
		},
		"session":
		{
			"seed": seed,
			"seat_count": clampi(public_state.get("seat_count", 0), 0, 8),
			"mode": _bounded(public_state.get("mode", ""), 80),
			"fallback_applied": public_state.get("fallback_applied", false),
			"companion_used": false,
			"started_at_utc": _bounded(started_at_utc, 40),
			"ended_at_utc": "",
			"completion_reason": "",
			"post_ending_disposition": "",
		},
		"lifecycle_events": [],
		"seat_events": [],
		"recovery_events": [],
		"wait_progress": [],
		"rejections": [],
		"stage_durations": [],
		"outcome":
		{
			"terminal_reason": "",
			"authority_digest": "",
			"public_history_digest": "",
		},
		"tester_feedback": {"rating": 0, "notes": ""},
	}
	_last_lifecycle = ""
	_last_stage_id = ""
	_last_stage_started = maxi(elapsed_seconds, 0)
	_last_wait_signature = ""
	_last_paused = false
	_previous_seats.clear()
	_sequence = 0
	_finalized = false
	observe(public_state, [], {}, elapsed_seconds)


func observe(
	public_state: Dictionary,
	seats: Array[Dictionary],
	companion_status: Dictionary,
	elapsed_seconds: int
) -> void:
	if _report.is_empty() or _finalized:
		return
	var elapsed: int = maxi(elapsed_seconds, 0)
	_observe_lifecycle(public_state, elapsed)
	_observe_stage(public_state, elapsed)
	_observe_pause(public_state, elapsed)
	_observe_seats(seats, elapsed)
	_observe_wait(public_state, elapsed)
	var scenario_version: int = public_state.get("scenario_version", 0)
	if scenario_version > 0:
		_report.scenario = {
			"id": _bounded(public_state.get("scenario_id", "unknown"), 80),
			"version": scenario_version,
		}
	if companion_status.get("connected_count", 0) > 0 and not _report.session.companion_used:
		_report.session.companion_used = true
		_append_bounded(
			"recovery_events",
			{
				"sequence": _next_sequence(),
				"elapsed_seconds": elapsed,
				"event": "companion_connected"
			},
			MAX_RECOVERY_EVENTS,
		)
	_report.session.seat_count = clampi(public_state.get("seat_count", 0), 0, 8)
	_report.session.mode = _bounded(public_state.get("mode", ""), 80)
	_report.session.fallback_applied = public_state.get("fallback_applied", false)


func record_rejection(reason: String, elapsed_seconds: int) -> void:
	if _report.is_empty() or _finalized or reason.is_empty():
		return
	_append_bounded(
		"rejections",
		{
			"sequence": _next_sequence(),
			"elapsed_seconds": maxi(elapsed_seconds, 0),
			"category": _rejection_category(reason),
		},
		MAX_REJECTIONS,
	)


func set_tester_feedback(rating: int, notes: String) -> Dictionary:
	if _report.is_empty() or _finalized:
		return {"accepted": false, "reason": "report_not_editable"}
	if rating < 0 or rating > 5 or notes.length() > MAX_FEEDBACK_NOTES:
		return {"accepted": false, "reason": "invalid_feedback"}
	_report.tester_feedback = {"rating": rating, "notes": notes}
	return {"accepted": true, "reason": ""}


func finalize(
	completion_reason: String,
	public_state: Dictionary,
	ended_at_utc: String,
	elapsed_seconds: int,
	authority_digest: String,
	public_history_digest: String
) -> Dictionary:
	if _report.is_empty() or _finalized:
		return {"accepted": false, "reason": "report_not_active"}
	if not COMPLETION_REASONS.has(completion_reason):
		return {"accepted": false, "reason": "invalid_completion_reason"}
	observe(public_state, [], {}, elapsed_seconds)
	_close_stage(elapsed_seconds)
	_report.session.ended_at_utc = _bounded(ended_at_utc, 40)
	_report.session.completion_reason = completion_reason
	_report.session.post_ending_disposition = (
		"pending" if completion_reason == "ending" else "not_applicable"
	)
	var ending: Dictionary = public_state.get("ending", {})
	_report.outcome = {
		"terminal_reason": _bounded(ending.get("terminal_reason", ""), 120),
		"authority_digest": _digest_or_empty(authority_digest),
		"public_history_digest": _digest_or_empty(public_history_digest),
	}
	_finalized = true
	return {"accepted": true, "reason": ""}


func record_post_ending_disposition(disposition: String) -> Dictionary:
	if not _finalized or _report.is_empty():
		return {"accepted": false, "reason": "report_not_finalized"}
	if _report.session.completion_reason != "ending":
		return {"accepted": false, "reason": "disposition_not_applicable"}
	if not disposition in ["rematch", "return_to_title", "reset"]:
		return {"accepted": false, "reason": "invalid_post_ending_disposition"}
	if _report.session.post_ending_disposition != "pending":
		return {"accepted": false, "reason": "disposition_already_recorded"}
	_report.session.post_ending_disposition = disposition
	return {"accepted": true, "reason": ""}


func is_finalized() -> bool:
	return _finalized


func to_report() -> Dictionary:
	return _report.duplicate(true)


func to_json() -> String:
	return JSON.stringify(_report, "  ") + "\n"


func to_markdown() -> String:
	var session: Dictionary = _report.get("session", {})
	var outcome: Dictionary = _report.get("outcome", {})
	var lines := PackedStringArray(
		[
			"# Terror Turn local playtest report",
			"",
			"- Schema: %d" % _report.get("schema_version", 0),
			"- Release: %s" % _report.get("release", ""),
			(
				"- Scenario: %s v%s"
				% [
					_report.get("scenario", {}).get("id", ""),
					_report.get("scenario", {}).get("version", 0)
				]
			),
			"- Seed: %s" % session.get("seed", 0),
			"- Seats: %s" % session.get("seat_count", 0),
			"- Public mode: %s" % session.get("mode", ""),
			"- Cooperative fallback: %s" % session.get("fallback_applied", false),
			"- Optional companion used: %s" % session.get("companion_used", false),
			"- Started: %s" % session.get("started_at_utc", ""),
			"- Ended: %s" % session.get("ended_at_utc", ""),
			"- Completion: %s" % session.get("completion_reason", ""),
			"- Post-ending disposition: %s" % session.get("post_ending_disposition", ""),
			"",
			"## Public outcome",
			"",
			"- Terminal reason: %s" % outcome.get("terminal_reason", ""),
			"- Authority digest: `%s`" % outcome.get("authority_digest", ""),
			"- Public-history digest: `%s`" % outcome.get("public_history_digest", ""),
			"",
			"## Bounded observations",
			"",
			"- Lifecycle transitions: %d" % _report.get("lifecycle_events", []).size(),
			"- Seat events: %d" % _report.get("seat_events", []).size(),
			"- Recovery events: %d" % _report.get("recovery_events", []).size(),
			"- Prompt/vote progress events: %d" % _report.get("wait_progress", []).size(),
			"- Rejection categories: %d" % _report.get("rejections", []).size(),
			"",
			"This local report contains only approved public and aggregate fields. It was not transmitted.",
		]
	)
	return "\n".join(lines) + "\n"


func export_with(writer: PlaytestReportWriter, basename: String) -> Dictionary:
	if not _finalized:
		return {"accepted": false, "reason": "report_not_finalized"}
	if writer == null:
		return {"accepted": false, "reason": "writer_unavailable"}
	return writer.write_report(basename, to_json(), to_markdown())


static func validate_schema(value: Dictionary) -> Dictionary:
	if not _has_exact_keys(value, REPORT_KEYS):
		return {"accepted": false, "reason": "invalid_report_keys"}
	if value.get("schema_version") != SCHEMA_VERSION or value.get("release") != release_id():
		return {"accepted": false, "reason": "unsupported_report_version"}
	if not _has_exact_keys(value.get("scenario", {}), SCENARIO_KEYS):
		return {"accepted": false, "reason": "invalid_scenario"}
	if not _has_exact_keys(value.get("session", {}), SESSION_KEYS):
		return {"accepted": false, "reason": "invalid_session"}
	if not _has_exact_keys(value.get("outcome", {}), OUTCOME_KEYS):
		return {"accepted": false, "reason": "invalid_outcome"}
	if not _has_exact_keys(value.get("tester_feedback", {}), FEEDBACK_KEYS):
		return {"accepted": false, "reason": "invalid_feedback"}
	if not _valid_scalar_sections(value):
		return {"accepted": false, "reason": "invalid_report_values"}
	var row_contracts: Array[Dictionary] = [
		{
			"key": "lifecycle_events",
			"limit": MAX_LIFECYCLE_EVENTS,
			"keys": ["sequence", "elapsed_seconds", "lifecycle"],
			"kind": "lifecycle",
		},
		{
			"key": "seat_events",
			"limit": MAX_SEAT_EVENTS,
			"keys": ["sequence", "elapsed_seconds", "seat", "event", "input_kind"],
			"kind": "seat",
		},
		{
			"key": "recovery_events",
			"limit": MAX_RECOVERY_EVENTS,
			"keys": ["sequence", "elapsed_seconds", "event"],
			"kind": "recovery",
		},
		{
			"key": "wait_progress",
			"limit": MAX_WAIT_EVENTS,
			"keys":
			[
				"sequence",
				"elapsed_seconds",
				"kind",
				"eligible_count",
				"submitted_count",
				"complete",
			],
			"kind": "wait",
		},
		{
			"key": "rejections",
			"limit": MAX_REJECTIONS,
			"keys": ["sequence", "elapsed_seconds", "category"],
			"kind": "rejection",
		},
		{
			"key": "stage_durations",
			"limit": MAX_STAGE_DURATIONS,
			"keys": ["stage_id", "elapsed_seconds"],
			"kind": "stage",
		},
	]
	for contract: Dictionary in row_contracts:
		if not _valid_rows(value.get(contract.key), contract.keys, contract.limit, contract.kind):
			return {"accepted": false, "reason": "invalid_%s" % contract.key}
	return {"accepted": true, "reason": ""}


static func _valid_scalar_sections(value: Dictionary) -> bool:
	var scenario: Dictionary = value.scenario
	var session: Dictionary = value.session
	var outcome: Dictionary = value.outcome
	var feedback: Dictionary = value.tester_feedback
	return (
		scenario.id is String
		and not scenario.id.is_empty()
		and scenario.id.length() <= 80
		and scenario.version is int
		and scenario.version >= 0
		and session.seed is int
		and session.seat_count is int
		and session.seat_count >= 0
		and session.seat_count <= 8
		and session.mode is String
		and session.mode.length() <= 80
		and session.fallback_applied is bool
		and session.companion_used is bool
		and _valid_bounded_string(session.started_at_utc, 40)
		and _valid_bounded_string(session.ended_at_utc, 40)
		and session.completion_reason in COMPLETION_REASONS
		and session.post_ending_disposition in POST_ENDING_DISPOSITIONS
		and (
			(
				session.completion_reason == "ending"
				and session.post_ending_disposition != "not_applicable"
			)
			or (
				session.completion_reason == "reset"
				and session.post_ending_disposition == "not_applicable"
			)
		)
		and _valid_bounded_string(outcome.terminal_reason, 120)
		and _valid_digest(outcome.authority_digest)
		and _valid_digest(outcome.public_history_digest)
		and feedback.rating is int
		and feedback.rating >= 0
		and feedback.rating <= 5
		and feedback.notes is String
		and feedback.notes.length() <= MAX_FEEDBACK_NOTES
	)


static func _valid_rows(value: Variant, keys: Array, limit: int, kind: String) -> bool:
	if not value is Array or value.size() > limit:
		return false
	var previous_sequence: int = 0
	for row_value: Variant in value:
		if not row_value is Dictionary or not _has_exact_array_keys(row_value, keys):
			return false
		var row: Dictionary = row_value
		if kind != "stage":
			if not row.sequence is int or row.sequence <= previous_sequence:
				return false
			previous_sequence = row.sequence
		if not row.elapsed_seconds is int or row.elapsed_seconds < 0:
			return false
		if not _valid_row_values(row, kind):
			return false
	return true


static func _valid_row_values(row: Dictionary, kind: String) -> bool:
	match kind:
		"lifecycle":
			return row.lifecycle in LIFECYCLES
		"seat":
			return (
				row.seat is int
				and row.seat >= 1
				and row.seat <= 8
				and row.event in SEAT_EVENT_TYPES
				and row.input_kind in ["controller", "keyboard"]
			)
		"recovery":
			return row.event in RECOVERY_EVENT_TYPES
		"wait":
			return (
				row.kind in ["prompt", "vote"]
				and row.eligible_count is int
				and row.eligible_count >= 0
				and row.eligible_count <= 8
				and row.submitted_count is int
				and row.submitted_count >= 0
				and row.submitted_count <= row.eligible_count
				and row.complete is bool
			)
		"rejection":
			return row.category in REJECTION_CATEGORIES
		"stage":
			return _valid_bounded_string(row.stage_id, 80) and not row.stage_id.is_empty()
	return false


static func _valid_bounded_string(value: Variant, limit: int) -> bool:
	return value is String and value.length() <= limit


static func _valid_digest(value: Variant) -> bool:
	return (
		value is String
		and (value.is_empty() or (value.length() == 64 and value.is_valid_hex_number(false)))
	)


static func _has_exact_array_keys(value: Dictionary, expected: Array) -> bool:
	if value.size() != expected.size():
		return false
	for key: String in expected:
		if not value.has(key):
			return false
	return true


func _observe_lifecycle(public_state: Dictionary, elapsed: int) -> void:
	var lifecycle: String = public_state.get("lifecycle", "")
	if lifecycle == _last_lifecycle or not LIFECYCLES.has(lifecycle):
		return
	_last_lifecycle = lifecycle
	_append_bounded(
		"lifecycle_events",
		{"sequence": _next_sequence(), "elapsed_seconds": elapsed, "lifecycle": lifecycle},
		MAX_LIFECYCLE_EVENTS,
	)


func _observe_stage(public_state: Dictionary, elapsed: int) -> void:
	var stage: Dictionary = public_state.get("stage", {})
	var stage_id: String = _bounded(stage.get("id", ""), 80)
	if stage_id == _last_stage_id:
		return
	_close_stage(elapsed)
	_last_stage_id = stage_id
	_last_stage_started = elapsed


func _close_stage(elapsed: int) -> void:
	if _last_stage_id.is_empty():
		return
	_append_bounded(
		"stage_durations",
		{"stage_id": _last_stage_id, "elapsed_seconds": maxi(elapsed - _last_stage_started, 0)},
		MAX_STAGE_DURATIONS,
	)
	_last_stage_id = ""


func _observe_pause(public_state: Dictionary, elapsed: int) -> void:
	var paused: bool = public_state.get("paused", false)
	if paused == _last_paused:
		return
	_last_paused = paused
	_append_bounded(
		"recovery_events",
		{
			"sequence": _next_sequence(),
			"elapsed_seconds": elapsed,
			"event": "pause" if paused else "resume"
		},
		MAX_RECOVERY_EVENTS,
	)


func _observe_seats(seats: Array[Dictionary], elapsed: int) -> void:
	for seat: Dictionary in seats:
		var seat_number: int = clampi(seat.get("seat_number", 0), 0, 8)
		if seat_number == 0:
			continue
		var previous: int = _previous_seats.get(seat_number, SeatManager.SeatState.UNASSIGNED)
		var current: int = seat.get("state", SeatManager.SeatState.UNASSIGNED)
		var event: String = _seat_event(previous, current)
		if not event.is_empty():
			_append_bounded(
				"seat_events",
				{
					"sequence": _next_sequence(),
					"elapsed_seconds": elapsed,
					"seat": seat_number,
					"event": event,
					"input_kind": seat.get("input_kind", "controller"),
				},
				MAX_SEAT_EVENTS,
			)
		_previous_seats[seat_number] = current


func _observe_wait(public_state: Dictionary, elapsed: int) -> void:
	var prompt: Dictionary = public_state.get("rules", {}).get("prompt", {})
	if prompt.is_empty():
		_last_wait_signature = ""
		return
	var statuses: Array = prompt.get("response_status", [])
	var submitted: int = (
		statuses
		. filter(func(status: Dictionary) -> bool: return status.get("submitted", false))
		. size()
	)
	var kind: String = _wait_kind(public_state)
	if not kind in ["prompt", "vote"]:
		kind = "prompt"
	var signature: String = "%s:%d:%d" % [kind, submitted, statuses.size()]
	if signature == _last_wait_signature:
		return
	_last_wait_signature = signature
	_append_bounded(
		"wait_progress",
		{
			"sequence": _next_sequence(),
			"elapsed_seconds": elapsed,
			"kind": kind,
			"eligible_count": clampi(statuses.size(), 0, 8),
			"submitted_count": clampi(submitted, 0, 8),
			"complete": submitted == statuses.size() and not statuses.is_empty(),
		},
		MAX_WAIT_EVENTS,
	)


func _seat_event(previous: int, current: int) -> String:
	if previous == SeatManager.SeatState.UNASSIGNED and current == SeatManager.SeatState.ACTIVE:
		return "join"
	if previous == SeatManager.SeatState.ACTIVE and current == SeatManager.SeatState.DISCONNECTED:
		return "disconnect"
	if previous == SeatManager.SeatState.RESERVED and current == SeatManager.SeatState.ACTIVE:
		return "reconnect"
	if previous != SeatManager.SeatState.UNASSIGNED and current == SeatManager.SeatState.UNASSIGNED:
		return "leave"
	return ""


func _rejection_category(reason: String) -> String:
	if "lifecycle" in reason or "transition" in reason:
		return "lifecycle"
	if "seat" in reason or "authorized" in reason or "owner" in reason:
		return "authorization"
	if "input" in reason or "response" in reason or "selection" in reason:
		return "input"
	if "manifest" in reason or "scenario" in reason or "mode" in reason:
		return "manifest"
	if "board" in reason or "rules" in reason or "director" in reason or "role" in reason:
		return "authority"
	return "unknown"


func _append_bounded(key: String, value: Dictionary, limit: int) -> void:
	var rows: Array = _report[key]
	if rows.size() >= limit:
		rows.pop_front()
	rows.append(value)


func _next_sequence() -> int:
	_sequence += 1
	return _sequence


static func _bounded(value: Variant, limit: int) -> String:
	var text: String = str(value).strip_edges()
	return text.left(limit)


static func _digest_or_empty(value: String) -> String:
	if value.is_empty():
		return ""
	if value.length() != 64 or not value.is_valid_hex_number(false):
		return ""
	return value.to_lower()


static func _has_exact_keys(value: Variant, expected: PackedStringArray) -> bool:
	if not value is Dictionary or value.size() != expected.size():
		return false
	for key: String in expected:
		if not value.has(key):
			return false
	return true


static func _wait_kind(public_state: Dictionary) -> String:
	var operation_index: int = public_state.get("operation_index", 0)
	var operations: Array = public_state.get("stage", {}).get("operations", [])
	if operation_index <= 0 or operation_index > operations.size():
		return "prompt"
	return "vote" if operations[operation_index - 1].get("type") == "submit_vote" else "prompt"


static func release_id() -> String:
	return str(ProjectSettings.get_setting("application/config/version"))
