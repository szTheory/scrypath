---
phase: 179-bounded-id-lists-and-related-sync-parity
reviewed: 2026-10-25T22:49:55Z
depth: standard
review_kind: re-review
diff_range: e69b2601..79c3dc7f (excluding .planning)
files_reviewed: 15
files_reviewed_list:
  - lib/scrypath.ex
  - lib/scrypath/backfill.ex
  - lib/scrypath/chunks.ex
  - lib/scrypath/oban/enqueue.ex
  - lib/scrypath/oban/job_args.ex
  - lib/scrypath/oban/payload.ex
  - lib/scrypath/oban/upsert_worker.ex
  - lib/scrypath/reindex.ex
  - lib/scrypath/sync.ex
  - lib/scrypath/sync/related_enqueue.ex
  - lib/scrypath/sync/related_worker.ex
  - examples/scrypath_ecommerce/lib/scrypath_ecommerce/catalog.ex
  - examples/scrypath_ecommerce/test/scrypath_ecommerce/catalog_test.exs
  - guides/related-data-and-reindexing.md
  - guides/sync-modes-and-visibility.md
findings:
  critical: 1
  warning: 2
  info: 1
  total: 4
status: issues_found
---

# Phase 179: Code Review Report (re-review of fix commits)

**Reviewed:** 2026-10-25T22:49:55Z
**Depth:** standard
**Files Reviewed:** 15
**Status:** issues_found

## Summary

This review covers the 11 fix commits after `e69b2601` (858e83dc through 64b8dc8c). I also read the code each fix touches: `Scrypath.Loader`, `Scrypath.Identity`, `Scrypath.Oban.DeleteWorker`, `Scrypath.Config`, and Oban 2.23's `Oban.Repo` and `Oban.Engines.Basic`.

The targeted test files pass: oban, sync, chunks, backfill, reindex and telemetry give 202 tests, 0 failures.

Most fixes hold:

- **CR-01:** module names resolve by the full atom, and atom safety is kept.
- **WR-01:** the nested-transaction branch is mechanically correct.
- **WR-04:** delete chunk tasks are reported and waited on before cutover.
- **IN-01:** id normalization is consistent across enqueue, `Chunks.id_key/1`, worker decoding and the span counts.

Two fixes regressed or left gaps:

- **IN-02 (d8053655)** replaced correct advice with incorrect advice, so it is now a blocker. The related guide used to say to call `sync_related/3` after the commit. It now says that calling it inside the transaction under same-repo `:oban` is "supported and atomic", and the sync-modes text added by WR-01 implies the same for `sync_records/3`. With Scrypath's `unique:` policy this is not safe. The collapse decision is made before the caller commits, which brings back the lost update that D-20 exists to prevent. The flagship ecommerce example follows this pattern.
- **WR-02 (4d74ed9d)** narrowed what the worker accepts, but the enqueue side still accepts the old types. A `nil`, float or boolean id is enqueued and then silently cancels its whole chunk of up to 1000 ids. Separately, a string for an integer primary key still raises and is retried 8 times.

## Prior findings

