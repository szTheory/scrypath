# Phase 135: Shell Chrome Polish (Dual-Theme) - Research

**Researched:** 2026-06-26
**Domain:** Phoenix LiveView shell chrome, Tailwind v4/daisyUI theming, WCAG AA contrast, Playwright browser verification
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
## Implementation Decisions

### 1. Light-change boundary
- **D-01:** Phase 135 is **dark-first and shell-only**. Keep light pixel-identical by default.
  Allow a light-theme change only when all of these are true: the target is explicitly shell chrome
  in this phase, the defect is objective (AA/state/focus/geometry), the change is local to shell
  selectors/components, and the planner records the rationale plus verification.
- **D-02:** Do **not** open a broad light-theme chrome redesign. v1.35 kept palette/type stable;
  Phase 134 restored light parity; reopening light aesthetics now would create milestone churn and
  blur Phase 136's final before/after evidence.
- **D-03:** If light pixels move, that is an explicit exception, not a silent pass. The plan/summary
  must say which selector moved, why it was necessary, and which gate recaptured or approved it.

### 2. Header/nav, brand mark, and shell wash
- **D-04:** Preserve the existing Phoenix structure: `ScrypathOpsWeb.Layouts.app/1` owns the ops
  shell, and `ScrypathOpsWeb.Nav.primary/1` owns the ordered primary navigation. No nav IA or shell
  variant restructuring is needed for SHELL-DARK-01.
- **D-05:** Active nav stays conventional and accessible: `aria-current="page"`, a text-bearing
  `--color-primary-strong` fill, and a restrained dark glow composed on top of existing surface lift.
  Do not use decorative gradients, pulsing, or extra path motion on ordinary nav items.
- **D-06:** The header should read as a seated, useful operator surface, not a hero bar. Use the
  existing dark ambient-shadow-plus-border recipe (`--shadow-ops-panel-dark` / overlay composition)
  where it improves separation, with both explicit dark and system-dark paths mirrored.
- **D-07:** The `.ops-shell` wash remains **one quiet top-left radial**. Tune dark/mobile strength down
  before it reads as a violet blob. No extra gradient layers, orbs, bokeh, noise, or decorative texture.
- **D-08:** Reconcile stale route-mark CSS with the v1.35 inline SVG brand mark if needed. The old
  `.ops-route-mark` selector should not remain the only proof target if no current element uses it.
  Either attach a small stable class to the inline mark or move proof to the live selector, without
  changing the brand identity.

### 3. Command palette, flash, and theme toggle
- **D-09:** Keep behavior mostly intact. The command palette remains the existing client-side
  `CommandPalette` hook; flash remains the framework-level flash component; theme preference remains
  root-script/localStorage driven. Do not redesign these into new public APIs or LiveComponents.
- **D-10:** Promote shell chrome to durable `.ops-*` selectors where useful for styling and proof:
  e.g. `ops-theme-toggle`, `ops-theme-toggle__pill`, `ops-theme-toggle__button`, and
  `ops-flash`/`ops-flash--info|error`, while preserving existing IDs used by JS and tests. This follows
  the local design-token law: reusable chrome gets component classes instead of brittle ID/utility
  styling.
- **D-11:** Minor semantic hardening is in scope when it makes an existing claim true without behavior
  redesign. Examples: selected theme buttons exposing accurate pressed/current state, command-palette
  active option state, close buttons with stable labels, and focus-return/focus-visible behavior if
  the browser proof finds a gap.
- **D-12:** If `role="dialog"` + `aria-modal="true"` stays on command palette / shortcut sheet, the
  implementation must not leave obvious modal-a11y debt unverified. Either prove enough focus behavior
  for the current bounded palette or downgrade the semantic claim to match actual behavior. Do not ship
  stronger ARIA than the UI actually honors.
- **D-13:** Flash styling should adopt the dark ambient-shadow-plus-border recipe and remain passive
  operator feedback. Do not make flashes bounce, glow, or steal focus. Keep `aria-live`/`role="alert"`
  semantics and text/icon pairing; color must not be the only signal.

### 4. Verification shape
- **D-14:** Add a focused browser proof for SHELL-DARK-01 rather than relying only on static contracts.
  Preferred shape: `examples/scrypath_ecommerce/e2e/admin_shell_chrome.spec.ts` plus an npm script such
  as `test:e2e:admin-shell`, reusing `helpers/theme-grid.ts`.
- **D-15:** The shell spec should cover `THEME_MODES` (`explicit-light`, `explicit-dark`, `system-dark`)
  and both mobile/desktop viewports for shared shell consistency. It should visit all six admin surfaces
  or use the existing scenario captures so header/nav/wash/chrome do not drift by route.
- **D-16:** The shell spec should explicitly exercise hidden/interactive chrome that contrast screenshots
  can miss: open/filter/empty/close command palette, shortcut sheet open/close, theme toggle system/light/dark
  transitions (`data-theme*`, localStorage, pill position, selected indicator), and at least one visible flash
  with computed shadow/border/background assertions.
- **D-17:** Use computed-style checks for shell visual contracts: header separation, nav active fill and
  dark glow, shell wash boundedness (prefer relative/computed checks over screenshot thresholds), command
  palette/flash overlay shadow composition, focus-ring visibility, and AA contrast via the existing axe
  matrix/contrast harness.
- **D-18:** Keep Phase 136 ownership intact. Do not move the full 40-shot recapture, v1.33->v1.34 gallery,
  milestone audit, or human UAT into Phase 135 unless Phase 136 is intentionally collapsed.

### 5. Design/JTBD principles for the planner
- **D-19:** Primary user persona is a Phoenix/Ecto operator or maintainer trying to answer, "Can I trust
  search right now, and where do I go next?" Shell chrome should orient, not decorate. The header/nav,
  palette, and flash are wayfinding aids around operational evidence.
- **D-20:** JTBD language: nouns are surfaces (`Control Room`, `Posture`, `Failed Sync`, `Sync Drift`,
  `Search`, `Playbooks`), events are navigation/theme/flash/palette interactions, verbs are jump,
  refresh, inspect, recover, explore, and close. Keep UI microcopy concrete and task-first.
