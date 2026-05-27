---
phase: 100-install-release-contract-reconciliation
plan: 02
subsystem: testing
tags: [contracts, verify.phase99, docs-contract, truth-guards]
requires:
  - phase: 100-install-release-contract-reconciliation
    provides: reconciled install/release wording tokens
provides:
  - "Deterministic TRUTH-01/TRUTH-02 assertions in phase99 contract suite"
  - "Bounded phase-100 evergreen docs guard for install/release tokens"
  - "Stale major install token refutes on intake and template surfaces"
affects: [phase99-contract-test, docs-contract-test, verify-phase99, outside-adopter-intake]
tech-stack:
  added: []
  patterns: ["token-level trust assertions", "bounded evergreen guards"]
key-files:
  created: []
  modified:
    - test/scrypath/phase99_contract_test.exs
    - test/scrypath/docs_contract_test.exs
    - guides/outside-adopter-intake.md
key-decisions:
  - "Keep phase99 contract suite as the authoritative TRUTH-01/TRUTH-02 seam."
  - "Use one bounded docs-contract evergreen guard instead of broad snapshot-style prose checks."
patterns-established:
  - "Release/install trust checks stay deterministic and service-free."
  - "Case-insensitive token assertions avoid brittle capitalization drift."
requirements-completed: [TRUTH-01, TRUTH-02]
duration: 3min
completed: 2026-05-27
---

# Phase 100 Plan 02: Trust contract test enforcement summary

**Extended the existing phase99 trust lane with deterministic install/release assertions and a bounded docs evergreen guard for Phase 100 contracts.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-05-27T12:18:00Z
- **Completed:** 2026-05-27T12:21:00Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Added TRUTH-01 checks for `{:scrypath, "~> 0.3"}` parity, stale `{:scrypath, "~> 1.0"}` refutes, and exact evidence boundary tokens.
- Added TRUTH-02 checks for release-backed guidance vs unreleased `main` wording plus support-authority routing checks.
- Added one focused docs-contract evergreen test to keep Phase-100 install/release tokens anchored without broad snapshot assertions.

## Task Commits

Each task was committed atomically:

1. **Task 100-02-01: Extend phase99 contract seam for install/release coherence** - `520fd8f` (test)
2. **Task 100-02-02: Add bounded docs-contract evergreen guard** - `e14d366` (test)

**Plan metadata:** pending

## Files Created/Modified
- `test/scrypath/phase99_contract_test.exs` - authoritative TRUTH-01/TRUTH-02 deterministic contract assertions.
- `test/scrypath/docs_contract_test.exs` - bounded phase-100 evergreen guard for install/release token stability.
- `guides/outside-adopter-intake.md` - inserted missing release-backed guidance token required by new TRUTH-02 assertions.

## Decisions Made
- Kept assertions token-based and helper-driven (no snapshot-style guards).
- Preserved `mix verify.phase99` as the single trust-lane command for these checks.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Missing Contract Token] intake guide lacked exact TRUTH-02 token wording**
- **Found during:** Task 100-02-01 test run
- **Issue:** New TRUTH-02 assertion failed because intake surface did not include `release-backed guidance`.
- **Fix:** Added concise release-truth sentence to `guides/outside-adopter-intake.md`.
- **Files modified:** guides/outside-adopter-intake.md
- **Verification:** `mix test test/scrypath/phase99_contract_test.exs`
- **Committed in:** `520fd8f`

---

**Total deviations:** 1 auto-fixed (missing contract token)
**Impact on plan:** Required token alignment was restored with no runtime-scope expansion.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
Wave 3 can now finalize verify-lane wiring/docs messaging on top of passing TRUTH-01/TRUTH-02 contract checks.

---
*Phase: 100-install-release-contract-reconciliation*
*Completed: 2026-05-27*
