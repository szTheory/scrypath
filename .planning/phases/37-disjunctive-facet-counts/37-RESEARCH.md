# Phase 37 — Technical research: Disjunctive facet counts (FACET-02)

**Question:** What must implementers know to plan **OR-within-field** facet selection, **single-search `facetDistribution` truth**, and **Meilisearch-style disjunctive count UX** (multi-search merge)?

**Sources:** `37-CONTEXT.md`, Meilisearch docs, current `lib/scrypath/meilisearch/query.ex`, `search_many/2`, `SearchResult` decode.

---

## 1. Meilisearch engine semantics (single search)

- **`facetDistribution`** is computed on the **same filtered hit set** as the search hits: active `q`, `filter`, and **`facetFilters`** (or unified `filter` on newer lines) all **intersect** ([Search parameters — faceting](https://www.meilisearch.com/docs/reference/api/search)).
- Therefore, with **genre = Action OR genre = Drama** encoded as an OR group, counts for **genre** in that **single** response reflect the **narrowed** set (both buckets can be non-zero only within documents matching the OR). This is **honest** but **not** the Algolia-style “disjunctive” count UX where the active OR group’s list shows counts **as if** that group were not applied.
- **Implication (CONTEXT D-01, D-02):** Scrypath must **document** that one `search/3` call returns **engine-native** counts; it must **not** document behavior that implies unrefined counts for the active OR group from a single response.

## 2. Meilisearch disjunctive facet pattern (multi-search)

- Official guide: [Build disjunctive facets](https://www.meilisearch.com/docs/capabilities/filtering_sorting_faceting/advanced/disjunctive_facets) — pattern is **client-side** using **multi-search** (or multiple `/search` calls):
  1. **Main query:** all refinements applied → hits + `facetDistribution` for **non-disjunctive** facet fields (and/or all fields if you merge carefully).
  2. **One auxiliary query per disjunctive facet group:** **drop** that group’s facet filters, keep others; often **`hitsPerPage: 0`** / `limit: 0` to avoid duplicate hit payloads; read **`facetDistribution`** for the disjunctive field(s) from that response.
  3. **Merge** distributions client-side: for each disjunctive field **F**, take **`facetDistribution[F]`** from the auxiliary query that removed **F**’s filters; keep other fields’ distributions from the **main** query (or from dedicated auxiliaries if multiple OR groups — each group appears in **exactly one** auxiliary omitting that group’s filters per guide table).

- **Multi-search API:** [Perform a multi-search](https://www.meilisearch.com/docs/reference/api/multi_search) — Scrypath already exposes **`Scrypath.search_many/2`** with per-index tuples and shared opts (`lib/scrypath/search.ex`, `lib/scrypath/meilisearch.ex`).

## 3. Current Scrypath wiring (encoding + decode)

- **`Scrypath.Meilisearch.Query.translate_facet_filter/1`** (`lib/scrypath/meilisearch/query.ex`):
  - Plain list value under a field → **nested array** inside `facetFilters` → **OR within that field** (see `test/scrypath/meilisearch/query_test.exs` test *"disjunctive within one facet field and conjunctive with another (FACET-04)"* — note test name is legacy; FACET-02 is the REQ for **count contract**).
  - **AND across** distinct facet keys via **outer list** of facet predicates.
- **`Scrypath.Options`** validates `facet_filter` keys against declared faceting attributes (`lib/scrypath/options.ex`).
- **`Scrypath.SearchResult`** / **`Scrypath.SearchResult.Facets`** decode `facetDistribution` / `facetStats` into **`%Facets{distribution: %{atom => [%Bucket{}]}, ...}`** — **no change** to struct shape per CONTEXT D-18; disjunctive merge is **before or after** decode at planner/executor discretion (pure merge on wire maps is simplest for a helper used next to raw multi-search JSON).

## 4. Edge cases (empty selection, single bucket)

- **Empty `facet_filter` for a field:** no refinement on that field → single-search distribution is the **full constrained set** for other active filters; auxiliaries that “drop” an absent group are a **no-op** pattern — recipe should branch on “user selected any value for OR-group G”.
- **Single selected bucket:** OR group collapses to one value; single-search and merged disjunctive strategies **converge** for that field’s UX; tests should still lock **conjunctive vs OR** encoding via existing `query_test.exs` plus new **merge** tests.
- **Hierarchical × OR (CONTEXT D-13–D-15):** Phase 37 **does not** guarantee hierarchical multi-branch OR in core helpers; document **caveats** in guide only.

## 5. Documentation and contract-test placement

- **Single primary guide:** `guides/faceted-search-with-phoenix-liveview.md` — add **`##`** section (CONTEXT D-10) in main flow: definition, single-search counts, multi-search recipe, wrong mental models → existing Meilisearch **anti-pattern appendix**.
- **`test/scrypath/docs_contract_test.exs`:** add **3–5** stable substrings (no `FACET-NN` in published text per hygiene test); follow Phase 36 pattern (`assert_contains_all` on guide).
- **`mix verify.phase37`:** mirror `lib/mix/tasks/verify.phase36.ex` — focused paths: new disjunctive tests, `query_test.exs`, `docs_contract_test.exs`, optionally `search_test.exs` if touched.

## 6. Optional opt-in orchestration (CONTEXT D-04)

- Any **automatic** multi-query helper must be **explicitly named**, **opt-in**, and expose **query fan-out** (count or list of stripped groups) for operational honesty — consider **`:telemetry`** event in a follow-on task if implemented in this phase.

---

## Validation Architecture

> Nyquist / execution sampling for Phase 37.

**Stack:** Elixir 1.17+, ExUnit, `mix test`.

**Commands:**

| Layer | Command | When |
|-------|---------|------|
| Quick | `mix compile --warnings-as-errors` | After new modules / `Scrypath` delegations |
| Focused | `mix test test/scrypath/facets/disjunctive_test.exs` | After pure merge helper edits |
| Encoding regression | `mix test test/scrypath/meilisearch/query_test.exs` | If `query.ex` or facet encoding touched |
| Docs | `mix test test/scrypath/docs_contract_test.exs` | After guide + contract strings |
| Gate | `mix verify.phase37` | After each plan wave; before handoff |

**Sampling expectations:**

- Every behavioral task maps to **`mix test`** (or compile-only only when truly impossible — not expected here).
- Merge logic: **unit tests only** are sufficient for Nyquist Dimension 8; live Meilisearch optional tagged test only if executor adds one with clear `@tag`.

**Dimension 8:** Plans must reference the table above in `<verification>` blocks.

---

## RESEARCH COMPLETE

Research artifact is sufficient to plan Phase 37 with locked CONTEXT decisions D-01–D-18 and ROADMAP success criteria.
