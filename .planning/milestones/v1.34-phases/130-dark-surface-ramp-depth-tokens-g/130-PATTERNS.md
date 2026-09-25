# Phase 130: Dark surface ramp + depth tokens `[G]` — Pattern Map

**Mapped:** 2026-06-04
**Files analyzed:** 5 (4 modified + 1 new)
**Analogs found:** 5 / 5

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `scrypath_ops/assets/css/app.css` (plugin blocks + recipes + helper class + shadow override) | config/style | transform | Self (existing `select.ops-form-control` dual-path block at L525-533; existing `@plugin` blocks at L23-91) | exact — in-file precedent |
| `scrypath_ops/assets/css/app.css` (D-05 dark-scoped overrides for `.ops-data-card` + `.ops-result-row`) | config/style | transform | `select.ops-form-control` dual-path block (L525-533) | exact — dual-path pattern |
| `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` (`ops_code_block :default`) | component | request-response | Self (`ops_code_block` `:compact` and `:embedded` variants at L995-996) | exact — adjacent variant lines |
| `scrypath_ops/assets/css/DESIGN-TOKENS.md` (new elevation-surface subsection) | documentation | transform | Self (existing `## Shadow` subsection at L72-78; existing brand-colors table at L28-41) | exact — in-file table pattern |
| `examples/scrypath_ecommerce/e2e/light-pixel-diff.mjs` (NEW — disposable Wave 0 script) | utility | file-I/O | `examples/scrypath_ecommerce/contrast-checker.mjs` | role-match (Node.js script: path resolution, file reads, exit-code pattern) |

---

## Pattern Assignments

### 1. `scrypath_ops/assets/css/app.css` — `@plugin` block token declarations (D-01, D-02)

**Analog:** Self — dark `@plugin` block (L23-56), light `@plugin` block (L58-91)

**Core `@plugin` block structure** (app.css L23-56 and L58-91):
```css
@plugin "../vendor/daisyui-theme" {
  name: "dark";
  default: false;
  prefersdark: true;
  color-scheme: "dark";
  --color-base-100: #141923;
  --color-base-200: #0c0f14;
  --color-base-300: #2a3446;
  --color-base-content: #f4f1ea;
  /* ... existing tokens ... */
  --depth: 1;
  --noise: 0;
  /* NEW: elevation tokens go here — plugin spreads all non-reserved props to
     both [data-theme="dark"] AND @media (prefers-color-scheme: dark) */
  /* --ops-bg: #0c0f14;       */
  /* --ops-surface-1: #141923; */
  /* --ops-surface-2: #1b2230; */
}

@plugin "../vendor/daisyui-theme" {
  name: "light";
  default: true;
  prefersdark: false;
  color-scheme: "light";
  --color-base-100: #fffdf8;
  --color-base-200: #faf7f2;
  /* ... existing tokens ... */
  --depth: 1;
  --noise: 0;
  /* NEW: MUST also add to light block — D-01 requires both blocks */
  /* --ops-bg: #faf7f2;        */
  /* --ops-surface-1: #fffdf8; */
  /* --ops-surface-2: #faf7f2; */
}
```

**Key rule:** Any custom property added inside either `@plugin "../vendor/daisyui-theme"` block (beyond the reserved keys `name`, `default`, `prefersdark`, `color-scheme`, `root`) is included in `...customThemeTokens` by `daisyui-theme.js` (lines 59-96) and emitted to BOTH `[data-theme="dark"]` AND `@media (prefers-color-scheme: dark) { :root }`. No manual dual-selector authoring needed for these tokens.

---

### 2. `scrypath_ops/assets/css/app.css` — `color-mix` recipe token swap (D-03)

**Analog:** Self — existing recipe declarations at the verified live lines

**Current recipe pattern** (representative excerpts):
```css
/* app.css L240-244 — .ops-panel (base-100 → --ops-surface-1) */
.ops-panel {
  border: 1px solid color-mix(in oklch, var(--color-base-content) 14%, transparent);
  border-radius: var(--radius-ops-lg);
  background: color-mix(in oklch, var(--color-base-100) 96%, transparent);
  box-shadow: var(--shadow-ops-surface);
}

/* app.css L253-257 — .ops-muted-panel (base-200 → --ops-surface-2) */
.ops-muted-panel {
  border: 1px solid color-mix(in oklch, var(--color-base-content) 10%, transparent);
  border-radius: var(--radius-ops-lg);
  background: color-mix(in oklch, var(--color-base-200) 64%, transparent);
}
```

