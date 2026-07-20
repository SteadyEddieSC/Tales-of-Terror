# Terror Turn — GitHub & Cloudflare Project Launch Guide

**Version:** 0.2  
**Date:** July 11, 2026

## Current repository

- Account: `SteadyEddieSC`
- Repository: `SteadyEddieSC/Tales-of-Terror`
- Visibility: public
- Default branch: `main`
- Preferred merge method: squash
- Protect main ruleset: keep **Disabled** until the foundation commit and first repository check exist

The repository name remains temporary until the Terror Turn name receives a careful trademark, storefront, domain, and common-law review.

## Stack

- Public GitHub monorepo, `main` plus short-lived branches, squash merges.
- Official Godot 4.7.1-stable, 960×540, Compatibility renderer, typed GDScript.
- Cloudflare companion services later: Workers/Pages, Durable Objects, D1, R2, optional KV/config, Turnstile.
- Native host authority first; companion and hidden-information rooms before full remote game clients.

## Git LFS timing

Git LFS is **not required** for the initial v0.0.1 foundation push. The current source files, concept PNG, and DOCX exports are comfortably below GitHub’s normal per-file limit.

Install and activate LFS before large editable art/audio enters regular development—target **no later than v0.0.3 Visual Language Lab**. Track files such as PSD, KRA, BLEND, WAV, FLAC, large video, and exceptionally large textures. Do not put every small PNG or build artifact in LFS.

The current `.gitattributes` intentionally contains only text normalization. Add LFS patterns in a dedicated pull request after Git LFS is installed and tested on the Windows 11 workstation.

## Protect main activation sequence

1. Push the foundation to `main` while the ruleset is Disabled.
2. Wait for the `Repository checks` workflow to run successfully.
3. Activate Protect main.
4. Require pull requests before merging.
5. Keep required approvals at zero while Eddie is the only contributor.
6. Require conversation resolution.
7. Block force pushes and branch deletion when available.
8. Add the passing status check using its exact observed name only after it has run.
9. Prefer squash merging and automatically delete merged branches.

## Documentation rule

Markdown is canonical and reviewable in Git. Polished DOCX snapshots are generated at meaningful design milestones and retained in the downloadable starter or tagged Release artifacts until the LFS/Release-storage decision is finalized. Preserve deliberate decisions in `docs/decisions/`.

## Release workflow

Issue → acceptance criteria → short branch → implementation/test → pull request → checks/preview → docs/ADR/CHANGELOG → squash merge → milestone test plan → tag and GitHub Release.

## Cloudflare environments

Use separate development, staging, and production resources. One Durable Object coordinates each room; D1 stores persistent metadata; R2 stores large objects; KV holds non-authoritative flags/config; Turnstile protects public room/account creation. Do not simulate high-frequency game physics in Durable Objects during early phases.

See the DOCX export for resource names, room/message design, security controls, first-day commands, and release operations.