- **D-21:** Design pillars to preserve: accessibility (AA hard gate, focus visible/not obscured),
  clarity (chrome never competes with evidence), consistency (same shell across six screens), performance
  (CSS/computed state, no heavy visual effects), resilience (system-dark and explicit-dark both covered),
  maintainability (named selectors and tokenized values), restraint (quiet glow, no dashboard-toy motion),
  and developer ergonomics (small components, stable tests, no new dependencies).

### the agent's Discretion
### Claude's Discretion
- Exact selector names may vary if they fit existing `.ops-*` vocabulary and avoid breaking JS hooks.
- Exact shell-wash alpha/extent values are left to implementation, but the final result must read quiet
  in dark mobile and desktop and must be backed by objective checks plus screenshot spot review.
- The focused shell browser spec may scope axe checks to the visible interactive chrome rather than rerun
  the whole contrast matrix inside every interaction, as long as the existing contrast gates remain part
  of the phase verification bundle.

### Deferred Ideas (OUT OF SCOPE)
## Deferred Ideas

- Broad light-theme shell redesign — defer to a future explicit light-theme or brand-token milestone if concrete evidence appears.
- Full command palette/combobox redesign or dependency adoption — defer unless focused Phase 135 browser proof shows the current bounded palette cannot honestly satisfy its ARIA/keyboard claims.
- New nav IA, shell variants, or operator productization — out of scope; current posture-first IA and six-screen route set are preserved.
- Full 40-shot recapture, v1.33->v1.34 before/after gallery, milestone audit, and human UAT — Phase 136 DUALVERIFY-01.
- HexDocs/website/README brand adoption follow-ups — v1.35 already handled live brand adoption; not Phase 135.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SHELL-DARK-01 | Shell chrome (header/nav, command palette, theme toggle, flash, `.ops-shell` radial violet wash) must be brand-expressive and AA-clean in both themes; weak header-nav dark contrast is fixed; palette/flash adopt the dark ambient-shadow-plus-border recipe. | Use `Layouts.app/1`, `Nav.primary/1`, `OpsUI.ops_command_palette/1`, `core_components.flash/1`, `app.css` shell selectors, existing contrast/depth/motion harnesses, and a new focused `admin_shell_chrome.spec.ts`. [VERIFIED: .planning/REQUIREMENTS.md][VERIFIED: codebase grep] |
</phase_requirements>

## Summary

Phase 135 should be planned as a small shared-shell polish phase, not a screen redesign. The operative files are `scrypath_ops/lib/scrypath_ops_web/components/layouts.ex`, `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex`, `scrypath_ops/lib/scrypath_ops_web/components/core_components.ex`, `scrypath_ops/assets/js/app.js`, and `scrypath_ops/assets/css/app.css`; those files already centralize header/nav/theme/flash/palette behavior and selectors. [VERIFIED: codebase grep]

The safest implementation path is to add durable `.ops-*` classes around shell chrome, tune dark-only and system-dark CSS for header/nav/wash/palette/flash, preserve existing IDs used by JS/tests, and keep light changes exception-only. [VERIFIED: .planning/phases/135-shell-chrome-polish-dual-theme-s/135-CONTEXT.md][VERIFIED: scrypath_ops/assets/css/DESIGN-TOKENS.md]

**Primary recommendation:** Plan one CSS/component pass plus one focused Playwright proof: `examples/scrypath_ecommerce/e2e/admin_shell_chrome.spec.ts`, reusing `THEME_MODES`, `VIEWPORTS`, and route helpers from `helpers/theme-grid.ts`, then run the existing contrast and ops UI gates. [VERIFIED: examples/scrypath_ecommerce/e2e/helpers/theme-grid.ts][VERIFIED: examples/scrypath_ecommerce/e2e/admin_contrast_matrix.spec.ts]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Header/nav chrome | Frontend Server (Phoenix LiveView HEEx components) | Browser/CSS | `Layouts.app/1` renders the header and `Nav.primary/1` owns ordered nav data; CSS owns visual state. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/components/layouts.ex][VERIFIED: scrypath_ops/lib/scrypath_ops_web/nav.ex] |
| `.ops-shell` wash | Browser/CSS | Frontend Server | The wash is a CSS background on `.ops-shell`; `Layouts.app/1` only provides the `main` element and class. [VERIFIED: scrypath_ops/assets/css/app.css][VERIFIED: scrypath_ops/lib/scrypath_ops_web/components/layouts.ex] |
| Command palette and shortcut sheet | Browser/Client | Frontend Server | `OpsUI.ops_command_palette/1` renders the DOM once; `CommandPalette` in `app.js` owns open/filter/active/close behavior. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex][VERIFIED: scrypath_ops/assets/js/app.js] |
| Theme preference toggle | Browser/Client | Frontend Server | Root script maps `localStorage["phx:theme"]`, `data-theme`, and `data-theme-*`; `Layouts.theme_toggle/1` dispatches `phx:set-theme`. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/components/layouts/root.html.heex][VERIFIED: scrypath_ops/lib/scrypath_ops_web/components/layouts.ex] |
| Flash/toast chrome | Frontend Server | Browser/CSS | `Layouts.flash_group/1` renders flash containers and `CoreComponents.flash/1`; CSS positions and styles `#flash-group`. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/components/layouts.ex][VERIFIED: scrypath_ops/lib/scrypath_ops_web/components/core_components.ex][VERIFIED: scrypath_ops/assets/css/app.css] |
| SHELL-DARK-01 proof | Browser automation | Static ExUnit contracts | Hidden interactive chrome and computed CSS require Playwright; static tests remain useful selector/token tripwires. [VERIFIED: examples/scrypath_ecommerce/e2e/admin_surface_depth.spec.ts][VERIFIED: scrypath_ops/test/scrypath_ops_web/ops_shell_contract_test.exs] |

## Project Constraints (from AGENTS.md)

