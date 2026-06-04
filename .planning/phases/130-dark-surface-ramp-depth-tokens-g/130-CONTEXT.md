# Phase 130: Dark surface ramp + depth tokens `[G]` - Context

**Gathered:** 2026-06-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Land the missing **`#1B2230` surface-2 elevation step** in the dark theme and refactor the
`.ops-*` fill recipes through **theme-scoped elevation tokens** so dark surfaces step **up**
in elevation (true 4-step midnight ramp: bg `#0C0F14` → panel `#141923` → raised/muted
`#1B2230` → border `#2A3446`) while the **light theme stays pixel-identical**. Adds a
dark-specific ambient-depth shadow recipe so panels seat visually. This is the milestone's
**highest-blast-radius** change (one token layer + ~12 recipes in the most-consumed CSS file)
→ tagged a **cross-AI `[G]` gate**.

**Closes:** DARKTOKEN-01. **Consumes** findings DK-01, DK-05, DK-06, DK-08, DK-09 from
`129-DARK-AUDIT-BACKLOG.md` (the locked, prescriptive backlog — the WHAT is already decided).

**In scope:** the dark surface-2 token, the elevation-token routing of the named recipes, the
dark ambient-shadow ladder, and the `DESIGN-TOKENS.md` ramp doc.

**Out of scope (later phases):** glow/copper vocabulary (131), dark-input/code-block/primary AA
fixes (132 — note these *consume* this phase's surface-2 token), motion (133), per-screen polish
(134), shell chrome (135), the full 40-shot re-capture + before/after gallery (136 / DUALVERIFY-01).

**Success criteria (from ROADMAP):**
1. Dark renders a true 4-step ramp `#0C0F14 → #141923 → #1B2230 → #2A3446`.
2. `.ops-muted-panel`, `.ops-data-card`, `.ops-surface-flat`, `.ops-nav-list`, `.ops-disclosure`,
   `.ops-kbd`, `.ops-result-row`, `.ops-preflight__card--locked` step **up** (not down) in dark.
3. Light is pixel-identical (light matrix + light contrast gate unchanged); `DESIGN-TOKENS.md`
   records the dark ramp.

</domain>

<decisions>
## Implementation Decisions

Calibration: technical owner, `opinionated` → `minimal_decisive`. All four gray areas were
researched **codebase-grounded** (daisyUI plugin emission, the actual recipes, the contrast
harness, the verification toolchain — not external ecosystem trends, per the Phase 128/129
precedent) and locked to the decisive recommendation in one pass.

### ① Elevation token architecture — named theme-scoped tokens declared *inside* the daisyUI blocks
- **D-01:** Introduce three named elevation tokens and route recipes to them:
  - `--ops-bg` (page floor / Night), `--ops-surface-1` (resting panel / Ink),
    `--ops-surface-2` (**the missing raised step**).
  - Dark values: `--ops-bg:#0c0f14; --ops-surface-1:#141923; --ops-surface-2:#1b2230;`
  - Light values: `--ops-bg:#faf7f2; --ops-surface-1:#fffdf8; --ops-surface-2:#faf7f2;`
    (each = the *current* light base it replaces).
- **D-02:** **Declare the three tokens INSIDE both `@plugin "../vendor/daisyui-theme"` theme
  blocks** (the dark block and the light block). **Decisive repo finding:** the vendored
  `daisyui-theme.js` plugin destructures only its known keys and **spreads every other custom
  property verbatim into BOTH** the `[data-theme=dark]` selector AND the
  `@media (prefers-color-scheme: dark)` block (verified in the built
  `priv/static/assets/css/app.css`). So these tokens get **both-path (explicit + system dark)
  coverage for free** — no hand-authored dual selectors needed for the *tokens*.
- **D-03:** **Recipe routing — keep the `color-mix(in oklch, … N%, transparent)` WRAPPER, swap
  only the inner token** `var(--color-base-1xx)` → `var(--ops-surface-N)`. Resting panels
  (`.ops-panel`, `.ops-surface-flat`, `.ops-preflight__card`) → `surface-1`; everything the
  audit flagged flat/coplanar/below-bg (`.ops-muted-panel`, `.ops-disclosure`, `.ops-nav-list`,
  `.ops-kbd`, `.ops-verdict-neutral`, `.ops-notice-surface`, `ops_code_block :default`) →
  `surface-2`. Page floor stays `bg` (`base-200`).
- **Rationale:** the plugin's pass-through makes named tokens strictly cheaper than per-recipe
  dark overrides (which would need ~18 hand-synced dual-selector blocks), keeps the ramp
  tunable from one site, and mirrors the brand book's own `--sp-surface-2:#1B2230` model.
  Namespaced `--ops-*` (not `--sp-*`) respects the locked rename ban.

### ② Light pixel-identical guarantee — token-swap (not value-baking); dark-override fallback where needed
- **D-04:** **Light parity is the dominant `[G]`-gate constraint and the universal tie-breaker.**
  Because light `--ops-surface-1 = #fffdf8` (= light `base-100`) and `--ops-surface-2 = #faf7f2`
  (= light `base-200`), the `color-mix` inputs are unchanged → the browser computes
  **byte-identical light pixels**. This is a token *reference* swap, **NOT** value-baking, so the
  oklch-mix-over-a-gradient-backdrop baking hazard does not arise.
- **D-05 (the one real judgment call — LOCKED):** a recipe is only safe via the *shared*
  `surface-2` token when its current light base equals that token's light value (`#faf7f2`).
  `.ops-data-card` and `.ops-result-row` currently derive from **base-100** in dark yet must
  *also* lift to `#1B2230` — routing them through the shared `surface-2` token would move them in
  light (`#fffdf8`→`#faf7f2`). **Therefore: leave those two recipes' light
  `color-mix(base-100 …)` byte-unchanged and add a DARK-SCOPED `var(--ops-surface-2)` override
  (both dark paths) for just those two.** This carve-out was chosen over the inverse (set light
  surface-2=`#fffdf8` and dark-override the larger base-200 group) because it minimizes the
  dark-scoped override count to two recipes.
- **D-06:** **Rule for the planner:** default to token-swap; fall back to a dark-scoped override
  wherever token-swap would move light. **Light non-modification always wins the tie.**
- **D-07:** The contrast lockstep guard (`contrast-checker.mjs` D-15) scans **only** the `color:`
  property — all in-scope recipes lift via `background:`, so the guard is a non-issue for this
  refactor. (Verified: the Guard-2 regex excludes `background`/`border-color`.)

### ③ Dark ambient-depth recipe — override the four `--shadow-ops-*` tokens under both dark paths
- **D-08:** Reseat dark depth (DK-06) by **overriding the existing four `--shadow-ops-*` token
  values** (not adding new tokens, not per-recipe shadows) with a **dark-inward, low-spread
  `rgba(0,0,0,α)`** ladder — **same offsets/blur as light, color/alpha only**:
  `surface 0 1px 2px /.40` · `mid 0 1px 4px /.45` · `raised 0 2px 10px /.50` ·
  `overlay 0 8px 24px /.55`.
- **D-09:** One override site cascades to all 14 shadow consumers; because every panel recipe
  already carries a 1px border, §6.5's "**faint ambient shadow plus border**" falls out with
  **zero recipe edits**. Resolves DK-14 (warm cream halo → seated depth) and DK-17 (result-row
  hover perceptibility) for free. Static → reduced-motion-irrelevant. Light untouched (dark-scoped).
- **D-10 (asymmetry vs ①):** `--shadow-ops-*` are custom **`@theme`** tokens, **NOT** daisyUI keys
  → they **cannot** ride the `@plugin` block (the plugin would ignore them). They **must** be
  hand-authored in **both** dark selectors: `[data-theme="dark"]` AND
  `@media (prefers-color-scheme: dark) { html:not([data-theme="light"]) }` — the established
  dual-path precedent at `app.css:525-533` (the `select.ops-form-control` chevron).

### ④ Blast-radius verification — gate-scoped triad; defer the full 40-shot to Phase 136
- **D-11:** Proof bundle for THIS gate (run in order), **without duplicating Phase 136**:
  1. **Code green:** `mix test` + `mix opsui.test_a11y` (from `scrypath_ops/`).
  2. **Light token proof (cheap, decisive):** `contrast-checker.mjs` / `make contrast` — light
     AA/AAA counts MUST be **unchanged** = the light token graph didn't move.
  3. **Contrast gate in both themes:** `npm run test:e2e:admin-contrast` (light / dark /
     system-dark × 390/1440), per-scenario `CONTRAST_REPORT_DIR` to dodge the report-overwrite
     quirk. Success = Phase 128 clusters 1 (`.leading-4` 1.08:1 ramp collapse) + the surface-2
     ramp findings resolve in dark.
  4. **Light pixel-identity artifact (the minimal gate artifact):** re-shoot **light-only** 20
     PNGs, diff against the existing `.tmp/admin-screenshots/*light*` baseline with a disposable
     `pixelmatch`/`compare` loop → expect **0 diff pixels**. (No built-in `toMatchSnapshot`.)
  5. **Mounted-admin smoke** + update `DESIGN-TOKENS.md` to record the 4-step dark ramp.
- **D-12:** **Defer the full 40-shot re-capture + v1.33→v1.34 before/after gallery to Phase 136
  (DUALVERIFY-01), which explicitly owns it.** At this gate, prove the ramp via the contrast
  clusters resolving + light pixel-diff, not a full matrix.
- **D-13 (doc drift to flag):** REQUIREMENTS/ROADMAP reference **`mix verify.opsui`, which does
  NOT exist** as an alias. Real targets are `mix test` + `mix opsui.test_a11y`. Either use the
  real names or add a `verify.opsui` alias so the docs become literal.

### Claude's Discretion
- The exact per-recipe `surface-1` vs `surface-2` assignment (validated against the live file),
  the precise α values within the shadow ladder, ordering of edits, and whether to add the
  `verify.opsui` alias — left to the researcher/planner, provided D-04/D-05/D-06 (light parity
  tie-breaker), D-02 (token declaration site), and D-10 (shadow dual-path) hold.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope & the locked work-list
- `.planning/ROADMAP.md` §"Phase 130" — goal, success criteria, `[G]` cross-AI gate tag.
- `.planning/REQUIREMENTS.md` → **DARKTOKEN-01** (the requirement this phase closes) and the
  §Traceability table.
- `.planning/phases/129-dark-theme-brand-expression-audit-s-r/129-DARK-AUDIT-BACKLOG.md` — **the
  prescriptive backlog.** Findings **DK-01, DK-05, DK-06, DK-08, DK-09** route here with exact
  `app.css:line` evidence and proposed fixes; the "Prioritized fix list" row for Phase 130 is the
  scope contract. (DK-14, DK-17 are downstream per-screen items this phase resolves *for free*.)

### Tokens / surfaces being changed
- `scrypath_ops/assets/css/app.css` — the two daisyUI `@plugin` theme blocks (dark ~L23-56,
  light ~L58-91), the `@theme` shadow ladder (~L133-142), `@custom-variant dark` (~L109), the
  `select.ops-form-control` dual-path precedent (~L525-533), and all `.ops-*` recipes
  (`.ops-panel` ~243, `.ops-surface-flat` ~250, `.ops-muted-panel` ~256, `.ops-data-card` ~262,
  `.ops-verdict-neutral` ~357, `.ops-nav-list` ~557, `.ops-disclosure` ~594,
  `.ops-preflight__card[--locked]` ~792/801, `.ops-result-row` ~912, `.ops-kbd` ~1155).
- `scrypath_ops/assets/css/DESIGN-TOKENS.md` — the catalog; **must** gain an elevation-surface
  subsection recording the 4-step dark ramp (criterion 3). "Change a value here only by changing
  it in app.css."
- `scrypath_ops/assets/vendor/daisyui-theme.js` — proof of the custom-property both-path
  pass-through (the mechanism D-02 relies on).
- `scrypath_ops/lib/scrypath_ops/components/ops_ui.ex` — `ops_code_block :default` (~L994) uses
  `bg-base-200`; reroute its surface to `surface-2` (DK-09).
- `prompts/scrypath-brand-book.md` — §6.5 "ambient shadow plus border", §6.3 "quiet glow not
  loud", the 4-step midnight ramp + `--sp-surface-2:#1B2230` reference model.

### Verification substrate
- `examples/scrypath_ecommerce/e2e/admin_contrast_matrix.spec.ts` — the both-themes AA gate
  (`test:e2e:admin-contrast`).
- `examples/scrypath_ecommerce/e2e/admin_screenshot_matrix.spec.ts` — the 40-shot matrix
  (`test:e2e:admin-matrix`); **Phase 136-owned**, used here light-only for the pixel-diff.
- `examples/scrypath_ecommerce/contrast-checker.mjs` + `scrypath_ops/assets/css/contrast-pairs.mjs`
  — the sub-second light-token checker and the D-15 lockstep registry.
- `scrypath_ops/mix.exs` — aliases (`test`, `opsui.test_a11y`; **no `verify.opsui`**).
- `.planning/phases/128-contrast-gate-harness-dark-seed-coverage-s-g/128-CONTRAST-REPORT.md` —
  the 108-violation baseline; clusters 1+2 are this phase's dark success target.
- `.tmp/admin-screenshots/*light*` — the Jun-3 light baseline for the pixel-identity diff.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **daisyUI custom-property pass-through:** any non-daisyUI custom prop placed in a theme
  `@plugin` block is emitted to both the `[data-theme=dark]` and `@media prefers-color-scheme`
  paths — the free both-path mechanism behind D-02.
- **`select.ops-form-control` chevron (app.css:525-533):** the in-repo precedent for the *manual*
  dual-path dark override pattern that D-05 (recipe override) and D-10 (shadow tokens) follow.
- **Contrast harness (Phase 128):** already runs light/dark/system-dark × 390/1440; re-running it
  IS the canonical "both themes" gate — no new tooling.
- **`color-mix(in oklch, … N%, transparent)` recipe wrapper:** preserved intact; only the inner
  token reference is swapped, which is what makes light byte-identical.

### Established Patterns
- **Elevation ladder authority:** `--shadow-ops-surface/mid/raised/overlay` is the single shadow
  vocabulary; override at the token, never per-recipe (D-08/D-09).
- **Light non-modification = proof of parity:** the only way to *prove* a `color-mix` recipe
  renders identically is to not change its inputs (D-04). Light pixel-identity is verified, not
  re-derived.
- **`fix_class: token`** (from the 129 backlog): this is a token + recipe-routing phase, not a
  component/markup phase.

### Integration Points
- This phase's `--ops-surface-2` token is **consumed by Phase 132** (A11Y-TOKEN-01) for the dark
  form-input, code-block, and primary AA fixes (DK-02/03/04) — so name it stably.
- The dark ramp + ambient shadow propagate to Phases 134/135 per-screen and shell polish "for
  free" (DK-11/15/16/18 verify-only after this lands).

</code_context>

<specifics>
## Specific Ideas

- Owner wants the **decisive "don't make me think" path** (Phase 128/129 pattern): recommendations
  grounded in our own artifacts (the daisyUI plugin source, the live recipes, the contrast
  harness), not external ecosystem research — the brand book + 129 backlog + daisyUI behavior
  fully determine the answers. All four gray areas locked to the recommendation in one pass.
- The `#1B2230` surface-2 step is the single most impactful fix in the milestone (finding #1 of
  the 129 backlog) — it simultaneously fixes a systemic AA blocker, the DD1 ramp flatness, and
  the DD4 depth absence across all 6 screens.
- Light pixel-identical is **non-negotiable** on this `[G]` gate file; every architecture choice
  is subordinate to it (D-06 tie-breaker).

</specifics>

<deferred>
## Deferred Ideas

- **Symmetric re-tokenization of both themes** (baking light values so light + dark share one
  clean token set with no `color-mix` wrapper) — deliberately NOT done now; oklch-mix-over-a-
  gradient-backdrop cannot be baked pixel-exactly, a regression risk on a `[G]` gate. Revisit as a
  later cleanup once dark is locked and light is proven stable.
- **Dark form-input / code-block / `.bg-primary` AA fixes (DK-02/03/04)** → Phase 132
  (A11Y-TOKEN-01); they *consume* this phase's surface-2 token.
- **Glow + copper accent vocabulary, shell-wash tuning (DK-07/08/10/12)** → Phase 131.
- **Full 40-shot re-capture + v1.33→v1.34 before/after gallery** → Phase 136 (DUALVERIFY-01).
- **Per-screen polish + shell chrome (DK-11/13/15/16/18)** → Phases 134/135 (verify-only after
  this ramp fix propagates).

None of the above is scope creep into Phase 130 — they are the downstream phases this token layer
feeds.

</deferred>

---

*Phase: 130-dark-surface-ramp-depth-tokens-g*
*Context gathered: 2026-06-04*
