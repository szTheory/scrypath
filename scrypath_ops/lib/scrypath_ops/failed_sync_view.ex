defmodule ScrypathOps.FailedSyncView do
  @moduledoc """
  What the Failed sync page shows, as one pure value.

  `build/4` takes what `ScrypathOpsWeb.FailedSyncLive` holds (the per-schema loads, the URL scope, the
  retry receipts) and a snapshot instant, and returns this struct: the page state, the visible rows
  with their classification, the summary, and the filter facets. It reads no clock, starts no process
  and imports nothing from Phoenix, so the component catalog builds the same value from fixture data
  with no application running.

  The LiveView keeps everything with a side effect: events, the `Gating` calls, receipt registration
  and `start_async`. The function components in `ScrypathOpsWeb.Components.FailedSync` only render
  this struct.

  ## Closed sets

    * page state: `:no_schemas | :unavailable | :missing_backend | :ready`
    * summary kind: `:warning | :neutral | :partial | :success`
    * cause: `:validation | :transport | :backend_rejected | :queue_exhausted | :unknown`
    * row sync status: `:retrying | :failed` (Failed sync never observes pending work, so it never
      shows Clear or Pending)
    * row action: `:retry | :receipt | :ineligible` (see `ScrypathOps.FailedSyncView.Row`)
  """

  alias Scrypath.Operator.FailedWork
  alias ScrypathOps.FailedSyncView.Row
  alias ScrypathOps.OperatorSelection

  @causes [:validation, :transport, :backend_rejected, :queue_exhausted, :unknown]

  @type cause :: :validation | :transport | :backend_rejected | :queue_exhausted | :unknown
  @type page_state :: :no_schemas | :unavailable | :missing_backend | :ready
  @type summary_kind :: :warning | :neutral | :partial | :success
  @type sync_status :: :retrying | :failed

  @typedoc """
  One schema's load: `{schema_module, {:ok, [FailedWork.t()]} | {:error, reason}}`, as
  `ScrypathOpsWeb.FailedSyncLive` stores it. The whole value is `:missing_backend` when the Scrypath
  runtime has no backend, and `nil` while a scope error (no schemas, an unavailable schema) means
  nothing was loaded.
  """
  @type loads ::
          [{module(), {:ok, [FailedWork.t()]} | {:error, term()}}] | :missing_backend | nil

  @typedoc """
  The URL and page scope, with these keys:

    * `:error` - `nil | :no_schemas | :unavailable`
    * `:allowlist` - every allowlisted schema module
    * `:schema_filter` - the schema modules selected in the URL
    * `:cause_filter` - the causes selected in the URL
    * `:delete_confirmation` - the key of the delete retry awaiting confirmation, or `nil`
  """
  @type scope :: %{
          required(:error) => nil | :no_schemas | :unavailable,
          required(:allowlist) => [module()],
          required(:schema_filter) => [module()],
          required(:cause_filter) => [cause()],
          required(:delete_confirmation) => String.t() | nil
        }

  @type schema_facet :: %{
          module: module(),
          name: String.t(),
          short_name: String.t(),
          count: non_neg_integer(),
          failed: non_neg_integer(),
          retrying: non_neg_integer(),
          error?: boolean(),
          selected?: boolean()
        }

  @type cause_facet :: %{
          cause: cause(),
          value: String.t(),
          label: String.t(),
          count: non_neg_integer(),
          selected?: boolean()
        }

  @type t :: %__MODULE__{
          state: page_state(),
          now: DateTime.t(),
          rows: [Row.t()],
          errors: [{module(), term()}],
          all_failed?: boolean(),
          filtered?: boolean(),
          filtered_out?: boolean(),
          hidden_count: non_neg_integer(),
          show_filters?: boolean(),
          show_schema_facets?: boolean(),
          summary_kind: summary_kind(),
          headline: String.t(),
          guidance: String.t(),
          schema_facets: [schema_facet()],
          cause_facets: [cause_facet()],
          handoff_schema: module() | nil,
          delete_row: Row.t() | nil
        }

  @enforce_keys [:state, :now]
  defstruct [
    :state,
    :now,
    :summary_kind,
    :headline,
    :handoff_schema,
    :delete_row,
    rows: [],
    errors: [],
    all_failed?: false,
    filtered?: false,
    filtered_out?: false,
    hidden_count: 0,
    show_filters?: false,
    show_schema_facets?: false,
    guidance: "",
    schema_facets: [],
    cause_facets: []
  ]

  @doc "The closed set of failure causes, in the order they are offered when counts tie."
  @spec causes() :: [cause()]
  def causes, do: @causes

  @doc """
  Builds the page view.

  `loads` is the LiveView's per-schema result, `scope` its URL scope (see `t:scope/0`), `receipts`
  its map of retry receipts keyed by `row_key/1`, and `now` the instant every time on the page is
  measured against. The caller reads the clock once and passes it in; nothing here does.

  `loads` may be `nil` only while `scope.error` is set (nothing is loaded for a scope error); any
  other `nil` raises, because the LiveView never produces it.
  """
  @spec build(loads(), scope(), %{optional(String.t()) => map()}, DateTime.t()) :: t()
  def build(loads, scope, receipts, %DateTime{} = now) do
    entries = all_rows(loads)
    errors = scoped_errors(loads, scope)
    filtered? = scope.schema_filter != [] or scope.cause_filter != []
    visible = visible_entries(entries, scope)
    any_rows? = entries != []

    %__MODULE__{
      state: page_state(loads, scope),
      now: now,
      rows: Enum.map(visible, &build_row(&1, receipts)),
      errors: errors,
      all_failed?: all_scoped_failed?(loads, scope),
      filtered?: filtered?,
      filtered_out?: visible == [] and filtered? and any_rows?,
      hidden_count: if(filtered?, do: length(entries) - length(visible), else: 0),
      show_filters?: any_rows? or filtered?,
      show_schema_facets?: length(scope.allowlist) > 1,
      summary_kind: summary_kind(visible, entries, errors, filtered?),
      headline: summary_headline(visible, entries, errors, filtered?),
      guidance: summary_guidance(visible),
      schema_facets: schema_facets(loads, entries, scope),
      cause_facets: cause_facets(entries, scope),
      handoff_schema: single_scope_schema(scope),
      delete_row: delete_row(entries, scope.delete_confirmation, receipts)
    }
  end

  @doc "Every loaded failed or retrying job across all schemas, in load order."
  @spec all_rows(loads()) :: [FailedWork.t()]
  def all_rows(loads) when is_list(loads),
    do: for({_mod, {:ok, rows}} <- loads, row <- rows, do: row)

  def all_rows(_loads), do: []

  @doc "The row's cause, `:unknown` when Scrypath did not classify it."
  @spec cause(FailedWork.t() | map()) :: cause()
  def cause(%{reason_class: class}) when class in @causes, do: class
  def cause(_row), do: :unknown

  @doc "The key a receipt is stored under: schema, source and id, so two schemas never collide."
  @spec row_key(FailedWork.t() | map()) :: String.t()
  def row_key(row), do: "#{OperatorSelection.canonical(row.schema)}|#{row.source}|#{row.id}"

  @doc "A DOM-safe id for the row's elements."
  @spec row_dom_id(FailedWork.t() | map()) :: String.t()
  def row_dom_id(row) do
    "#{OperatorSelection.canonical(row.schema)}-#{row.source}-#{row.id}"
    |> String.replace(~r/[^A-Za-z0-9_-]+/, "-")
  end

  @doc "The patch path for a schema and cause filter selection under the mount path."
  @spec filter_path(String.t(), [module()], [cause()]) :: String.t()
  def filter_path(mount_path, schemas, causes) do
    base = String.trim_trailing(mount_path, "/")

    query =
      Enum.map(schemas, &{"schema", OperatorSelection.canonical(&1)}) ++
        Enum.map(causes, &{"cause", Atom.to_string(&1)})

    case query do
      [] -> "#{base}/failed-sync"
      pairs -> "#{base}/failed-sync?#{URI.encode_query(pairs)}"
    end
  end

  @doc "The last segment of the schema's canonical name, for headings and chips."
  @spec schema_short_name(module()) :: String.t()
  def schema_short_name(mod),
    do: mod |> OperatorSelection.canonical() |> String.split(".") |> List.last()

  @doc "The operator-facing words for a cause."
  @spec cause_label(cause() | term()) :: String.t()
  def cause_label(:validation), do: "Invalid data"
  def cause_label(:transport), do: "Couldn't reach Meilisearch"
  def cause_label(:backend_rejected), do: "Meilisearch rejected it"
  def cause_label(:queue_exhausted), do: "Retries used up"
  def cause_label(_), do: "Unknown cause"

  # ── Page state ─────────────────────────────────────────────────────────────

  defp page_state(_loads, %{error: :no_schemas}), do: :no_schemas
  defp page_state(_loads, %{error: :unavailable}), do: :unavailable
  defp page_state(:missing_backend, _scope), do: :missing_backend
  defp page_state(loads, _scope) when is_list(loads), do: :ready

  # ── Rows ───────────────────────────────────────────────────────────────────

  defp build_row(%FailedWork{} = entry, receipts) do
    key = row_key(entry)
    receipt = Map.get(receipts, key)

    %Row{
      entry: entry,
      key: key,
      dom_id: row_dom_id(entry),
      id: entry.id,
      schema: entry.schema,
      source: entry.source,
      operation: entry.operation,
      state: entry.state,
      cause: cause(entry),
      sync_status: row_sync_status(entry.state),
      action: row_action(entry, receipt),
      receipt: receipt,
      reason: entry.reason,
      attempts: attempts_label(entry),
      last_attempt_at: entry.last_attempt_at || entry.failed_at,
      next_attempt_at: next_attempt_at(entry),
      record_ids: record_ids(entry),
      recoverable?: not is_nil(entry.recovery)
    }
  end

  # A queued retry replaces the Retry action with its receipt. Without a receipt, the job is
  # retryable when Scrypath exposes a recovery action for it.
  defp row_action(_entry, receipt) when is_map(receipt), do: :receipt
  defp row_action(%{recovery: nil}, _receipt), do: :ineligible
  defp row_action(_entry, _receipt), do: :retry

  # Failed sync work is only ever failed or retrying; it does not observe pending work, so it
  # never renders Clear or Pending.
  defp row_sync_status(:retrying), do: :retrying
  defp row_sync_status(_state), do: :failed

  defp next_attempt_at(%{state: :retrying} = row), do: Map.get(row, :next_attempt_at)
  defp next_attempt_at(_row), do: nil

  defp attempts_label(%{attempt: attempt, max_attempts: max})
       when is_integer(attempt) and is_integer(max),
       do: "#{attempt} of #{max}"

  defp attempts_label(%{attempt: attempt}) when is_integer(attempt), do: "#{attempt}"
  defp attempts_label(_row), do: nil

  defp record_ids(%{recovery: %{reference: reference}}) do
    case get_in(reference, [:payload, "document_ids"]) do
      ids when is_list(ids) -> ids
      _ -> nil
    end
  end

  defp record_ids(_row), do: nil

  # ── Scope ──────────────────────────────────────────────────────────────────

  defp visible_entries(entries, scope) do
    entries
    |> in_schema_scope(scope.schema_filter)
    |> in_cause_scope(scope.cause_filter)
    |> Enum.sort_by(
      &(&1.last_attempt_at || &1.failed_at || ~U[0001-01-01 00:00:00Z]),
      {:desc, DateTime}
    )
  end

  defp in_schema_scope(rows, []), do: rows
  defp in_schema_scope(rows, schemas), do: Enum.filter(rows, &(&1.schema in schemas))

  defp in_cause_scope(rows, []), do: rows
  defp in_cause_scope(rows, causes), do: Enum.filter(rows, &(cause(&1) in causes))

  defp load_errors(loads) when is_list(loads),
    do: for({mod, {:error, reason}} <- loads, do: {mod, reason})

  defp load_errors(_loads), do: []

  defp scoped_errors(loads, scope) do
    errors = load_errors(loads)

    case scope.schema_filter do
      [] -> errors
      schemas -> Enum.filter(errors, fn {mod, _} -> mod in schemas end)
    end
  end

  defp all_scoped_failed?(loads, scope) do
    schemas =
      case scope.schema_filter do
        [] -> scope.allowlist
        schemas -> schemas
      end

    schemas != [] and length(scoped_errors(loads, scope)) == length(schemas)
  end

  defp single_scope_schema(%{schema_filter: [mod]}), do: mod
  defp single_scope_schema(%{allowlist: [mod]}), do: mod
  defp single_scope_schema(_scope), do: nil

  # ── Facets ─────────────────────────────────────────────────────────────────

  # Schema facet counts follow the cause filter; cause facet counts follow the schema filter.
  defp schema_facets(loads, entries, scope) do
    rows = in_cause_scope(entries, scope.cause_filter)
    errors = Map.new(load_errors(loads))

    Enum.map(scope.allowlist, fn mod ->
      schema_rows = Enum.filter(rows, &(&1.schema == mod))

      %{
        module: mod,
        name: OperatorSelection.canonical(mod),
        short_name: schema_short_name(mod),
        count: length(schema_rows),
        failed: Enum.count(schema_rows, &(&1.state == :failed)),
        retrying: Enum.count(schema_rows, &(&1.state == :retrying)),
        error?: Map.has_key?(errors, mod),
        selected?: mod in scope.schema_filter
      }
    end)
  end

  defp cause_facets(entries, scope) do
    counts =
      entries
      |> in_schema_scope(scope.schema_filter)
      |> Enum.frequencies_by(&cause/1)

    @causes
    |> Enum.map(fn cause ->
      %{
        cause: cause,
        value: Atom.to_string(cause),
        label: cause_label(cause),
        count: Map.get(counts, cause, 0),
        selected?: cause in scope.cause_filter
      }
    end)
    |> Enum.filter(&(&1.count > 0 or &1.selected?))
    |> Enum.with_index()
    |> Enum.sort_by(fn {facet, index} -> {-facet.count, index} end)
    |> Enum.map(&elem(&1, 0))
  end

  # ── Summary ────────────────────────────────────────────────────────────────

  defp summary_kind(visible, entries, errors, filtered?) do
    cond do
      visible != [] -> :warning
      filtered? and entries != [] -> :neutral
      errors != [] -> :partial
      true -> :success
    end
  end

  defp summary_headline(visible, entries, errors, filtered?) do
    failed = Enum.count(visible, &(&1.state == :failed))
    retrying = Enum.count(visible, &(&1.state == :retrying))

    cond do
      visible != [] ->
        [failed > 0 && "#{failed} failed", retrying > 0 && "#{retrying} retrying"]
        |> Enum.filter(& &1)
        |> Enum.join(", ")

      filtered? and entries != [] ->
        "No sync work matches these filters"

      errors != [] ->
        "No failed or retrying sync work in the schemas that loaded"

      true ->
        "No failed or retrying sync work"
    end
  end

  defp summary_guidance(visible) do
    failed = Enum.count(visible, &(&1.state == :failed))
    retrying = Enum.count(visible, &(&1.state == :retrying))

    retry_copy =
      if Enum.any?(visible, &(&1.state == :failed and &1.recovery)), do: ", then retry", else: ""

    failed_copy =
      case failed do
        0 -> nil
        1 -> "Review the error and fix its cause#{retry_copy}."
        _ -> "Review the errors and fix their causes#{retry_copy}."
      end

    retrying_copy =
      case {failed, retrying} do
        {_, 0} -> nil
        {0, 1} -> "It will retry automatically."
        {0, _} -> "They will retry automatically."
        {_, 1} -> "The retrying item will run again automatically."
        {_, _} -> "Retrying items will run again automatically."
      end

    [failed_copy, retrying_copy] |> Enum.filter(& &1) |> Enum.join(" ")
  end

  # ── Delete confirmation ────────────────────────────────────────────────────

  defp delete_row(entries, key, receipts) when is_binary(key) do
    entries
    |> Enum.find(&(row_key(&1) == key and &1.operation == :delete and &1.recovery))
    |> case do
      nil -> nil
      entry -> build_row(entry, receipts)
    end
  end

  defp delete_row(_entries, _key, _receipts), do: nil
end
