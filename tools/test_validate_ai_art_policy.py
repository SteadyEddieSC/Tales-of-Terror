#!/usr/bin/env python3
from __future__ import annotations

import copy
import importlib.util
import unittest
from pathlib import Path

MODULE_PATH = Path(__file__).with_name("validate_ai_art_policy.py")
SPEC = importlib.util.spec_from_file_location("validate_ai_art_policy", MODULE_PATH)
assert SPEC and SPEC.loader
module = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(module)


class AIArtPolicyTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.policy = module.load(module.POLICY)
        cls.providers = module.load(module.PROVIDERS)
        cls.schema = module.load(module.SCHEMA)
        cls.ledger = module.load(module.LEDGER)

    def test_baseline_records_validate(self) -> None:
        module.validate_policy(copy.deepcopy(self.policy))
        module.validate_providers(copy.deepcopy(self.providers))
        module.validate_schema_and_ledger(copy.deepcopy(self.schema), copy.deepcopy(self.ledger))

    def test_generation_authority_fails_closed(self) -> None:
        value = copy.deepcopy(self.policy)
        value["decision"]["generation_authorized_by_this_release"] = True
        with self.assertRaises(module.ValidationError):
            module.validate_policy(value)

    def test_human_drawn_requirement_cannot_return(self) -> None:
        value = copy.deepcopy(self.policy)
        value["decision"]["human_drawn_or_painted_source_required"] = True
        with self.assertRaises(module.ValidationError):
            module.validate_policy(value)

    def test_live_generation_fails_closed(self) -> None:
        value = copy.deepcopy(self.policy)
        value["decision"]["live_generation_authorized"] = True
        with self.assertRaises(module.ValidationError):
            module.validate_policy(value)

    def test_copyrightability_cannot_be_assumed(self) -> None:
        value = copy.deepcopy(self.policy)
        value["decision"]["copyrightability_of_machine_determined_pixels_assumed"] = True
        with self.assertRaises(module.ValidationError):
            module.validate_policy(value)

    def test_external_reference_protection_is_required(self) -> None:
        value = copy.deepcopy(self.policy)
        value["supersession"]["preserved_requirements"].remove(
            "all_25_external_reference_images_remain_R1_private_internal_reference"
        )
        with self.assertRaises(module.ValidationError):
            module.validate_policy(value)

    def test_unknown_provider_is_rejected(self) -> None:
        value = copy.deepcopy(self.providers)
        value["providers"][0]["provider_id"] = "unknown_provider"
        with self.assertRaises(module.ValidationError):
            module.validate_providers(value)

    def test_google_cannot_be_promoted_without_conditional_review(self) -> None:
        value = copy.deepcopy(self.providers)
        value["providers"][1]["eligibility"] = "eligible_after_separate_generation_activation"
        with self.assertRaises(module.ValidationError):
            module.validate_providers(value)

    def test_policy_ledger_must_remain_empty(self) -> None:
        value = copy.deepcopy(self.ledger)
        value["state"] = "active_asset_ledger"
        with self.assertRaises(module.ValidationError):
            module.validate_schema_and_ledger(copy.deepcopy(self.schema), value)

    def test_schema_must_remain_closed(self) -> None:
        value = copy.deepcopy(self.schema)
        value["$defs"]["asset"]["additionalProperties"] = True
        with self.assertRaises(module.ValidationError):
            module.validate_schema_and_ledger(value, copy.deepcopy(self.ledger))

    def test_synthetic_asset_schema_contract(self) -> None:
        sha = "0" * 64
        asset = {
            "asset_id": "synthetic_policy_test",
            "tale_or_scope": "test_only",
            "asset_family": "test",
            "intended_use": "schema_validation_only",
            "provider_id": "openai_chatgpt_image_generation",
            "model_name": "test-model",
            "model_version": None,
            "generated_on": "2026-08-05T00:00:00Z",
            "account_owner": "test-owner",
            "prompt": "test prompt",
            "negative_prompt": None,
            "seed": None,
            "source_inputs": [],
            "generator_output_sha256": sha,
            "editable_master_path": None,
            "editable_master_sha256": None,
            "transformations": [],
            "runtime_exports": [],
            "c2pa_or_content_credentials": "not_detected",
            "watermark_or_signature_disposition": "none_detected",
            "human_contributions": ["selection"],
            "rights_review": {
                "reviewer": "test",
                "reviewed_on": "2026-08-05",
                "disposition": "pass",
                "notes": "synthetic",
            },
            "similarity_review": {
                "reviewer": "test",
                "reviewed_on": "2026-08-05",
                "disposition": "pass",
                "notes": "synthetic",
            },
            "quality_review": {
                "reviewer": "test",
                "reviewed_on": "2026-08-05",
                "disposition": "pass",
                "notes": "synthetic",
            },
            "steam_disclosure_batch": None,
            "promotion_state": "generated_source_quarantined",
            "release_coordinate": "test-only",
        }
        active = copy.deepcopy(self.ledger)
        active["state"] = "active_asset_ledger"
        active["assets"] = [asset]
        module.validate_instance(active, self.schema, self.schema)


if __name__ == "__main__":
    unittest.main(verbosity=2)
