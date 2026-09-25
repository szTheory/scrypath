# Phase 135: Shell Chrome Polish (Dual-Theme) - Pattern Map

**Mapped:** 2026-06-26
**Files analyzed:** 13 target/conditional files
**Analogs found:** 13 / 13

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `scrypath_ops/lib/scrypath_ops_web/components/layouts.ex` | component | request-response + event-driven | `scrypath_ops/lib/scrypath_ops_web/components/layouts.ex` | exact |
| `scrypath_ops/lib/scrypath_ops_web/components/layouts/root.html.heex` | provider | event-driven | `scrypath_ops/lib/scrypath_ops_web/components/layouts/root.html.heex` | exact |
| `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` | component | request-response + event-driven | `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` | exact |
| `scrypath_ops/lib/scrypath_ops_web/components/core_components.ex` | component | event-driven | `scrypath_ops/lib/scrypath_ops_web/components/core_components.ex` | exact |
| `scrypath_ops/assets/js/app.js` | hook | event-driven | `scrypath_ops/assets/js/app.js` | exact |
| `scrypath_ops/assets/css/app.css` | config | transform | `scrypath_ops/assets/css/app.css` | exact |
| `scrypath_ops/assets/css/DESIGN-TOKENS.md` | config | transform | `scrypath_ops/assets/css/DESIGN-TOKENS.md` | exact |
| `scrypath_ops/assets/css/contrast-pairs.mjs` | config | transform | `scrypath_ops/assets/css/contrast-pairs.mjs` | exact, conditional |
| `examples/scrypath_ecommerce/e2e/admin_shell_chrome.spec.ts` | test | event-driven + request-response | `examples/scrypath_ecommerce/e2e/admin_surface_depth.spec.ts` | exact |
| `examples/scrypath_ecommerce/package.json` | config | batch | `examples/scrypath_ecommerce/package.json` | exact |
| `scrypath_ops/test/scrypath_ops_web/ops_shell_contract_test.exs` | test | request-response | `scrypath_ops/test/scrypath_ops_web/ops_shell_contract_test.exs` | exact, conditional |
| `scrypath_ops/test/scrypath_ops_web/shell_chrome_token_contract_test.exs` | test | transform | `scrypath_ops/test/scrypath_ops_web/surface_depth_token_contract_test.exs` | role-match, conditional new file |
| `lib/mix/tasks/verify.opsui.ex` | utility | batch | `lib/mix/tasks/verify.opsui.ex` | exact, conditional |

## Pattern Assignments

### `scrypath_ops/lib/scrypath_ops_web/components/layouts.ex` (component, request-response + event-driven)

**Analog:** `scrypath_ops/lib/scrypath_ops_web/components/layouts.ex`

**Imports/component authority pattern** (lines 1-12):
```elixir
defmodule ScrypathOpsWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use ScrypathOpsWeb, :html

  # Embed all files in layouts/* within this module.
  embed_templates("layouts/*")
```

**Ops shell ownership pattern** (lines 50-105):
```elixir
def app(%{shell: :ops} = assigns) do
  ~H"""
  <a href="#ops-main" class="sr-only focus:not-sr-only ...">
    Skip to operator content
  </a>

  <header class="ops-header px-4 py-3 sm:px-6 lg:px-8">
    ...
    <nav aria-label="Operator primary" class="hidden sm:block">
      <ul class="ops-nav-list">
        <li :for={item <- ScrypathOpsWeb.Nav.primary(@mount_path)}>
          <.link
            navigate={item.path}
            class={nav_link_classes(item, @page_title)}
            aria-current={if item.title == @page_title, do: "page", else: nil}
          >
            {item.label}
          </.link>
        </li>
      </ul>
    </nav>
    <.theme_toggle />
  </header>

  <main id="ops-main" aria-labelledby="ops-page-title" class="ops-shell ...">
    <div class={main_width_classes(@ops_main_width)}>
      {render_slot(@inner_block)}
    </div>
  </main>

  <.flash_group flash={@flash} id="flash-group" />
  <.ops_command_palette mount_path={@mount_path} />
  """
end
```

**Inline brand mark pattern** (lines 148-178):
```elixir
# Brand mark: the scrypath `s/p` monogram. Inlined (not <img>) so the letters ride
# `currentColor` and adapt to light/dark, with the copper "/" as the fixed brand accent.
attr(:class, :string, default: nil)

defp brand_mark(assigns) do
  ~H"""
  <svg
    class={@class}
    width="36"
    height="36"
    viewBox="-21 868 205 205"
    fill="none"
    aria-hidden="true"
    focusable="false"
    xmlns="http://www.w3.org/2000/svg"
  >
```

**Nav active-state pattern** (lines 183-191):
```elixir
defp nav_link_classes(item, page_title) do
  [
    "ops-nav-item",
    item.title == page_title && "ops-nav-item-active"
  ]
end
```

**Theme toggle pattern** (lines 241-283):
```elixir
def theme_toggle(assigns) do
  ~H"""
  <div
    id="theme-toggle"
    class="card relative flex flex-row items-center border border-base-300 bg-base-300 rounded-full"
    role="group"
    aria-label="Theme preference"
  >
    <div id="theme-toggle-pill" class="absolute top-0 left-0 h-full w-1/3 ..." />

    <button type="button" phx-click={JS.dispatch("phx:set-theme")} data-phx-theme="system">
      <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
    </button>
    ...
  </div>
  """
end
```

**Planner notes:**
- Add durable `.ops-*` chrome classes here only around existing elements; keep IDs such as `theme-toggle`, `theme-toggle-pill`, `flash-group`, `ops-main`, and JS/test selectors stable.
- Do not move `<.flash_group>` outside `layouts.ex`; nested `scrypath_ops/AGENTS.md` forbids using it elsewhere.
- If brand proof changes, target the live inline SVG or add a small stable class to this `brand_mark/1`; do not rely only on stale `.ops-route-mark`.

