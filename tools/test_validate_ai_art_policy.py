#!/usr/bin/env python3
from __future__ import annotations

import copy
import json
import unittest

import validate_ai_art_policy as subject


class AIArtPolicyTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.policy = subject.load(subject.POLICY)
        cls.providers = subject.load(subject.PROVIDERS)
        cls.schema = subject.load(subject.SCHEMA)
        cls.ledger = subject.load(subject.LEDGER)

    def test_baseline_records_validate(self) -> None:
        subject.validate_policy(copy.deepcopy(self.policy))
        subject.validate_providers(copy.deepcopy(self.providers))
        subject.validate_schema(copy.deepcopy(self.schema))
        subject.validate_ledger(copy.deepcopy(self.ledger))

    def test_exact_25_asset_inventory_is_required(self) -> None:
        ledger = copy.deepcopy(self.ledger)
        ledger["assets"].pop()
        with self.assertRaises(subject.ValidationError):
            subject.validate_ledger(ledger)

    def test_no_asset_is_promoted(self) -> None:
        ledger = copy.deepcopy(self.ledger)
        ledger["common_controls"]["promotion_state"] = "runtime_candidate"
        with self.assertRaises(subject.ValidationError):
            subject.validate_ledger(ledger)

    def test_existing_assets_cannot_become_automatically_approved(self) -> None:
        policy = copy.deepcopy(self.policy)
        policy["decision"]["existing_images_automatically_approved"] = True
        with self.assertRaises(subject.ValidationError):
            subject.validate_policy(policy)

    def test_existing_asset_eligibility_cannot_be_removed(self) -> None:
        policy = copy.deepcopy(self.policy)
        policy["decision"]["existing_drowned_harbor_images_eligible_for_controlled_use_review"] = False
        with self.assertRaises(subject.ValidationError):
            subject.validate_policy(policy)

    def test_unknown_historical_metadata_cannot_become_automatic_rejection(self) -> None:
        policy = copy.deepcopy(self.policy)
        policy["decision"]["unknown_historical_prompt_model_seed_or_timestamp_is_automatic_rejection"] = True
        with self.assertRaises(subject.ValidationError):
            subject.validate_policy(policy)

    def test_pixel_reuse_prohibition_cannot_return(self) -> None:
        policy = copy.deepcopy(self.policy)
        policy["supersession"]["superseded_future_requirements"].remove(
            "tracing_vectorization_paint_over_compositing_cropping_upscaling_recoloring_retouching_extraction_and_model_input_permanently_prohibited"
        )
        with self.assertRaises(subject.ValidationError):
            subject.validate_policy(policy)

    def test_original_hash_cannot_change(self) -> None:
        ledger = copy.deepcopy(self.ledger)
        ledger["assets"][0]["sha256"] = "0" * 64
        ledger["assets"][1]["sha256"] = "0" * 64
        with self.assertRaises(subject.ValidationError):
            subject.validate_ledger(ledger)

    def test_permitted_use_must_be_allowlisted(self) -> None:
        ledger = copy.deepcopy(self.ledger)
        ledger["assets"][0]["permitted_next_uses"].append("ship_without_review")
        with self.assertRaises(subject.ValidationError):
            subject.validate_ledger(ledger)

    def test_full_resolution_review_requirement_cannot_be_overclaimed(self) -> None:
        ledger = copy.deepcopy(self.ledger)
        ledger["review_method"]["full_resolution_binary_review_complete"] = True
        with self.assertRaises(subject.ValidationError):
            subject.validate_ledger(ledger)

    def test_closed_schema_cannot_be_opened(self) -> None:
        schema = copy.deepcopy(self.schema)
        schema["$defs"]["asset"]["additionalProperties"] = True
        with self.assertRaises(subject.ValidationError):
            subject.validate_schema(schema)

    def test_provider_registry_stays_bounded(self) -> None:
        providers = copy.deepcopy(self.providers)
        providers["providers"].append(copy.deepcopy(providers["providers"][0]))
        with self.assertRaises(subject.ValidationError):
            subject.validate_providers(providers)


if __name__ == "__main__":
    unittest.main(verbosity=2)
