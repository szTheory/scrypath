# Phase 180: Oban worker telemetry - Research

**Researched:** 2026-10-25
**Domain:** Elixir `:telemetry` spans in Oban workers, doc/code parity contract tests
**Confidence:** HIGH (every in-repo claim was read this session; Oban and telemetry behavior was read from the locked dependency sources in `deps/`)

## Summary

The phase is small in code and large in contract. Two spans (`[:scrypath, :oban, :upsert]`, `[:scrypath, :oban, :delete]`) and one point event (`[:scrypath, :oban, :upsert, :missing_removed]`) go into two ~100-line workers. The existing `Scrypath.Telemetry.span/3` wrapper already gives the start/stop/exception shape. Most of the planning risk is elsewhere: the guide, the parity test, and six existing tests and docs that hard-code what this phase changes.

I found seven facts the CONTEXT does not mention, and each changes a plan:
1. **The docs contract suite does not run in required CI.** `test/scrypath/docs_contract_test.exs` carries `@moduletag :docs_contract`, and the `core` job runs `mix verify.core --exclude integration --exclude docs_contract`. If the drift check lives in that file, CI never runs it. Put it in a new, untagged test file. It then runs in the existing `core` lane, so no new CI job is needed.
2. **`ARCHITECTURE.md` currently says the opposite of this phase:** "Oban job lifecycle remains on Oban's own telemetry events. Scrypath emits search semantics, not a second queue lifecycle." Reword it.
3. **`test/release/package_metadata_test.exs` asserts the exact Operations group list.** Adding `guides/telemetry.md` without updating that list breaks the `package` lane.
4. **A trailing `?` for optional keys (D-16's example) collides with a real key, `retryable?`.** `[:scrypath, :operator, :failed_work, :observed]` emits it. Use a different optional marker.
5. **`:telemetry.span` adds `telemetry_span_context` to every start, stop and exception event,** and exception events also carry `stacktrace`, which is a list. The "emitted ⊆ documented" check and the D-08 "no tuples or lists" check must allow these standard keys.
6. **The only cancels inside the D-02 boundary are upsert-side and come after the load:** `:repo_required`, `:search_records_required`, `:invalid_search_records`, `{:invalid_arg, "document_ids"}`. `{:unknown_repo, _}` and `{:invalid_config, _}` are raised by decode and `resolve_config`, both outside the boundary. DeleteWorker has no cancel inside the boundary at all.
7. **A bare `%Oban.Job{}` has `attempt: 0`.** Tests that check that `attempt` is a pos_integer must set it themselves.

A static AST scan of `lib/**/*.ex` was prototyped this session. It finds exactly the 14 event names CONTEXT D-15 lists, it ignores event names written inside `@moduledoc`/`@doc` text (they are string literals in the AST), and the D-17(b) guard reports exactly one non-literal call site: the `Scrypath.Telemetry.span/3` wrapper itself.

**Primary recommendation:** Add a pure, Oban-free `Scrypath.Telemetry.job_stop_metadata/1` helper and wrap each worker's post-`resolve_config` work in `Telemetry.span/3`. Thread a small facts map (source, counts) out of `UpsertWorker.sync`. Emit `missing_removed` only after the missing-id delete returns `:ok`. Enforce guide parity in a new untagged `test/scrypath/telemetry_contract_test.exs`.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

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

### Deferred Ideas (OUT OF SCOPE)
- **Upsert/delete workers retry on backend 4xx.** They return `{:error, _}` and burn all 8 attempts, while the related worker cancels. That's a behavior change to retry semantics, so it needs its own decision or ticket, not Phase 180.
- **`[:scrypath, :oban, :related]` job-level span** for the related worker. The namespace is reserved by D-01.
- **Strict key-level contract for the 14 existing events.** They get name-level drift checks only in this phase.
- **A `[:scrypath, :backfill, ..., :missing_removed]` analogue** for backfill's `removed:`. The name is reusable.
- **A `[:scrypath, :oban, :invalid_job]` point event for decode failures.** Considered and rejected for now: Oban's own cancelled stop plus `failed_work` cover it. Revisit if adopters ask.
- **A public `Scrypath.Telemetry` moduledoc** pointing at the guide (Oban.Telemetry convention). It needs the helpers split first.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| OBS-01 | The Oban upsert and delete workers emit telemetry spans (start, stop, exception) with stable metadata: schema, index, backend, document count and attempt. | Span placement and boundary: Pattern 1. Stop builder: Pattern 2. Exception path: Pitfall 6. Test harness: Validation Architecture. |
| OBS-02 | When a job finds ids with no current record and deletes them from the index, it emits an event with the count of those ids. This case is no longer silent. | Emit site after `write(..., :delete_documents, ..., missing_ids, ...)` returns `:ok`: Pattern 3. Count via `Chunks.distinct_count/1`: Pitfall 4. |
| OBS-03 | The telemetry guide and its contract test list the new events and metadata keys. | `guides/telemetry.md` plus the mix.exs and test updates: Pattern 4. AST scan and guard, both prototyped: Pattern 5. The test must be untagged so CI runs it: Pitfall 1. |
</phase_requirements>

## Project Constraints (from CLAUDE.md / AGENTS.md)

- Elixir floor 1.17, OTP 26. Use Ecto-first APIs. Telemetry is a first-class contract [VERIFIED: AGENTS.md].
- Oban is **optional**: worker code stays inside the `if Code.ensure_loaded?(Oban.Worker) and Code.ensure_loaded?(Oban.Job)` guard, and `mix verify.no_optional_deps` must stay green [VERIFIED: lib/scrypath/oban/upsert_worker.ex:1, lib/mix/tasks/verify.no_optional_deps.ex].
- No new dependency. No mandatory supervision.
- Green-main posture: completion must be backed by executable tests or exact-SHA hosted evidence, never human UAT. Keep the lean required gates. Add no new required CI job (CONTEXT scope).
- Credo, Dialyxir, ExDoc (`mix docs --warnings-as-errors`) and `mix format --check-formatted` are part of `verify.core` [VERIFIED: lib/mix/tasks/verify.ex:28-34].
- Update `.planning/PROJECT.md` only if shipped claims change. New published telemetry events count as a shipped-surface change, so the planner should consider a one-line PROJECT.md note.
- Published markdown hygiene: no requirement IDs or `(D-xx)` refs in guides or docs [VERIFIED: test/scrypath/docs_contract_test.exs:93-117].

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Worker spans and `missing_removed` emit | Library: Oban worker modules (`lib/scrypath/oban/*_worker.ex`) | `Scrypath.Telemetry` (pure helpers) | Only the worker knows `attempt`, the outcome and the load facts. Helpers stay Oban-free so they compile without Oban. |
| Stop-metadata mapping (outcome, error_kind, cancel_reason) | `Scrypath.Telemetry` | — | Pure function of the worker return value. Unit-testable without Oban. Reuses the private `error_kind/1`. |
| Event catalog | Docs (`guides/telemetry.md`, HexDocs Operations group) | SRE doc and per-query guide link to it | One table only (D-14). |
| Drift enforcement | Test tier (new untagged ExUnit file in the `core` CI lane) | `test/support` capture helper | A static scan plus runtime key capture. |

## Standard Stack

### Core (already locked in `mix.lock`; nothing to install)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| telemetry | 1.4.2 | `:telemetry.span/3`, `:telemetry.execute/3` | Already the project's telemetry primitive [VERIFIED: mix.lock] |
| oban (optional) | 2.23.0 | `%Oban.Job{attempt, max_attempts}`, `Oban.Testing.build_job/3` | Already the async path [VERIFIED: mix.lock] |
| ExUnit | Elixir 1.19.5 / OTP 28 locally | handler capture, AST scan via `Code.string_to_quoted/2` | stdlib [VERIFIED: `elixir --version` this session] |

**Installation:** none. The phase adds no dependency, so the Package Legitimacy Audit is not applicable.

## Package Legitimacy Audit

Not applicable. This phase installs no external packages (CONTEXT: "no new dependency").

## Architecture Patterns

### System Architecture Diagram

```
Oban executor ──perform(%Oban.Job{args, attempt, max_attempts})──▶ Worker.perform/1
   │                                                                 │
   │                                         JobArgs.decode_* ──fail──▶ {:cancel, {:invalid_job, tag}}  (NO Scrypath event;
   │                                                                 │                                    visible as [:oban,:job,:stop] state: :cancelled)
   │                                         JobArgs.resolve_config ─fail─▶ same as above
   │                                                                 ▼
   │                         ┌──── [:scrypath, :oban, :upsert|:delete, :start]  (schema, backend, index, sync_mode: :oban,
   │                         │                                                     repo?, attempt, max_attempts, document_count)
   │                         │   Upsert: Loader.load ─▶ {records, missing_ids} | legacy snapshot | cancel tag | {:error,_}
   │                         │      ├─ write :upsert_documents (chunked) ──▶ [:scrypath, :meilisearch, :request|:task_wait] (nested)
   │                         │      └─ write :delete_documents missing_ids ──:ok──▶ [:scrypath, :oban, :upsert, :missing_removed] %{count: n>0}
   │                         │   Delete: write :delete_documents (chunked)
   │                         │   raise? ──▶ [..., :exception] (kind, reason, stacktrace) ── re-raised ──▶ Oban :exception
   │                         └──── [..., :stop]  + outcome, error_kind?|cancel_reason?, (upsert) source?, upserted_count?, missing_count?
   ▼
[:oban, :job, :stop | :exception]  (Oban's own: job, conf, state, result)
```

### Recommended file touch list
```
lib/scrypath/telemetry.ex                 # + job_stop_metadata/1 (public, @doc false), cancel_reason flattening
lib/scrypath/oban/upsert_worker.ex        # span + facts threading + missing_removed emit
lib/scrypath/oban/delete_worker.ex        # span
lib/scrypath/sync/related_worker.ex       # D-18 {:cancel, {:http_error, status}}
guides/telemetry.md                       # NEW canonical catalog
guides/per-query-tuning-pipeline.md       # table -> pointer (keep "## Telemetry catalog" heading)
guides/related-data-and-reindexing.md     # 4xx row: `{:cancel, {:http_error, status}}`
docs/search-backend-sre.md                # table -> pointer + aggregation advice
ARCHITECTURE.md                           # Observability bullet rewording
mix.exs                                   # extras + Operations group
test/support/telemetry_capture.ex         # NEW handler capture helper (full event names)
test/support/oban_telemetry_scenarios.ex  # NEW (optional) shared backends/schemas/scenario runner
test/scrypath/oban/worker_telemetry_test.exs   # NEW async: false: OBS-01/02 behavior
test/scrypath/telemetry_contract_test.exs      # NEW async: false, UNTAGGED: OBS-03 names/guard/keys
test/scrypath/telemetry_test.exs          # + job_stop_metadata/1 unit cases (optional)
test/scrypath/docs_contract_test.exs      # @guide_paths += telemetry.md; SRE assertion; OBS-NN ban
test/release/package_metadata_test.exs    # Operations list
test/scrypath/sync/related_worker_test.exs # line ~503 cancel shape
```

### Pattern 1: Span at the D-02 boundary (both workers)

Current code [VERIFIED: lib/scrypath/oban/upsert_worker.ex:15-24]:
```elixir
def perform(%Oban.Job{args: args}) do
  with {:ok, job} <- JobArgs.decode_upsert(args),
       {:ok, config} <-
         JobArgs.resolve_config([backend: job.backend, sync_mode: :manual] ++ job.opts) do
    config = Keyword.put(config, :index_name, job.index)
    sync(job, args, config)
  else
    {:error, tag} -> {:cancel, {:invalid_job, tag}}
  end
end
```
DeleteWorker has the same shape and calls `write(job.backend, job.schema, job.document_ids, config)` [VERIFIED: lib/scrypath/oban/delete_worker.ex:12-21].

Recommended shape (sketch; the names `start_metadata/3` and `job_stop_metadata/1` are proposed, not existing):
```elixir
def perform(%Oban.Job{args: args} = oban_job) do
  with {:ok, job} <- JobArgs.decode_upsert(args),
       {:ok, config} <- JobArgs.resolve_config([backend: job.backend, sync_mode: :manual] ++ job.opts) do
    config = Keyword.put(config, :index_name, job.index)
    metadata = start_metadata(job, config, oban_job)

    Telemetry.span([:scrypath, :oban, :upsert], metadata, fn ->
      {result, facts} = sync(job, args, config, metadata)
      {result, Map.merge(Telemetry.job_stop_metadata(result), facts)}
    end)
  else
    {:error, tag} -> {:cancel, {:invalid_job, tag}}
  end
end

defp start_metadata(job, config, %Oban.Job{attempt: attempt, max_attempts: max}) do
  Telemetry.common_metadata(job.schema, config,
    sync_mode: :oban,
    attempt: attempt,
    max_attempts: max,
    document_count: Chunks.distinct_count(job.document_ids)
  )
end
```
- The `sync_mode: :oban` extra wins because `common_metadata/3` merges `extra` last: `|> maybe_put(:sync_mode, Keyword.get(config, :sync_mode)) |> maybe_put(:repo, Keyword.get(config, :repo)) |> Map.merge(Map.new(extra))` [VERIFIED: lib/scrypath/telemetry.ex:26-28].
- The event name must stay a **literal list** at the call site, or the D-17(b) guard fails.
- `Telemetry.span/3` merges the stop map onto the start metadata: `{result, Map.merge(metadata, stop_metadata)}` [VERIFIED: lib/scrypath/telemetry.ex:10-14]. The stop builder must therefore never return `document_count`.

### Pattern 2: Pure stop-metadata helper in `Scrypath.Telemetry`

Do not reuse `stop_metadata/2` for worker results. A worker returns `:ok`, and `stop_metadata(:ok, [])` falls through to `Map.merge(%{result_kind: result_kind(result)}, ...)` [VERIFIED: lib/scrypath/telemetry.ex:55-57]. That would emit an undocumented `result_kind: :ok` key and fail the D-17(c) "emitted ⊆ documented" check.

The existing classifier is private [VERIFIED: lib/scrypath/telemetry.ex:75-82]:
```elixir
defp error_kind({:http_error, status, _body}) when is_integer(status), do: :http
defp error_kind({:transport_error, _}), do: :transport
defp error_kind({:timeout, _}), do: :timeout
defp error_kind({:task_failed, _}), do: :task_failed
defp error_kind({:cancelled, _}), do: :cancelled
defp error_kind({:invalid_task_payload, _}), do: :invalid_task_payload
defp error_kind(reason) when is_atom(reason), do: reason
defp error_kind(_), do: :other
```
Note that the real value set also includes `:cancelled` and `:invalid_task_payload`, which D-06's list omits. The guide should state "an atom; see …" rather than a closed list, or list all of them.

Recommended (keeps `error_kind/1` private, adds one public `@doc false` function):
```elixir
@doc false
@spec job_stop_metadata(term()) :: metadata()
def job_stop_metadata(:ok), do: %{outcome: :ok}
def job_stop_metadata({:error, reason}), do: %{outcome: :error, error_kind: error_kind(reason)}
def job_stop_metadata({:cancel, reason}), do: %{outcome: :cancel, cancel_reason: cancel_reason(reason)}

defp cancel_reason({:invalid_job, tag}), do: cancel_reason(tag)
defp cancel_reason({tag, _detail}) when is_atom(tag), do: tag
defp cancel_reason(tag) when is_atom(tag), do: tag
defp cancel_reason(_other), do: :other
```
The worker cancel wrapper is `{:invalid_job, tag}` [VERIFIED: lib/scrypath/oban/upsert_worker.ex:22,49,55,59]. Strip it so `cancel_reason` is the tag head, as D-06 says. The helper references no Oban module, so `verify.no_optional_deps` stays green.

### Pattern 3: Threading upsert facts and emitting `missing_removed`

Current branches [VERIFIED: lib/scrypath/oban/upsert_worker.ex:33-63]:
- `{:ok, records, missing_ids}` → upsert documents, then `write(backend, :delete_documents, schema_module, missing_ids, config)`. Facts: `source: :loaded`, `upserted_count`, `missing_count`.
- `{:error, reason} when reason in [:repo_required, :search_records_required]`, then `legacy_snapshot/2`:
  - `{:ok, documents}` → facts `source: :legacy_snapshot`, `upserted_count: length(documents)`, `missing_count: 0`
  - `:error` → `{:cancel, {:invalid_job, reason}}`, with no source facts
- `{:error, {:invalid_search_records, _}}` → `{:cancel, {:invalid_job, :invalid_search_records}}`, with no facts
- `{:error, {:invalid_arg, _key} = tag}` → `{:cancel, {:invalid_job, tag}}`, with no facts
- `{:error, reason}` → `{:error, reason}`, with no facts

So `source`, `upserted_count` and `missing_count` are **optional** stop keys. They are absent whenever the load did not produce a plan. The guide must mark them optional, and the worker test should assert they are present exactly when `outcome != :cancel` and the load or snapshot succeeded.

Emit site:
```elixir
with :ok <- write(backend, :upsert_documents, schema_module, documents, config),
     :ok <- write(backend, :delete_documents, schema_module, missing_ids, config) do
  emit_missing_removed(missing_ids, metadata)
  :ok
end

defp emit_missing_removed(missing_ids, metadata) do
  case Chunks.distinct_count(missing_ids) do
    0 -> :ok
    n -> :telemetry.execute([:scrypath, :oban, :upsert, :missing_removed], %{count: n}, metadata)
  end
end
```
- `write/5` already returns `:ok` for `[]` (`defp write(_backend, _fun, _schema_module, [], _config), do: :ok`), and `Chunks.each_ok/2` halts at the first `{:error, _}` [VERIFIED: lib/scrypath/oban/upsert_worker.ex:68-76, lib/scrypath/chunks.ex:84-93]. So "after every chunk succeeded" just means "after the `with` reaches the emit".
- `metadata` here is the **start** metadata (D-09). Pass it into `sync` and do not rebuild it.
- The event fires inside the span, after the nested backend spans and before `:stop`.

### Pattern 4: Guide plus docs wiring

- `mix.exs`: add `"guides/telemetry.md"` to `extras` and to `groups_for_extras[:Operations]` [VERIFIED: mix.exs docs/0, Operations list]. `files:` already includes `guides` [VERIFIED: mix.exs package/0 `~w(lib ... guides docs/jtbd-gap-map.md ...)`].
- Update `test/release/package_metadata_test.exs`. It asserts the exact list [VERIFIED: test/release/package_metadata_test.exs:84-92]:
  ```
  assert docs[:groups_for_extras][:Operations] == [
           "ARCHITECTURE.md",
           "guides/drift-recovery.md",
           "guides/meilisearch-operations.md",
           "guides/operator-mix-tasks.md",
           "guides/relevance-tuning.md",
           "guides/per-query-tuning-pipeline.md",
           "guides/sync-modes-and-visibility.md"
         ]
  ```
- Link style: from `docs/` use `../guides/telemetry.md` (the SRE doc uses `../guides/sync-modes-and-visibility.md`); from `guides/` use `telemetry.md` [VERIFIED: grep this session].
- `docs_contract_test.exs`:
  - Add `"guides/telemetry.md"` to `@guide_paths`. That brings it under the hygiene patterns via `@published_markdown_for_hygiene`.
  - Add `{~r/\bOBS-\d{2}\b/, "OBS-NN requirement-style IDs"}`. The current list has no OBS pattern [VERIFIED: test/scrypath/docs_contract_test.exs:94-107].
  - Keep `assert String.contains?(@per_query_tuning_pipeline, "## Telemetry catalog")` [VERIFIED: :90] satisfied by keeping that heading as a pointer section.
  - The SRE test at ~:669 asserts `"[:scrypath, :search]"`, `"[:scrypath, :meilisearch, :request]"`, `"[:scrypath, :operator, :failed_work, :observed]"`, `"alert fatigue"`, `"Disk free"`, `"skip_settings_verification?"`, `"Scrypath v1"` and `"guides/sync-modes-and-visibility.md"`. When the table moves out, either keep those event names in the SRE aggregation prose or retarget the first three assertions at the guide and add `"guides/telemetry.md"`.
- `ARCHITECTURE.md` "## Observability" bullet [VERIFIED: ARCHITECTURE.md ~170]: "Oban job lifecycle remains on Oban's own telemetry events. Scrypath emits search semantics, not a second queue lifecycle." Reword it so the worker spans read as search semantics (index, document counts, outcome, missing removals), with queue lifecycle (queue, job id, `state`) still on `[:oban, :job, *]`. No test asserts the old sentence (grep this session).
- `guides/related-data-and-reindexing.md` table row "Backend HTTP 4xx (e.g. bad request) | `{:cancel, ...}`" → `{:cancel, {:http_error, status}}` (D-18).

**Optional-key marker:** do **not** use a trailing `?`. `[:scrypath, :operator, :failed_work, :observed]` emits a real key named `retryable?` [VERIFIED: lib/scrypath/operator/failed_work/telemetry.ex:9-15, quoted: `reason_class: row.reason_class, schema: row.schema, mode: row.mode, operation: row.operation, retryable?: row.retryable?`], and that key is itself optional. Recommended: a literal suffix outside the backticks, e.g. `` `repo` (optional) ``. The parser reads each cell as a comma-separated list of `` `key` `` tokens, each with an optional ` (optional)` suffix. Exception keys go in a fixed prose rule ("every span's `:exception` carries start metadata plus `kind`, `reason`, `stacktrace`") rather than a column, so the six-column format from D-16 holds.

### Pattern 5: Drift test (prototyped and working this session)

Name scan: walk the quoted AST and collect list literals whose head is `:scrypath` and whose tail is all atoms. Doc strings are binaries in the AST, so moduledoc mentions are skipped automatically. Event names do appear in doc text in `lib/scrypath.ex:238`, `lib/scrypath/meilisearch/settings.ex:251` and the `lib/scrypath/operator/failed_work.ex` moduledoc [VERIFIED: grep].
```elixir
# Prototype run this session against lib/**/*.ex returned exactly 14 names
for f <- Path.wildcard("lib/**/*.ex"), reduce: MapSet.new() do
  acc ->
    {:ok, ast} = Code.string_to_quoted(File.read!(f), file: f)
    {_, acc} =
      Macro.prewalk(ast, acc, fn
        [:scrypath | rest] = node, acc when rest != [] ->
          if Enum.all?(rest, &is_atom/1), do: {node, MapSet.put(acc, node)}, else: {node, acc}
        node, acc -> {node, acc}
      end)
    acc
end
```
Prototype output: `[:scrypath, :hydration]`, `[:scrypath, :meilisearch, :request]`, `[:scrypath, :meilisearch, :task_wait]`, `[:scrypath, :operator, :failed_work, :observed]`, `[:scrypath, :reindex, :settings_verified]`, `[:scrypath, :reindex, :verify_skipped]`, `[:scrypath, :search]`, `[:scrypath, :search_facet_values]`, `[:scrypath, :search_many]`, `[:scrypath, :search_many, :partial]`, `[:scrypath, :settings, :hot_apply]`, `[:scrypath, :sync, :delete]`, `[:scrypath, :sync, :related, :resolve]`, `[:scrypath, :sync, :upsert]`. Count: 14.

Guard: match `{{:., _, [mod, fun]}, meta, [first | _]}` with `fun in [:span, :execute]`, where `mod` is `:telemetry` or `{:__aliases__, _, [:Telemetry]}` / `[:Scrypath, :Telemetry]`, and `first` is not a list literal. The prototype reports exactly one site: `lib/scrypath/telemetry.ex:11 :telemetry.span event_name`, the wrapper. Allowlist that one `{file, function}` explicitly. Note `lib/scrypath/operator/failed_work.ex:145` calls `Telemetry.emit/1`, where `Telemetry` is aliased to `Scrypath.Operator.FailedWork.Telemetry`. It is not `span`/`execute`, so the guard ignores it, but a regex-based guard would have to handle the alias too. Prefer the AST approach.

Guide table parse: take rows matching `` ^\| `\[:scrypath `` and run `Code.string_to_quoted!/1` on the backticked event cell to get the list. Assert `MapSet.equal?(scanned, documented)`, and on failure print both difference sets.

### Anti-Patterns to Avoid
- **Computing event names** (`prefix ++ [:upsert]`): it slips past the name scan and is rejected by the guard.
- **Putting the drift test in `docs_contract_test.exs`:** that file is excluded from required CI (Pitfall 1).
- **Using `Telemetry.stop_metadata/2` for worker results:** it adds `result_kind` and can overwrite `document_count`.
- **Emitting `missing_removed` before the delete chunks finish, or once per chunk:** this breaks D-10 and makes retries double-count.
- **Building `cancel_reason` with `String.to_atom`, or passing the tag tuple through:** forbidden by D-06 and D-08.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| start/stop/exception timing | manual `System.monotonic_time` and three `execute` calls | `Scrypath.Telemetry.span/3` → `:telemetry.span/3` | Re-raises correctly, adds `telemetry_span_context` for OTel parenting, and gives standard `duration` |
| Distinct id counting | `length(Enum.uniq(ids))` | `Chunks.distinct_count/1` | Uses the same `id_key/1` identity (`:a == "a"`, `1 != "1"`) as the delete chunks [VERIFIED: lib/scrypath/chunks.ex:45-50,57-61] |
| Finding event literals in source | regex over file text | `Code.string_to_quoted/2` plus `Macro.prewalk/3` | Skips doc strings and handles multi-line call sites, as `reindex.ex:137-147` and `tasks.ex:107-127` have |
| Building Oban jobs in tests | hand-rolled maps with nil `attempt` | `%Oban.Job{args: args, attempt: 1, max_attempts: 8}` or `Oban.Testing.build_job(worker, args, attempt: n)` | `build_job/3` sets `attempt: 1` by default and needs no repo [VERIFIED: deps/oban/lib/oban/testing.ex:200-218] |

## Runtime State Inventory

Not a rename phase. The only stored-data effect is D-18: Oban's `errors` column for *future* cancelled related jobs will hold `{:http_error, 400}` instead of `"HTTP 400: \"…body…\""`. Existing rows are untouched and need no migration.
- Stored data: none to migrate. Verified that `Scrypath.Operator.FailedWork.Translation` classifies queue error text by substring and regex. The transport regex `~r/\b(401|403|408|429|50[0-9])\b/` matches the status in both old and new forms, and 400 is `:unknown` in both [VERIFIED: lib/scrypath/operator/failed_work/translation.ex:248-262]. So D-18 does not change classification.
- Live service config: none.
- OS-registered state: none.
- Secrets and env vars: none.
- Build artifacts: none.
- `scrypath_ops`: the only "HTTP #{status}" string is `posture_live.ex:618`, which is unrelated UI copy. Nothing parses the related-worker cancel string [VERIFIED: grep scrypath_ops/lib].

## Common Pitfalls

### Pitfall 1: The drift test never runs in CI
**What goes wrong:** the contract test is green locally but never enforced.
**Why it happens:** `@moduletag :docs_contract` [VERIFIED: test/scrypath/docs_contract_test.exs:3], and CI `core` runs `mix verify.core --exclude integration --exclude docs_contract` [VERIFIED: .github/workflows/ci.yml:35]. CONTRIBUTING says the docs contract suite "is no longer part of the default CI and release gates".
**How to avoid:** put names, guard and keys in a new **untagged** `test/scrypath/telemetry_contract_test.exs` (async: false). Hygiene edits to `docs_contract_test.exs` are fine, but they are not the enforcement point.
**Warning signs:** a PR changes an event name and `core` stays green.

### Pitfall 2: The strict key check trips on telemetry's own keys
**What goes wrong:** "emitted ⊆ documented" fails on keys nobody documented.
**Why it happens:** `:telemetry.span` adds `telemetry_span_context` to start, stop and exception metadata, and exception metadata adds `kind`, `reason` and `stacktrace` [VERIFIED: deps/telemetry/src/telemetry.erl:242, 275, 310, 341-342, 384].
**How to avoid:** use a fixed implicit set: `[:telemetry_span_context]` on every span event, plus `[:kind, :reason, :stacktrace]` on `:exception`. For the D-08 "no tuple or list values" assertion, skip `stacktrace` (a list), `reason` (any term) and `telemetry_span_context` (a ref).

### Pitfall 3: `attempt: 0` in tests
**What goes wrong:** the pos_integer assertion fails, or tests silently document `0`.
**Why it happens:** the `Oban.Job` schema has `field :attempt, :integer, default: 0` and `field :max_attempts, :integer, default: 20` [VERIFIED: deps/oban/lib/oban/job.ex:142,144]. Existing worker tests call `perform(%Oban.Job{args: args})` [VERIFIED: test/scrypath/oban/worker_test.exs:142ff]. Real execution always has attempt ≥ 1.
**How to avoid:** new tests pass `attempt:` and `max_attempts: 8` explicitly. The worker passes the struct values through and does not clamp them.

### Pitfall 4: Duplicate ids inflate counts
**What goes wrong:** `missing_removed.count` or `document_count` exceeds the ids actually sent.
**Why it happens:** `Loader.load/3` computes `missing = Enum.reject(document_ids, &MapSet.member?(found, to_string(&1)))`, which keeps duplicates [VERIFIED: lib/scrypath/loader.ex ~99-103], while the delete chunks dedupe (`Chunks.ids/1`). Enqueue dedupes via `Chunks.ids()` [VERIFIED: lib/scrypath/oban/enqueue.ex:29,48], but job args are editable stored input.
**How to avoid:** use `Chunks.distinct_count/1` for `document_count`, `missing_count` and the event `count`. This matches the sync-span WR-05 rule ("sync span start and stop report the same deduped document_count") [VERIFIED: test/scrypath/telemetry_test.exs:107].

### Pitfall 5: Handlers leak between tests
**What goes wrong:** flaky cross-test events, or a handler is silently detached.
**Why it happens:** handlers are global. The existing `capture_events/2` detaches only after `fun.()` returns normally [VERIFIED: test/scrypath/telemetry_test.exs:350-369]. A handler that raises is detached by telemetry, which emits `[:telemetry, :handler, :failure]` instead [VERIFIED: deps/telemetry/src/telemetry.erl:211-215].
**How to avoid:** use `async: false`, a unique handler id, and `on_exit(fn -> :telemetry.detach(id) end)`. Keep the handler a plain `send/2`. The new helper must accept **full** event names, because the existing helper only appends `:start`/`:stop`/`:exception` and could never attach `:missing_removed`. `test/scrypath/oban/worker_test.exs` is `async: true`, so put the telemetry assertions in a new file instead of adding them there.

### Pitfall 6: The exception scenario
**What goes wrong:** no `:exception` event is ever observed.
**Why it happens:** workers return `{:error, _}` rather than raising (D-07).
**How to avoid:** use a test backend whose `upsert_documents/3` (and `delete_documents/3` for the delete worker) raises. Wrap the call in `assert_raise`. The span re-raises.

### Pitfall 7: Docs build and the package lane
**What goes wrong:** the `package` lane or `mix docs --warnings-as-errors` fails.
**Why it happens:** the exact Operations list assertion (Pattern 4), or a link to `telemetry.md` from a doc built before the extra was registered.
**How to avoid:** change mix.exs, the package metadata test and the links in the same plan.

### Pitfall 8: CHANGELOG mechanics conflict with Release Please
**What goes wrong:** a hand-edited CHANGELOG fights Release Please. The `## [Unreleased]` block at CHANGELOG.md:127 is historical residue.
**Why it happens:** Release Please owns CHANGELOG.md. Phase 179 resolved this by **not** editing CHANGELOG and carrying the notes into the PR body, the squash-commit body and the release PR [VERIFIED: .planning/phases/179-…/179-06-SUMMARY.md:32, 179-RESEARCH.md:588-590].
**How to avoid:** see Open Question 1. Recommended: a conventional `feat(telemetry): …` squash subject so Release Please writes the Features entry, plus the D-18 "Changed" sentence in the PR body for the release PR.

## Code Examples

### Capture helper (test/support)
```elixir
defmodule Scrypath.TestSupport.TelemetryCapture do
  import ExUnit.Callbacks, only: [on_exit: 1]

  def attach(event_names) do
    parent = self()
    id = "scrypath-capture-#{System.unique_integer([:positive])}"
    :ok = :telemetry.attach_many(id, event_names, &__MODULE__.handle/4, parent)
    on_exit(fn -> :telemetry.detach(id) end)
    id
  end

  def handle(name, measurements, metadata, parent),
    do: send(parent, {:telemetry_event, name, measurements, metadata})
end
```
`test/support/**/*.ex` is loaded by `test_helper.exs` via `Code.require_file/1` [VERIFIED: test/test_helper.exs]. Use the full-name list, e.g. `for s <- [:start, :stop, :exception], k <- [:upsert, :delete], do: [:scrypath, :oban, k, s]` plus `[:scrypath, :oban, :upsert, :missing_removed]`. A plain module function avoids telemetry's local-function performance warning.

### Scenario: success with missing ids (OBS-02)
Reuse the existing pattern of a `search_records/2` schema that drops id 404 [VERIFIED: test/scrypath/oban/worker_test.exs:68-80: `Enum.map(ids -- [404], &%__MODULE__{id: &1, title: "Loaded #{&1}"})`]. Run `UpsertWorker.perform(%Oban.Job{args: upsert_args(LoaderPost, RecordingBackend, [1, 404]), attempt: 2, max_attempts: 8})`. Then assert:
- one `missing_removed` with `%{count: 1}`
- stop `outcome: :ok`, `source: :loaded`, `upserted_count: 1`, `missing_count: 1`, `document_count: 2`, `sync_mode: :oban`, `attempt: 2`

Also add a 1,500-missing-id case: one event, `count: 1500`. And a failing second delete chunk: no event, `outcome: :error`, `error_kind: :timeout`.

### Scenario: cancel inside the boundary
Use a `search_records/2` that returns a non-list. The existing fixture is `BrokenLoaderPost` [VERIFIED: test/scrypath/oban/worker_test.exs:94-104]. Expect stop `outcome: :cancel`, `cancel_reason: :invalid_search_records`, with no `source`. Also run a decode failure (e.g. a bad `"index"`) and assert **no** `[:scrypath, :oban, *]` event fires.

### Scenario: legacy snapshot
Use the `"documents"` snapshot fixture the existing tests already build, with a schema whose load returns `:repo_required` or `:search_records_required`. Expect `source: :legacy_snapshot`, `missing_count: 0`, and no `missing_removed`.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Oban reported `{:cancel, _}` as an exception (older Oban) | `:ok`, `:cancelled` and `:snoozed` count as success and emit `[:oban, :job, :stop]` with `state: :cancelled`; `{:error, _}` and raises emit `:exception` with `state: :failure` | present in locked 2.23.0 | Confirms D-02/D-16 guide wording [VERIFIED: deps/oban/lib/oban/telemetry.ex:24-47, deps/oban/lib/oban/queue/executor.ex:145-162] |

Oban's job-event `state` vocabulary is quoted verbatim from `deps/oban/lib/oban/telemetry.ex:47`: "`:state` — one of `:success`, `:failure`, `:cancelled`, `:discard` or `:snoozed`". Note that a `{:error, _}` return is `state: :failure`, not `:exception`. `:exception` is the event suffix. The guide's join section should say exactly that.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Release Please will generate an acceptable "Features" entry from a `feat(telemetry):` squash subject, so CHANGELOG.md need not be hand-edited [ASSUMED from the Phase 179 precedent] | Pitfall 8 | Low: the release PR can be edited by hand, as in 0.3.16 |
| A2 | ExDoc builds `guides/telemetry.md` as `telemetry.html` with no collision, because `Scrypath.Telemetry` is `@moduledoc false` and gets no page [ASSUMED] | Pattern 4 | Low: `mix docs --warnings-as-errors` would surface it |

## Open Questions

1. **CHANGELOG (D-19) vs the Release Please precedent.**
   - What we know: D-19 asks for "Added"/"Changed" entries. Release Please owns CHANGELOG.md, and Phase 179 chose not to edit it (OQ6).
   - Recommendation: honor D-19's *content* through the conventional commit subject plus the PR-body "Changed" note for D-18, and do not add an `## Unreleased` section. If the maintainer wants a hand edit, put it on the release PR. The planner should state this choice in the plan rather than silently drop D-19.
2. **Optional-key marker.**
   - The trailing `?` from D-16 is ambiguous with `retryable?`. Recommendation: `` `key` (optional) ``. This is within discretion, since D-16 says "e.g.".
3. **D-02's `{:unknown_repo, name}` "if it resolves inside the boundary".** It does not: `fetch_repo/1` runs inside `decode_upsert/1` [VERIFIED: lib/scrypath/oban/job_args.ex:27-41,139-155]. So `cancel_reason: :unknown_repo` never appears on a worker span. The guide should list only the in-boundary values: `:repo_required`, `:search_records_required`, `:invalid_search_records`, `:invalid_arg`. The `cancel_reason/1` helper may still handle any `{atom, _}` shape.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir / OTP | everything | ✓ | 1.19.5 / OTP 28 (with `ASDF_ERLANG_VERSION=28.5 ASDF_ELIXIR_VERSION=1.19.5-otp-28`) | — |
| oban (dep) | worker tests | ✓ | 2.23.0 in deps | — |
| Meilisearch / Postgres | not needed: all tests use in-process recording backends | — | — | — |

Baseline this session: `mix test test/scrypath/oban/worker_test.exs test/scrypath/telemetry_test.exs test/scrypath/sync/related_worker_test.exs` gave 57 tests, 0 failures, in 0.6s.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.19.5 / OTP 28) |
| Config file | `test/test_helper.exs` (loads `test/support/**/*.ex`) |
| Quick run command | `mix test test/scrypath/oban/worker_telemetry_test.exs test/scrypath/telemetry_contract_test.exs test/scrypath/telemetry_test.exs test/scrypath/oban/worker_test.exs test/scrypath/sync/related_worker_test.exs` |
| Full suite command | `mix verify.core --exclude integration --exclude docs_contract` plus `mix test test/scrypath/docs_contract_test.exs test/release/package_metadata_test.exs` plus `mix verify.no_optional_deps` plus `mix docs --warnings-as-errors` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| OBS-01 | upsert and delete start/stop carry schema, backend, index, `sync_mode: :oban`, attempt, max_attempts, document_count; stop has `outcome` | unit | `mix test test/scrypath/oban/worker_telemetry_test.exs` | ❌ Wave 0 |
| OBS-01 | `{:error, _}` → `outcome: :error`, `error_kind`; in-boundary cancel → `cancel_reason` atom; decode failure → no Scrypath event | unit | same | ❌ Wave 0 |
| OBS-01 | a raising backend → `:exception` with start metadata plus kind/reason/stacktrace | unit | same | ❌ Wave 0 |
| OBS-01 | `job_stop_metadata/1` mapping, including the `{:invalid_job, {:invalid_arg, "x"}}` → `:invalid_arg` flattening | unit | `mix test test/scrypath/telemetry_test.exs` | ✅ (extend) |
| OBS-02 | missing ids → one `missing_removed` with `count` = distinct missing; 1,500 → one event; failed chunk → none; legacy → none; zero missing → none | unit | `mix test test/scrypath/oban/worker_telemetry_test.exs` | ❌ Wave 0 |
| OBS-03 | guide event set == AST-scanned `lib/` set (both directions) | contract | `mix test test/scrypath/telemetry_contract_test.exs` | ❌ Wave 0 |
| OBS-03 | every span/execute call uses a literal name (allowlist: the wrapper in `telemetry.ex`) | contract | same | ❌ Wave 0 |
| OBS-03 | for the 3 new events across 5 scenarios: required ⊆ emitted ⊆ required ∪ optional ∪ implicit; no tuple or list tag values | contract | same | ❌ Wave 0 |
| OBS-03 | guide in extras and the Operations group; hygiene (no OBS-NN) | contract | `mix test test/release/package_metadata_test.exs test/scrypath/docs_contract_test.exs` | ✅ (extend) |
| D-18 | related worker 4xx → `{:cancel, {:http_error, 400}}` | unit | `mix test test/scrypath/sync/related_worker_test.exs` | ✅ (edit ~:503) |

