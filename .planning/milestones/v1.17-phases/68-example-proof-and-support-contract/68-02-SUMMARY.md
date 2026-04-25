---
phase: 68-example-proof-and-support-contract
plan: 02
subsystem: testing
tags: [example, phoenix, integration, docs, manual-sync]
requires:
  - phase: 68-01
    provides: Support contract and canonical public wayfinding
provides:
  - Real :manual smoke proof in the Phoenix example
  - Canonical example README for inline, manual, and oban adoption
  - Phase 68 bounded docs-contract assertions for support/example wayfinding and example env/command order
affects: [examples/phoenix_meilisearch, docs contracts, onboarding]
tech-stack:
  added: []
  patterns: [example README as proof authority, manual sync proves accepted-then-observe flow]
key-files:
  created: [examples/phoenix_meilisearch/test/smoke/meilisearch_manual_stack_test.exs]
  modified: [examples/phoenix_meilisearch/README.md, test/scrypath/docs_contract_test.exs]
key-decisions:
  - "Used Scrypath.sync_status/2 in the manual smoke test instead of inventing a new helper or second example app."
  - "Kept docs-contract coverage bounded to facts and navigation: links, env names, command order, and mode coverage."
patterns-established:
  - "The example README is the canonical authority for example env vars, startup order, CI shape, and mode-specific proof paths."
  - "Manual sync proof requires explicit follow-up before search visibility is treated as complete."
requirements-completed: [INTG-01, INTG-04]
duration: 41 min
completed: 2026-04-22
---

# Phase 68 Plan 02 Summary

**Turned the Phoenix example into the canonical proof surface for inline, manual, and oban sync with bounded docs-contract coverage**

## Performance

- **Duration:** 41 min
- **Started:** 2026-04-23T01:20:00Z
- **Completed:** 2026-04-23T02:01:00Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added a live `:manual` smoke test that proves accepted work first and explicit `Scrypath.sync_status/2` follow-up before hydrated search visibility.
- Rewrote the example README into the canonical adopter-proof runbook, including CI path, local command order, env vars, and mode-specific proof surfaces.
- Extended `test/scrypath/docs_contract_test.exs` with bounded Phase 68 assertions for support/example wayfinding, example env vars, command order, and mode coverage.

## Task Commits

No git commits were created during this execution run.

## Files Created/Modified

- `examples/phoenix_meilisearch/test/smoke/meilisearch_manual_stack_test.exs` - Real manual sync smoke proof using `Scrypath.sync_status/2`.
- `examples/phoenix_meilisearch/README.md` - Canonical real-app proof runbook for inline, manual, and oban.
- `test/scrypath/docs_contract_test.exs` - Bounded assertions for Phase 68 docs/example drift.

## Decisions Made

- Used the existing Phoenix example as the only proof surface and added the missing manual path instead of creating a second app or browser-level system.
- Locked only fact/navigation drift in docs contracts, not whole prose sections.
- Reused live services already available on `5433` and `7700` for the CI-shaped example run when a host port conflict blocked a fresh Compose start.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Increased the manual smoke polling budget for live backend visibility**
- **Found during:** Task 1
- **Issue:** The first manual integration run timed out before `sync_status/2` observed the completed backend task.
- **Fix:** Increased the polling budget and interval so the test waits long enough for live Meilisearch task completion without weakening the assertion.
- **Files modified:** `examples/phoenix_meilisearch/test/smoke/meilisearch_manual_stack_test.exs`
- **Verification:** `cd examples/phoenix_meilisearch && SCRYPATH_EXAMPLE_INTEGRATION=1 PGPORT=5433 SCRYPATH_MEILISEARCH_URL=http://127.0.0.1:7700 mix test`

---

**Total deviations:** 1 auto-fixed (1 live integration timing issue)
**Impact on plan:** Improved reliability of the intended manual proof path. No scope creep.

## Issues Encountered

- `./scripts/smoke.sh` could not be re-run in this environment because host port `5433` was already occupied by unrelated running containers, which prevented `docker compose up -d` from binding Postgres. The CI-shaped example suite still ran successfully against live services already present on `5433` and `7700`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 69 can build a maintainer-facing verify spine on top of a stable support contract, canonical example proof, and bounded docs/example drift checks.
