#!/usr/bin/env python3
from __future__ import annotations
import argparse,importlib.util,json,os,subprocess,sys
from pathlib import Path
from typing import Any
ROOT=Path('.')
BASE='073e1a65c47f7ec39463fa5a04ed3b4d0e2e73c7'
POLICY='209bba6498686cd392ddce4bbc32f549d381913f'
QUALITY='3d29b454868295c7d3f4f06708de9c29b462abb2'
REJECTED='973d9d94c0b828f6e54990df3c335a4a9f36b5d7'
BRANCH='docs/post-dh-ai-source-status-reconciliation'
STATUS=Path('docs/preproduction/post_prototype_status_v1.json')
DOCS=[Path('README.md'),Path('docs/preproduction/README.md'),Path('docs/roadmap/Post_P0.19_Production_Candidate_Roadmap.md')]
ALLOWED={'README.md','docs/preproduction/README.md','docs/preproduction/post_prototype_status_v1.json','docs/roadmap/Post_P0.19_Production_Candidate_Roadmap.md','tools/validate_post_dh_ux_final_status.py','tools/test_validate_post_dh_ux_final_status.py'}

# Historical records remain immutable; their superseded art requirement is not current policy.
QUALITY_BASELINE = QUALITY
SOURCE_PLAN = Path('docs/tales/drowned_harbor/visual/drowned_harbor_clean_room_source_planning_v1.json')
PROVENANCE = Path('art/licenses/drowned_harbor/visual/dh_source_plan_001_provenance_v1.json')
PRESERVED_AUTHORITIES = {'ai_art_policy_merge': '209bba6498686cd392ddce4bbc32f549d381913f', 'alpha1_merge': '85b77d5216472afdb4abb7598917d5052eed180a', 'alpha2_merge': '4e28ce1d7b471c9be1113986647ccbc3147c0d9d', 'alpha3_candidate_head': '08fdbe8b52a66fc44a98bdd27878554c5478aef1', 'alpha3_merge': 'cad70c5c8f0db1de7d557aff242cc8fe3610361b', 'dh_ai_source_advisory_merge': '073e1a65c47f7ec39463fa5a04ed3b4d0e2e73c7', 'dh_owner_attestation_registration_merge': '7af430b5d9528c648d00291e4c32fa368279b41b', 'dh_present_family_registration_merge': '1cad8495c913d926c4422557ea59e8c6fa1f6c1a', 'dh_present_registration_merge': '671b8f2512be80c0c5f2cec701c29445159620e2', 'dh_rights_registration_merge': 'afa65009237b7b5494bf088c640ff542f93e16b4', 'dh_source_plan_registration_merge': 'a42d1104c16532e801164dc237a5fddc6187b489', 'dh_ux_final_addendum_registration_merge': 'eaa40667322928d39f6cee7c4bff3f74775c2792', 'dh_ux_registration_merge': '22b43893b7726e5c5bea1078aced1cf11e08049f', 'dh_visual_baseline_merge': '0cea1ac62733fda56d09cb0de8a789efc509308a', 'p01_p07_package_index': 'docs/preproduction/preproduction_package_index_v1.json', 'p021_merge': '4efdd76efdf2aa34823dae5d3624a3dca3f0a349', 'p022_merge': 'da86c0aa74bc0442862c97e3c371f6b714da4d0a', 'quality_security_baseline_merge': '3d29b454868295c7d3f4f06708de9c29b462abb2'}
ALPHA3 = {'candidate_head_sha': '08fdbe8b52a66fc44a98bdd27878554c5478aef1', 'developer_only': True, 'issue': 108, 'merged_main_sha': 'cad70c5c8f0db1de7d557aff242cc8fe3610361b', 'ordinary_export_included': False, 'package_version': 3, 'provider_version': 3, 'pull_request': 109, 'release_id': 'v0.2.0-alpha.3', 'scenario_version': 3, 'snapshot_version': 3, 'state': 'completed_developer_only'}
GATES = [{'issue': 7, 'purpose': 'professional naming and branding clearance', 'state': 'open'}, {'issue': 39, 'purpose': 'human household, physical-controller, television, remote, readability, motion, and accessibility evidence', 'state': 'deferred_open'}]
SOURCE_PACKAGE = {'admitted_to_repository': False, 'bytes': 36122, 'filename': 'DH-SOURCE-PLAN-001_Clean_Room_Source_Art_and_Composition_Planning_Package_v2.zip', 'manifest_bytes': 3304, 'manifest_sha256': '63b4c87e0a5ce9782c53994db49d6709eb864ab58585e5fbbdd5a8b09d6f4ca9', 'manifested_payload_count': 14, 'sha256': 'c16988b86f14a6d813d01dfbc3508865716c1e84bf78dfb792ca65f31abd2064', 'total_file_count': 15}
SOURCE_KEYS = {'source_art_creation_authorized', 'future_evidence_performed', 'current_blank_human_authored_source_requirement', 'state', 'godot_authorized', 'editable_source_created', 'merged_main_sha', 'source_family_count', 'clean_room_planning_complete', 'control_traceability_count', 'runtime_composition_authorized', 'release_id', 'mutation_count', 'issue', 'shared_low_high_tide_board_master_required', 'no_pixel_reuse_from_restricted_external_images_required', 'record_id', 'source_to_runtime_lineage_required', 'direct_generated_pixel_use_authorized', 'implementation_authorized', 'pull_request', 'candidate_created', 'blank_human_authored_sources_required_in_historical_record', 'external_package', 'similarity_review_required'}

