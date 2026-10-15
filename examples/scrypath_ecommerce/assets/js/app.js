import "phoenix_html";
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";

const csrfToken = document
  .querySelector("meta[name='csrf-token']")
  ?.getAttribute("content");

import { OpsSearchDraft, OpsHelpAnchor, OpsFieldValidation } from "../../../../scrypath_ops/assets/js/ops_search";

// Use the same operator hooks as the standalone app.
import {
  CommandPalette,
  OpsNavDrawer,
  OpsModal,
  OpsRefreshButton,
  OpsToast,
  OpsTimestampCopy
} from "../../../../scrypath_ops/assets/js/ops_hooks";

const createMemoryStorage = () => {
  const entries = new Map();
  return {
    get length() { return entries.size; },
    clear() { entries.clear(); },
    getItem(key) { return entries.get(key) ?? null; },
    key(index) { return Array.from(entries.keys())[index] ?? null; },
    removeItem(key) { entries.delete(key); },
    setItem(key, value) { entries.set(String(key), String(value)); }
  };
};

const memoryStorage = createMemoryStorage();
const safeLocalStorage = {
  get length() {
    try {
      return window.localStorage.length;
    } catch (_error) {
      return memoryStorage.length;
    }
  },
  clear() {
    memoryStorage.clear();
    try {
      window.localStorage.clear();
    } catch (_error) {
      // Keep the in-memory fallback available when browser storage is denied.
    }
  },
  getItem(key) {
    try {
      const value = window.localStorage.getItem(key);
      if (value === null) memoryStorage.removeItem(key);
      else memoryStorage.setItem(key, value);
      return value;
    } catch (_error) {
      return memoryStorage.getItem(key);
    }
  },
  key(index) {
    try {
      return window.localStorage.key(index) ?? memoryStorage.key(index);
    } catch (_error) {
      return memoryStorage.key(index);
    }
  },
  removeItem(key) {
    memoryStorage.removeItem(key);
    try {
      window.localStorage.removeItem(key);
    } catch (_error) {
      // The current page still observes the in-memory removal.
    }
  },
  setItem(key, value) {
    memoryStorage.setItem(key, value);
    try {
      window.localStorage.setItem(key, value);
    } catch (_error) {
      // The current page still observes the in-memory value.
    }
  }
};

const liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  localStorage: safeLocalStorage,
  hooks: { CommandPalette, OpsNavDrawer, OpsModal, OpsRefreshButton, OpsToast, OpsTimestampCopy, OpsSearchDraft, OpsHelpAnchor, OpsFieldValidation }
});

const themeKey = "phx:theme";
const normalizeTheme = (theme) =>
  theme === "light" || theme === "dark" ? theme : "system";

const readStoredTheme = () => {
  return normalizeTheme(safeLocalStorage.getItem(themeKey));
};

let currentPreference = readStoredTheme();

const effectiveTheme = () => {
  if (currentPreference === "light" || currentPreference === "dark") {
    return currentPreference;
  }

  return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
};

const syncThemeButtons = () => {
  document.querySelectorAll("[data-phx-theme]").forEach((button) => {
    const selected = button.dataset.phxTheme === currentPreference;
    button.setAttribute("aria-pressed", selected ? "true" : "false");
    button.setAttribute("data-theme-selected", selected ? "true" : "false");
  });
};

const syncThemeMeta = () => {
  document.documentElement.setAttribute("data-theme-effective", effectiveTheme());
  document.documentElement.setAttribute("data-theme-preference", currentPreference);
  syncThemeButtons();
};

const setTheme = (theme, persist = true) => {
  currentPreference = normalizeTheme(theme);

  if (persist) {
    if (currentPreference === "system") safeLocalStorage.removeItem(themeKey);
    else safeLocalStorage.setItem(themeKey, currentPreference);
  }

  if (currentPreference === "system") {
    document.documentElement.removeAttribute("data-theme");
  } else {
    document.documentElement.setAttribute("data-theme", currentPreference);
  }

  syncThemeMeta();
};

setTheme(currentPreference, false);
window.addEventListener("storage", (event) => {
  if (event.key === null) {
    memoryStorage.clear();
    setTheme(event.newValue, false);
  } else if (event.key === themeKey) {
    if (event.newValue === null) memoryStorage.removeItem(themeKey);
    else memoryStorage.setItem(themeKey, event.newValue);
    setTheme(event.newValue, false);
  }
});
window.addEventListener("phx:set-theme", (event) => {
  const button = event.target.closest("[data-phx-theme]");
  if (button) setTheme(button.dataset.phxTheme);
});
window
  .matchMedia("(prefers-color-scheme: dark)")
  .addEventListener("change", () => syncThemeMeta());

window.addEventListener("phx:page-loading-stop", () => syncThemeMeta());

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", () => syncThemeMeta(), { once: true });
} else {
  syncThemeMeta();
}

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
