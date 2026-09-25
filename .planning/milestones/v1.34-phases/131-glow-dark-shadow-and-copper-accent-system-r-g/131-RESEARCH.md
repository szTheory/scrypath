# Phase 131: Glow, dark shadow, and copper accent system — Research

**Researched:** 2026-06-04
**Domain:** CSS design-token authoring (Tailwind v4 + daisyUI, `.ops-*` system) — scrypath_ops admin UI
**Confidence:** HIGH (all findings grounded in live codebase; zero external research surface — per CONTEXT directive)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01 — Ship system + the one zero-cost in-situ proof; defer per-screen badges to 134.** Phase 131 wires up exactly:
  - `--shadow-ops-panel-dark` applied to `.ops-panel`, `.ops-cmdk__panel`, `#flash-group > *`, `.ops-intent-card` via a dark-scoped override block (D-10 dual-path) — pure CSS, no markup.
  - `.ops-glow` applied to `.ops-route-mark` (always in dark) and `.ops-nav-item-active` (active pill, dark) via dark-scoped CSS — classes already on the elements, no markup edit.
  - `.ops-intent-card--recommended` glow composition (D-02) — pure CSS.
  - Shell wash mobile tune (14%→10% alpha, 34rem→28rem extent at `max-width: 640px`) — pure CSS.
  - **Eyebrow re-style:** swap the inline `text-ops-sm font-semibold uppercase tracking-wide text-secondary` utilities at the single shared `ops_page_header` slot for `.ops-copper-eyebrow`. One edit, propagates to all 6 screens. This is a re-style of an existing slot, not new markup — the phase's in-situ proof.
- **D-01a — Declare** `.ops-copper-badge`, `.ops-copper-node`, `.ops-copper-node--fill` in `@layer components` (vocabulary ships now), but do NOT wire them into any per-screen template. Per-screen `.heex` edits → Phase 134.
- **D-02 — Recommended intent-card dark composition:** in dark, compose **all three** box-shadow layers in a single dark-scoped override, via token references, painted in this order:
  ```css
  .ops-intent-card--recommended {
    box-shadow:
      inset 0 0 0 1px color-mix(in oklch, var(--color-primary) 45%, transparent),  /* ring — on top */
      var(--shadow-ops-panel-dark),   /* ambient seat */
      var(--shadow-ops-glow);          /* violet aura — outermost / behind */
  }
  ```
- **D-02a — Light is untouched.** The recommended card keeps its existing `var(--shadow-ops-surface), inset 0 0 0 1px color-mix(primary 45%)`. The 3-layer stack exists only under dark paths.
- **D-03 — Declare `--shadow-ops-glow-copper`** in both D-10 dark paths (`0 0 6px 1px rgba(193,122,62,0.25)`) with `@theme` light default `none`. No `.ops-*` class consumes it in 131. The consuming hover rule is deferred to Phase 133/134.

### Claude's Discretion
- Exact authoring site/ordering of the dark-scoped override blocks within `app.css` (must follow the D-10 dual-path precedent and the Phase-130 shadow blocks).
- Whether the four panel-dark target overrides live in one shared dark-scoped rule block or per-selector blocks — provided light stays pixel-identical (`--shadow-ops-panel-dark` never declared in light).
- The precise `DESIGN-TOKENS.md` section wording (two new sections per UI-SPEC "Lockstep Obligations").
- The `mix verify.opsui` vs `mix test`/`mix opsui.test_a11y` naming question (D-13) — **RESOLVED by this research: the alias already exists, see Finding F4.**

### Deferred Ideas (OUT OF SCOPE)
- **Per-screen copper-badge/node application** (Search federation badge, Playbook file-type badge, Control-Room intent-card icon node) → **Phase 134** (SCREEN-DARK-01).
- **Copper-glow consuming hover rule** (uses `--shadow-ops-glow-copper`) → **Phase 133/134**.
- **`.ops-text-meta` / header-nav / muted-text AA re-tuning** → **Phase 132** (A11Y-TOKEN-01). Cluster 3 of the contrast harness stays deferred there, not gated in 131.
- **Full 40-shot re-capture + before/after gallery** → **Phase 136** (DUALVERIFY-01).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| GLOW-01 | Dark "faint ambient shadow plus border" panel recipe (seated depth) + tokenized opt-in low-spread violet "quiet glow" for route/path/diagram lines and key hover states only — never text or background floods. | `--shadow-ops-panel-dark` + `--shadow-ops-glow` tokens declared in both D-10 dark paths; `.ops-glow` class in `@layer components`; applied to `.ops-route-mark` / `.ops-nav-item-active` / recommended card via dark-scoped overrides (see Findings F1–F3, F6). Light gate enforced by light-pixel-diff (Validation Architecture). |
| COPPER-01 | Copper promoted to its 5% role — `.ops-*` copper accent vocabulary (eyebrow, key-callout badge, key-node emphasis), both themes, AA-safe dark-text-on-copper. Never a status tone. | `.ops-copper-eyebrow` / `.ops-copper-badge` / `.ops-copper-node[--fill]` in `@layer components`; eyebrow re-style at `ops_ui.ex:23`; 9-pairing AA evidence table in UI-SPEC (manually verified — NOT auto-checked, see Finding F8). |
</phase_requirements>

