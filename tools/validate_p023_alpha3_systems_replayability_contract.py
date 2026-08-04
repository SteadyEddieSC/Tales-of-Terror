#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import os
import subprocess
from pathlib import Path
from typing import Any

ROOT = Path(".")
BASE = "4e28ce1d7b471c9be1113986647ccbc3147c0d9d"
BRANCH = "docs/p0.23-alpha3-systems-replayability-contract"
ALPHA3_CANDIDATE = "08fdbe8b52a66fc44a98bdd27878554c5478aef1"
ALPHA3_MERGE = "cad70c5c8f0db1de7d557aff242cc8fe3610361b"
RECONCILIATION_BRANCH = "docs/post-alpha3-status-reconciliation"

CONTRACT = Path(
    "docs/preproduction/drowned_harbor_alpha3_systems_replayability_contract_v1.json"
)
SCHEMA = Path(
    "docs/preproduction/drowned_harbor_alpha3_systems_replayability_contract_schema_v1.json"
)
STATUS = Path("docs/preproduction/post_prototype_status_v1.json")
TECH = Path(
    "docs/technical/Drowned_Harbor_Alpha3_Systems_and_Replayability_Contract_v1.md"
)
ISSUE = Path("docs/preproduction/P0.23_Alpha3_Implementation_Issue.md")
RELEASE = Path("docs/releases/P0.23-alpha3-systems-replayability-contract.md")
ROADMAP = Path("docs/roadmap/Post_P0.19_Production_Candidate_Roadmap.md")
INDEX = Path("docs/preproduction/README.md")
ISSUE_SET = Path("docs/preproduction/P0.21_Implementation_Issue_Set.md")

EXPECTED_ROLES = [
    "bellhouse_archivist",
    "fog_listener",
    "lantern_surveyor",
    "lifeboat_keeper",
    "tide_chapel_warden",
    "wreckers_heir",
]
EXPECTED_ENDINGS = [
    "drowned_released",
    "harbor_rises",
    "harbor_sealed",
    "last_lifeboat",
    "light_comes_home",
    "mixed_outcomes",
    "names_erased",
]
EXPECTED_MODES = ["cooperative", "hidden_betrayer", "outbreak"]
EXPECTED_PRIVACY = [
    "public",
    "controlled_reveal_private",
    "seat_private",
    "faction_private",
]
EXPECTED_IDS = [
    "council_commitment_id",
    "high_water_transformation_id",
    "role_assignment_id",
    "private_objective_assignment_id",
    "faction_assignment_id",
    "tidebound_conversion_id",
    "continuation_transition_id",
    "director_selection_id",
    "ending_resolution_id",
]
ALLOWED = {
    ".github/workflows/p021-production-architecture.yml",
    ".github/workflows/p022-alpha2-graybox-contract.yml",
    ".github/workflows/p023-alpha3-systems-replayability-contract.yml",
    ".github/workflows/post-prototype-reconciliation.yml",
    "docs/preproduction/P0.21_Implementation_Issue_Set.md",
    "docs/preproduction/P0.23_Alpha3_Implementation_Issue.md",
    "docs/preproduction/README.md",
    "docs/preproduction/drowned_harbor_alpha3_systems_replayability_contract_schema_v1.json",
    "docs/preproduction/drowned_harbor_alpha3_systems_replayability_contract_v1.json",
    "docs/preproduction/post_prototype_status_v1.json",
    "docs/releases/P0.23-alpha3-systems-replayability-contract.md",
    "docs/roadmap/Post_P0.19_Production_Candidate_Roadmap.md",
    "docs/technical/Drowned_Harbor_Alpha3_Systems_and_Replayability_Contract_v1.md",
    "tools/test_validate_p023_alpha3_systems_replayability_contract.py",
    "tools/validate_p023_alpha3_systems_replayability_contract.py",
}


class ValidationError(ValueError):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValidationError(message)


