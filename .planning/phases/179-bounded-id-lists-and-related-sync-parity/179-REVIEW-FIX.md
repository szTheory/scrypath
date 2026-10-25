---
phase: 179-bounded-id-lists-and-related-sync-parity
fixed_at: 2026-10-25T00:00:00Z
review_path: .planning/phases/179-bounded-id-lists-and-related-sync-parity/179-REVIEW.md
iteration: 2
findings_in_scope: 11
fixed: 10
skipped: 1
status: all_fixed
---

# Phase 179: Code Review Fix Report

**Source review:** `179-REVIEW.md`
**Iteration:** 2 (iteration 1 covered CR-01 and WR-01..WR-05; iteration 2 covers IN-01..IN-05)
**Scope:** all (critical + warning + info)

`status: all_fixed` means every in-scope finding is either fixed or skipped by design with a written rationale. IN-05 is the one skip: the omission it flags is deliberate and correct, so only a code comment was added.

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
| IN-01 | fixed | b9d67b09 | Oban enqueue dedupes ids as the job stores them, and `Chunks` uses the same key in every mode. Tests added. |
| IN-02 | fixed (docs) | d8053655 | The guide now says, per mode, where `sync_related/3` belongs relative to a transaction. The example already follows the rule and is unchanged. |
| IN-03 | fixed | c250ce5c | Removed the ecommerce resolver's id clause, which skipped the tenant filter. The test passes loaded categories. |
| IN-04 | fixed | 44a44b84 | A non-list `search_records/2` result now cancels as `{:invalid_job, :invalid_search_records}`. Tests added. |
| IN-05 | skipped (by design) | 64b8dc8c | The `:executing` omission is correct (D-20). Only a code comment was added; behaviour is unchanged. |

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

## Iteration 2: Info findings

### IN-01: Dedupe runs on raw values before JSON serialization

**Files modified:** `lib/scrypath/chunks.ex`, `lib/scrypath/oban/payload.ex`, `lib/scrypath/oban/enqueue.ex`, `lib/scrypath/sync/related_enqueue.ex`, `lib/scrypath/sync.ex`, `test/scrypath/chunks_test.exs`, `test/scrypath/oban/enqueue_test.exs`, `test/scrypath/sync/related_test.exs`
**Commit:** b9d67b09

I checked the claim against the source first. `Payload.serialize_scalar!/1` turns an atom into its name and leaves strings, integers, floats, booleans and `nil` as they are. So `:a` and `"a"` were both stored as `"a"`, and `document_count` counted that id twice. The review's other example, `1` and `"1"`, does not collapse: JSON keeps them apart, the job stores them apart, and the existing `Chunks` contract and its test deliberately keep them distinct. I left that unchanged.

**Applied fix:**
- New `Payload.serialize_ids!/1`. `Enqueue.enqueue_upsert/3`, `Enqueue.enqueue_delete/3` and `RelatedEnqueue.enqueue/4` serialize the ids before `Chunks.ids/1`, so dedupe, sort and chunking all work on the values the job stores.
- To keep inline and manual mode consistent, `Chunks` now dedupes on `id_key/1`. That function maps a non-boolean, non-nil atom to its name and leaves every other value as it is. `Chunks.ids/1` keeps the first occurrence of each id, and `Chunks.by_id/2` keeps the last.
- New `Chunks.distinct_count/1`. The `delete_documents` span start count now uses it, and `sync_records`' `distinct_record_count/2` uses the same key. The WR-05 rule still holds: the span start count, the stop count and the result count agree.

**Tests:**
- `Chunks`: atom and string collapse, booleans and `nil` stay distinct, `distinct_count/1` works, and `by_id/2` collapses atom and string ids.
- Enqueue: `[:a, "a", 1, "1", :b]` produces one job with ids `[1, "1", "a", "b"]` and count 4.
- Related enqueue: triggers with ids `:a` and `"a"` produce one id `"a"` and count 1.

### IN-02: Example calls `sync_related` inside an open transaction against the guide

**Files modified:** `guides/related-data-and-reindexing.md`
**Commit:** d8053655

I checked the claim. The ecommerce example runs `sync_mode: :oban`, and Oban uses `repo: ScrypathEcommerce.Repo`, the same repo the `Multi` runs on (`examples/scrypath_ecommerce/config/config.exs`). The job is inserted on the transaction's connection, so no worker can see it before the commit, and a rollback discards it. The guide's reason ("the job can run on another connection before the commit") was wrong for this setup. The example is correct under the corrected rule, so I did not change it.

**Applied fix:** the "Call `sync_related/3` after the write commits" bullet now gives one rule per case:
- **`:oban` with Oban on the same repo:** calling it inside the transaction, for example from `Ecto.Multi.run/3`, is supported and atomic. Return the `{:error, _}` so the transaction aborts; this is the WR-01 contract, and the bullet points to the sync-modes guide's `:oban` section.
- **`:oban` with Oban on a different repo or database:** call it after the commit.
- **`:inline`:** call it after the commit, or the backend indexes rows that are not committed yet.

The guide's other code sample makes no transaction and calls after the commit, which is correct in every mode, so it is unchanged. The review's note that the example "also hits WR-01" with more than 1000 categories no longer applies: WR-01 (24a35c9a) made nested inserts safe.

### IN-03: The ecommerce resolver's id clause is dead code that skips the tenant filter

**Files modified:** `examples/scrypath_ecommerce/lib/scrypath_ecommerce/catalog.ex`, `examples/scrypath_ecommerce/test/scrypath_ecommerce/catalog_test.exs`
**Commit:** c250ce5c

