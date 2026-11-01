#!/usr/bin/env python3
"""Regression tests for presentation evidence metrics validation."""

from __future__ import annotations

import json
import struct
import tempfile
import unittest
from pathlib import Path

import validate_presentation_evidence as validator

PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"


def write_minimal_png(path: Path, width: int, height: int) -> None:
    ihdr = struct.pack(">II", width, height) + b"\x08\x06\x00\x00\x00"
    import zlib

    def chunk(tag: bytes, payload: bytes) -> bytes:
        crc = zlib.crc32(tag + payload) & 0xFFFFFFFF
        return struct.pack(">I", len(payload)) + tag + payload + struct.pack(">I", crc)

    ihdr_chunk = chunk(b"IHDR", ihdr)
    idat_chunk = chunk(b"IDAT", zlib.compress(b"\x00" * (width * height * 4 + height)))
    iend_chunk = chunk(b"IEND", b"")
    path.write_bytes(PNG_SIGNATURE + ihdr_chunk + idat_chunk + iend_chunk)


def base_metrics(stage: str, width: int, height: int) -> dict[str, object]:
    expected_mode, expected_panes, expected_common = validator.STAGES[stage]
    pane = {"objects": 1, "primitives": 1, "draw_calls": 1, "pane_index": 0}
    return {
        "stage": stage,
        "sandbox_hud_visible": False,
        "image_width": width,
        "image_height": height,
        "window_width": width,
        "window_height": height,
        "rendering_method": "gl_compatibility",
        "rendering_driver": "dummy",
        "fps": 60.0,
        "process_ms": 1.0,
        "physics_ms": 0.0,
        "frame_setup_cpu_ms": 0.0,
        "presentation_mode": expected_mode,
        "active_player_panes": expected_panes,
        "common_pane_state": expected_common,
        "root_canvas": {"objects": 1, "primitives": 1, "draw_calls": 1},
        "pane_canvas_draw_calls_total": expected_panes,
        "pane_canvas": [dict(pane, pane_index=index) for index in range(expected_panes)],
    }


class PresentationEvidenceValidatorTests(unittest.TestCase):
    def test_rejects_visible_sandbox_hud(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            stage = "screen_shared"
            width, height = validator.RESOLUTIONS["1080p"]
            write_minimal_png(root / "1080p-screen_shared.png", width, height)
            metrics = base_metrics(stage, width, height)
            metrics["sandbox_hud_visible"] = True
            (root / "1080p-screen_shared.json").write_text(
                json.dumps(metrics), encoding="utf-8"
            )
            with self.assertRaises(AssertionError) as context:
                validator.validate_pair(root, "1080p", stage)
            self.assertIn("sandbox_hud_visible", str(context.exception))

    def test_accepts_suppressed_sandbox_hud(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            stage = "screen_grid_terror"
            width, height = validator.RESOLUTIONS["1080p"]
            write_minimal_png(root / f"1080p-{stage}.png", width, height)
            metrics = base_metrics(stage, width, height)
            (root / f"1080p-{stage}.json").write_text(
                json.dumps(metrics), encoding="utf-8"
            )
            validator.validate_pair(root, "1080p", stage)


if __name__ == "__main__":
    unittest.main()
