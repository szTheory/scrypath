---
phase: 81-edge-normalization-errors-and-phoenix-wrappers
plan: 02
subsystem: api
tags: [scrypath, phoenix, liveview, docs-contracts, query-params]
requires:
  - phase: 81-01
    provides: request-edge normalization and structured query-param errors
provides:
  - optional pure Phoenix wrappers over the core query-param contract
  - compile-checked Phoenix fixture adoption for controller and LiveView edges
  - guide and docs-contract coverage for the wrapper-only Phoenix story
affects: [phase-82, phoenix-guides, docs-contracts]
tech-stack:
  added: []
  patterns: [pure wrapper helpers, handle_params-first normalization, compile-checked guide fixtures]
key-files:
  created:
    - lib/scrypath/phoenix.ex
    - test/scrypath/phoenix_test.exs
  modified:
    - test/support/docs/phoenix_example_case.ex
    - test/support/docs/phoenix_examples_test.exs
    - test/support/docs/phoenix_request_shape_smoke_test.exs
    - test/scrypath/docs_contract_test.exs
    - guides/phoenix-contexts.md
    - guides/phoenix-liveview.md
    - guides/phoenix-controllers-and-json.md
    - guides/faceted-search-with-phoenix-liveview.md
key-decisions:
  - "Kept `Scrypath.Phoenix` pure and framework-light: it delegates normalization, round-trips URL params, and projects renderable values plus errors."
  - "Made `handle_params/3` the single search read path in fixtures; invalid edge input now renders attempted state without searching."
  - "Updated docs contracts to lock the wrapper-only story and to resolve the historical AUDT-01 registry row from canonical requirement archives."
patterns-established:
  - "Phoenix helpers wrap request-edge concerns only; contexts still own `Scrypath.search/3` calls."
  - "Compile-checked docs fixtures should consume shared helpers instead of hand-rolled controller or LiveView parsing."
requirements-completed: [PHX-01, PHX-02]
duration: 9min
completed: 2026-05-22
---

# Phase 81: Edge normalization errors and phoenix wrappers Summary

**Optional Phoenix helpers now wrap Scrypath’s request edge for params, URL round-tripping, and renderable errors while contexts remain the only search boundary.**

## Performance

- **Duration:** 9 min
- **Started:** 2026-05-22T23:10:32Z
- **Completed:** 2026-05-22T23:19:58Z
- **Tasks:** 3
- **Files modified:** 10

## Accomplishments
- Added `Scrypath.Phoenix` with `from_params/1`, `to_query_params/1`, and `to_form_data/1,2` over the core `Scrypath.QueryParams` contract.
- Replaced hand-rolled controller and LiveView request parsing in compile-checked fixtures with helper-based normalization and attempted-state rendering.
- Updated Phoenix guides and docs-contract tests so the published story stays wrapper-only, `handle_params/3`-first, and context-owned.

## Task Commits

1. **Task 1: Add pure optional Phoenix wrappers over the core edge contract** - `f9f2dc3` (feat)
2. **Task 2: Adopt Phoenix helpers in compile-checked fixtures and regressions** - `7530d77` (test)
3. **Task 3: Update Phoenix guides and docs contracts to lock the wrapper-only story** - `b2e053a` (docs)

## Files Created/Modified
- `lib/scrypath/phoenix.ex` - pure wrapper helpers for param normalization delegation, query-param round-tripping, and renderable attempted values plus errors.
- `test/scrypath/phoenix_test.exs` - locks the helper contract independent of Phoenix runtime dependencies.
- `test/support/docs/phoenix_example_case.ex` - adopts the shared helper in JSON and LiveView fixture flows while keeping contexts as the search boundary.
- `test/support/docs/phoenix_examples_test.exs` - proves fixture adoption and refutes runtime/search ownership drift in the helper layer.
- `test/support/docs/phoenix_request_shape_smoke_test.exs` - pins Plug-decoded nested request shapes that the shared helper grammar accepts.
- `test/scrypath/docs_contract_test.exs` - locks the wrapper-only guide language and fixes the historical AUDT-01 lookup to read a canonical archive row.
- `guides/phoenix-contexts.md` - explains the context-first boundary plus the narrow role of `Scrypath.Phoenix`.
- `guides/phoenix-liveview.md` - teaches `handle_params/3`-first normalization with attempted-value rendering on invalid input.
- `guides/phoenix-controllers-and-json.md` - replaces ad hoc page parsing with helper-based request-edge handling.
- `guides/faceted-search-with-phoenix-liveview.md` - aligns the faceted LiveView URL flow with the shared helper and the same normalization contract.

## Decisions Made
- Kept helper names literal and boring instead of adding macros, controller mixins, or generated components.
- Preserved controller and LiveView ownership boundaries by making the helper stop before any context call or search execution.
- Treated attempted params as renderable state, distinct from feature defaults like controller-owned page-size defaults.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Repaired docs-contract lookup for the historical AUDT-01 registry row**
- **Found during:** Task 3 (Update Phoenix guides and docs contracts to lock the wrapper-only story)
- **Issue:** The focused docs-contract suite was blocked by a pre-existing invariant that read the current root `REQUIREMENTS.md` even when the canonical `AUDT-01` row only existed in archived milestone requirement files.
- **Fix:** Taught the test to resolve the first canonical requirements file that still carries the `AUDT-01` registry row.
- **Files modified:** `test/scrypath/docs_contract_test.exs`
- **Verification:** `mix test test/scrypath/phoenix_test.exs test/support/docs/phoenix_examples_test.exs test/support/docs/phoenix_request_shape_smoke_test.exs test/scrypath/docs_contract_test.exs`
- **Committed in:** `b2e053a`

---

**Total deviations:** 1 auto-fixed (Rule 1 bug)
**Impact on plan:** Verification-only repair inside the owned docs-contract surface. No product-scope expansion.

## Issues Encountered
- A delegated executor created the initial `Scrypath.Phoenix` file but did not advance into tests or docs. The remaining work was completed locally from that partial file.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
Phase 82 can now document and example the Phoenix helper layer against a stable request-edge contract without inventing new runtime seams.
The guide and fixture story is compile-checked and aligned with the public wrapper boundary.

## Self-Check: PASSED

- `mix test test/scrypath/phoenix_test.exs test/support/docs/phoenix_examples_test.exs test/support/docs/phoenix_request_shape_smoke_test.exs test/scrypath/docs_contract_test.exs`

---
*Phase: 81-edge-normalization-errors-and-phoenix-wrappers*
*Completed: 2026-05-22*
