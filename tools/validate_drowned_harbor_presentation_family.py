#!/usr/bin/env python3
from __future__ import annotations
import argparse, json, os, subprocess, sys
from pathlib import Path
from typing import Any

BASE='42e2fed1737fa17bad5d2bafb6dee6aedad87319'
BRANCH='docs/dh-present-002-003-family-registration'
ALLOWED={
'.github/workflows/drowned-harbor-presentation-family.yml',
'docs/releases/DH-PRESENT-002-003-presentation-family-registration.md',
'docs/tales/drowned_harbor/visual/Drowned_Harbor_Last_Light_Presentation_Hook_Storyboard_Study_v1.md',
'docs/tales/drowned_harbor/visual/Drowned_Harbor_Ending_Resolution_and_Epilogue_Attribution_Presentation_Hook_Storyboard_Study_v1.md',
'docs/tales/drowned_harbor/visual/Drowned_Harbor_Presentation_Family_Consistency_and_Conversion_Readiness_v1.md',
'docs/tales/drowned_harbor/visual/drowned_harbor_presentation_family_registration_v1.json',
'docs/tales/drowned_harbor/visual/drowned_harbor_presentation_family_registration_schema_v1.json',
'art/licenses/drowned_harbor/visual/dh_present_002_003_provenance_v1.json',
'tools/validate_drowned_harbor_presentation_family.py',
'tools/test_validate_drowned_harbor_presentation_family.py'}
CONTRACT=Path('docs/tales/drowned_harbor/visual/drowned_harbor_presentation_family_registration_v1.json')
SCHEMA=Path('docs/tales/drowned_harbor/visual/drowned_harbor_presentation_family_registration_schema_v1.json')
PROVENANCE=Path('art/licenses/drowned_harbor/visual/dh_present_002_003_provenance_v1.json')
DOCS=[Path('docs/releases/DH-PRESENT-002-003-presentation-family-registration.md'),Path('docs/tales/drowned_harbor/visual/Drowned_Harbor_Last_Light_Presentation_Hook_Storyboard_Study_v1.md'),Path('docs/tales/drowned_harbor/visual/Drowned_Harbor_Ending_Resolution_and_Epilogue_Attribution_Presentation_Hook_Storyboard_Study_v1.md'),Path('docs/tales/drowned_harbor/visual/Drowned_Harbor_Presentation_Family_Consistency_and_Conversion_Readiness_v1.md')]
class ValidationError(ValueError): pass
def require(c:bool,m:str):
    if not c: raise ValidationError(m)
def load(p:Path)->dict[str,Any]:
    x=json.loads(p.read_text(encoding='utf-8')); require(isinstance(x,dict),f'object required: {p}'); return x

