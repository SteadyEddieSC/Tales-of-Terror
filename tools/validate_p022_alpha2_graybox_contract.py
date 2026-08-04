#!/usr/bin/env python3
"""Validate the P0.22 Drowned Harbor alpha.2 graybox route contract."""

from __future__ import annotations

import argparse
import json
import subprocess
from pathlib import Path
from typing import Any

ROOT = Path(".")
BASELINE = "85b77d5216472afdb4abb7598917d5052eed180a"
CONTRACT_PATH = Path("docs/preproduction/drowned_harbor_alpha2_graybox_route_contract_v1.json")
SCHEMA_PATH = Path("docs/preproduction/drowned_harbor_alpha2_graybox_route_contract_schema_v1.json")
TECHNICAL_PATH = Path("docs/technical/Drowned_Harbor_Alpha2_Graybox_Route_Contract_v1.md")
ISSUE_PATH = Path("docs/preproduction/P0.22_Alpha2_Implementation_Issue.md")
RELEASE_PATH = Path("docs/releases/P0.22-alpha2-graybox-contract.md")
STATUS_PATH = Path("docs/preproduction/post_prototype_status_v1.json")
ROADMAP_PATH = Path("docs/roadmap/Post_P0.19_Production_Candidate_Roadmap.md")
PREPROD_README_PATH = Path("docs/preproduction/README.md")
P021_ISSUE_SET_PATH = Path("docs/preproduction/P0.21_Implementation_Issue_Set.md")

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
STAGE_ORDER = [
    "low_tide_arrival_v1", "bellhouse_ledger_v1", "lighthouse_council_v1",
    "high_water_v1", "last_light_v1", "ending_resolution_v1",
    "epilogue_attribution_v1", "rematch_title_cleanup_v1",
]
TRANSITIONS = [
    "transition_low_tide_to_bellhouse", "transition_bellhouse_to_council",
    "transition_council_to_high_water", "transition_high_water_to_last_light",
    "transition_last_light_to_ending", "transition_ending_to_epilogue",
    "transition_epilogue_to_cleanup",
]
PRIVACY = ["public", "controlled_reveal_private", "seat_private", "faction_private"]
DIRECTOR = [
    "authoritative_revision", "connected_seat_count", "stage_id",
    "public_progress", "public_pressure", "public_recovery_count",
]
ROOT_FIELDS = {
    "contract_kind", "schema_version", "release", "authorization", "identities",
    "route", "stages", "transitions", "systems", "persistence", "privacy",
    "safe_routes", "traceability", "implementation_issue", "evidence",
}

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

def closed(node: Any, expected: set[str], label: str) -> None:
    require(isinstance(node, dict), f"schema object missing: {label}")
    require(node.get("type") == "object", f"schema type drift: {label}")
    require(node.get("additionalProperties") is False, f"schema opened: {label}")
    require(set(node.get("required", [])) == expected, f"schema required drift: {label}")
    require(set(node.get("properties", {})) == expected, f"schema properties drift: {label}")

def validate_schema(schema: dict[str, Any]) -> None:
    require(schema.get("$schema") == "https://json-schema.org/draft/2020-12/schema", "schema dialect drift")
    closed(schema, ROOT_FIELDS, "root")
    props = schema["properties"]
    require(props["contract_kind"].get("const") == "drowned_harbor_alpha2_graybox_route_contract", "schema kind drift")
    require(props["schema_version"].get("const") == 1, "schema version drift")
    closed(props["release"], {"release_id","issue","baseline","branch","state"}, "release")
    closed(props["authorization"], {"planning_only","runtime_implementation","alpha2_issue_created","alpha2_activation_authorized","normal_library_visibility","ordinary_export_inclusion","human_evidence_claimed"}, "authorization")
    closed(props["route"], {"entry_stage","terminal_stage","stage_order","transition_order","linear","bounded","terminal_cleanup_required"}, "route")
    closed(props["privacy"], {"classes","shared_output_policy","director_input_allowlist","private_projection_owner","director_private_access"}, "privacy")
    closed(props["implementation_issue"], {"release_id","title","state","github_issue","branch","draft_pr_title","codex_expected","recommended_codex_effort","activation_authorized","issue_definition_path"}, "implementation_issue")
    require(schema.get("$defs", {}).get("stage", {}).get("additionalProperties") is False, "stage schema opened")
    require(schema.get("$defs", {}).get("transition", {}).get("additionalProperties") is False, "transition schema opened")

