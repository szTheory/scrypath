// scrypath_ops/assets/css/contrast-pairs.mjs
//
// Data for the contrast checker (examples/scrypath_ecommerce/contrast-checker.mjs): the focus and
// surface bindings, the brand pair matrix and the published pair bindings.
//
// Design constraints:
//   (1) References TOKEN NAMES not hex — hex lives in app.css only (D-10). No
//       `--color-*` declarations, no hex literals, no import of app.css.
//   (2) Text never uses alpha (Phase 187, A11Y-01). The muted-alpha manifest this file used to hold
//       (with its D-11 and D-15 lockstep) is retired: every text declaration is Ink or the
//       opaque `--ops-text-muted`, so there is no alpha to composite and no manifest to keep in step.
//       The checker bans alpha on the `color` property directly (N-07) and bans any color-mix of the
//       primary, secondary or a status color (N-12); `--ops-text-muted` is covered by the muted text
//       pairs on four backdrops and by the opaque-token guard.

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
  // Inside a table scroller the ring is drawn inward so overflow clipping cannot cut it (A11Y-02).
  { selector: ".ops-table-scroll :focus-visible", offset: "-2px" },
];

export const SURFACE_BINDINGS = [
  { selector: ".ops-shell", property: "background-color", background: "ops-bg" },
  { selector: ".ops-header", background: "ops-surface-1" },
  { selector: ".ops-panel", background: "ops-surface-1" },
  { selector: ".ops-sidebar", expression: "color-mix(in oklch, var(--color-base-100) 97%, transparent)" },
  { selector: ".ops-command-hint", background: "color-base-100" },
  { selector: "body", background: "color-base-200" },
  { selector: ".ops-filter-chip--selected", background: "ops-selection" },
  { selector: ".ops-theme-toggle__button[data-theme-selected=\"true\"]", background: "ops-theme-selection" },
  { selector: ".ops-saved-search-menu", background: "color-base-100" },
  { selector: ".ops-saved-search-menu__item:hover:not(:disabled), .ops-saved-search-menu__item:focus-visible", background: "ops-sunken" },
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
