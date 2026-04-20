---
phase: 37-disjunctive-facet-counts
plan: "01"
subsystem: search
tags: [meilisearch, facets, pure-functions]

requires: []
provides:
  - Scrypath.Facets.Disjunctive.merge_distributions/2 on wire facetDistribution maps
  - ExUnit merge contract tests
affects: []

tech-stack:
  added: []
  patterns:
    - "Wire-level facetDistribution merge before SearchResult decode for disjunctive UX"

key-files:
  created:
    - lib/scrypath/facets/disjunctive.ex
    - test/scrypath/facets/disjunctive_test.exs
  modified: []

key-decisions:
  - "Documented single-search vs multi-search count semantics in @moduledoc only; no HTTP orchestration in core."

patterns-established:
  - "merge_distributions/2 deep-copies main, replaces or inserts per override key using to_string/1 on outer keys."

requirements-completed: [FACET-02]

duration: 15min
completed: 2026-04-19
---

# Phase 37 plan 01 summary

**Pure `merge_distributions/2` helper plus tests for Meilisearch-style facetDistribution merging without implying single-response disjunctive counts.**

## Performance

- **Duration:** ~15 min
- **Tasks:** 2
- **Files modified:** 2

## Task commits

1. **Task 1: Add module + merge_distributions** — `700021f`
2. **Task 2: ExUnit contract tests** — `20a606a`

## Files created

- `lib/scrypath/facets/disjunctive.ex` — documented merge helper; integer-normalized inner maps.
- `test/scrypath/facets/disjunctive_test.exs` — replace, empty overrides copy, insert key, string vs atom keys.

## Deviations from plan

None — adjusted test B to prove deep copy by mutating merged map instead of reference inequality on small maps.

## Self-check

PASSED — `mix compile --warnings-as-errors`, `mix test test/scrypath/facets/disjunctive_test.exs`.
