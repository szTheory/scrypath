# Phase 13: Operator Primitives - Research

**Researched:** 2026-04-16 [VERIFIED: current workspace date + user prompt]  
**Domain:** Scrypath-owned operator APIs for sync status, failed work inspection, retry, reconcile, and reindex visibility on top of the Phase 12 operations seam [VERIFIED: `.planning/ROADMAP.md` + `.planning/REQUIREMENTS.md` + `lib/scrypath/operations.ex`]  
**Confidence:** HIGH [VERIFIED: repo evidence covers the existing seam and lifecycle contracts directly; only Meilisearch task semantics and Oban lifecycle states needed external confirmation from official docs]

## User Constraints

- Keep the public surface Meilisearch-first and do not imply a public multi-backend abstraction in v1.2. [VERIFIED: user prompt + `.planning/PROJECT.md` + `.planning/REQUIREMENTS.md` + `README.md` + `ARCHITECTURE.md`]
- Represent operator results with Scrypath-owned structs or stable maps rather than raw Meilisearch or Oban payloads. [VERIFIED: user prompt + `SEAM-01` in `.planning/REQUIREMENTS.md` + `lib/scrypath/operations.ex`]
- Cover inline, Oban, and manual sync modes while staying explicit about eventual consistency, drift, and recovery boundaries. [VERIFIED: user prompt + `.planning/PROJECT.md` + `README.md` + `ARCHITECTURE.md`]
- Use primary repo evidence first; only use official docs to clarify Meilisearch task semantics or Oban job lifecycle. [VERIFIED: user prompt]
- Output must be implementation-oriented and include recommended structure, patterns, pitfalls, and a likely plan split with file ownership and verification. [VERIFIED: user prompt]

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| OPS-01 | Operator can inspect current Scrypath sync status for a schema, including pending work, failed work, and last successful activity where available. [VERIFIED: `.planning/REQUIREMENTS.md`] | Add a public `Scrypath.Operator.status/2` facade returning a Scrypath-owned status struct that aggregates Meilisearch task visibility for all modes and Oban queue visibility for `:oban` mode. [VERIFIED: `README.md` + `ARCHITECTURE.md` + `lib/scrypath/operations.ex` + `lib/scrypath/sync.ex`][CITED: https://www.meilisearch.com/docs/capabilities/indexing/tasks_and_batches/async_operations][CITED: https://www.meilisearch.com/docs/capabilities/indexing/tasks_and_batches/filter_tasks][CITED: https://hexdocs.pm/oban/job_lifecycle.html] |
| OPS-02 | Operator can inspect and retry failed async or manual work through explicit Scrypath APIs and thin Mix tasks instead of backend-specific spelunking. [VERIFIED: `.planning/REQUIREMENTS.md`] | Model failed work as Scrypath-owned references with summarized reason, document ids, mode, and retryability; retry through existing Scrypath enqueue/write paths instead of exposing raw Oban or Meilisearch admin payloads. [VERIFIED: `lib/scrypath/oban/enqueue.ex` + `lib/scrypath/sync.ex` + `test/scrypath/oban/enqueue_test.exs` + `test/scrypath/oban/worker_test.exs`] |
| OPS-03 | Operator can run an explicit reconcile or recovery workflow that makes drift and reindex state legible without pretending automatic healing. [VERIFIED: `.planning/REQUIREMENTS.md`] | Add a Scrypath-owned reconcile report and explicit recovery actions that point to `backfill` or `reindex`, plus reindex visibility derived from target index naming and task state rather than hidden automation. [VERIFIED: `README.md` + `ARCHITECTURE.md` + `lib/scrypath/backfill.ex` + `lib/scrypath/reindex.ex`][CITED: https://www.meilisearch.com/docs/capabilities/indexing/tasks_and_batches/async_operations] |

## Summary

Phase 12 already did the hard prerequisite work: sync, enqueue, backfill, and reindex now exchange `%Scrypath.Operations.Result{}` and `%Scrypath.Operations.Task{}` internally instead of passing raw Meilisearch task maps through common orchestration. [VERIFIED: `.planning/phases/12-internal-operations-seam/12-VERIFICATION.md` + `lib/scrypath/operations.ex` + `lib/scrypath/sync.ex` + `lib/scrypath/backfill.ex` + `lib/scrypath/reindex.ex`] That means Phase 13 should not add more seam extraction; it should add a narrow public operator layer that reads from the seam and projects durable operator vocabulary. [VERIFIED: user prompt + `.planning/ROADMAP.md` + `ARCHITECTURE.md`]

The repo’s operator contract is already opinionated in docs: `:inline` means terminal backend success before return, `:manual` means accepted backend work only, and `:oban` means durable enqueue only, while all three modes share one operator-facing lifecycle and all recovery language stays explicit about drift. [VERIFIED: `README.md` + `ARCHITECTURE.md`] The missing piece is a Scrypath-owned read model that can answer, for a schema and mode, “what is pending, what failed, what last succeeded, and what should I do next?” without returning raw backend or queue payloads. [VERIFIED: user prompt + `.planning/REQUIREMENTS.md` + `lib/scrypath/operations/task.ex`]

The safest design is a small `Scrypath.Operator` namespace backed by Meilisearch task inspection plus optional Oban job inspection. [VERIFIED: `lib/scrypath/operations.ex` + `lib/scrypath/oban/enqueue.ex` + `README.md`] Meilisearch task filtering is the durable backend-side source of truth for inline and manual work, while Oban state adds queue-side visibility only when the app chose `sync_mode: :oban`. [VERIFIED: `README.md` + `ARCHITECTURE.md`][CITED: https://www.meilisearch.com/docs/capabilities/indexing/tasks_and_batches/filter_tasks][CITED: https://hexdocs.pm/oban/job_lifecycle.html]

**Primary recommendation:** Add `Scrypath.Operator.Status`, `Scrypath.Operator.FailedWork`, and `Scrypath.Operator.Reconcile` as public read/action structs on top of a slightly widened internal operations seam that can list Meilisearch tasks, inspect Oban jobs when available, and route retries back through existing Scrypath sync/enqueue/backfill/reindex code paths. [VERIFIED: `lib/scrypath/operations.ex` + `lib/scrypath/sync.ex` + `lib/scrypath/oban/enqueue.ex` + `lib/scrypath/backfill.ex` + `lib/scrypath/reindex.ex`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Schema sync status aggregation | API / Library core [VERIFIED: this is common Scrypath API work, not host-app UI work] | Backend admin adapter [VERIFIED: `lib/scrypath/operations.ex` + `README.md`] | The common operator API should own the stable struct, while Meilisearch-specific listing/filtering stays behind the internal seam. [VERIFIED: user prompt + `ARCHITECTURE.md`][CITED: https://www.meilisearch.com/docs/capabilities/indexing/tasks_and_batches/filter_tasks] |
| Queue-side failed work inspection | API / Library core [VERIFIED: `OPS-02` is a Scrypath API requirement] | Oban integration [VERIFIED: `lib/scrypath/oban/enqueue.ex`] | Queue state is only relevant in `:oban` mode, but the operator-facing failed-work shape should still be Scrypath-owned. [VERIFIED: `README.md` + `ARCHITECTURE.md`][CITED: https://hexdocs.pm/oban/job_lifecycle.html] |
| Retry action routing | API / Library core [VERIFIED: retry should reuse `Scrypath.*` orchestration] | Oban integration + backend admin adapter [VERIFIED: `lib/scrypath/sync.ex` + `lib/scrypath/oban/enqueue.ex`] | Retrying should call existing enqueue/write paths instead of exposing raw Oban or Meilisearch retry commands directly. [VERIFIED: repo code and tests] |
| Reconcile and drift reporting | API / Library core [VERIFIED: `OPS-03` + docs contract] | Backfill and reindex workflows [VERIFIED: `lib/scrypath/backfill.ex` + `lib/scrypath/reindex.ex`] | Drift handling is a decision/reporting concern first; the actual repair actions remain `backfill/2` and `reindex/2`. [VERIFIED: `README.md` + `ARCHITECTURE.md`] |
| Thin Mix-task ergonomics | Mix task layer in Phase 14 [VERIFIED: `.planning/ROADMAP.md`] | Public operator API [VERIFIED: Phase 14 depends on Phase 13] | Phase 13 should stop at API/structs and not absorb CLI concerns that the roadmap assigns to Phase 14. [VERIFIED: `.planning/ROADMAP.md`] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | `~> 1.17` support floor in the library; workspace currently on `1.19.5` [VERIFIED: `mix.exs` + `elixir --version`] | Public operator API modules, structs, and pattern-matched orchestration. [VERIFIED: repo is Elixir-only] | Existing repo patterns are function-heavy modules plus structs, not processes or macros. [VERIFIED: `lib/scrypath.ex` + `lib/scrypath/sync.ex` + `lib/scrypath/reindex.ex`] |
| Ecto | `3.13.5` published `2025-11-09` [VERIFIED: `mix hex.info ecto` + `curl https://hex.pm/api/packages/ecto`] | Querying Oban jobs and preserving Ecto-first ergonomics in operator APIs. [VERIFIED: `mix.exs` + repo architecture docs] | Scrypath’s public value is Ecto-native orchestration, and the test suite already uses Ecto-shaped query fixtures for operational flows. [VERIFIED: `README.md` + `ARCHITECTURE.md` + `test/scrypath/backfill_test.exs`] |
| Oban | `2.21.1` published `2026-03-26` [VERIFIED: `mix hex.info oban` + `curl https://hex.pm/api/packages/oban`] | Optional queue-side status and failed-work inspection for `sync_mode: :oban`. [VERIFIED: `mix.exs` + `lib/scrypath/oban/enqueue.ex`] | Oban is already the recommended durable async path and its state model maps directly to Phase 13 queue visibility. [VERIFIED: `.planning/PROJECT.md` + `README.md` + `ARCHITECTURE.md`][CITED: https://hexdocs.pm/oban/job_lifecycle.html] |
| Req | `0.5.17` published `2026-01-05` [VERIFIED: `mix hex.info req` + `curl https://hex.pm/api/packages/req`] | Existing transport for Meilisearch admin/task inspection. [VERIFIED: `mix.exs` + `lib/scrypath/meilisearch/client.ex`] | Phase 13 should reuse the current Meilisearch client path rather than adding a second transport or admin client abstraction. [VERIFIED: `README.md` + `lib/scrypath/meilisearch/tasks.ex` + `lib/scrypath/meilisearch/client.ex`] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Telemetry | repo dependency surface, first-class from project guidance [VERIFIED: `.planning/PROJECT.md` + `ARCHITECTURE.md` + `lib/scrypath/telemetry.ex`] | Emit operator-facing semantics such as status checks, retries, and reconcile runs without mirroring Oban internals. [VERIFIED: existing telemetry split in docs] | Use for common-path operator spans and low-cardinality metadata only. [VERIFIED: `ARCHITECTURE.md` + `.planning/phases/12-internal-operations-seam/12-VERIFICATION.md`] |
| Req.Test | repo test helper already used [VERIFIED: `test/scrypath/sync_test.exs` + `test/scrypath/meilisearch/tasks_test.exs`] | Stub Meilisearch task-list and task-detail responses in operator tests. [VERIFIED: existing test style] | Use whenever new operator APIs need HTTP-level verification without live Meilisearch. [VERIFIED: existing tests] |
| ExUnit | built-in test framework in repo [VERIFIED: all `test/scrypath/*_test.exs`] | File-focused contract tests for operator structs, status aggregation, and retry decisions. [VERIFIED: repo conventions] | Use for all Phase 13 verification; no new framework is needed. [VERIFIED: repo conventions] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Public `Scrypath.Operator.*` structs [VERIFIED: recommended path] | Extend `Scrypath.sync_*`/`backfill`/`reindex` result maps directly [VERIFIED: current public maps exist in `lib/scrypath/sync.ex` + `lib/scrypath/backfill.ex` + `lib/scrypath/reindex.ex`] | Overloading existing write-path result maps would blur “write request accepted” with “operator inspection result” and make Phase 14 Mix tasks harder to keep thin. [VERIFIED: repo docs emphasize explicit semantics] |
| Retry through Scrypath-owned replay paths [VERIFIED: recommended path] | Expose raw Oban rescue/retry or raw Meilisearch task actions publicly [VERIFIED: this is the rejected public-leak direction implied by the requirement] | Raw backend/admin controls would violate the requirement to avoid backend-specific spelunking and would weaken the stable common operator contract. [VERIFIED: user prompt + `.planning/REQUIREMENTS.md`] |

**Installation:** [VERIFIED: `mix.exs`]
```bash
mix deps.get
```

**Version verification:** [VERIFIED: `mix hex.info ecto` + `mix hex.info oban` + `mix hex.info req` + Hex package API]
```bash
mix hex.info ecto
mix hex.info oban
mix hex.info req
```

## Architecture Patterns

### System Architecture Diagram

```text
Host app / Mix task
    |
    v
Scrypath.Operator.status/2 | failed_work/2 | retry/2 | reconcile/2
    |
    +--> Scrypath.Operator.Status/FailedWork/Reconcile structs
    |
    +--> Scrypath.Operations admin seam
           |
           +--> Meilisearch task listing/filtering by index + type + status
           |       |
           |       +--> backend-side pending/failed/last-success visibility
           |
           +--> Oban job inspection by queue/worker/schema (only when configured)
                   |
                   +--> queue-side queued/retryable/discarded visibility
    |
    +--> explicit recovery action
           |
           +--> Scrypath.sync_* / Scrypath.Oban.Enqueue for retry
           +--> Scrypath.backfill/2 for live-index repair
           +--> Scrypath.reindex/2 for contract-change rebuild
```

The diagram matches the current repo boundary: public `Scrypath.*` orchestration, Meilisearch-specific work under `Scrypath.Meilisearch.*`, and optional queue work under `Scrypath.Oban.*`. [VERIFIED: `README.md` + `ARCHITECTURE.md` + `lib/scrypath/sync.ex` + `lib/scrypath/oban/enqueue.ex`]

### Recommended Project Structure

```text
lib/
├── scrypath/
│   ├── operator.ex                  # public facade and top-level API docs
│   ├── operator/
│   │   ├── status.ex                # %Status{} struct + normalization helpers
│   │   ├── failed_work.ex           # %FailedWork{} struct + retryability rules
│   │   ├── reconcile.ex             # %Reconcile{} report + action result
│   │   └── recovery_action.ex       # stable action/reference structs
│   ├── operations.ex                # extend seam with admin/list helpers
│   ├── operations/
│   │   ├── result.ex                # unchanged result envelope
│   │   ├── task.ex                  # unchanged task envelope
│   │   └── admin.ex                 # internal callbacks for task/job inspection
│   ├── meilisearch/
│   │   ├── operations.ex            # existing write adapter
│   │   └── tasks.ex                 # add list/filter helpers on current client
│   └── oban/
│       └── inspect.ex               # optional queue-state query helpers
test/
├── scrypath/
│   ├── operator_test.exs            # public facade contract tests
│   ├── operator/
│   │   ├── status_test.exs
│   │   ├── failed_work_test.exs
│   │   └── reconcile_test.exs
│   ├── meilisearch/
│   │   └── tasks_test.exs           # extend existing task-list coverage
│   └── oban/
│       └── inspect_test.exs
```

### Pattern 1: Public Operator Facade Over Seam-Owned Read Models

**What:** Add a new public namespace for operator inspection instead of widening existing write-result maps. [VERIFIED: `lib/scrypath.ex` currently exposes sync/backfill/reindex only, and docs say no public operator API existed before this phase]

**When to use:** Use for status inspection, failed-work listing, retry, and reconcile flows that are semantically different from ordinary sync writes. [VERIFIED: `.planning/ROADMAP.md` + `.planning/REQUIREMENTS.md`]

**Example:**
```elixir
# Source: repo-aligned recommendation derived from lib/scrypath.ex and Phase 13 requirements
defmodule Scrypath.Operator do
  @spec status(module(), keyword()) :: {:ok, Scrypath.Operator.Status.t()} | {:error, term()}
  def status(schema_module, opts \\ []) do
    Scrypath.Operator.Status.fetch(schema_module, opts)
  end

  @spec failed_work(module(), keyword()) ::
          {:ok, [Scrypath.Operator.FailedWork.t()]} | {:error, term()}
  def failed_work(schema_module, opts \\ []) do
    Scrypath.Operator.FailedWork.list(schema_module, opts)
  end
end
```

### Pattern 2: Split Queue Visibility From Backend Visibility, Then Merge In One Status Struct

**What:** Status should expose separate queue-side and backend-side buckets instead of collapsing them into one raw status field. [VERIFIED: `ARCHITECTURE.md` distinguishes durable enqueue from backend completion, and `lib/scrypath/operations.ex` already models queue jobs separately from backend tasks]

**When to use:** Use for `Scrypath.Operator.status/2` and `failed_work/2` so `:oban` can show queued or retryable work while inline/manual still show backend task state where available. [VERIFIED: `README.md` + `ARCHITECTURE.md`][CITED: https://hexdocs.pm/oban/job_lifecycle.html][CITED: https://www.meilisearch.com/docs/capabilities/indexing/tasks_and_batches/filter_tasks]

**Example:**
```elixir
# Source: repo-aligned recommendation derived from current seam structs and docs contract
defmodule Scrypath.Operator.Status do
  @enforce_keys [:schema, :mode, :index]
  defstruct [
    :schema,
    :mode,
    :index,
    backend: %{pending: [], failed: [], last_succeeded: nil},
    queue: %{pending: [], retrying: [], failed: [], last_succeeded: nil},
    reindex: %{active: false, target_index: nil, cutover_pending: false},
    signals: []
  ]
end
```

### Pattern 3: Explicit Reconcile Report, Explicit Recovery Action

**What:** Reconcile should return a report of observed drift signals plus a chosen recovery action; it should not silently repair anything. [VERIFIED: `README.md` + `ARCHITECTURE.md` repeatedly reject hidden healing]

**When to use:** Use when operators need to turn failed work, stale deletes, count mismatches, or in-progress target indexes into a documented next step. [VERIFIED: `README.md` + `ARCHITECTURE.md`]

**Example:**
```elixir
# Source: repo-aligned recommendation derived from README/ARCHITECTURE drift wording
%Scrypath.Operator.Reconcile{
  schema: MyApp.Post,
  index: "tenant_posts",
  signals: [:failed_work_present, :reindex_target_present],
  recommended_action: :reindex,
  runnable_actions: [:retry_failed, :backfill, :reindex]
}
```

### Anti-Patterns to Avoid

- **Raw payload passthrough:** Do not return `%Oban.Job{}` or full Meilisearch task objects from public operator APIs. [VERIFIED: user prompt + `.planning/REQUIREMENTS.md` + `lib/scrypath/operations.ex`]
- **Single flat status enum:** Do not collapse queue and backend states into one field such as `:failed`; `retryable` and `discarded` are queue facts, while `failed` and `canceled` are backend task facts. [VERIFIED: `ARCHITECTURE.md` + `lib/scrypath/operations.ex`][CITED: https://hexdocs.pm/oban/job_lifecycle.html][CITED: https://www.meilisearch.com/docs/capabilities/indexing/tasks_and_batches/async_operations]
- **Auto-heal wording:** Do not make `reconcile/2` perform writes by default or imply drift disappeared automatically. [VERIFIED: `README.md` + `ARCHITECTURE.md`]
- **Phase-14 leakage:** Do not build Mix tasks in Phase 13; Phase 13 should provide reusable structs and functions that Mix tasks can wrap later. [VERIFIED: `.planning/ROADMAP.md`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Backend task queue semantics | A custom task-state model unrelated to Meilisearch statuses [VERIFIED: tempting but wrong abstraction] | Meilisearch task status + filter endpoints behind Scrypath normalization. [CITED: https://www.meilisearch.com/docs/capabilities/indexing/tasks_and_batches/async_operations][CITED: https://www.meilisearch.com/docs/capabilities/indexing/tasks_and_batches/filter_tasks] | Meilisearch already exposes durable task history, filtering, and task type metadata that Phase 13 can summarize safely. [CITED: same official docs] |
| Queue lifecycle semantics | A second custom queue state machine in Scrypath [VERIFIED: current docs explicitly avoid this] | Oban’s existing lifecycle states, mapped into Scrypath-owned summaries. [VERIFIED: `ARCHITECTURE.md`][CITED: https://hexdocs.pm/oban/job_lifecycle.html] | Oban already defines available/scheduled/executing/retryable/completed/cancelled/discarded; Scrypath only needs projection, not reinvention. [CITED: https://hexdocs.pm/oban/job_lifecycle.html] |
| Retry transport | New bespoke retry workers or payload formats [VERIFIED: repo already serializes job payloads and has enqueue paths] | Existing `Scrypath.Oban.Enqueue` plus existing sync/backfill/reindex functions. [VERIFIED: `lib/scrypath/oban/enqueue.ex` + `lib/scrypath/sync.ex` + `lib/scrypath/backfill.ex` + `lib/scrypath/reindex.ex`] | Reusing current paths keeps retry behavior aligned with normal writes and avoids duplicate payload logic. [VERIFIED: repo code + tests] |

**Key insight:** Phase 13 is mostly projection and routing work, not new persistence or new transport work. [VERIFIED: existing seam and workflows already exist in Phase 12 code]

## Plan Split Suggestion

### Plan 13-01: Public operator structs and status aggregation

- **Scope:** Add `Scrypath.Operator`, `Scrypath.Operator.Status`, and internal inspection helpers that aggregate backend-side Meilisearch tasks plus optional queue-side Oban jobs into one Scrypath-owned status shape. [VERIFIED: recommended architecture above]
- **Primary files:** `lib/scrypath.ex`, `lib/scrypath/operator.ex`, `lib/scrypath/operator/status.ex`, `lib/scrypath/operations.ex`, `lib/scrypath/meilisearch/tasks.ex`, optional `lib/scrypath/oban/inspect.ex`. [VERIFIED: recommended project structure]
- **Tests:** `test/scrypath/operator_test.exs`, `test/scrypath/operator/status_test.exs`, extensions in `test/scrypath/meilisearch/tasks_test.exs` and `test/scrypath/oban/inspect_test.exs`. [VERIFIED: repo test style follows file-local coverage]
- **Verification target:** `OPS-01`. [VERIFIED: `.planning/REQUIREMENTS.md`]

### Plan 13-02: Failed work inspection and retry primitives

- **Scope:** Add `Scrypath.Operator.FailedWork` plus retry routing that replays work through `Scrypath.Oban.Enqueue` or existing backend write paths without exposing raw admin payloads. [VERIFIED: `OPS-02` + current enqueue/sync code]
- **Primary files:** `lib/scrypath/operator/failed_work.ex`, `lib/scrypath/operator/recovery_action.ex`, `lib/scrypath/oban/inspect.ex`, `lib/scrypath/operations.ex`. [VERIFIED: recommended structure]
- **Tests:** `test/scrypath/operator/failed_work_test.exs`, extensions to `test/scrypath/oban/enqueue_test.exs` and `test/scrypath/oban/worker_test.exs`. [VERIFIED: repo patterns already assert payload integrity and retryable-vs-cancelled worker semantics]
- **Verification target:** `OPS-02`. [VERIFIED: `.planning/REQUIREMENTS.md`]

### Plan 13-03: Reconcile report and reindex visibility

- **Scope:** Add `Scrypath.Operator.Reconcile` that makes drift signals and active rebuild state legible, then routes explicit actions to `backfill/2` or `reindex/2` without automatic healing. [VERIFIED: `OPS-03` + docs contract]
- **Primary files:** `lib/scrypath/operator/reconcile.ex`, `lib/scrypath/reindex.ex` only if extra public projection is needed, `README.md`/`ARCHITECTURE.md` only for narrow contract wording if required. [VERIFIED: recommended structure + docs contract tests]
- **Tests:** `test/scrypath/operator/reconcile_test.exs`, possibly `test/scrypath/docs_contract_test.exs` if wording changes. [VERIFIED: existing docs contract coverage]
- **Verification target:** `OPS-03`. [VERIFIED: `.planning/REQUIREMENTS.md`]

## Common Pitfalls

### Pitfall 1: Pretending manual mode is discoverable without explicit references

**What goes wrong:** The API promises complete manual-mode inspection even though Scrypath does not own a queue or app database history for manual work. [VERIFIED: `README.md` + `ARCHITECTURE.md` + current code has no persistence layer for operator history]
**Why it happens:** Manual mode returns accepted backend work immediately and leaves durability/retention to the backend task database and the operator. [VERIFIED: `README.md` + `lib/scrypath/sync.ex`]
**How to avoid:** Make manual visibility explicitly backend-task-based and scope claims with “where available,” using Meilisearch task history filtered by index and task type. [VERIFIED: requirement wording includes “where available”][CITED: https://www.meilisearch.com/docs/capabilities/indexing/tasks_and_batches/filter_tasks]
**Warning signs:** Status structs start inventing `last_success` data for manual mode without a corresponding backend task source or caller-supplied reference. [VERIFIED: current repo has no such source]

### Pitfall 2: Collapsing `retryable` and `failed` into the same meaning

**What goes wrong:** Queue jobs waiting for retry are reported as terminal failures, or backend task failures are reported as queue retries. [VERIFIED: distinct state systems exist in repo docs and official docs]
**Why it happens:** Oban and Meilisearch model different lifecycle layers. [VERIFIED: `ARCHITECTURE.md` + `lib/scrypath/operations.ex`][CITED: https://hexdocs.pm/oban/job_lifecycle.html][CITED: https://www.meilisearch.com/docs/capabilities/indexing/tasks_and_batches/async_operations]
**How to avoid:** Keep separate `queue` and `backend` sections in public status/failed-work structs and summarize them into operator signals instead of flattening them. [VERIFIED: recommended pattern above]
**Warning signs:** A single `state` field starts needing incompatible values like `:retryable`, `:discarded`, and `:canceled` from different systems. [VERIFIED: official docs and current seam model]

### Pitfall 3: Leaking raw `raw` payloads because they are convenient in tests

**What goes wrong:** Public operator structs expose the `raw` task/job maps that currently live inside internal seam structs. [VERIFIED: `lib/scrypath/operations/task.ex` carries `raw`; public sync maps already keep this boundary deliberate]
**Why it happens:** Existing sync/backfill public maps still expose backend/task detail for write results, and tests already assert parts of those maps. [VERIFIED: `lib/scrypath/sync.ex` + `lib/scrypath/backfill.ex` + tests]
**How to avoid:** Limit public operator structs to stable identifiers, timestamps, type, summarized reason, and retryability; keep raw payloads internal or namespaced under backend-specific modules only. [VERIFIED: user prompt + repo boundary docs]
**Warning signs:** Operator tests assert on task `error`, `details`, or full job args instead of stable Scrypath-owned fields. [VERIFIED: this would violate Phase 13 goals]

### Pitfall 4: Turning reconcile into an automatic fix button

**What goes wrong:** `reconcile/2` mutates state immediately, hiding whether it chose backfill or reindex and why. [VERIFIED: this conflicts with docs contract]
**Why it happens:** Repair workflows are tempting to compress into one command. [ASSUMED]
**How to avoid:** Make `reconcile/2` return a report and require an explicit `action:` or follow-up function for mutation. [VERIFIED: repo docs emphasize explicit backfill vs reindex choices]
**Warning signs:** Operator output says “healed” without listing the invoked workflow, target index, or remaining drift signals. [VERIFIED: current docs reject optimistic wording]

## Code Examples

Verified repo patterns from local sources:

### Seam-Owned Result Before Public Projection
```elixir
# Source: /Users/jon/projects/scrypath/lib/scrypath/operations.ex
def result_from_enqueue(payload, opts \\ []) when is_map(payload) do
  job = Map.fetch!(payload, :job)

  Result.new(
    mode: Keyword.get(opts, :mode, :oban),
    status: Keyword.get(opts, :status, :accepted),
    document_ids: Map.get(payload, :document_ids, []),
    document_count: Map.get(payload, :document_count, 0),
    task:
      Task.new(
        source: :oban,
        kind: :queue_job,
        id: Map.get(job, :id),
        state: normalize_queue_state(Map.get(job, :state)),
        reference: %{job_id: Map.get(job, :id), worker: Map.get(job, :worker), queue: Map.get(job, :queue)},
        metadata: %{oban_state: Map.get(job, :state)},
        raw: job
      )
  )
end
```

### Existing Reindex Workflow As Explicit Recovery Path
```elixir
# Source: /Users/jon/projects/scrypath/lib/scrypath/reindex.ex
with {:ok, create_result} <- meilisearch.create_index(schema_module, primary_key(schema_module), workflow_config),
     {:ok, _create_result} <- maybe_wait_for_result_task(create_result, workflow_config),
     {:ok, settings_result} <- meilisearch.apply_settings(schema_module, target_index, workflow_config),
     {:ok, _settings_result} <- maybe_wait_for_result_task(settings_result, workflow_config),
     {:ok, backfill_result} <- backfill.run(schema_module, workflow_config |> backfill_config() |> Keyword.put(:index_name, target_index)),
     {:ok, _backfill_result} <- maybe_wait_for_backfill_tasks(backfill_result, workflow_config),
     {:ok, cutover} <- maybe_cutover(schema_module, workflow_config, meilisearch) do
  {:ok, %{live_index: live_index, target_index: target_index, settings_applied: true, batches: Map.fetch!(backfill_result, :batches), documents: Map.fetch!(backfill_result, :documents), cutover: cutover}}
end
```

### Recommended Failed-Work Shape
```elixir
# Source: repo-aligned recommendation derived from current seam and docs contract
defmodule Scrypath.Operator.FailedWork do
  @enforce_keys [:reference, :mode, :operation, :state, :retryable?]
  defstruct [
    :reference,
    :mode,
    :operation,
    :state,
    :retryable?,
    :index,
    :document_ids,
    :attempt,
    :max_attempts,
    :failed_at,
    :reason,
    metadata: %{}
  ]
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Common orchestration passed raw task-ish maps and inferred followability from backend identity. [VERIFIED: described in Phase 12 research and fixed in Phase 12 code] | Common orchestration now uses `%Scrypath.Operations.Result{}` and `%Scrypath.Operations.Task{}` before projecting public maps. [VERIFIED: `lib/scrypath/operations.ex` + `lib/scrypath/sync.ex` + `lib/scrypath/reindex.ex`] | Phase 12 on 2026-04-16. [VERIFIED: `.planning/phases/12-internal-operations-seam/12-VERIFICATION.md`] | Phase 13 can build a public operator API without reopening seam extraction. [VERIFIED: repo evidence] |
| No public operator namespace existed. [VERIFIED: `lib/scrypath.ex` + `README.md` + `ARCHITECTURE.md`] | Roadmap now explicitly expects Phase 13 to add operator primitives and Phase 14 to add thin Mix tasks on top. [VERIFIED: `.planning/ROADMAP.md`] | Milestone v1.2 defined 2026-04-16. [VERIFIED: `.planning/PROJECT.md` + `.planning/ROADMAP.md`] | The public API can now add a narrow operator namespace without contradicting prior docs, as long as it stays Meilisearch-first and explicit. [VERIFIED: roadmap + requirements + prompt] |

**Deprecated/outdated:**
- “No public operator API in this phase” language from Phase 12 is outdated for Phase 13 planning, but the narrower point still holds: the new API should sit on top of the private seam rather than turn the seam itself into the public contract. [VERIFIED: `ARCHITECTURE.md` + `.planning/ROADMAP.md`]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Reconcile is best expressed as a report-first API with explicit follow-up action rather than a mutating function by default. [ASSUMED] | `Architecture Patterns`, `Common Pitfalls` | Low to medium; if users strongly prefer a direct mutating API, planner may need a small naming adjustment, but the repo’s explicitness bias still argues against silent healing. |

## Open Questions

1. **How much Oban inspection should Phase 13 own directly?**
   - What we know: Scrypath already owns enqueue payload shape and recommends Oban as the production async path. [VERIFIED: `lib/scrypath/oban/enqueue.ex` + `.planning/PROJECT.md` + `README.md`]
   - What's unclear: Whether Phase 13 should query Oban jobs directly by worker/queue/schema or require caller-provided filters for multi-tenant apps. [VERIFIED: no current repo module answers this]
   - Recommendation: Plan for a narrow internal `Scrypath.Oban.Inspect` helper that filters by Scrypath workers and index/schema metadata only, leaving broader Oban admin concerns out of scope. [VERIFIED: recommended structure + project scope]

2. **Should last successful activity come from backend tasks only, or also from queue success?**
   - What we know: Inline/manual success maps to backend task completion, while Oban has both queue completion and backend completion layers. [VERIFIED: `ARCHITECTURE.md` + `lib/scrypath/operations.ex`][CITED: https://hexdocs.pm/oban/job_lifecycle.html][CITED: https://www.meilisearch.com/docs/capabilities/indexing/tasks_and_batches/async_operations]
   - What's unclear: Whether the public status struct should expose both timestamps separately or collapse them into one canonical “last success.” [VERIFIED: current repo has no operator struct]
   - Recommendation: Expose both `queue.last_succeeded` and `backend.last_succeeded` in Phase 13 to preserve explicitness. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Implementation and tests [VERIFIED: repo is Elixir] | ✓ [VERIFIED: `elixir --version`] | `1.19.5` [VERIFIED: `elixir --version`] | — |
| Mix | Test and verification commands [VERIFIED: repo uses Mix] | ✓ [VERIFIED: `mix --version`] | `1.19.5` [VERIFIED: `mix --version`] | — |
| Erlang/OTP | Runtime and test execution [VERIFIED: repo + environment] | ✓ [VERIFIED: `erl ... otp_release`] | `28` [VERIFIED: `erl ... otp_release`] | — |
| Hex package metadata access | Version verification during research [VERIFIED: `mix hex.info` worked] | ✓ [VERIFIED: `mix hex.info ecto` + `mix hex.info oban` + `mix hex.info req`] | package metadata current as of 2026-04-16 [VERIFIED: command outputs + Hex API] | `curl https://hex.pm/api/packages/<pkg>` [VERIFIED: used in this research] |

**Missing dependencies with no fallback:**
- None found for Phase 13 research or planning. [VERIFIED: environment probes above]

**Missing dependencies with fallback:**
- Oban remains an optional dependency at runtime for library consumers, but Phase 13 should still support non-Oban inline/manual inspection through Meilisearch task data. [VERIFIED: `mix.exs` + `README.md` + `ARCHITECTURE.md`]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit with Req.Test-based HTTP stubs and local fixture modules. [VERIFIED: `test/scrypath/sync_test.exs` + `test/scrypath/meilisearch/tasks_test.exs` + `test/scrypath/operations_test.exs`] |
| Config file | none visible at repo root beyond standard Mix project layout. [VERIFIED: repo root listing + `rg` probe] |
| Quick run command | `MIX_ENV=test mix test test/scrypath/operator_test.exs test/scrypath/operator/status_test.exs` after files exist. [ASSUMED] |
| Full suite command | `mix test` [VERIFIED: Mix-based ExUnit repo + current test layout] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| OPS-01 | Status reports pending, failed, and last-success visibility across modes where available. [VERIFIED: requirement] | unit/integration [VERIFIED: matches repo style] | `MIX_ENV=test mix test test/scrypath/operator/status_test.exs` [ASSUMED] | ❌ Wave 0 |
| OPS-02 | Failed work can be listed and retried through Scrypath-owned APIs. [VERIFIED: requirement] | unit/integration [VERIFIED: queue and backend adapters need direct tests] | `MIX_ENV=test mix test test/scrypath/operator/failed_work_test.exs test/scrypath/oban/enqueue_test.exs` [ASSUMED] | ❌ Wave 0 |
| OPS-03 | Reconcile makes drift and reindex state legible and routes explicit recovery actions. [VERIFIED: requirement] | unit/integration/docs-contract [VERIFIED: repo tests docs wording when semantics matter] | `MIX_ENV=test mix test test/scrypath/operator/reconcile_test.exs test/scrypath/reindex_test.exs test/scrypath/docs_contract_test.exs` [ASSUMED] | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `MIX_ENV=test mix test test/scrypath/operator_test.exs test/scrypath/operator/status_test.exs` once those files exist. [ASSUMED]
- **Per wave merge:** `MIX_ENV=test mix test test/scrypath/operations_test.exs test/scrypath/meilisearch/tasks_test.exs test/scrypath/oban/enqueue_test.exs test/scrypath/oban/worker_test.exs test/scrypath/sync_test.exs test/scrypath/backfill_test.exs test/scrypath/reindex_test.exs test/scrypath/docs_contract_test.exs` [VERIFIED: these are the relevant existing files; command composition is recommended]
- **Phase gate:** `mix test` plus targeted doc-contract coverage green before `/gsd-verify-work`. [VERIFIED: repo uses Mix + docs contract tests already exist]

### Wave 0 Gaps

- [ ] `test/scrypath/operator_test.exs` — top-level public API contract for `Scrypath.Operator.*`. [VERIFIED: file absent in current repo]
- [ ] `test/scrypath/operator/status_test.exs` — cross-mode status aggregation and last-success coverage. [VERIFIED: file absent]
- [ ] `test/scrypath/operator/failed_work_test.exs` — failed-work normalization, retryability, and replay routing. [VERIFIED: file absent]
- [ ] `test/scrypath/operator/reconcile_test.exs` — drift/reindex visibility and explicit recovery actions. [VERIFIED: file absent]
- [ ] Optional `test/scrypath/oban/inspect_test.exs` — queue inspection helper coverage if a dedicated helper module is added. [VERIFIED: file absent]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no [VERIFIED: Phase 13 is library operator visibility, not auth] | — |
| V3 Session Management | no [VERIFIED: same scope reasoning] | — |
| V4 Access Control | no at the library common-path level; host apps own authorization around operator APIs. [VERIFIED: README positions Scrypath as library APIs, not dashboard product] | Keep operator APIs pure and require caller-supplied credentials/config; do not invent host-app authorization. [VERIFIED: project boundary docs] |
| V5 Input Validation | yes [VERIFIED: operator APIs will accept filters/references/options] | Reuse explicit options validation and stable structs; reject malformed references rather than passing them through. [VERIFIED: repo already uses explicit options validation in `lib/scrypath/options.ex`] |
| V6 Cryptography | no [VERIFIED: no cryptographic behavior is in scope] | — |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Exposing raw job args or backend payloads through public operator APIs [VERIFIED: user prompt forbids this direction] | Information Disclosure | Return Scrypath-owned summaries only; keep raw payloads internal or backend-namespaced. [VERIFIED: repo boundary docs + prompt] |
| Running retry/reconcile against the wrong index in multi-index apps [VERIFIED: index targeting is explicit throughout repo] | Tampering | Carry explicit `index` and `reference` fields through operator structs and require caller confirmation/action. [VERIFIED: `lib/scrypath/backfill.ex` + `lib/scrypath/reindex.ex` + docs] |
| Treating queue acceptance as search visibility [VERIFIED: repo docs call this out repeatedly] | Integrity | Keep queue-side and backend-side success distinct in status structs and docs. [VERIFIED: `README.md` + `ARCHITECTURE.md`][CITED: https://hexdocs.pm/oban/job_lifecycle.html][CITED: https://www.meilisearch.com/docs/capabilities/indexing/tasks_and_batches/async_operations] |

## Sources

### Primary (HIGH confidence)

- Local repo planning artifacts and code: `.planning/PROJECT.md`, `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/phases/12-internal-operations-seam/12-RESEARCH.md`, `.planning/phases/12-internal-operations-seam/12-VERIFICATION.md`, `README.md`, `ARCHITECTURE.md`, `lib/scrypath/operations.ex`, `lib/scrypath/operations/result.ex`, `lib/scrypath/operations/task.ex`, `lib/scrypath/sync.ex`, `lib/scrypath/backfill.ex`, `lib/scrypath/reindex.ex`, `lib/scrypath/oban/enqueue.ex`, `test/scrypath/operations_test.exs`, `test/scrypath/sync_test.exs`, `test/scrypath/backfill_test.exs`, `test/scrypath/reindex_test.exs`. [VERIFIED: files read directly in this session]
- Meilisearch official docs on asynchronous operations and task filtering. [CITED: https://www.meilisearch.com/docs/capabilities/indexing/tasks_and_batches/async_operations][CITED: https://www.meilisearch.com/docs/capabilities/indexing/tasks_and_batches/filter_tasks]
- Oban official docs on job lifecycle and job schema. [CITED: https://hexdocs.pm/oban/job_lifecycle.html][CITED: https://hexdocs.pm/oban/Oban.Job.html]
- Hex package metadata for current versions: Ecto `3.13.5`, Oban `2.21.1`, Req `0.5.17`. [VERIFIED: `mix hex.info ...` + Hex API]

### Secondary (MEDIUM confidence)

- Local prompt references on Elixir OSS and search-library product shape, used only to reinforce repo-aligned API discipline rather than override repo evidence. [VERIFIED: `prompts/elixir-opensource-libs-best-practices-deep-research.md` + `prompts/search-lib-use-cases-deep-research.md`]

### Tertiary (LOW confidence)

- None. [VERIFIED: all non-repo claims were checked against official docs or package metadata]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - versions and release dates were verified from Hex metadata and match the repo lock/config. [VERIFIED: `mix hex.info` + Hex API + `mix.exs`]
- Architecture: HIGH - repo docs, current seam code, and Phase 12 verification all align on the recommended direction. [VERIFIED: planning artifacts + code]
- Pitfalls: HIGH - each pitfall is grounded in current repo contracts or official lifecycle docs. [VERIFIED: repo docs + cited official docs]

**Research date:** 2026-04-16 [VERIFIED: current workspace date]  
**Valid until:** 2026-05-16 for repo-shape findings; recheck official Meilisearch and Oban docs sooner if those dependencies change. [VERIFIED: repo findings are stable; external lifecycle docs are reasonably stable but dependency-sensitive]
