---
phase: 18-release-parity-gate-node-20-ci-cleanup
plan: 04
subsystem: infra
tags: [ci, github-actions, node-20, node-24, pin-swap, infra-03]

# Dependency graph
requires:
  - phase: 18-release-parity-gate-node-20-ci-cleanup
    provides: "Plan 18-01 authored the INFRA-03 describe block in workflow_wiring_test.exs (the RED tests this plan drives to GREEN)"
provides:
  - "ci.yml pinned to Node-24-ready actions/checkout@v6 + actions/cache@v5 on all 4 jobs"
  - "INFRA-03 describe block in test/mix/tasks/workflow_wiring_test.exs passes (4 tests, 0 failures)"
  - "ROADMAP Phase 18 Success Criterion #3 met"
affects: [18-05, 18-06, 18-07, v1.3-feature-phases]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Pin-swap discipline: one replace_all Edit per action family keeps diff surgical and reviewable"

key-files:
  created: []
  modified:
    - .github/workflows/ci.yml

key-decisions:
  - "Plan scope restricted to ci.yml per D-13; sibling workflows already on target pins"
  - "Plan-05 retains sole ownership of the new workspace_clean step insertion; Plan-04 is pin-swap-only to keep diffs reviewable in isolation"

patterns-established:
  - "Pin-only substitutions should use Edit tool replace_all mode (2 edits cover 8 line swaps cleanly)"
  - "git diff --numstat N\\tN\\t<file> is the invariant for pure line-level substitutions"

requirements-completed: [INFRA-03]

# Metrics
duration: 2min
completed: 2026-04-17
---

# Phase 18 Plan 04: Swap ci.yml @v4 pins to Node-24-ready versions Summary

**Swapped 4× actions/checkout@v4 → @v6 and 4× actions/cache@v4 → @v5 across all four ci.yml jobs, clearing GitHub Actions Node 20 deprecation warnings and turning the INFRA-03 describe block green.**

## Performance

- **Duration:** 2 min
- **Started:** 2026-04-17T13:55:20Z
- **Completed:** 2026-04-17T13:57:04Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments
- All 8 legacy `@v4` pins in `.github/workflows/ci.yml` replaced with Node-24-ready versions (4× `actions/checkout@v6`, 4× `actions/cache@v5`)
- All four CI jobs now on current pins: `test` (matrix), `quality`, `phase5-verification`, `phase13-verification`
- INFRA-03 describe block (`INFRA-03 D-13: ci.yml action pins on Node 24 runtime`) turned from 4 failures → 4 passes
- ROADMAP Phase 18 Success Criterion #3 satisfied (zero Node 20 deprecation warnings on `actions/checkout` and `actions/cache` pins)
- Line-count invariant preserved: `git diff --numstat` reports `8\t8\t.github/workflows/ci.yml` (pure substitution, no insertions/deletions)
- Zero collateral changes: no other workflow files (`publish-hex.yml`, `release-please.yml`, `verify-published-release.yml`) touched

## Task Commits

Each task was committed atomically:

1. **Task 1: Swap all 8 @v4 pins in .github/workflows/ci.yml to Node-24-ready pins (INFRA-03)** - `bf116d7` (feat)

## Files Created/Modified
- `.github/workflows/ci.yml` - Swapped 4× `actions/checkout@v4` → `@v6` (lines 29, 56, 114, 161) and 4× `actions/cache@v4` → `@v5` (lines 36, 63, 121, 168); all other bytes unchanged.

## Decisions Made
None — plan executed exactly as written. Both plan-specified approach (two `replace_all` Edits covering 8 line swaps) and scope discipline (no step additions, no sibling-workflow edits) honored.

## Deviations from Plan

None - plan executed exactly as written.

### TDD Gate Compliance

Plan 18-04 inherits the TDD gate sequence from Plan 18-01:
- **RED gate:** Tests were authored in Plan 18-01 (`test(18-01)` commit sequence); pre-edit run confirmed `4 tests, 4 failures` for the INFRA-03 describe block.
- **GREEN gate:** This plan's `feat(18-04): swap 8 @v4 pins ...` commit `bf116d7` flips the INFRA-03 describe to `4 tests, 0 failures`.
- **REFACTOR gate:** Not applicable — pin-swap has no structure to refactor; would be no-op.

## Issues Encountered
- Plan's `must_haves.truths` and `verify.automated` text references "5 tests" for the INFRA-03 describe block; the actual file has 4 tests. The plan's command grep on `4 tests, 0 failures` is correct and matched the real test count. No divergence — test count matches verifier and acceptance criteria; the "5 tests" phrase appears to be a count discrepancy in the plan's narrative, not a functional issue. Verification ran on the real 4-test describe block and all passed.

## Verification Results

**Pre-edit RED state (confirmed):**
```
INFRA-03 D-13: ci.yml action pins on Node 24 runtime
4 tests, 4 failures (11 excluded)
```

**Post-edit GREEN state (confirmed):**
```
INFRA-03 D-13: ci.yml action pins on Node 24 runtime
4 tests, 0 failures (11 excluded)
```

**Acceptance criteria results:**
- `grep -c "actions/checkout@v6" .github/workflows/ci.yml` → 4 ✓
- `grep -c "actions/cache@v5" .github/workflows/ci.yml` → 4 ✓
- `grep -cE "actions/(checkout|cache)@v4" .github/workflows/ci.yml` → 0 ✓
- `git diff --numstat .github/workflows/ci.yml` → `8\t8\t.github/workflows/ci.yml` ✓
- `git status .github/workflows/` lists only `ci.yml` ✓
- Line count preserved (git diff shows 8 insertions + 8 deletions, no structural changes) ✓

## User Setup Required
None - no external service configuration required. Live CI verification (zero Node 20 deprecation warnings on `actions/checkout`/`actions/cache`) is captured in VALIDATION.md §"Manual-Only Verifications" and will be observed on the first PR after merge to main.

## Next Phase Readiness
- Plan 18-05 can now insert the `workspace_clean` step into the `quality` job of ci.yml on top of the Node-24-ready pins without conflict.
- The INFRA-03 describe block is GREEN and will be observed by any subsequent run of `mix test test/mix/tasks/workflow_wiring_test.exs`.
- No blockers introduced; no deferred items created.

## Self-Check: PASSED

**Files created/modified verified:**
- `.github/workflows/ci.yml` — modified, 8 line swaps confirmed via grep counts (checkout@v6=4, cache@v5=4, @v4=0)
- `.planning/phases/18-release-parity-gate-node-20-ci-cleanup/18-04-SUMMARY.md` — this file, created

**Commits verified:**
- `bf116d7` — `feat(18-04): swap 8 @v4 pins in ci.yml to Node-24-ready versions (INFRA-03)` — present in `git log`

---
*Phase: 18-release-parity-gate-node-20-ci-cleanup*
*Completed: 2026-04-17*
