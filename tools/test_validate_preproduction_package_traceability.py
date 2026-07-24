#!/usr/bin/env python3
"""Regression tests for the P0.8 package and traceability validator."""

from __future__ import annotations

import copy
import re
from pathlib import Path

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

FAILURE_PATH = Path("p0.8-regression-failure.txt")


def record_unrejected(case: str) -> None:
    FAILURE_PATH.write_text(case + "\n", encoding="utf-8")


def expect_index_failure(data: dict, case: str) -> None:
    try:
        validate_index(data, ROOT)
    except TraceabilityValidationError as exc:
        assert str(exc).strip(), f"{case}: failure diagnostic must not be empty"
    else:
        record_unrejected(case)
        raise AssertionError(f"Expected package-index rejection: {case}")


def expect_trace_failure(data: dict, case: str) -> None:
    try:
        validate_traceability(data, ROOT)
    except TraceabilityValidationError as exc:
        assert str(exc).strip(), f"{case}: failure diagnostic must not be empty"
    else:
        record_unrejected(case)
        raise AssertionError(f"Expected traceability rejection: {case}")


def expect_handoff_failure(content: str, case: str) -> None:
    try:
        validate_handoff(content)
    except TraceabilityValidationError as exc:
        assert str(exc).strip(), f"{case}: failure diagnostic must not be empty"
    else:
        record_unrejected(case)
        raise AssertionError(f"Expected handoff rejection: {case}")


def main() -> int:
    FAILURE_PATH.unlink(missing_ok=True)
    index = read_json(INDEX_PATH)
    trace = read_json(TRACE_PATH)
    handoff = HANDOFF_PATH.read_text(encoding="utf-8")

    validate_index(index, ROOT)
    validate_traceability(trace, ROOT)
    validate_handoff(handoff)

    authorized = copy.deepcopy(index)
    authorized["runtime_implementation_authorized"] = True
    expect_index_failure(authorized, "runtime implementation authorization")

    catalog = copy.deepcopy(index)
    catalog["production_catalog_authorized"] = True
    expect_index_failure(catalog, "production catalog authorization")

    missing_package = copy.deepcopy(index)
    missing_package["packages"].pop()
    expect_index_failure(missing_package, "missing P0.7 package")

    wrong_order = copy.deepcopy(index)
    wrong_order["packages"][1]["release_id"] = "P0.3"
    expect_index_failure(wrong_order, "nonsequential release order")

    approved_assets = copy.deepcopy(index)
    approved_assets["packages"][2]["production_assets_approved"] = True
    expect_index_failure(approved_assets, "production asset approval")

    missing_path = copy.deepcopy(index)
    missing_path["packages"][0]["primary_paths"][0] = "docs/not_real.md"
    expect_index_failure(missing_path, "missing controlling path")

    wrong_main = copy.deepcopy(index)
    wrong_main["current_protected_main_at_index_creation"] = "0" * 40
    expect_index_failure(wrong_main, "wrong protected-main lineage")

    missing_gate = copy.deepcopy(index)
    missing_gate["known_external_gates"].pop()
    expect_index_failure(missing_gate, "missing required external gate")

    trace_authorized = copy.deepcopy(trace)
    trace_authorized["implementation_authorized"] = True
    expect_trace_failure(trace_authorized, "traceability implementation authorization")

    duplicate_concept = copy.deepcopy(trace)
    duplicate_concept["entries"].append(copy.deepcopy(duplicate_concept["entries"][-1]))
    duplicate_concept["entries"][-1]["concept_id"] = "DH-XM-016"
    expect_trace_failure(duplicate_concept, "duplicate concept title")

    unknown_audio = copy.deepcopy(trace)
    unknown_audio["entries"][0]["audio_asset_ids"].append("DH-AUD-SFX-999")
    expect_trace_failure(unknown_audio, "unknown audio identifier")

    unknown_music = copy.deepcopy(trace)
    signature_entry = next(
        entry for entry in unknown_music["entries"] if entry["criticality"] == "signature"
    )
    signature_entry["music_asset_ids"] = ["DH-MUS-CUE-999"]
    expect_trace_failure(unknown_music, "unknown music identifier")

    missing_access = copy.deepcopy(trace)
    missing_access["entries"][0]["accessible_unit_ids"].pop()
    expect_trace_failure(missing_access, "voice and accessibility coverage drift")

    no_human = copy.deepcopy(trace)
    no_human["entries"][0]["human_validation_required"] = False
    expect_trace_failure(no_human, "human validation removed")

    runtime_status = copy.deepcopy(trace)
    runtime_status["entries"][0]["implementation_status"] = "implementation_ready"
    expect_trace_failure(runtime_status, "implementation-ready concept status")

    missing_signature_visual = copy.deepcopy(trace)
    target = next(
        entry
        for entry in missing_signature_visual["entries"]
        if entry["criticality"] == "signature"
    )
    target["visual_paths"] = []
    expect_trace_failure(missing_signature_visual, "signature concept without visual coverage")

    incomplete_handoff = re.sub(
        r"issue #39 remains open",
        "issue thirty-nine",
        handoff,
        flags=re.IGNORECASE,
    )
    expect_handoff_failure(incomplete_handoff, "missing issue #39 boundary")

    destructive_reset = handoff + "\nRun git reset --hard.\n"
    expect_handoff_failure(destructive_reset, "destructive reset instruction")

    destructive_clean = handoff + "\nRun git clean -fd.\n"
    expect_handoff_failure(destructive_clean, "destructive clean instruction")

    print("Preproduction package traceability tests passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
