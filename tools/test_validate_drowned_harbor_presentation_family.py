#!/usr/bin/env python3
from __future__ import annotations
import copy, importlib.util, json, shutil, tempfile
from pathlib import Path
from typing import Callable
ROOT=Path('.')
spec=importlib.util.spec_from_file_location('v',ROOT/'tools/validate_drowned_harbor_presentation_family.py'); v=importlib.util.module_from_spec(spec); assert spec.loader; spec.loader.exec_module(v)
contract=json.loads((ROOT/v.CONTRACT).read_text(encoding='utf-8')); schema=json.loads((ROOT/v.SCHEMA).read_text(encoding='utf-8')); provenance=json.loads((ROOT/v.PROVENANCE).read_text(encoding='utf-8'))
Mutation=Callable[[dict],None]
def expect(name:str,fn:Mutation):
    c=copy.deepcopy(contract); fn(c)
    try:v.validate_contract(c)
    except (v.ValidationError,KeyError,TypeError,IndexError):return
    raise AssertionError(f'mutation survived: {name}')
cases=[
('release drift',lambda d:d['identity'].__setitem__('release_id','DH-PRESENT-REG-003')),
('family drift',lambda d:d['identity'].__setitem__('family_id','DH-PRESENT-FAMILY-002')),
('base drift',lambda d:d['release'].__setitem__('protected_main_base','0'*40)),
('separate release split',lambda d:d['release'].__setitem__('separate_releases_required',True)),
('implementation authorized',lambda d:d['authorization'].__setitem__('implementation_authorized',True)),
('UX implementation authorized',lambda d:d['authorization'].__setitem__('ux_implementation_authorized',True)),
('Codex authorized',lambda d:d['authorization'].__setitem__('codex_authorized',True)),
('candidate creation',lambda d:d['authorization'].__setitem__('candidate_creation_authorized',True)),
('conversion ready auth',lambda d:d['authorization'].__setitem__('conversion_ready',True)),
('package hash drift',lambda d:d['external_package'].__setitem__('sha256','0'*64)),
('manifest hash drift',lambda d:d['external_package']['manifest'].__setitem__('sha256','0'*64)),
('payload removed',lambda d:d['external_package']['payloads'].pop()),
('study removed',lambda d:d['studies'].pop()),
('study disposition promoted',lambda d:d['studies'][0].__setitem__('review_disposition','approved')),
('image repository path',lambda d:d['studies'][0]['image'].__setitem__('repository_path','game/assets/x.png')),
('960 proof fabricated',lambda d:d['studies'][1]['image'].__setitem__('logical_960x540_validation',True)),
('generation prompt fabricated',lambda d:d['studies'][0]['generation'].__setitem__('exact_prompt','invented')),
('frame removed',lambda d:d['studies'][0]['frames'].pop()),
('candidate promoted',lambda d:d['studies'][1]['lifecycle'].__setitem__('production_candidate',True)),
('Last Light owner changed',lambda d:d['studies'][0].__setitem__('authority_owner','presentation')),
('preview qualification removed',lambda d:d['studies'][0].__setitem__('special_qualification','preview allowed')),
('private attribution owner changed',lambda d:d['studies'][1]['authority_owners'].__setitem__('private_attribution','presentation')),
('family conversion ready',lambda d:d['presentation_family'].__setitem__('conversion_readiness','ready')),
('family implementation auth',lambda d:d['presentation_family'].__setitem__('implementation_authorized',True)),
('UX authority promoted',lambda d:d['presentation_family']['ux_helper'].__setitem__('authority','implementation_authority')),
('RulesSession authority removed',lambda d:d['authority']['rules_session_owns'].remove('ending resolution')),
('presentation owns ending',lambda d:d['authority']['presentation_never_owns'].remove('ending resolution')),
('private output allowed',lambda d:d['privacy']['shared_output_must_exclude'].remove('private objectives')),
('public rail unsafe',lambda d:d['privacy'].__setitem__('public_outcome_rail_private_safe_required',False)),
('replay reducer auth',lambda d:d['presentation_replay'].__setitem__('rerun_reducers_authorized',True)),
('replay RNG auth',lambda d:d['presentation_replay'].__setitem__('rng_mutation_authorized',True)),
('readability evidence fabricated',lambda d:d['review_requirements'].__setitem__('television_readability_validated',True)),
('eight seat evidence fabricated',lambda d:d['review_requirements'].__setitem__('eight_seat_density_validated',True)),
('seat examples authoritative',lambda d:d['generated_content'].__setitem__('visible_four_seat_and_four_commitment_examples_authoritative',True)),
('checkmarks evidence',lambda d:d['generated_content'].__setitem__('visible_readability_checkmarks_are_evidence',True)),
('rights fabricated',lambda d:d['rights'].__setitem__('derivative_production_rights','cleared')),
('issue 7 removed',lambda d:d['governance'].__setitem__('issue_7_naming_branding_gate',False)),
('issue 39 removed',lambda d:d['governance'].__setitem__('issue_39_human_physical_evidence_gate',False)),
('PR32 included',lambda d:d['governance'].__setitem__('pr_32_excluded',False)),
('shipping claimed',lambda d:d['evidence_claims'].__setitem__('shipping_authorization',True)),
]
for name,fn in cases:expect(name,fn)
sc=copy.deepcopy(schema); sc['additionalProperties']=True
try:v.validate_schema(sc,contract)
except v.ValidationError:pass
else:raise AssertionError('open schema survived')
pc=copy.deepcopy(provenance); pc['rights']['production_use_authorized']=True
try:v.validate_provenance(pc,contract)
except v.ValidationError:pass
else:raise AssertionError('provenance rights mutation survived')
with tempfile.TemporaryDirectory() as td:
    root=Path(td)
    for p in v.DOCS:
        t=root/p; t.parent.mkdir(parents=True,exist_ok=True); shutil.copy2(ROOT/p,t)
    old=v.DOCS
    try:
        v.DOCS=[root/p for p in old]; v.validate_markdown()
        p=v.DOCS[0]; p.write_text(p.read_text(encoding='utf-8')+'\nConversion readiness: ready\n',encoding='utf-8')
        try:v.validate_markdown()
        except v.ValidationError:pass
        else:raise AssertionError('false readiness Markdown survived')
    finally:v.DOCS=old
print(f'Validated {len(cases)+3} DH-PRESENT-REG-002 fail-closed mutations')
