# Phase 21: Multi-Index Search - Context

**Gathered:** 2026-04-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship `Scrypath.search_many/2` as a Meilisearch-first federated query across N schemas: declaration-ordered results, per-schema validation and `%SearchResult{}` parity (including facets via `facetsByIndex`, never `mergeFacets`), concurrent hydration with explicit timeouts, cardinality rails, `%Scrypath.MultiSearchResult{}` with partial-failure envelope, optional `Backend.search_many/3` with sequential fallback, telemetry, and **`guides/multi-index-search.md`** (4-schema LiveView dashboard + cross-links). Additive over `scrypath 0.3.0`. Requirements: MULTI-01..13 and roadmap Phase 21 success criteria.

</domain>

<decisions>
## Implementation Decisions

### D-01 — Guide narrative spine (dashboard-first + explicit omnibox recipe)

- **Primary story:** Federated **multi-section dashboard** — each tuple is an independent sub-query (possibly different `text`, `filter:`, `page:`, `facets:`). This matches Meilisearch federation, `%MultiSearchResult.ordered`, and Scrypath’s “schemas stay decoupled” posture.
- **Secondary recipe (clearly labeled):** “Same `q` everywhere” global search bar — one assign / one URL param threaded into each tuple’s `text`. Framed as a **special case of the tuple API**, not a second verb or registry. Call out explicitly: **ranking scores are not comparable across schemas**; facets remain **per schema** (no merged cross-schema facet UX implied).
- **LiveView / URL:** Reuse Phase 20 D-02: **`handle_params/3` owns query + facet state**, `mount/3` for static context, **single normalization path** to build `[{schema, text, opts}]`, **`push_patch`** for same LiveView. For mixed dashboards, use **namespaced URL keys** (e.g. `post_q`, `user_q` or a documented param encoding) — never one overloaded param meaning different things per section.
- **Progressive disclosure:** Optional short **event-only** variant allowed with the same disclaimer as Phase 20 (refresh/deep links).
- **Avoid in docs:** implying unified merged hits, cross-schema relevance normalization, or `search_many("q", …)`-style shared-only text (rejected in deep research); avoid shared `filter:` in shared opts without the validation fan-out warning.

### D-02 — `search_many!/2` (parity with `search!/3`)

- **Ship `search_many!/2` in Phase 21** as a thin mirror of `search!/3`: unwrap `{:ok, %MultiSearchResult{}}`; on `{:error, reason}` raise **`RuntimeError`** with `inspect(reason)` (same family as `search!/3` for transport/backend errors — document that **`ArgumentError`** remains the domain of invalid options only where `search/3` raises before tags).
- **Contract (critical):** `!` **does not** mean “every sub-query succeeded.” It only means `search_many/2` returned **`{:ok, _}`** vs **`{:error, _}`**. Per-schema problems stay in **`failures:`** on the returned struct — **never** raise solely because `failures != []`.
- **Doc guidance:** Prefer `search_many/2` in production LiveView for explicit `case`/degradation; position `search_many!/2` for scripts, tests, and “abort the request on invalid call or total failure” contexts.
- **Deferred (not v1.3 unless demand is proven):** a separate **`search_many_strict!/2`** (or opt) that raises when `failures != []` — honest naming if ever added; avoids overloading `!` semantics.

### D-03 — Duplicate schema modules in one call

- **Allow** the same schema module to appear **more than once** in the entries list (e.g. two Post panels, different filters). Matches tuple-list rationale in deep research, Meilisearch/ES multi-search **positional** models, and avoids the Keyword duplicate-key collapse problem.
- **`ordered` is authoritative** for rendering and for “which slot failed” when matching failures to UI.
- **`by_schema` remains `ordered |> Enum.into(%{})`** so **MULTI-05 stays literally true**; document that when duplicates exist, **`by_schema[schema]` is last-wins** — callers who need both panels must use **`ordered`** (or `Enum.filter/ordered`).
- **Guide:** Short **“Duplicate schema”** subsection mandating iteration over `ordered` for multi-section same-schema layouts.
- **Optional later (only if field evidence demands it):** `strict_unique_schemas?: true` or `{:error, {:duplicate_schema, mod}}` — **not** default in v1.3; would fight “tuple list is lossless vs `search/3`” unless explicitly chosen later.

### D-04 — `federation` metadata on `%MultiSearchResult{}`

