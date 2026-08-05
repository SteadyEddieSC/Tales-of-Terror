#!/usr/bin/env python3
from __future__ import annotations
import argparse, json, subprocess, sys
from pathlib import Path

REGISTER=Path("docs/tales/drowned_harbor/visual/drowned_harbor_external_visual_rights_and_provenance_register_v1.json")
SCHEMA=Path("docs/tales/drowned_harbor/visual/drowned_harbor_external_visual_rights_and_provenance_register_schema_v1.json")
PROVENANCE=Path("art/licenses/drowned_harbor/visual/dh_rights_001_provenance_v1.json")
BASE="3aa7d3b8dd32ef50738098780c15a27890961e50"
BRANCH="docs/dh-rights-001-metadata-registration"
EXPECTED_PATHS={
".github/workflows/drowned-harbor-rights-provenance.yml",
"docs/releases/DH-RIGHTS-001-rights-provenance-registration.md",
"docs/tales/drowned_harbor/visual/Drowned_Harbor_External_Visual_Rights_and_Provenance_Disposition_v1.md",
"docs/tales/drowned_harbor/visual/drowned_harbor_external_visual_rights_and_provenance_register_v1.json",
"docs/tales/drowned_harbor/visual/drowned_harbor_external_visual_rights_and_provenance_register_schema_v1.json",
"docs/tales/drowned_harbor/visual/Drowned_Harbor_External_Visual_Provenance_Gap_Matrix_v1.md",
"docs/tales/drowned_harbor/visual/Drowned_Harbor_External_Visual_Rights_Disposition_Matrix_v1.md",
"docs/tales/drowned_harbor/visual/Drowned_Harbor_Project_Owner_Rights_Attestation_Template_v1.md",
"art/licenses/drowned_harbor/visual/dh_rights_001_provenance_v1.json",
"tools/validate_drowned_harbor_rights_provenance.py",
"tools/test_validate_drowned_harbor_rights_provenance.py",
}
EXPECTED_IDS=['EXT-VIS-001', 'EXT-VIS-002', 'EXT-VIS-003', 'EXT-VIS-004', 'EXT-VIS-005', 'EXT-VIS-006', 'EXT-VIS-007', 'EXT-VIS-008', 'EXT-VIS-009', 'EXT-VIS-010', 'EXT-VIS-011', 'EXT-VIS-012', 'EXT-VIS-013', 'EXT-VIS-014', 'EXT-VIS-015', 'EXT-VIS-016', 'EXT-VIS-017', 'EXT-VIS-018', 'EXT-VIS-019', 'EXT-VIS-020', 'EXT-VIS-021', 'EXT-VIS-022', 'EXT-VIS-023', 'EXT-VIS-024', 'EXT-VIS-025']
EXPECTED_SHAS={'EXT-VIS-001': '25a6fb006f223461d09144037818678aa6558c35ec7eb576ea4d7d24ed9ec6ef', 'EXT-VIS-002': '7e9bcce999ffc68a34b13f56489cd875fd626f14d60be5ffe06e694cc7d340c1', 'EXT-VIS-003': '04416d770cc5197afd19ea4c72fcc901324ffa7948aa525c936405d5d2ef94a8', 'EXT-VIS-004': '31c8dd42a5f0f0746540a54c7cf5188d115225b4c84bd3406f810253c5fae737', 'EXT-VIS-005': 'f37cea3322b2730d68c09107c78f433daf6a37465b72f2794a8db018df444569', 'EXT-VIS-006': 'f71f4b308183fda120998d3e3f54d40745ca2eb4e62aef354a61eebbf6e7216a', 'EXT-VIS-007': '04b47454734fce5ab9a58ef6b8cada9b0a956b1dd57af61eb2402a1e0f3868d5', 'EXT-VIS-008': '510962c1939bc425a38ed0b54133c9b56e521831741638de4aadebb2a01179e9', 'EXT-VIS-009': '1ac0dfa90b54eaebe60e1cc9326dd9232141f87c740cdab8dbda7498c62ff87b', 'EXT-VIS-010': '912792d5f9f6705fb3418e590ea5eca2bfe709368f3a3c8a205e5a0bcf68fab8', 'EXT-VIS-011': '51e2a1774529500385260d1800aacd1f3265024db6cc0b93c0e76ee8a363cc07', 'EXT-VIS-012': '904aa44dfa2b6980d88d0776213d28d3e1fa3b2b8acba7798fdbed84e526e00e', 'EXT-VIS-013': 'dc8cd6ee426c486043a688bcf3a89025597e2c96b2b66e4064392b9bd9f901b2', 'EXT-VIS-014': 'c54e0cdb412daab719819c803c1ea4d6817cbcf9f506b35aea82fd9646d9687a', 'EXT-VIS-015': '12cf4422ba189c038844d139d828f1f92fe8fd8209649c1d8197ecdbae052a60', 'EXT-VIS-016': '9f343570adb0e51f6d7215bd73434f25fb2af1e502641f15c0ef4de50ccfc587', 'EXT-VIS-017': '30aeb03f169506a3889635219b4e3afbe03720d8c3e1405d1d1424c1e5425a88', 'EXT-VIS-018': '30a54b35c4b6176159bab260cc8b17af98985d879d3d33863c8d8ef287512975', 'EXT-VIS-019': '67176e1c4e093e21e4febab1a8cb8871936605662fbd7428e506243e58d33bdb', 'EXT-VIS-020': '78ba2f5b050635b65df2e2b26fe7237238fdc19da4ded2fafdcda384f6d76818', 'EXT-VIS-021': '0fbc0caf6ca2c2439d855cd81276f5e2b8ed918a0b37234f106be3f792913738', 'EXT-VIS-022': 'cb263c5501768d4c6bbafcfc0a5fcd1403abc2be0cb4322a22b0390f17ba8d09', 'EXT-VIS-023': '7a878e31215c95238f97bbb21046e427a6aef2c009b71b165a7c067964edffea', 'EXT-VIS-024': '6d674820f1430b7255a6dd29d55ab3dd43ecd1f150b7c76c22660aa2c6ac65cf', 'EXT-VIS-025': '2662185f4254257002251cc95c489e7bc05a8ecf2c79001f014d6fb55822b2f7'}
C2PA_IDS=['EXT-VIS-004', 'EXT-VIS-006', 'EXT-VIS-007', 'EXT-VIS-008', 'EXT-VIS-009', 'EXT-VIS-010', 'EXT-VIS-011', 'EXT-VIS-012', 'EXT-VIS-013', 'EXT-VIS-014', 'EXT-VIS-015', 'EXT-VIS-016', 'EXT-VIS-017', 'EXT-VIS-019', 'EXT-VIS-023', 'EXT-VIS-024']
JPEG_IDS=['EXT-VIS-020', 'EXT-VIS-021', 'EXT-VIS-022', 'EXT-VIS-025']
OPENAI_ATTR_ONLY=['EXT-VIS-001', 'EXT-VIS-002', 'EXT-VIS-003', 'EXT-VIS-005', 'EXT-VIS-020']
GEMINI_IDS=['EXT-VIS-018', 'EXT-VIS-021', 'EXT-VIS-022', 'EXT-VIS-025']
EXPECTED_ASSET_INVENTORY_SHA256="cb4d802c7d625c1f8c674ce3b8aff0a992fa48aca31398e2922a5087c0bbddca"
class ValidationError(Exception): pass
def need(cond,msg):
    if not cond: raise ValidationError(msg)
