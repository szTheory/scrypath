# Phase 130: Dark surface ramp + depth tokens `[G]` - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-04
**Phase:** 130-dark-surface-ramp-depth-tokens-g
**Areas discussed:** Elevation token architecture, Light pixel-identical guarantee, Dark ambient-depth recipe, Blast-radius verification

> Mode: advisor (`minimal_decisive`, technical owner, `opinionated`). Each area was researched
> codebase-grounded by a parallel advisor agent; all four locked to the recommendation in one pass.

---

## Elevation token architecture

| Option | Description | Selected |
|--------|-------------|----------|
| A — Named theme-scoped tokens | `--ops-bg/-surface-1/-surface-2` declared inside both daisyUI `@plugin` blocks; recipes consume via `var()`. Plugin spreads custom props to both `[data-theme=dark]` + `@media prefers-color-scheme` → both-path coverage free. | ✓ |
| B — Per-recipe dark overrides | Keep `color-mix(base-1xx N%)`; add `[data-theme=dark]` + `@media` override on each of ~9 recipes (~18 hand-synced blocks). | |

**User's choice:** A (Lock all & create context).
**Notes:** Decisive repo finding — `daisyui-theme.js` spreads arbitrary custom properties into both dark paths (verified in built CSS), making named tokens strictly cheaper than ~18 dual-selector override blocks and keeping the ramp tunable from one site. Namespaced `--ops-*` (not `--sp-*`) respects the locked rename ban.

---

## Light pixel-identical guarantee

| Option | Description | Selected |
|--------|-------------|----------|
| A — Token-swap (light untouched by construction) | Light `--ops-surface-1=#fffdf8`/`-surface-2=#faf7f2` = current light bases; keep `color-mix` wrapper, swap inner token only → byte-identical light. Dark-scoped override for the 2 base-100-lift recipes (`.ops-data-card`, `.ops-result-row`). | ✓ |
| B — Symmetric re-tokenization | Both themes share new tokens; bake light values from current computed oklch mixes. | |
| (Flip) Inverse carve-out | Set `--ops-surface-2` light = `#fffdf8`; dark-override the larger base-200 group instead. | |

**User's choice:** A with the locked carve-out (chose "Lock all & create context" over "Flip the parity carve-out").
**Notes:** Light parity is the dominant `[G]`-gate constraint and the universal tie-breaker. Token-swap (not value-baking) sidesteps the oklch-mix-over-gradient baking hazard agent 2 flagged in Option B. The carve-out for `.ops-data-card`/`.ops-result-row` was kept (vs flipping) because it minimizes the dark-scoped override count to two recipes. Contrast lockstep guard scans only `color:`; all recipes lift via `background:` → guard is a non-issue.

---

## Dark ambient-depth recipe

| Option | Description | Selected |
|--------|-------------|----------|
| A — Override the four `--shadow-ops-*` tokens | Dark-inward `rgba(0,0,0,α)` ladder (α .40/.45/.50/.55), same offsets/blur as light, authored under both dark paths. One site cascades to all 14 consumers; zero recipe edits. | ✓ |
| B — Separate `*-dark` tokens + per-recipe box-shadow | New tokens + dark box-shadow on each raised recipe (~20+ edits, must re-state animated transitions). | |

**User's choice:** A.
**Notes:** Every panel already carries a 1px border, so §6.5 "ambient shadow plus border" falls out free; resolves DK-14 (warm halo → seated depth) and DK-17 (result-row hover) at no extra cost. Asymmetry vs ①: `--shadow-ops-*` are `@theme` tokens (not daisyUI keys) → cannot ride the plugin block; must be hand-authored in both dark selectors (select-chevron precedent at app.css:525-533).

---

## Blast-radius verification

| Option | Description | Selected |
|--------|-------------|----------|
| A — Gate-scoped triad; defer full 40-shot to 136 | `mix test` + `opsui.test_a11y` → `make contrast` (light counts unchanged) → `test:e2e:admin-contrast` both themes → light-only 20-shot pixel-diff (0 px). | ✓ |
| B — Full re-capture now | A + re-shoot all 40 + before/after gallery (duplicates Phase 136/DUALVERIFY-01). | |

**User's choice:** A.
**Notes:** Contrast harness already covers light/dark/system-dark — re-running it is the canonical both-themes gate. Light pixel-identity proven cheaply by unchanged light AA/AAA counts + a light-only 20-shot diff against the Jun-3 baseline. Full 40-shot re-capture + gallery is Phase 136's owned deliverable. Flagged doc drift: `mix verify.opsui` doesn't exist (real targets: `mix test` + `mix opsui.test_a11y`).

## Claude's Discretion

- Exact per-recipe `surface-1` vs `surface-2` assignment (validated against the live file), precise α values within the shadow ladder, edit ordering, and whether to add a `verify.opsui` alias — left to researcher/planner, provided the light-parity tie-breaker (D-04/05/06), token declaration site (D-02), and shadow dual-path (D-10) hold.

## Deferred Ideas

- Symmetric re-tokenization / value-baking of both themes → later cleanup once dark is locked.
- Dark form-input / code-block / `.bg-primary` AA fixes (DK-02/03/04) → Phase 132 (consume this phase's surface-2 token).
- Glow + copper vocabulary, shell-wash tuning (DK-07/08/10/12) → Phase 131.
- Full 40-shot re-capture + before/after gallery → Phase 136 (DUALVERIFY-01).
- Per-screen polish + shell chrome (DK-11/13/15/16/18) → Phases 134/135 (verify-only after this lands).
