# Post-v0.1.9 Preproduction Roadmap

**Version:** 0.1
**Status:** Active planning roadmap
**Protected-main baseline:** `2151696e76147cc9fbe7f56709e585753cb331a3`
**Working title status:** Terror Turn and The Underteller remain provisional pending issue #7

## 1. Current operating constraints

Until the project owner explicitly states otherwise:

- Codex Desktop and local implementation work are considered blocked.
- Human or physical-controller playtesting is considered blocked.
- No release may claim local checkout reconciliation, manual playtest evidence, physical-controller evidence, living-room readability, fun, balance, accessibility certification, or long-session validation.
- No documentation release should silently introduce gameplay, package, catalog, provider, snapshot, report, RNG, companion protocol, or cloud-service changes.

These constraints do not block preproduction.

## 2. Work that remains authorized

This release-management chat may continue advancing and preserving:

- game design bibles;
- Tale concepts and authored story structures;
- Underteller dialogue and localization-ready line metadata;
- roles, factions, objectives, items, cards, encounters, endings, and Chronicle concepts;
- drop-in/drop-out and future multiplayer admission contracts;
- UI and UX specifications, wireframes, screen flows, and visual briefs;
- concept art, icons, board mockups, character sheets, environment studies, and prompt packs;
- audio scripts, voice direction, sound-effect inventories, music briefs, and temporary prototypes;
- video storyboards, animatics, trailer concepts, and scene lists;
- reusable Tale-authoring schemas and validation fixtures;
- asset inventories, provenance, licensing, attribution, and replacement plans;
- implementation-ready issues and acceptance criteria for later Codex work;
- legal-clearance preparation that does not make final branding claims.

## 3. Separate preproduction release stream

Preproduction packages use a `P` prefix and do not change the playable game version.

Examples:

- `P0.1` — Preproduction Narrative & Continuity Foundation
- `P0.2` — Drowned Harbor Dialogue and Localization Corpus
- `P0.3` — Drowned Harbor Visual Development Pack
- `P0.4` — Underteller Audio Direction and Prototype Pack

This avoids consuming gameplay versions such as v0.1.10 while code and playtest work are blocked.

A preproduction release may consist of reviewed documentation and source assets merged to the repository. It must state clearly that it does not create new playable content.

# Release sequence

## P0.1 — Preproduction Narrative & Continuity Foundation

**Status:** Current target

Deliverables:

- Underteller Voice Bible.
- Drowned Harbor Design Bible.
- Seat Continuity and Multiplayer Admission Contract.
- AI Media Production and Provenance Guide.
- This preproduction roadmap.
- Documentation index and cross-links where appropriate.
- Draft PR preserving all material independently of chat history.

Boundaries:

- no gameplay code;
- no second production Tale;
- no package or catalog changes;
- no version bump;
- no playtest or implementation claims.

## P0.2 — Drowned Harbor Dialogue and Localization Corpus

Deliverables:

- governed dialogue-key catalog;
- Spooky, Grim, and Gore & Dread variants where appropriate;
- plain-language fallbacks;
- stage introductions and transitions;
- interaction confirmations and rejections;
- Director pressure, relief, and hint lines;
- High Water Terror Turn variants;
- faction reveal and transformation lines;
- defeat, Restless, replacement, departure, surrogate, takeover, return, and spectator lines;
- all ending variants;
- display-character and spoken-duration budgets;
- privacy classifications;
- repetition classes and cooldown recommendations;
- pronunciation and voice-performance notes for unusual proper nouns;
- CSV or JSON authoring source suitable for later conversion into localization resources.

Exit criteria:

- every required mechanical category has at least a plain fallback;
- no public line leaks hidden information;
- profile variants remain mechanically equivalent;
- line keys and placeholders are deterministic and documented.

## P0.3 — Drowned Harbor Visual Development Pack

Deliverables:

- environment mood boards and original concept studies;
- Harbor map and tide-state board diagrams;
- lighthouse, Bellhouse, Archive, lifeboat, mudflat, market, and chapel visual briefs;
- public-role silhouette sheets;
- Bellmarked, Tidebound, and Restless transformation studies;
- item and card icon briefs;
- tide, control-source, faction, condition, and objective-state icon families;
- shared-screen composition studies for 720p, 1080p, and 4K;
- reduced-motion alternatives;
- concept-art prompt library and provenance ledger;
- production-versus-reference labeling.

Boundaries:

- generated concept art is not automatically production-ready;
- no copied commercial character, interface, composition, or distinctive style;
- provisional title text remains replaceable;
- every asset records generator, date, prompt, edit history, and license or usage status.

## P0.4 — Underteller Audio Direction and Prototype Pack

Deliverables:

