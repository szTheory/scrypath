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

    <header class="ops-header px-4 py-3 sm:px-6 lg:px-8">
      <div class="flex flex-wrap items-center justify-between gap-4">
        <.link navigate={@mount_path} class="flex w-fit items-center gap-3">
          <.brand_mark />
          <span>
            <span class="block text-ops-body font-semibold leading-4">ScrypathOps</span>
            <span class="block text-ops-sm text-base-content/60">Ecto-native search operations</span>
          </span>
        </.link>

        <div class="flex flex-wrap items-center gap-3">
          <%!-- Header nav duplicates the command palette (⌘K) on mobile and wraps into a
          second row at 390px. Hide it below `sm`; ⌘K + the breadcrumb trail are the
          mobile navigation tiers. --%>
          <nav aria-label="Operator primary" class="hidden sm:block">
            <ul class="ops-nav-list">
              <li
                :for={item <- ScrypathOpsWeb.Nav.primary(@mount_path)}
                class={item.group == :explore && "ops-nav-group-explore"}
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
          <.brand_mark />
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

  @doc false
  # Brand mark: the scrypath `s/p` monogram. Inlined (not <img>) so the letters ride
  # `currentColor` and adapt to light/dark, with the copper "/" as the fixed brand accent —
  # mirroring the wordmark's "ink letters + copper slash" logic. Decorative; the adjacent
  # "ScrypathOps" text is the accessible name.
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
      <path
        d="M30 1002Q20 1002 14 998Q8 995 5 990Q2 986 2 981H17Q18 983 20 986Q21 988 24 989Q27 990 31 990Q35 990 38 988Q40 987 40 984Q40 982 38 980Q36 978 31 977L24 975Q19 973 15 971Q10 969 7 965Q5 962 5 956Q5 948 11 943Q17 938 28 938Q36 938 41 941Q47 944 49 948Q52 952 52 957H37Q37 953 34 951Q32 949 28 949Q24 949 22 951Q20 952 20 955Q20 958 22 959Q24 961 28 962L36 965Q41 966 45 968Q49 970 52 974Q55 977 55 983Q55 991 48 996Q42 1002 30 1002Z"
        fill="currentColor"
      />
      <path d="M55 1010V1009L83 920H96V921L68 1010Z" fill="#C17A3E" />
      <path
        d="M102 1020V940H117V948H119Q121 944 125 941Q129 939 136 939Q144 939 149 943Q155 947 157 954Q160 961 160 970Q160 979 157 986Q154 993 149 997Q144 1001 136 1001Q130 1001 126 999Q122 997 120 993H118V1020ZM131 990Q137 990 140 985Q143 980 143 970Q143 960 140 955Q137 950 131 950Q125 950 121 956Q118 961 118 970Q118 979 121 984Q125 990 131 990Z"
        fill="currentColor"
      />
    </svg>
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
        class="absolute top-0 left-0 h-full w-1/3 rounded-full border border-base-200 bg-base-100"
      />

      <button
        class="flex min-h-[var(--control-h-md)] min-w-[var(--control-h-md)] cursor-pointer items-center justify-center p-ops-2"
        type="button"
        aria-label="Use system theme"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex min-h-[var(--control-h-md)] min-w-[var(--control-h-md)] cursor-pointer items-center justify-center p-ops-2"
        type="button"
        aria-label="Use light theme"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex min-h-[var(--control-h-md)] min-w-[var(--control-h-md)] cursor-pointer items-center justify-center p-ops-2"
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
