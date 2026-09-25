# Phase 133: Dark/path motion expression `[R] [G]` - Pattern Map

**Mapped:** 2026-06-24
**Files analyzed:** 5 (4 modified, 1 created)
**Analogs found:** 5 / 5 (all in-repo, all verified against current code)

> This is a CSS-first, visual-only phase. Almost every target file is **MODIFIED**, not created.
> Phase 133 is **application of an existing token/primitive system to stable state**, not invention.
> The closest analogs all live in the same files being modified — the planner should mirror the
> exact in-file precedent rather than reach for a remote template.

## File Classification

| Target File | New/Mod | Role | Data Flow | Closest Analog | Match Quality |
|-------------|---------|------|-----------|----------------|---------------|
| `scrypath_ops/assets/css/app.css` | MODIFIED | config (design-system CSS) | transform (stable-state) | `.ops-disclosure summary::before` + `.ops-glow` + `.ops-route-mark` (same file) | exact (in-file precedent) |
| `scrypath_ops/assets/css/DESIGN-TOKENS.md` | MODIFIED | config (docs) | n/a | Phase 123 A1/A2/A3/A4 entries (same file, lines 242-279) | exact |
| `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` | MODIFIED | component | request-response (render) | `ops_object_item/1` `active` bool + `ops_disclosure` `open` bool (same file) | exact (in-file precedent) |
| `examples/scrypath_ecommerce/e2e/admin_path_motion.spec.ts` | CREATED | test (e2e) | event-driven (browser) | `admin_screenshot_matrix.spec.ts` + `helpers/e2e.ts` | role+flow match |
| `lib/mix/tasks/verify.opsui.ex` | MODIFIED (optional) | test (gate) | batch | self (existing task) — static CSS assert is additive | partial (no static-CSS analog exists) |

---

## Pattern Assignments

### `scrypath_ops/assets/css/app.css` (config, transform/opacity stable-state)

This file is the home of the new `.ops-path-*` vocabulary. There are FOUR in-file precedents to mirror — quote each into the relevant plan action.

#### Precedent A — state-toggled `transform` on a pseudo-element (THE line-draw template)
**Analog:** `.ops-disclosure summary::before` — `app.css:668-683`
```css
.ops-disclosure summary::before {
  content: "";
  /* ...mask icon, sizing... */
  transition: transform var(--duration-ops-fast) var(--ease-ops-standard);
}
.ops-disclosure[open] > summary::before {
  transform: rotate(90deg);   /* STATE toggle — not @keyframes; re-paints identically on every patch */
}
```
**New `.ops-path-*` line-draw must copy this shape exactly:** a `::before`/`::after` with
`content: ""; transform: scaleX(0); transform-origin: left center; opacity: 0; transition: transform var(--duration-ops-fast) var(--ease-ops-standard), opacity var(--duration-ops-fast) var(--ease-ops-standard);`
and an active/hover selector that sets `transform: scaleX(1); opacity: 1;`. State-driven `transition`, NEVER `animation` on mount (D-02c, patch-safe per A3). The global reduced-motion rule already neutralizes it (snaps visible-when-active).

#### Precedent B — quiet glow opt-in via box-shadow token
**Analog:** `.ops-glow` — `app.css:480-485`
```css
/* Glow opt-in: quiet violet aura via --shadow-ops-glow (none in light, faint in dark).
   Apply to route-mark, active nav pill, recommended intent-card. Never text/bg floods. */
.ops-glow {
  box-shadow: var(--shadow-ops-glow);
  transition: box-shadow var(--duration-ops-fast) var(--ease-ops-standard);
}
```
**New node/path glow copies this:** `box-shadow: var(--shadow-ops-glow)` (violet, route/path emphasis) or `var(--shadow-ops-glow-copper)` (key node, D-03a), transitioned with the existing token. Light is free (`--shadow-ops-glow: none` in light, `app.css:153-154`).

