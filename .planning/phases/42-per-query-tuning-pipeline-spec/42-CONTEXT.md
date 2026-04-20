# Phase 42: Per-query tuning pipeline spec - Context

**Gathered:** 2026-04-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Publish the authoritative **`TUNE-PIPE-*`** specification (**precedence**, **Meilisearch request mapping**, **non-goals**, **errors/telemetry expectations**, **implementation gate checklist** authorizing **`TUNE-PQ-*`**). This phase is **documentation and contract design only**—no new runtime search API unless a doc-driven correction is unavoidable.

**Process note:** User selected **all** discuss gray areas and requested **parallel subagent research** plus a **single synthesized recommendation set** (coherent with Scrypath vision, Phase 19 settings work, and Phase 41 doc/verify discipline). This file locks those recommendations for planning and execution.

</domain>

<decisions>
## Implementation Decisions

### A) Canonical home and discoverability (gray area 1)

- **D-01:** **Single canonical published spec** lives at **`guides/per-query-tuning-pipeline.md`** (name matches roadmap language “per-query tuning pipeline”). It is both **normative spec** and **operator-readable guide** via a **fixed spine** (sections below)—**not** split across `docs/` + `guides/` unless maintainer-only material later forces an appendix in `docs/` with a clear secondary role.
- **D-02:** **Register** the guide in **`mix.exs`** `extras` and **`groups_for_extras`** under **Operations**, immediately after **`guides/relevance-tuning.md`** (index-time settings vs request-time pipeline are adjacent concerns).
- **D-03 (README):** **One sentence + link** from `README.md` (billboard rule, Phase 41 **D-10**).
- **D-04 (Golden path):** **`guides/golden-path.md`** gets a **pointer-only** “read next” line after first successful search—**no** second manual inside golden path (Phase 41 **D-12**).
- **D-05 (`guides/overview.md`):** Add a **table row** so GitHub and HexDocs nav stay aligned.
- **D-06 (`@doc`):** **`Scrypath.search/3`** and **`search_many/2`** each carry **one compact canonical paragraph** + “Full pipeline:” link to the guide (mirrors Phase 41 **D-17** for federation).
- **D-07:** **Do not** put the normative spec only under `.planning/` or only in giant `@moduledoc` blocks—adopters and HexDocs consumers must see it; `@moduledoc` stays a **compression layer**, not the source of truth.
- **D-08 (Fixed spine for `guides/per-query-tuning-pipeline.md`):** (1) Scope & non-goals, (2) Two-plane model & precedence, (3) Pipeline stages (ordered), (4) Meilisearch mapping & version stance, (5) Error taxonomy (summary + pointer to appendix tables), (6) Telemetry catalog (summary + pointer), (7) Federation / `search_many` notes, (8) Recipes (Phoenix/LiveView), (9) **Implementation readiness checklist** (gates **`TUNE-PQ-*`**).

### B) Precedence and option layering (gray area 2)

