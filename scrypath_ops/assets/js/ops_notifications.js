// Browser-only actions use the same notification stack as server flashes.
// Never move focus or insert confirmation text into the invoking control.
let dismissTimer
let returnFocus

export function notify(message, kind = "info", source = null) {
  const toast = document.querySelector("[data-ops-client-toast]")
  if (!toast) return
  window.clearTimeout(dismissTimer)
  const text = toast.querySelector("[data-ops-notification-message]")
  const fallback = toast.querySelector("[data-ops-notification-source]")
  text.textContent = message
  text.setAttribute("role", kind === "error" ? "alert" : "status")
  fallback.textContent = source ?? ""
  fallback.hidden = source == null
  toast.classList.toggle("ops-flash--error", kind === "error")
  toast.classList.toggle("ops-flash--info", kind !== "error")
  returnFocus = document.activeElement
  toast.hidden = false
  if (kind !== "error") dismissTimer = window.setTimeout(() => { toast.hidden = true }, 4000)
}

document.addEventListener("click", event => {
  if (event.target instanceof Element && event.target.closest("[data-ops-notification-close]")) {
    window.clearTimeout(dismissTimer)
    document.querySelector("[data-ops-client-toast]")?.setAttribute("hidden", "")
    if (returnFocus instanceof HTMLElement && returnFocus.isConnected) returnFocus.focus()
  }
})
