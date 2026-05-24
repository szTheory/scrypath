---
phase: "88"
plan: "01"
subsystem: "planning"
tags:
  - planning
  - docs
requires: []
provides:
  - "guides/related-data-and-reindexing.md"
  - "test/scrypath/docs_contract_test.exs"
  - ".planning/ROADMAP.md"
  - ".planning/STATE.md"
  - ".planning/REQUIREMENTS.md"
affects:
  - ".planning/STATE.md"
  - ".planning/ROADMAP.md"
  - ".planning/REQUIREMENTS.md"
tech_stack_added: []
tech_stack_patterns: []
key_files_created: []
key_files_modified:
  - "guides/related-data-and-reindexing.md"
  - "test/scrypath/docs_contract_test.exs"
  - ".planning/ROADMAP.md"
  - ".planning/STATE.md"
  - ".planning/REQUIREMENTS.md"
key_decisions:
  - "Phase 88 complete: Papercuts fixed and milestone frozen. Next-pull verdict is related-data propagation."
metrics:
  duration_minutes: 5
  completed_date: "2026-05-24"
---

# Phase 88 Plan 01: Evidence-Backed Papercuts And Next-Pull Verdict Summary

Closed evidence-backed papercuts by adding temporary Oban workaround for related-data and froze milestone v1.23.

## Work Completed
- Added custom Oban job instructions to `guides/related-data-and-reindexing.md` explaining it as a "temporary workaround" until "related-data propagation" becomes a "first-class feature".
- Added ExUnit doc contract test to assert the presence of these instructions.
- Marked the `v1.23` milestone as "shipped + archived in-repo" in `.planning/ROADMAP.md` and explicitly established "related-data propagation" as the next-pull verdict.
- Completed phase 88 in `.planning/STATE.md` and updated `.planning/REQUIREMENTS.md`.

## Deviations from Plan
None - plan executed exactly as written.

## Known Stubs
None

## Threat Flags
None

## Self-Check: PASSED
FOUND: guides/related-data-and-reindexing.md
FOUND: test/scrypath/docs_contract_test.exs
FOUND: .planning/ROADMAP.md
FOUND: .planning/STATE.md
FOUND: .planning/REQUIREMENTS.md
FOUND: 932b84c
FOUND: 1cb39c0