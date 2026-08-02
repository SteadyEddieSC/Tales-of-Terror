#!/usr/bin/env python3
"""Validate preserved release history and current P0.22 status succession."""

from __future__ import annotations

import argparse
import json
import re
import subprocess
from pathlib import Path
from typing import Any

ROOT = Path(".")
BASELINE = "85b77d5216472afdb4abb7598917d5052eed180a"
P021_MERGE = "4efdd76efdf2aa34823dae5d3624a3dca3f0a349"
STATUS_PATH = Path("docs/preproduction/post_prototype_status_v1.json")
PREPROD_README_PATH = Path("docs/preproduction/README.md")
HISTORICAL_ROADMAP_PATH = Path("docs/roadmap/Post_v0.1.9_Preproduction_Roadmap.md")
CURRENT_ROADMAP_PATH = Path("docs/roadmap/Post_P0.19_Production_Candidate_Roadmap.md")
P020_SUMMARY_PATH = Path("docs/preproduction/P0.20_Release_Summary.md")
P021_SUMMARY_PATH = Path("docs/preproduction/P0.21_Release_Summary.md")
FROZEN_INDEX_PATH = Path("docs/preproduction/preproduction_package_index_v1.json")
P022_RELEASE_PATH = Path("docs/releases/P0.22-alpha2-graybox-contract.md")

ALLOWED_PATHS = {
    ".github/workflows/p021-production-architecture.yml",
    ".github/workflows/p022-alpha2-graybox-contract.yml",
    ".github/workflows/post-prototype-reconciliation.yml",
    "docs/preproduction/P0.21_Implementation_Issue_Set.md",
    "docs/preproduction/P0.22_Alpha2_Implementation_Issue.md",
    "docs/preproduction/README.md",
    "docs/preproduction/drowned_harbor_alpha2_graybox_route_contract_schema_v1.json",
    "docs/preproduction/drowned_harbor_alpha2_graybox_route_contract_v1.json",
    "docs/preproduction/post_prototype_status_v1.json",
    "docs/releases/P0.22-alpha2-graybox-contract.md",
    "docs/roadmap/Post_P0.19_Production_Candidate_Roadmap.md",
    "docs/technical/Drowned_Harbor_Alpha2_Graybox_Route_Contract_v1.md",
    "tools/test_validate_p021_production_architecture.py",
    "tools/test_validate_p022_alpha2_graybox_contract.py",
    "tools/test_validate_post_prototype_reconciliation.py",
    "tools/validate_p021_production_architecture.py",
    "tools/validate_p022_alpha2_graybox_contract.py",
    "tools/validate_post_prototype_reconciliation.py",
}
EXPECTED_RELEASES = [f"P0.{index}" for index in range(1, 22)]
EXPECTED_COMPLETED_ISSUES = [80, 81, 82, 83, 84, 85, 86, 100]


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


