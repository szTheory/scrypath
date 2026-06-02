// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import {hooks as colocatedHooks} from "phoenix-colocated/scrypath_ops"
import topbar from "../vendor/topbar"

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

// Operator command palette (⌘K), cheat-sheet (?), and `r`-to-refresh. Pure
// client-side: items are live-navigation links, so no server event is needed.
const CommandPalette = {
  mounted() {
    this.cmdk = this.el.querySelector("#ops-cmdk")
    this.sheet = document.getElementById(this.el.dataset.cheatsheet)
    this.input = this.cmdk.querySelector("[data-cmdk-input]")
    this.empty = this.cmdk.querySelector("[data-cmdk-empty]")
    this.items = Array.from(this.cmdk.querySelectorAll("[data-cmdk-item]"))
    this.visible = this.items.slice()
    this.activeIndex = -1

    this.onKeydown = e => this.handleKeydown(e)
    window.addEventListener("keydown", this.onKeydown)

    this.cmdk.querySelectorAll("[data-cmdk-close]").forEach(el =>
      el.addEventListener("click", () => this.close()))
    this.sheet.querySelectorAll("[data-cmdk-close]").forEach(el =>
      el.addEventListener("click", () => this.closeSheet()))
    this.input.addEventListener("input", () => this.filter())
    this.input.addEventListener("keydown", e => this.inputKeydown(e))
  },
  destroyed() {
    window.removeEventListener("keydown", this.onKeydown)
  },
  isTyping() {
    const a = document.activeElement
    return !!a && (a.tagName === "INPUT" || a.tagName === "TEXTAREA" ||
      a.tagName === "SELECT" || a.isContentEditable)
  },
  isOpen() { return !this.cmdk.hasAttribute("hidden") },
  sheetOpen() { return !this.sheet.hasAttribute("hidden") },
  handleKeydown(e) {
    if ((e.metaKey || e.ctrlKey) && (e.key === "k" || e.key === "K")) {
      e.preventDefault()
      this.isOpen() ? this.close() : this.open()
      return
    }
    if (this.isOpen()) {
      if (e.key === "Escape") { e.preventDefault(); this.close() }
      return
    }
    if (this.sheetOpen()) {
      if (e.key === "Escape") { e.preventDefault(); this.closeSheet() }
      return
    }
    if (this.isTyping() || e.metaKey || e.ctrlKey || e.altKey) return
    if (e.key === "?") { e.preventDefault(); this.openSheet() }
    else if (e.key === "r") { this.refresh() }
  },
  open() {
    this.closeSheet()
    this.cmdk.removeAttribute("hidden")
    this.input.value = ""
    this.filter()
    this.input.focus()
  },
  close() {
    this.cmdk.setAttribute("hidden", "")
    this.setActive(-1)
  },
  openSheet() { this.sheet.removeAttribute("hidden") },
  closeSheet() { this.sheet.setAttribute("hidden", "") },
  refresh() {
    const btn = document.querySelector("[data-ops-refresh]")
    if (btn) btn.click()
  },
  filter() {
    const q = this.input.value.trim().toLowerCase()
    this.visible = []
    this.items.forEach(item => {
      const match = q === "" || (item.dataset.cmdkLabel || "").includes(q)
      item.parentElement.hidden = !match
      if (match) this.visible.push(item)
    })
    this.empty.hidden = this.visible.length > 0
    this.setActive(this.visible.length ? 0 : -1)
  },
  setActive(idx) {
    this.items.forEach(i => i.classList.remove("is-active"))
    this.activeIndex = idx
    const item = idx >= 0 && this.visible[idx]
    if (item) {
      item.classList.add("is-active")
      item.scrollIntoView({block: "nearest"})
    }
  },
  inputKeydown(e) {
    if (!this.visible.length) return
    if (e.key === "ArrowDown") {
      e.preventDefault()
      this.setActive((this.activeIndex + 1) % this.visible.length)
    } else if (e.key === "ArrowUp") {
      e.preventDefault()
      this.setActive((this.activeIndex - 1 + this.visible.length) % this.visible.length)
    } else if (e.key === "Enter") {
      e.preventDefault()
      const item = this.visible[this.activeIndex] || this.visible[0]
      if (item) { this.close(); item.click() }
    }
  },
}

const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: {...colocatedHooks, CommandPalette},
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())
window.addEventListener("phx:copy_run_diagnostics", async ({detail}) => {
  const text = detail?.text

  if (!text || !navigator.clipboard?.writeText) return

  try {
    await navigator.clipboard.writeText(text)
  } catch (_error) {
    // Flash feedback still confirms the action when clipboard permissions are unavailable.
  }
})

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({detail: reloader}) => {
    // Enable server log streaming to client.
    // Disable with reloader.disableServerLogs()
    reloader.enableServerLogs()

    // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
    //
    //   * click with "c" key pressed to open at caller location
    //   * click with "d" key pressed to open at function component definition location
    let keyDown
    window.addEventListener("keydown", e => keyDown = e.key)
    window.addEventListener("keyup", _e => keyDown = null)
    window.addEventListener("click", e => {
      if(keyDown === "c"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      } else if(keyDown === "d"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })
}
