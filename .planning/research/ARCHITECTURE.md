# Architecture Research — v1.25 Tenant-Safe Search (AUTH-01)

**Domain:** Multi-tenant search integration — schema declaration, metadata reflection, and optional search-path enforcement for Scrypath  
**Researched:** 2026-05-25  
**Confidence:** HIGH — all integration points verified against live codebase

---

## System Overview

The AUTH-01 changes touch three distinct layers of the existing architecture. No new runtime layer is added. The change is additive at each layer:

```
┌───────────────────────────────────────────────────────────────────┐
│  Host App (context layer — unchanged boundary)                    │
│                                                                   │
│   MyApp.Blog.search_posts(text, %Tenant{id: id}, opts)            │
│     -> Scrypath.search(Post, text, [filter: [tenant_id: id], ...])│
└──────────────────────────────┬────────────────────────────────────┘
                               │
┌──────────────────────────────▼────────────────────────────────────┐
│  Scrypath Public API  (lib/scrypath.ex)  — UNCHANGED              │
│                                                                   │
│   search/3   search_many/2   schema_capabilities/1               │
│                                                                   │
│   (stretch) tenant_scope: option injects privileged filter        │
└──────────────────────────────┬────────────────────────────────────┘
                               │
┌──────────────────────────────▼────────────────────────────────────┐
│  Options Layer  (lib/scrypath/options.ex)                         │
│                                                                   │
│   @schema_options — ADD tenant_field: atom | nil                  │
│   validate_schema_options!/1 — auto-merge tenant_field            │
│     into :filterable list                                         │
│   (stretch) @search_options — ADD tenant_scope: term | nil        │
│   validate_search_options/2 — inject tenant filter into :filter   │
└───────────┬───────────────────────────────────────┬───────────────┘
            │                                       │
┌───────────▼───────────┐             ┌─────────────▼───────────────┐
│  Schema Layer          │             │  Search Path                │
│  (lib/scrypath/        │             │  (lib/scrypath/search.ex    │
│   schema.ex)           │             │   lib/scrypath/query.ex)    │
│                        │             │                             │
│  __using__ macro       │             │  (stretch) tenant_scope     │
│  stores config map     │             │  merged into filter before  │
│  with :tenant_field    │             │  Query.new/2 is called      │
│  key added             │             │                             │
└───────────┬───────────┘             └─────────────────────────────┘
            │
┌───────────▼───────────┐
│  Metadata Layer        │
│  (lib/scrypath/        │
│   metadata/            │
│   capabilities.ex)     │
│                        │
│  schema_capabilities/1 │
│  ADD :tenant_field key │
│  when declared         │
└───────────────────────┘
```

---

## Component Responsibilities

| Component | Current Responsibility | AUTH-01 Change |
|-----------|----------------------|----------------|
| `Scrypath.Options` | Validates all schema and runtime options via NimbleOptions; schema_options drives `validate_schema_options!/1` | ADD `tenant_field:` to `@schema_options`; auto-merge into `:filterable` in `validate_schema_options!/1`; (stretch) ADD `tenant_scope:` to `@search_options` |
| `Scrypath.Schema` | `__using__` macro that calls `Options.validate_schema_options!/1` and stores the config map in `@scrypath_config`; exposes `__scrypath__/1` accessor | ADD `:tenant_field` key dispatch to `__scrypath__/1` |
| `Scrypath.Metadata.Capabilities` | Builds the `schema_capabilities` map from `__scrypath__/1` calls | ADD `:tenant_field` key to returned capabilities map |
| `Scrypath.Metadata.Resolve` | Resolves applied/defaulted/fixed/unsupported state; already declares `@host_owned` with `tenant_policy: :host_owned` | No change needed; host_owned advisory already surfaces correctly |
| `Scrypath.Search` | Validates search opts then calls `Query.new/2` and dispatches to backend | (stretch) Inject `tenant_scope:` as privileged filter before `Query.new/2` |
| `Scrypath.Query` | Internal struct holding normalized filter, sort, page, facets, per_query | No change — filter list just gains the tenant entry |
| `Scrypath.Projection` | Builds document map from `fields:` list | Auto-include `tenant_field` in projected fields (field must appear in document for filter to match) |
| `guides/multitenancy.md` | Does not exist yet | NEW — canonical shared-index guide |

---

## Integration Points: New vs Modified

### Modified (existing modules that need targeted changes)

**`lib/scrypath/options.ex`** — the primary integration point