def validate_contract(data: dict[str, Any]) -> None:
    require(set(data) == ROOT_FIELDS, "contract root drift")
    require(data["contract_kind"] == "drowned_harbor_alpha2_graybox_route_contract", "contract kind drift")
    require(data["schema_version"] == 1, "contract schema drift")
    require(data["release"] == {
        "release_id":"P0.22","issue":102,"baseline":BASELINE,
        "branch":"docs/p0.22-alpha2-graybox-contract","state":"active_planning"
    }, "release identity drift")
    require(data["authorization"] == {
        "planning_only":True,"runtime_implementation":False,"alpha2_issue_created":False,
        "alpha2_activation_authorized":False,"normal_library_visibility":False,
        "ordinary_export_inclusion":False,"human_evidence_claimed":False
    }, "authorization drift")
    require(data["identities"] == {
        "tale_id":"drowned_harbor","provider_id":"drowned_harbor_authorities_v1",
        "package_kind":"tale","package_schema_version":1,"target_package_version":2,
        "target_scenario_version":2,"target_snapshot_version":2
    }, "identity/version drift")
    route = data["route"]
    require(route["entry_stage"] == STAGE_ORDER[0] and route["terminal_stage"] == STAGE_ORDER[-1], "route endpoints drift")
    require(route["stage_order"] == STAGE_ORDER, "stage order drift")
    require(route["transition_order"] == TRANSITIONS, "transition order drift")
    require(route["linear"] is True and route["bounded"] is True and route["terminal_cleanup_required"] is True, "route policy drift")

    stages = data["stages"]
    require(isinstance(stages, list) and len(stages) == 8, "stage inventory drift")
    require([row.get("stage_id") for row in stages] == STAGE_ORDER, "stage rows reordered")
    require(len({row.get("stage_id") for row in stages}) == 8, "stage IDs not unique")
    for row in stages:
        require(set(row) == {"stage_id","stage_version","authority_owner","allowed_intents","reducer_outputs","event_output","save_boundaries","rejection_policy","interruption_policy","maximum_accepted_actions"}, f"stage field drift: {row.get('stage_id')}")
        require(row["stage_version"] == 1, "stage version drift")
        require(row["authority_owner"] in {"rules_session","role_session","session_coordinator"}, "ambiguous stage owner")
        require(row["allowed_intents"] and row["reducer_outputs"], "stage authority incomplete")
        require("stage_entry" in row["save_boundaries"] and "stage_complete" in row["save_boundaries"] or row["stage_id"] == STAGE_ORDER[-1], "stage save boundary incomplete")
        require(row["rejection_policy"] == "state_and_rng_noop", "rejection mutates state/RNG")
        require(row["interruption_policy"] == "restore_exact_checkpoint_or_fail_closed", "interruption policy drift")
        require(1 <= row["maximum_accepted_actions"] <= 24, "stage action bound invalid")

    transitions = data["transitions"]
    require(len(transitions) == 7 and [row.get("transition_id") for row in transitions] == TRANSITIONS, "transition inventory drift")
    require([(row["from_stage"], row["to_stage"]) for row in transitions] == list(zip(STAGE_ORDER, STAGE_ORDER[1:])), "transition graph unreachable or non-linear")
    for row in transitions:
        require(row["condition"] == "source_complete_and_target_preconditions_valid", "transition condition drift")
        require(row["save_checkpoint"] and 1 <= row["maximum_attempts"] <= 3, "transition unbounded")
    require(transitions[2]["exactly_once_identity"] == "council_commitment_id", "Council exactly-once identity drift")
    require(transitions[3]["exactly_once_identity"] == "high_water_transformation_id", "High Water identity drift")
    require(not any(row["from_stage"] == STAGE_ORDER[-1] for row in transitions), "terminal stage has outgoing transition")

    systems = data["systems"]
    require(systems["movement_owner"] == "board_state", "movement owner drift")
    require(systems["stage_and_decision_owner"] == "rules_session", "decision owner drift")
    require(systems["private_attribution_owner"] == "role_session", "private owner drift")
    require(systems["cleanup_owner"] == "session_coordinator", "cleanup owner drift")
    require(systems["council_identity"] == "council_commitment_id", "Council system identity drift")
    require(systems["high_water_identity"] == "high_water_transformation_id", "High Water system identity drift")
    require(len(systems["rng_streams"]) == 4 and len(set(systems["rng_streams"])) == 4, "named RNG stream drift")

    persistence = data["persistence"]
    require(persistence["migration_policy"] == "explicit_alpha1_snapshot_v1_to_alpha2_snapshot_v2_or_fail_closed", "migration policy drift")
    require(persistence["checkpoints"] == STAGE_ORDER, "checkpoint coverage drift")
    require(persistence["processed_request_and_event_ids_persisted"] is True, "exactly-once IDs not persisted")
    require(persistence["replay_policy"] == "equal_authoritative_inputs_seeds_and_snapshot_produce_equivalent_outcome", "replay policy drift")
    require(persistence["rollback_policy"] == "reject_without_partial_authority_and_preserve_prior_snapshot", "rollback drift")

    privacy = data["privacy"]
    require(privacy["classes"] == PRIVACY, "privacy class drift")
    require(privacy["director_input_allowlist"] == DIRECTOR, "Director allowlist drift")
    require(privacy["director_private_access"] is False, "Director reads private state")
    require(privacy["shared_output_policy"] == "public_projection_only_without_private_terms_or_desirability_hints", "shared projection drift")

    safe = data["safe_routes"]
    require(safe["supported_seat_counts"] == list(range(1,9)), "1-8 seat coverage drift")
    require(safe["stage_order"] == STAGE_ORDER, "safe route stage drift")
    require(safe["maximum_accepted_actions"] == 96, "safe route action bound drift")
    require(safe["maximum_rejections_before_diagnostic"] == 8, "rejection watchdog drift")
    require(safe["deadlock_free_required"] is True, "deadlock requirement removed")
    require(safe["disconnect_policy"] == "surrogate_control_preserves_stable_seat_state", "stable-seat fallback drift")

    trace = data["traceability"]
    require(trace["runtime_may_load_authoring_references"] is False, "authoring reference became runtime input")
    require(trace["runtime_may_load_prototype_fixtures"] is False, "prototype fixture became runtime input")
    require(trace["prototype_fixture_path"] == "game/tests/drowned_harbor_dev_only/", "prototype source drift")
    require(len(trace["future_outputs"]) == 5, "future output inventory drift")

    issue = data["implementation_issue"]
    require(issue == {
        "release_id":"v0.2.0-alpha.2","title":"Drowned Harbor End-to-End Graybox",
        "state":"planned_blocked","github_issue":None,
        "branch":"feature/v0.2.0-alpha.2-end-to-end-graybox",
        "draft_pr_title":"v0.2.0-alpha.2 — Drowned Harbor End-to-End Graybox",
        "codex_expected":True,"recommended_codex_effort":"very_high",
        "activation_authorized":False,
        "issue_definition_path":"docs/preproduction/P0.22_Alpha2_Implementation_Issue.md"
    }, "inactive implementation issue drift")
    require(all(value is False for value in data["evidence"].values()), "unsupported evidence claim")

