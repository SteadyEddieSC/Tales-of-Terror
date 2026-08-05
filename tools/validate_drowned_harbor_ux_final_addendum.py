#!/usr/bin/env python3
from __future__ import annotations
import argparse, hashlib, json, os, subprocess, sys
from pathlib import Path

ROOT = Path(".")
BASE = "7449e9e93bf2519b285abab7812c3600c876b04d"
BRANCH = "docs/dh-ux-final-001-addendum-registration"
RECORD = Path("docs/tales/drowned_harbor/ux/drowned_harbor_final_ux_advisory_addendum_v2.json")
SCHEMA = Path("docs/tales/drowned_harbor/ux/drowned_harbor_final_ux_advisory_addendum_schema_v2.json")
PROVENANCE = Path("art/licenses/drowned_harbor/ux/dh_ux_final_001_provenance_v2.json")
DOCS = [
    Path("docs/releases/DH-UX-FINAL-001-final-ux-advisory-addendum-registration.md"),
    Path("docs/tales/drowned_harbor/ux/Drowned_Harbor_Final_UX_Advisory_Addendum_v2.md"),
    Path("docs/tales/drowned_harbor/ux/Drowned_Harbor_Clean_Room_Source_Planning_Inputs_Gated_v2.md"),
    Path("docs/tales/drowned_harbor/ux/Drowned_Harbor_UX_Authority_Dependencies_v2.md"),
]
ALLOWED = {
    ".github/workflows/drowned-harbor-ux-final-addendum.yml",
    "docs/releases/DH-UX-FINAL-001-final-ux-advisory-addendum-registration.md",
    "docs/tales/drowned_harbor/ux/Drowned_Harbor_Final_UX_Advisory_Addendum_v2.md",
    "docs/tales/drowned_harbor/ux/Drowned_Harbor_Clean_Room_Source_Planning_Inputs_Gated_v2.md",
    "docs/tales/drowned_harbor/ux/Drowned_Harbor_UX_Authority_Dependencies_v2.md",
    "docs/tales/drowned_harbor/ux/drowned_harbor_final_ux_advisory_addendum_v2.json",
    "docs/tales/drowned_harbor/ux/drowned_harbor_final_ux_advisory_addendum_schema_v2.json",
    "art/licenses/drowned_harbor/ux/dh_ux_final_001_provenance_v2.json",
    "tools/validate_drowned_harbor_ux_final_addendum.py",
    "tools/test_validate_drowned_harbor_ux_final_addendum.py",
}
RECORD_SHA = "87cd6535f29337f79e7cbe8556f033019aea8e277ad4aefebe90384e92de65d6"
PROVENANCE_SHA = "f4c95ed23dd44c416792505428c32f23eb2dd48f12e5dca5339b82bbe921cc39"

class ValidationError(Exception):
    pass

def need(value, message):
    if not value:
        raise ValidationError(message)

def load(path):
    return json.loads((ROOT / path).read_text(encoding="utf-8"))

def digest(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode()).hexdigest()

