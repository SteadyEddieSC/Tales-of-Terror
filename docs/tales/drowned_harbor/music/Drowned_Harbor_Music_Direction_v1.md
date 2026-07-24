# Drowned Harbor Music Direction

**Version:** 1.0
**Status:** P0.5 preproduction direction
**Tale status:** Design-only
**Production approval:** None
**Scope:** Musical identity, adaptive score states, motifs, instrumentation, transition rules, stems, silence, and music-candidate governance
**Deferred:** Final composition, final recordings, final mix, middleware or Godot implementation, voice interaction tuning, and human listening tests

## 1. Musical north star

Drowned Harbor should sound like **a damaged maritime memory trying to organize itself into a song before the tide removes the evidence**.

The score should feel:

- intimate rather than orchestral by default;
- old without becoming generic medieval or pirate music;
- cold, dreary, and emotionally colored without collapsing into one gray-brown drone;
- rhythmically connected to bells, rope, tide, lens rotation, and page indexing;
- capable of long quiet stretches;
- adaptive to public pressure and route state without revealing hidden roles, objectives, bargains, or unrevealed transformations;
- original enough that its central motifs cannot be mistaken for stock horror-library cues.

Music should not be continuously present merely because the system can play it.

## 2. Relationship to P0.4 sound design

P0.4 establishes the Tale's tactile audio world:

- water;
- timber;
- bells;
- rope;
- cloudy glass;
- damaged records;
- seat-control and public-state cues.

P0.5 must not duplicate those functions musically.

Rules:

- Bell strikes remain sound effects, not percussion loops.
- The unresolved extra ring remains a public Tale cue, not a secret musical motif.
- Rope strain and water routes remain environmental information, not hidden rhythm tracks.
- Music may borrow intervals, timing relationships, or timbral colors from the Bellhouse and lighthouse families, but may not replace their critical cues.
- Public score transitions occur only after authoritative public state changes.
- Private state never changes shared music before public revelation.

## 3. Core composition principles

### 3.1 Melody is scarce and meaningful

Most exploration music should use fragments, incomplete phrases, and restrained interval relationships.

Longer melodic statements belong to:

- opening invitation;
- first complete truth reveal;
- Last Light;
- selected ending resolutions;
- Chronicle-facing remembrance, if later approved.

A memorable theme should emerge through accumulation rather than begin fully formed.

### 3.2 Harmony should remain colored, not muddy

Avoid relying on one sustained minor drone.

Preferred harmonic behavior:

- open fifths with unstable added tones;
- narrow clusters that separate before masking speech;
- suspended intervals;
- pedal tones that change color through sparse upper voices;
- incomplete cadences;
- shifting modal centers;
- mirrored or overwritten phrases;
- occasional warm consonance that may be comforting or suspicious.

Avoid:

- constant low dissonance;
- featureless minor-key pads;
- generic horror chromatic clusters in every stage;
- heavy brass or sub-bass as the main tension tool;
- sentimental major-key release without narrative justification.

### 3.3 Rhythm comes from mechanisms and tide

Preferred rhythmic sources:

- asymmetric bell-spacing relationships;
- rope pull and release;
- slow lens indexing;
- page-turn interruption;
- tide advance and retreat;
- footsteps separated by unstable ground;
- repeated phrases with one absent or extra pulse.

The score should not become a clock that pressures players during ordinary decisions unless an explicit public timer is active.

### 3.4 Silence is a scored state

Silence may be the correct musical response during:

- private or controlled reveals;
- complex Council choices;
- accessibility-heavy text presentation;
- final confirmations;
- after a major Terror Turn;
- morally difficult rescue decisions;
- mixed ending attribution.

Silence must not be treated as a missing asset or implementation failure.

## 4. Musical material palette

The following palette is provisional and does not require literal historical instruments.

### 4.1 Primary identity instruments

- bowed or rubbed cloudy-glass textures;
- restrained harmonium or reed-organ breath;
- prepared upright piano or damped maritime piano fragments;
- low bowed strings in small ensembles;
- bowed metal and oxidized-brass resonances;
- plucked wire, rope-like string, or muted hammered string;
- frame drum or low skin used sparingly and without trailer weight;
- bass clarinet, contrabass clarinet, or similarly breathy low woodwind colors;
- small handbells or metal bowls transformed beyond stock usage;
- processed paper, page, and indexing textures used musically but not as critical SFX.

### 4.2 Secondary colors

- solo viola, cello, or nyckelharpa-like bowed texture without folk pastiche;
- thin flute or whistle air without sea-shanty character;
- distant pump organ color;
- soft analog or granular synthesis used to extend physical sources rather than create science-fiction atmosphere;
- restrained female, male, or mixed nonverbal human breath used only when licensing, privacy, and content rules are clear.

