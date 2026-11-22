# ScrypathOps design tokens

The shared token/component contract for the ScrypathOps operator shell. The shell is
mount-path agnostic; the ecommerce example mounts it at `/admin/search`. Tokens live in the
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

The palette is the pinned plum and orchid brand book (`brand/`, with its tokens in
`brand/tokens.json`). That file is the single token authority; `app.css` is a hand-maintained
projection of it, checked both ways by `ui-tokens.test.mjs` (token-map parity in both
directions). daisyUI semantic tokens, two themes. System appearance is the default:
`html[data-theme]` wins, otherwise the operating system decides (`prefers-color-scheme`), and
ops never forces light. Both theme blocks in `app.css` declare exactly the 20 daisyUI color
variables below plus the platform rows, every value a literal hex (no `var()` aliases), and
[`token-map.json`](./token-map.json) records the brand source of each value. Generate utilities
like `bg-primary`, `text-base-content`, `border-base-300`.

| Token | Light | Dark | Brand role and use |
| --- | --- | --- | --- |
| `base-100` | `#ffffff` | `#201624` | Panel / Night Panel: resting surfaces and overlays |
| `base-200` | `#f8f4f2` | `#160e19` | Page / Night: app background |
| `base-300` | `#e0d5d1` | `#3a2a3e` | Hairline / Night Hairline: dividers and container borders, never a control's only edge |
| `base-content` | `#1e1220` | `#f4edf3` | Ink / Pale Ink: text |
| `primary`, `accent` | `#7b2d6b` | `#d58bc4` | Plum / Orchid: the accent, on the reserved list below |
| `primary-content`, `accent-content` | `#ffffff` | `#160e19` | label on an accent fill |
| `secondary` | `#f0e9e6` | `#3a2a3e` | quiet neutral (Sunken Page / Night Hairline), not an accent |
| `secondary-content` | `#1e1220` | `#f4edf3` | Ink / Pale Ink |
| `neutral` | `#1e1220` | `#3a2a3e` | Ink / Night Hairline |
| `neutral-content` | `#f8f4f2` | `#f4edf3` | Page / Pale Ink |
| `info` | `#5e5360` | `#bbaac0` | Muted Ink / Muted Pale (local default LD-1) |
| `success` | `#1d6b3c` | `#7fcb9a` | the Clear text color (LD-1) |
| `warning` | `#8a5a00` | `#e3b25c` | the Retrying text color (LD-1) |
| `error` | `#b0360b` | `#ff9a6b` | the Failed text color (LD-1) |
| `info-content`, `success-content`, `warning-content`, `error-content` | `#ffffff` | `#160e19` | Panel / Night (LD-1) |

The four LD-1 aliases exist because daisyUI requires a fill and a content color for each; ops
never paints them as fills (notices use a 2px rule), and the content colors still hold 4.5:1
on them if a daisyUI utility leaks. There is no destructive fill: Failed is a status and error
color only.

### 60 / 30 / 10

| Role | Light | Dark | Share and usage |
| --- | --- | --- | --- |
| Dominant (60%) | Page `#f8f4f2` | Night `#160e19` | `body`, the page floor, the space between rows |
| Secondary (30%) | Panel `#ffffff`, Sunken `#f0e9e6`, Selected `#ebdfe7` | Night Panel `#201624`, Night Sunken `#110a14`, Selected Night `#2b2130` | header, sidebar, tables, rows, fields, notices, verdicts, code blocks, selected state |
| Accent (10% at most) | Plum `#7b2d6b` | Orchid `#d58bc4` | the reserved list below and nothing else |

Ink is text, not a surface.

**Accent is reserved for (and nothing else):** the lockup's slash (inside the SVG); the
`:focus-visible` ring; text links, underlined at rest; the one primary button per scope (the page,
or one open modal or sheet); the selection line (`border-inline-start`) and the text of the
current-page nav item and the active command-palette item; the checked fill of native checkbox,
radio and toggle inputs; the finite navigation progress bar. Plum is never an info color and never
text on Night (Orchid is the dark pair).

**Failed color is reserved for:** the word and icon of `ops_sync_status :failed`, error-kind
notices, verdicts and flash (rule and title), and invalid-input or unreadable text (`.text-error`).
Retrying amber is the word and icon of Retrying plus warning and partial notices (rule and title
only). Green is the word and icon of Clear only. Pending is a muted gray-plum.

### Alpha policy

Text never uses alpha: no `color-mix`, `rgba`, `/NN` utility or element `opacity` below 1 on
text; it is Ink or the opaque `--ops-text-muted`. Plum and status tints (`color-mix` containing
the primary or a status color), glow and tinted fills are retired in favor of `--ops-selected`,
`--ops-sunken`, `--ops-control-edge`, `--color-base-300` or a solid token. Control borders are the
opaque Control Edge. Kept, because they are not text and carry no retired color: container
dividers and borders that mix `--color-base-content` with transparent, the black or
base-content shadows, the one normalized scrim, the scroll-edge gradients in `.ops-table-scroll`,
and near-opaque surface mixes such as the sidebar.

`contrast-checker.mjs` enforces both halves from the stylesheet text, each with a planted failure in
`--self-test` and a planted clone case in `verify.repository_contracts`: N-07 fails any `color`
declaration that carries a `color-mix`, an `rgba` or `hsla` call, a slash alpha or a four- or
eight-digit hex, and N-12 fails any `color-mix` (or relative color) of the primary, the secondary or
a status color. Secondary text is the `.ops-muted` class (`color: var(--ops-text-muted)`); templates
never put an opacity step on a text color utility or an `opacity-NN` step on a glyph.

## A11y contrast floors

AA contrast is the hard gate for the operator UI. Body and long-form AAA status is
advisory/report-only; AAA findings should stay visible in reports, but AA failures block
the contrast gate.

`contrast-checker.mjs` computes every pair below from the custom properties in `app.css`
(pair names live in [`contrast-pairs.mjs`](./contrast-pairs.mjs) as property names, never as hex),
compares unrounded ratios, and prints the thinnest text pair on every run.