Negative-proof suggestion for the contract test: make the parser and scanner pure functions that take the guide text and a list of source strings. A unit case can then feed a guide missing one row and assert the diff names it, which proves the test can fail without mutating repo files.

### Sampling Rate
- **Per task commit:** the quick run command.
- **Per wave merge:** quick run plus `mix compile --warnings-as-errors`, `mix credo --strict`, `mix format --check-formatted`, `mix verify.no_optional_deps` and `mix docs --warnings-as-errors`.
- **Phase gate:** full suite green locally, then hosted PR checks green on the exact SHA (`core`, `package`, `repository-contracts`, `backend`).

### Wave 0 Gaps
- [ ] `test/support/telemetry_capture.ex`: full-name capture helper with `on_exit` detach
- [ ] `test/support/oban_telemetry_scenarios.ex` (or private to the test files): recording, failing-second-delete-chunk and raising backends; loader schemas; scenario runner shared by the worker and contract tests
- [ ] `test/scrypath/oban/worker_telemetry_test.exs`: covers OBS-01 and OBS-02
- [ ] `test/scrypath/telemetry_contract_test.exs`: covers OBS-03, untagged

## Security Domain

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | yes | Job args are untrusted stored input. Never create atoms from them, and never put tag second elements in metadata (`cancel_reason/1` keeps only the atom head) |
| V6 Cryptography | no | — |
| V7 Error handling and logging | yes | No error bodies or ids in metadata (D-08). D-18 stops persisting backend bodies in Oban `errors` |