def validate_status(status: dict[str, Any]) -> None:
    require(status.get("protected_main") == BASELINE, "status baseline drift")
    require(status.get("current_release") == {
        "release_id":"P0.22","issue":102,"branch":"docs/p0.22-alpha2-graybox-contract",
        "type":"documentation_schema_validation","runtime_authority_created":False
    }, "current release drift")
    require(status.get("recommended_next_release") == {
        "release_id":"v0.2.0-alpha.2","title":"Drowned Harbor End-to-End Graybox",
        "state":"planned_blocked","github_issue":None,"codex_required":True,
        "recommended_codex_effort":"very_high","activation_authorized":False
    }, "next release activated or drifted")
    require(status.get("runtime_implementation_authorized") is False, "runtime authorized")
    require(status.get("human_evidence_claimed") is False, "human evidence claimed")

def validate_docs(root: Path, later_succession: bool = False) -> None:
    docs = {
        "technical": read_text(root, TECHNICAL_PATH),
        "issue": read_text(root, ISSUE_PATH),
        "release": read_text(root, RELEASE_PATH),
        "roadmap": read_text(root, ROADMAP_PATH),
        "preproduction": read_text(root, PREPROD_README_PATH),
        "issue_set": read_text(root, P021_ISSUE_SET_PATH),
    }
    required = {
        "technical":["The route is linear","council_commitment_id","high_water_transformation_id","Automation is not human evidence","Very High"],
        "issue":["State:** `planned_blocked`","GitHub issue:** none","Recommended Codex effort:** Very High","Codex must stop"],
        "release":["Codex used: no","alpha.2 runtime issue remains","Automation is machine evidence only"],
    }
    if not later_succession:
        required.update({
            "roadmap":["P0.22 alpha.2 planning active","No alpha.2 GitHub issue, branch, or Codex prompt is created","Lantern House remains the sole normal/default Tale"],
            "preproduction":["Current package:** P0.22","Alpha.2 remains `planned_blocked`","Codex is not required for this planning release"],
            "issue_set":["P0.21 and v0.2.0-alpha.1 are completed","P0.22 is the sole active planning release","v0.2.0-alpha.2 remains blocked"],
        })
    for label, phrases in required.items():
        for phrase in phrases:
            require(phrase in docs[label], f"{label} missing required phrase: {phrase}")
    combined = "\n".join(docs.values())
    for phrase in ("alpha.2 runtime is active","normal Tale catalog contains Drowned Harbor","Automation proves human experience"):
        require(phrase not in combined, f"prohibited claim: {phrase}")

