#!/usr/bin/env python3
from __future__ import annotations
import argparse, copy, json, os, subprocess, sys
from pathlib import Path
from typing import Any

ROOT=Path('.')
BASE='cbe917771ae98089f8cea11b08d68427be84ccd0'
BRANCH='docs/dh-vbl-001-visual-baseline-registration'
ALLOWED={
'.github/workflows/drowned-harbor-visual-baseline.yml',
'.github/workflows/preproduction-shared-screen-storyboards.yml',
'docs/releases/DH-VBL-001-visual-baseline-registration.md',
'docs/tales/drowned_harbor/visual/Drowned_Harbor_Visual_Baseline_v1.md',
'docs/tales/drowned_harbor/visual/drowned_harbor_concept_batch_002.json',
'docs/tales/drowned_harbor/visual/Drowned_Harbor_Board_Production_Conversion_Brief_01.md',
'docs/tales/drowned_harbor/visual/drowned_harbor_board_production_conversion_brief_01_v1.json',
'docs/tales/drowned_harbor/visual/drowned_harbor_board_production_conversion_brief_01_schema_v1.json',
'art/licenses/drowned_harbor/visual/dh_vbl_001_provenance_v1.json',
'tools/validate_drowned_harbor_visual_baseline.py',
'tools/test_validate_drowned_harbor_visual_baseline.py',
'tools/validate_preproduction_visual_candidates_reviewed_external.py'}
BATCH=Path('docs/tales/drowned_harbor/visual/drowned_harbor_concept_batch_002.json')
CONTRACT=Path('docs/tales/drowned_harbor/visual/drowned_harbor_board_production_conversion_brief_01_v1.json')
SCHEMA=Path('docs/tales/drowned_harbor/visual/drowned_harbor_board_production_conversion_brief_01_schema_v1.json')
PROVENANCE=Path('art/licenses/drowned_harbor/visual/dh_vbl_001_provenance_v1.json')
BASELINE=Path('docs/tales/drowned_harbor/visual/Drowned_Harbor_Visual_Baseline_v1.md')
BRIEF=Path('docs/tales/drowned_harbor/visual/Drowned_Harbor_Board_Production_Conversion_Brief_01.md')
RELEASE=Path('docs/releases/DH-VBL-001-visual-baseline-registration.md')

class ValidationError(ValueError): pass
def require(c:bool,m:str):
    if not c: raise ValidationError(m)
def load(p:Path)->dict[str,Any]:
    x=json.loads(p.read_text(encoding='utf-8')); require(isinstance(x,dict),f'object required: {p}'); return x

