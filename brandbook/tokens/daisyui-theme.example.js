/* ============================================================================
   scrypath — daisyUI theme (copy-paste mirror of the live scrypath_ops theme)
   ----------------------------------------------------------------------------
   This mirrors scrypath_ops/assets/css/app.css so adoption is copy-paste.
   In daisyUI v5 themes are normally declared with the @plugin "daisyui/theme"
   at-rule in CSS (see the CSS block at the bottom). This JS object is provided
   for tooling / Tailwind-config style setups and as the single source of truth.

   Colours are sRGB hex. `primary-strong` is a brand floor used by the contrast
   gate (contrast-pairs.mjs) — keep it in lockstep if you change primary.
   ============================================================================ */

export const scrypathLight = {
  "color-scheme": "light",
  "--color-base-100": "#fffdf8",
  "--color-base-200": "#faf7f2",
  "--color-base-300": "#ded8ce",
  "--color-base-content": "#141923",
  "--color-primary": "#5b4ad1",
  "--color-primary-content": "#f4f1ea",
  "--color-primary-strong": "#5b4ad1",
  "--color-secondary": "#a85d2e",
  "--color-secondary-content": "#fffdf8",
  "--color-accent": "#6c5ce7",
  "--color-accent-content": "#fffdf8",
  "--color-neutral": "#2a3446",
  "--color-neutral-content": "#f4f1ea",
  "--color-info": "#5ca9e6",
  "--color-info-content": "#0c0f14",
  "--color-success": "#4fae74",
  "--color-success-content": "#0c0f14",
  "--color-warning": "#d9a441",
  "--color-warning-content": "#0c0f14",
  "--color-error": "#d96262",
  "--color-error-content": "#0c0f14",
  "--radius-selector": "0.25rem",
  "--radius-field": "0.25rem",
  "--radius-box": "0.5rem",
  "--size-selector": "0.21875rem",
  "--size-field": "0.21875rem",
  "--border": "1.5px",
  "--depth": "1",
  "--noise": "0",
  /* elevation surfaces (ops-specific) */
  "--ops-bg": "#faf7f2",
  "--ops-surface-1": "#fffdf8",
  "--ops-surface-2": "#faf7f2",
  "--ops-text-muted": "color-mix(in oklch, var(--color-base-content) 64%, transparent)",
};

export const scrypathDark = {
  "color-scheme": "dark",
  "--color-base-100": "#141923",
  "--color-base-200": "#0c0f14",
  "--color-base-300": "#2a3446",
  "--color-base-content": "#f4f1ea",
  "--color-primary": "#6c5ce7",
  "--color-primary-content": "#f4f1ea",
  "--color-primary-strong": "#5b4ad1",
  "--color-secondary": "#c17a3e",
  "--color-secondary-content": "#0c0f14",
  "--color-accent": "#5b4ad1",
  "--color-accent-content": "#f4f1ea",
  "--color-neutral": "#2a3446",
  "--color-neutral-content": "#f4f1ea",
  "--color-info": "#5ca9e6",
  "--color-info-content": "#0c0f14",
  "--color-success": "#4fae74",
  "--color-success-content": "#0c0f14",
  "--color-warning": "#d9a441",
  "--color-warning-content": "#0c0f14",
  "--color-error": "#d96262",
  "--color-error-content": "#0c0f14",
  "--radius-selector": "0.25rem",
  "--radius-field": "0.25rem",
  "--radius-box": "0.5rem",
  "--size-selector": "0.21875rem",
  "--size-field": "0.21875rem",
  "--border": "1.5px",
  "--depth": "1",
  "--noise": "0",
  "--ops-bg": "#0c0f14",
  "--ops-surface-1": "#141923",
  "--ops-surface-2": "#1b2230",
  "--ops-text-muted": "color-mix(in oklch, var(--color-base-content) 64%, transparent)",
};

export default { light: scrypathLight, dark: scrypathDark };

/* ----------------------------------------------------------------------------
   Equivalent daisyUI v5 CSS (what actually lives in scrypath_ops/assets/css/app.css):

   @plugin "daisyui/theme" {
     name: "light";
     default: true;
     color-scheme: light;
     --color-base-100: #fffdf8;
     ... (as above) ...
   }
   @plugin "daisyui/theme" {
     name: "dark";
     prefersdark: true;
     color-scheme: dark;
     --color-base-100: #141923;
     ... (as above) ...
   }
   ---------------------------------------------------------------------------- */
