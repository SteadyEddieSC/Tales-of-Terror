#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import re
import subprocess
import sys
from pathlib import Path
from typing import Any

ROOT = Path(".")
BASE = "0a6686d8cc4d15feac81c128cfc414b954e234b1"
BRANCH = "docs/ai-art-policy-001"

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
    "docs/technical/Steam_PreGenerated_AI_Disclosure_Draft_v1.md",
    "docs/tales/drowned_harbor/visual/Drowned_Harbor_AI_Only_Art_Provenance_Amendment_v1.md",
    "art/ai/ai_art_policy_v1.json",
    "art/ai/approved_generators_v1.json",
    "art/ai/ai_art_provenance_schema_v1.json",
    "art/ai/ai_art_provenance_ledger_v1.json",
    "tools/validate_ai_art_policy.py",
    "tools/test_validate_ai_art_policy.py",
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


def resolve_ref(schema_root: dict[str, Any], ref: str) -> dict[str, Any]:
    need(ref.startswith("#/"), f"unsupported schema reference: {ref}")
    value: Any = schema_root
    for part in ref[2:].split("/"):
        value = value[part.replace("~1", "/").replace("~0", "~")]
    need(isinstance(value, dict), f"schema reference is not an object: {ref}")
    return value


def type_matches(value: Any, expected: str) -> bool:
    return {
        "object": isinstance(value, dict),
        "array": isinstance(value, list),
        "string": isinstance(value, str),
        "integer": isinstance(value, int) and not isinstance(value, bool),
        "number": isinstance(value, (int, float)) and not isinstance(value, bool),
        "boolean": isinstance(value, bool),
        "null": value is None,
    }.get(expected, False)


def validate_instance(value: Any, schema: dict[str, Any], root_schema: dict[str, Any], path: str = "$") -> None:
    if "$ref" in schema:
        validate_instance(value, resolve_ref(root_schema, schema["$ref"]), root_schema, path)
        return
    if "anyOf" in schema:
        errors = []
        for candidate in schema["anyOf"]:
            try:
                validate_instance(value, candidate, root_schema, path)
                return
            except ValidationError as error:
                errors.append(str(error))
        raise ValidationError(f"{path}: no anyOf option matched: {errors}")
    if "const" in schema:
        need(value == schema["const"], f"{path}: const mismatch")
    if "enum" in schema:
        need(value in schema["enum"], f"{path}: enum mismatch")
    if "type" in schema:
        need(type_matches(value, schema["type"]), f"{path}: expected {schema['type']}")
    if isinstance(value, dict):
        properties = schema.get("properties", {})
        required = schema.get("required", [])
        for key in required:
            need(key in value, f"{path}: missing {key}")
        if schema.get("additionalProperties") is False:
            extra = set(value) - set(properties)
            need(not extra, f"{path}: unexpected fields {sorted(extra)}")
        for key, child in value.items():
            if key in properties:
                validate_instance(child, properties[key], root_schema, f"{path}.{key}")
    if isinstance(value, list):
        if "minItems" in schema:
            need(len(value) >= schema["minItems"], f"{path}: too few items")
        if "maxItems" in schema:
            need(len(value) <= schema["maxItems"], f"{path}: too many items")
        if schema.get("uniqueItems"):
            encoded = [json.dumps(item, sort_keys=True) for item in value]
            need(len(encoded) == len(set(encoded)), f"{path}: duplicate items")
        if "items" in schema:
            for index, child in enumerate(value):
                validate_instance(child, schema["items"], root_schema, f"{path}[{index}]")
    if isinstance(value, str):
        if "minLength" in schema:
            need(len(value) >= schema["minLength"], f"{path}: string too short")
        if "pattern" in schema:
            need(re.search(schema["pattern"], value) is not None, f"{path}: pattern mismatch")


def audit_closed_schema(schema: Any, path: str = "$") -> int:
    count = 0
    if isinstance(schema, dict):
        if schema.get("type") == "object":
            count += 1
            need(schema.get("additionalProperties") is False, f"{path}: object schema is not closed")
            properties = schema.get("properties")
            required = schema.get("required")
            need(isinstance(properties, dict), f"{path}: properties missing")
            need(isinstance(required, list), f"{path}: required missing")
            need(set(required) == set(properties), f"{path}: required/properties mismatch")
        for key, child in schema.items():
            count += audit_closed_schema(child, f"{path}.{key}")
    elif isinstance(schema, list):
        for index, child in enumerate(schema):
            count += audit_closed_schema(child, f"{path}[{index}]")
    return count


