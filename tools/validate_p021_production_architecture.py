#!/usr/bin/env python3
"""Validate the P0.21 production architecture and compilation boundary."""

from __future__ import annotations

import argparse
import json
import subprocess
from pathlib import Path
from typing import Any

ROOT = Path(".")
BASELINE = "58f6f4e4ece9bbdd5932216c87aacc064e48e05a"
CONTRACT_PATH = Path("docs/preproduction/drowned_harbor_production_compilation_contract_v1.json")
SCHEMA_PATH = Path("docs/preproduction/drowned_harbor_production_compilation_contract_schema_v1.json")
STATUS_PATH = Path("docs/preproduction/post_prototype_status_v1.json")
TECHNICAL_PATH = Path("docs/technical/Drowned_Harbor_Production_Architecture_and_Compilation_Contract_v1.md")
ISSUE_SET_PATH = Path("docs/preproduction/P0.21_Implementation_Issue_Set.md")
SUMMARY_PATH = Path("docs/preproduction/P0.21_Release_Summary.md")
README_PATH = Path("README.md")
PREPROD_README_PATH = Path("docs/preproduction/README.md")
ROADMAP_PATH = Path("docs/roadmap/Post_P0.19_Production_Candidate_Roadmap.md")

ALLOWED_PATHS = {
    ".github/workflows/p021-production-architecture.yml",
    ".github/workflows/post-prototype-reconciliation.yml",
    "README.md",
    "docs/preproduction/README.md",
    "docs/preproduction/P0.21_Release_Summary.md",
    "docs/preproduction/post_prototype_status_v1.json",
    "docs/preproduction/drowned_harbor_production_compilation_contract_schema_v1.json",
    "docs/preproduction/drowned_harbor_production_compilation_contract_v1.json",
    "docs/preproduction/P0.21_Implementation_Issue_Set.md",
    "docs/technical/Drowned_Harbor_Production_Architecture_and_Compilation_Contract_v1.md",
    "docs/roadmap/Post_P0.19_Production_Candidate_Roadmap.md",
    "tools/validate_p021_production_architecture.py",
    "tools/test_validate_p021_production_architecture.py",
    "tools/validate_post_prototype_reconciliation.py",
    "tools/test_validate_post_prototype_reconciliation.py",
}

IMMUTABLE_INPUTS = {
    "docs/preproduction/tale_authoring_reference_schema_v1.json",
    "docs/tales/drowned_harbor/authoring/drowned_harbor_authoring_reference_v1.json",
    "docs/technical/Tale_Authoring_Reference_Contract_v1.md",
    "docs/technical/Tale_Catalog_Contract.md",
    "docs/technical/Tale_Package_Contract.md",
    "docs/technical/Tale_Runtime_Providers.md",
}

EXPECTED_ROOT = {
    "contract_kind",
    "schema_version",
    "release",
    "authorization",
    "immutable_inputs",
    "compilation_pipeline",
    "authority_ownership",
    "admission",
    "persistence",
    "localization_and_assets",
    "rollback",
    "implementation_stages",
    "evidence_boundaries",
}

