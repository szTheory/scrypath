---
phase: 179-bounded-id-lists-and-related-sync-parity
plan: 02
subsystem: sync
status: complete
requirements-completed: [PAGE-03]
tags: [chunking, backfill, reindex, page-03]
requires: [179-01]
provides:
  - chunked Scrypath.Backfill.write/5 (at most 1000 documents or ids per backend call, halt on first failed chunk)
  - tasks list on every Scrypath.backfill/2 batch_results entry
  - reindex waits on every chunk task of every batch before cutover
  - Scrypath.backfill/2 docs separating :batch_size paging from write chunks
affects: [179-03, 179-04, 179-05]
tech-stack:
  added: []
  patterns:
    - "Enum.chunk_every(list, Chunks.max_ids()) |> Chunks.reduce_ok for order-preserving backfill writes"
key-files:
  created: []
  modified:
    - lib/scrypath/backfill.ex
    - lib/scrypath/reindex.ex
    - lib/scrypath.ex
    - test/scrypath/backfill_test.exs
    - test/scrypath/reindex_test.exs
    - test/support/loader_backfill_cases.ex
decisions:
  - "Backfill write chunks keep the page's primary-key order: Enum.chunk_every(Chunks.max_ids()) instead of Chunks.by_id/ids, whose string-form sort would reorder a keyset page (rows are already deduped by key)"
  - "Reindex replaces a waited batch's task with the last waited chunk task and tasks with the waited list; batches with no or empty tasks keep the single-task wait"
metrics:
  duration: ~7m
  completed: 2026-10-25
estimate:
  tokens: 40000
  tasks: 2
actuals:
  tokens: 4000
  tasks: 2
  commits: 3
plan_head_before: cb3a241f37a5b49c7897c8a27d1779601b88456d
plan_head_after: 7ed50c92ff1423c27c9b75fb70cc6a9460079465
---

# Phase 179 Plan 02: Chunked backfill writes and every-chunk reindex wait Summary

`Scrypath.backfill/2` now writes each page in chunks of at most 1000 documents (and at most 1000 ids for removals) and stops at the first chunk that fails. Each `batch_results` entry now has a `tasks:` list of its chunk tasks. `Scrypath.reindex/2` waits on every one of those tasks before cutover, so a failed earlier chunk can no longer let an incomplete index go live.

## What was built

- **`Scrypath.Backfill.write/5`**:
  - Skipped writes return `{:ok, []}`.
  - Upserts and deletes are split with `Enum.chunk_every(Chunks.max_ids())` and run through `Chunks.reduce_ok/2`. Each chunk is one backend call followed by `normalize/4`.
  - `run_batch/2`'s `with` already stops at the first error, and that now covers a failed chunk. Later chunks and later pages are not sent.
- **Batch results**:
  - `tasks:` holds every upsert chunk task in order. It is always a list, `[]` when nothing was upserted, and it is never dropped.
  - `task:` and `index:` come from the last upsert chunk, and `delete_task:` from the last delete chunk.
  - The existing `maybe_drop_nil` behavior for `:task` and `:delete_task` is unchanged.
- **`Scrypath.Reindex`**: the new `maybe_wait_for_batch_tasks/2` waits each entry in a non-empty `tasks` list in order with `maybe_wait_for_result_task/2` and stops at the first error. It then sets `task` to the last waited task and `tasks` to the waited list. A batch with no `tasks`, or an empty list, falls back to the single-task wait. `delete_task` is still not waited, as before.
- **Docs** (`Scrypath.backfill/2`):
  - A new paragraph says `:batch_size` sets the page size only, that each page is written in chunks of at most 1000, that `batch_size: 5000` therefore means five upsert calls per page, and that the first failed chunk stops the backfill.
  - The Result list has a new `tasks` bullet.
  - `## Batch tasks` now says a caller must follow every `tasks` entry, and that `reindex/2` does this before cutover.

## Tasks

| Task | Name | Commits |
| ---- | ---- | ------- |
| 1 | Tracer: a 2,500-row page writes three bounded upserts and reports three batch tasks | 760851db |
| 2 | Reindex waits on every chunk task; backfill docs explain paging vs write chunks | 8f523bdb (RED), 7ed50c92 (GREEN) |