### 4.3 Avoid as dominant identity

- pirate fiddle;
- sea shanty rhythm;
- heroic orchestra;
- cinematic trailer percussion;
- gothic choir used as shorthand;
- music-box cliché;
- constant children’s choir;
- generic dark-ambient pad;
- recognizable commercial sample-library loops;
- culturally specific ritual instruments used without context or expertise;
- intelligible lyrics before a separately governed vocal-music review.

## 5. Motif families

Motifs are musical relationships, not direct copies of sound effects.

### 5.1 Harbor Memory Motif

**Function:** Represents the town's incomplete remembered identity.

Provisional shape:

- a short phrase of four positions;
- one position may be absent, delayed, or overwritten;
- the phrase can appear in several modes and registers;
- completion is reserved for truth or ending states.

The motif must not identify a hidden faction.

### 5.2 Lighthouse Destination Motif

**Function:** Represents direction, transmission, and where memory is being sent.

Behavior:

- rising or rotating interval relationship;
- clean upper register against slower lower mechanism;
- can turn inward, seaward, extinguish, or become carried;
- should remain distinguishable without becoming heroic.

### 5.3 Bellhouse Index Motif

**Function:** Represents names becoming part of the mechanism.

Behavior:

- measured repeated tones or attacks;
- one extra or missing temporal position;
- musical use remains subordinate to public Bellhouse SFX;
- never appears privately to identify Bellmarked allegiance.

### 5.4 Living Witness Motif

**Function:** Represents active human choice and mutual rescue.

Behavior:

- warmer but restrained interval color;
- fragile, incomplete, and transferable among instruments;
- may persist through Tidebound or Restless transformation in altered timbre;
- should not imply moral purity.

### 5.5 Drowned Release Motif

**Function:** Represents trapped residents separating from the Harbor mechanism.

Behavior:

- derived from Harbor Memory Motif but no longer rhythmically indexed;
- more air and vertical space;
- not automatically major, triumphant, or sentimental;
- full statement reserved for an eligible release ending.

### 5.6 Harbor Propagation Motif

**Function:** Represents the signal leaving the board.

Behavior:

- Lighthouse Destination Motif carried by an unfamiliar or displaced timbre;
- can sound beautiful before its danger is understood;
- public only after propagation is mechanically possible or revealed;
- never used to expose a hidden carrier early.

## 6. Adaptive score state model

The score responds to approved **public** aggregate state.

### 6.1 Stage layer

Exactly one primary stage identity is active:

- `low_tide_arrival`
- `bellhouse_ledger`
- `lighthouse_council`
- `high_water`
- `last_light`
- `ending_resolution`

### 6.2 Pressure layer

Provisional public pressure bands:

- `quiet`
- `watchful`
- `strained`
- `critical`

Pressure may derive from approved public aggregates such as:

- tide progression;
- public unresolved hazards;
- visible route loss;
- number of active rescue crises;
- public lighthouse or bell instability;
- public objective urgency;
- Director pressure level.

Pressure must not derive from:

- hidden faction count;
- private objectives;
- unrevealed infection;
- private bargain cost;
- latent transformation;
- private inventory;
- unannounced Director target selection.

### 6.3 Truth layer

Provisional public truth states:

- `obscured`
- `fragmented`
- `substantial`
- `complete`

Truth affects motif completeness and harmonic clarity, not raw loudness.

### 6.4 Mechanism layer

Approved public mechanism states may enable sparse overlays:

- Bellhouse active, silenced, damaged, or redirected;
- lighthouse active, extinguished, inland, seaward, or claimed;
- Archive closed, open, collapsing, or lost;
- lifeboat unavailable, preparing, ready, drifting, or launched.

These overlays must remain musically subordinate to corresponding critical SFX.

### 6.5 Social and faction layer

Shared music may respond only to **publicly revealed** faction or form states.

Examples:

- public Bellmarked reveal permits a public motif reinterpretation;
- public Tidebound transformation permits altered Living Witness timbre;
- Restless continuation may preserve a seat motif in another instrument family;
- unrevealed faction and private objective state have no shared-music authority.

## 7. Stage direction

### 7.1 Low-Tide Arrival

Music use:

- sparse or absent during initial orientation;
- fragments of Harbor Memory Motif;
- distant, incomplete pitch relationships;
- prepared piano, bowed glass, or low reed breath;
- room for mud, wind, and environmental SFX.

Emotional target:

- curiosity;
- melancholy;
- exposed scale;
- an invitation that feels prepared for the players.

Avoid:

- immediate full horror score;
- rhythmic urgency before danger exists;
- nautical adventure tone.

