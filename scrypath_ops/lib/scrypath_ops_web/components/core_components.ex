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
      role="alert"
      class={[
        "ops-flash z-50",
        @kind == :info && "ops-flash--info",
        @kind == :error && "ops-flash--error"
      ]}
      {@rest}
    >
      <div class={[
        "alert w-full max-w-full text-wrap",
        @kind == :info && "alert-info",
        @kind == :error && "alert-error"
      ]}>
        <.icon :if={@kind == :info} name="hero-information-circle" class="size-5 shrink-0" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle" class="size-5 shrink-0" />
        <div>
          <p :if={@title} class="font-semibold">{@title}</p>
          <p>{msg}</p>
        </div>
        <div class="flex-1" />
        <button
          type="button"
          class="group self-start cursor-pointer"
          aria-label={gettext("Close notification")}
        >
          <.icon name="hero-x-mark" class="size-5 opacity-40 group-hover:opacity-70" />
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

  ## Examples

      <.icon name="hero-x-mark" />
      <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
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
  # (= --duration-ops-slow). Routes through the house ease token, not a raw Tailwind step.
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

  # Exit is the crisp dismissal beat: `ease-ops-exit` (ease-in), faster than the enter, so
  # closing a flash/banner feels as intentional as it appearing (A1 enter/exit asymmetry).
  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 120,
      transition:
        {"transition-all ease-ops-exit duration-200", "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end
end