EXPECTED_NESTED_SCHEMA_FIELDS = {
    "release": {"release_id", "issue", "baseline", "branch", "state"},
    "authorization": {
        "planning_only",
        "runtime_implementation",
        "production_package",
        "provider_registration",
        "catalog_registration",
        "normal_library_visibility",
        "ordinary_export_inclusion",
        "successor_issue_created",
        "human_evidence_claimed",
    },
    "compilation_pipeline": {
        "input_kind",
        "runtime_input",
        "target_outputs",
        "prohibited_features",
        "traceability_policy",
    },
    "authority_ownership": {
        "stage_progression",
        "authoritative_mutations",
        "public_history",
        "private_terms",
        "rng_streams",
        "director_inputs",
        "presentation",
        "ending_attribution",
        "rejected_action_policy",
        "stable_seat_policy",
        "privacy_classes",
    },
    "admission": {
        "normal_default_tale",
        "normal_production_tale_count",
        "future_tale_id",
        "future_provider_id",
        "future_package_kind",
        "future_package_schema_version",
        "internal_gate",
        "normal_library_visible",
        "ordinary_export_included",
        "dynamic_registration",
        "candidate_commit_policy",
    },
    "persistence": {
        "stable_id_policy",
        "snapshot_selection",
        "migration_policy",
        "replay_policy",
        "exactly_once_policy",
        "rng_policy",
        "reset_policy",
        "rematch_policy",
        "digest_policy",
    },
    "localization_and_assets": {
        "governed_text_keys",
        "captions_and_transcripts",
        "asset_identity",
        "placeholder_policy",
        "provenance_policy",
        "optional_media_fallback",
        "authority_independent_of_media",
    },
    "rollback": {
        "trigger",
        "action",
        "save_behavior",
        "catalog_behavior",
        "provider_behavior",
    },
    "evidence_boundaries": {
        "automation_is_human_evidence",
        "physical_controller_validated",
        "television_readability_validated",
        "accessibility_certified",
        "privacy_certified",
        "security_certified",
        "fun_validated",
        "balance_validated",
        "production_ready",
        "public_release_authorized",
    },
}

EXPECTED_OUTPUTS = [
    "scenario_stage_graph",
    "board_authority",
    "rules_reducer_authority",
    "director_content",
    "social_private_authority",
    "localization_catalog",
    "tale_package",
    "provider_registration",
    "catalog_entry",
    "migration_envelope",
    "validation_evidence",
]

EXPECTED_STAGES = [
    "v0.2.0-alpha.1",
    "v0.2.0-alpha.2",
    "v0.2.0-alpha.3",
    "v0.2.0-beta",
    "v0.2.0-rc",
]

EXPECTED_PRIVACY = [
    "controlled_reveal_private",
    "faction_private",
    "public",
    "seat_private",
]


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
    require(isinstance(value, dict), f"JSON root must be an object: {path}")
    return value


def require_closed_schema_object(node: Any, expected: set[str], label: str) -> None:
    require(isinstance(node, dict), f"schema object missing: {label}")
    require(node.get("type") == "object", f"schema object type drift: {label}")
    require(node.get("additionalProperties") is False, f"schema object must remain closed: {label}")
    required = node.get("required")
    properties = node.get("properties")
    require(isinstance(required, list) and set(required) == expected, f"schema required fields drift: {label}")
    require(isinstance(properties, dict) and set(properties) == expected, f"schema properties drift: {label}")


def validate_schema(schema: dict[str, Any]) -> None:
    require(schema.get("$schema") == "https://json-schema.org/draft/2020-12/schema", "unexpected schema dialect")
    require_closed_schema_object(schema, EXPECTED_ROOT, "root")
    properties = schema["properties"]
    require(properties["contract_kind"].get("const") == "drowned_harbor_production_compilation_contract", "schema contract kind drift")
    require(properties["schema_version"].get("const") == 1, "schema version drift")

    for name, fields in EXPECTED_NESTED_SCHEMA_FIELDS.items():
        require_closed_schema_object(properties.get(name), fields, name)

    release_props = properties["release"]["properties"]
    require(release_props["release_id"].get("const") == "P0.21", "schema release drift")
    require(release_props["issue"].get("const") == 98, "schema issue drift")
    require(release_props["baseline"].get("const") == BASELINE, "schema baseline drift")

    definitions = schema.get("$defs")
    require(isinstance(definitions, dict), "schema definitions missing")
    require_closed_schema_object(
        definitions.get("immutable_input"),
        {"path", "role", "compilation_input", "runtime_input", "mutable_by_p021"},
        "$defs.immutable_input",
    )
    require_closed_schema_object(
        definitions.get("target_output"),
        {"id", "owner", "status", "runtime_registered", "source_traceability_required"},
        "$defs.target_output",
    )
    require_closed_schema_object(
        definitions.get("implementation_stage"),
        {"release_id", "title", "state", "github_issue", "codex_expected", "activation_authorized"},
        "$defs.implementation_stage",
    )

    prohibited = properties["compilation_pipeline"]["properties"]["prohibited_features"]
    require(prohibited.get("minItems") == 12 and prohibited.get("maxItems") == 12, "schema prohibited-feature count drift")


