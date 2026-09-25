# Phase 128: Contrast Gate Harness + Dark Seed Coverage — Pattern Map

**Mapped:** 2026-06-04
**Files analyzed:** 5 (3 new, 2 modified)
**Analogs found:** 4 / 5 (contrast-pairs.mjs has no direct analog — documented below)

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `examples/scrypath_ecommerce/e2e/admin_contrast_matrix.spec.ts` | test | request-response (axe analyze per page) | `examples/scrypath_ecommerce/e2e/admin_screenshot_matrix.spec.ts` | exact clone — replace `shoot()` with `axeCheck()`, extend theme loop to discriminated union |
| `examples/scrypath_ecommerce/contrast-checker.mjs` | utility | batch (parse CSS → compute → write report) | `examples/scrypath_ecommerce/e2e/admin_screenshot_matrix.spec.ts` (fs/promises + path + report write pattern) | partial — same Node built-ins, no browser; math is self-contained |
| `scrypath_ops/assets/css/contrast-pairs.mjs` | config | transform (token-name → alpha+surface manifest) | `scrypath_ops/assets/css/DESIGN-TOKENS.md` (sibling design-system doc) | no code analog — first `.mjs` in that directory; structure from D-11 spec |
| `examples/scrypath_ecommerce/Makefile` (modify) | config | batch | `examples/scrypath_ecommerce/Makefile` lines 61–69 (`screenshots` / `screenshots-matrix` targets) | exact — follow `ADMIN_SCREENSHOT_DIR` env convention and `## ` help string pattern |
| `examples/scrypath_ecommerce/package.json` (modify) | config | — | `examples/scrypath_ecommerce/package.json` lines 9–10 (`test:e2e:admin-screens` / `test:e2e:admin-matrix` scripts) | exact — follow existing `playwright test <spec-path>` script shape |

---

## Pattern Assignments

### `examples/scrypath_ecommerce/e2e/admin_contrast_matrix.spec.ts` (test, request-response)

**Analog:** `examples/scrypath_ecommerce/e2e/admin_screenshot_matrix.spec.ts`

**Clone strategy:** Copy the analog wholesale. Three surgical changes:
1. Replace the `Theme` union + `THEMES` array + `shoot()` function with the `ThemeMode` discriminated union + `THEME_MODES` array + `axeCheck()` function (D-09).
2. Replace the `screenshotDir` / `mkdir` / `page.screenshot()` logic inside `shoot()` with the two-pass axe analyze (D-04, D-20) and report accumulation (D-17, D-18).
3. Extend the `describeScenario` captures with the 4 dark-risk supplement states (D-02, indices 10–13).

All six `gotoXxx` prepare helpers, `runSearch`, `describeScenario` loop structure, `ScreenCapture` type, timeout, and the `drainSearchQueue`/`waitForSearchVisible` guard in the `all_green` branch carry over unchanged.

**Imports pattern** (analog lines 19–29 — copy exactly, add `AxeBuilder` import):
```typescript
import { expect, test, type Browser, type Page } from "@playwright/test";
import { mkdir } from "node:fs/promises";
import path from "node:path";

import {
  drainSearchQueue,
  seedScenario,
  waitForLiveConnected,
  waitForSearchVisible,
  type SeedScenario
} from "./helpers/e2e";
```
Add after those imports:
```typescript
import { AxeBuilder } from "@axe-core/playwright";
```

**Theme type replacement** (analog lines 33–42 → D-09 discriminated union):
```typescript
// REMOVE:
type Theme = "light" | "dark";
const THEMES: Theme[] = ["light", "dark"];

// REPLACE WITH (D-09):
type ThemeMode =
  | { kind: "explicit"; theme: "light" | "dark" }
  | { kind: "system"; colorScheme: "dark" };

const THEME_MODES: ThemeMode[] = [
  { kind: "explicit", theme: "light" },
  { kind: "explicit", theme: "dark" },
  { kind: "system", colorScheme: "dark" }
];

// Flat slug for file naming and report schema `theme` field (D-18):
function themeSlug(mode: ThemeMode): string {
  return mode.kind === "system" ? `system-${mode.colorScheme}` : mode.theme;
}
```

**Viewport constants** (analog lines 36–43 — copy unchanged):
```typescript
type ViewportName = "mobile" | "desktop";

const VIEWPORTS: Record<ViewportName, { width: number; height: number }> = {
  mobile: { width: 390, height: 844 },
  desktop: { width: 1440, height: 900 }
};

const VIEWPORT_NAMES: ViewportName[] = ["mobile", "desktop"];
```

