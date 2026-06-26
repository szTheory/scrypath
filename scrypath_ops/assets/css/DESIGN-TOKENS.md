# ScrypathOps design tokens

The brand + design-system contract for the `/ops` operator shell. Tokens live in the
`@theme` block of [`app.css`](./app.css); the `.ops-*` component classes in the same
file consume them. This doc is the catalog — change a value here only by changing it in
`app.css`.

## Two governing laws

1. **Prefix convention.** daisyUI classnames stay **unprefixed** (`btn`, `select`,
   `input`, `table`, `modal`, `checkbox`). Custom classes are **`.ops-`** BEM-ish
   (`.ops-block`, `.ops-block-modifier`, `.ops-block__element`). Never mix the two
   namespaces for the same concept.
2. **Component class vs utility.** Put a value in a **`.ops-*` component class** when it
   is intrinsic to a reusable surface/control's identity (panel padding, control height,
   badge radius, transition timing, focus ring). Put it in a **utility**
   (`p-ops-*`, `gap-ops-*`, `text-ops-*`, `rounded-ops-*`, `shadow-ops-*`) when it is
   compositional layout applied per-instance. **Never** hardcode a raw Tailwind step
   (`p-4`, `text-2xl`, `rounded-md`, `shadow-sm`) when an `-ops-` equivalent exists.

> Tailwind v4 auto-generates utilities only from recognized `@theme` namespaces:
> `--spacing-*`→`p-/m-/gap-/space-y-`, `--text-*`→`text-`, `--radius-*`→`rounded-`,
> `--shadow-*`→`shadow-`, `--ease-*`→`ease-`, `--leading-*`→`leading-`, `--z-index-*`→`z-`.
> `--control-*` and `--duration-*` have **no** utility namespace and are component-only
> (consumed via `var()`).

## Brand colors

daisyUI semantic tokens, two themes (light default, dark via `prefers-dark` / explicit
`data-theme="dark"`). Generate utilities like `bg-primary`, `text-base-content`, `border-base-300`.

| Token | Light | Dark | Use |
| --- | --- | --- | --- |
| `primary` | `#5b4ad1` | `#6c5ce7` | brand/accent, active nav, primary actions |
| `--color-primary-strong` | `#5b4ad1` | `#5b4ad1` | text-bearing selected fills only; see Phase 132 floor |
| `secondary` | `#a85d2e` | `#c17a3e` | warm accent, eyebrow labels |
| `accent` | `#6c5ce7` | `#5b4ad1` | gradient partner (route mark) |
| `base-100` | `#fffdf8` | `#141923` | surfaces |
| `base-200` | `#faf7f2` | `#0c0f14` | app background, muted panels |
| `base-300` | `#ded8ce` | `#2a3446` | borders, dividers |
| `base-content` | `#141923` | `#f4f1ea` | text |
| `info` / `success` / `warning` / `error` | `#5ca9e6` / `#4fae74` / `#d9a441` / `#d96262` | (same hues) | status semantics |

## A11y contrast floors -- Phase 132

AA contrast is the hard gate for the operator UI. Body and long-form AAA status is
advisory/report-only; AAA findings should stay visible in reports, but AA failures block
the contrast gate.

| Token | Light | Dark | Consumers |
| --- | --- | --- | --- |
| `--ops-text-muted` | `color-mix(in oklch, var(--color-base-content) 64%, transparent)` | `color-mix(in oklch, var(--color-base-content) 64%, transparent)` | `.ops-header .text-base-content/60`, `.ops-shell .text-base-content/60`, `.ops-text-meta`, `.ops-trail__crumb`, `.ops-handoff__hint`, `.ops-preflight__hint`, `.ops-cmdk__item-hint`, `.ops-cmdk__empty` |
| `--color-primary-strong` | `#5b4ad1` | `#5b4ad1` | `.ops-nav-item-active`, `.bg-primary.text-primary-content` |

