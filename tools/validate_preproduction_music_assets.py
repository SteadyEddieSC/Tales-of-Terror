#!/usr/bin/env python3
"""Validate governed Drowned Harbor preproduction music briefs."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any, Sequence

DEFAULT_MUSIC_DIR = Path("docs/tales/drowned_harbor/music")
DEFAULT_PATTERN = "drowned_harbor_music_*_briefs_v1.json"

ID_PATTERN = re.compile(r"^DH-MUS-(CUE|STM|TRN|END)-[0-9]{3}$")
PREFIX_CATEGORY = {
    "CUE": "cue",
    "STM": "adaptive_stem",
    "TRN": "transition",
    "END": "ending_treatment",
}
ALLOWED_STATUS = {
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
ALLOWED_STAGE = {
    "low_tide_arrival",
    "bellhouse_ledger",
    "lighthouse_council",
    "high_water",
    "last_light",
    "ending_resolution",
    "reusable_system",
}
ALLOWED_LOOP = {"none", "seamless_loop", "adaptive_loop_family", "phrase_bound"}
ALLOWED_PROFILE = {"spooky", "grim", "gore_and_dread", "profile_neutral"}
ALLOWED_MOTIF = {
    "harbor_memory",
    "lighthouse_destination",
    "bellhouse_index",
    "living_witness",
    "drowned_release",
    "harbor_propagation",
    "none",
}
ALLOWED_STEM = {
    "foundation",
    "memory",
    "witness",
    "mechanism",
    "pressure",
    "transformation",
    "resolution",
}
ALLOWED_SOURCE = {
    "original_human_composition",
    "original_performance",
    "original_synthesis",
    "original_ai_assisted",
    "commissioned",
    "licensed_transformed",
    "licensed_supporting",
    "placeholder",
}
PRIVATE_INPUT_MARKERS = {
    "hidden faction",
    "private objective",
    "private bargain",
    "private inventory",
    "latent transformation",
    "unrevealed infection",
    "unrevealed mark",
    "hidden director",
    "private route",
    "future random",
    "unrevealed ending",
    "private vote",
    "future ending",
}
IMITATION_PHRASES = {
    "in the style of",
    "exactly like",
    "copy the music",
    "replicate the soundtrack",
    "sound exactly like",
    "imitate the composer",
}
REQUIRED_FIELDS = {
    "asset_id",
    "title",
    "category",
    "signature_asset",
    "originality_tier",
    "priority",
    "status",
    "stages",
    "public_state_inputs",
    "forbidden_private_inputs",
    "purpose",
    "duration",
    "loop_mode",
    "tempo_behavior",
    "meter_behavior",
    "harmonic_behavior",
    "motif_families",
    "instrumentation",
    "stem_architecture",
    "transition_policy",
    "dialogue_policy",
    "presentation_profiles",
    "accessibility",
    "generator_guidance",
    "provenance_policy",
    "approval_boundary",
}


class MusicValidationError(ValueError):
    """Raised when a music brief violates the preproduction contract."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise MusicValidationError(message)


def text(value: Any, field: str, minimum: int = 1) -> str:
    require(isinstance(value, str), f"{field} must be text")
    stripped = value.strip()
    require(len(stripped) >= minimum, f"{field} must contain at least {minimum} characters")
    return stripped


def text_list(value: Any, field: str, minimum: int = 1) -> list[str]:
    require(isinstance(value, list), f"{field} must be a list")
    require(len(value) >= minimum, f"{field} must contain at least {minimum} item(s)")
    require(all(isinstance(item, str) and item.strip() for item in value), f"{field} must contain non-empty text")
    require(len(value) == len(set(value)), f"{field} contains duplicates")
    return value


def validate_duration(asset_id: str, value: Any, loop_mode: str) -> None:
    require(isinstance(value, dict), f"{asset_id}: duration must be an object")
    require(set(value) == {"minimum_seconds", "target_seconds", "maximum_seconds"}, f"{asset_id}: invalid duration fields")
    minimum = value["minimum_seconds"]
    target = value["target_seconds"]
    maximum = value["maximum_seconds"]
    for name, number in value.items():
        require(isinstance(number, (int, float)) and not isinstance(number, bool), f"{asset_id}: {name} must be numeric")
        require(0.5 <= number <= 1200, f"{asset_id}: {name} outside allowed range")
    require(minimum <= target <= maximum, f"{asset_id}: duration ordering is invalid")
    if loop_mode != "none":
        require(target >= 30, f"{asset_id}: looped or phrase-bound music requires at least 30 target seconds")