## Summary

Phase 131 is a **CSS + design-token-only** change to a single stylesheet (`scrypath_ops/assets/css/app.css`, 1313 lines) plus one mirror-doc (`DESIGN-TOKENS.md`) and one one-line Elixir re-style (`ops_ui.ex:23`). There is **no external research surface** — Tailwind v4 + daisyUI + the in-repo `.ops-*` system are the entire stack, and every value is pre-locked by `131-UI-SPEC.md`. The research job is therefore pure **codebase grounding**: pin every cited line number against the live file (several have drifted), capture the exact copy-from precedents, and design the Validation Architecture that drives the Nyquist `VALIDATION.md` gate.

The dominant architectural pattern is the **D-10 dual-path dark override**: `--shadow-ops-*` are `@theme` custom tokens, *not* daisyUI semantic keys, so they cannot ride the `@plugin` theme pass-through and must be **hand-authored in BOTH** `[data-theme="dark"]` (explicit dark) **and** `@media (prefers-color-scheme: dark) html:not([data-theme="light"])` (system dark). Two distinct in-repo precedents exist for this and must be matched: (a) **token redefinition** at end-of-file (`app.css:1298–1313`, outside any layer) for the `--shadow-ops-*` ladder; (b) **dark-scoped rule blocks** inside `@layer components` (`select.ops-form-control` at `app.css:531–539`; `.ops-data-card`/`.ops-result-row` at `app.css:1279–1295`).

**The non-negotiable gate is light pixel-identity** (`[G]` cross-AI gate, inherited from Phase 130 D-06): every new visual layer is dark-scoped, and the only way to *prove* light is unchanged is to never touch its inputs. The proof bundle is unchanged from Phase 130 (no new tooling): `mix verify.opsui` + `contrast-checker.mjs` + `test:e2e:admin-contrast` + `light-pixel-diff.mjs`.

**Primary recommendation:** Follow the UI-SPEC's 10-step Implementation Checklist verbatim, authoring all dark-scoped blocks against the two precedents above. Watch four grounding gotchas (Findings F5, F7, F8, F9): every line number in UI-SPEC/CONTEXT has drifted; `.ops-route-mark` and `#flash-group > *`/`.ops-cmdk__panel` already carry box-shadows that must be **composed**, not replaced; the copper AA pairings are **not** machine-checked by the contrast harness; and `verify.opsui` already exists (D-13 closed).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Ambient dark panel depth (`--shadow-ops-panel-dark`) | CSS / design tokens (`app.css`) | — | Pure box-shadow token + dark-scoped application; no runtime, no markup. |
| Quiet violet glow (`--shadow-ops-glow` + `.ops-glow`) | CSS / design tokens (`app.css`) | — | Token + opt-in class applied to existing elements via dark-scoped rules. |
| Copper accent vocabulary (`.ops-copper-*`) | CSS / design tokens (`app.css`) | Elixir template (`ops_ui.ex` — 1 line, eyebrow re-style) | Classes are CSS-authored; the single in-situ application swaps utilities at one shared component slot. |
| Token documentation (lockstep) | Markdown (`DESIGN-TOKENS.md`) | — | Project convention: every `app.css` token mirrored in the design doc. |
| Light pixel-identity proof | Test substrate (Node lane in `examples/scrypath_ecommerce/`) | Elixir test (`mix verify.opsui`) | D-16: contrast/pixel tooling lives in the Node lane; `scrypath_ops` stays Node-free. |

## Project Constraints (from codebase conventions)

No root `CLAUDE.md` exists. Constraints are derived from the established Phase 128–130 patterns and in-file documentation comments:

- **D-10 — `--shadow-ops-*` are `@theme` tokens, not daisyUI keys** → they CANNOT ride the `@plugin` pass-through and MUST be hand-authored in both dark paths (`app.css:1298` comment).
- **D-16 — Node-free `scrypath_ops`.** All contrast/pixel tooling lives in `examples/scrypath_ecommerce/`; `contrast-checker.mjs` reads `app.css` cross-workspace via `../../scrypath_ops/assets/css/app.css`.
- **D-10/D-11 — contrast-pairs.mjs references TOKEN NAMES, not hex.** No `--color-*` declarations, no hex literals in the manifest.
- **T-128-03 — CSS is parsed as text only.** No `eval()` of CSS content.
- **Light non-modification = proof of parity.** Override at the token / dark-scoped rule, never the base recipe (Phase 130 D-04/D-06).
- **Copper is a brand accent, never a status tone.** `.ops-copper-*` does NOT join `tone_class/1` / `badge_class/1`.

