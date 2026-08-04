#!/usr/bin/env python3
from __future__ import annotations
import copy, importlib.util, json, tempfile
from pathlib import Path

ROOT=Path('.')
spec=importlib.util.spec_from_file_location('validator',ROOT/'tools/validate_drowned_harbor_visual_baseline.py')
v=importlib.util.module_from_spec(spec); assert spec.loader; spec.loader.exec_module(v)
B=json.loads((ROOT/v.BATCH).read_text(encoding='utf-8'))
C=json.loads((ROOT/v.CONTRACT).read_text(encoding='utf-8'))
S=json.loads((ROOT/v.SCHEMA).read_text(encoding='utf-8'))
P=json.loads((ROOT/v.PROVENANCE).read_text(encoding='utf-8'))

def rejected(fn,name):
    try: fn()
    except (v.ValidationError,KeyError,ValueError): return
    raise AssertionError(f'mutation survived: {name}')

def test_batch(mut,name):
    x=copy.deepcopy(B); mut(x); rejected(lambda:v.validate_batch(x),name)
def test_contract(mut,name):
    x=copy.deepcopy(C); mut(x); rejected(lambda:v.validate_contract(x),name)
def test_schema(mut,name):
    x=copy.deepcopy(S); mut(x); rejected(lambda:v.validate_schema(x,C),name)
def test_provenance(mut,name):
    x=copy.deepcopy(P); mut(x); rejected(lambda:v.validate_provenance(x,B),name)

def main():
    test_batch(lambda x:x['candidates'][0].update(status='production_candidate'),'candidate promotion')
    test_batch(lambda x:x['boundaries'].update(approved_allowed=True),'approved state')
    test_provenance(lambda x:x['candidate_provenance'][0].update(rights_state='cleared',public_distribution_authorized=True),'fabricated rights clearance')
    test_contract(lambda x:x['authority_references'].remove('docs/technical/Shared_Screen_Storyboard_Contract_v1.md'),'missing authority path')
    test_contract(lambda x:x['tide_authority']['chain'].__setitem__(0,'visual owns Tide state'),'altered Tide authority')
    test_contract(lambda x:x['tide_authority'].update(presentation_never_owns=[]),'visual ownership of runtime state')
    test_contract(lambda x:x.update(qualified_identity_contexts={'DH-UI-001':'ambiguous'}),'unqualified DH-UI-001')
    test_contract(lambda x:x['authorization'].update(implementation_authorized=True),'implementation authorization')
    test_contract(lambda x:x['authorization'].update(codex_authorized=True),'Codex authorization')
    test_contract(lambda x:x['prohibited_path_prefixes'].remove('game/assets/'),'runtime path boundary')
    test_contract(lambda x:x['governance'].update(issue_7_naming_branding_gate=False),'issue 7 removal')
    test_contract(lambda x:x['governance'].update(issue_39_human_physical_evidence_gate=False),'issue 39 removal')
    test_contract(lambda x:x['authorization'].update(normal_tale_registration_authorized=True),'normal Tale registration')
    test_contract(lambda x:x['authorization'].update(ordinary_export_inclusion_authorized=True),'ordinary export inclusion')
    test_batch(lambda x:x['candidates'][0]['binary_metadata'].update(width_px=2048),'fabricated candidate dimension')
    test_batch(lambda x:x['candidates'][0]['binary_metadata'].update(sha256='0'*64),'fabricated candidate hash')
    test_batch(lambda x:x['candidates'][-1].pop('superseded_by'),'missing supersession')
    test_schema(lambda x:x.update(additionalProperties=True),'opened schema')
    test_contract(lambda x:x['evidence_claims'].update(television_readability=True),'unsupported evidence claim')
    test_batch(lambda x:x['source_package_evidence']['external_planning_package'].update(bytes=1),'package dimension/status drift')
    test_provenance(lambda x:x['binary_repository_paths'].append('art/exports/fake.png'),'binary path introduced')
    print('Validated 21 fail-closed DH-VBL-001 mutations')
    return 0
if __name__=='__main__': raise SystemExit(main())