- **D-10 (Two-plane rule — normative):** **Plane A — index settings:** declared in schema **`settings:`**, resolved/applied through **reindex / managed settings** (`Settings.resolve/2`, `settings_merge`, drift tooling). **Plane B — search request:** JSON (or equivalent) for **`POST …/search`** / each multi-search query object—**never** implicitly re-resolve full Plane A maps into every search unless a **future explicit mode** documents latency and semantics.
- **D-11 (Stack for Plane B):** Weakest → strongest: **Meilisearch defaults for omitted search fields** → **live index settings on the server** (operational truth) → **Scrypath allowlisted per-query / per-request overrides** (and any library-side projection keys that never hit the wire). **Schema `settings:`** is the **declared source** that should produce Plane A truth via reindex; **drift** is an operational concern (honesty), not silently papered over on each search.
- **D-12 (Right-biased merge everywhere):** Extend Phase 19 **D-10/D-11** explicitly to search-time keywords: **`Application.get_env(:scrypath, :defaults)` < per-repo `:scrypath` < per-call runtime opts < per-entry tuple opts < per-query tuning map** (include only layers that apply to a given call). This matches **`Scrypath.Config.resolve!/1`** and **`Scrypath.MultiSearch.Entries`** (“entry wins” on duplicate keys; **shared-only** keys stay shared-only).
- **D-13 (`search_many/2`):** Document that **per-entry tuple keywords beat `shared_opts`** for duplicate top-level keys; **federation rail keys** remain **shared-only**; any future **per-query tuning** keys follow the **same** merge story unless explicitly documented as shared-only.
- **D-14 (Nested maps):** Reuse **`:settings_merge`-style semantics** for any nested map merge the pipeline defines: **default `:replace` (shallow)**; **`:deep` opt-in only**—same footgun avoidance as Phase 19 (Phoenix deep-merge clobber, Oban `queues: []` lesson).
- **D-15 (Normalize before merge):** Any map-shaped user input for tuning participates in the **same normalize-on-entry** story as Phase 19 **D-15–D-17** (canonical keys + **`__unrecognized__`** / operator visibility)—**no** second ad-hoc key story for search-time maps.
- **D-16 (Validation posture):** **Strict allowlist** for **library-owned** per-query keys (clear **`{:invalid_options, _}`** family); unknown Meilisearch passthrough (if any escape hatch exists) must be **explicitly labeled** as such in the spec so adopters know what semver covers.
- **D-17 (Rejected models):** **Reject** “schema-as-runtime-truth on every search” (re-resolve index settings each call) and **reject** left-biased merge—both violate shipped ergonomics and operational story.

### C) Meilisearch mapping scope for v1.9 / TUNE-PQ (gray area 3)

- **D-20 (Spec strategy):** **Principle-based catalog (categories)** + **small exemplar “v1.9 implementation slice”** for Phase 43—**not** a full OpenAPI dump and **not** silent “anything goes” without categories.
- **D-21 (Categories — normative framing):** (1) **Pass-through search parameters** Meilisearch documents on **`SearchQuery`** and that the adapter can forward **without semantic rewrite**; (2) **Index prerequisites** (filterable/sortable/displayed/embedder constraints) as a **short matrix** with links to Meilisearch reference—**do not** copy vendor prose; (3) **Explicitly index-bound** (synonym sets, ranking rule order, typo policy, etc.)—per-query doc must say **why** these stay in Plane A and point to **`guides/relevance-tuning.md`** / reindex lifecycle.
- **D-22 (IN-SCOPE exemplars for first runtime slice — suggest in spec, implement in Phase 43):** Treat as **first-class in the written contract**: **`rankingScoreThreshold`** (document upstream semantics: may affect **hits, totals, facet distributions**, pagination interaction, performance caveats), **`showRankingScore`**, optional **`showRankingScoreDetails`** as **debug/tuning** with response-shape/cost callouts; plus **existing** first-class search options Scrypath already models (filter, sort, facets, pagination, retrieve/highlight/crop, etc.) **as today**—the spec **anchors** how they participate in the pipeline relative to new knobs.
- **D-23 (DEFER with rationale):** **Vector / hybrid / personalization / enterprise-only knobs** unless the milestone explicitly expands—keep behind **documented escape hatch** only; **full synonym / rankingRules mutation** as “per-query tuning” (**deferred**—index lifecycle); **federated product completeness** (cross-index `distinct`, merge facets, full weighting tutorial) **deferred** to multi-search guide ownership **except** a **short compatibility appendix** so Plane B types do not bake a **single-search-only** dead end.
- **D-24 (Multi-search footgun):** Spec includes an **appendix callout**: federated vs non-federated payloads differ (`federation`, global pagination, `facetsByIndex`, per-query `federationOptions`)—**pointer** to **`guides/multi-index-search.md`** as canonical merge story; TUNE-PIPE does not duplicate federation narrative.
- **D-25 (Version stance):** Spec states **minimum Meilisearch version** for threshold/score features and links **release notes / reference**—Scrypath does not re-teach ranking theory.

