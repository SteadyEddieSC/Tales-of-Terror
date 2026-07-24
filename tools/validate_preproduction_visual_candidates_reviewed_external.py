#!/usr/bin/env python3
"""Validate external visual candidates that may be reviewed before repository upload."""

from __future__ import annotations

import copy
import sys
from pathlib import Path
from typing import Any, Sequence

import validate_preproduction_visual_candidates as legacy


class ReviewedExternalValidationError(ValueError):
    """Raised when reviewed external candidate state is inconsistent."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ReviewedExternalValidationError(message)


def normalize_for_legacy(data: dict[str, Any]) -> dict[str, Any]:
    """Normalize reviewed external records for the original structural validator."""

    normalized = copy.deepcopy(data)
    for entry in normalized.get("entries", []):
        if (
            entry.get("repository_disposition")
            == "external_candidate_pending_upload"
            and entry.get("status") == "generated_external"
            and entry.get("review_status") != "unreviewed"
        ):
            entry["review_status"] = "unreviewed"
    return normalized


def validate_external_review_state(entry: dict[str, Any]) -> None:
    candidate_id = entry.get("candidate_id", "unknown-candidate")
    disposition = entry.get("repository_disposition")
    status = entry.get("status")
    review_status = entry.get("review_status")

    if disposition != "external_candidate_pending_upload":
        return

    require(
        entry.get("candidate_path") is None,
        f"{candidate_id}: external-only candidate may not claim a repository path",
    )
    require(
        entry.get("sha256") is None,
        f"{candidate_id}: external-only candidate digest belongs in its review record, not as a repository upload claim",
    )

    if review_status == "unreviewed":
        require(
            status in {"planned", "generated_external", "deferred"},
            f"{candidate_id}: unreviewed external candidate has invalid status",
        )
        return

    require(
        status == "generated_external",
        f"{candidate_id}: reviewed external candidate must be generated_external",
    )
    require(
        review_status
        in {"needs_revision", "reference_only", "rejected", "preproduction_shortlist"},
        f"{candidate_id}: invalid reviewed external disposition",
    )
    require(
        bool(str(entry.get("model_or_tool", "")).strip()),
        f"{candidate_id}: reviewed external candidate requires generator provenance",
    )
    require(
        bool(str(entry.get("approval_boundary", "")).strip()),
        f"{candidate_id}: reviewed external candidate requires a non-approval boundary",
    )


def validate_batches(paths: Sequence[Path]) -> tuple[int, int]:
    require(bool(paths), "at least one candidate batch is required")
    assets = legacy.load_asset_index()
    batch_ids: set[str] = set()
    candidate_ids: set[str] = set()
    total = 0

    for path in paths:
        data = legacy.read_batch(path)
        entries = data.get("entries")
        require(isinstance(entries, list), f"entries must be a list: {path}")
        for entry in entries:
            require(isinstance(entry, dict), f"candidate entry must be an object: {path}")
            validate_external_review_state(entry)

        normalized = normalize_for_legacy(data)
        batch_id, count = legacy.validate_batch(normalized, assets)
        require(batch_id not in batch_ids, f"duplicate batch id: {batch_id}")
        batch_ids.add(batch_id)

        for entry in entries:
            candidate_id = entry["candidate_id"]
            require(
                candidate_id not in candidate_ids,
                f"duplicate candidate id across batches: {candidate_id}",
            )
            candidate_ids.add(candidate_id)
        total += count

    return len(paths), total


def main(argv: list[str] | None = None) -> int:
    args = sys.argv[1:] if argv is None else argv
    paths = tuple(Path(value) for value in args) if args else legacy.discover_batches()
    try:
        batch_count, candidate_count = validate_batches(paths)
    except (ReviewedExternalValidationError, legacy.VisualCandidateValidationError) as exc:
        print(f"Visual candidate validation failed: {exc}", file=sys.stderr)
        return 1

    print(
        f"Validated {candidate_count} visual candidates across "
        f"{batch_count} batch(es), including governed external reviews"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