**ScreenCapture type** (analog lines 46–51 — copy unchanged):
```typescript
type ScreenCapture = {
  index: string;
  screen: string;
  state: string;
  prepare: (page: Page) => Promise<void>;
};
```

**`shoot()` → `axeCheck()` replacement** (analog lines 53–76 — the core divergence):

The analog `shoot()` (lines 53–76):
```typescript
async function shoot(
  browser: Browser,
  capture: ScreenCapture,
  theme: Theme,
  viewport: ViewportName
): Promise<void> {
  const context = await browser.newContext({ viewport: VIEWPORTS[viewport] });
  await context.addInitScript(
    ([key, value]) => { window.localStorage.setItem(key, value); },
    ["phx:theme", theme]
  );
  const page = await context.newPage();
  try {
    await capture.prepare(page);
    await mkdir(screenshotDir, { recursive: true });
    const name = `${capture.index}-${capture.screen}--${theme}--${viewport}--${capture.state}`;
    await page.screenshot({ path: path.join(screenshotDir, `${name}.png`), fullPage: true });
  } finally {
    await context.close();
  }
}
```

Replace with `axeCheck()` following D-06/D-08/D-09/D-04/D-20:
```typescript
const BODY_SELECTORS = [
  "main p", "main li", "main dd", "main dt",
  ".ops-text-body", ".ops-preflight__hint", ".ops-handoff__hint",
  ".ops-intent-card__summary"
];

async function axeCheck(
  browser: Browser,
  capture: ScreenCapture,
  mode: ThemeMode,
  viewport: ViewportName,
  findings: ContrastFinding[]   // accumulator for unified report (D-17)
): Promise<void> {
  // D-09: system-dark uses colorScheme override; explicit rows do NOT set colorScheme
  const ctxOptions = mode.kind === "system"
    ? { viewport: VIEWPORTS[viewport], colorScheme: mode.colorScheme as "dark" }
    : { viewport: VIEWPORTS[viewport] };

  const context = await browser.newContext(ctxOptions);

  if (mode.kind === "explicit") {
    // D-09: write phx:theme for explicit rows only
    await context.addInitScript(
      ([key, value]: [string, string]) => { window.localStorage.setItem(key, value); },
      ["phx:theme", mode.theme]
    );
  }
  // D-07: system-dark row deliberately OMITS the phx:theme write

  const page = await context.newPage();
  try {
    await capture.prepare(page);
    // D-08: runtime invariants for system-dark AFTER waitForLiveConnected (called inside prepare)
    if (mode.kind === "system") {
      await assertSystemDarkInvariants(page);
    }

    // D-04: AA gate pass — color-contrast rule only, gate on violations[] NEVER on incomplete[]
    const aaResults = await new AxeBuilder({ page })
      .withRules(["color-contrast"])
      .analyze();

    // D-20: AAA advisory pass — scoped to body selectors, NEVER affects exit code
    const aaaBuilder = new AxeBuilder({ page })
      .withRules(["color-contrast-enhanced"]);
    for (const sel of BODY_SELECTORS) { aaaBuilder.include(sel); }
    const aaaResults = await aaaBuilder.analyze();

    // Accumulate into unified report (D-17/D-18) — see report section below
    appendFindings(findings, { capture, mode, viewport, aaResults, aaaResults });
  } finally {
    await context.close();
  }
}
```

**D-08 runtime invariants** (after `waitForLiveConnected`, before axe pass — system-dark only):
```typescript
async function assertSystemDarkInvariants(page: Page): Promise<void> {
  // 1. <html> must have NO data-theme (proves we're on the media-query path, not explicit)
  await expect(page.locator("html")).not.toHaveAttribute("data-theme");
  // 2. Playwright colorScheme emulation must be active (guards silent no-op)
  const mediaMatches = await page.evaluate(
    () => window.matchMedia("(prefers-color-scheme: dark)").matches
  );
  expect(mediaMatches).toBe(true);
  // 3. App's own OS-resolution logic must resolve to dark
  await expect(page.locator("html")).toHaveAttribute("data-theme-effective", "dark");
}
```

**`describeScenario()` loop** (analog lines 79–107 — one word changed: `THEMES` → `THEME_MODES`, `theme` → `mode`):
```typescript
function describeScenario(scenario: SeedScenario, captures: ScreenCapture[]): void {
  test(`admin contrast matrix — ${scenario}`, async ({ browser, request }) => {
    test.setTimeout(180_000);
    const seed = await seedScenario(request, scenario);
    if (scenario === "all_green" && seed.tenant_id) {
      await drainSearchQueue(request);
      await waitForSearchVisible(request, {
        tenantId: seed.tenant_id,
        query: "quantum",
        expectedName: "Quantum CyberPhone X"
      });
    }
    const findings: ContrastFinding[] = [];
    for (const capture of captures) {
      for (const mode of THEME_MODES) {      // ← was: for (const theme of THEMES)
        for (const viewport of VIEWPORT_NAMES) {
          await axeCheck(browser, capture, mode, viewport, findings);
        }
      }
    }
    // D-21: write report BEFORE deciding exit
    await writeContrastReport(findings, scenario);
    const aaFails = findings.filter(f => f.severity === "aa-fail").length;
    expect(aaFails, `${aaFails} AA contrast violations found — see CONTRAST_REPORT_DIR`).toBe(0);
  });
}
```

