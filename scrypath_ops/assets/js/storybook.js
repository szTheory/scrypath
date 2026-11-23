// Loaded by the component catalog iframe (dev and test only). Phoenix and LiveView are prepended by
// the storybook itself, so only the operator hooks and the theme attribute live here. The hook list
// equals the app.js hook list minus the colocated hooks (none exist under lib).
import {CommandPalette, OpsNavDrawer, OpsModal, OpsRefreshButton, OpsToast, OpsTimestampCopy} from "./ops_hooks"

import {OpsSearchDraft, OpsHelpAnchor, OpsFieldValidation} from "./ops_search"

// The storybook puts the theme on <body>; the ops System rules key on the <html> attribute.
// "system" (or anything else) sets nothing, so the ops stylesheet follows the browser preference.
;(function () {
  const theme = new URLSearchParams(window.location.search).get("theme")
  if (theme === "light" || theme === "dark") document.documentElement.setAttribute("data-theme", theme)
})()

// The storybook sandbox class sets `font-family: serif` on <body>, and that beats the product
// stylesheet, so every story drew in a serif face while the real screens (which get the product
// sans from <html>) did not. Give the iframe body the product family. The stylesheet stays as is:
// this is the one place that only the catalog loads.
;(function () {
  const useProductFont = () => { document.body.style.fontFamily = "var(--font-sans)" }
  if (document.body) useProductFont()
  else document.addEventListener("DOMContentLoaded", useProductFont, {once: true})
})()

// The storybook's own page (not the story iframes) imports the product stylesheet, which paints <html>
// with the ops dark page color when the OS is dark, and the library draws its content as an inset
// rounded card on that frame. Neither belongs in a review surface: fill the shell flat with the
// library's own sidebar color and drop the card's margin, radius and shadow, keeping one divider.
// Only the page that has the library's #psb-main is touched, so the story iframes are unchanged.
;(function () {
  const style = document.createElement("style")
  style.id = "ops-catalog-shell"
  style.textContent = [
    "html:has(#psb-main) { background-color: var(--psb-color-sidebar); color-scheme: normal; }",
    "@media (min-width: 1024px) {",
    "  #psb-main { margin: 0; border-width: 0 0 0 1px; border-radius: 0; box-shadow: none; }",
    "}"
  ].join("\n")
  document.head.appendChild(style)
})()

window.storybook = {
  Hooks: {CommandPalette, OpsNavDrawer, OpsModal, OpsRefreshButton, OpsToast, OpsTimestampCopy, OpsSearchDraft, OpsHelpAnchor, OpsFieldValidation}
}
