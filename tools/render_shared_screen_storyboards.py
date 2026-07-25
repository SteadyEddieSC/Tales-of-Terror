#!/usr/bin/env python3
"""Render validated shared-screen storyboard records to one offline HTML file."""

from __future__ import annotations

import argparse
import html
import json
import sys
from pathlib import Path
from typing import Any

import validate_shared_screen_storyboards as validator

REGION_LABELS = {
    "stage_objective_upper_left": "STAGE + OBJECTIVE",
    "tide_state_upper_center": "TIDE + TRANSFORMATION",
    "host_authority_upper_right": "HOST + AUTHORITY",
    "playable_board_center": "PLAYABLE BOARD",
    "decision_panel_center": "DECISION PANEL",
    "decision_drawer_right": "DECISION DRAWER",
    "caption_lower_center": "CAPTIONS",
    "seat_rail_bottom": "STABLE-SEAT RAIL",
    "controller_prompt_strip": "CONTROLLER PROMPTS",
    "private_shield_full_screen": "PRIVATE SHIELD",
    "transcript_drawer": "TRANSCRIPT + REPLAY",
    "settings_overlay": "ACCESSIBILITY SETTINGS",
    "outcome_columns": "OUTCOME ATTRIBUTION",
    "public_recap_panel": "PUBLIC RECAP",
}


def esc(value: Any) -> str:
    return html.escape(str(value), quote=True)


def list_items(values: list[str]) -> str:
    return "".join(f"<li>{esc(value)}</li>" for value in values)


def definition_items(values: dict[str, Any]) -> str:
    return "".join(
        f"<dt>{esc(key.replace('_', ' ').title())}</dt><dd>{esc(value)}</dd>"
        for key, value in values.items()
    )


def region_class(region: str) -> str:
    mapping = {
        "stage_objective_upper_left": "top-left",
        "tide_state_upper_center": "top-center",
        "host_authority_upper_right": "top-right",
        "playable_board_center": "board",
        "decision_panel_center": "decision-center",
        "decision_drawer_right": "decision-right",
        "caption_lower_center": "captions",
        "seat_rail_bottom": "seats",
        "controller_prompt_strip": "prompts",
        "private_shield_full_screen": "private-shield",
        "transcript_drawer": "drawer",
        "settings_overlay": "drawer",
        "outcome_columns": "board",
        "public_recap_panel": "decision-center",
    }
    return mapping[region]


def render_frame(record: dict[str, Any]) -> str:
    regions = record["layout_regions"]
    if "private_shield_full_screen" in regions:
        return (
            '<div class="wireframe private-mode">'
            '<div class="private-shield"><strong>PRIVATE HANDOFF</strong>'
            '<span>Shared display shows no private hint</span></div>'
            '<div class="prompts">ACKNOWLEDGE · BACK WHERE LEGAL</div>'
            "</div>"
        )
    blocks: list[str] = []
    for region in regions:
        blocks.append(
            f'<div class="region {region_class(region)}" data-region="{esc(region)}">'
            f"<strong>{esc(REGION_LABELS[region])}</strong>"
            f"<span>{esc(record['title'])}</span>"
            "</div>"
        )
    return '<div class="wireframe">' + "".join(blocks) + "</div>"


