---
phase: 179-bounded-id-lists-and-related-sync-parity
reviewed: 2026-10-25T22:04:57Z
depth: standard
files_reviewed: 22
files_reviewed_list:
  - lib/scrypath/chunks.ex
  - lib/scrypath/sync.ex
  - lib/scrypath/loader.ex
  - lib/scrypath/operations.ex
  - lib/scrypath/operations/result.ex
  - lib/scrypath/backfill.ex
  - lib/scrypath/reindex.ex
  - lib/scrypath.ex
  - lib/scrypath/oban.ex
  - lib/scrypath/oban/enqueue.ex
  - lib/scrypath/oban/job_args.ex
  - lib/scrypath/oban/upsert_worker.ex
  - lib/scrypath/oban/delete_worker.ex
  - lib/scrypath/sync/related_enqueue.ex
  - lib/scrypath/sync/related_worker.ex
  - test/support/oban_sqlite_repo.ex
  - test/support/oban_sqlite_migration.ex
  - test/support/fake_repo.ex
  - examples/scrypath_ecommerce/lib/scrypath_ecommerce/catalog/category.ex
  - examples/scrypath_ecommerce/lib/scrypath_ecommerce/catalog.ex
  - examples/phoenix_meilisearch/lib/scrypath_demo/blog.ex
  - examples/phoenix_meilisearch/lib/scrypath_demo/blog/author.ex
findings:
  critical: 1
  warning: 5
  info: 5
  total: 11
status: issues_found
---

# Phase 179: Code Review Report

**Reviewed:** 2026-10-25T22:04:57Z
**Depth:** standard
**Files Reviewed:** 22
**Status:** issues_found

## Summary

I reviewed the phase diff (`1d3399c1..HEAD`) for chunking (`Scrypath.Chunks` and its call sites in sync, loader, backfill, reindex and the workers), the multi-job Oban enqueue, the shared `JobArgs` decoder, and resolver parity in the related worker.

The chunk halt semantics are correct. `reduce_ok` and `each_ok` stop at the first `{:error, _}`. Inline mode waits on each chunk inside the reducer, and the combined result is built fresh when there are two or more chunks. Reindex now waits on every chunk task before cutover. The unique policy is now shared by all three job kinds.

There is one blocker. The module-name decoder that this phase moved into `JobArgs` resolves names segment by segment with `String.to_existing_atom/1`. In a VM that never parsed source that names those aliases, such as a `mix release`, the bare segment atoms (`:MyApp`, `:Post`) do not exist. Every job then cancels as `{:unknown_schema, _}` or `{:unknown_backend, _}`. I reproduced this in a fresh VM. The test suite cannot catch it, because test files parse those aliases.

For the related worker this is a regression from 0.3.17, which resolved the full name. The upsert and delete workers inherit the same pattern, which was latent there since 0.3.0.

The warnings are:

- the multi-chunk insert transaction poisons a caller's outer transaction
- job ids are not validated, so a bad id raises and retries instead of cancelling
- in-flight 0.3.17 related jobs from repo-less apps are cancelled on upgrade
- backfill reports only the last delete chunk's task
- telemetry start and stop `document_count` disagree after dedupe

String-sort ordering (`"10" < "9"`) changes which ids share a chunk, for example `[1, 10, 100, 1000, 1001, …]`. I found no correctness consequence. Loader `in` queries, missing-id computation (compared by `to_string`) and unique collapse are all order-independent once the set is fixed.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: `JobArgs.safe_module/1` cannot resolve module names in a release, so every Scrypath job cancels

**File:** `lib/scrypath/oban/job_args.ex:243-248` (used by `resolve_existing_module/3` at 230-239 for schema, backend, repo, and the related `opts` backend and repo)

**Issue:** `safe_module/1` splits `"Elixir.MyApp.Blog.Post"` on `"."` and calls `String.to_existing_atom/1` on each segment (`"MyApp"`, `"Blog"`, `"Post"`) before `Module.safe_concat/1`.

A loaded BEAM only adds its full module atom (`:"Elixir.MyApp.Blog.Post"`) to the atom table. The bare alias segments exist only if some source that names them was parsed in the running VM. That happens in tests and in `mix` runs that parse config, but not in a release.

Reproduced on Elixir 1.19.5 / OTP 28 with a compiled `Qzxwv.Plokm` beam loaded into a fresh VM:

```
JobArgs.safe_module style: {:error, "... not an already existing atom"}
safe_concat([name]): Qzxwv.Plokm
```

In production every upsert, delete and related job therefore returns `{:cancel, {:invalid_job, {:unknown_schema, name}}}`, or `:unknown_backend` (for example, `:Meilisearch` is not a standalone atom). The work is silently cancelled, not retried.

`RelatedWorker` in 0.3.17 used `String.to_existing_atom(name)` on the full name, so this phase introduced a regression for related jobs. The upsert and delete workers had the same latent bug since 0.3.0, and this phase centralised it. The tests pass only because test files parse those aliases, for example `Scrypath.Sync.RelatedWorkerTest.DummySchema` in `related_worker_test.exs:277`.