### 7.2 Bellhouse Ledger

Music use:

- measured indexing pulse with irregular absence or addition;
- paper, brass, and damped-string colors;
- motif fragments may become more legible as truth increases;
- silence before significant ledger votes or revelations.

Emotional target:

- procedural dread;
- recognition;
- moral unease;
- a system making space for the players.

### 7.3 Lighthouse Council

Music use:

- narrow and deliberate;
- Lighthouse Destination Motif appears in incomplete forms;
- reduced density during choices;
- glass, reed, and bowed-string colors;
- transition stingers reserved for committed public decisions.

Emotional target:

- authority;
- possibility;
- irreversible direction;
- not yet knowing which future is mercy.

### 7.4 High Water

Music use:

- increased motion through stem interaction, not simple tempo escalation;
- water-route rhythm, rope-like pulse, and altered motif registers;
- public Tidebound and Restless states may transform timbre;
- preserve dialogue and route SFX clarity;
- allow post-Terror-Turn silence before the adaptive bed enters.

Emotional target:

- active danger;
- divided priorities;
- changing geography;
- continuation under altered conditions.

### 7.5 Last Light

Music use:

- fewer active stems;
- longer motif statements only when public truth supports them;
- high sensitivity to dialogue ducking and silence;
- mechanism-specific colors according to public final options;
- no false promise of a good ending.

Emotional target:

- clarity;
- consequence;
- moral weight;
- several valid but costly endings.

### 7.6 Ending Resolution

Music use:

- separate from P0.4 nonmusical ending punctuation;
- short ending-family treatments rather than one universal victory theme;
- seat and faction attribution may occur before or during restrained tails;
- mixed outcomes preserve unresolved harmony or layered incompatible motifs;
- credits or Chronicle music is outside this package unless separately briefed.

## 8. Adaptive transition rules

### 8.1 Transition timing

Transitions should support:

- immediate cut to silence for critical dialogue;
- short crossfade for pressure changes;
- phrase-boundary transitions for stage or truth changes;
- authored stingers only after committed public state;
- recovery from paused or skipped narration;
- deterministic replay when given the same public state and music seed.

### 8.2 No musical premonition of hidden state

Music must not foreshadow hidden betrayal, private infection, a private bargain cost, or an unrevealed ending carrier unless the foreshadowing is explicitly public and mechanically fair.

### 8.3 Transition priority

Provisional priority:

1. silence for critical speech or controlled reveal;
2. committed stage or Terror Turn change;
3. committed ending state;
4. public mechanism transformation;
5. public pressure-band change;
6. public truth-band change;
7. noncritical regional color.

Lower-priority transitions may delay or be absorbed into higher-priority changes.

## 9. Stem architecture

A music cue may be authored as compatible stems.

Provisional families:

- `foundation` — harmonic identity and room tone;
- `memory` — Harbor Memory Motif fragments;
- `witness` — Living Witness material;
- `mechanism` — bell, lens, ledger, or route-derived musical texture;
- `pressure` — motion and tension without critical SFX duplication;
- `transformation` — publicly revealed form reinterpretation;
- `resolution` — truth or ending-specific material.

Rules:

- stems must be phase and length compatible where intended;
- each stem has a declared entry and exit behavior;
- no stem contains a critical one-shot SFX;
- no stem contains private information;
- reduced-density mode can remove stems without breaking musical sense;
- mono collapse must not erase critical rhythm or motif identity;
- music can stop cleanly without exposing an obvious missing loop.

## 10. Tempo and meter

No single fixed BPM is approved.

Preferred range:

- slow and moderate pulse relationships;
- flexible or breath-led timing in quiet stages;
- asymmetric phrase lengths;
- occasional measured indexing patterns;
- High Water motion through subdivision and layering rather than extreme tempo.

Avoid:

- dance-like groove;
- constant ticking;
- action-game combat tempo;
- sea-shanty meter;
- tempo-based urgency when no public timer exists.

## 11. Presentation profiles

Profiles preserve music structure and mechanics.

### Spooky

- clearer upper-register color;
- lighter texture density;
- softer dissonance;
- more audible paper, glass, and small acoustic detail;
- shorter or cleaner low tails;
- no childish or comedic instrumentation.

### Grim

- default harmonic tension;
- stronger low-mid string, reed, and bowed-metal color;
- cooler storm-pressure character;
- clear material separation rather than one dark drone;
- wider dynamic contrast only within approved reduced-dynamics limits.

### Gore & Dread

- retains Grim structure;
- permits localized breath, friction, and transformed-body timbre after public events;
- does not become louder simply because content is more explicit;
- no constant human suffering layer;
- no sexualized vocal material;
- no additional gameplay information.

