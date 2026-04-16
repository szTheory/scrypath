---
gsd_state_version: 1.0
milestone: v1.2
milestone_name: public-release-trust-and-operator-visibility
current_phase: 11
current_phase_name: public-release-contract
current_plan: none
status: ready_to_plan
stopped_at: Roadmap created for milestone v1.2
last_updated: "2026-04-16T20:20:00Z"
last_activity: 2026-04-16
progress:
  total_phases: 4
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-04-16)

**Core value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.
**Current focus:** Phase 11 roadmap follow-through for the public release contract

## Current Position

Phase: 11 of 14 (Public Release Contract)
Plan: None
Current Phase: 11
Current Phase Name: public-release-contract
Current Plan: None
Status: Ready to plan
Last activity: 2026-04-16
Last Activity Description: Created the v1.2 roadmap and mapped all milestone requirements to Phases 11-14.

Progress: [----------] 0%

## Accumulated Context

### Decisions

- Public v1 backend target remains Meilisearch.
- Internal architecture should preserve a future backend seam without making it public in v1.2.
- Core architecture remains Ecto-first and Phoenix-friendly.
- Sync modes for v1 remain inline, Oban, and manual.
- Phase 11 owns the real public release contract, clean-consumer smoke verification, and maintainer recovery runbooks.
- Phase 12 owns the internal operations seam so operator APIs do not depend on raw Meilisearch task shapes.
- Phase 13 owns status, failure inspection, retry, and reconcile primitives through Scrypath-owned results.
- Phase 14 owns thin Mix task ergonomics and operational guides while keeping backend-native search power namespaced.

### Blockers/Concerns

- The working tree already contains user-side deletions under `.planning/phases/08-*`, `.planning/phases/09-*`, and `.planning/phases/10-*`; roadmap work must leave them untouched.
- A publisher-scoped `HEX_API_KEY` is still needed to validate the real public Hex publish path once Phase 11 executes.
- Live Meilisearch verification still depends on a reachable `SCRYPATH_MEILISEARCH_URL` for any end-to-end publish smoke path that exercises a real backend.

### Deferred Items

| Category | Item | Status |
|----------|------|--------|
| backend | Additional public backend support | Deferred until post-release adoption pressure is real |
| search | Richer backend-native search power | Deferred until the operator/release milestone settles |

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 260416-if2 | fix mix.exs GitHub URLs add a GitHub Actions publish job gated on release creation use HEX_API_KEY only in that publish job | 2026-04-16 | 40c6398 | [260416-if2-fix-mix-exs-github-urls-add-a-github-act](./quick/260416-if2-fix-mix-exs-github-urls-add-a-github-act/) |

## Session Continuity

Last session: 2026-04-16T20:20:00Z
Stopped at: Created ROADMAP.md, STATE.md, and v1.2 traceability for milestone kickoff
Resume file: None

## Current Status

- v1.0 remains archived with the full Meilisearch-first core, search, Oban, reindex, docs, and release baseline shipped.
- v1.1 remains archived with release hardening, docs-safety fixes, `mix verify.phase10`, and the launch-readiness evidence chain.
- v1.2 is now structured into four phases: release contract, internal operations seam, operator primitives, and Mix-task-plus-guide ergonomics.
- No second public backend is planned in this milestone, and backend-native power remains outside the common search contract.

## Next Command

- `$gsd-plan-phase 11`

---
*Last updated: 2026-04-16 after creating the v1.2 roadmap*