- voice-performance bible;
- casting brief without final actor selection;
- accent and delivery experiments;
- voice-line sample set covering welcome, pressure, relief, Terror Turn, defeat, afterlife, takeover, and endings;
- processing-chain recommendations;
- intelligibility and loudness targets;
- temporary synthetic-voice prototypes clearly marked non-final;
- licensing and voice-consent records;
- music and ambience briefs for Lantern House and Drowned Harbor;
- sound-effect inventory for bells, water, lighthouse machinery, Restless actions, and seat-control transitions.

Boundaries:

- no unauthorized voice cloning;
- no use of a real performer's likeness or voice without permission;
- prototypes must be replaceable and must not establish final canon or casting.

## P0.5 — UI, UX, and Storyboard Pack

Deliverables:

- Tale Library presentation concept;
- Drowned Harbor briefing and Council screens;
- tide-state indicator;
- Bellhouse Ledger interaction;
- controlled-private takeover review;
- public-safe join-request and seat-selection flows;
- surrogate-control and reconnect indicators;
- High Water transition storyboard;
- Last Light decision screen;
- public and controlled-private ending layouts;
- trailer and reveal-video storyboard concepts;
- screenshot-baseline plan.

## P0.6 — Tale Authoring and Validation Specification

Deliverables:

- reusable Tale design schema;
- stage and transition tables;
- role, faction, objective, item, card, hazard, and encounter schemas;
- dialogue metadata schema;
- privacy-projection contract;
- seat-continuity requirements;
- reachability, deadlock, profile-parity, and localization validators;
- malformed-content fixture inventory;
- future Codex implementation issues with exact acceptance criteria.

This remains documentation and test-fixture design until implementation is explicitly unblocked.

## P0.7 — Chronicle and Wider World Foundation

Possible deliverables:

- relationship between Greymoor, Blackpine, Last Laugh, Red Moon, Starfall, Castle Vesper, Drowned Harbor, and Winterbound;
- what the Underteller remembers across Tales;
- Chronicle-safe consequences;
- recurring motifs and cross-Tale objects;
- rules for continuity without invalidating standalone Tales;
- additional Tale pitches ranked by distinctiveness and system coverage.

This release should not lock a large campaign before at least one human playtest is eventually available.

# Playable release backlog when implementation resumes

## Security release

The first blocked code release remains Companion Dependency Security Remediation. It must update the inherited vulnerable dependency path without changing gameplay, story, networking semantics, audit policy, or companion behavior.

## Stable Seat Continuity Foundation

The recommended next substantive gameplay feature is local stable-seat continuity:

- departure and reconnect;
- deterministic surrogate control;
- local human takeover of an AI-controlled seat;
- exact state preservation;
- public-safe seat summaries;
- privacy-safe controlled reveal;
- no online multiplayer dependency.

## Narrative and Tale validation

Implement metadata, privacy, fallback, profile-parity, stage-reachability, ending-reachability, and deadlock validation before a second production Tale.

## Visual regression and living-room QA automation

Implement screenshot baselines, text-overflow checks, seat ownership indicators, private shielding, control-source states, and reduced-motion alternatives.

## Human playtest

Issue #39 remains deferred until explicitly unblocked. A fresh candidate must be created from then-current protected main. Automated results must never be described as human evidence.

## Second production Tale

Drowned Harbor should become a production candidate only after:

- its design and assets are reviewed;
- Tale validators exist;
- stable seat continuity is implemented or consciously deferred;
- Lantern House human findings are eventually reviewed;
- a separate implementation release is authorized.

# Documentation structure

Maintain four primary sources plus the media guide rather than many disconnected files:

1. `docs/narrative/Underteller_Voice_Bible.md`
2. `docs/tales/drowned_harbor/Drowned_Harbor_Design_Bible.md`
3. `docs/design/Seat_Continuity_and_Admission.md`
4. `docs/roadmap/Post_v0.1.9_Preproduction_Roadmap.md`
5. `docs/assets/AI_Media_Production_Guide.md`

Large machine-readable dialogue, asset, and schema catalogs may be separate files beneath the same feature directories. The GDD should retain summaries and links rather than duplicating full Tale content.

# Asset governance

Every generated or externally sourced asset should record:

- stable asset ID;
- purpose and status;
- generator or source;
- model and service version where known;
- creation date;
- prompt and negative constraints;
- human edits;
- source files;
- license and commercial-use status;
- attribution requirements;
- whether training or reference material raises unresolved risk;
- production, prototype, reference-only, or rejected classification.

Do not commit opaque generated assets without a provenance entry.

# Review cadence

Perform a roadmap check:

- after each preproduction release;
- before introducing a new Tale or major asset family;
- when implementation or playtest access changes;
- when external AI-service terms or capabilities materially change;
- before moving any generated asset from concept to production status.

# Current next target

**P0.1 — Preproduction Narrative & Continuity Foundation**

The target is a reviewed GitHub documentation package containing the Underteller voice authority, Drowned Harbor design authority, stable-seat continuity and future admission model, the AI media guide, and the preproduction release roadmap. It does not change the playable game.
