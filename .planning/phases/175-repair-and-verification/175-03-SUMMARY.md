---
phase: 175-repair-and-verification
plan: 03
subsystem: ui
tags: [elixir, phoenix-liveview, meilisearch, operations, task-status]
requires:
  - phase: 175-02
    provides: exact task identity and context-bound recovery evidence patterns
provides:
  - Read-only exact-UID promotion task observation through the configured Meilisearch client
  - Separate local status-check activity and persistent promotion task identity
  - Stale success/error callback rejection across schema, allowlist, generation, endpoint, backend, and runtime changes
affects: [175-04, 175-05, 175-06]
actuals:
  tokens: 8985
  tasks: 2
  commits: 3
tech-stack:
  added: []
  patterns: [exact-UID normalized task observation, independent activity and remote status]
key-files:
  created: []
  modified:
    - scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex
    - scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs
key-decisions:
  - "Use the configured Meilisearch task client and normalize every GET response before publishing status."
  - "Retain an accepted task as accepted while a read is in progress or returns enqueued; never treat unavailable evidence as remote failure."
  - "Keep OPUX-21 and OPUX-22 phase-level requirement checkboxes pending until the remaining Phase 175 plans are complete."
patterns-established:
  - "Promotion callbacks publish a result only when the captured task and current schema/runtime context still match."
requirements-completed: []
coverage:
  - id: D1
    description: "Rendered exact-UID swap checks distinguish accepted, running, terminal, and unconfirmed observations without another swap submission."
    requirement: OPUX-21
    verification:
      - kind: automated_ui
        ref: "scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs#rendered promotion status checks; /private/tmp/scrypath-phase173-20261006-155750/evidence/phase175/175-03-focused.log"
        status: pass
      - kind: integration
        ref: "mix verify.ops_ui; /private/tmp/scrypath-phase173-20261006-155750/evidence/phase175/175-03-ops-full.log"
        status: pass
    human_judgment: false
  - id: D2
    description: "Stale callbacks cannot publish a task result after promotion schema, allowlist, generation, endpoint, backend, or runtime identity changes."
    requirement: OPUX-21
    verification:
      - kind: unit
        ref: "scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs#promotion callbacks discard success and error results after runtime or context changes"
        status: pass
      - kind: integration
        ref: "mix verify.ops_ui; /private/tmp/scrypath-phase173-20261006-155750/evidence/phase175/175-03-ops-full.log"
        status: pass
    human_judgment: false
metrics:
  duration: 15min
  completed: 2026-10-10
  status: complete
  commits: 3
  plan_head_before: ddff00b7ab84e0cf25fcceed05fcac5e2fe98897
  plan_head_after: d28ae81835953770a90f7c56f49c16daa3cc448c
---

# Phase 175 Plan 03: Read-only Exact-UID Swap Status Summary

**Operators can recheck the accepted swap through its retained Meilisearch UID, with local check activity separated from backend task state.**

## Performance

- **Duration:** 15 minutes
- **Started:** 2026-10-10T13:30:08Z
- **Completed:** 2026-10-10T13:44:59Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added a rendered “Check swap status” control that performs only a GET for the retained task UID through the configured client and `TaskPayload.normalize/2`.
- Kept `enqueued` as accepted, mapped only exact-UID processing and terminal states to remote claims, and retained the UID for timeout, malformed, mismatched, and failed reads.
- Separated “Checking swap status…” from remote status and protected success and error callbacks against stale schema, allowlist, generation, endpoint, backend, and runtime context.
- Added rendered call-counter tests proving retry after timeout reads the same UID and does not submit another swap.

## Task Commits

Each task was committed atomically:

1. **Task 1: Observe one accepted swap UID as authoritatively processing** - `2168d2b` (RED test), `e6fe428` (implementation; focused tracer gate passed).
2. **Task 2: Map matching terminal and unknown task states with stale-context rejection** - `d28ae81` (adversarial callback context coverage; the shared implementation was included in `e6fe428`).

The initial RED test failed on the intended missing rendered status row. ExUnit output was observed during execution but not persisted as a separate log; no unsupported-format RED classifier result is claimed.

## Files Created/Modified

- `scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex` - exact task observation, retained task context, current-runtime checks, and separate check activity.
- `scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs` - rendered lifecycle, read-count, no-resubmit, and stale callback cases.

## Decisions Made

- Used the configured Meilisearch task client with `Client` fallback and normalized responses before assigning a remote task state.
- Kept `refresh_promotion_checks` separate from task polling; neither the status check nor a retry invokes another swap POST.
- Left OPUX-21 and OPUX-22 requirement checkboxes pending because these are phase-level requirements with remaining Phase 175 plans.

## Deviations from Plan

None. The initial canonical alias attempt stopped in `mix deps.get` because Hex tried to persist under its default read-only cache. Rerunning with the dispatched writable `HEX_HOME` completed the canonical lane; no dependency changes were made.

## Issues Encountered

- The pinned toolchain reports a pre-existing Dialyzer warning in `Scrypath.Sync.sync_related/3`; it is outside the two files owned by this plan.
- The canonical Ops command succeeded with the owned database `127.0.0.1:52706`, partition `175_owned`.

## Verification

- Focused: `cd scrypath_ops && mix test test/scrypath_ops_web/live/sync_drift_live_test.exs` — 34 tests, 0 failures. Log: `/private/tmp/scrypath-phase173-20261006-155750/evidence/phase175/175-03-focused.log`.
- Canonical Ops lane: `mix verify.ops_ui` — 2 doctests, 316 tests, 0 failures. Log: `/private/tmp/scrypath-phase173-20261006-155750/evidence/phase175/175-03-ops-full.log`.
- Full lane used `PGHOST=127.0.0.1 PGPORT=52706 PGUSER=postgres PGPASSWORD=postgres MIX_TEST_PARTITION=175_owned` and writable Hex cache `/private/tmp/scrypath-phase173-20261006-155750/hex-home`.

## User Setup Required

None.

## Next Phase Readiness

The exact-UID read-only status slice is ready for the next Phase 175 plan. The owned Postgres test resource remains available for subsequent waves; parent retains cleanup ownership. No next plan was executed.

## Self-Check: PASSED

- Modified source and test files exist and the recorded task commits are ancestors of the plan head.
- Focused and full Ops log files exist and report zero failures.

---
*Phase: 175-repair-and-verification*
*Completed: 2026-10-10*
