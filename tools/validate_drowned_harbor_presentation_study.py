#!/usr/bin/env python3
from __future__ import annotations
import argparse, json, os, subprocess, sys
from pathlib import Path
from typing import Any

BASE='0cea1ac62733fda56d09cb0de8a789efc509308a'
BRANCH='docs/dh-present-001-metadata-registration'
ALLOWED={
'.github/workflows/drowned-harbor-presentation-study.yml',
'docs/releases/DH-PRESENT-001-presentation-study-registration.md',
'docs/tales/drowned_harbor/visual/Drowned_Harbor_High_Water_Presentation_Hook_Storyboard_Study_v1.md',
'docs/tales/drowned_harbor/visual/drowned_harbor_high_water_presentation_hook_storyboard_study_v1.json',
'docs/tales/drowned_harbor/visual/drowned_harbor_high_water_presentation_hook_storyboard_study_schema_v1.json',
'art/licenses/drowned_harbor/visual/dh_present_001_provenance_v1.json',
'tools/validate_drowned_harbor_presentation_study.py',
'tools/test_validate_drowned_harbor_presentation_study.py'}
CONTRACT=Path('docs/tales/drowned_harbor/visual/drowned_harbor_high_water_presentation_hook_storyboard_study_v1.json')
SCHEMA=Path('docs/tales/drowned_harbor/visual/drowned_harbor_high_water_presentation_hook_storyboard_study_schema_v1.json')
PROVENANCE=Path('art/licenses/drowned_harbor/visual/dh_present_001_provenance_v1.json')
STUDY=Path('docs/tales/drowned_harbor/visual/Drowned_Harbor_High_Water_Presentation_Hook_Storyboard_Study_v1.md')
RELEASE=Path('docs/releases/DH-PRESENT-001-presentation-study-registration.md')

class ValidationError(ValueError): pass
def require(c:bool,m:str):
    if not c: raise ValidationError(m)
def load(p:Path)->dict[str,Any]:
    x=json.loads(p.read_text(encoding='utf-8')); require(isinstance(x,dict),f'object required: {p}'); return x

