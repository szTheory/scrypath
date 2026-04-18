---
phase: 27
plan: 02
subsystem: operator
tags: [reconcile, elixir]

requires:
  - plan: 01
    provides: IndexContractDrift builder and report struct
provides:
  - Optional `include_index_contract_drift` operator opt-in
  - `index_contract_drift` field on `%Reconcile{}` (not in `@enforce_keys`)
affects: [phase-28]

tech-stack:
  added: []
  patterns:
    - "Operator-only keyword gated; contract read failures fail the whole reconcile when opt-in is true."

key-files:
  created: []
  modified:
    - lib/scrypath/operator.ex
    - lib/scrypath/operator/reconcile.ex
    - lib/scrypath.ex
    - test/scrypath/operator/reconcile_test.exs

key-decisions:
  - "Propagate `IndexContractDrift.build/2` errors on opt-in so operators never see a false-green reconcile when the contract read fails."

patterns-established: []

requirements-completed: [DRIFT15-01, DRIFT15-02, OPS15-01]

duration: 15min
completed: 2026-04-17
---

# Phase 27 Plan 02 Summary

**Reconcile can optionally attach the same index contract drift report as the standalone API, without changing default reconcile behavior or `%Reconcile{}` enforce keys.**

## Self-Check: PASSED

- `mix compile --warnings-as-errors`
- `mix test test/scrypath/operator/reconcile_test.exs test/scrypath/operator/index_contract_drift_test.exs`

## Accomplishments

- `:include_index_contract_drift` on `@operator_only_opts`; documented on `reconcile_sync/2`.
- `Reconcile.run/3` calls `IndexContractDrift.build/2` only when opted in; defaults `index_contract_drift: nil`.
- Tests for default nil, opt-in success, and propagated 404.

## Deviations

- None material.
