# Phase 130: Dark surface ramp + depth tokens `[G]` — Research

**Researched:** 2026-06-04
**Domain:** CSS token architecture / daisyUI theme plugin / `.ops-*` fill recipes
**Confidence:** HIGH — all findings verified against live files

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01:** Introduce `--ops-bg`, `--ops-surface-1`, `--ops-surface-2` tokens.
- Dark: `--ops-bg:#0c0f14; --ops-surface-1:#141923; --ops-surface-2:#1b2230;`
- Light: `--ops-bg:#faf7f2; --ops-surface-1:#fffdf8; --ops-surface-2:#faf7f2;`

**D-02:** Declare the three tokens INSIDE both `@plugin "../vendor/daisyui-theme"` blocks (dark + light). The plugin spreads all non-reserved custom props into both `[data-theme=dark]` and `@media (prefers-color-scheme: dark)` — both-path coverage for free.

**D-03:** Keep the `color-mix(in oklch, … N%, transparent)` wrapper; swap only the inner token. Resting panels → `surface-1`; flat/coplanar/below-bg surfaces → `surface-2`.

**D-04:** Light parity is the dominant `[G]`-gate constraint and the universal tie-breaker.

**D-05:** `.ops-data-card` and `.ops-result-row` currently derive from `base-100` in dark but must also lift to `#1B2230` — routing through shared `surface-2` would move their light value. Leave those two recipes' light `color-mix(base-100 …)` unchanged; add a DARK-SCOPED `var(--ops-surface-2)` override for just those two.

**D-06:** Default to token-swap; fall back to dark-scoped override wherever token-swap would move light. Light non-modification always wins.

**D-07:** The contrast lockstep guard (`contrast-checker.mjs`) scans only the `color:` property — all in-scope recipes lift via `background:`, so the guard is a non-issue for this refactor.

**D-08:** Override the four `--shadow-ops-*` token values with a dark-inward low-spread `rgba(0,0,0,α)` ladder — same offsets/blur as light, color/alpha only:
`surface 0 1px 2px /.40` · `mid 0 1px 4px /.45` · `raised 0 2px 10px /.50` · `overlay 0 8px 24px /.55`

**D-09:** One override site cascades to all shadow consumers. Zero recipe edits required.

**D-10:** `--shadow-ops-*` are `@theme` tokens, NOT daisyUI keys — they CANNOT ride the `@plugin` block. Must be hand-authored in BOTH dark selectors: `[data-theme="dark"]` AND `@media (prefers-color-scheme: dark) { html:not([data-theme="light"]) }`.

**D-11:** Proof bundle (run in order): (1) `mix test` + `mix opsui.test_a11y`, (2) `contrast-checker.mjs` light AA/AAA counts unchanged, (3) `npm run test:e2e:admin-contrast`, (4) light-only 20-PNG pixel-diff against `.tmp/admin-screenshots/*light*` baseline, (5) mounted-admin smoke + `DESIGN-TOKENS.md` update.

**D-12:** Defer full 40-shot re-capture + v1.33→v1.34 before/after gallery to Phase 136.

**D-13:** `mix verify.opsui` does NOT exist. Real targets are `mix test` + `mix opsui.test_a11y`. Either use the real names or add a `verify.opsui` alias.

### Claude's Discretion
- Exact per-recipe `surface-1` vs `surface-2` assignment (validated against the live file).
- Precise α values within the shadow ladder (within the D-08 offsets/blur constraint).
- Ordering of edits.
- Whether to add the `verify.opsui` alias.

Provided D-04/D-05/D-06 (light parity tie-breaker), D-02 (token declaration site), and D-10 (shadow dual-path) hold.

### Deferred Ideas (OUT OF SCOPE)
- Symmetric re-tokenization of both themes (baking light values).
- Dark form-input / code-block / `.bg-primary` AA fixes (DK-02/03/04) → Phase 132.
- Glow + copper accent vocabulary (DK-07/08/10/12) → Phase 131.
- Full 40-shot re-capture + v1.33→v1.34 before/after gallery → Phase 136 (DUALVERIFY-01).
- Per-screen polish + shell chrome (DK-11/13/15/16/18) → Phases 134/135.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DARKTOKEN-01 | Dark theme gains a true 4-step surface ramp (`#1B2230` surface-2); `.ops-*` fill recipes resolve correctly in both themes via theme-scoped elevation tokens; light stays pixel-identical; `DESIGN-TOKENS.md` kept in lockstep. | Live file audit confirms: token declarations go in `@plugin` blocks (D-02 verified via plugin source); recipe map below gives exact current token refs for each swap; `ops_code_block` confirmed at `ops_ui.ex:994` as `bg-base-200` (DK-09 reroute target). |
</phase_requirements>

---

## Summary

