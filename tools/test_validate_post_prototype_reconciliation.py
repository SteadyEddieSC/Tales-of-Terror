#!/usr/bin/env python3
"""Fail-closed mutations for current post-prototype status succession."""

from __future__ import annotations

import json
import shutil
import tempfile
from pathlib import Path

from validate_post_prototype_reconciliation import (
    CURRENT_ROADMAP_PATH,
    FROZEN_INDEX_PATH,
    HISTORICAL_ROADMAP_PATH,
    P020_SUMMARY_PATH,
    P021_SUMMARY_PATH,
    P022_RELEASE_PATH,
    PREPROD_README_PATH,
    STATUS_PATH,
    ValidationError,
    validate,
)

ROOT = Path(".")


def copy_fixture(target: Path) -> None:
    for path in (
        STATUS_PATH,
        PREPROD_README_PATH,
        HISTORICAL_ROADMAP_PATH,
        CURRENT_ROADMAP_PATH,
        P020_SUMMARY_PATH,
        P021_SUMMARY_PATH,
        P022_RELEASE_PATH,
        FROZEN_INDEX_PATH,
    ):
        destination = target / path
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(ROOT / path, destination)


def edit_json(target: Path, mutate) -> None:
    path = target / STATUS_PATH
    data = json.loads(path.read_text(encoding="utf-8"))
    mutate(data)
    path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")


def replace_text(target: Path, path: Path, old: str, new: str) -> None:
    full = target / path
    content = full.read_text(encoding="utf-8")
    if old not in content:
        raise AssertionError(f"fixture missing text: {old}")
    full.write_text(content.replace(old, new, 1), encoding="utf-8")


def expect_failure(name: str, mutate) -> None:
    with tempfile.TemporaryDirectory(prefix="post-p022-mutation-") as directory:
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
        ("wrong_baseline", lambda root: edit_json(root, lambda data: data.update(protected_main="0" * 40))),
        ("issue_44_reopened", lambda root: edit_json(root, lambda data: data["companion_security"].update(state="open"))),
        ("drowned_registered", lambda root: edit_json(root, lambda data: data["production"].update(drowned_harbor_catalog_registered=True))),
        ("drowned_ordinary_play", lambda root: edit_json(root, lambda data: data["drowned_harbor"].update(ordinary_playable=True))),
        ("alpha1_not_developer_only", lambda root: edit_json(root, lambda data: data["drowned_harbor"]["alpha1_scaffold"].update(developer_only=False))),
        ("completed_issue_removed", lambda root: edit_json(root, lambda data: data["drowned_harbor"].update(completed_work_issues=[80,81,82,83,84,85,86]))),
        ("p021_history_removed", lambda root: edit_json(root, lambda data: data.update(preproduction_releases=data["preproduction_releases"][:-1]))),
        ("p021_wrong_sha", lambda root: edit_json(root, lambda data: data["preproduction_releases"][-1].update(merged_main_sha="0" * 40))),
        ("alpha1_runtime_removed", lambda root: edit_json(root, lambda data: data.update(runtime_releases=[]))),
        ("current_release_reverted", lambda root: edit_json(root, lambda data: data["current_release"].update(release_id="P0.21"))),
        ("alpha2_issue_created", lambda root: edit_json(root, lambda data: data["recommended_next_release"].update(github_issue=103))),
        ("alpha2_activated", lambda root: edit_json(root, lambda data: data["recommended_next_release"].update(activation_authorized=True))),
        ("human_evidence_claimed", lambda root: edit_json(root, lambda data: data.update(human_evidence_claimed=True))),
        ("roadmap_alpha2_active", lambda root: replace_text(root, CURRENT_ROADMAP_PATH, "alpha.2 runtime blocked", "alpha.2 implementation is active")),
        ("historical_not_superseded", lambda root: replace_text(root, HISTORICAL_ROADMAP_PATH, "Superseded Historical Record", "Current Roadmap")),
        ("preprod_reverts_p021", lambda root: replace_text(root, PREPROD_README_PATH, "Current package:** P0.22", "Current package:** P0.21")),
        ("p020_history_changed", lambda root: replace_text(root, P020_SUMMARY_PATH, "does not activate P0.21", "activates P0.21")),
        ("p021_shipping_claim", lambda root: replace_text(root, P021_SUMMARY_PATH, "It does not compile, register, expose, or ship Drowned Harbor", "It ships Drowned Harbor")),
        ("p022_runtime_claim", lambda root: replace_text(root, P022_RELEASE_PATH, "No `game/**` path changes", "Runtime gameplay was implemented")),
    ]
    for name, mutation in mutations:
        expect_failure(name, mutation)
    print(f"Post-prototype P0.22 succession mutation suite passed: {len(mutations)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
