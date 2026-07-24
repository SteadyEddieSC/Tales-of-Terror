# Localization, Captions, and Accessible Narrative Direction

**Version:** 1.0
**Status:** P0.7 preproduction direction
**Scope:** Source text, localization readiness, subtitles, closed captions, transcripts, plain-system presentation, screen-reader announcements, reading order, and accessible narrative controls
**Production approval:** None

## 1. Core principle

**Narrative information must survive the loss of voice, music, sound effects, color, animation timing, and English word order.**

A player must be able to understand the current state, legal choices, consequences, ownership, and public narrative result through persistent text and non-audio presentation.

Localization and accessibility are authored properties of every narrative unit. They are not export-time transformations applied after final writing.

## 2. Source-of-truth hierarchy

For mechanically meaningful narrative content:

1. authoritative game state;
2. mechanical-equivalence key;
3. plain-system source text;
4. profile-specific character text;
5. recorded or synthesized voice;
6. captions and transcript generated from the governed source unit;
7. visual flourish and animation.

Lower layers may not contradict higher layers.

The plain-system source is the clearest textual statement of the mechanic. It is not merely a transcript of the most theatrical line.

## 3. Stable text identity

Use stable IDs rather than English source strings as keys.

A localized narrative unit should retain:

- stable unit ID;
- source family or event ID;
- mechanical-equivalence key;
- source locale;
- profile and presentation role;
- privacy class;
- speaker key;
- source text version;
- placeholder definitions;
- translator notes;
- caption and transcript behavior;
- screen-reader announcement behavior;
- review and approval state.

Renaming the game, Tale, host, location, role, or item must not require replacing stable IDs.

## 4. Source locale

The provisional authoring locale is `en-US`.

This does not mean:

- United States idiom should dominate the world;
- other English variants are unnecessary;
- English word order may be embedded in code;
- punctuation, plural, gender, number, or date formats are universal;
- English text length defines layout.

English source copy should be written for translation:

- direct subject and action;
- limited ambiguous pronouns;
- no string concatenation;
- no hidden meaning carried only by wordplay;
- short metaphors around, not instead of, mechanical facts;
- consistent terminology;
- named placeholders with full context.

## 5. Named placeholders

Use named placeholders, never positional fragments or sentence concatenation.

Preferred examples:

```text
{seat_name}
{location_name}
{route_name}
{item_name}
{count}
{faction_name}
{form_name}
{stage_name}
{action_name}
{controller_name}
```

Rules:

- placeholders represent complete semantic units;
- translators receive type and meaning notes;
- articles, prepositions, gender, case, and plural grammar remain localizable;
- a placeholder may not inject markup or another untranslated sentence;
- private placeholders may not enter a public unit;
- runtime values require localized display names, not internal IDs;
- sentence fragments may not be assembled from separately translated words.

## 6. Plural, gender, and pronouns

Source units should support language-aware plural and grammatical variation.

Do not assume:

- singular versus plural can be handled by adding `s`;
- a stable seat maps to a person's gender;
- controller account identity provides pronouns;
- role names have one grammatical form;
- neutral English pronouns translate directly.

When a player-provided name or pronoun cannot be declined safely, prefer sentence structures that avoid unsupported grammatical assumptions.

Narrative mechanics must not require a player to disclose gender or pronouns.

## 7. Terminology governance

Maintain a localizable terminology register for:

- stable seat;
- human control;
- game control;
- takeover;
- return;
- public and private state;
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
- Drowned Archive;
- Tale and stage concepts.

Each term should declare:

- source definition;
- player-facing meaning;
- words to avoid;
- capitalization behavior;
- whether it is provisional;
- pronunciation note where relevant;
- whether it may be shortened in constrained UI;
- grammatical notes for translators.

Working names remain localizable and provisional. Translation does not confer legal clearance.

## 8. Subtitle and caption distinction

### Subtitles

Represent spoken words.

### Closed captions

Represent spoken words plus meaningful non-speech audio such as:

- bell events;
- route failure;
- water entering a street;
- lighthouse mechanism movement;
- a mooring under strain;
- seat-control handoff confirmation.

Settings may allow:

- speech subtitles only;
- full closed captions;
- captions off;
- speaker labels on or off;
- background opacity;
- text scale;
- line spacing;
- caption position preference where layout permits;
- sound-direction indicators only as supplemental information.

Critical information remains visually represented outside captions.

## 9. Caption composition targets

Provisional internal targets:

