# Phase 1: Core Contracts and API Shape - Research

**Researched:** 2026-04-15
**Status:** Ready for planning

## Research Question

What do I need to know to PLAN this phase well?

## Executive Summary

Phase 1 is where Scrypath decides what kind of library it is. The planning target is not "build search," but "lock the product shape so later indexing, query, Oban, and reindex work can land without rewriting the public API."

The strongest direction, based on the phase context and project research, is:

- keep one small schema macro: `use Scrypath`
- keep runtime behavior in explicit `Scrypath.*` functions, not generated schema APIs
- support a hybrid projection contract: declarative `fields: [...]` plus explicit override hook
- create a narrow internal adapter behavior for backend operations without promising public backend agnosticism
- prefer explicit runtime options and centralized validation over hidden application config
- document operational truths early: projection changes can require reindexing, association data must be explicit, and delete semantics must work without reloading deleted rows

If planning stays disciplined around those constraints, Phase 1 can produce stable foundations without leaking too much Phase 2+ implementation.

## What Phase 1 Must Actually Deliver

Per the roadmap and requirements, this phase must cover:

- `SCMA-01`: small, explicit searchable schema declaration
- `SCMA-02`: documented and testable projection contract
- `SCMA-03`: runtime inspection of declared search metadata
- `BACK-02`: internal future-backend seam without premature public abstraction

That means the plan should produce four concrete outputs:

1. A schema declaration API and metadata model.
2. A projection contract with tests and docs.
3. An internal backend behavior and config normalization layer.
4. Core docs explaining the boundary, tradeoffs, and what is intentionally deferred.

## Planning Constraints That Should Stay Locked

### 1. The macro must stay small

The local context is already clear: `use Scrypath` should declare metadata, validate options, and expose inspectable helpers such as `__scrypath__/1`. It should not inject hidden callbacks, generated runtime orchestration, or model-centric APIs like `Post.search/2`.

Planning implication:

- keep macro work limited to declaration, metadata registration, and reflection helpers
- keep runtime verbs under `Scrypath` modules
- avoid building DSL features that imply sync/query support before those phases exist

### 2. The public API should be Ecto-first and function-heavy

The strongest fit for Elixir OSS is explicit functions and narrow behaviors, with macros used only when declaration materially improves ergonomics. That aligns with the project stack guidance and Elixir OSS research.

Planning implication:

- define top-level modules deliberately now
- avoid generated per-schema runtime helpers
- design return shapes and error contracts conservatively so later phases can extend them without breaking callers

### 3. Projection must support both defaults and escape hatches

The phase context already locks a hybrid projection model:

- `fields: [...]` for the simple path
- explicit override hook such as `search_document/1` for custom shaping

This is the right planning target because field lists alone will not cover denormalized documents, but a hook-only design would make first-mile adoption heavier.

Planning implication:

- define precedence rules now
- specify how reflection exposes the chosen projection mode
- document that association-based projection requires explicit preloads or dedicated queries

### 4. The adapter seam should be real but internal

The project guidance is explicit: preserve a path to future backend support, but do not sell a public multi-backend facade in v1. Haystack-style over-abstraction is the trap to avoid.

Planning implication:

- introduce an internal behavior for backend operations
- keep adapter-facing contracts narrow and boring
- do not expose backend-neutral public extension points yet
- reserve backend-specific power for later explicit namespaces like `Scrypath.Meilisearch.*`

### 5. Runtime config must be explicit

The Elixir OSS research strongly favors runtime options over hidden global application config. For this library, that matters because sync, search, and reindex flows will eventually need per-call or per-context control.

Planning implication:

- add central option normalization and validation in Phase 1
- treat application config only as optional defaults, not the primary contract
- keep Oban and any future process-backed integrations optional

## Recommended Public Shape To Plan Around

These are the design targets Phase 1 planning should assume unless discuss work later changes them.

### Schema declaration

