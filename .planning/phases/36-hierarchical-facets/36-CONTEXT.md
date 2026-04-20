# Phase 36: Hierarchical facets - Context

**Gathered:** 2026-04-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship **declarative nested facet paths** within what **Meilisearch** supports: settings and `filterableAttributes` stay truthful to the engine, **`Scrypath.search/3`** (and the same option vocabulary as today) returns **stable, documented** facet **keys** and **counts** for those paths, with **no regression** for existing **flat-only** facet schemas in CI. Satisfies **FACET-01** and roadmap success criteria. Out of scope: **disjunctive counts** (Phase 37 / FACET-02), **`search_within_facet/4`** and broad **FACET-04** README/anchor closure (Phase 38).

**Research note:** Four parallel research passes (declaration, `%Facets{}` shape, rollout, docs split) were synthesized into one coherent package below. User asked for a single recommended direction (minimal decision fatigue).

</domain>

<decisions>
## Implementation Decisions

### Meilisearch model (shared premise)

- **D-01:** Treat Meilisearch hierarchy as **a bundle of related filterable facet attributes**, not a separate server-side “tree type”. Typical pattern: **`categories.lvl0`**, **`categories.lvl1`**, … (dotted paths in `filterableAttributes`, `facets`, and `facetDistribution` keys), or **flat field names** (`categories_lvl0`, …) if documents are denormalized that way. `facetDistribution` stays **flat maps per attribute** (`value → count`); there is no nested JSON tree for hierarchy in the response.
- **D-02:** **AND across levels** for drill-down is the usual refinement model when using **multiple level attributes**; keep that as the **documented default mental model** for the guide (conjunctive across attributes, existing `facet_filter:` semantics per field).

### Declaration and settings

- **D-03 (Canonical wire shape):** The **canonical** declaration remains **`faceting: [attributes: [...]]`** where each entry is an **atom naming a Meilisearch filterable path** (either **no dots** for flat legacy fields, or **dotted paths** such as `:"categories.lvl0"` when nested document keys match Meilisearch’s filter grammar). This stays **1:1** with what appears in **`facets:`**, **`facet_filter:`**, settings merge (`Scrypath.Meilisearch.Settings`), and drift’s faceting projection—no second hidden namespace of “virtual” facet ids on the common path.
- **D-04 (Optional sugar):** Support **optional compile-time expansion** under the same `faceting:` keyword list, e.g. a **`hierarchy:`** (or similarly named) nested spec that **expands** into the explicit `attributes:` list using **fixed, documented naming** (default convention **`lvl0`…`lvl{N-1}`** under a declared map field, matching common **InstantSearch `HierarchicalMenu`** / Meilisearch blog patterns). Sugar **normalizes to** the same internal representation `__scrypath__(:faceting)` already uses—**no parallel declaration channel** (avoid the “declare in two places” footgun from other ecosystems).
- **D-05 (Validation):** Keep **`faceting.attributes ⊆ filterable:`** mandatory. **Reject string keys** for attribute names on the common path (preserve atom-first Scrypath ergonomics). For dotted atoms, validate **only documented patterns** after opt-in (see D-09): e.g. allow **Meilisearch-aligned dotted filterable paths**; do not accept arbitrary user-defined composite grammar in attribute names.
- **D-06 (Escape hatch):** Anything outside the supported declaration model (experimental `filterableAttributes` shapes, ad-hoc wildcards, server-version-specific hacks) stays under **`Scrypath.Meilisearch.*`** and **raw settings**, consistent with the existing **backend-native vs common path** boundary.

### `%SearchResult.Facets{}` and runtime API

- **D-07 (Struct shape):** **Do not change** the public `%Scrypath.SearchResult.Facets{}` shape: **`distribution: %{atom() => [%Bucket{}]}`, `stats`, `declared_order`**. Hierarchical facets appear as **additional keys** (or dotted-atom keys) in those maps—**not** a nested tree inside `%Facets{}`.
- **D-08 (`Bucket.value`):** Keep **`value` as wire literals** (primarily **`String.t()`** for path-style facet values). **Do not** require parsing `"A > B"` into segment structs in core for Phase 36; optional **pure helpers** may be a later convenience, not a contract requirement.
- **D-09 (One identifier everywhere):** The atom used in **`faceting.attributes`**, runtime **`facets:`**, **`facet_filter:`**, and **`result.facets.distribution[key]`** must be **identical**—extends Phase 20 **D-05** (code-first vocabulary, small wire↔Elixir mapping table in `@moduledoc` updated for dotted keys).

