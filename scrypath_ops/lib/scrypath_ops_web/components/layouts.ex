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
          <div class="flex items-center justify-between gap-4">
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
              <.link navigate={@mount_path} class="flex w-fit min-w-0 items-center gap-3">
                <.brand_mark />
                <span class="min-w-0">
                  <span class="block text-ops-body font-semibold leading-4">ScrypathOps</span>
                  <span class="block truncate text-ops-sm text-base-content/60">
                    Ecto-native search operations
                  </span>
                </span>
              </.link>
            </div>

            <div class="hidden min-w-0 xl:flex">
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

  attr(:mount_path, :string, required: true)
  attr(:page_title, :string, default: nil)

  defp ops_sidebar(assigns) do
    ~H"""
    <aside class="ops-sidebar" aria-label="Operator primary">
      <div class="ops-sidebar__brand">
        <.link navigate={@mount_path} class="flex min-w-0 items-center gap-3">
          <.brand_mark />
          <span class="min-w-0">
            <span class="block text-ops-body font-semibold leading-4">ScrypathOps</span>
            <span class="block truncate text-ops-sm text-base-content/60">
              Ecto-native search operations
            </span>
          </span>
        </.link>
      </div>

      <.ops_primary_nav mount_path={@mount_path} page_title={@page_title} />

      <div class="ops-sidebar__footer">
        <.ops_command_hint prefix="Jump fast with" suffix="" />
      </div>
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
          <.link navigate={@mount_path} class="flex min-w-0 items-center gap-3" data-ops-nav-link>
            <.brand_mark />
            <span class="min-w-0">
              <span id="ops-mobile-nav-title" class="block text-ops-body font-semibold leading-4">
                ScrypathOps
              </span>
              <span class="block truncate text-ops-sm text-base-content/60">
                Ecto-native search operations
              </span>
            </span>
          </.link>
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
  # Brand mark: the scrypath `s/p` monogram. Inlined (not <img>) so the letters ride
  # `currentColor` and adapt to light/dark, with the copper "/" as the fixed brand accent —
  # mirroring the wordmark's "ink letters + copper slash" logic. Decorative; the adjacent
  # "ScrypathOps" text is the accessible name.
  attr(:class, :string, default: nil)

  defp brand_mark(assigns) do
    ~H"""
    <svg
      class={["ops-brand-mark", @class]}
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

  defp nav_item_icon(%{label: "Posture"}), do: "hero-shield-check"
  defp nav_item_icon(%{label: "Failed Sync"}), do: "hero-exclamation-triangle"
  defp nav_item_icon(%{label: "Sync Drift"}), do: "hero-arrows-right-left"
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
      <div
        id="theme-toggle-pill"
        class="ops-theme-toggle__pill absolute top-0 left-0 h-full w-1/3 rounded-full border border-base-200 bg-base-100"
      />

      <button
        class="ops-theme-toggle__button flex min-h-[var(--control-h-md)] min-w-[var(--control-h-md)] cursor-pointer items-center justify-center p-ops-2"
        type="button"
        aria-label="Use system theme"
        aria-pressed="false"
        data-theme-selected="false"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="ops-theme-toggle__button flex min-h-[var(--control-h-md)] min-w-[var(--control-h-md)] cursor-pointer items-center justify-center p-ops-2"
        type="button"
        aria-label="Use light theme"
        aria-pressed="false"
        data-theme-selected="false"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="ops-theme-toggle__button flex min-h-[var(--control-h-md)] min-w-[var(--control-h-md)] cursor-pointer items-center justify-center p-ops-2"
        type="button"
        aria-label="Use dark theme"
        aria-pressed="false"
        data-theme-selected="false"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
