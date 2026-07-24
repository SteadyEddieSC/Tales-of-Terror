#!/usr/bin/env python3
"""Validate governed Drowned Harbor preproduction visual asset manifests."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any, Sequence

DEFAULT_VISUAL_DIR = Path("docs/tales/drowned_harbor/visual")
DEFAULT_MANIFEST = DEFAULT_VISUAL_DIR / "drowned_harbor_visual_asset_briefs_v1.json"
DEFAULT_MANIFEST_PATTERN = "drowned_harbor_visual_asset_briefs*_v1.json"

ID_PATTERN = re.compile(r"^DH-(ENV|PROP|CHAR|FORM|UI|ICON|KEY)-[0-9]{3}$")
PREFIX_CATEGORY = {
    "ENV": "environment",
    "PROP": "prop",
    "CHAR": "character",
    "FORM": "continuation_form",
    "UI": "ui",
    "ICON": "icon_family",
    "KEY": "key_art",
}
ALLOWED_TIERS = {"A", "B", "C", "D"}
ALLOWED_PRIORITIES = {"P0", "P1", "P2", "P3"}
ALLOWED_STATUSES = {
    "brief_draft",
    "brief_reviewed",
    "generation_ready",
    "candidate_generated",
    "candidate_reviewed",
    "production_candidate",
    "approved",
    "rejected",
    "deferred",
}
ALLOWED_PROFILES = {"spooky", "grim", "gore_and_dread", "profile_neutral"}
ALLOWED_SOURCE_KINDS = {
    "original_human",
    "original_ai_assisted",
    "commissioned",
    "licensed_transformed",
    "licensed_supporting",
    "placeholder",
}
DISALLOWED_PROMPT_PHRASES = {
    "in the style of",
    "exactly like",
    "copy the style",
    "replicate the style",
}
REQUIRED_ENTRY_FIELDS = {
    "asset_id",
    "title",
    "category",
    "signature_asset",
    "originality_tier",
    "priority",
    "status",
    "intended_use",
    "deliverables",
    "visual_requirements",
    "negative_constraints",
    "presentation_profiles",
    "dependencies",
    "generator_guidance",
    "provenance_policy",
    "approval_boundary",
}


class VisualAssetValidationError(ValueError):
    """Raised when a visual manifest violates preproduction policy."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise VisualAssetValidationError(message)


def nonempty_text(value: Any, field: str) -> str:
    require(
        isinstance(value, str) and bool(value.strip()),
        f"{field} must be non-empty text",
    )
    return value


def nonempty_unique_text_list(value: Any, field: str) -> list[str]:
    require(isinstance(value, list) and value, f"{field} must be a non-empty list")
    require(
        all(isinstance(item, str) and bool(item.strip()) for item in value),
        f"{field} must contain non-empty text",
    )
    require(len(value) == len(set(value)), f"{field} must not contain duplicates")
    return value


