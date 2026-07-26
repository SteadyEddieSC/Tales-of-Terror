# Drowned Harbor development-only fixtures

Everything in this directory is synthetic, test-only, and excluded from ordinary Windows and Linux exports by the existing `tests/*` export rule.

## Current package

- `state_projection_fixture_schema_v1.json` — closed P0.14 fixture schema.
- `state_projection_fixtures_v1.json` — six deterministic fixtures bound to P0.11 interaction traces.

## Covered states

- Low Tide public action
- Bellhouse decision
- controlled-private Harbor bargain handoff
- High Water transformation
- Tidebound transformation
- invalid-action recovery

## Validation

From the repository root:

```bash
python tools/validate_drowned_harbor_projection_fixtures.py
python tools/test_validate_drowned_harbor_projection_fixtures.py
python tools/validate_drowned_harbor_prototype_isolation.py
python tools/test_validate_drowned_harbor_prototype_isolation.py
```

The projector is pure and data-driven. It creates canonical public/private projections and event sequences from synthetic source states. It does not implement gameplay, mutate a real session, consume RNG, register a Tale, create a provider, or authorize a playable export.

Drowned Harbor remains design-only. Lantern House remains the sole production Tale. Human validation remains required.