def validate_batch(d):
    require(d['register_kind']=='external_visual_candidate_register','register kind drift')
    require(d['batch_id']=='DH-CB-002' and d['baseline_id']=='DH-VBL-001','batch identity drift')
    require(d['protected_main_base']==BASE and d['branch']==BRANCH,'release coordinate drift')
    require(d['repository_storage']=='metadata_only_external_binaries','storage drift')
    sc=d['existing_candidate_schema']; require(sc['conformance']=='blocked_by_unresolved_required_source_facts' and sc['must_not_be_claimed_conformant'] is True,'false schema conformance')
    ids=[x['candidate_id'] for x in d['candidates']]
    require(ids==[f'DH-CAND-{i:03d}-A' for i in range(5,16)],'candidate inventory drift')
    for i,r in enumerate(d['candidates'],5):
        expected_status='deferred' if i==15 else 'generated_external'
        expected_review='preproduction_shortlist' if i<=9 else 'reference_only'
        require(r['status']==expected_status and r['review_status']==expected_review,'candidate status drift')
        require(r['repository_disposition']=='external_candidate_pending_upload','repository disposition drift')
        require(r['production_master'] is False and r['runtime_asset'] is False and r['generated_text_authoritative'] is False,'candidate promotion or generated-text authority')
        bm=r['binary_metadata']; require(bm=={'width_px':None,'height_px':None,'bytes':None,'sha256':None,'availability':'unresolved_not_disclosed_by_reviewed_source'},'candidate binary metadata fabricated or drifted')
        pf=r['provenance_facts']; require(pf['availability']=='unresolved_not_disclosed_by_reviewed_source' and all(pf[k] is None for k in pf if k!='availability'),'candidate provenance fabricated')
    require(d['candidates'][-1].get('superseded_by')=='DH-CAND-005-A','missing supersession')
    b=d['boundaries']; require(all(b[k] is False for k in ['production_candidate_allowed','approved_allowed','image_binaries_committed','implementation_authorized','codex_authorized','normal_tale_registered','ordinary_export_included','pr_32_incorporated']),'authorization boundary opened')
    require(all(b[k] is True for k in ['issue_7_gate_preserved','issue_39_gate_preserved','alpha3_developer_only','lantern_house_sole_normal_default_tale']),'governance gate removed')
    expected={'external_planning_package':(47061,'152c67e0ce971ee341d30070d752d24803e3ba7cc5c2d03a4b917f2c74cddaaf'),'working_draft_package':(18960,'a02c156c7a62af3f301e505741d71e8f0ff4f5e7b3e2f1fa308442a9d63e68f1'),'baseline_registration_package':(11321,'57694b81d9ee207ba0ae18d0b23495d54243c5ebc68c81a3b2a5e35e0db4052e'),'machine_contract_package':(6978,'b7962bb515f57b634dbda9de640378c17cd0dd382b628c4abcb993788d80c517'),'routing_packet':(5993,'5eaaba13d786841863dfb33385f285b3d8ed07b2b44942ee47382d6111812b70')}
    for k,(n,h) in expected.items(): require(d['source_package_evidence'][k]['bytes']==n and d['source_package_evidence'][k]['sha256']==h and d['source_package_evidence'][k]['integrity_verified'] is True,'package hash/size drift')

def validate_contract(d):
    require(d['contract_kind']=='drowned_harbor_board_production_conversion_brief' and d['schema_version']==1,'contract identity drift')
    require(d['identity']=={'brief_id':'DH-VCB-001','title':'Drowned Harbor Board Environment Breakdown','baseline_id':'DH-VBL-001','candidate_batch_id':'DH-CB-002','review_disposition':'accepted_external_working_specification'},'identity or review disposition drift')
    require(d['release']=={'issue':110,'protected_main_base':BASE,'branch':BRANCH,'planning_only':True,'metadata_only':True},'release drift')
    require(all(v is False for v in d['authorization'].values()),'implementation, Codex, promotion, PR32, runtime, source, registration, or export authority opened')
    g=d['governance']; require(g['issue_7_naming_branding_gate'] and g['issue_39_human_physical_evidence_gate'] and g['alpha3_developer_only'] and g['lantern_house_sole_normal_default_tale'],'governance gate drift')
    required_authorities={'docs/tales/drowned_harbor/visual/visual_asset_brief_schema_v1.json','docs/tales/drowned_harbor/visual/visual_candidate_batch_schema_v1.json','docs/tales/drowned_harbor/visual/drowned_harbor_concept_batch_001.json','docs/tales/drowned_harbor/ui/README.md','docs/tales/drowned_harbor/ui/drowned_harbor_core_storyboards_v1.json','docs/tales/drowned_harbor/ui/drowned_harbor_continuity_accessibility_storyboards_v1.json','docs/preproduction/shared_screen_storyboard_schema_v1.json','docs/technical/Shared_Screen_Storyboard_Contract_v1.md'}
    require(required_authorities.issubset(set(d['authority_references'])),'missing authority paths')
    q=d['qualified_identity_contexts']; require(set(q)=={'visual_asset_brief_DH_UI_001','storyboard_DH_UI_001','storyboard_family_DH_UI_001_through_DH_UI_022'},'unqualified DH-UI-001')
    c=d['construction']; require(c['default_presumption']=='layered_painted_2_5d' and c['permitted_later_alternatives']==['controlled_stylized_3d','bounded_hybrid'] and c['final_construction_decision_made'] is False and c['one_authoritative_shared_board_master_required'] is True and c['independently_painted_state_masters_acceptable'] is False,'construction boundary drift')
    require([x['board_module_id'] for x in d['board_modules']]==[f'DH-BMOD-{i:03d}' for i in range(1,8)],'module identity drift')
    require(d['planning_vocabulary']['runtime_enum_mappings_created'] is False,'runtime enum mapping created')
    t=d['tide_authority']; require(t['chain']==['authoritative runtime Tide/stage state','visual_tide_state','authorized flood/water presentation mapping','mask set and presentation derivative'],'Tide authority altered')
    require(t['land_connector_phrase']=='visual representation of authoritative land-connector state' and t['water_only_connector_phrase']=='visual representation of authoritative water-only connector state','connector authority wording drift')
    require(t['presentation_never_owns']==['route legality','movement authority','runtime Tide state','runtime stage state','authoritative connector state','gameplay-event authority'],'presentation owns runtime authority')
    require(d['source_model']['path_is_reserved_not_authorized'] is True and d['source_model']['module_sources_own_independent_placement'] is False,'source master authorization drift')
    require(d['prohibited_path_prefixes']==['art/source/','game/assets/','game/src/'],'prohibited path boundary drift')
    require(all(v is False for v in d['evidence_claims'].values()),'unsupported evidence claim')
    p=d['provenance']; require(p['external_binaries_only'] and p['unresolved_rights'] and p['unresolved_candidate_binary_metadata'] and p['existing_candidate_schema_conformance_claimed'] is False,'provenance or rights prematurely cleared')