`--ops-text-muted` is the named readable-muted floor. Do not reintroduce raw
`color-mix(in oklch, var(--color-base-content) NN%, transparent)` declarations for
the consumers above. `contrast-pairs.mjs` entries that use `css_var: "ops-text-muted"`
remain part of the D-15 lockstep contract: the manifest selector, token name, and
`64%` alpha must match `app.css`.

`--color-primary-strong` is allowed only for text-bearing interactive/selected fills:
`.ops-nav-item-active` and `.bg-primary.text-primary-content`. Decorative primary and
accent recipes stay on `--color-primary` / `--color-accent` so the violet brand wash,
glow, borders, focus, and route-mark treatments are not globally retuned.

## Elevation surfaces — `--ops-bg`, `--ops-surface-1`, `--ops-surface-2`

Named elevation tokens declared in the daisyUI `@plugin` blocks (dark + light). The plugin
spreads them to both `[data-theme="dark"]` and `@media (prefers-color-scheme: dark)` for
free. Ramp direction in dark: bg (floor) → surface-1 (resting panel) → surface-2 (raised).

| Token | Light value | Dark value | Use |
| --- | --- | --- | --- |
| `--ops-bg` | `#faf7f2` | `#0c0f14` | Page floor / Night — app background |
| `--ops-surface-1` | `#fffdf8` | `#141923` | Resting panel / Ink — `.ops-panel`, `.ops-surface-flat`, `.ops-preflight__card` |
| `--ops-surface-2` | `#faf7f2` | `#1b2230` | Raised / muted step — `.ops-muted-panel`, `.ops-disclosure`, `.ops-nav-list`, `.ops-kbd`, `.ops-verdict-neutral`, `.ops-preflight__card--locked` |

Dark 4-step midnight ramp: `#0C0F14` (bg) → `#141923` (surface-1) → `#1B2230` (surface-2) → `#2A3446` (base-300 / borders).
Light values are byte-identical to the prior `base-200`/`base-100` references — zero light regression.

## Spacing — `--spacing-ops-*` → `p-ops-*` / `gap-ops-*` / `space-y-ops-*`

| Token | Value | Use |
| --- | --- | --- |
| `--spacing-ops-1..6` | 0.25 → 1.5rem | raw steps |
| `--spacing-ops-field` | 0.375rem | label↔input gap (`space-y-ops-field`) |
| `--spacing-ops-row` | 1rem | between list items |
| `--spacing-ops-section` | 1.5rem | between major page sections |
| `--spacing-ops-panel` | 1.25rem | panel interior padding (`p-ops-panel`) |
| `--spacing-ops-control-gap` | 0.5rem | gap between adjacent controls |
| `--spacing-ops-page-gap` | 1.5rem | top-level page section gap |

**Page rhythm:** the `:ops` shell wraps page content in `space-y-4`; do **not** add `mt-*`
to its direct children (that double-spaces them). Use the container gap.

## Control sizing — `--control-*` (component-only, via `var()`)

| Token | Value | Use |
| --- | --- | --- |
| `--control-h-xs` | 1.75rem | compact disclosure summaries, dense chips, journey home |
| `--control-h-sm` | 2.25rem | segmented buttons, checkbox rows |
| `--control-h-md` | 2.5rem | **default** — inputs, selects, nav items, buttons (`.ops-btn`, `.ops-form-control`) |
| `--control-h-lg` | 2.75rem | prominent / touch |
| `--control-pad-x-sm/md` | 0.625 / 0.75rem | control inline padding |

## Radius — `--radius-ops-*` → `rounded-ops-*`

`sm` 0.25 · `md` 0.375 · `lg` 0.5 · `control` 0.375 (buttons/inputs) · `surface` 0.5 (panels/cards) · `overlay` 0.75rem (modals/tooltips).

## Shadow — `--shadow-ops-*` → `shadow-ops-*`

Elevation ladder: `surface` (1px, resting) → `mid` (subtle hover / interactive state) →
`raised` (10px, the element lifts off the page) → `overlay` (24px, modals/flash). Use
`mid` for hover/selected feedback, `raised` only for a genuine lift (intent-card hover).
`focus` is **reserved** — prefer the global `:focus-visible` outline (see Focus below);
the box-shadow ring is only an escape hatch for inset focus inside overflow-clipped boxes.

