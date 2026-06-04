# Phase 132: a11y-contrast-remediation-both-themes-hard-gate-g - Pattern Map

**Mapped:** 2026-06-04
**Files analyzed:** 3 new/modified files
**Analogs found:** 3 / 3

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `scrypath_ops/assets/css/app.css` | config | transform | `scrypath_ops/assets/css/app.css` theme blocks + Phase 130/131 token overrides | exact |
| `scrypath_ops/assets/css/contrast-pairs.mjs` | config | transform | `scrypath_ops/assets/css/contrast-pairs.mjs` muted manifest | exact |
| `scrypath_ops/assets/css/DESIGN-TOKENS.md` | config | batch | `scrypath_ops/assets/css/DESIGN-TOKENS.md` token catalog sections | exact |

Scope note: this phase is CSS/token-only. `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` and `scrypath_ops/lib/scrypath_ops_web/components/layouts.ex` are consumers to verify, not planned modification targets.

## Pattern Assignments

### `scrypath_ops/assets/css/app.css` (config, transform)

**Analog:** `scrypath_ops/assets/css/app.css`

**Theme token declaration pattern** (lines 23-59, 61-97):
```css
@plugin "../vendor/daisyui-theme" {
  name: "dark";
  default: false;
  prefersdark: true;
  color-scheme: "dark";
  --color-base-100: #141923;
  --color-base-content: #f4f1ea;
  --color-primary: #6c5ce7;
  --color-primary-content: #f4f1ea;
  --ops-bg: #0c0f14;
  --ops-surface-1: #141923;
  --ops-surface-2: #1b2230;
}

@plugin "../vendor/daisyui-theme" {
  name: "light";
  default: true;
  prefersdark: false;
  color-scheme: "light";
  --color-base-content: #141923;
  --color-primary: #5b4ad1;
  --color-primary-content: #f4f1ea;
  --ops-bg: #faf7f2;
  --ops-surface-1: #fffdf8;
  --ops-surface-2: #faf7f2;
}
```

Copy this pattern for `--ops-text-muted`, optional `--ops-text-muted-strong`, and `--color-primary-strong`: declare theme-scoped values inside both daisyUI theme blocks when the token should participate in explicit light, explicit dark, and system-dark token output.

**Primary text-bearing background pattern** (lines 620-624):
```css
.ops-nav-item-active {
  background: var(--color-primary);
  color: var(--color-primary-content);
  box-shadow: var(--shadow-ops-surface);
}
```

Route the active nav background to `var(--color-primary-strong)` while preserving `color: var(--color-primary-content)` and the existing shadow/glow composition.

**Generated `bg-primary` consumer to verify, not edit by default** (`scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` lines 795-799):
```elixir
class={[
  "ops-segmented-btn ops-transition-status px-3 text-ops-body font-semibold",
  value == @selected && "bg-primary text-primary-content shadow-ops-mid",
  value != @selected && "text-base-content/75 hover:bg-base-100"
]}
```

The `.bg-primary` failure comes from semantic utility generation. Keep this phase CSS/token-only unless the planner proves a CSS override cannot safely cover text-bearing `.bg-primary` surfaces.

**Muted text recipe pattern** (lines 579, 732-734, 786-788, 872-875, 1163-1171):
```css
.ops-text-meta  { font-size: var(--text-ops-xs); line-height: var(--leading-ops-body); color: color-mix(in oklch, var(--color-base-content) 55%, transparent); }

.ops-trail__crumb {
  color: color-mix(in oklch, var(--color-base-content) 60%, transparent);
}

.ops-cmdk__item-hint {
  font-size: var(--text-ops-xs);
  color: color-mix(in oklch, var(--color-base-content) 55%, transparent);
}

.ops-cmdk__empty {
  padding: var(--spacing-ops-3) var(--spacing-ops-panel);
  color: color-mix(in oklch, var(--color-base-content) 55%, transparent);
  font-size: var(--text-ops-body);
}
```

Replace failing readable muted `color-mix(...)` declarations with named token consumption, e.g. `color: var(--ops-text-muted)`. If any retained `color: color-mix(in oklch, var(--color-base-content) NN%, transparent)` remains, it must stay represented in `contrast-pairs.mjs`.

