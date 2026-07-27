#!/usr/bin/env python3
"""Validate the export-excluded Drowned Harbor Low Tide shared-screen shell."""

from __future__ import annotations

import hashlib
import json
import re
import sys
from pathlib import Path
from typing import Any

ROOT = Path(".")
FIXTURE_PATH = Path(
    "game/tests/drowned_harbor_dev_only/state_projection_fixtures_v1.json"
)
ADAPTER_PATH = Path(
    "game/tests/drowned_harbor_dev_only/low_tide_fixture_adapter.gd"
)
SHELL_PATH = Path(
    "game/tests/drowned_harbor_dev_only/low_tide_shared_screen_shell.gd"
)
SCENE_PATH = Path(
    "game/tests/drowned_harbor_dev_only/low_tide_shared_screen_shell.tscn"
)
TEST_PATH = Path("game/tests/drowned_harbor_low_tide_shell_test.gd")
MANIFEST_PATH = Path("game/tests/drowned_harbor_prototype_manifest_v1.json")
CATALOG_PATH = Path("game/data/tales/tale_catalog_v1.json")
PROVIDER_PATH = Path("game/src/session/tale_provider_registry.gd")
EXPORT_PRESETS_PATH = Path("game/export_presets.cfg")
PROJECT_PATH = Path("game/project.godot")
TECHNICAL_PATH = Path(
    "docs/technical/Drowned_Harbor_Low_Tide_Shared_Screen_Shell_v1.md"
)
SUMMARY_PATH = Path("docs/preproduction/P0.15_Release_Summary.md")
EXPECTED_CATALOG_DIGEST = (
    "2b478fd0d11fa075c2050409193aa06e"
    "6b9ca4dcf6efd4e4c550a9f3a5ff9db6"
)
PRIVATE_MARKERS = {
    "PRIVATE_FIND_MISSING_NAME",
    "PRIVATE_SALT_KEY",
    "archive_culvert",
    "bellmarked_candidate",
}
EXPECTED_COMPONENT_URIS = [
    "res://tests/drowned_harbor_dev_only/low_tide_fixture_adapter.gd",
    "res://tests/drowned_harbor_dev_only/low_tide_shared_screen_shell.gd",
    "res://tests/drowned_harbor_dev_only/low_tide_shared_screen_shell.tscn",
]
EXPECTED_ENTRY_POINTS = [
    "res://tests/drowned_harbor_low_tide_shell_test.gd",
    "res://tests/drowned_harbor_prototype_isolation_test.gd",
]


