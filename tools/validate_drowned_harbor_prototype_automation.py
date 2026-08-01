#!/usr/bin/env python3
"""Validate P0.19 Drowned Harbor automation and ordinary-export exclusion."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path, PurePosixPath
from typing import Any, Iterable

ROOT = Path(".")
PROFILE_PATH = Path(
    "game/tests/drowned_harbor_dev_only/prototype_automation_profile_v1.json"
)
MANIFEST_PATH = Path("game/tests/drowned_harbor_prototype_manifest_v1.json")
FIXTURE_PATH = Path(
    "game/tests/drowned_harbor_dev_only/state_projection_fixtures_v1.json"
)
SCHEMA_PATH = Path(
    "game/tests/drowned_harbor_dev_only/state_projection_fixture_schema_v1.json"
)
TEST_PATH = Path("game/tests/drowned_harbor_prototype_automation_test.gd")
UID_PATH = TEST_PATH.with_suffix(".gd.uid")
ISOLATION_TEST_PATH = Path("game/tests/drowned_harbor_prototype_isolation_test.gd")
README_PATH = Path("game/tests/drowned_harbor_dev_only/README.md")
TECHNICAL_PATH = Path(
    "docs/technical/Drowned_Harbor_Prototype_Automation_Export_Exclusion_v1.md"
)
SUMMARY_PATH = Path("docs/preproduction/P0.19_Release_Summary.md")
WORKFLOW_PATH = Path(
    ".github/workflows/drowned-harbor-prototype-automation.yml"
)
GODOT_WORKFLOW_PATH = Path(".github/workflows/godot-tests.yml")
PORTABLE_WORKFLOW_PATH = Path(".github/workflows/portable-builds.yml")
EXPORT_PRESETS_PATH = Path("game/export_presets.cfg")
PROJECT_PATH = Path("game/project.godot")
CATALOG_PATH = Path("game/data/tales/tale_catalog_v1.json")
LANTERN_PATH = Path("game/data/tales/lantern_house/tale_package_v1.json")
PROVIDER_PATH = Path("game/src/session/tale_provider_registry.gd")

PROFILE_ID = "DH-AUTO-P019-V1"
CATALOG_DIGEST = "2b478fd0d11fa075c2050409193aa06e6b9ca4dcf6efd4e4c550a9f3a5ff9db6"
LANTERN_DIGEST = "abb39d6bfbdf8d7de108379f08180c13efb99bbffa3e53f30eaaa8de7f459dee"
SCHEMA_DIGEST = "1c88af5ca18ffaf9887d2c0321d79f2749007bde111b7bba96c164f1b7b694be"
CANONICAL_UID = re.compile(r"uid://[a-y0-8]{13}\n")
SOURCE_SHA = re.compile(r"[0-9a-f]{40}")

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
EXPECTED_PROFILE_REGISTRATION = [
    "res://tests/drowned_harbor_dev_only/prototype_automation_profile_v1.json"
]
EXPECTED_FAMILIES = [
    {
        "family_id": "low_tide_public_action",
        "fixtures": ["DH-FIX-001"],
        "trace_storyboard_pairs": ["DH-IS-003/DH-UI-003"],
        "focused_test": "res://tests/drowned_harbor_low_tide_shell_test.gd",
    },
    {
        "family_id": "bellhouse_decision_and_recovery",
        "fixtures": ["DH-FIX-002", "DH-FIX-006"],
        "trace_storyboard_pairs": [
            "DH-IS-004/DH-UI-004",
            "DH-IS-019/DH-UI-019",
        ],
        "focused_test": "res://tests/drowned_harbor_bellhouse_recovery_test.gd",
    },
    {
        "family_id": "controlled_private_shield_and_handoff",
        "fixtures": ["DH-FIX-003", "DH-FIX-007"],
        "trace_storyboard_pairs": [
            "DH-IS-007/DH-UI-007",
            "DH-IS-016/DH-UI-016",
        ],
        "focused_test": "res://tests/drowned_harbor_controlled_private_shield_test.gd",
    },
    {
        "family_id": "high_water_transformation",
        "fixtures": ["DH-FIX-004"],
        "trace_storyboard_pairs": [
            "DH-IS-008/DH-UI-008",
            "DH-IS-009/DH-UI-009",
        ],
        "focused_test": "res://tests/drowned_harbor_high_water_transformation_test.gd",
    },
]
EXPECTED_SEQUENCES = [
    "canonical_forward",
    "reverse",
    "high_water_full_presentation",
    "high_water_semantic_skip",
    "controlled_private_unavailable_surface",
    "controlled_private_disconnect_interruption",
    "bellhouse_recovery_first",
    "stale_revision_rejection",
    "wrong_authority_wrong_seat_rejection",
    "duplicate_replay_idempotence",
    "repeated_fresh_shell_equivalence",
    "post_commit_reprojection",
]
AUTHORIZED_PATHS = {
    ".github/workflows/drowned-harbor-prototype-automation.yml",
    ".github/workflows/godot-tests.yml",
    ".github/workflows/portable-builds.yml",
    "docs/preproduction/P0.19_Release_Summary.md",
    "docs/technical/Drowned_Harbor_Prototype_Automation_Export_Exclusion_v1.md",
    "game/tests/drowned_harbor_prototype_automation_test.gd",
    "game/tests/drowned_harbor_prototype_automation_test.gd.uid",
    "game/tests/drowned_harbor_dev_only/prototype_automation_profile_v1.json",
    "game/tests/drowned_harbor_dev_only/README.md",
    "game/tests/drowned_harbor_prototype_isolation_test.gd",
    "game/tests/drowned_harbor_prototype_manifest_v1.json",
    "tools/validate_drowned_harbor_prototype_automation.py",
    "tools/test_validate_drowned_harbor_prototype_automation.py",
    "tools/validate_drowned_harbor_high_water_transformation.py",
    "tools/validate_drowned_harbor_controlled_private_shield.py",
    "tools/validate_drowned_harbor_bellhouse_recovery.py",
    "tools/validate_drowned_harbor_low_tide_shell_p016.py",
    "tools/validate_drowned_harbor_projection_fixtures_p016.py",
    "tools/validate_drowned_harbor_prototype_isolation_p016.py",
}


class AutomationValidationError(ValueError):
    """Raised when the closed P0.19 contract is violated."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AutomationValidationError(message)