def validate_contract(d):
    require(d['record_kind']=='drowned_harbor_presentation_family_registration' and d['record_version']==1,'contract identity drift')
    i=d['identity']; require(i['release_id']=='DH-PRESENT-REG-002' and i['family_id']=='DH-PRESENT-FAMILY-001' and i['governing_issue']==118 and i['study_ids']==['DH-PRESENT-002','DH-PRESENT-003'],'identity drift')
    require(i['registered_predecessor']=={'release_id':'DH-PRESENT-REG-001','study_id':'DH-PRESENT-001','issue':114,'pr':115,'merge_sha':'671b8f2512be80c0c5f2cec701c29445159620e2'},'predecessor drift')
    require(d['release']=={'protected_main_base':BASE,'branch':BRANCH,'planning_only':True,'metadata_only':True,'combined_registration':True,'separate_releases_required':False},'release coordinates drift')
    require(all(v is False for v in d['authorization'].values()),'authorization boundary opened')
    p=d['external_package']; require(p['filename']=='DH-PRESENT-002-003_External_Art_Director_Planning_Package_v1.zip' and p['bytes']==5313560 and p['sha256']=='5f9c5c9a965bb58b99e8771d8e2448f1bf7c1a3e4f0c1b300b52812208aeee4b' and p['integrity_verified'] is True and p['repository_disposition']=='external_private_only','package evidence drift')
    require(p['manifest']=={'path':'02_MACHINE_READABLE/PACKAGE_MANIFEST.json','bytes':1972,'sha256':'640110e50a85a6dc9a146b2cd9212c77a351f964f4a8e64a58ac5ce0af5d438c','file_count_excluding_manifest':8,'all_payloads_matched':True},'manifest evidence drift')
    require(len(p['payloads'])==8 and len({x['path'] for x in p['payloads']})==8,'payload inventory drift')
    studies=d['studies']; require([x['study_id'] for x in studies]==['DH-PRESENT-002','DH-PRESENT-003'],'study order drift')
    expected=[('DH-PRESENT-002',1672,941,2809928,'904aa44dfa2b6980d88d0776213d28d3e1fa3b2b8acba7798fdbed84e526e00e','34e1383c-a055-42fb-8458-f9c5e1a28642'),('DH-PRESENT-003',1536,1024,2580384,'dc8cd6ee426c486043a688bcf3a89025597e2c96b2b66e4064392b9bd9f901b2','bce19b7c-3393-477c-9724-9553145f343a')]
    for s,(sid,w,h,b,sha,gid) in zip(studies,expected):
        require(s['study_id']==sid and s['review_disposition']=='accepted_external_storyboard_reference_with_qualifications','study disposition drift')
        img=s['image']; require(img['width_px']==w and img['height_px']==h and img['bytes']==b and img['sha256']==sha and img['mode']=='RGB' and img['decode_verified'] is True,'image evidence drift')
        require(img['repository_path'] is None and img['repository_disposition']=='external_private_only' and img['runtime_composition'] is False and img['logical_960x540_validation'] is False,'binary/runtime claim introduced')
        g=s['generation']; require(g['available_generation_id']==gid and all(g[k] is None for k in ['exact_model_variant','exact_prompt','exact_negative_prompt','seed','exact_generation_timestamp','generator_side_reference_handling','content_credentials_status','watermark_status']),'generation facts fabricated')
        require(g['human_edits_after_generation']=='none_known_not_proof_none_occurred','human edit uncertainty drift')
        require([x['frame_id'] for x in s['frames']]==[f'{sid}-FR-{n:02d}' for n in range(1,11)],'frame identity/order drift')
        require(s['lifecycle']=={'status':'generated_external','review_status':'accepted_external_storyboard_reference_with_qualifications','candidate_id':None,'production_candidate':False,'approved':False},'candidate/lifecycle promotion')
    require(studies[0]['authority_owner']=='rules_session' and studies[0]['stage']=='last_light_v1','Last Light authority drift')
    require(studies[0]['special_qualification'].startswith('DH-PRESENT-002-FR-06 visualizes only an already-authorized'),'preview qualification missing')
    require(studies[1]['authority_owners']=={'ending_resolution':'rules_session','private_attribution':'role_session','cleanup':'session_coordinator'},'ending/attribution/cleanup authority drift')
    fam=d['presentation_family']; require(fam['sequence']==['DH-PRESENT-001','DH-PRESENT-002','DH-PRESENT-003'] and fam['status']=='family_consistency_assessed' and fam['conversion_readiness']=='not_ready' and fam['implementation_authorized'] is False,'family readiness promoted')
    require(fam['ux_helper']=={'state':'pending','authority':'advisory_until_release_coordination_review','implementation_authorized':False},'UX advisory boundary drift')
    a=d['authority']; require(a['rules_session_owns']==['stage legality','Last Light commitments and result','ending resolution','public ending result'],'RulesSession authority drift')
    require(a['role_session_owns']==['private attribution','controlled-reveal attribution timing','private and faction projections'],'RoleSession authority drift')
    require(a['session_coordinator_owns']==['rematch eligibility','return-to-title cleanup','terminal cleanup'],'coordinator authority drift')
    require('ending resolution' in a['presentation_never_owns'] and 'private attribution' in a['presentation_never_owns'] and 'RNG' in a['presentation_never_owns'],'presentation authority opened')
    pr=d['privacy']; require(pr['public_outcome_rail_private_safe_required'] is True and 'private objectives' in pr['shared_output_must_exclude'] and 'public ending consequences' in pr['shared_output_may_include'],'privacy boundary drift')
    rep=d['presentation_replay']; require(rep['played_skipped_interrupted_restored_replayed_converge'] and rep['presentation_replay_only'] and all(rep[k] is False for k in ['rerun_reducers_authorized','rerun_ending_resolution_authorized','rerun_attribution_authorized','rng_mutation_authorized','authoritative_event_reemission_authorized','cleanup_mutation_authorized']),'replay authority opened')
    q=d['qualifications']; require(len(q)==8 and 'not validation evidence' in q[5] and 'no seat cap' in q[7],'qualification inventory drift')
    r=d['review_requirements']; require(r['engine']=='Godot 4.7.1' and r['renderer']=='Compatibility' and r['logical_review_space']=={'width':960,'height':540,'origin':'top-left','safe_margin_reviews_px':[0,24,48]},'review space drift')
    require(all(r[k] is False for k in ['four_seat_density_validated','eight_seat_density_validated','safe_frame_validated','grayscale_value_validated','reduced_motion_validated','interruption_validated','replay_validated','television_readability_validated','human_comprehension_validated','essential_meaning_may_depend_on_color_only','essential_meaning_may_depend_on_transparency_only']),'unsupported review claim')
    gc=d['generated_content']; require(gc['branding_dates_counts_labels_signage_results_prose_seat_depictions']=='reference_only_non_authoritative' and gc['visible_four_seat_and_four_commitment_examples_authoritative'] is False and gc['visible_readability_checkmarks_are_evidence'] is False,'generated content promoted')
    rights=d['rights']; require(all(rights[k] is None for k in ['public_repository_rights','github_release_distribution_rights','derivative_production_rights']) and rights['public_distribution_authorized'] is False,'rights prematurely cleared')
    require(all(d['governance'].values()),'governance gate removed')
    require(all(v is False for v in d['evidence_claims'].values()),'unsupported evidence claim')

