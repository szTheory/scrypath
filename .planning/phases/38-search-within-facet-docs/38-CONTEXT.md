# Phase 38: Search within facet + docs - Context

**Gathered:** 2026-04-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship **FACET-03** and **FACET-04** for v1.7: a **public** scoped full-text entry that searches **inside a declared facet bucket** with **filter composition** consistent with **`Scrypath.search/3`**, plus **guide-first documentation**, **`docs_contract_test.exs`** anchors, and **thin README/ExDoc discoverability**. Stays Meilisearch-first and honest: **one physical search** by default, **engine-aligned** semantics, no multi-index federation or per-query relevance pipeline.

**Process note:** User requested **all** gray areas and delegated decisions to **parallel research + one-shot synthesis** (no per-question interactive loop). Subagent findings were merged into a single coherent package below; conflicts (option-only vs dedicated function) were resolved in **§Hybrid API (D-01)**.

</domain>

<decisions>
## Implementation Decisions

### 1) Hybrid public API (FACET-03 naming + single pipeline)

- **D-01 (`search_within_facet/4` — recommended shape):** Expose **`search_within_facet(schema_module, query_text, facet_bucket, opts)`** as the **canonical public** function (arity **4**). Third argument **`facet_bucket`** is a **positional** scope value (not buried only in `opts`) so call sites read like product language (“search *this* text *inside this bucket*”). Recommended **`facet_bucket` types:** **`{facet_attribute, value}`** where `facet_attribute` is a declared faceting atom and **`value`** is either a **scalar** (single bucket) or a **list** for **OR inside that attribute** (same list-as-OR encoding as `facet_filter:` today). Alternatives like a **one-key keyword** `[genre: "Sci-Fi"]` are acceptable **only if** validation enforces **exactly one** facet key — the tuple form is slightly clearer for `@spec` and error messages.

- **D-02 (Thin implementation, not a fork):** Implement **`search_within_facet/4`** (and **`search_within_facet!/4`** if bang parity is required) as a **thin delegate** into the **same** code path as **`search/3`**: merge the locked bucket into the effective **`facet_filter:`** (or the engine-faithful representation your `Query` layer already uses) **before** `Query.new/2` / payload build. **Do not** duplicate HTTP, telemetry, or option-validation stacks. This satisfies **FACET-03** naming and grep-ability while preserving **one NimbleOptions + Query pipeline** (addresses “second blessed HTTP path” footgun from pure duplicate APIs).

- **D-03 (Bang parity):** If **`search!/3`** exists for the primary path, ship **`search_within_facet!/4`** with the same **`ArgumentError` vs raised backend** semantics for consistency.

### 2) “Within bucket” semantics (Model A — AND composition)

- **D-04 (Single semantic story):** “**Within a facet bucket**” means: **the same document set** as running **`search/3`** with **`q`** plus **all** other constraints, **with an additional AND** that restricts hits to the bucket predicate. There is **no** separate engine “partition” or SQL **`GROUP BY`** intuition — counts and hits are always on the **intersection** of constraints.

- **D-05 (Composition with `filter:` and other `facet_filter:` keys):** **`filter:`** (non-facet predicates) **AND**s naturally with the bucket — keep **allowed** and **document** with one short example (e.g. category + price). **`facet_filter:`** entries on **other** attributes **AND** with the bucket the same way they do today across keys.

- **D-06 (Same-attribute conflict — reject, don’t merge):** If the caller passes **`facet_filter:`** containing the **same facet attribute** as the locked bucket, **raise `ArgumentError`** with a **stable prefix** and a message that tells them to **omit** the duplicate or use plain **`search/3`**. Silent merge or “precedence” rules are **high footgun** territory (double-filter → empty hits, support burden). Nested / **dotted hierarchical** attributes use the **same rule on the declared atom key** (one identifier everywhere, per Phase 36).

- **D-07 (Hierarchical keys):** Dotted facet atoms are **ordinary filterable attributes** — no implicit tree-walk or cross-level OR semantics in core. **Cross-level OR** and “subtree without listing levels” remain **app-composed `filter:`** / explicit expressions — same non-goals spirit as Phase 37.

- **D-08 (Disjunctive counts / Phase 37):** **`search_within_facet`** does **not** change disjunctive **count** mechanics. If an app wants Algolia-style distributions, it keeps using **Phase 37** multi-search / merge **recipes** — **never** implied by the scoped-search API.

### 3) Wire behavior, parity, operational honesty

- **D-09 (Opts parity):** **`opts`** accepts the **same subset** as **`search/3`** wherever semantically valid: **`facets`**, **`sort`**, **`page`**, **`filter:`**, **`facet_filter:`** (subject to D-06), etc. Reuse **`Scrypath.Options.validate_search_options/2`** (or equivalent) so NimbleOptions and error shapes stay identical.

- **D-10 (Single HTTP search default):** Default implementation is **one** `POST …/search` (same as today’s search). **Do not** silently fan out to multi-search for this entrypoint.

- **D-11 (Telemetry):** Emit metadata that distinguishes scoped searches from plain search — either a **dedicated** telemetry event name (e.g. **`[:scrypath, :search_within_facet]`**) or **shared** `[:scrypath, :search]` with **required extra keys** (`:scoped_facet`, bucket fingerprint). Pick one pattern and **document** it for operators.

- **D-12 (Tests):** Reuse **`Req.Test`** stub style from **`search/3`**; assert composed **`filter` / `facetFilters`** JSON matches the documented AND story.

### 4) FACET-04 — documentation and contracts

