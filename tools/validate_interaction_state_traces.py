#!/usr/bin/env python3
"""Validate Drowned Harbor P0.11 interaction-state traceability records."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any, Sequence

TRACE_DIR = Path("docs/tales/drowned_harbor/interaction")
TRACE_PATTERN = "drowned_harbor_interaction_*_traces_v1.json"
STORYBOARD_DIR = Path("docs/tales/drowned_harbor/ui")
STORYBOARD_PATTERN = "drowned_harbor_*_storyboards_v1.json"
TRACEABILITY_PATH = Path("docs/preproduction/drowned_harbor_cross_media_traceability_v1.json")

TRACE_ID_PATTERN = re.compile(r"^DH-IS-[0-9]{3}$")
STORYBOARD_ID_PATTERN = re.compile(r"^DH-UI-[0-9]{3}$")
CONCEPT_ID_PATTERN = re.compile(r"^DH-XM-[0-9]{3}$")
STABLE_KEY_PATTERN = re.compile(r"^[a-z][a-z0-9_]*$")

ALLOWED_DOMAINS = {
    "session_public",
    "board_public",
    "seat_public",
    "seat_private",
    "tale_public",
    "tale_private",
    "accessibility_public",
    "admission_public",
    "diagnostic_nonplayer",
}
PRIVATE_DOMAINS = {"seat_private", "tale_private"}
ALLOWED_ACTORS = {
    "host",
    "active_stable_seat",
    "specific_public_seat",
    "returning_reserved_controller",
    "approved_takeover_controller",
    "game_control",
    "spectator",
    "system",
}
ALLOWED_LIFECYCLE = {
    "eligible",
    "presented",
    "focused",
    "previewed",
    "confirming",
    "committed",
    "projected",
    "settled",
}
ALLOWED_PRIVACY = {
    "public_shared",
    "neutral_shared_shield",
    "controlled_private_surface",
}
ALLOWED_CONFIRMATION = {
    "acknowledgement_only",
    "confirmed_commitment",
    "hold_to_confirm",
    "host_approval",
    "none",
    "no_commit",
    "reversible_selection",
    "safe_handoff_confirmation",
}
ALLOWED_STATUS = {
    "brief_draft",
    "preproduction_ready",
    "implementation_planning_candidate",
    "implementation_authorized",
    "production_candidate",
    "approved",
    "rejected",
    "deferred",
}
PROHIBITED_STATUS = {
    "implementation_authorized",
    "production_candidate",
    "approved",
}
ALLOWED_IMPLEMENTATION_SEAMS = {
    "authoritative_state_reader",
    "legal_action_query",
    "command_validator",
    "deterministic_reducer",
    "public_projection_builder",
    "private_projection_builder",
    "focus_coordinator",
    "caption_transcript_adapter",
    "replay_adapter",
    "controller_authority_adapter",
    "admission_adapter",
    "diagnostic_recorder",
}
REQUIRED_FIELDS = {
    "trace_id",
    "title",
    "tale_id",
    "storyboard_id",
    "criticality",
    "privacy_surface",
    "read_domains",
    "write_domains",
    "allowed_actors",
    "entry_preconditions",
    "lifecycle_steps",
    "input_intents",
    "action_guards",
    "commit_contract",
    "projection_contract",
    "privacy_contract",
    "recovery_contract",
    "presentation_obligations",
    "implementation_seams",
    "source_paths",
    "traceability_concepts",
    "human_validation_questions",
    "status",
    "approval_boundary",
}


class InteractionTraceValidationError(ValueError):
    """Raised when a P0.11 interaction trace violates its contract."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise InteractionTraceValidationError(message)


def text(value: Any, field: str, minimum: int = 1) -> str:
    require(isinstance(value, str), f"{field} must be text")
    result = value.strip()
    require(len(result) >= minimum, f"{field} must contain at least {minimum} characters")
    return result


def unique_text_list(value: Any, field: str, minimum: int = 0) -> list[str]:
    require(isinstance(value, list), f"{field} must be a list")
    require(len(value) >= minimum, f"{field} must contain at least {minimum} item(s)")
    require(all(isinstance(item, str) and item.strip() for item in value), f"{field} must contain non-empty text")
    require(len(value) == len(set(value)), f"{field} contains duplicates")
    return value


