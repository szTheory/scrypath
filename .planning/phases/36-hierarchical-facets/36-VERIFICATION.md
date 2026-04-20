---
status: passed
phase: 36-hierarchical-facets
verified: 2026-04-19
---

# Phase 36 verification

## Automated

- `mix compile --warnings-as-errors`
- `mix verify.phase36` (options, search, settings, drift, docs_contract)

## Must-haves (from plans)

- [x] Opt-in `nested_facet_paths` with default flat-only dotted rejection preserved
- [x] Optional `hierarchy:` expands `lvl0`..`lvl{N-1}` under base; normalized faceting omits `:hierarchy`
- [x] Meilisearch settings merge projects dotted facet attributes with `facetSearch`
- [x] Index contract drift faceting compares hierarchical declarations to applied wire
- [x] `SearchResult` decodes `facetDistribution` for dotted facet keys
- [x] Guide `## Hierarchical facets` and anti-pattern appendix aligned
- [x] `mix verify.phase36` + `preferred_cli_env`

## Human verification

None required for this phase.

## Gaps

None.
