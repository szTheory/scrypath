---
phase: 131
slug: glow-dark-shadow-and-copper-accent-system-r-g
status: gate-run
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-04
gate_run: 2026-06-04
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

| Success Criterion | Requirement | Check Type | Automated Command | Expected | Status |
|-------------------|-------------|-----------|-------------------|----------|--------|
| SC-1 seated dark depth, light keeps lift | GLOW-01 | pixel-identity + manual | `node e2e/light-pixel-diff.mjs`; human dark-browser check | Failed pairs **0/20**; dark seated-depth confirmed (perceptual) | ✅ 0/20 PASS; perceptual: APPROVED 2026-06-04 (Task 3 human-verify) |
| SC-2 glow on route/active/hover only | GLOW-01 | pixel-identity + static grep | `light-pixel-diff` + grep `--shadow-ops-glow` light default = `none` | 0/20; `none` in `@theme`; glow absent on forbidden targets | ✅ 0/20; `--shadow-ops-glow: none` at app.css:149 confirmed |
| SC-3 AA-safe copper vocabulary @~5% | COPPER-01 | static spec assertion (F8) + axe (eyebrow) | UI-SPEC 9-pairing table review; `npm run test:e2e:admin-contrast` | AA table all PASS (manual); Cluster 1 = 0 | ✅ all-PASS (Task 2 manual re-confirm); Cluster 1 = 0 |
| Light non-regression (all changes) | GLOW-01, COPPER-01 | regression | `node contrast-checker.mjs`; `light-pixel-diff` | 3 AA / 12 AAA; 0/20 | ✅ 3 AA / 12 AAA (baseline unchanged); 0/20 |
| Existing UI behavior unchanged | — | unit | `mix verify.opsui` | 129 tests + 4 a11y, exit 0 | ✅ 129 tests, 0 failures, exit 0 |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] **Light baseline freshness (RESEARCH A1):** confirmed by 131-01-SUMMARY (20 PNGs, Jun-4, post-Phase-130 body-class fix; baseline re-shot in Plan 02 to resolve content drift). `0/20` pixel-diff result is trusted.
- [x] No new test files needed — all four gate scripts exist (`node --check` clean / wired in `mix.exs`).
- [x] Dev server + Postgres available — `mix verify.opsui` ran (Postgres via ecto.create/migrate), `test:e2e:admin-contrast` ran against dev server at `http://127.0.0.1:4012`.

*Infrastructure covers all phase requirements.*

---

## D-11 Bundle Gate Results (Plan 04 — Task 1)

Assets rebuilt via `mix assets.build` (Pitfall 5 compliance) before all four scripts.

### Gate 1: `mix verify.opsui` — ✅ EXIT 0

```
Nav contract OK: operator-ia.md matches Nav.primary/0
Running ExUnit with seed: 466292, max_cases: 36

...................................................................................................................................
Finished in 1.9 seconds (1.2s async, 0.7s sync)
2 doctests, 129 tests, 0 failures
EXIT_CODE: 0
```

**Result:** 129 tests, 0 failures, exit 0. Gate PASS.

---

### Gate 2: `node contrast-checker.mjs` — ✅ 3 AA / 12 AAA (Phase 128 baseline unchanged)

```
Contrast check: FAIL
  AA failures:  3
  AAA advisory: 12
  Report: test-results/contrast/contrast-report.token.json

AA Failures:
  [light] .ops-text-meta: 3.9 (required: 4.5, role: text)
  [light] .ops-cmdk__item-hint: 3.9 (required: 4.5, role: text)
  [light] .ops-cmdk__empty: 3.9 (required: 4.5, role: text)
EXIT_CODE: 1
```

**Result:** 3 AA failures (Phase 128 baseline light muted-text, deferred to Phase 132 A11Y-TOKEN-01) + 12 AAA advisory. Count unchanged from Phase 128 baseline. Per F8, copper classes use raw `var(--color-secondary)`/`var(--color-base-content)` refs that the checker does NOT track — a stable count here confirms no new base-content regression. Gate PASS (count = baseline).

---

### Gate 3: `node e2e/light-pixel-diff.mjs` — ✅ Failed pairs: 0 / 20

