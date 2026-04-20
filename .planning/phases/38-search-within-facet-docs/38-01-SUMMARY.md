---
phase: 38-search-within-facet-docs
plan: "01"
subsystem: search
tags: [faceting, meilisearch, telemetry]

requires: []
provides:
  - "Scrypath.search_within_facet/4 and search_within_facet!/4 on the common search pipeline"
  - "do_search/5 threading for telemetry extras"
affects: []

tech-stack:
  added: []
  patterns:
    - "Scoped facet bucket merged into facet_filter: before validate_search_options/2; duplicate attribute raises ArgumentError with search_within_facet: prefix"

key-files:
  created:
    - "test/scrypath/search_within_facet_test.exs"
  modified:
    - "lib/scrypath/search.ex"
    - "lib/scrypath.ex"

key-decisions:
  - "Extended [:scrypath, :search] metadata with search_scope: :within_facet and scoped_facet instead of a second event"

patterns-established:
  - "Caller opts preserved for Config.resolve!(runtime_opts/1) while Query.new uses validated search options"

requirements-completed:
  - "FACET-03"

duration: 25min
completed: 2026-04-20
---

# Phase 38 — Plan 01 summary

Delivered **`search_within_facet/4`** / **`!`** as thin delegates over the existing validated search path, **`do_search/5`** for optional telemetry extras, and **Req.Test** coverage for composed Meilisearch JSON plus duplicate-attribute rejection.

## Task commits

Implemented as one integration commit with the repository (atomic per-phase delivery).

## Self-Check: PASSED

- `mix compile --warnings-as-errors`
- `mix test test/scrypath/search_within_facet_test.exs`
