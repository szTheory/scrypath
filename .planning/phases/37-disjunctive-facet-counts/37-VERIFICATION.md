---
status: passed
phase: 37-disjunctive-facet-counts
verified: 2026-04-19
---

# Phase 37 verification

## Automated

- `mix compile --warnings-as-errors`
- `mix verify.phase37` (disjunctive tests, Meilisearch query tests, docs_contract)
- `mix verify.phase36` (regression slice for hierarchical facets phase)

## Must-haves (from plans)

- [x] Documented pure `merge_distributions/2` merges wire `facetDistribution` maps; `@moduledoc` states single-search vs multi-search honesty
- [x] Unit tests cover merge replace, empty overrides, missing outer key, atom vs string override keys
- [x] Guide `## Disjunctive facet counts` with Genre + year reference scenario; appendix pointer for wrong OR-count mental model; no internal REQ IDs in prose
- [x] `docs_contract_test.exs` locks stable substrings and `verify.phase37` listing without Hex secrets
- [x] `mix verify.phase37` + `preferred_cli_envs` entry

## Human verification

None required for this phase.

## Gaps

None.