**The swap rule — change ONLY the inner token, preserve the wrapper and alpha:**

| Recipe | Live line | Current inner token | New inner token | Method |
|--------|-----------|--------------------|-----------------|-|
| `.ops-panel` | L243 | `var(--color-base-100)` | `var(--ops-surface-1)` | token-swap |
| `.ops-surface-flat` | L250 | `var(--color-base-100)` | `var(--ops-surface-1)` | token-swap |
| `.ops-muted-panel` | L256 | `var(--color-base-200)` | `var(--ops-surface-2)` | token-swap |
| `.ops-data-card` | L262 | `var(--color-base-100)` | **STAYS** `var(--color-base-100)` | D-05 carve-out — dark override instead |
| `.ops-verdict-neutral` | L357 | `var(--color-base-200)` | `var(--ops-surface-2)` | token-swap |
| `.ops-nav-list` | L557 | `var(--color-base-200)` | `var(--ops-surface-2)` | token-swap |
| `.ops-disclosure` | L594 | `var(--color-base-200)` | `var(--ops-surface-2)` | token-swap |
| `.ops-preflight__card` | L792 | `var(--color-base-100)` | `var(--ops-surface-1)` | token-swap |
| `.ops-preflight__card--locked` | L801 | `var(--color-base-200)` | `var(--ops-surface-2)` | token-swap |
| `.ops-result-row` | L912 | `var(--color-base-100)` | **STAYS** `var(--color-base-100)` | D-05 carve-out — dark override instead |
| `.ops-kbd` | L1155 | `var(--color-base-200)` | `var(--ops-surface-2)` | token-swap |

**Anti-pattern:** Do NOT add `--ops-surface-*` to `@theme` — this bypasses the plugin pass-through and provides no theme-aware both-path coverage. Do NOT bake hex values into `background:` declarations; the `color-mix` wrapper must be preserved.

**SKIP:** `.ops-notice-surface` (L270-277) has NO `background:` property — fill comes from composed `.ops-tone-*` classes. No token swap needed.

---

### 3. `scrypath_ops/assets/css/app.css` — D-05 dark-scoped overrides + `.bg-ops-surface-2` helper

**Analog:** Self — `select.ops-form-control` dual-path precedent (app.css L525-533)

**The exact dual-path precedent to copy** (app.css L515-533):
```css
/* Light/base rule — stays untouched */
select.ops-form-control {
  appearance: none;
  padding-inline: var(--control-pad-x-md);
  /* ... */
  background-image: url("data:image/svg+xml,...light SVG...");
  background-repeat: no-repeat;
  background-position: right 0.625rem center;
}

/* Explicit dark path */
[data-theme="dark"] select.ops-form-control {
  background-image: url("data:image/svg+xml,...dark SVG...");
}

/* System dark path */
@media (prefers-color-scheme: dark) {
  html:not([data-theme="light"]) select.ops-form-control {
    background-image: url("data:image/svg+xml,...dark SVG...");
  }
}
```

**D-05 dark-scoped override pattern** (for `.ops-data-card` and `.ops-result-row` — copy from research):
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

**Note:** Dark-scoped overrides use raw `var(--ops-surface-2)` with NO `color-mix` wrapper. The color-mix wrapper stays ONLY on the shared light recipe. The media-query guard is `html:not([data-theme="light"])` — NOT `html:not([data-theme="dark"])`.

**`.bg-ops-surface-2` CSS helper class** (new, in `@layer components`):
```css
/* Helper utility for ops_code_block — enables bg-ops-surface-2 Tailwind-style class.
   --ops-surface-2 is declared in the @plugin block (not @theme), so Tailwind v4
   cannot auto-generate a bg-* utility for it. One-liner bridge. */
.bg-ops-surface-2 {
  background: var(--ops-surface-2);
}
```

---

### 4. `scrypath_ops/assets/css/app.css` — `--shadow-ops-*` dark dual-path override (D-08, D-10)

**Analog:** Self — `select.ops-form-control` dual-path precedent (L525-533); shadow `@theme` tokens (L135-138)

