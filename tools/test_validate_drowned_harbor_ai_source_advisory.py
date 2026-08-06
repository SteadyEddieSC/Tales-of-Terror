#!/usr/bin/env python3
from __future__ import annotations

import copy
import importlib.util
import json
import shutil
import tempfile
from pathlib import Path
from typing import Any, Iterator

HERE = Path(__file__).resolve()
VALIDATOR_PATH = HERE.with_name('validate_drowned_harbor_ai_source_advisory.py')
spec = importlib.util.spec_from_file_location('dh_ai_source_advisory_validator', VALIDATOR_PATH)
if spec is None or spec.loader is None:
    raise SystemExit('Unable to load validator')
validator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(validator)

def object_paths(value: Any, path: tuple[Any, ...] = ()) -> Iterator[tuple[Any, ...]]:
    if isinstance(value, dict):
        yield path
        for key, child in value.items():
            yield from object_paths(child, path + (key,))
    elif isinstance(value, list):
        for index, child in enumerate(value):
            yield from object_paths(child, path + (index,))

def get_path(value: Any, path: tuple[Any, ...]) -> Any:
    node = value
    for part in path:
        node = node[part]
    return node

def write_json(path: Path, value: Any) -> None:
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')

def expect_failure(root: Path) -> None:
    old_root = validator.ROOT
    validator.ROOT = root
    try:
        try:
            validator.validate(check_git=False)
        except Exception:
            return
        raise AssertionError('mutation unexpectedly passed')
    finally:
        validator.ROOT = old_root

