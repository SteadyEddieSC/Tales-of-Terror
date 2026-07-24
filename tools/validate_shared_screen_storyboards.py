#!/usr/bin/env python3
"""Validate design-only shared-screen storyboard manifests."""

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

STORYBOARD_ID = re.compile(r"^DH-UI-[0-9]{3}$")
TRACE_ID = re.compile(r"^DH-XM-[0-9]{3}$")
STABLE_ID = re.compile(r"^[a-z][a-z0-9_]*$")
WINDOWS_ABSOLUTE = re.compile(r"^[A-Za-z]:[\\/]")

MANIFEST_FIELDS = {
    "manifest_kind",
    "schema_version",
    "tale_id",
    "production_status",
    "record_schema",
    "entries",
}
RECORD_FIELDS = {
    "storyboard_id",
    "title",
    "category",
    "tale_id",
    "stage_context",
    "layout_mode",
    "privacy_surface",
    "entry_condition",
    "exit_condition",
    "purpose",
    "required_information",
    "layout_regions",
    "legal_actions",
    "confirmation_pattern",
    "focus_order",
    "caption_policy",
    "transcript_policy",
    "persistent_text_policy",
    "seat_authority_policy",
    "state_variants",
    "visual_guidance",
    "negative_constraints",
    "source_paths",
    "traceability_concepts",
    "human_validation_questions",
    "status",
    "approval_boundary",
}
CATEGORIES = {
    "accessibility_settings",
    "ending_attribution",
    "lobby_and_admission",
    "private_reveal",
    "public_board",
    "public_decision",
    "seat_continuity",
    "system_recovery",
    "tale_entry",
    "transcript_and_replay",
    "transformation",
}
REQUIRED_CATEGORIES = CATEGORIES
STAGES = {
    "reusable_system",
    "low_tide_arrival",
    "bellhouse_ledger",
    "lighthouse_council",
    "high_water",
    "last_light",
    "ending_resolution",
}
LAYOUT_MODES = {
    "board_first",
    "decision_focus",
    "outcome_attribution",
    "private_shield",
    "system_overlay",
    "transformation",
}
PRIVACY_SURFACES = {
    "public_shared",
    "neutral_shared_shield",
    "controlled_private_surface",
}
CONFIRMATION_PATTERNS = {
    "acknowledgement_only",
    "confirmed_commitment",
    "none",
    "reversible_selection",
}
STATUSES = {"brief_draft", "preproduction_ready", "review_required", "deferred"}
CAPTION_FIELDS = {
    "subtitles_supported",
    "closed_captions_supported",
    "maximum_lines",
    "target_characters_per_line",
    "speaker_labels_supported",
    "critical_information_outside_captions",
}
TRANSCRIPT_FIELDS = {"public_history", "replay_supported", "private_content_excluded"}
PERSISTENT_FIELDS = {
    "required",
    "plain_system_available",
    "survives_voice_interruption",
    "dismissal_rule",
}
SEAT_FIELDS = {
    "active_seat_visible",
    "control_source_visible",
    "stable_seat_preserved",
    "private_state_publicly_hidden",
    "authority_transfer_allowed",
}
PRIVATE_HINTS = {
    "private faction",
    "private objective",
    "private inventory",
    "private bargain",
    "hidden faction",
    "hidden role",
    "latent transformation",
    "seat-private",
    "faction-private",
}
REQUIRED_TITLES = {
    "Drowned Harbor Tale Preview",
    "Local Stable-Seat Lobby",
    "Low-Tide Arrival Board",
    "Bellhouse Ledger Decision",
    "Lighthouse Council Direction Choice",
    "Public Harbor Bargain Offer",
    "Private Harbor Bargain Terms",
    "High Water Commitment and Transition",
    "High Water Transformed Board",
    "Tidebound Public Transformation",
    "Last Light Final Decision",
    "Mixed Public Outcome Attribution",
    "Stable Seat Reconnecting",
    "Stable Seat Under Game Control",
    "Public Takeover Seat Selection",
    "Inherited Private State Handoff",
    "Returning Player Recap",
    "Restless Continuation Activation",
    "Invalid Action Recovery",
    "Transcript and Replay Drawer",
    "Narrative Accessibility Settings",
    "Remote Join Request and Admission Queue",
}


