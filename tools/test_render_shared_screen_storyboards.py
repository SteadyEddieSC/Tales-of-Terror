#!/usr/bin/env python3
"""Regression tests for the offline shared-screen storyboard renderer."""

from __future__ import annotations

import tempfile
from pathlib import Path

import render_shared_screen_storyboards as renderer
import validate_shared_screen_storyboards as validator


def main() -> int:
    paths = validator.discover_manifests()
    diagnostics, summary = validator.validate_manifests(paths)
    assert diagnostics == [], [item.as_dict() for item in diagnostics]
    records = []
    for path in paths:
        records.extend(validator.read_json(path)["entries"])

    first = renderer.render_html(records, summary["identity"])
    second = renderer.render_html(list(reversed(records)), summary["identity"])
    assert first == second
    assert first.startswith("<!doctype html>")
    assert "PREPRODUCTION ONLY" in first
    assert "Lantern House remains the sole production Tale" in first
    assert summary["identity"] in first
    assert first.count('class="storyboard"') == 22
    for index in range(1, 23):
        storyboard_id = f"DH-UI-{index:03d}"
        assert f'id="{storyboard_id}"' in first
        assert f'href="#{storyboard_id}"' in first
    assert "PRIVATE HANDOFF" in first
    assert "STABLE-SEAT RAIL" in first
    assert "CAPTIONS" in first
    assert "http://" not in first
    assert "https://" not in first
    assert "<script" not in first.lower()
    assert "src=" not in first.lower()

    with tempfile.TemporaryDirectory() as temporary:
        output = Path(temporary) / "storyboards.html"
        result = renderer.main(["--output", str(output), *map(str, paths)])
        assert result == 0
        assert output.is_file()
        assert output.read_text(encoding="utf-8") == first
        assert output.stat().st_size > 100_000

    print("Shared-screen storyboard renderer tests passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