### Rollout, SemVer, and operator tooling

- **D-10 (Schema opt-in — default unchanged):** Keep Phase 20 behavior as the **default**: **`lib/scrypath/options.ex`** continues to **reject** facet attribute atoms whose names contain **`.`** **until** an explicit **`faceting:` opt-in** is present (boolean or enum—exact keyword left to implementation naming review, but must be **obvious in docs** and **grep-friendly** in schemas). **Rationale:** avoids “invalid → valid” surprises on upgrade, keeps FACET-01 SC3 honest, and gives one switch for tests/docs/drift. *Suggested keyword:* **`nested_paths: true`** (final name may differ if NimbleOptions or style prefers `nested_facet_paths:`—planner picks one and uses it consistently).
- **D-11 (SemVer messaging):** Ship the capability in a **minor** `0.x` bump (e.g. **0.3.x → 0.4.0**) with release notes: **no code changes** for apps that do not set the opt-in; hierarchical adopters enable the flag and add paths + documents + settings apply / reindex as required.
- **D-12 (Drift and CI):** Extend **faceting** drift normalization so hierarchical declarations compare cleanly to live Meilisearch **`faceting`** JSON. Keep **existing Phase 20 facet tests** as the **non-regression spine**; add **parallel** schemas/tests that enable **`nested_paths`** (or chosen flag). Prefer a **dedicated verify slice** or integration file for hierarchical end-to-end if the matrix would otherwise get noisy.

### Documentation and contract tests (Phase 36 only)

- **D-13 (Primary doc location):** Extend **`guides/faceted-search-with-phoenix-liveview.md`** with a dedicated section (e.g. **`## Hierarchical facets`** or equivalent **stable heading** chosen once). **Do not** add a second long-form guide unless the chapter would dominate the LiveView narrative—Phase 20 **D-01** (single primary extra) still applies.
- **D-14 (Guide contradiction):** **Must** revise the current appendix/mistake text that says **hierarchical dotted atoms in `faceting.attributes` are always wrong** (`guides/faceted-search-with-phoenix-liveview.md` ~wildcards / hierarchy). Replace with **v1.7 truth**: wildcards and unsupported patterns stay mistakes; **documented hierarchical paths + opt-in** are supported. **Ship this in the same release as the feature** so the guide never lies.
- **D-15 (`docs_contract_test.exs` for Phase 36):** Add a **small, stable** set of substrings (3–6) locking: the **section heading**, **one line on supported shape**, **one line on Meilisearch limits/version caveats**, **one line on distribution key semantics** for nested paths. **Do not** lock **`search_within_facet`**, README facet-depth bullets, or full composition tables here—those belong to **Phase 38 / FACET-04**. Follow existing hygiene: **no REQ IDs** in published markdown strings used as contracts.
- **D-16 (README / ExDoc):** **Defer** broad README “facet depth” discoverability and ExDoc entry-point churn to **Phase 38** (FACET-04 / roadmap SC4). **Exception:** if Phase 36 introduces a **new public module or function** adopters must discover immediately, allow **at most a one-line cross-link** in README or `@moduledoc`; Phase 38 still re-validates ordering and final copy.

### Cross-cutting product principles (locked)

