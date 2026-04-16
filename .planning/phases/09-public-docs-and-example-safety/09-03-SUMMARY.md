---
phase: 09-public-docs-and-example-safety
plan: 03
subsystem: docs
tags: [phoenix, liveview, request-shape, smoke-test]
requires:
  - phase: 09-02
    provides: safe JSON request normalization and docs fixture coverage
provides:
  - realistic string-keyed LiveView publish example
  - fixture behavior aligned with browser-shaped nested attrs
  - narrow Plug-based request-shape smoke coverage
affects: [guides, fixtures, docs-tests]
tech-stack:
  added: []
  patterns: [string-keyed request attrs, Plug.Conn.Query smoke verification]
key-files:
  created:
    - .planning/phases/09-public-docs-and-example-safety/09-03-SUMMARY.md
    - test/support/docs/phoenix_request_shape_smoke_test.exs
  modified:
    - guides/phoenix-liveview.md
    - test/support/docs/phoenix_example_case.ex
    - test/support/docs/phoenix_examples_test.exs
key-decisions:
  - "The fixture-backed publish path now models nested string-keyed attrs instead of atom-key maps."
  - "One narrow Plug-decoded smoke test is enough to prove request-shape realism without adding Phoenix as a dependency."
patterns-established:
  - "LiveView docs keep request attrs string-keyed at the web boundary before the context handles persistence."
  - "Docs trust boosters use existing fixtures plus tiny Plug-shaped smoke tests instead of expanding into an embedded Phoenix app."
requirements-completed: [DOCS-03]
duration: 10min
completed: 2026-04-16
---

# Phase 09: Public Docs and Example Safety Summary

**The LiveView publish example now matches real nested string-keyed request attrs, with one small Plug-based smoke test proving the fixture boundary accepts browser-shaped params**

## Performance

- **Duration:** 10 min
- **Started:** 2026-04-16T18:31:00Z
- **Completed:** 2026-04-16T18:41:00Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Kept the LiveView publish example explicitly string-keyed and aligned the fixture’s `publish_post/2` path with real request attrs.
- Updated the fixture behavior tests so the publish flow now exercises nested `%{"post" => %{"title" => ...}}` params instead of atom-key maps.
- Added one focused `Plug.Conn.Query.decode/1` smoke test that proves real nested request params match the fixture contract.

## Task Commits

Each task was committed atomically:

1. **Task 1: Align the LiveView guide and fixture with real string-keyed publish attrs per D-09 through D-12** - `cb832ce` (docs)
2. **Task 2: Add one narrow request-shape smoke test without introducing Phoenix as a dependency** - `5f5d2d3` (test)

## Files Created/Modified
- `guides/phoenix-liveview.md` - makes the string-keyed request-attr boundary explicit in the publish example.
- `test/support/docs/phoenix_example_case.ex` - updates the fixture publish path to read realistic string-keyed attrs.
- `test/support/docs/phoenix_examples_test.exs` - switches publish-path assertions to nested string-keyed params and validates the fixture behavior directly.
- `test/support/docs/phoenix_request_shape_smoke_test.exs` - proves decoded nested request params match the LiveView fixture contract.

## Decisions Made
- Used `Plug.Conn.Query.decode/1` for the smoke proof because Plug is already in test scope and it verifies the shape that matters.
- Kept the smoke test intentionally narrow so the repo still uses plain fixtures as the main docs safety harness.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
The key-link verification helper reported false negatives even after the relevant patterns existed in source and target files. The executable tests passed, and direct `rg` checks confirmed the expected strings.

## User Setup Required

None.

## Next Phase Readiness
Phase 09 now has a copy-paste-safe install contract, non-raising JSON pagination docs, and realistic Phoenix request-shape coverage. Phase 10 can focus on launch verification and milestone-close evidence.

## Self-Check: PASSED

---
*Phase: 09-public-docs-and-example-safety*
*Completed: 2026-04-16*