class ValidationError(Exception):pass
def need(v:bool,m:str)->None:
 if not v:raise ValidationError(m)
def load(p:Path)->Any:return json.loads((ROOT/p).read_text(encoding='utf-8'))
def at(v:Any,p:str)->Any:
 for k in p.split('.'):v=v[int(k)] if k.isdigit() else v[k]
 return v
def checks(v:Any,items:list[tuple[str,Any]])->None:
 for p,e in items:need(at(v,p)==e,f'{p} drift')
def exact_keys(value: dict[str, Any], expected: set[str], label: str) -> None:
    actual = set(value)
    need(actual == expected, f'{label} fields drift: missing={sorted(expected-actual)} unexpected={sorted(actual-expected)}')


def validate_preserved_status(status: dict[str, Any]) -> None:
    need(status['preserved_authorities'] == PRESERVED_AUTHORITIES, 'preserved authority coordinates drift')
    need(status['alpha3'] == ALPHA3, 'Alpha.3 version or developer/export boundary drift')
    need(status['gates'] == GATES, 'human/legal gate shape or evidence drift')
    exact_keys(status['quality_security_baseline'], {
        'codeql_supported_languages', 'exact_head_exports', 'full_history_secret_scan', 'issue',
        'merged_main_sha', 'pull_request', 'release_id', 'sbom_generation', 'state',
        'workflow_policy_validation',
    }, 'quality baseline')
    source = status['visual_planning']['source_plan']
    exact_keys(source, SOURCE_KEYS, 'source plan')
    need(source['external_package'] == SOURCE_PACKAGE, 'registered external package drift')

