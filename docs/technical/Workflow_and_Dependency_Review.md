# Workflow and Dependency Review

## Purpose

This layer adds two free, repository-controlled checks without replacing the established quality, security, Godot, companion, export, or provenance baselines.

## Actionlint and ShellCheck

GitHub Actions workflows are checked with checksum-pinned Actionlint `1.7.12`. The Ubuntu runner's ShellCheck installation is required and detected by Actionlint, so embedded Bash in workflow `run:` steps receives shell analysis as part of the same blocking job.

The workflow:

- runs when workflow files or the local quality command change;
- checks every workflow rather than only the changed file;
- blocks on Actionlint syntax, expression, action-input, reusable-workflow, job-dependency, security, or embedded ShellCheck findings;
- stores tool versions and console output as a 14-day Actions artifact;
- checks out source with persisted credentials disabled.

Local use is optional when Actionlint is already installed:

```powershell
actionlint
python quality/run_quality.py static
```

`quality/run_quality.py static` runs Actionlint when it is present. A missing local binary is reported without blocking because GitHub Actions installs and enforces the checksum-pinned version automatically.

## Dependency review

The dependency review workflow uses `actions/dependency-review-action` `5.0.0` pinned to its immutable commit. It runs only on pull requests that change npm, Python, Dependabot, or dependency-review configuration.

Policy:

- block newly introduced high or critical known vulnerabilities;
- evaluate runtime, development, and unknown dependency scopes;
- retain license reporting without establishing an unreviewed allowlist or denylist;
- show patched versions when available;
- avoid duplicate OpenSSF Scorecard output;
- use read-only repository permissions and non-persisted checkout credentials.

The full-graph npm audit, pip audit, Dependabot, CodeQL, Gitleaks, Zizmor, SBOM generation, and deterministic workflow policy remain authoritative companion controls. Dependency review adds pull-request-specific change detection rather than replacing those controls.

## Maintenance

Tool updates must preserve immutable action pins or checksum-pinned release archives. Version changes require a reviewed pull request and successful execution of the repository's existing quality and security workflows. No automatic merge or publication is authorized.