**Fix:** resolve the full atom, which exists once the module is loaded, and keep the exact-spelling check:

```elixir
defp safe_module("Elixir." <> _ = name) do
  {:ok, String.to_existing_atom(name)}
rescue
  ArgumentError -> :error
end

defp safe_module(_name), do: :error
```

`Module.safe_concat([name])` is equivalent. Add a regression test that runs `JobArgs.decode_*` in a separate `:peer` node or script where only the compiled beam is loaded. A test file can never prove this, because the file itself creates the atoms.

## Warnings

### WR-01: The multi-chunk enqueue transaction aborts the caller's outer transaction and ignores Oban's nested-transaction guidance

**File:** `lib/scrypath/oban/enqueue.ex:118-131`

**Issue:** With two or more chunks, `insert_chunks/2` opens `Oban.Repo.transaction/2` and calls `Oban.Repo.rollback/2` on the first failed insert. Callers commonly enqueue inside their own transaction. The ecommerce example calls `Scrypath.sync_related/3` inside `Multi.run` (`examples/scrypath_ecommerce/lib/scrypath_ecommerce/catalog.ex:68-69`).

Ecto flattens nested transactions, so the inner `rollback` marks the whole outer transaction as failed. Any further query by the caller raises, and the outer call returns `{:error, :rollback}` instead of letting the caller handle `{:error, changeset}`. Before this phase, a single failed insert returned `{:error, changeset}` and left the caller's transaction usable. The same caller now gets different failure behaviour depending on whether the id count is above 1000.

`Oban.Repo.transaction/3` (Oban 2.23 docs, `deps/oban/lib/oban/repo.ex:207-213`) also warns to pass `retry: false` when nested. Without it, a deadlock retry inside the caller's transaction masks the real error.

**Fix:** when `Oban.Repo.in_transaction?(conf)` is true, do not open or roll back a transaction. Insert sequentially with `Chunks.reduce_ok/2` and return the error; the caller's transaction already gives atomicity. Otherwise keep the transaction, and pass `retry: false` whenever nested:

```elixir
{:ok, conf} ->
  if Oban.Repo.in_transaction?(conf) do
    Chunks.reduce_ok(changesets, &insert_job(oban, &1))
  else
    Oban.Repo.transaction(conf, fn -> ... end)
  end
```

### WR-02: Job `document_ids` elements are not validated, so malformed ids raise and burn 8 retries instead of cancelling (FAN-03 gap)

**File:** `lib/scrypath/oban/job_args.ex:113-114`; consumed at `lib/scrypath/loader.ex:157-159`

**Issue:** `fetch_document_ids/1` accepts any list. An edited or corrupted job with entries that are not ids, such as `[{"a" => 1}]`, `[[1]]`, `nil`, or `"abc"` for an integer primary key, reaches `from(... in ^document_ids) |> repo.all()`. That raises `Ecto.Query.CastError`, so the upsert and related workers crash and Oban retries all 8 attempts.

The delete worker sends such values to the backend, which returns a 4xx `{:error, _}`, and that is also retried. This contradicts the phase goal: fail cleanly on bad job arguments with `{:cancel, {:invalid_job, tag}}`.

**Fix:** validate the elements in `fetch_document_ids/1`. Accept only binary, integer, float or boolean values, matching what `Payload.serialize_scalar!/1` can emit, apart from `nil`. Otherwise return `{:error, {:invalid_arg, "document_ids"}}`. Optionally also rescue `Ecto.Query.CastError` in the workers' load step and return `{:cancel, {:invalid_job, {:invalid_arg, "document_ids"}}}`.

### WR-03: In-flight 0.3.17 related jobs from apps without a repo or `search_records/2` are cancelled on upgrade

**File:** `lib/scrypath/sync/related_worker.ex:24-37`

**Issue:** 0.3.17 enqueued related jobs without requiring `:repo`, and its worker passed ids straight to the resolver. After upgrade, `run/3` always calls `Loader.load/3`. For a trigger schema with no `search_records/2` and no configured repo (`"repo" => nil` in the stored opts and no `:scrypath` default), this returns `{:error, :repo_required}`. The job is cancelled as `{:invalid_job, :repo_required}`, and those fan-outs are lost silently.

The legacy fixture test (`test/scrypath/sync/related_worker_test.exs:274-292`) passes only because `DummySchema` can load without a repo, so this path is untested. The upsert worker has a legacy fallback for the same situation; the related worker has none and no upgrade note.

**Fix:** at minimum, add an upgrade note: drain the `:scrypath` queue of `Scrypath.Sync.RelatedWorker` jobs, or configure `:repo` before deploying. Add a legacy-fixture test with a trigger schema that cannot load, asserting the documented outcome. Consider an `{:error, :repo_required}` that is retried, not cancelled, so an operator can fix the config and the job then succeeds.

