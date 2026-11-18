---
phase: 179-bounded-id-lists-and-related-sync-parity
reviewed: 2026-10-25T23:59:00Z
depth: standard
review_kind: re-review
diff_range: 79c3dc7f..6375b554 (excluding .planning); commits 7e33db41, f021a559, 9c63f4a2, ce86499e, 189cef0f
files_reviewed: 16
files_reviewed_list:
  - lib/scrypath/chunks.ex
  - lib/scrypath/loader.ex
  - lib/scrypath/oban.ex
  - lib/scrypath/oban/enqueue.ex
  - lib/scrypath/oban/job_args.ex
  - lib/scrypath/oban/payload.ex
  - lib/scrypath/oban/upsert_worker.ex
  - lib/scrypath/sync.ex
  - lib/scrypath/sync/related_worker.ex
  - lib/scrypath/sync/related_enqueue.ex
  - lib/scrypath/operator/recovery_action.ex
  - examples/scrypath_ecommerce/lib/scrypath_ecommerce/catalog.ex
  - examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/controllers/e2e_controller.ex
  - examples/scrypath_ecommerce/test/scrypath_ecommerce/catalog_test.exs
  - guides/related-data-and-reindexing.md
  - guides/sync-modes-and-visibility.md
findings:
  critical: 0
  warning: 2
  info: 2
  total: 4
status: issues_found
---

# Phase 179: Code Review Report (re-review of iteration-3 fix commits)

**Reviewed:** 2026-10-25T23:59:00Z
**Depth:** standard
**Files Reviewed:** 16
**Status:** issues_found

## Summary

This review covers the five commits after the last review: 7e33db41 (CR-02), f021a559 (WR-06), 9c63f4a2 (WR-07), ce86499e (IN-06) and 189cef0f (Multi helpers without `unique:`). I also read the code these commits touch or that calls them:

- `Scrypath.Identity`, `Scrypath.Schema.Metadata`, `Scrypath.Sync.RelatedEnqueue`
- `Scrypath.Operator.RecoveryAction` and `FailedWork.Translation`, plus the ScrypathOps `failed_sync_live.ex` retry handler
- the ecommerce `E2EController`
- Oban 2.23: `Oban.Engine.insert_job/5` (Multi), `Oban.Engines.Basic` (`insert_unique/3`, `acquire_lock/2`)
- Ecto 3: `Ecto.Type.cast/2` for `:binary_id`, `Ecto.Query.Planner.cast_param/6`, and the `ecto_sql` Postgres dumpers

The targeted suites pass: `test/scrypath/oban_test.exs`, `test/scrypath/oban/`, `test/scrypath/sync/`, `chunks_test.exs` and `sync_test.exs` give 205 tests, 0 failures.

**CR-02 is resolved.** The after-commit guidance is now correct and the same in both guides, the `Scrypath.Oban` moduledoc, the `insert_chunks/2` comment and the example. The Multi-helper exception holds:

- `Oban.Engine.insert_job/5` runs the insert inside `Multi.run` with `%{conf | repo: repo}`, which is the Multi's own repo and connection. The job is therefore visible only at commit, whatever repo the Oban instance is configured with.
- With no `unique` change, `Basic.insert_unique/3` takes the `nil -> Repo.insert` branch. No advisory lock is taken, so the phantom-conflict hazard is gone.
- A later direct unique enqueue may collapse into a pending Multi-helper job. That is safe: the Multi job only exists after its commit, and it has not started yet.

**IN-06 and WR-06 are resolved** as scoped. **WR-07 is only partly resolved.** The new cast reproduces the planner's cast step but not its adapter-dump step. So the most common Phoenix key type, `:binary_id` on Postgres, still raises and is retried 8 times (WR-08). WR-06's new raise has one caller that expects `{:error, _}`: operator recovery retry. A legacy job holding a nil id now crashes the ScrypathOps retry handler (WR-09).

## Prior findings

