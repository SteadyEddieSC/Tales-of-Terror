#!/usr/bin/env python3
"""Validate the P0.13 Drowned Harbor development-only isolation boundary."""

from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path
from typing import Any

ROOT = Path(".")
MANIFEST_PATH = Path("game/tests/drowned_harbor_prototype_manifest_v1.json")
CATALOG_PATH = Path("game/data/tales/tale_catalog_v1.json")
PROVIDER_PATH = Path("game/src/session/tale_provider_registry.gd")
EXPORT_PRESETS_PATH = Path("game/export_presets.cfg")
README_PATH = Path("README.md")
GODOT_TEST_PATH = Path("game/tests/drowned_harbor_prototype_isolation_test.gd")
EXPECTED_CATALOG_DIGEST = "2b478fd0d11fa075c2050409193aa06e6b9ca4dcf6efd4e4c550a9f3a5ff9db6"
EXPECTED_MANIFEST_FIELDS = {
    "prototype_kind",
    "schema_version",
    "prototype_id",
    "tale_id",
    "display_name",
    "status",
    "launch_policy",
    "allowed_entry_points",
    "production_catalog_path",
    "production_catalog_sha256",
    "production_tale_id",
    "production_catalog_registered",
    "production_provider_registered",
    "normal_tale_library_visible",
    "playable_export_authorized",
    "runtime_authority_created",
    "dependencies",
    "export_policy",
    "source_authorities",
    "future_work_issues",
    "human_validation_required",
    "human_evidence_claimed",
    "notes",
}
EXPECTED_DEPENDENCY_FIELDS = {
    "network",
    "companion",
    "credentials",
    "telemetry",
    "cloud",
    "production_assets",
}
EXPECTED_EXPORT_FIELDS = {
    "required_exclusion_pattern",
    "internal_windows_preset",
    "internal_linux_preset",
    "ordinary_exports_include_prototype",
}


