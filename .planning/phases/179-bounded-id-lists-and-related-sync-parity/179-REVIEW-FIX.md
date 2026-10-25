---
phase: 179-bounded-id-lists-and-related-sync-parity
fixed_at: 2026-10-25T00:00:00Z
review_path: .planning/phases/179-bounded-id-lists-and-related-sync-parity/179-REVIEW.md
iteration: 1
findings_in_scope: 6
fixed: 6
skipped: 0
status: all_fixed
---

# Phase 179: Code Review Fix Report

**Source review:** `179-REVIEW.md`
**Iteration:** 1
**Scope:** critical + warning (IN-01..IN-05 are out of scope and were not touched)

**Summary:**
- Findings in scope: 6 (CR-01, WR-01..WR-05)
- Fixed: 6. CR-01 and WR-02 were fixed earlier; WR-01, WR-03, WR-04 and WR-05 are fixed in this pass.
- Skipped: 0

| Finding | Status | Commit | Notes |
|---------|--------|--------|-------|
| CR-01 | fixed (previously) | 858e83dc | Job module names now resolve by the full atom, so they decode in a release. Not redone. |
| WR-02 | fixed (previously) | 4d74ed9d | Jobs whose `document_ids` hold non-id values are cancelled. Not redone. |
| WR-01 | fixed | 24a35c9a | Nested enqueue inserts in the caller's transaction and returns the bare error. Tests cover both paths. Needs human check of the logic. |
| WR-03 | fixed (docs + test, no behaviour change) | 81930d86 | Upgrade note added to the related guide and to the 179-06 Release note. A legacy fixture test pins the `:repo_required` cancel. |
| WR-04 | fixed | 70c8f326 | Backfill reports `delete_tasks:`, and reindex waits on those tasks too. Needs human check of the logic. |
| WR-05 | fixed | a28bc4e7 | The span start count is now deduped. Deduped, string-sorted `document_ids` is documented rather than reverted. |

## Fixed Issues

### WR-01: Multi-chunk enqueue transaction poisons the caller's transaction

**Files modified:** `lib/scrypath/oban/enqueue.ex`, `test/scrypath/oban/enqueue_unique_test.exs`, `guides/sync-modes-and-visibility.md`
**Commit:** 24a35c9a

**Applied fix:**
- `insert_chunks/2` with two or more changesets now checks `Oban.Repo.in_transaction?(conf)`.
- **Nested:** it opens no transaction and never calls rollback. It inserts the chunks one after another in the caller's transaction and stops at the first failure, returning that bare `{:error, reason}`. The caller must fail its own transaction; returning the error from `Ecto.Multi.run/3` does this.
- **Not nested:** the existing all-or-nothing own-transaction path is unchanged.
- Single-chunk behaviour and the path for a fake module with no running Oban instance are unchanged.
- This follows the nested-transaction warning on `Oban.Repo.transaction/3`: no Scrypath-opened transaction, and so no retry loop, runs inside the caller's transaction. That makes `retry: false` moot.
- The guide's `:oban` section now states the contract for callers inside a transaction.

**Tests** (real Oban, Lite engine on SQLite):
- A failed nested insert returns `{:error, %Ecto.Changeset{}}`, the caller's transaction still accepts queries, and a caller rollback leaves no jobs. The old code fails this test with `DBConnection.ConnectionError: transaction rolling back`; I checked this by temporarily reverting the source.
- A `Multi.run` step that returns the error aborts the transaction and leaves no jobs.
- 2,500 records synced inside a caller transaction produce 3 committed chunk jobs.
- The existing non-nested rollback test still passes.

### WR-03: 0.3.17 related jobs cancel with `:repo_required` after upgrade

**Files modified:** `guides/related-data-and-reindexing.md`, `.planning/phases/179-bounded-id-lists-and-related-sync-parity/179-06-SUMMARY.md`, `test/scrypath/sync/related_worker_test.exs`
**Commit:** 81930d86

**Applied fix:** No behaviour change, as directed.

The related guide has a new "Upgrading from 0.3.17 with `:oban` related jobs still queued" note after the "needs a way to load owners" bullet. It tells adopters to do one of these before deploying:
- configure a default repo with `config :scrypath, :defaults, repo: MyApp.Repo`, which queued jobs pick up through `Config.resolve!` when they run
- define `search_records/2`
- let the related jobs drain on the old version

It also says how to recover jobs that were already cancelled: retry them after the fix, or re-run `sync_related/3`. The same instruction is now a bullet in the 179-06-SUMMARY "Release note" section.

