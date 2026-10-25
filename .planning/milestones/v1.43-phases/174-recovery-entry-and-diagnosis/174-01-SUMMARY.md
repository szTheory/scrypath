---
phase: recovery-entry-and-diagnosis
plan: 01
subsystem: ui
tags: [phoenix, liveview, playwright, recovery, schema-selection]

requires:
  - phase: 173
    provides: shared operator UI foundation, URL-backed schema selection patterns, theme and responsive contracts
provides:
  - Visible current retry eligibility on failed-work rows.
  - Focused route/render/action proof for explicit allowed non-first schemas and retained accepted receipts.
  - Fail-closed tests and mounted browser coverage for schema selection, history, refresh, themes, focus, and narrow layouts.
affects: [phase-174, phase-175, failed-sync, recovery]

actuals:
  tokens: 3244
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - Resolve explicit schema identity against the current host allowlist at route and event time.
    - Show retry eligibility from the existing RecoveryAction and keep acceptance adjacent to the source failure.

key-files:
  modified:
    - scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex
    - scrypath_ops/test/scrypath_ops_web/live/failed_sync_live_test.exs
    - examples/scrypath_ecommerce/e2e/operator.spec.ts
    - examples/scrypath_ecommerce/e2e/harness.spec.ts

key-decisions:
  - "Keep URL schema identity and the existing host gate as the authorities for recovery actions."
  - "Use the existing retry action as the source of visible eligibility; unsupported work receives the exact unavailable explanation."

requirements-completed: [OPUX-18, OPUX-19]

coverage:
  - id: D1
    description: "Failed-work rows expose diagnosis and current retry eligibility, and accepted retry work remains beside its source failure."
    requirement: OPUX-18
    verification:
      - kind: unit
        ref: "scrypath_ops/test/scrypath_ops_web/live/failed_sync_live_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Explicit non-first schema selection survives mounted recovery handoff, refresh, reload, and browser history with fail-closed invalid targets."
    requirement: OPUX-19
    verification:
      - kind: automated_ui
        ref: "examples/scrypath_ecommerce/e2e/operator.spec.ts#operator verifies a rendered recovery for the non-first Variant schema"
        status: pass
    human_judgment: false

duration: 6min
completed: 2026-10-11
status: complete
plan_head_before: eaf03cef62443d82d9a34927ead2f44e176a16be
plan_head_after: 474355a62126b7032a65a4086985baefe503dc27
commits: 2
---

# Phase 174 Plan 01: Recovery Entry and Diagnosis Summary

**Failed sync rows now state retry eligibility and preserve schema-bound retry receipts alongside the original failure.**

## Performance

- **Duration:** 6 minutes
- **Started:** 2026-10-11T02:13:02Z
- **Completed:** 2026-10-11T02:18:18Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added explicit "Retry currently available" and the contracted unavailable explanation before Diagnostics.
- Proved an explicitly selected non-first schema renders its own seeded failure, uses the existing gated retry, and retains its source failure beside the accepted, non-complete receipt.
- Expanded fail-closed ExUnit coverage and the mounted journey for selection, refresh, reload, Back/Forward, invalid schema, theme preference, focus, and 320px/390px overflow.

## Task Commits

Each task was committed atomically:

1. **Task 1: Trace one allowed schema through the LiveView route and accepted retry** - `c7b42cb` (feat)
2. **Task 2: Expand failed-work states, fail-closed selection, and browser-history proof** - `474355a` (test)

## Files Created/Modified

- `scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex` - Visible eligibility copy for each failed-work row.
- `scrypath_ops/test/scrypath_ops_web/live/failed_sync_live_test.exs` - Explicit-schema retry and fail-closed/security assertions.
- `examples/scrypath_ecommerce/e2e/operator.spec.ts` - Mounted schema/history/theme/focus/responsive journey.
- `examples/scrypath_ecommerce/e2e/harness.spec.ts` - Exact Search page heading locator so the page heading is distinct from its search empty-state heading.

## Decisions Made

- Kept retry eligibility derived from the existing RecoveryAction and retained the existing route allowlist and event-time authorization checks.
- Preserved URL-backed schema identity and the current receipt context/generation behavior.

## Deviations from Plan

None. No new dependencies, routes, retry policies, or authorization paths were introduced.

## Issues Encountered

- The first local Mix run lacked fetched dependencies. `mix deps.get` fetched only lockfile-pinned dependencies into the worktree; Hex cache was redirected to `/private/tmp` because the default user cache was not writable.
- The first mounted run exposed a substring heading locator collision between the Search page title and its empty-state title. The harness now requests an exact heading match; the complete mounted gate then passed all 4 browser tests, including the recovery journey.
- An initial `mix precommit` invocation reported two Sync/drift teardown failures. A rerun with the project's Elixir 1.19/OTP 28 toolchain passed 2 doctests and all 250 tests with 0 failures.

## User Setup Required

None.

## Next Phase Readiness

The recovery entry behavior is ready for the remaining Phase 174 Control Room and Search health plans. The mounted and precommit suite issues above remain isolated to existing checks outside this plan's Failed sync ownership.

## Self-Check: PASSED

The three planned code/test files and deferred-items artifact exist. Both task commits are ancestors of HEAD, and the measured plan ledger records 2 task commits. The summary is the remaining plan close-out artifact.

---
*Phase: 174-recovery-entry-and-diagnosis*
*Completed: 2026-10-11*