@dataclass(frozen=True, order=True)
class Diagnostic:
    code: str
    path: str
    message: str

    def as_dict(self) -> dict[str, str]:
        return {"code": self.code, "path": self.path, "message": self.message}


class StoryboardValidationError(ValueError):
    """Raised when storyboard validation cannot continue."""


def add(diagnostics: list[Diagnostic], code: str, path: str, message: str) -> None:
    diagnostics.append(Diagnostic(code, path, message))


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


def exact_fields(
    value: Any,
    expected: set[str],
    path: str,
    diagnostics: list[Diagnostic],
) -> bool:
    if not isinstance(value, dict):
        add(diagnostics, "invalid_shape", path, "expected object")
        return False
    for key in sorted(expected - set(value)):
        add(diagnostics, "missing_field", f"{path}/{key}", "required field is missing")
    for key in sorted(set(value) - expected):
        add(diagnostics, "unknown_field", f"{path}/{key}", "unknown field is rejected")
    return set(value) == expected


def text(value: Any, path: str, diagnostics: list[Diagnostic], minimum: int = 1) -> str:
    if not isinstance(value, str) or len(value.strip()) < minimum:
        add(diagnostics, "invalid_text", path, f"must contain at least {minimum} characters")
        return ""
    return value.strip()


def text_list(
    value: Any,
    path: str,
    diagnostics: list[Diagnostic],
    minimum: int = 1,
) -> list[str]:
    if not isinstance(value, list) or len(value) < minimum:
        add(diagnostics, "invalid_list", path, f"must contain at least {minimum} item(s)")
        return []
    if not all(isinstance(item, str) and item.strip() for item in value):
        add(diagnostics, "invalid_list", path, "all items must be non-empty text")
        return []
    if len(value) != len(set(value)):
        add(diagnostics, "duplicate_value", path, "items must be unique")
    return value


def repository_path(value: Any, path: str, diagnostics: list[Diagnostic]) -> Path | None:
    if not isinstance(value, str) or not value or WINDOWS_ABSOLUTE.match(value):
        add(diagnostics, "unsafe_path", path, "must be a repository-relative docs path")
        return None
    pure = PurePosixPath(value.replace("\\", "/"))
    if pure.is_absolute() or ".." in pure.parts or not pure.parts or pure.parts[0] != "docs":
        add(diagnostics, "unsafe_path", path, "must remain below docs without traversal")
        return None
    resolved = ROOT / pure
    if not resolved.is_file():
        add(diagnostics, "missing_source", path, f"source file does not exist: {value}")
        return None
    return resolved


def traceability_ids(diagnostics: list[Diagnostic]) -> set[str]:
    try:
        data = read_json(TRACEABILITY_PATH)
    except StoryboardValidationError as exc:
        add(diagnostics, "missing_traceability", "/", str(exc))
        return set()
    entries = data.get("entries")
    if not isinstance(entries, list):
        add(diagnostics, "missing_traceability", "/", "traceability entries are unavailable")
        return set()
    return {
        entry.get("concept_id")
        for entry in entries
        if isinstance(entry, dict) and isinstance(entry.get("concept_id"), str)
    }


def validate_caption_policy(value: Any, path: str, diagnostics: list[Diagnostic]) -> None:
    if not exact_fields(value, CAPTION_FIELDS, path, diagnostics):
        return
    expected_true = {
        "subtitles_supported",
        "closed_captions_supported",
        "speaker_labels_supported",
        "critical_information_outside_captions",
    }
    for key in expected_true:
        if value[key] is not True:
            add(diagnostics, "caption_contract", f"{path}/{key}", "must remain true")
    if value["maximum_lines"] != 2:
        add(diagnostics, "caption_contract", f"{path}/maximum_lines", "design target must remain two lines")
    target = value["target_characters_per_line"]
    if not isinstance(target, int) or not 20 <= target <= 42:
        add(diagnostics, "caption_contract", f"{path}/target_characters_per_line", "must be 20–42")


def validate_transcript_policy(
    value: Any,
    path: str,
    privacy_surface: str,
    diagnostics: list[Diagnostic],
) -> None:
    if not exact_fields(value, TRANSCRIPT_FIELDS, path, diagnostics):
        return
    if value["private_content_excluded"] is not True:
        add(diagnostics, "privacy_leak", f"{path}/private_content_excluded", "private content must be excluded")
    if privacy_surface == "controlled_private_surface":
        if value["public_history"] is not False or value["replay_supported"] is not False:
            add(diagnostics, "privacy_leak", path, "private surfaces cannot enter public history or public replay")


