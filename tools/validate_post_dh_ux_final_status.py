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
BASE = 'a42d1104c16532e801164dc237a5fddc6187b489'
QUALITY_BASELINE = '3d29b454868295c7d3f4f06708de9c29b462abb2'
BRANCH = 'docs/post-dh-source-plan-status-reconciliation'
STATUS = Path('docs/preproduction/post_prototype_status_v1.json')
SOURCE_PLAN = Path('docs/tales/drowned_harbor/visual/drowned_harbor_clean_room_source_planning_v1.json')
PROVENANCE = Path('art/licenses/drowned_harbor/visual/dh_source_plan_001_provenance_v1.json')
DOCS = [
    Path('README.md'),
    Path('docs/preproduction/README.md'),
    Path('docs/roadmap/Post_P0.19_Production_Candidate_Roadmap.md'),
]
ALLOWED = {
    'README.md',
    'docs/preproduction/README.md',
    'docs/preproduction/post_prototype_status_v1.json',
    'docs/roadmap/Post_P0.19_Production_Candidate_Roadmap.md',
    'tools/validate_post_dh_ux_final_status.py',
    'tools/test_validate_post_dh_ux_final_status.py',
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

def validate_status(status: dict[str, Any]) -> None:
    exact_keys(status, {
        'alpha3','as_of_date','closed_unmerged_pull_requests','companion_dependency_security',
        'current_release','drowned_harbor','gates','human_evidence_claimed','pending_inputs',
        'playable_release','preserved_authorities','production','protected_main',
        'protected_main_semantics','quality_security_baseline','recommended_next_release',
        'runtime_implementation_authorized','schema_version','status_kind',
        'unrelated_open_pull_requests','ux_implementation_authorized',
        'visual_implementation_authorized','visual_planning',
    }, 'status')
    need(status['schema_version'] == 9, 'schema version drift')
    need(status['status_kind'] == 'post_prototype_project_status', 'status kind drift')
    need(status['protected_main'] == BASE, 'protected-main reconciliation baseline drift')
    need(status['protected_main_semantics'] == 'exact_reconciliation_starting_baseline', 'protected-main semantics drift')
    need(status['as_of_date'] == '2026-08-05', 'status date drift')
    need(status['playable_release'] == 'v0.1.9', 'normal playable release drift')
    need(status['pending_inputs'] == [], 'unexpected pending input')
    need(status['closed_unmerged_pull_requests'] == [32], 'closed/unmerged PR record drift')
    need(status['unrelated_open_pull_requests'] == [], 'unrelated open PR drift')
    need(status['human_evidence_claimed'] is False, 'human evidence claimed')
    need(status['runtime_implementation_authorized'] is False, 'runtime implementation authorized')
    need(status['ux_implementation_authorized'] is False, 'UX implementation authorized')
    need(status['visual_implementation_authorized'] is False, 'visual implementation authorized')

    need(status['current_release'] == {
        'activation_authorized': False,
        'issue': None,
        'release_id': None,
        'runtime_authority_created': False,
        'state': 'none_active_after_reconciliation',
        'type': None,
    }, 'active release drift')
    need(status['recommended_next_release'] == {
        'activation_authorized': False,
        'codex_required': False,
        'github_issue': None,
        'release_id': None,
        'state': 'unselected_post_clean_room_planning_source_creation_requires_explicit_activation',
        'title': None,
    }, 'successor selected or activated')

    preserved = status['preserved_authorities']
    need(preserved['dh_source_plan_registration_merge'] == BASE, 'source-plan merge drift')
    need(preserved['quality_security_baseline_merge'] == QUALITY_BASELINE, 'quality baseline merge drift')
    need(preserved['dh_ux_final_addendum_registration_merge'] == 'eaa40667322928d39f6cee7c4bff3f74775c2792', 'UX addendum merge drift')
    need(preserved['dh_owner_attestation_registration_merge'] == '7af430b5d9528c648d00291e4c32fa368279b41b', 'owner attestation merge drift')
    need(preserved['dh_rights_registration_merge'] == 'afa65009237b7b5494bf088c640ff542f93e16b4', 'rights merge drift')
    need(preserved['alpha3_merge'] == 'cad70c5c8f0db1de7d557aff242cc8fe3610361b', 'Alpha.3 merge drift')

    quality = status['quality_security_baseline']
    exact_keys(quality, {
        'codeql_supported_languages','exact_head_exports','full_history_secret_scan','issue',
        'merged_main_sha','pull_request','release_id','sbom_generation','state',
        'workflow_policy_validation',
    }, 'quality baseline')
    need(quality['merged_main_sha'] == QUALITY_BASELINE and quality['pull_request'] == 140, 'quality baseline coordinates drift')
    need(quality['release_id'] == 'automated_quality_security_baseline', 'quality baseline identity drift')
    need(quality['state'] == 'completed_repository_wide_machine_assurance', 'quality baseline state drift')
    need(quality['codeql_supported_languages'] == ['javascript-typescript', 'python'], 'CodeQL language drift')
    for key in ['exact_head_exports','full_history_secret_scan','sbom_generation','workflow_policy_validation']:
        need(quality[key] is True, f'quality control disabled: {key}')

    production = status['production']
    need(production['default_tale_id'] == 'lantern_house_vertical_slice', 'default Tale drift')
    need(production['tale_count'] == 1, 'production Tale count drift')
    for key in [
        'drowned_harbor_catalog_registered','drowned_harbor_normal_library_visible',
        'drowned_harbor_ordinary_export_included','drowned_harbor_provider_registered',
        'drowned_harbor_startup_or_fallback_registered',
    ]:
        need(production[key] is False, f'Drowned Harbor production opening: {key}')
    need(status['drowned_harbor']['ordinary_playable'] is False, 'Drowned Harbor became ordinarily playable')

    planning = status['visual_planning']
    need(planning['external_binaries_in_git'] is False, 'external visual binary admitted')
    need(planning['production_art_authorized'] is False, 'production art authorized')
    need(planning['public_github_release_assets_authorized'] is False, 'public release asset authorized')
    need(planning['runtime_art_authorized'] is False, 'runtime art authorized')

    rights = planning['rights_provenance']
    need(rights['asset_count'] == 25, 'external asset count drift')
    need(rights['max_rights_tier'] == 'R1_private_internal_reference', 'rights tier promoted')
    need(rights['reference_only_nonproduction'] is True, 'reference-only boundary removed')
    need(rights['conversion_readiness'] == 'not_ready', 'conversion readiness promoted')
    for key in [
        'candidate_created','direct_pixel_use_cleared','implementation_authorized',
        'legal_clearance_created','public_distribution_cleared','runtime_art_authorized',
        'source_art_authorized',
    ]:
        need(rights[key] is False, f'forbidden rights authority enabled: {key}')

    source = planning['source_plan']
    exact_keys(source, {
        'blank_human_authored_sources_required','candidate_created','clean_room_planning_complete',
        'control_traceability_count','direct_generated_pixel_use_authorized','editable_source_created',
        'external_package','future_evidence_performed','godot_authorized','implementation_authorized',
        'issue','merged_main_sha','mutation_count','no_pixel_reuse_required','pull_request',
        'record_id','release_id','runtime_composition_authorized',
        'shared_low_high_tide_board_master_required','similarity_review_required',
        'source_art_creation_authorized','source_family_count','source_to_runtime_lineage_required',
        'state',
    }, 'source plan')
    need(source['release_id'] == 'DH-SOURCE-PLAN-001' and source['record_id'] == 'DH-SOURCE-PLAN-001', 'source-plan identity drift')
    need(source['issue'] == 139 and source['pull_request'] == 146 and source['merged_main_sha'] == BASE, 'source-plan coordinates drift')
    need(source['state'] == 'completed_metadata_only_planning', 'source-plan completion drift')
    need(source['clean_room_planning_complete'] is True, 'clean-room planning not complete')
    need(source['source_family_count'] == 10 and source['control_traceability_count'] == 20, 'source/control count drift')
    need(source['mutation_count'] == 529, 'source-plan mutation evidence drift')
    for key in [
        'blank_human_authored_sources_required','no_pixel_reuse_required',
        'shared_low_high_tide_board_master_required','similarity_review_required',
        'source_to_runtime_lineage_required',
    ]:
        need(source[key] is True, f'source-plan requirement disabled: {key}')
    for key in [
        'candidate_created','direct_generated_pixel_use_authorized','editable_source_created',
        'future_evidence_performed','godot_authorized','implementation_authorized',
        'runtime_composition_authorized','source_art_creation_authorized',
    ]:
        need(source[key] is False, f'forbidden source authority enabled: {key}')
    package = source['external_package']
    need(package == {
        'admitted_to_repository': False,
        'bytes': 36122,
        'filename': 'DH-SOURCE-PLAN-001_Clean_Room_Source_Art_and_Composition_Planning_Package_v2.zip',
        'manifest_bytes': 3304,
        'manifest_sha256': '63b4c87e0a5ce9782c53994db49d6709eb864ab58585e5fbbdd5a8b09d6f4ca9',
        'manifested_payload_count': 14,
        'sha256': 'c16988b86f14a6d813d01dfbc3508865716c1e84bf78dfb792ca65f31abd2064',
        'total_file_count': 15,
    }, 'registered external package drift')

    gates = {entry['issue']: entry for entry in status['gates']}
    need(gates[7]['state'] == 'open', 'issue #7 gate drift')
    need(gates[39]['state'] == 'deferred_open', 'issue #39 gate drift')

def validate_source_plan(machine: dict[str, Any]) -> None:
    exact_keys(machine, {
        'record_kind','record_version','release','governing_authorities','authority_split',
        'authorization','external_visual_state','clean_room_requirements','asset_taxonomy',
        'control_traceability','future_evidence','unresolved_questions','stop_conditions',
        'planned_repository_paths_after_package_acceptance',
    }, 'registered source-plan machine record')
    need(machine['record_kind'] == 'drowned_harbor_clean_room_source_planning' and machine['record_version'] == 1, 'source-plan record identity drift')
    release = machine['release']
    need(release['release_id'] == 'DH-SOURCE-PLAN-001' and release['governing_issue'] == 139, 'source-plan release drift')
    need(release['protected_main'] == QUALITY_BASELINE, 'source-plan Phase B baseline drift')
    need(release['package_state'] == 'accepted_external_package_registered_as_metadata_only_planning', 'source-plan package state drift')
    auth = machine['authorization']
    need(auth['metadata_only_clean_room_planning_authorized'] is True, 'registered planning authority lost')
    need(auth['conversion_readiness'] == 'not_ready', 'registered source-plan conversion promoted')
    for key in [
        'source_art_creation_authorized','runtime_composition_authorized','godot_authorized',
        'ux_implementation_authorized','runtime_implementation_authorized','candidate_authorized',
        'public_distribution_authorized','marketing_or_merchandise_authorized',
        'accessibility_claim_authorized','human_evidence_claim_authorized','implementation_authorized',
    ]:
        need(auth[key] is False, f'registered source-plan forbidden authority: {key}')
    visual = machine['external_visual_state']
    need(visual['asset_count'] == 25 and visual['maximum_rights_tier'] == 'R1_private_internal_reference', 'registered visual state drift')
    need(visual['reference_only_nonproduction'] is True, 'registered reference-only boundary removed')
    need(visual['source_file_status'] == 'none_of_the_25_images_are_source_files', 'external image became source')
    need(len(machine['asset_taxonomy']) == 10, 'registered source-family count drift')
    need(len(machine['control_traceability']) == 20, 'registered control count drift')
    need(all(value.startswith('unperformed_') for value in machine['future_evidence'].values()), 'registered future evidence promoted')

def validate_provenance(prov: dict[str, Any]) -> None:
    exact_keys(prov, {
        'record_kind','record_version','release_id','issue','repository','phase_b_protected_main',
        'external_package','registration','registered_authorities','external_visual_state',
        'quality_security_baseline',
    }, 'source-plan provenance')
    need(prov['release_id'] == 'DH-SOURCE-PLAN-001' and prov['issue'] == 139, 'provenance identity drift')
    need(prov['phase_b_protected_main'] == QUALITY_BASELINE, 'provenance Phase B baseline drift')
    package = prov['external_package']
    need(package['bytes'] == 36122 and package['sha256'] == 'c16988b86f14a6d813d01dfbc3508865716c1e84bf78dfb792ca65f31abd2064', 'provenance package drift')
    need(package['manifest_bytes'] == 3304 and package['manifest_sha256'] == '63b4c87e0a5ce9782c53994db49d6709eb864ab58585e5fbbdd5a8b09d6f4ca9', 'provenance manifest drift')
    need(package['admitted_to_repository'] is False and package['public_release_asset_authorized'] is False, 'external package admitted')
    registration = prov['registration']
    need(registration['text_only'] is True, 'registration text-only boundary removed')
    for key, value in registration.items():
        if key.endswith('_authorized'):
            need(value is False, f'provenance grants forbidden authority: {key}')
    need(prov['quality_security_baseline'] == {'merge_sha': QUALITY_BASELINE, 'pull_request': 140, 'inherited': True}, 'quality baseline provenance drift')

def validate_docs() -> None:
    text = '\n'.join((ROOT / path).read_text(encoding='utf-8') for path in DOCS).lower()
    required = [
        BASE,
        QUALITY_BASELINE,
        'dh-source-plan-001',
        'issue #139 / pr #146',
        'issue #147',
        'clean-room planning is complete',
        'source creation',
        'ten source families',
        'twenty authority-traced',
        'shared low tide/high water board master',
        'no-pixel-reuse',
        'source sha-256',
        'export sha-256',
        'similarity review',
        'r1_private_internal_reference',
        'reference_only_nonproduction',
        'conversion readiness `not_ready`',
        'implementation authorization false',
        'no successor release is selected or activated',
        'pr #32 is closed and unmerged',
        'lantern house remains the sole normal/default tale',
        'drowned harbor remains developer-only',
        'issue #39',
        'issue #7',
        'automation is not human evidence',
    ]
    for phrase in required:
        need(phrase in text, f'missing current documentation: {phrase}')
    forbidden = [
        'source creation is authorized',
        'runtime composition is authorized',
        'direct generated-pixel use is authorized',
        'godot implementation is authorized',
        'ux implementation is authorized',
        'candidate approved',
        'production ready',
        'shipping authorized',
        'accessibility certified',
        'human evidence passed',
        'rights are fully cleared',
        'pr #32 remains unrelated',
        'pr #32 is open',
    ]
    for phrase in forbidden:
        need(phrase not in text, f'stale or unsupported claim: {phrase}')

def branch_name() -> str:
    return os.environ.get('GITHUB_HEAD_REF') or os.environ.get('GITHUB_REF_NAME') or subprocess.check_output(['git','branch','--show-current'], text=True).strip()

def validate_git() -> None:
    if branch_name() != BRANCH:
        return
    output = subprocess.check_output(['git','diff','--name-only',f'{BASE}...HEAD'], text=True)
    actual = {line for line in output.splitlines() if line}
    need(actual == ALLOWED, f'path mismatch missing={sorted(ALLOWED-actual)} unexpected={sorted(actual-ALLOWED)}')
    prohibited_ext = {'.png','.jpg','.jpeg','.webp','.zip','.psd','.kra','.blend','.aseprite','.tscn','.tres','.gd','.gdshader','.wav','.ogg','.mp3','.flac'}
    prohibited_prefix = ('game/','art/source/','game/assets/','audio/','web/companion/','services/room-service/')
    for path in actual:
        need(not path.startswith(prohibited_prefix), f'prohibited path {path}')
        need(Path(path).suffix.lower() not in prohibited_ext, f'prohibited extension {path}')

def validate(check_git: bool = True) -> None:
    validate_status(load(STATUS))
    validate_source_plan(load(SOURCE_PLAN))
    validate_provenance(load(PROVENANCE))
    validate_docs()
    if check_git:
        validate_git()

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--skip-git-boundary', action='store_true')
    args = parser.parse_args()
    validate(not args.skip_git_boundary)
    print('Validated post-DH-SOURCE-PLAN-001 current status and succession boundary')
    return 0

if __name__ == '__main__':
    try:
        raise SystemExit(main())
    except (ValidationError, KeyError, TypeError, IndexError, json.JSONDecodeError, subprocess.CalledProcessError, OSError) as exc:
        print(f'ERROR: {exc}', file=sys.stderr)
        raise SystemExit(1)
