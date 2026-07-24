# Drowned Harbor Audio Preproduction

**Release stream:** P0.4
**Status:** Audio direction and SFX briefs only
**Tale status:** Design-only; Lantern House remains the sole production Tale
**Production audio:** None approved

## Audio north star

Drowned Harbor should sound like **a town remembering itself through water, timber, bells, rope, glass, and damaged records**.

The package prioritizes:

- mechanical truth;
- speech and decision clarity;
- original-first signature sound design;
- public/private information boundaries;
- mono-safe critical cues;
- caption and visual redundancy;
- reduced-dynamics and reduced-density behavior;
- television-speaker compatibility as a later human-review target;
- provenance and licensing records before generation, recording, or purchase.

The controlling direction is `Drowned_Harbor_Audio_Direction_v1.md`.

## Governed inventory

P0.4 currently defines **36 audio briefs across three manifests**.

### Ambience — 8 briefs

- Lowest Tide Harbor Bed;
- Salt Market Canvas and Stall Bed;
- Bellhouse Square Resonance Bed;
- Lighthouse Exterior Wind and Beam Bed;
- Lantern Room Mechanism Bed;
- Drowned Archive Interior Bed;
- High Water Flooded Streets Bed;
- Last Light Reduced Ambience.

### Signature and gameplay events — 12 briefs

- Bellhouse Ordinary Public Strike;
- Unresolved Extra Ring;
- Ledger Name Index Commit;
- Lighthouse Lens Rotation Commit;
- Rope Rescue Under Load;
- Lifeboat Launch Commit;
- Current Takes Public Item;
- Street Gives Way Warning and Collapse;
- Drowned Archive Collapse;
- High Water Terror Turn Signature;
- Bellmarked Public Reveal;
- Tidebound Public Transformation.

### Continuity, bargains, afterlife, and resolution — 16 briefs

- Harbor Bargain Offer;
- Harbor Bargain Accepted;
- Harbor Bargain Refused;
- Harbor Debt Collection;
- Bell-Witness Activation;
- Drowned Guide Activation;
- Lighthouse Guardian Activation;
- Lifeboat Breaks Free;
- Bell Marks a Living Seat;
- Stable Seat Human Departure;
- Stable Seat Surrogate Activation;
- Stable Seat Human Takeover;
- Reserved Player Return;
- Spectator Enters Public View;
- Join Request Received;
- Public Ending Punctuation Family.

## Every brief declares

- governed asset ID;
- category and originality tier;
- priority and preproduction status;
- privacy and gameplay-information class;
- valid stages and trigger;
- purpose and duration budget;
- loop, spatial, and source-channel mode;
- presentation profiles;
- component layers;
- sonic requirements and negative constraints;
- mix priority, concurrency, variation, and dialogue-ducking behavior;
- caption, visual-redundancy, mono-safety, and reduced-dynamics requirements;
- generation prompt and consistency anchor;
- permitted source kinds and provenance records;
- explicit non-approval boundary.

## Validation

Validate all audio manifests together:

```bash
python tools/validate_preproduction_audio_assets.py
python tools/test_validate_preproduction_audio_assets.py
```

The validator rejects:

- duplicate asset IDs within or across manifests;
- category and ID-prefix mismatches;
- signature assets below Originality Tier A;
- production approval inside P0.4;
- invalid or reversed duration budgets;
- short ambience loops;
- critical cues without captions, visual redundancy, or mono safety;
- private audio represented on public spatial channels;
- ambience without dialogue ducking or reduced-density behavior;
- system cues that are spatialized or stereo-source dependent;
- imitation-oriented generation prompts;
- weak negative constraints;
- licensed-source records that claim unrestricted public distribution;
- licensed supporting or placeholder content defining signature sounds.

## Privacy boundary

P0.4 governs public and neutral system audio only.

Private roles, factions, objectives, bargains, latent transformations, takeover details, and controlled-reveal state must not be encoded into shared-speaker audio.

Private-surface audio remains deferred. Local play may not require headphones or private speakers.

## Generation and purchasing boundary

No audio should be generated, recorded, licensed, or purchased merely because a tool, bundle, or subscription is available.

Before a paid tool or library is used:

- a governed brief identifies the exact need;
- commercial-game rights are verified;
- public-repository and raw-source restrictions are understood;
- AI-input permissions are documented;
- the usable subset justifies the cost;
- cancellation, download, redemption, and preservation steps are recorded.

Potential tools may include original recording, local synthesis, Gemini where suitable, ElevenLabs Sound Effects, commissioned design, or licensed libraries. Tool selection is not production approval.

## Deferred work

P0.4 does not approve:

- final music or adaptive scoring;
- final Underteller voice or casting;
- recorded dialogue;
- final loudness or bus implementation;
- audio middleware or Godot import settings;
- television-speaker, headphone, surround, accessibility, or fatigue claims;
- production audio files;
- Drowned Harbor runtime integration.

Music is reserved for P0.5. Underteller voice production and recorded dialogue are reserved for a later separately governed package.
