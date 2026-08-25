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
    this.previousFocus = null

    this.onKeydown = e => this.handleKeydown(e)
    this.onCmdkKeydown = e => this.overlayKeydown(e, this.cmdk)
    this.onSheetKeydown = e => this.overlayKeydown(e, this.sheet)
    this.onCommandOpenClick = e => {
      const opener = e.target instanceof Element
        ? e.target.closest("[data-ops-command-open]")
        : null
      if (!opener) return

      e.preventDefault()
      this.open()
    }
    window.addEventListener("keydown", this.onKeydown)
    document.addEventListener("click", this.onCommandOpenClick)
    this.cmdk.addEventListener("keydown", this.onCmdkKeydown)
    this.sheet.addEventListener("keydown", this.onSheetKeydown)

    this.cmdk.querySelectorAll("[data-cmdk-close]").forEach(el =>
      el.addEventListener("click", () => this.close()))
    this.sheet.querySelectorAll("[data-cmdk-close]").forEach(el =>
      el.addEventListener("click", () => this.closeSheet()))
    this.input.addEventListener("input", () => this.filter())
    this.input.addEventListener("keydown", e => this.inputKeydown(e))
  },
  destroyed() {
    window.removeEventListener("keydown", this.onKeydown)
    document.removeEventListener("click", this.onCommandOpenClick)
    this.cmdk.removeEventListener("keydown", this.onCmdkKeydown)
    this.sheet.removeEventListener("keydown", this.onSheetKeydown)
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
    if (e.key === "?" || (e.key === "/" && e.shiftKey)) { e.preventDefault(); this.openSheet() }
    else if (e.key === "r") { this.refresh() }
  },
  open() {
    this.rememberFocus()
    this.closeSheet({restoreFocus: false})
    this.cancelDismiss(this.cmdk)
    this.cmdk.removeAttribute("hidden")
    this.input.value = ""
    this.filter()
    this.input.focus()
  },
  close({restoreFocus = true} = {}) {
    if (!this.isOpen()) return
    this.dismiss(this.cmdk)
    this.setActive(-1)
    if (restoreFocus) this.restoreFocus()
  },
  openSheet() {
    this.rememberFocus()
    this.cancelDismiss(this.sheet)
    this.sheet.removeAttribute("hidden")
    this.focusOverlay(this.sheet)
  },
  closeSheet({restoreFocus = true} = {}) {
    if (!this.sheetOpen()) return
    this.dismiss(this.sheet)
    if (restoreFocus) this.restoreFocus()
  },
  // A1 exit beat: play the crisp --ease-ops-exit dismissal (`.ops-cmdk--closing`, ~120ms)
  // before hiding, so close feels as intentional as open. Behavior is unchanged — the panel
  // still ends up [hidden]; this only eases the transition. Re-opening cancels any pending
  // close so an interrupted dismissal snaps back open (interruptibility). Reduced-motion makes
  // the animation ~instant via the global rule, so the panel still hides on the next frame.
  dismiss(el) {
    if (el.hasAttribute("hidden")) return
    if (el._opsCloseTimer) return
    el.classList.add("ops-cmdk--closing")
    el._opsCloseTimer = window.setTimeout(() => {
      el._opsCloseTimer = null
      el.classList.remove("ops-cmdk--closing")
      el.setAttribute("hidden", "")
    }, 160)
  },
  // Interrupt a pending dismissal (re-open mid-close): clear the timer + the closing class
  // so the panel stays open and re-enters cleanly instead of fading out under the user.
  cancelDismiss(el) {
    if (el._opsCloseTimer) {
      window.clearTimeout(el._opsCloseTimer)
      el._opsCloseTimer = null
    }
    el.classList.remove("ops-cmdk--closing")
  },
  refresh() {
    const btn = document.querySelector("[data-ops-refresh]")
    if (btn) btn.click()
  },
  rememberFocus() {
    const active = document.activeElement
    this.previousFocus = active && active !== document.body && active !== document.documentElement
      ? active
      : null
  },
  restoreFocus() {
    const target = this.previousFocus
    this.previousFocus = null
    if (target && target.isConnected && typeof target.focus === "function") {
      target.focus({preventScroll: true})
    }
  },
  focusableElements(root) {
    const selector = [
      "a[href]",
      "button:not([disabled])",
      "input:not([disabled])",
      "select:not([disabled])",
      "textarea:not([disabled])",
      "[tabindex]:not([tabindex='-1'])"
    ].join(",")

    return Array.from(root.querySelectorAll(selector)).filter(el =>
      !el.closest("[hidden]") && el.getAttribute("aria-hidden") !== "true")
  },
  focusOverlay(root) {
    const focusables = this.focusableElements(root)
    const panel = root.querySelector(".ops-cmdk__panel")
    const target = root === this.cmdk ? this.input : (focusables[0] || panel || root)
    target.focus({preventScroll: true})
  },
  overlayKeydown(e, root) {
    if (e.key !== "Tab") return

    const focusables = this.focusableElements(root)
    if (!focusables.length) {
      e.preventDefault()
      this.focusOverlay(root)
      return
    }

    const first = focusables[0]
    const last = focusables[focusables.length - 1]

    if (!root.contains(document.activeElement)) {
      e.preventDefault()
      first.focus({preventScroll: true})
    } else if (e.shiftKey && document.activeElement === first) {
      e.preventDefault()
      last.focus({preventScroll: true})
    } else if (!e.shiftKey && document.activeElement === last) {
      e.preventDefault()
      first.focus({preventScroll: true})
    }
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
    this.items.forEach(i => {
      i.classList.remove("is-active")
      i.setAttribute("aria-selected", "false")
    })
    this.input.removeAttribute("aria-activedescendant")
    this.activeIndex = idx
    const item = idx >= 0 && this.visible[idx]
    if (item) {
      item.classList.add("is-active")
      item.setAttribute("aria-selected", "true")
      this.input.setAttribute("aria-activedescendant", item.id)
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
      if (item) { this.close({restoreFocus: false}); item.click() }
    }
  },
}

