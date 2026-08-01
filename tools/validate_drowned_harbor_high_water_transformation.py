#!/usr/bin/env python3
"""Validate the export-excluded P0.18 deterministic High Water proof."""

from __future__ import annotations

import hashlib
import json
import re
import subprocess
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
    "game/tests/drowned_harbor_dev_only/high_water_fixture_adapter.gd"
)
SHELL_PATH = Path(
    "game/tests/drowned_harbor_dev_only/high_water_transformation_shell.gd"
)
SCENE_PATH = Path(
    "game/tests/drowned_harbor_dev_only/high_water_transformation_shell.tscn"
)
TEST_PATH = Path("game/tests/drowned_harbor_high_water_transformation_test.gd")
UID_SIDECAR_PATHS = (
    ADAPTER_PATH.with_suffix(".gd.uid"),
    SHELL_PATH.with_suffix(".gd.uid"),
    TEST_PATH.with_suffix(".gd.uid"),
)
EXPECTED_UID_TEXTS = {
    ADAPTER_PATH.with_suffix(".gd.uid"): "uid://c5s0l3fkk448w",
    SHELL_PATH.with_suffix(".gd.uid"): "uid://c5s0l3fkln84w",
    TEST_PATH.with_suffix(".gd.uid"): "uid://c5s0l3fklpldw",
}
CANONICAL_UID_PATTERN = re.compile(r"uid://[a-y0-8]{13}")
ISOLATION_TEST_PATH = Path("game/tests/drowned_harbor_prototype_isolation_test.gd")
MANIFEST_PATH = Path("game/tests/drowned_harbor_prototype_manifest_v1.json")
README_PATH = Path("game/tests/drowned_harbor_dev_only/README.md")
TECHNICAL_PATH = Path(
    "docs/technical/Drowned_Harbor_High_Water_Deterministic_Transformation_v1.md"
)
P019_TECHNICAL_AUTHORITY = (
    "docs/technical/Drowned_Harbor_Prototype_Automation_Export_Exclusion_v1.md"
)
AUTOMATION_PROFILE = (
    "res://tests/drowned_harbor_dev_only/prototype_automation_profile_v1.json"
)
SUMMARY_PATH = Path("docs/preproduction/P0.18_Release_Summary.md")
WORKFLOW_PATH = Path(
    ".github/workflows/drowned-harbor-high-water-transformation.yml"
)
CATALOG_PATH = Path("game/data/tales/tale_catalog_v1.json")
LANTERN_PACKAGE_PATH = Path(
    "game/data/tales/lantern_house/tale_package_v1.json"
)
PROVIDER_PATH = Path("game/src/session/tale_provider_registry.gd")
EXPORT_PRESETS_PATH = Path("game/export_presets.cfg")
PROJECT_PATH = Path("game/project.godot")
PACKAGE_JSON_PATH = Path("package.json")
PACKAGE_LOCK_PATH = Path("package-lock.json")
STORYBOARD_PATH = Path(
    "docs/tales/drowned_harbor/ui/drowned_harbor_core_storyboards_v1.json"
)
TRACE_PATH = Path(
    "docs/tales/drowned_harbor/interaction/"
    "drowned_harbor_interaction_resolution_traces_v1.json"
)
AUTHORING_PATH = Path(
    "docs/tales/drowned_harbor/authoring/"
    "drowned_harbor_authoring_reference_v1.json"
)

EXPECTED_CATALOG_DIGEST = (
    "2b478fd0d11fa075c2050409193aa06e"
    "6b9ca4dcf6efd4e4c550a9f3a5ff9db6"
)
EXPECTED_LANTERN_DIGEST = (
    "abb39d6bfbdf8d7de108379f08180c13"
    "efb99bbffa3e53f30eaaa8de7f459dee"
)
EXPECTED_ENTRY_POINTS = [
    "res://tests/drowned_harbor_low_tide_shell_test.gd",
    "res://tests/drowned_harbor_bellhouse_recovery_test.gd",
    "res://tests/drowned_harbor_controlled_private_shield_test.gd",
    "res://tests/drowned_harbor_high_water_transformation_test.gd",
    "res://tests/drowned_harbor_prototype_automation_test.gd",
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
    "res://tests/drowned_harbor_dev_only/high_water_fixture_adapter.gd",
    "res://tests/drowned_harbor_dev_only/high_water_transformation_shell.gd",
    "res://tests/drowned_harbor_dev_only/high_water_transformation_shell.tscn",
]
AUTHORIZED_PATHS = {
    ".github/workflows/drowned-harbor-high-water-transformation.yml",
    "docs/preproduction/P0.18_Release_Summary.md",
    "docs/technical/Drowned_Harbor_High_Water_Deterministic_Transformation_v1.md",
    "game/tests/drowned_harbor_high_water_transformation_test.gd",
    "game/tests/drowned_harbor_high_water_transformation_test.gd.uid",
    "game/tests/drowned_harbor_dev_only/README.md",
    "game/tests/drowned_harbor_dev_only/high_water_fixture_adapter.gd",
    "game/tests/drowned_harbor_dev_only/high_water_fixture_adapter.gd.uid",
    "game/tests/drowned_harbor_dev_only/high_water_transformation_shell.gd",
    "game/tests/drowned_harbor_dev_only/high_water_transformation_shell.gd.uid",
    "game/tests/drowned_harbor_dev_only/high_water_transformation_shell.tscn",
    "game/tests/drowned_harbor_dev_only/state_projection_fixtures_v1.json",
    "game/tests/drowned_harbor_prototype_isolation_test.gd",
    "game/tests/drowned_harbor_prototype_manifest_v1.json",
    "tools/test_validate_drowned_harbor_high_water_transformation.py",
    "tools/validate_drowned_harbor_high_water_transformation.py",
    "tools/validate_drowned_harbor_projection_fixtures_p016.py",
    "tools/validate_drowned_harbor_prototype_isolation_p016.py",
    "tools/validate_drowned_harbor_controlled_private_shield.py",
    "tools/validate_drowned_harbor_bellhouse_recovery.py",
    "tools/validate_drowned_harbor_low_tide_shell_p016.py",
}


