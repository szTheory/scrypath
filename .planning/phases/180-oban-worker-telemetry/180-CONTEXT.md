# Phase 180: Oban worker telemetry - Context

**Gathered:** 2026-10-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Operators can observe every Oban upsert and delete job through stable, documented telemetry. That includes jobs that remove index entries whose records no longer exist (OBS-01, OBS-02). One telemetry guide is the canonical catalog, and a contract test fails when the guide and the emitted events drift apart (OBS-03).

Library-only: `lib/`, tests, guides/docs, mix.exs docs config, CHANGELOG. No `scrypath_ops`, no UI, no new required CI job, no new dependency.

Decisions were made by fanning out four research agents, one per gray area. The maintainer asked for coherent, ready-to-follow recommendations and delegated the calls (see memory "delegated decisions, coherence first").

</domain>

<decisions>
## Implementation Decisions

### Event names and span placement
- **D-01:** Two new spans, each with `:start`, `:stop` and `:exception`: `[:scrypath, :oban, :upsert]` in `Scrypath.Oban.UpsertWorker` and `[:scrypath, :oban, :delete]` in `Scrypath.Oban.DeleteWorker`. Emit them through the existing `Scrypath.Telemetry.span/3`. — **Reversibility:** one-way — event names become a published telemetry contract that adopters' handlers attach to; renaming breaks them silently.
  - The prefix follows the integration-named precedent `[:scrypath, :meilisearch, :request]`. The `[:scrypath, :oban, <job_kind>]` namespace leaves room for a later `[:scrypath, :oban, :related]`.
  - Rejected: reusing `[:scrypath, :sync, :upsert | :delete]`. In `:oban` mode those spans already fire at **enqueue** time with `sync_mode: :oban` and `status: :accepted` (`lib/scrypath/sync.ex` ~31/149, ~333). Reuse would double-count and mix enqueue latency with write latency. It would also change the meaning of a span that Phase 179 D-10 locked.
  - Rejected: relying only on Oban's `[:oban, :job, *]`. Those events carry only Scrypath's private `JobArgs` encoding: no resolved index or backend, and no way to see missing-record removals. They can't meet OBS-01 or OBS-02.
- **D-02:** **Span boundary.** The span wraps the work after `JobArgs.decode_*` **and** `JobArgs.resolve_config` succeed, so `common_metadata/3` can compute schema, index and backend. Decode and config failures emit **no** Scrypath span and **no** new event. The guide states that these jobs show up as Oban's own `[:oban, :job, :stop]` with `state: :cancelled` and in `[:scrypath, :operator, :failed_work, :observed]`. That avoids spans with nil tags, which break metrics reporters.
  - Cancels that happen inside the boundary go through the span with `outcome: :cancel` (see D-06): upsert's `:invalid_search_records`, `{:invalid_arg, key}`, `:repo_required` / `:search_records_required` with no usable legacy snapshot, and `{:unknown_repo, name}` if it resolves inside the boundary.
- **D-03:** One span per job, with no per-chunk spans (consistent with Phase 179 D-10). The existing `[:scrypath, :meilisearch, :request]` / `:task_wait` spans nest inside the worker span in the same process, so an OpenTelemetry bridge gets the parent/child tree for free.
- **D-04:** `Scrypath.Sync.RelatedWorker` gets **no** job-level span in this phase. OBS-01 names only the upsert and delete workers, and the related worker already has `[:scrypath, :sync, :related, :resolve]`.

