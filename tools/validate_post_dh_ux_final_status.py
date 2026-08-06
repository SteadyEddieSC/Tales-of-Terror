#!/usr/bin/env python3
from __future__ import annotations
import argparse,json,os,subprocess,sys
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
class ValidationError(Exception):pass
def need(v:bool,m:str)->None:
 if not v:raise ValidationError(m)
def load(p:Path)->Any:return json.loads((ROOT/p).read_text(encoding='utf-8'))
def at(v:Any,p:str)->Any:
 for k in p.split('.'):v=v[int(k)] if k.isdigit() else v[k]
 return v
def checks(v:Any,items:list[tuple[str,Any]])->None:
 for p,e in items:need(at(v,p)==e,f'{p} drift')
def validate_status(s:dict[str,Any])->None:
 need(set(s)=={'alpha3','as_of_date','closed_unmerged_pull_requests','companion_dependency_security','current_release','drowned_harbor','gates','human_evidence_claimed','pending_inputs','playable_release','preserved_authorities','production','protected_main','protected_main_semantics','quality_security_baseline','recommended_next_release','rejected_competing_release','runtime_implementation_authorized','schema_version','status_kind','status_reconciliation','unrelated_open_pull_requests','ux_implementation_authorized','visual_implementation_authorized','visual_planning'},'status fields drift')
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
def validate_docs()->None:
 t='\n'.join((ROOT/p).read_text(encoding='utf-8') for p in DOCS).lower()
 req=[BASE,POLICY,REJECTED,'ai-art-policy-001','dh-ai-source-001','issue #151 / pr #152','issue #149 / pr #153','issue #155','draft pr #156','dh-ai-gen-001','selected but not activated','approximately 22 generations','immediate incremental spend `$0`','chatgpt and gemini','ordinary editing','godot','r1_private_internal_reference','reference_only_nonproduction','image-to-image inputs','hidden references','extracted fragments','pr #154 is closed, unmerged, and rejected','none of its policy amendments','lantern house remains the sole normal/default tale','drowned harbor remains developer-only','issue #39','issue #7','automation is not human evidence']
 bad=['no successor release is selected or activated','no successor release is selected','successor unselected','requires blank human-authored editable sources','blank human-authored source requirements','generation is authorized','generation request is authorized','image import is authorized','source acceptance is authorized','runtime composition is authorized','godot implementation is authorized','ux implementation is authorized','ordinary export is authorized','marketing is authorized','storefront is authorized','public release is authorized','candidate approved','production ready','shipping authorized','accessibility certified','human evidence passed','rights are fully cleared','pr #154 is open','pr #154 is merged']
 for x in req:need(x in t,f'missing documentation {x}')
 for x in bad:need(x not in t,f'unsupported documentation {x}')
def branch_name()->str:return os.environ.get('GITHUB_HEAD_REF') or os.environ.get('GITHUB_REF_NAME') or subprocess.check_output(['git','branch','--show-current'],text=True).strip()
def validate_git()->None:
 if branch_name()!=BRANCH:return
 a={x for x in subprocess.check_output(['git','diff','--name-only',f'{BASE}...HEAD'],text=True).splitlines() if x};need(a==ALLOWED,f'path mismatch {sorted(a)}')
 for x in a:need(not x.startswith(('game/','art/source/','game/assets/','audio/','web/companion/','services/room-service/')) and Path(x).suffix.lower() not in {'.png','.jpg','.jpeg','.webp','.zip','.psd','.kra','.blend','.aseprite','.tscn','.tres','.gd','.gdshader','.wav','.ogg','.mp3','.flac'},f'prohibited path {x}')
def validate(check_git:bool=True)->None:
 validate_status(load(STATUS));validate_docs()
 if check_git:validate_git()
def main()->int:
 p=argparse.ArgumentParser();p.add_argument('--skip-git-boundary',action='store_true');a=p.parse_args();validate(not a.skip_git_boundary);print('Validated post-DH-AI-SOURCE-001 current status, rejected PR, and selected-not-activated successor boundary');return 0
if __name__=='__main__':
 try:raise SystemExit(main())
 except (ValidationError,KeyError,TypeError,IndexError,json.JSONDecodeError,subprocess.CalledProcessError,OSError) as e:print(f'ERROR: {e}',file=sys.stderr);raise SystemExit(1)
