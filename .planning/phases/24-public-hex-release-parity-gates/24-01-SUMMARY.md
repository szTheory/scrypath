---
phase: 24-public-hex-release-parity-gates
plan: "01"
status: complete
completed: 2026-04-17
---

## Summary — Plan 24-01: Release Please pre-1.0 bump policy

### Outcome

Added `bump-minor-pre-major` and `bump-patch-for-minor-pre-major` to `release-please-config.json` and rewrote UAT-09 so CI locks the pre-1.0 patch bump story for `feat:` on `0.3.x` (with `Release-As:` as the override path).

### Key files

- `release-please-config.json`
- `test/mix/tasks/workflow_wiring_test.exs`

### Deviations

- None.

## Self-Check: PASSED
