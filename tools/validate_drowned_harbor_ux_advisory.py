#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import os
import subprocess
from pathlib import Path
from typing import Any

BASE = "1cad8495c913d926c4422557ea59e8c6fa1f6c1a"
BRANCH = "docs/dh-ux-001-advisory-registration"
CONTRACT = Path("docs/tales/drowned_harbor/ux/drowned_harbor_ux_advisory_registration_v1.json")
SCHEMA = Path("docs/tales/drowned_harbor/ux/drowned_harbor_ux_advisory_registration_schema_v1.json")
PROVENANCE = Path("art/licenses/drowned_harbor/ux/dh_ux_001_provenance_v1.json")
DOCS = [
    Path("docs/releases/DH-UX-001-shared-screen-ux-advisory-registration.md"),
    Path("docs/tales/drowned_harbor/ux/Drowned_Harbor_Shared_Screen_UX_Architecture_and_Stage_Flows_v1.md"),
    Path("docs/tales/drowned_harbor/ux/Drowned_Harbor_960x540_Layout_and_Stable_Seat_Advisory_v1.md"),
    Path("docs/tales/drowned_harbor/ux/Drowned_Harbor_UX_Validation_and_Human_Evidence_Plan_v1.md"),
]
ALLOWED = {
    ".github/workflows/drowned-harbor-ux-advisory.yml",
    "docs/releases/DH-UX-001-shared-screen-ux-advisory-registration.md",
    "docs/tales/drowned_harbor/ux/Drowned_Harbor_Shared_Screen_UX_Architecture_and_Stage_Flows_v1.md",
    "docs/tales/drowned_harbor/ux/Drowned_Harbor_960x540_Layout_and_Stable_Seat_Advisory_v1.md",
    "docs/tales/drowned_harbor/ux/Drowned_Harbor_UX_Validation_and_Human_Evidence_Plan_v1.md",
    "docs/tales/drowned_harbor/ux/drowned_harbor_ux_advisory_registration_v1.json",
    "docs/tales/drowned_harbor/ux/drowned_harbor_ux_advisory_registration_schema_v1.json",
    "art/licenses/drowned_harbor/ux/dh_ux_001_provenance_v1.json",
    "tools/validate_drowned_harbor_ux_advisory.py",
    "tools/test_validate_drowned_harbor_ux_advisory.py",
}
DIGESTS = {
    CONTRACT: "afd32e86b7fdafbc2dcc4adfe63ecc80f7cb7a7eb47e43e483383d0d65848328",
    SCHEMA: "c03594c3fab2b9c317229de6ec4524413c5dd09fc0c36575508b4970e180c49c",
    PROVENANCE: "32942b0664cf13425cc0587c01b0f1f7a6f96848fb7edc8a988a955cb143d6e8",
}
STAGES = [
    "low_tide_arrival_v1", "bellhouse_ledger_v1", "lighthouse_council_v1",
    "high_water_v1", "last_light_v1", "ending_resolution_v1",
    "epilogue_attribution_v1", "rematch_title_cleanup_v1",
]

class ValidationError(ValueError):
    pass

def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValidationError(message)

def canonical_digest(value: Any) -> str:
    payload = json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode()
    return hashlib.sha256(payload).hexdigest()

