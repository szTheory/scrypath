defmodule ScrypathOpsWeb.Components.SearchHealth do
  @moduledoc """
  Function components for the Search health page (`ScrypathOpsWeb.PostureLive`).

  The LiveView and the component catalog (`scrypath_ops/storybook`) both call these, so a story
  renders the same markup the page does. They are pure: no socket, flash or authorization reads,
  and no clock. The posture comes in as a `%ScrypathOps.Posture{}` built by
  `ScrypathOps.Posture.build/3`, which is what lets a story build one with no process running.

  Three levels, smallest first: `health_verdict/1` (the answer at the top), `health_schema_row/1`
  (one schema's card) and `screen/1` (the whole page inside the operator shell).
  """
  use Phoenix.Component
  import ScrypathOpsWeb.OpsUi

  alias ScrypathOps.OperatorSelection
  alias ScrypathOps.Posture
  alias ScrypathOpsWeb.Layouts

  @doc """
  The answer at the top of Search health: a verdict that follows the worst row, then a one-line
  count of schemas and the sync mode. A posture with a setup problem (no schemas, or no backend)
  shows the matching configuration empty state instead.
  """
  attr(:summary, Posture, required: true, doc: "built by `ScrypathOps.Posture.build/3`")

  attr(:sync_mode, :any,
    default: :inline,
    doc: "the `:sync_mode` option the page scans with: `:oban`, `:inline` or `:manual`"
  )

  def health_verdict(%{summary: %Posture{state: :unconfigured}} = assigns) do
    ~H"""
    <.ops_config_empty kind={:no_schemas} class="mt-ops-4" />
    """
  end

  def health_verdict(%{summary: %Posture{state: :missing_backend}} = assigns) do
    ~H"""
    <.ops_config_empty kind={:missing_backend} class="mt-ops-4" />
    """
  end

  def health_verdict(assigns) do
    ~H"""
    <section aria-labelledby="posture-summary-heading" class="space-y-ops-4">
      <h2 id="posture-summary-heading" class="sr-only">Search health summary</h2>
      <.ops_verdict
        kind={Posture.verdict_kind(@summary.rows)}
        status={Posture.worst_status(@summary.rows)}
        class="ops-posture-verdict"
        headline={@summary.headline}
      >
        {@summary.evidence}
      </.ops_verdict>
      <p class="text-ops-sm ops-muted">
        {@summary.schema_count} {if @summary.schema_count == 1,
          do: "schema",
          else: "schemas"} · {sync_summary(@sync_mode)}
        <span :if={@summary.error_count > 0}>
          · {@summary.error_count} {if @summary.error_count == 1, do: "check", else: "checks"} unavailable
        </span>
      </p>
    </section>
    """
  end

  @doc """
  One schema's card on Search health: its status word, a link to its failed sync work when it has
  any, the facts line, and the Meilisearch and queue signal groups. A row that could not be
  checked renders its error variant, with the last observations retained from the posture.
  """
  attr(:row, :any,
    required: true,
    doc: "`{schema_module, {:ok, status} | {:error, reason}}`, as in `ScrypathOps.Posture`"
  )

  attr(:summary, Posture, required: true, doc: "the posture the row came from (retained refs)")
  attr(:mount_path, :string, required: true)

  attr(:now, DateTime,
    required: true,
    doc: "the posture's snapshot instant; no time here ever reads the clock"
  )

  def health_schema_row(%{row: {mod, {:ok, status} = result}} = assigns) do
    assigns = assign(assigns, mod: mod, status: status, result: result)

    ~H"""
    <article
      data-testid="posture-row"
      id={"posture-#{inspect(@mod)}"}
      aria-labelledby={"posture-title-#{inspect(@mod)}"}
      class="ops-schema-signal-card"
    >
      <div class="ops-schema-signal-card__header">
        <div class="min-w-0">
          <h3
            id={"posture-title-#{inspect(@mod)}"}
            class="text-ops-h3 font-semibold text-base-content"
            title={inspect(@mod)}
            data-ops-identity
          >
            {@mod |> Module.split() |> List.last()}
          </h3>
          <dl class="ops-schema-identifiers">
            <div>
              <dt>Schema module</dt>
              <dd>
                <.ops_inline_code>{inspect(@mod)}</.ops_inline_code>
              </dd>
            </div>
            <div>
              <dt>Meilisearch index</dt>
              <dd>
                <.ops_inline_code>{@status.index}</.ops_inline_code>
              </dd>
            </div>
          </dl>
        </div>
        <div class="ops-schema-signal-card__badges">
          <.row_status_word status={Posture.row_status(@result)} />
          <.link
            :if={failed_work_present?(@status)}
            navigate={OperatorSelection.path(@mount_path, "failed-sync", @mod)}
            class="ops-text-action"
            data-testid="posture-failed-sync-link"
          >
            View failed sync work <span aria-hidden="true">→</span>
          </.link>
        </div>
      </div>

      <p class="ops-signal-facts" data-testid="posture-facts">
        <span data-source="queue">
          <%= if @status.queue.observed? do %>
            Queue {queue_counts_text(@status)},
            <.ops_time
              id={"posture-facts-time-queue-#{inspect(@mod)}"}
              dt={state_at(@status.queue.last_succeeded)}
              source_iso={state_source_iso(@status.queue.last_succeeded)}
              snapshot_at={source_ref(@summary, @mod, :queue)[:checked_at] || @now}
              label={facts_time_label(@status.queue.last_succeeded)}
              state_text={lower_first(queue_time_state_text(@status))}
              operational
              copyable={false}
            />
          <% else %>
            <%= if Posture.queue_unused?(@status) do %>
              <.ops_condition word="Queue not used" />
            <% else %>
              Queue <.ops_condition word="Not observed" />
            <% end %>
          <% end %>
        </span>
        <span class="ops-signal-facts__sep" aria-hidden="true">·</span>
        <span data-source="backend">
          Meilisearch {backend_counts_text(@status)},
          <.ops_time
            id={"posture-facts-time-backend-#{inspect(@mod)}"}
            dt={state_at(@status.backend.last_succeeded)}
            source_iso={state_source_iso(@status.backend.last_succeeded)}
            snapshot_at={source_ref(@summary, @mod, :backend)[:checked_at] || @now}
            label={facts_time_label(@status.backend.last_succeeded)}
            state_text={lower_first(time_state_text(@status.backend.last_succeeded))}
            operational
            copyable={false}
          />
        </span>
      </p>

      <div class="ops-schema-signal-card__groups">
        <section
          aria-label={"Backend task signals for #{inspect(@mod)}"}
          class="ops-signal-group"
        >
          <header>
            <p class="ops-signal-group__title">Meilisearch document tasks</p>
            <p class="ops-search-query-hint">
              Applying document additions, updates and deletions.
              <.ops_help_link href={"#{@mount_path}/help#sync"}>
                About sync stages
              </.ops_help_link>
            </p>
          </header>
          <div class="ops-signal-activity">
            <p
              :if={@status.backend.pending == [] && @status.backend.failed == []}
              class="ops-signal-empty text-ops-body ops-muted"
            >
              <.ops_sync_status status={:clear} /> No pending or failed tasks.
            </p>
            <dl
              :if={@status.backend.pending != [] || @status.backend.failed != []}
              class="ops-signal-counts"
            >
              <div :if={@status.backend.pending != []}>
                <dt><.ops_sync_status status={:pending} /></dt>
                <dd>{length(@status.backend.pending)}</dd>
              </div>
              <div :if={@status.backend.failed != []} data-tone="error">
                <dt><.ops_sync_status status={:failed} /></dt>
                <dd>{length(@status.backend.failed)}</dd>
              </div>
            </dl>
          </div>
          <dl class="ops-signal-success">
            <div>
              <dt>Last succeeded</dt>
              <dd>
                <.ops_time
                  id={"posture-time-backend-#{inspect(@mod)}"}
                  dt={state_at(@status.backend.last_succeeded)}
                  source_iso={state_source_iso(@status.backend.last_succeeded)}
                  snapshot_at={source_ref(@summary, @mod, :backend)[:checked_at] || @now}
                  state_text={time_state_text(@status.backend.last_succeeded)}
                  operational
                />
              </dd>
            </div>
          </dl>
        </section>
        <section
          aria-label={"Queue job signals for #{inspect(@mod)}"}
          class="ops-signal-group"
        >
          <header>
            <p class="ops-signal-group__title">{sync_mode_label(@status.mode)}</p>
            <p class="ops-search-query-hint">
              {if @status.mode == :oban,
                do: "Application jobs delivering changes to Meilisearch.",
                else: "Host-configured sync mode; no background job history."}
            </p>
          </header>
          <div class="ops-signal-activity">
            <p
              :if={
                @status.queue.observed? && @status.queue.pending == [] &&
                  @status.queue.retrying == [] && @status.queue.failed == []
              }
              class="ops-signal-empty text-ops-body ops-muted"
            >
              <.ops_sync_status status={:clear} /> No pending, retrying or failed jobs.
            </p>
            <dl :if={@status.queue.observed?} class="ops-signal-counts">
              <div :if={@status.queue.pending != []}>
                <dt><.ops_sync_status status={:pending} /></dt>
                <dd>{length(@status.queue.pending)}</dd>
              </div>
              <div :if={@status.queue.retrying != []} data-tone="retrying">
                <dt><.ops_sync_status status={:retrying} /></dt>
                <dd>{length(@status.queue.retrying)}</dd>
              </div>
              <div :if={@status.queue.failed != []} data-tone="error">
                <dt><.ops_sync_status status={:failed} /></dt>
                <dd>{length(@status.queue.failed)}</dd>
              </div>
            </dl>
            <p :if={!@status.queue.observed?} class="text-ops-body ops-muted">
              <.ops_condition :if={!Posture.queue_unused?(@status)} word="Not observed" />
              {queue_unobserved_copy(@status)}
            </p>
          </div>
          <dl class="ops-signal-success">
            <div>
              <dt>Last succeeded</dt>
              <dd>
                <.ops_time
                  id={"posture-time-queue-#{inspect(@mod)}"}
                  dt={state_at(@status.queue.last_succeeded)}
                  source_iso={state_source_iso(@status.queue.last_succeeded)}
                  snapshot_at={source_ref(@summary, @mod, :queue)[:checked_at] || @now}
                  state_text={queue_time_state_text(@status)}
                  operational
                />
              </dd>
            </div>
          </dl>
        </section>
      </div>
    </article>
    """
  end

  def health_schema_row(%{row: {mod, {:error, reason} = result}} = assigns) do
    assigns = assign(assigns, mod: mod, reason: reason, result: result)

    ~H"""
    <article
      data-testid="posture-row"
      id={"posture-#{inspect(@mod)}"}
      aria-labelledby={"posture-title-#{inspect(@mod)}"}
      class="ops-schema-signal-card"
    >
      <div class="ops-schema-signal-card__header">
        <div class="min-w-0">
          <h3
            id={"posture-title-#{inspect(@mod)}"}
            class="text-ops-h3 font-semibold text-base-content"
            title={inspect(@mod)}
            data-ops-identity
          >
            {@mod |> Module.split() |> List.last()}
          </h3>
          <p class="mt-ops-1 break-all text-ops-sm ops-muted">{inspect(@mod)}</p>
        </div>
        <div class="ops-schema-signal-card__badges">
          <.row_status_word status={Posture.row_status(@result)} />
        </div>
      </div>
      <p class="mt-ops-2 text-ops-body" data-testid="posture-row-error">
        Search health could not be checked: {fetch_error_copy(@reason)} Refresh health to try again.
      </p>
      <dl class="ops-signal-metrics ops-signal-metrics--retained mt-ops-2">
        <div :for={source <- [:backend, :queue]}>
          <dt>{source_last_success_label(source)}</dt>
          <dd>
            <.ops_time
              id={"posture-time-retained-#{source}-#{inspect(@mod)}"}
              dt={retained_state_at(@summary, @mod, source)}
              source_iso={retained_source_iso(@summary, @mod, source)}
              snapshot_at={retained_snapshot_at(@summary, @mod, source) || @now}
              state_text={retained_state_text(@summary, @mod, source)}
              retained_text={retained_evidence_text(@summary, @mod, source)}
              operational
            />
          </dd>
        </div>
      </dl>
    </article>
    """
  end

  @doc """
  The whole Search health page inside the operator shell: header and refresh control, the verdict,
  and one card per schema.

  `rows` are the ranked rows the page was loaded with (see `ScrypathOps.Posture.sort_by_urgency/1`);
  this component never sorts, so a card does not jump while an operator reads it. The Phase 173
  fixture controls arrive through the `fixture_controls` slot, which the LiveView fills only for its
  fixture route.
  """
  attr(:mount_path, :string, required: true)
  attr(:flash, :map, required: true)
  attr(:shell, :atom, default: :ops)
  attr(:page_title, :string, default: "Search health")
  attr(:summary, Posture, required: true, doc: "built by `ScrypathOps.Posture.build/3`")

  attr(:rows, :list,
    required: true,
    doc: "ranked `{schema_module, {:ok, status} | {:error, reason}}` rows"
  )

  attr(:sync_mode, :any, default: :inline)
  attr(:now, DateTime, required: true, doc: "the posture's snapshot instant")
  attr(:refresh_disabled, :boolean, default: false)
  attr(:auto_refresh, :boolean, default: false)
  slot(:fixture_controls, doc: "fixture scenario selector, rendered under the trail")

  def screen(assigns) do
    ~H"""
    <Layouts.app
      mount_path={@mount_path}
      flash={@flash}
      shell={@shell}
      page_title={@page_title}
      ops_main_width={:wide}
    >
      <.ops_toolbar class="items-end gap-ops-4">
        <.ops_page_header
          title="Search health"
          subtitle="Find sync failures and pending work by schema."
        />
        <.ops_refresh_control
          id="search-health-refresh"
          checked_at={@now}
          disabled={@refresh_disabled}
          phx-click="refresh"
          aria_label="Refresh search health"
        />
      </.ops_toolbar>

      <.ops_trail current={:posture} />

      {render_slot(@fixture_controls)}

      <.health_verdict summary={@summary} sync_mode={@sync_mode} />

      <p :if={@auto_refresh} class="mt-ops-2 text-ops-body ops-muted">
        Auto-refresh is not enabled by default; only manual refresh runs in this build.
      </p>

      <section
        :if={@summary.state in [:ok, :degraded]}
        class="ops-schema-signal-list"
        aria-label="Per-schema search health"
      >
        <.health_schema_row
          :for={row <- @rows}
          row={row}
          summary={@summary}
          mount_path={@mount_path}
          now={@now}
        />
      </section>
    </Layouts.app>
    """
  end

  # One status word per row: the most urgent sync status, or a condition word when the row could not be
  # observed. Never an icon beside a condition, never a status for a missing observation.
  defp row_status_word(%{status: {:condition, word}} = assigns) do
    assigns = assign(assigns, :word, word)

    ~H"""
    <.ops_condition word={@word} />
    """
  end

  defp row_status_word(assigns) do
    ~H"""
    <.ops_sync_status status={@status} />
    """
  end

  defp sync_summary(mode) do
    case mode do
      :oban -> "Background sync with Oban"
      :inline -> "Inline sync"
      :manual -> "Manual sync"
      _ -> "Sync mode unavailable"
    end
  end

  defp failed_work_present?(status) do
    status.backend.failed != [] or status.queue.failed != []
  end

  defp state_at(%Scrypath.Operator.State{at: at}), do: at
  defp state_at(_state), do: nil

  defp state_source_iso(%Scrypath.Operator.State{metadata: metadata}),
    do: Map.get(metadata, :source_iso)

  defp state_source_iso(_state), do: nil

  defp time_state_text(nil), do: "No completed task in available history"
  defp time_state_text(%Scrypath.Operator.State{at: nil}), do: "Completion time unavailable"
  defp time_state_text(%Scrypath.Operator.State{}), do: ""

  defp queue_time_state_text(%{queue: %{observed?: false}}), do: "Queue not used"

  defp queue_time_state_text(%{queue: %{last_succeeded: nil}}),
    do: "No completed job in available history"

  defp queue_time_state_text(%{queue: %{last_succeeded: state}}), do: time_state_text(state)

  defp source_last_success_label(:backend), do: "Meilisearch last succeeded"
  defp source_last_success_label(:queue), do: "Queue last succeeded"

  defp source_ref(%Posture{last_success_refs: refs}, schema, source) do
    refs
    |> Map.get(schema, %{})
    |> Map.get(source)
  end

  defp source_ref(_summary, _schema, _source), do: nil

  defp retained_state_at(summary, schema, source) do
    case source_ref(summary, schema, source) do
      %{state: %Scrypath.Operator.State{at: at}} -> at
      _other -> nil
    end
  end

  defp retained_source_iso(summary, schema, source) do
    case source_ref(summary, schema, source) do
      %{state: state} -> state_source_iso(state)
      _other -> nil
    end
  end

  defp retained_snapshot_at(summary, schema, source) do
    case source_ref(summary, schema, source) do
      %{checked_at: checked_at} -> checked_at
      _other -> nil
    end
  end

  defp retained_state_text(summary, schema, source) do
    case source_ref(summary, schema, source) do
      %{unused?: true} -> "Queue not used"
      %{state: state} -> time_state_text(state)
      nil -> "No successful observation recorded."
    end
  end

  defp fetch_error_copy({:http_error, status, _body}) when is_integer(status),
    do: "The search backend returned HTTP #{status}."

  defp fetch_error_copy({:transport_error, _exception}),
    do: "Could not connect to the search backend."

  defp fetch_error_copy({:invalid_task_payload, _details}),
    do: "The search backend returned an invalid task response."

  defp fetch_error_copy({:task_history_truncated, _details}),
    do: "Search task history exceeded its configured limit."

  defp fetch_error_copy({:unsupported_operator_backend, _backend}),
    do: "The configured search backend is not supported."

  defp fetch_error_copy(_reason),
    do: "A configured search health source could not be read."

  defp retained_evidence_text(summary, schema, source) do
    case source_ref(summary, schema, source) do
      %{unused?: true} ->
        "Queue not used."

      %{checked_at: %DateTime{} = checked_at} ->
        checked_iso = checked_at |> DateTime.shift_zone!("Etc/UTC") |> DateTime.to_iso8601()

        "Current observation is unavailable; this source-local evidence is retained from check #{checked_iso}."

      _other ->
        nil
    end
  end

  # The dense facts line: counts per source, zero statuses left out unless all are zero.
  defp queue_counts_text(status) do
    counts_text([
      {status.queue.pending, "pending"},
      {status.queue.retrying, "retrying"},
      {status.queue.failed, "failed"}
    ])
  end

  defp backend_counts_text(status) do
    counts_text([
      {status.backend.pending, "pending"},
      {status.backend.failed, "failed"}
    ])
  end

  defp counts_text(counts) do
    case for({states, word} <- counts, states != [], do: "#{length(states)} #{word}") do
      [] -> "0 pending"
      parts -> Enum.join(parts, ", ")
    end
  end

  # A recorded success time reads "last succeeded <time>"; a missing one prints its own sentence.
  defp facts_time_label(%Scrypath.Operator.State{at: %DateTime{}}), do: "last succeeded"
  defp facts_time_label(_state), do: nil

  defp lower_first(<<first::utf8, rest::binary>>), do: String.downcase(<<first::utf8>>) <> rest
  defp lower_first(other), do: other

  defp sync_mode_label(:oban), do: "Background sync with Oban"
  defp sync_mode_label(:inline), do: "Inline sync"
  defp sync_mode_label(:manual), do: "Manual sync"
  defp sync_mode_label(mode), do: "Sync: #{mode}"

  defp queue_unobserved_copy(status) do
    if Posture.queue_unused?(status) do
      "Queue not used in #{status.mode} sync mode."
    else
      "Queue observations unavailable; no queue counts are reported as zero."
    end
  end
end
