#!/usr/bin/env python3
"""Regression tests for Drowned Harbor interaction-state trace validation."""

from __future__ import annotations

import copy
import json
import tempfile
from pathlib import Path

from validate_interaction_state_traces import (
    InteractionTraceValidationError,
    TRACEABILITY_PATH,
    discover_storyboards,
    discover_traces,
    load_concepts,
    load_storyboards,
    read_json,
    validate_manifests,
    validate_trace,
)


def expect_trace_failure(entry: dict, storyboards: dict, concepts: set[str], fragment: str) -> None:
    try:
        validate_trace(entry, 0, storyboards, concepts)
    except InteractionTraceValidationError as exc:
        assert fragment in str(exc), (fragment, str(exc))
    else:
        raise AssertionError(f"Expected trace failure containing: {fragment}")


def expect_manifest_failure(manifests: list[dict], storyboards: dict, concepts: set[str], fragment: str) -> None:
    with tempfile.TemporaryDirectory() as tmp:
        paths: list[Path] = []
        for index, manifest in enumerate(manifests):
            path = Path(tmp) / f"manifest_{index}.json"
            path.write_text(json.dumps(manifest), encoding="utf-8")
            paths.append(path)
        try:
            validate_manifests(paths, storyboards, concepts)
        except InteractionTraceValidationError as exc:
            assert fragment in str(exc), (fragment, str(exc))
        else:
            raise AssertionError(f"Expected manifest failure containing: {fragment}")


def main() -> int:
    paths = discover_traces()
    storyboards = load_storyboards(discover_storyboards())
    concepts = load_concepts(TRACEABILITY_PATH)
    manifest_count, trace_count, event_count = validate_manifests(paths, storyboards, concepts)
    assert manifest_count == 3
    assert trace_count == 22
    assert event_count >= 22

    manifests = [read_json(path) for path in paths]
    entries = [entry for manifest in manifests for entry in manifest["entries"]]
    public_trace = next(entry for entry in entries if entry["trace_id"] == "DH-IS-001")
    private_trace = next(entry for entry in entries if entry["trace_id"] == "DH-IS-007")
    commit_trace = next(entry for entry in entries if entry["trace_id"] == "DH-IS-005")
    critical_trace = next(entry for entry in entries if entry["criticality"] == "critical")

    unknown_storyboard = copy.deepcopy(public_trace)
    unknown_storyboard["storyboard_id"] = "DH-UI-999"
    expect_trace_failure(unknown_storyboard, storyboards, concepts, "unknown storyboard ID")

    privacy_drift = copy.deepcopy(public_trace)
    privacy_drift["privacy_surface"] = "controlled_private_surface"
    expect_trace_failure(privacy_drift, storyboards, concepts, "privacy surface differs from storyboard")

    private_no_shield = copy.deepcopy(private_trace)
    private_no_shield["privacy_contract"]["neutral_shield_required"] = False
    expect_trace_failure(private_no_shield, storyboards, concepts, "private surface requires a neutral shield")

    private_no_actor = copy.deepcopy(private_trace)
    private_no_actor["privacy_contract"]["authorized_private_actor_required"] = False
    expect_trace_failure(private_no_actor, storyboards, concepts, "private surface requires an authorized private actor")

    private_no_output = copy.deepcopy(private_trace)
    private_no_output["projection_contract"]["private_outputs"] = []
    expect_trace_failure(private_no_output, storyboards, concepts, "private surface requires private outputs")

    nondeterministic = copy.deepcopy(commit_trace)
    nondeterministic["commit_contract"]["deterministic"] = False
    expect_trace_failure(nondeterministic, storyboards, concepts, "interactions must be deterministic")

    partial_commit = copy.deepcopy(commit_trace)
    partial_commit["commit_contract"]["partial_commit_prohibited"] = False
    expect_trace_failure(partial_commit, storyboards, concepts, "partial commit must be prohibited")

    no_exactly_once = copy.deepcopy(commit_trace)
    for event in no_exactly_once["projection_contract"]["emitted_events"]:
        event["exactly_once"] = False
    expect_trace_failure(no_exactly_once, storyboards, concepts, "authoritative commits require an exactly-once event")

    missing_recovery = copy.deepcopy(commit_trace)
    missing_recovery["recovery_contract"] = []
    expect_trace_failure(missing_recovery, storyboards, concepts, "at least two recovery cases are required")

    stable_seat_lost = copy.deepcopy(critical_trace)
    stable_seat_lost["presentation_obligations"]["active_seat_identity_preserved"] = False
    expect_trace_failure(stable_seat_lost, storyboards, concepts, "active_seat_identity_preserved must be true")

    confirmation_drift = copy.deepcopy(commit_trace)
    confirmation_drift["presentation_obligations"]["confirmation_pattern"] = "none"
    expect_trace_failure(confirmation_drift, storyboards, concepts, "confirmation pattern differs from storyboard")

    missing_source = copy.deepcopy(public_trace)
    missing_source["source_paths"][0] = "docs/not_a_real_contract.md"
    expect_trace_failure(missing_source, storyboards, concepts, "does not exist")

    unknown_concept = copy.deepcopy(public_trace)
    unknown_concept["traceability_concepts"] = ["DH-XM-999"]
    expect_trace_failure(unknown_concept, storyboards, concepts, "unknown traceability concept")

    premature_authorization = copy.deepcopy(public_trace)
    premature_authorization["status"] = "implementation_authorized"
    expect_trace_failure(premature_authorization, storyboards, concepts, "may not authorize implementation or production")

    too_short_human_review = copy.deepcopy(public_trace)
    too_short_human_review["human_validation_questions"] = ["Too short", "Also too short"]
    expect_trace_failure(too_short_human_review, storyboards, concepts, "human-validation questions are too short")

    duplicate_trace_manifests = copy.deepcopy(manifests)
    duplicate = copy.deepcopy(duplicate_trace_manifests[0]["entries"][0])
    duplicate_trace_manifests[0]["entries"].append(duplicate)
    expect_manifest_failure(duplicate_trace_manifests, storyboards, concepts, "duplicate interaction trace ID")

    duplicate_event_manifests = copy.deepcopy(manifests)
    first_event = duplicate_event_manifests[0]["entries"][0]["projection_contract"]["emitted_events"][0]["event_key"]
    duplicate_event_manifests[0]["entries"][1]["projection_contract"]["emitted_events"][0]["event_key"] = first_event
    expect_manifest_failure(duplicate_event_manifests, storyboards, concepts, "duplicate event key across traces")

    missing_coverage = copy.deepcopy(manifests)
    missing_coverage[0]["entries"].pop()
    expect_manifest_failure(missing_coverage, storyboards, concepts, "interaction trace coverage differs")

    print("Interaction-state trace validator tests passed: 18 fail-closed mutations")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
