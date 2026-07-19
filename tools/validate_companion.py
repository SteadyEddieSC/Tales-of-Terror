#!/usr/bin/env python3
"""Validate companion lockfile, secret hygiene, and durable privacy constraints."""

from __future__ import annotations

import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
SKIP_PARTS = {".git", ".godot", ".evidence", "node_modules", "dist", "output"}
TEXT_SUFFIXES = {".gd", ".ts", ".css", ".html", ".md", ".json", ".jsonc", ".yml", ".yaml", ".py"}
REQUIRED = [
    "package.json",
    "package-lock.json",
    "services/room-service/wrangler.jsonc",
    "services/room-service/src/protocol.ts",
    "services/room-service/src/room-coordinator.ts",
    "services/room-service/src/worker.ts",
    "web/companion/src/model.ts",
    "game/src/companion/companion_bridge.gd",
    "game/src/companion/companion_wire_codec.gd",
    "game/src/companion/companion_room_service_host.gd",
    "game/tests/fixtures/companion_protocol_v1.json",
    "tools/run_companion_live_e2e.mjs",
    "docs/decisions/ADR-0019-companion-room-authority-and-privacy.md",
]
FORBIDDEN_CONTENT = {
    "private key block": re.compile(r"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----"),
    "Cloudflare API token assignment": re.compile(r"(?i)\b(?:CF_API_TOKEN|CLOUDFLARE_API_TOKEN)\s*[:=]\s*['\"]?[A-Za-z0-9_-]{20,}"),
    "capability in URL": re.compile(r"(?i)https?://[^\s'\"]*[?&](?:host|resume)Capability="),
}


def text_files() -> list[pathlib.Path]:
    result: list[pathlib.Path] = []
    for path in ROOT.rglob("*"):
        if not path.is_file() or any(part in SKIP_PARTS for part in path.relative_to(ROOT).parts):
            continue
        if path == pathlib.Path(__file__).resolve():
            continue
        if path.suffix.lower() in TEXT_SUFFIXES:
            result.append(path)
    return result


def main() -> int:
    failures: list[str] = []
    for relative in REQUIRED:
        if not (ROOT / relative).is_file():
            failures.append(f"missing required companion file: {relative}")

    package = json.loads((ROOT / "package.json").read_text(encoding="utf-8"))
    lock = json.loads((ROOT / "package-lock.json").read_text(encoding="utf-8"))
    if lock.get("lockfileVersion") != 3:
        failures.append("package-lock.json must use lockfileVersion 3")
    for family in ("dependencies", "devDependencies"):
        for name, version in package.get(family, {}).items():
            if not re.fullmatch(r"\d+\.\d+\.\d+(?:[-+][A-Za-z0-9.-]+)?", version):
                failures.append(f"{family}.{name} is not exactly pinned: {version}")

    for path in text_files():
        try:
            value = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            failures.append(f"non-UTF-8 companion text: {path.relative_to(ROOT)}")
            continue
        for label, pattern in FORBIDDEN_CONTENT.items():
            if pattern.search(value):
                failures.append(f"{label}: {path.relative_to(ROOT)}")

    worker_source = (ROOT / "services/room-service/src/worker.ts").read_text(encoding="utf-8")
    coordinator_source = (ROOT / "services/room-service/src/room-coordinator.ts").read_text(encoding="utf-8")
    browser_source = (ROOT / "web/companion/src/app.ts").read_text(encoding="utf-8")
    host_source = (ROOT / "game/src/companion/companion_room_service_host.gd").read_text(encoding="utf-8")
    websocket_source = (ROOT / "game/src/companion/companion_websocket_transport.gd").read_text(encoding="utf-8")
    if "console.log" in worker_source or "console.log" in coordinator_source:
        failures.append("room service must not log payloads or capabilities")
    for forbidden in ("serviceWorker", "Notification.requestPermission", "getUserMedia"):
        if forbidden in browser_source:
            failures.append(f"browser companion includes out-of-scope API: {forbidden}")
    if "advanceTo" in coordinator_source or "ExpirySteps" in coordinator_source:
        failures.append("room service production model must use persisted elapsed time, not manually advanced test steps")
    if "CompanionWireCodec.parse_wire_envelope" not in websocket_source or "CompanionWireCodec.stringify_wire_envelope" not in websocket_source:
        failures.append("Godot WebSocket transport must convert both directions at the wire boundary")
    if "print(" in host_source or "_host_capability" not in host_source:
        failures.append("native room-service host must retain authorization privately without logging it")

    if failures:
        print("\n".join(failures))
        return 1
    print("Companion repository/privacy validation passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