Phase 130 lands the `#1B2230` surface-2 elevation step — the single missing rung in the dark surface ramp — and re-routes the `.ops-*` fill recipes through three named elevation tokens (`--ops-bg`, `--ops-surface-1`, `--ops-surface-2`) declared inside the daisyUI `@plugin` blocks. All decisions (D-01 through D-13) were validated against the live source files. The plugin mechanism (D-02) is confirmed by reading `daisyui-theme.js` lines 59–96: the rest-spread (`...customThemeTokens`) places ALL non-reserved props into both the explicit `[data-theme="dark"]` selector and the `@media (prefers-color-scheme: dark)` block; the built `priv/static/assets/css/app.css` confirms both blocks at lines 4266 and 4301 are produced correctly. The `--shadow-ops-*` tokens cannot ride the plugin block (they are `@theme` tokens, not daisyUI keys) — the dual-path hand-override at `app.css:525-533` is the established precedent for the shadow override site. The ops_code_block `:default` variant uses `bg-base-200` exactly as CONTEXT.md states, confirmed at `ops_ui.ex:994`.

**Primary recommendation:** Token-swap the 8 listed recipes in `app.css` (routing their inner `var(--color-base-1xx)` refs to `--ops-surface-1` or `--ops-surface-2` per the map below), add DARK-SCOPED overrides for `.ops-data-card` and `.ops-result-row` only (D-05), then override the four `--shadow-ops-*` tokens under both dark selectors. Route `ops_code_block :default` in `ops_ui.ex` to a new `bg-ops-surface-2` utility (which the `@theme` declaration will generate). Update `DESIGN-TOKENS.md`.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Elevation token declaration | CSS `@plugin` block (daisyUI) | — | Plugin spreads custom props to both dark paths for free |
| Recipe token routing | CSS `@layer components` | — | All `.ops-*` fill recipes live in components layer |
| Shadow token dark override | CSS manual dual-path (hand-authored) | — | `@theme` tokens not daisyUI keys — cannot ride plugin |
| `ops_code_block` surface fix | Elixir HEEx component (`ops_ui.ex`) | CSS `@theme` | Utility class must exist before component can use it |
| DESIGN-TOKENS.md lockstep | Documentation (CSS-adjacent) | — | Doc follows `app.css`; no reverse dependency |

---

## Live File Audit — Verified Line Numbers and Current Token References

All line numbers below are from `scrypath_ops/assets/css/app.css` as of 2026-06-04 (1265 total lines). [VERIFIED: live file read]

### daisyUI `@plugin` theme blocks

| Block | Lines | Key dark values confirmed |
|-------|-------|--------------------------|
| Dark theme block | **L23–56** | `--color-base-100: #141923` (L28), `--color-base-200: #0c0f14` (L29), `--color-base-300: #2a3446` (L30), `--color-base-content: #f4f1ea` (L31), `prefersdark: true` (L26) |
| Light theme block | **L58–91** | `--color-base-100: #fffdf8` (L63), `--color-base-200: #faf7f2` (L64), `default: true` (L60) |

CONTEXT.md stated "dark ~L23-56, light ~L58-91" — **CONFIRMED exact**. [VERIFIED: live file read]

### `@custom-variant dark`

| Item | Live line | Value |
|------|-----------|-------|
| `@custom-variant dark` | **L109** | `(&:where([data-theme=dark], [data-theme=dark] *))` |

CONTEXT.md stated "~L109" — **CONFIRMED exact**. [VERIFIED: live file read]

### `@theme` shadow ladder

| Token | Live line | Current light value |
|-------|-----------|-------------------|
| `--shadow-ops-surface` | **L135** | `0 1px 2px color-mix(in oklch, var(--color-base-content) 8%, transparent)` |
| `--shadow-ops-mid` | **L136** | `0 1px 4px color-mix(in oklch, var(--color-base-content) 9%, transparent)` |
| `--shadow-ops-raised` | **L137** | `0 2px 10px color-mix(in oklch, var(--color-base-content) 10%, transparent)` |
| `--shadow-ops-overlay` | **L138** | `0 8px 24px color-mix(in oklch, var(--color-base-content) 12%, transparent)` |

CONTEXT.md stated "~L133-142" — actual range is **L135-138** (4 lines only, not 10). Minor drift. [VERIFIED: live file read]

### `select.ops-form-control` dual-path precedent

| Selector | Live lines | Pattern |
|----------|-----------|---------|
| Light/base | L515-523 | `appearance: none; padding-inline; background-image: url(light-svg);` |
| `[data-theme="dark"]` | **L525** | dark SVG override |
| `@media (prefers-color-scheme: dark) { html:not([data-theme="light"]) }` | **L529-532** | same dark SVG |

CONTEXT.md stated "~L525-533" — **CONFIRMED** (L525 + L529-532 = span of ~L525-533). [VERIFIED: live file read]

### Per-recipe audit

The planner needs the exact current `background:` token reference for each recipe to know what to swap. [VERIFIED: live file read]

