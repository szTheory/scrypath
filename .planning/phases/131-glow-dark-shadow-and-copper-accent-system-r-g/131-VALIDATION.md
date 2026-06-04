---
phase: 131
slug: glow-dark-shadow-and-copper-accent-system-r-g
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-04
---

# Phase 131 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> This is the **Phase 130 D-11 proof bundle, re-run** — no new tooling. CSS/token-only
> phase: copper AA is a static spec assertion (RESEARCH Finding F8), NOT an automated check.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Elixir `mix test` + `mix opsui.test_a11y` (via `mix verify.opsui`); Node AA checker; Playwright axe matrix; Node pixel-diff |
| **Config file** | `scrypath_ops/mix.exs:87` (`verify.opsui` alias); `examples/scrypath_ecommerce/contrast-checker.mjs`; `examples/scrypath_ecommerce/e2e/` |
| **Quick run command** | `node contrast-checker.mjs` (from `examples/scrypath_ecommerce/`, sub-second) |
| **Full suite command** | `mix verify.opsui` (Postgres req) + `node e2e/light-pixel-diff.mjs` (after `mix assets.build`) |
| **Estimated runtime** | quick ~1s; full ~30–60s + browser matrix |

---

## Sampling Rate

- **After every task commit:** `node contrast-checker.mjs` — light AA count must stay at **3 AA / 12 AAA** (Phase 128 baseline; catches any base-content muted-text regression).
- **After every plan wave:** `mix verify.opsui` (exit 0) + `node e2e/light-pixel-diff.mjs` (**0 / 20**) after `mix assets.build`.
- **Before `/gsd:verify-work`:** Full D-11 bundle green (see Phase Gate below).
- **Max feedback latency:** ~1s (quick) / ~60s (full).

---

## Per-Task Verification Map

> Task IDs are assigned by the planner. Each task maps to the success-criterion gate below.
> The phase gate is the D-11 bundle, not per-task unit tests (this is a CSS/token phase).

| Success Criterion | Requirement | Check Type | Automated Command | Expected |
|-------------------|-------------|-----------|-------------------|----------|
| SC-1 seated dark depth, light keeps lift | GLOW-01 | pixel-identity + manual | `node e2e/light-pixel-diff.mjs`; human dark-browser check | Failed pairs **0/20**; dark seated-depth confirmed (perceptual) |
| SC-2 glow on route/active/hover only | GLOW-01 | pixel-identity + static grep | `light-pixel-diff` + grep `--shadow-ops-glow` light default = `none` | 0/20; `none` in `@theme`; glow absent on forbidden targets |
| SC-3 AA-safe copper vocabulary @~5% | COPPER-01 | static spec assertion (F8) + axe (eyebrow) | UI-SPEC 9-pairing table review; `npm run test:e2e:admin-contrast` | AA table all PASS (manual); Cluster 1 = 0 |
| Light non-regression (all changes) | GLOW-01, COPPER-01 | regression | `node contrast-checker.mjs`; `light-pixel-diff` | 3 AA / 12 AAA; 0/20 |
| Existing UI behavior unchanged | — | unit | `mix verify.opsui` | 129 tests + 4 a11y, exit 0 |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] **Light baseline freshness (RESEARCH A1):** confirm `examples/scrypath_ecommerce/.tmp/admin-screenshots/*--light--*.png` (20 files) is still the canonical Jun-3 baseline post-Phase-130. If Phase 130's body-class fix changed light rendering, re-capture once before relying on `0/20`.
- [ ] No new test files needed — all four gate scripts exist (`node --check` clean / wired in `mix.exs`).
- [ ] Dev server + Postgres available for `mix verify.opsui` and `test:e2e:admin-contrast`.

*Otherwise: existing infrastructure covers all phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Copper 9-pairing AA table holds | COPPER-01 | F8 — copper classes use raw `var(--color-secondary)`/`var(--color-base-content)` refs the contrast harness does not track | Review each pairing in `131-UI-SPEC.md` AA evidence table against computed values; all rows must read PASS |
| Dark seated-depth reads correctly | GLOW-01 | Perceptual — shadow depth is not machine-measurable | Human review in dark-mode browser: `.ops-panel`/intent-card/cmdk/flash read as seated, not floating |
| Quiet glow restraint | GLOW-01 | Perceptual — "quiet not loud" is a brand judgment | Human review: glow only on route-mark/active-pill/recommended-card; never text/resting panels/bg floods |

---

## Validation Sign-Off

- [ ] All success criteria have an automated gate or a documented manual verification
- [ ] Sampling continuity: light-AA quick check after every commit
- [ ] Wave 0 baseline-freshness check completed before pixel-diff is trusted
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] Cluster 3 (primary-violet) recorded as out-of-scope-known-fail → deferred to Phase 132
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