- Add `tenant_field:` entry to `@schema_options`:
  ```elixir
  tenant_field: [
    type: {:custom, __MODULE__, :validate_optional_atom, []},
    default: nil,
    doc: "Declares the tenant isolation field; auto-added to filterable: and document projection."
  ]
  ```
- In `validate_schema_options!/1` (currently the pipeline `opts |> validate!(@schema_options) |> ensure_non_empty_fields!() |> validate_faceting_rules!() |> Map.put(:document_source, :fields)`): add a `|> auto_merge_tenant_field()` step that appends the declared field to `:filterable` when non-nil, deduplicating. This happens at compile time — the resulting `filterable` list is what gets stored in `@scrypath_config`.
- (stretch) Add `tenant_scope:` entry to `@search_options` with type `:any`, default `nil`.
- (stretch) In `validate_search_options/2`: after the NimbleOptions validation succeeds, extract `tenant_scope:` and check that the schema declares a `tenant_field`. Inject `{tenant_field_name, tenant_scope_value}` at the front of the `:filter` keyword list so it cannot be overridden by caller-supplied filter entries that follow it in the list. Return a validation error if `tenant_scope:` is supplied but no `tenant_field:` is declared on the schema.

**`lib/scrypath/schema.ex`** — minor extension

- Add `:tenant_field` dispatch to the `__scrypath__/1` generated function:
  ```elixir
  def __scrypath__(:tenant_field), do: @scrypath_config.tenant_field
  ```
  This is a two-line addition inside the `quote` block.

**`lib/scrypath/metadata/capabilities.ex`** — small additive change

- In `schema_capabilities/1`, add a `:tenant` key to the returned map:
  ```elixir
  tenant: %{
    field: schema_module.__scrypath__(:tenant_field)
  }
  ```
  When `tenant_field` is `nil` (not declared), `field: nil` is returned so callers can distinguish "not declared" from "declared as nil". The field is non-nil only when `tenant_field: :some_atom` was explicitly declared.

**`lib/scrypath/projection.ex`** — potential addition

- `build_field_document/2` currently projects exactly the `fields:` list. If `tenant_field` is auto-added to `filterable:` but NOT to `fields:`, the field will be absent from the synced document — meaning Meilisearch receives the filterable attribute metadata but no document data for that field.
- Simplest approach: auto-add `tenant_field` to `fields:` at `validate_schema_options!/1` time alongside the `filterable:` merge. This keeps document projection correct without touching `Projection` at all. The `fields:` list after validation would contain the tenant field.
- If the adopter explicitly declares `tenant_field: :tenant_id` and also has `:tenant_id` in `fields:`, deduplication prevents doubling.
- Custom `search_document/1` hooks are the adopter's responsibility — the guide must note this.

### New (does not exist yet)

**`guides/multitenancy.md`**

The guide is the highest-leverage deliverable. No existing module does this job. It must cover:
- Shared-index model with `filterable: [:tenant_id]` and context-layer injection
- Why per-tenant indexes are not the default (Meilisearch sequential task processing)
- The correct context function pattern with explicit tenant parameter
- Filter merge order bug — why `Keyword.merge([filter: [tenant_id: id]], opts)` silently drops the tenant guard and the correct fix
- `tenant_field:` declaration example (before/after)
- `schema_capabilities/1` reflection showing `:tenant` key
- (stretch) `tenant_scope:` option on `search/3` and when to use it vs manual filter injection
- Tenant token section: server-side search uses filter injection, browser-direct search uses Meilisearch tenant tokens; Scrypath does not generate tokens

---

## Data Flow

### Declaration-time (compile-time)

```
use Scrypath, tenant_field: :tenant_id, fields: [...], filterable: [...]
    |
    v
Options.validate_schema_options!/1
    |
    +-- auto_merge_tenant_field()
    |       appends :tenant_id to filterable (dedup)
    |       appends :tenant_id to fields (dedup, ensures doc projection)
    |
    v
config map: %{tenant_field: :tenant_id, filterable: [:tenant_id, ...], fields: [..., :tenant_id], ...}
    |
    v
Schema.__using__ stores config in @scrypath_config
    |
    v
__scrypath__/1 accessors generated for all keys including :tenant_field
```

### Reflection-time (runtime, read-only)

```
Scrypath.schema_capabilities(Post)
    |
    v
Scrypath.Metadata.schema_capabilities(Post)
    |
    v
Capabilities.schema_capabilities(Post)
    |
    +-- Post.__scrypath__(:tenant_field) -> :tenant_id
    |
    v
%{
  filters: %{...},
  sorts: %{...},
  facets: %{...},
  paging: %{...},
  limits: %{...},
  tenant: %{field: :tenant_id}   <-- NEW
}
```

