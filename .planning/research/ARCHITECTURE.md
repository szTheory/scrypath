# Architecture Research — v1.22 Composition And Real-App Depth

**Domain:** Composition, presets, scopes, UI metadata, and real-app integration for Scrypath search flows  
**Researched:** 2026-05-23  
**Confidence:** HIGH

## Executive Verdict

Scrypath should add **one new feature-level composition seam** above the existing request-edge toolkit and below application contexts:

- `Scrypath.search/3` and `Scrypath.search_many/2` stay the only runtime entrypoints.
- `%Scrypath.Query{}` stays internal.
- **Schema declarations stay index-contract metadata only.**
- **Composition, presets, scopes, and UI metadata belong on context-owned search definition modules** or equivalent context-local modules, not on Ecto schemas and not in Phoenix helpers.

The architecture should be:

```text
Browser params / internal inputs
  -> Scrypath.QueryParams / app data
  -> Scrypath.Composition (preset + scope + metadata assembly)
  -> context function
  -> Scrypath.search/3 or Scrypath.search_many/2
  -> SearchResult / MultiSearchResult
```

This gives apps reusable composition without creating a second query/runtime abstraction.

## Recommended Architecture

### Core rule: composition is args assembly, not query execution

Composition should only do four things:

1. collect feature declarations
2. merge preset and scope fragments
3. produce existing plain-data search args
4. expose UI metadata derived from those declarations

It should **not**:

- execute search
- own Repo access
- replace contexts
- expose a public query struct
- invent a second API separate from `search/3` and `search_many/2`

### Recommended public seam

Add a new core surface centered on a **feature search definition**, not on schemas:

| Module | Responsibility | Public? | Notes |
|--------|----------------|---------|-------|
| `Scrypath.Composition` | Build composed search args and metadata from declared presets/scopes | Yes | Main entrypoint |
| `Scrypath.Composition.Definition` | Behaviour and validation for feature-level declarations | Yes | Prefer behaviour + plain functions over heavy macro magic |
| `Scrypath.Composition.Metadata` | Read normalized UI metadata from a definition | Yes | For Phoenix or JSON clients |
| `Scrypath.Composition.Builder` | Internal merge/order logic | No | Keeps merge semantics isolated |

I would avoid a broad `use Scrypath.SearchModule`-style runtime wrapper here. The current checkout already shows the stable surfaces as `Scrypath.QueryParams`, `Scrypath.search/3`, `Scrypath.search_many/2`, and `Scrypath.Phoenix`. Composition should sit on those directly.

## Boundary Split: Schema vs Feature Definition

### Keep on `use Scrypath` schema metadata

These remain schema-owned because they describe the backend index contract:

- `fields`
- `filterable`
- `sortable`
- `faceting`
- `settings`
- `document_id`
- `document_source`

These are already reflected via `__scrypath__/1` and `Scrypath.schema_*` helpers. That boundary is good and should stay narrow.

### Move to feature-level search definitions

These should **not** live on schemas because they are app- and context-specific:

- named presets like `:published`, `:admin_queue`, `:catalog_default`
- actor- or tenant-aware scopes
- default paging/sort choices
- which declared facets are shown in one UI
- labels/help text/options for filters and sorts
- multi-search entry composition

Reason: one schema can legitimately back several different search experiences. Putting those choices on the schema would blur index contract with product UX.

## Definition Shape

### Recommended declaration model

Use a **behaviour with plain functions**. That keeps the API explicit and easy to evolve.

Recommended callback surface:

```elixir
@callback schema() :: module() | nil
@callback presets() :: %{optional(atom()) => preset()}
@callback scopes() :: %{optional(atom()) => scope_callback()}
@callback metadata() :: metadata()
@callback search_many_entries() :: [entry_definition()] | nil
```

Where the important idea is not the exact types, but the output:

- presets and scopes return **plain data fragments**
- metadata returns **plain UI metadata**
- the final build step returns either:
  - `{text, keyword_opts}` for `Scrypath.search/3`
  - `{entries, shared_opts}` for `Scrypath.search_many/2`

### Fragment model

Presets and scopes should compile down to a small plain-data fragment with two lanes:

- `defaults`
- `fixed`

Meaning:

- `defaults` are user-overridable
- `fixed` always apply

Example shape:

```elixir
%{
  defaults: [
    sort: [inserted_at: :desc],
    page: [size: 20],
    facets: [:status, :author]
  ],
  fixed: [
    filter: [status: "published"]
  ]
}
```

