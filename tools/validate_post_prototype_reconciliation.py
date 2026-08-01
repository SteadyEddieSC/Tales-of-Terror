#!/usr/bin/env python3
"""Validate preserved P0.20 history and the exact P0.21 status succession."""

from __future__ import annotations

import argparse
import json
import re
import subprocess
from pathlib import Path
from typing import Any

BASELINE = "58f6f4e4ece9bbdd5932216c87aacc064e48e05a"
ROOT = Path(".")
STATUS_PATH = Path("docs/preproduction/post_prototype_status_v1.json")
README_PATH = Path("README.md")
PREPROD_README_PATH = Path("docs/preproduction/README.md")
HISTORICAL_ROADMAP_PATH = Path("docs/roadmap/Post_v0.1.9_Preproduction_Roadmap.md")
CURRENT_ROADMAP_PATH = Path("docs/roadmap/Post_P0.19_Production_Candidate_Roadmap.md")
P020_SUMMARY_PATH = Path("docs/preproduction/P0.20_Release_Summary.md")
SUMMARY_PATH = Path("docs/preproduction/P0.21_Release_Summary.md")
FROZEN_INDEX_PATH = Path("docs/preproduction/preproduction_package_index_v1.json")

ALLOWED_PATHS = {
    ".github/workflows/p021-production-architecture.yml",
    ".github/workflows/post-prototype-reconciliation.yml",
    "README.md",
    "docs/preproduction/README.md",
    "docs/preproduction/P0.21_Release_Summary.md",
    "docs/preproduction/post_prototype_status_v1.json",
    "docs/preproduction/drowned_harbor_production_compilation_contract_schema_v1.json",
    "docs/preproduction/drowned_harbor_production_compilation_contract_v1.json",
    "docs/preproduction/P0.21_Implementation_Issue_Set.md",
    "docs/technical/Drowned_Harbor_Production_Architecture_and_Compilation_Contract_v1.md",
    "docs/roadmap/Post_P0.19_Production_Candidate_Roadmap.md",
    "tools/validate_p021_production_architecture.py",
    "tools/test_validate_p021_production_architecture.py",
    "tools/validate_post_prototype_reconciliation.py",
    "tools/test_validate_post_prototype_reconciliation.py",
}