### D) Errors, telemetry, and doc contracts (gray area 4)

- **D-30 (Hybrid spec — recommended):** **Normative:** stable **error tags** (`reason` discriminant after `{:error, …}`), stable **telemetry event names** (`[:scrypath | …]`), and **documented metadata keys** adopters may attach handlers to. **Non-normative:** human **`Exception.message/1`** text, NimbleOptions copy, HTTP body wording, log lines—**semver patch** unless explicitly promised.
- **D-31 (NimbleOptions seam):** Keep **`{:error, {:validation, String.t()}}`** (or a **future structured** `{:validation, map}`) as the **documented wrapper** for options validation—**do not** promise substring stability on the string beyond **informative examples** in the guide.
- **D-32 (Domain errors):** Continue **tagged tuples** the library owns (`:unknown_facet`, `{:invalid_options, {:all_expansion, _}}`, etc.)—these are **what tests and semver lock** (pattern match on shape, not message).
- **D-33 (Telemetry catalog):** Spec includes **tables**: event name → span vs execute → **documented metadata keys** → when emitted (success, partial, failure). **`[:scrypath, :search_many, :partial]`**-style events are **public observability contract**; policy: **additive metadata** minor OK; **rename/remove events** = breaking.
- **D-34 (Doc contracts for TUNE):** Follow Phase 41: **hygiene** (no internal REQ/planning tokens in published paths), **structural locks** (fixed **H2** spine in the new guide), **minimal substring anchors** for critical invariants (error tag literals, key event names)—**no** full-page prose snapshots; Phase 43 adds **`mix verify.phaseNN`** (or extends an existing verify task) per existing **thin-composer** pattern.
- **D-35 (Categories in errors):** Spec requires errors to distinguish **layer**: options validation vs query shape vs HTTP/transport vs engine semantics—avoids “invalid search” soup (Stripe/GraphQL lesson: stable machine channel vs narrative).

### E) Cross-cutting product alignment

- **D-40:** **Operational honesty:** index drift, threshold effects on counts/facets, and multi-search semantics must be **visible in prose**, not buried in footnotes only.
- **D-41:** **Meilisearch-first vocabulary** in the spec; **internal adapter seam** preserved; **no** public multi-backend promise.
- **D-42:** **DX:** one guide to grep, one merge mental model (right-bias), predictable **`case`** shapes, telemetry hooks SREs can rely on, fast verify slice—matches Ecto/Oban/Req expectations for Elixir OSS.

### Claude's Discretion

- Exact filename if **`per-query-tuning-pipeline.md`** is renamed for consistency with future URLs (must remain **one** canonical path once published).
- Minor subsection ordering inside the fixed spine if editorial flow improves without splitting authority.
- Whether **`rankingScoreDetails`** lands as **dev-only** or **supported** in Phase 43—spec should allow **either** if labeled; implementation picks one.

### Folded Todos

_None — `todo.match-phase` returned no matches._

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirements

- `.planning/ROADMAP.md` — Phase 42 table (**v1.9**), success criteria, **`TUNE-PIPE-*`**
- `.planning/REQUIREMENTS.md` — **TUNE-PIPE-01** … **TUNE-PIPE-04** acceptance text; traceability table

### Locked prior context (must stay consistent)

- `.planning/phases/19-relevance-tuning/19-CONTEXT.md` — Plane A settings, **right-biased** cascade, **`settings_merge`**, normalize-on-entry, **no** per-query ranking in Phase 19 scope (superseded for v1.9 only by this milestone’s new explicit surface)
- `.planning/phases/41-federation-docs-contracts/41-CONTEXT.md` — README vs guides, **`docs_contract_test.exs`** philosophy, verify slice patterns, **`search_many/2`** `@doc` invariant style
- `.planning/phases/21-multi-index-search/21-CONTEXT.md` — tuple API, multi-index baseline
- `.planning/phases/39-federation-scoring-weights/39-CONTEXT.md` — federation weights, merge semantics

