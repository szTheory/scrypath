// scrypath_ops/assets/css/contrast-pairs.mjs
//
// Muted-alpha text manifest (D-11): ONLY muted cases that are opacity-mixes of
// base-content via `color-mix(in oklch, var(--color-base-content) NN%, transparent)`.
//
// Design constraints:
//   (1) References TOKEN NAMES not hex — hex lives in app.css only (D-10). No
//       `--color-*` declarations, no hex literals, no import of app.css.
//   (2) Alpha compositing is sRGB, not OKLCH: for opacity-only mixes the OKLCH
//       mix-space is a no-op on the pre-composite color (only alpha changes), so
//       composite over the opaque surface in sRGB:
//         out = fg·α + bg·(1−α)  per channel  (D-12)
//       This matches what axe-core itself does, so the fast checker and the browser
//       gate produce one verdict.
//   (3) The D-15 lockstep guard in contrast-checker.mjs validates that every
//       `color: color-mix(in oklch, var(--color-base-content) NN%, transparent)`
//       occurrence in app.css (the `color:` CSS property only — not border-color,
//       background, box-shadow) is tracked here. Any untracked (alpha%, selector)
//       pair causes `make contrast` to fail.
//   (4) Phase 187: `--ops-text-muted` is an opaque hex (Muted Ink on light, Muted Pale
//       on dark), so the entries that routed through `color: var(--ops-text-muted)`
//       are gone. That token is covered by the muted text pairs on four backdrops
//       and by the opaque-token guard in contrast-checker.mjs. Only the direct
//       `color: color-mix(...)` declarations remain here, until the plan that
//       converts them retires this manifest.
//
// Field reference:
//   selector  — exact CSS selector as it appears in app.css
//   alpha     — decimal 0–1 (e.g. 0.55 for 55%)
//   fg_token  — token name without `--color-` prefix (always "base-content" here)
//   bg_token  — token name without `--color-` prefix (the opaque surface)
//   role      — "text" → AA 4.5 / AAA 7.0
//               "large" → AA 3.0 (only text that meets WCAG large-text size/weight)
//               "ui"    → AA 3.0 (non-text UI components)
//               decorative  → skipped by checker (no threshold applied)
//   note      — human-readable description

export const MUTED_PAIRS = [
  // app.css line 748 — timestamp label text
  {
    selector: ".ops-time__label",
    alpha: 0.62,
    fg_token: "base-content",
    bg_token: "base-100",
    role: "text",
    note: "timestamp label text"
  },
  // app.css line 877 — sidebar nav group label
  {
    selector: ".ops-nav-group__label",
    alpha: 0.64,
    fg_token: "base-content",
    bg_token: "base-100",
    role: "text",
    note: "uppercase sidebar nav group label"
  },
  // app.css line 899 — sidebar nav item text
  {
    selector: ".ops-nav-item",
    alpha: 0.74,
    fg_token: "base-content",
    bg_token: "base-100",
    role: "text",
    note: "sidebar nav item text"
  },
  // app.css line 815 — fieldset hint copy
  {
    selector: ".ops-fieldset__hint",
    alpha: 0.70,
    fg_token: "base-content",
    bg_token: "base-100",
    role: "text",
    note: "fieldset hint copy"
  },
  // app.css line 898 — card body text (intent-card bg is base-100 94% ≈ opaque base-100)
  {
    selector: ".ops-intent-card__summary",
    alpha: 0.75,
    fg_token: "base-content",
    bg_token: "base-100",
    role: "text",
    note: "card body text"
  },
  // app.css line 479 — chip value text (default/no-tone state)
  {
    selector: ".ops-tone-chip__value",
    alpha: 0.75,
    fg_token: "base-content",
    bg_token: "base-100",
    role: "text",
    note: "chip value text (default/no-tone state)"
  },
  // app.css line 493 — empty-state body text
  {
    selector: ".ops-empty-hero__body",
    alpha: 0.74,
    fg_token: "base-content",
    bg_token: "base-100",
    role: "text",
    note: "empty-state body text"
  },
  // app.css line 431 — neutral badge text (badge bg is base-200 74% ≈ base-200, not base-100)
  {
    selector: ".ops-badge-neutral",
    alpha: 0.82,
    fg_token: "base-content",
    bg_token: "base-200",
    role: "text",
    note: "neutral badge text"
  },
  // app.css line 985 — table row header text
  {
    selector: ".ops-signal-table th[scope=\"row\"]",
    alpha: 0.78,
    fg_token: "base-content",
    bg_token: "base-100",
    role: "text",
    note: "table row header text"
  },
  // app.css line 1144 — cheatsheet description text
  {
    selector: ".ops-cheatsheet__row dd",
    alpha: 0.70,
    fg_token: "base-content",
    bg_token: "base-100",
    role: "text",
    note: "cheatsheet description text"
  },
  // app.css line 711 — decorative separator: NOT contrast-gated
  {
    selector: ".ops-trail__sep",
    alpha: 0.35,
    fg_token: "base-content",
    bg_token: "base-100",
    role: "decorative",
    note: "breadcrumb separator — decorative, not readable text"
  }
];