| Check | Rule |
| --- | --- |
| N-03 text pairs | Seven text roles (`base-content`, `--ops-text-muted`, `primary`, and the four `--ops-status-*` colors) on four backdrops (`base-200`, `base-100`, `--ops-sunken`, `--ops-selected`), both themes: 56 pairs, each 4.5:1 or better. Thinnest pair: Retrying on Selected Page, 4.58:1 |
| N-04 non-text pairs | `--ops-control-edge` on the four backdrops and on the overlay surface (`base-100`), and `primary` on the four backdrops: 3:1 or better. Button labels (`primary-content` on `primary`, `base-content` on `base-100`): 4.5:1 or better |
| N-05 published pairs | The 14 pairs printed in the brand book are bound to custom properties and must reproduce to two decimals; Failed and Retrying stay at least 25 degrees apart in CIELAB hue angle |
| Opaque muted token | `--ops-text-muted` is a six-digit hex equal to the brand's Muted Ink (light) and Muted Pale (dark); an alpha mix on it fails |
| N-07 text alpha | No `color` declaration in `app.css` contains `color-mix(`, `rgba(`, `hsla(`, a slash alpha or a four- or eight-digit hex; the failure names the selector and the line |
| N-12 retired tints | No `color-mix(` or relative color in `app.css` contains the primary, the secondary, `info`, `success`, `warning`, `error` or a status color; base-color borders, shadows, scrims and scroll-edge gradients pass |
| Fixed floors | The pair matrix may not lower 4.5 (text, button labels), 3.0 (control edge, primary) or 25 degrees (status hue); lowering one fails |
| Color-variable count | Each theme block declares exactly 20 `--color-*` variables |

`--ops-text-muted` consumers: `.ops-muted` (the class templates use for secondary text),
`.ops-text-meta`, `.ops-trail__crumb`, `.ops-trail__sep`, `.ops-handoff__hint`, `.ops-preflight__hint`,
`.ops-cmdk__item-hint`, `.ops-cmdk__empty`, `.ops-empty-hero__body`, `.ops-fieldset__hint`,
`.ops-time__label`, `.ops-nav-group__label`, `.ops-nav-item`, `.ops-intent-card__summary`,
`.ops-signal-table th[scope="row"]` and `.ops-cheatsheet__row dd`. Because the token is an opaque
color, a consumer needs no registry entry and there is no registry: do not reintroduce a
`color-mix(in oklch, var(--color-base-content) NN%, transparent)` text declaration (N-07 fails it).
The former rule for converting an alpha was: 80 percent or more became Ink, below 80 percent became
the muted token; every one of the nine declarations that remained at the end of Phase 187 was below 80.

Text links inside `.ops-shell` use `--color-base-content` unless the template explicitly
selects a primary color. This prevents an inline link from inheriting a muted container
color while keeping muted supporting copy on `--ops-text-muted`.

## Surfaces, selection, control edge and status roles — Phase 187

Named roles declared in the daisyUI `@plugin` blocks (dark + light), each a literal hex. The plugin
spreads them to both `[data-theme="dark"]` and `@media (prefers-color-scheme: dark)` for free.

| Token | Light value | Dark value | Use |
| --- | --- | --- | --- |
| `--ops-bg` | `#f8f4f2` | `#160e19` | Flat page floor and shell background |
| `--ops-surface-1` | `#ffffff` | `#201624` | Resting panel — `.ops-panel`, `.ops-surface-flat`, `.ops-preflight__card` |
| `--ops-sunken` | `#f0e9e6` | `#110a14` | Recessed fill: code, hover fills, disabled fields, skeleton blocks |
| `--ops-selected` | `#ebdfe7` | `#2b2130` | Selected fill, always paired with the 2px Plum or Orchid inline-start line |
| `--ops-selection`, `--ops-theme-selection` | `#ebdfe7` | `#2b2130` | The same value under the two older names, kept one milestone because tests and surface lists still name them; the v1.47 cleanup collapses them into `--ops-selected` |
| `--ops-control-edge` | `#8a7a8e` | `#8f7f94` | The opaque border of every control; 3:1 or better on every backdrop |
| `--ops-text-muted` | `#5e5360` | `#bbaac0` | Opaque muted text (Muted Ink / Muted Pale) |
| `--ops-status-failed` | `#b0360b` | `#ff9a6b` | The word and icon of Failed |
| `--ops-status-retrying` | `#8a5a00` | `#e3b25c` | The word and icon of Retrying |
| `--ops-status-pending` | `#615765` | `#ab9bb0` | The word and icon of Pending |
| `--ops-status-clear` | `#1d6b3c` | `#7fcb9a` | The word and icon of Clear |
| `--ops-warning-text`, `--ops-error-text` | `#8a5a00`, `#b0360b` | `#e3b25c`, `#ff9a6b` | Kept names, literal duplicates of the Retrying and Failed text colors |

`--ops-surface-2` is deleted. Its consumers were reclassified: a raised surface is `--color-base-100`
(Panel), and a hover or recessed surface is `--ops-sunken`. The dark surface order is now
`--ops-sunken` < `--ops-bg` < `--ops-surface-1`, and `surface_depth_token_contract_test.exs` asserts it.

### Retired in Phase 187

Names only; none of these is a brand value.

- `--color-primary-strong`: the second primary tier is deleted from both blocks, the token map and the
  example theme. Plum and Orchid carry 4.5:1 labels themselves.
- `--ops-surface-2`: deleted with its consumers (see above).
- `--shadow-ops-glow` and `--shadow-ops-glow-copper`, the glow that rode on them, the `.ops-glow`
  utility and the route mark's gradient and glow: deleted.
- The `.ops-path-*` path-motion vocabulary and the `.ops-code-block--shimmer` hover glint (with the
  `shimmer` attribute of `ops_code_block/1`): deleted.
- The copper secondary and the `.ops-copper-*` classes: deleted; `--color-secondary` is now a quiet
  neutral.
- The select chevron's hard-coded stroke colors and its dark and System twins: replaced by one
  `currentColor` two-layer gradient chevron (LD-11).
- Plum and status alpha tints (`color-mix` of the primary or a status color) and the violet and
  copper translucent shadows.