### Metadata contract (start / stop / exception)
- **D-05:** **Start metadata (both workers)**, using the same key names as the `[:scrypath, :sync, *]` spans so one handler shape reads both:
  - `schema`, `backend`, `index` (from `Telemetry.common_metadata/3`)
  - `sync_mode: :oban`. Set it explicitly: the worker config carries `sync_mode: :manual`, so `common_metadata/3` would otherwise report `:manual`. Pin it in a test.
  - `repo`, optional, exactly as `common_metadata/3` already emits it
  - `attempt` and `max_attempts`, pos_integers from the `%Oban.Job{}`. They allow a final-attempt alert: `attempt == max_attempts and outcome != :ok`.
  - `document_count`, non_neg_integer: the number of ids in the job args (upsert: ids requested; delete: ids to delete)

  Not included: `job_id`, `queue`, `worker`. Oban's own events carry them in the same process, the event name already identifies the worker, and `job_id` is high-cardinality.

  — **Reversibility:** one-way — documented metadata keys are part of the telemetry contract.
- **D-06:** **Stop metadata** is merged onto the start metadata:
  - `outcome`: `:ok | :error | :cancel`, mapping the worker's return value: `:ok`, `{:error, _}` (Oban retries), `{:cancel, _}` (no retry). Use a **new key**, not `status`, because `status` already means `:noop` / result status on the sync spans and shared handlers would misread it. Don't use Oban's `state` vocabulary either: Oban reports `{:error, _}` as `:exception`, and identical labels on different event mappings would confuse anyone joining the two.
  - `error_kind`: an atom, present only when `outcome: :error`. It comes from the existing `error_kind/1` in `lib/scrypath/telemetry.ex` (`:http`, `:transport`, `:timeout`, `:task_failed`, an atom reason, or `:other`).
  - `cancel_reason`: an atom, present only when `outcome: :cancel`. It is the **atom head** of the Phase 179 D-15 tag, flattened: `{:unknown_repo, _}` → `:unknown_repo`, `{:invalid_arg, _}` → `:invalid_arg`, `{:invalid_config, _}` → `:invalid_config`; bare atoms such as `:invalid_search_records` stay as they are. The second element is **always dropped**, because it can be untrusted job input, a module, or an exception message. Never pass a tuple as a tag value, and never create an atom from job input.
  - **Upsert only:**
    - `source`: `:loaded | :legacy_snapshot`. It makes the pre-0.3.16 snapshot path visible, so adopters can tell when it's safe to drop.
    - `upserted_count`: documents planned for upsert (records loaded, or the snapshot length).
    - `missing_count`: ids with no current record, which are removed from the index. Always `0` on the legacy path. Same key name as `[:scrypath, :hydration]` and `[:scrypath, :sync, :related, :resolve]`.
  - **Counts describe the plan; `outcome` is authoritative.** After a failed chunk (Phase 179 D-06 halts at the first failure) the counts still describe what the job planned. The guide says so.
  - The stop path must **not** overwrite the start `document_count` with a result-derived count. Today `stop_metadata/2` would do that, so the worker spans need their own stop-metadata builder or clause.
- **D-07:** **Exception metadata**: the standard `:telemetry.span` keys `kind`, `reason`, `stacktrace`, merged with the start metadata. The guide states that `reason` is diagnostic only and never a metric tag, the same convention as Ecto, Finch and Oban. Since the workers return `{:error, _}` rather than raising, `:exception` means the job raised. The success-criteria test has to make the backend raise to observe it.
- **D-08:** **Cardinality and privacy rule (whole contract):** tag values are atoms, integers, modules or the bounded index string. No ids, document bodies, error bodies, raw HTTP bodies or tuples. A test asserts that no captured worker metadata value is a tuple or a list of ids.

### Missing-record removal signal (OBS-02)
- **D-09:** A point event `[:scrypath, :oban, :upsert, :missing_removed]` with measurements `%{count: n}` and metadata equal to the upsert span's start metadata (schema, backend, index, sync_mode, repo, attempt, max_attempts, document_count). The count is a **measurement**, so `telemetry_metrics` `counter/1` and `sum/2` work without a custom `measurement:` function. — **Reversibility:** one-way — published event name.
  - The wording follows the repo's vocabulary: "missing" for these ids (`missing_ids`, `missing_count`), and "removed" for the delete side (Loader moduledoc: "removed from the index"; backfill's `removed:`). Rejected names: "stale" (already means stale search results in the guides), "orphan" (a reconcile concept for index documents with no source row), "pruned" and "deleted".
