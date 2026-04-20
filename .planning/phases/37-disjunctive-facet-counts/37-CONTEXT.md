# Phase 37: Disjunctive facet counts - Context

**Gathered:** 2026-04-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Satisfy **FACET-02**: a **clear, falsifiable contract** for **OR-style facet selection** (vs conjunctive filters), **how facet counts (`facetDistribution`) behave** under those filters, **documented edge cases** (empty selection, single bucket), and **one reference scenario** where operator-visible behavior matches docs and tests. Stays within v1.7 facet-depth intent: **Meilisearch-first honesty**, no multi-index federation, no `search_within_facet` surface (Phase 38).

**Process note:** User delegated gray areas **1–4** to deep parallel research + one-shot synthesis (subagents + maintainer merge). Interactive Q&A was skipped in favor of a single coherent package below.

</domain>

<decisions>
## Implementation Decisions

### 1) Facet count semantics (FACET-02 core)

- **D-01 (Single-search truth):** Treat **one** `Scrypath.search/3` call’s **`facetDistribution`** as **Meilisearch-native**: counts are computed on the **same document set** as hits after **`q` + all active constraints** (including facet refinements). This is **honest** and **cheap** to explain; it matches “stacked filters narrow the set” semantics in Meilisearch’s own faceting docs.
- **D-02 (Disjunctive counts ≠ single response):** **Do not** imply Algolia-helper-style “unrefined counts for the active OR group” from **one** search response. Meilisearch documents **disjunctive facet counts** as a **client / multi-search** pattern (main query with all filters + auxiliary queries that **drop** each disjunctive group’s filters for that group’s distribution, often `limit: 0`, then merge). The library **must** say this explicitly in prose so adopters do not blame Scrypath for engine behavior.
- **D-03 (Default product shape — B over A-alone):** Ship **(B)** as the default FACET-02 story: **document** single-search semantics **and** ship a **small, pure, testable helper and/or guide recipe** (building payloads compatible with existing **`search_many/2`** or raw multi-search) to **merge** `facetDistribution` with a **documented merge rule** aligned with Meilisearch’s disjunctive-facets guide (each facet group appears in exactly one auxiliary query). **(A)** alone (engine counts only, no recipe) is **insufficient** for least surprise given ecommerce-style expectations.
- **D-04 (Optional C — gated):** Any **automatic** multi-query wrapper **(C)** is **opt-in only**, with **explicit** naming (e.g. option or dedicated function), **observable** query fan-out (count or list of stripped filter groups), and **no** pretense of a single physical search when multiple ran. Prefer **telemetry-friendly** boundaries if implemented.
- **D-05 (Wire note):** Today’s encoder emits **`facetFilters`** for facet refinements (`lib/scrypath/meilisearch/query.ex`); tests lock OR-within-field as nested arrays. **Semantics** (AND across facet keys, OR within a plain list value) are the **stable contract**; **exact JSON key** for the Meilisearch version line Scrypath supports is an **implementation / drift** concern—verify against supported engine docs during execution, preserving behavior if the engine migrates to unified `filter` encoding.

### 2) API / vocabulary clarity

- **D-06 (Keep `facet_filter` OR encoding):** Retain **`facet_filter: [field: v]`** scalar and **`facet_filter: [field: [v1, v2]]`** plain list as **OR within `field`**, **AND across distinct keys**—already idiomatic Elixir, matches NimbleOptions-style validation (`Keyword.keyword?/1` disambiguates **ranges** from **OR lists**). **Do not** add a duplicate “disjunctive” flag that must stay in sync **only** for filter encoding.
- **D-07 (Reserve “disjunctive” naming for counts):** Introduce **new** public names only when implementing **multi-search count behavior** (e.g. `:disjunctive_facet_counts`, `:facet_count_mode`, or a dedicated function)—aligned with Algolia / Meilisearch vocabulary where **“disjunctive”** refers to **count UX**, not OR syntax.
- **D-08 (Backward compatibility):** Treat documented list-as-OR as a **compatibility guarantee** once shipped in FACET-02 docs + tests. If **AND-within-field** is ever needed, use an **explicit** wrapper (never overload bare lists).
- **D-09 (Errors and strictness):** Keep **structured** validation → **`ArgumentError`** with stable prefixes at the boundary; document one canonical **URL param encoding** for repeated facet values in the LiveView story (avoid comma ambiguity).

### 3) Reference scenario & documentation placement

- **D-10 (Single primary guide):** Extend **`guides/faceted-search-with-phoenix-liveview.md`** only—no second long-form facet guide. Add a **first-class `##` section** in the **main flow** for **disjunctive semantics** (definition: OR-within-key, AND-across-keys; what happens to **counts** on one vs multi-search). Place **wrong mental models** (SQL `GROUP BY` intuition, “counts ignore my OR group”) in the **existing banded anti-pattern appendix** (Meilisearch band).
- **D-11 (Reference scenario):** Lock one scripted scenario: **“Genre OR + year AND on the movies catalog”** — states A–D: no facets → single genre → second genre (OR) → add year conjunctive; URL via `handle_params` / `push_patch` matches **`facet_filter`** shape; expected **hit set** and **count behavior** described in **one falsifiable paragraph + small table** (“given filter F, distribution for attribute X means …”).
- **D-12 (`docs_contract_test.exs` for Phase 37):** Add a **small** set of stable substrings (**3–5**): new **section heading**, **one line** on OR-within-field / AND-across-fields, **one line** on single-search vs multi-search counts. **No REQ IDs** in published strings. **Defer** README ordering, `search_within_facet` naming, and broad FACET-04 anchors to **Phase 38**.

### 4) Hierarchical (Phase 36) × disjunctive interaction

