# Phase 2: Meilisearch Core Sync - Research

**Researched:** 2026-04-15
**Domain:** Meilisearch-backed indexing sync for an Ecto-first Elixir OSS library [VERIFIED: .planning/ROADMAP.md]
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Phase 2 public sync APIs should live under `Scrypath.*`, not on schema modules.
- **D-02:** Insert and update should collapse into one upsert-oriented sync path because Meilisearch itself treats document writes as upserts.
- **D-03:** Delete should be a separate public path with explicit identity semantics instead of being inferred from a generic polymorphic `sync` call.
- **D-04:** The documented primary API should use explicit lifecycle verbs rather than a single action-dispatcher API with option-heavy branching.
- **D-05:** `:inline` and `:manual` should share the same public verb semantics; only execution strategy and completion guarantees differ.
- **D-06:** Sync invocation should be explicit in contexts and write orchestration code, not injected automatically by `use Scrypath` or hidden callback magic.
- **D-07:** Manual workflows should support intentional single-record and batch sync without introducing a separate conceptual API family.
- **D-08:** Delete operations are keyed by canonical document identity, not by full document projection.
- **D-09:** Scrypath must capture delete identity from the source struct before the row becomes unavailable.
- **D-10:** `document_id` metadata remains the default identity source.
- **D-11:** If custom identity is needed, Scrypath should support a dedicated identity hook such as `search_document_id/1`.
- **D-12:** `search_document/1` must not be the authoritative source for delete identity in v1.
- **D-13:** Manual delete APIs should accept explicit document IDs for cases where no source struct is available.
- **D-14:** Future async delete payloads should carry schema, document id, and resolved index context, not instructions to reload a deleted row.
- **D-15:** Custom document ids must be stable, deterministic, and derivable from pre-delete data alone.
- **D-16:** `sync_mode: :inline` means Scrypath waits for Meilisearch task completion before returning success.
- **D-17:** Scrypath must not treat Meilisearch task acceptance or `202 Accepted` as inline success.
- **D-18:** The public write-path contract should use stable Elixir tuples: `{:ok, sync_result}` or `{:error, reason}`.
- **D-19:** `sync_result` should expose backend task metadata so Meilisearch’s asynchronous execution remains visible instead of being hidden behind fake synchrony.
- **D-20:** Manual sync is the explicit enqueue/operator path and may return task references without waiting.
- **D-21:** Inline timeout before terminal task completion is an error outcome, not a silent partial success.
- **D-22:** Phase 2 docs must state clearly that inline improves immediacy but does not make database and search writes atomic.
- **D-23:** Scrypath should encourage calling inline sync after successful repo persistence, not from inside uncommitted transaction steps.
- **D-24:** Backend failure details should preserve enough structure to distinguish transport failure, backend task failure, timeout, and cancellation.
- **D-25:** `Scrypath.*` remains the canonical runtime surface for common sync verbs in Phase 2.
- **D-26:** Phase 2 should expose a small public `Scrypath.Meilisearch.*` namespace for backend-native operations instead of hiding them behind generic options.
- **D-27:** The common path should cover only the stable cross-backend core: document identity, index resolution, upsert, delete, sync mode selection, and explicit runtime config.
- **D-28:** Meilisearch-only concepts such as raw responses, task handling, and index or settings operations should live under `Scrypath.Meilisearch.*`.
- **D-29:** Backend-specific power should be opt-in and explicit, never silently tunneled through the common API.
- **D-30:** `use Scrypath` should stay metadata-first; avoid adding Meilisearch-heavy schema DSL in Phase 2 unless the backend coupling is obvious and immediately valuable.
- **D-31:** Phase 2 docs should distinguish the common happy path from the Meilisearch-specific escape hatch.

### Claude's Discretion
- Exact function names and module grouping beneath the `Scrypath.*` and `Scrypath.Meilisearch.*` surfaces, as long as the public semantics above remain intact.
- Exact polling, timeout, and result-struct layout for inline task waiting, as long as inline success still means terminal backend success.
- Exact validation rules for a dedicated custom identity hook, as long as identity stays single-source and stable.

