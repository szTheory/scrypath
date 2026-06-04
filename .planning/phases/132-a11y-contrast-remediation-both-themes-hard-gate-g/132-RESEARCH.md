# Phase 132: A11y contrast remediation — both themes (hard gate) `[G]` - Research

**Researched:** 2026-06-04
**Domain:** WCAG contrast token remediation for Phoenix LiveView ops UI CSS
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### ① Primary-violet AA fix — scoped interactive-text variant (NOT a global brand shift)
- **D-01:** Add a scoped strong-violet token (e.g. `--color-primary-strong`, ≈ the dark theme's
  `#5b4ad1` or whatever clears cream-on-violet ≥4.5:1) used **only as the background of
  text-bearing interactive surfaces** — `.ops-nav-item-active` (active pill, `app.css:620`) and
  `.bg-primary` buttons (`app.css:410`). The brand signature violet `#6c5ce7` (which is also
  `--color-accent`) stays **untouched** everywhere it is decorative/ui-role (glow, radial wash,
  focus ring, borders — all already ≥3:1 ui-role-safe).
- **D-01a:** This is **light-only** in practice — dark `--color-primary` `#5b4ad1` already clears
  AA for cream text. Planner: confirm dark nav-active/bg-primary pass before touching dark; do not
  regress dark.
- **Rationale:** during a *brand-perfection* milestone, globally darkening `--color-primary` would
  shift every violet fill/border/ring/wash in light — exactly the brand expression v1.34 is
  protecting. A scoped variant fixes the AA-failing text surfaces with a clean, enumerable blast
  radius. (Rejected: global `--color-primary` darken.)

#### ② Muted-text re-tune — named AA-floor token(s), not scattered percentages
- **D-02:** Introduce **named, AA-verified muted-text token(s)** (e.g. `--ops-text-muted`, themed
  per light/dark) that every muted recipe routes to, replacing the scattered ad-hoc
  `color-mix(... N%, transparent)` percentages. The token's per-theme value is chosen so
  base-content-muted clears **AA 4.5:1** on its actual surface in **both** themes.
- **D-02a:** Route the flagged recipes through it: `.ops-text-meta` (`app.css:579`, currently 55%),
  `.ops-trail__crumb` (`app.css:732`), `.ops-cmdk__item-hint` (`app.css:1163`), `.ops-cmdk__empty`
  (`app.css:1168`), and the dark header-nav `/60` muted text. If a single muted tier cannot serve
  every site at AA, a second strong tier is allowed — but justify each tier.
- **D-02b:** Record the new alpha floors in `DESIGN-TOKENS.md` (success criterion 3 requires it) —
  lockstep, same-commit, mirroring Phase 131's DESIGN-TOKENS.md discipline.
- **Rationale:** matches Phase 130's named-elevation-token precedent (`--ops-surface-N`), makes the
  AA floor **enforceable and documented** rather than N hand-tuned values that drift. (Rejected:
  per-recipe alpha bumps in place.)

#### ③ 132 vs 135 header-nav boundary — clean seam: 132 = text-contrast math, 135 = chrome
- **D-03:** Phase 132 owns the **AA text-contrast** of header-nav (the `/60` muted text + the
  violet) — explicitly enumerated in A11Y-TOKEN-01 ("header nav `/60`"). Phase 135 (SHELL-DARK-01)
  owns the **chrome/depth/styling** of the same shell surfaces (header/nav, palette, flash, wash).
- **Rationale:** keeps each phase's blast radius clean and matches the requirement wording. 132
  touches token alphas only; 135 touches the visual recipe. (Rejected: folding all header-nav into 132.)

#### ④ AAA-body posture — advisory report, AA-only hard gate
- **D-04:** The **hard phase gate stays AA-only** (the harness already gates `summary.aa_fail > 0`;
  AAA is counted as `aaa_advisory`). Body/long-form text (the `base-content` on `base-100/200/300`
  "text" pairs) gets its **AAA status reported and attached** — feeding DUALVERIFY-01's
  "AAA-body report attached" obligation in Phase 136. AAA is a *target*, not a blocker.
