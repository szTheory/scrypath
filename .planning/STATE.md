---
gsd_state_version: 1.0
milestone: v1.3
milestone_name: Search Power That Phoenix Teams Reach For
current_phase: null
current_phase_name: null
current_plan: null
status: defining_requirements
stopped_at: v1.3 milestone started — defining requirements
last_updated: "2026-04-16T00:00:00Z"
last_activity: 2026-04-16 -- Milestone v1.3 started
progress:
  total_phases: 0
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-04-16)

**Core value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.
**Current focus:** Defining requirements for v1.3 (Meilisearch-native search power + tooling-debt retirement)

## Current Position

Phase: Not started (defining requirements)
Plan: —
Current Phase: None
Current Phase Name: None
Current Plan: None
Status: Defining requirements
Last activity: 2026-04-16 — Milestone v1.3 started
Last Activity Description: v1.3 milestone opened: facets, relevance tuning, multi-index search, operator polish, and release/tooling debt closure

Progress: [          ] 0%

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
- [Phase 11]: Release-facing package links stay pinned to @version and @source_ref instead of moving main/latest-doc targets.
- [Phase 11]: Phase 11 verification extends the narrow verify.phase10 orchestration shape instead of introducing a new release script.
- [Phase 11]: Local clean-consumer release proof uses the packaged artifact contents through a tagged temporary git repo so the smoke test stays auth-free without a path dependency.
- [Phase 11]: Phase 11 release docs stay on the existing Release Please plus GitHub Actions publish path and document recovery instead of adding a second release system.
- [Phase 11]: The canonical publish workflow now verifies version/ref alignment, `mix verify.phase11`, a Hex dry-run, and the live published package before Phase 11 can be considered released.
- [Phase 11]: Ongoing published-release verification belongs in a separate verification-only workflow that reads the latest Hex version and never attempts recovery or publish.
- [Phase 12]: Keep the internal operations seam constructor-focused and internal-only until runtime rewiring in Plan 02. — Plan 12-01 establishes contract ownership without implying a new public operator surface or backend abstraction.
- [Phase 12]: Use one Scrypath-owned task struct for backend tasks and queue jobs, separating source and kind from public sync projection. — This keeps lifecycle vocabulary Scrypath-owned while still preserving a path back to the existing sync result map.
- [Phase 12]: Keep `Scrypath.Meilisearch` as the explicit public namespace and push seam normalization into `Scrypath.Meilisearch.Operations`. — This preserves the Meilisearch-first public contract while moving backend task normalization behind the internal seam.
- [Phase 12]: Convert seam-owned `Scrypath.Operations.Result` and `Task` values back into the current public sync maps only at the `Scrypath.Sync` boundary. — Phase 13 can now build operator primitives on the seam without changing the caller-facing sync contract.
- [Phase 12]: Route Meilisearch backfill writes through the internal operations adapter so batch summaries can be built from Scrypath-owned results.
- [Phase 12]: Treat the presence of a followable operation task as the reindex waiting contract instead of branching on a concrete backend module.
- [Phase 17]: Use `origin/main` as the canonical release source, then repair repo Actions workflow permissions instead of bypassing Release Please.
- [Phase 17]: Fix the first publish gate on `main` with the minimal release commit `13f1789` and complete the public release through the documented recovery publish workflow.

### Blockers/Concerns

- The working tree already contains unrelated user-side changes outside the Phase 17 bookkeeping files; they remain untouched.
- Live Meilisearch verification still depends on a reachable `SCRYPATH_MEILISEARCH_URL` for any end-to-end publish smoke path that exercises a real backend.
- GitHub Actions still emits Node.js 20 deprecation warnings for some upstream actions; this should be cleaned up before runner defaults change.

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

Last session: 2026-04-16T00:00:00Z
Stopped at: v1.3 milestone started — defining requirements
Resume file: None

## Current Status

- v1.0, v1.1, and v1.2 all archived; `scrypath 0.3.0` live on Hex with verified HexDocs and recovery runbooks.
- Milestone `v1.3` "Search Power That Phoenix Teams Reach For" is now active.
- Direction chosen by evidence-based extrapolation (codebase gap analysis + planning history + ecosystem research) rather than a single adopter request — primary bet is deepening Meilisearch-native capabilities over widening to a second backend.
- v1.3 scope: faceted search, relevance tuning (typo/synonyms/ranking), multi-index search, narrow operator polish, and release/tooling-debt retirement (GitHub Actions Node 20 cleanup + v1.2 VALIDATION.md closure).
- v1.3 non-goals (locked): no second public backend, no vector/hybrid/semantic search, no breaking changes to v1.2 public contracts, no dashboard surface.

## Next Command

- `$gsd-discuss-phase 18`

## Performance Metrics

| Phase | Plan | Duration | Tasks | Files | Date |
|-------|------|----------|-------|-------|------|
| 12 | 03 | 3 min | 2 | 7 | 2026-04-16 |
| 12 | 02 | 5 min | 2 | 8 | 2026-04-16 |
| 12 | 01 | 2 min | 1 | 4 | 2026-04-16 |
| 11 | 02 | 10min | 3 | 4 | 2026-04-16 |
| 11 | hardening | follow-up | release automation, recovery workflow, published-release monitor | 2026-04-16 |
| Phase 15 | 01 | 12 min | 2 | 4 | 2026-04-17 |
| Phase 16 | 01 | 0 min | 2 | 7 | 2026-04-17 |
| Phase 17 | 01 | 24 min | 2 | 6 | 2026-04-17 |

---
*Last updated: 2026-04-16 — v1.3 milestone started*
