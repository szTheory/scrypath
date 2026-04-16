# Phase 3: Search Query API and Hydration - Context

**Gathered:** 2026-04-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Provide the developer-facing search API that turns Scrypath's completed indexing core into a usable product. This phase owns the common search entrypoint, filtering, sorting, pagination, raw-hit access, and hydration back into Ecto records. It must extend the existing `Scrypath.*` runtime surface without introducing schema-injected runtime APIs, fake backend portability, or hidden hydration behavior.

</domain>

<decisions>
## Implementation Decisions

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

### the agent's Discretion
- The exact names and field layout of the internal query struct and result struct, as long as the public semantics above remain stable and explicit.
- The exact structured-filter DSL for range and boolean composition, as long as it remains validation-friendly and does not expose raw backend syntax on the common path.
- The exact normalization and translation boundary between the common query struct and `Scrypath.Meilisearch.*`.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project scope and locked phase boundaries
- `.planning/PROJECT.md` — project framing, non-negotiable constraints, and the Ecto-first and Meilisearch-first product posture
- `.planning/REQUIREMENTS.md` — Phase 3 requirement mapping for `SRCH-01` through `SRCH-06`
- `.planning/ROADMAP.md` — Phase 3 goal and success criteria
- `.planning/STATE.md` — current project state and continuity notes
- `.planning/phases/01-core-contracts-and-api-shape/01-CONTEXT.md` — locked decisions about runtime surface, schema boundaries, and explicit adapter escape hatches
- `.planning/phases/02-meilisearch-core-sync/02-CONTEXT.md` — locked decisions about explicit runtime verbs, Meilisearch namespace boundaries, and operational honesty

### Current implementation surface
- `lib/scrypath.ex` — top-level public runtime facade that Phase 3 must extend without introducing schema-generated APIs
- `lib/scrypath/backend.ex` — current internal backend behavior, including the existing `search/3` callback that should be tightened around a normalized query shape
- `lib/scrypath/schema.ex` — runtime-searchable metadata, including declared `filterable` and `sortable` fields
- `lib/scrypath/options.ex` — current schema and runtime option conventions, validation patterns, and runtime-config style
- `lib/scrypath/config.ex` — canonical runtime option resolution behavior
- `lib/scrypath/projection.ex` — projection rules and explicit no-implicit-preload policy that Phase 3 hydration must respect
- `lib/scrypath/identity.ex` — current document identity behavior that Phase 3 must not misuse as the hydration identifier
- `lib/scrypath/meilisearch.ex` — current Meilisearch backend module and namespace boundary
- `lib/scrypath/meilisearch/client.ex` — existing search transport layer and current Meilisearch search payload boundary
- `ARCHITECTURE.md` — public architecture statement and deferred-work boundaries
- `README.md` — public product boundary and examples that Phase 3 should extend consistently

### Existing tests and fixtures
- `test/support/searchable_post.ex` — current fixture schema showing declared `filterable` and `sortable` metadata
- `test/support/fake_backend.ex` — backend test double pattern for adapter contract verification
- `test/scrypath/backend_test.exs` — backend contract expectations, including the current search callback shape
- `test/scrypath/meilisearch_test.exs` — current Meilisearch adapter behavior and client call expectations
- `test/scrypath/schema_test.exs` — existing assertions that schema macros do not generate runtime search APIs
- `test/scrypath/sync_test.exs` — existing sync and identity semantics that Phase 3 must remain consistent with

### Local research context
- `prompts/elixir-search-lib-deep-research.md` — ecosystem framing for search-library architecture, DX benchmarks, and operational lessons from adjacent libraries
- `prompts/search-lib-use-cases-deep-research.md` — lessons from Searchkick, Scout, Meilisearch Rails, Haystack, and search-library product positioning
- `prompts/elixir-best-practices-deep-research.md` — Elixir API-shape guidance, especially stable return types and explicit function surfaces
- `prompts/ecto-best-practices-deep-research.md` — Ecto and Phoenix guidance for explicit preloads, context boundaries, query composition, and transactional clarity

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Scrypath.Schema` metadata keys for `:filterable` and `:sortable`: Phase 3 can validate common-path filters and sorts against already-declared schema metadata.
- `Scrypath.Options` plus `NimbleOptions`: existing option validation patterns can support query option normalization without inventing a different public style.
- `Scrypath.Config.resolve!/1`: keeps runtime options explicit and consistent with the rest of the public surface.
- `Scrypath.Meilisearch.Client.search/3`: existing backend transport can become the translation target for a normalized query struct.
- `test/support/fake_backend.ex` and current backend tests: provide an established pattern for backend contract verification and search callback evolution.

### Established Patterns
- Runtime behavior stays under `Scrypath.*`; schema modules remain metadata-first and do not get runtime search helpers.
- Public APIs use explicit verbs and stable Elixir tuples instead of hidden callbacks or magical lifecycle behavior.
- Backend-specific power lives under `Scrypath.Meilisearch.*` instead of being flattened into the common API.
- Projection and data loading are explicit; no implicit association loading or lazy hydration semantics should be introduced.

### Integration Points
- `lib/scrypath.ex` needs the new common search entrypoint and result exposure.
- `lib/scrypath/backend.ex` should evolve from `search(module(), term(), keyword())` toward a normalized query contract.
- `lib/scrypath/meilisearch.ex` and `lib/scrypath/meilisearch/client.ex` need the Meilisearch translation layer for the common query struct plus the explicit native search escape hatch.
- New hydration code must connect to Ecto repos explicitly without breaking Phase 2 identity semantics or overloading `search_document_id/1`.
- Tests should extend the existing backend, schema, and Meilisearch suites instead of introducing a separate shape for query behavior.

</code_context>

<specifics>
## Specific Ideas

- The common happy path should feel like idiomatic Ecto and Phoenix code: `Scrypath.search(Post, "ecto", ..., repo: Repo)` rather than a schema-injected API or builder chain.
- Searchkick is the DX benchmark to learn from, but Scrypath should copy the delight and simplicity rather than the Rails object model.
- Laravel Scout is the architectural benchmark for a clean common path plus explicit engine split, but Scrypath should avoid observer-style hidden behavior and keep hydration semantics clearer than Scout's post-search query hook.
- Meilisearch Rails is the operational benchmark for explicit backend escape hatches, but Scrypath should not leak raw Meilisearch filter strings into the common API.
- The user wants a one-shot coherent recommendation set that emphasizes least surprise, great DX, and strong software architecture rather than a menu of disconnected options.

</specifics>

<deferred>
## Deferred Ideas

- Common-path support for richer backend-native search features such as facets, multisearch, highlighting, and deeper Meilisearch query controls — defer to later work or backend-specific modules unless they become clearly part of the stable Phase 3 happy path.
- Generic post-search hydration callbacks or custom query hooks in the common API — defer until there is proven demand and a clearer least-surprise design.
- Public multi-backend query parity — still deferred until Scrypath has real pressure from a second supported backend.

</deferred>

---
*Phase: 03-search-query-api-and-hydration*
*Context gathered: 2026-04-15*
