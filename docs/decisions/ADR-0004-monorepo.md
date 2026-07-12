# ADR-0004-monorepo — Use one public monorepo

- **Status:** Accepted for foundation
- **Date:** July 11, 2026

## Context

The project needs coordinated code, docs, art metadata, services, testing, and release operations. The owner is comfortable with public visibility during pre-production.

## Decision

Game, docs, companion, services, tools, art metadata, and release operations remain in `SteadyEddieSC/Tales-of-Terror` until a clear operational need justifies a split. The repository is public, but visibility does not replace an explicit license.

## Consequences

Public Actions minutes are not billed for standard GitHub-hosted runners, collaboration is easier, and the work is visible. Sensitive credentials, licensed assets, private playtest data, and signing material must never enter the repository.