- **D-10:** **Firing rule:**
  - Fire only when `n > 0`.
  - Fire only **after every delete chunk for the missing ids has succeeded**. A failed chunk returns `{:error, _}` with no event, and the retry reloads records and recomputes the missing ids, so retries never re-count. `attempt` stays in the metadata.
  - Never fire on the legacy snapshot path, which loads nothing.
  - The guide documents that `count` means ids whose source record is missing and which the job confirmed absent from the index. Meilisearch treats deleting an absent id as a successful no-op, so this is **not** a count of documents that were actually present.
- **D-11:** Both surfaces exist and answer different questions:
  - the event = ids **removed** (count it on dashboards)
  - the span's stop `missing_count` = ids the load **found** missing (for traces)

  The guide says "count the event, not the metadata", which prevents double-summing.
- **D-12:** No Logger line. A soft delete routed through upsert is a normal path, so logging it would be noise. Libraries emit telemetry and let the host log.
- **D-13:** No analogous event elsewhere:
  - `DeleteWorker` deletes the ids it is given, and its span's `document_count` covers that.
  - The related worker skips missing triggers and already reports them on the resolve span.
  - Inline `sync_records` takes records, not ids.
  - Hydration's `missing_count` is a read-side drift signal and stays unchanged.

### Telemetry guide and drift contract (OBS-03)
- **D-14:** **Canonical location:** a new `guides/telemetry.md` HexDocs extra in the **Operations** group (`mix.exs` `docs.extras` ~188 and `groups_for_extras` ~247; package `files:` already ships `guides/`, so the parity gate is unaffected).
  - `Scrypath.Telemetry` stays `@moduledoc false`: its helpers are internal, and making it public would leak them.
  - Two existing docs drop their copies of the event table and keep only aggregation advice plus a link to the guide, so no file holds a second table: `docs/search-backend-sre.md` "## Scrypath telemetry" and `guides/per-query-tuning-pipeline.md` "## Telemetry catalog".
  - Update the existing `docs_contract_test` string assertions (`[:scrypath, :search]`, etc. around line 669) so they point at the guide, or keep them satisfied by the shortened SRE text. Don't let them break.
- **D-15:** **Catalog scope:** every Scrypath event, at the name level. Today `lib/` emits 14 events: `search`, `search_many`, `search_many.partial`, `search_facet_values`, `hydration`, `sync.upsert`, `sync.delete`, `sync.related.resolve`, `meilisearch.request`, `meilisearch.task_wait`, `settings.hot_apply`, `reindex.settings_verified`, `reindex.verify_skipped`, `operator.failed_work.observed`. Plus the 3 new ones. A two-way name check can't work with a partial catalog, and the current SRE table already misses 4 emitted events.
- **D-16:** **Guide table format (machine-parseable, fixed columns):** Event | Kind (`span` / `event`) | Measurements | Start metadata | Stop-only metadata | When. Required and optional keys are distinguished with an explicit marker (e.g. a trailing `?` for optional, such as `repo?`). The guide also has prose sections:
  - Oban jobs and how to join with `[:oban, :job, *]`. Decode cancels appear only there. Oban reports `{:error, _}` as `:exception`, while Scrypath reports it as `:stop` with `outcome: :error`.
  - Cardinality (D-08).
  - "count the event, not the metadata" (D-11).
  - Exception `reason` is not a tag (D-07).