## Standard Stack

No packages are installed or changed by this phase. Stack is entirely in-repo and pre-existing.

| Component | Where | Purpose | Why Standard |
|-----------|-------|---------|--------------|
| Tailwind v4 + daisyUI (vendored) | `@plugin "../vendor/daisyui*"` (`app.css:13,23,61`) | Theme tokens + utilities | Project standard since Phase 49; `@custom-variant dark` defined L115. |
| `.ops-*` component system | `@layer components` (`app.css:232`+) | Custom admin-UI vocabulary | All admin chrome authored here. |
| `--shadow-ops-*` token ladder | `@theme` block (`app.css:141–148`) | Elevation tokens | surface → mid → raised → overlay; redefined per-theme via D-10. |
| Node verification lane | `examples/scrypath_ecommerce/` | contrast + pixel-diff gates | D-16; keeps `scrypath_ops` Node-free. |

**Package Legitimacy Audit:** N/A — this phase installs zero external packages. `pixelmatch ^5.3.0` and `pngjs` are already-present devDependencies in `examples/scrypath_ecommerce/package.json` (verified by Phase 130; no new installs).

## Architecture Patterns

### The D-10 dual-path dark override (THE central pattern)

`--shadow-ops-*` custom tokens do not pass through daisyUI's `@plugin` theme blocks (only daisyUI-reserved keys like `--color-*`, `--radius-*`, `--ops-surface-*` do). So any dark value for a `--shadow-ops-*` token must be written **twice**, once per dark path. There are **two distinct precedent shapes** in the file — match the right one:

**Precedent A — token redefinition (end of file, OUTSIDE any layer, `app.css:1298–1313`):**
```css
/* D-10: --shadow-ops-* are @theme tokens, not daisyUI keys — must hand-author both dark paths.
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
**Use this shape for:** declaring `--shadow-ops-panel-dark`, the dark value of `--shadow-ops-glow`, and `--shadow-ops-glow-copper`. Recommend appending these new tokens into the existing two blocks (one line each per path) rather than creating new blocks — keeps the token-ladder in one cascade site.

**Precedent B — dark-scoped RULE block (inside `@layer components`, `app.css:531–539`):**
```css
[data-theme="dark"] select.ops-form-control {
  background-image: url("data:image/svg+xml,...stroke='%23a6adba'...");
}
@media (prefers-color-scheme: dark) {
  html:not([data-theme="light"]) select.ops-form-control {
    background-image: url("data:image/svg+xml,...stroke='%23a6adba'...");
  }
}
```
A second instance of Precedent B (added in Phase 130) lives at `app.css:1279–1295` (`.ops-data-card`, `.ops-result-row`). **Use this shape for:** applying `--shadow-ops-panel-dark` / `.ops-glow` to the four panels, the route mark, the active nav pill, and the recommended-card 3-layer composition.

### `@theme` light defaults

`--shadow-ops-glow` and `--shadow-ops-glow-copper` get their **light default of `none`** declared once in the `@theme` block (`app.css:120–`, alongside the existing `--shadow-ops-*` ladder at L141–148). The dark values then override via Precedent A. This is what makes `.ops-glow` a no-op in light with zero light regression.

### Recommended Project Structure (files touched)
```
scrypath_ops/
├── assets/css/
│   ├── app.css                 # ALL token + class + dark-scoped-rule edits (1313 lines)
│   └── DESIGN-TOKENS.md        # +2 sections (lockstep mirror)
└── lib/scrypath_ops_web/components/
    └── ops_ui.ex               # 1-line eyebrow re-style at L23
