#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path
from typing import Any

ROOT = Path('.')
BASE = '209bba6498686cd392ddce4bbc32f549d381913f'
BRANCH = 'docs/dh-ai-source-001-board-master-advisory'
MACHINE = Path('docs/tales/drowned_harbor/visual/drowned_harbor_ai_source_001_advisory_v1.json')
SCHEMA = Path('docs/tales/drowned_harbor/visual/drowned_harbor_ai_source_001_advisory_schema_v1.json')
PROVENANCE = Path('art/ai/dh_ai_source_001_advisory_provenance_v1.json')
POLICY = Path('art/ai/ai_art_policy_v1.json')
LEDGER = Path('art/ai/ai_art_provenance_ledger_v1.json')
PROVIDERS = Path('art/ai/approved_generators_v1.json')
WORKFLOW = Path('.github/workflows/drowned-harbor-ai-source-advisory.yml')
DOCS = [
    Path('docs/releases/DH-AI-SOURCE-001-ai-first-art-pipeline-and-board-master-advisory.md'),
    Path('docs/tales/drowned_harbor/visual/Drowned_Harbor_AI_First_Art_Pipeline_and_Shared_Board_Master_Pilot_v1.md'),
    Path('docs/tales/drowned_harbor/visual/Drowned_Harbor_AI_Prompt_Tool_and_Budget_Plan_v1.md'),
    Path('docs/tales/drowned_harbor/visual/Drowned_Harbor_AI_Generation_Provenance_and_Review_Plan_v1.md'),
]
ALLOWED = {
    '.github/workflows/drowned-harbor-ai-source-advisory.yml',
    'docs/releases/DH-AI-SOURCE-001-ai-first-art-pipeline-and-board-master-advisory.md',
    'docs/tales/drowned_harbor/visual/Drowned_Harbor_AI_First_Art_Pipeline_and_Shared_Board_Master_Pilot_v1.md',
    'docs/tales/drowned_harbor/visual/Drowned_Harbor_AI_Prompt_Tool_and_Budget_Plan_v1.md',
    'docs/tales/drowned_harbor/visual/Drowned_Harbor_AI_Generation_Provenance_and_Review_Plan_v1.md',
    'docs/tales/drowned_harbor/visual/drowned_harbor_ai_source_001_advisory_v1.json',
    'docs/tales/drowned_harbor/visual/drowned_harbor_ai_source_001_advisory_schema_v1.json',
    'art/ai/dh_ai_source_001_advisory_provenance_v1.json',
    'tools/validate_drowned_harbor_ai_source_advisory.py',
    'tools/test_validate_drowned_harbor_ai_source_advisory.py',
}

class ValidationError(Exception):
    pass

def need(value: bool, message: str) -> None:
    if not value:
        raise ValidationError(message)

def load(path: Path) -> Any:
    return json.loads((ROOT / path).read_text(encoding='utf-8'))

def exact_keys(value: dict[str, Any], expected: set[str], label: str) -> None:
    actual = set(value)
    need(actual == expected, f'{label} fields drift: missing={sorted(expected-actual)} unexpected={sorted(actual-expected)}')

def type_matches(value: Any, expected: str) -> bool:
    if expected == 'object':
        return isinstance(value, dict)
    if expected == 'array':
        return isinstance(value, list)
    if expected == 'string':
        return isinstance(value, str)
    if expected == 'integer':
        return isinstance(value, int) and not isinstance(value, bool)
    if expected == 'boolean':
        return isinstance(value, bool)
    return False

def validate_schema_instance(value: Any, schema: dict[str, Any], path: str = '$') -> None:
    if 'const' in schema:
        need(value == schema['const'], f'{path}: const mismatch')
    if 'type' in schema:
        need(type_matches(value, schema['type']), f"{path}: expected {schema['type']}")
    if isinstance(value, dict):
        properties = schema.get('properties', {})
        required = schema.get('required', [])
        for key in required:
            need(key in value, f'{path}: missing {key}')
        if schema.get('additionalProperties') is False:
            extra = set(value) - set(properties)
            need(not extra, f'{path}: unexpected fields {sorted(extra)}')
        for key, child in value.items():
            if key in properties:
                validate_schema_instance(child, properties[key], f'{path}.{key}')