- **D-17:** **Least surprise:** same mental model as Phase 20—**declare once**, select subsets at query time with **`facets:`**, filter with **`facet_filter:``**, Meilisearch engine semantics stay **visible** in docs (counts refined by active filters, etc.)—no pretending hierarchy is a magic tree inside the engine.
- **D-18:** **DX:** Prefer **explicit, Meilisearch-faithful** declarations + **optional sugar** over clever implicit defaults; prefer **compile-time** errors for misconfiguration over silent acceptance.
- **D-19:** **Pattern B support (documentation-only for Phase 36 core):** If adopters use a **single** filterable attribute whose **values** encode paths (`"Electronics > Audio"`), that can remain a **supported indexing convention** with **no extra core struct fields**—document as a recipe; first-class ergonomics in code/docs emphasize **Pattern A** (multi-attribute `lvlN`) for **clearest** `facet_filter:` + URL state alignment.

### Claude's Discretion

- Exact **`faceting:`** keyword for the opt-in (`nested_paths`, `nested_facet_paths`, `hierarchical_paths`, etc.) after a quick pass for consistency with **`NimbleOptions`** schema and existing keys.
- Exact grammar for **`hierarchy:`** sugar blocks (field names, max depth, optional naming strategy beyond default `lvlN`).
- Whether **`facetStats`** empty maps for non-numeric hierarchical keys omit keys vs return `%{}`—match existing **`%Facets{}`** behavior for flat facets.
- Submodule layout for expansion/validation helpers.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirements

- `.planning/ROADMAP.md` — Phase 36 goal, success criteria, canonical phase block
- `.planning/REQUIREMENTS.md` — **FACET-01**; traceability table (FACET-02..04 explicitly later phases)

### Prior phase and research

- `.planning/phases/20-faceted-search-liveview-guide/20-CONTEXT.md` — Faceting D-01..D-06, test pyramid, appendix rules (supersede hierarchy prohibition where noted above)
- `.planning/research/deep/FACETING.md` — Declaration philosophy, grammar boundaries, ecosystem survey

### Code anchors (implementation)

- `lib/scrypath/options.ex` — `validate_faceting_rules!/1` dotted-atom guard (default until opt-in)
- `lib/scrypath/meilisearch/settings.ex` — `merge_faceting_filterable_attributes/2`
- `lib/scrypath/search_result.ex` — `decode_facets/2`
- `lib/scrypath/search_result/facets.ex` — `%Facets{}` types
- `lib/scrypath/operator/index_contract_drift.ex` — faceting declared vs applied wire

### Docs and contracts

- `guides/faceted-search-with-phoenix-liveview.md` — Primary narrative; must gain hierarchical section + anti-pattern fix
- `test/scrypath/docs_contract_test.exs` — Extend stable substring list per D-15

### External (Meilisearch)

- Meilisearch docs: **Search with facets** — `facetDistribution` / `facetStats` behavior
- Meilisearch docs: **Filter expression reference** — dotted attribute names
- Meilisearch blog/spec: **Hierarchical facets guide** — `lvl0` / `lvl1` multi-attribute pattern and AND-across-levels UX

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`Scrypath.Meilisearch.Settings.merge_faceting_filterable_attributes/2`** — extend projection for nested path attributes without a parallel settings dialect.
- **`Scrypath.SearchResult.decode_facets/2`** — already orders by declared `facets:` list and stringifies atoms for JSON keys; extends naturally to dotted atoms.
- **`Scrypath.Operator.IndexContractDrift` faceting compare** — extend declared/applied wire normalization for hierarchical declarations.

### Established Patterns

- **Schema-declarative-first** — `filterable:` / `faceting:` / `__scrypath__(:faceting)` / `schema_faceting/1` (Phase 20).
- **Atom keys on the public facet surface**; **subset validation** `facets ⊆ declared`.

### Integration Points

- **`Scrypath.search/3`** options pipeline and **`Query`** construction for `facets:` / `facet_filter:`.
- **Guides + `docs_contract_test`** as the documentation truth chain.

</code_context>

<specifics>
## Specific Ideas

- Align **first-class** examples with **Meilisearch + InstantSearch** hierarchical menu interop (**per-level attributes**, dotted names).
- User requested **one-shot cohesive recommendations**; interactive gray-area Q&A was skipped in favor of research-synthesized locks above.

</specifics>

<deferred>
## Deferred Ideas

- **Disjunctive facet counts** — Phase 37 / FACET-02.
- **`search_within_facet/4`**, broad **FACET-04** README/ExDoc anchors — Phase 38.
- **Optional UI helpers** (parse path strings for tree widgets) — post–Phase 36 if demand is clear.

### Reviewed Todos (not folded)

- None (`todo.match-phase` returned no matches).

</deferred>

---

*Phase: 36-hierarchical-facets*
*Context gathered: 2026-04-19*
