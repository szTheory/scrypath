---
phase: 184-explicit-and-lean-dependency-graphs
plan: "01"
subsystem: dependency-management
tags: [elixir, mix, telemetry, req, hex]
requires: []
provides:
  - Mandatory direct Telemetry and approved Req 0.6/0.7 dependency metadata
  - One real Hex archive verified in isolated Req 0.6 and Req 0.7 consumers
affects: [dependency-compatibility, release-packaging]
actuals:
  tokens: 6390
  tasks: 2
  commits: 3
  plan_head_before: 1934c4da410026453160092176c6abd322e9fb7d
  plan_head_after: 270df2f427273a497beeddf082bb58ce23e2cf3f
tech-stack:
  added: []
  patterns:
    - One unpacked Hex artifact is installed into independently resolved consumer workspaces.
key-files:
  created:
    - .planning/phases/184-explicit-and-lean-dependency-graphs/184-01-SUMMARY.md
  modified:
    - mix.exs
    - test/release/consumer_smoke_test.exs
    - test/release/package_metadata_test.exs
key-decisions:
  - "Declare Telemetry ~> 1.0 and Req ~> 0.6.1 or ~> 0.7 directly; keep Oban optional."
  - "Use ~> 0.7.0 only as the concrete Req 0.7 witness while preserving the shipped ~> 0.7 range."
requirements-completed: [DEP-01, DEP-02]
coverage:
  - id: D1
    description: The actual Hex metadata requires direct Telemetry and Req dependencies and preserves optional Oban.
    requirement: DEP-01
    verification:
      - kind: integration
        ref: "MIX_ENV=test mix test test/release/consumer_smoke_test.exs test/release/package_metadata_test.exs --warnings-as-errors (11 tests, 0 failures)"
        status: pass
      - kind: other
        ref: "mix verify.no_optional_deps"
        status: pass
    human_judgment: false
  - id: D2
    description: One real archive works in isolated Req 0.6 and 0.7 consumers with common search, error, Telemetry and package-surface checks.
    requirement: DEP-02
    verification:
      - kind: integration
        ref: "MIX_ENV=test mix test test/release/consumer_smoke_test.exs --warnings-as-errors (6 tests, 0 failures)"
        status: pass
      - kind: integration
        ref: "mix verify.package (108 tests, 0 failures)"
        status: pass
    human_judgment: false
duration: 14min
completed: 2026-10-29
status: complete
---

# Phase 184 Plan 01: Explicit and Lean Dependency Graphs Summary

**Mandatory Telemetry and the approved Req 0.6/0.7 range verified through one Hex archive and independent adopter builds.**

## Performance

- **Duration:** 14 min
- **Started:** 2026-10-29T20:20:54Z
- **Completed:** 2026-10-29T20:35:31Z
- **Tasks:** 2
- **Source files modified:** 3

## Accomplishments

- Declared `{:telemetry, "~> 1.0"}` as mandatory and widened mandatory Req to `~> 0.6.1 or ~> 0.7`; Oban remains optional. Root `mix.lock` did not change.
- Added checks against the real `hex_metadata.config`, including a mutation that removes only Telemetry and is rejected even while Ecto remains present.
- Built one archive and installed it into two consumer roots with separate locks, dependency directories, build directories, Mix homes, and Hex homes. Req `0.6.3` and `0.7.5` both matched their direct witness requirements and their lock entries.
- Both consumers exercised `Scrypath.search/3` through Req.Test. The probes checked the POST path and body, normalized success result, HTTP 503 error result, and search start/stop Telemetry metadata for both outcomes. The same tests checked the eight public operator tasks, maintainer-task exclusion, and absence of Oban from both consumer locks.

## Task Commits

1. **Task 1: Tracer: installed 0.6.x public search emits Telemetry** - `7bd26680` (`feat`)
2. **Task 2 RED: Assert independent Req consumer workspaces** - `027d37a0` (`test`)
3. **Task 2 GREEN: Verify independent Req 0.7 consumer** - `270df2f4` (`feat`)

Plan metadata was committed with this summary.

## Files Created/Modified

