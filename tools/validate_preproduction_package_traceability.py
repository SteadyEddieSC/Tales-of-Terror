#!/usr/bin/env python3
"""Validate the merged preproduction package index and cross-media traceability."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

ROOT = Path(".")
INDEX_PATH = Path("docs/preproduction/preproduction_package_index_v1.json")
TRACE_PATH = Path("docs/preproduction/drowned_harbor_cross_media_traceability_v1.json")
HANDOFF_PATH = Path("docs/preproduction/P0.8_Codex_Return_Handoff_v1.md")

RELEASE_PATTERN = re.compile(r"^P0\.[1-7]$")
SHA_PATTERN = re.compile(r"^[0-9a-f]{40}$")
CONCEPT_PATTERN = re.compile(r"^DH-XM-[0-9]{3}$")

AUDIO_PATTERN = "docs/tales/drowned_harbor/audio/drowned_harbor_audio_*_briefs_v1.json"
MUSIC_PATTERN = "docs/tales/drowned_harbor/music/drowned_harbor_music_*_briefs_v1.json"
VOICE_PATTERN = "docs/tales/drowned_harbor/voice/drowned_harbor_voice_*_families_v1.json"
ACCESS_PATTERN = "docs/tales/drowned_harbor/accessibility/drowned_harbor_accessible_*_units_v1.json"

INDEX_PACKAGE_FIELDS = {
    "release_id",
    "title",
    "pull_request",
    "status",
    "merged_main_sha",
    "merge_reference",
    "release_summary",
    "primary_paths",
    "governed_outputs",
    "implementation_authorized",
    "production_assets_approved",
}
TRACE_ENTRY_FIELDS = {
    "concept_id",
    "title",
    "criticality",
    "design_paths",
    "visual_paths",
    "audio_asset_ids",
    "music_asset_ids",
    "voice_family_ids",
    "accessible_unit_ids",
    "governance_paths",
    "human_validation_required",
    "implementation_status",
    "non_negotiable",
}


class TraceabilityValidationError(ValueError):
    """Raised when the P0.8 package contract is inconsistent."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise TraceabilityValidationError(message)


def text(value: Any, field: str, minimum: int = 1) -> str:
    require(isinstance(value, str), f"{field} must be text")
    result = value.strip()
    require(len(result) >= minimum, f"{field} must contain at least {minimum} characters")
    return result


def unique_text_list(value: Any, field: str, minimum: int = 0) -> list[str]:
    require(isinstance(value, list), f"{field} must be a list")
    require(len(value) >= minimum, f"{field} must contain at least {minimum} item(s)")
    require(
        all(isinstance(item, str) and item.strip() for item in value),
        f"{field} must contain non-empty text",
    )
    require(len(value) == len(set(value)), f"{field} contains duplicates")
    return value


def read_json(path: Path) -> dict[str, Any]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise TraceabilityValidationError(f"file not found: {path}") from exc
    except json.JSONDecodeError as exc:
        raise TraceabilityValidationError(f"invalid JSON in {path}: {exc}") from exc
    require(isinstance(data, dict), f"JSON root must be an object: {path}")
    return data


def validate_repo_path(root: Path, value: str, field: str) -> None:
    path = Path(value)
    require(not path.is_absolute(), f"{field} must be repository relative")
    require(".." not in path.parts, f"{field} may not escape the repository")
    require((root / path).is_file(), f"{field} does not exist: {value}")


def collect_ids(
    root: Path, pattern: str, key: str
) -> tuple[set[str], dict[str, dict[str, Any]]]:
    identifiers: set[str] = set()
    entries: dict[str, dict[str, Any]] = {}
    paths = tuple(sorted(root.glob(pattern)))
    require(bool(paths), f"no manifests found for {pattern}")
    for path in paths:
        data = read_json(path)
        values = data.get("entries")
        require(isinstance(values, list), f"entries must be a list: {path}")
        for entry in values:
            require(isinstance(entry, dict), f"manifest entry must be an object: {path}")
            identifier = text(entry.get(key), f"{path}.{key}")
            require(identifier not in identifiers, f"duplicate authoritative ID: {identifier}")
            identifiers.add(identifier)
            entries[identifier] = entry
    return identifiers, entries


