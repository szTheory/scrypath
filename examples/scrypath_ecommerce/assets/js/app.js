import "phoenix_html";
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";

const csrfToken = document
  .querySelector("meta[name='csrf-token']")
  ?.getAttribute("content");

// Use the same operator hooks as the standalone app.
import {
  CommandPalette,
  OpsNavDrawer,
  OpsModal,
  OpsRefreshButton,
  OpsToast
} from "../../../../scrypath_ops/assets/js/ops_hooks";

const liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: { CommandPalette, OpsNavDrawer, OpsModal, OpsRefreshButton, OpsToast }
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
