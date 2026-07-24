#!/usr/bin/env python3
"""Validate Drowned Harbor accessible narrative registry against voice sources."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any, Sequence

VOICE_DIR = Path("docs/tales/drowned_harbor/voice")
ACCESS_DIR = Path("docs/tales/drowned_harbor/accessibility")
VOICE_PATTERN = "drowned_harbor_voice_*_families_v1.json"
ACCESS_PATTERN = "drowned_harbor_accessible_*_units_v1.json"
PLACEHOLDER_PATTERN = re.compile(r"\{[a-z][a-z0-9_]*\}")
UNIT_ID_PATTERN = re.compile(r"^DH-LOC-VO-[0-9]{3}$")
SOURCE_ID_PATTERN = re.compile(r"^DH-VO-(NAR|SYS|REV|END)-[0-9]{3}$")
EXPECTED_SOURCE_PATHS = {
    "draft_script.spooky",
    "draft_script.grim",
    "draft_script.gore_and_dread",
    "draft_script.plain_system",
}
ALLOWED_STATUS = {
    "brief_draft",
    "preproduction_ready",
    "localization_candidate",
    "linguistic_reviewed",
    "in_context_reviewed",
    "production_candidate",
    "approved",
    "rejected",
    "deferred",
}
REQUIRED_FIELDS = {
    "unit_id",
    "source_family_id",
    "source_locale",
    "speaker_key",
    "privacy_class",
    "importance",
    "source_field_paths",
    "mechanical_equivalence_key",
    "placeholder_policy",
    "caption_policy",
    "transcript_policy",
    "announcement_policy",
    "persistent_text_policy",
    "reading_order",
    "translator_notes",
    "status",
    "approval_boundary",
}


class AccessibleNarrativeValidationError(ValueError):
    """Raised when accessible narrative data violates the P0.7 contract."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AccessibleNarrativeValidationError(message)


def text(value: Any, field: str, minimum: int = 1) -> str:
    require(isinstance(value, str), f"{field} must be text")
    result = value.strip()
    require(len(result) >= minimum, f"{field} must contain at least {minimum} characters")
    return result


def text_list(value: Any, field: str, minimum: int = 1) -> list[str]:
    require(isinstance(value, list), f"{field} must be a list")
    require(len(value) >= minimum, f"{field} must contain at least {minimum} item(s)")
    require(all(isinstance(item, str) and item.strip() for item in value), f"{field} must contain non-empty text")
    require(len(value) == len(set(value)), f"{field} contains duplicates")
    return value


def read_json(path: Path) -> dict[str, Any]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise AccessibleNarrativeValidationError(f"file not found: {path}") from exc
    except json.JSONDecodeError as exc:
        raise AccessibleNarrativeValidationError(f"invalid JSON in {path}: {exc}") from exc
    require(isinstance(data, dict), f"root must be an object: {path}")
    return data


def discover_voice_manifests() -> tuple[Path, ...]:
    paths = tuple(sorted(VOICE_DIR.glob(VOICE_PATTERN)))
    require(bool(paths), "no governed voice manifests found")
    return paths


def discover_access_manifests() -> tuple[Path, ...]:
    paths = tuple(sorted(ACCESS_DIR.glob(ACCESS_PATTERN)))
    require(bool(paths), "no accessible narrative manifests found")
    return paths


def load_voice_families(paths: Sequence[Path]) -> dict[str, dict[str, Any]]:
    families: dict[str, dict[str, Any]] = {}
    for path in paths:
        data = read_json(path)
        require(data.get("manifest_kind") == "voice_line_families_preproduction", f"unexpected voice manifest kind: {path}")
        require(data.get("production_status") == "design_only", f"voice manifest must remain design_only: {path}")
        entries = data.get("entries")
        require(isinstance(entries, list) and entries, f"voice entries missing: {path}")
        for entry in entries:
            require(isinstance(entry, dict), f"voice entry must be an object: {path}")
            family_id = text(entry.get("family_id"), f"{path}.family_id")
            require(SOURCE_ID_PATTERN.fullmatch(family_id) is not None, f"invalid voice family ID: {family_id}")
            require(family_id not in families, f"duplicate voice family ID: {family_id}")
            families[family_id] = entry
    return families