**Dark-only augmentation:** `--shadow-ops-panel-dark` is a dark-only supplement declared in
the D-10 dual-path blocks; it is **not** declared in light. Light panels continue to use
`--shadow-ops-surface` (vertical lift). See §Glow + dark ambient depth — Phase 131 below.

## Glow + dark ambient depth — Phase 131

Three new shadow tokens extending the ladder for dark brand expression. Light values for the
glow tokens are `none` (declared in `@theme`) so they produce zero visual change in light;
`--shadow-ops-panel-dark` has no light declaration at all — the absence is the mechanism that
keeps light panels pixel-identical.

| Token | Light value | Dark value | Use |
| --- | --- | --- | --- |
| `--shadow-ops-panel-dark` | (not declared in light) | `0 0 0 1px rgba(0,0,0,0.30), 0 1px 3px rgba(0,0,0,0.45)` | Ambient seated-depth shadow on dark panels and shell chrome: `.ops-panel`, `.ops-header`, `.ops-theme-toggle`, `.ops-cmdk__panel`, `.ops-flash`, `.ops-intent-card` |
| `--shadow-ops-glow` | `none` | `0 0 8px 2px rgba(108,92,231,0.30)` | Quiet violet glow — live brand mark, active nav, theme-toggle selected pill/button, route/path nodes, and key-callout hover only. Never on text, resting panels, or background floods |
| `--shadow-ops-glow-copper` | `none` | `0 0 6px 1px rgba(193,122,62,0.25)` | Quiet copper glow — key-node hover only. No consumer in Phase 131 (reserved for Phase 133/134) |

**Panel-dark detail:** the `0 0 0 1px` zero-offset ring reads as ambient inset depth (panel
seated into the surface, not floating above it); the `0 1px 3px` retains the subtle downward
lift. Combined with the panel's `border: 1px solid color-mix(base-content 14%)`, the result is
dark seated depth without visible shadow lift.

**Glow-copper restraint:** Lower alpha (0.25) and tighter spread (6px/1px) than the violet
glow — copper is the 5% accent; violet is the 10% primary. The `.ops-glow` class wraps
`--shadow-ops-glow` only; copper glow is applied per-site as needed (not via a shared class).

## Copper accent vocabulary — Phase 131

Copper (`--color-secondary`: `#c17a3e` dark / `#a85d2e` light) is the brand's **5% accent**.
Three component classes expose it for eyebrow labels, key-callout badges, and key-node markers.

**Hard rule:** Copper is a brand accent, **NEVER a status tone**. It does not appear in
`tone_class/1` or `badge_class/1`. It carries no semantic meaning (not info / success /
warning / error / partial / running / neutral). Do not route copper through status machinery.

### Allowed application sites (exhaustive — no others)

| Class | Allowed sites | Screen(s) |
| --- | --- | --- |
| `.ops-copper-eyebrow` | Page eyebrow label ("Operator workspace") | All 6 screens |
| `.ops-copper-badge` (compose with `.ops-badge`) | Intent-card federation badge, playbook file-type badge, key-callout badge | Control Room, Search, Playbooks |
| `.ops-copper-node` | Key-node / diagram icon emphasis (color only) | Future Phase 133/134 |
| `.ops-copper-node--fill` | Filled copper icon container | Future Phase 133/134 |

### Text color rules

**Badge text:** Always `var(--color-base-content)` inside `.ops-copper-badge` — never
`var(--color-secondary)` as the badge label text. Light AA fails at 4.15:1 on tinted copper
background (below the 4.5:1 AA threshold for small text).

**Eyebrow text:** `var(--color-secondary)` as eyebrow text on a `--ops-surface-1` background
is AA-safe in both themes. Do NOT use `var(--color-secondary)` as badge label text.

### AA pairing evidence