- **D-13 (FACET-02 scope lock):** Phase 37 **proves** disjunctive **count contract + optional query planner** for **flat declared facet attributes** (including dotted atoms as **keys**, same as Phase 36). **Do not** productize **hierarchical multi-select OR** (arbitrary branches, parent rollup guarantees) as a core guarantee.
- **D-14 (Documented caveats):** Hierarchical keys remain **filterable attributes**; **OR on a single level attribute** (e.g. two `lvl2` values) may be a **documented manual** pattern. **Cross-level OR** (`lvl0` OR mixed `lvl1` branches) is **unsupported / undefined** for any **helper** the phase ships—call out **empty-hit** and **misleading tree** risks; point advanced apps to explicit filter construction + their own UX state machine.
- **D-15 (Explicit non-goals):** No InstantSearch-compatible hierarchical+disjunctive state machine in core; no automatic boolean DAG planner; no multi-index coordinated disjunctive counts; no promise of parent counts for arbitrary multi-branch OR without app-side indexing and extra queries.

### Cross-cutting (cohesion with PROJECT / prior phases)

- **D-16:** **Least surprise** = engine semantics visible in docs; **DX** = keywords + explicit opt-in for expensive paths; **Operational honesty** = query fan-out visible for multi-search helpers.
- **D-17:** Reuse **Phase 20** test pyramid discipline: **unit** (payload encoding, merge pure functions), **Req.Test / HTTP fixtures** for search bodies, **optional** live Meilisearch tagged tests if needed for `facetDistribution` truth.
- **D-18:** Stay aligned with **Phase 36**: **no change** to **`%SearchResult.Facets{}`** shape; disjunctive merge only affects **how** distributions are assembled **before** or **after** decode—document which layer applies.

### Claude's Discretion

- Exact helper **module/function** names and whether they live beside `search_many` vs `Scrypath.Facets.*`.
- Whether Phase 37 ships **only** recipe + pure functions vs **also** one thin opt-in orchestration function.
- Exact `docs_contract_test` substring set (within 3–5 budget).
- Telemetry event names for multi-search helper (if implemented).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirements

- `.planning/ROADMAP.md` — Phase 37 goal, success criteria, FACET-02
- `.planning/REQUIREMENTS.md` — **FACET-02** traceability

### Prior phase context

- `.planning/phases/36-hierarchical-facets/36-CONTEXT.md` — Hierarchical keys, AND-across-levels mental model, `%Facets{}` shape, opt-in nested paths
- `.planning/phases/20-faceted-search-liveview-guide/20-CONTEXT.md` — Facet guide spine, test pyramid, appendix discipline, honesty on counts

### Code anchors

- `lib/scrypath/meilisearch/query.ex` — `facetFilters` encoding, OR-within-field nesting
- `lib/scrypath/options.ex` — `facet_filter` validation
- `lib/scrypath/search_result.ex` / `lib/scrypath/search_result/facets.ex` — decode and `%Facets{}`
- `test/scrypath/meilisearch/query_test.exs` — locked payload shapes (incl. disjunctive-within-field test)

### Documentation

- `guides/faceted-search-with-phoenix-liveview.md` — primary narrative + new disjunctive section + appendix entries
- `test/scrypath/docs_contract_test.exs` — minimal new anchors (Phase 37)

### External (Meilisearch)

- Meilisearch: **Search and filter together** — facet distribution intersection with filters
- Meilisearch: **Build disjunctive facets** — multi-search pattern, `limit: 0`, merge strategy
- Meilisearch: **Filter expression reference** — `AND` / `OR`, nesting limits, parentheses

### External (ecosystem patterns — research only)

- Algolia / InstantSearch faceting + hierarchical menu docs (disjunctive vs hierarchical limitations)
- Searchkick / Scout patterns (implicit OR footguns) — contrast with Scrypath explicit encoding

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **`Scrypath.Meilisearch.Query.translate_facet_filter/1`** — already produces nested `facetFilters` for OR-within-field; extend docs/tests around **counts**, not basic encoding.
- **`search_many/2`** (existing multi-index path) — natural batching primitive for recipes/helpers that mirror Meilisearch multi-search semantics where applicable.
- **`DocsContractTest`** — Phase 36 pattern for minimal stable guide substrings.

### Established patterns

- **Keyword options** on `search/3`, **raise** on invalid options, **Req.Test** for HTTP bodies.
- **Declare once** (`faceting:` / `filterable:`) with runtime **`facets:` / `facet_filter:`** subset validation.

### Integration points

- Search options pipeline → Meilisearch payload → `SearchResult` decode.
- LiveView guide examples for URL **`handle_params`** ↔ `facet_filter` parity.

</code_context>

<specifics>
## Specific Ideas

- Reference scenario title: **“Genre OR + year AND on the movies catalog.”**
- User asked for **research-heavy, one-shot** recommendations; subagents covered Meilisearch disjunctive docs, Elixir/NimbleOptions idioms, Algolia/InstantSearch footguns, and doc placement.

</specifics>

<deferred>
## Deferred Ideas

- **`search_within_facet/4`**, broad **FACET-04** README/ExDoc discoverability refresh — **Phase 38**.
- **Hierarchical multi-select + disjunctive parent counts** as a **productized** core feature — deferred; document as app/index concern if needed.
- **Automatic migration** from `facetFilters` key to engine-preferred `filter` encoding — only if/when required for supported Meilisearch versions; preserve semantic contract.

### Reviewed Todos (not folded)

- None (`todo.match-phase` returned no matches for phase 37).

</deferred>

---

*Phase: 37-disjunctive-facet-counts*
*Context gathered: 2026-04-20*