def audit_closed_schema(value: Any, path: str = '$') -> int:
    count = 0
    if isinstance(value, dict):
        if value.get('type') == 'object':
            count += 1
            need(value.get('additionalProperties') is False, f'{path}: object schema is not closed')
            properties = value.get('properties')
            required = value.get('required')
            need(isinstance(properties, dict), f'{path}: object properties missing')
            need(isinstance(required, list), f'{path}: required list missing')
            need(set(properties) == set(required), f'{path}: required/properties mismatch')
        for key, child in value.items():
            count += audit_closed_schema(child, f'{path}.{key}')
    elif isinstance(value, list):
        for index, child in enumerate(value):
            count += audit_closed_schema(child, f'{path}[{index}]')
    return count

def validate_machine(machine: dict[str, Any], schema: dict[str, Any]) -> None:
    need(schema.get('$schema') == 'https://json-schema.org/draft/2020-12/schema', 'schema draft drift')
    need(audit_closed_schema(schema) >= 10, 'closed schema coverage too small')
    validate_schema_instance(machine, schema)

    release = machine['release']
    need(release['release_id'] == 'DH-AI-SOURCE-001' and release['governing_issue'] == 149, 'release identity drift')
    need(release['registration_protected_main'] == BASE, 'registration baseline drift')
    need(release['state'] == 'advisory_registered_no_generation', 'advisory state drift')
    need(machine['policy_dependency'] == {
        'release_id': 'AI-ART-POLICY-001', 'issue': 151, 'pull_request': 152,
        'merged_main_sha': BASE, 'ledger_state': 'policy_only_no_assets',
    }, 'policy dependency drift')

    package = machine['external_package']
    need(package['bytes'] == 32721 and package['sha256'] == 'dc4e91101c5906e5cef6f3b482d1c83e576849ce94a3dd33d03aa2644cdf530c', 'package identity drift')
    need(package['manifest_bytes'] == 2716 and package['manifest_sha256'] == '0dba5c1b4c3ddcee0303d5a3feb1627f509896a0d3e75f559156db28dcff4853', 'manifest identity drift')
    need(package['manifested_payload_count'] == 15 and package['total_file_count'] == 16, 'package inventory drift')
    need(package['zip_crc_clean'] is True, 'package CRC state drift')
    need(package['admitted_to_repository'] is False and package['public_release_asset_authorized'] is False, 'external package admitted')

    authorization = machine['authorization']
    need(authorization['metadata_only_advisory_authorized'] is True, 'metadata advisory authority missing')
    for key, value in authorization.items():
        if key != 'metadata_only_advisory_authorized':
            need(value is False, f'forbidden authority enabled: {key}')

    boundary = machine['external_visual_boundary']
    need(boundary['asset_count'] == 25 and boundary['maximum_rights_tier'] == 'R1_private_internal_reference', 'external visual identity drift')
    need(boundary['reference_only_nonproduction'] is True and boundary['source_file_status'] == 'none_are_source_files', 'external reference boundary drift')
    for key in ['upload_to_ai_tools_allowed', 'image_to_image_or_control_use_allowed', 'fragment_texture_mask_or_hidden_layer_use_allowed']:
        need(boundary[key] is False, f'restricted external-image use enabled: {key}')

    tools = machine['tool_strategy']
    need(tools['immediate_stack'] == ['openai_chatgpt_image_generation', 'google_gemini_apps_image_generation', 'ordinary_non_ai_editing', 'godot_procedural_rendering'], 'immediate tool stack drift')
    need(tools['recraft_role'] == 'optional_after_documented_vector_gap', 'Recraft gate drift')
    need(tools['firefly_role'] == 'optional_after_documented_editing_or_content_credentials_gap', 'Firefly gate drift')
    need(tools['multiple_overlapping_subscriptions_authorized'] is False, 'overlapping subscriptions authorized')

    privacy = machine['privacy_controls']
    need(privacy['chatgpt'] == 'temporary_chat_or_improve_model_for_everyone_disabled', 'ChatGPT privacy control drift')
    need(privacy['gemini'] == 'temporary_chat_or_keep_activity_disabled_and_no_proprietary_feedback', 'Gemini privacy control drift')
    need(privacy['recraft_api'] == 'non_sensitive_prompt_only_due_temporary_signed_url_exposure', 'Recraft API privacy control drift')
    need(privacy['restricted_or_unlicensed_uploads_allowed'] is False, 'restricted uploads enabled')
    need(privacy['account_plan_and_privacy_mode_record_required'] is True, 'account/privacy record requirement removed')

    budget = machine['budget']
    need(budget['immediate_incremental_spend_usd'] == 0 and budget['initial_full_pilot_generation_count'] == 22, 'pilot budget/count drift')
    need(budget['recraft_api_optional_test_usd'] == 1 and budget['recraft_api_test_authorized_by_this_release'] is False, 'Recraft test gate drift')
    need(budget['artist_or_contractor_authorized'] is False, 'artist/contractor authorized')

    board = machine['board_master']
    need(board['bounded_target'] == 'one_shared_low_tide_high_water_board_master_pilot', 'pilot target drift')
    need(board['invariant_geometry_required'] is True and board['independent_low_and_high_tide_boards_allowed'] is False, 'shared master rule drift')
    need(board['planning_canvas_selected'] is False, 'planning hypothesis presented as selected')
    need(board['layer_group_count'] == 13 and len(board['layer_groups']) == 13, 'layer-group count drift')
    need(board['exact_text_labels_routes_and_state_baked_into_ai_images'] is False, 'exact state baked into AI images')
    need(board['runtime_and_procedural_information_required'] is True, 'runtime information authority removed')

    need(len(machine['prompt_families']) == 6, 'prompt-family count drift')
    need(len(machine['generation_sequence']) == 8, 'generation-sequence count drift')
    need(len(machine['immediate_generation_candidates']) == 6, 'candidate count drift')
    need(all(value is True for value in machine['provenance_extensions'].values()), 'provenance requirement disabled')
    need(len(machine['unresolved']) == 7, 'unresolved dependency count drift')
    need(set(machine['planned_repository_paths']) == ALLOWED, 'planned path set drift')