- The old blue, green, gold and red fills of `info`, `success`, `warning` and `error`, and the old
  near-black content color on them.
- Capital-letter transforms on labels (see Typography).

## Spacing — `--spacing-ops-*` → `p-ops-*` / `gap-ops-*` / `space-y-ops-*`

| Token | Value | Use |
| --- | --- | --- |
| `--spacing-ops-1..6` | 0.25 → 1.5rem | raw steps |
| `--spacing-ops-field` | 0.375rem | label↔input gap (`space-y-ops-field`) |
| `--spacing-ops-row` | 1rem | between list items |
| `--spacing-ops-section` | 1.5rem | between major page sections and grouped form fieldsets |
| `--spacing-ops-panel` | 1.25rem | panel interior padding (`p-ops-panel`) |
| `--spacing-ops-control-gap` | 0.5rem | gap between adjacent controls |
| `--spacing-ops-page-gap` | 1.5rem | top-level page section gap |

**Page rhythm:** the `:ops` shell wraps page content in `space-y-4`; do **not** add `mt-*`
to its direct children (that double-spaces them). Use the container gap.

**Form rhythm:** use `.ops-form-stack` around groups of `.ops-fieldset`. Fieldsets keep
legend/hint copy tight, then use `--spacing-ops-3` before controls and
`--spacing-ops-section` between groups.

**Empty states:** use `.ops-empty-hero` for high-attention blank sections where the user
needs orientation and a next action. Keep `.ops-muted-panel` / `<.ops_empty_state>` for
compact config guards, errors, and small no-result messages.

## Control sizing — `--control-*` (component-only, via `var()`)

| Token | Value | Use |
| --- | --- | --- |
| `--control-h-xs` | 1.75rem | compact disclosure summaries, dense chips, journey home |
| `--control-h-sm` | 2.25rem | segmented buttons, checkbox rows |
| `--control-h-md` | 2.5rem | **default** — inputs, selects, nav items, buttons (`.ops-btn`, `.ops-form-control`) |
| `--control-h-lg` | 2.75rem | prominent / touch |
| `--control-pad-x-sm/md` | 0.625 / 0.75rem | control inline padding |

## Component roles and consumers

`OpsUi` in `lib/scrypath_ops_web/components/ops_ui.ex` is the component authority. This
inventory names every current export; add new exports here with their role consumers.

| Component exports | Consumed roles |
| --- | --- |
| `ops_page_header`, `ops_heading` | Page h1 28px at weight 700 with title leading (1.2) and -0.01em tracking, the only 700 in ops; section h2 18px and subsection h3 16px at 600 with tight heading leading |
| `ops_panel`, `ops_section`, `ops_scaffold`, `ops_toolbar`, `ops_table` | Body 14px; named spacing and 24px page gap; panel padding 16px below 640px and 20px from 640px |
| `ops_command_hint`, `ops_button`, `ops_link_button`, `ops_refresh_button`, `ops_refresh_control`, `ops_action_group` | Action labels 14px/600; standard targets 40px; prominent and icon-only targets 44px; compact actions retain compact horizontal padding. The refresh button is an outline button with no glyph: it renders two words (`label`, `busy_label`, default `Refresh` and `Refreshing…`) in one grid cell and the stylesheet swaps them on `[aria-busy="true"]`, which the `OpsRefreshButton` hook sets |
| `ops_fieldset`, `ops_field`, `ops_text_input`, `ops_number_input`, `ops_textarea`, `ops_select`, `ops_schema_select`, `ops_segmented_control`, `ops_checkbox_list`, `ops_upload_box` | Form labels, help, and values use 14px; standard controls are 40px, multiline controls are at least 96px |
| `ops_verdict` | Outcome surface with a visible label and headline. The optional `status` attr renders `ops_sync_status` before the headline; `kind` sets the rule (Failed for `:error`, Retrying amber for `:warning`, Control Edge for the rest) and the Control room and Search health derive both from the worst row, never from the coarse posture state, with one exception: while a refresh issue is showing, the Control room drops the `Clear` word (a failed refresh leaves an earlier observation on screen, and `Clear` needs an observation) and keeps `Failed`, `Retrying` and `Pending`. Evidence and next-step content stay readable |
| `ops_sync_status` | The one place the four sync-status words and shapes render. Statuses `:failed`, `:retrying`, `:pending`, `:clear` render the word first (600 weight, title case: `Failed`, `Retrying`, `Pending`, `Clear`) and then an `aria-hidden` 16px bar icon whose `data-shape` is `notched`, `bottom-filled`, `hollow` or `filled`. Word and icon take `--ops-status-<status>` through `currentColor`; hooks are `[data-sync-status]` on the span and `[data-shape]` on the svg. The icon never appears without its word and has no role or name |
| `ops_condition` | A plain muted word for something nobody looked at: `Not observed`, `Not checked`, `Queue not used` or `Unavailable` (a closed set, weight 400, no icon, no status color). `Clear` needs an observation and is rendered by `ops_sync_status` instead; a zero count from an unobserved source never earns it. Hook: `.ops-condition`, `[data-condition]` |
| `ops_notice`, `ops_status`, `ops_tone_chip` | Panel (`--color-base-100`) with a full 1px border, no one-sided bar, no tint, no shadow, no cue dot. Border by kind: `:error` Failed (border and title), `:warning` and `:partial` Retrying amber (border and title), `:info`, `:success`, `:running` and `:neutral` the Hairline with an Ink title. Body text is Ink. `ops_status` keeps `data-status-kind`; its `neutral` attr is accepted but no longer changes the surface. `ops_tone_chip` rides the same surface |
| `ops_badge`, `ops_metric`, `ops_metric_grid` | `ops_badge` is plain muted text (12px, 600) for non-sync labels such as the Search run state; it never carries a sync status. `ops_metric` has no cue icon: state shows as the value color, `data-ops-metric-tone` stays. None of the three is used for a sync status |
| `ops_intent_card`, `ops_handoff`, `ops_trail` | Body and next action use 14px; recovery CTA has a 44px target; retain named color and motion roles. `ops_intent_card` is words only: no icon and no "Start here" flag |
| `ops_empty_state`, `ops_empty_hero`, `ops_loading`, `ops_config_empty` | Required instructions and error copy use body 14px; optional metadata may use the small exception. `ops_empty_hero` has no mark icon. `ops_loading` always shows its `label` word and sets `aria-busy="true"` on its region; the `:bars` lines are static Sunken blocks (the last one a `--short` class, never an inline width) and nothing animates |
| `ops_data_card`, `ops_result_row`, `ops_object_list`, `ops_object_item`, `ops_signal_table` | Record headings use h3 16px; body uses 14px; spacing, radius, shadow, and responsive layout stay token-backed |
| `ops_time`, `ops_disclosure`, `ops_code_block`, `ops_inline_code` | Required copy uses 14px; exact technical evidence may use monospace; optional timestamps and metadata use the 12px floor; times, code, keys and identity names are Sometype Mono |
| `ops_modal`, `ops_sheet`, `ops_command_palette` | Body/actions use 14px; dialog icon target is 44px; consume named overlay layer, radius, shadow, and motion roles. `ops_sheet` docks right on wide screens and rises from the bottom below 640px |

