// Shared hooks for standalone and mounted ScrypathOps LiveSockets.
let opsModalPendingTrigger = null
let activeOpsModal = null

// Keep rich refresh buttons intact while LiveView marks their click as loading.
// `phx-disable-with` rewrites textContent, which permanently drops nested icons.
const OpsRefreshButton = {
  mounted() {
    this.serverDisabled = this.el.disabled
    this.syncLoadingState = () => {
      const loading = this.el.classList.contains("phx-click-loading")
      this.el.disabled = this.serverDisabled || loading
      if (loading) this.el.setAttribute("aria-busy", "true")
      else this.el.removeAttribute("aria-busy")
    }
    this.loadingObserver = new MutationObserver(this.syncLoadingState)
    this.loadingObserver.observe(this.el, {attributes: true, attributeFilter: ["class"]})
    this.syncLoadingState()
  },
  updated() {
    this.serverDisabled = this.el.disabled
    this.syncLoadingState()
  },
  destroyed() {
    this.loadingObserver.disconnect()
  }
}

// Info flashes are brief confirmations; errors stay visible until dismissed.
const OpsToast = {
  mounted() { this.scheduleDismiss() },
  updated() { this.scheduleDismiss() },
  destroyed() { window.clearTimeout(this.dismissTimer) },
  scheduleDismiss() {
    window.clearTimeout(this.dismissTimer)
    if (!this.el.classList.contains("ops-flash--info")) return

    this.dismissTimer = window.setTimeout(() => {
      this.el.querySelector('button[aria-label="Close notification"]')?.click()
    }, 4000)
  }
}

document.addEventListener("click", e => {
  const trigger = e.target instanceof Element
    ? e.target.closest("[data-ops-modal-trigger]")
    : null
  if (trigger) opsModalPendingTrigger = trigger
}, true)

