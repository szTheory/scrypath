---
phase: 179-bounded-id-lists-and-related-sync-parity
fixed_at: 2026-10-26T00:45:00Z
review_path: .planning/phases/179-bounded-id-lists-and-related-sync-parity/179-REVIEW.md
iteration: 4
findings_in_scope: 4
fixed: 4
skipped: 0
status: all_fixed
---

<!-- Iteration 4 counts cover the second re-review findings (WR-08, WR-09, IN-07, IN-08). Iteration 3 covered CR-02, WR-06, WR-07, IN-06 (all fixed; WR-07 partly, remainder is WR-08). Iterations 1-2 covered 11 findings: 10 fixed, 1 skipped by design (IN-05); IN-02 was later reopened as CR-02. -->


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

## Iteration 3: re-review findings

**Source review:** `179-REVIEW.md` (re-review of e69b2601..79c3dc7f). Scope: all four open findings.

| Finding | Status | Commit | Notes |
|---------|--------|--------|-------|
| CR-02 | fixed | 7e33db41 | Both guides say to call sync functions after the commit, with the correct reasons. The ecommerce `update_category/3` syncs after `Repo.update`. Needs a human check of the guide wording. |
| WR-06 | fixed | f021a559 | One shared predicate, `JobArgs.document_id?/1`. Enqueue raises `ArgumentError` for nil, float and boolean ids. |
| WR-07 | fixed | 9c63f4a2 | The default loader casts ids to the key's Ecto type. An id that fails the cast cancels as `{:invalid_job, {:invalid_arg, "document_ids"}}`. Needs a human check of the logic. |
| IN-06 | fixed | ce86499e | Inline `sync_related` dedupes triggers by `Chunks.id_key/1`, and the span counts the deduped set. |

### CR-02: The guides recommend enqueueing inside the caller's transaction

**Files modified:** `guides/sync-modes-and-visibility.md`, `guides/related-data-and-reindexing.md`, `lib/scrypath/oban/enqueue.ex` (comment), `lib/scrypath/oban.ex` (moduledoc), `examples/scrypath_ecommerce/lib/scrypath_ecommerce/catalog.ex`, `examples/scrypath_ecommerce/test/scrypath_ecommerce/catalog_test.exs`
**Commit:** 7e33db41

I checked the claim against `deps/oban/lib/oban/engines/basic.ex` before changing anything:
- `insert_unique/3` decides `conflict?` at insert time.
- `acquire_lock/2` takes `pg_try_advisory_xact_lock` when testing is disabled, and returns an unsaved `conflict?: true` job when the lock is held.

**Applied fix:**
- **Sync-modes guide:** a new subsection, "Call sync functions after your write commits", under the `:oban` job section. It covers `sync_records/3`, `delete_documents/3` and `sync_related/3` in every mode, and gives three reasons:
  - An in-transaction enqueue can collapse into a pending job that runs before the commit and reads the old rows (D-20).
  - The transaction-scoped unique lock makes a concurrent identical sync report `conflict?: true` without inserting, so that sync is lost if the caller rolls back.
  - Under `:inline`, the backend would index rows that are not committed yet.
- **The trade-off is stated.** A crash between the commit and the call misses that sync. The data is committed, so a retry, a backfill or a reindex recovers it. The text links to `drift-recovery.md` and the recovery posture for each mode.
- **The WR-01 paragraph is kept but reframed.** It now reads "If you do call a sync function inside a transaction on the Oban repo, Scrypath won't break your transaction", followed by the nested-insert mechanics and "the freshness hazards above still apply". It no longer reads as a recommended pattern.
- **Related guide:** the bullet is back to "Call `sync_related/3` after the write commits, in every sync mode", with the same reasons, the trade-off, and a pointer to the sync-modes subsection for the nested-call safety net.
- **Coherence additions:**
  - `Scrypath.Oban.enqueue_upsert/5` and `enqueue_delete/5` insert into the caller's `Ecto.Multi` by design, so the same hazard applies to them. Their moduledoc and the guide now say so and point callers to the after-commit sync functions. Their behaviour is unchanged; see the follow-up below.
  - The `insert_chunks/2` comment now calls the nested path a safety net.
