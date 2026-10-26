# Phase 179: Bounded id lists and related-sync parity - Context

**Gathered:** 2026-10-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Large id sets never produce unbounded record loads, backend calls or Oban job args (PAGE-03). `sync_related` resolvers get loaded records in every sync mode (FAN-01). Related enqueue dedupes with the main enqueue `unique:` policy (FAN-02). Related, upsert and delete jobs with undecodable args end with a clear, non-retrying error (FAN-03).

Library-only: `lib/`, tests, guides, CHANGELOG. No `scrypath_ops`, no UI, no new required CI job, no new telemetry events (Phase 180 owns those).

</domain>

<decisions>
## Implementation Decisions

The maintainer asked for a research fan-out with one-shot coherent recommendations and accepted all four. There was one researcher per area, using Oban, Meilisearch SDK, meilisearch-rails, Searchkick, Laravel Scout, Ecto and Rails ActiveJob prior art. Alternatives are in `179-DISCUSSION-LOG.md`.

### Chunk size and where chunking happens (PAGE-03)
- **D-01:** The limit is fixed at 1000, an internal module attribute (e.g. `@max_ids 1000`). There is **no public option**.
  - This matches the prior-art defaults: meilisearch-rails `DEFAULT_BATCH_SIZE = 1000`, Searchkick `batch_size || 1000`.
  - It stays far below the 65,535 bind-parameter limit (`in ^ids` uses one parameter per element).
  - An option can be added later without breaking anyone; removing one breaks adopters. Revisit only if an adopter reports Meilisearch payload-limit problems (≈100KB+ documents).
  - If an option is ever added, it must **not** be named `:batch_size`, which stays backfill's paging knob.
- **D-02:** One shared internal chunking helper (`@moduledoc false`) sits **above the adapter layer**. Every bounded call site uses it:
  - `Scrypath.Sync` upsert and delete dispatch
  - `Scrypath.Backfill` writes
  - `Scrypath.Oban.UpsertWorker` and `DeleteWorker`, including their missing-id deletes, which still run after the upserts as today
  - `Scrypath.Loader.load/3`, so `search_records/2` is guaranteed ≤1000 ids per call
  - `Scrypath.Sync.RelatedEnqueue`

  Adapter-level-only chunking was rejected: test fakes and custom backends would bypass it, and `Loader` would stay unbounded. Backfill `:batch_size` controls paging only; a `batch_size: 5000` page becomes 5 writes. Document that.
- **D-03:** Ids are deduped and sorted (stable, e.g. by `to_string/1`) before chunking. The same id set then always yields the same chunks, so `unique:` collapses duplicate jobs (D-13). Resolvers and loaders get set semantics; document that there is no ordering contract.

### Oban job split (PAGE-03)
- **D-04:** Under `sync_mode: :oban`, enqueueing N ids inserts **one job per chunk of ≤1000 ids**, so 2,500 ids make 3 jobs. Each job is inserted with `insert` (not `insert_all`) inside one transaction.
  - Open-source Oban's `insert_all` drops `unique:` (Oban docs: only Pro's Smart Engine does bulk unique).
  - The transaction ensures a mid-enqueue failure leaves no orphan jobs.
  - Rejected: one job that chunks internally. It means huge jsonb args, whole-job retry amplification, meaningless per-job telemetry for Phase 180, and timeout risk.
  - Workers still chunk whatever they receive through D-02, so legacy jobs with more than 1000 ids stay bounded.
- **D-05:** RelatedEnqueue chunks **trigger** ids into jobs the same way. The resolver output inside the worker goes through `sync_records`, so it is chunked automatically.

### Combined result and failure semantics (PAGE-03)
- **D-06:** Chunks run **sequentially** and the call **halts at the first failed chunk**, returning the same bare `{:error, reason}` as today. No partial payload and no id lists in errors (Phase 178 D-05: counts, not ids).
  - Chunks already sent stay applied; one docs sentence states this.
  - Rationale: writes are idempotent by id, and an Oban retry reloads current records.
  - This matches backfill's `run_batch` `with` precedent and Ecto.Multi stop-at-first-failure.
  - Rejected: continue-on-error / `{:ok, %{errors: ...}}`. Callers matching `{:ok, _}` and Oban would silently miss failures, which contradicts "sync failures are operational issues".
