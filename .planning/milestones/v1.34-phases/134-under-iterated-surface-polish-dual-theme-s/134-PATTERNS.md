# Phase 134: Under-iterated surface polish (dual-theme) - Pattern Map

**Mapped:** 2026-06-25
**Files analyzed:** 6 (2 new, 4 modified)
**Analogs found:** 6 / 6 (every file has a same-role, same-data-flow in-repo analog)

> Hard phase constraint honored: **NO new tokens / components / hooks / keyframes.** Every
> excerpt below maps to an EXISTING analog. The two "new" files are a new Playwright spec and a
> new ExUnit value-contract test — both clone existing siblings in the same directory; they add
> verification, not design-system surface area.

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `examples/scrypath_ecommerce/e2e/admin_surface_depth.spec.ts` | test (e2e computed-style) | request-response / transform (read computed CSS) | `e2e/admin_path_motion.spec.ts` (probe idiom) + `e2e/admin_contrast_matrix.spec.ts` (theme grid + seed map) | exact (two complementary analogs) |
| `scrypath_ops/test/scrypath_ops_web/<token_tripwire>_test.exs` (NEW value-contract) | test (ExUnit static CSS contract) | file-I/O / transform (read `app.css`, regex literals) | `scrypath_ops/test/scrypath_ops_web/motion_contract_test.exs` | exact (same file-read + regex value-assertion shape) |
| `scrypath_ops/assets/css/app.css` (hover boost + DK-13) | config (CSS design tokens) | transform (theme cascade) | self — existing dark-only override blocks (`:1424-1441`, `:1495-1502`) | exact (extend established dual-path idiom) |
| `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` and/or `control_room_live.ex` (copper badge wiring, D-01) | component / template | request-response (render) | `ops_ui.ex` `ops_badge/1` (`:329-335`) + `.ops-copper-badge` CSS (`:499-503`) | role-match (compose existing class onto markup) |
| `examples/scrypath_ecommerce/package.json` (`test:e2e:admin-depth` script) | config (npm scripts) | n/a | existing `test:e2e:*` scripts (`:9-12`) | exact |

> **R3 note (from RESEARCH):** the token tripwire is a NEW value-assertion test, a SIBLING of
> `motion_contract_test.exs` — it is NOT an extension of `design_tokens_contract_test.exs` (that
> one is an orphan-checker, it asserts tokens *resolve*, not their *values*). Copy the
> motion-contract shape, not the orphan-checker shape.

---

## Pattern Assignments

### `examples/scrypath_ecommerce/e2e/admin_surface_depth.spec.ts` (NEW — e2e computed-style test)

**Primary analog:** `examples/scrypath_ecommerce/e2e/admin_path_motion.spec.ts` (probe idiom)
**Secondary analog:** `examples/scrypath_ecommerce/e2e/admin_contrast_matrix.spec.ts` (theme grid + seeds)

**Imports pattern** — clone from `admin_path_motion.spec.ts:38-47` and pull the theme/seed helpers
that `admin_contrast_matrix.spec.ts` already defines. The helpers module is the shared seed/wait API:
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

**Theme-grid pattern** — DO NOT re-author. The depth spec runs `{explicit-dark, system-dark}`
(light is covered by the pixel-diff gate). Reuse the EXACT discriminated-union + slug shape from
`admin_contrast_matrix.spec.ts:44-59` and the viewport map at `:63-68`:
```typescript
// admin_contrast_matrix.spec.ts:44-54 — copy THEME_MODES verbatim, then filter to dark + system
type ThemeMode =
  | { kind: "explicit"; theme: "light" | "dark" }
  | { kind: "system"; colorScheme: "dark" };
const THEME_MODES: ThemeMode[] = [
  { kind: "explicit", theme: "light" },
  { kind: "explicit", theme: "dark" },
  { kind: "system", colorScheme: "dark" }
];
// VIEWPORTS at :63-68 — mobile 390 (DK-13 border-alpha risk) + desktop 1440 (DK-16/18 coplanar)
```

**System-dark invariant pattern** — copy `assertSystemDarkInvariants` verbatim from
`admin_contrast_matrix.spec.ts:123-133` and call it first on every `system-dark` run (proves the
`@media (prefers-color-scheme: dark)` branch, not the explicit `data-theme` path):
```typescript
async function assertSystemDarkInvariants(page: Page): Promise<void> {
  await expect(page.locator("html")).not.toHaveAttribute("data-theme");
  const mediaMatches = await page.evaluate(
    () => window.matchMedia("(prefers-color-scheme: dark)").matches
  );
  expect(mediaMatches).toBe(true);
  await expect(page.locator("html")).toHaveAttribute("data-theme-effective", "dark");
}
```

