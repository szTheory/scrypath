---
phase: 01-core-contracts-and-api-shape
plan: 01-03
subsystem: docs
tags: [readme, architecture, docs, exdoc]
requires:
  - phase: 01-01
    provides: searchable schema contract
  - phase: 01-02
    provides: projection runtime and backend seam
provides:
  - product boundary documentation
  - architecture reference
  - module-level API docs
affects: [phase-06, docs, adoption]
tech-stack:
  added: []
  patterns: [meilisearch-first messaging, contract-first documentation]
key-files:
  created:
    - README.md
    - ARCHITECTURE.md
  modified:
    - lib/scrypath.ex
    - lib/scrypath/schema.ex
    - lib/scrypath/projection.ex
key-decisions:
  - "Public docs state that v1 is Meilisearch-first and keep the backend seam explicitly internal."
  - "Module docs reuse the same terminology as README and ARCHITECTURE.md to avoid drift."
patterns-established:
  - "Docs describe operational truth early, including projection changes and later reindex work."
  - "Inline module docs mirror top-level guides instead of inventing separate language."
requirements-completed: [SCMA-01, SCMA-02, SCMA-03, BACK-02]
duration: 1m
completed: 2026-04-15
---

# Phase 1: Core Contracts and API Shape Summary

**Public-facing docs that define Scrypath’s Meilisearch-first boundary and Phase 1 API contracts**

## Performance

- **Duration:** 1 min
- **Started:** 2026-04-15T18:54:09-04:00
- **Completed:** 2026-04-15T18:54:54-04:00
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments
- Wrote a README that explains what Scrypath is, what remains deferred, and how projection works.
- Added an architecture guide separating the public surface from the internal backend seam.
- Added module docs so the code-level API language matches the top-level docs.

## Task Commits

Each task was committed atomically:

1. **Task 1: README product boundary** - `e042d17` (docs)
2. **Task 2: Architecture guide** - `01ce702` (docs)
3. **Task 3: Module docs** - `6cfa2ef` (docs)

## Files Created/Modified
- `README.md` - product boundary, schema declaration, projection, and roadmap overview
- `ARCHITECTURE.md` - public surface, projection flow, backend seam, and deferred work
- `lib/scrypath.ex` - module docs for runtime reflection helpers
- `lib/scrypath/schema.ex` - module docs for the metadata-only macro contract
- `lib/scrypath/projection.ex` - module docs for projection precedence and preload expectations

## Decisions Made
- Kept the README focused on product boundary and contract language rather than prematurely documenting unbuilt sync behavior.
- Described association-derived projection as explicit preload work everywhere it appears.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
Running `mix test` across the whole suite emits a benign warning because `test/support/*.ex` files are support fixtures, not `_test.exs` files. The suite still passes cleanly.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
The code and docs now describe the same public shape, which gives Phase 2 a stable contract to extend with a Meilisearch adapter and sync flows without re-explaining the product boundary.

---
*Phase: 01-core-contracts-and-api-shape*
*Completed: 2026-04-15*