def validate_policy_dependency() -> None:
    policy = load(POLICY)
    need(policy['release']['release_id'] == 'AI-ART-POLICY-001', 'AI-art policy identity drift')
    need(policy['release']['protected_main'] == '0a6686d8cc4d15feac81c128cfc414b954e234b1', 'AI-art policy historical baseline drift')
    need(policy['release']['state'] == 'policy_only_no_assets', 'AI-art policy state drift')
    decision = policy['decision']
    need(decision['ai_generated_pixels_may_become_eligible_after_separate_asset_promotion'] is True, 'AI-generated source eligibility missing')
    for key in ['generation_authorized_by_this_release', 'import_authorized_by_this_release', 'runtime_integration_authorized_by_this_release', 'ordinary_export_authorized_by_this_release', 'marketing_authorized_by_this_release', 'storefront_publication_authorized_by_this_release', 'live_generation_authorized']:
        need(decision[key] is False, f'policy dependency grants forbidden authority: {key}')
    need(load(LEDGER) == {
        'record_kind': 'terror_turn_ai_art_provenance_ledger', 'record_version': 1,
        'policy_release': 'AI-ART-POLICY-001', 'state': 'policy_only_no_assets', 'assets': [],
    }, 'AI-art ledger is not empty policy-only state')
    provider_ids = {entry['provider_id'] for entry in load(PROVIDERS)['providers']}
    need(provider_ids == {'openai_chatgpt_image_generation', 'google_gemini_apps_image_generation'}, 'approved-provider registry drift')

