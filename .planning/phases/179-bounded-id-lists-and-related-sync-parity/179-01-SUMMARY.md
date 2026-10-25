---
phase: 179-bounded-id-lists-and-related-sync-parity
plan: 01
subsystem: sync
status: complete
tags: [chunking, sync, loader, page-03, fan-01]
requires: []
provides:
  - Scrypath.Chunks (internal, @max_ids 1000): max_ids/0, ids/1, by_id/2, reduce_ok/2, each_ok/2
  - Operations.Result.tasks field and public tasks list on sync results
  - public conflict? on every public job map
  - chunked inline/manual upsert and delete with per-chunk inline wait and halt
  - chunked Loader.load/3 with owner-only :preload tolerance
affects: [179-02, 179-03, 179-04, 179-05]
tech-stack:
  added: []
  patterns:
    - "Chunks.by_id / Chunks.ids then Chunks.reduce_ok per backend or DB call"
    - "single chunk keeps today's result map plus tasks; 2+ chunks build the Result fresh"
key-files:
  created:
    - lib/scrypath/chunks.ex
    - test/scrypath/chunks_test.exs
  modified:
    - lib/scrypath/operations/result.ex
    - lib/scrypath/sync.ex
    - lib/scrypath/loader.ex
    - test/scrypath/sync_test.exs
    - test/scrypath/loader_test.exs
    - test/scrypath/oban/worker_test.exs
decisions:
  - "Empty-trigger sync_related returns noop_result for every sync mode (guard sits before the mode case, as the plan specified), so oban with [] no longer enqueues"
  - "Loader.preload_for/1 only swallows FunctionClauseError raised by the schema's own __scrypath__/1; any other FunctionClauseError is re-raised"
  - "Multi-chunk combined metadata keeps only :index from the last chunk; a chunk result that is not a Result (fake backend id list) counts as a chunk with no task, using the chunk's ids and length"
metrics:
  duration: ~35m
  completed: 2026-10-25
estimate:
  tokens: 55000
  tasks: 3
actuals:
  tokens: 8000
  tasks: 3
  commits: 5
plan_head_before: 1d3399c15ea7bed40a259e9e32eaa2163b7245c9
plan_head_after: 64fc7a143bdb3ebb7b6575304641b2d6b0e076f1
---

# Phase 179 Plan 01: Bounded id lists for inline/manual sync and the loader Summary

Inline and manual sync and `Loader.load/3` now send at most 1000 ids per backend or database call, using one internal `Scrypath.Chunks` helper. Each call returns one combined result with a new `tasks:` list. A failed chunk, or a failed inline chunk task, stops the later chunks and returns the bare error.

## What was built

- **`Scrypath.Chunks`** (`@moduledoc false`, `@max_ids 1000`, no Oban references, no public option):
  - `ids/1` dedupes by raw value and sorts by `{to_string(id), id}`, so `1` and `"1"` stay distinct.
  - `by_id/2` keeps the last occurrence of a duplicate id.
  - `reduce_ok/2` and `each_ok/2` run chunks in order and halt at the first error.
- **`Result.tasks`** (default `[]`). `Result.to_public_sync/1` now renders it.
- **`Sync`**:
  - Inline/manual `dispatch_upsert` and `dispatch_delete` run `backend call |> normalize |> maybe_wait_for_task` once per chunk. Inline waits on each chunk's Meilisearch task before it sends the next chunk.
  - `combine_chunks/2`:
    - One chunk returns today's exact map plus a one-element `tasks` (or `tasks: []` when there is no task).
    - Two or more chunks build a fresh `Result`: concatenated ids, summed count, `task:` set to the last chunk's task, every chunk task in `tasks:`, and no `backend_result`.
  - `public_result/1` adds `tasks:` through the new `public_task/1`.
  - `public_job/1` carries `conflict?:` (default `false`).
  - `sync_related` with an empty trigger list is a noop and never calls the resolver.
  - No new telemetry span: the `Telemetry.span` count stays at 3, and one `[:scrypath, :sync, :upsert, :stop]` event fires with `document_count: 2500`.
- **`Loader`**:
  - `load/3` fetches once per `Chunks.ids/1` chunk, halts on the first `{:error, _}`, and computes `missing_ids` across the full caller input.
  - `preload_for/1` returns `[]` for hand-written owner-only schemas that have no `:preload` clause.
  - The moduledoc and `load/3` doc say ids are deduped, loaded in batches of at most 1000, and come with no ordering contract.