#### Precedent C — copper node primitives to WIRE (currently declared-but-unused)
**Analog:** `.ops-copper-node` / `.ops-copper-node--fill` — `app.css:505-512`
```css
.ops-copper-node      { color: var(--color-secondary); }
.ops-copper-node--fill { color: var(--color-secondary-content); background: var(--color-secondary); }
```
**Comment at `app.css:490` says these are "not wired to templates until Phase 134."** Phase 133 may be the FIRST consumer — expect to attach the class to real DOM for an active key-node, not just restyle an existing usage (D-03a).

#### Precedent D — route-mark base + composed-glow pattern
**Analog:** `.ops-route-mark` — `app.css:1042-1045` (base)
```css
.ops-route-mark {
  background: linear-gradient(135deg, var(--color-primary), var(--color-secondary));
  box-shadow: 0 0 0 1px color-mix(in oklch, var(--color-primary-content) 30%, transparent) inset;
}
```
Dark variant (per research `app.css:1388-1395`) keeps the inset ring and COMPOSES `var(--shadow-ops-glow)` onto the same `box-shadow`. New active-path marks that need dark glow must follow this compose pattern.

#### Reduced-motion guard (DO NOT duplicate — rely on global)
**Analog:** `app.css:1306-1314`
```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    transition-duration: 0.01ms !important;
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
  }
}
```
Covers `*::before`/`*::after` already → every new pseudo-element transition is auto-neutralized (D-09). **No local guard needed.** Design resting/active end states so the snap is acceptable (visible-when-active, hidden-when-not).

#### Keyframe discipline reference (style template ONLY — do not reuse for line-draw)
**Analog:** `app.css:1248-1304` (`ops-fade-in`, `ops-pulse`, `ops-modal-in/out`, `ops-fade-out`) — all transform/opacity-only. Use as the *discipline* template. **Do NOT** drive the path line-draw with these `@keyframes` (they re-fire on LiveView patch — the A3 failure mode). Use a state-driven `transition` (Precedent A) instead.

#### Dual-dark-path mirror (MANDATORY if a new dark-only color/glow end state is added)
Per research `app.css:1425-1444`: `--shadow-ops-*` are `@theme` tokens, not daisyUI keys. Every dark-only end state must be hand-authored in BOTH:
```css
[data-theme="dark"] .ops-path-... { /* ...glow... */ }
@media (prefers-color-scheme: dark) {
  html:not([data-theme="light"]) .ops-path-... { /* same glow */ }
}
```
Miss the system-dark mirror → system-dark users get the light no-op. Only `admin_contrast_matrix.spec.ts`'s system-dark lane catches it, and only if color end states change.

---

### `scrypath_ops/assets/css/DESIGN-TOKENS.md` (config, docs)

**Analog:** Phase 123 motion entries in the same file — `DESIGN-TOKENS.md:242-279`

Mirror the existing A1/A2/A3/A4 documentation cadence. Each entry: named rule, the tokens it uses, what it's applied to, and the restraint boundary. The A3 entry (lines 269-272) is the precedent for documenting a *deliberately-not-shipped* boundary — replicate that voice for the new path-motion vocabulary (e.g. "no result-list reveal stagger," "shimmer never on evidence").

Existing motion-table shape to extend (lines 274-279):
```markdown
| Animate | Never animate |
| --- | --- |
| disclosure chevron rotate + body opacity fade | layout/reflow: width, height, margin, top/left |
| button press scale, card hover lift (transform) | table row insertion / sort |
```
Add the new path-line-draw / node-glow / hover-glint rows to the "Animate" column and the forbidden techniques (SVG `stroke-dashoffset`, `background-position` shimmer, `filter`) to "Never animate."

---

### `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` (component, request-response)

#### New attr — `shimmer` on `ops_code_block/1` (the ONLY new API in the phase)
**Target:** `ops_code_block/1` — `ops_ui.ex:983-1002` (current: NO `shimmer` attr)
**Boolean-attr analog (copy this pattern):** `ops_object_item/1` `active` — `ops_ui.ex:926-928`
```elixir
attr(:active, :boolean, default: false)
# ...
<div class={["ops-object-item", @active && "ops-object-item-active", @class]}>
```
Also `ops_disclosure` uses `attr(:open, :boolean, default: false)` (`ops_ui.ex:943`).

