#!/usr/bin/env python3
"""Retain the prototype-isolation contract after P0.16 progression."""

from __future__ import annotations

import copy
import sys
from pathlib import Path
from typing import Any

import validate_drowned_harbor_prototype_isolation as inherited

ROOT = Path(".")
P016_TECHNICAL_AUTHORITY = (
    "docs/technical/Drowned_Harbor_Bellhouse_Decision_Recovery_v1.md"
)
P017_TECHNICAL_AUTHORITY = (
    "docs/technical/Drowned_Harbor_Controlled_Private_Shield_Proof_v1.md"
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


def validate_manifest(manifest: dict[str, Any], root: Path = ROOT) -> None:
    """Run the inherited closed contract with P0.16 issue progression."""
    inherited.require(
        manifest.get("completed_work_issues") == [80, 81, 82, 83, 84],
        "completed prototype work must be exactly issues #80 through #84",
    )
    inherited.require(
        manifest.get("future_work_issues") == [85, 86],
        "future work issue set must remain #85 and #86",
    )
    inherited.require(
        P016_TECHNICAL_AUTHORITY in manifest.get("source_authorities", []),
        "P0.16 Bellhouse technical authority must remain registered",
    )
    inherited.require(
        P017_TECHNICAL_AUTHORITY in manifest.get("source_authorities", []),
        "P0.17 controlled-private technical authority must remain registered",
    )
    adjusted = copy.deepcopy(manifest)
    adjusted["completed_work_issues"] = [80, 81, 82]
    adjusted["future_work_issues"] = [83, 84, 85, 86]
    original_validate_manifest(adjusted, root)


original_validate_manifest = inherited.validate_manifest


def validate(root: Path = ROOT) -> None:
    original_entries = inherited.EXPECTED_ENTRY_POINTS
    original_components = inherited.EXPECTED_COMPONENTS
    original_manifest_validator = inherited.validate_manifest
    inherited.EXPECTED_ENTRY_POINTS = EXPECTED_ENTRY_POINTS
    inherited.EXPECTED_COMPONENTS = EXPECTED_COMPONENTS
    inherited.validate_manifest = validate_manifest
    try:
        inherited.validate(root)
    finally:
        inherited.EXPECTED_ENTRY_POINTS = original_entries
        inherited.EXPECTED_COMPONENTS = original_components
        inherited.validate_manifest = original_manifest_validator


def main() -> int:
    try:
        validate(ROOT)
    except (inherited.IsolationValidationError, OSError) as exc:
        print(
            f"Drowned Harbor P0.16 isolation compatibility failed: {exc}",
            file=sys.stderr,
        )
        return 1
    print(
        "Validated inherited prototype isolation through P0.17 entry points, "
        "components, issue progression, source authority, production invariance, "
        "and exports"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
