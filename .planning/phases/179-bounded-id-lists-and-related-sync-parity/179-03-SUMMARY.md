---
phase: 179-bounded-id-lists-and-related-sync-parity
plan: 03
subsystem: oban
status: complete
requirements-completed: [PAGE-03, FAN-02]
tags: [chunking, oban, uniqueness, page-03, fan-02]
requires: [179-01]
provides:
  - Scrypath.Oban.Enqueue.unique_opts/0 (shared unique policy, @doc false)
  - Scrypath.Oban.Enqueue.enqueue_chunks/3 and insert_chunks/2 (@doc false)
  - Scrypath.Operations.task_from_job/1 with conflict? in task metadata
  - Scrypath.TestSupport.ObanSQLiteRepo + ObanSQLiteMigration real-Oban test harness
  - Scrypath.TestSupport.ObanSQLite.TestOban facade (defined in enqueue_unique_test.exs)
affects: [179-05]
tech-stack:
  added: []
  patterns:
    - "one Oban job per Chunks.ids/1 chunk; 2+ chunks inserted one by one inside Oban.Repo.transaction/2, rollback on first error"
    - "fakes with no running Oban instance (Oban.config raises RuntimeError) insert sequentially via Chunks.reduce_ok/2"
key-files:
  created:
    - test/support/oban_sqlite_repo.ex
    - test/support/oban_sqlite_migration.ex
    - test/scrypath/oban/enqueue_unique_test.exs
  modified:
    - lib/scrypath/oban/enqueue.ex
    - lib/scrypath/operations.ex
    - test/scrypath/oban/enqueue_test.exs
decisions:
  - "An empty id list still enqueues one empty job (at_least_one_chunk/1), preserving pre-chunking behaviour for RecoveryAction.retry/2 payloads without ids"
  - "Combined enqueue metadata :index comes from the first changeset's args[\"index\"] (same value as before), merged with %{oban: %{queue, max_attempts, name}}"
  - "Real-Oban test uses a `use Oban, otp_app: :scrypath` facade module named Scrypath.TestSupport.ObanSQLite.TestOban, because Config.validate_oban_module!/1 requires oban: to be a loaded module"
metrics:
  duration: ~25m
  completed: 2026-10-25
estimate:
  tokens: 45000
  tasks: 3
actuals:
  tokens: 9000
  tasks: 3
  commits: 3
plan_head_before: cb3a241f37a5b49c7897c8a27d1779601b88456d
plan_head_after: 6e3e68708612cecd3b588b9950cce2fe0cf986ce
---

# Phase 179 Plan 03: Chunked, unique, transactional Oban enqueue Summary

`sync_records` and `delete_documents` under `sync_mode: :oban` now enqueue one job per chunk of at most 1000 sorted, deduped ids. When there are two or more chunks, the jobs go in one at a time inside one `Oban.Repo.transaction/2`, and the first failed insert rolls them all back. A duplicate pending batch collapses into the existing job, and the result reports it as `conflict?: true` with status `:accepted`. A real Oban engine (Lite on SQLite) proves both behaviours.

## What was built

- **`Scrypath.Oban.Enqueue`**
  - `unique_opts/0` returns `[period: :infinity, states: [:available, :scheduled, :retryable]]`. It has no `keys:` or `fields:` override and leaves out `:executing`. `job_changeset/3` uses it, so every upsert and delete job carries it. Plan 05 can reuse it for related jobs.
  - `enqueue_upsert/3` and `enqueue_delete/3` build one changeset per `Chunks.ids/1` chunk through the unchanged `upsert_job_changeset/3` and `delete_job_changeset/3`, then call `enqueue_chunks/3`.
  - `insert_chunks/2`:
    - One changeset uses today's `insert_job/2` and returns `{:ok, [job]}`.
    - Two or more changesets: if `Oban.config/1` resolves, the inserts run inside `Oban.Repo.transaction/2` with `Oban.Repo.rollback/2` on the first error. Otherwise (a fake module with no running instance) they run through plain `Chunks.reduce_ok/2`.
    - Bulk insert is never used.
  - `enqueue_chunks/3` builds one `%Result{}`:
    - `tasks:` has one queue-job task per job, and `task:` is the last one.
    - Ids are concatenated across jobs and `document_count` is their total.
    - It keeps `mode: :oban` and `status: :accepted`, and its metadata holds `%{index:, oban: %{queue:, max_attempts:, name:}}`.
- **`Scrypath.Operations.task_from_job/1`**: this was extracted from `result_from_enqueue/2` and adds `conflict?` to the task metadata. `Sync.public_job/1` from plan 01 already renders `conflict?` on `job:` and on each `tasks:` entry.
- **The `Scrypath.Oban` Multi helpers** (`enqueue_upsert/5`, `enqueue_delete/5`) still build one changeset (resolved OQ1).
- **Test harness**:
  - `ObanSQLiteRepo` is a dedicated SQLite sandbox repo (`pool_size: 2`, WAL, `scrypath-oban-*.db`).
  - `ObanSQLiteMigration` runs `Oban.Migrations.up/0` and only compiles when `Oban.Migrations` is loaded.

