# Per-query tuning pipeline

This document is the **canonical** request-time tuning pipeline specification for Scrypath’s Meilisearch-first search path. It describes how search-time options flow from configuration through validation to Meilisearch, how that relates to index-time settings, and what operators and implementers should rely on for stable contracts versus illustrative prose.

## Scope and non-goals

**In scope:** Plane B (search request) semantics, merge precedence, pipeline stages, mapping categories for Meilisearch search parameters, error and telemetry expectations at a normative level, federation pointers, and recipes that stay thin relative to dedicated guides.

**Non-goals:**

- **Replacing index-time documentation.** Synonym sets, default ranking rule order, typo policies, and other **Plane A** concerns remain in **`guides/relevance-tuning.md`** and the managed reindex lifecycle. This guide links there instead of duplicating index settings narrative.
- **Teaching Meilisearch ranking theory.** Prefer links to vendor reference and release notes over copying vendor prose blocks.
- **Promising a public multi-backend abstraction.** Scrypath is Meilisearch-first here; an internal adapter seam exists but is not a semver-stable portability layer for adopters.
- **Embedding secrets in examples.** Transport configuration and API keys belong in operator docs and application configuration, not copy-pasted into search-option examples.
- **Normative stability for human strings.** `Exception.message/1`, raw HTTP bodies, log lines, and NimbleOptions copy may change in patch releases unless explicitly documented otherwise.

## Two-plane model and precedence

**Plane A — index settings:** Declared on `use Scrypath` in **`settings:`**, translated to Meilisearch index configuration, applied through managed reindex and drift-aware tooling. The declared schema is the **source of intent** for what the index should look like after a successful apply.

**Plane B — search request:** The JSON (or equivalent) payload for **`POST …/indexes/{uid}/search`** and each query object inside **`/multi-search`**. Plane B parameters tune a **single search** (filters, sort, facets retrieval, pagination, ranking-score knobs, and similar) without re-resolving the full Plane A map on every call. Operational drift between declared Plane A and the live server is an **operator visibility** problem (diff tasks, reindex), not something Plane B silently “fixes” on each request.

**Stack for Plane B keywords (weakest → strongest):**

1. Meilisearch defaults for omitted search fields (vendor baseline).
2. **Live index settings on the server** (operational truth for attributes, embedders, etc.).
3. **Scrypath allowlisted per-request options** after validation and projection (what the library forwards this release).
4. **Per-entry tuple keywords** in `search_many/2` winning over **shared** keywords for duplicate top-level keys (see **`Scrypath.MultiSearch.Entries`** — entry side wins in `Keyword.merge/3` with a conflict function favoring the entry).
5. **Optional `:per_query` tuning map** (search-time, carried on **`%Scrypath.Query{}`** when used) — same right-bias story as other tuning maps; nested map merge defaults align with Plane A **`:settings_merge`** semantics unless this guide or **`guides/relevance-tuning.md`** explicitly documents an exception.

**Configuration cascade for runtime (repo, URL, backend) — `Scrypath.Config.resolve!/1`:**

`Application.get_env(:scrypath, :defaults, [])` is merged with per-repo `Application.get_env(otp_app, repo)[:scrypath]` (when `:repo` / `:otp_app` resolution succeeds), then merged again with explicit per-call keywords; explicit call-time keys win. That stack addresses **transport and library runtime**, not the full Plane A `settings:` map.

**Nested maps:** Default **shallow replace** for duplicate keys at each level; **`:deep`** (where the pipeline exposes it) is **opt-in** only, matching the index-time settings-merge posture in **`guides/relevance-tuning.md`** (avoid accidental deep-merge clobber of large maps).

## Pipeline stages

Ordered stages describe responsibility boundaries; exact function names may evolve, but the **ordering** is normative for reasoning and docs:

1. **Normalize and validate** — Canonical keys, allowlists, and `{:invalid_options, _}` / `{:validation, _}` style failures before any HTTP work. Unknown keys should not silently become wire noise unless an explicitly labeled escape hatch documents semver coverage.
2. **Merge** — Apply the Plane B precedence rules above (including `search_many/2` shared vs per-entry merge and shared-only federation rail keys).
3. **Project** — Translate Scrypath option keywords into Meilisearch camelCase request fields the adapter sends.
4. **Dispatch** — Backend `search/3` or native `search_many/2` (federation) with configured timeouts.
5. **Decode and hydrate** — Parse engine responses, optional record hydration, facet maps, and ranking score fields when requested.
6. **Surface result or error** — Tagged tuples for domain failures; `{:ok, _}` for success including partial federation success with per-schema failures listed.

## Meilisearch mapping and version stance

**Principle-based categories (normative framing):**

| Category | Meaning |
| --- | --- |
| **Pass-through search parameters** | Fields Meilisearch documents on **Search** / **Multi-search** query objects that the adapter forwards **without semantic rewrite**, subject to allowlisting and naming translation. |
| **Index prerequisites** | Plane A constraints (filterable, sortable, displayed, embedder availability) required before a Plane B knob becomes meaningful. Document as a **short matrix** with links to vendor reference rather than copying vendor tables. |
| **Explicitly index-bound** | Synonym sets, ranking rule **order**, default typo policy, and similar — remain Plane A; per-query docs explain **why** and point to **`guides/relevance-tuning.md`**. |

**Shipped search-time ranking exemplars** (Plane B; normative here, implemented in **`Scrypath.search/3`**, **`search_many/2`**, and **`%Scrypath.Query{}` / `:per_query`):**