def validate_persistent_policy(
    value: Any,
    path: str,
    category: str,
    diagnostics: list[Diagnostic],
) -> None:
    if not exact_fields(value, PERSISTENT_FIELDS, path, diagnostics):
        return
    if value["plain_system_available"] is not True or value["survives_voice_interruption"] is not True:
        add(diagnostics, "persistent_text", path, "plain-system text must survive voice interruption")
    critical_categories = {
        "ending_attribution",
        "private_reveal",
        "public_board",
        "public_decision",
        "seat_continuity",
        "system_recovery",
        "transformation",
    }
    if category in critical_categories and value["required"] is not True:
        add(diagnostics, "persistent_text", f"{path}/required", "critical storyboard requires persistent text")
    if value["dismissal_rule"] not in {
        "state_change_only",
        "state_change_or_user",
        "acknowledgement_then_state_change",
        "user_or_transcript",
    }:
        add(diagnostics, "persistent_text", f"{path}/dismissal_rule", "unsupported dismissal rule")


def validate_seat_policy(
    value: Any,
    path: str,
    category: str,
    privacy_surface: str,
    diagnostics: list[Diagnostic],
) -> None:
    if not exact_fields(value, SEAT_FIELDS, path, diagnostics):
        return
    if value["stable_seat_preserved"] is not True:
        add(diagnostics, "seat_continuity", f"{path}/stable_seat_preserved", "stable seat must be preserved")
    if value["private_state_publicly_hidden"] is not True:
        add(diagnostics, "privacy_leak", f"{path}/private_state_publicly_hidden", "private state must remain hidden")
    if category == "seat_continuity" and privacy_surface == "public_shared":
        if value["active_seat_visible"] is not True or value["control_source_visible"] is not True:
            add(diagnostics, "seat_continuity", path, "public continuity screens require seat and control-source visibility")