def validate_status(data: dict[str, Any]) -> None:
    require(data.get("status_kind") == "post_prototype_project_status", "status kind drift")
    require(data.get("schema_version") == 1, "status schema drift")
    require(data.get("as_of_date") == "2026-08-01", "status date drift")
    require(data.get("protected_main") == BASELINE, "protected-main drift")
    require(data.get("playable_release") == "v0.1.9", "playable release drift")

    production = data.get("production", {})
    require(production.get("default_tale_id") == "lantern_house_vertical_slice", "Lantern House default drift")
    require(production.get("tale_count") == 1, "normal Tale count drift")
    for key in (
        "drowned_harbor_catalog_registered",
        "drowned_harbor_provider_registered",
        "drowned_harbor_normal_library_visible",
        "drowned_harbor_ordinary_export_included",
    ):
        require(production.get(key) is False, f"production boundary changed: {key}")

    drowned = data.get("drowned_harbor", {})
    require(drowned.get("status") == "developer_only_alpha1_scaffold_export_excluded", "Drowned Harbor status drift")
    require(drowned.get("ordinary_playable") is False, "Drowned Harbor became ordinarily playable")
    require(drowned.get("fixture_count") == 7, "prototype fixture count drift")
    require(drowned.get("completed_work_issues") == EXPECTED_COMPLETED_ISSUES, "completed issue inventory drift")
    require(drowned.get("successor_implementation_issue") is None, "alpha.2 issue created prematurely")
    require(drowned.get("successor_implementation_authorized") is False, "alpha.2 authorized prematurely")
    alpha1 = drowned.get("alpha1_scaffold", {})
    require(alpha1.get("issue") == 100 and alpha1.get("pull_request") == 101, "alpha.1 issue/PR record drift")
    require(alpha1.get("merged_main_sha") == BASELINE, "alpha.1 merge SHA drift")
    require(alpha1.get("developer_only") is True, "alpha.1 developer gate drift")
    require(alpha1.get("normal_library_visible") is False, "alpha.1 normal visibility drift")
    require(alpha1.get("ordinary_export_included") is False, "alpha.1 export boundary drift")

    companion = data.get("companion_security", {})
    require(companion.get("issue") == 44 and companion.get("state") == "completed", "Companion issue state drift")
    require(companion.get("wrangler") == "4.114.0", "Wrangler drift")
    require(companion.get("miniflare") == "4.20260722.0", "Miniflare drift")
    require(companion.get("sharp") == "0.35.2", "Sharp drift")
    require(companion.get("workers_types") == "5.20260722.1", "Workers Types drift")
    require(companion.get("audit_high_or_critical") == 0, "Companion audit drift")

    releases = data.get("preproduction_releases")
    require(isinstance(releases, list) and len(releases) == 21, "P0.1-P0.21 history length drift")
    require([row.get("release_id") for row in releases] == EXPECTED_RELEASES, "preproduction release order drift")
    require(all(row.get("state") == "merged" for row in releases), "preproduction release state drift")
    require(all(re.fullmatch(r"[0-9a-f]{40}", str(row.get("merged_main_sha", ""))) for row in releases), "invalid preproduction SHA")
    require(releases[-1] == {
        "release_id": "P0.21",
        "pull_request": 99,
        "merged_main_sha": P021_MERGE,
        "title": "Production Architecture & Tale-Compilation Contract",
        "state": "merged",
    }, "P0.21 history record drift")

    runtime = data.get("runtime_releases")
    require(isinstance(runtime, list) and len(runtime) == 1, "runtime release history drift")
    require(runtime[0] == {
        "release_id": "v0.2.0-alpha.1",
        "issue": 100,
        "pull_request": 101,
        "merged_main_sha": BASELINE,
        "title": "Drowned Harbor Production Tale Scaffold",
        "state": "merged_internal_candidate",
        "normal_library_visible": False,
        "ordinary_export_included": False,
    }, "alpha.1 runtime history drift")

    architecture = data.get("production_architecture", {})
    require(architecture.get("state") == "merged_authority", "P0.21 architecture state drift")
    require(architecture.get("merged_main_sha") == P021_MERGE, "P0.21 architecture SHA drift")
    require(architecture.get("runtime_input") is False, "architecture contract became runtime input")

    planning = data.get("alpha2_planning", {})
    require(planning.get("state") == "active_planning", "P0.22 planning state drift")
    require(planning.get("runtime_input") is False, "P0.22 contract became runtime input")
    require(planning.get("runtime_issue_created") is False, "alpha.2 issue created")
    require(planning.get("activation_authorized") is False, "alpha.2 activation authorized")

    require(data.get("current_release") == {
        "release_id": "P0.22",
        "issue": 102,
        "branch": "docs/p0.22-alpha2-graybox-contract",
        "type": "documentation_schema_validation",
        "runtime_authority_created": False,
    }, "current release drift")
    require(data.get("recommended_next_release") == {
        "release_id": "v0.2.0-alpha.2",
        "title": "Drowned Harbor End-to-End Graybox",
        "state": "planned_blocked",
        "github_issue": None,
        "codex_required": True,
        "recommended_codex_effort": "very_high",
        "activation_authorized": False,
    }, "recommended alpha.2 state drift")
    require(data.get("runtime_implementation_authorized") is False, "runtime implementation authorized")
    require(data.get("human_evidence_claimed") is False, "human evidence claimed")