- **Rationale:** promoting AAA (≥7:1) to a blocking gate risks over-darkening body text and
  fighting the brand palette. The success criteria say body text "reaches/targets" AAA, and the
  harness design already treats AAA as advisory. (Rejected: hard-gate body AAA.)

### the agent's Discretion

- Exact final token values/alphas (the WCAG-math to clear 4.5:1 on each real surface), the precise
  `--color-primary-strong` value, and whether muted needs one tier or two — all
  **codebase-grounded** by the planner/executor against live `@plugin` hex values and the
  contrast-checker output. No further user input needed.

### Deferred Ideas (OUT OF SCOPE)

- **Header-nav chrome/depth, palette/flash ambient-shadow recipe, `.ops-shell` wash dark-tune** →
  Phase 135 (SHELL-DARK-01). 132 only does the text-contrast math on these surfaces.
- **Hard-gating body-text AAA** → not adopted; AAA stays advisory-reported (re-evaluable at the
  milestone DUALVERIFY-01 gate if desired).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| A11Y-TOKEN-01 | Muted-text alphas, header nav `/60`, handoff/palette/preflight hints, and primary text-bearing violet fills must clear AA in both themes; body/long-form text targets AAA advisory. `[VERIFIED: .planning/REQUIREMENTS.md]` | Use named muted token(s), scoped `--color-primary-strong`, `contrast-pairs.mjs` manifest updates, `mix assets.build`, fast token checker, Playwright axe matrix, and `DESIGN-TOKENS.md` lockstep docs. `[VERIFIED: codebase grep + .planning/phases/132.../132-CONTEXT.md]` |
</phase_requirements>

## Summary

Phase 132 should be planned as a narrowly scoped CSS/token remediation in `scrypath_ops/assets/css/app.css`, `scrypath_ops/assets/css/contrast-pairs.mjs`, and `scrypath_ops/assets/css/DESIGN-TOKENS.md`; no Phoenix components, LiveView hooks, routes, copy, layout, or new packages are needed. `[VERIFIED: 132-CONTEXT.md + 132-UI-SPEC.md + codebase grep]`

The hard standard is WCAG AA: normal text requires 4.5:1, large text requires 3:1, and computed ratios must not be rounded up to pass; body/long-form AAA is advisory at 7:1. `[CITED: https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html]` `[CITED: https://www.w3.org/WAI/WCAG22/Understanding/contrast-enhanced.html]` Non-text UI affordances and state indicators require 3:1 when they are needed to identify controls or states. `[CITED: https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html]`

**Primary recommendation:** Introduce `--ops-text-muted` and, only if needed, `--ops-text-muted-strong`, plus `--color-primary-strong`; route every flagged muted/primary text-bearing site through those tokens, update the muted manifest in lockstep, rebuild assets, and require `node contrast-checker.mjs` plus `npm run test:e2e:admin-contrast` to report zero AA failures for light, dark, and system-dark. `[VERIFIED: codebase grep + Phase 131 validation]`

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Muted text AA floors | Browser / Client CSS | Static assets | The failing behavior is CSS color computation in built assets, not Elixir rendering logic. `[VERIFIED: app.css + contrast-pairs.mjs]` |
| Primary-violet text-bearing fills | Browser / Client CSS | Phoenix component templates | The active nav and `bg-primary` classes are emitted by templates, but the fix should be token/class routing, not component behavior. `[VERIFIED: app.css:620-624 + ops_ui.ex:795-798 + layouts.ex:155-158]` |
| Contrast gate | Browser / Playwright test tier | Node fast checker | The hard gate is the Playwright axe matrix; the fast checker is the sub-second token preflight and manifest guard. `[VERIFIED: admin_contrast_matrix.spec.ts + contrast-checker.mjs]` |
| Token documentation | Static docs | CSS | `DESIGN-TOKENS.md` is the catalog and must be kept in lockstep with `app.css`. `[VERIFIED: DESIGN-TOKENS.md]` |

## Project Constraints (from AGENTS.md)