// Exact live indicator declarations. Suppressions are explicit inventory entries;
// they do not claim a visible indicator. Global outlines sit outside the control;
// the menu item is inset and is also checked against its focused fill.
export const FOCUS_BINDINGS = [
  { selector: ":focus-visible", offset: "2px" },
  { selector: ".ops-command-hint:focus-visible", offset: "2px" },
  { selector: ".ops-schema-picker__option:has(input:focus-visible)", offset: "2px" },
  { selector: ".ops-cmdk__input:focus", suppressed: true },
  { selector: ".ops-saved-search-menu__item:focus-visible", offset: "-2px" },
  { selector: ".ops-sheet__panel:focus", suppressed: true },
  { selector: ".ops-sheet__header h2:focus", suppressed: true },
  { selector: ".ops-sheet__header h2:focus-visible", offset: "2px" },
  { selector: ".ops-filter-chip:has(input:focus-visible)", offset: "2px" },
];

export const SURFACE_BINDINGS = [
  { selector: ".ops-shell", property: "background-color", background: "ops-bg" },
  { selector: ".ops-header", background: "ops-surface-1" },
  { selector: ".ops-panel", background: "ops-surface-1" },
  { selector: ".ops-sidebar", expression: "color-mix(in oklch, var(--color-base-100) 97%, transparent)" },
  { selector: ".ops-command-hint", expression: "color-mix(in oklch, var(--ops-surface-2) 56%, transparent)" },
  { selector: "body", background: "color-base-200" },
  { selector: ".ops-filter-chip--selected", background: "ops-selection" },
  { selector: ".ops-theme-toggle__button[data-theme-selected=\"true\"]", background: "ops-theme-selection" },
  { selector: ".ops-saved-search-menu", background: "color-base-100" },
  { selector: ".ops-saved-search-menu__item:hover:not(:disabled), .ops-saved-search-menu__item:focus-visible", background: "ops-surface-2" },
  { selector: ".ops-sheet__panel", background: "color-base-100" },
];

// ─── Phase 187 brand pair matrix (A11Y-01: N-03, N-04, N-05) ───────────────────
//
// Every name below is a custom property name (without the leading `--`), never a hex: the checker
// resolves each one from the two theme blocks in app.css, so a recolor changes the verdict and
// this file never needs to repeat a value.