const OpsNavDrawer = {
  mounted() {
    this.drawer = this.el.querySelector("[data-ops-nav-drawer]")
    this.panel = this.el.querySelector("[data-ops-nav-panel]")
    this.openers = Array.from(this.el.querySelectorAll("[data-ops-nav-open]"))
    this.closers = Array.from(this.el.querySelectorAll("[data-ops-nav-close]"))
    this.links = Array.from(this.el.querySelectorAll("[data-ops-nav-link]"))
    this.previousFocus = null
    this.closeTimer = null
    this.desktopQuery = window.matchMedia("(min-width: 1280px)")

    this.onKeydown = e => this.handleKeydown(e)
    this.onDesktopChange = () => {
      if (this.desktopQuery.matches) this.close({restoreFocus: false})
    }

    this.openers.forEach(el => el.addEventListener("click", () => this.open()))
    this.closers.forEach(el => el.addEventListener("click", () => this.close()))
    this.links.forEach(el => el.addEventListener("click", () => this.close({restoreFocus: false})))
    window.addEventListener("keydown", this.onKeydown)
    this.desktopQuery.addEventListener("change", this.onDesktopChange)
  },
  destroyed() {
    window.removeEventListener("keydown", this.onKeydown)
    this.desktopQuery.removeEventListener("change", this.onDesktopChange)
    document.body.classList.remove("ops-nav-drawer-open")
  },
  isOpen() {
    return this.drawer && !this.drawer.hasAttribute("hidden")
  },
  open() {
    if (!this.drawer || this.isOpen()) return

    this.previousFocus = document.activeElement
    if (this.closeTimer) {
      window.clearTimeout(this.closeTimer)
      this.closeTimer = null
    }

    this.drawer.removeAttribute("hidden")
    document.body.classList.add("ops-nav-drawer-open")
    this.openers.forEach(el => el.setAttribute("aria-expanded", "true"))
    window.requestAnimationFrame(() => {
      this.drawer.classList.add("is-open")
      this.focusPanel()
    })
  },
  close({restoreFocus = true} = {}) {
    if (!this.drawer || !this.isOpen()) return

    this.drawer.classList.remove("is-open")
    document.body.classList.remove("ops-nav-drawer-open")
    this.openers.forEach(el => el.setAttribute("aria-expanded", "false"))

    if (this.closeTimer) window.clearTimeout(this.closeTimer)
    this.closeTimer = window.setTimeout(() => {
      this.drawer.setAttribute("hidden", "")
      this.closeTimer = null
      if (restoreFocus) this.restoreFocus()
    }, 180)
  },
  handleKeydown(e) {
    if (!this.isOpen()) return

    if (e.key === "Escape") {
      e.preventDefault()
      this.close()
    } else if (e.key === "Tab") {
      this.trapFocus(e)
    }
  },
  focusableElements() {
    const selector = [
      "a[href]",
      "button:not([disabled])",
      "input:not([disabled])",
      "select:not([disabled])",
      "textarea:not([disabled])",
      "[tabindex]:not([tabindex='-1'])"
    ].join(",")

    return Array.from(this.panel.querySelectorAll(selector)).filter(el =>
      !el.closest("[hidden]") && el.getAttribute("aria-hidden") !== "true")
  },
  focusPanel() {
    const focusables = this.focusableElements()
    const active = this.panel.querySelector(".ops-nav-item-active")
    const target = active || focusables[0] || this.panel
    target.focus({preventScroll: true})
  },
  trapFocus(e) {
    const focusables = this.focusableElements()
    if (!focusables.length) {
      e.preventDefault()
      this.panel.focus({preventScroll: true})
      return
    }

    const first = focusables[0]
    const last = focusables[focusables.length - 1]

    if (!this.panel.contains(document.activeElement)) {
      e.preventDefault()
      first.focus({preventScroll: true})
    } else if (e.shiftKey && document.activeElement === first) {
      e.preventDefault()
      last.focus({preventScroll: true})
    } else if (!e.shiftKey && document.activeElement === last) {
      e.preventDefault()
      first.focus({preventScroll: true})
    }
  },
  restoreFocus() {
    const target = this.previousFocus
    this.previousFocus = null
    if (target && target.isConnected && typeof target.focus === "function") {
      target.focus({preventScroll: true})
    }
  },
}

const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: {...colocatedHooks, CommandPalette, OpsNavDrawer},
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
window.addEventListener("phx:copy_to_clipboard", async ({detail}) => {
  const text = detail?.text

  if (!text || !navigator.clipboard?.writeText) return

  try {
    await navigator.clipboard.writeText(text)
  } catch (_error) {
    // Clipboard permissions vary by browser; the exact value remains visible in title text.
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