**Six `gotoXxx` prepare helpers** (analog lines 111–156 — copy verbatim, zero changes):
```typescript
// Copy these functions unchanged from admin_screenshot_matrix.spec.ts lines 111-156:
async function gotoControlRoom(page: Page): Promise<void>  // lines 111-115
async function gotoPosture(page: Page): Promise<void>       // lines 117-121
async function gotoFailedSync(page: Page): Promise<void>    // lines 123-129
async function gotoSyncDrift(page: Page): Promise<void>     // lines 131-139
async function gotoSearch(page: Page): Promise<void>        // lines 141-145
async function gotoPlaybooks(page: Page): Promise<void>     // lines 147-151
async function runSearch(page: Page, query: string): Promise<void>  // lines 153-156
```

Key pattern from `gotoControlRoom` (lines 111–115) as exemplar — each calls `waitForLiveConnected` internally, which is where D-08 invariants can safely attach:
```typescript
async function gotoControlRoom(page: Page): Promise<void> {
  await page.goto("/admin/search");
  await waitForLiveConnected(page);
  await expect(page.getByRole("heading", { name: "Control Room" })).toBeVisible();
}
```

**Scenario groups** (analog lines 161–218 — copy D-01 curated 9 states verbatim, add D-02 dark-risk supplement):
```typescript
// D-01: Copy the 3 scenario groups exactly (indices 00-09), then add dark-risk captures:
describeScenario("incident", [
  { index: "00", screen: "control-room", state: "incident", prepare: gotoControlRoom },
  { index: "01", screen: "posture", state: "incident", prepare: gotoPosture },
  { index: "02", screen: "failed-sync", state: "populated", prepare: async (page) => {
      await gotoFailedSync(page);
      await expect(page.getByTestId("failed-sync-row").first()).toBeVisible();
  }},
  { index: "03", screen: "sync-drift", state: "drift", prepare: gotoSyncDrift },
  // D-02 dark-risk supplement:
  { index: "10", screen: "sync-drift", state: "drift-detail", prepare: async (page) => {
      await gotoSyncDrift(page);
      // drift chips + muted metadata on non-incident surface — dark #1B2230 gap target
  }}
]);
describeScenario("all_green", [
  { index: "04", screen: "control-room", state: "all-green", prepare: gotoControlRoom },
  { index: "05", screen: "posture", state: "all-green", prepare: gotoPosture },
  { index: "06", screen: "search", state: "results", prepare: async (page) => {
      await gotoSearch(page); await runSearch(page, "quantum");
      await expect(page.getByRole("heading", { name: "Results" })).toBeVisible();
  }},
  // D-02 dark-risk supplement:
  { index: "11", screen: "posture", state: "healthy-detail", prepare: async (page) => {
      await gotoPosture(page);
      // posture populated/healthy detail — muted metadata rows
  }},
  { index: "13", screen: "search", state: "results-with-facets", prepare: async (page) => {
      await gotoSearch(page); await runSearch(page, "quantum");
      await expect(page.getByRole("heading", { name: "Results" })).toBeVisible();
      // facet/secondary text visible — muted text contrast target
  }}
]);
describeScenario("empty", [
  { index: "07", screen: "failed-sync", state: "empty", prepare: gotoFailedSync },
  { index: "08", screen: "search", state: "zero-results", prepare: async (page) => {
      await gotoSearch(page); await runSearch(page, "nothingmatchesthisquery");
      await page.waitForTimeout(500);
  }},
  { index: "09", screen: "playbooks", state: "empty-workspace", prepare: gotoPlaybooks },
  // D-02 dark-risk supplement:
  { index: "12", screen: "playbooks", state: "populated", prepare: async (page) => {
      await gotoPlaybooks(page);
      // playbooks with saved items — muted metadata rows in dark
  }}
]);
```