```
Baseline: /Users/jon/projects/scrypath/examples/scrypath_ecommerce/.tmp/admin-screenshots
Fresh:    /Users/jon/projects/scrypath/examples/scrypath_ecommerce/.tmp/pixel-diff-fresh
Diff out: /Users/jon/projects/scrypath/examples/scrypath_ecommerce/.tmp/pixel-diff-out
Light PNGs to diff: 20

OK:   00-control-room--light--desktop--incident.png
OK:   00-control-room--light--mobile--incident.png
OK:   01-posture--light--desktop--incident.png
OK:   01-posture--light--mobile--incident.png
OK:   02-failed-sync--light--desktop--populated.png
OK:   02-failed-sync--light--mobile--populated.png
OK:   03-sync-drift--light--desktop--drift.png
OK:   03-sync-drift--light--mobile--drift.png
OK:   04-control-room--light--desktop--all-green.png
OK:   04-control-room--light--mobile--all-green.png
OK:   05-posture--light--desktop--all-green.png
OK:   05-posture--light--mobile--all-green.png
OK:   06-search--light--desktop--results.png
OK:   06-search--light--mobile--results.png
OK:   07-failed-sync--light--desktop--empty.png
OK:   07-failed-sync--light--mobile--empty.png
OK:   08-search--light--desktop--zero-results.png
OK:   08-search--light--mobile--zero-results.png
OK:   09-playbooks--light--desktop--empty-workspace.png
OK:   09-playbooks--light--mobile--empty-workspace.png

Light pixel-diff: PASS
  Failed pairs: 0 / 20
EXIT_CODE: 0
```

**Result:** 0/20 failed pairs, exit 0. All 20 light PNGs byte-identical against the Jun-4 baseline. Gate PASS.

---

### Gate 4: `npm run test:e2e:admin-contrast` — ✅ Cluster 1 = 0 (131 gate condition met)

Run against dev server `http://127.0.0.1:4012` via `PLAYWRIGHT_BASE_URL=http://127.0.0.1:4012`.

```
Running 3 tests using 1 worker

  ✘  1 [chromium] › e2e/admin_contrast_matrix.spec.ts:404:7 › admin contrast matrix — incident (19.4s)
  ✘  2 [chromium] › e2e/admin_contrast_matrix.spec.ts:404:7 › admin contrast matrix — all_green (18.5s)
  ✘  3 [chromium] › e2e/admin_contrast_matrix.spec.ts:404:7 › admin contrast matrix — empty (17.7s)

EXIT_CODE: 1 (matrix exit — NOT the 131 gate; Cluster 1 = 0 is the gate)
```

**Cluster analysis of all violations:**

| Scenario | AA failures | Selectors violated | Cluster |
|----------|------------|-------------------|---------|
| incident | 8 | `.ops-nav-item-active` (4.3:1) only | Cluster 3 |
| all_green | 16 | `.ops-nav-item-active` (4.3:1) + `.bg-primary` (4.3:1) | Cluster 3 |
| empty | 12 | `.ops-nav-item-active` (4.3:1) + `.bg-primary` (4.3:1) | Cluster 3 |

**Cluster 1** (`.leading-4` ramp collapse): **0 violations** across all 3 scenarios. **Gate condition PASS.**

**Cluster 3** (primary-violet `#6c5ce7` @ 4.3:1 on cream — `.ops-nav-item-active` / `.bg-primary`): **OUT-OF-SCOPE KNOWN-FAIL — deferred to Phase 132 (A11Y-TOKEN-01)**. Exactly as Phase 130-VERIFICATION documented. This cluster is NOT gated in Phase 131. The matrix exit code of 1 is caused entirely by Cluster 3 violations.

**Static grep confirmation** (SC-2 glow-restraint light default):
```
app.css:149:  --shadow-ops-glow: none;          /* light no-op — Precedent A overrides in dark */
```
`--shadow-ops-glow` has `none` light default in `@theme`. Glow is a no-op in light. Confirmed.

---

## Copper 9-Pairing AA Re-Confirmation (Plan 04 — Task 2)

**Method:** Manual re-confirmation of WCAG 2.1 sRGB relative-luminance math against live `@plugin` hex values (Research F2 — confirmed from `app.css` dark block lines 23–59, light block lines 61–97). This is a static design-contract assertion per RESEARCH Finding F8 (copper classes use raw `var(--color-secondary)` / `var(--color-base-content)` refs the contrast harness does NOT track).

**Live hex values confirmed from app.css `@plugin` blocks:**

| Token | Dark | Light |
|-------|------|-------|
| `--color-secondary` | `#c17a3e` | `#a85d2e` |
| `--color-secondary-content` | `#0c0f14` | `#fffdf8` |
| `--color-base-content` | `#f4f1ea` | `#141923` |
| `--ops-surface-1` | `#141923` | `#fffdf8` |
| `--ops-surface-2` | `#1b2230` | `#faf7f2` |

**Re-confirmed pairing table (all 6 text pairings + 3 non-text/exempt):**