- Keep Scrypath Ecto/Phoenix ecosystem fit central; this phase is limited to the mounted Phoenix ops UI and must not alter library runtime APIs. `[VERIFIED: AGENTS.md]`
- Public v1 targets Meilisearch first with internal adapter seam; this phase must not touch backend strategy. `[VERIFIED: AGENTS.md]`
- v1 supports inline, Oban-backed, and manual sync flows; this phase must not alter synchronization behavior. `[VERIFIED: AGENTS.md]`
- Developer experience and correctness are high priority; contrast fixes should use named tokens so future contributors can reason about floors. `[VERIFIED: AGENTS.md + 132-CONTEXT.md]`
- Operational clarity matters; do not hide or bypass contrast failures with axe exclusions or rule disables. `[VERIFIED: AGENTS.md + Playwright docs]` `[CITED: https://playwright.dev/docs/accessibility-testing]`
- Follow `CONTRIBUTING.md` for verify tasks and keep edits focused. `[VERIFIED: AGENTS.md]`
- Keep green-main release train posture; do not invent unrelated milestone scope. `[VERIFIED: AGENTS.md]`

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| Tailwind CSS v4 + vendored daisyUI theme plugin | Vendored in `scrypath_ops/assets/vendor/`; versions not declared in package manager | Semantic theme token emission and `bg-*` / `text-*` utilities | Existing CSS architecture is locked by requirements. `[VERIFIED: REQUIREMENTS.md + app.css]` |
| `@axe-core/playwright` | Installed `^4.11.3`; npm latest `4.11.3`, modified 2026-06-02 | Browser contrast scan integration | Playwright's official accessibility guide uses this package for axe scans in Playwright tests. `[VERIFIED: npm registry]` `[CITED: https://playwright.dev/docs/accessibility-testing]` |
| `@playwright/test` | Installed `^1.54.2`; npm latest `1.60.0`, modified 2026-06-04 | Browser matrix runner | Existing `admin_contrast_matrix.spec.ts` uses Playwright Test; official CLI runs `playwright test`. `[VERIFIED: npm registry]` `[CITED: https://playwright.dev/docs/test-cli]` |
| `contrast-checker.mjs` | Local script | Fast token-pair and muted-manifest gate | It implements sRGB compositing, unrounded WCAG ratio comparisons, role thresholds, and exits non-zero on `summary.aa_fail > 0`. `[VERIFIED: examples/scrypath_ecommerce/contrast-checker.mjs]` |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| `pixelmatch` | Installed `^5.3.0`; npm latest `7.2.0`, modified 2026-04-29 | Light screenshot diff support | Use only for re-capturing expected light baseline after intentional light token changes. `[VERIFIED: npm registry + package.json]` |
| `pngjs` | Installed `^7.0.0`; npm latest `7.0.0`, modified 2023-02-20 | PNG read/write for pixel diff | Existing `light-pixel-diff.mjs` support; no new install. `[VERIFIED: npm registry + package.json]` |
| `mix verify.opsui` | Local Mix alias | Runs `mix test` and `mix opsui.test_a11y` | Required ops UI regression command; the alias now exists. `[VERIFIED: scrypath_ops/mix.exs]` |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Named muted tokens | Bump scattered percentages in place | Rejected because scattered ad-hoc alphas drift and are harder to enforce. `[VERIFIED: 132-CONTEXT.md]` |
| Scoped `--color-primary-strong` | Globally darken `--color-primary` | Rejected because global primary changes would move decorative violet roles and brand expression. `[VERIFIED: 132-CONTEXT.md + app.css primary consumers]` |
| Keep axe known-fails | `AxeBuilder.exclude()` or `disableRules()` | Rejected because Phase 132 is the hard gate and should fix failures, not suppress them; Playwright docs warn exclusions/rule disables have downsides. `[CITED: https://playwright.dev/docs/accessibility-testing]` |

**Installation:**
```bash
# No new packages for Phase 132. Existing deps are already in examples/scrypath_ecommerce/package.json.
```

