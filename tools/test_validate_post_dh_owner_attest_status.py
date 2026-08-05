#!/usr/bin/env python3
from __future__ import annotations
import copy, importlib.util, json
from pathlib import Path
ROOT=Path('.')
spec=importlib.util.spec_from_file_location('validator',ROOT/'tools/validate_post_dh_owner_attest_status.py')
v=importlib.util.module_from_spec(spec); assert spec.loader; spec.loader.exec_module(v)
STATUS=json.loads((ROOT/v.STATUS).read_text(encoding='utf-8'))
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
    elif isinstance(old,str): y[k]=old+'_drift'
    elif old is None: y[k]='drift'
    else: raise TypeError(path)
def rejected(d):
    try: v.validate_status(d)
    except (v.ValidationError,KeyError,TypeError,IndexError): return True
    return False
def main():
    count=0
    for path in scalar_paths(STATUS):
        d=copy.deepcopy(STATUS); mutate(d,path); assert rejected(d),f'scalar mutation survived {path}'; count+=1
    for key in list(STATUS):
        d=copy.deepcopy(STATUS); d.pop(key); assert rejected(d),f'top-level removal survived {key}'; count+=1
    d=copy.deepcopy(STATUS); d['unexpected']=True; assert rejected(d); count+=1
    target=v.DOCS[1]; original=(ROOT/target).read_text(encoding='utf-8')
    try:
        (ROOT/target).write_text(original+'\nClean-room source planning is authorized.\n',encoding='utf-8')
        try: v.validate_docs()
        except v.ValidationError: count+=1
        else: raise AssertionError('unsupported planning claim survived')
    finally: (ROOT/target).write_text(original,encoding='utf-8')
    try:
        (ROOT/target).write_text(original.replace('The owner-attestation prerequisite is complete to the best of firsthand knowledge','Project Owner attestation and generation-session reconstruction remain required'),encoding='utf-8')
        try: v.validate_docs()
        except v.ValidationError: count+=1
        else: raise AssertionError('stale attestation-pending claim survived')
    finally: (ROOT/target).write_text(original,encoding='utf-8')
    print(f'Validated {count} fail-closed post-attestation status mutations')
    return 0
if __name__=='__main__': raise SystemExit(main())