def validate_status(s:dict[str,Any])->None:
 need(set(s)=={'alpha3','as_of_date','closed_unmerged_pull_requests','companion_dependency_security','current_release','drowned_harbor','gates','human_evidence_claimed','pending_inputs','playable_release','preserved_authorities','production','protected_main','protected_main_semantics','quality_security_baseline','recommended_next_release','rejected_competing_release','runtime_implementation_authorized','schema_version','status_kind','status_reconciliation','unrelated_open_pull_requests','ux_implementation_authorized','visual_implementation_authorized','visual_planning'},'status fields drift')
 validate_preserved_status(s)
 checks(s,[
 ('schema_version',10),('status_kind','post_prototype_project_status'),('protected_main',BASE),('protected_main_semantics','exact_reconciliation_starting_baseline'),('as_of_date','2026-08-06'),('playable_release','v0.1.9'),('pending_inputs',[]),('closed_unmerged_pull_requests',[32,154]),('unrelated_open_pull_requests',[]),('human_evidence_claimed',False),('runtime_implementation_authorized',False),('ux_implementation_authorized',False),('visual_implementation_authorized',False),
 ('current_release',{'activation_authorized':False,'issue':None,'release_id':None,'runtime_authority_created':False,'state':'none_active_after_reconciliation','type':None}),
 ('status_reconciliation',{'branch':BRANCH,'issue':155,'pull_request':156,'release_type':'documentation_and_governance_reconciliation','state':'draft_for_independent_review'}),
 ('recommended_next_release',{'activation_authorized':False,'codex_required':False,'github_issue':None,'immediate_incremental_spend_usd':0,'planned_generation_count':22,'release_id':'DH-AI-GEN-001','state':'selected_not_activated','title':'Drowned Harbor Shared Board-Master Visual Source Pilot'}),
 ('rejected_competing_release',{'accepted':False,'exact_head_sha':REJECTED,'policy_amendments_accepted':False,'pull_request':154,'state':'closed_unmerged_rejected','visual_asset_dispositions_accepted':False}),
 ('preserved_authorities.ai_art_policy_merge',POLICY),('preserved_authorities.dh_ai_source_advisory_merge',BASE),('preserved_authorities.dh_source_plan_registration_merge','a42d1104c16532e801164dc237a5fddc6187b489'),('preserved_authorities.quality_security_baseline_merge',QUALITY),('preserved_authorities.alpha3_merge','cad70c5c8f0db1de7d557aff242cc8fe3610361b'),
 ('quality_security_baseline.merged_main_sha',QUALITY),('quality_security_baseline.pull_request',140),('quality_security_baseline.release_id','automated_quality_security_baseline'),('quality_security_baseline.state','completed_repository_wide_machine_assurance'),('quality_security_baseline.codeql_supported_languages',['javascript-typescript','python']),('quality_security_baseline.exact_head_exports',True),('quality_security_baseline.full_history_secret_scan',True),('quality_security_baseline.sbom_generation',True),('quality_security_baseline.workflow_policy_validation',True),
 ('production.default_tale_id','lantern_house_vertical_slice'),('production.tale_count',1),('drowned_harbor.ordinary_playable',False),
 ('visual_planning.external_binaries_in_git',False),('visual_planning.production_art_authorized',False),('visual_planning.public_github_release_assets_authorized',False),('visual_planning.runtime_art_authorized',False),
 ('visual_planning.ai_art_policy',{'ai_generated_or_assisted_source_may_become_eligible_after_asset_specific_promotion':True,'asset_generation_authorized':False,'human_art_direction_selection_arrangement_and_review_required':True,'human_drawn_or_painted_source_required':False,'issue':151,'ledger_asset_count':0,'ledger_state':'policy_only_no_assets','merged_main_sha':POLICY,'pull_request':152,'release_id':'AI-ART-POLICY-001','state':'completed_policy_only'}),
 ('visual_planning.ai_source_advisory',{'generation_request_authorized':False,'immediate_incremental_spend_usd':0,'issue':149,'merged_main_sha':BASE,'ordinary_editing_role':'exact_geometry_alignment_masking_assembly_and_editable_master','planned_generation_count':22,'primary_generation_tools':['openai_chatgpt_image_generation','google_gemini_apps_image_generation'],'pull_request':153,'record_id':'DH-AI-SOURCE-001','release_id':'DH-AI-SOURCE-001','runtime_procedural_role':'exact_text_routes_focus_preview_warning_recovery_commitment_and_dynamic_state','shared_invariant_low_high_tide_board_master_required':True,'state':'completed_metadata_only_advisory'}),
 ])
 for k in ['drowned_harbor_catalog_registered','drowned_harbor_normal_library_visible','drowned_harbor_ordinary_export_included','drowned_harbor_provider_registered','drowned_harbor_startup_or_fallback_registered']:need(s['production'][k] is False,f'production opening {k}')
 r=s['visual_planning']['rights_provenance'];checks(r,[('asset_count',25),('max_rights_tier','R1_private_internal_reference'),('reference_only_nonproduction',True),('conversion_readiness','not_ready')])
 for k in ['candidate_created','direct_pixel_use_cleared','extracted_fragment_use_allowed','hidden_reference_use_allowed','image_to_image_input_allowed','implementation_authorized','legal_clearance_created','mask_or_control_input_allowed','public_distribution_cleared','runtime_art_authorized','source_art_authorized','texture_use_allowed','upload_to_ai_tool_allowed']:need(r[k] is False,f'external-image authority {k}')
 p=s['visual_planning']['source_plan'];checks(p,[('release_id','DH-SOURCE-PLAN-001'),('record_id','DH-SOURCE-PLAN-001'),('issue',139),('pull_request',146),('merged_main_sha','a42d1104c16532e801164dc237a5fddc6187b489'),('state','completed_historical_metadata_only_planning_superseded_where_conflicting_with_ai_art_policy'),('blank_human_authored_sources_required_in_historical_record',True),('current_blank_human_authored_source_requirement',False),('clean_room_planning_complete',True),('source_family_count',10),('control_traceability_count',20),('mutation_count',529),('no_pixel_reuse_from_restricted_external_images_required',True),('shared_low_high_tide_board_master_required',True),('similarity_review_required',True),('source_to_runtime_lineage_required',True)])
 for k in ['candidate_created','direct_generated_pixel_use_authorized','editable_source_created','future_evidence_performed','godot_authorized','implementation_authorized','runtime_composition_authorized','source_art_creation_authorized']:need(p[k] is False,f'source authority {k}')
 g={x['issue']:x for x in s['gates']};need(set(g)=={7,39} and g[7]['state']=='open' and g[39]['state']=='deferred_open','gate drift')
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