def validate_record(
    value: Any,
    path: str,
    trace_ids: set[str],
    diagnostics: list[Diagnostic],
) -> str | None:
    if not exact_fields(value, RECORD_FIELDS, path, diagnostics):
        return None
    storyboard_id = text(value["storyboard_id"], f"{path}/storyboard_id", diagnostics)
    if not STORYBOARD_ID.fullmatch(storyboard_id):
        add(diagnostics, "invalid_id", f"{path}/storyboard_id", "must match DH-UI-NNN")
    text(value["title"], f"{path}/title", diagnostics, 3)
    category = value["category"]
    if category not in CATEGORIES:
        add(diagnostics, "invalid_category", f"{path}/category", "unsupported category")
    if value["tale_id"] != "drowned_harbor":
        add(diagnostics, "wrong_tale", f"{path}/tale_id", "must be drowned_harbor")
    stages = text_list(value["stage_context"], f"{path}/stage_context", diagnostics, 1)
    for stage in stages:
        if stage not in STAGES:
            add(diagnostics, "invalid_stage", f"{path}/stage_context", f"unknown stage: {stage}")
    layout_mode = value["layout_mode"]
    privacy_surface = value["privacy_surface"]
    if layout_mode not in LAYOUT_MODES:
        add(diagnostics, "invalid_layout", f"{path}/layout_mode", "unsupported layout mode")
    if privacy_surface not in PRIVACY_SURFACES:
        add(diagnostics, "invalid_privacy", f"{path}/privacy_surface", "unsupported privacy surface")
    if category == "private_reveal":
        if layout_mode != "private_shield" or privacy_surface != "controlled_private_surface":
            add(diagnostics, "privacy_leak", path, "private reveal requires private-shield controlled surface")
    elif privacy_surface == "controlled_private_surface":
        add(diagnostics, "invalid_privacy", path, "controlled private surface is reserved for private reveals")
    text(value["entry_condition"], f"{path}/entry_condition", diagnostics, 10)
    text(value["exit_condition"], f"{path}/exit_condition", diagnostics, 10)
    text(value["purpose"], f"{path}/purpose", diagnostics, 20)
    required_information = text_list(value["required_information"], f"{path}/required_information", diagnostics, 2)
    regions = text_list(value["layout_regions"], f"{path}/layout_regions", diagnostics, 2)
    if layout_mode == "private_shield" and "private_shield_full_screen" not in regions:
        add(diagnostics, "privacy_leak", f"{path}/layout_regions", "private shield region is required")
    actions = text_list(value["legal_actions"], f"{path}/legal_actions", diagnostics, 1)
    if any(not STABLE_ID.fullmatch(action) for action in actions):
        add(diagnostics, "invalid_action", f"{path}/legal_actions", "legal actions require stable IDs")
    if actions != sorted(actions):
        add(diagnostics, "unstable_order", f"{path}/legal_actions", "legal actions must be sorted")
    confirmation = value["confirmation_pattern"]
    if confirmation not in CONFIRMATION_PATTERNS:
        add(diagnostics, "invalid_confirmation", f"{path}/confirmation_pattern", "unsupported pattern")
    if category in {"public_decision", "private_reveal"} and confirmation == "none":
        add(diagnostics, "confirmation_boundary", f"{path}/confirmation_pattern", "decision or private reveal requires a boundary")
    text_list(value["focus_order"], f"{path}/focus_order", diagnostics, 2)
    validate_caption_policy(value["caption_policy"], f"{path}/caption_policy", diagnostics)
    validate_transcript_policy(value["transcript_policy"], f"{path}/transcript_policy", privacy_surface, diagnostics)
    validate_persistent_policy(value["persistent_text_policy"], f"{path}/persistent_text_policy", category, diagnostics)
    validate_seat_policy(value["seat_authority_policy"], f"{path}/seat_authority_policy", category, privacy_surface, diagnostics)
    text_list(value["state_variants"], f"{path}/state_variants", diagnostics, 1)
    text_list(value["visual_guidance"], f"{path}/visual_guidance", diagnostics, 2)
    negative_constraints = text_list(value["negative_constraints"], f"{path}/negative_constraints", diagnostics, 2)
    source_paths = text_list(value["source_paths"], f"{path}/source_paths", diagnostics, 2)
    if source_paths != sorted(source_paths):
        add(diagnostics, "unstable_order", f"{path}/source_paths", "source paths must be sorted")
    for index, source in enumerate(source_paths):
        repository_path(source, f"{path}/source_paths/{index}", diagnostics)
    concepts = text_list(value["traceability_concepts"], f"{path}/traceability_concepts", diagnostics, 0)
    if concepts != sorted(concepts):
        add(diagnostics, "unstable_order", f"{path}/traceability_concepts", "traceability IDs must be sorted")
    for concept in concepts:
        if not TRACE_ID.fullmatch(concept) or concept not in trace_ids:
            add(diagnostics, "unknown_traceability", f"{path}/traceability_concepts", f"unknown concept: {concept}")
    text_list(value["human_validation_questions"], f"{path}/human_validation_questions", diagnostics, 2)
    if value["status"] not in STATUSES:
        add(diagnostics, "invalid_status", f"{path}/status", "unsupported preproduction status")
    text(value["approval_boundary"], f"{path}/approval_boundary", diagnostics, 40)
    if privacy_surface == "public_shared":
        combined = " ".join(required_information + negative_constraints).lower()
        leaked = sorted(hint for hint in PRIVATE_HINTS if hint in combined and "no " not in combined)
        if leaked:
            add(diagnostics, "privacy_leak", path, f"public record appears to expose private concepts: {', '.join(leaked)}")
    return storyboard_id


def discover_manifests() -> tuple[Path, ...]:
    manifests = tuple(sorted(STORYBOARD_DIR.glob(DEFAULT_PATTERN)))
    if not manifests:
        raise StoryboardValidationError("no storyboard manifests found")
    return manifests