## 12. Dialogue and local-conversation policy

Music must support a shared living-room game where players speak over the board.

Requirements:

- Underteller and plain-system speech remain intelligible;
- decision prompts create musical space;
- player conversation is not continuously competed with by dense midrange writing;
- repeated cues do not restart full phrases for every action;
- long dialogue does not leave a conspicuous loop seam;
- music may reduce to foundation or silence during discussion-heavy moments;
- no musical event requires headphones.

## 13. Accessibility and reduced stimulation

P0.5 must support future definitions for:

- music volume independent of dialogue and SFX;
- music-off mode without losing mechanics;
- reduced-density music;
- reduced-dynamics or night behavior;
- mono-safe core identity;
- captions not required for music-only emotional information;
- no required clue encoded in melody, harmony, or instrumentation;
- non-color-equivalent visual state remains authoritative.

Human listening tests remain required before making accessibility claims.

## 14. Original-first and licensing rules

Signature music defaults to:

- original human composition;
- commissioned composition with explicit game rights;
- original AI-assisted composition with complete prompt, tool, model, terms, and human transformation records;
- original performance or synthesis;
- licensed transformed sources only when source rights permit the intended transformation and game use.

Do not use:

- unmodified stock music as a signature Tale identity;
- subscription tracks whose post-cancellation project rights are unclear;
- content with unclear Content ID or claims risk;
- model outputs that imitate a named composer, performer, soundtrack, game, film, or living artist;
- third-party music as AI input without explicit permission;
- lyrics or identifiable voices without separate rights and content review.

## 15. AI and tool-use policy

Potential tools may include:

- human composition in a DAW;
- local instruments and synthesis;
- Google music-generation tools available under the owner's plan;
- ElevenLabs Music where terms and commercial rights fit the exact use;
- other generators only after current terms, export rights, Content ID behavior, and source retention are reviewed;
- licensed loops used only as transformed supporting sources where permitted.

Before any paid plan or generation batch:

- a governed cue or stem brief exists;
- output count and purpose are bounded;
- model and plan terms are recorded;
- commercial game use is allowed;
- attribution and Content ID behavior are understood;
- raw-source and public-repository rules are clear;
- cancellation does not invalidate already-created project use;
- a human-edit and replacement plan exists.

## 16. Candidate review criteria

A music candidate should be reviewed for:

- originality;
- Drowned Harbor identity;
- motif clarity without overstatement;
- ability to remain quiet;
- speech and conversation masking risk;
- stage and pressure fit;
- loop and transition potential;
- absence of hidden-state leakage;
- mono and reduced-density resilience;
- fatigue risk;
- distinction from generic dark ambience;
- licensing and provenance completeness;
- editability into stems or alternate states;
- compatibility with P0.4 SFX families.

## 17. First-wave music briefs

P0.5 should govern at least:

- opening invitation;
- Low-Tide exploration foundation;
- Salt Market regional color;
- Bellhouse Ledger procedural bed;
- lighthouse exterior ascent;
- Lighthouse Council decision bed;
- High Water post-turn adaptive bed;
- Drowned Archive truth-recovery cue;
- Last Light decision bed;
- pressure stem family;
- public Bellmarked reinterpretation;
- public Tidebound reinterpretation;
- Restless continuation color;
- Harbor Sealed ending treatment;
- Drowned Released ending treatment;
- Last Lifeboat ending treatment;
- Harbor Rises treatment;
- Light Comes Home propagation treatment;
- Names Erased treatment;
- mixed-outcome resolution.

## 18. Human review questions deferred

When listening becomes available, evaluate:

- whether music is memorable without becoming repetitive;
- whether the Harbor sounds original rather than generically nautical or gothic;
- whether cold and dreary color remains distinct rather than muddy;
- whether dialogue and local discussion stay intelligible;
- whether silence feels intentional;
- whether adaptive transitions are noticeable in a good way;
- whether hidden roles remain musically private;
- whether pressure rises without manipulating players unfairly;
- whether endings feel distinct without declaring simplistic victory or defeat;
- whether loops cause fatigue over a full Tale;
- whether music-off, mono, and reduced-density modes remain coherent.

No automated validation substitutes for these listening tests.

## 19. Approval boundary

This document does not approve:

- final composition;
- final motifs or notation;
- final instrumentation;
- final tempo, meter, key, mode, or harmony;
- final adaptive logic;
- final mix, loudness, mastering, or stems;
- any AI-generated or licensed candidate as production music;
- Content ID registration;
- final Underteller interaction tuning;
- music accessibility or listening-fatigue claims;
- Drowned Harbor runtime integration;
- a second production Tale.