def validate_provenance(provenance: dict[str, Any]) -> None:
    exact_keys(provenance, {'record_kind', 'record_version', 'release_id', 'issue', 'repository', 'registration_protected_main', 'policy_dependency', 'external_package', 'registration', 'release_coordinator_supplements', 'external_visual_state', 'planned_paths'}, 'advisory provenance')
    need(provenance['record_kind'] == 'dh_ai_source_001_advisory_provenance' and provenance['record_version'] == 1, 'provenance record identity drift')
    need(provenance['release_id'] == 'DH-AI-SOURCE-001' and provenance['issue'] == 149, 'provenance release identity drift')
    need(provenance['repository'] == 'SteadyEddieSC/Tales-of-Terror', 'provenance repository drift')
    need(provenance['registration_protected_main'] == BASE, 'provenance baseline drift')
    need(provenance['policy_dependency'] == {'release_id': 'AI-ART-POLICY-001', 'issue': 151, 'pull_request': 152, 'merged_main_sha': BASE}, 'provenance policy dependency drift')

    package = provenance['external_package']
    exact_keys(package, {
        'filename', 'bytes', 'sha256', 'manifest_path', 'manifest_bytes', 'manifest_sha256',
        'manifested_payload_count', 'total_file_count', 'raw_advisory_record_sha256',
        'raw_advisory_schema_sha256', 'package_authoring_protected_main', 'zip_crc_clean',
        'utf8_text_only_audit_passed', 'draft_2020_12_validation_passed',
        'closed_object_schema_node_count', 'all_manifest_hashes_and_bytes_match',
        'admitted_to_repository', 'public_release_asset_authorized',
    }, 'external advisory package provenance')
    need(package['filename'] == 'DH-AI-SOURCE-001_External_UX_Helper_AI_First_Art_Pipeline_Advisory_v1.zip', 'provenance package filename drift')
    need(package['bytes'] == 32721 and package['sha256'] == 'dc4e91101c5906e5cef6f3b482d1c83e576849ce94a3dd33d03aa2644cdf530c', 'provenance package drift')
    need(package['manifest_path'] == '12_MACHINE_READABLE/PACKAGE_MANIFEST.json', 'provenance manifest path drift')
    need(package['manifest_bytes'] == 2716 and package['manifest_sha256'] == '0dba5c1b4c3ddcee0303d5a3feb1627f509896a0d3e75f559156db28dcff4853', 'provenance manifest drift')
    need(package['manifested_payload_count'] == 15 and package['total_file_count'] == 16, 'provenance package inventory drift')
    need(package['raw_advisory_record_sha256'] == '8e691c948e5d513f9eb0c8aaceaab31ae19567acb2b7dbf9ed99fca397c2ecc6', 'raw advisory record hash drift')
    need(package['raw_advisory_schema_sha256'] == 'fc360d67478ce18b7553b21bb7998077b4e7d46bd58062b1b4f9adf491a9c1f5', 'raw advisory schema hash drift')
    need(package['package_authoring_protected_main'] == 'f361fbfc9df9384f7c1eefb447a911a31fdc3fee', 'package authoring baseline drift')
    for key in ['zip_crc_clean', 'utf8_text_only_audit_passed', 'draft_2020_12_validation_passed', 'all_manifest_hashes_and_bytes_match']:
        need(package[key] is True, f'package audit flag disabled: {key}')
    need(package['closed_object_schema_node_count'] == 6, 'raw package closed-schema count drift')
    need(package['admitted_to_repository'] is False and package['public_release_asset_authorized'] is False, 'package admission drift')

    registration = provenance['registration']
    exact_keys(registration, {
        'branch', 'path_count', 'text_only', 'package_specific_advisory_registered',
        'generation_request_authorized', 'image_asset_created_or_imported',
        'source_acceptance_authorized', 'runtime_or_godot_implementation_authorized',
        'paid_tool_purchase_authorized', 'public_or_storefront_use_authorized',
        'codex_authorized',
    }, 'advisory registration provenance')
    need(registration['branch'] == BRANCH, 'registration branch drift')
    need(registration['path_count'] == 10 and registration['text_only'] is True and registration['package_specific_advisory_registered'] is True, 'registration boundary drift')
    for key in [
        'generation_request_authorized', 'image_asset_created_or_imported',
        'source_acceptance_authorized', 'runtime_or_godot_implementation_authorized',
        'paid_tool_purchase_authorized', 'public_or_storefront_use_authorized',
        'codex_authorized',
    ]:
        need(registration[key] is False, f'provenance registration grants authority: {key}')

    supplements = provenance['release_coordinator_supplements']
    exact_keys(supplements, {
        'immediate_incremental_spend_usd', 'chatgpt_privacy_control',
        'gemini_privacy_control', 'recraft_free_outputs_eligible',
        'recraft_api_optional_non_sensitive_test_usd',
        'recraft_api_test_authorized_by_registration',
        'private_recraft_month_requires_documented_gap',
        'firefly_is_fallback_not_current_purchase',
        'restricted_external_images_may_be_uploaded',
    }, 'release coordinator supplements')
    need(supplements['immediate_incremental_spend_usd'] == 0, 'supplement immediate spend drift')
    need(supplements['chatgpt_privacy_control'] == 'temporary_chat_or_improve_model_for_everyone_disabled', 'supplement ChatGPT privacy drift')
    need(supplements['gemini_privacy_control'] == 'temporary_chat_or_keep_activity_disabled_and_no_proprietary_feedback', 'supplement Gemini privacy drift')
    need(supplements['recraft_free_outputs_eligible'] is False, 'Recraft Free made eligible')
    need(supplements['recraft_api_optional_non_sensitive_test_usd'] == 1, 'supplement Recraft amount drift')
    need(supplements['recraft_api_test_authorized_by_registration'] is False, 'supplement Recraft test activated')
    need(supplements['private_recraft_month_requires_documented_gap'] is True, 'private Recraft gap requirement removed')
    need(supplements['firefly_is_fallback_not_current_purchase'] is True, 'Firefly fallback gate removed')
    need(supplements['restricted_external_images_may_be_uploaded'] is False, 'restricted uploads allowed')

    need(provenance['external_visual_state'] == {
        'asset_count': 25, 'maximum_rights_tier': 'R1_private_internal_reference',
        'reference_only_nonproduction': True, 'none_are_source_files': True,
        'implementation_authorized': False,
    }, 'provenance external visual state drift')
    need(set(provenance['planned_paths']) == ALLOWED, 'provenance path set drift')

