#!/usr/bin/env python3
"""Validate governed Underteller voice line families for preproduction."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any, Sequence

DEFAULT_VOICE_DIR = Path("docs/tales/drowned_harbor/voice")
DEFAULT_PATTERN = "drowned_harbor_voice_*_families_v1.json"

ID_PATTERN = re.compile(r"^DH-VO-(NAR|SYS|REV|END)-[0-9]{3}$")
PREFIX_CATEGORY = {
    "NAR": "narrative",
    "SYS": "system",
    "REV": "reveal",
    "END": "ending",
}
ALLOWED_STATUS = {
    "brief_draft",
    "brief_reviewed",
    "audition_ready",
    "candidate_recorded",
    "candidate_reviewed",
    "production_candidate",
    "approved",
    "rejected",
    "deferred",
}
ALLOWED_STAGE = {
    "low_tide_arrival",
    "bellhouse_ledger",
    "lighthouse_council",
    "high_water",
    "last_light",
    "ending_resolution",
    "reusable_system",
}
ALLOWED_DELIVERY = {
    "host",
    "witness",
    "tempter",
    "adjudicator",
    "mourner",
    "revelator",
    "plain_system",
}
ALLOWED_PRIVACY = {"public_shared", "plain_system", "private_surface_deferred"}
ALLOWED_SOURCE = {
    "human_performer",
    "synthetic_consented",
    "synthetic_original",
    "temporary_placeholder",
}
PRIVATE_BOUNDARY_MARKERS = {
    "hidden",
    "private",
    "latent",
    "unrevealed",
    "future",
}
DANGEROUS_PUBLIC_INPUT_MARKERS = {
    "hidden faction assignment",
    "private objective value",
    "private bargain cost value",
    "latent transformation state",
    "hidden director target",
    "private inventory contents",
    "private vote value",
    "unrevealed ending carrier identity",
}
IMITATION_MARKERS = {
    "in the style of",
    "exactly like",
    "sound like a celebrity",
    "imitate the actor",
    "imitate the character",
    "celebrity clone",
}
RESET_OR_ELIMINATION_PHRASES = {
    "the player is out",
    "the character has left the game",
    "the bot replaced the character",
    "the seat has reset",
    "the seat was deleted",
    "all health is restored",
    "all items are restored",
}
REQUIRED_FIELDS = {
    "family_id",
    "title",
    "category",
    "delivery_mode",
    "intensity_range",
    "priority",
    "status",
    "privacy_class",
    "stages",
    "trigger",
    "required_public_facts",
    "forbidden_private_inputs",
    "prohibited_implications",
    "mechanical_equivalence_key",
    "draft_script",
    "performance_notes",
    "timing",
    "playback_policy",
    "pronunciation_terms",
    "take_plan",
    "candidate_guidance",
    "provenance_policy",
    "approval_boundary",
}


class VoiceValidationError(ValueError):
    """Raised when a voice line family violates the P0.6 contract."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise VoiceValidationError(message)


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


def validate_intensity(family_id: str, value: Any) -> None:
    require(isinstance(value, dict), f"{family_id}: intensity_range must be an object")
    require(set(value) == {"minimum", "target", "maximum"}, f"{family_id}: invalid intensity fields")
    minimum = value["minimum"]
    target = value["target"]
    maximum = value["maximum"]
    for name, number in value.items():
        require(isinstance(number, int) and not isinstance(number, bool), f"{family_id}: intensity {name} must be an integer")
        require(1 <= number <= 5, f"{family_id}: intensity {name} is outside 1-5")
    require(minimum <= target <= maximum, f"{family_id}: intensity ordering is invalid")


def validate_timing(family_id: str, value: Any) -> None:
    require(isinstance(value, dict), f"{family_id}: timing must be an object")
    require(set(value) == {"minimum_seconds", "target_seconds", "maximum_seconds"}, f"{family_id}: invalid timing fields")
    minimum = value["minimum_seconds"]
    target = value["target_seconds"]
    maximum = value["maximum_seconds"]
    for name, number in value.items():
        require(isinstance(number, (int, float)) and not isinstance(number, bool), f"{family_id}: {name} must be numeric")
        require(0.2 <= number <= 60, f"{family_id}: {name} is outside allowed range")
    require(minimum <= target <= maximum, f"{family_id}: timing ordering is invalid")


def validate_scripts(family_id: str, value: Any) -> str:
    require(isinstance(value, dict), f"{family_id}: draft_script must be an object")
    expected = {"spooky", "grim", "gore_and_dread", "plain_system"}
    require(set(value) == expected, f"{family_id}: draft_script must contain all profiles and plain_system")
    for key in expected:
        text(value[key], f"{family_id}.draft_script.{key}", 20)
    plain = value["plain_system"].strip()
    require("..." not in plain, f"{family_id}: plain-system script may not use ellipses")
    lowered = " ".join(value.values()).lower()
    for phrase in RESET_OR_ELIMINATION_PHRASES:
        require(phrase not in lowered, f"{family_id}: prohibited reset or elimination phrase: {phrase}")
    return plain


