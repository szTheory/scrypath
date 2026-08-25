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
      <p class="ops-copper-eyebrow">
        Operator workspace
      </p>
      <h1
        id={@title_id}
        class="text-ops-h1 font-semibold leading-ops-tight tracking-normal text-base-content"
      >
        {@title}
      </h1>
      <p :if={@subtitle} class="max-w-3xl text-ops-body text-base-content/70">{@subtitle}</p>
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
          <p :if={@subtitle} class="max-w-3xl text-ops-body text-base-content/75">{@subtitle}</p>
          <p :if={@meta} class="font-mono text-ops-sm tabular-nums text-base-content/60">{@meta}</p>
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
    <div class={["ops-table-scroll overflow-x-auto min-w-0", @class]} {@rest}>
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
      ~w(phx-click phx-value-id phx-value-mode phx-value-name phx-value-schema phx-disable-with disabled data-testid data-ops-refresh aria-label)
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
        "ops-notice-surface",
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
        "ops-notice-surface ops-notice-surface--raised",
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

  attr(:kind, :atom,
    default: :neutral,
    values: [:neutral, :info, :success, :warning, :error, :partial, :running]
  )

  def ops_metric(assigns) do
    ~H"""
    <div class={["ops-metric ops-muted-panel px-3 py-2", metric_tone_class(@kind)]}>
      <p class="text-ops-sm font-semibold uppercase tracking-wide text-base-content/60">{@label}</p>
      <p class="mt-1 font-mono text-ops-lg font-semibold tabular-nums">{@value}</p>
    </div>
    """
  end

  @doc """
  Responsive grid wrapper for `ops_metric/1` tiles (and other rollup cards).

  `cols` is the column count at the `lg` breakpoint; every grid stacks to one column
  on mobile and two on `sm`, so metric rollups read consistently everywhere. Column
  classes are emitted as literals (`metric_grid_cols/1`) so Tailwind's source scan
  keeps them.
  """
  attr(:cols, :integer, default: 4, values: [3, 4, 5, 6])
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def ops_metric_grid(assigns) do
    ~H"""
    <div class={["grid gap-3", metric_grid_cols(@cols), @class]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Labelled tone chip — a compact `label : value` pill whose surface settles to a
  status tone. The single shared home for "this dimension matches / differs" style
  status rows (drift dimensions, per-reason flags) so tone branching stays out of
  templates and routes through the `tone_class/1` authority.
  """
  attr(:kind, :atom,
    default: :neutral,
    values: [:neutral, :info, :success, :warning, :error, :partial, :running]
  )

  attr(:label, :string, required: true)
  attr(:value, :string, default: nil)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  def ops_tone_chip(assigns) do
    ~H"""
    <div class={["ops-tone-chip", tone_chip_class(@kind), @class]} {@rest}>
      <span class="font-semibold">{@label}</span>
      <span :if={@value} class="ops-tone-chip__value">{@value}</span>
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
            class="text-ops-sm font-semibold uppercase tracking-wide text-base-content/55"
          >
            {@label}
          </p>
          <p class="flex items-center gap-2 text-ops-h2 font-semibold leading-ops-tight text-base-content">
            <span class="ops-verdict__dot" aria-hidden="true"></span>
            {@headline}
          </p>
          <div :if={@inner_block != []} class="text-ops-body text-base-content/75">
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
  Contextual breadcrumb trail for ScrypathOps surfaces.

  A short "where am I" trail — `Control Room › <group> › <page>` — not a map of the
  whole product (that's the header nav's job). Siblings are deliberately omitted; the
  group label (Triage / Explore) is context, not a link. Renders nothing on the
  Control Room landing (a breadcrumb that says "you are at the top" is noise).
  """
  attr(:current, :atom,
    required: true,
    values: [:control_room, :posture, :failed_sync, :sync_drift, :search, :playbooks]
  )

  attr(:mount_path, :string, required: true)
  attr(:class, :any, default: nil)

  def ops_trail(assigns) do
    assigns = assign(assigns, :trail, trail_for(assigns.current))

    ~H"""
    <nav :if={@trail} aria-label="Breadcrumb" class={["ops-trail", @class]}>
      <ol class="ops-trail__list">
        <li>
          <.link navigate={@mount_path} class="ops-trail__crumb ops-trail__link">
            Control Room
          </.link>
        </li>
        <li class="ops-trail__sep" aria-hidden="true">›</li>
        <li><span class="ops-trail__crumb ops-trail__group">{elem(@trail, 0)}</span></li>
        <li class="ops-trail__sep" aria-hidden="true">›</li>
        <li>
          <span class="ops-trail__crumb ops-trail__current" aria-current="page">
            {elem(@trail, 1)}
          </span>
        </li>
      </ol>
    </nav>
    """
  end

  defp trail_for(:posture), do: {"Recover", "Posture"}
  defp trail_for(:failed_sync), do: {"Recover", "Failed Sync"}
  defp trail_for(:sync_drift), do: {"Recover", "Sync Drift"}
  defp trail_for(:search), do: {"Explore", "Search"}
  defp trail_for(:playbooks), do: {"Explore", "Playbooks"}
  defp trail_for(_), do: nil

  @doc """
  Unified "Next step" page-footer handoff.

  Every triage/explore surface ends with the same affordance so operators learn that
  the bottom of the page tells them where to go next. One consistent grammar: an
  optional muted completion-condition, then an imperative link with a trailing arrow.
  Pass 1–2 `:step` slots (primary first) for branch points.
  """
  attr(:class, :any, default: nil)

  slot :step, required: true do
    attr(:navigate, :string, required: true)
    attr(:hint, :string, doc: "muted completion-condition shown before the link")
  end

  def ops_handoff(assigns) do
    ~H"""
    <nav aria-label="Next step" class={["ops-handoff", @class]}>
      <p class="ops-handoff__eyebrow">Next step</p>
      <div class="ops-handoff__steps">
        <div :for={step <- @step} class="ops-handoff__step">
          <span :if={step[:hint]} class="ops-handoff__hint">{step[:hint]}</span>
          <.link navigate={step.navigate} class="ops-handoff__link">
            {render_slot(step)} <span aria-hidden="true">→</span>
          </.link>
        </div>
      </div>
    </nav>
    """
  end

  @doc """
  Intent task-card for the Control Room landing.

  The whole card is a single navigation target; `route_label` is the visible
  affordance. Composes the `.ops-*` surface layer so it inherits branded styling.
  """
  attr(:icon, :string,
    required: true,
    doc: "a `hero-*` Heroicon name; rendered as a monoline mark, not an emoji"
  )

  attr(:title, :string, required: true)
  attr(:summary, :string, required: true)
  attr(:route_label, :string, required: true)
  attr(:navigate, :string, required: true)

  attr(:kind, :atom,
    default: :neutral,
    values: [:neutral, :info, :success, :warning, :error, :partial, :running]
  )

  attr(:recommended, :boolean,
    default: false,
    doc: "marks this card as the state-recommended next action (renders a 'Start here' flag)"
  )

  attr(:rest, :global, include: ~w(data-testid))

  def ops_intent_card(assigns) do
    ~H"""
    <.link
      navigate={@navigate}
      class={[
        "ops-intent-card",
        @kind != :neutral && tone_class(@kind),
        @recommended && "ops-intent-card--recommended"
      ]}
      {@rest}
    >
      <span :if={@recommended} class="ops-intent-card__flag">Start here</span>
      <span class="ops-intent-card__icon" aria-hidden="true">
        <ScrypathOpsWeb.CoreComponents.icon name={@icon} class="size-6" />
      </span>
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
    <div class={["ops-muted-panel p-ops-5 text-ops-body", @class]}>
      <h2 class="text-ops-h3 font-semibold leading-ops-tight text-base-content">{@title}</h2>
      <div class="mt-ops-2 text-base-content/75">{render_slot(@inner_block)}</div>
    </div>
    """
  end

  @doc """
  Restrained loading primitive for in-flight operator reads.

  `:bars` renders an opacity-pulsing skeleton (a stand-in for content that's loading);
  `:inline` is a compact pulsing "working…" label for buttons/status rows. Opacity-only
  and neutralized under reduced-motion (the global rule). Presentation-only — the screen
  owns when it's shown; wiring into specific reads (drift, search, swap) is Phase 125/126.
  """
  attr(:variant, :atom, default: :bars, values: [:bars, :inline])
  attr(:lines, :integer, default: 3)
  attr(:label, :string, default: "Loading…")
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  def ops_loading(assigns) do
    ~H"""
    <div
      :if={@variant == :bars}
      class={["ops-loading ops-loading__bars", @class]}
      role="status"
      aria-label={@label}
      {@rest}
    >
      <span :for={n <- 1..@lines} class="ops-loading__bar" style={loading_bar_width(n, @lines)}></span>
    </div>
    <span
      :if={@variant == :inline}
      class={["ops-loading inline-flex items-center gap-2 text-ops-sm text-base-content/65", @class]}
      role="status"
      {@rest}
    >
      {@label}
    </span>
    """
  end

  @doc "Shared shell for file-upload controls."
  attr(:label, :string, required: true)
  attr(:hint, :string, default: nil)
  attr(:class, :any, default: nil)
  slot(:inner_block, required: true)

  def ops_upload_box(assigns) do
    ~H"""
    <div class={["ops-surface-flat p-ops-3", @class]}>
      <p class="text-ops-body font-semibold text-base-content">{@label}</p>
      <p :if={@hint} class="mt-ops-1 text-ops-sm leading-5 text-base-content/65">{@hint}</p>
      <div class="mt-ops-3">{render_slot(@inner_block)}</div>
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
      title="No schemas configured"
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
      title="Runtime not configured"
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
        <legend class="text-ops-body font-semibold text-base-content">{@legend}</legend>
        <p :if={@hint} class="max-w-3xl text-ops-sm leading-5 text-base-content/70">{@hint}</p>
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
      <label class="block text-ops-body font-semibold text-base-content/75" for={@id}>{@label}</label>
      {render_slot(@inner_block)}
      <p :if={@hint} class="text-ops-sm leading-5 text-base-content/65">{@hint}</p>
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
      class={[
        "textarea textarea-bordered min-h-[var(--control-h-textarea)] w-full text-ops-body",
        @class
      ]}
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
          class="font-mono text-ops-sm"
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
      <p class="text-ops-body font-semibold text-base-content">{@label}</p>
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
    <div class={["ops-data-card p-ops-3", @class]}>
      <label
        :for={{label, value} <- @options}
        class="flex min-h-[var(--control-h-sm)] cursor-pointer items-center gap-2 text-ops-body"
      >
        <input
          type="checkbox"
          name={@name}
          value={value}
          checked={value in @selected}
          class="checkbox checkbox-sm rounded-ops-sm"
        />
        <span class="min-w-0 font-mono text-ops-sm">{label}</span>
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
    <div class={["ops-data-card p-ops-4 text-ops-body", @class]}>
      <div
        :if={@title || @subtitle || @actions != []}
        class="mb-3 flex flex-wrap items-start justify-between gap-3"
      >
        <div class="min-w-0">
          <p :if={@title} class="font-semibold text-base-content">{@title}</p>
          <p :if={@subtitle} class="mt-ops-1 text-ops-sm leading-5 text-base-content/65">{@subtitle}</p>
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
    <article class={["ops-result-row text-ops-body", @class]} {@rest}>
      <div class="min-w-0">
        <h3 class="font-semibold text-base-content">{@title}</h3>
        <p :if={@subtitle} class="mt-1 text-ops-sm leading-5 text-base-content/70">{@subtitle}</p>
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
  attr(:open, :boolean, default: false)
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def ops_disclosure(assigns) do
    ~H"""
    <details
      id={@id}
      open={@open}
      class={[
        "ops-disclosure",
        @variant == :compact && "ops-disclosure-compact",
        @class
      ]}
      {@rest}
    >
      <summary class="cursor-pointer text-ops-body font-medium text-base-content">
        {@summary}
      </summary>
      <div class="ops-disclosure-body mt-2 text-ops-body text-base-content/80">
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
  # Phase 133 (DARKMOTION-01): opt-in hover glint. Default false is load-bearing —
  # evidence code blocks (Failed Sync, search/merge payloads) must stay calm (D-04a/c).
  attr(:shimmer, :boolean, default: false)
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def ops_code_block(assigns) do
    ~H"""
    <pre
      class={[
        "overflow-auto rounded-ops-md font-mono text-ops-sm whitespace-pre-wrap break-words",
        @variant == :default && "max-h-96 bg-ops-surface-2 p-ops-3",
        @variant == :compact && "max-h-48 bg-base-100 p-ops-2",
        @variant == :embedded && "max-h-64 bg-base-100/70 p-ops-3",
        @shimmer && "ops-code-block--shimmer",
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
    <code class={["font-mono text-ops-sm tabular-nums", @class]}>{render_slot(@inner_block)}</code>
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
      <div
        class={["modal-box relative rounded-ops-overlay", @class]}
        tabindex="-1"
        phx-remove={
          Phoenix.LiveView.JS.transition(
            {"transition-all ease-ops-exit duration-200",
             "opacity-100 translate-y-0 scale-100",
             "opacity-0 translate-y-1 scale-[0.98]"},
            time: 120
          )
        }
      >
        <button
          :if={@cancel_event}
          type="button"
          class="btn btn-circle btn-ghost btn-sm absolute right-ops-3 top-ops-3"
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
  Operator command palette (⌘K / Ctrl-K) + keyboard cheat-sheet (`?`).

  Pure client-side: every item is a live-navigation link, so the palette needs no
  server event. The `CommandPalette` JS hook owns open/close, fuzzy filter, arrow
  navigation, `?` for the cheat-sheet, and `r` to click the page's `[data-ops-refresh]`
  control. Rendered once in the `:ops` shell so it is available on every surface.
  """
  attr(:mount_path, :string, required: true)

  def ops_command_palette(assigns) do
    assigns =
      assign(assigns, :items, [
        %{path: assigns.mount_path, label: "Control Room", hint: "Home · trust verdict"}
        | Enum.map(
            ScrypathOpsWeb.Nav.primary(assigns.mount_path),
            &%{path: &1.path, label: &1.label, hint: &1.title}
          )
      ])

    ~H"""
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
          <input
            type="text"
            class="ops-cmdk__input"
            placeholder="Jump to a surface…"
            aria-label="Search surfaces"
            autocomplete="off"
            spellcheck="false"
            data-cmdk-input
          />
          <ul class="ops-cmdk__list" role="listbox" aria-label="Surfaces">
            <li :for={item <- @items}>
              <.link
                navigate={item.path}
                class="ops-cmdk__item"
                role="option"
                data-cmdk-item
                data-cmdk-label={String.downcase("#{item.label} #{item.hint}")}
              >
                <span class="ops-cmdk__item-label">{item.label}</span>
                <span class="ops-cmdk__item-hint">{item.hint}</span>
              </.link>
            </li>
          </ul>
          <p class="ops-cmdk__empty" data-cmdk-empty hidden>No matching surface.</p>
        </div>
      </div>

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
            <div class="ops-cheatsheet__row">
              <dt><kbd class="ops-kbd">⌘</kbd> <kbd class="ops-kbd">K</kbd></dt>
              <dd>Jump to any surface</dd>
            </div>
            <div class="ops-cheatsheet__row">
              <dt><kbd class="ops-kbd">r</kbd></dt>
              <dd>Refresh this surface</dd>
            </div>
            <div class="ops-cheatsheet__row">
              <dt><kbd class="ops-kbd">?</kbd></dt>
              <dd>Show this cheat-sheet</dd>
            </div>
            <div class="ops-cheatsheet__row">
              <dt><kbd class="ops-kbd">Esc</kbd></dt>
              <dd>Close</dd>
            </div>
          </dl>
        </div>
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
    <span class={["inline-flex flex-wrap items-center gap-1.5 text-ops-sm", @class]}>
      <.ops_badge kind={if @mode == :examples, do: :warning, else: :neutral}>
        {if @mode == :examples, do: "Examples (read-only)", else: "Workspace"}
      </.ops_badge>
      <span
        :if={@path && @mode == :workspace}
        class="max-w-xs truncate font-mono text-ops-sm text-base-content/55"
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

  # Skeleton bars taper: the last line is short so the pulse reads as text, not a block.
  defp loading_bar_width(n, total) when n == total and total > 1, do: "width: 60%"
  defp loading_bar_width(_n, _total), do: "width: 100%"

  defp tone_class(:success), do: "ops-tone-success"
  defp tone_class(:warning), do: "ops-tone-warning"
  defp tone_class(:error), do: "ops-tone-error"
  defp tone_class(:partial), do: "ops-tone-partial"
  defp tone_class(:running), do: "ops-tone-running"
  defp tone_class(_), do: "ops-tone-info"

  # Literal column classes so Tailwind's source scan keeps them; mobile-first base.
  defp metric_grid_cols(3), do: "sm:grid-cols-2 lg:grid-cols-3"
  defp metric_grid_cols(5), do: "sm:grid-cols-2 lg:grid-cols-5"
  defp metric_grid_cols(6), do: "sm:grid-cols-2 lg:grid-cols-6"
  defp metric_grid_cols(_), do: "sm:grid-cols-2 lg:grid-cols-4"

  # Tone chips reuse the surface tones; :neutral stays a quiet muted panel (never blue).
  defp tone_chip_class(:neutral), do: "ops-muted-panel"
  defp tone_chip_class(kind), do: tone_class(kind)

  # Metric tiles keep their muted-panel background and only accent the border by tone,
  # so they route through their own border-only modifiers (not the full tinted surface).
  defp metric_tone_class(:success), do: "ops-metric-success"
  defp metric_tone_class(:warning), do: "ops-metric-warning"
  defp metric_tone_class(:error), do: "ops-metric-error"
  defp metric_tone_class(:info), do: "ops-metric-info"
  defp metric_tone_class(:partial), do: "ops-metric-partial"
  defp metric_tone_class(:running), do: "ops-metric-running"
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