def read_json(path: Path) -> dict[str, Any]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise InteractionTraceValidationError(f"file not found: {path}") from exc
    except json.JSONDecodeError as exc:
        raise InteractionTraceValidationError(f"invalid JSON in {path}: {exc}") from exc
    require(isinstance(data, dict), f"root must be an object: {path}")
    return data


def discover_traces() -> tuple[Path, ...]:
    paths = tuple(sorted(TRACE_DIR.glob(TRACE_PATTERN)))
    require(bool(paths), "no governed interaction trace manifests found")
    return paths


def discover_storyboards() -> tuple[Path, ...]:
    paths = tuple(sorted(STORYBOARD_DIR.glob(STORYBOARD_PATTERN)))
    require(bool(paths), "no governed storyboard manifests found")
    return paths


def load_storyboards(paths: Sequence[Path]) -> dict[str, dict[str, Any]]:
    records: dict[str, dict[str, Any]] = {}
    for path in paths:
        data = read_json(path)
        require(data.get("manifest_kind") == "shared_screen_storyboards_preproduction", f"unexpected storyboard manifest kind: {path}")
        require(data.get("production_status") == "design_only", f"storyboards must remain design_only: {path}")
        entries = data.get("entries")
        require(isinstance(entries, list) and entries, f"storyboard entries missing: {path}")
        for entry in entries:
            require(isinstance(entry, dict), f"storyboard entry must be an object: {path}")
            storyboard_id = text(entry.get("storyboard_id"), f"{path}.storyboard_id")
            require(STORYBOARD_ID_PATTERN.fullmatch(storyboard_id) is not None, f"invalid storyboard ID: {storyboard_id}")
            require(storyboard_id not in records, f"duplicate storyboard ID: {storyboard_id}")
            records[storyboard_id] = entry
    return records


def load_concepts(path: Path) -> set[str]:
    data = read_json(path)
    entries = data.get("entries")
    require(isinstance(entries, list), "cross-media traceability entries must be a list")
    concepts: set[str] = set()
    for entry in entries:
        require(isinstance(entry, dict), "cross-media traceability entry must be an object")
        concept_id = text(entry.get("concept_id"), "concept_id")
        require(CONCEPT_ID_PATTERN.fullmatch(concept_id) is not None, f"invalid concept ID: {concept_id}")
        require(concept_id not in concepts, f"duplicate concept ID: {concept_id}")
        concepts.add(concept_id)
    return concepts


def validate_repo_path(value: str, field: str) -> None:
    path = Path(value)
    require(not path.is_absolute(), f"{field} must be repository relative")
    require(".." not in path.parts, f"{field} may not escape the repository")
    require(path.is_file(), f"{field} does not exist: {value}")


def validate_rules(value: Any, field: str) -> None:
    require(isinstance(value, list) and value, f"{field} must be a non-empty list")
    ids: set[str] = set()
    for index, rule in enumerate(value):
        require(isinstance(rule, dict) and set(rule) == {"rule_id", "description"}, f"{field}[{index}] fields do not match contract")
        rule_id = text(rule["rule_id"], f"{field}[{index}].rule_id")
        require(STABLE_KEY_PATTERN.fullmatch(rule_id) is not None, f"{field}[{index}] has invalid rule_id")
        require(rule_id not in ids, f"{field} contains duplicate rule_id: {rule_id}")
        ids.add(rule_id)
        text(rule["description"], f"{field}[{index}].description", 12)


