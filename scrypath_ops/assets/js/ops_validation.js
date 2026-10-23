// Native constraints with consistent, task-specific feedback. No requests on blur.
const touched = new WeakSet()
let pendingFocus = null
let pointerButton = null
function focusInvalid(field) {
  pendingFocus = field
  requestAnimationFrame(() => { if (pendingFocus === field && field.isConnected) field.focus() })
}
// Later user intent wins over validation focus, including a pending LiveView change patch.
document.addEventListener("pointerdown", event => {
  pendingFocus = null
  pointerButton = event.target instanceof Element ? event.target.closest("button") : null
}, true)
document.addEventListener("pointerup", () => { pointerButton = null }, true)
document.addEventListener("keydown", () => { pendingFocus = null }, true)
// Saved search names: up to 120 characters after trimming, no control characters.
const maxNameLength = 120
const invalidName = value => [...value.trim()].length > maxNameLength || /\p{Cc}/u.test(value)
function errorFor(field) {
  const value = field.value
  const label = field.labels?.[0]?.textContent.trim() || "this field"
  if (field.validity.badInput) return "Enter a whole number."
  if (field.required && !value.trim()) return `Enter ${label.toLowerCase()}.`
  if (field.type === "number" && value === "" && !field.required) return ""
  if (field.type === "number" && (value === "" || !Number.isInteger(Number(value)) || Number(value) < Number(field.min) || (field.max && Number(value) > Number(field.max)))) return `Enter a whole number from ${field.min} to ${field.max}.`
  if (/basename|new-name|to-name/.test(field.id) && value && invalidName(value)) return `Enter a name of up to ${maxNameLength} characters.`
  if (field.dataset.opsMaxBytes && new TextEncoder().encode(value).length > Number(field.dataset.opsMaxBytes)) return `Shorten ${label.toLowerCase()} to ${field.dataset.opsMaxBytes} bytes or fewer. Non-English characters may use several bytes.`
  if (field.dataset.opsJson !== undefined && value.trim()) {
    try { const data = JSON.parse(value); if (!data || Array.isArray(data) || typeof data !== "object") return "Paste a JSON object for a saved search." }
    catch (_) { return "Check the JSON syntax: use double quotes and match brackets and braces." }
  }
  if (field.validity.patternMismatch) return "Match the requested format."
  return ""
}
function validate(field, edited = false) {
  if (!field.matches?.("[data-ops-validate]") || field.disabled) return true
  const error = errorFor(field)
  const message = document.getElementById(`${field.id}-error`)
  if (message?.dataset.serverError && !edited && !error) return true
  if (message) {
    message.textContent = error
    message.hidden = !error
    // A later input edit supersedes a prior server error; a new submit is still server-validated.
    message.removeAttribute("data-server-error")
  }
  if (message) { if (error) message.setAttribute("role", "alert"); else message.removeAttribute("role") }
  field.setAttribute("aria-invalid", error ? "true" : "false")
  const ids = new Set((field.getAttribute("aria-describedby") || "").split(/\s+/).filter(Boolean))
  if (error) ids.add(`${field.id}-error`); else ids.delete(`${field.id}-error`)
  field.setAttribute("aria-describedby", [...ids].join(" "))
  return !error
}
document.addEventListener("focusout", event => {
  const field = event.target
  if (!field.matches?.("[data-ops-validate]")) return
  touched.add(field)
  // Inserting an error between pointerdown and click can move the pressed button.
  // Submit validates after the click; cancel and other buttons keep their intended action.
  if (pointerButton && event.relatedTarget === pointerButton) return
  validate(field)
})
document.addEventListener("input", event => { pendingFocus = null; if (touched.has(event.target)) validate(event.target, true) })
// Invalid native submit fires before submit; suppress browser-only bubbles and expose our error.
document.addEventListener("invalid", event => {
  if (!event.target.matches?.("[data-ops-validate]")) return
  event.preventDefault(); touched.add(event.target); validate(event.target)
  const invalid = [...event.target.form.querySelectorAll("[data-ops-validate]")].find(field => !field.validity.valid)
  if (invalid) focusInvalid(invalid)
}, true)
document.addEventListener("submit", event => {
  const fields = [...event.target.querySelectorAll("[data-ops-validate]")]
  const invalid = fields.filter(field => { touched.add(field); return !validate(field) })
  if (invalid.length) { event.preventDefault(); event.stopImmediatePropagation(); focusInvalid(invalid[0]) }
}, true)

export const OpsFieldValidation = {
  updated() {
    const field = this.el.querySelector("[data-ops-validate]")
    if (field && touched.has(field) && !this.el.querySelector("[data-server-error]")?.dataset.serverError) validate(field)
    if (field && pendingFocus === field) focusInvalid(field)
  }
}
