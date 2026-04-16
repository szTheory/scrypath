# Phase 12: Internal Operations Seam - Research

**Researched:** 2026-04-16
**Domain:** Internal operations modeling for Scrypath sync and reindex workflows under a Meilisearch-first public surface [VERIFIED: roadmap + requirements + `lib/scrypath/sync.ex` + `lib/scrypath/reindex.ex`]
**Confidence:** HIGH

## User Constraints

- Ecto-first, Phoenix-friendly Elixir OSS library. [VERIFIED: user prompt + AGENTS.md instructions in conversation]
- Public v1 targets Meilisearch first. [VERIFIED: user prompt + README.md]
- Keep an internal adapter seam, but do not promise public multi-backend abstraction in v1. [VERIFIED: user prompt + README.md + ARCHITECTURE.md]
- Support inline, Oban, and manual sync flows. [VERIFIED: user prompt + README.md + `lib/scrypath/options.ex`]
- Keep eventual consistency, delete semantics, backfills, and reindex workflows explicit. [VERIFIED: user prompt + README.md + ARCHITECTURE.md]

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SEAM-01 | Scrypath exposes operator primitives through Scrypath-owned structs and APIs rather than direct Meilisearch task payloads or Oban-only assumptions. | Introduce an internal `Scrypath.Operations` seam with Scrypath-owned result, reference, and lifecycle structs; keep Meilisearch task maps inside `Scrypath.Meilisearch.*` and translate them at the boundary. [VERIFIED: `lib/scrypath/sync.ex` + `lib/scrypath/reindex.ex` + `lib/scrypath/meilisearch.ex` + ARCHITECTURE.md][CITED: https://www.meilisearch.com/docs/capabilities/indexing/tasks_and_batches/async_operations][CITED: https://hexdocs.pm/oban/job_lifecycle.html] |
| SEAM-02 | Scrypath's internal sync and reindex flows depend on a backend/admin operations seam that preserves the existing Meilisearch-first public contract while making future backend work safer. | Keep `Scrypath.Backend` narrow for common search/write verbs, and add a separate internal operations/admin boundary for lifecycle inspection, waiting, and workflow references used by sync, backfill, reindex, and future operator APIs. [VERIFIED: `lib/scrypath/backend.ex` + `lib/scrypath/reindex.ex` + `lib/scrypath/backfill.ex` + README.md + ARCHITECTURE.md] |

## Summary

The repo already has the right product boundary but not yet the right internal shape. Public docs say `Scrypath` owns the common path and `Scrypath.Meilisearch.*` is the explicit backend-specific escape hatch, yet the current sync and reindex internals still pass `%{task: ...}` maps shaped around Meilisearch task payloads and branch on `backend == Scrypath.Meilisearch` to decide whether lifecycle waiting is possible. [VERIFIED: README.md + ARCHITECTURE.md + `lib/scrypath/sync.ex` + `lib/scrypath/reindex.ex` + `lib/scrypath/backfill.ex`]

That mismatch is the Phase 12 seam to extract. The internal contract should become Scrypath-owned operation structs that describe three separate concerns: what work was requested, what external system reference can be followed, and what lifecycle state Scrypath can currently know. Meilisearch raw task payloads, task polling, and index-swap specifics should stay under `Scrypath.Meilisearch.*`, while Oban job state should remain an input to lifecycle projection rather than the lifecycle model itself. [VERIFIED: `lib/scrypath/meilisearch.ex` + `lib/scrypath/meilisearch/tasks.ex` + `lib/scrypath/oban/enqueue.ex` + `lib/scrypath/oban/upsert_worker.ex` + `lib/scrypath/oban/delete_worker.ex`][CITED: https://www.meilisearch.com/docs/capabilities/indexing/tasks_and_batches/monitor_tasks][CITED: https://hexdocs.pm/oban/job_lifecycle.html]

The safest plan is to add an internal `Scrypath.Operations` namespace and adapt current public return maps from those structs instead of changing the public shape in Phase 12. That preserves the Meilisearch-first public behavior promised in the roadmap, gives Phase 13 a stable seam for operator primitives, and avoids implying that the existing public backend behaviour has suddenly become a generalized multi-backend API. [VERIFIED: ROADMAP.md + REQUIREMENTS.md + README.md + ARCHITECTURE.md]

**Primary recommendation:** Add a private `Scrypath.Operations` seam now, keep `Scrypath.Meilisearch.*` as the only public backend-native namespace, and make all sync/backfill/reindex orchestration exchange Scrypath-owned `result`, `reference`, and `lifecycle` structs internally before any public map is assembled. [VERIFIED: `lib/scrypath/sync.ex` + `lib/scrypath/reindex.ex` + `lib/scrypath/backfill.ex` + `lib/scrypath/meilisearch.ex`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Common sync verbs (`sync_*`, `delete_*`) | API / Library core | Backend adapter | The public `Scrypath.*` functions already own orchestration, mode semantics, and telemetry; backends only perform writes. [VERIFIED: `lib/scrypath.ex` + `lib/scrypath/sync.ex` + `lib/scrypath/backend.ex`] |
| Backend task normalization and waiting | Backend adapter namespace | API / Library core | Task shapes and polling are Meilisearch-specific today and already live in `Scrypath.Meilisearch.normalize_task/2` and `Scrypath.Meilisearch.Tasks.wait_for_task/2`. [VERIFIED: `lib/scrypath/meilisearch.ex` + `lib/scrypath/meilisearch/tasks.ex`][CITED: https://www.meilisearch.com/docs/capabilities/indexing/tasks_and_batches/async_operations] |
| Queue enqueue and worker execution | Queue integration layer | API / Library core | Oban enqueue and worker payload logic are already isolated under `Scrypath.Oban.*`, and they should feed lifecycle observation rather than define it. [VERIFIED: `lib/scrypath/oban/enqueue.ex` + `lib/scrypath/oban/payload.ex` + `lib/scrypath/oban/upsert_worker.ex` + `lib/scrypath/oban/delete_worker.ex`][CITED: https://hexdocs.pm/oban/job_lifecycle.html] |
| Reindex workflow orchestration | API / Library core | Backend adapter namespace | `Scrypath.Reindex` owns the workflow order and should depend on Scrypath-owned operation results instead of raw backend task maps. [VERIFIED: `lib/scrypath/reindex.ex` + ARCHITECTURE.md] |
| Operator-facing lifecycle inspection | Internal operations seam | Backend adapter + queue integration | Phase 13 needs a Scrypath-owned model that can summarize inline, manual, and Oban flows without leaking raw Meilisearch or Oban admin shapes. [VERIFIED: ROADMAP.md + REQUIREMENTS.md + README.md + ARCHITECTURE.md] |
| Backend-native power operations | `Scrypath.Meilisearch.*` public namespace | Internal operations seam | The repo already documents `Scrypath.Meilisearch.*` as the visible Meilisearch-specific escape hatch, so Phase 12 should not hide or generalize it. [VERIFIED: README.md + ARCHITECTURE.md + `lib/scrypath/meilisearch.ex`] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `ecto` | `3.13.5` [VERIFIED: `mix hex.info ecto`] | Keep sync/reindex orchestration explicit in library functions and transactions at app-context boundaries. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] | Scrypath is explicitly Ecto-first, and Ecto's transaction/orchestration model fits a narrow internal seam better than callback magic. [VERIFIED: README.md + ARCHITECTURE.md + user prompt][CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] |
| `nimble_options` | `1.1.1` [VERIFIED: `mix hex.info nimble_options`] | Preserve explicit runtime option validation while adding operations-seam options or internal references. [VERIFIED: `lib/scrypath/options.ex`] | The repo already uses NimbleOptions as its runtime contract surface, so Phase 12 should extend that pattern rather than introduce ad hoc option validation. [VERIFIED: `lib/scrypath/options.ex`] |
| `telemetry` | `1.4.1` [VERIFIED: `mix hex.info telemetry`] | Keep common-path metadata low-cardinality while backend-specific detail stays under backend event families. [VERIFIED: `lib/scrypath/telemetry.ex` + `test/scrypath/telemetry_test.exs`] | The repo already separates common sync/search spans from Meilisearch request/task spans, which is the right model for a seam extraction. [VERIFIED: ARCHITECTURE.md + `test/scrypath/telemetry_test.exs`] |
| `req` | `0.5.17` [VERIFIED: `mix hex.info req`] | Continue to own Meilisearch transport internally instead of exposing HTTP client choices in the public API. [VERIFIED: README.md + `lib/scrypath/meilisearch/client.ex`] | The README explicitly says Scrypath owns its internal transport dependency, which aligns with keeping backend-native detail behind the seam. [VERIFIED: README.md] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `oban` | `2.21.1` [VERIFIED: `mix hex.info oban`] | Durable enqueue and worker execution for `sync_mode: :oban`. [VERIFIED: `lib/scrypath/options.ex` + `lib/scrypath/oban/enqueue.ex`] | Use only for the queued path; lifecycle projection must not depend on Oban being present for inline/manual flows. [VERIFIED: README.md + `lib/scrypath/options.ex` + `test/scrypath/sync_test.exs`][CITED: https://hexdocs.pm/oban/job_lifecycle.html] |
| `Scrypath.Meilisearch.Tasks` | repo module [VERIFIED: `lib/scrypath/meilisearch/tasks.ex`] | Poll summarized/full Meilisearch task objects into terminal task outcomes. [VERIFIED: `lib/scrypath/meilisearch/tasks.ex`] | Use behind the new operations seam as the Meilisearch-specific waiter; do not call it from common orchestration after Phase 12. [VERIFIED: `lib/scrypath/sync.ex` + `lib/scrypath/reindex.ex`] |
| `Scrypath.Oban.Enqueue` | repo module [VERIFIED: `lib/scrypath/oban/enqueue.ex`] | Create durable job references for queued sync work. [VERIFIED: `lib/scrypath/oban/enqueue.ex`] | Use as the queue-specific reference producer; translate returned job metadata into a Scrypath-owned operation reference before higher layers see it. [VERIFIED: `lib/scrypath/oban/enqueue.ex` + `test/scrypath/sync_test.exs`] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Internal `Scrypath.Operations` seam | Keep passing `%{task: ...}` and `%{job: ...}` maps through orchestration | Current maps already leak Meilisearch task assumptions into common sync and reindex flows, and they leave Phase 13 without a stable internal contract. [VERIFIED: `lib/scrypath/sync.ex` + `lib/scrypath/reindex.ex` + `lib/scrypath/backfill.ex`] |
| Separate internal operations/admin behaviour | Widen `Scrypath.Backend` with waiting, task lookup, and admin callbacks immediately | That would turn an internal seam extraction into an implied public backend abstraction expansion, which the roadmap and docs explicitly reject for v1.2. [VERIFIED: README.md + ARCHITECTURE.md + REQUIREMENTS.md] |
| Scrypath-owned lifecycle enum | Reuse raw Oban states or raw Meilisearch statuses directly | Oban and Meilisearch states describe different layers of execution, and the docs already promise one shared operator-facing lifecycle across modes. [VERIFIED: README.md + ARCHITECTURE.md + `lib/scrypath/meilisearch/tasks.ex` + `lib/scrypath/oban/enqueue.ex`][CITED: https://www.meilisearch.com/docs/capabilities/indexing/tasks_and_batches/async_operations][CITED: https://hexdocs.pm/oban/job_lifecycle.html] |

**Installation:** No new dependency is required for Phase 12; the work is an internal seam extraction on top of the existing Ecto, NimbleOptions, Telemetry, Req, and optional Oban stack. [VERIFIED: mix.exs + `mix hex.info ecto` + `mix hex.info nimble_options` + `mix hex.info telemetry` + `mix hex.info req` + `mix hex.info oban`]

## Architecture Patterns

### System Architecture Diagram

```text
Scrypath.sync_* / backfill / reindex
        |
        v
common orchestration modules
  - build documents / ids
  - decide sync mode
  - emit common telemetry
        |
        v
internal Scrypath operations seam
  - operation result
  - operation reference
  - lifecycle projection
        |
        +--> inline/manual backend path ----------------------------+
        |                                                          |
        |                                                          v
        |                                              Scrypath.Meilisearch.*
        |                                              - document writes
        |                                              - settings/index ops
        |                                              - raw task normalization
        |                                              - task wait / admin lookups
        |                                                          |
        |                                                          v
        |                                             Meilisearch summarized/full task objects
        |
        +--> oban enqueue path ------------------------------------+
                                                                   |
                                                                   v
                                                        Scrypath.Oban.Enqueue
                                                        - durable job insert
                                                        - queue/job metadata
                                                                   |
                                                                   v
                                                        Oban job reference + later worker execution

All paths return through the operations seam, which projects:
  request accepted? -> current lifecycle state -> followable external reference
before any public result map is assembled.
```

The diagram matches the current split between common orchestration, `Scrypath.Meilisearch.*`, and `Scrypath.Oban.*`, while adding the missing seam Phase 12 needs. [VERIFIED: `lib/scrypath/sync.ex` + `lib/scrypath/reindex.ex` + `lib/scrypath/meilisearch.ex` + `lib/scrypath/oban/enqueue.ex` + ARCHITECTURE.md]

### Recommended Project Structure

```text
lib/
└── scrypath/
    ├── operations/              # New internal seam for result/reference/lifecycle modeling
    │   ├── result.ex            # Scrypath-owned operation envelope
    │   ├── reference.ex         # backend/queue follow-up reference structs
    │   └── lifecycle.ex         # shared operator-facing lifecycle projection
    ├── sync.ex                  # translates sync execution into operations seam
    ├── backfill.ex              # stores batch results as operation results
    ├── reindex.ex               # consumes operation results instead of raw :task maps
    ├── meilisearch/             # keeps raw task/admin/native power here
    └── oban/                    # keeps raw queue/job integration here
```

The new `operations/` namespace is a planning recommendation, not an existing directory. It matches the repo's current preference for small explicit modules and visible boundaries. [VERIFIED: current `lib/scrypath/` structure + README.md + ARCHITECTURE.md]

### Pattern 1: Separate Lifecycle From External Reference

**What:** Model operation lifecycle as Scrypath-owned state and keep Meilisearch task ids or Oban job ids in a distinct reference struct. [VERIFIED: current repo mixes these concepts in `%{status: ..., task: ...}` and `%{status: ..., job: ...}` maps in `lib/scrypath/sync.ex`]

**When to use:** Use for every sync, delete, backfill batch, and reindex step that Phase 13 may need to inspect. [VERIFIED: ROADMAP.md + REQUIREMENTS.md + `lib/scrypath/sync.ex` + `lib/scrypath/reindex.ex` + `lib/scrypath/backfill.ex`]

**Example:**

```elixir
# Source: recommended shape derived from lib/scrypath/sync.ex,
# lib/scrypath/reindex.ex, lib/scrypath/oban/enqueue.ex,
# and Meilisearch task semantics in official docs.
defmodule Scrypath.Operations.Result do
  defstruct [
    :kind,
    :mode,
    :lifecycle,
    :reference,
    :document_ids,
    :document_count,
    :index,
    :meta
  ]
end

defmodule Scrypath.Operations.Reference do
  defstruct [:adapter, :type, :id, :index, :raw]
end
```

This shape preserves follow-up power without making raw backend payloads the common contract. [VERIFIED: `lib/scrypath/sync.ex` + `lib/scrypath/reindex.ex`][CITED: https://www.meilisearch.com/docs/capabilities/indexing/tasks_and_batches/monitor_tasks][CITED: https://hexdocs.pm/oban/job_lifecycle.html]

### Pattern 2: Project Into One Shared Lifecycle Vocabulary

**What:** Keep the operator-facing lifecycle states Scrypath-owned and mode-agnostic, then map backend or queue-native states into that vocabulary. [VERIFIED: README.md and ARCHITECTURE.md already promise one operator-facing lifecycle across modes]

**When to use:** Use whenever returning common-path results or building internal status inspection helpers. [VERIFIED: README.md + ARCHITECTURE.md + REQUIREMENTS.md]

**Example:**

```elixir
# Source: README.md + ARCHITECTURE.md lifecycle contract,
# Meilisearch task status docs, and Oban lifecycle docs.
def from_meilisearch_status(:enqueued), do: :enqueued
def from_meilisearch_status(:processing), do: :processing
def from_meilisearch_status(:succeeded), do: :completed
def from_meilisearch_status(:failed), do: :failed
def from_meilisearch_status(:cancelled), do: :cancelled

def from_oban_state("available"), do: :enqueued
def from_oban_state("scheduled"), do: :enqueued
def from_oban_state("executing"), do: :processing
def from_oban_state("retryable"), do: :retrying
def from_oban_state("completed"), do: :completed
def from_oban_state("cancelled"), do: :cancelled
def from_oban_state("discarded"), do: :discarded
```

The projection must stay explicit about information loss: Oban reflects queue execution, not backend acceptance; Meilisearch reflects backend processing, not host-app transaction state. [VERIFIED: README.md + guides/sync-modes-and-visibility.md + `lib/scrypath/oban/enqueue.ex` + `lib/scrypath/meilisearch/tasks.ex`][CITED: https://www.meilisearch.com/docs/capabilities/indexing/tasks_and_batches/async_operations][CITED: https://hexdocs.pm/oban/job_lifecycle.html]

### Pattern 3: Keep Public Maps As Adapters Over Internal Structs In Phase 12

**What:** Build internal `Scrypath.Operations.Result` values first, then translate them into the existing public result maps for `Scrypath.sync_*`, `Scrypath.backfill/2`, and `Scrypath.reindex/2`. [VERIFIED: public return maps are already documented in README.md and asserted in tests]

**When to use:** Use for the entire Phase 12 implementation so Phase 13 can change operator primitives without forcing a public contract break during seam extraction. [VERIFIED: ROADMAP.md + README.md + `test/scrypath/sync_test.exs` + `test/scrypath/backfill_test.exs` + `test/scrypath/reindex_test.exs`]

**Example:**

```elixir
# Source: public return contracts in tests and docs
def to_public_sync_map(%Scrypath.Operations.Result{} = result) do
  %{
    mode: result.mode,
    status: result.lifecycle,
    document_ids: result.document_ids,
    document_count: result.document_count
  }
  |> maybe_put_task(result.reference)
  |> maybe_put_job(result.reference)
end
```

This pattern keeps public behavior stable while moving the dependency direction inward toward Scrypath-owned types. [VERIFIED: README.md + `test/scrypath/sync_test.exs` + `test/scrypath/reindex_test.exs`]

### Likely Task Decomposition

1. Add internal operation structs and lifecycle projection helpers under a new `Scrypath.Operations` namespace. [VERIFIED: repo currently lacks any such namespace via `rg --files lib | rg 'operations'` returning no matches in session]
2. Refactor `Scrypath.Meilisearch` and `Scrypath.Meilisearch.Tasks` to return/consume Meilisearch-native references plus translation helpers instead of being called directly from common orchestration. [VERIFIED: `lib/scrypath/sync.ex` and `lib/scrypath/reindex.ex` call `Scrypath.Meilisearch.Tasks` directly today]
3. Refactor `Scrypath.Sync` to decorate operation results, not raw `%{task: ...}` or `%{job: ...}` maps, while preserving current public maps. [VERIFIED: `lib/scrypath/sync.ex`]
4. Refactor `Scrypath.Backfill` batch results to store operation results or references, not optional bare `:task` keys. [VERIFIED: `lib/scrypath/backfill.ex`]
5. Refactor `Scrypath.Reindex` to wait through the operations seam instead of `backend == Scrypath.Meilisearch` branching. [VERIFIED: `lib/scrypath/reindex.ex`]
6. Add seam-focused tests before or alongside refactors, then preserve current docs wording while removing references that imply common-path task-native payloads. [VERIFIED: existing tests pin current maps in `test/scrypath/sync_test.exs`, `test/scrypath/backfill_test.exs`, and `test/scrypath/reindex_test.exs`] |

### Anti-Patterns to Avoid

- **Common-path `%{task: ...}` as a contract:** It leaks Meilisearch semantics into modules that are supposed to stay backend-neutral at the public layer. [VERIFIED: `lib/scrypath/sync.ex` + `lib/scrypath/backfill.ex` + `lib/scrypath/reindex.ex`]
- **Using raw Oban states as the shared lifecycle vocabulary:** Oban describes durable queue execution, not backend acceptance or reindex step completion. [VERIFIED: README.md + `lib/scrypath/oban/enqueue.ex`][CITED: https://hexdocs.pm/oban/job_lifecycle.html]
- **Growing `Scrypath.Backend` into a public admin facade in Phase 12:** The project constraints explicitly reject a public multi-backend promise in v1.2. [VERIFIED: README.md + REQUIREMENTS.md + user prompt]
- **Conditionals on concrete backend modules in orchestration code:** `wait_for_tasks? = backend == Scrypath.Meilisearch` is a direct sign the seam is in the wrong place. [VERIFIED: `lib/scrypath/reindex.ex`] 

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Shared lifecycle via untyped maps | More `%{status: ..., task: ...}` / `%{status: ..., job: ...}` conventions | Internal structs with small translation functions | The current maps already drift across sync, backfill, reindex, and Oban enqueue paths. Structs give planner-visible, testable contracts without widening the public API. [VERIFIED: `lib/scrypath/sync.ex` + `lib/scrypath/backfill.ex` + `lib/scrypath/reindex.ex` + `lib/scrypath/oban/enqueue.ex`] |
| Queue lifecycle as the whole operator model | Oban-only status inspection API | Scrypath-owned lifecycle projection plus queue-specific reference data | The roadmap explicitly requires operator-facing internals that do not assume Oban-only execution. [VERIFIED: ROADMAP.md + REQUIREMENTS.md] |
| Meilisearch admin details on the common path | Generic `Scrypath.task/1` facade over Meilisearch task routes | Keep raw task/admin power under `Scrypath.Meilisearch.*` and translate internally for common workflows | The repo docs intentionally keep backend-native power visible and namespaced. [VERIFIED: README.md + ARCHITECTURE.md + `lib/scrypath/meilisearch.ex`] |
| Ad hoc transaction orchestration in schema modules | Callback-heavy hooks or generated per-schema runtime verbs | Context-owned orchestration and Ecto transaction helpers where apps need persistence coupling | The project and local prompts consistently prefer explicit orchestration over callback magic. [VERIFIED: README.md + prompts/ecto-best-practices-deep-research.md + prompts/elixir-opensource-libs-best-practices-deep-research.md][CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] |

**Key insight:** Phase 12 is not a backend-abstraction phase. It is a contract-ownership phase: Scrypath needs to own the operation vocabulary internally before it can expose operator primitives safely. [VERIFIED: ROADMAP.md + REQUIREMENTS.md + README.md]

## Common Pitfalls

### Pitfall 1: One `status` Field Currently Means Different Things At Different Layers

**What goes wrong:** `status` in public sync results currently means `:completed` for inline and `:accepted` for manual/Oban, while `task.status` or `job.state` means something else entirely. [VERIFIED: `lib/scrypath/sync.ex` + `test/scrypath/sync_test.exs`]

**Why it happens:** `Scrypath.Sync.decorate_result/2` adds a mode-derived status after backend/queue-specific maps already contain their own lifecycle fields. [VERIFIED: `lib/scrypath/sync.ex`]

**How to avoid:** Split common lifecycle from backend/queue reference details in the new operations seam, then adapt outward. [VERIFIED: current repo shape in `lib/scrypath/sync.ex`]

**Warning signs:** Tests asserting both `status: :accepted` and `task.status: :enqueued` in the same result; docs needing careful prose to explain accepted versus visible. [VERIFIED: `test/scrypath/sync_test.exs` + README.md + guides/sync-modes-and-visibility.md]

### Pitfall 2: Reindex Waiting Is Hard-Coded To Meilisearch Instead Of To A Followable Operation Reference

**What goes wrong:** `Scrypath.Reindex.run/2` uses `backend == Scrypath.Meilisearch` to decide whether create/settings/backfill/swap steps can be waited. [VERIFIED: `lib/scrypath/reindex.ex`]

**Why it happens:** The current code has no Scrypath-owned concept of "this workflow step has a followable external reference." [VERIFIED: `lib/scrypath/reindex.ex` + `lib/scrypath/backfill.ex`]

**How to avoid:** Give every workflow step a reference struct plus a capability check such as "followable?" or "waitable?" owned by the operations seam. [VERIFIED: repo currently lacks such a struct via module inventory in session]

**Warning signs:** Branches on concrete backend modules, or special-casing `task` keys in orchestration modules. [VERIFIED: `lib/scrypath/reindex.ex` + `lib/scrypath/backfill.ex`]

### Pitfall 3: Oban Workers Already Flatten Queue Work Into Manual Backend Calls

**What goes wrong:** The Oban workers rebuild config with `sync_mode: :manual` before calling backend write functions, which is correct for execution but wrong as an operator lifecycle model. [VERIFIED: `lib/scrypath/oban/upsert_worker.ex` + `lib/scrypath/oban/delete_worker.ex`]

**Why it happens:** The worker's job is to execute queued work, not to define the semantic lifecycle presented to operators. [VERIFIED: `lib/scrypath/oban/upsert_worker.ex` + `lib/scrypath/oban/delete_worker.ex`]

**How to avoid:** Treat queue state and backend state as separate observations that the operations seam can project into one higher-level lifecycle. [VERIFIED: README.md + ARCHITECTURE.md][CITED: https://hexdocs.pm/oban/job_lifecycle.html][CITED: https://www.meilisearch.com/docs/capabilities/indexing/tasks_and_batches/async_operations]

**Warning signs:** Any new Phase 12 API that exposes raw `%Oban.Job{}` state or assumes a queued workflow exists for all sync modes. [VERIFIED: REQUIREMENTS.md + ROADMAP.md]

### Pitfall 4: Backfill Batch Results Are Too Weak For Operator Inspection

**What goes wrong:** `Scrypath.Backfill` returns `batch_results` with `documents`, `last_primary_key`, and an optional `task`, but no stable Scrypath-owned reference or lifecycle field. [VERIFIED: `lib/scrypath/backfill.ex` + `test/scrypath/backfill_test.exs`]

**Why it happens:** Backfill was designed around Meilisearch write acceptance, not later operator visibility. [VERIFIED: `lib/scrypath/backfill.ex`]

**How to avoid:** Store a per-batch operation result or reference now so Phase 13 can inspect or retry batches without parsing backend-native payloads directly. [VERIFIED: ROADMAP.md + REQUIREMENTS.md]

**Warning signs:** Reindex code needing to know whether `batch_result.task` exists, or future operator APIs stitching lifecycle from loose maps. [VERIFIED: `lib/scrypath/reindex.ex` + `lib/scrypath/backfill.ex`]

## Code Examples

Verified patterns from official sources and current repo code:

### Explicit Transaction-Orchestration Hook

```elixir
# Source: https://hexdocs.pm/ecto/Ecto.Multi.html
Ecto.Multi.run(multi, :write, fn _repo, changes ->
  # use the changes so far and return {:ok, value} | {:error, value}
end)
```

Use this pattern in host apps or future integration helpers when sync enqueue needs to be composed with repo persistence without hiding the transaction boundary. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html]

### Meilisearch Summarized Task Follow-Up

```elixir
# Source: https://www.meilisearch.com/docs/capabilities/indexing/tasks_and_batches/monitor_tasks
%{
  "taskUid" => 12,
  "indexUid" => "movies",
  "status" => "enqueued",
  "type" => "documentAdditionOrUpdate"
}

# then GET /tasks/12 for the full task object
```

This is the exact raw shape that Phase 12 should keep behind `Scrypath.Meilisearch.*` and translate into a Scrypath-owned reference. [CITED: https://www.meilisearch.com/docs/capabilities/indexing/tasks_and_batches/monitor_tasks]

### Oban Lifecycle Projection Boundary

```elixir
# Source: https://hexdocs.pm/oban/job_lifecycle.html
"available"   # queued and ready
"executing"   # currently running
"retryable"   # failed but scheduled to retry
"completed"   # final success
"cancelled"   # final cancelled state
"discarded"   # final retry exhaustion
```

These are queue states, not backend states. Phase 12 should project them into the shared Scrypath lifecycle instead of exposing them as the common operator model. [CITED: https://hexdocs.pm/oban/job_lifecycle.html]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Common orchestration returns or stores raw `task` maps from Meilisearch writes | Phase 12 should move to Scrypath-owned operation results internally, with Meilisearch task payloads retained only in backend-native references. [VERIFIED: `lib/scrypath/sync.ex` + `lib/scrypath/backfill.ex` + `lib/scrypath/reindex.ex`] | Phase 12 target in 2026-04-16 roadmap. [VERIFIED: ROADMAP.md] | Gives Phase 13 a stable operator seam and removes direct task-payload coupling from common orchestration. [VERIFIED: ROADMAP.md + REQUIREMENTS.md] |
| Reindex decides waitability by comparing `backend == Scrypath.Meilisearch` | Phase 12 should decide waitability by whether a step returns a followable reference through the operations seam. [VERIFIED: `lib/scrypath/reindex.ex`] | Phase 12 target. [VERIFIED: ROADMAP.md] | Removes concrete-backend branching from workflow orchestration without implying public multi-backend parity. [VERIFIED: README.md + REQUIREMENTS.md] |
| Oban metadata and Meilisearch task metadata are both surfaced as loose maps | Phase 12 should preserve those raw details only as adapter-specific references attached to one Scrypath-owned lifecycle/result model. [VERIFIED: `lib/scrypath/oban/enqueue.ex` + `lib/scrypath/sync.ex`] | Phase 12 target. [VERIFIED: ROADMAP.md] | Makes operator primitives mode-aware without being Oban-only or Meilisearch-native. [VERIFIED: ROADMAP.md + REQUIREMENTS.md] |

**Deprecated/outdated:**

- Common-path dependence on bare `:task` keys in sync, backfill, and reindex internals. [VERIFIED: `lib/scrypath/sync.ex` + `lib/scrypath/backfill.ex` + `lib/scrypath/reindex.ex`]
- Reindex lifecycle waiting gated by concrete backend comparison instead of a seam-owned capability. [VERIFIED: `lib/scrypath/reindex.ex`]

## Open Questions

1. **Should Phase 12 preserve the exact public `task` and `job` map fields for backward compatibility, or start a staged deprecation immediately?**
   - What we know: The roadmap says public Meilisearch-first behavior must keep working, and current tests/docs assert `task` and `job` fields in result maps. [VERIFIED: ROADMAP.md + README.md + `test/scrypath/sync_test.exs`]
   - What's unclear: Whether any external consumers already depend on those exact nested shapes beyond repo tests. [VERIFIED: codebase only shows in-repo assertions via `rg -n 'task: %\\{|job: %\\{' README.md ARCHITECTURE.md test lib` in session]
   - Recommendation: Keep public fields in Phase 12 and make them adapters over internal structs; revisit deprecation only in a later public-contract phase. [VERIFIED: roadmap success criterion 3 + current repo tests]

2. **Should the new operations seam live under `Scrypath.Operations` or under an existing namespace such as `Scrypath.Sync`?**
   - What we know: The repo favors small explicit namespaces (`Scrypath.Meilisearch.*`, `Scrypath.Oban.*`) and does not yet have an operations namespace. [VERIFIED: `rg --files lib/scrypath` in session]
   - What's unclear: Whether the maintainer prefers result/reference structs grouped by workflow (`Sync.Result`, `Reindex.Step`) or by shared operator semantics. [VERIFIED: codebase naming conventions only]
   - Recommendation: Use `Scrypath.Operations.*` because the seam must be shared across sync, backfill, reindex, and Phase 13 operator primitives. [VERIFIED: ROADMAP.md + REQUIREMENTS.md]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir 1.19.5 / OTP 28 [VERIFIED: `elixir --version` + repo test files] |
| Config file | none; standard Mix + `test/test_helper.exs` [VERIFIED: `rg --files test lib` + `test/test_helper.exs`] |
| Quick run command | `mix test test/scrypath/sync_test.exs test/scrypath/reindex_test.exs test/scrypath/backfill_test.exs test/scrypath/meilisearch/tasks_test.exs test/scrypath/oban/worker_test.exs` [VERIFIED: local successful run on 2026-04-16] |
| Full suite command | `mix test` [VERIFIED: Mix task support output + standard repo structure] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SEAM-01 | Sync/backfill/reindex internals use Scrypath-owned result/reference structs while public behavior remains stable. [VERIFIED: REQUIREMENTS.md + roadmap goal] | unit | `mix test test/scrypath/sync_test.exs test/scrypath/backfill_test.exs test/scrypath/reindex_test.exs` | Existing coverage for public maps exists; seam-struct coverage is missing. [VERIFIED: `test/scrypath/sync_test.exs` + `test/scrypath/backfill_test.exs` + `test/scrypath/reindex_test.exs`] |
| SEAM-02 | Operator-facing lifecycle inspection does not depend on raw Meilisearch task payloads or Oban-only assumptions. [VERIFIED: REQUIREMENTS.md] | unit | `mix test test/scrypath/meilisearch/tasks_test.exs test/scrypath/oban/worker_test.exs test/scrypath/telemetry_test.exs` | Partial; backend and queue state tests exist, seam-lifecycle projection tests are missing. [VERIFIED: `test/scrypath/meilisearch/tasks_test.exs` + `test/scrypath/oban/worker_test.exs` + `test/scrypath/telemetry_test.exs`] |

### Sampling Rate

- **Per task commit:** `mix test test/scrypath/sync_test.exs test/scrypath/reindex_test.exs test/scrypath/backfill_test.exs test/scrypath/meilisearch/tasks_test.exs test/scrypath/oban/worker_test.exs` [VERIFIED: local successful run on 2026-04-16]
- **Per wave merge:** `mix test` [VERIFIED: standard ExUnit repo flow]
- **Phase gate:** Full suite green before `/gsd-verify-work`. [VERIFIED: project workflow + `.planning/config.json` with `nyquist_validation: true`]

### Wave 0 Gaps

- [ ] `test/scrypath/operations/result_test.exs` - assert the new seam struct contract and public-map adaptation for sync/backfill/reindex. [VERIFIED: file does not exist in current repo inventory]
- [ ] `test/scrypath/operations/lifecycle_test.exs` - cover projection from Meilisearch task status and Oban job state into one shared lifecycle vocabulary. [VERIFIED: file does not exist in current repo inventory]
- [ ] `test/scrypath/reindex_test.exs` - extend coverage so waitability is driven by operation references, not `backend == Scrypath.Meilisearch`. [VERIFIED: current file asserts workflow order but not seam capability logic]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Host applications, not Scrypath's internal operations seam, own authentication. [VERIFIED: project scope in REQUIREMENTS.md + README.md] |
| V3 Session Management | no | Host applications own session state; Scrypath only models search operations. [VERIFIED: README.md + REQUIREMENTS.md] |
| V4 Access Control | no | Phase 12 should not invent access control; keep backend-native admin power namespaced and leave caller authorization to host apps. [VERIFIED: README.md + ROADMAP.md] |
| V5 Input Validation | yes | Continue using NimbleOptions plus explicit module/payload normalization for runtime inputs and Oban payload decoding. [VERIFIED: `lib/scrypath/options.ex` + `lib/scrypath/oban/upsert_worker.ex` + `lib/scrypath/oban/delete_worker.ex`] |
| V6 Cryptography | no | This phase does not introduce cryptographic responsibilities. [VERIFIED: phase goal + current code inventory] |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Malicious or malformed job payload attempts module injection | Elevation of Privilege | Keep `safe_module/1` on `String.to_existing_atom/1`, validate expected callbacks, and do not widen worker payload authority through the new seam. [VERIFIED: `lib/scrypath/oban/upsert_worker.ex` + `lib/scrypath/oban/delete_worker.ex`] |
| Backend-native raw payload leakage into common operator APIs | Information Disclosure | Keep raw task/job payloads behind adapter references and expose only Scrypath-owned lifecycle and summary fields on common surfaces. [VERIFIED: phase goal + README.md + ARCHITECTURE.md] |
| State confusion between durable enqueue, backend acceptance, and search visibility | Tampering | Preserve explicit lifecycle semantics in docs, telemetry, and result adaptation; never collapse accepted/enqueued/completed into one boolean success flag. [VERIFIED: README.md + guides/sync-modes-and-visibility.md + ARCHITECTURE.md] |

## Sources

### Primary (HIGH confidence)

- Current codebase: `lib/scrypath/sync.ex`, `lib/scrypath/reindex.ex`, `lib/scrypath/backfill.ex`, `lib/scrypath/backend.ex`, `lib/scrypath/meilisearch.ex`, `lib/scrypath/meilisearch/tasks.ex`, `lib/scrypath/oban/enqueue.ex`, `lib/scrypath/oban/upsert_worker.ex`, `lib/scrypath/oban/delete_worker.ex`, `lib/scrypath/options.ex`, `lib/scrypath/telemetry.ex` - current seam shape, lifecycle coupling, and option contracts. [VERIFIED: code reads in session]
- Current docs: README.md, ARCHITECTURE.md, guides/sync-modes-and-visibility.md - declared public/operator contract. [VERIFIED: file reads in session]
- Tests: `test/scrypath/sync_test.exs`, `test/scrypath/backfill_test.exs`, `test/scrypath/reindex_test.exs`, `test/scrypath/meilisearch/tasks_test.exs`, `test/scrypath/oban/worker_test.exs`, `test/scrypath/telemetry_test.exs` - current externally visible behavior and gap analysis. [VERIFIED: file reads in session]
- `https://www.meilisearch.com/docs/capabilities/indexing/tasks_and_batches/monitor_tasks` - summarized vs full task objects and tracking workflow. [CITED: https://www.meilisearch.com/docs/capabilities/indexing/tasks_and_batches/monitor_tasks]
- `https://www.meilisearch.com/docs/capabilities/indexing/tasks_and_batches/async_operations` - task statuses, batching, and global task semantics. [CITED: https://www.meilisearch.com/docs/capabilities/indexing/tasks_and_batches/async_operations]
- `https://hexdocs.pm/oban/job_lifecycle.html` - current Oban lifecycle states and final-state semantics. [CITED: https://hexdocs.pm/oban/job_lifecycle.html]
- `https://hexdocs.pm/ecto/Ecto.Multi.html` - explicit transaction/orchestration pattern for Elixir/Ecto apps. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html]

### Secondary (MEDIUM confidence)

- Local prompts: `prompts/ecto-best-practices-deep-research.md`, `prompts/elixir-opensource-libs-best-practices-deep-research.md`, `prompts/elixir-best-practices-deep-research.md` - project-local guidance reinforcing explicit orchestration, narrow public APIs, and small explicit module boundaries. [VERIFIED: file reads in session]

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - the phase uses the repo's existing verified Elixir dependency set and does not require speculative new libraries. [VERIFIED: mix.exs + `mix hex.info ecto` + `mix hex.info nimble_options` + `mix hex.info telemetry` + `mix hex.info req` + `mix hex.info oban`]
- Architecture: HIGH - the cut points are directly visible in current modules, docs, and tests. [VERIFIED: `lib/scrypath/sync.ex` + `lib/scrypath/reindex.ex` + README.md + ARCHITECTURE.md + tests]
- Pitfalls: HIGH - each pitfall maps to concrete code patterns already present in the repo and to official Meilisearch or Oban lifecycle semantics. [VERIFIED: codebase + docs][CITED: https://www.meilisearch.com/docs/capabilities/indexing/tasks_and_batches/async_operations][CITED: https://hexdocs.pm/oban/job_lifecycle.html]

**Research date:** 2026-04-16
**Valid until:** 2026-05-16