- **Shape:** Expose **`federation`** as a **Scrypath-owned** value — preferably **`%Scrypath.MultiSearchResult.Federation{}`** (or fixed-field struct) with **snake_case** fields such as `estimated_total_hits`, `processing_time_ms`, `limit`, `offset` (exact set finalized against pinned Meilisearch response in implementation). **No raw Meilisearch JSON / camelCase** on the common public surface (Phase 20 doc contract discipline).
- **Versioning:** New engine-only fields are ignored until promoted into the struct (or an explicitly **unstable** `extensions:` bag if ever needed). Semver owned by Scrypath fields, not forwarded OpenAPI maps.
- **Nil semantics:** Use **`federation: nil`** when global metadata would mislead — default for **`{:ok, result}` when `failures != []`** unless implementation proves the backend returns federation totals that apply only to successful sub-queries and you normalize that safely; full transport failure before a usable envelope stays **`{:error, ...}`** (no struct).
- **Telemetry vs assign:** **Telemetry** (`[:scrypath, :search_many, *]`, MULTI-13) is operator/SRE truth; **`federation`** is optional **in-page** summary — may be `nil` while telemetry still fired. Dashboards: golden signals from telemetry; copy like “~N matches” from `federation` when present.
- **Power users:** Raw payloads and engine escape hatches stay under **`Scrypath.Meilisearch.*`**, not `federation`.

### D-05 — Test pyramid (extend Phase 20 D-03)

- **Default CI (`mix test`, no integration):** Majority of coverage from **pure unit tests** (merge rules, rails, unpack `facetsByIndex`, `MultiSearchResult` invariants), **`FakeBackend` / inline backends** for orchestration (pattern `test/scrypath/search_test.exs`), and **`Req.Test`** for **one** `POST /multi-search` round-trip: body shape (`queries`, `federation`, `facetsByIndex`), **assert `mergeFacets` absent**, response → structs.
- **New files (expected):** `test/scrypath/search_many_test.exs`; client-level `Req.Test` module (new file or extend `meilisearch_test.exs` / `client_test.exs` per repo hygiene); extend **`FakeBackend`** with `search_many/3` when behaviour exists; **telemetry** assertions alongside existing search patterns.
- **Tagged live Meilisearch (`@moduletag :integration`, `SCRYPATH_INTEGRATION`):** **Thin** suite (target **2–4** tests): MULTI-08 **facet byte-for-byte / struct equality** vs solo `search/3`; optionally one partial/error shape once confirmed against pinned image. **Do not** require Docker on every PR.
- **Docs truth:** Extend **`DocsContractTest`** for `guides/multi-index-search.md`; **`PhoenixExamplesTest`** (or equivalent) for critical HEEx + assigns compile.
- **Fixtures:** Prefer inline maps in `Req.Test` until unwieldy; then `test/fixtures/meilisearch/multi_search_*.json`.
- **Upgrade path:** When CI Meilisearch image bumps, treat **live failures as source of truth**, then refresh Req.Test goldens.

### D-06 — Partial-failure UX in the guide (MULTI-07)

- **Contract:** `failures: [%{schema: module(), reason: term()}]` — list order preserved; with duplicate schemas, **multiple entries** with the same `schema` are allowed; do not dedupe by schema in examples.
- **Two fully worked code paths:** (1) **`reason: :hydration_timeout`** — search OK, hydration killed one schema; others show records + facets. (2) **Transport-style** structured `reason` (e.g. map with `kind: :transport`, status) — one index failed, others OK; banner + optional retry.
- **Third family (validation):** Not a third full walkthrough — **compact table** mapping validation-style reasons → “not always retryable” UX and copy (“Check filters / config”).
- **UI layers:** **User banner:** short, schema-labeled, no raw `inspect/1` — use **`aria-live="polite"`** (not `role="alert"` unless whole page blocking). **Details:** `<details>` or modal with **bucket** + optional correlation metadata. **Dev / operator:** full `reason` in `Logger` metadata or dev-only assign — not default production HEEx.
- **Include `user_message(schema, reason)`** (or equivalent) in the guide as the **canonical pattern** for mapping known `reason` shapes to copy; fallback generic line.
- **Telemetry / runbooks:** Cross-link failure buckets to **symptom → check** (DB slow vs Meilisearch vs invalid opts) without duplicating full operator docs.

### Claude's Discretion