def extract_profile_placeholders(family: dict[str, Any], family_id: str) -> dict[str, set[str]]:
    scripts = family.get("draft_script")
    require(isinstance(scripts, dict), f"{family_id}: draft_script missing")
    require(set(scripts) == {"spooky", "grim", "gore_and_dread", "plain_system"}, f"{family_id}: source profiles are incomplete")
    return {
        profile: set(PLACEHOLDER_PATTERN.findall(text(script, f"{family_id}.{profile}")))
        for profile, script in scripts.items()
    }


def validate_placeholder_policy(unit: dict[str, Any], family: dict[str, Any], unit_id: str) -> None:
    policy = unit["placeholder_policy"]
    require(isinstance(policy, dict), f"{unit_id}: placeholder_policy must be an object")
    expected = {"allowed_placeholders", "named_only", "sentence_concatenation", "private_placeholders_allowed"}
    require(set(policy) == expected, f"{unit_id}: invalid placeholder-policy fields")
    allowed = text_list(policy["allowed_placeholders"], f"{unit_id}.allowed_placeholders", minimum=0)
    require(all(PLACEHOLDER_PATTERN.fullmatch(item) for item in allowed), f"{unit_id}: placeholders must be named brace tokens")
    require(policy["named_only"] is True, f"{unit_id}: named placeholders are required")
    require(policy["sentence_concatenation"] is False, f"{unit_id}: sentence concatenation is prohibited")
    require(policy["private_placeholders_allowed"] is False, f"{unit_id}: private placeholders are prohibited in public registry units")

    profile_sets = extract_profile_placeholders(family, unit["source_family_id"])
    unique_sets = {frozenset(values) for values in profile_sets.values()}
    require(len(unique_sets) == 1, f"{unit_id}: source profile placeholder sets differ")
    actual = next(iter(profile_sets.values()))
    require(actual.issubset(set(allowed)), f"{unit_id}: source contains undeclared placeholders: {sorted(actual - set(allowed))}")


def validate_caption_policy(unit: dict[str, Any], unit_id: str) -> None:
    policy = unit["caption_policy"]
    require(isinstance(policy, dict), f"{unit_id}: caption_policy must be an object")
    expected = {"subtitle_required", "closed_caption_supported", "max_lines", "target_characters_per_line", "timed_only", "speaker_label_supported", "text_scale_safe"}
    require(set(policy) == expected, f"{unit_id}: invalid caption-policy fields")
    require(policy["subtitle_required"] is True, f"{unit_id}: subtitles are required")
    require(policy["closed_caption_supported"] is True, f"{unit_id}: closed-caption presentation is required")
    require(policy["max_lines"] == 2, f"{unit_id}: P0.7 caption target is two lines")
    require(20 <= policy["target_characters_per_line"] <= 42, f"{unit_id}: caption character target exceeds P0.7 bounds")
    require(policy["timed_only"] is False, f"{unit_id}: critical narrative may not be timed-only")
    require(policy["speaker_label_supported"] is True, f"{unit_id}: speaker labels must remain supported")
    require(policy["text_scale_safe"] is True, f"{unit_id}: text-scale safety is required")


def validate_transcript_policy(unit: dict[str, Any], unit_id: str) -> None:
    policy = unit["transcript_policy"]
    require(isinstance(policy, dict), f"{unit_id}: transcript_policy must be an object")
    expected = {"included", "replayable", "event_label_key", "public_history"}
    require(set(policy) == expected, f"{unit_id}: invalid transcript-policy fields")
    require(policy["included"] is True, f"{unit_id}: transcript inclusion is required")
    require(policy["replayable"] is True, f"{unit_id}: transcript replay is required")
    text(policy["event_label_key"], f"{unit_id}.event_label_key", 10)
    require(policy["public_history"] is True, f"{unit_id}: governed public unit must remain in public history")