| ID | Verdict | Evidence |
|----|---------|----------|
| CR-02 | **Resolved** | `sync-modes-and-visibility.md:134-144` and `related-data-and-reindexing.md:230-247` both say to call sync functions after the commit, in every mode. Both give the right reasons: collapse is decided at enqueue (`basic.ex:428-445`); the transaction-scoped `pg_try_advisory_xact_lock` (`basic.ex:533-541`) yields `conflict?: true` with nothing inserted; and inline writes would index uncommitted rows. The WR-01 nested path is described as a safety net (`enqueue.ex:131-140`). The Multi-helper exception (`oban.ex:10-14`, guide line 144) matches the code: `oban.ex:33,46` pass `unique: false`, and `enqueue.ex:232-233` drops `unique:`. It also matches Oban: `engine.ex:231-235` inserts on the Multi's repo. The example's `update_category/3` (`catalog.ex:68-74`) syncs only after `Repo.update` succeeds, and a test checks that a failed update enqueues no `RelatedWorker` job. Removing `unique:` from the Multi helpers creates no correctness hazard. The only cost is that repeated Multi writes are no longer collapsed (see IN-08 for the release-note gap). |
| WR-06 | **Resolved** (one caller regression: WR-09) | `job_args.ex:116` `document_id?/1` is the single predicate. `payload.ex:29-42` `serialize_ids!/1` applies it after atom→string serialization, and `build_upsert/3` and `build_delete/3` use it. Every enqueue path reaches it: `enqueue.ex:28,47` (direct), `related_enqueue.ex:41` (related), and `oban.ex:33,46` through `*_job_changeset` → `Payload.build_*` (Multi helpers). Identity-derived ids are still accepted: string and composite `search_document_id/1` values (`"tenant:1"`), UUID strings and atoms all serialize to integers or strings. Tuples and maps already raised in `serialize_scalar!/1`. `delete_record/3` on a nil-id struct stays a `:noop` (`sync.ex:128-133`, `List.wrap(nil) == []`). The new raise does reach `RecoveryAction.retry/2`, which is specced to return `{:ok, _} | {:error, _}` (WR-09). |
| WR-07 | **Partially resolved** (residual: WR-08) | `loader.ex:176-193` casts each id with `Ecto.Type.cast/2` against `__schema__(:type, Metadata.document_id(schema))`. That is the field the query binds, so a custom `document_id:` field is handled correctly. Schemas with no `__schema__/2`, or a field with no Ecto type, pass the ids through. `search_records/2` schemas never reach the cast. Both workers map `{:error, {:invalid_arg, _}}` to `{:cancel, {:invalid_job, tag}}`. The cast is exactly the planner's own cast step (`planner.ex:2592-2603`), so it cannot reject an id the query would have accepted. Castable ids such as `"12"` behave as before, because the planner cast them too. The planner's second step, `dump_param` (`planner.ex:1149`), is not mirrored. `Ecto.Type.cast(:binary_id, "abc")` returns `{:ok, "abc"}` (checked in IEx), but `Ecto.Type.adapter_dump(Ecto.Adapters.Postgres, :binary_id, "abc")` returns `:error`. The query therefore still raises `Ecto.Query.CastError`. |
| IN-06 | **Resolved** | `sync.ex:96,121-125` dedupes triggers with `Chunks.uniq_by_id/2`, keyed on `id_key/1` and keeping the last copy, before the span starts and before the resolver runs. The span `document_count` is the deduped length. `Chunks.by_id/2` now delegates to `uniq_by_id/2`, so there is one dedupe rule. When an id cannot be read (an owner-only `__scrypath__/1`), the fallback keeps the caller's list. That is the pre-fix behaviour, and the `sync_test.exs` fixtures still pass. The `rescue _error` is broad, but its only effect is to fall back to the old, non-deduped behaviour, so it cannot introduce a failure. |

## Narrative Findings (AI reviewer)

## Warnings

### WR-08: Uncastable ids for a `:binary_id` key still raise `Ecto.Query.CastError` on Postgres and use up all 8 retries (residual of WR-07)

**File:** `lib/scrypath/loader.ex:176-199`; `guides/related-data-and-reindexing.md:371`; `lib/scrypath/loader.ex:93-95` (doc)

**Issue:** The new `cast_ids/3` reproduces only the first half of what the Ecto planner does with a query parameter. `Ecto.Query.Planner.cast_param/6` (`deps/ecto/lib/ecto/query/planner.ex:1144-1162`) runs `cast_param` (= `Ecto.Type.cast/2`) and then `dump_param(adapter, type, cast_v)`. It raises `Ecto.Query.CastError` if either step fails.

For `:binary_id`, `Ecto.Type.cast/2` is `cast_binary/1` (`deps/ecto/lib/ecto/type.ex:845`) and accepts any binary. The Postgres adapter's dumper is `[type, Ecto.UUID]` (`deps/ecto_sql/lib/ecto/adapters/postgres.ex:185`). Verified:

```
Ecto.Type.cast(:binary_id, "abc")                                   #=> {:ok, "abc"}
Ecto.Type.adapter_dump(Ecto.Adapters.Postgres, :binary_id, "abc")   #=> :error
```

So for any schema with `@primary_key {:id, :binary_id, autogenerate: true}` (the `mix phx.gen --binary-id` default), a job holding a non-UUID string passes `cast_ids/3`. `repo.all/1` then raises. The upsert and related workers crash, and Oban retries all 8 attempts.

The prior review named exactly this case ("a non-UUID string against a `:binary_id` key"). Despite that, the guide row now says that "a document id the primary key's type cannot cast" is cancelled, and the `Loader.load/3` doc makes the same promise. The new SQLite test cannot catch this: `ecto_sqlite3` stores `:binary_id` as a string by default, so its dump succeeds.

**Fix:** mirror the dump step too, using the repo's adapter. Alternatively, rescue the cast error around the default query only:

```elixir
type ->
  adapter = repo.__adapter__()

  Enum.reduce_while(document_ids, {:ok, []}, fn id, {:ok, acc} ->
    with {:ok, cast} <- Ecto.Type.cast(type, id),
         {:ok, _dumped} <- Ecto.Type.adapter_dump(adapter, type, cast) do
      {:cont, {:ok, [cast | acc]}}
    else
      _ -> {:halt, {:error, {:invalid_arg, "document_ids"}}}
    end
  end)
```