---

### `scrypath_ops/lib/scrypath_ops_web/components/layouts/root.html.heex` (provider, event-driven)

**Analog:** `scrypath_ops/lib/scrypath_ops_web/components/layouts/root.html.heex`

**Root asset and theme-provider pattern** (lines 11-14):
```heex
<link phx-track-static rel="stylesheet" href={"#{@mount_path}/assets/css/app.css"} />
<script defer phx-track-static type="text/javascript" src={"#{@mount_path}/assets/js/app.js"}>
</script>
<script>
```

**Theme state source of truth** (lines 15-63):
```javascript
(() => {
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

  window.addEventListener("phx:set-theme", (e) => setTheme(e.target.dataset.phxTheme));
})();
```

**Planner notes:**
- Preserve `localStorage["phx:theme"]`, `data-theme`, `data-theme-effective`, and `data-theme-preference`.
- Do not add unrelated inline script behavior. If semantic hardening needs dynamic button attributes, keep it scoped to this existing theme preference mechanism or move browser-only behavior to `assets/js/app.js`.

---

### `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` (component, request-response + event-driven)

**Analog:** `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex`

**Component contract pattern** (lines 1069-1079):
```elixir
@doc """
Operator command palette (⌘K / Ctrl-K) + keyboard cheat-sheet (`?`).

Pure client-side: every item is a live-navigation link, so the palette needs no
server event. The `CommandPalette` JS hook owns open/close, fuzzy filter, arrow
navigation, `?` for the cheat-sheet, and `r` to click the page's `[data-ops-refresh]`
control. Rendered once in the `:ops` shell so it is available on every surface.
"""
attr(:mount_path, :string, required: true)
```

**Palette data source pattern** (lines 1080-1087):
```elixir
assigns =
  assign(assigns, :items, [
    %{path: assigns.mount_path, label: "Control Room", hint: "Home · trust verdict"}
    | Enum.map(
        ScrypathOpsWeb.Nav.primary(assigns.mount_path),
        &%{path: &1.path, label: &1.label, hint: &1.title}
      )
  ])
```

**Palette DOM and selector pattern** (lines 1090-1125):
```heex
<div id="ops-command-palette" phx-hook="CommandPalette" data-cheatsheet="ops-cheatsheet">
  <div
    id="ops-cmdk"
    class="ops-cmdk"
    role="dialog"
    aria-modal="true"
    aria-label="Command palette"
    hidden
  >
    <div class="ops-cmdk__backdrop" data-cmdk-close aria-hidden="true"></div>
    <div class="ops-cmdk__panel">
      <input class="ops-cmdk__input" data-cmdk-input ... />
      <ul class="ops-cmdk__list" role="listbox" aria-label="Surfaces">
        <li :for={item <- @items}>
          <.link
            navigate={item.path}
            class="ops-cmdk__item"
            role="option"
            data-cmdk-item
            data-cmdk-label={String.downcase("#{item.label} #{item.hint}")}
          >
```

**Shortcut sheet pattern** (lines 1128-1160):
```heex
<div
  id="ops-cheatsheet"
  class="ops-cmdk"
  role="dialog"
  aria-modal="true"
  aria-label="Keyboard shortcuts"
  hidden
>
  <div class="ops-cmdk__backdrop" data-cmdk-close aria-hidden="true"></div>
  <div class="ops-cmdk__panel ops-cmdk__panel--sheet">
    <h2 class="text-ops-h3 font-semibold leading-ops-tight text-base-content">
      Keyboard shortcuts
    </h2>
    <dl class="ops-cheatsheet__list">
```

**Planner notes:**
- Preserve `id="ops-command-palette"`, `phx-hook="CommandPalette"`, `id="ops-cmdk"`, `id="ops-cheatsheet"`, `data-cmdk-*`, and `data-cheatsheet`.
- If `aria-modal="true"` remains, the browser spec must prove enough focus behavior and focus return; otherwise downgrade the semantic claim to match actual behavior.
- Do not introduce a LiveComponent or dependency for this bounded palette unless browser proof shows the current hook cannot satisfy the semantic contract.

---

### `scrypath_ops/lib/scrypath_ops_web/components/core_components.ex` (component, event-driven)

**Analog:** `scrypath_ops/lib/scrypath_ops_web/components/core_components.ex`

**Component scope pattern** (lines 1-22):
```elixir
defmodule ScrypathOpsWeb.CoreComponents do
  @moduledoc """
  Shared low-level chrome for the operator UI.

  > Operator UI is built exclusively from `ScrypathOpsWeb.OpsUI` (the `ops_*`
  > components) over the design-token system in `assets/css/app.css`.

  What lives here and why:
    * `flash/1` -- flash/toast notice (daisyUI `alert`), rendered by
      `ScrypathOpsWeb.Layouts.flash_group/1`.
    * `icon/1` -- Heroicon renderer via the Hex `heroicons` package.
    * `show/1,2` and `hide/1,2` -- `Phoenix.LiveView.JS` show/hide transitions.
  """
```

**Flash/toast pattern** (lines 44-73):
```elixir
def flash(assigns) do
  assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

  ~H"""
  <div
    :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
    id={@id}
    phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
    role="alert"
    class="z-50"
    {@rest}
  >
    <div class={[
      "alert w-full max-w-full text-wrap",
      @kind == :info && "alert-info",
      @kind == :error && "alert-error"
    ]}>
      <.icon :if={@kind == :info} name="hero-information-circle" class="size-5 shrink-0" />
      <.icon :if={@kind == :error} name="hero-exclamation-circle" class="size-5 shrink-0" />
      ...
      <button type="button" class="group self-start cursor-pointer" aria-label={gettext("close")}>
```