This is the smallest abstraction that solves the real problem. It avoids forcing every app to invent merge rules, while still staying grounded in the existing public option grammar.

## Merge Semantics

### Single-search composition

For `search/3`, the final order should be:

1. base defaults from the definition
2. selected preset defaults
3. selected scope defaults
4. request/app-provided search args
5. preset fixed constraints
6. scope fixed constraints

That ordering keeps user input powerful where it should be, but lets the app enforce non-negotiable boundaries like tenancy, publication status, or product area.

### `search_many/2` alignment

Do not create a separate composition model for multi-search.

Use the same fragment model and map it to the existing `search_many/2` shape:

- shared fragments become `shared_opts`
- per-entry fragments become each entry’s third tuple element
- entry-level precedence should match current `Scrypath.MultiSearch.Entries`
- `:per_query` should keep the existing shallow-merge semantics

Recommended rule:

- composition should build **the same tuple forms `search_many/2` already accepts**
- it may provide helpers to avoid repeated tuple assembly
- it should not introduce a new federated-query object

## Candidate Definition Placement In Real Apps

### Preferred placement

Put reusable definitions next to the owning context:

```text
lib/my_app/content/
  post_search.ex
  catalog_search.ex
  global_search.ex
```

Then contexts call them:

```elixir
def search_posts(actor, params) do
  with {:ok, query_params} <- Scrypath.QueryParams.normalize(params),
       {:ok, plan} <- Scrypath.Composition.build(MyApp.Content.PostSearch, actor: actor, params: query_params) do
    {text, opts} = Scrypath.Composition.to_search_args(plan)
    Scrypath.search(Post, text, Keyword.put(opts, :repo, Repo))
  end
end
```

This preserves the Phoenix/Ecto context boundary Phoenix documents recommend: contexts centralize data access and feature orchestration rather than scattering it across controllers or LiveViews.

### Acceptable secondary placement

If an app already has a search-module wrapper layer, let that module host the declarations. But Scrypath core should not require one for v1.22.

## Metadata Architecture

### What metadata should cover

The new metadata surface should describe the **declared, feature-level UI contract**:

| Metadata area | Belongs where | Why |
|---------------|---------------|-----|
| Filter field labels, operators, option lists | Feature definition | UI and workflow specific |
| Sort choices and default selection | Feature definition | Different pages need different defaults |
| Facet visibility/order/help text | Feature definition | One schema can expose different facet subsets |
| Paging defaults and max size for the feature | Feature definition | UI-level policy |
| Which preset/scope is active | Composition result | Needed for UI state |

### What metadata should not cover

Do not turn metadata into a form-builder or widget layer.

Out of scope for core:

- HTML generation
- HEEx components
- LiveView event wiring
- automatic tenant option loading from the database

Core should only expose normalized metadata that apps can render honestly.

## New vs Modified Components

### Core library code

| Action | Component | Why |
|--------|-----------|-----|
| New | `Scrypath.Composition` | Public composition seam |
| New | `Scrypath.Composition.Definition` | Declarative feature contract |
| New | `Scrypath.Composition.Metadata` | Stable UI metadata reader |
| New | internal merge/validation modules | Keep logic isolated from runtime search |
| Modify | `Scrypath.QueryParams` docs/examples | Show composition as the next step after normalization |
| Modify | `Scrypath` reflection docs | Clarify schema metadata vs feature metadata split |

### Optional Phoenix helpers

| Action | Component | Why |
|--------|-----------|-----|
| Small additive change | `Scrypath.Phoenix` helper for metadata-to-form-state projection | Useful, but keep pure and data-only |
| No change to runtime boundary | `Scrypath.Phoenix` must not call contexts or searches | Preserve current architecture |

### Docs and examples only

| Action | Component | Why |
|--------|-----------|-----|
| New guide | “real-app composition patterns” | Main adoption proof for v1.22 |
| Update example app | one single-search and one multi-search example | Prove reduced app glue |
| New snippets | context-owned `build -> search` flow | This is the canonical story |

### Defer

| Item | Why defer |
|------|-----------|
| Public `%Scrypath.ComposedQuery{}` or similar struct | Would become a second query abstraction |
| Schema-generated `search/2` or `search_many/1` verbs | Weakens context boundary |
| Phoenix components/widgets | Too framework-heavy for core milestone |
| Cross-context registry of all search definitions | Premature; apps can own registry locally |

## Data Flow

### Single-search flow

```text
params
  -> Scrypath.QueryParams.normalize/1
  -> context chooses preset(s)/scope(s)
  -> Scrypath.Composition.build/2
  -> {text, opts}
  -> Scrypath.search/3
```

