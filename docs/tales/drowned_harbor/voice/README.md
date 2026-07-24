# Drowned Harbor Underteller Voice Preproduction

**Release stream:** P0.6
**Status:** Voice direction, casting preparation, and audition-ready draft line families only
**Tale status:** Design-only; Lantern House remains the sole production Tale
**Production voice:** None approved
**Name status:** The Underteller remains provisional pending issue #7

## Voice identity

The Underteller is an **elegant, mechanically truthful master of ceremonies who happens to be dead**.

The performance should provide:

- polite menace;
- dry observational amusement;
- selective warmth;
- mechanical clarity;
- earned intensity;
- quiet authority;
- privacy-safe public narration;
- complete plain-system fallback.

It should not become:

- a pirate captain;
- a demon;
- a trailer announcer;
- a carnival barker;
- a constant whisper;
- a recognizable celebrity or fictional-character imitation;
- a source of improvised gameplay facts.

The controlling global direction is `docs/voice/Underteller_Voice_Direction_v1.md`.

The Tale-specific addendum is `Drowned_Harbor_Underteller_Performance_Addendum_v1.md`.

Casting and audition governance is defined in `docs/voice/Underteller_Casting_and_Audition_Protocol_v1.md`.

## Governed inventory

P0.6 defines **22 audition-ready draft line families across two manifests**.

### Narrative and stage flow — 10 families

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

### Reveal, continuation, system, and ending flow — 12 families

- Bellmarked Public Reveal;
- Tidebound Public Transformation;
- Bell-Witness Continuation Activated;
- Drowned Guide Continuation Activated;
- Lighthouse Guardian Continuation Activated;
- Invalid Action and Legal Options;
- Public Route Instability Warning;
- Stable Seat Human Departure;
- Stable Seat Surrogate Activation;
- Stable Seat Human Takeover;
- Reserved Player Return;
- Mixed Public Outcome Attribution.

## Draft-script boundary

The profile scripts are **audition-ready drafts**, not final narrative copy.

Each family contains:

- Spooky wording;
- Grim wording;
- Gore & Dread wording;
- a plain-system equivalent;
- one mechanical-equivalence key;
- required public facts;
- forbidden private inputs;
- prohibited implications;
- delivery mode and intensity range;
- performance and pronunciation notes;
- duration targets;
- replay, caption, interruption, and input behavior;
- take structure;
- human and synthetic audition direction;
- consent and provenance requirements;
- a non-production approval boundary.

Profile variants may change explicitness and theatrical texture. They may not change legal options, state, timing rules, consequences, or privacy.

## Public and private state

Shared-speaker voice may reference only authorized public information.

It must not expose:

- hidden factions or roles;
- private objectives;
- private bargain terms;
- private inventory or route knowledge;
- latent transformations;
- hidden targets;
- private votes;
- unrevealed ending carriers;
- controlled companion-device content.

Private information defaults to controlled visual presentation. Private voice remains deferred pending a separate device, privacy, interruption, and accessibility review.

## Stable-seat continuity

Human departure, surrogate activation, takeover, return, defeat, transformation, and Restless continuation do not replace or reset the stable seat.

Voice lines must preserve:

- the same character and seat identity;
- evolved health and condition;
- location and form;
- inventory and public state;
- hidden role and private objective boundaries;
- active agency after Tidebound or Restless transition.

The voice must not frame these events as:

- character replacement;
- respawn;
- automatic healing;
- item restoration;
- player elimination;
- punishment for disconnecting or leaving.

## Plain-system fallback

All critical families include mechanically explicit plain-system wording.

The game must remain understandable with:

- Underteller voice disabled;
- music disabled;
- reduced sound effects;
- captions enabled;
- text-only prompts and transcripts.

Voice playback is governed as:

- interruptible;
- replayable;
- captioned;
- text-persistent after interruption;
- non-blocking for player input.

## Human performer rights

Before recording, an agreement must define:

- audition, game, update, DLC, port, trailer, and marketing uses;
- compensation and pickup terms;
- credit preference;
- edit and processing permission;
- source-session storage;
- localization and replacement rights;
- whether synthetic replication or model training is prohibited or separately licensed.

A general recording release or absence of an objection is not voice-cloning consent.

Public GitHub must not contain performer contact information, confidential contracts, tax details, or restricted raw auditions.

## Synthetic voice boundary

A synthetic candidate may render approved governed text only.

It may not:

- improvise rules or state;
- rewrite authoritative facts;
- inspect private game state;
- imitate a recognizable performer or character;
- use an undisclosed cloned voice;
- generate new public claims from raw runtime data.

Each synthetic audition requires provider, product, model or voice ID, plan, terms, generation date, exact input, style direction, source-consent basis, data-retention notes, human edits, replacement plan, and review disposition.

No provider or plan is approved in P0.6.

## Validation

Validate both manifests together:

```bash
python tools/validate_preproduction_voice_lines.py
python tools/test_validate_preproduction_voice_lines.py
```

The validator rejects:

- duplicate IDs within or across manifests;
- category and ID-prefix mismatches;
- production approval inside P0.6;
- invalid intensity or duration ordering;
- private values declared as required public facts;
- weak private-state exclusions;
- missing profile or plain-system scripts;
- prohibited seat-reset or player-elimination language;
- non-interruptible, non-replayable, uncaptioned, or input-blocking speech;
- imitation-oriented audition direction;
- missing clone-consent boundaries;
- unrestricted distribution claims for performer-linked raw files;
- profile-specific wording drift in neutral plain-system families;
- active private-surface voice;
- ending families outside ending resolution.

## Recording and audition boundary

P0.6 prepares a later audition process. It does not authorize outreach, compensation, recording, cloning, synthetic generation, or performer selection.

A later governed audition batch should:

- use neutral candidate codes;
- provide the same script packet and take direction;
- separate performance scoring from rights risk;
- record file identity and digests without publishing restricted audio;
- compare character voice with plain-system fallback;
- test dialogue against silence, ambience, SFX, and music;
- perform human television-speaker, fatigue, caption, and gameplay-clarity review;
- use only `needs_revision`, `reference_only`, `rejected`, `preproduction_shortlist`, or `deferred` dispositions.

## Deferred work

P0.6 does not approve:

- final Underteller name;
- final script wording;
- final casting, performer, accent, model, vendor, plan, or voice identity;
- audition outreach or compensation;
- production recording;
- synthetic replication or model training;
- final editing, processing, loudness, mix, or runtime integration;
- private voice delivery;
- localization casting;
- television, fatigue, hearing, or accessibility claims;
- Drowned Harbor runtime integration.