- **Example:** `update_category/3` no longer uses a `Multi`.
  - It runs `Repo.update` and calls `Scrypath.sync_related/3` only on success.
  - A sync error is logged with `Logger.warning`, and the function still returns `{:ok, category}`. That matches how the example's `create_product`, `update_product` and `delete_product` treat post-commit sync results: the write is not reported as failed.
  - Return contract: `{:ok, category}` or `{:error, changeset}`. The old `{:error, reason}` for a sync failure inside the `Multi` is gone. The only caller, `E2EController.category_name/2`, matches `{:error, reason}` generically, so it still works.

**Tests:**
- The existing `update_category/3 enqueues related product sync` test still passes.
- New: a failed update returns `{:error, changeset}`, enqueues no `RelatedWorker` job, and leaves the category unchanged.
- I did not add a test for the logged sync-error path. Under `Oban.Testing` in manual mode, `sync_related` cannot be made to return `{:error, _}` deterministically, and configuration errors raise instead.

**Follow-up (design decision, not done):** If transactional-outbox semantics are wanted for the `Scrypath.Oban` Multi helpers, they need a non-unique insert path when `in_transaction?` is true, as the review notes.

### WR-06: Enqueue accepts ids the worker cancels

**Files modified:** `lib/scrypath/oban/payload.ex`, `lib/scrypath/oban/job_args.ex`, `guides/sync-modes-and-visibility.md`, `test/scrypath/oban/enqueue_test.exs`, `test/scrypath/sync/related_test.exs`
**Commit:** f021a559

**Applied fix:**
- **One predicate:** `JobArgs.document_id?/1` (`is_integer or is_binary`), now public and `@doc false`. The worker's `fetch_document_ids/1` and `Payload.serialize_ids!/1` both use it, so the two sides cannot drift.
- **`serialize_ids!/1`** serializes each id as before (an atom becomes its name), then raises `ArgumentError` ("Oban sync document ids must be integers or strings, got nil") for anything else. This follows the existing `serialize_scalar!/1` raise convention.
- **`Payload.build_upsert/3` and `build_delete/3`** now use `serialize_ids!/1` as well. That covers every enqueue path: `sync_records`, `delete_documents`, `sync_related`, and the `Scrypath.Oban` Multi helpers.
- **Guide:** one sentence in the sync-modes job section about allowed id types and the raise.

**Correction to the review:** `delete_record/3` on a struct with `id: nil` never returned `:accepted`. `List.wrap(nil)` is `[]`, so the call was, and still is, a `:noop` that enqueues nothing. The test now pins that noop. The rest of the claim holds: `sync_records/3` with one nil-id struct returned `:accepted` and then cancelled the whole chunk job.

**Tests:**
- `sync_records` with `[id: 1, id: nil]` raises and inserts nothing.
- `delete_record` on a nil-id struct is a noop.
- `delete_documents` raises for each of `nil`, `1.5` and `true`.
- The Multi helper `enqueue_delete/5` raises for `[nil]`.
- `serialize_ids!([1, "a", :b])` gives `[1, "a", "b"]`, and every value satisfies `document_id?/1`.
- Related enqueue with a nil-id trigger raises and inserts nothing.

### WR-07: Uncastable string ids raise in the loader and retry 8 times

**Files modified:** `lib/scrypath/loader.ex`, `lib/scrypath/oban/upsert_worker.ex`, `lib/scrypath/sync/related_worker.ex`, `lib/scrypath/oban/job_args.ex` (comment), `guides/related-data-and-reindexing.md`, `test/scrypath/oban/worker_test.exs`, `test/scrypath/sync/related_worker_test.exs`, `test/support/loader_backfill_cases.ex`
**Commit:** 9c63f4a2

**Applied fix:**
- **Loader:** the default query in `Loader.fetch/3` now casts each id with `Ecto.Type.cast/2` before querying.
  - The type is that of the field the query filters on, `__schema__(:type, document_id_field)`. That is the primary key unless the schema declares another `document_id:`.
  - If any cast fails, it returns `{:error, {:invalid_arg, "document_ids"}}`.
  - A castable string is cast before querying, so `"12"` becomes `12`.
- **Workers:** the upsert and related workers map `{:error, {:invalid_arg, _} = tag}` to `{:cancel, {:invalid_job, tag}}`. The delete worker never loads records, so it is unaffected.
- **Comment:** the `job_args.ex` comment that overstated what the shape check guarantees is corrected.
- **Guide:** the related guide's outcome table mentions the cancel.
- **Deviation from the brief:** I cast against the queried `document_id` field's type rather than requiring "a single primary key". This is the field the query actually binds, so it is also correct for a schema whose document id is not its primary key. For a single-primary-key schema with the default document id, the two are the same thing.
- **Casting is skipped when:**
  - the schema loads through `search_records/2`, because that path never reaches the default query and the app's loader owns its ids
  - the module has no `__schema__/2`, or the field has no Ecto type; ids are then passed through as before