**Dark dual-path override pattern** (lines 1379-1387, 1406-1427):
```css
/* D-10 application: glow composed onto .ops-nav-item-active (keep surface lift) in dark. */
[data-theme="dark"] .ops-nav-item-active {
  box-shadow: var(--shadow-ops-surface), var(--shadow-ops-glow);
}
@media (prefers-color-scheme: dark) {
  html:not([data-theme="light"]) .ops-nav-item-active {
    box-shadow: var(--shadow-ops-surface), var(--shadow-ops-glow);
  }
}

/* D-10: --shadow-ops-* are @theme tokens, not daisyUI keys — must hand-author both dark paths. */
[data-theme="dark"] {
  --shadow-ops-surface: 0 1px 2px rgba(0,0,0,0.40);
  --shadow-ops-glow:        0 0 8px 2px rgba(108,92,231,0.30);
}
@media (prefers-color-scheme: dark) {
  html:not([data-theme="light"]) {
    --shadow-ops-surface: 0 1px 2px rgba(0,0,0,0.40);
    --shadow-ops-glow:        0 0 8px 2px rgba(108,92,231,0.30);
  }
}
```

Use this only for custom properties that cannot live in daisyUI theme blocks. Prefer theme-block declarations first because they already cover both explicit and system theme paths.

**Boundary pattern to preserve decorative primary uses** (lines 244, 313-314, 917-918, 1031):
```css
.ops-shell {
  background:
    radial-gradient(circle at top left, color-mix(in oklch, var(--color-primary) 14%, transparent), transparent 34rem),
    linear-gradient(180deg, var(--color-base-200), var(--color-base-100));
}

.ops-tone-running {
  border-color: color-mix(in oklch, var(--color-primary) 46%, transparent);
  background: color-mix(in oklch, var(--color-primary) 10%, transparent);
}

.ops-route-mark {
  background: linear-gradient(135deg, var(--color-primary), var(--color-secondary));
}
```

Do not globally darken `--color-primary`; use `--color-primary-strong` only for text-bearing interactive fills.

---

### `scrypath_ops/assets/css/contrast-pairs.mjs` (config, transform)

**Analog:** `scrypath_ops/assets/css/contrast-pairs.mjs`

**Manifest schema and guard contract** (lines 1-31):
```javascript
// Muted-alpha text manifest (D-11): ONLY muted cases that are opacity-mixes of
// base-content via `color-mix(in oklch, var(--color-base-content) NN%, transparent)`.
//
// Design constraints:
//   (1) References TOKEN NAMES not hex — hex lives in app.css only (D-10).
//   (2) Alpha compositing is sRGB, not OKLCH.
//   (3) The D-15 lockstep guard in contrast-checker.mjs validates that every
//       `color: color-mix(in oklch, var(--color-base-content) NN%, transparent)`
//       occurrence in app.css is tracked here.
```

Keep token names, not hex values. If Phase 132 removes failing `color-mix(...)` text declarations by routing to named CSS variables, remove or update the corresponding manifest entries so the reverse lockstep guard does not fail.

**Current failing muted entries to retune or remove if routed through named vars** (lines 32-50, 114-131):
```javascript
export const MUTED_PAIRS = [
  {
    selector: ".ops-text-meta",
    alpha: 0.55,
    fg_token: "base-content",
    bg_token: "base-100",
    role: "text",
    note: "meta/secondary text — xs size"
  },
  {
    selector: ".ops-trail__crumb",
    alpha: 0.60,
    fg_token: "base-content",
    bg_token: "base-100",
    role: "text",
    note: "breadcrumb text"
  },
  {
    selector: ".ops-cmdk__item-hint",
    alpha: 0.55,
    fg_token: "base-content",
    bg_token: "base-100",
    role: "text",
    note: "palette item hint"
  },
  {
    selector: ".ops-cmdk__empty",
    alpha: 0.55,
    fg_token: "base-content",
    bg_token: "base-100",
    role: "text",
    note: "palette empty state"
  }
];
```

**Nearby scoped muted entries** (lines 60-77):
```javascript
{
  selector: ".ops-handoff__hint",
  alpha: 0.60,
  fg_token: "base-content",
  bg_token: "base-100",
  role: "text",
  note: "hint copy"
},
{
  selector: ".ops-preflight__hint",
  alpha: 0.60,
  fg_token: "base-content",
  bg_token: "base-100",
  role: "text",
  note: "hint copy"
}
```

