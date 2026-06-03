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
| `secondary` | `#a85d2e` | `#c17a3e` | warm accent, eyebrow labels |
| `accent` | `#6c5ce7` | `#5b4ad1` | gradient partner (route mark) |
| `base-100` | `#fffdf8` | `#141923` | surfaces |
| `base-200` | `#faf7f2` | `#0c0f14` | app background, muted panels |
| `base-300` | `#ded8ce` | `#2a3446` | borders, dividers |
| `base-content` | `#141923` | `#f4f1ea` | text |
| `info` / `success` / `warning` / `error` | `#5ca9e6` / `#4fae74` / `#d9a441` / `#d96262` | (same hues) | status semantics |

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

## Focus

One ring for the whole shell: the global `:focus-visible { outline: 2px solid primary;
outline-offset: 2px }` in `@layer base`. Do **not** add per-element `focus-visible:ring-*`
utilities — an `outline` is not clipped by `overflow-x-auto` (e.g. `.ops-table`) where a
box-shadow ring is, and double-drawing outline + ring reads as muddy.

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

| Animate | Never animate |
| --- | --- |
| tone/badge/verdict **color** settle (≤200ms) | layout/reflow: width, height, margin, content top/left |
| disclosure chevron rotate + body **opacity** fade | `<details>` height (auto height can't transition → reflow) |
| button press scale, card hover lift (transform) | table row insertion / sort |
| nav/segmented hover, modal opacity+translateY entrance | metric **value** count-ups (no dashboard-toy tickers) |
| | flash bounce, focus rings, anything looping/decorative |