def validate_git_boundary(root: Path) -> None:
    try:
        output = subprocess.check_output(["git","diff","--name-only",f"{BASELINE}...HEAD"], cwd=root, text=True, stderr=subprocess.STDOUT)
    except (FileNotFoundError, subprocess.CalledProcessError) as exc:
        raise ValidationError(f"unable to evaluate git boundary: {exc}") from exc
    actual = {line.strip() for line in output.splitlines() if line.strip()}
    require(actual == ALLOWED_PATHS, f"path boundary mismatch: missing={sorted(ALLOWED_PATHS-actual)} unexpected={sorted(actual-ALLOWED_PATHS)}")
    require(not any(path.startswith(("game/","services/","web/","packaging/","art/","audio/")) for path in actual), "runtime/service/media path changed")
    require("README.md" not in actual and "CHANGELOG.md" not in actual, "unplanned project-facing path changed")

def validate(
    root: Path = ROOT,
    check_git: bool = True,
    later_succession: bool = False,
) -> None:
    validate_schema(read_json(root, SCHEMA_PATH))
    validate_contract(read_json(root, CONTRACT_PATH))
    if not later_succession:
        validate_status(read_json(root, STATUS_PATH))
    else:
        read_json(root, STATUS_PATH)
    validate_docs(root, later_succession=later_succession)
    if check_git:
        validate_git_boundary(root)

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--skip-git-boundary", action="store_true")
    parser.add_argument("--later-succession", action="store_true")
    args = parser.parse_args()
    try:
        validate(
            args.root,
            check_git=not args.skip_git_boundary,
            later_succession=args.later_succession,
        )
    except ValidationError as exc:
        print(f"P0.22 alpha.2 graybox contract validation failed: {exc}")
        return 1
    print("P0.22 alpha.2 graybox route contract validated")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