## Tasks

| Task | Name | Commit |
| ---- | ---- | ------ |
| 1 | Tracer: 2,500 ids under `:oban` produce 3 chunk jobs and one combined result | f6199238 |
| 2 | Dedicated Oban SQLite test harness | 408fba35 |
| 3 | Real-Oban proof of `conflict?` collapse and multi-chunk rollback | 6e3e6870 |

**Tracer gate (Task 1):** I re-ran the tracer's `<verify>` before the expansion tasks. It passed: 89 tests, 0 failures, together with `test/scrypath/operator`, which calls the same enqueue functions through `RecoveryAction.retry/2`.

## TDD Gate Compliance

- Task 3 (`tdd="true"`) is a test-only proof of behaviour built in the Task 1 tracer, so its tests passed on the first run. This is the same ordering note as plan 01's tracer. Two checks show the assertions are not vacuous:
  - The rollback test inserts a valid chunk before the invalid one, so a non-transactional insert would leave one job behind.
  - The collapse test sends ids in a different order (`[2, 1]` then `[1, 2]`).

## Verification

- `mix test test/scrypath/oban/enqueue_test.exs test/scrypath/oban_test.exs test/scrypath/sync_test.exs test/scrypath/sync test/scrypath/oban test/scrypath/operator`: 116 tests, 0 failures.
- `mix test test/scrypath/oban/enqueue_unique_test.exs`: 4 tests, 0 failures, stable across 3 repeat runs with no "database is locked" failure.
- `mix test test/scrypath/oban/enqueue_test.exs test/scrypath/loader_backfill_sqlite_test.exs`: 0 failures, with no warning about the new support modules.
- Full `mix test`: 809 tests, 1 failure. The failure is the known `Scrypath.NoHumanGatesContractTest`, which flags the 179-04 and 179-05 PLAN files until those plans finish. It is not in this plan's scope.
- These gates exit 0: `mix compile --warnings-as-errors`, `mix format --check-formatted`, `mix credo --strict` and `mix verify.no_optional_deps`.
- Acceptance greps:

  | Grep | Count |
  | ---- | ----- |
  | `def unique_opts` | 1 |
  | `insert_all` (non-comment) | 0 |
  | `Oban.Repo.transaction` | 1 |
  | `conflict?` in operations.ex | 2 |
  | `Chunks.ids` in enqueue.ex | 2 |
  | `pool_size: 1` in oban_sqlite_repo.ex | 0 |
  | `ObanSQLiteRepo` in lib/ | 0 |

- I did not change any existing assertions in enqueue_test.exs. None of them compared a whole result map exactly.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] The real-Oban instance needs a facade module**
- **Found during:** Task 3
- **Issue:** `Config.validate_oban_module!/1` requires `oban:` to be a loaded module. A bare `{Oban, name: Scrypath.TestSupport.ObanSQLite.TestOban}` name raised "configured Oban instance ... is not available".
- **Fix:** `enqueue_unique_test.exs` now defines `Scrypath.TestSupport.ObanSQLite.TestOban` with `use Oban, otp_app: :scrypath` and starts it as `{TestOban, repo:, engine: Oban.Engines.Lite, testing: :manual, notifier: Oban.Notifiers.PG, queues: false, plugins: false}`. Host apps are wired the same way. Because the facade exports `insert/1`, the real path goes through `insert_job/2`'s `insert/1` branch.
- **Files modified:** test/scrypath/oban/enqueue_unique_test.exs
- **Commit:** 6e3e6870

**2. [Rule 2 - Correctness] Empty id lists keep enqueuing one job**
- `Chunks.ids([])` returns `[]`, which would have inserted nothing, and `List.last([])` would have produced a result with no job. `RecoveryAction.retry/2` can pass an empty id list from a payload, so `at_least_one_chunk/1` keeps today's single empty job. Commit f6199238.

### Environment
- The fresh worktree had no `deps/`, so I ran `mix deps.get` against the existing `mix.lock`. No packages were added or changed.

## Deferred Issues

- `Scrypath.NoHumanGatesContractTest` (179-04/179-05 `verification: backstop`). This failure was expected and is outside this plan's scope.

## Known Stubs

None.

## Threat Flags

None. The changes fall within T-179-06 (at most 1000 ids per job), T-179-07 (transaction plus rollback, proven on SQLite) and T-179-08 (shared `unique_opts/0` with sorted ids).

## Self-Check: PASSED

- FOUND: lib/scrypath/oban/enqueue.ex, lib/scrypath/operations.ex, test/support/oban_sqlite_repo.ex, test/support/oban_sqlite_migration.ex, test/scrypath/oban/enqueue_unique_test.exs, test/scrypath/oban/enqueue_test.exs
- FOUND commits: f6199238, 408fba35, 6e3e6870