- no more than two displayed lines at once;
- target up to 42 characters per line where language permits;
- prefer natural phrase and sentence boundaries;
- avoid splitting names, articles from nouns, negation from verbs, or numerical values from units;
- target readable pacing rather than exact voice synchronization;
- minimum ordinary display near 1.5 seconds;
- ordinary timed segment generally no longer than 7 seconds;
- critical instructions persist through the decision or remain available in the transcript;
- player-controlled replay is always available for governed critical lines.

These are design targets, not a claim of compliance with a particular external standard. Human testing and language-specific review may change them.

## 10. Caption styling

Captions should:

- use a high-contrast configurable background;
- remain distinct from decorative Tale typography;
- avoid all-caps paragraphs;
- avoid color as the only speaker identifier;
- preserve readable punctuation;
- use italics sparingly and never as the sole signal of private, supernatural, or off-screen speech;
- avoid animated letter-by-letter reveals for critical content;
- avoid shaking, distortion, blur, or fading that harms reading;
- remain visible above safe-area and controller-prompt conflicts;
- support enlarged text without clipping or loss of choices.

The storybook-horror style may frame captions, but must not deform the text.

## 11. Speaker labels

Speaker identity uses localizable keys.

Until legal naming is resolved, internal speaker keys may include:

- `speaker.host`;
- `speaker.system`;
- `speaker.harbor`;
- `speaker.bellhouse`;
- `speaker.lighthouse`;
- `speaker.public_seat`.

The displayed label may later be “The Underteller,” another cleared name, “Host,” or a localized equivalent.

Speaker identity may not depend only on color, screen position, or voice timbre.

## 12. Non-speech sound captions

A meaningful sound caption should describe what is publicly perceivable without revealing its hidden cause.

Preferred:

- `[A bell rings once beyond the visible count.]`
- `[Water enters the lower street.]`
- `[The lifeboat mooring strains.]`
- `[The lighthouse lens begins to turn.]`
- `[Human control ends; the stable seat remains.]`

Avoid:

- `[The hidden traitor rings the bell.]`
- `[Your private objective is failing.]`
- `[The correct route opens.]`
- `[A Bellmarked player approaches.]`

Direction may be included when public and useful, but cannot be the sole locator.

## 13. Transcript and history

Governed narrative and critical system text should be available in a session transcript or event history.

Each entry should preserve:

- localized timestamp or sequence position;
- speaker label;
- source unit ID in diagnostics, not ordinary player text;
- rendered public text;
- associated stage or event label;
- replay availability;
- whether the line was interrupted;
- current versus historical status where needed.

The transcript must not collect private text into a public history.

Private companion or controlled-reveal content requires a separate private history policy.

## 14. Persistent critical text

Critical instructions should not disappear because voice playback ended.

Persistent content includes:

- current legal options;
- confirmation consequences;
- route instability and response window;
- transformed-board rules;
- public form and continuation rules;
- seat-control state;
- public ending attribution;
- recovery instructions after invalid or unavailable actions.

Persistence ends when:

- the relevant state changes;
- the player dismisses a non-blocking information panel;
- a newer authoritative instruction replaces it;
- the session ends.

## 15. Screen-reader and announcement behavior

A future accessible UI should separate visual text updates from announcement priority.

Provisional announcement classes:

- `none` — decorative or repeated text;
- `polite` — stage recap, public status update, nonurgent control change;
- `assertive` — imminent public hazard, invalid action requiring correction, confirmation consequence;
- `focus_required` — a new decision or controlled panel receives explicit navigation focus, not merely a live announcement.

Rules:

- do not announce every ambient or decorative update;
- do not interrupt critical speech with lower-priority text;
- repeated public state should coalesce;
- a control handoff announcement remains neutral;
- private content never enters a public live region;
- focus order must match the logical decision sequence;
- controller-first navigation and accessible focus are both required in later implementation.

## 16. Reading order

For a decision panel, logical order should generally be:

1. context or stage label;
2. current public state;
3. question or required action;
4. legal choices;
5. consequence preview;
6. confirmation or cancel controls;
7. help, replay, transcript, or details.

Decorative lore should not precede the required action in assistive reading order.

## 17. Controller-first accessible behavior

Accessible presentation must preserve controller-first local play.

Requirements for later implementation:

- visible and programmatic focus;
- deterministic focus order;
- no pointer-only interaction;
- no hover-only explanation;
- replay and transcript reachable without abandoning the active decision;
- text-scale changes do not move essential controls off-screen;
- simultaneous local seats do not fight for inaccessible focus;
- active-seat ownership remains public and understandable;
- private companion content does not leak onto the shared display.

## 18. Profile equivalence

Spooky, Grim, and Gore & Dread variants may change:

- explicitness;
- imagery;
- bodily detail;
- threat texture;
- humor intensity.

They may not change:

