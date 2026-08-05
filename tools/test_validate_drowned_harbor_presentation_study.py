#!/usr/bin/env python3
from __future__ import annotations
import copy, importlib.util, json
from pathlib import Path

ROOT=Path('.')
spec=importlib.util.spec_from_file_location('validator',ROOT/'tools/validate_drowned_harbor_presentation_study.py')
v=importlib.util.module_from_spec(spec); assert spec.loader; spec.loader.exec_module(v)
C=json.loads((ROOT/v.CONTRACT).read_text(encoding='utf-8'))
S=json.loads((ROOT/v.SCHEMA).read_text(encoding='utf-8'))
P=json.loads((ROOT/v.PROVENANCE).read_text(encoding='utf-8'))

def rejected(fn,name):
    try: fn()
    except (v.ValidationError,KeyError,ValueError): return
    raise AssertionError(f'mutation survived: {name}')
def test_contract(mut,name):
    x=copy.deepcopy(C); mut(x); rejected(lambda:v.validate_contract(x),name)
def test_schema(mut,name):
    x=copy.deepcopy(S); mut(x); rejected(lambda:v.validate_schema(x,C),name)
def test_provenance(mut,name):
    x=copy.deepcopy(P); mut(x); rejected(lambda:v.validate_provenance(x,C),name)

def main():
    test_contract(lambda x:x['lifecycle'].update(candidate_id='DH-CAND-016-A'),'candidate creation')
    test_contract(lambda x:x['lifecycle'].update(production_candidate=True),'candidate promotion')
    test_contract(lambda x:x['lifecycle'].update(approved=True),'approval promotion')
    test_contract(lambda x:x['authorization'].update(implementation_authorized=True),'implementation authorization')
    test_contract(lambda x:x['authorization'].update(codex_authorized=True),'Codex authorization')
    test_contract(lambda x:x['authorization'].update(image_binaries_authorized=True),'binary authorization')
    test_contract(lambda x:x['image'].update(repository_path='game/assets/drowned_harbor/study.png'),'repository binary path')
    test_contract(lambda x:x['rights'].update(public_repository_rights=True),'fabricated repository rights')
    test_contract(lambda x:x['rights'].update(derivative_production_rights=True),'fabricated derivative rights')
    test_contract(lambda x:x['generation'].update(exact_prompt='invented'),'fabricated prompt')
    test_contract(lambda x:x['authority']['chain'].__setitem__(0,'presentation owns Tide'),'Tide authority drift')
    test_contract(lambda x:x['authority'].update(presentation_never_owns=[]),'runtime ownership')
    test_contract(lambda x:x['authority'].update(one_authoritative_shared_board_master_required=False),'shared-master removal')
    test_contract(lambda x:x['frames'][4]['hook_ids'].__setitem__(0,'unknown_hook'),'hook drift')
    test_contract(lambda x:x['frames'][0].update(frame_id='DH-PRESENT-001-FR-02'),'duplicate frame')
    test_contract(lambda x:x['skip_equivalence'].update(implementation_proof_claimed=True),'implementation proof claim')
    test_contract(lambda x:x['review_requirements'].update(safe_frame_validated=True),'unsupported safe-frame claim')
    test_contract(lambda x:x['evidence_claims'].update(human_comprehension=True),'unsupported human evidence')
    test_contract(lambda x:x['governance'].update(issue_7_naming_branding_gate=False),'issue 7 removal')
    test_contract(lambda x:x['governance'].update(issue_39_human_physical_evidence_gate=False),'issue 39 removal')
    test_contract(lambda x:x['governance'].update(pr_32_excluded=False),'PR 32 incorporation')
    test_contract(lambda x:x['external_package'].update(bytes=1),'package hash/size drift')
    test_contract(lambda x:x['image'].update(sha256='0'*64),'image hash drift')
    test_schema(lambda x:x.update(additionalProperties=True),'opened schema')
    test_schema(lambda x:x['required'].remove('rights'),'missing schema field')
    test_provenance(lambda x:x['external_image']['binary_repository_paths'].append('art/exports/study.png'),'provenance binary path')
    test_provenance(lambda x:x['rights'].update(state='cleared',public_distribution_authorized=True),'provenance rights clearance')
    test_provenance(lambda x:x['hard_boundaries'].update(godot_authorized=True),'Godot authority')
    print('Validated 28 fail-closed DH-PRESENT-REG-001 mutations')
    return 0
if __name__=='__main__': raise SystemExit(main())
