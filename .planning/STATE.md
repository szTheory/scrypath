---
gsd_state_version: 1.0
milestone: v1.7
milestone_name: candidates)
status: planning
last_updated: "2026-04-20T00:59:18.915Z"
last_activity: 2026-04-20
progress:
  total_phases: 3
  completed_phases: 1
  total_plans: 3
  completed_plans: 3
  percent: 100
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-19)

**Core value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

**Current focus:** Phase 36 — hierarchical-facets

## Current Position

Phase: 36 (hierarchical-facets) — EXECUTING
Plan: 1 of 3
**Phase:** 37

**Plan:** Not started

**Status:** Ready to plan

**Last activity:** 2026-04-20

## Accumulated Context

### Decisions

(See `.planning/PROJECT.md` Key Decisions.)

**v1.6 shipped:** Adoption golden path, consumer-shaped proof depth, verification story for contributors, **`STATE.md`** triage (**AUDT-01**), and doc-contract gap closure **33–35**.

**v1.7 intent (ROI):** Prioritize **facet depth** on existing faceting; defer **multi-index federation scoring** and **per-query relevance implementation** until a dedicated design (**`TUNE-PIPE-01`**) / later milestone.

### Blockers / Concerns

- **None.**

### Deferred Items

**Prior (v1.5 and earlier):** Rows from v1.5 milestone close — **triaged phase 32 (AUDT-01)**; canonical ledger below.

| Category | Item | Status |
|----------|------|--------|
| uat_gap | Phase 18 — `18-UAT.md` retained as shift-left map; phase **passed** — see `.planning/phases/18-release-parity-gate-node-20-ci-cleanup/18-VERIFICATION.md`, `.planning/milestones/v1.4-MILESTONE-AUDIT.md`, and `.planning/phases/18-release-parity-gate-node-20-ci-cleanup/18-UAT.md` | resolved |
| quick_task | `260416-eoj-automate-phase-5-verification-with-live-` — obsolete (completed); see `.planning/quick/260416-eoj-automate-phase-5-verification-with-live-/260416-eoj-SUMMARY.md` | obsolete |
| quick_task | `260416-if2-fix-mix-exs-github-urls-add-a-github-act` — obsolete (completed); see `.planning/quick/260416-if2-fix-mix-exs-github-urls-add-a-github-act/260416-if2-SUMMARY.md` | obsolete |

### Acknowledged at v1.6 milestone close (`audit-open`, 2026-04-19)

Structured **`audit-open`** still counted **3** items at close; each is **superseded** by shipped verification and the table above. Recorded so milestone close does not imply unmanaged debt.

| Category | Item | Status |
|----------|------|--------|
| uat_gap | Phase 18 — `18-UAT.md` listing in audit tool | acknowledged — UAT **passed**; file retained by policy |
| quick_task | `260416-eoj-automate-phase-5-verification-with-live-` | acknowledged — stub **missing** on disk; **obsolete** per §Deferred Items |
| quick_task | `260416-if2-fix-mix-exs-github-urls-add-a-github-act` | acknowledged — stub **missing** on disk; **obsolete** per §Deferred Items |

## Next Command

1. **`/gsd-discuss-phase 36`** — gather context for **Phase 36: Hierarchical facets** (or **`/gsd-plan-phase 36`** to plan directly).

**Resume files:** `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/PROJECT.md`, `.planning/STATE.md`

---
*Last updated: 2026-04-19 — milestone **v1.7** opened (facet depth); prior **v1.6** archived*

**Prior milestone:** **v1.6** (phases **29–35**) — archived 2026-04-19

**Planned Phase:** 36 (Hierarchical facets) — 3 plans — 2026-04-20T00:37:21.621Z
