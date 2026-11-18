---
phase: 180-oban-worker-telemetry
fixed_at: 2026-10-25T00:00:00Z
review_path: .planning/phases/180-oban-worker-telemetry/180-REVIEW.md
iteration: 1
findings_in_scope: 13
fixed: 12
skipped: 1
status: all_fixed
---

# Phase 180: Code Review Fix Report

**Source review:** `180-REVIEW.md`
**Iteration:** 1
**Scope:** all (critical + warning + info)

`status: all_fixed` means every in-scope finding is either fixed or skipped by design with a written rationale. IN-06 is the one skip: the effect it describes is what D-18 intended, so it is recorded as accepted.

**Summary:**
- Findings in scope: 13 (WR-01..WR-05, IN-01..IN-08)
- Fixed: 12
- Skipped: 1 (IN-06, accepted by design)

| Finding | Status | Commit | Notes |
|---------|--------|--------|-------|
| WR-01 | fixed | f4044779 | Worker spans tag `index` with `job.index`. A fixture backend that ignores `:index_name` pins it; the test fails on the old code. |
| WR-04 | fixed | a488287a | `upserted_count` counts distinct ids, as `Chunks.by_id/2` writes them. A duplicate-row `search_records/2` test fails on the old code (4 vs 2). |
| WR-02 | fixed (docs) | d177d945, eb58d9bc | Final-attempt recipe covers `:stop`, `:exception`, and Oban's `[:oban, :job, :exception]` at `state` `:discard`. The reviewer's `:exhausted` is internal only; telemetry reports `:discard`. |
| WR-03 | fixed (docs) | 2514305d | Bounded-value claim scoped to the worker spans. Unbounded keys are named. `schema` is no longer a recommended tag. |
| WR-05 | fixed (docs) | 5e091f48 | Decode/config failures emit no Scrypath event. Oban's `:cancelled` stop is the counter. `failed_work.observed` is per `failed_sync_work/2` call. |
| IN-01 | fixed (docs) | 4d208c1a | `cancel_reason` dropped from the delete row; `:cancel` documented as upsert-only. Contract test still passes. |
| IN-02 | fixed | 495fcbd0 | Guide says "distinct ids". The related job's resolve span now uses `Chunks.distinct_count/1`, like the inline path. Test added. |
| IN-03 | fixed | b02d0d75 | `Telemetry.job_start_metadata/5` replaces the two copies of `start_metadata/3`. |
| IN-04 | fixed | 7a2b9e0d | `== 16` is now `== @event_count - 1`. |
| IN-05 | fixed (docs) | b24fc8e5 | The guide states only the three worker rows are key-checked. Extending capture checks to 14 more spans is not small and D-17 scopes it out. |
| IN-06 | skipped (accepted) | — | Intended effect of D-18; see below. |
| IN-07 | fixed (docs) | 5c5a30e8 | Sync `:noop`-ratio and `verify_skipped` bullets restored in the SRE doc (bullets, not a table). |
| IN-08 | fixed | e92d425f | `TelemetryCapture` comment says the handler is global and for `async: false` modules only. |

## Fixed Issues

### WR-01: The worker span `index` tag is recomputed, not the index the job writes to

**Files modified:** `lib/scrypath/oban/upsert_worker.ex`, `lib/scrypath/oban/delete_worker.ex`, `test/support/oban_telemetry_scenarios.ex`, `test/scrypath/oban/worker_telemetry_test.exs`
**Commit:** f4044779

**Applied fix:** I confirmed the claim: `Scrypath.Meilisearch.Naming.index_name/2` rebuilds `"#{prefix}_#{schema}"` and ignores `:index_name`. The start metadata now passes `index: job.index` as an extra key. It merges last, so it overrides the backend-derived name. `missing_removed` reuses the start metadata, so it gets the same index. New fixture `RebuiltNameBackend` returns a fixed name that differs from the job's index. Two tests (delete span; upsert span plus `missing_removed`) assert the job's index. Both fail with the source change reverted.