The UI spec includes handoff, palette, and preflight hints. Keep the manifest aligned with every readable muted `color-mix(...)` that remains.

---

### `scrypath_ops/assets/css/DESIGN-TOKENS.md` (config, batch)

**Analog:** `scrypath_ops/assets/css/DESIGN-TOKENS.md`

**Token catalog lockstep pattern** (lines 1-6):
```markdown
# ScrypathOps design tokens

The brand + design-system contract for the `/ops` operator shell. Tokens live in the
`@theme` block of [`app.css`](./app.css); the `.ops-*` component classes in the same
file consume them. This doc is the catalog — change a value here only by changing it in
`app.css`.
```

Update this doc in the same change as `app.css`. For Phase 132, record the exact muted alpha floors, any `--ops-text-muted-strong` split, and `--color-primary-strong` scope.

**Brand color table pattern** (lines 27-41):
```markdown
## Brand colors

daisyUI semantic tokens, two themes (light default, dark via `prefers-dark` / explicit
`data-theme="dark"`). Generate utilities like `bg-primary`, `text-base-content`, `border-base-300`.

| Token | Light | Dark | Use |
| --- | --- | --- | --- |
| `primary` | `#5b4ad1` | `#6c5ce7` | brand/accent, active nav, primary actions |
| `accent` | `#6c5ce7` | `#5b4ad1` | gradient partner (route mark) |
| `base-content` | `#141923` | `#f4f1ea` | text |
```

Add `--color-primary-strong` near this section as a scoped text-bearing interactive background token, not as a replacement for brand/accent primary use.

**Previous token-evidence pattern** (lines 139-159):
```markdown
### Text color rules

**Badge text:** Always `var(--color-base-content)` inside `.ops-copper-badge` — never
`var(--color-secondary)` as the badge label text. Light AA fails at 4.15:1 on tinted copper
background (below the 4.5:1 AA threshold for small text).

### AA pairing evidence

| Pairing | Theme | Ratio | AA verdict |
| --- | --- | --- | --- |
| `base-content` (`#f4f1ea`) text on `.ops-copper-badge` tinted bg | Dark | 12.07:1 | PASS |
```

Copy this style for Phase 132 evidence: specific pair, theme, ratio, and AA verdict. Do not write vague accessibility claims.

**Muted registry documentation pattern** (lines 260-292):
```markdown
## Muted-Text Contrast Registry

The muted-alpha text pairs are tracked in [`contrast-pairs.mjs`](./contrast-pairs.mjs) (beside
this file) — the single source for the D-15 lockstep guard in `contrast-checker.mjs`. The guard
is **bidirectional**: every `color: color-mix(in oklch, var(--color-base-content) NN%, transparent)`
occurrence in `app.css` ... must have a corresponding manifest entry, AND every non-`decorative`
manifest entry must match an actual `app.css` rule.

| Role | AA | AAA |
|------|-----|-----|
| `text` (body/inline) | 4.5:1 | 7.0:1 |
| `large` (uppercase + bold, WCAG large text) | 3.0:1 | 4.5:1 |
| `ui` (non-text, semantic pairs `X-content/X`) | 3.0:1 | 4.5:1 |

The `contrast-checker.mjs` gate exits non-zero iff AA failures exist; AAA is reported as advisory
only and never affects the exit code.
```

Adjust this section if named muted variables replace raw alpha manifest tracking. The doc must explain which muted token(s) are AA floors and which remaining raw muted mixes are still registry-gated.

## Shared Patterns

### WCAG Math And Exit Contract

**Source:** `examples/scrypath_ecommerce/contrast-checker.mjs` lines 39-111, 616-655, 791-809  
**Apply to:** `app.css`, `contrast-pairs.mjs`, `DESIGN-TOKENS.md`

```javascript
function contrastRatioRaw(fg, bg) {
  const L1 = relativeLuminance(fg);
  const L2 = relativeLuminance(bg);
  const lighter = Math.max(L1, L2);
  const darker = Math.min(L1, L2);
  return (lighter + 0.05) / (darker + 0.05);
}

const THRESHOLDS = {
  text:  { aa: 4.5, aaa: 7.0 },
  large: { aa: 3.0, aaa: 4.5 },
  ui:    { aa: 3.0, aaa: 4.5 },
};