def load(path): return json.loads(path.read_text(encoding="utf-8"))
def validate(data):
    need(data["schema_version"]==1,"schema")
    need(data["release_id"]=="DH-RIGHTS-REG-001" and data["record_id"]=="DH-RIGHTS-001","identity")
    need(data["protected_main_starting_sha"]==BASE,"base")
    p=data["package"]; need(p["bytes"]==61194347 and p["sha256"]=="ce79e9413fd93405f01691eeefbe7e17dfdc103d40be076a73a3b218f7b26dcb","archive")
    need(p["manifest_bytes"]==9038 and p["manifest_sha256"]=="386e325e46a5f8b0ba3ba15893af5fe33c70f95f397f05c939b2058f2573968d","manifest")
    need(p["manifested_payload_count_excluding_manifest"]==37,"payload count")
    need(not p["missing_payloads"] and not p["extra_payloads"] and not p["payload_hash_or_byte_mismatches"],"payload mismatch")
    d=data["disposition"]
    need(d["status"]=="partial_resolution_for_private_internal_reference_only","status")
    need(d["conversion_readiness"]=="not_ready" and d["implementation_authorized"] is False,"readiness")
    need(d["rights_and_provenance_prerequisite_complete"] is False,"prerequisite")
    for k in ["direct_generated_pixel_use_authorized","source_art_authorized","runtime_art_authorized","godot_authorized","codex_authorized","candidate_creation_or_promotion_authorized","public_repository_or_release_assets_authorized","marketing_storefront_or_merchandise_authorized","human_evidence_claimed","accessibility_or_readability_claimed","production_or_shipping_authorized"]:
        need(d[k] is False,k)
    s=data["inventory_summary"]
    need(s["unique_image_binary_count"]==25 and s["true_png_count"]==21 and s["jpeg_binary_with_png_filename_count"]==4,"formats")
    need(s["jpeg_binary_with_png_filename_asset_keys"]==JPEG_IDS,"jpeg ids")
    need(s["provider_counts"]=={"openai":21,"google_gemini":4} and s["unknown_provider_count"]==0,"providers")
    need(s["locally_detected_openai_c2pa_reference_count_not_authenticated"]==16 and s["locally_detected_openai_c2pa_reference_asset_keys"]==C2PA_IDS,"c2pa")
    need(s["openai_source_attribution_only_asset_keys"]==OPENAI_ATTR_ONLY and s["gemini_source_attribution_asset_keys"]==GEMINI_IDS,"attribution")
    need(s["duplicate_sha256_group_count"]==0,"dedup")
    assets=data["assets"]
    canonical=json.dumps(assets,sort_keys=True,separators=(",",":"),ensure_ascii=False).encode("utf-8")
    need(__import__("hashlib").sha256(canonical).hexdigest()==EXPECTED_ASSET_INVENTORY_SHA256,"asset inventory")
    need(data["external_binary_policy"]=={"images_in_git":False,"archive_in_git":False,"public_github_release_assets":False,"binary_storage_location":"external_private_only"},"binary policy")
    g=data["governance"]; need(g["naming_gate_issue"]==7 and g["human_evidence_gate_issue"]==39 and g["unrelated_pull_request_excluded"]==32,"gates")
    need(g["lantern_house_remains_sole_normal_default_tale"] and g["drowned_harbor_remains_developer_only_and_ordinary_export_excluded"],"production boundary")
    need("project_owner_rights_and_provenance_attestation" in data["remaining_prerequisites"],"attestation prerequisite")
    return True
