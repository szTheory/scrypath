---
phase: 81-edge-normalization-errors-and-phoenix-wrappers
plan: 01
subsystem: api
tags: [scrypath, query-params, phoenix, request-edge, search]
requires: []
provides:
  - request-edge normalization for browser-shaped query params
  - structured aggregate error payload for owned Scrypath namespaces
  - runtime parity proof from normalized params into Scrypath.search/3
affects: [81-02, phoenix-guides, docs-contracts]
tech-stack:
  added: []
  patterns: [plain-data request normalization, aggregate edge errors, runtime-parity regression]
key-files:
  created: [lib/scrypath/query_params/error.ex]
  modified:
    - lib/scrypath/query_params.ex
    - lib/scrypath/query_params/caster.ex
    - test/scrypath/query_params_test.exs
    - test/scrypath/search_test.exs
key-decisions:
  - "Kept `cast/1` as the runtime-compatible seam and introduced `normalize/1` as the non-raising browser-param entrypoint."
  - "Rejected browser-facing `per_query` input with a stable structured issue instead of widening the public edge grammar."
  - "Canonicalized normalized keyword ordering so plain-data output stays deterministic across request maps and validation passes."
patterns-established:
  - "Request-edge helpers normalize once and stop at plain data; `Scrypath.search/3` remains the only executor."
  - "Owned namespaces validate strictly and return aggregate field-scoped issues instead of raising."
requirements-completed: [QTK-02, QTK-03]
duration: 3min
completed: 2026-05-22
---

# Phase 81: Edge normalization errors and phoenix wrappers Summary

**Browser-shaped query params now normalize once into the public plain-data search contract, return structured edge errors, and prove parity back into `Scrypath.search/3`.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-05-22T23:07:52Z
- **Completed:** 2026-05-22T23:10:32Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments
- Added `Scrypath.QueryParams.normalize/1` as the request-edge API with aggregate `form_errors`, `field_errors`, and flat `errors`.
- Implemented strict owned-namespace normalization for `filter`, `sort`, `page`, `facets`, and `facet_filter` without exposing `%Scrypath.Query{}` or Phoenix dependencies.
- Locked runtime parity so normalized request params feed `QueryParams.to_search_args/1` into the canonical `Scrypath.search/3` path.

## Task Commits

1. **Task 1: Freeze the public normalization and error contracts** - `7d64ee8` (feat)
2. **Task 2: Implement browser-param normalization with strict owned-namespace validation** - `7e383e9` (fix)
3. **Task 3: Lock canonical runtime delegation on the normalized output** - `f6a4c5b` (test)

## Files Created/Modified
- `lib/scrypath/query_params.ex` - documents and exposes the new non-raising `normalize/1` entrypoint.
- `lib/scrypath/query_params/caster.ex` - implements request-shape normalization, structured issue aggregation, and deterministic keyword ordering.
- `lib/scrypath/query_params/error.ex` - defines the plain structured edge-error shape.
- `test/scrypath/query_params_test.exs` - covers success grammar, aggregate invalid-input behavior, alias handling, `per_query` rejection, and deterministic ordering.
- `test/scrypath/search_test.exs` - proves normalized params still delegate through `Scrypath.search/3`.

## Decisions Made
- Kept top-level unknown params ignored while treating malformed keys inside owned namespaces as explicit issues.
- Reused `Scrypath.Options` validators after conversion so browser grammar cannot drift from the canonical runtime grammar.
- Preserved `cast/1` for already-runtime-compatible callers instead of silently changing the previously shipped Phase 80 contract.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Canonicalized normalized keyword ordering**
- **Found during:** Task 2 (Implement browser-param normalization with strict owned-namespace validation)
- **Issue:** `page` order drifted after validation because the validator returned a map that was converted back to a keyword list without a stable key order.
- **Fix:** Canonicalized `page` ordering and sorted normalized field-map keyword pairs for deterministic plain-data output.
- **Files modified:** `lib/scrypath/query_params/caster.ex`, `test/scrypath/query_params_test.exs`
- **Verification:** `mix test test/scrypath/query_params_test.exs test/scrypath/search_test.exs`
- **Committed in:** `7e383e9`

---

**Total deviations:** 1 auto-fixed (Rule 1 bug)
**Impact on plan:** Correctness-only fix. No scope creep and no public API expansion.

## Issues Encountered
None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
The core request-edge contract is now stable for Phoenix wrappers to consume in `81-02`.
No blocker remains for URL round-tripping, form projection, or fixture/doc adoption work.

## Self-Check: PASSED

- `mix test test/scrypath/query_params_test.exs test/scrypath/search_test.exs`

---
*Phase: 81-edge-normalization-errors-and-phoenix-wrappers*
*Completed: 2026-05-22*