process.exit(report.summary.aa_fail > 0 ? 1 : 0);
```

Use unrounded ratios for pass/fail; rounded values are display-only.

### Bidirectional Muted Manifest Guard

**Source:** `examples/scrypath_ecommerce/contrast-checker.mjs` lines 470-612  
**Apply to:** `app.css`, `contrast-pairs.mjs`

```javascript
function assertNoUntrackedMutedTokens(cssText, mutedPairs) {
  const colorMixRe = /(?:^\s*|[{;]\s*)color:\s*color-mix\(in oklch,\s*var\(--color-base-content\)\s*(\d+)%,\s*transparent\)/;

  // Check each found (selector, alpha) pair is in the manifest
  for (const { selector, alpha, lineNumber } of found) {
    const inManifest = mutedPairs.some(
      (pair) => pair.selector === selector && Math.abs(pair.alpha - alpha) <= 0.01
    );
    if (!inManifest) {
      throw new Error(
        `D-15 Guard 2: untracked muted text token!\n` +
          `  Selector: "${selector}" at app.css line ${lineNumber}\n`
      );
    }
  }

  // WR-02: reverse lockstep — every non-decorative manifest entry must correspond to an
  // actual `color: color-mix(...)` occurrence found in app.css.
}
```

Any switch from raw `color-mix(...)` to `var(--ops-text-muted)` changes what this guard sees. Update CSS and manifest together.

### Browser Matrix Hard Gate

**Source:** `examples/scrypath_ecommerce/e2e/admin_contrast_matrix.spec.ts` lines 44-54, 107-119, 316-399, 433-440  
**Apply to:** final verification

```typescript
const THEME_MODES: ThemeMode[] = [
  { kind: "explicit", theme: "light" },
  { kind: "explicit", theme: "dark" },
  { kind: "system", colorScheme: "dark" }
];

const BODY_SELECTORS = [
  "main p",
  "main li",
  "main dd",
  "main dt",
  ".ops-text-body",
  ".ops-preflight__hint",
  ".ops-handoff__hint",
  ".ops-intent-card__summary"
];

const aaResults = await new AxeBuilder({ page })
  .withRules(["color-contrast"])
  .analyze();

const aaFails = findings.filter(f => f.severity === "aa-fail").length;
expect(aaFails, `${aaFails} AA contrast violations found — see CONTRAST_REPORT_DIR`).toBe(0);
```

AA is the hard gate across light, dark, and system-dark. AAA remains advisory and scoped to body selectors.

### Light Pixel Baseline Handling

**Source:** `examples/scrypath_ecommerce/e2e/light-pixel-diff.mjs` lines 1-18, 30-39, 113-136  
**Apply to:** visual proof only

```javascript
// Diffs the 20 light-only admin PNGs from the Jun-3 baseline against a fresh
// set of PNGs using pixelmatch, and exits non-zero if any pair has > 0 diff
// pixels.

const BASELINE_DIR = path.resolve(__dirname, "../.tmp/admin-screenshots");
const FRESH_DIR =
  process.env.PIXEL_DIFF_FRESH_DIR ??
  path.resolve(__dirname, "../.tmp/pixel-diff-fresh");

const diffCount = pixelmatch(
  baseline.data,
  fresh.data,
  diff.data,
  width,
  height,
  { threshold: 0 }
);
```

Phase 132 intentionally changes light pixels. Re-capture the light baseline rather than preserving Phase 131's zero-diff expectation.

### Brand Restraint

**Source:** `prompts/scrypath-brand-book.md` lines 11-13, 193-215  
**Apply to:** `app.css`, `DESIGN-TOKENS.md`

```markdown
Positioning: Ecto-native search indexing and search orchestration
Brand posture: open-source, trustworthy, technical, calm, slightly arcane, never gimmicky

Scrypath should sound:
  • calm
  • exact
  • capable
  • technical
  • generous
  • slightly enigmatic
  • never theatrical
```

Preserve the violet/copper brand expression by scoping stronger contrast tokens to readable text surfaces only.

## No Analog Found

None. All planned files have exact local analogs and established verification tooling.

## Metadata

**Analog search scope:** `scrypath_ops/assets/css/`, `examples/scrypath_ecommerce/`, `scrypath_ops/lib/scrypath_ops_web/components/`, `.planning/phases/130-*`, `.planning/phases/131-*`, `prompts/`  
**Files scanned:** 10 primary files plus phase context/research/UI spec  
**Pattern extraction date:** 2026-06-04