def validate_schema_shape(schema):
    need(schema.get("additionalProperties") is False,"schema open")
    need(schema["properties"]["assets"]["items"].get("additionalProperties") is False,"asset schema open")
def validate_provenance(p):
    need(p["release_id"]=="DH-RIGHTS-REG-001" and p["record_id"]=="DH-RIGHTS-001","provenance identity")
    need(p["prerequisite_state"]=="partial_resolution_owner_attestation_required" and p["owner_attestation_required"] is True,"provenance prerequisite")
    need(p["binary_admission"]=={"archive_committed":False,"images_committed":False,"public_release_assets_authorized":False},"binary admission")
def validate_git_boundary():
    out=subprocess.check_output(["git","diff","--name-only",f"{BASE}...HEAD"],text=True)
    actual={x for x in out.splitlines() if x}
    need(actual==EXPECTED_PATHS,f"path mismatch missing={sorted(EXPECTED_PATHS-actual)} unexpected={sorted(actual-EXPECTED_PATHS)}")
def main():
    ap=argparse.ArgumentParser(); ap.add_argument("--skip-git-boundary",action="store_true"); args=ap.parse_args()
    validate(load(REGISTER)); validate_schema_shape(load(SCHEMA)); validate_provenance(load(PROVENANCE))
    if not args.skip_git_boundary: validate_git_boundary()
    print("Validated DH-RIGHTS-REG-001 closed metadata registration")
    return 0
if __name__=="__main__":
    try: raise SystemExit(main())
    except ValidationError as e: print(f"ERROR: {e}",file=sys.stderr); raise SystemExit(1)