**Tests:**
- A real SQLite loader case, run in the core lane through `LoaderBackfillCases`: `Loader.load(Product, [to_string(id)])` loads the row, and `[id, "abc"]` returns the tagged error. I checked that this case fails on the old loader by temporarily restoring `loader.ex` from git: it raised `Ecto.Query.CastError ... cannot be cast to type {:in, :id}`. I then re-applied the change.
- The upsert worker with `[1, "abc"]` cancels with `{:invalid_job, {:invalid_arg, "document_ids"}}` and never calls the repo or the backend.
- The upsert worker binds `"12"` as the integer `12`.
- The related worker with an integer-key Ecto owner and `[1, "abc"]` cancels the same way and never calls the resolver.

### IN-06: Inline `sync_related/3` passes duplicate triggers

**Files modified:** `lib/scrypath/chunks.ex`, `lib/scrypath/sync.ex`, `test/scrypath/chunks_test.exs`, `test/scrypath/sync/related_test.exs`
**Commit:** ce86499e

**Applied fix:**
- New `Chunks.uniq_by_id/2`. It dedupes by `id_key/1` and keeps the last copy, without sorting or chunking. `Chunks.by_id/2` now uses it, so there is one dedupe rule.
- `inline_resolve_and_sync/6` dedupes triggers with `Identity.document_id/2` before the span starts and before the resolver is called, so the span's `document_count` is the deduped count. This matches the guide's "Resolvers … get deduped input".
- Hand-written owner-only `__scrypath__/1` schemas answer only `:fan_outs`, and inline mode never needed their document id. The guide promises these "keep working", and two existing `sync_test.exs` fixtures are like this. For such a schema, an id read that raises keeps the caller's list unchanged, as before. Without this fallback those two tests failed with `FunctionClauseError`.

**Tests:**
- Inline `sync_related` with triggers `[1 "Old", 2, 1 "Latest"]` reports a resolve span start count of 2, resolves `"Latest"` and `"Two"` only, and returns a result count of 2.
- `uniq_by_id/2` collapses `:a` and `"a"`, keeps the last copy, and otherwise keeps the caller's order.

### Iteration 3 verification

All gates ran in the **main checkout** (`/Users/jon/projects/scrypath`, branch `planning/v1.44-new-milestone`) with no worktree, as the maintainer instructed. They ran after the last commit (ce86499e), with toolchain `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5`.

- `mix compile --warnings-as-errors --force`: exit 0
- `mix format --check-formatted`: exit 0
- `mix credo --strict`: no issues
- `mix docs --warnings-as-errors`: exit 0
- `mix test --exclude integration --exclude docs_contract`: 5 properties, 863 tests, 0 failures. The baseline was 851. The 12 new tests are 6 for WR-06 (5 enqueue, 1 related), 4 for WR-07 (2 upsert worker, 1 related worker, 1 SQLite loader case) and 2 for IN-06. The CR-02 test is in the example's suite.
- `mix test --include docs_contract test/scrypath/docs_contract_test.exs`: 74 tests, 0 failures
- Backfill contract docs, phase108 and phase112 contract tests, and package metadata, run with docs_contract: 18 tests, 0 failures
- **Ecommerce example**, on native Postgres at 127.0.0.1:5432; no Docker container was started, stopped or recreated:
  - `MIX_ENV=test mix compile --warnings-as-errors --force`: exit 0
  - `mix format --check-formatted` on both changed files: exit 0
  - `PGHOST=127.0.0.1 mix test test/scrypath_ecommerce/catalog_test.exs`: 11 tests, 0 failures. That is 10 existing tests plus 1 new.
  - The run logged `too_many_connections` from a few pool connections against the shared local Postgres. The tests were not affected.

## Iteration 4: second re-review findings

**Source review:** `179-REVIEW.md` (re-review of 79c3dc7f..6375b554). Scope: all four open findings.