**Show/hide transition pattern** (lines 132-154):
```elixir
def show(js \\ %JS{}, selector) do
  JS.show(js,
    to: selector,
    time: 240,
    transition:
      {"transition-all ease-ops-out duration-200",
       "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
       "opacity-100 translate-y-0 sm:scale-100"}
  )
end

def hide(js \\ %JS{}, selector) do
  JS.hide(js,
    to: selector,
    time: 120,
    transition:
      {"transition-all ease-ops-exit duration-200", "opacity-100 translate-y-0 sm:scale-100",
       "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
  )
end
```

**Planner notes:**
- Add `ops-flash` / `ops-flash--info` / `ops-flash--error` classes here if needed, while preserving `role="alert"`, text/icon pairing, `Phoenix.Flash` lookup, and `phx-click` dismissal.
- Do not move generic operator controls into `CoreComponents`; durable ops UI belongs in `.ops-*` CSS and `OpsUI`.

---

### `scrypath_ops/assets/js/app.js` (hook, event-driven)

**Analog:** `scrypath_ops/assets/js/app.js`

**Hook registration pattern** (lines 20-32, 157-160):
```javascript
import "phoenix_html"
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import {hooks as colocatedHooks} from "phoenix-colocated/scrypath_ops"
import topbar from "../vendor/topbar"

const CommandPalette = {
  mounted() {
```

```javascript
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: {...colocatedHooks, CommandPalette},
})
```

**Palette keyboard pattern** (lines 42-79):
```javascript
this.onKeydown = e => this.handleKeydown(e)
window.addEventListener("keydown", this.onKeydown)

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
}
```

**Open/close and exit-beat pattern** (lines 80-116):
```javascript
open() {
  this.closeSheet()
  this.cancelDismiss(this.cmdk)
  this.cmdk.removeAttribute("hidden")
  this.input.value = ""
  this.filter()
  this.input.focus()
},
close() {
  this.dismiss(this.cmdk)
  this.setActive(-1)
},
dismiss(el) {
  if (el._opsCloseTimer) return
  el.classList.add("ops-cmdk--closing")
  el._opsCloseTimer = window.setTimeout(() => {
    el._opsCloseTimer = null
    el.classList.remove("ops-cmdk--closing")
    el.setAttribute("hidden", "")
  }, 160)
},
cancelDismiss(el) {
  if (el._opsCloseTimer) {
    window.clearTimeout(el._opsCloseTimer)
    el._opsCloseTimer = null
  }
  el.classList.remove("ops-cmdk--closing")
},
```

**Filter and active item pattern** (lines 121-153):
```javascript
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
```

**Planner notes:**
- Any focus-return or active-option ARIA hardening should extend this existing hook; do not add a second hook for the same palette.
- Preserve the close timer and `.ops-cmdk--closing` CSS handshake unless deliberately changing the motion contract and tests.

---

### `scrypath_ops/assets/css/app.css` (config, transform)

**Analog:** `scrypath_ops/assets/css/app.css`

**Tailwind/daisyUI import pattern** (lines 4-23):
```css
@import "tailwindcss" source(none);

@source "../css";
@source "../js";
@source "../../lib/scrypath_ops_web";

@plugin "../vendor/daisyui" {
  themes: false;
}

@plugin "../vendor/daisyui-theme" {
  name: "dark";
  default: false;
  prefersdark: true;
```

**System-dark warning pattern** (lines 108-119):
```css
/*
 * This `@custom-variant dark` matches only when `data-theme="dark"` is set on `<html>`
 * (explicit dark mode). When the operator chooses **system**, `data-theme` is absent and
 * daisyUI applies light/dark semantic tokens from the OS `prefers-color-scheme`.
 */
@custom-variant dark (&:where([data-theme=dark], [data-theme=dark] *));
```

**Header and shell wash pattern** (lines 238-250):
```css
@layer components {
  .ops-header {
    min-height: 4.25rem;
    border-bottom: 1px solid color-mix(in oklch, var(--color-base-content) 10%, transparent);
    background: color-mix(in oklch, var(--color-base-100) 96%, transparent);
    box-shadow: var(--shadow-ops-surface);
  }

  .ops-shell {
    background:
      radial-gradient(circle at top left, color-mix(in oklch, var(--color-primary) 14%, transparent), transparent 34rem),
      linear-gradient(180deg, var(--color-base-200), var(--color-base-100));
  }
```

**Nav active fill pattern** (lines 605-637):
```css
.ops-nav-list {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.25rem;
  border-radius: var(--radius-ops-lg);
  background: color-mix(in oklch, var(--ops-surface-2) 72%, transparent);
  padding: 0.25rem;
}

.ops-nav-item {
  display: inline-flex;
  min-height: var(--control-h-md);
  align-items: center;
  border-radius: var(--radius-ops-md);
  transition-property: background-color, color, box-shadow;
  transition-duration: var(--duration-ops-fast);
}

.ops-nav-item-active {
  background: var(--color-primary-strong);
  color: var(--color-primary-content);
  font-weight: 650;
  box-shadow: var(--shadow-ops-surface);
}
```

**Flash and command palette selector pattern** (lines 1047-1124):
```css
#flash-group {
  position: fixed;
  top: 5.75rem;
  right: 1rem;
  z-index: var(--z-index-ops-flash);
  display: grid;
  width: min(22rem, calc(100vw - 2rem));
  gap: 0.75rem;
  pointer-events: none;
}

#flash-group > * {
  pointer-events: auto;
  box-shadow: var(--shadow-ops-overlay);
}

.ops-cmdk {
  position: fixed;
  inset: 0;
  z-index: var(--z-index-ops-command);
  display: flex;
  align-items: flex-start;
  justify-content: center;
  padding-top: 12vh;
}

.ops-cmdk__panel {
  position: relative;
  display: flex;
  flex-direction: column;
  width: min(34rem, calc(100vw - 2rem));
  max-height: 70vh;
  overflow: hidden;
  border: 1px solid color-mix(in oklch, var(--color-base-content) 14%, transparent);
  border-radius: var(--radius-ops-overlay);
  background: color-mix(in oklch, var(--color-base-100) 98%, transparent);
  box-shadow: var(--shadow-ops-overlay);
  animation: ops-modal-in var(--duration-ops-slow) var(--ease-ops-out);
}
```