### Six-surface examples

These examples describe current consumers, not a requirement to make each route share one
template. Preserve the task-specific scan order documented in the root [`DESIGN.md`](../../../DESIGN.md).

| Surface | Existing pattern | Component/source example |
| --- | --- | --- |
| Control room | Observation → verdict or setup state → safe destination | Labelled native `<section>`, `ops_verdict`, `ops_link_button`, three `ops_intent_card` destinations |
| Search health | Fleet verdict and metrics → worst-first schema evidence | `ops_verdict`, `ops_metric_grid`, schema articles with distinct Backend and Queue groups |
| Failed sync work | All-schema summary → schema/cause filter chips → compact rows (facts line, error code block, outline Retry, More details) | `ops_verdict`, `.ops-filter-chip`, `.ops-failed-row`, `ops_code_block` (`inline_copy`, `clamp`), `ops_disclosure`, `ops_modal`, `ops_handoff` |
| Sync and drift | Reconciliation → contract → freshness/recovery → gated promotion | `ops_section`, `ops_signal_table`, `ops_data_card`, native advanced `<details>` |
| Search | Target/query form → compact backend-ordered Results → page / save | `ops_segmented_control`, `ops_schema_select`, `ResultUi.result_hit`, `ops_disclosure`, `ops_help_link` |
| Saved searches | Workspace catalog → preview → run outcome → import | `ops_object_list`, `ops_object_item`, labelled preview/outcome sections, native import controls |

### Superseded rules

| Retired treatment | Current rule |
| --- | --- |
| Decorative shell wash and separate sliding theme-selection pill | Keep `.ops-shell` flat; use the three visible System/Light/Dark buttons and their explicit selected state. |
| Extra top margins on direct `:ops` shell children | Let the shell's `space-y-4` own the page rhythm; add spacing inside the component group that needs it. |
| Broad status-colored verdict or metric surfaces | Keep summary surfaces on the Panel; state is the surface's full 1px status border plus an explicit status word from `ops_sync_status`, never a tint, a cue dot, an icon or a one-sided bar. |
| Hidden radios presented as schema cards | One schema is read-only context; multiple schemas use visible native radios in plain stacked rows, with full module names available. |
| Panels around individual actions or native disclosures | Action groups provide spacing; buttons carry their own affordance. Disclosures remain unframed. Group rows with headings, spacing, or separators. |
| Repeated “Operator workspace” page eyebrow | The actual page heading provides orientation. |

Search health diagnostic groups share their schema's surface with a single divider where useful, rather than another boxed card. Keep full identifiers and last-success evidence readable. Schema choices use the same radio treatment at all current allowlist counts; revisit only when real list size demonstrates a need for another control. One schema is read-only context when it is the resolved selection; an unresolved scope remains unselected and offers an explicit valid choice, including with one allowed schema. Never make the first option look selected when the server rejected the URL scope. Keep the confirmation on the action itself (a destructive confirm is the dialog's one Plum button, named by its consequence), not on a surrounding decorative panel.

Primary task weights are 400 for body/value text and 600 for actions, labels, and headings.
The type floor is 12px: `--text-ops-xs` and `--text-ops-sm` are both 0.75rem and nothing
computes below it. The 12px size remains reserved for short timestamps, badges, labels, and
optional technical metadata; never use it for an action, form label, failure reason, or
the only copy needed to choose what to do. Labels are sentence case at 12px, 600, with
0.01em letter-spacing; no text is transformed to capitals. Existing radius, shadow, motion,
and z-index tokens remain the sole authorities for those dimensions.

Shared `.ops-btn` actions use a neutral Sunken hover and a stronger transient neutral press; the existing global 2px focus outline with 2px offset remains independent. Only explicit `aria-pressed="true"` marks a persistent selected action. Disabled native buttons suppress hover/press feedback, and refresh eligibility is re-read from the server-rendered `data-ops-refresh-eligible` value after each LiveView patch.

## Radius — `--radius-ops-*` → `rounded-ops-*`

`sm` 0.25 · `md` 0.375 · `lg` 0.5 · `control` 0.375 (buttons/inputs) · `surface` 0.5 (panels/cards) · `overlay` 0.75rem (modals/tooltips).

## Shadow — `--shadow-ops-*` → `shadow-ops-*`

Elevation ladder: `surface` (1px, resting) → `mid` (subtle hover / interactive state) →
`raised` (10px, the element lifts off the page) → `overlay` (24px, modals/flash). Use
`mid` for hover/selected feedback, `raised` only for a genuine lift (intent-card hover).
There is no focus shadow token (retired in Phase 187): focus is an outline (see Focus below), and
inside an overflow-clipped box the outline is drawn inward instead.

**Dark-only augmentation:** `--shadow-ops-panel-dark` is a dark-only supplement declared in
the D-10 dual-path blocks; it is **not** declared in light. Light panels continue to use
`--shadow-ops-surface` (vertical lift). See §Dark ambient depth — Phase 131 below.

