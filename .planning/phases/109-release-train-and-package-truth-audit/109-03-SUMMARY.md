---
phase: 109-release-train-and-package-truth-audit
plan: "03"
subsystem: release
tags: [github-actions, release-please, hex, docs-contract, release-truth]
requires:
  - phase: 109-release-train-and-package-truth-audit
    provides: REL-01 and REL-02 contract baselines from plans 01 and 02
provides:
  - ordered publish-proof-chain parity checks across canonical and recovery workflows
  - release docs and contributor routing aligned to deterministic-vs-live verification boundaries
affects: [REL-01, REL-03, release workflows, release docs contract]
tech-stack:
  added: []
  patterns: [canonical-workflow parity assertions, docs-as-release-authority routing]
key-files:
  created: []
  modified:
    - .github/workflows/publish-hex.yml
    - test/mix/tasks/workflow_wiring_test.exs
    - docs/releasing.md
    - CONTRIBUTING.md
    - test/scrypath/docs_contract_test.exs
key-decisions:
  - "Kept release-please.yml as canonical release authority; publish-hex.yml remains break-glass replay from explicit tag/version."
  - "Kept mix verify.phase11 auth-free and always-on; live Hex/HexDocs/package checks remain post-publish and scheduled only."
patterns-established:
  - "Publish and recovery workflows must preserve identical ordered proof steps before/after hex.publish."
  - "CONTRIBUTING.md routes contributors to docs/releasing.md instead of duplicating release mechanics."
requirements-completed: [REL-01, REL-03]
duration: 31min
completed: 2026-05-31
---

# Phase 109 Plan 03: Release Train and Package Truth Audit Summary

**Canonical and recovery publish workflows now share one enforced ordered proof chain, with docs/tests aligned to the same release-truth contract.**

## Performance

- **Duration:** 31 min
- **Started:** 2026-05-31T20:20:00Z
- **Completed:** 2026-05-31T20:51:00Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added TDD workflow-wiring assertions that enforce strict step order for canonical publish, manual recovery, and publish-free scheduled monitor behavior.
- Patched `publish-hex.yml` ordering drift so recovery now mirrors canonical proof sequencing.
- Updated release/maintainer docs and docs-contract assertions so contributor guidance, maintainer authority, and checked-in wording match implemented release behavior.

## Task Commits

1. **Task 1: Strengthen workflow-chain assertions before patching publish/recovery/monitor wiring**
   - `7f55d7f` (`test`): RED assertions for ordered chain parity and publish-free monitor checks
   - `e944749` (`feat`): GREEN workflow correction to recovery chain ordering
2. **Task 2: Align maintainer and contributor docs to the implemented release chain**
   - `c210fe2` (`docs`): release doc/contributor routing alignment and docs-contract wording updates

## Files Created/Modified

- `.github/workflows/publish-hex.yml` - Reordered release checks to match canonical chain.
- `test/mix/tasks/workflow_wiring_test.exs` - Added ordered chain and monitor guard assertions.
- `docs/releasing.md` - Documented explicit canonical/recovery ordered publish proof chain.
- `CONTRIBUTING.md` - Added routing line back to `docs/releasing.md` for release mechanics authority.
- `test/scrypath/docs_contract_test.exs` - Updated release-adjacent wording assertions to current checked-in docs text.

## Decisions Made

- Preserve `release-please.yml` as single release authority and keep `publish-hex.yml` as explicit replay path from reviewed ref/version inputs.
- Keep `mix verify.phase11` deterministic/auth-free; do not move live publish checks into PR/main deterministic gates.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Task 2 verification started with two pre-existing docs-contract drifts; resolved by updating `docs_contract_test.exs` expectations to current guide/JTBD wording in-plan.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Release workflow wiring, recovery posture, and docs truth are now mechanically aligned for REL-03.
- Phase 109 is complete from this plan perspective and ready for consolidated phase closeout checks.

## Self-Check: PASSED

- Verified summary file exists at `.planning/phases/109-release-train-and-package-truth-audit/109-03-SUMMARY.md`.
- Verified commits `7f55d7f`, `e944749`, and `c210fe2` exist in git history.
