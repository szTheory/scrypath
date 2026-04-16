---
phase: 09-public-docs-and-example-safety
plan: 01
subsystem: docs
tags: [readme, guides, install-contract, docs-tests]
requires: []
provides:
  - narrowed public install snippet
  - explicit optional Oban guidance outside the base install path
  - executable docs contract coverage for transport and queue wording
affects: [readme, guides, public-adoption]
tech-stack:
  added: []
  patterns: [direct-dependency install fences, string-exact docs contract assertions]
key-files:
  created:
    - .planning/phases/09-public-docs-and-example-safety/09-01-SUMMARY.md
  modified:
    - README.md
    - guides/getting-started.md
    - test/scrypath/docs_contract_test.exs
key-decisions:
  - "The canonical install snippet now exposes only `{:scrypath, \"~> 0.1.0\"}` as the public dependency contract."
  - "Oban guidance stays explicit but optional, and transport details stay outside the base install fence."
patterns-established:
  - "Install-adjacent docs reinforce that Scrypath owns its internal transport dependency."
  - "Docs contract tests refute `:req` in the README install path and require optional queue wording."
requirements-completed: [DOCS-01]
duration: 12min
completed: 2026-04-16
---

# Phase 09: Public Docs and Example Safety Summary

**The public install path now teaches Scrypath as the only direct dependency, with backend/runtime setup and optional Oban guidance kept outside the base install fence**

## Performance

- **Duration:** 12 min
- **Started:** 2026-04-16T18:08:00Z
- **Completed:** 2026-04-16T18:20:00Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Removed `{:req, "~> 0.5"}` from the canonical README dependency snippet so copied install steps match the real consumer contract.
- Tightened getting-started language so backend/runtime choices remain explicit and `sync_mode: :oban` stays clearly optional.
- Added exact docs contract assertions that lock the direct dependency boundary and optional queue wording.

## Task Commits

Each task was committed atomically:

1. **Task 1: Narrow the public install snippet to direct Scrypath-only setup per D-01 through D-04** - `199ce7f` (docs)
2. **Task 2: Lock the install contract in docs tests so drift is caught automatically** - `891548e` (test)

## Files Created/Modified
- `README.md` - narrows the install snippet to `:scrypath` only and moves transport/optional queue guidance into prose.
- `guides/getting-started.md` - reinforces that Scrypath owns the transport dependency and that Oban is an optional sync path.
- `test/scrypath/docs_contract_test.exs` - refutes `:req` in the install path and requires explicit optional queue wording.

## Decisions Made
- Kept Meilisearch-first positioning in prose rather than widening the dependency snippet again.
- Reused the existing docs contract test harness instead of adding a separate install-doc review layer.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
The plan’s `mix test ... -x` example is stale for the current Mix version. Verification ran with `--trace`.

## User Setup Required

None.

## Next Phase Readiness
The base install contract is now copy-paste safe, so Phase 09-02 can harden the JSON controller example without carrying install-surface drift forward.

## Self-Check: PASSED

---
*Phase: 09-public-docs-and-example-safety*
*Completed: 2026-04-16*
