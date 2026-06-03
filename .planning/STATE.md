---
gsd_state_version: 1.0
milestone: v1.33
milestone_name: Admin UI Insane Polish
status: Active — Phase 120 complete; Phase 121 pending (owner gate)
last_updated: "2026-06-03"
last_activity: 2026-06-03 — Phase 120 complete (per-touchpoint audit: 47 findings, 11 systemic, ranked fix-class-tagged backlog)
progress:
  total_phases: 9
  completed_phases: 2
  total_plans: 2
  completed_plans: 2
  percent: 22
---

# Project State

## Project Reference

**Core Value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.
**Current Focus:** v1.33 Admin UI Insane Polish — Phase 121 (design-system tightening: tokens) — owner gate

## Current Position

Phase: 121 — Design-system tightening: tokens (pending, owner gate)
Plan: —
Status: Active — Phase 120 complete; Phase 121 not yet planned
Last activity: 2026-06-03 — Phase 120 complete (per-touchpoint audit → 47-finding ranked backlog, 11 systemic fixes mapped to 121/122)

## Current Milestone

**v1.33 Admin UI Insane Polish** (phases 119-127) — owner-initiated, screenshot-backed UI/UX + design-system iteration of the `scrypath_ops` admin console, building on the v1.32 foundation. Deliberately overrides the idle/maintenance posture as an explicit polish wedge. See `milestones/v1.33-{ROADMAP,REQUIREMENTS}.md`.

**Locked decisions:** task-first IA restructure (we commit, no external gate) · elevate brand within "reserved" (one signature verdict tone-settle) · scaffold + run autonomously, checkpoint at gate phases (121,122,123,127) + IA before/after (124).

## Accumulated Context

### Key Decisions

- v1.31 maintainer UAT passed; the realistic demo worked locally.
- v1.32 uses the System + Screens scope and Quiet Ops Console visual direction.
- OPSUI cleanup must preserve posture-first IA: posture, failed sync, sync/drift, search/federation, saved playbooks.
- `phase105-e2e` remains advisory; UI cleanup does not promote browser proof to a required merge gate.
- The admin UI is a mounted, host-owned operator surface, not a new hosted/productized admin product.
- Phase 118 verification passed with focused ScrypathOps LiveView tests, root `mix verify.opsui`, and mounted ecommerce admin route tests.
- Mounted `/admin/search/*` host tests must explicitly prove ScrypathOps asset hooks and avoid storefront bleed.
- OPSUI token cleanup removes Tailwind utility-prefix residue and keeps unprefixed daisyUI usage an explicit contract.
- OPSUI shared primitives stay as small Phoenix function components; no LiveComponent state boundary was needed for Phase 117.
- Schema selectors and swap actions must compare against configured allowlists and reject unknown strings without atom creation.
- (Phase 119) Four named operational seed scenarios (all_green/degraded/incident/empty) live in BOTH seeding paths; `incident` stays default so `make dev`/E2E behavior is unchanged. The admin UI computes posture live from the live index + Oban jobs, so scenarios differ only in sync state + injected signals, not in the catalog fixtures.
- (Phase 119) Screenshot baseline = `admin_screenshot_matrix.spec.ts`: 6 screens × {light,dark} × {mobile 390, desktop 1440} grouped by scenario → 40 deterministic shots in `.tmp/admin-screenshots/`. Theme set via `addInitScript` localStorage `phx:theme` on a fresh context.
- (Phase 120) Per-touchpoint audit produced 47 findings (6 blocker / 9 structural / 32 polish); 11 promoted to systemic token/component fixes. All 10 plan design-system hypotheses confirmed (none refuted; `shadow-ops-mid` already correct). Top systemic anchors: tone-set gap (`ops_ui.ex:259,475,1176-1179`), `ops_code_block` `rounded-md` (`:941`), notice/status duplication (`:203-254`), no `ops_loading` primitive, missing `--ease-ops-exit` (`app.css:167-169`), no row hover/press parity (`app.css:615,845`), preflight 1→4-col jump (`app.css:722-726`). Biggest screen issues: Posture 11-col table overflows mobile, Sync/Drift renders narrow (`:default` not `:wide`), verdict label forks across screens (SHELL-01), nav vocab still Triage/Probes.

### Active Blockers

- None.

### Todos

- Keep future runtime breadth closed unless concrete production bug evidence, reviewed outside-adopter evidence, or an explicit strategic decision justifies it.

## Operator Next Steps

- Owner gate: review the Phase 120 systemic backlog (`milestones/v1.33-phases/120-per-touchpoint-audit/120-AUDIT-BACKLOG.md` — 11 systemic token/component fixes), then plan and execute Phase 121 (design-system tightening: tokens — `--ease-ops-exit`, complete tone set, raw-step leak fixes in skip-link/theme-toggle/code-block/data-card/checkbox/modal, preflight tablet step; `DESIGN-TOKENS.md` in lockstep).

## Performance Metrics

| Phase | Plan | Duration | Notes |
|-------|------|----------|-------|
| Phase 117 P117 | 33min | 6 tasks | 9 files |
