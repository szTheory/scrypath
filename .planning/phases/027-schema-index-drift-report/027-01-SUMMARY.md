---
phase: 27
plan: 01
subsystem: operator
tags: [meilisearch, drift, elixir]

requires: []
provides:
  - Read-only index contract drift report (`IndexContractDrift.Report`)
  - `Scrypath.index_contract_drift/2` and `Operator.index_contract_drift/2`
affects: [phase-28]

tech-stack:
  added: []
  patterns:
    - "Single `get_settings` per drift build; settings slice uses `Settings.resolve/2`, `translate_settings/1`, `compute_drift/2`"

key-files:
  created:
    - lib/scrypath/operator/index_contract_drift/report.ex
    - lib/scrypath/operator/index_contract_drift.ex
    - test/scrypath/operator/index_contract_drift_test.exs
  modified:
    - lib/scrypath/operator.ex
    - lib/scrypath.ex

key-decisions:
  - "Faceting dimension compares normalized declared projection vs live `faceting` object (empty schema faceting matches empty or omitted live object)."
  - "Non-Meilisearch backends return `{:error, :unsupported_backend}` from `build/2`."

patterns-established:
  - "Dimension structs carry `match` and bounded `details` for DRIFT15-02 without dumping full Meilisearch payloads."

requirements-completed: [DRIFT15-01, DRIFT15-02, OPS15-01]

duration: 25min
completed: 2026-04-17
---

# Phase 27 Plan 01 Summary

**Operators get a typed, JSON-stable declared-vs-live index contract report with named dimensions and explicit settings drift tuples.**

## Self-Check: PASSED

- `mix format --check-formatted`
- `mix compile --warnings-as-errors`
- `mix test test/scrypath/operator/index_contract_drift_test.exs`

## Accomplishments

- Versioned `%Report{}` with `Jason.Encoder` and stable field order.
- Pure dimension comparers plus one orchestrated live `get_settings` read.
- ExUnit coverage for parity, settings drift, 404, and JSON round-trip.

## Deviations

- None material.
