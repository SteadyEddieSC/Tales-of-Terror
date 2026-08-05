#!/usr/bin/env python3
from __future__ import annotations
import copy, importlib.util, json
from pathlib import Path
ROOT=Path(".")
spec=importlib.util.spec_from_file_location("validator",ROOT/"tools/validate_drowned_harbor_owner_attestation.py")
v=importlib.util.module_from_spec(spec); assert spec.loader; spec.loader.exec_module(v)
DATA=json.loads((ROOT/v.REGISTER).read_text(encoding="utf-8"))
def scalar_paths(x,p=()):
    if isinstance(x,dict):
        for k,z in x.items(): yield from scalar_paths(z,p+(k,))
    elif isinstance(x,list):
        for i,z in enumerate(x): yield from scalar_paths(z,p+(i,))
    else: yield p
def mutate(x,path):
    y=x
    for k in path[:-1]: y=y[k]
    k=path[-1]; old=y[k]
    if isinstance(old,bool): y[k]=not old
    elif isinstance(old,int): y[k]=old+1
    elif isinstance(old,str): y[k]=old+"_drift"
    elif old is None: y[k]="drift"
    else: raise TypeError(path)
def rejected(d):
    try: v.validate_record(d)
    except (v.ValidationError,KeyError,TypeError,IndexError): return True
    return False
def main():
    count=0
    for path in scalar_paths(DATA):
        d=copy.deepcopy(DATA); mutate(d,path); assert rejected(d),f"scalar mutation survived {path}"; count+=1
    for key in list(DATA):
        d=copy.deepcopy(DATA); d.pop(key); assert rejected(d),f"top-level removal survived {key}"; count+=1
    d=copy.deepcopy(DATA); d["unexpected"]=True; assert rejected(d); count+=1
    schema=json.loads((ROOT/v.SCHEMA).read_text(encoding="utf-8")); schema["additionalProperties"]=True
    try: v.validate_schema(schema,DATA)
    except v.ValidationError: count+=1
    else: raise AssertionError("open schema survived")
    prov=json.loads((ROOT/v.PROVENANCE).read_text(encoding="utf-8")); prov["eligibility_state"]="source_creation_authorized"
    try: v.validate_provenance(prov)
    except v.ValidationError: count+=1
    else: raise AssertionError("provenance promotion survived")
    target=v.DOCS[1]
    original=target.read_text(encoding="utf-8")
    try:
        target.write_text(original+"\nSource creation is authorized.\n",encoding="utf-8")
        try: v.validate_docs()
        except v.ValidationError: count+=1
        else: raise AssertionError("unsupported doc claim survived")
    finally: target.write_text(original,encoding="utf-8")
    print(f"Validated {count} fail-closed owner-attestation mutations")
    return 0
if __name__=="__main__": raise SystemExit(main())
