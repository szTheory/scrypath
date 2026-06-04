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
//
// Field reference:
//   selector  — exact CSS selector as it appears in app.css
//   alpha     — decimal 0–1 (e.g. 0.55 for 55%)
//   fg_token  — token name without `--color-` prefix (always "base-content" here)
//   bg_token  — token name without `--color-` prefix (the opaque surface)
//   role      — "text" → AA 4.5 / AAA 7.0
//               "large" → AA 3.0 (uppercase/bold qualifies as large text per WCAG)
//               "ui"    → AA 3.0 (non-text UI components)
//               decorative  → skipped by checker (no threshold applied)
//   note      — human-readable description

export const MUTED_PAIRS = [
  // app.css line 537 — meta/secondary text
  {
    selector: ".ops-text-meta",
    alpha: 0.55,
    fg_token: "base-content",
    bg_token: "base-100",
    role: "text",
    note: "meta/secondary text — xs size"
  },
  // app.css line 691 — breadcrumb text
  {
    selector: ".ops-trail__crumb",
    alpha: 0.60,
    fg_token: "base-content",
    bg_token: "base-100",
    role: "text",
    note: "breadcrumb text"
  },
  // app.css line 727 — uppercase eyebrow label (large text: uppercase + font-weight 700)
  {
    selector: ".ops-handoff__eyebrow",
    alpha: 0.50,
    fg_token: "base-content",
    bg_token: "base-100",
    role: "large",
    note: "uppercase eyebrow label — qualifies as large text by weight+size"
  },
  // app.css line 746 — hint copy
  {
    selector: ".ops-handoff__hint",
    alpha: 0.60,
    fg_token: "base-content",
    bg_token: "base-100",
    role: "text",
    note: "hint copy"
  },
  // app.css line 833 — hint copy
  {
    selector: ".ops-preflight__hint",
    alpha: 0.60,
    fg_token: "base-content",
    bg_token: "base-100",
    role: "text",
    note: "hint copy"
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
  // app.css line 1115 — command palette item hint
  {
    selector: ".ops-cmdk__item-hint",
    alpha: 0.55,
    fg_token: "base-content",
    bg_token: "base-100",
    role: "text",
    note: "palette item hint"
  },
  // app.css line 1120 — command palette empty state
  {
    selector: ".ops-cmdk__empty",
    alpha: 0.55,
    fg_token: "base-content",
    bg_token: "base-100",
    role: "text",
    note: "palette empty state"
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
