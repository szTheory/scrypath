---
phase: 178-loader-routed-backfill-and-full-key-paging
plan: 03
subsystem: backfill
status: complete
requirements-completed: [PAGE-01, PAGE-02, LOAD-03]
tags: [backfill, reindex, keyset-paging, composite-primary-key, ecto, property-test]
requires:
  - 178-01 (real-DB harness: LoaderBackfillCases, SQLite sandbox repo, Postgres repo)
provides:
  - Full-key keyset paging in Scrypath.Backfill (pk_columns/1, keyset_after/2, run_batches/1 state map)
  - Composite last_primary_key keyword cursor (scalar kept for single-column keys)
  - D-02 caller :query stripping (order_by/limit/offset/select/preload)
  - Reindex target index primaryKey = Metadata.document_id/1 (D-17)
affects:
  - 178-04 (extends the run_batches/1 state map with removed/omitted totals; adds :removed to the result-key assertion)
  - 178-05 (docs for composite key ordering)
tech-stack:
  added: []
  patterns:
    - Ecto.Query.dynamic/2 keyset predicate (leading-column bound plus OR expansion), no fragments, no DISTINCT
    - Loop state carried in a map to stay inside credo max_arity
    - Shared case template split into several quote blocks (credo LongQuoteBlocks)
key-files:
  created: []
  modified:
    - lib/scrypath/backfill.ex
    - lib/scrypath/reindex.ex
    - test/support/loader_backfill_cases.ex
    - test/scrypath/backfill_test.exs
    - test/scrypath/reindex_test.exs
decisions:
  - "The internal paging cursor lives under the state key `keyset` (list of {col, value} pairs); the public batch field stays `last_primary_key` and no `:cursor` key is added (D-09)"
  - "Fan-out dedupe keeps the first occurrence per key tuple, so the last DB-ordered row (the cursor source) is unchanged"
  - "The not-nil guard is added only when the schema has no Ecto primary key, so single-column Ecto-PK SQL is unchanged"
  - "LoaderBackfillCases is split into harness/composite_paging_cases/query_scope_cases quote blocks to satisfy credo --strict"
metrics:
  duration: ~35m
  completed: 2026-10-25
actuals:
  tokens: 5400
  tasks: 3
  commits: 6
plan_head_before: 49ba78670ea2392eaa546756334b53f364554c97
plan_head_after: 1f5f8c48dff8dab6cb6badc64ff644589baea166
---

# Phase 178 Plan 03: Full-key keyset paging and reindex document-id primary key Summary

Backfill now pages on every primary-key column. It uses one portable `Ecto.Query.dynamic/2` predicate: a `>=` bound on the leading column plus an OR expansion over the rest. Composite schemas visit every row exactly once (the pinned `{1, 3}` row is no longer skipped) and report keyword cursors such as `[org_id: 1, seq: 2]`. Reindex now creates its target index keyed by `Metadata.document_id/1`.

## What changed

- **`lib/scrypath/backfill.ex`**
  - `pk_columns/1` replaces the old first-column `primary_key/1`. It returns `[document_id]` when the schema has no Ecto primary key.
  - `keyset_after/2`, `keyset_predicate/1` and `expand/1` build the paging predicate. For a single column it is exactly `field > ^v`, the same AST as before.
  - `run_batches/1` and `run_batch/2` carry their state in a map. The cursor comes from `List.last(rows)` in database order.
  - `public_cursor/2` returns a scalar for single-column keys and a keyword list for composite keys.
  - `base_query/3` now also excludes `:offset`, `:select` and `:preload`.
  - Rows are deduped with `Enum.uniq_by` on the key tuple.
  - The keyless fallback adds a `not is_nil` where. A nil cursor value raises `ArgumentError`.
- **`lib/scrypath/reindex.ex`**: `create_index` receives `Metadata.document_id(schema_module)`. The private `primary_key/1` is removed.
- **Shared real-DB cases** (SQLite and Postgres):
  - the pinned `{1,3}` regression, with an exact top-level result-key assertion
  - a StreamData property: keys from `integer(1..3) x integer(1..20)`, batch_size from `integer(1..12)`, `max_runs: 40`, each run in a `repo.transaction`/`rollback(:reset)` savepoint
  - a `binary_id` second key column
  - a caller query's where scope kept while offset/order_by/limit are ignored
  - fan-out cross-join dedupe
  - the keyless nil-id skip
  - single-column SQL shape (one `>`, no `>=`, no `OR`), captured from repo telemetry
  - an empty table, and a single row
