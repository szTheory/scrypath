---
phase: 178-loader-routed-backfill-and-full-key-paging
plan: 04
subsystem: backfill
status: complete
tags: [backfill, reindex, loader, search_records, preload, delete-semantics]
requires:
  - 178-03 (state-map backfill loop, full-key keyset paging, split LoaderBackfillCases)
provides:
  - Scrypath.Loader.prepare_records/3 (@doc false, records-in loader routing)
  - Loader-routed backfill with omitted-id deletes, removed:/delete_task: reporting
  - Internal :_scrypath_fresh_target backfill option and reindex omitted:
  - Real-DB parity and search_records/2 proofs on SQLite and Postgres
affects:
  - 178-05 (guides must document the live-index delete behavior change, removed:/delete_task:/omitted:, and that backfill does not wait on either task)
tech-stack:
  added: []
  patterns:
    - Upsert-then-delete per batch with empty-list skips (mirrors UpsertWorker without its ack wait)
    - Separate delete_task: key so task: keeps meaning the upsert task
    - to_string id matching against the batch id set to drop out-of-batch loader records
key-files:
  created:
    - test/scrypath/loader_test.exs
  modified:
    - lib/scrypath/loader.ex
    - lib/scrypath/backfill.ex
    - lib/scrypath/options.ex
    - lib/scrypath/reindex.ex
    - test/scrypath/backfill_test.exs
    - test/scrypath/reindex_test.exs
    - test/scrypath/options_test.exs
    - test/support/loader_backfill_cases.ex
    - test/support/loader_backfill_fixtures.ex
decisions:
  - "Backfill writes go through one private write/5 (:upsert | :delete) that skips empty lists and normalizes the backend result; the batch result is built once from both results"
  - "Batch index now falls back to the resolved index when the backend result metadata has a nil :index (previously Map.get/3 default only applied to a missing key)"
  - "Managed reindex takes no :query, so the reindex search_records/2 proof runs over the whole table and asserts omitted == all unpublished rows"
metrics:
  duration: ~30m
  completed: 2026-10-25
actuals:
  tokens: 8500
  tasks: 3
  commits: 5
plan_head_before: 3fa52c1a46c3c0d2fb0db89cb58c38f86e7e3d1d
plan_head_after: 116299e19c3311da0c9149870f0f80a82b348957
---

# Phase 178 Plan 04: Loader-routed backfill and fresh-target reindex Summary

Backfill now builds documents through `Scrypath.Loader`, the loader Oban sync uses. `preload:` is applied with `force: true`. For a schema that defines `search_records/2`, that function decides which rows in each batch are indexed. Records it returns for ids outside the batch are dropped. On a live index, ids it omits are deleted after the batch upsert. A managed reindex into a fresh target counts omissions instead of deleting them and reports them as `omitted:`.

## What changed

- **`lib/scrypath/loader.ex`**
  - New `@doc false` `prepare_records/3`, which takes records and returns `{:ok, records, omitted_ids}`. An empty list returns `{:ok, [], []}`.
  - Custom-loader schemas go through `load/3` with the batch's document ids. The result is then filtered to the batch id set by `to_string` match (T-178-09).
  - Every other schema keeps its rows and gets its declared `preload:`. There is no `check_loadable` call, so schemas that only define `search_document_id/1` still backfill.
  - `preload_records/3` now calls `repo.preload(..., force: true)`. The `nil`/`[]` and empty-records short-circuits are kept.
  - `load/3` is unchanged.
- **`lib/scrypath/backfill.ex`**
  - Each deduped batch goes through `Loader.prepare_records/3`, then `Projection.document/2`.
  - The upsert is sent only when there are documents. The new private `delete_documents/5` (Meilisearch dispatch or `backend.delete_documents/3`) runs after it, only when there are omitted ids.
  - Each batch result carries `removed:`. It carries `delete_task:` only when a delete ran and the backend returned a task. `task:` is still the upsert task and is absent when nothing was upserted.
  - The top-level result carries `removed:`, plus `omitted:` only under the fresh-target flag.
  - The cursor still comes from the scoped rows.
  - No telemetry was added. The non-comment telemetry grep count is 0.
