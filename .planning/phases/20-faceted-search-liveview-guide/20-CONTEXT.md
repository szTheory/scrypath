# Phase 20: Faceted Search + LiveView Guide - Context

**Gathered:** 2026-04-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship declarative `faceting:` on schemas (compile-time alignment with `filterable:`), runtime `facets:` / `facet_filter:` on `Scrypath.search/3`, a `%Scrypath.SearchResult.Facets{}` sub-struct with ordered distributions and default-on numeric stats, reindex-time derivation of Meilisearch `filterableAttributes` object form with `features: ["facetSearch"]` for declared facet attributes (zero user-facing Meilisearch config), and **`guides/faceted-search-with-phoenix-liveview.md`** — movies-by-genre-year-rating-director worked example, four canonical UI patterns, 7+ entry anti-pattern appendix. Narrow filter grammar unchanged; no backend-native shapes on the common public surface. Additive over `scrypath 0.3.0`. See FACET-01..10 and roadmap success criteria.

</domain>

<decisions>
## Implementation Decisions

### D-01 — Guide packaging (documentation-first spine)

- **Primary artifact:** One excellent **`guides/faceted-search-with-phoenix-liveview.md`** wired through `mix.exs` ExDoc `:extras`, with copy-pasteable HEEx + LiveView handlers. Matches ecosystem idioms (Ecto/Oban/Req-style: HexDocs narrative + snippets, not a second product).
- **Phase 20 does not block** on a runnable `examples/` Phoenix app, a **`mix scrypath.gen.*` generator**, or a second lockfile/CI matrix. Generators and full example apps are **deferred** until the facet public API has shipped and support volume or maintainer capacity justifies the ongoing tax (~0.25–0.5 FTE churn around Phoenix/Elixir majors per runnable app).
- **Optional follow-on (post–Phase 20 or parallel if cheap):** bounded hybrid only if needed — e.g. **compile-check** of critical snippets via existing `PhoenixExamplesTest`-style fixtures, or a **minimal** `examples/faceted_liveview` with pinned versions and CI scoped to weekly/main-only. Never two unenforced sources of truth without a sync mechanism.

**Cross-language rationale:** Searchkick/Scout teach model-centric DX well but hide operational reality; Scrypath doubles down on **explicit** index semantics in prose. Meilisearch official examples are often script-thin — the guide bridges to **full Phoenix**, which is exactly Scrypath’s wedge, without owning a second deployable product in v1.3.

### D-02 — URL sync in the worked LiveView example (main path)

- The **primary** worked example **MUST** use **URL as serialized search + facet state**: `handle_params/3` + `push_patch/2` and/or `<.link patch={...}>`, aligned with Phoenix LiveView **live navigation** idioms (patchable query in `handle_params`, stable LiveView lifecycle context in `mount`).
- **Single entry point** for param-driven search: normalize raw query params once; avoid loading the same facet/query state from both `mount/3` and `handle_params/3` in conflicting ways (stale assigns, double fetch). Prefer the official split: **resource scope / static assigns in `mount`**, **query + facets + page in `handle_params`**.
- **Progressive disclosure:** A **short, clearly labeled** sidebar or subsection may show a **mount + `handle_event` only** variant with the explicit disclaimer that **refresh and deep links do not preserve facet state** — not the default story.

**Rationale:** Bookmarks, shareable URLs, and refresh-correctness match production Phoenix search UX and Scrypath’s **operational honesty** for apps built on the library. Footguns (double fetch, `""` vs missing keys, repeated query keys for multi-select) are addressed in-guide with one normalization module and blank-param rejection — not by dropping URL sync.

### D-03 — Test pyramid (library repo, not a host app)

- **Bulk:** Pure **unit tests** — schema/`faceting:` compile enforcement, option validation, `facet_filter:` → internal query representation, JSON fixture → `%SearchResult.Facets{}` decoding, ordering and empty cases.
- **Integration-shaped (default CI):** **`Req.Test`** (or existing fake-backend **`SearchTest`**) asserting **HTTP bodies and response decoding** for `facets`, `facetFilter`, and facet distribution/stats JSON — deterministic, no Docker on every PR.
- **Documentation truth:** Extend **`DocsContractTest`** for the new guide path (required sections, stable public API strings, cross-links). Extend **`PhoenixExamplesTest`** (or equivalent) so **critical HEEx + assigns compile** in `test/support` — not full browser LiveView tests.
- **Optional upper layer:** Tagged **live Meilisearch** tests (existing project pattern) for wire compatibility on upgrades — not mandatory for every push.