- **D-07:** Waiting:
  - **Inline** waits on each chunk's task before sending the next, so a failed task stops later chunks. Waiting only on the last task would miss an earlier chunk's failure; each Meilisearch task fails independently.
  - **Workers** wait per chunk through `IndexingAck` as today.
  - **Manual** mode doesn't wait; it sends all chunks and returns every task.
  - Document that `inline_timeout` applies per chunk, and that inline sync of more than 1000 ids inside a request is a smell (use Oban).
- **D-08:** `Scrypath.Operations.Result` gains `tasks: [Task.t()]`, always a list.
  - One entry per chunk, in order: Meilisearch tasks, or Oban jobs, which are already modelled as `Operations.Task` with `source: :oban`.
  - Empty for noop.
  - `task:` stays, pointing at the last chunk's task, so the ≤1000 case is unchanged plus a one-element `tasks`.
  - `document_ids` and `document_count` are combined across chunks.
  - There is **no separate `jobs:` key**. This supersedes the "add `jobs:`" wording from discussion, because enqueue results already put jobs in `task`.
  - Manual-mode docs: a successful `task:` doesn't prove earlier tasks succeeded; check `tasks`.
  - — **Reversibility:** costly — `tasks:` becomes part of the public result map for 0.3.x and later.
- **D-09:** Build the combined public result fresh. Never merge the first or last chunk's raw `metadata.backend_result` into `public_result/1`, because that would present one chunk's `task`/`raw` as covering the whole call.
- **D-10:** Telemetry stays one existing span around the whole call (`[:scrypath, :sync, :upsert | :delete]`), with the total `document_count`. No per-chunk spans and no new events.

### Related resolver input (FAN-01)
- **D-11:** A resolver always receives a **non-empty list of current trigger structs** and returns target records.
  - **Oban:** the related worker loads triggers through `Scrypath.Loader.load/3` (with `preload:` / `search_records/2`), then calls the resolver with the survivors.
    - Triggers that no longer load, because they were deleted or excluded by `search_records/2`, are skipped and counted as `missing_count`. This is added to the existing `[:scrypath, :sync, :related, :resolve]` span's stop metadata and to the result; it is not a new event.
    - If **none** survive, the resolver is not called and the job returns `:ok`. It must not return `{:error, _}`, which would burn 8 retries.
  - **Inline:** keeps passing the caller's structs. No reload and no new inline `:repo` requirement.
  - Prior art: Searchkick, Laravel `deleteWhenMissingModels` and Oban's ids-not-structs guidance all drop missing records quietly. Rejected: passing missing ids to the resolver (a second arity or context map). It brings back two resolver shapes and adds public surface nobody has asked for. An opt-in `on_missing:` can be added later without breaking anyone.
  - — **Reversibility:** costly — this is a visible behaviour change for adopters whose resolvers only accept ids.
- **D-12:** `RelatedEnqueue` calls `Loader.ensure_loadable!` on the trigger schema before enqueueing, so a missing `:repo` or custom-id schema fails where `sync_related` is called. This matches `sync_records` under Oban.
- **D-13 (docs):**
  - Rewrite `guides/related-data-and-reindexing.md` §(c), "Write an arity-safe resolver (the #1 footgun)", as "What your resolver receives":
    - Drop the id clause, and note that existing id clauses are now dead code and safe to remove.
    - State the soft-delete skip, and to sync targets directly (`Scrypath.sync_records(Post, posts)`) to hide them.
    - Say to call `sync_related` after the write commits; enqueueing inside an open transaction can load stale or missing triggers.
    - State that inline with a deleted struct still calls the resolver, which usually returns `[]`.
  - CHANGELOG entry under **Changed**: "Oban `sync_related` resolvers now receive loaded trigger records instead of document ids."

### Job-arg decoding and non-retrying errors (FAN-03)
- **D-14:** Every arg-decode or resolve failure in the related, upsert and delete workers returns `{:cancel, {:invalid_job, reason}}`.
  - `{:discard, _}` is deprecated in Oban. `{:error, _}` burns retries on input that can never succeed.
  - The Oban floor `~> 2.21` supports cancel.
  - A cancelled job can still be retried manually from Oban Web or Ops after a fix.
