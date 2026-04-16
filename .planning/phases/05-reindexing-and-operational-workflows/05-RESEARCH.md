# Phase 5: Reindexing and Operational Workflows - Research

**Researched:** 2026-04-16 [VERIFIED: system date]
**Domain:** Ecto-native bulk backfill, Meilisearch managed reindexing, and operator recovery workflows [VERIFIED: roadmap + requirements]
**Confidence:** MEDIUM [ASSUMED]

<user_constraints>
## User Constraints

### Locked Constraints (derived from project docs and completed phases; no Phase 5 CONTEXT.md exists) [VERIFIED: gsd init + AGENTS.md + .planning/STATE.md]
- Public v1 backend target is Meilisearch, while the backend seam stays internal and v1 must avoid a premature public multi-backend abstraction. [VERIFIED: AGENTS.md + README.md + ARCHITECTURE.md]
- v1 must support inline, Oban-backed, and manual synchronization flows, and those flows already share the existing `Scrypath.*` sync verbs plus top-level `mode` and `status` metadata. [VERIFIED: AGENTS.md + .planning/STATE.md + lib/scrypath/sync.ex]
- Operational clarity is a product requirement: eventual consistency, delete semantics, backfills, reindex workflows, retries, discarded jobs, and drift must stay explicit in APIs and docs rather than hidden behind optimistic wording. [VERIFIED: AGENTS.md + README.md + ARCHITECTURE.md]
- The common public path stays under `Scrypath.*`; Meilisearch-native behavior stays under `Scrypath.Meilisearch.*` as the explicit escape hatch. [VERIFIED: README.md + ARCHITECTURE.md + .planning/phases/02-meilisearch-core-sync/02-04-SUMMARY.md + .planning/phases/03-search-query-api-and-hydration/03-04-SUMMARY.md]
- Phase 5 should extend the documented Meilisearch-native boundary for index-level operations instead of widening the common sync/search contracts with backend-specific flags. [VERIFIED: .planning/phases/02-meilisearch-core-sync/02-04-SUMMARY.md]
- Public telemetry must remain low-cardinality on the common path, with Meilisearch-specific request and task detail scoped to backend-prefixed events. [VERIFIED: .planning/STATE.md + .planning/phases/04-oban-and-observability/04-03-SUMMARY.md + lib/scrypath/telemetry.ex]

### Claude's Discretion Areas (because there is no Phase 5 CONTEXT.md) [VERIFIED: gsd init]
- Exact public API names for bulk backfill and managed reindex verbs. [ASSUMED]
- Whether managed reindexing is one public common-path verb plus backend-native detail helpers, or a thin common orchestrator paired with Meilisearch-only admin modules. [ASSUMED]
- Exact settings surface: how much should be derived from existing schema metadata versus exposed as explicit Meilisearch-specific declaration hooks. [ASSUMED]
- Exact plan split across implementation and docs/tests. [ASSUMED]

