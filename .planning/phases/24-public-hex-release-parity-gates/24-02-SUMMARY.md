---
phase: 24-public-hex-release-parity-gates
plan: "02"
status: complete
completed: 2026-04-17
---

## Summary — Plan 24-02: Post-publish `release_parity` on publish workflows

### Outcome

Inserted `mix verify.release_parity` immediately after `mix verify.release_publish` in `.github/workflows/release-please.yml` and `.github/workflows/publish-hex.yml`, reusing the same `SCRYPATH_RELEASE_VERIFY_ATTEMPTS` / `SCRYPATH_RELEASE_VERIFY_SLEEP_MS` env block. Added SHIP-03 contract tests for ordering.

### Key files

- `.github/workflows/release-please.yml`
- `.github/workflows/publish-hex.yml`
- `test/mix/tasks/workflow_wiring_test.exs`

### Deviations

- None.

## Self-Check: PASSED
