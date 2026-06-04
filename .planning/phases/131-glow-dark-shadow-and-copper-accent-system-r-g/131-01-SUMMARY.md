---
phase: "131"
plan: "01"
subsystem: scrypath_ops/assets/css
tags: [css, design-tokens, dark-mode, shadow, copper-accent, glow]
dependency_graph:
  requires: []
  provides: [shadow-token-contracts, copper-class-vocabulary, glow-class]
  affects: [scrypath_ops/assets/css/app.css]
tech_stack:
  added: []
  patterns: [D-10-dual-path-dark-override, @theme-light-defaults, @layer-components-classes]
key_files:
  created: []
  modified:
    - scrypath_ops/assets/css/app.css
decisions:
  - "baseline FRESH — A1 confirmed: 20 light PNGs dated Jun 4 12:04, post Phase-130 body-class fix"
  - "--shadow-ops-panel-dark declared dark-only (never in @theme/light) — undeclared-ness is the pixel-identity mechanism"
  - "Two light defaults (--shadow-ops-glow: none, --shadow-ops-glow-copper: none) appended to @theme shadow ladder"
  - "Three dark tokens appended into both Precedent A blocks (D-10 dual-path); no new block created"
  - "Five classes placed after .ops-badge-running in @layer components — natural adjacency to badge vocab"
  - ".ops-copper-badge uses color: var(--color-base-content) for text (not secondary) — AA verified"
  - "Copper is brand accent, not status tone — zero references from tone_class/1 or badge_class/1"
metrics:
  duration: "~15min"
  completed: "2026-06-04"
  tasks_completed: 3
  files_modified: 1
---

# Phase 131 Plan 01: Token + Class Contracts Summary

Three dark shadow tokens (D-10 dual-path Precedent A), two @theme light-default no-ops, and five @layer components classes (.ops-glow + four .ops-copper-* variants) declared as the interface-first contracts that downstream plans 02 and 03 consume directly.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Confirm light-baseline freshness (Wave-0 gate, RESEARCH A1) | (no edit) | none — verification only |
| 2 | Declare three dark shadow tokens + two @theme light defaults | 71a6a27 | scrypath_ops/assets/css/app.css |
| 3 | Declare .ops-glow and copper vocabulary classes in @layer components | 32ced41 | scrypath_ops/assets/css/app.css |

## Baseline Freshness Verdict

**baseline FRESH — A1 confirmed**

20 light baseline PNGs (`examples/scrypath_ecommerce/.tmp/admin-screenshots/*--light--*.png`) are present and dated Jun 4 12:04 — same day as Phase 130 completion and its documented "baseline updated post-body-class fix." Downstream pixel-diff results may now be trusted.

## What Was Built

### Task 2: Token declarations (app.css)

Added to `@theme` block alongside existing `--shadow-ops-*` ladder (after `--shadow-ops-focus`):
```css
--shadow-ops-glow: none;          /* light no-op — Precedent A overrides in dark */
--shadow-ops-glow-copper: none;   /* light no-op */
```

Appended into BOTH Precedent A dark blocks (`[data-theme="dark"]` + `@media html:not([data-theme="light"])`):
```css
--shadow-ops-panel-dark: 0 0 0 1px rgba(0,0,0,0.30), 0 1px 3px rgba(0,0,0,0.45);
--shadow-ops-glow:        0 0 8px 2px rgba(108,92,231,0.30);
--shadow-ops-glow-copper: 0 0 6px 1px rgba(193,122,62,0.25);
```

Both dark blocks are identical (D-10 dual-path; covers explicit toggle + system dark).

### Task 3: @layer components classes (app.css)

Five classes inserted after `.ops-badge-running` in `@layer components`:
- `.ops-glow`: `box-shadow: var(--shadow-ops-glow)` + transition (light no-op since token is `none`)
- `.ops-copper-eyebrow`: text-ops-sm / 600 / uppercase / 0.04em / color-secondary
- `.ops-copper-badge`: border + background as secondary color-mix; `color: var(--color-base-content)` (AA verified)
- `.ops-copper-node`: `color: var(--color-secondary)`
- `.ops-copper-node--fill`: `color: var(--color-secondary-content); background: var(--color-secondary)`

Classes are theme-agnostic (reference `var(--color-*)` tokens that flip via `@plugin` blocks). No D-10 dual-path needed for class bodies — only the `--shadow-ops-glow` token value they reference is dark-pathed (done in Task 2).

## Verification Results

| Check | Result |
|-------|--------|
| `--shadow-ops-panel-dark:` count | 2 (both dark paths; never in @theme/light) |
| `--shadow-ops-glow:` count | 3 (1 @theme none + 2 dark) |
| `--shadow-ops-glow-copper:` count | 3 (1 @theme none + 2 dark) |
| Five @layer components classes present | 5 selectors confirmed |
| `.ops-glow` references `var(--shadow-ops-glow)` | Confirmed (not a literal shadow) |
| `.ops-copper-badge` text = base-content | Confirmed (not color-secondary) |
| `.ops-copper-eyebrow` text = color-secondary | Confirmed |
| Copper classes in tone_class/1 or badge_class/1 | Zero references |
| `node contrast-checker.mjs` | 3 AA / 12 AAA — Phase 128 baseline unchanged |
| Light baseline freshness | FRESH — A1 confirmed (20 PNGs, Jun 4) |

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

`.ops-copper-badge`, `.ops-copper-node`, `.ops-copper-node--fill` are declared but not wired into any per-screen template. This is intentional per D-01a — per-screen `.heex` application is deferred to Phase 134 (SCREEN-DARK-01).

## Threat Flags

None. This plan adds only static CSS token literals and class declarations. No input, network, auth, or data flow introduced. T-131-01 (static design literals) and T-131-SC (zero package installs) both accepted per plan threat model.

## Self-Check: PASSED

- [x] `scrypath_ops/assets/css/app.css` modified (confirmed via git log)
- [x] Commit 71a6a27 exists (Task 2)
- [x] Commit 32ced41 exists (Task 3)
- [x] Token counts: panel-dark=2, glow=3, glow-copper=3
- [x] Class count: 5 selectors present
- [x] Contrast baseline unchanged: 3 AA / 12 AAA