- **`test/scrypath/backfill_test.exs`**: the `:query` override test now carries `offset`, `select` and `preload`. It asserts all three are stripped and the where scope is kept.
- **`test/scrypath/reindex_test.exs`**: asserts that a composite Membership reindex records `{:create_index, Membership, :id, _}`.

## Verification

- `mix test test/scrypath/loader_backfill_sqlite_test.exs test/scrypath/backfill_test.exs test/scrypath/reindex_test.exs test/scrypath/oban/worker_test.exs`: 1 property, 40 tests, 0 failures
- `MIX_TEST_PARTITION=3 SCRYPATH_POSTGRES_URL=postgres://postgres:postgres@127.0.0.1:5434 mix test --include postgres test/scrypath/loader_backfill_postgres_test.exs`: 1 property, 8 tests, 0 failures. This ran against a real Postgres 16 (compose container `scrypath-postgres-1`).
- Full core suite `mix test`: 5 properties, 750 tests, 0 failures (20 excluded)
- `mix format --check-formatted`, `mix credo --strict` (no issues), `mix compile --warnings-as-errors --force`: all pass
- Acceptance greps: `defp primary_key(` returns 0 in both backfill.ex and reindex.ex. `fragment(`/`distinct:` returns 0 in backfill.ex.

## TDD Gate Compliance

Each task has a RED `test(...)` commit, confirmed failing, before its GREEN `fix(...)` commit:
- Task 1: d246d370 (RED: documents 3 vs 4, `{1,3}` skipped) then 7c724270 (GREEN)
- Task 2: 9d1e4fd3 (RED: 4 failures for offset, fan-out, keyless and fake-repo stripping) then c8bf4194 (GREEN)
- Task 3: 120cd5c7 (RED: create_index received `:org_id`) then 1f5f8c48 (GREEN)

The Task 1 tracer gate passed. The automated verify was re-run end to end on SQLite and Postgres before expansion.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Credo `LongQuoteBlocks` on the shared case template**
- **Found during:** Task 2
- **Issue:** The new cases pushed the `__using__` quote past credo's quote-length limit, so `mix credo --strict` failed.
- **Fix:** Split the template into `harness/1`, `composite_paging_cases/0` and `query_scope_cases/0` quote blocks, composed in `__using__`. Added an `upserted_ids/0` helper to remove a repeated flat_map. Plan 04 should add its cases to one of these blocks, or to a new block.
- **Files modified:** test/support/loader_backfill_cases.ex
- **Commit:** c8bf4194

**2. [Rule 3 - Blocking] `require Ecto.Query` in the template**
- **Found during:** Task 2
- **Issue:** `Ecto.Query.from/2` inside the quoted tests needs the macro required in the caller module.
- **Fix:** Added `require Ecto.Query` to the harness quote.
- **Commit:** 9d1e4fd3

### Minor shape choices
- In `reindex.ex` the document id is bound to a local `document_id` before the `with`, so the `create_index(schema_module, document_id, workflow_config)` call stays on one line. `Scrypath.Schema.Metadata` is now aliased.
- The offset case also passes `order_by: [desc: ...]` and `limit: 1` on the caller query. This shows that all caller paging clauses are ignored.

## Known Stubs

None.

## Threat Flags

None. The change adds no new endpoints or trust boundaries. Cursor values are only pinned `^` params against schema-typed fields (T-178-06). Nil keys are guarded (T-178-07). The reindex primaryKey is fixed (T-178-08).

## Self-Check: PASSED

- FOUND: lib/scrypath/backfill.ex, lib/scrypath/reindex.ex, test/support/loader_backfill_cases.ex, test/scrypath/backfill_test.exs, test/scrypath/reindex_test.exs
- FOUND commits: d246d370, 7c724270, 9d1e4fd3, c8bf4194, 120cd5c7, 1f5f8c48
