---
phase: 65-playbook-run-lifecycle-opsui
plan: "04"
subsystem: testing
tags: [elixir, phoenix_live_view, scrypath_ops, telemetry, mix]
requires:
  - phase: 65-playbook-run-lifecycle-opsui
    provides: async playbook lifecycle, failure panel UI, and run telemetry hooks
provides:
  - render_async-backed LiveView coverage for saved and catalog playbook runs
  - forced-failure assertions for structured error UI and outbound docs
  - root mix test delegation for scrypath_ops test paths plus CI-equivalent verification proof
affects: [opsui-run-lifecycle, opsui-ci-verification, phase-65-closeout]
tech-stack:
  added: []
  patterns: [root mix test delegation for scrypath_ops paths, async LiveView run assertions with telemetry handlers]
key-files:
  created:
    - .planning/phases/65-playbook-run-lifecycle-opsui/65-04-SUMMARY.md
  modified:
    - mix.exs
    - scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex
    - scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs
key-decisions:
  - "Expose a stable run-failure panel test hook instead of relying on copy-only assertions."
  - "Delegate root `mix test scrypath_ops/test/...` paths into `scrypath_ops/` so the plan's acceptance command matches the repo's split-app layout."
patterns-established:
  - "OPSUI run lifecycle tests should call `render_async/1` before asserting terminal run state."
  - "Root-level focused OPSUI test commands route through the optional Phoenix app without changing normal library `mix test` behavior."
requirements-completed: [OPS3-01, OPS3-02]
duration: 4min
completed: 2026-04-22
---

# Phase 65 Plan 04: LiveView tests and CI proof Summary

**Async playbook runs now have explicit LiveView coverage for saved catalog execution, structured failure UI, telemetry, and root-level focused test routing**

## Performance

- **Duration:** 4 min
- **Started:** 2026-04-22T19:01:05Z
- **Completed:** 2026-04-22T19:04:50Z
- **Tasks:** 1
- **Files modified:** 4

## Accomplishments

- Tightened `PlaybookLiveTest` around `render_async/1`, including saved-playbook `run_now` coverage through the catalog path.
- Added explicit forced-failure assertions for the structured run failure panel, diagnostics affordance, and primary `https` troubleshooting link.
- Proved both the focused root command and `mix verify.opsui` succeed after adding root delegation for `scrypath_ops/test/...` paths.

## Task Commits

Each task was committed atomically:

1. **Task 1: LiveView tests and CI proof** - `007feb7` (feat)

## Files Created/Modified

- `mix.exs` - Delegates root `mix test scrypath_ops/test/...` invocations into the optional `scrypath_ops` app.
- `scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex` - Adds a stable `data-testid` hook for the structured run failure panel.
- `scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs` - Covers async catalog runs, forced failures, and explicit telemetry start/stop events.
- `.planning/phases/65-playbook-run-lifecycle-opsui/65-04-SUMMARY.md` - Records execution outcome for this plan.

## Decisions Made

- Split failure-surface and telemetry expectations into separate tests so async UI assertions stay readable and deterministic.
- Reused the saved-playbook path in the `run_now` test instead of writing raw JSON directly, matching the operator workflow the plan called for.
- Fixed the acceptance command at the root Mix layer rather than teaching the test file about the repository split.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Routed root focused OPSUI tests into `scrypath_ops`**
- **Found during:** Task 1 (LiveView tests and CI proof)
- **Issue:** The plan-required command `mix test scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs` failed from the repo root because the root Mix project does not load `ScrypathOpsWeb.ConnCase` or Phoenix test support.
- **Fix:** Added a root `test` alias that detects `scrypath_ops/test/...` paths, rewrites them relative to `scrypath_ops/`, and shells into that app while leaving normal root tests untouched.
- **Files modified:** `mix.exs`
- **Verification:** `mix test scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs`; `mix verify.opsui`
- **Committed in:** `007feb7`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** The deviation was required to satisfy the explicit acceptance command and stayed within test tooling for the existing split-app layout.

## Issues Encountered

- Root `mix test` initially failed on the OPSUI test file because the repository is not an umbrella app. That is now handled by targeted delegation in `mix.exs`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 65 now has proof at the test and CI-gate layer that async runs, failure surfacing, and telemetry are wired end to end.
- The root repo can execute focused OPSUI test files directly, which reduces friction for follow-on plan work in this area.

## Self-Check: PASSED

---
*Phase: 65-playbook-run-lifecycle-opsui*
*Completed: 2026-04-22*
