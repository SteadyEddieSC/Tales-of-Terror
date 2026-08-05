#!/usr/bin/env python3
from __future__ import annotations
import copy
import importlib.util
import json
from pathlib import Path

MODULE_PATH = Path("tools/validate_drowned_harbor_ux_final_addendum.py")
spec = importlib.util.spec_from_file_location("ux_addendum_validator", MODULE_PATH)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)

def mutate_scalar(value):
    if isinstance(value, bool):
        return not value
    if isinstance(value, int):
        return value + 1
    if isinstance(value, str):
        return value + "__MUTATED"
    if value is None:
        return "MUTATED"
    raise TypeError(type(value))

def scalar_paths(value, path=()):
    if isinstance(value, dict):
        for key, child in value.items():
            yield from scalar_paths(child, path + (key,))
    elif isinstance(value, list):
        for index, child in enumerate(value):
            yield from scalar_paths(child, path + (index,))
    elif isinstance(value, (str, int, bool)) or value is None:
        yield path

def set_path(value, path, replacement):
    node = value
    for part in path[:-1]:
        node = node[part]
    node[path[-1]] = replacement

def get_path(value, path):
    node = value
    for part in path:
        node = node[part]
    return node

def must_fail(fn, *args):
    try:
        fn(*args)
    except module.ValidationError:
        return
    raise AssertionError("mutation unexpectedly passed")

record = module.load(module.RECORD)
schema = module.load(module.SCHEMA)
provenance = module.load(module.PROVENANCE)

module.validate(False)
count = 0

for path in scalar_paths(record):
    candidate = copy.deepcopy(record)
    set_path(candidate, path, mutate_scalar(get_path(candidate, path)))
    must_fail(module.validate_record, candidate)
    count += 1

for key in list(record):
    candidate = copy.deepcopy(record)
    del candidate[key]
    must_fail(module.validate_record, candidate)
    count += 1

candidate = copy.deepcopy(record)
candidate["unexpected"] = True
must_fail(module.validate_record, candidate)
count += 1

for path in scalar_paths(provenance):
    candidate = copy.deepcopy(provenance)
    set_path(candidate, path, mutate_scalar(get_path(candidate, path)))
    must_fail(module.validate_provenance, candidate)
    count += 1

for key in list(provenance):
    candidate = copy.deepcopy(provenance)
    del candidate[key]
    must_fail(module.validate_provenance, candidate)
    count += 1

for mutation in [
    {**schema, "type": "array"},
    {**schema, "additionalProperties": True},
    {k:v for k,v in schema.items() if k != "const"},
    {**schema, "const": {**record, "record_version": 3}},
]:
    must_fail(module.validate_schema, mutation, record)
    count += 1

print(f"Validated {count} fail-closed UX addendum mutations")
