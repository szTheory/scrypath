---
phase: 180-oban-worker-telemetry
reviewed: 2026-10-25T00:00:00Z
depth: standard
files_reviewed: 19
files_reviewed_list:
  - lib/scrypath/telemetry.ex
  - lib/scrypath/oban/delete_worker.ex
  - lib/scrypath/oban/upsert_worker.ex
  - lib/scrypath/sync/related_worker.ex
  - mix.exs
  - guides/telemetry.md
  - guides/related-data-and-reindexing.md
  - guides/per-query-tuning-pipeline.md
  - docs/search-backend-sre.md
  - ARCHITECTURE.md
  - test/support/telemetry_capture.ex
  - test/support/oban_telemetry_scenarios.ex
  - test/support/telemetry_contract.ex
  - test/scrypath/oban/worker_telemetry_test.exs
  - test/scrypath/telemetry_contract_test.exs
  - test/scrypath/telemetry_test.exs
  - test/scrypath/sync/related_worker_test.exs
  - test/scrypath/docs_contract_test.exs
  - test/release/package_metadata_test.exs
findings:
  critical: 0
  warning: 5
  info: 8
  total: 13
status: issues_found
---

# Phase 180: Code Review Report

**Reviewed:** 2026-10-25
**Depth:** standard
**Files Reviewed:** 19
**Status:** issues_found

## Summary

I reviewed the diff `1e47fb0f..HEAD` for the Oban worker spans, the `missing_removed` event, `job_stop_metadata/1`, the related-worker 4xx cancel shape, the new telemetry guide, and the guide-vs-code drift contract. The scoped tests pass (`worker_telemetry_test`, `telemetry_contract_test`, `telemetry_test`, `related_worker_test`: 81 tests, 0 failures).

The span wiring is sound. The span opens only after decode and config succeed. `document_count` is never overwritten on stop. `missing_removed` fires only after every delete chunk succeeds. Cancel tags are reduced to their atom head. I found no blockers.

The real problems are these:
- The `index` tag on the worker spans is recomputed instead of taken from the index the job actually writes to.
- `upserted_count` is not deduplicated, unlike the other counts.
- Several operator-facing guide statements are wrong or incomplete: the final-attempt alert recipe, the blanket cardinality claim, and the claim that failed-work rows appear automatically. Operators following them would build wrong dashboards or alerts.

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: The worker span `index` tag is recomputed, not the index the job writes to

**File:** `lib/scrypath/oban/upsert_worker.ex:20-21,35-41`, `lib/scrypath/oban/delete_worker.ex:17-18,31-37` (via `lib/scrypath/telemetry.ex:24`)
**Issue:** Both workers set `config[:index_name] = job.index`, and the Meilisearch write path uses that value (`lib/scrypath/meilisearch/operations.ex:15,39`). The span metadata comes from `Telemetry.common_metadata/3`, which calls `backend.index_name(schema, config)`. For the real backend that is `Scrypath.Meilisearch.Naming.index_name/2` (`lib/scrypath/meilisearch/naming.ex:5-14`), which ignores `:index_name` and rebuilds `"#{prefix}_#{schema}"` from the current prefix config and schema metadata. The two values diverge whenever the prefix differs between enqueue and run. A deploy that changes the schema `index_prefix` or app-env config while jobs are queued is enough. That deploy-boundary case is exactly what these workers are written to survive. In that case the span is tagged with an index the job never touched, and per-index dashboards misattribute writes. The test fixtures hide this: every test backend's `index_name/2` returns `Keyword.get(config, :index_name, ...)` (`test/support/oban_telemetry_scenarios.ex:27,57,81,113`), which the real backend does not.
**Fix:** Tag with the index the job writes to, and add a test that uses a backend whose `index_name/2` ignores `:index_name`:
```elixir
defp start_metadata(job, config, %Oban.Job{} = oban_job) do
  job.schema
  |> Telemetry.common_metadata(config,
    sync_mode: :oban,
    attempt: oban_job.attempt,
    max_attempts: oban_job.max_attempts,
    document_count: Chunks.distinct_count(job.document_ids)
  )
  |> Map.put(:index, job.index)
end
```

### WR-02: The final-attempt alert recipe misses jobs that raise or are killed on their last attempt