**`waitForLiveConnected` signature** (from `examples/scrypath_ecommerce/e2e/helpers/e2e.ts` lines 11–20):
```typescript
export async function waitForLiveConnected(page: Page): Promise<void> {
  await page.waitForFunction(
    () => {
      const ls = (window as unknown as { liveSocket?: { isConnected?: () => boolean } }).liveSocket;
      return Boolean(ls && typeof ls.isConnected === "function" && ls.isConnected());
    },
    undefined,
    { timeout: 15_000 }
  );
}
```
Note: D-08 invariants attach AFTER `waitForLiveConnected` returns — `data-theme-effective` is set by the no-flash init script before LiveView connects, so it is safe to read after this point.

**`seedScenario` signature** (from `helpers/e2e.ts` lines 99–116):
```typescript
export async function seedScenario(
  request: APIRequestContext,
  scenario: SeedScenario = "e2e_search_catalog"
): Promise<SeedResult>
// SeedResult: { tenant_id: number | null, categories: Record<string,number>, products: Record<string,number>, scenario?, failed_count?, drift? }
// SeedScenario: "all_green" | "degraded" | "incident" | "empty" | "e2e_search_catalog"
```

**Report env convention** (mirrors `ADMIN_SCREENSHOT_DIR` from analog line 31):
```typescript
const contrastReportDir = process.env.CONTRAST_REPORT_DIR || "test-results/contrast";
```

---

### `examples/scrypath_ecommerce/contrast-checker.mjs` (utility, batch)

**Analog:** `examples/scrypath_ecommerce/e2e/admin_screenshot_matrix.spec.ts` (Node fs/promises, path, mkdir patterns) + RESEARCH.md Patterns 5–9 (no code analog for the WCAG math or CSS parse; use the locked D-10–D-16 spec).

**Node built-ins pattern** (from analog — copy the import pattern):
```javascript
import { readFile, mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
// app.css path: ../../scrypath_ops/assets/css/app.css (D-16)
const APP_CSS_PATH = path.resolve(__dirname, "../../scrypath_ops/assets/css/app.css");
// manifest path: ../../scrypath_ops/assets/css/contrast-pairs.mjs (D-11)
const PAIRS_PATH = path.resolve(__dirname, "../../scrypath_ops/assets/css/contrast-pairs.mjs");
```

**CSS parse strategy** (D-10 — two daisyUI theme blocks in `app.css` lines 23–91):

Dark theme block (lines 23–56) starts with `name: "dark"` and has 20 `--color-*` declarations:
```css
@plugin "../vendor/daisyui-theme" {
  name: "dark";
  --color-base-100: #141923;
  --color-base-200: #0c0f14;
  --color-base-300: #2a3446;
  --color-base-content: #f4f1ea;
  --color-primary: #6c5ce7;
  --color-primary-content: #f4f1ea;
  --color-secondary: #c17a3e;
  --color-secondary-content: #0c0f14;
  --color-accent: #5b4ad1;
  --color-accent-content: #f4f1ea;
  --color-neutral: #2a3446;
  --color-neutral-content: #f4f1ea;
  --color-info: #5ca9e6;
  --color-info-content: #0c0f14;
  --color-success: #4fae74;
  --color-success-content: #0c0f14;
  --color-warning: #d9a441;
  --color-warning-content: #0c0f14;
  --color-error: #d96262;
  --color-error-content: #0c0f14;
  /* + non-color tokens: --radius-*, --size-*, --border, --depth, --noise */
}
```

Light theme block (lines 58–91) same structure with different hex values. Parse with:
```javascript
function parseThemeBlocks(css) {
  const blocks = {};
  const blockRe = /@plugin[^{]*daisyui-theme[^{]*\{([^}]+)\}/g;
  let m;
  while ((m = blockRe.exec(css)) !== null) {
    const body = m[1];
    const nameMatch = body.match(/name:\s*"([^"]+)"/);
    if (!nameMatch) continue;
    const name = nameMatch[1];
    blocks[name] = {};
    const tokenRe = /--color-([\w-]+):\s*(#[0-9a-fA-F]{6})/g;
    let t;
    while ((t = tokenRe.exec(body)) !== null) {
      blocks[name][t[1]] = t[2];
    }
  }
  return blocks; // { dark: { "base-100": "#141923", ... }, light: { ... } }
}
```

**Semantic pair derivation rule table** (D-10 — derive pairs, never re-declare hex):
```javascript
// Fixed rule table: X ↔ X-content for all 8 semantic pairs + base-content ↔ base-100/200/300
const PAIR_RULES = [
  { fg: "base-content", bg: "base-100",     role: "text" },
  { fg: "base-content", bg: "base-200",     role: "text" },
  { fg: "base-content", bg: "base-300",     role: "text" },
  { fg: "primary-content", bg: "primary",   role: "ui" },   // button pairs → 3.0 threshold
  { fg: "secondary-content", bg: "secondary", role: "ui" },
  { fg: "accent-content", bg: "accent",     role: "ui" },
  { fg: "neutral-content", bg: "neutral",   role: "ui" },
  { fg: "info-content", bg: "info",         role: "ui" },
  { fg: "success-content", bg: "success",   role: "ui" },
  { fg: "warning-content", bg: "warning",   role: "ui" },
  { fg: "error-content", bg: "error",       role: "ui" },
];
```

