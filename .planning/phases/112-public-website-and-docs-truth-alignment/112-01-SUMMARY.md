---
phase: 112-public-website-and-docs-truth-alignment
plan: 01
subsystem: docs
tags: [readme, exdoc, scope-policy, support-routing]
requires:
  - phase: 110-support-intake-and-evidence-routing
    provides: support and outside-adopter evidence routing authorities
provides:
  - canonical public scope and reopen policy guide
  - ExDoc publication wiring for scope policy guide
  - route-first scope policy pointers from README/support/intake surfaces
affects: [WEB-01, SCOPE-01, public-docs]
tech-stack:
  added: []
  patterns: [single-policy-authority, route-first-doc-surfaces]
key-files:
  created:
    - guides/scope-and-reopen-policy.md
  modified:
    - mix.exs
    - README.md
    - guides/support-and-compatibility.md
    - guides/outside-adopter-intake.md
key-decisions:
  - "Kept scope/reopen policy single-sourced in one new guide and routed all pressure to it."
  - "Used compact pointer language on README/support/intake to avoid duplicated policy bodies."
patterns-established:
  - "Public scope authority: one canonical guide, many route links."
requirements-completed: [WEB-01, SCOPE-01]
duration: 16m
completed: 2026-06-01
---

# Phase 112 Plan 01: Public Scope Authority Summary

**Published a single canonical scope/reopen policy guide and routed README/support/intake scope pressure to that authority with ExDoc navigation wiring.**

## Performance

- **Duration:** 16 min
- **Started:** 2026-06-01T15:58:00Z
- **Completed:** 2026-06-01T16:13:58Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- Added `guides/scope-and-reopen-policy.md` as the single public scope and feature-lane reopen authority.
- Registered the new guide in ExDoc `extras` and `Getting Started` groups so published docs links resolve.
- Updated README, support, and outside-adopter intake surfaces to route scope pressure to the policy owner.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create the canonical scope-and-reopen policy guide and publish it in ExDoc** - `b65e2c7` (docs)
2. **Task 2: Route README, support guidance, and intake guidance to the new policy owner** - `8c3035e` (docs)

## Files Created/Modified
- `guides/scope-and-reopen-policy.md` - Canonical public scope/reopen authority with exact trigger and out-of-scope classes.
- `mix.exs` - ExDoc extras and `Getting Started` guide-group registration for the new policy guide.
- `README.md` - Compact route-first scope/reopen pointer with the three allowed triggers.
- `guides/support-and-compatibility.md` - Scope-boundary routing to canonical policy guide.
- `guides/outside-adopter-intake.md` - Explicit evidence-lane reopen path through canonical policy guide.

## Decisions Made
- Kept policy authority centralized in one guide and avoided duplicate policy bodies across route surfaces.
- Preserved existing support/install authority and Class A-D intake structure while adding scope-lane routing language.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None.

## Next Phase Readiness

- Ready for subsequent Phase 112 plans to reference a single public scope/reopen authority.
- No blockers identified for this phase from Plan 01 work.

## Self-Check: PASSED

- Verified created file exists: `guides/scope-and-reopen-policy.md`
- Verified task commits exist: `b65e2c7`, `8c3035e`
- Verified required checks passed: `mix docs --warnings-as-errors`

