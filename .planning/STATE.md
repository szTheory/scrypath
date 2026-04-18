---
gsd_state_version: 1.0
milestone: "v1.5"
milestone_name: "Operator drift and schema-diff tooling"
current_phase: "28"
current_phase_name: "Operator CLI, docs, and verify gate"
current_plan: ""
status: milestone_v1_5_phase_27_complete
stopped_at: "Phase 27 execution complete — start Phase 28 planning"
last_updated: "2026-04-18T04:00:00Z"
last_activity: 2026-04-17
progress:
  total_phases: 2
  completed_phases: 1
  total_plans: 2
  completed_plans: 2
  percent: 50
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-17)

**Core value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

**Current focus:** **v1.5** — Operator drift and schema-diff tooling; **Phase 27 shipped in-repo**, **Phase 28** (Mix + docs + `mix verify.phase27`) next. **Hex** line: **`0.3.3`**.

## Current Position

**Milestone v1.5:** **Phase 27 complete** — `Scrypath.index_contract_drift/2`, optional `include_index_contract_drift` on `reconcile_sync/2`, verification **`.planning/phases/027-schema-index-drift-report/027-VERIFICATION.md`**.

**Next step:** **`/gsd-plan-phase 28`** — operator CLI, guides, and **`mix verify.phase27`** per **`.planning/REQUIREMENTS.md`** (OPS15-02..04).

## Accumulated Context

### Decisions

(See `.planning/PROJECT.md` Key Decisions — unchanged at milestone boundary unless v1.5 planning adds rows.)

**v1.5 intent:** Extend operator trust without new silent heal paths — **report-first** drift visibility that composes with `mix scrypath.settings.diff`, `Scrypath.reconcile_sync/2`, and managed `reindex/2`.

### Blockers / Concerns

- **None.**

### Deferred Items

Unchanged from **v1.4** close — see prior **`STATE.md`** snapshots under **`milestones/v1.4-MILESTONE-AUDIT.md`** if needed. No new deferrals at v1.5 open.

## Next Command

1. **`/gsd-plan-phase 28`** — Mix task(s), **`--json`**, guides, **`mix verify.phase27`**.
2. **`/gsd-discuss-phase 28`** — only if context gaps.

**Resume files:** `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/phases/027-schema-index-drift-report/027-VERIFICATION.md`

---
*Last updated: 2026-04-17 — Phase 27 executed (drift report + reconcile opt-in)*