### Search-time (runtime — standard path, no tenant_scope:)

```
Host context assembles:
  filter: [tenant_id: current_tenant_id] ++ caller_filter

Scrypath.search(Post, text, [filter: [...], ...])
    |
    v
Options.validate_search_options(Post, opts)
    |  validates filter fields against Post.__scrypath__(:filterable)
    |  :tenant_id is in filterable (auto-added at declaration time) -> passes
    |
    v
Search.do_search -> Query.new(text, search_opts)
    |  %Query{filter: [tenant_id: id, ...], ...}
    |
    v
Meilisearch.Query.to_payload -> filter string "tenant_id = 42 AND ..."
    |
    v
Meilisearch backend
```

### Search-time (runtime — stretch: tenant_scope: path)

```
Scrypath.search(Post, text, [tenant_scope: current_tenant_id, filter: [...]])
    |
    v
Options.validate_search_options(Post, opts)
    |  extracts tenant_scope: current_tenant_id
    |  confirms Post.__scrypath__(:tenant_field) == :tenant_id (not nil)
    |  prepends {tenant_field, tenant_scope_value} to :filter list
    |  returns validated opts with :filter = [{:tenant_id, id} | caller_filter]
    |
    v
Search.do_search -> Query.new(text, validated_opts)
    |  tenant filter is first in list, caller filter follows
    |
    v
Meilisearch backend (same as above)
```

---

## Build Order

This ordering respects the compile-time declaration dependency and the runtime reflection dependency.

### Phase 1: Schema declaration + guide (highest leverage, lowest risk)

1. `lib/scrypath/options.ex` — add `tenant_field:` to `@schema_options`, implement `auto_merge_tenant_field/1` pipeline step (appends to `:filterable` and `:fields`, deduplicates both)
2. `lib/scrypath/schema.ex` — add `:tenant_field` dispatch to `__scrypath__/1`
3. Unit tests: schema with `tenant_field:`, verify `__scrypath__(:filterable)` contains the field, verify `__scrypath__(:fields)` contains it, verify `__scrypath__(:tenant_field)` returns the atom
4. `guides/multitenancy.md` — the canonical guide (can be written once options.ex is working)

### Phase 2: Metadata reflection

1. `lib/scrypath/metadata/capabilities.ex` — add `:tenant` key to `schema_capabilities/1` output
2. Unit tests: `schema_capabilities/1` on a schema with and without `tenant_field:`, verify `:tenant` key presence and `field` value
3. `lib/scrypath.ex` — update `@doc` for `schema_capabilities/1` to mention the `:tenant` key

### Phase 3: Guide verification gate

1. `mix verify.phase_N` hermetic test that:
   - confirms `guides/multitenancy.md` exists and anchors match (shared-index model, filter merge warning, tenant_field: example)
   - confirms `schema_capabilities/1` returns `:tenant` key for a schema with `tenant_field:` declared
   - confirms a schema with `tenant_field: :tenant_id` has `:tenant_id` in both `filterable` and `fields`
2. `docs_contract_test.exs` anchor for `guides/multitenancy.md`

### Phase 4 (stretch): tenant_scope: search option

1. `lib/scrypath/options.ex` — add `tenant_scope:` to `@search_options`, implement injection into `:filter` in `validate_search_options/2`
2. `lib/scrypath/search.ex` — no structural change needed if injection happens in options validation; verify the injected filter passes through `Query.new/2` unchanged
3. Unit tests: `search/3` with `tenant_scope:` and a schema that has `tenant_field:` declared; verify the injected filter appears first in the query filter list; verify rejection when `tenant_scope:` is passed on a schema without `tenant_field:`
4. Guide update: add `tenant_scope:` section to `guides/multitenancy.md`

---

## Architectural Patterns

### Pattern 1: Declaration-time auto-merge (preferred)

**What:** `tenant_field:` auto-adds the named field to both `filterable:` and `fields:` during `validate_schema_options!/1` at compile time.

**When to use:** Always. This is the primary value-add — one declaration instead of three repeated atoms across `fields:`, `filterable:`, and context code.

**Trade-offs:** The auto-merge is implicit behavior. The guide must make it explicit. Adopters using `search_document/1` custom projection bypass `fields:` entirely — the guide must call this out.

```elixir
# Declaration
defmodule MyApp.Blog.Post do
  use Scrypath,
    fields: [:title, :body],
    filterable: [:status],
    tenant_field: :tenant_id     # auto-adds :tenant_id to both fields: and filterable:
end

# Result stored in @scrypath_config:
# %{fields: [:title, :body, :tenant_id], filterable: [:status, :tenant_id], tenant_field: :tenant_id, ...}
```