### Known Threat Patterns
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Document content or PII leaking into telemetry or Oban errors through HTTP bodies | Information disclosure | Counts and atoms only. `{:cancel, {:http_error, status}}` without the body |
| Atom-table exhaustion through job-arg-derived tags | DoS | Tags come from fixed atoms in code. `cancel_reason/1` pattern-matches and never calls `String.to_atom` |
| Metric-cardinality blowup (ids or job_id as tags) | DoS (observability backend) | D-05 excludes `job_id`. The D-08 test rejects tuple and list values |

## Sources

### Primary (HIGH confidence; read this session)
- `lib/scrypath/telemetry.ex`, `lib/scrypath/oban/{upsert_worker,delete_worker,job_args,indexing_ack}.ex`, `lib/scrypath/chunks.ex`, `lib/scrypath/loader.ex`, `lib/scrypath/sync/related_worker.ex`, `lib/scrypath/operator/failed_work{,/telemetry,/translation}.ex`, `lib/scrypath/{reindex,search,hydration}.ex`, `lib/scrypath/search/{single,many,facet_values}.ex`, `lib/scrypath/meilisearch/tasks.ex`
- `mix.exs`, `mix.lock`, `.github/workflows/ci.yml`, `lib/mix/tasks/verify{,.no_optional_deps,.phase99}.ex`, `lib/mix/tasks/verify/capability.ex`
- `test/scrypath/{docs_contract,telemetry}_test.exs`, `test/scrypath/oban/worker_test.exs`, `test/scrypath/sync/related_worker_test.exs`, `test/release/package_metadata_test.exs`, `test/test_helper.exs`
- `deps/oban/lib/oban/{telemetry,job,testing}.ex`, `deps/oban/lib/oban/queue/executor.ex` (Oban 2.23.0)
- `deps/telemetry/src/telemetry.erl` (telemetry 1.4.2)
- AST-scan prototype run this session, kept in the scratchpad (not committed)

### Secondary
- Phase 179 RESEARCH, SUMMARY and VALIDATION, for verify commands and the CHANGELOG precedent

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH. No new deps; versions read from mix.lock.
- Architecture: HIGH. Every insertion point was read; the scan and guard were prototyped.
- Pitfalls: HIGH. Each one is tied to a quoted file and line.

**Research date:** 2026-10-25
**Valid until:** 2026-11-24 (stable; re-check if Oban or telemetry are bumped)