| Finding | Status | Commit | Notes |
|---------|--------|--------|-------|
| WR-08 | fixed | dc50f0c9 | The loader now runs both planner steps: cast, then dump through the repo's adapter. A non-UUID id for a Postgres `:binary_id` key cancels instead of raising. Needs a human check of the logic. |
| WR-09 | fixed | 88b0458f | Oban retry validation checks each stored id with `JobArgs.document_id?/1` and returns `{:error, {:invalid_retry_input, :document_ids}}`. |
| IN-07 | fixed | 419c8656 | New `Catalog.update_category_and_sync/3` returns the sync outcome. The E2E endpoint reports `queued_related_sync` from it. |
| IN-08 | fixed (docs) | 81ba55a0 | The 179-06 Release note now lists every adopter-visible change from the fix cycle. |

### WR-08: Uncastable `:binary_id` ids still raise on Postgres

**Files modified:** `lib/scrypath/loader.ex`, `guides/related-data-and-reindexing.md`, `test/scrypath/loader_test.exs`
**Commit:** dc50f0c9

I confirmed the claim in IEx before changing anything:
- `Ecto.Type.adapter_dump(Ecto.Adapters.Postgres, :binary_id, "abc")` returns `:error`.
- A generated UUID returns `{:ok, <<16 bytes>>}`.

**Applied fix:**
- `cast_ids/4` now takes the repo. Each id must pass `Ecto.Type.cast/2` and then `Ecto.Type.adapter_dump(repo.__adapter__(), type, cast)`. If either step fails, it returns `{:error, {:invalid_arg, "document_ids"}}`, which both workers already cancel.
- The query still binds the cast value, not the dumped one, so the planner does its own dump as before.
- The dump step is skipped when the repo does not export `__adapter__/0` or the adapter has no `dumpers/2`. Hand-written test repos and fakes therefore behave as before.
- **No `rescue Ecto.Query.CastError` was added.** The adapter dump is the exact step the planner adds after the cast (`planner.ex` `cast_param` then `dump_param`), so it covers this case without hiding other cast errors.
- The `Loader.load/3` doc and the guide's outcome row now say "the document id field's type", and name the `:binary_id` on Postgres case.

**Tests** (`test/scrypath/loader_test.exs`) use a repo whose `__adapter__/0` returns `Ecto.Adapters.Postgres` and a `:binary_id` schema. No connection is needed.
- `[uuid, "abc"]` returns the tagged error and never queries. This test failed on the pre-fix loader: I temporarily restored `loader.ex` from HEAD and the stub repo received the query.
- A valid UUID still loads and is bound as the UUID string.
- A repo with no `__adapter__/0` skips the dump step and still queries.

**Postgres lane:** I ran the existing real-Postgres loader/backfill suite against the already-running `scrypath-postgres-1` on 127.0.0.1:5434, with `MIX_TEST_PARTITION=_rf179i4`. No container was started, stopped or recreated. Result: 15 tests, 0 failures. That suite has no single-key `:binary_id` table, so the `"abc"` case is proven through the Postgres adapter's real dumpers, not through a live query.

### WR-09: Operator retry of a bad-id job raises

**Files modified:** `lib/scrypath/operator/recovery_action.ex`, `test/scrypath/operator/failed_work_test.exs`
**Commit:** 88b0458f

**Applied fix:**
- `validate_oban_retry/3` has a new clause after the existing `is_list` check. For `:upsert` and `:delete`, it returns `{:error, {:invalid_retry_input, :document_ids}}` unless every stored id passes `JobArgs.document_id?/1`.
- The existing error for a missing list is `{:missing_retry_input, :document_ids}`. I added a sibling `:invalid_retry_input` tag for this case rather than reuse that one, because the list is present but its contents are bad.
- I did not change `Translation.replay_payload_available?/1`, which the review listed as optional. These rows are still offered as retryable, and retrying one now returns the error.

**ScrypathOps:** `FailedSyncLive.retry_failed_work/2` (`scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex:342-352`) already matches `{:error, reason}` and shows a "Retry failed: …" flash. I did not change scrypath_ops.

**Tests:** three cases: upsert `[1, nil]`, delete `[1.5]` and upsert `[true]`. Each returns the error tuple and inserts no job. All three raised `ArgumentError` on the pre-fix module, which I checked by temporarily restoring the file from HEAD.

### IN-07: The E2E endpoint always reports `queued_related_sync: true`

