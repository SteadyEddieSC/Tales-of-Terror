#!/usr/bin/env python3
from __future__ import annotations

import copy
import importlib.util
import json
import shutil
import tempfile
from pathlib import Path
from typing import Any, Iterator

HERE = Path(__file__).resolve()
VALIDATOR_PATH = HERE.with_name('validate_drowned_harbor_clean_room_source_planning.py')
spec = importlib.util.spec_from_file_location('dh_source_plan_validator', VALIDATOR_PATH)
if spec is None or spec.loader is None:
    raise SystemExit('Unable to load validator')
validator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(validator)

def object_paths(value: Any, path: tuple[Any, ...] = ()) -> Iterator[tuple[Any, ...]]:
    if isinstance(value, dict):
        yield path
        for key, child in value.items():
            yield from object_paths(child, path + (key,))
    elif isinstance(value, list):
        for index, child in enumerate(value):
            yield from object_paths(child, path + (index,))

def get_path(root: Any, path: tuple[Any, ...]) -> Any:
    value = root
    for part in path:
        value = value[part]
    return value

def write_json(path: Path, data: Any) -> None:
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')

def expect_failure(root: Path) -> None:
    old = validator.ROOT
    validator.ROOT = root
    try:
        try:
            validator.validate(check_git=False)
        except Exception:
            return
        raise AssertionError('mutation unexpectedly passed')
    finally:
        validator.ROOT = old

def main() -> int:
    repo_root = HERE.parents[1]
    with tempfile.TemporaryDirectory(prefix='dh-source-plan-mutations-') as raw:
        root = Path(raw)
        for rel in validator.ALLOWED:
            source = repo_root / rel
            target = root / rel
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, target)
        old = validator.ROOT
        validator.ROOT = root
        try:
            validator.validate(check_git=False)
        finally:
            validator.ROOT = old

        count = 0
        machine_path = root / validator.MACHINE
        machine = json.loads(machine_path.read_text(encoding='utf-8'))
        for path in list(object_paths(machine)):
            target = get_path(machine, path)
            for key in list(target):
                mutated = copy.deepcopy(machine)
                del get_path(mutated, path)[key]
                write_json(machine_path, mutated)
                expect_failure(root)
                count += 1
            mutated = copy.deepcopy(machine)
            get_path(mutated, path)['unexpected_field'] = True
            write_json(machine_path, mutated)
            expect_failure(root)
            count += 1
        write_json(machine_path, machine)

        for control_id in machine['control_traceability']:
            for field in ['owner','legal_intent_source','availability','information_class','interaction_category','source_responsibility']:
                mutated = copy.deepcopy(machine)
                mutated['control_traceability'][control_id][field] = ''
                write_json(machine_path, mutated)
                expect_failure(root)
                count += 1
            mutated = copy.deepcopy(machine)
            mutated['control_traceability'][control_id]['future_consumer'] = 'implemented_consumer'
            write_json(machine_path, mutated)
            expect_failure(root)
            count += 1
        write_json(machine_path, machine)

        for evidence_id in machine['future_evidence']:
            mutated = copy.deepcopy(machine)
            mutated['future_evidence'][evidence_id] = 'passed'
            write_json(machine_path, mutated)
            expect_failure(root)
            count += 1
        write_json(machine_path, machine)

        schema_path = root / validator.SCHEMA
        schema = json.loads(schema_path.read_text(encoding='utf-8'))
        mutated_schema = copy.deepcopy(schema)
        mutated_schema['additionalProperties'] = True
        write_json(schema_path, mutated_schema)
        expect_failure(root)
        count += 1
        write_json(schema_path, schema)

        prov_path = root / validator.PROVENANCE
        provenance = json.loads(prov_path.read_text(encoding='utf-8'))
        for path in list(object_paths(provenance)):
            target = get_path(provenance, path)
            for key in list(target):
                mutated = copy.deepcopy(provenance)
                del get_path(mutated, path)[key]
                write_json(prov_path, mutated)
                expect_failure(root)
                count += 1
            mutated = copy.deepcopy(provenance)
            get_path(mutated, path)['unexpected_field'] = True
            write_json(prov_path, mutated)
            expect_failure(root)
            count += 1
        write_json(prov_path, provenance)

        for rel in [validator.WORKFLOW, *validator.DOCS]:
            path = root / rel
            original = path.read_text(encoding='utf-8')
            path.write_text(original + '\nsource creation is authorized\n', encoding='utf-8')
            expect_failure(root)
            count += 1
            path.write_text(original, encoding='utf-8')

        print(f'Validated {count} fail-closed DH-SOURCE-PLAN-001 mutations')
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
