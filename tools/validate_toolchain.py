#!/usr/bin/env python3
"""Validate repository-owned toolchain pins and non-gameplay boundaries."""

from __future__ import annotations

import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
GODOT_WORKFLOW = ROOT / ".github" / "workflows" / "godot-tests.yml"
PROJECT = ROOT / "game" / "project.godot"


def _contains(path: Path, expected: str, failures: list[str]) -> None:
    if expected not in path.read_text(encoding="utf-8"):
        failures.append(f"{path.relative_to(ROOT)} is missing: {expected}")


def main() -> int:
    failures: list[str] = []

    required_files = [
        ROOT / "requirements-dev.txt",
        ROOT / "game" / ".gutconfig.json",
        ROOT / "game" / "addons" / "gut" / "LICENSE.md",
        ROOT / "game" / "addons" / "gut" / "fonts" / "OFL.txt",
        ROOT / "game" / "addons" / "gut" / "plugin.cfg",
        ROOT / "third_party" / "licenses" / "gdtoolkit-4.5.0-MIT.txt",
        ROOT / "docs" / "decisions" / "ADR-0020-toolchain-and-test-strategy.md",
        ROOT / "docs" / "technical" / "Toolchain_and_Testing.md",
    ]
    for path in required_files:
        if not path.is_file():
            failures.append(f"missing required toolchain file: {path.relative_to(ROOT)}")

    if (ROOT / "requirements-dev.txt").read_text(encoding="utf-8").strip() != "gdtoolkit==4.5.0":
        failures.append("requirements-dev.txt must contain only the exact gdtoolkit==4.5.0 pin")

    _contains(PROJECT, 'config/features=PackedStringArray("4.7", "GL Compatibility")', failures)
    _contains(PROJECT, "size/viewport_width=960", failures)
    _contains(PROJECT, "size/viewport_height=540", failures)
    _contains(PROJECT, 'renderer/rendering_method="gl_compatibility"', failures)
    _contains(PROJECT, 'enabled=PackedStringArray("res://addons/gut/plugin.cfg")', failures)

    workflow_expectations = [
        "name: Godot 4.7 headless validation",
        "Godot_v4.7.1-stable_linux.x86_64.zip",
        "4ccdab7a48eeccbe8819a2fc1f6262f8d72065d98601bcb3743fcbd7ebd39f373758a788ee3293a05ec5b2c48538266c437404312e372225cd2df273945a2de9",
        "python-version: 3.11.9",
        "actions/setup-python@ece7cb06caefa5fff74198d8649806c4678c61a1",
        "gdlint",
        "gdformat --check",
        "-not -path 'game/addons/gut/*'",
        "res://addons/gut/gut_cmdln.gd",
        "gut-junit.xml",
        "if: always()",
    ]
    for expected in workflow_expectations:
        _contains(GODOT_WORKFLOW, expected, failures)
    workflow_text = GODOT_WORKFLOW.read_text(encoding="utf-8").lower()
    rewriting_format_command = any(
        line.strip().startswith("gdformat ")
        and not line.strip().startswith("gdformat --check ")
        for line in workflow_text.splitlines()
    )
    if "godot-ci" in workflow_text or rewriting_format_command:
        failures.append("workflow must not add godot-ci or a source-rewriting gdformat command")

    _contains(ROOT / "game" / "addons" / "gut" / "plugin.cfg", 'version="9.7.1"', failures)

    legacy_tests = [
        "seat_manager_test.gd",
        "visual_language_test.gd",
        "exploration_test.gd",
        "living_board_test.gd",
        "turn_event_card_test.gd",
        "dread_director_test.gd",
        "director_simulation_test.gd",
        "role_session_test.gd",
        "social_simulation_test.gd",
        "companion_room_test.gd",
        "companion_simulation_test.gd",
        "companion_live_host_test.gd",
    ]
    for filename in legacy_tests:
        if not (ROOT / "game" / "tests" / filename).is_file():
            failures.append(f"legacy test missing: game/tests/{filename}")

    tracked = subprocess.run(
        ["git", "ls-files"], cwd=ROOT, check=True, capture_output=True, text=True
    ).stdout.splitlines()
    forbidden_suffixes = (".exe", ".tpz")
    forbidden = [
        path
        for path in tracked
        if path.lower().endswith(forbidden_suffixes)
        or ("godot_v4.7.1" in path.lower() and path.lower().endswith(".zip"))
    ]
    if forbidden:
        failures.append(f"engine binary/archive must not be tracked: {', '.join(forbidden)}")

    if failures:
        print("Toolchain policy validation failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1
    print("Toolchain policy validation passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