| Pairing | Theme | Ratio | AA verdict |
| --- | --- | --- | --- |
| `base-content` (`#f4f1ea`) text on `.ops-copper-badge` tinted bg | Dark | 12.07:1 | PASS |
| `base-content` (`#141923`) text on `.ops-copper-badge` tinted bg | Light | 14.86:1 | PASS |
| `.ops-copper-eyebrow` (`--color-secondary` `#c17a3e`) on `--ops-surface-1` `#141923` | Dark | 5.13:1 | PASS |
| `.ops-copper-eyebrow` (`--color-secondary` `#a85d2e`) on `--ops-surface-1` `#fffdf8` | Light | 4.84:1 | PASS |
| `--color-secondary-content` (`#0c0f14`) on solid copper `#c17a3e` | Dark | 5.59:1 | PASS |
| Copper text `#c17a3e` on `--ops-surface-2` `#1b2230` | Dark | 4.64:1 | PASS |

All ratios computed with sRGB relative luminance (D-12 compliant, matching axe-core).

## Focus

One ring for the whole shell: the global `:focus-visible { outline: 2px solid primary;
outline-offset: 2px }` in `@layer base`. Do **not** add per-element `focus-visible:ring-*`
utilities — an `outline` is not clipped by `overflow-x-auto` (e.g. `.ops-table`) where a
box-shadow ring is, and double-drawing outline + ring reads as muddy.

## Shell chrome — Phase 135

Shell chrome is the shared operator frame: `.ops-header`, `.ops-shell`, `.ops-brand-mark`,
`.ops-nav-list`, `.ops-nav-item-active`, `.ops-theme-toggle*`, `.ops-cmdk__panel`, and
`.ops-flash`. Light remains on the base recipes by default; custom shell depth is dark-only
and must be authored in both explicit `[data-theme="dark"]` and system-dark
`@media (prefers-color-scheme: dark) html:not([data-theme="light"])` paths.

| Selector | Contract |
| --- | --- |
| `.ops-header` | In dark, composes `--shadow-ops-surface` with `--shadow-ops-panel-dark` plus a 14% base-content divider so the header reads as a seated operator surface. Light keeps the base `--shadow-ops-surface` lift. |
| `.ops-shell` | Exactly one top-left `radial-gradient(...)` wash plus one `linear-gradient(...)` page floor per rule. Base/light stays 14% / 34rem; dark is bounded to 10% / 30rem and dark mobile to 8% / 24rem. No extra gradient layers, orbs, bokeh, texture, or loops. |
| `.ops-brand-mark` | Stable class on the live inline SVG brand mark. Dark paths apply only a quiet primary drop-shadow; proof must not rely only on stale `.ops-route-mark`. |
| `.ops-nav-item-active` | Text-bearing selected fill stays `--color-primary-strong`; dark paths compose `--shadow-ops-surface` with `--shadow-ops-glow`. |
| `.ops-theme-toggle`, `.ops-theme-toggle__pill`, `.ops-theme-toggle__button` | Class selectors mirror the existing IDs. Selected state is exposed through `aria-pressed` and `data-theme-selected`; dark paths use `--shadow-ops-panel-dark`, `--shadow-ops-glow`, and `--color-primary-strong`. |
| `.ops-cmdk__panel`, `.ops-flash` | Overlay chrome uses `--shadow-ops-overlay` in light. In explicit dark and system dark, compose overlay first (`--shadow-ops-overlay`) and panel-dark second (`--shadow-ops-panel-dark`) so transient shell surfaces keep depth without glow. |
| `.ops-flash`, `.ops-flash--info`, `.ops-flash--error` | Durable flash classes live on the passive `role="alert"` wrapper. Kind-specific classes tune non-text border accents while the icon/text pair and close button carry the status semantics. |

## Typography — `--text-ops-*` → `text-ops-*`, `--leading-ops-*` → `leading-ops-*`

