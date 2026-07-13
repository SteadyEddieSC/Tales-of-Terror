# Authored Rules Content Schema

Authored rules content is trusted, reviewable data created in `LanternHouseRulesContent`. It cannot load scripts or execute arbitrary code.

## Event example

```gdscript
{
  "id": "threshold_whisper", "version": 1,
  "title": "The Threshold Whispers", "body": "…",
  "conditions": [{"type": "always"}],
  "prompts": [{
    "id": "choose_path", "scope": "single", "seat": 1,
    "options": [{"id": "listen", "text": "Listen", "symbol": "◉"}],
    "min_selections": 1, "max_selections": 1, "allow_pass": false
  }],
  "effects": [{
    "type": "board_mutation",
    "mutation": {"type": "set_connector_state", "connector_id": "hall_gate", "state": "open"}
  }],
  "follow_ups": ["gallery_council"],
  "presenter": {"speaker_key": "scenario_host", "mode": "story", "tone": "hushed"}
}
```

## Card example

```gdscript
{
  "id": "iron_resolve", "version": 1, "tags": ["reaction"],
  "conditions": [{"type": "phase_is", "phase": "player_decision"}],
  "target_count": 0, "policy": "exhaust",
  "effects": [{"type": "add_counter", "counter_id": "resolve", "value": 1}]
}
```

Stable IDs are lowercase snake_case and independent of display text. Supported conditions are `always`, `flag_equals`, `counter_at_least`, `seat_has_item`, and `phase_is`. Supported effects are documented in the engine guide and enforced by `RulesContent.VALID_EFFECTS`. Card policies are `discard`, `exhaust`, `retain`, and `remove`.

Validation rejects duplicate/malformed identities, unsupported vocabulary, missing event/card/board references, impossible prompt selection counts, invalid policies, and obvious follow-up recursion. Runtime event-chain depth is additionally capped at 16.
