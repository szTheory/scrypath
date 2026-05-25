# Phase 89: Related Data Fan-Out API - Research

**Researched:** 2026-05-24
**Domain:** Elixir/Ecto Search Synchronization
**Confidence:** HIGH

## Summary

Phase 89 introduces a first-class, explicit API for fanning out search index updates when related Ecto data changes, fulfilling requirements DATA-01 and DATA-02. This resolves the "temporary workaround" currently documented in `guides/related-data-and-reindexing.md` (which relies on custom Oban workers) by pushing the execution capability into the core Scrypath runtime. The design explicitly avoids hidden Ecto callback magic; contexts must explicitly invoke `Scrypath.sync_related/3`. The intent and resolver strategies are declared statically on the schema as metadata (`fan_outs`), ensuring the system remains observable and declarative.

**Primary recommendation:** Introduce `Scrypath.sync_related/3`, backed by a schema-declared `fan_outs` metadata option, to explicitly execute related-data updates inline or durably via the existing Oban sync mode.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Explicit Fan-Out Orchestration | API / Backend (Context) | — | The context is responsible for recognizing when a mutation affects related documents and explicitly calling `Scrypath.sync_related/3`. Scrypath does not rely on Ecto `after_update` callbacks or hidden database triggers. |
| Fan-Out Execution | API / Backend (Library) | Database / Oban | The `Scrypath.Sync` runtime handles executing the declared resolver, mapping to target documents, and issuing backend upserts or Oban jobs based on the `sync_mode`. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `Ecto` | (Current) | Data mapping & resolution | Core domain structures for related data lookups |
| `Oban` | (Current) | Durable queueing | Standard for async search document synchronization |

## Architecture Patterns

### Recommended Design for Fan-Out Metadata
The core addition is a capability struct or declarative option to `Scrypath.Schema`.

**Pattern: Static Fan-Out Declaration**
**What:** Define fan-out targets and resolution strategies statically in the schema using MFA (Module, Function, Arguments).
**When to use:** When a child schema's search index incorporates parent data (or vice versa), and updates to the source need to propagate.

**Example Implementation:**
```elixir
defmodule MyApp.Blog.Author do
  use Ecto.Schema
  
  # The source schema declares the fan-out capability.
  use Scrypath,
    fields: [:id, :name],
    fan_outs: [
      author_posts: [
        target: MyApp.Blog.Post,
        # Resolver function should accept the source records and return target records
        resolver: {MyApp.Blog, :list_posts_by_author, []} 
      ]
    ]
end
```

### Pattern: Explicit Orchestration in Context
**What:** The app context explicitly invokes the library entrypoint to fan out.
**When to use:** Whenever mutating the source entity.

**Example Implementation:**
```elixir
def update_author(%Author{} = author, attrs) do
  Repo.transaction(fn ->
    author
    |> Author.changeset(attrs)
    |> Repo.update!()
    |> tap(fn updated_author ->
      # No hidden magic. Explicit intent.
      Scrypath.sync_related(Author, updated_author, fan_out: :author_posts, sync_mode: :oban)
    end)
  end)
end
```

### Anti-Patterns to Avoid
- **Hidden Ecto Callbacks:** Do not implement `Scrypath.sync_related` as an `Ecto.Schema` lifecycle hook (`after_update`, `after_insert`). Scrypath explicitly rejects silent association walking.
- **Parsing Ecto Changesets:** Do not attempt to dynamically infer if an indexed field changed across associations. Contexts must drive the intent.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Fan-out async execution | Custom `Oban.Worker` for each relationship | `Scrypath.sync_related/3` with `sync_mode: :oban` | Standardizes telemetry, error reporting, and durable sync routing. Replaces the temporary workaround in the guides. |
| Deep Ecto preload resolution | Automatic association traversal | Explicit MFA resolvers in `fan_outs:` | Opaque traversals cause hidden N+1 queries and race conditions; explicit resolvers keep boundaries honest. |

## Common Pitfalls

### Pitfall 1: Assuming `sync_related/3` magically resolves data
**What goes wrong:** A developer calls `Scrypath.sync_related(Target, record)` expecting it to automatically fetch `Target` without defining a resolver.
**Why it happens:** Confusion with traditional ORM magic.
**How to avoid:** Validate that `fan_outs` is statically declared and enforces an MFA resolver. If missing, fail synchronously with `ArgumentError`.

### Pitfall 2: Silent failures during resolution
**What goes wrong:** The resolver MFA fails midway or returns an invalid data structure, causing the fan-out sync to fail silently.
**Why it happens:** Lack of standard library telemetry wrapper around the resolution step.
**How to avoid:** Wrap the resolution step in `[:scrypath, :sync, :related, :resolve]` telemetry span. Requirement EXEC-01 mandates clear error returns without silent partial failures.

## Code Examples

### Modifying `Scrypath.Options`
```elixir
# lib/scrypath/options.ex
@schema_options [
  # ... existing options ...
  fan_outs: [
    type: {:custom, __MODULE__, :validate_fan_outs, []},
    default: [],
    doc: "Explicit related-data fan-out capabilities defining target schemas and resolvers."
  ]
]
```

### `Scrypath.sync_related/3` Signature
```elixir
# lib/scrypath.ex
@doc """
Fans out updates to related search documents based on statically declared `fan_outs`.
"""
@spec sync_related(module(), struct() | [struct()], keyword()) :: {:ok, term()} | {:error, term()}
def sync_related(schema_module, records, opts \\ []) do
  Scrypath.Sync.sync_related(schema_module, records, opts)
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Custom Oban Workers | `Scrypath.sync_related/3` | Phase 89 | Reduces boilerplate; library handles telemetry, error tracking, and routing to the target's configured backend directly. |

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DATA-01 | Library exposes a public, explicit API (e.g., `sync_related/3`) | Investigated API signature and `Scrypath.Options` schema struct modifications. |
| DATA-02 | Enforces "no hidden magic" invariant | Architecture ensures explicit Context orchestration and MFA-based resolving rather than Ecto lifecycle callbacks. |

## Environment Availability
Step 2.6: SKIPPED (no external dependencies identified beyond standard Ecto/Oban/Meilisearch).

## Open Questions (RESOLVED)

1. **Inline vs Oban Resolver Execution**
   - What we know: `sync_mode: :oban` delegates the sync job durably.
   - What's unclear: Does the resolver MFA run immediately inline before enqueueing the Oban job, or does the Oban job execute the resolver?
   - **RESOLVED:** The Oban job should execute the resolver to prevent inline API latency when resolving a large number of related records, though `args` must be carefully serialized. Ensure tests (`89-03`) cover both modes.