```

### Anti-Patterns to Avoid
- **Editing the base `.ops-panel` / `.ops-intent-card` / `.ops-route-mark` definitions to add the new shadows.** This would regress light. Always add via a dark-scoped Precedent-B block.
- **Declaring `--shadow-ops-panel-dark` in light** (`@theme` or light `@plugin`). It must NEVER exist in light — that is the pixel-identity mechanism.
- **Replacing an existing `box-shadow` with `.ops-glow`/`panel-dark`** on elements that already have one (route mark, flash, cmdk panel). See Finding F7 — these must be **composed**.
- **Routing copper through `tone_class/1` / `badge_class/1`.** Copper is decorative, not semantic.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Dark-token override | A new `dark:` Tailwind utility scheme | The D-10 dual-path precedent (A for tokens, B for rules) | `dark:` is explicit-dark only (`app.css:104–115` D-07); it does NOT track system dark. |
| Light-parity proof | Visual eyeballing | `light-pixel-diff.mjs` (threshold 0, 20 PNGs) | Byte-exact pixel gate already exists and is the `[G]` contract. |
| AA verification of muted text | New contrast math | `contrast-checker.mjs` + `contrast-pairs.mjs` | Sub-second sRGB checker; D-12/D-15 compliant. (Note: does NOT cover copper — Finding F8.) |
| The `verify.opsui` alias | Adding a new alias | The existing `mix verify.opsui` | Already present (Finding F4). |

## Grounding Findings (line-number drift + precedents)

These are the verified-against-live-file results. **Every line number cited in CONTEXT/UI-SPEC has drifted** — use these instead.

### F1 — `@theme` block & shadow ladder
- `@theme` opens at **`app.css:120`**. Existing `--shadow-ops-*` ladder at **L141–148** (`surface`/`mid`/`raised`/`overlay`/`focus`). Add `--shadow-ops-glow: none;` and `--shadow-ops-glow-copper: none;` here (light defaults). `--shadow-ops-panel-dark` is dark-only (do NOT add a light default — it must be undeclared in light).

### F2 — daisyUI `@plugin` theme blocks (color source of truth)
- Dark block: **`app.css:23–59`** (`--color-secondary: #c17a3e`, `--color-secondary-content: #0c0f14`, `--ops-surface-1: #141923`, `--ops-surface-2: #1b2230`).
- Light block: **`app.css:61–97`** (`--color-secondary: #a85d2e`, `--color-secondary-content: #fffdf8`, `--ops-surface-1: #fffdf8`, `--ops-surface-2: #faf7f2`).
- `--color-base-content`: dark `#f4f1ea` / light `#141923`. These confirm every hex the UI-SPEC AA table relies on.

### F3 — Panel-dark target selectors (current shadows; UI-SPEC line numbers are wrong)
| Selector | Live line | Current `box-shadow` | Compose action |
|----------|-----------|----------------------|----------------|
| `.ops-panel` | **L246–251** | `var(--shadow-ops-surface)` (L250) | Replace token ref in dark with `var(--shadow-ops-panel-dark)` (it already gets dark `--shadow-ops-surface` via Precedent A — overriding the rule is the seated-depth swap). |
| `.ops-intent-card` | **L842–856** | `var(--shadow-ops-surface)` (L851) | Add `var(--shadow-ops-panel-dark)` in dark override. |
| `#flash-group > *` | **L1010–1013** | `var(--shadow-ops-overlay)` (L1012) | **Compose:** `var(--shadow-ops-overlay), var(--shadow-ops-panel-dark)` (keep overlay). |
| `.ops-cmdk__panel` | **L1057–1069** | `var(--shadow-ops-overlay)` (L1067) | **Compose:** keep overlay + add `var(--shadow-ops-panel-dark)`. |

### F4 — D-13 RESOLVED: `mix verify.opsui` already exists
`scrypath_ops/mix.exs:87`:
```elixir
"verify.opsui": ["test", "opsui.test_a11y"],
```
- `test` alias (L80–85): `scrypath_ops.check_nav_contract` → `ecto.create --quiet` → `ecto.migrate --quiet` → `test`.
- `opsui.test_a11y` (L86, `&opsui_test_a11y/1` at L99–104): runs nav-contract + ecto + `test --only opsui_a11y`.
- `preferred_envs` (L30) already maps `"verify.opsui": :test`.
**No alias work needed.** The UI-SPEC checklist's `mix verify.opsui` is correct as-is. Phase 130 added this (commits `4ffd8a9` + `5c13930`). Drop D-13 from open questions.

### F5 — Eyebrow slot (one-line re-style target)
`scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex:23` (path uses `scrypath_ops_web`, confirmed):
```elixir
<p class="text-ops-sm font-semibold uppercase tracking-wide text-secondary">
  Operator workspace
</p>
```
Swap the four utility classes for `.ops-copper-eyebrow`. String "Operator workspace" unchanged. This is the lone in-situ copper application 131 makes.

### F6 — Glow target selectors (both already carry box-shadows — compose)
| Selector | Live line | Current `box-shadow` | Action |
|----------|-----------|----------------------|--------|
| `.ops-route-mark` | **L994–997** | `0 0 0 1px color-mix(...primary-content 30%...) inset` (L996) | **Compose:** keep the inset ring + add `var(--shadow-ops-glow)` in dark. Do NOT drop the existing inset ring. |
| `.ops-nav-item-active` | **L584–589** | `var(--shadow-ops-surface)` (L588) | **Compose:** keep surface + add `var(--shadow-ops-glow)` in dark. |
| `.ops-intent-card--recommended` | **L866–870** | `var(--shadow-ops-surface), inset 0 0 0 1px color-mix(...primary 45%...)` (L867–869) | Light untouched (D-02a). Dark override = the 3-layer D-02 stack. |
| `.ops-shell` | **L240–244** | radial `color-mix(...primary 14%...)` to `transparent 34rem` (L242) | Mobile tune at `max-width: 640px`: 14%→10%, 34rem→28rem. |