**Existing `@theme` shadow ladder** (app.css L133-138):
```css
/* Elevation ladder: surface (resting) → mid (hover) → raised (lifts off page) → overlay */
--shadow-ops-surface: 0 1px 2px color-mix(in oklch, var(--color-base-content) 8%, transparent);
--shadow-ops-mid:     0 1px 4px color-mix(in oklch, var(--color-base-content) 9%, transparent);
--shadow-ops-raised:  0 2px 10px color-mix(in oklch, var(--color-base-content) 10%, transparent);
--shadow-ops-overlay: 0 8px 24px color-mix(in oklch, var(--color-base-content) 12%, transparent);
```

**Dark override pattern** (hand-authored dual-path — these are `@theme` tokens, NOT daisyUI keys):
```css
/* D-10: --shadow-ops-* are @theme tokens, not daisyUI keys — must hand-author both paths.
   Same offsets/blur as light; color/alpha only. Cascades to all 14 shadow consumers. */
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

**Anti-pattern:** Do NOT place `--shadow-ops-*` overrides inside the `@plugin` block. Although the plugin DOES spread them via `...customThemeTokens`, the Tailwind `@theme` namespace would conflict — safest to hand-author separately, exactly as D-10 prescribes.

---

### 5. `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` — `ops_code_block :default` (DK-09)

**Analog:** Self — adjacent `:compact` and `:embedded` variants at L994-996

**Current `ops_code_block` component** (ops_ui.ex L989-1002):
```elixir
def ops_code_block(assigns) do
  ~H"""
  <pre
    class={[
      "overflow-auto rounded-ops-md font-mono text-ops-sm whitespace-pre-wrap break-words",
      @variant == :default && "max-h-96 bg-base-200 p-ops-3",    # ← L994: change bg-base-200
      @variant == :compact && "max-h-48 bg-base-100 p-ops-2",    # ← L995: stays (already surface-1)
      @variant == :embedded && "max-h-64 bg-base-100/70 p-ops-3", # ← L996: stays
      @class
    ]}
    {@rest}
  >{render_slot(@inner_block)}</pre>
  """
end
```

**The edit:** Change `bg-base-200` → `bg-ops-surface-2` on L994 only. The `.bg-ops-surface-2` helper class must exist in `app.css` first (see Pattern 3 above).

**Rationale:** In dark, `bg-base-200` = Night `#0c0f14` = the deepest floor (inverted hierarchy for a code block inside a panel). `bg-ops-surface-2` = `#1b2230` in dark (raised step, visually elevated vs the panel) and `#faf7f2` in light (= current `base-200` value — pixel-identical).

**Pattern to mirror** (how the sibling variants use background utilities):
```elixir
@variant == :compact  && "max-h-48 bg-base-100 p-ops-2"    # bg-base-100 = surface-1
@variant == :embedded && "max-h-64 bg-base-100/70 p-ops-3" # bg-base-100/70 = semi-transparent surface-1
# New target:
@variant == :default  && "max-h-96 bg-ops-surface-2 p-ops-3" # bg-ops-surface-2 = surface-2
```

---

### 6. `scrypath_ops/assets/css/DESIGN-TOKENS.md` — elevation-surface subsection (D-11 step 5)

**Analog:** Self — existing `## Shadow` subsection (L72-78) and `## Brand colors` table (L28-41)

**Existing table pattern** to mirror (L28-41):
```markdown
| Token | Light | Dark | Use |
| --- | --- | --- | --- |
| `primary` | `#5b4ad1` | `#6c5ce7` | brand/accent, active nav, primary actions |
| `base-100` | `#fffdf8` | `#141923` | surfaces |
| `base-200` | `#faf7f2` | `#0c0f14` | app background, muted panels |
```

**Existing shadow subsection pattern** to mirror (L72-78):
```markdown
## Shadow — `--shadow-ops-*` → `shadow-ops-*`

