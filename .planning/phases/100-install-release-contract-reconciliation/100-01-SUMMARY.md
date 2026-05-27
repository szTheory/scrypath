---
phase: 100-install-release-contract-reconciliation
plan: 01
subsystem: docs
tags: [contracts, release-truth, install-token, intake]
requires:
  - phase: 99-drift-gates-and-ci-enforcement
    provides: deterministic trust-lane contract enforcement
provides:
  - "Canonical install/release truth wording on support authority"
  - "Intake/template evidence boundary parity for package vs repo proof"
  - "Route-first release-truth language on README and CONTRIBUTING"
affects: [README, CONTRIBUTING, support-and-compatibility, outside-adopter-intake, outside-adopter-evidence-template]
tech-stack:
  added: []
  patterns: ["route-first authority boundaries", "exact token contract wording"]
key-files:
  created: []
  modified:
    - guides/support-and-compatibility.md
    - guides/outside-adopter-intake.md
    - docs/templates/outside-adopter-evidence.md
    - README.md
    - CONTRIBUTING.md
key-decisions:
  - "Keep normative install/release policy in guides/support-and-compatibility.md only."
  - "Require exact Hex package version or exact git ref/commit wording on intake evidence surfaces."
patterns-established:
  - "Entry surfaces route to authority instead of duplicating policy matrices."
  - "Install/release trust wording is anchored with exact low-noise tokens."
requirements-completed: [TRUTH-01, TRUTH-02]
duration: 2min
completed: 2026-05-27
---

# Phase 100 Plan 01: Install/release wording reconciliation summary

**Reconciled install and release-truth language across owner and intake surfaces so adopter guidance uses one release-backed contract.**

## Performance

- **Duration:** 2 min
- **Started:** 2026-05-27T12:15:00Z
- **Completed:** 2026-05-27T12:17:30Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments
- Added a canonical install and release-truth micro-contract section in `guides/support-and-compatibility.md`, including `{:scrypath, "~> 0.3"}`.
- Replaced intake's conflicting `{:scrypath, "~> 1.0"}` token and added exact evidence-boundary wording in intake/template surfaces.
- Added concise route-first release-truth tokens to `README.md` and `CONTRIBUTING.md` while preserving proof-path command references.

## Task Commits

Each task was committed atomically:

1. **Task 100-01-01: Canonicalize install/release contract on support authority** - `ba5bdcb` (chore)
2. **Task 100-01-02: Reconcile intake and evidence template tokens** - `3819320` (chore)
3. **Task 100-01-03: Route README and CONTRIBUTING to canonical owner** - `49d53a5` (chore)

**Plan metadata:** pending

## Files Created/Modified
- `guides/support-and-compatibility.md` - canonical install token and release/main truth micro-contract.
- `guides/outside-adopter-intake.md` - aligned install token and explicit package-vs-repo evidence wording.
- `docs/templates/outside-adopter-evidence.md` - explicit exact version/ref requirement language.
- `README.md` - route-first release-truth note pointing to canonical owner surface.
- `CONTRIBUTING.md` - maintainer-facing release-truth routing note matching owner policy.

## Decisions Made
- Kept full normative policy text in the support guide and kept other surfaces route-first.
- Locked explicit wording tokens for release-backed guidance and unreleased `main` behavior to support deterministic drift checks.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
Wave 2 can now add deterministic TRUTH-01/TRUTH-02 assertions against stabilized docs tokens.

---
*Phase: 100-install-release-contract-reconciliation*
*Completed: 2026-05-27*
