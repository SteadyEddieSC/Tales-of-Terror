#!/usr/bin/env python3
from __future__ import annotations

import copy
import importlib.util
import json
import shutil
import tempfile
from pathlib import Path
from typing import Callable

ROOT = Path(".")
spec = importlib.util.spec_from_file_location("validator", ROOT / "tools/validate_drowned_harbor_ux_advisory.py")
validator = importlib.util.module_from_spec(spec)
assert spec.loader
spec.loader.exec_module(validator)

CONTRACT = json.loads((ROOT / validator.CONTRACT).read_text(encoding="utf-8"))
Mutation = Callable[[dict], None]

def expect_rejected(name: str, mutation: Mutation) -> None:
    candidate = copy.deepcopy(CONTRACT)
    mutation(candidate)
    try:
        validator.validate_contract(candidate)
    except (validator.ValidationError, KeyError, TypeError, IndexError):
        return
    raise AssertionError(f"mutation survived: {name}")

def main() -> int:
    cases: list[tuple[str, Mutation]] = [
        ("release identity drift", lambda d: d["identity"].__setitem__("release_id", "DH-UX-REG-002")),
        ("advisory identity drift", lambda d: d["identity"].__setitem__("external_advisory_id", "DH-UX-002")),
        ("issue drift", lambda d: d["identity"].__setitem__("governing_issue", 121)),
        ("disposition promoted", lambda d: d["identity"].__setitem__("review_disposition", "approved")),
        ("base drift", lambda d: d["release"].__setitem__("protected_main_base", "0" * 40)),
        ("branch drift", lambda d: d["release"].__setitem__("branch", "feature/ux")),
        ("implementation authorized", lambda d: d["authorization"].__setitem__("implementation_authorized", True)),
        ("Codex authorized", lambda d: d["authorization"].__setitem__("codex_authorized", True)),
        ("Godot authorized", lambda d: d["authorization"].__setitem__("godot_work_authorized", True)),
        ("candidate authorized", lambda d: d["authorization"].__setitem__("candidate_creation_authorized", True)),
        ("successor issue authorized", lambda d: d["authorization"].__setitem__("successor_implementation_issue_authorized", True)),
        ("PR32 incorporated", lambda d: d["authorization"].__setitem__("pr_32_incorporated", True)),
        ("package hash drift", lambda d: d["external_package"].__setitem__("sha256", "0" * 64)),
        ("package admitted", lambda d: d["external_package"].__setitem__("repository_disposition", "repository")),
        ("manifest count drift", lambda d: d["external_package"]["manifest"].__setitem__("file_count_excluding_manifest", 24)),
        ("CRC unverified", lambda d: d["external_package"].__setitem__("zip_crc_verified", False)),
        ("external schema falsely valid", lambda d: d["external_schema_review"].__setitem__("external_contract_validates_against_external_schema", True)),
        ("external schema defect erased", lambda d: d["external_schema_review"].__setitem__("validation_error_count", 0)),
        ("repository schema not corrected", lambda d: d["external_schema_review"].__setitem__("repository_registration_uses_corrected_closed_schema", False)),
        ("source authority drift", lambda d: d["source_authorities"][0].__setitem__("blob_sha", "0" * 40)),
        ("reference promoted", lambda d: d["reference_inputs"][0].__setitem__("approved", True)),
        ("candidate id assigned", lambda d: d["reference_inputs"][0].__setitem__("candidate_id", "DH-CAND-999")),
        ("unregistered reference registered", lambda d: d["reference_inputs"][0].__setitem__("repository_status", "registered")),
        ("BoardState route reachability removed", lambda d: d["authority"]["board_state"].remove("route_reachability")),
        ("RulesSession owns routes", lambda d: d["authority"]["rules_session"].append("route_reachability")),
        ("new legal actions", lambda d: d["authority"].__setitem__("new_legal_actions_authorized", True)),
        ("presentation owns RNG", lambda d: d["authority"]["presentation"].append("rng")),
        ("canvas drift", lambda d: d["logical_review_envelope"]["logical_canvas"].__setitem__("width", 1920)),
        ("coordinates made final", lambda d: d["logical_review_envelope"].__setitem__("classification", "runtime_spec")),
        ("caption overlap removed", lambda d: d["logical_review_envelope"].__setitem__("caption_reserve_intentionally_overlays_board_action", False)),
        ("safe frame claimed", lambda d: d["logical_review_envelope"].__setitem__("safe_frame_validated", True)),
        ("seat cap introduced", lambda d: d["stable_seat_hypotheses"]["supported_seats"].__setitem__("maximum", 4)),
        ("eight-seat tile final", lambda d: d["stable_seat_hypotheses"].__setitem__("classification", "approved_component_spec")),
        ("density claimed", lambda d: d["stable_seat_hypotheses"].__setitem__("eight_seat_density_validated", True)),
        ("first-focus commit", lambda d: d["interaction_model"].__setitem__("first_focus_may_commit_irreversible_action", True)),
        ("preview mutation", lambda d: d["interaction_model"].__setitem__("preview_mutates_authority", True)),
        ("stage order drift", lambda d: d["stage_flows"].reverse()),
        ("High Water confirmation drift", lambda d: d["stage_flows"][3].__setitem__("confirmation", "confirmed_commitment")),
        ("private shared output", lambda d: d["privacy"].__setitem__("shared_screen_may_show_private_content", True)),
        ("private transcript leak", lambda d: d["privacy"].__setitem__("public_transcript_excludes_private_content", False)),
        ("private surface selected", lambda d: d["privacy"].__setitem__("private_surface_technology_selected", True)),
        ("private review new action", lambda d: d["privacy"].__setitem__("private_review_request_is_new_legal_action", True)),
        ("takeover authority opened", lambda d: d["privacy"].__setitem__("takeover_request_requires_existing_authorized_intent", False)),
        ("microcopy final", lambda d: d["microcopy"].__setitem__("status", "final_localization")),
        ("illegal prompts", lambda d: d["microcopy"].__setitem__("prompts_conditioned_on_current_legal_actions", False)),
        ("Godot automation authorized", lambda d: d["validation_plan"].__setitem__("godot_automation_authorized", True)),
        ("human evidence claimed", lambda d: d["validation_plan"].__setitem__("human_validation_claimed", True)),
        ("blocker bypassed", lambda d: d.__setitem__("next_blocking_prerequisite", "implementation")),
        ("successor selected", lambda d: d["next_release"].update({"selected": True, "release_id": "beta", "issue": 121})),
        ("conversion ready", lambda d: d["lifecycle"].__setitem__("conversion_readiness", "ready")),
        ("production candidate", lambda d: d["lifecycle"].__setitem__("production_candidate", True)),
        ("issue 39 gate removed", lambda d: d["governance"].__setitem__("issue_39_human_physical_evidence_gate", False)),
        ("binary path opened", lambda d: d["prohibited_path_prefixes"].remove("game/assets/")),
        ("evidence claim", lambda d: d["evidence_claims"].__setitem__("television_readability", True)),
    ]
    for name, mutation in cases:
        expect_rejected(name, mutation)

    with tempfile.TemporaryDirectory() as temp_dir:
        temp = Path(temp_dir)
        for path in validator.DOCS:
            target = temp / path
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT / path, target)
        old = validator.DOCS
        try:
            validator.DOCS = [temp / p for p in old]
            validator.validate_docs()
            release = temp / old[0]
            release.write_text(release.read_text(encoding="utf-8") + "\nTelevision readability validated.\n", encoding="utf-8")
            try:
                validator.validate_docs()
            except validator.ValidationError:
                pass
            else:
                raise AssertionError("unsupported human evidence claim survived")
        finally:
            validator.DOCS = old

    print(f"Validated {len(cases) + 1} fail-closed DH-UX-REG-001 mutations")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
