---
phase: 53-contributor-opsui-verify-spine
plan: "02"
subsystem: testing
tags: [readme, opsui, contributing]

requires:
  - plan: "01"
    provides: Moduledoc and task behavior context for contributors
provides:
  - README sentence surfacing mix verify.opsui next to scrypath_ops maintainer links
affects: []

tech-stack:
  added: []
  patterns:
    - "README operator UI section links CONTRIBUTING for CI matrix without duplicating tables"

key-files:
  created: []
  modified:
    - README.md

key-decisions:
  - "Extended existing Operator UI maintainer bullet to keep wayfinding in one place"

patterns-established: []

requirements-completed:
  - VRFY-04

duration: 10min
completed: 2026-04-22
---

# Phase 53 — Plan 02

**README now names `mix verify.opsui` beside `scrypath_ops/` maintainer docs and points to CONTRIBUTING for job names.**

## Performance

- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Added one sentence with literal `mix verify.opsui`, `scrypath_ops/`, `scrypath-ops`, and a `](CONTRIBUTING.md)` markdown link matching the integration-smoke link style.

## Task Commits

1. **README — verify.opsui sentence + CONTRIBUTING link** — (see git log)

## Files Created/Modified

- `README.md`

## Decisions Made

- Kept the addition on the Operator UI line to satisfy same-paragraph / 3-line proximity to `scrypath_ops`.

## Deviations from Plan

None.

## Issues Encountered

None.

## Self-Check: PASSED

- README acceptance greps satisfied; full docs contract suite green after plan 03.

---
*Phase: 53-contributor-opsui-verify-spine*
