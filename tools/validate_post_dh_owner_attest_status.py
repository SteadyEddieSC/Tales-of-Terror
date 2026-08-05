#!/usr/bin/env python3
from __future__ import annotations
import argparse, hashlib, json, os, subprocess, sys
from pathlib import Path
ROOT=Path('.')
BASE='7af430b5d9528c648d00291e4c32fa368279b41b'
BRANCH='docs/post-dh-owner-attest-status-reconciliation'
STATUS=Path('docs/preproduction/post_prototype_status_v1.json')
OWNER=Path('docs/tales/drowned_harbor/visual/drowned_harbor_project_owner_attestation_v1.json')
DOCS=[Path('README.md'),Path('docs/preproduction/README.md'),Path('docs/roadmap/Post_P0.19_Production_Candidate_Roadmap.md')]
ALLOWED={'README.md','.github/workflows/p021-production-architecture.yml','.github/workflows/p022-alpha2-graybox-contract.yml','.github/workflows/p023-alpha3-systems-replayability-contract.yml','.github/workflows/post-prototype-reconciliation.yml','docs/preproduction/README.md','docs/preproduction/post_prototype_status_v1.json','docs/roadmap/Post_P0.19_Production_Candidate_Roadmap.md','tools/test_validate_post_dh_owner_attest_status.py','tools/validate_post_dh_owner_attest_status.py'}
STATUS_SHA='74d4ad968a47a665570a1fc75dec4978e1435283452d50f3ef92a32a4739c6b2'
OWNER_SHA='e41e603bf3654bac392fee006dad4f979c6f7dcead7b683e4f6f16fd4e7ca520'
class ValidationError(Exception): pass
def need(v,m):
    if not v: raise ValidationError(m)
def load(p): return json.loads((ROOT/p).read_text(encoding='utf-8'))
def digest(v): return hashlib.sha256(json.dumps(v,sort_keys=True,separators=(',',':'),ensure_ascii=False).encode()).hexdigest()
def validate_status(s):
    need(digest(s)==STATUS_SHA,'status drift')
    need(s['schema_version']==7 and s['protected_main']==BASE,'status identity drift')
    need(s['pending_inputs']==[],'attestation still pending')
    need(s['recommended_next_release']=={'activation_authorized':False,'codex_required':False,'github_issue':None,'release_id':None,'state':'unselected_metadata_only_clean_room_planning_eligible_explicit_activation_required','title':None},'successor selected or eligibility drift')
    o=s['visual_planning']['owner_attestation']
    need(o['attestation_complete'] is True and o['metadata_only_clean_room_planning_eligibility_established'] is True,'owner attestation incomplete')
    need(o['clean_room_source_planning_authorized'] is False and o['clean_room_source_creation_authorized'] is False and o['implementation_authorized'] is False,'planning or implementation authorized')
    r=s['visual_planning']['rights_provenance']
    need(r['owner_attestation_required'] is False and r['prerequisite_state']=='owner_attestation_complete_clean_room_planning_eligible_not_authorized','rights prerequisite drift')
    need(r['max_rights_tier']=='R1_private_internal_reference' and r['reference_only_nonproduction'] is True and r['conversion_readiness']=='not_ready','R1 boundary drift')
def validate_owner(o):
    need(digest(o)==OWNER_SHA,'owner registration drift')
    d=o['disposition']; need(d['metadata_only_clean_room_planning_eligibility_established'] is True,'eligibility missing')
    for k in ['clean_room_source_planning_authorized','clean_room_source_creation_authorized','direct_generated_pixel_use_authorized','source_art_authorized','runtime_art_authorized','godot_authorized','codex_authorized','candidate_creation_or_promotion_authorized','public_distribution_authorized','implementation_authorized','next_release_selected','next_release_activation_authorized']:
        need(d[k] is False,f'forbidden authority: {k}')
def validate_docs():
    t='\n'.join((ROOT/p).read_text(encoding='utf-8') for p in DOCS).lower()
    for x in [BASE,'issue #131 / pr #132','dh-owner-attest-reg-001','dh-owner-attest-001','accepted_completed_owner_attestation_sufficient_for_metadata_only_clean_room_planning_eligibility','clean-room source planning itself remains unauthorized','r1_private_internal_reference','reference_only_nonproduction','conversion readiness `not_ready`','implementation authorization false','no successor release is selected or activated','lantern house remains the sole normal/default tale','drowned harbor remains developer-only','issue #39','issue #7','pr #32','automation is not human evidence']:
        need(x in t,f'missing current documentation: {x}')
    for x in ['project owner attestation and generation-session reconstruction remain required','owner attestation pending','blocked on project owner attestation','clean-room source planning is authorized','source creation is authorized','direct generated-pixel use is authorized','rights are fully cleared','legal clearance complete','candidate approved','production ready','shipping authorized','human evidence passed','accessibility certified']:
        need(x not in t,f'stale or unsupported claim: {x}')
def branch(): return os.environ.get('GITHUB_HEAD_REF') or os.environ.get('GITHUB_REF_NAME') or subprocess.check_output(['git','branch','--show-current'],text=True).strip()
def validate_git():
    if branch()!=BRANCH: return
    actual={x for x in subprocess.check_output(['git','diff','--name-only',f'{BASE}...HEAD'],text=True).splitlines() if x}
    need(actual==ALLOWED,f'path mismatch missing={sorted(ALLOWED-actual)} unexpected={sorted(actual-ALLOWED)}')
    for p in actual: need(not p.startswith(('game/','art/source/','game/assets/')) and Path(p).suffix.lower() not in {'.png','.jpg','.jpeg','.webp','.zip','.psd','.kra','.blend','.aseprite','.tscn','.tres'},f'prohibited path {p}')
def validate(check_git=True):
    validate_status(load(STATUS)); validate_owner(load(OWNER)); validate_docs()
    if check_git: validate_git()
def main():
    ap=argparse.ArgumentParser(); ap.add_argument('--skip-git-boundary',action='store_true'); a=ap.parse_args(); validate(not a.skip_git_boundary); print('Validated post-DH-OWNER-ATTEST current status and succession boundary'); return 0
if __name__=='__main__':
    try: raise SystemExit(main())
    except (ValidationError,KeyError,TypeError,IndexError,json.JSONDecodeError,subprocess.CalledProcessError,OSError) as e: print(f'ERROR: {e}',file=sys.stderr); raise SystemExit(1)
