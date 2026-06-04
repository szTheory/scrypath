# Phase 132: A11y contrast remediation — both themes (hard gate) `[G]` - Context

**Gathered:** 2026-06-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Re-tune the **failing text-contrast tokens** so the contrast gate (CONTRAST-HARNESS-01) is
**green at AA 4.5:1 in BOTH themes** — closing `A11Y-TOKEN-01`. Two concrete failure families,
both already identified by the Phase 131 proof bundle:

1. **Muted-text alphas** — `.ops-text-meta`, `.ops-trail__crumb`, `.ops-cmdk__item-hint`,
   `.ops-cmdk__empty`, and dark header-nav `/60` muted text use ad-hoc
   `color-mix(in oklch, var(--color-base-content) N%, transparent)` percentages that land at
   **3.9:1** (light) — below AA.
2. **Primary-violet text** — light `--color-primary: #6c5ce7` with cream `primary-content`
   text on `.ops-nav-item-active` / `.bg-primary` lands at **4.3:1** (the Cluster 3 failure
   Phase 131 deferred here). Dark already uses a darker `#5b4ad1` and passes — **this is a
   light-only fix.**

**CSS + token only.** No new Elixir components, no behavior changes, no LiveView hooks.
Body/long-form text additionally **targets** AAA (≥7:1) as an attached advisory report, not a
hard gate. The gate must be green for **light, dark, and system-dark**.