def validate_contract(data: dict[str, Any]) -> None:
    require(set(data) == EXPECTED_ROOT, "contract root field set drift")
    require(data["contract_kind"] == "drowned_harbor_production_compilation_contract", "contract kind drift")
    require(data["schema_version"] == 1, "contract schema version drift")

    require(data["release"] == {
        "release_id": "P0.21",
        "issue": 98,
        "baseline": BASELINE,
        "branch": "docs/p0.21-production-architecture-contract",
        "state": "active_planning",
    }, "release identity drift")

    authorization = data["authorization"]
    require(authorization.get("planning_only") is True, "P0.21 must remain planning-only")
    for field in (
        "runtime_implementation",
        "production_package",
        "provider_registration",
        "catalog_registration",
        "normal_library_visibility",
        "ordinary_export_inclusion",
        "successor_issue_created",
        "human_evidence_claimed",
    ):
        require(authorization.get(field) is False, f"authorization must remain false: {field}")

    immutable = data["immutable_inputs"]
    require(isinstance(immutable, list) and len(immutable) == 6, "immutable input inventory drift")
    require({entry.get("path") for entry in immutable if isinstance(entry, dict)} == IMMUTABLE_INPUTS, "immutable input paths drift")
    for entry in immutable:
        require(entry.get("compilation_input") is True, "immutable source must remain a compilation input")
        require(entry.get("runtime_input") is False, "authoring sources may not become runtime inputs")
        require(entry.get("mutable_by_p021") is False, "P0.21 may not mutate source authorities")

    pipeline = data["compilation_pipeline"]
    require(pipeline.get("input_kind") == "tale_authoring_reference", "unexpected compilation input kind")
    require(pipeline.get("runtime_input") is False, "authoring reference may not be a runtime input")
    outputs = pipeline.get("target_outputs")
    require(isinstance(outputs, list), "target outputs must be a list")
    require([entry.get("id") for entry in outputs] == EXPECTED_OUTPUTS, "target output inventory/order drift")
    for entry in outputs:
        require(entry.get("status") == "future_required", "target output must remain future-required")
        require(entry.get("runtime_registered") is False, "target output may not be runtime-registered")
        require(entry.get("source_traceability_required") is True, "target output must retain source traceability")

    require(set(pipeline.get("prohibited_features", [])) == {
        "arbitrary_code_generation",
        "class_names",
        "script_paths",
        "callbacks",
        "expressions",
        "remote_content",
        "network_urls",
        "credentials",
        "telemetry",
        "untrusted_execution",
        "dynamic_provider_registration",
        "best_effort_identity_guessing",
    }, "prohibited compilation feature set drift")
    require(pipeline.get("traceability_policy") == "every_output_maps_to_repository_authority_and_stable_authoring_ids", "traceability policy drift")

    require(data["authority_ownership"] == {
        "stage_progression": "rules_session_reducer",
        "authoritative_mutations": "rules_session_reducer",
        "public_history": "native_session_public_projection",
        "private_terms": "role_session_private_projection",
        "rng_streams": "named_native_authority_streams",
        "director_inputs": "public_and_authorized_aggregate_state_only",
        "presentation": "read_only_projection_consumers",
        "ending_attribution": "authoritative_rules_and_social_resolution",
        "rejected_action_policy": "state_and_rng_noop_for_invalid_stale_duplicate_wrong_seat_or_unavailable",
        "stable_seat_policy": "seat_owns_state_across_disconnect_surrogate_return_transformation_defeat_and_continuation",
        "privacy_classes": EXPECTED_PRIVACY,
    }, "authority ownership drift")

    require(data["admission"] == {
        "normal_default_tale": "lantern_house_vertical_slice",
        "normal_production_tale_count": 1,
        "future_tale_id": "drowned_harbor",
        "future_provider_id": "drowned_harbor_authorities_v1",
        "future_package_kind": "tale",
        "future_package_schema_version": 1,
        "internal_gate": "developer_only_explicit_launch",
        "normal_library_visible": False,
        "ordinary_export_included": False,
        "dynamic_registration": False,
        "candidate_commit_policy": "validate_complete_candidate_before_authority_commit",
    }, "admission contract drift")

    persistence = data["persistence"]
    require(persistence.get("migration_policy") == "explicit_versioned_migration_or_fail_closed", "migration policy drift")
    require(persistence.get("replay_policy") == "equal_authoritative_inputs_and_seeds_produce_equivalent_outcomes", "replay policy drift")
    require(persistence.get("exactly_once_policy") == "stable_event_identity_persisted_and_deduplicated", "exactly-once policy drift")
    require(persistence.get("rng_policy") == "named_authority_owned_streams_only", "RNG policy drift")
    require(persistence.get("snapshot_selection") == "select_validated_tale_identity_before_restore", "restore selection drift")
    require(persistence.get("digest_policy") == "package_and_catalog_digests_are_provenance_only", "digest authority drift")

    media = data["localization_and_assets"]
    require(media.get("authority_independent_of_media") is True, "media may not own authority")
    require(media.get("provenance_policy") == "license_source_status_and_attribution_required_before_production_use", "provenance policy drift")
    require(media.get("optional_media_fallback") == "safe_text_or_original_placeholder_without_authority_change", "optional-media fallback drift")

    rollback = data["rollback"]
    require(rollback.get("action") == "remove_hidden_admission_and_fail_closed_without_partial_authority", "rollback action drift")
    require(rollback.get("catalog_behavior") == "normal_catalog_remains_lantern_house_only", "rollback catalog drift")

    stages = data["implementation_stages"]
    require(isinstance(stages, list) and [stage.get("release_id") for stage in stages] == EXPECTED_STAGES, "implementation stage inventory/order drift")
    for stage in stages:
        require(stage.get("state") == "planned_blocked", "implementation stage must remain blocked")
        require(stage.get("github_issue") is None, "successor GitHub issue must remain unset")
        require(stage.get("activation_authorized") is False, "implementation stage may not be activated")

    evidence = data["evidence_boundaries"]
    require(isinstance(evidence, dict) and evidence, "evidence boundary missing")
    require(all(value is False for value in evidence.values()), "P0.21 may not claim human or release evidence")


