import {notify} from "./ops_notifications"

// Copy from the user gesture in both host and standalone bundles. A server
// round trip must never claim that a browser clipboard operation succeeded.
const attempts = new WeakMap()
document.addEventListener("click", async event => {
  const button = event.target instanceof Element ? event.target.closest("[data-ops-copy-text]") : null
  if (!button) return
  const group = button.closest("[data-ops-copy-group]")
  const feedback = group?.querySelector("[data-ops-copy-feedback]")
  const fallback = group?.querySelector("[data-ops-copy-fallback]")
  const attempt = (attempts.get(button) || 0) + 1
  attempts.set(button, attempt)
  const source = button.dataset.opsCopyText
  if (feedback) feedback.textContent = ""
  if (fallback) fallback.hidden = true
  try {
    if (typeof navigator.clipboard?.writeText !== "function") throw new Error("Clipboard unavailable")
    await navigator.clipboard.writeText(source)
    if (!button.isConnected || attempts.get(button) !== attempt || source !== button.dataset.opsCopyText) return
    notify(button.dataset.opsCopySuccess || "Diagnostics copied")
  } catch (_) {
    if (!button.isConnected || attempts.get(button) !== attempt || source !== button.dataset.opsCopyText) return
    notify("Could not copy. Select and copy the value below.", "error", source)
  }
})