def load(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    require(isinstance(value, dict), f"object required: {path}")
    return value


def canonical(value: Any) -> str:
    payload = json.dumps(
        value, sort_keys=True, separators=(",", ":"), ensure_ascii=False
    ).encode()
    return hashlib.sha256(payload).hexdigest()


def validate_contract(data: dict[str, Any]) -> None:
    require(
        data["contract_kind"]
        == "drowned_harbor_alpha3_systems_replayability_contract",
        "kind drift",
    )
    require(data["schema_version"] == 1, "schema version drift")
    require(
        data["release"]
        == {
            "release_id": "P0.23",
            "issue": 106,
            "baseline": BASE,
            "branch": BRANCH,
            "state": "active_planning",
        },
        "release drift",
    )
    require(
        data["authorization"]
        == {
            "planning_only": True,
            "runtime_implementation": False,
            "alpha3_issue_created": False,
            "alpha3_activation_authorized": False,
            "normal_library_visibility": False,
            "ordinary_export_inclusion": False,
            "human_evidence_claimed": False,
        },
        "authorization drift",
    )
    inherited = data["inherited_alpha2"]
    require(
        inherited["merged_main_sha"] == BASE
        and inherited["package_digest"]
        == "ee9e2f21b23f2b8f7ac8c8be1520c6ebcb679807a5f0dbd0d23825824b2f90b7"
        and inherited["scenario_digest"]
        == "5927dba92238512fdc74b10387ea7378f00d74a462445749d6493a512b7d7a0d"
        and inherited["localization_digest"]
        == "137919b02a572fc1c844521c38633bf27ad49bcb9d1fe8a83147db2210d1a227",
        "alpha2 identity drift",
    )
    require(
        data["target_versions"]
        == {
            "package_version": 3,
            "scenario_version": 3,
            "localization_version": 3,
            "provider_version": 3,
            "snapshot_version": 3,
        },
        "target version drift",
    )
    require(
        [row["mode_id"] for row in data["mode_plans"]] == EXPECTED_MODES,
        "mode drift",
    )
    require(
        data["mode_plans"][0]["minimum_seats"] == 1
        and data["mode_plans"][1]["minimum_seats"] == 3
        and data["mode_plans"][2]["minimum_seats"] == 2,
        "seat minima drift",
    )
    require(data["deferred_modes"] == ["hunted", "rival_crews"], "deferred mode drift")
    require(
        data["role_system"]["role_archetype_order"] == EXPECTED_ROLES
        and data["role_system"]["role_required_for_ending"] is False,
        "role plan drift",
    )
    require(
        data["faction_system"]["private_factions"] == ["bellmarked"]
        and data["faction_system"]["no_hidden_faction_required_for_valid_route"]
        is True,
        "faction drift",
    )
    require(
        data["transformation_system"]["conversion_identity"]
        == "tidebound_conversion_id"
        and data["transformation_system"]["mid_session_cure_supported"] is False,
        "conversion drift",
    )
    require(
        data["continuation_system"]["restless_forms"]
        == ["bell_witness", "drowned_guide", "lighthouse_guardian"],
        "continuation drift",
    )
    content = data["content_system"]
    require(
        len(content["items"]) == 12
        and len(content["cards"]) == 12
        and len(content["resources"]) == 8
        and len(content["hazards"]) == 12,
        "content inventory drift",
    )
    require(
        sum(len(values) for values in content["encounters_by_stage"].values()) == 19,
        "encounter inventory drift",
    )
    require(
        data["director_system"]["anti_repeat_window"] == 3
        and data["director_system"]["unbounded_generation_allowed"] is False,
        "Director drift",
    )
    require(
        data["ending_system"]["ending_ids"] == EXPECTED_ENDINGS
        and data["ending_system"][
            "every_reachable_ending_attributes_every_stable_seat"
        ]
        is True,
        "ending drift",
    )
    require(
        data["persistence"]["snapshot_version"] == 3
        and data["persistence"]["migration_policy"]
        == "explicit_alpha2_snapshot_v2_to_alpha3_snapshot_v3_or_fail_closed",
        "migration drift",
    )
    require(
        data["persistence"]["exactly_once_identities"] == EXPECTED_IDS,
        "exactly-once inventory drift",
    )
    require(
        data["privacy"]["classes"] == EXPECTED_PRIVACY
        and data["privacy"]["director_private_access"] is False
        and data["privacy"]["surrogate_private_access"] is False,
        "privacy drift",
    )
    replayability = data["replayability"]
    require(
        replayability["minimum_total_runs"] == 126
        and replayability["repeat_each_case"] == 2
        and replayability["maximum_accepted_actions_per_run"] == 192
        and replayability["maximum_rejections_before_diagnostic"] == 8
        and replayability["deadlock_free_required"] is True,
        "replay matrix drift",
    )
    require(
        data["traceability"]["runtime_may_load_authoring_references"] is False
        and data["traceability"]["runtime_may_load_prototype_fixtures"] is False,
        "runtime source boundary drift",
    )
    require(
        data["implementation_issue"]
        == {
            "release_id": "v0.2.0-alpha.3",
            "title": "Drowned Harbor Systems & Replayability",
            "state": "planned_blocked",
            "github_issue": None,
            "branch": "feature/v0.2.0-alpha.3-systems-replayability",
            "draft_pr_title": "v0.2.0-alpha.3 — Drowned Harbor Systems & Replayability",
            "codex_expected": True,
            "recommended_codex_effort": "very_high",
            "activation_authorized": False,
            "issue_definition_path": "docs/preproduction/P0.23_Alpha3_Implementation_Issue.md",
        },
        "implementation issue activated or drifted",
    )
    require(all(value is False for value in data["evidence"].values()), "unsupported evidence claim")


def validate_schema(schema: dict[str, Any], contract: dict[str, Any]) -> None:
    require(
        schema.get("$schema") == "https://json-schema.org/draft/2020-12/schema",
        "schema dialect drift",
    )
    require(schema.get("additionalProperties") is False, "schema opened")
    require(set(schema.get("required", [])) == set(contract), "schema required drift")
    require(set(schema.get("properties", {})) == set(contract), "schema property drift")
    require(
        schema["properties"]["contract_kind"].get("const")
        == contract["contract_kind"],
        "schema kind drift",
    )
    require(
        schema["properties"]["release"]["properties"]["baseline"].get("const")
        == BASE,
        "schema baseline drift",
    )


def validate_historical_status(status: dict[str, Any]) -> None:
    require(
        status["schema_version"] == 2 and status["protected_main"] == BASE,
        "status baseline drift",
    )
    require(
        status["production"]["default_tale_id"] == "lantern_house_vertical_slice"
        and status["production"]["tale_count"] == 1,
        "production default drift",
    )
    require(
        status["drowned_harbor"]["alpha2"]["merged_main_sha"] == BASE
        and status["drowned_harbor"]["status"]
        == "developer_only_alpha2_end_to_end_graybox_export_excluded",
        "alpha2 status drift",
    )
    require(
        status["current_release"]
        == {
            "release_id": "P0.23",
            "issue": 106,
            "branch": BRANCH,
            "type": "documentation_schema_validation",
            "runtime_authority_created": False,
        },
        "current release drift",
    )
    require(
        status["recommended_next_release"]["state"] == "planned_blocked"
        and status["recommended_next_release"]["github_issue"] is None
        and status["recommended_next_release"]["activation_authorized"] is False,
        "alpha3 activated",
    )
    require(
        status["runtime_implementation_authorized"] is False
        and status["human_evidence_claimed"] is False,
        "unsupported authorization/evidence",
    )


def validate_later_status(status: dict[str, Any]) -> None:
    require(status.get("schema_version") == 3, "successor status schema drift")
    require(status.get("status_kind") == "post_prototype_project_status", "status kind drift")
    require(status.get("as_of_date") == "2026-08-04", "status date drift")
    require(status.get("protected_main") == ALPHA3_MERGE, "Alpha.3 merge baseline drift")
    require(status.get("playable_release") == "v0.1.9", "normal playable release drift")
    require(status.get("runtime_implementation_authorized") is False, "runtime authorization drift")
    require(status.get("human_evidence_claimed") is False, "human evidence claimed")
    require(status.get("unrelated_open_pull_requests") == [32], "unrelated PR boundary drift")

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
        "completed Alpha.3 identity drift",
    )
    require(
        status.get("current_release")
        == {
            "branch": RECONCILIATION_BRANCH,
            "issue": 111,
            "release_id": "post_alpha3_status_reconciliation",
            "runtime_authority_created": False,
            "type": "documentation_status_reconciliation",
        },
        "successor current release drift",
    )
    require(
        status.get("drowned_harbor")
        == {
            "ordinary_playable": False,
            "status": "developer_only_alpha3_systems_replayability_export_excluded",
        },
        "Drowned Harbor successor boundary drift",
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
        "production successor boundary drift",
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
        "Companion remediation identity drift",
    )
    require(
        status.get("recommended_next_release")
        == {
            "activation_authorized": False,
            "codex_required": False,
            "github_issue": 110,
            "release_id": "DH-VBL-001",
            "state": "planned_blocked",
            "title": "Drowned Harbor Visual Baseline Registration & Board Production Conversion Brief 01",
        },
        "issue #110 activated or drifted",
    )
    gates = {row.get("issue"): row.get("state") for row in status.get("gates", [])}
    require(
        gates == {7: "open", 39: "deferred_open", 110: "planned_blocked"},
        "successor gate inventory drift",
    )
    preserved = status.get("preserved_authorities", {})
    require(
        preserved.get("alpha3_candidate_head") == ALPHA3_CANDIDATE
        and preserved.get("alpha3_merge") == ALPHA3_MERGE,
        "preserved Alpha.3 authority drift",
    )


