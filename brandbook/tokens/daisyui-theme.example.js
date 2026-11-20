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

   Colors are sRGB hex. The plum/orchid roles come from the pinned brand book
   (brand/tokens.json); text roles hold 4.5:1 on every backdrop and the
   control edge holds 3:1, both proven from app.css by contrast-checker.mjs.
   ============================================================================ */

export const scrypathLight = {
  "color-scheme": "light",
  "--color-base-100": "#ffffff",
  "--color-base-200": "#f8f4f2",
  "--color-base-300": "#e0d5d1",
  "--color-base-content": "#1e1220",
  "--color-primary": "#7b2d6b",
  "--color-primary-content": "#ffffff",
  "--color-secondary": "#f0e9e6",
  "--color-secondary-content": "#1e1220",
  "--color-accent": "#7b2d6b",
  "--color-accent-content": "#ffffff",
  "--color-neutral": "#1e1220",
  "--color-neutral-content": "#f8f4f2",
  "--color-info": "#5e5360",
  "--color-info-content": "#ffffff",
  "--color-success": "#1d6b3c",
  "--color-success-content": "#ffffff",
  "--color-warning": "#8a5a00",
  "--color-warning-content": "#ffffff",
  "--color-error": "#b0360b",
  "--color-error-content": "#ffffff",
  "--radius-selector": "0.25rem",
  "--radius-field": "0.25rem",
  "--radius-box": "0.5rem",
  "--size-selector": "0.21875rem",
  "--size-field": "0.21875rem",
  "--border": "1.5px",
  "--depth": "1",
  "--noise": "0",
  /* elevation surfaces, selection, control edge and sync status colors (ops-specific) */
  "--ops-bg": "#f8f4f2",
  "--ops-surface-1": "#ffffff",
  "--ops-sunken": "#f0e9e6",
  "--ops-selected": "#ebdfe7",
  "--ops-selection": "#ebdfe7",
  "--ops-theme-selection": "#ebdfe7",
  "--ops-control-edge": "#8a7a8e",
  "--ops-text-muted": "#5e5360",
  "--ops-status-failed": "#b0360b",
  "--ops-status-retrying": "#8a5a00",
  "--ops-status-pending": "#615765",
  "--ops-status-clear": "#1d6b3c",
  "--ops-warning-text": "#8a5a00",
  "--ops-error-text": "#b0360b",
};

export const scrypathDark = {
  "color-scheme": "dark",
  "--color-base-100": "#201624",
  "--color-base-200": "#160e19",
  "--color-base-300": "#3a2a3e",
  "--color-base-content": "#f4edf3",
  "--color-primary": "#d58bc4",
  "--color-primary-content": "#160e19",
  "--color-secondary": "#3a2a3e",
  "--color-secondary-content": "#f4edf3",
  "--color-accent": "#d58bc4",
  "--color-accent-content": "#160e19",
  "--color-neutral": "#3a2a3e",
  "--color-neutral-content": "#f4edf3",
  "--color-info": "#bbaac0",
  "--color-info-content": "#160e19",
  "--color-success": "#7fcb9a",
  "--color-success-content": "#160e19",
  "--color-warning": "#e3b25c",
  "--color-warning-content": "#160e19",
  "--color-error": "#ff9a6b",
  "--color-error-content": "#160e19",
  "--radius-selector": "0.25rem",
  "--radius-field": "0.25rem",
  "--radius-box": "0.5rem",
  "--size-selector": "0.21875rem",
  "--size-field": "0.21875rem",
  "--border": "1.5px",
  "--depth": "1",
  "--noise": "0",
  "--ops-bg": "#160e19",
  "--ops-surface-1": "#201624",
  "--ops-sunken": "#110a14",
  "--ops-selected": "#2b2130",
  "--ops-selection": "#2b2130",
  "--ops-theme-selection": "#2b2130",
  "--ops-control-edge": "#8f7f94",
  "--ops-text-muted": "#bbaac0",
  "--ops-status-failed": "#ff9a6b",
  "--ops-status-retrying": "#e3b25c",
  "--ops-status-pending": "#ab9bb0",
  "--ops-status-clear": "#7fcb9a",
  "--ops-warning-text": "#e3b25c",
  "--ops-error-text": "#ff9a6b",
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
     --color-base-100: #201624;
     ... (as above) ...
   }
   ---------------------------------------------------------------------------- */
