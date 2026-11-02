#!/usr/bin/env python3
"""Validate deterministic PROTO-SCREEN-001 presentation evidence artifacts."""

from __future__ import annotations

import json
import struct
import sys
from pathlib import Path

PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
RESOLUTIONS = {
    "1080p": (1920, 1080),
    "4k": (3840, 2160),
}
STAGES = {
    "screen_shared": ("SHARED", 0, "MAP / BOARD"),
    "screen_split_2": ("SPLIT_2", 2, "MAP / BOARD"),
    "screen_split_4": ("SPLIT_4", 4, "MAP / BOARD"),
    "screen_grid_map": ("GRID_3X3", 8, "MAP / BOARD"),
    "screen_grid_objective": ("GRID_3X3", 8, "OBJECTIVE / PHASE"),
    "screen_grid_terror": ("GRID_3X3", 8, "TERROR EVENT"),
}
NUMERIC_METRICS = (
    "fps",
    "process_ms",
    "physics_ms",
    "frame_setup_cpu_ms",
    "pane_canvas_draw_calls_total",
)


def fail(message: str) -> None:
    raise AssertionError(message)


def png_size(path: Path) -> tuple[int, int]:
    data = path.read_bytes()[:24]
    if len(data) < 24 or data[:8] != PNG_SIGNATURE or data[12:16] != b"IHDR":
        fail(f"{path}: invalid PNG header")
    return struct.unpack(">II", data[16:24])


def require_nonnegative_number(metrics: dict[str, object], key: str, source: Path) -> None:
    value = metrics.get(key)
    if not isinstance(value, (int, float)) or isinstance(value, bool) or value < 0:
        fail(f"{source}: {key} must be a non-negative number, got {value!r}")


def require_canvas_stats(value: object, source: Path, label: str) -> None:
    if not isinstance(value, dict):
        fail(f"{source}: {label} must be an object")
    for key in ("objects", "primitives", "draw_calls"):
        metric = value.get(key)
        if not isinstance(metric, int) or isinstance(metric, bool) or metric < 0:
            fail(f"{source}: {label}.{key} must be a non-negative integer")


def validate_pair(root: Path, resolution_label: str, stage: str) -> None:
    expected_width, expected_height = RESOLUTIONS[resolution_label]
    expected_mode, expected_panes, expected_common = STAGES[stage]
    stem = f"{resolution_label}-{stage}"
    png_path = root / f"{stem}.png"
    json_path = root / f"{stem}.json"
    if not png_path.is_file():
        fail(f"missing {png_path}")
    if not json_path.is_file():
        fail(f"missing {json_path}")
    width, height = png_size(png_path)
    if (width, height) != (expected_width, expected_height):
        fail(
            f"{png_path}: expected {expected_width}x{expected_height}, "
            f"got {width}x{height}"
        )
    metrics = json.loads(json_path.read_text(encoding="utf-8"))
    if metrics.get("stage") != stage:
        fail(f"{json_path}: stage mismatch: {metrics.get('stage')!r}")
    if metrics.get("rendering_method") != "gl_compatibility":
        fail(f"{json_path}: Compatibility renderer was not active")
    if (metrics.get("image_width"), metrics.get("image_height")) != (
        expected_width,
        expected_height,
    ):
        fail(f"{json_path}: image dimensions do not match requested resolution")
    if metrics.get("presentation_mode") != expected_mode:
        fail(
            f"{json_path}: expected mode {expected_mode}, "
            f"got {metrics.get('presentation_mode')!r}"
        )
    if metrics.get("active_player_panes") != expected_panes:
        fail(
            f"{json_path}: expected {expected_panes} active panes, "
            f"got {metrics.get('active_player_panes')!r}"
        )
    if metrics.get("common_pane_state") != expected_common:
        fail(
            f"{json_path}: expected common pane {expected_common}, "
            f"got {metrics.get('common_pane_state')!r}"
        )
    if metrics.get("rules_hud_visible") is not True:
        fail(
            f"{json_path}: rules_hud_visible must be true for screen evidence, "
            f"got {metrics.get('rules_hud_visible')!r}"
        )
    for key in NUMERIC_METRICS:
        require_nonnegative_number(metrics, key, json_path)
    require_canvas_stats(metrics.get("root_canvas"), json_path, "root_canvas")
    pane_canvas = metrics.get("pane_canvas")
    if not isinstance(pane_canvas, list) or len(pane_canvas) != expected_panes:
        fail(f"{json_path}: pane_canvas count does not match active pane count")
    for index, pane in enumerate(pane_canvas):
        require_canvas_stats(pane, json_path, f"pane_canvas[{index}]")


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: validate_presentation_evidence.py <evidence-directory>", file=sys.stderr)
        return 2
    root = Path(sys.argv[1])
    if not root.is_dir():
        print(f"evidence directory not found: {root}", file=sys.stderr)
        return 2
    try:
        for resolution_label in RESOLUTIONS:
            for stage in STAGES:
                validate_pair(root, resolution_label, stage)
    except (AssertionError, json.JSONDecodeError, OSError) as error:
        print(f"presentation evidence validation failed: {error}", file=sys.stderr)
        return 1
    print(
        "presentation evidence validation passed: "
        f"{len(RESOLUTIONS) * len(STAGES)} screenshot/metrics pairs"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