class IsolationValidationError(ValueError):
    """Raised when the development-only boundary is weakened."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise IsolationValidationError(message)


def read_json(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise IsolationValidationError(f"required file does not exist: {path}") from exc
    except json.JSONDecodeError as exc:
        raise IsolationValidationError(f"invalid JSON in {path}: {exc}") from exc
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


def validate_manifest(manifest: dict[str, Any], root: Path = ROOT) -> None:
    require(set(manifest) == EXPECTED_MANIFEST_FIELDS, "prototype manifest fields do not match the closed contract")
    require(manifest["prototype_kind"] == "isolated_tale_prototype", "unexpected prototype kind")
    require(manifest["schema_version"] == 1, "unsupported prototype schema")
    require(manifest["prototype_id"] == "drowned_harbor_dev_only", "prototype identity must remain unmistakably dev-only")
    require(manifest["tale_id"] == "drowned_harbor", "unexpected design Tale ID")
    require("Not Shipped" in manifest["display_name"], "display name must state that the prototype is not shipped")
    require(manifest["status"] == "development_only_export_excluded", "prototype status must remain development-only and export-excluded")
    require(manifest["launch_policy"] == "explicit_test_script_only", "prototype launch must remain explicit and test-only")

    entry_points = manifest["allowed_entry_points"]
    require(isinstance(entry_points, list) and entry_points, "prototype requires at least one explicit test-only entry point")
    require(len(entry_points) == len(set(entry_points)), "prototype entry points contain duplicates")
    for entry_point in entry_points:
        require(isinstance(entry_point, str) and entry_point.startswith("res://tests/"), "every prototype entry point must stay under res://tests/")
        local_path = root / "game" / entry_point.removeprefix("res://")
        require(local_path.is_file(), f"prototype entry point does not exist: {entry_point}")

    require(manifest["production_catalog_path"] == "res://data/tales/tale_catalog_v1.json", "prototype must reference the accepted production catalog")
    require(manifest["production_catalog_sha256"] == EXPECTED_CATALOG_DIGEST, "prototype catalog identity drifted")
    require(manifest["production_tale_id"] == "lantern_house_vertical_slice", "Lantern House must remain the production Tale")
    for field in (
        "production_catalog_registered",
        "production_provider_registered",
        "normal_tale_library_visible",
        "playable_export_authorized",
        "runtime_authority_created",
        "human_evidence_claimed",
    ):
        require(manifest[field] is False, f"{field} must remain false")
    require(manifest["human_validation_required"] is True, "future human validation must remain required")

    dependencies = manifest["dependencies"]
    require(isinstance(dependencies, dict) and set(dependencies) == EXPECTED_DEPENDENCY_FIELDS, "dependency fields do not match the closed contract")
    require(all(value is False for value in dependencies.values()), "prototype may not add network, Companion, credential, telemetry, cloud, or production-asset dependencies")

    export_policy = manifest["export_policy"]
    require(isinstance(export_policy, dict) and set(export_policy) == EXPECTED_EXPORT_FIELDS, "export policy fields do not match the closed contract")
    require(export_policy["required_exclusion_pattern"] == "tests/*", "prototype must stay behind the existing tests/* export exclusion")
    require(export_policy["internal_windows_preset"] == "Internal Windows x86_64", "unexpected Windows export preset")
    require(export_policy["internal_linux_preset"] == "Internal Linux x86_64", "unexpected Linux export preset")
    require(export_policy["ordinary_exports_include_prototype"] is False, "ordinary exports may not include the prototype")

    source_authorities = manifest["source_authorities"]
    require(isinstance(source_authorities, list) and len(source_authorities) >= 4, "prototype must retain its governing sources")
    require(len(source_authorities) == len(set(source_authorities)), "source authorities contain duplicates")
    for source_path in source_authorities:
        require(isinstance(source_path, str) and not source_path.startswith(("/", "http://", "https://")), "source authority must be repository-relative")
        require((root / source_path).is_file(), f"source authority does not exist: {source_path}")

    require(manifest["future_work_issues"] == [81, 82, 83, 84, 85, 86], "future work issue set must remain #81 through #86")
    notes = manifest["notes"]
    require(isinstance(notes, str) and len(notes) >= 180, "prototype notes must preserve the evidence boundary")
    for phrase in (
        "does not make Drowned Harbor playable",
        "controller-validated",
        "privacy-certified",
        "accessibility-compliant",
    ):
        require(phrase in notes, f"prototype notes missing boundary phrase: {phrase}")


def validate_production_catalog(root: Path = ROOT) -> None:
    catalog = read_json(root / CATALOG_PATH)
    require(canonical_sha256(catalog) == EXPECTED_CATALOG_DIGEST, "production Tale catalog canonical digest changed")
    require(catalog.get("catalog_kind") == "tale_catalog", "unexpected production catalog kind")
    require(catalog.get("schema_version") == 1 and catalog.get("catalog_version") == 1, "unsupported production catalog version")
    require(catalog.get("default_tale_id") == "lantern_house_vertical_slice", "production default must remain Lantern House")
    entries = catalog.get("entries")
    require(isinstance(entries, list) and len(entries) == 1, "production catalog must contain exactly one Tale")
    require(entries[0].get("tale_id") == "lantern_house_vertical_slice", "only production Tale must remain Lantern House")
    catalog_text = json.dumps(catalog, ensure_ascii=False).lower()
    require("drowned_harbor" not in catalog_text, "production catalog may not reference Drowned Harbor")
    require("res://tests/" not in catalog_text, "production catalog may not reference test-only paths")

    provider_text = (root / PROVIDER_PATH).read_text(encoding="utf-8").lower()
    require("drowned_harbor" not in provider_text, "production provider registry may not reference Drowned Harbor")
    require(not (root / "game/data/tales/drowned_harbor").exists(), "Drowned Harbor production Tale directory may not exist")


def validate_export_boundary(root: Path = ROOT) -> None:
    preset_text = (root / EXPORT_PRESETS_PATH).read_text(encoding="utf-8")
    require(preset_text.count('name="Internal Windows x86_64"') == 1, "Windows internal export preset missing or duplicated")
    require(preset_text.count('name="Internal Linux x86_64"') == 1, "Linux internal export preset missing or duplicated")
    require(preset_text.count("tests/*") == 2, "both export presets must exclude tests/*")
    require("drowned_harbor_prototype_manifest_v1.json" not in preset_text, "export preset may not explicitly include the prototype manifest")
    require("drowned_harbor_prototype_isolation_test.gd" not in preset_text, "export preset may not explicitly include the prototype test")


def validate_readme(root: Path = ROOT) -> None:
    readme = (root / README_PATH).read_text(encoding="utf-8")
    for heading in (
        "## Elevator pitch",
        "## What exists today",
        "## What the finished game is aiming for",
        "## Story mode: Tales",
        "## Current production Tale: Lantern House",
        "## Future Tale in design: Drowned Harbor",
    ):
        require(heading in readme, f"README missing required section: {heading}")
    for phrase in (
        "internal vertical slice",
        "not a finished game",
        "Lantern House remains the sole production Tale",
        "Drowned Harbor is not a production Tale",
        "automation is not human evidence",
        "working title",
    ):
        require(phrase.lower() in readme.lower(), f"README missing required status phrase: {phrase}")
    require("1–8" in readme or "1-8" in readme, "README must retain supported stable-seat range")
    require("The Underteller" in readme, "README must explain the provisional host")
    require("Living Board" in readme, "README must explain the Living Board concept")
    require("Restless" in readme, "README must explain meaningful play after defeat")


def validate(root: Path = ROOT) -> None:
    require((root / MANIFEST_PATH).is_file(), f"required manifest missing: {MANIFEST_PATH}")
    require((root / GODOT_TEST_PATH).is_file(), f"required Godot test missing: {GODOT_TEST_PATH}")
    validate_manifest(read_json(root / MANIFEST_PATH), root)
    validate_production_catalog(root)
    validate_export_boundary(root)
    validate_readme(root)


def main() -> int:
    try:
        validate(ROOT)
    except (IsolationValidationError, OSError) as exc:
        print(f"Drowned Harbor prototype isolation validation failed: {exc}", file=sys.stderr)
        return 1
    print("Validated Drowned Harbor dev-only isolation, Lantern House production exclusivity, export exclusion, and README vision boundary")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
