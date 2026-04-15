---
phase: 01-core-contracts-and-api-shape
plan: 01-02
subsystem: api
tags: [projection, backend, config, ecto]
requires:
  - phase: 01-01
    provides: searchable schema metadata and reflection helpers
provides:
  - projection runtime
  - runtime config normalization
  - internal backend behavior
affects: [phase-02, sync, meilisearch]
tech-stack:
  added: []
  patterns: [projection struct, explicit config merge, narrow backend behavior]
key-files:
  created:
    - lib/scrypath/projection.ex
    - lib/scrypath/config.ex
    - lib/scrypath/backend.ex
    - lib/scrypath/document.ex
    - test/scrypath/projection_test.exs
    - test/scrypath/backend_test.exs
    - test/support/fake_backend.ex
  modified:
    - lib/scrypath.ex
key-decisions:
  - "Custom `search_document/1` projection takes precedence over declarative field projection."
  - "Runtime options merge explicit call-site values over application defaults."
patterns-established:
  - "Projection returns a concrete `Scrypath.Document` struct with source metadata."
  - "Backend extensibility stays behind an internal behavior instead of a public registration API."
requirements-completed: [SCMA-02, SCMA-03, BACK-02]
duration: 1m
completed: 2026-04-15
---

# Phase 1: Core Contracts and API Shape Summary

**Projection runtime, config normalization, and internal backend behavior ready for Meilisearch work**

## Performance

- **Duration:** 1 min
- **Started:** 2026-04-15T18:52:57-04:00
- **Completed:** 2026-04-15T18:53:39-04:00
- **Tasks:** 3
- **Files modified:** 8

## Accomplishments
- Added the projection runtime with default field-based projection and custom hook precedence.
- Introduced explicit runtime config resolution and backend lookup helpers.
- Added focused tests for projection behavior and the fake backend contract.

## Task Commits

Each task was committed atomically:

1. **Task 1: Projection runtime** - `26b04b0` (feat)
2. **Task 2: Runtime config and backend seam** - `60a84ce` (feat)
3. **Task 3: Projection and backend tests** - `08a7930` (test)

## Files Created/Modified
- `lib/scrypath/projection.ex` - projection logic and source detection
- `lib/scrypath/document.ex` - stable internal document struct
- `lib/scrypath/config.ex` - explicit runtime option resolution
- `lib/scrypath/backend.ex` - internal backend behavior callbacks
- `lib/scrypath.ex` - top-level document source reflection now follows projection precedence
- `test/support/fake_backend.ex` - behavior fixture for backend contract tests
- `test/scrypath/projection_test.exs` - projection precedence and failure-mode tests
- `test/scrypath/backend_test.exs` - runtime config precedence and backend contract tests

## Decisions Made
- Custom projection may supply its own `id`, but defaults still derive the document id from the configured field.
- Missing projection fields raise immediately so association-derived data remains explicit.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
Phase 2 can implement a real Meilisearch adapter against `Scrypath.Backend`, consume normalized runtime config from `Scrypath.Config`, and project source records through `Scrypath.Projection.document/2` without changing the public declaration surface.

---
*Phase: 01-core-contracts-and-api-shape*
*Completed: 2026-04-15*