**D-14 threshold table** (role → AA / AAA required):
```javascript
const THRESHOLDS = {
  text:  { aa: 4.5, aaa: 7.0 },
  large: { aa: 3.0, aaa: 4.5 },
  ui:    { aa: 3.0, aaa: 4.5 },
};
```

**WCAG math** (D-13 — hand-rolled ~30 lines, zero deps):
```javascript
// D-12: composite in sRGB (matches axe-core): out = fg·α + bg·(1−α) per channel
function compositeAlpha(fgHex, alpha, bgHex) {
  const parse = h => [parseInt(h.slice(1,3),16), parseInt(h.slice(3,5),16), parseInt(h.slice(5,7),16)];
  const fg = parse(fgHex), bg = parse(bgHex);
  const out = fg.map((f, i) => Math.round(f * alpha + bg[i] * (1 - alpha)));
  return "#" + out.map(c => c.toString(16).padStart(2, "0")).join("");
}

function toLinear(c) {
  return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
}

function relativeLuminance(hex) {
  const r = parseInt(hex.slice(1,3),16)/255;
  const g = parseInt(hex.slice(3,5),16)/255;
  const b = parseInt(hex.slice(5,7),16)/255;
  return 0.2126*toLinear(r) + 0.7152*toLinear(g) + 0.0722*toLinear(b);
}

function contrastRatio(fg, bg) {
  const L1 = relativeLuminance(fg), L2 = relativeLuminance(bg);
  const [lighter, darker] = [Math.max(L1, L2), Math.min(L1, L2)];
  return Math.round(((lighter + 0.05) / (darker + 0.05)) * 100) / 100;
}

// D-13 golden self-test: contrastRatio("#000000", "#ffffff") === 21.00
```

**D-15 lockstep guard — untracked muted token check:**

The D-15 guard greps `app.css` for every `color:` property using `color-mix(in oklch, var(--color-base-content) NN%, transparent)` and fails if any `(alpha%, selector)` is not in the `contrast-pairs.mjs` manifest. The grep target is exclusively the `color:` CSS property (not `border-color`, `background`, `box-shadow`, `--shadow-*`).