## Dark ambient depth — Phase 131 (glow retired in Phase 187)

`--shadow-ops-panel-dark` extends the shadow ladder for dark panels. It has no light declaration at
all — the absence is the mechanism that keeps light panels unchanged.

| Token | Light value | Dark value | Use |
| --- | --- | --- | --- |
| `--shadow-ops-panel-dark` | (not declared in light) | `0 0 0 1px rgba(0,0,0,0.30), 0 1px 3px rgba(0,0,0,0.45)` | Ambient seated-depth shadow on dark panels and shell chrome: `.ops-panel`, `.ops-header`, `.ops-theme-toggle`, `.ops-cmdk__panel`, `.ops-flash > .alert`, `.ops-intent-card` |

**Panel-dark detail:** the `0 0 0 1px` zero-offset ring reads as ambient inset depth (panel
seated into the surface, not floating above it); the `0 1px 3px` retains the subtle downward
lift. Combined with the panel's `border: 1px solid color-mix(base-content 14%)`, the result is
dark seated depth without visible shadow lift.

**Glow and copper are deleted.** `--shadow-ops-glow`, `--shadow-ops-glow-copper`, the `.ops-glow`
utility and the copper vocabulary (`.ops-copper-eyebrow`, `.ops-copper-badge`, `.ops-copper-node`,
`.ops-copper-node--fill`) no longer exist in `app.css`, and `motion_contract_test.exs` fails if any of
them returns. The active nav item and every other selected element carry the Selection Signature
(below) instead of a glow. `--color-secondary` is a quiet neutral: it is never an accent and never a
status tone.

## Focus

One ring for the whole shell: the global `:focus-visible { outline: 2px solid primary;
outline-offset: 2px }` in `@layer base`. Do **not** add per-element `focus-visible:ring-*`
utilities — an `outline` is not clipped by `overflow-x-auto` (e.g. `.ops-table`) where a
box-shadow ring is, and double-drawing outline + ring reads as muddy.

Inside `.ops-table-scroll` the same ring is drawn inward (`outline-offset: -2px`), so the
scroller's overflow cannot cut it; the contrast manifest binds that selector and offset.

**Header height and scroll padding.** `--ops-header-h` is the sticky header's height: 4rem, and 7rem
at 640px and below where the header wraps to two rows. `html:has(.ops-shell)` sets
`scroll-padding-top: calc(var(--ops-header-h) + 1rem)`, so a focused or anchored element is scrolled
below the header, never under it. The rule is scoped by `:has(.ops-shell)` so it never reaches a host
page. `ui-tokens.test.mjs` ("live scroll padding clears the sticky header") enforces it.

## Buttons, row actions, selection and overlays — Phase 187

- **One Plum button per scope.** A scope is a page or one open dialog or sheet. Every other button is
  the outline default (Panel fill, Ink text, opaque Control Edge border; hover and press are
  `--ops-sunken`, never `--ops-selected`). There is no danger variant and no error button class: a
  destructive confirm is the dialog's one Plum button, named by its consequence, with Cancel focused.
  Plum buttons keep their Plum fill and lay a 14% black veil over it on hover (a darker fill in both themes, label untouched; 10.2:1 text contrast in light, 5.7:1 in dark; no color mix, no new hex) and never underline their label.
  Buttons come in three variants: `:default` (outline), `:primary` and `:ghost`.
- **Row actions** (`.ops-text-action`) are underlined Ink text, 14px 600, with a 40px target and a 2px
  underline on hover. They share one computed style; nothing else may override it. Prose links are
  Plum (Orchid in dark) and underlined at rest.
- **Selection Signature.** Every selected or current element has the `--ops-selected` fill and a 2px
  `border-inline-start` in `--color-primary`. The 2px is reserved at rest (transparent, or the control
  edge on a bordered chip) so selecting never moves layout. One shared rule at the end of `app.css`
  lists the selectors.
- **Overlays.** `.modal-box`, `.ops-sheet__panel`, `.ops-cmdk__panel`, `.ops-mobile-nav__panel` and
  `.ops-flash > .alert` are `--color-base-100` with a 1px Control Edge border and `--shadow-ops-overlay`.
  Every backdrop is one scrim, `color-mix(in oklch, var(--color-black) 50%, transparent)`.

## Shell chrome — Phase 135

Shell chrome is the shared operator frame: `.ops-header`, `.ops-shell`, `.ops-wordmark`,
`.ops-nav-list`, `.ops-nav-item-active`, `.ops-theme-toggle*`, `.ops-cmdk__panel`, and
`.ops-flash`. Phase 173 sets a flat warm-neutral light floor and neutral dark floor; this
supersedes the earlier shell wash and separate sliding pill treatments. Explicit and System
appearance share the same shell tokens, while selected preference remains independent from
the effective OS appearance.

| Selector | Contract |
| --- | --- |
| `.ops-header` | In dark, composes `--shadow-ops-surface` with `--shadow-ops-panel-dark` plus a 14% base-content divider so the header reads as a seated operator surface. Light keeps the base `--shadow-ops-surface` lift. |
| `.ops-shell` | Flat `background-color: var(--ops-bg)` with `background-image: none` in light, dark, System, and responsive modes. Keep functional scroll-edge cues; do not add a decorative wash. |
| `.ops-wordmark` | Displays the canonical horizontal Scrypath wordmark. Light and inverse SVG assets switch with explicit and system theme; the files are byte-identical copies of the brand lockups under frozen names; keep the artwork unfiltered. The lockup is 136px wide (`width: 8.5rem`, `flex: none`, `height: auto`), so at least 28.8px tall. |
| `.ops-nav-item-active` | Selected fill is `--ops-selection` (Selected Page, Selected Night) with Plum or Orchid text; the Selection Signature line and the removal of the dark glow composed with `--shadow-ops-surface` arrive with the shape pass. |
| `.ops-theme-toggle`, `.ops-theme-toggle__button` | Three visible native buttons name System, Light, and Dark and retain at least a 44px target. Exactly one preference-selected button exposes `aria-pressed="true"` and `data-theme-selected="true"`; its backing uses `--ops-selection`. System appearance may change with the OS without changing the selected preference. |
| `.ops-cmdk__panel`, `.ops-flash` | Overlay chrome uses `--shadow-ops-overlay` in light. In explicit dark and system dark, compose overlay first (`--shadow-ops-overlay`) and panel-dark second (`--shadow-ops-panel-dark`) so transient shell surfaces keep depth without glow. |
| `.ops-flash`, `.ops-flash--info`, `.ops-flash--error` | Info confirmations use a polite `role="status"` toast and dismiss after 4 seconds; errors use `role="alert"` and stay until dismissed. Status colors tint the active theme's base surface and mark the outer border; text stays on `base-content` for contrast. |