def validate_commit(trace_id: str, contract: Any) -> None:
    require(isinstance(contract, dict), f"{trace_id}: commit_contract must be an object")
    expected = {
        "authoritative_commit",
        "deterministic",
        "confirmation_revision_required",
        "partial_commit_prohibited",
        "once_only_transition",
        "retry_behavior",
    }
    require(set(contract) == expected, f"{trace_id}: commit_contract fields do not match contract")
    require(isinstance(contract["authoritative_commit"], bool), f"{trace_id}: authoritative_commit must be boolean")
    require(contract["deterministic"] is True, f"{trace_id}: interactions must be deterministic")
    require(isinstance(contract["confirmation_revision_required"], bool), f"{trace_id}: confirmation_revision_required must be boolean")
    require(contract["partial_commit_prohibited"] is True, f"{trace_id}: partial commit must be prohibited")
    require(isinstance(contract["once_only_transition"], bool), f"{trace_id}: once_only_transition must be boolean")
    require(contract["retry_behavior"] in {"no_authoritative_change", "reproject_existing_result", "requery_and_present_current_state"}, f"{trace_id}: invalid retry behavior")


def validate_projection(trace_id: str, projection: Any, authoritative_commit: bool) -> None:
    require(isinstance(projection, dict), f"{trace_id}: projection_contract must be an object")
    expected = {
        "public_outputs",
        "private_outputs",
        "emitted_events",
        "public_payload_private_data_prohibited",
        "projection_after_authoritative_commit",
    }
    require(set(projection) == expected, f"{trace_id}: projection_contract fields do not match contract")
    unique_text_list(projection["public_outputs"], f"{trace_id}.public_outputs", minimum=1)
    unique_text_list(projection["private_outputs"], f"{trace_id}.private_outputs", minimum=0)
    require(projection["public_payload_private_data_prohibited"] is True, f"{trace_id}: public payload must prohibit private data")
    require(projection["projection_after_authoritative_commit"] is True, f"{trace_id}: projection must follow authoritative state")
    events = projection["emitted_events"]
    require(isinstance(events, list) and events, f"{trace_id}: at least one event is required")
    event_keys: set[str] = set()
    exactly_once = False
    for index, event in enumerate(events):
        require(isinstance(event, dict), f"{trace_id}: emitted_events[{index}] must be an object")
        expected_event = {
            "event_key",
            "classification",
            "exactly_once",
            "idempotent_reprojection",
            "includes_source_revision",
            "includes_result_revision",
            "raw_identity_prohibited",
        }
        require(set(event) == expected_event, f"{trace_id}: emitted_events[{index}] fields do not match contract")
        key = text(event["event_key"], f"{trace_id}.event_key")
        require(STABLE_KEY_PATTERN.fullmatch(key) is not None, f"{trace_id}: invalid event key")
        require(key not in event_keys, f"{trace_id}: duplicate event key: {key}")
        event_keys.add(key)
        require(event["classification"] in {"public", "private", "diagnostic"}, f"{trace_id}: invalid event classification")
        require(isinstance(event["exactly_once"], bool), f"{trace_id}: exactly_once must be boolean")
        exactly_once = exactly_once or event["exactly_once"]
        for field in ("idempotent_reprojection", "includes_source_revision", "includes_result_revision", "raw_identity_prohibited"):
            require(event[field] is True, f"{trace_id}: event {field} must be true")
    if authoritative_commit:
        require(exactly_once, f"{trace_id}: authoritative commits require an exactly-once event")


def validate_privacy(trace_id: str, privacy_surface: str, read_domains: set[str], projection: dict[str, Any], privacy: Any) -> None:
    require(isinstance(privacy, dict), f"{trace_id}: privacy_contract must be an object")
    expected = {
        "public_shared_content",
        "private_content",
        "neutral_shield_required",
        "authorized_private_actor_required",
        "private_clearing_rule",
        "public_transcript_private_content_prohibited",
        "public_audio_private_content_prohibited",
        "mirrored_private_content_prohibited",
    }
    require(set(privacy) == expected, f"{trace_id}: privacy_contract fields do not match contract")
    unique_text_list(privacy["public_shared_content"], f"{trace_id}.public_shared_content", minimum=1)
    private_content = unique_text_list(privacy["private_content"], f"{trace_id}.private_content", minimum=0)
    text(privacy["private_clearing_rule"], f"{trace_id}.private_clearing_rule", 10)
    for field in ("public_transcript_private_content_prohibited", "public_audio_private_content_prohibited", "mirrored_private_content_prohibited"):
        require(privacy[field] is True, f"{trace_id}: {field} must be true")

    if privacy_surface == "controlled_private_surface":
        require(privacy["neutral_shield_required"] is True, f"{trace_id}: private surface requires a neutral shield")
        require(privacy["authorized_private_actor_required"] is True, f"{trace_id}: private surface requires an authorized private actor")
        require(bool(private_content), f"{trace_id}: private surface requires declared private content")
        require(bool(projection["private_outputs"]), f"{trace_id}: private surface requires private outputs")
        require(bool(read_domains & PRIVATE_DOMAINS), f"{trace_id}: private surface requires a declared private read domain")
    elif privacy_surface == "public_shared":
        require(privacy["neutral_shield_required"] is False, f"{trace_id}: public surface may not require a hidden shield")
        require(not projection["private_outputs"], f"{trace_id}: public surface may not project private outputs")
    else:
        require(privacy["neutral_shield_required"] is True, f"{trace_id}: neutral shield record must require the shield")