| Recipe | Live line | Current `background:` token | Audit result | Assignment (D-03/D-05) |
|--------|-----------|----------------------------|--------------|------------------------|
| `.ops-panel` | **L243** | `color-mix(in oklch, var(--color-base-100) 96%, transparent)` | base-100 → light `#fffdf8` = light surface-1 | **→ `--ops-surface-1`** (shared token-swap safe) |
| `.ops-surface-flat` | **L250** | `color-mix(in oklch, var(--color-base-100) 94%, transparent)` | base-100 → light `#fffdf8` = light surface-1 | **→ `--ops-surface-1`** (shared token-swap safe) |
| `.ops-muted-panel` | **L256** | `color-mix(in oklch, var(--color-base-200) 64%, transparent)` | base-200 → light `#faf7f2` = light surface-2 | **→ `--ops-surface-2`** (shared token-swap safe) |
| `.ops-data-card` | **L262** | `color-mix(in oklch, var(--color-base-100) 92%, transparent)` | base-100 → light `#fffdf8` = light surface-1 ≠ light surface-2 | **D-05 carve-out**: keep `base-100` in light; add dark-scoped `--ops-surface-2` override |
| `.ops-notice-surface` | **L270-277** | NO explicit `background:` property set; inherits transparent | No background to swap. Tone classes (`.ops-tone-*`) set the fill | **No change needed**; tone-class fills are semantic colors, not elevation tokens |
| `.ops-verdict-neutral` | **L357** | `color-mix(in oklch, var(--color-base-200) 64%, transparent)` | base-200 → light `#faf7f2` = light surface-2 | **→ `--ops-surface-2`** (shared token-swap safe) |
| `.ops-nav-list` | **L557** | `color-mix(in oklch, var(--color-base-200) 72%, transparent)` | base-200 → light `#faf7f2` = light surface-2 | **→ `--ops-surface-2`** (shared token-swap safe) |
| `.ops-disclosure` | **L594** | `color-mix(in oklch, var(--color-base-200) 58%, transparent)` | base-200 → light `#faf7f2` = light surface-2 | **→ `--ops-surface-2`** (shared token-swap safe) |
| `.ops-preflight__card` (base) | **L792** | `color-mix(in oklch, var(--color-base-100) 94%, transparent)` | base-100 → light `#fffdf8` = light surface-1 | **→ `--ops-surface-1`** (shared token-swap safe) |
| `.ops-preflight__card--locked` | **L801** | `color-mix(in oklch, var(--color-base-200) 60%, transparent)` | base-200 → light `#faf7f2` = light surface-2 | **→ `--ops-surface-2`** (shared token-swap safe) |
| `.ops-result-row` | **L912** | `color-mix(in oklch, var(--color-base-100) 94%, transparent)` | base-100 → light `#fffdf8` = light surface-1 ≠ light surface-2 | **D-05 carve-out**: keep `base-100` in light; add dark-scoped `--ops-surface-2` override |
| `.ops-kbd` | **L1155** | `color-mix(in oklch, var(--color-base-200) 70%, transparent)` | base-200 → light `#faf7f2` = light surface-2 | **→ `--ops-surface-2`** (shared token-swap safe) |

**CONTEXT.md line number comparison:**

| Recipe | CONTEXT.md stated | Actual live line | Drift? |
|--------|------------------|-----------------|--------|
| `.ops-panel` | ~243 | **243** | None |
| `.ops-surface-flat` | ~250 | **250** | None |
| `.ops-muted-panel` | ~256 | **256** | None |
| `.ops-data-card` | ~262 | **262** | None |
| `.ops-verdict-neutral` | ~357 | **355** (class), **357** (background) | Negligible — 357 is correct for the `background:` property |
| `.ops-nav-list` | ~557 | **557** | None |
| `.ops-disclosure` | ~594 | **594** | None |
| `.ops-preflight__card[--locked]` | ~792/801 | **792** (base bg), **801** (locked bg) | **CONFIRMED exact** |
| `.ops-result-row` | ~912 | **912** (background at 912) | Confirmed; class def starts at 907 |
| `.ops-kbd` | ~1155 | **1155** | None |
| `.ops-notice-surface` | implied as recipe | **L270-277** | **DRIFT: `.ops-notice-surface` has NO `background:` property** — it relies on `.ops-tone-*` classes for fill. No elevation-token swap needed; the tone-fills are semantic colors. |

### `.ops-notice-surface` — important finding

CONTEXT.md groups `.ops-notice-surface` among recipes that need re-routing, but the live CSS at L270-277 shows `.ops-notice-surface` sets only `border-width`, `border-style`, `border-radius`, `padding`, `font-size`, and `color`. The background fill comes entirely from the composed `.ops-tone-*` classes (`.ops-tone-info`, `.ops-tone-success`, etc.), which use tone-semantic colors (info, success, warning, error) mixed at low alphas — NOT from any base-1xx token. There is nothing to re-route for this recipe. The DK-05/DK-15 finding about notice surfaces blending in will resolve automatically once the surrounding page bg and panel surfaces lift — no direct token change needed on this class.

---

## D-02 Verification — daisyUI Plugin Pass-Through Mechanism

**Source read:** `scrypath_ops/assets/vendor/daisyui-theme.js` lines 58–97. [VERIFIED: live file read]

The plugin destructures options as:
```javascript
const {
  name, default: isDefault, prefersdark,
  "color-scheme": colorScheme, root,
  ...customThemeTokens  // ALL remaining props captured here
} = options;
```

