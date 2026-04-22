---
phase: 63-bounded-team-persistence-and-security-posture
plan: "02"
subsystem: testing
tags: [elixir, mix, playbook, opsui]

requires: []
provides:
  - mix scrypath_ops.playbooks.validate for CI/GitOps directory checks
  - example v1 playbooks under examples/playbooks
affects: []

tech-stack:
  added: []
  patterns:
    - "Mix task: expand directory, non-recursive Store.safe_basename? JSON only, fail-fast on first invalid file"

key-files:
  created:
    - scrypath_ops/lib/mix/tasks/scrypath_ops/playbooks/validate.ex
    - scrypath_ops/examples/playbooks/search_minimal.json
    - scrypath_ops/examples/playbooks/search_many_minimal.json
    - scrypath_ops/test/scrypath_ops/mix/playbooks_validate_test.exs
  modified: []

key-decisions:
  - "Nested mix invocations use full System.get_env merge with MIX_ENV=test for subprocess fidelity"

patterns-established:
  - "Operator playbook corpus validation without Meilisearch or app.start"

requirements-completed:
  - OPS2-04

duration: 15min
completed: 2026-04-22
---

# Phase 63: Plan 02 Summary

**Shipped an opt-in Mix task and golden example JSON so teams can validate a flat playbook directory against `Playbook.V1` in CI without Meilisearch.**

## Self-Check: PASSED

- `mix test scrypath_ops/test/scrypath_ops/mix/playbooks_validate_test.exs`
- `cd scrypath_ops && mix scrypath_ops.playbooks.validate examples/playbooks`

## Task Commits

1. **Task 63-02-01** — single commit below (one task in plan).

## Files Created/Modified

- `scrypath_ops/lib/mix/tasks/scrypath_ops/playbooks/validate.ex` — `mix scrypath_ops.playbooks.validate DIR`
- `scrypath_ops/examples/playbooks/search_minimal.json` — minimal `search` example
- `scrypath_ops/examples/playbooks/search_many_minimal.json` — two-entry `search_many` example
- `scrypath_ops/test/scrypath_ops/mix/playbooks_validate_test.exs` — subprocess smoke + invalid fixture exit 1

## Deviations

None.