def validate_recovery(trace_id: str, recovery: Any) -> None:
    require(isinstance(recovery, list) and len(recovery) >= 2, f"{trace_id}: at least two recovery cases are required")
    failures: set[str] = set()
    for index, case in enumerate(recovery):
        require(isinstance(case, dict), f"{trace_id}: recovery[{index}] must be an object")
        expected = {"failure", "authoritative_mutation", "focus_destination", "player_message", "private_data_exposure", "stable_seat_reset"}
        require(set(case) == expected, f"{trace_id}: recovery[{index}] fields do not match contract")
        failure = text(case["failure"], f"{trace_id}.recovery[{index}].failure")
        require(failure not in failures, f"{trace_id}: duplicate recovery failure: {failure}")
        failures.add(failure)
        require(case["authoritative_mutation"] in {"none", "committed_once_before_failure"}, f"{trace_id}: invalid recovery mutation")
        text(case["focus_destination"], f"{trace_id}.recovery[{index}].focus_destination", 3)
        text(case["player_message"], f"{trace_id}.recovery[{index}].player_message", 12)
        require(case["private_data_exposure"] is False, f"{trace_id}: recovery may not expose private data")
        require(case["stable_seat_reset"] is False, f"{trace_id}: recovery may not reset a stable seat")


def validate_presentation(trace_id: str, presentation: Any, storyboard: dict[str, Any], criticality: str) -> None:
    require(isinstance(presentation, dict), f"{trace_id}: presentation_obligations must be an object")
    expected = {
        "required_layout_regions",
        "focus_owner_visible",
        "focus_restoration_rule",
        "confirmation_pattern",
        "persistent_text_required",
        "plain_system_required",
        "caption_support_required",
        "transcript_private_exclusion_required",
        "active_seat_identity_preserved",
        "control_source_visibility",
        "no_audio_operation_required",
    }
    require(set(presentation) == expected, f"{trace_id}: presentation fields do not match contract")
    regions = set(unique_text_list(presentation["required_layout_regions"], f"{trace_id}.required_layout_regions", minimum=1))
    storyboard_regions = set(storyboard.get("layout_regions", []))
    require(regions == storyboard_regions, f"{trace_id}: required layout regions differ from storyboard")
    require(isinstance(presentation["focus_owner_visible"], bool), f"{trace_id}: focus_owner_visible must be boolean")
    text(presentation["focus_restoration_rule"], f"{trace_id}.focus_restoration_rule", 10)
    confirmation = presentation["confirmation_pattern"]
    require(confirmation in ALLOWED_CONFIRMATION, f"{trace_id}: invalid confirmation pattern")
    storyboard_confirmation = storyboard.get("confirmation_pattern")
    require(confirmation == storyboard_confirmation or (storyboard_confirmation == "none" and confirmation == "no_commit"), f"{trace_id}: confirmation pattern differs from storyboard")
    for field in ("plain_system_required", "caption_support_required", "transcript_private_exclusion_required", "active_seat_identity_preserved", "no_audio_operation_required"):
        require(presentation[field] is True, f"{trace_id}: {field} must be true")
    require(presentation["control_source_visibility"] in {"required", "not_required", "public_when_applicable"}, f"{trace_id}: invalid control-source visibility")
    if criticality == "critical":
        require(presentation["persistent_text_required"] is True, f"{trace_id}: critical traces require persistent text")