Grep strategy for the guard (run against the parsed text, not shell):
```javascript
// Find all text-color muted patterns: property `color:` with base-content alpha mix
const textColorRe = /color:\s*color-mix\(in oklch,\s*var\(--color-base-content\)\s*(\d+)%,\s*transparent\)/g;
// The selector context requires finding the surrounding rule block — either use:
// 1. A CSS rule parser (scan for the preceding `{` and the selector before it), or
// 2. A line-by-line scan pairing selector lines (`.ops-*`) with color-mix `color:` lines
```

**D-21 exit behavior pattern:**
```javascript
// D-21: write report BEFORE deciding exit so failure reasons are readable
await mkdir(reportDir, { recursive: true });
await writeFile(path.join(reportDir, "contrast-report.json"), JSON.stringify(report, null, 2));
await writeFile(path.join(reportDir, "contrast-report.md"), buildMarkdownReport(report));

// Exit non-zero iff summary.aa_fail > 0 (NEVER gate on aaa_advisory count)
process.exit(report.summary.aa_fail > 0 ? 1 : 0);
```

**`--self-test` flag** (D-13 golden test + Proof 1/2/5):
```javascript
// Invoked as: node contrast-checker.mjs --self-test
if (process.argv.includes("--self-test")) {
  const r1 = contrastRatio("#000000", "#ffffff");
  console.assert(r1 === 21.00, `golden test failed: expected 21.00 got ${r1}`);
  const r2 = contrastRatio("#767676", "#ffffff");
  console.assert(r2 < 4.5, `known-fail pair should be <4.5, got ${r2}`);
  const r3 = contrastRatio("#595959", "#ffffff");
  console.assert(r3 >= 4.5, `known-pass pair should be >=4.5, got ${r3}`);
  // Proof 5: AAA advisory pair must not affect aa_fail count
  // (verified structurally: aaa findings use severity:"aaa-body-advisory" only)
  console.log("self-test passed");
  process.exit(0);
}
```

---

### `scrypath_ops/assets/css/contrast-pairs.mjs` (config, transform)

**Analog:** `scrypath_ops/assets/css/DESIGN-TOKENS.md` (sibling location; same design-system family). No code analog — first `.mjs` in that directory.

**Location rationale** (D-11): Sits beside `DESIGN-TOKENS.md` so it is physically adjacent to `app.css` and the design token documentation. References token NAMES not hex (hex lives only in `app.css` — D-10).

**Muted text-color patterns extracted from `app.css`** (lines with `color: color-mix(in oklch, var(--color-base-content) NN%, transparent)`):

| Line | Selector | Alpha | Role | Surface |
|------|----------|-------|------|---------|
| 431 | `.ops-badge-neutral` | 82% | text | `--color-base-200` (badge background) |
| 479 | `.ops-tone-chip__value` | 75% | text | tone-chip surface (transparent over `base-100`/`base-200`) |
| 537 | `.ops-text-meta` | 55% | text | nearest opaque ancestor (`base-100` or `base-200`) |
| 691 | `.ops-trail__crumb` | 60% | text | `base-100` nav background |
| 711 | `.ops-trail__sep` | 35% | decorative | (not contrast-gated — separator) |
| 727 | `.ops-handoff__eyebrow` | 50% | text (large/upper) | `base-100` page background |
| 746 | `.ops-handoff__hint` | 60% | text | `base-100` page background |
| 833 | `.ops-preflight__hint` | 60% | text | `base-100` page background |
| 898 | `.ops-intent-card__summary` | 75% | text | `.ops-intent-card` background (`base-100` 94%) |
| 985 | `.ops-signal-table th[scope="row"]` | 78% | text | table `base-100` background |
| 1115 | `.ops-cmdk__item-hint` | 55% | text | cmdk panel background (`base-100`/`base-200`) |
| 1120 | `.ops-cmdk__empty` | 55% | text | cmdk panel background |
| 1144 | `.ops-cheatsheet__row dd` | 70% | text | cheatsheet surface (`base-100`) |

**Module shape** (D-11 — export an array of manifest entries):
```javascript
// scrypath_ops/assets/css/contrast-pairs.mjs
// Muted-alpha text manifest: ONLY cases that are opacity-mixes of base-content.
// References TOKEN NAMES not hex (hex lives in app.css — D-10).
// The D-15 lockstep guard in contrast-checker.mjs validates that every
// `color: color-mix(in oklch, var(--color-base-content) NN%, transparent)` in
// app.css is tracked here.
// Alpha compositing: sRGB (D-12): out = fg·α + bg·(1−α) per channel.

export const MUTED_PAIRS = [
  {
    selector: ".ops-text-meta",
    alpha: 0.55,
    fg_token: "base-content",
    bg_token: "base-100",
    role: "text",          // → AA 4.5 / AAA 7.0 (D-14)
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
    selector: ".ops-handoff__eyebrow",
    alpha: 0.50,
    fg_token: "base-content",
    bg_token: "base-100",
    role: "large",         // → AA 3.0 (uppercase, font-weight 700, letter-spacing)
    note: "uppercase eyebrow label — qualifies as large text by weight+size"
  },
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
  },
  {
    selector: ".ops-intent-card__summary",
    alpha: 0.75,
    fg_token: "base-content",
    bg_token: "base-100",  // intent-card bg is base-100 94% ≈ opaque base-100
    role: "text",
    note: "card body text"
  },
  {
    selector: ".ops-tone-chip__value",
    alpha: 0.75,
    fg_token: "base-content",
    bg_token: "base-100",
    role: "text",
    note: "chip value text (default/no-tone state)"
  },
  {
    selector: ".ops-badge-neutral",
    alpha: 0.82,
    fg_token: "base-content",
    bg_token: "base-200",  // badge bg is base-200 74% ≈ base-200
    role: "text",
    note: "neutral badge text"
  },
  {
    selector: ".ops-signal-table th[scope=\"row\"]",
    alpha: 0.78,
    fg_token: "base-content",
    bg_token: "base-100",
    role: "text",
    note: "table row header text"
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
  },
  {
    selector: ".ops-cheatsheet__row dd",
    alpha: 0.70,
    fg_token: "base-content",
    bg_token: "base-100",
    role: "text",
    note: "cheatsheet description text"
  },
  // Decorative separator — NOT contrast-gated (excluded from checker evaluation):
  {
    selector: ".ops-trail__sep",
    alpha: 0.35,
    fg_token: "base-content",
    bg_token: "base-100",
    role: "decorative",    // decorative: skipped by contrast checker (no threshold)
    note: "breadcrumb separator — decorative, not readable text"
  }
];
```

---

### `examples/scrypath_ecommerce/Makefile` (config, modify)

**Analog:** `examples/scrypath_ecommerce/Makefile` lines 61–69 (`screenshots` / `screenshots-matrix` targets).

**Existing pattern to mirror** (lines 26–27 and 61–69):
```makefile
# Line 26 — .PHONY declaration (add to this):
.PHONY: help dev infra infra-pg up down reset seed screenshots screenshots-matrix logs ps

# Lines 61-69 — existing screenshot targets (mirror this pattern exactly):
screenshots: ## Capture admin-UI screenshots against the running dev server
	@ADMIN_SCREENSHOT_DIR=$${ADMIN_SCREENSHOT_DIR:-test-results/admin-screenshots} \
	  PLAYWRIGHT_BASE_URL=http://127.0.0.1:$(WEB_PORT) \
	  npm run test:e2e:admin-screens

screenshots-matrix: ## Capture the full theme×viewport×state admin screenshot matrix
	@ADMIN_SCREENSHOT_DIR=$${ADMIN_SCREENSHOT_DIR:-test-results/admin-screenshots} \
	  PLAYWRIGHT_BASE_URL=http://127.0.0.1:$(WEB_PORT) \
	  npm run test:e2e:admin-matrix
```

**New targets to add** (D-16/D-17 — sibling of `screenshots-matrix`):
```makefile
# Add CONTRAST_REPORT_DIR env var alongside ADMIN_SCREENSHOT_DIR (line 31 area):
CONTRAST_REPORT_DIR ?= test-results/contrast

# Add to .PHONY line 26:
.PHONY: help dev infra infra-pg up down reset seed screenshots screenshots-matrix contrast contrast-matrix logs ps

# Add after screenshots-matrix target (after line 69):
contrast: ## Run the fast token-pair contrast checker (no browser, <1s)
	@CONTRAST_REPORT_DIR=$${CONTRAST_REPORT_DIR:-$(CONTRAST_REPORT_DIR)} \
	  node contrast-checker.mjs

contrast-matrix: ## Run the full axe contrast matrix (browser required — server must be running)
	@CONTRAST_REPORT_DIR=$${CONTRAST_REPORT_DIR:-$(CONTRAST_REPORT_DIR)} \
	  PLAYWRIGHT_BASE_URL=http://127.0.0.1:$(WEB_PORT) \
	  npm run test:e2e:admin-contrast
```

Key conventions (from Makefile lines 28–30):
- `## ` after the target name — used by the self-documenting `help` target's `grep -hE` pattern
- `@` prefix suppresses echoing the command
- `$${VAR:-$(VAR)}` pattern — allows env override while falling back to the Make variable default
- Tab indentation (not spaces) — Make requires this

---

### `examples/scrypath_ecommerce/package.json` (config, modify)

**Analog:** `examples/scrypath_ecommerce/package.json` lines 9–10 (existing `test:e2e:*` scripts).

**Existing pattern to mirror** (lines 5–11):
```json
"scripts": {
  "test:e2e:headed": "playwright test --headed",
  "test:e2e": "playwright test",
  "test:e2e:list": "playwright test --list",
  "test:e2e:admin-screens": "playwright test e2e/admin_screenshots.spec.ts",
  "test:e2e:admin-matrix": "playwright test e2e/admin_screenshot_matrix.spec.ts"
},
```

**Changes to make:**
```json
"scripts": {
  "test:e2e:headed": "playwright test --headed",
  "test:e2e": "playwright test",
  "test:e2e:list": "playwright test --list",
  "test:e2e:admin-screens": "playwright test e2e/admin_screenshots.spec.ts",
  "test:e2e:admin-matrix": "playwright test e2e/admin_screenshot_matrix.spec.ts",
  "test:e2e:admin-contrast": "playwright test e2e/admin_contrast_matrix.spec.ts"
},
"devDependencies": {
  "@axe-core/playwright": "^4.11.3",
  "@playwright/test": "^1.54.2"
}
```

Install command (D-16): `cd examples/scrypath_ecommerce && npm install --save-dev @axe-core/playwright`

---

## Shared Patterns

### Theme injection via `addInitScript`
**Source:** `examples/scrypath_ecommerce/e2e/admin_screenshot_matrix.spec.ts` lines 60–65
**Apply to:** `axeCheck()` in `admin_contrast_matrix.spec.ts` — explicit rows only (D-09)
```typescript
await context.addInitScript(
  ([key, value]) => { window.localStorage.setItem(key, value); },
  ["phx:theme", theme]
);
```
Critical: system-dark rows deliberately OMIT this call. The absence of `phx:theme` in localStorage causes the no-flash init script to take the `"system"` branch, leaving `data-theme` absent on `<html>`, which routes to the `@media (prefers-color-scheme: dark)` daisyUI token block.

### `waitForLiveConnected` usage pattern
**Source:** `examples/scrypath_ecommerce/e2e/helpers/e2e.ts` lines 11–20
**Apply to:** All `gotoXxx` prepare helpers (called inside each helper before assertions) and the D-08 invariants (which fire after `waitForLiveConnected` returns)
```typescript
export async function waitForLiveConnected(page: Page): Promise<void> {
  await page.waitForFunction(
    () => {
      const ls = (window as unknown as { liveSocket?: { isConnected?: () => boolean } }).liveSocket;
      return Boolean(ls && typeof ls.isConnected === "function" && ls.isConnected());
    },
    undefined,
    { timeout: 15_000 }
  );
}
```

### `@custom-variant dark` — explicit-dark vs system-dark cascade distinction
**Source:** `scrypath_ops/assets/css/app.css` line 109
**Apply to:** Understanding why system-dark must use `colorScheme` not `phx:theme` write
```css
@custom-variant dark (&:where([data-theme=dark], [data-theme=dark] *));
```
Tailwind `dark:` utilities only fire on `[data-theme=dark]`. System dark (`@media (prefers-color-scheme: dark)`) applies daisyUI semantic tokens via `:root` but does NOT activate `dark:` utilities. This is why system-dark is a genuinely different cascade worth testing.

### System-only CSS branch (the reason D-06 exists)
**Source:** `scrypath_ops/assets/css/app.css` lines 529–533 (not read in full but documented in RESEARCH.md)
```css
@media (prefers-color-scheme: dark) {
  html:not([data-theme="light"]) select.ops-form-control {
    background-image: url("data:image/svg+xml,...#a6adba...");
  }
}
```
This branch is unreachable by explicit `[data-theme=dark]` — a concrete example of why the system-dark row exists.

### `mkdir({ recursive: true })` before file writes
**Source:** `examples/scrypath_ecommerce/e2e/admin_screenshot_matrix.spec.ts` line 70
**Apply to:** `axeCheck()` before writing the contrast report; `contrast-checker.mjs` before writing JSON/MD output
```typescript
await mkdir(screenshotDir, { recursive: true });
```

### Makefile `## ` help convention
**Source:** `examples/scrypath_ecommerce/Makefile` lines 28–30
**Apply to:** All new `contrast` and `contrast-matrix` Makefile targets
```makefile
help: ## List targets
	@grep -hE '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	  | sort | awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'
```
Any target with `## <description>` after the colon appears in `make help` output. Both new targets must follow this convention.

### `$${VAR:-$(VAR)}` env override pattern
**Source:** `examples/scrypath_ecommerce/Makefile` lines 62–68
**Apply to:** `contrast` and `contrast-matrix` Makefile targets
```makefile
@ADMIN_SCREENSHOT_DIR=$${ADMIN_SCREENSHOT_DIR:-test-results/admin-screenshots} \
  PLAYWRIGHT_BASE_URL=http://127.0.0.1:$(WEB_PORT) \
  npm run test:e2e:admin-screens
```
`$${VAR:-default}` in a Makefile recipe: double `$` escapes Make's own `$` expansion; `:-` is shell default-value syntax. Allows `CONTRAST_REPORT_DIR=custom/path make contrast` overrides.

### D-21 write-before-exit pattern
**Source:** D-21 (locked decision)
**Apply to:** Both `axeCheck()` report writer and `contrast-checker.mjs` main function
```javascript
// ALWAYS write the report file BEFORE calling process.exit() or throwing
await writeFile(reportPath, reportContent);
// ONLY then decide exit
process.exit(report.summary.aa_fail > 0 ? 1 : 0);
```
If the report is written after exit, CI cannot read why it failed.

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `scrypath_ops/assets/css/contrast-pairs.mjs` | config | transform | First `.mjs` file in the `scrypath_ops/assets/css/` directory. The design-system sibling (`DESIGN-TOKENS.md`) is a markdown doc, not executable code. Structure is fully specified by D-11 and the muted-text grep of `app.css`. |

---

## Metadata

**Analog search scope:** `examples/scrypath_ecommerce/e2e/`, `examples/scrypath_ecommerce/`, `scrypath_ops/assets/css/`
**Files read:** 7 source files (`admin_screenshot_matrix.spec.ts`, `helpers/e2e.ts`, `Makefile`, `package.json`, `app.css` (lines 1–120 + targeted reads), `DESIGN-TOKENS.md`, CONTEXT.md, RESEARCH.md)
**Pattern extraction date:** 2026-06-04