def validate_announcement_policy(unit: dict[str, Any], unit_id: str) -> None:
    policy = unit["announcement_policy"]
    require(isinstance(policy, dict), f"{unit_id}: announcement_policy must be an object")
    expected = {"priority", "coalesce_key", "focus_required", "interrupt_lower_priority"}
    require(set(policy) == expected, f"{unit_id}: invalid announcement-policy fields")
    priority = policy["priority"]
    require(priority in {"none", "polite", "assertive", "focus_required"}, f"{unit_id}: invalid announcement priority")
    text(policy["coalesce_key"], f"{unit_id}.coalesce_key", 5)
    require(policy["focus_required"] is (priority == "focus_required"), f"{unit_id}: focus_required flag must match priority")
    if priority in {"assertive", "focus_required"}:
        require(policy["interrupt_lower_priority"] is True, f"{unit_id}: high-priority announcements must interrupt lower-priority output")
    if priority in {"none", "polite"}:
        require(policy["interrupt_lower_priority"] is False, f"{unit_id}: nonurgent announcements may not interrupt lower-priority output")


def validate_persistent_policy(unit: dict[str, Any], unit_id: str) -> None:
    policy = unit["persistent_text_policy"]
    require(isinstance(policy, dict), f"{unit_id}: persistent_text_policy must be an object")
    expected = {"required", "dismissal", "plain_system_available", "survives_voice_interruption"}
    require(set(policy) == expected, f"{unit_id}: invalid persistent-text fields")
    require(isinstance(policy["required"], bool), f"{unit_id}: persistent required must be boolean")
    require(policy["dismissal"] in {"state_change_or_user", "state_change_only", "user_or_transcript", "transcript_only"}, f"{unit_id}: invalid dismissal policy")
    require(policy["plain_system_available"] is True, f"{unit_id}: plain-system text is required")
    require(policy["survives_voice_interruption"] is True, f"{unit_id}: text must survive voice interruption")
    if unit["importance"] == "critical":
        require(policy["required"] is True, f"{unit_id}: critical units require persistent text")


def validate_unit(unit: Any, index: int, voice_families: dict[str, dict[str, Any]]) -> tuple[str, str]:
    require(isinstance(unit, dict), f"entries[{index}] must be an object")
    missing = REQUIRED_FIELDS - unit.keys()
    unexpected = set(unit) - REQUIRED_FIELDS
    require(not missing, f"entries[{index}] missing fields: {sorted(missing)}")
    require(not unexpected, f"entries[{index}] unexpected fields: {sorted(unexpected)}")

    unit_id = text(unit["unit_id"], f"entries[{index}].unit_id")
    require(UNIT_ID_PATTERN.fullmatch(unit_id) is not None, f"invalid accessible unit ID: {unit_id}")
    source_id = text(unit["source_family_id"], f"{unit_id}.source_family_id")
    require(source_id in voice_families, f"{unit_id}: unknown source family: {source_id}")
    family = voice_families[source_id]
    require(unit["source_locale"] == "en-US", f"{unit_id}: source locale must remain en-US")
    require(unit["privacy_class"] == family["privacy_class"], f"{unit_id}: privacy class differs from source family")
    require(unit["importance"] in {"critical", "important", "contextual"}, f"{unit_id}: invalid importance")
    source_paths = text_list(unit["source_field_paths"], f"{unit_id}.source_field_paths", minimum=4)
    require(set(source_paths) == EXPECTED_SOURCE_PATHS, f"{unit_id}: all four governed source fields are required")
    require(unit["mechanical_equivalence_key"] == family["mechanical_equivalence_key"], f"{unit_id}: mechanical-equivalence key differs from source")
    require(unit["speaker_key"] in {"speaker.host", "speaker.system", "speaker.harbor", "speaker.bellhouse", "speaker.lighthouse", "speaker.seat", "speaker.none"}, f"{unit_id}: invalid speaker key")
    if family["category"] == "system":
        require(unit["speaker_key"] == "speaker.system", f"{unit_id}: system families must use system speaker key")
    if family["category"] in {"narrative", "reveal", "ending"}:
        require(unit["speaker_key"] == "speaker.host", f"{unit_id}: character families must use host speaker key")

    validate_placeholder_policy(unit, family, unit_id)
    validate_caption_policy(unit, unit_id)
    validate_transcript_policy(unit, unit_id)
    validate_announcement_policy(unit, unit_id)
    validate_persistent_policy(unit, unit_id)
    text_list(unit["reading_order"], f"{unit_id}.reading_order", minimum=3)
    text_list(unit["translator_notes"], f"{unit_id}.translator_notes", minimum=2)
    require(unit["status"] in ALLOWED_STATUS, f"{unit_id}: invalid status")
    require(unit["status"] not in {"production_candidate", "approved"}, f"{unit_id}: P0.7 may not approve production localization")
    text(unit["approval_boundary"], f"{unit_id}.approval_boundary", 40)

    if unit["privacy_class"] == "private_surface_deferred":
        require(unit["status"] == "deferred", f"{unit_id}: private-surface units must remain deferred")
        require(unit["transcript_policy"]["public_history"] is False, f"{unit_id}: private units may not enter public history")

    return unit_id, source_id


