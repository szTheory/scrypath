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
      <h1
        id={@title_id}
        class="text-ops-h1 font-semibold leading-ops-tight tracking-normal text-base-content"
      >
        {@title}
      </h1>
      <p :if={@subtitle} class="max-w-3xl text-sm text-base-content/70">{@subtitle}</p>
    </div>
    """
  end

  @doc """
  Section/subsection heading on the branded heading scale.

  `level` picks the element (`h2`/`h3`) and the `text-ops-h*` size so headings never
  reach for raw `text-lg`/`text-base`. (Page `<h1>` lives in `ops_page_header/1`.)
  """
  attr(:level, :integer, default: 2, values: [2, 3])
  attr(:id, :string, default: nil)
  attr(:class, :any, default: nil)
  slot(:inner_block, required: true)

  def ops_heading(assigns) do
    ~H"""
    <h2
      :if={@level == 2}
      id={@id}
      class={["text-ops-h2 font-semibold leading-ops-tight text-base-content", @class]}
    >
      {render_slot(@inner_block)}
    </h2>
    <h3
      :if={@level == 3}
      id={@id}
      class={["text-ops-h3 font-semibold leading-ops-tight text-base-content", @class]}
    >
      {render_slot(@inner_block)}
    </h3>
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
    <div class={["ops-panel p-ops-panel", @class]} {@rest}>
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

  @doc "Section wrapper for repeated operator screen blocks."
  attr(:title, :string, required: true)
  attr(:subtitle, :string, default: nil)
  attr(:meta, :string, default: nil)
  attr(:id, :string, default: nil)
  attr(:class, :any, default: nil)
  slot(:actions)
  slot(:inner_block, required: true)

  def ops_section(assigns) do
    assigns =
      assign_new(assigns, :heading_id, fn ->
        assigns.id || "ops-section-#{System.unique_integer([:positive])}"
      end)

    ~H"""
    <section aria-labelledby={@heading_id} class={["space-y-3", @class]}>
      <.ops_toolbar class="items-start gap-3">
        <div class="min-w-0 space-y-1">
          <h2 id={@heading_id} class="text-ops-h2 font-semibold leading-ops-tight text-base-content">
            {@title}
          </h2>
          <p :if={@subtitle} class="max-w-3xl text-sm text-base-content/75">{@subtitle}</p>
          <p :if={@meta} class="font-mono text-xs tabular-nums text-base-content/60">{@meta}</p>
        </div>
        <div :if={@actions != []} class="flex flex-wrap items-center justify-end gap-2">
          {render_slot(@actions)}
        </div>
      </.ops_toolbar>
      {render_slot(@inner_block)}
    </section>
    """
  end

  @doc "Responsive table wrapper for dense operator data."
  attr(:zebra, :boolean, default: false)
  attr(:class, :any, default: nil)
  attr(:table_class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def ops_table(assigns) do
    ~H"""
    <div class={["overflow-x-auto min-w-0", @class]} {@rest}>
      <table class={["table table-sm", @zebra && "table-zebra", @table_class]}>
        {render_slot(@inner_block)}
      </table>
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
    <button type={@type} class={[button_classes(@variant, @size), @class]} {@rest}>
      {render_slot(@inner_block)}
    </button>
    """
  end

  @doc "Link with the same visual contract as `ops_button/1`."
  attr(:navigate, :string, default: nil)
  attr(:href, :string, default: nil)

  attr(:variant, :atom,
    default: :default,
    values: [:default, :primary, :secondary, :danger, :ghost]
  )

  attr(:size, :atom, default: :sm, values: [:xs, :sm, :md])
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(target rel aria-label data-testid))
  slot(:inner_block, required: true)

  def ops_link_button(assigns) do
    ~H"""
    <.link navigate={@navigate} href={@href} class={[button_classes(@variant, @size), @class]} {@rest}>
      {render_slot(@inner_block)}
    </.link>
    """
  end

  @doc "Status or guidance notice with Scrypath operator styling."
  attr(:kind, :atom,
    default: :info,
    values: [:info, :success, :warning, :error, :partial, :running]
  )

  attr(:title, :string, default: nil)
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def ops_notice(assigns) do
    ~H"""
    <div
      class={[
        "rounded-ops-control border px-4 py-3 text-sm text-base-content",
        tone_class(@kind),
        @class
      ]}
      {@rest}
    >
      <p :if={@title} class="font-semibold">{@title}</p>
      <div class={[@title && "mt-1"]}>{render_slot(@inner_block)}</div>
    </div>
    """
  end

  @doc "Operator status surface for results, failures, and important workflow feedback."
  attr(:kind, :atom,
    default: :info,
    values: [:info, :success, :warning, :error, :partial, :running]
  )

  attr(:title, :string, required: true)
  attr(:role, :string, default: nil)
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:actions)
  slot(:inner_block, required: true)

  def ops_status(assigns) do
    ~H"""
    <div
      class={[
        "rounded-ops-control border px-4 py-3 text-sm text-base-content shadow-ops-surface",
        tone_class(@kind),
        @class
      ]}
      role={@role}
      {@rest}
    >
      <div class="flex flex-wrap items-start justify-between gap-3">
        <div class="min-w-0">
          <p class="font-semibold">{@title}</p>
          <div class="mt-1 text-base-content/80">{render_slot(@inner_block)}</div>
        </div>
        <div :if={@actions != []} class="flex flex-wrap gap-2">
          {render_slot(@actions)}
        </div>
      </div>
    </div>
    """
  end

  @doc "Small metric tile for rollups and status counts."
  attr(:label, :string, required: true)
  attr(:value, :any, required: true)
  attr(:kind, :atom, default: :neutral, values: [:neutral, :success, :warning, :error])

  def ops_metric(assigns) do
    ~H"""
    <div class={["ops-metric ops-muted-panel px-3 py-2", metric_tone_class(@kind)]}>
      <p class="text-xs font-semibold uppercase tracking-wide text-base-content/60">{@label}</p>
      <p class="mt-1 font-mono text-ops-lg font-semibold tabular-nums">{@value}</p>
    </div>
    """
  end

  @doc "Compact status badge for booleans, counts, and operator states."
  attr(:kind, :atom,
    default: :neutral,
    values: [:neutral, :info, :success, :warning, :error, :partial, :running]
  )

  attr(:class, :any, default: nil)
  slot(:inner_block, required: true)

  def ops_badge(assigns) do
    ~H"""
    <span class={["ops-badge", badge_class(@kind), @class]}>
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc """
  Trust-verdict hero — the branded answer to "can I trust search right now?".

  A large status headline + one-line evidence, tone routed through `kind`. The anchor of
  the Control Room landing; also used for the Posture summary and Sync Drift promotion
  readiness. Keep the headline short and honest (don't upgrade green past the evidence).
  """
  attr(:kind, :atom,
    default: :neutral,
    values: [:neutral, :info, :success, :warning, :error, :partial, :running]
  )

  attr(:headline, :string, required: true)
  attr(:label, :string, default: nil)
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:actions)
  slot(:inner_block)

  def ops_verdict(assigns) do
    ~H"""
    <div
      class={[
        "ops-verdict rounded-ops-surface border p-ops-panel",
        verdict_tone_class(@kind),
        @class
      ]}
      {@rest}
    >
      <div class="flex flex-wrap items-start justify-between gap-3">
        <div class="min-w-0 space-y-1">
          <p
            :if={@label}
            class="text-xs font-semibold uppercase tracking-wide text-base-content/55"
          >
            {@label}
          </p>
          <p class="flex items-center gap-2 text-ops-h2 font-semibold leading-ops-tight text-base-content">
            <span class="ops-verdict__dot" aria-hidden="true"></span>
            {@headline}
          </p>
          <div :if={@inner_block != []} class="text-sm text-base-content/75">
            {render_slot(@inner_block)}
          </div>
        </div>
        <div :if={@actions != []} class="flex flex-wrap items-center justify-end gap-2">
          {render_slot(@actions)}
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Operator workflow map for ScrypathOps.

  Group-aware (not a linear pipeline): a Control Room home chip, then the two task
  clusters that mirror `Nav` groups — Triage (posture → failed sync → sync drift) and
  Probe & capture (search → playbooks). `current` highlights the active surface.
  """
  attr(:current, :atom,
    required: true,
    values: [:control_room, :posture, :failed_sync, :sync_drift, :search, :playbooks]
  )

  attr(:mount_path, :string, required: true)
  attr(:class, :any, default: nil)

  def ops_journey(assigns) do
    assigns =
      assign(assigns, :groups, [
        %{
          label: "Triage",
          steps: [
            %{key: :posture, label: "Posture", path: "#{assigns.mount_path}/posture"},
            %{key: :failed_sync, label: "Failed Sync", path: "#{assigns.mount_path}/failed-sync"},
            %{key: :sync_drift, label: "Sync Drift", path: "#{assigns.mount_path}/sync-drift"}
          ]
        },
        %{
          label: "Probe & capture",
          steps: [
            %{key: :search, label: "Search", path: "#{assigns.mount_path}/search"},
            %{key: :playbooks, label: "Playbooks", path: "#{assigns.mount_path}/playbooks"}
          ]
        }
      ])

    ~H"""
    <nav aria-label="Operator workflow" class={["ops-surface-flat px-3 py-2", @class]}>
      <div class="ops-journey">
        <.link
          navigate={@mount_path}
          class={["ops-journey-home", @current == :control_room && "ops-journey-step-active"]}
          aria-current={if @current == :control_room, do: "page", else: nil}
        >
          <span aria-hidden="true">⌂</span> Control Room
        </.link>
        <span :for={{group, idx} <- Enum.with_index(@groups)} class="ops-journey-group">
          <span :if={idx > 0} class="ops-journey-divider" aria-hidden="true"></span>
          <span class="ops-journey-group-label">{group.label}</span>
          <.link
            :for={step <- group.steps}
            navigate={step.path}
            class={["ops-journey-step", step.key == @current && "ops-journey-step-active"]}
            aria-current={if step.key == @current, do: "step", else: nil}
          >
            {step.label}
          </.link>
        </span>
      </div>
    </nav>
    """
  end

  @doc """
  Intent task-card for the Control Room landing.

  The whole card is a single navigation target; `route_label` is the visible
  affordance. Composes the `.ops-*` surface layer so it inherits branded styling.
  """
  attr(:icon, :string, required: true)
  attr(:title, :string, required: true)
  attr(:summary, :string, required: true)
  attr(:route_label, :string, required: true)
  attr(:navigate, :string, required: true)
  attr(:kind, :atom, default: :neutral, values: [:neutral, :info, :success, :warning, :error])
  attr(:rest, :global, include: ~w(data-testid))

  def ops_intent_card(assigns) do
    ~H"""
    <.link
      navigate={@navigate}
      class={["ops-intent-card", @kind != :neutral && tone_class(@kind)]}
      {@rest}
    >
      <span class="ops-intent-card__icon" aria-hidden="true">{@icon}</span>
      <span class="ops-intent-card__title">{@title}</span>
      <span class="ops-intent-card__summary">{@summary}</span>
      <span class="ops-intent-card__cta">{@route_label} <span aria-hidden="true">→</span></span>
    </.link>
    """
  end

  @doc "Consistent empty/config state."
  attr(:title, :string, required: true)
  attr(:class, :any, default: nil)
  slot(:inner_block, required: true)

  def ops_empty_state(assigns) do
    ~H"""
    <div class={["ops-muted-panel p-5 text-sm", @class]}>
      <h2 class="text-ops-h3 font-semibold leading-ops-tight text-base-content">{@title}</h2>
      <div class="mt-2 text-base-content/75">{render_slot(@inner_block)}</div>
    </div>
    """
  end

  @doc "Shared shell for file-upload controls."
  attr(:label, :string, required: true)
  attr(:hint, :string, default: nil)
  attr(:class, :any, default: nil)
  slot(:inner_block, required: true)

  def ops_upload_box(assigns) do
    ~H"""
    <div class={["ops-surface-flat p-3", @class]}>
      <p class="text-sm font-semibold text-base-content">{@label}</p>
      <p :if={@hint} class="mt-1 text-xs leading-5 text-base-content/65">{@hint}</p>
      <div class="mt-3">{render_slot(@inner_block)}</div>
    </div>
    """
  end

  @doc "Canned configuration empty state for common OPSUI setup gaps."
  attr(:kind, :atom, required: true, values: [:no_schemas, :missing_backend])
  attr(:class, :any, default: nil)

  def ops_config_empty(assigns) do
    ~H"""
    <.ops_empty_state
      :if={@kind == :no_schemas}
      title="No Schemas Configured"
      class={@class}
    >
      Add allowlisted schema modules with
      <.ops_inline_code>schema_allowlist</.ops_inline_code>
      in
      <.ops_inline_code>:scrypath_ops</.ops_inline_code>
      or <.ops_inline_code>SCRYPATH_OPS_SCHEMAS</.ops_inline_code>. Then refresh this screen.
    </.ops_empty_state>
    <.ops_empty_state
      :if={@kind == :missing_backend}
      title="Runtime Not Configured"
      class={@class}
    >
      Configure
      <.ops_inline_code>:backend</.ops_inline_code>
      and the Scrypath runtime options under <.ops_inline_code>:scrypath_ops</.ops_inline_code>.
      This screen cannot query operator state until the runtime is wired.
    </.ops_empty_state>
    """
  end

  @doc "Fieldset wrapper for consistent operator form rhythm."
  attr(:legend, :string, required: true)
  attr(:hint, :string, default: nil)
  attr(:class, :any, default: nil)
  slot(:inner_block, required: true)

  def ops_fieldset(assigns) do
    ~H"""
    <fieldset class={["space-y-3 border-0 p-0 m-0 min-w-0", @class]}>
      <div class="space-y-1">
        <legend class="text-sm font-semibold text-base-content">{@legend}</legend>
        <p :if={@hint} class="max-w-3xl text-xs leading-5 text-base-content/70">{@hint}</p>
      </div>
      {render_slot(@inner_block)}
    </fieldset>
    """
  end

  @doc "Label/input wrapper with consistent vertical rhythm."
  attr(:id, :string, required: true)
  attr(:label, :string, required: true)
  attr(:hint, :string, default: nil)
  attr(:class, :any, default: nil)
  slot(:inner_block, required: true)

  def ops_field(assigns) do
    ~H"""
    <div class={["space-y-ops-field", @class]}>
      <label class="block text-sm font-semibold text-base-content/75" for={@id}>{@label}</label>
      {render_slot(@inner_block)}
      <p :if={@hint} class="text-xs leading-5 text-base-content/65">{@hint}</p>
    </div>
    """
  end

  @doc "Text input tuned to the operator control scale."
  attr(:id, :string, required: true)
  attr(:name, :string, required: true)
  attr(:value, :any, default: nil)
  attr(:placeholder, :string, default: nil)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(aria-describedby required disabled autocomplete))

  def ops_text_input(assigns) do
    ~H"""
    <input
      id={@id}
      name={@name}
      type="text"
      value={@value}
      placeholder={@placeholder}
      class={["input input-bordered ops-form-control w-full", @class]}
      {@rest}
    />
    """
  end

  @doc "Number input tuned to the operator control scale."
  attr(:id, :string, required: true)
  attr(:name, :string, required: true)
  attr(:value, :any, default: nil)
  attr(:min, :any, default: nil)
  attr(:max, :any, default: nil)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(aria-describedby required disabled))

  def ops_number_input(assigns) do
    ~H"""
    <input
      id={@id}
      name={@name}
      type="number"
      value={@value}
      min={@min}
      max={@max}
      class={["input input-bordered ops-form-control w-full", @class]}
      {@rest}
    />
    """
  end

  @doc "Textarea tuned to the operator control scale."
  attr(:id, :string, required: true)
  attr(:name, :string, required: true)
  attr(:value, :any, default: nil)
  attr(:placeholder, :string, default: nil)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(aria-describedby required disabled))

  def ops_textarea(assigns) do
    ~H"""
    <textarea
      id={@id}
      name={@name}
      placeholder={@placeholder}
      class={["textarea textarea-bordered min-h-24 w-full text-sm", @class]}
      {@rest}
    ><%= @value %></textarea>
    """
  end

  @doc "Select control tuned to the operator control scale."
  attr(:id, :string, required: true)
  attr(:name, :string, default: "schema")
  attr(:options, :list, required: true)
  attr(:selected, :any, default: nil)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(aria-describedby required disabled))

  def ops_select(assigns) do
    ~H"""
    <select
      id={@id}
      name={@name}
      class={["select select-bordered ops-form-control w-full", @class]}
      {@rest}
    >
      <option
        :for={{label, value} <- @options}
        value={value}
        selected={value == @selected}
      >
        {label}
      </option>
    </select>
    """
  end

  @doc "Schema selector for allowlisted schema modules."
  attr(:id, :string, required: true)
  attr(:label, :string, default: "Schema")
  attr(:hint, :string, default: nil)
  attr(:schemas, :list, required: true)
  attr(:selected, :any, default: nil)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(phx-change))

  def ops_schema_select(assigns) do
    assigns =
      assign(
        assigns,
        :options,
        Enum.map(assigns.schemas, &{module_flat_name(&1), module_flat_name(&1)})
      )

    ~H"""
    <form :if={@schemas != []} class={["max-w-xl", @class]} {@rest}>
      <.ops_field id={@id} label={@label} hint={@hint}>
        <.ops_select
          id={@id}
          name="schema"
          options={@options}
          selected={module_flat_name(@selected)}
          class="font-mono text-xs"
        />
      </.ops_field>
    </form>
    """
  end

  @doc "Segmented button control for mutually-exclusive modes."
  attr(:label, :string, required: true)
  attr(:selected, :string, required: true)
  attr(:event, :string, required: true)
  attr(:items, :list, required: true)
  attr(:class, :any, default: nil)

  def ops_segmented_control(assigns) do
    ~H"""
    <div class={["space-y-2", @class]}>
      <p class="text-sm font-semibold text-base-content">{@label}</p>
      <div class="inline-flex flex-wrap gap-1 rounded-ops-control border border-base-300 bg-base-200/70 p-1">
        <button
          :for={{label, value} <- @items}
          type="button"
          phx-click={@event}
          phx-value-mode={value}
          data-testid={if value == "multi", do: "search-mode-multi"}
          class={[
            "ops-segmented-btn ops-transition-status px-3 text-ops-body font-semibold",
            value == @selected && "bg-primary text-primary-content shadow-ops-mid",
            value != @selected && "text-base-content/75 hover:bg-base-100"
          ]}
        >
          {label}
        </button>
      </div>
    </div>
    """
  end

  @doc "Checkbox list with consistent schema/object selection spacing."
  attr(:name, :string, required: true)
  attr(:options, :list, required: true)
  attr(:selected, :list, default: [])
  attr(:class, :any, default: nil)

  def ops_checkbox_list(assigns) do
    ~H"""
    <div class={["ops-data-card p-3", @class]}>
      <label
        :for={{label, value} <- @options}
        class="flex min-h-9 cursor-pointer items-center gap-2 text-sm"
      >
        <input
          type="checkbox"
          name={@name}
          value={value}
          checked={value in @selected}
          class="checkbox checkbox-sm rounded"
        />
        <span class="min-w-0 font-mono text-xs">{label}</span>
      </label>
    </div>
    """
  end

  @doc "Consistent action grouping for table rows and toolbar action clusters."
  attr(:tone, :atom, default: :default, values: [:default, :advanced, :danger])
  attr(:class, :any, default: nil)
  slot(:inner_block, required: true)

  def ops_action_group(assigns) do
    ~H"""
    <div class={[
      "flex flex-wrap items-center gap-ops-control-gap",
      @tone == :advanced && ["rounded-ops-control border p-ops-2", tone_class(:warning)],
      @tone == :danger && ["rounded-ops-control border p-ops-2", tone_class(:error)],
      @class
    ]}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "Compact data card for result summaries, diagnostics, and repeated object rows."
  attr(:title, :string, default: nil)
  attr(:subtitle, :string, default: nil)
  attr(:class, :any, default: nil)
  slot(:actions)
  slot(:inner_block, required: true)

  def ops_data_card(assigns) do
    ~H"""
    <div class={["ops-data-card p-4 text-sm", @class]}>
      <div
        :if={@title || @subtitle || @actions != []}
        class="mb-3 flex flex-wrap items-start justify-between gap-3"
      >
        <div class="min-w-0">
          <p :if={@title} class="font-semibold text-base-content">{@title}</p>
          <p :if={@subtitle} class="mt-0.5 text-xs leading-5 text-base-content/65">{@subtitle}</p>
        </div>
        <div :if={@actions != []} class="flex flex-wrap gap-2">
          {render_slot(@actions)}
        </div>
      </div>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "Compact row for search/playbook result summaries with optional right-side actions."
  attr(:title, :string, required: true)
  attr(:subtitle, :string, default: nil)
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:meta)
  slot(:actions)
  slot(:inner_block)

  def ops_result_row(assigns) do
    ~H"""
    <article class={["ops-result-row text-sm", @class]} {@rest}>
      <div class="min-w-0">
        <h3 class="font-semibold text-base-content">{@title}</h3>
        <p :if={@subtitle} class="mt-1 text-xs leading-5 text-base-content/70">{@subtitle}</p>
        <div :if={@meta != []} class="mt-2 flex flex-wrap gap-2">
          {render_slot(@meta)}
        </div>
        <div :if={@inner_block != []} class="mt-3">
          {render_slot(@inner_block)}
        </div>
      </div>
      <div :if={@actions != []} class="flex flex-wrap justify-start gap-2 md:justify-end">
        {render_slot(@actions)}
      </div>
    </article>
    """
  end

  @doc "List wrapper for repeated operator objects such as saved playbooks."
  attr(:class, :any, default: nil)
  slot(:inner_block, required: true)

  def ops_object_list(assigns) do
    ~H"""
    <div class={["ops-object-list", @class]}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "Object-list row with consistent action alignment."
  attr(:active, :boolean, default: false)
  attr(:class, :any, default: nil)
  slot(:actions)
  slot(:inner_block, required: true)

  def ops_object_item(assigns) do
    ~H"""
    <div class={["ops-object-item", @active && "ops-object-item-active", @class]}>
      <div class="flex flex-wrap items-start justify-between gap-3">
        <div class="min-w-0 flex-1">{render_slot(@inner_block)}</div>
        <div :if={@actions != []} class="flex flex-wrap justify-end gap-2">
          {render_slot(@actions)}
        </div>
      </div>
    </div>
    """
  end

  @doc "Disclosure with consistent operator trace/debug styling."
  attr(:summary, :string, required: true)
  attr(:id, :string, default: nil)
  attr(:variant, :atom, default: :default, values: [:default, :compact])
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def ops_disclosure(assigns) do
    ~H"""
    <details
      id={@id}
      class={[
        "ops-disclosure",
        @variant == :compact && "ops-disclosure-compact",
        @class
      ]}
      {@rest}
    >
      <summary class="cursor-pointer text-sm font-medium text-base-content">
        {@summary}
      </summary>
      <div class="ops-disclosure-body mt-2 text-sm text-base-content/80">
        {render_slot(@inner_block)}
      </div>
    </details>
    """
  end

  @doc "Compact two-column signal table for status key/value data."
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def ops_signal_table(assigns) do
    ~H"""
    <.ops_table class={["ops-signal-table", @class]} {@rest}>
      {render_slot(@inner_block)}
    </.ops_table>
    """
  end

  @doc "Scrollable code/data block."
  attr(:variant, :atom, default: :default, values: [:default, :compact, :embedded])
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def ops_code_block(assigns) do
    ~H"""
    <pre
      class={[
        "overflow-auto rounded-md font-mono text-xs whitespace-pre-wrap break-words",
        @variant == :default && "max-h-96 bg-base-200 p-3",
        @variant == :compact && "max-h-48 bg-base-100 p-2",
        @variant == :embedded && "max-h-64 bg-base-100/70 p-3",
        @class
      ]}
      {@rest}
    >{render_slot(@inner_block)}</pre>
    """
  end

  @doc "Inline code text with consistent operator sizing."
  attr(:class, :any, default: nil)
  slot(:inner_block, required: true)

  def ops_inline_code(assigns) do
    ~H"""
    <code class={["font-mono text-xs tabular-nums", @class]}>{render_slot(@inner_block)}</code>
    """
  end

  @doc "Accessible modal shell for blocking file actions."
  attr(:title, :string, required: true)
  attr(:id, :string, required: true)
  attr(:cancel_event, :string, default: nil)
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
      phx-window-keydown={@cancel_event}
      phx-key={if @cancel_event, do: "escape", else: nil}
    >
      <div class={["modal-box relative rounded-ops-overlay", @class]} tabindex="-1">
        <button
          :if={@cancel_event}
          type="button"
          class="btn btn-circle btn-ghost btn-sm absolute right-3 top-3"
          phx-click={@cancel_event}
          aria-label="Close dialog"
          autofocus
        >
          <span aria-hidden="true">×</span>
        </button>
        <h3 id={"#{@id}-title"} class="text-ops-h2 font-semibold leading-ops-tight">{@title}</h3>
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

  @doc "Inline indicator for playbook workspace mode (examples read-only vs writable workspace)."
  attr(:mode, :atom, values: [:examples, :workspace], required: true)
  attr(:path, :string, default: nil)
  attr(:class, :any, default: nil)

  def ops_workspace_mode_indicator(assigns) do
    ~H"""
    <span class={["inline-flex flex-wrap items-center gap-1.5 text-xs", @class]}>
      <.ops_badge kind={if @mode == :examples, do: :warning, else: :neutral}>
        {if @mode == :examples, do: "Examples (read-only)", else: "Workspace"}
      </.ops_badge>
      <span
        :if={@path && @mode == :workspace}
        class="max-w-xs truncate font-mono text-xs text-base-content/55"
      >
        {@path}
      </span>
    </span>
    """
  end

  # Single source of truth for the button visual contract, shared by
  # `ops_button/1` and `ops_link_button/1`. Height + press feel live in `.ops-btn`;
  # radius is the `rounded-ops-control` utility so it wins over daisyUI's layer.
  defp button_classes(variant, size) do
    [
      "btn ops-btn rounded-ops-control",
      size == :xs && "btn-xs",
      size == :sm && "btn-sm",
      size == :md && "btn-md",
      variant == :primary && "btn-primary",
      variant == :secondary && "btn-secondary",
      variant == :danger && "btn-error",
      variant == :ghost && "btn-ghost",
      variant == :default && "btn-outline"
    ]
  end

  defp module_flat_name(nil), do: nil

  defp module_flat_name(mod) when is_atom(mod) do
    mod |> Atom.to_string() |> String.replace_prefix("Elixir.", "")
  end

  defp tone_class(:success), do: "ops-tone-success"
  defp tone_class(:warning), do: "ops-tone-warning"
  defp tone_class(:error), do: "ops-tone-error"
  defp tone_class(:partial), do: "ops-tone-partial"
  defp tone_class(:running), do: "ops-tone-running"
  defp tone_class(_), do: "ops-tone-info"

  # Metric tiles keep their muted-panel background and only accent the border by tone,
  # so they route through their own border-only modifiers (not the full tinted surface).
  defp metric_tone_class(:success), do: "ops-metric-success"
  defp metric_tone_class(:warning), do: "ops-metric-warning"
  defp metric_tone_class(:error), do: "ops-metric-error"
  defp metric_tone_class(_), do: nil

  # The verdict hero uses the full tinted surface for non-neutral states; neutral gets a
  # quiet muted surface (so "nothing to watch yet" never reads as info-blue).
  defp verdict_tone_class(:neutral), do: "ops-verdict-neutral"
  defp verdict_tone_class(kind), do: tone_class(kind)

  defp badge_class(:success), do: "ops-badge-success"
  defp badge_class(:warning), do: "ops-badge-warning"
  defp badge_class(:error), do: "ops-badge-error"
  defp badge_class(:partial), do: "ops-badge-partial"
  defp badge_class(:running), do: "ops-badge-running"
  defp badge_class(:info), do: "ops-badge-info"
  defp badge_class(_), do: "ops-badge-neutral"
end
