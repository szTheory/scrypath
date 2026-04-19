---
phase: 034-golden-path-readme-and-ci-alignment
plan: "01"
subsystem: docs
tags: [readme, golden-path, adoption, contract-test]

key-files:
  created: []
  modified:
    - README.md
    - test/scrypath/docs_contract_test.exs

requirements-completed: [ADPT-01, ADPT-03]

duration: 15min
completed: 2026-04-19
---

# Phase 34 plan 01 summary

Slimmed **README** Quick Path to a single canonical schema micro-snippet with **`field :status, :string`**, prose for the three-layer shape, and a CTA into **`guides/golden-path.md`**. Contract tests now assert the new README anchors and add explicit README ↔ golden-path status parity.

## Task commits

1. **README Quick Path** — `217596a` (feat)
2. **docs_contract_test** — `6c34712` (test)

## Self-Check: PASSED

- `mix test test/scrypath/docs_contract_test.exs` green after plan 01 commits.
