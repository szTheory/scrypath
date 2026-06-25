---
phase: 134
slug: under-iterated-surface-polish-dual-theme-s
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-25
---

# Phase 134 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution. Derived from
> 134-RESEARCH.md `## Validation Architecture` + CONTEXT.md D-10→D-14. Binding gate is a new
> Playwright computed-style spec; light parity is pinned by the existing pixel-diff at threshold 0.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework (binding gate)** | Playwright `@playwright/test ^1.54.2` + `@axe-core/playwright ^4.11.3` |
| **Framework (static contract)** | ExUnit (`scrypath_ops/test/`) via `mix verify.opsui` → `mix test` |
| **Config file** | `examples/scrypath_ecommerce/playwright.config.*` (existing) + new spec `e2e/admin_surface_depth.spec.ts` |
| **Quick run command** | `npm run test:e2e:admin-depth` (NEW script → `playwright test e2e/admin_surface_depth.spec.ts`) |
| **Full suite command** | `npm run test:e2e` + `node e2e/light-pixel-diff.mjs` + `mix verify.opsui` + `make contrast` + `npm run test:e2e:admin-contrast` |
| **Estimated runtime** | ~90s quick (depth spec across 2 themes × 2 viewports); ~5–8 min full suite |

---

## Sampling Rate

- **After every task commit:** Run `npm run test:e2e:admin-depth` (surfaces touched by that task) + `mix verify.opsui` if any CSS/token changed.
- **After every plan wave:** Run `npm run test:e2e` + `node e2e/light-pixel-diff.mjs` + `make contrast` + `npm run test:e2e:admin-contrast`.
- **Before `/gsd-verify-work`:** Full suite green + 40-shot human spot-review for "earned copper feel"/halo aesthetic reads.
- **Max feedback latency:** ~90 seconds (quick depth spec).

**Hard precondition (D-14):** all browser-driven checks run against a **booted, seeded ops server with ops assets built first**. The ecommerce dev server does NOT live-reload the `scrypath_ops` path-dep — rebuild assets + restart `mix phx.server` (or run dev compose `--no-deps` against source) or the gate tests stale CSS.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 134-01-01 | 01 | 1 | SCREEN-DARK-01 | — | N/A (visual/CSS) | e2e computed-style | `npm run test:e2e:admin-depth` | ❌ W0 (new spec) | ⬜ pending |
| 134-01-02 | 01 | 1 | SCREEN-DARK-01 | — | N/A | unit (ExUnit token tripwire) | `mix verify.opsui` | ❌ W0 (new test) | ⬜ pending |
| 134-02-01 | 02 | 2 | SCREEN-DARK-01 | — | N/A | e2e computed-style (hover D-15) | `npm run test:e2e:admin-depth` | ✅ (after W0) | ⬜ pending |
| 134-02-02 | 02 | 2 | SCREEN-DARK-01 | — | N/A | e2e computed-style (copper D-01 + negative D-02) | `npm run test:e2e:admin-depth` | ✅ | ⬜ pending |
| 134-02-03 | 02 | 2 | SCREEN-DARK-01 | — | N/A | measured ratio (DK-13 trigger) | `npm run test:e2e:admin-depth` | ✅ | ⬜ pending |
| 134-03-01 | 03 | 3 | SCREEN-DARK-01 | — | N/A | light pixel-diff threshold 0 | `node e2e/light-pixel-diff.mjs` | ✅ existing | ⬜ pending |
| 134-03-02 | 03 | 3 | SCREEN-DARK-01 | — | N/A | AA gate (axe, 3 themes) | `make contrast` + `npm run test:e2e:admin-contrast` | ✅ existing | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky. Task IDs are indicative — final IDs come from PLAN.md.*

---

## Requirements → Test Map (binding assertions)