### Deferred Ideas (already out of scope for v1) [VERIFIED: .planning/REQUIREMENTS.md]
- Public multi-backend parity in v1. [VERIFIED: .planning/REQUIREMENTS.md]
- Postgres-native full-text search as a coequal v1 feature. [VERIFIED: .planning/REQUIREMENTS.md]
- Vector search, hybrid retrieval, analytics, and advanced backend-native feature parity. [VERIFIED: .planning/REQUIREMENTS.md]
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| OPER-01 | Developer can bulk backfill an index from existing Ecto records. [VERIFIED: .planning/REQUIREMENTS.md] | Use repo-owned queryables with explicit `batch_size`, `preload`, and `sync_mode`; stream or page records in batches and delegate each batch to the existing sync path. [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html#c:stream/2] [VERIFIED: lib/scrypath/sync.ex] |
| OPER-02 | Developer can trigger a reindex workflow intentionally rather than reimplementing it ad hoc. [VERIFIED: .planning/REQUIREMENTS.md] | Use a managed Meilisearch workflow: explicit working index creation, settings application, bulk backfill, validation, atomic swap, and optional cleanup/rollback retention. [CITED: https://www.meilisearch.com/docs/resources/internals/indexes] |
| OPER-03 | Developer can apply index settings as part of managed indexing workflows. [VERIFIED: .planning/REQUIREMENTS.md] | Apply settings before document import on the working index, derive generic settings from schema metadata, and keep Meilisearch-native settings explicit under the Meilisearch boundary. [CITED: https://www.meilisearch.com/docs/resources/internals/indexes] [VERIFIED: lib/scrypath/options.ex + README.md] |
| OPER-05 | Developer can understand eventual consistency, failure modes, and recovery workflows from the official documentation. [VERIFIED: .planning/REQUIREMENTS.md] | Document drift signals, task states, stale-doc symptoms, cutover failure semantics, rollback options, and recovery playbooks; keep docs wording testable like Phase 4. [CITED: https://www.meilisearch.com/docs/reference/api/async-task-management/list-tasks] [CITED: https://www.meilisearch.com/docs/reference/api/stats/get-stats-of-all-indexes] [VERIFIED: test/scrypath/telemetry_test.exs] |
</phase_requirements>

## Summary

Phase 5 should stay small on the public surface and heavy on explicit operator semantics. The repo already has the right foundation: one common sync contract, one explicit Meilisearch escape hatch, optional Oban durability, and low-cardinality telemetry. The missing layer is not another generic abstraction; it is an operational orchestration layer that can rebuild an index predictably without widening the existing common API with raw Meilisearch concepts. [VERIFIED: lib/scrypath/sync.ex + lib/scrypath/meilisearch.ex + README.md + ARCHITECTURE.md]

The safest planning shape is: a common `Scrypath` operator API for backfill/reindex entrypoints, explicit Meilisearch admin helpers for create/settings/stats/swap/delete, and a workflow that always uses a working index for rebuilds. Meilisearch documents explicit index creation as safer for production than implicit creation, requires settings such as `filterableAttributes` and `sortableAttributes` before those search features work, and documents atomic index swapping for zero-downtime cutover. [CITED: https://www.meilisearch.com/docs/resources/internals/indexes]

Backfill should remain Ecto-native by taking a caller-owned repo/queryable and explicit batching options instead of hiding database pagination rules. Ecto documents `Repo.stream/2` as a lazy enumerable consumed inside a transaction, and Ecto 3.13 prefers `Repo.transact/2` over the deprecated `transaction/2`. That makes the right default an explicit batch enumerator with clearly documented memory, preload, and transaction tradeoffs, plus optional Oban fan-out only when the caller chooses durability over direct operator control. [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html#c:stream/2] [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html#c:transact/2] [CITED: https://hexdocs.pm/oban/Oban.html#insert_all/3]

**Primary recommendation:** Build Phase 5 as four plans: common operator contracts, Meilisearch index/settings primitives, explicit bulk backfill plus managed swap orchestration, and operator docs/tests. [ASSUMED]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Bulk record enumeration from application data | Database / Storage | API / Backend | Ecto repo/queryable owns record selection, transactional streaming, and preload semantics; Scrypath should consume explicit queryables rather than inventing its own hidden data source rules. [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html#c:stream/2] |
| Batch projection into search documents | API / Backend | Database / Storage | Projection already lives in pure Elixir over loaded records and must stay explicit about preload requirements. [VERIFIED: lib/scrypath/projection.ex] |
| Bulk upsert/delete dispatch | API / Backend | CDN / Static | Existing sync verbs and backend adapter dispatch already live on the library side. [VERIFIED: lib/scrypath/sync.ex + lib/scrypath/backend.ex] |
| Working-index creation, settings application, stats lookup, and swap | API / Backend | External service boundary | These are backend-admin calls to Meilisearch and belong in the explicit Meilisearch namespace, not in Ecto schemas. [VERIFIED: ARCHITECTURE.md] [CITED: https://www.meilisearch.com/docs/resources/internals/indexes] |
| Durable backfill/reindex execution | API / Backend | Database / Storage | Oban is the optional durable path and already owns durable enqueue semantics. [VERIFIED: lib/scrypath/oban.ex + README.md] [CITED: https://hexdocs.pm/oban/Oban.html] |
| Drift visibility and operator recovery docs | API / Backend | Database / Storage | Scrypath can expose stats, task states, and symptoms, but the source of truth remains Postgres while recovery drives Meilisearch state back toward it. [VERIFIED: README.md] [CITED: https://www.meilisearch.com/docs/reference/api/stats/get-stats-of-all-indexes] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `ecto` | `3.13.5` (`2025-11-09`) [VERIFIED: hex.pm api] | Query building, `Repo.transact/2`, and batch-safe streaming for bulk backfill. [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html#c:stream/2] | The current repo already uses Ecto as the source-of-truth integration surface, and Ecto is the native way to keep record selection and preload semantics explicit. [VERIFIED: mix.exs + AGENTS.md] |
| `req` | `0.5.17` (`2026-01-05`) [VERIFIED: hex.pm api] | HTTP transport for Meilisearch admin endpoints such as create index, update settings, stats, tasks, swap, and delete. [VERIFIED: lib/scrypath/meilisearch/client.ex] | Reusing the current client keeps Phase 5 inside the existing boring transport boundary instead of adding another HTTP layer. [VERIFIED: mix.exs + lib/scrypath/meilisearch/client.ex] |
| `oban` | `2.21.1` (`2026-03-26`) [VERIFIED: hex.pm api] | Optional durable fan-out for large backfills or long-running managed reindex jobs. [CITED: https://hexdocs.pm/oban/Oban.html#insert_all/3] | The repo already standardized Oban as the optional durable path, and Oban documents bulk insert plus job telemetry without forcing it into the core path. [VERIFIED: mix.exs + README.md] [CITED: https://hexdocs.pm/oban/Oban.html] |
| `telemetry` | `1.4.1` (`2026-03-09`) [VERIFIED: hex.pm api] | Reindex/backfill lifecycle spans and low-cardinality operator visibility. [VERIFIED: lib/scrypath/telemetry.ex] | Phase 4 already established the public/common telemetry boundary, so Phase 5 should extend it instead of inventing a second observability model. [VERIFIED: .planning/phases/04-oban-and-observability/04-03-SUMMARY.md] |
| `nimble_options` | `1.1.1` (`2024-05-25`) [VERIFIED: hex.pm api] | Validation for new backfill/reindex/settings options. [VERIFIED: lib/scrypath/options.ex] | The repo already relies on it for schema/runtime/search option validation, so extending that contract is lower risk than adding ad hoc argument parsing. [VERIFIED: mix.exs + lib/scrypath/options.ex] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Req.Test` | bundled with `req 0.5.17` [VERIFIED: codebase grep] | Stub Meilisearch admin HTTP flows without a live cluster. [VERIFIED: test/scrypath/meilisearch_test.exs] | Use for fast contract tests over create/settings/stats/swap/delete flows. [VERIFIED: existing test pattern] |
| ExUnit | bundled with Elixir `1.19.5` [VERIFIED: `elixir --version`] | Unit and focused integration tests. [VERIFIED: test/test_helper.exs] | Use for all new phase tests and doc-text assertions. [VERIFIED: existing test suite] |
| Docker | `29.3.1` [VERIFIED: `docker --version`] | Optional live Meilisearch smoke validation when a local binary is absent. [VERIFIED: environment audit] | Use for manual/e2e validation because the local `meilisearch` binary is not installed here. [VERIFIED: environment audit] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| One opaque `Scrypath.reindex/3` that hides batch and cutover details [ASSUMED] | A thin operator verb plus explicit per-step results and Meilisearch-native helpers [ASSUMED] | The explicit shape matches existing Scrypath contracts and keeps operator failure states legible. [VERIFIED: README.md + ARCHITECTURE.md] |
| Implicit Meilisearch index creation during the first document write [CITED: https://www.meilisearch.com/docs/resources/internals/indexes] | Explicit create-index before settings and import [CITED: https://www.meilisearch.com/docs/resources/internals/indexes] | Explicit creation is documented as safer for production because implicit creation bundles multiple actions into one task. [CITED: https://www.meilisearch.com/docs/resources/internals/indexes] |
| Reindexing in place on the live index [ASSUMED] | Working index + atomic swap [CITED: https://www.meilisearch.com/docs/resources/internals/indexes] | In-place rebuild risks downtime and mixed settings/data states; swap is documented as atomic. [CITED: https://www.meilisearch.com/docs/resources/internals/indexes] |
| Hidden internal pagination rules for bulk backfill [ASSUMED] | Explicit `batch_size`, queryable, preload, and optional streaming/page mode [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html#c:stream/2] | Hidden batching semantics would violate the project’s “no hidden reality” product boundary. [VERIFIED: AGENTS.md] |

**Installation:** [VERIFIED: mix.exs]
```bash
mix deps.get
```

No new runtime dependencies are necessary for the recommended Phase 5 implementation. [VERIFIED: mix.exs]

## Architecture Patterns

### System Architecture Diagram
```text
Operator/API call
    |
    v
Scrypath.Backfill / Scrypath.Reindex (common operator entrypoints)
    |
    +--> validate options (NimbleOptions) --> resolve repo/backend/config
    |
    +--> build source enumerable from explicit Ecto queryable
    |        |
    |        +--> stream in Repo.transact/2 for large consistent scans
    |        \--> page/chunk explicitly when transaction-scoped streaming is not desired
    |
    +--> project records -> Scrypath.Document batches
    |
    +--> dispatch batch writes through existing sync/admin paths
             |
             +--> Scrypath.Meilisearch.Indexes.create/update_settings/stats/swap/delete
             +--> Scrypath.sync_records(..., sync_mode: :manual | :inline | :oban)
             \--> Oban optional durable execution
    |
    +--> collect batch/task telemetry and operator-visible progress
    |
    \--> return explicit result envelope
             |
             +--> pre-cutover failure => live index untouched, working index retained
             +--> swap task failure => atomic no-cutover
             \--> post-cutover cleanup failure => both indexes visible for manual cleanup/rollback
```

### Recommended Project Structure
```text
lib/
├── scrypath/backfill.ex                 # Common bulk enumeration and batch orchestration
├── scrypath/reindex.ex                  # Managed reindex workflow and result envelopes
├── scrypath/options.ex                  # Extended backfill/reindex/settings validation
├── scrypath/meilisearch/indexes.ex      # Create, settings, stats, swap, delete helpers
├── scrypath/meilisearch/settings.ex     # Derive/apply Meilisearch settings from schema + explicit hook
└── scrypath/meilisearch/client.ex       # Extend existing HTTP transport with admin endpoints

test/
├── scrypath/backfill_test.exs
├── scrypath/reindex_test.exs
├── scrypath/meilisearch/indexes_test.exs
└── scrypath/operational_docs_test.exs
```

### Pattern 1: Explicit Batch Enumerator
**What:** Accept `repo:`, an explicit queryable or schema module, `batch_size:`, and optional `preload:` so bulk backfill stays obviously tied to Ecto semantics. [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html#c:stream/2] [VERIFIED: lib/scrypath/projection.ex]
**When to use:** For OPER-01 backfills and as the inner engine of managed reindexing. [VERIFIED: .planning/REQUIREMENTS.md]
**Example:**
```elixir
# Source: https://hexdocs.pm/ecto/Ecto.Repo.html#c:stream/2
repo.transact(fn ->
  queryable
  |> repo.stream()
  |> Stream.chunk_every(batch_size)
  |> Enum.reduce_while(initial_acc, fn records, acc ->
    projected = Enum.map(records, &Scrypath.Projection.document(schema, &1))
    case Scrypath.sync_records(schema, records, sync_opts) do
      {:ok, result} -> {:cont, update_acc(acc, result)}
      {:error, reason} -> {:halt, {:error, reason, acc}}
    end
  end)
end)
```

### Pattern 2: Managed Working Index Workflow
**What:** Create a working index, apply settings before document import, bulk load into the working index, validate stats, then atomic-swap into the live UID. [CITED: https://www.meilisearch.com/docs/resources/internals/indexes]
**When to use:** For schema changes, settings changes, or drift recovery when operators want a supported rebuild path. [VERIFIED: roadmap + README.md]
**Example:**
```elixir
# Source: https://www.meilisearch.com/docs/resources/internals/indexes
with {:ok, create} <- Scrypath.Meilisearch.Indexes.create(working_uid, primary_key, config),
     {:ok, _settings} <- Scrypath.Meilisearch.Indexes.apply_settings(working_uid, settings, config),
     {:ok, backfill} <- Scrypath.Backfill.run(schema, repo: Repo, index_name: working_uid, ...),
     {:ok, _stats} <- Scrypath.Meilisearch.Indexes.stats(working_uid, config),
     {:ok, swap} <- Scrypath.Meilisearch.Indexes.swap(live_uid, working_uid, config) do
  {:ok, %{create: create, backfill: backfill, swap: swap}}
end
```

### Pattern 3: Settings Are Applied Deliberately, Not on Every Write
**What:** Derive baseline search settings from schema metadata (`document_id`, `filterable`, `sortable`) and merge any explicit Meilisearch-only settings from a Meilisearch-native declaration hook or option surface. [VERIFIED: lib/scrypath/options.ex + README.md] [ASSUMED]
**When to use:** On working-index creation and any operator-invoked settings refresh, not on ordinary `sync_record/3` calls. [CITED: https://www.meilisearch.com/docs/resources/internals/indexes] [ASSUMED]
**Example:**
```elixir
# Source: repo metadata + Meilisearch settings docs
%{
  primaryKey: to_string(Scrypath.document_id_field(schema)),
  filterableAttributes: Enum.map(schema.__scrypath__(:filterable), &to_string/1),
  sortableAttributes: Enum.map(schema.__scrypath__(:sortable), &to_string/1)
}
|> merge_meilisearch_only_settings(schema)
```

### Anti-Patterns to Avoid
- **Implicit batching:** Do not hide the batch size, preload policy, or query scope inside internal defaults and then market the API as “automatic.” That contradicts the project’s explicit operational stance. [VERIFIED: AGENTS.md] [ASSUMED]
- **In-place live-index rebuilds:** Do not mutate the production index directly when settings or document shape changed. Use a working index and swap. [CITED: https://www.meilisearch.com/docs/resources/internals/indexes]
- **Backend-specific flags on the common sync/search APIs:** Keep raw Meilisearch admin behavior under `Scrypath.Meilisearch.*` instead of tunneling it through generic options. [VERIFIED: ARCHITECTURE.md + lib/scrypath/meilisearch.ex]
- **Settings updates during ordinary writes:** Do not auto-apply expensive settings changes inside `sync_record/3`; make settings application an intentional operator step. [CITED: https://www.meilisearch.com/docs/resources/internals/indexes] [ASSUMED]

## Suggested Plan Split

1. `05-01` Common backfill/reindex contracts and option validation. [ASSUMED]
2. `05-02` Meilisearch admin primitives: create index, update settings, stats, swap, delete, and task/result normalization. [ASSUMED]
3. `05-03` Bulk backfill engine and managed reindex orchestration, including explicit batch semantics and optional Oban durability hooks. [ASSUMED]
4. `05-04` Operator docs, recovery playbooks, and focused tests that lock wording and failure semantics. [ASSUMED]

This split matches the repo’s prior phase pattern of isolating common contract work, backend-specific primitives, execution logic, and docs/tests. [VERIFIED: ROADMAP.md + prior phase summaries]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Zero-downtime cutover | A homegrown alias/cutover abstraction that pretends every backend works the same | Meilisearch working index + swap endpoint [CITED: https://www.meilisearch.com/docs/resources/internals/indexes] | Meilisearch already documents atomic swap semantics, including task-history behavior and rollback-friendly retention of the old index UID. [CITED: https://www.meilisearch.com/docs/resources/internals/indexes] |
| Durable reindex fan-out | Custom queue tables or bespoke retry workers [ASSUMED] | Oban jobs and `insert_all/3` for bulk job insertion [CITED: https://hexdocs.pm/oban/Oban.html#insert_all/3] | Oban already provides durable insertion and lifecycle telemetry, which matches the project’s optional-Oban contract. [VERIFIED: README.md] [CITED: https://hexdocs.pm/oban/Oban.html] |
| Option parsing for operator workflows | Handwritten keyword validation branches | `NimbleOptions` extension in `Scrypath.Options` [VERIFIED: lib/scrypath/options.ex] | The repo already standardizes on `NimbleOptions`, so reusing it keeps errors and docs consistent. [VERIFIED: lib/scrypath/options.ex] |
| Full drift truth engine | A false “search is always in sync” detector [ASSUMED] | Coarse drift signals from task status, index stats, hydration `missing_ids`, failed jobs, and operator docs [CITED: https://www.meilisearch.com/docs/reference/api/async-task-management/list-tasks] [CITED: https://www.meilisearch.com/docs/reference/api/stats/get-stats-of-all-indexes] [VERIFIED: lib/scrypath/search_result.ex + README.md] | The product boundary already says search is eventually consistent; operator tooling should expose symptoms and recovery, not promise impossible certainty. [VERIFIED: AGENTS.md + README.md] |

**Key insight:** The hard part of this phase is not HTTP plumbing; it is making failure boundaries, batching semantics, and rollback behavior explicit enough that operators can trust the workflow. [VERIFIED: project constraints + Meilisearch docs] [ASSUMED]

## Common Pitfalls

### Pitfall 1: Relying on implicit index creation
**What goes wrong:** A rebuild can partially create an index and partially apply settings/documents in a single opaque task. [CITED: https://www.meilisearch.com/docs/resources/internals/indexes]
**Why it happens:** Meilisearch allows implicit creation when adding documents or settings to a missing index. [CITED: https://www.meilisearch.com/docs/resources/internals/indexes]
**How to avoid:** Always create the working index explicitly before settings or document import. [CITED: https://www.meilisearch.com/docs/resources/internals/indexes]
**Warning signs:** Operators cannot tell whether a failed run created the index, applied settings, or imported any documents. [ASSUMED]

### Pitfall 2: Applying settings after import
**What goes wrong:** Filters and sorts may not work until the settings task completes, and rebuild work becomes harder to reason about. [CITED: https://www.meilisearch.com/docs/resources/internals/indexes]
**Why it happens:** Meilisearch requires `filterableAttributes` and `sortableAttributes` to be configured before those query capabilities exist. [CITED: https://www.meilisearch.com/docs/resources/internals/indexes]
**How to avoid:** Apply the full working-index settings payload before the first batch write. [CITED: https://www.meilisearch.com/docs/resources/internals/indexes]
**Warning signs:** Search behavior differs between old and new indexes during validation, or sort/filter errors appear right after cutover. [ASSUMED]

### Pitfall 3: Hidden backfill batching semantics
**What goes wrong:** Operators cannot reason about memory use, lock duration, or partial progress because the library chose chunking rules they never declared. [ASSUMED]
**Why it happens:** Batch size, preload scope, and enumeration strategy were buried in internals instead of surfaced in the API. [ASSUMED]
**How to avoid:** Make `batch_size`, queryable, and preload choices explicit and return per-batch progress metadata. [ASSUMED]
**Warning signs:** Surprising transaction duration, OOM behavior, or “why did this batch size change?” questions during recovery. [ASSUMED]

### Pitfall 4: Treating swap completion as synchronous success
**What goes wrong:** The code reports “reindex complete” before the swap task reaches a terminal state. [CITED: https://www.meilisearch.com/docs/reference/api/async-task-management/list-tasks]
**Why it happens:** Meilisearch admin operations are task-based, just like document writes. [CITED: https://www.meilisearch.com/docs/reference/api/async-task-management/list-tasks]
**How to avoid:** Reuse the existing task normalization/wait/result semantics and document accepted versus completed states for reindex as clearly as Phase 2 and Phase 4 did for sync. [VERIFIED: lib/scrypath/meilisearch/tasks.ex + README.md]
**Warning signs:** A result envelope claims success but later task polling shows `failed` or `canceled`. [CITED: https://www.meilisearch.com/docs/reference/api/async-task-management/list-tasks]

### Pitfall 5: Deleting the old index too early
**What goes wrong:** Operators lose the easiest rollback path after cutover. [CITED: https://www.meilisearch.com/docs/resources/internals/indexes]
**Why it happens:** Cleanup is bundled into the same “success” step as swap. [ASSUMED]
**How to avoid:** Make cleanup explicit and optionally deferred; successful swap should not imply immediate deletion of the previous index. [CITED: https://www.meilisearch.com/docs/resources/internals/indexes]
**Warning signs:** A swap succeeds but post-cutover validation fails and there is no retained fallback UID. [ASSUMED]

## Code Examples

Verified patterns from official sources:

### Streaming a Large Backfill Inside a Transaction
```elixir
# Source: https://hexdocs.pm/ecto/Ecto.Repo.html#c:stream/2
repo.transact(fn ->
  queryable
  |> repo.stream()
  |> Stream.chunk_every(batch_size)
  |> Enum.each(&process_batch/1)
end)
```

### Bulk-Inserting Durable Jobs
```elixir
# Source: https://hexdocs.pm/oban/Oban.html#insert_all/3
changesets = Enum.map(batches, &MyReindexWorker.new/1)
Oban.insert_all(changesets)
```

### Meilisearch Swap-Based Cutover
```bash
# Source: https://www.meilisearch.com/docs/resources/internals/indexes
curl -X POST "$MEILI_URL/swap-indexes" \
  -H "Authorization: Bearer $MEILI_KEY" \
  -H "Content-Type: application/json" \
  --data-binary '[{"indexes":["posts","posts_rebuild_20260416"]}]'
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `Repo.transaction/2` as the recommended Ecto transaction API [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html#c:transaction/2] | `Repo.transact/2` is the current non-deprecated API in Ecto 3.13. [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html#c:transact/2] | Current in Ecto `3.13.5`. [VERIFIED: hex.pm api] | New bulk backfill examples should use `transact/2` so fresh docs do not bake in deprecated guidance. [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html#c:transaction/2] |
| Ad hoc live-index rebuilds [ASSUMED] | Working-index rebuild plus atomic swap. [CITED: https://www.meilisearch.com/docs/resources/internals/indexes] | Current Meilisearch docs. [CITED: https://www.meilisearch.com/docs/resources/internals/indexes] | The planner should center Phase 5 on swap orchestration, not on mutating the live UID in place. [CITED: https://www.meilisearch.com/docs/resources/internals/indexes] |
| Implicit index creation for convenience [CITED: https://www.meilisearch.com/docs/resources/internals/indexes] | Explicit create-index is documented as safer for production. [CITED: https://www.meilisearch.com/docs/resources/internals/indexes] | Current Meilisearch docs. [CITED: https://www.meilisearch.com/docs/resources/internals/indexes] | Phase 5 should implement explicit create/apply/import flows instead of relying on “upsert to missing index.” [CITED: https://www.meilisearch.com/docs/resources/internals/indexes] |

**Deprecated/outdated:**
- `Ecto.Repo.transaction/2` in fresh examples: deprecated in favor of `transact/2`. [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html#c:transaction/2]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The best Phase 5 split is four plans rather than three or five. | Summary / Suggested Plan Split | Low; planning can still re-split without changing the technical core. |
| A2 | A thin common `Scrypath` operator API plus Meilisearch-native admin modules is the right public shape. | Summary / Architecture Patterns | Medium; a different API split could force docs and tests to move. |
| A3 | Settings beyond `filterable`/`sortable` should stay on a Meilisearch-native declaration surface rather than a new backend-agnostic schema DSL. | Architecture Patterns | Medium; if the product later wants portable settings, this phase may need refactoring. |
| A4 | Cleanup should be an explicit post-swap step rather than automatic on success. | Common Pitfalls | Low; automatic cleanup is possible but raises rollback risk. |

## Open Questions

1. **What is the minimum public operator API that still feels complete?**
   - What we know: Existing phases favor small common verbs with explicit result metadata and a Meilisearch-native escape hatch. [VERIFIED: lib/scrypath/sync.ex + lib/scrypath/meilisearch.ex]
   - What's unclear: Whether `Scrypath.backfill/3` and `Scrypath.reindex/3` are enough, or whether settings application should also have a first-class common verb. [ASSUMED]
   - Recommendation: Keep common verbs to backfill and managed reindex; keep raw create/settings/stats/swap/delete on `Scrypath.Meilisearch.*`. [ASSUMED]

2. **Should backfill default to streaming or explicit paging?**
   - What we know: `Repo.stream/2` is a lazy enumerable consumed inside a transaction. [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html#c:stream/2]
   - What's unclear: Whether the library should own a page-based fallback for repos or workloads where long transactions are undesirable. [ASSUMED]
   - Recommendation: Plan for streaming first and leave a page-based strategy as an internal alternative only if tests show long transactions are a problem. [ASSUMED]

3. **How much validation should happen before swap?**
   - What we know: Meilisearch exposes per-index document counts and indexing status via `/stats`, and task statuses via `/tasks`. [CITED: https://www.meilisearch.com/docs/reference/api/stats/get-stats-of-all-indexes] [CITED: https://www.meilisearch.com/docs/reference/api/async-task-management/list-tasks]
   - What's unclear: Whether Phase 5 should block swap on count parity alone, or only expose counts and let operators decide. [ASSUMED]
   - Recommendation: Expose counts and task results in the result envelope, and gate automatic swap only on terminal task success, not on guessed semantic parity. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Phase implementation and tests | ✓ [VERIFIED: `elixir --version`] | `1.19.5` [VERIFIED: `elixir --version`] | — |
| Mix | Test and docs commands | ✓ [VERIFIED: `mix --version`] | OTP `28` toolchain [VERIFIED: `mix --version`] | — |
| Docker | Optional live Meilisearch smoke validation | ✓ [VERIFIED: `docker --version`] | `29.3.1` [VERIFIED: `docker --version`] | — |
| Meilisearch local binary | Live admin-flow manual testing | ✗ [VERIFIED: environment audit] | — | Use Docker or stay on `Req.Test` for non-live tests. [VERIFIED: environment audit + existing tests] |

**Missing dependencies with no fallback:**
- None identified for planning or implementation inside this repo. [VERIFIED: environment audit]

**Missing dependencies with fallback:**
- Local `meilisearch` binary is absent, but Docker is available and the current suite already relies on `Req.Test` for HTTP contract tests. [VERIFIED: environment audit + test grep]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir `1.19.5`. [VERIFIED: `elixir --version` + test/test_helper.exs] |
| Config file | `test/test_helper.exs`; no standalone test config file detected. [VERIFIED: test/test_helper.exs + repo scan] |
| Quick run command | `mix test test/scrypath/backfill_test.exs -x` for focused Phase 5 work. [ASSUMED] |
| Full suite command | `mix test` [VERIFIED: `mix help test`] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| OPER-01 | Explicit bulk backfill batches records from an Ecto queryable and returns batch/progress metadata. [VERIFIED: requirements] | unit + focused integration | `mix test test/scrypath/backfill_test.exs -x` [ASSUMED] | ❌ Wave 0 [VERIFIED: file list] |
| OPER-02 | Managed reindex creates a working index, backfills it, and performs swap orchestration with explicit failure states. [VERIFIED: requirements] | unit + contract | `mix test test/scrypath/reindex_test.exs -x` [ASSUMED] | ❌ Wave 0 [VERIFIED: file list] |
| OPER-03 | Settings payload derivation/application is explicit and runs before import. [VERIFIED: requirements] | unit + HTTP contract | `mix test test/scrypath/meilisearch/indexes_test.exs -x` [ASSUMED] | ❌ Wave 0 [VERIFIED: file list] |
| OPER-05 | Docs and result envelopes explain drift, task states, cutover failure, and recovery. [VERIFIED: requirements] | docs assertion | `mix test test/scrypath/operational_docs_test.exs -x` [ASSUMED] | ❌ Wave 0 [VERIFIED: file list] |

### Sampling Rate
- **Per task commit:** focused Phase 5 file or test command. [ASSUMED]
- **Per wave merge:** `mix test` [VERIFIED: `mix help test`] |
- **Phase gate:** full suite green plus one manual or Docker-backed managed reindex smoke run if live Meilisearch validation is feasible. [ASSUMED]

### Wave 0 Gaps
- [ ] `test/scrypath/backfill_test.exs` — covers OPER-01. [VERIFIED: file list]
- [ ] `test/scrypath/reindex_test.exs` — covers OPER-02. [VERIFIED: file list]
- [ ] `test/scrypath/meilisearch/indexes_test.exs` — covers OPER-03. [VERIFIED: file list]
- [ ] `test/scrypath/operational_docs_test.exs` — covers OPER-05 wording. [VERIFIED: file list]
- [ ] Optional Docker-backed smoke harness for live swap/stat/task validation. [ASSUMED]

## Security Domain

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no [ASSUMED] | Host application owns operator authentication; Scrypath should only document that reindex endpoints are operator-only. [ASSUMED] |
| V3 Session Management | no [ASSUMED] | Not a library-owned concern in this phase. [ASSUMED] |
| V4 Access Control | yes [ASSUMED] | Operator-triggered backfill/reindex flows should only be invoked from trusted admin paths in the host app. [ASSUMED] |
| V5 Input Validation | yes [VERIFIED: workflow config defaults + existing options layer] | Extend `NimbleOptions` validation for batch size, preload, index UID suffixes, cleanup policy, and sync mode. [VERIFIED: lib/scrypath/options.ex] |
| V6 Cryptography | no [ASSUMED] | Reuse Meilisearch API key transport and do not introduce custom crypto. [VERIFIED: lib/scrypath/meilisearch/client.ex] |

### Known Threat Patterns for this Stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Wrong target index or prefix causes destructive writes to the wrong environment. [ASSUMED] | Tampering | Require explicit live UID resolution, deterministic working-index naming, and dry-run/loggable result metadata. [ASSUMED] |
| Oversized backfill batches create resource exhaustion against Repo or Meilisearch. [ASSUMED] | Denial of Service | Validate `batch_size`, document tradeoffs, and expose progress so operators can tune instead of guessing. [ASSUMED] |
| API key leakage through logs or telemetry. [ASSUMED] | Information Disclosure | Keep telemetry metadata low-cardinality and never emit headers or credentials; current request telemetry records method/path/status only. [VERIFIED: lib/scrypath/meilisearch/client.ex + lib/scrypath/telemetry.ex] |
| Public app endpoints trigger reindex workflows without admin protection. [ASSUMED] | Elevation of Privilege | Document operator-only usage and keep destructive verbs out of any automatic callback path. [ASSUMED] |

## Sources

### Primary (HIGH confidence)
- `AGENTS.md`, `README.md`, `ARCHITECTURE.md`, `mix.exs`, `lib/scrypath/*.ex`, `test/scrypath/*.exs` — current project constraints, public boundaries, existing patterns, and test infrastructure. [VERIFIED: codebase reads]
- https://www.meilisearch.com/docs/resources/internals/indexes — explicit vs implicit creation, settings requirements, and atomic swap guidance. [CITED: official docs]
- https://www.meilisearch.com/docs/reference/api/async-task-management/list-tasks — task statuses and task-management semantics. [CITED: official docs]
- https://www.meilisearch.com/docs/reference/api/stats/get-stats-of-all-indexes — stats/document-count/indexing-status fields. [CITED: official docs]
- https://hexdocs.pm/ecto/Ecto.Repo.html#c:stream/2 — bulk streaming semantics. [CITED: official docs]
- https://hexdocs.pm/ecto/Ecto.Repo.html#c:transact/2 — current transaction API. [CITED: official docs]
- https://hexdocs.pm/ecto/Ecto.Repo.html#c:transaction/2 — deprecation status for `transaction/2`. [CITED: official docs]
- https://hexdocs.pm/oban/Oban.html and https://hexdocs.pm/oban/Oban.html#insert_all/3 — durable job insertion and Telemetry notes. [CITED: official docs]
- Hex package API + `mix hex.info` for `ecto`, `nimble_options`, `oban`, `req`, and `telemetry` current versions. [VERIFIED: hex.pm api + mix hex.info]

### Secondary (MEDIUM confidence)
- `prompts/elixir-search-lib-deep-research.md`, `prompts/elixir-best-practices-deep-research.md`, `prompts/ecto-best-practices-deep-research.md`, `prompts/elixir-opensource-libs-best-practices-deep-research.md`, `prompts/search-lib-use-cases-deep-research.md` — prior local research framing that aligns with the repo’s product direction. [VERIFIED: local file reads]

### Tertiary (LOW confidence)
- None. All non-local ecosystem claims used here were verified against official docs or package registries. [VERIFIED: research notes]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all recommended libraries are already in the repo or verified from official package sources. [VERIFIED: mix.exs + hex.pm api]
- Architecture: MEDIUM — the backend capabilities are verified, but the exact public API split for Phase 5 still requires product judgment. [CITED: Meilisearch docs] [ASSUMED]
- Pitfalls: HIGH — they follow directly from explicit project constraints, current code boundaries, and official Meilisearch/Ecto docs. [VERIFIED: codebase + cited docs]

**Research date:** 2026-04-16 [VERIFIED: system date]
**Valid until:** 2026-05-16 for codebase-specific guidance; re-check Meilisearch docs before execution if the phase starts later than that. [ASSUMED]