### WR-04: Backfill keeps only the last delete chunk's task, so callers can't follow removals larger than 1000 ids

**File:** `lib/scrypath/backfill.ex:76-79`

**Issue:** Upserts report every chunk task in `tasks:`, but deletes report only `delete_task: task_of(List.last(delete))`. A page with more than 1000 omitted ids is deleted in several chunks, and every task but the last is dropped. The `Scrypath.backfill/2` docs (`lib/scrypath.ex:430-434`) tell callers that need removals applied to follow `delete_task`. That is now insufficient, for the same reason the phase added `tasks` for upserts (D-08: "a successful `task:` doesn't prove earlier tasks succeeded").

**Fix:** add `delete_tasks: delete |> Enum.map(&task_of/1) |> Enum.reject(&is_nil/1)`, keep `delete_task` as the last entry, and update the docs.

### WR-05: Telemetry start `document_count` counts duplicates but stop/result counts are deduped; ≤1000 results changed order

**File:** `lib/scrypath/sync.ex:26-27, 131-132, 157-167, 226-235`

**Issue:** The span start metadata uses `length(records)` or `length(document_ids)`, before dedupe. The chunked path dedupes through `Chunks.by_id` or `Chunks.ids`, so stop metadata and the result's `document_count` can be lower for the same span. For example, `sync_records(Post, [p1, p1])` starts at 2 and stops at 1.

The ≤1000 inline and manual result is also no longer "unchanged plus a one-element `tasks`" as D-08 promised. `document_ids` is now deduped and string-sorted, so `[2, 10]` becomes `[10, 2]`. Callers that zip `document_ids` with their input will misalign. Phase 180 telemetry consumers will see inconsistent counts.

**Fix:** compute `document_count` for span start from the deduped set, using `records |> Enum.uniq_by(...)` or the ids after `Identity.document_ids |> Enum.uniq`. Document in the 0.3.x CHANGELOG that `document_ids` in sync results is now deduped and has no ordering contract.

## Info

### IN-01: Dedupe runs on raw values before JSON serialization

**File:** `lib/scrypath/chunks.ex:17-22` and `lib/scrypath/oban/payload.ex` (`serialize_scalar!/1`)

**Issue:** `:a` and `"a"` both survive `Chunks.ids/1`, which dedupes raw values, and are then both serialized as `"a"`. The job carries a duplicate id and an inflated `document_count`. The same applies to `1` and `"1"` for Meilisearch, which treats them as the same document.

**Fix:** dedupe on the serialized form inside the Oban path, or normalise ids before chunking.

### IN-02: Example calls `sync_related` inside an open transaction against the new guide advice

**File:** `examples/scrypath_ecommerce/lib/scrypath_ecommerce/catalog.ex:68-69`

**Issue:** The rewritten guide says to call `sync_related/3` after the write commits. The flagship example still calls it inside `Multi.run`. With Oban on the same database this is actually safe, because the job is invisible until commit. The guide's stated reason ("the job can run on another connection before the commit") is inaccurate for same-repo Oban. The example also hits WR-01 when more than 1000 categories are passed.

**Fix:** either move the call after the transaction, or correct the guide's rationale (same-repo Oban inserts are transactional) and keep the example.

### IN-03: The resolver's id clause is kept as dead code in the ecommerce example

**File:** `examples/scrypath_ecommerce/lib/scrypath_ecommerce/catalog.ex:103-109`

**Issue:** Scrypath never passes ids now (D-11, D-13). The kept `[_id | _]` clause also skips the tenant filter that the struct clause applies, so a "direct caller" gets cross-tenant products. This contradicts the guide's "id clauses are now dead code and safe to remove".

**Fix:** remove the clause, or add the tenant scope to it.

### IN-04: Loader programming errors are retried instead of cancelled

**File:** `lib/scrypath/sync/related_worker.ex:34-35`, `lib/scrypath/oban/upsert_worker.ex:52-53`

**Issue:** `{:error, {:invalid_search_records, other}}`, where `search_records/2` returned something other than a list, is a deterministic app bug. It is retried 8 times.

**Fix:** map it to `{:cancel, {:invalid_job, {:invalid_search_records, ...}}}`, keeping counts and not values per Phase 178 D-05, or leave as is and document it.

### IN-05: The unique `:states` list omits `:executing`, which Oban 2.23 flags as uniqueness-breaking

**File:** `lib/scrypath/oban/enqueue.ex:89`

**Issue:** The exclusion is deliberate (D-20) and predates this phase, but it now applies to related jobs too. Oban 2.23's `Job.warn_unique/1` (`deps/oban/lib/oban/job.ex:840-870`) warns that missing incomplete states "may break uniqueness". This matters for engines that enforce uniqueness with an index, such as Pro's Smart engine. The warning only fires for worker-level `unique:` at compile time, so it is not visible here.

**Fix:** add a note that Pro/Smart-engine users may see unique-index conflicts, or verify the behaviour against the Pro engine.

---

_Reviewed: 2026-10-25T22:04:57Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