**Theme-toggle state pattern** (lines 1313-1416):
```css
/* Theme toggle: pill position follows `html[data-theme-effective]` (root inline script). */
#theme-toggle-pill {
  transition-property: left;
  transition-duration: var(--duration-ops-fast);
  transition-timing-function: var(--ease-ops-standard);
}

html[data-theme-effective="light"] #theme-toggle-pill {
  left: 33.333333%;
}

html[data-theme-effective="dark"] #theme-toggle-pill {
  left: 66.666667%;
}

html[data-theme-preference="system"] #theme-toggle [data-phx-theme="system"] {
  box-shadow: 0 0 0 2px var(--color-primary);
}
```

**Dual-dark composition pattern** (lines 1470-1500):
```css
/* panel-dark seated depth -- GROUP 2 (overlay-base panels).
   #flash-group > * and .ops-cmdk__panel carry --shadow-ops-overlay; compose (keep overlay first). */
[data-theme="dark"] #flash-group > *,
[data-theme="dark"] .ops-cmdk__panel {
  box-shadow: var(--shadow-ops-overlay), var(--shadow-ops-panel-dark);
}
@media (prefers-color-scheme: dark) {
  html:not([data-theme="light"]) #flash-group > *,
  html:not([data-theme="light"]) .ops-cmdk__panel {
    box-shadow: var(--shadow-ops-overlay), var(--shadow-ops-panel-dark);
  }
}

[data-theme="dark"] .ops-nav-item-active {
  box-shadow: var(--shadow-ops-surface), var(--shadow-ops-glow);
}
@media (prefers-color-scheme: dark) {
  html:not([data-theme="light"]) .ops-nav-item-active {
    box-shadow: var(--shadow-ops-surface), var(--shadow-ops-glow);
  }
}
```

**Dark shadow token pattern** (lines 1534-1555):
```css
[data-theme="dark"] {
  --shadow-ops-surface: 0 1px 2px rgba(0,0,0,0.40);
  --shadow-ops-mid:     0 1px 4px rgba(0,0,0,0.45);
  --shadow-ops-raised:  0 2px 10px rgba(0,0,0,0.50);
  --shadow-ops-overlay: 0 8px 24px rgba(0,0,0,0.55);
  --shadow-ops-panel-dark: 0 0 0 1px rgba(0,0,0,0.30), 0 1px 3px rgba(0,0,0,0.45);
  --shadow-ops-glow:        0 0 8px 2px rgba(108,92,231,0.30);
}
@media (prefers-color-scheme: dark) {
  html:not([data-theme="light"]) {
    --shadow-ops-surface: 0 1px 2px rgba(0,0,0,0.40);
    --shadow-ops-panel-dark: 0 0 0 1px rgba(0,0,0,0.30), 0 1px 3px rgba(0,0,0,0.45);
    --shadow-ops-glow:        0 0 8px 2px rgba(108,92,231,0.30);
  }
}
```

**Planner notes:**
- Preserve Tailwind v4 import/source/plugin syntax; do not use `@apply`.
- For custom shell dark rules, mirror explicit dark and system dark unless the rule rides semantic daisyUI tokens.
- Compose shadows instead of replacing them: overlay first, seated/glow layer second.
- Keep `.ops-shell` to one top-left radial wash; no additional gradient layers, orbs, texture, or bokeh.

---

### `scrypath_ops/assets/css/DESIGN-TOKENS.md` (config, transform)

**Analog:** `scrypath_ops/assets/css/DESIGN-TOKENS.md`

**Token law pattern** (lines 1-19):
```markdown
# ScrypathOps design tokens

The brand + design-system contract for the `/ops` operator shell. Tokens live in the
`@theme` block of [`app.css`](./app.css); the `.ops-*` component classes in the same
file consume them. This doc is the catalog -- change a value here only by changing it in
`app.css`.

## Two governing laws

1. **Prefix convention.** daisyUI classnames stay **unprefixed** (`btn`, `select`,
   `input`, `table`, `modal`, `checkbox`). Custom classes are **`.ops-`** BEM-ish
   (`.ops-block`, `.ops-block-modifier`, `.ops-block__element`).
2. **Component class vs utility.** Put a value in a **`.ops-*` component class** when it
   is intrinsic to a reusable surface/control's identity.
```

**Contrast floor pattern** (lines 50-64):
```markdown
| `--ops-text-muted` | `color-mix(in oklch, var(--color-base-content) 64%, transparent)` | `color-mix(in oklch, var(--color-base-content) 64%, transparent)` | `.ops-header .text-base-content/60`, `.ops-shell .text-base-content/60`, ... |
| `--color-primary-strong` | `#5b4ad1` | `#5b4ad1` | `.ops-nav-item-active`, `.bg-primary.text-primary-content` |

`--ops-text-muted` is the named readable-muted floor. Do not reintroduce raw
`color-mix(in oklch, var(--color-base-content) NN%, transparent)` declarations for
the consumers above.

`--color-primary-strong` is allowed only for text-bearing interactive/selected fills:
`.ops-nav-item-active` and `.bg-primary.text-primary-content`.
```

**Dark ambient depth pattern** (lines 118-132):
```markdown
**Dark-only augmentation:** `--shadow-ops-panel-dark` is a dark-only supplement declared in
the D-10 dual-path blocks; it is **not** declared in light. Light panels continue to use
`--shadow-ops-surface` (vertical lift).