Elevation ladder: `surface` (1px, resting) → `mid` (subtle hover / interactive state) →
`raised` (10px, the element lifts off the page) → `overlay` (24px, modals/flash). Use
`mid` for hover/selected feedback, `raised` only for a genuine lift (intent-card hover).
`focus` is **reserved** — prefer the global `:focus-visible` outline (see Focus below);
the box-shadow ring is only an escape hatch for inset focus inside overflow-clipped boxes.
```

**New subsection to add** (after the brand-colors table, before `## Spacing`):
```markdown
## Elevation surfaces — `--ops-bg`, `--ops-surface-1`, `--ops-surface-2`

Named elevation tokens declared in the daisyUI `@plugin` blocks (dark + light). The plugin
spreads them to both `[data-theme="dark"]` and `@media (prefers-color-scheme: dark)` for
free. Ramp direction in dark: bg (floor) → surface-1 (resting panel) → surface-2 (raised).

| Token | Light value | Dark value | Use |
| --- | --- | --- | --- |
| `--ops-bg` | `#faf7f2` | `#0c0f14` | Page floor / Night — app background |
| `--ops-surface-1` | `#fffdf8` | `#141923` | Resting panel / Ink — `.ops-panel`, `.ops-surface-flat`, `.ops-preflight__card` |
| `--ops-surface-2` | `#faf7f2` | `#1b2230` | Raised / muted step — `.ops-muted-panel`, `.ops-disclosure`, `.ops-nav-list`, `.ops-kbd`, `.ops-verdict-neutral`, `.ops-preflight__card--locked` |

