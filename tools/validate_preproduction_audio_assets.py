#!/usr/bin/env python3
"""Validate governed Drowned Harbor preproduction audio asset briefs."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any, Sequence

DEFAULT_AUDIO_DIR = Path("docs/tales/drowned_harbor/audio")
DEFAULT_MANIFEST_PATTERN = "drowned_harbor_audio_*_briefs_v1.json"

ID_PATTERN = re.compile(r"^DH-AUD-(AMB|SFX|UI|TRN|SYS)-[0-9]{3}$")
PREFIX_CATEGORY = {
    "AMB": "ambience",
    "SFX": "sound_effect",
    "UI": "ui",
    "TRN": "transition",
    "SYS": "system",
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
ALLOWED_PRIVACY = {"public", "private_surface_deferred", "diagnostic_only"}
ALLOWED_INFORMATION = {"none", "redundant", "critical_redundant"}
ALLOWED_STAGES = {
    "low_tide_arrival",
    "bellhouse_ledger",
    "lighthouse_council",
    "high_water",
    "last_light",
    "reusable_system",
    "ending_resolution",
}
ALLOWED_LOOPS = {"none", "seamless_loop", "layered_bed"}
ALLOWED_SPATIAL = {
    "global_nonspatial",
    "board_localized",
    "environment_bed",
    "private_surface_deferred",
}
ALLOWED_CHANNELS = {"mono", "stereo"}
ALLOWED_PROFILES = {"spooky", "grim", "gore_and_dread", "profile_neutral"}
ALLOWED_BUSES = {
    "critical_ui",
    "critical_tale_sfx",
    "interaction_sfx",
    "environment_sfx",
    "ambience",
    "system",
}
ALLOWED_SOURCE_KINDS = {
    "original_recording",
    "original_synthesis",
    "original_ai_assisted",
    "commissioned",
    "licensed_transformed",
    "licensed_supporting",
    "placeholder",
}
DISALLOWED_PROMPT_PHRASES = {
    "in the style of",
    "exactly like",
    "copy the sound",
    "replicate the sound",
    "sound exactly like",
    "imitate the voice",
}
REQUIRED_ENTRY_FIELDS = {
    "asset_id",
    "title",
    "category",
    "signature_asset",
    "originality_tier",
    "priority",
    "status",
    "privacy_class",
    "gameplay_information",
    "stages",
    "trigger",
    "purpose",
    "duration",
    "loop_mode",
    "spatial_mode",
    "source_channel_layout",
    "presentation_profiles",
    "layers",
    "sonic_requirements",
    "negative_constraints",
    "mix_policy",
    "accessibility",
    "generator_guidance",
    "provenance_policy",
    "approval_boundary",
}


class AudioAssetValidationError(ValueError):
    """Raised when an audio brief violates the preproduction contract."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AudioAssetValidationError(message)


def nonempty_text(value: Any, field: str) -> str:
    require(
        isinstance(value, str) and bool(value.strip()),
        f"{field} must be non-empty text",
    )
    return value


def unique_text_list(value: Any, field: str, *, allow_empty: bool = False) -> list[str]:
    require(isinstance(value, list), f"{field} must be a list")
    if not allow_empty:
        require(bool(value), f"{field} must be non-empty")
    require(
        all(isinstance(item, str) and bool(item.strip()) for item in value),
        f"{field} must contain non-empty text",
    )
    require(len(value) == len(set(value)), f"{field} contains duplicates")
    return value


def validate_duration(asset_id: str, duration: Any, loop_mode: str) -> None:
    require(isinstance(duration, dict), f"{asset_id}: duration must be an object")
    require(
        set(duration) == {"minimum_seconds", "target_seconds", "maximum_seconds"},
        f"{asset_id}: duration fields do not match contract",
    )
    minimum = duration["minimum_seconds"]
    target = duration["target_seconds"]
    maximum = duration["maximum_seconds"]
    for name, value in duration.items():
        require(
            isinstance(value, (int, float)) and not isinstance(value, bool),
            f"{asset_id}: {name} must be numeric",
        )
        require(0.05 <= value <= 600, f"{asset_id}: {name} is outside bounds")
    require(minimum <= target <= maximum, f"{asset_id}: duration ordering is invalid")
    if loop_mode != "none":
        require(target >= 15, f"{asset_id}: looped assets require at least 15 target seconds")


