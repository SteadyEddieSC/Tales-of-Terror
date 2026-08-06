from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from validate_repository import Validator


class ValidatorTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        (self.root / "quality").mkdir()
        config = json.loads((Path(__file__).with_name("quality_config.json")).read_text(encoding="utf-8"))
        (self.root / "quality" / "quality_config.json").write_text(json.dumps(config), encoding="utf-8")
        (self.root / "game").mkdir()
        (self.root / ".github" / "workflows").mkdir(parents=True)
        (self.root / "quality" / "fixtures").mkdir(parents=True)

    def tearDown(self) -> None:
        self.temp.cleanup()

    def validator(self) -> Validator:
        return Validator(self.root, self.root / "quality" / "quality_config.json")

    def test_missing_scene_reference_blocks(self) -> None:
        scene = self.root / "game" / "broken.tscn"
        scene.write_text(
            '[gd_scene format=3]\n[ext_resource path="res://missing.gd" type="Script" id="1"]\n',
            encoding="utf-8",
        )
        report = self.validator().run(["references"])
        self.assertTrue(
            any(
                finding["code"] == "RESOURCE_MISSING" and finding["severity"] == "blocking"
                for finding in report["findings"]
            )
        )

    def test_script_missing_reference_is_advisory(self) -> None:
        script = self.root / "game" / "probe.gd"
        script.write_text('const PATH = "res://future.generated"\n', encoding="utf-8")
        (self.root / "game" / "main.tscn").write_text('[gd_scene format=3]\n', encoding="utf-8")
        report = self.validator().run(["references"])
        self.assertTrue(
            any(
                finding["code"] == "RESOURCE_MISSING" and finding["severity"] == "advisory"
                for finding in report["findings"]
            )
        )

    def test_unpinned_action_blocks(self) -> None:
        workflow = self.root / ".github" / "workflows" / "bad.yml"
        workflow.write_text(
            'permissions: {}\njobs:\n  x:\n    steps:\n      - uses: actions/checkout@v4\n',
            encoding="utf-8",
        )
        report = self.validator().run(["workflows"])
        self.assertTrue(any(finding["code"] == "WORKFLOW_ACTION_UNPINNED" for finding in report["findings"]))

    def test_duplicate_uid_blocks(self) -> None:
        for name in ("a.gd.uid", "b.gd.uid"):
            (self.root / "game" / name).write_text("uid://abc123\n", encoding="utf-8")
        report = self.validator().run(["references"])
        self.assertTrue(any(finding["code"] == "UID_DUPLICATE" for finding in report["findings"]))

    def test_localization_envelope_uses_entries_object(self) -> None:
        path = self.root / "game" / "localization_en.json"
        path.write_text(
            json.dumps(
                {
                    "schema_version": 1,
                    "locale": "en",
                    "entries": {"ui.confirm": "Confirm"},
                }
            ),
            encoding="utf-8",
        )
        report = self.validator().run(["data"])
        self.assertEqual(0, report["blocking_count"])

    def test_localization_duplicate_key_blocks(self) -> None:
        path = self.root / "game" / "localization_en.json"
        path.write_text(
            '{"entries":{"ui.confirm":"Confirm","ui.confirm":"Continue"}}',
            encoding="utf-8",
        )
        report = self.validator().run(["data"])
        self.assertTrue(any(finding["code"] == "DATA_JSON_DUPLICATE_KEY" for finding in report["findings"]))

    def test_future_save_fixture_is_valid_synthetic_input(self) -> None:
        fixtures = self.root / "quality" / "fixtures"
        for name, version in {
            "coordinator_snapshot_v2.json": 2,
            "coordinator_snapshot_future_v99.json": 99,
            "coordinator_snapshot_unknown_field.json": 2,
        }.items():
            (fixtures / name).write_text(
                json.dumps(
                    {
                        "fixture_classification": "synthetic_test_only",
                        "snapshot_version": version,
                    }
                ),
                encoding="utf-8",
            )
        (fixtures / "coordinator_snapshot_truncated.fixture").write_text(
            '{"snapshot_version": 2,',
            encoding="utf-8",
        )
        report = self.validator().run(["save-fixtures"])
        self.assertEqual(0, report["blocking_count"])


if __name__ == "__main__":
    unittest.main()