**File:** `guides/telemetry.md:48,89`, `docs/search-backend-sre.md:29`
**Issue:** The guide tells operators to alert on final-attempt failures with `attempt == max_attempts` and `outcome != :ok` on the worker span's `:stop`. When the backend raises (D-07; tested in `worker_telemetry_test.exs:130,264`), the span emits `:exception` with no `:stop` and no `outcome`, so a last-attempt crash never matches the alert. A job killed by an Oban timeout or a node shutdown emits neither event. Both lose the index change, and both are invisible to the documented alert. Line 47 also says `{:error, _}` produces Oban `state: :failure`. On the final attempt Oban normalizes that to `:exhausted` (`deps/oban/lib/oban/queue/executor.ex:184-187`), so an operator joining on `:failure` misses exactly the jobs this alert targets.
**Fix:** Change the recipe to: "alert on `[:scrypath, :oban, *, :stop]` with `attempt == max_attempts and outcome != :ok`, **and** on `[:scrypath, :oban, *, :exception]` with `attempt == max_attempts`; for jobs that never report (timeouts, kills), use Oban's `[:oban, :job, :exception]` with `state: :exhausted`." Make the same edit in the SRE doc bullet, and mention `:exhausted` next to `:failure` on line 47.

### WR-03: The cardinality section says every metadata value is bounded, which is false for documented keys

**File:** `guides/telemetry.md:80`
**Issue:** The section says "Metadata values are atoms, integers, modules, or the bounded index string." The same catalog documents keys that break this:
- `[:scrypath, :meilisearch, :request]` `path` embeds task uids and index names (`/tasks/12345`, `/indexes/<name>/...`; `lib/scrypath/meilisearch/client.ex:150-154`).
- `filters` is a keyword list (`client.ex:87`).
- `[:scrypath, :settings, :hot_apply]` `families` is a list (`lib/scrypath/meilisearch/settings.ex:288`).
- `failed_work.observed` `schema` is called unsafe for metric labels in `Scrypath.Operator.FailedWork`'s own moduledoc (`lib/scrypath/operator/failed_work.ex:38-41`), while this guide recommends tagging on `schema`.

The guide calls itself a public observability contract, so this blanket statement is a false promise that invites tagging on `path` or `filters`.
**Fix:** Scope the sentence to the worker spans ("On the Oban worker spans, metadata values are…"). List the known unbounded keys (`path`, `filters`, `families`, exception `reason`/`stacktrace`) under "never tag on". Reconcile the `schema` guidance with the `FailedWork` moduledoc.

### WR-04: `upserted_count` counts raw records, while `document_count` and `missing_count` are deduplicated

**File:** `lib/scrypath/oban/upsert_worker.ex:61,83`
**Issue:** `upserted_count: length(documents)` counts every record `Loader.load/3` returned. With a custom `search_records/2` that is any list the app returns. A join without `distinct` yields duplicate rows, and the loader does not drop records whose id was not requested (`lib/scrypath/loader.ex:150-156`). The write dedupes through `Chunks.by_id/2` (`lib/scrypath/chunks.ex:26-31`), so the "plan" actually sent is smaller than the reported count. `document_count` and `missing_count` both use `Chunks.distinct_count/1`, so `upserted_count + missing_count` can exceed `document_count`. Dashboards that compare them will show phantom writes.
**Fix:** Count what the write sends:
```elixir
upserted_count: documents |> Enum.map(& &1.id) |> Chunks.distinct_count(),
```
Do the same on the legacy path. Add a test with a `search_records/2` that returns a duplicate record.

### WR-05: The guide says invalid jobs automatically appear as `failed_work.observed` rows

**File:** `guides/telemetry.md:46`
**Issue:** "A job whose args fail to decode… shows up only as `[:oban, :job, :stop]` with `state` `:cancelled`, and as a row in `[:scrypath, :operator, :failed_work, :observed]`." That event is not emitted when the job is cancelled. It fires once per row each time something calls `Scrypath.failed_sync_work/2` (`lib/scrypath/operator/failed_work.ex:23-31`): an operator page load, a mix task, and so on. An operator who counts these events to track decode failures gets nothing when nobody queries, and repeated counts when someone does. Undecodable jobs are therefore effectively invisible to Scrypath telemetry, and the guide hides that.
**Fix:** Change the line to say decode/config failures emit **no** Scrypath event. Explain that they can be listed on demand through `Scrypath.failed_sync_work/2` (which emits `failed_work.observed` per row per call, so it must not be used as a counter). Point to Oban's `[:oban, :job, :stop]` with `state: :cancelled` and `worker` in `Scrypath.Oban.*` as the countable signal.

## Info

### IN-01: The delete row documents a `cancel_reason` the delete span can never emit