def validate_mix(asset_id: str, mix: Any, category: str) -> None:
    require(isinstance(mix, dict), f"{asset_id}: mix_policy must be an object")
    expected = {
        "bus",
        "foreground_priority",
        "duck_under_dialogue",
        "maximum_simultaneous_instances",
        "minimum_variation_count",
        "reduced_density_supported",
    }
    require(set(mix) == expected, f"{asset_id}: mix_policy fields do not match contract")
    require(mix["bus"] in ALLOWED_BUSES, f"{asset_id}: unsupported bus")
    require(
        isinstance(mix["foreground_priority"], int)
        and not isinstance(mix["foreground_priority"], bool)
        and 1 <= mix["foreground_priority"] <= 100,
        f"{asset_id}: invalid foreground priority",
    )
    require(
        isinstance(mix["duck_under_dialogue"], bool),
        f"{asset_id}: duck_under_dialogue must be boolean",
    )
    require(
        isinstance(mix["maximum_simultaneous_instances"], int)
        and not isinstance(mix["maximum_simultaneous_instances"], bool)
        and 1 <= mix["maximum_simultaneous_instances"] <= 32,
        f"{asset_id}: invalid maximum simultaneous instances",
    )
    require(
        isinstance(mix["minimum_variation_count"], int)
        and not isinstance(mix["minimum_variation_count"], bool)
        and 1 <= mix["minimum_variation_count"] <= 32,
        f"{asset_id}: invalid variation count",
    )
    require(
        isinstance(mix["reduced_density_supported"], bool),
        f"{asset_id}: reduced_density_supported must be boolean",
    )
    if category == "ambience":
        require(mix["bus"] == "ambience", f"{asset_id}: ambience must use ambience bus")
        require(mix["duck_under_dialogue"], f"{asset_id}: ambience must duck under dialogue")
        require(
            mix["reduced_density_supported"],
            f"{asset_id}: ambience must support reduced density",
        )
    if category == "system":
        require(mix["bus"] == "system", f"{asset_id}: system cues must use system bus")


def validate_accessibility(
    asset_id: str,
    accessibility: Any,
    gameplay_information: str,
) -> None:
    require(
        isinstance(accessibility, dict),
        f"{asset_id}: accessibility must be an object",
    )
    expected = {
        "caption_key_required",
        "visual_redundancy_required",
        "mono_safe",
        "reduced_dynamics_behavior",
    }
    require(
        set(accessibility) == expected,
        f"{asset_id}: accessibility fields do not match contract",
    )
    for field in ("caption_key_required", "visual_redundancy_required", "mono_safe"):
        require(
            isinstance(accessibility[field], bool),
            f"{asset_id}: accessibility.{field} must be boolean",
        )
    nonempty_text(
        accessibility["reduced_dynamics_behavior"],
        f"{asset_id}.accessibility.reduced_dynamics_behavior",
    )
    if gameplay_information == "critical_redundant":
        require(
            accessibility["caption_key_required"],
            f"{asset_id}: critical cues require captions",
        )
        require(
            accessibility["visual_redundancy_required"],
            f"{asset_id}: critical cues require visual redundancy",
        )
        require(
            accessibility["mono_safe"],
            f"{asset_id}: critical cues must be mono safe",
        )


def validate_generator_guidance(asset_id: str, guidance: Any) -> None:
    require(
        isinstance(guidance, dict),
        f"{asset_id}: generator_guidance must be an object",
    )
    expected = {"prompt", "negative_prompt", "consistency_anchor"}
    require(
        set(guidance) == expected,
        f"{asset_id}: generator_guidance fields do not match contract",
    )
    prompt = nonempty_text(guidance["prompt"], f"{asset_id}.generator_guidance.prompt")
    negative = nonempty_text(
        guidance["negative_prompt"],
        f"{asset_id}.generator_guidance.negative_prompt",
    )
    nonempty_text(
        guidance["consistency_anchor"],
        f"{asset_id}.generator_guidance.consistency_anchor",
    )
    require(len(negative) >= 20, f"{asset_id}: negative prompt is too weak")
    lowered = prompt.lower()
    for phrase in DISALLOWED_PROMPT_PHRASES:
        require(
            phrase not in lowered,
            f"{asset_id}: disallowed imitation phrase in prompt: {phrase}",
        )