**Version verification:**
```bash
npm view @axe-core/playwright version time.modified repository.url scripts.postinstall
npm view @playwright/test version time.modified repository.url scripts.postinstall
npm view pixelmatch version time.modified repository.url scripts.postinstall
npm view pngjs version time.modified repository.url scripts.postinstall
```

## Package Legitimacy Audit

No external packages should be installed in Phase 132. `[VERIFIED: 132-UI-SPEC.md + package.json]`

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| `@axe-core/playwright` | npm | created 2021-06-02 | npm downloads not returned by `npm view downloads`; registry metadata verified | `github.com/dequelabs/axe-core-npm` | Local `slopcheck install` incorrectly checked PyPI and flagged scoped npm packages `[SLOP]`; ignore for this no-install phase, planner must not install. | Existing approved devDep only |
| `@playwright/test` | npm | created 2020-09-24 | npm downloads not returned by `npm view downloads`; registry metadata verified | `github.com/microsoft/playwright` | Local `slopcheck install` incorrectly checked PyPI and flagged scoped npm packages `[SLOP]`; ignore for this no-install phase, planner must not install. | Existing approved devDep only |
| `pixelmatch` | npm | created 2015-10-14 | npm downloads not returned by `npm view downloads`; registry metadata verified | `github.com/mapbox/pixelmatch` | `slopcheck install` checked PyPI and rated OK there, which is not the npm package legitimacy signal. | Existing approved devDep only |
| `pngjs` | npm | created 2012-08-18 | npm downloads not returned by `npm view downloads`; registry metadata verified | `github.com/pngjs/pngjs` | Local `slopcheck install` incorrectly checked PyPI and flagged npm package `[SLOP]`; ignore for this no-install phase, planner must not install. | Existing approved devDep only |

**Packages removed due to slopcheck [SLOP] verdict:** none; Phase 132 installs none. `[VERIFIED: package.json + phase scope]`
**Packages flagged as suspicious [SUS]:** none for planned work; local slopcheck result is invalid for npm-scoped existing devDeps because it queried PyPI. `[VERIFIED: slopcheck CLI output]`

## Architecture Patterns

### System Architecture Diagram

```text
CSS source tokens/classes
  app.css @plugin theme blocks + @theme + .ops-* recipes
      |
      v
contrast-pairs.mjs muted manifest  <---- lockstep guard scans app.css color: muted mixes
      |
      v
mix assets.build in scrypath_ops
      |
      v
built CSS consumed by mounted ecommerce admin UI
      |
      +--> node contrast-checker.mjs
      |       - parses theme hex tokens
      |       - composites muted alpha over declared bg tokens
      |       - fails iff AA failures > 0
      |
      +--> npm run test:e2e:admin-contrast
              - seeds scenario
              - checks light, dark, system-dark
              - runs axe color-contrast as hard AA gate
              - runs color-contrast-enhanced for AAA advisory
```

### Recommended Project Structure

```text
scrypath_ops/assets/css/
├── app.css              # declare tokens and route selectors
├── contrast-pairs.mjs   # update every muted color: alpha manifest entry
└── DESIGN-TOKENS.md     # document alpha floors and primary-strong scope

examples/scrypath_ecommerce/
├── contrast-checker.mjs # fast token gate
└── e2e/
    ├── admin_contrast_matrix.spec.ts
    └── light-pixel-diff.mjs
```

### Pattern 1: Named Muted AA Floor Tokens

**What:** Define `--ops-text-muted` as the normal AA muted text color and optionally `--ops-text-muted-strong` for smaller/denser text or darker surfaces; route flagged selectors to `color: var(--ops-text-muted*)`. `[VERIFIED: 132-CONTEXT.md + app.css]`

**When to use:** Use for every `color: color-mix(in oklch, var(--color-base-content) N%, transparent)` selector that is readable text and appears in `contrast-pairs.mjs`. `[VERIFIED: contrast-pairs.mjs]`