### WR-04: `upserted_count` counts raw records

**Files modified:** `lib/scrypath/oban/upsert_worker.ex`, `test/support/oban_telemetry_scenarios.ex`, `test/scrypath/oban/worker_telemetry_test.exs`
**Commit:** a488287a

**Applied fix:** A new `upserted_count/1` counts `Chunks.distinct_count/1` over the document ids. It uses the same `id_key/1` dedupe as `Chunks.by_id/2`, which the write uses. It applies to both the loaded and the legacy snapshot path. New fixture `DuplicateLoaderPost` returns every record twice. The test asserts two documents are sent and `upserted_count == 2`; the old code reports 4.

### WR-02: Final-attempt alert recipe misses raises and kills

**Files modified:** `guides/telemetry.md`, `docs/search-backend-sre.md`
**Commits:** d177d945, eb58d9bc

**Applied fix:** I checked the Oban states in `deps/oban` 2.23.0. `Executor.normalize_state/1` turns a last-attempt `:failure` into `:exhausted`. `Executor.emit_event/1` then reports it as `[:oban, :job, :exception]` with `state: :discard`. Raises and `{:error, _}` both arrive as `:failure` (or `:discard` on the last attempt). In `Producer.handle_info({:DOWN, ...})`, timeouts and crashes become `:failure`, so they follow the same rule. A `:shutdown` exit becomes `[:oban, :job, :stop]` with `state: :cancelled`. The guide and SRE doc now say:
- `:failure` while attempts remain, `:discard` on the last attempt
- the Scrypath `:exception` carries no `outcome`
- the final-attempt alert matches `:stop` (`attempt == max_attempts and outcome != :ok`), `:exception` (`attempt == max_attempts`), and Oban's `:exception` at `state: :discard` for the Scrypath workers, which also covers timeouts and crashed processes

### WR-03: Blanket cardinality claim

**Files modified:** `guides/telemetry.md`, `docs/search-backend-sre.md`
**Commit:** 2514305d

**Applied fix:** The bounded-values sentence now covers only the worker spans and `missing_removed`. A "never tag on" list names `path`, `task_uid`, `filters`, `families`, `source_index`/`target_index`, and exception `reason`/`stacktrace`. `schema` was dropped from the recommended tags, citing the `Scrypath.Operator.FailedWork` moduledoc. "Per schema" charting advice is now "per index" in both docs.

### WR-05: Invalid jobs do not automatically appear as `failed_work.observed`

**Files modified:** `guides/telemetry.md`
**Commit:** 5e091f48

**Applied fix:** I confirmed that `FailedWork.list/3` emits per row when `failed_sync_work/2` runs, and that queue rows only exist if the configured inspector returns them. The guide now says decode and config failures emit no Scrypath event, and that Oban's `[:oban, :job, :stop]` with `state: :cancelled` and the Scrypath worker name is the countable signal. It also warns that `failed_work.observed` is not a counter. The event table's "When" text was corrected to match.

This corrects the D-02 sentence that described these jobs as rows "in `failed_work.observed`". The decision itself (no span before decode and config succeed) is unchanged.

### IN-01: Unreachable `cancel_reason` on the delete row

**Files modified:** `guides/telemetry.md`, `docs/search-backend-sre.md`
**Commit:** 4d208c1a

**Applied fix:** I confirmed that `IndexingAck.await/3` is specced `:ok | {:error, term()}` and that `Chunks.each_ok/2` never returns a cancel. `cancel_reason (optional)` was removed from the delete row, keeping the table format. The prose and dashboard advice now say `:cancel` is upsert-only, because delete jobs cancel before the span. The telemetry contract test still passes.

### IN-02: `document_count` meaning

**Files modified:** `guides/telemetry.md`, `lib/scrypath/sync/related_worker.ex`, `test/scrypath/sync/related_worker_test.exs`
**Commit:** 495fcbd0