**Themed-page builder pattern** — clone `admin_path_motion.spec.ts:70-92` `newThemedPage` (it
addInitScripts `phx:theme` before first paint for explicit themes, and opens
`colorScheme:'dark'` with NO key for system-dark). This is the canonical theme-application idiom.

**Computed-style probe pattern (THE core idiom)** — clone the `getComputedStyle` shape from
`admin_path_motion.spec.ts:204-216`. The glow constant + box-shadow read transfer directly to the
`.ops-object-item-active` glow assertion (D-11):
```typescript
// admin_path_motion.spec.ts:202-210
const GLOW_RGB = "108, 92, 231"; // getComputedStyle resolves rgba(108,92,231,…) with this triplet
async function glowBoxShadow(page: Page, selector: string): Promise<string> {
  return page.evaluate((sel) => {
    const el = document.querySelector(sel);
    if (!el) throw new Error(`glow probe: element not found for ${sel}`);
    return getComputedStyle(el).boxShadow;
  }, selector);
}
```
Generalize this one probe to also read `.backgroundColor` and `.borderColor` (D-11 needs all
three props). For the resting-vs-hover border delta, read the selector both at rest and after
`.hover()` — mirrors the hover read at `admin_path_motion.spec.ts:318-327`.

**Seed-scenario map** — reuse the EXACT index map from `admin_contrast_matrix.spec.ts:497-598`.
D-12's seed matrix is 1:1 with these existing captures:
| D-12 key | contrast-spec anchor | scenario | prepare |
|----------|---------------------|----------|---------|
| `06` search results | `:528-537` | `all_green` | `gotoSearch` + `runSearch("quantum")` + assert "Results" heading |
| `08` search zero-results | `:573-581` | `empty` | `gotoSearch` + `runSearch("nothingmatches…")` |
| `03` sync-drift drift | `:510` | `incident` | `gotoSyncDrift` (`:466-474` — note the "Load / refresh contract drift" click + "Contract dimensions" wait) |
| `09` playbooks empty-workspace | `:582-587` | `empty` | `gotoPlaybooks` |
| `12` playbooks populated | `:588-597` | `empty` | `gotoPlaybooks` — **R4: this prepare creates NO playbook; the depth spec MUST seed/create one before asserting populated depth** |

Copy the nav helpers `gotoControlRoom`/`gotoSearch`/`gotoSyncDrift`/`gotoPlaybooks`/`runSearch`
verbatim from `admin_contrast_matrix.spec.ts:446-491`.

**Per-test structure pattern** — clone the `for (const theme …) test(…)` + `newThemedPage` +
`try/finally { await close() }` shape from `admin_path_motion.spec.ts:227-268`. The
`seedScenario(request, "…")` call at the top of each test is the contrast/motion-spec seeding idiom.

**Assertions to author (from D-11; R2 corrections applied):**
- `.ops-result-row` / `.ops-data-card` `backgroundColor` === `rgb(27,34,48)` — exact-rgb OK (flat token, `app.css:1424/1434`).
- `.ops-muted-panel` / preflight cards — **luminance-delta / relative-step only, NOT exact rgb** (R2: these are `color-mix(...transparent)` fills). `.ops-preflight__card--locked` luminance **>** `.ops-preflight__card`.
- Every surface: sRGB rel-luminance exceeds `--ops-bg` `rgb(12,15,20)` floor by ≥ delta (start 0.015, tunable).
- `.ops-result-row:hover` AND `.ops-object-item:hover` `borderColor` resolves to `primary 55%` in dark AND differs from resting (proves D-12 on BOTH surfaces).
- `.ops-object-item-active` `boxShadow` contains `108, 92, 231` in dark, `none` in light (use `GLOW_RGB` probe).
- `.ops-copper-badge` on Control Room recommended card resolves to copper; **negative:** no `tone_class`/`badge_class` chip computes to copper (D-02).

---

### `scrypath_ops/test/scrypath_ops_web/<token_tripwire>_test.exs` (NEW — ExUnit value contract)

**Analog:** `scrypath_ops/test/scrypath_ops_web/motion_contract_test.exs` (NOT design_tokens_contract_test.exs — R3)

**Module + file-read scaffold pattern** (`motion_contract_test.exs:26-50`):
```elixir
use ExUnit.Case, async: true

@app_css Path.join(__DIR__, "../../assets/css/app.css") |> Path.expand()

defp css, do: File.read!(@app_css)
```