Tracer gate (Task 1): before starting Task 2, I re-ran the `<verify>` checks. The SQLite run passed 26 tests, and the Postgres run passed 14 tests across 6 seeds.

## TDD Gate Compliance

- Task 2 RED commit `8f523bdb`: both new reindex tests failed. The three-chunk test never received `{:task_wait, 31}`. The failed-first-chunk test got `{:ok, _}`: reindex cut over after waiting only on task 33.
- GREEN commit `7ed50c92`: reindex, backfill and loader-backfill SQLite tests pass (46 tests, 0 failures).

## Verification

- `mix test test/scrypath/reindex_test.exs test/scrypath/backfill_test.exs test/scrypath/loader_backfill_sqlite_test.exs`: 46 tests, 0 failures.
- `SCRYPATH_POSTGRES_URL=postgres://postgres:postgres@127.0.0.1:5434 MIX_TEST_PARTITION=_a179_02 mix test --include postgres test/scrypath/loader_backfill_postgres_test.exs`: 14 tests, 0 failures, on seeds 238431, 586253, 869133, 1, 2 and 3. I used the scrypath Postgres container that was already running on 5434. My own `docker compose up` could not bind the port. The unique partition kept my run's database separate from other agents' databases.
- `mix compile --warnings-as-errors`, `mix format --check-formatted`, `mix credo --strict` (no issues) and `mix docs --warnings-as-errors` all exit 0.
- Full `mix test`: 806 tests, 1 failure. That failure is the expected `Scrypath.NoHumanGatesContractTest`, which flags the 179-04/179-05 PLAN `verification: backstop` until those plans have SUMMARYs.
- Acceptance greps:
  - `Chunks\.` in backfill.ex: 6
  - `tasks:` in backfill.ex: 1
  - `tasks:|:tasks|\.tasks` in reindex.ex: 2
  - `batch_size: 5000` in scrypath.ex: 1
- The halt test sees exactly two upsert calls and one page query.
- No existing exact-map batch assertion needed `tasks:` added; all existing assertions are partial pattern matches.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug avoidance] Backfill chunks keep page order instead of using Chunks.by_id / Chunks.ids**
- **Found during:** Task 1
- **Issue:** `Chunks.by_id/2` and `Chunks.ids/1` sort by the string form of the id. That would reorder a keyset page: ids `[9, 10]` would be sent as `[10, 9]`. Order-sensitive existing cases would also break on Postgres, where sequence ids grow across tests.
- **Fix:** Pages are split with `Enum.chunk_every(Chunks.max_ids())` plus `Chunks.reduce_ok/2`. The rows are already deduped by key, and the same 1000 bound applies.
- **Files modified:** lib/scrypath/backfill.ex
- **Commit:** 760851db

**2. [Rule 1 - Flaky test from 179-01's D-03] search_records shared case pinned loader id order**
- **Found during:** Task 1 Postgres verify
- **Issue:** `Loader.load/3` (changed in plan 01) sorts ids by string form. On Postgres, a batch `[9, 11]` reached `search_records/2` as `[11, 9]`. The shared case expected exact order, so it failed depending on the seed (3 of 6 seeds).
- **Fix:** The case now compares the received batch ids, upserted ids and deleted ids sorted, with a D-03 comment. This matches 179-01's worker_test fix.
- **Files modified:** test/support/loader_backfill_cases.ex
- **Commit:** 760851db

## Known Stubs

None.

## Threat Flags

None. T-179-04 is mitigated by the 1000-per-call write bound. T-179-05 is mitigated by the every-task wait, and a test asserts no swap happens after a failed chunk.

## Self-Check: PASSED

- lib/scrypath/backfill.ex, lib/scrypath/reindex.ex, lib/scrypath.ex, test/scrypath/backfill_test.exs, test/scrypath/reindex_test.exs and test/support/loader_backfill_cases.ex all exist and are modified.
- Commits 760851db, 8f523bdb and 7ed50c92 are ancestors of HEAD.
