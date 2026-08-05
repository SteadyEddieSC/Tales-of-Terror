#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import subprocess
from pathlib import Path
from typing import Any

ROOT = Path('.')
BASE = '671b8f2512be80c0c5f2cec701c29445159620e2'
BRANCH = 'docs/post-dh-present-status-reconciliation'
ALLOWED = {
    'README.md',
    '.github/workflows/p021-production-architecture.yml',
    '.github/workflows/p022-alpha2-graybox-contract.yml',
    '.github/workflows/p023-alpha3-systems-replayability-contract.yml',
    '.github/workflows/post-prototype-reconciliation.yml',
    'docs/preproduction/README.md',
    'docs/preproduction/post_prototype_status_v1.json',
    'docs/roadmap/Post_P0.19_Production_Candidate_Roadmap.md',
    'tools/validate_post_dh_present_status.py',
    'tools/test_validate_post_dh_present_status.py',
}
STATUS = Path('docs/preproduction/post_prototype_status_v1.json')
README = Path('README.md')
INDEX = Path('docs/preproduction/README.md')
ROADMAP = Path('docs/roadmap/Post_P0.19_Production_Candidate_Roadmap.md')

ALPHA3_CANDIDATE = '08fdbe8b52a66fc44a98bdd27878554c5478aef1'
ALPHA3_MERGE = 'cad70c5c8f0db1de7d557aff242cc8fe3610361b'
VISUAL_BASELINE_MERGE = '0cea1ac62733fda56d09cb0de8a789efc509308a'
PRESENTATION_MERGE = BASE


class ValidationError(ValueError):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValidationError(message)


def load(root: Path, path: Path) -> dict[str, Any]:
    value = json.loads((root / path).read_text(encoding='utf-8'))
    require(isinstance(value, dict), f'object required: {path}')
    return value


def validate_status(status: dict[str, Any]) -> None:
    require(status.get('status_kind') == 'post_prototype_project_status', 'status kind drift')
    require(status.get('schema_version') == 4, 'status schema drift')
    require(status.get('as_of_date') == '2026-08-05', 'status date drift')
    require(status.get('protected_main') == BASE, 'protected-main drift')
    require(
        status.get('protected_main_semantics') == 'exact_reconciliation_starting_baseline',
        'protected-main semantics drift',
    )
    require(status.get('playable_release') == 'v0.1.9', 'normal playable release drift')
    require(status.get('runtime_implementation_authorized') is False, 'runtime authorized')
    require(status.get('visual_implementation_authorized') is False, 'visual implementation authorized')
    require(status.get('human_evidence_claimed') is False, 'human evidence claimed')
    require(status.get('unrelated_open_pull_requests') == [32], 'PR #32 boundary drift')

    require(
        status.get('alpha3')
        == {
            'candidate_head_sha': ALPHA3_CANDIDATE,
            'developer_only': True,
            'issue': 108,
            'merged_main_sha': ALPHA3_MERGE,
            'ordinary_export_included': False,
            'package_version': 3,
            'provider_version': 3,
            'pull_request': 109,
            'release_id': 'v0.2.0-alpha.3',
            'scenario_version': 3,
            'snapshot_version': 3,
            'state': 'completed_developer_only',
        },
        'Alpha.3 identity drift',
    )
    require(
        status.get('current_release')
        == {
            'activation_authorized': False,
            'issue': None,
            'release_id': None,
            'runtime_authority_created': False,
            'state': 'none_active_after_reconciliation',
            'type': None,
        },
        'current release must remain empty and unauthorized',
    )
    require(
        status.get('recommended_next_release')
        == {
            'activation_authorized': False,
            'codex_required': False,
            'github_issue': None,
            'release_id': None,
            'state': 'waiting_on_ux_handoff_and_explicit_activation',
            'title': None,
        },
        'successor release selected or authorized',
    )
    require(
        status.get('pending_inputs')
        == [
            {
                'authority': 'advisory_until_release_coordination_review',
                'input_id': 'ux_helper_handoff',
                'implementation_authorized': False,
                'state': 'pending',
            }
        ],
        'UX helper advisory boundary drift',
    )
    require(
        status.get('drowned_harbor')
        == {
            'ordinary_playable': False,
            'status': 'developer_only_alpha3_with_completed_metadata_only_visual_planning_export_excluded',
        },
        'Drowned Harbor boundary drift',
    )
    require(
        status.get('production')
        == {
            'default_tale_id': 'lantern_house_vertical_slice',
            'drowned_harbor_catalog_registered': False,
            'drowned_harbor_normal_library_visible': False,
            'drowned_harbor_ordinary_export_included': False,
            'drowned_harbor_provider_registered': False,
            'tale_count': 1,
        },
        'production/catalog/provider/export boundary drift',
    )
    require(
        status.get('companion_dependency_security')
        == {
            'audit_threshold': 'moderate',
            'miniflare': '4.20260722.0',
            'override_policy': {'postcss': '8.5.23', 'undici': '7.29.0'},
            'sharp': '0.35.2',
            'state': 'remediated_and_exact_head_validated',
            'workers_types': '5.20260722.1',
            'wrangler': '4.114.0',
        },
        'Companion dependency authority drift',
    )

    gates = {row.get('issue'): row.get('state') for row in status.get('gates', [])}
    require(gates == {7: 'open', 39: 'deferred_open'}, 'issue-gate inventory drift')

    visual = status.get('visual_planning', {})
    require(
        visual.get('external_binaries_in_git') is False
        and visual.get('production_art_authorized') is False
        and visual.get('public_github_release_assets_authorized') is False
        and visual.get('runtime_art_authorized') is False,
        'visual binary/art/public-release boundary opened',
    )
    require(
        visual.get('visual_baseline')
        == {
            'baseline_id': 'DH-VBL-001',
            'candidate_batch_id': 'DH-CB-002',
            'conversion_brief_id': 'DH-VCB-001',
            'issue': 110,
            'merged_main_sha': VISUAL_BASELINE_MERGE,
            'pull_request': 113,
            'state': 'completed_metadata_only',
        },
        'visual baseline identity drift',
    )
    require(
        visual.get('presentation_study')
        == {
            'issue': 114,
            'merged_main_sha': PRESENTATION_MERGE,
            'pull_request': 115,
            'release_id': 'DH-PRESENT-REG-001',
            'state': 'completed_metadata_only',
            'study_id': 'DH-PRESENT-001',
            'visual_candidate_created': False,
        },
        'presentation study identity or candidate boundary drift',
    )

    preserved = status.get('preserved_authorities', {})
    require(preserved.get('alpha3_candidate_head') == ALPHA3_CANDIDATE, 'preserved Alpha.3 candidate drift')
    require(preserved.get('alpha3_merge') == ALPHA3_MERGE, 'preserved Alpha.3 merge drift')
    require(preserved.get('dh_visual_baseline_merge') == VISUAL_BASELINE_MERGE, 'preserved visual baseline drift')
    require(preserved.get('dh_present_registration_merge') == PRESENTATION_MERGE, 'preserved presentation merge drift')


