---
phase: 99-drift-gates-and-ci-enforcement
plan: 03
subsystem: infra
tags: [ci, required-checks, docs, contract-tests]
requires:
  - phase: 99-01
    provides: "Docs and proof-boundary trust assertions"
  - phase: 99-02
    provides: "Executable mix verify.phase99 gate and alias parity wiring"
provides:
  - "Stable required CI token `phase99-trust` wired to `mix verify.phase99`"
  - "Required-vs-advisory merge policy published in CONTRIBUTING"
  - "Cross-surface parity tests for required-check naming and ordering"
affects: [ci-policy, branch-protection-tokens, contributor-workflow]
tech-stack:
  added: []
  patterns: ["required-check token locking", "workflow-doc parity tests"]
key-files:
  created: []
  modified:
    - .github/workflows/ci.yml
    - CONTRIBUTING.md
    - test/mix/tasks/workflow_wiring_test.exs
    - test/scrypath/phase99_contract_test.exs
key-decisions:
  - "Use `phase99-trust` as the single stable phase99 required-check token."
  - "Keep heavy/live checks advisory by default while phase99 trust lane is required."
patterns-established:
  - "Required check names are contract tokens verified in both wiring and phase contract suites."
  - "Contributing required-check list ordering is explicitly asserted to reduce drift."
requirements-completed: [TEST-03, GATE-02]
duration: 24min
completed: 2026-05-27
---

# Phase 99 Plan 03: Required-check policy enforcement summary

**Locked one stable CI trust token (`phase99-trust`) and enforced required-check parity across workflow, docs, and deterministic tests.**

## Performance

- **Duration:** 24 min
- **Started:** 2026-05-27T10:56:00Z
- **Completed:** 2026-05-27T11:20:00Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments
- Added the `phase99-trust` CI job with deterministic setup and `mix verify.phase99` execution.
- Updated `CONTRIBUTING.md` to publish the explicit required blockers (`main-ci`, `repo-hygiene`, `release-truth`, `phase99-trust`) and advisory boundary.
- Extended workflow and phase99 contract tests to enforce required-check token parity and ordering.

## Task Commits

1. **Task 99-03-01: add phase99 required trust job in CI** - `7fa1017` (chore)
2. **Task 99-03-02: document required-check policy in CONTRIBUTING** - `90c3bdf` (docs)
3. **Task 99-03-03: lock parity assertions for required-check names** - `1ccd8cc` (test)

**Plan metadata:** pending

## Files Created/Modified
- `.github/workflows/ci.yml` - added stable `phase99-trust` required-check job.
- `CONTRIBUTING.md` - explicit required-blocker contract plus advisory boundary wording.
- `test/mix/tasks/workflow_wiring_test.exs` - CI/docs parity assertions for `phase99-trust` and `mix verify.phase99`.
- `test/scrypath/phase99_contract_test.exs` - TEST-03 required-check token parity and ordering assertions.

## Decisions Made
- Preferred one stable trust token (`phase99-trust`) over rotating phase-specific names.
- Enforced required-check ordering in docs to reduce rename/reorder drift noise.

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
ExDoc warnings-as-errors initially flagged `mix verify.phase99` references in `CONTRIBUTING.md`; resolved by switching those specific references to `<code>mix verify.phase99</code>` so docs stay explicit without hidden-module warnings.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
All phase 99 plans are complete and phase-level verification can now evaluate final goal achievement.

---
*Phase: 99-drift-gates-and-ci-enforcement*
*Completed: 2026-05-27*