- **D-13 (Guide-first):** Put **prose semantics** (bucket = AND refinement; conflict rule D-06; double-filter **LiveView** footgun) in **`guides/faceted-search-with-phoenix-liveview.md`** only — **two** new stable **`##` headings**, e.g. **`## Searching within a facet selection`** and **`## Composing facet filters with scoped search`** (exact titles can be adjusted once, then locked in contract tests).

- **D-14 (`docs_contract_test.exs`):** Add **2–4** minimal anchors: both **heading strings** plus **1–2** durable lines (e.g. conflict / AND phrasing, **no REQ IDs** in published strings). Avoid locking long paragraphs or marketing copy.

- **D-15 (README / ExDoc):** **README:** at most **one** discoverability line + **link** (with optional fragment) into the guide — **no** full composition tables on the README (reduces dual-contract churn vs Phase 36/37 intent). **ExDoc:** extend **`Scrypath`** `@moduledoc` / **`search/3` `@doc`** with “see also” pointers; keep **`Scrypath.Search`** **`@moduledoc false`** unless the phase **deliberately** promotes it (default: **do not**).

- **D-16 (`mix verify.phase38`):** Add **`Mix.Tasks.Verify.Phase38`** mirroring **36/37**: focused test list including **`docs_contract_test.exs`** and **search/query/facet** tests touched by this feature; listing test **refutes `HEX_API_KEY`** like prior phases.

### Cross-cutting (vision alignment)

- **D-17:** **Least surprise** = Meilisearch truth in prose; **DX** = one validation surface + a **named** entry for catalog UX; **Operational honesty** = single-request default, explicit rejection instead of silent merge, telemetry that tells operators what ran.

### Claude's Discretion

- Exact **`facet_bucket`** Elixir type representation (tuple vs one-key keyword) after a quick pass for **`@spec`** clarity and `ArgumentError` messages.
- Whether **`search_within_facet!`** is strictly required on first ship or follows in the same PR if trivial.
- Exact telemetry event name vs extended metadata on `[:scrypath, :search]`.
- Final stable `##` heading strings for doc contracts (within the D-13 intent).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirements

- `.planning/ROADMAP.md` — Phase 38 goal, success criteria, FACET-03 / FACET-04
- `.planning/REQUIREMENTS.md` — **FACET-03**, **FACET-04**; traceability table

### Prior phase context (locked patterns)

- `.planning/phases/37-disjunctive-facet-counts/37-CONTEXT.md` — `facet_filter` OR/AND vocabulary, disjunctive counts ≠ single response, doc placement deferrals into Phase 38
- `.planning/phases/36-hierarchical-facets/36-CONTEXT.md` — dotted keys, `%Facets{}` shape, opt-in nested paths, “one identifier everywhere”
- `.planning/phases/20-faceted-search-liveview-guide/20-CONTEXT.md` — guide spine, test pyramid, URL/`handle_params` discipline

### Project principles

- `.planning/PROJECT.md` — Ecto-first, Meilisearch-first, operational honesty, DX priorities

### Code anchors (expected touchpoints)

- `lib/scrypath.ex` — public delegates
- `lib/scrypath/search.ex` — search pipeline, validation, telemetry
- `lib/scrypath/options.ex` — `facet_filter` / `facets` validation
- `lib/scrypath/meilisearch/query.ex` — `filter` + `facetFilters` composition
- `test/scrypath/docs_contract_test.exs` — contract anchors
- `lib/mix/tasks/verify.phase36.ex` / `lib/mix/tasks/verify.phase37.ex` — verify-task pattern

### External (Meilisearch)

- Meilisearch docs: **Search with facets** — interaction of `q`, `filter`, and facet refinements on hits and `facetDistribution`
- Meilisearch docs: **Filter expression reference** — AND/OR nesting

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **`Scrypath.search/3`** / **`Scrypath.Search.search/3`** — validation, `Query` construction, single-request path to extend via delegate.
- **`Scrypath.Options`** — `facet_filter` shapes, unknown facet errors, declared-attribute subset checks.
- **`Scrypath.Meilisearch.Query`** — existing AND composition between `filter` and facet refinements.
- **`Scrypath.Facets.Disjunctive`** — reference only for docs cross-links; not an implementation dependency of scoped text search.

### Established patterns

- **`ArgumentError`** with stable messages for invalid options; **`{:error, term()}`** for transport/engine failures on non-bang paths.
- **Phase 36/37** — small `docs_contract_test` anchors; **`mix verify.phaseNN`** focused slices.

### Integration points

- Phoenix / LiveView guides: URL param normalization to avoid **duplicate** bucket + `facet_filter` (document as app responsibility; library rejects same-key conflict).

</code_context>

<specifics>
## Specific Ideas

User asked for **research-backed, one-shot** recommendations emphasizing **DX**, **least surprise**, ecosystem lessons (Searchkick/Scout-style “one search composes,” Algolia/InstantSearch filter state, Meilisearch “same POST /search”), and **cohesion** with Phases **36–37**. Synthesis explicitly **rejects** silent merge of duplicate facet keys and **rejects** multi-search as the default for this API.

</specifics>

<deferred>
## Deferred Ideas

- **Pure option-only API** (`search/3` + `:within_facet` only) — deferred in favor of **named `search_within_facet/4`** for FACET-03 discoverability **plus** shared pipeline (hybrid D-01/D-02).
- **Public `Scrypath.Search` module docs** — deferred unless product explicitly widens the “golden path” surface.
- **Automatic disjunctive / multi-search “browse mode”** inside scoped search — out of scope; remains Phase 37 opt-in story.

### Reviewed Todos (not folded)

- None — `todo.match-phase` returned no matches for phase 38.

</deferred>

---

*Phase: 38-search-within-facet-docs*
*Context gathered: 2026-04-20*