Body sizes: `xs` 0.6875 · `sm` 0.75 · `body` 0.875 · `md` 1 · `lg` 1.125rem.
Heading scale: `h1` 1.5 (page title) · `h2` 1.125 (section) · `h3` 1rem (card/subsection)
→ `text-ops-h1/h2/h3`. **Headings use the heading scale, never raw `text-2xl`/`text-lg`/
`text-base`**; pair with `leading-ops-tight font-semibold` (the `<.ops_heading>` component
does this for you). Leading: `tight` 1.3 · `body` 1.5. Mono stack lives in `.ops-text-mono`.

## Status / tone — `.ops-tone-*` and `.ops-badge-*`

Six states: `info` · `success` · `warning` (= `partial`) · `error` · `running`, plus
`neutral` for badges. The single mapping authority is `tone_class/1` / `badge_class/1`
in `ops_ui.ex`; route any tinted surface (notice, status, action group) through them.
The **full tone set is supported everywhere a tone is consumed** — surfaces
(`.ops-tone-*`), badges (`.ops-badge-*`), and the metric border-accent modifiers
(`.ops-metric-{info,success,warning,partial,error,running}` via `metric_tone_class/1`,
where `:partial` settles like `:warning` and `:running` accents the brand primary). No
tone has a "supported on badges but silently `nil` on metrics" gap.
**Semantics:** neutral facts (counts) use `:neutral`; only real problems use
`:warning`/`:error`. Don't cry wolf (e.g. "0 queues observed" is neutral, not a warning).
Red is reserved for "the tool genuinely can't answer" (missing backend); a single degraded
schema is amber, not red.

**Prop naming:** a component attr named **`kind`** carries *status* semantics
(`:info/:success/:warning/:error/:partial/:running/:neutral`) — `ops_notice`, `ops_status`,
`ops_badge`, `ops_metric`, `ops_intent_card`, `ops_verdict`. An attr named **`variant`** or
**`tone`** carries a *presentation* axis, not status — e.g. `ops_action_group`'s
`:default/:advanced/:danger` or `ops_button`'s `:primary/:ghost/...`. Don't conflate them.

## Z-index — `--z-index-ops-*` → `z-ops-*`

`skip-link` 50 < `flash` 60 < `modal` 70.

## Motion — `--duration-ops-*` (component-only) + `--ease-ops-*` → `ease-ops-*`

| Token | Value | Use |
| --- | --- | --- |
| `--duration-ops-instant` | 90ms | tap/press feedback (`.ops-btn:active`) |
| `--duration-ops-fast` | 120ms | hover, nav/badge color shifts |
| `--duration-ops-standard` | 180ms | disclosure content fade, larger surfaces |
| `--duration-ops-status` | 200ms | status/verdict tone settle (metric + `ops_verdict`) |
| `--duration-ops-slow` | 240ms | overlay/modal entrance only |
| `--ease-ops-standard` | cubic-bezier(0.2,0.8,0.2,1) | ease-out, enter |
| `--ease-ops-out` | cubic-bezier(0.16,1,0.3,1) | stronger ease-out, overlay/modal entrance |
| `--ease-ops-in-out` | cubic-bezier(0.45,0,0.55,1) | symmetric, position toggles |
| `--ease-ops-exit` | cubic-bezier(0.4,0,1,1) | ease-in, crisp dismissal (modal/palette/flash **close**); faster/more linear than the enter eases |

Everything below is neutralized under `@media (prefers-reduced-motion: reduce)` (one global
rule), so any new transition is reduced-motion-safe by default. Keep it restrained:
transform/opacity only, < 300ms, ease-out for enter, no bounce (this is an incident tool).

### Enter/exit keyframes (Phase 123, MOTION-01)

| Keyframe | Direction | Pairing | Used by |
| --- | --- | --- | --- |
| `ops-modal-in` | enter | `--duration-ops-slow` + `--ease-ops-out` | `.modal-box`, `.ops-cmdk__panel` (open) |
| `ops-modal-out` | exit | `--duration-ops-fast` + `--ease-ops-exit` | `.ops-cmdk--closing .ops-cmdk__panel` (palette/sheet close) |
| `ops-fade-in` | enter | `--duration-ops-standard` + `--ease-ops-standard` | `.ops-disclosure[open] > .ops-disclosure-body` |
| `ops-fade-out` | exit | `--duration-ops-fast` + `--ease-ops-exit` | `.ops-cmdk--closing .ops-cmdk__backdrop` |