Dark 4-step midnight ramp: `#0C0F14` (bg) → `#141923` (surface-1) → `#1B2230` (surface-2) → `#2A3446` (base-300 / borders).
Light values are byte-identical to the prior `base-200`/`base-100` references — zero light regression.
```

---

### 7. `examples/scrypath_ecommerce/e2e/light-pixel-diff.mjs` (NEW — Wave 0 disposable script)

**Analog:** `examples/scrypath_ecommerce/contrast-checker.mjs`

**Structural pattern from contrast-checker.mjs to copy:**

**Header / module-level comment** (contrast-checker.mjs L1-22):
```javascript
// light-pixel-diff.mjs
//
// Disposable Wave 0 pixel-identity gate for Phase 130 (DARKTOKEN-01-c).
// Shoots the same 20 light-only PNGs that exist in BASELINE_DIR (the Jun-3 baseline),
// diffs each pair with pixelmatch, and exits non-zero if any pair has > 0 diff pixels.
//
// Usage (from examples/scrypath_ecommerce/):
//   node e2e/light-pixel-diff.mjs
//
// Requires: pixelmatch, pngjs (add to devDependencies if absent)
// Phase 136 owns the full 40-shot re-capture; this script is light-only and disposable.
```

**Import / path-setup block** (mirrors contrast-checker.mjs L23-37):
```javascript
import { readFile, readdir, mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// Baseline: the Jun-3 light screenshots stored in .tmp/admin-screenshots/
const BASELINE_DIR = path.resolve(__dirname, "../../.tmp/admin-screenshots");
// Fresh shots: re-shoot light-only PNGs here
const FRESH_DIR = process.env.PIXEL_DIFF_FRESH_DIR || "test-results/pixel-diff-fresh";
// Diff output: write side-by-side diff PNGs for any failing pair
const DIFF_DIR = process.env.PIXEL_DIFF_DIFF_DIR || "test-results/pixel-diff-out";
```

**Exit-code pattern** (mirrors contrast-checker.mjs L807-815):
```javascript
// Exit non-zero iff any pair has > 0 diff pixels.
// Mirrors the contract of contrast-checker.mjs: the exit code IS the gate verdict.
main().catch((err) => {
  console.error("light-pixel-diff error:", err.message);
  process.exit(2);
});
```

**File-listing pattern** — baseline PNG names follow the naming convention from admin_screenshot_matrix.spec.ts (L71):
`NN-screen--theme--viewport--state.png`

Light-only files match: `*--light--*`

```javascript
// Filter baseline for light-only PNGs
const allFiles = await readdir(BASELINE_DIR);
const lightFiles = allFiles.filter(f => f.includes("--light--") && f.endsWith(".png"));
```

**Pass/fail accumulation pattern** (mirrors contrast-checker.mjs L791-809):
```javascript
let totalFail = 0;

for (const filename of lightFiles) {
  const baselinePng = /* read from BASELINE_DIR */;
  const freshPng    = /* read from FRESH_DIR — same filename */;
  const diffCount   = /* pixelmatch result */;
  if (diffCount > 0) {
    totalFail++;
    console.error(`DIFF: ${filename} — ${diffCount} px differ`);
  } else {
    console.log(`OK:   ${filename}`);
  }
}

console.log(`\nLight pixel-diff: ${totalFail === 0 ? "PASS" : "FAIL"}`);
console.log(`  Failed pairs: ${totalFail} / ${lightFiles.length}`);
process.exit(totalFail > 0 ? 1 : 0);
```

**Wave 0 prerequisite:** `pixelmatch` and `pngjs` are NOT in `examples/scrypath_ecommerce/package.json` (confirmed: devDependencies only has `@axe-core/playwright` and `@playwright/test`). The plan's Wave 0 must add them:
```json
"devDependencies": {
  "@axe-core/playwright": "^4.11.3",
  "@playwright/test": "^1.54.2",
  "pixelmatch": "^5.3.0",
  "pngjs": "^7.0.0"
}
```

**Playwright integration note:** The script is a standalone Node.js runner (like `contrast-checker.mjs`), NOT a Playwright spec. It does NOT use `@playwright/test` APIs — screenshots are re-shot by driving Playwright's CLI or by a separate Playwright script, then read as raw PNG buffers. The simpler approach: re-shoot using Playwright with `--project=chromium` (light theme only) via a minimal inline spec, then run the `pixelmatch` comparison loop in this Node script against the saved files.

---

## Shared Patterns

### Dual-path dark selector structure
**Source:** `scrypath_ops/assets/css/app.css` L525-533 (`select.ops-form-control`)
**Apply to:** D-05 dark-scoped overrides for `.ops-data-card` + `.ops-result-row`; D-10 shadow token overrides

```css
/* Pattern: explicit dark path first, then system-dark path */
[data-theme="dark"] .TARGET {
  /* dark-only override */
}
@media (prefers-color-scheme: dark) {
  html:not([data-theme="light"]) .TARGET {
    /* identical override — same values, same property */
  }
}
```

Always `html:not([data-theme="light"])` — never `html:not([data-theme="dark"])`.

### `color-mix(in oklch, TOKEN N%, transparent)` recipe wrapper
**Source:** `scrypath_ops/assets/css/app.css` L243, L250, L256, L262, etc.
**Apply to:** ALL 8 token-swappable recipes — change only the inner `var(--color-base-1xx)` reference; α and wrapper are preserved verbatim.

```css
/* Example: before → after */
background: color-mix(in oklch, var(--color-base-200) 64%, transparent);  /* BEFORE */
background: color-mix(in oklch, var(--ops-surface-2)  64%, transparent);  /* AFTER */
```

### Node.js script file-I/O boilerplate
**Source:** `examples/scrypath_ecommerce/contrast-checker.mjs` L23-37, L660-668, L807-815
**Apply to:** `light-pixel-diff.mjs`

Core imports: `node:fs/promises` (readFile, readdir, mkdir, writeFile), `node:path`, `node:url` (fileURLToPath). Paths resolved with `path.resolve(__dirname, "../../...")`. Main function is `async function main()` called as `main().catch(err => { console.error(...); process.exit(2); })`.

---

## No Analog Found

None. All 5 files have strong in-repo analogs (either direct self-references or the contrast-checker.mjs pattern).

---

## Anti-Patterns to Avoid (Compiler Checks)

These are confirmed pitfalls from RESEARCH.md that the planner must explicitly guard against in task descriptions:

| Anti-pattern | Correct pattern | Where |
|---|---|---|
| Adding `--ops-surface-*` to `@theme` block | Add ONLY to `@plugin` blocks (both dark + light) | D-02 |
| Removing `color-mix(...)` wrapper when swapping token | Swap inner token only; wrapper + alpha stay | D-03/D-04 |
| Adding dark-scoped overrides for the 8 token-swappable recipes | Only `.ops-data-card` + `.ops-result-row` need overrides | D-05/D-06 |
| `html:not([data-theme="dark"])` in media query | Always `html:not([data-theme="light"])` | L530 precedent |
| Placing `--shadow-ops-*` overrides in `@plugin` block | Hand-author in both dark selectors only | D-10 |
| Including `.ops-notice-surface` in the recipe-routing task | Skip it — no `background:` property to swap | RESEARCH.md L141 |
| Calling `mix verify.opsui` in plan tasks | Use `mix test` + `mix opsui.test_a11y` | D-13 |

---

## Metadata

**Analog search scope:** `scrypath_ops/assets/css/`, `scrypath_ops/lib/scrypath_ops_web/components/`, `examples/scrypath_ecommerce/`
**Files read:** 7 source files (app.css × targeted sections, DESIGN-TOKENS.md, ops_ui.ex, contrast-checker.mjs, admin_screenshot_matrix.spec.ts, package.json, .tmp/admin-screenshots/ listing)
**Pattern extraction date:** 2026-06-04
