#!/usr/bin/env python3
"""Cross-platform local command surface for automated quality checks."""
from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TESTS = [
    "seat_manager_test.gd", "visual_language_test.gd", "exploration_test.gd",
    "living_board_test.gd", "turn_event_card_test.gd", "dread_director_test.gd",
    "director_simulation_test.gd", "role_session_test.gd", "social_simulation_test.gd",
    "companion_room_test.gd", "companion_simulation_test.gd", "vertical_slice_test.gd",
    "tale_package_test.gd", "tale_catalog_test.gd", "drowned_harbor_prototype_automation_test.gd",
    "drowned_harbor_prototype_isolation_test.gd", "tale_library_test.gd",
    "player_owned_interaction_test.gd", "private_reveal_flow_test.gd",
    "tale_replay_equivalence_test.gd", "playtest_readiness_test.gd",
    "playtest_main_route_test.gd", "portable_build_identity_test.gd",
    "vertical_slice_simulation_test.gd", "automated_playthrough_lab_test.gd",
    "quality_baseline_test.gd",
]


def run(command: list[str]) -> None:
    print("+", subprocess.list2cmdline(command), flush=True)
    subprocess.run(command, cwd=ROOT, check=True)


def run_actionlint_when_available() -> None:
    actionlint = shutil.which("actionlint")
    if actionlint is None:
        print(
            "! actionlint is not installed locally; CI enforces checksum-pinned "
            "Actionlint 1.7.12 with ShellCheck integration.",
            flush=True,
        )
        return
    run([actionlint])


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("scope", choices=["static", "godot", "all"], default="all", nargs="?")
    parser.add_argument("--godot", default=os.environ.get("GODOT_BIN", "godot"))
    args = parser.parse_args()
    if args.scope in {"static", "all"}:
        run([sys.executable, "-m", "unittest", "discover", "-s", "quality", "-p", "test_*.py"])
        run([sys.executable, "quality/validate_repository.py", "all"])
        run_actionlint_when_available()
    if args.scope in {"godot", "all"}:
        run([args.godot, "--headless", "--editor", "--path", "game", "--quit"])
        run([args.godot, "--headless", "--path", "game", "--quit-after", "3"])
        for test in TESTS:
            run([args.godot, "--headless", "--path", "game", "--script", f"res://tests/{test}"])
        run([
            args.godot, "--headless", "--path", "game", "--script", "res://addons/gut/gut_cmdln.gd",
            "-gexit", "-gjunit_xml_file=res://test-results/gut-junit.xml",
        ])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
