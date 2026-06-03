---
gsd_state_version: 1.0
milestone: v1.33
milestone_name: Admin UI Insane Polish
status: Active — Phase 119 pending
last_updated: "2026-06-03"
last_activity: 2026-06-03 — Milestone v1.33 scaffolded; phases 119-127 defined
progress:
  total_phases: 9
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

**Core Value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.
**Current Focus:** v1.33 Admin UI Insane Polish — Phase 119 (audit harness + seed scenarios)

## Current Position

Phase: 119 — Audit harness + seed-scenario coverage (pending)
Plan: —
Status: Active — milestone scaffolded, Phase 119 not yet planned
Last activity: 2026-06-03 — Milestone v1.33 scaffolded; phases 119-127 defined

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

### Active Blockers

- None.

### Todos

- Keep future runtime breadth closed unless concrete production bug evidence, reviewed outside-adopter evidence, or an explicit strategic decision justifies it.

## Operator Next Steps

- Plan and execute Phase 119 (audit harness + seed scenarios) with the GSD phase loop.

## Performance Metrics

| Phase | Plan | Duration | Notes |
|-------|------|----------|-------|
| Phase 117 P117 | 33min | 6 tasks | 9 files |