def validate_trace(entry: Any, index: int, storyboards: dict[str, dict[str, Any]], concepts: set[str]) -> tuple[str, str, set[str]]:
    require(isinstance(entry, dict), f"entries[{index}] must be an object")
    missing = REQUIRED_FIELDS - entry.keys()
    unexpected = set(entry) - REQUIRED_FIELDS
    require(not missing, f"entries[{index}] missing fields: {sorted(missing)}")
    require(not unexpected, f"entries[{index}] unexpected fields: {sorted(unexpected)}")

    trace_id = text(entry["trace_id"], f"entries[{index}].trace_id")
    require(TRACE_ID_PATTERN.fullmatch(trace_id) is not None, f"invalid trace ID: {trace_id}")
    storyboard_id = text(entry["storyboard_id"], f"{trace_id}.storyboard_id")
    require(storyboard_id in storyboards, f"{trace_id}: unknown storyboard ID: {storyboard_id}")
    storyboard = storyboards[storyboard_id]
    require(entry["tale_id"] == "drowned_harbor", f"{trace_id}: unexpected Tale ID")
    text(entry["title"], f"{trace_id}.title", 5)
    require(entry["criticality"] in {"critical", "important", "contextual"}, f"{trace_id}: invalid criticality")
    privacy_surface = entry["privacy_surface"]
    require(privacy_surface in ALLOWED_PRIVACY, f"{trace_id}: invalid privacy surface")
    require(privacy_surface == storyboard.get("privacy_surface"), f"{trace_id}: privacy surface differs from storyboard")

    read_domains = set(unique_text_list(entry["read_domains"], f"{trace_id}.read_domains", minimum=1))
    write_domains = set(unique_text_list(entry["write_domains"], f"{trace_id}.write_domains", minimum=0))
    require(read_domains.issubset(ALLOWED_DOMAINS), f"{trace_id}: unknown read domain")
    require(write_domains.issubset(ALLOWED_DOMAINS), f"{trace_id}: unknown write domain")
    actors = set(unique_text_list(entry["allowed_actors"], f"{trace_id}.allowed_actors", minimum=1))
    require(actors.issubset(ALLOWED_ACTORS), f"{trace_id}: unknown actor")
    validate_rules(entry["entry_preconditions"], f"{trace_id}.entry_preconditions")
    lifecycle = unique_text_list(entry["lifecycle_steps"], f"{trace_id}.lifecycle_steps", minimum=4)
    require(set(lifecycle).issubset(ALLOWED_LIFECYCLE), f"{trace_id}: unknown lifecycle step")
    require(lifecycle[0] == "eligible" and lifecycle[-1] == "settled", f"{trace_id}: lifecycle must begin eligible and end settled")
    intents = unique_text_list(entry["input_intents"], f"{trace_id}.input_intents", minimum=1)
    require(all(STABLE_KEY_PATTERN.fullmatch(intent) for intent in intents), f"{trace_id}: invalid input intent")
    validate_rules(entry["action_guards"], f"{trace_id}.action_guards")

    validate_commit(trace_id, entry["commit_contract"])
    validate_projection(trace_id, entry["projection_contract"], entry["commit_contract"]["authoritative_commit"])
    validate_privacy(trace_id, privacy_surface, read_domains, entry["projection_contract"], entry["privacy_contract"])
    validate_recovery(trace_id, entry["recovery_contract"])
    validate_presentation(trace_id, entry["presentation_obligations"], storyboard, entry["criticality"])

    seams = set(unique_text_list(entry["implementation_seams"], f"{trace_id}.implementation_seams", minimum=2))
    require(seams.issubset(ALLOWED_IMPLEMENTATION_SEAMS), f"{trace_id}: unknown implementation seam")
    paths = unique_text_list(entry["source_paths"], f"{trace_id}.source_paths", minimum=2)
    for path_index, path in enumerate(paths):
        validate_repo_path(path, f"{trace_id}.source_paths[{path_index}]")
    referenced_concepts = set(unique_text_list(entry["traceability_concepts"], f"{trace_id}.traceability_concepts", minimum=0))
    require(referenced_concepts.issubset(concepts), f"{trace_id}: unknown traceability concept")
    questions = unique_text_list(entry["human_validation_questions"], f"{trace_id}.human_validation_questions", minimum=2)
    require(all(len(question.strip()) >= 20 for question in questions), f"{trace_id}: human-validation questions are too short")
    require(entry["status"] in ALLOWED_STATUS, f"{trace_id}: invalid status")
    require(entry["status"] not in PROHIBITED_STATUS, f"{trace_id}: P0.11 may not authorize implementation or production")
    text(entry["approval_boundary"], f"{trace_id}.approval_boundary", 40)

    return trace_id, storyboard_id, {event["event_key"] for event in entry["projection_contract"]["emitted_events"]}


