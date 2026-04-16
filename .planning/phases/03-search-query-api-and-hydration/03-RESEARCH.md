# Phase 3: Search Query API and Hydration - Research

**Researched:** 2026-04-15
**Domain:** Search query API design, Meilisearch query translation, and Ecto hydration for an Elixir OSS library
**Confidence:** MEDIUM

<user_constraints>
## User Constraints (from CONTEXT.md)

Source: `.planning/phases/03-search-query-api-and-hydration/03-CONTEXT.md`. [VERIFIED: .planning/phases/03-search-query-api-and-hydration/03-CONTEXT.md]

### Locked Decisions

### Search API surface
- **D-01:** Phase 3 should expose one obvious common search entrypoint under `Scrypath`, centered on `Scrypath.search/3` plus a bang variant `Scrypath.search!/3`.
- **D-02:** Runtime search APIs must remain under `Scrypath.*`; do not generate schema methods such as `Post.search/2` or a fluent builder API.
- **D-03:** The public happy path should read like explicit Elixir function calls with keyword options, not like Rails-style model chaining.

### Query input shape
- **D-04:** The common search API should accept the search text as the second argument, not bury it inside a query map or builder object.
- **D-05:** Public query options should use a small Elixir-shaped DSL with structured `filter:`, `sort:`, and `page:` options, then normalize internally into a dedicated query struct such as `%Scrypath.Query{}`.
- **D-06:** `filter:` in the common path should use structured Elixir data over declared `filterable` fields only; raw Meilisearch filter strings are out of bounds for the common API.
- **D-07:** `sort:` in the common path should mirror Ecto-style ordering, such as `[desc: :inserted_at]`, over declared `sortable` fields only.
- **D-08:** Pagination should be expressed as a nested option such as `page: [number: 2, size: 20]`, not as loose top-level `limit` and `offset` options.

### Result shape and hydration contract
- **D-09:** `Scrypath.search/3` should return one stable result envelope struct rather than switching return shapes based on flags or options.
- **D-10:** The result envelope must include both hydrated Ecto records and raw hit data so advanced search metadata remains accessible without sacrificing the normal Phoenix and Ecto happy path.
- **D-11:** The result envelope should also surface pagination metadata, total or estimated total information where available, and explicit missing-hit information such as `missing_ids`.
- **D-12:** Hydration must be batched, explicit, and Ecto-native: one batch reload per search result set, never N+1 hydration queries.
- **D-13:** Hydrated record ordering must follow search-engine hit order, restored in Elixir after the batch repo load, rather than depending on database return order.
- **D-14:** Missing or stale source rows must not disappear silently; the common result should surface them explicitly so search drift stays operationally visible.

### Hydration inputs and source identity
- **D-15:** The common search path should require an explicit `repo:` option for hydration behavior rather than relying on hidden global repo inference.
- **D-16:** `preload:` is allowed in the common path, but it must remain explicit and should apply only to the hydration query, not to search-engine filtering semantics.
- **D-17:** Phase 3 must reserve an explicit source-record identifier for hydration, defaulting to the schema primary key, so hydration does not depend on reversible custom `search_document_id/1` values.
- **D-18:** Do not add a generic post-search query callback in the common API for v1; it is too easy to confuse DB hydration customization with search-engine filtering semantics.

### Backend escape hatch
- **D-19:** Phase 3 should keep the common search path small and backend-agnostic only across the stable happy path: query text, declared filters, declared sorts, pagination, raw-hit access, and hydration.
- **D-20:** Richer Meilisearch-native search power should live under an explicit `Scrypath.Meilisearch.*` namespace, including a native search entrypoint such as `Scrypath.Meilisearch.search/3`.
- **D-21:** Do not tunnel backend-native query features through opaque passthrough options on `Scrypath.search/3`; that would create a fake abstraction and an unstable public contract.

### Claude's Discretion
- The exact names and field layout of the internal query struct and result struct, as long as the public semantics above remain stable and explicit.
- The exact structured-filter DSL for range and boolean composition, as long as it remains validation-friendly and does not expose raw backend syntax on the common path.
- The exact normalization and translation boundary between the common query struct and `Scrypath.Meilisearch.*`.

