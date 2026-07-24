# Drowned Harbor Localization and Accessible Narrative Preproduction

**Release stream:** P0.7
**Status:** Localization, captions, transcript, accessible narrative, and pseudolocalization contracts only
**Tale status:** Design-only; Lantern House remains the sole production Tale
**Production localization:** None approved

## Core principle

Narrative information must survive the loss of:

- recorded voice;
- music;
- sound effects;
- color;
- animation timing;
- English word order.

The current state, legal choices, consequences, public ownership, and narrative result must remain understandable through persistent text and non-audio presentation.

The global direction is `docs/accessibility/Localization_Captions_and_Accessible_Narrative_Direction_v1.md`.

The Drowned Harbor terminology and caption style is `Drowned_Harbor_Caption_and_Localization_Style_v1.md`.

## Governed inventory

P0.7 defines **22 accessible narrative registry units across two manifests**, covering every P0.6 voice family exactly once.

### Stage and narrative flow — 10 units

- Harbor Welcome;
- Low-Tide Board Established;
- Bellhouse Ledger Introduced;
- Unresolved Extra Ring Acknowledged;
- Lighthouse Council Opens;
- High Water Board Transformation Recap;
- Drowned Archive Opens;
- Last Light Begins;
- Harbor Bargain Offered;
- Harbor Debt Collected.

### Reveal, continuation, system, and ending flow — 12 units

- Bellmarked Public Reveal;
- Tidebound Public Transformation;
- Bell-Witness Continuation;
- Drowned Guide Continuation;
- Lighthouse Guardian Continuation;
- Invalid Action and Legal Options;
- Public Route Instability Warning;
- Stable Seat Human Departure;
- Stable Seat Surrogate Activation;
- Stable Seat Human Takeover;
- Reserved Player Return;
- Mixed Public Outcome Attribution.

## Source-of-truth relationship

The accessibility registry does not duplicate or replace the English draft scripts.

Each unit references:

- its governed P0.6 source family ID;
- all four source fields:
  - Spooky;
  - Grim;
  - Gore & Dread;
  - plain system;
- the exact mechanical-equivalence key;
- the source privacy class.

A source-family edit must continue to match its accessibility unit.

## Every registry unit declares

- stable accessibility unit ID;
- source family and source locale;
- localizable speaker key;
- public or plain-system privacy class;
- importance;
- allowed named placeholders;
- no-concatenation and no-private-placeholder rules;
- subtitle and closed-caption behavior;
- two-line and character-count design targets;
- text-scale safety;
- transcript inclusion and replay;
- public event-label key;
- polite, assertive, or focus-required announcement behavior;
- coalescing and interruption rules;
- persistent text and dismissal behavior;
- logical reading order;
- translator notes;
- explicit non-production boundary.

## Terminology

The package defines source meanings and words to avoid for:

- stable seat;
- human control;
- game control;
- Bellhouse;
- Bellmarked;
- Tidebound;
- Bell-Witness;
- Drowned Guide;
- Lighthouse Guardian;
- Low Tide;
- High Water;
- Last Light;
- Harbor bargain;
- Drowned Archive.

The terminology register preserves stable-seat continuity and prevents translation from turning public forms into elimination, generic monsters, traitor shorthand, respawn, or character replacement.

Working names remain provisional and localizable. Translation does not confer legal clearance.

## Caption behavior

Governed speech must support:

- subtitles;
- full closed captions;
- localizable speaker labels;
- configurable text scale and contrast background;
- transcript history;
- replay;
- text that survives interrupted voice playback;
- persistent critical instructions;
- plain-language or plain-system presentation.

Critical information cannot exist only in audio or a timed caption.

Provisional internal caption targets:

- no more than two lines;
- target up to 42 characters per line where the language permits;
- semantic line breaks;
- no all-caps paragraphs;
- no color-only speaker identity;
- no illegible distortion or animated letter-by-letter reveal for critical text.

These are preproduction design targets, not external-standard compliance claims.

## Transcript and announcement behavior

Public governed narrative enters a public session transcript with:

- localizable event labels;
- speaker label;
- rendered public text;
- replay availability;
- interruption history where useful;
- stage or event context.

Private content may not enter the public transcript.

Announcement priorities are authored as:

- polite;
- assertive;
- focus required.

Lower-priority updates coalesce and must not interrupt critical decisions. Focus order follows the required action and legal choices before optional lore.

## Placeholders

Approved placeholders use named semantic tokens such as:

- `{seat_name}`;
- `{route_name}`;
- `{location_name}`;
- `{form_name}`;
- `{faction_name}`;
- `{count}`;
- `{action_name}`;
- `{stage_name}`;
- `{item_name}`;
- `{controller_name}`.

Sentence concatenation and private placeholders are prohibited.

The same placeholder set must remain present across Spooky, Grim, Gore & Dread, and plain-system source variants.

## Pseudolocalization

`tools/pseudolocalize_narrative.py` generates a deterministic `qps-ploc` test package.

It:

- processes all 22 source families;
- generates 88 profile and plain-system strings;
- adds accented glyphs;
- expands text by a configurable ratio;
- preserves named placeholders exactly;
- marks output visibly as nonproduction;
- writes only to an explicitly selected output path;
- does not modify source manifests.

Example:

```bash
python tools/pseudolocalize_narrative.py \
  --output /tmp/drowned_harbor_qps_ploc.json
```

The generated package is not a real translation or supported locale.

## Validation

Run:

```bash
python tools/validate_accessible_narrative_registry.py
python tools/test_validate_accessible_narrative_registry.py
python tools/test_pseudolocalize_narrative.py
```

The validator rejects:

- unknown, missing, duplicate, or multiply registered source families;
- accessibility units with mismatched mechanical-equivalence keys;
- privacy drift from the source family;
- missing profile or plain-system source paths;
- unnamed, private, or undeclared placeholders;
- placeholder-set drift across profiles;
- sentence concatenation;
- captions beyond the P0.7 two-line target;
- timed-only critical narrative;
- missing captions, transcript, replay, speaker labels, or text-scale safety;
- inconsistent focus and announcement priority;
- interrupting nonurgent announcements;
- critical text without persistence;
- system text assigned to the host speaker or character text assigned to the system speaker;
- production localization approval inside P0.7.

## Translation boundary

P0.7 does not contain a translated locale.

A later translation package must:

- freeze a source version;
- export stable IDs, source text, placeholders, privacy, speaker, screenshots, and translator notes;
- use qualified human review for mechanical and privacy-sensitive text;
- preserve placeholders and profile equivalence;
- perform linguistic and in-context review;
- test captions, transcript, focus, text scale, overflow, and right-to-left behavior;
- record unresolved risks and disposition.

Machine translation may assist a draft. It may not approve mechanically authoritative or privacy-sensitive text without qualified review.

## Deferred work

P0.7 does not approve:

- final English copy;
- any translated locale;
- a localization vendor or machine-translation provider;
- final caption speed, segmentation, layout, speaker label, or font;
- final transcript, focus, live-region, screen-reader, controller, or right-to-left implementation;
- font files or licensing decisions;
- accessibility compliance claims;
- production runtime integration;
- a second production Tale.
