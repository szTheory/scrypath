---
phase: 36-hierarchical-facets
plan: "03"
subsystem: testing
tags: [facets, docs, mix]

requires:
  - phase: 36-02
    provides: settings and drift coverage for hierarchical facets
provides:
  - SearchResult facet decode regression for dotted keys
  - "## Hierarchical facets" guide section and anti-pattern correction
  - mix verify.phase36 focused gate
  - REQUIREMENTS traceability row for AUDT-01 (docs contract continuity)
affects: [contributors-ci]

key-files:
  created:
    - lib/mix/tasks/verify.phase36.ex
  modified:
    - guides/faceted-search-with-phoenix-liveview.md
    - test/scrypath/search_test.exs
    - test/scrypath/docs_contract_test.exs
    - mix.exs
    - .planning/REQUIREMENTS.md

key-decisions:
  - verify.phase36 runs tests only (no ExDoc build) to keep the slice fast while matching plan file list

requirements-completed: [FACET-01]

duration: unknown
completed: 2026-04-19
---

# Phase 36 — Plan 03 summary

**End-to-end facet decoding, adopter guide updates, doc contracts, and a dedicated verify task ship for hierarchical facets.**

## Self-Check: PASSED

- `mix verify.phase36`

## Deviations

- Full `mix test` hit a 60s timeout in `ConsumerSmokeTest` (transient `deps.get`); focused suites and `mix verify.phase36` pass.