**Explicit non-goals for default CI:** Full LiveView feature tests, long HEEx in doctests, requiring Meilisearch on every PR for the guide narrative.

### D-04 — Anti-pattern appendix (structure, order, tone)

- **Single appendix, three labeled bands:** `API` | `Meilisearch` | `UI` — one index, grep-friendly titles; no ambiguous entries straddling two bands without stating both.
- **Ordering:** (1) **API misuse** first (fastest to diagnose, ties to FACET compile/runtime validation), (2) **Meilisearch semantics** (why counts/stats behave as they do), (3) **UI / LiveView** (state sync, loading, a11y — not visual taste).
- **Per-entry template:** **Title** → **Layer** → **The mistake** (short) → **User-visible consequence** (one line, UI-SPEC requirement) → **Why** (1–2 sentences, tie to Scrypath contract or engine rule) → **Do instead** (canonical API or guide pattern) → **See also** (main section + `Scrypath.Meilisearch.*` escape hatch when applicable).
- **Cardinality:** **7+ entries**; default mix **~3 API, ~2 Meilisearch, ~2–3 UI**, adjusted if telemetry/issue patterns say otherwise.
- **FACET-10 coherence:** Appendix entries **must not** recommend wildcards, raw string DSL in `facet_filter:`, hierarchical facet declarations, or other locked non-goals. Workarounds that need backend-native filters stay **explicitly** under **`Scrypath.Meilisearch.*`** and outside the supported common contract.

**Tone model:** Phoenix Security / Stripe-style — calm, specific, falsifiable; honest tradeoffs (e.g. disjunctive counts) with pointer to **`search_many`** or second-query recipe where v1.3 deliberately does not hide engine behavior.

### D-05 — Docs vs public API naming (code-first, wire-explicit)

- **Single source of truth for user-facing names:** **`defstruct` / `@type` / public functions in `lib/`** that ship in the Hex release. The guide’s stable sections **reference those real modules** (`%Scrypath.SearchResult.Facets{}`, field names, option keys).
- **Wire vocabulary vs Elixir vocabulary:** Meilisearch returns **`facetDistribution`**, **`facetStats`** with **`min` / `max`** aggregates. **`gte` / `lte`** belong to **Scrypath’s filter/range model** (and UI copy for sliders), **not** as aliases for Meilisearch stat field names. A **short mapping table** in `%Facets{}` `@moduledoc` (wire key → Elixir field) is required so guide, ExDoc, and `Req.Test` fixtures stay aligned.
- **Facet search vs facet distribution:** Do not overload one struct for Meilisearch **facet-search API** responses vs **search** `facetDistribution` — v1.3 guide covers **assign-only “search within facet”** per UI-SPEC; if future API exposes facet-search hits, use a **distinct type or clearly named subfield**, not ambiguous `values`.
- **Before implementation exists:** Naming debates live in **phase/research artifacts**; the **published guide must not** present unshipped `Scrypath.*` modules as final without an explicit **“proposed / lands in same release”** banner, or users perceive docs drift (Searchkick-class “magic until it breaks” footgun avoided).

**Stripe/Algolia lesson:** Spec/codegen monorepos enforce alignment at scale; at Scrypath scale, **typed decoders + fixture JSON + ExDoc from real modules** achieve the same invariant cheaply.

### D-06 — Cohesion across decisions (vision check)

- **Documentation-first + additive releases:** D-01 + D-05 keep shipping weight in one versioned guide and one Hex artifact, while tests (D-03) enforce truth.
- **Least surprise for Phoenix devs:** D-02 teaches the navigation model they will use in production; D-04 explains when counts “lie” without blaming the wrong layer.
- **Ecto-first, Meilisearch-first:** Core behavior and tests stay in **`lib/scrypath`** and existing patterns (`options.ex`, `Meilisearch` client, `SearchTest`, `Req.Test`); LiveView remains **documentation and compile-checked fixtures**, not a second framework inside the repo (D-01, D-03).
- **Phase 19 handoff:** Facet-related **settings translation** for `filterableAttributes` / `facetSearch` features reuses the **normalization and verification discipline** established in `Scrypath.Meilisearch.Settings` — no parallel ad-hoc translation layer.

### Claude's Discretion

