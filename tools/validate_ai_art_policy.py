#!/usr/bin/env python3
from __future__ import annotations

import copy
import json
import os
import re
import subprocess
import sys
from pathlib import Path
from typing import Any

ROOT = Path(".")
BASE = "073e1a65c47f7ec39463fa5a04ed3b4d0e2e73c7"
BRANCH = "docs/ai-art-existing-assets-review"

POLICY = Path("art/ai/ai_art_policy_v1.json")
PROVIDERS = Path("art/ai/approved_generators_v1.json")
SCHEMA = Path("art/ai/ai_art_provenance_schema_v1.json")
LEDGER = Path("art/ai/ai_art_provenance_ledger_v1.json")
WORKFLOW = Path(".github/workflows/ai-art-policy.yml")
DOCS = [
    Path("docs/decisions/ADR-0025-ai-only-production-art-policy.md"),
    Path("docs/releases/AI-ART-POLICY-001-ai-only-production-art-and-provenance.md"),
    Path("docs/technical/AI_Art_Production_and_Provenance_Policy_v1.md"),
    Path("docs/technical/AI_Art_Similarity_and_Promotion_Checklist_v1.md"),
    Path("docs/technical/Steam_PreGenerated_AI_Disclosure_Draft_v1.md"),
    Path("docs/tales/drowned_harbor/visual/Drowned_Harbor_AI_Only_Art_Provenance_Amendment_v1.md"),
]
ALLOWED = {
    ".github/workflows/ai-art-policy.yml",
    "docs/decisions/ADR-0025-ai-only-production-art-policy.md",
    "docs/releases/AI-ART-POLICY-001-ai-only-production-art-and-provenance.md",
    "docs/technical/AI_Art_Production_and_Provenance_Policy_v1.md",
    "docs/technical/AI_Art_Similarity_and_Promotion_Checklist_v1.md",
    "docs/tales/drowned_harbor/visual/Drowned_Harbor_AI_Only_Art_Provenance_Amendment_v1.md",
    "art/ai/ai_art_policy_v1.json",
    "art/ai/ai_art_provenance_schema_v1.json",
    "art/ai/ai_art_provenance_ledger_v1.json",
    "tools/validate_ai_art_policy.py",
    "tools/test_validate_ai_art_policy.py",
}
SHA256 = re.compile(r"^[0-9a-f]{64}$")
ASSET_ID = re.compile(r"^EXT-VIS-(\d{3})$")
DISPOSITIONS = {
    "eligible_direct_source_after_edit",
    "eligible_production_input_after_edit",
    "eligible_model_input_after_review",
    "retain_reference_only",
    "reject",
}
PERMITTED_USES = {
    "direct_source_candidate",
    "edited_source_candidate",
    "image_to_image_input",
    "mask_or_control_input",
    "texture_or_fragment_extraction",
    "runtime_candidate",
    "marketing_candidate",
    "storefront_candidate",
    "reference_only",
}


class ValidationError(Exception):
    pass


def need(value: bool, message: str) -> None:
    if not value:
        raise ValidationError(message)


def load(path: Path) -> Any:
    return json.loads((ROOT / path).read_text(encoding="utf-8"))


def exact_keys(value: dict[str, Any], expected: set[str], label: str) -> None:
    need(set(value) == expected, f"{label} fields drift: {sorted(set(value) ^ expected)}")


def audit_closed_schema(value: Any, path: str = "$") -> int:
    count = 0
    if isinstance(value, dict):
        if value.get("type") == "object":
            count += 1
            need(value.get("additionalProperties") is False, f"{path}: object schema is not closed")
            properties = value.get("properties")
            required = value.get("required")
            need(isinstance(properties, dict), f"{path}: properties missing")
            need(isinstance(required, list), f"{path}: required missing")
            need(set(required) == set(properties), f"{path}: required/properties mismatch")
        for key, child in value.items():
            count += audit_closed_schema(child, f"{path}.{key}")
    elif isinstance(value, list):
        for index, child in enumerate(value):
            count += audit_closed_schema(child, f"{path}[{index}]")
    return count


