# ADR-0001-engine-and-version — Use Godot 4.7 stable

- **Status:** Superseded for patch pinning by ADR-0020; Godot 4.7 remains the feature family
- **Date:** July 11, 2026

## Context

The project needs a stable, explainable foundation before gameplay scope expands.

## Decision

Godot 4.7 stable was the foundation engine pin. Do not use 4.8 development builds for production work. Typed GDScript is primary. ADR-0020 advances the maintenance pin to 4.7.1-stable without changing the feature family.

## Consequences

This decision should be revisited only with measured evidence and a replacement plan.
