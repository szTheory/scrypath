---
phase: 53-contributor-opsui-verify-spine
plan: "01"
subsystem: testing
tags: [mix, exdoc, opsui, contributing]

requires: []
provides:
  - Contributor-visible moduledoc for mix verify.opsui with CONTRIBUTING handoff
affects: []

tech-stack:
  added: []
  patterns:
    - "Mix verify tasks document CI parity in @moduledoc with a single CONTRIBUTING link"

key-files:
  created: []
  modified:
    - lib/mix/tasks/verify.opsui.ex

key-decisions:
  - "Linked CONTRIBUTING.md from repo root for mix help / ExDoc readability"

patterns-established:
  - "OpsUI verify task documents scrypath-ops job, path gate, Postgres-only prereqs, and non-interactive mix sequence"

requirements-completed:
  - VRFY-04

duration: 15min
completed: 2026-04-22
---

# Phase 53: Contributor OPSUI verify spine — Plan 01

**`mix verify.opsui` now ships a short `@moduledoc` so `mix help` lists the task and help output defers the verify matrix to CONTRIBUTING.**

## Performance

- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Replaced `@moduledoc false` with a bounded moduledoc aligned to `Verify.Phase11` layout (`use Mix.Task`, `@shortdoc`, `@moduledoc`).
- Documented CI parity (`scrypath-ops`), path-gate paths, `CI=true` + `printf` guard, Postgres-only / no Meilisearch, and no arguments.

## Task Commits

1. **Add @moduledoc to verify.opsui** — (see git log for hash)

## Files Created/Modified

- `lib/mix/tasks/verify.opsui.ex` — moduledoc + task listing for Hex/Mix help

## Decisions Made

- Used `[CONTRIBUTING.md](CONTRIBUTING.md)` as the single matrix handoff link.

## Deviations from Plan

None - plan executed as written.

## Issues Encountered

- `mix format --check-formatted` initially failed on unrelated `scrypath_ops` drift already in the working tree; ran `mix format` to satisfy the gate without staging non-phase files.

## Self-Check: PASSED

- Acceptance greps and `mix compile --warnings-as-errors`, `mix help verify.opsui`, and `mix test test/scrypath/docs_contract_test.exs` (after plan 03) verified.

---
*Phase: 53-contributor-opsui-verify-spine*