def validate_policy(policy: dict[str, Any]) -> None:
    exact_keys(
        policy,
        {
            "record_kind",
            "record_version",
            "release",
            "decision",
            "supersession",
            "existing_drowned_harbor_review",
            "registries",
            "promotion_stages",
            "required_reviews",
            "stop_conditions",
            "authoritative_documents",
        },
        "policy",
    )
    need(policy["record_kind"] == "terror_turn_ai_art_policy", "policy kind drift")
    need(policy["record_version"] == 1, "policy version drift")
    release = policy["release"]
    need(release["release_id"] == "AI-ART-POLICY-001", "release ID drift")
    need(release["protected_main"] == BASE, "protected-main drift")
    need(release["policy_date"] == "2026-08-06", "policy date drift")
    need(release["state"] == "policy_and_existing_asset_review_no_promotions", "release state drift")

    decision = policy["decision"]
    need(decision["human_drawn_or_painted_source_required"] is False, "human-drawn requirement returned")
    need(decision["existing_drowned_harbor_images_eligible_for_controlled_use_review"] is True, "existing image eligibility removed")
    need(decision["existing_images_automatically_approved"] is False, "automatic approval enabled")
    need(decision["unknown_historical_prompt_model_seed_or_timestamp_is_automatic_rejection"] is False, "unknown historical metadata became automatic rejection")
    need(decision["approved_uses_may_include_direct_source_editing_image_to_image_masks_controls_extraction_runtime_and_marketing"] is True, "controlled-use eligibility narrowed")
    for key in (
        "generation_authorized_by_this_release",
        "binary_import_authorized_by_this_release",
        "runtime_integration_authorized_by_this_release",
        "ordinary_export_authorized_by_this_release",
        "marketing_authorized_by_this_release",
        "storefront_publication_authorized_by_this_release",
        "live_generation_authorized",
        "copyrightability_of_machine_determined_pixels_assumed",
    ):
        need(decision[key] is False, f"forbidden authority or claim enabled: {key}")
    need(decision["steam_ai_classification"] == "pre_generated_ai_content", "Steam classification drift")

    supersession = policy["supersession"]
    need(supersession["historical_authority"] == "DH-SOURCE-PLAN-001", "historical authority drift")
    need(supersession["historical_record_unchanged"] is True, "historical record rewritten")
    need(supersession.get("dependent_historical_authorities") == ["DH-AI-SOURCE-001"], "dependent advisory supersession drift")
    superseded = set(supersession["superseded_future_requirements"])
    for value in {
        "all_25_existing_drowned_harbor_images_permanently_reference_only",
        "tracing_vectorization_paint_over_compositing_cropping_upscaling_recoloring_retouching_extraction_and_model_input_permanently_prohibited",
        "dh_ai_source_001_restricted_external_images_upload_prohibition_for_registered_25_assets",
    }:
        need(value in superseded, f"required supersession missing: {value}")
    preserved = set(supersession["preserved_requirements"])
    for value in {
        "preserve_original_external_binary_and_registered_sha256",
        "keep_exact_known_and_unknown_provenance",
        "independent_human_visual_rights_similarity_and_quality_review",
        "record_every_transformation_model_input_extraction_export_and_hash",
        "no_automatic_asset_promotion",
        "no_current_generation_binary_import_runtime_export_marketing_or_publication_authority",
        "automation_is_not_human_evidence",
    }:
        need(value in preserved, f"preserved control missing: {value}")

    review = policy["existing_drowned_harbor_review"]
    need(review["inventory_count"] == 25, "inventory count drift")
    need(review["owner_attestation"] == "DH-OWNER-ATTEST-001", "owner attestation drift")
    need(review["current_promotion_count"] == 0, "existing image was promoted")
    counts = review["disposition_counts"]
    need(sum(counts.values()) == 25, "review disposition counts do not total 25")
    need(counts == {
        "eligible_direct_source_after_edit": 1,
        "eligible_production_input_after_edit": 16,
        "eligible_model_input_after_review": 8,
        "retain_reference_only": 0,
        "reject": 0,
    }, "review disposition counts drift")
    need(review["full_resolution_human_review_still_required_before_exact_use"] is True, "full-resolution review requirement removed")

    need(len(policy["promotion_stages"]) == 9 and len(set(policy["promotion_stages"])) == 9, "promotion stages drift")
    need(policy["promotion_stages"][0] == "policy_and_existing_asset_review_no_promotions", "promotion start drift")
    need(policy["promotion_stages"][-1] == "retired_or_rejected", "promotion end drift")
    need(len(policy["required_reviews"]) == 11, "required review count drift")
    need(len(policy["stop_conditions"]) == 14, "stop condition count drift")