### F7 — CRITICAL: compose, don't replace
`.ops-route-mark` (L996), `#flash-group > *` (L1012), `.ops-cmdk__panel` (L1067), and `.ops-nav-item-active` (L588) **all already have a `box-shadow`**. A dark-scoped rule that sets `box-shadow: var(--shadow-ops-glow)` would **erase** the existing shadow. Each dark override must list the existing layer(s) first, then the new layer. The UI-SPEC's panel-dark table already says "Compose: keep overlay + add…" for flash/cmdk — apply the same care to the route mark (inset ring) and active nav pill (surface lift).

### F8 — CRITICAL: copper AA is NOT machine-checked
`contrast-checker.mjs` + `contrast-pairs.mjs` only track `color: color-mix(in oklch, var(--color-base-content) NN%, transparent)` declarations (the D-15 lockstep guard scans the `color:` property for *base-content alpha mixes* only — confirmed in `contrast-checker.mjs:320–363` and the `contrast-pairs.mjs` header). The new copper classes use `color: var(--color-secondary)` / `var(--color-base-content)` / `var(--color-secondary-content)` — **raw token refs, not base-content alpha mixes** — so they will **NOT** trip the lockstep guard and will **NOT** be auto-evaluated by the fast checker. **Implication:** the 9-pairing copper AA table in the UI-SPEC is **manually/spec-verified only**; the contrast harness neither confirms nor regresses it. The planner must treat the AA table as a static design-contract assertion, not an automated gate. (The `test:e2e:admin-contrast` axe matrix WOULD catch a rendered copper violation, but only for sites actually wired up — and 131 only wires the eyebrow, which the spec says is already AA-correct.)

### F9 — `light-pixel-diff.mjs` has no npm script (invoke directly)
Invoke as `node e2e/light-pixel-diff.mjs` from `examples/scrypath_ecommerce/`. Baseline = `examples/scrypath_ecommerce/.tmp/admin-screenshots/*--light--*.png` (**20 files confirmed present**). Fresh shots default to `.tmp/pixel-diff-fresh/` (override `PIXEL_DIFF_FRESH_DIR`). Threshold is **0** (byte-exact); exits `1` on any diff or missing fresh PNG, `2` on baseline-read error, `0` on "Failed pairs: 0 / 20". Caller must re-shoot the light matrix into the fresh dir first.

## Runtime State Inventory

This is a CSS/token/doc phase with one one-line template re-style. There is **no stored data, live-service config, OS-registered state, secrets, or build artifacts** to migrate.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — no DB keys, collections, or IDs reference any token/class name. | None. |
| Live service config | None — no external service stores these CSS class names. | None. |
| OS-registered state | None. | None. |
| Secrets/env vars | None — the only env vars are test-runner overrides (`PIXEL_DIFF_FRESH_DIR`, `CONTRAST_REPORT_DIR`), not changed by this phase. | None. |
| Build artifacts | Tailwind rebuild required: `app.css` changes need `mix assets.build` (or the dev watcher) to regenerate `priv/static/assets/`. Not a rename-migration, just a normal asset compile. | Run `mix assets.build` before screenshotting for the pixel-diff gate. |

**The canonical question** ("after every file is updated, what runtime systems still have the old string?"): **Nothing** — no string is being renamed; new tokens/classes are additive, and the one re-style swaps utility classes at a single slot.

## Common Pitfalls

### Pitfall 1: Trusting the UI-SPEC/CONTEXT line numbers
**What goes wrong:** UI-SPEC cites `.ops-panel` ~L250, intent-card ~L851/866-870, route-mark ~L994, nav-active ~L584, cmdk ~L1067, flash ~L1010, form-control ~L525-533. Several have drifted (cmdk is L1057–1069, flash-group `> *` is L1010–1013, form-control precedent is L531–539, the token-redefinition precedent is L1298–1313).
**How to avoid:** Use the F1–F6 verified line numbers in this doc; grep before editing.

### Pitfall 2: Replacing instead of composing box-shadows (F7)
**What goes wrong:** Setting `box-shadow: var(--shadow-ops-glow)` on `.ops-route-mark` erases its inset ring; same for flash/cmdk overlay and active-pill surface lift.
**How to avoid:** Every dark override on an already-shadowed element lists existing layers first.

### Pitfall 3: Forgetting one of the two dark paths
**What goes wrong:** Declaring a token/rule only in `[data-theme="dark"]` breaks **system-dark** (no explicit `data-theme`), or vice versa.
**Warning signs:** Glow/depth appears with the explicit toggle but not when OS is dark (or the reverse).
**How to avoid:** Both Precedent-A token lines AND both Precedent-B rule blocks, every time.