## Typography — `--text-ops-*` → `text-ops-*`, `--leading-ops-*` → `leading-ops-*`

Body sizes: `xs` 0.75 (alias of `sm`, the 12px floor) · `sm` 0.75 · `body` 0.875 · `md` 1 · `lg` 1.125rem.
Heading scale: `h1` 1.75 (page title, weight 700) · `h2` 1.125 (section) · `h3` 1rem (card/subsection)
→ `text-ops-h1/h2/h3`. **Headings use the heading scale, never raw `text-2xl`/`text-lg`/
`text-base`**; pair h2 and h3 with `leading-ops-tight font-semibold` (the `<.ops_heading>`
component does this for you) and the h1 with `font-bold leading-ops-title tracking-ops-title`
(the `<.ops_page_header>` component does this). Leading: `tight` 1.3 · `body` 1.5 · `title` 1.2
(h1 only). Tracking: `title` -0.01em (h1 only) · `label` 0.01em (sentence-case 12px labels).

Faces: `--font-sans` is Hanken Grotesk (weights 400, 600, 700) and `--font-mono` is Sometype
Mono (weights 400, 500), each followed by a metric-adjusted local fallback face and then the
platform stack. Both load from `<mount>/assets/fonts/` through CSS-relative URLs with a
`?v=<sha256>` content hash and `font-display: swap`; no base64, no third-party host, and the
brand display face is never declared. Schema and index names (`data-ops-identity`), times
(`.ops-time__value`, `[data-ops-timestamp-copy]`), `code`, `pre`, `kbd` and `.ops-inline-code`
compute to the mono face. Weight snapping: 500 and 650 become 600 on Hanken and 500 on mono;
700 becomes 600 everywhere except the h1; nothing is lighter than 400.

Size scale record (`keep-platform`, no body reflow in this phase; the token map's parity
scope is the theme blocks only, so the values are recorded here): `--text-ops-sm` 0.75rem ·
`--text-ops-body` 0.875rem · `--text-ops-md` 1rem · `--text-ops-lg` 1.125rem ·
`--text-ops-h2` 1.125rem · `--text-ops-h3` 1rem.

Source invariants: `ui-tokens.test.mjs` checks the ops-authored source (`scrypath_ops/lib`,
`scrypath_ops/assets/js` without vendored files, and `app.css`) for a 12px minimum font size
(resolved through the `--text-ops-*` properties; every `--text-*` token in `app.css` is held
to it, even one only a utility class uses), no arbitrary `text-[` length, no uppercase, no
infinite iteration (including the `animate-spin`, `animate-ping`, `animate-pulse` and
`animate-bounce` utilities) and no `size: :xs` caller. `@apply` lists in `app.css` are read like
class attributes. These read source declarations, not rendered size. Demo host CSS, the tracked built CSS and vendored files are not scanned. A variant that
emits the daisyUI `btn-xs` class (11px) is caught only by the `size: :xs` caller check and by
the browser spec on the advisory lane; computed size stays browser-only.

## Status / tone: the notice border scheme and the sync-status words

Notices, statuses, verdicts and tone chips share one surface: `.ops-notice-surface` plus one
modifier chosen by `notice_modifier/1` in `ops_ui.ex` (the single mapping authority). The table is for those surfaces only. `ops_badge` is not one
of them: its `kind` is only a data attribute with no visual effect:

| Kind | Modifier | Border (full, 1px) | Title |
| --- | --- | --- | --- |
| `:error` | `--error` | `--ops-status-failed` | Failed color |
| `:warning`, `:partial` | `--warning` | `--ops-status-retrying` | Retrying amber |
| `:info`, `:success`, `:running`, `:neutral` | `--neutral` | `--color-base-300` (Hairline) | Ink |

Plum is never an info color and green appears only on `Clear`, so a success notice stays a
neutral rule. There are no `.ops-tone-*` tinted fills, no `.ops-badge-*` tinted variants and no
cue dots. **Sync states** do not use badges or notices at all: they render through
`ops_sync_status` (`Failed`, `Retrying`, `Pending`, `Clear`) or, when nothing was observed,
`ops_condition`. **Semantics:** neutral facts (counts) use `:neutral`; only real problems use
`:warning`/`:error`. Don't cry wolf (e.g. "0 queues observed" is neutral, not a warning). A
verdict derives its kind from the worst row status, never from the coarse posture state:
a failed row is `:error`, a retrying or unverified row is `:warning`, anything else is neutral.

**Prop naming:** a component attr named **`kind`** carries *status* semantics
(`:info/:success/:warning/:error/:partial/:running/:neutral`) — `ops_notice`, `ops_status`,
`ops_badge`, `ops_metric`, `ops_verdict`. An attr named **`variant`** or
**`tone`** carries a *presentation* axis, not status — e.g. `ops_action_group`'s
`:default/:secondary/:advanced` or `ops_button`'s `:primary/:ghost/...`. There is no danger value
anywhere (Phase 187). Don't conflate them.

## Icons — control glyphs only (Phase 187, LD-6)