**Value-assertion (regex-literal) pattern** — this is the shape to copy for the D-13 tripwire
(orphan-checker does NOT do this; motion-contract does). Read `app.css`, regex the literal token
value, assert it matches. Author one `test`/`describe` block per pinned value:
```elixir
# Shape mirrors motion_contract_test.exs:60-77 (Regex.match? over css() + assert with message).
test "--ops-surface-2 stays #1b2230 (dark surface-2 elevation token)" do
  assert Regex.match?(~r/--ops-surface-2:\s*#1b2230/, css()),
         "Dark --ops-surface-2 token drifted from the locked #1b2230 surface-2 ramp value."
end

test "dark hover-border boost resolves to primary 55% on the paired row/item selector" do
  # asserts the D-15/D-16 dark-only override exists at primary 55% (not the 32% base)
  assert Regex.match?(~r/--color-primary\)\s*55%/, css()),
         "Dark hover-border boost (D-15/16) missing or not at primary 55%."
end
```
Pin per D-13: `--ops-surface-2: #1b2230`; raised-surface recipes reference the token; dark hover =
`primary 55%`. Runs automatically under `mix verify.opsui` (which is just `mix test` — see
`lib/mix/tasks/verify.opsui.ex`), exactly like the motion contract does.

---

### `scrypath_ops/assets/css/app.css` (MODIFY — hover boost + conditional DK-13)

**Analog:** the file's own existing dual-dark-path override blocks. Do not invent a new pattern.

**Both-themes dual-path idiom** (the hard invariant) — copy the shape from the EXISTING
`.ops-result-row` dark fill at `app.css:1433-1441`:
```css
/* app.css:1433-1441 — the canonical "dark-only override, BOTH paths" shape to clone */
[data-theme="dark"] .ops-result-row {
  background: var(--ops-surface-2);
}
@media (prefers-color-scheme: dark) {
  html:not([data-theme="light"]) .ops-result-row {
    background: var(--ops-surface-2);
  }
}
```

**Hover-border boost (D-15/D-16/DK-17)** — the base shared rule stays at `primary 32%`
(`app.css:979-983`, = light value + dark fallback). Add a dark-only override on the SAME paired
selector in BOTH dark paths lifting to `primary 55%`. Do NOT split the shared rule (re-introduces
DK-17 on Playbooks) and do NOT add a `--hover-border` var (no new tokens):
```css
/* base shared rule — UNCHANGED (app.css:979-983) */
.ops-result-row:hover,
.ops-object-item:hover {
  border-color: color-mix(in oklch, var(--color-primary) 32%, transparent);
  box-shadow: var(--shadow-ops-mid);
}
/* NEW dark-only override — author in BOTH paths, mirrors the :1433-1441 idiom */
[data-theme="dark"] .ops-result-row:hover,
[data-theme="dark"] .ops-object-item:hover {
  border-color: color-mix(in oklch, var(--color-primary) 55%, transparent);
}
@media (prefers-color-scheme: dark) {
  html:not([data-theme="light"]) .ops-result-row:hover,
  html:not([data-theme="light"]) .ops-object-item:hover {
    border-color: color-mix(in oklch, var(--color-primary) 55%, transparent);
  }
}
```

**DK-13 table-row border (D-08, CONDITIONAL on the 1.20:1 trigger)** — R1: there is NO existing
`.ops-*` table-row selector; the posture table is daisyUI `table table-sm table-zebra` emitted by
`ops_table` (`ops_ui.ex:135-138`). The leaf-scoped pattern (RESEARCH Open Q1) is to pass a
`table_class` (e.g. `ops-posture-table`) to `<.ops_table>` and scope a dark-only override to it,
reusing the SAME dual-path idiom above:
```css
/* Only if measured border↔surface contrast < 1.20:1 at dark 390. Both paths; light untouched. */
[data-theme="dark"] .ops-posture-table :where(td, th) {
  border-color: color-mix(in oklch, var(--color-base-content) 18%, transparent);
}
@media (prefers-color-scheme: dark) {
  html:not([data-theme="light"]) .ops-posture-table :where(td, th) {
    border-color: color-mix(in oklch, var(--color-base-content) 18%, transparent);
  }
}
```
(`ops_table` already accepts `@table_class` — `ops_ui.ex:138` — so no component-API change needed.)

---

### `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` / `control_room_live.ex` (MODIFY — copper badge, D-01)

**CSS analog (already shipped, just wire onto markup):** `.ops-copper-badge` at `app.css:499-503`
— theme-agnostic (consumes `--color-secondary`), AA pre-cleared (dark 12.07:1 / light 14.86:1),
text is `--color-base-content` NOT `--color-secondary` (D-03). No dual-path CSS needed.
```css
/* app.css:499-503 — compose with .ops-badge for layout; do NOT redefine */
.ops-copper-badge {
  border-color: color-mix(in oklch, var(--color-secondary) 44%, transparent);
  background:   color-mix(in oklch, var(--color-secondary) 12%, transparent);
  color: var(--color-base-content);
}
```

**Markup-composition analog:** the existing `ops_badge/1` shows the `class={["ops-badge", …, @class]}`
list-merge idiom (`ops_ui.ex:329-335`). D-01 wants `class="ops-badge ops-copper-badge"`:
```elixir
# ops_ui.ex:329-335 — the badge class-list pattern to follow when composing the copper badge
def ops_badge(assigns) do
  ~H"""
  <span class={["ops-badge", badge_class(@kind), @class]}>
    {render_slot(@inner_block)}
  </span>
  """
end
```

