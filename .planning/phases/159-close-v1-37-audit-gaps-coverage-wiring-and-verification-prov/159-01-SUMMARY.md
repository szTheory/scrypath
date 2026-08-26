---
phase: 159-close-v1-37-audit-gaps-coverage-wiring-and-verification-prov
plan: "01"
subsystem: ci
tags: [github-actions, elixir, mix, coverage, ci]
requires:
  - phase: 148-quality-baseline
    provides: existing `mix verify.coverage` capability and TEST-05 ownership
provides:
  - Scheduled/manual advisory coverage job with seven-day source-SHA-bound report retention
  - Scoped ExUnit workflow contract and maintainer recovery guidance
affects: [ci, contributor-guidance, milestone-audit]
tech-stack:
  added: []
  patterns:
    - Reuse immutable action pins and job-scoped structural workflow assertions for advisory evidence lanes
key-files:
  created: []
  modified:
    - .github/workflows/ci.yml
    - test/mix/tasks/workflow_wiring_test.exs
    - CONTRIBUTING.md
key-decisions:
  - "Coverage remains schedule/manual-only, advisory, informational, and non-blocking."
  - "The built-in Mix coverage report is retained directly with no hosted service, threshold, token, or new dependency."
patterns-established:
  - "Coverage workflow tests scope every assertion through workflow_job_block/2 to prevent cross-job false positives."
requirements-completed: []
coverage:
  - id: D1
    description: Scheduled/manual advisory coverage job runs the existing canonical command and retains a source-SHA-bound report.
    verification:
      - kind: unit
        ref: test/mix/tasks/workflow_wiring_test.exs#TEST-05 scheduled/manual informational coverage
        status: pass
      - kind: other
        ref: actionlint .github/workflows/ci.yml
        status: pass
      - kind: other
        ref: mix verify.coverage
        status: pass
    human_judgment: false
  - id: D2
    description: Contributor guidance explains local reproduction, manual redispatch, report retrieval, retention, and non-blocking posture.
    verification:
      - kind: unit
        ref: mix test test/mix/tasks/workflow_wiring_test.exs --warnings-as-errors
        status: pass
      - kind: other
        ref: mix verify.repository_contracts
        status: pass
    human_judgment: false
duration: 1min
completed: 2026-08-26
status: complete
---

# Phase 159 Plan 01: Scheduled Manual Advisory Coverage Summary

**A dependency-free scheduled/manual coverage lane now runs `mix verify.coverage`, retains its source-SHA-bound report for seven days, and documents maintainer recovery.**

## Performance

- **Duration:** 1 min
- **Started:** 2026-08-26T20:05:40Z
- **Completed:** 2026-08-26T20:06:21Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added the non-blocking `coverage (advisory)` job for scheduled and manually dispatched CI runs only.
- Pinned TEST-05 topology, artifact retention, and least-privilege constraints through job-scoped ExUnit assertions.
- Documented local reproduction, manual redispatch, SHA-bound artifact retrieval, and the advisory-only posture.

## Task Commits

1. **Task 1: Wire and prove one scheduled/manual informational coverage run end to end** — `cae25ad` (feat)
2. **Task 2: Document the CI posture, artifact retrieval, and manual recovery path** — `953de69` (docs)

## Files Created/Modified

- `.github/workflows/ci.yml` — scheduled/manual informational coverage producer and bounded artifact upload.
- `test/mix/tasks/workflow_wiring_test.exs` — scoped TEST-05 workflow contract.
- `CONTRIBUTING.md` — coverage policy, reproduction, redispatch, and report retrieval guidance.

## Decisions Made

- Kept coverage advisory and separate from the required merge-gate topology.
- Reused the built-in report and existing immutable upload pin instead of adding a coverage service or dependency.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The repaired TEST-05 evidence path is ready for the remaining provenance and closure work.

## Self-Check: PASSED

- Required files exist and both task commits are reachable in Git history.