def validate_providers(providers: dict[str, Any]) -> None:
    need(providers["record_kind"] == "terror_turn_approved_ai_generators", "provider registry kind drift")
    need(providers["record_version"] == 1, "provider registry version drift")
    need(len(providers["providers"]) == 2, "provider count drift")
    ids = {entry["provider_id"] for entry in providers["providers"]}
    need(ids == {"openai_chatgpt_image_generation", "google_gemini_apps_image_generation"}, "provider IDs drift")


def validate_schema(schema: dict[str, Any]) -> None:
    need(schema.get("$schema") == "https://json-schema.org/draft/2020-12/schema", "schema draft drift")
    need(audit_closed_schema(schema) >= 6, "closed schema coverage too small")
    asset = schema["$defs"]["asset"]
    need(asset["additionalProperties"] is False, "asset schema is open")
    need(set(asset["properties"]) == set(asset["required"]), "asset schema required fields drift")
    need(asset["properties"]["preliminary_disposition"]["enum"] == [
        "eligible_direct_source_after_edit",
        "eligible_production_input_after_edit",
        "eligible_model_input_after_review",
        "retain_reference_only",
        "reject",
    ], "disposition enum drift")


def validate_ledger(ledger: dict[str, Any]) -> None:
    exact_keys(
        ledger,
        {
            "record_kind",
            "record_version",
            "policy_release",
            "state",
            "inventory_source",
            "review_date",
            "reviewer",
            "review_method",
            "summary",
            "common_controls",
            "assets",
        },
        "ledger",
    )
    need(ledger["record_kind"] == "terror_turn_ai_art_provenance_ledger", "ledger kind drift")
    need(ledger["record_version"] == 1, "ledger version drift")
    need(ledger["state"] == "existing_asset_review_complete_no_promotions", "ledger state drift")
    need(ledger["review_date"] == "2026-08-06", "review date drift")
    method = ledger["review_method"]
    need(method["full_resolution_binary_review_complete"] is False, "review overclaims full-resolution completion")
    need(method["limitations"], "review limitations missing")

    assets = ledger["assets"]
    need(len(assets) == 25, "ledger must contain exactly 25 reviewed assets")
    ids = []
    filenames = set()
    hashes = set()
    disposition_counts = {key: 0 for key in DISPOSITIONS}
    for index, asset in enumerate(assets, 1):
        source_id = asset["source_inventory_id"]
        match = ASSET_ID.fullmatch(source_id)
        need(match is not None, f"invalid source inventory ID: {source_id}")
        need(int(match.group(1)) == index, f"asset ordering drift at {source_id}")
        need(asset["asset_id"] == source_id.lower().replace("-", "_"), f"normalized asset ID drift: {source_id}")
        need(SHA256.fullmatch(asset["sha256"]) is not None, f"invalid SHA-256: {source_id}")
        need(asset["filename"] not in filenames, f"duplicate filename: {asset['filename']}")
        need(asset["sha256"] not in hashes, f"duplicate SHA-256: {source_id}")
        filenames.add(asset["filename"])
        hashes.add(asset["sha256"])
        ids.append(source_id)
        need(asset["actual_format"] in {"PNG", "JPEG"}, f"actual format drift: {source_id}")
        need(asset["dimensions"]["width"] > 0 and asset["dimensions"]["height"] > 0, f"invalid dimensions: {source_id}")
        need(asset["bytes"] > 0, f"invalid bytes: {source_id}")
        need(asset["preliminary_disposition"] in DISPOSITIONS, f"invalid disposition: {source_id}")
        disposition_counts[asset["preliminary_disposition"]] += 1
        uses = set(asset["permitted_next_uses"])
        need(uses and uses <= PERMITTED_USES, f"invalid permitted uses: {source_id}")
        need(asset["strengths"], f"strengths missing: {source_id}")

    controls = ledger["common_controls"]
    need(controls["owner_attestation_reference"] == "DH-OWNER-ATTEST-001", "attestation drift")
    metadata = controls["historical_generation_metadata"]
    need(metadata["uploaded_external_reference_inputs"] == "none_reported_by_owner", "input record drift")
    need(metadata["unknown_metadata_is_automatic_rejection"] is False, "unknown metadata became automatic rejection")
    need(metadata["known_unknowns"], "known unknowns missing")
    need(controls["required_before_exact_use"], "exact-use controls missing")
    need(controls["promotion_state"] == "existing_asset_reviewed_not_promoted", "asset review batch promoted")
    need(controls["release_coordinate"] == "AI-ART-POLICY-001", "release coordinate drift")
    for review_name in ("rights_review_baseline", "similarity_review_baseline", "quality_review_baseline"):
        need(controls[review_name]["status"] and controls[review_name]["notes"], f"{review_name} incomplete")

    need(ids == [f"EXT-VIS-{i:03d}" for i in range(1, 26)], "asset inventory IDs drift")
    expected_counts = {
        "eligible_direct_source_after_edit": 1,
        "eligible_production_input_after_edit": 16,
        "eligible_model_input_after_review": 8,
        "retain_reference_only": 0,
        "reject": 0,
    }
    need(disposition_counts == expected_counts, "ledger disposition counts drift")
    summary = ledger["summary"]
    need(summary["asset_count"] == 25 and summary["assets_promoted"] == 0, "ledger summary drift")
    for key, value in expected_counts.items():
        need(summary[key] == value, f"ledger summary mismatch: {key}")