def validate_status(data: dict[str, Any]) -> None:
    require(data.get("protected_main") == BASELINE, "status baseline drift")
    releases = data.get("preproduction_releases")
    require(isinstance(releases, list) and len(releases) == 20, "status must contain P0.1 through P0.20")
    require(releases[-1] == {
        "release_id": "P0.20",
        "pull_request": 97,
        "merged_main_sha": BASELINE,
        "title": "Post-Prototype Reconciliation & Production Decision Pack",
        "state": "merged",
    }, "P0.20 release record drift")
    require(data.get("current_release") == {
        "release_id": "P0.21",
        "issue": 98,
        "branch": "docs/p0.21-production-architecture-contract",
        "type": "documentation_schema_validation",
        "runtime_authority_created": False,
    }, "current P0.21 status drift")
    require(data.get("recommended_next_release") == {
        "release_id": "v0.2.0-alpha.1",
        "title": "Production Tale Scaffold",
        "state": "planned_blocked",
        "github_issue": None,
        "codex_required": True,
        "activation_authorized": False,
    }, "next runtime stage must remain blocked")
    architecture = data.get("production_architecture")
    require(isinstance(architecture, dict), "production architecture status missing")
    require(architecture.get("state") == "active_planning", "architecture status drift")
    require(architecture.get("runtime_input") is False, "architecture contract may not be a runtime input")
    require(architecture.get("normal_library_visible") is False, "Drowned Harbor may not be normally visible")
    require(architecture.get("ordinary_export_included") is False, "Drowned Harbor may not enter ordinary exports")
    require(data.get("runtime_implementation_authorized") is False, "runtime implementation may not be authorized")
    require(data.get("human_evidence_claimed") is False, "human evidence may not be claimed")