class HighWaterValidationError(ValueError):
    """Raised when the bounded P0.18 contract is violated."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise HighWaterValidationError(message)


def read_json(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise HighWaterValidationError(f"required file missing: {path}") from exc
    except json.JSONDecodeError as exc:
        raise HighWaterValidationError(f"invalid JSON in {path}: {exc}") from exc
    require(isinstance(value, dict), f"JSON root must be an object: {path}")
    return value


def tracked_uid_contents(root: Path = ROOT) -> dict[Path, str]:
    try:
        result = subprocess.run(
            ["git", "ls-files", "-z", "--", "*.gd.uid"],
            cwd=root,
            check=True,
            capture_output=True,
        )
    except (OSError, subprocess.CalledProcessError) as exc:
        raise HighWaterValidationError(
            "tracked Godot UID inventory could not be read"
        ) from exc
    paths = [
        Path(value.decode("utf-8"))
        for value in result.stdout.split(b"\0")
        if value
    ]
    contents: dict[Path, str] = {}
    for path in paths:
        try:
            contents[path] = (root / path).read_text(encoding="utf-8")
        except FileNotFoundError as exc:
            raise HighWaterValidationError(
                f"tracked Godot UID sidecar is missing: {path}"
            ) from exc
    return contents


def validate_uid_sidecar_contents(
    new_contents: dict[Path, str],
    tracked_contents: dict[Path, str],
) -> None:
    require(
        tuple(new_contents) == UID_SIDECAR_PATHS,
        "High Water UID sidecar inventory or order drifted",
    )
    authorized = {Path(value) for value in AUTHORIZED_PATHS}
    textual_uids: list[str] = []
    for path in UID_SIDECAR_PATHS:
        require(path in authorized, f"High Water UID sidecar is unauthorized: {path}")
        require(
            path.is_relative_to(Path("game/tests")),
            f"High Water UID sidecar escaped the test-only tree: {path}",
        )
        content = new_contents[path]
        require(
            content.endswith("\n") and content.count("\n") == 1 and "\r" not in content,
            f"{path} must contain exactly one UID and a trailing newline",
        )
        uid_text = content[:-1]
        require(uid_text.startswith("uid://"), f"{path} is missing the uid:// prefix")
        payload = uid_text.removeprefix("uid://")
        require(payload != "", f"{path} UID payload is empty")
        require(len(payload) <= 13, f"{path} UID payload exceeds 13 characters")
        require(len(payload) == 13, f"{path} must use the generated 13-character convention")
        require(
            CANONICAL_UID_PATTERN.fullmatch(uid_text) is not None,
            f"{path} UID uses a noncanonical Godot character",
        )
        require(
            uid_text == EXPECTED_UID_TEXTS[path],
            f"{path} canonical round-trip UID identity drifted",
        )
        textual_uids.append(uid_text)
    require(len(set(textual_uids)) == 3, "High Water UID sidecars must be distinct")
    for path, content in tracked_contents.items():
        if path in UID_SIDECAR_PATHS:
            continue
        other_uid = content.strip()
        for uid_text in textual_uids:
            require(
                other_uid != uid_text,
                f"High Water UID duplicates tracked sidecar {path}",
            )


def validate_uid_sidecars(root: Path = ROOT) -> None:
    tracked_contents = tracked_uid_contents(root)
    require(
        all(path in tracked_contents for path in UID_SIDECAR_PATHS),
        "all three High Water UID sidecars must exist and remain tracked",
    )
    for path in UID_SIDECAR_PATHS:
        require((root / path).is_file(), f"required High Water UID sidecar missing: {path}")
        require(
            (root / path.with_suffix("")).is_file(),
            f"High Water UID sidecar has no associated script: {path}",
        )
    validate_uid_sidecar_contents(
        {path: tracked_contents[path] for path in UID_SIDECAR_PATHS},
        tracked_contents,
    )


def canonical_bytes(value: Any) -> bytes:
    return json.dumps(
        value,
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    ).encode("utf-8")


def canonical_sha256(value: Any) -> str:
    return hashlib.sha256(canonical_bytes(value)).hexdigest()


def record_by_id(
    document: dict[str, Any],
    key: str,
    value: str,
) -> dict[str, Any]:
    entries = document.get("entries")
    require(isinstance(entries, list), f"{value} source entries are missing")
    matches = [
        entry
        for entry in entries
        if isinstance(entry, dict) and entry.get(key) == value
    ]
    require(len(matches) == 1, f"{value} must resolve exactly once")
    return matches[0]


def fixture_by_id(package: dict[str, Any], fixture_id: str) -> dict[str, Any]:
    fixtures = package.get("fixtures")
    require(isinstance(fixtures, list), "fixture inventory must be an array")
    matches = [
        value
        for value in fixtures
        if isinstance(value, dict) and value.get("fixture_id") == fixture_id
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
) -> dict[str, Any]:
    fixtures = package.get("fixtures")
    require(isinstance(fixtures, list), "fixture inventory must be an array")
    require(
        [value.get("fixture_id") for value in fixtures]
        == [f"DH-FIX-{number:03d}" for number in range(1, 8)],
        "fixture inventory must remain exactly DH-FIX-001 through DH-FIX-007",
    )
    fixture_schema = schema.get("properties", {}).get("fixtures", {})
    require(
        fixture_schema.get("minItems") == 7
        and fixture_schema.get("maxItems") == 7,
        "fixture schema must remain unchanged at exactly seven entries",
    )
    fixture = fixture_by_id(package, "DH-FIX-004")
    require(fixture.get("trace_id") == "DH-IS-008", "DH-FIX-004 trace drifted")
    require(
        fixture.get("storyboard_id") == "DH-UI-008",
        "DH-FIX-004 storyboard drifted",
    )
    require(
        fixture.get("fixture_kind") == "once_only_public_transform_projection",
        "DH-FIX-004 kind drifted",
    )
    require(
        fixture.get("seed") == 6108
        and fixture.get("source_revision") == 41
        and fixture.get("result_revision") == 42,
        "DH-FIX-004 seed or revisions drifted",
    )
    require(
        fixture.get("rng_cursor_before")
        == fixture.get("rng_cursor_after")
        == 12,
        "DH-FIX-004 must consume no RNG",
    )
    require(
        fixture.get("authorized_actor_kinds") == ["system"],
        "DH-FIX-004 system authority drifted",
    )
    require(
        fixture.get("stable_seat_identity_before")
        == fixture.get("stable_seat_identity_after")
        == fixture.get("active_stable_seat_id")
        == "seat_04",
        "DH-FIX-004 stable-seat identity drifted",
    )
    request = fixture.get("projection_request", {})
    require(
        request
        == {
            "fixture_id": "DH-FIX-004",
            "source_revision": 41,
            "actor_kind": "system",
            "stable_seat_id": "seat_04",
            "intent": "project_high_water_transformation",
        },
        "DH-FIX-004 request binding drifted",
    )
    public = fixture.get("source_state", {}).get("public", {})
    seat = fixture.get("source_state", {}).get("seat_public", {})
    private = fixture.get("source_state", {}).get("private", {})
    require(
        public.get("council_direction")
        == "synthetic_council_direction_fixture_004",
        "synthetic Council direction drifted",
    )
    require(
        public.get("stage_before") == "lighthouse_council"
        and public.get("stage_after") == "high_water"
        and public.get("once_only_marker") == "high_water_committed",
        "stage or once-only marker drifted",
    )
    require(
        public.get("changed_categories")
        == ["route", "hazard", "mechanism", "objective"],
        "changed-category inventory drifted",
    )
    require(
        public.get("public_hazards_before") == ["mudflat_instability"]
        and public.get("public_hazards_after")
        == ["submerged_causeway", "collapsed_archive_street"],
        "public hazard transformation drifted",
    )
    require(
        public.get("public_mechanism_changes") == [],
        "fixture must explicitly declare no mechanism changes",
    )
    before_routes = public.get("board_before")
    after_routes = public.get("board_after")
    require(
        isinstance(before_routes, dict)
        and isinstance(after_routes, dict)
        and set(before_routes) == set(after_routes),
        "before/after route identities must be complete and stable",
    )
    route_states = set(before_routes.values()) | set(after_routes.values())
    require(
        {
            "open",
            "unstable",
            "submerged",
            "flooded_passable",
            "water_route_only",
            "collapsed",
        }.issubset(route_states),
        "fixture route-state proof is incomplete",
    )
    require(
        isinstance(public.get("objective_before"), str)
        and isinstance(public.get("objective_after"), str)
        and public.get("objective_before")
        != public.get("objective_after"),
        "objective before/after proof drifted",
    )
    require(
        seat.get("seat_id") == "seat_04"
        and seat.get("location_before") == "salt_market"
        and seat.get("location_after") == "salt_market_platform"
        and seat.get("public_form_before")
        == seat.get("public_form_after")
        == seat.get("public_form")
        == "living",
        "stable-seat location or public-form continuity drifted",
    )
    legal_actions = public.get("legal_inspection_actions")
    require(
        isinstance(legal_actions, list)
        and legal_actions
        and all(str(action).startswith("inspect_") for action in legal_actions),
        "transformed-board inventory must be read-only inspection labels",
    )
    summary = public.get("persistent_summary", "")
    for phrase in (
        "synthetic_council_direction_fixture_004",
        "High Water",
        "Routes:",
        "Hazards:",
        "Mechanisms:",
        "no fixture-declared mechanism changes",
        "Objective:",
        "seat_04",
        "salt_market",
        "salt_market_platform",
        "Read-only transformed-board inspection",
    ):
        require(phrase in summary, f"persistent summary missing: {phrase}")
    markers = set(private_strings(private))
    require(
        markers
        == {
            "PRIVATE_TIDEBOUND_PENDING",
            "PRIVATE_CARRY_NAME_TO_LIGHTHOUSE",
            "PRIVATE_SEAT_04",
        },
        "DH-FIX-004 private leak sentinels drifted",
    )
    projection = fixture.get("projection_map", {})
    require(projection.get("private") == {}, "DH-FIX-004 may not project private data")
    public_paths = projection.get("public", {})
    require(
        isinstance(public_paths, dict)
        and all(
            str(path) == "seat_public"
            or str(path).startswith(("public.", "seat_public."))
            for path in public_paths.values()
        ),
        "DH-FIX-004 public projection escaped public source domains",
    )
    for field in (
        "council_direction",
        "public_hazards_before",
        "public_hazards_after",
        "public_mechanism_changes",
        "objective_before",
        "legal_inspection_actions",
        "persistent_summary",
    ):
        require(field in public_paths, f"bounded fixture projection missing: {field}")
    events = fixture.get("expected_events")
    require(isinstance(events, list) and len(events) == 1, "one event is required")
    event = events[0]
    require(
        event.get("event_key") == "high_water_transformation_committed"
        and event.get("classification") == "public"
        and event.get("exactly_once") is True,
        "High Water public event contract drifted",
    )
    require(
        event.get("payload_map", {}).get("council_direction")
        == "public.council_direction",
        "public event must retain committed Council direction",
    )
    require(
        fixture.get("human_validation_required") is True
        and fixture.get("human_evidence_claimed") is False,
        "human evidence boundary drifted",
    )
    return fixture


def build_proof(fixture: dict[str, Any]) -> dict[str, Any]:
    """Build the canonical presentation-independent public proof."""
    public = fixture["source_state"]["public"]
    seat = fixture["source_state"]["seat_public"]
    event_key = fixture["expected_events"][0]["event_key"]
    event_identity = hashlib.sha256(
        (
            f"{fixture['fixture_id']}|{fixture['source_revision']}|"
            f"{fixture['result_revision']}|{event_key}"
        ).encode("utf-8")
    ).hexdigest()
    authoritative_state = {
        "council_direction": public["council_direction"],
        "fixture_id": fixture["fixture_id"],
        "legal_inspection_actions": public["legal_inspection_actions"],
        "objective": public["objective_after"],
        "once_only_marker": public["once_only_marker"],
        "public_forms": {seat["seat_id"]: seat["public_form_after"]},
        "public_hazards": public["public_hazards_after"],
        "public_mechanism_changes": public["public_mechanism_changes"],
        "result_revision": fixture["result_revision"],
        "rng_cursor": fixture["rng_cursor_after"],
        "routes": public["board_after"],
        "seat_positions": {seat["seat_id"]: seat["location_after"]},
        "source_revision": fixture["source_revision"],
        "stable_seat_ids": [seat["seat_id"]],
        "stage": public["stage_after"],
    }
    event_payload = {
        "changed_categories": public["changed_categories"],
        "council_direction": public["council_direction"],
        "event_key": event_key,
        "fixture_id": fixture["fixture_id"],
        "result_revision": fixture["result_revision"],
        "seat_id": seat["seat_id"],
        "source_revision": fixture["source_revision"],
        "stage": public["stage_after"],
    }
    transformed_board = {
        "geography_identity": "recognizable_low_tide_geography_under_high_water",
        "legal_inspection_actions": public["legal_inspection_actions"],
        "objective": public["objective_after"],
        "placeholder_geometry": True,
        "public_forms": {seat["seat_id"]: seat["public_form_after"]},
        "public_hazards": public["public_hazards_after"],
        "route_state_legend": {
            "collapsed": "X-shape / broken hatch",
            "damaged": "split outline / diagonal scar",
            "flooded_passable": "double line / shallow-wave pattern",
            "open": "solid line / OPEN label",
            "submerged": "dotted line / SUBMERGED label",
            "unstable": "zigzag line / UNSTABLE label",
            "water_only": "wave line / WATER ONLY label",
        },
        "routes": public["board_after"],
        "seat_positions": {seat["seat_id"]: seat["location_after"]},
        "stage": public["stage_after"],
    }
    event = {
        "classification": "public",
        "event_identity": event_identity,
        "event_key": event_key,
        "payload": event_payload,
    }
    recap = {"event_identity": event_identity, "summary": public["persistent_summary"]}
    return {
        "authoritative_state": authoritative_state,
        "caption": public["caption"],
        "changed_categories": public["changed_categories"],
        "commit_count": 1,
        "event_count": 1,
        "event_identity": event_identity,
        "event_payload": event_payload,
        "legal_inspection_actions": public["legal_inspection_actions"],
        "mirrored_output": [recap],
        "persistent_summary": public["persistent_summary"],
        "public_form_state": transformed_board["public_forms"],
        "public_history": [event],
        "replay_summary": [recap],
        "result_revision": fixture["result_revision"],
        "signal_count": 1,
        "stable_seat_positions": transformed_board["seat_positions"],
        "transcript": [public["persistent_summary"]],
        "transformed_board_projection": transformed_board,
    }


def validate_deterministic_model(fixture: dict[str, Any]) -> dict[str, Any]:
    prepared_before_branch = build_proof(fixture)
    full = json.loads(canonical_bytes(prepared_before_branch))
    skipped = json.loads(canonical_bytes(prepared_before_branch))
    require(
        canonical_bytes(full) == canonical_bytes(skipped),
        "full and skipped public proof bytes differ",
    )
    require(full["commit_count"] == 1, "model must commit exactly once")
    require(full["event_count"] == 1, "model must emit exactly one public event")
    require(full["signal_count"] == 1, "model must emit exactly one signal")
    require(
        full["authoritative_state"]["rng_cursor"] == 12,
        "model changed RNG cursor",
    )
    public_bytes = canonical_bytes(full).decode("utf-8")
    for marker in private_strings(fixture["source_state"]["private"]):
        require(marker not in public_bytes, f"private marker leaked: {marker}")
    return full


def validate_governed_sources(root: Path = ROOT) -> None:
    storyboards = read_json(root / STORYBOARD_PATH)
    traces = read_json(root / TRACE_PATH)
    ui_008 = record_by_id(storyboards, "storyboard_id", "DH-UI-008")
    ui_009 = record_by_id(storyboards, "storyboard_id", "DH-UI-009")
    is_008 = record_by_id(traces, "trace_id", "DH-IS-008")
    is_009 = record_by_id(traces, "trace_id", "DH-IS-009")
    require(
        ui_008.get("legal_actions")
        == [
            "acknowledge_transformation",
            "open_transcript",
            "replay_summary",
            "skip_animation",
        ],
        "DH-UI-008 governed action inventory drifted",
    )
    require(
        ui_008.get("persistent_text_policy", {}).get("required") is True
        and ui_008.get("seat_authority_policy", {}).get(
            "authority_transfer_allowed"
        )
        is False,
        "DH-UI-008 persistent text or authority policy drifted",
    )
    require(
        ui_009.get("privacy_surface") == "public_shared"
        and "inspect_route" in ui_009.get("legal_actions", []),
        "DH-UI-009 public inspection boundary drifted",
    )
    require(
        is_008.get("allowed_actors") == ["system"]
        and is_008.get("commit_contract", {}).get("once_only_transition") is True
        and is_008.get("commit_contract", {}).get("retry_behavior")
        == "reproject_existing_result",
        "DH-IS-008 authority or retry contract drifted",
    )
    emitted = is_008.get("projection_contract", {}).get("emitted_events", [])
    require(
        len(emitted) == 1
        and emitted[0].get("event_key")
        == "high_water_transformation_committed"
        and emitted[0].get("exactly_once") is True,
        "DH-IS-008 event contract drifted",
    )
    require(
        is_009.get("privacy_contract", {}).get(
            "public_payload_private_data_prohibited"
        )
        is None
        or is_009.get("projection_contract", {}).get(
            "public_payload_private_data_prohibited"
        )
        is True,
        "DH-IS-009 private exclusion drifted",
    )
    authoring = read_json(root / AUTHORING_PATH)
    transforms = authoring.get("signature_transformations", [])
    high_water = next(
        (value for value in transforms if value.get("id") == "high_water_transform"),
        None,
    )
    require(
        isinstance(high_water, dict)
        and high_water.get("deterministic") is True
        and high_water.get("once_only") is True
        and high_water.get("source_stage") == "lighthouse_council"
        and high_water.get("target_stage") == "high_water",
        "authoring High Water transformation drifted",
    )


def validate_godot_sources_text(
    adapter: str,
    shell: str,
    test: str,
    isolation_test: str,
    scene: str,
) -> None:
    for phrase in (
        "class_name DrownedHarborHighWaterFixtureAdapter",
        'const FIXTURE_ID: String = "DH-FIX-004"',
        'const TRACE_ID: String = "DH-IS-008"',
        'const STORYBOARD_ID: String = "DH-UI-008"',
        'const EVENT_KEY: String = "high_water_transformation_committed"',
        'const SYNTHETIC_COUNCIL_DIRECTION: String = "synthetic_council_direction_fixture_004"',
        "stale_source_revision",
        "unauthorized_actor",
        "wrong_stable_seat",
        "malformed_transform_request",
        "incomplete_transform_input",
        "already_committed",
        "rng_mutation_detected",
        "private_data_rejected",
        "func _prepare_canonical_result() -> Dictionary:",
        "func _build_event_identity() -> String:",
    ):
        require(phrase in adapter, f"High Water adapter missing: {phrase}")
    require("Time." not in adapter and "Time." not in shell, "wall-clock authority is prohibited")
    require("RandomNumberGenerator" not in adapter + shell, "presentation RNG is prohibited")
    require(
        '"%s|%d|%d|%s" % [FIXTURE_ID, SOURCE_REVISION, RESULT_REVISION, EVENT_KEY]'
        in adapter,
        "event identity derivation drifted",
    )
    for phrase in (
        "class_name DrownedHarborHighWaterTransformationShell",
        "authoritative_result_prepared_before_presentation_branch",
        "func run_full_presentation() -> Dictionary:",
        "func skip_presentation() -> Dictionary:",
        "func interrupt_caption_or_voice() -> Dictionary:",
        "func _fail_projection_before_commit() -> Dictionary:",
        "func _fail_projection_after_commit() -> Dictionary:",
        "func recover_projection(",
        "func reproject_existing_result() -> Dictionary:",
        "func acknowledge_persistent_summary() -> Dictionary:",
        "func inspect_transformed_board(action: String) -> Dictionary:",
        "func _attempt_transformed_board_action_commit(action: String) -> Dictionary:",
        "func _attempt_gameplay_action(action: String) -> Dictionary:",
        "func _attempt_authority_transfer() -> Dictionary:",
        '"read_only_boundary"',
        '"authority_transfer_prohibited"',
        '"persistent_summary_required"',
        '"production_authority"' if '"production_authority"' in shell else "BLOCKED_GAMEPLAY_ACTIONS",
    ):
        require(phrase in shell, f"High Water shell missing: {phrase}")
    require(shell.count("_committed_result = authoritative") == 1, "authoritative assignment drifted")
    require(shell.count("_commit_count += 1") == 1, "exactly-once commit increment drifted")
    require(shell.count("_public_event_count += 1") == 1, "exactly-once event increment drifted")
    require(shell.count("_public_history.append(") == 1, "history accumulation drifted")
    require(shell.count("_public_transcript.append(") == 1, "transcript accumulation drifted")
    require(shell.count("_public_replay.append(") == 1, "replay accumulation drifted")
    require(shell.count("_mirrored_output.append(") == 1, "mirror accumulation drifted")
    require(
        shell.count("prototype_high_water_event_emitted.emit(") == 1,
        "public signal emission drifted",
    )
    require(
        '_public_transcript.append(str(summary_entry.get("summary", "")))' in shell,
        "transcript must use the sanitized public summary",
    )
    require(
        "_public_replay.append(summary_entry.duplicate(true))" in shell,
        "replay must use the sanitized public summary",
    )
    commit = shell[
        shell.index("func commit_authoritative_transformation(") : shell.index(
            "func run_full_presentation("
        )
    ]
    require(
        commit.index("_committed_result = authoritative")
        < commit.index("_mode = SurfaceMode.PRESENTING"),
        "authoritative result must commit before presentation",
    )
    skip = shell[
        shell.index("func skip_presentation(") : shell.index(
            "func acknowledge_persistent_summary("
        )
    ]
    for prohibited in (
        '_committed_result["result_revision"]',
        '_committed_result["rng_cursor"]',
        '_committed_result["routes"]',
        '_committed_result["seat_positions"]',
    ):
        require(prohibited not in skip, f"skip may not alter authority: {prohibited}")
    presentation = shell[
        shell.index("func advance_placeholder_presentation(") : shell.index(
            "func skip_presentation("
        )
    ]
    require(
        "_committed_result =" not in presentation,
        "presentation may not choose authoritative result",
    )
    interruption = shell[
        shell.index("func interrupt_caption_or_voice(") : shell.index(
            "func _fail_projection_before_commit("
        )
    ]
    require(
        "_committed_result.clear()" not in interruption,
        "interruption may not roll back committed High Water",
    )
    recovery = shell[
        shell.index("func recover_projection(") : shell.index(
            "func _set_transcript_available("
        )
    ]
    require(
        "return reproject_existing_result()" in recovery,
        "post-commit recovery must reproject existing result",
    )
    next_interaction = shell[
        shell.index("func _next_interaction_allowed(") : shell.index(
            "func _prepared_result_bytes("
        )
    ]
    require(
        "_summary_available and _summary_acknowledged" in next_interaction,
        "control returned before persistent summary acknowledgement",
    )
    gameplay = shell[
        shell.index("func _attempt_gameplay_action(") : shell.index(
            "func _attempt_authority_transfer("
        )
    ]
    require(
        "_commit_count" not in gameplay
        and "_committed_result" not in gameplay
        and "gameplay_mutation_blocked" in gameplay,
        "gameplay action may mutate proof state",
    )
    transformed_commit = shell[
        shell.index("func _attempt_transformed_board_action_commit(") : shell.index(
            "func _attempt_gameplay_action("
        )
    ]
    require(
        'return _reject(\n\t\t"read_only_boundary"' in transformed_commit,
        "transformed-board action commitment became enabled",
    )
    for phrase in (
        "_test_complete_full_and_skip_are_byte_equivalent",
        "_test_exactly_once_event_and_duplicate_reprojection",
        "_test_request_rejections_fail_closed",
        "_test_precommit_projection_failure_and_recovery",
        "_test_postcommit_projection_failure_reprojects_existing_result",
        "_test_caption_interruptions_preserve_commit_boundary",
        "_test_transcript_and_replay_unavailability_preserve_board",
        "_test_persistent_summary_precedes_focus_return",
        "_test_transformed_board_is_read_only_and_multichannel",
        "_test_private_markers_never_enter_public_channels",
        "_test_no_duplicate_outputs_or_signals",
        "_test_repeated_projection_and_second_shell_are_deterministic",
        "_test_gameplay_and_unsupported_inputs_fail_closed",
        "_test_canonical_uid_sidecars_round_trip_and_remain_test_only",
    ):
        require(phrase in test, f"focused Godot coverage missing: {phrase}")
    require(
        "EXPECTED_ENTRY_POINTS" in isolation_test
        and "drowned_harbor_high_water_transformation_test.gd" in isolation_test
        and "high_water_transformation_shell.tscn" in isolation_test,
        "isolation Godot suite does not register P0.18 test-only files",
    )
    require(
        "res://tests/drowned_harbor_dev_only/high_water_transformation_shell.gd"
        in scene,
        "High Water scene escaped the test-only shell",
    )


def validate_manifest_and_production_boundary(
    manifest: dict[str, Any],
    catalog: dict[str, Any],
    lantern_package: dict[str, Any],
    provider: str,
    presets: str,
    project: str,
    package_json: dict[str, Any],
    package_lock: dict[str, Any],
) -> None:
    require(
        manifest.get("completed_work_issues") == [80, 81, 82, 83, 84, 85, 86],
        "completed work must be exactly issues #80 through #86",
    )
    require(
        manifest.get("future_work_issues") == [],
        "future work must be empty after P0.19",
    )
    require(manifest.get("allowed_entry_points") == EXPECTED_ENTRY_POINTS, "entry points drifted")
    require(manifest.get("prototype_components") == EXPECTED_COMPONENTS, "components drifted")
    require(
        TECHNICAL_PATH.as_posix() in manifest.get("source_authorities", []),
        "P0.18 technical authority is not registered",
    )
    require(
        P019_TECHNICAL_AUTHORITY in manifest.get("source_authorities", []),
        "P0.19 technical authority is not registered",
    )
    require(
        manifest.get("automation_profiles") == [AUTOMATION_PROFILE],
        "P0.19 automation profile registration drifted",
    )
    require(manifest.get("human_validation_required") is True, "human validation must remain required")
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
        and catalog["entries"][0].get("tale_id")
        == "lantern_house_vertical_slice",
        "production catalog must remain Lantern House-only",
    )
    require(canonical_sha256(lantern_package) == EXPECTED_LANTERN_DIGEST, "Lantern House digest changed")
    require("drowned_harbor" not in json.dumps(catalog).lower(), "Drowned Harbor entered catalog")
    require("drowned_harbor" not in provider.lower(), "Drowned Harbor entered provider")
    require(presets.count("tests/*") == 2, "both ordinary exports must exclude tests/*")
    for filename in (
        ADAPTER_PATH.name,
        SHELL_PATH.name,
        SCENE_PATH.name,
        TEST_PATH.name,
        FIXTURE_PATH.name,
    ):
        require(filename not in presets, f"ordinary export explicitly includes {filename}")
    require(
        "drowned_harbor_high_water" not in project.lower(),
        "P0.18 input or autoload registration entered project.godot",
    )
    dependencies = package_json.get("devDependencies", {})
    require(dependencies.get("wrangler") == "4.114.0", "Wrangler direct pin changed")
    require(
        dependencies.get("@cloudflare/workers-types") == "5.20260722.1",
        "Workers Types direct pin changed",
    )
    lock_packages = package_lock.get("packages", {})
    require(
        lock_packages.get("node_modules/wrangler", {}).get("version") == "4.114.0",
        "lock Wrangler changed",
    )
    require(
        lock_packages.get("node_modules/miniflare", {}).get("version")
        == "4.20260722.0",
        "lock Miniflare changed",
    )
    require(
        lock_packages.get("node_modules/sharp", {}).get("version") == "0.35.2",
        "lock Sharp changed",
    )
    require("sharp" not in package_json.get("dependencies", {}), "direct Sharp dependency prohibited")
    require("sharp" not in dependencies, "direct Sharp dev dependency prohibited")
    require(
        "overrides" not in package_json and "resolutions" not in package_json,
        "dependency override prohibited",
    )


def validate_workflow_text(workflow: str) -> None:
    require(
        workflow.startswith("name: Drowned Harbor High Water deterministic transformation\n"),
        "workflow display name drifted",
    )
    require(
        "agent/p0.18-drowned-harbor-high-water-transformation" in workflow,
        "required branch boundary is missing",
    )
    for path in AUTHORIZED_PATHS:
        require(
            workflow.count(f"'{path}'") == 3,
            f"workflow must govern exact path three times: {path}",
        )
    require(
        "Validated exact 21-path P0.18 release boundary" in workflow,
        "workflow exact-path proof is missing",
    )
    for command in (
        "validate_drowned_harbor_high_water_transformation.py",
        "test_validate_drowned_harbor_high_water_transformation.py",
        "validate_drowned_harbor_controlled_private_shield.py",
        "test_validate_drowned_harbor_controlled_private_shield.py",
        "validate_drowned_harbor_bellhouse_recovery.py",
        "test_validate_drowned_harbor_bellhouse_recovery.py",
        "validate_drowned_harbor_low_tide_shell_p016.py",
        "test_validate_drowned_harbor_low_tide_shell_p016.py",
        "validate_drowned_harbor_projection_fixtures_p016.py",
        "test_validate_drowned_harbor_projection_fixtures_p016.py",
        "validate_drowned_harbor_prototype_isolation_p016.py",
        "test_validate_drowned_harbor_prototype_isolation_p016.py",
        "gdformat --check",
        "gdlint",
        "Godot_v4.7.1-stable_linux.x86_64",
        "drowned_harbor_high_water_transformation_test.gd",
        "drowned_harbor_low_tide_shell_test.gd",
        "drowned_harbor_bellhouse_recovery_test.gd",
        "drowned_harbor_controlled_private_shield_test.gd",
        "drowned_harbor_prototype_isolation_test.gd",
        "p018-high-water-transformation-evidence",
        "Remove generated evidence",
        "Prove repository remains clean",
    ):
        require(command in workflow, f"workflow requirement missing: {command}")
    for pin in (
        "actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0",
        "actions/setup-python@ece7cb06caefa5fff74198d8649806c4678c61a1",
        "actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a",
    ):
        require(pin in workflow, f"immutable action pin drifted: {pin}")


def validate_documentation_text(technical: str, summary: str, readme: str) -> None:
    combined = "\n".join((technical, summary, readme)).lower()
    for phrase in (
        "p0.18",
        "dh-fix-004",
        "dh-ui-008",
        "dh-ui-009",
        "dh-is-008",
        "dh-is-009",
        "synthetic_council_direction_fixture_004",
        "test-only",
        "export-excluded",
        "byte-equivalent",
        "exactly once",
        "persistent",
        "read-only",
        "issue #39",
        "issue #86 remains future and blocked",
        "physical-controller",
        "television",
        "privacy or security certification",
    ):
        require(phrase in combined, f"P0.18 documentation missing: {phrase}")
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
        "production ready",
    ):
        require(claim not in combined, f"prohibited evidence claim found: {claim}")
    require(
        summary.startswith(
            "# P0.18 — Drowned Harbor High Water Deterministic Transformation Proof"
        ),
        "P0.18 summary heading drifted",
    )
    require(
        re.search(r"\b\d+\s*/\s*\d+\b", summary) is None,
        "documentation predeclared a mutation pass count",
    )


def validate(root: Path = ROOT) -> tuple[int, int, str]:
    fixture_count, negative_count = inherited_projection.validate(root)
    package = read_json(root / FIXTURE_PATH)
    schema = read_json(root / SCHEMA_PATH)
    fixture = validate_fixture_package(package, schema)
    proof = validate_deterministic_model(fixture)
    validate_governed_sources(root)
    validate_uid_sidecars(root)
    validate_godot_sources_text(
        (root / ADAPTER_PATH).read_text(encoding="utf-8"),
        (root / SHELL_PATH).read_text(encoding="utf-8"),
        (root / TEST_PATH).read_text(encoding="utf-8"),
        (root / ISOLATION_TEST_PATH).read_text(encoding="utf-8"),
        (root / SCENE_PATH).read_text(encoding="utf-8"),
    )
    validate_manifest_and_production_boundary(
        read_json(root / MANIFEST_PATH),
        read_json(root / CATALOG_PATH),
        read_json(root / LANTERN_PACKAGE_PATH),
        (root / PROVIDER_PATH).read_text(encoding="utf-8"),
        (root / EXPORT_PRESETS_PATH).read_text(encoding="utf-8"),
        (root / PROJECT_PATH).read_text(encoding="utf-8"),
        read_json(root / PACKAGE_JSON_PATH),
        read_json(root / PACKAGE_LOCK_PATH),
    )
    validate_workflow_text((root / WORKFLOW_PATH).read_text(encoding="utf-8"))
    validate_documentation_text(
        (root / TECHNICAL_PATH).read_text(encoding="utf-8"),
        (root / SUMMARY_PATH).read_text(encoding="utf-8"),
        (root / README_PATH).read_text(encoding="utf-8"),
    )
    return fixture_count, negative_count, canonical_sha256(proof)


def main() -> int:
    try:
        fixture_count, negative_count, proof_identity = validate(ROOT)
    except (
        HighWaterValidationError,
        inherited_projection.inherited.ProjectionFixtureError,
        OSError,
    ) as exc:
        print(f"Drowned Harbor High Water validation failed: {exc}", file=sys.stderr)
        return 1
    print(
        "Validated P0.18 deterministic High Water transformation: "
        f"{fixture_count} fixtures, {negative_count} embedded fail-closed cases, "
        f"proof identity {proof_identity}, production and export invariance"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