**Render site:** the recommended intent card is the incident card in `control_room_live.ex:92-101`
(`recommended={@posture.state in [:degraded, :missing_backend]}`, `data-testid="intent-incident"`).
`ops_intent_card/1` (`ops_ui.ex:496-516`) currently has NO badge slot — its template is fixed
(flag / icon / title / summary / cta). **Planning decision (executor's call, Claude's Discretion
in D / Open Q3):** either (a) add an optional badge slot to `ops_intent_card` rendered in the card
head, or (b) compose the `ops-badge ops-copper-badge` span in the LiveView near the card. Keep it a
genuine key fact on the scan path ("Federated" / key-scope callout). The negative D-02 assertion
(no `badge_class/1` status chip computes to copper) is guarded by the e2e spec, not by markup.

---

### `examples/scrypath_ecommerce/package.json` (MODIFY — npm script)

**Analog:** existing `test:e2e:*` scripts at `package.json:9-12`. Add one line in the same shape:
```json
"test:e2e:path-motion": "playwright test e2e/admin_path_motion.spec.ts",
"test:e2e:admin-contrast": "playwright test e2e/admin_contrast_matrix.spec.ts",
"test:e2e:admin-depth": "playwright test e2e/admin_surface_depth.spec.ts"
```

---

## Shared Patterns

### Both-themes dual-path authoring (HARD invariant — applies to ALL `app.css` edits this phase)
**Source:** `scrypath_ops/assets/css/app.css:1433-1441` (`.ops-result-row` dark fill)
**Apply to:** the hover boost (D-15/16) and the conditional DK-13 table border (D-08).
Every dark change is authored in BOTH `[data-theme="dark"] …` AND
`@media (prefers-color-scheme: dark) { html:not([data-theme="light"]) … }`. Light path untouched
(pixel-identical). The token tripwire + light-pixel-diff (threshold 0) guard against drift.

### Computed-style probe (deterministic, replaces subjective UAT — 0-human-UAT)
**Source:** `admin_path_motion.spec.ts:202-216` (`GLOW_RGB`, `glowBoxShadow`)
**Apply to:** every assertion in the new depth spec. Read `getComputedStyle(el).{backgroundColor,
borderColor,boxShadow}`; assert exact rgb only on flat-token surfaces, luminance-delta on
alpha-mixed (R2).

### Theme grid + system-dark invariants (do NOT re-author)
**Source:** `admin_contrast_matrix.spec.ts:44-68` (`THEME_MODES`, `VIEWPORTS`) + `:123-133`
(`assertSystemDarkInvariants`)
**Apply to:** the depth spec's run grid `{explicit-dark, system-dark} × {390, 1440}`.

### Static CSS value contract (file-read + regex literal)
**Source:** `motion_contract_test.exs:26-77`
**Apply to:** the new token-tripwire test (R3). NOT the orphan-checker shape.

### Seed-once-per-scenario + nav/wait helpers
**Source:** `admin_contrast_matrix.spec.ts:403-491` (`describeScenario` seeding +
`goto*`/`runSearch`) and `helpers/e2e` (`seedScenario`, `waitForLiveConnected`,
`waitForSearchVisible`, `drainSearchQueue`)
**Apply to:** the depth spec's per-scenario seeding. R4: the `populated` playbooks prepare creates
no playbook — the depth spec must seed/create one.

---

## No Analog Found

None. Every file maps to a same-role analog already in the repo. The only NET-NEW design surface
this phase touches is the wiring of the already-shipped `.ops-copper-badge` onto the intent-card
head (a class composition, not a new primitive) and an optional `ops_intent_card` badge slot — both
modeled on the existing `ops_badge/1` class-list idiom.

---

## Metadata

**Analog search scope:**
- `examples/scrypath_ecommerce/e2e/` (Playwright specs + `helpers/e2e.ts`, `package.json`)
- `scrypath_ops/test/scrypath_ops_web/` (ExUnit contract tests)
- `scrypath_ops/assets/css/app.css` (CSS tokens / dual-path overrides)
- `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` + `live/control_room_live.ex`

**Files scanned (read this session):** 8 — `admin_path_motion.spec.ts`,
`admin_contrast_matrix.spec.ts`, `package.json`, `design_tokens_contract_test.exs`,
`motion_contract_test.exs`, `app.css` (anchors), `ops_ui.ex` (anchors), `control_room_live.ex` (anchor).

**Pattern extraction date:** 2026-06-25
**Anchor validity:** matches RESEARCH live-verification (app.css 1542 lines); re-grep if line count shifts.