- **D-15:** One shared private decoder, `Scrypath.Oban.JobArgs` (`@moduledoc false`, pure, no Oban compile dependency), used by all three workers. It returns specific tags:
  - `{:unknown_schema, name}`, `{:unknown_fan_out, name}`, `{:unknown_backend, name}`, `{:unknown_repo, name}`, `{:unknown_otp_app, name}`
  - `{:invalid_arg, key}`, e.g. missing `"document_ids"`; this replaces today's `MatchError` on the pattern match
  - `{:invalid_config, message}`, from a rescued `Config.resolve!`. An unconfigured fan-out also maps to `{:unknown_fan_out, _}` instead of raising.

  Lift the existing `safe_module` / `Module.safe_concat` / `resolve_existing_module` pattern from the upsert and delete workers. The upsert and delete error atoms are private, so changing them breaks no contract. The tags are designed for Phase 180 telemetry metadata.
- **D-16:** Validation rules:
  - **Schema:** an existing loaded module.
  - **Backend:** the same callback check as upsert (`upsert_documents/3`, `delete_documents/3`, `index_name/2`). The related worker currently does no check.
  - **Repo:** `safe_module` + `Code.ensure_loaded?` + `function_exported?(m, :__adapter__, 0)`.
  - **otp_app:** `String.to_existing_atom` inside a rescue, plus `Application.spec(app) != nil`.
- **D-17:** Opts keys are decoded from a **string allowlist** (`index_prefix`, `meilisearch_url`, `backend`, `otp_app`, `repo`); unknown keys are ignored, not cancelled. Atoms are never created from job input, and a job enqueued by a newer version during a rolling deploy isn't stranded. Keys come only from Scrypath's own `job_args`, so a typo is a library bug that tests catch.
- **D-18:** The upsert worker's `put_repo/2` **cancels with `{:unknown_repo, name}`** when a `"repo"` value is present but can't be resolved, instead of silently falling back. Pre-0.3.16 jobs carry no `"repo"` key, so the 0.3.17 legacy path is unaffected. The plan must verify this against the 0.3.17 legacy tests.
- **D-19:** The related worker's `{:cancel, "HTTP 4xx: ..."}` string stays as is in this phase. Flag it for Phase 180 so reason shapes are aligned there.

### Related-job uniqueness and legacy jobs (FAN-02)
- **D-20:** Extract one shared `unique_opts/0` from `Scrypath.Oban.Enqueue`: `[period: :infinity, states: [:available, :scheduled, :retryable]]`, with the default fields `[:worker, :queue, :args]` and no `keys:`. Both enqueue paths use it.
  - `executing` is deliberately excluded: a running job may have read stale rows.
  - With D-03's sorted ids, the same set collapses regardless of call order.
- **D-21:** A collapsed duplicate is reported as `conflict?: job.conflict?` in that job's `Operations.Task` metadata. Status stays `:accepted`, since the work still happens, and no new status atom is added.
- **D-22:** The related job args shape doesn't change (`schema`, `document_ids`, `fan_out`, `opts`); only the worker's behaviour changes. A test runs a hard-coded pre-upgrade args map through `perform/1` (the 0.3.17 lesson).

### Tests (success criteria 1–4)
- **D-23:** Required:
  - 2,500 ids → 3 loads and 3 backend upsert calls, and 3 delete calls, each ≤1000, with one combined result (`document_count: 2500`, 3 `tasks`). Observe this through the test backend or fake.
  - Under Oban, 2,500 ids → 3 jobs.
  - Halt on a chunk-2 failure: chunk 3 is never sent, and the result is `{:error, reason}`.
  - A `search_records/2` spy sees ≤1000 ids per call.
  - The resolver receives structs under inline **and** Oban.
  - Under Oban, a deleted trigger is skipped and counted; all triggers deleted → resolver not called, job `:ok`; a soft-deleted trigger excluded by `search_records/2` is skipped.
  - FAN-02: enqueueing twice (ids in a different order) yields one job with `conflict?: true`. Use `Oban.Testing` in `testing: :manual`, because inline mode doesn't enforce uniqueness.
  - FAN-03: for each worker × {unknown schema, fan-out, backend, repo, otp_app, missing `document_ids`}, the job returns `{:cancel, {:invalid_job, tag}}` and never raises.
  - The legacy related-args fixture.

### Claude's Discretion
- Names of the chunking helper module and functions, and of the `@max_ids` attribute.
- Exact transaction mechanism for multi-job insert (`Ecto.Multi` vs `repo.transaction`), consistent with how `Enqueue` gets its repo or Oban instance.
- Whether `missing_count` also lands on the related-sync public result or only in the span metadata (span metadata is required).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and requirements
- `.planning/ROADMAP.md` § Phase 179: goal and success criteria 1–4
- `.planning/REQUIREMENTS.md`: PAGE-03, FAN-01, FAN-02, FAN-03 (and the "open for discuss-phase" notes, resolved here)
- `.planning/reference/ROLLING-ROADMAP.md` §2: v1.44 sync-correctness origin
- `.planning/phases/178-loader-routed-backfill-and-full-key-paging/178-CONTEXT.md`: D-01 (`prepare_records/3`), D-05 (counts, not id lists; Phase 180 owns telemetry), D-15 test style