| ID | Verdict | Evidence |
|----|---------|----------|
| CR-01 | **Resolved** | `job_args.ex:250-256`: `safe_module/1` accepts only `"Elixir." <> _` and calls `String.to_existing_atom/1` on the full name. No atom is created. `resolve_existing_module/3` (236-245) still checks the exact spelling, `Code.ensure_loaded?` and the role validator. The new test builds the module at runtime with `Module.concat/1` and checks that the alias segments never become atoms. |
| WR-01 | **Resolved (mechanics)**, but see CR-02 | `enqueue.ex:142-163`: `Oban.Repo.in_transaction?(conf)` exists (generated from `deps/oban/lib/oban/repo.ex:66`) and checks `conf.repo.in_transaction?()`. Nested: there is no Scrypath-opened transaction and no rollback, and the bare `{:error, _}` is returned. A caller transaction on a different repo reports `false`, so Oban's own all-or-nothing transaction runs on its repo, which is correct. Partial inserts on error are not reachable in practice, because every chunk changeset is built the same way and the first one fails first. Oban's engine still nests `Repo.transaction` per insert (`basic.ex:71-75`), but that is pre-existing and the same as the single-chunk path. |
| WR-02 | **Partially resolved** | `job_args.ex:113-117` rejects non-integer, non-binary elements, so the shapes listed in the prior finding now cancel. Two gaps remain: a residual value-cast failure (WR-07), and a new asymmetry with what enqueue accepts (WR-06). |
| WR-03 | **Resolved (docs + test)** | The guide note at `related-data-and-reindexing.md:253-267` is accurate. `config :scrypath, :defaults` is the key `Config` reads (`config.ex:14`). The cancelled-job recovery path works, because the worker merges defaults through `Config.resolve!`. A legacy fixture test pins `{:cancel, {:invalid_job, :repo_required}}`. |
| WR-04 | **Resolved** | `backfill.ex:73-81` adds `delete_tasks: tasks_of(delete)`, always a list. `reindex.ex:221-264` waits on `tasks` and then `delete_tasks`, `put_waited/4` leaves empty lists alone, and a `%Result{}` batch falls through to the single-task path. The shapes agree: `task` is present exactly when `tasks != []`, and likewise for the delete keys. |
| WR-05 | **Resolved** for the upsert and delete spans | `sync.ex:26-29, 133-136, 153-159` dedupe the start count with the same `Chunks.id_key/1` key that dispatch uses, so start, stop and result counts agree. The inline related-resolve span still reports the raw trigger count (IN-06). |
| IN-01 | **Resolved** | Enqueue paths (`enqueue.ex:26-31, 45-50`, `related_enqueue.ex:40-42`) serialize before `Chunks.ids/1`. `id_key/1` (`chunks.ex:49-52`) maps the same values `serialize_scalar!/1` does (only non-boolean, non-nil atoms change), so the enqueue dedupe, the span count and the inline `by_id` dedupe agree. Workers only receive integers and strings, for which `id_key` is the identity. `Payload.build_*` re-serializing is idempotent, and `"document_count" == length(chunk)` still satisfies `check_document_count/2`. |
| IN-02 | **Not resolved: the fix regressed the guidance** | See CR-02. The old advice ("call after the write commits") was correct and only its stated reason was wrong. The new per-mode rule calls in-transaction enqueue "supported and atomic", and that is false under Scrypath's `unique:` policy. |
| IN-03 | **Resolved** | `catalog.ex:93-105`: only the tenant-scoped struct clause and `[]` remain. `Category.search_records/2` loads with `skip_tenant_id: true`, so Oban-loaded triggers carry `tenant_id`, which the resolver uses. The test passes `[category]` and checks `[]`. |
| IN-04 | **Resolved** | `upsert_worker.ex:52-55` and `related_worker.ex:34-37` map `{:invalid_search_records, _}` to `{:cancel, {:invalid_job, :invalid_search_records}}` without including the returned value. Clause order is correct: they come before the generic `{:error, reason}`. |
| IN-05 | **Skip rationale holds** | `Oban.Job.warn_unique/1` is called only from `deps/oban/lib/oban/worker.ex:514` at compile time. The Basic engine checks uniqueness with a query at insert time (`basic.ex:428-445`). The `enqueue.ex:85-102` comment is accurate. |

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-02: The guides now recommend enqueueing inside the caller's transaction, which reintroduces the D-20 lost update under `unique:`

**File:** `guides/related-data-and-reindexing.md:230-241` (from IN-02 fix d8053655); `guides/sync-modes-and-visibility.md:133` (from WR-01 fix 24a35c9a); applied in `examples/scrypath_ecommerce/lib/scrypath_ecommerce/catalog.ex:63-77`

**Issue:** The guide now says that under `:oban` with Oban on the same repo, calling `sync_related/3` inside the transaction "is supported and atomic", and the sync-modes `:oban` section describes in-transaction calls as the intended pattern. That is atomic for the job rows. It is not correct for search freshness, because every Scrypath job is inserted with `unique: [states: [:available, :scheduled, :retryable]]` (`enqueue.ex:104`), and Oban decides uniqueness when the job is inserted (`deps/oban/lib/oban/engines/basic.ex:428-445`).

1. **Collapse decided before commit.** Transaction T1 updates category C, then enqueues. An identical job J from an earlier write is still `:available`, so the insert collapses into J (`conflict?: true`) and no new job is written. Before T1 commits, a producer fetches J. J loads the triggers on its own connection and sees the pre-T1 rows. T1 then commits, and no job is left to index T1's change.

   This is exactly the hazard that D-20, and the comment at `enqueue.ex:87-89`, exist to prevent ("collapsing it into the running job would lose that update"). The window now spans the rest of the caller's transaction, not a single insert. When the call is made after the commit, the race cannot happen. Any job the check finds still `:available` reads committed data when it runs, and a job that already started is `:executing`, so it is not matched and a fresh job is inserted.

2. **Phantom conflicts while the caller's transaction is open.** With testing disabled, the Basic engine takes `pg_try_advisory_xact_lock` on the unique key (`basic.ex:533-541`). If the lock is held, it returns an unsaved job marked `conflict?: true`. Nested inside a caller's transaction, that lock is held until the caller commits or rolls back.

   Suppose a concurrent identical sync made after its own write committed arrives during that time. It gets `{:ok, %{conflict?: true}}` and inserts nothing. If the first transaction then rolls back, for example because a later `Multi` step fails, neither job exists and the second writer's update is never indexed.

The old guide text ("call after the write commits") gave the right instruction for the wrong reason. The fix kept the wrong analysis and changed the instruction.

**Fix:** go back to "call after the commit" in every mode, and give the correct reason. Update the example to match:

```elixir
def update_category(tenant, %Category{} = category, attrs) do
  opts = tenant_opts(tenant)

  with {:ok, category} <- category |> Category.changeset(attrs) |> Repo.update(opts),
       {:ok, _} <- Scrypath.sync_related(Category, category, fan_out: :products) do
    {:ok, category}
  end
end
```

Guide wording, for both guides:

> Call sync functions after your write commits. Scrypath collapses an identical pending job (`conflict?: true`). If you enqueue inside a transaction, the job you collapse into can run before your commit and read the old rows, and an open transaction holds Oban's unique lock so concurrent identical syncs can be dropped if you roll back.

Keep the WR-01 mechanics paragraph, which says nested calls insert in your transaction and return the bare error. Present it as what happens when you do nest, not as a recommended pattern. If transactional outbox semantics are wanted later, they need a non-unique insert path when `in_transaction?` is true. That is a design decision, not a docs fix.

## Warnings

### WR-06: Enqueue still accepts `nil`, float and boolean ids that the worker now cancels, so one bad id silently drops its whole chunk

**File:** `lib/scrypath/oban/payload.ex:67-72` (`serialize_scalar!/1`, used by `serialize_ids!/1` at 24-26); `lib/scrypath/oban/job_args.ex:113-117`

**Issue:** WR-02 narrowed `fetch_document_ids/1` to integers and binaries. The enqueue side still serializes and stores floats, booleans and `nil` without complaint.

`Identity.document_id/2` (`identity.ex:23-37`) returns `nil` for an unsaved struct, and a custom `search_document_id/1` can return anything scalar. For example, `Scrypath.sync_records(Post, posts)` where one struct has `id: nil` or `delete_record/3` on such a struct returns `{:ok, %{status: :accepted}}`. The chunk job holding that id then cancels with `{:invalid_job, {:invalid_arg, "document_ids"}}`, and the other up to 999 valid ids in that chunk are never synced. The caller was told the work was accepted.

The disposition says float and boolean ids are "now rejected", but they are rejected at the wrong end: silently, after acceptance. Meilisearch document ids must be integers or strings anyway, so nothing legitimate is lost by failing fast.

**Fix:** validate at enqueue with the same predicate as decode, so the caller gets the error inside its own call:

```elixir
# payload.ex
def serialize_ids!(document_ids) when is_list(document_ids) do
  Enum.map(document_ids, fn id ->
    case serialize_scalar!(id) do
      v when is_integer(v) or is_binary(v) -> v
      other ->
        raise ArgumentError,
              "Oban sync document ids must be integers or strings, got #{inspect(other)}"
    end
  end)
end
```

Better still, share one `valid_document_id?/1` between `Payload` and `JobArgs` so the two cannot drift again. Add an enqueue test with `[1, nil]`.

### WR-07: A string id that can't be cast to the schema's key type still raises in the loader and burns 8 retries (residual of WR-02)

**File:** `lib/scrypath/loader.ex:157-159`; `lib/scrypath/oban/job_args.ex:111-117`

**Issue:** The prior WR-02 named `"abc"` for an integer primary key as one of the inputs that crash. The fix checks only the element type. `"abc"` is a binary, so it passes decode. It then reaches `from(... in ^document_ids) |> repo.all()`, where Ecto raises `Ecto.Query.CastError`. The upsert and related workers crash and Oban retries all 8 attempts.

The same happens for a non-UUID string against a `:binary_id` key. The comment at `job_args.ex:111-112` ("Anything else would make the loader's query raise ... so reject it here") overstates what the check guarantees. FAN-03 says undecodable args end with a clear, non-retrying error.

**Fix:** in `Loader.fetch/3`, cast ids against the schema's `document_id` field type before querying:

```elixir
type = schema_module.__schema__(:type, id_field)
case Enum.reduce_while(document_ids, {:ok, []}, fn id, {:ok, acc} ->
       case Ecto.Type.cast(type, id) do
         {:ok, v} -> {:cont, {:ok, [v | acc]}}
         :error -> {:halt, :error}
       end
     end) do
  {:ok, cast} -> ...query with Enum.reverse(cast)...
  :error -> {:error, {:invalid_arg, "document_ids"}}
end
```

Map `{:error, {:invalid_arg, _}}` to `{:cancel, {:invalid_job, ...}}` in both workers. Alternatively, rescue `Ecto.Query.CastError` around the default query only. Adjust the `job_args.ex` comment either way.

## Info

### IN-06: Inline `sync_related/3` passes duplicate triggers to the resolver and counts them in the span, contrary to the guide

**File:** `lib/scrypath/sync.ex:96-108`; `guides/sync-modes-and-visibility.md:36`

**Issue:** The guide says "Resolvers, loaders and `search_records/2` get deduped input (set semantics)". Under `:oban` that holds: the related worker's resolver gets `Loader.load/3` output, which is deduped. The inline path calls the resolver with `List.wrap(records)` unchanged, and its `[:scrypath, :sync, :related, :resolve]` span start reports `length(records_list)`, duplicates included. The worker's span for the same input reports the deduped count.

This is outside the scope of the WR-05 fix, but it is the same inconsistency. It is harmless for typical `in`-query resolvers.

**Fix:** dedupe in `inline_resolve_and_sync/6` with the shared key:

```elixir
records_list =
  records
  |> List.wrap()
  |> Enum.uniq_by(&Chunks.id_key(Identity.document_id(schema_module, &1)))
```

Alternatively, narrow the guide sentence to say that inline passes the caller's structs as given (D-11).

---

_Reviewed: 2026-10-25T22:49:55Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
