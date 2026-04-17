---
status: testing
phase: 18-release-parity-gate-node-20-ci-cleanup
source: [18-01-SUMMARY.md, 18-02-SUMMARY.md, 18-03-SUMMARY.md, 18-04-SUMMARY.md, 18-05-SUMMARY.md, 18-06-SUMMARY.md, 18-07-SUMMARY.md]
started: 2026-04-17T17:00:00Z
updated: 2026-04-17T17:00:00Z
---

## Current Test

number: 1
name: mix verify.workspace_clean on clean tree
expected: |
  Run `mix verify.workspace_clean` against the current working tree (which is clean). Task exits 0 and prints "Workspace clean across N pathspecs".
awaiting: user response

## Tests

### 1. mix verify.workspace_clean on clean tree
expected: Run `mix verify.workspace_clean` against the current working tree. Exits 0 with message "Workspace clean across N pathspecs".
result: [pending]

### 2. mix verify.workspace_clean on dirty tree
expected: Touch a file under lib/ (e.g., `echo "" >> lib/scrypath.ex`), then run `mix verify.workspace_clean`. Task exits non-zero with "Workspace is not clean" followed by the offending paths and a next-step hint. Undo the touch afterward.
result: [pending]

### 3. mix verify.release_parity 0.3.0 live canary
expected: Run `mix verify.release_parity 0.3.0` against live Hex. Task prints "==> hex.package fetch scrypath 0.3.0 (attempt 1/N)" then "Release parity OK for scrypath 0.3.0: tag and Hex tarball agree on lib/ + guides/ + docs/". Exit 0.
result: [pending]

### 4. mix verify.release_parity rejects non-semver input
expected: Run `mix verify.release_parity "; echo pwn"`. Task raises `** (Mix) Invalid version ...` with semver guidance. No "pwn" appears anywhere in output (Security V5 injection guard holds).
result: [pending]

### 5. CI ci.yml has no Node 20 deprecation warnings on next run
expected: After pushing the `feat(18):` commit (80500de), open any PR or observe the push run in the Actions tab. For each of the 4 jobs in ci.yml (test, quality, phase5-verification, phase13-verification), search the job log for "deprecated" — expect zero matches for `actions/checkout` or `actions/cache` (Node 24 pins live).
result: [pending]

### 6. docs/releasing.md §Release parity gate readable
expected: Open `docs/releasing.md` or run a local HexDocs preview (`mix docs`). Navigate to the "Release parity gate" section at the end. Section has three subsections (mix verify.workspace_clean, mix verify.release_parity X.Y.Z, Historical context). "Historical context" references `.planning/milestones/v1.2-MILESTONE-AUDIT.md`.
result: [pending]

### 7. CHANGELOG Unreleased names both new tasks + Node 24 + v1.2 pointer
expected: Open `CHANGELOG.md`. Exactly one `## Unreleased` heading (at line 7). Under it: `### Added` with bullets for `mix verify.workspace_clean` and `mix verify.release_parity`; `### Changed` bullet mentioning `actions/checkout@v6` + `actions/cache@v5`; `### Notes` bullet pointing at `v1.2-MILESTONE-AUDIT.md`. No stale legacy `[Unreleased]` block further down.
result: [pending]

### 8. Manual workflow_dispatch of verify-published-release.yml on branch
expected: Push the phase 18 commits to a branch. Open GitHub Actions → "Verify Published Release" → "Run workflow" → select the branch → Run. Workflow completes green. No GitHub issue is auto-filed (non-schedule run is silent per D-19 guard). This is the one wall-clock verification item in the plan.
result: [pending]

### 9. release-please opens 0.4.0 PR after merge
expected: After the `feat(18):` closing commit merges to main, release-please bot opens a release PR bumping `mix.exs @version "0.3.0"` → `"0.4.0"` and generating release notes from the Unreleased section of CHANGELOG.md (both Mix tasks + Node 24 + v1.2 traceability bullet absorbed into the 0.4.0 entry). Merging that PR triggers the canonical publish path, which now enforces all 4 INFRA gates.
result: [pending]

## Summary

total: 9
passed: 0
issues: 0
pending: 9
skipped: 0

## Gaps

[none yet]