**Files modified:** `examples/scrypath_ecommerce/lib/scrypath_ecommerce/catalog.ex`, `examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/controllers/e2e_controller.ex`, `examples/scrypath_ecommerce/test/scrypath_ecommerce/catalog_test.exs`, `examples/scrypath_ecommerce/test/scrypath_ecommerce_web/controllers/e2e_controller_test.exs`
**Commit:** 419c8656

**Applied fix:**
- New `Catalog.update_category_and_sync/3`. It returns `{:ok, category, :ok | {:error, reason}}`, or `{:error, changeset}` if the update fails.
- `update_category/3` delegates to it and keeps its conventional `{:ok, category}` shape, so code copied from the example stays idiomatic.
- `sync_related_products/1` still logs the failure, and now also returns the error.
- The comment now notes that a raising sync still raises after the commit.
- The E2E `category_name/2` action uses the new function:
  - `:ok` keeps the existing response.
  - `{:error, reason}` returns 200, because the rename committed, with `queued_related_sync: false` and `related_sync_error: inspect(reason)`.
- `e2e/helpers/e2e.ts` reads `queued_related_sync` as a boolean and the spec does not assert its value, so the contract is unchanged.

**Tests:**
- Catalog, failing sync: an Oban stand-in whose `insert/1` fails, set through `:scrypath, :defaults` and restored in `on_exit`. The rename commits, the result is `{:error, :queue_down}`, the warning is logged, and no job is enqueued.
- Catalog, success: the result is `:ok` and a related job is enqueued.
- Controller: the endpoint reports `false` with the error. This test builds its tenant and category through `Catalog`, not `/dev/e2e/seed`, because seeding needs a live Meilisearch.

### IN-08: The release note is missing behaviour changes

**Files modified:** `.planning/phases/179-bounded-id-lists-and-related-sync-parity/179-06-SUMMARY.md`
**Commit:** 81ba55a0

The Release note gained six bullets, each checked against the code:
- **WR-06:** `ArgumentError` for nil, float or boolean ids under `:oban`, including the Multi helpers.
- **189cef0f:** the Multi helpers no longer use `unique:`, so job volume grows for hot rows.
- **WR-05:** `document_ids` is deduped and string-sorted at every call size.
- **WR-02/WR-07/WR-08/WR-09:** bad or unbindable ids cancel, and operator retry returns `{:invalid_retry_input, :document_ids}`.
- **WR-04:** `delete_tasks:`.
- **WR-01:** in-transaction behaviour: no nested transaction, a bare `{:error, reason}`, and the caller must fail its transaction.

WR-03's 0.3.17 upgrade path was already there and is unchanged.

### Iteration 4 verification

All gates ran in the **main checkout** (`/Users/jon/projects/scrypath`, branch `planning/v1.44-new-milestone`) with no worktree. They ran after the last commit (81ba55a0), with toolchain `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5`.

- `mix compile --warnings-as-errors --force`: exit 0
- `mix format --check-formatted`: exit 0
- `mix credo --strict`: no issues
- `mix docs --warnings-as-errors`: exit 0
- `mix test --exclude integration --exclude docs_contract`: 5 properties, 871 tests, 0 failures. The baseline was 865; the 6 new tests are 3 for WR-08 and 3 for WR-09.
- `mix test --include docs_contract test/scrypath/docs_contract_test.exs`: 74 tests, 0 failures
- Real-Postgres loader lane (`--only postgres`, 127.0.0.1:5434, `MIX_TEST_PARTITION=_rf179i4`): 15 tests, 0 failures
- scrypath_ops: not modified. `mix compile` there stops on a pre-existing `mix.lock` mismatch ("dependency is out of date"). I did not run `mix deps.get`.
- **Ecommerce example**, on native Postgres at 127.0.0.1:5432; no Docker container was started, stopped or recreated:
  - `MIX_ENV=test mix compile --warnings-as-errors --force`: exit 0
  - `mix format --check-formatted` on the four changed files: exit 0
  - `PGHOST=127.0.0.1 mix test test/scrypath_ecommerce/catalog_test.exs`: 13 tests, 0 failures. That is 11 existing tests plus 2 new.
  - `e2e_controller_test.exs` together with the catalog tests: 25 tests, 5 failures. All 5 are existing tests that call `/dev/e2e/seed`, which raises `econnrefused` against Meilisearch at localhost:7700. The `scrypath_ecommerce-meilisearch-1` container does not publish its port to the host. These failures are environmental and not caused by this change. The new controller test passes.

---

_Fixer: Claude (gsd-code-fixer)_
_Iteration: 4_