- Root project is an Elixir OSS library with Ecto-first APIs and Phoenix-friendly integrations; this phase must not add runtime search-library scope. [VERIFIED: AGENTS.md]
- Public v1 backend target remains Meilisearch first with internal adapter seam; Phase 135 should not introduce backend abstraction work. [VERIFIED: AGENTS.md]
- `scrypath_ops/AGENTS.md` requires `mix precommit` when done with all changes in the Phoenix app. [VERIFIED: scrypath_ops/AGENTS.md]
- Phoenix templates must use `<Layouts.app flash={@flash} ...>` and `<.flash_group>` is forbidden outside `layouts.ex`. [VERIFIED: scrypath_ops/AGENTS.md]
- Use the imported `<.icon>` component for Heroicons; do not call Heroicons modules directly. [VERIFIED: scrypath_ops/AGENTS.md]
- Tailwind v4 import syntax in `app.css` must be preserved: `@import "tailwindcss" source(none);` plus `@source` entries. [VERIFIED: scrypath_ops/AGENTS.md][VERIFIED: scrypath_ops/assets/css/app.css]
- Do not use `@apply`; hand-write Tailwind/CSS rules and keep daisyUI classnames unprefixed. [VERIFIED: scrypath_ops/AGENTS.md][VERIFIED: scrypath_ops/assets/css/DESIGN-TOKENS.md]
- Do not write inline custom scripts in templates; existing root theme script is established, but new behavior should stay in `assets/js/app.js` or LiveView JS commands if needed. [VERIFIED: scrypath_ops/AGENTS.md][VERIFIED: scrypath_ops/assets/js/app.js]
- LiveView tests should use `Phoenix.LiveViewTest`, `LazyHTML`, `element/2`, and `has_element?/2` rather than raw HTML snapshots when interaction is under test. [VERIFIED: scrypath_ops/AGENTS.md]
- Existing untracked generated artifacts are present in the worktree; planners/executors must not clean or commit unrelated artifacts while touching Phase 135. [VERIFIED: git status]

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix | locked `1.8.7`; latest Hex `1.8.8` as of 2026-06-26 | Phoenix app/layout/component foundation for ScrypathOps | Existing app is Phoenix-generated and uses Phoenix 1.8 layout/component conventions. [VERIFIED: scrypath_ops/mix.lock][VERIFIED: mix hex.info] |
| Phoenix LiveView | locked `1.1.31`; latest Hex `1.2.3` as of 2026-06-26 | HEEx components, JS commands, `phx-hook` shell behavior | Existing app uses LiveView components and hooks; keep version locked for polish phase. [VERIFIED: scrypath_ops/mix.lock][VERIFIED: mix hex.info][CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html] |
| Tailwind CSS | configured `4.1.12` through Phoenix `tailwind` Hex `0.4.1` | Tokenized CSS build and Tailwind v4 directives | Existing `app.css` uses Tailwind v4 `@import`, `@source`, `@theme`, and `@custom-variant`. [VERIFIED: scrypath_ops/config/config.exs][VERIFIED: scrypath_ops/assets/css/app.css][CITED: https://tailwindcss.com/docs/functions-and-directives] |
| daisyUI | vendored `5.0.35` | Semantic theme tokens and component classes | Existing themes are authored via vendored daisyUI plugin/theme bundles and custom theme maps. [VERIFIED: scrypath_ops/assets/vendor/daisyui.js][VERIFIED: scrypath_ops/assets/css/app.css][CITED: https://daisyui.com/docs/themes/] |
| `@playwright/test` | package-lock `1.60.0`; package.json range `^1.54.2`; latest npm `1.61.1` as of 2026-06-26 | Browser proof for theme modes, viewport states, hidden chrome | Existing e2e suite uses Playwright; no upgrade needed for this phase. [VERIFIED: examples/scrypath_ecommerce/package-lock.json][VERIFIED: npm view][CITED: https://playwright.dev/docs/api/class-browsercontext] |
| `@axe-core/playwright` | package.json `^4.11.3`, package-lock `4.11.3`; latest npm `4.12.1` as of 2026-06-26 | Browser-level WCAG contrast/a11y checks | Existing contrast matrix already uses `AxeBuilder` after preparing each screen. [VERIFIED: examples/scrypath_ecommerce/package.json][VERIFIED: examples/scrypath_ecommerce/package-lock.json][VERIFIED: npm view][CITED: https://playwright.dev/docs/accessibility-testing] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Heroicons Hex package | locked `0.5.7` | Icons through `<.icon>` without npm assets | Use for theme-toggle and flash icons; do not call `Heroicons` modules directly. [VERIFIED: scrypath_ops/mix.lock][VERIFIED: scrypath_ops/AGENTS.md] |
| LazyHTML | locked `0.1.11` | LiveView test DOM selectors | Use only for ExUnit DOM inspection; shell interactions belong in Playwright. [VERIFIED: scrypath_ops/mix.lock][VERIFIED: scrypath_ops/AGENTS.md] |
| Existing contrast checker | repo-local `make contrast` / `contrast-pairs.mjs` | Fast token/selector contrast lockstep | Extend only if new muted text or tracked contrast selectors are introduced. [VERIFIED: scrypath_ops/assets/css/contrast-pairs.mjs][VERIFIED: examples/scrypath_ecommerce/package.json] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Existing `CommandPalette` hook | Full combobox/dialog dependency | Out of scope and risks dependency/API churn; only revisit if browser proof shows current semantics cannot honestly be supported. [VERIFIED: 135-CONTEXT.md] |
| Existing Playwright + axe suite | Screenshot-only or manual-only review | Screenshot review cannot open hidden palette/theme/flash states or assert computed CSS; Playwright can. [VERIFIED: examples/scrypath_ecommerce/e2e/admin_contrast_matrix.spec.ts][CITED: https://playwright.dev/docs/accessibility-testing] |
| Existing daisyUI/Tailwind tokens | New design-system library | Contradicts local token law and risks light-theme churn. [VERIFIED: scrypath_ops/assets/css/DESIGN-TOKENS.md] |

**Installation:**
```bash
# No new package installation is recommended for Phase 135.
# Reuse existing package-lock and mix.lock dependencies.
```

**Version verification performed:**
```bash
cd scrypath_ops && mix hex.info phoenix
cd scrypath_ops && mix hex.info phoenix_live_view
cd scrypath_ops && mix hex.info tailwind
cd examples/scrypath_ecommerce && npm ls @playwright/test @axe-core/playwright --depth=0
npm view @playwright/test version
npm view @axe-core/playwright version
```

## Package Legitimacy Audit

No new external package should be installed in Phase 135. [VERIFIED: 135-CONTEXT.md]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| `@playwright/test` | npm | locked `1.60.0` published 2026-05-11; latest `1.61.1` published 2026-06-23 | 41,891,083/wk reported by seam for package | github.com/microsoft/playwright | `SUS` from seam for latest release because "too-new" | Already locked and installed; do not upgrade/install in this phase. [VERIFIED: npm view][VERIFIED: package-legitimacy seam] |
| `@axe-core/playwright` | npm | locked `4.11.3` published 2026-04-30; latest `4.12.1` published 2026-06-23 | 5,048,139/wk reported by seam for package | github.com/dequelabs/axe-core-npm | `SUS` from seam for latest release because "too-new" | Already locked and installed; do not upgrade/install in this phase. [VERIFIED: npm view][VERIFIED: package-legitimacy seam] |

**Packages removed due to [SLOP] verdict:** none. [VERIFIED: package-legitimacy seam]
**Packages flagged as suspicious [SUS]:** latest `@playwright/test` and latest `@axe-core/playwright` were flagged by recency; planner should not add an install/upgrade task, and any intentional package change needs a human checkpoint. [VERIFIED: package-legitimacy seam]

## Architecture Patterns

### System Architecture Diagram

```text
Operator route (/admin/search/*)
  -> Phoenix LiveView route renders <Layouts.app shell={:ops}>
     -> Layouts.app/1 emits shared header/nav/theme/main/flash/palette shell
        -> app.css resolves light/dark/system-dark semantic tokens
        -> root theme script resolves phx:theme -> data-theme/data-theme-effective/data-theme-preference
        -> CommandPalette hook owns open/filter/active/close for hidden palette/sheet
        -> LiveView put_flash renders CoreComponents.flash through Layouts.flash_group
  -> Playwright shell spec visits every surface under theme modes + viewports
     -> computed styles + axe checks prove AA, state, and dark ambient recipes
```

### Recommended Project Structure

```text
scrypath_ops/
├── lib/scrypath_ops_web/components/layouts.ex          # header, nav, theme toggle, flash group
├── lib/scrypath_ops_web/components/ops_ui.ex           # command palette / shortcut sheet component
├── lib/scrypath_ops_web/components/core_components.ex  # flash component and show/hide JS commands
├── assets/js/app.js                                    # existing CommandPalette hook
├── assets/css/app.css                                  # shell chrome selectors and dual-dark CSS
└── assets/css/DESIGN-TOKENS.md                         # lockstep token documentation

examples/scrypath_ecommerce/
├── e2e/admin_shell_chrome.spec.ts                      # add focused SHELL-DARK-01 browser proof
├── e2e/helpers/theme-grid.ts                           # reuse theme modes, viewports, route helpers
└── package.json                                        # add test:e2e:admin-shell script only
```

### Pattern 1: Add Durable Shell Classes Without Breaking Existing IDs
**What:** Add `.ops-theme-toggle*` and `.ops-flash*` classes to existing markup while retaining `id="theme-toggle"`, `id="theme-toggle-pill"`, `id="flash-group"`, `id="ops-cmdk"`, and `id="ops-cheatsheet"`. [VERIFIED: 135-CONTEXT.md][VERIFIED: scrypath_ops/assets/js/app.js]
**When to use:** Use when styling/proof needs a durable selector but JS or tests already depend on an ID. [VERIFIED: scrypath_ops/assets/css/DESIGN-TOKENS.md]
**Example:**
```elixir
# Source: scrypath_ops/lib/scrypath_ops_web/components/layouts.ex
<div id="theme-toggle" class="ops-theme-toggle ..." role="group" aria-label="Theme preference">
  <div id="theme-toggle-pill" class="ops-theme-toggle__pill ..." />
  <button class="ops-theme-toggle__button" data-phx-theme="dark" aria-label="Use dark theme">
    <.icon name="hero-moon-micro" class="size-4" />
  </button>
</div>
```

### Pattern 2: Mirror Every Dark-Only Shell Rule
**What:** Author dark-only chrome changes in both explicit `[data-theme="dark"]` and system-dark `@media (prefers-color-scheme: dark) html:not([data-theme="light"])` paths. [VERIFIED: scrypath_ops/assets/css/app.css][VERIFIED: scrypath_ops/assets/css/DESIGN-TOKENS.md]
**When to use:** Use for shell rules that rely on custom tokens like `--shadow-ops-panel-dark` or route-specific box-shadow composition. [VERIFIED: scrypath_ops/assets/css/app.css]
**Example:**
```css
/* Source: scrypath_ops/assets/css/app.css */
[data-theme="dark"] .ops-header {
  box-shadow: var(--shadow-ops-panel-dark);
}

@media (prefers-color-scheme: dark) {
  html:not([data-theme="light"]) .ops-header {
    box-shadow: var(--shadow-ops-panel-dark);
  }
}
```

### Pattern 3: Browser Proof Opens Hidden Chrome Before Checking It
**What:** Use Playwright to open the command palette, filter to empty state, open the shortcut sheet, trigger theme states, and create at least one flash before computed-style/axe checks. [VERIFIED: 135-CONTEXT.md][CITED: https://playwright.dev/docs/accessibility-testing]
**When to use:** Use for UI that is hidden by default or stateful in the browser. [VERIFIED: scrypath_ops/assets/js/app.js]
**Example:**
```typescript
// Source: examples/scrypath_ecommerce/e2e/admin_shell_chrome.spec.ts (recommended)
await page.keyboard.press(process.platform === "darwin" ? "Meta+K" : "Control+K");
await expect(page.locator("#ops-cmdk")).toBeVisible();
await page.locator("[data-cmdk-input]").fill("zzzz-no-match");
await expect(page.locator("[data-cmdk-empty]")).toBeVisible();
```

### Anti-Patterns to Avoid
- **Broad light redesign:** Light changes are exception-only and must be documented with selector/rationale/gate. [VERIFIED: 135-CONTEXT.md]
- **Replacing composed shadows:** Do not set `box-shadow: var(--shadow-ops-panel-dark)` on overlays that already carry `--shadow-ops-overlay`; compose layers instead. [VERIFIED: scrypath_ops/assets/css/app.css]
- **Only testing explicit dark:** System-dark is a distinct cascade because `data-theme` is absent and daisyUI `prefersdark` applies. [VERIFIED: scrypath_ops/assets/css/app.css][VERIFIED: examples/scrypath_ecommerce/e2e/helpers/theme-grid.ts][CITED: https://daisyui.com/docs/themes/]
- **ARIA overclaim:** Do not leave `aria-modal="true"` on palette/sheet if focus/inert behavior is not defensible. [VERIFIED: 135-CONTEXT.md][CITED: https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/]
- **New dependency for palette polish:** Dependency adoption is explicitly deferred unless proof shows current bounded palette cannot satisfy its claims. [VERIFIED: 135-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| WCAG AA contrast verification | Custom visual judgement or one-off contrast scripts for browser states | Existing `make contrast`, `admin_contrast_matrix.spec.ts`, `AxeBuilder` | Existing harness already reports AA failures and system-dark parity; axe is the browser-level authority for rendered contrast. [VERIFIED: examples/scrypath_ecommerce/e2e/admin_contrast_matrix.spec.ts][CITED: https://playwright.dev/docs/accessibility-testing] |
| Theme-mode matrix | Ad hoc localStorage setup in each test | `THEME_MODES`, `VIEWPORTS`, `assertSystemDarkInvariants` from `helpers/theme-grid.ts` | Existing helper avoids races and distinguishes explicit-dark from system-dark. [VERIFIED: examples/scrypath_ecommerce/e2e/helpers/theme-grid.ts] |
| Command palette behavior | New LiveComponent or dependency | Existing `CommandPalette` hook and `OpsUI.ops_command_palette/1` | Behavior is already client-owned, rendered once globally, and route links are ordinary LiveView navigation. [VERIFIED: scrypath_ops/assets/js/app.js][VERIFIED: scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex] |
| Focus/keyboard proof | Static HTML grep only | Playwright interaction checks plus existing LiveView contract tests | Static tests cannot prove focus return, active option state, or hidden dialog semantics. [VERIFIED: scrypath_ops/test/scrypath_ops_web/ops_shell_contract_test.exs][CITED: https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/] |
| Token discipline | Raw Tailwind steps or `@apply` | `.ops-*` component classes and existing `-ops-` tokens | Local token law requires durable chrome classes for reusable shell controls. [VERIFIED: scrypath_ops/assets/css/DESIGN-TOKENS.md][VERIFIED: scrypath_ops/AGENTS.md] |

**Key insight:** The hard part is not inventing new UI; it is proving the already-shared shell reads correctly in explicit light, explicit dark, and system-dark while hidden chrome is open. [VERIFIED: 135-CONTEXT.md][VERIFIED: examples/scrypath_ecommerce/e2e/helpers/theme-grid.ts]

## Common Pitfalls

### Pitfall 1: Light Churn From Shared Selectors
**What goes wrong:** A shell selector such as `.ops-shell`, `.ops-header`, `.ops-cmdk__panel`, or `#flash-group > *` changes light pixels while trying to fix dark. [VERIFIED: 135-CONTEXT.md]
**Why it happens:** Base rules apply to both themes unless overridden in dark-only paths. [VERIFIED: scrypath_ops/assets/css/app.css]
**How to avoid:** Prefer dark-only explicit/system mirrors for visual-depth changes; document any light exception. [VERIFIED: 135-CONTEXT.md]
**Warning signs:** Light pixel-diff changes with no selector-specific rationale. [VERIFIED: examples/scrypath_ecommerce/e2e/light-pixel-diff.mjs]

### Pitfall 2: Explicit-Dark Pass, System-Dark Fail
**What goes wrong:** `[data-theme="dark"]` looks correct but OS/system dark remains flat or low contrast. [VERIFIED: examples/scrypath_ecommerce/e2e/helpers/theme-grid.ts]
**Why it happens:** System-dark has no `data-theme` attr and depends on `prefers-color-scheme`. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/components/layouts/root.html.heex][CITED: https://daisyui.com/docs/themes/]
**How to avoid:** Use `THEME_MODES` and dual CSS paths for custom dark overrides. [VERIFIED: examples/scrypath_ecommerce/e2e/helpers/theme-grid.ts]
**Warning signs:** Tests set `localStorage["phx:theme"]="dark"` for every dark row. [VERIFIED: examples/scrypath_ecommerce/e2e/admin_contrast_matrix.spec.ts]

### Pitfall 3: Shadow Composition Erases Existing Depth
**What goes wrong:** Overlay panels or nav pills lose their original lift when dark ambient shadow is applied. [VERIFIED: scrypath_ops/assets/css/app.css]
**Why it happens:** CSS `box-shadow` is a full replacement, not an additive property. [VERIFIED: scrypath_ops/assets/css/app.css]
**How to avoid:** Keep existing overlay/surface layer first, then append `var(--shadow-ops-panel-dark)` or `var(--shadow-ops-glow)`. [VERIFIED: scrypath_ops/assets/css/app.css][VERIFIED: scrypath_ops/assets/css/DESIGN-TOKENS.md]
**Warning signs:** `box-shadow: var(--shadow-ops-glow)` appears alone on `.ops-nav-item-active`, `.ops-cmdk__panel`, or flash. [VERIFIED: scrypath_ops/assets/css/app.css]

### Pitfall 4: Stale `.ops-route-mark` Proof
**What goes wrong:** Tests prove a selector that no current element renders after the v1.35 inline SVG brand adoption. [VERIFIED: 135-CONTEXT.md][VERIFIED: scrypath_ops/lib/scrypath_ops_web/components/layouts.ex]
**Why it happens:** `.ops-route-mark` CSS still exists, but the current brand mark is inline SVG with no class by default. [VERIFIED: scrypath_ops/assets/css/app.css][VERIFIED: scrypath_ops/lib/scrypath_ops_web/components/layouts.ex]
**How to avoid:** Attach a stable class to the live inline mark or point proof at the live SVG selector without changing identity. [VERIFIED: 135-CONTEXT.md]
**Warning signs:** Browser assertions pass with zero matched live brand elements. [VERIFIED: codebase grep]

### Pitfall 5: Dialog Semantics Without Dialog Behavior
**What goes wrong:** Palette/sheet claim `role="dialog"` + `aria-modal="true"` but focus can escape or return behavior is untested. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex][CITED: https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/]
**Why it happens:** The current hook opens/focuses the input and closes on Escape, but does not currently show a complete focus trap in the inspected code. [VERIFIED: scrypath_ops/assets/js/app.js]
**How to avoid:** Either prove bounded focus behavior and focus return or reduce the semantic claim. [VERIFIED: 135-CONTEXT.md]
**Warning signs:** Axe passes but keyboard Tab can move behind the open palette. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/]

### Pitfall 6: Running Browser Proof Against a Stale Server
**What goes wrong:** Playwright tests pass/fail against an old baked app image instead of current source. [VERIFIED: .planning/STATE.md][VERIFIED: examples/scrypath_ecommerce/e2e/admin_path_motion.spec.ts]
**Why it happens:** The ecommerce path dependency does not live-reload ops BEAM edits mid-run; the dev server needs restart after ops code changes. [VERIFIED: .planning/STATE.md]
**How to avoid:** Rebuild ops assets and boot a source Phoenix server before the shell spec. [VERIFIED: examples/scrypath_ecommerce/e2e/admin_path_motion.spec.ts]
**Warning signs:** CSS file changes are absent from computed styles in Playwright. [VERIFIED: examples/scrypath_ecommerce/e2e/admin_surface_depth.spec.ts]

## Code Examples

Verified patterns from official and local sources:

### Theme Context Helper
```typescript
// Source: examples/scrypath_ecommerce/e2e/helpers/theme-grid.ts
export const THEME_MODES = [
  { kind: "explicit", theme: "light" },
  { kind: "explicit", theme: "dark" },
  { kind: "system", colorScheme: "dark" }
];
```

### Browser Context Setup
```typescript
// Source: examples/scrypath_ecommerce/e2e/admin_surface_depth.spec.ts
const context = await browser.newContext({
  viewport: VIEWPORTS[viewport],
  ...(mode.kind === "system" ? { colorScheme: mode.colorScheme as "dark" } : {})
});

if (mode.kind === "explicit") {
  await context.addInitScript(([key, value]) => {
    window.localStorage.setItem(key, value);
  }, ["phx:theme", mode.theme]);
}
```

### Composed Dark Overlay Shadow
```css
/* Source: scrypath_ops/assets/css/app.css */
[data-theme="dark"] #flash-group > *,
[data-theme="dark"] .ops-cmdk__panel {
  box-shadow: var(--shadow-ops-overlay), var(--shadow-ops-panel-dark);
}

@media (prefers-color-scheme: dark) {
  html:not([data-theme="light"]) #flash-group > *,
  html:not([data-theme="light"]) .ops-cmdk__panel {
    box-shadow: var(--shadow-ops-overlay), var(--shadow-ops-panel-dark);
  }
}
```

### Focused Axe Pattern After Interaction
```typescript
// Source: Playwright accessibility docs pattern + existing admin_contrast_matrix.spec.ts
await page.keyboard.press(process.platform === "darwin" ? "Meta+K" : "Control+K");
await expect(page.locator("#ops-cmdk")).toBeVisible();

const results = await new AxeBuilder({ page })
  .include("#ops-cmdk")
  .withRules(["color-contrast"])
  .analyze();

expect(results.violations).toEqual([]);
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Static shell grep only | Browser-state proof for hidden chrome and computed CSS | Phase 135 planning target | Planner should add `admin_shell_chrome.spec.ts`; existing static tests stay as tripwires. [VERIFIED: 135-CONTEXT.md] |
| One dark mode path | Explicit-dark + system-dark matrix | Phase 128+ harness | Every dark visual change must cover both paths. [VERIFIED: examples/scrypath_ecommerce/e2e/helpers/theme-grid.ts] |
| Raw muted alpha selectors | Named `--ops-text-muted` plus manifest lockstep | Phase 132 | New muted shell text must update `contrast-pairs.mjs` or avoid new raw mixes. [VERIFIED: scrypath_ops/assets/css/contrast-pairs.mjs][VERIFIED: scrypath_ops/assets/css/DESIGN-TOKENS.md] |
| Generic caged mark proof | v1.35 inline SVG brand mark | v1.35 brand adoption | `.ops-route-mark` is no longer sufficient as the only brand-mark proof target. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/components/layouts.ex][VERIFIED: 135-CONTEXT.md] |
| Full gallery in every polish phase | Focused proof now, full 40-shot gallery in Phase 136 | Phase 133+ precedent | Keeps Phase 135 small and preserves DUALVERIFY-01 ownership. [VERIFIED: examples/scrypath_ecommerce/e2e/admin_path_motion.spec.ts][VERIFIED: 135-CONTEXT.md] |

**Deprecated/outdated:**
- Testing only `.ops-route-mark` for brand chrome is outdated because current `brand_mark/1` renders inline SVG paths without that class. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/components/layouts.ex][VERIFIED: scrypath_ops/assets/css/app.css]
- Installing/upgrading Playwright or axe during this phase is unnecessary and was flagged as risky by package-legitimacy recency checks. [VERIFIED: package-legitimacy seam]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | All implementation work can fit without new external packages. [ASSUMED] | Standard Stack | If focused browser proof reveals a hard ARIA gap in the current palette, planner may need a human decision on whether to downgrade semantics or adopt a dependency. |

## Open Questions

1. **Should the command palette keep `aria-modal="true"`?**
   - What we know: Current markup uses `role="dialog"` and `aria-modal="true"`; current hook opens/focuses input and closes on Escape. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex][VERIFIED: scrypath_ops/assets/js/app.js]
   - What's unclear: Whether Tab focus containment and focus return meet the semantic claim. [VERIFIED: 135-CONTEXT.md]
   - Recommendation: Make the browser spec answer this before finalizing markup; either prove bounded behavior or reduce the semantic claim. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/]

2. **Should static shell CSS tripwires be added to `mix verify.opsui`?**
   - What we know: Static token/motion/depth contracts already exist and are cheap. [VERIFIED: scrypath_ops/test/scrypath_ops_web/design_tokens_contract_test.exs][VERIFIED: scrypath_ops/test/scrypath_ops_web/motion_contract_test.exs][VERIFIED: scrypath_ops/test/scrypath_ops_web/surface_depth_token_contract_test.exs]
   - What's unclear: Whether shell-specific CSS rules will be complex enough to justify another regex test. [VERIFIED: codebase grep]
   - Recommendation: Add static checks only for durable invariants that are easy to express, such as dual-dark mirror presence or required shell classes. [VERIFIED: codebase grep]

3. **How much wash tuning is enough?**
   - What we know: `.ops-shell` currently uses one top-left radial with 14% alpha/34rem base and 10%/28rem mobile. [VERIFIED: scrypath_ops/assets/css/app.css]
   - What's unclear: Whether dark desktop still reads too blob-like after Phase 131 mobile tuning. [VERIFIED: 129-DARK-AUDIT-BACKLOG.md]
   - Recommendation: Use computed/background-string checks to prevent extra layers, plus screenshot spot review for the subjective "quiet ambient glow" read. [VERIFIED: 135-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | ScrypathOps tests/build | yes | 1.19.5 | none needed. [VERIFIED: local command] |
| Erlang/OTP | ScrypathOps tests/build | yes | 28 / ERTS 16.3 | none needed. [VERIFIED: local command] |
| Mix | `mix verify.opsui`, assets build | yes | 1.19.5 | none needed. [VERIFIED: local command] |
| Node.js | Playwright/contrast tools | yes | v22.14.0 | none needed. [VERIFIED: local command] |
| npm | e2e scripts | yes | 11.1.0 | none needed. [VERIFIED: local command] |
| Docker CLI | ecommerce dev lane services | yes | 29.5.2 | Use existing local Postgres/Meilisearch only if already configured. [VERIFIED: local command] |
| PostgreSQL default port | local tests | yes | `pg_isready` reports accepting connections on `/tmp:5432` | Docker compose lane can use alternate ports if needed. [VERIFIED: local command] |
| Playwright CLI | shell browser spec | yes | 1.60.0 installed in e2e app | Do not upgrade in this phase. [VERIFIED: npm ls] |
| `@axe-core/playwright` | contrast/a11y checks | yes | 4.11.3 installed in e2e app | Existing contrast matrix already uses it. [VERIFIED: npm ls] |
| `ctx7` | Context7 docs fallback | no | - | Official docs were fetched directly and cited. [VERIFIED: local command] |

**Missing dependencies with no fallback:** none identified for planning. [VERIFIED: local command]

**Missing dependencies with fallback:**
- `ctx7` is missing; direct official docs were used for research citations. [VERIFIED: local command]
- A running source Phoenix server was not assumed; browser proof plans must boot/restart it before running Playwright. [VERIFIED: examples/scrypath_ecommerce/playwright.config.ts][VERIFIED: examples/scrypath_ecommerce/e2e/admin_path_motion.spec.ts]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit/Phoenix LiveViewTest for static/semantic contracts; Playwright `1.60.0` + `@axe-core/playwright` `4.11.3` for browser proof. [VERIFIED: scrypath_ops/mix.lock][VERIFIED: npm ls] |
| Config file | `examples/scrypath_ecommerce/playwright.config.ts`; ExUnit config through Mix. [VERIFIED: examples/scrypath_ecommerce/playwright.config.ts][VERIFIED: scrypath_ops/mix.exs] |
| Quick run command | `cd scrypath_ops && mix test test/scrypath_ops_web/ops_shell_contract_test.exs test/scrypath_ops_web/ops_a11y_contract_test.exs` [VERIFIED: codebase grep] |
| Full suite command | `cd scrypath_ops && mix verify.opsui`; plus after server boot: `cd examples/scrypath_ecommerce && npm run test:e2e:admin-shell -- --reporter=line && npm run test:e2e:admin-contrast -- --reporter=line` [VERIFIED: scrypath_ops/mix.exs][VERIFIED: examples/scrypath_ecommerce/package.json] |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| SHELL-DARK-01 | Header/nav contrast, active nav fill/glow, seated header separation, quiet `.ops-shell` wash in light/dark/system-dark. | browser/computed-style + axe | `cd examples/scrypath_ecommerce && npm run test:e2e:admin-shell -- --reporter=line` | no - Wave 0 creates `e2e/admin_shell_chrome.spec.ts`. [VERIFIED: 135-CONTEXT.md] |
| SHELL-DARK-01 | Command palette and shortcut sheet open/filter/empty/close states, focus visibility, and honest dialog semantics. | browser interaction/a11y | `cd examples/scrypath_ecommerce && npm run test:e2e:admin-shell -- --reporter=line` | no - Wave 0. [VERIFIED: 135-CONTEXT.md] |
| SHELL-DARK-01 | Theme toggle system/light/dark transitions update `data-theme*`, localStorage, selected state, and pill position. | browser interaction/computed-style | `cd examples/scrypath_ecommerce && npm run test:e2e:admin-shell -- --reporter=line` | no - Wave 0. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/components/layouts/root.html.heex] |
| SHELL-DARK-01 | Flash adopts dark ambient-shadow-plus-border recipe and keeps role/text/icon signal. | LiveView/Playwright | `cd examples/scrypath_ecommerce && npm run test:e2e:admin-shell -- --reporter=line` | no - Wave 0; flash component exists. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/components/core_components.ex] |
| SHELL-DARK-01 | AA remains green in both themes across shell surfaces. | browser axe/contrast | `cd examples/scrypath_ecommerce && npm run test:e2e:admin-contrast -- --reporter=line` and `make contrast` | yes. [VERIFIED: examples/scrypath_ecommerce/e2e/admin_contrast_matrix.spec.ts] |

### Sampling Rate
- **Per task commit:** Run targeted ExUnit tests for touched components and, for CSS/browser-touching tasks, run the new shell spec against a booted source server. [VERIFIED: scrypath_ops/mix.exs][VERIFIED: 135-CONTEXT.md]
- **Per wave merge:** Run `cd scrypath_ops && mix verify.opsui`, `cd examples/scrypath_ecommerce && make contrast`, and the shell spec. [VERIFIED: scrypath_ops/mix.exs][VERIFIED: examples/scrypath_ecommerce/package.json]
- **Phase gate:** Full shell spec, existing contrast matrix, and `mix verify.opsui` green before `$gsd-verify-work`. [VERIFIED: 135-CONTEXT.md]

### Wave 0 Gaps
- [ ] `examples/scrypath_ecommerce/e2e/admin_shell_chrome.spec.ts` - covers SHELL-DARK-01 hidden chrome, shell computed styles, and theme state transitions. [VERIFIED: 135-CONTEXT.md]
- [ ] `examples/scrypath_ecommerce/package.json` script `test:e2e:admin-shell` - runs the focused shell spec. [VERIFIED: 135-CONTEXT.md]
- [ ] Optional static contract additions in `scrypath_ops/test/scrypath_ops_web/ops_shell_contract_test.exs` or a new CSS contract test - only if new `.ops-*` shell classes need cheap tripwires. [VERIFIED: codebase grep]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | No auth/session boundary changes in this shell polish phase; keep existing route/auth posture unchanged. [VERIFIED: 135-CONTEXT.md] |
| V3 Session Management | no | Theme preference uses localStorage only for non-sensitive display preference. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/components/layouts/root.html.heex] |
| V4 Access Control | no | No new operator routes or actions should be added. [VERIFIED: 135-CONTEXT.md] |
| V5 Input Validation | yes | Command palette filter is client-only; theme events must stay constrained to controlled `data-phx-theme` values. [VERIFIED: scrypath_ops/assets/js/app.js][VERIFIED: scrypath_ops/lib/scrypath_ops_web/components/layouts.ex] |
| V6 Cryptography | no | No crypto or secret handling is touched. [VERIFIED: 135-CONTEXT.md] |

### Known Threat Patterns for Phoenix LiveView Shell Chrome

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| DOM/event overreach from new hooks | Tampering | Reuse existing `CommandPalette` hook; do not add new hooks unless proof requires it; preserve unique IDs. [VERIFIED: 135-CONTEXT.md][VERIFIED: scrypath_ops/AGENTS.md] |
| XSS through dynamic shell labels | Elevation of Privilege | Keep nav/palette labels as server-defined literals from `Nav.primary/1`; do not inject untrusted HTML. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/nav.ex][VERIFIED: scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex] |
| Misleading accessibility state | Spoofing/Repudiation | Match ARIA state to actual behavior, especially `aria-modal`, active option, and theme selected state. [VERIFIED: 135-CONTEXT.md][CITED: https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/] |
| Color-only status meaning in flash | Information Disclosure/Usability risk | Preserve role/text/icon pairings; color is not the only signal. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/components/core_components.ex][CITED: https://www.w3.org/WAI/WCAG21/Understanding/non-text-contrast.html] |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/135-shell-chrome-polish-dual-theme-s/135-CONTEXT.md` - locked phase scope, decisions, and verification shape. [VERIFIED: codebase grep]
- `.planning/REQUIREMENTS.md` - SHELL-DARK-01 requirement. [VERIFIED: codebase grep]
- `.planning/STATE.md` - v1.34/v1.35 state, server restart note, Phase 134 outcome. [VERIFIED: codebase grep]
- `scrypath_ops/AGENTS.md` and root `AGENTS.md` - Phoenix/Tailwind/project rules. [VERIFIED: codebase grep]
- `scrypath_ops/lib/scrypath_ops_web/components/layouts.ex`, `ops_ui.ex`, `core_components.ex`, `nav.ex`, `assets/js/app.js`, `assets/css/app.css`, `assets/css/DESIGN-TOKENS.md`, `assets/css/contrast-pairs.mjs` - live shell implementation. [VERIFIED: codebase grep]
- `examples/scrypath_ecommerce/e2e/helpers/theme-grid.ts`, `admin_contrast_matrix.spec.ts`, `admin_surface_depth.spec.ts`, `admin_path_motion.spec.ts` - existing browser proof patterns. [VERIFIED: codebase grep]

### Secondary (MEDIUM confidence)
- Phoenix Component docs - `attr/3`, `slot/3`, function components. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html]
- Phoenix LiveView JS interop docs - hooks and client-side interop. [CITED: https://hexdocs.pm/phoenix_live_view/js-interop.html]
- Tailwind CSS dark mode and directives docs - data-selector/custom variant patterns. [CITED: https://tailwindcss.com/docs/dark-mode][CITED: https://tailwindcss.com/docs/functions-and-directives]
- daisyUI theme docs - `default` and `prefersdark` theme behavior. [CITED: https://daisyui.com/docs/themes/]
- Playwright BrowserContext/API/accessibility docs - `colorScheme`, `addInitScript`, and interaction-before-axe pattern. [CITED: https://playwright.dev/docs/api/class-browsercontext][CITED: https://playwright.dev/docs/accessibility-testing]
- W3C WCAG contrast/focus and WAI APG dialog docs. [CITED: https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html][CITED: https://www.w3.org/WAI/WCAG21/Understanding/non-text-contrast.html][CITED: https://www.w3.org/TR/WCAG22/][CITED: https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/]

### Tertiary (LOW confidence)
- None used as authoritative support; one implementation assumption is logged above. [VERIFIED: research protocol]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - versions verified from lockfiles, local commands, Hex, npm, and package legitimacy seam. [VERIFIED: scrypath_ops/mix.lock][VERIFIED: npm view]
- Architecture: HIGH - shell ownership and verification harnesses are directly visible in code. [VERIFIED: codebase grep]
- Pitfalls: HIGH - derived from locked context and existing phase reports/tests; external ARIA/WCAG guidance is cited as MEDIUM. [VERIFIED: 135-CONTEXT.md][CITED: https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/]

**Research date:** 2026-06-26
**Valid until:** 2026-07-26 for local architecture; 2026-07-03 for npm/latest-package recency checks. [VERIFIED: npm view]
