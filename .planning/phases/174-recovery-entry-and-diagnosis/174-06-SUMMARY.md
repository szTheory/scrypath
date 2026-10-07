---
phase: 174-recovery-entry-and-diagnosis
plan: 06
subsystem: operator-ui/testing
tags: [phoenix, liveview, sigra, meilisearch, oban, tdd]

# Dependency graph
requires:
  - phase: 174-05
    provides: Source-qualified failed-work inspection and recovery diagnosis.
  - phase: 174-03
    provides: Safe stale-sudo return behavior and selected-schema validation.
  - phase: 174-04
    provides: Production Control Room and Search health views for controlled evidence.
provides:
  - Test-only Phase174 standalone routes mounting production operator LiveViews and built assets.
  - Deterministic A/B and source-collision fixtures exercised through production data boundaries.
  - Executable real-Sigra stale-sudo redirect and explicit selected-A return proof.
affects: [174-08, standalone-browser-proof]

# Actuals (#2632), measured from the plan diff using chars/4.
actuals:
  tokens: 60650
  tasks: 2
  commits: 5

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Test-only LiveView actions select deterministic fixture sources at existing data-fetch boundaries.
    - Recovery identities remain source-qualified when backend and queue records share a numeric ID.

key-files:
  created:
    - scrypath_ops/test/support/phase174_fixture_source.ex
    - scrypath_ops/test/scrypath_ops_web/live/phase174_fixture_live_test.exs
    - .planning/phases/174-recovery-entry-and-diagnosis/174-06-T2-GREEN.json
  modified:
    - scrypath_ops/lib/scrypath_ops_web/dev_router.ex
    - scrypath_ops/lib/scrypath_ops_web/endpoint.ex
    - scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex
    - scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex
    - scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex
    - scrypath_ops/config/test.exs

key-decisions:
  - "Keep fixture routing and provider configuration restricted to MIX_ENV=test and the :phase174 route action."
  - "Use real Gating with a stale test-only OperatorContext; the confirmation landing proves navigation only and never replays the interrupted action."
  - "Leave OPUX-16 through OPUX-19 pending until Plan 174-08 supplies the required browser proof."

requirements-completed: []

# Plan 08 owns browser acceptance. This plan proves executable fixture and gate behavior only.
coverage:
  - id: D1
    description: "Test-only standalone routes render production LiveViews over deterministic source-qualified fixtures while normal /ops/health remains isolated."
    verification:
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/live/phase174_fixture_live_test.exs#test-only routes target production views and deterministic source fixtures"
        status: pass
    human_judgment: false
  - id: D2
    description: "The real stale-sudo gate navigates to the configured confirmation destination and an explicit new navigation returns to validated schema A without a receipt."
    verification:
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/live/phase174_fixture_live_test.exs#standalone fixture renders selected A and returns from the real stale-sudo gate"
        status: pass
    human_judgment: false

# Task commit ledger measurement (#3968): 5 commits after plan head.
commits: 5
plan_head_before: 58fde1d8dda457c92df7aced959e0255519a426d
plan_head_after: c2706f186a6223adc0bc753065a30fe19bc70d33

# Metrics
duration: 301min
started: 2026-10-07T13:11:14Z
completed: 2026-10-07T18:12:39Z
status: complete
---

# Phase 174 Plan 06: Standalone Recovery Fixture and Gated Return Summary

Test-only standalone routes now drive the production Control Room, Search health, and Failed sync work views with deterministic A/B evidence; the real Sigra stale-sudo branch returns only to the validated A target.

## Performance

- **Duration:** 301 minutes
- **Started:** 2026-10-07 13:11:14 UTC
- **Completed:** 2026-10-07 18:12:39 UTC
- **Tasks:** 2/2
- **Files modified:** 25 files across implementation and committed evidence

## Accomplishments

- Added a `MIX_ENV=test` standalone route and asset prefix backed by the real production LiveViews. Deterministic fixtures cover A-selected/B-worse posture, backend/queue ID collisions, unavailable and retained source states, unknown/no-success states, long values, and empty data.
- Wired fixture state only through the Phase174 test route action. Runtime tests verify the ordinary `/ops/health` route keeps its normal action and options, while Phase174 refresh, schema selection, handoff links, unavailable targets, and source-qualified rows behave as expected.
- Exercised the actual `Sigra.Audit`-enabled Gating implementation. A stale fixture context redirects to `/sudo/confirm` with only the selected A return path; the landing responds successfully, and a deliberate new LiveView navigation revalidates A with empty recovery receipts. No host confirmation, mutation approval, or retry replay was simulated.

## Task Commits

Each task used a test-only RED commit followed by its implementation commit:

1. **Task 1: Expose isolated Phase174 standalone fixture route through real LiveViews** — `e6f4f54` (RED), `e537a2b` (GREEN).
2. **Task 2: Drive standalone fixture states and real Sigra safe-return seam** — `f19ec6e` (RED), `00ca41e` (GREEN), `c2706f1` (mount-only stale fixture context refinement).

The plan had five commits measured from `plan_head_before`; the SUMMARY is committed separately before state tracking.

## Files Created/Modified

