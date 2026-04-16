---
phase: 05-reindexing-and-operational-workflows
plan: 01
subsystem: api
tags: [elixir, ecto, meilisearch, options, schema-metadata, reindexing]
requires:
  - phase: 01-schema-contract-and-reflection
    provides: schema metadata reflection and Scrypath top-level helpers
  - phase: 02-meilisearch-core-sync
    provides: backend runtime option validation and Meilisearch write-path contracts
provides:
  - schema-declared Meilisearch settings metadata with runtime reflection
  - dedicated backfill and reindex option validators for Phase 5 workflows
  - bulk workflow rejection of unsupported Oban execution mode
affects: [05-02, 05-03, 05-04, reindexing, backfill, operator-workflows]
tech-stack:
  added: []
  patterns: [metadata-only schema settings contract, dedicated bulk workflow option validation]
key-files:
  created: [.planning/phases/05-reindexing-and-operational-workflows/05-01-SUMMARY.md]
  modified:
    - lib/scrypath/options.ex
    - lib/scrypath/schema.ex
    - lib/scrypath.ex
    - test/scrypath/schema_test.exs
    - test/scrypath/options_test.exs
    - test/support/searchable_post.ex
key-decisions:
  - "Kept schema settings metadata-only and exposed it through Scrypath reflection helpers instead of generating schema-local runtime APIs."
  - "Added dedicated backfill and reindex validators instead of overloading general runtime option validation."
  - "Defaulted bulk workflow sync_mode to :manual and rejected :oban so Phase 5 orchestration stays explicit."
patterns-established:
  - "Schema settings declarations must normalize at compile time and persist through __scrypath__/1 metadata."
  - "Bulk operational workflows get their own option schemas with concrete required modules and early rejection of impossible values."
requirements-completed: [OPER-03]
duration: 16min
completed: 2026-04-16
---

# Phase 05 Plan 01: Settings Contract Summary

**Schema-declared Meilisearch settings reflection and explicit backfill/reindex option validation for Phase 5 workflows**

## Performance

- **Duration:** 16 min
- **Started:** 2026-04-16T12:36:13Z
- **Completed:** 2026-04-16T12:52:13Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added `settings:` to the schema contract, persisted it in `__scrypath__(:config)`, and exposed it via `__scrypath__(:settings)` plus `Scrypath.schema_settings/1`.
- Added dedicated `validate_backfill_options!/1` and `validate_reindex_options!/1` contracts with required `backend`, `repo`, and positive `batch_size`.
- Rejected `sync_mode: :oban` for bulk workflows before any reindex or backfill execution can begin.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add schema-declared Meilisearch settings metadata per OPER-03** - `6df4b99` (feat)
2. **Task 2: Validate backfill and reindex runtime options per OPER-03** - `4d49d8f` (feat)

## Files Created/Modified

- `lib/scrypath/options.ex` - schema settings validation and dedicated bulk workflow validators
- `lib/scrypath/schema.ex` - persisted `:settings` metadata on searchable schemas
- `lib/scrypath.ex` - top-level schema settings reflection helper
- `test/scrypath/schema_test.exs` - schema settings storage, reflection, and compile-time validation coverage
- `test/scrypath/options_test.exs` - backfill and reindex runtime contract coverage
- `test/support/searchable_post.ex` - configured schema fixture for settings reflection tests

## Decisions Made

- Kept Phase 5 settings support metadata-only. Settings are declared and reflected, but not auto-applied by schema macros or boot-time hooks.
- Used dedicated bulk validators instead of extending `validate_runtime_options!/1`, which keeps sync-path configuration separate from operator workflow configuration.
- Allowed optional settings overrides on backfill and reindex validators so later orchestration can apply target-index settings intentionally.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Normalize literal settings maps from macro AST during schema validation**
- **Found during:** Task 1 (Add schema-declared Meilisearch settings metadata per OPER-03)
- **Issue:** `use Scrypath, settings: %{...}` reaches `Scrypath.Options` as quoted syntax during macro expansion, so a strict runtime `is_map/1` check rejected valid literal declarations at compile time.
- **Fix:** Updated `validate_settings/1` to accept quoted literals, evaluate them safely, and still reject non-map values.
- **Files modified:** `lib/scrypath/options.ex`
- **Verification:** `mix test test/scrypath/schema_test.exs`
- **Committed in:** `6df4b99`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Required for the planned schema settings feature to compile correctly. No scope expansion.

## Issues Encountered

- Macro-time schema option validation needed quoted literal normalization for settings maps. Resolved inline during Task 1.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 5 now has an explicit settings contract and validated bulk runtime semantics for Meilisearch orchestration.
- The next plans can build index creation, settings application, backfill, and cutover logic on top of stable reflected metadata and validated workflow options.

## Self-Check: PASSED

- Summary file created at `.planning/phases/05-reindexing-and-operational-workflows/05-01-SUMMARY.md`
- Task commits present: `6df4b99`, `4d49d8f`

---
*Phase: 05-reindexing-and-operational-workflows*
*Completed: 2026-04-16*