**Apply to `ops_code_block`:** add `attr(:shimmer, :boolean, default: false)` and a conditional class on the `<pre>`:
```elixir
attr(:variant, :atom, default: :default, values: [:default, :compact, :embedded])
attr(:shimmer, :boolean, default: false)   # NEW — opt-in hover glint, default OFF (evidence stays calm, D-04)
attr(:class, :any, default: nil)
attr(:rest, :global)
# ...
<pre class={[
  "overflow-auto rounded-ops-md font-mono ...",
  @variant == :default && "max-h-96 bg-ops-surface-2 p-ops-3",
  # ...
  @shimmer && "ops-code-block--shimmer",   # NEW conditional
  @class
]} {@rest}>{render_slot(@inner_block)}</pre>
```
Default `false` is load-bearing: code blocks hold evidence (D-04a/c — search payloads, failed-sync reasons). Never set `shimmer={true}` on Failed Sync or raw result payloads.

#### Stable path/active-state classes — NO new attrs needed
The other four anchors already expose the state Phase 133 needs:

| Anchor | Line | Existing state hook | How Phase 133 uses it |
|--------|------|--------------------|----------------------|
| `ops_object_item/1` | `ops_ui.ex:926-928` | `active` bool → `.ops-object-item-active` | Playbook active-path marker keys off `.ops-object-item-active` (re-paints to correct resting state on patch — model anchor) |
| `ops_intent_card/1` | `ops_ui.ex:496-516` | `recommended` bool → `.ops-intent-card--recommended` (line 503) | Control Room glow/path on the recommended card via existing class — no new attr |
| `ops_trail/1` | `ops_ui.ex:406-428` | `.ops-trail__current` + `aria-current="page"` (line 421) | Stable path mark on `.ops-trail__current` (optional anchor) |
| `ops_result_row/1` | `ops_ui.ex:888` | `class` + `:rest` passthrough | Stable trace class on the merge-trace affordance — `:hover`/persistent only, NEVER list-entry animation (D-06) |

All four accept `class` passthrough; `ops_intent_card`/`ops_result_row`/`ops_code_block` also have `:global` `:rest` (a `data-active` is possible if wanted). **Net API impact: exactly one new attr.**

---

### `examples/scrypath_ecommerce/e2e/admin_path_motion.spec.ts` (test, event-driven) — CREATED

**Analog:** `admin_screenshot_matrix.spec.ts` + `helpers/e2e.ts`

**Imports / helper reuse** (`admin_screenshot_matrix.spec.ts:19-29`):
```typescript
import { expect, test, type Browser, type Page } from "@playwright/test";
import { drainSearchQueue, seedScenario, waitForLiveConnected, type SeedScenario } from "./helpers/e2e";
```

**Theme-before-first-paint pattern (copy)** (`admin_screenshot_matrix.spec.ts:59-67`):
```typescript
const context = await browser.newContext({ viewport: VIEWPORTS[viewport] });
await context.addInitScript(
  ([key, value]) => { window.localStorage.setItem(key, value); },
  ["phx:theme", theme]   // "light" | "dark"; system-dark = newContext({ colorScheme: 'dark' }) with NO phx:theme write
);
const page = await context.newPage();
```

**Live-ready + seed gates (copy)** — `helpers/e2e.ts:11` and `:99`:
```typescript
await waitForLiveConnected(page);                 // window.liveSocket.isConnected()
await seedScenario(request, "all_green");         // POST /dev/e2e/seed; scenarios: all_green | degraded | incident | empty
```

**NEW inline helpers (no existing analog — planner adds inline):**
- Reduced-motion: `await context.newContext({ reducedMotion: 'reduce' })` or `await page.emulateMedia({ reducedMotion: 'reduce' })`, then assert each shipped anchor computes `transition-duration`/`animation-duration` ≈ `0.01ms` and the active state is still visually present.
- Patch-refire probe: attach `getAnimations()` count / `animationstart` counter on the anchor BEFORE triggering a `push_patch` (toggle Search single↔multi mode), then assert the running-animation count does NOT increment and no opacity flash on the merge-trace region. (If motion is pure `transition`, there are zero animations to count — itself the proof.)