**Closes:** A11Y-TOKEN-01. **Builds on** Phase 130's surface-2 token + D-10 dual-path pattern
(130-CONTEXT explicitly pre-scoped "primary AA fixes → 132, consuming this phase's surface-2
token"). **Consumes** the recorded failures in `131-VALIDATION.md`.

**⚠ NOT light-pixel-identical** (unlike Phase 131). These AA fixes *intentionally* darken light
muted text and the light primary-text-bg, so the light pixel-diff baseline **must be
re-captured** — a non-zero light diff here is expected and correct, not a regression.

</domain>

<decisions>
## Implementation Decisions

Calibration: technical owner (`technical_background: true`, `explanation_depth:
practical-detailed:technical` → `NON_TECHNICAL_OWNER = false`), `vendor_philosophy: opinionated`
→ `minimal_decisive`. Per the **explicit Phase 128/129/130/131 precedent**, the gray areas were
locked **codebase-grounded** (live `app.css` + WCAG sRGB math + the contrast harness), **NOT**
external ecosystem research — a CSS/token AA-math phase gains nothing from web research. All four
locked to the decisive recommendation in one pass.

### ① Primary-violet AA fix — scoped interactive-text variant (NOT a global brand shift)
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

### ② Muted-text re-tune — named AA-floor token(s), not scattered percentages
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

### ③ 132 vs 135 header-nav boundary — clean seam: 132 = text-contrast math, 135 = chrome
- **D-03:** Phase 132 owns the **AA text-contrast** of header-nav (the `/60` muted text + the
  violet) — explicitly enumerated in A11Y-TOKEN-01 ("header nav `/60`"). Phase 135 (SHELL-DARK-01)
  owns the **chrome/depth/styling** of the same shell surfaces (header/nav, palette, flash, wash).
- **Rationale:** keeps each phase's blast radius clean and matches the requirement wording. 132
  touches token alphas only; 135 touches the visual recipe. (Rejected: folding all header-nav into 132.)

### ④ AAA-body posture — advisory report, AA-only hard gate
- **D-04:** The **hard phase gate stays AA-only** (the harness already gates `summary.aa_fail > 0`;
  AAA is counted as `aaa_advisory`). Body/long-form text (the `base-content` on `base-100/200/300`
  "text" pairs) gets its **AAA status reported and attached** — feeding DUALVERIFY-01's
  "AAA-body report attached" obligation in Phase 136. AAA is a *target*, not a blocker.
- **Rationale:** promoting AAA (≥7:1) to a blocking gate risks over-darkening body text and
  fighting the brand palette. The success criteria say body text "reaches/targets" AAA, and the
  harness design already treats AAA as advisory. (Rejected: hard-gate body AAA.)

### Claude's Discretion
- Exact final token values/alphas (the WCAG-math to clear 4.5:1 on each real surface), the precise
  `--color-primary-strong` value, and whether muted needs one tier or two — all
  **codebase-grounded** by the planner/executor against live `@plugin` hex values and the
  contrast-checker output. No further user input needed.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirement + scope
- `.planning/ROADMAP.md` — Phase 132 entry (goal, 3 success criteria, the AA-both-themes gate)
- `.planning/REQUIREMENTS.md` §A11Y-TOKEN-01 — the locked requirement (muted-text alphas list incl. "header nav `/60`"; AAA-body target; enforced by CONTRAST-HARNESS-01)
- `.planning/phases/130-dark-surface-ramp-depth-tokens-g/130-CONTEXT.md` — named-elevation-token precedent (D-01/D-02) + the explicit "primary AA fixes → 132 consumes surface-2 token" hand-off

### The recorded failures this phase fixes
- `.planning/phases/131-glow-dark-shadow-and-copper-accent-system-r-g/131-VALIDATION.md` — recorded D-11 bundle: the 3 light muted-text AA fails (3.9:1) + Cluster 3 primary-violet (4.3:1 on cream) deferred here
- `.planning/phases/130-dark-surface-ramp-depth-tokens-g/130-VERIFICATION.md` — Cluster 3 out-of-scope-known-fail precedent wording (carry-forward pattern)

### The contrast gate (CONTRAST-HARNESS-01) — the `[G]` proof tooling
- `examples/scrypath_ecommerce/contrast-checker.mjs` — token/selector AA/AAA checker; role→threshold map (text 4.5/7.0, ui+large 3.0/4.5); gate = `aa_fail > 0`; un-rounded WCAG sRGB ratio (WR-01)
- `examples/scrypath_ecommerce/e2e/admin_contrast_matrix.spec.ts` — axe browser matrix (`npm run test:e2e:admin-contrast`); the 131 gate is **Cluster 1 = 0**; Cluster 3 is the violet this phase fixes
- `examples/scrypath_ecommerce/e2e/light-pixel-diff.mjs` — light pixel-diff (baseline **must be re-captured** this phase; non-zero is expected)

### The files this phase edits
- `scrypath_ops/assets/css/app.css` — muted recipes (`.ops-text-meta` L579, `.ops-trail__crumb` L732, `.ops-cmdk__item-hint` L1163, `.ops-cmdk__empty` L1168); primary tokens (`--color-primary` L32 light / L70 dark); `.ops-nav-item-active` L620; `.bg-primary` L410; daisyUI `@plugin` theme blocks for token declaration (both-path coverage)
- `scrypath_ops/assets/css/DESIGN-TOKENS.md` — records the new muted alpha floors + the primary-strong token (lockstep, same-commit)
- `prompts/scrypath-brand-book.md` — the brand violet `#6c5ce7` rationale (consult before any primary-color change)

### Build/verify
- `mix verify.opsui` (run from `scrypath_ops/`) — the LiveView + a11y suite that must stay green
- Asset rebuild (`mix assets.build` in `scrypath_ops`) **before** running gate scripts (Pitfall 5 — stale assets give false results)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **D-10 dual-path theme-scoped pattern** (Phases 130/131): `[data-theme="dark"]` + media-dark
  `html:not([data-theme="light"])` — reuse for any dark-only token override; covers system-dark for free.
- **daisyUI `@plugin` theme blocks**: declaring tokens inside both theme blocks gives both-path
  (explicit + system-dark) coverage with no hand-authored dual selectors (130-D-02).
- **The D-11 proof bundle** is already built (Phase 128/130): `verify.opsui` + `contrast-checker.mjs`
  + `admin_contrast_matrix.spec.ts` + `light-pixel-diff.mjs`. No new tooling needed — re-run it as the gate.

### Established Patterns
- Muted text = `color-mix(in oklch, var(--color-base-content) N%, transparent)` — the alpha % is the
  knob; raising it (or routing to a named floor token) is the AA fix.
- `priv/static/assets/css/app.css` is the **built** copy — edit the source `scrypath_ops/assets/css/app.css`
  and rebuild before diffing (Pitfall 5).
- Light base-content `#141923`, dark base-content `#f4f1ea`; light primary `#6c5ce7`, dark primary
  `#5b4ad1` (from `@plugin` blocks).

### Integration Points
- Named muted token → consumed by ~4+ `.ops-*` muted recipes + dark header-nav.
- `--color-primary-strong` → consumed only by text-bearing interactive bg (`.ops-nav-item-active`, `.bg-primary`).

</code_context>

<specifics>
## Specific Ideas

- The fix is **light-weighted**: the recorded failures (muted 3.9:1, violet 4.3:1) are all in the
  **light** theme; dark already passes. Planner should verify dark stays green but expect the real
  edits to land in light token values.
- Unlike Phase 131, **light WILL change** — re-capture the light pixel-diff baseline; do not hold 0/20.

</specifics>

<deferred>
## Deferred Ideas

- **Header-nav chrome/depth, palette/flash ambient-shadow recipe, `.ops-shell` wash dark-tune** →
  Phase 135 (SHELL-DARK-01). 132 only does the text-contrast math on these surfaces.
- **Hard-gating body-text AAA** → not adopted; AAA stays advisory-reported (re-evaluable at the
  milestone DUALVERIFY-01 gate if desired).

</deferred>

---

*Phase: 132-a11y-contrast-remediation-both-themes-hard-gate-g*
*Context gathered: 2026-06-04*
