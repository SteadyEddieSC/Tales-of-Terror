#!/usr/bin/env python3
"""Validate inherited Drowned Harbor fixtures against P0.16 progression."""

from __future__ import annotations

import sys
from pathlib import Path
from typing import Any

import validate_drowned_harbor_projection_fixtures as inherited

ROOT = Path(".")


def validate_prototype_manifest(root: Path = ROOT) -> None:
    """Retain the inherited engine while advancing through issue #84."""
    manifest: dict[str, Any] = inherited.read_json(
        root / inherited.PROTOTYPE_MANIFEST_PATH
    )
    inherited.require(
        manifest.get("completed_work_issues") == [80, 81, 82, 83, 84],
        "prototype manifest must record completed work issues #80 through #84",
    )
    inherited.require(
        manifest.get("future_work_issues") == [85, 86],
        "prototype manifest must leave issues #85 and #86 as future work",
    )
    inherited.require(
        manifest.get("fixture_packages")
        == [
            "res://tests/drowned_harbor_dev_only/"
            "state_projection_fixtures_v1.json"
        ],
        "prototype manifest fixture package registration drifted",
    )
    for field in (
        "production_catalog_registered",
        "production_provider_registered",
        "normal_tale_library_visible",
        "playable_export_authorized",
        "runtime_authority_created",
        "human_evidence_claimed",
    ):
        inherited.require(
            manifest.get(field) is False,
            f"prototype manifest {field} must remain false",
        )


def validate(root: Path = ROOT) -> tuple[int, int]:
    """Run the inherited fixture engine with P0.16 manifest progression."""
    original = inherited.validate_prototype_manifest
    inherited.validate_prototype_manifest = validate_prototype_manifest
    try:
        return inherited.validate(root)
    finally:
        inherited.validate_prototype_manifest = original


def main() -> int:
    try:
        fixture_count, negative_count = validate(ROOT)
    except (inherited.ProjectionFixtureError, OSError) as exc:
        print(
            f"Drowned Harbor P0.16 projection compatibility failed: {exc}",
            file=sys.stderr,
        )
        return 1
    package = inherited.read_json(ROOT / inherited.PACKAGE_PATH)
    print(
        "Validated inherited projection engine through P0.17: "
        f"{fixture_count} fixtures, {negative_count} fail-closed request cases, "
        f"canonical identity {inherited.canonical_sha256(package)}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
