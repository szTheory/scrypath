# Phase 133: Dark/path motion expression `[R] [G]` - Research

**Researched:** 2026-06-24
**Domain:** CSS-first ops-admin motion (Phoenix LiveView + Tailwind v4 + daisyUI), patch-safe path-expression vocabulary
**Confidence:** HIGH (all findings grounded in quoted, current repo code)

## Summary

Phase 133 ships a small, named, opt-in path-motion vocabulary for ScrypathOps and applies it only to stable JTBD anchors. The good news: every primitive the phase needs already exists and is patch-safe by construction. The motion-token authority (`--duration-ops-*` / `--ease-ops-*`), the quiet-glow vocabulary (`.ops-glow`, `--shadow-ops-glow`, `--shadow-ops-glow-copper`), the copper node primitives (`.ops-copper-node`, `.ops-copper-node--fill`), the route mark (`.ops-route-mark`), and a global `@media (prefers-reduced-motion: reduce)` neutralizer that already covers `*`, `*::before`, `*::after` are all live in `scrypath_ops/assets/css/app.css`. The component anchors (`ops_intent_card`, `ops_result_row`, `ops_object_item`, `ops_code_block`, `ops_trail`) already accept `class` and/or `:rest` global, so stable state classes and one opt-in `shimmer` attr can be added with minimal API surface.

The single phase-specific risk is LiveView patch-refire (the Phase 123 A3 failure mode). None of the candidate LiveViews use `phx-update="stream"` — confirmed by grep — which means every re-render is a full diff/patch. Search (`search_live.ex`) re-renders its entire results/merge-trace region on every `push_patch`/`handle_params` mode switch; a mount-keyframe reveal there would replay on every patch. The safe pattern, already proven by `.ops-object-item-active` (data-driven `active={...}` boolean) and the `.ops-disclosure summary::before` chevron (state-toggled `transform`), is: stable-state CSS only — `:hover`, `[data-active]`/`.is-active` driven by server state, `:has()`, persistent classes — never `animation` on mount.

**Primary recommendation:** Add an `.ops-path-*` CSS vocabulary (pseudo-element `transform: scaleX()` + opacity line-draw, copper/violet node glow on active path, hover-only code-block glint) consumed via stable state on the five existing anchors. Reuse the existing motion tokens verbatim, add zero JS hooks, add exactly one `shimmer` attr to `ops_code_block`, and prove patch-safety with a Playwright re-run/no-flicker check plus a reduced-motion check in dark AND light.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Path line-draw / reveal | CSS (`app.css`) | — | Pseudo-element `scaleX()`+opacity on stable hover/active state; no DOM/JS |
| Active-path node pulse / glow | CSS (`app.css`) | HEEx (state class) | Glow is a `box-shadow` token; the *which-node-is-active* signal is server state rendered as a class |
| Code-block hover shimmer | CSS (`app.css`) | HEEx (`shimmer` attr on `ops_code_block`) | Opt-in glint is a pseudo-element on `:hover`; the opt-in gate is one new attr |
| Route/path marker on anchors | CSS (`app.css`) | HEEx (stable class) | `.ops-route-mark` exists; new `.ops-path-*` classes added on `ops_intent_card`/`ops_object_item`/`ops_trail` |
| Patch-safety (no re-fire) | LiveView render shape | CSS (no mount animation) | All anchors render via full diff/patch (no streams); CSS must use stable state, not mount keyframes |
| Reduced-motion neutralization | CSS (global rule) | — | One existing `@media (prefers-reduced-motion: reduce)` block covers `*`/`::before`/`::after` |

## Standard Stack

No new packages. This is a CSS + HEEx-only phase on the existing stack.

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Tailwind CSS | v4 (`@theme`/`@plugin` tokens in `app.css`) | Token + utility authority | Already the project's CSS system [VERIFIED: codebase] |
| daisyUI | (bundled, `[data-theme]`) | Theme switching | Existing dark/light mechanism [VERIFIED: codebase] |
| Phoenix LiveView | (project version) | Render/patch | Existing; patch semantics are the phase risk [VERIFIED: codebase] |
| Playwright `@playwright/test` | (project version) | Focused motion proof | Existing e2e harness; supports `reducedMotion` per-context [VERIFIED: codebase] |

**Installation:** None. `## Package Legitimacy Audit` is therefore **not applicable** — Phase 133 installs no external packages.

## Architecture Patterns

