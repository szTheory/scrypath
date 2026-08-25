import "phoenix_html";
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";

const csrfToken = document
  .querySelector("meta[name='csrf-token']")
  ?.getAttribute("content");

// ScrypathOps command palette (⌘K) / cheat-sheet (?) / r-to-refresh. Mirrored from
// scrypath_ops/assets/js/app.js — the embedded /admin/search demo runs on this host
// app's LiveSocket, so the host must register the ops hooks (same as the theme +
// copy_run_diagnostics handlers above).
const CommandPalette = {
  mounted() {
    this.cmdk = this.el.querySelector("#ops-cmdk");
    this.sheet = document.getElementById(this.el.dataset.cheatsheet);
    this.input = this.cmdk.querySelector("[data-cmdk-input]");
    this.empty = this.cmdk.querySelector("[data-cmdk-empty]");
    this.items = Array.from(this.cmdk.querySelectorAll("[data-cmdk-item]"));
    this.visible = this.items.slice();
    this.activeIndex = -1;
    this.previousFocus = null;

    this.onKeydown = (e) => this.handleKeydown(e);
    this.onCmdkKeydown = (e) => this.overlayKeydown(e, this.cmdk);
    this.onSheetKeydown = (e) => this.overlayKeydown(e, this.sheet);
    window.addEventListener("keydown", this.onKeydown);
    this.cmdk.addEventListener("keydown", this.onCmdkKeydown);
    this.sheet.addEventListener("keydown", this.onSheetKeydown);

    this.cmdk.querySelectorAll("[data-cmdk-close]").forEach((el) =>
      el.addEventListener("click", () => this.close()));
    this.sheet.querySelectorAll("[data-cmdk-close]").forEach((el) =>
      el.addEventListener("click", () => this.closeSheet()));
    this.input.addEventListener("input", () => this.filter());
    this.input.addEventListener("keydown", (e) => this.inputKeydown(e));
  },
  destroyed() {
    window.removeEventListener("keydown", this.onKeydown);
    this.cmdk.removeEventListener("keydown", this.onCmdkKeydown);
    this.sheet.removeEventListener("keydown", this.onSheetKeydown);
  },
  isTyping() {
    const a = document.activeElement;
    return !!a && (a.tagName === "INPUT" || a.tagName === "TEXTAREA" ||
      a.tagName === "SELECT" || a.isContentEditable);
  },
  isOpen() { return !this.cmdk.hasAttribute("hidden"); },
  sheetOpen() { return !this.sheet.hasAttribute("hidden"); },
  handleKeydown(e) {
    if ((e.metaKey || e.ctrlKey) && (e.key === "k" || e.key === "K")) {
      e.preventDefault();
      this.isOpen() ? this.close() : this.open();
      return;
    }
    if (this.isOpen()) {
      if (e.key === "Escape") { e.preventDefault(); this.close(); }
      return;
    }
    if (this.sheetOpen()) {
      if (e.key === "Escape") { e.preventDefault(); this.closeSheet(); }
      return;
    }
    if (this.isTyping() || e.metaKey || e.ctrlKey || e.altKey) return;
    if (e.key === "?" || (e.key === "/" && e.shiftKey)) { e.preventDefault(); this.openSheet(); }
    else if (e.key === "r") { this.refresh(); }
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
  dismiss(el) {
    if (el.hasAttribute("hidden")) return;
    if (el._opsCloseTimer) return;
    el.classList.add("ops-cmdk--closing");
    el._opsCloseTimer = window.setTimeout(() => {
      el._opsCloseTimer = null;
      el.classList.remove("ops-cmdk--closing");
      el.setAttribute("hidden", "");
    }, 160);
  },
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
    this.previousFocus = active && active !== document.body && active !== document.documentElement
      ? active
      : null;
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

    return Array.from(root.querySelectorAll(selector)).filter((el) =>
      !el.closest("[hidden]") && el.getAttribute("aria-hidden") !== "true");
  },
  focusOverlay(root) {
    const focusables = this.focusableElements(root);
    const panel = root.querySelector(".ops-cmdk__panel");
    const target = root === this.cmdk ? this.input : (focusables[0] || panel || root);
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
      if (item) { this.close({ restoreFocus: false }); item.click(); }
    }
  },
};

const OpsNavDrawer = {
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
    this.onDesktopChange = () => {
      if (this.desktopQuery.matches) this.close({ restoreFocus: false });
    };

    this.openers.forEach((el) => el.addEventListener("click", () => this.open()));
    this.closers.forEach((el) => el.addEventListener("click", () => this.close()));
    this.links.forEach((el) => el.addEventListener("click", () => this.close({ restoreFocus: false })));
    window.addEventListener("keydown", this.onKeydown);
    this.desktopQuery.addEventListener("change", this.onDesktopChange);
  },
  destroyed() {
    window.removeEventListener("keydown", this.onKeydown);
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
    }, 180);
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

    return Array.from(this.panel.querySelectorAll(selector)).filter((el) =>
      !el.closest("[hidden]") && el.getAttribute("aria-hidden") !== "true");
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
  },
};

const liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: { CommandPalette, OpsNavDrawer }
});

const effectiveTheme = () => {
  const explicit = document.documentElement.getAttribute("data-theme");
  if (explicit === "dark") return "dark";
  if (explicit === "light") return "light";
  return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
};

const preferenceTheme = () => {
  const stored = localStorage.getItem("phx:theme");
  if (stored === "light" || stored === "dark") return stored;
  return "system";
};

const syncThemeButtons = () => {
  const preference = preferenceTheme();
  document.querySelectorAll("[data-phx-theme]").forEach((button) => {
    const selected = button.dataset.phxTheme === preference;
    button.setAttribute("aria-pressed", selected ? "true" : "false");
    button.setAttribute("data-theme-selected", selected ? "true" : "false");
  });
};

const syncThemeMeta = () => {
  document.documentElement.setAttribute("data-theme-effective", effectiveTheme());
  document.documentElement.setAttribute("data-theme-preference", preferenceTheme());
  syncThemeButtons();
};

const setTheme = (theme) => {
  if (theme === "system") {
    localStorage.removeItem("phx:theme");
    document.documentElement.removeAttribute("data-theme");
  } else {
    localStorage.setItem("phx:theme", theme);
    document.documentElement.setAttribute("data-theme", theme);
  }
  syncThemeMeta();
};

setTheme(localStorage.getItem("phx:theme") || "system");
window.addEventListener("phx:set-theme", (event) => {
  const button = event.target.closest("[data-phx-theme]");
  if (button) setTheme(button.dataset.phxTheme);
});
window
  .matchMedia("(prefers-color-scheme: dark)")
  .addEventListener("change", () => syncThemeMeta());

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", () => syncThemeMeta(), { once: true });
} else {
  syncThemeMeta();
}

window.addEventListener("phx:page-loading-stop", () => syncThemeMeta());

window.addEventListener("phx:copy_run_diagnostics", async ({ detail }) => {
  const text = detail?.text;
  if (!text || !navigator.clipboard?.writeText) return;

  try {
    await navigator.clipboard.writeText(text);
  } catch (_error) {
    // Server-side flash still confirms the action if clipboard permissions are unavailable.
  }
});

window.addEventListener("phx:copy_to_clipboard", async ({ detail }) => {
  const text = detail?.text;
  if (!text || !navigator.clipboard?.writeText) return;

  try {
    await navigator.clipboard.writeText(text);
  } catch (_error) {
    // Clipboard permissions vary by browser; the exact value remains visible in title text.
  }
});

liveSocket.connect();
window.liveSocket = liveSocket;
