# Drowned Harbor Adaptive Music State Contract

**Version:** 1.0
**Status:** P0.5 preproduction contract
**Tale status:** Design-only
**Production approval:** None

## 1. Purpose

This contract defines which authoritative **public** Tale states may influence shared music and which private states are forbidden.

Music is presentation. It does not own gameplay state, resolve actions, predict hidden outcomes, or replace sound effects, captions, prompts, route indicators, or controlled reveals.

## 2. Authoritative input model

A music decision may read only a normalized public snapshot:

```text
MusicPublicSnapshot
  stage
  pressure_band
  truth_band
  public_mechanism_states
  public_route_summary
  public_rescue_summary
  public_revealed_forms
  public_revealed_factions
  presentation_profile
  reduced_density_enabled
  reduced_dynamics_enabled
  dialogue_active
  controlled_reveal_active
  critical_confirmation_active
  music_seed
```

No music cue may query raw private seat state.

## 3. Stage state

Exactly one stage is active:

- `low_tide_arrival`
- `bellhouse_ledger`
- `lighthouse_council`
- `high_water`
- `last_light`
- `ending_resolution`

Stage changes have higher transition priority than pressure, truth, or regional color.

## 4. Pressure bands

Allowed public pressure bands:

- `quiet`
- `watchful`
- `strained`
- `critical`

Pressure may be calculated from public aggregates such as:

- visible tide progression;
- unresolved public hazards;
- visible route reduction;
- public rescue crises;
- public lighthouse or Bellhouse instability;
- public objective urgency;
- public Director pressure.

Pressure may change texture, subdivision, stem density, register, and harmonic tension.

Pressure may not:

- accelerate a non-timed decision as though a timer exists;
- reveal a hidden target;
- imply defeat before an authoritative result;
- replace a warning cue;
- become louder as its primary distinction.

## 5. Truth bands

Allowed public truth bands:

- `obscured`
- `fragmented`
- `substantial`
- `complete`

Truth affects:

- motif completeness;
- phrase continuity;
- harmonic clarity;
- instrumentation transparency;
- eligibility for longer melodic statements.

Truth does not certify that one interpretation, faction, or ending is morally correct.

## 6. Public mechanism states

Music may respond to normalized public states for:

### Bellhouse

- `inactive`
- `active`
- `silenced`
- `damaged`
- `redirected`

### Lighthouse

- `inactive`
- `active_inland`
- `active_seaward`
- `extinguished`
- `claimed`
- `damaged`

### Archive

- `closed`
- `open`
- `collapsing`
- `lost`

### Lifeboat

- `unavailable`
- `preparing`
- `ready`
- `drifting`
- `launched`
- `lost`

Mechanism overlays remain subordinate to P0.4 critical sound effects. A musical layer may begin only after the public state commits.

## 7. Public route and rescue summaries

Music may read coarse public summaries such as:

- count of publicly open land routes;
- count of publicly open water routes;
- count of visible unstable routes;
- count of active public rescue crises;
- public escape-capacity band;
- public unresolved item-recovery count.

Music must not encode exact route answers, optimal paths, private item locations, hidden beneficiaries, or unrevealed rescue outcomes.

## 8. Revealed forms and factions

Shared music may respond only after public commitment.

Allowed examples:

- publicly revealed Bellmarked allegiance;
- public Tidebound transformation;
- public Bell-Witness continuation;
- public Drowned Guide continuation;
- public Lighthouse Guardian continuation.

The score may reinterpret a stable-seat motif through timbre or register. It may not erase the original seat's musical identity or imply loss of agency.

## 9. Forbidden inputs

The following inputs are prohibited from shared music before public revelation:

- hidden faction assignments;
- private objectives;
- private bargain terms or costs;
- latent transformation eligibility;
- unrevealed infection or mark state;
- private inventory;
- private route knowledge;
- hidden Director targets;
- private companion-device selections;
- pending uncommitted choices;
- future random outcomes;
- unrevealed ending carriers;
- player identity inferred from controller, network, account, or voice data.

A validator should reject any music brief whose declared public inputs contain these concepts.

## 10. Silence authority

Music must yield immediately when any of the following are true:

- `controlled_reveal_active`;
- critical plain-system speech requires full clarity;
- an authored confirmation requires silence;
- a stage transition explicitly calls for post-event silence.

During ordinary Underteller speech, cues may duck, reduce to foundation, or cut to silence according to their brief.

Silence is a valid deterministic score state.

## 11. Transition priority

Highest to lowest:

1. controlled reveal or critical-speech silence;
2. committed stage change;
3. committed ending result;
4. committed public mechanism transformation;
5. public revealed-form or faction change;
6. pressure-band change;
7. truth-band change;
8. regional color change.

Lower-priority transitions may be delayed, absorbed, or omitted when a higher-priority event occurs.

## 12. Determinism

Given the same:

- public snapshot;
- active cue family;
- music seed;
- prior phrase position;
- presentation profile;
- accessibility settings;

…the score selector must choose the same eligible cue, stem set, and transition class.

Determinism does not require identical rendered audio when a later production system intentionally uses bounded humanized performance variation. Such variation must not change musical meaning or gameplay information.

## 13. Stem eligibility

Provisional stems:

- `foundation`
- `memory`
- `witness`
- `mechanism`
- `pressure`
- `transformation`
- `resolution`

Rules:

- `foundation` may remain when density reduces;
- `pressure` is never the only active stem;
- `transformation` requires a public revealed-form state;
- `resolution` requires substantial or complete public truth, Last Light, or committed ending state;
- no stem contains critical SFX;
- no stem contains private-state cues;
- reduced-density mode removes optional stems without breaking phrase or harmony;
- music-off mode leaves mechanics fully understandable.

## 14. Profile behavior

Presentation profiles may alter:

- instrumentation density;
- dissonance texture;
- physical breath or friction detail;
- register;
- decay length;
- transformed-body timbre after public revelation.

Profiles may not alter:

- cue eligibility;
- mechanical timing;
- hidden-state access;
- objective information;
- transition priority;
- success or defeat rules.

## 15. Ending-state inputs

Ending music may read only the committed public ending family and public attribution data.

Provisional ending families:

- `harbor_sealed`
- `drowned_released`
- `last_lifeboat`
- `harbor_rises`
- `light_comes_home`
- `names_erased`
- `mixed_outcome`

No ending cue may flatten seat-by-seat or faction-specific outcomes into one universal victory or defeat.

## 16. Fail-closed behavior

When music state is missing, contradictory, or unsupported:

- do not infer private state;
- do not select a more dramatic cue;
- retain the current legal cue if safe;
- otherwise reduce to foundation or silence;
- log a diagnostic outside the player-facing mix;
- preserve gameplay progression.

## 17. Approval boundary

This contract does not approve final adaptive logic, music runtime implementation, middleware, Godot integration, transition timing, mix behavior, generated music, final motifs, or human listening claims.