- **D-17:** **Drift mechanism (bidirectional, no new deps):** the contract test parses the guide table.
  - (a) **Names:** a static scan of `lib/**/*.ex` for `[:scrypath, ...]` event-name literals, excluding doc text. It asserts that the set equals the table's event set in both directions, so it catches documented-but-not-emitted and emitted-but-not-documented events deterministically, with no handlers.
  - (b) **Guard:** every `Telemetry.span(` / `:telemetry.execute(` / `:telemetry.span(` call in `lib/` takes a literal event-name list. A computed name would slip past (a), so it fails the test. If an existing call site uses a variable, the planner either rewrites it to a literal or adds a tiny explicit allowlist, decided per site.
  - (c) **Keys:** for the 3 new worker events, attach handlers (`async: false`, unique handler ids, detached in `on_exit`) and run the real workers through `perform/1` (or `Oban.Testing.perform_job`). Cover:
    - success with missing ids
    - `{:error, _}`
    - `{:cancel, _}` inside the boundary
    - a raise
    - a legacy snapshot

    On every captured event, assert that the required keys ⊆ emitted ⊆ required ∪ optional, checking start and stop separately. Existing events get the name-level check only. Strict key coverage for them is a stated gap, not Phase 180 work.

  — **Reversibility:** reversible.

### Related-worker reason shape (Phase 179 D-19 carry-over)
- **D-18:** `Scrypath.Sync.RelatedWorker` currently returns `{:cancel, "HTTP #{status}: #{inspect(body)}"}` (`lib/scrypath/sync/related_worker.ex` ~80). Change it to `{:cancel, {:http_error, status}}`. That aligns it with the D-15 tag shape. It also stops the backend body (which can echo document content) from being persisted in Oban's `errors` column, and makes the reason pattern-matchable. Phase 179 D-19 explicitly flagged this for Phase 180. Update any test or operator code that matches the string (grep `scrypath_ops` too, read-only, to confirm nothing parses it; if something does, flag it instead of editing `scrypath_ops`).

### Docs and changelog
- **D-19:** CHANGELOG "Added" entry for the 3 events and the telemetry guide, plus a "Changed" entry for the related worker cancel reason (D-18). Published markdown must not contain requirement IDs (the existing docs contract test bans `XXX-NN` patterns).

### Claude's Discretion
- How the worker stop-metadata builder is factored (a new clause in `Scrypath.Telemetry` vs a private helper in each worker), as long as D-06 holds and `document_count` isn't overwritten.
- Whether `error_kind/1` becomes public or gets wrapped.
- The exact table-parsing helper and where the capture helper lives (`test/support/`).
- How the existing 14 events' rows and "When" prose are worded in the guide, as long as they match current behavior.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope
- `.planning/ROADMAP.md` §"Phase 180: Oban worker telemetry": goal and 3 success criteria
- `.planning/REQUIREMENTS.md`: OBS-01, OBS-02, OBS-03

### Prior decisions this phase builds on
- `.planning/phases/179-bounded-id-lists-and-related-sync-parity/179-CONTEXT.md`: D-06 (halt at first failed chunk), D-10 (one span per call, no per-chunk spans), D-14/D-15 (cancel tags designed for Phase 180 metadata), D-19 (related-worker reason string flagged for Phase 180)
- `.planning/phases/178-loader-routed-backfill-and-full-key-paging/178-CONTEXT.md`: D-05 (counts, not id lists; Phase 180 owns telemetry)

### Code
- `lib/scrypath/telemetry.ex`: `span/3`, `common_metadata/3`, `stop_metadata/2`, `error_kind/1`
- `lib/scrypath/oban/upsert_worker.ex`, `lib/scrypath/oban/delete_worker.ex`: span sites, `missing_ids` delete, legacy snapshot path
- `lib/scrypath/oban/job_args.ex`: decode tags (source of `cancel_reason`)
- `lib/scrypath/sync.ex`: enqueue-time `[:scrypath, :sync, *]` spans (why D-01 rejects reuse)
- `lib/scrypath/sync/related_worker.ex`: resolve span precedent (`missing_count`); D-18 cancel string
- `lib/scrypath/loader.ex`: what makes an id "missing"; "removed from the index" wording

