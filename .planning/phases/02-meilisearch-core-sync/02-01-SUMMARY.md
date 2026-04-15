---
phase: 02-meilisearch-core-sync
plan: 02-01
subsystem: api
tags: [elixir, ecto, meilisearch, sync, identity]
requires:
  - phase: 01-core-contracts-and-api-shape
    provides: metadata-only schema declarations, runtime config resolution, document projection, backend behaviour
provides:
  - explicit Scrypath upsert and delete runtime verbs
  - shared list-oriented sync orchestration for single and batch flows
  - canonical delete identity resolution via metadata or search_document_id/1
affects: [meilisearch backend runtime, manual sync flows, future oban sync, docs]
tech-stack:
  added: []
  patterns: [thin public delegates, shared sync orchestration, dedicated delete identity helper]
key-files:
  created:
    - lib/scrypath/sync.ex
    - lib/scrypath/identity.ex
    - test/scrypath/sync_test.exs
    - test/scrypath/identity_test.exs
  modified:
    - lib/scrypath.ex
key-decisions:
  - "Kept explicit public write verbs on Scrypath and delegated orchestration into Scrypath.Sync."
  - "Resolved delete ids through Scrypath.Identity so delete flows stay independent from search_document/1 projection."
patterns-established:
  - "Single-record and batch writes should normalize to list-oriented backend calls before dispatch."
  - "Delete identity should come from schema metadata or search_document_id/1, never from projected document payloads."
requirements-completed: [SYNC-01, SYNC-02, SYNC-03]
duration: 2 min
completed: 2026-04-15
---

# Phase 2 Plan 02-01: Common Sync Surface Summary

**Explicit Scrypath sync and delete verbs with shared orchestration and dedicated delete identity resolution**

## Performance

- **Duration:** 2 min
- **Started:** 2026-04-15T19:36:15-04:00
- **Completed:** 2026-04-15T23:37:56Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added `Scrypath.sync_record/3`, `sync_records/3`, `delete_record/3`, `delete_document/3`, and `delete_documents/3` as the public write-path surface.
- Introduced `Scrypath.Sync` as the shared orchestration layer for single-record and batch upsert/delete flows.
- Added `Scrypath.Identity` so delete ids resolve from metadata or `search_document_id/1` without relying on `search_document/1`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add the common sync facade and orchestration layer** - `3fcfd58` (`test`)
2. **Task 1: Add the common sync facade and orchestration layer** - `71c8f63` (`feat`)
3. **Task 2: Add canonical delete identity resolution** - `9735cc3` (`test`)
4. **Task 2: Add canonical delete identity resolution** - `8f67773` (`feat`)

## Files Created/Modified

- `lib/scrypath.ex` - Added explicit public sync and delete delegates under `Scrypath.*`.
- `lib/scrypath/sync.ex` - Centralized runtime config resolution, projection, and list-oriented backend dispatch.
- `lib/scrypath/identity.ex` - Added canonical document id helpers and custom hook detection.
- `test/scrypath/sync_test.exs` - Added contract tests for public sync/delete verbs and shared orchestration.
- `test/scrypath/identity_test.exs` - Added contract tests for default and custom delete identity resolution.

## Decisions Made

- Kept the public write-path contract under `Scrypath.*` and pushed implementation detail into helper modules to preserve the Phase 1 API boundary.
- Reused list-oriented backend operations for both single-record and batch calls so validation and dispatch stay on one path.
- Treated delete identity as a dedicated concern via `Scrypath.Identity`, with `search_document_id/1` as the only custom override hook.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- A transient `.git/index.lock` blocked one commit attempt. The lock was gone on inspection, and the retry succeeded without code changes.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The common Phase 2 write surface is now fixed in code and tests, so backend-specific Meilisearch work can build on a stable contract.
- Delete flows already enforce the phase threat-model requirement that identity stay independent from projection output.

## Self-Check: PASSED

- Verified summary target file exists: `.planning/phases/02-meilisearch-core-sync/02-01-SUMMARY.md`
- Verified task commits exist: `3fcfd58`, `71c8f63`, `9735cc3`, `8f67773`

---
*Phase: 02-meilisearch-core-sync*
*Completed: 2026-04-15*
