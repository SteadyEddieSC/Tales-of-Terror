#!/usr/bin/env python3
"""Regression tests for reviewed external visual candidate validation."""

from __future__ import annotations

import copy

import validate_preproduction_visual_candidates as legacy
from validate_preproduction_visual_candidates_reviewed_external import (
    ReviewedExternalValidationError,
    normalize_for_legacy,
    validate_batches,
    validate_external_review_state,
)


def expect_failure(entry: dict, fragment: str) -> None:
    try:
        validate_external_review_state(entry)
    except ReviewedExternalValidationError as exc:
        assert fragment in str(exc), (fragment, str(exc))
    else:
        raise AssertionError(f"Expected failure containing: {fragment}")


def main() -> int:
    batch_count, candidate_count = validate_batches(legacy.discover_batches())
    assert batch_count >= 1
    assert candidate_count >= 8

    reviewed = {
        "candidate_id": "DH-CAND-999-A",
        "repository_disposition": "external_candidate_pending_upload",
        "status": "generated_external",
        "review_status": "preproduction_shortlist",
        "model_or_tool": "External generator with recorded review provenance",
        "approval_boundary": "Concept only; no production approval.",
    }
    validate_external_review_state(reviewed)

    normalized = normalize_for_legacy({"entries": [reviewed]})
    assert normalized["entries"][0]["review_status"] == "unreviewed"
    assert reviewed["review_status"] == "preproduction_shortlist"

    planned_but_reviewed = copy.deepcopy(reviewed)
    planned_but_reviewed["status"] = "planned"
    expect_failure(planned_but_reviewed, "must be generated_external")

    false_path = copy.deepcopy(reviewed)
    false_path["candidate_path"] = "docs/fake.png"
    expect_failure(false_path, "may not claim a repository path")

    false_digest = copy.deepcopy(reviewed)
    false_digest["sha256"] = "0" * 64
    expect_failure(false_digest, "digest belongs in its review record")

    missing_provenance = copy.deepcopy(reviewed)
    missing_provenance["model_or_tool"] = ""
    expect_failure(missing_provenance, "requires generator provenance")

    print("Reviewed external visual candidate tests passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
