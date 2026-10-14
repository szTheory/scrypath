// Browser-local display preference. Exact source strings remain untouched for copying.
const key = "scrypath:time-zone"
let preference = "utc"
try { preference = localStorage.getItem(key) === "local" ? "local" : "utc" } catch (_) {}

export function formatTimes(root = document) {
  const options = {year: "numeric", month: "short", day: "numeric", hour: "2-digit", minute: "2-digit", second: "2-digit", timeZoneName: "short", ...(preference === "utc" ? {timeZone: "UTC"} : {})}
  const formatter = new Intl.DateTimeFormat(undefined, options)
  root.querySelectorAll("[data-ops-time-value]").forEach(time => {
    const date = new Date(time.getAttribute("datetime"))
    if (Number.isNaN(date.getTime())) return
    time.textContent = formatter.format(date)
  })
}

export function syncTimePreference() {
  document.querySelectorAll("[data-ops-time-zone]").forEach(select => { select.value = preference })
  formatTimes()
}

document.addEventListener("change", event => {
  if (!event.target.matches("[data-ops-time-zone]")) return
  preference = event.target.value === "local" ? "local" : "utc"
  try { localStorage.setItem(key, preference) } catch (_) {}
  syncTimePreference()
})
window.addEventListener("storage", event => {
  if (event.key !== key && event.key !== null) return
  preference = event.newValue === "local" ? "local" : "utc"
  syncTimePreference()
})