def validate_manifests(paths: Sequence[Path], storyboards: dict[str, dict[str, Any]], concepts: set[str]) -> tuple[int, int, int]:
    require(bool(paths), "at least one interaction trace manifest is required")
    trace_ids: set[str] = set()
    storyboard_ids: set[str] = set()
    event_keys: set[str] = set()
    total = 0
    for path in paths:
        data = read_json(path)
        require(data.get("manifest_kind") == "interaction_state_traces_preproduction", f"unexpected manifest kind: {path}")
        require(data.get("schema_version") == 1, f"unsupported schema version: {path}")
        require(data.get("tale_id") == "drowned_harbor", f"unexpected Tale ID: {path}")
        require(data.get("production_status") == "design_only", f"production status must remain design_only: {path}")
        require(data.get("record_schema") == "docs/preproduction/interaction_state_trace_schema_v1.json", f"unexpected record schema: {path}")
        entries = data.get("entries")
        require(isinstance(entries, list) and entries, f"entries must be non-empty: {path}")
        for index, entry in enumerate(entries):
            trace_id, storyboard_id, current_events = validate_trace(entry, index, storyboards, concepts)
            require(trace_id not in trace_ids, f"duplicate interaction trace ID: {trace_id}")
            require(storyboard_id not in storyboard_ids, f"storyboard registered more than once: {storyboard_id}")
            duplicate_events = event_keys & current_events
            require(not duplicate_events, f"duplicate event key across traces: {sorted(duplicate_events)}")
            trace_ids.add(trace_id)
            storyboard_ids.add(storyboard_id)
            event_keys.update(current_events)
            total += 1

    expected_trace_ids = {f"DH-IS-{number:03d}" for number in range(1, 23)}
    expected_storyboard_ids = {f"DH-UI-{number:03d}" for number in range(1, 23)}
    require(trace_ids == expected_trace_ids, f"interaction trace coverage differs: missing={sorted(expected_trace_ids - trace_ids)} extra={sorted(trace_ids - expected_trace_ids)}")
    require(storyboard_ids == expected_storyboard_ids, f"storyboard coverage differs: missing={sorted(expected_storyboard_ids - storyboard_ids)} extra={sorted(storyboard_ids - expected_storyboard_ids)}")
    require(set(storyboards) == expected_storyboard_ids, "P0.10 storyboard inventory must remain exactly 22 records")
    return len(paths), total, len(event_keys)


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("manifests", nargs="*", type=Path)
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    paths = tuple(args.manifests) if args.manifests else discover_traces()
    try:
        storyboards = load_storyboards(discover_storyboards())
        concepts = load_concepts(TRACEABILITY_PATH)
        manifest_count, trace_count, event_count = validate_manifests(paths, storyboards, concepts)
    except InteractionTraceValidationError as exc:
        print(f"Interaction-state trace validation failed: {exc}", file=sys.stderr)
        return 1
    print(f"Validated {trace_count} interaction traces, {event_count} event keys, and exact coverage of 22 P0.10 storyboards across {manifest_count} manifest(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
