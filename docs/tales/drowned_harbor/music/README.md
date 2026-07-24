# Drowned Harbor Music Preproduction

**Release stream:** P0.5
**Status:** Music direction and adaptive-score briefs only
**Tale status:** Design-only; Lantern House remains the sole production Tale
**Production music:** None approved

## Musical north star

Drowned Harbor should sound like **a damaged maritime memory trying to organize itself into a song before the tide removes the evidence**.

The score is designed to be:

- intimate rather than orchestral by default;
- cold and dreary without collapsing into one minor-key drone;
- rhythmically connected to bells, rope, tide, lens rotation, and page indexing;
- capable of long deliberate silence;
- adaptive only to authoritative public state;
- fully optional from a gameplay-information perspective;
- original-first and resistant to stock-horror or named-composer imitation.

The controlling direction is `Drowned_Harbor_Music_Direction_v1.md`.

The public-input and fail-closed selection rules are defined in `Drowned_Harbor_Adaptive_Music_State_Contract_v1.md`.

## Governed inventory

P0.5 currently defines **20 music briefs across two manifests**.

### Stage and adaptive system — 10 briefs

- Opening Invitation;
- Low-Tide Exploration Foundation;
- Salt Market Regional Color;
- Bellhouse Ledger Procedural Bed;
- Lighthouse Exterior Ascent;
- Lighthouse Council Decision Bed;
- High Water Post-Turn Adaptive Bed;
- Drowned Archive Truth Recovery;
- Last Light Decision Bed;
- Public Pressure Stem Family.

### Public forms and ending resolution — 10 briefs

- Public Bellmarked Reinterpretation;
- Public Tidebound Reinterpretation;
- Restless Continuation Color;
- Harbor Sealed Ending Treatment;
- Drowned Released Ending Treatment;
- Last Lifeboat Ending Treatment;
- Harbor Rises Ending Treatment;
- Light Comes Home Propagation Treatment;
- Names Erased Ending Treatment;
- Mixed Outcome Resolution.

## Adaptive public-state model

Shared music may respond only to normalized public state:

- stage;
- public pressure band;
- public truth band;
- public Bellhouse, lighthouse, Archive, and lifeboat states;
- coarse public route and rescue summaries;
- publicly revealed factions and forms;
- presentation profile;
- reduced-density and reduced-dynamics settings;
- dialogue, controlled-reveal, and confirmation state;
- deterministic music seed and phrase position.

Shared music must not read:

- hidden factions;
- private objectives;
- private bargains;
- latent transformations;
- unrevealed infections or marks;
- private inventory or route knowledge;
- hidden Director targets;
- pending private choices;
- future random outcomes;
- unrevealed ending carriers.

When state is missing or contradictory, music retains a safe legal cue, reduces to foundation, or becomes silent. It does not infer private state or choose the most dramatic option.

## Motif families

The package governs six provisional motif relationships:

- Harbor Memory;
- Lighthouse Destination;
- Bellhouse Index;
- Living Witness;
- Drowned Release;
- Harbor Propagation.

Motifs are not critical sound effects and do not communicate hidden information.

A stable seat's Living Witness color may survive public Bellmarked, Tidebound, or Restless transitions in altered instrumentation. Transformation changes musical context without implying removal of the seat or loss of agency.

## Stem architecture

Provisional stem families:

- `foundation`;
- `memory`;
- `witness`;
- `mechanism`;
- `pressure`;
- `transformation`;
- `resolution`.

No music stem may contain:

- a critical P0.4 sound effect;
- a required clue or warning;
- private role, objective, bargain, route, or transformation information;
- a hidden outcome cue.

Reduced-density mode removes optional stems while retaining musical sense. Music-off mode leaves gameplay fully understandable.

## Composition and generation boundary

Potential creation methods include:

- original human composition;
- original performance and synthesis;
- commissioned composition with explicit game rights;
- original AI-assisted composition with complete prompt, model, plan, and human-edit records;
- transformed licensed sources where terms explicitly permit the intended use.

Before any paid plan or generation batch:

- the exact governed brief is selected;
- output count and purpose are bounded;
- commercial game rights and post-cancellation rights are verified;
- Content ID and claims behavior are understood;
- public-repository and source-retention rules are recorded;
- named-composer and copyrighted-score imitation is prohibited;
- a human edit, stem extraction, and replacement plan exists.

No tool availability, subscription, bundle, or generated output constitutes production approval.

## Validation

Validate all music manifests together:

```bash
python tools/validate_preproduction_music_assets.py
python tools/test_validate_preproduction_music_assets.py
```

The validator rejects:

- duplicate IDs within or across manifests;
- category and ID-prefix mismatch;
- signature music below Originality Tier A;
- production approval inside P0.5;
- private or hidden state declared as a public music input;
- weak private-state exclusion boundaries;
- invalid duration or ending-loop behavior;
- critical sound effects inside music stems;
- broken reduced-density stem maps;
- music that cannot yield to dialogue or silence;
- required gameplay information encoded in music;
- imitation-oriented prompts;
- weak negative prompts or missing human-edit plans;
- Content ID registration;
- unsafe licensed-source distribution claims;
- licensed supporting or placeholder content defining signature music.

## P0.4 relationship

P0.4 remains authoritative for physical and critical sound effects.

Music must not replace:

- Bellhouse strikes;
- the unresolved extra ring;
- Ledger commits;
- lighthouse mechanism commits;
- route warnings;
- High Water Terror Turn SFX;
- transformations;
- seat-control confirmations;
- ending punctuation.

Music may begin only after the corresponding public state and P0.4 cue commit.

## Deferred work

P0.5 does not approve:

- final composition or recordings;
- final motifs, notation, instrumentation, tempo, meter, harmony, or key;
- final adaptive-selection logic;
- final stems, loops, mix, loudness, mastering, or middleware;
- Godot integration;
- Underteller voice interaction tuning;
- Content ID registration;
- television, headphone, mono, fatigue, or accessibility claims;
- production music files;
- Drowned Harbor runtime integration.

Candidate composition and human listening remain separate later packages.
