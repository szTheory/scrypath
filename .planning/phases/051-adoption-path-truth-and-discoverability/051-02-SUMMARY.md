---
phase: 051-adoption-path-truth-and-discoverability
plan: "02"
subsystem: docs
tags: [contributing, ci, onboarding]

requires: []
provides:
  - CONTRIBUTING CI table matches phoenix-example-integration job (deps.get before mix test)
  - Contributor pointer block for first hour, sync authority, and docs_contract_test
affects: [051-03]

key-files:
  created: []
  modified:
    - CONTRIBUTING.md

key-decisions:
  - "Single CI table row documents both Mix sequence and smoke.sh as non-CI driver"

requirements-completed: [ONBD-02, ONBD-03]

duration: 12min
completed: 2026-04-21
---

# Phase 51 — Plan 02 summary

**CONTRIBUTING now mirrors `phoenix-example-integration` in `ci.yml` and orients contributors to the same first-hour and sync-authority docs as the README.**

## Task commits

1. **CI table — phoenix-example-integration exact steps** — `1a60b73`
2. **First-hour narrative + sync / doc pointer block** — `4edac8a`
3. **Smoke.sh vs CI wording pass** — `62b639b`

## Verification

- `mix test test/scrypath/docs_contract_test.exs` — PASS

## Self-Check: PASSED
