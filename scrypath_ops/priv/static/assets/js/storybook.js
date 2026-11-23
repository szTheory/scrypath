(() => {
  // js/ops_notifications.js
  var dismissTimer;
  var returnFocus;
  function notify(message, kind = "info", source = null) {
    const toast = document.querySelector("[data-ops-client-toast]");
    if (!toast) return;
    window.clearTimeout(dismissTimer);
    const text = toast.querySelector("[data-ops-notification-message]");
    const fallback = toast.querySelector("[data-ops-notification-source]");
    text.textContent = message;
    text.setAttribute("role", kind === "error" ? "alert" : "status");
    fallback.textContent = source ?? "";
    fallback.hidden = source == null;
    toast.classList.toggle("ops-flash--error", kind === "error");
    toast.classList.toggle("ops-flash--info", kind !== "error");
    returnFocus = document.activeElement;
    toast.hidden = false;
    if (kind !== "error") dismissTimer = window.setTimeout(() => {
      toast.hidden = true;
    }, 4e3);
  }
  document.addEventListener("click", (event) => {
    if (event.target instanceof Element && event.target.closest("[data-ops-notification-close]")) {
      window.clearTimeout(dismissTimer);
      document.querySelector("[data-ops-client-toast]")?.setAttribute("hidden", "");
      if (returnFocus instanceof HTMLElement && returnFocus.isConnected) returnFocus.focus();
    }
  });

  // js/ops_clipboard.js
  var attempts = /* @__PURE__ */ new WeakMap();
  document.addEventListener("click", async (event) => {
    const button = event.target instanceof Element ? event.target.closest("[data-ops-copy-text]") : null;
    if (!button) return;
    const group = button.closest("[data-ops-copy-group]");
    const feedback = group?.querySelector("[data-ops-copy-feedback]");
    const fallback = group?.querySelector("[data-ops-copy-fallback]");
    const attempt = (attempts.get(button) || 0) + 1;
    attempts.set(button, attempt);
    const source = button.dataset.opsCopyText;
    if (feedback) feedback.textContent = "";
    if (fallback) fallback.hidden = true;
    try {
      if (typeof navigator.clipboard?.writeText !== "function") throw new Error("Clipboard unavailable");
      await navigator.clipboard.writeText(source);
      if (!button.isConnected || attempts.get(button) !== attempt || source !== button.dataset.opsCopyText) return;
      notify(button.dataset.opsCopySuccess || "Diagnostics copied");
    } catch (_) {
      if (!button.isConnected || attempts.get(button) !== attempt || source !== button.dataset.opsCopyText) return;
      notify("Could not copy. Select and copy the value below.", "error", source);
    }
  });

  // js/ops_time.js
  var key = "scrypath:time-zone";
  var preference = "utc";
  try {
    preference = localStorage.getItem(key) === "local" ? "local" : "utc";
  } catch (_) {
  }
  function formatTimes(root = document) {
    const options = { year: "numeric", month: "short", day: "numeric", hour: "2-digit", minute: "2-digit", second: "2-digit", timeZoneName: "short", ...preference === "utc" ? { timeZone: "UTC" } : {} };
    const formatter = new Intl.DateTimeFormat(void 0, options);
    root.querySelectorAll("[data-ops-time-value]").forEach((time) => {
      const date = new Date(time.getAttribute("datetime"));
      if (Number.isNaN(date.getTime())) return;
      time.textContent = formatter.format(date);
    });
  }
  function syncTimePreference() {
    document.querySelectorAll("[data-ops-time-zone]").forEach((select) => {
      select.value = preference;
    });
    formatTimes();
  }
  document.addEventListener("change", (event) => {
    if (!event.target.matches("[data-ops-time-zone]")) return;
    preference = event.target.value === "local" ? "local" : "utc";
    try {
      localStorage.setItem(key, preference);
    } catch (_) {
    }
    syncTimePreference();
  });
  window.addEventListener("storage", (event) => {
    if (event.key !== key && event.key !== null) return;
    preference = event.newValue === "local" ? "local" : "utc";
    syncTimePreference();
  });

  // js/ops_hooks.js
  var opsModalPendingTrigger = null;
  var activeOpsModal = null;
  var OPS_INFO_DISMISS_MS = 4e3;
  var OPS_PALETTE_CLOSE_MS = 80;
  var scheduleInfoDismiss = (owner, dismiss) => {
    window.clearTimeout(owner.dismissTimer);
    owner.dismissTimer = window.setTimeout(dismiss, OPS_INFO_DISMISS_MS);
  };
  var OpsRefreshButton = {
    mounted() {
      this.readServerEligibility = () => {
        this.serverDisabled = this.el.dataset.opsRefreshEligible !== "true";
      };
      this.syncLoadingState = () => {
        const loading = this.el.classList.contains("phx-click-loading");
        this.el.disabled = this.serverDisabled || loading;
        if (loading) this.el.setAttribute("aria-busy", "true");
        else this.el.removeAttribute("aria-busy");
      };
      this.readServerEligibility();
      this.loadingObserver = new MutationObserver(this.syncLoadingState);
      this.loadingObserver.observe(this.el, { attributes: true, attributeFilter: ["class"] });
      this.syncLoadingState();
    },
    updated() {
      this.readServerEligibility();
      this.syncLoadingState();
    },
    destroyed() {
      this.loadingObserver.disconnect();
    }
  };
  var OpsToast = {
    mounted() {
      this.scheduleDismiss();
    },
    updated() {
      this.scheduleDismiss();
    },
    destroyed() {
      window.clearTimeout(this.dismissTimer);
    },
    scheduleDismiss() {
      if (!this.el.classList.contains("ops-flash--info")) {
        window.clearTimeout(this.dismissTimer);
        return;
      }
      scheduleInfoDismiss(this, () => {
        this.el.querySelector('button[aria-label="Close notification"]')?.click();
      });
    }
  };
  var OpsTimestampCopy = {
    mounted() {
      this.latestAttempt = 0;
      formatTimes(this.el);
      this.sourceValue = this.el.querySelector("[data-ops-timestamp-copy]")?.dataset.opsTimestampCopy;
      this.onCopyClick = async (event) => {
        const trigger = event.target instanceof Element ? event.target.closest("[data-ops-timestamp-copy]") : null;
        if (!trigger || !this.el.contains(trigger)) return;
        event.preventDefault();
        const attempt = ++this.latestAttempt;
        try {
          const exact = trigger.dataset.opsTimestampCopy;
          const clipboard = navigator.clipboard;
          if (!exact || typeof clipboard?.writeText !== "function") throw new Error("Clipboard unavailable");
          await clipboard.writeText(exact);
          if (attempt !== this.latestAttempt || !trigger.isConnected) return;
          notify("Timestamp copied");
        } catch (_error) {
          if (attempt !== this.latestAttempt || !trigger.isConnected) return;
          notify("Could not copy timestamp. Select and copy the exact value below.", "error", trigger.dataset.opsTimestampCopy);
        }
      };
      this.el.addEventListener("click", this.onCopyClick);
    },
    updated() {
      const current = this.el.querySelector("[data-ops-timestamp-copy]")?.dataset.opsTimestampCopy;
      if (current !== this.sourceValue) {
        this.latestAttempt += 1;
        this.sourceValue = current;
      }
      formatTimes(this.el);
    },
    destroyed() {
      this.latestAttempt += 1;
      this.el.removeEventListener("click", this.onCopyClick);
    }
  };
  document.addEventListener("click", (e) => {
    const trigger = e.target instanceof Element ? e.target.closest("[data-ops-modal-trigger]") : null;
    if (trigger) opsModalPendingTrigger = trigger;
  }, true);
  var CommandPalette = {
    mounted() {
      this.cmdk = this.el.querySelector("#ops-cmdk");
      this.sheet = document.getElementById(this.el.dataset.cheatsheet);
      this.input = this.cmdk.querySelector("[data-cmdk-input]");
      this.list = this.cmdk.querySelector("#ops-cmdk-list");
      this.empty = this.cmdk.querySelector("[data-cmdk-empty]");
      this.items = Array.from(this.cmdk.querySelectorAll("[data-cmdk-item]"));
      this.visible = this.items.slice();
      this.activeIndex = -1;
      this.previousFocus = null;
      this.onKeydown = (e) => this.handleKeydown(e);
      this.onModalOverlayOpen = () => this.closeForModal();
      this.onCmdkKeydown = (e) => this.overlayKeydown(e, this.cmdk);
      this.onSheetKeydown = (e) => this.overlayKeydown(e, this.sheet);
      this.onCmdkPointerMove = (e) => {
        const item = e.target instanceof Element ? e.target.closest("[data-cmdk-item]") : null;
        const index = this.visible.indexOf(item);
        if (index >= 0 && index !== this.activeIndex) this.setActive(index);
      };
      this.onCommandOpenClick = (e) => {
        const opener = e.target instanceof Element ? e.target.closest("[data-ops-command-open]") : null;
        if (!opener) return;
        e.preventDefault();
        this.open();
      };
      window.addEventListener("keydown", this.onKeydown);
      document.addEventListener("ops:modal-overlay-open", this.onModalOverlayOpen);
      document.addEventListener("click", this.onCommandOpenClick);
      this.cmdk.addEventListener("keydown", this.onCmdkKeydown);
      this.list.addEventListener("pointermove", this.onCmdkPointerMove);
      this.sheet.addEventListener("keydown", this.onSheetKeydown);
      this.cmdk.querySelectorAll("[data-cmdk-close]").forEach((el) => el.addEventListener("click", () => this.close()));
      this.sheet.querySelectorAll("[data-cmdk-close]").forEach((el) => el.addEventListener("click", () => this.closeSheet()));
      this.input.addEventListener("input", () => this.filter());
      this.input.addEventListener("keydown", (e) => this.inputKeydown(e));
    },
    destroyed() {
      window.removeEventListener("keydown", this.onKeydown);
      document.removeEventListener("ops:modal-overlay-open", this.onModalOverlayOpen);
      document.removeEventListener("click", this.onCommandOpenClick);
      this.cmdk.removeEventListener("keydown", this.onCmdkKeydown);
      this.list.removeEventListener("pointermove", this.onCmdkPointerMove);
      this.sheet.removeEventListener("keydown", this.onSheetKeydown);
    },
    isTyping() {
      const a = document.activeElement;
      return !!a && (a.tagName === "INPUT" || a.tagName === "TEXTAREA" || a.tagName === "SELECT" || a.isContentEditable);
    },
    isOpen() {
      return !this.cmdk.hasAttribute("hidden");
    },
    sheetOpen() {
      return !this.sheet.hasAttribute("hidden");
    },
    handleKeydown(e) {
      if ((e.metaKey || e.ctrlKey) && (e.key === "k" || e.key === "K")) {
        e.preventDefault();
        this.isOpen() ? this.close() : this.open();
        return;
      }
      if (this.isOpen()) {
        if (e.key === "Escape") {
          e.preventDefault();
          this.close();
        }
        return;
      }
      if (this.sheetOpen()) {
        if (e.key === "Escape") {
          e.preventDefault();
          this.closeSheet();
        }
        return;
      }
      if (this.isTyping() || e.metaKey || e.ctrlKey || e.altKey) return;
      if (e.key === "?" || e.key === "/" && e.shiftKey) {
        e.preventDefault();
        this.openSheet();
      } else if (e.key === "r") {
        this.refresh();
      }
    },
    open() {
      this.rememberFocus();
      this.closeSheet({ restoreFocus: false });
      this.cancelDismiss(this.cmdk);
      this.cmdk.removeAttribute("hidden");
      this.input.value = "";
      this.filter();
      this.input.focus();
    },
    close({ restoreFocus = true } = {}) {
      if (!this.isOpen()) return;
      this.dismiss(this.cmdk);
      this.setActive(-1);
      if (restoreFocus) this.restoreFocus();
    },
    openSheet() {
      this.rememberFocus();
      this.cancelDismiss(this.sheet);
      this.sheet.removeAttribute("hidden");
      this.focusOverlay(this.sheet);
    },
    closeSheet({ restoreFocus = true } = {}) {
      if (!this.sheetOpen()) return;
      this.dismiss(this.sheet);
      if (restoreFocus) this.restoreFocus();
    },
    closeForModal() {
      this.cancelDismiss(this.cmdk);
      this.cancelDismiss(this.sheet);
      this.cmdk.setAttribute("hidden", "");
      this.sheet.setAttribute("hidden", "");
      this.setActive(-1);
    },
    // A1 exit beat: play the crisp --ease-ops-exit dismissal (`.ops-cmdk--closing`, the 80ms
    // `instant` token) before hiding, so close feels as intentional as open. The timer waits
    // OPS_PALETTE_CLOSE_MS, the same 80ms, so the panel is hidden the moment its animation ends and
    // a fully faded panel never holds focus or catches a click. Behavior is unchanged — the panel
    // still ends up [hidden]; this only eases the transition. Re-opening cancels any pending
    // close so an interrupted dismissal snaps back open (interruptibility). Reduced-motion makes
    // the animation ~instant via the global rule, so the panel still hides on the next frame.
    dismiss(el) {
      if (el.hasAttribute("hidden")) return;
      if (el._opsCloseTimer) return;
      el.classList.add("ops-cmdk--closing");
      el._opsCloseTimer = window.setTimeout(() => {
        el._opsCloseTimer = null;
        el.classList.remove("ops-cmdk--closing");
        el.setAttribute("hidden", "");
      }, OPS_PALETTE_CLOSE_MS);
    },
    // Interrupt a pending dismissal (re-open mid-close): clear the timer + the closing class
    // so the panel stays open and re-enters cleanly instead of fading out under the user.
    cancelDismiss(el) {
      if (el._opsCloseTimer) {
        window.clearTimeout(el._opsCloseTimer);
        el._opsCloseTimer = null;
      }
      el.classList.remove("ops-cmdk--closing");
    },
    refresh() {
      const btn = document.querySelector("[data-ops-refresh]");
      if (btn) btn.click();
    },
    rememberFocus() {
      const active = document.activeElement;
      this.previousFocus = active && active !== document.body && active !== document.documentElement ? active : null;
    },
    restoreFocus() {
      const target = this.previousFocus;
      this.previousFocus = null;
      if (target && target.isConnected && typeof target.focus === "function") {
        target.focus({ preventScroll: true });
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
      ].join(",");
      return Array.from(root.querySelectorAll(selector)).filter((el) => !el.closest("[hidden]") && el.getAttribute("aria-hidden") !== "true");
    },
    focusOverlay(root) {
      const focusables = this.focusableElements(root);
      const panel = root.querySelector(".ops-cmdk__panel");
      const target = root === this.cmdk ? this.input : focusables[0] || panel || root;
      target.focus({ preventScroll: true });
    },
    overlayKeydown(e, root) {
      if (e.key !== "Tab") return;
      const focusables = this.focusableElements(root);
      if (!focusables.length) {
        e.preventDefault();
        this.focusOverlay(root);
        return;
      }
      const first = focusables[0];
      const last = focusables[focusables.length - 1];
      if (!root.contains(document.activeElement)) {
        e.preventDefault();
        first.focus({ preventScroll: true });
      } else if (e.shiftKey && document.activeElement === first) {
        e.preventDefault();
        last.focus({ preventScroll: true });
      } else if (!e.shiftKey && document.activeElement === last) {
        e.preventDefault();
        first.focus({ preventScroll: true });
      }
    },
    filter() {
      const q = this.input.value.trim().toLowerCase();
      this.visible = [];
      this.items.forEach((item) => {
        const match = q === "" || (item.dataset.cmdkLabel || "").includes(q);
        item.parentElement.hidden = !match;
        if (match) this.visible.push(item);
      });
      this.empty.hidden = this.visible.length > 0;
      this.setActive(this.visible.length ? 0 : -1);
    },
    setActive(idx) {
      this.items.forEach((i) => {
        i.classList.remove("is-active");
        i.setAttribute("aria-selected", "false");
      });
      this.input.removeAttribute("aria-activedescendant");
      this.activeIndex = idx;
      const item = idx >= 0 && this.visible[idx];
      if (item) {
        item.classList.add("is-active");
        item.setAttribute("aria-selected", "true");
        this.input.setAttribute("aria-activedescendant", item.id);
        item.scrollIntoView({ block: "nearest" });
      }
    },
    inputKeydown(e) {
      if (!this.visible.length) return;
      if (e.key === "ArrowDown") {
        e.preventDefault();
        this.setActive((this.activeIndex + 1) % this.visible.length);
      } else if (e.key === "ArrowUp") {
        e.preventDefault();
        this.setActive((this.activeIndex - 1 + this.visible.length) % this.visible.length);
      } else if (e.key === "Enter") {
        e.preventDefault();
        const item = this.visible[this.activeIndex] || this.visible[0];
        if (item) {
          this.close({ restoreFocus: false });
          item.click();
        }
      }
    }
  };
  var OpsNavDrawer = {
    mounted() {
      this.drawer = this.el.querySelector("[data-ops-nav-drawer]");
      this.panel = this.el.querySelector("[data-ops-nav-panel]");
      this.openers = Array.from(this.el.querySelectorAll("[data-ops-nav-open]"));
      this.closers = Array.from(this.el.querySelectorAll("[data-ops-nav-close]"));
      this.links = Array.from(this.el.querySelectorAll("[data-ops-nav-link]"));
      this.previousFocus = null;
      this.closeTimer = null;
      this.desktopQuery = window.matchMedia("(min-width: 1280px)");
      this.onKeydown = (e) => this.handleKeydown(e);
      this.onModalOverlayOpen = () => this.closeForModal();
      this.onDesktopChange = () => {
        if (this.desktopQuery.matches) this.close({ restoreFocus: false });
      };
      this.openers.forEach((el) => el.addEventListener("click", () => this.open()));
      this.closers.forEach((el) => el.addEventListener("click", () => this.close()));
      this.links.forEach((el) => el.addEventListener("click", () => this.close({ restoreFocus: false })));
      window.addEventListener("keydown", this.onKeydown);
      document.addEventListener("ops:modal-overlay-open", this.onModalOverlayOpen);
      this.desktopQuery.addEventListener("change", this.onDesktopChange);
    },
    destroyed() {
      window.removeEventListener("keydown", this.onKeydown);
      document.removeEventListener("ops:modal-overlay-open", this.onModalOverlayOpen);
      this.desktopQuery.removeEventListener("change", this.onDesktopChange);
      document.body.classList.remove("ops-nav-drawer-open");
    },
    isOpen() {
      return this.drawer && !this.drawer.hasAttribute("hidden");
    },
    open() {
      if (!this.drawer || this.isOpen()) return;
      this.previousFocus = document.activeElement;
      if (this.closeTimer) {
        window.clearTimeout(this.closeTimer);
        this.closeTimer = null;
      }
      this.drawer.removeAttribute("hidden");
      document.body.classList.add("ops-nav-drawer-open");
      this.openers.forEach((el) => el.setAttribute("aria-expanded", "true"));
      window.requestAnimationFrame(() => {
        this.drawer.classList.add("is-open");
        this.focusPanel();
      });
    },
    close({ restoreFocus = true } = {}) {
      if (!this.drawer || !this.isOpen()) return;
      this.drawer.classList.remove("is-open");
      document.body.classList.remove("ops-nav-drawer-open");
      this.openers.forEach((el) => el.setAttribute("aria-expanded", "false"));
      if (this.closeTimer) window.clearTimeout(this.closeTimer);
      this.closeTimer = window.setTimeout(() => {
        this.drawer.setAttribute("hidden", "");
        this.closeTimer = null;
        if (restoreFocus) this.restoreFocus();
      }, 240);
    },
    closeForModal() {
      if (this.closeTimer) {
        window.clearTimeout(this.closeTimer);
        this.closeTimer = null;
      }
      if (this.drawer) this.drawer.setAttribute("hidden", "");
      document.body.classList.remove("ops-nav-drawer-open");
      this.openers.forEach((el) => el.setAttribute("aria-expanded", "false"));
    },
    handleKeydown(e) {
      if (!this.isOpen()) return;
      if (e.key === "Escape") {
        e.preventDefault();
        this.close();
      } else if (e.key === "Tab") {
        this.trapFocus(e);
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
      ].join(",");
      return Array.from(this.panel.querySelectorAll(selector)).filter((el) => !el.closest("[hidden]") && el.getAttribute("aria-hidden") !== "true");
    },
    focusPanel() {
      const focusables = this.focusableElements();
      const active = this.panel.querySelector(".ops-nav-item-active");
      const target = active || focusables[0] || this.panel;
      target.focus({ preventScroll: true });
    },
    trapFocus(e) {
      const focusables = this.focusableElements();
      if (!focusables.length) {
        e.preventDefault();
        this.panel.focus({ preventScroll: true });
        return;
      }
      const first = focusables[0];
      const last = focusables[focusables.length - 1];
      if (!this.panel.contains(document.activeElement)) {
        e.preventDefault();
        first.focus({ preventScroll: true });
      } else if (e.shiftKey && document.activeElement === first) {
        e.preventDefault();
        last.focus({ preventScroll: true });
      } else if (!e.shiftKey && document.activeElement === last) {
        e.preventDefault();
        first.focus({ preventScroll: true });
      }
    },
    restoreFocus() {
      const target = this.previousFocus;
      this.previousFocus = null;
      if (target && target.isConnected && typeof target.focus === "function") {
        target.focus({ preventScroll: true });
      }
    }
  };
  var OpsModal = {
    mounted() {
      const pending = opsModalPendingTrigger;
      const disclosure = pending?.closest("details");
      if (disclosure) disclosure.open = false;
      const returnTargetSelector = pending?.dataset.opsModalReturn;
      this.returnTarget = this.queryTarget(returnTargetSelector) || (pending && pending.isConnected ? pending : document.activeElement);
      opsModalPendingTrigger = null;
      this.returnTargetName = pending?.getAttribute("phx-value-name") || this.targetRecordName(this.returnTarget);
      this.focusRequest = this.el.dataset.opsModalFocusRequest || "";
      this.inerted = [];
      this.onKeydown = (e) => this.handleKeydown(e);
      this.onModalOverlayOpen = () => {
        if (activeOpsModal && activeOpsModal !== this) activeOpsModal.closeImmediately();
        activeOpsModal = this;
      };
      document.addEventListener("ops:modal-overlay-open", this.onModalOverlayOpen);
      document.dispatchEvent(new CustomEvent("ops:modal-overlay-open"));
      document.addEventListener("keydown", this.onKeydown, true);
      this.inertBackground();
      this.queueInitialFocus();
    },
    updated() {
      const request = this.el.dataset.opsModalFocusRequest || "";
      if (request !== this.focusRequest) {
        this.focusRequest = request;
        window.cancelAnimationFrame(this.focusErrorFrame);
        this.focusErrorFrame = window.requestAnimationFrame(() => {
          if (this.el.isConnected && activeOpsModal === this && (this.el.dataset.opsModalFocusRequest || "") === request) {
            this.focusErrorField();
          }
        });
      }
    },
    destroyed() {
      window.cancelAnimationFrame(this.focusFrame);
      window.cancelAnimationFrame(this.focusErrorFrame);
      document.removeEventListener("keydown", this.onKeydown, true);
      document.removeEventListener("ops:modal-overlay-open", this.onModalOverlayOpen);
      this.restoreBackground();
      if (activeOpsModal === this) activeOpsModal = null;
      window.requestAnimationFrame(() => {
        if (!activeOpsModal) this.restoreFocus();
      });
    },
    focusableElements() {
      const selector = [
        "a[href]:not([tabindex='-1'])",
        "button:not([disabled]):not([tabindex='-1'])",
        "input:not([disabled]):not([type='hidden']):not([tabindex='-1'])",
        "select:not([disabled]):not([tabindex='-1'])",
        "textarea:not([disabled]):not([tabindex='-1'])",
        "details > summary:not([tabindex='-1'])",
        "[tabindex]:not([tabindex='-1'])"
      ].join(",");
      return Array.from(this.el.querySelectorAll(selector)).filter((el) => {
        const closed = el.closest("details:not([open])");
        if (closed && !(el.tagName === "SUMMARY" && el.parentElement === closed)) return false;
        return !el.closest("[hidden]") && el.getAttribute("aria-hidden") !== "true" && !el.matches(":disabled") && el.getClientRects().length > 0;
      });
    },
    queueInitialFocus() {
      window.cancelAnimationFrame(this.focusFrame);
      this.focusFrame = window.requestAnimationFrame(() => {
        if (this.el.isConnected && activeOpsModal === this) this.focusInitial();
      });
    },
    focusInitial() {
      const selector = this.el.dataset.opsModalInitialFocus;
      let target = null;
      try {
        target = selector ? this.el.querySelector(selector) : null;
      } catch (_error) {
        target = null;
      }
      target = this.isUsableFocusTarget(target) ? target : null;
      target = target || this.focusableElements()[0] || this.el.querySelector(".modal-box") || this.el;
      target.focus({ preventScroll: true });
    },
    focusErrorField() {
      const target = this.queryTarget(this.el.dataset.opsModalFocusError);
      if (this.el.contains(target) && this.isUsableFocusTarget(target)) {
        target.focus({ preventScroll: true });
      }
    },
    handleKeydown(e) {
      if (activeOpsModal !== this) return;
      if (e.key === "Escape") {
        e.preventDefault();
        e.stopImmediatePropagation();
        this.close();
        return;
      }
      if (e.key === "Tab") {
        this.trapFocus(e);
      }
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === "k") e.preventDefault();
      e.stopImmediatePropagation();
    },
    trapFocus(e) {
      this.queueFocusReturn(e.shiftKey);
      const focusables = this.focusableElements();
      if (!focusables.length) {
        e.preventDefault();
        this.focusInitial();
        return;
      }
      const first = focusables[0];
      const last = focusables[focusables.length - 1];
      if (!this.el.contains(document.activeElement)) {
        e.preventDefault();
        first.focus({ preventScroll: true });
      } else if (e.shiftKey && document.activeElement === first) {
        e.preventDefault();
        last.focus({ preventScroll: true });
      } else if (!e.shiftKey && document.activeElement === last) {
        e.preventDefault();
        first.focus({ preventScroll: true });
      }
    },
    // Safety net: if the browser's tab order still carries focus out of the dialog
    // (onto the inert page, i.e. <body>), wrap it back to the matching end.
    queueFocusReturn(backwards) {
      window.setTimeout(() => {
        if (activeOpsModal !== this || !this.el.isConnected) return;
        if (this.el.contains(document.activeElement)) return;
        const focusables = this.focusableElements();
        const target = backwards ? focusables[focusables.length - 1] : focusables[0];
        if (target) target.focus({ preventScroll: true });
        else this.focusInitial();
      }, 0);
    },
    close() {
      const event = this.el.dataset.opsModalCancelEvent;
      if (event) this.pushEvent(event, {});
    },
    restoreFocus() {
      const originalIsUsable = this.isUsableFocusTarget(this.returnTarget, this.returnTargetName);
      if (originalIsUsable) this.returnTarget.focus({ preventScroll: true });
      if (!originalIsUsable || document.activeElement !== this.returnTarget) {
        const successor = this.querySuccessor();
        if (successor && successor !== this.returnTarget && typeof successor.focus === "function") {
          successor.focus({ preventScroll: true });
        }
      }
      this.returnTarget = null;
      this.returnTargetName = null;
    },
    inertBackground() {
      let branch = this.el;
      while (branch.parentElement) {
        const parent = branch.parentElement;
        for (const sibling of parent.children) {
          if (sibling === branch) continue;
          this.inerted.push({ element: sibling, inert: sibling.inert });
          sibling.inert = true;
        }
        if (parent === document.body) break;
        branch = parent;
      }
      this.inertObserver = new MutationObserver(() => {
        this.inerted.forEach(({ element }) => {
          if (element.isConnected && !element.inert) element.inert = true;
        });
      });
      this.inerted.forEach(({ element }) => {
        this.inertObserver.observe(element, { attributes: true, attributeFilter: ["inert"] });
      });
    },
    restoreBackground() {
      this.inertObserver?.disconnect();
      this.inertObserver = null;
      this.inerted.forEach(({ element, inert }) => {
        if (element.isConnected) element.inert = inert;
      });
      this.inerted = [];
    },
    querySuccessor() {
      const primarySelector = this.el.dataset.opsModalSuccessor;
      const fallbackSelector = this.el.dataset.opsModalFallbackSuccessor;
      const primaryName = this.el.dataset.opsModalSuccessorName || null;
      for (const [selector, expectedName] of [
        [primarySelector, primaryName],
        [fallbackSelector, null]
      ]) {
        const target = this.queryTarget(selector);
        if (this.isUsableFocusTarget(target, expectedName)) return target;
      }
      return null;
    },
    queryTarget(selector) {
      if (!selector) return null;
      try {
        return document.querySelector(selector);
      } catch (_error) {
        return null;
      }
    },
    targetRecordName(target) {
      if (!target) return null;
      return target.getAttribute("phx-value-name") || target.dataset.opsFileName || target.closest("details[data-ops-file-name]")?.dataset.opsFileName || null;
    },
    isUsableFocusTarget(target, expectedName = null) {
      if (!target || !target.isConnected || typeof target.focus !== "function") return false;
      if (target.matches(":disabled,[hidden]") || target.closest("[hidden], [inert], [aria-hidden='true']")) return false;
      const closedDisclosure = target.closest("details:not([open])");
      if (closedDisclosure && !(target.tagName === "SUMMARY" && target.parentElement === closedDisclosure)) {
        return false;
      }
      if (expectedName && this.targetRecordName(target) !== expectedName) return false;
      return target.getClientRects().length > 0;
    },
    closeImmediately() {
      this.el.setAttribute("hidden", "");
      document.removeEventListener("keydown", this.onKeydown, true);
      this.restoreBackground();
    }
  };
  window.addEventListener("phx:page-loading-stop", () => syncTimePreference());
  syncTimePreference();

  // js/ops_validation.js
  var touched = /* @__PURE__ */ new WeakSet();
  var pendingFocus = null;
  var pointerButton = null;
  function focusInvalid(field) {
    pendingFocus = field;
    requestAnimationFrame(() => {
      if (pendingFocus === field && field.isConnected) field.focus();
    });
  }
  document.addEventListener("pointerdown", (event) => {
    pendingFocus = null;
    pointerButton = event.target instanceof Element ? event.target.closest("button") : null;
  }, true);
  document.addEventListener("pointerup", () => {
    pointerButton = null;
  }, true);
  document.addEventListener("keydown", () => {
    pendingFocus = null;
  }, true);
  var maxNameLength = 120;
  var invalidName = (value) => [...value.trim()].length > maxNameLength || /\p{Cc}/u.test(value);
  function errorFor(field) {
    const value = field.value;
    const label = field.labels?.[0]?.textContent.trim() || "this field";
    if (field.validity.badInput) return "Enter a whole number.";
    if (field.required && !value.trim()) return `Enter ${label.toLowerCase()}.`;
    if (field.type === "number" && value === "" && !field.required) return "";
    if (field.type === "number" && (value === "" || !Number.isInteger(Number(value)) || Number(value) < Number(field.min) || field.max && Number(value) > Number(field.max))) return `Enter a whole number from ${field.min} to ${field.max}.`;
    if (/basename|new-name|to-name/.test(field.id) && value && invalidName(value)) return `Enter a name of up to ${maxNameLength} characters.`;
    if (field.dataset.opsMaxBytes && new TextEncoder().encode(value).length > Number(field.dataset.opsMaxBytes)) return `Shorten ${label.toLowerCase()} to ${field.dataset.opsMaxBytes} bytes or fewer. Non-English characters may use several bytes.`;
    if (field.dataset.opsJson !== void 0 && value.trim()) {
      try {
        const data = JSON.parse(value);
        if (!data || Array.isArray(data) || typeof data !== "object") return "Paste a JSON object for a saved search.";
      } catch (_) {
        return "Check the JSON syntax: use double quotes and match brackets and braces.";
      }
    }
    if (field.validity.patternMismatch) return "Match the requested format.";
    return "";
  }
  function validate(field, edited = false) {
    if (!field.matches?.("[data-ops-validate]") || field.disabled) return true;
    const error = errorFor(field);
    const message = document.getElementById(`${field.id}-error`);
    if (message?.dataset.serverError && !edited && !error) return true;
    if (message) {
      message.textContent = error;
      message.hidden = !error;
      message.removeAttribute("data-server-error");
    }
    if (message) {
      if (error) message.setAttribute("role", "alert");
      else message.removeAttribute("role");
    }
    field.setAttribute("aria-invalid", error ? "true" : "false");
    const ids = new Set((field.getAttribute("aria-describedby") || "").split(/\s+/).filter(Boolean));
    if (error) ids.add(`${field.id}-error`);
    else ids.delete(`${field.id}-error`);
    field.setAttribute("aria-describedby", [...ids].join(" "));
    return !error;
  }
  document.addEventListener("focusout", (event) => {
    const field = event.target;
    if (!field.matches?.("[data-ops-validate]")) return;
    touched.add(field);
    if (pointerButton && event.relatedTarget === pointerButton) return;
    validate(field);
  });
  document.addEventListener("input", (event) => {
    pendingFocus = null;
    if (touched.has(event.target)) validate(event.target, true);
  });
  document.addEventListener("invalid", (event) => {
    if (!event.target.matches?.("[data-ops-validate]")) return;
    event.preventDefault();
    touched.add(event.target);
    validate(event.target);
    const invalid = [...event.target.form.querySelectorAll("[data-ops-validate]")].find((field) => !field.validity.valid);
    if (invalid) focusInvalid(invalid);
  }, true);
  document.addEventListener("submit", (event) => {
    const fields = [...event.target.querySelectorAll("[data-ops-validate]")];
    const invalid = fields.filter((field) => {
      touched.add(field);
      return !validate(field);
    });
    if (invalid.length) {
      event.preventDefault();
      event.stopImmediatePropagation();
      focusInvalid(invalid[0]);
    }
  }, true);
  var OpsFieldValidation = {
    updated() {
      const field = this.el.querySelector("[data-ops-validate]");
      if (field && touched.has(field) && !this.el.querySelector("[data-server-error]")?.dataset.serverError) validate(field);
      if (field && pendingFocus === field) focusInvalid(field);
    }
  };

  // js/ops_search.js
  var OpsSearchDraft = {
    mounted() {
      this.syncDraft = () => {
        const context = document.getElementById("search-run-attribution");
        if (!context) return;
        const data = new FormData(this.el);
        const mode = this.el.dataset.searchMode;
        const schemas = mode === "multi" ? data.getAll("schemas[]").map(String).sort() : [String(data.get("schema") || "")];
        const submitted = JSON.parse(context.dataset.schemas);
        const changed = mode !== context.dataset.mode || String(data.get("q") || "").trim() !== context.dataset.query || Number(data.get("page_size")) !== Number(context.dataset.limit) || JSON.stringify(schemas) !== JSON.stringify(submitted.sort());
        context.hidden = !changed;
      };
      this.el.addEventListener("input", this.syncDraft);
      this.el.addEventListener("change", this.syncDraft);
      this.syncDraft();
    },
    updated() {
      this.syncDraft();
    },
    destroyed() {
      this.el.removeEventListener("input", this.syncDraft);
      this.el.removeEventListener("change", this.syncDraft);
    }
  };
  var OpsHelpAnchor = {
    mounted() {
      this.reveal = () => {
        const id = decodeURIComponent(location.hash.slice(1));
        const target = id && document.getElementById(id);
        if (target && this.el.contains(target)) target.scrollIntoView({ block: "start" });
      };
      window.addEventListener("hashchange", this.reveal);
      requestAnimationFrame(this.reveal);
    },
    destroyed() {
      window.removeEventListener("hashchange", this.reveal);
    }
  };

  // js/storybook.js
  (function() {
    const theme = new URLSearchParams(window.location.search).get("theme");
    if (theme === "light" || theme === "dark") document.documentElement.setAttribute("data-theme", theme);
  })();
  (function() {
    const useProductFont = () => {
      document.body.style.fontFamily = "var(--font-sans)";
    };
    if (document.body) useProductFont();
    else document.addEventListener("DOMContentLoaded", useProductFont, { once: true });
  })();
  (function() {
    const style = document.createElement("style");
    style.id = "ops-catalog-shell";
    style.textContent = [
      "html:has(#psb-main) { background-color: var(--psb-color-sidebar); color-scheme: normal; }",
      "@media (min-width: 1024px) {",
      "  #psb-main { margin: 0; border-width: 0 0 0 1px; border-radius: 0; box-shadow: none; }",
      "}"
    ].join("\n");
    document.head.appendChild(style);
  })();
  window.storybook = {
    Hooks: { CommandPalette, OpsNavDrawer, OpsModal, OpsRefreshButton, OpsToast, OpsTimestampCopy, OpsSearchDraft, OpsHelpAnchor, OpsFieldValidation }
  };
})();