### Pitfall 4: Assuming the contrast harness validates copper (F8)
**What goes wrong:** Planner schedules "run contrast-checker to confirm copper AA" — but the checker doesn't look at copper.
**How to avoid:** Treat the UI-SPEC 9-pairing table as a manual design assertion; the automated copper-rendering check only happens via the axe matrix on sites that are actually wired (eyebrow only in 131).

### Pitfall 5: Stale assets before pixel-diff
**What goes wrong:** Running `light-pixel-diff.mjs` against screenshots taken before `mix assets.build` recompiled `app.css` → false PASS or false FAIL.
**How to avoid:** Rebuild assets, then re-shoot the light matrix into the fresh dir, then diff.

## Code Examples

### Declaring the new dark tokens (Precedent A — append into the existing end-of-file blocks)
```css
/* app.css:1300 [data-theme="dark"] block — add: */
--shadow-ops-panel-dark: 0 0 0 1px rgba(0,0,0,0.30), 0 1px 3px rgba(0,0,0,0.45);
--shadow-ops-glow:        0 0 8px 2px rgba(108,92,231,0.30);
--shadow-ops-glow-copper: 0 0 6px 1px rgba(193,122,62,0.25);
/* …and the IDENTICAL three lines inside the @media html:not([data-theme="light"]) block at app.css:1307 */
```

### Applying panel-dark + composing (Precedent B — dark-scoped rule, both paths)
```css
[data-theme="dark"] .ops-cmdk__panel,
[data-theme="dark"] #flash-group > * {
  box-shadow: var(--shadow-ops-overlay), var(--shadow-ops-panel-dark);  /* compose, keep overlay */
}
@media (prefers-color-scheme: dark) {
  html:not([data-theme="light"]) .ops-cmdk__panel,
  html:not([data-theme="light"]) #flash-group > * {
    box-shadow: var(--shadow-ops-overlay), var(--shadow-ops-panel-dark);
  }
}
```
(Note: `.ops-panel` and `.ops-intent-card` use `--shadow-ops-surface` at rest; the planner decides per Discretion whether to fold all four panels into one shared dark-scoped selector list or keep per-selector blocks.)

### The glow class (`@layer components`)
```css
.ops-glow {
  box-shadow: var(--shadow-ops-glow);
  transition: box-shadow var(--duration-ops-fast) var(--ease-ops-standard);
}
```

### Copper classes (`@layer components`) — color refs that bypass the contrast guard (F8)
```css
.ops-copper-eyebrow {
  font-size: var(--text-ops-sm);
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  color: var(--color-secondary);            /* AA: dark 5.13:1 / light 4.84:1 on surface-1 (spec-verified) */
}
.ops-copper-badge {                          /* compose with .ops-badge for layout */
  border-color: color-mix(in oklch, var(--color-secondary) 44%, transparent);
  background:   color-mix(in oklch, var(--color-secondary) 12%, transparent);
  color: var(--color-base-content);          /* AA: dark 12.07:1 / light 14.86:1 (spec-verified) */
}
.ops-copper-node       { color: var(--color-secondary); }
.ops-copper-node--fill { color: var(--color-secondary-content); background: var(--color-secondary); }
```

## Validation Architecture

> nyquist_validation treated as ENABLED (no `.planning/config.json` override found disabling it).
> The validation strategy is the **Phase 130 D-11 proof bundle, re-run** — no new tooling. The gate splits cleanly into (a) Elixir test suite, (b) fast token-AA checker, (c) browser axe matrix, (d) light pixel-identity. Copper AA is a static spec assertion (Finding F8), NOT an automated check.

### Test Framework
| Property | Value |
|----------|-------|
| Elixir gate | `mix verify.opsui` (= `mix test` + `mix opsui.test_a11y`), `scrypath_ops/mix.exs:87`. Requires Postgres (alias runs `ecto.create/migrate`). |
| Fast AA checker | `node contrast-checker.mjs` from `examples/scrypath_ecommerce/` (reads `../../scrypath_ops/assets/css/app.css`). Exits non-zero iff `aa_fail > 0`. |
| Browser axe matrix | `npm run test:e2e:admin-contrast` (= `playwright test e2e/admin_contrast_matrix.spec.ts`). Requires a running dev server. |
| Light pixel gate | `node e2e/light-pixel-diff.mjs` from `examples/scrypath_ecommerce/`. Threshold 0, 20 light PNGs. No npm script (invoke directly). |

