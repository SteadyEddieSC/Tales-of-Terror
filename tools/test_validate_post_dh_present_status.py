#!/usr/bin/env python3
from __future__ import annotations

import copy
import importlib.util
import json
import shutil
import tempfile
from pathlib import Path
from typing import Callable

ROOT = Path('.')
spec = importlib.util.spec_from_file_location(
    'validator', ROOT / 'tools/validate_post_dh_present_status.py'
)
validator = importlib.util.module_from_spec(spec)
assert spec.loader
spec.loader.exec_module(validator)

STATUS_PATH = ROOT / validator.STATUS
STATUS = json.loads(STATUS_PATH.read_text(encoding='utf-8'))
Mutation = Callable[[dict], None]


def expect_rejected(name: str, mutation: Mutation) -> None:
    candidate = copy.deepcopy(STATUS)
    mutation(candidate)
    try:
        validator.validate_status(candidate)
    except (validator.ValidationError, KeyError, TypeError, IndexError):
        return
    raise AssertionError(f'mutation survived: {name}')


def main() -> int:
    cases: list[tuple[str, Mutation]] = [
        ('schema drift', lambda d: d.__setitem__('schema_version', 3)),
        ('protected main drift', lambda d: d.__setitem__('protected_main', '0' * 40)),
        ('protected main semantics drift', lambda d: d.__setitem__('protected_main_semantics', 'latest_dynamic_head')),
        ('playable release drift', lambda d: d.__setitem__('playable_release', 'v0.2.0-alpha.3')),
        ('Alpha.3 candidate drift', lambda d: d['alpha3'].__setitem__('candidate_head_sha', '0' * 40)),
        ('Alpha.3 merge drift', lambda d: d['alpha3'].__setitem__('merged_main_sha', '0' * 40)),
        ('Alpha.3 package drift', lambda d: d['alpha3'].__setitem__('package_version', 2)),
        ('Alpha.3 export opened', lambda d: d['alpha3'].__setitem__('ordinary_export_included', True)),
        ('active current issue created', lambda d: d['current_release'].update({'issue': 117, 'release_id': 'future'})),
        ('current release activated', lambda d: d['current_release'].__setitem__('activation_authorized', True)),
        ('successor issue selected', lambda d: d['recommended_next_release'].__setitem__('github_issue', 117)),
        ('successor activated', lambda d: d['recommended_next_release'].__setitem__('activation_authorized', True)),
        ('Codex required prematurely', lambda d: d['recommended_next_release'].__setitem__('codex_required', True)),
        ('UX implementation authorized', lambda d: d['pending_inputs'][0].__setitem__('implementation_authorized', True)),
        ('UX authority promoted', lambda d: d['pending_inputs'][0].__setitem__('authority', 'implementation_authority')),
        ('visual baseline merge drift', lambda d: d['visual_planning']['visual_baseline'].__setitem__('merged_main_sha', '0' * 40)),
        ('visual baseline identity drift', lambda d: d['visual_planning']['visual_baseline'].__setitem__('baseline_id', 'DH-VBL-002')),
        ('presentation merge drift', lambda d: d['visual_planning']['presentation_study'].__setitem__('merged_main_sha', '0' * 40)),
        ('presentation candidate created', lambda d: d['visual_planning']['presentation_study'].__setitem__('visual_candidate_created', True)),
        ('external binary admitted', lambda d: d['visual_planning'].__setitem__('external_binaries_in_git', True)),
        ('production art authorized', lambda d: d['visual_planning'].__setitem__('production_art_authorized', True)),
        ('runtime art authorized', lambda d: d['visual_planning'].__setitem__('runtime_art_authorized', True)),
        ('public asset release authorized', lambda d: d['visual_planning'].__setitem__('public_github_release_assets_authorized', True)),
        ('catalog opened', lambda d: d['production'].__setitem__('drowned_harbor_catalog_registered', True)),
        ('provider opened', lambda d: d['production'].__setitem__('drowned_harbor_provider_registered', True)),
        ('normal library opened', lambda d: d['production'].__setitem__('drowned_harbor_normal_library_visible', True)),
        ('ordinary export opened', lambda d: d['production'].__setitem__('drowned_harbor_ordinary_export_included', True)),
        ('ordinary play opened', lambda d: d['drowned_harbor'].__setitem__('ordinary_playable', True)),
        ('runtime implementation authorized', lambda d: d.__setitem__('runtime_implementation_authorized', True)),
        ('visual implementation authorized', lambda d: d.__setitem__('visual_implementation_authorized', True)),
        ('human evidence claimed', lambda d: d.__setitem__('human_evidence_claimed', True)),
        ('issue 7 gate removed', lambda d: d['gates'].__setitem__(0, {'issue': 7, 'purpose': 'naming', 'state': 'closed'})),
        ('issue 39 gate changed', lambda d: d['gates'].__setitem__(1, {'issue': 39, 'purpose': 'human evidence', 'state': 'completed'})),
        ('PR 32 boundary removed', lambda d: d.__setitem__('unrelated_open_pull_requests', [])),
        ('Companion Undici drift', lambda d: d['companion_dependency_security']['override_policy'].__setitem__('undici', '7.28.0')),
        ('preserved visual merge drift', lambda d: d['preserved_authorities'].__setitem__('dh_visual_baseline_merge', '0' * 40)),
        ('preserved presentation merge drift', lambda d: d['preserved_authorities'].__setitem__('dh_present_registration_merge', '0' * 40)),
    ]
    for name, mutation in cases:
        expect_rejected(name, mutation)

    with tempfile.TemporaryDirectory() as temp_dir:
        temp = Path(temp_dir)
        for path in [validator.README, validator.INDEX, validator.ROADMAP]:
            target = temp / path
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT / path, target)
        validator.validate_docs(temp)

        readme = temp / validator.README
        readme.write_text(
            readme.read_text(encoding='utf-8') + '\nCurrent active release:** post-Alpha.3 status reconciliation\n',
            encoding='utf-8',
        )
        try:
            validator.validate_docs(temp)
        except validator.ValidationError:
            pass
        else:
            raise AssertionError('stale documentation claim survived')

        readme.write_text(
            (ROOT / validator.README).read_text(encoding='utf-8').replace('UX helper', 'specialist'),
            encoding='utf-8',
        )
        index = temp / validator.INDEX
        index.write_text(index.read_text(encoding='utf-8').replace('UX helper', 'specialist'), encoding='utf-8')
        roadmap = temp / validator.ROADMAP
        roadmap.write_text(roadmap.read_text(encoding='utf-8').replace('UX helper', 'specialist'), encoding='utf-8')
        try:
            validator.validate_docs(temp)
        except validator.ValidationError:
            pass
        else:
            raise AssertionError('missing UX advisory marker survived')

    print(f'Validated {len(cases) + 2} fail-closed post-DH-PRESENT status mutations')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
