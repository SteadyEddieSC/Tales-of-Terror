# ADR-0010-git-lfs-timing — Defer Git LFS until large source assets begin

- **Status:** Accepted for foundation
- **Date:** July 11, 2026

## Context

The foundation contains mostly text plus a few small binary reference/export files. Requiring Git LFS before the first push would add setup friction without solving an immediate size problem.

## Decision

Commit the v0.0.1 foundation without LFS filters. Install Git LFS on the Windows 11 workstation and add tested patterns in a dedicated pull request no later than v0.0.3 Visual Language Lab, before regular PSD/KRA/BLEND, lossless audio, video, or very large texture commits.

## Consequences

The initial push remains simple. A few early binary files remain in normal Git history, which is acceptable at their current size. Large future binaries must not be committed until the LFS policy is active.