def validate_policy(policy: dict[str, Any]) -> None:
    exact_keys(
        policy,
        {"record_kind", "record_version", "release", "decision", "supersession", "registries", "promotion_stages", "required_reviews", "stop_conditions", "authoritative_documents"},
        "policy",
    )
    need(policy["record_kind"] == "terror_turn_ai_art_policy" and policy["record_version"] == 1, "policy identity drift")
    release = policy["release"]
    exact_keys(release, {"release_id", "governing_issue", "repository", "protected_main", "policy_date", "release_type", "state"}, "release")
    need(release == {
        "release_id": "AI-ART-POLICY-001",
        "governing_issue": 151,
        "repository": "SteadyEddieSC/Tales-of-Terror",
        "protected_main": BASE,
        "policy_date": "2026-08-05",
        "release_type": "metadata_only_ai_art_policy_and_provenance_authority",
        "state": "policy_only_no_assets",
    }, "release coordinates drift")
    decision = policy["decision"]
    exact_keys(decision, {
        "new_production_visuals_policy", "human_drawn_or_painted_source_required",
        "human_art_direction_selection_arrangement_and_review_required",
        "ai_generated_pixels_may_become_eligible_after_separate_asset_promotion",
        "generation_authorized_by_this_release", "import_authorized_by_this_release",
        "runtime_integration_authorized_by_this_release", "ordinary_export_authorized_by_this_release",
        "marketing_authorized_by_this_release", "storefront_publication_authorized_by_this_release",
        "live_generation_authorized", "copyrightability_of_machine_determined_pixels_assumed",
        "steam_ai_classification",
    }, "decision")
    need(decision["new_production_visuals_policy"] == "ai_generated_or_ai_assisted_source_required_unless_exception_approved", "AI-only direction drift")
    need(decision["human_drawn_or_painted_source_required"] is False, "human-drawn source requirement reintroduced")
    need(decision["human_art_direction_selection_arrangement_and_review_required"] is True, "human review removed")
    need(decision["ai_generated_pixels_may_become_eligible_after_separate_asset_promotion"] is True, "future AI eligibility removed")
    for key in [
        "generation_authorized_by_this_release", "import_authorized_by_this_release",
        "runtime_integration_authorized_by_this_release", "ordinary_export_authorized_by_this_release",
        "marketing_authorized_by_this_release", "storefront_publication_authorized_by_this_release",
        "live_generation_authorized", "copyrightability_of_machine_determined_pixels_assumed",
    ]:
        need(decision[key] is False, f"forbidden current authority or claim enabled: {key}")
    need(decision["steam_ai_classification"] == "pre_generated_ai_content", "Steam classification drift")
    supersession = policy["supersession"]
    exact_keys(supersession, {"historical_authority", "historical_record_unchanged", "superseded_future_requirements", "preserved_requirements"}, "supersession")
    need(supersession["historical_authority"] == "DH-SOURCE-PLAN-001", "historical authority drift")
    need(supersession["historical_record_unchanged"] is True, "historical record rewritten")
    need(set(supersession["superseded_future_requirements"]) == {
        "blank_human_authored_editable_sources_required",
        "all_direct_ai_generated_pixel_use_permanently_prohibited",
        "independent_human_authorship_disposition_required_for_future_source_acceptance",
    }, "superseded requirement set drift")
    preserved = set(supersession["preserved_requirements"])
    for required in {
        "all_25_external_reference_images_remain_R1_private_internal_reference",
        "none_of_the_25_external_reference_images_are_source_files",
        "no_tracing_vectorization_paint_over_or_fragment_extraction_from_external_reference_images",
        "provider_model_prompt_source_input_and_hash_provenance",
        "independent_similarity_review",
        "no_current_generation_import_runtime_export_marketing_or_publication_authority",
        "automation_is_not_human_evidence",
    }:
        need(required in preserved, f"preserved protection missing: {required}")
    need(policy["registries"] == {
        "approved_generators": "art/ai/approved_generators_v1.json",
        "provenance_schema": "art/ai/ai_art_provenance_schema_v1.json",
        "provenance_ledger": "art/ai/ai_art_provenance_ledger_v1.json",
    }, "registry paths drift")
    need(policy["promotion_stages"][0] == "policy_only_no_assets", "promotion lifecycle start drift")
    need(policy["promotion_stages"][-1] == "retired_or_rejected", "promotion lifecycle end drift")
    need(len(policy["promotion_stages"]) == 9 and len(set(policy["promotion_stages"])) == 9, "promotion stage count drift")
    need(len(policy["required_reviews"]) == 10 and len(set(policy["required_reviews"])) == 10, "required review count drift")
    need(len(policy["stop_conditions"]) == 14 and len(set(policy["stop_conditions"])) == 14, "stop condition count drift")
    need(set(policy["authoritative_documents"]) == {path.as_posix() for path in DOCS if "releases/" not in path.as_posix()}, "authoritative document set drift")


