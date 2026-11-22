defmodule ScrypathOpsWeb.Components.FailedSync do
  @moduledoc """
  Function components for the Failed sync page (`ScrypathOpsWeb.FailedSyncLive`).

  The LiveView and the component catalog (`scrypath_ops/storybook`) both call these, so a story
  renders the same markup the page does. They are pure: no socket, flash or authorization reads, and
  no clock. What they show comes in as a `%ScrypathOps.FailedSyncView{}` built by
  `ScrypathOps.FailedSyncView.build/4`, which is what lets a story build one with no process running.
  Events (`retry`, `filter`, `confirm_retry_delete`, ...) are bound here by name and handled in the
  LiveView, where `Gating` decides whether the operator may act.

  Smallest first: `failed_filters/1` and `retry_receipt/1` are patterns reused inside the areas;
  `failed_summary/1`, `failed_row/1` and `delete_confirmation/1` are areas; `surface/1` is the whole
  page inside the operator shell.
  """
  use Phoenix.Component
  import ScrypathOpsWeb.OpsUi

  alias ScrypathOps.FailedSyncView
  alias ScrypathOps.FailedSyncView.Row
  alias ScrypathOps.OperatorSelection
  alias ScrypathOpsWeb.Layouts

  @record_id_preview 3
  @clamp_length 240
  @known_metadata [:worker, :queue, :index, :task_uid, :type]

  @doc """
  The schema and cause filter chips. Each chip is a checkbox named by its wrapping label; the form
  sends `filter` on change and the LiveView patches the URL.
  """
  attr(:view, FailedSyncView,
    required: true,
    doc: "built by `ScrypathOps.FailedSyncView.build/4`"
  )

  def failed_filters(assigns) do
    ~H"""
    <.form
      for={%{}}
      id="failed-sync-filters"
      phx-change="filter"
      class="ops-failed-filters"
    >
      <fieldset :if={@view.show_schema_facets?} class="ops-failed-filters__group">
        <legend class="ops-failed-filters__legend">Schema</legend>
        <label
          :for={facet <- @view.schema_facets}
          class={[
            "ops-filter-chip",
            facet.selected? && "ops-filter-chip--selected",
            facet.count == 0 && !facet.error? && "ops-filter-chip--quiet"
          ]}
          title={facet.name}
          data-testid="failed-sync-schema-filter"
        >
          <input
            type="checkbox"
            name="schema[]"
            value={facet.name}
            checked={facet.selected?}
          />
          <span>{facet.short_name}{" "}</span>
          <span :if={facet.error?} class="ops-filter-chip__count">
            couldn't load
          </span>
          <span :if={!facet.error?} class="ops-filter-chip__count">
            {facet.count}<span class="sr-only">
              {" "}({facet.failed} failed, {facet.retrying} retrying)</span>
          </span>
        </label>
      </fieldset>
      <fieldset
        :if={@view.cause_facets != []}
        class="ops-failed-filters__group"
      >
        <legend class="ops-failed-filters__legend">Cause</legend>
        <label
          :for={facet <- @view.cause_facets}
          class={[
            "ops-filter-chip",
            facet.selected? && "ops-filter-chip--selected",
            facet.count == 0 && "ops-filter-chip--quiet"
          ]}
          data-testid="failed-sync-cause-filter"
        >
          <input
            type="checkbox"
            name="cause[]"
            value={facet.value}
            checked={facet.selected?}
          />
          <span>{facet.label}{" "}</span>
          <span class="ops-filter-chip__count">{facet.count}</span>
        </label>
      </fieldset>
    </.form>
    """
  end

  @doc """
  The answer at the top of Failed sync: any schema that could not be loaded, then the verdict
  (headline, guidance, the hidden-by-filters note) and the filter chips. When every schema in scope
  failed to load, only the load errors show.
  """
  attr(:view, FailedSyncView,
    required: true,
    doc: "built by `ScrypathOps.FailedSyncView.build/4`"
  )

  attr(:mount_path, :string, required: true)

  def failed_summary(assigns) do
    ~H"""
    <.ops_status
      :for={{mod, reason} <- @view.errors}
      kind={:error}
      title={"Failed sync work could not load for #{FailedSyncView.schema_short_name(mod)}"}
      role="alert"
      data-testid="failed-sync-load-error"
    >
      <p>
        {OperatorSelection.canonical(mod)} couldn't be checked, so its failures aren't listed.
        Check backend and queue configuration, then refresh.
      </p>
      <.ops_code_block
        class="mt-2"
        variant={:compact}
        label={"Load error for #{FailedSyncView.schema_short_name(mod)}"}
        text={load_error_text(reason)}
        copy
        inline_copy
        copy_label="Copy error"
        copy_success="Error copied"
      />
    </.ops_status>

    <section
      :if={not @view.all_failed?}
      aria-labelledby="failed-sync-summary-heading"
      class="space-y-3"
    >
      <.ops_verdict
        kind={@view.summary_kind}
        headline={@view.headline}
        headline_id="failed-sync-summary-heading"
        data-testid="failed-sync-summary"
      >
        <span :if={@view.rows != []}>{@view.guidance}</span>
        <span :if={@view.rows != [] and @view.hidden_count > 0} data-testid="failed-sync-filter-note">
          {@view.hidden_count} more hidden by filters.
          <.link
            patch={FailedSyncView.filter_path(@mount_path, [], [])}
            class="link underline underline-offset-2"
          >
            Clear filters
          </.link>
        </span>
        <span :if={@view.filtered_out?}>
          <.link
            patch={FailedSyncView.filter_path(@mount_path, [], [])}
            class="link underline underline-offset-2"
          >
            Clear filters
          </.link>
          to see all failed and retrying work.
        </span>
        <span :if={@view.rows == [] and not @view.filtered_out?}>
          No failures were found in the available history. Pending work and document freshness are checked on Sync and index.
        </span>
      </.ops_verdict>

      <.failed_filters :if={@view.show_filters?} view={@view} />
    </section>
    """
  end

  @doc """
  The block shown in place of Retry once a retry was queued: the replacement Oban job, a plain
  statement that completion is not confirmed, and a link to check its status on Sync and index when
  the receipt could be registered for observation.
  """
  attr(:row, Row, required: true, doc: "a row whose `action` is `:receipt`")
  attr(:mount_path, :string, required: true)

  def retry_receipt(assigns) do
    ~H"""
    <.ops_status
      class="ops-failed-row__receipt"
      kind={:neutral}
      title="Retry queued"
      role="status"
      data-testid="recovery-receipt"
    >
      Oban job #{@row.receipt.replacement_job} will {if @row.receipt.operation == :delete,
        do: "delete",
        else: "add or update"} records in <.ops_inline_code>{@row.receipt.index}</.ops_inline_code>.
      Completion has not been confirmed. Original job #{@row.id} is retained.
      <.link
        :if={@row.receipt.handle}
        navigate={recovery_handoff_path(@mount_path, @row.schema, @row.receipt)}
        class="ml-2 min-h-ops-control link link-primary underline underline-offset-2"
      >
        Check sync status
      </.link>
    </.ops_status>
    """
  end

  @doc """
  One failed or retrying sync job: its status word, schema and operation, source, record ids, times,
  the error text, the Retry action (or its receipt, or why it cannot be retried) and the secondary
  details. Every time is measured against `now`, never the clock.
  """
  attr(:row, Row, required: true, doc: "a row built by `ScrypathOps.FailedSyncView.build/4`")
  attr(:now, DateTime, required: true, doc: "the view's snapshot instant")
  attr(:mount_path, :string, required: true)

  def failed_row(assigns) do
    ~H"""
    <article
      id={"failed-row-#{@row.dom_id}"}
      class="ops-failed-row"
      data-testid="failed-sync-row"
      data-state={@row.state}
    >
      <div class="ops-failed-row__facts">
        <.ops_sync_status status={@row.sync_status} />
        <h3 class="ops-failed-row__title">
          <span title={OperatorSelection.canonical(@row.schema)} data-ops-identity>
            {FailedSyncView.schema_short_name(@row.schema)}
          </span>
          <span aria-hidden="true">·</span>
          {operation_label(@row.operation)}
        </h3>
        <span class="ops-failed-row__sep" aria-hidden="true">·</span>
        <span>{source_label(@row)}</span>
        <span :if={record_count_label(@row)} class="ops-failed-row__sep" aria-hidden="true">
          ·
        </span>
        <span :if={record_count_label(@row)} data-testid="failed-sync-records">
          {record_count_label(@row)}<span :if={preview = record_id_preview(@row)}>:
            <code class="ops-failed-row__ids">{elem(preview, 0)}</code>{elem(preview, 1)}</span>
        </span>
        <span class="ops-failed-row__sep" aria-hidden="true">·</span>
        <span class="ops-failed-row__time">
          <span class="sr-only">Last attempt</span>
          <.ops_time
            id={"failed-attempt-#{@row.dom_id}"}
            dt={@row.last_attempt_at}
            snapshot_at={@now}
            state_text="No attempt time recorded"
            operational
          />
        </span>
        <span :if={@row.next_attempt_at} class="ops-failed-row__sep" aria-hidden="true">
          ·
        </span>
        <span
          :if={@row.next_attempt_at}
          class="ops-failed-row__time"
          data-testid="failed-sync-next-try"
        >
          <.ops_time
            id={"failed-next-try-#{@row.dom_id}"}
            dt={@row.next_attempt_at}
            snapshot_at={@now}
            label="Next try"
            operational
          />
        </span>
      </div>

      <div :if={@row.reason} class="ops-failed-row__error">
        <.ops_code_block
          id={"failed-reason-#{@row.dom_id}"}
          variant={:compact}
          label="Error"
          text={@row.reason}
          copy
          inline_copy
          clamp={clamp?(@row.reason)}
          copy_label="Copy error"
          copy_success="Error copied"
          data-testid="failed-sync-reason"
        />
      </div>

      <div :if={@row.action == :retry} class="ops-failed-row__actions">
        <button
          type="button"
          class="ops-text-action"
          phx-click="retry"
          phx-value-id={@row.id}
          phx-value-schema={OperatorSelection.canonical(@row.schema)}
          phx-value-source={@row.source}
          data-testid="failed-sync-retry"
        >
          Retry
        </button>
      </div>

      <.retry_receipt :if={@row.action == :receipt} row={@row} mount_path={@mount_path} />

      <div class="ops-failed-row__foot">
        <p class="ops-failed-row__guidance">
          {cause_guidance(@row)}
          <span :if={not @row.recoverable?} data-testid="failed-sync-eligibility">
            {retry_eligibility(@row)}
          </span>
        </p>
        <.ops_disclosure
          id={"failed-detail-#{@row.dom_id}"}
          summary="More details"
          variant={:compact}
          class="ops-failed-row__details"
        >
          <dl :if={detail_facts(@row) != []} class="ops-failed-details">
            <div :for={{label, value} <- detail_facts(@row)}>
              <dt>{label}</dt>
              <dd>{value}</dd>
            </div>
          </dl>
          <.ops_code_block
            :if={job_args(@row)}
            class="mt-2"
            variant={:compact}
            label="Job args"
            text={job_args(@row)}
            copy
            inline_copy
            copy_label="Copy job args"
            copy_success="Job args copied"
          />
          <p :if={detail_facts(@row) == [] and is_nil(job_args(@row))}>
            No further details were recorded.
          </p>
        </.ops_disclosure>
      </div>
    </article>
    """
  end

  @doc """
  The confirmation dialog for retrying a delete: the schema, the index and every document id the
  retry would delete, with a Keep action focused first.
  """
  attr(:row, Row,
    required: true,
    doc: "a row whose operation is `:delete` and that has a recovery"
  )

  def delete_confirmation(assigns) do
    ~H"""
    <.ops_modal
      id="retry-delete-modal"
      title="Confirm delete sync work"
      description={delete_confirmation_description(@row)}
      action_label="retry delete"
      initial_focus="[data-ops-modal-cancel]"
      cancel_event="cancel_retry_delete"
    >
      <.form for={%{}} phx-submit="confirm_retry_delete" class="space-y-3">
        <div class="rounded-ops-surface border border-base-300 p-ops-3 text-ops-body">
          <p>
            Schema
            <.ops_inline_code>{OperatorSelection.canonical(@row.schema)}</.ops_inline_code>
          </p>
          <p>
            Index
            <.ops_inline_code>{delete_confirmation_index(@row)}</.ops_inline_code>
          </p>
          <p>{document_count_label(length(delete_confirmation_ids(@row)))}</p>
          <ul class="mt-2 list-inside list-disc break-all font-mono text-ops-sm">
            <li :for={document_id <- delete_confirmation_ids(@row)}>
              {inspect(document_id)}
            </li>
          </ul>
        </div>
        <div class="flex justify-between gap-2">
          <.ops_button
            type="button"
            phx-click="cancel_retry_delete"
            variant={:default}
            aria-label="Keep failed work and close"
            data-ops-modal-cancel
          >
            Keep failed work and close
          </.ops_button>
          <.ops_button type="submit" variant={:primary}>
            Retry deleting {document_count_label(length(delete_confirmation_ids(@row)))}
          </.ops_button>
        </div>
      </.form>
    </.ops_modal>
    """
  end

  @doc """
  The whole Failed sync page inside the operator shell: header and refresh control, the setup or
  unavailable states, the summary and filters, the rows, the handoff to Sync and index and, when a
  delete retry is awaiting confirmation, its dialog.
  """
  attr(:view, FailedSyncView,
    required: true,
    doc: "built by `ScrypathOps.FailedSyncView.build/4`"
  )

  attr(:mount_path, :string, required: true)
  attr(:flash, :map, required: true)
  attr(:shell, :atom, default: :ops)
  attr(:page_title, :string, default: "Failed sync work")

  attr(:last_refresh_at, :any,
    default: nil,
    doc:
      "when the work was last loaded, shown by the refresh control; `nil` before the first load"
  )

  def surface(assigns) do
    ~H"""
    <Layouts.app
      mount_path={@mount_path}
      flash={@flash}
      shell={@shell}
      page_title={@page_title}
      ops_main_width={:wide}
    >
      <.ops_toolbar class="items-end gap-4">
        <.ops_page_header
          title={@page_title}
          subtitle="Each row is sync work that didn't reach Meilisearch. Retry queues the same records again and sends their current data."
        />
        <.ops_refresh_control
          id="failed-sync-refresh"
          checked_at={@last_refresh_at}
          phx-click="refresh"
          aria_label="Refresh failed sync work"
        />
      </.ops_toolbar>

      <.ops_trail current={:failed_sync} />

      <.ops_empty_state :if={@view.state == :no_schemas} title="No schemas configured.">
        Add allowlisted schema modules with
        <.ops_inline_code>schema_allowlist</.ops_inline_code>
        in <.ops_inline_code>:scrypath_ops</.ops_inline_code>, then refresh failed sync jobs.
      </.ops_empty_state>

      <.ops_status
        :if={@view.state == :unavailable}
        kind={:error}
        title="That schema is unavailable."
        role="alert"
      >
        It isn't in the schema allowlist.
        <.link
          patch={"#{String.trim_trailing(@mount_path, "/")}/failed-sync"}
          class="link underline underline-offset-2"
        >
          Show all schemas
        </.link>
      </.ops_status>

      <.ops_empty_state :if={@view.state == :missing_backend} title="Runtime not configured">
        Configure the Scrypath runtime under
        <.ops_inline_code>:scrypath_ops</.ops_inline_code>
        — see <.ops_inline_code>scrypath_ops/README.md</.ops_inline_code>, then refresh.
      </.ops_empty_state>

      <div :if={@view.state == :ready} class="space-y-ops-page-gap">
        <.failed_summary view={@view} mount_path={@mount_path} />

        <section
          :if={@view.rows != []}
          aria-labelledby="failed-sync-list-heading"
          class="ops-failed-list"
        >
          <h2 id="failed-sync-list-heading" class="sr-only">Failed and retrying sync work</h2>
          <.failed_row
            :for={row <- @view.rows}
            row={row}
            now={@view.now}
            mount_path={@mount_path}
          />
        </section>

        <p :if={@view.rows != []} class="ops-search-query-hint">
          <.ops_help_link href={"#{@mount_path}/help#recovery"}>
            Help with sync failures and recovery
          </.ops_help_link>
        </p>
      </div>

      <.ops_handoff :if={@view.state == :ready}>
        <:step
          navigate={sync_and_index_path(@mount_path, @view.handoff_schema)}
          hint="Check pending work and index settings —"
        >
          Check sync and index
        </:step>
      </.ops_handoff>

      <.delete_confirmation :if={@view.delete_row} row={@view.delete_row} />
    </Layouts.app>
    """
  end

  # ── Copy ───────────────────────────────────────────────────────────────────

  defp cause_guidance(%Row{recoverable?: false} = row),
    do: FailedSyncView.cause_label(row.cause) <> "."

  defp cause_guidance(%Row{} = row) do
    case {row.cause, row.state} do
      {:validation, _} -> "Invalid data: fix the record, then retry."
      {:queue_exhausted, _} -> "Retries used up. Fix the cause, then retry."
      {cause, :retrying} -> "#{FailedSyncView.cause_label(cause)}. This will retry automatically."
      {:transport, _} -> "Couldn't reach Meilisearch. Check that it's running, then retry."
      {:backend_rejected, _} -> "Meilisearch rejected it. Check the index, then retry."
      {_, _} -> "Unknown cause. Read the error, then retry."
    end
  end

  defp retry_eligibility(%Row{source: :meilisearch}),
    do: "Meilisearch tasks can't be retried here. Resubmit the change from your app."

  defp retry_eligibility(%Row{operation: :unknown}),
    do: "The operation is unknown, so this can't be retried here."

  defp retry_eligibility(%Row{}),
    do: "The job didn't keep its record IDs, so it can't be retried here."

  defp operation_label(:upsert), do: "Add or update"
  defp operation_label(:delete), do: "Delete"
  defp operation_label(_), do: "Unknown operation"

  defp source_label(%Row{source: :meilisearch, id: id}), do: "Meilisearch task ##{id}"

  defp source_label(%Row{entry: %{metadata: metadata}, id: id}) do
    case Map.get(metadata, :queue) do
      queue when is_binary(queue) and queue != "" -> "Oban #{queue} ##{id}"
      queue when is_atom(queue) and not is_nil(queue) -> "Oban #{queue} ##{id}"
      _ -> "Oban job ##{id}"
    end
  end

  defp record_count_label(%Row{record_ids: nil}), do: nil
  defp record_count_label(%Row{record_ids: [_]}), do: "1 record"
  defp record_count_label(%Row{record_ids: ids}), do: "#{length(ids)} records"

  defp record_id_preview(%Row{record_ids: ids}) when ids in [nil, []], do: nil

  defp record_id_preview(%Row{record_ids: ids}) do
    shown = ids |> Enum.take(@record_id_preview) |> Enum.map_join(", ", &to_string/1)
    extra = length(ids) - @record_id_preview
    {shown, if(extra > 0, do: " and #{extra} more")}
  end

  defp clamp?(reason) when is_binary(reason),
    do: String.length(reason) > @clamp_length or length(String.split(reason, "\n")) > 3

  defp clamp?(_reason), do: false

  defp detail_facts(%Row{entry: entry} = row) do
    metadata = entry.metadata || %{}

    known =
      [
        {"Worker", Map.get(metadata, :worker)},
        {"Meilisearch index",
         Map.get(metadata, :index) || (entry.recovery && entry.recovery.index)},
        {"Attempts", row.attempts},
        {"Meilisearch task type", Map.get(metadata, :type)},
        {"Meilisearch task",
         if(Map.get(metadata, :task_uid) != row.id, do: Map.get(metadata, :task_uid))}
      ]
      |> Enum.reject(fn {_label, value} -> value in [nil, ""] end)

    other =
      metadata
      |> Enum.reject(fn {key, _} -> key in @known_metadata end)
      |> Enum.sort_by(fn {key, _} -> to_string(key) end)
      |> Enum.map(fn {key, value} -> {humanize_key(key), value} end)

    Enum.map(known ++ other, fn {label, value} -> {label, display_value(value)} end)
  end

  defp humanize_key(key) do
    key |> to_string() |> String.replace("_", " ") |> String.capitalize()
  end

  defp display_value(value) when is_binary(value), do: value
  defp display_value(value) when is_atom(value), do: OperatorSelection.canonical(value)
  defp display_value(value), do: inspect(value)

  defp job_args(%Row{entry: %{recovery: %{reference: %{payload: payload}}}})
       when is_map(payload) do
    case Jason.encode(payload, pretty: true) do
      {:ok, json} -> json
      _ -> inspect(payload, pretty: true)
    end
  end

  defp job_args(_row), do: nil

  defp load_error_text(reason), do: inspect(reason, pretty: true)

  # ── Delete confirmation ────────────────────────────────────────────────────

  defp delete_confirmation_ids(%Row{entry: entry}),
    do: get_in(entry.recovery.reference, [:payload, "document_ids"]) || []

  defp delete_confirmation_index(%Row{entry: entry}),
    do: entry.recovery.index || Map.get(entry.metadata, :index) || "unknown"

  defp delete_confirmation_description(%Row{} = row) do
    count = length(delete_confirmation_ids(row))

    "Retry deletion of #{document_count_label(count)} for #{OperatorSelection.canonical(row.schema)} in #{delete_confirmation_index(row)}."
  end

  # `1 document`, `3 documents`: the singular reads correctly in the description, the count line
  # and the confirm label, so one helper builds all three.
  defp document_count_label(1), do: "1 document"
  defp document_count_label(count), do: "#{count} documents"

  # ── Paths ──────────────────────────────────────────────────────────────────

  defp recovery_handoff_path(mount_path, schema, receipt) do
    base = String.trim_trailing(mount_path, "/")

    query =
      URI.encode_query(%{
        "schema" => OperatorSelection.canonical(schema),
        "recovery" => receipt.handle,
        "recovery_generation" => receipt.generation
      })

    "#{base}/sync-and-index?#{query}"
  end

  defp sync_and_index_path(mount_path, nil),
    do: "#{String.trim_trailing(mount_path, "/")}/sync-and-index"

  defp sync_and_index_path(mount_path, mod),
    do: OperatorSelection.path(mount_path, "sync-and-index", mod)
end