**Example:**
```css
/* Source: local pattern from app.css + Phase 132 context */
@plugin "../vendor/daisyui-theme" {
  name: "light";
  --ops-text-muted: color-mix(in oklch, var(--color-base-content) 60%, transparent);
  --ops-text-muted-strong: color-mix(in oklch, var(--color-base-content) 64%, transparent);
}

.ops-text-meta {
  color: var(--ops-text-muted);
}
```

**Planning note:** Tailwind/daisyUI plugin pass-through is verified for custom properties in theme blocks from Phase 130; if token values use `color-mix`, executor must confirm the vendored plugin preserves the value form in built CSS before relying on it. `[VERIFIED: 130-CONTEXT.md]`

### Pattern 2: Scoped Primary Strong Background

**What:** Add `--color-primary-strong` as a semantic strong-violet background for text-bearing interactive surfaces only; do not replace `--color-primary` for glow, borders, shell wash, route mark, or focus. `[VERIFIED: 132-CONTEXT.md]`

**When to use:** Apply to `.ops-nav-item-active` and template-produced `bg-primary text-primary-content` selected button states that render cream text on violet. `[VERIFIED: app.css:620-624 + ops_ui.ex:795-798]`

**Example:**
```css
/* Source: local app.css active-nav pattern */
.ops-nav-item-active {
  background: var(--color-primary-strong);
  color: var(--color-primary-content);
}
```

**Important divergence:** The current live CSS has dark `--color-primary: #6c5ce7` and light `--color-primary: #5b4ad1`, while `132-CONTEXT.md` says the reverse in D-01a. `[VERIFIED: app.css:32-33 and app.css:70-71]` Phase 131 validation shows the remaining Cluster 3 failures are dark/system-dark `.ops-nav-item-active` and `.bg-primary` at 4.3:1. `[VERIFIED: 131-VALIDATION.md]` The planner should fix the current failing dark/system-dark pair without changing decorative `#6c5ce7` uses. `[VERIFIED: codebase grep + 132-CONTEXT.md]`

### Anti-Patterns to Avoid

- **Changing global `--color-primary`:** It affects shell wash, focus, borders, glows, route mark, verdict dots, and other decorative/semantic roles. `[VERIFIED: app.css grep]`
- **Editing built CSS under `priv/static`:** Source is `scrypath_ops/assets/css/app.css`; rebuild assets before proving. `[VERIFIED: 132-UI-SPEC.md]`
- **Leaving manifest drift:** The fast checker has a D-15 guard that scans muted `color:` properties and compares them with `contrast-pairs.mjs`. `[VERIFIED: contrast-checker.mjs]`
- **Using rounded ratios to pass:** WCAG says thresholds must be compared without rounding. `[CITED: https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html]`
- **Suppressing axe failures:** Phase 132 is a hard gate; no `exclude()` or `disableRules()` for the known contrast failures. `[VERIFIED: 132-CONTEXT.md]` `[CITED: https://playwright.dev/docs/accessibility-testing]`

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| WCAG ratio math in implementation | New calculator or spreadsheet | Existing `contrast-checker.mjs` and Playwright axe matrix | The local checker already implements sRGB compositing, relative luminance, unrounded threshold comparison, and report schema. `[VERIFIED: contrast-checker.mjs]` |
| Browser contrast crawl | New Playwright spec | Existing `admin_contrast_matrix.spec.ts` | The spec already covers light, dark, system-dark, mobile, desktop, and seed scenarios. `[VERIFIED: admin_contrast_matrix.spec.ts]` |
| Muted token registry | New JSON/config format | Existing `contrast-pairs.mjs` | It is already wired into the lockstep guard and role thresholds. `[VERIFIED: contrast-pairs.mjs]` |
| Design token documentation | New docs page | Existing `DESIGN-TOKENS.md` | It is the established token catalog and success criterion requires recording alpha floors there. `[VERIFIED: DESIGN-TOKENS.md + ROADMAP.md]` |

**Key insight:** This phase is not about inventing accessibility tooling; the project already has a live AA gate, and the plan should reduce remaining failures to zero by changing named tokens and manifest entries. `[VERIFIED: Phase 128 report + Phase 131 validation]`

## Common Pitfalls