| # | Pairing | Theme | Hex foreground | Hex background | Ratio | AA (4.5:1) | Verdict |
|---|---------|-------|---------------|----------------|-------|-----------|---------|
| 1 | `base-content` text on copper-badge tinted bg (`copper 12% on surface-2`) | Dark | `#f4f1ea` | ~`#1d2435` (12% of #c17a3e on #1b2230) | 12.07:1 | ✅ PASS | **badge-text rule: use base-content, not secondary** |
| 2 | `base-content` text on copper-badge tinted bg (`copper 12% on surface-1 light`) | Light | `#141923` | ~`#faf0eb` (12% of #a85d2e on #fffdf8) | 14.86:1 | ✅ PASS | **badge-text rule confirmed** |
| 3 | `.ops-copper-eyebrow` (`--color-secondary`) on `--ops-surface-1` | Dark | `#c17a3e` | `#141923` | 5.13:1 | ✅ PASS | eyebrow text rule |
| 4 | `.ops-copper-eyebrow` (`--color-secondary`) on `--ops-surface-1` | Light | `#a85d2e` | `#fffdf8` | 4.84:1 | ✅ PASS | eyebrow text rule |
| 5 | `--color-secondary-content` (Night `#0c0f14`) on solid copper `#c17a3e` | Dark | `#0c0f14` | `#c17a3e` | 5.59:1 | ✅ PASS | `.ops-copper-node--fill` text |
| 6 | Copper text `#c17a3e` on `--ops-surface-2` `#1b2230` | Dark | `#c17a3e` | `#1b2230` | 4.64:1 | ✅ PASS | `.ops-copper-node` text |
| 7 | `--shadow-ops-glow` (box-shadow, decorative) | Dark | n/a (not text) | n/a | — | Exempt | decorative shadow |
| 8 | `--shadow-ops-panel-dark` (box-shadow, decorative) | Dark | n/a (not text) | n/a | — | Exempt | decorative shadow |
| 9 | `.ops-shell` wash alpha reduction | Both | n/a (decorative gradient) | n/a | — | Exempt | no text pairs |

**Re-confirmation notes:**
- All 6 text pairings re-confirmed PASS via WCAG 2.1 sRGB relative-luminance formula (D-12 compliant) against live `@plugin` hex values.
- Badge-text rule: `.ops-copper-badge` uses `color: var(--color-base-content)` — NOT `var(--color-secondary)`. This is correct; using secondary as badge label text would fail AA in light at 4.15:1 (spec-noted boundary).
- Ratios 3 + 4 (eyebrow) are the narrowest passing margins (5.13:1 dark / 4.84:1 light), both clearing the 4.5:1 AA threshold.
- Ratio 6 (copper on surface-2 dark, 4.64:1) is also a narrow margin, but passes.

**Verdict: ALL 9 PAIRINGS CONFIRMED PASS** — static F8 assertion holds against live hex values.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Status |
|----------|-------------|------------|--------|
| Copper 9-pairing AA table holds | COPPER-01 | F8 — copper classes use raw `var(--color-secondary)`/`var(--color-base-content)` refs the contrast harness does not track | ✅ All 9 re-confirmed PASS (Task 2) |
| Dark seated-depth reads correctly | GLOW-01 | Perceptual — shadow depth is not machine-measurable | ✅ APPROVED 2026-06-04 — seated depth confirmed (panels pressed into surface with border, not floating) |
| Quiet glow restraint | GLOW-01 | Perceptual — "quiet not loud" is a brand judgment | ✅ APPROVED 2026-06-04 — violet glow appropriately quiet and scoped to route mark, active nav pill, recommended intent-card only |
| Copper eyebrow renders correctly on all screens | COPPER-01 | Perceptual — correct color rendering requires human confirmation | ✅ APPROVED 2026-06-04 — copper eyebrow confirmed on all 6 screens at ~5% accent ratio |
| Light mode non-regression | GLOW-01, COPPER-01 | Perceptual final confirmation + 0/20 pixel-diff backing | ✅ APPROVED 2026-06-04 — light mode unchanged; 0/20 pixel-diff confirmed |

---

## Validation Sign-Off

- [x] All success criteria have an automated gate or a documented manual verification
- [x] Sampling continuity: light-AA quick check after every commit
- [x] Wave 0 baseline-freshness check completed before pixel-diff is trusted
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] Cluster 3 (primary-violet) recorded as out-of-scope-known-fail → deferred to Phase 132
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** APPROVED 2026-06-04 — all four perceptual criteria confirmed by human review: seated depth reads correctly (panels pressed into surface with border shadow, not floating), violet glow is appropriately quiet and scoped (route mark, active nav pill, recommended intent-card only — never on text, resting panels, or background floods), copper eyebrow renders correctly on all 6 screens at ~5% accent ratio, and light mode is pixel-identical (0/20 confirmed).
