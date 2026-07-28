#!/usr/bin/env python3
"""Retain the P0.15 Low Tide proof after P0.16 manifest progression."""

from __future__ import annotations

import json
import sys
from pathlib import Path, PurePosixPath

import validate_drowned_harbor_low_tide_shell as inherited

ROOT = Path(".")
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


def validate_manifest_and_production_boundary(root: Path = ROOT) -> None:
    """Validate P0.16 progression without weakening the Low Tide contract."""
    manifest = inherited.read_json(root / inherited.MANIFEST_PATH)
    inherited.require(
        manifest.get("completed_work_issues") == [80, 81, 82, 83, 84],
        "manifest must record issue #84 as completed bounded work",
    )
    inherited.require(
        manifest.get("future_work_issues") == [85, 86],
        "issues #85 and #86 must remain future work",
    )
    inherited.require(
        manifest.get("allowed_entry_points") == EXPECTED_ENTRY_POINTS,
        "manifest entry-point set drifted",
    )
    inherited.require(
        manifest.get("prototype_components") == EXPECTED_COMPONENTS,
        "manifest component set drifted",
    )
    for field in (
        "production_catalog_registered",
        "production_provider_registered",
        "normal_tale_library_visible",
        "playable_export_authorized",
        "runtime_authority_created",
        "human_evidence_claimed",
    ):
        inherited.require(manifest.get(field) is False, f"{field} must remain false")
    inherited.require(
        manifest.get("human_validation_required") is True,
        "human validation must remain required",
    )

    catalog = inherited.read_json(root / inherited.CATALOG_PATH)
    inherited.require(
        inherited.canonical_sha256(catalog) == inherited.EXPECTED_CATALOG_DIGEST,
        "production Tale catalog canonical digest changed",
    )
    inherited.require(
        catalog.get("default_tale_id") == "lantern_house_vertical_slice",
        "production default must remain Lantern House",
    )
    entries = catalog.get("entries")
    inherited.require(
        isinstance(entries, list)
        and len(entries) == 1
        and entries[0].get("tale_id") == "lantern_house_vertical_slice",
        "production catalog must remain Lantern House-only",
    )
    inherited.require(
        "drowned_harbor" not in json.dumps(catalog).lower(),
        "production catalog may not reference Drowned Harbor",
    )
    provider = (root / inherited.PROVIDER_PATH).read_text(encoding="utf-8").lower()
    inherited.require(
        "drowned_harbor" not in provider,
        "production provider may not reference Drowned Harbor",
    )
    inherited.require(
        'packedstringarray([lantern_house_provider_id])' in provider.replace('"', ""),
        "production provider allowlist drifted",
    )
    presets = (root / inherited.EXPORT_PRESETS_PATH).read_text(encoding="utf-8")
    inherited.require(
        presets.count("tests/*") == 2,
        "both exports must exclude tests/*",
    )
    for filename in (
        inherited.ADAPTER_PATH.name,
        inherited.SHELL_PATH.name,
        inherited.SCENE_PATH.name,
        inherited.TEST_PATH.name,
        "bellhouse_fixture_adapter.gd",
        "bellhouse_decision_shell.gd",
        "bellhouse_decision_shell.tscn",
        "drowned_harbor_bellhouse_recovery_test.gd",
    ):
        inherited.require(
            filename not in presets,
            f"export preset may not explicitly include {filename}",
        )


def validate(root: Path = ROOT) -> None:
    original = inherited.validate_manifest_and_production_boundary
    path_names = ("ADAPTER_PATH", "SHELL_PATH", "SCENE_PATH", "TEST_PATH")
    original_paths = {name: getattr(inherited, name) for name in path_names}
    inherited.validate_manifest_and_production_boundary = (
        validate_manifest_and_production_boundary
    )
    for name, path in original_paths.items():
        setattr(inherited, name, PurePosixPath(path.as_posix()))
    try:
        inherited.validate(root)
    finally:
        inherited.validate_manifest_and_production_boundary = original
        for name, path in original_paths.items():
            setattr(inherited, name, path)


def main() -> int:
    try:
        validate(ROOT)
    except (inherited.LowTideShellValidationError, OSError) as exc:
        print(
            f"P0.16 inherited Low Tide compatibility failed: {exc}",
            file=sys.stderr,
        )
        return 1
    print(
        "Validated the full P0.15 Low Tide contract against P0.17 manifest progression"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