### Pitfall 1: Context Says Light-Only, Code Fails Dark/System
**What goes wrong:** Planner follows stale wording and changes light primary while current failures remain dark/system-dark. `[VERIFIED: 132-CONTEXT.md vs app.css + 131-VALIDATION.md]`
**How to avoid:** Treat `app.css` and latest contrast reports as authoritative; confirm `#f4f1ea` on `#6c5ce7` is 4.307:1 and `#f4f1ea` on `#5b4ad1` is 5.566:1 before editing. `[VERIFIED: local WCAG calculation]`

### Pitfall 2: Token Values Pass Fast Checker But Browser Still Fails
**What goes wrong:** Token manifest covers declared pairs, but actual rendered surfaces or template utility classes differ. `[VERIFIED: Phase 128 report]`
**How to avoid:** Require both `node contrast-checker.mjs` and `npm run test:e2e:admin-contrast`; the Playwright axe matrix is the hard close gate. `[VERIFIED: 132-UI-SPEC.md]`

### Pitfall 3: Adding a Token Without Manifest Lockstep
**What goes wrong:** `app.css` and `contrast-pairs.mjs` diverge and the fast checker fails before the browser gate. `[VERIFIED: contrast-checker.mjs D-15 guard]`
**How to avoid:** Update `contrast-pairs.mjs` in the same task as every muted `color:` change. `[VERIFIED: contrast-pairs.mjs]`

### Pitfall 4: Forgetting Asset Rebuild
**What goes wrong:** Browser proof runs stale built assets and reports false failures. `[VERIFIED: 132-UI-SPEC.md]`
**How to avoid:** Run `mix assets.build` from `scrypath_ops/` before token checker, pixel diff, or Playwright matrix. `[VERIFIED: scrypath_ops/mix.exs]`

### Pitfall 5: Treating AAA Advisory as Blocking
**What goes wrong:** Planner over-darkens text or rewrites typography to chase AAA. `[VERIFIED: 132-CONTEXT.md]`
**How to avoid:** Hard gate only `aa_fail == 0`; attach/report AAA-body findings for Phase 136. `[VERIFIED: admin_contrast_matrix.spec.ts + contrast-checker.mjs]`

## Code Examples

### Compute Candidate Alpha Floors

```js
// Source: local WCAG math mirrors contrast-checker.mjs and W3C formula.
// Current candidate floors from app.css tokens:
// light base-100: AA at 60%, AAA at 73%
// light base-200: AA at 60%, AAA at 74%
// light base-300: AA at 64%, AAA at 78%
// dark base-100: AA at 50%, AAA at 65%
// dark surface-2: AA at 50%, AAA at 67%
```

Use these as planning starting points only; executor must verify with the fast checker and browser matrix because actual rendered backgrounds can differ from the simple token pair. `[VERIFIED: local WCAG calculation + Phase 128 report]`

### Gate Commands

```bash
cd scrypath_ops
mix assets.build
mix verify.opsui

cd ../examples/scrypath_ecommerce
node contrast-checker.mjs
CONTRAST_REPORT_DIR=test-results/contrast/phase132 npm run test:e2e:admin-contrast
node e2e/light-pixel-diff.mjs
```

`node contrast-checker.mjs` exits non-zero until AA failures are zero; AAA advisory does not affect exit code. `[VERIFIED: contrast-checker.mjs]`

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Ad-hoc muted `color-mix(... N%, transparent)` per selector | Named AA-floor muted token(s) with manifest lockstep | Phase 132 decision | Reduces drift and makes floors documentable. `[VERIFIED: 132-CONTEXT.md]` |
| Surface ramp missing `#1B2230` and dark text near-invisible | `--ops-bg`, `--ops-surface-1`, `--ops-surface-2` available | Phase 130 | Phase 132 can consume surface tokens and focus on remaining AA failures. `[VERIFIED: 130-VERIFICATION.md]` |
| Cluster 1 allowed as scoped known failure | Cluster 1 resolved; Cluster 3 remains | Phase 131 validation | Phase 132 must make the full contrast matrix exit 0, not just cluster-scoped green. `[VERIFIED: 131-VALIDATION.md]` |

