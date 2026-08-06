#!/usr/bin/env python3
from __future__ import annotations
import copy,importlib.util,re,shutil,tempfile
from pathlib import Path
from typing import Any
P=Path('tools/validate_post_dh_ux_final_status.py');s=importlib.util.spec_from_file_location('v',P);v=importlib.util.module_from_spec(s);assert s.loader;s.loader.exec_module(v)
def get(x:Any,p:tuple[Any,...])->Any:
 for k in p:x=x[k]
 return x
def put(x:Any,p:tuple[Any,...],r:Any)->None:
 for k in p[:-1]:x=x[k]
 x[p[-1]]=r
def mut(x:Any)->Any:
 if isinstance(x,bool):return not x
 if isinstance(x,int):return x+1
 if isinstance(x,str):return x+'__MUTATED'
 if x is None:return 'MUTATED'
 if isinstance(x,list):return x+['MUTATED']
 raise TypeError(type(x))
def fail(fn,*a)->None:
 try:fn(*a)
 except v.ValidationError:return
 raise AssertionError('mutation unexpectedly passed')
st=v.load(v.STATUS);v.validate(False);n=0
paths=[('schema_version',),('status_kind',),('protected_main',),('protected_main_semantics',),('as_of_date',),('playable_release',),('human_evidence_claimed',),('runtime_implementation_authorized',),('ux_implementation_authorized',),('visual_implementation_authorized',),('closed_unmerged_pull_requests',),('unrelated_open_pull_requests',),('pending_inputs',)]
for group,keys in {
'current_release':['activation_authorized','issue','release_id','runtime_authority_created','state','type'],
'status_reconciliation':['branch','issue','pull_request','release_type','state'],
'recommended_next_release':['activation_authorized','codex_required','github_issue','immediate_incremental_spend_usd','planned_generation_count','release_id','state','title'],
'rejected_competing_release':['accepted','exact_head_sha','policy_amendments_accepted','pull_request','state','visual_asset_dispositions_accepted'],
'quality_security_baseline':['merged_main_sha','pull_request','release_id','state','codeql_supported_languages','exact_head_exports','full_history_secret_scan','sbom_generation','workflow_policy_validation'],
'production':['default_tale_id','tale_count','drowned_harbor_catalog_registered','drowned_harbor_normal_library_visible','drowned_harbor_ordinary_export_included','drowned_harbor_provider_registered','drowned_harbor_startup_or_fallback_registered'],
}.items():paths += [(group,k) for k in keys]
paths += [('drowned_harbor','ordinary_playable')]
for k in ['ai_art_policy_merge','dh_ai_source_advisory_merge','dh_source_plan_registration_merge','quality_security_baseline_merge','alpha3_merge']:paths.append(('preserved_authorities',k))
for k in ['external_binaries_in_git','production_art_authorized','public_github_release_assets_authorized','runtime_art_authorized']:paths.append(('visual_planning',k))
for group,keys in {
'ai_art_policy':['ai_generated_or_assisted_source_may_become_eligible_after_asset_specific_promotion','asset_generation_authorized','human_art_direction_selection_arrangement_and_review_required','human_drawn_or_painted_source_required','issue','ledger_asset_count','ledger_state','merged_main_sha','pull_request','release_id','state'],
'ai_source_advisory':['generation_request_authorized','immediate_incremental_spend_usd','issue','merged_main_sha','ordinary_editing_role','planned_generation_count','primary_generation_tools','pull_request','record_id','release_id','runtime_procedural_role','shared_invariant_low_high_tide_board_master_required','state'],
'rights_provenance':['asset_count','max_rights_tier','reference_only_nonproduction','conversion_readiness','candidate_created','direct_pixel_use_cleared','extracted_fragment_use_allowed','hidden_reference_use_allowed','image_to_image_input_allowed','implementation_authorized','legal_clearance_created','mask_or_control_input_allowed','public_distribution_cleared','runtime_art_authorized','source_art_authorized','texture_use_allowed','upload_to_ai_tool_allowed'],
'source_plan':['release_id','record_id','issue','pull_request','merged_main_sha','state','blank_human_authored_sources_required_in_historical_record','current_blank_human_authored_source_requirement','clean_room_planning_complete','source_family_count','control_traceability_count','mutation_count','no_pixel_reuse_from_restricted_external_images_required','shared_low_high_tide_board_master_required','similarity_review_required','source_to_runtime_lineage_required','candidate_created','direct_generated_pixel_use_authorized','editable_source_created','future_evidence_performed','godot_authorized','implementation_authorized','runtime_composition_authorized','source_art_creation_authorized'],
}.items():paths += [('visual_planning',group,k) for k in keys]
for p in paths:
 c=copy.deepcopy(st);put(c,p,mut(get(c,p)));fail(v.validate_status,c);n+=1
for r in [[],[32],[154],[154,32],[32,154,999]]:
 c=copy.deepcopy(st);c['closed_unmerged_pull_requests']=r;fail(v.validate_status,c);n+=1
for r in [[32],[154],[156]]:
 c=copy.deepcopy(st);c['unrelated_open_pull_requests']=r;fail(v.validate_status,c);n+=1
for k in list(st):
 c=copy.deepcopy(st);del c[k];fail(v.validate_status,c);n+=1
c=copy.deepcopy(st);c['unexpected']=True;fail(v.validate_status,c);n+=1
for i,k in [(0,'issue'),(0,'state'),(1,'issue'),(1,'state')]:
 c=copy.deepcopy(st);c['gates'][i][k]=mut(c['gates'][i][k]);fail(v.validate_status,c);n+=1
with tempfile.TemporaryDirectory(prefix='post-ai-source-') as raw:
 r=Path(raw);orig={p:(Path(p).read_text(encoding='utf-8')) for p in v.DOCS}
 for p,t in orig.items():q=r/p;q.parent.mkdir(parents=True,exist_ok=True);q.write_text(t,encoding='utf-8')
 old=v.ROOT;v.ROOT=r
 try:
  v.validate_docs();combined='\n'.join(orig.values())
  req=[v.BASE,v.POLICY,v.REJECTED,'AI-ART-POLICY-001','DH-AI-SOURCE-001','issue #155','draft PR #156','DH-AI-GEN-001','selected but not activated','approximately 22 generations','immediate incremental spend `$0`','ChatGPT and Gemini','ordinary editing','R1_private_internal_reference','reference_only_nonproduction','image-to-image inputs','hidden references','extracted fragments','PR #154 is closed, unmerged, and rejected','Automation is not human evidence']
  for x in req:
   if x in combined:
    for p,t in orig.items():(r/p).write_text(re.sub(re.escape(x),'[REMOVED]',t,flags=re.I),encoding='utf-8')
    fail(v.validate_docs);n+=1
    for p,t in orig.items():(r/p).write_text(t,encoding='utf-8')
  target=r/v.DOCS[0]
  for x in ['no successor release is selected or activated','requires blank human-authored editable sources','generation is authorized','image import is authorized','source acceptance is authorized','runtime composition is authorized','godot implementation is authorized','ux implementation is authorized','ordinary export is authorized','public release is authorized','production ready','shipping authorized','accessibility certified','human evidence passed','rights are fully cleared','PR #154 is merged']:
   target.write_text(orig[v.DOCS[0]]+'\n'+x+'\n',encoding='utf-8');fail(v.validate_docs);n+=1;target.write_text(orig[v.DOCS[0]],encoding='utf-8')
 finally:v.ROOT=old
print(f'Validated {n} fail-closed post-DH-AI-SOURCE status mutations')
