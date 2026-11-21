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

window.storybook = {
  Hooks: {CommandPalette, OpsNavDrawer, OpsModal, OpsRefreshButton, OpsToast, OpsTimestampCopy, OpsSearchDraft, OpsHelpAnchor, OpsFieldValidation}
}
