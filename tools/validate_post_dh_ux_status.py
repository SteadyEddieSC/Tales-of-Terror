#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import subprocess
from pathlib import Path
from typing import Any

ROOT = Path(".")
BASE = "22b43893b7726e5c5bea1078aced1cf11e08049f"
BRANCH = "docs/post-dh-ux-status-reconciliation"
ALLOWED = {
    "README.md",
    ".github/workflows/p021-production-architecture.yml",
    ".github/workflows/p022-alpha2-graybox-contract.yml",
    ".github/workflows/p023-alpha3-systems-replayability-contract.yml",
    ".github/workflows/post-prototype-reconciliation.yml",
    "docs/preproduction/README.md",
    "docs/preproduction/post_prototype_status_v1.json",
    "docs/roadmap/Post_P0.19_Production_Candidate_Roadmap.md",
    "tools/test_validate_post_dh_ux_status.py",
    "tools/validate_post_dh_ux_status.py",
}
STATUS = Path("docs/preproduction/post_prototype_status_v1.json")
README = Path("README.md")
INDEX = Path("docs/preproduction/README.md")
ROADMAP = Path("docs/roadmap/Post_P0.19_Production_Candidate_Roadmap.md")

ALPHA3_CANDIDATE = "08fdbe8b52a66fc44a98bdd27878554c5478aef1"
ALPHA3_MERGE = "cad70c5c8f0db1de7d557aff242cc8fe3610361b"
VISUAL_BASELINE_MERGE = "0cea1ac62733fda56d09cb0de8a789efc509308a"
HIGH_WATER_MERGE = "671b8f2512be80c0c5f2cec701c29445159620e2"
PRESENTATION_FAMILY_MERGE = "1cad8495c913d926c4422557ea59e8c6fa1f6c1a"
UX_MERGE = BASE


class ValidationError(ValueError):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValidationError(message)


def load(root: Path, path: Path) -> dict[str, Any]:
    value = json.loads((root / path).read_text(encoding="utf-8"))
    require(isinstance(value, dict), f"object required: {path}")
    return value


