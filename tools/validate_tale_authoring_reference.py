#!/usr/bin/env python3
"""Validate design-only Tale authoring references without network access."""
from __future__ import annotations

import argparse, hashlib, json, re, sys
from dataclasses import dataclass
from pathlib import Path, PurePosixPath
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_REFERENCE = ROOT / "docs/tales/drowned_harbor/authoring/drowned_harbor_authoring_reference_v1.json"
TRACEABILITY_PATH = ROOT / "docs/preproduction/drowned_harbor_cross_media_traceability_v1.json"
SID = re.compile(r"^[a-z][a-z0-9_]*$")
TID = re.compile(r"^DH-XM-[0-9]{3}$")
WIN = re.compile(r"^[A-Za-z]:[\\/]")
URL = re.compile(r"^(?:https?|wss?)://", re.I)
SECRET = re.compile(r"(?:api[_-]?key|authorization|credential|password|private[_-]?key|room[_-]?secret|token)$", re.I)
GENERATED = {".evidence", ".git", ".godot", "builds", "dist", "node_modules", "output", "test-results"}
EXEC = {".gd", ".cs", ".dll", ".exe", ".js", ".py", ".sh", ".ps1"}
TOP = {"authoring_kind","schema_version","tale_id","reference_version","display_name","production_status","runtime_integration_authorized","production_catalog_authorized","source_authorities","compatibility","privacy_classes","stage_graph","signature_transformations","content_manifests","media_sources","fallbacks","validation_obligations","open_decisions","compilation_boundary","identity_policy"}
MKEYS = {"manifest_kind","schema_version","tale_id","manifest_id","production_status","groups"}
GKEYS = {"kind","status","privacy","stages","tags","source_path","source_anchor","traceability_concepts","ids","note"}
KINDS = {"stage","tide_state","space","region","mode","role","faction","form","resource","item","card","hazard","encounter","ending"}
STATUS = {"draft","preproduction_ready","review_required","deferred"}
PRIVACY = {"public","controlled_reveal_private","seat_private","faction_private"}
EXPECTED_PRIVACY = ["controlled_reveal_private","faction_private","public","seat_private"]
TAGS = {"active_continuation","authored_recovery_required","controlled_reveal_required","deterministic_consequence","explicit_outcome_attribution","generic_alternative_required","legal_choices_required","mechanical_truth_required","optional_hidden_state","public_warning_required","stable_seat_continuation","stateful_condition","transformation_preserves_agency","warning_response_recovery"}
FALLBACKS = {"cooperative_mode","no_phone","optional_companion_unavailable","voice_unavailable","music_unavailable","noncritical_media_unavailable","invalid_action","defeat_continuation","unsupported_optional_feature"}
MEDIA = {"dialogue_catalogs","visual_manifests","audio_manifests","music_manifests","voice_manifests","accessibility_manifests","traceability_path"}

@dataclass(frozen=True, order=True)
class Diagnostic:
    code: str
    path: str
    message: str
    def as_dict(self) -> dict[str,str]: return {"code":self.code,"path":self.path,"message":self.message}

def add(ds:list[Diagnostic], code:str, path:str, msg:str)->None: ds.append(Diagnostic(code,path,msg))
def sid(v:Any)->bool: return isinstance(v,str) and bool(SID.fullmatch(v))
def canonical_bytes(v:Any)->bytes: return json.dumps(v,ensure_ascii=True,separators=(",",":"),sort_keys=True).encode()
def authoring_digest(v:Any)->str: return hashlib.sha256(canonical_bytes(v)).hexdigest()

def read_json(path:Path, ds:list[Diagnostic], logical:str)->dict[str,Any]|None:
    try: v=json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError: add(ds,"unresolved_reference",logical,f"file does not exist: {path}"); return None
    except (OSError,json.JSONDecodeError) as e: add(ds,"malformed_json",logical,f"unreadable JSON: {e}"); return None
    if not isinstance(v,dict): add(ds,"unsupported_schema",logical,"JSON root must be an object"); return None
    return v

def exact(v:Any, keys:set[str], path:str, ds:list[Diagnostic])->bool:
    if not isinstance(v,dict): add(ds,"missing_required_field",path,"expected object"); return False
    for k in sorted(keys-set(v)): add(ds,"missing_required_field",f"{path}/{k}","required field is missing")
    for k in sorted(set(v)-keys): add(ds,"unsupported_schema",f"{path}/{k}","unknown field is rejected")
    return set(v)==keys

