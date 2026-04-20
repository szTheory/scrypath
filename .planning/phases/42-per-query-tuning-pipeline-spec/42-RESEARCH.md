# Phase 42 — Technical research: per-query tuning pipeline spec

**Phase:** 42 — Per-query tuning pipeline spec  
**Question:** What do we need to know to PLAN this phase well?

## Summary

Phase 42 is **documentation-only**: publish **`guides/per-query-tuning-pipeline.md`** as the single normative contract for **Plane A (index settings)** vs **Plane B (search request)** precedence, **Meilisearch Search API** mapping categories (not a full OpenAPI dump), **non-goals**, **error/telemetry contracts**, and an **implementation readiness checklist** that explicitly authorizes **Phase 43 (`TUNE-PQ-*`)** runtime work.

Execution anchors already exist in **`Scrypath.Config.resolve!/1`**, **`Scrypath.MultiSearch.Entries`**, **`Scrypath.Options`**, and **`Scrypath.Search`** (including **`[:scrypath, :search_many, :partial]`**). Phase 19 **`guides/relevance-tuning.md`** owns index-time settings; the new guide must **cross-link** (request-time vs index-time) without duplicating federation narrative (**`guides/multi-index-search.md`** remains canonical for **`search_many/2`** merge semantics).

**HexDocs / hygiene:** Follow **Phase 41** patterns: register the guide in **`mix.exs`** `extras` + **`groups_for_extras`**, extend **`test/scrypath/docs_contract_test.exs`** `@guide_paths` / `@published_markdown_for_hygiene`, and avoid **internal REQ IDs** (`TUNE-NN` bare pattern), **`DocsContractTest`**, **`(D-xx)`**, etc., in published markdown per existing regex guards.

**Meilisearch surface (v1.9 slice):** CONTEXT locks **exemplars** — **`rankingScoreThreshold`**, **`showRankingScore`**, optional **`showRankingScoreDetails`** — with honest callouts on **hits, facet counts, totals, pagination**, and **minimum engine version** (pin in spec prose + links to vendor docs, do not copy vendor prose).

## Findings

### Precedence and two-plane model

- **Plane A:** Schema **`settings:`** → managed reindex / drift tooling (**`Settings.resolve`**, **`settings_merge`**, hot apply). Operational truth on the server may drift from declared schema; CONTEXT **D-11** forbids silently re-resolving full Plane A into every search.
- **Plane B:** **`POST /indexes/{uid}/search`** (and multi-search query objects). Stack (weakest → strongest): Meilisearch defaults for omitted fields → live index settings → Scrypath allowlisted per-query / per-request overrides → **right-biased** keyword merge aligned with **`Config.resolve!/1`** and **entry-over-shared** rules for **`search_many/2`**.
- **Nested maps:** Reuse **`:settings_merge`-style** semantics: default **shallow `:replace`**, **`:deep` opt-in** only (Phase 19 footgun avoidance).

### Meilisearch mapping strategy

- **Principle-based catalog:** (1) pass-through **SearchQuery** parameters the adapter forwards without semantic rewrite; (2) **index prerequisites** matrix (filterable/sortable/displayed/embedder) with links; (3) **index-bound** knobs (synonyms, **`rankingRules`**, typo policy) documented as **Plane A** with pointer to **`guides/relevance-tuning.md`**.
- **Deferred:** vector/hybrid/personalization unless milestone expands; full per-query synonym / **`rankingRules`** mutation deferred to index lifecycle.

### Errors and telemetry (normative vs non-normative)

- **Normative:** Tagged **`{:error, _}`** shapes the library owns, stable **`:telemetry` event names** (`[:scrypath | …]`), documented **metadata keys**.
- **Non-normative:** Human exception messages, NimbleOptions string detail (informative examples only in guide).
- **Catalog:** Tables in the guide — event → span vs execute → metadata keys → emit conditions; policy: **additive metadata** minor OK; **rename/remove events** = breaking.

### Verification without Phase 43 runtime

- **No new `mix verify.phase42`** required by CONTEXT (**Phase 43** owns thin verify composer extension) unless planner chooses a minimal **docs-only** slice; default path: **`mix test test/scrypath/docs_contract_test.exs`** after edits to published paths and **`mix compile --warnings-as-errors`** after **`@doc`** changes in **`lib/scrypath/search.ex`**.

## Risks and mitigations

| Risk | Mitigation |
|------|------------|
| Published guide trips **docs_contract_test** hygiene regexes | Avoid `TUNE-01`-style bare IDs, internal planning tokens, `DocsContractTest` string |
| Spec contradicts shipped Phase 19 / 39 / 41 behavior | Lock sections to **42-CONTEXT.md** + cited source files; executor reads **`search.ex`**, **`config.ex`**, **`multi_search/entries.ex`**, **`options.ex`** before writing |
| Scope creep into Phase 43 implementation | Checklist gates **`TUNE-PQ-*`**; no new runtime NimbleOptions keys in Phase 42 unless doc-driven correction is unavoidable (CONTEXT boundary) |

## Validation Architecture

Phase 42 validation is **doc-contract + compile** oriented (no Meilisearch daemon required for the default verify path).

### Dimension coverage

| Dimension | How it is sampled |
|-----------|-------------------|
| Published doc hygiene | `mix test test/scrypath/docs_contract_test.exs` (published markdown patterns) |
| ExDoc wiring | `grep` / read **`mix.exs`** `extras` and `groups_for_extras` |
| API doc compression | `mix compile --warnings-as-errors` after **`@doc`** edits on **`Scrypath.search/3`** and **`search_many/2`** |
| Cross-link integrity | `grep` for relative links to **`guides/per-query-tuning-pipeline.md`** from README, golden-path, overview, relevance-tuning, multi-index-search |

### Nyquist sampling policy

- After each task wave touching **`guides/*.md`** or **`README.md`**: run **`mix test test/scrypath/docs_contract_test.exs`**.
- After **`lib/scrypath/search.ex`** changes: **`mix compile --warnings-as-errors`** minimum; full doc test file as above recommended.

### Wave 0

Not applicable — existing **ExUnit** + **Mix** infrastructure covers the phase.

---

## RESEARCH COMPLETE

Research artifacts are sufficient to author **PLAN.md** files with concrete file paths, grep-verifiable acceptance criteria, and a validation strategy aligned with **`42-VALIDATION.md`**.
