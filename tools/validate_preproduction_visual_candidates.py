#!/usr/bin/env python3
"""Validate governed Drowned Harbor preproduction visual candidate batches."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any, Sequence

from validate_preproduction_visual_assets import (
    DEFAULT_VISUAL_DIR,
    VisualAssetValidationError,
    discover_default_manifests,
    read_manifest,
    validate_manifests,
)

DEFAULT_BATCH_PATTERN = "drowned_harbor_concept_batch_*.json"
CANDIDATE_ID_PATTERN = re.compile(r"^DH-CAND-[0-9]{3}-[A-Z]$")
BATCH_ID_PATTERN = re.compile(r"^DH-CB-[0-9]{3}$")
ASPECT_PATTERN = re.compile(r"^[0-9]+:[0-9]+$")
SHA256_PATTERN = re.compile(r"^[a-f0-9]{64}$")
DISALLOWED_PROMPT_PHRASES = {
    "in the style of",
    "exactly like",
    "copy the style",
    "replicate the style",
}
ALLOWED_GENERATORS = {"chatgpt", "gemini", "human", "commissioned"}
ALLOWED_STATUSES = {
    "planned",
    "generated_external",
    "uploaded_unreviewed",
    "reviewed",
    "rejected",
    "deferred",
}
ALLOWED_REVIEW_STATUSES = {
    "unreviewed",
    "needs_revision",
    "reference_only",
    "rejected",
    "preproduction_shortlist",
}
ALLOWED_DISPOSITIONS = {
    "external_candidate_pending_upload",
    "public_candidate_path_recorded",
    "rejected_not_retained",
}
REQUIRED_FIELDS = {
    "candidate_id",
    "asset_id",
    "generator",
    "model_or_tool",
    "status",
    "source_kind",
    "prompt_source",
    "prompt",
    "negative_prompt",
    "aspect_ratio",
    "input_assets",
    "third_party_inputs",
    "expected_outputs",
    "repository_disposition",
    "review_status",
    "approval_boundary",
}
OPTIONAL_FIELDS = {"candidate_path", "sha256"}


class VisualCandidateValidationError(ValueError):
    """Raised when a candidate batch violates preproduction policy."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise VisualCandidateValidationError(message)


def nonempty_text(value: Any, field: str) -> str:
    require(
        isinstance(value, str) and bool(value.strip()),
        f"{field} must be non-empty text",
    )
    return value


def load_asset_index() -> dict[str, dict[str, Any]]:
    manifest_paths = discover_default_manifests()
    try:
        validate_manifests(manifest_paths)
    except VisualAssetValidationError as exc:
        raise VisualCandidateValidationError(
            f"visual asset manifests are invalid: {exc}"
        ) from exc

    index: dict[str, dict[str, Any]] = {}
    for path in manifest_paths:
        data = read_manifest(path)
        for entry in data["entries"]:
            index[entry["asset_id"]] = entry
    return index


def read_batch(path: Path) -> dict[str, Any]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise VisualCandidateValidationError(f"batch not found: {path}") from exc
    except json.JSONDecodeError as exc:
        raise VisualCandidateValidationError(
            f"invalid JSON in {path}: {exc}"
        ) from exc
    require(isinstance(data, dict), f"batch root must be an object: {path}")
    return data


