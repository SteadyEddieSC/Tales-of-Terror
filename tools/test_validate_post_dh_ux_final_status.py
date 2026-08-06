#!/usr/bin/env python3
from __future__ import annotations

import copy
import importlib.util
import shutil
import tempfile
from pathlib import Path
from typing import Any

MODULE_PATH = Path('tools/validate_post_dh_ux_final_status.py')
spec = importlib.util.spec_from_file_location('post_source_plan_validator', MODULE_PATH)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)

def get_path(value: Any, path: tuple[Any, ...]) -> Any:
    node = value
    for part in path:
        node = node[part]
    return node

def set_path(value: Any, path: tuple[Any, ...], replacement: Any) -> None:
    node = value
    for part in path[:-1]:
        node = node[part]
    node[path[-1]] = replacement

def mutate_scalar(value: Any) -> Any:
    if isinstance(value, bool):
        return not value
    if isinstance(value, int):
        return value + 1
    if isinstance(value, str):
        return value + '__MUTATED'
    if value is None:
        return 'MUTATED'
    raise TypeError(type(value))

def must_fail(fn, *args) -> None:
    try:
        fn(*args)
    except module.ValidationError:
        return
    raise AssertionError('mutation unexpectedly passed')

status = module.load(module.STATUS)
source_plan = module.load(module.SOURCE_PLAN)
provenance = module.load(module.PROVENANCE)
module.validate(False)
count = 0

status_paths = [
    ('schema_version',), ('status_kind',), ('protected_main',), ('protected_main_semantics',),
    ('as_of_date',), ('playable_release',), ('human_evidence_claimed',),
    ('runtime_implementation_authorized',), ('ux_implementation_authorized',),
    ('visual_implementation_authorized',),
    ('current_release','activation_authorized'), ('current_release','issue'),
    ('current_release','release_id'), ('current_release','runtime_authority_created'),
    ('current_release','state'), ('current_release','type'),
    ('recommended_next_release','activation_authorized'),
    ('recommended_next_release','codex_required'), ('recommended_next_release','github_issue'),
    ('recommended_next_release','release_id'), ('recommended_next_release','state'),
    ('recommended_next_release','title'),
    ('preserved_authorities','dh_source_plan_registration_merge'),
    ('preserved_authorities','quality_security_baseline_merge'),
    ('preserved_authorities','dh_ux_final_addendum_registration_merge'),
    ('preserved_authorities','dh_owner_attestation_registration_merge'),
    ('preserved_authorities','dh_rights_registration_merge'),
    ('preserved_authorities','alpha3_merge'),
    ('quality_security_baseline','merged_main_sha'), ('quality_security_baseline','pull_request'),
    ('quality_security_baseline','release_id'), ('quality_security_baseline','state'),
    ('quality_security_baseline','exact_head_exports'),
    ('quality_security_baseline','full_history_secret_scan'),
    ('quality_security_baseline','sbom_generation'),
    ('quality_security_baseline','workflow_policy_validation'),
    ('production','default_tale_id'), ('production','tale_count'),
    ('production','drowned_harbor_catalog_registered'),
    ('production','drowned_harbor_normal_library_visible'),
    ('production','drowned_harbor_ordinary_export_included'),
    ('production','drowned_harbor_provider_registered'),
    ('production','drowned_harbor_startup_or_fallback_registered'),
    ('drowned_harbor','ordinary_playable'),
    ('visual_planning','external_binaries_in_git'),
    ('visual_planning','production_art_authorized'),
    ('visual_planning','public_github_release_assets_authorized'),
    ('visual_planning','runtime_art_authorized'),
    ('visual_planning','rights_provenance','asset_count'),
    ('visual_planning','rights_provenance','max_rights_tier'),
    ('visual_planning','rights_provenance','reference_only_nonproduction'),
    ('visual_planning','rights_provenance','conversion_readiness'),
    ('visual_planning','rights_provenance','candidate_created'),
    ('visual_planning','rights_provenance','direct_pixel_use_cleared'),
    ('visual_planning','rights_provenance','implementation_authorized'),
    ('visual_planning','rights_provenance','legal_clearance_created'),
    ('visual_planning','rights_provenance','public_distribution_cleared'),
    ('visual_planning','rights_provenance','runtime_art_authorized'),
    ('visual_planning','rights_provenance','source_art_authorized'),
    ('visual_planning','source_plan','release_id'),
    ('visual_planning','source_plan','record_id'),
    ('visual_planning','source_plan','issue'),
    ('visual_planning','source_plan','pull_request'),
    ('visual_planning','source_plan','merged_main_sha'),
    ('visual_planning','source_plan','state'),
    ('visual_planning','source_plan','clean_room_planning_complete'),
    ('visual_planning','source_plan','source_family_count'),
    ('visual_planning','source_plan','control_traceability_count'),
    ('visual_planning','source_plan','mutation_count'),
    ('visual_planning','source_plan','blank_human_authored_sources_required'),
    ('visual_planning','source_plan','no_pixel_reuse_required'),
    ('visual_planning','source_plan','shared_low_high_tide_board_master_required'),
    ('visual_planning','source_plan','similarity_review_required'),
    ('visual_planning','source_plan','source_to_runtime_lineage_required'),
    ('visual_planning','source_plan','candidate_created'),
    ('visual_planning','source_plan','direct_generated_pixel_use_authorized'),
    ('visual_planning','source_plan','editable_source_created'),
    ('visual_planning','source_plan','future_evidence_performed'),
    ('visual_planning','source_plan','godot_authorized'),
    ('visual_planning','source_plan','implementation_authorized'),
    ('visual_planning','source_plan','runtime_composition_authorized'),
    ('visual_planning','source_plan','source_art_creation_authorized'),
    ('visual_planning','source_plan','external_package','admitted_to_repository'),
    ('visual_planning','source_plan','external_package','bytes'),
    ('visual_planning','source_plan','external_package','filename'),
    ('visual_planning','source_plan','external_package','manifest_bytes'),
    ('visual_planning','source_plan','external_package','manifest_sha256'),
    ('visual_planning','source_plan','external_package','manifested_payload_count'),
    ('visual_planning','source_plan','external_package','sha256'),
    ('visual_planning','source_plan','external_package','total_file_count'),
]

