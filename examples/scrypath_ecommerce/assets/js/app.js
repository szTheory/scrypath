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
  OpsTimestampCopy,
  OpsToast
} from "../../../../scrypath_ops/assets/js/ops_hooks";

const liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: { CommandPalette, OpsNavDrawer, OpsModal, OpsRefreshButton, OpsTimestampCopy, OpsToast }
});

const normalizeTheme = (theme) => {
  return theme === "light" || theme === "dark" ? theme : "system";
};

const readThemePreference = () => {
  try {
    return normalizeTheme(localStorage.getItem("phx:theme"));
  } catch (_error) {
    return "system";
  }
};

let currentThemePreference = readThemePreference();

const preferenceTheme = () => currentThemePreference;

const effectiveTheme = () => {
  const preference = preferenceTheme();
  if (preference === "dark" || preference === "light") return preference;
  return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
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

const setTheme = (theme, persist = true) => {
  currentThemePreference = normalizeTheme(theme);

  if (persist) {
    try {
      if (currentThemePreference === "system") {
        localStorage.removeItem("phx:theme");
      } else {
        localStorage.setItem("phx:theme", currentThemePreference);
      }
    } catch (_error) {
      // The in-memory preference remains usable for this page when persistence is denied.
    }
  }

  if (currentThemePreference === "system") {
    document.documentElement.removeAttribute("data-theme");
  } else {
    document.documentElement.setAttribute("data-theme", currentThemePreference);
  }
  syncThemeMeta();
};

setTheme(currentThemePreference, false);

window.addEventListener("storage", (event) => {
  if (event.key === "phx:theme" || event.key === null) {
    setTheme(event.key === "phx:theme" ? event.newValue : "system", false);
  }
});

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