- **`rankingScoreThreshold`** — May change which hits appear, and can interact with **hit counts**, **estimated totals**, **facet distributions**, and **pagination** semantics. Operators should read vendor guidance on threshold behavior and performance.
- **`showRankingScore`** — Surfaces ranking-related score fields in the response when the engine supports it.
- **`showRankingScoreDetails`** — Treat as **debug / tuning** only: richer response shape and higher cost; enable deliberately in non-production or bounded dashboards.

Also anchor **existing** first-class options Scrypath already models (`filter`, `sort`, `facets`, pagination, retrieve / highlight / crop, etc.) as participating in the same validate → merge → project → dispatch story.

**Deferred (documented rationale):**

- **Vector / hybrid / personalization / enterprise-only knobs** unless a future documented public release expands scope — keep behind any documented escape hatch with clear semver expectations.
- **Per-query mutation of synonyms or full `rankingRules` replacement** — deferred to index lifecycle (Plane A) to avoid split-brain between declared schema and live search.
- **Full federated product tutorial** — deferred to **`guides/multi-index-search.md`** except for compatibility notes in this guide.

**Minimum Meilisearch version:** Scrypath’s CI and support statement pin a **floor** Meilisearch version (see project **`README.md`** / release docs). Features such as **`rankingScoreThreshold`** and related score fields require a server at or above the vendor version that introduced them — verify against [Meilisearch release notes](https://github.com/meilisearch/meilisearch/releases) and [Search API reference](https://www.meilisearch.com/docs/reference/api/search) before enabling in production.

## Error taxonomy

Stable contracts are **tags and tuple shapes**, not human strings.

| Layer | Examples | Adopter guidance |
| --- | --- | --- |
| **Options validation** | `{:error, {:validation, message}}` (NimbleOptions wrapper), `{:error, {:invalid_options, _}}` family | Match on the **discriminant** after `{:error, …}`; do not assert on full `message` text for control flow. |
| **Query shape / domain** | `:unknown_facet`, facet bucket conflicts, `{:validation_failed, schema, reason}` (multi-search preflight) | Pattern match tags; semver treats these shapes as API. |
| **HTTP / transport** | Timeouts, connection errors, non-success HTTP classified by the backend | Often wrapped or annotated by the adapter; treat as operational incidents with retry policy outside the library. |
| **Engine semantics** | 4xx/422 from Meilisearch for impossible requests | Surface as `{:error, _}` shapes the backend documents; do not rely on raw body text in tests. |

## Telemetry catalog

Telemetry is a **public observability contract** for event names and documented metadata keys. **Additive** metadata in minor releases is acceptable; **renaming or removing** events or documented keys is **breaking**.

| Event | Span / execute | Documented metadata (non-exhaustive) | When |
| --- | --- | --- | --- |
| `[:scrypath, :search]` | Span | Module, config-derived fields via `Telemetry.common_metadata/3`, optional `search_scope`, `scoped_facet` for facet-scoped searches | Around single-index `search/3` work |
| `[:scrypath, :search_many]` | Span | `schema_count`, `raw_entry_count`, stop metadata from results | Around multi-search orchestration |
| `[:scrypath, :search_many, :partial]` | Execute | Per-schema failure summaries where applicable | When some indexes fail but the API returns partial success |

Refer to the public search API docs for the emit points as the code evolves.

## Federation and search_many

`Scrypath.search_many/2` merges **shared** and **per-entry** options with **per-entry winning** on duplicate keys. Federation rail keys (`:federation_limit`, `:federation_offset`, `:hydration_timeout`, `:federation_timeout`, `:max_schemas`, etc.) remain **shared-only** and are rejected on entry tuples.

Federated payloads differ from independent multi-search (weights, merge ordering, `facetsByIndex`, global pagination). **Canonical narrative:** **`guides/multi-index-search.md`**. This pipeline spec does not duplicate that guide; it only states that **Plane B** tuning keys must remain compatible with the **per-entry vs shared** merge story unless a future decision explicitly introduces a shared-only exception list.

## Recipes (Phoenix and LiveView)

- **Controller / context:** Build a single keyword list per request (params → allowed keys only), merge over repo defaults, pass to **`Scrypath.search/3`**. Keep ranking-score debug options behind feature flags.
- **LiveView:** Treat search assigns as **request-scoped** Plane B state; reload index-time Plane A through reindex workflows when operators change schema settings.
- **Dashboards:** For `search_many/2`, render per-schema sections from declaration order; never assume merged facets across indexes unless the engine and guide explicitly describe that behavior.

## Implementation readiness checklist

Use this checklist before extending **Plane B** per-query search-time options or changing merge/projection behavior. Every item should be satisfied in writing and in code review:

- [ ] **Plane A vs Plane B** is documented for the team; no plan relies on “schema-as-runtime-truth on every search.”
- [ ] **Right-biased merge** is implemented for all new tuning maps, including `search_many/2` entry vs shared behavior.
- [ ] **Nested map default** is **shallow replace** with **`:deep` opt-in** only, consistent with existing settings-merge semantics.
- [ ] **Allowlist** posture is enforced for library-owned keys; any escape hatch is explicitly labeled and semver-scoped.
- [ ] **Meilisearch version floor** is verified for **`rankingScoreThreshold`** / score field features used in production.
- [ ] **Error taxonomy** tests match on tuple tags, not exception strings or HTTP bodies.
- [ ] **Telemetry** events above are emitted with documented metadata keys and are covered in changelog when changed.
- [ ] **Multi-search** compatibility is covered without duplicating **`guides/multi-index-search.md`** — links and merge rules stay single-sourced.
- [ ] **Operator honesty** — drift, threshold effects on counts/facets, and partial federation are visible in UX copy or operator runbooks, not only internal comments.

When all boxes are checked, changes to the per-query runtime may proceed with changelog and contract-test coverage as usual.