def render_record(record: dict[str, Any]) -> str:
    status = record["status"].replace("_", " ").upper()
    stages = ", ".join(record["stage_context"])
    trace = ", ".join(record["traceability_concepts"]) or "None"
    policy_blocks = (
        '<section class="policy"><h4>Caption policy</h4><dl>'
        + definition_items(record["caption_policy"])
        + "</dl></section>"
        '<section class="policy"><h4>Transcript policy</h4><dl>'
        + definition_items(record["transcript_policy"])
        + "</dl></section>"
        '<section class="policy"><h4>Persistent text</h4><dl>'
        + definition_items(record["persistent_text_policy"])
        + "</dl></section>"
        '<section class="policy"><h4>Stable-seat authority</h4><dl>'
        + definition_items(record["seat_authority_policy"])
        + "</dl></section>"
    )
    return f"""
<section class="storyboard" id="{esc(record['storyboard_id'])}">
  <header class="storyboard-header">
    <div>
      <span class="eyebrow">{esc(record['storyboard_id'])} · {esc(record['category'])}</span>
      <h2>{esc(record['title'])}</h2>
      <p>{esc(record['purpose'])}</p>
    </div>
    <div class="status">{esc(status)}</div>
  </header>
  <div class="content-grid">
    <div>
      {render_frame(record)}
      <div class="facts">
        <span><b>Layout:</b> {esc(record['layout_mode'])}</span>
        <span><b>Privacy:</b> {esc(record['privacy_surface'])}</span>
        <span><b>Stages:</b> {esc(stages)}</span>
        <span><b>Confirmation:</b> {esc(record['confirmation_pattern'])}</span>
      </div>
      <div class="conditions">
        <p><b>Entry:</b> {esc(record['entry_condition'])}</p>
        <p><b>Exit:</b> {esc(record['exit_condition'])}</p>
      </div>
      <div class="policy-grid">{policy_blocks}</div>
    </div>
    <aside>
      <details open><summary>Required information</summary><ul>{list_items(record['required_information'])}</ul></details>
      <details><summary>Layout regions</summary><ul>{list_items(record['layout_regions'])}</ul></details>
      <details><summary>Legal actions</summary><ul>{list_items(record['legal_actions'])}</ul></details>
      <details><summary>Focus order</summary><ol>{list_items(record['focus_order'])}</ol></details>
      <details><summary>State variants</summary><ul>{list_items(record['state_variants'])}</ul></details>
      <details><summary>Visual guidance</summary><ul>{list_items(record['visual_guidance'])}</ul></details>
      <details><summary>Negative constraints</summary><ul>{list_items(record['negative_constraints'])}</ul></details>
      <details><summary>Source authorities</summary><ul>{list_items(record['source_paths'])}</ul></details>
      <details><summary>Human validation questions</summary><ul>{list_items(record['human_validation_questions'])}</ul></details>
      <p class="trace"><b>Traceability:</b> {esc(trace)}</p>
    </aside>
  </div>
  <footer>{esc(record['approval_boundary'])}</footer>
</section>
"""


def render_html(records: list[dict[str, Any]], identity: str) -> str:
    records = sorted(records, key=lambda record: record["storyboard_id"])
    navigation = "".join(
        f'<a href="#{esc(record["storyboard_id"])}">{esc(record["storyboard_id"])} {esc(record["title"])}</a>'
        for record in records
    )
    sections = "".join(render_record(record) for record in records)
    return f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Drowned Harbor Shared-Screen Storyboards</title>