This needs `repo` threaded into `cast_ids/3`; `fetch/3` already has it. The simpler alternative:

```elixir
try do
  {:ok, from(...) |> repo.all()}
rescue
  Ecto.Query.CastError -> {:error, {:invalid_arg, "document_ids"}}
end
```

Add a unit test that does not need Postgres: a fake repo whose `__adapter__/0` returns `Ecto.Adapters.Postgres`, with a `:binary_id` schema and the id `"abc"`. Also say "the document id field's type" instead of "the primary key's type" in the guide row.

### WR-09: Operator retry of a legacy job with a nil, float or boolean id now raises `ArgumentError` instead of returning `{:error, _}`, which crashes the ScrypathOps retry handler

**File:** `lib/scrypath/operator/recovery_action.ex:43-60` (calls `Enqueue.enqueue_upsert/3` and `enqueue_delete/3` with `payload["document_ids"]`); the raise comes from `lib/scrypath/oban/payload.ex:33-42` (f021a559)

**Issue:** `RecoveryAction.retry/2` is specced `{:ok, map()} | {:error, term()}`. Its Oban branch re-enqueues the stored job's `document_ids` verbatim, and `validate_oban_retry/3` checks only `is_list/1`.

`FailedWork.Translation.queue_attrs/3` marks any failed, cancelled or discarded upsert or delete job as `retryable?` whenever `document_ids` is a list (`translation.ex:36,105-110`). That includes the jobs this phase now cancels with `{:invalid_job, {:invalid_arg, "document_ids"}}` because they hold a `nil`, float or boolean id: jobs written by 0.3.17, by pre-f021a559 builds, or by hand.

Before f021a559, retrying such a job enqueued a replacement and returned `{:ok, _}`. Now `Payload.serialize_ids!/1` raises `ArgumentError` out of `retry/2`. `ScrypathOps.FailedSyncLive.retry_failed_work/2` (`scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex:342-352`) matches only `{:ok, _}` and `{:error, _}`, so the LiveView process crashes and the operator gets no "Retry failed" flash. These bad-id jobs are exactly the rows an operator is most likely to retry.

**Fix:** validate the stored ids in `validate_oban_retry/3` with the shared predicate, and return an error tuple:

```elixir
action.operation in [:upsert, :delete] and
    not Enum.all?(Map.get(payload, "document_ids"), &Scrypath.Oban.JobArgs.document_id?/1) ->
  {:error, {:invalid_retry_input, :document_ids}}
```

This clause goes after the existing `is_list` clause. Optionally, have `Translation.replay_payload_available?/1` use the same check, so these rows are not offered as retryable at all. Add a `RecoveryAction` test with a payload of `[1, nil]`.

## Info

### IN-07: The ecommerce E2E endpoint reports `queued_related_sync: true` even when the post-commit sync failed

**File:** `examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/controllers/e2e_controller.ex:316-318`; `examples/scrypath_ecommerce/lib/scrypath_ecommerce/catalog.ex:76-87`

**Issue:** Before 7e33db41, `{:ok, category}` from `update_category/3` meant the related sync had been enqueued, because a sync error rolled back the `Multi` and returned `{:error, reason}`. Now `update_category/3` logs a sync failure and still returns `{:ok, category}`. That is a reasonable post-commit policy and matches the product functions. However, `E2EController.category_name/2` still answers `queued_related_sync: true` unconditionally, so an E2E run can report a fan-out that never happened. Also, a raising `sync_related/3` (for example a config error) escapes after the commit. That is acceptable, but it is not mentioned in the new comment.

**Fix:** have `sync_related_products/1` return `:ok | {:error, reason}`, have `update_category/3` return a value the controller can use, and set `queued_related_sync` from it. Alternatively, drop the field or rename it to `related_sync_attempted`.

### IN-08: The phase release note omits three adopter-visible behaviour changes from this fix cycle

**File:** `.planning/phases/179-bounded-id-lists-and-related-sync-parity/179-06-SUMMARY.md:106-111` ("Release note", the declared source for the release PR's upgrade notes, since CHANGELOG is not edited per OQ6)

**Issue:** None of these changes from 0.3.17 is in the Release note:

1. **WR-06 (f021a559):** under `:oban`, `sync_records/3`, `delete_documents/3`, `sync_related/3` and the `Scrypath.Oban` Multi helpers now raise `ArgumentError` for nil, float or boolean ids. Before, they returned `{:ok, %{status: :accepted}}`.
2. **189cef0f:** in 0.3.17, `Scrypath.Oban.enqueue_upsert/5` and `enqueue_delete/5` used the shared `unique:` policy (`scrypath-0.3.17/lib/scrypath/oban/enqueue.ex:120`). Now every Multi commit inserts its own job, so job volume grows for hot rows. This is harmless for correctness but visible in queue metrics and Oban Web.
3. **WR-05:** `document_ids` is now deduped and sorted by its string form at every call size. The fix report explicitly says the release-PR author "should carry this sentence".

**Fix:** add three bullets to the 179-06 Release note so the release-PR author has one source.

---

_Reviewed: 2026-10-25T23:59:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