def validate_docs_and_workflow() -> None:
    text = " ".join("\n".join((ROOT / path).read_text(encoding="utf-8") for path in DOCS).lower().split())
    for phrase in (
        "ai-only production art",
        "human-drawn or human-painted",
        "all 25",
        "eligible for controlled",
        "image-to-image",
        "mask",
        "texture",
        "unknown",
        "not an automatic rejection",
        "full-resolution",
        "no image is automatically approved",
        "assets promoted",
        "pre-generated",
        "live generation",
        "dh-source-plan-001",
        "sha-256",
        "960×540",
        "automation is not human evidence",
    ):
        need(phrase in text, f"required policy statement missing: {phrase}")
    for phrase in (
        "copyright protection guaranteed",
        "non-infringement guaranteed",
        "steam approval guaranteed",
        "all 25 images are approved for shipping",
        "legal clearance complete",
        "production ready",
        "shipping authorized",
    ):
        need(phrase not in text, f"unsupported claim present: {phrase}")

    workflow = (ROOT / WORKFLOW).read_text(encoding="utf-8")
    for token in (
        "actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0",
        "actions/setup-python@ece7cb06caefa5fff74198d8649806c4678c61a1",
        "persist-credentials: false",
        "python-version: 3.11.9",
        "python tools/validate_ai_art_policy.py",
        "python tools/test_validate_ai_art_policy.py",
        "quality/validate_repository.py all",
    ):
        need(token in workflow, f"workflow requirement missing: {token}")
    need("pull_request_target:" not in workflow, "dangerous workflow trigger")


def current_branch() -> str:
    return os.environ.get("GITHUB_HEAD_REF") or os.environ.get("GITHUB_REF_NAME") or subprocess.check_output(
        ["git", "branch", "--show-current"], text=True
    ).strip()


def validate_git_boundary() -> None:
    if current_branch() != BRANCH:
        return
    output = subprocess.check_output(["git", "diff", "--name-only", f"{BASE}...HEAD"], text=True)
    actual = {line for line in output.splitlines() if line}
    need(actual == ALLOWED, f"path mismatch missing={sorted(ALLOWED - actual)} extra={sorted(actual - ALLOWED)}")


def validate_all() -> dict[str, Any]:
    policy = load(POLICY)
    providers = load(PROVIDERS)
    schema = load(SCHEMA)
    ledger = load(LEDGER)
    validate_policy(policy)
    validate_providers(providers)
    validate_schema(schema)
    validate_ledger(ledger)
    validate_docs_and_workflow()
    validate_git_boundary()
    return {
        "release": "AI-ART-POLICY-001",
        "providers": len(providers["providers"]),
        "ledger_assets": len(ledger["assets"]),
        "assets_promoted": ledger["summary"]["assets_promoted"],
        "promotion_stages": len(policy["promotion_stages"]),
        "status": "passed",
    }


def main() -> int:
    try:
        report = validate_all()
    except (OSError, json.JSONDecodeError, KeyError, TypeError, ValidationError, subprocess.CalledProcessError) as error:
        print(f"AI art policy validation failed: {error}", file=sys.stderr)
        return 1
    print(json.dumps(report, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