**Deprecated/outdated:**
- `132-CONTEXT.md` D-01a light-only primary statement: stale against current `app.css` and Phase 131 validation; use latest code/report evidence. `[VERIFIED: app.css + 131-VALIDATION.md]`
- Phase 128 report's dark-input/code-block failures as active 132 targets: those were largely resolved by Phase 130; validate current report before planning extra form/code fixes. `[VERIFIED: 130-VERIFICATION.md + 131-VALIDATION.md]`

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `--ops-text-muted` can be declared in daisyUI `@plugin` blocks with `color-mix(...)` values and emitted correctly to both explicit and system theme paths. `[ASSUMED]` | Architecture Patterns | If plugin pass-through does not preserve functional values, executor should declare the token in a normal CSS selector block for light/dark/system instead. |
| A2 | One normal muted tier plus one strong tier will be enough for all flagged text sites. `[ASSUMED]` | Summary / Standard Stack | If actual surfaces differ, planner must allow task-level calibration and justify additional tiers. |

## Open Questions (RESOLVED)

1. **Should `bg-primary` template utilities be replaced globally or wrapped with a local strong class?**
   - What we know: `ops_segmented_control` uses `"bg-primary text-primary-content"` for selected buttons, and `.ops-nav-item-active` has a CSS rule. `[VERIFIED: ops_ui.ex:795-798 + app.css:620-624]`
   - What's unclear: whether every `bg-primary text-primary-content` use should be strong-violet, or only selected text-bearing controls identified by the matrix. `[VERIFIED: codebase grep]`
   - Recommendation: plan a grep-driven local replacement for text-bearing interactive fills only, then rerun the matrix. `[VERIFIED: 132-CONTEXT.md]`
   - Resolution: Phase 132 will use the scoped CSS route already selected in the approved plans: `.ops-nav-item-active` uses `background: var(--color-primary-strong)`, and `.bg-primary.text-primary-content` gets a local CSS override using `background-color: var(--color-primary-strong)`. This avoids global replacement of all `bg-primary` utilities and avoids Phoenix component/template edits while preserving decorative `--color-primary` uses. `[RESOLVED: 132-01-PLAN.md]`

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | `mix assets.build`, `mix verify.opsui` | ✓ | 1.19.5 / OTP 28 | None |
| Mix | Build/test aliases | ✓ | 1.19.5 | None |
| Node.js | contrast checker and Playwright | ✓ | v22.14.0 | None |
| npm | Playwright scripts | ✓ | 11.1.0 | None |
| Docker | optional ecommerce test stack | ✓ | 29.5.2 | Host dev loop via Makefile if services are already running |
| PostgreSQL client | local DB verification visibility | ✓ | 14.17 | Docker Postgres via `make infra-pg` |
| Context7 CLI | library docs fallback | ✗ | — | Official docs via WebFetch/WebSearch |
| graphify | code graph context | ✗ | disabled | Direct code grep/read |

**Missing dependencies with no fallback:**
- None found for planning; actual Playwright gate still requires a running ecommerce server at `PLAYWRIGHT_BASE_URL`. `[VERIFIED: Makefile + playwright.config.ts]`

**Missing dependencies with fallback:**
- Context7 CLI absent; official W3C, Playwright, and Deque/GitHub docs were used directly. `[VERIFIED: command -v ctx7]`

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Elixir ExUnit via `mix verify.opsui`; Node local checker; Playwright Test + axe matrix |
| Config file | `scrypath_ops/mix.exs`; `examples/scrypath_ecommerce/playwright.config.ts`; `examples/scrypath_ecommerce/e2e/admin_contrast_matrix.spec.ts` |
| Quick run command | `cd examples/scrypath_ecommerce && node contrast-checker.mjs` |
| Full suite command | `cd scrypath_ops && mix assets.build && mix verify.opsui`; then `cd ../examples/scrypath_ecommerce && npm run test:e2e:admin-contrast` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| A11Y-TOKEN-01 | Muted token pairs clear AA and manifest stays in lockstep | static/unit | `cd examples/scrypath_ecommerce && node contrast-checker.mjs` | ✅ |
| A11Y-TOKEN-01 | Light/dark/system-dark browser contrast has zero AA failures | e2e | `cd examples/scrypath_ecommerce && npm run test:e2e:admin-contrast` | ✅ |
| A11Y-TOKEN-01 | Ops UI tests and a11y contracts stay green | unit/a11y | `cd scrypath_ops && mix verify.opsui` | ✅ |
| A11Y-TOKEN-01 | Intentional light changes are baselined | visual regression | `cd examples/scrypath_ecommerce && node e2e/light-pixel-diff.mjs` after re-capture | ✅ |