### Adopter-facing docs to update
- `guides/related-data-and-reindexing.md`: fan-out section, §(c) "arity-safe resolver" (rewrite per D-13)
- `guides/sync-modes-and-visibility.md`: chunking, per-chunk `inline_timeout`, `tasks:` result, halt semantics
- `CHANGELOG.md`: Changed entry for the resolver input (D-13) and `tasks:` (D-08)

### Local research
- `prompts/meileisearch best practices for scrypath deep research.md`: task model and payload limits
- `prompts/elixir-search-lib-deep-research.md`: sync/fan-out prior art

### External (primary)
- Oban Worker return values (cancel vs. the deprecated discard): https://oban.hexdocs.pm/Oban.Worker.html
- Oban unique jobs, `conflict?`, `insert_all` and unique (Pro only): https://oban.hexdocs.pm/unique_jobs.html, https://oban.hexdocs.pm/Oban.html

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Scrypath.Loader.load/3` returns `{:ok, records, missing_ids}`. It is the Oban related worker's loader, and D-02 chunking goes inside it.
- `Loader.ensure_loadable!/2` is the enqueue-time check (D-12).
- The `safe_module/1` + `resolve_existing_module/2` helpers in `lib/scrypath/oban/upsert_worker.ex` and `delete_worker.ex` get lifted into `Scrypath.Oban.JobArgs` (D-15).
- The `unique:` policy in `lib/scrypath/oban/enqueue.ex` `job_changeset/3` gets extracted into `unique_opts/0` (D-20).
- `Scrypath.Operations.result_from_enqueue/2` already models an Oban job as an `Operations.Task` (`source: :oban`); `tasks:` reuses this (D-08).

### Established Patterns
- Oban modules are wrapped in `if Code.ensure_loaded?(Oban.Worker)` / `Oban.Job` with no-Oban stubs. New Oban-touching code must keep this so Phase 181's no-Oban build stays warnings-clean. `JobArgs` should be pure, with no Oban references.
- Backfill's `run_batch/2` uses a `with` that halts at the first error, which is the precedent for D-06.
- `Sync.maybe_wait_for_task/2` (inline only) and the workers' `IndexingAck.await/3` are the per-chunk wait hooks for D-07.
- `Sync.public_result/1` merges `metadata.backend_result`, the footgun behind D-09.

### Integration Points
- `lib/scrypath/sync.ex`: `sync_records`, `delete_documents`, `dispatch_upsert`/`dispatch_delete`, `inline_resolve_and_sync`
- `lib/scrypath/sync/related_worker.ex`: rewritten around `JobArgs` + `Loader.load/3`
- `lib/scrypath/sync/related_enqueue.ex`: chunked, unique, `ensure_loadable!`
- `lib/scrypath/oban/enqueue.ex`, `upsert_worker.ex`, `delete_worker.ex`
- `lib/scrypath/operations/result.ex` (`tasks` field), `lib/scrypath/operations.ex`
- `lib/scrypath/backfill.ex`: per-write chunking under large `:batch_size`

</code_context>

<specifics>
## Specific Ideas

- The maintainer prefers "another copy-paste over another dependency", so no new deps; chunking is `Enum.chunk_every/2`.
- Prior-art anchor: Searchkick `ProcessQueueJob` queues one batch job per 1000-id slice, which is the model for D-04.
- Footgun to avoid: meilisearch-rails' `ms_index_documents` sends the whole array in one `add_documents` call.

</specifics>

<deferred>
## Deferred Ideas

- A configurable chunk size (name must not be `:batch_size`). Add only if an adopter reports payload-limit issues.
- An opt-in fan-out `on_missing:` hook that gives resolvers the missing trigger ids. Add only on real adopter demand.
- Aligning the related worker's HTTP-4xx `{:cancel, "HTTP ..."}` string with tagged reasons. Phase 180.
- New telemetry events, including per-chunk spans and an event for cancelled-job reasons. Phase 180.

</deferred>

---

*Phase: 179-bounded-id-lists-and-related-sync-parity*
*Context gathered: 2026-10-25*