### Phase Requirements → Test Map
| Req / Success criterion | Behavior | Check type | Command | Expected |
|-------------------------|----------|-----------|---------|----------|
| GLOW-01 + SC-1 (seated depth, light keeps lift) | Dark panels get panel-dark; light unchanged | pixel-identity + manual | `node e2e/light-pixel-diff.mjs`; human dark-browser check | Failed pairs: **0 / 20**; dark seated-depth confirmed (perceptual — human) |
| GLOW-01 + SC-2 (glow on route/active/hover only) | `.ops-glow` applied to allowed sites only; light = none | pixel-identity + static grep | `light-pixel-diff` + grep that `--shadow-ops-glow` has `none` light default | 0/20; `none` in `@theme`; glow absent on forbidden targets |
| COPPER-01 + SC-3 (AA-safe copper vocabulary @5%) | `.ops-copper-*` declared; eyebrow re-styled; AA pairings hold | **static spec assertion (F8)** + axe (eyebrow only) | UI-SPEC 9-pairing table review; `npm run test:e2e:admin-contrast` (Cluster 1 = 0) | AA table all PASS (manual); Cluster 1 = 0 |
| Light non-regression (all changes) | No light input changed | regression | `node contrast-checker.mjs`; `light-pixel-diff` | 3 AA / 12 AAA = Phase 128 baseline; 0/20 |
| Existing UI behavior | No component/behavior change | unit | `mix verify.opsui` | 129 tests + 4 a11y, exit 0 |

### Sampling Rate
- **Per task commit:** `node contrast-checker.mjs` (sub-second) to confirm light AA count stays at 3 (no new base-content muted regressions).
- **Per wave merge:** `mix verify.opsui` (exit 0) + `node e2e/light-pixel-diff.mjs` (0/20) after `mix assets.build`.
- **Phase gate:** full D-11 bundle green: `mix verify.opsui` exit 0; `contrast-checker.mjs` 3 AA / 12 AAA (= Phase 128 baseline); `test:e2e:admin-contrast` **Cluster 1 = 0** (Cluster 3 primary-violet deferred to Phase 132); `light-pixel-diff.mjs` **Failed pairs: 0 / 20**.

### Cluster scoping (inherited from Phase 130, must not regress)
- **Cluster 1** (`.leading-4` ramp collapse): must remain **0**.
- **Cluster 3** (primary-violet `#6c5ce7` @ 4.3:1 on cream — `.ops-nav-item-active` / `.bg-primary`): **explicitly deferred to Phase 132 (A11Y-TOKEN-01)**; `test:e2e:admin-contrast` will still exit 1 on these until 132. The 131 gate is "Cluster 1 = 0", not "matrix exit 0". The planner must record Cluster 3 as out-of-scope-known-fail, exactly as 130-VERIFICATION did.

### Wave 0 Gaps
- [ ] **Pre-shoot light baseline freshness:** confirm `examples/scrypath_ecommerce/.tmp/admin-screenshots/*--light--*.png` (20 files, present) is still the canonical Jun-3 baseline post-Phase-130. If Phase 130's body-class fix changed light rendering, the baseline may need a one-time re-capture before 131 diffs against it. **Verify the baseline matches current main light render before relying on 0/20.**
- [ ] No new test files needed — all four gate scripts exist and pass `node --check` / are wired in `mix.exs`.
- [ ] Dev server + Postgres required for `mix verify.opsui` and `test:e2e:admin-contrast` (browser matrix is human/dev-server routed per 130-VERIFICATION).

## Security Domain

