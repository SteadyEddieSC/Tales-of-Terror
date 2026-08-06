#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from pathlib import Path
from typing import Any

ROOT = Path('.')
BASE = '3d29b454868295c7d3f4f06708de9c29b462abb2'
BRANCH = 'docs/dh-source-plan-001-clean-room-planning'
MACHINE = Path('docs/tales/drowned_harbor/visual/drowned_harbor_clean_room_source_planning_v1.json')
SCHEMA = Path('docs/tales/drowned_harbor/visual/drowned_harbor_clean_room_source_planning_schema_v1.json')
PROVENANCE = Path('art/licenses/drowned_harbor/visual/dh_source_plan_001_provenance_v1.json')
WORKFLOW = Path('.github/workflows/drowned-harbor-clean-room-source-planning.yml')
DOCS = [
    Path('docs/releases/DH-SOURCE-PLAN-001-clean-room-source-art-and-composition-planning.md'),
    Path('docs/tales/drowned_harbor/visual/Drowned_Harbor_Clean_Room_Source_Art_and_Composition_Plan_v1.md'),
    Path('docs/tales/drowned_harbor/visual/Drowned_Harbor_Source_Asset_Taxonomy_and_Ownership_Matrix_v1.md'),
    Path('docs/tales/drowned_harbor/visual/Drowned_Harbor_Shared_Board_Master_and_State_Composition_Plan_v1.md'),
    Path('docs/tales/drowned_harbor/ux/Drowned_Harbor_Clean_Room_UX_Token_and_Control_Traceability_Plan_v1.md'),
]
ALLOWED = {
    '.github/workflows/drowned-harbor-clean-room-source-planning.yml',
    'docs/releases/DH-SOURCE-PLAN-001-clean-room-source-art-and-composition-planning.md',
    'docs/tales/drowned_harbor/visual/Drowned_Harbor_Clean_Room_Source_Art_and_Composition_Plan_v1.md',
    'docs/tales/drowned_harbor/visual/Drowned_Harbor_Source_Asset_Taxonomy_and_Ownership_Matrix_v1.md',
    'docs/tales/drowned_harbor/visual/Drowned_Harbor_Shared_Board_Master_and_State_Composition_Plan_v1.md',
    'docs/tales/drowned_harbor/ux/Drowned_Harbor_Clean_Room_UX_Token_and_Control_Traceability_Plan_v1.md',
    'docs/tales/drowned_harbor/visual/drowned_harbor_clean_room_source_planning_v1.json',
    'docs/tales/drowned_harbor/visual/drowned_harbor_clean_room_source_planning_schema_v1.json',
    'art/licenses/drowned_harbor/visual/dh_source_plan_001_provenance_v1.json',
    'tools/validate_drowned_harbor_clean_room_source_planning.py',
    'tools/test_validate_drowned_harbor_clean_room_source_planning.py',
}

class ValidationError(Exception):
    pass

def need(value: bool, message: str) -> None:
    if not value:
        raise ValidationError(message)

def load(path: Path) -> Any:
    return json.loads((ROOT / path).read_text(encoding='utf-8'))

def resolve_ref(schema_root: dict[str, Any], ref: str) -> dict[str, Any]:
    need(ref.startswith('#/'), f'unsupported schema reference: {ref}')
    value: Any = schema_root
    for part in ref[2:].split('/'):
        value = value[part.replace('~1', '/').replace('~0', '~')]
    need(isinstance(value, dict), f'schema reference is not an object: {ref}')
    return value

def type_matches(value: Any, expected: str) -> bool:
    return {
        'object': isinstance(value, dict),
        'array': isinstance(value, list),
        'string': isinstance(value, str),
        'integer': isinstance(value, int) and not isinstance(value, bool),
        'number': isinstance(value, (int, float)) and not isinstance(value, bool),
        'boolean': isinstance(value, bool),
        'null': value is None,
    }.get(expected, False)

