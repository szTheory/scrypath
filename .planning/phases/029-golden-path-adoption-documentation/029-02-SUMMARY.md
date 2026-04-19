---
phase: 29
plan: 02
subsystem: docs
tags: [adoption, readme, releasing, changelog]

requires: [029-01]
provides:
  - "README sync-mode heuristics + authority link in Sync Modes section"
  - "README versioning section; install `~> 0.3`; docs contract alignment"
  - "Adopter note in docs/releasing.md; CHANGELOG Unreleased cross-link"
affects: [phase-29]

tech-stack:
  added: []
  patterns:
    - "CHANGELOG link in README as bold path to satisfy ExDoc --warnings-as-errors"

key-files:
  created: []
  modified:
    - README.md
    - docs/releasing.md
    - CHANGELOG.md
    - test/scrypath/docs_contract_test.exs

key-decisions:
  - "Docs contract test updated from `~> 0.3.0` to `~> 0.3` to match ADPT-03."

patterns-established: []

requirements-completed: [ADPT-02, ADPT-03]

duration: inline
completed: 2026-04-18
---

# Phase 29 Plan 02 Summary

Extended **README** under **Sync Modes** with inline vs Oban vs manual heuristics and an explicit authority pointer to **`guides/sync-modes-and-visibility.md`**. Added **Versioning and upgrades**, aligned the install snippet with **`{:scrypath, "~> 0.3"}`**, linked **`docs/releasing.md`** / **`CHANGELOG.md`** / **`mix verify.phase11`** without duplicating the releasing verify matrix. Added a short **adopter** note atop **`docs/releasing.md`**, a matching **CHANGELOG** Unreleased bullet, and updated **`docs_contract_test.exs`** so **`mix verify.phase11`** stays green.

## Self-Check: PASSED

- Plan acceptance greps (Sync Modes section scope, README strings, CHANGELOG Unreleased)
- `mix format --check-formatted && MIX_ENV=test mix docs --warnings-as-errors && mix verify.phase11`
