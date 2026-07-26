#!/usr/bin/env python3
"""Regression tests for the P0.12 prototype authorization validator."""

from __future__ import annotations

import copy

from validate_prototype_authorization import (
    DECISION_PATH,
    PrototypeAuthorizationValidationError,
    read_json,
    validate_catalog,
    validate_decision,
)


def expect_failure(decision: dict, fragment: str) -> None:
    try:
        validate_decision(decision)
    except PrototypeAuthorizationValidationError as exc:
        assert fragment in str(exc), (fragment, str(exc))
    else:
        raise AssertionError(f"Expected validation failure containing: {fragment}")


def main() -> int:
    validate_catalog()
    decision = read_json(DECISION_PATH)
    validate_decision(decision)

    wrong_baseline = copy.deepcopy(decision)
    wrong_baseline["baseline_main_sha"] = "0" * 40
    expect_failure(wrong_baseline, "baseline must remain")

    runtime_enabled = copy.deepcopy(decision)
    runtime_enabled["runtime_changes_in_release"] = True
    expect_failure(runtime_enabled, "runtime_changes_in_release must remain false")

    catalog_authorized = copy.deepcopy(decision)
    catalog_authorized["production_catalog_change_authorized"] = True
    expect_failure(catalog_authorized, "production_catalog_change_authorized must remain false")

    provider_authorized = copy.deepcopy(decision)
    provider_authorized["provider_change_authorized"] = True
    expect_failure(provider_authorized, "provider_change_authorized must remain false")

    export_authorized = copy.deepcopy(decision)
    export_authorized["playable_export_authorized"] = True
    expect_failure(export_authorized, "playable_export_authorized must remain false")

    human_claimed = copy.deepcopy(decision)
    human_claimed["human_evidence_claimed"] = True
    expect_failure(human_claimed, "human_evidence_claimed must remain false")

    explicit_reopen_claimed = copy.deepcopy(decision)
    gate = next(item for item in explicit_reopen_claimed["unlock_gates"] if item["gate_id"] == "explicit_user_reopen")
    gate["satisfied_in_p0_12"] = True
    expect_failure(explicit_reopen_claimed, "unlock gate identities or current satisfaction values changed")

    self_merged_claimed = copy.deepcopy(decision)
    gate = next(item for item in self_merged_claimed["unlock_gates"] if item["gate_id"] == "p0_12_merged")
    gate["satisfied_in_p0_12"] = True
    expect_failure(self_merged_claimed, "unlock gate identities or current satisfaction values changed")

    unblocked_package = copy.deepcopy(decision)
    unblocked_package["work_packages"][0]["status"] = "implementation_authorized"
    expect_failure(unblocked_package, "work package must remain blocked")

    duplicate_issue = copy.deepcopy(decision)
    duplicate_issue["work_packages"][1]["github_issue"] = 80
    expect_failure(duplicate_issue, "duplicate GitHub issue")

    dependency_cycle = copy.deepcopy(decision)
    dependency_cycle["work_packages"][0]["depends_on_issues"].append(80)
    expect_failure(dependency_cycle, "dependencies must precede")

    unknown_trace = copy.deepcopy(decision)
    unknown_trace["work_packages"][1]["trace_ids"].append("DH-IS-999")
    expect_failure(unknown_trace, "unknown P0.11 trace ID")

    missing_source = copy.deepcopy(decision)
    missing_source["work_packages"][0]["source_paths"][0] = "docs/not_a_real_authority.md"
    expect_failure(missing_source, "source path does not exist")

    suppressed_external_gate = copy.deepcopy(decision)
    suppressed_external_gate["external_gates"][2]["may_be_suppressed"] = True
    expect_failure(suppressed_external_gate, "external gate may not be suppressed")

    missing_external_gate = copy.deepcopy(decision)
    missing_external_gate["external_gates"].pop()
    expect_failure(missing_external_gate, "external gate set must contain exactly")

    weak_boundary = copy.deepcopy(decision)
    weak_boundary["approval_boundary"] = "This decision allows the prototype to proceed after review without further limitations."
    expect_failure(weak_boundary, "approval boundary must explicitly deny runtime-file authorization")

    missing_required_package = copy.deepcopy(decision)
    missing_required_package["work_packages"].pop()
    expect_failure(missing_required_package, "work package set must contain exactly 7")

    wrong_production_tale = copy.deepcopy(decision)
    wrong_production_tale["production_tale"] = "drowned_harbor"
    expect_failure(wrong_production_tale, "Lantern House must remain the production Tale")

    print("Prototype authorization validator tests passed: 18 fail-closed mutations")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
