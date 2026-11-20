defmodule ScrypathOpsWeb.CoreComponents do
  @moduledoc """
  Shared low-level chrome for the operator UI.

  > #### One component authority {: .warning}
  >
  > Operator UI is built **exclusively** from `ScrypathOpsWeb.OpsUI` (the `ops_*`
  > components) over the design-token system in `assets/css/app.css`. Do **not**
  > add generic `button`/`table`/`input`/`header`/`list` components here — reaching
  > for a `<.button>` bypasses the `.ops-btn` height/press-feel authority and ships
  > an inconsistent control. This module is intentionally minimal: it holds only
  > the framework-level pieces that have no `ops_*` equivalent.

  What lives here and why:

    * `flash/1` — flash/toast notice (daisyUI `alert`), rendered by
      `ScrypathOpsWeb.Layouts.flash_group/1`.
    * `icon/1` — Heroicon renderer via the Hex `heroicons` package (no npm asset
      dependency in host apps).
    * `show/1,2` and `hide/1,2` — `Phoenix.LiveView.JS` show/hide transitions used
      by the layout's connection-status banners and flash dismissal.
  """
  use Phoenix.Component
  use Gettext, backend: ScrypathOpsWeb.Gettext

  alias Phoenix.LiveView.JS

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr(:id, :string, doc: "the optional id of flash container")
  attr(:flash, :map, default: %{}, doc: "the map of flash messages to display")
  attr(:title, :string, default: nil)
  attr(:kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup")
  attr(:rest, :global, doc: "the arbitrary HTML attributes to add to the flash container")

  slot(:inner_block, doc: "the optional inner block that renders the flash message")

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      phx-hook={if(@kind == :info, do: "OpsToast", else: nil)}
      role={if(@kind == :info, do: "status", else: "alert")}
      class={[
        "ops-flash z-50",
        @kind == :info && "ops-flash--info",
        @kind == :error && "ops-flash--error"
      ]}
      {@rest}
    >
      <div class="alert w-full max-w-full text-wrap">
        <div>
          <p :if={@title} class="font-semibold">{@title}</p>
          <p>{msg}</p>
        </div>
        <div class="flex-1" />
        <button
          type="button"
          class="ops-flash__close self-start cursor-pointer"
          aria-label={gettext("Close notification")}
        >
          <.icon name="hero-x-mark" class="size-5" />
        </button>
      </div>
    </div>
    """
  end

  @doc """
  Renders a [Heroicon](https://heroicons.com).

  Heroicons come in four styles – outline, solid, mini, and micro.
  By default, the outline style is used, but solid and mini may
  be applied by using the `-solid`, `-mini`, and `-micro` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons render through the Hex `heroicons` Phoenix components so ScrypathOps
  does not depend on npm Heroicons assets being present in host applications.

  ScrypathOps renders icons only as control glyphs (the menu, close, copy, theme,
  new-tab, command-hint and disclosure controls), each inside a control that has an
  accessible name. Say a state in words, never with an icon, and never animate one.

  ## Examples

      <.icon name="hero-x-mark" />
      <.icon name="hero-x-mark" class="size-5" />
  """
  attr(:name, :string, required: true)
  attr(:class, :any, default: "size-4")

  def icon(%{name: "hero-" <> _} = assigns) do
    case heroicon(assigns.name) do
      {icon, style} ->
        attrs =
          %{class: assigns.class, __changed__: nil}
          |> maybe_put_icon_style(style)

        apply(Heroicons, icon, [attrs])

      :error ->
        ~H"""
        <span class={[@name, @class]} />
        """
    end
  end

  defp heroicon("hero-" <> name) do
    Code.ensure_loaded?(Heroicons)

    {name, style} =
      cond do
        String.ends_with?(name, "-solid") -> {String.replace_suffix(name, "-solid", ""), :solid}
        String.ends_with?(name, "-mini") -> {String.replace_suffix(name, "-mini", ""), :mini}
        String.ends_with?(name, "-micro") -> {String.replace_suffix(name, "-micro", ""), :micro}
        true -> {name, :outline}
      end

    {:erlang.binary_to_existing_atom(String.replace(name, "-", "_")), style}
  rescue
    ArgumentError -> :error
  end

  defp maybe_put_icon_style(attrs, :outline), do: attrs
  defp maybe_put_icon_style(attrs, style), do: Map.put(attrs, style, true)

  ## JS Commands

  # Enter eases in with the overlay ease (`ease-ops-out`); flash/banner shows over 240ms
  # (= --duration-ops-base). The duration is the brand token, not a raw Tailwind step, and `time`
  # is the same 240ms so the classes stay applied for exactly as long as the transition runs.
  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 240,
      transition:
        {"transition-all ease-ops-out duration-(--duration-ops-base)",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  # Exit is the crisp dismissal beat: `ease-ops-exit` (ease-in), faster than the enter, so
  # closing a flash/banner feels as intentional as it appearing (A1 enter/exit asymmetry). It
  # runs on the quick token (--duration-ops-quick, 160ms), with `time` equal to it.
  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 160,
      transition:
        {"transition-all ease-ops-exit duration-(--duration-ops-quick)",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end
end
