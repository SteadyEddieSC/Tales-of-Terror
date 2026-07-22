#!/usr/bin/env python3
"""Validate repository-owned toolchain pins and non-gameplay boundaries."""

from __future__ import annotations

import re
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
GODOT_WORKFLOW = ROOT / ".github" / "workflows" / "godot-tests.yml"
REPOSITORY_WORKFLOW = ROOT / ".github" / "workflows" / "repository-checks.yml"
PROJECT = ROOT / "game" / "project.godot"
REQUIREMENTS_INPUT = ROOT / "requirements-dev.in"
REQUIREMENTS_LOCK = ROOT / "requirements-dev.txt"

LOCKED_DEVELOPMENT_PACKAGES = {
    "colorama": "0.4.6",
    "docopt-ng": "0.9.0",
    "gdtoolkit": "4.5.0",
    "lark": "1.2.2",
    "mando": "0.7.1",
    "pyyaml": "6.0.3",
    "radon": "6.0.1",
    "regex": "2026.7.19",
    "setuptools": "83.0.0",
    "six": "1.17.0",
}

EXACT_REQUIREMENT = re.compile(
    r"(?P<name>[A-Za-z0-9][A-Za-z0-9._-]*)"
    r"(?:\[[A-Za-z0-9._,-]+\])?=="
    r"(?P<version>[^<>=~*!;,\s\\/]+)"
)
SHA256_HASH = re.compile(r"--hash=sha256:[0-9a-f]{64}(?:\s|$)")


def _contains(path: Path, expected: str, failures: list[str]) -> None:
    if expected not in path.read_text(encoding="utf-8"):
        failures.append(f"{path.relative_to(ROOT)} is missing: {expected}")


def _logical_requirements(path: Path) -> list[str]:
    """Join pip continuation lines and return non-comment requirement entries."""
    entries: list[str] = []
    pending: list[str] = []
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        continued = line.endswith("\\")
        pending.append(line[:-1].strip() if continued else line)
        if not continued:
            entries.append(" ".join(pending))
            pending = []
    if pending:
        entries.append(" ".join(pending))
    return entries


def _workflow_step(workflow: str, name: str) -> str:
    marker = f"      - name: {name}\n"
    start = workflow.find(marker)
    if start < 0:
        return ""
    end = workflow.find("\n      - name:", start + len(marker))
    if end < 0:
        end = len(workflow)
    return workflow[start:end]


def _validate_python_lock(failures: list[str]) -> None:
    if not REQUIREMENTS_INPUT.is_file() or not REQUIREMENTS_LOCK.is_file():
        return

    direct_requirements = _logical_requirements(REQUIREMENTS_INPUT)
    if direct_requirements != ["gdtoolkit==4.5.0"]:
        failures.append(
            "requirements-dev.in must select only the reviewed direct dependency "
            "gdtoolkit==4.5.0"
        )

    locked_packages: dict[str, str] = {}
    for entry in _logical_requirements(REQUIREMENTS_LOCK):
        requirement = entry.split(" --hash=", maxsplit=1)[0]
        match = EXACT_REQUIREMENT.fullmatch(requirement)
        if match is None:
            failures.append(
                "requirements-dev.txt contains a non-exact, editable, ranged, "
                f"wildcard, URL, or moving-branch requirement: {requirement}"
            )
            continue
        if SHA256_HASH.search(entry) is None:
            failures.append(
                "requirements-dev.txt requirement is missing a SHA-256 distribution "
                f"hash: {requirement}"
            )
        name = match.group("name").lower().replace("_", "-")
        locked_packages[name] = match.group("version")

    if locked_packages != LOCKED_DEVELOPMENT_PACKAGES:
        failures.append(
            "requirements-dev.txt resolved package set differs from the reviewed "
            f"Python 3.11.9 lock: expected {LOCKED_DEVELOPMENT_PACKAGES}, "
            f"found {locked_packages}"
        )