**Applied fix:** The guide now says "number of distinct ids". The related job's resolve span start count now uses `Chunks.distinct_count/1`. That matches the inline path, which already dedupes triggers with `dedupe_triggers/2`. A test performs a related job with `[1, 1, 2]` and asserts the start `document_count` is 2; it fails on the old code.

### IN-03: Duplicated `start_metadata/3`

**Files modified:** `lib/scrypath/telemetry.ex`, `lib/scrypath/oban/upsert_worker.ex`, `lib/scrypath/oban/delete_worker.ex`
**Commit:** b02d0d75

**Applied fix:** Added `Telemetry.job_start_metadata(schema, config, oban_job, document_ids, index)` next to `job_stop_metadata/1`. It uses plain field access rather than an `%Oban.Job{}` pattern, because `Scrypath.Telemetry` compiles without Oban. Both workers call it. Behaviour is unchanged and all worker telemetry tests pass.

### IN-04: Magic `16`

**Files modified:** `test/scrypath/telemetry_contract_test.exs`
**Commit:** 7a2b9e0d

**Applied fix:** `== @event_count - 1`.

### IN-05: The guide overstated what the drift contract enforces

**Files modified:** `guides/telemetry.md`
**Commit:** b24fc8e5

**Applied fix:** I took the reviewer's first option. The guide intro now says names are checked in both directions for every row, but metadata keys are checked only for the three Oban worker rows. Capture-based key checks for the other 14 events would need new scenarios for search, hydration, Meilisearch requests, settings and reindex. That is not a small change, and D-17 records it as a stated gap.

### IN-07: SRE doc lost alert-fatigue guidance

**Files modified:** `docs/search-backend-sre.md`
**Commit:** 5c5a30e8

**Applied fix:** I restored two bullets:
- the sync `status: :noop` share is noisy if alerted per call
- `reindex.verify_skipped` spikes may be intentional deploys

They are bullets, not table rows, so the "single catalog" test still passes. The `failed_work.observed` bullet also now says it fires per `failed_sync_work/2` call, consistent with WR-05.

### IN-08: `TelemetryCapture` scope

**Files modified:** `test/support/telemetry_capture.ex`
**Commit:** e92d425f

**Applied fix:** The comment now says the handler is global, forwards events from every process, and must be used only in `async: false` modules. Both current users are `async: false`.

## Skipped Issues

### IN-06: Dropping the 4xx body removes text the failed-work classifier used to see

**File:** `lib/scrypath/sync/related_worker.ex:81-82`
**Reason:** Accepted as the intended effect of D-18. That decision stops persisting backend bodies, which can echo document content, in Oban's `errors` column. 401/403/408/429 cancels still classify as `:transport` through the status regex. Other related-job 4xx cancels now classify as `:unknown`, which is low impact: the reviewer notes most Meilisearch rejection codes are 5xx and are retried, not cancelled. A pinning test was not cheap. It would need a related-worker queue row through `failed_sync_work/2`, whose row builder targets upsert/delete args. Carrying an allowlisted backend error code atom is a possible later change; it is not part of this phase.
**Original issue:** Related-job 4xx cancels whose body held a `backend_rejection_signal?` substring now classify as `:unknown`.

## Verification

All gates ran in the main checkout `/Users/jon/projects/scrypath` on branch `planning/v1.44-new-milestone`; no worktree was used.

- `mix test --exclude integration`: 5 properties, 1000 tests, 0 failures (27 excluded)
- `mix test --only docs_contract`: 74 tests, 0 failures
- `MIX_ENV=test mix compile --warnings-as-errors`: clean
- `mix format --check-formatted`: clean
- `mix credo --strict`: no issues
- `mix docs --warnings-as-errors`: clean
- `deps/scrypath` was not created.

---

_Fixed: 2026-10-25_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
