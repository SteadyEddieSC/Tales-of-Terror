#!/usr/bin/env python3
"""Validate governed preproduction dialogue catalogs without third-party packages."""

from __future__ import annotations

import argparse
import json
import re
import string
import sys
from pathlib import Path
from typing import Any, Iterable

DEFAULT_CATALOG = Path(
    "docs/tales/drowned_harbor/dialogue/drowned_harbor_dialogue_en_v1.json"
)

KEY_PATTERN = re.compile(
    r"^(?:tale\.drowned_harbor|system\.seat_control|system\.admission|"
    r"private\.seat_control)\.[a-z0-9_]+(?:\.[a-z0-9_]+)*$"
)

ALLOWED_FUNCTIONS = {
    "welcome",
    "opening",
    "briefing",
    "stage_transition",
    "choice_prompt",
    "choice_confirmation",
    "accepted_action",
    "rejected_action",
    "warning",
    "hint",
    "director_pressure",
    "director_relief",
    "terror_turn",
    "reveal",
    "transformation",
    "defeat",
    "afterlife_activation",
    "seat_departure",
    "surrogate_activation",
    "seat_takeover",
    "seat_return",
    "admission",
    "spectator",
    "ending",
    "rematch",
    "closure",
}

ALLOWED_CLASSIFICATIONS = {
    "public",
    "controlled_reveal_private",
    "seat_private",
    "faction_private",
    "diagnostic_only",
}

ALLOWED_SPEAKERS = {"underteller", "plain_system"}
ALLOWED_PROFILES = {"spooky", "grim", "gore_and_dread"}
ALLOWED_REPEAT_CLASSES = {
    "unique_per_tale",
    "unique_per_stage",
    "rare",
    "reusable",
    "system_repeatable",
}
ALLOWED_PLACEHOLDER_TYPES = {
    "stable_seat_label",
    "public_item_name",
    "public_space_name",
    "public_route_name",
    "public_condition_name",
    "nonnegative_integer",
    "governed_public_text",
}
ALLOWED_PLACEHOLDER_VISIBILITY = {"public_safe", "authorized_private_only"}
ALLOWED_STATUSES = {
    "preproduction_draft",
    "narrative_reviewed",
    "mechanical_reviewed",
    "localization_ready",
    "production_candidate",
    "approved",
}

REQUIRED_ENTRY_FIELDS = {
    "key",
    "function",
    "classification",
    "speaker",
    "public_trigger",
    "required_facts",
    "variants",
    "fallback",
    "display_budget",
    "voice_budget",
    "repeat_policy",
    "placeholders",
    "implementation_status",
}

FORBIDDEN_PUBLIC_PLACEHOLDER_NAMES = {
    "account",
    "email",
    "username",
    "device",
    "device_name",
    "hidden_role",
    "hidden_faction",
    "private_objective",
    "private_target",
    "real_name",
}


class DialogueValidationError(ValueError):
    """Raised when a catalog violates the preproduction dialogue contract."""


def _require(condition: bool, message: str) -> None:
    if not condition:
        raise DialogueValidationError(message)


def _nonempty_string(value: Any, field: str) -> str:
    _require(isinstance(value, str) and bool(value.strip()), f"{field} must be non-empty text")
    return value


def _extract_placeholders(text: str) -> set[str]:
    formatter = string.Formatter()
    names: set[str] = set()
    try:
        for _, field_name, _, _ in formatter.parse(text):
            if field_name is None:
                continue
            _require(
                re.fullmatch(r"[a-z][a-z0-9_]*", field_name) is not None,
                f"unsupported placeholder expression {{{field_name}}}",
            )
            names.add(field_name)
    except ValueError as exc:
        raise DialogueValidationError(f"invalid placeholder formatting: {exc}") from exc
    return names


def _all_text_fields(entry: dict[str, Any]) -> Iterable[tuple[str, str]]:
    for profile, text in entry["variants"].items():
        yield f"variants.{profile}", text
    yield "fallback", entry["fallback"]
    if "plain_system_equivalent" in entry:
        yield "plain_system_equivalent", entry["plain_system_equivalent"]


