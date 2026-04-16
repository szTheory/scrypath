# Phase 4: Oban and Observability - Research

**Researched:** 2026-04-15
**Domain:** Oban-backed async sync and Telemetry instrumentation for an Elixir OSS library
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Oban-backed async sync should remain on the existing `Scrypath.*` sync verbs through `sync_mode: :oban`.
- **D-02:** Phase 4 should not introduce a second full public sync API under `Scrypath.Oban.*`; the common verbs remain the primary runtime surface.
- **D-03:** Scrypath should add a narrow `Scrypath.Oban` helper only for transactional enqueue composition in `Ecto.Multi` / `Repo.transact`.
- **D-04:** Oban configuration and queue-specific options should stay explicit and local to the call or explicit defaults, not hidden behind magical global behavior.
- **D-05:** If `sync_mode: :oban` is used without the required dependency or runtime configuration, Scrypath should fail clearly and directly.

### Async job payload and execution model
- **D-06:** Phase 4 should use separate operation-specific workers, centered on an upsert worker and a delete worker.
- **D-07:** Upsert jobs should carry normalized, JSON-safe projected document payloads rather than source-row reload instructions.
- **D-08:** Delete jobs should carry resolved document ids plus index context and must not reload deleted rows.
- **D-09:** Projection and identity resolution should stay in the explicit application-side orchestration path before enqueue, not move into hidden worker reload logic.
- **D-10:** `:manual` and `:oban` should preserve the same normalized sync semantics; only execution strategy and durability guarantees change.
- **D-11:** Batch semantics in `:oban` mode should follow the caller's explicit API shape such as `sync_records/3` and `delete_documents/3`, not hidden cross-job aggregation.
- **D-12:** Oban job args must stay JSON-safe and validation-friendly; do not serialize Ecto structs or atom-keyed opaque terms into jobs.
- **D-13:** Phase 4 should not make debounce or buffer-flush orchestration the default async model; heavier batching strategy can be revisited in later operational phases.

### Telemetry surface and event naming
- **D-14:** Scrypath should expose a layered Telemetry model: stable common-path spans on `Scrypath.*` plus explicit backend-specific spans under `Scrypath.Meilisearch.*`.
- **D-15:** Public workflow events should use `:telemetry.span/3` conventions with `:start`, `:stop`, and `:exception` semantics rather than outcome-specific event names.
- **D-16:** Common Telemetry metadata must stay low-cardinality and stable, centered on fields such as schema, backend, sync mode, index, repo, document count, hit count, and missing count where relevant.
- **D-17:** Meilisearch-specific details such as task uid, task status, request ids, poll counts, and backend wait timing should live only on explicit Meilisearch event prefixes, not on the common event contract.
- **D-18:** Scrypath should emit batch- or workflow-level events, not one public Telemetry event per record.

### Consistency and operator contract
- **D-19:** Phase 4 docs should define sync modes through an explicit contract matrix, not through a vague "automatic background sync" story.
- **D-20:** `sync_mode: :inline` means Scrypath waits for terminal backend task success before returning success, while still documenting that DB and search are not atomic.
- **D-21:** `sync_mode: :manual` means Scrypath accepts work intentionally and returns control immediately for operator-controlled execution.
- **D-22:** `sync_mode: :oban` means durable enqueue accepted, not search visibility completed; a successful enqueue does not mean the document is already searchable.
- **D-23:** Phase 4 should document one shared async lifecycle for operators: `requested -> enqueued -> processing -> backend_accepted -> completed | retrying | discarded`.
- **D-24:** Retry exhaustion, discarded jobs, stale deletes, and search drift are normal operational realities that must be documented plainly rather than treated as rare edge cases.

### Claude's Discretion
- Exact worker module names, option names, and internal payload field layout, as long as the public semantics above remain intact.
- Exact retry classification and backoff defaults, as long as transient failures retry and permanent data-shape or config errors do not loop forever.
- Exact stable common Telemetry metadata field names and result-struct shape, as long as the public instrumentation contract stays small, low-cardinality, and explicit.

