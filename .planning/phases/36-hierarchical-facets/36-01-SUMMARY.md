---
phase: 36-hierarchical-facets
plan: "01"
subsystem: api
tags: [faceting, elixir, compile-time]

requires: []
provides:
  - Opt-in nested_facet_paths on schema faceting
  - hierarchy sugar expanding lvlN attributes
  - Golden FacetableHierarchy fixture
affects: [meilisearch-settings, search-result, docs]

key-files:
  created:
    - test/support/facetable_hierarchy.ex
  modified:
    - lib/scrypath/options.ex
    - test/scrypath/options_test.exs

key-decisions:
  - Declaring hierarchy forces nested_facet_paths true because expansion always emits dotted lvlN atoms
  - Dotted atoms when opted in must match single-dot lvlN suffix pattern

patterns-established:
  - "preprocess_faceting_declarations/1 expands hierarchy before attribute validation so generated atoms participate in filterable subset checks"

requirements-completed: [FACET-01]

duration: unknown
completed: 2026-04-19
---

# Phase 36: Hierarchical facets — Plan 01 summary

**Schema faceting now supports opt-in Meilisearch-style dotted facet paths and optional hierarchy expansion without changing flat-only defaults.**

## Task commits

Commits recorded after `feat(36-01)` — see `git log --grep=36-01`.

## Self-Check: PASSED

- `mix compile --warnings-as-errors`
- `mix test test/scrypath/options_test.exs`

## Deviations

None.
