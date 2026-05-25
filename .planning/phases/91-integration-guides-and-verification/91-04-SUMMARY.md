---
phase: 91-integration-guides-and-verification
plan: "04"
subsystem: docs
tags: [elixir, scrypath, fan-out, sync_related, docs-contract, guides]

# Dependency graph
requires:
  - phase: 91-03
    provides: Phoenix example fan-out integration with hand-written __scrypath__/1 accessors

provides:
  - Fixed guides/related-data-and-reindexing.md section (a): hand-written accessor pattern replaces broken use Scrypath fan_outs: snippet
  - Prose note explaining use Scrypath macro limitation for fan_outs:
  - Corrected update_author/3 3-tuple return {:ok, result, updated} in guide section (c)
  - Docs-contract test assertions anchoring the working pattern (regression gate)

affects:
  - Any future edits to guides/related-data-and-reindexing.md (contract test now guards pattern)
  - Adopters following the guide: no longer hit ArgumentError on __scrypath__(:fan_outs)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "hand-written __scrypath__(:fan_outs) and __scrypath__(:document_id) declared alongside Ecto.Schema (not via use Scrypath)"
    - "docs-contract test extends assert_contains_all to lock both code pattern and prose note"

key-files:
  created: []
  modified:
    - guides/related-data-and-reindexing.md
    - test/scrypath/docs_contract_test.exs

key-decisions:
  - "Hand-written accessor pattern (not use Scrypath) is the canonical schema declaration for fan_outs — matches author.ex example and hermetic test fixtures"
  - "Prose note with exact wording is part of the docs contract — two strings asserted verbatim in the test"
  - "3-tuple {:ok, result, updated} is the canonical update_author/3 return, matching blog.ex and smoke tests"

patterns-established:
  - "Docs-contract: assert_contains_all locks both the working code pattern AND prose notes explaining macro limitations"

requirements-completed: [EXEC-02, TEST-01, TEST-02]

# Metrics
duration: 8min
completed: 2026-05-25
---

# Phase 91 Plan 04: Gap Closure (CR-01 + WR-02) Summary

**Fixed broken `use Scrypath, fan_outs:` guide snippet with hand-written `def __scrypath__(:fan_outs)` accessor pattern, corrected 3-tuple return value, and added regression-proof docs-contract assertions — `mix verify.phase91` passes at 73 tests, 0 failures.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-05-25T~07:30:00Z
- **Completed:** 2026-05-25
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Replaced broken `use Scrypath, fan_outs: [...]` code block in guide section (a) with the working hand-written accessor pattern (`def __scrypath__(:fan_outs)` + `def __scrypath__(:document_id)`) modelled on `author.ex` lines 33–43
- Added prose note stating: `use Scrypath` does not generate a `__scrypath__(:fan_outs)` accessor — adopters now understand why hand-written accessors are required
- Fixed `update_author/3` return in guide section (c) from `{:ok, updated}` (2-tuple) to `{:ok, result, updated}` (3-tuple) — matches `blog.ex` canonical implementation and smoke test assertions
- Added two new strings to `assert_contains_all` in the existing docs-contract test: the accessor function definition and the prose note — broken pattern cannot silently return without CI failure

## Task Commits

1. **Task 1: Fix guide section (a) + update_author/3 return** — `a45b64e` (fix)
2. **Task 2: Add docs-contract assertions** — `60c08f0` (test)

## Files Created/Modified

- `guides/related-data-and-reindexing.md` — Replaced broken `use Scrypath, fan_outs:` snippet with `def __scrypath__(:fan_outs)` pattern; added `def __scrypath__(:document_id)`; added prose note; fixed 3-tuple return in `update_author/3`
- `test/scrypath/docs_contract_test.exs` — Extended `assert_contains_all` in the existing "related-data guide adopts sync_related/3" test with two new required strings

## Decisions Made

- The `use Scrypath` macro generates reflection for `:config`, `:fields`, `:filterable`, `:faceting`, `:sortable`, `:settings`, `:document_id`, `:document_source`, `:backend` — NOT `:fan_outs`. The guide must teach the hand-written accessor as the only working path.
- The docs-contract assertion uses verbatim substring matching, so the prose note wording in the guide is now authoritative and cannot drift silently.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None. Both edits were targeted; `mix verify.phase91` passed on first run (73 tests, 0 failures). `mix docs --warnings-as-errors` also passed.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Gaps CR-01 (broken schema declaration) and WR-02 (wrong return value) are closed.
- Phase 91 verification now passes all 73 tests with 0 failures.
- The regression gate is in place: any future guide edit that removes the working accessor pattern or prose note will fail the docs-contract test immediately.

## Self-Check: PASSED

- `guides/related-data-and-reindexing.md` — exists and contains `def __scrypath__(:fan_outs)` at line 113
- `test/scrypath/docs_contract_test.exs` — exists and contains new assertions
- `a45b64e` — committed (Task 1)
- `60c08f0` — committed (Task 2)
- `mix verify.phase91` — 73 tests, 0 failures

---
*Phase: 91-integration-guides-and-verification*
*Completed: 2026-05-25*
