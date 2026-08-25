---
phase: 129-dark-theme-brand-expression-audit-s-r
plan: 01
subsystem: scrypath_ops dark theme audit
tags: [dark-mode, brand-audit, accessibility, contrast, design-tokens]
dependency_graph:
  requires:
    - 128-CONTRAST-REPORT.md (AA spine — 108 violations, 3 clusters, promoted not re-derived)
    - .tmp/admin-screenshots/ (40-shot matrix — visual substrate for DD1–DD5)
    - prompts/scrypath-brand-book.md (dark-signature scoring rubric)
  provides:
    - 129-DARK-AUDIT-BACKLOG.md (single authoritative input for phases 130–135)
  affects:
    - Phase 130 (DARKTOKEN-01 — surface ramp tokens)
    - Phase 131 (GLOW-01 + COPPER-01 — glow/depth/copper)
    - Phase 132 (A11Y-TOKEN-01 — AA remediation)
    - Phase 133 (DARKMOTION-01 — path motion)
    - Phase 134 (SCREEN-DARK-01 — per-screen polish)
    - Phase 135 (SHELL-DARK-01 — shell chrome)
tech_stack:
  added: []
  patterns:
    - DD1–DD6 dark-specific scoring dimensions on 0–3 scale
    - Promote-not-re-derive AA spine from 128-CONTRAST-REPORT.md
    - Systemic promotion rule: same token/recipe failing ≥3 screens → structural
key_files:
  created:
    - .planning/phases/129-dark-theme-brand-expression-audit-s-r/129-DARK-AUDIT-BACKLOG.md
  modified: []
decisions:
  - DK-01 (#1B2230 ramp gap) is finding #1 by construction — systemic AA blocker (128 cluster 1, 1.08:1) + DD1 ramp violation + DD4 depth absence across all 6 screens
  - DD6 AA values promoted verbatim from 128-CONTRAST-REPORT.md — zero ratios independently re-derived
  - 7 systemic promotions (DK-01 through DK-09 as systemic cluster members) route to phases 130–132
  - DD3 glow and DD5 path-line glow show no violations — shell wash is restrained; path diagram elements absent from these screens
  - 19 total findings (4 blocker / 6 structural / 9 polish) across 6 screens; fix-class breakdown: token 10 / component 3 / screen 4 / motion 1 / seed 1
metrics:
  duration: ~35 min
  completed_date: 2026-06-04
  tasks_completed: 2
  files_changed: 1
---

# Phase 129 Plan 01: Dark-Theme Brand-Expression Audit Summary

**One-liner:** 19-finding ranked dark-expression backlog driven by the 128 AA spine + DD1–DD5 brand overlay, anchoring `#1B2230` surface-2 ramp gap as finding #1 across all 6 admin screens.

## What Was Done

Produced `129-DARK-AUDIT-BACKLOG.md` — the single authoritative ranked backlog for phases 130–135. The plan had two tasks: (1) score all 6 dark touchpoints on DD1–DD6 across both viewports, and (2) write the backlog file mirroring the 120-AUDIT-BACKLOG.md format.

**Substrates consumed:**
- `128-CONTRAST-REPORT.md`: 108 AA violations, 3 systemic clusters (`.leading-4` 1.08:1 ramp collapse; dark form inputs 1.19:1; `.bg-primary` 4.3:1 near-miss) — promoted verbatim into DD6/Sev/Scope columns.
- 20 dark screenshots (6 screens × dark × mobile 390 + desktop 1440) — visual substrate for DD1–DD5 brand-expression scoring.
- `prompts/scrypath-brand-book.md` — dark-signature rules (midnight ramp, 65/20/10/5, quiet glow, ambient depth, path-line restraint).
- `scrypath_ops/assets/css/app.css` — exact file:line evidence citations for all findings.
- `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` — component-level touchpoint citations.

**Finding #1 anchored:** DK-01 — the `#1B2230` surface-2 ramp gap — is simultaneously the `.leading-4` 1.08:1 systemic AA blocker (128 cluster 1), a DD1 ramp failure (no surface-2 step in dark daisyUI theme), and a DD4 depth failure (ambient shadow cannot create depth when raised-surface bg = page bg). All 6 screens affected.

**DD6 note:** All AA data is from 128-CONTRAST-REPORT.md. Zero ratios were independently re-derived. The DK-02 (form inputs 1.19:1) and DK-04 (.bg-primary 4.3:1) rows copy ratio/scope/fix_class verbatim from the 128 report clusters.

**Confirmed non-violations (satisfy brand rules):**
- DD3 glow: `.ops-shell` radial violet wash at 14%/34rem = restrained (adequate, score 2). `.ops-route-mark` gradient = reserved for path element (score 3). No violations.
- DD5 path-line restraint: no route/diagram elements in the 6 admin screens. `.ops-intent-card:hover` primary border glow = restrained and contextual. No violations.

## Findings Summary

| Severity | Count | IDs |
|----------|-------|-----|
| Blocker | 4 | DK-01, DK-02, DK-03, DK-04 |
| Structural | 6 | DK-05, DK-06, DK-07, DK-08, DK-09, DK-10 |
| Polish | 9 | DK-11 through DK-19 |

| Fix-class | Count |
|-----------|-------|
| token | 10 |
| component | 3 |
| screen | 4 |
| motion | 1 |
| seed | 1 |

**Systemic promotions (≥3 screens):** 7 — DK-01 (#1B2230 ramp), DK-05 (panel ramp flatness), DK-06 (ambient depth absent), DK-07 (copper absence), DK-08 (neutral ratio dominance), DK-09 (code-block bg inverted), and DK-02 (form inputs).

## Deviations from Plan

None — plan executed exactly as written. Task 1 was internal analysis; Task 2 wrote the backlog file. Scope guard confirmed clean: no source files outside the phase directory were modified.

## Threat Surface Scan

No new runtime endpoints, auth paths, file access patterns, or schema changes. This phase reads in-repo markdown and CSS files and writes one markdown artifact. No untrusted input, no secrets, no network operations.

## Self-Check: PASSED

- [x] `129-DARK-AUDIT-BACKLOG.md` exists at `.planning/phases/129-dark-theme-brand-expression-audit-s-r/129-DARK-AUDIT-BACKLOG.md`
- [x] Three severity tables: `### Blockers`, `### Structural`, `### Polish` all present
- [x] `DK-01` is first row of Blockers table, labeled DD1+DD4+DD6, systemic, blocker
- [x] `1B2230` appears 6+ times (finding #1 anchor, ramp analysis, proposed fix)
- [x] `128-report cluster` references in every DD6 Evidence cell (12 occurrences)
- [x] All 7 req IDs present: DARKTOKEN-01, GLOW-01, COPPER-01, A11Y-TOKEN-01, DARKMOTION-01, SCREEN-DARK-01, SHELL-DARK-01 (26 occurrences total)
- [x] Commit `6a488d9` exists: `feat(129-01): write 129-DARK-AUDIT-BACKLOG.md`
- [x] No source files outside phase directory modified (pre-existing untracked static assets in `scrypath_ops/priv/static/` were present before this phase; STATE.md modification was pre-existing orchestrator state, not introduced by this task)