def read_json(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (FileNotFoundError, json.JSONDecodeError) as exc:
        raise AutomationValidationError(f"required JSON invalid: {path}: {exc}") from exc
    require(isinstance(value, dict), f"JSON root must be an object: {path}")
    return value


def canonical_bytes(value: Any) -> bytes:
    return json.dumps(
        value,
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    ).encode("utf-8")


def canonical_sha256(value: Any) -> str:
    return hashlib.sha256(canonical_bytes(value)).hexdigest()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def exact_keys(value: dict[str, Any], expected: Iterable[str], label: str) -> None:
    require(set(value) == set(expected), f"{label} exact fields drifted")


def validate_profile(profile: dict[str, Any]) -> None:
    exact_keys(
        profile,
        (
            "profile_kind",
            "schema_version",
            "profile_id",
            "status",
            "classification",
            "godot_version",
            "prototype_manifest_path",
            "fixture_package_path",
            "aggregate_test_entry_point",
            "feature_families",
            "projection_only_fixtures",
            "determinism",
            "coverage",
            "production_boundary",
            "forbidden_export_inventory",
            "evidence",
        ),
        "profile root",
    )
    require(profile["profile_kind"] == "drowned_harbor_prototype_automation", "profile kind drifted")
    require(profile["schema_version"] == 1, "profile schema drifted")
    require(profile["profile_id"] == PROFILE_ID, "profile ID drifted")
    require(profile["status"] == "synthetic_test_only_export_excluded", "profile status drifted")
    require(profile["godot_version"] == "4.7.1-stable", "Godot version drifted")
    require(
        profile["prototype_manifest_path"]
        == "res://tests/drowned_harbor_prototype_manifest_v1.json",
        "profile manifest path drifted",
    )
    require(
        profile["fixture_package_path"]
        == "res://tests/drowned_harbor_dev_only/state_projection_fixtures_v1.json",
        "profile fixture path drifted",
    )
    require(
        profile["aggregate_test_entry_point"]
        == "res://tests/drowned_harbor_prototype_automation_test.gd",
        "aggregate entry point drifted",
    )
    require(profile["feature_families"] == EXPECTED_FAMILIES, "feature family inventory drifted")
    require(
        profile["projection_only_fixtures"]
        == [
            {
                "fixture_id": "DH-FIX-005",
                "trace_storyboard_pair": "DH-IS-010/DH-UI-010",
                "runtime_shell": False,
                "validation_path": "existing_projection_fixture_engine",
            }
        ],
        "DH-FIX-005 projection-only boundary drifted",
    )
    classification = profile["classification"]
    exact_keys(
        classification,
        (
            "automated",
            "deterministic",
            "headless",
            "machine_evidence",
            "human_playtest_evidence",
            "physical_controller_evidence",
            "television_evidence",
            "accessibility_compliance",
            "privacy_certification",
            "security_certification",
            "fun_evidence",
            "pacing_evidence",
            "fairness_evidence",
            "balance_evidence",
            "comprehension_evidence",
            "production_readiness_evidence",
        ),
        "classification",
    )
    for field in ("automated", "deterministic", "headless", "machine_evidence"):
        require(classification[field] is True, f"classification {field} must be true")
    for field in set(classification) - {"automated", "deterministic", "headless", "machine_evidence"}:
        require(classification[field] is False, f"classification {field} must remain denied")
    determinism = profile["determinism"]
    require(
        determinism
        == {
            "repetitions_per_sequence": 2,
            "max_steps_per_case": 32,
            "canonical_evidence_comparison": "utf8_json_sorted_keys_compact_sha256",
            "sequence_ids": EXPECTED_SEQUENCES,
        },
        "determinism contract drifted",
    )
    coverage = profile["coverage"]
    exact_coverage = {
        "public_evidence_only",
        "private_fixture_values_forbidden_from_output",
        "stale_revision",
        "wrong_authority",
        "wrong_stable_seat",
        "invalid_intent",
        "unavailable_surface",
        "replay",
        "duplicate_request",
        "high_water_full_skip_equivalence",
        "controlled_private_disconnect",
        "controlled_private_interruption",
        "bellhouse_recovery",
        "high_water_recovery",
        "bounded_no_deadlock",
    }
    require(set(coverage) == exact_coverage, "coverage inventory drifted")
    require(all(coverage.values()), "every governed coverage flag must be true")
    production = profile["production_boundary"]
    require(
        production
        == {
            "catalog_path": "res://data/tales/tale_catalog_v1.json",
            "catalog_sha256": CATALOG_DIGEST,
            "default_tale_id": "lantern_house_vertical_slice",
            "lantern_house_package_sha256": LANTERN_DIGEST,
            "provider_path": "res://src/session/tale_provider_registry.gd",
            "project_entry_point": "res://src/main/Main.tscn",
            "production_authority_created": False,
            "ordinary_export_presets": [
                "Internal Windows x86_64",
                "Internal Linux x86_64",
            ],
            "ordinary_exports_include_prototype": False,
        },
        "production boundary drifted",
    )
    export_inventory = profile["forbidden_export_inventory"]
    require(
        export_inventory
        == {
            "path_prefixes": ["res://tests/", "drowned_harbor_dev_only"],
            "fixture_ids": [f"DH-FIX-{number:03d}" for number in range(1, 8)],
            "public_markers": [
                "synthetic_council_direction_fixture_004",
                "high_water_transformation_committed",
                "drowned_harbor_prototype_manifest_v1.json",
                "prototype_automation_profile_v1.json",
                "drowned_harbor_prototype_automation_test.gd",
                PROFILE_ID,
            ],
            "prototype_filename_inventory_source": "exact_manifest_components_and_entry_points",
            "private_sentinel_source": "derive_exact_PRIVATE_values_from_fixture_package",
        },
        "closed forbidden-export inventory drifted",
    )
    require(
        profile["evidence"]
        == {
            "summary_prefix": "DROWNED_HARBOR_AUTOMATION_EVIDENCE:",
            "source_sha_required": True,
            "source_sha_format": "lowercase_hex_40",
            "generated_evidence_cleanup_required": True,
            "human_evidence_claimed": False,
        },
        "evidence contract drifted",
    )


def validate_manifest(manifest: dict[str, Any]) -> None:
    require(manifest.get("completed_work_issues") == [80, 81, 82, 83, 84, 85, 86], "completed issues drifted")
    require(manifest.get("future_work_issues") == [], "future issues must be empty")
    require(manifest.get("allowed_entry_points") == EXPECTED_ENTRY_POINTS, "six entry points drifted")
    require(manifest.get("prototype_components") == EXPECTED_COMPONENTS, "thirteen components drifted")
    require(manifest.get("automation_profiles") == EXPECTED_PROFILE_REGISTRATION, "profile registration drifted")
    require(
        TECHNICAL_PATH.as_posix() in manifest.get("source_authorities", []),
        "P0.19 authority missing",
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
    require(manifest.get("export_policy", {}).get("ordinary_exports_include_prototype") is False, "ordinary export denial drifted")
    require(manifest.get("dependencies") == {
        "network": False,
        "companion": False,
        "credentials": False,
        "telemetry": False,
        "cloud": False,
        "production_assets": False,
    }, "dependency denials drifted")


def private_sentinels(value: Any) -> set[str]:
    found: set[str] = set()
    if isinstance(value, dict):
        for nested in value.values():
            found.update(private_sentinels(nested))
    elif isinstance(value, list):
        for nested in value:
            found.update(private_sentinels(nested))
    elif isinstance(value, str) and value.startswith("PRIVATE_"):
        found.add(value)
    return found


def validate_fixture_and_schema(package: dict[str, Any], schema: dict[str, Any]) -> None:
    fixtures = package.get("fixtures")
    require(isinstance(fixtures, list), "fixture inventory missing")
    require(
        [item.get("fixture_id") for item in fixtures]
        == [f"DH-FIX-{number:03d}" for number in range(1, 8)],
        "fixture inventory must remain exactly 001 through 007",
    )
    require(canonical_sha256(schema) == SCHEMA_DIGEST, "fixture schema changed")
    fixture_five = fixtures[4]
    require(fixture_five.get("fixture_id") == "DH-FIX-005", "projection-only fixture identity drifted")
    require(fixture_five.get("trace_id") == "DH-IS-010", "DH-FIX-005 trace drifted")
    require(fixture_five.get("storyboard_id") == "DH-UI-010", "DH-FIX-005 storyboard drifted")


def validate_uid_contents(content: str, repository_contents: dict[Path, str]) -> None:
    require(CANONICAL_UID.fullmatch(content) is not None, "automation UID is not canonical 13-character text")
    uid_text = content.strip()
    matches = [path for path, value in repository_contents.items() if value.strip() == uid_text]
    require(len(matches) == 1 and matches[0] == UID_PATH, "automation UID duplicates a repository UID")


def validate_uid(root: Path = ROOT) -> None:
    uid_file = root / UID_PATH
    require(uid_file.is_file(), "automation UID sidecar missing")
    content = uid_file.read_text(encoding="utf-8")
    require((root / TEST_PATH).is_file(), "automation UID has no associated test")
    repository_contents: dict[Path, str] = {}
    for path in (root / "game").rglob("*.gd.uid"):
        text = path.read_text(encoding="utf-8").strip()
        repository_contents[path.relative_to(root)] = text
    validate_uid_contents(content, repository_contents)


def validate_godot_source(test: str, isolation: str) -> None:
    for token in (
        "DROWNED_HARBOR_AUTOMATION_EVIDENCE:",
        "EXPECTED_SEQUENCES",
        "repetition_count",
        "governed_case_count",
        "fail_closed_rejection_count",
        "private_leak_findings",
        "deadlock_findings",
        "deterministic_equivalence",
        "production_authority_created",
        "human_evidence_claimed",
        "_run_low",
        "_run_bellhouse",
        "_run_private",
        "_run_high",
        "_run_rejections",
        "_run_duplicates",
        "_run_high_reprojection",
        "_test_high_water_full_skip_equivalence",
        "DH-FIX-005",
        "max_steps_per_case",
    ):
        require(token in test, f"aggregate Godot source obligation missing: {token}")
    request_helper_match = re.search(
        r"func _run_low_request_contract_rejections\(\) -> Dictionary:\n"
        r"(?P<body>.*?)(?=\n\nfunc )",
        test,
        re.DOTALL,
    )
    require(request_helper_match is not None, "aggregate request-contract rejection helper missing")
    request_helper = request_helper_match.group("body") if request_helper_match else ""
    require(
        re.search(
            r'"stale_revision_rejection":\s*result = _sequence_bundle\(\s*\[\s*'
            r'_run_rejections\("stale"\),\s*_run_low_request_contract_rejections\(\)\s*\]\s*\)',
            test,
            re.DOTALL,
        )
        is not None,
        "aggregate request-contract helper is not executed in the sequence matrix",
    )
    require(request_helper.count("LOW_ADAPTER.new()") == 2, "request-contract cases need two fresh adapters")
    require(request_helper.count(".load_fixture()") == 2, "request-contract cases must load DH-FIX-001 twice")
    require(request_helper.count(".default_request()") == 2, "request-contract cases must start exact")
    require(request_helper.count(".project(") == 2, "request-contract cases must execute both requests")
    for token in (
        'unknown_request["intent"] = "unknown_fixture_intent"',
        'not unknown_rejected.get("accepted", true)',
        'unknown_code == "unauthorized_intent"',
        'malformed_request.erase("intent")',
        'not malformed_rejected.get("accepted", true)',
        'malformed_code == "malformed_request"',
        '_low_rejection_is_public_safe(unknown_rejected)',
        '_low_rejection_is_public_safe(malformed_rejected)',
        '"governed_cases": 2',
        '"rejections": 2',
    ):
        require(token in request_helper, f"aggregate request-contract execution missing: {token}")
    require(
        request_helper.count("_low_request_invariants(unknown_adapter)") == 2,
        "unknown-intent case does not prove governed no-mutation invariants",
    )
    require(
        request_helper.count("_low_request_invariants(malformed_adapter)") == 2,
        "malformed-request case does not prove governed no-mutation invariants",
    )
    invariant_helper_match = re.search(
        r"func _low_request_invariants\(.*?\) -> Dictionary:\n"
        r"(?P<body>.*?)(?=\n\nfunc )",
        test,
        re.DOTALL,
    )
    require(invariant_helper_match is not None, "Low Tide governed-invariant helper missing")
    invariant_helper = invariant_helper_match.group("body") if invariant_helper_match else ""
    for token in (
        "adapter.source_fingerprint()",
        "adapter.source_revision()",
        "adapter.result_revision()",
        "adapter.rng_cursor()",
        "adapter.stable_seat_id()",
    ):
        require(token in invariant_helper, f"Low Tide no-mutation invariant missing: {token}")
    require("PRIVATE_" in test and "_scan_public_evidence" in test, "private leak guard missing")
    require("prototype_automation_profile_v1.json" in isolation, "isolation profile coverage missing")
    require("drowned_harbor_prototype_automation_test.gd" in isolation, "isolation entry coverage missing")
    require("run/main_scene" in isolation, "isolation startup coverage missing")


def validate_production_boundary(
    profile: dict[str, Any],
    catalog: dict[str, Any],
    lantern: dict[str, Any],
    provider: str,
    project: str,
    presets: str,
) -> None:
    require(canonical_sha256(catalog) == CATALOG_DIGEST, "production catalog digest drifted")
    require(canonical_sha256(lantern) == LANTERN_DIGEST, "Lantern House digest drifted")
    require(catalog.get("default_tale_id") == "lantern_house_vertical_slice", "default Tale drifted")
    require(len(catalog.get("entries", [])) == 1, "production catalog inventory drifted")
    require("drowned_harbor" not in canonical_bytes(catalog).decode().lower(), "Drowned Harbor entered catalog")
    require("drowned_harbor" not in provider.lower(), "Drowned Harbor entered provider registry")
    require('run/main_scene="res://src/main/Main.tscn"' in project, "project entry point drifted")
    require("drowned_harbor" not in project.lower(), "Drowned Harbor entered project startup")
    require(presets.count('exclude_filter="') == 2, "ordinary export preset count drifted")
    require(presets.count("tests/*") == 2, "ordinary exports no longer exclude tests")
    require(profile["production_boundary"]["catalog_sha256"] == CATALOG_DIGEST, "profile catalog identity drifted")
    require(profile["production_boundary"]["lantern_house_package_sha256"] == LANTERN_DIGEST, "profile Lantern identity drifted")


def validate_workflows(p019: str, godot: str, portable: str) -> None:
    require("name: Drowned Harbor prototype automation and export exclusion" in p019, "P0.19 workflow name drifted")
    for pin in (
        "actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0",
        "actions/setup-python@ece7cb06caefa5fff74198d8649806c4678c61a1",
        "actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a",
    ):
        require(pin in p019, f"immutable action pin missing: {pin}")
    require("python-version: 3.11.9" in p019, "P0.19 Python pin missing")
    for command in (
        "python tools/validate_drowned_harbor_prototype_automation.py",
        "python tools/test_validate_drowned_harbor_prototype_automation.py",
        "res://tests/drowned_harbor_prototype_automation_test.gd",
        "res://tests/drowned_harbor_low_tide_shell_test.gd",
        "res://tests/drowned_harbor_bellhouse_recovery_test.gd",
        "res://tests/drowned_harbor_controlled_private_shield_test.gd",
        "res://tests/drowned_harbor_high_water_transformation_test.gd",
        "res://tests/drowned_harbor_prototype_isolation_test.gd",
        "p019-drowned-harbor-automation-evidence",
    ):
        require(command in p019, f"P0.19 workflow command missing: {command}")
    require("agent/p0.19-drowned-harbor-prototype-automation" in p019, "P0.19 branch gate missing")
    for path in AUTHORIZED_PATHS:
        require(f"'{path}'," in p019, f"P0.19 exact path boundary missing: {path}")
    require("actual != expected" in p019 and "expected = {" in p019, "exact path comparison missing")
    require("if: always()" in p019, "failure evidence upload missing")
    require("git status --porcelain" in p019, "P0.19 cleanliness proof missing")
    require(
        "res://tests/drowned_harbor_prototype_automation_test.gd" in godot,
        "general Godot workflow lacks aggregate step",
    )
    for token in (
        "native-export",
        "bundle-export",
        "p019-drowned-harbor-export-exclusion-evidence",
        "if: always()",
        "p019-windows-native.status",
        "p019-linux-native.status",
        "p019-windows-bundle.status",
        "p019-linux-bundle.status",
    ):
        require(token in portable, f"portable P0.19 integration missing: {token}")


def validate_documentation(technical: str, summary: str, readme: str) -> None:
    combined = "\n".join((technical, summary, readme)).lower()
    for phrase in (
        "dh-fix-005",
        "projection-only",
        "deterministic",
        "deadlock",
        "generated evidence",
        "lantern house",
        "issue #39",
        "no new gameplay",
        "no successor",
    ):
        require(phrase in combined, f"documentation obligation missing: {phrase}")
    for forbidden in (
        "privacy certified",
        "security certified",
        "accessibility compliant",
        "human validated",
        "production ready",
        "controller validated",
        "television validated",
    ):
        require(forbidden not in combined, f"documentation makes forbidden claim: {forbidden}")
    require(re.search(r"\b\d+/\d+ mutations? passed\b", combined) is None, "documentation predeclares mutation count")


def forbidden_markers(
    profile: dict[str, Any], package: dict[str, Any], manifest: dict[str, Any]
) -> list[tuple[str, bytes]]:
    markers: list[tuple[str, bytes]] = []
    inventory = profile["forbidden_export_inventory"]
    for index, value in enumerate(inventory["path_prefixes"], 1):
        markers.append((f"path_prefix_{index}", value.encode()))
    for value in inventory["fixture_ids"]:
        markers.append((f"fixture_{value[-3:]}", value.encode()))
    for index, value in enumerate(inventory["public_markers"], 1):
        markers.append((f"public_marker_{index}", value.encode()))
    filenames = sorted(
        {PurePosixPath(value.removeprefix("res://")).name for value in EXPECTED_ENTRY_POINTS + EXPECTED_COMPONENTS}
    )
    for index, value in enumerate(filenames, 1):
        markers.append((f"prototype_filename_{index}", value.encode()))
    for index, value in enumerate(sorted(private_sentinels(package)), 1):
        markers.append((f"private_sentinel_{index:02d}", value.encode()))
    unique: dict[bytes, str] = {}
    for identifier, marker in markers:
        unique.setdefault(marker, identifier)
    return [(identifier, marker) for marker, identifier in unique.items()]


def scan_bytes(data: bytes, markers: list[tuple[str, bytes]]) -> list[str]:
    return [identifier for identifier, marker in markers if marker in data]


def write_evidence(path: Path, evidence: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(evidence, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def validate_source_sha(value: str) -> None:
    require(SOURCE_SHA.fullmatch(value) is not None, "source SHA must be exact lowercase hex-40")


def verify_native_export(
    root: Path,
    platform: str,
    source_sha: str,
    preset: str,
    native: Path,
    export_log: Path,
    output: Path | None = None,
) -> dict[str, Any]:
    validate_source_sha(source_sha)
    expected = {"windows": "Internal Windows x86_64", "linux": "Internal Linux x86_64"}
    require(platform in expected and preset == expected[platform], "platform or preset identity drifted")
    require(native.is_file(), "native export missing")
    require(export_log.is_file(), "export log missing")
    profile = read_json(root / PROFILE_PATH)
    package = read_json(root / FIXTURE_PATH)
    manifest = read_json(root / MANIFEST_PATH)
    markers = forbidden_markers(profile, package, manifest)
    log_hits = scan_bytes(export_log.read_bytes(), markers)
    native_hits = scan_bytes(native.read_bytes(), markers)
    require(not log_hits, "export log contains forbidden test/prototype material")
    require(not native_hits, "native export contains forbidden test/prototype material")
    evidence = {
        "platform": platform,
        "source_sha": source_sha,
        "preset": preset,
        "native_file_size": native.stat().st_size,
        "native_sha256": sha256_file(native),
        "export_log_sha256": sha256_file(export_log),
        "bundle_inventory_digest": "not_applicable_native_phase",
        "bundle_manifest_digest": "not_applicable_native_phase",
        "catalog_digest": CATALOG_DIGEST,
        "lantern_house_package_digest": LANTERN_DIGEST,
        "forbidden_path_hit_count": 0,
        "forbidden_marker_hit_count": 0,
        "result_classification": "p019_native_export_exclusion_pass",
        "human_evidence_claimed": False,
    }
    if output is not None:
        write_evidence(output, evidence)
    return evidence


def bundle_inventory(bundle: Path) -> tuple[list[dict[str, Any]], str]:
    records = []
    for path in sorted(value for value in bundle.rglob("*") if value.is_file()):
        records.append({
            "path": path.relative_to(bundle).as_posix(),
            "size": path.stat().st_size,
            "sha256": sha256_file(path),
        })
    return records, canonical_sha256(records)


def verify_bundle_export(
    root: Path,
    platform: str,
    source_sha: str,
    preset: str,
    native: Path,
    export_log: Path,
    bundle: Path,
    output: Path | None = None,
) -> dict[str, Any]:
    native_evidence = verify_native_export(root, platform, source_sha, preset, native, export_log)
    require(bundle.is_dir(), "assembled bundle missing")
    profile = read_json(root / PROFILE_PATH)
    package = read_json(root / FIXTURE_PATH)
    manifest = read_json(root / MANIFEST_PATH)
    markers = forbidden_markers(profile, package, manifest)
    records, inventory_digest = bundle_inventory(bundle)
    path_hits = [item["path"] for item in records if "tests/" in item["path"] or "drowned_harbor" in item["path"].lower()]
    marker_hits: set[str] = set()
    for path in (value for value in bundle.rglob("*") if value.is_file()):
        marker_hits.update(scan_bytes(path.read_bytes(), markers))
    require(not path_hits, "bundle inventory contains a forbidden prototype path")
    require(not marker_hits, "bundle bytes contain a forbidden prototype marker")
    manifest_path = bundle / "build_manifest.json"
    require(manifest_path.is_file(), "bundle build manifest missing")
    bundle_manifest = read_json(manifest_path)
    require(bundle_manifest.get("source_commit") == source_sha, "bundle source SHA mismatch")
    require(bundle_manifest.get("platform") == platform, "bundle platform mismatch")
    require(bundle_manifest.get("tale_catalog", {}).get("sha256") == CATALOG_DIGEST, "bundle catalog identity drifted")
    require(bundle_manifest.get("tale_package", {}).get("sha256") == LANTERN_DIGEST, "bundle Lantern identity drifted")
    evidence = dict(native_evidence)
    evidence.update({
        "bundle_inventory_digest": inventory_digest,
        "bundle_manifest_digest": sha256_file(manifest_path),
        "bundle_file_count": len(records),
        "forbidden_path_hit_count": 0,
        "forbidden_marker_hit_count": 0,
        "result_classification": "p019_bundle_export_exclusion_pass",
    })
    if output is not None:
        write_evidence(output, evidence)
    return evidence


def validate(root: Path = ROOT) -> tuple[str, int]:
    profile = read_json(root / PROFILE_PATH)
    manifest = read_json(root / MANIFEST_PATH)
    package = read_json(root / FIXTURE_PATH)
    schema = read_json(root / SCHEMA_PATH)
    validate_profile(profile)
    validate_manifest(manifest)
    validate_fixture_and_schema(package, schema)
    validate_uid(root)
    validate_godot_source(
        (root / TEST_PATH).read_text(encoding="utf-8"),
        (root / ISOLATION_TEST_PATH).read_text(encoding="utf-8"),
    )
    validate_production_boundary(
        profile,
        read_json(root / CATALOG_PATH),
        read_json(root / LANTERN_PATH),
        (root / PROVIDER_PATH).read_text(encoding="utf-8"),
        (root / PROJECT_PATH).read_text(encoding="utf-8"),
        (root / EXPORT_PRESETS_PATH).read_text(encoding="utf-8"),
    )
    validate_workflows(
        (root / WORKFLOW_PATH).read_text(encoding="utf-8"),
        (root / GODOT_WORKFLOW_PATH).read_text(encoding="utf-8"),
        (root / PORTABLE_WORKFLOW_PATH).read_text(encoding="utf-8"),
    )
    validate_documentation(
        (root / TECHNICAL_PATH).read_text(encoding="utf-8"),
        (root / SUMMARY_PATH).read_text(encoding="utf-8"),
        (root / README_PATH).read_text(encoding="utf-8"),
    )
    markers = forbidden_markers(profile, package, manifest)
    return sha256_file(root / PROFILE_PATH), len(markers)


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser()
    sub = result.add_subparsers(dest="command")
    for name in ("native-export", "bundle-export"):
        command = sub.add_parser(name)
        command.add_argument("--platform", choices=("windows", "linux"), required=True)
        command.add_argument("--source-sha", required=True)
        command.add_argument("--preset", required=True)
        command.add_argument("--native", type=Path, required=True)
        command.add_argument("--export-log", type=Path, required=True)
        command.add_argument("--output", type=Path, required=True)
        if name == "bundle-export":
            command.add_argument("--bundle", type=Path, required=True)
    return result


def main(argv: list[str] | None = None) -> int:
    args = parser().parse_args(argv)
    try:
        if args.command == "native-export":
            evidence = verify_native_export(
                ROOT, args.platform, args.source_sha, args.preset,
                args.native, args.export_log, args.output,
            )
            print(json.dumps(evidence, sort_keys=True))
            return 0
        if args.command == "bundle-export":
            evidence = verify_bundle_export(
                ROOT, args.platform, args.source_sha, args.preset,
                args.native, args.export_log, args.bundle, args.output,
            )
            print(json.dumps(evidence, sort_keys=True))
            return 0
        profile_digest, marker_count = validate(ROOT)
    except (AutomationValidationError, OSError, subprocess.CalledProcessError) as exc:
        print(f"Drowned Harbor P0.19 automation validation failed: {exc}", file=sys.stderr)
        return 1
    print(
        "Validated P0.19 automation profile, matrix, isolation, workflows, "
        f"and {marker_count} closed export markers; profile digest {profile_digest}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