def validate_provenance(
    asset_id: str,
    provenance: Any,
    signature_asset: bool,
) -> None:
    require(
        isinstance(provenance, dict),
        f"{asset_id}: provenance_policy must be an object",
    )
    expected = {
        "allowed_source_kinds",
        "raw_public_distribution",
        "third_party_ai_input",
        "required_record",
    }
    require(
        set(provenance) == expected,
        f"{asset_id}: provenance_policy fields do not match contract",
    )
    source_kinds = unique_text_list(
        provenance["allowed_source_kinds"],
        f"{asset_id}.provenance_policy.allowed_source_kinds",
    )
    require(
        set(source_kinds).issubset(ALLOWED_SOURCE_KINDS),
        f"{asset_id}: unsupported source kind",
    )
    require(
        provenance["raw_public_distribution"]
        in {"allowed", "prohibited", "license_dependent"},
        f"{asset_id}: invalid public-distribution rule",
    )
    require(
        provenance["third_party_ai_input"]
        in {"prohibited", "explicit_permission_required", "not_applicable"},
        f"{asset_id}: invalid third-party AI-input rule",
    )
    unique_text_list(
        provenance["required_record"],
        f"{asset_id}.provenance_policy.required_record",
    )
    if signature_asset:
        require(
            "licensed_supporting" not in source_kinds,
            f"{asset_id}: signature assets may not use licensed-supporting content",
        )
        require(
            "placeholder" not in source_kinds,
            f"{asset_id}: signature assets may not use placeholder content",
        )
    if "licensed_transformed" in source_kinds or "licensed_supporting" in source_kinds:
        require(
            provenance["raw_public_distribution"] == "license_dependent",
            f"{asset_id}: licensed sources require license-dependent distribution",
        )
        require(
            provenance["third_party_ai_input"] != "not_applicable",
            f"{asset_id}: licensed sources require an explicit AI-input rule",
        )


def validate_entry(entry: Any, index: int) -> str:
    prefix = f"entries[{index}]"
    require(isinstance(entry, dict), f"{prefix} must be an object")
    missing = REQUIRED_ENTRY_FIELDS - entry.keys()
    require(not missing, f"{prefix} missing fields: {sorted(missing)}")
    unexpected = set(entry) - REQUIRED_ENTRY_FIELDS
    require(not unexpected, f"{prefix} has unexpected fields: {sorted(unexpected)}")

    asset_id = nonempty_text(entry["asset_id"], f"{prefix}.asset_id")
    match = ID_PATTERN.fullmatch(asset_id)
    require(match is not None, f"{asset_id}: invalid asset id")
    category = entry["category"]
    require(
        category == PREFIX_CATEGORY[match.group(1)],
        f"{asset_id}: category does not match id prefix",
    )
    nonempty_text(entry["title"], f"{asset_id}.title")

    signature_asset = entry["signature_asset"]
    require(isinstance(signature_asset, bool), f"{asset_id}: signature_asset must be boolean")
    tier = entry["originality_tier"]
    require(tier in ALLOWED_TIERS, f"{asset_id}: invalid originality tier")
    if signature_asset:
        require(tier == "A", f"{asset_id}: signature assets must remain Tier A")

    require(entry["priority"] in ALLOWED_PRIORITIES, f"{asset_id}: invalid priority")
    status = entry["status"]
    require(status in ALLOWED_STATUSES, f"{asset_id}: invalid status")
    require(
        status not in {"production_candidate", "approved"},
        f"{asset_id}: design-only manifest may not approve production audio",
    )

    privacy_class = entry["privacy_class"]
    require(privacy_class in ALLOWED_PRIVACY, f"{asset_id}: invalid privacy class")
    gameplay_information = entry["gameplay_information"]
    require(
        gameplay_information in ALLOWED_INFORMATION,
        f"{asset_id}: invalid gameplay-information class",
    )

    stages = unique_text_list(entry["stages"], f"{asset_id}.stages")
    require(set(stages).issubset(ALLOWED_STAGES), f"{asset_id}: invalid stage")
    nonempty_text(entry["trigger"], f"{asset_id}.trigger")
    nonempty_text(entry["purpose"], f"{asset_id}.purpose")

    loop_mode = entry["loop_mode"]
    require(loop_mode in ALLOWED_LOOPS, f"{asset_id}: invalid loop mode")
    validate_duration(asset_id, entry["duration"], loop_mode)

    spatial_mode = entry["spatial_mode"]
    require(spatial_mode in ALLOWED_SPATIAL, f"{asset_id}: invalid spatial mode")
    require(
        entry["source_channel_layout"] in ALLOWED_CHANNELS,
        f"{asset_id}: invalid channel layout",
    )
    profiles = unique_text_list(
        entry["presentation_profiles"],
        f"{asset_id}.presentation_profiles",
    )
    require(set(profiles).issubset(ALLOWED_PROFILES), f"{asset_id}: invalid profile")

    unique_text_list(entry["layers"], f"{asset_id}.layers")
    unique_text_list(entry["sonic_requirements"], f"{asset_id}.sonic_requirements")
    unique_text_list(entry["negative_constraints"], f"{asset_id}.negative_constraints")

    validate_mix(asset_id, entry["mix_policy"], category)
    validate_accessibility(asset_id, entry["accessibility"], gameplay_information)
    validate_generator_guidance(asset_id, entry["generator_guidance"])
    validate_provenance(asset_id, entry["provenance_policy"], signature_asset)
    nonempty_text(entry["approval_boundary"], f"{asset_id}.approval_boundary")

    if privacy_class == "private_surface_deferred":
        require(
            spatial_mode == "private_surface_deferred",
            f"{asset_id}: deferred private audio must use private_surface_deferred spatial mode",
        )
        require(
            status == "deferred",
            f"{asset_id}: private-surface audio must remain deferred in P0.4",
        )
    else:
        require(
            spatial_mode != "private_surface_deferred",
            f"{asset_id}: public or diagnostic audio may not use private-surface spatial mode",
        )

    if category == "ambience":
        require(loop_mode != "none", f"{asset_id}: ambience must be looped or layered")
    else:
        require(loop_mode == "none", f"{asset_id}: one-shot category must not loop")

    if category in {"system", "ui"}:
        require(
            entry["source_channel_layout"] == "mono",
            f"{asset_id}: system and UI cues must use mono source layout",
        )
        require(
            spatial_mode == "global_nonspatial",
            f"{asset_id}: system and UI cues must be global nonspatial",
        )

    return asset_id