def validate_manifests(paths: Sequence[Path]) -> tuple[list[Diagnostic], dict[str, Any]]:
    diagnostics: list[Diagnostic] = []
    trace_ids = traceability_ids(diagnostics)
    all_ids: list[str] = []
    titles: list[str] = []
    categories: set[str] = set()
    records: list[dict[str, Any]] = []
    for manifest_index, path in enumerate(paths):
        logical = f"/manifests/{manifest_index}"
        try:
            data = read_json(path)
        except StoryboardValidationError as exc:
            add(diagnostics, "malformed_manifest", logical, str(exc))
            continue
        if not exact_fields(data, MANIFEST_FIELDS, logical, diagnostics):
            continue
        if data["manifest_kind"] != "shared_screen_storyboards_preproduction":
            add(diagnostics, "wrong_manifest", f"{logical}/manifest_kind", "unsupported manifest kind")
        if data["schema_version"] != 1 or data["tale_id"] != "drowned_harbor":
            add(diagnostics, "wrong_manifest", logical, "must be Drowned Harbor schema v1")
        if data["production_status"] != "design_only":
            add(diagnostics, "production_boundary", f"{logical}/production_status", "must remain design_only")
        schema_path = repository_path(data["record_schema"], f"{logical}/record_schema", diagnostics)
        expected_schema = ROOT / "docs/preproduction/shared_screen_storyboard_schema_v1.json"
        if schema_path and schema_path != expected_schema:
            add(diagnostics, "wrong_schema", f"{logical}/record_schema", "must use shared-screen storyboard schema v1")
        entries = data["entries"]
        if not isinstance(entries, list) or not entries:
            add(diagnostics, "missing_entries", f"{logical}/entries", "entries are required")
            continue
        for entry_index, entry in enumerate(entries):
            record_path = f"{logical}/entries/{entry_index}"
            storyboard_id = validate_record(entry, record_path, trace_ids, diagnostics)
            if storyboard_id:
                all_ids.append(storyboard_id)
            if isinstance(entry, dict):
                if isinstance(entry.get("title"), str):
                    titles.append(entry["title"])
                if isinstance(entry.get("category"), str):
                    categories.add(entry["category"])
                records.append(entry)
    if len(all_ids) != len(set(all_ids)):
        add(diagnostics, "duplicate_id", "/", "storyboard IDs must be globally unique")
    expected_ids = [f"DH-UI-{index:03d}" for index in range(1, 23)]
    if sorted(all_ids) != expected_ids:
        add(diagnostics, "incomplete_inventory", "/", "exact DH-UI-001 through DH-UI-022 inventory is required")
    if set(titles) != REQUIRED_TITLES:
        add(diagnostics, "incomplete_inventory", "/", "required storyboard title inventory is incomplete or changed")
    if len(titles) != len(set(titles)):
        add(diagnostics, "duplicate_value", "/", "storyboard titles must be unique")
    if categories != REQUIRED_CATEGORIES:
        add(diagnostics, "incomplete_category", "/", "all storyboard categories must be represented")
    by_id = {record.get("storyboard_id"): record for record in records if isinstance(record.get("storyboard_id"), str)}
    if by_id.get("DH-UI-008", {}).get("layout_mode") != "transformation" or by_id.get("DH-UI-009", {}).get("layout_mode") != "board_first":
        add(diagnostics, "high_water_pair", "/", "High Water requires transformation and transformed-board storyboards")
    if by_id.get("DH-UI-016", {}).get("seat_authority_policy", {}).get("authority_transfer_allowed") is not True:
        add(diagnostics, "seat_continuity", "/DH-UI-016", "private inherited-state handoff must allow queued transfer")
    if by_id.get("DH-UI-007", {}).get("seat_authority_policy", {}).get("authority_transfer_allowed") is not False:
        add(diagnostics, "privacy_leak", "/DH-UI-007", "private bargain review cannot transfer authority")
    canonical_records = sorted(records, key=lambda item: item.get("storyboard_id", ""))
    identity = hashlib.sha256(
        json.dumps(canonical_records, ensure_ascii=True, sort_keys=True, separators=(",", ":")).encode("utf-8")
    ).hexdigest()
    return sorted(set(diagnostics)), {"storyboard_count": len(records), "identity": identity}


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("manifests", nargs="*", type=Path)
    parser.add_argument("--identity", action="store_true")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    paths = tuple(args.manifests) if args.manifests else discover_manifests()
    diagnostics, summary = validate_manifests(paths)
    if diagnostics:
        for diagnostic in diagnostics:
            print(json.dumps(diagnostic.as_dict(), sort_keys=True), file=sys.stderr)
        print(
            f"Shared-screen storyboard validation failed with {len(diagnostics)} diagnostic(s)",
            file=sys.stderr,
        )
        return 1
    if args.identity:
        print(summary["identity"])
    else:
        print(f"Validated {summary['storyboard_count']} design-only shared-screen storyboards")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