def validate_docs(root: Path) -> None:
    readme = (root / README).read_text(encoding='utf-8')
    index = (root / INDEX).read_text(encoding='utf-8')
    roadmap = (root / ROADMAP).read_text(encoding='utf-8')
    joined = '\n'.join([readme, index, roadmap])
    lowered = joined.lower()

    for phrase in [
        BASE,
        'issue #108 / pr #109',
        'issue #110 / pr #113',
        'issue #114 / pr #115',
        'issue #116',
        'dh-vbl-001',
        'dh-cb-002',
        'dh-vcb-001',
        'dh-present-reg-001',
        'dh-present-001',
        'ux helper',
        'unselected',
        'lantern house remains the sole normal/default tale',
        'drowned harbor remains developer-only',
        'excluded from ordinary exports',
        'automation is not human evidence',
        'issue #39 remains the human-evidence authority',
        'issue #7 remains the naming gate',
        'pr #32 remains unrelated',
    ]:
        require(phrase.lower() in lowered, f'current documentation missing: {phrase}')

    for stale in [
        'current active release:** post-alpha.3 status reconciliation',
        'next planned release:** dh-vbl-001',
        'issue #111 is the sole active release',
        'issue #110 remains planning-only and blocked',
        'post-alpha.3 status reconciliation:** active',
        'issue #110 is the next planning release but remains blocked',
    ]:
        require(stale not in lowered, f'stale current-state claim: {stale}')

    for claim in [
        'human playtesting passed',
        'television readability validated',
        'physical-controller validation passed',
        'accessibility certified',
        'privacy certified',
        'security certified',
        'production ready',
        'shipping authorized',
        'public release authorized',
    ]:
        require(claim not in lowered, f'unsupported claim: {claim}')


def effective_branch(root: Path) -> str:
    return (
        os.environ.get('GITHUB_HEAD_REF')
        or os.environ.get('GITHUB_REF_NAME')
        or subprocess.check_output(['git', 'branch', '--show-current'], cwd=root, text=True).strip()
    )


def validate_git_boundary(root: Path) -> None:
    branch = effective_branch(root)
    if branch != BRANCH:
        return
    merge_base = subprocess.check_output(['git', 'merge-base', 'HEAD', BASE], cwd=root, text=True).strip()
    require(merge_base == BASE, f'reconciliation baseline changed: {merge_base}')
    actual = {
        line
        for line in subprocess.check_output(
            ['git', 'diff', '--name-only', f'{BASE}...HEAD'], cwd=root, text=True
        ).splitlines()
        if line
    }
    require(
        actual == ALLOWED,
        f'exact path mismatch missing={sorted(ALLOWED - actual)} unexpected={sorted(actual - ALLOWED)}',
    )
    for path in actual:
        require(not path.startswith(('game/', 'art/source/', 'game/assets/')), f'prohibited path changed: {path}')
        require(Path(path).suffix.lower() not in {'.png', '.webp', '.svg', '.glb', '.zip', '.kra', '.psd', '.blend', '.tscn', '.tres'}, f'prohibited binary/runtime extension changed: {path}')


def validate(root: Path = ROOT, *, check_git: bool = True) -> None:
    validate_status(load(root, STATUS))
    validate_docs(root)
    if check_git:
        validate_git_boundary(root)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--skip-git-boundary', action='store_true')
    args = parser.parse_args()
    try:
        validate(check_git=not args.skip_git_boundary)
    except (ValidationError, KeyError, TypeError, OSError, json.JSONDecodeError, subprocess.CalledProcessError) as exc:
        print(f'Post-DH-PRESENT status validation failed: {exc}')
        return 1
    print('Validated post-DH-PRESENT current status and succession boundary')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