def validate_playback(family_id: str, value: Any) -> None:
    require(isinstance(value, dict), f"{family_id}: playback_policy must be an object")
    expected = {"interruptible", "replayable", "caption_required", "text_persists_after_interruption", "blocks_input"}
    require(set(value) == expected, f"{family_id}: invalid playback policy fields")
    require(value["interruptible"] is True, f"{family_id}: speech must be interruptible")
    require(value["replayable"] is True, f"{family_id}: speech must be replayable")
    require(value["caption_required"] is True, f"{family_id}: captions are required")
    require(value["text_persists_after_interruption"] is True, f"{family_id}: text must persist after interruption")
    require(value["blocks_input"] is False, f"{family_id}: voice playback may not block input")


def validate_take_plan(family_id: str, value: Any) -> None:
    require(isinstance(value, dict), f"{family_id}: take_plan must be an object")
    expected = {"canonical", "alternate_b", "alternate_c", "pickup_allowed"}
    require(set(value) == expected, f"{family_id}: invalid take-plan fields")
    text(value["canonical"], f"{family_id}.take_plan.canonical", 8)
    text(value["alternate_b"], f"{family_id}.take_plan.alternate_b", 8)
    text(value["alternate_c"], f"{family_id}.take_plan.alternate_c", 8)
    require(value["pickup_allowed"] is True, f"{family_id}: pickups must remain allowed")


def validate_guidance(family_id: str, value: Any) -> None:
    require(isinstance(value, dict), f"{family_id}: candidate_guidance must be an object")
    expected = {"human_direction", "synthetic_direction", "negative_direction", "human_edit_plan"}
    require(set(value) == expected, f"{family_id}: invalid candidate-guidance fields")
    human = text(value["human_direction"], f"{family_id}.candidate_guidance.human_direction", 30)
    synthetic = text(value["synthetic_direction"], f"{family_id}.candidate_guidance.synthetic_direction", 30)
    negative = text(value["negative_direction"], f"{family_id}.candidate_guidance.negative_direction", 35)
    text(value["human_edit_plan"], f"{family_id}.candidate_guidance.human_edit_plan", 30)
    combined = f"{human} {synthetic}".lower()
    for marker in IMITATION_MARKERS:
        require(marker not in combined, f"{family_id}: imitation-oriented direction is prohibited: {marker}")
    require("imitation" in negative.lower(), f"{family_id}: negative direction must reject imitation")


def validate_provenance(family_id: str, value: Any, priority: str) -> None:
    require(isinstance(value, dict), f"{family_id}: provenance_policy must be an object")
    expected = {"allowed_source_kinds", "voice_clone_consent", "raw_public_distribution", "required_record"}
    require(set(value) == expected, f"{family_id}: invalid provenance-policy fields")
    sources = text_list(value["allowed_source_kinds"], f"{family_id}.allowed_source_kinds")
    require(set(sources).issubset(ALLOWED_SOURCE), f"{family_id}: unsupported source kind")
    require(value["voice_clone_consent"] in {"prohibited", "separate_explicit_agreement_required", "not_applicable"}, f"{family_id}: invalid clone-consent policy")
    require(value["raw_public_distribution"] in {"allowed", "prohibited", "agreement_dependent"}, f"{family_id}: invalid distribution policy")
    text_list(value["required_record"], f"{family_id}.required_record", minimum=6)
    if "human_performer" in sources or "synthetic_consented" in sources:
        require(value["voice_clone_consent"] != "not_applicable", f"{family_id}: performer-linked sources require an explicit clone-consent boundary")
        require(value["raw_public_distribution"] != "allowed", f"{family_id}: performer or consented synthetic raw files may not claim unrestricted public distribution")
    if priority in {"P0", "P1"}:
        require("temporary_placeholder" not in sources or len(sources) > 1, f"{family_id}: critical families may not rely only on a placeholder source")