def validate_status(status: dict[str, Any], *, later_succession: bool = False) -> None:
    if later_succession:
        validate_later_status(status)
    else:
        validate_historical_status(status)


def validate_preserved_runtime(root: Path) -> None:
    package = load(root / "game/data/tales/drowned_harbor/tale_package_v2.json")
    require(
        canonical(package)
        == "ee9e2f21b23f2b8f7ac8c8be1520c6ebcb679807a5f0dbd0d23825824b2f90b7",
        "alpha2 package changed",
    )
    require(
        hashlib.sha256(
            (root / "game/data/scenarios/drowned_harbor_graybox_v2.json").read_bytes()
        ).hexdigest()
        == "5927dba92238512fdc74b10387ea7378f00d74a462445749d6493a512b7d7a0d",
        "alpha2 scenario changed",
    )
    require(
        hashlib.sha256(
            (
                root
                / "game/data/tales/drowned_harbor/localization_graybox_en_v2.json"
            ).read_bytes()
        ).hexdigest()
        == "137919b02a572fc1c844521c38633bf27ad49bcb9d1fe8a83147db2210d1a227",
        "alpha2 localization changed",
    )
    catalog = load(root / "game/data/tales/tale_catalog_v1.json")
    require(
        canonical(catalog)
        == "2b478fd0d11fa075c2050409193aa06e6b9ca4dcf6efd4e4c550a9f3a5ff9db6",
        "catalog changed",
    )


