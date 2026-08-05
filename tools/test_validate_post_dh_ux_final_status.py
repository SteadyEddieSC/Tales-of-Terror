#!/usr/bin/env python3
from __future__ import annotations
import copy
import importlib.util
from pathlib import Path

MODULE_PATH = Path("tools/validate_post_dh_ux_final_status.py")
spec = importlib.util.spec_from_file_location("post_ux_final_validator", MODULE_PATH)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)

def scalar_paths(value, path=()):
    if isinstance(value, dict):
        for key, child in value.items():
            yield from scalar_paths(child, path + (key,))
    elif isinstance(value, list):
        for index, child in enumerate(value):
            yield from scalar_paths(child, path + (index,))
    elif isinstance(value, (str, int, bool)) or value is None:
        yield path

def get_path(value, path):
    node = value
    for part in path:
        node = node[part]
    return node

def set_path(value, path, replacement):
    node = value
    for part in path[:-1]:
        node = node[part]
    node[path[-1]] = replacement

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

def must_fail(fn, *args):
    try:
        fn(*args)
    except module.ValidationError:
        return
    raise AssertionError("mutation unexpectedly passed")

status = module.load(module.STATUS)
addendum = module.load(module.ADDENDUM)
module.validate(False)
count = 0

for path in scalar_paths(status):
    candidate = copy.deepcopy(status)
    set_path(candidate, path, mutate_scalar(get_path(candidate, path)))
    must_fail(module.validate_status, candidate)
    count += 1

for key in list(status):
    candidate = copy.deepcopy(status)
    del candidate[key]
    must_fail(module.validate_status, candidate)
    count += 1

candidate = copy.deepcopy(status)
candidate["unexpected"] = True
must_fail(module.validate_status, candidate)
count += 1

for path in scalar_paths(addendum):
    candidate = copy.deepcopy(addendum)
    set_path(candidate, path, mutate_scalar(get_path(candidate, path)))
    must_fail(module.validate_addendum, candidate)
    count += 1

for key in list(addendum):
    candidate = copy.deepcopy(addendum)
    del candidate[key]
    must_fail(module.validate_addendum, candidate)
    count += 1

candidate = copy.deepcopy(addendum)
candidate["unexpected"] = True
must_fail(module.validate_addendum, candidate)
count += 1

print(f"Validated {count} fail-closed post-UX-final status mutations")