def validate_entry(entry: Any, index: int) -> str:
    require(isinstance(entry, dict), f"entries[{index}] must be an object")
    missing = REQUIRED_FIELDS - entry.keys()
    unexpected = set(entry) - REQUIRED_FIELDS
    require(not missing, f"entries[{index}] missing fields: {sorted(missing)}")
    require(not unexpected, f"entries[{index}] unexpected fields: {sorted(unexpected)}")

    family_id = text(entry["family_id"], f"entries[{index}].family_id")
    match = ID_PATTERN.fullmatch(family_id)
    require(match is not None, f"{family_id}: invalid family ID")
    category = entry["category"]
    require(category == PREFIX_CATEGORY[match.group(1)], f"{family_id}: category does not match ID prefix")
    text(entry["title"], f"{family_id}.title")
    require(entry["delivery_mode"] in ALLOWED_DELIVERY, f"{family_id}: invalid delivery mode")
    validate_intensity(family_id, entry["intensity_range"])
    require(entry["priority"] in {"P0", "P1", "P2", "P3"}, f"{family_id}: invalid priority")
    require(entry["status"] in ALLOWED_STATUS, f"{family_id}: invalid status")
    require(entry["status"] not in {"production_candidate", "approved"}, f"{family_id}: P0.6 may not approve production voice")
    privacy = entry["privacy_class"]
    require(privacy in ALLOWED_PRIVACY, f"{family_id}: invalid privacy class")

    stages = text_list(entry["stages"], f"{family_id}.stages")
    require(set(stages).issubset(ALLOWED_STAGE), f"{family_id}: unsupported stage")
    text(entry["trigger"], f"{family_id}.trigger", 30)
    public_facts = text_list(entry["required_public_facts"], f"{family_id}.required_public_facts", minimum=2)
    forbidden = text_list(entry["forbidden_private_inputs"], f"{family_id}.forbidden_private_inputs", minimum=3)
    implications = text_list(entry["prohibited_implications"], f"{family_id}.prohibited_implications", minimum=2)
    public_text = " ".join(public_facts).lower()
    for marker in DANGEROUS_PUBLIC_INPUT_MARKERS:
        require(marker not in public_text, f"{family_id}: private value declared as a required public fact: {marker}")
    forbidden_text = " ".join(forbidden).lower()
    require(any(marker in forbidden_text for marker in PRIVATE_BOUNDARY_MARKERS), f"{family_id}: forbidden inputs must explicitly cover hidden, private, latent, unrevealed, or future state")
    text(" ".join(implications), f"{family_id}.prohibited_implications", 30)
    text(entry["mechanical_equivalence_key"], f"{family_id}.mechanical_equivalence_key", 12)

    validate_scripts(family_id, entry["draft_script"])
    text_list(entry["performance_notes"], f"{family_id}.performance_notes", minimum=2)
    validate_timing(family_id, entry["timing"])
    validate_playback(family_id, entry["playback_policy"])
    text_list(entry["pronunciation_terms"], f"{family_id}.pronunciation_terms", minimum=0)
    validate_take_plan(family_id, entry["take_plan"])
    validate_guidance(family_id, entry["candidate_guidance"])
    validate_provenance(family_id, entry["provenance_policy"], entry["priority"])
    text(entry["approval_boundary"], f"{family_id}.approval_boundary", 40)

    if privacy == "private_surface_deferred":
        require(entry["status"] == "deferred", f"{family_id}: private-surface voice must remain deferred")
    if privacy == "plain_system":
        require(entry["delivery_mode"] == "plain_system", f"{family_id}: plain-system privacy requires plain-system delivery")
        scripts = entry["draft_script"]
        require(len(set(scripts.values())) == 1, f"{family_id}: plain-system families must not change wording across presentation profiles")
    if category == "ending":
        require(stages == ["ending_resolution"], f"{family_id}: ending families must use ending_resolution only")
    if category == "reveal":
        require(privacy == "public_shared", f"{family_id}: public reveal families must use shared public output")

    return family_id


def read_manifest(path: Path) -> dict[str, Any]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise VoiceValidationError(f"manifest not found: {path}") from exc
    except json.JSONDecodeError as exc:
        raise VoiceValidationError(f"invalid JSON in {path}: {exc}") from exc
    require(isinstance(data, dict), f"manifest root must be an object: {path}")
    return data


def discover_default_manifests() -> tuple[Path, ...]:
    paths = tuple(sorted(DEFAULT_VOICE_DIR.glob(DEFAULT_PATTERN)))
    require(bool(paths), "no governed voice manifests found")
    return paths


def validate_manifest(data: Any) -> tuple[str, int, set[str]]:
    require(isinstance(data, dict), "manifest root must be an object")
    require(data.get("manifest_kind") == "voice_line_families_preproduction", "unexpected manifest_kind")
    require(data.get("schema_version") == 1, "unsupported schema_version")
    require(data.get("tale_id") == "drowned_harbor", "unexpected tale_id")
    require(data.get("production_status") == "design_only", "production_status must remain design_only")
    schema_name = text(data.get("entry_schema"), "entry_schema")
    entries = data.get("entries")
    require(isinstance(entries, list) and entries, "entries must be a non-empty list")
    ids: set[str] = set()
    for index, entry in enumerate(entries):
        family_id = validate_entry(entry, index)
        require(family_id not in ids, f"duplicate family ID: {family_id}")
        ids.add(family_id)
    return schema_name, len(entries), ids


def validate_manifests(paths: Sequence[Path]) -> tuple[int, int]:
    require(bool(paths), "at least one voice manifest is required")
    schema_name: str | None = None
    global_ids: dict[str, Path] = {}
    total = 0
    for path in paths:
        current_schema, count, ids = validate_manifest(read_manifest(path))
        if schema_name is None:
            schema_name = current_schema
        require(current_schema == schema_name, f"{path}: all manifests must share one entry schema")
        for family_id in ids:
            require(family_id not in global_ids, f"duplicate family ID across manifests: {family_id}")
            global_ids[family_id] = path
        total += count
    return len(paths), total


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("manifests", nargs="*", type=Path)
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    paths = tuple(args.manifests) if args.manifests else discover_default_manifests()
    try:
        manifest_count, family_count = validate_manifests(paths)
    except VoiceValidationError as exc:
        print(f"Voice line validation failed: {exc}", file=sys.stderr)
        return 1
    print(f"Validated {family_count} governed voice line families across {manifest_count} manifest(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