def validate_record(record):
    need(digest(record) == RECORD_SHA, "registration record drift")
    need(record["identity"]["release_id"] == "DH-UX-ADDENDUM-REG-001", "release identity drift")
    need(record["identity"]["external_record_id"] == "DH-UX-FINAL-001", "external identity drift")
    need(record["identity"]["addendum_to_record_id"] == "DH-UX-001", "governing advisory drift")
    need(record["release"]["protected_main_base"] == BASE, "protected-main coordinate drift")
    need(record["release"]["planning_performed"] is False, "planning performed")
    need(record["release"]["planning_authorized"] is False, "planning authorized")
    package = record["external_package"]
    need(package["bytes"] == 17569, "archive byte drift")
    need(package["sha256"] == "ffc0ff48a801301764d9ef596768a437ef7302f644472271ab70a2cc58a1c3b9", "archive hash drift")
    need(package["zip_crc"] == "clean", "archive CRC drift")
    manifest = package["manifest"]
    need(manifest["bytes"] == 3294, "manifest byte drift")
    need(manifest["sha256"] == "149a5358d1df0eeae71e108a12ff5195aeee7e4b887485386dc0cb08eba8f1d1", "manifest hash drift")
    need(manifest["file_count_excluding_manifest"] == 13 and len(manifest["payloads"]) == 13, "payload count drift")
    need(not manifest["missing_payloads"] and not manifest["extra_payloads"] and not manifest["payload_hash_or_byte_mismatches"], "payload mismatch recorded")
    review = record["external_schema_review"]
    need(review["external_record_validates_against_external_schema"] is True, "external validation result drift")
    need(review["not_fully_closed"] is True, "external schema defect lost")
    need(review["unconstrained_nested_objects"] == ["registered_authorities", "authorization", "no_pixel_reuse", "proposed_next_governance"], "schema defect detail drift")
    need(record["required_sections"] == [
        "pixel_independent_ux_recommendations",
        "clean_room_source_planning_inputs_gated",
        "implementation_dependent_recommendations_deferred",
        "unresolved_assumptions_questions_and_evidence",
        "proposed_corrections_and_additions_to_dh_ux_001",
        "authority_dependencies",
    ], "required-section drift")
    need(record["recommendation_classes"] == [
        "pixel_independent_advisory",
        "clean_room_source_planning_input_gated",
        "implementation_dependent_deferred",
        "human_evidence_dependent",
        "rejected_or_out_of_scope",
    ], "recommendation-class drift")
    need(record["authority_dependencies"]["new_runtime_fields_authorized"] is False, "new runtime fields authorized")
    need(record["authority_dependencies"]["new_legal_actions_authorized"] is False, "new legal actions authorized")
    for key, value in record["no_pixel_reuse"].items():
        need(value is False, f"pixel-reuse authority: {key}")
    auth = record["authorization"]
    need(auth["clean_room_source_planning_eligibility_established"] is True, "planning eligibility lost")
    for key, value in auth.items():
        if key != "clean_room_source_planning_eligibility_established":
            need(value is False, f"forbidden authority: {key}")
    rights = record["rights_and_lifecycle"]
    need(rights == {
        "external_image_count": 25,
        "all_assets": "R1_private_internal_reference",
        "reference_only_nonproduction": True,
        "conversion_readiness": "not_ready",
        "implementation_authorized": False,
    }, "rights/lifecycle drift")
    held = record["held_source_plan"]
    need(held["bytes"] == 14913 and held["sha256"] == "34fb5de40bd1dabfde66cd4792d8ad67173191de088cf65e5be0ecee1a1f444b", "held source-plan identity drift")
    need(held["status"] == "external_draft_not_activated" and held["admitted_to_repository"] is False, "held source-plan promoted")
    governance = record["governance"]
    need(all(governance[k] is True for k in [
        "lantern_house_sole_normal_default_tale",
        "drowned_harbor_developer_only",
        "drowned_harbor_normal_catalog_absent",
        "drowned_harbor_central_provider_absent",
        "drowned_harbor_normal_library_absent",
        "drowned_harbor_startup_fallback_absent",
        "drowned_harbor_ordinary_export_excluded",
        "issue_7_naming_gate_preserved",
        "issue_39_human_evidence_gate_preserved",
    ]), "governance boundary drift")
    need(governance["pr_32_incorporated"] is False and governance["automation_is_human_evidence"] is False, "PR/evidence boundary drift")

def validate_schema(schema, record):
    need(set(schema) == {"$schema", "$id", "title", "type", "const"}, "schema key drift")
    need(schema["$schema"] == "https://json-schema.org/draft/2020-12/schema", "schema dialect drift")
    need(schema["type"] == "object", "schema type drift")
    need(schema["const"] == record, "schema is not exact-const closed")

