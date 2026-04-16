# Phase 1: Core Contracts and API Shape - Patterns

**Mapped:** 2026-04-15
**Status:** Ready for planning

## Pattern Mapping Outcome

This repository does not yet contain `lib/` or `test/` implementation code. There are no meaningful runtime analogs for the Phase 1 contracts yet.

That means this artifact does two things:

1. Extracts the likely files Phase 1 will create or modify from `01-CONTEXT.md` and `01-RESEARCH.md`.
2. States explicitly where the codebase has no analog yet, while preserving the concrete API and module-shape examples already locked by the planning artifacts.

## Current Codebase Reality

### Existing implementation analogs
- None. No Elixir source files exist yet.
- None. No test files exist yet.
- None. No README or architecture doc exists yet beyond planning artifacts.

### Closest available analogs
- `.planning/phases/01-core-contracts-and-api-shape/01-CONTEXT.md` - locked decisions about API boundaries, data ownership, and module responsibilities
- `.planning/phases/01-core-contracts-and-api-shape/01-RESEARCH.md` - concrete proposed module layout, example API snippets, and test/doc surface
- `.planning/REQUIREMENTS.md` - requirement IDs that Phase 1 must satisfy
- `.planning/ROADMAP.md` - phase goal and success criteria

## Concrete Excerpts Already Locked

These are the closest things to reusable code patterns in the repo today.

### Schema declaration example

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

Source: `01-RESEARCH.md`

### Reflection helper example

```elixir
MyApp.Post.__scrypath__(:config)
MyApp.Post.__scrypath__(:fields)
MyApp.Post.__scrypath__(:document_source)
```

Source: `01-RESEARCH.md`

### Projection hook example

```elixir
def search_document(post) do
  %{
    id: post.id,
    title: post.title,
    body: post.body
  }
end
```

Source: `01-RESEARCH.md`

### Recommended module shape

```text
- Scrypath
- Scrypath.Schema or equivalent
- Scrypath.Projection
- Scrypath.Config
- Scrypath.Options
- Scrypath.Backend
- Scrypath.Document or equivalent
```

Source: `01-RESEARCH.md`

## Inferred File Map

The files below are inferred from the phase context and research. Where names are still discretionary, that is called out explicitly.

### 1. `mix.exs`

- **Role:** project definition / dependency boundary
- **Data flow:** external configuration into library compile/runtime dependencies
- **Why Phase 1 likely touches it:** research explicitly raises whether `NimbleOptions` should be added now; the initial library surface will need project metadata and dependency declaration
- **Closest analog in codebase:** none
- **Pattern note:** keep dependencies narrow; only add `:nimble_options` if the planner locks centralized option validation in this phase

### 2. `lib/scrypath.ex`

- **Role:** public facade
- **Data flow:** caller input -> normalized config / schema reflection / projection helpers -> internal modules
- **Why inferred:** `01-CONTEXT.md` locks one obvious top-level `Scrypath` facade for common verbs
- **Closest analog in codebase:** none
- **Concrete guidance excerpt:**

```text
Scrypath should expose one obvious top-level Scrypath facade for common verbs,
with deeper modules underneath for more specialized concerns.
```

### 3. `lib/scrypath/schema.ex`

- **Role:** macro and metadata declaration
- **Data flow:** schema module declaration -> validated options -> stored metadata -> `__scrypath__/1` reflection
- **Why inferred:** both context and research lock a small `use Scrypath` declaration surface and inspectable helpers
- **Closest analog in codebase:** none
- **Concrete guidance excerpt:**

```text
The macro should validate declarative options, register schema metadata, and
generate inspectable helpers such as __scrypath__/1.
```

### 4. `lib/scrypath/projection.ex`

- **Role:** document projection contract
- **Data flow:** schema metadata + record input -> default field projection or `search_document/1` override -> search document map
- **Why inferred:** projection behavior is a first-class phase deliverable
- **Closest analog in codebase:** none
- **Concrete guidance excerpt:**

```text
Scrypath v1 should use a hybrid projection model: declarative fields: [...] for
the default path plus an explicit override hook such as search_document/1 for
custom document shaping.
```

### 5. `lib/scrypath/config.ex`

- **Role:** runtime configuration lookup and normalization entrypoint
- **Data flow:** explicit options and optional app defaults -> normalized runtime config
- **Why inferred:** context locks explicit runtime options as canonical; research recommends a central config layer
- **Closest analog in codebase:** none
- **Pattern note:** avoid hidden global behavior; config should support later inline / Oban / manual sync modes without requiring supervision

### 6. `lib/scrypath/options.ex`

- **Role:** options schema and validation
- **Data flow:** raw keyword options -> validated / normalized options -> downstream modules
- **Why inferred:** context locks centralized validation; research names this module directly
- **Closest analog in codebase:** none
- **Pattern note:** this is the likely home for `NimbleOptions` if adopted now

### 7. `lib/scrypath/backend.ex`

- **Role:** internal behavior seam
- **Data flow:** normalized config and projected documents -> backend callbacks for future upsert/delete/search operations
- **Why inferred:** `BACK-02` requires an internal future-backend seam without public multi-backend abstraction
- **Closest analog in codebase:** none
- **Concrete guidance excerpt:**

