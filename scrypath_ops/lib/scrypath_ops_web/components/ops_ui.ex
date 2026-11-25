defmodule ScrypathOpsWeb.OpsUi do
  @moduledoc """
  Shared function components for `/ops` screens: page chrome, panels, and optional scaffold.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS
  import ScrypathOpsWeb.CoreComponents, only: [icon: 1]

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
      <h1
        id={@title_id}
        class="text-ops-h1 font-bold leading-ops-title tracking-ops-title text-base-content"
      >
        {@title}
      </h1>
      <p :if={@subtitle} class="max-w-3xl text-ops-body ops-muted">{@subtitle}</p>
    </div>
    """
  end

  @doc """
  Click/touch affordance for opening the operator command palette.

  The CommandPalette hook owns the behavior via `data-ops-command-open`; this component
  keeps visible shortcut hints from reading like inert text. The button has no `aria-label`:
  its accessible name comes from its visible text, so it always contains that text (WCAG 2.5.3).
  """
  attr(:class, :any, default: nil)

  def ops_command_hint(assigns) do
    ~H"""
    <button
      type="button"
      class={["ops-command-hint", @class]}
      data-ops-command-open
      aria-keyshortcuts="Meta+K Control+K"
    >
      <.icon name="hero-magnifying-glass" class="ops-command-hint__icon size-4" />
      <span>Go to…</span>
      <kbd class="ops-kbd">⌘K</kbd>
    </button>
    """
  end

  @doc """
  Section/subsection heading on the branded heading scale.

  `level` picks the element (`h2`/`h3`) and the `text-ops-h*` size so headings never
  reach for raw `text-lg`/`text-base`. (Page `<h1>` lives in `ops_page_header/1`.)
  """
  attr(:level, :integer, default: 2, values: [2, 3])
  attr(:id, :string, default: nil)
  attr(:tabindex, :integer, default: nil)
  attr(:class, :any, default: nil)
  slot(:inner_block, required: true)

  def ops_heading(assigns) do
    ~H"""
    <h2
      :if={@level == 2}
      id={@id}
      tabindex={@tabindex}
      class={["text-ops-h2 font-semibold leading-ops-tight text-base-content", @class]}
    >
      {render_slot(@inner_block)}
    </h2>
    <h3
      :if={@level == 3}
      id={@id}
      tabindex={@tabindex}
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
    <div class={["ops-panel p-ops-4 sm:p-ops-panel", @class]} {@rest}>
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
  attr(:prominent_title, :boolean, default: false)
  slot(:actions)
  slot(:metadata)
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
          <h2
            id={@heading_id}
            class={[
              if(@prominent_title, do: "text-ops-h1", else: "text-ops-h2"),
              "font-semibold leading-ops-tight text-base-content"
            ]}
          >
            {@title}
          </h2>
          <p :if={@subtitle} class="max-w-3xl text-ops-body ops-muted">{@subtitle}</p>
          <p :if={@meta} class="text-ops-sm tabular-nums ops-muted">{@meta}</p>
          <div :if={@metadata != []}>{render_slot(@metadata)}</div>
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
    values: [:default, :primary, :ghost]
  )

  attr(:size, :atom, default: :sm, values: [:xs, :sm, :md])
  attr(:type, :string, default: "button")
  attr(:id, :string, default: nil)
  attr(:class, :any, default: nil)

  attr(:rest, :global,
    include:
      ~w(phx-click phx-hook phx-value-id phx-value-source phx-value-mode phx-value-name phx-value-schema phx-disable-with disabled form data-testid data-ops-refresh data-ops-refresh-eligible data-ops-modal-trigger data-ops-state aria-label aria-controls)
  )

  slot(:inner_block, required: true)

  def ops_button(assigns) do
    ~H"""
    <button id={@id} type={@type} class={[button_classes(@variant, @size), @class]} {@rest}>
      {render_slot(@inner_block)}
    </button>
    """
  end

  @doc """
  Contextual refresh action for operator status screens.

  An outline button with two words and no glyph: `label` while idle and `busy_label` while the
  click is in flight. Both words are always rendered and the stylesheet swaps them on
  `[aria-busy="true"]`, which the `OpsRefreshButton` hook sets while LiveView marks the click as
  loading, so the width never changes and nothing animates. The server never sets `aria-busy`.
  """
  attr(:id, :string,
    required: true,
    doc: "Unique DOM id required by the LiveView refresh hook."
  )

  attr(:label, :string, default: "Refresh")
  attr(:busy_label, :string, default: "Refreshing…")
  attr(:aria_label, :string, required: true)
  attr(:disabled, :boolean, default: false)

  attr(:variant, :atom,
    default: :default,
    values: [:default, :primary, :ghost]
  )

  attr(:size, :atom, default: :sm, values: [:xs, :sm, :md])
  attr(:class, :any, default: nil)

  attr(:rest, :global,
    include:
      ~w(phx-click data-testid title phx-value-id phx-value-mode phx-value-name phx-value-schema)
  )

  def ops_refresh_button(assigns) do
    ~H"""
    <.ops_button
      id={@id}
      variant={@variant}
      size={@size}
      class={["ops-refresh-button", @class]}
      disabled={@disabled}
      data-ops-refresh-eligible={if @disabled, do: "false", else: "true"}
      data-ops-refresh
      phx-hook="OpsRefreshButton"
      aria-label={@aria_label}
      {@rest}
    >
      <span class="ops-refresh-button__words">
        <span data-ops-refresh-label="idle">{@label}</span>
        <span data-ops-refresh-label="busy">{@busy_label}</span>
      </span>
    </.ops_button>
    """
  end

  @doc "Refresh action paired with the time of the latest check."
  attr(:id, :string, required: true)
  attr(:checked_at, :any, default: nil)
  attr(:checked_label, :string, default: "Checked")
  attr(:label, :string, default: "Refresh")
  attr(:busy_label, :string, default: "Refreshing…")
  attr(:aria_label, :string, required: true)
  attr(:disabled, :boolean, default: false)

  attr(:variant, :atom,
    default: :default,
    values: [:default, :primary, :ghost]
  )

  attr(:size, :atom, default: :sm, values: [:xs, :sm, :md])
  attr(:class, :any, default: nil)

  attr(:rest, :global,
    include:
      ~w(phx-click data-testid title phx-value-id phx-value-mode phx-value-name phx-value-schema)
  )

  def ops_refresh_control(assigns) do
    ~H"""
    <div class={["flex flex-wrap items-center gap-x-3 gap-y-1", @class]}>
      <.ops_time :if={@checked_at} label={@checked_label} dt={@checked_at} />
      <.ops_refresh_button
        id={@id}
        label={@label}
        busy_label={@busy_label}
        aria_label={@aria_label}
        variant={@variant}
        size={@size}
        disabled={@disabled}
        {@rest}
      />
    </div>
    """
  end

  @doc "Link with the same visual contract as `ops_button/1`."
  attr(:navigate, :string, default: nil)
  attr(:href, :string, default: nil)

  attr(:variant, :atom,
    default: :default,
    values: [:default, :primary, :ghost]
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

  @doc """
  Status or guidance notice: a Panel with a 2px inline-start rule, never a tint.

  The kind picks the rule (and the title color): `:error` is Failed, `:warning` and `:partial` are
  Retrying amber, everything else (`:info`, `:success`, `:running`) is the neutral Control Edge
  rule. Plum is never an info color and green is only for Clear, so `:success` stays neutral.
  """
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
        notice_modifier(@kind),
        @class
      ]}
      {@rest}
    >
      <p :if={@title} class="ops-notice-surface__title font-semibold">{@title}</p>
      <div class={[@title && "mt-1"]}>{render_slot(@inner_block)}</div>
    </div>
    """
  end

  @doc """
  Operator status surface for results, failures, and important workflow feedback.

  Same surface and rule scheme as `ops_notice/1`; `data-status-kind` keeps the kind readable. The
  `neutral` attr is accepted for existing call sites and no longer changes the surface: the kind
  already decides the rule, so an error stays Failed and a success stays a neutral rule.
  """
  attr(:kind, :atom,
    default: :info,
    values: [:neutral, :info, :success, :warning, :error, :partial, :running]
  )

  attr(:title, :string, required: true)
  attr(:role, :string, default: nil)
  attr(:neutral, :boolean, default: false)
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:actions)
  slot(:inner_block, required: true)

  def ops_status(assigns) do
    ~H"""
    <div
      class={[
        "ops-notice-surface",
        notice_modifier(@kind),
        @class
      ]}
      data-status-kind={@kind}
      role={@role}
      {@rest}
    >
      <div class="flex flex-wrap items-start justify-between gap-3">
        <div class="ops-notice-surface__copy min-w-0">
          <p class="ops-notice-surface__title font-semibold">
            {@title}
          </p>
          <div class="ops-notice-surface__body mt-1">
            {render_slot(@inner_block)}
          </div>
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
    <div class="ops-metric ops-muted-panel px-3 py-2" data-ops-metric-tone={@kind}>
      <p class="ops-metric__label text-ops-sm font-semibold tracking-ops-label">{@label}</p>
      <p class={[
        "ops-metric__value mt-1 font-mono text-ops-lg tabular-nums",
        metric_value_class(@kind)
      ]}>
        {@value}
      </p>
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
  Labelled tone chip: a compact `label : value` row on the same Panel-with-a-rule surface as a
  notice. The single shared home for "this dimension matches / differs" style status rows (drift
  dimensions, per-reason flags) so tone branching stays out of templates and routes through the
  `notice_modifier/1` authority.
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
    <div class={["ops-tone-chip ops-notice-surface", notice_modifier(@kind), @class]} {@rest}>
      <span class="font-semibold">{@label}</span>
      <span :if={@value} class="ops-tone-chip__value">{@value}</span>
    </div>
    """
  end

  @doc """
  Plain muted label for a non-sync fact (for example the Search run state).

  It is text, not a pill: no border, no tint, no color of its own. Sync states never use it; they
  render through `ops_sync_status/1` and `ops_condition/1`. `kind` stays readable as
  `data-badge-kind` and has no visual effect.
  """
  attr(:kind, :atom,
    default: :neutral,
    values: [:neutral, :info, :success, :warning, :error, :partial, :running]
  )

  attr(:class, :any, default: nil)
  slot(:inner_block, required: true)

  def ops_badge(assigns) do
    ~H"""
    <span class={["ops-badge", @class]} data-badge-kind={@kind}>
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc """
  The one sync-status vocabulary: a word first, then a 16 px bar icon.

  `status` is one of `:failed`, `:retrying`, `:pending` or `:clear`. The word is the accessible
  text; the icon is decoration, so it carries no role and no name and never appears without its
  word. The four icons differ by shape (`data-shape` is `notched`, `bottom-filled`, `hollow` or
  `filled`), so the status reads without color. Word and icon take their color from
  `--ops-status-<status>` through `currentColor`.

  Words and shapes come from a private table, never from the input, and the attr rejects any
  other atom at compile time. `Clear` is only for an observed-clear source; callers that did not
  observe something must render an `ops_condition/1` word instead.
  """
  attr(:status, :atom, required: true, values: [:failed, :retrying, :pending, :clear])
  attr(:class, :any, default: nil)

  def ops_sync_status(assigns) do
    {shape, word, path} = sync_status_shape(assigns.status)
    assigns = assign(assigns, shape: shape, word: word, path: path)

    ~H"""
    <span class={["ops-sync-status", @class]} data-sync-status={@status}>
      <span class="ops-sync-status__word">{@word}</span>
      <svg
        class="ops-sync-status__icon"
        data-shape={@shape}
        aria-hidden="true"
        focusable="false"
        width="8.63"
        height="16"
        viewBox="0 0 8.63 16"
        fill="currentColor"
        fill-rule="evenodd"
      >
        <path d={@path} />
      </svg>
    </span>
    """
  end

  @doc """
  A condition word: plain muted text that says what was not looked at. Never a status.

  The closed set is `Not observed`, `Not checked`, `Queue not used` and `Unavailable`. A
  condition carries no icon and no color of its own, so an unobserved source can never read as
  healthy or as failed; `Clear` needs an observation and is rendered by `ops_sync_status/1`.
  """
  attr(:word, :string,
    required: true,
    values: ["Not observed", "Not checked", "Queue not used", "Unavailable"]
  )

  attr(:class, :any, default: nil)

  def ops_condition(assigns) do
    ~H"""
    <span class={["ops-condition", @class]} data-condition={@word}>{@word}</span>
    """
  end

  @doc """
  Trust-verdict hero — the branded answer to "can I trust search right now?".

  A large status headline + one-line evidence, tone routed through `kind`. The anchor of
  the Control room landing; also used for the Search health summary and Sync and index promotion
  readiness. Keep the headline short and honest (don't upgrade green past the evidence).
  """
  attr(:kind, :atom,
    default: :neutral,
    values: [:neutral, :info, :success, :warning, :error, :partial, :running]
  )

  attr(:headline, :string, required: true)
  attr(:headline_id, :string, default: nil, doc: "id for labelling the surrounding section")

  attr(:status, :atom,
    default: nil,
    values: [nil, :failed, :retrying, :pending, :clear],
    doc: "worst sync status, rendered by `ops_sync_status/1` before the headline"
  )

  attr(:label, :string, default: nil)
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:actions)
  slot(:inner_block)

  def ops_verdict(assigns) do
    ~H"""
    <div
      class={[
        "ops-verdict ops-notice-surface rounded-ops-surface p-ops-panel",
        notice_modifier(@kind),
        @class
      ]}
      data-verdict-kind={@kind}
      {@rest}
    >
      <div class="flex flex-col gap-3 md:flex-row md:items-start md:justify-between">
        <div class="min-w-0 flex-1 space-y-1">
          <p
            :if={@label}
            class="ops-verdict__label text-ops-sm font-semibold tracking-ops-label"
          >
            {@label}
          </p>
          <p
            id={@headline_id}
            class="flex items-center gap-2 text-ops-h2 font-semibold leading-ops-tight text-base-content"
          >
            <.ops_sync_status :if={@status} status={@status} />
            {@headline}
          </p>
          <div :if={@inner_block != []} class="text-ops-body ops-muted">
            {render_slot(@inner_block)}
          </div>
        </div>
        <div
          :if={@actions != []}
          class="flex shrink-0 flex-wrap items-center justify-start gap-2 md:justify-end"
        >
          {render_slot(@actions)}
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Contextual breadcrumb trail for ScrypathOps screens.

  A short context trail — `<group> › <page>` — not a map of the whole product (that's
  the primary shell nav's job). Siblings are deliberately omitted; the group label
  (Recover / Explore) is context, not a link. Renders nothing on the Control room
  landing (a breadcrumb that says "you are at the top" is noise).
  """
  attr(:current, :atom,
    required: true,
    values: [:control_room, :posture, :failed_sync, :sync_and_index, :search]
  )

  attr(:class, :any, default: nil)

  def ops_trail(assigns) do
    assigns = assign(assigns, :trail, trail_for(assigns.current))

    ~H"""
    <nav :if={@trail} aria-label="Breadcrumb" class={["ops-trail", @class]}>
      <ol class="ops-trail__list">
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

  defp trail_for(_), do: nil

  @doc """
  Unified "Next step" page-footer handoff.

  Every triage/explore screen ends with the same affordance so operators learn that
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
  Intent task-card for the Control room landing.

  The whole card is a single navigation target; `route_label` is the visible
  affordance. Composes the `.ops-*` surface layer so it inherits branded styling.
  It carries words only: no icon and no "Start here" flag.
  """
  attr(:title, :string, required: true)
  attr(:summary, :string, required: true)
  attr(:route_label, :string, required: true)
  attr(:navigate, :string, required: true)
  attr(:rest, :global, include: ~w(data-testid))
  slot(:badge)

  def ops_intent_card(assigns) do
    ~H"""
    <.link navigate={@navigate} class="ops-intent-card" {@rest}>
      <span :if={@badge != []} class="ops-intent-card__badges">
        {render_slot(@badge)}
      </span>
      <span class="ops-intent-card__title">{@title}</span>
      <span class="ops-intent-card__summary">{@summary}</span>
      <span class="ops-intent-card__cta" aria-hidden="true">→</span>
    </.link>
    """
  end

  @doc "Consistent empty/config state."
  attr(:title, :string, required: true)
  attr(:class, :any, default: nil)
  slot(:actions)
  slot(:inner_block, required: true)

  def ops_empty_state(assigns) do
    ~H"""
    <div class={["ops-muted-panel p-ops-5 text-ops-body", @class]}>
      <h2 class="text-ops-h3 font-semibold leading-ops-tight text-base-content">{@title}</h2>
      <div class="mt-ops-2 ops-muted">{render_slot(@inner_block)}</div>
      <div :if={@actions != []} class="mt-ops-4 flex flex-wrap gap-2">
        {render_slot(@actions)}
      </div>
    </div>
    """
  end

  @doc "Hero-style empty state for high-attention blank sections."
  attr(:id, :string, default: nil)
  attr(:title, :string, required: true)
  attr(:heading_level, :integer, default: 3, values: [2, 3])
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:actions)
  slot(:inner_block, required: true)

  def ops_empty_hero(assigns) do
    assigns =
      assign_new(assigns, :heading_id, fn ->
        if assigns.id,
          do: "#{assigns.id}-heading",
          else: "ops-empty-hero-heading-#{System.unique_integer([:positive])}"
      end)

    ~H"""
    <div
      id={@id}
      class={["ops-empty-hero", @class]}
      aria-labelledby={@heading_id}
      {@rest}
    >
      <div class="ops-empty-hero__copy">
        <h2
          :if={@heading_level == 2}
          id={@heading_id}
          class="ops-empty-hero__title text-ops-h2 font-semibold leading-ops-tight text-base-content"
        >
          {@title}
        </h2>
        <h3
          :if={@heading_level == 3}
          id={@heading_id}
          class="ops-empty-hero__title text-ops-h3 font-semibold leading-ops-tight text-base-content"
        >
          {@title}
        </h3>
        <div class="ops-empty-hero__body">{render_slot(@inner_block)}</div>
      </div>
      <div :if={@actions != []} class="ops-empty-hero__actions">
        {render_slot(@actions)}
      </div>
    </div>
    """
  end

  @doc """
  Restrained loading primitive for in-flight operator reads.

  Loading is said in a word: `label` is always visible, in a `role="status"` node that never
  carries `aria-busy`. `aria-busy` on a live region (or on anything that contains one) asks
  assistive technology to hold what it says until the busy state clears, and this word is removed
  when loading ends, so it would never be released. Instead `:bars` marks the skeleton lines, the
  stand-in for the content that is loading, as the busy region (`aria-busy="true"` on a sibling of
  the word, never an ancestor of it). Nothing animates. The lines are static Sunken blocks, the
  last one short. `:inline` is just the word, for buttons and status rows; nothing is being
  replaced there, so it has no busy region. A screen that keeps earlier content on show while it
  reloads marks that content `aria-busy` itself, and keeps it apart from the word. Presentation-only:
  the screen owns when it is shown.
  """
  attr(:variant, :atom, default: :bars, values: [:bars, :inline])
  attr(:lines, :integer, default: 3)
  attr(:label, :string, default: "Loading…")
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  def ops_loading(assigns) do
    ~H"""
    <div :if={@variant == :bars} class={["ops-loading ops-loading__bars", @class]} {@rest}>
      <p class="ops-loading__label" role="status">{@label}</p>
      <div class="grid gap-ops-2" aria-busy="true">
        <span
          :for={n <- 1..@lines}
          class={[
            "ops-loading__bar",
            if(n == @lines and @lines > 1, do: "ops-loading__bar--short")
          ]}
          aria-hidden="true"
        >
        </span>
      </div>
    </div>
    <span
      :if={@variant == :inline}
      class={["ops-loading inline-flex items-center gap-2 text-ops-sm ops-muted", @class]}
      role="status"
      {@rest}
    >
      {@label}
    </span>
    """
  end

  @doc "Shared shell for file-upload controls."
  attr(:label, :string, required: true)
  attr(:control_id, :string, default: nil)
  attr(:hint, :string, default: nil)
  attr(:class, :any, default: nil)
  slot(:inner_block, required: true)

  def ops_upload_box(assigns) do
    ~H"""
    <div class={["ops-surface-flat p-ops-3", @class]}>
      <label
        :if={@control_id}
        for={@control_id}
        class="block text-ops-body font-semibold text-base-content"
      >
        {@label}
      </label>
      <p :if={!@control_id} class="text-ops-body font-semibold text-base-content">{@label}</p>
      <p
        :if={@hint}
        id={@control_id && "#{@control_id}-hint"}
        class="mt-ops-1 text-ops-sm leading-5 ops-muted"
      >
        {@hint}
      </p>
      <div class="mt-ops-3">{render_slot(@inner_block)}</div>
    </div>
    """
  end

  @doc "Canned configuration empty state for common OPSUI setup gaps."
  attr(:kind, :atom, required: true, values: [:no_schemas, :missing_backend])
  attr(:class, :any, default: nil)
  slot(:actions)

  def ops_config_empty(assigns) do
    ~H"""
    <.ops_empty_state
      :if={@kind == :no_schemas}
      title="No search schemas configured"
      class={@class}
    >
      Configure the host application's schema allowlist to inspect search health.
      <:actions :for={action <- @actions}>
        {render_slot(action)}
      </:actions>
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
      <:actions :for={action <- @actions}>
        {render_slot(action)}
      </:actions>
    </.ops_empty_state>
    """
  end

  @doc "Fieldset wrapper for consistent operator form rhythm."
  attr(:legend, :string, required: true)
  attr(:hint, :string, default: nil)
  attr(:disabled, :boolean, default: false)
  attr(:class, :any, default: nil)
  slot(:inner_block, required: true)

  def ops_fieldset(assigns) do
    ~H"""
    <fieldset class={["ops-fieldset", @class]} disabled={@disabled}>
      <legend class="ops-fieldset__legend">{@legend}</legend>
      <p :if={@hint} class="ops-fieldset__hint">{@hint}</p>
      <div class="ops-fieldset__body">
        {render_slot(@inner_block)}
      </div>
    </fieldset>
    """
  end

  @doc "Label/input wrapper with consistent vertical rhythm."
  attr(:id, :string, required: true)
  attr(:label, :string, required: true)
  attr(:hint, :string, default: nil)
  attr(:error, :string, default: nil)
  attr(:class, :any, default: nil)
  slot(:inner_block, required: true)

  def ops_field(assigns) do
    ~H"""
    <div id={"#{@id}-field"} phx-hook="OpsFieldValidation" class={["space-y-ops-field", @class]}>
      <label class="block text-ops-body font-semibold ops-muted" for={@id}>{@label}</label>
      {render_slot(@inner_block)}
      <p :if={@hint} id={"#{@id}-hint"} class="text-ops-body leading-5 ops-muted">
        {@hint}
      </p>
      <p
        id={"#{@id}-error"}
        class="ops-field-error text-ops-body leading-5 text-error"
        role={if @error, do: "alert"}
        hidden={!@error}
        data-ops-field-error
        data-server-error={@error}
      >
        {@error}
      </p>
    </div>
    """
  end

  @doc "Text input tuned to the operator control scale."
  attr(:id, :string, required: true)
  attr(:name, :string, required: true)
  attr(:value, :any, default: nil)
  attr(:placeholder, :string, default: nil)
  attr(:hint, :string, default: nil)
  attr(:error, :string, default: nil)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(aria-describedby required disabled autocomplete))

  def ops_text_input(assigns) do
    assigns = assign(assigns, :describedby, field_descriptions(assigns))

    ~H"""
    <input
      id={@id}
      name={@name}
      type="text"
      data-ops-validate
      value={@value}
      placeholder={@placeholder}
      aria-describedby={@describedby}
      aria-invalid={@error && "true"}
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
  attr(:hint, :string, default: nil)
  attr(:error, :string, default: nil)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(aria-describedby required disabled))

  def ops_number_input(assigns) do
    assigns = assign(assigns, :describedby, field_descriptions(assigns))

    ~H"""
    <input
      id={@id}
      name={@name}
      type="number"
      data-ops-validate
      value={@value}
      min={@min}
      max={@max}
      aria-describedby={@describedby}
      aria-invalid={@error && "true"}
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
  attr(:hint, :string, default: nil)
  attr(:error, :string, default: nil)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(aria-describedby required disabled))

  def ops_textarea(assigns) do
    assigns = assign(assigns, :describedby, field_descriptions(assigns))

    ~H"""
    <textarea
      id={@id}
      name={@name}
      data-ops-validate
      placeholder={@placeholder}
      aria-describedby={@describedby}
      aria-invalid={@error && "true"}
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
  attr(:hint, :string, default: nil)
  attr(:error, :string, default: nil)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(aria-describedby required disabled))

  def ops_select(assigns) do
    assigns = assign(assigns, :describedby, field_descriptions(assigns))

    ~H"""
    <select
      id={@id}
      name={@name}
      aria-describedby={@describedby}
      aria-invalid={@error && "true"}
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
  attr(:name, :string, default: "schema")
  attr(:error, :string, default: nil)
  attr(:disabled, :boolean, default: false)
  attr(:schemas, :list, required: true)
  attr(:selected, :any, default: nil)
  attr(:multiple, :boolean, default: false)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(phx-change))

  def ops_schema_select(assigns) do
    schema_items =
      if assigns.multiple do
        Enum.map(assigns.schemas, fn schema ->
          hd(schema_picker_items([schema], if(schema in List.wrap(assigns.selected), do: schema)))
        end)
      else
        schema_picker_items(assigns.schemas, assigns.selected)
      end

    single_schema_item =
      if !assigns.multiple && length(schema_items) == 1 && hd(schema_items).selected,
        do: hd(schema_items)

    assigns =
      assigns
      |> assign(:schema_items, schema_items)
      |> assign(:single_schema_item, single_schema_item)
      |> assign(:description_ids, schema_descriptions(assigns))

    ~H"""
    <div :if={@schemas != []} class={["ops-schema-picker", @class]} {@rest}>
      <fieldset class="space-y-ops-field" disabled={@disabled}>
        <legend class="block text-ops-body font-semibold ops-muted">{@label}</legend>
        <p :if={@hint} id={"#{@id}-hint"} class="max-w-3xl text-ops-sm leading-5 ops-muted">
          {@hint}
        </p>
        <p :if={@error} id={"#{@id}-error"} class="text-ops-sm text-error" role="alert">
          {@error}
        </p>

        <div :if={@single_schema_item} class="ops-schema-picker__single">
          <input type="hidden" name={@name} value={@single_schema_item.name} />
          <span class="ops-schema-picker__name">{@single_schema_item.short_name}</span>
          <span
            :if={@single_schema_item.name != @single_schema_item.short_name}
            class="ops-schema-picker__module-name"
          >
            {@single_schema_item.name}
          </span>
        </div>

        <div :if={is_nil(@single_schema_item)} class="ops-schema-picker__options max-w-xl">
          <label
            :for={item <- @schema_items}
            for={"#{@id}-#{item.dom_id}"}
            class={[
              "ops-schema-picker__option",
              item.selected && "ops-schema-picker__option--selected"
            ]}
          >
            <input
              id={"#{@id}-#{item.dom_id}"}
              type={if @multiple, do: "checkbox", else: "radio"}
              name={@name}
              value={item.name}
              checked={item.selected}
              class="ops-schema-picker__radio"
              aria-describedby={@description_ids}
              aria-invalid={@error && "true"}
            />
            <span class="ops-schema-picker__choice-copy">
              <span class="ops-schema-picker__name">{item.short_name}</span>
              <span :if={item.name != item.short_name} class="ops-schema-picker__module-name">
                {item.name}
              </span>
            </span>
          </label>
        </div>
      </fieldset>
    </div>
    """
  end

  @doc "Segmented button control for mutually-exclusive modes."
  attr(:label, :string, required: true)
  attr(:selected, :string, required: true)
  attr(:event, :string, required: true)
  attr(:items, :list, required: true)
  attr(:class, :any, default: nil)
  attr(:disabled, :boolean, default: false)

  def ops_segmented_control(assigns) do
    ~H"""
    <div class={["space-y-2", @class]}>
      <p id="search-mode-label" class="text-ops-body font-semibold text-base-content">{@label}</p>
      <div
        role="group"
        aria-label={@label}
        class="ops-segmented-group"
      >
        <button
          :for={{label, value} <- @items}
          type="button"
          phx-click={@event}
          phx-value-mode={value}
          aria-pressed={if(value == @selected, do: "true", else: "false")}
          disabled={@disabled}
          data-testid={if value == "multi", do: "search-mode-multi"}
          class={[
            "ops-segmented-btn ops-transition-status px-3 text-ops-body font-semibold",
            value != @selected && "ops-muted"
          ]}
        >
          {label}
        </button>
      </div>
    </div>
    """
  end

  defp field_descriptions(assigns) do
    rest = Map.get(assigns, :rest, %{})
    existing = Map.get(rest, :"aria-describedby") || Map.get(rest, :aria_describedby)

    [existing, assigns.hint && "#{assigns.id}-hint", assigns.error && "#{assigns.id}-error"]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.flat_map(&String.split(to_string(&1)))
    |> Enum.uniq()
    |> case do
      [] -> nil
      ids -> Enum.join(ids, " ")
    end
  end

  defp schema_descriptions(assigns) do
    [assigns.hint && "#{assigns.id}-hint", assigns.error && "#{assigns.id}-error"]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" ")
    |> case do
      "" -> nil
      ids -> ids
    end
  end

  @doc "Checkbox list with consistent schema/object selection spacing."
  attr(:name, :string, required: true)
  attr(:options, :list, required: true)
  attr(:selected, :list, default: [])
  attr(:class, :any, default: nil)

  def ops_checkbox_list(assigns) do
    ~H"""
    <div class={["space-y-ops-2", @class]}>
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
  attr(:tone, :atom, default: :default, values: [:default, :secondary, :advanced])
  attr(:class, :any, default: nil)
  slot(:inner_block, required: true)

  def ops_action_group(assigns) do
    ~H"""
    <div
      class={["ops-action-group flex flex-wrap items-center gap-ops-control-gap", @class]}
      data-action-tone={@tone}
    >
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
          <p :if={@subtitle} class="mt-ops-1 text-ops-sm leading-5 ops-muted">
            {@subtitle}
          </p>
        </div>
        <div :if={@actions != []} class="flex flex-wrap gap-2">
          {render_slot(@actions)}
        </div>
      </div>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "Compact row for search and saved search result summaries with optional right-side actions."
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
        <h3 class="text-ops-h3 font-semibold text-base-content">{@title}</h3>
        <p :if={@subtitle} class="mt-1 text-ops-sm leading-5 ops-muted">{@subtitle}</p>
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

  @doc "Time metadata with a shared UTC/local display preference and exact-source clipboard feedback."
  attr(:id, :string, default: nil)
  attr(:dt, :any, default: nil)
  attr(:snapshot_at, :any, default: nil)
  attr(:source_iso, :string, default: nil)
  attr(:label, :string, default: nil)
  attr(:state_text, :string, default: "No success observed")
  attr(:retained_text, :string, default: nil)
  attr(:operational, :boolean, default: false)
  attr(:copy, :boolean, default: false)

  attr(:copyable, :boolean,
    default: true,
    doc:
      "`false` renders the exact time as plain mono text with no copy button, for a summary line that repeats a time already offered once with its copy control (one copy control per exact value)."
  )

  attr(:class, :any, default: nil)

  def ops_time(assigns) do
    exact = exact_dt(assigns.dt, assigns.source_iso)

    assigns =
      assigns
      |> assign(:exact, exact)
      |> assign(:human, if(exact, do: utc_absolute(assigns.dt), else: assigns.state_text))
      |> assign(:age, if(exact, do: human_dt(assigns.dt, assigns.snapshot_at), else: nil))
      |> assign(:time_id, assigns.id || "ops-time-#{System.unique_integer([:positive])}")

    ~H"""
    <span id={@time_id} class={["ops-time", @class]} phx-hook="OpsTimestampCopy">
      <span :if={@label && @label != ""} class="ops-time__label">{@label}</span>
      <%= if @exact && @copyable do %>
        <button
          type="button"
          class="ops-time__stamp"
          data-ops-timestamp-copy={@exact}
          title={"#{@age} · #{@exact} · Click to copy"}
        >
          <time class="ops-time__value" datetime={@exact} data-ops-time-value>{@human}</time>
          <span class="sr-only">, copy timestamp</span>
          <ScrypathOpsWeb.CoreComponents.icon
            name="hero-clipboard-document"
            class="ops-time__affordance size-3.5"
          />
        </button>
      <% else %>
        <%= if @exact do %>
          <time class="ops-time__value" datetime={@exact} data-ops-time-value>{@human}</time>
        <% else %>
          <span class="ops-time__value">{@human}</span>
        <% end %>
      <% end %>
      <span :if={@retained_text} class="ops-time__retained">{@retained_text}</span>
    </span>
    """
  end

  @doc "List wrapper for repeated operator objects such as saved searches."
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
  attr(:id, :string, default: nil)
  attr(:class, :any, default: nil)
  slot(:actions)
  slot(:inner_block, required: true)

  def ops_object_item(assigns) do
    ~H"""
    <div
      id={@id}
      aria-current={if(@active, do: "true")}
      class={["ops-object-item", @active && "ops-object-item-active", @class]}
    >
      <div class="flex flex-col items-start justify-between gap-3 sm:flex-row">
        <div class="min-w-0 w-full flex-1">{render_slot(@inner_block)}</div>
        <div :if={@actions != []} class="flex flex-wrap gap-2 sm:justify-end">
          {render_slot(@actions)}
        </div>
      </div>
    </div>
    """
  end

  @doc "Disclosure with consistent operator trace/debug styling."
  attr(:summary, :string, required: true)
  attr(:id, :string, default: nil)
  attr(:summary_id, :string, default: nil)
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
      <summary
        id={@summary_id}
        class="cursor-pointer text-ops-body font-semibold text-base-content"
      >
        {@summary}
      </summary>
      <div class="ops-disclosure-body mt-2 text-ops-body text-base-content">
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
  attr(:label, :string, default: "Technical details")
  attr(:variant, :atom, default: :default, values: [:default, :compact, :embedded])
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  attr(:text, :string, default: nil)
  attr(:copy, :boolean, default: false)
  attr(:copy_label, :string, default: "Copy payload")
  attr(:copy_success, :string, default: "Payload copied")

  attr(:inline_copy, :boolean,
    default: false,
    doc: "Place Copy beside a short value instead of reserving a row above it."
  )

  attr(:clamp, :boolean,
    default: false,
    doc: "Show the first few lines with a Show all toggle; pass `id` with it."
  )

  attr(:id, :string, default: nil)
  slot(:inner_block)

  def ops_code_block(assigns) do
    ~H"""
    <div class={[
      "ops-code-block",
      @copy && @text && "ops-code-block--copyable",
      @inline_copy && "ops-code-block--inline-copy",
      @clamp && "ops-code-block--clamp"
    ]}>
      <div :if={@copy && @text} class="ops-code-toolbar">
        <button
          type="button"
          class="ops-quiet-action"
          data-ops-copy-text={@text}
          data-ops-copy-success={@copy_success}
          aria-label={@copy_label}
        >
          <.icon name="hero-clipboard-document" class="size-4" /> Copy
        </button>
      </div>
      <pre
        id={@id}
        tabindex="0"
        role="region"
        aria-label={@label}
        class={[
          "overflow-auto rounded-ops-md font-mono text-ops-sm whitespace-pre-wrap break-words",
          @variant == :default && "max-h-96 bg-ops-sunken p-ops-3",
          @variant == :compact && "max-h-48 bg-base-100 p-ops-2",
          @variant == :embedded && "max-h-64 bg-base-100/70 p-ops-3",
          @class
        ]}
        {@rest}
      >{if is_nil(@text), do: render_slot(@inner_block), else: @text}</pre>
      <button
        :if={@clamp}
        type="button"
        class="ops-code-expand"
        aria-expanded="false"
        aria-controls={@id}
        phx-click={
          JS.toggle_class("ops-code-block--expanded", to: {:closest, ".ops-code-block"})
          |> JS.toggle_attribute({"aria-expanded", "true", "false"})
        }
      >
        <span class="ops-code-expand__more">Show all</span>
        <span class="ops-code-expand__less">Show less</span>
      </button>
    </div>
    """
  end

  @doc "Task-adjacent help in a new tab, preserving the current task."
  attr(:href, :string, required: true)
  slot(:inner_block, required: true)

  def ops_help_link(assigns) do
    ~H"""
    <a href={@href} class="ops-help-link" target="_blank" rel="noopener">
      <span>{render_slot(@inner_block)}</span>
      <.icon name="hero-arrow-top-right-on-square" class="size-3.5" />
      <span class="sr-only">
        (opens in a new tab)
      </span>
    </a>
    """
  end

  @doc """
  Inline code text with consistent operator sizing.

  The tag is written without whitespace around the slot so no space renders inside the code or
  before the punctuation that follows it. A long identifier wraps only when it cannot fit on a line
  of its own (`overflow-wrap`), never in the middle of a word that would have fit.
  """
  attr(:class, :any, default: nil)
  slot(:inner_block, required: true)

  def ops_inline_code(assigns) do
    ~H"""
    <code
      class={["ops-inline-code font-mono text-ops-body tabular-nums", @class]}
      phx-no-format
    >{render_slot(@inner_block)}</code>
    """
  end

  @doc "Accessible modal shell for blocking file actions."
  attr(:title, :string, required: true)
  attr(:id, :string, required: true)
  attr(:cancel_event, :string, default: nil)
  attr(:description, :string, default: nil)
  attr(:action_label, :string, default: "action")
  attr(:initial_focus, :string, default: "[data-ops-modal-cancel]")
  attr(:successor, :string, default: nil)
  attr(:successor_name, :string, default: nil)
  attr(:fallback_successor, :string, default: nil)
  attr(:focus_error, :string, default: nil)
  attr(:focus_request, :integer, default: 0)
  attr(:class, :any, default: nil)
  slot(:inner_block, required: true)

  def ops_modal(assigns) do
    ~H"""
    <div
      id={@id}
      role="dialog"
      aria-modal="true"
      aria-labelledby={"#{@id}-title"}
      aria-describedby={@description && "#{@id}-description"}
      phx-hook="OpsModal"
      data-ops-modal-action={@action_label}
      data-ops-modal-cancel-event={@cancel_event}
      data-ops-modal-initial-focus={@initial_focus}
      data-ops-modal-successor={@successor}
      data-ops-modal-successor-name={@successor_name}
      data-ops-modal-fallback-successor={@fallback_successor}
      data-ops-modal-focus-error={@focus_error}
      data-ops-modal-focus-request={@focus_request}
      class="modal modal-open ops-modal z-ops-modal"
      phx-remove={
        JS.transition(
          {"transition-opacity duration-(--duration-ops-quick) ease-ops-exit", "opacity-100",
           "opacity-0"},
          time: 160
        )
      }
    >
      <div
        class={["modal-box relative rounded-ops-overlay", @class]}
        tabindex="-1"
      >
        <button
          :if={@cancel_event}
          type="button"
          class="btn ops-icon-btn btn-circle btn-ghost btn-sm absolute right-ops-3 top-ops-3"
          phx-click={@cancel_event}
          aria-label={"Close #{@title} dialog"}
        >
          <.icon name="hero-x-mark" class="size-5" />
        </button>
        <h3 id={"#{@id}-title"} class="text-ops-h2 font-semibold leading-ops-tight">{@title}</h3>
        <p
          :if={@description}
          id={"#{@id}-description"}
          class="mt-2 max-w-2xl text-ops-body text-base-content"
        >
          {@description}
        </p>
        <div class="mt-3">{render_slot(@inner_block)}</div>
      </div>
    </div>
    """
  end

  @doc """
  Side panel (sheet) for secondary management tasks.

  Shares the `OpsModal` hook with `ops_modal/1`: it traps focus, closes on Escape through
  `cancel_event`, makes the page behind it inert and returns focus to the control that opened
  it (mark that control with `data-ops-modal-trigger`). It docks to the right on wide screens
  and rises from the bottom on narrow ones.

  `focus_target` and `focus_request` move focus inside the open sheet after the server changes
  its content: bump `focus_request` to focus the element matching `focus_target`.
  """
  attr(:id, :string, required: true)
  attr(:title, :string, required: true)
  attr(:cancel_event, :string, required: true)
  attr(:description, :string, default: nil)
  attr(:initial_focus, :string, default: "[data-ops-sheet-close]")
  attr(:fallback_successor, :string, default: nil)
  attr(:focus_target, :string, default: nil)
  attr(:focus_request, :integer, default: 0)
  attr(:class, :any, default: nil)
  slot(:inner_block, required: true)

  def ops_sheet(assigns) do
    ~H"""
    <div
      id={@id}
      role="dialog"
      aria-modal="true"
      aria-labelledby={"#{@id}-title"}
      aria-describedby={@description && "#{@id}-description"}
      phx-hook="OpsModal"
      data-ops-modal-action="manage"
      data-ops-modal-cancel-event={@cancel_event}
      data-ops-modal-initial-focus={@initial_focus}
      data-ops-modal-fallback-successor={@fallback_successor}
      data-ops-modal-focus-error={@focus_target}
      data-ops-modal-focus-request={@focus_request}
      class="ops-sheet z-ops-modal"
      phx-remove={
        JS.transition(
          {"transition-opacity duration-(--duration-ops-quick) ease-ops-exit", "opacity-100",
           "opacity-0"},
          time: 160
        )
      }
    >
      <div class="ops-sheet__backdrop" phx-click={@cancel_event} aria-hidden="true"></div>
      <div class={["ops-sheet__panel", @class]} tabindex="-1">
        <div class="ops-sheet__header">
          <h2
            id={"#{@id}-title"}
            tabindex="-1"
            class="text-ops-h2 font-semibold leading-ops-tight"
          >
            {@title}
          </h2>
          <button
            type="button"
            class="btn ops-icon-btn btn-circle btn-ghost btn-sm"
            phx-click={@cancel_event}
            aria-label="Close"
            data-ops-sheet-close
          >
            <.icon name="hero-x-mark" class="size-5" />
          </button>
        </div>
        <p
          :if={@description}
          id={"#{@id}-description"}
          class="mt-ops-1 text-ops-body ops-muted"
        >
          {@description}
        </p>
        <div class="ops-sheet__body">{render_slot(@inner_block)}</div>
      </div>
    </div>
    """
  end

  @doc """
  Operator command palette (⌘K / Ctrl-K) + keyboard cheat-sheet (`?`).

  Pure client-side: every item is a live-navigation link, so the palette needs no
  server event. The `CommandPalette` JS hook owns open/close, fuzzy filter, arrow
  navigation, `?` for the cheat-sheet, and `r` to click the page's `[data-ops-refresh]`
  control. Rendered once in the `:ops` shell so it is available on every screen.
  """
  attr(:mount_path, :string, required: true)

  def ops_command_palette(assigns) do
    items =
      ([
         %{path: assigns.mount_path, label: "Control room", hint: "Search and sync overview"}
         | Enum.map(
             ScrypathOpsWeb.Nav.primary(assigns.mount_path),
             &%{path: &1.path, label: &1.label, hint: nav_hint(&1.label)}
           )
       ] ++
         [
           %{
             path: "#{assigns.mount_path}/search?saved=manage",
             label: "Manage saved searches",
             hint: "Load, rename, import or export"
           }
         ])
      |> Enum.with_index()
      |> Enum.map(fn {item, index} -> Map.put(item, :id, "ops-cmdk-item-#{index}") end)

    assigns = assign(assigns, :items, items)

    ~H"""
    <div
      id="ops-command-palette"
      phx-hook="CommandPalette"
      phx-update="ignore"
      data-cheatsheet="ops-cheatsheet"
    >
      <div
        id="ops-cmdk"
        class="ops-cmdk"
        role="dialog"
        aria-modal="true"
        aria-label="Command palette"
        hidden
      >
        <div class="ops-cmdk__backdrop" data-cmdk-close aria-hidden="true"></div>
        <div class="ops-cmdk__panel" tabindex="-1">
          <input
            type="text"
            class="ops-cmdk__input"
            placeholder="Find a page…"
            aria-label="Find a page"
            aria-controls="ops-cmdk-list"
            autocomplete="off"
            spellcheck="false"
            data-cmdk-input
          />
          <ul id="ops-cmdk-list" class="ops-cmdk__list" role="listbox" aria-label="Pages">
            <li :for={item <- @items}>
              <.link
                id={item.id}
                navigate={item.path}
                class="ops-cmdk__item"
                role="option"
                aria-selected="false"
                data-cmdk-item
                data-cmdk-label={String.downcase("#{item.label} #{item.hint}")}
              >
                <span class="ops-cmdk__item-label">{item.label}</span>
                <span class="ops-cmdk__item-hint">{item.hint}</span>
              </.link>
            </li>
          </ul>
          <p class="ops-cmdk__empty" data-cmdk-empty hidden>No matching page.</p>
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
        <div class="ops-cmdk__panel ops-cmdk__panel--sheet" tabindex="-1">
          <h2 class="text-ops-h3 font-semibold leading-ops-tight text-base-content">
            Keyboard shortcuts
          </h2>
          <dl class="ops-cheatsheet__list">
            <div class="ops-cheatsheet__row">
              <dt>
                <span class="sr-only">Command or Control K</span>
                <span aria-hidden="true">
                  <kbd class="ops-kbd">⌘</kbd>/<kbd class="ops-kbd">Ctrl</kbd>
                  <kbd class="ops-kbd">K</kbd>
                </span>
              </dt>
              <dd>Go to a page</dd>
            </div>
            <div class="ops-cheatsheet__row">
              <dt><kbd class="ops-kbd">r</kbd></dt>
              <dd>Refresh this page</dd>
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

  # Single source of truth for the button visual contract, shared by
  # `ops_button/1` and `ops_link_button/1`. Height + press feel live in `.ops-btn`;
  # radius is the `rounded-ops-control` utility so it wins over daisyUI's layer.
  # There is no danger variant: a destructive confirm is the dialog's one Plum button with its
  # consequence in the label (Failed orange is a status color, never a button). There are three
  # variants: `:default` (outline), `:primary` (the one Plum button per scope) and `:ghost` (borderless,
  # for icon-only and refresh controls). A fourth was removed because it rendered like `:default`.
  defp button_classes(variant, size) do
    [
      "btn ops-btn rounded-ops-control",
      "text-ops-body font-semibold",
      size == :xs && "btn-xs",
      size == :sm && "btn-sm",
      size == :md && "btn-md",
      variant == :primary && "btn-primary",
      variant == :ghost && "btn-ghost",
      variant == :default && "btn-outline"
    ]
  end

  defp module_flat_name(nil), do: nil

  defp module_flat_name(mod) when is_atom(mod) do
    mod |> Atom.to_string() |> String.replace_prefix("Elixir.", "")
  end

  defp schema_short_name(nil), do: ""

  defp schema_short_name(name), do: name |> String.split(".") |> List.last()

  defp schema_picker_items(schemas, selected) do
    selected_name = module_flat_name(selected)

    Enum.map(schemas, fn schema ->
      name = module_flat_name(schema)

      %{
        name: name,
        short_name: schema_short_name(name),
        dom_id: schema_dom_id(name),
        selected: name == selected_name
      }
    end)
  end

  defp schema_dom_id(name) do
    name
    |> String.replace(~r/[^A-Za-z0-9_-]+/, "-")
    |> String.trim("-")
  end

  defp exact_dt(nil, _source_iso), do: nil

  defp exact_dt(%DateTime{} = dt, source_iso) when is_binary(source_iso) do
    case DateTime.from_iso8601(source_iso) do
      {:ok, parsed, _offset} ->
        if DateTime.compare(parsed, dt) == :eq, do: source_iso, else: DateTime.to_iso8601(dt)

      _other ->
        DateTime.to_iso8601(dt)
    end
  end

  defp exact_dt(%DateTime{} = dt, _source_iso), do: DateTime.to_iso8601(dt)

  defp utc_absolute(nil), do: nil

  defp utc_absolute(%DateTime{} = dt) do
    utc = DateTime.shift_zone!(dt, "Etc/UTC")

    "#{Calendar.strftime(utc, "%b")} #{utc.day}, #{utc.year} at #{Calendar.strftime(utc, "%H:%M:%S")} UTC"
  end

  defp human_dt(nil, _snapshot_at), do: "—"

  defp human_dt(%DateTime{} = dt, snapshot_at) do
    reference =
      if match?(%DateTime{}, snapshot_at), do: snapshot_at, else: ScrypathOps.Clock.utc_now()

    case DateTime.compare(dt, reference) do
      :gt -> "After this check · #{utc_absolute(dt)}"
      _not_future -> relative_age(DateTime.diff(reference, dt, :microsecond), dt)
    end
  end

  defp relative_age(diff_microseconds, _dt) when diff_microseconds < 60 * 1_000_000,
    do: "just now"

  defp relative_age(diff_microseconds, _dt) when diff_microseconds < 3_600 * 1_000_000 do
    minutes = div(diff_microseconds, 60 * 1_000_000)
    "#{minutes} #{pluralize(minutes, "min")} ago"
  end

  defp relative_age(diff_microseconds, _dt) when diff_microseconds < 86_400 * 1_000_000 do
    hours = div(diff_microseconds, 3_600 * 1_000_000)
    "#{hours} #{pluralize(hours, "hr")} ago"
  end

  defp relative_age(diff_microseconds, _dt) when diff_microseconds < 604_800 * 1_000_000 do
    days = div(diff_microseconds, 86_400 * 1_000_000)
    "#{days} #{pluralize(days, "day")} ago"
  end

  defp relative_age(_diff_microseconds, dt), do: utc_absolute(dt)

  defp pluralize(1, unit), do: unit
  defp pluralize(_count, unit), do: "#{unit}s"

  defp nav_hint("Search"), do: "Query your schemas"
  defp nav_hint("Search health"), do: "Failures and pending work"
  defp nav_hint("Failed sync work"), do: "Review errors and retry"
  defp nav_hint("Sync and index"), do: "Sync progress and index settings"
  defp nav_hint(_), do: ""

  # The four status shapes (UI-SPEC "Shapes", LD-7): one sharp bar that leans 14.46 degrees
  # (4.13 over 16), drawn in a 8.63 x 16 box. They differ without color: filled, hollow,
  # hollow with a filled lower half, and a filled bar with a bite out of its left edge.
  @sync_status_bar "M0 16H4.5L8.63 0H4.13Z"
  @sync_status_hollow "M1.61 14.75H3.53L7.02 1.25H5.10Z"
  @sync_status_lower_half "M1.61 14.75H3.53L5.27 8H3.36Z"

  defp sync_status_shape(:clear), do: {"filled", "Clear", @sync_status_bar}

  defp sync_status_shape(:pending),
    do: {"hollow", "Pending", @sync_status_bar <> " " <> @sync_status_hollow}

  defp sync_status_shape(:retrying),
    do:
      {"bottom-filled", "Retrying",
       @sync_status_bar <> " " <> @sync_status_hollow <> " " <> @sync_status_lower_half}

  defp sync_status_shape(:failed),
    do: {"notched", "Failed", "M0 16H4.5L8.63 0H4.13L2.71 5.5L4.06 8L1.42 10.5Z"}

  # Notice, status, verdict and tone-chip kinds map to three rules: Failed, Retrying amber and the
  # neutral Control Edge. Nothing else carries a rule color (Plum is never info; green is Clear).
  defp notice_modifier(:error), do: "ops-notice-surface--error"
  defp notice_modifier(kind) when kind in [:warning, :partial], do: "ops-notice-surface--warning"
  defp notice_modifier(_kind), do: "ops-notice-surface--neutral"

  # Literal column classes so Tailwind's source scan keeps them; mobile-first base.
  defp metric_grid_cols(3), do: "sm:grid-cols-2 lg:grid-cols-3"
  defp metric_grid_cols(5), do: "sm:grid-cols-2 lg:grid-cols-5"
  defp metric_grid_cols(6), do: "sm:grid-cols-2 lg:grid-cols-6"
  defp metric_grid_cols(_), do: "sm:grid-cols-2 lg:grid-cols-4"

  # Tone chips reuse the surface tones; :neutral stays a quiet muted panel (never blue).

  defp metric_value_class(:warning), do: "ops-metric__value--warning"
  defp metric_value_class(:error), do: "ops-metric__value--error"
  defp metric_value_class(_kind), do: nil
end
