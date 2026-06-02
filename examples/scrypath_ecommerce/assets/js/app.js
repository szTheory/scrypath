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

    this.onKeydown = (e) => this.handleKeydown(e);
    window.addEventListener("keydown", this.onKeydown);

    this.cmdk.querySelectorAll("[data-cmdk-close]").forEach((el) =>
      el.addEventListener("click", () => this.close()));
    this.sheet.querySelectorAll("[data-cmdk-close]").forEach((el) =>
      el.addEventListener("click", () => this.closeSheet()));
    this.input.addEventListener("input", () => this.filter());
    this.input.addEventListener("keydown", (e) => this.inputKeydown(e));
  },
  destroyed() {
    window.removeEventListener("keydown", this.onKeydown);
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
    this.closeSheet();
    this.cmdk.removeAttribute("hidden");
    this.input.value = "";
    this.filter();
    this.input.focus();
  },
  close() {
    this.cmdk.setAttribute("hidden", "");
    this.setActive(-1);
  },
  openSheet() { this.sheet.removeAttribute("hidden"); },
  closeSheet() { this.sheet.setAttribute("hidden", ""); },
  refresh() {
    const btn = document.querySelector("[data-ops-refresh]");
    if (btn) btn.click();
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
    this.items.forEach((i) => i.classList.remove("is-active"));
    this.activeIndex = idx;
    const item = idx >= 0 && this.visible[idx];
    if (item) {
      item.classList.add("is-active");
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
      if (item) { this.close(); item.click(); }
    }
  },
};

const liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: { CommandPalette }
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

const syncThemeMeta = () => {
  document.documentElement.setAttribute("data-theme-effective", effectiveTheme());
  document.documentElement.setAttribute("data-theme-preference", preferenceTheme());
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
window.addEventListener("phx:set-theme", (event) => setTheme(event.target.dataset.phxTheme));
window
  .matchMedia("(prefers-color-scheme: dark)")
  .addEventListener("change", () => syncThemeMeta());

window.addEventListener("phx:copy_run_diagnostics", async ({ detail }) => {
  const text = detail?.text;
  if (!text || !navigator.clipboard?.writeText) return;

  try {
    await navigator.clipboard.writeText(text);
  } catch (_error) {
    // Server-side flash still confirms the action if clipboard permissions are unavailable.
  }
});

liveSocket.connect();
window.liveSocket = liveSocket;