def validate_instance(value: Any, schema: dict[str, Any], root_schema: dict[str, Any], path: str = '$') -> None:
    if '$ref' in schema:
        validate_instance(value, resolve_ref(root_schema, schema['$ref']), root_schema, path)
        return
    if 'const' in schema:
        need(value == schema['const'], f'{path}: const mismatch')
    if 'enum' in schema:
        need(value in schema['enum'], f'{path}: enum mismatch')
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
                validate_instance(child, properties[key], root_schema, f'{path}.{key}')
    if isinstance(value, list):
        if 'minItems' in schema:
            need(len(value) >= schema['minItems'], f'{path}: too few items')
        if 'maxItems' in schema:
            need(len(value) <= schema['maxItems'], f'{path}: too many items')
        if schema.get('uniqueItems'):
            encoded = [json.dumps(item, sort_keys=True) for item in value]
            need(len(encoded) == len(set(encoded)), f'{path}: duplicate items')
        if 'items' in schema:
            for index, child in enumerate(value):
                validate_instance(child, schema['items'], root_schema, f'{path}[{index}]')
    if isinstance(value, str):
        if 'minLength' in schema:
            need(len(value) >= schema['minLength'], f'{path}: string too short')
        if 'pattern' in schema:
            need(re.search(schema['pattern'], value) is not None, f'{path}: pattern mismatch')

def audit_closed_schema(schema: Any, path: str = '$') -> int:
    count = 0
    if isinstance(schema, dict):
        if schema.get('type') == 'object':
            count += 1
            need(schema.get('additionalProperties') is False, f'{path}: object schema is not closed')
            properties = schema.get('properties')
            required = schema.get('required')
            need(isinstance(properties, dict), f'{path}: properties missing')
            need(isinstance(required, list), f'{path}: required missing')
            need(set(required) == set(properties), f'{path}: required/properties mismatch')
        for key, child in schema.items():
            count += audit_closed_schema(child, f'{path}.{key}')
    elif isinstance(schema, list):
        for index, child in enumerate(schema):
            count += audit_closed_schema(child, f'{path}[{index}]')
    return count

def exact_keys(value: dict[str, Any], expected: set[str], label: str) -> None:
    need(set(value) == expected, f'{label} fields drift: {sorted(set(value) ^ expected)}')

def validate_machine(machine: dict[str, Any], schema: dict[str, Any]) -> None:
    need(schema.get('$schema') == 'https://json-schema.org/draft/2020-12/schema', 'schema draft drift')
    need(audit_closed_schema(schema) >= 10, 'closed schema coverage too small')
    validate_instance(machine, schema, schema)
    release = machine['release']
    need(release['release_id'] == 'DH-SOURCE-PLAN-001' and release['governing_issue'] == 139, 'release identity drift')
    need(release['protected_main'] == BASE, 'Phase B baseline drift')
    auth = machine['authorization']
    need(auth['metadata_only_clean_room_planning_authorized'] is True, 'planning authority missing')
    for key in [
        'source_art_creation_authorized','runtime_composition_authorized','godot_authorized',
        'ux_implementation_authorized','runtime_implementation_authorized','candidate_authorized',
        'public_distribution_authorized','marketing_or_merchandise_authorized',
        'accessibility_claim_authorized','human_evidence_claim_authorized','implementation_authorized',
    ]:
        need(auth[key] is False, f'forbidden authority enabled: {key}')
    need(auth['conversion_readiness'] == 'not_ready', 'conversion readiness promoted')
    visual = machine['external_visual_state']
    need(visual['asset_count'] == 25, 'external asset count drift')
    need(visual['maximum_rights_tier'] == 'R1_private_internal_reference', 'rights tier promoted')
    need(visual['reference_only_nonproduction'] is True, 'reference-only boundary removed')
    need(visual['source_file_status'] == 'none_of_the_25_images_are_source_files', 'source-file boundary drift')
    clean = machine['clean_room_requirements']
    for key in [
        'blank_human_authored_editable_sources_required','independent_geometry_and_composition_required',
        'contributor_records_required','tool_records_required','font_records_required','asset_records_required',
        'license_records_required','source_sha256_required','export_sha256_required',
        'source_to_runtime_lineage_required','similarity_review_before_later_advancement_required',
        'unknown_facts_must_remain_unknown',
    ]:
        need(clean[key] is True, f'required clean-room control disabled: {key}')
    for key in [
        'tracing_allowed','generated_image_vectorization_allowed','paint_over_allowed',
        'generated_image_compositing_allowed','extracted_textures_allowed',
        'direct_generated_pixel_reuse_allowed','generated_text_icons_or_logos_as_source_allowed',
    ]:
        need(clean[key] is False, f'prohibited generated reuse enabled: {key}')
    need(len(machine['asset_taxonomy']) == 10, 'asset taxonomy count drift')
    need(len(machine['control_traceability']) == 20, 'control count drift')
    for control_id, control in machine['control_traceability'].items():
        exact_keys(control, {'owner','legal_intent_source','availability','information_class','interaction_category','source_responsibility','future_consumer'}, control_id)
        need(control['future_consumer'].endswith('_hypothesis_not_implemented'), f'{control_id}: future consumer presented as implemented')
        for field, value in control.items():
            need(isinstance(value, str) and value, f'{control_id}: empty {field}')
    need(len(machine['future_evidence']) == 8, 'future evidence count drift')
    need(all(value.startswith('unperformed_') for value in machine['future_evidence'].values()), 'evidence presented as performed')
    need(len(machine['unresolved_questions']) == 8, 'unresolved question count drift')
    need(set(machine['planned_repository_paths_after_package_acceptance']) == ALLOWED, 'planned path set drift')

