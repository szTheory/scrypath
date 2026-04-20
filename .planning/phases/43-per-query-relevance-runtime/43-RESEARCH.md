# Phase 43 — Technical research: per-query relevance runtime

**Question:** What do we need to know to plan **TUNE-PQ-01…TUNE-PQ-03** well?

**Sources:** `43-CONTEXT.md`, `guides/per-query-tuning-pipeline.md`, `lib/scrypath/options.ex`, `lib/scrypath/query.ex`, `lib/scrypath/meilisearch/query.ex`, `lib/scrypath/search.ex`, `lib/scrypath/multi_search/entries.ex`, Phase 41 verify/doc-contract patterns.

---

## Current architecture (baseline)

1. **Validation** — `Scrypath.Options.validate_search_options/2` uses `@search_options` (NimbleOptions) on keywords after `Keyword.drop(opts, runtime_option_keys())`. Today keys are `:facets`, `:facet_filter`, `:filter`, `:sort`, `:page` only. Unknown search keys fail Nimble validation (no silent pass-through).

2. **Query struct** — `%Scrypath.Query{}` holds `text`, `filter`, `sort`, `page`, `facets`, `facet_filter` only. `Query.new/2` reads those keys from validated search opts.

3. **Wire projection** — `Scrypath.Meilisearch.Query.to_payload/1` maps `%Query{}` → JSON map with `q`, optional `filter`, `facetFilters`, `facets`, `sort`, `page`, `hitsPerPage`. **No** ranking-score fields yet.

4. **`search_many/2`** — `MultiSearch.Entries.normalize_one/2` does `Keyword.merge(shared, entry_core, fn _k, _s, e -> e end)` so **top-level** entry wins on duplicates. Federation-only keys are rejected on entries. There is **no** `:per_query` today; introducing it requires the **documented exception** (inner `Map.merge/2` with entry inner keys winning) when **both** sides supply `:per_query`.

5. **Telemetry** — `Telemetry.span([:scrypath, :search], metadata, …)` with `Telemetry.common_metadata/3` and `Telemetry.stop_metadata/1`. Pattern: add **low-cardinality** metadata when expensive debug knobs are active (CONTEXT D-22), not `Mix.env/0` gating (D-20).

---

## Meilisearch v1.9 slice (normative names)

Per locked guide, the first Plane B runtime slice projects at minimum:

| Scrypath `:per_query` key (recommended snake atoms) | Meilisearch JSON field |
|---------------------------------------------------|-------------------------|
| `:ranking_score_threshold` | `rankingScoreThreshold` |
| `:show_ranking_score` | `showRankingScore` |
| `:show_ranking_score_details` | `showRankingScoreDetails` |

Types: threshold is numeric (float/int per Meilisearch); both `show*` are booleans. Reject wrong types with `{:error, {:validation, _}}` (same family as existing NimbleOptions failures).

---

## Implementation approach (consensus)

1. **Single `:per_query` keyword** on `search/3`, `search_within_facet/4`, and `search_many/2` entry/shared opts — nested map, allowlisted keys only.

2. **Extend `%Query{}`** with a field (e.g. `per_query: %{}`) populated from validated opts so the Meilisearch adapter stays a pure function of `Query`.

3. **`search_within_facet`** — bucket merge happens **before** `validate_search_options`; `:per_query` on the merged opts must validate like `search/3`.

4. **Tests** — Unit tests without live Meilisearch: (a) validation + rejection paths, (b) `Meilisearch.Query.to_payload/1` asserts exact JSON keys/values, (c) `Entries.normalize/2` merge matrix for `:per_query` only / shared only / both. Optional Req.Test on backend only if existing patterns already do so for search.

5. **Verify slice** — New `lib/mix/tasks/verify.phase43.ex` mirroring `verify.phase41.ex`: `@focused_tests` listing `docs_contract_test.exs` plus the new focused per-query test file(s). Register in `mix.exs`, CI `quality`, CONTRIBUTING, and `@verify_phase43` in `docs_contract_test.exs`.

---

## Pitfalls

- **Top-level-only merge** for `:per_query` loses shared defaults — must implement **explicit** `Map.merge(shared_map, entry_map)` when both present (CONTEXT D-11).
- **Placing ranking keys on flat opts** — violates D-01/D-02; keep all Plane B tuning keys for this slice inside `:per_query`.
- **`Mix.env/0` in core** — forbidden for prod gating (D-20).
- **Doc-contract hygiene** — follow existing `docs_contract_test.exs` forbidden-token rules when adding guide/README anchors.

---

## Validation Architecture

**Sampling strategy for Phase 43**

| Dimension | Approach |
|-----------|----------|
| **Automated unit** | ExUnit on `Options`, `Query` / `Meilisearch.Query`, `MultiSearch.Entries`, and any new per-query test module — no Meilisearch daemon required. |
| **Thin verify gate** | `mix verify.phase43` runs a focused `mix test` list (doc contracts + per-query tests), same pattern as `mix verify.phase41`. |
| **CI** | Add `mix verify.phase43` to the existing `quality` job beside other phase verifies. |
| **Regression** | Tests assert **tuple tags** and stable wire field strings, not exception message prose or HTTP bodies (TUNE-PIPE error taxonomy). |

**Nyquist / feedback latency:** After each implementation task, run `mix test` on the touched test file(s). After each plan wave completes, run `mix verify.phase43` (once Plan 03 wires it) or equivalent focused paths.

---

## RESEARCH COMPLETE

Planning can proceed with executable tasks against the files listed in **43-PATTERNS.md**.