def validate_stems(asset_id: str, value: Any, category: str) -> None:
    require(isinstance(value, dict), f"{asset_id}: stem_architecture must be an object")
    expected = {"required_stems", "optional_stems", "reduced_density_removals", "contains_critical_sfx"}
    require(set(value) == expected, f"{asset_id}: invalid stem_architecture fields")
    required = text_list(value["required_stems"], f"{asset_id}.required_stems")
    optional = text_list(value["optional_stems"], f"{asset_id}.optional_stems", minimum=0)
    removals = text_list(value["reduced_density_removals"], f"{asset_id}.reduced_density_removals", minimum=0)
    require(set(required).issubset(ALLOWED_STEM), f"{asset_id}: unsupported required stem")
    require(set(optional).issubset(ALLOWED_STEM), f"{asset_id}: unsupported optional stem")
    require(not set(required).intersection(optional), f"{asset_id}: required and optional stems overlap")
    require(set(removals).issubset(set(required).union(optional)), f"{asset_id}: reduced-density removals reference unavailable stems")
    require(value["contains_critical_sfx"] is False, f"{asset_id}: music may not contain critical SFX")
    if category == "adaptive_stem":
        require(required == ["pressure"] or set(required) == {"pressure"}, f"{asset_id}: adaptive pressure stem family must require pressure stem")


def validate_transition(asset_id: str, value: Any) -> None:
    require(isinstance(value, dict), f"{asset_id}: transition_policy must be an object")
    expected = {"entry", "exit", "silence_allowed", "deterministic_replay_required"}
    require(set(value) == expected, f"{asset_id}: invalid transition_policy fields")
    text(value["entry"], f"{asset_id}.transition.entry", 12)
    text(value["exit"], f"{asset_id}.transition.exit", 12)
    require(value["silence_allowed"] is True, f"{asset_id}: silence must remain allowed")
    require(value["deterministic_replay_required"] is True, f"{asset_id}: deterministic replay is required")


def validate_dialogue(asset_id: str, value: Any) -> None:
    require(isinstance(value, dict), f"{asset_id}: dialogue_policy must be an object")
    expected = {"duck_under_dialogue", "may_drop_to_foundation", "may_cut_to_silence", "midrange_density_limit"}
    require(set(value) == expected, f"{asset_id}: invalid dialogue_policy fields")
    require(value["duck_under_dialogue"] is True, f"{asset_id}: music must duck under dialogue")
    require(isinstance(value["may_drop_to_foundation"], bool), f"{asset_id}: may_drop_to_foundation must be boolean")
    require(value["may_cut_to_silence"] is True, f"{asset_id}: music must be able to cut to silence")
    text(value["midrange_density_limit"], f"{asset_id}.dialogue.midrange_density_limit", 20)


def validate_accessibility(asset_id: str, value: Any) -> None:
    require(isinstance(value, dict), f"{asset_id}: accessibility must be an object")
    expected = {"music_off_safe", "mono_safe", "reduced_density_supported", "reduced_dynamics_behavior", "contains_required_gameplay_information"}
    require(set(value) == expected, f"{asset_id}: invalid accessibility fields")
    require(value["music_off_safe"] is True, f"{asset_id}: music-off mode must remain safe")
    require(value["mono_safe"] is True, f"{asset_id}: music must remain mono safe")
    require(value["reduced_density_supported"] is True, f"{asset_id}: reduced-density mode is required")
    require(value["contains_required_gameplay_information"] is False, f"{asset_id}: music may not contain required gameplay information")
    text(value["reduced_dynamics_behavior"], f"{asset_id}.accessibility.reduced_dynamics_behavior", 20)


def validate_generator(asset_id: str, value: Any) -> None:
    require(isinstance(value, dict), f"{asset_id}: generator_guidance must be an object")
    expected = {"prompt", "negative_prompt", "consistency_anchor", "human_edit_plan"}
    require(set(value) == expected, f"{asset_id}: invalid generator_guidance fields")
    prompt = text(value["prompt"], f"{asset_id}.generator.prompt", 80)
    negative = text(value["negative_prompt"], f"{asset_id}.generator.negative_prompt", 40)
    text(value["consistency_anchor"], f"{asset_id}.generator.consistency_anchor", 40)
    text(value["human_edit_plan"], f"{asset_id}.generator.human_edit_plan", 40)
    lowered = prompt.lower()
    for phrase in IMITATION_PHRASES:
        require(phrase not in lowered, f"{asset_id}: disallowed imitation phrase: {phrase}")
    require("named composer imitation" in negative.lower(), f"{asset_id}: negative prompt must reject named-composer imitation")


