#!/usr/bin/env python3
"""Regression tests for the shared-screen storyboard validator."""

from __future__ import annotations

import copy
import json
import tempfile
from pathlib import Path
from typing import Any, Callable

import validate_shared_screen_storyboards as validator

CORE_PATH = Path("docs/tales/drowned_harbor/ui/drowned_harbor_core_storyboards_v1.json")
CONTINUITY_PATH = Path(
    "docs/tales/drowned_harbor/ui/drowned_harbor_continuity_accessibility_storyboards_v1.json"
)


def load(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    assert isinstance(value, dict)
    return value


def write_manifests(root: Path, manifests: list[dict[str, Any]]) -> tuple[Path, ...]:
    paths: list[Path] = []
    for index, manifest in enumerate(manifests):
        path = root / f"manifest_{index}.json"
        path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
        paths.append(path)
    return tuple(paths)


def find_record(manifests: list[dict[str, Any]], storyboard_id: str) -> dict[str, Any]:
    for manifest in manifests:
        for record in manifest["entries"]:
            if record["storyboard_id"] == storyboard_id:
                return record
    raise AssertionError(f"Missing storyboard {storyboard_id}")


def expect_failure(
    originals: list[dict[str, Any]],
    mutate: Callable[[list[dict[str, Any]]], None],
    expected_code: str,
) -> None:
    manifests = copy.deepcopy(originals)
    mutate(manifests)
    with tempfile.TemporaryDirectory() as temporary:
        diagnostics, _ = validator.validate_manifests(
            write_manifests(Path(temporary), manifests)
        )
    codes = {diagnostic.code for diagnostic in diagnostics}
    assert expected_code in codes, (expected_code, [item.as_dict() for item in diagnostics])


def main() -> int:
    repository_root = Path(__file__).resolve().parents[1]
    originals = [load(repository_root / CORE_PATH), load(repository_root / CONTINUITY_PATH)]

    diagnostics, summary = validator.validate_manifests(
        (repository_root / CORE_PATH, repository_root / CONTINUITY_PATH)
    )
    assert diagnostics == [], [item.as_dict() for item in diagnostics]
    assert summary["storyboard_count"] == 22
    assert len(summary["identity"]) == 64

    expect_failure(
        originals,
        lambda manifests: manifests[1]["entries"].__setitem__(
            0, copy.deepcopy(manifests[0]["entries"][0])
        ),
        "duplicate_id",
    )
    expect_failure(
        originals,
        lambda manifests: manifests[1]["entries"].pop(),
        "incomplete_inventory",
    )
    expect_failure(
        originals,
        lambda manifests: manifests[0].__setitem__("production_status", "approved"),
        "production_boundary",
    )
    expect_failure(
        originals,
        lambda manifests: find_record(manifests, "DH-UI-003").__setitem__(
            "runtime_scene", "res://ui/danger.tscn"
        ),
        "unknown_field",
    )
    expect_failure(
        originals,
        lambda manifests: find_record(manifests, "DH-UI-003").__setitem__(
            "source_paths", ["docs/not-real.md", "docs/technical/Shared_Screen_Storyboard_Contract_v1.md"]
        ),
        "missing_source",
    )
    expect_failure(
        originals,
        lambda manifests: find_record(manifests, "DH-UI-003").__setitem__(
            "traceability_concepts", ["DH-XM-999"]
        ),
        "unknown_traceability",
    )
    expect_failure(
        originals,
        lambda manifests: (
            find_record(manifests, "DH-UI-007").__setitem__("layout_mode", "decision_focus"),
            find_record(manifests, "DH-UI-007").__setitem__("privacy_surface", "public_shared"),
        ),
        "privacy_leak",
    )
    expect_failure(
        originals,
        lambda manifests: find_record(manifests, "DH-UI-007")["transcript_policy"].__setitem__(
            "public_history", True
        ),
        "privacy_leak",
    )
    expect_failure(
        originals,
        lambda manifests: find_record(manifests, "DH-UI-005").__setitem__(
            "confirmation_pattern", "none"
        ),
        "confirmation_boundary",
    )
    expect_failure(
        originals,
        lambda manifests: find_record(manifests, "DH-UI-011")["persistent_text_policy"].__setitem__(
            "required", False
        ),
        "persistent_text",
    )
    expect_failure(
        originals,
        lambda manifests: find_record(manifests, "DH-UI-010")["seat_authority_policy"].__setitem__(
            "stable_seat_preserved", False
        ),
        "seat_continuity",
    )
    expect_failure(
        originals,
        lambda manifests: find_record(manifests, "DH-UI-014")["seat_authority_policy"].__setitem__(
            "control_source_visible", False
        ),
        "seat_continuity",
    )
    expect_failure(
        originals,
        lambda manifests: find_record(manifests, "DH-UI-008").__setitem__(
            "layout_mode", "board_first"
        ),
        "high_water_pair",
    )
    expect_failure(
        originals,
        lambda manifests: find_record(manifests, "DH-UI-007")["seat_authority_policy"].__setitem__(
            "authority_transfer_allowed", True
        ),
        "privacy_leak",
    )
    expect_failure(
        originals,
        lambda manifests: find_record(manifests, "DH-UI-016")["seat_authority_policy"].__setitem__(
            "authority_transfer_allowed", False
        ),
        "seat_continuity",
    )
    expect_failure(
        originals,
        lambda manifests: find_record(manifests, "DH-UI-003")["caption_policy"].__setitem__(
            "maximum_lines", 3
        ),
        "caption_contract",
    )
    expect_failure(
        originals,
        lambda manifests: find_record(manifests, "DH-UI-003").__setitem__(
            "human_validation_questions", ["Only one question remains."]
        ),
        "invalid_list",
    )
    expect_failure(
        originals,
        lambda manifests: find_record(manifests, "DH-UI-021").__setitem__(
            "category", "public_board"
        ),
        "incomplete_category",
    )

    print("Shared-screen storyboard validator tests passed: 18 fail-closed mutations")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