Then merges:
```javascript
themeTokens = {
  ...builtinTheme,       // built-in daisyUI "dark" palette defaults
  ...customThemeTokens,  // our @plugin block props — OVERRIDES built-in
  "color-scheme": colorScheme
};
```

Then emits:
```javascript
const baseStyles = { [selector]: { "color-scheme": ..., ...themeTokens } };
if (prefersdark) {
  addBase({ "@media (prefers-color-scheme: dark)": { [root]: baseStyles[selector] } });
}
addBase(baseStyles);
```

**Conclusion:** Any prop placed in the `@plugin "../vendor/daisyui-theme" { name: "dark"; ... }` block (beyond the reserved keys `name`, `default`, `prefersdark`, `color-scheme`, `root`) is included in `customThemeTokens` and is therefore spread into BOTH the `[data-theme="dark"]` selector AND the `@media (prefers-color-scheme: dark) { :root }` block. **D-02 is confirmed. Custom `--ops-bg`, `--ops-surface-1`, `--ops-surface-2` declared in the dark `@plugin` block will get both-path coverage with no manual dual-selector authoring.** [VERIFIED: live file read]

**Built CSS confirmation:** `priv/static/assets/css/app.css` shows both blocks at L4266 (media) and L4301 (explicit selector) contain IDENTICAL token sets — confirming the plugin emits the same custom props to both paths. [VERIFIED: live file read]

---

## D-05 Carve-Out Detail — Two Dark-Scoped Overrides

Two recipes use `base-100` (light value `#fffdf8` = `--ops-surface-1`) but must lift to `--ops-surface-2` (`#1b2230`) in dark without changing light:

**Pattern (following `select.ops-form-control` precedent at L525-533):**

```css
/* .ops-data-card: keep light base-100 fill; dark-only surface-2 lift */
[data-theme="dark"] .ops-data-card {
  background: var(--ops-surface-2);
}
@media (prefers-color-scheme: dark) {
  html:not([data-theme="light"]) .ops-data-card {
    background: var(--ops-surface-2);
  }
}

/* .ops-result-row: same pattern */
[data-theme="dark"] .ops-result-row {
  background: var(--ops-surface-2);
}
@media (prefers-color-scheme: dark) {
  html:not([data-theme="light"]) .ops-result-row {
    background: var(--ops-surface-2);
  }
}
```

Note: The dark-scoped override uses the raw token `var(--ops-surface-2)` (no color-mix wrapper) since the override fires only in dark where `--ops-surface-2` is already `#1b2230` — a solid value. The light `color-mix(base-100 92%/94%)` wrapper stays on the shared recipe.

---

## D-10 Shadow Dual-Path Override Detail

The `--shadow-ops-*` tokens are `@theme` declarations (L135-138) — they are standard Tailwind v4 custom properties, NOT part of any daisyUI `@plugin` block. The plugin's pass-through cannot help here.

**Override pattern (following L525-533 precedent):**

```css
[data-theme="dark"] {
  --shadow-ops-surface: 0 1px 2px rgba(0,0,0,0.40);
  --shadow-ops-mid:     0 1px 4px rgba(0,0,0,0.45);
  --shadow-ops-raised:  0 2px 10px rgba(0,0,0,0.50);
  --shadow-ops-overlay: 0 8px 24px rgba(0,0,0,0.55);
}
@media (prefers-color-scheme: dark) {
  html:not([data-theme="light"]) {
    --shadow-ops-surface: 0 1px 2px rgba(0,0,0,0.40);
    --shadow-ops-mid:     0 1px 4px rgba(0,0,0,0.45);
    --shadow-ops-raised:  0 2px 10px rgba(0,0,0,0.50);
    --shadow-ops-overlay: 0 8px 24px rgba(0,0,0,0.55);
  }
}
```

This single override cascades to all 14 existing shadow consumers (`.ops-panel`, `.ops-surface-flat`, `.ops-notice-surface--raised`, `.ops-verdict--hero`, `.ops-intent-card`, `.ops-intent-card--recommended`, `.ops-nav-item-active`, `#flash-group > *`, `.ops-cmdk__panel`, `.ops-result-row:hover`, `.ops-object-item:hover`, plus the shadow-ops-mid/raised/overlay uses). Zero per-recipe changes required (D-09). [VERIFIED: live file read — shadow token uses confirmed]

---

## `ops_code_block :default` Surface — DK-09 Fix

**File:** `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex`
**Confirmed line:** **994** [VERIFIED: live file read]
**Current value:** `@variant == :default && "max-h-96 bg-base-200 p-ops-3"`

`bg-base-200` in dark = Night `#0c0f14` = darker than surrounding content (inverted hierarchy). The fix replaces `bg-base-200` with `bg-ops-surface-2` — a Tailwind v4 utility that will be auto-generated from the `--spacing-ops-*`... wait, actually from `@theme { --color-ops-surface-2: ... }` but these are NOT standard Tailwind color namespaces.

