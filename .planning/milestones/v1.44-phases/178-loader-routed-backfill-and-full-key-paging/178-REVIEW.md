---
phase: 178-loader-routed-backfill-and-full-key-paging
reviewed: 2026-10-25T00:00:00Z
depth: standard
files_reviewed: 32
files_reviewed_list:
  - .github/workflows/ci.yml
  - CONTRIBUTING.md
  - README.md
  - compose.yaml
  - guides/related-data-and-reindexing.md
  - guides/sync-modes-and-visibility.md
  - lib/mix/tasks/verify.all.ex
  - lib/mix/tasks/verify.phase5.ex
  - lib/mix/tasks/verify.postgres.ex
  - lib/mix/tasks/verify/capability.ex
  - lib/scrypath.ex
  - lib/scrypath/backfill.ex
  - lib/scrypath/loader.ex
  - lib/scrypath/options.ex
  - lib/scrypath/reindex.ex
  - mix.exs
  - mix.lock
  - test/mix/tasks/verify_capability_test.exs
  - test/mix/tasks/verify_postgres_test.exs
  - test/mix/tasks/workflow_wiring_test.exs
  - test/scrypath/backfill_contract_docs_test.exs
  - test/scrypath/backfill_test.exs
  - test/scrypath/loader_backfill_postgres_test.exs
  - test/scrypath/loader_backfill_sqlite_test.exs
  - test/scrypath/loader_test.exs
  - test/scrypath/options_test.exs
  - test/scrypath/reindex_test.exs
  - test/support/loader_backfill_cases.ex
  - test/support/loader_backfill_fixtures.ex
  - test/support/postgres_repo.ex
  - test/support/sqlite_sandbox_repo.ex
  - test/test_helper.exs
findings:
  critical: 0
  warning: 3
  info: 6
  total: 9
status: issues_found
---

# Phase 178: Code Review Report

**Reviewed:** 2026-10-25T00:00:00Z
**Depth:** standard
**Files Reviewed:** 32
**Status:** issues_found

## Summary

I reviewed the diff `93502339..HEAD` for the loader-routed backfill, full-key keyset paging, the reindex primary-key fix, and the new real-Postgres verification lane.

The core paging logic holds up when traced by hand. The composite predicate `c1 >= v1 AND (c1 > v1 OR (c1 = v1 AND ...))` is correct. The cursor comes from the scoped rows and not from the loader output, so batches where every row is omitted still advance. Duplicate rows from a fan-out join sit next to each other under a full-key ORDER BY, so dedupe never splits one key across two pages. The reindex change to `create_index(schema, Metadata.document_id(schema), ...)` is a real fix: `Meilisearch.Client.upsert_documents/3` serializes documents under `document_id_field`, so the old first-Ecto-pk value was wrong for any schema whose `document_id` differs from its first key column. The fresh-target assumption is safe because a pre-existing `__reindex` index makes the create task fail, and `wait_for_task` turns that into an error.

I found no blockers. The main concerns:
- The `:query` sanitizer misses `distinct` (and other clauses that change ordering). On Postgres this can skip rows silently.
- The internal `_scrypath_fresh_target` flag can be set through the public `Scrypath.backfill/2` API, which turns off live-index deletes.
- Existing `search_records/2` adopters get a behavior change that the upgrade notes don't mention: live backfill now issues deletes.

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: `:query` with `distinct` (or combinations/group_by) breaks keyset paging; on Postgres rows are skipped silently