def validate_docs()->None:
 t='\n'.join((ROOT/p).read_text(encoding='utf-8') for p in DOCS).lower()
 req=[BASE,POLICY,REJECTED,'ai-art-policy-001','dh-ai-source-001','issue #151 / pr #152','issue #149 / pr #153','issue #155','draft pr #156','dh-ai-gen-001','selected but not activated','approximately 22 generations','immediate incremental spend `$0`','chatgpt and gemini','ordinary editing','godot','r1_private_internal_reference','reference_only_nonproduction','image-to-image inputs','hidden references','extracted fragments','pr #154 is closed, unmerged, and rejected','none of its policy amendments','lantern house remains the sole normal/default tale','drowned harbor remains developer-only','issue #39','issue #7','automation is not human evidence']
 bad=['no successor release is selected or activated','no successor release is selected','successor unselected','requires blank human-authored editable sources','blank human-authored source requirements','generation is authorized','generation request is authorized','image import is authorized','source acceptance is authorized','runtime composition is authorized','godot implementation is authorized','ux implementation is authorized','ordinary export is authorized','marketing is authorized','storefront is authorized','public release is authorized','candidate approved','production ready','shipping authorized','accessibility certified','human evidence passed','rights are fully cleared','pr #154 is open','pr #154 is merged','source creation is authorized','direct generated-pixel use is authorized','pr #32 is open','pr #32 remains unrelated']
 for x in req:need(x in t,f'missing documentation {x}')
 for x in bad:need(x not in t,f'unsupported documentation {x}')
def branch_name()->str:return os.environ.get('GITHUB_HEAD_REF') or os.environ.get('GITHUB_REF_NAME') or subprocess.check_output(['git','branch','--show-current'],text=True).strip()
def validate_git()->None:
 if branch_name()!=BRANCH:return
 a={x for x in subprocess.check_output(['git','diff','--name-only',f'{BASE}...HEAD'],text=True).splitlines() if x};need(a==ALLOWED,f'path mismatch {sorted(a)}')
 for x in a:need(not x.startswith(('game/','art/source/','game/assets/','audio/','web/companion/','services/room-service/')) and Path(x).suffix.lower() not in {'.png','.jpg','.jpeg','.webp','.zip','.psd','.kra','.blend','.aseprite','.tscn','.tres','.gd','.gdshader','.wav','.ogg','.mp3','.flac'},f'prohibited path {x}')
def validate_runtime_boundaries()->None:
 # Check actual resources, not only status booleans. Reuse the accepted Alpha.3 policy.
 path=Path(__file__).resolve().with_name('validate_drowned_harbor_alpha3_systems.py')
 spec=importlib.util.spec_from_file_location('alpha3_boundary',path)
 need(spec is not None and spec.loader is not None,'Alpha.3 validator unavailable')
 module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
 try:
  module.validate_production_boundaries(load(module.CATALOG_PATH),load(module.LANTERN_PATH),(ROOT/module.REGISTRY_PATH).read_text(encoding='utf-8'),(ROOT/module.PROJECT_PATH).read_text(encoding='utf-8'))
  module.validate_export_policy((ROOT/module.EXPORT_PRESETS_PATH).read_text(encoding='utf-8'),(ROOT/module.PORTABLE_PATH).read_text(encoding='utf-8'))
 except module.Alpha3ValidationError as exc:
  raise ValidationError(f'actual runtime boundary: {exc}') from exc
def validate(check_git:bool=True)->None:
 validate_status(load(STATUS));validate_source_plan(load(SOURCE_PLAN));validate_provenance(load(PROVENANCE));validate_docs();validate_runtime_boundaries()
 if check_git:validate_git()
def main()->int:
 p=argparse.ArgumentParser();p.add_argument('--skip-git-boundary',action='store_true');a=p.parse_args();validate(not a.skip_git_boundary);print('Validated post-DH-AI-SOURCE-001 current status, rejected PR, and selected-not-activated successor boundary');return 0
if __name__=='__main__':
 try:raise SystemExit(main())
 except (ValidationError,KeyError,TypeError,IndexError,json.JSONDecodeError,subprocess.CalledProcessError,OSError) as e:print(f'ERROR: {e}',file=sys.stderr);raise SystemExit(1)