def resolve(v:Any)->Path|None:
    if not isinstance(v,str) or not v or v.startswith("res://") or WIN.match(v) or v.startswith(("/","~")): return None
    p=PurePosixPath(v.replace("\\","/"))
    return None if ".." in p.parts else ROOT/p

def repo_file(v:Any, path:str, ds:list[Diagnostic])->Path|None:
    p=resolve(v)
    if p is None: add(ds,"unsafe_path",path,"must be a repository-relative non-runtime path"); return None
    if set(x.lower() for x in p.relative_to(ROOT).parts)&GENERATED: add(ds,"generated_reference",path,"generated/cache/dependency/build/evidence path is prohibited")
    if p.suffix.lower() in EXEC: add(ds,"executable_reference",path,"executable content is prohibited")
    if not p.is_file(): add(ds,"unresolved_reference",path,f"file does not exist: {v}"); return None
    return p

def safety(v:Any,path:str,ds:list[Diagnostic])->None:
    if isinstance(v,dict):
        for k,x in v.items():
            if SECRET.search(str(k)): add(ds,"secret",f"{path}/{k}","secret-bearing fields are prohibited")
            safety(x,f"{path}/{k}",ds)
    elif isinstance(v,list):
        for i,x in enumerate(v): safety(x,f"{path}/{i}",ds)
    elif isinstance(v,str):
        if URL.match(v): add(ds,"network_url",path,"network URLs are prohibited")
        if WIN.match(v) or v.startswith(("/home/","/Users/","~")): add(ds,"unsafe_path",path,"absolute/private paths are prohibited")

def sorted_ids(v:Any,path:str,ds:list[Diagnostic])->list[str]:
    if not isinstance(v,list) or not v: add(ds,"missing_required_field",path,"non-empty ID array required"); return []
    out=[x for x in v if isinstance(x,str)]
    if len(out)!=len(v) or any(not sid(x) for x in out): add(ds,"unstable_identity",path,"stable lowercase IDs required")
    if len(out)!=len(set(out)): add(ds,"duplicate_id",path,"IDs must be unique")
    if out!=sorted(out): add(ds,"unstable_ordering",path,"IDs must be sorted")
    return out

def trace_ids(ds:list[Diagnostic])->set[str]:
    v=read_json(TRACEABILITY_PATH,ds,"/media_sources/traceability_path")
    if not v or not isinstance(v.get("entries"),list): return set()
    return {x.get("concept_id") for x in v["entries"] if isinstance(x,dict) and isinstance(x.get("concept_id"),str)}

def validate_group(g:Any,path:str,stages:set[str],traces:set[str],ds:list[Diagnostic])->tuple[str|None,list[str]]:
    if not exact(g,GKEYS,path,ds): return None,[]
    kind,status,privacy=g["kind"],g["status"],g["privacy"]
    if kind not in KINDS: add(ds,"unsupported_kind",f"{path}/kind","unsupported kind")
    if status not in STATUS: add(ds,"unsupported_status",f"{path}/status","unsupported status")
    if privacy not in PRIVACY: add(ds,"invalid_privacy",f"{path}/privacy","unsupported privacy")
    ss=g["stages"]
    if not isinstance(ss,list) or any(not sid(x) for x in ss): add(ds,"unstable_identity",f"{path}/stages","stable stage IDs required"); ss=[]
    if len(ss)!=len(set(ss)): add(ds,"duplicate_id",f"{path}/stages","stage IDs must be unique")
    for x in ss:
        if x not in stages: add(ds,"unresolved_stage",f"{path}/stages",f"unknown stage '{x}'")
    tags=g["tags"]
    if not isinstance(tags,list) or any(x not in TAGS for x in tags): add(ds,"unsupported_tag",f"{path}/tags","unsupported tag"); tags=[]
    if tags!=sorted(set(tags)): add(ds,"unstable_ordering",f"{path}/tags","tags must be sorted and unique")
    src=repo_file(g["source_path"],f"{path}/source_path",ds)
    anchor=g["source_anchor"]
    if not isinstance(anchor,str) or len(anchor.strip())<3: add(ds,"missing_required_field",f"{path}/source_anchor","source anchor required")
    elif src:
        try:
            if anchor not in src.read_text(encoding="utf-8"): add(ds,"unresolved_anchor",f"{path}/source_anchor","anchor not found in source")
        except OSError: pass
    concepts=g["traceability_concepts"]
    if not isinstance(concepts,list) or any(not isinstance(x,str) or not TID.fullmatch(x) for x in concepts): add(ds,"unstable_identity",f"{path}/traceability_concepts","DH-XM-NNN IDs required"); concepts=[]
    if concepts!=sorted(set(concepts)): add(ds,"unstable_ordering",f"{path}/traceability_concepts","concept IDs must be sorted and unique")
    for x in concepts:
        if x not in traces: add(ds,"unresolved_traceability",f"{path}/traceability_concepts",f"unknown concept '{x}'")
    ids=sorted_ids(g["ids"],f"{path}/ids",ds)
    if not isinstance(g["note"],str) or len(g["note"].strip())<10: add(ds,"missing_required_field",f"{path}/note","note is too short")
    ts=set(tags)
    if kind=="hazard" and not {"public_warning_required","warning_response_recovery","deterministic_consequence"}<=ts: add(ds,"missing_semantic_obligation",path,"hazard warning/response/recovery/determinism required")
    if kind=="encounter" and "legal_choices_required" not in ts: add(ds,"missing_semantic_obligation",path,"encounters require legal choices")
    if kind=="ending" and "explicit_outcome_attribution" not in ts: add(ds,"missing_semantic_obligation",path,"endings require outcome attribution")
    if kind=="role" and "generic_alternative_required" not in ts: add(ds,"missing_semantic_obligation",path,"roles require generic alternatives")
    if kind=="form" and "stable_seat_continuation" not in ts: add(ds,"missing_semantic_obligation",path,"forms preserve stable seats")
    if kind=="faction" and privacy=="faction_private" and "controlled_reveal_required" not in ts: add(ds,"missing_semantic_obligation",path,"private factions require controlled reveal")
    return kind if isinstance(kind,str) else None,ids

