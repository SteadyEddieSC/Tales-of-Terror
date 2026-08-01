#!/usr/bin/env python3
"""Fail-closed mutation tests for the P0.20 reconciliation validator."""

from __future__ import annotations

import json
import shutil
import tempfile
from pathlib import Path

from validate_post_prototype_reconciliation import (
    CURRENT_ROADMAP_PATH,
    HISTORICAL_ROADMAP_PATH,
    PREPROD_README_PATH,
    README_PATH,
    STATUS_PATH,
    SUMMARY_PATH,
    ValidationError,
    validate,
)

ROOT = Path(".")


def copy_fixture(target: Path) -> None:
    for path in (
        STATUS_PATH,
        README_PATH,
        PREPROD_README_PATH,
        HISTORICAL_ROADMAP_PATH,
        CURRENT_ROADMAP_PATH,
        SUMMARY_PATH,
        Path("docs/preproduction/preproduction_package_index_v1.json"),
    ):
        destination = target / path
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(ROOT / path, destination)


def expect_failure(name: str, mutate) -> None:
    with tempfile.TemporaryDirectory(prefix="p020-mutation-") as directory:
        target = Path(directory)
        copy_fixture(target)
        mutate(target)
        try:
            validate(target, check_git=False)
        except ValidationError:
            print(f"PASS {name}")
            return
        raise AssertionError(f"mutation unexpectedly passed: {name}")


def edit_json(target: Path, mutate) -> None:
    path = target / STATUS_PATH
    data = json.loads(path.read_text(encoding="utf-8"))
    mutate(data)
    path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")


def replace_text(target: Path, path: Path, old: str, new: str) -> None:
    full = target / path
    content = full.read_text(encoding="utf-8")
    if old not in content:
        raise AssertionError(f"test fixture missing text: {old}")
    full.write_text(content.replace(old, new, 1), encoding="utf-8")


def main() -> int:
    mutations = [
        ("issue_44_reopened", lambda root: edit_json(root, lambda data: data["companion_security"].update(state="open"))),
        ("drowned_harbor_registered", lambda root: edit_json(root, lambda data: data["production"].update(drowned_harbor_catalog_registered=True))),
        ("successor_authorized", lambda root: edit_json(root, lambda data: data["drowned_harbor"].update(successor_implementation_authorized=True))),
        ("successor_issue_created", lambda root: edit_json(root, lambda data: data["drowned_harbor"].update(successor_implementation_issue=97))),
        ("missing_p019", lambda root: edit_json(root, lambda data: data.update(preproduction_releases=data["preproduction_releases"][:-1]))),
        ("wrong_default_tale", lambda root: edit_json(root, lambda data: data["production"].update(default_tale_id="drowned_harbor"))),
        ("human_evidence_claimed", lambda root: edit_json(root, lambda data: data.update(human_evidence_claimed=True))),
        ("roadmap_stage_removed", lambda root: replace_text(root, CURRENT_ROADMAP_PATH, "### v0.2.0-alpha.2 — End-to-End Graybox", "### Removed stage")),
        ("historical_not_superseded", lambda root: replace_text(root, HISTORICAL_ROADMAP_PATH, "Superseded Historical Record", "Current Roadmap")),
        ("preproduction_p01_current", lambda root: replace_text(root, PREPROD_README_PATH, "Current package:** P0.20", "Current package:** P0.1")),
        ("readme_issue_44_stale", lambda root: replace_text(root, README_PATH, "issue #44:** completed", "Issue #44 remains open")),
        ("readme_drowned_production", lambda root: replace_text(root, README_PATH, "Drowned Harbor is not a production Tale and is not ordinarily playable", "Drowned Harbor is a production Tale and is ordinarily playable")),
    ]
    for name, mutation in mutations:
        expect_failure(name, mutation)
    print(f"P0.20 mutation suite passed: {len(mutations)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