def validate_candidate(
    entry: Any,
    index: int,
    assets: dict[str, dict[str, Any]],
) -> str:
    prefix = f"entries[{index}]"
    require(isinstance(entry, dict), f"{prefix} must be an object")
    missing = REQUIRED_FIELDS - entry.keys()
    require(not missing, f"{prefix} missing fields: {sorted(missing)}")
    unexpected = set(entry) - REQUIRED_FIELDS - OPTIONAL_FIELDS
    require(not unexpected, f"{prefix} has unexpected fields: {sorted(unexpected)}")

    candidate_id = nonempty_text(entry["candidate_id"], f"{prefix}.candidate_id")
    require(
        CANDIDATE_ID_PATTERN.fullmatch(candidate_id) is not None,
        f"{candidate_id}: invalid candidate id",
    )
    asset_id = nonempty_text(entry["asset_id"], f"{candidate_id}.asset_id")
    require(asset_id in assets, f"{candidate_id}: unknown asset id {asset_id}")
    asset = assets[asset_id]

    generator = entry["generator"]
    require(generator in ALLOWED_GENERATORS, f"{candidate_id}: invalid generator")
    nonempty_text(entry["model_or_tool"], f"{candidate_id}.model_or_tool")

    status = entry["status"]
    require(status in ALLOWED_STATUSES, f"{candidate_id}: invalid status")
    source_kind = entry["source_kind"]
    expected_source = {
        "chatgpt": "original_ai_assisted",
        "gemini": "original_ai_assisted",
        "human": "original_human",
        "commissioned": "commissioned",
    }[generator]
    require(
        source_kind == expected_source,
        f"{candidate_id}: source_kind does not match generator",
    )
    require(
        source_kind in asset["provenance_policy"]["allowed_source_kinds"],
        f"{candidate_id}: source kind is not allowed by asset brief",
    )

    prompt_source = entry["prompt_source"]
    require(
        prompt_source in {"governed_brief", "governed_revision"},
        f"{candidate_id}: invalid prompt_source",
    )
    prompt = nonempty_text(entry["prompt"], f"{candidate_id}.prompt")
    negative_prompt = nonempty_text(
        entry["negative_prompt"], f"{candidate_id}.negative_prompt"
    )
    require(
        len(negative_prompt) >= 20,
        f"{candidate_id}: negative prompt is too weak",
    )
    lowered = prompt.lower()
    for phrase in DISALLOWED_PROMPT_PHRASES:
        require(
            phrase not in lowered,
            f"{candidate_id}: disallowed imitation phrase: {phrase}",
        )

    aspect_ratio = entry["aspect_ratio"]
    require(
        isinstance(aspect_ratio, str)
        and ASPECT_PATTERN.fullmatch(aspect_ratio) is not None,
        f"{candidate_id}: invalid aspect ratio",
    )

    guidance = asset["generator_guidance"]
    if prompt_source == "governed_brief":
        require(
            prompt == guidance["prompt"],
            f"{candidate_id}: prompt differs from governed brief",
        )
        require(
            negative_prompt == guidance["negative_prompt"],
            f"{candidate_id}: negative prompt differs from governed brief",
        )
        require(
            aspect_ratio == guidance["aspect_ratio"],
            f"{candidate_id}: aspect ratio differs from governed brief",
        )

    input_assets = entry["input_assets"]
    require(isinstance(input_assets, list), f"{candidate_id}: input_assets must be a list")
    require(
        all(isinstance(item, str) and item.strip() for item in input_assets),
        f"{candidate_id}: input_assets must contain non-empty paths",
    )
    require(
        len(input_assets) == len(set(input_assets)),
        f"{candidate_id}: duplicate input assets",
    )
    third_party_inputs = entry["third_party_inputs"]
    require(
        isinstance(third_party_inputs, bool),
        f"{candidate_id}: third_party_inputs must be boolean",
    )
    if third_party_inputs:
        require(bool(input_assets), f"{candidate_id}: third-party inputs must be listed")
        require(
            asset["provenance_policy"]["third_party_ai_input"]
            == "explicit_permission_required",
            f"{candidate_id}: asset brief does not permit third-party AI inputs",
        )
    else:
        require(
            not input_assets,
            f"{candidate_id}: input assets require an explicit third-party-input record",
        )

    expected_outputs = entry["expected_outputs"]
    require(
        isinstance(expected_outputs, int) and 1 <= expected_outputs <= 8,
        f"{candidate_id}: expected_outputs must be from 1 to 8",
    )
    disposition = entry["repository_disposition"]
    require(
        disposition in ALLOWED_DISPOSITIONS,
        f"{candidate_id}: invalid repository disposition",
    )
    review_status = entry["review_status"]
    require(
        review_status in ALLOWED_REVIEW_STATUSES,
        f"{candidate_id}: invalid review status",
    )

    candidate_path = entry.get("candidate_path")
    digest = entry.get("sha256")
    if disposition == "external_candidate_pending_upload":
        require(
            candidate_path is None and digest is None,
            f"{candidate_id}: pending external candidates may not claim a path or digest",
        )
        require(
            status in {"planned", "generated_external", "deferred"},
            f"{candidate_id}: pending external disposition conflicts with status",
        )
        require(
            review_status == "unreviewed",
            f"{candidate_id}: pending external candidate must remain unreviewed",
        )
    elif disposition == "public_candidate_path_recorded":
        nonempty_text(candidate_path, f"{candidate_id}.candidate_path")
        require(
            isinstance(digest, str) and SHA256_PATTERN.fullmatch(digest),
            f"{candidate_id}: recorded public candidate requires a sha256 digest",
        )
        require(
            status in {"uploaded_unreviewed", "reviewed"},
            f"{candidate_id}: recorded path conflicts with status",
        )
    else:
        require(status == "rejected", f"{candidate_id}: rejected disposition requires rejected status")
        require(
            review_status == "rejected",
            f"{candidate_id}: rejected disposition requires rejected review status",
        )

    nonempty_text(entry["approval_boundary"], f"{candidate_id}.approval_boundary")
    return candidate_id