<style>
:root {{ color-scheme:dark; font-family:system-ui,sans-serif; background:#10191d; color:#eef1ec; }}
* {{ box-sizing:border-box; }}
body {{ margin:0; background:linear-gradient(180deg,#142126,#0d1518); }}
.top {{ padding:2rem max(5vw,1rem); border-bottom:1px solid #526166; background:#17252a; position:sticky; top:0; z-index:5; }}
h1,h2,h4,p {{ margin-top:0; }}
.warning {{ color:#ffe4a8; font-weight:700; }}
.identity {{ font-family:ui-monospace,monospace; font-size:.78rem; color:#aab9bc; word-break:break-all; }}
nav {{ display:flex; gap:.45rem; overflow:auto; padding:.75rem max(5vw,1rem); background:#0d1518; position:sticky; top:151px; z-index:4; }}
nav a {{ white-space:nowrap; color:#dfe9e7; text-decoration:none; border:1px solid #526166; border-radius:999px; padding:.35rem .65rem; font-size:.75rem; }}
main {{ max-width:1500px; margin:auto; padding:1rem; }}
.storyboard {{ border:1px solid #526166; background:#17252a; margin:1.25rem 0 2.5rem; border-radius:16px; overflow:hidden; box-shadow:0 18px 55px #0007; }}
.storyboard-header {{ display:flex; justify-content:space-between; gap:1rem; padding:1.25rem; border-bottom:1px solid #526166; }}
.eyebrow,.status {{ color:#d0b174; text-transform:uppercase; letter-spacing:.08em; font-size:.75rem; }}
.status {{ border:1px solid #7c8b8e; border-radius:999px; padding:.4rem .7rem; height:max-content; }}
.content-grid {{ display:grid; grid-template-columns:minmax(0,2fr) minmax(300px,1fr); gap:1rem; padding:1rem; }}
.wireframe {{ aspect-ratio:16/9; background:#27363a; border:2px solid #7c8b8e; border-radius:10px; padding:2.5%; display:grid; grid-template-columns:1fr 1fr 1fr; grid-template-rows:12% 1fr 12% 14% 8%; gap:1.4%; position:relative; overflow:hidden; }}
.region {{ background:#d9ded8; color:#172024; border:2px solid #26363a; border-radius:6px; padding:.35rem; display:flex; flex-direction:column; justify-content:center; align-items:center; text-align:center; font-size:clamp(.45rem,1vw,.85rem); }}
.region span {{ font-size:.72em; opacity:.7; }}
.top-left {{ grid-column:1; grid-row:1; }} .top-center {{ grid-column:2; grid-row:1; }} .top-right {{ grid-column:3; grid-row:1; }}
.board {{ grid-column:1/4; grid-row:2; background:#839499; }}
.decision-center {{ grid-column:1/4; grid-row:2/4; background:#cdd1c7; }}
.decision-right,.drawer {{ grid-column:3; grid-row:2/4; background:#cdd1c7; }}
.captions {{ grid-column:1/4; grid-row:3; background:#10191de8; color:#fff; border-color:#d9ded8; }}
.seats {{ grid-column:1/4; grid-row:4; background:#a4b2b0; }}
.prompts {{ grid-column:1/4; grid-row:5; background:#111c20; color:#fff; border:1px solid #718287; display:flex; align-items:center; justify-content:center; font-size:.7rem; }}
.private-mode {{ display:flex; align-items:center; justify-content:center; flex-direction:column; gap:1rem; background:#111c20; }}
.private-shield {{ width:70%; height:55%; border:2px solid #a9b8b5; background:#26363a; display:flex; flex-direction:column; align-items:center; justify-content:center; text-align:center; border-radius:10px; }}
.private-shield span {{ margin-top:.6rem; color:#a9b8b5; }}
.facts {{ display:flex; flex-wrap:wrap; gap:.5rem; padding:.75rem 0; }}
.facts span {{ border:1px solid #526166; border-radius:999px; padding:.35rem .6rem; font-size:.75rem; }}
.conditions {{ border:1px solid #526166; border-radius:10px; padding:.8rem; background:#111c20; font-size:.86rem; }}
.conditions p:last-child {{ margin-bottom:0; }}
.policy-grid {{ display:grid; grid-template-columns:1fr 1fr; gap:.65rem; margin-top:.75rem; }}
.policy {{ border:1px solid #526166; border-radius:10px; padding:.7rem; background:#111c20; }}
.policy h4 {{ color:#e2c98d; }}
dl {{ display:grid; grid-template-columns:1fr 1fr; gap:.25rem .5rem; margin:0; font-size:.76rem; }}
dt {{ color:#aab9bc; }} dd {{ margin:0; text-align:right; word-break:break-word; }}
aside {{ max-height:90vh; overflow:auto; }}
details {{ border-bottom:1px solid #526166; padding:.5rem 0; }}
summary {{ cursor:pointer; font-weight:700; color:#e2c98d; }}
li {{ margin:.35rem 0; line-height:1.35; }}
.trace {{ color:#aab9bc; font-size:.85rem; }}
.storyboard footer {{ border-top:1px solid #526166; padding:1rem; color:#bac7c7; font-size:.82rem; }}
@media (max-width:900px) {{ .content-grid,.policy-grid {{ grid-template-columns:1fr; }} nav {{ top:178px; }} aside {{ max-height:none; }} }}
@media print {{ .top,nav {{ position:static; }} .storyboard {{ break-inside:avoid; box-shadow:none; }} details {{ display:block; }} }}
</style>
</head>
<body>
<header class="top">
<h1>Drowned Harbor Shared-Screen Storyboards</h1>
<p class="warning">PREPRODUCTION ONLY — NOT A RUNNING GAME, FINAL UI, OR HUMAN USABILITY RESULT</p>
<p>{len(records)} controller-first 16:9 storyboard records. Lantern House remains the sole production Tale.</p>
<p class="identity">Storyboard identity: {esc(identity)}</p>
</header>
<nav aria-label="Storyboard navigation">{navigation}</nav>
<main>{sections}</main>
</body>
</html>
"""


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("manifests", nargs="*", type=Path)
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    paths = tuple(args.manifests) if args.manifests else validator.discover_manifests()
    diagnostics, summary = validator.validate_manifests(paths)
    if diagnostics:
        for diagnostic in diagnostics:
            print(json.dumps(diagnostic.as_dict(), sort_keys=True), file=sys.stderr)
        return 1
    records: list[dict[str, Any]] = []
    for path in paths:
        records.extend(validator.read_json(path)["entries"])
    output = render_html(records, summary["identity"])
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(output, encoding="utf-8")
    print(f"Rendered {len(records)} shared-screen storyboards to {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
