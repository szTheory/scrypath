---
phase: 80-public-query-toolkit-contract
plan: 02
subsystem: api
tags: [elixir, search, meilisearch, query-params, docs]
requires:
  - phase: 80-01
    provides: public plain-data Scrypath.QueryParams contract and to_search_args/1 bridge
provides:
  - runtime parity coverage from QueryParams output into Scrypath.search/3
  - Meilisearch payload parity coverage for toolkit-produced search args
  - root-level boundary docs that keep QueryParams at the request edge
affects: [phase-81, phoenix-edge-helpers, search-runtime-boundary]
tech-stack:
  added: []
  patterns: [toolkit-to-runtime parity tests, root boundary documentation]
key-files:
  created: []
  modified:
    - lib/scrypath.ex
    - test/scrypath/search_test.exs
    - test/scrypath/meilisearch/query_test.exs
    - .planning/phases/80-public-query-toolkit-contract/80-02-SUMMARY.md
key-decisions:
  - "Kept runtime parity on Scrypath.search/3 and moved full filter/sort/facet grammar proof to the adapter payload test because no live schema exposes every axis at once."
  - "Documented Scrypath.QueryParams only as request-edge preparation so contexts remain the orchestration boundary."
patterns-established:
  - "Public toolkit output should be proven by comparing it against direct Scrypath.search/3 calls, not by introducing helper executors."
  - "Adapter parity tests can use Query.new/2 on toolkit-produced args to lock payload grammar without widening the runtime surface."
requirements-completed: [QTK-04]
duration: 6min
completed: 2026-05-22
---

# Phase 80 Plan 02: Public Query Toolkit Runtime Parity Summary

**QueryParams runtime parity coverage into `Scrypath.search/3` plus Meilisearch payload proof and root-boundary discoverability**

## Performance

- **Duration:** 6 min
- **Started:** 2026-05-22T12:00:30Z
- **Completed:** 2026-05-22T12:06:41Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Added explicit parity coverage showing `Scrypath.QueryParams.to_search_args/1` feeds the common `Scrypath.search/3` path without a second executor.
- Added Meilisearch payload proof that toolkit-produced args preserve the existing `filter`, `sort`, `facets`, `facetFilters`, and pagination grammar.
- Updated the root `Scrypath` moduledoc to point to `Scrypath.QueryParams` at the request edge while keeping contexts and `Scrypath.search/3` canonical.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add runtime delegation parity tests for toolkit output** - `26ee0dd` (test)
2. **Task 2: Make the root boundary explicit without widening the public runtime** - `02913ad` (docs)

## Files Created/Modified
- `lib/scrypath.ex` - Root-level request-edge note for `Scrypath.QueryParams` and explicit `search/3` runtime boundary wording.
- `test/scrypath/search_test.exs` - Common-path parity coverage comparing toolkit-produced search args to direct `Scrypath.search/3` calls.
- `test/scrypath/meilisearch/query_test.exs` - Adapter-shape parity coverage proving toolkit-produced args keep the existing Meilisearch payload grammar.
- `.planning/phases/80-public-query-toolkit-contract/80-02-SUMMARY.md` - Execution summary for this plan.

## Decisions Made
- Split the proof across the runtime test and the adapter test because the checked-out support schemas separate sortable and facetable contracts.
- Kept `Scrypath.search/3` as the only runtime executor and used `QueryParams.to_search_args/1` strictly as a data bridge.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The first parity test draft used `SearchablePost` with `facets`, which the common validator correctly rejected as `{:unknown_facet, :status}`. The final proof matches the live schema contracts by keeping sortable/filterable parity in `search_test.exs` and full payload grammar parity in `meilisearch/query_test.exs`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 81 can build on a defended edge-to-runtime seam: `QueryParams` prepares plain data, contexts execute search, and the adapter grammar remains unchanged.
- The root API docs now expose the toolkit without implying a second runtime or a Phoenix dependency.

## Verification

- `mix test test/scrypath/query_params_test.exs test/scrypath/search_test.exs test/scrypath/meilisearch/query_test.exs` - PASS

## Self-Check: PASSED

- Confirmed `.planning/phases/80-public-query-toolkit-contract/80-02-SUMMARY.md` exists on disk.
- Confirmed task commits `26ee0dd` and `02913ad` exist in git history.
