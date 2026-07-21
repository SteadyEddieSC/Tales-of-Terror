#!/usr/bin/env python3
"""Focused tests for offline v0.1.3 pilot evidence and findings tooling."""

from __future__ import annotations

import ast
import copy
import hashlib
import json
import tempfile
import unittest
from pathlib import Path

import pilot_evidence as pilot


class PilotEvidenceTests(unittest.TestCase):
    def setUp(self) -> None:
        self.blank = json.loads(pilot.BLANK_PILOT.read_text(encoding="utf-8"))

    def _identity(self, platform: str = "windows") -> dict:
        return {
            "source_sha": "a" * 40,
            "platform": platform,
            "architecture": "x86_64",
            "artifact_name": f"lantern-house-internal-playtest-v0.1.3-{platform}-x86_64",
            "archive_sha256": "b" * 64,
            "native_sha256": "c" * 64,
            "runtime_digest": "d" * 64,
            "bundle_digest": "e" * 64,
            "build_timestamp_utc": "2026-07-21T18:00:00Z",
            "classification": "internal_playtest",
        }

    def _record(self) -> dict:
        value = copy.deepcopy(self.blank)
        value["candidate"] = self._identity()
        value["session"] = {
            "session_id": "PILOT-AB12CD34",
            "session_date_utc": "2026-07-21",
            "mode": "household_in_room",
            "facilitator_evidence_class": "physical_in_room",
            "participant_count": 2,
            "stable_seat_count": 2,
            "participant_grouping": ["adult"],
            "controller_count": 2,
            "controller_categories": ["generic_gamepad"],
            "phone_path": "none",
            "display_class": "television",
            "resolution_category": "1080p",
        }
        value["route"]["completion_state"] = "ending_reached"
        value["route"]["report_export"] = "pass"
        value["route"]["report_hashes"] = [{"format": "json", "sha256": "f" * 64}]
        value["durations"] = [{"stage": "active_tale", "minutes": 30}]
        value["counts"] = {"interruptions": 0, "assistance": 1}
        value["manual_checks"][0] = {
            "id": "one_physical_controller",
            "status": "pass",
            "evidence_class": "physical_in_room",
            "notes": "Controller input was directly observed.",
        }
        value["observations"] = [{
            "source_type": "observed",
            "evidence_class": "physical_in_room",
            "category": "controller_input",
            "stage": "lobby",
            "note": "Both stable seats joined before confirmation.",
        }]
        value["questionnaire"] = [{
            "question_id": "Q2",
            "evidence_class": "physical_in_room",
            "rating": 4,
            "response": "Join guidance was mostly clear.",
        }]
        value["declarations"].update({
            "voluntary_participation_confirmed": True,
            "stop_at_any_time_explained": True,
            "direct_identifiers_excluded": True,
            "human_observation_entered": True,
        })
        return value

    def _write_json(self, path: Path, value: dict) -> None:
        path.write_text(json.dumps(value, indent=2) + "\n", encoding="utf-8")

    def test_committed_templates_are_exact_blank_defaults(self) -> None:
        pilot.validate_templates()
        self.assertEqual(self.blank["session"]["mode"], "not_tested")
        self.assertEqual(self.blank["route"]["completion_state"], "not_observed")
        self.assertTrue(all(item["status"] == "not_tested" for item in self.blank["manual_checks"]))
        self.assertEqual(self.blank["observations"], [])
        self.assertEqual(self.blank["questionnaire"], [])

    def test_valid_human_record_accepts_exact_candidate(self) -> None:
        result = pilot.validate_pilot_record(self._record())
        self.assertEqual(result["candidate"], self._identity())

    def test_unknown_record_key_rejects(self) -> None:
        value = self._record()
        value["participant_name"] = "prohibited"
        with self.assertRaises(pilot.PilotError):
            pilot.validate_pilot_record(value)

    def test_candidate_identity_mismatch_rejects(self) -> None:
        with tempfile.TemporaryDirectory() as root_text:
            root = Path(root_text)
            package = root / "package"
            package.mkdir()
            self._write_json(package / pilot.PACKAGE_FILE, self._record())
            identity = self._identity()
            identity["source_sha"] = "9" * 40
            identity_path = root / "identity.json"
            self._write_json(identity_path, identity)
            with self.assertRaises(pilot.PilotError):
                pilot.normalize(package, identity_path, root / "normalized.json")

    def test_unknown_package_file_and_nested_folder_reject(self) -> None:
        with tempfile.TemporaryDirectory() as root_text:
            package = Path(root_text)
            self._write_json(package / pilot.PACKAGE_FILE, self._record())
            (package / "raw_report.json").write_text("{}", encoding="utf-8")
            identity = package / "identity.json"
            self._write_json(identity, self._identity())
            with self.assertRaises(pilot.PilotError):
                pilot.normalize(package, identity, package / "output.json")

    def test_path_traversal_and_absolute_members_reject(self) -> None:
        root = Path(".")
        for member in ("../PILOT_SESSION_RECORD.json", "/PILOT_SESSION_RECORD.json", "nested/PILOT_SESSION_RECORD.json"):
            with self.subTest(member=member), self.assertRaises(pilot.PilotError):
                pilot.safe_package_path(root, member)

    def test_oversized_package_rejects(self) -> None:
        with tempfile.TemporaryDirectory() as root_text:
            root = Path(root_text)
            source = root / pilot.PACKAGE_FILE
            source.write_bytes(b" " * (pilot.MAX_PACKAGE_FILE_BYTES + 1))
            identity = root.parent / "synthetic_identity.json"
            try:
                self._write_json(identity, self._identity())
                with self.assertRaises(pilot.PilotError):
                    pilot.normalize(root, identity, root / "normalized.json")
            finally:
                identity.unlink(missing_ok=True)

    def test_private_identifiers_and_paths_reject(self) -> None:
        prohibited = (
            "contact person@example.com",
            "host 192.0.2.44",
            "C:\\Users\\Example\\report.json",
            "/home/example/private/report.json",
            "Documents\\Codex\\Tales-of-Terror",
            "room code: ABCD-1234",
            "device id: controller-44",
            "username=example_user",
            "token=github_pat_example_private_value",
            "participant name: Example Person",
            "age 17",
            "+1 555-555-0100",
        )
        for text in prohibited:
            value = self._record()
            value["observations"][0]["note"] = text
            with self.subTest(text=text), self.assertRaises(pilot.PilotError):
                pilot.validate_pilot_record(value)

    def test_automated_evidence_cannot_promote_to_physical(self) -> None:
        value = self._record()
        value["observations"][0].update({"source_type": "automated", "evidence_class": "physical_in_room"})
        with self.assertRaises(pilot.PilotError):
            pilot.validate_pilot_record(value)
        value = self._record()
        value["manual_checks"][0]["evidence_class"] = "automated_ci"
        with self.assertRaises(pilot.PilotError):
            pilot.validate_pilot_record(value)

    def test_normalization_is_deterministic_and_records_source_hash(self) -> None:
        with tempfile.TemporaryDirectory() as root_text:
            root = Path(root_text)
            package = root / "package"
            package.mkdir()
            source = package / pilot.PACKAGE_FILE
            self._write_json(source, self._record())
            identity = root / "identity.json"
            self._write_json(identity, self._identity())
            first = root / "first.json"
            second = root / "second.json"
            pilot.normalize(package, identity, first)
            pilot.normalize(package, identity, second)
            self.assertEqual(first.read_bytes(), second.read_bytes())
            normalized = json.loads(first.read_text(encoding="utf-8"))
            self.assertEqual(normalized["provenance"][0]["sha256"], hashlib.sha256(source.read_bytes()).hexdigest())

    def _finding(self) -> dict:
        return {
            "category": "usability_guidance",
            "evidence_source": "observed",
            "session_id": "PILOT-AB12CD34",
            "classification": "physical_in_room",
            "severity": "P2_moderate",
            "reproducibility": "single_occurrence",
            "confidence": "medium",
            "evidence_limits": "One bounded pilot observation only.",
            "affected_platform": "windows",
            "seat_count": 2,
            "stage": "lobby",
            "steps": ["Launch the reviewed candidate.", "Join two stable seats."],
            "expected_result": "Roster confirmation is understood.",
            "observed_result": "One assistance prompt was needed.",
            "notes": "No participant intent is inferred.",
            "disposition": "open_issue_required",
            "proposed_issue_title": "Clarify roster confirmation guidance",
            "certification_limit": pilot.CERTIFICATION_LIMIT,
        }

    def test_findings_ids_and_output_are_deterministic(self) -> None:
        with tempfile.TemporaryDirectory() as root_text:
            root = Path(root_text)
            session = root / "session.json"
            self._write_json(session, self._record())
            findings = root / "input.json"
            self._write_json(findings, {"findings": [self._finding()]})
            first = root / "first.json"
            second = root / "second.json"
            pilot.generate_findings(session, findings, first)
            pilot.generate_findings(session, findings, second)
            self.assertEqual(first.read_bytes(), second.read_bytes())
            finding_id = json.loads(first.read_text(encoding="utf-8"))["findings"][0]["finding_id"]
            self.assertRegex(finding_id, r"^FND-[0-9A-F]{12}$")

    def test_findings_reject_automated_source_and_unknown_values(self) -> None:
        value = self._finding()
        value["evidence_source"] = "automated"
        with self.assertRaises(pilot.PilotError):
            pilot._validate_finding_input(value, self._record())
        value = self._finding()
        value["severity"] = "inferred_critical"
        with self.assertRaises(pilot.PilotError):
            pilot._validate_finding_input(value, self._record())

    def test_tool_has_no_network_imports(self) -> None:
        source = Path(pilot.__file__).read_text(encoding="utf-8")
        tree = ast.parse(source)
        imported = set()
        for node in ast.walk(tree):
            if isinstance(node, ast.Import):
                imported.update(alias.name.split(".")[0] for alias in node.names)
            elif isinstance(node, ast.ImportFrom) and node.module:
                imported.add(node.module.split(".")[0])
        self.assertTrue(imported.isdisjoint({"socket", "urllib", "http", "requests", "ftplib", "smtplib"}))


if __name__ == "__main__":
    unittest.main()
