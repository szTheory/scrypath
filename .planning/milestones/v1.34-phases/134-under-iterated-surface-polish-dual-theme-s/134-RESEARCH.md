# Phase 134: Under-iterated surface polish (dual-theme) - Research

**Researched:** 2026-06-25
**Domain:** Phoenix/LiveView + Tailwind v4 + daisyUI dual-theme CSS application; Playwright computed-style verification
**Confidence:** HIGH (all findings verified against live code this session)

## Summary

Phase 134 is a deliberately constrained **application** pass: it closes `129-DARK-AUDIT-BACKLOG.md` rows DK-11→DK-18 by *applying* the design system shipped in Phases 119–133 to three under-iterated `scrypath_ops` surfaces (Search rows, Sync/Drift depth, Playbooks cards), plus a verify-and-tune sweep. **No new tokens, components, JS hooks, or keyframes.** The design decisions are LOCKED in `134-CONTEXT.md` (D-01→D-18) and `134-UI-SPEC.md` (approved) — this research does NOT relitigate them.

This research has two jobs: (1) define the **Validation Architecture** — the deterministic, CI-enforced gate (`admin_surface_depth.spec.ts` computed-style assertions + light-pixel-diff + static tripwire) that converts subjective dark-depth reads into CI-failing numbers, matching the owner's 0-human-UAT preference; and (2) **verify implementation-readiness** — confirm the live-code anchors the executor will edit, since CONTEXT warned several Phase-129 anchors are stale.

**Verification result:** Most CONTEXT anchors are now **accurate** (the file is currently 1542 lines; the ~979/1424/1434/1495/377/1526 anchors all resolve correctly). However, three material planning risks surfaced (see Planning Risks): **(R1)** the DK-13 posture table has **no hand-authored row-border selector** — it is a daisyUI `table table-sm table-zebra` component, so the `app.css:719` *and* `:773` anchors are both wrong and the executor must scope a new `.ops-`-prefixed override or `table_class`; **(R2)** the D-11 exact-match assertion `backgroundColor === rgb(27,34,48)` will NOT hold for several named surfaces because their fills are `color-mix(... NN%, transparent)` not the flat token; **(R3)** `mix verify.opsui` is only a `mix test` wrapper and the existing `design_tokens_contract_test.exs` is an orphan-checker, not a value-assertion contract — the static tripwire needs a *new* assertion.

**Primary recommendation:** Plan tasks against the verified anchors below; treat R1/R2/R3 as the three things to resolve in planning, not as re-decisions. Build the binding gate (`admin_surface_depth.spec.ts`) by cloning the `admin_path_motion.spec.ts` glow idiom and importing `THEME_MODES`/`assertSystemDarkInvariants`/seed helpers from `admin_contrast_matrix.spec.ts`.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Dark surface-2 elevation fills (rows/cards/panels) | CSS (`scrypath_ops/assets/css/app.css`) | — | Pure styling; both dark paths hand-authored |
| Hover-border boost (DK-17) | CSS (paired `:hover` selector) | — | Leaf style change, dark-only override |
| Copper badge application (D-01) | Phoenix component template (`ops_ui.ex` / Control Room LiveView) | CSS (`.ops-copper-badge` already defined) | Class is shipped; phase wires it onto markup |
| DK-13 table row-border tune | CSS (daisyUI `.table` scoped override) | Phoenix (`ops_table` `table_class`) | No existing custom rule — must scope one |
| Binding verification gate | Playwright e2e (`examples/scrypath_ecommerce/e2e/`) | npm script + CI | Computed-style assertions against booted ops server |
| Light parity / static tripwire | ExUnit contract test (`scrypath_ops/test/`) + `light-pixel-diff.mjs` | `mix verify.opsui` wrapper | Cheap pre-flight + threshold-0 pixel gate |

## Standard Stack

No new dependencies. This phase uses only the already-installed stack. **No `## Package Legitimacy Audit` section is required — the phase installs zero external packages.**

