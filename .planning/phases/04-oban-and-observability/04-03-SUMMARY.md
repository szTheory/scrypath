---
phase: 04-oban-and-observability
plan: 04-03
subsystem: observability
tags: [elixir, telemetry, oban, meilisearch, docs, tdd]
requires:
  - phase: 04-oban-and-observability
    provides: durable oban enqueueing, worker execution, shared sync result envelope
provides:
  - stable common-path telemetry spans for sync, search, and hydration workflows
  - backend-specific meilisearch request and inline task-wait spans
  - explicit sync mode contract and async lifecycle docs for operators
affects: [phase-04-oban-and-observability, docs, operations]
tech-stack:
  added: []
  patterns: [shared telemetry span helper, layered common-vs-backend event prefixes, explicit async lifecycle documentation]
key-files:
  created:
    - lib/scrypath/telemetry.ex
    - test/scrypath/telemetry_test.exs
  modified:
    - lib/scrypath/sync.ex
    - lib/scrypath/search.ex
    - lib/scrypath/hydration.ex
    - lib/scrypath/meilisearch/client.ex
    - lib/scrypath/meilisearch/tasks.ex
    - README.md
    - ARCHITECTURE.md
key-decisions:
  - "Kept public Scrypath telemetry low-cardinality around schema, backend, index, sync mode, and workflow counts."
  - "Put Meilisearch request and task-wait detail on explicit backend prefixes so task uid and poll counts never leak onto the common path."
  - "Documented `sync_mode: :oban` as durable enqueue acceptance only, with one shared async lifecycle for operators."
patterns-established:
  - "Use `Scrypath.Telemetry.span/3` to define stable workflow spans and merge stop metadata from result envelopes."
  - "Keep backend-specific telemetry in `Scrypath.Meilisearch.*` modules instead of widening the shared runtime contract."
requirements-completed: [OPER-04, SYNC-05]
duration: 4 min
completed: 2026-04-16
---

# Phase 4 Plan 04-03: Observability and Operator Contract Summary

**Shared workflow spans, Meilisearch-specific request visibility, and blunt async docs now make Scrypath's sync and search behavior observable without blurring the common-path boundary**

## Performance

- **Duration:** 4 min
- **Completed:** 2026-04-16T02:06:55Z
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments

- Added a shared `Scrypath.Telemetry` helper and instrumented common sync, search, and hydration workflows with span-based events and low-cardinality metadata.
- Added Meilisearch-only spans for HTTP requests and inline task waiting so request status, task uid, and poll counts stay visible without polluting the public event surface.
- Updated the README and architecture docs with a sync-mode contract matrix, one shared async lifecycle, and explicit statements about retries, discarded jobs, stale deletes, drift, and Oban enqueue semantics.

## Task Commits

Each task was committed atomically:

1. **Task 1: Instrument common sync, search, and hydration workflows with stable spans** - `5996cf3` (`test`)
2. **Task 1: Instrument common sync, search, and hydration workflows with stable spans** - `1b17923` (`feat`)
3. **Task 2: Add Meilisearch-specific spans and document the async operator contract** - `c74f426` (`test`)
4. **Task 2: Add Meilisearch-specific spans and document the async operator contract** - `61fc32e` (`feat`)

## Files Created/Modified

- `lib/scrypath/telemetry.ex` - Added the shared span helper plus normalized common metadata extraction.
- `lib/scrypath/sync.ex` - Wrapped common upsert and delete workflows in public sync spans.
- `lib/scrypath/search.ex` - Added the common search span around backend execution and result decoration.
- `lib/scrypath/hydration.ex` - Added a separate hydration workflow span with hit, record, and missing counts.
- `lib/scrypath/meilisearch/client.ex` - Added backend-specific request spans with method, path, index, and status code metadata.
- `lib/scrypath/meilisearch/tasks.ex` - Added backend-specific task-wait spans with task uid, poll counts, and final status metadata.
- `test/scrypath/telemetry_test.exs` - Locked the common-path spans, backend-specific spans, and operator docs wording through focused TDD coverage.
- `README.md` - Added the sync mode matrix, async lifecycle, and explicit operator failure semantics.
- `ARCHITECTURE.md` - Documented the layered telemetry model and the shared async lifecycle contract.

## Decisions Made

- Common-path events expose only stable workflow metadata and counts so subscribers can depend on them without inheriting backend churn.
- Meilisearch request and wait detail lives on backend prefixes so task identifiers and polling behavior stay explicit and scoped.
- The operator-facing docs use one lifecycle across inline, manual, and Oban paths, and state plainly that successful Oban enqueueing does not imply search visibility.

## Deviations from Plan

None - plan executed exactly as written.

## TDD Gate Compliance

- RED gate commit present: `5996cf3`
- GREEN gate commit present: `1b17923`
- RED gate commit present: `c74f426`
- GREEN gate commit present: `61fc32e`
- No refactor commit was needed

## Known Stubs

None.

## Self-Check: PASSED

- Verified summary target file exists: `.planning/phases/04-oban-and-observability/04-03-SUMMARY.md`
- Verified task commits exist: `5996cf3`, `1b17923`, `c74f426`, `61fc32e`
