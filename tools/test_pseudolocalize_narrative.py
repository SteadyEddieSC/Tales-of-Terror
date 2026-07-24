#!/usr/bin/env python3
"""Regression tests for deterministic narrative pseudolocalization."""

from __future__ import annotations

import json
import tempfile
from pathlib import Path

from pseudolocalize_narrative import (
    PseudolocalizationError,
    discover_voice_manifests,
    generate_package,
    pseudolocalize_text,
)


def main() -> int:
    source = "The {route_name} is unstable. Choose {action_name}."
    first = pseudolocalize_text(source, 0.35)
    second = pseudolocalize_text(source, 0.35)
    assert first == second
    assert first.startswith("[!! ") and first.endswith(" !!]")
    assert "{route_name}" in first
    assert "{action_name}" in first
    assert first.count("{route_name}") == 1
    assert first.count("{action_name}") == 1
    assert len(first) > len(source)
    assert "Ŧ" in first or "ŧ" in first

    no_placeholder = pseudolocalize_text("High Water is active.", 0.5)
    assert len(no_placeholder) > len("High Water is active.")

    try:
        pseudolocalize_text("", 0.35)
    except PseudolocalizationError as exc:
        assert "source text must be non-empty" in str(exc)
    else:
        raise AssertionError("Expected empty-source failure")

    try:
        pseudolocalize_text("Text", 1.5)
    except PseudolocalizationError as exc:
        assert "expansion ratio" in str(exc)
    else:
        raise AssertionError("Expected expansion-ratio failure")

    package = generate_package(discover_voice_manifests(), 0.35)
    assert package["locale"] == "qps-ploc"
    assert package["status"] == "generated_test_only"
    assert package["family_count"] >= 22
    assert package["string_count"] == package["family_count"] * 4
    assert len(package["families"]) == package["family_count"]
    assert all(
        set(family["strings"])
        == {"spooky", "grim", "gore_and_dread", "plain_system"}
        for family in package["families"]
    )

    source_family_ids = [family["family_id"] for family in package["families"]]
    assert len(source_family_ids) == len(set(source_family_ids))

    with tempfile.TemporaryDirectory() as tmp:
        output = Path(tmp) / "pseudo.json"
        output.write_text(
            json.dumps(package, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        loaded = json.loads(output.read_text(encoding="utf-8"))
        assert loaded == package
        assert output.stat().st_size > 0

    print("Narrative pseudolocalization tests passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