def validate_provenance(provenance):
    need(digest(provenance) == PROVENANCE_SHA, "provenance drift")
    need(provenance["review"]["registered_as_addendum_not_replacement"] is True, "replacement drift")
    need(provenance["review"]["external_schema_fully_closed"] is False, "external schema closure misrepresented")
    need(provenance["review"]["repository_corrected_schema_kind"] == "exact_const_fully_closed", "corrected schema kind drift")
    for key, value in provenance["authority"].items():
        if key in {"dh_ux_001_remains_governing", "clean_room_planning_eligibility_established"}:
            need(value is True, f"required provenance authority lost: {key}")
        else:
            need(value is False, f"forbidden provenance authority: {key}")

def validate_docs():
    text = "\n".join((ROOT / p).read_text(encoding="utf-8") for p in DOCS).lower()
    required = [
        "dh-ux-addendum-reg-001",
        "dh-ux-final-001",
        "bounded addendum",
        "does not replace",
        "accepted_final_external_ux_advisory_as_bounded_dh_ux_001_addendum_with_required_schema_correction",
        "not fully fail-closed",
        "registered_authorities",
        "authorization",
        "no_pixel_reuse",
        "proposed_next_governance",
        "pixel_independent_advisory",
        "clean_room_source_planning_input_gated",
        "implementation_dependent_deferred",
        "human_evidence_dependent",
        "rejected_or_out_of_scope",
        "r1_private_internal_reference",
        "reference_only_nonproduction",
        "conversion readiness remains `not_ready`",
        "implementation authorization remains false",
        "clean-room source planning is not authorized",
        "dh-source-plan-001_clean_room_source_art_and_composition_planning_package_v1.zip",
        "34fb5de40bd1dabfde66cd4792d8ad67173191de088cf65e5be0ecee1a1f444b",
        "lantern house remains the sole normal/default tale",
        "drowned harbor remains developer-only",
        "issue #7",
        "issue #39",
        "pr #32",
    ]
    for phrase in required:
        need(phrase in text, f"missing documentation phrase: {phrase}")
    forbidden = [
        "clean-room source planning is authorized",
        "source creation is authorized",
        "runtime composition is authorized",
        "direct generated-pixel use is authorized",
        "candidate approved",
        "production ready",
        "shipping authorized",
        "accessibility certified",
        "human evidence passed",
        "rights are fully cleared",
    ]
    for phrase in forbidden:
        need(phrase not in text, f"unsupported documentation claim: {phrase}")

def branch_name():
    return os.environ.get("GITHUB_HEAD_REF") or os.environ.get("GITHUB_REF_NAME") or subprocess.check_output(["git", "branch", "--show-current"], text=True).strip()

def validate_git():
    if branch_name() != BRANCH:
        return
    actual = {x for x in subprocess.check_output(["git", "diff", "--name-only", f"{BASE}...HEAD"], text=True).splitlines() if x}
    need(actual == ALLOWED, f"path mismatch missing={sorted(ALLOWED-actual)} unexpected={sorted(actual-ALLOWED)}")
    prohibited_ext = {".png", ".jpg", ".jpeg", ".webp", ".zip", ".psd", ".kra", ".blend", ".aseprite", ".tscn", ".tres"}
    prohibited_prefix = ("game/", "art/source/", "game/assets/", "web/companion/", "services/room-service/")
    for path in actual:
        need(not path.startswith(prohibited_prefix), f"prohibited path: {path}")
        need(Path(path).suffix.lower() not in prohibited_ext, f"prohibited extension: {path}")

def validate(check_git=True):
    record = load(RECORD)
    schema = load(SCHEMA)
    provenance = load(PROVENANCE)
    validate_record(record)
    validate_schema(schema, record)
    validate_provenance(provenance)
    validate_docs()
    if check_git:
        validate_git()

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--skip-git-boundary", action="store_true")
    args = parser.parse_args()
    validate(not args.skip_git_boundary)
    print("Validated Drowned Harbor final UX advisory addendum registration")
    return 0

if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (ValidationError, KeyError, TypeError, IndexError, json.JSONDecodeError, subprocess.CalledProcessError, OSError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1)
