#!/usr/bin/env python3
"""Validate the bounded, local-only playtest observation boundary."""

from __future__ import annotations

import json
import struct
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PLAYTEST_ROOT = ROOT / "game" / "src" / "playtest"
FIXTURE = ROOT / "game" / "tests" / "fixtures" / "playtest_report_v2.json"
REPORT_KEYS = {
    "schema_version",
    "release",
    "scenario",
    "session",
    "lifecycle_events",
    "seat_events",
    "recovery_events",
    "wait_progress",
    "rejections",
    "stage_durations",
    "outcome",
    "tester_feedback",
}
FORBIDDEN_NETWORK_APIS = {
    "HTTPClient",
    "HTTPRequest",
    "WebSocketPeer",
    "PacketPeerUDP",
    "StreamPeerTCP",
}
FORBIDDEN_REPORT_FIELDS = {
    "role_id",
    "faction_id",
    "objective_id",
    "join_code",
    "token",
    "request_body",
    "client_id",
    "ip_address",
    "machine_name",
    "os_username",
    "device_id",
    "repository_path",
}


def main() -> int:
    failures: list[str] = []
    required = [
        PLAYTEST_ROOT / "playtest_report.gd",
        PLAYTEST_ROOT / "playtest_report_writer.gd",
        PLAYTEST_ROOT / "local_playtest_report_writer.gd",
        FIXTURE,
        ROOT / "game" / "tests" / "fixtures" / "playtest_report_v2.md",
        ROOT / "game" / "src" / "session" / "guided_session_help.gd",
        ROOT / "game" / "tests" / "playtest_readiness_test.gd",
        ROOT / "game" / "tests" / "playtest_main_route_test.gd",
        ROOT / "game" / "tests" / "playtest_capture_fixture.gd",
        ROOT / "game" / "tests" / "gut" / "test_playtest_readiness.gd",
        ROOT / "docs" / "playtests" / "Playtest_Readiness_Evidence.md",
        ROOT / "docs" / "playtests" / "v0.1.1-facilitator-guide.md",
    ]
    for path in required:
        if not path.is_file():
            failures.append(f"missing playtest-readiness file: {path.relative_to(ROOT)}")

    evidence_root = ROOT / "docs" / "playtests" / "evidence" / "v0.1.1"
    for state in ("lobby", "prompt", "help", "ending_export"):
        for resolution in ("1280x720", "1920x1080", "3840x2160"):
            capture = evidence_root / f"{state}_{resolution}_virtual_offscreen.png"
            if not capture.is_file():
                failures.append(f"missing review capture: {capture.relative_to(ROOT)}")
                continue
            expected = tuple(int(value) for value in resolution.split("x"))
            with capture.open("rb") as stream:
                header = stream.read(24)
            if len(header) != 24 or header[:8] != b"\x89PNG\r\n\x1a\n":
                failures.append(f"review capture is not PNG: {capture.relative_to(ROOT)}")
            elif struct.unpack(">II", header[16:24]) != expected:
                failures.append(
                    f"review capture dimensions changed: {capture.relative_to(ROOT)}"
                )

    sources = "\n".join(
        path.read_text(encoding="utf-8") for path in PLAYTEST_ROOT.glob("*.gd")
    )
    for api in sorted(FORBIDDEN_NETWORK_APIS):
        if api in sources:
            failures.append(f"reporting source must not use network API {api}")
    for field in sorted(FORBIDDEN_REPORT_FIELDS):
        if f'"{field}"' in sources:
            failures.append(f"reporting source contains forbidden field {field}")

    writer = (PLAYTEST_ROOT / "local_playtest_report_writer.gd").read_text(
        encoding="utf-8"
    )
    if 'const EXPORT_FOLDER: String = "user://playtest_exports"' not in writer:
        failures.append("local report writer must remain pinned to user://playtest_exports")
    if "p_path" in writer or "absolute_path" in writer:
        failures.append("local report writer must not accept an arbitrary output path")

    if FIXTURE.is_file():
        report = json.loads(FIXTURE.read_text(encoding="utf-8"))
        if set(report) != REPORT_KEYS:
            failures.append("playtest report fixture root schema keys changed")
        if report.get("schema_version") != 2 or report.get("release") != "v0.1.2":
            failures.append("playtest report fixture version is not v0.1.2 schema 2")
        serialized = json.dumps(report).lower()
        for field in sorted(FORBIDDEN_REPORT_FIELDS):
            if f'"{field}"' in serialized:
                failures.append(f"playtest report fixture contains forbidden field {field}")

    workflow = (ROOT / ".github" / "workflows" / "godot-tests.yml").read_text(
        encoding="utf-8"
    )
    if "res://tests/playtest_readiness_test.gd" not in workflow:
        failures.append("Godot workflow must run the playtest-readiness standalone suite")
    if "res://tests/playtest_main_route_test.gd" not in workflow:
        failures.append("Godot workflow must run the main-route input integration suite")
    capture_source = (
        ROOT / "game" / "tests" / "playtest_capture_fixture.gd"
    ).read_text(encoding="utf-8")
    for expected in (
        "res://src/main/Main.tscn",
        "InputEventJoypadButton",
        "_input",
        "_sandbox",
    ):
        if expected not in capture_source:
            failures.append(f"normal-route capture fixture is missing: {expected}")
    if "VerticalSliceView.new()" in capture_source:
        failures.append("capture fixture must not instantiate the isolated view directly")
    project = (ROOT / "game" / "project.godot").read_text(encoding="utf-8")
    if 'config/version="v0.1.2"' not in project:
        failures.append("project must provide the single v0.1.2 release identity")
    repository_workflow = (
        ROOT / ".github" / "workflows" / "repository-checks.yml"
    ).read_text(encoding="utf-8")
    if "python tools/validate_playtest_readiness.py" not in repository_workflow:
        failures.append("repository workflow must validate playtest report privacy")

    if failures:
        print("Playtest readiness validation failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1
    print("Playtest readiness validation passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