def validate_schema(s,c):
    require(s.get('$schema')=='https://json-schema.org/draft/2020-12/schema' and s.get('type')=='object' and s.get('additionalProperties') is False,'schema opened')
    require(s.get('required')==list(c.keys()) and set(s.get('properties',{}))==set(c),'schema inventory drift')
    for k in ['record_kind','record_version','identity','release']:
        require(s['properties'][k].get('const')==c[k],f'schema identity const drift: {k}')
    for k,v in c.items():
        if k in ['record_kind','record_version','identity','release']:
            continue
        expected='object' if isinstance(v,dict) else 'array' if isinstance(v,list) else 'boolean' if isinstance(v,bool) else 'integer' if isinstance(v,int) else 'string'
        require(s['properties'][k].get('type')==expected,f'schema type drift: {k}')

def validate_provenance(p,c):
    require(p['record_kind']=='dh_present_002_003_provenance' and p['record_version']==1 and p['release_id']=='DH-PRESENT-REG-002' and p['family_id']=='DH-PRESENT-FAMILY-001' and p['governing_issue']==118,'provenance identity drift')
    require(p['external_package']==c['external_package'],'provenance package drift')
    require([x['study_id'] for x in p['external_images']]==['DH-PRESENT-002','DH-PRESENT-003'] and all(x['binary_repository_paths']==[] for x in p['external_images']),'binary repository path introduced')
    require([x['available_generation_id'] for x in p['generation']]==['34e1383c-a055-42fb-8458-f9c5e1a28642','bce19b7c-3393-477c-9724-9553145f343a'],'generation provenance drift')
    rights=p['rights']; require(rights['state']=='unresolved' and all(rights[k] is None for k in ['public_repository_rights','github_release_distribution_rights','derivative_production_rights']) and all(rights[k] is False for k in ['public_distribution_authorized','candidate_creation_authorized','candidate_promotion_authorized','production_use_authorized','runtime_use_authorized']),'provenance rights cleared')
    require(p['generated_content']==c['generated_content'] and all(v is False for v in p['hard_boundaries'].values()),'provenance boundary opened')

def validate_markdown():
    joined='\n'.join(p.read_text(encoding='utf-8') for p in DOCS)
    for token in ['DH-PRESENT-REG-002','DH-PRESENT-001','DH-PRESENT-002','DH-PRESENT-003','DH-PRESENT-FAMILY-001','accepted_external_storyboard_reference_with_qualifications','family_consistency_assessed','not_ready','RulesSession','RoleSession','session coordinator','external/private','Issue #7','Issue #39','Alpha.3','Lantern House','PR #32']:
        require(token in joined,f'missing Markdown token: {token}')
    for token in ['preview authority','public consequences only','presentation replay only','readability checkmarks','not evidence','1–8 stable seats','UX helper']:
        require(token.lower() in joined.lower(),f'missing qualification: {token}')
    for claim in ['conversion readiness: ready','human playtesting passed','television readability validated','accessibility certified','public release authorized','production ready','shipping authorized']:
        require(claim not in joined.lower(),f'unsupported Markdown claim: {claim}')

def validate_git_boundary(skip=False):
    if skip:return
    head=os.environ.get('GITHUB_HEAD_REF') or subprocess.check_output(['git','branch','--show-current'],text=True).strip(); require(head==BRANCH,f'wrong branch: {head}')
    base_ref=os.environ.get('GITHUB_BASE_REF','main'); subprocess.run(['git','fetch','origin',base_ref,'--depth=1'],check=True,stdout=subprocess.DEVNULL)
    base_sha=subprocess.check_output(['git','rev-parse',f'origin/{base_ref}'],text=True).strip(); require(base_sha==BASE,f'protected main changed: {base_sha}')
    actual={x for x in subprocess.check_output(['git','diff','--name-only',f'{BASE}...HEAD'],text=True).splitlines() if x}
    require(actual==ALLOWED,f'exact path mismatch missing={sorted(ALLOWED-actual)} unexpected={sorted(actual-ALLOWED)}')
    for path in actual:
        require(not any(path.startswith(x) for x in ['art/source/','game/assets/','game/src/']),'prohibited path changed')
        require(Path(path).suffix.lower() not in {'.png','.webp','.svg','.glb','.zip','.kra','.psd','.blend','.aseprite','.xcf','.tscn','.tres'},'binary/source/runtime extension changed')

def validate_all(root=Path('.'),skip_git=False):
    old=Path.cwd()
    try:
        os.chdir(root); c=load(CONTRACT); validate_contract(c); validate_schema(load(SCHEMA),c); validate_provenance(load(PROVENANCE),c); validate_markdown(); validate_git_boundary(skip_git)
    finally: os.chdir(old)

def main():
    ap=argparse.ArgumentParser(); ap.add_argument('--skip-git-boundary',action='store_true'); a=ap.parse_args()
    try: validate_all(Path('.'),a.skip_git_boundary)
    except (ValidationError,KeyError,ValueError,json.JSONDecodeError,subprocess.CalledProcessError,OSError) as e:
        print(f'VALIDATION FAILED: {e}',file=sys.stderr); return 1
    print('Validated DH-PRESENT-REG-002 exact presentation-family metadata package'); return 0
if __name__=='__main__': raise SystemExit(main())
