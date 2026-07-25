#!/usr/bin/env python3
"""Validate design-only Drowned Harbor shared-screen storyboard manifests."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path, PurePosixPath
from typing import Any, Sequence

ROOT = Path(__file__).resolve().parents[1]
STORYBOARD_DIR = ROOT / "docs/tales/drowned_harbor/ui"
DEFAULT_PATTERN = "drowned_harbor_*_storyboards_v1.json"
TRACEABILITY_PATH = ROOT / "docs/preproduction/drowned_harbor_cross_media_traceability_v1.json"
SCHEMA_PATH = ROOT / "docs/preproduction/shared_screen_storyboard_schema_v1.json"

STORYBOARD_ID = re.compile(r"^DH-UI-[0-9]{3}$")
TRACE_ID = re.compile(r"^DH-XM-[0-9]{3}$")
STABLE_ID = re.compile(r"^[a-z][a-z0-9_]*$")
WINDOWS_ABSOLUTE = re.compile(r"^[A-Za-z]:[\\/]")

MANIFEST_FIELDS = {
    "manifest_kind", "schema_version", "tale_id", "production_status",
    "record_schema", "entries",
}
RECORD_FIELDS = {
    "storyboard_id", "title", "category", "tale_id", "stage_context",
    "layout_mode", "privacy_surface", "entry_condition", "exit_condition",
    "purpose", "required_information", "layout_regions", "legal_actions",
    "confirmation_pattern", "focus_order", "caption_policy",
    "transcript_policy", "persistent_text_policy", "seat_authority_policy",
    "state_variants", "visual_guidance", "negative_constraints",
    "source_paths", "traceability_concepts", "human_validation_questions",
    "status", "approval_boundary",
}
CATEGORIES = {
    "accessibility_settings", "ending_attribution", "lobby_and_admission",
    "private_reveal", "public_board", "public_decision", "seat_continuity",
    "system_recovery", "tale_entry", "transcript_and_replay", "transformation",
}
STAGES = {
    "reusable_system", "low_tide_arrival", "bellhouse_ledger",
    "lighthouse_council", "high_water", "last_light", "ending_resolution",
}
LAYOUT_MODES = {
    "board_first", "decision_focus", "outcome_attribution", "private_shield",
    "system_overlay", "transformation",
}
PRIVACY_SURFACES = {
    "public_shared", "neutral_shared_shield", "controlled_private_surface",
}
CONFIRMATION_PATTERNS = {
    "acknowledgement_only", "confirmed_commitment", "none", "reversible_selection",
}
STATUSES = {"brief_draft", "preproduction_ready", "review_required", "deferred"}
CAPTION_FIELDS = {
    "subtitles_supported", "closed_captions_supported", "maximum_lines",
    "target_characters_per_line", "speaker_labels_supported",
    "critical_information_outside_captions",
}
TRANSCRIPT_FIELDS = {"public_history", "replay_supported", "private_content_excluded"}
PERSISTENT_FIELDS = {
    "required", "plain_system_available", "survives_voice_interruption",
    "dismissal_rule",
}
SEAT_FIELDS = {
    "active_seat_visible", "control_source_visible", "stable_seat_preserved",
    "private_state_publicly_hidden", "authority_transfer_allowed",
}
CRITICAL_CATEGORIES = {
    "ending_attribution", "private_reveal", "public_board", "public_decision",
    "seat_continuity", "system_recovery", "transformation",
}
REQUIRED_IDS = {f"DH-UI-{index:03d}" for index in range(1, 23)}


@dataclass(frozen=True, order=True)
class Diagnostic:
    code: str
    path: str
    message: str

    def as_dict(self) -> dict[str, str]:
        return {"code": self.code, "path": self.path, "message": self.message}


class StoryboardValidationError(ValueError):
    """Raised when storyboard validation cannot continue."""


def add(items: list[Diagnostic], code: str, path: str, message: str) -> None:
    items.append(Diagnostic(code, path, message))


def read_json(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise StoryboardValidationError(f"file not found: {path}") from exc
    except json.JSONDecodeError as exc:
        raise StoryboardValidationError(f"invalid JSON in {path}: {exc}") from exc
    if not isinstance(value, dict):
        raise StoryboardValidationError(f"JSON root must be an object: {path}")
    return value


def exact_fields(value: Any, expected: set[str], path: str, items: list[Diagnostic]) -> bool:
    if not isinstance(value, dict):
        add(items, "invalid_shape", path, "expected object")
        return False
    for key in sorted(expected - set(value)):
        add(items, "missing_field", f"{path}/{key}", "required field is missing")
    for key in sorted(set(value) - expected):
        add(items, "unknown_field", f"{path}/{key}", "unknown field is rejected")
    return set(value) == expected


def require_text(value: Any, path: str, items: list[Diagnostic], minimum: int = 1) -> str:
    if not isinstance(value, str) or len(value.strip()) < minimum:
        add(items, "invalid_text", path, f"must contain at least {minimum} characters")
        return ""
    return value.strip()


def require_list(value: Any, path: str, items: list[Diagnostic], minimum: int = 1) -> list[str]:
    if not isinstance(value, list) or len(value) < minimum:
        add(items, "invalid_list", path, f"must contain at least {minimum} item(s)")
        return []
    if not all(isinstance(item, str) and item.strip() for item in value):
        add(items, "invalid_list", path, "all items must be non-empty text")
        return []
    if len(value) != len(set(value)):
        add(items, "duplicate_value", path, "items must be unique")
    return list(value)


def repository_path(value: Any, path: str, items: list[Diagnostic]) -> Path | None:
    if not isinstance(value, str) or not value or WINDOWS_ABSOLUTE.match(value):
        add(items, "unsafe_path", path, "must be a repository-relative docs path")
        return None
    pure = PurePosixPath(value.replace("\\", "/"))
    if pure.is_absolute() or ".." in pure.parts or not pure.parts or pure.parts[0] != "docs":
        add(items, "unsafe_path", path, "must remain below docs without traversal")
        return None
    resolved = ROOT / pure
    if not resolved.is_file():
        add(items, "missing_source", path, f"source file does not exist: {value}")
        return None
    return resolved


def traceability_ids(items: list[Diagnostic]) -> set[str]:
    try:
        data = read_json(TRACEABILITY_PATH)
    except StoryboardValidationError as exc:
        add(items, "missing_traceability", "/", str(exc))
        return set()
    entries = data.get("entries")
    if not isinstance(entries, list):
        add(items, "missing_traceability", "/", "traceability entries are unavailable")
        return set()
    return {
        record["concept_id"]
        for record in entries
        if isinstance(record, dict) and isinstance(record.get("concept_id"), str)
    }


def validate_record(record: Any, path: str, known_trace: set[str], items: list[Diagnostic]) -> str | None:
    if not exact_fields(record, RECORD_FIELDS, path, items):
        return None

    storyboard_id = require_text(record["storyboard_id"], f"{path}/storyboard_id", items)
    if not STORYBOARD_ID.fullmatch(storyboard_id):
        add(items, "invalid_id", f"{path}/storyboard_id", "must match DH-UI-NNN")
    require_text(record["title"], f"{path}/title", items, 3)

    category = record["category"]
    if category not in CATEGORIES:
        add(items, "invalid_category", f"{path}/category", "unsupported category")
    if record["tale_id"] != "drowned_harbor":
        add(items, "wrong_tale", f"{path}/tale_id", "must be drowned_harbor")

    for stage in require_list(record["stage_context"], f"{path}/stage_context", items):
        if stage not in STAGES:
            add(items, "invalid_stage", f"{path}/stage_context", f"unknown stage: {stage}")

    layout = record["layout_mode"]
    privacy = record["privacy_surface"]
    if layout not in LAYOUT_MODES:
        add(items, "invalid_layout", f"{path}/layout_mode", "unsupported layout mode")
    if privacy not in PRIVACY_SURFACES:
        add(items, "invalid_privacy", f"{path}/privacy_surface", "unsupported privacy surface")
    if category == "private_reveal":
        if layout != "private_shield" or privacy != "controlled_private_surface":
            add(items, "privacy_leak", path, "private reveal requires a controlled private shield")
    elif privacy == "controlled_private_surface":
        add(items, "invalid_privacy", path, "controlled private surfaces are reserved for private reveals")

    require_text(record["entry_condition"], f"{path}/entry_condition", items, 10)
    require_text(record["exit_condition"], f"{path}/exit_condition", items, 10)
    require_text(record["purpose"], f"{path}/purpose", items, 20)
    require_list(record["required_information"], f"{path}/required_information", items, 2)
    regions = require_list(record["layout_regions"], f"{path}/layout_regions", items, 2)
    if layout == "private_shield" and "private_shield_full_screen" not in regions:
        add(items, "privacy_leak", f"{path}/layout_regions", "private shield region is required")

    actions = require_list(record["legal_actions"], f"{path}/legal_actions", items)
    if any(not STABLE_ID.fullmatch(action) for action in actions):
        add(items, "invalid_action", f"{path}/legal_actions", "legal actions require stable IDs")
    if actions != sorted(actions):
        add(items, "unstable_order", f"{path}/legal_actions", "legal actions must be sorted")

    confirmation = record["confirmation_pattern"]
    if confirmation not in CONFIRMATION_PATTERNS:
        add(items, "invalid_confirmation", f"{path}/confirmation_pattern", "unsupported pattern")
    if category in {"public_decision", "private_reveal"} and confirmation == "none":
        add(items, "confirmation_boundary", f"{path}/confirmation_pattern", "decision requires confirmation")
    require_list(record["focus_order"], f"{path}/focus_order", items, 2)

    caption = record["caption_policy"]
    if exact_fields(caption, CAPTION_FIELDS, f"{path}/caption_policy", items):
        required_true = {
            "subtitles_supported", "closed_captions_supported",
            "speaker_labels_supported", "critical_information_outside_captions",
        }
        if any(caption[key] is not True for key in required_true):
            add(items, "caption_contract", f"{path}/caption_policy", "caption support fields must remain true")
        if caption["maximum_lines"] != 2:
            add(items, "caption_contract", f"{path}/caption_policy/maximum_lines", "must remain two lines")
        target = caption["target_characters_per_line"]
        if not isinstance(target, int) or not 20 <= target <= 42:
            add(items, "caption_contract", f"{path}/caption_policy/target_characters_per_line", "must be 20-42")

    transcript = record["transcript_policy"]
    if exact_fields(transcript, TRANSCRIPT_FIELDS, f"{path}/transcript_policy", items):
        if transcript["private_content_excluded"] is not True:
            add(items, "privacy_leak", f"{path}/transcript_policy", "private content must remain excluded")
        if privacy == "controlled_private_surface" and (
            transcript["public_history"] is not False or transcript["replay_supported"] is not False
        ):
            add(items, "privacy_leak", f"{path}/transcript_policy", "private surfaces cannot enter public history or replay")

    persistent = record["persistent_text_policy"]
    if exact_fields(persistent, PERSISTENT_FIELDS, f"{path}/persistent_text_policy", items):
        if persistent["plain_system_available"] is not True or persistent["survives_voice_interruption"] is not True:
            add(items, "persistent_text", f"{path}/persistent_text_policy", "plain-system text must survive voice interruption")
        if category in CRITICAL_CATEGORIES and persistent["required"] is not True:
            add(items, "persistent_text", f"{path}/persistent_text_policy/required", "critical storyboard requires persistent text")
        if persistent["dismissal_rule"] not in {
            "state_change_only", "state_change_or_user",
            "acknowledgement_then_state_change", "user_or_transcript",
        }:
            add(items, "persistent_text", f"{path}/persistent_text_policy/dismissal_rule", "unsupported dismissal rule")

    seat = record["seat_authority_policy"]
    if exact_fields(seat, SEAT_FIELDS, f"{path}/seat_authority_policy", items):
        if seat["stable_seat_preserved"] is not True:
            add(items, "seat_continuity", f"{path}/seat_authority_policy/stable_seat_preserved", "stable seat must be preserved")
        if seat["private_state_publicly_hidden"] is not True:
            add(items, "privacy_leak", f"{path}/seat_authority_policy/private_state_publicly_hidden", "private state must remain hidden")
        if category == "seat_continuity" and privacy == "public_shared":
            if seat["active_seat_visible"] is not True or seat["control_source_visible"] is not True:
                add(items, "seat_continuity", f"{path}/seat_authority_policy", "public continuity screens require seat and control-source visibility")
        if storyboard_id == "DH-UI-007" and seat["authority_transfer_allowed"] is not False:
            add(items, "privacy_leak", f"{path}/seat_authority_policy/authority_transfer_allowed", "bargain review cannot transfer authority")
        if storyboard_id == "DH-UI-016" and seat["authority_transfer_allowed"] is not True:
            add(items, "seat_continuity", f"{path}/seat_authority_policy/authority_transfer_allowed", "inherited-state acknowledgement must permit the authorized transfer")

    require_list(record["state_variants"], f"{path}/state_variants", items)
    require_list(record["visual_guidance"], f"{path}/visual_guidance", items, 2)
    require_list(record["negative_constraints"], f"{path}/negative_constraints", items, 2)

    for index, source in enumerate(require_list(record["source_paths"], f"{path}/source_paths", items, 2)):
        repository_path(source, f"{path}/source_paths/{index}", items)

    concepts = require_list(record["traceability_concepts"], f"{path}/traceability_concepts", items, 0)
    if concepts != sorted(concepts):
        add(items, "unstable_order", f"{path}/traceability_concepts", "traceability IDs must be sorted")
    for concept in concepts:
        if not TRACE_ID.fullmatch(concept) or concept not in known_trace:
            add(items, "unknown_traceability", f"{path}/traceability_concepts", f"unknown concept: {concept}")

    require_list(record["human_validation_questions"], f"{path}/human_validation_questions", items, 2)
    if record["status"] not in STATUSES:
        add(items, "invalid_status", f"{path}/status", "unsupported preproduction status")
    require_text(record["approval_boundary"], f"{path}/approval_boundary", items, 40)
    return storyboard_id


def discover_manifests() -> tuple[Path, ...]:
    paths = tuple(sorted(STORYBOARD_DIR.glob(DEFAULT_PATTERN)))
    if not paths:
        raise StoryboardValidationError("no storyboard manifests found")
    return paths


def validate_manifests(paths: Sequence[Path]) -> tuple[list[Diagnostic], dict[str, Any]]:
    items: list[Diagnostic] = []
    known_trace = traceability_ids(items)
    ids: list[str] = []
    categories: set[str] = set()
    records: list[dict[str, Any]] = []

    for manifest_index, manifest_path in enumerate(paths):
        logical = f"/manifests/{manifest_index}"
        try:
            manifest = read_json(manifest_path)
        except StoryboardValidationError as exc:
            add(items, "malformed_manifest", logical, str(exc))
            continue
        if not exact_fields(manifest, MANIFEST_FIELDS, logical, items):
            continue
        if manifest["manifest_kind"] != "shared_screen_storyboards_preproduction":
            add(items, "wrong_manifest", f"{logical}/manifest_kind", "unsupported manifest kind")
        if manifest["schema_version"] != 1 or manifest["tale_id"] != "drowned_harbor":
            add(items, "wrong_manifest", logical, "must be Drowned Harbor schema v1")
        if manifest["production_status"] != "design_only":
            add(items, "production_boundary", f"{logical}/production_status", "must remain design_only")
        schema = repository_path(manifest["record_schema"], f"{logical}/record_schema", items)
        if schema and schema != SCHEMA_PATH:
            add(items, "wrong_schema", f"{logical}/record_schema", "must use shared-screen storyboard schema v1")
        entries = manifest["entries"]
        if not isinstance(entries, list) or not entries:
            add(items, "missing_entries", f"{logical}/entries", "entries are required")
            continue
        for entry_index, entry in enumerate(entries):
            entry_path = f"{logical}/entries/{entry_index}"
            storyboard_id = validate_record(entry, entry_path, known_trace, items)
            if storyboard_id:
                ids.append(storyboard_id)
            if isinstance(entry, dict):
                records.append(entry)
                category = entry.get("category")
                if isinstance(category, str):
                    categories.add(category)

    if len(ids) != len(set(ids)):
        add(items, "duplicate_id", "/", "storyboard IDs must be globally unique")
    actual_ids = set(ids)
    if actual_ids != REQUIRED_IDS:
        missing = sorted(REQUIRED_IDS - actual_ids)
        extra = sorted(actual_ids - REQUIRED_IDS)
        add(items, "incomplete_inventory", "/", f"required 22-screen inventory differs; missing={missing}, extra={extra}")
    if categories != CATEGORIES:
        add(items, "incomplete_category", "/", f"category coverage differs; missing={sorted(CATEGORIES - categories)}")

    by_id = {record.get("storyboard_id"): record for record in records if isinstance(record.get("storyboard_id"), str)}
    high_water_transition = by_id.get("DH-UI-008", {})
    high_water_board = by_id.get("DH-UI-009", {})
    if (
        high_water_transition.get("layout_mode") != "transformation"
        or high_water_board.get("layout_mode") != "board_first"
        or "high_water" not in high_water_transition.get("stage_context", [])
        or high_water_board.get("stage_context") != ["high_water"]
    ):
        add(items, "high_water_pair", "/", "High Water requires a transformation screen followed by a transformed board screen")

    canonical_records = sorted(records, key=lambda item: str(item.get("storyboard_id", "")))
    identity = hashlib.sha256(
        json.dumps(canonical_records, ensure_ascii=True, separators=(",", ":"), sort_keys=True).encode("utf-8")
    ).hexdigest()
    summary = {
        "manifest_count": len(paths),
        "storyboard_count": len(ids),
        "categories": sorted(categories),
        "identity": identity,
    }
    return sorted(set(items)), summary


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--identity", action="store_true", help="print the canonical storyboard identity")
    parser.add_argument("paths", nargs="*", type=Path)
    args = parser.parse_args(argv)
    try:
        paths = tuple(args.paths) or discover_manifests()
        diagnostics, summary = validate_manifests(paths)
    except StoryboardValidationError as exc:
        print(str(exc), file=sys.stderr)
        return 2
    if diagnostics:
        for diagnostic in diagnostics:
            print(json.dumps(diagnostic.as_dict(), sort_keys=True), file=sys.stderr)
        return 1
    print(f"Validated {summary['storyboard_count']} shared-screen storyboard records")
    if args.identity:
        print(summary["identity"])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
