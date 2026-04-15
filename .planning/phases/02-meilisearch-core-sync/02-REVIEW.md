---
phase: 02-meilisearch-core-sync
reviewed: 2026-04-15T23:59:00Z
depth: standard
files_reviewed: 14
files_reviewed_list:
  - lib/scrypath.ex
  - lib/scrypath/sync.ex
  - lib/scrypath/identity.ex
  - lib/scrypath/options.ex
  - lib/scrypath/config.ex
  - lib/scrypath/meilisearch.ex
  - lib/scrypath/meilisearch/client.ex
  - lib/scrypath/meilisearch/tasks.ex
  - mix.exs
  - test/scrypath/sync_test.exs
  - test/scrypath/identity_test.exs
  - test/scrypath/options_test.exs
  - test/scrypath/meilisearch_test.exs
  - test/scrypath/meilisearch/tasks_test.exs
findings:
  critical: 0
  warning: 2
  info: 0
  total: 2
status: issues_found
---

# Phase 02: Code Review Report

**Reviewed:** 2026-04-15T23:59:00Z
**Depth:** standard
**Files Reviewed:** 14
**Status:** issues_found

## Summary

Reviewed the Phase 02 Meilisearch sync implementation across the common sync surface, the concrete Meilisearch backend/client/tasks modules, and the phase-owned tests. The implementation is generally coherent and the current suite passes (`mix test` plus the focused phase test set), but there are two operational correctness gaps in the write path.

## Warnings

### WR-01: Inline sync can poll an invalid task id and still label the operation as completed

**File:** `lib/scrypath/meilisearch.ex:73-80`, `lib/scrypath/sync.ex:57-79`, `lib/scrypath/meilisearch/tasks.ex:42`
**Issue:** `Scrypath.Meilisearch.normalize_task/1` always builds a `%{task: ...}` map even when the backend response is missing `taskUid`/`uid`. `Scrypath.Sync.maybe_wait_for_task/2` treats any task map as pollable, so inline mode will call `Tasks.wait_for_task/2`, which in turn requests `/tasks/#{task.uid}` even when `task.uid` is `nil`. If the response shape changes or a partial body comes back from Meilisearch, callers get a confusing follow-up transport error from `/tasks/nil`, and `decorate_result/2` still hard-codes inline results to `status: :completed` whenever the wait path does not fail first.
**Fix:**
```elixir
defp normalize_task(response) do
  uid = response["taskUid"] || response[:taskUid] || response["uid"] || response[:uid]

  if is_nil(uid) do
    {:error, {:invalid_task_response, response}}
  else
    {:ok,
     %{
       uid: uid,
       status: response["status"] || response[:status],
       type: response["type"] || response[:type],
       index_uid: response["indexUid"] || response[:indexUid],
       raw: response
     }}
  end
end
```

Then have `upsert_documents/3` and `delete_documents/3` propagate that error, and add a test that a missing task id does not attempt polling.

### WR-02: Empty batch sync/delete calls are passed through without a defined contract

**File:** `lib/scrypath/sync.ex:15-19`, `lib/scrypath/sync.ex:36-38`
**Issue:** `sync_records/3` and `delete_documents/3` accept any list, including `[]`, and immediately dispatch it to the backend. In real operator flows, empty chunks are common after filtering, deduping, or import partitioning. Right now the behavior depends on backend internals: the recording backend makes it look harmless, while the Meilisearch client would still POST an empty payload. That leaves callers with an undefined operational contract and there is no test coverage for it.
**Fix:**
```elixir
def sync_records(_schema_module, [], opts) do
  config = Config.resolve!(opts)
  {:ok, %{document_ids: [], mode: config[:sync_mode], status: empty_batch_status(config)}}
end

def delete_documents(_schema_module, [], opts) do
  config = Config.resolve!(opts)
  {:ok, %{document_ids: [], mode: config[:sync_mode], status: empty_batch_status(config)}}
end
```

If the library should reject empty batches instead, raise `ArgumentError` consistently and add tests for both verbs so callers can rely on one explicit behavior.

---

_Reviewed: 2026-04-15T23:59:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