```elixir
defmodule MyApp.Post do
  use Ecto.Schema
  use Scrypath,
    fields: [:title, :body],
    filterable: [:status],
    sortable: [:inserted_at]

  schema "posts" do
    field :title, :string
    field :body, :string
    field :status, Ecto.Enum, values: [:draft, :published]
    timestamps()
  end
end
```

Planning notes:

- the option set can stay narrower in Phase 1 if needed
- metadata should be introspectable even if later phases expand the DSL
- declaration should be explicit enough that future docs read cleanly in Phoenix/Ecto examples

### Reflection helper

Plan around a small reflective API, for example:

```elixir
MyApp.Post.__scrypath__(:config)
MyApp.Post.__scrypath__(:fields)
MyApp.Post.__scrypath__(:document_source)
```

The exact keys can change, but the planner should lock:

- a stable helper name
- what information is returned
- whether return values are keyword lists, maps, or structs

### Projection hook

Plan around an optional override on the schema module, for example:

```elixir
def search_document(post) do
  %{
    id: post.id,
    title: post.title,
    body: post.body
  }
end
```

The plan must define:

- hook name
- input contract
- precedence over `fields: [...]`
- expectations around preloads and nil handling

### Runtime entrypoints

Even if implementation stays minimal in Phase 1, planning should reserve a top-level runtime surface like:

- `Scrypath.schema_config/1`
- `Scrypath.document/2` or equivalent projection helper
- `Scrypath.backend/1` or internal config lookup helpers

This keeps later sync/query phases from inventing scattered entrypoints.

## Internal Architecture Recommendations

Phase 1 should likely define a small set of foundational modules before later behavior lands. The exact names may vary, but the responsibilities should stay close to this shape:

- `Scrypath` - public facade for common runtime helpers
- `Scrypath.Schema` or equivalent - macro and reflection implementation
- `Scrypath.Projection` - default field projection plus custom-hook dispatch
- `Scrypath.Config` - runtime config normalization and lookup
- `Scrypath.Options` - option schema and validation
- `Scrypath.Backend` - internal behavior contract
- `Scrypath.Document` or equivalent struct module if document metadata needs a stable internal shape

Planning guidance:

- keep module count low
- separate declaration concerns from runtime concerns
- avoid introducing processes or supervision in this phase unless a module absolutely requires them

## Key Decisions The Plan Must Make Explicit

The planner should not leave these ambiguous:

1. What exact options does `use Scrypath` accept in Phase 1?
2. What does `__scrypath__/1` return for each supported key?
3. Is projected document identity derived automatically from schema primary key, configurable, or both?
4. What is the canonical projection helper used internally?
5. What behavior callbacks exist on the internal backend seam?
6. Where is options validation defined, and does it use `NimbleOptions`?
7. Which docs are required in this phase: README updates, architecture doc, API docs, or all three?

If these remain fuzzy, Phase 2 will likely reopen the contracts.

## Recommended Backend Behavior Scope

The internal backend behavior should stay intentionally narrow in Phase 1. It only needs the contract surface required to avoid API damage later.

Good planning target:

- backend identification / capability metadata
- index naming helpers or config resolution hooks
- document upsert callback contract
- document delete callback contract
- search callback placeholder if needed by later phases
- settings / reindex placeholders only if they help lock later API shape

Avoid in Phase 1:

- a rich generic adapter framework
- public adapter registration APIs
- solving feature parity across future engines
- over-modeling backend capabilities before Meilisearch implementation exists

## Documentation Outcomes Required

The roadmap explicitly requires docs, so the plan should treat docs as first-class deliverables, not cleanup.

Phase 1 docs should explain:

- what Scrypath is and is not
- why v1 is Meilisearch-first
- why the adapter seam is internal
- how schema declaration works
- how projection works
- what later phases will add
- why eventual consistency and reindex workflows are part of the product story

Minimum planning target:

- core `README.md` product boundary section
- architecture document describing public surface vs internal seams
- module docs for schema declaration and projection contract

## Testing Surface The Plan Should Include

Phase 1 is contract-heavy, so the tests should be contract-heavy too.

