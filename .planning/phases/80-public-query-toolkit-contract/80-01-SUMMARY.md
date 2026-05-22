---
phase: 80-public-query-toolkit-contract
plan: 01
subsystem: api
tags: [elixir, ecto, search, query-params, tdd]
requires: []
provides:
  - public plain-data Scrypath.QueryParams contract
  - internal allowlisted request casting seam for query params
  - contract tests that lock the toolkit boundary to data-only helpers
affects: [phase-81, phoenix-edge-helpers, search-runtime-boundary]
tech-stack:
  added: []
  patterns: [public data-only facade, internal casting seam, request-key allowlist]
key-files:
  created:
    - lib/scrypath/query_params.ex
    - lib/scrypath/query_params/caster.ex
    - test/scrypath/query_params_test.exs
  modified:
    - .planning/phases/80-public-query-toolkit-contract/80-01-SUMMARY.md
key-decisions:
  - "Published QueryParams as a plain map contract instead of a public struct so `%Scrypath.Query{}` stays internal."
  - "Kept the toolkit surface to `cast/1` and `to_search_args/1` so contexts remain the execution boundary."
patterns-established:
  - "Request-edge params should be normalized through an allowlisted mapper before feeding Scrypath.search/3."
  - "Public helper modules can expose runtime-compatible plain data without becoming a second executor."
requirements-completed: [QTK-01]
duration: 1min
completed: 2026-05-22
---

# Phase 80 Plan 01: Public Query Toolkit Contract Summary

**Public `Scrypath.QueryParams` map contract with an internal allowlisted caster and a data-only `to_search_args/1` bridge**

## Performance

- **Duration:** 1 min
- **Started:** 2026-05-22T12:00:50Z
- **Completed:** 2026-05-22T12:01:43Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Added RED-first contract tests for the Phase 80 query toolkit boundary.
- Implemented `Scrypath.QueryParams.cast/1` as the public plain-data facade over request-shaped input.
- Added `Scrypath.QueryParams.Caster` as an internal allowlisted seam and `to_search_args/1` as the bridge into `Scrypath.search/3`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Write the public contract tests for `Scrypath.QueryParams`** - `2821e3b` (test)
2. **Task 2: Implement the public facade and internal casting seam** - `931c0f9` (feat)

## Files Created/Modified
- `lib/scrypath/query_params.ex` - Public plain-data query toolkit facade and bridge to `{text, opts}`.
- `lib/scrypath/query_params/caster.ex` - Internal request-shape caster that maps only recognized keys.
- `test/scrypath/query_params_test.exs` - Contract tests for the public map shape and narrow helper surface.
- `.planning/phases/80-public-query-toolkit-contract/80-01-SUMMARY.md` - Execution summary for this plan.

## Decisions Made
- Used a plain map contract with stable top-level keys instead of publishing a new struct.
- Left validation and execution out of the toolkit so host contexts still own `Scrypath.search/3`.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Ready for Phase 80 plan 02 to add richer normalization and runtime-parity coverage on top of the frozen plain-data contract.
- The toolkit boundary now stays narrow: no Phoenix dependency, no `search/...` helper, and no public `%Scrypath.Query{}` exposure.

## Verification

- `mix test test/scrypath/query_params_test.exs` - PASS

## Self-Check: PASSED

- Confirmed `lib/scrypath/query_params.ex`, `lib/scrypath/query_params/caster.ex`, and `test/scrypath/query_params_test.exs` exist on disk.
- Confirmed task commits `2821e3b` and `931c0f9` exist in git history.
