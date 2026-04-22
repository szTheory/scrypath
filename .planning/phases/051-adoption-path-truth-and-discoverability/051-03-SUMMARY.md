---
phase: 051-adoption-path-truth-and-discoverability
plan: "03"
subsystem: testing
tags: [docs-contract, ci, example-readme]

requires: [051-01, 051-02]
provides:
  - ExUnit locks README sync-authority wording and CONTRIBUTING vs ci.yml ordering
  - Example README documents phoenix-example-integration mix deps.get + mix test
affects: []

key-files:
  created: []
  modified:
    - test/scrypath/docs_contract_test.exs
    - examples/phoenix_meilisearch/README.md

key-decisions:
  - "Extended existing CI workflow test with ordered mix steps; added focused Phase 51 tests"
  - "Separate commits for workflow_wiring + TasksTest stability (regression gate green)"

requirements-completed: [ONBD-01, ONBD-03]

duration: 25min
completed: 2026-04-21
---

# Phase 51 — Plan 03 summary

**Doc contracts now fail if README loses sync-modes authority language, if CONTRIBUTING or `ci.yml` drift on Phoenix example Mix ordering, or if the example README omits the CI mix entrypoint.**

## Task commits

1. **ExUnit — README sync authority invariant** — `c671dd6` (with CI job ordering assertions in same file)
2. **Example README — CI mix entrypoint honesty** — `5864a8a`
3. **Suite stability (outside plan `files_modified`)** — `6ddbdb2` (`workflow_wiring_test` log depth, `tasks_test` poll timeout)

## Verification

- `mix test test/scrypath/docs_contract_test.exs` — PASS (44 tests)
- `mix test --exclude integration` — PASS (411 tests)

## Self-Check: PASSED
