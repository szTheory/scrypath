---
phase: 174-recovery-entry-and-diagnosis
plan: 02
subsystem: ui
tags: [phoenix-liveview, operator-ui, playwright, posture]

# Dependency graph
requires:
  - phase: 173-shared-visual-foundation-and-operational-time
    provides: shared operator shell, controls, tokens, and timestamp rendering
  - phase: 174-recovery-entry-and-diagnosis
    provides: selected-schema recovery route proved by Plan 174-01
provides:
  - Control Room verdict with observed cause and affected schema scope
  - One generic primary Search health route for degraded state
  - Truthful handling of setup states and partial refresh observations
affects: [174-03-search-health, 175]

# Actuals (#2632)
actuals:
  tokens: 4635
  tasks: 2
  commits: 2
plan_head_before: a7e8472160213557ca7780593a254659d0058334
plan_head_after: be1882d9f65caccb147d2abf4e59f8c6b0861216

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Preserve the last complete posture snapshot when a refresh has incomplete schema evidence.
    - Keep the generic health destination separate from schema-specific recovery identity.

key-files:
  created: []
  modified:
    - scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex
    - scrypath_ops/test/scrypath_ops_web/live/control_room_live_test.exs
    - examples/scrypath_ecommerce/e2e/operator.spec.ts

key-decisions:
  - "Keep Control Room as an orientation point: observed state and scope first, one generic health route for degraded state, and change/search intents secondary."
  - "Retain the last successful observation on a partial refresh and never announce refresh success without complete schema observations."
  - "Keep unconfigured and missing-backend guidance distinct, with no retry or recovery offer."

patterns-established:
  - "Fleet-level health routes omit schema identity; schema-specific identity begins at the Search health diagnosis handoff."
  - "When refresh evidence is partial, disclose the affected scope and label retained evidence as the last successful observation."

requirements-completed: [OPUX-16]

coverage:
  - id: D1
    description: "Control Room presents truthful observed state and affected scope before one safe health route, while setup and partial-refresh states avoid false recovery or freshness claims."
    requirement: OPUX-16
    verification:
      - kind: unit
        ref: "scrypath_ops/test/scrypath_ops_web/live/control_room_live_test.exs — 6 tests"
        status: pass
      - kind: e2e
        ref: "BUILDX_CONFIG=/private/tmp/scrypath-buildx make -C examples/scrypath_ecommerce verify-mounted — 4 browser checks"
        status: pass
    human_judgment: false

duration: 20min
completed: 2026-10-11
status: complete
---

# Phase 174 Plan 02: Control Room Summary

**Control Room now leads with current posture and affected schema scope, routes degraded health to one generic diagnosis page, and preserves clear last-known evidence when refreshes are partial.**

## Performance

- **Duration:** approximately 20 minutes
- **Started:** 2026-10-11T02:23:00Z (approximate)
- **Completed:** 2026-10-11T02:43:17Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Replaced the duplicated recovery card and repeated incident copy with one verdict, observed reason/scope, one degraded-state Search health route, secondary change/search actions, and a quiet operator guide.
- Added distinct no-schema and missing-backend setup guidance and the exact healthy freshness caveat.
- Retained the prior complete observation and surfaced current affected scope after incomplete refresh; only complete observations produce the refresh-success message.
- Updated the mounted recovery journey to verify Control Room reading order, unique primary route, secondary intents, and continuation into Search health.

## Task Commits

1. **Task 1: Put Control Room state, affected scope, and one safe route first** — `d298777` (feat)
2. **Task 2: Assert the Control Room entry route in the mounted recovery journey** — `be1882d` (test)

**Plan metadata:** pending summary commit.

## Files Created/Modified

- `scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex` — posture hierarchy, exact setup guidance, affected-scope detail, and refresh retention.
- `scrypath_ops/test/scrypath_ops_web/live/control_room_live_test.exs` — rendered healthy/degraded/setup states, DOM order, and refresh outcomes.
- `examples/scrypath_ecommerce/e2e/operator.spec.ts` — mounted route and secondary-intent assertions in the existing operator journey.

## Decisions Made

Kept the Control Room fleet-level and concise. It uses the existing Posture classifications, existing mounted route prefix, existing OpsUi components, and no added dependency or authorization behavior.

## Deviations from Plan

None. The initial mounted run exposed two assertion mismatches in the planned surface migration; the fixture’s `Elixir.` module prefix is normalized to Elixir’s rendered module identity, and the existing promotion journey now follows the renamed **Verify a change** destination.

## Issues Encountered

- Final focused ControlRoomLive suite passed: `ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.1 mix test test/scrypath_ops_web/live/control_room_live_test.exs` — 6 tests, 0 failures.
- Final mounted verification passed: `BUILDX_CONFIG=/private/tmp/scrypath-buildx make -C examples/scrypath_ecommerce verify-mounted` — 4 browser checks passed, including both operator journeys.
- The first full Ops `mix precommit` run (seed **219458**) reported 250 tests and 2 doctests with one teardown failure in the unrelated `ScrypathOpsWeb.SyncDriftLiveTest` case “observer exits from a previous schema cannot change the current screen”: `GenServer.stop(...): no process`, raised in `ExUnit.OnExitHandler.exec_callback/1` from `test/scrypath_ops_web/live/sync_drift_live_test.exs:269`. An isolated rerun with `ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.1 mix test test/scrypath_ops_web/live/sync_drift_live_test.exs:269` passed (seed **367094**, 1 test, 0 failures). Treat the full-suite result as initial and unreproduced pending the orchestrator’s planned rerun; no SyncDrift source was changed.

## User Setup Required

None.

## Next Phase Readiness

Control Room’s rendered and mounted contract is verified. Plan 174-03 can proceed with the shared generic Search health entry and this plan’s state/scope hierarchy.

---
*Phase: 174-recovery-entry-and-diagnosis*
*Plan: 02*
*Completed: 2026-10-11*

## Self-Check: PASSED

- Summary artifact exists at the required phase path.
- Task commits `d298777` and `be1882d` are ancestors of the current plan branch.
- `git diff --check` passed for the working tree.
