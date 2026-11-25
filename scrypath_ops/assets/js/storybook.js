// Loaded by the component catalog iframe (dev and test only). Phoenix and LiveView are prepended by
// the storybook itself, so only the operator hooks and the theme attribute live here. The hook list
// equals the app.js hook list minus the colocated hooks (none exist under lib).
import {CommandPalette, OpsNavDrawer, OpsModal, OpsRefreshButton, OpsToast, OpsTimestampCopy} from "./ops_hooks"

import {OpsSearchDraft, OpsHelpAnchor, OpsFieldValidation} from "./ops_search"

// The storybook puts the theme on <body>; the ops System rules key on the <html> attribute. The
// /storybook/iframe route also names the theme in the query, but the frames on a story page are
// srcdoc documents with no query, so a story frame mirrors its body's attribute. "system" (or
// anything else) sets nothing, so the ops stylesheet follows the browser preference.
;(function () {
  const root = document.documentElement
  const apply = (theme) => {
    if (theme === "light" || theme === "dark") root.setAttribute("data-theme", theme)
    else root.removeAttribute("data-theme")
  }
  const query = new URLSearchParams(window.location.search).get("theme")
  if (query) apply(query)
  const mirror = () => {
    // Only a story frame; the storybook's own page keeps its own theme handling.
    if (!document.getElementById("psb-iframe-container")) return
    const sync = () => {
      if (document.body.hasAttribute("data-theme")) apply(document.body.getAttribute("data-theme"))
    }
    sync()
    new MutationObserver(sync).observe(document.body, {attributes: true, attributeFilter: ["data-theme"]})
    // A story page sizes each frame to its content. The operator shell asks for at least a window's
    // height, which inside a frame is the frame's own height plus the header: the bottom is cut off.
    if (window.location.href !== "about:srcdoc") return
    const style = document.createElement("style")
    style.textContent = "#psb-iframe-container .ops-shell-frame, #psb-iframe-container .min-h-screen { min-height: 0; }"
    document.head.appendChild(style)
  }
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", mirror, {once: true})
  else mirror()
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
  const stories = "story-variations-scrypath_ops_catalog_stories_"
  const composed = `[id^="${stories}"]:not([id^="${stories}primitives_"]) .psb-variation-block`
  const style = document.createElement("style")
  style.id = "ops-catalog-shell"
  style.textContent = [
    "html:has(#psb-main) { background-color: var(--psb-color-sidebar); color-scheme: normal; }",
    "@media (min-width: 1024px) {",
    "  #psb-main { margin: 0; border-width: 0 0 0 1px; border-radius: 0; box-shadow: none; }",
    "}",
    // Only a primitive is read alongside its code. Patterns, areas, screens and flows are read by
    // looking at them, so their preview takes the full width and the code block is dropped. The
    // library names each story's wrapper after its module, which carries the tier.
    `${composed} > [id$="-component"] { grid-column: 1 / -1; }`,
    `${composed} > [id$="-code"] { display: none; }`
  ].join("\n")
  document.head.appendChild(style)
})()

// The library keeps a rendered story frame when only the theme changes (its id does not name the
// theme), so the storybook's own page passes the newly picked theme on to the frames it holds.
window.addEventListener("phx:navigate", () => {
  const theme = new URLSearchParams(window.location.search).get("theme")
  if (!theme) return
  document.querySelectorAll("#psb-main iframe").forEach((frame) => {
    frame.contentDocument?.body?.setAttribute("data-theme", theme)
  })
})

window.storybook = {
  Hooks: {CommandPalette, OpsNavDrawer, OpsModal, OpsRefreshButton, OpsToast, OpsTimestampCopy, OpsSearchDraft, OpsHelpAnchor, OpsFieldValidation}
}
