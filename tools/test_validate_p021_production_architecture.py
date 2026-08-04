#!/usr/bin/env python3
"""Fail-closed mutations for the frozen P0.21 architecture contract."""

from __future__ import annotations

import json
import shutil
import subprocess
import tempfile
from pathlib import Path

from validate_p021_production_architecture import (
    CONTRACT_PATH,
    IMMUTABLE_INPUTS,
    SCHEMA_PATH,
    STATUS_PATH,
    SUMMARY_PATH,
    TECHNICAL_PATH,
    ValidationError,
    validate,
)

ROOT = Path(".")
FROZEN_STATUS_COMMIT = "da86c0aa74bc0442862c97e3c371f6b714da4d0a"


def frozen_status_content() -> bytes:
    return subprocess.check_output(
        ["git", "show", f"{FROZEN_STATUS_COMMIT}:{STATUS_PATH.as_posix()}"],
        cwd=ROOT,
    )


def copy_fixture(target: Path) -> None:
    for path in {CONTRACT_PATH, SCHEMA_PATH, STATUS_PATH, SUMMARY_PATH, TECHNICAL_PATH} | {Path(p) for p in IMMUTABLE_INPUTS}:
        destination = target / path
        destination.parent.mkdir(parents=True, exist_ok=True)
        if path == STATUS_PATH:
            destination.write_bytes(frozen_status_content())
        else:
            shutil.copy2(ROOT / path, destination)


def copy_current_fixture(target: Path) -> None:
    for path in {CONTRACT_PATH, SCHEMA_PATH, STATUS_PATH, SUMMARY_PATH, TECHNICAL_PATH} | {Path(p) for p in IMMUTABLE_INPUTS}:
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
        raise AssertionError(f"fixture missing text: {old}")
    full.write_text(content.replace(old, new, 1), encoding="utf-8")


def expect_failure(name: str, mutate) -> None:
    with tempfile.TemporaryDirectory(prefix="p021-frozen-mutation-") as directory:
        target = Path(directory)
        copy_fixture(target)
        mutate(target)
        try:
            validate(target, check_git=False, later_succession=False)
        except ValidationError:
            print(f"PASS {name}")
            return
        raise AssertionError(f"mutation unexpectedly passed: {name}")


def compatibility_preflight() -> None:
    try:
        validate(ROOT, check_git=False, later_succession=False)
    except ValidationError as exc:
        if "P0.21 architecture not recorded merged" not in str(exc):
            raise AssertionError(f"strict current succession failed unexpectedly: {exc}") from exc
        print("PASS strict current succession rejects superseded P0.21 status")
    else:
        raise AssertionError("strict P0.21 validation accepted current succession")
    validate(ROOT, check_git=False, later_succession=True)
    print("PASS later succession accepts current project status")
    with tempfile.TemporaryDirectory(prefix="p021-frozen-preflight-") as directory:
        target = Path(directory)
        copy_fixture(target)
        validate(target, check_git=False, later_succession=False)
        print("PASS strict frozen P0.21 fixture validates before mutation")
    with tempfile.TemporaryDirectory(prefix="p021-later-preflight-") as directory:
        target = Path(directory)
        copy_current_fixture(target)
        edit_json(
            target,
            CONTRACT_PATH,
            lambda data: data["authority_ownership"].update(
                director_inputs="all_private_state"
            ),
        )
        try:
            validate(target, check_git=False, later_succession=True)
        except ValidationError:
            print("PASS later succession rejects immutable P0.21 violation")
        else:
            raise AssertionError("later succession accepted immutable P0.21 violation")


def main() -> int:
    compatibility_preflight()
    mutations = [
        ("schema_opened", lambda root: edit_json(root, SCHEMA_PATH, lambda data: data.update(additionalProperties=True))),
        ("runtime_authorized", lambda root: edit_json(root, CONTRACT_PATH, lambda data: data["authorization"].update(runtime_implementation=True))),
        ("catalog_registered", lambda root: edit_json(root, CONTRACT_PATH, lambda data: data["authorization"].update(catalog_registration=True))),
        ("authoring_runtime_input", lambda root: edit_json(root, CONTRACT_PATH, lambda data: data["immutable_inputs"][1].update(runtime_input=True))),
        ("target_removed", lambda root: edit_json(root, CONTRACT_PATH, lambda data: data["compilation_pipeline"].update(target_outputs=data["compilation_pipeline"]["target_outputs"][:-1]))),
        ("director_private", lambda root: edit_json(root, CONTRACT_PATH, lambda data: data["authority_ownership"].update(director_inputs="all_private_state"))),
        ("rejection_rng_mutates", lambda root: edit_json(root, CONTRACT_PATH, lambda data: data["authority_ownership"].update(rejected_action_policy="rng_advances"))),
        ("best_effort_restore", lambda root: edit_json(root, CONTRACT_PATH, lambda data: data["persistence"].update(migration_policy="best_effort"))),
        ("historical_successor_issue", lambda root: edit_json(root, CONTRACT_PATH, lambda data: data["implementation_stages"][0].update(github_issue=100))),
        ("historical_successor_active", lambda root: edit_json(root, CONTRACT_PATH, lambda data: data["implementation_stages"][0].update(activation_authorized=True))),
        ("human_claim", lambda root: edit_json(root, CONTRACT_PATH, lambda data: data["evidence_boundaries"].update(fun_validated=True))),
        ("status_unmerges_p021", lambda root: edit_json(root, STATUS_PATH, lambda data: data["production_architecture"].update(state="active_planning"))),
        ("status_wrong_sha", lambda root: edit_json(root, STATUS_PATH, lambda data: data["production_architecture"].update(merged_main_sha="0" * 40))),
        ("technical_runtime_input", lambda root: replace_text(root, TECHNICAL_PATH, "compilation inputs only", "runtime inputs")),
        ("summary_claims_shipping", lambda root: replace_text(root, SUMMARY_PATH, "It does not compile, register, expose, or ship Drowned Harbor", "It ships Drowned Harbor")),
    ]
    for name, mutation in mutations:
        expect_failure(name, mutation)
    print(f"P0.21 frozen mutation suite passed: {len(mutations)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
