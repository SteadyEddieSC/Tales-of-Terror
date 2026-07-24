# Drowned Harbor Governed Dialogue Corpus

**Release stream:** P0.2
**Status:** Preproduction content and tooling; not runtime localization
**Locale:** `en-US`
**Tale status:** Design-only; Lantern House remains the sole production Tale

## Contents

The corpus currently contains 104 unique governed dialogue entries across seven catalog files:

- foundation, stage, Director, continuity, and core ending dialogue;
- encounter and Council dialogue;
- item, resource, and hazard dialogue;
- faction, afterlife, replacement, and seat-attributed ending dialogue;
- Bellmarked, Tidebound, and Harbor-bargain private dialogue;
- multiplayer admission, reservation, spectator, removal, and host-transition dialogue;
- controlled private handoffs, additional endings, and card-result dialogue.

Every entry declares:

- a stable key;
- function and privacy classification;
- authorized trigger;
- required mechanical facts;
- Spooky, Grim, and Gore & Dread variants;
- a plain fallback;
- display and voice budgets;
- repetition policy;
- governed placeholders;
- implementation status.

## Validation

Run all catalog, cross-file, privacy, placeholder, and budget checks:

```bash
python tools/validate_preproduction_dialogue.py \
  docs/tales/drowned_harbor/dialogue/drowned_harbor_dialogue*.json
python tools/test_validate_preproduction_dialogue.py
```

The GitHub workflow discovers every matching Drowned Harbor catalog automatically and rejects duplicate keys across files.

## Voice audition export

Validate the curated 24-selection Underteller audition manifest:

```bash
python tools/export_preproduction_voice_audition.py --check
```

Create local CSV and Markdown handoff files for Gemini, ElevenLabs, or human recording:

```bash
python tools/export_preproduction_voice_audition.py \
  --output-dir build/preproduction/voice-audition
```

Generated exports are local working outputs and are not committed automatically.

## Privacy boundary

Public dialogue may use only public-safe placeholders. Controlled private handoffs may use governed private values only on authorized private surfaces. The voice-audition manifest excludes controlled-private and diagnostic-only material.

## Approval boundary

This corpus does not approve:

- final localization;
- final voice casting;
- recorded production audio;
- runtime integration;
- a Drowned Harbor production Tale package;
- gameplay or balance changes;
- human-playtest conclusions.
