#!/usr/bin/env python3
"""Validate the export-excluded P0.16 Bellhouse and recovery shell."""

from __future__ import annotations

import hashlib
import json
import re
import sys
from pathlib import Path
from typing import Any, Iterable

ROOT = Path(".")
FIXTURE_PATH = Path(
    "game/tests/drowned_harbor_dev_only/state_projection_fixtures_v1.json"
)
ADAPTER_PATH = Path(
    "game/tests/drowned_harbor_dev_only/bellhouse_fixture_adapter.gd"
)
SHELL_PATH = Path(
    "game/tests/drowned_harbor_dev_only/bellhouse_decision_shell.gd"
)
SCENE_PATH = Path(
    "game/tests/drowned_harbor_dev_only/bellhouse_decision_shell.tscn"
)
TEST_PATH = Path("game/tests/drowned_harbor_bellhouse_recovery_test.gd")
MANIFEST_PATH = Path("game/tests/drowned_harbor_prototype_manifest_v1.json")
CATALOG_PATH = Path("game/data/tales/tale_catalog_v1.json")
PROVIDER_PATH = Path("game/src/session/tale_provider_registry.gd")
EXPORT_PRESETS_PATH = Path("game/export_presets.cfg")
PROJECT_PATH = Path("game/project.godot")
TECHNICAL_PATH = Path(
    "docs/technical/Drowned_Harbor_Bellhouse_Decision_Recovery_v1.md"
)
SUMMARY_PATH = Path("docs/preproduction/P0.16_Release_Summary.md")
EXPECTED_CATALOG_DIGEST = (
    "2b478fd0d11fa075c2050409193aa06e"
    "6b9ca4dcf6efd4e4c550a9f3a5ff9db6"
)
EXPECTED_ENTRY_POINTS = [
    "res://tests/drowned_harbor_low_tide_shell_test.gd",
    "res://tests/drowned_harbor_bellhouse_recovery_test.gd",
    "res://tests/drowned_harbor_prototype_isolation_test.gd",
]
EXPECTED_COMPONENTS = [
    "res://tests/drowned_harbor_dev_only/low_tide_fixture_adapter.gd",
    "res://tests/drowned_harbor_dev_only/low_tide_shared_screen_shell.gd",
    "res://tests/drowned_harbor_dev_only/low_tide_shared_screen_shell.tscn",
    "res://tests/drowned_harbor_dev_only/bellhouse_fixture_adapter.gd",
    "res://tests/drowned_harbor_dev_only/bellhouse_decision_shell.gd",
    "res://tests/drowned_harbor_dev_only/bellhouse_decision_shell.tscn",
]