def validate_schema(s,c):
    require(s.get('$schema')=='https://json-schema.org/draft/2020-12/schema','schema dialect drift')
    require(s.get('type')=='object','schema type drift')
    require(s.get('additionalProperties') is False,'schema opened')
    require(s.get('const')==c,'schema no longer closes exact contract')

def validate_provenance(p,b):
    require(p['baseline_id']=='DH-VBL-001' and p['candidate_batch_id']=='DH-CB-002','provenance identity drift')
    require(p['binary_repository_paths']==[],'binary path introduced')
    require(len(p['candidate_provenance'])==11,'provenance inventory drift')
    require(all(x['rights_state']=='unresolved' and x['public_distribution_authorized'] is False and x['derivative_use_authorized'] is False and x['production_replacement_required'] is True for x in p['candidate_provenance']),'rights cleared or production replacement removed')
    require(all(v is False for v in p['hard_boundaries'].values()),'provenance hard boundary opened')

def validate_markdown():
    texts={p:p.read_text(encoding='utf-8') for p in [BASELINE,BRIEF,RELEASE]}
    combined='\n'.join(texts.values())
    for token in ['DH-VBL-001','DH-CB-002','DH-VCB-001','accepted_external_working_specification','Issue #7','Issue #39','PR #32','Alpha.3','Lantern House','developer-only','planning authority only']:
        require(token in combined,f'missing Markdown boundary: {token}')
    require('visual asset brief `DH-UI-001`' in combined and 'storyboard `DH-UI-001`' in combined,'unqualified DH-UI-001 in Markdown')
    require('authoritative runtime Tide/stage state' in texts[BRIEF] and 'visual representation of authoritative land-connector state' in texts[BRIEF],'Tide wording missing from Markdown')
    forbidden=['production_candidate` / `approved','Codex used:** yes','implementation authorized: yes']
    require(not any(x in combined for x in forbidden),'unsupported Markdown authorization')

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
    global ROOT
    old=Path.cwd()
    try:
        os.chdir(root)
        b=load(BATCH); c=load(CONTRACT); s=load(SCHEMA); p=load(PROVENANCE)
        validate_batch(b); validate_contract(c); validate_schema(s,c); validate_provenance(p,b); validate_markdown(); validate_git_boundary(skip_git)
    finally: os.chdir(old)

def main():
    ap=argparse.ArgumentParser(); ap.add_argument('--skip-git-boundary',action='store_true'); a=ap.parse_args()
    try: validate_all(Path('.'),a.skip_git_boundary)
    except (ValidationError,KeyError,ValueError,json.JSONDecodeError,subprocess.CalledProcessError) as e:
        print(f'VALIDATION FAILED: {e}',file=sys.stderr); return 1
    print('Validated DH-VBL-001 exact planning package'); return 0
if __name__=='__main__': raise SystemExit(main())
