---
phase: 04-oban-and-observability
plan: 04-01
subsystem: api
tags: [elixir, oban, sync, payloads, tdd]
requires:
  - phase: 02-meilisearch-core-sync
    provides: common sync verbs, accepted/completed result metadata, explicit delete identity
provides:
  - shared sync-path oban option validation and readiness checks
  - accepted oban result metadata without widening the public sync API
  - JSON-safe batch payload builders for future upsert and delete workers
affects: [phase-04-oban-and-observability, phase-05-reindexing-and-operational-workflows, docs]
tech-stack:
  added: []
  patterns: [shared sync verbs across inline/manual/oban, explicit runtime oban config, JSON-safe batch worker args]
key-files:
  created:
    - lib/scrypath/oban/payload.ex
    - test/scrypath/oban/payload_test.exs
  modified:
    - lib/scrypath/options.ex
    - lib/scrypath/config.ex
    - lib/scrypath/sync.ex
    - test/scrypath/sync_test.exs
key-decisions:
  - "Kept oban on the existing Scrypath sync/delete verbs and surfaced queue acceptance through the established mode/status envelope."
  - "Defined worker args as pre-projected, string-keyed payload maps so future workers never need source-row reload logic."
patterns-established:
  - "Oban runtime behavior should be validated on the common sync path before any enqueue or backend dispatch."
  - "Persisted worker args should stringify module names, atom keys, and atom values while rejecting structs and unsupported terms."
requirements-completed: [SYNC-05]
duration: 4 min
completed: 2026-04-16
---

# Phase 4 Plan 04-01: Common Oban Sync Contract Summary

**Shared `Scrypath.*` verbs now validate explicit Oban runtime settings, return accepted queue metadata, and serialize batch payloads into JSON-safe worker args**

## Performance

- **Duration:** 4 min
- **Started:** 2026-04-16T01:46:00Z
- **Completed:** 2026-04-16T01:50:33Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added runtime Oban options for queue selection, instance selection, and retry attempts on the shared sync path.
- Centralized Oban readiness checks so `sync_mode: :oban` fails before backend dispatch and keeps the existing accepted result contract.
- Created JSON-safe upsert and delete payload builders that preserve caller batch boundaries and reject structs or unsupported terms.

## Task Commits

Each task was committed atomically:

1. **Task 1: Lock the common Oban sync option contract and fail-fast guard** - `40afe98` (`test`)
2. **Task 1: Lock the common Oban sync option contract and fail-fast guard** - `38b7abf` (`feat`)
3. **Task 2: Create JSON-safe Oban payload builders for upsert and delete batches** - `46b0ea9` (`test`)
4. **Task 2: Create JSON-safe Oban payload builders for upsert and delete batches** - `016178d` (`feat`)

## Files Created/Modified

- `lib/scrypath/options.ex` - Added explicit Oban runtime options and conditional validation for `sync_mode: :oban`.
- `lib/scrypath/config.ex` - Added a centralized Oban readiness guard plus queue and retry accessors.
- `lib/scrypath/sync.ex` - Kept Oban on the shared verb path and returned accepted metadata without backend dispatch.
- `lib/scrypath/oban/payload.ex` - Added batch-oriented payload builders for future upsert and delete workers.
- `test/scrypath/sync_test.exs` - Locked the shared-verb Oban contract, config failures, and accepted result metadata with TDD coverage.
- `test/scrypath/oban/payload_test.exs` - Locked JSON-safe worker args, preserved batch semantics, and nested-value rejection behavior.

## Decisions Made

- Kept `sync_mode: :oban` on `Scrypath.*` instead of introducing a second runtime API surface.
- Required explicit queue configuration for Oban mode so queue behavior stays local and reviewable at the call site.
- Serialized payloads eagerly into string-keyed maps so future workers can trust persisted args without re-projecting records.

## Deviations from Plan

None - plan executed exactly as written.

## TDD Gate Compliance

- RED gate commit present: `40afe98`
- GREEN gate commit present: `38b7abf`
- RED gate commit present: `46b0ea9`
- GREEN gate commit present: `016178d`
- No refactor commit was needed

## Issues Encountered

- The repo does not yet include the real Oban dependency, so the acceptance-path contract was exercised through the configured Oban instance option while preserving a clear failure when the default `Oban` module is unavailable.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 4 plan 04-02 can now plug real enqueueing and workers into a stable common sync contract without reopening the public API.
- Telemetry and operator documentation can build on the accepted/completed result envelope and the new JSON-safe worker arg format.

## Self-Check: PASSED

- Verified summary target file exists: `.planning/phases/04-oban-and-observability/04-01-SUMMARY.md`
- Verified task commits exist: `40afe98`, `38b7abf`, `46b0ea9`, `016178d`

---
*Phase: 04-oban-and-observability*
*Completed: 2026-04-16*