def load(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    require(isinstance(value, dict), f"object required: {path}")
    return value

def validate_contract(d: dict[str, Any]) -> None:
    require(canonical_digest(d) == DIGESTS[CONTRACT], "contract package drift")
    require(d["identity"]["release_id"] == "DH-UX-REG-001", "release identity drift")
    require(d["identity"]["review_disposition"] == "accepted_external_ux_advisory_with_required_corrections", "disposition drift")
    require(d["release"] == {"protected_main_base": BASE, "branch": BRANCH, "planning_only": True, "metadata_only": True}, "release coordinates drift")
    require(all(value is False for value in d["authorization"].values()), "authorization opened")
    require(d["external_package"]["sha256"] == "e3857353dc0257b72866e0e5259b8e3bab2e856126903675f8e73e1f23a02ae3", "package hash drift")
    require(d["external_package"]["manifest"]["sha256"] == "7742a59b402957d63593917a291d807f3fba7fd4bea82937a22730b65d6d469d", "manifest hash drift")
    defect = d["external_schema_review"]
    require(defect["external_contract_validates_against_external_schema"] is False and defect["validation_error_count"] == 1, "external schema defect erased")
    authority = d["authority"]
    require(authority["board_state"] == ["board_geometry", "spaces", "connectors", "pawn_positions", "tide_mutations", "route_reachability"], "BoardState authority drift")
    require(authority["new_runtime_fields_authorized"] is False and authority["new_legal_actions_authorized"] is False, "new runtime authority created")
    envelope = d["logical_review_envelope"]
    require(envelope["logical_canvas"] == {"x": 0, "y": 0, "width": 960, "height": 540}, "logical canvas drift")
    require(envelope["caption_reserve_intentionally_overlays_board_action"] is True, "caption overlap drift")
    seats = d["stable_seat_hypotheses"]
    require(seats["supported_seats"] == {"minimum": 1, "maximum": 8}, "seat range drift")
    require(seats["compact"]["eight_seat_tile_width_px"] == 104 and seats["classification"] == "feasibility_hypothesis_not_final_component_spec", "seat hypothesis promoted")
    require([row["stage_id"] for row in d["stage_flows"]] == STAGES, "stage order drift")
    require(d["privacy"]["shared_screen_may_show_private_content"] is False, "private content admitted")
    require(d["privacy"]["private_review_request_is_new_legal_action"] is False, "private review authority created")
    require(d["microcopy"]["status"] == "advisory_placeholder_not_final_localization", "microcopy promoted")
    require(d["next_release"] == {"selected": False, "release_id": None, "issue": None, "implementation_release": False}, "successor selected")
    require(d["lifecycle"]["conversion_readiness"] == "not_ready" and d["lifecycle"]["implementation_authorized"] is False, "conversion/implementation promoted")
    require(all(d["governance"].values()) and all(value is False for value in d["evidence_claims"].values()), "governance/evidence drift")

def validate_schema(s: dict[str, Any], c: dict[str, Any]) -> None:
    require(canonical_digest(s) == DIGESTS[SCHEMA], "schema package drift")
    require(s["additionalProperties"] is False and s["required"] == list(c.keys()), "schema opened")
    require(set(s["properties"]) == set(c), "schema inventory drift")
    for key in ["record_kind", "record_version", "title", "identity", "release", "lifecycle"]:
        require(s["properties"][key]["const"] == c[key], f"schema closure drift: {key}")

def validate_provenance(p: dict[str, Any], c: dict[str, Any]) -> None:
    require(canonical_digest(p) == DIGESTS[PROVENANCE], "provenance package drift")
    for key in ["external_package", "external_schema_review", "source_authorities", "reference_inputs"]:
        require(p[key] == c[key], f"provenance mismatch: {key}")
    generation = p["generation_and_authorship"]
    require(all(generation[key] is None for key in ["exact_model_variant", "exact_prompt", "exact_generation_timestamp", "human_edits_after_generation", "content_credentials_status", "watermark_status"]), "generation facts fabricated")
    rights = p["rights"]
    require(rights["public_distribution_authorized"] is False and rights["binary_repository_paths"] == [], "rights/storage boundary opened")
    require(all(value is False for value in p["hard_boundaries"].values()), "provenance authorization opened")

def validate_docs() -> None:
    text = "\n".join(path.read_text(encoding="utf-8") for path in DOCS).lower()
    for token in [
        "dh-ux-reg-001", "dh-ux-001", "accepted_external_ux_advisory_with_required_corrections",
        "boardstate", "rulessession", "rolesession", "session coordinator", "960×540",
        "104", "135%", "caption reserve", "external/private", "not_ready",
        "rights and provenance", "issue #7", "issue #39", "pr #32", "lantern house",
        "developer-only", "placeholder", "automation is not human evidence",
    ]:
        require(token in text, f"missing documentation token: {token}")
    for claim in [
        "television readability validated", "accessibility certified", "production ready",
        "shipping authorized", "candidate approved", "implementation authorized: true",
    ]:
        require(claim not in text, f"unsupported documentation claim: {claim}")

def validate_git_boundary(skip: bool = False) -> None:
    if skip:
        return
    branch = os.environ.get("GITHUB_HEAD_REF") or os.environ.get("GITHUB_REF_NAME") or subprocess.check_output(["git", "branch", "--show-current"], text=True).strip()
    require(branch == BRANCH, f"wrong branch: {branch}")
    base_ref = os.environ.get("GITHUB_BASE_REF", "main")
    subprocess.run(["git", "fetch", "origin", base_ref, "--depth=1"], check=True, stdout=subprocess.DEVNULL)
    require(subprocess.check_output(["git", "rev-parse", f"origin/{base_ref}"], text=True).strip() == BASE, "protected main changed")
    actual = {line for line in subprocess.check_output(["git", "diff", "--name-only", f"{BASE}...HEAD"], text=True).splitlines() if line}
    require(actual == ALLOWED, f"exact path mismatch missing={sorted(ALLOWED-actual)} unexpected={sorted(actual-ALLOWED)}")
    for path in actual:
        require(not path.startswith(("art/source/", "game/assets/", "game/src/", "game/data/")), f"prohibited source/runtime path: {path}")
        require(Path(path).suffix.lower() not in {".png", ".webp", ".svg", ".glb", ".zip", ".kra", ".psd", ".blend", ".aseprite", ".xcf", ".tscn", ".tres"}, f"prohibited binary/runtime extension: {path}")

def validate_all(skip_git: bool = False) -> None:
    contract = load(CONTRACT)
    validate_contract(contract)
    validate_schema(load(SCHEMA), contract)
    validate_provenance(load(PROVENANCE), contract)
    validate_docs()
    validate_git_boundary(skip_git)

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--skip-git-boundary", action="store_true")
    args = parser.parse_args()
    try:
        validate_all(args.skip_git_boundary)
    except (ValidationError, KeyError, TypeError, ValueError, OSError, json.JSONDecodeError, subprocess.CalledProcessError) as exc:
        print(f"DH-UX-REG-001 validation failed: {exc}")
        return 1
    print("Validated DH-UX-REG-001 exact metadata package")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