def validate_status(status: dict[str, Any]) -> None:
    require(status.get("status_kind") == "post_prototype_project_status", "status kind drift")
    require(status.get("schema_version") == 5, "status schema drift")
    require(status.get("as_of_date") == "2026-08-05", "status date drift")
    require(status.get("protected_main") == BASE, "protected-main drift")
    require(
        status.get("protected_main_semantics") == "exact_reconciliation_starting_baseline",
        "protected-main semantics drift",
    )
    require(status.get("playable_release") == "v0.1.9", "normal playable release drift")
    require(status.get("runtime_implementation_authorized") is False, "runtime authorized")
    require(status.get("visual_implementation_authorized") is False, "visual implementation authorized")
    require(status.get("ux_implementation_authorized") is False, "UX implementation authorized")
    require(status.get("human_evidence_claimed") is False, "human evidence claimed")
    require(status.get("unrelated_open_pull_requests") == [32], "PR #32 boundary drift")

    require(
        status.get("alpha3")
        == {
            "candidate_head_sha": ALPHA3_CANDIDATE,
            "developer_only": True,
            "issue": 108,
            "merged_main_sha": ALPHA3_MERGE,
            "ordinary_export_included": False,
            "package_version": 3,
            "provider_version": 3,
            "pull_request": 109,
            "release_id": "v0.2.0-alpha.3",
            "scenario_version": 3,
            "snapshot_version": 3,
            "state": "completed_developer_only",
        },
        "Alpha.3 identity drift",
    )
    require(
        status.get("current_release")
        == {
            "activation_authorized": False,
            "issue": None,
            "release_id": None,
            "runtime_authority_created": False,
            "state": "none_active_after_reconciliation",
            "type": None,
        },
        "current release must remain empty and unauthorized",
    )
    require(
        status.get("recommended_next_release")
        == {
            "activation_authorized": False,
            "codex_required": False,
            "github_issue": None,
            "release_id": None,
            "state": "unselected_blocked_on_rights_provenance_and_explicit_activation",
            "title": None,
        },
        "successor selected or authorized",
    )
    require(
        status.get("pending_inputs")
        == [
            {
                "authority": "required_before_source_art_or_runtime_composition",
                "implementation_authorized": False,
                "input_id": "rights_and_provenance_resolution_for_external_visual_inputs",
                "state": "blocking_unresolved",
            }
        ],
        "rights/provenance blocker drift",
    )
    require(
        status.get("drowned_harbor")
        == {
            "ordinary_playable": False,
            "status": "developer_only_alpha3_with_completed_metadata_only_visual_and_ux_planning_export_excluded",
        },
        "Drowned Harbor boundary drift",
    )
    require(
        status.get("production")
        == {
            "default_tale_id": "lantern_house_vertical_slice",
            "drowned_harbor_catalog_registered": False,
            "drowned_harbor_normal_library_visible": False,
            "drowned_harbor_ordinary_export_included": False,
            "drowned_harbor_provider_registered": False,
            "tale_count": 1,
        },
        "production/catalog/provider/export boundary drift",
    )
    require(
        status.get("companion_dependency_security")
        == {
            "audit_threshold": "moderate",
            "miniflare": "4.20260722.0",
            "override_policy": {"postcss": "8.5.23", "undici": "7.29.0"},
            "sharp": "0.35.2",
            "state": "remediated_and_exact_head_validated",
            "workers_types": "5.20260722.1",
            "wrangler": "4.114.0",
        },
        "Companion dependency authority drift",
    )

    gates = {row.get("issue"): row.get("state") for row in status.get("gates", [])}
    require(gates == {7: "open", 39: "deferred_open"}, "issue-gate inventory drift")

    visual = status.get("visual_planning", {})
    require(
        visual.get("external_binaries_in_git") is False
        and visual.get("production_art_authorized") is False
        and visual.get("public_github_release_assets_authorized") is False
        and visual.get("runtime_art_authorized") is False,
        "visual binary/art/public-release boundary opened",
    )
    require(
        visual.get("visual_baseline")
        == {
            "baseline_id": "DH-VBL-001",
            "candidate_batch_id": "DH-CB-002",
            "conversion_brief_id": "DH-VCB-001",
            "issue": 110,
            "merged_main_sha": VISUAL_BASELINE_MERGE,
            "pull_request": 113,
            "state": "completed_metadata_only",
        },
        "visual baseline identity drift",
    )
    require(
        visual.get("presentation_study")
        == {
            "issue": 114,
            "merged_main_sha": HIGH_WATER_MERGE,
            "pull_request": 115,
            "release_id": "DH-PRESENT-REG-001",
            "state": "completed_metadata_only",
            "study_id": "DH-PRESENT-001",
            "visual_candidate_created": False,
        },
        "High Water presentation identity drift",
    )
    require(
        visual.get("presentation_family")
        == {
            "conversion_readiness": "not_ready",
            "family_id": "DH-PRESENT-FAMILY-001",
            "implementation_authorized": False,
            "issue": 118,
            "merged_main_sha": PRESENTATION_FAMILY_MERGE,
            "pull_request": 119,
            "release_id": "DH-PRESENT-REG-002",
            "state": "completed_metadata_only",
            "study_ids": ["DH-PRESENT-001", "DH-PRESENT-002", "DH-PRESENT-003"],
            "visual_candidate_created": False,
        },
        "presentation family identity or readiness drift",
    )
    require(
        visual.get("ux_advisory")
        == {
            "advisory_id": "DH-UX-001",
            "candidate_id": None,
            "conversion_readiness": "not_ready",
            "disposition": "accepted_external_ux_advisory_with_required_corrections",
            "implementation_authorized": False,
            "issue": 120,
            "merged_main_sha": UX_MERGE,
            "pull_request": 124,
            "release_id": "DH-UX-REG-001",
            "state": "completed_metadata_only",
        },
        "UX advisory identity, disposition, or boundary drift",
    )

    preserved = status.get("preserved_authorities", {})
    require(preserved.get("alpha3_candidate_head") == ALPHA3_CANDIDATE, "preserved Alpha.3 candidate drift")
    require(preserved.get("alpha3_merge") == ALPHA3_MERGE, "preserved Alpha.3 merge drift")
    require(preserved.get("dh_visual_baseline_merge") == VISUAL_BASELINE_MERGE, "preserved visual baseline drift")
    require(preserved.get("dh_present_registration_merge") == HIGH_WATER_MERGE, "preserved High Water merge drift")
    require(
        preserved.get("dh_present_family_registration_merge") == PRESENTATION_FAMILY_MERGE,
        "preserved presentation-family merge drift",
    )
    require(preserved.get("dh_ux_registration_merge") == UX_MERGE, "preserved UX merge drift")