def validate_index(data: dict[str, Any], root: Path = ROOT) -> None:
    require(data.get("index_kind") == "preproduction_package_index", "unexpected index_kind")
    require(data.get("schema_version") == 1, "unsupported package index schema")
    require(data.get("future_tale") == "drowned_harbor", "unexpected future Tale")
    require(data.get("future_tale_status") == "design_only", "Drowned Harbor must remain design_only")
    require(data.get("production_tale") == "lantern_house_vertical_slice", "Lantern House must remain the production Tale")
    require(data.get("runtime_implementation_authorized") is False, "package index may not authorize runtime implementation")
    require(data.get("production_catalog_authorized") is False, "package index may not authorize a production catalog entry")

    packages = data.get("packages")
    require(
        isinstance(packages, list) and len(packages) == 7,
        "package index must contain P0.1 through P0.7",
    )

    release_ids: list[str] = []
    pull_requests: list[int] = []
    merge_shas: list[str] = []
    for index, package in enumerate(packages, start=1):
        require(isinstance(package, dict), f"packages[{index - 1}] must be an object")
        require(
            set(package) == INDEX_PACKAGE_FIELDS,
            f"packages[{index - 1}] fields do not match contract",
        )
        release_id = text(package["release_id"], f"packages[{index - 1}].release_id")
        require(RELEASE_PATTERN.fullmatch(release_id) is not None, f"invalid release ID: {release_id}")
        require(release_id == f"P0.{index}", f"release order is not sequential at {release_id}")
        release_ids.append(release_id)

        require(package["pull_request"] == 64 + index, f"{release_id}: unexpected pull request number")
        pull_requests.append(package["pull_request"])
        require(package["status"] == "merged", f"{release_id}: package must be merged")
        text(package["title"], f"{release_id}.title", 8)
        text(package["merge_reference"], f"{release_id}.merge_reference", 20)

        sha = text(package["merged_main_sha"], f"{release_id}.merged_main_sha")
        require(SHA_PATTERN.fullmatch(sha) is not None, f"{release_id}: invalid merge SHA")
        merge_shas.append(sha)

        validate_repo_path(root, package["release_summary"], f"{release_id}.release_summary")
        primary_paths = unique_text_list(
            package["primary_paths"], f"{release_id}.primary_paths", minimum=1
        )
        for path_index, path in enumerate(primary_paths):
            validate_repo_path(root, path, f"{release_id}.primary_paths[{path_index}]")
        unique_text_list(
            package["governed_outputs"], f"{release_id}.governed_outputs", minimum=2
        )
        require(
            package["implementation_authorized"] is False,
            f"{release_id}: implementation authorization is prohibited",
        )
        require(
            package["production_assets_approved"] is False,
            f"{release_id}: production asset approval is prohibited",
        )

    require(len(release_ids) == len(set(release_ids)), "duplicate release IDs")
    require(len(pull_requests) == len(set(pull_requests)), "duplicate pull request numbers")
    require(len(merge_shas) == len(set(merge_shas)), "duplicate merge SHAs")

    current_main = text(
        data.get("current_protected_main_at_index_creation"),
        "current_protected_main_at_index_creation",
    )
    require(SHA_PATTERN.fullmatch(current_main) is not None, "invalid protected-main SHA")
    require(
        current_main == packages[-1]["merged_main_sha"],
        "index creation SHA must equal the P0.7 protected-main squash",
    )

    gates = data.get("known_external_gates")
    require(
        isinstance(gates, list) and gates,
        "known_external_gates must be a non-empty list",
    )
    issue_numbers: set[int] = set()
    for gate in gates:
        require(
            isinstance(gate, dict) and set(gate) == {"issue", "summary"},
            "invalid external-gate entry",
        )
        require(isinstance(gate["issue"], int), "external gate issue must be an integer")
        require(gate["issue"] not in issue_numbers, "duplicate external gate issue")
        issue_numbers.add(gate["issue"])
        text(gate["summary"], f"issue_{gate['issue']}.summary", 20)
    require(
        issue_numbers == {7, 39, 44},
        "external gates must include issues #7, #39, and #44",
    )


