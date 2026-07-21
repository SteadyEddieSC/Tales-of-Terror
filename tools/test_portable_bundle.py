#!/usr/bin/env python3
"""Focused portable-bundle policy and assembly regression tests."""

from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest import mock

import portable_bundle as portable


SOURCE_COMMIT = "a" * 40


class PortableBundleTests(unittest.TestCase):
    def test_repository_and_pilot_defaults_validate(self) -> None:
        portable.validate_repository()
        record = portable.validate_pilot_record()
        self.assertTrue(all(item["status"] == "not_tested" for item in record["manual_checks"]))
        self.assertTrue(all(item["evidence_class"] == "not_tested" for item in record["manual_checks"]))
        self.assertEqual(record["observations"], [])
        self.assertEqual(record["questionnaire"], [])

    def test_repeated_assembly_has_stable_content_identity(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            binary = root / "fixture.bin"
            binary.write_bytes(b"bounded deterministic runtime fixture\n")
            first, first_archive, _ = portable.assemble(
                "linux", SOURCE_COMMIT, "2026-07-21T01:00:00Z", root / "first", binary
            )
            second, second_archive, _ = portable.assemble(
                "linux", SOURCE_COMMIT, "2026-07-21T02:00:00Z", root / "second", binary
            )
            first_manifest = portable.validate_bundle(first)
            second_manifest = portable.validate_bundle(second)
            self.assertEqual(first_manifest["tale_package"], portable._tale_package_identity())
            self.assertEqual(first_manifest["tale_catalog"], portable._tale_catalog_identity())
            self.assertEqual(
                first_manifest["runtime_content"]["digest"],
                second_manifest["runtime_content"]["digest"],
            )
            self.assertEqual(
                first_manifest["bundle_content"]["digest"],
                second_manifest["bundle_content"]["digest"],
            )
            self.assertNotEqual(
                first_manifest["build_timestamp_utc"], second_manifest["build_timestamp_utc"]
            )
            self.assertNotEqual(portable._sha256(first_archive), portable._sha256(second_archive))

    def test_generated_identity_is_exact_internal_artifact_schema(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            identity_path = Path(temporary) / "build_identity.generated.json"
            with mock.patch.object(portable, "BUILD_IDENTITY_PATH", identity_path):
                for platform in ("windows", "linux"):
                    portable.write_build_identity(platform, SOURCE_COMMIT)
                    value = json.loads(identity_path.read_text(encoding="utf-8"))
                    self.assertEqual(
                        value,
                        {
                            "schema_version": 1,
                            "release": "v0.1.5",
                            "source_commit": SOURCE_COMMIT,
                            "platform": platform,
                            "architecture": "x86_64",
                            "classification": "internal_playtest",
                        },
                    )
                for invalid_source in ("a" * 39, "A" * 40, "g" * 40):
                    with self.assertRaises(portable.BundleError):
                        portable.write_build_identity("windows", invalid_source)

    def test_bundle_documents_have_actionable_private_report_guidance(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            binary = root / "fixture.bin"
            binary.write_bytes(b"fixture\n")
            bundle, _, _ = portable.assemble(
                "windows", SOURCE_COMMIT, None, root / "output", binary
            )
            document_names = (
                "START_HERE.md",
                "FACILITATOR_GUIDE.md",
                "PRIVACY_AND_LIMITATIONS.md",
            )
            for name in document_names:
                text = (bundle / name).read_text(encoding="utf-8")
                for location in portable.REPORT_LOCATION_TOKENS:
                    self.assertIn(location, text, name)
                self.assertIn("provisional", text.lower(), name)
                for pattern in portable.CONCRETE_PRIVATE_PATH_PATTERNS:
                    self.assertIsNone(pattern.search(text), name)
                self.assertIsNone(
                    re.search(r"(?:room_secret|token|device_id|ip_address)\s*=", text), name
                )

    def test_bundle_contains_only_bounded_blank_pilot_materials(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            binary = root / "fixture.bin"
            binary.write_bytes(b"fixture\n")
            bundle, _, _ = portable.assemble(
                "linux", SOURCE_COMMIT, "2026-07-21T18:00:00Z", root / "output", binary
            )
            expected = {
                "FACILITATOR_GUIDE.md",
                "OBSERVATION_SHEET.md",
                "POST_SESSION_QUESTIONNAIRE.md",
                "PILOT_SESSION_SCHEMA.json",
                "PILOT_SESSION_RECORD.json",
                "FINDINGS_REGISTER_SCHEMA.json",
                "FINDINGS_REGISTER.json",
            }
            self.assertTrue(expected <= portable.expected_files("linux"))
            record = json.loads((bundle / "PILOT_SESSION_RECORD.json").read_text(encoding="utf-8"))
            self.assertEqual(record["observations"], [])
            self.assertEqual(record["questionnaire"], [])
            self.assertTrue(all(item["status"] == "not_tested" for item in record["manual_checks"]))
            findings = json.loads((bundle / "FINDINGS_REGISTER.json").read_text(encoding="utf-8"))
            self.assertEqual(findings["findings"], [])
            actual = {path.relative_to(bundle).as_posix() for path in bundle.rglob("*") if path.is_file()}
            self.assertEqual(actual, portable.expected_files("linux"))

    def test_versioned_output_never_overwrites(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            binary = root / "fixture.bin"
            binary.write_bytes(b"fixture\n")
            portable.assemble("windows", SOURCE_COMMIT, None, root / "output", binary)
            with self.assertRaises(portable.BundleError):
                portable.assemble("windows", SOURCE_COMMIT, None, root / "output", binary)

    def test_allowlist_rejects_extra_and_missing_files(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            binary = root / "fixture.bin"
            binary.write_bytes(b"fixture\n")
            bundle, _, _ = portable.assemble("windows", SOURCE_COMMIT, None, root / "output", binary)
            extra = bundle / ".env"
            extra.write_text("TOKEN=forbidden\n", encoding="utf-8")
            with self.assertRaises(portable.BundleError):
                portable.validate_bundle(bundle)
            extra.unlink()
            (bundle / "START_HERE.md").unlink()
            with self.assertRaises(portable.BundleError):
                portable.validate_bundle(bundle)

    def test_manifest_exact_keys_hashes_and_privacy(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            binary = root / "fixture.bin"
            binary.write_bytes(b"fixture\n")
            bundle, _, _ = portable.assemble("linux", SOURCE_COMMIT, None, root / "output", binary)
            manifest_path = bundle / "build_manifest.json"
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            manifest["username"] = "private-builder"
            with self.assertRaises(portable.BundleError):
                portable.validate_manifest(manifest, bundle)
            manifest.pop("username")
            manifest["bundle_files"][0]["sha256"] = "0" * 64
            with self.assertRaises(portable.BundleError):
                portable.validate_manifest(manifest, bundle)

    def test_launcher_missing_file_and_success_paths(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            if os.name == "nt":
                launcher = root / "launch.cmd"
                shutil.copy2(portable.ROOT / "packaging/portable/launch_windows.cmd", launcher)
                missing = subprocess.run(
                    ["cmd.exe", "/d", "/c", str(launcher)], capture_output=True, text=True
                )
                self.assertEqual(missing.returncode, 2)
                self.assertIn("Required game executable is missing", missing.stderr)
                shutil.copy2(Path(os.environ["WINDIR"]) / "System32/cmd.exe", root / "lantern_house_internal.exe")
                success = subprocess.run(
                    ["cmd.exe", "/d", "/c", str(launcher), "/d", "/c", "exit", "0"],
                    capture_output=True,
                    text=True,
                )
                self.assertEqual(success.returncode, 0, success.stderr)
            else:
                launcher = root / "launch.sh"
                shutil.copy2(portable.ROOT / "packaging/portable/launch_linux.sh", launcher)
                launcher.chmod(0o755)
                missing = subprocess.run([str(launcher)], capture_output=True, text=True)
                self.assertEqual(missing.returncode, 2)
                self.assertIn("missing or not executable", missing.stderr)
                game = root / "lantern_house_internal.x86_64"
                game.write_text("#!/bin/sh\nexit 0\n", encoding="utf-8")
                game.chmod(0o755)
                success = subprocess.run([str(launcher)], capture_output=True, text=True)
                self.assertEqual(success.returncode, 0, success.stderr)


if __name__ == "__main__":
    unittest.main(verbosity=2)
