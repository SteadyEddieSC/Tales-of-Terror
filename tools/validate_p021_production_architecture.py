#!/usr/bin/env python3
"""Validate the frozen merged P0.21 production architecture contract."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

ROOT = Path(".")
P021_BASELINE = "58f6f4e4ece9bbdd5932216c87aacc064e48e05a"
P021_MERGE = "4efdd76efdf2aa34823dae5d3624a3dca3f0a349"
CONTRACT_PATH = Path("docs/preproduction/drowned_harbor_production_compilation_contract_v1.json")
SCHEMA_PATH = Path("docs/preproduction/drowned_harbor_production_compilation_contract_schema_v1.json")
TECHNICAL_PATH = Path("docs/technical/Drowned_Harbor_Production_Architecture_and_Compilation_Contract_v1.md")
SUMMARY_PATH = Path("docs/preproduction/P0.21_Release_Summary.md")
STATUS_PATH = Path("docs/preproduction/post_prototype_status_v1.json")

IMMUTABLE_INPUTS = {
    "docs/preproduction/tale_authoring_reference_schema_v1.json",
    "docs/tales/drowned_harbor/authoring/drowned_harbor_authoring_reference_v1.json",
    "docs/technical/Tale_Authoring_Reference_Contract_v1.md",
    "docs/technical/Tale_Catalog_Contract.md",
    "docs/technical/Tale_Package_Contract.md",
    "docs/technical/Tale_Runtime_Providers.md",
}
EXPECTED_ROOT = {
    "contract_kind",
    "schema_version",
    "release",
    "authorization",
    "immutable_inputs",
    "compilation_pipeline",
    "authority_ownership",
    "admission",
    "persistence",
    "localization_and_assets",
    "rollback",
    "implementation_stages",
    "evidence_boundaries",
}
EXPECTED_STAGES = [
    "v0.2.0-alpha.1",
    "v0.2.0-alpha.2",
    "v0.2.0-alpha.3",
    "v0.2.0-beta",
    "v0.2.0-rc",
]


class ValidationError(ValueError):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValidationError(message)


def read_text(root: Path, path: Path) -> str:
    try:
        return (root / path).read_text(encoding="utf-8")
    except FileNotFoundError as exc:
        raise ValidationError(f"missing file: {path}") from exc


def read_json(root: Path, path: Path) -> dict[str, Any]:
    try:
        value = json.loads(read_text(root, path))
    except json.JSONDecodeError as exc:
        raise ValidationError(f"invalid JSON: {path}: {exc}") from exc
    require(isinstance(value, dict), f"JSON root must be object: {path}")
    return value


def validate_schema(schema: dict[str, Any]) -> None:
    require(schema.get("$schema") == "https://json-schema.org/draft/2020-12/schema", "schema dialect drift")
    require(schema.get("type") == "object", "schema root type drift")
    require(schema.get("additionalProperties") is False, "schema root opened")
    require(set(schema.get("required", [])) == EXPECTED_ROOT, "schema root required drift")
    require(set(schema.get("properties", {})) == EXPECTED_ROOT, "schema root properties drift")
    props = schema["properties"]
    require(props["contract_kind"].get("const") == "drowned_harbor_production_compilation_contract", "schema kind drift")
    require(props["schema_version"].get("const") == 1, "schema version drift")
    release = props["release"]["properties"]
    require(release["release_id"].get("const") == "P0.21", "schema release drift")
    require(release["issue"].get("const") == 98, "schema issue drift")
    require(release["baseline"].get("const") == P021_BASELINE, "schema baseline drift")


def validate_contract(data: dict[str, Any]) -> None:
    require(set(data) == EXPECTED_ROOT, "P0.21 contract root drift")
    require(data.get("contract_kind") == "drowned_harbor_production_compilation_contract", "contract kind drift")
    require(data.get("schema_version") == 1, "contract schema drift")
    require(data.get("release") == {
        "release_id": "P0.21",
        "issue": 98,
        "baseline": P021_BASELINE,
        "branch": "docs/p0.21-production-architecture-contract",
        "state": "active_planning",
    }, "P0.21 release identity drift")
    auth = data.get("authorization", {})
    require(auth.get("planning_only") is True, "P0.21 planning-only flag drift")
    for key in (
        "runtime_implementation",
        "production_package",
        "provider_registration",
        "catalog_registration",
        "normal_library_visibility",
        "ordinary_export_inclusion",
        "successor_issue_created",
        "human_evidence_claimed",
    ):
        require(auth.get(key) is False, f"P0.21 authorization drift: {key}")
    immutable = data.get("immutable_inputs")
    require(isinstance(immutable, list) and len(immutable) == 6, "immutable input inventory drift")
    require({row.get("path") for row in immutable} == IMMUTABLE_INPUTS, "immutable path drift")
    require(all(row.get("runtime_input") is False for row in immutable), "authoring input became runtime")
    pipeline = data.get("compilation_pipeline", {})
    require(pipeline.get("runtime_input") is False, "compilation input became runtime")
    require(len(pipeline.get("target_outputs", [])) == 11, "target output inventory drift")
    require("dynamic_provider_registration" in pipeline.get("prohibited_features", []), "dynamic registration prohibition missing")
    ownership = data.get("authority_ownership", {})
    require(ownership.get("stage_progression") == "rules_session_reducer", "stage owner drift")
    require(ownership.get("director_inputs") == "public_and_authorized_aggregate_state_only", "Director boundary drift")
    require(ownership.get("rejected_action_policy") == "state_and_rng_noop_for_invalid_stale_duplicate_wrong_seat_or_unavailable", "rejection policy drift")
    require(set(ownership.get("privacy_classes", [])) == {"public", "controlled_reveal_private", "seat_private", "faction_private"}, "privacy classes drift")
    admission = data.get("admission", {})
    require(admission.get("normal_default_tale") == "lantern_house_vertical_slice", "default Tale drift")
    require(admission.get("normal_production_tale_count") == 1, "normal Tale count drift")
    require(admission.get("normal_library_visible") is False, "normal visibility drift")
    require(admission.get("ordinary_export_included") is False, "ordinary export drift")
    persistence = data.get("persistence", {})
    require(persistence.get("migration_policy") == "explicit_versioned_migration_or_fail_closed", "migration drift")
    require(persistence.get("snapshot_selection") == "select_validated_tale_identity_before_restore", "restore identity drift")
    stages = data.get("implementation_stages")
    require([stage.get("release_id") for stage in stages] == EXPECTED_STAGES, "stage inventory drift")
    require(all(stage.get("state") == "planned_blocked" for stage in stages), "P0.21 historical stage state drift")
    require(all(stage.get("github_issue") is None for stage in stages), "P0.21 historical issue inventory drift")
    require(all(stage.get("activation_authorized") is False for stage in stages), "P0.21 historical activation drift")
    evidence = data.get("evidence_boundaries", {})
    require(evidence and all(value is False for value in evidence.values()), "P0.21 evidence claim drift")


def validate_docs(root: Path) -> None:
    technical = read_text(root, TECHNICAL_PATH)
    summary = read_text(root, SUMMARY_PATH)
    for phrase in (
        "authoring reference and its content manifests are compilation inputs only",
        "Invalid, stale, duplicate, wrong-seat, unavailable, or malformed actions must leave state and RNG unchanged",
        "developer_only_explicit_launch",
        "Automation is not human evidence",
    ):
        require(phrase in technical, f"P0.21 technical contract missing: {phrase}")
    for phrase in (
        "It does not compile, register, expose, or ship Drowned Harbor",
        "P0.1–P0.20 remain recorded as merged",
        "Automation is not human evidence",
    ):
        require(phrase in summary, f"P0.21 summary missing: {phrase}")


def validate_current_status(root: Path) -> None:
    status = read_json(root, STATUS_PATH)
    architecture = status.get("production_architecture", {})
    require(architecture.get("state") == "merged_authority", "P0.21 architecture not recorded merged")
    require(architecture.get("merged_main_sha") == P021_MERGE, "P0.21 merge SHA drift")
    require(architecture.get("runtime_input") is False, "P0.21 contract became runtime input")
    require(architecture.get("normal_library_visible") is False, "P0.21 changed normal visibility")
    require(architecture.get("ordinary_export_included") is False, "P0.21 changed export boundary")
    releases = status.get("preproduction_releases", [])
    require(any(row.get("release_id") == "P0.21" and row.get("pull_request") == 99 and row.get("merged_main_sha") == P021_MERGE for row in releases), "P0.21 history record missing")


def validate(root: Path = ROOT, check_git: bool = False) -> None:
    del check_git
    for path in IMMUTABLE_INPUTS:
        require((root / path).is_file(), f"immutable authority missing: {path}")
    validate_schema(read_json(root, SCHEMA_PATH))
    validate_contract(read_json(root, CONTRACT_PATH))
    validate_docs(root)
    validate_current_status(root)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--skip-git-boundary", action="store_true")
    args = parser.parse_args()
    try:
        validate(args.root, check_git=False)
    except ValidationError as exc:
        print(f"P0.21 frozen architecture validation failed: {exc}")
        return 1
    print("P0.21 frozen production architecture contract validated")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
