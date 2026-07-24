# Tale Authoring Reference Contract v1

**Status:** P0.9 preproduction contract
**Scope:** Repository-authored design references for future Tales
**Runtime authority:** None
**Production schema changed:** No
**Production Tale catalog changed:** No

## 1. Purpose

The Tale Authoring Reference contract converts a reviewed design bible into stable, machine-validated preproduction data before runtime implementation is authorized.

It exists between narrative design and the closed production Tale package contract.

It records:

- stable authoring identities;
- stage and transformation structure;
- seat and mode compatibility intentions;
- privacy classifications;
- content inventories;
- cross-media and source provenance;
- deterministic and continuity obligations;
- unresolved decisions that still block production;
- the exact boundary between design reference and runtime package.

It does not create a playable Tale.

## 2. Relationship to the production Tale package

The accepted production contract remains:

- package kind `tale`;
- schema version `1`;
- closed exact-field validation;
- repository-authored allowlisted identities only;
- static provider registration;
- reviewed catalog identity;
- reviewed scenario, board, rules, Director, social, and localization authorities;
- canonical SHA-256 identity;
- runtime fail-closed loading.

P0.9 does not change `tools/tale_package.py`, `tools/tale_catalog.py`, `game/src/session/tale_package.gd`, `game/src/session/tale_catalog.gd`, the provider registry, or the production catalog.

The authoring reference uses package kind `tale_authoring_reference`. It is documentation and validation input only. Runtime Tale loaders must reject or ignore it because it is outside `game/data/tales/` and is not a `tale` package.

## 3. Repository location

Authoring references live below:

```text
docs/tales/<tale_id>/authoring/
```

They must not be placed below:

```text
game/data/tales/
```

until a separate runtime implementation issue explicitly authorizes a production or synthetic package.

## 4. Stable identity

Stable IDs are future persistence and replay contracts.

The reference must use lowercase snake_case IDs for:

- Tale;
- stage;
- tide or environment state;
- space and region;
- mode;
- role;
- faction;
- form;
- resource;
- item;
- card;
- hazard;
- encounter;
- ending;
- authored transition;
- open decision;
- validation obligation.

An ID may be corrected during preproduction only through an explicit migration record. Once adopted by a runtime package, save, replay, fixture, or published localization catalog, it may not be renamed or reused casually.

## 5. Source authority

Every authoring record names:

- a repository-relative source path;
- a source anchor or section;
- one or more P0.8 traceability concepts where applicable.

Source paths must:

- exist in the repository;
- remain repository-relative;
- avoid generated, cache, evidence, build, private, and dependency paths;
- contain no URL, credential, local user path, or executable reference.

The authoring reference indexes design authority. It does not silently replace or expand the source design.

## 6. Privacy classes

The authoring reference uses the existing production vocabulary:

- `public`;
- `controlled_reveal_private`;
- `seat_private`;
- `faction_private`.

No authoring record may create a fifth runtime privacy class without a separately reviewed schema and authority change.

Shared-screen presentation, public voice, public music, public SFX, transcript, and public history may use only public projections.

## 7. Content record structure

Every record declares:

- stable ID;
- kind;
- preproduction status;
- default privacy class;
- relevant stage IDs;
- bounded semantic tags;
- source path and anchor;
- P0.8 traceability concept IDs;
- concise authoring note.

Allowed statuses are:

- `draft`;
- `preproduction_ready`;
- `review_required`;
- `deferred`.

The P0.9 package may not use:

- `implementation_ready`;
- `production_candidate`;
- `approved`.

## 8. Stage graph

The authoring reference declares:

- one entry stage;
- one required terminal stage;
- semantic stage order;
- sorted authored transitions;
- stable transition IDs;
- public trigger descriptions;
- whether a transition is once-only.

Validation requires:

- every stage in the registry appears exactly once in stage order;
- every transition resolves;
- all required stages are reachable from entry;
- the terminal stage is reachable;
- no transition references hidden state as its only trigger;
- once-only signature transformations declare deterministic identity.

The authoring reference does not execute the graph.

## 9. Signature transformation contract

A Tale may declare one or more signature transformations.

Each transformation declares:

- stable ID;
- source and target stage;
- public trigger ID;
- deterministic and once-only behavior;
- minimum number of major state categories changed;
- allowed categories.

Major categories include:

- board;
- objective;
- faction;
- form;
- route;
- resource economy;
- encounter eligibility;
- ending eligibility.

Drowned Harbor's High Water must change at least two categories and may not be reduced to a visual cutscene.

## 10. Seat and mode compatibility

The reference declares intended seat bounds and authored mode plans.

Every mode plan includes:

- stable mode ID;
- status;
- minimum and maximum seats;
- privacy model;
- fallback mode where applicable.

At least one supported cooperative mode is required.

A hidden-role or dynamic-faction mode must declare a cooperative fallback for unsupported seat counts or missing authored plans.

Deferred modes remain reference material and may not enter production compatibility lists.

## 11. Stable-seat continuity

Every Tale reference must preserve the accepted stable-seat principle:

> The stable seat owns gameplay state. A human, deterministic surrogate, returning human, or authorized replacement controller supplies decisions for that same seat.

Control-source change must not reset:

- location;
- condition;
- inventory;
- role;
- faction;
- objective;
- form;
- cooldowns;
- participation history;
- ending attribution.

Defeat must produce an authored continuation, transformation, replacement route, or explicit terminal result. Active seats may not become passive spectators accidentally.

## 12. Content-kind obligations

### Stages

- appear in the stage graph;
- use public identity;
- carry semantic order.

### Modes

- declare seat compatibility and fallback behavior.

### Roles

- no ending may require one named role unless a generic authored substitute exists.

### Factions

- private allegiance remains private until a legal reveal;
- faction status cannot be inferred through public media before reveal.

### Forms

- transformed and continuation forms preserve stable-seat ownership;
- form changes must not imply player elimination.

### Hazards

- require warning, legal response, deterministic consequence, and recovery semantics.

### Encounters

- require legal choices or an explicit acknowledgement-only agency mode;
- cannot imply choice when no choice exists.

### Endings

- must be reachable only from authoritative state;
- require explicit public or controlled-private attribution for every seat and faction;
- mixed outcomes may not collapse into one universal verdict.

## 13. Media and narrative references

The reference points to governed P0.x artifacts rather than copying them.

It may index:

- dialogue catalogs;
- visual briefs;
- audio briefs;
- music briefs;
- voice families;
- accessible narrative units;
- P0.8 cross-media concepts.

A missing optional medium does not invalidate a design record when a safe fallback exists. A missing critical text, public state, privacy rule, or stable-seat rule does invalidate the reference.

## 14. Determinism and replay obligations

The authoring reference must declare obligations for later implementation, including:

- stable transition identity;
- once-only mutation;
- rejected-mutation no-op behavior;
- dedicated RNG ownership where randomness is later introduced;
- no gameplay authority from wall-clock time, animation, voice duration, network arrival, controller polling order, or asset availability;
- snapshot coverage for authoritative state;
- replay-equivalent outcomes for equal authoritative input and seeds;
- deterministic final attribution.

P0.9 validates that these obligations are declared. It does not claim they are implemented.

## 15. Fallbacks

Every reference declares:

- cooperative fallback;
- no-phone route;
- optional Companion unavailable behavior;
- voice unavailable behavior;
- music unavailable behavior;
- noncritical media unavailable behavior;
- invalid-action behavior;
- defeat continuation behavior;
- unsupported optional feature behavior.

Fallbacks must preserve complete gameplay understanding and legal action through shared-screen text and native authority.

## 16. Open decisions

Open decisions are first-class records, not hidden TODOs.

Each open decision declares:

- stable decision ID;
- summary;
- whether it blocks production;
- current status;
- source authority.

A package with any production-blocking open decision remains design-only.

## 17. Compilation boundary

A future compiler or implementation process may use the authoring reference as input only after separate authorization.

Compilation into a production Tale would still require:

- reviewed scenario manifest;
- reviewed board authority;
- reviewed rules content;
- reviewed Director content;
- reviewed social content;
- governed localization catalog;
- exact inventories;
- provider allowlist registration;
- catalog entry and new catalog digest;
- production Tale package identity;
- runtime and replay tests;
- portable-build evidence;
- human validation where required.

The authoring reference itself cannot satisfy those requirements.

## 18. Safety boundary

Authoring references prohibit:

- executable scripts or class names as content;
- expressions or dynamic callbacks;
- network URLs;
- secrets or credentials;
- local user paths;
- downloaded or untrusted package execution;
- generated build and cache paths;
- private evidence;
- hidden account identity;
- telemetry or cloud-service requirements;
- final legal naming claims.

## 19. Validation commands

P0.9 will provide:

```text
python tools/validate_tale_authoring_reference.py
python tools/test_validate_tale_authoring_reference.py
```

The validator is standard-library-only, offline, read-only, and fail-closed.

## 20. Approval boundary

This contract does not approve:

- a production Tale package;
- a second catalog entry;
- a provider registration;
- runtime code;
- new gameplay authorities;
- new snapshot or report schemas;
- Companion protocol changes;
- generated or licensed production media;
- final balance;
- final localization;
- human playtest results;
- Drowned Harbor implementation.
