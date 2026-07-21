#!/usr/bin/env python3
"""Focused Tale-package authoring validator regression tests."""

from __future__ import annotations

import copy
import json
import unittest
from pathlib import Path
from typing import Any

import tale_package


FIXTURES = tale_package.ROOT / "game/tests/fixtures/tale_package_invalid_cases_v1.json"


def _parent(value: Any, pointer: str) -> tuple[Any, str]:
    parts = pointer.strip("/").split("/")
    current = value
    for part in parts[:-1]:
        current = current[int(part)] if isinstance(current, list) else current[part]
    return current, parts[-1]


def _mutate(value: dict[str, Any], mutation: dict[str, Any]) -> None:
    parent, leaf = _parent(value, mutation["path"])
    operation = mutation["operation"]
    key: int | str = int(leaf) if isinstance(parent, list) else leaf
    if operation == "set":
        parent[key] = mutation["value"]
    elif operation == "delete":
        del parent[key]
    elif operation == "append":
        parent[key].append(mutation["value"])
    elif operation == "swap":
        first, second = mutation["indices"]
        parent[key][first], parent[key][second] = parent[key][second], parent[key][first]
    else:
        raise AssertionError(f"unsupported synthetic mutation: {operation}")


class TalePackageTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.package = json.loads(tale_package.DEFAULT_PACKAGE.read_text(encoding="utf-8"))
        cls.fixtures = json.loads(FIXTURES.read_text(encoding="utf-8"))

    def test_valid_lantern_house_package_and_summary(self) -> None:
        self.assertEqual(tale_package.validate(self.package), [])
        result = tale_package.summary(self.package)
        self.assertTrue(result["accepted"])
        self.assertEqual(result["package_kind"], "tale")
        self.assertEqual(result["schema_version"], 1)
        self.assertEqual(result["tale_id"], "lantern_house_vertical_slice")
        self.assertRegex(result["sha256"], r"^[0-9a-f]{64}$")
        self.assertEqual(result["inventory"]["stages"], 5)
        self.assertEqual(result["inventory"]["roles"], 8)
        self.assertEqual(len(result["source_ledger"]), 6)

    def test_canonicalization_and_digest_are_order_independent_for_objects(self) -> None:
        reversed_root = {key: self.package[key] for key in reversed(list(self.package))}
        self.assertEqual(
            tale_package.canonical_bytes(self.package),
            tale_package.canonical_bytes(reversed_root),
        )
        self.assertEqual(
            tale_package.package_digest(self.package),
            tale_package.package_digest(reversed_root),
        )
        changed = copy.deepcopy(self.package)
        changed["package_version"] = 2
        self.assertNotEqual(
            tale_package.package_digest(self.package),
            tale_package.package_digest(changed),
        )

    def test_every_synthetic_negative_fixture_is_rejected_actionably(self) -> None:
        self.assertEqual(
            self.fixtures["fixture_kind"],
            "synthetic_invalid_tale_package_cases_not_shipped_content",
        )
        seen: set[str] = set()
        for fixture in self.fixtures["cases"]:
            with self.subTest(fixture=fixture["id"]):
                candidate = copy.deepcopy(self.package)
                _mutate(candidate, fixture["mutation"])
                diagnostics = tale_package.validate(candidate)
                codes = {item.code for item in diagnostics}
                self.assertIn(fixture["expected_code"], codes, diagnostics)
                self.assertTrue(all(item.path.startswith("/") for item in diagnostics))
                self.assertTrue(all(item.message for item in diagnostics))
                seen.add(fixture["expected_code"])
        self.assertEqual(
            seen,
            {
                "duplicate_id",
                "generated_reference",
                "incompatible_social_declaration",
                "invalid_privacy",
                "invalid_transition",
                "missing_fallback",
                "missing_required_field",
                "network_url",
                "orphaned_record",
                "prohibited_path",
                "secret",
                "unreachable_stage",
                "unresolved_localization",
                "unresolved_reference",
                "unstable_identity",
                "unstable_ordering",
                "unsupported_player_count",
                "unsupported_schema",
            },
        )

    def test_validator_is_offline_and_has_no_generated_output(self) -> None:
        source = Path(tale_package.__file__).read_text(encoding="utf-8").lower()
        for prohibited in ("import requests", "import socket", "import urllib", "subprocess"):
            self.assertNotIn(prohibited, source)
        before = set(tale_package.ROOT.rglob("*"))
        self.assertEqual(tale_package.validate(self.package), [])
        after = set(tale_package.ROOT.rglob("*"))
        self.assertEqual(before, after)


if __name__ == "__main__":
    unittest.main(verbosity=2)
