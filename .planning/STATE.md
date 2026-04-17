---
gsd_state_version: 1.0
milestone: v1.4
milestone_name: Public package parity & operator depth
current_phase: 24
current_phase_name: Public Hex release & parity gates
current_plan: "24-03"
status: ready
stopped_at: Phase 24 plans 24-01..03 executed locally — SUMMARY + VERIFICATION in phase dir; merge when satisfied
last_updated: "2026-04-17T23:59:00.000Z"
last_activity: 2026-04-17
progress:
  total_phases: 3
  completed_phases: 0
  total_plans: 3
  completed_plans: 3
  percent: 100
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-17)

**Core value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

**Current focus:** Milestone **v1.4** — Phase **24** implementation merged pending your review; Hex `0.3.1` still ships via Release Please after merge.

## Current Position

**Phase:** 24 of 26 (v1.4) — **Implementation done** (3/3 plans; verify + merge)  
**Plan:** 24-01 ✓, 24-02 ✓, 24-03 ✓  
**Status:** Summaries and `24-VERIFICATION.md` in `.planning/phases/24-public-hex-release-parity-gates/`; roadmap phase checkbox still open until you mark v1.4 slice complete after release PR / publish.

## Accumulated Context

### Decisions

(See `.planning/PROJECT.md` Key Decisions — unchanged at milestone boundary.)

**Phase 24 (release slice):** See `.planning/phases/24-public-hex-release-parity-gates/24-CONTEXT.md` — target `0.3.1`, Release Please alignment, narrow SHIP-02 sweep, post-publish `release_parity` on both publish workflows.

### Blockers / Concerns

- Uncommitted implementation may still exist outside `.planning/` — reconcile before SHIP work.

### Deferred Items

(Previous quick-task stubs remain deferred from v1.3 close — see git history of `STATE.md` if needed.)

## Next Command

1. Review git diff, then commit. Mark Phase 24 complete in ROADMAP when the Hex release slice is merged/published as you define “done.”

---
*Last updated: 2026-04-17 — Phase 24 execute: plans 01–03 + verification*
