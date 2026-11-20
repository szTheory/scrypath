// How the site handles color themes.
//
//   'picker'     ships the Light, Dark and System picker, assets/theme.js, and the dark,
//                system and print blocks of the generated tokens.css.
//   'light-only' is the pre-authorized SITE-02 fallback (D-25): no picker, no theme.js, and
//                tokens.css holds only the light :root block.
//
// build.mjs, the static contract (site-contract.test.mjs) and check.mjs all read this one
// constant and are mode-aware, so switching it needs no edit to any test or assertion.
export const THEME_MODE = 'picker';