### Docs and tests
- `docs/search-backend-sre.md` §"Scrypath telemetry": current table, to become a pointer
- `guides/per-query-tuning-pipeline.md` §"Telemetry catalog": to become a pointer
- `test/scrypath/docs_contract_test.exs`: existing contract pattern, SRE assertion ~669, banned requirement-ID patterns
- `test/scrypath/telemetry_test.exs`: handler-capture pattern, `RecordingBackend`
- `mix.exs`: `docs.extras` (~188), `groups_for_extras` Operations (~247), package `files:`

### External
- Oban.Telemetry (https://hexdocs.pm/oban/Oban.Telemetry.html): `[:oban, :job, *]` metadata and `state` values, for the join section of the guide

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Scrypath.Telemetry.span/3` merges extra stop metadata onto start metadata, which gives D-05/D-06 their shape.
- `Telemetry.common_metadata/3` supplies schema, backend, index, sync_mode and repo. Override `sync_mode` to `:oban`.
- `error_kind/1` already classifies backend errors (currently `defp`).
- `test/scrypath/telemetry_test.exs` `RecordingBackend` and its handler-capture setup can be reused for the worker tests. The Phase 179 Oban SQLite harness (`test/scrypath/oban/enqueue_unique_test.exs`) is there if real-Oban runs are needed.

### Established Patterns
- Point events with `%{count: 1}` measurements: `[:scrypath, :operator, :failed_work, :observed]`, `[:scrypath, :reindex, :verify_skipped]` (the D-09 precedent).
- `missing_count` on stop metadata: `[:scrypath, :hydration]`, `[:scrypath, :sync, :related, :resolve]` (the D-06/D-11 precedent).
- Workers are compiled only when Oban is loaded (`if Code.ensure_loaded?(Oban.Worker)`). Telemetry code in them stays inside that guard. The guide and docs test must not need Oban at compile time.
- Docs contract tests read files at compile time via module attributes (`@search_backend_sre_docs File.read!(...)`).

### Integration Points
- UpsertWorker `sync/3` and the `write/4` chunk loop are where the span and the `missing_removed` emit go. The emit goes after `write(backend, :delete_documents, ..., missing_ids, ...)` returns `:ok`.
- DeleteWorker `perform/1`, after `resolve_config`.

</code_context>

<specifics>
## Specific Ideas

- Prior art considered: Finch `[:finch, :request, *]`, Broadway `[:broadway, :processor, :message, *]`, Oban `[:oban, :job, *]` naming; Searchkick `should_index?`, meilisearch-rails `remove_from_index` and Laravel Scout `unsearchable` for "removed" wording; and the fact that Oban, Finch, Ecto and Broadway document telemetry in moduledocs but none check doc/code parity. Scrypath's contract test goes further.
- Dashboard guidance for the guide: alert on `outcome: :cancel` rate and on final-attempt failures. Put `missing_removed` count per schema on a dashboard; don't page on it.

</specifics>

<deferred>
## Deferred Ideas

- **Upsert/delete workers retry on backend 4xx.** They return `{:error, _}` and burn all 8 attempts, while the related worker cancels. That's a behavior change to retry semantics, so it needs its own decision or ticket, not Phase 180.
- **`[:scrypath, :oban, :related]` job-level span** for the related worker. The namespace is reserved by D-01.
- **Strict key-level contract for the 14 existing events.** They get name-level drift checks only in this phase.
- **A `[:scrypath, :backfill, ..., :missing_removed]` analogue** for backfill's `removed:`. The name is reusable.
- **A `[:scrypath, :oban, :invalid_job]` point event for decode failures.** Considered and rejected for now: Oban's own cancelled stop plus `failed_work` cover it. Revisit if adopters ask.
- **A public `Scrypath.Telemetry` moduledoc** pointing at the guide (Oban.Telemetry convention). It needs the helpers split first.

</deferred>

---

*Phase: 180-oban-worker-telemetry*
*Context gathered: 2026-10-25*
