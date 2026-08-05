#!/usr/bin/env python3
from __future__ import annotations
import argparse, hashlib, json, os, subprocess, sys
from pathlib import Path

ROOT = Path(".")
BASE = "eaa40667322928d39f6cee7c4bff3f74775c2792"
BRANCH = "docs/post-dh-ux-final-status-reconciliation"
STATUS = Path("docs/preproduction/post_prototype_status_v1.json")
ADDENDUM = Path("docs/tales/drowned_harbor/ux/drowned_harbor_final_ux_advisory_addendum_v2.json")
DOCS = [Path("README.md"), Path("docs/preproduction/README.md"), Path("docs/roadmap/Post_P0.19_Production_Candidate_Roadmap.md")]
ALLOWED = {
    "README.md",
    ".github/workflows/p021-production-architecture.yml",
    ".github/workflows/p022-alpha2-graybox-contract.yml",
    ".github/workflows/p023-alpha3-systems-replayability-contract.yml",
    ".github/workflows/post-prototype-reconciliation.yml",
    "docs/preproduction/README.md",
    "docs/preproduction/post_prototype_status_v1.json",
    "docs/roadmap/Post_P0.19_Production_Candidate_Roadmap.md",
    "tools/test_validate_post_dh_ux_final_status.py",
    "tools/validate_post_dh_ux_final_status.py",
}
STATUS_SHA = "13f947996f4a119431c62377b76506079babacacf37a752fd0e9b833c01edeb7"
ADDENDUM_SHA = "87cd6535f29337f79e7cbe8556f033019aea8e277ad4aefebe90384e92de65d6"

class ValidationError(Exception):
    pass

def need(value, message):
    if not value:
        raise ValidationError(message)

def load(path):
    return json.loads((ROOT / path).read_text(encoding="utf-8"))

def digest(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode()).hexdigest()

def validate_status(status):
    need(digest(status) == STATUS_SHA, "status drift")
    need(status["schema_version"] == 8 and status["protected_main"] == BASE, "status identity drift")
    need(status["pending_inputs"] == [], "unexpected pending input")
    need(status["current_release"] == {
        "activation_authorized": False,
        "issue": None,
        "release_id": None,
        "runtime_authority_created": False,
        "state": "none_active_after_reconciliation",
        "type": None,
    }, "active release drift")
    need(status["recommended_next_release"] == {
        "activation_authorized": False,
        "codex_required": False,
        "github_issue": None,
        "release_id": None,
        "state": "unselected_metadata_only_clean_room_source_planning_eligible_explicit_activation_required",
        "title": None,
    }, "successor selected or eligibility drift")
    need(status["preserved_authorities"]["dh_ux_final_addendum_registration_merge"] == BASE, "addendum merge drift")
    ux = status["visual_planning"]["ux_addendum"]
    need(ux["release_id"] == "DH-UX-ADDENDUM-REG-001" and ux["record_id"] == "DH-UX-FINAL-001", "addendum identity drift")
    need(ux["merged_main_sha"] == BASE and ux["issue"] == 135 and ux["pull_request"] == 136, "addendum coordinates drift")
    need(ux["governing_advisory_replaced"] is False, "DH-UX-001 replaced")
    need(ux["clean_room_source_planning_authorized"] is False and ux["source_creation_authorized"] is False and ux["direct_pixel_use_authorized"] is False and ux["implementation_authorized"] is False, "planning or implementation authorized")
    need(ux["five_recommendation_classes"] == [
        "pixel_independent_advisory",
        "clean_room_source_planning_input_gated",
        "implementation_dependent_deferred",
        "human_evidence_dependent",
        "rejected_or_out_of_scope",
    ], "recommendation classes drift")
    need(len(ux["six_part_rights_planning_gate"]) == 6, "six-part gate drift")
    held = status["visual_planning"]["held_source_plan"]
    need(held == {
        "admitted_to_repository": False,
        "bytes": 14913,
        "filename": "DH-SOURCE-PLAN-001_Clean_Room_Source_Art_and_Composition_Planning_Package_v1.zip",
        "refresh_required_after_explicit_activation": True,
        "sha256": "34fb5de40bd1dabfde66cd4792d8ad67173191de088cf65e5be0ecee1a1f444b",
        "state": "external_draft_not_activated",
    }, "held source-plan drift")
    rights = status["visual_planning"]["rights_provenance"]
    need(rights["asset_count"] == 25 and rights["max_rights_tier"] == "R1_private_internal_reference", "asset/R1 drift")
    need(rights["reference_only_nonproduction"] is True and rights["conversion_readiness"] == "not_ready", "lifecycle drift")
    for key in ["direct_pixel_use_cleared", "implementation_authorized", "public_distribution_cleared", "runtime_art_authorized", "source_art_authorized", "legal_clearance_created", "candidate_created"]:
        need(rights[key] is False, f"forbidden rights authority: {key}")
    production = status["production"]
    need(production["default_tale_id"] == "lantern_house_vertical_slice" and production["tale_count"] == 1, "default Tale drift")
    for key in ["drowned_harbor_catalog_registered", "drowned_harbor_normal_library_visible", "drowned_harbor_ordinary_export_included", "drowned_harbor_provider_registered", "drowned_harbor_startup_or_fallback_registered"]:
        need(production[key] is False, f"Drowned Harbor production opening: {key}")
    need(status["human_evidence_claimed"] is False and status["runtime_implementation_authorized"] is False and status["ux_implementation_authorized"] is False and status["visual_implementation_authorized"] is False, "evidence or implementation authority drift")
    need(status["unrelated_open_pull_requests"] == [32], "PR #32 drift")

