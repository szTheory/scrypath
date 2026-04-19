---
phase: 29
plan: 01
subsystem: docs
tags: [adoption, golden-path, exdoc]

requires: []
provides:
  - "`guides/golden-path.md` linear ADPT-01 checklist (inline sync + `Scrypath.search/3`)"
  - "ExDoc extras + Getting Started group registration"
affects: [phase-29]

tech-stack:
  added: []
  patterns:
    - "README Start here → golden path; getting-started links forward"

key-files:
  created:
    - guides/golden-path.md
  modified:
    - mix.exs
    - guides/getting-started.md
    - README.md

key-decisions:
  - "Golden path defers Oban/manual to sync guide; Ecto-without-Phoenix subsection included."

patterns-established:
  - "Literal `guides/...` path strings where automation greps for repo-relative hygiene."

requirements-completed: [ADPT-01]

duration: inline
completed: 2026-04-18
---

# Phase 29 Plan 01 Summary

Added **`guides/golden-path.md`** (install → Meilisearch → config → schema → context `sync_mode: :inline` → IEx search proof), registered it in **`mix.exs`** ExDoc extras and the Getting Started group, cross-linked from **`guides/getting-started.md`**, and added a README **Start here** pointer after Installation.

## Self-Check: PASSED

- Plan task acceptance greps (golden-path content strings)
- `mix format --check-formatted && MIX_ENV=test mix docs --warnings-as-errors`