def validate_access_manifests(access_paths: Sequence[Path], voice_families: dict[str, dict[str, Any]]) -> tuple[int, int]:
    require(bool(access_paths), "at least one accessibility manifest is required")
    unit_ids: set[str] = set()
    source_ids: set[str] = set()
    total = 0
    schema_name: str | None = None

    for path in access_paths:
        data = read_json(path)
        require(data.get("manifest_kind") == "accessible_narrative_units_preproduction", f"unexpected manifest kind: {path}")
        require(data.get("schema_version") == 1, f"unsupported schema version: {path}")
        require(data.get("tale_id") == "drowned_harbor", f"unexpected Tale ID: {path}")
        require(data.get("production_status") == "design_only", f"production status must remain design_only: {path}")
        current_schema = text(data.get("entry_schema"), f"{path}.entry_schema")
        if schema_name is None:
            schema_name = current_schema
        require(current_schema == schema_name, f"{path}: all accessibility manifests must share one schema")
        entries = data.get("entries")
        require(isinstance(entries, list) and entries, f"entries must be non-empty: {path}")
        for index, unit in enumerate(entries):
            unit_id, source_id = validate_unit(unit, index, voice_families)
            require(unit_id not in unit_ids, f"duplicate accessibility unit ID: {unit_id}")
            require(source_id not in source_ids, f"source family registered more than once: {source_id}")
            unit_ids.add(unit_id)
            source_ids.add(source_id)
            total += 1

    missing_sources = set(voice_families) - source_ids
    extra_sources = source_ids - set(voice_families)
    require(not missing_sources, f"voice families missing accessibility registry units: {sorted(missing_sources)}")
    require(not extra_sources, f"unknown accessibility source references: {sorted(extra_sources)}")
    return len(access_paths), total


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("access_manifests", nargs="*", type=Path)
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    access_paths = tuple(args.access_manifests) if args.access_manifests else discover_access_manifests()
    try:
        voice_families = load_voice_families(discover_voice_manifests())
        manifest_count, unit_count = validate_access_manifests(access_paths, voice_families)
    except AccessibleNarrativeValidationError as exc:
        print(f"Accessible narrative validation failed: {exc}", file=sys.stderr)
        return 1
    print(f"Validated {unit_count} accessible narrative units across {manifest_count} manifest(s) against {len(voice_families)} voice families")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