- `mix.exs` - declares direct Telemetry and the approved mandatory Req range.
- `test/release/package_metadata_test.exs` - covers project dependency declarations and optional Oban metadata.
- `test/release/consumer_smoke_test.exs` - builds one artifact and verifies both independent consumer witnesses.
- `.planning/phases/184-explicit-and-lean-dependency-graphs/184-01-SUMMARY.md` - records this plan's outcome.

## Decisions Made

- Kept Oban optional and used the narrower `~> 0.7.0` constraint only for the concrete 0.7 consumer witness.
- Kept all cold consumer state disposable; no runtime receipt or consumer workspace was written into the checkout.

## TDD Evidence

- **RED:** `MIX_ENV=test mix test test/release/consumer_smoke_test.exs --warnings-as-errors --name-pattern "same archive has independent Req 0.6 and Req 0.7 consumer workspaces"` exited 2 with one targeted test failure. The named assertion ran after setup and observed `[]` instead of `[:req_0_6, :req_0_7]`, so the failure demonstrated the missing behavior. The complete output was kept at `/private/tmp/scrypath-phase184-184-01/task2-red.log`.
- **GREEN:** The final consumer command passed with six tests and zero failures. Its output showed both witnesses using archive `f4556ac66686bb378ec1504b9b9490e34024e6be`; each consumer lock's Scrypath git SHA matched that archive. `mix verify.package` rebuilt the same packaged source in a separate temporary artifact (`d5d2c78e9280526a3a2987a84904db10b9997c6d`) and passed its full 108-test release contract suite.

## Verification

- `MIX_ENV=test mix test test/release/consumer_smoke_test.exs test/release/package_metadata_test.exs --warnings-as-errors` - 11 tests, 0 failures.
- `mix verify.no_optional_deps` - passed; Oban absent from the isolated build.
- `MIX_ENV=test mix test test/release/consumer_smoke_test.exs --warnings-as-errors` - 6 tests, 0 failures. Consumer lock versions: Req `0.6.3` and `0.7.5`; both locked Scrypath to archive `f4556ac66686bb378ec1504b9b9490e34024e6be`.
- `mix verify.package` - 108 tests, 0 failures; the package workflow contract and archive build passed. The independent run's temporary artifact SHA was `d5d2c78e9280526a3a2987a84904db10b9997c6d`.
- `mix format --check-formatted test/release/consumer_smoke_test.exs` and `git diff --check` - passed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Replaced an unavailable Enum.find!/2 call in consumer setup**

- **Found during:** Task 2
- **Issue:** Setup raised `UndefinedFunctionError` before the consumer tests could run.
- **Fix:** Used `Enum.find/2` with an explicit error if the Req 0.6 witness is absent.
- **Files modified:** `test/release/consumer_smoke_test.exs`
- **Verification:** Consumer suite passed (6 tests, 0 failures); `mix verify.package` passed (108 tests, 0 failures).
- **Committed in:** `270df2f4`

**Total deviations:** 1 auto-fixed (Rule 3 - blocking). **Impact:** Required setup correction only; no scope expansion.

## Issues Encountered

- The first RED command used unsupported Mix option `--grep`, so it failed before test discovery. It was rerun with the supported `--name-pattern` option and produced the intended one-test assertion failure.
- The root `.planning/REQUIREMENTS.md` readiness query reported DEP-01 and DEP-02 blocked because plans 184-07, 184-09, and 184-10 also declare them. Per the shared-ID gate, their global checklist entries remain pending for the orchestrator's later re-evaluation. `STATE.md` and `ROADMAP.md` were not modified.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 184-01 is complete and ready for the next plan. The compatibility evidence covers the concrete locked Req versions `0.6.3` and `0.7.5`; it does not claim that future Req minors were exercised.

---
*Phase: 184-explicit-and-lean-dependency-graphs*
*Completed: 2026-10-29*

## Self-Check: PASSED

- Summary and declared source files exist; all three task commits are ancestors of this worktree HEAD.
- Recorded task verification logs confirm the required tests, no-Oban check, both Req witness versions, matching archive identity, and package verification.
- No edits were made to `STATE.md`, `ROADMAP.md`, or `.planning/config.json`.
