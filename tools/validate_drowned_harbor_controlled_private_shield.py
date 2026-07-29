#!/usr/bin/env python3
"""Validate the export-excluded P0.17 controlled-private shield proof."""

from __future__ import annotations

import hashlib
import json
import re
import sys
from pathlib import Path
from typing import Any, Iterable

import validate_drowned_harbor_projection_fixtures_p016 as inherited_projection

ROOT = Path(".")
FIXTURE_PATH = Path(
    "game/tests/drowned_harbor_dev_only/state_projection_fixtures_v1.json"
)
SCHEMA_PATH = Path(
    "game/tests/drowned_harbor_dev_only/state_projection_fixture_schema_v1.json"
)
ADAPTER_PATH = Path(
    "game/tests/drowned_harbor_dev_only/controlled_private_fixture_adapter.gd"
)
SURFACE_PATH = Path(
    "game/tests/drowned_harbor_dev_only/controlled_private_surface.gd"
)
SHELL_PATH = Path(
    "game/tests/drowned_harbor_dev_only/controlled_private_shield_shell.gd"
)
SCENE_PATH = Path(
    "game/tests/drowned_harbor_dev_only/controlled_private_shield_shell.tscn"
)
TEST_PATH = Path("game/tests/drowned_harbor_controlled_private_shield_test.gd")
MANIFEST_PATH = Path("game/tests/drowned_harbor_prototype_manifest_v1.json")
CATALOG_PATH = Path("game/data/tales/tale_catalog_v1.json")
PROVIDER_PATH = Path("game/src/session/tale_provider_registry.gd")
EXPORT_PRESETS_PATH = Path("game/export_presets.cfg")
PACKAGE_JSON_PATH = Path("package.json")
PACKAGE_LOCK_PATH = Path("package-lock.json")
CORE_STORYBOARD_PATH = Path(
    "docs/tales/drowned_harbor/ui/drowned_harbor_core_storyboards_v1.json"
)
CONTINUITY_STORYBOARD_PATH = Path(
    "docs/tales/drowned_harbor/ui/"
    "drowned_harbor_continuity_accessibility_storyboards_v1.json"
)
RESOLUTION_TRACE_PATH = Path(
    "docs/tales/drowned_harbor/interaction/"
    "drowned_harbor_interaction_resolution_traces_v1.json"
)
CONTINUITY_TRACE_PATH = Path(
    "docs/tales/drowned_harbor/interaction/"
    "drowned_harbor_interaction_continuity_traces_v1.json"
)
TECHNICAL_PATH = Path(
    "docs/technical/Drowned_Harbor_Controlled_Private_Shield_Proof_v1.md"
)
SUMMARY_PATH = Path("docs/preproduction/P0.17_Release_Summary.md")
README_PATH = Path("game/tests/drowned_harbor_dev_only/README.md")

EXPECTED_CATALOG_DIGEST = (
    "2b478fd0d11fa075c2050409193aa06e"
    "6b9ca4dcf6efd4e4c550a9f3a5ff9db6"
)
EXPECTED_PACKAGE_DIGEST = (
    "abb39d6bfbdf8d7de108379f08180c13"
    "efb99bbffa3e53f30eaaa8de7f459dee"
)
EXPECTED_ENTRY_POINTS = [
    "res://tests/drowned_harbor_low_tide_shell_test.gd",
    "res://tests/drowned_harbor_bellhouse_recovery_test.gd",
    "res://tests/drowned_harbor_controlled_private_shield_test.gd",
    "res://tests/drowned_harbor_prototype_isolation_test.gd",
]
EXPECTED_COMPONENTS = [
    "res://tests/drowned_harbor_dev_only/low_tide_fixture_adapter.gd",
    "res://tests/drowned_harbor_dev_only/low_tide_shared_screen_shell.gd",
    "res://tests/drowned_harbor_dev_only/low_tide_shared_screen_shell.tscn",
    "res://tests/drowned_harbor_dev_only/bellhouse_fixture_adapter.gd",
    "res://tests/drowned_harbor_dev_only/bellhouse_decision_shell.gd",
    "res://tests/drowned_harbor_dev_only/bellhouse_decision_shell.tscn",
    "res://tests/drowned_harbor_dev_only/controlled_private_fixture_adapter.gd",
    "res://tests/drowned_harbor_dev_only/controlled_private_surface.gd",
    "res://tests/drowned_harbor_dev_only/controlled_private_shield_shell.gd",
    "res://tests/drowned_harbor_dev_only/controlled_private_shield_shell.tscn",
]


