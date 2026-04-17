---
gsd_state_version: 1.0
milestone: v1.4
milestone_name: Public package parity & operator depth
current_phase: 24
current_phase_name: Public Hex release & parity gates
current_plan: "24-01, 24-02, 24-03"
status: shipped_hex_0_3_1
stopped_at: "Hex scrypath 0.3.1 published 2026-04-17 (Release Please PR #5 merged). Planning checkboxes updated. Run /gsd-complete-milestone v1.4 when ready to archive."
last_updated: "2026-04-17T23:50:00Z"
last_activity: 2026-04-17
progress:
  total_phases: 3
  completed_phases: 3
  total_plans: 8
  completed_plans: 8
  percent: 100
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-17)

**Core value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

**Current focus:** Milestone **v1.4** — **shipped to Hex as `0.3.1`** (2026-04-17). All phases **24–26** complete; **SHIP-01..03** satisfied. Optional: **`/gsd-complete-milestone v1.4`** to archive roadmap/requirements into `milestones/`.

## Current Position

**Phase 24 (release):** ✅ **Hex `0.3.1`** — Release Please merge + Actions publish + `release_publish` / `release_parity` steps green (Actions **run 24589910084**).  
**Phases 25–26:** ✅ as before (`hot_apply/3`, **`mix verify.phase26`**).

## Accumulated Context

### Decisions

(See `.planning/PROJECT.md` Key Decisions — unchanged at milestone boundary.)

**Phase 24 (release slice):** See `.planning/phases/24-public-hex-release-parity-gates/24-CONTEXT.md` — target `0.3.1`, Release Please alignment, narrow SHIP-02 sweep, post-publish `release_parity` on both publish workflows.

**Phase 26 (operator rollups):** See `.planning/phases/26-operator-failure-rollups/26-CONTEXT.md` — opt-in `failed_sync_work/2`, dense `%ReasonClassCounts{}`-style struct, reconcile field, Mix defaults + `--json`. Canonical verify: **`mix verify.phase26`**.

### Blockers / Concerns

- **None for Hex ship.** Optional follow-up: milestone archive via **`/gsd-complete-milestone v1.4`**.

### Deferred Items

- **Quick-task stubs (audit-open):** two slugs reported **missing** on disk — same class as v1.3 close; safe to drop from audit index or recreate files if you still want those tasks tracked.
- **v1.4 milestone archive:** optional GSD **`/gsd-complete-milestone v1.4`** (SHIP done).

## Pre-close evidence (automated)

| Gate | Result (2026-04-17) |
|------|---------------------|
| `mix verify.phase11` | pass |
| `mix verify.phase26` | pass |
| `mix verify.workspace_clean` | pass (after last commit) |
| `mix format --check-formatted` | pass |

**Milestone audit file:** `.planning/v1.4-MILESTONE-AUDIT.md` (updated after publish).

## Next Command

1. **`/gsd-complete-milestone v1.4`** when you want roadmap + requirements archived under **`milestones/`** and `PROJECT.md` evolved per GSD.
2. **`git pull`** on any other clone — **`main`** now includes **`0.3.1`** release merge (**`c52542b`** area).

Ship checklist **`.planning/FOLLOW-SHIP-v1.4.md`** is satisfied for **`0.3.1`**; keep it as a template for the next release. **`docs/releasing.md`** remains the deep runbook.

**Resume file:** `.planning/phases/24-public-hex-release-parity-gates/24-VERIFICATION.md`

---
*Last updated: 2026-04-17 — Hex 0.3.1 published; SHIP + Phase 24 closed in planning*