def validate_reference(r:Any, reference_path:Path=DEFAULT_REFERENCE)->list[Diagnostic]:
    ds:list[Diagnostic]=[]
    if not isinstance(r,dict): return [Diagnostic("unsupported_schema","/","reference root must be object")]
    exact(r,TOP,"",ds); safety(r,"",ds)
    if r.get("authoring_kind")!="tale_authoring_reference" or r.get("schema_version")!=1: add(ds,"unsupported_schema","/authoring_kind","must be tale_authoring_reference v1")
    if r.get("tale_id")!="drowned_harbor" or r.get("reference_version")!=1: add(ds,"unstable_identity","/tale_id","must be drowned_harbor version 1")
    if r.get("production_status")!="design_only" or r.get("runtime_integration_authorized") is not False or r.get("production_catalog_authorized") is not False: add(ds,"production_boundary","/","reference must remain design-only with no runtime/catalog authority")
    try:
        if "game/data/tales" in reference_path.relative_to(ROOT).as_posix(): add(ds,"production_boundary","/","reference must remain outside game/data/tales")
    except ValueError: add(ds,"unsafe_path","/","reference must reside inside repository")
    auth=r.get("source_authorities")
    if not isinstance(auth,list) or len(auth)<2: add(ds,"missing_required_field","/source_authorities","at least two authorities required")
    else:
        if auth!=sorted(set(auth)): add(ds,"unstable_ordering","/source_authorities","must be sorted and unique")
        for i,x in enumerate(auth): repo_file(x,f"/source_authorities/{i}",ds)
    if r.get("privacy_classes")!=EXPECTED_PRIVACY: add(ds,"invalid_privacy","/privacy_classes","exact sorted production privacy vocabulary required")

    mode_ids:set[str]=set(); c=r.get("compatibility")
    if not isinstance(c,dict) or set(c)!={"engine_target","minimum_seats","maximum_seats","modes"}: add(ds,"unsupported_schema","/compatibility","invalid compatibility fields")
    else:
        if (c.get("engine_target"),c.get("minimum_seats"),c.get("maximum_seats")) != ("godot_4_7",1,8): add(ds,"unsupported_player_count","/compatibility","Godot 4.7 and 1-8 stable seats required")
        modes=c.get("modes"); order=[]
        if not isinstance(modes,list) or not modes: add(ds,"missing_required_field","/compatibility/modes","mode plans required")
        else:
            for i,m in enumerate(modes):
                p=f"/compatibility/modes/{i}"; keys={"id","status","minimum_seats","maximum_seats","privacy_model","fallback_mode"}
                if not exact(m,keys,p,ds): continue
                mid=m["id"]
                if not sid(mid): add(ds,"unstable_identity",f"{p}/id","stable mode ID required"); continue
                order.append(mid); mode_ids.add(mid)
                if not isinstance(m["minimum_seats"],int) or not isinstance(m["maximum_seats"],int) or not (1<=m["minimum_seats"]<=m["maximum_seats"]<=8): add(ds,"unsupported_player_count",p,"mode seats must be within 1-8")
                if m["status"] not in {"supported","review_required","deferred"}: add(ds,"unsupported_status",f"{p}/status","unsupported mode status")
                if mid=="cooperative":
                    if m["status"]!="supported" or m["fallback_mode"] is not None: add(ds,"missing_fallback",p,"cooperative must be supported with no fallback")
                elif m["fallback_mode"]!="cooperative": add(ds,"missing_fallback",p,"non-cooperative modes require cooperative fallback")
            if order!=sorted(order) or len(order)!=len(set(order)): add(ds,"unstable_ordering","/compatibility/modes","modes must be sorted and unique")
            if "cooperative" not in mode_ids: add(ds,"missing_fallback","/compatibility/modes","cooperative mode required")

    graph=r.get("stage_graph"); stages:list[str]=[]; transition_records=[]
    if not isinstance(graph,dict) or set(graph)!={"entry_stage","required_terminal_stage","stage_order","transitions"}: add(ds,"unsupported_schema","/stage_graph","invalid stage graph fields")
    else:
        stages=graph["stage_order"] if isinstance(graph["stage_order"],list) else []
        if not stages or any(not sid(x) for x in stages) or len(stages)!=len(set(stages)): add(ds,"unstable_identity","/stage_graph/stage_order","unique stable stages required")
        entry,terminal=graph["entry_stage"],graph["required_terminal_stage"]
        if entry not in stages or terminal not in stages: add(ds,"invalid_transition","/stage_graph","entry/terminal must resolve")
        ts=graph["transitions"]
        if not isinstance(ts,list): add(ds,"invalid_transition","/stage_graph/transitions","array required")
        else:
            ids=[]; norm=[]; adj={x:set() for x in stages}
            for i,t in enumerate(ts):
                p=f"/stage_graph/transitions/{i}"
                if not exact(t,{"id","from","to","trigger_id","once_only"},p,ds): continue
                if not sid(t["id"]) or not sid(t["trigger_id"]): add(ds,"unstable_identity",p,"stable transition/trigger IDs required"); continue
                ids.append(t["id"]); s,d=t["from"],t["to"]
                if s not in adj or d not in adj: add(ds,"invalid_transition",p,"stages must resolve"); continue
                if t["once_only"] is not True: add(ds,"nondeterministic_transition",p,"transition must be once-only")
                norm.append((s,d,t["id"])); adj[s].add(d); transition_records.append(t)
            if norm!=sorted(norm) or len(ids)!=len(set(ids)): add(ds,"unstable_ordering","/stage_graph/transitions","sort by source/target with unique IDs")
            reachable={entry} if entry in adj else set(); pending=list(reachable)
            while pending:
                s=pending.pop(0)
                for d in sorted(adj[s]):
                    if d not in reachable: reachable.add(d); pending.append(d)
            missing=[x for x in stages if x not in reachable]
            if missing or terminal not in reachable: add(ds,"unreachable_stage","/stage_graph",f"unreachable stages: {', '.join(missing or [str(terminal)])}")

    traces=trace_ids(ds); groups={k:[] for k in KINDS}; all_ids:set[str]=set(); cps=r.get("content_manifests")
    if not isinstance(cps,list) or not cps: add(ds,"missing_required_field","/content_manifests","content manifests required")
    else:
        if cps!=sorted(set(cps)): add(ds,"unstable_ordering","/content_manifests","paths must be sorted and unique")
        mids=[]
        for i,raw in enumerate(cps):
            lp=f"/content_manifests/{i}"; p=repo_file(raw,lp,ds)
            if not p: continue
            if "docs/tales/drowned_harbor/authoring/" not in p.relative_to(ROOT).as_posix(): add(ds,"production_boundary",lp,"manifest must remain in authoring directory")
            m=read_json(p,ds,lp)
            if not m or not exact(m,MKEYS,lp,ds): continue
            if m["manifest_kind"]!="tale_authoring_content_groups" or m["schema_version"]!=1: add(ds,"unsupported_schema",lp,"unsupported content manifest")
            if m["tale_id"]!=r.get("tale_id") or m["production_status"]!="design_only": add(ds,"production_boundary",lp,"manifest must match design-only Tale")
            if not sid(m["manifest_id"]): add(ds,"unstable_identity",f"{lp}/manifest_id","stable manifest ID required")
            else: mids.append(m["manifest_id"])
            if not isinstance(m["groups"],list) or not m["groups"]: add(ds,"missing_required_field",f"{lp}/groups","groups required"); continue
            for j,g in enumerate(m["groups"]):
                gp=f"{lp}/groups/{j}"; kind,ids=validate_group(g,gp,set(stages),traces,ds)
                if kind in groups and isinstance(g,dict): groups[kind].append(g)
                for x in ids:
                    if x in all_ids: add(ds,"duplicate_id",f"{gp}/ids",f"content ID '{x}' appears more than once")
                    all_ids.add(x)
        if mids!=sorted(mids) or len(mids)!=len(set(mids)): add(ds,"unstable_ordering","/content_manifests","manifest IDs must be sorted and unique")
    stage_content={x for g in groups["stage"] for x in g.get("ids",[])}
    if stage_content!=set(stages): add(ds,"unresolved_stage","/content_manifests","stage content must exactly match stage graph")
    mode_content={x for g in groups["mode"] for x in g.get("ids",[])}
    if mode_content!=mode_ids: add(ds,"unresolved_mode","/content_manifests","mode content must exactly match mode plans")
    for kind,count in {"stage":5,"tide_state":5,"ending":7}.items():
        actual=sum(len(g.get("ids",[])) for g in groups[kind])
        if actual!=count: add(ds,"incomplete_inventory",f"/content_manifests/{kind}",f"expected {count}, found {actual}")
    if len(all_ids)!=120: add(ds,"incomplete_inventory","/content_manifests",f"expected 120 stable IDs, found {len(all_ids)}")

    transforms=r.get("signature_transformations")
    if not isinstance(transforms,list) or not transforms: add(ds,"missing_required_field","/signature_transformations","at least one required")
    else:
        ids=[]
        for i,t in enumerate(transforms):
            p=f"/signature_transformations/{i}"; keys={"id","source_stage","target_stage","trigger_id","deterministic","once_only","minimum_changed_state_categories","allowed_state_categories"}
            if not exact(t,keys,p,ds): continue
            if not sid(t["id"]): add(ds,"unstable_identity",f"{p}/id","stable transformation ID required")
            else: ids.append(t["id"])
            if t["source_stage"] not in stages or t["target_stage"] not in stages: add(ds,"invalid_transition",p,"transformation stages must resolve")
            if t["deterministic"] is not True or t["once_only"] is not True: add(ds,"nondeterministic_transition",p,"must be deterministic and once-only")
            cats=t["allowed_state_categories"]; minimum=t["minimum_changed_state_categories"]
            if not isinstance(cats,list) or cats!=sorted(set(cats)) or len(cats)<2: add(ds,"unstable_ordering",f"{p}/allowed_state_categories","sorted unique categories required")
            if not isinstance(minimum,int) or minimum<2 or minimum>len(cats or []): add(ds,"missing_semantic_obligation",f"{p}/minimum_changed_state_categories","at least two categories must change")
            if not any(x.get("from")==t["source_stage"] and x.get("to")==t["target_stage"] and x.get("trigger_id")==t["trigger_id"] for x in transition_records): add(ds,"invalid_transition",p,"must match declared stage transition")
        if ids!=sorted(ids) or len(ids)!=len(set(ids)): add(ds,"unstable_ordering","/signature_transformations","IDs must be sorted and unique")

    media=r.get("media_sources")
    if not isinstance(media,dict) or set(media)!=MEDIA: add(ds,"unsupported_schema","/media_sources","invalid media source fields")
    else:
        for k in sorted(MEDIA-{"traceability_path"}):
            vals=media[k]
            if not isinstance(vals,list) or not vals: add(ds,"missing_required_field",f"/media_sources/{k}","paths required"); continue
            if vals!=sorted(set(vals)): add(ds,"unstable_ordering",f"/media_sources/{k}","paths must be sorted and unique")
            for i,x in enumerate(vals): repo_file(x,f"/media_sources/{k}/{i}",ds)
        tp=repo_file(media["traceability_path"],"/media_sources/traceability_path",ds)
        if tp and tp!=TRACEABILITY_PATH: add(ds,"unresolved_traceability","/media_sources/traceability_path","P0.8 traceability path required")

    fb=r.get("fallbacks")
    if not isinstance(fb,dict) or set(fb)!=FALLBACKS or any(not sid(x) for x in fb.values()): add(ds,"missing_fallback","/fallbacks","all stable fallback declarations required")
    elif fb["cooperative_mode"]!="cooperative": add(ds,"missing_fallback","/fallbacks/cooperative_mode","must resolve to cooperative")

    obs=r.get("validation_obligations")
    if not isinstance(obs,list) or not obs: add(ds,"missing_required_field","/validation_obligations","obligations required")
    else:
        ids=[]; human=0
        for i,o in enumerate(obs):
            p=f"/validation_obligations/{i}"
            if not exact(o,{"id","requirement","status"},p,ds): continue
            if not sid(o["id"]): add(ds,"unstable_identity",f"{p}/id","stable ID required")
            else: ids.append(o["id"])
            if not isinstance(o["requirement"],str) or len(o["requirement"].strip())<20: add(ds,"missing_required_field",f"{p}/requirement","requirement too short")
            if o["status"]=="human_validation_required": human+=1
            elif o["status"]!="declared_preproduction": add(ds,"unsupported_status",f"{p}/status","unsupported status")
        if ids!=sorted(ids) or len(ids)!=len(set(ids)): add(ds,"unstable_ordering","/validation_obligations","must be sorted and unique")
        if human<3: add(ds,"human_evidence_required","/validation_obligations","at least three human-review obligations must remain")

    dec=r.get("open_decisions")
    if not isinstance(dec,list) or not dec: add(ds,"missing_required_field","/open_decisions","open decisions required")
    else:
        ids=[]; blockers=0
        for i,d in enumerate(dec):
            p=f"/open_decisions/{i}"
            if not exact(d,{"id","summary","blocks_production","status","source_path"},p,ds): continue
            if not sid(d["id"]): add(ds,"unstable_identity",f"{p}/id","stable ID required")
            else: ids.append(d["id"])
            blockers+=d["blocks_production"] is True
            if d["status"] not in {"open","review_required","deferred"}: add(ds,"unsupported_status",f"{p}/status","unsupported status")
            repo_file(d["source_path"],f"{p}/source_path",ds)
        if ids!=sorted(ids) or len(ids)!=len(set(ids)): add(ds,"unstable_ordering","/open_decisions","must be sorted and unique")
        if blockers==0: add(ds,"production_boundary","/open_decisions","at least one production blocker must remain")

    expected_comp={"target_package_kind":"tale","target_schema_version":1,"compilation_authorized":False,"runtime_loader_input":False,"production_catalog_entry":False,"required_future_artifacts":["board_authority","director_content","governed_localization_catalog","provider_registration","rules_content","scenario_manifest","social_content"]}
    if r.get("compilation_boundary")!=expected_comp: add(ds,"production_boundary","/compilation_boundary","exact no-compilation/no-runtime/no-catalog boundary required")
    expected_identity={"algorithm":"sha256","canonicalization":"utf8_json_sorted_object_keys_compact_arrays_preserved","authoring_identity_only":True}
    if r.get("identity_policy")!=expected_identity: add(ds,"unstable_identity","/identity_policy","exact authoring-only SHA-256 policy required")
    return sorted(set(ds))

def parse_args(argv:list[str])->argparse.Namespace:
    p=argparse.ArgumentParser(description=__doc__); p.add_argument("reference",nargs="?",type=Path,default=DEFAULT_REFERENCE); p.add_argument("--identity",action="store_true"); return p.parse_args(argv)
def main(argv:list[str]|None=None)->int:
    args=parse_args(sys.argv[1:] if argv is None else argv); ds:list[Diagnostic]=[]; r=read_json(args.reference,ds,"/")
    if r is not None: ds.extend(validate_reference(r,args.reference))
    ds=sorted(set(ds))
    if ds:
        for d in ds: print(json.dumps(d.as_dict(),sort_keys=True),file=sys.stderr)
        print(f"Tale authoring reference validation failed with {len(ds)} diagnostic(s)",file=sys.stderr); return 1
    assert r is not None
    print(authoring_digest(r) if args.identity else f"Validated design-only Tale authoring reference '{r.get('tale_id')}' with {len(r.get('content_manifests',[]))} content manifests")
    return 0
if __name__=="__main__": raise SystemExit(main())