def validate_provenance(asset_id: str, value: Any, signature: bool) -> None:
    require(isinstance(value, dict), f"{asset_id}: provenance_policy must be an object")
    expected = {"allowed_source_kinds", "content_id_policy", "raw_public_distribution", "third_party_ai_input", "required_record"}
    require(set(value) == expected, f"{asset_id}: invalid provenance_policy fields")
    sources = text_list(value["allowed_source_kinds"], f"{asset_id}.allowed_source_kinds")
    require(set(sources).issubset(ALLOWED_SOURCE), f"{asset_id}: unsupported source kind")
    require(value["content_id_policy"] == "prohibited", f"{asset_id}: Content ID registration is prohibited in P0.5")
    require(value["raw_public_distribution"] in {"allowed", "prohibited", "license_dependent"}, f"{asset_id}: invalid distribution policy")
    require(value["third_party_ai_input"] in {"prohibited", "explicit_permission_required", "not_applicable"}, f"{asset_id}: invalid third-party AI input policy")
    text_list(value["required_record"], f"{asset_id}.required_record", minimum=5)
    if signature:
        require("licensed_supporting" not in sources, f"{asset_id}: signature music may not use licensed-supporting content")
        require("placeholder" not in sources, f"{asset_id}: signature music may not use placeholder content")
    if "licensed_transformed" in sources or "licensed_supporting" in sources:
        require(value["raw_public_distribution"] == "license_dependent", f"{asset_id}: licensed sources require license-dependent distribution")
        require(value["third_party_ai_input"] == "explicit_permission_required", f"{asset_id}: licensed sources require explicit AI-input permission")


def validate_entry(entry: Any, index: int) -> str:
    require(isinstance(entry, dict), f"entries[{index}] must be an object")
    missing = REQUIRED_FIELDS - entry.keys()
    unexpected = set(entry) - REQUIRED_FIELDS
    require(not missing, f"entries[{index}] missing fields: {sorted(missing)}")
    require(not unexpected, f"entries[{index}] unexpected fields: {sorted(unexpected)}")

    asset_id = text(entry["asset_id"], f"entries[{index}].asset_id")
    match = ID_PATTERN.fullmatch(asset_id)
    require(match is not None, f"{asset_id}: invalid asset ID")
    category = entry["category"]
    require(category == PREFIX_CATEGORY[match.group(1)], f"{asset_id}: category does not match ID prefix")
    text(entry["title"], f"{asset_id}.title")
    require(isinstance(entry["signature_asset"], bool), f"{asset_id}: signature_asset must be boolean")
    require(entry["originality_tier"] in {"A", "B", "C", "D"}, f"{asset_id}: invalid originality tier")
    if entry["signature_asset"]:
        require(entry["originality_tier"] == "A", f"{asset_id}: signature music must remain Tier A")
    require(entry["priority"] in {"P0", "P1", "P2", "P3"}, f"{asset_id}: invalid priority")
    require(entry["status"] in ALLOWED_STATUS, f"{asset_id}: invalid status")
    require(entry["status"] not in {"production_candidate", "approved"}, f"{asset_id}: design-only package may not approve production music")

    stages = text_list(entry["stages"], f"{asset_id}.stages")
    require(set(stages).issubset(ALLOWED_STAGE), f"{asset_id}: unsupported stage")
    public_inputs = text_list(entry["public_state_inputs"], f"{asset_id}.public_state_inputs", minimum=2)
    forbidden_inputs = text_list(entry["forbidden_private_inputs"], f"{asset_id}.forbidden_private_inputs", minimum=3)
    public_text = " ".join(public_inputs).lower()
    for marker in PRIVATE_INPUT_MARKERS:
        require(marker not in public_text, f"{asset_id}: private-state marker declared as public input: {marker}")
    require(any("private" in item.lower() or "hidden" in item.lower() or "unrevealed" in item.lower() or "latent" in item.lower() for item in forbidden_inputs), f"{asset_id}: forbidden inputs must explicitly cover private or hidden state")

    text(entry["purpose"], f"{asset_id}.purpose", 30)
    loop_mode = entry["loop_mode"]
    require(loop_mode in ALLOWED_LOOP, f"{asset_id}: invalid loop mode")
    validate_duration(asset_id, entry["duration"], loop_mode)
    if category == "ending_treatment":
        require(loop_mode == "none", f"{asset_id}: ending treatments must not loop")
        require(stages == ["ending_resolution"], f"{asset_id}: ending treatments must use ending_resolution stage only")
    if category == "adaptive_stem":
        require(loop_mode == "adaptive_loop_family", f"{asset_id}: adaptive stems must use adaptive_loop_family")

    text(entry["tempo_behavior"], f"{asset_id}.tempo_behavior", 20)
    text(entry["meter_behavior"], f"{asset_id}.meter_behavior", 20)
    text(entry["harmonic_behavior"], f"{asset_id}.harmonic_behavior", 20)
    motifs = text_list(entry["motif_families"], f"{asset_id}.motif_families")
    require(set(motifs).issubset(ALLOWED_MOTIF), f"{asset_id}: unsupported motif family")
    if "none" in motifs:
        require(motifs == ["none"], f"{asset_id}: none motif may not be combined with named motifs")
    text_list(entry["instrumentation"], f"{asset_id}.instrumentation", minimum=2)
    validate_stems(asset_id, entry["stem_architecture"], category)
    validate_transition(asset_id, entry["transition_policy"])
    validate_dialogue(asset_id, entry["dialogue_policy"])
    profiles = text_list(entry["presentation_profiles"], f"{asset_id}.presentation_profiles")
    require(set(profiles).issubset(ALLOWED_PROFILE), f"{asset_id}: unsupported presentation profile")
    validate_accessibility(asset_id, entry["accessibility"])
    validate_generator(asset_id, entry["generator_guidance"])
    validate_provenance(asset_id, entry["provenance_policy"], entry["signature_asset"])
    text(entry["approval_boundary"], f"{asset_id}.approval_boundary", 30)
    return asset_id