ScrypathOps says state in words. The only Heroicons `lib/` may render are nine control glyphs,
each inside a control that has an accessible name or screen-reader text: `hero-bars-3` (open
navigation), `hero-x-mark` (close), `hero-chevron-down` (the Saved searches disclosure),
`hero-clipboard-document` (copy), `hero-sun-micro`, `hero-moon-micro` and
`hero-computer-desktop-micro` (theme choice), `hero-arrow-top-right-on-square` (opens in a new
tab) and `hero-magnifying-glass` (the command hint, shown alone only at 360px and below). Nav
items, headings, flash messages, counts, the refresh button, the import button, intent cards
and the empty hero render no icon. The four sync-status shapes are not Heroicons; they exist
only inside `ops_sync_status`. Control glyphs render at full opacity: the flash close glyph, the
theme-toggle glyphs and the timestamp-copy glyph take the text color (muted, Ink on hover or focus
for the copy glyph) and carry no opacity step. E-10 in
`reskin_static_contract_test.exs` scans every quoted `"hero-…"` literal under `lib/` against
this list, so adding a glyph is an edit to the list and a design decision, not a side effect.

## Z-index — `--z-index-ops-*` → `z-ops-*`

| Token | Value | Consumer |
| --- | ---: | --- |
| `--z-index-ops-header` | 30 | sticky `.ops-header` |
| `--z-index-ops-sidebar` | 35 | fixed `.ops-sidebar` |
| `--z-index-ops-skip-link` | 50 | keyboard skip link |
| `--z-index-ops-flash` | 60 | live notification region |
| `--z-index-ops-drawer` | 75 | mobile navigation drawer |
| `--z-index-ops-palette` | 80 | command palette and shortcut sheet |
| `--z-index-ops-modal` | 90 | operator dialogs, above vendor modal defaults |

The order is deliberate: header < sidebar < skip link < flash < drawer < palette < modal.
Every layer has a named token and a concrete consumer; component CSS does not repeat the
numeric values.

## Motion — `--duration-ops-*` (component-only) + `--ease-ops-*` → `ease-ops-*`

The brand book's names are the source (Phase 187, SKIN-05): four durations and six easings, and
nothing else. The old names stay for one milestone as `var()` aliases, so no consumer had to move.

| Token | Value | Use |
| --- | --- | --- |
| `--duration-ops-instant` | 80ms | a change the eye must not wait for: hover, press, focus (`.ops-btn:active`) |
| `--duration-ops-quick` | 160ms | a small change of one element: a status word, a row highlight, a dialog closing |
| `--duration-ops-base` | 240ms | a change of a region: a panel or dialog opening |
| `--duration-ops-advance` | 600ms | an update moving along the progress line. **No rule consumes it** in v1.46 |
| `--duration-ops-fast` | alias of `instant` | was 120ms: hover, nav/badge color shifts, modal dismissal |
| `--duration-ops-status` | alias of `quick` | was 200ms: status/verdict tone settle |
| `--duration-ops-standard` | alias of `base` | was 180ms: disclosure content fade, larger surfaces |
| `--duration-ops-slow` | alias of `base` | was 240ms: overlay/modal entrance |
| `--ease-ops-strike` | cubic-bezier(0.1,0.9,0.2,1) | fast in, hard stop: a thing that lands |
| `--ease-ops-resolve` | cubic-bezier(0.2,0.8,0.2,1) | quick start, soft landing: a thing that appears |
| `--ease-ops-settle` | cubic-bezier(0.3,0,0.2,1) | slow start, gentle stop: coming back from an overshoot |
| `--ease-ops-sweep` | cubic-bezier(0.45,0,0.25,1) | in and out: a marker crossing something |
| `--ease-ops-exit` | cubic-bezier(0.4,0,1,1) | accelerates away: crisp dismissal (modal/palette/flash **close**) |
| `--ease-ops-advance` | cubic-bezier(0.45,0,0.2,1) | in and out, a little slower to arrive: a step along the progress line |
| `--ease-ops-standard` | alias of `resolve` | the same curve under its old name |
| `--ease-ops-out` | alias of `resolve` | was a stronger ease-out for overlays |
| `--ease-ops-in-out` | alias of `sweep` | was symmetric, for position toggles |

Every transition and animation duration in ops computes to 0, 80, 160 or 240ms, and the stylesheet
holds no raw millisecond or second literal outside the reduced-motion rule. Three things keep it
that way:

- **Tailwind's default.** `@theme inline { --default-transition-duration: var(--duration-ops-quick); }`
  puts `transition`, `transition-all` and `transition-opacity` on the quick token. A duration
  utility in a template is the token form, `duration-(--duration-ops-quick)`, and a `JS.transition`
  `time:` is 80, 160 or 240 (E-18).
- **daisyUI's own literals.** daisyUI sets `.btn` 0.2s, `.modal` 0.3s and 0.1s, `.modal-box` 0.3s and
  0.2s, `.checkbox` 0.2s and its check mark 0.3s and 0.1s, `.card` outline 0.2s and `.radio` 0.2s.
  One block in the utilities layer at the end of `app.css` sets each to a token (`quick` for
  controls, `base` for dialogs), after the vendor rules, as a longhand so each component keeps its
  own properties and delays.
- **The contract.** `motion_contract_test.exs` fails any raw literal or unknown or advance token in
  a `transition` or `animation` declaration, with a planted stylesheet proving each matcher fires,
  and it fails a component that keeps its vendor duration. `e2e/admin_path_motion.spec.ts` (P-12)
  proves the computed durations and the absence of any looping animation in a real browser, in
  light, dark and System, with and without reduced motion.

Everything below is neutralized under `@media (prefers-reduced-motion: reduce)` (one global
rule), so any new transition is reduced-motion-safe by default. Keep it restrained:
transform/opacity only, < 300ms, ease-out for enter, no bounce (this is an incident tool).

### Enter/exit keyframes (Phase 123, MOTION-01)

| Keyframe | Direction | Pairing | Used by |
| --- | --- | --- | --- |
| `ops-modal-in` | enter | `--duration-ops-slow` (240ms) + `--ease-ops-out` | `.modal-box`, `.ops-cmdk__panel` (open) |
| `ops-modal-out` | exit | `--duration-ops-fast` (80ms) + `--ease-ops-exit` | `.ops-cmdk--closing .ops-cmdk__panel` (palette/sheet close) |
| `ops-fade-in` | enter | `--duration-ops-standard` (240ms) + `--ease-ops-standard` | `.ops-disclosure[open] > .ops-disclosure-body` |
| `ops-fade-out` | exit | `--duration-ops-fast` (80ms) + `--ease-ops-exit` | `.ops-cmdk--closing .ops-cmdk__backdrop` |

