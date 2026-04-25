---
phase: 66-runner-library-contract
plan: "02"
subsystem: testing
tags: [scrypath_ops, playbook, runner, liveview, parity, testing]
requires:
  - phase: 66-01
    provides: Canonical runner contract docs and boundary freeze for raw reason handling
provides:
  - Representative runner-vs-library parity matrix for search and search_many seams
  - LiveView regression proving raw run_error survives before failure enrichment
  - Narrow runner normalization for page and facet parity with core Scrypath semantics
affects: [OPS3-03, scrypath_ops, playbook execution, verify.opsui]
tech-stack:
  added: []
  patterns: [Representative parity matrix, raw reason before formatting]
key-files:
  created: [.planning/phases/66-runner-library-contract/66-02-SUMMARY.md]
  modified:
    - scrypath_ops/lib/scrypath_ops/playbook/runner.ex
    - scrypath_ops/test/scrypath_ops/playbook/runner_test.exs
    - scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs
key-decisions:
  - "Keep parity coverage explicit and fixture-local instead of introducing a generalized runner meta-harness."
  - "Align playbook dispatch with direct Scrypath semantics by preserving absent page opts and coercing JSON facet names into existing atoms."
patterns-established:
  - "Runner parity tests compare direct Scrypath results to Runner.run_validated/3 on the same fixture inputs."
  - "LiveView failure tests inspect assign state for raw run_error identity and only shallow-check enriched output."
requirements-completed: [OPS3-03]
duration: 16 min
completed: 2026-04-22
---

# Phase 66 Plan 02: Representative parity matrix Summary

**Runner parity coverage now locks search/search_many success and failure semantics against direct `Scrypath` calls, while `PlaybookLive` tests prove raw failure reasons survive into assign state before enrichment.**

## Performance

- **Duration:** 16 min
- **Started:** 2026-04-22T22:37:00Z
- **Completed:** 2026-04-22T22:53:52Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added the representative runner-vs-library parity matrix for `search`, `search_many`, pre-dispatch config failure, backend/runtime failure, and a multi-search validation edge.
- Fixed runner drift exposed by the parity tests so playbook dispatch no longer injects implicit `page.size` and now coerces JSON facet names into the core atom-based contract.
- Added a downstream LiveView regression test that inspects assigns and proves `run_error` still holds `:stub_hard_failure` while `run_failure_enriched` remains a derived presentation layer.

## Task Commits

1. **Task 1: Add runner-vs-library parity cases in `runner_test.exs`** - `c4c1580` (`feat`)
2. **Task 2: Lock the downstream boundary without freezing UI strings** - `99abf74` (`test`)

_TDD note: Task 1 used a RED commit `edc7099` before the green implementation commit above. Task 2's new regression passed on its first run, so the seam already behaved correctly and the task only needed a coverage commit._

## Files Created/Modified

- `scrypath_ops/lib/scrypath_ops/playbook/runner.ex` - Stops injecting default page opts into playbook dispatch and coerces JSON facet names into existing atoms.
- `scrypath_ops/test/scrypath_ops/playbook/runner_test.exs` - Adds the representative parity matrix and fixture-local schemas/backends for delegated `scrypath_ops` test execution.
- `scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs` - Adds raw-reason assign assertions for a failing async playbook run.

## Decisions Made

- Kept the parity suite explicit and local to `runner_test.exs` so the tests document the five required seams directly instead of hiding them behind a meta-harness.
- Treated the exact `reason` term and result struct modules as the compatibility key; the tests intentionally avoid freezing flash copy or docs-link wording.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed runner-only `page.size` injection and facet string drift**
- **Found during:** Task 1 (Add runner-vs-library parity cases in `runner_test.exs`)
- **Issue:** `Runner.run_validated/3` was adding a default `page.size` for `search_many` and forwarding JSON facet names as strings, which diverged from direct `Scrypath.search/3` / `search_many/2` semantics.
- **Fix:** Updated `build_dispatch_opts/3` to preserve absent page opts and added existing-atom coercion for `facets`.
- **Files modified:** `scrypath_ops/lib/scrypath_ops/playbook/runner.ex`, `scrypath_ops/test/scrypath_ops/playbook/runner_test.exs`
- **Verification:** `mix test scrypath_ops/test/scrypath_ops/playbook/runner_test.exs`; `mix test test/scrypath/search_many_test.exs`
- **Committed in:** `c4c1580`

---

**Total deviations:** 1 auto-fixed (Rule 1)
**Impact on plan:** Necessary correctness fix for the exact contract drift this plan was supposed to catch. No scope creep beyond the runner seam.

## Issues Encountered

- The plan-level verification command `mix test test/scrypath/search_many_test.exs scrypath_ops/test/scrypath_ops/playbook/runner_test.exs` fails in the root app because root test compilation does not load `scrypath_ops` modules. Verification was rerun successfully in native contexts with `mix test test/scrypath/search_many_test.exs` and delegated `mix test scrypath_ops/test/scrypath_ops/playbook/runner_test.exs`.
- Task 2 was marked `tdd="true"`, but the newly added LiveView regression passed on its first run. The behavior already existed; this plan locked it with coverage rather than requiring a green code fix.

## TDD Gate Compliance

- RED gate present for Task 1: `edc7099` (`test(66-02): add failing runner parity matrix`)
- GREEN gate present for Task 1: `c4c1580` (`feat(66-02): align runner parity with scrypath contract`)
- Task 2 added regression coverage only. No RED commit was possible because the new test passed immediately against existing behavior.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 66 is complete for `OPS3-03`; parity and downstream-boundary coverage are in place for Phase 67 verification/doc-contract work.
- Remaining caveat is documentation of the mixed root/`scrypath_ops` verification command limitation if future plans keep referencing that combined invocation.

## Verification

- `grep -n "Scrypath.search(" scrypath_ops/test/scrypath_ops/playbook/runner_test.exs`
- `grep -n "Scrypath.search_many(" scrypath_ops/test/scrypath_ops/playbook/runner_test.exs`
- `grep -n "search happy path\|search_many happy path\|pre-dispatch\|backend/runtime\|multi-search" scrypath_ops/test/scrypath_ops/playbook/runner_test.exs`
- `grep -n "run_error\|run_failure_enriched" scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs`
- `grep -n "stub_hard_failure\|timed_out\|cancelled\|validation_failed" scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs`
- `mix test scrypath_ops/test/scrypath_ops/playbook/runner_test.exs`
- `mix test scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs`
- `mix test test/scrypath/search_many_test.exs`
- `mix verify.opsui`
- `mix test test/scrypath/search_many_test.exs scrypath_ops/test/scrypath_ops/playbook/runner_test.exs` (fails in root context because `scrypath_ops` modules are not compiled there)

## Self-Check: PASSED

- Summary file exists at `.planning/phases/66-runner-library-contract/66-02-SUMMARY.md`
- Commit `edc7099` found in `git log --oneline --all`
- Commit `c4c1580` found in `git log --oneline --all`
- Commit `99abf74` found in `git log --oneline --all`
