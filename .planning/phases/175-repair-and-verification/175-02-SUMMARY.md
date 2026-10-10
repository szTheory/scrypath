---
phase: 175-repair-and-verification
plan: 02
subsystem: ops-ui
tags: [elixir, phoenix-liveview, recovery, ecto, meilisearch]
requires:
  - phase: 175-01
    provides: selected-schema sync observations and current runtime context
provides:
  - Exact source-qualified retry receipt identity remains visible when recovery observation is unknown.
  - Expired receipt handoffs stay explicitly unknown and refresh remains read-only.
  - A task UID mismatch cannot verify expected delete absence.
affects: [175-03, 175-05, 175-06]
actuals:
  tokens: 3039
  tasks: 2
  commits: 4
  plan_head_before: a3b856cb22cfa6072db7d62cd722185ccc9418b1
  plan_head_after: 6e67eb177e5a56a8fe12864cfcf5be1d3b0a2ad2
tech-stack:
  added: []
  patterns:
    - Preserve only bounded receipt identity when authority reads are unavailable; keep outcome unknown.
    - Render unavailable evidence distinctly while keeping refresh scoped to the same opaque receipt.
key-files:
  created: []
  modified:
    - scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex
    - scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs
    - scrypath_ops/test/scrypath_ops/document_observation_test.exs
key-decisions:
  - "Known source, operation, schema, and retry identity remain visible even when runtime or queue/task/document evidence cannot be read."
  - "Unknown observation state remains explicit, and refresh only rechecks the existing receipt without submitting work."
patterns-established:
  - "Recovery presentation may retain sanitized receipt identity independently from verification authority."
requirements-completed: []
coverage:
  - id: D1
    description: "A rendered retry handoff retains source failure, schema, operation, replacement job, attempt, and task identity when observation remains unknown; refresh does not enqueue work."
    verification:
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs#rendered recovery handoff keeps source identity through a read-only refresh"
        status: pass
    human_judgment: false
  - id: D2
    description: "Expired receipt handoff remains visibly unknown with selected schema context and an explanation of unavailable evidence; refresh remains read-only."
    verification:
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs#expired recovery handoff remains visible and names unavailable evidence"
        status: pass
    human_judgment: false
  - id: D3
    description: "A successful but unrelated task UID cannot verify expected delete absence or trigger a document read."
    verification:
      - kind: unit
        ref: "scrypath_ops/test/scrypath_ops/document_observation_test.exs#an unrelated task cannot verify expected delete absence"
        status: pass
    human_judgment: false
duration: 7min
completed: 2026-10-10
status: complete
---

# Phase 175 Plan 02: Exact Retry Evidence Summary

**Recovery handoffs retain exact, source-qualified receipt identity through unavailable reads while keeping their status unknown and refresh read-only.**

## Performance

- **Duration:** 7 minutes
- **Started:** 2026-10-10T13:22:33Z
- **Completed:** 2026-10-10T13:29:30Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Preserved sanitized source failure, operation, schema, index, job, attempt, and task identity for a recognized retry receipt even when runtime validation leaves the result unknown.
- Kept expired receipts visible with explicit unavailable-evidence guidance and preserved `:unknown` through the asynchronous observation callback.
- Added correlation coverage proving an unrelated successful task cannot establish delete absence or cause an active-index document read.
- Kept OPUX-20, OPUX-21, and OPUX-22 pending for whole-phase verification.

## Task Commits

1. **Task 1: RED: assert rendered recovery handoff identity** - `4e4e70d` (test)
2. **Task 1: GREEN: preserve exact recovery receipt identity** - `b61200c` (feat)
3. **Task 2: RED: cover expired and unrelated recovery evidence** - `cbed4bd` (test)
4. **Task 2: GREEN: retain unknown recovery observations** - `6e67eb1` (fix)

Plan metadata, STATE, and ROADMAP updates are captured by the final plan metadata commit.

## Files Created/Modified

- `scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex` - Preserves safe receipt identity across unknown observations and renders unavailable evidence and source-qualified failure identity.
- `scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs` - Covers rendered handoff identity, explicit unknown state, selected schema, and read-only refresh behavior.
- `scrypath_ops/test/scrypath_ops/document_observation_test.exs` - Covers rejection of unrelated task evidence for delete absence.

## Decisions Made

- Keep known source-qualified receipt identity available independently of whether current runtime, queue, task, or document authority checks can complete.
- Keep unavailable observation explicitly unknown; retry refresh is a read-only recheck of the same receipt.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Retained receipt identity when runtime validation returns unknown**
- **Found during:** Task 1 (tracer)
- **Issue:** A valid opaque receipt's exact retry identity disappeared from the rendered handoff when runtime/queue proof could not be established.
- **Fix:** Preserve a bounded allowlist of source-qualified receipt fields while leaving the outcome unknown.
- **Files modified:** `scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex`
- **Verification:** Rendered LiveView regression test and focused task-1 command passed.
- **Committed in:** `b61200c`

**2. [Rule 1 - Bug] Preserved unknown observer state through the async callback**
- **Found during:** Task 2
- **Issue:** The callback normalized `{unknown, nil}` into a tuple state, preventing the unknown-evidence explanation from rendering.
- **Fix:** Preserve tuple states with map or nil evidence, and render unavailable-evidence guidance after observation completes.
- **Files modified:** `scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex`
- **Verification:** Expired-receipt rendered regression test and focused task-2 command passed.
- **Committed in:** `6e67eb1`

**Total deviations:** 2 auto-fixed (Rule 1). **Impact on plan:** Both fixes were required to preserve truthful identity and unknown-state behavior; no scope expansion.

## Verification

- Task 1: `mix test test/scrypath_ops_web/live/sync_drift_live_test.exs test/scrypath_ops/recovery_observation_test.exs` — **40 tests, 0 failures**.
- Task 2: `mix test test/scrypath_ops_web/live/sync_drift_live_test.exs test/scrypath_ops/recovery_observation_test.exs test/scrypath_ops/document_observation_test.exs` — **55 tests, 0 failures**.
- Canonical Ops lane: `mix verify.ops_ui` — **2 doctests, 311 tests, 0 failures**. Nav contract passed.
- `mix format --check-formatted` on the three modified files and `git diff --check` — passed.
- Logs: `/private/tmp/scrypath-phase173-20261006-155750/evidence/phase175/175-02-task1-red.log`, `175-02-task1-green.log`, `175-02-task2-red.log`, `175-02-task2-green.log`, and `175-02-canonical-ops.log`.

## Issues Encountered

- The canonical run reported the pre-existing Dialyzer warning in `lib/scrypath/sync.ex:61`; this file is outside this plan's scope and was left unchanged.
- `mix deps.get` reported existing security advisories for installed `cloak 1.1.1` and `cloak_ecto 1.3.0`; dependency files were unchanged.

## User Setup Required

None. The suite used the already provisioned PostgreSQL test service on port 52706.

## Next Phase Readiness

Ready for plan 175-03. Phase requirements remain pending until the phase-wide verification proves their complete scope.

## Self-Check: PASSED

- All three modified files exist and the four task commits are ancestors of the current plan head.
- The canonical Ops lane and focused verification commands passed.
- No new files, dependencies, endpoints, auth paths, or schema trust boundaries were introduced.

---
*Phase: 175-repair-and-verification*
*Completed: 2026-10-10*
