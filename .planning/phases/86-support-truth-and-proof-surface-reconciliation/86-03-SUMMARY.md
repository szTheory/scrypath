---
phase: 86-support-truth-and-proof-surface-reconciliation
plan: 03
subsystem: planning-truth
tags: [planning, docs-contract, archive-classification]
requires: [TRUTH-01, TRUTH-02]
provides:
  - branch-tip-vs-history wording for v1.20 SearchModule archive drift
  - bounded docs-contract coverage for support authority and verify.adopter parity
  - refreshed JTBD gap-map truth after Phase 86 repairs
affects: [phase-86, planning, docs, tests]
tech-stack:
  added: []
  patterns: [active-file truth, archive classification notes, bounded string/order assertions]
key-files:
  created: []
  modified: [.planning/STATE.md, .planning/MILESTONES.md, .planning/ROADMAP.md, .planning/milestones/v1.20-ROADMAP.md, .planning/milestones/v1.20-MILESTONE-AUDIT.md, docs/jtbd-gap-map.md, test/scrypath/docs_contract_test.exs]
key-decisions:
  - "Corrected active planning files first, then added minimal historical classification notes to the v1.20 archive instead of rewriting archive history as if the milestone never closed that way."
  - "Extended `docs_contract_test.exs` only around the repaired seams: support authority discoverability, verify.adopter parity, and explicit branch-tip absence of SearchModule."
patterns-established:
  - "Use active planning files for branch-tip truth and archive notes for history classification when code and archive claims diverge."
requirements-completed: [TRUTH-03]
duration: 1 session
completed: 2026-05-24
---

# Phase 86 Plan 03: Support Truth And Proof Surface Reconciliation Summary

**Active planning now distinguishes branch-tip truth from archive history, and the repaired seams are under contract**

## Accomplishments

- Updated active planning files to state that the support/readiness guide and `verify.adopter` fast seam are restored on branch tip, while the `v1.20` `SearchModule` story remains historical/archive-backed rather than currently shipped.
- Added small classification notes to the `v1.20` roadmap and audit archives so future readers can tell the difference between milestone-close claims and present-day checkout truth.
- Extended `test/scrypath/docs_contract_test.exs` to cover the restored support authority, `verify.adopter` contract parity, and the current JTBD/search-module truth wording.

## Files Created/Modified

- `.planning/STATE.md` - Updated support/proof drift items to resolved-at-branch-tip language and kept the SearchModule mismatch explicit.
- `.planning/MILESTONES.md` - Reframed `v1.20` bullets as archive history with a branch-tip note.
- `.planning/ROADMAP.md` - Added a branch-tip truth note for the current milestone.
- `.planning/milestones/v1.20-ROADMAP.md` - Added archive classification note and historical wording.
- `.planning/milestones/v1.20-MILESTONE-AUDIT.md` - Added historical classification note.
- `docs/jtbd-gap-map.md` - Replaced stale support-drift caveat with current Phase 86 truth.
- `test/scrypath/docs_contract_test.exs` - Added bounded guards for support authority and verify.adopter parity; updated reviewed-date expectation.

## Verification

- `rg -n "SearchModule|support-and-compatibility|outside-adopter evidence|defended in-repo proof|archive claims|historical|does not currently expose|checked-out code does not expose" .planning/STATE.md .planning/MILESTONES.md .planning/ROADMAP.md .planning/milestones/v1.20-ROADMAP.md .planning/milestones/v1.20-MILESTONE-AUDIT.md docs/jtbd-gap-map.md`
- `mix test test/scrypath/docs_contract_test.exs`
- `mix docs --warnings-as-errors`

## Task Commits

No commits were created during this execution run.

## Issues Encountered

- `test/scrypath/docs_contract_test.exs` initially failed on the stale JTBD reviewed-date expectation. The contract was updated alongside the repaired branch-tip wording.

## Next Phase Readiness

Phase 86's support/proof surfaces are reconciled, and the next milestone step can move to outside-adopter intake and evidence review instead of more internal truth repair.

---
*Phase: 86-support-truth-and-proof-surface-reconciliation*
*Completed: 2026-05-24*
