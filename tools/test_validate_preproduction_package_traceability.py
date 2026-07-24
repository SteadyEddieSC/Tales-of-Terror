#!/usr/bin/env python3
"""Regression tests for the P0.8 package and traceability validator."""

from __future__ import annotations

import copy

from validate_preproduction_package_traceability import (
    HANDOFF_PATH,
    INDEX_PATH,
    ROOT,
    TRACE_PATH,
    TraceabilityValidationError,
    read_json,
    validate_handoff,
    validate_index,
    validate_traceability,
)


def expect_index_failure(data: dict, fragment: str) -> None:
    try:
        validate_index(data, ROOT)
    except TraceabilityValidationError as exc:
        assert fragment in str(exc), (fragment, str(exc))
    else:
        raise AssertionError(f"Expected package-index failure containing: {fragment}")


def expect_trace_failure(data: dict, fragment: str) -> None:
    try:
        validate_traceability(data, ROOT)
    except TraceabilityValidationError as exc:
        assert fragment in str(exc), (fragment, str(exc))
    else:
        raise AssertionError(f"Expected traceability failure containing: {fragment}")


def expect_handoff_failure(content: str, fragment: str) -> None:
    try:
        validate_handoff(content)
    except TraceabilityValidationError as exc:
        assert fragment in str(exc), (fragment, str(exc))
    else:
        raise AssertionError(f"Expected handoff failure containing: {fragment}")


def main() -> int:
    index = read_json(INDEX_PATH)
    trace = read_json(TRACE_PATH)
    handoff = HANDOFF_PATH.read_text(encoding="utf-8")

    validate_index(index, ROOT)
    validate_traceability(trace, ROOT)
    validate_handoff(handoff)

    authorized = copy.deepcopy(index)
    authorized["runtime_implementation_authorized"] = True
    expect_index_failure(authorized, "may not authorize runtime implementation")

    catalog = copy.deepcopy(index)
    catalog["production_catalog_authorized"] = True
    expect_index_failure(catalog, "may not authorize a production catalog entry")

    missing_package = copy.deepcopy(index)
    missing_package["packages"].pop()
    expect_index_failure(missing_package, "must contain P0.1 through P0.7")

    wrong_order = copy.deepcopy(index)
    wrong_order["packages"][1]["release_id"] = "P0.3"
    expect_index_failure(wrong_order, "release order is not sequential")

    approved_assets = copy.deepcopy(index)
    approved_assets["packages"][2]["production_assets_approved"] = True
    expect_index_failure(approved_assets, "production asset approval is prohibited")

    missing_path = copy.deepcopy(index)
    missing_path["packages"][0]["primary_paths"][0] = "docs/not_real.md"
    expect_index_failure(missing_path, "does not exist")

    wrong_main = copy.deepcopy(index)
    wrong_main["current_protected_main_at_index_creation"] = "0" * 40
    expect_index_failure(wrong_main, "must equal the P0.7 protected-main squash")

    missing_gate = copy.deepcopy(index)
    missing_gate["known_external_gates"].pop()
    expect_index_failure(missing_gate, "must include issues #7, #39, and #44")

    trace_authorized = copy.deepcopy(trace)
    trace_authorized["implementation_authorized"] = True
    expect_trace_failure(trace_authorized, "may not authorize implementation")

    duplicate_concept = copy.deepcopy(trace)
    duplicate_concept["entries"].append(copy.deepcopy(duplicate_concept["entries"][-1]))
    duplicate_concept["entries"][-1]["concept_id"] = "DH-XM-016"
    expect_trace_failure(duplicate_concept, "duplicate concept title")

    unknown_audio = copy.deepcopy(trace)
    unknown_audio["entries"][0]["audio_asset_ids"].append("DH-AUD-SFX-999")
    expect_trace_failure(unknown_audio, "unknown audio ID")

    unknown_music = copy.deepcopy(trace)
    signature_entry = next(
        entry for entry in unknown_music["entries"] if entry["criticality"] == "signature"
    )
    signature_entry["music_asset_ids"] = ["DH-MUS-CUE-999"]
    expect_trace_failure(unknown_music, "unknown music ID")

    missing_access = copy.deepcopy(trace)
    missing_access["entries"][0]["accessible_unit_ids"].pop()
    expect_trace_failure(missing_access, "voice and accessible-unit coverage do not match")

    no_human = copy.deepcopy(trace)
    no_human["entries"][0]["human_validation_required"] = False
    expect_trace_failure(no_human, "human validation must remain required")

    runtime_status = copy.deepcopy(trace)
    runtime_status["entries"][0]["implementation_status"] = "implementation_ready"
    expect_trace_failure(runtime_status, "must remain preproduction_only")

    missing_signature_visual = copy.deepcopy(trace)
    target = next(
        entry
        for entry in missing_signature_visual["entries"]
        if entry["criticality"] == "signature"
    )
    target["visual_paths"] = []
    expect_trace_failure(missing_signature_visual, "signature concepts require visual coverage")

    incomplete_handoff = handoff.replace("Issue #39 remains open", "Issue thirty-nine")
    expect_handoff_failure(incomplete_handoff, "Issue #39 remains open")

    destructive_reset = handoff + "\nRun git reset --hard.\n"
    expect_handoff_failure(destructive_reset, "destructive reset")

    destructive_clean = handoff + "\nRun git clean -fd.\n"
    expect_handoff_failure(destructive_clean, "destructive clean")

    print("Preproduction package traceability tests passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