def validate_traceability(data: dict[str, Any], root: Path = ROOT) -> None:
    require(
        data.get("traceability_kind") == "cross_media_preproduction_traceability",
        "unexpected traceability_kind",
    )
    require(data.get("schema_version") == 1, "unsupported traceability schema")
    require(data.get("tale_id") == "drowned_harbor", "unexpected traceability Tale")
    require(data.get("tale_status") == "design_only", "traceability Tale must remain design_only")
    require(data.get("implementation_authorized") is False, "traceability may not authorize implementation")

    audio_ids, _ = collect_ids(root, AUDIO_PATTERN, "asset_id")
    music_ids, _ = collect_ids(root, MUSIC_PATTERN, "asset_id")
    voice_ids, _ = collect_ids(root, VOICE_PATTERN, "family_id")
    access_ids, access_entries = collect_ids(root, ACCESS_PATTERN, "unit_id")

    voice_to_access: dict[str, str] = {}
    for unit_id, entry in access_entries.items():
        source_id = text(entry.get("source_family_id"), f"{unit_id}.source_family_id")
        require(
            source_id not in voice_to_access,
            f"voice family has multiple accessibility units: {source_id}",
        )
        voice_to_access[source_id] = unit_id

    entries = data.get("entries")
    require(
        isinstance(entries, list) and len(entries) >= 15,
        "traceability must contain at least fifteen concepts",
    )

    concept_ids: list[str] = []
    titles: set[str] = set()
    for index, entry in enumerate(entries, start=1):
        require(isinstance(entry, dict), f"entries[{index - 1}] must be an object")
        require(
            set(entry) == TRACE_ENTRY_FIELDS,
            f"entries[{index - 1}] fields do not match contract",
        )

        concept_id = text(entry["concept_id"], f"entries[{index - 1}].concept_id")
        require(CONCEPT_PATTERN.fullmatch(concept_id) is not None, f"invalid concept ID: {concept_id}")
        require(
            concept_id == f"DH-XM-{index:03d}",
            f"concept order is not sequential at {concept_id}",
        )
        concept_ids.append(concept_id)

        title = text(entry["title"], f"{concept_id}.title", 8)
        require(title not in titles, f"duplicate concept title: {title}")
        titles.add(title)
        require(
            entry["criticality"] in {"foundational", "signature", "supporting"},
            f"{concept_id}: invalid criticality",
        )
        require(
            entry["human_validation_required"] is True,
            f"{concept_id}: human validation must remain required",
        )
        require(
            entry["implementation_status"] == "preproduction_only",
            f"{concept_id}: implementation status must remain preproduction_only",
        )
        text(entry["non_negotiable"], f"{concept_id}.non_negotiable", 50)

        design_paths = unique_text_list(
            entry["design_paths"], f"{concept_id}.design_paths", minimum=1
        )
        visual_paths = unique_text_list(
            entry["visual_paths"], f"{concept_id}.visual_paths", minimum=0
        )
        governance_paths = unique_text_list(
            entry["governance_paths"], f"{concept_id}.governance_paths", minimum=1
        )
        for field, values in (
            ("design_paths", design_paths),
            ("visual_paths", visual_paths),
            ("governance_paths", governance_paths),
        ):
            for path_index, path in enumerate(values):
                validate_repo_path(root, path, f"{concept_id}.{field}[{path_index}]")

        referenced_audio = unique_text_list(
            entry["audio_asset_ids"], f"{concept_id}.audio_asset_ids"
        )
        referenced_music = unique_text_list(
            entry["music_asset_ids"], f"{concept_id}.music_asset_ids"
        )
        referenced_voice = unique_text_list(
            entry["voice_family_ids"], f"{concept_id}.voice_family_ids", minimum=1
        )
        referenced_access = unique_text_list(
            entry["accessible_unit_ids"],
            f"{concept_id}.accessible_unit_ids",
            minimum=1,
        )

        for identifier in referenced_audio:
            require(identifier in audio_ids, f"{concept_id}: unknown audio ID: {identifier}")
        for identifier in referenced_music:
            require(identifier in music_ids, f"{concept_id}: unknown music ID: {identifier}")
        for identifier in referenced_voice:
            require(identifier in voice_ids, f"{concept_id}: unknown voice family ID: {identifier}")
            require(
                identifier in voice_to_access,
                f"{concept_id}: voice family lacks an accessibility unit: {identifier}",
            )
        for identifier in referenced_access:
            require(identifier in access_ids, f"{concept_id}: unknown accessible unit ID: {identifier}")

        expected_access = {voice_to_access[voice_id] for voice_id in referenced_voice}
        require(
            set(referenced_access) == expected_access,
            f"{concept_id}: voice and accessible-unit coverage do not match",
        )

        if entry["criticality"] == "signature":
            require(bool(visual_paths), f"{concept_id}: signature concepts require visual coverage")
            require(bool(referenced_audio), f"{concept_id}: signature concepts require audio coverage")
            require(bool(referenced_music), f"{concept_id}: signature concepts require music coverage")

    require(len(concept_ids) == len(set(concept_ids)), "duplicate concept IDs")
    required_titles = {
        "Stable Seat Continuity",
        "High Water Terror Turn",
        "Bellmarked Public Reveal",
        "Tidebound Public Transformation",
        "Restless Continuation Forms",
        "Mixed Outcome Attribution",
    }
    require(
        required_titles.issubset(titles),
        "traceability omits a required foundational concept",
    )


def validate_handoff(content: str) -> None:
    required_phrases = [
        "reconcile, do not develop",
        "Drowned Harbor remains design-only",
        "Lantern House remains the sole production Tale",
        "Issue #7 remains open",
        "Issue #39 remains open",
        "Issue #44",
        "No implementation authorization",
        "git pull --ff-only origin main",
        "validate_preproduction_package_traceability.py",
        "Do not suppress the Companion audit",
    ]
    lowered = content.lower()
    for phrase in required_phrases:
        require(
            phrase.lower() in lowered,
            f"Codex handoff missing required phrase: {phrase}",
        )
    require(
        "create `drowned_harbor` under the production Tale package directory"
        in content,
        "Codex handoff must explicitly prohibit a production Tale package",
    )
    require("git reset --hard" not in lowered, "Codex handoff may not prescribe destructive reset")
    require("git clean -fd" not in lowered, "Codex handoff may not prescribe destructive clean")


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=ROOT)
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    root = args.root
    try:
        validate_index(read_json(root / INDEX_PATH), root)
        validate_traceability(read_json(root / TRACE_PATH), root)
        validate_handoff((root / HANDOFF_PATH).read_text(encoding="utf-8"))
    except (TraceabilityValidationError, FileNotFoundError) as exc:
        print(
            f"Preproduction package traceability validation failed: {exc}",
            file=sys.stderr,
        )
        return 1
    print(
        "Validated seven merged preproduction packages, fifteen cross-media "
        "concepts, and the Codex return handoff"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