def validate_docs_and_workflow() -> None:
    text = '\n'.join((ROOT / path).read_text(encoding='utf-8') for path in DOCS).lower()
    required = [
        'dh-ai-source-001', 'ai-art-policy-001', 'shared low tide / high water board master',
        'one shared board master', 'thirteen', 'six prompt families', 'eight batches',
        'twenty-two', 'temporary chat', 'improve the model for everyone', 'keep activity',
        '$0', '$1', 'recraft free', 'ordinary non-ai editing', 'godot procedural',
        'r1_private_internal_reference', 'reference_only_nonproduction',
        'source sha-256', 'export sha-256', 'similarity review', 'steam',
        'lantern house remains the sole normal/default tale', 'drowned harbor remains developer-only',
        'issue #39', 'automation is not human evidence',
    ]
    for phrase in required:
        need(phrase in text, f'required advisory statement missing: {phrase}')
    for phrase in [
        'generation is authorized', 'image generation is authorized', 'source art has been created',
        'implementation is authorized', 'public release is approved', 'steam approval',
        'copyright is guaranteed', 'legal clearance is complete', 'accessibility is validated',
        'production ready', 'shipping ready', 'the 25 images may be uploaded',
    ]:
        need(phrase not in text, f'unsupported advisory claim: {phrase}')
    workflow = (ROOT / WORKFLOW).read_text(encoding='utf-8')
    for token in [
        'actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0',
        'actions/setup-python@ece7cb06caefa5fff74198d8649806c4678c61a1',
        'persist-credentials: false', 'python-version: 3.11.9', '--require-hashes',
        'quality/validate_repository.py all',
    ]:
        need(token in workflow, f'workflow policy token missing: {token}')
    need('pull_request_target:' not in workflow, 'dangerous workflow trigger')

def branch_name() -> str:
    return os.environ.get('GITHUB_HEAD_REF') or os.environ.get('GITHUB_REF_NAME') or subprocess.check_output(['git', 'branch', '--show-current'], text=True).strip()

def validate_git_boundary() -> None:
    if branch_name() != BRANCH:
        return
    output = subprocess.check_output(['git', 'diff', '--name-only', f'{BASE}...HEAD'], text=True)
    actual = {line for line in output.splitlines() if line}
    need(actual == ALLOWED, f'path mismatch missing={sorted(ALLOWED-actual)} unexpected={sorted(actual-ALLOWED)}')
    prohibited_extensions = {'.png', '.jpg', '.jpeg', '.webp', '.zip', '.psd', '.kra', '.blend', '.aseprite', '.tscn', '.tres', '.gd', '.gdshader', '.wav', '.ogg', '.mp3', '.flac', '.svg'}
    for path in actual:
        need(Path(path).suffix.lower() not in prohibited_extensions, f'prohibited advisory path: {path}')
        need(not path.startswith(('game/', 'audio/', 'art/source/', 'game/assets/')), f'implementation or source path prohibited: {path}')

def validate(check_git: bool = True) -> None:
    for path in ALLOWED:
        need((ROOT / path).is_file(), f'missing governed path: {path}')
    validate_machine(load(MACHINE), load(SCHEMA))
    validate_policy_dependency()
    validate_provenance(load(PROVENANCE))
    validate_docs_and_workflow()
    if check_git:
        validate_git_boundary()

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--skip-git-boundary', action='store_true')
    args = parser.parse_args()
    validate(not args.skip_git_boundary)
    print('Validated DH-AI-SOURCE-001 metadata-only AI-first board-master advisory')
    return 0

if __name__ == '__main__':
    try:
        raise SystemExit(main())
    except (ValidationError, KeyError, TypeError, IndexError, json.JSONDecodeError, OSError, subprocess.CalledProcessError) as exc:
        print(f'ERROR: {exc}', file=sys.stderr)
        raise SystemExit(1)
