---
phase: 05-reindexing-and-operational-workflows
plan: 02
subsystem: api
tags: [elixir, ecto, meilisearch, reindexing, operational-workflows, tdd]
requires:
  - phase: 05-01
    provides: schema-declared settings reflection and validated reindex option contracts
  - phase: 02-meilisearch-core-sync
    provides: Req-backed Meilisearch transport and normalized task metadata handling
provides:
  - explicit Meilisearch client endpoints for index creation, settings updates, and index swaps
  - Meilisearch-native helper modules for target-index settings application and lifecycle operations
  - public Scrypath.Meilisearch escape-hatch wrappers for managed reindex orchestration
affects: [05-03, 05-04, reindexing, backfill, meilisearch, operator-workflows]
tech-stack:
  added: []
  patterns: [TDD for operator helpers, explicit target-index lifecycle helpers, Meilisearch-only operational escape hatch]
key-files:
  created:
    - .planning/phases/05-reindexing-and-operational-workflows/05-02-SUMMARY.md
    - lib/scrypath/meilisearch/index_management.ex
    - lib/scrypath/meilisearch/settings.ex
  modified:
    - lib/scrypath/meilisearch/client.ex
    - lib/scrypath/meilisearch.ex
    - test/scrypath/meilisearch_test.exs
key-decisions:
  - "Kept index lifecycle verbs under Scrypath.Meilisearch and out of the common backend behaviour."
  - "Made settings application explicitly index-scoped so rebuild flows can target a separate index without touching the live one."
  - "Let IndexManagement compute live and target names together while honoring target_index overrides end to end."
patterns-established:
  - "Meilisearch lifecycle operations use explicit caller-provided or helper-resolved index names instead of hidden recomputation in the client."
  - "Schema-declared settings are merged with runtime overrides only at the Meilisearch helper layer, not during ordinary sync or search."
requirements-completed: [OPER-03]
duration: 3min
completed: 2026-04-16
---

# Phase 05 Plan 02: Meilisearch Lifecycle Summary

**Explicit Meilisearch index creation, settings application, and cutover helpers for Phase 5 reindex orchestration**

## Performance

- **Duration:** 3 min
- **Started:** 2026-04-16T12:52:30Z
- **Completed:** 2026-04-16T12:55:29Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added concrete Meilisearch client support for `/indexes`, `/indexes/:uid/settings`, and `/swap-indexes`.
- Added `Scrypath.Meilisearch.Settings` and `Scrypath.Meilisearch.IndexManagement` for explicit target-index operations.
- Exposed `apply_settings/3`, `create_index/3`, and `swap_indexes/2` from `Scrypath.Meilisearch` without widening the common backend API.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add explicit Meilisearch client endpoints for index creation, settings, and swaps per OPER-03** - `d91c835` (test), `8a274f6` (feat)
2. **Task 2: Build the Meilisearch operational helper layer and public escape-hatch wrappers per OPER-03** - `7f462c0` (test), `15e0276` (feat)

## Files Created/Modified

- `lib/scrypath/meilisearch/client.ex` - adds explicit create-index, update-settings, and swap-indexes requests on the existing Req transport.
- `lib/scrypath/meilisearch/settings.ex` - resolves schema settings plus runtime overrides and applies them to an explicit index.
- `lib/scrypath/meilisearch/index_management.ex` - computes live and target index names and delegates native lifecycle operations through the client.
- `lib/scrypath/meilisearch.ex` - exposes the Meilisearch-only operational escape hatch and shares task normalization.
- `test/scrypath/meilisearch_test.exs` - covers the new endpoints, helper wrappers, and target-index override behavior.

## Decisions Made

- Kept lifecycle behavior under `Scrypath.Meilisearch` so the common backend seam remains narrow and unchanged.
- Used an explicit `index_name` argument for settings application instead of deriving it from ordinary sync/search config.
- Preserved the existing response normalization path by reusing the client transport and shared task-shaping helper.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 5 now has the Meilisearch-native lifecycle primitives needed for bulk backfill and managed reindex orchestration.
- Later plans can call settings application and cutover helpers directly while keeping live-index mutation explicit.

## Self-Check: PASSED

- Summary file created at `.planning/phases/05-reindexing-and-operational-workflows/05-02-SUMMARY.md`
- Task commits present: `d91c835`, `8a274f6`, `7f462c0`, `15e0276`

---
*Phase: 05-reindexing-and-operational-workflows*
*Completed: 2026-04-16*