def validate_docs(root: Path, *, later_succession: bool = False) -> None:
    joined = "\n".join(
        (root / path).read_text(encoding="utf-8")
        for path in [TECH, ISSUE, RELEASE, ROADMAP, INDEX, ISSUE_SET]
    )
    for phrase in [
        "P0.23",
        "planned_blocked",
        "Very High",
        "Hunted and Rival Crews",
        "Automation is machine evidence only",
        "Issue #39",
        "issue #7",
        "PR #32",
    ]:
        require(phrase.lower() in joined.lower(), f"documentation missing: {phrase}")
    for claim in [
        "human playtesting passed",
        "privacy certified",
        "security certified",
        "production ready",
        "public release authorized",
        "balance validated",
    ]:
        require(claim not in joined.lower(), f"unsupported claim: {claim}")

    if later_succession:
        current = "\n".join(
            (root / path).read_text(encoding="utf-8") for path in [ROADMAP, INDEX]
        )
        for phrase in [
            ALPHA3_MERGE,
            "issue #108 / PR #109",
            "issue #111",
            "issue #110",
            "developer-only",
            "ordinary Windows/Linux exports",
        ]:
            require(phrase.lower() in current.lower(), f"successor documentation missing: {phrase}")
        for stale in [
            "P0.23 is the sole active release",
            "P0.23 creates planning authority only",
            "No Alpha.3 implementation issue",
            "Alpha.3 runtime blocked",
            "no GitHub issue",
        ]:
            require(stale.lower() not in current.lower(), f"stale current-state claim: {stale}")


def validate_git(root: Path) -> None:
    branch = (
        os.environ.get("GITHUB_HEAD_REF")
        or os.environ.get("GITHUB_REF_NAME")
        or subprocess.check_output(
            ["git", "branch", "--show-current"], cwd=root, text=True
        ).strip()
    )
    require(branch == BRANCH, f"wrong branch: {branch}")
    require(
        subprocess.check_output(
            ["git", "merge-base", "HEAD", BASE], cwd=root, text=True
        ).strip()
        == BASE,
        "baseline changed",
    )
    changed = set(
        filter(
            None,
            subprocess.check_output(
                ["git", "diff", "--name-only", BASE], cwd=root, text=True
            ).splitlines(),
        )
    )
    require(
        changed == ALLOWED,
        f"path boundary mismatch: missing={sorted(ALLOWED - changed)} unexpected={sorted(changed - ALLOWED)}",
    )


def validate(
    root: Path = ROOT,
    *,
    check_git: bool = True,
    later_succession: bool = False,
) -> None:
    contract = load(root / CONTRACT)
    validate_contract(contract)
    validate_schema(load(root / SCHEMA), contract)
    validate_status(load(root / STATUS), later_succession=later_succession)
    validate_preserved_runtime(root)
    validate_docs(root, later_succession=later_succession)
    if check_git:
        validate_git(root)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--skip-git-boundary", action="store_true")
    parser.add_argument("--later-succession", action="store_true")
    args = parser.parse_args()
    try:
        validate(
            check_git=not args.skip_git_boundary,
            later_succession=args.later_succession,
        )
    except (
        ValidationError,
        OSError,
        subprocess.CalledProcessError,
        json.JSONDecodeError,
    ) as exc:
        print(f"P0.23 validation failed: {exc}")
        return 1
    mode = "later succession" if args.later_succession else "historical"
    print(f"P0.23 Alpha.3 systems and replayability contract validated ({mode})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