**Important nuance:** The new `--ops-surface-2` token is declared inside the daisyUI `@plugin` block as a CSS custom property — it is NOT a `@theme` `--color-*` declaration, so Tailwind v4 will NOT generate a `bg-ops-surface-2` utility automatically. The fix requires one of:
1. A direct inline style: `style="background: var(--ops-surface-2)"` (breaks the utility-first convention)
2. A CSS class in `app.css` that applies the token, e.g. `.bg-ops-surface-2 { background: var(--ops-surface-2); }` (add a helper class)
3. Replace `bg-base-200` in the Elixir component with a dark-scoped override in CSS targeting `pre` within `.ops-code-block` (avoids touching `ops_ui.ex`)
4. Add `--color-ops-surface-2` to `@theme` (makes it a Tailwind color utility) and ALSO add `--ops-surface-2` to the plugin block

**Recommended approach (Claude's discretion):** Add a one-liner `.bg-ops-surface-2 { background: var(--ops-surface-2); }` CSS helper class in `app.css` (component layer), then change `bg-base-200` → `bg-ops-surface-2` in `ops_ui.ex:994`. This is the cleanest path — one CSS line, one Elixir line, zero ambiguity. Alternatively, declare `--color-ops-surface-2` in `@theme` (in ADDITION to `--ops-surface-2` in the plugin block), which auto-generates `bg-ops-surface-2`. Either approach is valid within Claude's Discretion.

Note: `:compact` variant uses `bg-base-100` (= light surface-1) and `:embedded` uses `bg-base-100/70` — both already resolve to lighter surfaces in dark (Ink `#141923`). Only `:default` needs the fix. [VERIFIED: live file read, ops_ui.ex:994-996]

---

## Verification Substrate — Confirmed Existence

| Artifact | Path | Status |
|----------|------|--------|
| `mix test` alias | `scrypath_ops/mix.exs:80-85` | CONFIRMED (runs nav-contract check + ecto.create/migrate + test) |
| `mix opsui.test_a11y` alias | `scrypath_ops/mix.exs:86` | CONFIRMED (runs `--only opsui_a11y` tag) |
| `mix verify.opsui` | `scrypath_ops/mix.exs` | CONFIRMED ABSENT — D-13 drift documented |
| `contrast-checker.mjs` | `examples/scrypath_ecommerce/contrast-checker.mjs` | CONFIRMED EXISTS |
| `contrast-pairs.mjs` (D-15 guard) | `scrypath_ops/assets/css/contrast-pairs.mjs` | CONFIRMED EXISTS |
| `admin_contrast_matrix.spec.ts` | `examples/scrypath_ecommerce/e2e/admin_contrast_matrix.spec.ts` | CONFIRMED EXISTS |
| `admin_screenshot_matrix.spec.ts` | `examples/scrypath_ecommerce/e2e/admin_screenshot_matrix.spec.ts` | CONFIRMED EXISTS |
| `npm run test:e2e:admin-contrast` | `examples/scrypath_ecommerce/package.json:11` | CONFIRMED (`playwright test e2e/admin_contrast_matrix.spec.ts`) |
| `npm run test:e2e:admin-matrix` | `examples/scrypath_ecommerce/package.json:10` | CONFIRMED (`playwright test e2e/admin_screenshot_matrix.spec.ts`) |
| Light baselines `.tmp/admin-screenshots/*light*` | `.tmp/admin-screenshots/` | CONFIRMED — 20 light PNGs present (10 screens × 2 viewports) |
| `128-CONTRAST-REPORT.md` baseline | `.planning/phases/128-*/128-CONTRAST-REPORT.md` | CONFIRMED — 108 AA violations, dated 2026-06-04 |
| `DESIGN-TOKENS.md` | `scrypath_ops/assets/css/DESIGN-TOKENS.md` | CONFIRMED EXISTS — has brand-colors table, no elevation-surface subsection yet |

[VERIFIED: all paths confirmed by Bash]

---

## Validation Architecture

`workflow.nyquist_validation: true` in `.planning/config.json` — this section is required. [VERIFIED: live file read]

### Test Framework

| Property | Value |
|----------|-------|
| Framework (unit/a11y) | ExUnit (`mix test`, `mix opsui.test_a11y`) from `scrypath_ops/` |
| Framework (contrast/e2e) | Playwright (`npm run test:e2e:admin-contrast`) from `examples/scrypath_ecommerce/` |
| Framework (light token) | Node.js script (`node contrast-checker.mjs`) from `examples/scrypath_ecommerce/` |
| Framework (pixel-diff) | Disposable pixelmatch/compare loop (no built-in `toMatchSnapshot`) |
| Config files | `scrypath_ops/mix.exs` (Elixir); `examples/scrypath_ecommerce/playwright.config.ts` (Playwright) |
| Elixir quick run | `mix test` (from `scrypath_ops/`) |
| Elixir a11y run | `mix opsui.test_a11y` (from `scrypath_ops/`) |
| Contrast gate run | `npm run test:e2e:admin-contrast` (from `examples/scrypath_ecommerce/`) |
| Light token check | `node contrast-checker.mjs` (from `examples/scrypath_ecommerce/`) |

### Phase Success Criteria → Verification Map

| Criterion | Verification Method | Highest-Fidelity Check | Automated? |
|-----------|--------------------|-----------------------|-----------|
| (a) 4-step dark ramp renders (`#0C0F14→#141923→#1B2230→#2A3446`) | `npm run test:e2e:admin-contrast` — axe sees actual rendered colors in both dark paths | Dark contrast clusters 1 (`.leading-4` 1.08:1 ramp collapse) resolve to 0 failures | Yes |
| (b) Named recipes step UP in dark | Same contrast gate + visual inspection of dark screenshots | Cluster 1 AA violations drop to 0; re-shot dark PNGs show visible panel separation | Partially automated (contrast AA) |
| (c) Light is pixel-identical | Shoot 20 light-only PNGs → `pixelmatch` diff against `.tmp/admin-screenshots/*light*` | 0 diff pixels across all 20 light shots | Yes (disposable script) |
| (d) `DESIGN-TOKENS.md` records the ramp | Human review of committed file diff | Elevation-surface subsection present with 4-step ramp table | Manual |

### Per-Requirement Test Map

| Req ID | Behavior | Test Type | Command | File Exists? |
|--------|----------|-----------|---------|-------------|
| DARKTOKEN-01-a | Dark ramp has 4 distinct steps rendering correctly | e2e contrast | `npm run test:e2e:admin-contrast` | ✅ `admin_contrast_matrix.spec.ts` |
| DARKTOKEN-01-b | Named recipes step up in elevation in dark | e2e contrast | `npm run test:e2e:admin-contrast` | ✅ |
| DARKTOKEN-01-c | Light is pixel-identical (0 diff pixels) | visual diff | Disposable pixelmatch loop (20 PNGs) | ❌ Wave 0 gap — script must be written |
| DARKTOKEN-01-d | No Elixir test regressions | unit | `mix test` (from `scrypath_ops/`) | ✅ existing suite |
| DARKTOKEN-01-e | No a11y regressions | unit/a11y | `mix opsui.test_a11y` | ✅ |
| DARKTOKEN-01-f | Light token contrast counts unchanged | fast token check | `node contrast-checker.mjs` | ✅ |
| DARKTOKEN-01-g | `DESIGN-TOKENS.md` has elevation-surface section | manual review | git diff DESIGN-TOKENS.md | ✅ file exists, section to add |

### Sampling Rate (D-11 order)

1. **Per task commit:** `mix test` (from `scrypath_ops/`)
2. **Post-token-swap:** `node contrast-checker.mjs` — light AA/AAA counts must match Phase 128 baseline
3. **Post-shadow-override:** `npm run test:e2e:admin-contrast` — dark AA failures must resolve cluster 1
4. **Phase gate:** Light 20-PNG pixel-diff → 0 diff pixels; then `mix opsui.test_a11y`

### Wave 0 Gap

- [ ] `examples/scrypath_ecommerce/e2e/light-pixel-diff.mjs` (or equivalent) — a disposable Node script that: loops over `.tmp/admin-screenshots/*light*`, re-shoots the same 20 PNGs in light mode, runs `pixelmatch` per-pair, exits non-zero if any diff > 0. No built-in `toMatchSnapshot` is available (D-12 explicitly defers full matrix to Phase 136); this one-off script is the minimal gate artifact. The plan's Wave 0 must create it.

---

## Architecture Patterns

### Recommended Edit Order

```
app.css:
├── Dark @plugin block (L23-56): add --ops-bg, --ops-surface-1, --ops-surface-2 (dark values)
├── Light @plugin block (L58-91): add --ops-bg, --ops-surface-1, --ops-surface-2 (light values)
├── @layer components:
│   ├── .ops-panel (L243): base-100 → --ops-surface-1
│   ├── .ops-surface-flat (L250): base-100 → --ops-surface-1
│   ├── .ops-muted-panel (L256): base-200 → --ops-surface-2
│   ├── .ops-data-card (L262): stays base-100 (light unchanged)
│   ├── .ops-verdict-neutral (L357): base-200 → --ops-surface-2
│   ├── .ops-nav-list (L557): base-200 → --ops-surface-2
│   ├── .ops-disclosure (L594): base-200 → --ops-surface-2
│   ├── .ops-preflight__card (L792): base-100 → --ops-surface-1
│   ├── .ops-preflight__card--locked (L801): base-200 → --ops-surface-2
│   ├── .ops-result-row (L912): stays base-100 (light unchanged)
│   ├── .ops-kbd (L1155): base-200 → --ops-surface-2
│   ├── [NEW] .bg-ops-surface-2 helper class (for ops_ui.ex)
│   └── [NEW] dark-scoped overrides for .ops-data-card + .ops-result-row
└── [NEW] dual-path --shadow-ops-* overrides (after component layer or at end of file)

ops_ui.ex:
└── L994: bg-base-200 → bg-ops-surface-2

DESIGN-TOKENS.md:
└── Add elevation-surface subsection after brand-colors table
```

### Anti-Patterns to Avoid

- **Baking hex values into recipe `background:` declarations:** The `color-mix` wrapper must be preserved (D-03). Swapping only the inner token is what makes light byte-identical.
- **Adding `--ops-surface-*` to `@theme` instead of `@plugin`:** Would NOT give both-path coverage. `@theme` tokens only set values on `:root` — they don't respond to `[data-theme]` or `prefers-color-scheme` automatically.
- **Authoring dark overrides for the 8 token-swappable recipes:** Only `.ops-data-card` and `.ops-result-row` need dark-scoped overrides (D-05). The other 8 route safely through the shared token.
- **Using `html:not([data-theme="dark"])` in the media query:** The established precedent is `html:not([data-theme="light"])` — this is what `select.ops-form-control` uses at L530. Follow that pattern exactly.
- **Placing `--shadow-ops-*` overrides in the `@plugin` block:** The plugin ignores non-daisyUI tokens placed there (they ARE captured in `customThemeTokens` and emitted, but the Tailwind `@theme` namespace would conflict — safest to hand-author them separately, D-10).

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Both-path dark coverage for new tokens | Hand-authoring `[data-theme="dark"]` + `@media` dual-selectors for elevation tokens | `@plugin` block (D-02) | Plugin auto-emits both paths; verified in vendor source |
| Per-recipe dark shadow variants | New `--shadow-ops-dark-*` tokens or per-recipe overrides | Single `--shadow-ops-*` override (D-08/D-09) | One site cascades to all 14 consumers |
| Pixel-identity proof | Re-derived analysis | Run the 20-PNG pixelmatch diff | Only empirical proof satisfies D-04 |

---

## Common Pitfalls

### Pitfall 1: Token declared in `@plugin` but not emitted in system-dark
**What goes wrong:** Developer adds `--ops-surface-2` to the dark `@plugin` block but forgets the light `@plugin` block → light theme has no `--ops-surface-2` → recipes using it in light fall back to `initial` or `inherited` → visual regression.
**Why it happens:** D-01 requires both blocks. Light's `--ops-surface-2: #faf7f2` is mandatory.
**How to avoid:** Always add the token to BOTH plugin blocks in the same commit.

### Pitfall 2: `color-mix` wrapper removed for dark-scoped overrides
**What goes wrong:** D-05 dark-scoped overrides use raw `var(--ops-surface-2)` (correct!) but developer also removes the `color-mix` from the shared recipe, baking `--ops-surface-1` as a solid value → light loses the subtle transparency layer.
**How to avoid:** The shared recipe keeps its `color-mix(in oklch, var(--ops-surface-N) XX%, transparent)` wrapper. The dark-scoped overrides for `.ops-data-card` and `.ops-result-row` use a SOLID `var(--ops-surface-2)` (the alpha is irrelevant in dark since surface-2 is opaque).

### Pitfall 3: `contrast-checker.mjs` D-15 guard fails on shadow tokens
**What goes wrong:** A `box-shadow` value using `color-mix(…, var(--color-base-content) …)` is flagged by the lockstep guard.
**Why it happens:** The D-15 guard regex matches `color:` property only — NOT `box-shadow`. D-07 explicitly documents this guard excludes `background` and `border-color`; it also excludes `box-shadow`.
**How to avoid:** No action needed. The shadow `color-mix` overrides are in `box-shadow`, not `color:`, so the D-15 guard is silent.

### Pitfall 4: `mix verify.opsui` called in plan tasks
**What goes wrong:** Plan references `mix verify.opsui` — this alias does NOT exist (D-13). CI/plan execution fails.
**How to avoid:** Use `mix test` + `mix opsui.test_a11y` explicitly, OR create a `verify.opsui` alias as a Wave 0 optional improvement. The planner should choose one path.

### Pitfall 5: `.ops-notice-surface` treated as a recipe to reroute
**What goes wrong:** Plan includes a token-swap task for `.ops-notice-surface` — but this class has no `background:` property to swap (tone fills come from `.ops-tone-*`). Task is a no-op and wastes a wave slot.
**How to avoid:** Skip `.ops-notice-surface` from the recipe-routing wave. DK-15 will resolve as the surrounding surface hierarchy lifts.

---

## Runtime State Inventory

Step 2.5 does not apply — this is a CSS/token/component phase (no rename, no migration). [SKIPPED: greenfield CSS edit, not a rename/refactor]

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node.js | `contrast-checker.mjs`, pixelmatch script | ✓ | (confirmed: npm scripts work) | — |
| Playwright | `test:e2e:admin-contrast` | ✓ | (confirmed: spec files exist, harness used in Phase 128) | — |
| Docker (containerized test stack) | contrast gate (needs server) | ✓ | (confirmed: used in Phase 128 at WEB_PORT=4012) | — |
| `pixelmatch` npm package | Wave 0 light-pixel-diff script | [ASSUMED] — likely in devDeps but not verified | — | Install in Wave 0 |
| `.tmp/admin-screenshots/*light*` | Light pixel-identity baseline | ✓ | 20 PNGs confirmed present 2026-06-04 | — |

**Missing dependencies with no fallback:** None blocking.
**Missing dependencies with fallback:** `pixelmatch` — verify it's in `examples/scrypath_ecommerce/package.json` before writing the diff script; if absent, add it in Wave 0.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Per-recipe dark overrides (~18 dual-selector blocks) | Token-layer + plugin pass-through (3 tokens, 2 blocks) | Phase 130 (this phase) | Ramp tunable from one site; no hand-sync of per-recipe dark rules |
| Cream-on-dark shadows (`color-mix(base-content N%, transparent)`) | Dark-inward `rgba(0,0,0,α)` shadows under dark selectors | Phase 130 (this phase) | Shadow depth visible in dark; light untouched |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `pixelmatch` is available in the ecommerce Node lane (in package.json devDeps) | Environment Availability | Wave 0 must add it if absent — small additional task |
| A2 | The D-08 shadow alpha values (`0.40/0.45/0.50/0.55`) are the exact values the planner should use | Architecture Patterns | They are within "Claude's Discretion" per CONTEXT.md — planner can tune within D-08's stated range |
| A3 | Adding `.bg-ops-surface-2` as a CSS helper class is the right fix strategy for `ops_code_block` | `ops_code_block` section | Planner may prefer adding `--color-ops-surface-2` to `@theme` instead — both valid under Claude's Discretion |

---

## Open Questions (RESOLVED)

1. **`verify.opsui` alias — add it or not?**
   - What we know: the alias does not exist (D-13 confirmed); REQUIREMENTS.md and ROADMAP.md reference it.
   - What's unclear: whether the planner should add it as a Wave 0 task or just document it as a doc-drift.
   - Recommendation: Add `"verify.opsui": ["test", "opsui.test_a11y"]` as an alias in `mix.exs` — one-line fix that makes future milestone docs (Phase 136's DUALVERIFY-01 instructions) literal. Claude's Discretion.
   - **RESOLVED by Plan 01 Task 2:** adds the `"verify.opsui": ["test", "opsui.test_a11y"]` alias to `scrypath_ops/mix.exs`.

2. **`pixelmatch` availability**
   - What we know: `.tmp/admin-screenshots/*light*` has 20 baseline PNGs.
   - What's unclear: whether `pixelmatch` is already in `examples/scrypath_ecommerce/package.json`.
   - Recommendation: Wave 0 task should verify and install if absent.
   - **RESOLVED by Plan 01 Task 1:** adds `pixelmatch` and `pngjs` to `examples/scrypath_ecommerce/package.json` devDependencies.

---

## Drift Corrections from CONTEXT.md

| Item | CONTEXT.md stated | Live file reality | Severity |
|------|------------------|-------------------|----------|
| `--shadow-ops-*` ladder lines | "~L133-142" | **L135-138** (4 lines, not spanning to 142) | Low — 4-line span vs 10-line span; shadow tokens are at 135-138 |
| `.ops-notice-surface` treatment | Grouped with recipes needing re-routing | **No `background:` property** — tone-fills from `.ops-tone-*` classes only | Medium — removes one task from scope; planner should NOT add a recipe-routing task for this class |
| `ops_code_block` fix strategy | Implied as simple class swap in `ops_ui.ex` | Requires a CSS helper class (`.bg-ops-surface-2`) because `--ops-surface-2` is NOT a `@theme` color token and won't auto-generate a `bg-*` utility | Medium — plan needs an extra 1-line CSS task |

---

## Sources

### Primary (HIGH confidence)
- `scrypath_ops/assets/css/app.css` (1265 lines) — live recipe audit, line-number confirmation
- `scrypath_ops/assets/vendor/daisyui-theme.js` — plugin pass-through mechanism (lines 59–96)
- `scrypath_ops/priv/static/assets/css/app.css` — built CSS confirming both-path emission at L4266 + L4301
- `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex:994` — `ops_code_block :default` `bg-base-200` confirmation
- `scrypath_ops/mix.exs` — alias verification (test, opsui.test_a11y present; verify.opsui absent)
- `.tmp/admin-screenshots/` — 20 light baseline PNGs confirmed present
- `examples/scrypath_ecommerce/package.json` — npm script names confirmed
- `.planning/phases/129-dark-theme-brand-expression-audit-s-r/129-DARK-AUDIT-BACKLOG.md` — phase scope contracts

### Secondary (MEDIUM confidence)
- `.planning/phases/128-contrast-gate-harness-dark-seed-coverage-s-g/128-CONTRAST-REPORT.md` — 108-violation baseline
- `scrypath_ops/assets/css/DESIGN-TOKENS.md` — confirmed exists, no elevation-surface section yet
- `scrypath_ops/assets/css/contrast-pairs.mjs` — D-15 lockstep guard confirmed

---

## Metadata

**Confidence breakdown:**
- Token architecture (D-02 plugin mechanism): HIGH — verified in plugin source + built CSS
- Recipe line numbers and current values: HIGH — verified by live read of all named lines
- `.ops-notice-surface` finding (no background): HIGH — confirmed by direct read of L270-277
- `ops_code_block` fix strategy (needs CSS helper): HIGH — confirmed by understanding of `@theme` vs `@plugin` namespaces
- Shadow alpha values (0.40/0.45/0.50/0.55): MEDIUM — within Claude's Discretion range per D-08
- `pixelmatch` availability: LOW — not verified in package.json

**Research date:** 2026-06-04
**Valid until:** 2026-07-04 (stable CSS — no fast-moving dependencies)
