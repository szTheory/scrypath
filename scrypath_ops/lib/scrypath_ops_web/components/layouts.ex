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
      class="sr-only focus:not-sr-only focus:absolute focus:top-2 focus:left-2 focus:z-50 focus:rounded-md focus:bg-base-100 focus:px-3 focus:py-2 focus:text-ops-body focus:font-medium focus:shadow-lg focus:outline-none focus:ring-2 focus:ring-primary"
    >
      Skip to operator content
    </a>

    <header class="ops-header px-4 py-3 sm:px-6 lg:px-8">
      <div class="flex flex-wrap items-center justify-between gap-4">
        <.link navigate={@mount_path} class="flex w-fit items-center gap-3">
          <img src={"#{@mount_path}/images/logo.svg"} width="36" height="36" alt="" />
          <span>
            <span class="block text-ops-body font-semibold leading-4">ScrypathOps</span>
            <span class="block text-ops-sm text-base-content/60">Ecto-native search operations</span>
          </span>
        </.link>

        <div class="flex flex-wrap items-center gap-3">
          <nav aria-label="Operator primary">
            <ul class="ops-nav-list">
              <li
                :for={item <- ScrypathOpsWeb.Nav.primary(@mount_path)}
                class={item.group == :probes && "ops-nav-group-probes"}
              >
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

    <.flash_group flash={@flash} id="flash-group" />
    <.ops_command_palette mount_path={@mount_path} />
    """
  end

  def app(assigns) do
    ~H"""
    <header class="navbar px-4 sm:px-6 lg:px-8">
      <div class="flex-1">
        <a href={"#{@mount_path}"} class="flex-1 flex w-fit items-center gap-2">
          <img src={"#{@mount_path}/images/logo.svg"} width="36" height="36" alt="" />
          <span class="text-ops-body font-semibold">v{Application.spec(:phoenix, :vsn)}</span>
        </a>
      </div>
      <div class="flex-none">
        <ul class="flex flex-column px-1 space-x-4 items-center">
          <li>
            <a href="https://github.com/szTheory/scrypath" class="btn btn-ghost">GitHub</a>
          </li>
          <li>
            <a href={"#{@mount_path}/posture"} class="btn btn-ghost">Operator UI</a>
          </li>
          <li>
            <.theme_toggle />
          </li>
          <li>
            <a href={"#{@mount_path}/posture"} class="btn btn-primary">
              Open Posture <span aria-hidden="true">&rarr;</span>
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

  defp main_width_classes(:wide), do: ~w(mx-auto max-w-7xl w-full min-w-0 space-y-4)
  defp main_width_classes(_), do: ~w(mx-auto max-w-3xl w-full min-w-0 space-y-4)

  defp nav_link_classes(item, page_title) do
    # Focus indication comes from the single global `:focus-visible` outline (app.css
    # @layer base). No per-element `ring-*` — the outline isn't clipped by the nav's
    # flex-wrap container and double-drawing reads as muddy.
    [
      "ops-nav-item",
      item.title == page_title && "ops-nav-item-active"
    ]
  end

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
      class="card relative flex flex-row items-center border border-base-300 bg-base-300 rounded-full"
      role="group"
      aria-label="Theme preference"
    >
      <div
        id="theme-toggle-pill"
        class="absolute top-0 w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0"
      />

      <button
        class="flex min-h-[var(--control-h-md)] min-w-[var(--control-h-md)] cursor-pointer items-center justify-center p-2"
        type="button"
        aria-label="Use system theme"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex min-h-[var(--control-h-md)] min-w-[var(--control-h-md)] cursor-pointer items-center justify-center p-2"
        type="button"
        aria-label="Use light theme"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex min-h-[var(--control-h-md)] min-w-[var(--control-h-md)] cursor-pointer items-center justify-center p-2"
        type="button"
        aria-label="Use dark theme"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