export const BRAND_PAIR_MATRIX = {
  // N-03: 7 text roles on 4 backdrops, in both themes (56 pairs), 4.5:1 or better, unrounded.
  text: {
    min: 4.5,
    roles: [
      "color-base-content",
      "ops-text-muted",
      "color-primary",
      "ops-status-failed",
      "ops-status-retrying",
      "ops-status-pending",
      "ops-status-clear",
    ],
    backdrops: ["color-base-200", "color-base-100", "ops-sunken", "ops-selected"],
  },
  // N-04: Control Edge is the only edge of a control, so it needs 3:1 on every backdrop it sits on
  // and on the overlay surface (LD-3: overlays use the base-100 fill).
  controlEdge: {
    property: "ops-control-edge",
    min: 3.0,
    backdrops: ["color-base-200", "color-base-100", "ops-sunken", "ops-selected"],
    overlay: "color-base-100",
  },
  // N-04: the focus ring, the selection line and the link color are non-text uses of the primary.
  primaryNonText: {
    property: "color-primary",
    min: 3.0,
    backdrops: ["color-base-200", "color-base-100", "ops-sunken", "ops-selected"],
  },
  // N-04: button labels against their fills (the one Plum button; the default Ink-on-Panel button).
  buttonLabels: {
    min: 4.5,
    pairs: [
      { fg: "color-primary-content", bg: "color-primary" },
      { fg: "color-base-content", bg: "color-base-100" },
    ],
  },
  // N-05: Failed and Retrying differ by at least this many degrees of CIELAB hue angle.
  statusHue: {
    failed: "ops-status-failed",
    retrying: "ops-status-retrying",
    minDegrees: 25,
  },
};

// N-05: each pair published in brand/brand.json (color.contrastPairs, by pair id) is bound to the
// custom properties that carry its two colors in each theme. The checker recomputes the ratio from
// the resolved properties and compares it, to two decimals, with the number the book prints, so
// recomputing from the book's own hex text can never satisfy it. Every published pair has exactly
// one binding here and every binding names a published pair.
export const PUBLISHED_PAIR_BINDINGS = {
  body: {
    light: { fg: "color-base-content", bg: "color-base-200" },
    dark: { fg: "color-base-content", bg: "color-base-200" },
  },
  descriptor: {
    light: { fg: "ops-text-muted", bg: "color-base-200" },
    dark: { fg: "ops-text-muted", bg: "color-base-200" },
  },
  caption: {
    light: { fg: "ops-text-muted", bg: "color-base-100" },
    dark: { fg: "ops-text-muted", bg: "color-base-100" },
  },
  "application-copy": {
    light: { fg: "color-base-content", bg: "color-base-100" },
    dark: { fg: "color-base-content", bg: "color-base-100" },
  },
  link: {
    light: { fg: "color-primary", bg: "color-base-100" },
    dark: { fg: "color-primary", bg: "color-base-100" },
  },
  focus: {
    light: { fg: "color-primary", bg: "color-base-200" },
    dark: { fg: "color-primary", bg: "color-base-200" },
  },
  artwork: {
    light: { fg: "color-primary", bg: "color-base-200" },
    dark: { fg: "color-primary", bg: "color-base-200" },
  },
  button: {
    light: { fg: "color-primary-content", bg: "color-primary" },
    dark: { fg: "color-primary-content", bg: "color-primary" },
  },
  "selected-row": {
    light: { fg: "ops-text-muted", bg: "ops-selected" },
    dark: { fg: "ops-text-muted", bg: "ops-selected" },
  },
  "selected-status": {
    light: { fg: "ops-status-failed", bg: "ops-selected" },
    dark: { fg: "ops-status-failed", bg: "ops-selected" },
  },
  "status-failed": {
    light: { fg: "ops-status-failed", bg: "color-base-100" },
    dark: { fg: "ops-status-failed", bg: "color-base-100" },
  },
  "status-retrying": {
    light: { fg: "ops-status-retrying", bg: "color-base-100" },
    dark: { fg: "ops-status-retrying", bg: "color-base-100" },
  },
  "status-pending": {
    light: { fg: "ops-status-pending", bg: "color-base-100" },
    dark: { fg: "ops-status-pending", bg: "color-base-100" },
  },
  "status-clear": {
    light: { fg: "ops-status-clear", bg: "color-base-100" },
    dark: { fg: "ops-status-clear", bg: "color-base-100" },
  },
};