| `--shadow-ops-panel-dark` | (not declared in light) | `0 0 0 1px rgba(0,0,0,0.30), 0 1px 3px rgba(0,0,0,0.45)` | Ambient seated-depth shadow on dark panels: `.ops-panel`, `.ops-cmdk__panel`, `#flash-group > *`, `.ops-intent-card` |
| `--shadow-ops-glow` | `none` | `0 0 8px 2px rgba(108,92,231,0.30)` | Quiet violet glow -- route mark / active nav / key-callout hover only. |
```

**Motion restraint pattern** (lines 236-257):
```markdown
Everything below is neutralized under `@media (prefers-reduced-motion: reduce)` (one global
rule), so any new transition is reduced-motion-safe by default. Keep it restrained:
transform/opacity only, < 300ms, ease-out for enter, no bounce (this is an incident tool).

| `ops-modal-in` | enter | `--duration-ops-slow` + `--ease-ops-out` | `.modal-box`, `.ops-cmdk__panel` (open) |
| `ops-modal-out` | exit | `--duration-ops-fast` + `--ease-ops-exit` | `.ops-cmdk--closing .ops-cmdk__panel` (palette/sheet close) |
```

**Planner notes:**
- Any CSS token/value change in `app.css` must be reflected here.
- Keep light unchanged unless a shell-only objective defect is documented as an exception.

---

### `scrypath_ops/assets/css/contrast-pairs.mjs` (config, transform, conditional)

**Analog:** `scrypath_ops/assets/css/contrast-pairs.mjs`

**Manifest rule pattern** (lines 1-35):
```javascript
// Muted-alpha text manifest (D-11): ONLY muted cases that are opacity-mixes of
// base-content via `color-mix(in oklch, var(--color-base-content) NN%, transparent)`.
//
// Design constraints:
//   (1) References TOKEN NAMES not hex -- hex lives in app.css only.
//   (2) Alpha compositing is sRGB, not OKLCH.
//   (3) The D-15 lockstep guard validates that every
//       `color: color-mix(in oklch, var(--color-base-content) NN%, transparent)`
//       occurrence in app.css is tracked here.
```

**Existing shell entries pattern** (lines 36-56, 142-170):
```javascript
export const MUTED_PAIRS = [
  // app.css line 252 -- header utility override
  {
    selector: ".ops-header .text-base-content\\/60",
    css_var: "ops-text-muted",
    alpha: 0.64,
    fg_token: "base-content",
    bg_token: "base-100",
    role: "text",
    note: "header utility override"
  },
```

```javascript
  // app.css line 1115 -- command palette item hint
  {
    selector: ".ops-cmdk__item-hint",
    css_var: "ops-text-muted",
    alpha: 0.64,
    fg_token: "base-content",
    bg_token: "base-100",
    role: "text",
    note: "palette item hint"
  },
  // app.css line 1144 -- cheatsheet description text
  {
    selector: ".ops-cheatsheet__row dd",
    alpha: 0.70,
    fg_token: "base-content",
    bg_token: "base-100",
    role: "text",
    note: "cheatsheet description text"
  },
```

**Planner notes:**
- Modify only if Phase 135 introduces new tracked muted text or raw `color-mix(... base-content NN%, transparent)` `color:` declarations.
- Prefer `--ops-text-muted` for readable muted shell text so existing lockstep stays small.

---

### `examples/scrypath_ecommerce/e2e/admin_shell_chrome.spec.ts` (test, event-driven + request-response)

**Analog:** `examples/scrypath_ecommerce/e2e/admin_surface_depth.spec.ts`

**Supporting analogs:**
- `examples/scrypath_ecommerce/e2e/helpers/theme-grid.ts`
- `examples/scrypath_ecommerce/e2e/admin_contrast_matrix.spec.ts`
- `examples/scrypath_ecommerce/e2e/admin_path_motion.spec.ts`

**Imports and theme grid pattern** (`admin_surface_depth.spec.ts` lines 13-37):
```typescript
import { expect, test, type APIRequestContext, type Browser, type Locator, type Page } from "@playwright/test";

import {
  drainSearchQueue,
  seedScenario,
  waitForSearchVisible,
  type SeedScenario
} from "./helpers/e2e";
import {
  assertSystemDarkInvariants,
  gotoControlRoom,
  gotoFailedSync,
  gotoPlaybooks,
  gotoPosture,
  gotoSearch,
  SCENARIO_CAPTURES,
  THEME_MODES,
  themeSlug,
  VIEWPORT_NAMES,
  VIEWPORTS,
  type ThemeMode,
  type ViewportName
} from "./helpers/theme-grid";
```

**Theme modes and routes pattern** (`helpers/theme-grid.ts` lines 5-27, 44-82):
```typescript
export type ThemeMode =
  | { kind: "explicit"; theme: "light" | "dark" }
  | { kind: "system"; colorScheme: "dark" };

export const THEME_MODES: ThemeMode[] = [
  { kind: "explicit", theme: "light" },
  { kind: "explicit", theme: "dark" },
  { kind: "system", colorScheme: "dark" }
];

export const VIEWPORTS: Record<ViewportName, { width: number; height: number }> = {
  mobile: { width: 390, height: 844 },
  desktop: { width: 1440, height: 900 }
};
```

```typescript
export async function gotoControlRoom(page: Page): Promise<void> {
  await page.goto("/admin/search");
  await waitForLiveConnected(page);
  await expect(page.getByRole("heading", { name: "Control Room" })).toBeVisible();
}

export async function gotoPosture(page: Page): Promise<void> {
  await page.goto("/admin/search/posture");
  await waitForLiveConnected(page);
  await page.getByRole("button", { name: "Refresh posture" }).click();
  await expect(page.getByRole("heading", { name: "Posture", exact: true })).toBeVisible();
}
```

**Themed browser context pattern** (`admin_surface_depth.spec.ts` lines 67-88):
```typescript
async function newThemedPage(
  browser: Browser,
  mode: ThemeMode,
  viewport: ViewportName
): Promise<{ page: Page; close: () => Promise<void> }> {
  const context = await browser.newContext({
    viewport: VIEWPORTS[viewport],
    ...(mode.kind === "system" ? { colorScheme: mode.colorScheme as "dark" } : {})
  });

  if (mode.kind === "explicit") {
    await context.addInitScript(
      ([key, value]: [string, string]) => {
        window.localStorage.setItem(key, value);
      },
      ["phx:theme", mode.theme]
    );
  }

  const page = await context.newPage();
  return { page, close: () => context.close() };
}
```

**Computed-style helper pattern** (`admin_surface_depth.spec.ts` lines 90-112):
```typescript
async function readComputedStyle(
  page: Page,
  selector: string,
  property: "backgroundColor" | "borderColor" | "boxShadow" | "color"
): Promise<string> {
  return page.evaluate(
    ([sel, prop]) => {
      const el = document.querySelector(sel);
      if (!el) throw new Error(`surface-depth probe: element not found for ${sel}`);
      return getComputedStyle(el)[prop as "backgroundColor" | "borderColor" | "boxShadow" | "color"];
    },
    [selector, property] as const
  );
}
```

**Loop/try-finally pattern** (`admin_surface_depth.spec.ts` lines 404-429):
```typescript
test.describe("admin surface depth -- SCREEN-DARK-01", () => {
  test.describe.configure({ timeout: 120_000 });

  for (const target of DEPTH_TARGETS) {
    for (const mode of DARK_THEME_MODES) {
      for (const viewport of VIEWPORT_NAMES) {
        test(`${target.id} skeleton (${themeSlug(mode)}, ${viewport})`, async ({ browser, request }) => {
          await seedAndMaybeConfirmSearch(request, target.scenario);

          const { page, close } = await newThemedPage(browser, mode, viewport);
          try {
            if (target.prepare) {
              await target.prepare(page);
            } else {
              await captureByIndex(target.scenario, target.captureIndex).prepare(page);
            }

            if (mode.kind === "system") {
              await assertSystemDarkInvariants(page);
            }
```

**Axe-after-state pattern** (`admin_contrast_matrix.spec.ts` lines 314-317):
```typescript
const aaResults = await new AxeBuilder({ page })
  .withRules(["color-contrast"])
  .analyze();
```

**AA report/gate pattern** (`admin_contrast_matrix.spec.ts` lines 394-401):
```typescript
await writeContrastReport(findings, scenario);

const aaFails = findings.filter(f => f.severity === "aa-fail").length;
expect(
  aaFails,
  `${aaFails} AA contrast violations found -- see CONTRAST_REPORT_DIR`
).toBe(0);
```

**Existing flash trigger pattern** (`playbook_live.ex` lines 210-219 and 1115-1117):
```elixir
def handle_event("copy_run_diagnostics", _params, socket) do
  payload =
    socket.assigns.run_failure_enriched
    |> diagnostics_payload()
    |> Jason.encode!()

  {:noreply,
   socket
   |> push_event("copy_run_diagnostics", %{text: payload})
   |> put_flash(:info, "Copied diagnostics.")}
end
```

```heex
<.ops_button phx-click="copy_run_diagnostics" variant={:ghost} size={:xs}>
  Copy diagnostics
</.ops_button>
```

**Planner notes:**
- New spec should cover `THEME_MODES` x `VIEWPORT_NAMES`, and all six surfaces through helper routes or scenario captures.
- Exercise hidden chrome before checking it: open/filter/empty/close command palette, shortcut sheet, theme toggle transitions, and a real visible flash.
- Use computed-style assertions for header separation, active nav fill/glow, `.ops-shell` wash boundedness, palette/flash shadow composition, focus visibility, and theme state attributes.
- Use `try/finally` to close contexts.

---

### `examples/scrypath_ecommerce/package.json` (config, batch)

**Analog:** `examples/scrypath_ecommerce/package.json`

**Script pattern** (lines 5-13):
```json
"scripts": {
  "test:e2e:headed": "playwright test --headed",
  "test:e2e": "playwright test",
  "test:e2e:list": "playwright test --list",
  "test:e2e:path-motion": "playwright test e2e/admin_path_motion.spec.ts",
  "test:e2e:admin-depth": "playwright test e2e/admin_surface_depth.spec.ts",
  "test:e2e:admin-screens": "playwright test e2e/admin_screenshots.spec.ts",
  "test:e2e:admin-matrix": "playwright test e2e/admin_screenshot_matrix.spec.ts",
  "test:e2e:admin-contrast": "playwright test e2e/admin_contrast_matrix.spec.ts"
}
```

**Planner notes:**
- Add only a script such as `"test:e2e:admin-shell": "playwright test e2e/admin_shell_chrome.spec.ts"`.
- Do not install or upgrade Playwright/axe packages in this phase.

---

### `scrypath_ops/test/scrypath_ops_web/ops_shell_contract_test.exs` (test, request-response, conditional)

**Analog:** `scrypath_ops/test/scrypath_ops_web/ops_shell_contract_test.exs`

**LiveView contract setup pattern** (lines 1-10, 42-103):
```elixir
defmodule ScrypathOpsWeb.OpsShellContractTest do
  @moduledoc false
  use ScrypathOpsWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias ScrypathOps.Test.OpsPostA
  alias ScrypathOps.Test.OpsPostB
  alias ScrypathOps.Test.SearchPlaygroundStubAdapter
```

```elixir
setup do
  keys = ~w(
    schema_allowlist backend sync_mode index_prefix meilisearch_url meilisearch_client
    meilisearch_tasks oban oban_queue oban_inspector oban_jobs search_playground_adapter
    search_stub_variant
  )a

  previous = Map.new(keys, &{&1, Application.get_env(:scrypath_ops, &1)})

  Application.put_env(:scrypath_ops, :schema_allowlist, [OpsPostA, OpsPostB])
  Application.put_env(:scrypath_ops, :backend, Scrypath.Meilisearch)
  ...

  on_exit(fn ->
    Enum.each(previous, fn
      {k, nil} -> Application.delete_env(:scrypath_ops, k)
      {k, v} -> Application.put_env(:scrypath_ops, k, v)
    end)
  end)

  :ok
end
```

**Shell marker assertions pattern** (lines 105-127):
```elixir
defp assert_ops_shell!(html, title_fragment) do
  assert html =~ "data-phx-session"
  assert html =~ title_fragment
  assert html =~ ~r/href="\/ops\/assets\/css\/app(?:-[^"]+)?\.css(?:\?[^"]*)?"/
  assert html =~ ~r/src="\/ops\/assets\/js\/app(?:-[^"]+)?\.js(?:\?[^"]*)?"/
  assert html =~ ~s(id="flash-group")
  assert Regex.scan(~r/id=\"flash-group\"/, html) |> length() == 1
  assert html =~ ~s(id="ops-main")
  assert html =~ "Skip to operator content"
  assert html =~ ~s(aria-current="page")
  assert html =~ ~s(fill="#C17A3E")
  assert html =~ "ScrypathOps"
  assert html =~ ~s(aria-label="Theme preference")
end
```

**Route iteration pattern** (lines 129-148):
```elixir
describe "ops shell markers" do
  test "/ops/posture", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/ops/posture")
    assert_ops_shell!(html, "Posture / health")
  end

  test "/ops/search", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/ops/search")
    assert_ops_shell!(html, "Search &amp; federation")
  end
end
```

**Planner notes:**
- Use this existing file for cheap DOM marker assertions such as required `.ops-*` classes, live inline brand selector, and one `flash-group`.
- Do not use raw snapshots for browser behavior; keep interactive/focus/theme checks in Playwright.

---

### `scrypath_ops/test/scrypath_ops_web/shell_chrome_token_contract_test.exs` (test, transform, conditional new file)

**Analog:** `scrypath_ops/test/scrypath_ops_web/surface_depth_token_contract_test.exs`

**Static CSS contract pattern** (lines 1-13):
```elixir
defmodule ScrypathOpsWeb.SurfaceDepthTokenContractTest do
  @moduledoc """
  Locks the SCREEN-DARK-01 surface-depth value contract as static CSS assertions.

  This is a pure file-read + regex contract over `assets/css/app.css`, modeled on
  `MotionContractTest`.
  """
  use ExUnit.Case, async: true

  @app_css Path.join(__DIR__, "../../assets/css/app.css") |> Path.expand()

  defp css, do: File.read!(@app_css)
```

**Dual-dark regex assertion pattern** (lines 20-32):
```elixir
test ".ops-data-card dark fill references --ops-surface-2" do
  assert Regex.match?(
           ~r/\[data-theme="dark"\]\s+\.ops-data-card\s*\{[^{}]*background:\s*var\(--ops-surface-2\)/,
           css()
         ),
         ".ops-data-card explicit-dark fill must reference var(--ops-surface-2), not a hardcoded color."

  assert Regex.match?(
           ~r/html:not\(\[data-theme="light"\]\)\s+\.ops-data-card\s*\{[^{}]*background:\s*var\(--ops-surface-2\)/,
           css()
         ),
         ".ops-data-card system-dark fill must mirror var(--ops-surface-2)."
end
```

**Motion-contract analog for symmetry** (`motion_contract_test.exs` lines 118-178):
```elixir
test "every dark-only path glow end state is mirrored in both dark paths" do
  source = css()

  explicit_dark =
    Regex.scan(
      ~r/\[data-theme="dark"\]\s+([^{}\n]*?ops-[a-z0-9-]+)[^{}]*\{[^{}]*var\(--shadow-ops-glow/,
      source
    )
    |> Enum.map(fn [_, sel] -> String.trim(sel) end)
    |> MapSet.new()

  system_dark =
    Regex.scan(
      ~r/html:not\(\[data-theme="light"\]\)\s+([^{}\n]*?ops-[a-z0-9-]+)[^{}]*\{[^{}]*var\(--shadow-ops-glow/,
      source
    )
    |> Enum.map(fn [_, sel] -> String.trim(sel) end)
    |> MapSet.new()
```

**Planner notes:**
- Prefer adding static checks only for durable invariants: required shell classes, dual-dark mirror presence, no extra `.ops-shell` wash layers, or stale `.ops-route-mark` proof.
- If assertions are normal ExUnit tests under `scrypath_ops/test`, `mix verify.opsui` already runs them; no root task change is needed.

---

### `lib/mix/tasks/verify.opsui.ex` (utility, batch, conditional)

**Analog:** `lib/mix/tasks/verify.opsui.ex`

**Batch verification pattern** (lines 24-49):
```elixir
@impl true
def run(args) do
  Mix.Task.run("app.start")
  ensure_no_args!(args)

  ops_dir = Path.expand("scrypath_ops", File.cwd!())

  unless File.dir?(ops_dir) do
    Mix.raise("verify.opsui: expected #{ops_dir} to exist")
  end

  Mix.shell().info("==> verify.opsui: cd scrypath_ops && mix deps.get && mix test")

  script = "export CI=true; printf 'n\\n' | mix deps.get && mix test"

  {out, status} =
    System.cmd("bash", ["-lc", script], cd: ops_dir, stderr_to_stdout: true)

  Mix.shell().info(out)

  if status != 0 do
    Mix.raise("verify.opsui failed: `#{script}` (in #{ops_dir}) exited #{status}")
  end
end
```

**No-args guard pattern** (lines 51-55):
```elixir
defp ensure_no_args!([]), do: :ok

defp ensure_no_args!(args) do
  Mix.raise("verify.opsui does not accept arguments, got: #{Enum.join(args, " ")}")
end
```

**Planner notes:**
- Likely no edit is needed if new static shell checks are ExUnit tests.
- Modify only if adding a non-ExUnit, cheap, durable selector/token tripwire that must be part of `mix verify.opsui`.

## Shared Patterns

### Project and Phoenix Rules
**Source:** `scrypath_ops/AGENTS.md`
**Apply to:** All Phoenix component, CSS, JS, and test files

- Run `mix precommit` when done with Phoenix app changes.
- Preserve Tailwind v4 imports in `app.css`.
- Do not use `@apply`.
- Do not write new inline custom scripts in templates unless extending the established root theme mechanism is explicitly justified.
- Use the imported `<.icon>` component for Heroicons.
- Keep `<.flash_group>` inside `layouts.ex`.
- LiveView tests should use `Phoenix.LiveViewTest`, `element/2`, and `has_element?/2` style assertions where interaction is under test.

### Nav Data Source
**Source:** `scrypath_ops/lib/scrypath_ops_web/nav.ex` lines 1-47
**Apply to:** `layouts.ex`, `ops_ui.ex`, `admin_shell_chrome.spec.ts`
```elixir
defmodule ScrypathOpsWeb.Nav do
  @moduledoc """
  Curated primary navigation for the `/ops` operator shell.
  """

  def primary(mount_path \\ "/ops") do
    [
      %{path: "#{mount_path}/posture", label: "Posture", title: "Posture / health", group: :recover},
      %{path: "#{mount_path}/failed-sync", label: "Failed Sync", title: "Failed sync work", group: :recover},
      %{path: "#{mount_path}/sync-drift", label: "Sync Drift", title: "Sync / drift", group: :recover},
      %{path: "#{mount_path}/search", label: "Search", title: "Search & federation", group: :explore},
      %{path: "#{mount_path}/playbooks", label: "Playbooks", title: "Saved playbooks", group: :explore}
    ]
  end
end
```

### Durable `.ops-*` Selectors With Stable IDs
**Source:** `layouts.ex` lines 59-105, `ops_ui.ex` lines 1090-1161, `app.css` lines 1047-1124
**Apply to:** Shell markup, palette, theme toggle, flash, browser tests

Keep existing IDs for JS/tests and add component classes for durable styling/proof:
```heex
<header class="ops-header ...">
<main id="ops-main" class="ops-shell ...">
<.flash_group flash={@flash} id="flash-group" />
<div id="ops-command-palette" phx-hook="CommandPalette" data-cheatsheet="ops-cheatsheet">
  <div id="ops-cmdk" class="ops-cmdk" ...>
```

### Dual-Dark CSS Mirrors
**Source:** `app.css` lines 1472-1500 and 1536-1555
**Apply to:** Any custom shell dark visual change
```css
[data-theme="dark"] .selector {
  box-shadow: var(--shadow-ops-panel-dark);
}
@media (prefers-color-scheme: dark) {
  html:not([data-theme="light"]) .selector {
    box-shadow: var(--shadow-ops-panel-dark);
  }
}
```

### Browser Theme Matrix
**Source:** `helpers/theme-grid.ts` lines 5-27 and `admin_surface_depth.spec.ts` lines 67-88
**Apply to:** `admin_shell_chrome.spec.ts`
```typescript
export const THEME_MODES: ThemeMode[] = [
  { kind: "explicit", theme: "light" },
  { kind: "explicit", theme: "dark" },
  { kind: "system", colorScheme: "dark" }
];

const context = await browser.newContext({
  viewport: VIEWPORTS[viewport],
  ...(mode.kind === "system" ? { colorScheme: mode.colorScheme as "dark" } : {})
});
```

### Static Contract Style
**Source:** `surface_depth_token_contract_test.exs` lines 1-13, `motion_contract_test.exs` lines 118-178
**Apply to:** Optional shell CSS contract checks
```elixir
use ExUnit.Case, async: true

@app_css Path.join(__DIR__, "../../assets/css/app.css") |> Path.expand()
defp css, do: File.read!(@app_css)

assert Regex.match?(~r/\[data-theme="dark"\]\s+\.selector/, css())
assert Regex.match?(~r/html:not\(\[data-theme="light"\]\)\s+\.selector/, css())
```

## No Analog Found

All target and conditional files have close local analogs.

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| None | - | - | Existing shell, CSS, JS, ExUnit, and Playwright patterns cover the phase. |

## Metadata

**Analog search scope:** `scrypath_ops/lib/scrypath_ops_web`, `scrypath_ops/assets/css`, `scrypath_ops/assets/js`, `scrypath_ops/test/scrypath_ops_web`, `examples/scrypath_ecommerce/e2e`, `examples/scrypath_ecommerce/package.json`, `lib/mix/tasks/verify.opsui.ex`
**Files scanned:** 122
**Project skill directories:** `.codex/skills` and `.agents/skills` not present in this repo
**Recent analog commits considered:** `layouts.ex` 2026-06-25, `app.css` 2026-06-25, `admin_surface_depth.spec.ts` 2026-06-25, `admin_contrast_matrix.spec.ts` 2026-06-25, `ops_shell_contract_test.exs` 2026-06-25
**Pattern extraction date:** 2026-06-26