def read_manifest(path: Path) -> dict[str, Any]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise MusicValidationError(f"manifest not found: {path}") from exc
    except json.JSONDecodeError as exc:
        raise MusicValidationError(f"invalid JSON in {path}: {exc}") from exc
    require(isinstance(data, dict), f"manifest root must be an object: {path}")
    return data


def discover_default_manifests() -> tuple[Path, ...]:
    paths = tuple(sorted(DEFAULT_MUSIC_DIR.glob(DEFAULT_PATTERN)))
    require(bool(paths), "no governed music manifests found")
    return paths


def validate_manifest(data: Any) -> tuple[str, int, set[str]]:
    require(isinstance(data, dict), "manifest root must be an object")
    require(data.get("manifest_kind") == "music_asset_briefs_preproduction", "unexpected manifest_kind")
    require(data.get("schema_version") == 1, "unsupported schema_version")
    require(data.get("tale_id") == "drowned_harbor", "unexpected tale_id")
    require(data.get("production_status") == "design_only", "production_status must remain design_only")
    schema_name = text(data.get("entry_schema"), "entry_schema")
    entries = data.get("entries")
    require(isinstance(entries, list) and entries, "entries must be a non-empty list")
    ids: set[str] = set()
    for index, entry in enumerate(entries):
        asset_id = validate_entry(entry, index)
        require(asset_id not in ids, f"duplicate asset ID: {asset_id}")
        ids.add(asset_id)
    return schema_name, len(entries), ids


def validate_manifests(paths: Sequence[Path]) -> tuple[int, int]:
    require(bool(paths), "at least one music manifest is required")
    global_ids: dict[str, Path] = {}
    total = 0
    schema_name: str | None = None
    for path in paths:
        current_schema, count, ids = validate_manifest(read_manifest(path))
        if schema_name is None:
            schema_name = current_schema
        require(current_schema == schema_name, f"{path}: manifests must share one entry schema")
        for asset_id in ids:
            require(asset_id not in global_ids, f"duplicate asset ID across manifests: {asset_id}")
            global_ids[asset_id] = path
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
        manifest_count, asset_count = validate_manifests(paths)
    except MusicValidationError as exc:
        print(f"Music asset validation failed: {exc}", file=sys.stderr)
        return 1
    print(f"Validated {asset_count} governed music briefs across {manifest_count} manifest(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