def validate_provenance(prov: dict[str, Any]) -> None:
    exact_keys(prov, {'record_kind','record_version','release_id','issue','repository','phase_b_protected_main','external_package','registration','registered_authorities','external_visual_state','quality_security_baseline'}, 'provenance')
    need(prov['release_id'] == 'DH-SOURCE-PLAN-001' and prov['issue'] == 139, 'provenance identity drift')
    need(prov['phase_b_protected_main'] == BASE, 'provenance baseline drift')
    package = prov['external_package']
    exact_keys(package, {'filename','bytes','sha256','manifest_path','manifest_bytes','manifest_sha256','manifested_payload_count','total_file_count','zip_crc_clean','raw_machine_record_sha256','raw_schema_sha256','package_authoring_protected_main','admitted_to_repository','public_release_asset_authorized'}, 'external package')
    need(package['filename'] == 'DH-SOURCE-PLAN-001_Clean_Room_Source_Art_and_Composition_Planning_Package_v2.zip', 'package filename drift')
    need(package['bytes'] == 36122 and package['sha256'] == 'c16988b86f14a6d813d01dfbc3508865716c1e84bf78dfb792ca65f31abd2064', 'package identity drift')
    need(package['manifest_bytes'] == 3304 and package['manifest_sha256'] == '63b4c87e0a5ce9782c53994db49d6709eb864ab58585e5fbbdd5a8b09d6f4ca9', 'manifest identity drift')
    need(package['manifested_payload_count'] == 14 and package['total_file_count'] == 15 and package['zip_crc_clean'] is True, 'package inventory drift')
    need(package['admitted_to_repository'] is False and package['public_release_asset_authorized'] is False, 'external package admitted')
    registration = prov['registration']
    exact_keys(registration, {'branch','planned_paths','text_only','source_creation_authorized','runtime_composition_authorized','direct_generated_pixel_use_authorized','godot_authorized','ux_implementation_authorized','candidate_authorized','public_use_authorized','codex_authorized'}, 'registration')
    need(registration['branch'] == BRANCH and set(registration['planned_paths']) == ALLOWED and registration['text_only'] is True, 'registration boundary drift')
    for key, value in registration.items():
        if key.endswith('_authorized'):
            need(value is False, f'provenance grants forbidden authority: {key}')
    visual = prov['external_visual_state']
    need(visual == {'asset_count':25,'max_rights_tier':'R1_private_internal_reference','reference_only_nonproduction':True,'conversion_readiness':'not_ready','implementation_authorized':False}, 'provenance visual state drift')
    quality = prov['quality_security_baseline']
    need(quality == {'merge_sha':BASE,'pull_request':140,'inherited':True}, 'quality baseline provenance drift')

