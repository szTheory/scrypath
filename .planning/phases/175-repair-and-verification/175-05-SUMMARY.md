---
phase: 175-repair-and-verification
plan: 05
subsystem: testing
tags: [phoenix-liveview, meilisearch, ops-ui, test-fixtures, recovery]
requires:
  - phase: 175-repair-and-verification
    provides: Production SyncDriftLive controls and Phase 175 operational contracts from plans 01–04
provides:
  - Test-only standalone route mounting production SyncDriftLive at /ops/phase175/sync-drift
  - Bounded named fake-client scenarios for selected-schema, task, config, sync, recovery, and blocker states
  - Rendered proof that exact task rechecks do not submit another swap and normal routing stays isolated
affects: [175-06 browser fixture verification]
actuals:
  tokens: 7457
  tasks: 2
  commits: 4
commits: 4
plan_head_before: 630d21a2ab44cb05c49bd7beb107c7de21f868eb
plan_head_after: 888c1ebcedb1103fca4ac5b3840b79d983a1c492
tech-stack:
  added: []
  patterns: [test-action-scoped LiveView fixtures, named process-owned scenarios, exact task and swap counters]
key-files:
  created:
    - scrypath_ops/test/support/phase175_fixture_source.ex
    - scrypath_ops/test/scrypath_ops_web/live/phase175_fixture_live_test.exs
  modified:
    - scrypath_ops/lib/scrypath_ops_web/dev_router.ex
    - scrypath_ops/lib/scrypath_ops_web/live/on_mount.ex
    - scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex
    - scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs
key-decisions:
  - "Phase 175 scenarios are available only through the :phase175 test action; the ordinary Sync and drift route uses normal runtime configuration."
  - "An unknown recovery observation keeps the last known receipt identity visible while the retry outcome remains unknown."
requirements-completed: []
coverage:
  - id: D1
    description: A standalone test-only URL mounts the production SyncDriftLive with allowlisted schema selection and deterministic fake task client.
    verification:
      - kind: unit
        ref: "scrypath_ops/test/scrypath_ops_web/live/phase175_fixture_live_test.exs: test-only standalone route mounts the production SyncDriftLive"
        status: pass
      - kind: unit
        ref: "scrypath_ops/test/scrypath_ops_web/live/phase175_fixture_live_test.exs: standalone exact-UID recheck and normal route isolation"
        status: pass
    human_judgment: false
  - id: D2
    description: Bounded rendered scenarios cover non-first and removed schemas, partial reads, configuration mismatch, exact task states, recovery identity, blockers, and stale callbacks.
    verification:
      - kind: unit
        ref: "MIX_ENV=test mix test test/scrypath_ops_web/live/phase175_fixture_live_test.exs test/scrypath_ops_web/live/sync_drift_live_test.exs --warnings-as-errors; 50 tests, 0 failures"
        status: pass
      - kind: integration
        ref: "mix verify.ops_ui; MIX_TEST_PARTITION=175_owned PGHOST=127.0.0.1 PGPORT=52706; 2 doctests, 332 tests, 0 failures"
        status: pass
      - kind: integration
        ref: "MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors --exclude integration --exclude docs_contract; 2 doctests, 332 tests, 0 failures"
        status: pass
    human_judgment: false
duration: 13m
completed: 2026-10-10
status: complete
---

# Phase 175 Plan 05: Standalone Ops Fixture Summary

**A guarded standalone route now drives production SyncDriftLive through exact-UID rechecks, adverse task and configuration states, recovery identity retention, and fixture isolation.**

## Performance

- **Duration:** 13 minutes
- **Started:** 2026-10-10T14:11:38Z
- **Completed:** 2026-10-10T14:24:37Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added `/ops/phase175/sync-drift` as an explicit `:phase175` test route mounting the production LiveView. Its allowlist and runtime options are test-action scoped; normal `/ops/sync-drift` keeps its ordinary configuration.
- Added process-owned named scenarios and fake-client counters for exact task GETs, settings reads, sync/queue observations, and swap POSTs. Rendered tests prove non-first-schema selection, queued/processing/terminal/unconfirmed outcomes, partial read failures, configuration mismatch, promotion blockers, recovery identity, and stale callback handling.
- Preserved the last known retry identity while a read-only refresh reports unknown. The selected schema and receipt remain visible without turning missing evidence into an outcome or submitting new work.

## Task Commits

**Task 1: Drive one standalone selected-schema task recheck through the production LiveView** — RED `ac1428f`, GREEN `1f1a571`

**Task 2: Expand standalone fixtures to adverse recovery, task and promotion controls** — RED `d3e3044`, GREEN `888c1eb`

## Verification

- Focused fixture and existing SyncDriftLive tests with warnings-as-errors: 50 tests, 0 failures, on Elixir 1.19.0 / OTP 28.1.
- Canonical `mix verify.ops_ui` with owned Postgres at `127.0.0.1:52706` and partition `175_owned`: 2 doctests, 332 tests, 0 failures.
- Full Ops compile/test with `--warnings-as-errors` (excluding integration and docs-contract tags): 2 doctests, 332 tests, 0 failures.
- Logs: `/private/tmp/scrypath-phase173-20261006-155750/evidence/phase175/175-05-focused-final.log`, `175-05-ops-suite-final.log`, and `175-05-warnings-as-errors.log`.
- The pre-existing core compiler warning at `scrypath/lib/scrypath/sync.ex:61` remains visible; all requested commands exited successfully, and no warning was suppressed.

## Fixture Contract for Plan 175-06

Open `/ops/phase175/sync-drift?schema=ScrypathOps.Test.OpsPostB&scenario=<name>` in the owned test app. Supported scenario names are `accepted-processing`, `accepted-queued`, `accepted-succeeded`, `accepted-failed`, `accepted-cancelled`, `accepted-wrong-uid`, `accepted-malformed`, `accepted-timeout`, `accepted-slow-processing`, `sync-error`, `queue-error`, `config-mismatch`, `config-error`, `promotion-blocked`, `removed-schema`, `retry-active`, and `retry-expired`. Unknown names produce an empty allowlist and are rejected. Recovery scenarios use an explicit registered receipt handle and generation; invalidating that handle exercises the expired/unknown read while preserving its known identity.

Fixture Agent counters are `task_calls` (ordered exact UIDs), `tasks_calls`, `settings_calls`, `jobs_calls`, and `swap_post_count`. The accepted processing scenario starts with UID `17501`; clicking “Check swap status” GETs that same UID and leaves the swap POST count at one. Scenario state lives in the test process and does not configure the regular route. The browser matrix can assert each rendered state alongside these counters.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Retained known retry evidence across an unavailable refresh**
- **Found during:** Task 2
- **Issue:** The production view cleared the last known receipt identity as soon as a read-only refresh began or returned an unknown result, contrary to the Phase 175 recovery contract.
- **Fix:** Keep the existing evidence during refresh and retain it when the new observation has no receipt map; update the existing regression assertion and prove this through the standalone rendered fixture.
- **Files modified:** `scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex`, `scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs`, `scrypath_ops/test/scrypath_ops_web/live/phase175_fixture_live_test.exs`
- **Commit:** `888c1eb`

## Requirements

OPUX-20, OPUX-21, and OPUX-22 remain pending. This plan supplies the standalone fixture; plan 175-06 and independent phase verification still need to complete before phase requirements are marked done.

## Self-Check: PASSED

- Summary file exists at the planned phase path.
- All four task commits (`ac1428f`, `1f1a571`, `d3e3044`, `888c1eb`) are ancestors of the current HEAD.
- The persisted plan ledger measures four plan commits from `630d21a` through `888c1eb`.