### Guides and docs to cross-link (edit targets for Phase 42 deliverable)

- `guides/relevance-tuning.md` — index-time settings; add **request-time vs index-time** pointer **to** the new pipeline guide
- `guides/multi-index-search.md` — Layer 1 vs Layer 2; pointer **from** pipeline guide for **`search_many`**
- `guides/golden-path.md` — pointer-only deep link
- `guides/overview.md` — navigation row
- `README.md` — billboard link
- `mix.exs` — `extras` + `groups_for_extras` registration

### Implementation anchors (code today)

- `lib/scrypath/search.ex` — `search/3`, `search_many/2`, telemetry **`[:scrypath, :search_many, :partial]`**
- `lib/scrypath/config.ex` — **`Config.resolve!/1`** cascade
- `lib/scrypath/multi_search/entries.ex` — shared vs entry keyword merge semantics
- `lib/scrypath/options.ex` — NimbleOptions schemas, **`{:validation, _}`** mapping
- `test/scrypath/docs_contract_test.exs` — contract-test patterns to extend in Phase 43

### External (link, do not copy)

- Meilisearch **Search API** / **SearchQuery** reference (version-pinned in spec)
- Meilisearch **multi-search** / **federation** reference
- Meilisearch **ranking score** / **threshold** release notes for minimum engine version

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **`Scrypath.Config.resolve!/1`** — canonical **right-biased** runtime option cascade to reference in the spec diagram.
- **`Scrypath.MultiSearch.Entries.normalize/2`** — **entry wins** merge semantics for **`search_many/2`**; document extension for per-query maps.
- **`lib/scrypath/search.ex`** — existing telemetry patterns for **partial** multi-search; template for new events in Phase 43.
- **`NimbleOptions`** integration in **`lib/scrypath/options.ex`** — **`{:validation, message}`** wrapper remains the stable validation seam.

### Established patterns

- **Phase 19** — shallow-default **`:replace`**, **`:deep` opt-in** for nested settings maps; **normalize-on-entry** before merge.
- **Phase 41** — **single concept source** per domain in **`guides/`**; README as **pointer**; verify tasks as **thin composers**.

### Integration points

- New guide links **from** **`guides/relevance-tuning.md`** and **`guides/multi-index-search.md`** **into** the pipeline guide and back.
- **`mix.exs`** ExDoc **Operations** group becomes the **HexDocs** home for the spec alongside **`relevance-tuning.md`**.

</code_context>

<specifics>
## Specific Ideas

- Subagent consensus: **Searchkick**-style scattered advanced docs hurts operators; **Laravel Scout**-style driver vagueness conflicts with Scrypath’s **operational honesty**; **meilisearch-rails** “settings vs `ms_search` params” split is a good **mental model** for **Plane A vs Plane B**.
- Treat **TUNE-PIPE** like **federation** in Phase 41: **one canonical markdown home** under **`guides/`**, **`@doc` as compressed contract**, **cross-links** so index settings, per-query pipeline, and federation merge stay **three non-overlapping stories**.

</specifics>

<deferred>
## Deferred Ideas

- **Split normative spec into `docs/`** — only revisit if maintainer-only content splits the audience; if split, one file must be explicitly **non-normative** to avoid Phase 41 **D-11** drift.
- **Auto-generated SearchQuery matrix from OpenAPI** — optional later to reduce drift; not required for Phase 42 text deliverable.
- **Phase 43 verify task name** — `mix verify.phase43` (or other) left to planner; CONTEXT requires **thin composer** pattern only.

</deferred>

---

*Phase: 42-per-query-tuning-pipeline-spec*
*Context gathered: 2026-04-20*