def validate_docs(root: Path) -> None:
    docs = {
        "README": read_text(root, README_PATH),
        "preproduction README": read_text(root, PREPROD_README_PATH),
        "roadmap": read_text(root, ROADMAP_PATH),
        "technical contract": read_text(root, TECHNICAL_PATH),
        "issue set": read_text(root, ISSUE_SET_PATH),
        "release summary": read_text(root, SUMMARY_PATH),
    }
    required = {
        "README": [
            "Current active package:** P0.21",
            "Drowned Harbor is not a production Tale and is not ordinarily playable",
            "Automation is not human evidence",
            "v0.2.0-alpha.1 — planned, blocked, and not active",
            "authoring references as compilation inputs, never runtime inputs",
        ],
        "preproduction README": [
            "Current package:** P0.21",
            "planned_blocked",
            "Codex is not required for P0.21",
        ],
        "roadmap": [
            "P0.21 planning stage active",
            "Only P0.21 is active",
            "v0.2.0-alpha.1 — Production Tale Scaffold",
            "GitHub issue:** none",
            "No runtime Codex prompt is created until that separate authorization",
        ],
        "technical contract": [
            "authoring reference and its content manifests are compilation inputs only",
            "Invalid, stale, duplicate, wrong-seat, unavailable, or malformed actions must leave state and RNG unchanged",
            "developer_only_explicit_launch",
            "explicit versioned migration or fail closed",
            "Automation is not human evidence",
        ],
        "issue set": [
            "Definitions only; all stages blocked and inactive",
            "No GitHub issue is created or activated",
            "v0.2.0-alpha.1 Production Tale Scaffold",
            "v0.2.0-rc Hardening & Distribution Readiness",
        ],
        "release summary": [
            "It does not compile, register, expose, or ship Drowned Harbor",
            "P0.1–P0.20 remain recorded as merged",
            "Automation is not human evidence",
        ],
    }
    for label, phrases in required.items():
        for phrase in phrases:
            require(phrase in docs[label], f"{label} missing required phrase: {phrase}")

    combined = "\n".join(docs.values())
    for phrase in (
        "does not activate P0.21",
        "Current package:** P0.20",
        "Drowned Harbor is a production Tale",
        "successor implementation issue activated",
    ):
        require(phrase not in combined, f"stale or prohibited claim retained: {phrase}")


def validate_git_boundary(root: Path) -> None:
    try:
        output = subprocess.check_output(
            ["git", "diff", "--name-only", f"{BASELINE}...HEAD"],
            cwd=root,
            text=True,
            stderr=subprocess.STDOUT,
        )
    except (FileNotFoundError, subprocess.CalledProcessError) as exc:
        raise ValidationError(f"unable to evaluate git boundary: {exc}") from exc
    actual = {line.strip() for line in output.splitlines() if line.strip()}
    require(actual == ALLOWED_PATHS, f"path boundary mismatch: missing={sorted(ALLOWED_PATHS-actual)} unexpected={sorted(actual-ALLOWED_PATHS)}")
    require(not (actual & IMMUTABLE_INPUTS), "immutable authoring/package/catalog/provider authority changed")
    require(not any(path.startswith(("game/", "services/", "web/", "packaging/")) for path in actual), "runtime/service/export path changed")


def validate(root: Path = ROOT, check_git: bool = True) -> None:
    for path in IMMUTABLE_INPUTS:
        require((root / path).is_file(), f"immutable authority missing: {path}")
    validate_schema(read_json(root, SCHEMA_PATH))
    validate_contract(read_json(root, CONTRACT_PATH))
    validate_status(read_json(root, STATUS_PATH))
    validate_docs(root)
    if check_git:
        validate_git_boundary(root)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--skip-git-boundary", action="store_true")
    args = parser.parse_args()
    try:
        validate(args.root, check_git=not args.skip_git_boundary)
    except ValidationError as exc:
        print(f"P0.21 validation failed: {exc}")
        return 1
    print("P0.21 production architecture and compilation contract validated")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
