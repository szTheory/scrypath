defmodule ScrypathOpsWeb.OpsUi do
  @moduledoc """
  Shared function components for `/ops` surfaces: page chrome, panels, and optional scaffold.
  """
  use Phoenix.Component

  use Gettext, backend: ScrypathOpsWeb.Gettext

  @doc """
  Primary page title (`<h1>`) and optional subtitle for operator LiveViews.

  The visible title exposes `id={title_id}` (default `"ops-page-title"`) so the `:ops`
  shell can reference it from `main` via `aria-labelledby`. Each `/ops` route should
  render a single page-level `h1` — do not duplicate this id elsewhere.
  """
  attr(:title, :string, required: true)
  attr(:subtitle, :string, default: nil)
  attr(:title_id, :string, default: "ops-page-title")

  def ops_page_header(assigns) do
    ~H"""
    <div class="space-y-1">
      <p class="text-xs font-semibold uppercase tracking-wide text-secondary">Operator workspace</p>
      <h1 id={@title_id} class="text-2xl font-semibold leading-8 tracking-normal text-base-content">
        {@title}
      </h1>
      <p :if={@subtitle} class="max-w-3xl text-sm text-base-content/70">{@subtitle}</p>
    </div>
    """
  end

  @doc """
  Flat bordered panel for primary JTBD blocks (D-12).
  """
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def ops_panel(assigns) do
    ~H"""
    <div class={["ops-panel p-4 md:p-5", @class]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "Toolbar row for page and section actions."
  attr(:class, :any, default: nil)
  slot(:inner_block, required: true)

  def ops_toolbar(assigns) do
    ~H"""
    <div class={["flex flex-wrap items-center justify-between gap-3", @class]}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "Button styling wrapper for operator actions."
  attr(:variant, :atom,
    default: :default,
    values: [:default, :primary, :secondary, :danger, :ghost]
  )

  attr(:size, :atom, default: :sm, values: [:xs, :sm, :md])
  attr(:type, :string, default: "button")
  attr(:class, :any, default: nil)

  attr(:rest, :global,
    include:
      ~w(phx-click phx-value-id phx-value-mode phx-value-name phx-value-schema phx-disable-with disabled data-testid aria-label)
  )

  slot(:inner_block, required: true)

  def ops_button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "btn min-h-10 rounded-md transition-transform active:scale-[0.96]",
        @size == :xs && "btn-xs",
        @size == :sm && "btn-sm",
        @variant == :primary && "btn-primary",
        @variant == :secondary && "btn-secondary",
        @variant == :danger && "btn-error",
        @variant == :ghost && "btn-ghost",
        @variant == :default && "btn-outline",
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  @doc "Status or guidance notice with Scrypath operator styling."
  attr(:kind, :atom, default: :info, values: [:info, :success, :warning, :error])
  attr(:title, :string, default: nil)
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def ops_notice(assigns) do
    ~H"""
    <div
      class={[
        "rounded-md border px-4 py-3 text-sm",
        @kind == :info && "border-info/40 bg-info/10 text-base-content",
        @kind == :success && "border-success/40 bg-success/10 text-base-content",
        @kind == :warning && "border-warning/40 bg-warning/10 text-base-content",
        @kind == :error && "border-error/40 bg-error/10 text-base-content",
        @class
      ]}
      {@rest}
    >
      <p :if={@title} class="font-semibold">{@title}</p>
      <div class={[@title && "mt-1"]}>{render_slot(@inner_block)}</div>
    </div>
    """
  end

  @doc "Small metric tile for rollups and status counts."
  attr(:label, :string, required: true)
  attr(:value, :any, required: true)
  attr(:tone, :atom, default: :neutral, values: [:neutral, :success, :warning, :error])

  def ops_metric(assigns) do
    ~H"""
    <div class={[
      "ops-muted-panel px-3 py-2",
      @tone == :success && "border-success/40",
      @tone == :warning && "border-warning/50",
      @tone == :error && "border-error/50"
    ]}>
      <p class="text-xs font-semibold uppercase tracking-wide text-base-content/60">{@label}</p>
      <p class="mt-1 font-mono text-lg font-semibold tabular-nums">{@value}</p>
    </div>
    """
  end

  @doc "Consistent empty/config state."
  attr(:title, :string, required: true)
  attr(:class, :any, default: nil)
  slot(:inner_block, required: true)

  def ops_empty_state(assigns) do
    ~H"""
    <div class={["ops-muted-panel p-5 text-sm", @class]}>
      <h2 class="text-base font-semibold text-base-content">{@title}</h2>
      <div class="mt-2 text-base-content/75">{render_slot(@inner_block)}</div>
    </div>
    """
  end

  @doc "Schema selector for allowlisted schema modules."
  attr(:id, :string, required: true)
  attr(:label, :string, default: "Schema")
  attr(:schemas, :list, required: true)
  attr(:selected, :any, default: nil)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(phx-change))

  def ops_schema_select(assigns) do
    ~H"""
    <form :if={@schemas != []} class={["flex flex-wrap items-end gap-2", @class]} {@rest}>
      <label for={@id} class="text-sm font-semibold text-base-content/75">{@label}</label>
      <select id={@id} name="schema" class="select select-bordered select-sm min-h-10">
        <option :for={mod <- @schemas} value={module_flat_name(mod)} selected={mod == @selected}>
          {module_flat_name(mod)}
        </option>
      </select>
    </form>
    """
  end

  @doc "Scrollable code/data block."
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def ops_code_block(assigns) do
    ~H"""
    <pre
      class={[
        "max-h-96 overflow-auto rounded-md bg-base-200 p-3 text-xs font-mono whitespace-pre-wrap break-words",
        @class
      ]}
      {@rest}
    >{render_slot(@inner_block)}</pre>
    """
  end

  @doc "Accessible modal shell for blocking file actions."
  attr(:title, :string, required: true)
  attr(:id, :string, required: true)
  attr(:class, :any, default: nil)
  slot(:inner_block, required: true)

  def ops_modal(assigns) do
    ~H"""
    <div
      id={@id}
      class="modal modal-open"
      role="dialog"
      aria-modal="true"
      aria-labelledby={"#{@id}-title"}
    >
      <div class={["modal-box rounded-lg", @class]}>
        <h3 id={"#{@id}-title"} class="text-lg font-semibold">{@title}</h3>
        <div class="mt-3">{render_slot(@inner_block)}</div>
      </div>
    </div>
    """
  end

  @doc """
  Composes `ops_page_header/1` and `ops_panel/1` when a LiveView prefers a single wrapper.
  """
  attr(:title, :string, required: true)
  attr(:subtitle, :string, default: nil)
  attr(:title_id, :string, default: "ops-page-title")
  slot(:inner_block, required: true)

  def ops_scaffold(assigns) do
    ~H"""
    <div class="space-y-4">
      <.ops_page_header title={@title} subtitle={@subtitle} title_id={@title_id} />
      <.ops_panel>
        {render_slot(@inner_block)}
      </.ops_panel>
    </div>
    """
  end

  defp module_flat_name(mod) when is_atom(mod) do
    mod |> Atom.to_string() |> String.replace_prefix("Elixir.", "")
  end
end
