---
status: testing
phase: 24-public-hex-release-parity-gates
source: 24-01-SUMMARY.md, 24-02-SUMMARY.md, 24-03-SUMMARY.md
started: 2026-04-17T12:00:00Z
updated: 2026-04-17T12:00:00Z
---

## Current Test

number: 1
name: Pre-1.0 Release Please bump flags
expected: |
  In `release-please-config.json`, both `bump-minor-pre-major` and `bump-patch-for-minor-pre-major` are set to `true` (pre-1.0 patch bump story for conventional commits, with `Release-As:` as the override path per phase notes).
awaiting: user response

## Tests

### 1. Pre-1.0 Release Please bump flags
expected: `release-please-config.json` includes `"bump-minor-pre-major": true` and `"bump-patch-for-minor-pre-major": true`.
result: [pending]

### 2. Post-publish parity step order in workflows
expected: In `.github/workflows/release-please.yml` and `.github/workflows/publish-hex.yml`, the job runs `mix verify.release_publish …` then the very next step runs `mix verify.release_parity …` with the same `SCRYPATH_RELEASE_VERIFY_ATTEMPTS` / `SCRYPATH_RELEASE_VERIFY_SLEEP_MS` env block pattern as the publish-verify step.
result: [pending]

### 3. README Hex install constraint
expected: `README.md` shows `{:scrypath, "~> 0.3.0"}` in the dependency example (or equivalent documented install line for `~> 0.3.0`).
result: [pending]

### 4. Releasing docs describe post-publish parity
expected: `docs/releasing.md` states that after a real publish, workflows run `mix verify.release_publish`, then `mix verify.release_parity`, and names both `release-please.yml` and `publish-hex.yml` (or clearly describes the same behavior for both paths).
result: [pending]

## Summary

total: 4
passed: 0
issues: 0
pending: 4
skipped: 0
blocked: 0

## Gaps

[none yet]