**Applied fix:**
- Removed the `[_id | _]` clause of `resolve_products_for_categories/1`, which ran `skip_tenant_id: true` with no tenant filter. The struct clause scopes products by each category's `tenant_id` and is now the only non-empty clause, with a comment saying so.
- `git grep` found no other callers. The catalog test now calls the resolver with `[category]`, and also checks that `[]` returns `[]`.
- This supersedes the 179-07 plan's choice to keep the clause for that test. It now matches the related guide ("id clauses are now dead code and safe to remove").

**Verification** (example checkout, no Docker container started, stopped or recreated):
- I first had to run `MIX_ENV=test mix deps.get` in the example. `bandit` and `lazy_html` reported a lock mismatch in the local `deps/` directory. Fetching the locked versions changed no tracked file; `mix.lock` is unchanged.
- `MIX_ENV=test mix compile --warnings-as-errors --force`: exit 0.
- `PGHOST=127.0.0.1 mix test test/scrypath_ecommerce/catalog_test.exs` against native Postgres on 127.0.0.1:5432: 10 tests, 0 failures.
- `mix format --check-formatted` on both files: exit 0.

### IN-04: Loader programming errors are retried instead of cancelled

**Files modified:** `lib/scrypath/oban/upsert_worker.ex`, `lib/scrypath/sync/related_worker.ex`, `guides/related-data-and-reindexing.md`, `test/scrypath/oban/worker_test.exs`, `test/scrypath/sync/related_worker_test.exs`
**Commit:** 44a44b84

**Applied fix:**
- In both workers, `{:error, {:invalid_search_records, _returned}}` from `Loader.load/3` now returns `{:cancel, {:invalid_job, :invalid_search_records}}`, following D-14. The reason does not include the returned value, following Phase 178 D-05; that value can be arbitrary or large.
- `Loader` still returns `{:invalid_search_records, other}` to backfill and reindex callers, unchanged.
- The related guide's worker outcome table has a new row for this cancel, saying to fix `search_records/2` and then retry the cancelled job.

**Tests:** a schema whose `search_records/2` returns `{:ok, list}` is cancelled with that tag by both the upsert worker and the related worker, and the resolver and backend are never called. Before the fix, both workers returned `{:error, _}`.

### IN-05: The unique `:states` list omits `:executing` (skipped by design)

**File:** `lib/scrypath/oban/enqueue.ex` (`unique_opts/0`)
**Commit:** 64b8dc8c (comment only, no behaviour change)

**Reason:** the omission is deliberate (D-20) and correct for sync. A job that is running may have loaded its rows before the caller's write committed. If a new identical sync collapsed into that job, the update would be lost. Adding `:executing` would bring back the lost-update bug that D-20 prevents.

**Checked in `deps/oban` (2.23.0):**
- `Oban.Job.warn_unique/1` is called only from `Oban.Worker`'s compile-time option validation (`worker.ex:514`), which covers worker-level `unique:`. Scrypath passes `unique:` to `Oban.Job.new/2` at runtime, and `validate_unique` there does not warn. Nothing warns, so there is nothing to suppress.
- The Oban 2.23 CHANGELOG says explicit `:states` lists are deprecated in favour of groups. None of the groups (`:all`, `:incomplete`, `:scheduled`, `:successful`) leaves out `:executing` while keeping `:available` and `:retryable`, so Scrypath needs an explicit list.
- The Basic, Lite and Dolphin engines check uniqueness with a query at insert time only, so the gap in states is safe for them.
- The caveat for index-enforced engines (Oban Pro's Smart engine) is recorded in the comment and has not been checked against Pro.
- `:suspended` is also not added: Scrypath never inserts suspended jobs, and adding it would mean checking that the `~> 2.21` floor accepts that state.

**Follow-up option:** the maintainer could add a one-line Pro caveat to the public sync-modes guide if a Pro adopter appears. I left it out of the public docs because I could not verify it.

## Verification

All gates ran in the **main checkout** (`/Users/jon/projects/scrypath`, branch `planning/v1.44-new-milestone`) with no worktree, as the maintainer instructed. Toolchain: `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5`.

- `mix compile --warnings-as-errors --force`: exit 0
- `mix format --check-formatted`: exit 0
- `mix credo --strict`: no issues
- `mix docs --warnings-as-errors`: exit 0, with no "failed due to warnings" line
- `mix test --exclude integration --exclude docs_contract`: 5 properties, 845 tests, 0 failures. The baseline was 837; the 8 new tests are 3 for WR-01, 1 for WR-03, 3 for WR-04 and 1 for WR-05.
- `mix test --include docs_contract test/scrypath/docs_contract_test.exs`: 74 tests, 0 failures
- `mix verify.phase108`: 6 tests, 0 failures (run after WR-03)

**Iteration 2** gates ran in the **main checkout** as well, after the IN-05 commit (64b8dc8c), with the same toolchain:

- `mix compile --warnings-as-errors --force`: exit 0
- `mix format --check-formatted`: exit 0
- `mix credo --strict`: no issues
- `mix docs --warnings-as-errors`: exit 0
- `mix test --exclude integration --exclude docs_contract`: 5 properties, 851 tests, 0 failures. The baseline was 845; the 6 new tests are 4 for IN-01 and 2 for IN-04.
- `mix test --include docs_contract test/scrypath/docs_contract_test.exs`: 74 tests, 0 failures
- `test/scrypath/phase108_contract_test.exs` and `test/scrypath/backfill_contract_docs_test.exs`, run with docs_contract after IN-02: pass
- Ecommerce example (IN-03): see the IN-03 section. Compile with warnings as errors gave exit 0, and `catalog_test.exs` gave 10 tests, 0 failures on native Postgres.

---

_Fixer: Claude (gsd-code-fixer)_
_Iteration: 2_