class BellhouseRecoveryValidationError(ValueError):
    """Raised when the bounded P0.16 contract is violated."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise BellhouseRecoveryValidationError(message)


def read_json(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise BellhouseRecoveryValidationError(
            f"required file missing: {path}"
        ) from exc
    except json.JSONDecodeError as exc:
        raise BellhouseRecoveryValidationError(f"invalid JSON in {path}: {exc}") from exc
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


def validate_decision_fixture(package: dict[str, Any]) -> None:
    fixture = fixture_by_id(package, "DH-FIX-002")
    require(fixture.get("trace_id") == "DH-IS-004", "Bellhouse trace binding drifted")
    require(
        fixture.get("storyboard_id") == "DH-UI-004",
        "Bellhouse storyboard binding drifted",
    )
    require(
        fixture.get("fixture_kind") == "public_commit_projection",
        "Bellhouse fixture kind drifted",
    )
    require(
        fixture.get("privacy_surface") == "public_shared",
        "Bellhouse fixture must remain public-shared",
    )
    require(
        fixture.get("source_revision") == 21
        and fixture.get("result_revision") == 22,
        "Bellhouse fixture revisions drifted",
    )
    require(
        fixture.get("rng_cursor_before") == fixture.get("rng_cursor_after") == 7,
        "Bellhouse projection must consume no RNG",
    )
    require(
        fixture.get("stable_seat_identity_before")
        == fixture.get("stable_seat_identity_after")
        == fixture.get("active_stable_seat_id")
        == "seat_02",
        "Bellhouse stable-seat identity drifted",
    )
    request = fixture.get("projection_request")
    require(isinstance(request, dict), "Bellhouse request must be an object")
    require(
        request.get("actor_kind") == "active_stable_seat"
        and request.get("stable_seat_id") == "seat_02"
        and request.get("intent") == "project_bellhouse_decision",
        "Bellhouse request authority or intent drifted",
    )
    source = fixture.get("source_state")
    require(isinstance(source, dict), "Bellhouse source state must be an object")
    public = source.get("public")
    private = source.get("private")
    seat_public = source.get("seat_public")
    require(
        isinstance(public, dict)
        and isinstance(private, dict)
        and isinstance(seat_public, dict),
        "Bellhouse public, seat-public, and private domains are required",
    )
    require(public.get("stage") == "bellhouse_ledger", "Bellhouse stage drifted")
    require(
        public.get("selected_option") == "record_missing_position",
        "governed synthetic Bellhouse option drifted",
    )
    require(
        public.get("ledger")
        == {"visible_names": 5, "erased_positions": 2, "unresolved_positions": 1},
        "public Ledger evidence drifted",
    )
    require(
        public.get("ring_state")
        == {"visible_count": 5, "audible_count": 6, "extra_ring_unresolved": True},
        "public ring evidence drifted",
    )
    require(
        public.get("legal_actions")
        == [
            "continue_to_lighthouse",
            "inspect_ledger",
            "review_public_record",
        ],
        "Bellhouse public legal-action inventory drifted",
    )
    projection_map = fixture.get("projection_map")
    require(isinstance(projection_map, dict), "Bellhouse projection map is required")
    require(
        projection_map.get("private") == {},
        "Bellhouse public projection may not map private data",
    )
    public_map = projection_map.get("public")
    require(isinstance(public_map, dict), "Bellhouse public map is required")
    require(
        all(
            isinstance(path, str)
            and (path.startswith("public.") or path == "seat_public")
            for path in public_map.values()
        ),
        "Bellhouse public map may read only public and seat-public data",
    )
    require(
        set(private_strings(private))
        == {
            "PRIVATE_BELLMARKED",
            "PRIVATE_PRESERVE_HARBOR",
            "PRIVATE_SIXTH_NAME",
        },
        "Bellhouse fixture private leak sentinels drifted",
    )
    events = fixture.get("expected_events")
    require(
        isinstance(events, list)
        and len(events) == 1
        and events[0].get("event_key") == "bellhouse_decision_committed"
        and events[0].get("classification") == "public"
        and events[0].get("exactly_once") is True,
        "Bellhouse governed event contract drifted",
    )


def validate_recovery_fixture(package: dict[str, Any]) -> None:
    fixture = fixture_by_id(package, "DH-FIX-006")
    require(fixture.get("trace_id") == "DH-IS-019", "recovery trace binding drifted")
    require(
        fixture.get("storyboard_id") == "DH-UI-019",
        "recovery storyboard binding drifted",
    )
    require(
        fixture.get("fixture_kind") == "public_recovery_projection",
        "recovery fixture kind drifted",
    )
    require(
        fixture.get("privacy_surface") == "public_shared",
        "recovery fixture must remain public-shared",
    )
    require(
        fixture.get("source_revision") == fixture.get("result_revision") == 61,
        "recovery revision must remain unchanged",
    )
    require(
        fixture.get("rng_cursor_before") == fixture.get("rng_cursor_after") == 18,
        "recovery must consume no RNG",
    )
    require(
        fixture.get("authoritative_commit") is False,
        "recovery may not commit authoritative state",
    )
    require(
        fixture.get("stable_seat_identity_before")
        == fixture.get("stable_seat_identity_after")
        == fixture.get("active_stable_seat_id")
        == "seat_06",
        "recovery stable-seat identity drifted",
    )
    source = fixture.get("source_state")
    require(isinstance(source, dict), "recovery source state must be an object")
    public = source.get("public")
    private = source.get("private")
    seat_public = source.get("seat_public")
    require(
        isinstance(public, dict)
        and isinstance(private, dict)
        and isinstance(seat_public, dict),
        "recovery public, seat-public, and private domains are required",
    )
    require(public.get("state_changed") is False, "recovery must preserve state")
    require(public.get("rng_changed") is False, "recovery must preserve RNG")
    alternatives = public.get("legal_alternatives")
    require(
        isinstance(alternatives, list)
        and public.get("focus_destination") in alternatives,
        "recovery focus must target a legal alternative",
    )
    require(
        public.get("focus_destination") == "move_to_bellhouse_roof",
        "governed recovery focus drifted",
    )
    require(
        set(private_strings(private))
        == {
            "PRIVATE_ARCHIVE_ROUTE_RESERVED_FOR_DROWNED_GUIDE",
            "PRIVATE_FIND_MISSING_NAME",
        },
        "recovery fixture private leak sentinels drifted",
    )
    projection_map = fixture.get("projection_map")
    require(isinstance(projection_map, dict), "recovery projection map is required")
    require(
        projection_map.get("private") == {},
        "recovery public projection may not map private data",
    )
    events = fixture.get("expected_events")
    require(
        isinstance(events, list)
        and len(events) == 1
        and events[0].get("event_key") == "invalid_action_recovery_projected"
        and events[0].get("classification") == "diagnostic"
        and events[0].get("exactly_once") is False,
        "recovery governed event contract drifted",
    )


def validate_godot_components(root: Path, package: dict[str, Any]) -> None:
    for path in (ADAPTER_PATH, SHELL_PATH, SCENE_PATH, TEST_PATH):
        require((root / path).is_file(), f"required P0.16 component missing: {path}")
        require(
            str(path).startswith("game/tests/"),
            f"P0.16 component escaped the test tree: {path}",
        )
    for path in (
        ADAPTER_PATH.with_suffix(".gd.uid"),
        SHELL_PATH.with_suffix(".gd.uid"),
        TEST_PATH.with_suffix(".gd.uid"),
    ):
        require((root / path).is_file(), f"Godot UID file missing: {path}")
        uid = (root / path).read_text(encoding="utf-8").strip()
        require(
            re.fullmatch(r"uid://[a-z0-9]{13}", uid) is not None,
            f"invalid Godot UID format: {path}",
        )

    adapter = (root / ADAPTER_PATH).read_text(encoding="utf-8")
    shell = (root / SHELL_PATH).read_text(encoding="utf-8")
    scene = (root / SCENE_PATH).read_text(encoding="utf-8")
    test = (root / TEST_PATH).read_text(encoding="utf-8")

    for phrase in (
        "class_name DrownedHarborBellhouseFixtureAdapter",
        'const DECISION_FIXTURE_ID: String = "DH-FIX-002"',
        'const RECOVERY_FIXTURE_ID: String = "DH-FIX-006"',
        'const DECISION_TRACE_ID: String = "DH-IS-004"',
        'const RECOVERY_TRACE_ID: String = "DH-IS-019"',
        "func project_decision(request: Dictionary) -> Dictionary:",
        "func project_recovery(request: Dictionary) -> Dictionary:",
        "stale_source_revision",
        "unauthorized_actor",
        "wrong_stable_seat",
        "unauthorized_intent",
        "private_data_rejected",
        "source_mutation_detected",
        "bellhouse_decision_committed",
        "invalid_action_recovery_projected",
    ):
        require(phrase in adapter, f"adapter missing required phrase: {phrase}")

    for phrase in (
        "class_name DrownedHarborBellhouseDecisionShell",
        "enum SurfaceMode",
        "func preview_selected() -> Dictionary:",
        "func request_confirmation() -> Dictionary:",
        "func confirm_pending(",
        "func project_fixture_recovery() -> Dictionary:",
        "func return_to_decision() -> Dictionary:",
        "func open_transcript() -> Dictionary:",
        "func request_replay() -> Dictionary:",
        "prototype_commit_count",
        '"production_authority": false',
        '"prototype_commit": true',
        "stale_confirmation_revision",
        "wrong_confirmation_authority",
        "unauthorized_confirmation_actor",
        "changed_confirmation_option",
        "unavailable_confirmation_option",
        '"state_changed": false',
        '"rng_changed": false',
        '"stable_seat_reset": false',
        "placeholder_geometry_not_final",
        "persistent_text_when_voice_off",
    ):
        require(phrase in shell, f"shell missing required phrase: {phrase}")

    require(
        shell.count("_commit_count = 1") == 1,
        "shell must contain exactly one exactly-once commit assignment",
    )
    require(
        shell.count('"production_authority": false') == 1,
        "shell production-authority denial drifted",
    )
    require(
        shell.count('"stable_seat_reset": false') == 1,
        "shell stable-seat preservation marker drifted",
    )

    require(
        'path="res://tests/drowned_harbor_dev_only/'
        'bellhouse_decision_shell.gd"' in scene,
        "scene does not use the bounded Bellhouse shell script",
    )
    require('type="Control"' in scene, "Bellhouse scene root must remain a Control")

    for phrase in (
        "_test_deterministic_decision_and_recovery_projection",
        "_test_public_outputs_exclude_private_fixture_data",
        "_test_adapter_rejects_malformed_and_unauthorized_requests",
        "_test_bellhouse_presentation_and_voice_off_text",
        "_test_preview_inspect_focus_and_cancel_are_non_mutating",
        "_test_confirmation_commits_once_and_reprojects_idempotently",
        "_test_confirmation_failures_restore_public_safe_focus",
        "_test_independent_fixture_recovery_preserves_bellhouse_state",
        "_test_transcript_and_replay_do_not_reexecute_commit",
        "_test_controller_and_keyboard_fallback_mappings",
        "_test_scene_is_test_only_and_instantiable",
    ):
        require(phrase in test, f"Godot P0.16 test missing coverage: {phrase}")

    private_values = set(private_strings(package))
    public_source = adapter + shell + test
    for marker in private_values:
        require(
            marker not in public_source,
            f"private fixture value copied into public source: {marker}",
        )


def validate_input_contract(root: Path) -> None:
    project = (root / PROJECT_PATH).read_text(encoding="utf-8")
    for action in (
        "ui_navigate_up",
        "ui_navigate_down",
        "ui_navigate_left",
        "ui_navigate_right",
        "ui_confirm",
        "ui_cancel_action",
        "interact",
    ):
        match = re.search(
            rf"^{re.escape(action)}=\{{.*\}}$",
            project,
            flags=re.MULTILINE,
        )
        require(match is not None, f"semantic input action missing: {action}")
        line = match.group(0)
        require("InputEventKey" in line, f"{action} lacks keyboard fallback")
        require(
            "InputEventJoypadButton" in line or "InputEventJoypadMotion" in line,
            f"{action} lacks controller mapping",
        )


def validate_manifest_and_production_boundary(root: Path) -> None:
    manifest = read_json(root / MANIFEST_PATH)
    require(
        manifest.get("completed_work_issues") == [80, 81, 82, 83],
        "manifest must record issue #83 as completed bounded work",
    )
    require(
        manifest.get("future_work_issues") == [84, 85, 86],
        "issues #84 through #86 must remain future work",
    )
    require(
        manifest.get("allowed_entry_points") == EXPECTED_ENTRY_POINTS,
        "manifest entry-point set drifted",
    )
    require(
        manifest.get("prototype_components") == EXPECTED_COMPONENTS,
        "manifest P0.16 component set drifted",
    )
    require(
        str(TECHNICAL_PATH) in manifest.get("source_authorities", []),
        "manifest is missing the P0.16 technical authority",
    )
    for field in (
        "production_catalog_registered",
        "production_provider_registered",
        "normal_tale_library_visible",
        "playable_export_authorized",
        "runtime_authority_created",
        "human_evidence_claimed",
    ):
        require(manifest.get(field) is False, f"{field} must remain false")
    require(
        manifest.get("human_validation_required") is True,
        "human validation must remain required",
    )
    notes = manifest.get("notes")
    require(isinstance(notes, str) and len(notes) >= 1000, "manifest notes were weakened")
    for phrase in (
        "does not make Drowned Harbor playable",
        "production runtime authority",
        "independent from the Bellhouse fixture",
        "physical-controller evidence",
        "television-readability evidence",
        "human playtest evidence",
    ):
        require(phrase in notes, f"manifest notes missing boundary phrase: {phrase}")

    catalog = read_json(root / CATALOG_PATH)
    require(
        canonical_sha256(catalog) == EXPECTED_CATALOG_DIGEST,
        "production Tale catalog canonical digest changed",
    )
    require(
        catalog.get("default_tale_id") == "lantern_house_vertical_slice",
        "production default must remain Lantern House",
    )
    entries = catalog.get("entries")
    require(
        isinstance(entries, list)
        and len(entries) == 1
        and entries[0].get("tale_id") == "lantern_house_vertical_slice",
        "production catalog must remain Lantern House-only",
    )
    require(
        "drowned_harbor" not in json.dumps(catalog).lower(),
        "production catalog may not reference Drowned Harbor",
    )
    provider = (root / PROVIDER_PATH).read_text(encoding="utf-8").lower()
    require(
        "drowned_harbor" not in provider,
        "production provider may not reference Drowned Harbor",
    )
    require(
        'packedstringarray([lantern_house_provider_id])' in provider.replace('"', ""),
        "production provider allowlist drifted",
    )
    require(
        not (root / "game/data/tales/drowned_harbor").exists(),
        "Drowned Harbor production Tale directory may not exist",
    )
    presets = (root / EXPORT_PRESETS_PATH).read_text(encoding="utf-8")
    require(presets.count("tests/*") == 2, "both exports must exclude tests/*")
    for filename in (
        ADAPTER_PATH.name,
        SHELL_PATH.name,
        SCENE_PATH.name,
        TEST_PATH.name,
    ):
        require(
            filename not in presets,
            f"export preset may not explicitly include {filename}",
        )


def validate_documentation(root: Path) -> None:
    for path in (TECHNICAL_PATH, SUMMARY_PATH):
        require((root / path).is_file(), f"release documentation missing: {path}")
        text = (root / path).read_text(encoding="utf-8")
        for phrase in (
            "P0.16",
            "DH-FIX-002",
            "DH-FIX-006",
            "DH-UI-004",
            "DH-UI-019",
            "DH-IS-004",
            "DH-IS-019",
            "Lantern House",
            "issue #39",
            "issue #44",
            "physical-controller",
            "television-readability",
            "test-only",
            "export-excluded",
            "production authority",
        ):
            require(phrase.lower() in text.lower(), f"{path} missing phrase: {phrase}")
        if path == TECHNICAL_PATH:
            require(
                "physical-controller evidence" in text.lower(),
                "technical contract missing exact physical-controller evidence phrase",
            )
        if path == SUMMARY_PATH:
            require(
                text.startswith("# P0.16 —"),
                "release summary heading must retain the exact P0.16 identity",
            )


def validate(root: Path = ROOT) -> None:
    package = read_json(root / FIXTURE_PATH)
    validate_decision_fixture(package)
    validate_recovery_fixture(package)
    validate_godot_components(root, package)
    validate_input_contract(root)
    validate_manifest_and_production_boundary(root)
    validate_documentation(root)


def main() -> int:
    try:
        validate(ROOT)
    except (BellhouseRecoveryValidationError, OSError) as exc:
        print(
            f"Drowned Harbor Bellhouse/recovery validation failed: {exc}",
            file=sys.stderr,
        )
        return 1
    print(
        "Validated P0.16 Bellhouse decision, exactly-once prototype result, "
        "public-safe recovery, production invariance, and export exclusion"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
