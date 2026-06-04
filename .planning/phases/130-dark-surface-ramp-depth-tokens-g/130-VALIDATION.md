---
phase: 130
slug: dark-surface-ramp-depth-tokens-g
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-04
---

# Phase 130 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Source: `130-RESEARCH.md` § Validation Architecture (HIGH confidence, live-file verified).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework (unit/a11y)** | ExUnit — `mix test`, `mix opsui.test_a11y` (run from `scrypath_ops/`) |
| **Framework (contrast/e2e)** | Playwright — `npm run test:e2e:admin-contrast` (from `examples/scrypath_ecommerce/`) |
| **Framework (light token)** | Node script — `node contrast-checker.mjs` (from `examples/scrypath_ecommerce/`) |
| **Framework (pixel-diff)** | Disposable `pixelmatch` loop — Wave 0 artifact (no built-in `toMatchSnapshot`) |
| **Config files** | `scrypath_ops/mix.exs`; `examples/scrypath_ecommerce/playwright.config.ts` |
| **Quick run command** | `mix test` (from `scrypath_ops/`) |
| **Full suite command** | `mix test && mix opsui.test_a11y && npm run test:e2e:admin-contrast` |
| **Estimated runtime** | ~sub-second light token check · ~tens of sec ExUnit · ~minutes for the contrast matrix |

> Note (D-13 / research drift): `mix verify.opsui` does **NOT** exist. Use the real targets above, or add a `verify.opsui` alias as part of this phase.

---

## Sampling Rate (D-11 order)

- **After every task commit:** `mix test` (from `scrypath_ops/`)
- **After the token-swap tasks:** `node contrast-checker.mjs` — light AA/AAA counts MUST match the Phase 128 baseline (proves the light token graph did not move)
- **After the shadow-override task:** `npm run test:e2e:admin-contrast` — dark AA failures must resolve Phase 128 cluster 1
- **Before `/gsd:verify-work` (phase gate):** Light 20-PNG pixel-diff → **0 diff pixels**; then `mix opsui.test_a11y` green
- **Max feedback latency:** sub-second (token check) to a few minutes (full contrast matrix)

---

## Per-Task Verification Map

| Req ID | Behavior | Test Type | Automated Command | File Exists | Status |
|--------|----------|-----------|-------------------|-------------|--------|
| DARKTOKEN-01-a | Dark ramp renders 4 distinct steps (`#0C0F14→#141923→#1B2230→#2A3446`) | e2e contrast | `npm run test:e2e:admin-contrast` | ✅ `admin_contrast_matrix.spec.ts` | ⬜ pending |
| DARKTOKEN-01-b | Named recipes step **up** in elevation in dark (cluster 1 → 0 AA fails) | e2e contrast | `npm run test:e2e:admin-contrast` | ✅ | ⬜ pending |
| DARKTOKEN-01-c | Light is **pixel-identical** (0 diff pixels, 20 shots) | visual diff | `node e2e/light-pixel-diff.mjs` (Wave 0) | ❌ W0 | ⬜ pending |
| DARKTOKEN-01-d | No Elixir test regressions | unit | `mix test` | ✅ existing suite | ⬜ pending |
| DARKTOKEN-01-e | No a11y regressions | unit/a11y | `mix opsui.test_a11y` | ✅ | ⬜ pending |
| DARKTOKEN-01-f | Light token contrast counts unchanged vs Phase 128 | fast token check | `node contrast-checker.mjs` | ✅ | ⬜ pending |
| DARKTOKEN-01-g | `DESIGN-TOKENS.md` records the 4-step elevation ramp | manual review | `git diff scrypath_ops/assets/css/DESIGN-TOKENS.md` | ✅ file exists, section to add | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `examples/scrypath_ecommerce/e2e/light-pixel-diff.mjs` (or equivalent) — disposable Node script that re-shoots the 20 light-mode admin PNGs, `pixelmatch`-diffs each against `.tmp/admin-screenshots/*light*`, and exits non-zero on any diff > 0. This is the minimal light-parity gate artifact (D-11 step 4 / D-12 defers the full matrix to Phase 136).
- [ ] Verify `pixelmatch` (+ `pngjs`) availability in `examples/scrypath_ecommerce/package.json`; install if absent (research flagged this as LOW-confidence / unverified).

*All other infrastructure (ExUnit, a11y task, contrast matrix spec, contrast-checker.mjs, light baseline PNGs) already exists.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `DESIGN-TOKENS.md` elevation-surface subsection present and correct | DARKTOKEN-01-g | Doc content is prose/table, not assertable by the test harness | Confirm the committed `DESIGN-TOKENS.md` diff adds an elevation-surface subsection with the 4-step dark ramp table (`#0C0F14 / #141923 / #1B2230 / #2A3446`) |
| Named recipes visibly step **up** in dark | DARKTOKEN-01-b | Perceived elevation/separation beyond AA contrast is a visual judgment | Inspect re-shot dark PNGs (or running `/admin` in dark) — panels seat above bg with visible separation (contrast AA is the automated proxy) |

---

## Validation Sign-Off

- [ ] All tasks have an `<automated>` verify or a Wave 0 dependency
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers the MISSING reference (`light-pixel-diff.mjs`)
- [ ] No watch-mode flags
- [ ] Feedback latency acceptable (sub-second token check available per-commit)
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
