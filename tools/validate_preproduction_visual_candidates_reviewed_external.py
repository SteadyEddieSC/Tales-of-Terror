#!/usr/bin/env python3
"""Validate legacy and metadata-only external visual candidate records."""

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


def validate_metadata_only_register(
    data: dict[str, Any], assets: dict[str, dict[str, Any]]
) -> tuple[str, list[str]]:
    """Fail-closed validation for a register that truthfully lacks old schema facts."""

    require(
        data.get("register_kind") == "external_visual_candidate_register",
        "unexpected external register kind",
    )
    require(data.get("register_version") == 1, "unsupported external register version")
    batch_id = data.get("batch_id")
    require(
        isinstance(batch_id, str) and legacy.BATCH_ID_PATTERN.fullmatch(batch_id),
        "invalid external register batch_id",
    )
    require(data.get("baseline_id") == "DH-VBL-001", "unexpected baseline id")
    require(
        data.get("repository_storage") == "metadata_only_external_binaries",
        "external register must remain metadata-only",
    )

    schema_state = data.get("existing_candidate_schema")
    require(isinstance(schema_state, dict), "existing schema state must be an object")
    require(
        schema_state.get("conformance")
        == "blocked_by_unresolved_required_source_facts",
        "external register may not claim old schema conformance",
    )
    require(
        schema_state.get("must_not_be_claimed_conformant") is True,
        "external register conformance boundary removed",
    )

    candidates = data.get("candidates")
    require(isinstance(candidates, list) and candidates, "candidates must be a non-empty list")
    candidate_ids: list[str] = []
    seen: set[str] = set()
    for index, entry in enumerate(candidates):
        prefix = f"candidates[{index}]"
        require(isinstance(entry, dict), f"{prefix} must be an object")
        candidate_id = entry.get("candidate_id")
        require(
            isinstance(candidate_id, str)
            and legacy.CANDIDATE_ID_PATTERN.fullmatch(candidate_id),
            f"{prefix}: invalid candidate id",
        )
        require(candidate_id not in seen, f"duplicate candidate id: {candidate_id}")
        seen.add(candidate_id)
        candidate_ids.append(candidate_id)

        require(
            entry.get("repository_disposition")
            == "external_candidate_pending_upload",
            f"{candidate_id}: repository disposition drift",
        )
        require(
            entry.get("status") in {"generated_external", "deferred"},
            f"{candidate_id}: invalid metadata-only status",
        )
        require(
            entry.get("review_status")
            in {"reference_only", "preproduction_shortlist"},
            f"{candidate_id}: invalid metadata-only review status",
        )
        require(
            bool(str(entry.get("generator_or_tool_disclosure", "")).strip()),
            f"{candidate_id}: generator/tool disclosure required",
        )
        require(entry.get("production_master") is False, f"{candidate_id}: production promoted")
        require(entry.get("runtime_asset") is False, f"{candidate_id}: runtime promoted")
        require(
            entry.get("generated_text_authoritative") is False,
            f"{candidate_id}: generated text made authoritative",
        )
        require(entry.get("candidate_path") is None, f"{candidate_id}: repository path claimed")
        require(entry.get("sha256") is None, f"{candidate_id}: repository digest claimed")

        metadata = entry.get("binary_metadata")
        require(isinstance(metadata, dict), f"{candidate_id}: binary metadata must be an object")
        require(
            metadata.get("width_px") is None
            and metadata.get("height_px") is None
            and metadata.get("bytes") is None
            and metadata.get("sha256") is None
            and metadata.get("availability")
            == "unresolved_not_disclosed_by_reviewed_source",
            f"{candidate_id}: unresolved binary metadata fabricated or cleared",
        )

        provenance = entry.get("provenance_facts")
        require(isinstance(provenance, dict), f"{candidate_id}: provenance facts must be an object")
        require(
            provenance.get("availability")
            == "unresolved_not_disclosed_by_reviewed_source",
            f"{candidate_id}: provenance availability drift",
        )
        require(
            all(value is None for key, value in provenance.items() if key != "availability"),
            f"{candidate_id}: unresolved provenance fact fabricated",
        )

        authorities = entry.get("qualified_authorities")
        require(
            isinstance(authorities, list)
            and authorities
            and all(isinstance(value, str) and value.strip() for value in authorities),
            f"{candidate_id}: qualified authorities required",
        )
        for authority in authorities:
            prefix_text = "visual asset brief "
            if authority.startswith(prefix_text):
                asset_id = authority[len(prefix_text) :]
                require(asset_id in assets, f"{candidate_id}: unknown visual asset brief {asset_id}")
            else:
                require(
                    authority == "storyboard family DH-UI-001 through DH-UI-022",
                    f"{candidate_id}: unsupported qualified authority {authority}",
                )

    boundaries = data.get("boundaries")
    require(isinstance(boundaries, dict), "external register boundaries must be an object")
    for key in (
        "production_candidate_allowed",
        "approved_allowed",
        "image_binaries_committed",
        "implementation_authorized",
        "codex_authorized",
        "normal_tale_registered",
        "ordinary_export_included",
        "pr_32_incorporated",
    ):
        require(boundaries.get(key) is False, f"external register boundary opened: {key}")
    for key in (
        "issue_7_gate_preserved",
        "issue_39_gate_preserved",
        "alpha3_developer_only",
        "lantern_house_sole_normal_default_tale",
    ):
        require(boundaries.get(key) is True, f"external register gate removed: {key}")

    return batch_id, candidate_ids


def validate_batches(paths: Sequence[Path]) -> tuple[int, int]:
    require(bool(paths), "at least one candidate batch is required")
    assets = legacy.load_asset_index()
    batch_ids: set[str] = set()
    candidate_ids: set[str] = set()
    total = 0

    for path in paths:
        data = legacy.read_batch(path)
        if data.get("register_kind") == "external_visual_candidate_register":
            batch_id, ids = validate_metadata_only_register(data, assets)
            count = len(ids)
        else:
            entries = data.get("entries")
            require(isinstance(entries, list), f"entries must be a list: {path}")
            for entry in entries:
                require(isinstance(entry, dict), f"candidate entry must be an object: {path}")
                validate_external_review_state(entry)

            normalized = normalize_for_legacy(data)
            batch_id, count = legacy.validate_batch(normalized, assets)
            ids = [entry["candidate_id"] for entry in entries]

        require(batch_id not in batch_ids, f"duplicate batch id: {batch_id}")
        batch_ids.add(batch_id)
        for candidate_id in ids:
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