def main() -> int:
    failures: list[str] = []

    required_files = [
        REQUIREMENTS_INPUT,
        REQUIREMENTS_LOCK,
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

    _validate_python_lock(failures)

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
        "python -m pip install --disable-pip-version-check --require-hashes --requirement requirements-dev.txt",
        "python -m pip check",
        "python -m pip freeze --all",
        "name: Enforce zero-finding GDScript lint gate",
        'gdlint "${gd_files[@]}" 2>&1 | tee artifacts/gdscript-quality/gdlint.txt',
        "name: Enforce canonical GDScript format gate (check only)",
        'gdformat --check "${gd_files[@]}" 2>&1 | tee artifacts/gdscript-quality/gdformat.txt',
        "-not -path 'game/addons/gut/*'",
        "-not -path 'game/.godot/*'",
        "name: Upload enforced GDScript quality evidence",
        "name: gdscript-quality",
        "path: artifacts/gdscript-quality",
        "res://addons/gut/gut_cmdln.gd",
        "res://tests/vertical_slice_test.gd",
        "res://tests/tale_package_test.gd",
        "res://tests/tale_catalog_test.gd",
        "res://tests/tale_library_test.gd",
        "res://tests/tale_replay_equivalence_test.gd",
        "res://tests/playtest_readiness_test.gd",
        "res://tests/portable_build_identity_test.gd",
        "res://tests/vertical_slice_simulation_test.gd",
        "gut-junit.xml",
        "if: always()",
    ]
    for expected in workflow_expectations:
        _contains(GODOT_WORKFLOW, expected, failures)
    workflow_source = GODOT_WORKFLOW.read_text(encoding="utf-8")
    workflow_text = workflow_source.lower()
    rewriting_format_command = any(
        line.strip().startswith("gdformat ")
        and not line.strip().startswith("gdformat --check ")
        for line in workflow_text.splitlines()
    )
    if "godot-ci" in workflow_text or rewriting_format_command:
        failures.append("workflow must not add godot-ci or a source-rewriting gdformat command")

    inventory_step = _workflow_step(workflow_source, "Inventory first-party GDScript")
    expected_inventory_fragments = [
        "mkdir -p artifacts/gdscript-quality",
        "find game -type f -name '*.gd' \\",
        "-not -path 'game/addons/gut/*' \\",
        "-not -path 'game/.godot/*' \\",
        "-print | sort > artifacts/gdscript-quality/first-party-files.txt",
    ]
    if (
        not inventory_step
        or any(fragment not in inventory_step for fragment in expected_inventory_fragments)
        or inventory_step.count("-not -path") != 2
    ):
        failures.append(
            "workflow first-party GDScript inventory construction or reviewed exclusions changed"
        )

    lint_step = _workflow_step(
        workflow_source, "Enforce zero-finding GDScript lint gate"
    )
    format_step = _workflow_step(
        workflow_source, "Enforce canonical GDScript format gate (check only)"
    )
    masked_gate_tokens = [
        "set +e",
        "continue-on-error",
        "::warning::",
        "informational",
        "|| true",
        "; true",
        "status=$?",
        "exit 0",
    ]
    for gate_name, gate_step, command in [
        (
            "gdlint",
            lint_step,
            'gdlint "${gd_files[@]}" 2>&1 | tee artifacts/gdscript-quality/gdlint.txt',
        ),
        (
            "gdformat",
            format_step,
            'gdformat --check "${gd_files[@]}" 2>&1 | tee artifacts/gdscript-quality/gdformat.txt',
        ),
    ]:
        lowered_step = gate_step.lower()
        if (
            not gate_step
            or "set -euo pipefail" not in gate_step
            or command not in gate_step
            or any(token in lowered_step for token in masked_gate_tokens)
        ):
            failures.append(
                f"workflow {gate_name} gate must fail closed without informational or masked execution"
            )
    if workflow_source.count('gdlint "${gd_files[@]}"') != 1:
        failures.append("workflow must execute gdlint exactly once against the reviewed inventory")
    if workflow_source.count('gdformat --check "${gd_files[@]}"') != 1:
        failures.append(
            "workflow must execute gdformat --check exactly once against the reviewed inventory"
        )

    repository_workflow_expectations = [
        "fetch-depth: 0",
        "PR_BASE_SHA: ${{ github.event.pull_request.base.sha }}",
        "PR_HEAD_SHA: ${{ github.event.pull_request.head.sha }}",
        "PUSH_BEFORE_SHA: ${{ github.event.before }}",
        "PUSH_HEAD_SHA: ${{ github.sha }}",
        'diff_args=("${PR_BASE_SHA}...${PR_HEAD_SHA}")',
        "zero_sha=0000000000000000000000000000000000000000",
        "Unsupported event for committed-range whitespace validation",
        "git diff --check \"${diff_args[@]}\" -- . ':(exclude)game/addons/gut/**'",
    ]
    for expected in repository_workflow_expectations:
        _contains(REPOSITORY_WORKFLOW, expected, failures)
    if "git diff --check HEAD" in REPOSITORY_WORKFLOW.read_text(encoding="utf-8"):
        failures.append(
            "repository workflow must validate the committed event range, not "
            "git diff --check HEAD"
        )

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
        "vertical_slice_test.gd",
        "tale_package_test.gd",
        "tale_catalog_test.gd",
        "tale_library_test.gd",
        "tale_replay_equivalence_test.gd",
        "playtest_readiness_test.gd",
        "playtest_main_route_test.gd",
        "portable_build_identity_test.gd",
        "vertical_slice_simulation_test.gd",
    ]
    for filename in legacy_tests:
        if not (ROOT / "game" / "tests" / filename).is_file():
            failures.append(f"legacy test missing: game/tests/{filename}")

    tracked = subprocess.run(
        ["git", "ls-files"], cwd=ROOT, check=True, capture_output=True, text=True
    ).stdout.splitlines()
    forbidden_suffixes = (".exe", ".pck", ".tpz", ".x86_64", ".zip")
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
