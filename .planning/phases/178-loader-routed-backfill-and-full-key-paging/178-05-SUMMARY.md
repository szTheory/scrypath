---
phase: 178-loader-routed-backfill-and-full-key-paging
plan: 05
subsystem: docs
status: complete
tags: [backfill, reindex, docs, contract-test, postgres]
requires:
  - 178-02 (mix verify.postgres, backend lane Postgres service)
  - 178-04 (removed:/delete_task:/omitted: result keys, live-index omitted-id deletes)
provides:
  - "@doc for Scrypath.backfill/2 (result, batch tasks, cursor shape, removed documents)"
  - README result.omitted
  - Guide text on loader parity, removal vs omission, scope limit, composite keys, :query fan-out
  - CONTRIBUTING Postgres lane instructions
  - Core-lane contract test test/scrypath/backfill_contract_docs_test.exs
affects:
  - HexDocs for Scrypath.backfill/2
tech-stack:
  added: []
  patterns:
    - Core-lane (untagged) doc contract test over Code.fetch_docs/1 plus README/guides/CONTRIBUTING
key-files:
  created:
    - test/scrypath/backfill_contract_docs_test.exs
  modified:
    - lib/scrypath.ex
    - README.md
    - guides/sync-modes-and-visibility.md
    - guides/related-data-and-reindexing.md
    - CONTRIBUTING.md
decisions:
  - "The backfill @doc names reconcile_sync/2 as the drift-recovery path for rows outside the visited scope and names no internal module, option or hidden function"
  - "The :query fan-out guidance states the actual consequence (duplicates take batch slots and are dropped within a batch) rather than claiming incorrect paging"
  - "The contract test also refutes _scrypath_fresh_target and prepare_records in the backfill @doc"
metrics:
  duration: ~20m
  completed: 2026-10-25
actuals:
  tokens: 4200
  tasks: 2
  commits: 2
plan_head_before: c04eb9c292a25b43810de49ff748a6886b4944f3
plan_head_after: 124d5569
---

# Phase 178 Plan 05: Backfill result-contract docs and contract test Summary

`Scrypath.backfill/2` now has a HexDocs `@doc` covering the full result map: `index`, `batches`, `documents`, `removed`, `mode`, and `batch_results` entries with `index`, `documents`, `removed`, `last_primary_key`, optional `task` and optional `delete_task`. It also states that backfill waits on neither task in any `sync_mode`, gives the scalar and keyword (`[org_id: 1, id: 7]`) cursor shapes, and limits deletions to the visited scope. The README, both guides and CONTRIBUTING were updated to match what 178-02 and 178-04 shipped. A core-lane test pins all of it.

## Tasks

| Task | Name | Commit | Files |
| ---- | ---- | ------ | ----- |
| 1 (tracer) | backfill @doc, README result.omitted, contract test | 366b7fe4 | lib/scrypath.ex, README.md, test/scrypath/backfill_contract_docs_test.exs |
| 2 | Guides and CONTRIBUTING, extended contract test | 124d5569 | guides/sync-modes-and-visibility.md, guides/related-data-and-reindexing.md, CONTRIBUTING.md, test/scrypath/backfill_contract_docs_test.exs |

## What changed

- **lib/scrypath.ex**: added a `@doc` with `## Result`, `## Batch tasks`, `## Cursor shape` and `## Removed documents` sections. Each claim was checked against `lib/scrypath/backfill.ex`:
  - `task` is absent when no upsert ran.
  - `delete_task` is present only when a delete ran.
  - `removed` counts the ids submitted for deletion.
  - `public_cursor/2` returns a scalar or a keyword list.
  - Schemas without `search_records/2` never omit rows.
- **README.md**: added `result.omitted` to the reindex result list, plus one sentence saying omitted ids are counted, not deleted.
- **guides/sync-modes-and-visibility.md**: added two paragraphs after the `search_records/2` contract:
  - Loader parity.
  - A live backfill deletes omitted ids only from the rows it visits, asynchronously, and reports them under `delete_task`/`removed`. You must follow both tasks.
  - Reindex reports those ids as `omitted`.
  - The scope limit: this is not a whole-index prune. Rows deleted outside Scrypath, or outside the `:query` scope, wait for `Scrypath.reconcile_sync/2` or a reindex.
- **guides/related-data-and-reindexing.md**: added the same parity, removal-vs-omission and scope-limit points, and a new `### Primary keys and :query` subsection covering:
  - Composite keys are supported, with the keyword cursor.
  - Declare composite key fields in the database constraint's column order.
  - Which `:query` clauses are ignored.
  - `:query` must not fan out rows.
- **CONTRIBUTING.md**:
  - The verify-table backend row now mentions `mix verify.postgres`.
  - The backend runbook now has `docker compose up -d postgres meilisearch` and `SCRYPATH_POSTGRES_URL` in the env block, and a "real-Postgres loader/backfill tests" bullet.
  - A new standalone `mix verify.postgres` block notes that the database is dropped and recreated, and that plain `mix test` excludes `:postgres` unless the URL is set.
  - The **`backend`** job row now mentions the Postgres 16 service. The bold token is unchanged.
- CHANGELOG.md was not touched.

## Verification

- `mix test test/scrypath/backfill_contract_docs_test.exs`: 6 tests, 0 failures. The file has no `docs_contract` tag, so it runs in core.
- `mix test test/scrypath/backfill_contract_docs_test.exs test/mix/tasks/workflow_wiring_test.exs test/scrypath/phase108_contract_test.exs test/scrypath/phase112_contract_test.exs test/scrypath/telemetry_test.exs test/release/package_metadata_test.exs`: 71 tests, 0 failures.
- `mix test --include docs_contract test/scrypath/docs_contract_test.exs`: 74 tests, 0 failures.
- `mix docs --warnings-as-errors`: no warnings.
- `mix format --check-formatted`, `mix credo --strict` (no issues), `MIX_ENV=test mix compile --warnings-as-errors --force`: pass.
- Full `mix test`: 5 properties, 773 tests, 0 failures (24 excluded).
- Tracer gate: the Task 1 verify commands were re-run end to end before Task 2.
- Not run locally: the hosted PR checks named in the plan's phase gate. Those belong to the orchestrator's PR step.

## Deviations from Plan

**1. [Rule 1 - Accuracy] Fan-out consequence wording**
- **Found during:** Task 2
- **Issue:** Backfill dedupes within a batch, and its keyset predicate is strict. A fanned-out join therefore does not break paging. It only wastes batch slots and database work.
- **Fix:** The guide says exactly that, and recommends `where` or `exists` instead of a join that can match several rows.

**2. Plan commit ledger**
- The worktree sandbox blocked writing the ledger file under the shared `.git/worktrees/` dir.
- `plan_head_before` is the dispatched base c04eb9c2. `commits` was measured with `git rev-list c04eb9c2..HEAD`, which gives 2.

## Known Stubs

None.

## Threat Flags

None.
- T-178-13: both guides carry the scope-limit text, and `reconcile_sync`, `omitted` and "not a whole-index prune" are pinned.
- T-178-14: the `@doc` names no internal flag or hidden function, a test refutes both, and `mix docs --warnings-as-errors` passes.

## Self-Check: PASSED

- FOUND: test/scrypath/backfill_contract_docs_test.exs, lib/scrypath.ex, README.md, both guides, CONTRIBUTING.md
- FOUND commits: 366b7fe4, 124d5569
