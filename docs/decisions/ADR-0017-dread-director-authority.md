# ADR-0017: Dread Director authority, telemetry, and fairness

- **Status:** Accepted
- **Date:** July 12, 2026

## Context

Pacing adaptation must be reproducible, inspectable, and fair without letting a presentation system cheat, inspect future random results, or mutate authoritative gameplay dictionaries. It must remain useful offline and cannot depend on a cloud service, language model, personal profile, or wall-clock surveillance.

## Decision

The Dread Director is a local, scene-independent evaluator over validated authored profiles and intervention candidates. `DirectorTelemetry` copies and normalizes approved observations from `RulesSession` and `BoardState`; it never retains device identities or mutates either authority. `DirectorRuntime` owns only pacing state, budgets, cooldowns, repetition history, targeting history, mercy/recovery state, a bounded audit, and a separately salted deterministic RNG.

The Director emits an immutable decision/proposal record. It does not hold gameplay authority. `DirectorProposalApplier` is the explicit boundary that submits rules work to public `RulesSession` transactions, board work to `BoardState.apply_mutation`, or presentation cues to a replaceable host/ambient consumer. Rejected applications are atomic and audited. Accepted applications advance the Director revision and downstream revision record.

Every candidate is scored through generic category, tag, condition, budget, tension, telemetry, fairness, mercy, cooldown, and repetition vocabulary. Generic runtime and presentation code may not branch on a literal candidate ID. Empty, zero-score, invalid, cooled-down, or unfair sets select the authored no-op.

Pressure is bounded by budgets and a rolling pressure cap. Disconnected seats cannot receive negative targeting. A per-seat rolling cap prevents repeated targeting, failure/resource-pressure activates mercy, and severe pressure opens a recovery window. These rules protect pacing and recoverability; they do not secretly guarantee victory.

## Consequences

Director enablement cannot change deck/check RNG. A versioned in-memory Director snapshot reproduces the next decision without restoring or mutating `RulesSession` or `BoardState`. Fixed and reduced-volatility profiles are authored data. Presentation profile remains gameplay-equivalent and independent.

Roles, factions, afterlife, combat, networking, companion replication, campaign persistence, procedural generation, final balance, and any AI/LLM experiment remain separate future work.
