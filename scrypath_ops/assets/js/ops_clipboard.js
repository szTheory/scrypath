// Copy from the user gesture in both host and standalone bundles. A server
// round trip must never claim that a browser clipboard operation succeeded.
const attempts = new WeakMap()
document.addEventListener("click", async event => {
  const button = event.target instanceof Element ? event.target.closest("[data-ops-copy-text]") : null
  if (!button) return
  const group = button.closest("[data-ops-copy-group]")
  const feedback = group?.querySelector("[data-ops-copy-feedback]")
  const fallback = group?.querySelector("[data-ops-copy-fallback]")
  if (!feedback || !fallback) return
  const attempt = (attempts.get(button) || 0) + 1
  attempts.set(button, attempt)
  const source = button.dataset.opsCopyText
  feedback.textContent = ""
  fallback.hidden = true
  try {
    if (typeof navigator.clipboard?.writeText !== "function") throw new Error("Clipboard unavailable")
    await navigator.clipboard.writeText(source)
    if (!button.isConnected || attempts.get(button) !== attempt || source !== button.dataset.opsCopyText) return
    feedback.textContent = "Diagnostics copied"
    setTimeout(() => { if (attempts.get(button) === attempt) feedback.textContent = "" }, 4000)
  } catch (_) {
    if (!button.isConnected || attempts.get(button) !== attempt || source !== button.dataset.opsCopyText) return
    feedback.textContent = "Could not copy. Select and copy the details below."
    fallback.hidden = false
  }
})