```text
The internal adapter seam should stay narrow and behavior-driven so future
backend support remains possible without forcing premature public parity.
```

### 8. `lib/scrypath/document.ex` or equivalent

- **Role:** internal document shape / helper struct
- **Data flow:** projection output -> stable internal representation for backend-facing logic
- **Why inferred:** research suggests this only if a stable internal shape is useful
- **Closest analog in codebase:** none
- **Pattern note:** discretionary; planner should only add it if it reduces ambiguity instead of creating abstraction overhead

### 9. `test/scrypath/schema_test.exs`

- **Role:** contract test for macro declaration and reflection
- **Data flow under test:** declared schema options -> reflection output / validation errors
- **Why inferred:** research requires macro tests for accepted and rejected schema options and reflection tests for `__scrypath__/1`
- **Closest analog in codebase:** none

### 10. `test/scrypath/projection_test.exs`

- **Role:** contract test for projection behavior
- **Data flow under test:** record input -> default field projection or override hook -> document map
- **Why inferred:** research explicitly requires projection tests for default fields, hook precedence, and explicit association handling
- **Closest analog in codebase:** none

### 11. `test/scrypath/backend_test.exs` or `test/support/fake_backend.ex`

- **Role:** seam verification for the internal backend behavior
- **Data flow under test:** normalized inputs -> behavior callbacks / contract conformance
- **Why inferred:** research calls for backend behavior contract tests or fake-backend tests
- **Closest analog in codebase:** none
- **Pattern note:** the fake backend may live under `test/support/` if that yields clearer contract tests

### 12. `README.md`

- **Role:** product boundary and adoption guide
- **Data flow:** user understanding of library contract and scope
- **Why inferred:** research makes README updates a minimum planning target
- **Closest analog in codebase:** none
- **Concrete guidance excerpt:**

```text
Phase 1 docs should explain:
- what Scrypath is and is not
- why v1 is Meilisearch-first
- why the adapter seam is internal
- how schema declaration works
- how projection works
```

### 13. `ARCHITECTURE.md` or equivalent top-level architecture doc

- **Role:** internal/public boundary documentation
- **Data flow:** maintainer understanding of where responsibilities live
- **Why inferred:** research explicitly calls for an architecture document describing public surface vs internal seams
- **Closest analog in codebase:** `.planning/ARCHITECTURE.md` does not exist; only planning references mention architecture
- **Pattern note:** likely created at repo root unless the planner decides on a `docs/` layout

### 14. Module docs within `lib/scrypath*.ex`

- **Role:** API-level documentation
- **Data flow:** user-facing guidance attached directly to public modules
- **Why inferred:** research calls for module docs on schema declaration and projection contract
- **Closest analog in codebase:** none

## File Classification by Role and Data Flow

| File | Role | Primary data flow |
|------|------|-------------------|
| `mix.exs` | project boundary | dependency and app metadata -> build/runtime |
| `lib/scrypath.ex` | public facade | caller -> runtime helpers -> internal modules |
| `lib/scrypath/schema.ex` | declaration/meta | macro options -> metadata -> reflection |
| `lib/scrypath/projection.ex` | transformation | schema metadata + record -> document map |
| `lib/scrypath/config.ex` | normalization | explicit options + app defaults -> runtime config |
| `lib/scrypath/options.ex` | validation | raw options -> validated options |
| `lib/scrypath/backend.ex` | internal boundary | normalized operations -> backend callbacks |
| `lib/scrypath/document.ex` | internal representation | projection output -> stable document shape |
| `test/scrypath/schema_test.exs` | contract verification | declaration -> reflection/errors |
| `test/scrypath/projection_test.exs` | contract verification | record -> projected doc |
| `test/scrypath/backend_test.exs` | seam verification | behavior contract -> fake/backend assertions |
| `README.md` | product docs | library concepts -> user understanding |
| `ARCHITECTURE.md` | maintainer docs | design decisions -> implementation guidance |

## Pattern Decisions The Planner Should Preserve

### Prefer explicit function boundaries over generated runtime APIs
- Keep runtime verbs under `Scrypath.*`
- Do not generate `Post.search/2`, `Post.reindex/1`, or similar schema-centric runtime helpers

### Keep the macro reflective, not orchestration-heavy
- `use Scrypath` should declare and expose metadata
- It should not own sync orchestration, supervision, or hidden callbacks

### Keep projection honest about data loading
- Same-row fields work by default
- Association or denormalized projection requires explicit preloads or custom query logic

### Keep the backend seam internal and boring
- Behavior-driven, narrow, and future-safe
- No public backend registration or fake portability promise in v1

## Missing Analogs and Planning Implication

Because the repository has no existing Elixir implementation yet, the planner should treat the examples in `01-RESEARCH.md` as the authoritative starting pattern rather than looking for code reuse that does not exist.

The phase plan should therefore:

- lock file names deliberately instead of assuming repo precedent
- keep the first implementation surface small
- add tests and docs in the same phase so the contracts are frozen immediately

## Canonical Inputs Used

- `.planning/phases/01-core-contracts-and-api-shape/01-CONTEXT.md`
- `.planning/phases/01-core-contracts-and-api-shape/01-RESEARCH.md`
- repository file inventory at planning time

## PATTERNS COMPLETE