### Deferred Ideas (OUT OF SCOPE)
- Source-id reload workers that reload rows and re-project inside the job — deferred because they conflict with the current explicit projection and preload posture.
- Debounce or buffer-flush worker orchestration as the default async path — deferred to later operational or reindex phases where higher-volume batching is first-class scope.
- A separate companion package such as `scrypath_oban` — deferred because it would add adoption friction for a core v1 sync mode.
- A second full public API under `Scrypath.Oban.*` for normal sync verbs — deferred because it would fragment the product surface and weaken the existing `sync_mode` model.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SYNC-05 | Developer can choose Oban-backed asynchronous synchronization for production workflows. | Common sync verbs stay under `Scrypath.*`; `sync_mode: :oban` enqueues `Scrypath.Oban.UpsertWorker` and `Scrypath.Oban.DeleteWorker`; `Scrypath.Oban` only adds transaction helpers. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/oban/Oban.html] |
| OPER-04 | Developer can observe indexing and query workflows through Telemetry events. | Use common `:telemetry.span/3` events under `[:scrypath, ...]` plus backend spans under `[:scrypath, :meilisearch, ...]`; rely on Oban’s existing `[:oban, :job, ...]` events for queue/job lifecycle rather than duplicating them. [CITED: https://hexdocs.pm/telemetry/telemetry.html] [CITED: https://hexdocs.pm/oban/Oban.Telemetry.html] |
</phase_requirements>

## Summary

Scrypath already centralizes sync orchestration in `Scrypath.Sync`, keeps projected documents explicit through `Scrypath.Projection`, and treats `:oban` as an accepted-but-not-implemented mode. Phase 4 should keep that architecture intact: resolve documents or delete ids before enqueue, enqueue batch-shaped jobs through Oban, and let workers only execute backend work against normalized payloads. [VERIFIED: codebase grep]

Oban is the right production async path here because it supports inserting jobs directly and into `Ecto.Multi`, stores job args as JSON with string keys, provides retry/backoff/discard semantics at the worker layer, and already emits job lifecycle telemetry. That means Scrypath can stay focused on search semantics, payload normalization, and library-specific instrumentation instead of reimplementing queue durability or job execution state. [CITED: https://hexdocs.pm/oban/Oban.html] [CITED: https://hexdocs.pm/oban/Oban.Worker.html] [CITED: https://hexdocs.pm/oban/Oban.Telemetry.html]

The public recommendation is: keep one sync API under `Scrypath.*`, add only a narrow `Scrypath.Oban` helper for transactional enqueue composition, emit workflow spans with low-cardinality metadata, and document eventual consistency and drift as normal operational behavior. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/telemetry/telemetry.html]

**Primary recommendation:** Implement `sync_mode: :oban` by enqueueing projected batch jobs through two dedicated workers, then add span-based instrumentation around common sync/search flows and explicit Meilisearch wait/request boundaries. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/oban/Oban.Worker.html] [CITED: https://hexdocs.pm/telemetry/telemetry.html]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Sync API orchestration | API / Backend | Database / Storage | Scrypath’s sync verbs already live in `Scrypath.Sync`; enqueue decisions and payload normalization belong in library runtime code, while durability is delegated to Oban’s datastore-backed queue. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/oban/Oban.html] |
| Durable async job storage | Database / Storage | API / Backend | Oban persists jobs and controls retries/discards through its job table and engine, while Scrypath only builds job changesets and interprets outcomes. [CITED: https://hexdocs.pm/oban/Oban.html] [CITED: https://hexdocs.pm/oban/error_handling.html] |
| Worker execution of backend writes | API / Backend | Database / Storage | Oban workers execute Scrypath logic and call backend modules; they should not own source-row reads or business transactions. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/oban/Oban.Worker.html] |
| Search/indexing telemetry spans | API / Backend | — | The library owns sync/search semantics, so it should emit `[:scrypath, ...]` and backend spans there while consuming, not replacing, Oban’s own job events. [CITED: https://hexdocs.pm/telemetry/telemetry.html] [CITED: https://hexdocs.pm/oban/Oban.Telemetry.html] |
| Transactional enqueue composition | API / Backend | Database / Storage | `Ecto.Multi` or `Repo.transact/2` should compose data persistence and Oban job insertion in one DB transaction when callers want post-commit durability guarantees. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] [CITED: https://hexdocs.pm/oban/Oban.html] |

## Project Constraints (from AGENTS.md / project context)

- Keep the public v1 backend target Meilisearch-first and do not recommend a fake public multi-backend facade. [VERIFIED: codebase grep]
- Keep sync modes explicit and operationally honest; `:inline`, `:manual`, and `:oban` are product scope. [VERIFIED: codebase grep]
- Optimize for minimal setup and Phoenix/Ecto ergonomics without hiding eventual consistency, delete semantics, backfills, or drift. [VERIFIED: codebase grep]
- Keep Oban optional; the core path must remain lightweight. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.html]

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `oban` | `2.21.1` published `2026-03-26` [CITED: https://hex.pm/api/packages/oban] | Durable async job execution, retries, uniqueness, and `Ecto.Multi` insertion. [CITED: https://hexdocs.pm/oban/Oban.html] | It is the documented, transaction-friendly queue primitive for Elixir apps and matches the project’s locked Oban-first production path. [CITED: https://hexdocs.pm/oban/Oban.html] [VERIFIED: codebase grep] |
| `telemetry` | `1.4.1` published `2026-03-09` [CITED: https://hex.pm/api/packages/telemetry] | Span/event emission for sync and search workflows. [CITED: https://hexdocs.pm/telemetry/telemetry.html] | `:telemetry.span/3` gives the exact start/stop/exception convention Phase 4 locked in. [CITED: https://hexdocs.pm/telemetry/telemetry.html] |
| `ecto` | `3.13.5` published `2025-11-09` [CITED: https://hex.pm/api/packages/ecto] | Transaction composition through `Repo.transact/2` and `Ecto.Multi`. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] | Scrypath is explicitly Ecto-first, and `Ecto.Multi` is the right boundary for transactional enqueue helpers. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] |
| `req` | `0.5.17` published `2026-01-05` [CITED: https://hex.pm/api/packages/req] | Existing Meilisearch transport layer. [VERIFIED: codebase grep] | Phase 4 instrumentation should wrap the existing client/request path rather than replace HTTP transport. [VERIFIED: codebase grep] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `oban/testing` | bundled with `oban 2.21.1`. [CITED: https://hexdocs.pm/oban/testing_workers.html] | Unit-test workers with `perform_job/3` and integration-test queue execution. [CITED: https://hexdocs.pm/oban/testing_workers.html] | Use in worker and enqueue tests once Oban is added as an optional dependency. [CITED: https://hexdocs.pm/oban/testing_workers.html] |
| `:telemetry` handlers in ExUnit | existing package. [VERIFIED: codebase grep] | Assert emitted spans and metadata without adding another dependency. [CITED: https://hexdocs.pm/telemetry/telemetry.html] | Use for common-path and backend span assertions in library tests. [CITED: https://hexdocs.pm/telemetry/telemetry.html] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Oban workers with projected payloads | source-row reload jobs | Reload jobs conflict with Scrypath’s explicit projection/delete-id contract and break safe delete semantics after the row is gone. [VERIFIED: codebase grep] |
| Common sync API plus narrow `Scrypath.Oban` helper | second public `Scrypath.Oban.*` runtime API | A second verb family would fragment the product surface and contradict the locked `sync_mode` design. [VERIFIED: codebase grep] |
| `:telemetry.span/3` common spans | ad hoc `*_started` / `*_failed` event names | Span conventions already define start/stop/exception structure and keep handlers simpler. [CITED: https://hexdocs.pm/telemetry/telemetry.html] |

**Installation:**

```bash
mix hex.info oban
# latest: 2.21.1
```

```elixir
{:oban, "~> 2.21", optional: true}
```

`optional: true` is the correct dependency shape for Scrypath because Mix keeps optional deps available to this project while downstream dependants are not forced to include them. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.html]

## Architecture Patterns

### System Architecture Diagram

```text
Caller / Context
  |
  | Scrypath.sync_record(s) / delete_*
  v
Scrypath.Sync
  |
  |-- normalize config ------------------------------.
  |-- project documents / resolve delete ids         |
  |-- emit [:scrypath, :sync, op, *] span           |
  |                                                 |
  |--> :inline --> backend.* --> wait task --> return completed
  |                                                 |
  |--> :manual --> backend.* -----------> return accepted
  |                                                 |
  `--> :oban --> Scrypath.Oban enqueue helper ------+--> Oban jobs table
                                                       |
                                                       v
                                                 Oban Worker
                                                       |
                                                       | emit [:scrypath, :oban, worker, *]
                                                       v
                                            Scrypath backend execution
                                                       |
                                                       | emit [:scrypath, :meilisearch, *]
                                                       v
                                                  Meilisearch task API
```

`sync_mode: :oban` should stop at durable enqueue acceptance; backend visibility happens later in the worker lifecycle. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/oban/Oban.html]

### Recommended Project Structure

```text
lib/
├── scrypath/
│   ├── sync.ex                  # common sync orchestration + common telemetry
│   ├── telemetry.ex             # common span helpers and metadata normalization
│   ├── oban.ex                  # narrow public helper for Ecto.Multi / Repo.transact composition
│   └── oban/
│       ├── payload.ex           # JSON-safe payload builders/validators
│       ├── enqueue.ex           # internal job changeset builders
│       ├── upsert_worker.ex     # projected document batch execution
│       └── delete_worker.ex     # resolved delete-id batch execution
└── scrypath/meilisearch/
    ├── client.ex                # existing transport; add backend-specific spans
    └── tasks.ex                 # existing wait path; add backend-specific wait spans
```

This split maps cleanly onto 2-4 plans: common sync + result shape, Oban integration/helper, telemetry instrumentation, and docs/tests. [VERIFIED: codebase grep]

### Pattern 1: Pre-Project Before Enqueue
**What:** Build `Scrypath.Document` structs or delete-id lists before creating Oban jobs. [VERIFIED: codebase grep]  
**When to use:** Always for `sync_mode: :oban`; never reload source rows in the worker. [VERIFIED: codebase grep]  
**Example:**

```elixir
# Source: existing Scrypath.Sync + Oban JSON args docs
documents = Enum.map(records, &Scrypath.Projection.document(schema_module, &1))
args = Scrypath.Oban.Payload.upsert_args(schema_module, documents, config)
job = Scrypath.Oban.UpsertWorker.new(args, queue: :scrypath)
```

Source basis: [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/oban/Oban.Worker.html]

### Pattern 2: Transactional Enqueue Helper
**What:** Provide a narrow public helper that returns `Ecto.Multi.t()` with job inserts, or adds them onto an existing multi. [CITED: https://hexdocs.pm/oban/Oban.html]  
**When to use:** When callers want “DB commit implies job enqueue” semantics. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html]  
**Example:**

```elixir
# Source: Ecto.Multi + Oban insert/insert_all docs, adapted to Scrypath boundary
multi
|> Scrypath.Oban.enqueue_sync(:search_sync, Post, [post], backend: Scrypath.Meilisearch)
|> Repo.transact()
```

Source basis: [CITED: https://hexdocs.pm/oban/Oban.html] [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html]

### Pattern 3: Layered Telemetry
**What:** Emit common spans around sync/search workflows and explicit backend spans for Meilisearch request/wait detail. [CITED: https://hexdocs.pm/telemetry/telemetry.html]  
**When to use:** For `Scrypath.Sync`, `Scrypath.Search`, `Scrypath.Meilisearch.Client`, and `Scrypath.Meilisearch.Tasks`. [VERIFIED: codebase grep]  
**Example:**

```elixir
# Source: telemetry span/3 docs, adapted to Scrypath event model
:telemetry.span([:scrypath, :sync, :upsert], start_meta, fn ->
  case do_dispatch() do
    {:ok, result} ->
      {{:ok, result}, %{status: result.status}}

    {:error, reason} ->
      reraise reason, __STACKTRACE__
  end
end)
```

Source basis: [CITED: https://hexdocs.pm/telemetry/telemetry.html]

### Anti-Patterns to Avoid

- **Reload-in-worker design:** It breaks delete safety and violates the current projection contract. [VERIFIED: codebase grep]
- **Per-record public events:** High-cardinality event streams make handlers and dashboards noisy; Phase 4 explicitly wants batch/workflow events. [VERIFIED: codebase grep]
- **Mirroring Oban lifecycle with custom queue-state events:** Oban already emits `[:oban, :job, ...]`; Scrypath should emit search semantics instead. [CITED: https://hexdocs.pm/oban/Oban.Telemetry.html]
- **Global magical Oban config:** Queue name, uniqueness, and Oban instance should remain explicit options or explicit defaults. [VERIFIED: codebase grep]

## Recommended Payload and Worker Contract

Use two workers only in Phase 4: `Scrypath.Oban.UpsertWorker` and `Scrypath.Oban.DeleteWorker`. Separate workers preserve clear retry semantics and let payload validation stay operation-specific. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/oban/Oban.Worker.html]

Recommended job args:

| Worker | Required args | Notes |
|--------|---------------|-------|
| Upsert | `"schema"`, `"backend"`, `"index"`, `"document_ids"`, `"documents"`, `"sync_mode"` | `"documents"` should be a list of `%{"id" => ..., "data" => ..., "source" => ...}` maps serialized from `Scrypath.Document`. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/oban/Oban.Worker.html] |
| Delete | `"schema"`, `"backend"`, `"index"`, `"document_ids"`, `"sync_mode"` | No `"documents"` field; delete jobs must delete directly by resolved ids. [VERIFIED: codebase grep] |

Keep all keys as strings in tests and worker pattern matches because Oban stores args as JSON and stringifies keys. [CITED: https://hexdocs.pm/oban/Oban.Worker.html]

Keep `"schema"` and `"backend"` as module-name strings, then resolve with `Module.concat/1` only after validation. That keeps args JSON-safe while still letting workers rehydrate the already-declared runtime modules. [CITED: https://hexdocs.pm/oban/Oban.Worker.html] [ASSUMED]

Recommended enqueue-time options:

| Option | Owner | Recommendation |
|--------|-------|----------------|
| `oban` / `oban_name` | runtime config | Allow explicit Oban instance selection; default to `Oban` if loaded. [CITED: https://hexdocs.pm/oban/Oban.html] [ASSUMED] |
| `oban_queue` | runtime config | Default to a Scrypath-specific queue such as `:scrypath`; keep override explicit. [ASSUMED] |
| `oban_max_attempts` | worker/job defaults | Default lower than Oban’s generic 20 for sync jobs, e.g. `8`, because sync drift should surface within operationally reasonable time. [CITED: https://hexdocs.pm/oban/Oban.Worker.html] [ASSUMED] |
| `oban_unique` | job options | Default to uniqueness over worker + args for a short period to reduce duplicate enqueue storms, but only for single logical batches, not cross-call aggregation. [CITED: https://hexdocs.pm/oban/Oban.Worker.html] [ASSUMED] |

## Retry and Failure Semantics

Treat transport failures, transient Meilisearch unavailability, and task processing failures as retryable. Those failures are external-system failures, and Oban’s normal retry path is the right mechanism. [CITED: https://hexdocs.pm/oban/error_handling.html] [ASSUMED]

Treat payload-shape errors, missing backend module, missing Oban dependency/configuration, and impossible module resolution as terminal. Return `{:cancel, reason}` so the job stops retrying and lands in a non-retrying terminal state instead of looping forever. [CITED: https://hexdocs.pm/oban/Oban.Worker.html] [CITED: https://hexdocs.pm/elixir/Code.html] [ASSUMED]

Do not map discarded jobs to fake success in Scrypath telemetry or docs. Discarded jobs are drift indicators and should be documented as requiring operator recovery. [CITED: https://hexdocs.pm/oban/error_handling.html] [VERIFIED: codebase grep]

## Telemetry Event Model

### Common events

Use these stable public spans:

| Event Prefix | When | Stable metadata | Stable measurements |
|--------------|------|-----------------|---------------------|
| `[:scrypath, :sync, :upsert]` | `sync_record/3` or `sync_records/3` common path | `schema`, `backend`, `sync_mode`, `index`, `document_count`, `document_source` [VERIFIED: codebase grep] | `duration` from `span/3`; add `accepted_count` on stop. [CITED: https://hexdocs.pm/telemetry/telemetry.html] |
| `[:scrypath, :sync, :delete]` | `delete_*` common path | `schema`, `backend`, `sync_mode`, `index`, `document_count` [VERIFIED: codebase grep] | `duration`; add `accepted_count` on stop. [CITED: https://hexdocs.pm/telemetry/telemetry.html] |
| `[:scrypath, :search, :execute]` | `Scrypath.Search.search/3` | `schema`, `backend`, `repo`, `hit_count`, `missing_count` [VERIFIED: codebase grep] | `duration`. [CITED: https://hexdocs.pm/telemetry/telemetry.html] |
| `[:scrypath, :hydration, :load]` | repo hydration query | `schema`, `repo`, `hit_count`, `missing_count`, `preload?` [VERIFIED: codebase grep] | `duration`; add `record_count`. [CITED: https://hexdocs.pm/telemetry/telemetry.html] |

### Backend-specific events

| Event Prefix | When | Extra metadata |
|--------------|------|----------------|
| `[:scrypath, :meilisearch, :request]` | each HTTP write/search request | `index`, `operation`, `http_method`, `path`, `status_code` where present. [VERIFIED: codebase grep] |
| `[:scrypath, :meilisearch, :task_wait]` | inline wait polling | `index`, `task_uid`, `poll_count`, `final_status`. [VERIFIED: codebase grep] |
| `[:scrypath, :oban, :enqueue]` | Scrypath-built job insert or insert_all | `worker`, `queue`, `job_count`, `schema`, `operation`. [CITED: https://hexdocs.pm/oban/Oban.html] [ASSUMED] |
| `[:scrypath, :oban, :perform]` | worker-owned backend execution | `worker`, `schema`, `backend`, `index`, `document_count`, `attempt`. [CITED: https://hexdocs.pm/oban/Oban.Worker.html] [ASSUMED] |

Keep task uid, poll counts, attempt counts, and raw error detail out of the common sync/search prefixes. Those are backend or worker details, not stable cross-backend API metadata. [VERIFIED: codebase grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Durable retries and discard handling | custom retry loop or bespoke job table | Oban workers + built-in retry/backoff/discard lifecycle. [CITED: https://hexdocs.pm/oban/error_handling.html] | Oban already persists attempts, delays retries, and records failure history. [CITED: https://hexdocs.pm/oban/error_handling.html] |
| Transactional enqueue inside write flows | custom outbox wrapper for Phase 4 | Oban `insert/5` or `insert_all/5` into `Ecto.Multi`. [CITED: https://hexdocs.pm/oban/Oban.html] | The docs already cover `Ecto.Multi` insertion and uniqueness support. [CITED: https://hexdocs.pm/oban/Oban.html] |
| Span lifecycle event plumbing | hand-built `start`/`stop`/`exception` execute calls | `:telemetry.span/3`. [CITED: https://hexdocs.pm/telemetry/telemetry.html] | It standardizes metadata and measurements for start/stop/exception events. [CITED: https://hexdocs.pm/telemetry/telemetry.html] |
| Queue-state visibility | duplicate “job started/failed” library events | Oban’s `[:oban, :job, ...]` telemetry plus Scrypath semantic spans. [CITED: https://hexdocs.pm/oban/Oban.Telemetry.html] | Duplicating job state would create conflicting operational signals. [CITED: https://hexdocs.pm/oban/Oban.Telemetry.html] |

**Key insight:** Scrypath should own search semantics and payload contracts, while Oban owns durable execution mechanics. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/oban/Oban.html]

## Common Pitfalls

### Pitfall 1: Serializing structs into jobs
**What goes wrong:** Workers receive opaque args or runtime serialization failures. [CITED: https://hexdocs.pm/oban/Oban.Worker.html]  
**Why it happens:** Oban stores args as JSON and stringifies keys. [CITED: https://hexdocs.pm/oban/Oban.Worker.html]  
**How to avoid:** Serialize only strings, numbers, booleans, lists, and maps built from `Scrypath.Document` or delete ids. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/oban/Oban.Worker.html]  
**Warning signs:** Pattern matches expecting atom keys or tests that only pass with in-memory maps. [CITED: https://hexdocs.pm/oban/testing_workers.html]

### Pitfall 2: Treating enqueue acceptance as search completion
**What goes wrong:** Applications assume documents are searchable immediately after `{:ok, result}` from `sync_mode: :oban`. [VERIFIED: codebase grep]  
**Why it happens:** Inline and async modes both currently decorate accepted/completed results through the same sync facade. [VERIFIED: codebase grep]  
**How to avoid:** Keep `status: :accepted` for `:oban`, return job metadata, and document the full async lifecycle. [VERIFIED: codebase grep]  
**Warning signs:** Docs or telemetry labels that say “synced” at enqueue time. [VERIFIED: codebase grep]

### Pitfall 3: Retrying permanent payload/config errors forever
**What goes wrong:** Bad jobs churn until discard, hiding real operator action behind noisy retries. [CITED: https://hexdocs.pm/oban/error_handling.html]  
**Why it happens:** All failures are treated as transient. [ASSUMED]  
**How to avoid:** Cancel terminal shape/config errors and retry only external/transient failures. [CITED: https://hexdocs.pm/oban/Oban.Worker.html] [ASSUMED]  
**Warning signs:** Same args fail every attempt with the same validation error. [ASSUMED]

### Pitfall 4: Duplicating Oban lifecycle telemetry
**What goes wrong:** Dashboards disagree about success, failure, and timing. [CITED: https://hexdocs.pm/oban/Oban.Telemetry.html]  
**Why it happens:** Library code emits queue lifecycle events instead of semantic search events. [ASSUMED]  
**How to avoid:** Use Oban telemetry for queue/job state and Scrypath telemetry for sync/search semantics. [CITED: https://hexdocs.pm/oban/Oban.Telemetry.html] [CITED: https://hexdocs.pm/telemetry/telemetry.html]  
**Warning signs:** Separate “job failed” counters from Oban and Scrypath with different totals. [ASSUMED]

## Code Examples

Verified patterns from official sources:

### Oban Insert in `Ecto.Multi`
```elixir
# Source: https://hexdocs.pm/oban/Oban.html
Ecto.Multi.new()
|> Oban.insert(:search_sync, MyApp.SearchWorker.new(%{"id" => 1}))
|> Repo.transact()
```

### Telemetry Span
```elixir
# Source: https://hexdocs.pm/telemetry/telemetry.html
:telemetry.span([:scrypath, :sync, :upsert], %{schema: schema}, fn ->
  result = do_work()
  {result, %{document_count: 1}}
end)
```

### Worker `perform/1` With JSON Args
```elixir
# Source: https://hexdocs.pm/oban/Oban.Worker.html
def perform(%Oban.Job{args: %{"documents" => docs, "index" => index}}) do
  MyBackend.upsert(index, docs)
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Inline/manual only in Scrypath core. [VERIFIED: codebase grep] | Add durable `:oban` mode while keeping common verbs unchanged. [VERIFIED: codebase grep] | Phase 4 scope, 2026-04. [VERIFIED: codebase grep] | Production path becomes post-commit durable without adding a second public sync API. [VERIFIED: codebase grep] |
| Outcome-specific event naming in libraries. [ASSUMED] | `:telemetry.span/3` start/stop/exception conventions. [CITED: https://hexdocs.pm/telemetry/telemetry.html] | Telemetry 1.x current guidance. [CITED: https://hexdocs.pm/telemetry/telemetry.html] | Lower handler complexity and more standard tooling compatibility. [CITED: https://hexdocs.pm/telemetry/telemetry.html] |

**Deprecated/outdated:**
- Returning `:discard` or `{:discard, reason}` from Oban workers is deprecated; use `{:cancel, reason}` for terminal non-retrying outcomes. [CITED: https://hexdocs.pm/oban/Oban.Worker.html]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Store module references in job args as strings and resolve them at runtime after validation. | Recommended Payload and Worker Contract | Low; naming may change but JSON-safe payload design still stands. |
| A2 | Default queue name should be something Scrypath-specific such as `:scrypath`. | Recommended Payload and Worker Contract | Low; queue name is an implementation detail. |
| A3 | Default `oban_max_attempts` should be lower than Oban’s generic 20, e.g. `8`. | Recommended Payload and Worker Contract | Medium; retry budget affects operator experience and failure latency. |
| A4 | Treat config/payload errors as `{:cancel, reason}` and transient backend errors as retryable. | Retry and Failure Semantics | Medium; planner should confirm exact classification policy before implementation. |

## Open Questions (RESOLVED)

1. **`Scrypath.Oban` helper shape**
   - Resolution: expose one batch-capable public helper as the primary contract, with any single-record wrappers deferred unless execution proves they materially reduce friction.
   - Why: the common sync API is already batch-oriented, and the locked Phase 4 decisions prioritize preserving caller batch shape over multiplying public verbs. [VERIFIED: codebase grep]
   - Planning impact: `04-02-PLAN.md` should implement the narrow transactional helper around batch enqueue composition only.

2. **Default uniqueness behavior**
   - Resolution: plan for one job per caller batch and default uniqueness at that batch-job level rather than any cross-batch aggregation behavior.
   - Why: this matches the research recommendation, keeps queue semantics explicit, and avoids inventing hidden debounce or aggregation behavior that Phase 4 explicitly defers. [CITED: https://hexdocs.pm/oban/Oban.html] [ASSUMED]
   - Planning impact: `04-02-PLAN.md` should keep uniqueness explicit in the enqueue layer and document it as batch-scoped behavior.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | build/test | ✓ | `1.19.5` [VERIFIED: codebase grep] | — |
| OTP | build/test | ✓ | `28` [VERIFIED: codebase grep] | — |
| Mix | build/test | ✓ | `1.19.5` [VERIFIED: codebase grep] | — |
| Oban package in project deps | async sync implementation | ✗ | latest `2.21.1` available on Hex. [CITED: https://hex.pm/api/packages/oban] | Add optional dependency in `mix.exs`. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.html] |
| Telemetry package in project deps | instrumentation | ✓ | `1.4.1` locked. [VERIFIED: codebase grep] | — |
| PostgreSQL CLI | local integration/debugging | ✓ | `14.17` [VERIFIED: codebase grep] | — |

**Missing dependencies with no fallback:**
- `oban` is not currently declared in `mix.exs`, so Phase 4 implementation cannot compile until it is added as an optional dependency. [VERIFIED: codebase grep] [CITED: https://hex.pm/api/packages/oban]

**Missing dependencies with fallback:**
- None for implementation; the queue dependency itself is the feature. [VERIFIED: codebase grep]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir `1.19.5`. [VERIFIED: codebase grep] |
| Config file | none; current suite boots through `test/test_helper.exs`. [VERIFIED: codebase grep] |
| Quick run command | `mix test test/scrypath/sync_test.exs test/scrypath/meilisearch/tasks_test.exs` [VERIFIED: codebase grep] |
| Full suite command | `mix test` [VERIFIED: codebase grep] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SYNC-05 | `sync_mode: :oban` enqueues projected upsert/delete jobs and returns accepted result semantics. [VERIFIED: codebase grep] | unit + integration | `mix test test/scrypath/oban_test.exs` | ❌ Wave 0 |
| SYNC-05 | `Scrypath.Oban` composes with `Ecto.Multi` / `Repo.transact` without splitting public sync APIs. [VERIFIED: codebase grep] | unit | `mix test test/scrypath/oban_multi_test.exs` | ❌ Wave 0 |
| OPER-04 | Common sync/search spans emit stable metadata and measurements. [CITED: https://hexdocs.pm/telemetry/telemetry.html] | unit | `mix test test/scrypath/telemetry_test.exs` | ❌ Wave 0 |
| OPER-04 | Meilisearch request/task-wait spans carry backend-specific detail only on backend prefixes. [VERIFIED: codebase grep] | unit | `mix test test/scrypath/meilisearch_telemetry_test.exs` | ❌ Wave 0 |
| SYNC-05 | Worker retry/cancel classification is correct for transient vs terminal errors. [CITED: https://hexdocs.pm/oban/Oban.Worker.html] | unit | `mix test test/scrypath/oban_worker_test.exs` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `mix test test/scrypath/oban_test.exs test/scrypath/telemetry_test.exs`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `test/scrypath/oban_test.exs` — enqueue semantics and accepted result coverage for `SYNC-05`.
- [ ] `test/scrypath/oban_multi_test.exs` — transactional helper coverage for `SYNC-05`.
- [ ] `test/scrypath/telemetry_test.exs` — common sync/search span coverage for `OPER-04`.
- [ ] `test/scrypath/meilisearch_telemetry_test.exs` — backend-specific span coverage for `OPER-04`.
- [ ] Add Oban test setup guidance, likely using `Oban.Testing` and test-mode config, before worker integration tests. [CITED: https://hexdocs.pm/oban/testing_workers.html] [CITED: https://hexdocs.pm/oban/installation.html]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Phase 4 adds no auth surface. [VERIFIED: codebase grep] |
| V3 Session Management | no | Phase 4 adds no session surface. [VERIFIED: codebase grep] |
| V4 Access Control | no | Library runtime code does not introduce authorization decisions here. [VERIFIED: codebase grep] |
| V5 Input Validation | yes | Validate runtime options and Oban payload shape before enqueue and before worker execution. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/oban/Oban.Worker.html] |
| V6 Cryptography | no | No new crypto primitives should be introduced in this phase. [VERIFIED: codebase grep] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Oversized or malformed job args | Denial of Service | Enforce JSON-safe payload builders and bounded batch sizes before enqueue. [CITED: https://hexdocs.pm/oban/Oban.Worker.html] [ASSUMED] |
| Secret leakage through telemetry/log metadata | Information Disclosure | Never attach API keys, raw request bodies, or full document payloads to stable telemetry metadata. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/telemetry/telemetry.html] |
| Retry storms on permanent errors | Denial of Service | Cancel terminal config/payload errors and reserve retries for transient backend failures. [CITED: https://hexdocs.pm/oban/error_handling.html] [ASSUMED] |
| Silent search drift after discarded jobs | Tampering / Integrity | Treat discarded jobs as operator-visible failure states in docs, telemetry, and result semantics. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/oban/error_handling.html] |

## Docs Implications

The README should add a Phase 4 sync-mode matrix covering `:inline`, `:manual`, and `:oban`, with one row each for completion guarantee, failure surface, retry behavior, and when documents become searchable. That matrix is required to keep `sync_mode: :oban` from sounding like immediate sync. [VERIFIED: codebase grep]

Add a dedicated “Oban integration” guide showing: optional dependency setup, application `Oban` configuration in a consuming app, `Scrypath.sync_*` with `sync_mode: :oban`, and one `Ecto.Multi` example using `Scrypath.Oban`. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.html] [CITED: https://hexdocs.pm/oban/installation.html] [CITED: https://hexdocs.pm/oban/Oban.html]

Add a dedicated “Telemetry” guide with a table of public `[:scrypath, ...]` events, stable metadata fields, and a note that Oban’s own `[:oban, :job, ...]` events remain the queue/job lifecycle source of truth. [CITED: https://hexdocs.pm/telemetry/telemetry.html] [CITED: https://hexdocs.pm/oban/Oban.Telemetry.html]

## Sources

### Primary (HIGH confidence)
- `https://hexdocs.pm/oban/Oban.html` - job insertion, `Ecto.Multi` integration, uniqueness caveats, insert-all guidance.
- `https://hexdocs.pm/oban/Oban.Worker.html` - worker contract, JSON args, result semantics, backoff, retries, cancel/discard behavior.
- `https://hexdocs.pm/oban/error_handling.html` - retry/discard/error recording behavior.
- `https://hexdocs.pm/oban/Oban.Telemetry.html` - Oban lifecycle telemetry events and metadata.
- `https://hexdocs.pm/telemetry/telemetry.html` - `:telemetry.span/3` conventions and metadata/measurement model.
- `https://hexdocs.pm/ecto/Ecto.Multi.html` - transactional composition guidance.
- `https://hexdocs.pm/mix/Mix.Tasks.Deps.html` - optional dependency semantics.
- `https://hex.pm/api/packages/oban` - current package version and publish date.
- `https://hex.pm/api/packages/telemetry` - current package version and publish date.
- `https://hex.pm/api/packages/ecto` - current package version and publish date.
- `https://hex.pm/api/packages/req` - current package version and publish date.
- Local codebase files under `lib/scrypath/*`, `test/scrypath/*`, `.planning/*`, and `README.md`. [VERIFIED: codebase grep]

### Secondary (MEDIUM confidence)
- Local project research prompts under `prompts/*.md` for design consistency with prior project thinking. [VERIFIED: codebase grep]

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - versions were verified against Hex package metadata and usage was checked against current official docs.
- Architecture: HIGH - recommendations align with locked phase decisions and the current Scrypath module boundaries.
- Pitfalls: MEDIUM - core failure and JSON constraints are documented, but exact retry classification policy still needs planner confirmation on terminal-vs-transient boundaries.

**Research date:** 2026-04-15
**Valid until:** 2026-05-15

## RESEARCH COMPLETE
