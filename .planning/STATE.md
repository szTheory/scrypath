---
gsd_state_version: 1.0
milestone: none
milestone_name: Between milestones
status: between_milestones
last_updated: "2026-04-20T12:00:00.000Z"
last_activity: 2026-04-20
progress:
  total_phases: 0
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-20)

**Core value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

**Current focus:** Between milestones — run **`/gsd-new-milestone`** to open the next versioned scope.

## Current Position

Phase: —

Plan: —

**Status:** Milestone **v1.7** archived; no active milestone.

**Last activity:** 2026-04-20

## Accumulated Context

### Decisions

(See `.planning/PROJECT.md` Key Decisions.)

**v1.7 shipped:** Hierarchical facets (**36**), disjunctive facet counts (**37**), **`search_within_facet/4`** + docs/contracts (**38**).

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

### Acknowledged at v1.7 milestone close (`audit-open`, 2026-04-20)

Same **3** tooling rows as at v1.6 close; still **non-blocking** for archive.

| Category | Item | Status |
|----------|------|--------|
| uat_gap | Phase 18 — `18-UAT.md` | acknowledged — UAT **passed**; audit-open listing noise |
| quick_task | `260416-eoj-automate-phase-5-verification-with-live-` | acknowledged — **missing** stub; **obsolete** per §Deferred Items |
| quick_task | `260416-if2-fix-mix-exs-github-urls-add-a-github-act` | acknowledged — **missing** stub; **obsolete** per §Deferred Items |

## Next Command

1. **`/gsd-new-milestone`** — open the next versioned milestone (requirements → roadmap → phases).

**Resume files:** `.planning/ROADMAP.md`, `.planning/PROJECT.md`, `.planning/STATE.md`, `.planning/MILESTONES.md`

---
*Last updated: 2026-04-20 — milestone **v1.7** archived; **`REQUIREMENTS.md`** removed pending next milestone*

**Prior milestone:** **v1.7** (phases **36–38**) — archived 2026-04-20