## Tasks

| Task | Name | Commits |
| ---- | ---- | ------- |
| 1 | Tracer: 2,500 inline records → 3 bounded upserts, one combined result | d1218428 |
| 2 | Chunked deletes, halt, per-chunk wait, manual no-wait, conflict?, empty fan-out noop | a4dcdcd8 (RED), bc5b7795 (GREEN) |
| 3 | Chunked Loader.load/3 and owner-only preload tolerance | bbb03907 (RED), 64fc7a14 (GREEN) |

Tracer gate (Task 1): I re-ran the tracer's `<verify>` before I started the expansion tasks, and it passed with 32 tests and 0 failures.

## TDD Gate Compliance

- Task 2: the RED commit `a4dcdcd8` had 3 failing tests: chunked delete, `conflict?`, and empty `sync_related`. The halt, per-chunk wait, manual no-wait and single-span tests already passed at RED because Task 1 (the tracer) puts the wait and halt inside the per-chunk pipeline. They pin that behavior. GREEN commit: `bc5b7795`.
- Task 3: the RED commit `bbb03907` had 4 failing loader tests. GREEN commit: `64fc7a14`.

## Verification

- `mix test` (full suite): 800 tests and 1 failure. The failure comes from planning artifacts and is explained under Deferred Issues.
- These per-plan verify commands all pass:
  - `mix test test/scrypath/chunks_test.exs test/scrypath/sync_test.exs`
  - `mix test test/scrypath/sync/related_test.exs test/scrypath/telemetry_test.exs`
  - `mix test test/scrypath/loader_test.exs test/scrypath/loader_backfill_sqlite_test.exs test/scrypath/oban/worker_test.exs`
- These gates exit 0: `mix compile --warnings-as-errors`, `mix format --check-formatted`, `mix credo --strict` and `mix verify.no_optional_deps`.
- Acceptance greps:

  | Grep | Count |
  | ---- | ----- |
  | `Oban` in chunks.ex | 0 |
  | `batch_size` in chunks.ex | 0 |
  | `tasks: []` in result.ex | 1 |
  | `Chunks.` in sync.ex | 4 |
  | `conflict?` in sync.ex | 1 |
  | `Telemetry.span` in sync.ex | 3 (unchanged) |
  | `Chunks.ids` in loader.ex | 1 |
  | `FunctionClauseError` in loader.ex | 1 |
  | `Metadata.preload(schema_module)` in loader.ex | 1 |

- The single-chunk assertions in sync_test.exs (lines 252, 271 and 344-377) pass unedited. No existing sync test compared a whole result map exactly, so none needed `tasks:` added.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Test pinned an ordering contract that D-03 removes] worker_test search_records order**
- **Found during:** Task 3
- **Issue:** `test/scrypath/oban/worker_test.exs` asserted that `search_records/2` receives `[7, 404]` in caller order. Chunking sorts ids by string form, so the loader now sends `[404, 7]`.
- **Fix:** The assertion now compares `Enum.sort(loaded_ids) == [7, 404]`, with a comment pointing to D-03 (no ordering contract).
- **Files modified:** test/scrypath/oban/worker_test.exs
- **Commit:** 64fc7a14

**2. [Scope note] Empty-trigger guard applies to all sync modes**
- The plan put the guard before the mode `case`, so `sync_related(schema, [], sync_mode: :oban)` is now a noop too. Before this change it enqueued a related job with an empty id list. No existing test depended on the old behavior.

## Deferred Issues

- `Scrypath.NoHumanGatesContractTest` fails on `179-04-PLAN.md` and `179-05-PLAN.md`. Both contain `verification: backstop` and have no SUMMARY yet. This planning-artifact check is outside this plan's scope. The 179-01 entry clears now that this SUMMARY exists, and the other two clear when those plans complete or are reworded.

## Known Stubs

None.

## Threat Flags

None. The changes stay inside the threat register: T-179-01 (bounded calls), T-179-02 (fresh multi-chunk result, bare halt error) and T-179-03 (errors carry no id lists).

## Self-Check: PASSED

- FOUND: lib/scrypath/chunks.ex, test/scrypath/chunks_test.exs, lib/scrypath/operations/result.ex, lib/scrypath/sync.ex, lib/scrypath/loader.ex
- FOUND commits: d1218428, a4dcdcd8, bc5b7795, bbb03907, 64fc7a14