**Enter/exit asymmetry (the A1 rule):** enters ease *out* (longer, decelerating — `ease-ops-out`,
~240ms); exits ease *in* (shorter, accelerating — `ease-ops-exit`, ~120ms). Close feels as
intentional as open without dragging. The modal close also rides this via `phx-remove`
(`ops_modal`), and flash/banner show/hide via `core_components` `show/2`/`hide/2`. The command
palette plays `ops-modal-out` through a `.ops-cmdk--closing` class the JS hook adds for one tick
before `[hidden]` (re-opening cancels it → interruptible). Origin-aware: the exit settles back
toward the same `translateY(4px) scale(0.98)` the enter came from.

**A2 — signature verdict tone-settle:** `.ops-verdict` (surface), `.ops-verdict__dot`, and every
`.ops-metric` border share the *same* `--duration-ops-status` + `--ease-ops-standard` transition,
so a Refresh that flips posture reads as one coherent "the answer just moved" beat — not 6
independent flickers. Pure CSS (shared token, no JS, no stagger). The dot gets a transition so the
loudest tone signal doesn't snap ahead of the surface.

**A4 — row press/hover:** `.ops-result-row`/`.ops-object-item` press transform runs at
`--duration-ops-instant` (matching `.ops-btn:active`); hover color/elevation settle at
`--duration-ops-fast` — one press-feel authority across buttons, cards, and interactive rows.

**A3 (staggered result reveal) — deliberately NOT shipped.** A CSS-only `nth-child` stagger would
re-fire on every LiveView DOM patch of the result list (re-runs, re-sorts), reading as flicker —
the dashboard-toy bar the reserved brand rejects. Gating it to first-reveal needs a JS hook this
item explicitly forbids, so it was skipped on the side of restraint.