### Pattern 2: Context-layer injection (canonical pattern — no new library code needed)

**What:** The host context assembles the tenant filter explicitly as an argument, not from process state, and calls `Scrypath.search/3` with it.

**When to use:** Always, for server-side search through Scrypath.

**Trade-offs:** Every search callsite must thread the tenant through. This is the correct tradeoff — explicit is safe, implicit is a data-leak footgun. The library can make the declaration correct (Pattern 1) but cannot own the injection without knowing who the tenant is.

```elixir
defmodule MyApp.Blog do
  def search_posts(text, %Tenant{id: tenant_id}, opts \\ []) do
    tenant_filter = [tenant_id: tenant_id]
    caller_filter = Keyword.get(opts, :filter, [])

    Scrypath.search(Post, text,
      Keyword.merge(opts, [
        backend: Scrypath.Meilisearch,
        repo: Repo,
        filter: tenant_filter ++ caller_filter   # tenant first, cannot be shadowed
      ])
    )
  end
end
```

### Pattern 3: tenant_scope: privileged injection (stretch)

**What:** `tenant_scope:` is a search option that bypasses the caller's `filter:` composition risk. The library prepends the tenant filter inside `validate_search_options/2`, before the validated filter list is passed to `Query.new/2`.

**When to use:** Only build this when adopter evidence shows the filter-merge bug is actually occurring in production. It is the correct next step but is premature without that evidence.

**Trade-offs:** Requires `tenant_field:` to be declared on the schema. Returns a validation error if the schema has no declared tenant field. Slightly more magic than Pattern 2, but the injection site is visible in options validation — no hidden callbacks.

---

## Anti-Patterns To Avoid

### Anti-pattern 1: Auto-extraction from process dictionary

**What people do:** Read tenant ID from process state (Plug assigns, process dictionary populated by a Plug) inside the library.

**Why it's wrong:** Breaks across `Task.async`, `assign_async`, Oban workers, and any async boundary. Silent data leak if the process dict is empty. Contradicts the principle that tenant identity is an explicit argument, not ambient context.

**Do this instead:** Require the host context to pass tenant ID as an explicit argument to the search function. The library never reads process state for tenant context.

### Anti-pattern 2: Hidden Ecto callback / lifecycle hook

**What people do:** Add an `after_schema` callback that reads the schema's `tenant_field` and silently adjusts Ecto queries or search calls.

**Why it's wrong:** This is exactly the "hidden magic" pattern the project explicitly rejects. The library's boundary discipline ("no hidden callbacks or Ecto lifecycle magic") applies here.

**Do this instead:** Explicit `tenant_field:` declaration that adjusts `filterable:` and `fields:` at compile time (visible in the declaration). Explicit `filter:` injection at the context layer.

### Anti-pattern 3: Per-tenant index routing

**What people do:** Use `index_prefix:` to create one index per tenant (e.g., `"tenant_42_posts"`).

**Why it's wrong:** Meilisearch processes tasks sequentially per index. With 50+ tenants, all indexing throughput degrades because tasks queue behind each tenant's index worker. Also multiplies operational surface (backfill, reindex, settings drift) by tenant count.

**Do this instead:** Shared index with `filterable: [:tenant_id]` (or `tenant_field: :tenant_id`) plus context-layer filter injection. Reserve per-tenant indexes for compliance/regulatory isolation exceptions only.

### Anti-pattern 4: Using Meilisearch tenant tokens for server-side search

**What people do:** Generate a Meilisearch tenant token on each request and pass the token as the API key to Scrypath, expecting the token to enforce isolation.

**Why it's wrong:** Tenant tokens are designed for browser-direct search (the frontend hits Meilisearch directly). For server-side search through Scrypath, the correct mechanism is `filter: [tenant_id: id]` in the context. Using tokens server-side adds JWT generation overhead and a signing-key dependency to the hot search path.

**Do this instead:** `filter: [tenant_id: id]` in the context for server-side search. Tenant tokens only when the browser needs to call Meilisearch directly (LiveView instant search, InstantSearch.js, etc.) — and document that pattern in the guide.

### Anti-pattern 5: Keyword.merge with tenant filter as first arg

**What people do:**
```elixir
# WRONG — last-key-wins silently drops tenant filter when caller passes filter:
Scrypath.search(Post, text, Keyword.merge([filter: [tenant_id: id]], opts))
```

