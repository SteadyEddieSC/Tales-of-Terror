#!/usr/bin/env python3
from __future__ import annotations
import copy, json
from pathlib import Path
from validate_p023_alpha3_systems_replayability_contract import ValidationError, validate_contract, validate_schema, validate_status
ROOT=Path('.')
def expect(name,fn):
    try: fn()
    except (ValidationError,KeyError,TypeError): return
    raise AssertionError(f'mutation did not fail closed: {name}')
def main():
    contract=json.loads((ROOT/'docs/preproduction/drowned_harbor_alpha3_systems_replayability_contract_v1.json').read_text())
    schema=json.loads((ROOT/'docs/preproduction/drowned_harbor_alpha3_systems_replayability_contract_schema_v1.json').read_text())
    status=json.loads((ROOT/'docs/preproduction/post_prototype_status_v1.json').read_text())
    cases=[]
    def ccase(name,change):
        def run(): d=copy.deepcopy(contract); change(d); validate_contract(d)
        cases.append((name,run))
    ccase('runtime authorized',lambda d:d['authorization'].__setitem__('runtime_implementation',True))
    ccase('alpha3 issue created',lambda d:d['authorization'].__setitem__('alpha3_issue_created',True))
    ccase('alpha2 package identity drift',lambda d:d['inherited_alpha2'].__setitem__('package_digest','0'*64))
    ccase('target snapshot weakened',lambda d:d['target_versions'].__setitem__('snapshot_version',2))
    ccase('cooperative seat one removed',lambda d:d['mode_plans'][0].__setitem__('minimum_seats',2))
    ccase('hidden mode starts at two',lambda d:d['mode_plans'][1].__setitem__('minimum_seats',2))
    ccase('deferred mode activated',lambda d:d.__setitem__('deferred_modes',['rival_crews']))
    ccase('role removed',lambda d:d['role_system']['role_archetype_order'].pop())
    ccase('role required for ending',lambda d:d['role_system'].__setitem__('role_required_for_ending',True))
    ccase('hidden faction required',lambda d:d['faction_system'].__setitem__('no_hidden_faction_required_for_valid_route',False))
    ccase('mid-session cure enabled',lambda d:d['transformation_system'].__setitem__('mid_session_cure_supported',True))
    ccase('restless form removed',lambda d:d['continuation_system']['restless_forms'].pop())
    ccase('item removed',lambda d:d['content_system']['items'].pop())
    ccase('card removed',lambda d:d['content_system']['cards'].pop())
    ccase('resource removed',lambda d:d['content_system']['resources'].pop())
    ccase('hazard removed',lambda d:d['content_system']['hazards'].pop())
    ccase('encounter removed',lambda d:d['content_system']['encounters_by_stage']['high_water'].pop())
    ccase('unbounded Director',lambda d:d['director_system'].__setitem__('unbounded_generation_allowed',True))
    ccase('ending removed',lambda d:d['ending_system']['ending_ids'].pop())
    ccase('seat attribution removed',lambda d:d['ending_system'].__setitem__('every_reachable_ending_attributes_every_stable_seat',False))
    ccase('migration weakened',lambda d:d['persistence'].__setitem__('migration_policy','best_effort'))
    ccase('exactly-once ID removed',lambda d:d['persistence']['exactly_once_identities'].pop())
    ccase('privacy class removed',lambda d:d['privacy']['classes'].pop())
    ccase('Director private access',lambda d:d['privacy'].__setitem__('director_private_access',True))
    ccase('surrogate private access',lambda d:d['privacy'].__setitem__('surrogate_private_access',True))
    ccase('run matrix weakened',lambda d:d['replayability'].__setitem__('minimum_total_runs',125))
    ccase('deadlock requirement removed',lambda d:d['replayability'].__setitem__('deadlock_free_required',False))
    ccase('authoring runtime load',lambda d:d['traceability'].__setitem__('runtime_may_load_authoring_references',True))
    ccase('implementation activated',lambda d:d['implementation_issue'].__setitem__('activation_authorized',True))
    ccase('human evidence claimed',lambda d:d['evidence'].__setitem__('automation_is_human_evidence',True))
    def schema_open(): s=copy.deepcopy(schema); s['additionalProperties']=True; validate_schema(s,contract)
    cases.append(('schema opened',schema_open))
    def status_activate(): s=copy.deepcopy(status); s['recommended_next_release']['github_issue']=107; validate_status(s)
    cases.append(('status activated',status_activate))
    for name,fn in cases: expect(name,fn)
    print(f'Validated {len(cases)} P0.23 fail-closed mutations')
    return 0
if __name__=='__main__': raise SystemExit(main())