EXPECTED_RELEASES = [f"P0.{index}" for index in range(1, 21)]
EXPECTED_COMPLETED_ISSUES = list(range(80, 87))
REQUIRED_STAGES = [
    "P0.21 — Production Architecture & Tale-Compilation Contract",
    "v0.2.0-alpha.1 — Production Tale Scaffold",
    "v0.2.0-alpha.2 — End-to-End Graybox",
    "v0.2.0-alpha.3 — Systems & Replayability",
    "v0.2.0-beta — Presentation & Content Integration",
    "v0.2.0-rc — Hardening & Distribution Readiness",
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
        data = json.loads(read_text(root, path))
    except json.JSONDecodeError as exc:
        raise ValidationError(f"invalid JSON: {path}: {exc}") from exc
    require(isinstance(data, dict), f"JSON root must be an object: {path}")
    return data


def validate_status(data: dict[str, Any]) -> None:
    require(data.get("status_kind") == "post_prototype_project_status", "unexpected status_kind")
    require(data.get("schema_version") == 1, "unexpected schema version")
    require(data.get("protected_main") == BASELINE, "protected-main baseline drift")
    require(data.get("playable_release") == "v0.1.9", "playable release drift")

    production = data.get("production")
    require(isinstance(production, dict), "production must be an object")
    require(production.get("default_tale_id") == "lantern_house_vertical_slice", "Lantern House must remain default")
    require(production.get("tale_count") == 1, "production Tale count must remain one")
    for field in (
        "drowned_harbor_catalog_registered",
        "drowned_harbor_provider_registered",
        "drowned_harbor_normal_library_visible",
        "drowned_harbor_ordinary_export_included",
    ):
        require(production.get(field) is False, f"{field} must remain false")

    drowned = data.get("drowned_harbor")
    require(isinstance(drowned, dict), "drowned_harbor must be an object")
    require(drowned.get("status") == "development_only_export_excluded", "unexpected Drowned Harbor status")
    require(drowned.get("ordinary_playable") is False, "Drowned Harbor may not be ordinarily playable")
    require(drowned.get("fixture_count") == 7, "fixture count must remain seven")
    require(drowned.get("completed_work_issues") == EXPECTED_COMPLETED_ISSUES, "completed issue inventory drift")
    require(drowned.get("successor_implementation_issue") is None, "successor issue must remain unset")
    require(drowned.get("successor_implementation_authorized") is False, "successor implementation is not authorized")

    require(drowned.get("aggregate_automation") == {
        "profile_id": "DH-AUTO-P019-V1",
        "sequences": 12,
        "repetitions": 2,
        "governed_cases": 33,
        "fail_closed_rejections": 12,
        "private_leaks": 0,
        "deadlocks": 0,
    }, "P0.19 aggregate evidence drift")

    companion = data.get("companion_security")
    require(isinstance(companion, dict), "companion_security must be an object")
    require(companion.get("issue") == 44, "unexpected Companion issue")
    require(companion.get("state") == "completed", "issue #44 must be completed")
    require(companion.get("wrangler") == "4.114.0", "Wrangler version drift")
    require(companion.get("miniflare") == "4.20260722.0", "Miniflare version drift")
    require(companion.get("sharp") == "0.35.2", "Sharp version drift")
    require(companion.get("workers_types") == "5.20260722.1", "Workers Types version drift")
    require(companion.get("audit_high_or_critical") == 0, "Companion audit must remain zero high/critical")

    releases = data.get("preproduction_releases")
    require(isinstance(releases, list) and len(releases) == 20, "status must contain P0.1 through P0.20")
    release_ids = [entry.get("release_id") for entry in releases if isinstance(entry, dict)]
    require(release_ids == EXPECTED_RELEASES, "preproduction release order/inventory drift")
    require(all(entry.get("state") == "merged" for entry in releases), "every P0.1-P0.20 entry must be merged")
    require(all(re.fullmatch(r"[0-9a-f]{40}", str(entry.get("merged_main_sha", ""))) for entry in releases), "invalid merge SHA")
    require(releases[-1] == {
        "release_id": "P0.20",
        "pull_request": 97,
        "merged_main_sha": BASELINE,
        "title": "Post-Prototype Reconciliation & Production Decision Pack",
        "state": "merged",
    }, "P0.20 merge record drift")

    require(data.get("current_release") == {
        "release_id": "P0.21",
        "issue": 98,
        "branch": "docs/p0.21-production-architecture-contract",
        "type": "documentation_schema_validation",
        "runtime_authority_created": False,
    }, "current release must be P0.21 issue #98")

    require(data.get("recommended_next_release") == {
        "release_id": "v0.2.0-alpha.1",
        "title": "Production Tale Scaffold",
        "state": "planned_blocked",
        "github_issue": None,
        "codex_required": True,
        "activation_authorized": False,
    }, "alpha.1 must remain planned, blocked, and inactive")

    architecture = data.get("production_architecture")
    require(isinstance(architecture, dict), "production architecture status missing")
    require(architecture.get("state") == "active_planning", "P0.21 architecture must be active planning")
    require(architecture.get("runtime_input") is False, "architecture contract may not be a runtime input")
    require(architecture.get("normal_library_visible") is False, "Drowned Harbor may not be normally visible")
    require(architecture.get("ordinary_export_included") is False, "Drowned Harbor may not enter ordinary exports")
    require(data.get("runtime_implementation_authorized") is False, "runtime implementation may not be authorized")
    require(data.get("human_evidence_claimed") is False, "human evidence may not be claimed")


def validate_docs(root: Path) -> None:
    readme = read_text(root, README_PATH)
    preprod = read_text(root, PREPROD_README_PATH)
    historical = read_text(root, HISTORICAL_ROADMAP_PATH)
    roadmap = read_text(root, CURRENT_ROADMAP_PATH)
    p020_summary = read_text(root, P020_SUMMARY_PATH)
    p021_summary = read_text(root, SUMMARY_PATH)

    for phrase in (
        "Current active package:** P0.21",
        "P0.20 — Post-Prototype Reconciliation & Production Decision Pack",
        "Drowned Harbor is not a production Tale and is not ordinarily playable",
        "issue #44:** completed",
        "Lantern House remains the sole production/default Tale",
        "Automation is not human evidence",
    ):
        require(phrase in readme, f"README missing: {phrase}")

    for phrase in (
        "Current package:** P0.21",
        "P0.20 merged through PR #97",
        "planned_blocked",
        "Issue #44 is complete",
        "Codex is not required for P0.21",
    ):
        require(phrase in preprod, f"preproduction index missing: {phrase}")

    require("Superseded Historical Record" in historical, "historical roadmap must remain superseded")
    require("Post_P0.19_Production_Candidate_Roadmap.md" in historical, "historical roadmap must retain successor link")
    require("P0.1 is current" not in historical, "historical roadmap may not present P0.1 as current")

    for stage in REQUIRED_STAGES:
        require(stage in roadmap, f"roadmap missing stage: {stage}")
    require("P0.21 planning stage active" in roadmap, "roadmap must identify P0.21 as active")
    require("Only P0.21 is active" in roadmap, "roadmap must block all later stages")
    require("Codex must never activate, merge, or close the release" in roadmap, "Codex boundary missing")
    require("Lantern House remains the sole normal production/default Tale" in roadmap, "production invariant missing")

    for phrase in (
        "P0.1–P0.19 are recorded as merged",
        "Issue #44 is recorded as completed",
        "does not activate P0.21",
        "No runtime",
        "No human",
    ):
        require(phrase in p020_summary, f"P0.20 historical summary missing: {phrase}")

    for phrase in (
        "P0.1–P0.20 remain recorded as merged",
        "It does not compile, register, expose, or ship Drowned Harbor",
        "Automation is not human evidence",
        "Codex is not needed for P0.21",
    ):
        require(phrase in p021_summary, f"P0.21 summary missing: {phrase}")

    combined = "\n".join((readme, preprod, roadmap, p021_summary))
    for phrase in (
        "Current package:** P0.20",
        "Current active package:** P0.20",
        "P0.21 must remain planned, not active",
        "Companion workflow intentionally remains red",
        "Codex/local implementation is considered blocked",
    ):
        require(phrase not in combined, f"stale claim retained: {phrase}")


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
    require("docs/preproduction/preproduction_package_index_v1.json" not in actual, "historical package index changed")
    require("tools/validate_preproduction_package_traceability.py" not in actual, "historical P0.8 validator changed")
    require(not any(path.startswith(("game/", "services/", "web/", "packaging/")) for path in actual), "runtime/service/export path changed")


def validate(root: Path = ROOT, check_git: bool = True) -> None:
    validate_status(read_json(root, STATUS_PATH))
    validate_docs(root)
    require((root / FROZEN_INDEX_PATH).is_file(), "historical package index missing")
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
    print("Post-prototype history and P0.21 status succession validated")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
