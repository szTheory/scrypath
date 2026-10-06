defmodule ScrypathOpsWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use ScrypathOpsWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates("layouts/*")

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app mount_path={@mount_path} flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr(:mount_path, :string, required: true, doc: "The dynamic engine mount path")
  attr(:flash, :map, required: true, doc: "the map of flash messages")
  attr(:page_title, :string, default: nil)

  attr(:shell, :atom,
    default: :default,
    doc: "`:ops` enables maintainer navigation for `/ops` LiveViews"
  )

  attr(:current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"
  )

  attr(:ops_main_width, :atom,
    default: :default,
    doc:
      "`:default` keeps `max-w-3xl` on `:ops` shell; `:wide` uses `max-w-7xl` for table-first routes (e.g. Search)."
  )

  slot(:inner_block, required: true)

  def app(%{shell: :ops} = assigns) do
    ~H"""
    <a
      href="#ops-main"
      class="sr-only focus:not-sr-only focus:absolute focus:top-ops-2 focus:left-ops-2 focus:z-ops-skip-link focus:rounded-ops-control focus:bg-base-100 focus:px-ops-3 focus:py-ops-2 focus:text-ops-body focus:font-medium focus:shadow-ops-overlay"
    >
      Skip to operator content
    </a>

    <div id="ops-shell-frame" class="ops-shell-frame" phx-hook="OpsNavDrawer">
      <.ops_sidebar mount_path={@mount_path} page_title={@page_title} />
      <.ops_mobile_nav mount_path={@mount_path} page_title={@page_title} />

      <div class="ops-shell-content">
        <header class="ops-header px-4 py-2 sm:px-6 lg:px-8">
          <div class="ops-header__inner">
            <div class="flex min-w-0 items-center gap-3 xl:hidden">
              <button
                type="button"
                class="ops-nav-trigger"
                aria-label="Open navigation"
                aria-controls="ops-mobile-nav"
                aria-expanded="false"
                data-ops-nav-open
              >
                <.icon name="hero-bars-3" class="size-5" />
              </button>
              <.link
                navigate={@mount_path}
                class="flex w-fit min-w-0 items-center gap-3"
                aria-label="Scrypath home"
                translate="no"
              >
                <.brand_mark mount_path={@mount_path} />
              </.link>
            </div>

            <div class="min-w-0 flex-1 xl:flex-none">
              <.ops_command_hint />
            </div>

            <div class="flex shrink-0 items-center gap-3">
              <.theme_toggle />
            </div>
          </div>
        </header>

        <main
          id="ops-main"
          aria-labelledby="ops-page-title"
          class="ops-shell min-h-screen px-4 pt-ops-4 pb-ops-6 sm:px-6 lg:px-8"
        >
          <div class={main_width_classes(@ops_main_width)}>
            {render_slot(@inner_block)}
          </div>
        </main>
      </div>
    </div>

    <.flash_group flash={@flash} id="flash-group" />
    <.ops_command_palette mount_path={@mount_path} />
    """
  end

  def app(assigns) do
    ~H"""
    <header class="navbar px-4 sm:px-6 lg:px-8">
      <div class="flex-1">
        <a href={"#{@mount_path}"} class="flex-1 flex w-fit items-center gap-2">
          <.brand_mark mount_path={@mount_path} />
          <span class="text-ops-body font-semibold">v{Application.spec(:phoenix, :vsn)}</span>
        </a>
      </div>
      <div class="flex-none">
        <ul class="flex flex-column px-1 space-x-4 items-center">
          <li>
            <a href="https://github.com/szTheory/scrypath" class="btn btn-ghost">GitHub</a>
          </li>
          <li>
            <a href={"#{@mount_path}/health"} class="btn btn-ghost">Operator UI</a>
          </li>
          <li>
            <.theme_toggle />
          </li>
          <li>
            <a href={"#{@mount_path}/health"} class="btn btn-primary">
              Open Search health <span aria-hidden="true">&rarr;</span>
            </a>
          </li>
        </ul>
      </div>
    </header>

    <main class="px-4 py-20 sm:px-6 lg:px-8">
      <div class="mx-auto max-w-2xl space-y-4">
        {render_slot(@inner_block)}
      </div>
    </main>

    <.flash_group flash={@flash} id="flash-group" />
    """
  end

  attr(:mount_path, :string, required: true)
  attr(:page_title, :string, default: nil)

  defp ops_sidebar(assigns) do
    ~H"""
    <aside class="ops-sidebar" aria-label="Operator primary">
      <div class="ops-sidebar__brand">
        <.link
          navigate={@mount_path}
          class="flex min-w-0 items-center gap-3"
          aria-label="Scrypath home"
          translate="no"
        >
          <.brand_mark mount_path={@mount_path} />
        </.link>
      </div>

      <.ops_primary_nav mount_path={@mount_path} page_title={@page_title} />
    </aside>
    """
  end

  attr(:mount_path, :string, required: true)
  attr(:page_title, :string, default: nil)

  defp ops_mobile_nav(assigns) do
    ~H"""
    <div
      id="ops-mobile-nav"
      class="ops-mobile-nav"
      role="dialog"
      aria-modal="true"
      aria-labelledby="ops-mobile-nav-title"
      hidden
      data-ops-nav-drawer
    >
      <div class="ops-mobile-nav__backdrop" data-ops-nav-close aria-hidden="true"></div>
      <aside class="ops-mobile-nav__panel" tabindex="-1" data-ops-nav-panel>
        <div class="ops-mobile-nav__header">
          <.link
            navigate={@mount_path}
            class="flex min-w-0 items-center gap-3"
            aria-label="Scrypath home"
            translate="no"
            data-ops-nav-link
          >
            <.brand_mark mount_path={@mount_path} />
          </.link>
          <h2 id="ops-mobile-nav-title" class="sr-only" translate="no">Scrypath navigation</h2>
          <button
            type="button"
            class="ops-nav-close"
            aria-label="Close navigation"
            data-ops-nav-close
          >
            <.icon name="hero-x-mark" class="size-5" />
          </button>
        </div>

        <.ops_primary_nav mount_path={@mount_path} page_title={@page_title} />
      </aside>
    </div>
    """
  end

  attr(:mount_path, :string, required: true)
  attr(:page_title, :string, default: nil)

  defp ops_primary_nav(assigns) do
    assigns = assign(assigns, :nav_sections, nav_sections(assigns.mount_path))

    ~H"""
    <nav class="ops-primary-nav" aria-label="Operator primary">
      <div class="ops-nav-groups">
        <section :for={section <- @nav_sections} class="ops-nav-group">
          <p class="ops-nav-group__label">{section.label}</p>
          <ul class="ops-nav-list">
            <li :for={item <- section.items}>
              <.link
                navigate={item.path}
                class={nav_link_classes(item, @page_title)}
                aria-current={if nav_item_active?(item, @page_title), do: "page", else: nil}
                data-ops-nav-link
              >
                <span class="ops-nav-item__icon" aria-hidden="true">
                  <.icon name={item.icon} class="size-4" />
                </span>
                <span class="ops-nav-item__label">{item.label}</span>
              </.link>
            </li>
          </ul>
        </section>
      </div>
    </nav>
    """
  end

  @doc false
  # Use the canonical horizontal wordmark from the brand book. The paired SVGs
  # preserve its ink/paper colors while the copper slash stays consistent in both themes.
  # Decorative; the enclosing home link supplies the accessible name.
  attr(:class, :string, default: nil)
  attr(:mount_path, :string, required: true)

  defp brand_mark(assigns) do
    ~H"""
    <span class={["ops-wordmark", @class]} aria-hidden="true">
      <img
        class="ops-wordmark__light"
        src={"#{@mount_path}/images/scrypath-wordmark.svg"}
        width="120"
        alt=""
        decoding="async"
      />
      <img
        class="ops-wordmark__dark"
        src={"#{@mount_path}/images/scrypath-wordmark-inverse.svg"}
        width="120"
        alt=""
        decoding="async"
      />
    </span>
    """
  end

  defp main_width_classes(:wide), do: ~w(mx-auto max-w-7xl w-full min-w-0 space-y-4)
  defp main_width_classes(_), do: ~w(mx-auto max-w-3xl w-full min-w-0 space-y-4)

  defp nav_link_classes(item, page_title) do
    # Focus indication comes from the single global `:focus-visible` outline (app.css
    # @layer base). No per-element `ring-*` — the outline isn't clipped by the nav's
    # flex-wrap container and double-drawing reads as muddy.
    [
      "ops-nav-item",
      nav_item_active?(item, page_title) && "ops-nav-item-active"
    ]
  end

  defp nav_item_active?(item, page_title), do: item.title == page_title

  defp nav_sections(mount_path) do
    [
      %{
        label: "Home",
        items: [
          %{
            path: mount_path,
            label: "Control Room",
            title: "Control Room",
            group: :home,
            icon: "hero-rectangle-group"
          }
        ]
      }
      | mount_path
        |> ScrypathOpsWeb.Nav.primary()
        |> Enum.map(&Map.put(&1, :icon, nav_item_icon(&1)))
        |> Enum.chunk_by(& &1.group)
        |> Enum.map(fn items -> %{label: nav_group_label(hd(items).group), items: items} end)
    ]
  end

  defp nav_group_label(:recover), do: "Recover"
  defp nav_group_label(:explore), do: "Explore"
  defp nav_group_label(group), do: group |> to_string() |> String.capitalize()

  defp nav_item_icon(%{label: "Search health"}), do: "hero-shield-check"
  defp nav_item_icon(%{label: "Failed sync work"}), do: "hero-exclamation-triangle"
  defp nav_item_icon(%{label: "Sync and drift"}), do: "hero-arrows-right-left"
  defp nav_item_icon(%{label: "Search"}), do: "hero-magnifying-glass"
  defp nav_item_icon(%{label: "Playbooks"}), do: "hero-book-open"
  defp nav_item_icon(_item), do: "hero-square-2-stack"

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr(:flash, :map, required: true, doc: "the map of flash messages")
  attr(:id, :string, default: "flash-group", doc: "the optional id of flash container")

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div
      id="theme-toggle"
      class="ops-theme-toggle card relative flex flex-row items-center border border-base-300 bg-base-300 rounded-full"
      role="group"
      aria-label="Theme preference"
    >
      <button
        class="ops-theme-toggle__button"
        type="button"
        aria-label="Use system theme"
        aria-pressed="false"
        data-theme-selected="false"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 shrink-0" />
        <span>System</span>
      </button>

      <button
        class="ops-theme-toggle__button"
        type="button"
        aria-label="Use light theme"
        aria-pressed="false"
        data-theme-selected="false"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 shrink-0" />
        <span>Light</span>
      </button>

      <button
        class="ops-theme-toggle__button"
        type="button"
        aria-label="Use dark theme"
        aria-pressed="false"
        data-theme-selected="false"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 shrink-0" />
        <span>Dark</span>
      </button>
    </div>
    """
  end
end