`security_enforcement` is not meaningfully applicable: this phase adds decorative CSS tokens and classes with **no auth, no input handling, no data flow, no network, no secrets**. The only adjacent guardrail is **T-128-03** (CSS parsed as text only, never `eval()`'d) which the existing checker already enforces — no change. ASVS V5 (Input Validation) and others are N/A. The relevant non-security hard gate is **WCAG 2.1 AA** (handled in Validation Architecture).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The Jun-3 light baseline in `.tmp/admin-screenshots/` is still valid post-Phase-130 (i.e., 130's body-class fix didn't shift light rendering). | Validation / Wave 0 | If stale, `light-pixel-diff` could false-fail or require a one-time re-baseline before 131. **Verify before relying on 0/20.** Tagged ASSUMED — Phase 130 SUMMARY says baseline was "updated post-body-class fix," which supports validity, but not re-confirmed this session. |

**All other claims** are VERIFIED against live files (line numbers, alias contents, precedent shapes, token values, gate scripts) or CITED from the UI-SPEC/ROADMAP/REQUIREMENTS/130-VERIFICATION.

## Open Questions (RESOLVED)

1. **Baseline freshness (A1)** — RESOLVED by Plan 131-01 Task 1 (the Wave-0 baseline-freshness gate runs before any `light-pixel-diff`). Recommendation: planner adds a Wave-0 step to re-shoot + re-confirm the light baseline before the first `light-pixel-diff` run, OR confirm via `git log` that `.tmp/admin-screenshots/*light*` post-dates Phase 130's last light-affecting commit.
2. **One shared panel-dark selector list vs per-selector blocks** — RESOLVED by Plan 131-02 Task 1 (Claude's-Discretion item, resolved to the recommended two grouped dark-scoped blocks). Both are pixel-safe; recommend a single grouped dark-scoped selector list for the four panels to minimize block count, with `#flash-group > *` and `.ops-cmdk__panel` kept in a composing variant (they keep `--shadow-ops-overlay`; `.ops-panel`/`.ops-intent-card` keep `--shadow-ops-surface`). The two groups have different base layers, so likely **two** grouped blocks, not one.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir / Mix | `mix verify.opsui` | assumed (project standard, `~> 1.17`) | — | — |
| PostgreSQL | `verify.opsui` ecto aliases | assumed (Phase 130 ran it) | — | — |
| Node | contrast-checker / pixel-diff | assumed (Phase 130 ran it) | — | — |
| `pixelmatch` / `pngjs` | `light-pixel-diff.mjs` | ✓ (devDeps, verified in package.json) | `pixelmatch ^5.3.0` | — |
| Playwright + dev server | `test:e2e:admin-contrast` | assumed; browser matrix is human/dev-server routed | — | Static grep substitutes (per 130-VERIFICATION pattern) |
| Light baseline PNGs | `light-pixel-diff.mjs` | ✓ 20 `*--light--*.png` present | Jun-3 | re-shoot matrix |

*Runtime probing of Elixir/Postgres/Playwright was not performed this session (sandbox); Phase 130 executed the full bundle successfully, so availability is inherited-assumed. The planner should not re-litigate these — they are the established Phase-130 substrate.*

## Sources

### Primary (HIGH confidence — live codebase, this session)
- `scrypath_ops/assets/css/app.css` — `@theme` L120–148; daisyUI `@plugin` dark L23–59 / light L61–97; `@custom-variant dark` L115; `.ops-shell` L240–244; `.ops-panel` L246–251; `.ops-badge` L418–433; `select.ops-form-control` D-10 precedent B L531–539; `.ops-nav-item-active` L584–589; `.ops-intent-card` L842–862; `--recommended` L866–870; `.ops-route-mark` L994–997; `#flash-group > *` L1010–1013; `.ops-cmdk__panel` L1057–1069; `.ops-data-card`/`.ops-result-row` dark blocks L1279–1295; D-10 token-redefinition precedent A L1298–1313.
- `scrypath_ops/mix.exs` — `verify.opsui` L87, `opsui.test_a11y` L86/L99–104, `test` L80–85, `preferred_envs` L30 (D-13 resolved).
- `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` — eyebrow slot L20–35 (target L23).
- `examples/scrypath_ecommerce/contrast-checker.mjs` — D-15 lockstep guard scope (base-content `color:` mixes only) L320–363; cross-workspace `app.css` read.
- `examples/scrypath_ecommerce/assets→/contrast-pairs.mjs` (`scrypath_ops/assets/css/contrast-pairs.mjs`) — manifest header: tracks only base-content opacity mixes.
- `examples/scrypath_ecommerce/e2e/light-pixel-diff.mjs` — threshold 0, 20 PNGs, exit contract, `.tmp/admin-screenshots/*--light--*.png` baseline (20 confirmed).
- `examples/scrypath_ecommerce/package.json` — `test:e2e:admin-contrast` script; `pixelmatch`/`pngjs` devDeps.

### Citations (design contract & upstream)
- `131-UI-SPEC.md` — token values, 9-pairing AA table, 10-step checklist, light invariants, lockstep obligations.
- `131-CONTEXT.md` — D-01..D-03, discretion areas, deferred ideas.
- `.planning/REQUIREMENTS.md` L35–37, L71–72 — GLOW-01 / COPPER-01 + traceability.
- `.planning/ROADMAP.md` L106–118, L221–228 — Phase 131 goal + 3 success criteria + ordering rationale (gate phases include 131).
- `130-VERIFICATION.md` — D-10/D-11 pattern, proof-bundle exit contracts, Cluster 1/Cluster 3 scoping precedent, baseline-updated note.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — fully in-repo, no external surface; all hex/tokens read from live `@plugin` blocks.
- Architecture (D-10 dual-path): HIGH — both precedent shapes captured verbatim with exact line numbers.
- Pitfalls / line-number drift: HIGH — every cited selector re-verified against the live 1313-line file.
- Validation architecture: HIGH for tooling/contracts (scripts read this session); MEDIUM for baseline freshness (A1, assumed valid).

**Research date:** 2026-06-04
**Valid until:** 2026-07-04 (stable; CSS/token domain. Re-verify line numbers if `app.css` is edited before planning.)