def validate_contract(d):
    require(d['record_kind']=='drowned_harbor_high_water_presentation_hook_storyboard_study_registration' and d['record_version']==1,'contract identity drift')
    require(d['identity']=={'release_id':'DH-PRESENT-REG-001','study_id':'DH-PRESENT-001','visual_baseline_id':'DH-VBL-001','conversion_brief_id':'DH-VCB-001','governing_issue':114,'review_disposition':'accepted_external_storyboard_reference'},'registered identities drift')
    require(d['release']=={'protected_main_base':BASE,'branch':BRANCH,'planning_only':True,'metadata_only':True},'release coordinates drift')
    require(all(v is False for v in d['authorization'].values()),'authorization boundary opened')
    pkg=d['external_package']; require(pkg['filename']=='DH-PRESENT-001_External_Art_Director_Handoff_Package_v1.zip' and pkg['bytes']==2408052 and pkg['sha256']=='6f3bbacb50dcca8ccf12ee2e7a228abaa4393299dd06864a65b72fa7c4b1a506' and pkg['repository_disposition']=='external_private_only' and pkg['integrity_verified'] is True,'package evidence drift')
    m=pkg['manifest']; require(m=={'path':'02_MACHINE_READABLE/PACKAGE_MANIFEST.json','bytes':1850,'sha256':'aca64d4592ab1a8ff50f11f2de160889dbf5d73340b983fff309c0f2e218e697','file_count_excluding_manifest':8,'all_payloads_matched':True},'manifest evidence drift')
    require(len(pkg['payloads'])==8 and len({x['path'] for x in pkg['payloads']})==8,'payload inventory drift')
    img=d['image']; require(img['filename']=='DH-PRESENT-001_Drowned_Harbor_High_Water_Environmental_Presentation-Hook_Storyboard_Study_v1.png' and img['media_type']=='image/png' and img['width_px']==1536 and img['height_px']==1024 and img['mode']=='RGB' and img['bytes']==2497096 and img['sha256']=='51e2a1774529500385260d1800aacd1f3265024db6cc0b93c0e76ee8a363cc07' and img['decode_verified'] is True,'image evidence drift')
    require(img['repository_path'] is None and img['repository_disposition']=='external_private_only' and img['runtime_composition'] is False and img['logical_960x540_validation'] is False,'binary/runtime claim introduced')
    a=d['authority']; require(a['chain']==['authoritative runtime Tide/stage state','visual_tide_state','authorized flood/water presentation mapping','mask set and presentation derivative'],'Tide authority drift')
    require(a['land_connector_phrase']=='visual representation of authoritative land-connector state' and a['water_only_connector_phrase']=='visual representation of authoritative water-only connector state','connector phrase drift')
    require(a['presentation_never_owns']==['route legality','movement authority','runtime Tide state','runtime stage state','authoritative connector state','gameplay-event authority'],'presentation owns runtime authority')
    require(a['one_authoritative_shared_board_master_required'] is True and a['shared_invariants']==['coordinate system','geometry','camera and projection','landmark anchors','route authority','elevation authority','shoreline and flood boundaries'],'shared-master drift')
    hooks=['dh_present_waterline_advance','dh_present_route_submerge','dh_present_route_reveal_water_only','dh_present_lighthouse_beam_rotate','dh_present_bellhouse_pressure','dh_present_lifeboat_release','dh_present_archive_access_reveal','dh_present_debris_current','dh_present_fog_pressure','dh_present_landmark_light_state']
    require(d['presentation_hooks']==hooks,'authorized hook inventory drift')
    frames=d['frames']; require([x['frame_id'] for x in frames]==[f'DH-PRESENT-001-FR-{i:02d}' for i in range(1,11)],'frame identity or order drift')
    require(len({x['frame_id'] for x in frames})==10,'duplicate frame identity')
    require(all(set(x['hook_ids']).issubset(set(hooks)) for x in frames),'unknown hook mapping')
    expected=[[],['dh_present_bellhouse_pressure'],['dh_present_fog_pressure','dh_present_debris_current'],['dh_present_waterline_advance'],['dh_present_route_submerge'],['dh_present_route_reveal_water_only'],['dh_present_lighthouse_beam_rotate','dh_present_bellhouse_pressure','dh_present_lifeboat_release','dh_present_archive_access_reveal','dh_present_landmark_light_state'],['dh_present_debris_current','dh_present_fog_pressure'],['dh_present_landmark_light_state'],[]]
    require([x['hook_ids'] for x in frames]==expected,'frame/hook mapping drift')
    s=d['skip_equivalence']; require(s['required'] and s['played_skipped_interrupted_restored_replayed_converge'] and s['implementation_proof_claimed'] is False and all(s[k] is False for k in ['authoritative_state_mutation_authorized','rng_mutation_authorized','stable_seat_identity_mutation_authorized','public_private_projection_mutation_authorized']),'skip equivalence boundary drift')
    r=d['review_requirements']; require(r['engine']=='Godot 4.7.1' and r['renderer']=='Compatibility' and r['logical_review_space']=={'width':960,'height':540,'origin':'top-left','safe_margin_reviews_px':[0,24,48]},'review-space drift')
    require(all(r[k] is False for k in ['four_seat_density_validated','eight_seat_density_validated','safe_frame_validated','grayscale_value_validated','reduced_motion_validated','interruption_validated','replay_validated','television_readability_validated','human_comprehension_validated','essential_meaning_may_depend_on_color_only','essential_meaning_may_depend_on_transparency_only']),'unsupported review/evidence claim')
    g=d['generation']; require(g['available_generation_id']=='65b33e0d-1cec-4439-bdb6-9b4da1b83669' and all(g[k] is None for k in ['exact_model_variant','exact_prompt','exact_negative_prompt','seed','exact_generation_timestamp','generator_side_reference_handling','content_credentials_status','watermark_status']),'generation facts fabricated')
    require(g['human_edits_after_generation']=='none_known_not_proof_none_occurred','human-edit uncertainty drift')
    rights=d['rights']; require(all(rights[k] is None for k in ['public_repository_rights','github_release_distribution_rights','derivative_production_rights']) and rights['public_distribution_authorized'] is False and rights['production_replacement_required'] is True,'rights prematurely cleared')
    gc=d['generated_content']; require(gc['text_labels_signage_prose']=='reference_only_non_authoritative' and gc['visible_date']=={'text':'May 18, 2025','authoritative':False,'creation_metadata':False} and gc['production_replacement_required'] is True,'generated content promoted')
    require(d['lifecycle']=={'status':'generated_external','review_status':'accepted_external_storyboard_reference','candidate_id':None,'production_candidate':False,'approved':False},'candidate/lifecycle promotion')
    gov=d['governance']; require(all(gov.values()),'governance gate removed')
    require(d['prohibited_path_prefixes']==['art/source/','game/assets/','game/src/'],'prohibited path drift')
    require(all(v is False for v in d['evidence_claims'].values()),'unsupported evidence claim')