- Exact query-string encoding for multi-value facets (repeated keys vs delimiter) as long as one convention is documented and parsed in one place.
- Submodule/file layout for facet validation vs search vs decode helpers.
- Exact `Req.Test` fixture filenames and golden JSON edge cases beyond the happy path.
- Minor HEEx structure in the guide (still within UI-SPEC roles, color, spacing, and copy).
- Telemetry event names/metadata for facet validation failures (match existing `[:scrypath, ...]` patterns).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap and requirements

- `.planning/ROADMAP.md` — Phase 20 goal, success criteria, dependencies (Phase 18, 19)
- `.planning/REQUIREMENTS.md` — FACET-01 through FACET-10 (faceting declaration, `facets:` / `facet_filter:`, `%SearchResult.Facets{}`, guide FACET-08, composition FACET-09, non-goals FACET-10)
- `.planning/PROJECT.md` — Core value, constraints, v1.3 milestone framing

### Research and prior phase

- `.planning/research/deep/FACETING.md` — Facet grammar, declaration model, Meilisearch mapping, escape hatches
- `.planning/research/SUMMARY.md` — Milestone ordering (Phase 19 translation pattern → Phase 20 facets)
- `.planning/phases/19-relevance-tuning/19-CONTEXT.md` — Settings normalization, `translate_settings/1`, verify/drift patterns to reuse for facet-related index settings

### UI contract (approved)

- `.planning/phases/20-faceted-search-liveview-guide/20-UI-SPEC.md` — Locked visual, copy, layout, four UI patterns, search-within-facet assign-only rule, loading/URL recommendations, anti-pattern consequence line requirement

### Existing guide tone and code anchors

- `guides/phoenix-liveview.md` — Context vs LiveView boundary, `handle_params` example
- `lib/scrypath/meilisearch.ex` — Public search surface documentation baseline
- `test/scrypath/docs_contract_test.exs` — Docs contract pattern to extend
- `test/support/docs/phoenix_examples_test.exs` — Compilable Phoenix snippet pattern
- `test/scrypath/search_test.exs` — Fake-backend search tests to extend for facet options

### External (wire semantics)

- Meilisearch documentation — faceting, `facetDistribution` / `facetStats` on search responses; facet search as a distinct API where relevant to “search within facet” non-scope

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`Scrypath.Meilisearch.Settings`** (Phase 19) — Pattern for declarative → wire translation, meta-key stripping, verification hooks; extend for facet-related `filterableAttributes` object form rather than new ad-hoc module.
- **`test/scrypath/search_test.exs`** — Fake backend for `Scrypath.search/3`; extend for `facets:` / `facet_filter:` argument expectations.
- **`Req.Test`** usage in existing `meilisearch_*_test.exs` — Assert JSON bodies for search requests.
- **`DocsContractTest` / `PhoenixExamplesTest`** — Enforce guide presence and compilable Phoenix-oriented snippets.

### Established Patterns

- **NimbleOptions**-style validation on `search/3` opts; explicit `{:error, tuple}` for unknown facets (FACET-03) — never silent empty facet maps.
- **Additive structs** — new `%Facets{}` on `%SearchResult{}` outside `@enforce_keys` with benign default (per v1.3 additive policy).

### Integration Points

- Schema compiler (`use Scrypath`) for `faceting:` + `filterable:` cross-check (FACET-02).
- Reindex pipeline / `Scrypath.Meilisearch.Settings` for index settings derivation (FACET-07).
- Search orchestration and response normalization in the existing search path (not a parallel public entrypoint).

</code_context>

<specifics>
## Specific Ideas

- User requested **research-backed defaults for all discuss gray areas** in one pass: snippets-first guide with URL-sync main path, test pyramid (unit + Req.Test + doc contracts + Phoenix fixture compile-check), structured anti-pattern appendix, code-first public names with explicit wire mapping table, no Phase-20 blocker on runnable example app or generator.

</specifics>

<deferred>
## Deferred Ideas

- **`examples/faceted_liveview` runnable app** — optional after Phase 20 if CI/support burden is acceptable; pin Phoenix/Scrypath versions.
- **`mix scrypath.gen.facets_liveview` (or similar)** — defer until public facet API is stable; high support surface for wrong defaults.
- **Meilisearch facet-search API as first-class Scrypath surface** — deferred per UI-SPEC and FACET backlog (`FACET-V14-03` class concerns); v1.3 assign-filter only in guide.

### Reviewed Todos (not folded)

- None — `gsd-sdk query todo.match-phase` unavailable in current CLI; no automated todo fold this session.

</deferred>

---

*Phase: 20-faceted-search-liveview-guide*
*Context gathered: 2026-04-17*