### Deferred Ideas (OUT OF SCOPE)
- Common-path support for richer backend-native search features such as facets, multisearch, highlighting, and deeper Meilisearch query controls — defer to later work or backend-specific modules unless they become clearly part of the stable Phase 3 happy path.
- Generic post-search hydration callbacks or custom query hooks in the common API — defer until there is proven demand and a clearer least-surprise design.
- Public multi-backend query parity — still deferred until Scrypath has real pressure from a second supported backend.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SRCH-01 | Developer can execute a search against a searchable schema using a small, consistent API. | Use `Scrypath.search/3` and `search!/3` with public keyword options normalized into `%Scrypath.Query{}`. [VERIFIED: .planning/REQUIREMENTS.md] |
| SRCH-02 | Developer can filter search results using declared filterable fields. | Validate `filter:` only against schema `:filterable` metadata before backend translation. [VERIFIED: lib/scrypath/schema.ex] |
| SRCH-03 | Developer can sort search results using declared sortable fields. | Accept Ecto-style keyword ordering and validate only against schema `:sortable` metadata. [VERIFIED: lib/scrypath/schema.ex] [CITED: https://hexdocs.pm/ecto/Ecto.Query.html] |
| SRCH-04 | Developer can paginate search results. | Normalize `page: [number:, size:]` into backend pagination params and expose returned totals explicitly. [VERIFIED: .planning/phases/03-search-query-api-and-hydration/03-CONTEXT.md] [CITED: https://www.meilisearch.com/docs/guides/front_end/pagination] |
| SRCH-05 | Developer can access raw backend hit metadata when needed. | Stable result envelope should keep `hits` and raw backend metadata instead of returning only hydrated rows. [VERIFIED: .planning/phases/03-search-query-api-and-hydration/03-CONTEXT.md] |
| SRCH-06 | Developer can hydrate search hits back into Ecto records. | Require explicit `repo:` and optional `preload:`, batch-load records, restore hit order in Elixir, and surface `missing_ids`. [VERIFIED: .planning/phases/03-search-query-api-and-hydration/03-CONTEXT.md] [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html] |
</phase_requirements>

## Summary

Phase 3 should add one common search facade under `Scrypath`, with public keyword options normalized into a dedicated query struct before any backend call. The current codebase already centralizes runtime behavior under `Scrypath.*`, keeps schema modules metadata-only, and keeps the backend seam narrow, but the existing `Scrypath.Backend.search/3` callback still accepts an unconstrained `term()` and the Meilisearch client still accepts either a binary or arbitrary map. [VERIFIED: lib/scrypath.ex] [VERIFIED: lib/scrypath/backend.ex] [VERIFIED: lib/scrypath/meilisearch.ex] [VERIFIED: lib/scrypath/meilisearch/client.ex]

The safest product shape is: `Scrypath.search(schema, text, opts)` for the common path, `%Scrypath.Query{}` for internal normalization, `%Scrypath.SearchResult{}` for the stable return envelope, and `Scrypath.Meilisearch.search/3` as the explicit native escape hatch. Meilisearch requires filterable and sortable attributes to be configured before those search parameters work, exposes `sort` as an array of `"field:direction"` strings, and supports both `offset`/`limit` and `page`/`hitsPerPage` pagination while returning different total metadata depending on pagination mode. [VERIFIED: lib/scrypath/schema.ex] [CITED: https://www.meilisearch.com/docs/reference/features/filtering] [CITED: https://www.meilisearch.com/docs/learn/filtering_and_sorting/sort_search_results] [CITED: https://www.meilisearch.com/docs/guides/front_end/pagination]

Hydration should stay explicit and Ecto-native: require `repo:`, allow `preload:`, fetch all source rows in one query, build an ID-to-record map, and restore hit order in Elixir while surfacing missing rows instead of silently dropping them. Ecto supports dynamic field references through `field/2`, explicit preloads through query preload or `Repo.preload/3`, and guarantees ordering preservation only for `Repo.reload/2` on an input list of structs, which is not the same problem as loading arbitrary IDs from search hits. [CITED: https://hexdocs.pm/ecto/Ecto.Query.API.html] [CITED: https://hexdocs.pm/ecto/Ecto.Query.html] [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html]

**Primary recommendation:** Implement a normalized `%Scrypath.Query{}` plus `%Scrypath.SearchResult{}` contract first, then adapt `Scrypath.Backend.search/3` and Meilisearch translation around that boundary. [VERIFIED: lib/scrypath/backend.ex] [VERIFIED: .planning/phases/03-search-query-api-and-hydration/03-CONTEXT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Public search facade (`Scrypath.search/3`) | API / Backend | — | Runtime APIs are explicitly centralized under `Scrypath.*`, not on schemas or in the browser. [VERIFIED: lib/scrypath.ex] [VERIFIED: test/scrypath/schema_test.exs] |
| Query normalization and validation | API / Backend | — | Schema metadata and runtime option validation already live in Elixir modules using `NimbleOptions`. [VERIFIED: lib/scrypath/schema.ex] [VERIFIED: lib/scrypath/options.ex] [CITED: https://hexdocs.pm/nimble_options/api-reference.html] |
| Search backend translation | API / Backend | External search service | `Scrypath.Backend` and `Scrypath.Meilisearch` already own index resolution and transport delegation. [VERIFIED: lib/scrypath/backend.ex] [VERIFIED: lib/scrypath/meilisearch.ex] |
| Hydration query and preload execution | API / Backend | Database / Storage | The library should build an Ecto query and execute it through an explicit repo, then optionally preload associations. [VERIFIED: .planning/phases/03-search-query-api-and-hydration/03-CONTEXT.md] [CITED: https://hexdocs.pm/ecto/Ecto.Query.html] [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html] |
| Hit-order restoration and missing-row reporting | API / Backend | — | Search hit order comes from the backend, while stale-row visibility and record ordering must be reconstructed in Elixir. [VERIFIED: .planning/phases/03-search-query-api-and-hydration/03-CONTEXT.md] |
| Meilisearch-native escape hatch | API / Backend | External search service | Phase context explicitly keeps richer backend-native search under `Scrypath.Meilisearch.*`. [VERIFIED: .planning/phases/03-search-query-api-and-hydration/03-CONTEXT.md] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Ecto | 3.13.5 | Query composition for hydration and explicit preload handling | Already in `mix.exs`; current stable release in Hex API; official docs cover keyword `order_by`, `field/2`, and explicit preload behavior. [VERIFIED: mix.exs] [VERIFIED: Hex API] [CITED: https://hexdocs.pm/ecto/Ecto.Query.html] [CITED: https://hexdocs.pm/ecto/Ecto.Query.API.html] [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html] |
| NimbleOptions | 1.1.1 | Public query option validation and normalization | Already used for schema/runtime option validation; fits current code style. [VERIFIED: lib/scrypath/options.ex] [VERIFIED: Hex API] [CITED: https://hexdocs.pm/nimble_options/api-reference.html] |
| Req | 0.5.17 | Meilisearch transport and request testing | Already the backend transport; `Req.Test` is already in current tests. [VERIFIED: lib/scrypath/meilisearch/client.ex] [VERIFIED: test/scrypath/meilisearch_test.exs] [VERIFIED: Hex API] |
| Meilisearch Search API | current docs | Backend-native search parameter contract | Common-path translation must target official `filter`, `sort`, and pagination semantics. [CITED: https://www.meilisearch.com/docs/reference/features/filtering] [CITED: https://www.meilisearch.com/docs/learn/filtering_and_sorting/sort_search_results] [CITED: https://www.meilisearch.com/docs/guides/front_end/pagination] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Jason | 1.4.4 | JSON encoding for transport payloads | Already present; keep as transport support, not query-domain logic. [VERIFIED: mix.exs] [VERIFIED: Hex API] |
| ExUnit | bundled with Elixir 1.19.5 | Unit and contract testing | Existing test suite already uses ExUnit; Phase 3 should extend it instead of adding a second framework. [VERIFIED: test/scrypath/backend_test.exs] [VERIFIED: elixir --version] |
| Plug | 1.19.1 | `Req.Test` support in tests | Already test-only dependency; enough for Meilisearch transport stubs. [VERIFIED: mix.exs] [VERIFIED: Hex API] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Normalized `%Scrypath.Query{}` | Raw keyword passthrough to backend | Faster to code now, but keeps `Scrypath.Backend.search/3` vague and makes validation, testing, and future backends harder. [VERIFIED: lib/scrypath/backend.ex] |
| Ecto-style `sort: [desc: :inserted_at]` | Meilisearch-native `"field:desc"` strings in common API | Native strings match Meilisearch directly, but violate the locked Phase 3 common-path boundary. [VERIFIED: .planning/phases/03-search-query-api-and-hydration/03-CONTEXT.md] [CITED: https://www.meilisearch.com/docs/learn/filtering_and_sorting/sort_search_results] |
| Reorder hydrated rows in Elixir | DB-specific SQL ordering fragments | DB-side ordering can work per adapter, but Elixir-side reordering is backend-agnostic and matches the locked Phase 3 ordering rule. [VERIFIED: .planning/phases/03-search-query-api-and-hydration/03-CONTEXT.md] |

**Installation:**
```bash
# No new Phase 3 packages required
mix deps.get
```

**Version verification:** Verified against the Hex API on 2026-04-15. [VERIFIED: Hex API]
```bash
curl -s https://hex.pm/api/packages/ecto | jq -r '.releases[0] | [.version, .inserted_at] | @tsv'
curl -s https://hex.pm/api/packages/req | jq -r '.releases[0] | [.version, .inserted_at] | @tsv'
curl -s https://hex.pm/api/packages/nimble_options | jq -r '.releases[0] | [.version, .inserted_at] | @tsv'
curl -s https://hex.pm/api/packages/jason | jq -r '[.releases[] | select(.version|test("-")|not)][0] | [.version, .inserted_at] | @tsv'
```

Verified publish dates: `ecto` 3.13.5 on 2025-11-09, `req` 0.5.17 on 2026-01-05, `nimble_options` 1.1.1 on 2024-05-25, `jason` 1.4.4 on 2024-07-26, and `plug` 1.19.1 on 2025-12-09. [VERIFIED: Hex API]

## Architecture Patterns

### System Architecture Diagram

```text
Caller
  |
  v
Scrypath.search/3
  |
  v
Query option validation
  |
  v
%Scrypath.Query{}
  |
  +--> schema metadata checks
  |      - filterable fields
  |      - sortable fields
  |
  v
Scrypath.Backend.search(schema, query, config)
  |
  +--> Scrypath.Meilisearch.search/3
           |
           v
      Meilisearch request payload
           |
           v
      raw backend response
           |
           v
      normalized backend result
  |
  v
hydration planner
  |
  +--> no repo: raw hits only result
  |
  +--> repo present:
         build Ecto query by source ids
         apply explicit preload
         repo.all(...)
         map rows by source id
         restore hit order
         collect missing_ids
  |
  v
%Scrypath.SearchResult{}
```

### Recommended Project Structure
```text
lib/
├── scrypath.ex                    # Public search facade and bang variants
├── scrypath/query.ex              # Normalized query struct + normalization helpers
├── scrypath/search_result.ex      # Stable result envelope struct
├── scrypath/search.ex             # Common orchestration and hydration logic
├── scrypath/backend.ex            # Narrowed search callback contract
└── scrypath/meilisearch/
    ├── query.ex                   # Common-query -> Meilisearch payload translation
    └── result.ex                  # Native response normalization helpers
```

### Pattern 1: Normalize Public Options Before Backend Calls
**What:** Convert `text + opts` into a dedicated query struct and reject invalid filter/sort fields before backend translation. [VERIFIED: .planning/phases/03-search-query-api-and-hydration/03-CONTEXT.md] [VERIFIED: lib/scrypath/options.ex]

**When to use:** Always on the common path; never pass raw keyword options directly into `Scrypath.Backend.search/3`. [VERIFIED: lib/scrypath/backend.ex]

**Example:**
```elixir
# Source: Phase 3 context + current codebase
%Scrypath.Query{
  text: "ecto",
  filter: [status: "published"],
  sort: [desc: :inserted_at],
  page: %{number: 2, size: 20}
}
```
[ASSUMED]

### Pattern 2: Hydrate by Explicit Source ID, Not Search Document ID
**What:** Keep a dedicated source-row identifier for hydration so custom `search_document_id/1` values do not become the DB lookup key. [VERIFIED: .planning/phases/03-search-query-api-and-hydration/03-CONTEXT.md] [VERIFIED: lib/scrypath/identity.ex]

**When to use:** Any time the common result includes hydrated records. [VERIFIED: .planning/REQUIREMENTS.md]

**Example:**
```elixir
# Source: Ecto.Query/API + Ecto.Query preload docs
ids = Enum.map(raw_hits, & &1.source_id)

records_by_id =
  schema
  |> where([record], field(record, ^source_id_field) in ^ids)
  |> preload(^preloads)
  |> repo.all()
  |> Map.new(&{Map.fetch!(&1, source_id_field), &1})

records = Enum.map(ids, &Map.get(records_by_id, &1))
missing_ids = for {id, nil} <- Enum.zip(ids, records), do: id
```
Source rationale: `field/2` and dynamic preload are documented Ecto patterns; the reordering step is the recommended Scrypath-specific adaptation. [CITED: https://hexdocs.pm/ecto/Ecto.Query.API.html] [CITED: https://hexdocs.pm/ecto/Ecto.Query.html] [ASSUMED]

### Pattern 3: Keep Meilisearch-Native Query Power Namespaced
**What:** Translate the common query struct into Meilisearch payloads in one module, and keep richer native features under `Scrypath.Meilisearch.*`. [VERIFIED: lib/scrypath/meilisearch.ex] [VERIFIED: .planning/phases/03-search-query-api-and-hydration/03-CONTEXT.md]

**When to use:** Common search API for stable happy-path features; native namespace for highlights, facets, multisearch, and raw filter expressions later. [VERIFIED: .planning/phases/03-search-query-api-and-hydration/03-CONTEXT.md]

**Example:**
```elixir
# Source: Meilisearch sort and pagination docs
%{
  q: query.text,
  filter: translated_filter,
  sort: ["inserted_at:desc"],
  page: 2,
  hitsPerPage: 20
}
```
[CITED: https://www.meilisearch.com/docs/learn/filtering_and_sorting/sort_search_results] [CITED: https://www.meilisearch.com/docs/guides/front_end/pagination]

### Anti-Patterns to Avoid
- **Raw filter strings on the common path:** Phase 3 explicitly forbids exposing Meilisearch filter syntax through `Scrypath.search/3`. [VERIFIED: .planning/phases/03-search-query-api-and-hydration/03-CONTEXT.md]
- **Hydration with hidden repo inference:** `repo:` is a locked explicit input, not an app-config side effect. [VERIFIED: .planning/phases/03-search-query-api-and-hydration/03-CONTEXT.md]
- **Switching result shape with flags:** Elixir guidance favors stable return types over option-driven shape changes. [VERIFIED: .planning/phases/03-search-query-api-and-hydration/03-CONTEXT.md] [CITED: https://hexdocs.pm/elixir/code-anti-patterns.html#alternative-return-types]
- **Treating `search_document_id/1` as the hydration key:** Delete identity and hydration identity are different concerns in the current design. [VERIFIED: lib/scrypath/identity.ex] [VERIFIED: .planning/phases/02-meilisearch-core-sync/02-CONTEXT.md] [VERIFIED: .planning/phases/03-search-query-api-and-hydration/03-CONTEXT.md]

## Likely Plan Slices

| Slice | Scope | Why this cut |
|------|-------|--------------|
| 1 | `%Scrypath.Query{}` struct, option schemas, schema metadata validation | Gives the rest of the phase a stable contract and closes the current `term()` backend seam. [VERIFIED: lib/scrypath/backend.ex] |
| 2 | `Scrypath.search/3` facade, bang variant, backend callback update | Establishes the common API surface required by SRCH-01 through SRCH-04. [VERIFIED: .planning/REQUIREMENTS.md] |
| 3 | Meilisearch query translator and native escape hatch | Keeps common-path semantics small while preserving backend-native power explicitly. [VERIFIED: .planning/phases/03-search-query-api-and-hydration/03-CONTEXT.md] |
| 4 | `%Scrypath.SearchResult{}` and hydration pipeline | Delivers SRCH-05 and SRCH-06 with explicit stale-row visibility. [VERIFIED: .planning/REQUIREMENTS.md] |
| 5 | Contract tests, hydration tests, README/architecture updates | Existing repo already treats docs and tests as part of phase completion. [VERIFIED: README.md] [VERIFIED: ARCHITECTURE.md] |

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Public query validation | Ad hoc keyword parsing with custom error strings | `NimbleOptions` schemas plus explicit post-validation checks against schema metadata | Current repo already uses `NimbleOptions`; it keeps option errors consistent and inspectable. [VERIFIED: lib/scrypath/options.ex] [CITED: https://hexdocs.pm/nimble_options/api-reference.html] |
| DB result ordering restoration | SQL-dialect-specific custom ordering for every repo | Batch fetch plus Elixir-side map/reorder | The locked phase rule already says restored order belongs in Elixir, not implicit DB order. [VERIFIED: .planning/phases/03-search-query-api-and-hydration/03-CONTEXT.md] |
| Common-path backend feature passthrough | Generic `backend_opts:` tunnel on `Scrypath.search/3` | Explicit `Scrypath.Meilisearch.*` namespace | Avoids fake portability and unstable common-path semantics. [VERIFIED: .planning/phases/03-search-query-api-and-hydration/03-CONTEXT.md] |
| Total-hit calculation | Local derivation of total pages from partial hit lists | Meilisearch response metadata (`estimatedTotalHits`, or `totalHits`/`totalPages` when page mode is used) | Official Meilisearch docs already define the pagination metadata contract. [CITED: https://www.meilisearch.com/docs/guides/front_end/pagination] |

**Key insight:** The common API should normalize and validate Elixir-shaped data, then translate once at the backend boundary; trying to make the common surface speak native Meilisearch terms too early will couple the product to one backend and make tests harder to reason about. [VERIFIED: .planning/phases/03-search-query-api-and-hydration/03-CONTEXT.md] [VERIFIED: lib/scrypath/backend.ex]

## Common Pitfalls

### Pitfall 1: Confusing search document identity with hydration identity
**What goes wrong:** A custom `search_document_id/1` such as `"post:123"` gets reused as the DB lookup key and hydration fails or becomes adapter-specific. [VERIFIED: lib/scrypath/identity.ex]
**Why it happens:** Phase 2 established delete identity around search documents, while Phase 3 needs source-row lookup semantics. [VERIFIED: .planning/phases/02-meilisearch-core-sync/02-CONTEXT.md] [VERIFIED: .planning/phases/03-search-query-api-and-hydration/03-CONTEXT.md]
**How to avoid:** Add an explicit source identifier to hit normalization and keep it separate from document ID in the result contract. [ASSUMED]
**Warning signs:** Tests pass for default `:id` schemas but fail for schemas with `search_document_id/1`. [VERIFIED: test/scrypath/sync_test.exs]

### Pitfall 2: Silently dropping stale rows during hydration
**What goes wrong:** Search hits whose DB rows were deleted or not yet visible simply disappear from the returned records list. [VERIFIED: .planning/phases/03-search-query-api-and-hydration/03-CONTEXT.md]
**Why it happens:** A naive `Enum.filter(& &1)` makes drift invisible to callers. [ASSUMED]
**How to avoid:** Preserve the raw hits list and return `missing_ids` in the result envelope. [VERIFIED: .planning/phases/03-search-query-api-and-hydration/03-CONTEXT.md]
**Warning signs:** `length(records) < length(hits)` with no explicit missing metadata. [ASSUMED]

### Pitfall 3: Letting raw backend syntax leak into the common API
**What goes wrong:** The happy path starts accepting Meilisearch filter strings, breaking the locked abstraction boundary. [VERIFIED: .planning/phases/03-search-query-api-and-hydration/03-CONTEXT.md]
**Why it happens:** The Meilisearch transport already accepts arbitrary maps today, so passthrough looks easy. [VERIFIED: lib/scrypath/meilisearch/client.ex]
**How to avoid:** Narrow `Scrypath.Backend.search/3` to a query struct and keep native search under `Scrypath.Meilisearch.search/3`. [VERIFIED: lib/scrypath/backend.ex] [VERIFIED: .planning/phases/03-search-query-api-and-hydration/03-CONTEXT.md]
**Warning signs:** New tests assert on raw Meilisearch filter strings from `Scrypath.search/3`. [ASSUMED]

### Pitfall 4: Treating pagination metadata as universal
**What goes wrong:** The result struct always expects exhaustive totals even when the query used estimated totals. [CITED: https://www.meilisearch.com/docs/guides/front_end/pagination]
**Why it happens:** Meilisearch returns `estimatedTotalHits` by default, but switches to `totalHits` and `totalPages` when `page` or `hitsPerPage` are present. [CITED: https://www.meilisearch.com/docs/guides/front_end/pagination]
**How to avoid:** Store both the chosen page request and the backend totals returned, with nils where Meilisearch does not provide exhaustive values. [ASSUMED]
**Warning signs:** Callers compute page counts from `estimatedTotalHits`. [CITED: https://www.meilisearch.com/docs/guides/front_end/pagination]

## Code Examples

Verified patterns from official sources and current code style:

### Dynamic Ecto Field Lookup for Hydration
```elixir
query =
  from record in schema,
    where: field(record, ^source_id_field) in ^ids,
    preload: ^preloads

repo.all(query)
```
Source rationale: `field/2` is part of `Ecto.Query.API`, and dynamic preloads are documented in `Ecto.Query`. [CITED: https://hexdocs.pm/ecto/Ecto.Query.API.html] [CITED: https://hexdocs.pm/ecto/Ecto.Query.html]

### Ecto-Style Sort Input
```elixir
sort = [asc: :title, desc: :inserted_at]

from record in schema, order_by: ^sort
```
Source rationale: Ecto query docs support interpolated keyword lists for `order_by`. [CITED: https://hexdocs.pm/ecto/Ecto.Query.html]

### Meilisearch Sort and Page Payload
```elixir
%{
  q: "ecto",
  sort: ["inserted_at:desc"],
  page: 2,
  hitsPerPage: 20
}
```
Source rationale: Official Meilisearch docs use string-array sort payloads and page-based pagination for exhaustive totals. [CITED: https://www.meilisearch.com/docs/learn/filtering_and_sorting/sort_search_results] [CITED: https://www.meilisearch.com/docs/guides/front_end/pagination]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Backend `search/3` accepts unconstrained `term()` | Normalize to a dedicated query struct before backend calls | Current Scrypath Phase 3 recommendation | Makes validation and adapter contract tests much simpler. [VERIFIED: lib/scrypath/backend.ex] [ASSUMED] |
| Hits-only or rows-only return values | Stable result envelope with raw hits, hydrated rows, and missing-row visibility | Current Scrypath Phase 3 requirement set | Keeps ranking metadata available without hiding drift. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/phases/03-search-query-api-and-hydration/03-CONTEXT.md] |
| Assume database returns `WHERE id IN (...)` rows in search-hit order | Restore order in Elixir after one batch load | Current Scrypath Phase 3 locked decision | Avoids database-specific ordering behavior in the common path. [VERIFIED: .planning/phases/03-search-query-api-and-hydration/03-CONTEXT.md] |
| Loose top-level `limit` and `offset` API | Nested `page: [number:, size:]` public DSL | Current Scrypath Phase 3 locked decision | Matches the requested Elixir-shaped API and maps cleanly to Meilisearch page mode. [VERIFIED: .planning/phases/03-search-query-api-and-hydration/03-CONTEXT.md] [CITED: https://www.meilisearch.com/docs/guides/front_end/pagination] |

**Deprecated/outdated:**
- Using raw Meilisearch filter strings in the common API: Phase 3 explicitly rejects that product shape. [VERIFIED: .planning/phases/03-search-query-api-and-hydration/03-CONTEXT.md]
- Returning different result shapes based on flags: Elixir anti-pattern guidance and the phase context both push toward stable return types. [CITED: https://hexdocs.pm/elixir/code-anti-patterns.html#alternative-return-types] [VERIFIED: .planning/phases/03-search-query-api-and-hydration/03-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `%Scrypath.Query{}` should use fields roughly shaped like `text`, `filter`, `sort`, and `page` | Architecture Patterns | Low; planner can rename fields without changing phase scope |
| A2 | The best common-path hydration result should expose `missing_ids` rather than only a count | Common Pitfalls / Summary | Low; planner can choose equivalent visibility like `missing_hits` |
| A3 | The common filter DSL should reserve explicit tuple forms for boolean composition and range operators | Architecture Patterns | Medium; planner may prefer a different but still structured DSL |
| A4 | A fake repo module plus query inspection is the lowest-friction initial test strategy for hydration in this phase | Validation Architecture | Medium; planner may decide DB-backed integration tests are worth the added setup |

## Open Questions

1. **Where should the source-row hydration identifier live?**
   - What we know: Phase 3 requires a hydration identifier distinct from custom `search_document_id/1`. [VERIFIED: .planning/phases/03-search-query-api-and-hydration/03-CONTEXT.md]
   - What's unclear: Whether to infer it from `__schema__(:primary_key)` at runtime, add metadata to `use Scrypath`, or reserve a hidden backend field. [ASSUMED]
   - Recommendation: Keep Phase 3 to a single primary-key hydration path and derive it from the schema at runtime unless code review finds an edge case that forces explicit metadata. [ASSUMED]

2. **How much boolean filter DSL belongs in Phase 3?**
   - What we know: The common API must stay structured and validation-friendly, and raw Meilisearch strings are out of scope. [VERIFIED: .planning/phases/03-search-query-api-and-hydration/03-CONTEXT.md]
   - What's unclear: Whether Phase 3 needs only implicit `AND` plus simple comparison operators, or also explicit `OR` groups. [ASSUMED]
   - Recommendation: Lock Phase 3 to equality plus range operators and add one explicit boolean-composition form only if a concrete requirement appears in planning. [ASSUMED]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir 1.19.5 [VERIFIED: elixir --version] |
| Config file | none — standard Mix/ExUnit layout detected [VERIFIED: rg --files] |
| Quick run command | `mix test test/scrypath/search_test.exs` [ASSUMED] |
| Full suite command | `mix test` [VERIFIED: Mix task usage] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SRCH-01 | `Scrypath.search/3` normalizes text plus opts and calls backend with a query struct | unit | `mix test test/scrypath/search_test.exs -x` | ❌ Wave 0 |
| SRCH-02 | filter validation rejects undeclared fields and invalid operators | unit | `mix test test/scrypath/search_test.exs -x` | ❌ Wave 0 |
| SRCH-03 | sort validation accepts Ecto-style keyword order and rejects undeclared fields | unit | `mix test test/scrypath/search_test.exs -x` | ❌ Wave 0 |
| SRCH-04 | page normalization produces stable result metadata for Meilisearch page mode | unit/integration | `mix test test/scrypath/meilisearch_search_test.exs -x` | ❌ Wave 0 |
| SRCH-05 | result envelope keeps raw hits and backend metadata | unit | `mix test test/scrypath/search_result_test.exs -x` | ❌ Wave 0 |
| SRCH-06 | hydration batch-loads, preserves hit order, and reports missing ids | unit | `mix test test/scrypath/hydration_test.exs -x` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test test/scrypath/search_test.exs`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/scrypath/search_test.exs` — common API, query normalization, and validation
- [ ] `test/scrypath/hydration_test.exs` — ordering, missing rows, explicit preload/repo semantics
- [ ] `test/scrypath/meilisearch_search_test.exs` — translator payloads and page metadata normalization
- [ ] `test/support/fake_repo.ex` or equivalent hydration test double — capture generated Ecto query or preload behavior [ASSUMED]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Phase 3 is a library query API, not an auth subsystem. [VERIFIED: .planning/ROADMAP.md] |
| V3 Session Management | no | Phase 3 does not manage sessions. [VERIFIED: .planning/ROADMAP.md] |
| V4 Access Control | no | Tenant-scoping and authz are not part of this phase scope. [VERIFIED: .planning/REQUIREMENTS.md] |
| V5 Input Validation | yes | Validate search text, filter fields, sort fields, and page bounds with `NimbleOptions` plus schema metadata checks. [VERIFIED: lib/scrypath/options.ex] [VERIFIED: lib/scrypath/schema.ex] [CITED: https://hexdocs.pm/nimble_options/api-reference.html] |
| V6 Cryptography | no | No cryptographic feature is introduced in this phase. [VERIFIED: .planning/ROADMAP.md] |

### Known Threat Patterns for Elixir query API + Meilisearch translation

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Invalid filter or sort field reaches backend | Tampering | Validate against schema `:filterable` and `:sortable` lists before translation. [VERIFIED: lib/scrypath/schema.ex] |
| Oversized page size causes excessive query cost | Denial of Service | Enforce page-size bounds in query validation. [ASSUMED] |
| Raw backend syntax injection through common API | Tampering | Keep native filter strings out of `Scrypath.search/3` and route native power to `Scrypath.Meilisearch.*`. [VERIFIED: .planning/phases/03-search-query-api-and-hydration/03-CONTEXT.md] |
| Silent stale-row masking hides drift | Repudiation / Integrity | Return `missing_ids` and raw hits so missing source rows remain visible. [VERIFIED: .planning/phases/03-search-query-api-and-hydration/03-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/03-search-query-api-and-hydration/03-CONTEXT.md` - locked Phase 3 decisions and boundaries
- `lib/scrypath.ex` - current public runtime facade
- `lib/scrypath/backend.ex` - current backend callback contract
- `lib/scrypath/schema.ex` - schema metadata keys for filterable/sortable fields
- `lib/scrypath/options.ex` - existing `NimbleOptions` validation pattern
- `lib/scrypath/identity.ex` - current document identity behavior
- `lib/scrypath/meilisearch.ex` - explicit Meilisearch namespace boundary
- `lib/scrypath/meilisearch/client.ex` - current search transport payload boundary
- `test/support/fake_backend.ex` and `test/scrypath/backend_test.exs` - backend contract testing pattern
- `test/scrypath/meilisearch_test.exs` - current Meilisearch request/response expectations
- `https://hexdocs.pm/ecto/Ecto.Query.html` - keyword `order_by`, dynamic preload docs
- `https://hexdocs.pm/ecto/Ecto.Query.API.html` - `field/2` for dynamic field access
- `https://hexdocs.pm/ecto/Ecto.Repo.html` - explicit preload/reload semantics
- `https://hexdocs.pm/nimble_options/api-reference.html` - option validation API
- `https://www.meilisearch.com/docs/reference/features/filtering` - filterable attributes and filter/sort/facet contract
- `https://www.meilisearch.com/docs/learn/filtering_and_sorting/sort_search_results` - search-time sort payload shape
- `https://www.meilisearch.com/docs/guides/front_end/pagination` - `page`/`hitsPerPage` vs `offset`/`limit`, total metadata behavior
- `https://hex.pm/api/packages/ecto` - verified package version and publish date
- `https://hex.pm/api/packages/req` - verified package version and publish date
- `https://hex.pm/api/packages/nimble_options` - verified package version and publish date
- `https://hex.pm/api/packages/jason` - verified package version and publish date
- `https://hex.pm/api/packages/plug` - verified package version and publish date

### Secondary (MEDIUM confidence)
- `https://hexdocs.pm/elixir/code-anti-patterns.html#alternative-return-types` - stable return type guidance applied to result-envelope recommendation

### Tertiary (LOW confidence)
- None

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - all recommended core libraries are already present in the repo and versions were verified via Hex API.
- Architecture: MEDIUM - the direction is strongly constrained by Phase 3 context, but exact query/result field layouts remain discretionary.
- Pitfalls: MEDIUM - most are locked by context and current code shape, but a few mitigation details are still design recommendations.

**Research date:** 2026-04-15
**Valid until:** 2026-05-15