def validate_docs(root: Path) -> None:
    preprod = read_text(root, PREPROD_README_PATH)
    historical = read_text(root, HISTORICAL_ROADMAP_PATH)
    roadmap = read_text(root, CURRENT_ROADMAP_PATH)
    p020 = read_text(root, P020_SUMMARY_PATH)
    p021 = read_text(root, P021_SUMMARY_PATH)
    p022 = read_text(root, P022_RELEASE_PATH)

    for phrase in (
        "Current package:** P0.22",
        "P0.21: production architecture",
        "v0.2.0-alpha.1: developer-only production scaffold",
        "Alpha.2 remains `planned_blocked`",
        "Automation is not human evidence",
    ):
        require(phrase in preprod, f"preproduction index missing: {phrase}")

    require("Superseded Historical Record" in historical, "historical roadmap lost superseded status")
    require("Post_P0.19_Production_Candidate_Roadmap.md" in historical, "historical successor link missing")

    for phrase in (
        "P0.22 alpha.2 planning active; alpha.2 runtime blocked",
        "P0.21 — Production Architecture & Tale-Compilation Contract",
        "v0.2.0-alpha.1 — Production Tale Scaffold",
        "**State:** completed internal runtime scaffold",
        "v0.2.0-alpha.2 — End-to-End Graybox",
        "**State:** `planned_blocked`",
        "No alpha.2 GitHub issue, branch, or Codex prompt is created",
    ):
        require(phrase in roadmap, f"current roadmap missing: {phrase}")

    for phrase in (
        "P0.1–P0.19 are recorded as merged",
        "Issue #44 is recorded as completed",
        "does not activate P0.21",
        "No runtime",
        "No human",
    ):
        require(phrase in p020, f"P0.20 history drift: {phrase}")

    for phrase in (
        "It does not compile, register, expose, or ship Drowned Harbor",
        "P0.1–P0.20 remain recorded as merged",
        "Automation is not human evidence",
    ):
        require(phrase in p021, f"P0.21 history drift: {phrase}")

    for phrase in (
        "P0.22 converts the broad alpha.2 milestone",
        "No `game/**` path changes",
        "runtime issue remains",
        "Automation is machine evidence only",
    ):
        require(phrase in p022, f"P0.22 release record missing: {phrase}")


def validate_git_boundary(root: Path) -> None:
    try:
        output = subprocess.check_output(
            ["git", "diff", "--name-only", f"{BASELINE}...HEAD"],
            cwd=root,
            text=True,
            stderr=subprocess.STDOUT,
        )
    except (FileNotFoundError, subprocess.CalledProcessError) as exc:
        raise ValidationError(f"unable to evaluate git boundary: {exc}") from exc
    actual = {line.strip() for line in output.splitlines() if line.strip()}
    require(actual == ALLOWED_PATHS, f"path boundary mismatch: missing={sorted(ALLOWED_PATHS-actual)} unexpected={sorted(actual-ALLOWED_PATHS)}")
    require(not any(path.startswith(("game/", "services/", "web/", "packaging/", "art/", "audio/")) for path in actual), "runtime/service/media path changed")
    require("docs/preproduction/preproduction_package_index_v1.json" not in actual, "frozen historical package index changed")


def validate(root: Path = ROOT, check_git: bool = True) -> None:
    validate_status(read_json(root, STATUS_PATH))
    validate_docs(root)
    require((root / FROZEN_INDEX_PATH).is_file(), "frozen historical package index missing")
    if check_git:
        validate_git_boundary(root)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--skip-git-boundary", action="store_true")
    args = parser.parse_args()
    try:
        validate(args.root, check_git=not args.skip_git_boundary)
    except ValidationError as exc:
        print(f"Post-prototype succession validation failed: {exc}")
        return 1
    print("Post-prototype history through P0.21, alpha.1, and active P0.22 validated")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
