---
phase: 28
plan: 02
subsystem: docs
tags: [operator, drift-recovery]

requires: ["028-01"]
provides:
  - "Drift recovery vs settings.diff vs reconcile/reindex guidance"
  - "operator-support first-response ordering + verify.phase28 callout"
affects: [phase-28]

tech-stack:
  added: []
  patterns:
    - "Cross-link operator-support from drift-recovery; avoid duplicate matrices"

key-files:
  created: []
  modified:
    - guides/drift-recovery.md
    - docs/operator-support.md
    - guides/operator-mix-tasks.md

requirements-completed: [OPS15-03]

duration: 20min
completed: 2026-04-18
---

# Phase 28 Plan 02 Summary

Extended **drift-recovery**, **operator-support**, and **operator-mix-tasks** so operators can choose **index contract drift** vs **settings-only diff**, **reconcile**, and **reindex**, with **`mix verify.phase28`** in the maintainer verify table.

## Self-Check: PASSED

- `mix test test/scrypath/docs_contract_test.exs`
