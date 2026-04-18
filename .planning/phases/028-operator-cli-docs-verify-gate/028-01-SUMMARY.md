---
phase: 28
plan: 01
subsystem: operator
tags: [mix, cli, index-contract-drift]

requires: []
provides:
  - "`mix scrypath.index.contract_drift` delegating to `Scrypath.index_contract_drift/2`"
  - "Exit 0 / 2 / 1 aligned with `mix scrypath.settings.diff`"
affects: [phase-28]

tech-stack:
  added: []
  patterns:
    - "OperatorTask.parse! + Config.resolve! + test_operator_opts mirror settings.diff"

key-files:
  created:
    - lib/mix/tasks/scrypath/index/contract_drift.ex
    - test/support/contract_drift_cli_drift.exs
  modified:
    - mix.exs
    - test/scrypath/mix_tasks/operator_tasks_test.exs

key-decisions:
  - "Drift exit 2 tested via `mix run` subprocess to avoid `System.halt/1` terminating ExUnit."

patterns-established:
  - "Sparse human output: explicit `Index contract OK` line on parity; mismatch-only lines + footer on drift."

requirements-completed: [OPS15-02]

duration: 45min
completed: 2026-04-18
---

# Phase 28 Plan 01 Summary

Shipped the read-only **`mix scrypath.index.contract_drift`** Mix task with **`--json`**, parity/drift human formatting, and ExUnit coverage (including subprocess exit-2 for drift).

## Self-Check: PASSED

- `mix format --check-formatted && mix compile --warnings-as-errors`
- `mix test test/scrypath/mix_tasks/operator_tasks_test.exs`