- `scrypath_ops/test/support/phase174_fixture_source.ex` and `scrypath_ops/config/test.exs` provide deterministic test-only backend and Oban source records.
- `scrypath_ops/lib/scrypath_ops_web/dev_router.ex` and `scrypath_ops/lib/scrypath_ops_web/endpoint.ex` expose the route, confirm landing, and built assets only in tests.
- `scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex`, `posture_live.ex`, and `failed_sync_live.ex` read selected fixture state only on the Phase174 action while normal routes continue reading current application configuration.
- `scrypath_ops/test/scrypath_ops_web/live/phase174_fixture_live_test.exs` exercises route identity, A/B evidence, refresh, selector patch, unavailable target, duplicate source IDs, and real gated return.
- `.planning/phases/174-recovery-entry-and-diagnosis/174-06-T*-*.{json,tap,full.log}` and the Ops/precommit logs retain direct native evidence and the initial regression notes.

## TDD Gate Compliance

| Task | RED evidence | RED verdict | GREEN evidence |
| --- | --- | --- | --- |
| T1 | `174-06-T1-RED.json` | `RED_EVIDENCE_OK`; missing test-only route assertion | Focused native TAP: 1/1 passed |
| T2 | `174-06-T2-RED.json` | `RED_EVIDENCE_OK`; target test failed on missing B evidence | Fixture + Sigra Gating native TAP: 10/10 passed |

## Decisions Made

- The Phase174 provider remains configured only in test config and is consumed only by the `:phase174` test route action. The ordinary `/ops/health` view is asserted at runtime to remain outside fixture mode.
- Source identities remain the row and action identity, so Backend task `501` and Queue job `501` render as two distinct rows.
- The stale `OperatorContext` is assigned only inside the Phase174 test-route mount branch. The confirm page is a navigation target; returning requires a separate explicit navigation and does not infer host authentication or action approval.
- OPUX-16, OPUX-17, OPUX-18, and OPUX-19 remain pending. Plan 06 supplies fixture/gate evidence; Plan 08 owns browser proof and final acceptance.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Preserve dynamic configuration reads on normal routes**
- **Found during:** Task 2 full Ops verification
- **Issue:** The first integration reused mount-time options and allowlists on normal Control Room refresh and Failed sync selection, breaking two existing tests that changed configuration after mount.
- **Fix:** Use fixture options and allowlists only when a test Phase174 fixture scenario is active; normal routes continue fetching current `ScrypathOps.Schemas` configuration.
- **Files modified:** `control_room_live.ex`, `failed_sync_live.ex`
- **Verification:** Final Ops precommit passed 273 TAP cases with zero failures.
- **Committed in:** `00ca41e`

**2. [Rule 1 - Bug] Carry the canonical failed-sync path through the real stale-sudo gate**
- **Found during:** Task 2 stale-sudo return test
- **Issue:** The standalone LiveView socket did not provide a usable current host path, so Gating fell back to `/` even though schema A was validated.
- **Fix:** Assign the current canonical failed-sync path with the selected allowlisted schema before invoking Gating; Gating still validates and appends the selected schema itself.
- **Files modified:** `failed_sync_live.ex`
- **Verification:** Focused native test asserts the exact safe confirmation URL and explicit return to A.
- **Committed in:** `00ca41e`

**Total deviations:** 2 auto-fixed correctness issues. Both were required to preserve ordinary route behavior and to prove the planned safe-return seam; scope remained within Task 2.

## Verification

- `cd scrypath_ops && mix test test/scrypath_ops_web/live/phase174_fixture_live_test.exs test/scrypath_ops/integrations/sigra/gating_test.exs` — 10 tests, 0 failures. `Code.ensure_loaded?(Sigra.Audit)` is asserted before the gated action.
- `cd scrypath_ops && mix test` — 273 TAP cases including two doctests, 0 failures.
- `cd scrypath_ops && mix precommit` — exit 0; compile, unused-dependency check, formatting, Nav contract, and all 273 TAP cases passed.
- The compile output includes the existing `Scrypath.Sync.sync_related/3` incompatible-types warning; the canonical precommit command nevertheless completed successfully.

The captured evidence proves server-rendered view state and the real Sigra redirect/return seam. It does not prove browser pixels, host confirmation, mutation approval, retry execution, live Meilisearch behavior, or the final UI acceptance criteria. Plan 08 must supply the disposable browser proof before the four OPUX requirements are considered complete.

## Issues Encountered

The initial RED attempts had a compile typo and a missing test import; both were corrected before accepting their behavioral RED evidence. During GREEN work, tests caught an absent stale context and an unavailable post-navigation process assertion; the route now supplies only a stale test context, and the proof checks the confirm navigation plus fresh returned-view state instead. The first full Ops run also exposed the two normal-route configuration regressions documented above; both were fixed and the final full suite and precommit passed.

## User Setup Required

None. The locked optional Sigra dependency was already compiled in the standalone Ops app.

## Next Phase Readiness

Plan 08 can use `/ops/phase174` and its health/failed-sync children for its disposable browser run. Keep the original preview, Phase173 checkout, and earlier worktree untouched. OPUX-16 through OPUX-19 remain pending until that browser proof and final-source verification are complete; do not start Phase 175 from this plan.

## Self-Check: PASSED

- SUMMARY file and T1/T2 RED plus final T2 GREEN evidence files exist.
- All five measured plan commits are ancestors of `plan_head_after`.
- Final focused and canonical Ops precommit evidence is retained in the phase directory.

---
*Phase: 174-recovery-entry-and-diagnosis*
*Completed: 2026-10-07*
