---
phase: 36-hierarchical-facets
plan: "02"
subsystem: api
tags: [meilisearch, settings, drift]

requires:
  - phase: 36-01
    provides: nested_facet_paths and dotted facet attributes on schemas
provides:
  - String-keyed covered set for filterable merge (no String.to_existing_atom on dotted paths)
  - Drift test proving faceting dimension for hierarchical schemas
affects: []

key-files:
  created: []
  modified:
    - lib/scrypath/meilisearch/settings.ex
    - test/scrypath/meilisearch/settings_test.exs
    - test/scrypath/operator/index_contract_drift_test.exs

key-decisions:
  - Track covered facet filterable entries by attribute string in MapSet to support new atoms safely

requirements-completed: [FACET-01]

duration: unknown
completed: 2026-04-19
---

# Phase 36 — Plan 02 summary

**Meilisearch settings merge and index contract drift tests now cover dotted hierarchical facet attribute names.**

## Task commits

1. **Tasks 1–2: settings merge + drift** — `00bc51e` (feat)

## Self-Check: PASSED

- `mix test test/scrypath/meilisearch/settings_test.exs test/scrypath/operator/index_contract_drift_test.exs`

## Deviations

None.
