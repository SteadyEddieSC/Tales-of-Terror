#!/usr/bin/env python3
"""Focused Tale-catalog validator and production-boundary regression tests."""

from __future__ import annotations

import copy
import json
import unittest
from pathlib import Path
from typing import Any

import tale_catalog


INVALID_FIXTURES = (
    tale_catalog.ROOT / "game/tests/fixtures/tale_catalog_invalid_cases_v1.json"
)
COORDINATOR = (
    tale_catalog.ROOT / "game/src/session/vertical_slice_coordinator.gd"
)
SELECTION_STATE = tale_catalog.ROOT / "game/src/session/tale_selection_state.gd"
SYNTHETIC_CATALOG = (
    tale_catalog.ROOT
    / "game/tests/fixtures/synthetic_two_entry_tale_catalog_v1.json"
)


def _resolve(value: Any, pointer: str) -> Any:
    current = value
    if pointer in ("", "/"):
        return current
    for part in pointer.strip("/").split("/"):
        current = current[int(part)] if isinstance(current, list) else current[part]
    return current


def _parent(value: Any, pointer: str) -> tuple[Any, str]:
    parts = pointer.strip("/").split("/")
    current = value
    for part in parts[:-1]:
        current = current[int(part)] if isinstance(current, list) else current[part]
    return current, parts[-1]


def _mutate(value: dict[str, Any], mutation: dict[str, Any]) -> None:
    operation = mutation["operation"]
    parent, leaf = _parent(value, mutation["path"])
    key: int | str = int(leaf) if isinstance(parent, list) else leaf
    if operation == "set":
        parent[key] = mutation["value"]
    elif operation == "delete":
        del parent[key]
    elif operation == "append_copy":
        parent[key].append(copy.deepcopy(_resolve(value, mutation["source_path"])))
    elif operation == "append_copy_with_set":
        candidate = copy.deepcopy(_resolve(value, mutation["source_path"]))
        target, target_leaf = _parent(candidate, mutation["set_path"])
        target[target_leaf] = mutation["value"]
        parent[key].append(candidate)
    else:
        raise AssertionError(f"unsupported synthetic catalog mutation: {operation}")


class TaleCatalogTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.catalog = json.loads(tale_catalog.DEFAULT_CATALOG.read_text(encoding="utf-8"))
        cls.fixtures = json.loads(INVALID_FIXTURES.read_text(encoding="utf-8"))

    def test_production_catalog_identity_inventory_and_coherence(self) -> None:
        self.assertEqual(
            tale_catalog.validate(
                self.catalog, expected_digest=tale_catalog.PRODUCTION_DIGEST
            ),
            [],
        )
        result = tale_catalog.summary(self.catalog)
        self.assertEqual(result["catalog_kind"], "tale_catalog")
        self.assertEqual(result["schema_version"], 1)
        self.assertEqual(result["catalog_version"], 1)
        self.assertEqual(result["sha256"], tale_catalog.PRODUCTION_DIGEST)
        self.assertEqual(result["default_tale_id"], "lantern_house_vertical_slice")
        self.assertEqual(
            result["inventory"],
            [
                {
                    "tale_id": "lantern_house_vertical_slice",
                    "package_sha256": "abb39d6bfbdf8d7de108379f08180c13efb99bbffa3e53f30eaaa8de7f459dee",
                    "provider_id": "lantern_house_authorities_v1",
                    "provider_version": 1,
                }
            ],
        )

    def test_canonicalization_is_stable_and_object_order_independent(self) -> None:
        reversed_root = {key: self.catalog[key] for key in reversed(list(self.catalog))}
        self.assertEqual(
            tale_catalog.canonical_bytes(self.catalog),
            tale_catalog.canonical_bytes(reversed_root),
        )
        self.assertEqual(
            tale_catalog.catalog_digest(self.catalog),
            tale_catalog.catalog_digest(reversed_root),
        )
        changed = copy.deepcopy(self.catalog)
        changed["catalog_version"] = 2
        self.assertNotEqual(
            tale_catalog.catalog_digest(self.catalog),
            tale_catalog.catalog_digest(changed),
        )

    def test_every_synthetic_negative_fixture_is_rejected_actionably(self) -> None:
        self.assertEqual(
            self.fixtures["fixture_kind"],
            "synthetic_invalid_tale_catalog_cases_not_shipped_content",
        )
        seen: set[str] = set()
        for fixture in self.fixtures["cases"]:
            with self.subTest(fixture=fixture["id"]):
                candidate = copy.deepcopy(self.catalog)
                _mutate(candidate, fixture["mutation"])
                diagnostics = tale_catalog.validate(candidate)
                codes = {item.code for item in diagnostics}
                self.assertIn(fixture["expected_code"], codes, diagnostics)
                self.assertTrue(all(item.path.startswith("/") for item in diagnostics))
                self.assertTrue(all(item.message for item in diagnostics))
                seen.add(fixture["expected_code"])
        self.assertEqual(
            seen,
            {
                "duplicate_source_role",
                "duplicate_tale_id",
                "entry_tale_id_mismatch",
                "incomplete_source_ledger",
                "invalid_default_tale",
                "network_url",
                "package_identity_mismatch",
                "package_kind_mismatch",
                "package_schema_mismatch",
                "package_version_mismatch",
                "prohibited_catalog_path",
                "prohibited_runtime_reference",
                "provider_reference_mismatch",
                "secret",
                "unstable_catalog_identity",
                "unstable_catalog_ordering",
                "unknown_provider",
                "unresolved_catalog_display",
                "unresolved_catalog_reference",
                "unsupported_catalog_schema",
                "missing_required_field",
            },
        )

    def test_generic_coordinator_has_no_lantern_provider_or_package_construction(self) -> None:
        source = COORDINATOR.read_text(encoding="utf-8")
        for prohibited in (
            "LanternHouseBoardDefinition",
            "LanternHouseRulesContent",
            "LanternHouseDirectorContent",
            "LanternHouseSocialContent",
            "lantern_house_vertical_slice_v1.json",
            "tale_package_v1.json",
        ):
            self.assertNotIn(prohibited, source)
        self.assertIn("_selection.registry.build_candidate", source)
        self.assertIn(
            "TaleCatalog.entry_by_id", SELECTION_STATE.read_text(encoding="utf-8")
        )

    def test_synthetic_two_entry_fixture_is_sorted_stable_and_not_production(self) -> None:
        fixture = json.loads(SYNTHETIC_CATALOG.read_text(encoding="utf-8"))
        self.assertEqual(
            tale_catalog.catalog_digest(fixture),
            "06a1f9968fa255aa9bad1cf09fe30ec2553e64599c3f8995d20aaa1610cc31c1",
        )
        self.assertEqual(
            [entry["tale_id"] for entry in fixture["entries"]],
            ["lantern_house_vertical_slice", "synthetic_fixture_tale"],
        )
        self.assertEqual(fixture["default_tale_id"], "lantern_house_vertical_slice")
        self.assertTrue(
            fixture["entries"][1]["package_path"].startswith("res://tests/fixtures/")
        )
        production_text = tale_catalog.DEFAULT_CATALOG.read_text(encoding="utf-8").lower()
        self.assertNotIn("synthetic", production_text)
        self.assertNotIn("res://tests/", production_text)

    def test_validator_is_offline_and_creates_no_output(self) -> None:
        source = Path(tale_catalog.__file__).read_text(encoding="utf-8").lower()
        for prohibited in (
            "import requests",
            "import socket",
            "import urllib",
            "subprocess",
        ):
            self.assertNotIn(prohibited, source)
        before = set(tale_catalog.ROOT.rglob("*"))
        self.assertEqual(
            tale_catalog.validate(
                self.catalog, expected_digest=tale_catalog.PRODUCTION_DIGEST
            ),
            [],
        )
        after = set(tale_catalog.ROOT.rglob("*"))
        self.assertEqual(before, after)


if __name__ == "__main__":
    unittest.main(verbosity=2)