def validate_docs_and_workflow() -> None:
    text = ' '.join('\n'.join((ROOT / path).read_text(encoding='utf-8') for path in DOCS).lower().split())
    for phrase in [
        'dh-source-plan-001','metadata-only','blank human-authored','independent geometry',
        'low tide','high water','trace generated pixels','vectorize generated images',
        'paint over generated images','composite generated images','source sha-256','export sha-256',
        'similarity review','unknown facts remain unknown','unperformed','issue #39',
        'r1_private_internal_reference','reference_only_nonproduction','conversion readiness `not_ready`',
        'implementation authorization false','lantern house remains the sole normal/default tale',
        'drowned harbor remains developer-only','automation is not human evidence',
    ]:
        need(phrase in text, f'required planning statement missing: {phrase}')
    for phrase in [
        'source creation is authorized','runtime composition is authorized','direct pixel reuse is authorized',
        'godot implementation is authorized','ux implementation is authorized','candidate approved',
        'production ready','shipping authorized','accessibility certified','human evidence passed',
        'legal clearance complete',
    ]:
        need(phrase not in text, f'unsupported claim: {phrase}')
    workflow = (ROOT / WORKFLOW).read_text(encoding='utf-8')
    for token in [
        'actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0',
        'actions/setup-python@ece7cb06caefa5fff74198d8649806c4678c61a1',
        'persist-credentials: false','python-version: 3.11.9','--require-hashes',
        'quality/validate_repository.py all',
    ]:
        need(token in workflow, f'workflow quality requirement missing: {token}')
    need('pull_request_target:' not in workflow, 'dangerous workflow trigger')

def current_branch() -> str:
    return os.environ.get('GITHUB_HEAD_REF') or os.environ.get('GITHUB_REF_NAME') or subprocess.check_output(['git','branch','--show-current'], text=True).strip()

def validate_git_boundary() -> None:
    if current_branch() != BRANCH:
        return
    output = subprocess.check_output(['git','diff','--name-only',f'{BASE}...HEAD'], text=True)
    actual = {line for line in output.splitlines() if line}
    need(actual == ALLOWED, f'path mismatch missing={sorted(ALLOWED-actual)} unexpected={sorted(actual-ALLOWED)}')
    prohibited = {'.png','.jpg','.jpeg','.webp','.zip','.psd','.kra','.blend','.aseprite','.tscn','.tres','.gd','.gdshader','.wav','.ogg','.mp3','.flac'}
    for raw in actual:
        need(Path(raw).suffix.lower() not in prohibited, f'prohibited Phase B path: {raw}')
        need(not raw.startswith(('game/','audio/','art/source/')), f'implementation/source path prohibited: {raw}')

def validate(check_git: bool = True) -> None:
    for path in ALLOWED:
        need((ROOT / path).is_file(), f'missing governed path: {path}')
    machine = load(MACHINE)
    schema = load(SCHEMA)
    provenance = load(PROVENANCE)
    validate_machine(machine, schema)
    validate_provenance(provenance)
    validate_docs_and_workflow()
    if check_git:
        validate_git_boundary()

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--skip-git-boundary', action='store_true')
    args = parser.parse_args()
    validate(not args.skip_git_boundary)
    print('Validated DH-SOURCE-PLAN-001 metadata-only clean-room planning authority')
    return 0

if __name__ == '__main__':
    try:
        raise SystemExit(main())
    except (ValidationError, KeyError, TypeError, IndexError, json.JSONDecodeError, OSError, subprocess.CalledProcessError) as exc:
        print(f'ERROR: {exc}', file=sys.stderr)
        raise SystemExit(1)