def validate_entry(entry: Any, index: int) -> None:
    prefix = f"entries[{index}]"
    require(isinstance(entry, dict), f"{prefix} must be an object")
    missing = REQUIRED_ENTRY_FIELDS - entry.keys()
    require(not missing, f"{prefix} missing fields: {sorted(missing)}")

    asset_id = nonempty_text(entry["asset_id"], f"{prefix}.asset_id")
    match = ID_PATTERN.fullmatch(asset_id)
    require(match is not None, f"{asset_id}: invalid asset id")
    category = entry["category"]
    require(
        category == PREFIX_CATEGORY[match.group(1)],
        f"{asset_id}: category does not match id prefix",
    )

    nonempty_text(entry["title"], f"{asset_id}.title")
    require(
        isinstance(entry["signature_asset"], bool),
        f"{asset_id}: signature_asset must be boolean",
    )
    tier = entry["originality_tier"]
    require(tier in ALLOWED_TIERS, f"{asset_id}: invalid originality tier")
    if entry["signature_asset"]:
        require(
            tier == "A",
            f"{asset_id}: signature assets must remain Tier A in preproduction",
        )

    require(entry["priority"] in ALLOWED_PRIORITIES, f"{asset_id}: invalid priority")
    status = entry["status"]
    require(status in ALLOWED_STATUSES, f"{asset_id}: invalid status")
    require(
        status not in {"production_candidate", "approved"},
        f"{asset_id}: design-only manifest may not approve production assets",
    )

    nonempty_text(entry["intended_use"], f"{asset_id}.intended_use")
    nonempty_unique_text_list(entry["deliverables"], f"{asset_id}.deliverables")
    nonempty_unique_text_list(
        entry["visual_requirements"], f"{asset_id}.visual_requirements"
    )
    nonempty_unique_text_list(
        entry["negative_constraints"], f"{asset_id}.negative_constraints"
    )

    profiles = nonempty_unique_text_list(
        entry["presentation_profiles"], f"{asset_id}.presentation_profiles"
    )
    require(
        set(profiles).issubset(ALLOWED_PROFILES),
        f"{asset_id}: invalid presentation profile",
    )

    dependencies = entry["dependencies"]
    require(
        isinstance(dependencies, list),
        f"{asset_id}.dependencies must be a list",
    )
    require(
        len(dependencies) == len(set(dependencies)),
        f"{asset_id}: duplicate dependencies",
    )
    for dependency in dependencies:
        require(
            isinstance(dependency, str) and ID_PATTERN.fullmatch(dependency),
            f"{asset_id}: invalid dependency {dependency}",
        )
        require(dependency != asset_id, f"{asset_id}: self dependency is prohibited")

    guidance = entry["generator_guidance"]
    require(
        isinstance(guidance, dict),
        f"{asset_id}: generator_guidance must be an object",
    )
    expected_guidance = {
        "prompt",
        "negative_prompt",
        "aspect_ratio",
        "camera_or_view",
        "consistency_anchor",
    }
    require(
        set(guidance) == expected_guidance,
        f"{asset_id}: generator_guidance fields do not match contract",
    )
    prompt = nonempty_text(
        guidance["prompt"], f"{asset_id}.generator_guidance.prompt"
    )
    negative_prompt = nonempty_text(
        guidance["negative_prompt"],
        f"{asset_id}.generator_guidance.negative_prompt",
    )
    require(
        re.fullmatch(r"[0-9]+:[0-9]+", guidance["aspect_ratio"]) is not None,
        f"{asset_id}: invalid aspect ratio",
    )
    nonempty_text(
        guidance["camera_or_view"],
        f"{asset_id}.generator_guidance.camera_or_view",
    )
    nonempty_text(
        guidance["consistency_anchor"],
        f"{asset_id}.generator_guidance.consistency_anchor",
    )
    lowered_prompt = prompt.lower()
    for phrase in DISALLOWED_PROMPT_PHRASES:
        require(
            phrase not in lowered_prompt,
            f"{asset_id}: disallowed imitation phrase in prompt: {phrase}",
        )
    require(len(negative_prompt) >= 20, f"{asset_id}: negative prompt is too weak")

    provenance = entry["provenance_policy"]
    require(
        isinstance(provenance, dict),
        f"{asset_id}: provenance_policy must be an object",
    )
    expected_provenance = {
        "allowed_source_kinds",
        "raw_public_distribution",
        "third_party_ai_input",
        "required_record",
    }
    require(
        set(provenance) == expected_provenance,
        f"{asset_id}: provenance_policy fields do not match contract",
    )
    source_kinds = nonempty_unique_text_list(
        provenance["allowed_source_kinds"],
        f"{asset_id}.allowed_source_kinds",
    )
    require(
        set(source_kinds).issubset(ALLOWED_SOURCE_KINDS),
        f"{asset_id}: invalid source kind",
    )
    require(
        provenance["raw_public_distribution"]
        in {"allowed", "prohibited", "license_dependent"},
        f"{asset_id}: invalid raw distribution rule",
    )
    require(
        provenance["third_party_ai_input"]
        in {"prohibited", "explicit_permission_required", "not_applicable"},
        f"{asset_id}: invalid AI-input rule",
    )
    nonempty_unique_text_list(
        provenance["required_record"], f"{asset_id}.required_record"
    )

    if entry["signature_asset"]:
        require(
            "licensed_supporting" not in source_kinds,
            f"{asset_id}: signature asset may not be licensed-supporting content",
        )
        require(
            "placeholder" not in source_kinds,
            f"{asset_id}: signature asset may not be placeholder content",
        )
    if "licensed_transformed" in source_kinds:
        require(
            provenance["third_party_ai_input"] != "not_applicable",
            f"{asset_id}: licensed transformed sources require an explicit "
            "AI-input rule",
        )
        require(
            provenance["raw_public_distribution"] == "license_dependent",
            f"{asset_id}: licensed transformed sources require "
            "license-dependent public distribution",
        )

    nonempty_text(entry["approval_boundary"], f"{asset_id}.approval_boundary")