class LowTideShellValidationError(ValueError):
    """Raised when the bounded Low Tide shell contract is violated."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise LowTideShellValidationError(message)


def read_json(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise LowTideShellValidationError(f"required file missing: {path}") from exc
    except json.JSONDecodeError as exc:
        raise LowTideShellValidationError(f"invalid JSON in {path}: {exc}") from exc
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


def low_tide_fixture(root: Path = ROOT) -> dict[str, Any]:
    package = read_json(root / FIXTURE_PATH)
    fixtures = package.get("fixtures")
    require(isinstance(fixtures, list), "fixture inventory must be an array")
    matches = [
        fixture
        for fixture in fixtures
        if isinstance(fixture, dict) and fixture.get("fixture_id") == "DH-FIX-001"
    ]
    require(len(matches) == 1, "DH-FIX-001 must resolve exactly once")
    return matches[0]


def validate_fixture(root: Path = ROOT) -> None:
    fixture = low_tide_fixture(root)
    require(fixture.get("trace_id") == "DH-IS-003", "trace binding drifted")
    require(fixture.get("storyboard_id") == "DH-UI-003", "storyboard binding drifted")
    require(
        fixture.get("privacy_surface") == "public_shared",
        "Low Tide fixture must remain public-shared",
    )
    require(
        fixture.get("source_revision") == 11
        and fixture.get("result_revision") == 12,
        "Low Tide fixture revisions drifted",
    )
    require(
        fixture.get("rng_cursor_before") == fixture.get("rng_cursor_after") == 4,
        "Low Tide projection must consume no RNG",
    )
    require(
        fixture.get("stable_seat_identity_before")
        == fixture.get("stable_seat_identity_after")
        == fixture.get("active_stable_seat_id")
        == "seat_01",
        "stable-seat identity drifted",
    )
    source = fixture.get("source_state")
    require(isinstance(source, dict), "fixture source state must be an object")
    public = source.get("public")
    seat_public = source.get("seat_public")
    private = source.get("private")
    require(
        isinstance(public, dict)
        and isinstance(seat_public, dict)
        and isinstance(private, dict),
        "fixture public, seat-public, and private domains are required",
    )
    require(public.get("stage") == "low_tide_arrival", "fixture stage drifted")
    require(
        public.get("legal_actions")
        == [
            "move_to_bellhouse",
            "inspect_salt_market",
            "stabilize_lifeboat_route",
        ],
        "Low Tide legal-action inventory drifted",
    )
    projection_map = fixture.get("projection_map")
    require(isinstance(projection_map, dict), "projection map must be an object")
    require(projection_map.get("private") == {}, "public shell may not map private data")
    public_map = projection_map.get("public")
    require(isinstance(public_map, dict), "public projection map must be an object")
    require(
        all(
            isinstance(path, str)
            and (path.startswith("public.") or path == "seat_public")
            for path in public_map.values()
        ),
        "public projection map may read only public and seat-public data",
    )
    source_text = json.dumps(source, ensure_ascii=False)
    require(
        all(marker in source_text for marker in PRIVATE_MARKERS),
        "source fixture must retain private leak sentinels",
    )


def validate_godot_components(root: Path = ROOT) -> None:
    for path in (ADAPTER_PATH, SHELL_PATH, SCENE_PATH, TEST_PATH):
        require((root / path).is_file(), f"required shell component missing: {path}")
        require(
            str(path).startswith("game/tests/"),
            f"shell component escaped the test tree: {path}",
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
        "class_name DrownedHarborLowTideFixtureAdapter",
        'const FIXTURE_ID: String = "DH-FIX-001"',
        'const TRACE_ID: String = "DH-IS-003"',
        'const STORYBOARD_ID: String = "DH-UI-003"',
        "func default_request() -> Dictionary:",
        "func project(request: Dictionary) -> Dictionary:",
        "stale_source_revision",
        "unauthorized_actor",
        "wrong_stable_seat",
        "unauthorized_intent",
        "private_data_rejected",
        "source_mutation_detected",
    ):
        require(phrase in adapter, f"adapter missing required contract phrase: {phrase}")

    for phrase in (
        "class_name DrownedHarborLowTideSharedScreenShell",
        "enum SurfaceMode",
        "func dispatch_semantic_action(action: String) -> Dictionary:",
        "func cancel() -> Dictionary:",
        "func open_transcript() -> Dictionary:",
        "func request_replay() -> Dictionary:",
        "func confirm_pending(current_revision: int, stable_seat_id: String)",
        "func render_snapshot() -> Dictionary:",
        "func state_signature() -> Dictionary:",
        "placeholder_geometry_not_final",
        "persistent_text_when_voice_off",
        "prototype_confirmation_requested",
        '"authoritative_commit": false',
        "No state, seat, or RNG change occurred.",
    ):
        require(phrase in shell, f"shell missing required contract phrase: {phrase}")

    for landmark in (
        "DAMAGED CAUSEWAY",
        "BELLHOUSE",
        "SALT MARKET",
        "LIFEBOAT SHED",
        "DISTANT LIGHTHOUSE",
    ):
        require(landmark in shell, f"placeholder geography missing {landmark}")

    require(
        'path="res://tests/drowned_harbor_dev_only/'
        'low_tide_shared_screen_shell.gd"' in scene,
        "scene does not use the bounded test-only shell script",
    )
    require(
        'type="Control"' in scene,
        "Low Tide shell scene root must remain a Control",
    )
    for phrase in (
        "_test_deterministic_public_projection",
        "_test_public_outputs_reject_private_fixture_data",
        "_test_focus_preview_cancel_and_stable_seat",
        "_test_voice_off_persistent_information",
        "_test_revision_bound_confirmation",
        "_test_controller_and_keyboard_fallback_mappings",
        "_test_scene_is_test_only_and_instantiable",
    ):
        require(phrase in test, f"Godot shell test missing coverage: {phrase}")

    public_source = adapter + shell + test
    for marker in PRIVATE_MARKERS:
        if marker in {"archive_culvert", "bellmarked_candidate"}:
            continue
        require(
            marker not in public_source,
            f"private fixture value copied into shell source: {marker}",
        )


def validate_input_contract(root: Path = ROOT) -> None:
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


def validate_manifest_and_production_boundary(root: Path = ROOT) -> None:
    manifest = read_json(root / MANIFEST_PATH)
    require(
        manifest.get("completed_work_issues") == [80, 81, 82],
        "manifest must record issue #82 as completed bounded work",
    )
    require(
        manifest.get("future_work_issues") == [83, 84, 85, 86],
        "issues #83 through #86 must remain future work",
    )
    require(
        manifest.get("allowed_entry_points") == EXPECTED_ENTRY_POINTS,
        "manifest entry-point set drifted",
    )
    require(
        manifest.get("prototype_components") == EXPECTED_COMPONENT_URIS,
        "manifest Low Tide component set drifted",
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


def validate_documentation(root: Path = ROOT) -> None:
    for path in (TECHNICAL_PATH, SUMMARY_PATH):
        require((root / path).is_file(), f"release documentation missing: {path}")
        text = (root / path).read_text(encoding="utf-8")
        for phrase in (
            "P0.15",
            "DH-FIX-001",
            "DH-UI-003",
            "DH-IS-003",
            "Lantern House",
            "issue #39",
            "issue #44",
            "physical-controller",
            "television-readability",
            "test-only",
            "export-excluded",
        ):
            require(phrase.lower() in text.lower(), f"{path} missing phrase: {phrase}")


def validate(root: Path = ROOT) -> None:
    validate_fixture(root)
    validate_godot_components(root)
    validate_input_contract(root)
    validate_manifest_and_production_boundary(root)
    validate_documentation(root)


def main() -> int:
    try:
        validate(ROOT)
    except (LowTideShellValidationError, OSError) as exc:
        print(
            f"Drowned Harbor Low Tide shell validation failed: {exc}",
            file=sys.stderr,
        )
        return 1
    print(
        "Validated P0.15 Low Tide fixture projection, public-only shell, "
        "semantic inputs, production invariance, and export exclusion"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