for path in status_paths:
    candidate = copy.deepcopy(status)
    set_path(candidate, path, mutate_scalar(get_path(candidate, path)))
    must_fail(module.validate_status, candidate)
    count += 1

for replacement in [[99], [], [32, 99]]:
    candidate = copy.deepcopy(status)
    candidate['closed_unmerged_pull_requests'] = replacement
    must_fail(module.validate_status, candidate)
    count += 1
for replacement in [[32], [99]]:
    candidate = copy.deepcopy(status)
    candidate['unrelated_open_pull_requests'] = replacement
    must_fail(module.validate_status, candidate)
    count += 1

for key in list(status):
    candidate = copy.deepcopy(status)
    del candidate[key]
    must_fail(module.validate_status, candidate)
    count += 1
candidate = copy.deepcopy(status)
candidate['unexpected'] = True
must_fail(module.validate_status, candidate)
count += 1

source_paths = [
    ('record_kind',), ('record_version',),
    ('release','release_id'), ('release','governing_issue'), ('release','protected_main'),
    ('release','package_state'),
    ('authorization','metadata_only_clean_room_planning_authorized'),
    ('authorization','source_art_creation_authorized'),
    ('authorization','runtime_composition_authorized'),
    ('authorization','godot_authorized'),
    ('authorization','ux_implementation_authorized'),
    ('authorization','runtime_implementation_authorized'),
    ('authorization','candidate_authorized'),
    ('authorization','public_distribution_authorized'),
    ('authorization','marketing_or_merchandise_authorized'),
    ('authorization','accessibility_claim_authorized'),
    ('authorization','human_evidence_claim_authorized'),
    ('authorization','conversion_readiness'),
    ('authorization','implementation_authorized'),
    ('external_visual_state','asset_count'),
    ('external_visual_state','maximum_rights_tier'),
    ('external_visual_state','reference_only_nonproduction'),
    ('external_visual_state','source_file_status'),
]
for path in source_paths:
    candidate = copy.deepcopy(source_plan)
    set_path(candidate, path, mutate_scalar(get_path(candidate, path)))
    must_fail(module.validate_source_plan, candidate)
    count += 1

candidate = copy.deepcopy(source_plan)
candidate['asset_taxonomy'].pop(next(iter(candidate['asset_taxonomy'])))
must_fail(module.validate_source_plan, candidate)
count += 1
candidate = copy.deepcopy(source_plan)
candidate['control_traceability'].pop(next(iter(candidate['control_traceability'])))
must_fail(module.validate_source_plan, candidate)
count += 1
candidate = copy.deepcopy(source_plan)
first_evidence = next(iter(candidate['future_evidence']))
candidate['future_evidence'][first_evidence] = 'passed'
must_fail(module.validate_source_plan, candidate)
count += 1
for key in list(source_plan):
    candidate = copy.deepcopy(source_plan)
    del candidate[key]
    must_fail(module.validate_source_plan, candidate)
    count += 1
candidate = copy.deepcopy(source_plan)
candidate['unexpected'] = True
must_fail(module.validate_source_plan, candidate)
count += 1

provenance_paths = [
    ('release_id',), ('issue',), ('phase_b_protected_main',),
    ('external_package','bytes'), ('external_package','sha256'),
    ('external_package','manifest_bytes'), ('external_package','manifest_sha256'),
    ('external_package','admitted_to_repository'),
    ('external_package','public_release_asset_authorized'),
    ('registration','text_only'),
    ('registration','source_creation_authorized'),
    ('registration','runtime_composition_authorized'),
    ('registration','direct_generated_pixel_use_authorized'),
    ('registration','godot_authorized'),
    ('registration','ux_implementation_authorized'),
    ('registration','candidate_authorized'),
    ('registration','public_use_authorized'),
    ('registration','codex_authorized'),
    ('quality_security_baseline','merge_sha'),
    ('quality_security_baseline','pull_request'),
    ('quality_security_baseline','inherited'),
]
for path in provenance_paths:
    candidate = copy.deepcopy(provenance)
    set_path(candidate, path, mutate_scalar(get_path(candidate, path)))
    must_fail(module.validate_provenance, candidate)
    count += 1
for key in list(provenance):
    candidate = copy.deepcopy(provenance)
    del candidate[key]
    must_fail(module.validate_provenance, candidate)
    count += 1
candidate = copy.deepcopy(provenance)
candidate['unexpected'] = True
must_fail(module.validate_provenance, candidate)
count += 1

with tempfile.TemporaryDirectory(prefix='post-source-plan-doc-mutation-') as raw:
    temp_root = Path(raw)
    for path in module.DOCS:
        target = temp_root / path
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, target)
    old_root = module.ROOT
    module.ROOT = temp_root
    try:
        module.validate_docs()
        for path in module.DOCS:
            target = temp_root / path
            original = target.read_text(encoding='utf-8')
            target.write_text(original + '\nsource creation is authorized\n', encoding='utf-8')
            must_fail(module.validate_docs)
            count += 1
            target.write_text(original, encoding='utf-8')
    finally:
        module.ROOT = old_root

print(f'Validated {count} fail-closed post-DH-SOURCE-PLAN status mutations')