At minimum, planning should include:

- macro tests for accepted and rejected schema options
- reflection tests for `__scrypath__/1`
- projection tests for default field projection
- projection tests for custom hook precedence
- tests proving association projection is explicit, not magical
- backend behavior contract tests or fake-backend tests for the internal seam
- doc examples or doctests where they clarify the public API

Nice-to-have if it fits cleanly:

- property tests for projection invariants
- tests around stable document id derivation

## Risks And Failure Modes To Plan Around

### 1. Overbuilding the adapter layer

This is the biggest architectural risk. If the planner turns BACK-02 into a generic multi-engine platform, the phase will sprawl and dilute the product.

Countermeasure:

- phrase tasks around an internal behavior seam, not public adapter support

### 2. Making the macro too magical

If the macro starts owning runtime behavior, later operational flows will be harder to reason about and harder to document honestly.

Countermeasure:

- keep schema modules declarative
- keep orchestration in ordinary modules

### 3. Under-specifying projection behavior

Projection looks small, but it decides later sync correctness, reindex triggers, and query hydration assumptions.

Countermeasure:

- make precedence, identity, and preload expectations explicit in code and docs

### 4. Hiding operational truth in docs language

The product promise explicitly rejects hiding operational realities. If Phase 1 docs imply magical sync or backend portability, later phases will inherit misleading copy.

Countermeasure:

- write docs that acknowledge eventual consistency, explicit reindexing, and backend-specific escape hatches from the start

## What Phase 1 Should Not Try To Finish

The plan should explicitly keep these out of scope:

- actual Meilisearch indexing implementation
- insert/update/delete sync orchestration
- Oban jobs or supervision trees
- search query execution
- hydration back into Ecto records
- full reindex orchestration
- Phoenix integration specifics beyond keeping the API Phoenix-friendly

Those belong to later phases. Phase 1 only needs enough structure so those additions fit naturally.

## Recommended Task Breakdown For Planning

A strong plan will probably break into 4-6 tasks around these units:

1. Define schema declaration contract and reflection helpers.
2. Define projection contract and projection runtime helpers.
3. Define config/options normalization and internal backend behavior.
4. Add focused tests for schema metadata, projection, and backend seam.
5. Write README and architecture docs for product boundary and tradeoffs.

That sequencing works well because it locks the public declaration surface first, then the runtime interpretation, then the internal seam, then documentation.

## Open Questions Worth Settling During Planning

These do not block research completeness, but they are good discuss/planning checkpoints:

- Should the metadata helper return raw options, normalized structs, or both?
- Should document id be configurable in Phase 1 or fixed to the schema primary key for now?
- Should `fields` be limited to same-row fields initially, with richer projection only through the override hook?
- Should filterable/sortable metadata be accepted in Phase 1 even though query execution lands in Phase 3?
- Should `NimbleOptions` be added now or deferred if the option surface stays tiny?

## Planner Guidance

When creating `PLAN.md`, optimize for:

- stable contracts over feature count
- explicit boundaries over clever abstractions
- docs and tests that freeze the intended product shape
- leaving Phase 2 with obvious extension points instead of cleanup work

The best Phase 1 outcome is a codebase where later phases mostly add behavior, not redesign foundations.

## Canonical References Consulted

- `.planning/phases/01-core-contracts-and-api-shape/01-CONTEXT.md`
- `.planning/REQUIREMENTS.md`
- `.planning/STATE.md`
- `.planning/ROADMAP.md`
- `prompts/search-lib-use-cases-deep-research.md`
- `prompts/elixir-opensource-libs-best-practices-deep-research.md`
- `prompts/elixir-best-practices-deep-research.md`
- `prompts/ecto-best-practices-deep-research.md`

## Research Outcome

This phase is ready to plan. The main planning job is to lock a small schema DSL, a projection contract with a clear override path, an inspectable metadata model, and an internal backend behavior that preserves future options without exposing false portability.

## RESEARCH COMPLETE
