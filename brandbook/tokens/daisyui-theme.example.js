/* ============================================================================
   ScrypathOps — daisyUI theme example
   ----------------------------------------------------------------------------
   The live Ops source of truth is scrypath_ops/assets/css/app.css. These
   copyable objects keep the same light/dark shape for host configurations;
   their values follow the CSS source and are separate from the warm --sp-*
   brand palette in tokens.css.
   In daisyUI v5 themes are normally declared with the @plugin "daisyui/theme"
   at-rule in CSS (see the CSS block at the bottom). This JS object is provided
   as an example for tooling / Tailwind-config style setups.

   Colors are sRGB hex. `primary-strong` is a floor used by the contrast
   gate (contrast-pairs.mjs) — keep it in lockstep if you change primary.
   ============================================================================ */

export const scrypathLight = {
  "color-scheme": "light",
  "--color-base-100": "#ffffff",
  "--color-base-200": "#f3f5f8",
  "--color-base-300": "#dce2e9",
  "--color-base-content": "#202124",
  "--color-primary": "#5b4ad1",
  "--color-primary-content": "#ffffff",
  "--color-primary-strong": "#5b4ad1",
  "--color-secondary": "#a85d2e",
  "--color-secondary-content": "#fffdf8",
  "--color-accent": "#5b4ad1",
  "--color-accent-content": "#ffffff",
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
  "--ops-bg": "#f3f5f8",
  "--ops-surface-1": "#ffffff",
  "--ops-surface-2": "#edf1f5",
  "--ops-selection": "#eeebff",
  "--ops-theme-selection": "#ffffff",
  "--ops-text-muted": "color-mix(in oklch, var(--color-base-content) 64%, transparent)",
  "--ops-warning-text": "#805000",
  "--ops-error-text": "#ad2922",
};

export const scrypathDark = {
  "color-scheme": "dark",
  "--color-base-100": "#191e25",
  "--color-base-200": "#111419",
  "--color-base-300": "#353d48",
  "--color-base-content": "#f1f2f4",
  "--color-primary": "#aaa0ff",
  "--color-primary-content": "#111419",
  "--color-primary-strong": "#aaa0ff",
  "--color-secondary": "#c17a3e",
  "--color-secondary-content": "#0c0f14",
  "--color-accent": "#aaa0ff",
  "--color-accent-content": "#111419",
  "--color-neutral": "#353d48",
  "--color-neutral-content": "#f1f2f4",
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
  "--ops-bg": "#111419",
  "--ops-surface-1": "#191e25",
  "--ops-surface-2": "#222831",
  "--ops-selection": "#302b4c",
  "--ops-theme-selection": "#222831",
  "--ops-text-muted": "color-mix(in oklch, var(--color-base-content) 64%, transparent)",
  "--ops-warning-text": "#f2c66d",
  "--ops-error-text": "#ffaaa2",
};

export default { light: scrypathLight, dark: scrypathDark };

/* ----------------------------------------------------------------------------
   Equivalent daisyUI v5 CSS (what actually lives in scrypath_ops/assets/css/app.css):

   @plugin "daisyui/theme" {
     name: "light";
     default: true;
     color-scheme: light;
     --color-base-100: #ffffff;
     ... (as above) ...
   }
   @plugin "daisyui/theme" {
     name: "dark";
     prefersdark: true;
     color-scheme: dark;
     --color-base-100: #191e25;
     ... (as above) ...
   }
   ---------------------------------------------------------------------------- */