**Enter/exit asymmetry (the A1 rule):** enters ease *out* (longer, decelerating — `ease-ops-out`,
240ms); exits ease *in* (shorter, accelerating — `ease-ops-exit`, 80 to 160ms). Close feels as
intentional as open without dragging. The modal close also rides this via `phx-remove`
(`ops_modal`), and flash/banner show/hide via `core_components` `show/2`/`hide/2`. The command
palette plays `ops-modal-out` through a `.ops-cmdk--closing` class the JS hook adds for one tick
before `[hidden]` (re-opening cancels it → interruptible). Origin-aware: the exit settles back
toward the same `translateY(4px) scale(0.98)` the enter came from.

**A2 — verdict tone-settle (retired):** the verdict used to animate its tone with a shared
transition. A status change must not animate, so `.ops-verdict` and `.ops-metric` carry no
transition now; the 2px rule and the status word change in place.

**A4 — row press/hover:** `.ops-result-row`/`.ops-object-item` press transform runs at
`--duration-ops-instant` (matching `.ops-btn:active`); hover color/elevation settle at
`--duration-ops-fast` — one press-feel authority across buttons, cards, and interactive rows.

**A3 (staggered result reveal) — deliberately NOT shipped.** A CSS-only `nth-child` stagger would
re-fire on every LiveView DOM patch of the result list (re-runs, re-sorts), reading as flicker —
the dashboard-toy bar the reserved brand rejects. Gating it to first-reveal needs a JS hook this
item explicitly forbids, so it was skipped on the side of restraint.

| Animate | Never animate |
| --- | --- |
| tone/badge/verdict **color** settle (≤160ms) | layout/reflow: width, height, margin, content top/left |
| disclosure chevron rotate + body **opacity** fade | `<details>` height (auto height can't transition → reflow) |
| button press scale, card hover lift (transform) | table row insertion / sort |
| nav/segmented hover, modal opacity+translateY entrance | metric **value** count-ups (no dashboard-toy tickers) |
| row hover/press (`.ops-result-row`/`.ops-object-item`: border + `shadow-ops-mid`, subtle scale) | flash bounce, focus rings, decorative loops |
| nothing loops: loading is a literal word plus `aria-busy="true"` (`Refreshing…`, `Running…`, `Checking Meilisearch settings…`, `Attempting to reconnect`) with static Sunken skeleton bars. The spin and pulse animations are gone, and E-16 plus a source scan keep them gone | any infinite iteration, spinner or pulse |

### Path motion (retired in Phase 187)

Phase 133 shipped a `.ops-path-*` vocabulary (a line-draw underline, active-path node glows in violet
and copper, and an opt-in code-block hover glint) and a dark glow on the active Saved search item.
All of it is deleted with the old identity: the Selection Signature, a 2px Plum line on the Selected
fill, is the one selection mark, and no rule draws a decorative path, glint or aura. The restraint
boundaries it kept still hold: no result-list reveal stagger (it would re-fire on every LiveView
patch), no animation of layout properties, no decorative loops, and evidence code blocks stay calm.
`motion_contract_test.exs` asserts that the retired families and both glow tokens are absent, and (Plan 09)
that every transition and animation duration is a brand token or zero.

## Muted-Text Contrast (the registry is retired)

Phase 187 retired the muted-alpha registry that used to live in `contrast-pairs.mjs`
(`MUTED_PAIRS`) together with the lockstep guard that tied it to `color: color-mix(...)` declarations
in `app.css`. There is no alpha on text any more, so there is nothing to track: secondary text is
`--ops-text-muted`, an opaque color covered by the muted text pairs on four backdrops (N-03) and by
the opaque-token guard, and N-07 (see A11y contrast floors) fails any alpha that returns. The file
now holds the focus and surface bindings, the brand pair matrix and the published pair bindings.

### Alpha Compositing Algorithm (D-12)

Text no longer uses alpha, so this applies only to the near-opaque sidebar surface binding, which
the checker composites over the page before it measures text on it. Alpha compositing uses sRGB:

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
| `large` (WCAG large text: 18pt, or 14pt bold) | 3.0:1 | 4.5:1 |
| `ui` (non-text, semantic pairs `X-content/X`) | 3.0:1 | 4.5:1 |

The `contrast-checker.mjs` gate exits non-zero iff AA failures exist; AAA is reported as advisory
only and never affects the exit code.

### Phase 172 rendered boundary corrections

- The header uses one named layout authority. At 640px and below, the brand occupies the first row and Jump/theme controls share the second; the keyboard badge is omitted on this touch-sized layout. Desktop retains the shortcut beside the Jump control. Theme icon targets are 44px.
- Schema cards and workspace paths wrap long identifiers without expanding the page. Record headings use the 16px h3 role.
- Code regions expose a name and keyboard focus for contained scrolling. The native schema select has an explicit accessible name. Phoenix upload labels use the generated upload reference.
- Saved search rows and successor controls have filename-derived identities. Modal return focus waits for the LiveView patch and rejects a connected trigger that has been reused for a different file.

## Task baseline controls

The flat navigation orders Search immediately after Control room. Native schema radios
remain visible; a single schema is context rather than a disabled picker. Search uses
one form surface with query and result limit beside one another on wider screens.
Saved searches use separator rows rather than cards nested inside action containers.

`.ops-time__stamp` is a plain timestamp button with a small copy icon, no link underline,
and normal keyboard focus. One UTC/local preference applies to all shared time values.
Copying preserves the original ISO string and source precision; failed copying reveals
selectable exact text and persistent recovery feedback. Unknown values have no button.
Retained source evidence wraps into one column on mobile and two columns on wider screens.

Index settings use a real declared/live comparison with a focusable scroll region when
needed. Specific differences replace overlapping mismatch counts and raw report-version
metadata. Settings agreement is separate from operation completion and document visibility.

- `ops_help_link`: contextual Help in a new tab, surrounding text size, external-window icon and accessible notice.