def validate_docs(root: Path) -> None:
    readme = (root / README).read_text(encoding="utf-8")
    index = (root / INDEX).read_text(encoding="utf-8")
    roadmap = (root / ROADMAP).read_text(encoding="utf-8")
    joined = "\n".join([readme, index, roadmap])
    lowered = joined.lower()

    required = [
        BASE,
        "issue #108 / pr #109",
        "issue #110 / pr #113",
        "issue #114 / pr #115",
        "issue #118 / pr #119",
        "issue #120 / pr #124",
        "issue #125",
        "dh-vbl-001",
        "dh-present-reg-001",
        "dh-present-reg-002",
        "dh-present-family-001",
        "dh-ux-reg-001",
        "dh-ux-001",
        "accepted external ux advisory with required corrections",
        "conversion readiness `not_ready`",
        "rights and provenance",
        "unselected",
        "lantern house remains the sole normal/default tale",
        "drowned harbor remains developer-only",
        "excluded from ordinary exports",
        "automation is not human evidence",
        "issue #39 remains the human-evidence authority",
        "issue #7 remains the naming gate",
        "pr #32 remains unrelated",
    ]
    for phrase in required:
        require(phrase.lower() in lowered, f"current documentation missing: {phrase}")

    stale = [
        "waiting on ux helper review",
        "ux helper handoff remains pending",
        "waiting_on_ux_handoff_and_explicit_activation",
        "the ux helper's output remains advisory until release coordination reviews",
        "next bounded release:** unselected, waiting on ux helper",
        "latest completed planning release:** `dh-present-reg-001`",
    ]
    for phrase in stale:
        require(phrase not in lowered, f"stale current-state claim: {phrase}")

    unsupported = [
        "rights and provenance resolved",
        "source art authorized",
        "ux implementation authorized",
        "human playtesting passed",
        "television readability validated",
        "physical-controller validation passed",
        "accessibility certified",
        "privacy certified",
        "security certified",
        "production ready",
        "shipping authorized",
        "public release authorized",
    ]
    for claim in unsupported:
        require(claim not in lowered, f"unsupported claim: {claim}")


def effective_branch(root: Path) -> str:
    return (
        os.environ.get("GITHUB_HEAD_REF")
        or os.environ.get("GITHUB_REF_NAME")
        or subprocess.check_output(["git", "branch", "--show-current"], cwd=root, text=True).strip()
    )


def validate_git_boundary(root: Path) -> None:
    branch = effective_branch(root)
    if branch != BRANCH:
        return
    merge_base = subprocess.check_output(["git", "merge-base", "HEAD", BASE], cwd=root, text=True).strip()
    require(merge_base == BASE, f"reconciliation baseline changed: {merge_base}")
    actual = {
        line
        for line in subprocess.check_output(
            ["git", "diff", "--name-only", f"{BASE}...HEAD"], cwd=root, text=True
        ).splitlines()
        if line
    }
    require(
        actual == ALLOWED,
        f"exact path mismatch missing={sorted(ALLOWED - actual)} unexpected={sorted(actual - ALLOWED)}",
    )
    for path in actual:
        require(
            not path.startswith(("game/", "art/source/", "game/assets/")),
            f"prohibited path changed: {path}",
        )
        require(
            Path(path).suffix.lower()
            not in {".png", ".webp", ".svg", ".glb", ".zip", ".kra", ".psd", ".blend", ".tscn", ".tres"},
            f"prohibited binary/runtime extension changed: {path}",
        )


def validate(root: Path = ROOT, *, check_git: bool = True) -> None:
    validate_status(load(root, STATUS))
    validate_docs(root)
    if check_git:
        validate_git_boundary(root)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--skip-git-boundary", action="store_true")
    args = parser.parse_args()
    try:
        validate(check_git=not args.skip_git_boundary)
    except (
        ValidationError,
        KeyError,
        TypeError,
        OSError,
        json.JSONDecodeError,
        subprocess.CalledProcessError,
    ) as exc:
        print(f"Post-DH-UX status validation failed: {exc}")
        return 1
    print("Validated post-DH-UX current status and succession boundary")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
