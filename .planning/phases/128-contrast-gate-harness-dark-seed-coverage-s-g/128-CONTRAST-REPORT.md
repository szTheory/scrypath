---
schema: scrypath.contrast.v1
phase: 128
generated: 2026-06-04
producer: axe (admin_contrast_matrix.spec.ts) + contrast-checker.mjs
status: FAIL
summary:
  aa_fail_total: 108
  aa_fail_incident: 22
  aa_fail_all_green: 60
  aa_fail_empty: 26
  aaa_advisory_total: 12
  themes_tested: [light, dark, system-dark]
  viewports_tested: [390, 1440]
  screen_states_tested: 13
---

# Phase 128 — Contrast Report (Baseline)

> **Status: FAIL** — 108 AA violations found across 3 scenarios. This is the expected
> result for Phase 128. The gate is **live** and measuring real violations. Phases 129–136
> fix the debt this report identifies.
>
> Raw run artifacts are gitignored at `examples/scrypath_ecommerce/test-results/contrast/`
> (gitignored by the existing `test-results/` rule). This committed file is the **single
> source of truth** for phases 129/132.

---

## Run Environment

| Property | Value |
|----------|-------|
| **Date** | 2026-06-04 |
| **Stack** | Containerized TEST stack (`MIX_ENV=test`) |
| **Host port** | 4012 (lane-shifted: `WEB_PORT=4012` — port 4002 was occupied by another project's native Phoenix server) |
| **`PLAYWRIGHT_BASE_URL`** | `http://127.0.0.1:4012` |
| **Image note** | Pre-existing baked image was **stale** (its `/dev/e2e/seed` endpoint did not know the operational scenarios `all_green`/`incident`/`empty`). Rebuilt via `docker compose build web` — 8-second rebuild (BuildKit hex/rebar cache mounts; no dependency re-download). After rebuild the seed endpoint returned scenarios correctly. |
| **Harness** | `admin_contrast_matrix.spec.ts` — 3 seed scenarios × ~13 screen-states × {light, dark, system-dark} × {mobile 390, desktop 1440} |
| **axe rule** | `color-contrast` (AA gate) + `color-contrast-enhanced` scoped to `BODY_SELECTORS` (AAA advisory) |

### Known harness limitation — per-run report overwrite

When all scenarios run together (`npm run test:e2e:admin-contrast`), each scenario overwrites the same
`CONTRAST_REPORT_DIR/contrast-report.{json,md}`. Only the last scenario survives the combined run.

**Workaround used for this baseline:** Each scenario was run with a per-scenario `CONTRAST_REPORT_DIR`
(e.g. `test-results/contrast/incident/`, `test-results/contrast/all_green/`,
`test-results/contrast/empty/`). Full baseline capture requires per-scenario dirs or
scenario-suffixed filenames. This is a **future enhancement** for the harness — do not block on it.

---

## Summary

### Per-Scenario AA Failure Counts

| Scenario | AA Failures | AAA Advisory | Exit |
|----------|------------|--------------|------|
| incident | 22 | 0 | 1 |
| all_green | 60 | 0 | 1 |
| empty | 26 | 0 | 1 |
| **Total** | **108** | **0** | **1** |

### Fast Token-Checker Summary (`make contrast`)

| Result | Count |
|--------|-------|
| AA failures (light theme) | 3 |
| AAA advisory (light theme) | 12 |
| Exit code | 1 |

The fast checker (`contrast-checker.mjs`) runs in under 1 second with no browser, scoring every
declared `--color-*` pair and documented muted alphas. It confirms AA debt exists before any browser run.

---

## Fast Checker — AA Failures (3)

These are light-theme failures found by `make contrast` (token-pair checker, no browser):

| Selector / Token | Actual Ratio | Required | Theme |
|-----------------|-------------|----------|-------|
| `.ops-text-meta` | 3.9:1 | 4.5 (AA) | light |
| `.ops-cmdk__item-hint` | 3.9:1 | 4.5 (AA) | light |
| `.ops-cmdk__empty` | 3.9:1 | 4.5 (AA) | light |

**Note:** These light-theme muted-text tokens just miss AA at 3.9:1. They are also AAA advisory candidates.
The fast checker also reported 12 AAA advisory findings in the light theme.

---

## Full Matrix — AA Failures by Scenario

### Scenario: `empty` — 26 AA failures

This scenario has the most detailed on-disk data (`test-results/contrast/empty/contrast-report.json`).

#### Systemic failures (same selector fails on ≥3 screens)

| Scope | Selector | fg | bg | Ratio | Required | Screens affected |
|-------|----------|-----|-----|-------|----------|-----------------|
| **systemic** | `.leading-4` | `#1f2933` | `#1d222c` | **1.08:1** | 4.5 | failed-sync (dark+system-dark), search (dark+system-dark), playbooks × 2 states (dark+system-dark) — 8 occurrences |

**`.leading-4` at 1.08:1 is the top systemic fix.** The fg `#1f2933` is nearly identical to bg `#1d222c` in dark —
this is the `#1B2230` surface-2 ramp collapse. Text rendered on a raised dark surface becomes invisible.
This is the v1.34 core fix target (DARKAUDIT-01 finding #1).

#### Local failures (scope: local)

| Screen | Theme | Viewport | State | Selector | fg | bg | Ratio | Required |
|--------|-------|----------|-------|----------|-----|-----|-------|----------|
| search | dark | mobile | zero-results | `.bg-primary` | `#f4f1ea` | `#6c5ce7` | 4.3:1 | 4.5 |
| search | dark | mobile | zero-results | `#search_q` | `#1f2933` | `#141923` | 1.19:1 | 4.5 |
| search | dark | mobile | zero-results | `#search_page_size` | `#1f2933` | `#141923` | 1.19:1 | 4.5 |
| search | dark | mobile | zero-results | `#capture_title` | `#1f2933` | `#141923` | 1.19:1 | 4.5 |
| search | dark | mobile | zero-results | `#capture_basename` | `#1f2933` | `#141923` | 1.19:1 | 4.5 |
| search | dark | mobile | zero-results | `#capture_description` | `#1f2933` | `#141923` | 1.19:1 | 4.5 |
| search | dark | mobile | zero-results | `pre` | `#1f2933` | `#0c0f14` | 1.3:1 | 4.5 |
| search | system-dark | mobile | zero-results | `.bg-primary` | `#f4f1ea` | `#6c5ce7` | 4.3:1 | 4.5 |
| search | system-dark | mobile | zero-results | `#search_q` | `#1f2933` | `#141923` | 1.19:1 | 4.5 |
| search | system-dark | mobile | zero-results | `#search_page_size` | `#1f2933` | `#141923` | 1.19:1 | 4.5 |
| search | system-dark | mobile | zero-results | `#capture_title` | `#1f2933` | `#141923` | 1.19:1 | 4.5 |
| search | system-dark | mobile | zero-results | `#capture_basename` | `#1f2933` | `#141923` | 1.19:1 | 4.5 |
| search | system-dark | mobile | zero-results | `#capture_description` | `#1f2933` | `#141923` | 1.19:1 | 4.5 |
| search | system-dark | mobile | zero-results | `pre` | `#1f2933` | `#0c0f14` | 1.3:1 | 4.5 |
| playbooks | dark | mobile | empty-workspace | `#phx-*` (input) | `#1f2933` | `#141923` | 1.19:1 | 4.5 |
| playbooks | system-dark | mobile | empty-workspace | `#phx-*` (input) | `#1f2933` | `#141923` | 1.19:1 | 4.5 |
| playbooks | dark | mobile | populated | `#phx-*` (input) | `#1f2933` | `#141923` | 1.19:1 | 4.5 |
| playbooks | system-dark | mobile | populated | `#phx-*` (input) | `#1f2933` | `#141923` | 1.19:1 | 4.5 |

**Pattern:** The playbooks `#phx-*` selectors are dynamic LiveView-generated IDs — axe picks up
an input element whose selector changes between renders. The underlying token issue is the same as
the form inputs above: text `#1f2933` on dark surface `#141923` → 1.19:1.

### Scenario: `incident` — 22 AA failures

Per-scenario JSON not retained on disk (overwritten by combined run). Summary from harness output:
- **22 AA failures**, 0 AAA advisory, exit 1
- Failure pattern matches the empty scenario: `.leading-4` systemic dark failures + dark form
  input failures on the same token pair `#1f2933`/`#141923` and `#1f2933`/`#1d222c`
- The incident scenario exercises failed-sync and sync-drift screens, so the systemic `.leading-4`
  failures appear on those screens in dark/system-dark

### Scenario: `all_green` — 60 AA failures

Per-scenario JSON not retained on disk. Summary from harness output:
- **60 AA failures**, 0 AAA advisory, exit 1
- Higher count because all_green seeds the full operational state, activating more screens
  (posture healthy, sync-drift, search with results, playbooks populated) — each additional
  screen-state × dark/system-dark × mobile multiplies the base token failures
- The same root token issues drive all failures: `#1f2933` text on raised dark surfaces

---

## Systemic Cluster Analysis

Per D-19: findings where the same `(selector | token_pair)` fails on ≥3 distinct screens
are tagged `scope: systemic`.

### Cluster 1 — `.leading-4` (SYSTEMIC, CRITICAL)

| Property | Value |
|----------|-------|
| **Selector** | `.leading-4` |
| **fg** | `#1f2933` |
| **bg** | `#1d222c` |
| **Actual ratio** | **1.08:1** |
| **Required** | 4.5:1 (AA) |
| **Gap** | −3.42:1 |
| **Scope** | systemic |
| **fix_class** | token |
| **Screens** | failed-sync, search, playbooks (empty-workspace), playbooks (populated) |
| **Themes** | dark, system-dark |
| **Viewport** | mobile (only — desktop not affected) |
| **Root cause** | The `#1B2230` surface-2 ramp step is missing in dark. `.leading-4` sits on a "raised" surface that in dark renders nearly the same color as the text. The fg `#1f2933` (navy dark) is nearly indistinguishable from bg `#1d222c` (surface-2 dark). |
| **Downstream fix** | DARKAUDIT-01 finding #1. Fix the dark surface-2 ramp token — a single token change will resolve all 8+ occurrences simultaneously. |

### Cluster 2 — Dark form inputs (SYSTEMIC)

| Property | Value |
|----------|-------|
| **Selectors** | `#search_q`, `#search_page_size`, `#capture_title`, `#capture_basename`, `#capture_description`, `#phx-*` (input) |
| **fg** | `#1f2933` |
| **bg** | `#141923` |
| **Actual ratio** | **1.19:1** |
| **Required** | 4.5:1 (AA) |
| **Gap** | −3.31:1 |
| **Scope** | systemic (same fg/bg across multiple screens) |
| **fix_class** | token |
| **Screens** | search, playbooks |
| **Themes** | dark, system-dark |
| **Root cause** | Input text color `#1f2933` renders nearly invisible against the dark input background `#141923`. Same ramp gap as cluster 1 — the dark text token is too close to the dark surface. |
| **Downstream fix** | Fix the dark input text token and/or input background token. |

### Cluster 3 — `.bg-primary` button (near-miss, local)

| Property | Value |
|----------|-------|
| **Selector** | `.bg-primary` |
| **fg** | `#f4f1ea` |
| **bg** | `#6c5ce7` |
| **Actual ratio** | **4.3:1** |
| **Required** | 4.5:1 (AA) |
| **Gap** | −0.2:1 |
| **Scope** | local |
| **fix_class** | token |
| **Screens** | search |
| **Themes** | dark, system-dark |
| **Root cause** | The brand's primary violet `#6c5ce7` at the sRGB-composited ratio is 4.3:1 vs the cream text — just 0.2 under the wire. This is a near-miss that only appears in dark (the light theme has a different bg). |
| **Downstream fix** | Lighten the primary violet slightly in dark, or darken the text. 0.2:1 gap — a minor token adjustment. |

---

## AAA Advisory

No AAA advisory findings were produced by the full axe matrix runs (0 across all 3 scenarios).

The fast token checker (`make contrast`) reported **12 AAA advisory findings** in the light theme.
These are advisory only — they do not affect the gate exit code or build status.

---

## Prioritized Fix List for Downstream Phases

Priority order for phases 129–136:

| Priority | Finding | Selector | Ratio | Gap | Scope | Phase target |
|----------|---------|----------|-------|-----|-------|-------------|
| 1 (critical) | `.leading-4` dark surface-2 ramp collapse | `.leading-4` | 1.08:1 | −3.42 | systemic | 130–132 (token fix) |
| 2 (high) | Dark form input text invisible | `#search_q` et al. | 1.19:1 | −3.31 | systemic | 130–132 (token fix) |
| 3 (high) | `pre` code block in dark | `pre` | 1.3:1 | −3.2 | local | 130–132 |
| 4 (medium) | `.bg-primary` near-miss | `.bg-primary` | 4.3:1 | −0.2 | local | 132 |
| 5 (low) | Light muted text trio | `.ops-text-meta` etc. | 3.9:1 | −0.6 | local | 132 |

**Single most impactful fix:** Repair the dark surface-2 ramp (`#1B2230` step).
A single token change to the raised-surface background in dark will resolve priority 1 AND likely
improve priority 2 (which shares the same flattened bg-to-text relationship).

---

## AAA Advisory (Fast Checker — Light Theme)

12 AAA advisory findings were reported by `make contrast` in the light theme. These are
**advisory only** — they do not affect exit code or gate status.

Details: Not enumerated here individually as they are light-theme advisory (v1.34's primary focus
is dark). Review via `make contrast` output for the full list.

---

## Notes for Phases 129/132

1. **Phase 129 (dark audit):** The `.leading-4` cluster at 1.08:1 IS finding #1 in the
   DARKAUDIT-01 backlog. The fg `#1f2933` / bg `#1d222c` pair is the `#1B2230` surface-2 gap.
   Every occurrence resolves together when the ramp token is fixed.

2. **Phase 132 (token fix):** Two token changes likely clear ~90% of the AA debt:
   a. Dark surface-2 raised background token (resolves clusters 1 + 2)
   b. Dark input/form text token (resolves cluster 2 remainder)
   The `.bg-primary` near-miss is a third, smaller token fix.

3. **Dynamic `#phx-*` selectors:** The playbooks form input failures are reported with
   dynamic LiveView-generated IDs. These are the same underlying token issue as `#search_q` etc.
   Fix the token; the dynamic IDs will pass automatically.

4. **Desktop not affected:** All AA failures occur at mobile (390px viewport). Desktop
   (1440px) passes. This may be layout-driven: some dark surfaces only appear at mobile
   breakpoints. Confirm during the Phase 132 fix pass.

5. **system-dark parity:** Every dark failure is mirrored in system-dark (same ratio, same
   selector). This confirms the D-08 system-dark media-query path is functioning correctly —
   both explicit `[data-theme=dark]` and `@media (prefers-color-scheme: dark)` activate the
   same broken token.