### Multi-search flow

```text
params + context intent
  -> Scrypath.QueryParams.normalize/1
  -> context chooses shared preset/scope + per-entry preset/scope
  -> Scrypath.Composition.build_many/2
  -> {entries, shared_opts}
  -> Scrypath.search_many/2
```

The important part is that the context still decides:

- which definition to use
- which actor/tenant scope applies
- whether to call single-search or multi-search
- which Repo/runtime opts to add

## Patterns To Follow

### Pattern 1: Context-owned search definitions

**What:** reusable modules near the context that declare presets, scopes, and metadata.  
**When:** whenever more than one controller/LiveView/API path shares the same search behavior.

### Pattern 2: Plain-data output only

**What:** build functions return existing public search arg shapes.  
**When:** always. This is the key guardrail against a second abstraction layer.

### Pattern 3: Metadata split by truth source

**What:** index contract on schemas, UI/search workflow metadata on feature definitions.  
**When:** always. It keeps backend truth separate from product choices.

### Pattern 4: Shared semantics across `search/3` and `search_many/2`

**What:** one composition model, two output adapters.  
**When:** always. Multi-search should feel like “same rules, more entries,” not a second product.

## Anti-Patterns To Avoid

### Anti-pattern 1: Put presets and labels on Ecto schemas

**Why bad:** one schema often serves several search experiences. This creates config collisions and bloats the schema macro surface.

### Anti-pattern 2: Public query struct for composed searches

**Why bad:** it would compete with both `QueryParams` and internal `%Scrypath.Query{}` and become semver baggage fast.

### Anti-pattern 3: Phoenix-owned composition

**Why bad:** it would pull search behavior into controllers/LiveViews and break the current “contexts remain canonical” guidance.

### Anti-pattern 4: Separate multi-search DSL

**Why bad:** `search_many/2` already has stable tuple semantics. Composition should target them, not replace them.

## Suggested Build Order

### Step 1: Core composition contract

- add `Scrypath.Composition`
- add definition behaviour and validation
- implement single-search fragment merge
- return `{text, opts}` only

### Step 2: Metadata exposure

- add normalized metadata reader
- make metadata derive from feature definitions plus schema reflection
- keep output pure data

### Step 3: `search_many/2` composition adapter

- add shared/per-entry builders
- reuse current precedence rules from `Scrypath.MultiSearch.Entries`
- verify `:per_query` behavior matches current runtime

### Step 4: Thin Phoenix additions

- only add projection helpers if needed
- keep them data-only and optional

### Step 5: Real-app proof

- update guides
- add one single-search and one federated example
- show context-owned definitions, not web-layer execution

## Most Important Architectural Call

The key decision is this:

**Scrypath v1.22 should standardize reusable search behavior as feature-level plain-data composition, not as a new runtime layer.**

That is the narrowest seam that meaningfully reduces app glue while keeping:

- contexts as the boundary
- `Scrypath.search/3` canonical
- `search_many/2` canonical
- `%Scrypath.Query{}` internal
- Phoenix optional

## Sources

- Project context and milestone scope:
  - `.planning/PROJECT.md`
  - `.planning/MILESTONE-ARC.md`
  - `.planning/milestone-candidates.md`
  - `.planning/seeds/SEED-002-composition-real-app-depth.md`
- Local research prompts:
  - `prompts/elixir-search-lib-deep-research.md`
  - `prompts/search-lib-use-cases-deep-research.md`
  - `prompts/ecto-best-practices-deep-research.md`
  - `prompts/elixir-opensource-libs-best-practices-deep-research.md`
- Current Scrypath surfaces:
  - `lib/scrypath.ex`
  - `lib/scrypath/search.ex`
  - `lib/scrypath/query.ex`
  - `lib/scrypath/query_params.ex`
  - `lib/scrypath/query_params/caster.ex`
  - `lib/scrypath/phoenix.ex`
  - `lib/scrypath/schema.ex`
  - `lib/scrypath/multi_search/entries.ex`
  - `guides/phoenix-contexts.md`
  - `guides/phoenix-liveview.md`
  - `guides/phoenix-controllers-and-json.md`
  - `guides/multi-index-search.md`
- Official docs:
  - Phoenix contexts: https://hexdocs.pm/phoenix/contexts.html
  - Ecto query composition: https://hexdocs.pm/ecto/Ecto.Query.html
  - Elixir library guidelines: https://hexdocs.pm/elixir/library-guidelines.html