### System Architecture Diagram

```
                         ┌─────────────────────────────────────────────┐
  server state           │ scrypath_ops_web/live/*.ex (LiveView)       │
  (posture, selected,    │  control_room · search · playbook           │
   active path)          │  renders anchors with STABLE STATE classes  │
                         │   active={...}  recommended={...}  class=... │
                         └───────────────┬─────────────────────────────┘
                                         │ full diff/patch (NO streams)
                                         ▼
                         ┌─────────────────────────────────────────────┐
   HEEx components       │ components/ops_ui.ex                         │
   (ops_intent_card,     │  emit class=["ops-intent-card", ...]         │
    ops_result_row,      │  + NEW: shimmer attr on ops_code_block       │
    ops_object_item,     │  + NEW: stable .ops-path-* classes           │
    ops_code_block,      └───────────────┬─────────────────────────────┘
    ops_trail)                           │ class list only — no animation trigger
                                         ▼
                         ┌─────────────────────────────────────────────┐
   CSS (app.css)         │ NEW .ops-path-* vocabulary                   │
                         │  • pseudo-element scaleX()+opacity line-draw │
                         │    fires on :hover / [active] STATE          │  ◄── stable state,
                         │  • node glow via --shadow-ops-glow[-copper]  │      never @keyframes
                         │  • code glint pseudo on :hover only          │      on mount
                         └───────────────┬─────────────────────────────┘
                                         ▼
                         ┌─────────────────────────────────────────────┐
   Global guard          │ @media (prefers-reduced-motion: reduce)      │
                         │  *, *::before, *::after → 0.01ms             │  ◄── neutralizes ALL
                         └─────────────────────────────────────────────┘      new transitions/anims
```

The decisive property: data enters as **server state → class list → CSS stable-state selector**. Motion never enters through a mount lifecycle, so a `phx-update`/`push_patch` re-render re-paints the same resting state without replaying anything.

### Existing motion tokens (REUSE verbatim) — `app.css:174-182` [VERIFIED: codebase]

```css
--duration-ops-instant: 90ms;   /* tap/press feedback */
--duration-ops-fast: 120ms;     /* hover, status/tone color shifts */
--duration-ops-standard: 180ms; /* disclosure expand, larger surfaces */
--duration-ops-slow: 240ms;     /* overlay/modal entrance only */
--duration-ops-status: 200ms;   /* status/verdict tone settle */
--ease-ops-standard: cubic-bezier(0.2, 0.8, 0.2, 1); /* ease-out: enter */
--ease-ops-out: cubic-bezier(0.16, 1, 0.3, 1);        /* stronger ease-out: overlays */
--ease-ops-in-out: cubic-bezier(0.45, 0, 0.55, 1);    /* symmetric: position toggles */
--ease-ops-exit: cubic-bezier(0.4, 0, 1, 1);          /* ease-in: crisp dismissal */
```