| Animate | Never animate |
| --- | --- |
| tone/badge/verdict **color** settle (≤200ms) | layout/reflow: width, height, margin, content top/left |
| disclosure chevron rotate + body **opacity** fade | `<details>` height (auto height can't transition → reflow) |
| button press scale, card hover lift (transform) | table row insertion / sort |
| nav/segmented hover, modal opacity+translateY entrance | metric **value** count-ups (no dashboard-toy tickers) |
| row hover/press (`.ops-result-row`/`.ops-object-item`: border + `shadow-ops-mid`, subtle scale) | flash bounce, focus rings, decorative loops |
| loading **opacity** pulse (`.ops-loading`, the one sanctioned in-flight loop besides the reconnect spinner) | |

### `.ops-path-*` path-motion vocabulary (Phase 133, DARKMOTION-01)

A small, named, **opt-in** path-expression layer applied **only** to stable JTBD anchors — the
design-system dividend Phase 134/135 reuse. No new keyframes (line-draw is a `transition`, not an
`@keyframes` — the A3 patch-safety precedent), no new JS hooks, no new tokens (reuses
`--duration-ops-fast`, `--ease-ops-standard`, `--shadow-ops-glow`, `--shadow-ops-glow-copper`).
Transform/opacity/box-shadow end states only.

| Class / token | What it does | Tokens | Fires on |
| --- | --- | --- | --- |
| `.ops-path-trace` + `::after` | Path line-draw underline (`transform: scaleX(0→1)` + opacity) — a pseudo-element copying the `.ops-disclosure summary::before` precedent | `--duration-ops-fast` + `--ease-ops-standard` | `:hover`, `.ops-path-trace--active`, or `[aria-current="page"]` — **never** mount/insert, **never** an `nth-child` stagger |
| `.ops-path-node` | Active-path node glow (violet route/path emphasis) via `--shadow-ops-glow` (none in light, faint in dark — dual-dark-path is free through the token) | `--shadow-ops-glow`, `--duration-ops-fast` | active path/key-node state only |
| `.ops-path-node--copper` | Key-node copper glow — first consumer of the declared `.ops-copper-node` vocabulary | `--shadow-ops-glow-copper`, `--duration-ops-fast` | active key node only |
| `.ops-object-item-active` (dark override) | Active Playbook item composes the violet glow onto its existing inset ring (Precedent D), **hand-authored in BOTH** `[data-theme="dark"]` and `@media (prefers-color-scheme: dark) html:not([data-theme="light"])` | `--shadow-ops-glow` | persistent active server-state class (patch-safe) |
| `.ops-code-block--shimmer` | Opt-in code-block hover glint — an opacity-only `::after` ring inside `@media (hover: hover)`; surfaced via `shimmer={true}` on `ops_code_block/1` | `--duration-ops-fast` + `--ease-ops-standard` | `:hover` on hover-capable pointers only |

**Anchors (the allowed surface):** the route mark, the recommended Control Room intent card
(`.ops-intent-card--recommended`), Search federation/merge-trace disclosures (`.ops-path-trace`),
the active Playbook item (`.ops-object-item-active`), and optionally the breadcrumb current path
(`[aria-current="page"]`). Every path/node signal is paired with the existing visible
text/ARIA state so motion never carries status meaning alone (D-07).

**Deliberately NOT shipped / restraint boundaries (the A3 voice):**
- **No result-list reveal stagger** — it would re-fire on every LiveView patch of the result list
  (re-runs, re-sorts) and read as flicker; the merge-trace line-draw is hover/state-driven, never
  list-entry (D-06).
- **`shimmer` never on evidence** — Failed Sync code blocks and search/merge payloads stay calm and
  readable; `shimmer` defaults to `false` and is never set on evidence panes (D-04a/c).
- **Glow is route/path emphasis only** — never on text, resting panels, ordinary buttons, broad
  backgrounds, or status surfaces (D-03b).

| Animate (path-motion) | Never animate (path-motion) |
| --- | --- |
| path line-draw (`.ops-path-trace` scaleX + opacity, hover/active) | SVG `stroke-dashoffset` line draws |
| active-path node glow (`.ops-path-node[--copper]` box-shadow) | `background-position` shimmer sweeps |
| opt-in code-block hover glint (`.ops-code-block--shimmer` opacity) | `filter:` animation |
| | result-list entry/reveal stagger (re-fires on patch) |
| | `shimmer` on evidence code blocks (Failed Sync / search-merge payloads) |

## Muted-Text Contrast Registry

The muted-alpha text pairs are tracked in [`contrast-pairs.mjs`](./contrast-pairs.mjs) (beside
this file) — the single source for the D-15 lockstep guard in `contrast-checker.mjs`. The guard
is **bidirectional**: every `color: color-mix(in oklch, var(--color-base-content) NN%, transparent)`
occurrence in `app.css` (including single-line rules and rules nested inside `@media` blocks) must
have a corresponding manifest entry, AND every non-`decorative` manifest entry must match an actual
`app.css` rule (so stale/removed entries are caught too). Either direction failing makes
`make contrast` fail.

### Alpha Compositing Algorithm (D-12)

Alpha compositing uses sRGB:

```
out_channel = fg_channel × α + bg_channel × (1−α)
```

per channel (0–255 space). This matches axe-core's compositing algorithm, ensuring the fast token
checker and the browser-based axe gate render one verdict on the same fg/bg pair.

### Thresholds (D-14)

Thresholds per D-14:

| Role | AA | AAA |
|------|-----|-----|
| `text` (body/inline) | 4.5:1 | 7.0:1 |
| `large` (uppercase + bold, WCAG large text) | 3.0:1 | 4.5:1 |
| `ui` (non-text, semantic pairs `X-content/X`) | 3.0:1 | 4.5:1 |

The `contrast-checker.mjs` gate exits non-zero iff AA failures exist; AAA is reported as advisory
only and never affects the exit code.
