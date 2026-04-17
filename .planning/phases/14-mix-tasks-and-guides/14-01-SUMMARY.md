---
phase: 14-mix-tasks-and-guides
plan: 01
subsystem: cli
tags: [elixir, mix, operator, docs]
requires:
  - phase: 13-operator-primitives
    provides: "Root-level status, failed-work, retry, and reconcile operator APIs."
provides:
  - "Thin `mix scrypath.*` wrappers over the root operator APIs"
  - "Focused task tests for delegation, explicit retry, and report-first reconcile output"
affects: [phase-14-mix-tasks-and-guides]
tech-stack:
  added: []
  patterns: ["Mix tasks stay thin and delegate through `Scrypath.*`"]
key-files:
  created:
    - lib/scrypath/cli/operator_task.ex
    - lib/mix/tasks/scrypath.status.ex
    - lib/mix/tasks/scrypath.failed.ex
    - lib/mix/tasks/scrypath.retry.ex
    - lib/mix/tasks/scrypath.reconcile.ex
    - test/scrypath/mix_tasks/operator_tasks_test.exs
key-decisions:
  - "Keep the CLI layer thin and formatting-focused while reusing the existing root operator APIs for all semantics."
  - "Require explicit failed-work ids for retry and explicit actions for reconcile."
patterns-established:
  - "Operator Mix tasks can use a small shared helper while keeping backend-native details out of CLI output."
requirements-completed: [SEAM-03]
completed: 2026-04-16
---

# Phase 14 Plan 01 Summary

Added four thin Mix tasks on top of the Phase 13 operator surface:

- `mix scrypath.status`
- `mix scrypath.failed`
- `mix scrypath.retry`
- `mix scrypath.reconcile`

The task layer starts the app, parses task-owned argv, delegates through `Scrypath.*`, and renders stable operator-facing output without exposing raw backend or queue internals.

## Verification

- `mix test test/scrypath/mix_tasks/operator_tasks_test.exs` -> PASS

## Notes

- Retry remains explicit and id-driven.
- Reconcile remains report-first unless an explicit action is requested.

## Self-Check: PASSED