def validate_batch(
    data: Any,
    assets: dict[str, dict[str, Any]],
) -> tuple[str, int]:
    require(isinstance(data, dict), "batch root must be an object")
    require(
        data.get("manifest_kind") == "visual_candidate_batch_preproduction",
        "unexpected manifest_kind",
    )
    require(data.get("schema_version") == 1, "unsupported schema_version")
    batch_id = data.get("batch_id")
    require(
        isinstance(batch_id, str) and BATCH_ID_PATTERN.fullmatch(batch_id),
        "invalid batch_id",
    )
    require(data.get("tale_id") == "drowned_harbor", "unexpected tale_id")
    require(
        data.get("production_status") == "concept_only",
        "production_status must remain concept_only",
    )
    created_date = data.get("created_date")
    require(
        isinstance(created_date, str)
        and re.fullmatch(r"[0-9]{4}-[0-9]{2}-[0-9]{2}", created_date),
        "created_date must use YYYY-MM-DD",
    )
    entries = data.get("entries")
    require(
        isinstance(entries, list) and entries,
        "entries must be a non-empty list",
    )
    ids: set[str] = set()
    for index, entry in enumerate(entries):
        candidate_id = validate_candidate(entry, index, assets)
        require(candidate_id not in ids, f"duplicate candidate id: {candidate_id}")
        ids.add(candidate_id)
    return batch_id, len(entries)


def discover_batches() -> tuple[Path, ...]:
    paths = tuple(sorted(DEFAULT_VISUAL_DIR.glob(DEFAULT_BATCH_PATTERN)))
    require(bool(paths), "no governed visual candidate batches found")
    return paths


def validate_batches(paths: Sequence[Path]) -> tuple[int, int]:
    require(bool(paths), "at least one candidate batch is required")
    assets = load_asset_index()
    batch_ids: set[str] = set()
    candidate_ids: set[str] = set()
    total = 0
    for path in paths:
        data = read_batch(path)
        batch_id, count = validate_batch(data, assets)
        require(batch_id not in batch_ids, f"duplicate batch id: {batch_id}")
        batch_ids.add(batch_id)
        for entry in data["entries"]:
            candidate_id = entry["candidate_id"]
            require(
                candidate_id not in candidate_ids,
                f"duplicate candidate id across batches: {candidate_id}",
            )
            candidate_ids.add(candidate_id)
        total += count
    return len(paths), total


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "batches",
        nargs="*",
        type=Path,
        help="One or more governed candidate batch paths.",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    try:
        paths = tuple(args.batches) if args.batches else discover_batches()
        batch_count, candidate_count = validate_batches(paths)
    except VisualCandidateValidationError as exc:
        print(f"Visual candidate validation failed: {exc}", file=sys.stderr)
        return 1
    print(
        f"Validated {candidate_count} visual candidates "
        f"across {batch_count} batch(es)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