- **`lib/scrypath/options.ex`**: new `_scrypath_fresh_target: [type: :boolean, default: false, doc: false]` backfill option.
- **`lib/scrypath/reindex.ex`**: the backfill config now gets `Keyword.put(:_scrypath_fresh_target, true)`. The result gains `omitted: Map.get(backfill_result, :omitted, 0)`. Reindex results have no `removed:` key.
- **Tests**
  - `loader_test.exs` (new): covers the no-preload pass-through, the force preload, custom-loader filtering (an out-of-batch extra, a string id for an integer row, omitted ids in batch order), the empty list, and a `search_document_id`-only schema.
  - `backfill_test.exs`: `RecordingBackend.delete_documents/3` now records the call and returns a `documentDeletion` task with uid id+900. New cases:
    - the delete order and per-batch delete tasks
    - an all-omitted batch, which has no `:task`, has a `:delete_task`, and still pages
    - a batch with no omissions, which has no `:delete_task`
    - the fresh-target flag
  - `reindex_test.exs`: asserts the flag is passed and that `omitted` is 0 or 3. `options_test.exs` covers flag validation.
  - Real-DB cases (both adapters) are in two new quote blocks, `preload_parity_cases/0` and `search_records_cases/0`:
    - Product documents built by backfill, inline sync from caller-preloaded records, `Loader.load` + `Projection`, and reindex are equal.
    - Article: `search_records/2` is called once per eu batch with exactly that batch's ids. No us or pinned id is upserted. Deleted ids are the unpublished eu ids.
    - Reindex makes no delete and reports `omitted == unpublished count`.
    - An all-omitted batch_size-1 run has strictly increasing cursors.
  - New fixture `StubMeilisearch` (create_index, apply_settings, swap_indexes). None of its results carries a task, so reindex never polls a server.
  - The sorted result-key assertion now includes `:removed`.

## Verification

- `mix test test/scrypath/loader_test.exs test/scrypath/backfill_test.exs test/scrypath/reindex_test.exs test/scrypath/oban/worker_test.exs test/scrypath/options_test.exs test/scrypath/loader_backfill_sqlite_test.exs`: green
- `MIX_TEST_PARTITION=4 SCRYPATH_POSTGRES_URL=postgres://postgres:postgres@127.0.0.1:5434 mix test --include postgres test/scrypath/loader_backfill_postgres_test.exs`: 1 property, 12 tests, 0 failures, no `Req.` errors. This ran against the real compose Postgres (`scrypath-postgres-1`).
- Full `mix test`: 5 properties, 767 tests, 0 failures (24 excluded)
- `mix format --check-formatted`, `mix credo --strict` (no issues), `MIX_ENV=test mix compile --warnings-as-errors --force`, `mix docs --warnings-as-errors`: all pass
- Mutation check: returning unfiltered loader records from `prepare_records/3` makes 2 real-DB cases fail (the pinned out-of-batch article gets indexed). The code was restored afterwards.

## TDD Gate Compliance

- Task 1 (tracer): RED 49780675 (8 failures: `prepare_records/3` undefined, no deletes, no `removed:`), then GREEN 7237114e. The tracer gate passed: the verify command was re-run end to end before expansion.
- Task 2: RED 277e766e (3 failures), then GREEN ca241577.
- Task 3: 116299e1. These are proof tests over behavior Tasks 1 and 2 had already implemented, so there is no separate failing commit. Instead, the mutation check above shows the cases detect a regression of the scope filter.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Reindex does not accept `:query`**
- **Found during:** Task 3
- **Issue:** The plan's "Article reindex over the same data" assumed the eu `:query` scope could be passed. `Options.validate_reindex_options!` rejects `:query`.
- **Fix:** The reindex proof now runs over the whole table, with no pinned rows. It asserts no delete, `omitted ==` all unpublished rows, and only the published id upserted.
- **Commit:** 116299e1

**2. [Rule 3 - Blocking] Compile-time struct use across test/support modules**
- **Found during:** Task 3
- **Issue:** `%LoaderBackfill.Article{}` in `loader_backfill_cases.ex` failed to compile, because the fixture module is compiled in parallel.
- **Fix:** `insert_articles!/2` builds the struct with `struct/2` at runtime.
- **Commit:** 116299e1

**3. Test fixture task index key**
- The delete task in `backfill_test.exs` RecordingBackend uses `index_uid:`, not `indexUid:`. `Operations.task_from_backend/1` only reads a string `"indexUid"` or an atom `:index_uid`, so the `index_uid` assertion on `delete_task` would otherwise have been nil. The existing upsert fixture is left unchanged.

## Known Stubs

None.

## Threat Flags

None. T-178-09 (filter to batch ids), T-178-10 (delete only the visited batch's omitted ids, on the resolved index, after the upsert; skip empty lists; never delete under fresh target; surface `delete_task:`) and T-178-11 (`:query` remains the row selector, proved on a real DB) are mitigated and tested.

## Self-Check: PASSED

- FOUND: lib/scrypath/loader.ex, lib/scrypath/backfill.ex, lib/scrypath/options.ex, lib/scrypath/reindex.ex, test/scrypath/loader_test.exs, test/support/loader_backfill_cases.ex, test/support/loader_backfill_fixtures.ex
- FOUND commits: 49780675, 7237114e, 277e766e, ca241577, 116299e1