**Every duration is ≤ 240ms; all ≤ `--duration-ops-status` (200ms) and below are < 300ms.** For path motion use `--duration-ops-fast` (120ms, hover) or `--duration-ops-standard` (180ms, larger reveal). All four easings are non-bounce ease-out/ease-in/symmetric cubic-beziers — none overshoot (no value > 1 on the y-axis except `--ease-ops-out`'s `0.3→1` which is a clean ease-out, not a spring). **Do NOT introduce a new easing** — D-08 forbids spring/bounce/playful.

### Existing keyframes — `app.css:1248-1304` [VERIFIED: codebase]

| Keyframe | Properties animated | Notes |
|----------|---------------------|-------|
| `ops-fade-in` | `opacity 0→1` | opacity-only |
| `ops-fade-out` | `opacity 1→0` | opacity-only (exit) |
| `ops-modal-in` | `opacity` + `transform: translateY(4px) scale(0.98)→none` | transform/opacity only |
| `ops-modal-out` | mirror of modal-in (exit) | transform/opacity only |
| `ops-pulse` | `opacity 1 → 0.45 → 1` | opacity-only; used by `.ops-loading` as `infinite` — the ONLY infinite loop, and it is a loading affordance, not decoration |

All existing keyframes are transform/opacity only — Phase 133's line-draw must match this discipline (D-02c).

### Global reduced-motion neutralizer — `app.css:1306-1314` (QUOTE — D-09 relies on this) [VERIFIED: codebase]

```css
@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    transition-duration: 0.01ms !important;
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
  }
}
```

**This already covers `*::before`/`*::after`.** Any pseudo-element line-draw / glint Phase 133 adds is automatically neutralized — no local guard needed (satisfies D-09). The one caveat: it neutralizes `transition-duration` and `animation-duration`, NOT static `transform`/`opacity` end states. If a line-draw's *resting* state is `scaleX(0)` (invisible) and the *active* state is `scaleX(1)`, reduced-motion will snap between them instantly (correct — the mark still appears, just without the draw). Design the resting/active end states so the reduced-motion snap is acceptable (visible-when-active, hidden-when-not), exactly like `.ops-disclosure[open] > summary::before { transform: rotate(90deg); }` snaps under reduced motion.

### Glow / copper vocabulary as actually defined [VERIFIED: codebase]

**`.ops-glow` — `app.css:480-485`:**
```css
/* Glow opt-in: quiet violet aura via --shadow-ops-glow (none in light, faint in dark).
   Apply to route-mark, active nav pill, recommended intent-card. Never text/bg floods. */
.ops-glow {
  box-shadow: var(--shadow-ops-glow);
  transition: box-shadow var(--duration-ops-fast) var(--ease-ops-standard);
}
```

**Copper node primitives — `app.css:505-512`:**
```css
.ops-copper-node      { color: var(--color-secondary); }
.ops-copper-node--fill { color: var(--color-secondary-content); background: var(--color-secondary); }
```
Comment at `app.css:490`: *".ops-copper-badge/node/node--fill are declared here but not wired to templates until Phase 134."* — i.e. these are **declared but currently unused**; Phase 133 may be the first to wire `.ops-copper-node` to a real path/key-node. (CONTEXT D-03a expects this.)

**Glow shadow tokens — light no-op, dark values [VERIFIED: codebase]:**
- Light (`app.css:153-154`): `--shadow-ops-glow: none;` `--shadow-ops-glow-copper: none;` → **light parity is free**: glow tokens evaluate to `none` in light, so any `box-shadow: var(--shadow-ops-glow)` is invisible in light by construction (protects D-05b / light baseline).
- Dark, **hand-authored in BOTH dark paths** (`app.css:1427-1444`):
  ```css
  [data-theme="dark"] { /* and the @media (prefers-color-scheme: dark) html:not([data-theme="light"]) mirror */
    --shadow-ops-glow:        0 0 8px 2px rgba(108,92,231,0.30);  /* violet #6c5ce7 */
    --shadow-ops-glow-copper: 0 0 6px 1px rgba(193,122,62,0.25);  /* copper #c17a3e */
  }
  ```

**`[data-theme="dark"]` + system-dark media DUPLICATION pattern (MUST mirror) [VERIFIED: codebase].** Comment `app.css:1425`: *"--shadow-ops-* are @theme tokens, not daisyUI keys — must hand-author both dark paths."* Every dark override appears twice:
```css
[data-theme="dark"] .ops-route-mark { box-shadow: ...inset, var(--shadow-ops-glow); }      /* explicit */
@media (prefers-color-scheme: dark) {
  html:not([data-theme="light"]) .ops-route-mark { box-shadow: ...inset, var(--shadow-ops-glow); }  /* system */
}
```
**Any new dark-only path glow/color end state Phase 133 adds MUST be authored in both branches**, or system-dark users get the light no-op. The contrast harness (`admin_contrast_matrix.spec.ts`) explicitly tests `system-dark` as a separate cascade — so a missed mirror would be caught there only if color end states change.

**`.ops-route-mark` — `app.css:1042-1045`** (base) **+ dark glow at `app.css:1388-1395`:**
```css
.ops-route-mark {
  background: linear-gradient(135deg, var(--color-primary), var(--color-secondary));
  box-shadow: 0 0 0 1px color-mix(in oklch, var(--color-primary-content) 30%, transparent) inset;
}
/* dark adds: box-shadow: <inset ring>, var(--shadow-ops-glow); — keep the inset ring, compose glow */
```

### Existing pseudo-element pattern to MIRROR for line-draw — `app.css:668-683` [VERIFIED: codebase]

The disclosure chevron is the in-repo template for a state-toggled `transform` on a pseudo-element (no keyframe, neutralized by the global rule):
```css
.ops-disclosure summary::before {
  content: "";
  /* ...mask icon... */
  transition: transform var(--duration-ops-fast) var(--ease-ops-standard);
}
.ops-disclosure[open] > summary::before {
  transform: rotate(90deg);   /* state toggle, not @keyframes — re-paints the same on every patch */
}
```
**Mirror this for the path line-draw:** a `::before`/`::after` with `transform: scaleX(0); transform-origin: left; transition: transform <dur> <ease>, opacity ...;` whose active/hover selector sets `transform: scaleX(1); opacity: 1;`. This is patch-safe (state-driven, not mount-driven) and reduced-motion-safe (global rule) and uses transform/opacity only (D-02c).

## Component Anchor Surfaces — real attr/slot signatures [VERIFIED: codebase]

`scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex`:

| Component | Line | Relevant attrs/slots | Where Phase 133 hooks in |
|-----------|------|----------------------|--------------------------|
| `ops_trail/1` | 406 | `current` (atom), `mount_path` (string), `class` (any, default nil) | Add stable path class on `.ops-trail__current`; `class` passthrough exists. No path-state attr yet — current item already carries `.ops-trail__current` + `aria-current="page"` (line 421) |
| `ops_intent_card/1` | 496 | `icon`, `title`, `summary`, `route_label`, `navigate`, `kind`, `recommended` (bool), `rest` (`:global`, `include: data-testid`) | `recommended` already drives `.ops-intent-card--recommended` (line 503). Apply path/glow to the recommended card via that existing class — **no new attr needed**. `:rest` global allows `data-active` if wanted |
| `ops_result_row/1` | 888 | `title`, `subtitle`, `class` (any), `rest` (`:global`), slots `meta`/`actions`/`inner_block` | `class` + `:rest` passthrough — add a stable path/trace class for the merge-trace affordance. Renders `<article>` (line 890) |
| `ops_object_item/1` | 926 | `active` (bool, default false), `class` (any), slots `actions`/`inner_block` | **`active` already exists** and drives `.ops-object-item-active` (line 928). This is the Playbook active-path anchor — add path marker to `.ops-object-item-active` |
| `ops_code_block/1` | 989 | `variant` (`:default`/`:compact`/`:embedded`), `class` (any), `rest` (`:global`), slot `inner_block` | **Has NO `shimmer` attr** — D-04 requires adding one. Renders a `<pre>` (line 991). Add `attr :shimmer, :boolean, default: false` → conditional `.ops-code-block--shimmer` class. Default false (D-04 / evidence stays calm) |

**API surface impact:** exactly ONE new attr (`shimmer` on `ops_code_block`). Everything else reuses existing `class`/`:rest`/`recommended`/`active`.

## LiveView Patch-Refire Risk Surface [VERIFIED: codebase]

**No `phx-update="stream"` anywhere** in `control_room_live.ex`, `search_live.ex`, `playbook_live.ex`, `failed_sync_live.ex` (grep returned zero matches). Therefore **every re-render is a full LiveView diff/patch** of the rendered region — the exact condition that re-fires a CSS mount animation (Phase 123 A3).

**Control Room — `control_room_live.ex:91-118`:** three static `<.ops_intent_card>`; the recommended flag is data-driven (`recommended={@posture.state in [:degraded, :missing_backend]}`, line 95). A posture refresh re-renders the cards. Safe pattern: glow/path on `.ops-intent-card--recommended` is a stable-state class → re-paints identically, no re-fire. **Do NOT** add a mount reveal here.

**Search — `search_live.ex` (HIGH patch churn):** `handle_params/3` (line 70) plus `push_patch` at lines 85, 118, 128, 327, 399 switch `mode: :single | :multi` and re-render the entire results/federation region. Anchors in that region:
- Results rows `<.ops_result_row>` (line 32) — re-render on every search/mode switch.
- Merge trace disclosure (lines 1018-1054) — `summary={"Merge trace (...)"}` re-renders on every multi-search.
- Code blocks (lines 34, 1052, 1068, 1140) — evidence; **must stay calm** (D-04a/D-04c).

**WHY a mount reveal re-fires here:** a `push_patch(mode: :multi)` produces a new diff for the whole results region; LiveView patches the DOM; a CSS `animation: <reveal>` declared on those elements (or `nth-child` stagger) restarts on every patch because the element's animation re-triggers on (re)insertion/class re-apply. This is precisely A3. **Safe:** federation/merge "path through results" affordance must be `:hover` or a `[data-active]`/persistent-class state, never a list-entry animation. **D-06 forbids result-list/row reveal staggers outright.**

**Playbooks — `playbook_live.ex:927-996`:** `<.ops_object_item active={row.name == @selected_basename}>` (line 929). The active state is **derived from server assigns** — selecting a playbook re-renders the list and the active item carries `.ops-object-item-active`. This is the model anchor: a path marker keyed off `.ops-object-item-active` re-paints to the correct resting state on every patch with no replay. Preview code block (line 1054) is `variant={:compact}` — leave shimmer OFF (evidence-adjacent preview).

**Failed Sync — `failed_sync_live.ex`:** evidence code blocks; D-04c explicitly excludes from default shimmer. No path motion here.

**Safe-pattern summary:** stable-state CSS only — `:hover`, server-state classes (`.ops-object-item-active`, `.ops-intent-card--recommended`, `aria-current`), `:has()`, persistent classes. **Never** `animation` keyed to mount/insert; **never** `nth-child` stagger on patched lists.

## Line-Draw / Reveal Technique (D-02c) [VERIFIED: codebase pattern]

Confirmed patch-safe + reduced-motion-safe approach:
1. **Pseudo-element** (`::before`/`::after`) on a stable anchor, `content: ""`.
2. Resting: `transform: scaleX(0); transform-origin: left center; opacity: 0;` (or 0.0–0.5).
3. Active/hover state selector: `transform: scaleX(1); opacity: 1;`.
4. `transition: transform var(--duration-ops-fast) var(--ease-ops-standard), opacity var(--duration-ops-fast) var(--ease-ops-standard);`

**Forbidden (D-02c) — do NOT use:** SVG `stroke-dashoffset`, CSS `filter:` animation, `background-position` shimmer, or any layout property (`width`/`height`/`top`/`margin`). Mirror `.ops-disclosure summary::before` (transform-on-pseudo, state-toggled). The global reduced-motion rule already neutralizes the `transition-duration` on the pseudo-element (it covers `*::before`/`*::after`), so the mark snaps to its active end state instead of drawing — acceptable and correct.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Reduced-motion guard for new motion | Per-rule `@media (prefers-reduced-motion)` blocks | The existing global rule (`app.css:1306`) | Already covers `*`/`::before`/`::after`; a local guard is redundant unless the global one can't reach the case |
| Timing/easing values | New `ms`/cubic-bezier literals | `--duration-ops-fast`/`--duration-ops-standard` + `--ease-ops-standard` | D-08 forbids new playful easing; tokens guarantee <300ms |
| Dark glow color | New rgba shadows | `--shadow-ops-glow` / `--shadow-ops-glow-copper` | Already light-no-op + dark-valued in both theme paths |
| Active-path state plumbing | New JS hook / assigns | `active={...}` on `ops_object_item`, `recommended` on `ops_intent_card`, `aria-current` on trail | Server already computes these |
| Line-draw motion | SVG stroke-dashoffset / JS | Pseudo-element `scaleX()`+opacity (D-02c) | SVG path animation can't be neutralized by the global CSS rule and adds DOM |
| Code-block shimmer default | Enabling shimmer on `ops_code_block` | Opt-in `shimmer={true}` attr, default false | Code blocks hold evidence (D-04a/c) |

**Key insight:** Phase 133 is almost entirely *application* of an existing token/primitive system to stable state, not invention. The brand book's "line draw / node pulse / shimmer" maps onto in-repo primitives that are already reduced-motion-safe and light-parity-safe.

## Common Pitfalls

### Pitfall 1: Mount-keyframe reveal on a patched region (Phase 123 A3 re-fire)
**What goes wrong:** A `@keyframes` reveal or `nth-child` stagger on search results / merge trace replays on every `push_patch`/`handle_params` → flicker.
**Why:** No `phx-update="stream"`; full diff/patch re-renders the region and restarts CSS animations.
**How to avoid:** Stable-state CSS only (`:hover`, server-state class, `:has`). The line-draw fires on hover/active, never on insert.
**Warning signs:** Any `animation:` (vs `transition:`) on a result/merge/list element; any `nth-child` delay; visible flash on search re-run.

### Pitfall 2: Dark glow authored in only one dark path
**What goes wrong:** New dark-only glow/color works under `[data-theme="dark"]` but is invisible (light no-op) for system-dark users.
**Why:** `--shadow-ops-*` are `@theme` tokens, not daisyUI keys — both `[data-theme="dark"]` and `@media (prefers-color-scheme: dark) html:not([data-theme="light"])` must be hand-authored (`app.css:1425` comment).
**How to avoid:** Duplicate every dark-only end state into both branches. The `system-dark` lane in `admin_contrast_matrix.spec.ts` only catches it if color end states change.
**Warning signs:** Glow shows in explicit-dark screenshots but not system-dark.

### Pitfall 3: Shimmer/glow on evidence surfaces
**What goes wrong:** Animating a code block that holds a JSON payload / failed-sync reason reads as "data is changing/loading" → erodes operator trust.
**Why:** `ops_code_block` is reused for evidence (search payloads line 34, federation line 1052, failed-sync evidence).
**How to avoid:** `shimmer` default false; only opt in on non-evidence preview surfaces (D-04c). Never on Failed Sync or raw result payloads.
**Warning signs:** shimmer attr set on a code block inside Failed Sync / search results / merge trace.

### Pitfall 4: Status meaning carried by motion alone
**What goes wrong:** A pulse that *means* "active path" with no text/ARIA equivalent fails D-07 and is invisible under reduced motion.
**How to avoid:** Pair every path/node signal with existing text/ARIA state (`aria-current="page"` on trail, the `active`/`recommended` flags that already render visible labels like "Start here").

## Runtime State Inventory

Not applicable — Phase 133 is a greenfield CSS/HEEx visual addition. No rename, no stored data, no service/OS/secret/build-artifact state is touched. (Verified: no string-rename in scope; new classes are additive.)

## Validation Architecture

> Nyquist enabled (`config.json: workflow.nyquist_validation: true`). D-05 proof bundle is LOCKED.

### Test Framework
| Property | Value |
|----------|-------|
| Elixir/LiveView gate | `mix verify.opsui` (root) → `cd scrypath_ops && CI=true mix deps.get && mix test` ([VERIFIED: `lib/mix/tasks/verify.opsui.ex`]) |
| Browser framework | Playwright `@playwright/test`, config `examples/scrypath_ecommerce/playwright.config.ts` |
| baseURL | `process.env.PLAYWRIGHT_BASE_URL || "http://127.0.0.1:4002"` (line 9) — **no `webServer` block**: server is booted manually (the screenshot-matrix / p124 pattern) [VERIFIED] |
| Reduced-motion | Playwright per-context `reducedMotion: 'reduce'` (proven in Phase 123 gate) or `page.emulateMedia({ reducedMotion: 'reduce' })` — **no existing helper**, planner adds inline |
| Theme set | `context.addInitScript(... localStorage["phx:theme"] = theme)` before first paint (matrix lines 60-65); system-dark via `newContext({ colorScheme: 'dark' })` with NO `phx:theme` write |
| Live-ready gate | `waitForLiveConnected(page)` (helpers/e2e.ts:11) before any interaction |
| Seeding | `seedScenario(request, scenario)` → `/dev/e2e/seed` (helpers/e2e.ts:99); scenarios `all_green` / `incident` / `empty` |

### Static CSS asserts (transform/opacity-only + tokenized <300ms)
Grep/lint over `app.css` new `.ops-path-*` rules:
- Assert new motion uses only `transform` / `opacity` (no `width`/`height`/`top`/`left`/`margin`/`filter`/`background-position`/`stroke-dashoffset` inside the new blocks).
- Assert every new `transition`/`animation` duration is a `--duration-ops-*` token (all ≤ 240ms < 300ms), not a raw literal.
- Assert every new dark-only color/glow end state appears in BOTH `[data-theme="dark"]` and the `@media (prefers-color-scheme: dark)` mirror.
- Can be a `mix test` assertion that reads the compiled CSS, or a node/grep check in the e2e lane.

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DARKMOTION-01 | Ops/LiveView tests stay green after CSS/component change | unit/integration | `mix verify.opsui` | ✅ |
| DARKMOTION-01 | Asset rebuild + host compile clean | build | ops asset build + ecommerce host compile (Docker DX lane) | ✅ harness pattern |
| DARKMOTION-01 | New motion is transform/opacity + tokenized <300ms | static | CSS-assert step (new) over `app.css` | ❌ Wave 0 |
| DARKMOTION-01 | Each shipped site reduced-motion-neutralized (dark AND light) | e2e | new focused spec w/ `reducedMotion: 'reduce'` asserting computed `transition/animation-duration ≈ 0.01ms` or end-state-snap | ❌ Wave 0 |
| DARKMOTION-01 | Hover code shimmer + active-path trace/node pulse render (dark AND light) | e2e | new focused spec: hover code block, select playbook, recommended card | ❌ Wave 0 |
| DARKMOTION-01 | LiveView patch/re-run does NOT re-fire / flicker | e2e | new focused spec: run search → `push_patch` mode switch → assert no animation restart on anchors | ❌ Wave 0 |
| DARKMOTION-01 | Targeted screenshot set for affected surfaces | e2e | reuse `admin_screenshot_matrix.spec.ts` shoot helper at rest/interaction endpoints (subset) | ✅ reuse |
| DARKMOTION-01 (D-05b only-if) | Color-bearing glow/shimmer end states keep AA | e2e | `admin_contrast_matrix.spec.ts` / `light-pixel-diff.mjs` — ONLY if end-state colors change | ✅ conditional |

### Proving "no patch-refire" concretely
1. Navigate to Search, `waitForLiveConnected`, run a bounded search (`all_green` + `quantum`, per matrix line 187).
2. Attach a JS observer (e.g. `getAnimations()` on the anchor, or an `animationstart` event counter) before triggering a `push_patch` (toggle single↔multi mode).
3. Trigger the patch; assert the anchor's running-animation count does NOT increment (path motion is `transition`/state-driven, not `animation` on insert) and no visible opacity flash on the merge-trace region.
4. Equivalent for Playbooks: select playbook A then B; assert the active marker moves via stable-state class without a re-played reveal.

### Proving reduced-motion neutralization
With `reducedMotion: 'reduce'`, on each shipped site assert the new pseudo-element/anchor computes `transition-duration`/`animation-duration` ≈ `0.01ms` (the global rule) and the active state is still visually present (functional integrity — the mark/glow shows, it just doesn't draw). Run in both `phx:theme=dark` and `phx:theme=light`.

### Sampling Rate
- **Per task commit:** `mix verify.opsui` (fast Elixir/LiveView green).
- **Per wave merge:** focused Playwright spec (reduced-motion + interaction + patch-refire, dark+light) against a booted seeded server.
- **Phase gate:** full `mix verify.opsui` green + focused spec green + targeted screenshots reviewed before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] New focused Playwright spec (e.g. `e2e/admin_path_motion.spec.ts`) — reduced-motion + hover-shimmer + active-path + patch-refire, dark AND light. Reuse `waitForLiveConnected`, `seedScenario`, `addInitScript(phx:theme)`, and a new inline `reducedMotion`/`getAnimations` helper.
- [ ] Static CSS-assert step over new `app.css` blocks (transform/opacity-only + token-duration + dual-dark-path).
- [ ] (Conditional) only wire `admin_contrast_matrix.spec.ts` / `light-pixel-diff.mjs` if Phase 133 changes color-bearing end states (D-05b) — otherwise skip (motion gate ≠ contrast gate).

## Security Domain

Not applicable in the threat sense — Phase 133 adds presentational CSS classes and one boolean HEEx attr with no auth, input, crypto, or data-flow surface. V5 Input Validation: the new `shimmer` attr is a compile-time boolean (Phoenix `attr` typed), not user input. No ASVS category is materially engaged. (If `security_enforcement` is enabled, this section documents the explicit non-applicability rather than omitting.)

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| CSS-only result reveal/stagger | Stable-state CSS only; reveal gating needs forbidden JS hook | Phase 123 (A3 rejection) | Phase 133 must NOT re-attempt reveal staggers |
| Per-rule reduced-motion guards | One global `*`/`::before`/`::after` neutralizer | pre-123 | New pseudo-element motion is auto-covered |
| Copper node primitives declared, unwired | Phase 133 first wires `.ops-copper-node` to active path/key-node | this phase | Consumes Phase 131's reserved vocabulary |

**Deprecated/outdated:** SVG `stroke-dashoffset` line-draw and `background-position` shimmer are explicitly out (D-02c) — they cannot be neutralized by the global CSS rule and/or animate non-transform/opacity properties.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Playwright server is booted manually (no `webServer` in config) and tests run against `:4002` or `PLAYWRIGHT_BASE_URL` | Validation Architecture | Low — confirmed config has no `webServer`; matches Docker DX memory. If a CI runner adds one, the spec command is unchanged |
| A2 | `getAnimations()`/`animationstart` is a reliable "did motion re-fire?" probe for the patch-refire test | Validation Architecture | Low — standard DOM API; if path motion is pure `transition` (recommended), there are no animations to count, which is itself the proof. Planner may instead assert no opacity flash via screenshot/`toHaveCSS` |

*Two assumptions, both low-risk and about test mechanics, not about the implementation surface (which is fully grounded in quoted code).*

## CONTEXT.md ↔ Code Reconciliation (flagged mismatches)

| CONTEXT claim | Code reality | Action for planner |
|---------------|--------------|--------------------|
| `.ops-copper-node`/`--fill` are "reserved Phase 131 node primitives Phase 133 can now apply" | True, but they are **declared-and-currently-unused** (`app.css:490` comment says "not wired to templates until Phase 134") | Phase 133 may be the FIRST consumer — fine, but expect to add the class to real DOM, not just style an existing usage |
| Code-block shimmer via `shimmer={true}` API or `.ops-code-block--shimmer` class | `ops_code_block/1` has **no `shimmer` attr today** (`ops_ui.ex:984-987`) | Planner must ADD `attr :shimmer, :boolean, default: false` and the conditional class |
| Phase 133 should use existing keyframes `ops-fade-in`, `ops-pulse`, etc. | They exist (`app.css:1248-1304`) but are all mount/loop reveals — **not directly reusable for path line-draw** (those re-fire on patch) | Use them only as the *style template* (transform/opacity discipline); implement line-draw as a state-driven `transition` on a pseudo-element instead |
| Anchors `ops_trail`, `ops_intent_card`, `ops_result_row`, `ops_object_item` "where stable path/active-state classes can be added" | Confirmed: all accept `class`; `ops_object_item` has `active`, `ops_intent_card` has `recommended` | No new state attrs needed except code-block `shimmer` |
| "breadcrumb/current path" optional anchor | `.ops-trail__current` + `aria-current="page"` exist (`ops_ui.ex:421`) | A stable-state path mark on `.ops-trail__current` is patch-safe |

No CONTEXT claim contradicts the code in a blocking way; the only real gap is the (expected) missing `shimmer` attr, which D-04 already anticipates adding.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/Mix + `scrypath_ops` deps | `mix verify.opsui` | ✓ (project) | — | — |
| Booted ops server on `:4002` (or compose dev lane) | Playwright focused spec | ✓ via Docker DX lane | — | `PLAYWRIGHT_BASE_URL` to a free WEB_PORT lane (see Docker multi-project memory) |
| `@playwright/test` + browsers | focused motion spec | ✓ (e2e dir) | — | — |
| `/dev/e2e/seed` endpoint | `seedScenario` | ✓ (SEED-01) | — | — |

**No blocking missing dependencies.** Note (from project memory): base compose boots a STALE baked image — rebuild ops assets / use `compose.dev.yaml --no-deps` so the focused spec runs against current source, not the old baked code.

## Sources

### Primary (HIGH confidence — codebase, quoted)
- `scrypath_ops/assets/css/app.css` — motion tokens (174-182), keyframes (1248-1304), reduced-motion (1306-1314), glow/copper (480-512, 1388-1444), pseudo-element pattern (668-683), anchors (711-729, 888-982, 1042-1045)
- `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` — anchor signatures (406, 496, 888, 926, 989)
- `scrypath_ops/lib/scrypath_ops_web/live/{control_room,search,playbook,failed_sync}_live.ex` — render anchors + patch surfaces; grep confirms no `phx-update="stream"`
- `lib/mix/tasks/verify.opsui.ex` — gate command
- `examples/scrypath_ecommerce/e2e/{admin_screenshot_matrix,admin_contrast_matrix,p124_after}.spec.ts`, `helpers/e2e.ts`, `playwright.config.ts` — harness patterns
- `scrypath_ops/assets/css/DESIGN-TOKENS.md` (238-271), `.planning/STATE.md` (line 78) — A3 precedent

### Secondary / Tertiary
- None — all findings verified against current repo code.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new packages; existing tokens/primitives quoted.
- Architecture / patch-safety: HIGH — `phx-update="stream"` absence and A3 precedent both verified.
- Pitfalls: HIGH — each grounded in a quoted code/comment or the A3 history.
- Validation: HIGH for harness reuse; the two test-mechanics assumptions are logged.

**Research date:** 2026-06-24
**Valid until:** 2026-07-24 (stable; re-verify only if `app.css` motion section or the LiveView render shapes change)
