---
phase: 65-playbook-run-lifecycle-opsui
plan: "01"
subsystem: ui
tags: [elixir, phoenix_live_view, scrypath_ops, playbooks, docs]
requires:
  - phase: 60-playbook-liveview-and-ia
    provides: playbook catalog, runner entry point, and existing run failure copy
provides:
  - config-backed documentation resolution for playbook run failures
  - stable JSON-serializable failure enrichment for runner reasons
  - focused tests covering failure class, message, doc URL, and allowlisted copy
affects: [phase-65-plan-02, phase-65-plan-03, opsui-run-failures]
tech-stack:
  added: []
  patterns: [registry-driven failure enrichment, config-backed doc resolution]
key-files:
  created:
    - scrypath_ops/lib/scrypath_ops/playbook/doc_resolver.ex
    - scrypath_ops/lib/scrypath_ops/playbook/run_failure.ex
    - scrypath_ops/test/scrypath_ops/playbook/run_failure_test.exs
  modified:
    - scrypath_ops/config/test.exs
key-decisions:
  - "Keep doc URL resolution in a dedicated module backed by :playbook_doc_base so LiveView copy can stop scattering raw GitHub links."
  - "Represent copy-building in the failure registry with strategy atoms instead of function captures so the table stays compile-safe."
patterns-established:
  - "Playbook run failures normalize through a pure map with failure_class, reason, message, copy, and doc keys."
  - "Operator doc targets are resolved from config and capped to one primary plus at most two related links."
requirements-completed: [OPS3-02]
duration: 3min
completed: 2026-04-22
---

# Phase 65 Plan 01: Run failure enrichment and doc resolver Summary

**Registry-driven playbook run failure payloads with config-backed documentation URLs for OPSUI operator errors**

## Performance

- **Duration:** 3 min
- **Started:** 2026-04-22T18:49:31Z
- **Completed:** 2026-04-22T18:52:31Z
- **Tasks:** 1
- **Files modified:** 4

## Accomplishments
- Added `ScrypathOps.Playbook.RunFailure` to normalize `Runner.run_validated/3` error reasons into stable, JSON-serializable maps.
- Added `ScrypathOps.Playbook.DocResolver` to centralize operator doc URLs behind `:playbook_doc_base`.
- Added focused tests proving failure messages, doc links, and allowlisted copy behavior.

## Task Commits

Each task was committed atomically:

1. **Task 1: Run failure enrichment and doc resolver** - `202941c` (feat)

**Plan metadata:** recorded in the final docs commit for this summary artifact

## Files Created/Modified
- `scrypath_ops/lib/scrypath_ops/playbook/doc_resolver.ex` - Resolves `doc_ref` atoms into absolute primary and related URLs.
- `scrypath_ops/lib/scrypath_ops/playbook/run_failure.ex` - Maps known runner failure reasons into stable operator-facing maps.
- `scrypath_ops/test/scrypath_ops/playbook/run_failure_test.exs` - Covers stable failure payload structure and doc URL behavior.
- `scrypath_ops/config/test.exs` - Pins the test doc base to the default GitHub docs location.

## Decisions Made
- Kept the failure registry pure and compile-safe by storing copy strategies as atoms and resolving them at runtime.
- Used the existing GitHub `main` docs base as the default and test value so no external setup or secrets are needed.
- Covered the current `PlaybookLive.format_run_flash/1` reason shapes plus `:stub_hard_failure` without changing LiveView yet.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Replaced function captures in the registry attribute**
- **Found during:** Task 1 (Run failure enrichment and doc resolver)
- **Issue:** The first implementation stored local function captures inside the module attribute registry, which failed compilation in `scrypath_ops`.
- **Fix:** Replaced function captures with small copy-strategy atoms and resolved those strategies at runtime.
- **Files modified:** `scrypath_ops/lib/scrypath_ops/playbook/run_failure.ex`
- **Verification:** `cd scrypath_ops && mix compile`; `cd scrypath_ops && mix test test/scrypath_ops/playbook/run_failure_test.exs`
- **Committed in:** `202941c` (part of task commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** The fix was required for compilation and did not widen scope.

## Issues Encountered
None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- `RunFailure` and `DocResolver` are ready for LiveView lifecycle wiring in Plan 02 and UI rendering in Plan 03.
- Verification for this slice is `cd scrypath_ops && mix test test/scrypath_ops/playbook/run_failure_test.exs` and `cd scrypath_ops && mix compile`; the repo root Mix project does not compile `scrypath_ops` directly.

## Self-Check: PASSED

---
*Phase: 65-playbook-run-lifecycle-opsui*
*Completed: 2026-04-22*