**Why it's wrong:** `Keyword.merge/2` is last-key-wins. If `opts` contains `filter: [status: :published]`, the caller's filter overwrites the tenant filter entirely. No error, no warning, cross-tenant data leak.

**Do this instead:** Assemble explicitly with tenant filter first in the list:
```elixir
# CORRECT — tenant filter prepended, caller filter appended
tenant_filter = [tenant_id: tenant_id]
caller_filter = Keyword.get(opts, :filter, [])
Scrypath.search(Post, text, Keyword.merge(opts, [filter: tenant_filter ++ caller_filter]))
```

---

## Scaling Considerations

Tenant-safe search in a shared-index model scales with document count, not tenant count. The filter `tenant_id = 42` is evaluated at query time against Meilisearch's inverted index — with `filterableAttributes` configured, this is an indexed lookup, not a full scan. No Scrypath architecture changes are needed at different scales; the underlying Meilisearch guidance applies.

| Scale | Architecture | Notes |
|-------|-------------|-------|
| 0-100k docs | Shared index + `filterable: [:tenant_id]` | Works without tuning |
| 100k-10M docs | Same | Meilisearch handles this well with proper RAM |
| 10M+ docs per tenant | Consider per-tenant index for that tenant only | Compliance or very large tenants; document as exception in guide |

---

## Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| `Options` -> `Schema` | `validate_schema_options!/1` returns config map; schema stores it | Auto-merge of tenant_field happens in Options, not Schema |
| `Schema` -> `Metadata.Capabilities` | `__scrypath__/1` accessor calls | Capabilities reads `:tenant_field` through `__scrypath__(:tenant_field)` |
| `Options` -> `Search` | `validate_search_options/2` returns `{:ok, keyword}` with injected filter | (stretch) Injection is entirely in Options; Search does not need to know about tenant |
| Host context -> `Scrypath.search/3` | Caller passes `filter: [tenant_id: id, ...]` | Filter passes through Options validation (`:tenant_id` is in `filterable` after auto-merge) |

---

## File Change Surface

### Files modified

| File | Change | Risk |
|------|--------|------|
| `lib/scrypath/options.ex` | Add `tenant_field:` to `@schema_options`; add `auto_merge_tenant_field/1` pipeline step; (stretch) add `tenant_scope:` to `@search_options` and injection logic | Low — additive, existing validation pipeline is well-tested |
| `lib/scrypath/schema.ex` | Add `:tenant_field` dispatch to `__scrypath__/1` generated function | Very low — two-line addition in the quote block |
| `lib/scrypath/metadata/capabilities.ex` | Add `:tenant` key to returned capabilities map | Very low — additive |
| `lib/scrypath.ex` | Update `schema_capabilities/1` `@doc` to mention `:tenant` key | Docs only |

### Files created

| File | Purpose |
|------|---------|
| `guides/multitenancy.md` | Canonical multi-tenant guide — the highest-leverage deliverable |

### Files unchanged

`lib/scrypath/search.ex`, `lib/scrypath/query.ex`, `lib/scrypath/meilisearch/query.ex`, `lib/scrypath/projection.ex` (if auto-merge adds tenant_field to fields: in Options), `lib/scrypath/composition.ex`, all operator modules.

---

## Sources

- Codebase (direct inspection, HIGH confidence):
  - `lib/scrypath/options.ex` — `@schema_options`, `validate_schema_options!/1` pipeline, `@search_options`, `validate_search_options/2`
  - `lib/scrypath/schema.ex` — `__using__` macro, `__scrypath__/1` dispatch pattern
  - `lib/scrypath/metadata/capabilities.ex` — `schema_capabilities/1` return shape
  - `lib/scrypath/metadata/resolve.ex` — `@host_owned` with `tenant_policy: :host_owned`
  - `lib/scrypath/search.ex` — `do_search/5`, `validate_search_options` call site
  - `lib/scrypath/query.ex` — `%Query{}` struct, `Query.new/2`
  - `lib/scrypath/meilisearch/query.ex` — `translate_filter/1` shape
  - `lib/scrypath/projection.ex` — `build_field_document/2` reads `__scrypath__(:fields)`
  - `lib/scrypath.ex` — public API surface, reflection helper docs
- Prior research (HIGH confidence):
  - `.planning/research/auth-01-tenant-research.md` — Meilisearch multitenancy mechanism, filter injection patterns, footgun catalogue
- Project context:
  - `.planning/PROJECT.md` — boundary discipline, out-of-scope declarations, key decisions

---
*Architecture research for: AUTH-01 Tenant-Safe Search, v1.25*  
*Researched: 2026-05-25*
