---
gsd_state_version: 1.0
milestone: v1.3
milestone_name: Search Power That Phoenix Teams Reach For
current_phase: 20
current_phase_name: faceted search + LiveView guide
current_plan: Not started
status: ready
stopped_at: Phase 19 bookkeeping — advance to Phase 20
last_updated: "2026-04-17T20:00:00.000Z"
last_activity: 2026-04-17
progress:
  total_phases: 6
  completed_phases: 2
  total_plans: 7
  completed_plans: 7
  percent: 33
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-04-16)

**Core value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.
**Current focus:** Phase 20 — faceted search + Phoenix LiveView guide (depends on Phase 19 translation patterns)

## Current Position

Phase: 20 (faceted search + LiveView guide) — NEXT
Plan: not yet planned (TBD on roadmap)
Previous: Phase 19 (relevance tuning) — complete (all 7 plans + summaries; optional `feat(19):` commit at maintainer discretion)
Phase 18: release-parity gate — complete (2026-04-17)
Current Plan: Not started
Status: Ready to plan or execute Phase 20
Last activity: 2026-04-17
Last Activity Description: GSD bookkeeping after Phase 19 implementation landed

Progress: v1.3 phases 18–19 of 6 done (~33% by phase count); Phase 20+ unstarted

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
- [v1.3 Roadmap]: Six phases (18–23) continue the v1.2 numbering. Phase 18 is the release-parity gate + Node 20 CI cleanup — load-bearing foundation that every feature phase inherits. Phase 23 (VALIDATION.md closure) is separated from feature phases so evidence-gathering review is not diluted by code-bearing PRs.
- [v1.3 Roadmap]: Phase ordering — 18 (gate) → 19 (relevance, narrowest translation pattern) → 20 (facets, reuses translation pattern) → 21 (multi-index, depends on facet parity) → 22 (operator polish, orthogonal to search features) → 23 (v1.2 validation closure, parallelizable with 22). Derived from deep research synthesis in `.planning/research/SUMMARY.md`.
- [v1.3 Roadmap]: Every v1.3 addition is additive over shipped `scrypath 0.3.0`; new struct fields land outside `@enforce_keys` with benign defaults. Non-goals locked: no second public backend, no vector/hybrid search, no breaking changes, no dashboard, no new `Scrypath.recover/2` verb.

### Blockers/Concerns

- The working tree already contains unrelated user-side changes outside the Phase 17 bookkeeping files; they remain untouched.
- Live Meilisearch verification still depends on a reachable `SCRYPATH_MEILISEARCH_URL` for any end-to-end publish smoke path that exercises a real backend.
- Phase 18 is now the canonical cleanup path for the remaining GitHub Actions Node 20 deprecation warnings; they no longer appear on the open-concerns list once Phase 18 ships.

### Deferred Items

| Category | Item | Status |
|----------|------|--------|
| backend | Additional public backend support | Deferred until post-release adoption pressure is real |
| search | Hot-apply escape hatch `Scrypath.Meilisearch.Settings.hot_apply/3` | Deferred to v1.4 (stub ships in Phase 19 returning `:hot_apply_disabled`) |
| search | Hierarchical/nested facet declarations, disjunctive facet counts, search-within-facet | Deferred to v1.4 |
| search | Cross-schema ranking normalization, custom weighting, `:all`-schema wildcard | Deferred to v1.4 |
| operator | Failure-class rollup + `reason_class`-driven reconcile branching | Deferred to v1.4 (narrow-polish discipline holds for v1.3) |

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 260416-if2 | fix mix.exs GitHub URLs add a GitHub Actions publish job gated on release creation use HEX_API_KEY only in that publish job | 2026-04-16 | 40c6398 | [260416-if2-fix-mix-exs-github-urls-add-a-github-act](./quick/260416-if2-fix-mix-exs-github-urls-add-a-github-act/) |

## Session Continuity

Last session: 2026-04-17 (bookkeeping)
Stopped at: Phase 19 marked complete in ROADMAP; STATE advanced to Phase 20
Resume: `.planning/ROADMAP.md` § Phase 20 (no `.planning/phases/20-*` directory until `/gsd-plan-phase 20` creates plans)

## Current Status

- v1.0, v1.1, and v1.2 all archived; `scrypath 0.3.0` live on Hex with verified HexDocs and recovery runbooks.
- Milestone `v1.3` "Search Power That Phoenix Teams Reach For" is active with 6 phases (18–23) mapped against 44 requirements at 100% coverage.
- Phase 18 (release-parity gate) shipped; Phase 19 (relevance tuning) implementation is complete on branch — next milestone work is Phase 20 (faceting) per roadmap order.
- v1.3 non-goals (locked): no second public backend, no vector/hybrid/semantic search, no breaking changes to v1.2 public contracts, no dashboard surface, no new `Scrypath.recover/*` verb.

## Next Command

1. Commit and push Phase 19 changes when satisfied (`mix test --exclude external_meilisearch`; clean tree for `mix verify.workspace_clean` in CI).
2. `/gsd-progress` — sanity-check progress vs disk (or `--forensic` for integrity audit).
3. `/gsd-plan-phase 20` — Phase 20 plans are still **TBD** on the roadmap; planning is the recommended next GSD step before `/gsd-execute-phase 20`.
4. Optional: conventional `feat(19): …` commit if you want Release Please to pick up a version bump from Phase 19 scope.

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
*Last updated: 2026-04-17 — Phase 19 bookkeeping; current focus Phase 20*