// Operator command palette (⌘K), cheat-sheet (?), and `r`-to-refresh. Pure
// client-side: items are live-navigation links, so no server event is needed.
const CommandPalette = {
  mounted() {
    this.cmdk = this.el.querySelector("#ops-cmdk")
    this.sheet = document.getElementById(this.el.dataset.cheatsheet)
    this.input = this.cmdk.querySelector("[data-cmdk-input]")
    this.list = this.cmdk.querySelector("#ops-cmdk-list")
    this.empty = this.cmdk.querySelector("[data-cmdk-empty]")
    this.items = Array.from(this.cmdk.querySelectorAll("[data-cmdk-item]"))
    this.visible = this.items.slice()
    this.activeIndex = -1
    this.previousFocus = null

    this.onKeydown = e => this.handleKeydown(e)
    this.onModalOverlayOpen = () => this.closeForModal()
    this.onCmdkKeydown = e => this.overlayKeydown(e, this.cmdk)
    this.onSheetKeydown = e => this.overlayKeydown(e, this.sheet)
    this.onCmdkPointerOver = e => {
      const item = e.target instanceof Element
        ? e.target.closest("[data-cmdk-item]")
        : null
      const index = this.visible.indexOf(item)
      if (index >= 0 && index !== this.activeIndex) this.setActive(index)
    }
    this.onCommandOpenClick = e => {
      const opener = e.target instanceof Element
        ? e.target.closest("[data-ops-command-open]")
        : null
      if (!opener) return

      e.preventDefault()
      this.open()
    }
    window.addEventListener("keydown", this.onKeydown)
    document.addEventListener("ops:modal-overlay-open", this.onModalOverlayOpen)
    document.addEventListener("click", this.onCommandOpenClick)
    this.cmdk.addEventListener("keydown", this.onCmdkKeydown)
    this.list.addEventListener("pointerover", this.onCmdkPointerOver)
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
    document.removeEventListener("ops:modal-overlay-open", this.onModalOverlayOpen)
    document.removeEventListener("click", this.onCommandOpenClick)
    this.cmdk.removeEventListener("keydown", this.onCmdkKeydown)
    this.list.removeEventListener("pointerover", this.onCmdkPointerOver)
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
  closeForModal() {
    this.cancelDismiss(this.cmdk)
    this.cancelDismiss(this.sheet)
    this.cmdk.setAttribute("hidden", "")
    this.sheet.setAttribute("hidden", "")
    this.setActive(-1)
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
    this.onModalOverlayOpen = () => this.closeForModal()
    this.onDesktopChange = () => {
      if (this.desktopQuery.matches) this.close({restoreFocus: false})
    }

    this.openers.forEach(el => el.addEventListener("click", () => this.open()))
    this.closers.forEach(el => el.addEventListener("click", () => this.close()))
    this.links.forEach(el => el.addEventListener("click", () => this.close({restoreFocus: false})))
    window.addEventListener("keydown", this.onKeydown)
    document.addEventListener("ops:modal-overlay-open", this.onModalOverlayOpen)
    this.desktopQuery.addEventListener("change", this.onDesktopChange)
  },
  destroyed() {
    window.removeEventListener("keydown", this.onKeydown)
    document.removeEventListener("ops:modal-overlay-open", this.onModalOverlayOpen)
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
  closeForModal() {
    if (this.closeTimer) {
      window.clearTimeout(this.closeTimer)
      this.closeTimer = null
    }
    if (this.drawer) this.drawer.setAttribute("hidden", "")
    document.body.classList.remove("ops-nav-drawer-open")
    this.openers.forEach(el => el.setAttribute("aria-expanded", "false"))
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

const OpsModal = {
  mounted() {
    const pending = opsModalPendingTrigger
    this.returnTarget = pending && pending.isConnected ? pending : document.activeElement
    opsModalPendingTrigger = null
    this.returnTargetName = this.returnTarget?.getAttribute("phx-value-name")
    this.inerted = []
    this.onKeydown = e => this.handleKeydown(e)
    this.onModalOverlayOpen = () => {
      if (activeOpsModal && activeOpsModal !== this) activeOpsModal.closeImmediately()
      activeOpsModal = this
    }

    document.addEventListener("ops:modal-overlay-open", this.onModalOverlayOpen)
    document.dispatchEvent(new CustomEvent("ops:modal-overlay-open"))
    document.addEventListener("keydown", this.onKeydown, true)
    this.inertBackground()
    this.queueInitialFocus()
  },
  updated() {
    if (!this.el.contains(document.activeElement)) this.queueInitialFocus()
  },
  destroyed() {
    window.cancelAnimationFrame(this.focusFrame)
    document.removeEventListener("keydown", this.onKeydown, true)
    document.removeEventListener("ops:modal-overlay-open", this.onModalOverlayOpen)
    this.restoreBackground()
    if (activeOpsModal === this) activeOpsModal = null

    // The destroyed hook runs during a LiveView patch. Wait until deleted rows
    // and replacement controls have settled before choosing the return target.
    window.requestAnimationFrame(() => {
      if (!activeOpsModal) this.restoreFocus()
    })
  },
  focusableElements() {
    const selector = [
      "a[href]:not([tabindex='-1'])",
      "button:not([disabled]):not([tabindex='-1'])",
      "input:not([disabled]):not([type='hidden']):not([tabindex='-1'])",
      "select:not([disabled]):not([tabindex='-1'])",
      "textarea:not([disabled]):not([tabindex='-1'])",
      "[tabindex]:not([tabindex='-1'])"
    ].join(",")

    return Array.from(this.el.querySelectorAll(selector)).filter(el => {
      return !el.closest("[hidden]") && el.getAttribute("aria-hidden") !== "true" &&
        !el.matches(":disabled") && el.getClientRects().length > 0
    })
  },
  queueInitialFocus() {
    window.cancelAnimationFrame(this.focusFrame)
    // LiveView restores its previous focus after patch hooks; focus the dialog
    // after that patch has settled rather than having it bounce to the body.
    this.focusFrame = window.requestAnimationFrame(() => {
      if (this.el.isConnected && activeOpsModal === this) this.focusInitial()
    })
  },
  focusInitial() {
    const selector = this.el.dataset.opsModalInitialFocus
    let target = null
    try {
      target = selector ? this.el.querySelector(selector) : null
    } catch (_error) {
      target = null
    }
    target = target && !target.matches(":disabled") ? target : null
    target = target || this.focusableElements()[0] || this.el.querySelector(".modal-box") || this.el
    target.focus({preventScroll: true})
  },
  handleKeydown(e) {
    if (activeOpsModal !== this) return

    if (e.key === "Escape") {
      e.preventDefault()
      e.stopImmediatePropagation()
      this.close()
      return
    }

    if (e.key === "Tab") {
      this.trapFocus(e)
    }

    // Prevent the browser's own search shortcut while this dialog owns focus.
    if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === "k") e.preventDefault()

    // Keep shell shortcuts and other overlay handlers from taking ownership.
    e.stopImmediatePropagation()
  },
  trapFocus(e) {
    const focusables = this.focusableElements()
    if (!focusables.length) {
      e.preventDefault()
      this.focusInitial()
      return
    }

    const first = focusables[0]
    const last = focusables[focusables.length - 1]
    if (!this.el.contains(document.activeElement)) {
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
  close() {
    const event = this.el.dataset.opsModalCancelEvent
    if (event) this.pushEvent(event, {})
  },
  restoreFocus() {
    // LiveView can reuse a connected button for the next record after deletion.
    const sameRecord = this.returnTarget?.getAttribute("phx-value-name") === this.returnTargetName
    const target = this.returnTarget && this.returnTarget.isConnected && sameRecord
      ? this.returnTarget
      : this.querySuccessor()
    if (target && typeof target.focus === "function") target.focus({preventScroll: true})
    this.returnTarget = null
  },
  inertBackground() {
    let branch = this.el
    while (branch.parentElement) {
      const parent = branch.parentElement
      for (const sibling of parent.children) {
        if (sibling === branch) continue
        this.inerted.push({element: sibling, inert: sibling.inert})
        sibling.inert = true
      }
      if (parent === document.body) break
      branch = parent
    }
  },
  restoreBackground() {
    this.inerted.forEach(({element, inert}) => {
      if (element.isConnected) element.inert = inert
    })
    this.inerted = []
  },
  querySuccessor() {
    const selector = this.el.dataset.opsModalSuccessor
    if (!selector) return null
    try {
      return document.querySelector(selector)
    } catch (_error) {
      return null
    }
  },
  closeImmediately() {
    this.el.setAttribute("hidden", "")
    document.removeEventListener("keydown", this.onKeydown, true)
    this.restoreBackground()
  }
}

export {CommandPalette, OpsNavDrawer, OpsModal, OpsRefreshButton, OpsToast}
