# Phase 120 Plan: Per-Touchpoint Audit Pass

**Status:** Complete
**Requirements:** AUDIT-01

## Tasks

- Enumerate every admin-UI touchpoint across 9 audit units (6 screens + shell chrome + cross-cutting error/empty + cross-cutting mobile) at three altitudes (element → component → page/flow).
- Score each touchpoint 0–3 on seven dimensions (D1 token consistency, D2 least-surprise, D3 a11y, D4 responsive, D5 brand, D6 state coverage, D7 motion), against the 40 Phase 119 baseline PNGs + the LiveView/component/token source.
- Tag each finding with severity (blocker/structural/polish) and fix-class (token/component/screen/motion/seed).
- Promote any finding recurring on ≥3 screens to a systemic token/component fix.
- Confirm or refute each "Design-system tightening target" hypothesis from the milestone plan with file-anchored evidence.
- Produce ONE ranked, fix-class-tagged backlog with a systemic-vs-per-screen-vs-motion split, mapping each item to its downstream phase (121–127).
- No pixel/CSS/component changes — read-only analysis; the only writes are the planning/backlog artifacts.

## Verification

- `mix verify.opsui` stays green (no source changed).
- Backlog written to `120-AUDIT-BACKLOG.md` with the full table, the systemic/per-screen/motion split, the executive summary (counts by severity + fix-class, top systemic fixes), and the plan-hypothesis confirm/refute table.
- Phase artifacts (PLAN/SUMMARY/VERIFICATION) present; roadmaps + STATE updated.