def validate_schema(s,c):
    require(s.get('$schema')=='https://json-schema.org/draft/2020-12/schema','schema dialect drift')
    require(s.get('type')=='object' and s.get('additionalProperties') is False,'schema opened')
    require(s.get('required')==list(c.keys()) and set(s.get('properties',{}))==set(c),'schema inventory drift')
    for key in ['record_kind','record_version','identity','release','lifecycle']:
        require(s['properties'][key].get('const')==c[key],f'schema identity closure drift: {key}')
    for key,value in c.items():
        if key in ['record_kind','record_version','identity','release','lifecycle']: continue
        expected='object' if isinstance(value,dict) else 'array' if isinstance(value,list) else 'string' if isinstance(value,str) else 'boolean' if isinstance(value,bool) else 'integer'
        require(s['properties'][key].get('type')==expected,f'schema type drift: {key}')

def validate_provenance(p,c):
    require(p['record_kind']=='dh_present_001_provenance' and p['record_version']==1 and p['release_id']=='DH-PRESENT-REG-001' and p['study_id']=='DH-PRESENT-001' and p['governing_issue']==114,'provenance identity drift')
    require(p['external_package']['sha256']==c['external_package']['sha256'] and p['external_package']['payloads']==c['external_package']['payloads'],'provenance package drift')
    img=p['external_image']; require(img['sha256']==c['image']['sha256'] and img['binary_repository_paths']==[],'binary repository path introduced')
    require(p['generation']==c['generation'],'generation provenance drift')
    rights=p['rights']; require(rights['state']=='unresolved' and all(rights[k] is None for k in ['public_repository_rights','github_release_distribution_rights','derivative_production_rights']) and all(rights[k] is False for k in ['public_distribution_authorized','candidate_creation_authorized','candidate_promotion_authorized','production_use_authorized','runtime_use_authorized']) and rights['production_replacement_required'] is True,'provenance rights cleared')
    require(p['generated_content']==c['generated_content'],'generated-content provenance drift')
    require(all(v is False for v in p['hard_boundaries'].values()),'provenance hard boundary opened')

def validate_markdown():
    texts={p:p.read_text(encoding='utf-8') for p in [STUDY,RELEASE]}; combined='\n'.join(texts.values())
    for token in ['DH-PRESENT-REG-001','DH-PRESENT-001','DH-VBL-001','DH-VCB-001','accepted_external_storyboard_reference','Issue #7','Issue #39','PR #32','Alpha.3','Lantern House','external/private','metadata and planning authority only']:
        require(token in combined,f'missing Markdown boundary: {token}')
    for token in ['authoritative runtime Tide/stage state','visual representation of authoritative land-connector state','visual representation of authoritative water-only connector state','1536 × 1024','960×540']:
        require(token in combined,f'missing study fact: {token}')
    require('The PNG and ZIP remain external/private' in combined,'binary storage boundary missing')

def validate_git_boundary(skip=False):
    if skip: return
    head=os.environ.get('GITHUB_HEAD_REF') or subprocess.check_output(['git','branch','--show-current'],text=True).strip()
    require(head==BRANCH,f'wrong branch: {head}')
    base_ref=os.environ.get('GITHUB_BASE_REF','main')
    subprocess.run(['git','fetch','origin',base_ref,'--depth=1'],check=True,stdout=subprocess.DEVNULL)
    base_sha=subprocess.check_output(['git','rev-parse',f'origin/{base_ref}'],text=True).strip()
    require(base_sha==BASE,f'protected main changed: {base_sha}')
    actual={x for x in subprocess.check_output(['git','diff','--name-only',f'{BASE}...HEAD'],text=True).splitlines() if x}
    require(actual==ALLOWED,f'exact path mismatch missing={sorted(ALLOWED-actual)} unexpected={sorted(actual-ALLOWED)}')
    for path in actual:
        require(not any(path.startswith(x) for x in ['art/source/','game/assets/','game/src/']),'prohibited path changed')
        require(Path(path).suffix.lower() not in {'.png','.webp','.svg','.glb','.zip','.kra','.psd','.blend','.aseprite','.xcf','.tscn','.tres'},'binary/source/runtime extension changed')

def validate_all(root=Path('.'),skip_git=False):
    old=Path.cwd()
    try:
        os.chdir(root); c=load(CONTRACT); s=load(SCHEMA); p=load(PROVENANCE)
        validate_contract(c); validate_schema(s,c); validate_provenance(p,c); validate_markdown(); validate_git_boundary(skip_git)
    finally: os.chdir(old)

def main():
    ap=argparse.ArgumentParser(); ap.add_argument('--skip-git-boundary',action='store_true'); a=ap.parse_args()
    try: validate_all(Path('.'),a.skip_git_boundary)
    except (ValidationError,KeyError,ValueError,json.JSONDecodeError,subprocess.CalledProcessError) as e:
        print(f'VALIDATION FAILED: {e}',file=sys.stderr); return 1
    print('Validated DH-PRESENT-REG-001 exact metadata package'); return 0
if __name__=='__main__': raise SystemExit(main())