- public facts;
- legal choices;
- objective state;
- timing windows;
- severity of mechanical consequence;
- privacy class;
- speaker authority;
- required placeholders.

The mechanical-equivalence key binds the variants.

## 19. Plain-language mode

A future plain-language setting may prefer plain-system or reduced-flavor text for mechanically meaningful content.

Plain-language presentation should:

- retain all facts and choices;
- use shorter sentences;
- state cause and consequence directly;
- avoid metaphor before the instruction;
- preserve Tale names and necessary terminology with glossary help;
- remain atmospheric through surrounding art and sound rather than unclear wording.

Plain language is not a “child mode” and must not be patronizing.

## 20. Pseudolocalization

Before human translation, run bounded pseudolocalization that tests:

- text expansion;
- accented Latin characters;
- mixed-width glyphs;
- long unbroken names;
- placeholder preservation;
- mirrored or right-to-left layout simulation;
- punctuation movement;
- multiline captions;
- transcript and decision-panel overflow;
- font fallback and missing-glyph behavior.

Pseudolocalization does not prove translation quality or full right-to-left support.

## 21. Right-to-left readiness

Preproduction contracts should avoid choices that block future RTL support.

Plan for:

- mirrored reading order where appropriate;
- logical rather than physical left/right terminology in code;
- isolated bidirectional placeholders;
- icons that do not embed directional English text;
- speaker labels and timestamps that reorder safely;
- controller prompts that remain understandable after mirroring;
- maps and routes that do not automatically mirror when geography must remain stable.

Final RTL behavior requires native-language and implementation testing.

## 22. Fonts and glyphs

The project must not rely on a decorative display face for captions or critical UI.

A later font plan should establish:

- readable UI and caption families;
- broad script coverage or governed fallbacks;
- consistent numeral and punctuation support;
- font licensing for game distribution;
- scalable metrics;
- fallback behavior that does not expose missing-glyph boxes;
- no sharing of font files outside licensed distribution paths.

P0.7 does not select or distribute font files.

## 23. Translation workflow

Provisional workflow:

1. freeze the source unit version for a translation batch;
2. export stable IDs, source text, placeholders, notes, privacy, speaker, and screenshots or context;
3. translate through a governed human or reviewed machine-assisted process;
4. preserve placeholders and markup;
5. perform linguistic review;
6. perform in-context review;
7. run pseudolocalization and automated structural checks;
8. review profile equivalence and mechanical meaning;
9. test captions, transcript, focus, and overflow;
10. record disposition and unresolved risks.

Machine translation may assist drafts but cannot approve mechanical or privacy-sensitive text without qualified review.

## 24. Translator context

Every unit should explain:

- who speaks;
- who can read it;
- what public state triggered it;
- what the line must communicate;
- what it must not imply;
- placeholder meanings;
- whether humor or wordplay matters;
- profile differences;
- maximum practical space;
- whether text persists, captions speech, or appears in a transcript;
- related terminology.

A translator should not need to infer mechanics from one English sentence.

## 25. Privacy in localization assets

Public localization exports may include public source text and context.

They must not include:

- hidden role assignments;
- production player data;
- private session content;
- personal contact information;
- confidential performer contracts;
- unreleased credentials or service configuration;
- restricted raw voice files.

Private narrative units require restricted handling and a separate export policy.

## 26. Automated validation targets

A future validator should reject:

- missing stable IDs;
- duplicate units;
- missing plain-system source;
- unknown source-family references;
- missing mechanical-equivalence keys;
- public units marked with private source inputs;
- unnamed or undocumented placeholders;
- concatenated sentence fragments;
- captions without transcript behavior for critical lines;
- critical text that is timed-only or not replayable;
- uncaptioned mechanically meaningful audio;
- profile variants with different placeholder sets;
- active private announcements on public channels;
- production approval inside preproduction packages.

## 27. Human testing deferred

When implementation and translated content exist, evaluate:

- television-distance readability;
- text-scale and reflow;
- caption speed and segmentation;
- transcript usability;
- controller and assistive focus order;
- low-vision contrast and background controls;
- deaf and hard-of-hearing comprehension;
- voice-off and music-off completeness;
- plain-language usefulness;
- pseudolocalized and translated overflow;
- right-to-left behavior;
- repeated-prompt fatigue;
- privacy safety on shared screens.

No schema or automated validator substitutes for this testing.

## 28. Approval boundary

This document does not approve:

- final source copy;
- any translated locale;
- a localization vendor or machine-translation service;
- final caption speed, styling, layout, or font;
- final transcript or assistive-technology implementation;
- final right-to-left behavior;
- accessibility compliance claims;
- Drowned Harbor runtime integration;
- a second production Tale.