### Deferred Ideas (OUT OF SCOPE)
- Automatic callback-style sync wiring on repo or schema writes — deferred because it conflicts with the explicit Ecto-first design and would be a separate product decision.
- Broader Meilisearch settings, raw client access, and richer operator workflows beyond the minimum escape hatch — deferred to later phases where settings and reindex orchestration are first-class scope.
- Shared-index and multi-schema identity ergonomics beyond the stable-id contract needed now — defer broader strategy until reindex and operational workflows are in scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| BACK-01 | Developer can use Scrypath with Meilisearch as the supported public backend in v1. [VERIFIED: .planning/REQUIREMENTS.md] | Implement a real `Scrypath.Backend` adapter backed by `Req` + Meilisearch HTTP endpoints and expose a narrow `Scrypath.Meilisearch.*` escape hatch. [VERIFIED: lib/scrypath/backend.ex] [CITED: https://hexdocs.pm/req/Req.html] [CITED: https://www.meilisearch.com/docs/assets/open-api/meilisearch-openapi-mintlify.json] |
| SYNC-01 | Developer can synchronize searchable records on insert. [VERIFIED: .planning/REQUIREMENTS.md] | Use a single upsert path that projects `Scrypath.Document`, resolves the index, and sends document-add/update requests to Meilisearch. [VERIFIED: lib/scrypath/projection.ex] [CITED: https://www.meilisearch.com/docs/assets/open-api/meilisearch-openapi-mintlify.json] |
| SYNC-02 | Developer can synchronize searchable records on update. [VERIFIED: .planning/REQUIREMENTS.md] | Reuse the same upsert verb as insert because Meilisearch document writes return `documentAdditionOrUpdate` tasks for both add/replace and add/update endpoints. [CITED: https://www.meilisearch.com/docs/assets/open-api/meilisearch-openapi-mintlify.json] |
| SYNC-03 | Developer can remove searchable records from the index on delete without requiring the source record to still exist. [VERIFIED: .planning/REQUIREMENTS.md] | Resolve delete identity from `document_id` or `search_document_id/1` before the row disappears, then call Meilisearch delete-by-id or delete-batch APIs with explicit IDs. [VERIFIED: lib/scrypath.ex] [CITED: https://www.meilisearch.com/docs/assets/open-api/meilisearch-openapi-mintlify.json] |
| SYNC-04 | Developer can choose inline synchronization for simple or local workflows. [VERIFIED: .planning/REQUIREMENTS.md] | Inline mode must poll `/tasks/{task_id}` until terminal success or terminal failure and treat timeout as `{:error, reason}`. [CITED: https://www.meilisearch.com/docs/assets/open-api/meilisearch-openapi-mintlify.json] |
| SYNC-06 | Developer can choose manual synchronization for imports, migrations, or operator-controlled flows. [VERIFIED: .planning/REQUIREMENTS.md] | Manual mode should enqueue the same upsert/delete operations but return task metadata immediately without waiting. [CITED: https://www.meilisearch.com/docs/assets/open-api/meilisearch-openapi-mintlify.json] |
</phase_requirements>

## Summary

Phase 2 should extend the existing Phase 1 contracts, not reshape them. The current codebase already has the right foundation: `Scrypath.Projection.document/2` produces a concrete backend document, `Scrypath.Config.resolve!/1` centralizes runtime options, and `Scrypath.Backend` is the narrow internal seam the adapter can satisfy. [VERIFIED: lib/scrypath/projection.ex] [VERIFIED: lib/scrypath/config.ex] [VERIFIED: lib/scrypath/backend.ex]

The central implementation fact is Meilisearch’s task model. Document writes and deletes enqueue asynchronous tasks and return summarized task metadata, while full task state is retrieved separately from `/tasks/{task_id}` with statuses `enqueued`, `processing`, `succeeded`, `failed`, or `canceled`. [CITED: https://www.meilisearch.com/docs/assets/open-api/meilisearch-openapi-mintlify.json] That means Scrypath inline mode cannot truthfully return success on `202 Accepted`; it has to poll task state until terminal success, while manual mode should return the task reference honestly and stop there. [CITED: https://www.meilisearch.com/docs/assets/open-api/meilisearch-openapi-mintlify.json]

The best stack for this phase is a thin Meilisearch client built on `Req` plus `Jason`, not the community `:meilisearch` Hex package. `Req` is current and already ships a strong testing story through `Req.Test`, while the Hex `:meilisearch` package’s latest release is `0.20.0` from 2021-09-03, which is materially stale against the current Meilisearch OpenAPI published in the docs. [VERIFIED: hex.pm api req] [VERIFIED: hex.pm api meilisearch] [CITED: https://hexdocs.pm/req/Req.html] [CITED: https://hexdocs.pm/req/Req.Test.html] [CITED: https://www.meilisearch.com/docs/assets/open-api/meilisearch-openapi-mintlify.json]

**Primary recommendation:** Use `Req`-backed Meilisearch HTTP modules plus a small Scrypath sync orchestration layer that shares one public verb model across `:inline` and `:manual`, with delete identity resolved before deletion and inline success defined strictly as terminal task success. [VERIFIED: lib/scrypath/options.ex] [CITED: https://hexdocs.pm/req/Req.html] [CITED: https://www.meilisearch.com/docs/assets/open-api/meilisearch-openapi-mintlify.json]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Public sync verbs (`Scrypath.*`) | API / Backend | — | Sync orchestration is library runtime behavior, not schema macro behavior, and Phase 2 locks it under `Scrypath.*`. [VERIFIED: .planning/phases/02-meilisearch-core-sync/02-CONTEXT.md] |
| Document projection | API / Backend | Database / Storage | Projection consumes already-loaded structs and must not perform hidden reads; callers own preload and persistence timing. [VERIFIED: lib/scrypath/projection.ex] [VERIFIED: README.md] |
| Delete identity resolution | API / Backend | Database / Storage | Delete IDs must be captured from pre-delete data before the source row becomes unavailable. [VERIFIED: .planning/phases/02-meilisearch-core-sync/02-CONTEXT.md] |
| Meilisearch HTTP transport | API / Backend | CDN / Static | HTTP request building, authentication headers, response decoding, and error normalization belong in backend-facing client modules. [CITED: https://hexdocs.pm/req/Req.html] |
| Inline task waiting | API / Backend | — | Meilisearch exposes task state through `/tasks/{task_id}`, so polling and timeout handling are runtime orchestration concerns. [CITED: https://www.meilisearch.com/docs/assets/open-api/meilisearch-openapi-mintlify.json] |
| Manual operator path | API / Backend | — | Manual mode should reuse the same verb layer but stop after enqueue, returning task metadata for the caller to manage. [VERIFIED: .planning/phases/02-meilisearch-core-sync/02-CONTEXT.md] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `ecto` | `3.13.5` (published 2025-11-09) [VERIFIED: hex.pm api ecto] | Existing schema/projection integration surface. [VERIFIED: mix.exs] | Scrypath is explicitly Ecto-first and already depends on Ecto `~> 3.13`. [VERIFIED: .planning/PROJECT.md] [VERIFIED: mix.exs] |
| `nimble_options` | `1.1.1` (published 2024-05-25) [VERIFIED: hex.pm api nimble_options] | Existing runtime/schema option validation. [VERIFIED: lib/scrypath/options.ex] | The project already uses it and HexDocs documents both validation and docs generation helpers. [VERIFIED: lib/scrypath/options.ex] [CITED: https://hexdocs.pm/nimble_options/NimbleOptions.html] |
| `req` | `0.5.17` (published 2026-01-05) [VERIFIED: hex.pm api req] | HTTP transport for Meilisearch requests, shared request config, and testing hooks. [CITED: https://hexdocs.pm/req/Req.html] | It is current, batteries-included, and aligned with modern Elixir HTTP-client conventions. [VERIFIED: hex.pm api req] [CITED: https://hexdocs.pm/req/Req.html] |
| `jason` | `1.4.4` (published 2024-07-26) [VERIFIED: hex.pm api jason] | JSON encoding/decoding for document payloads and Meilisearch responses. [VERIFIED: hex.pm api jason] | It is the standard lightweight JSON dependency in Elixir projects. [VERIFIED: hex.pm api jason] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Req.Test` | bundled with `req 0.5.17` [VERIFIED: hex.pm api req] | Stub HTTP responses, JSON bodies, and transport errors in concurrent tests. [CITED: https://hexdocs.pm/req/Req.Test.html] | Default choice for adapter/client tests that do not need a live Meilisearch process. [CITED: https://hexdocs.pm/req/Req.Test.html] |
| `mox` | `1.2.0` (published 2024-08-14) [VERIFIED: hex.pm api mox] | Behavior mocks and expectation verification for internal client/task-waiting boundaries. [CITED: https://hexdocs.pm/mox/Mox.html] | Use when a module boundary should be mocked by behavior rather than by HTTP. [CITED: https://hexdocs.pm/mox/Mox.html] |
| `stream_data` | `1.3.0` (published 2026-03-09) [VERIFIED: hex.pm api stream_data] | Property-based tests for stable identity and option normalization invariants. [CITED: https://hexdocs.pm/stream_data/StreamData.html] | Use for deterministic identity rules and result-shape invariants, not for every happy-path test. [CITED: https://hexdocs.pm/stream_data/StreamData.html] |
| `bypass` | `2.1.0` (published 2020-11-13) [VERIFIED: hex.pm api bypass] | Local HTTP server fallback when request-plug stubs are insufficient. [VERIFIED: hex.pm api bypass] | Only use if a test truly needs socket-level behavior rather than Req’s built-in plug testing. [CITED: https://hexdocs.pm/req/Req.Test.html] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `Req` | community `:meilisearch` Hex package `0.20.0` [VERIFIED: hex.pm api meilisearch] | The package appears stale relative to the current Meilisearch OpenAPI, so it adds API-risk right where Phase 2 needs fidelity. [VERIFIED: hex.pm api meilisearch] [CITED: https://www.meilisearch.com/docs/assets/open-api/meilisearch-openapi-mintlify.json] |
| `Req.Test` | `Bypass` | `Bypass` is useful for real socket behavior, but `Req.Test` is simpler and already designed for concurrent request stubs and transport errors. [CITED: https://hexdocs.pm/req/Req.Test.html] |
| `Repo.transaction/2` | `Repo.transact/2` | Ecto marks `transaction/2` as deprecated in favor of `transact/2`, so new docs and examples should use `transact/2` when Phase 2 discusses post-persist call sites. [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html] |

**Installation:** add these deps in `mix.exs`, then run `mix deps.get`. [VERIFIED: mix.exs]
```elixir
defp deps do
  [
    {:ecto, "~> 3.13"},
    {:nimble_options, "~> 1.1"},
    {:req, "~> 0.5.17"},
    {:jason, "~> 1.4"},
    {:mox, "~> 1.2", only: :test},
    {:stream_data, "~> 1.3", only: :test}
  ]
end
```

**Version verification:** [VERIFIED: hex.pm api ecto] [VERIFIED: hex.pm api nimble_options] [VERIFIED: hex.pm api req] [VERIFIED: hex.pm api jason] [VERIFIED: hex.pm api mox] [VERIFIED: hex.pm api stream_data]

## Architecture Patterns

### System Architecture Diagram

Recommended Phase 2 flow. [VERIFIED: lib/scrypath/projection.ex] [VERIFIED: lib/scrypath/config.ex] [CITED: https://www.meilisearch.com/docs/assets/open-api/meilisearch-openapi-mintlify.json]

```text
App context / write orchestration
        |
        v
Scrypath.upsert_* / Scrypath.delete_*
        |
        +--> Scrypath.Config.resolve!/1
        |
        +--> Projection / identity resolution
        |      |
        |      +--> Scrypath.Projection.document/2
        |      +--> search_document_id/1 or document_id metadata
        |
        +--> Backend selection (Scrypath.Backend behavior)
               |
               v
        Scrypath.Meilisearch.Adapter
               |
               +--> Req request builder / auth / JSON
               |
               +--> POST|PUT /indexes/{index_uid}/documents
               +--> DELETE /indexes/{index_uid}/documents/{document_id}
               +--> POST /indexes/{index_uid}/documents/delete-batch
               |
               v
        Summarized task response
               |
        +------|--------------------------+
        |                                 |
        v                                 v
 manual mode                       inline mode
 return task metadata              poll GET /tasks/{task_id}
 immediately                       until succeeded|failed|canceled|timeout
```

### Recommended Project Structure
```text
lib/
├── scrypath.ex                     # public common sync verbs and reflection helpers
├── scrypath/config.ex              # runtime option resolution
├── scrypath/options.ex             # runtime/schema validation
├── scrypath/projection.ex          # document projection
├── scrypath/document.ex            # backend-facing document struct
├── scrypath/sync_result.ex         # stable public result structs
├── scrypath/identity.ex            # delete-id resolution rules
└── scrypath/meilisearch/
    ├── adapter.ex                  # Scrypath.Backend implementation
    ├── client.ex                   # Req request construction and response normalization
    ├── tasks.ex                    # task polling / timeout / terminal-state mapping
    └── api.ex                      # narrow public escape hatch under Scrypath.Meilisearch.*
```

### Pattern 1: Split transport from orchestration
**What:** Keep `Req` request building and response normalization in `Scrypath.Meilisearch.Client`, while `Scrypath` or a small sync module owns projection, identity, mode selection, and tuple-return contracts. [VERIFIED: lib/scrypath/backend.ex] [CITED: https://hexdocs.pm/req/Req.html]
**When to use:** Always for Phase 2 common sync paths and the backend-native namespace. [VERIFIED: .planning/phases/02-meilisearch-core-sync/02-CONTEXT.md]
**Example:**
```elixir
# Source: https://hexdocs.pm/req/Req.html
req = Req.new(base_url: endpoint, headers: %{"authorization" => "Bearer " <> api_key})
{:ok, response} = Req.post(req, url: "/indexes/#{index_uid}/documents", json: documents)
```

### Pattern 2: One public upsert verb, two execution strategies
**What:** Expose one upsert-oriented common path for insert and update, then branch only on `sync_mode` after the Meilisearch task is enqueued. [VERIFIED: .planning/phases/02-meilisearch-core-sync/02-CONTEXT.md] [CITED: https://www.meilisearch.com/docs/assets/open-api/meilisearch-openapi-mintlify.json]
**When to use:** Any record or batch write that should appear in the index. [VERIFIED: .planning/REQUIREMENTS.md]
**Example:**
```elixir
# Source: project phase constraints + Meilisearch task API
case config[:sync_mode] do
  :manual -> {:ok, summarized_task}
  :inline -> Scrypath.Meilisearch.Tasks.await_task(client, summarized_task.task_uid, timeout: timeout)
end
```

### Pattern 3: Resolve delete identity before deletion
**What:** Use `document_id` metadata by default and allow a dedicated `search_document_id/1` hook for stable custom IDs; do not derive delete identity from `search_document/1`. [VERIFIED: .planning/phases/02-meilisearch-core-sync/02-CONTEXT.md] [VERIFIED: lib/scrypath.ex]
**When to use:** Every delete path, including manual batch delete. [VERIFIED: .planning/REQUIREMENTS.md]
**Example:**
```elixir
# Source: project phase constraints
document_id =
  if function_exported?(schema, :search_document_id, 1) do
    schema.search_document_id(struct)
  else
    Map.fetch!(struct, Scrypath.document_id_field(schema))
  end
```

### Anti-Patterns to Avoid
- **Treating `202 Accepted` as inline success:** Meilisearch only guarantees task enqueue at that point. [CITED: https://www.meilisearch.com/docs/assets/open-api/meilisearch-openapi-mintlify.json]
- **Adding callback magic to `use Scrypath`:** Phase 2 explicitly keeps sync invocation in app contexts and orchestration code. [VERIFIED: .planning/phases/02-meilisearch-core-sync/02-CONTEXT.md]
- **Using `search_document/1` to discover delete IDs:** The phase context forbids it as the authoritative delete identity source. [VERIFIED: .planning/phases/02-meilisearch-core-sync/02-CONTEXT.md]
- **Leaking Meilisearch-only options through the common API:** Backend-native power belongs under `Scrypath.Meilisearch.*`. [VERIFIED: .planning/phases/02-meilisearch-core-sync/02-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| HTTP transport | a custom Finch/Tesla wrapper stack for Phase 2 | `Req` | Req already provides request structs, verbs, base URL handling, and testing support. [CITED: https://hexdocs.pm/req/Req.html] [CITED: https://hexdocs.pm/req/Req.Test.html] |
| HTTP stubbing | ad hoc fake HTTP modules | `Req.Test` | Req.Test already supports JSON helpers, transport errors, and concurrent stub ownership. [CITED: https://hexdocs.pm/req/Req.Test.html] |
| behavior mocks | hand-written fake behaviors per test | `Mox` | Mox is built for concurrent mocks, `defmock`, `verify_on_exit!`, and process allowances. [CITED: https://hexdocs.pm/mox/Mox.html] |
| option validation | manual keyword-list parsing | `NimbleOptions` | The project already uses it and its docs cover both validation and docs generation. [VERIFIED: lib/scrypath/options.ex] [CITED: https://hexdocs.pm/nimble_options/NimbleOptions.html] |
| task status model | informal atoms/maps invented from memory | Meilisearch task schemas (`SummarizedTaskView`, `TaskView`) | The OpenAPI already defines summarized enqueue responses and full task states, including `failed` and `canceled`. [CITED: https://www.meilisearch.com/docs/assets/open-api/meilisearch-openapi-mintlify.json] |

**Key insight:** Phase 2 is an orchestration problem, not an SDK-construction problem. The highest-risk mistakes are semantic lies about task completion and delete identity, not low-level HTTP mechanics. [VERIFIED: .planning/phases/02-meilisearch-core-sync/02-CONTEXT.md] [CITED: https://www.meilisearch.com/docs/assets/open-api/meilisearch-openapi-mintlify.json]

## Common Pitfalls

### Pitfall 1: Choosing the wrong Meilisearch write endpoint
**What goes wrong:** `POST /documents` replaces whole existing documents, while `PUT /documents` partially updates them. [CITED: https://www.meilisearch.com/docs/assets/open-api/meilisearch-openapi-mintlify.json]
**Why it happens:** Both endpoints return the same task kind, so it is easy to flatten them conceptually without deciding whether Scrypath’s Phase 2 semantics are replace or partial-update. [CITED: https://www.meilisearch.com/docs/assets/open-api/meilisearch-openapi-mintlify.json]
**How to avoid:** Pick one explicit Phase 2 write semantic and document it in both README and tests. The safer v1 default is partial update via `PUT` for updates plus full projection for inserts only if the plan intentionally distinguishes them; otherwise a single full-document replace path is simpler but must be documented clearly. [VERIFIED: lib/scrypath/projection.ex] [CITED: https://www.meilisearch.com/docs/assets/open-api/meilisearch-openapi-mintlify.json]
**Warning signs:** Planner language says “upsert” without specifying whether absent fields are removed or preserved. [CITED: https://www.meilisearch.com/docs/assets/open-api/meilisearch-openapi-mintlify.json]

### Pitfall 2: Calling inline sync inside uncommitted DB work
**What goes wrong:** The search write can succeed while the database write later rolls back, or the search call can see state that the DB never commits. [VERIFIED: .planning/phases/02-meilisearch-core-sync/02-CONTEXT.md]
**Why it happens:** Inline mode feels synchronous, but Meilisearch still runs asynchronously and independently of database transactions. [CITED: https://www.meilisearch.com/docs/assets/open-api/meilisearch-openapi-mintlify.json]
**How to avoid:** Plan docs and examples around “persist first, then sync,” and when describing transaction boundaries use `Repo.transact/2` terminology from current Ecto docs. [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html]
**Warning signs:** Examples show sync calls inside `Ecto.Multi` steps before commit or inside `Repo.transact/2` before the transaction exits. [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html]

### Pitfall 3: Losing custom delete identity
**What goes wrong:** Deletes fail or delete the wrong record when custom IDs are derived from projection data rather than a dedicated stable identity rule. [VERIFIED: .planning/phases/02-meilisearch-core-sync/02-CONTEXT.md]
**Why it happens:** `search_document/1` can compute rich payloads, but delete only needs a stable ID derivable from the pre-delete struct. [VERIFIED: lib/scrypath/projection.ex] [VERIFIED: .planning/phases/02-meilisearch-core-sync/02-CONTEXT.md]
**How to avoid:** Introduce a single-purpose identity resolver and test it against both the default `document_id` field and the custom hook. [VERIFIED: lib/scrypath.ex]
**Warning signs:** Planner wants to “recompute the document then read `id` from it” for deletes. [VERIFIED: .planning/phases/02-meilisearch-core-sync/02-CONTEXT.md]

### Pitfall 4: Overcommitting the backend seam in Phase 2
**What goes wrong:** Meilisearch-specific concepts leak into the common API or `Scrypath.Backend` grows callbacks that only exist to satisfy imagined future engines. [VERIFIED: lib/scrypath/backend.ex] [VERIFIED: .planning/phases/02-meilisearch-core-sync/02-CONTEXT.md]
**Why it happens:** The first real adapter often tempts libraries into designing a fake universal abstraction too early. [VERIFIED: .planning/research/PITFALLS.md]
**How to avoid:** Keep `Scrypath.Backend` limited to the callbacks already present and place task-native operations in `Scrypath.Meilisearch.*`. [VERIFIED: lib/scrypath/backend.ex] [VERIFIED: .planning/phases/02-meilisearch-core-sync/02-CONTEXT.md]
**Warning signs:** New common callbacks for settings, raw client access, or cancellation appear in the Phase 2 plan. [VERIFIED: .planning/phases/02-meilisearch-core-sync/02-CONTEXT.md]

## Code Examples

Verified patterns from official sources and current project contracts.

### Req request struct with base URL
```elixir
# Source: https://hexdocs.pm/req/Req.html
req = Req.new(base_url: "http://localhost:7700")
{:ok, response} = Req.get(req, url: "/health")
```

### Req.Test stub for concurrent HTTP tests
```elixir
# Source: https://hexdocs.pm/req/Req.Test.html
Req.Test.stub(MyApp.Meili, fn conn ->
  Req.Test.json(conn, %{"taskUid" => 1, "status" => "enqueued", "type" => "documentAdditionOrUpdate"})
end)

req = Req.new(base_url: "https://meili", plug: {Req.Test, MyApp.Meili})
{:ok, response} = Req.post(req, url: "/indexes/posts/documents", json: [%{id: 1}])
```

### Current Ecto transaction terminology
```elixir
# Source: https://hexdocs.pm/ecto/Ecto.Repo.html
repo.transact(fn ->
  repo.insert!(changeset)
end)
```

### Mox concurrent behavior mock setup
```elixir
# Source: https://hexdocs.pm/mox/Mox.html
setup :verify_on_exit!
Mox.defmock(MyApp.MockClient, for: MyApp.ClientBehaviour)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `Repo.transaction/2` in new examples | `Repo.transact/2` | Current Ecto 3.13 docs mark `transaction/2` as deprecated in favor of `transact/2`. [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html] | Phase 2 docs should use `transact/2` language when explaining persistence timing. [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html] |
| Community-specific Meilisearch client packages | Thin client built on current HTTP API | Current Meilisearch docs publish a live OpenAPI and the visible Hex package is stale. [VERIFIED: hex.pm api meilisearch] [CITED: https://www.meilisearch.com/docs/assets/open-api/meilisearch-openapi-mintlify.json] | Scrypath should own a small, explicit client layer instead of inheriting unknown client drift. [VERIFIED: hex.pm api meilisearch] |
| Ad hoc HTTP test servers as default | `Req.Test` for most client tests | Current Req docs include a dedicated testing module with JSON and transport-error helpers. [CITED: https://hexdocs.pm/req/Req.Test.html] | Phase 2 can get strong adapter coverage without booting a live Meilisearch server for every test. [CITED: https://hexdocs.pm/req/Req.Test.html] |

**Deprecated/outdated:**
- `Repo.transaction/2` for new examples is outdated because Ecto 3.13 labels it deprecated. [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html]
- The Hex `:meilisearch` package is not a safe default for a greenfield adapter in 2026 because its latest release is from 2021-09-03. [VERIFIED: hex.pm api meilisearch]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| None | All substantive claims in this research were verified against codebase files, Hex package metadata, or official docs in this session. [VERIFIED: codebase grep] | All sections | Low |

## Open Questions

1. **Should the common upsert path use Meilisearch replace semantics or partial-update semantics by default?**
   - What we know: `POST /documents` replaces whole documents and removes missing fields, while `PUT /documents` keeps absent fields unchanged. [CITED: https://www.meilisearch.com/docs/assets/open-api/meilisearch-openapi-mintlify.json]
   - What's unclear: The phase context locks “upsert-oriented” behavior but does not lock whether Phase 2 update semantics should be replace or partial update. [VERIFIED: .planning/phases/02-meilisearch-core-sync/02-CONTEXT.md]
   - Recommendation: Decide this explicitly during planning and make tests/documentation use that exact semantic language. [CITED: https://www.meilisearch.com/docs/assets/open-api/meilisearch-openapi-mintlify.json]

2. **What timeout and polling interval should inline mode use by default?**
   - What we know: Inline success must mean terminal task success, and Meilisearch exposes full task state via `/tasks/{task_id}`. [VERIFIED: .planning/phases/02-meilisearch-core-sync/02-CONTEXT.md] [CITED: https://www.meilisearch.com/docs/assets/open-api/meilisearch-openapi-mintlify.json]
   - What's unclear: The exact timeout/interval defaults are left to Claude’s discretion. [VERIFIED: .planning/phases/02-meilisearch-core-sync/02-CONTEXT.md]
   - Recommendation: Pick conservative explicit defaults in `Scrypath.Options`, expose overrides, and test timeout classification separately from backend failure classification. [VERIFIED: lib/scrypath/options.ex]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | build and tests | ✓ [VERIFIED: local command check] | `1.19.5` [VERIFIED: local command check] | — |
| Mix | build and tests | ✓ [VERIFIED: local command check] | `1.19.5` [VERIFIED: local command check] | — |
| Docker | optional live Meilisearch integration test path | ✓ [VERIFIED: local command check] | `29.3.1` [VERIFIED: local command check] | — |
| Meilisearch CLI/binary | optional live integration test path | ✗ [VERIFIED: local command check] | — | Use Docker-based Meilisearch or pure `Req.Test` coverage. [VERIFIED: local command check] |
| `curl` | docs/debug scripts | ✓ [VERIFIED: local command check] | `8.7.1` [VERIFIED: local command check] | — |

**Missing dependencies with no fallback:**
- None. [VERIFIED: local command check]

**Missing dependencies with fallback:**
- Local Meilisearch binary is absent, but Docker is installed and most adapter tests can use `Req.Test` without any external service. [VERIFIED: local command check] [CITED: https://hexdocs.pm/req/Req.Test.html]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `ExUnit` with support files loaded from `test/support/**/*.ex`. [VERIFIED: test/test_helper.exs] |
| Config file | none. [VERIFIED: codebase grep] |
| Quick run command | `mix test test/scrypath/backend_test.exs test/scrypath/meilisearch/*_test.exs` [VERIFIED: test/scrypath/backend_test.exs] |
| Full suite command | `mix test` [VERIFIED: Mix availability] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| BACK-01 | backend adapter satisfies `Scrypath.Backend` and talks to Meilisearch endpoints correctly. [VERIFIED: .planning/REQUIREMENTS.md] | unit/integration | `mix test test/scrypath/meilisearch/adapter_test.exs` | ❌ Wave 0 |
| SYNC-01 | insert path projects and enqueues document write. [VERIFIED: .planning/REQUIREMENTS.md] | unit | `mix test test/scrypath/sync_test.exs --only insert` | ❌ Wave 0 |
| SYNC-02 | update path reuses common upsert semantics. [VERIFIED: .planning/REQUIREMENTS.md] | unit | `mix test test/scrypath/sync_test.exs --only update` | ❌ Wave 0 |
| SYNC-03 | delete path resolves canonical ID without reloading missing rows. [VERIFIED: .planning/REQUIREMENTS.md] | unit/property | `mix test test/scrypath/identity_test.exs` | ❌ Wave 0 |
| SYNC-04 | inline mode waits for terminal task success and classifies timeout/failure correctly. [VERIFIED: .planning/REQUIREMENTS.md] | unit | `mix test test/scrypath/meilisearch/tasks_test.exs` | ❌ Wave 0 |
| SYNC-06 | manual mode returns task metadata immediately for single and batch operations. [VERIFIED: .planning/REQUIREMENTS.md] | unit | `mix test test/scrypath/sync_test.exs --only manual` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test test/scrypath/backend_test.exs test/scrypath/meilisearch/*_test.exs`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/scrypath/sync_test.exs` — common public verb behavior and sync-mode branching. [VERIFIED: codebase grep]
- [ ] `test/scrypath/identity_test.exs` — default and custom delete-id rules, including property tests. [VERIFIED: codebase grep]
- [ ] `test/scrypath/meilisearch/adapter_test.exs` — endpoint, payload, and error normalization checks. [VERIFIED: codebase grep]
- [ ] `test/scrypath/meilisearch/tasks_test.exs` — polling, timeout, failed, and canceled task paths. [VERIFIED: codebase grep]
- [ ] Add test deps for `req`, `mox`, and `stream_data` before implementation. [VERIFIED: mix.exs] [VERIFIED: hex.pm api req] [VERIFIED: hex.pm api mox] [VERIFIED: hex.pm api stream_data]

## Security Domain

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no [VERIFIED: phase scope] | Meilisearch API keys are passed through to the backend client; Scrypath is not an auth system. [CITED: https://www.meilisearch.com/docs/assets/open-api/meilisearch-openapi-mintlify.json] |
| V3 Session Management | no [VERIFIED: phase scope] | — |
| V4 Access Control | no [VERIFIED: phase scope] | Authorization scope is enforced by Meilisearch API key permissions, not by Scrypath application logic. [CITED: https://www.meilisearch.com/docs/assets/open-api/meilisearch-openapi-mintlify.json] |
| V5 Input Validation | yes [VERIFIED: phase tech stack] | `NimbleOptions` for runtime options and explicit identity/document normalization before transport. [VERIFIED: lib/scrypath/options.ex] [CITED: https://hexdocs.pm/nimble_options/NimbleOptions.html] |
| V6 Cryptography | no [VERIFIED: phase scope] | Rely on HTTPS/TLS and Meilisearch API keys; do not add custom crypto logic. [CITED: https://www.meilisearch.com/docs/assets/open-api/meilisearch-openapi-mintlify.json] |

### Known Threat Patterns for Elixir + Meilisearch sync
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Accidental credential leakage in logs | Information Disclosure | Keep API keys in runtime config only and avoid logging authorization headers or full request structs. [VERIFIED: .planning/PROJECT.md] [CITED: https://hexdocs.pm/req/Req.html] |
| Sending malformed or unstable document IDs | Tampering | Centralize identity resolution and validate custom hooks before transport. [VERIFIED: .planning/phases/02-meilisearch-core-sync/02-CONTEXT.md] |
| Accepting enqueue as success | Integrity | Poll task state for inline mode and classify terminal failure explicitly. [CITED: https://www.meilisearch.com/docs/assets/open-api/meilisearch-openapi-mintlify.json] |
| Hanging client calls | Denial of Service | Use explicit request timeouts and bounded polling loops in the task waiter. [CITED: https://hexdocs.pm/req/Req.html] |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/02-meilisearch-core-sync/02-CONTEXT.md` - locked public semantics, delete identity rules, inline/manual constraints. [VERIFIED: .planning/phases/02-meilisearch-core-sync/02-CONTEXT.md]
- `lib/scrypath/backend.ex` - current internal backend seam. [VERIFIED: lib/scrypath/backend.ex]
- `lib/scrypath/config.ex` - current runtime config resolution. [VERIFIED: lib/scrypath/config.ex]
- `lib/scrypath/projection.ex` - current document projection contract. [VERIFIED: lib/scrypath/projection.ex]
- `https://www.meilisearch.com/docs/assets/open-api/meilisearch-openapi-mintlify.json` - current document and task endpoints, task schemas, and status model. [CITED: https://www.meilisearch.com/docs/assets/open-api/meilisearch-openapi-mintlify.json]
- `https://hexdocs.pm/req/Req.html` - current Req request API. [CITED: https://hexdocs.pm/req/Req.html]
- `https://hexdocs.pm/req/Req.Test.html` - current Req testing API. [CITED: https://hexdocs.pm/req/Req.Test.html]
- `https://hexdocs.pm/ecto/Ecto.Repo.html` - current `Repo.transact/2` guidance and `transaction/2` deprecation. [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html]
- `https://hexdocs.pm/nimble_options/NimbleOptions.html` - option validation and docs generation. [CITED: https://hexdocs.pm/nimble_options/NimbleOptions.html]
- `https://hexdocs.pm/mox/Mox.html` - concurrent behavior-mock patterns. [CITED: https://hexdocs.pm/mox/Mox.html]

### Secondary (MEDIUM confidence)
- `https://hex.pm/api/packages/req` - latest `req` version and publish date. [VERIFIED: hex.pm api req]
- `https://hex.pm/api/packages/jason` - latest stable `jason` version and publish date. [VERIFIED: hex.pm api jason]
- `https://hex.pm/api/packages/mox` - latest `mox` version and publish date. [VERIFIED: hex.pm api mox]
- `https://hex.pm/api/packages/stream_data` - latest `stream_data` version and publish date. [VERIFIED: hex.pm api stream_data]
- `https://hex.pm/api/packages/nimble_options` - latest `nimble_options` version and publish date. [VERIFIED: hex.pm api nimble_options]
- `https://hex.pm/api/packages/ecto` - latest `ecto` version and publish date. [VERIFIED: hex.pm api ecto]

### Tertiary (LOW confidence)
- None. [VERIFIED: source review]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - package versions were verified against Hex metadata and transport/testing recommendations are backed by current official docs. [VERIFIED: hex.pm api req] [VERIFIED: hex.pm api meilisearch] [CITED: https://hexdocs.pm/req/Req.html]
- Architecture: HIGH - the recommendation is tightly constrained by the existing codebase and the phase context’s locked decisions. [VERIFIED: lib/scrypath/backend.ex] [VERIFIED: .planning/phases/02-meilisearch-core-sync/02-CONTEXT.md]
- Pitfalls: HIGH - the main pitfalls follow directly from Meilisearch endpoint semantics and the project’s explicit delete/inline rules. [CITED: https://www.meilisearch.com/docs/assets/open-api/meilisearch-openapi-mintlify.json] [VERIFIED: .planning/phases/02-meilisearch-core-sync/02-CONTEXT.md]

**Research date:** 2026-04-15
**Valid until:** 2026-05-15 for codebase guidance and 2026-04-22 for Hex/doc version checks. [VERIFIED: hex.pm api req]
