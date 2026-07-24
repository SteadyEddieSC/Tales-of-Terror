#!/usr/bin/env python3
"""Validate or export the governed Underteller voice-audition manifest."""

from __future__ import annotations

import argparse
import csv
import json
import string
import sys
from pathlib import Path
from typing import Any

DEFAULT_CATALOG_DIR = Path("docs/tales/drowned_harbor/dialogue")
DEFAULT_MANIFEST = (
    DEFAULT_CATALOG_DIR / "underteller_voice_audition_manifest_v1.json"
)
ALLOWED_PROFILES = {"spooky", "grim", "gore_and_dread"}
DISALLOWED_CLASSIFICATIONS = {"controlled_reveal_private", "diagnostic_only"}


class AuditionManifestError(ValueError):
    """Raised when the audition manifest is invalid or unsafe."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AuditionManifestError(message)


def load_json(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise AuditionManifestError(f"file not found: {path}") from exc
    except json.JSONDecodeError as exc:
        raise AuditionManifestError(f"invalid JSON in {path}: {exc}") from exc
    require(isinstance(value, dict), f"JSON root must be an object: {path}")
    return value


def discover_catalogs(catalog_dir: Path) -> list[Path]:
    catalogs = sorted(catalog_dir.glob("drowned_harbor_dialogue*.json"))
    require(bool(catalogs), f"no governed dialogue catalogs found in {catalog_dir}")
    return catalogs


def build_entry_index(catalog_paths: list[Path]) -> dict[str, dict[str, Any]]:
    index: dict[str, dict[str, Any]] = {}
    for path in catalog_paths:
        catalog = load_json(path)
        require(
            catalog.get("catalog_kind") == "governed_dialogue_preproduction",
            f"unexpected catalog kind: {path}",
        )
        entries = catalog.get("entries")
        require(isinstance(entries, list), f"entries must be a list: {path}")
        for entry in entries:
            require(isinstance(entry, dict), f"entry must be an object: {path}")
            key = entry.get("key")
            require(isinstance(key, str) and key, f"entry key missing: {path}")
            require(key not in index, f"duplicate dialogue key: {key}")
            index[key] = entry
    return index


def placeholder_names(text: str) -> set[str]:
    names: set[str] = set()
    try:
        for _, name, _, _ in string.Formatter().parse(text):
            if name is not None:
                names.add(name)
    except ValueError as exc:
        raise AuditionManifestError(f"invalid placeholder format: {exc}") from exc
    return names


def render_selection(
    selection: dict[str, Any],
    entries: dict[str, dict[str, Any]],
) -> dict[str, str]:
    selection_id = selection.get("id")
    require(
        isinstance(selection_id, str) and selection_id,
        "selection id must be non-empty text",
    )
    key = selection.get("key")
    require(isinstance(key, str) and key, f"{selection_id}: key is required")
    profile = selection.get("profile")
    require(
        profile in ALLOWED_PROFILES,
        f"{selection_id}: unsupported profile {profile}",
    )
    purpose = selection.get("purpose")
    direction = selection.get("performance_direction")
    require(
        isinstance(purpose, str) and purpose.strip(),
        f"{selection_id}: purpose is required",
    )
    require(
        isinstance(direction, str) and direction.strip(),
        f"{selection_id}: performance_direction is required",
    )
    sample_values = selection.get("sample_values", {})
    require(
        isinstance(sample_values, dict),
        f"{selection_id}: sample_values must be an object",
    )
    require(
        all(
            isinstance(name, str) and isinstance(value, str)
            for name, value in sample_values.items()
        ),
        f"{selection_id}: sample_values must contain text keys and values",
    )

    entry = entries.get(key)
    require(entry is not None, f"{selection_id}: dialogue key not found: {key}")
    require(
        entry.get("speaker") == "underteller",
        f"{selection_id}: audition selection must use the Underteller speaker",
    )
    classification = entry.get("classification")
    require(
        classification not in DISALLOWED_CLASSIFICATIONS,
        f"{selection_id}: unsafe classification for voice audition: {classification}",
    )

    variants = entry.get("variants")
    require(isinstance(variants, dict), f"{selection_id}: variants missing")
    source_text = variants.get(profile)
    require(
        isinstance(source_text, str) and source_text,
        f"{selection_id}: profile text missing",
    )
    required_values = placeholder_names(source_text)
    require(
        set(sample_values) == required_values,
        f"{selection_id}: sample-value mismatch; "
        f"required={sorted(required_values)} provided={sorted(sample_values)}",
    )
    try:
        rendered_text = source_text.format_map(sample_values)
    except (KeyError, ValueError) as exc:
        raise AuditionManifestError(
            f"{selection_id}: failed to render sample text: {exc}"
        ) from exc

    fallback = entry.get("fallback")
    require(
        isinstance(fallback, str) and fallback,
        f"{selection_id}: fallback missing",
    )
    fallback_values = placeholder_names(fallback)
    require(
        fallback_values.issubset(sample_values),
        f"{selection_id}: fallback requires missing sample values",
    )
    rendered_fallback = fallback.format_map(sample_values)

    return {
        "id": selection_id,
        "key": key,
        "profile": profile,
        "purpose": purpose.strip(),
        "performance_direction": direction.strip(),
        "text": rendered_text,
        "fallback": rendered_fallback,
        "classification": str(classification),
    }


def validate_manifest(
    manifest: dict[str, Any],
    entries: dict[str, dict[str, Any]],
) -> list[dict[str, str]]:
    require(
        manifest.get("manifest_kind")
        == "underteller_voice_audition_preproduction",
        "unexpected manifest_kind",
    )
    require(manifest.get("version") == 1, "unsupported manifest version")
    require(manifest.get("locale") == "en-US", "audition locale must be en-US")
    require(manifest.get("tale_id") == "drowned_harbor", "unexpected tale_id")
    require(
        manifest.get("voice_identity") == "underteller_provisional",
        "voice identity must remain provisional",
    )
    require(
        manifest.get("production_status") == "audition_only",
        "production_status must be audition_only",
    )

    selections = manifest.get("selections")
    require(
        isinstance(selections, list) and selections,
        "selections must be a non-empty list",
    )
    rendered = [render_selection(selection, entries) for selection in selections]
    ids = [row["id"] for row in rendered]
    require(len(ids) == len(set(ids)), "audition selection ids must be unique")
    return rendered


def export_csv(rows: list[dict[str, str]], path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fields = [
        "order",
        "id",
        "key",
        "profile",
        "purpose",
        "performance_direction",
        "classification",
        "text",
        "fallback",
    ]
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        for order, row in enumerate(rows, start=1):
            writer.writerow({"order": order, **row})


def export_markdown(
    rows: list[dict[str, str]],
    path: Path,
) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    lines = [
        "# Underteller Voice Audition — Drowned Harbor",
        "",
        "**Status:** Audition only; not final casting or production audio",
        "",
        "Use each selection to compare clarity, menace, warmth, dry amusement, "
        "pacing, and presentation-profile differentiation.",
        "",
    ]
    for order, row in enumerate(rows, start=1):
        lines.extend(
            [
                f"## {order}. {row['id']}",
                "",
                f"- **Key:** `{row['key']}`",
                f"- **Profile:** `{row['profile']}`",
                f"- **Purpose:** {row['purpose']}",
                f"- **Direction:** {row['performance_direction']}",
                "",
                f"> {row['text']}",
                "",
                f"Plain fallback: {row['fallback']}",
                "",
            ]
        )
    path.write_text("\n".join(lines), encoding="utf-8")


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--catalog-dir", type=Path, default=DEFAULT_CATALOG_DIR)
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument(
        "--output-dir",
        type=Path,
        help="Directory for generated CSV and Markdown audition files.",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="Validate only; do not write audition exports.",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    try:
        catalog_paths = discover_catalogs(args.catalog_dir)
        entries = build_entry_index(catalog_paths)
        manifest = load_json(args.manifest)
        rows = validate_manifest(manifest, entries)
        require(
            args.check or args.output_dir is not None,
            "--output-dir is required unless --check is used",
        )
        if not args.check:
            assert args.output_dir is not None
            export_csv(rows, args.output_dir / "underteller_voice_audition_v1.csv")
            export_markdown(
                rows,
                args.output_dir / "underteller_voice_audition_v1.md",
            )
    except AuditionManifestError as exc:
        print(f"Voice audition validation failed: {exc}", file=sys.stderr)
        return 1

    action = "Validated" if args.check else "Exported"
    print(f"{action} {len(rows)} Underteller audition selections")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