The worker is named as the string `worker: "Scrypath.Sync.RelatedWorker"`, not as a backticked module. The module is `@moduledoc false`, so a backticked reference fails `mix docs --warnings-as-errors`.

**Test:** a legacy 0.3.17 args fixture for a repo-less owner with no `search_records/2` returns `{:cancel, {:invalid_job, :repo_required}}`. The resolver and the backend are not called.

### WR-04: Backfill keeps only the last delete chunk's task

**Files modified:** `lib/scrypath/backfill.ex`, `lib/scrypath/reindex.ex`, `lib/scrypath.ex`, `guides/sync-modes-and-visibility.md`, `test/scrypath/backfill_test.exs`, `test/scrypath/reindex_test.exs`
**Commit:** 70c8f326

**Applied fix:**
- Each `batch_results` entry now has `delete_tasks:`, built the same way as upsert `tasks:`:
  - one task per delete chunk, in order
  - always a list, and `[]` when the batch deleted nothing
  - `delete_task` is kept as the last entry, present only when the batch submitted a delete
- The `Scrypath.backfill/2` docs ("Result" and "Batch tasks") and the sync-modes guide describe both lists and tell callers to follow every entry.
- Reindex did **not** wait on delete tasks before this change. It now waits on every `delete_tasks` entry after the `tasks` entries before cutover.

Reindex always backfills into a fresh target with `_scrypath_fresh_target: true`, so today it submits no deletes. I still added the wait so the cutover guarantee ("waits on every task backfill reports") holds by construction rather than through that coupling. I chose this over leaving it as dead-path documentation because it is cheap and cannot change today's behaviour. A `%Result{}` batch, used by the existing test fakes, still goes through the old single-`task` wait path.

**Tests:**
- 2,500 ids omitted on one page give `delete_tasks` uids `[901, 1901, 2901]`, with `delete_task` equal to the last entry.
- A batch with no deletes has `delete_tasks: []` and no `delete_task` key.
- Reindex waits on injected delete chunk tasks 41 and 42 before swapping.

### WR-05: Telemetry start count includes duplicates; ≤1000 results are deduped and sorted

**Files modified:** `lib/scrypath/sync.ex`, `lib/scrypath.ex`, `guides/sync-modes-and-visibility.md`, `test/scrypath/telemetry_test.exs`
**Commit:** a28bc4e7

**Applied fix:**
- `sync_records` span start now uses `distinct_record_count/2`, which applies `Enum.uniq_by` on `Identity.document_id`. That is the same key both dispatch paths dedupe on.
- `delete_documents` span start now uses `Enum.uniq |> length`, matching `Chunks.ids/1`.
- If a record's id cannot be read, the start count falls back to `length(records)`, so dispatch still raises inside the span and the error is reported as the span's `:exception` event, as before.

**Ordering choice:** I documented the new behaviour rather than reverting it, as directed. D-03 removed the ordering contract and requires deduped, sorted ids so that unique-job collapse works. Reverting only the ≤1000 case would make results behave differently depending on call size.

`@sync_public_ops_doc` and the guide's "Large id lists" section now say that `document_ids`:
- lists each id once, sorted by its string form (`[2, 10]` becomes `[10, 2]`), for any call size
- must not be zipped with the caller's input

and that `document_count` counts distinct ids and matches the span start and stop counts.

This narrows D-08's "≤1000 unchanged" promise, and that narrowing is intended. Per the 179-06 decision, the CHANGELOG was not edited. The release-PR author should carry this sentence into the 0.3.x upgrade notes.

**Test:** duplicate records and ids give the same deduped `document_count` (2) on span start and stop for both upsert and delete, and the result's `document_ids` is `[10, 2]`.

## Verification

All gates ran in the **main checkout** (`/Users/jon/projects/scrypath`, branch `planning/v1.44-new-milestone`) with no worktree, as the maintainer instructed. Toolchain: `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5`.

- `mix compile --warnings-as-errors --force`: exit 0
- `mix format --check-formatted`: exit 0
- `mix credo --strict`: no issues
- `mix docs --warnings-as-errors`: exit 0, with no "failed due to warnings" line
- `mix test --exclude integration --exclude docs_contract`: 5 properties, 845 tests, 0 failures. The baseline was 837; the 8 new tests are 3 for WR-01, 1 for WR-03, 3 for WR-04 and 1 for WR-05.
- `mix test --include docs_contract test/scrypath/docs_contract_test.exs`: 74 tests, 0 failures
- `mix verify.phase108`: 6 tests, 0 failures (run after WR-03)

---

_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