def validate_dependency_graph(entries: list[dict[str, Any]]) -> None:
    by_id = {entry["asset_id"]: entry for entry in entries}
    for entry in entries:
        for dependency in entry["dependencies"]:
            require(
                dependency in by_id,
                f"{entry['asset_id']}: missing dependency {dependency}",
            )

    visiting: set[str] = set()
    visited: set[str] = set()

    def visit(asset_id: str) -> None:
        if asset_id in visited:
            return
        require(
            asset_id not in visiting,
            f"dependency cycle detected at {asset_id}",
        )
        visiting.add(asset_id)
        for dependency in by_id[asset_id]["dependencies"]:
            visit(dependency)
        visiting.remove(asset_id)
        visited.add(asset_id)

    for asset_id in by_id:
        visit(asset_id)


def validate_manifest_structure(data: Any) -> list[dict[str, Any]]:
    require(isinstance(data, dict), "manifest root must be an object")
    require(
        data.get("manifest_kind") == "visual_asset_briefs_preproduction",
        "unexpected manifest_kind",
    )
    require(data.get("schema_version") == 1, "unsupported schema_version")
    require(data.get("tale_id") == "drowned_harbor", "unexpected tale_id")
    require(
        data.get("production_status") == "design_only",
        "production_status must remain design_only",
    )

    entries = data.get("entries")
    require(
        isinstance(entries, list) and entries,
        "entries must be a non-empty list",
    )
    local_ids: set[str] = set()
    for index, entry in enumerate(entries):
        validate_entry(entry, index)
        asset_id = entry["asset_id"]
        require(asset_id not in local_ids, f"duplicate asset id: {asset_id}")
        local_ids.add(asset_id)
    return entries


def validate_manifest(data: Any) -> int:
    entries = validate_manifest_structure(data)
    validate_dependency_graph(entries)
    return len(entries)


def read_manifest(path: Path) -> dict[str, Any]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise VisualAssetValidationError(f"manifest not found: {path}") from exc
    except json.JSONDecodeError as exc:
        raise VisualAssetValidationError(f"invalid JSON in {path}: {exc}") from exc
    require(isinstance(data, dict), f"manifest root must be an object: {path}")
    return data


def load_and_validate(path: Path) -> dict[str, Any]:
    data = read_manifest(path)
    validate_manifest(data)
    return data


def discover_default_manifests() -> tuple[Path, ...]:
    paths = tuple(sorted(DEFAULT_VISUAL_DIR.glob(DEFAULT_MANIFEST_PATTERN)))
    require(bool(paths), "no governed visual asset manifests found")
    return paths


def validate_manifests(paths: Sequence[Path]) -> tuple[int, int]:
    require(bool(paths), "at least one visual asset manifest is required")

    all_entries: list[dict[str, Any]] = []
    owners: dict[str, Path] = {}
    for path in paths:
        data = read_manifest(path)
        entries = validate_manifest_structure(data)
        for entry in entries:
            asset_id = entry["asset_id"]
            prior = owners.get(asset_id)
            require(
                prior is None,
                f"duplicate asset id across manifests: {asset_id} "
                f"({prior} and {path})",
            )
            owners[asset_id] = path
            all_entries.append(entry)

    validate_dependency_graph(all_entries)
    return len(paths), len(all_entries)


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "manifests",
        nargs="*",
        type=Path,
        help="One or more governed visual asset manifest paths.",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    try:
        paths = tuple(args.manifests) if args.manifests else discover_default_manifests()
        manifest_count, asset_count = validate_manifests(paths)
    except VisualAssetValidationError as exc:
        print(f"Visual asset validation failed: {exc}", file=sys.stderr)
        return 1
    print(
        f"Validated {asset_count} governed visual asset briefs "
        f"across {manifest_count} manifest(s)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
