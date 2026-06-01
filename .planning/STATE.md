---
gsd_state_version: 1.0
milestone: v1.32
milestone_name: Admin UI/UX Design System Cleanup
status: verifying
last_updated: "2026-06-01T18:53:19.522Z"
last_activity: 2026-06-01
progress:
  total_phases: 3
  completed_phases: 2
  total_plans: 3
  completed_plans: 2
  percent: 67
---

# Project State

## Project Reference

**Core Value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.
**Current Focus:** Phase 117 — shared-ops-component-system

## Current Position

Phase: 117 (shared-ops-component-system) — READY FOR VERIFICATION
Plan: 1 of 1
Status: Phase complete — ready for verification
Last activity: 2026-06-01

## Current Milestone

**v1.32 Admin UI/UX Design System Cleanup**

This milestone is a bounded OPSUI polish and design-system wedge. It does not reopen Scrypath runtime product scope.

### Planned

- Phase 116: OPSUI Asset Contract and Design Tokens — implementation pass complete
- Phase 117: Shared Ops Component System — implementation pass complete
- Phase 118: Admin Screen UX Cleanup — implementation pass complete; DB-backed verification pending

## Accumulated Context

### Key Decisions

- v1.31 maintainer UAT passed; the realistic demo worked locally.
- v1.32 uses the System + Screens scope and Quiet Ops Console visual direction.
- OPSUI cleanup must preserve posture-first IA: posture, failed sync, sync/drift, search/federation, saved playbooks.
- `phase105-e2e` remains advisory; UI cleanup does not promote browser proof to a required merge gate.
- The admin UI is a mounted, host-owned operator surface, not a new hosted/productized admin product.
- Verification should resume with sequential, lower-connection test runs once local Postgres has available connection slots.
- Mounted `/admin/search/*` host tests must explicitly prove ScrypathOps asset hooks and avoid storefront bleed.
- OPSUI token cleanup removes Tailwind utility-prefix residue and keeps unprefixed daisyUI usage an explicit contract.
- OPSUI shared primitives stay as small Phoenix function components; no LiveComponent state boundary was needed for Phase 117.
- Schema selectors and swap actions must compare against configured allowlists and reject unknown strings without atom creation.

### Active Blockers

- None.

### Todos

- Rerun focused ScrypathOps LiveView tests once local Postgres is no longer saturated.
- Rerun mounted e-commerce admin smoke test once local Postgres is no longer saturated.
- Decide whether a screenshot/browser polish pass is warranted before v1.32 archive.
- Keep future runtime breadth closed unless concrete production bug evidence, reviewed outside-adopter evidence, or an explicit strategic decision justifies it.

## Operator Next Steps

- Clear local DB connection pressure and rerun the focused verification commands from this implementation pass.

## Performance Metrics

| Phase | Plan | Duration | Notes |
|-------|------|----------|-------|
| Phase 117 P117 | 33min | 3 tasks | 9 files |