**File:** `lib/scrypath/backfill.ex:142-152` (and docs at `guides/related-data-and-reindexing.md:410`, `lib/scrypath.ex` "visited exactly once")
**Issue:** `base_query/3` strips `order_by`, `limit`, `offset`, `select` and `preload`, but it keeps `distinct`, `group_by`, `having`, `combinations` (union/intersect/except) and `windows`. The Postgres adapter puts `DISTINCT ON` expressions in front of the ORDER BY. A caller query such as `from p in Post, distinct: p.category_id` therefore runs as `ORDER BY category_id, id`. The cursor still comes from the last row's primary key, so the next page's `id > cursor` predicate drops every row in later categories whose id is below that cursor. Those rows are never indexed and no error is raised. This contradicts the new `@doc` promise that "every row in scope is visited exactly once". With `union`, the keyset `where` applies only to the first branch while the ORDER BY/LIMIT apply to the combined result, so paging can regress or stop making progress. The guide says only `where`/`join` apply but says nothing about these clauses.
**Fix:** Reject the clauses that change ordering or row identity instead of passing them through:
```elixir
defp base_query(config, schema_module, cols) do
  query = Ecto.Queryable.to_query(config[:query] || schema_module)

  if query.distinct || query.group_bys != [] || query.havings != [] ||
       query.combinations != [] || query.windows != [] do
    raise ArgumentError,
          "backfill :query may only scope rows with where/join; " <>
            "distinct, group_by, having, windows and set operations are not supported " <>
            "(use a where/exists subquery instead)"
  end

  query
  |> exclude(:order_by)
  # ...
end
```
Alternatively, `exclude(:distinct)` explicitly (fan-out dedupe already covers `distinct: true`). Either way, list the behavior in the related-data guide and add a Postgres case for `distinct: [asc: field]`.

### WR-02: The internal `_scrypath_fresh_target` flag is accepted from public `Scrypath.backfill/2` and turns off live-index deletes

**File:** `lib/scrypath/options.ex:299-303`, `lib/scrypath/backfill.ex:38`, `lib/scrypath.ex:433-435`
**Issue:** The flag lives in the public backfill NimbleOptions schema (`doc: false` only hides it from docs). Any caller that passes it to `Scrypath.backfill/2`, including code that forwards a user-assembled keyword list, makes a live-index backfill skip deleting the ids that `search_records/2` omits. Those documents stay searchable even though the loader said they should not be. The result then carries `omitted` and `removed: 0`, which looks like a successful prune. `test/scrypath/backfill_test.exs` ("a fresh-target backfill counts omitted ids...") relies on this public path, which makes the leak part of the tested surface. The docs-contract test only checks that the name is absent from `@doc`, not that the public API rejects it.
**Fix:** Keep the flag off the public option surface. Have `Scrypath.backfill/2` drop or reject it, and let `Reindex` call a private entry point:
```elixir
# lib/scrypath.ex
def backfill(schema_module, opts \\ []) do
  if Keyword.has_key?(opts, :_scrypath_fresh_target),
    do: raise(ArgumentError, "unknown option :_scrypath_fresh_target")

  Scrypath.Backfill.run(schema_module, opts)
end
```
Alternatively, add `Scrypath.Backfill.run(schema, opts, fresh_target?: true)` as a separate arity and remove the key from `Options`. Update the backfill unit test to call the internal entry point.

### WR-03: Behavior change for existing `search_records/2` schemas is missing from the upgrade notes

**File:** `guides/sync-modes-and-visibility.md:112-118`, `lib/scrypath/backfill.ex:63-67`
**Issue:** Before this phase, `Scrypath.backfill/2` projected the scoped rows directly and never deleted anything. Now, for any schema that defines `search_records/2`, every live backfill (1) re-loads each batch through the adopter's loader and (2) issues `delete_documents` for every visited id the loader does not return. An adopter whose `search_records/2` depends on context that backfill does not supply (backfill passes only `%{repo: repo}`), or that filters harder than intended, will see documents removed from the live index on the next backfill. That is a data-visibility change on an operator command. The new text sits next to the existing "Upgrading from 0.3.15 or earlier" section, but the change is not called out as an upgrade note, and the commits are typed `fix(...)`, so release-please will not flag it.
**Fix:** Add an "Upgrading" note to the sync-modes guide and the CHANGELOG entry: "Backfill now routes batches through `search_records/2` and deletes the visited ids it omits; check your loader before you run a live backfill, or run `cutover?: false` reindex first to inspect `omitted`." Give the squash PR title a `feat!`/BREAKING-style marker, or add an explicit changelog line.

