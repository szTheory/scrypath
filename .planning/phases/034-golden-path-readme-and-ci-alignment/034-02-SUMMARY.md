---
phase: 034-golden-path-readme-and-ci-alignment
plan: "02"
subsystem: docs
tags: [golden-path, ci, contract-test, verification]

key-files:
  created: []
  modified:
    - guides/golden-path.md
    - test/scrypath/docs_contract_test.exs

requirements-completed: [ADPT-02, ADPT-03, VRFY-01]

duration: 10min
completed: 2026-04-19
---

# Phase 34 plan 02 summary

Replaced the golden path **Integration smoke** “local / optional CI wiring” bullet with prose aligned to **`.github/workflows/ci.yml`**: **`phoenix-example-integration`** on **pull requests** and pushes to **`main`**, **Postgres 16**, **Meilisearch v1.15**, env vars (**`SCRYPATH_EXAMPLE_INTEGRATION`**, **`PGPORT`**, **`SCRYPATH_MEILISEARCH_URL`**), and **`mix test`** under **`examples/phoenix_meilisearch`**. Added optional production note on **`status`** validation vs string filters. Retired **`optional CI wiring`** from **`docs_contract_test.exs`** and locked stable CI substrings.

## Task commits

1. **guides + tests** — `cce5f3c` (docs)

## Self-Check: PASSED

- `mix test test/scrypath/docs_contract_test.exs` green; **`optional CI wiring`** absent from README, golden path, and contract test source.