def validate_addendum(addendum):
    need(digest(addendum) == ADDENDUM_SHA, "registered addendum drift")
    need(addendum["identity"]["addendum_to_record_id"] == "DH-UX-001", "governing advisory link drift")
    need(addendum["authorization"]["clean_room_source_planning_eligibility_established"] is True, "planning eligibility lost")
    for key, value in addendum["authorization"].items():
        if key != "clean_room_source_planning_eligibility_established":
            need(value is False, f"registered addendum authority drift: {key}")

def validate_docs():
    text = "\n".join((ROOT / path).read_text(encoding="utf-8") for path in DOCS).lower()
    required = [
        BASE,
        "dh-ux-addendum-reg-001",
        "dh-ux-final-001",
        "issue #135 / pr #136",
        "subordinate addendum",
        "not a replacement",
        "five recommendation classes",
        "six-part rights/planning gate",
        "pixel_independent_advisory",
        "clean_room_source_planning_input_gated",
        "implementation_dependent_deferred",
        "human_evidence_dependent",
        "rejected_or_out_of_scope",
        "dh-source-plan-001_clean_room_source_art_and_composition_planning_package_v1.zip",
        "34fb5de40bd1dabfde66cd4792d8ad67173191de088cf65e5be0ecee1a1f444b",
        "external, unactivated draft",
        "clean-room source planning remains unauthorized",
        "r1_private_internal_reference",
        "reference_only_nonproduction",
        "conversion readiness `not_ready`",
        "implementation authorization false",
        "no successor release is selected or activated",
        "lantern house remains the sole normal/default tale",
        "drowned harbor remains developer-only",
        "issue #39",
        "issue #7",
        "pr #32",
        "automation is not human evidence",
    ]
    for phrase in required:
        need(phrase in text, f"missing current documentation: {phrase}")
    forbidden = [
        "clean-room source planning is authorized",
        "source creation is authorized",
        "runtime composition is authorized",
        "direct generated-pixel use is authorized",
        "dh-ux-final-001 replaces dh-ux-001",
        "held source-plan is activated",
        "candidate approved",
        "production ready",
        "shipping authorized",
        "accessibility certified",
        "human evidence passed",
        "rights are fully cleared",
    ]
    for phrase in forbidden:
        need(phrase not in text, f"stale or unsupported claim: {phrase}")

def branch_name():
    return os.environ.get("GITHUB_HEAD_REF") or os.environ.get("GITHUB_REF_NAME") or subprocess.check_output(["git", "branch", "--show-current"], text=True).strip()

def validate_git():
    if branch_name() != BRANCH:
        return
    actual = {line for line in subprocess.check_output(["git", "diff", "--name-only", f"{BASE}...HEAD"], text=True).splitlines() if line}
    need(actual == ALLOWED, f"path mismatch missing={sorted(ALLOWED-actual)} unexpected={sorted(actual-ALLOWED)}")
    prohibited_ext = {".png", ".jpg", ".jpeg", ".webp", ".zip", ".psd", ".kra", ".blend", ".aseprite", ".tscn", ".tres"}
    prohibited_prefix = ("game/", "art/source/", "game/assets/", "web/companion/", "services/room-service/")
    for path in actual:
        need(not path.startswith(prohibited_prefix), f"prohibited path {path}")
        need(Path(path).suffix.lower() not in prohibited_ext, f"prohibited extension {path}")

def validate(check_git=True):
    validate_status(load(STATUS))
    validate_addendum(load(ADDENDUM))
    validate_docs()
    if check_git:
        validate_git()

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--skip-git-boundary", action="store_true")
    args = parser.parse_args()
    validate(not args.skip_git_boundary)
    print("Validated post-DH-UX-FINAL current status and succession boundary")
    return 0

if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (ValidationError, KeyError, TypeError, IndexError, json.JSONDecodeError, subprocess.CalledProcessError, OSError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1)