### Core (already present, verified)
| Tool | Where | Purpose | Verified |
|------|-------|---------|----------|
| Tailwind v4 + daisyUI | `scrypath_ops/assets/css/app.css` | Theme tokens, `.ops-*` utilities, daisyUI `table`/`badge` | [VERIFIED: live app.css, 1542 lines] |
| Phoenix function components | `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` | `.ops-*` components incl. `ops_table`, `ops_copper`*, `ops_intent_card` | [VERIFIED: grep ops_ui.ex] |
| Playwright `@playwright/test ^1.54.2` | `examples/scrypath_ecommerce/` | e2e computed-style harness | [VERIFIED: package.json] |
| `@axe-core/playwright ^4.11.3` | same | AA contrast gate (`admin_contrast_matrix.spec.ts`) | [VERIFIED: package.json] |

**Installation:** none.

## Implementation-Readiness Verification (live-code anchors)

> CONTEXT.md flagged Phase-129 anchors as stale. Every anchor below was re-grepped against the current `scrypath_ops/assets/css/app.css` (1542 lines) this session.

### Confirmed ACCURATE anchors

| Item | CONTEXT anchor | Verified location | Current value | Tag |
|------|---------------|-------------------|---------------|-----|
| Shared hover selector `.ops-result-row:hover, .ops-object-item:hover` | ~979-983 | **lines 979-983** | `border-color: primary 32%`; `box-shadow: var(--shadow-ops-mid)` | [VERIFIED: live app.css] |
| `.ops-result-row` base (resting) | ~961-974 | **lines 961-974** | border `base-content 10%`; bg `base-100 94%` | [VERIFIED] |
| `.ops-object-item` base | ~711-729 | **lines 711-724** | border `base-content 10%`; bg `base-100 92%` | [VERIFIED] |
| Dark surface-2 fill `.ops-data-card` | ~1424-1431 | **lines 1423-1431** | both dark paths → `background: var(--ops-surface-2)` | [VERIFIED] |
| Dark surface-2 fill `.ops-result-row` | ~1434-1441 | **lines 1433-1441** | both dark paths → `background: var(--ops-surface-2)` | [VERIFIED] |
| `.ops-object-item-active` glow | ~1495-1502 | **lines 1495-1502** | dark box-shadow includes `var(--shadow-ops-glow)` (ring + glow) | [VERIFIED] |
| `.ops-verdict-neutral` | ~377 | **lines 375-378** | `background: color-mix(... var(--ops-surface-2) 64% ...)` — already routes surface-2 (confirms D-05 verify-only) | [VERIFIED] |
| Dark raised-shadow recipe | ~1526/1536 | **lines 1526 & 1536** | `--shadow-ops-raised: 0 2px 10px rgba(0,0,0,0.50)` — **cool black, no warm cream halo** (confirms D-06 verify-only) | [VERIFIED] |
| `--shadow-ops-glow` (dark) | — | **lines 1531 & 1541** | `0 0 8px 2px rgba(108,92,231,0.30)` — confirms the `108,92,231` glow-RGB assertion (D-11) | [VERIFIED] |
| `--ops-surface-2` token | — | **dark line 59** `#1b2230`; **light line 99** `#faf7f2` | confirms D-11 expected `rgb(27,34,48)` | [VERIFIED] |
| `.ops-copper-badge` exists, theme-agnostic, AA pre-cleared | — | **lines 499-503** | `border: secondary 44%`; `bg: secondary 12%`; `color: var(--color-base-content)` (NOT `--color-secondary`) — confirms D-03 | [VERIFIED] |
| Two dark authoring paths exist | — | `[data-theme="dark"]` + `@media (prefers-color-scheme: dark) html:not([data-theme="light"])` used throughout (e.g. 1424/1428, 1434/1438, 1495/1499) | [VERIFIED] |
| `.ops-preflight__card` / `--locked` | ~840-857 | **840-851 / 853-856** | base `surface-1 94%`; locked `surface-2 60%` (step up, confirms intent) | [VERIFIED] |
| Copper AA pre-clearance (DESIGN-TOKENS) | — | DESIGN-TOKENS.md lines 175-180: base-content on copper-badge dark **12.07:1** / light **14.86:1** PASS | [CITED: scrypath_ops/assets/css/DESIGN-TOKENS.md] |

### Harness files — all CONFIRMED present