- Exact field set on `%MultiSearchResult.Federation{}` after one read of live federated response on pinned Meilisearch version.
- Whether `hit_count` or similar secondary field ships in v1.3 on `Federation`.
- Exact `RuntimeError` message string for `search_many!/2` (match `search!/3` tone).
- Fixture file split vs inline JSON when bodies grow.
- Minor HEEx structure in the guide (within Phase 20 UI discipline: roles, copy, no visual redesign of product).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap and requirements
- `.planning/ROADMAP.md` — Phase 21 goal, success criteria, canonical phase ordering
- `.planning/REQUIREMENTS.md` — MULTI-01..MULTI-13 acceptance criteria
- `.planning/PROJECT.md` — v1.3 vision, non-goals, additive release posture

### Deep research and synthesis
- `.planning/research/deep/MULTI_INDEX.md` — DX design for `search_many/2`, layering, structs, partial failure, cardinality rails, library survey
- `.planning/research/deep/FACETING.md` — facet parity and multi-index notes
- `.planning/research/deep/RELEVANCE.md` — cross-schema relevance deferred; `Scrypath.Meilisearch.MultiSearch.federate/2` namespacing note for docs
- `.planning/research/SUMMARY.md` — milestone-level synthesis

### Prior phase context (patterns to carry)
- `.planning/phases/20-faceted-search-liveview-guide/20-CONTEXT.md` — D-02 URL sync, D-03 test pyramid, D-04 anti-pattern appendix, D-05 doc/code alignment
- `.planning/phases/19-relevance-tuning/19-CONTEXT.md` — settings translation / verification discipline for Meilisearch payloads
- `.planning/phases/18-release-parity-gate-node-20-ci-cleanup/18-CONTEXT.md` — release parity and CI constraints

### Implementation anchors (code)
- `lib/scrypath/search.ex` — current `search/3` and `search!/3` patterns to mirror
- `lib/scrypath/backend.ex` — optional callback extension point (MULTI-12)
- `.github/workflows/ci.yml` — integration job / Meilisearch image pin for live tests

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets
- `Scrypath.Search.search/3` — validation via `Options.validate_search_options/2`, telemetry span `[:scrypath, :search]`, `decorate_result/4`, `maybe_hydrate/3` via `Hydration.hydrate/3`
- `Scrypath.Config` / `Config.fetch_backend!/1` — backend resolution for multi-dispatch
- Phase 20 `%SearchResult.Facets{}` decoders and facet validation — MULTI-08 parity path
- `FakeBackend` and `Req.Test` patterns under `test/scrypath/` — extend for `search_many`

### Established patterns
- Bang functions unwrap only `{:error, _}` from the tagged API; validation may still raise earlier where single-search does
- Default CI excludes `:integration`; live tests use `SCRYPATH_INTEGRATION`

### Integration points
- New public API likely `lib/scrypath.ex` delegating to `Scrypath.Search`
- `Scrypath.Meilisearch` client: `/multi-search` POST, federation payload builder
- ExDoc extras in `mix.exs` for new guide path
- `DocsContractTest`, `PhoenixExamplesTest` (or equivalents) for guide enforcement

</code_context>

<specifics>
## Specific Ideas

- Primary guide narrative: **federated sections** LiveView; secondary: **one `q` assign** threaded into every tuple’s text with explicit “same string ≠ same relevance” callout.
- **`search_many!/2`:** Same unwrap semantics as `search!/3`; document partial `failures:` explicitly.
- **Duplicate `Post` twice:** Show `for {schema, result} <- results.ordered` — not `by_schema[Post]` for two panels.
- **`Federation` struct:** snake_case, `nil` on misleading partials; raw JSON only under `Scrypath.Meilisearch.*`.
- **Guide failures:** Demo **hydration_timeout** + **transport** in full; validation in a **table**; `user_message/2` pattern; `aria-live="polite"` banner.

</specifics>

<deferred>
## Deferred Ideas

- **`search_many_strict!/2`** (raise when `failures != []`) — only if adopters demand an “all green or bust” escape hatch with honest naming
- **`strict_unique_schemas?: true` / duplicate rejection** — only if telemetry shows widespread `by_schema` misuse
- **Unstable `extensions:` bag on `Federation`** — only if a concrete need appears before next minor struct fields
- **Roadmap backlog (already deferred):** cross-schema ranking normalization, `:all` registry wildcard, merged facets — v1.4 per `.planning/ROADMAP.md` Backlog

### Reviewed Todos (not folded)

- GSD `todo.match-phase` was unavailable in this environment’s `gsd-sdk` build — no automated todo fold; none manually reviewed.

</deferred>

---

*Phase: 21-multi-index-search*
*Context gathered: 2026-04-17*