### Sampling Rate

- **Per task commit:** `node contrast-checker.mjs` from `examples/scrypath_ecommerce/`. `[VERIFIED: Phase 131 validation pattern]`
- **Per wave merge:** `mix assets.build`, `mix verify.opsui`, `node contrast-checker.mjs`. `[VERIFIED: 132-UI-SPEC.md]`
- **Phase gate:** Full Playwright contrast matrix green for light, dark, and system-dark before `$gsd-verify-work`. `[VERIFIED: ROADMAP.md + 132-UI-SPEC.md]`

### Wave 0 Gaps

- None — existing test infrastructure covers the phase requirement. `[VERIFIED: local file scan]`

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | No auth behavior changes; keep existing tests green. `[VERIFIED: phase scope]` |
| V3 Session Management | no | No session behavior changes. `[VERIFIED: phase scope]` |
| V4 Access Control | no | No routes or authorization changes. `[VERIFIED: 132-UI-SPEC.md]` |
| V5 Input Validation | no | No user-input parsing changes. `[VERIFIED: phase scope]` |
| V6 Cryptography | no | No crypto changes. `[VERIFIED: phase scope]` |

### Known Threat Patterns for CSS/Token Phase

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Supply-chain drift from new visual/testing packages | Tampering | Install no packages in Phase 132; use existing harness. `[VERIFIED: phase scope]` |
| Hiding accessibility failures with test exclusions | Repudiation | Do not use axe excludes/rule disables; fix tokens and keep reports. `[CITED: https://playwright.dev/docs/accessibility-testing]` |
| Stale built assets causing false proof | Repudiation | Run `mix assets.build` before gates. `[VERIFIED: 132-UI-SPEC.md]` |

## Sources

### Primary (HIGH confidence)

- `132-CONTEXT.md` — locked implementation decisions and deferred scope.
- `132-UI-SPEC.md` — CSS/token-only design contract and verification contract.
- `scrypath_ops/assets/css/app.css` — live token values and failing selector anchors.
- `scrypath_ops/assets/css/contrast-pairs.mjs` — muted manifest and role map.
- `examples/scrypath_ecommerce/contrast-checker.mjs` — fast checker math and exit behavior.
- `examples/scrypath_ecommerce/e2e/admin_contrast_matrix.spec.ts` — Playwright axe hard gate.
- `131-VALIDATION.md` — latest known remaining Cluster 3 failure evidence.
- W3C WCAG Understanding docs for 1.4.3, 1.4.6, and 1.4.11 — thresholds and non-rounding rules.
- Playwright accessibility testing docs — `@axe-core/playwright` usage and automation limitations.

### Secondary (MEDIUM confidence)

- npm registry metadata for existing devDeps — versions, publish dates, repositories, postinstall script absence.

### Tertiary (LOW confidence)

- Local computed alpha floors — useful planning heuristics, but must be confirmed by the fast checker and browser matrix.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new stack, existing local harness and official docs verified.
- Architecture: HIGH — CSS/token responsibility and gate flow are directly present in the codebase.
- Pitfalls: HIGH — based on concrete divergence between current CSS, Phase 131 validation, and older Phase 132 context.

**Research date:** 2026-06-04
**Valid until:** 2026-07-04 for local architecture; re-check npm and official docs before dependency changes.