| File / symbol | Location | Tag |
|---------------|----------|-----|
| `admin_path_motion.spec.ts` (glow idiom `getComputedStyle(el).boxShadow`, `GLOW_RGB = "108, 92, 231"`, patch-safety probe) | `examples/scrypath_ecommerce/e2e/admin_path_motion.spec.ts` (glow probes ~196-216) | [VERIFIED] |
| `admin_contrast_matrix.spec.ts` | same dir | [VERIFIED] |
| `THEME_MODES` (`explicit-light`, `explicit-dark`, `system-dark`) | `admin_contrast_matrix.spec.ts:50-54` | [VERIFIED] |
| `assertSystemDarkInvariants` (no `data-theme`, media matches, `data-theme-effective="dark"`) | `admin_contrast_matrix.spec.ts:123-135` | [VERIFIED] |
| `VIEWPORTS` mobile 390 / desktop 1440 | `admin_contrast_matrix.spec.ts:64-67` | [VERIFIED] |
| Seed/index map matches D-12 exactly: `06` search results, `08` search zero-results, `03` sync-drift drift, `09` playbooks empty-workspace, `12` playbooks populated | `admin_contrast_matrix.spec.ts:498-565` | [VERIFIED] |
| `light-pixel-diff.mjs` | `examples/scrypath_ecommerce/e2e/light-pixel-diff.mjs` | [VERIFIED] |
| `helpers/e2e` (`seedScenario`, `runSearch`, `waitForLiveConnected`, `SeedScenario` type) | `examples/scrypath_ecommerce/e2e/helpers/e2e.ts` | [VERIFIED] |
| `mix verify.opsui` task | `lib/mix/tasks/verify.opsui.ex` | [VERIFIED] |
| Existing contract tests | `scrypath_ops/test/scrypath_ops_web/{design_tokens_contract_test,motion_contract_test}.exs` | [VERIFIED] |
| npm scripts pattern (`test:e2e:path-motion`, `test:e2e:admin-contrast`) | `examples/scrypath_ecommerce/package.json:9,12` | [VERIFIED] |

## Planning Risks (flagged — NOT re-decisions)

> Per instructions: where CONTEXT/UI-SPEC contradicts live code, flag as a planning risk rather than re-deciding.

### R1 — DK-13 posture table has NO hand-authored row-border selector [HIGH severity]
CONTEXT D-08 says "grep the current posture/per-schema table row-border selector before editing" and assumes such a selector exists. **It does not.** The posture per-schema table renders via `<.ops_table zebra>` (`posture_live.ex:234`), which emits a **daisyUI `<table class="table table-sm table-zebra">`** (`ops_ui.ex:138`). Row separators come from **daisyUI's internal `.table` border** (driven by `--border: 1.5px` line 54 + daisyUI's base-content/base-300 row rule), NOT from any `.ops-*` rule in `app.css`. The stale anchors `app.css:719` (doesn't exist as a table rule) and `app.css:773` (which is actually `.ops-handoff`, a page footer) both mislead.
- **Implication for planning:** if D-08's 1.20:1 trigger fires, the executor cannot "boost the alpha on the existing selector." They must either (a) add an `.ops-`-scoped dark-only override targeting daisyUI table rows within the posture table (e.g. a `table_class`/wrapper class so the override stays leaf-scoped and doesn't leak to other `table`s), or (b) pass a `table_class` to `ops_table`. **This is still a leaf edit (D-08/D-09 rationale holds)** but needs an explicit "where does the new rule live" planning step. The DK-13 measured contrast is currently between daisyUI's default row border and `#1b2230` — measure that, not a non-existent `.ops-table` rule.
- **AA note:** brand §6.5 / DESIGN-TOKENS line 78 target for dark borders is `#2A3446` (base-300, blue-gray slate); D-08's `base-content 18%` is the alpha route to approximate it. [VERIFIED: live grep + DESIGN-TOKENS.md]