def main() -> int:
    repo_root = HERE.parents[1]
    required = set(validator.ALLOWED) | {str(validator.POLICY), str(validator.LEDGER), str(validator.PROVIDERS)}
    with tempfile.TemporaryDirectory(prefix='dh-ai-source-advisory-mutations-') as raw:
        root = Path(raw)
        for relative in required:
            source = repo_root / relative
            target = root / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, target)

        old_root = validator.ROOT
        validator.ROOT = root
        try:
            validator.validate(check_git=False)
        finally:
            validator.ROOT = old_root

        count = 0
        machine_path = root / validator.MACHINE
        machine = json.loads(machine_path.read_text(encoding='utf-8'))

        for path in list(object_paths(machine)):
            target = get_path(machine, path)
            for key in list(target):
                mutated = copy.deepcopy(machine)
                del get_path(mutated, path)[key]
                write_json(machine_path, mutated)
                expect_failure(root)
                count += 1
            mutated = copy.deepcopy(machine)
            get_path(mutated, path)['unexpected_field'] = True
            write_json(machine_path, mutated)
            expect_failure(root)
            count += 1
        write_json(machine_path, machine)

        targeted_machine_mutations = [
            ('authorization', 'generation_request_authorized', True),
            ('authorization', 'image_creation_or_import_authorized', True),
            ('authorization', 'source_acceptance_authorized', True),
            ('authorization', 'runtime_composition_authorized', True),
            ('authorization', 'paid_tool_purchase_authorized', True),
            ('authorization', 'public_release_authorized', True),
            ('external_visual_boundary', 'upload_to_ai_tools_allowed', True),
            ('external_visual_boundary', 'image_to_image_or_control_use_allowed', True),
            ('external_visual_boundary', 'maximum_rights_tier', 'R2_internal_candidate'),
            ('privacy_controls', 'restricted_or_unlicensed_uploads_allowed', True),
            ('privacy_controls', 'account_plan_and_privacy_mode_record_required', False),
            ('budget', 'immediate_incremental_spend_usd', 12),
            ('budget', 'recraft_api_test_authorized_by_this_release', True),
            ('budget', 'artist_or_contractor_authorized', True),
            ('board_master', 'invariant_geometry_required', False),
            ('board_master', 'independent_low_and_high_tide_boards_allowed', True),
            ('board_master', 'planning_canvas_selected', True),
            ('board_master', 'exact_text_labels_routes_and_state_baked_into_ai_images', True),
            ('board_master', 'runtime_and_procedural_information_required', False),
            ('external_package', 'admitted_to_repository', True),
            ('external_package', 'public_release_asset_authorized', True),
        ]
        for section, key, replacement in targeted_machine_mutations:
            mutated = copy.deepcopy(machine)
            mutated[section][key] = replacement
            write_json(machine_path, mutated)
            expect_failure(root)
            count += 1
        write_json(machine_path, machine)

        schema_path = root / validator.SCHEMA
        schema = json.loads(schema_path.read_text(encoding='utf-8'))
        mutated_schema = copy.deepcopy(schema)
        mutated_schema['additionalProperties'] = True
        write_json(schema_path, mutated_schema)
        expect_failure(root)
        count += 1
        write_json(schema_path, schema)

        provenance_path = root / validator.PROVENANCE
        provenance = json.loads(provenance_path.read_text(encoding='utf-8'))
        for path in list(object_paths(provenance)):
            target = get_path(provenance, path)
            for key in list(target):
                mutated = copy.deepcopy(provenance)
                del get_path(mutated, path)[key]
                write_json(provenance_path, mutated)
                expect_failure(root)
                count += 1
            mutated = copy.deepcopy(provenance)
            get_path(mutated, path)['unexpected_field'] = True
            write_json(provenance_path, mutated)
            expect_failure(root)
            count += 1
        write_json(provenance_path, provenance)

        targeted_provenance_mutations = [
            ('registration', 'generation_request_authorized', True),
            ('registration', 'image_asset_created_or_imported', True),
            ('registration', 'paid_tool_purchase_authorized', True),
            ('release_coordinator_supplements', 'immediate_incremental_spend_usd', 12),
            ('release_coordinator_supplements', 'recraft_free_outputs_eligible', True),
            ('release_coordinator_supplements', 'recraft_api_test_authorized_by_registration', True),
            ('release_coordinator_supplements', 'restricted_external_images_may_be_uploaded', True),
            ('external_visual_state', 'maximum_rights_tier', 'R2_internal_candidate'),
            ('external_visual_state', 'none_are_source_files', False),
            ('external_visual_state', 'implementation_authorized', True),
        ]
        for section, key, replacement in targeted_provenance_mutations:
            mutated = copy.deepcopy(provenance)
            mutated[section][key] = replacement
            write_json(provenance_path, mutated)
            expect_failure(root)
            count += 1
        write_json(provenance_path, provenance)

        policy_path = root / validator.POLICY
        policy = json.loads(policy_path.read_text(encoding='utf-8'))
        mutated = copy.deepcopy(policy)
        mutated['decision']['generation_authorized_by_this_release'] = True
        write_json(policy_path, mutated)
        expect_failure(root)
        count += 1
        write_json(policy_path, policy)

        ledger_path = root / validator.LEDGER
        ledger = json.loads(ledger_path.read_text(encoding='utf-8'))
        mutated = copy.deepcopy(ledger)
        mutated['state'] = 'active_asset_ledger'
        write_json(ledger_path, mutated)
        expect_failure(root)
        count += 1
        write_json(ledger_path, ledger)

        providers_path = root / validator.PROVIDERS
        providers = json.loads(providers_path.read_text(encoding='utf-8'))
        mutated = copy.deepcopy(providers)
        mutated['providers'].append({'provider_id': 'unreviewed_generator'})
        write_json(providers_path, mutated)
        expect_failure(root)
        count += 1
        write_json(providers_path, providers)

        workflow_path = root / validator.WORKFLOW
        workflow = workflow_path.read_text(encoding='utf-8')
        workflow_path.write_text(workflow.replace('persist-credentials: false', 'persist-credentials: true'), encoding='utf-8')
        expect_failure(root)
        count += 1
        workflow_path.write_text(workflow, encoding='utf-8')

        for relative in validator.DOCS:
            path = root / relative
            original = path.read_text(encoding='utf-8')
            path.write_text(original + '\ngeneration is authorized\n', encoding='utf-8')
            expect_failure(root)
            count += 1
            path.write_text(original, encoding='utf-8')

        print(f'Validated {count} fail-closed DH-AI-SOURCE-001 advisory mutations')
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