class ControlledPrivateValidationError(ValueError):
    """Raised when the bounded P0.17 contract is violated."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ControlledPrivateValidationError(message)


def read_json(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise ControlledPrivateValidationError(
            f"required file missing: {path}"
        ) from exc
    except json.JSONDecodeError as exc:
        raise ControlledPrivateValidationError(f"invalid JSON in {path}: {exc}") from exc
    require(isinstance(value, dict), f"JSON root must be an object: {path}")
    return value


def canonical_sha256(value: dict[str, Any]) -> str:
    payload = json.dumps(
        value,
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    ).encode("utf-8")
    return hashlib.sha256(payload).hexdigest()


def fixture_by_id(package: dict[str, Any], fixture_id: str) -> dict[str, Any]:
    fixtures = package.get("fixtures")
    require(isinstance(fixtures, list), "fixture inventory must be an array")
    matches = [
        fixture
        for fixture in fixtures
        if isinstance(fixture, dict) and fixture.get("fixture_id") == fixture_id
    ]
    require(len(matches) == 1, f"{fixture_id} must resolve exactly once")
    return matches[0]


def private_strings(value: Any) -> Iterable[str]:
    if isinstance(value, dict):
        for nested in value.values():
            yield from private_strings(nested)
    elif isinstance(value, list):
        for nested in value:
            yield from private_strings(nested)
    elif isinstance(value, str) and value.startswith("PRIVATE_"):
        yield value


def validate_fixture_package(
    package: dict[str, Any],
    schema: dict[str, Any],
) -> None:
    fixtures = package.get("fixtures")
    require(isinstance(fixtures, list), "fixture inventory must be an array")
    fixture_ids = [fixture.get("fixture_id") for fixture in fixtures]
    require(
        fixture_ids == [f"DH-FIX-{number:03d}" for number in range(1, 8)],
        "fixture inventory must be exactly DH-FIX-001 through DH-FIX-007",
    )
    fixture_schema = schema.get("properties", {}).get("fixtures", {})
    require(
        fixture_schema.get("minItems") == 7
        and fixture_schema.get("maxItems") == 7,
        "fixture schema must require exactly seven entries",
    )
    bargain = fixture_by_id(package, "DH-FIX-003")
    inherited = fixture_by_id(package, "DH-FIX-007")
    validate_private_fixture(
        bargain,
        trace_id="DH-IS-007",
        storyboard_id="DH-UI-007",
        seat_id="seat_03",
        source_revision=31,
        result_revision=32,
        rng_cursor=9,
        intent="project_controlled_private_bargain",
        private_event="harbor_bargain_private_term_committed",
        public_event="harbor_bargain_public_resolution_projected",
    )
    validate_private_fixture(
        inherited,
        trace_id="DH-IS-016",
        storyboard_id="DH-UI-016",
        seat_id="seat_07",
        source_revision=71,
        result_revision=72,
        rng_cursor=21,
        intent="project_inherited_private_state_handoff",
        private_event="inherited_private_state_acknowledged",
        public_event="stable_seat_human_takeover_committed",
    )
    source = inherited.get("source_state", {})
    seat_public = source.get("seat_public", {})
    private = source.get("private", {})
    require(
        seat_public
        == {
            "seat_id": "seat_07",
            "control_source": "game_control",
            "location": "bellhouse_roof",
            "public_form": "living",
            "condition": "injured",
            "health": 2,
            "inventory_count": 1,
            "history_count": 8,
            "ending_identity": "seat_07_existing_ending_identity",
        },
        "DH-FIX-007 evolved public seat state drifted",
    )
    for field in (
        "role",
        "faction",
        "objective",
        "condition",
        "inventory",
        "knowledge",
        "surrogate_recap",
        "obligations",
        "legal_actions",
    ):
        require(field in private, f"DH-FIX-007 private {field} is required")
    diagnostic = source.get("diagnostic_nonplayer", {})
    require(
        diagnostic
        == {
            "fixture_revision": "p0.17",
            "authoring_note": "synthetic only",
            "controller_authority_id": "takeover_controller_authority_07",
            "handoff_id": "dh_inherited_state_handoff_007",
            "handoff_revision": 1,
            "expected_trace_id": "DH-IS-016",
            "valid_until_counter": 6,
        },
        "DH-FIX-007 deterministic handoff metadata drifted",
    )


def validate_private_fixture(
    fixture: dict[str, Any],
    *,
    trace_id: str,
    storyboard_id: str,
    seat_id: str,
    source_revision: int,
    result_revision: int,
    rng_cursor: int,
    intent: str,
    private_event: str,
    public_event: str,
) -> None:
    require(fixture.get("trace_id") == trace_id, f"{fixture.get('fixture_id')} trace drifted")
    require(
        fixture.get("storyboard_id") == storyboard_id,
        f"{fixture.get('fixture_id')} storyboard drifted",
    )
    require(
        fixture.get("fixture_kind") == "controlled_private_commit_projection"
        and fixture.get("privacy_surface") == "controlled_private_surface",
        f"{fixture.get('fixture_id')} controlled-private classification drifted",
    )
    require(
        fixture.get("source_revision") == source_revision
        and fixture.get("result_revision") == result_revision,
        f"{fixture.get('fixture_id')} revisions drifted",
    )
    require(
        fixture.get("rng_cursor_before")
        == fixture.get("rng_cursor_after")
        == rng_cursor,
        f"{fixture.get('fixture_id')} must consume no RNG",
    )
    require(
        fixture.get("stable_seat_identity_before")
        == fixture.get("stable_seat_identity_after")
        == fixture.get("active_stable_seat_id")
        == seat_id,
        f"{fixture.get('fixture_id')} stable-seat continuity drifted",
    )
    request = fixture.get("projection_request", {})
    require(
        request.get("source_revision") == source_revision
        and request.get("stable_seat_id") == seat_id
        and request.get("intent") == intent,
        f"{fixture.get('fixture_id')} request binding drifted",
    )
    projection = fixture.get("projection_map", {})
    public_map = projection.get("public", {})
    private_map = projection.get("private", {})
    require(isinstance(public_map, dict), "controlled-private public map is required")
    require(isinstance(private_map, dict) and private_map, "private map is required")
    require(
        all(
            isinstance(path, str)
            and (path.startswith("public.") or path.startswith("seat_public."))
            for path in public_map.values()
        ),
        "public projection may not read private state",
    )
    require(
        all(
            isinstance(path, str)
            and (path.startswith("private.") or path.startswith("seat_public."))
            for path in private_map.values()
        ),
        "private projection path escaped the controlled surface",
    )
    events = fixture.get("expected_events", [])
    require(isinstance(events, list) and len(events) == 2, "private fixture needs two events")
    event_index = {event.get("event_key"): event for event in events}
    require(
        event_index.get(private_event, {}).get("classification") == "private"
        and event_index.get(private_event, {}).get("exactly_once") is True,
        "private event must remain private and exactly once",
    )
    require(
        event_index.get(public_event, {}).get("classification") == "public"
        and event_index.get(public_event, {}).get("exactly_once") is True,
        "sanitized public event must remain public and exactly once",
    )
    require(
        all(
            not str(path).startswith("private.")
            for path in event_index[public_event].get("payload_map", {}).values()
        ),
        "public event may not read private state",
    )


def record_by_id(document: dict[str, Any], key: str, value: str) -> dict[str, Any]:
    entries = document.get("entries")
    require(isinstance(entries, list), f"{value} source entries are missing")
    matches = [entry for entry in entries if isinstance(entry, dict) and entry.get(key) == value]
    require(len(matches) == 1, f"{value} must resolve exactly once")
    return matches[0]


def validate_governed_sources(root: Path = ROOT) -> None:
    ui_007 = record_by_id(read_json(root / CORE_STORYBOARD_PATH), "storyboard_id", "DH-UI-007")
    ui_016 = record_by_id(
        read_json(root / CONTINUITY_STORYBOARD_PATH),
        "storyboard_id",
        "DH-UI-016",
    )
    is_007 = record_by_id(read_json(root / RESOLUTION_TRACE_PATH), "trace_id", "DH-IS-007")
    is_016 = record_by_id(read_json(root / CONTINUITY_TRACE_PATH), "trace_id", "DH-IS-016")
    require(
        ui_007.get("focus_order", [])[-2:] == ["Confirm", "Refuse"],
        "DH-UI-007 governed focus order drifted",
    )
    require(
        ui_016.get("focus_order", [])[-1] == "Acknowledge",
        "DH-UI-016 governed acknowledgement focus drifted",
    )
    for storyboard in (ui_007, ui_016):
        require(
            storyboard.get("privacy_surface") == "controlled_private_surface"
            and storyboard.get("layout_mode") == "private_shield",
            f"{storyboard.get('storyboard_id')} privacy surface drifted",
        )
        require(
            storyboard.get("focus_order", [""])[0] not in ("Confirm", "Acknowledge"),
            f"{storyboard.get('storyboard_id')} default focus may not confirm",
        )
    for trace in (is_007, is_016):
        require(
            trace.get("privacy_contract", {}).get("neutral_shield_required") is True,
            f"{trace.get('trace_id')} requires a neutral shield",
        )
        require(
            trace.get("commit_contract", {}).get("once_only_transition") is True
            and trace.get("commit_contract", {}).get("confirmation_revision_required")
            is True,
            f"{trace.get('trace_id')} exactly-once revision contract drifted",
        )


def validate_godot_sources_text(
    adapter: str,
    surface: str,
    shell: str,
    test: str,
) -> None:
    adapter_phrases = (
        "class_name DrownedHarborControlledPrivateFixtureAdapter",
        'const BARGAIN_FIXTURE_ID: String = "DH-FIX-003"',
        'const INHERITED_FIXTURE_ID: String = "DH-FIX-007"',
        "neutral_shield_required",
        "stale_source_revision",
        "wrong_stable_seat",
        "wrong_controller_authority",
        "unknown_handoff",
        "malformed_handoff",
        "expired_handoff",
        "private_surface_required",
    )
    for phrase in adapter_phrases:
        require(phrase in adapter, f"controlled-private adapter missing: {phrase}")
    surface_phrases = (
        "class_name DrownedHarborControlledPrivateSurface",
        "func request_acknowledgement() -> Dictionary:",
        "func refuse_private_bargain() -> Dictionary:",
        "func acknowledge(request: Dictionary) -> Dictionary:",
        "func complete_acknowledgement() -> Dictionary:",
        "func clear_private_state() -> void:",
        "_private_payload.clear()",
        "_private_event.clear()",
        "_binding.clear()",
        "_pending_acknowledgement.clear()",
        '_private_caption_request = ""',
        "_private_audio_requests.clear()",
        "acknowledgement_focus_required",
        "refusal_focus_required",
        "expired_handoff",
    )
    for phrase in surface_phrases:
        require(phrase in surface, f"controlled-private surface missing: {phrase}")
    focus_orders: dict[str, list[str]] = {}
    for name in ("BARGAIN_FOCUS_ORDER", "INHERITED_FOCUS_ORDER"):
        match = re.search(
            rf"const {name}: PackedStringArray = \[(.*?)\]",
            surface,
            re.DOTALL,
        )
        require(match is not None, f"{name} is missing")
        focus_orders[name] = re.findall(r'"([^"]+)"', match.group(1))
    require(
        focus_orders["BARGAIN_FOCUS_ORDER"]
        == [
            "private_surface_identity",
            "benefit",
            "cost",
            "affected_seat_state",
            "confirm_private_bargain",
            "refuse_private_bargain",
        ],
        "bargain focus order drifted or defaults to confirmation",
    )
    require(
        focus_orders["INHERITED_FOCUS_ORDER"]
        == [
            "assigned_seat_identity",
            "role_and_faction",
            "objective_and_conditions",
            "inventory_and_knowledge",
            "surrogate_recap",
            "legal_actions",
            "acknowledge_private_state",
        ],
        "inherited-state focus order drifted or defaults to acknowledgement",
    )
    shell_phrases = (
        "class_name DrownedHarborControlledPrivateShieldShell",
        'const NEUTRAL_SHIELD_TEXT: String = "PRIVATE REVIEW IN PROGRESS"',
        'const NEUTRAL_SHIELD_FOCUS: String = "private_review_notice"',
        'const NEUTRAL_SHIELD_COLOR: String = "neutral_shield"',
        'const NEUTRAL_SHIELD_ICON: String = "none"',
        'const NEUTRAL_SHIELD_ANIMATION: String = "none"',
        "neutral_shield_entered_before_private_request",
        "private_payload_requested",
        "private_payload_cleared_before_public_restoration",
        "func restore_public(succeeds: bool = true) -> Dictionary:",
        "func handle_disconnect() -> Dictionary:",
        "func interrupt_presentation() -> Dictionary:",
        "func cancel_or_defer() -> Dictionary:",
        '"production_authority": false',
    )
    for phrase in shell_phrases:
        require(phrase in shell, f"controlled-private shell missing: {phrase}")
    require(shell.count("_commit_count += 1") == 1, "exactly-once commit increment drifted")
    require(
        shell.count("_public_event_count += 1") == 1,
        "aggregate public-event increment drifted",
    )
    require("_commit_count != 0" not in shell, "lifetime-global commit gating is prohibited")
    require(
        "_public_event_count == 0" not in shell,
        "lifetime-global public-event suppression is prohibited",
    )
    begin_handoff = shell[
        shell.index("func begin_handoff(") : shell.index("func navigate_private(")
    ]
    require(
        begin_handoff.index("_enter_neutral_shield()")
        < begin_handoff.index('append("private_payload_requested")'),
        "source lifecycle must enter the neutral shield before private request",
    )
    require(
        "or not _pending_public_result.is_empty()" in begin_handoff,
        "new handoff must remain blocked while public restoration is pending",
    )
    combined_runtime = adapter + surface + shell
    require("timeout" not in combined_runtime.lower(), "timeout authority is prohibited")
    require(
        "not _private_surface.is_cleared()" in shell
        and "not _private_projection_result.is_empty()" in shell,
        "new handoff must reject retained private payload",
    )
    surface_acknowledgement = surface[
        surface.index("func acknowledge(") : surface.index("func complete_acknowledgement(")
    ]
    require(
        "clear_private_state()" not in surface_acknowledgement,
        "surface acknowledgement must validate before application clearing",
    )
    refusal = shell[
        shell.index("func refuse_private_bargain(") : shell.index("func acknowledge(")
    ]
    for phrase in (
        "_private_surface.refuse_private_bargain()",
        "_clear_private_application_state()",
        "explicit_private_bargain_refused_and_cleared",
        "SurfaceMode.PUBLIC_READY",
    ):
        require(phrase in refusal, f"governed refusal path missing: {phrase}")
    require(
        "_commit_count += 1" not in refusal
        and "prototype_private_commit_recorded" not in refusal
        and "prototype_public_event_emitted" not in refusal,
        "governed refusal must not create a private or public event",
    )
    dispatch = shell[shell.index("func dispatch_semantic_action(") : shell.index("func public_snapshot(")]
    require(
        'if _private_surface.focused_item() == "refuse_private_bargain":' in dispatch
        and "result = refuse_private_bargain()" in dispatch,
        "semantic Confirm must route governed Refuse to the refusal path",
    )
    acknowledgement = shell[
        shell.index("func acknowledge(") : shell.index("func restore_public(")
    ]
    for phrase in (
        "_build_event_identity(",
        "_committed_private_event_identities.has(private_event_identity)",
        "_committed_public_event_identities.has(public_event_identity)",
        "_committed_private_event_identities[private_event_identity] = true",
        "_private_surface.complete_acknowledgement()",
    ):
        require(phrase in acknowledgement, f"identity-scoped acknowledgement missing: {phrase}")
    require(
        "_private_surface.clear_private_state()" not in acknowledgement,
        "shell must not clear the surface before duplicate validation",
    )
    require(
        acknowledgement.index("_committed_private_event_identities.has(private_event_identity)")
        < acknowledgement.index("_pending_public_result = {")
        < acknowledgement.index("_committed_private_event_identities[private_event_identity] = true")
        < acknowledgement.index("_private_surface.complete_acknowledgement()")
        < acknowledgement.index("_private_projection_result.clear()")
        < acknowledgement.index("_commit_count += 1")
        < acknowledgement.index("_mode = SurfaceMode.RESTORING"),
        "acknowledgement validation, identity record, clearing, and restore ordering drifted",
    )
    identity_builder = shell[
        shell.index("static func _build_event_identity(") : shell.index(
            "static func _contains_private_marker("
        )
    ]
    for component in (
        "fixture_id",
        "handoff_id",
        "handoff_revision",
        "source_revision",
        "result_revision",
        "event_key",
        "sha256_text()",
    ):
        require(component in identity_builder, f"governed event identity missing: {component}")
    restoration = shell[shell.index("func restore_public(") : shell.index("func cancel_or_defer(")]
    require(
        "if _mode not in [SurfaceMode.RESTORING, SurfaceMode.RECOVERY]:"
        in restoration,
        "public restoration must remain callable from restoring and recovery modes",
    )
    for phrase in (
        "_committed_public_event_identities.has(event_identity)",
        "_committed_public_event_identities[event_identity] = true",
        "_public_event_count += 1",
        "_public_history.append(event.duplicate(true))",
        "_public_replay.append(event.duplicate(true))",
        "prototype_public_event_emitted.emit(event.duplicate(true))",
    ):
        require(phrase in restoration, f"identity-scoped public restoration missing: {phrase}")
    for phrase in (
        "_public_history.append(event.duplicate(true))",
        "_public_replay.append(event.duplicate(true))",
        "prototype_public_event_emitted.emit(event.duplicate(true))",
    ):
        require(
            restoration.count(phrase) == 1,
            f"public restoration exactly-once operation drifted: {phrase}",
        )
    cancel = shell[shell.index("func cancel_or_defer(") : shell.index("func handle_disconnect(")]
    for phrase in (
        "if not _pending_public_result.is_empty():",
        "_clear_private_state_preserving_public_result()",
        "_mode = SurfaceMode.RECOVERY",
        '"code": "public_restoration_pending"',
        "_clear_private_application_state()",
    ):
        require(phrase in cancel, f"mode-aware Cancel path missing: {phrase}")
    require(
        "_pending_public_result.clear()" not in cancel,
        "Cancel must not clear a committed pending public result",
    )
    interruption = shell[
        shell.index("func interrupt_presentation(") : shell.index("func open_help(")
    ]
    for phrase in (
        "if not _pending_public_result.is_empty():",
        "_clear_private_state_preserving_public_result()",
        "_mode = SurfaceMode.RECOVERY",
        "post_commit_interruption_recovery_preserved",
    ):
        require(phrase in interruption, f"post-commit interruption recovery missing: {phrase}")
    require(
        "_pending_public_result.clear()" not in interruption,
        "interruption must not clear a committed pending public result",
    )
    preserving_clear = shell[
        shell.index("func _clear_private_state_preserving_public_result(") : shell.index(
            "func _reject_pending_action("
        )
    ]
    for phrase in (
        "_private_surface.clear_private_state()",
        "_private_projection_result.clear()",
        "_adapter.clear_loaded_fixture()",
    ):
        require(phrase in preserving_clear, f"private-only clearing helper missing: {phrase}")
    require(
        "_pending_public_result" not in preserving_clear,
        "private-only clearing helper must preserve the pending public result",
    )
    public_snapshot = shell[
        shell.index("func public_snapshot(") : shell.index("func private_surface_snapshot(")
    ]
    require(
        "if not _pending_public_result.is_empty():" in public_snapshot
        and 'controller_prompts = "RESTORATION PENDING  |  X / H: HELP"'
        in public_snapshot,
        "post-commit shield must advertise only neutral restoration-pending guidance",
    )
    help_path = shell[shell.index("func open_help(") : shell.index("func dispatch_semantic_action(")]
    require(
        "if not _pending_public_result.is_empty():" in help_path
        and 'guidance = "Public restoration is pending. Retry the governed restoration."'
        in help_path,
        "post-commit Help must not advertise destructive cancellation",
    )
    for prohibited in (
        "Time.get_ticks",
        "Time.get_unix",
        "DateTime",
        "Timer.new",
        "timeout.connect",
        "WebSocketPeer",
        "HTTPRequest",
        "PacketPeerUDP",
        "StreamPeerTCP",
        "restore_inventory",
        "reset_objective",
        "reset_condition",
        "reroll",
        "heal_seat",
    ):
        require(prohibited not in combined_runtime, f"prohibited runtime seam found: {prohibited}")
    for phrase in (
        "_test_bargain_authorized_reveal_and_acknowledgement",
        "_test_governed_bargain_refusal_and_following_handoff",
        "_test_inherited_state_authorized_reveal_and_acknowledgement",
        "_test_shield_is_information_neutral_with_voice_disabled",
        "_test_private_values_never_enter_public_outputs",
        "_test_application_private_state_clears_before_public_restore",
        "_test_sequential_handoffs_and_identity_scoped_exactly_once",
        "_test_post_commit_control_matrix",
        "_exercise_post_commit_control",
        "_test_disconnect_and_reconnect_matrix",
        "_test_public_restoration_failure_recovers_deterministically",
        "_test_production_and_export_boundaries",
    ):
        require(phrase in test, f"P0.17 Godot test missing coverage: {phrase}")


def validate_godot_sources(root: Path, package: dict[str, Any]) -> None:
    for path in (ADAPTER_PATH, SURFACE_PATH, SHELL_PATH, SCENE_PATH, TEST_PATH):
        require((root / path).is_file(), f"required P0.17 component missing: {path}")
        require(path.as_posix().startswith("game/tests/"), f"P0.17 escaped tests: {path}")
    for path in (
        ADAPTER_PATH.with_suffix(".gd.uid"),
        SURFACE_PATH.with_suffix(".gd.uid"),
        SHELL_PATH.with_suffix(".gd.uid"),
        TEST_PATH.with_suffix(".gd.uid"),
    ):
        require((root / path).is_file(), f"Godot UID missing: {path}")
        require(
            re.fullmatch(r"uid://[a-z0-9]{13}", (root / path).read_text().strip())
            is not None,
            f"invalid Godot UID: {path}",
        )
    adapter = (root / ADAPTER_PATH).read_text(encoding="utf-8")
    surface = (root / SURFACE_PATH).read_text(encoding="utf-8")
    shell = (root / SHELL_PATH).read_text(encoding="utf-8")
    test = (root / TEST_PATH).read_text(encoding="utf-8")
    validate_godot_sources_text(adapter, surface, shell, test)
    scene = (root / SCENE_PATH).read_text(encoding="utf-8")
    require(
        'path="res://tests/drowned_harbor_dev_only/'
        'controlled_private_shield_shell.gd"' in scene,
        "P0.17 scene script binding drifted",
    )
    private_values = set(private_strings(fixture_by_id(package, "DH-FIX-003"))) | set(
        private_strings(fixture_by_id(package, "DH-FIX-007"))
    )
    for marker in private_values:
        require(marker not in adapter + surface + shell, f"private value copied into runtime source: {marker}")


def validate_manifest_and_production_boundary(
    manifest: dict[str, Any],
    catalog: dict[str, Any],
    provider: str,
    presets: str,
    package_json: dict[str, Any],
    package_lock: dict[str, Any],
) -> None:
    require(
        manifest.get("completed_work_issues") == [80, 81, 82, 83, 84]
        and manifest.get("future_work_issues") == [85, 86],
        "prototype issue progression must activate only #84",
    )
    require(manifest.get("allowed_entry_points") == EXPECTED_ENTRY_POINTS, "entry points drifted")
    require(manifest.get("prototype_components") == EXPECTED_COMPONENTS, "components drifted")
    require(
        TECHNICAL_PATH.as_posix() in manifest.get("source_authorities", []),
        "P0.17 technical authority is missing",
    )
    for field in (
        "production_catalog_registered",
        "production_provider_registered",
        "normal_tale_library_visible",
        "playable_export_authorized",
        "runtime_authority_created",
        "human_evidence_claimed",
    ):
        require(manifest.get(field) is False, f"manifest {field} must remain false")
    require(canonical_sha256(catalog) == EXPECTED_CATALOG_DIGEST, "catalog digest changed")
    require(
        catalog.get("default_tale_id") == "lantern_house_vertical_slice"
        and len(catalog.get("entries", [])) == 1
        and catalog["entries"][0].get("tale_id") == "lantern_house_vertical_slice",
        "production catalog must remain Lantern House-only",
    )
    require("drowned_harbor" not in json.dumps(catalog).lower(), "Drowned Harbor entered catalog")
    require("drowned_harbor" not in provider.lower(), "Drowned Harbor entered provider")
    require(presets.count("tests/*") == 2, "both ordinary exports must exclude tests/*")
    for filename in (
        ADAPTER_PATH.name,
        SURFACE_PATH.name,
        SHELL_PATH.name,
        SCENE_PATH.name,
        TEST_PATH.name,
    ):
        require(filename not in presets, f"export preset explicitly includes {filename}")
    dependencies = package_json.get("devDependencies", {})
    require(dependencies.get("wrangler") == "4.114.0", "Wrangler direct pin changed")
    require(
        dependencies.get("@cloudflare/workers-types") == "5.20260722.1",
        "Workers Types direct pin changed",
    )
    lock_packages = package_lock.get("packages", {})
    require(lock_packages.get("node_modules/wrangler", {}).get("version") == "4.114.0", "lock Wrangler changed")
    require(lock_packages.get("node_modules/miniflare", {}).get("version") == "4.20260722.0", "lock Miniflare changed")
    require(lock_packages.get("node_modules/sharp", {}).get("version") == "0.35.2", "lock Sharp changed")
    require("sharp" not in package_json.get("dependencies", {}), "direct Sharp dependency prohibited")
    require("sharp" not in dependencies, "direct Sharp dev dependency prohibited")
    require("overrides" not in package_json and "resolutions" not in package_json, "override prohibited")


def validate_documentation_text(technical: str, summary: str, readme: str) -> None:
    combined = "\n".join((technical, summary, readme)).lower()
    for phrase in (
        "p0.17",
        "dh-fix-003",
        "dh-fix-007",
        "dh-ui-007",
        "dh-ui-016",
        "dh-is-007",
        "dh-is-016",
        "neutral shield",
        "test-only",
        "export-excluded",
        "no-phone",
        "issue #39",
        "issues #85 and #86 remain blocked",
    ):
        require(phrase in combined, f"P0.17 documentation missing: {phrase}")
    for claim in (
        "human validation passed",
        "privacy certified",
        "security certified",
        "accessibility certified",
        "physical controller validated",
        "television readability passed",
        "fun validated",
        "balance validated",
        "fairness validated",
    ):
        require(claim not in combined, f"prohibited evidence claim found: {claim}")
    require(summary.startswith("# P0.17 —"), "P0.17 summary heading drifted")


def validate(root: Path = ROOT) -> tuple[int, int]:
    fixture_count, negative_count = inherited_projection.validate(root)
    package = read_json(root / FIXTURE_PATH)
    schema = read_json(root / SCHEMA_PATH)
    validate_fixture_package(package, schema)
    validate_governed_sources(root)
    validate_godot_sources(root, package)
    validate_manifest_and_production_boundary(
        read_json(root / MANIFEST_PATH),
        read_json(root / CATALOG_PATH),
        (root / PROVIDER_PATH).read_text(encoding="utf-8"),
        (root / EXPORT_PRESETS_PATH).read_text(encoding="utf-8"),
        read_json(root / PACKAGE_JSON_PATH),
        read_json(root / PACKAGE_LOCK_PATH),
    )
    validate_documentation_text(
        (root / TECHNICAL_PATH).read_text(encoding="utf-8"),
        (root / SUMMARY_PATH).read_text(encoding="utf-8"),
        (root / README_PATH).read_text(encoding="utf-8"),
    )
    lantern_package = read_json(
        root / "game/data/tales/lantern_house/tale_package_v1.json"
    )
    require(
        canonical_sha256(lantern_package) == EXPECTED_PACKAGE_DIGEST,
        "Lantern House package identity changed",
    )
    return fixture_count, negative_count


def main() -> int:
    try:
        fixture_count, negative_count = validate(ROOT)
    except (
        ControlledPrivateValidationError,
        inherited_projection.inherited.ProjectionFixtureError,
        OSError,
    ) as exc:
        print(f"Drowned Harbor controlled-private validation failed: {exc}", file=sys.stderr)
        return 1
    package = read_json(ROOT / FIXTURE_PATH)
    print(
        "Validated P0.17 controlled-private shield: "
        f"{fixture_count} fixtures, {negative_count} embedded fail-closed cases, "
        f"identity {canonical_sha256(package)}, production and export invariance"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