| Req / Criterion | Behavior | Check type | Automated assertion (selector → prop → expected) | Risk note |
|-----------------|----------|-----------|--------------------------------------------------|-----------|
| Criterion 1 (DK-17, Search rows separate in dark) | Rows lift off floor | computed-style | `.ops-result-row` / `.ops-data-card` `backgroundColor === rgb(27,34,48)` **AND** sRGB rel-luminance exceeds `--ops-bg` `rgb(12,15,20)` by ≥ delta floor (start 0.015) | exact-rgb OK (flat token) |
| Criterion 1 (hover, D-12/D-15) | Hover perceptible on BOTH surfaces | computed-style | `.ops-result-row:hover` **and** `.ops-object-item:hover` `borderColor` resolves to `primary 55%` in dark **and differs from resting** | proves D-15 on both surfaces |
| Criterion 2 (DK-16, Sync/Drift depth) | Sections + preflight step up | computed-style (relative) | `.ops-muted-panel` luminance > `--ops-bg` floor by ≥ delta; `.ops-preflight__card--locked` luminance **>** `.ops-preflight__card` | **R2**: luminance-delta/relative, NOT exact rgb (alpha-mixed) |
| Criterion 2 (DK-18, Playbooks cards) | Cards raised; active item glows | computed-style | `.ops-data-card` rgb/luminance proof; `.ops-object-item-active` `boxShadow` contains `108, 92, 231` in dark, `none` in light | **R4**: populated seed must create a playbook |
| Criterion 3 (D-01, earned copper) | Copper applied at one site | computed-style + **negative** | `.ops-copper-badge` (Control Room recommended card) tint resolves to `--color-secondary` copper; **negative:** no `tone_class`/`badge_class` status chip computes to copper | proves D-01 + D-02 "never a status tone" |
| DK-13 (table separators) | Border vs surface contrast | measured number | Compute contrast ratio (posture table row border ↔ `#1b2230`) at dark 390; **if < 1.20:1 → boost to 18%; else record ratio** | **R1**: no existing selector — measure daisyUI default row border |
| Light parity (D-13) | Light pixel-identical | pixel-diff | `node e2e/light-pixel-diff.mjs` threshold **0** | do NOT duplicate light depth checks |
| Static pre-flight (D-13) | Token values pinned | ExUnit value-assert | `--ops-surface-2: #1b2230`; raised recipes reference the token; dark hover = `primary 55%` | **R3**: NEW value-assertion test, not the orphan checker |
| AA gate (UI-SPEC) | 0 AA failures all 3 themes | axe | `make contrast` + `npm run test:e2e:admin-contrast` | inherited Phase 132; must stay green |

---

## Wave 0 Requirements

- [ ] `examples/scrypath_ecommerce/e2e/admin_surface_depth.spec.ts` — new binding gate (covers SCREEN-DARK-01 criteria 1+2+3 deterministic parts); clones `admin_path_motion.spec.ts` idiom and imports `THEME_MODES`/`assertSystemDarkInvariants`/seed map from `admin_contrast_matrix.spec.ts`.
- [ ] npm script `test:e2e:admin-depth` in `examples/scrypath_ecommerce/package.json`.
- [ ] NEW ExUnit value-assertion (token tripwire) under `scrypath_ops/test/scrypath_ops_web/` (R3) — runs under `mix verify.opsui`.
- [ ] Populated-playbooks seed step inside the depth spec `prepare` (R4).
- [ ] (Conditional) DK-13 dark-only daisyUI-table-row-border override — only if the 1.20:1 trigger fires (R1).

*Framework install: none — Playwright + axe already in `package.json`; ExUnit already present.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| "Earned copper *feel*" / non-decorative read | Criterion 3 | Aesthetic judgment resists a threshold | 40-shot matrix, dark target shots — confirm copper reads as earned on the scan path, not decorative |
| Warm-halo absence on verdict hero (DK-14) | Criterion 2 | Subjective "halo" read | Spot-review dark posture hero shot; if halo persists, file for Phase 135 (D-06), do not patch locally |

*All threshold-able behaviors have automated verification; the two rows above are explicitly human-spot-review per CONTEXT D-13/D-06.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (new depth spec, npm script, ExUnit tripwire, populated seed)
- [ ] No watch-mode flags
- [ ] Feedback latency < 90s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
