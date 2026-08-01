#!/usr/bin/env python3
"""Fail-closed mutation tests for the P0.21 architecture validator."""

from __future__ import annotations

import json
import shutil
import tempfile
from pathlib import Path

from validate_p021_production_architecture import (
    CONTRACT_PATH,
    IMMUTABLE_INPUTS,
    ISSUE_SET_PATH,
    PREPROD_README_PATH,
    README_PATH,
    ROADMAP_PATH,
    SCHEMA_PATH,
    STATUS_PATH,
    SUMMARY_PATH,
    TECHNICAL_PATH,
    ValidationError,
    validate,
)

ROOT = Path(".")


def copy_fixture(target: Path) -> None:
    paths = {
        CONTRACT_PATH,
        SCHEMA_PATH,
        STATUS_PATH,
        TECHNICAL_PATH,
        ISSUE_SET_PATH,
        SUMMARY_PATH,
        README_PATH,
        PREPROD_README_PATH,
        ROADMAP_PATH,
    } | {Path(path) for path in IMMUTABLE_INPUTS}
    for path in paths:
        destination = target / path
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(ROOT / path, destination)


def edit_json(target: Path, path: Path, mutate) -> None:
    full = target / path
    data = json.loads(full.read_text(encoding="utf-8"))
    mutate(data)
    full.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")


def replace_text(target: Path, path: Path, old: str, new: str) -> None:
    full = target / path
    content = full.read_text(encoding="utf-8")
    if old not in content:
        raise AssertionError(f"test fixture missing text: {old}")
    full.write_text(content.replace(old, new, 1), encoding="utf-8")


def expect_failure(name: str, mutate) -> None:
    with tempfile.TemporaryDirectory(prefix="p021-mutation-") as directory:
        target = Path(directory)
        copy_fixture(target)
        mutate(target)
        try:
            validate(target, check_git=False)
        except ValidationError:
            print(f"PASS {name}")
            return
        raise AssertionError(f"mutation unexpectedly passed: {name}")


def main() -> int:
    mutations = [
        (
            "nested_schema_opened",
            lambda root: edit_json(root, SCHEMA_PATH, lambda data: data["properties"]["authority_ownership"].update(additionalProperties=True)),
        ),
        (
            "runtime_authorized",
            lambda root: edit_json(root, CONTRACT_PATH, lambda data: data["authorization"].update(runtime_implementation=True)),
        ),
        (
            "catalog_registered",
            lambda root: edit_json(root, CONTRACT_PATH, lambda data: data["authorization"].update(catalog_registration=True)),
        ),
        (
            "authoring_becomes_runtime_input",
            lambda root: edit_json(root, CONTRACT_PATH, lambda data: data["immutable_inputs"][1].update(runtime_input=True)),
        ),
        (
            "target_output_removed",
            lambda root: edit_json(root, CONTRACT_PATH, lambda data: data["compilation_pipeline"].update(target_outputs=data["compilation_pipeline"]["target_outputs"][:-1])),
        ),
        (
            "dynamic_registration_enabled",
            lambda root: edit_json(root, CONTRACT_PATH, lambda data: data["admission"].update(dynamic_registration=True)),
        ),
        (
            "director_reads_private_state",
            lambda root: edit_json(root, CONTRACT_PATH, lambda data: data["authority_ownership"].update(director_inputs="all_private_state")),
        ),
        (
            "privacy_class_removed",
            lambda root: edit_json(root, CONTRACT_PATH, lambda data: data["authority_ownership"].update(privacy_classes=data["authority_ownership"]["privacy_classes"][:-1])),
        ),
        (
            "rejected_action_mutates_rng",
            lambda root: edit_json(root, CONTRACT_PATH, lambda data: data["authority_ownership"].update(rejected_action_policy="state_noop_rng_may_advance")),
        ),
        (
            "best_effort_migration",
            lambda root: edit_json(root, CONTRACT_PATH, lambda data: data["persistence"].update(migration_policy="best_effort_field_matching")),
        ),
        (
            "successor_issue_created",
            lambda root: edit_json(root, CONTRACT_PATH, lambda data: data["implementation_stages"][0].update(github_issue=100)),
        ),
        (
            "successor_activated",
            lambda root: edit_json(root, CONTRACT_PATH, lambda data: data["implementation_stages"][0].update(activation_authorized=True)),
        ),
        (
            "human_evidence_claimed",
            lambda root: edit_json(root, CONTRACT_PATH, lambda data: data["evidence_boundaries"].update(fun_validated=True)),
        ),
        (
            "status_returns_to_p020",
            lambda root: edit_json(root, STATUS_PATH, lambda data: data["current_release"].update(release_id="P0.20")),
        ),
        (
            "roadmap_marks_runtime_active",
            lambda root: replace_text(root, ROADMAP_PATH, "Only P0.21 is active", "v0.2.0-alpha.1 is active runtime"),
        ),
        (
            "technical_drops_human_boundary",
            lambda root: replace_text(root, TECHNICAL_PATH, "Automation is not human evidence", "Automation proves human experience"),
        ),
        (
            "readme_claims_drowned_production",
            lambda root: replace_text(root, README_PATH, "Drowned Harbor is not a production Tale and is not ordinarily playable", "Drowned Harbor is a production Tale and is ordinarily playable"),
        ),
    ]
    for name, mutation in mutations:
        expect_failure(name, mutation)
    print(f"P0.21 mutation suite passed: {len(mutations)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