def validate_providers(providers: dict[str, Any]) -> None:
    exact_keys(providers, {"record_kind", "record_version", "policy_release", "verified_on", "providers"}, "providers")
    need(providers["record_kind"] == "terror_turn_approved_ai_generators", "provider registry kind drift")
    need(providers["record_version"] == 1 and providers["policy_release"] == "AI-ART-POLICY-001", "provider registry identity drift")
    need(providers["verified_on"] == "2026-08-05", "provider verification date drift")
    need(len(providers["providers"]) == 2, "provider count drift")
    by_id = {entry["provider_id"]: entry for entry in providers["providers"]}
    need(set(by_id) == {"openai_chatgpt_image_generation", "google_gemini_apps_image_generation"}, "provider IDs drift")
    openai = by_id["openai_chatgpt_image_generation"]
    google = by_id["google_gemini_apps_image_generation"]
    for entry in providers["providers"]:
        exact_keys(entry, {"provider_id", "provider", "service", "eligibility", "account_requirement", "model_record_requirement", "terms", "mandatory_controls"}, entry["provider_id"])
        need(entry["terms"] and entry["mandatory_controls"], f"{entry['provider_id']}: missing terms or controls")
        for term in entry["terms"]:
            exact_keys(term, {"title", "effective", "url", "rights_summary"}, f"{entry['provider_id']} term")
            need(term["url"].startswith("https://"), f"{entry['provider_id']}: non-HTTPS terms URL")
    need(openai["provider"] == "OpenAI" and openai["eligibility"] == "eligible_after_separate_generation_activation", "OpenAI eligibility drift")
    need(any(term["url"] == "https://openai.com/policies/terms-of-use/" for term in openai["terms"]), "OpenAI Terms of Use missing")
    need("do_not_represent_output_as_human_generated" in openai["mandatory_controls"], "OpenAI disclosure control missing")
    need(google["provider"] == "Google" and google["eligibility"] == "conditional_after_separate_generation_activation", "Google eligibility overpromoted")
    need(any(term["url"].startswith("https://policies.google.com/terms") for term in google["terms"]), "Google Terms missing")
    need("owner_or_legal_review_required_before_storefront_candidate" in google["mandatory_controls"], "Google conditional review missing")


def validate_schema_and_ledger(schema: dict[str, Any], ledger: dict[str, Any]) -> None:
    need(schema.get("$schema") == "https://json-schema.org/draft/2020-12/schema", "schema draft drift")
    need(audit_closed_schema(schema) >= 6, "closed schema coverage too small")
    validate_instance(ledger, schema, schema)
    need(ledger == {
        "record_kind": "terror_turn_ai_art_provenance_ledger",
        "record_version": 1,
        "policy_release": "AI-ART-POLICY-001",
        "state": "policy_only_no_assets",
        "assets": [],
    }, "ledger must remain empty policy state")
    asset = schema["$defs"]["asset"]
    required = set(asset["required"])
    for field in {
        "asset_id", "provider_id", "model_name", "model_version", "generated_on", "account_owner", "prompt",
        "source_inputs", "generator_output_sha256", "transformations", "runtime_exports",
        "c2pa_or_content_credentials", "watermark_or_signature_disposition", "human_contributions",
        "rights_review", "similarity_review", "quality_review", "promotion_state", "release_coordinate",
    }:
        need(field in required, f"asset schema missing required field: {field}")
    need(asset.get("additionalProperties") is False, "asset schema is not closed")


def validate_docs_and_workflow() -> None:
    text = " ".join("\n".join((ROOT / path).read_text(encoding="utf-8") for path in DOCS).lower().split())
    for phrase in [
        "ai-only production art",
        "human-drawn or human-painted",
        "machine-determined pixels",
        "not presumed copyrightable",
        "pre-generated",
        "live generation",
        "dh-source-plan-001",
        "historical record",
        "all 25",
        "r1_private_internal_reference",
        "named living artist",
        "active studio",
        "substantial similarity",
        "c2pa",
        "sha-256",
        "art/provenance.json",
        "960×540",
        "controller-first",
        "automation is not human evidence",
        "no asset",
    ]:
        need(phrase in text, f"required policy statement missing: {phrase}")
    for phrase in [
        "copyright protection guaranteed",
        "non-infringement guaranteed",
        "steam approval guaranteed",
        "live-generated ai is authorized",
        "asset generation is authorized by this release",
        "the 25 external images are source files",
        "legal clearance complete",
        "production ready",
        "shipping authorized",
    ]:
        need(phrase not in text, f"unsupported claim: {phrase}")
    workflow = (ROOT / WORKFLOW).read_text(encoding="utf-8")
    for token in [
        "actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0",
        "actions/setup-python@ece7cb06caefa5fff74198d8649806c4678c61a1",
        "persist-credentials: false",
        "python-version: 3.11.9",
        "python tools/validate_ai_art_policy.py",
        "python tools/test_validate_ai_art_policy.py",
        "quality/validate_repository.py all",
    ]:
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
    validate_schema_and_ledger(schema, ledger)
    validate_docs_and_workflow()
    validate_git_boundary()
    return {
        "release": "AI-ART-POLICY-001",
        "providers": len(providers["providers"]),
        "ledger_assets": len(ledger["assets"]),
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
