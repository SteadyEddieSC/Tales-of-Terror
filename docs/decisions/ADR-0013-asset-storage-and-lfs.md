# ADR-0013: Asset storage boundaries and Git LFS activation

- **Status:** Accepted
- **Date:** July 12, 2026

## Context

The visual-language milestone begins reusable production assets. Large layered masters and lossless media would bloat ordinary Git history, while placing all binaries in LFS would add needless friction for modest runtime assets. Milestone packages and downloadable document snapshots are delivery artifacts rather than source.

## Decision

Activate Git LFS for the reviewed editable visual, lossless audio, and production video patterns in .gitattributes. Keep code, Godot text resources, documentation, metadata, and modest runtime assets in normal Git. Store builds, milestone bundles, large review deliveries, and polished downloadable snapshots as tagged GitHub Release attachments.

Separate editable masters (art/source and audio/source) from Godot-ready derivatives (game/assets). Require provenance metadata for generated and third-party runtime binaries. Validate LFS attributes and provenance statically without adding test binaries.

## Consequences

Clones remain small while editable history stays versioned. Contributors need Git LFS before working with tracked source formats. Runtime assets remain easy to diff and retrieve when reasonably sized. Release attachments are not canonical source and must be reproducible or traceable to a tagged commit.

ADR-0010's deferral ends with this decision.