def read_manifest(path: Path) -> dict[str, Any]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise AudioAssetValidationError(f"manifest not found: {path}") from exc
    except json.JSONDecodeError as exc:
        raise AudioAssetValidationError(f"invalid JSON in {path}: {exc}") from exc
    require(isinstance(data, dict), f"manifest root must be an object: {path}")
    return data


def discover_default_manifests() -> tuple[Path, ...]:
    paths = tuple(sorted(DEFAULT_AUDIO_DIR.glob(DEFAULT_MANIFEST_PATTERN)))
    require(bool(paths), "no governed audio asset manifests found")
    return paths


def validate_manifest(data: Any) -> tuple[str, int, set[str]]:
    require(isinstance(data, dict), "manifest root must be an object")
    require(
        data.get("manifest_kind") == "audio_asset_briefs_preproduction",
        "unexpected manifest_kind",
    )
    require(data.get("schema_version") == 1, "unsupported schema_version")
    require(data.get("tale_id") == "drowned_harbor", "unexpected tale_id")
    require(
        data.get("production_status") == "design_only",
        "production_status must remain design_only",
    )
    entry_schema = nonempty_text(data.get("entry_schema"), "entry_schema")

    entries = data.get("entries")
    require(isinstance(entries, list) and entries, "entries must be a non-empty list")
    ids: set[str] = set()
    for index, entry in enumerate(entries):
        asset_id = validate_entry(entry, index)
        require(asset_id not in ids, f"duplicate asset id: {asset_id}")
        ids.add(asset_id)
    return entry_schema, len(entries), ids


def validate_manifests(paths: Sequence[Path]) -> tuple[int, int]:
    require(bool(paths), "at least one audio manifest is required")
    global_ids: dict[str, Path] = {}
    total_entries = 0
    schema_name: str | None = None

    for path in paths:
        data = read_manifest(path)
        current_schema, count, ids = validate_manifest(data)
        if schema_name is None:
            schema_name = current_schema
        require(
            current_schema == schema_name,
            f"{path}: all manifests must use the same entry schema",
        )
        for asset_id in ids:
            prior = global_ids.get(asset_id)
            require(
                prior is None,
                f"duplicate asset id across manifests: {asset_id} ({prior} and {path})",
            )
            global_ids[asset_id] = path
        total_entries += count

    return len(paths), total_entries


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "manifests",
        nargs="*",
        type=Path,
        help="One or more governed audio manifest paths.",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    paths = tuple(args.manifests) if args.manifests else discover_default_manifests()
    try:
        manifest_count, entry_count = validate_manifests(paths)
    except AudioAssetValidationError as exc:
        print(f"Audio asset validation failed: {exc}", file=sys.stderr)
        return 1
    print(
        f"Validated {entry_count} governed audio briefs "
        f"across {manifest_count} manifest(s)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