**File:** `guides/telemetry.md:35`, `lib/scrypath/oban/delete_worker.ex:21-24`
**Issue:** Inside the delete span, `write/4` returns only `:ok` or `{:error, _}`, because `Chunks.each_ok/2` and `IndexingAck.await/3` never produce `{:cancel, _}`. Every delete cancel happens before the span. The `cancel_reason (optional)` key on the delete row, and the `:cancel` outcome guidance applied to both spans (line 88), are unreachable for deletes.
**Fix:** Drop `cancel_reason` from the delete row, or note that delete jobs only cancel before the span.

### IN-02: `document_count` is described as "the number of ids in the job args" but is a distinct count; related resolve is not

**File:** `guides/telemetry.md:42`, `lib/scrypath/sync/related_worker.ex:52`
**Issue:** The worker spans use `Chunks.distinct_count/1`, which the tests at `worker_telemetry_test.exs:111` confirm. `[:scrypath, :sync, :related, :resolve]` still uses `length(job.document_ids)`. D-05 aims for one handler shape across these spans, but the same key means different things.
**Fix:** Say "number of distinct ids". Optionally switch related resolve to `Chunks.distinct_count/1`.

### IN-03: `start_metadata/3` is duplicated verbatim in both workers

**File:** `lib/scrypath/oban/upsert_worker.ex:35-42`, `lib/scrypath/oban/delete_worker.ex:31-38`
**Issue:** The two copies must stay in lockstep, and the WR-01 fix has to land in both.
**Fix:** Move a `Telemetry.job_start_metadata(schema, config, oban_job, document_ids, index)` next to `job_stop_metadata/1`.

### IN-04: Magic `16` in the contract test duplicates `@event_count`

**File:** `test/scrypath/telemetry_contract_test.exs:146`
**Issue:** `== 16` hard-codes `@event_count - 1`. Adding an event means editing two numbers, and the comment on line 12 says to change only one.
**Fix:** `assert length(...) == @event_count - 1`.

### IN-05: The drift contract key-checks only the three worker rows

**File:** `test/scrypath/telemetry_contract_test.exs:288-307`
**Issue:** The guide says it lists "the metadata keys each one documents" for all 17 events, but 14 rows are only name-checked. Stop-only keys produced by the generic `Telemetry.stop_metadata/2` (`result_kind`, `record_count`, `hit_count`, `missing_count`) can appear on rows that don't list them, and nothing would catch the drift. This is a known scope choice, but the guide's wording overstates what is enforced.
**Fix:** Say in the guide that the worker rows are strictly enforced, or add capture-based key checks for the other spans later.

### IN-06: Dropping the 4xx body removes text the failed-work classifier used to see

**File:** `lib/scrypath/sync/related_worker.ex:81-82`, `lib/scrypath/operator/failed_work/translation.ex:228-262`
**Issue:** The queue-job classifier reads the Oban error text. The status code still matches the transport regex (401/403/408/429). Any `backend_rejection_signal?` substring that used to come from a 4xx body (Meilisearch error codes) no longer reaches it, so such related-job cancels now classify as `:unknown`. The impact is low because most of those codes are 5xx, which are retried rather than cancelled. No test covers how a related-worker 4xx cancel classifies.
**Fix:** If classification matters, carry a bounded backend error code atom, e.g. `{:cancel, {:http_error, status, code}}` with `code` taken from Meilisearch's `"code"` field through an allowlist. Or add a translation test that pins the current classification.

### IN-07: The SRE doc rewrite dropped operational guidance the new guide doesn't carry

**File:** `docs/search-backend-sre.md:23-31`
**Issue:** The old table said the `[:scrypath, :sync, :upsert|:delete]` `:noop` ratio is noisy if alerted per call, and that `reindex.verify_skipped` spikes may be intentional deploys. Neither the new bullets nor `guides/telemetry.md` keep this alert-fatigue advice.
**Fix:** Restore those two bullets in the SRE doc.

### IN-08: `TelemetryCapture` is not process-scoped, so it is safe only in `async: false` modules

**File:** `test/support/telemetry_capture.ex:19-38`
**Issue:** The handler forwards every matching event from every process. Both current users are `async: false`, which is correct. The moduledoc says "for the current test process", which invites someone to use it from an async test, where events from concurrent tests would leak in and cause flakes.
**Fix:** Reword the comment to "captures matching events from all processes; use only in `async: false` tests". Alternatively, filter on a `$callers`/pid allowlist.

---

_Reviewed: 2026-10-25_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
