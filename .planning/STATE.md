---
gsd_state_version: 1.0
milestone: "v1.5"
milestone_name: "Operator drift and schema-diff tooling"
current_phase: ""
current_phase_name: ""
current_plan: ""
status: milestone_v1_5_defining
stopped_at: ""
last_updated: "2026-04-17T23:45:00Z"
last_activity: 2026-04-17
progress:
  total_phases: 2
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-17)

**Core value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

**Current focus:** **v1.5** — Operator drift and schema-diff tooling (phases **27–28**). **Hex** line: **`0.3.3`**.

## Current Position

**Milestone v1.5:** Not started at phase execution level — requirements and roadmap are in **`.planning/REQUIREMENTS.md`** and **`.planning/ROADMAP.md`**.

**Next step:** **`/gsd-discuss-phase 27`** (recommended) or **`/gsd-plan-phase 27`** to open **Phase 27: Schema–index drift report (read-only)**.

## Accumulated Context

### Decisions

(See `.planning/PROJECT.md` Key Decisions — unchanged at milestone boundary unless v1.5 planning adds rows.)

**v1.5 intent:** Extend operator trust without new silent heal paths — **report-first** drift visibility that composes with `mix scrypath.settings.diff`, `Scrypath.reconcile_sync/2`, and managed `reindex/2`.

### Blockers / Concerns

- **None.**

### Deferred Items

Unchanged from **v1.4** close — see prior **`STATE.md`** snapshots under **`milestones/v1.4-MILESTONE-AUDIT.md`** if needed. No new deferrals at v1.5 open.

## Next Command

1. **`/gsd-discuss-phase 27`** — clarify API shape, Meilisearch read primitives, and non-goals for drift report.
2. **`/gsd-plan-phase 27`** — if discussion is already satisfied.

**Resume files:** `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`

---
*Last updated: 2026-04-17 — v1.5 milestone opened; phases 27–28 defined*