**Coverage the spec must hit (D-05/D-05a):** each shipped DARKMOTION-01 site in dark AND light — hover code-shimmer, active-path trace/node pulse, recommended intent card — plus at least one LiveView patch/re-run (Search mode switch; Playbook A→B selection).

---

### `lib/mix/tasks/verify.opsui.ex` (test gate, batch) — MODIFIED (optional)

**Analog:** the task itself (`verify.opsui.ex:24-49`) — it shells `cd scrypath_ops && mix deps.get && mix test`. There is **no existing static-CSS-assert analog in the repo**; this is net-new (see "No Analog Found").

The static CSS check (transform/opacity-only + token-duration + dual-dark-path over new `.ops-path-*` blocks) can live as either a `mix test` assertion that reads the compiled CSS, or a node/grep step in the e2e lane (research §"Static CSS asserts"). The planner chooses placement; this file is only touched if the assert is wired into the root gate.

---

## Shared Patterns

### Motion tokens (REUSE verbatim — never new literals)
**Source:** `app.css:174-182`
**Apply to:** every new `transition` in `.ops-path-*`
```css
--duration-ops-fast: 120ms;     /* hover, path line-draw */
--duration-ops-standard: 180ms; /* larger reveal */
--ease-ops-standard: cubic-bezier(0.2, 0.8, 0.2, 1); /* ease-out, non-bounce */
```
All durations ≤ 240ms (< 300ms). Do NOT introduce a new easing (D-08 forbids spring/bounce).

### Glow tokens (light no-op, dark-valued in both paths)
**Source:** `app.css:153-154` (light `none`) + dark `1427-1444` (per research)
**Apply to:** all node/path glow end states
```css
--shadow-ops-glow:        0 0 8px 2px rgba(108,92,231,0.30);  /* violet — route/path emphasis */
--shadow-ops-glow-copper: 0 0 6px 1px rgba(193,122,62,0.25);  /* copper — key node (D-03a) */
```
Light parity is free; any dark-only addition must be mirrored into the system-dark branch.

### Reduced-motion neutralization
**Source:** `app.css:1306-1314` (global `*`/`::before`/`::after`)
**Apply to:** all new motion — no per-rule guard needed (D-09 satisfied by the global rule).

### Server-state → class → CSS stable-state selector (patch-safety contract)
**Source:** `.ops-object-item-active` (object_item `active`), `.ops-intent-card--recommended`, `aria-current="page"` (trail)
**Apply to:** every active-path/node signal. Motion enters via `:hover` / server-state class / `:has()` / persistent class — NEVER an `animation` on mount/insert, NEVER `nth-child` stagger (D-06). Pair every motion signal with text/ARIA state (D-07).

---

## No Analog Found

| File / concern | Role | Data Flow | Reason |
|----------------|------|-----------|--------|
| Static CSS-assert step (transform/opacity-only + token-duration + dual-dark-path over `.ops-path-*`) | test (static) | batch | No existing static-CSS lint/assert in the repo. Net-new; planner picks `mix test` reading compiled CSS vs. node/grep in e2e lane (research §Validation). |
| Inline `reducedMotion` / `getAnimations` patch-refire helper | test helper | event-driven | `helpers/e2e.ts` has no reduced-motion or animation-probe helper. Planner adds inline (research Assumptions A2; logged low-risk). |

Everything else maps cleanly onto in-repo, in-file precedents — there is no implementation surface here that needs RESEARCH.md fallback patterns.

## Metadata

**Analog search scope:** `scrypath_ops/assets/css/app.css`, `scrypath_ops/assets/css/DESIGN-TOKENS.md`, `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex`, `examples/scrypath_ecommerce/e2e/` (+ `helpers/e2e.ts`), `lib/mix/tasks/verify.opsui.ex`
**Files scanned:** 6 (all read directly and line-verified)
**Pattern extraction date:** 2026-06-24
**Note:** RESEARCH.md was already grounded in quoted, current code; every line citation above was re-verified against the live files during mapping.