## Info

### IN-01: Docs conflate `preload:` and `search_records/2`; preload is not applied on the custom-loader path

**File:** `guides/related-data-and-reindexing.md:399`, `lib/scrypath.ex:380`, `guides/sync-modes-and-visibility.md:112`
**Issue:** "each batch is loaded with the schema's `preload:` associations, and a schema's `search_records/2` decides..." reads as if both apply together. In `Loader.prepare_records/3` (and `fetch/3`), a schema with `search_records/2` never gets `Metadata.preload/1` applied; the loader must preload on its own.
**Fix:** Write it as "either the schema's `preload:` is applied, or, when `search_records/2` is defined, that function returns fully loaded records".

### IN-02: Misleading `force: true` rationale in the loader

**File:** `lib/scrypath/loader.ex:152-155`
**Issue:** The comment says rows may "arrive with an association already loaded (for example from a caller query)". However, `Backfill.base_query/3` runs `exclude(:preload)`, which clears both preloads and join-preload assocs, and the Oban path loads fresh rows. Neither path can deliver pre-loaded associations, so `force: true` does nothing and the comment points maintainers at a scenario that cannot happen.
**Fix:** Either drop `force: true`, or reword the comment as defensive ("reload even if a future caller passes pre-loaded rows").

### IN-03: Partial failure gives no progress information now that each batch has two writes

**File:** `lib/scrypath/backfill.ex:63-67`
**Issue:** If `write(:delete, ...)` fails after `write(:upsert, ...)` succeeded, or any later batch fails, `run/2` returns a bare `{:error, reason}`. The batches already written and the upsert just accepted are not reported, so an operator cannot tell where to resume or whether the index is half-pruned. Errors already lost progress before this phase, but the second write per batch makes it worse.
**Fix:** Wrap the error with progress, for example `{:error, %{reason: reason, completed_batches: Enum.reverse(state.acc), last_primary_key: ...}}`, or at least emit telemetry per batch.

### IN-04: Nullable composite-key columns on SQLite are only partly guarded

**File:** `lib/scrypath/backfill.ex:172-185`, `196-203`
**Issue:** SQLite allows NULL in non-`INTEGER PRIMARY KEY` composite key columns. `cursor_values/2` raises only when the *last* row of a batch has a nil key. Rows with NULL key columns in the middle of the first page are indexed, and the same rows on later pages are dropped silently because `NULL > x` evaluates to NULL. Postgres forbids this, so the risk is limited to SQLite adopters.
**Fix:** Add `not is_nil(field(r, ^col))` for every key column (as `exclude_nil_document_ids/3` already does for keyless schemas), or document that key columns must be NOT NULL.

### IN-05: Keyless schemas with non-unique document ids drop duplicates across page boundaries

**File:** `lib/scrypath/backfill.ex:156-170`
**Issue:** For `@primary_key false` schemas, paging uses the `document_id` column, which the database does not require to be unique. A run of equal ids that spans a page boundary is cut off by the strict `>` keyset, and `dedupe_rows/2` keeps whichever duplicate the database returns first. As a result, which row's content wins is nondeterministic.
**Fix:** Document that a keyless schema's `document_id` column must be unique, or add a secondary order (for example `ctid`/`rowid`) where the adapter allows it.

### IN-06: Composite-key fixtures use `"org:seq"` ids that Meilisearch rejects

**File:** `test/support/loader_backfill_fixtures.ex:133-136` (also Device, around line 155)
**Issue:** Meilisearch document ids allow only `[a-zA-Z0-9_-]`. The fixtures' `search_document_id/1` returns `"1:7"`, which only works because every case uses the recording backend or the stub. The composite-key reindex proof therefore never shows that a composite schema can actually be indexed, and the fixtures model a pattern adopters might copy.
**Fix:** Use `"#{org_id}-#{seq}"` in the fixtures. Optionally add a note in the related-data guide on choosing Meilisearch-safe composite document ids.

---

_Reviewed: 2026-10-25T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
