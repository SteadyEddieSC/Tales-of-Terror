#!/usr/bin/env python3
"""Regression tests for governed preproduction visual candidate batches."""

from __future__ import annotations

import copy

from validate_preproduction_visual_candidates import (
    DEFAULT_VISUAL_DIR,
    VisualCandidateValidationError,
    load_asset_index,
    read_batch,
    validate_batch,
)

DEFAULT_BATCH = DEFAULT_VISUAL_DIR / "drowned_harbor_concept_batch_001.json"


def expect_failure(data: dict, fragment: str) -> None:
    assets = load_asset_index()
    try:
        validate_batch(data, assets)
    except VisualCandidateValidationError as exc:
        assert fragment in str(exc), (fragment, str(exc))
    else:
        raise AssertionError(f"Expected failure containing: {fragment}")


def main() -> int:
    assets = load_asset_index()
    valid = read_batch(DEFAULT_BATCH)
    batch_id, count = validate_batch(valid, assets)
    assert batch_id == "DH-CB-001"
    assert count == 4

    duplicate = copy.deepcopy(valid)
    duplicate["entries"].append(copy.deepcopy(duplicate["entries"][0]))
    expect_failure(duplicate, "duplicate candidate id")

    unknown_asset = copy.deepcopy(valid)
    unknown_asset["entries"][0]["asset_id"] = "DH-KEY-999"
    expect_failure(unknown_asset, "unknown asset id")

    prompt_drift = copy.deepcopy(valid)
    prompt_drift["entries"][0]["prompt"] += " add a bright moon"
    expect_failure(prompt_drift, "prompt differs from governed brief")

    negative_drift = copy.deepcopy(valid)
    negative_drift["entries"][0]["negative_prompt"] += ", extra boats"
    expect_failure(negative_drift, "negative prompt differs from governed brief")

    imitation = copy.deepcopy(valid)
    imitation["entries"][0]["prompt_source"] = "governed_revision"
    imitation["entries"][0]["prompt"] += " in the style of a famous painter"
    expect_failure(imitation, "disallowed imitation phrase")

    hidden_input = copy.deepcopy(valid)
    hidden_input["entries"][0]["input_assets"] = ["private/reference.png"]
    expect_failure(hidden_input, "explicit third-party-input record")

    unlisted_third_party = copy.deepcopy(valid)
    unlisted_third_party["entries"][0]["third_party_inputs"] = True
    expect_failure(unlisted_third_party, "third-party inputs must be listed")

    false_upload = copy.deepcopy(valid)
    false_upload["entries"][0]["repository_disposition"] = (
        "public_candidate_path_recorded"
    )
    false_upload["entries"][0]["status"] = "uploaded_unreviewed"
    expect_failure(false_upload, "candidate_path must be non-empty text")

    premature_review = copy.deepcopy(valid)
    premature_review["entries"][0]["review_status"] = "preproduction_shortlist"
    expect_failure(premature_review, "must remain unreviewed")

    wrong_source = copy.deepcopy(valid)
    wrong_source["entries"][0]["source_kind"] = "original_human"
    expect_failure(wrong_source, "source_kind does not match generator")

    print("Preproduction visual candidate validator tests passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