### R2 — D-11 exact `rgb(27,34,48)` match will FAIL for alpha-mixed surfaces [MEDIUM severity]
D-11 asserts `.ops-result-row` / `.ops-data-card` / `.ops-muted-panel` `backgroundColor === rgb(27,34,48)`. This holds for `.ops-result-row` and `.ops-data-card` in dark (they set `background: var(--ops-surface-2)` flat — lines 1424/1434). But:
- `.ops-muted-panel` (line 276) and `.ops-verdict-neutral` (line 377) use `color-mix(in oklch, var(--ops-surface-2) 64%, transparent)` — these composite to a DIFFERENT computed rgb against whatever is behind them, and `getComputedStyle().backgroundColor` will return the **mixed** value (or an `oklch`/`color-mix` string in some engines), not `rgb(27,34,48)`.
- `.ops-preflight__card--locked` uses `surface-2 60%` (line 854); `.ops-preflight__card` uses `surface-1 94%` (line 846) — D-11's "locked steps above card" is a *relative* comparison, which is robust, but the absolute equality assertions are not.
- **Implication for planning:** the spec should assert flat-token surfaces (`.ops-result-row`, `.ops-data-card`) by exact rgb, but assert the **luminance-delta / relative-step** comparison for alpha-mixed surfaces (`.ops-muted-panel`, preflight cards) rather than exact equality. The luminance-delta proof (D-11's "exceeds `--ops-bg` floor by ≥ 0.015") is the durable, engine-agnostic check and should be the *primary* assertion for every surface; exact-rgb is a secondary check only where the fill is a flat token. This is consistent with CONTEXT's "Claude's Discretion" note that the delta floor is tunable.

### R3 — `mix verify.opsui` is a `mix test` wrapper; the existing token contract is an orphan-checker, not a value contract [MEDIUM severity]
- `lib/mix/tasks/verify.opsui.ex` only runs `cd scrypath_ops && mix deps.get && mix test`. The "static `.ops-*` CSS contract + MotionContractTest + light pixel-diff" are **ExUnit tests inside `scrypath_ops/test/`**, not logic in the task. So D-13's "static token tripwire added to `mix verify.opsui`'s `.ops-*` CSS contract" means: **add assertions to an ExUnit test under `scrypath_ops/test/scrypath_ops_web/`** (the test then runs under `mix verify.opsui` automatically). [VERIFIED: read verify.opsui.ex]
- `design_tokens_contract_test.exs` is an **orphan checker** — it asserts every `*-ops-*` utility / `var(--…)` reference resolves to a *defined* token; it does NOT assert token *values*. D-13's tripwire (`--ops-surface-2: #1b2230`, dark hover `primary 55%`, raised-surface recipes reference the token) requires **new value-regex assertions** (read `app.css`, regex the literal). Plan this as a small new test (or a new `describe` block in the existing file), not "extend the orphan checker." [VERIFIED: read design_tokens_contract_test.exs]

### R4 — "populated" playbooks seed (index 12) may render empty [LOW severity]
The contrast spec's index-12 `playbooks/populated` capture (`admin_contrast_matrix.spec.ts:563`) calls `gotoPlaybooks(page)` with **no playbook-creation step** in `prepare`. D-12 requires a genuinely *populated* Playbooks state to prove DK-18 (`.ops-data-card` raised, `.ops-object-item-active` glow). The new `admin_surface_depth.spec.ts` must ensure a playbook actually exists (capture one via the Search→Playbooks loop, or seed it) before asserting populated-state depth — otherwise the populated assertions silently test an empty screen. Confirm the seed path when authoring the spec.

## Validation Architecture

> nyquist_validation is enabled (`.planning/config.json` → `workflow.nyquist_validation: true`). This section is the PRIMARY deliverable and triggers VALIDATION.md scaffolding downstream.

### Test Framework
| Property | Value |
|----------|-------|
| Framework (binding gate) | Playwright `@playwright/test ^1.54.2` + `@axe-core/playwright ^4.11.3` |
| Framework (static contract) | ExUnit (`scrypath_ops/test/`) run via `mix verify.opsui` → `mix test` |
| New spec file | `examples/scrypath_ecommerce/e2e/admin_surface_depth.spec.ts` (clone `admin_path_motion.spec.ts` idiom) |
| Config file | `examples/scrypath_ecommerce/playwright.config.*` (existing) |
| Quick run command | `npm run test:e2e:admin-depth` (NEW script → `playwright test e2e/admin_surface_depth.spec.ts`) |
| Full suite command | `npm run test:e2e` + `node e2e/light-pixel-diff.mjs` + `mix verify.opsui` + `make contrast` + `npm run test:e2e:admin-contrast` |

### Binding gate: `admin_surface_depth.spec.ts` (computed-style, D-10)
Clone the structure of `admin_path_motion.spec.ts`:
- Reuse `getComputedStyle(el).backgroundColor / .borderColor / .boxShadow` probe helpers (the path-motion `glowBoxShadow` shape).
- Import `THEME_MODES`, `assertSystemDarkInvariants`, `VIEWPORTS`, seed `prepare`/`describeScenario` helpers, and the seed/index map from `admin_contrast_matrix.spec.ts` (do NOT re-author them).
- Run the grid `{explicit-dark, system-dark} × {mobile 390, desktop 1440}`. (Light is covered by the pixel-diff gate; the depth spec asserts dark behavior + the light *negative* assertions for glow=`none`.)
- Each `system-dark` run calls `assertSystemDarkInvariants(page)` first (proves media-query path, not explicit `data-theme`).

### Phase Requirements → Test Map
| Req / Criterion | Behavior | Check type | Automated assertion (selector → prop → expected) | Risk note |
|-----------------|----------|-----------|--------------------------------------------------|-----------|
| Criterion 1 (DK-17, Search rows separate in dark) | Rows lift off floor | computed-style | `.ops-result-row` / `.ops-data-card` `backgroundColor === rgb(27,34,48)` **AND** sRGB rel-luminance exceeds `--ops-bg` `rgb(12,15,20)` by ≥ delta floor (start 0.015) | exact-rgb OK (flat token) |
| Criterion 1 (hover, D-12/D-15) | Hover perceptible on BOTH surfaces | computed-style | `.ops-result-row:hover` **and** `.ops-object-item:hover` `borderColor` resolves to `primary 55%` in dark **and differs from resting** | proves D-12 on both surfaces |
| Criterion 2 (DK-16, Sync/Drift depth) | Sections + preflight step up | computed-style (relative) | `.ops-muted-panel` luminance > `--ops-bg` floor by ≥ delta; `.ops-preflight__card--locked` `backgroundColor` luminance **>** `.ops-preflight__card` | **R2**: use luminance-delta/relative, NOT exact rgb (alpha-mixed) |
| Criterion 2 (DK-18, Playbooks cards) | Cards raised; active item glows | computed-style | `.ops-data-card` rgb/luminance proof; `.ops-object-item-active` `boxShadow` contains `108, 92, 231` in dark, `none` in light | **R4**: ensure populated seed creates a playbook |
| Criterion 3 (D-01, earned copper) | Copper applied at one site | computed-style + **negative** | `.ops-copper-badge` (Control Room recommended card) `color`/tint resolves to `--color-secondary` copper; **negative:** no `tone_class`/`badge_class` status chip computes to copper | proves D-01 applied + D-02 "never a status tone" |
| Criterion 3 ("earned copper *feel*") | Aesthetic read | **human-spot-review** | 40-shot matrix, dark target shots — NOT thresholdable | stays human per D-13 |
| DK-13 (table separators) | Border vs surface contrast | measured number | Compute contrast ratio (table row border ↔ `#1b2230`) at dark 390; **if < 1.20:1 → boost; else record ratio** | **R1**: no existing selector — measure daisyUI default row border |
| Light parity (D-13) | Light pixel-identical | pixel-diff | `node e2e/light-pixel-diff.mjs` threshold **0** | do NOT duplicate light depth checks |
| Static pre-flight (D-13) | Token values pinned | ExUnit value-regex | `--ops-surface-2: #1b2230`; raised recipes reference the token; dark hover = `primary 55%` | **R3**: NEW value-assertion test, not the orphan checker |
| AA gate (UI-SPEC) | 0 AA failures all 3 themes | axe | `make contrast` + `npm run test:e2e:admin-contrast` | inherited; must stay green |

### Sampling Rate
- **Per task commit:** `npm run test:e2e:admin-depth` (the surfaces touched by that task) + `mix verify.opsui` if CSS/token changed.
- **Per wave merge:** full e2e (`npm run test:e2e`) + `node e2e/light-pixel-diff.mjs` + `make contrast` + `npm run test:e2e:admin-contrast`.
- **Phase gate:** all of the above green + 40-shot human spot-review for "earned copper feel"/halo, against a **booted, seeded ops server with ops assets built first** (D-14 — the ecommerce dev server does NOT live-reload the `scrypath_ops` path-dep; restart `mix phx.server` / rebuild assets or LiveView styles never apply).

### Wave 0 Gaps
- [ ] `examples/scrypath_ecommerce/e2e/admin_surface_depth.spec.ts` — new binding gate (covers SCREEN-DARK-01 criteria 1+2+3 deterministic parts).
- [ ] npm script `test:e2e:admin-depth` in `examples/scrypath_ecommerce/package.json`.
- [ ] New ExUnit value-assertion (token tripwire) under `scrypath_ops/test/scrypath_ops_web/` (R3) — runs under `mix verify.opsui`.
- [ ] Populated-playbooks seed step in the depth spec (R4).
- [ ] (Conditional) DK-13 dark-only table-row-border override location decided (R1) — only if the 1.20:1 trigger fires.
- Framework install: none — Playwright + axe already in `package.json`.

## Architecture Patterns

### Both-themes invariant (hard)
Every dark change is authored in BOTH paths; light untouched:
```css
/* Source: live app.css, e.g. lines 1434-1443 (.ops-result-row dark fill) */
[data-theme="dark"] .ops-result-row { background: var(--ops-surface-2); }
@media (prefers-color-scheme: dark) {
  html:not([data-theme="light"]) .ops-result-row { background: var(--ops-surface-2); }
}
```

### Pattern: dark-only hover-border boost on the PAIRED selector (D-15/D-16)
Keep the shared base rule (lines 979-983) at `primary 32%` (= light value, dark fallback). Add a dark-only override on the *same paired selector* (both dark paths) lifting to `primary 55%`. Do NOT split the shared rule (that would re-introduce DK-17 faintness on Playbooks) and do NOT add a `--hover-border` var (no new tokens).
```css
/* Target shape — author in BOTH dark paths, mirrors lines 1434/1438 idiom */
[data-theme="dark"] .ops-result-row:hover,
[data-theme="dark"] .ops-object-item:hover { border-color: color-mix(in oklch, var(--color-primary) 55%, transparent); }
@media (prefers-color-scheme: dark) {
  html:not([data-theme="light"]) .ops-result-row:hover,
  html:not([data-theme="light"]) .ops-object-item:hover { border-color: color-mix(in oklch, var(--color-primary) 55%, transparent); }
}
```
Hover (border 55% + `--shadow-ops-mid`, NO glow) and active (`.ops-object-item-active`: border 55% + inset ring + `--shadow-ops-glow`) stay on different axes → rest < hover < active unambiguous (D-17). [VERIFIED: lines 979-983, 726-728, 1495-1502]

### Pattern: copper badge composition (D-01)
Compose `class="ops-badge ops-copper-badge"` onto a federation/key-callout badge inside the Control Room recommended intent-card head. The class is theme-agnostic (consumes `--color-secondary`, AA pre-cleared) — no dual-path CSS needed for the badge itself.
```css
/* Source: live app.css lines 499-503 — already defined, just wire onto markup */
.ops-copper-badge {
  border-color: color-mix(in oklch, var(--color-secondary) 44%, transparent);
  background:   color-mix(in oklch, var(--color-secondary) 12%, transparent);
  color: var(--color-base-content);  /* AA dark 12.07:1 / light 14.86:1 */
}
```

### Anti-Patterns to Avoid
- **Splitting the shared `:hover` selector** to make Search-only — re-introduces DK-17 on Playbooks (D-15).
- **Adding any new token / var / component / keyframe** — explicitly out of scope; the orphan-checker won't catch a *missing value*, but the phase contract forbids it.
- **Copper as `--color-secondary` label text** — fails light AA at 4.15:1; badge text must be `--color-base-content` (D-03).
- **Copper anywhere near `tone_class/1` status chips** (D-02) — risks reading as a status tone.
- **Editing systemic tokens for DK-11/14/15** — blast-radius onto un-screenshotted surfaces; defer to Phase 135 (D-05/06/07/09).
- **Pixel-diff as the dark depth gate** — a small coplanar delta passes silently under threshold; use computed luminance-delta (D-10 rationale).
- **Asserting exact `rgb(27,34,48)` on alpha-mixed surfaces** (R2).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Theme grid + system-dark invariants | New theme-toggle harness | Import `THEME_MODES` / `assertSystemDarkInvariants` from `admin_contrast_matrix.spec.ts` | Already proven; D-10 mandates reuse |
| Glow/box-shadow probe | New `getComputedStyle` helper | Clone `admin_path_motion.spec.ts` glow idiom (`GLOW_RGB = "108, 92, 231"`) | Identical computed-style read |
| Seeding scenarios | New seed code | `seedScenario` + `describeScenario` + index map in helpers/contrast spec | Maps 1:1 to D-12 |
| Light parity | New light depth assertions | `light-pixel-diff.mjs` threshold 0 | D-13 — don't duplicate |
| AA verification | New contrast math | `make contrast` + `test:e2e:admin-contrast` (axe) | Inherited Phase 132 gate |

## Runtime State Inventory

This is a styling/verification phase (CSS + template class wiring + new e2e test), not a rename/migration. The one runtime-state gotcha is a **build/asset** concern, not stored data:

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — no datastore keys touched. | none |
| Live service config | None. | none |
| OS-registered state | None. | none |
| Secrets/env vars | None. | none |
| Build artifacts | **`scrypath_ops` path-dep does NOT live-reload in the ecommerce dev server** (D-14, Phase-133 lesson). Stale baked image at :4002 serves old CSS. | CI/local MUST build ops assets + restart `mix phx.server` (or run the dev compose with `--no-deps` against source) before the depth spec / 40-shot capture — else LiveView styles never apply and the gate tests stale CSS. |

## Common Pitfalls

### Pitfall 1: Testing against the stale baked ops image
**What goes wrong:** depth spec / screenshots pass-or-fail against old CSS. **Why:** ecommerce dev server doesn't live-reload the `scrypath_ops` path-dep. **Avoid:** build ops assets + restart `mix phx.server` first (D-14); spec runs against a booted, seeded server. **Warning sign:** computed `backgroundColor` doesn't match the token you just changed.

### Pitfall 2: DK-13 "edit the table row-border selector" — there isn't one
**What goes wrong:** executor greps for a `.ops-table` row rule, finds none, edits the wrong thing (`.ops-handoff` at the old `:773` anchor). **Why:** posture table is daisyUI `table table-sm table-zebra`. **Avoid:** scope a new dark-only override to daisyUI table rows *within the posture table* (R1). **Warning sign:** border change leaks to unrelated tables.

### Pitfall 3: exact-rgb assertions on `color-mix` surfaces
**What goes wrong:** `.ops-muted-panel` / preflight cards never equal `rgb(27,34,48)`. **Why:** alpha-mixed fills composite differently (R2). **Avoid:** luminance-delta / relative-step assertions for mixed surfaces; exact-rgb only for flat-token fills. **Warning sign:** spec flakes or returns an `oklch(...)`/`color-mix(...)` string.

### Pitfall 4: populated Playbooks renders empty
**What goes wrong:** DK-18 populated assertions test an empty screen (R4). **Avoid:** create/seed a playbook in `prepare` before asserting. **Warning sign:** `.ops-object-item-active` not found.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Subjective "looks faint in dark" UAT read | Computed luminance-delta + measured contrast trigger (objective number) | Phase 133 precedent; this phase | 0-human-UAT; CI-failing assertion |
| Pixel-diff for dark regressions | Computed-style for dark depth; pixel-diff light-only threshold 0 | D-10 | Catches coplanar bug a threshold swallows |

**Deprecated/outdated:**
- Phase-129 anchors `app.css:719` (DK-13 table), `:845-860` (DK-17 rows) — stale; superseded by the verified table above.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | daisyUI table row borders derive from `--border` + daisyUI's base-300/base-content row rule (no custom override) | R1 | If a hidden override exists elsewhere, DK-13 edit location differs — executor must re-grep before editing |
| A2 | `getComputedStyle().backgroundColor` returns the composited rgb (not a literal `color-mix` string) on the test browser | R2 | If engine returns `oklch`/`color-mix` string, exact-rgb assertions need parsing regardless of flat vs mixed |
| A3 | Index-12 populated-playbooks seed currently renders without a created playbook | R4 | If a fixture already seeds one, R4 is moot — confirm when authoring spec |

## Open Questions (RESOLVED)

1. **DK-13 override scope (R1)** — Where does the dark-only table-row-border rule live so it stays leaf-scoped to the posture table? Recommendation: pass a `table_class` (e.g. `ops-posture-table`) to `<.ops_table>` and scope the dark override to it — avoids leaking to other daisyUI tables; stays a leaf edit (D-09 holds).
   **RESOLVED:** Plan 02 Task 3 adopts the `table_class` leaf-scope route — the dark-only row-border override is scoped to a `.ops-posture-table` wrapper class passed to `<.ops_table>`, so it never leaks to other daisyUI tables (R1 recommendation accepted; D-09 leaf-edit posture holds).
2. **Luminance-delta floor / 1.20:1 trigger (Claude's Discretion)** — start at 0.015 / 1.20:1; tune to smallest reliable non-flaking value; must stay an objective number.
   **RESOLVED:** Explicitly Claude's Discretion per 134-CONTEXT.md (`### Claude's Discretion`). Executor starts at 0.015 / 1.20:1 and tunes to the smallest reliable non-flaking objective number — no further planning decision required.
3. **Copper badge content (Claude's Discretion)** — "Federated" vs a key-scope callout on the recommended card; executor's call, must be a genuine scan-path key fact.
   **RESOLVED:** Explicitly Claude's Discretion per 134-CONTEXT.md (`### Claude's Discretion`). Executor picks the genuine scan-path key fact ("Federated" or a key-scope callout) at implementation time — no further planning decision required.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Playwright | binding gate | ✓ | `^1.54.2` | — |
| @axe-core/playwright | AA gate | ✓ | `^4.11.3` | — |
| Elixir/Mix + `mix verify.opsui` | static contract | ✓ | task present | — |
| Booted seeded ops server (assets built) | depth spec + 40-shot | requires explicit build/restart (D-14) | — | none — blocking until ops assets built |

**Missing dependencies with no fallback:** none (all present). The only gate is the operational requirement to build ops assets / restart before running (D-14).

## Project Constraints (from CLAUDE.md)

No `./CLAUDE.md` or `./.claude/CLAUDE.md` present; no `.claude/skills/` or `.agents/skills/`. Constraints derive entirely from `134-CONTEXT.md` (D-01→D-18, locked), `134-UI-SPEC.md` (approved), and `DESIGN-TOKENS.md` (the two governing laws: `.ops-` namespacing; never hardcode a raw Tailwind step when a named token exists).

## Sources

### Primary (HIGH confidence)
- `scrypath_ops/assets/css/app.css` (live, 1542 lines) — all selector/value verification.
- `scrypath_ops/assets/css/DESIGN-TOKENS.md` — surface ramp, copper AA pre-clearances, glow recipes.
- `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` — `ops_table` (daisyUI table), `ops_copper_*`, `ops_intent_card`.
- `scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex` — `<.ops_table zebra>` usage (DK-13).
- `examples/scrypath_ecommerce/e2e/{admin_path_motion,admin_contrast_matrix}.spec.ts`, `helpers/e2e.ts`, `light-pixel-diff.mjs`, `package.json` — harness.
- `lib/mix/tasks/verify.opsui.ex`, `scrypath_ops/test/scrypath_ops_web/{design_tokens_contract,motion_contract}_test.exs` — static contract.
- `.planning/config.json` — nyquist_validation enabled.

### Secondary (MEDIUM confidence)
- `129-DARK-AUDIT-BACKLOG.md` rows DK-11→DK-18 — findings being closed (note stale anchors).

## Metadata

**Confidence breakdown:**
- Live-code anchors: HIGH — every anchor re-grepped this session against the 1542-line file.
- Validation architecture: HIGH — harness files, helpers, seed map, npm scripts all confirmed present and matching D-10→D-14.
- Planning risks R1–R4: HIGH (R1/R3 directly verified in code), MEDIUM (R2/R4 depend on browser-engine / seed runtime behavior — see Assumptions).

**Research date:** 2026-06-25
**Valid until:** 2026-07-25 (stable; CSS/harness change infrequently — re-verify anchors if `app.css` line count shifts again before execution)
