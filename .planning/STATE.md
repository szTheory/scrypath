---
gsd_state_version: 1.0
milestone: v1.4
milestone_name: Public package parity & operator depth
current_phase: 24
current_phase_name: Public Hex release & parity gates
current_plan: "24-01, 24-02, 24-03"
status: at_release_gate
stopped_at: "Phase 26 closed (verified + automated UAT via mix verify.phase26). v1.4 engineering complete except SHIP: tick Phase 24 when published, then /gsd-complete-milestone."
last_updated: "2026-04-17T23:45:00Z"
last_activity: 2026-04-17
progress:
  total_phases: 3
  completed_phases: 2
  total_plans: 8
  completed_plans: 8
  percent: 67
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-17)

**Core value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

**Current focus:** Milestone **v1.4** — **Phase 24** is the only open roadmap checkbox (Hex publish + SHIP-01..03). Phases **25** and **26** are **complete** on the branch (`mix verify.meilisearch_smoke`, **`mix verify.phase26`**).

## Current Position

**Phase:** Maintainer focus **24** (release) — **Phase 26** ✅ 2026-04-17 — plans executed, **`26-VERIFICATION.md`** passed, **`26-UAT.md`** complete (automated gate).  
**Prior:** Phase 25 complete — `hot_apply/3`, `mix scrypath.settings.hot_apply`, smoke CI.  
**Phase 24:** Plans 24-01..03 executed + `24-VERIFICATION.md`; keep ROADMAP **`[ ]`** until you merge/publish and intentionally close the release row.

## Accumulated Context

### Decisions

(See `.planning/PROJECT.md` Key Decisions — unchanged at milestone boundary.)

**Phase 24 (release slice):** See `.planning/phases/24-public-hex-release-parity-gates/24-CONTEXT.md` — target `0.3.1`, Release Please alignment, narrow SHIP-02 sweep, post-publish `release_parity` on both publish workflows.

**Phase 26 (operator rollups):** See `.planning/phases/26-operator-failure-rollups/26-CONTEXT.md` — opt-in `failed_sync_work/2`, dense `%ReasonClassCounts{}`-style struct, reconcile field, Mix defaults + `--json`. Canonical verify: **`mix verify.phase26`**.

### Blockers / Concerns

- **SHIP:** Hex publish + Release Please merge still the active gate for closing v1.4 (see **`docs/releasing.md`**).

### Deferred Items

- **Quick-task stubs (audit-open):** two slugs reported **missing** on disk — same class as v1.3 close; safe to drop from audit index or recreate files if you still want those tasks tracked.
- **v1.4 milestone close:** blocked on **SHIP** only — see **`.planning/v1.4-MILESTONE-AUDIT.md`**.

## Pre-close evidence (automated)

| Gate | Result (2026-04-17) |
|------|---------------------|
| `mix verify.phase11` | pass |
| `mix verify.phase26` | pass |
| `mix verify.workspace_clean` | pass (after last commit) |
| `mix format --check-formatted` | pass |

**Milestone audit file:** `.planning/v1.4-MILESTONE-AUDIT.md` (`status: implementation_ready_pending_hex_ship`).

## Next Command

**Start here:** open **`.planning/FOLLOW-SHIP-v1.4.md`** and check boxes top to bottom. It is the only path you need until the milestone is closed.

Background (optional): **`.planning/v1.4-MILESTONE-AUDIT.md`** — engineering vs **SHIP** boundary. Full narrative: **`docs/releasing.md`**.

**Resume file:** `.planning/phases/24-public-hex-release-parity-gates/24-VERIFICATION.md`

---
*Last updated: 2026-04-17 — v1.4 pre-close audit written; SHIP pending Hex*