def validate_entry(entry: Any, index: int) -> None:
    prefix = f"entries[{index}]"
    _require(isinstance(entry, dict), f"{prefix} must be an object")

    missing = REQUIRED_ENTRY_FIELDS - entry.keys()
    _require(not missing, f"{prefix} is missing fields: {sorted(missing)}")

    key = _nonempty_string(entry["key"], f"{prefix}.key")
    _require(KEY_PATTERN.fullmatch(key) is not None, f"{prefix}.key has an invalid format: {key}")
    _require(entry["function"] in ALLOWED_FUNCTIONS, f"{key}: unsupported function")
    classification = entry["classification"]
    _require(classification in ALLOWED_CLASSIFICATIONS, f"{key}: unsupported classification")
    _require(entry["speaker"] in ALLOWED_SPEAKERS, f"{key}: unsupported speaker")
    _nonempty_string(entry["public_trigger"], f"{key}.public_trigger")

    required_facts = entry["required_facts"]
    _require(isinstance(required_facts, list) and required_facts, f"{key}: required_facts must be a non-empty list")
    _require(len(set(required_facts)) == len(required_facts), f"{key}: required_facts contains duplicates")
    for fact_index, fact in enumerate(required_facts):
        _nonempty_string(fact, f"{key}.required_facts[{fact_index}]")

    variants = entry["variants"]
    _require(isinstance(variants, dict), f"{key}: variants must be an object")
    _require(set(variants) == ALLOWED_PROFILES, f"{key}: variants must contain exactly {sorted(ALLOWED_PROFILES)}")
    for profile, text in variants.items():
        _nonempty_string(text, f"{key}.variants.{profile}")
    _nonempty_string(entry["fallback"], f"{key}.fallback")

    display = entry["display_budget"]
    _require(isinstance(display, dict), f"{key}: display_budget must be an object")
    _require(
        set(display) == {"max_characters", "max_lines", "skippable"},
        f"{key}: display_budget has unexpected fields",
    )
    max_characters = display["max_characters"]
    max_lines = display["max_lines"]
    _require(isinstance(max_characters, int) and 1 <= max_characters <= 600, f"{key}: invalid max_characters")
    _require(isinstance(max_lines, int) and 1 <= max_lines <= 12, f"{key}: invalid max_lines")
    _require(isinstance(display["skippable"], bool), f"{key}: skippable must be boolean")

    voice = entry["voice_budget"]
    _require(isinstance(voice, dict), f"{key}: voice_budget must be an object")
    _require(set(voice) == {"target_seconds", "maximum_seconds"}, f"{key}: voice_budget has unexpected fields")
    target_seconds = voice["target_seconds"]
    maximum_seconds = voice["maximum_seconds"]
    _require(isinstance(target_seconds, (int, float)) and target_seconds >= 0.5, f"{key}: invalid target_seconds")
    _require(isinstance(maximum_seconds, (int, float)) and maximum_seconds >= target_seconds, f"{key}: maximum_seconds must be at least target_seconds")
    _require(maximum_seconds <= 180, f"{key}: maximum_seconds exceeds contract")

    repeat = entry["repeat_policy"]
    _require(isinstance(repeat, dict), f"{key}: repeat_policy must be an object")
    _require(set(repeat) == {"class", "minimum_cooldown_events"}, f"{key}: repeat_policy has unexpected fields")
    _require(repeat["class"] in ALLOWED_REPEAT_CLASSES, f"{key}: unsupported repeat class")
    cooldown = repeat["minimum_cooldown_events"]
    _require(isinstance(cooldown, int) and 0 <= cooldown <= 1000, f"{key}: invalid cooldown")

    placeholders = entry["placeholders"]
    _require(isinstance(placeholders, list), f"{key}: placeholders must be a list")
    declared_names: set[str] = set()
    for placeholder_index, placeholder in enumerate(placeholders):
        field = f"{key}.placeholders[{placeholder_index}]"
        _require(isinstance(placeholder, dict), f"{field} must be an object")
        _require(set(placeholder) == {"name", "type", "visibility"}, f"{field} has unexpected fields")
        name = _nonempty_string(placeholder["name"], f"{field}.name")
        _require(re.fullmatch(r"[a-z][a-z0-9_]*", name) is not None, f"{field}.name has invalid format")
        _require(name not in declared_names, f"{key}: duplicate placeholder {name}")
        _require(placeholder["type"] in ALLOWED_PLACEHOLDER_TYPES, f"{field}: unsupported type")
        visibility = placeholder["visibility"]
        _require(visibility in ALLOWED_PLACEHOLDER_VISIBILITY, f"{field}: unsupported visibility")
        if classification == "public":
            _require(visibility == "public_safe", f"{key}: public entries may use only public-safe placeholders")
            _require(name not in FORBIDDEN_PUBLIC_PLACEHOLDER_NAMES, f"{key}: forbidden public placeholder {name}")
        declared_names.add(name)

    used_names: set[str] = set()
    for field, text in _all_text_fields(entry):
        _nonempty_string(text, f"{key}.{field}")
        _require(len(text) <= max_characters, f"{key}.{field} exceeds max_characters ({len(text)} > {max_characters})")
        _require(text.count("\n") + 1 <= max_lines, f"{key}.{field} exceeds max_lines")
        used_names.update(_extract_placeholders(text))

    _require(used_names == declared_names, f"{key}: placeholder mismatch; declared={sorted(declared_names)} used={sorted(used_names)}")
    _require(entry["implementation_status"] in ALLOWED_STATUSES, f"{key}: unsupported implementation_status")

    if classification == "controlled_reveal_private":
        _require(entry["speaker"] == "plain_system", f"{key}: controlled private handoff must use plain_system")
        _require(not display["skippable"], f"{key}: controlled private handoff may not be skippable")


def validate_catalog(data: Any) -> None:
    _require(isinstance(data, dict), "catalog root must be an object")
    _require(data.get("catalog_kind") == "governed_dialogue_preproduction", "unexpected catalog_kind")
    _require(data.get("schema_version") == 1, "unsupported schema_version")
    _require(data.get("locale") == "en-US", "initial catalog locale must be en-US")
    _require(data.get("tale_id") == "drowned_harbor", "unexpected tale_id")
    _require(data.get("production_status") == "design_only", "production_status must remain design_only")

    entries = data.get("entries")
    _require(isinstance(entries, list) and entries, "entries must be a non-empty list")

    keys: set[str] = set()
    for index, entry in enumerate(entries):
        validate_entry(entry, index)
        key = entry["key"]
        _require(key not in keys, f"duplicate dialogue key: {key}")
        keys.add(key)


def load_and_validate(path: Path) -> dict[str, Any]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise DialogueValidationError(f"catalog not found: {path}") from exc
    except json.JSONDecodeError as exc:
        raise DialogueValidationError(f"invalid JSON in {path}: {exc}") from exc
    validate_catalog(data)
    return data


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("catalog", nargs="?", type=Path, default=DEFAULT_CATALOG)
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    try:
        data = load_and_validate(args.catalog)
    except DialogueValidationError as exc:
        print(f"Dialogue validation failed: {exc}", file=sys.stderr)
        return 1
    print(f"Validated {len(data['entries'])} governed dialogue entries in {args.catalog}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
