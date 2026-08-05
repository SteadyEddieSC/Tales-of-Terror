#!/usr/bin/env python3
from __future__ import annotations
import argparse, hashlib, json, subprocess, sys
from pathlib import Path
REGISTER=Path("docs/tales/drowned_harbor/visual/drowned_harbor_project_owner_attestation_v1.json")
SCHEMA=Path("docs/tales/drowned_harbor/visual/drowned_harbor_project_owner_attestation_schema_v1.json")
PROVENANCE=Path("art/licenses/drowned_harbor/visual/dh_owner_attest_001_provenance_v1.json")
SOURCE_RIGHTS=Path("docs/tales/drowned_harbor/visual/drowned_harbor_external_visual_rights_and_provenance_register_v1.json")
DOCS=[Path("docs/tales/drowned_harbor/visual/Drowned_Harbor_Completed_Project_Owner_Attestation_v1.md"),Path("docs/tales/drowned_harbor/visual/Drowned_Harbor_Project_Owner_Attestation_Disposition_v1.md"),Path("docs/releases/DH-OWNER-ATTEST-001-project-owner-attestation-registration.md")]
BASE="1f75ec56779d1e99b10105f142f99f1a6f3fbd27"
EXPECTED_PATHS={".github/workflows/drowned-harbor-owner-attestation.yml","docs/releases/DH-OWNER-ATTEST-001-project-owner-attestation-registration.md","docs/tales/drowned_harbor/visual/Drowned_Harbor_Completed_Project_Owner_Attestation_v1.md","docs/tales/drowned_harbor/visual/Drowned_Harbor_Project_Owner_Attestation_Disposition_v1.md","docs/tales/drowned_harbor/visual/drowned_harbor_project_owner_attestation_v1.json","docs/tales/drowned_harbor/visual/drowned_harbor_project_owner_attestation_schema_v1.json","art/licenses/drowned_harbor/visual/dh_owner_attest_001_provenance_v1.json","tools/validate_drowned_harbor_owner_attestation.py","tools/test_validate_drowned_harbor_owner_attestation.py"}
EXPECTED_REGISTER_SHA="e41e603bf3654bac392fee006dad4f979c6f7dcead7b683e4f6f16fd4e7ca520"
EXPECTED_PROVENANCE_SHA="b9183f6b42caf5f6f9eebfb47dab4552fd3898a74e87d524f1f30344a09c5635"
EXPECTED_PAYLOAD_SHA="1c8faec1209a070e5d03fd481a6526af366573a0c9626c6679dd90eef1e15819"
class ValidationError(Exception): pass
def need(v,m):
    if not v: raise ValidationError(m)
def load(p): return json.loads(p.read_text(encoding="utf-8"))
def digest(v): return hashlib.sha256(json.dumps(v,sort_keys=True,separators=(",",":"),ensure_ascii=False).encode()).hexdigest()
def validate_record(d):
    need(digest(d)==EXPECTED_REGISTER_SHA,"registration drift")
    need(digest(d["package"]["payloads"])==EXPECTED_PAYLOAD_SHA,"payload drift")
    need(d["disposition"]["metadata_only_clean_room_planning_eligibility_established"] is True,"eligibility missing")
    for k in ["clean_room_source_planning_authorized","clean_room_source_creation_authorized","direct_generated_pixel_use_authorized","tracing_vectorization_or_paint_over_authorized","source_art_authorized","runtime_art_authorized","godot_authorized","codex_authorized","candidate_creation_or_promotion_authorized","public_distribution_authorized","marketing_storefront_or_merchandise_authorized","legal_clearance_created","accessibility_or_human_evidence_claimed","production_or_shipping_authorized","implementation_authorized","next_release_selected","next_release_activation_authorized"]: need(d["disposition"][k] is False,k)
    need(d["attestation"]["unknown_facts_preserved"] is True and d["attestation"]["no_direct_pixel_reuse_agreed"] is True,"attestation boundary")
    need(d["inventory_summary"]["all_assets"]=="R1_private_internal_reference" and d["inventory_summary"]["reference_only_nonproduction"] is True,"R1 boundary")
def validate_schema(s,d):
    need(s.get("additionalProperties") is False,"schema open")
    need(s.get("required")==list(d.keys()),"schema required drift")
    need(set(s.get("properties",{}))==set(d),"schema properties drift")
    for k,v in d.items(): need(s["properties"][k].get("const")==v,f"schema const drift {k}")
def validate_provenance(p):
    need(digest(p)==EXPECTED_PROVENANCE_SHA,"provenance drift")
    need(p["eligibility_state"]=="metadata_only_clean_room_planning_eligible_but_not_authorized","eligibility promotion")
def validate_source_rights(r):
    need(r["release_id"]=="DH-RIGHTS-REG-001" and r["record_id"]=="DH-RIGHTS-001","source authority")
    need(r["disposition"]["status"]=="partial_resolution_for_private_internal_reference_only","source disposition")
    s=r["inventory_summary"]; need((s["unique_image_binary_count"],s["true_png_count"],s["jpeg_binary_with_png_filename_count"])==(25,21,4),"source inventory")
    need(s["provider_counts"]=={"openai":21,"google_gemini":4},"source providers")
    need(r["accepted_lifecycle"]["all_assets"]=="R1_private_internal_reference","source lifecycle")
def validate_docs():
    t="\n".join(p.read_text(encoding="utf-8") for p in DOCS).lower()
    for x in ["accepted_completed_owner_attestation_sufficient_for_metadata_only_clean_room_planning_eligibility","r1_private_internal_reference","reference_only_nonproduction","conversion_readiness: not_ready","implementation_authorized: false","unknown facts","no successor is selected or activated","issue #7","issue #39","pr #32","lantern house","drowned harbor remains developer-only"]: need(x in t,f"missing doc phrase {x}")
    for x in ["source creation is authorized","clean-room source planning is authorized","direct generated-pixel use is authorized","rights are fully cleared","legal clearance complete","candidate approved","production ready","shipping authorized","human evidence passed","accessibility certified"]: need(x not in t,f"unsupported claim {x}")
def validate_git():
    actual={x for x in subprocess.check_output(["git","diff","--name-only",f"{BASE}...HEAD"],text=True).splitlines() if x}
    need(actual==EXPECTED_PATHS,f"path mismatch missing={sorted(EXPECTED_PATHS-actual)} unexpected={sorted(actual-EXPECTED_PATHS)}")
    for p in actual: need(not p.startswith(("game/","art/source/","game/assets/")) and Path(p).suffix.lower() not in {".png",".jpg",".jpeg",".webp",".zip",".psd",".kra",".blend",".aseprite",".tscn",".tres"},f"prohibited path {p}")
def main():
    ap=argparse.ArgumentParser(); ap.add_argument("--skip-git-boundary",action="store_true"); a=ap.parse_args()
    d=load(REGISTER); validate_record(d); validate_schema(load(SCHEMA),d); validate_provenance(load(PROVENANCE)); validate_source_rights(load(SOURCE_RIGHTS)); validate_docs()
    if not a.skip_git_boundary: validate_git()
    print("Validated DH-OWNER-ATTEST-REG-001 closed metadata registration")
    return 0
if __name__=="__main__":
    try: raise SystemExit(main())
    except (ValidationError,KeyError,TypeError,IndexError,json.JSONDecodeError,subprocess.CalledProcessError) as e: print(f"ERROR: {e}",file=sys.stderr); raise SystemExit(1)
