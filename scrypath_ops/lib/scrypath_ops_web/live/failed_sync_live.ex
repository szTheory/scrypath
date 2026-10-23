defmodule ScrypathOpsWeb.FailedSyncLive do
  @moduledoc """
  Failed sync triage across every allowlisted schema.

  Each schema is inspected with `Scrypath.failed_sync_work/2` (`reason_class_counts:
  true`) concurrently and with a bounded timeout, so one schema's load error is shown
  against that schema without hiding the others. Schema and cause filters live in
  the URL (`?schema=` may repeat or hold comma-separated values; `?cause=` likewise).
  Retry and delete stay bound to the row's own schema and index.
  """

  use ScrypathOpsWeb, :live_view

  alias Scrypath.Operator.FailedSyncWorkInspection
  alias Scrypath.Operator.FailedWork
  alias ScrypathOps.Integrations.Sigra.Gating
  alias ScrypathOps.OperatorSelection

  @causes [:validation, :transport, :backend_rejected, :queue_exhausted, :unknown]
  @cause_params Map.new(@causes, &{Atom.to_string(&1), &1})
  @load_concurrency 4
  @load_timeout 15_000
  @record_id_preview 3
  @clamp_length 240
  @known_metadata [:worker, :queue, :index, :task_uid, :type]

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Failed sync work")
      |> assign(:schema_allowlist, ScrypathOps.Schemas.allowlist())
      |> assign(:scrypath_opts, ScrypathOps.Schemas.scrypath_opts())
      |> assign(:schema_filter, [])
      |> assign(:cause_filter, [])
      |> assign(:scope_error, nil)
      |> assign(:loads, nil)
      |> assign(:context_generation, 0)
      |> assign(:last_refresh_at, nil)
      |> assign(:recovery_receipts, %{})
      |> assign(:delete_confirmation, nil)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, uri, socket) do
    {:noreply, resolve_scope(socket, params, uri)}
  end

  @impl true
  def handle_event("refresh", _params, socket) do
    socket =
      if socket.assigns.scope_error, do: socket, else: load_all(socket)

    socket =
      if loaded?(socket) and load_errors(socket) == [],
        do: put_flash(socket, :info, "Failed sync work refreshed."),
        else: socket

    {:noreply, socket}
  end

  def handle_event("filter", params, socket) do
    allowlist = ScrypathOps.Schemas.allowlist()

    schemas =
      params
      |> Map.get("schema", [])
      |> List.wrap()
      |> Enum.flat_map(fn name ->
        case Enum.find(allowlist, &(OperatorSelection.canonical(&1) == name)) do
          nil -> []
          mod -> [mod]
        end
      end)

    causes = params |> Map.get("cause", []) |> List.wrap() |> parse_causes()

    {:noreply, push_patch(socket, to: filter_path(socket.assigns.mount_path, schemas, causes))}
  end

  def handle_event("retry", params, socket) do
    {:noreply, request_retry(socket, params)}
  end

  def handle_event("confirm_retry_delete", _params, socket) do
    socket =
      case socket.assigns.delete_confirmation do
        nil ->
          socket

        key ->
          case row_by_key(socket, key) do
            %{schema: schema} = row ->
              if allowed?(schema) do
                Gating.gate_sensitive_action(socket, :failed_work_retry, fn ->
                  retry_failed_work(socket, row)
                end)
              else
                unavailable(socket)
              end

            nil ->
              put_flash(socket, :error, "Could not find that failed job.")
          end
      end

    {:noreply, normalize_live_reply(assign(socket, :delete_confirmation, nil))}
  end

  def handle_event("cancel_retry_delete", _params, socket) do
    {:noreply, assign(socket, :delete_confirmation, nil)}
  end

  # ── Scope (URL) ────────────────────────────────────────────────────────────

  defp resolve_scope(socket, params, uri) do
    allowlist = ScrypathOps.Schemas.allowlist()
    pairs = query_pairs(uri, params)
    requested = query_values(pairs, "schema")
    causes = pairs |> query_values("cause") |> parse_causes()

    resolved =
      Enum.map(requested, fn name ->
        Enum.find(allowlist, &(OperatorSelection.canonical(&1) == name))
      end)

    scope_error =
      cond do
        allowlist == [] -> :no_schemas
        Enum.any?(resolved, &is_nil/1) -> :unavailable
        true -> nil
      end

    schemas = if scope_error, do: [], else: Enum.uniq(resolved)
    allowlist_changed? = allowlist != socket.assigns.schema_allowlist

    socket =
      socket
      |> assign(:schema_allowlist, allowlist)
      |> assign(:schema_filter, schemas)
      |> assign(:cause_filter, causes)
      |> assign(:scope_error, scope_error)

    cond do
      scope_error == :unavailable ->
        unavailable(socket)

      scope_error ->
        assign(socket, :loads, nil)

      is_nil(socket.assigns.loads) or allowlist_changed? ->
        load_all(socket)

      true ->
        socket
    end
  end

  defp query_pairs(uri, params) do
    case uri && URI.parse(uri).query do
      query when is_binary(query) and query != "" ->
        query |> URI.query_decoder() |> Enum.to_list()

      _ ->
        Enum.flat_map(params, fn {key, value} -> Enum.map(List.wrap(value), &{key, &1}) end)
    end
  end

  defp query_values(pairs, key) do
    pairs
    |> Enum.filter(fn {k, _v} -> k in [key, key <> "[]"] end)
    |> Enum.flat_map(fn {_k, v} -> String.split(v, ",", trim: true) end)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
  end

  defp parse_causes(values) do
    values
    |> Enum.flat_map(fn value ->
      case Map.fetch(@cause_params, value) do
        {:ok, cause} -> [cause]
        :error -> []
      end
    end)
    |> Enum.uniq()
  end

  defp filter_path(mount_path, schemas, causes) do
    base = String.trim_trailing(mount_path, "/")

    query =
      Enum.map(schemas, &{"schema", OperatorSelection.canonical(&1)}) ++
        Enum.map(causes, &{"cause", Atom.to_string(&1)})

    case query do
      [] -> "#{base}/failed-sync"
      pairs -> "#{base}/failed-sync?#{URI.encode_query(pairs)}"
    end
  end

  defp allowed?(schema), do: schema in ScrypathOps.Schemas.allowlist()

  defp unavailable(socket) do
    invalidate_receipts(socket)

    socket
    |> assign(:scope_error, :unavailable)
    |> assign(:schema_filter, [])
    |> update(:context_generation, &(&1 + 1))
    |> assign(:loads, nil)
    |> assign(:last_refresh_at, nil)
    |> assign(:recovery_receipts, %{})
    |> assign(:delete_confirmation, nil)
  end

  defp invalidate_receipts(socket) do
    Enum.each(Map.values(Map.get(socket.assigns, :recovery_receipts, %{})), fn receipt ->
      if receipt.handle, do: ScrypathOps.RecoveryObservation.invalidate(receipt.handle)
    end)
  end

  # ── Loading ────────────────────────────────────────────────────────────────

  defp load_all(socket) do
    allowlist = socket.assigns.schema_allowlist
    opts = Keyword.put(socket.assigns.scrypath_opts, :reason_class_counts, true)

    loads =
      if Keyword.has_key?(opts, :backend) do
        allowlist
        |> Task.async_stream(&load_schema(&1, opts),
          max_concurrency: @load_concurrency,
          timeout: @load_timeout,
          on_timeout: :kill_task,
          ordered: true
        )
        |> Enum.zip(allowlist)
        |> Enum.map(fn
          {{:ok, result}, mod} -> {mod, result}
          {{:exit, :timeout}, mod} -> {mod, {:error, :timeout}}
          {{:exit, reason}, mod} -> {mod, {:error, {:exit, reason}}}
        end)
      else
        :missing_backend
      end

    socket
    |> assign(:loads, loads)
    |> assign(:last_refresh_at, DateTime.utc_now())
  end

  defp reload_schema(socket, mod) do
    case socket.assigns.loads do
      loads when is_list(loads) ->
        opts = Keyword.put(socket.assigns.scrypath_opts, :reason_class_counts, true)
        result = load_schema(mod, opts)

        socket
        |> assign(:loads, List.keyreplace(loads, mod, 0, {mod, result}))
        |> assign(:last_refresh_at, DateTime.utc_now())

      _ ->
        socket
    end
  end

  defp load_schema(mod, opts) do
    case Scrypath.failed_sync_work(mod, opts) do
      {:ok, %FailedSyncWorkInspection{entries: entries}} -> {:ok, entries}
      {:ok, rows} when is_list(rows) -> {:ok, rows}
      {:error, reason} -> {:error, reason}
    end
  rescue
    exception -> {:error, {:exception, Exception.message(exception)}}
  catch
    kind, reason -> {:error, {kind, reason}}
  end

  defp loaded?(socket), do: is_list(socket.assigns.loads)

  defp load_errors(socket) do
    case socket.assigns.loads do
      loads when is_list(loads) -> for {mod, {:error, reason}} <- loads, do: {mod, reason}
      _ -> []
    end
  end

  # ── Retry ──────────────────────────────────────────────────────────────────

  defp request_retry(socket, params) do
    schema_name = Map.get(params, "schema")

    cond do
      is_binary(schema_name) and
          not Enum.any?(
            ScrypathOps.Schemas.allowlist(),
            &(OperatorSelection.canonical(&1) == schema_name)
          ) ->
        unavailable(socket)

      true ->
        case find_row(socket, params) do
          nil ->
            Gating.gate_sensitive_action(socket, :failed_work_retry, fn ->
              put_flash(socket, :error, "Could not find that failed job.")
            end)

          row ->
            cond do
              not allowed?(row.schema) ->
                unavailable(socket)

              Map.has_key?(socket.assigns.recovery_receipts, row_key(row)) ->
                put_flash(socket, :info, "A retry for job #{row.id} is already accepted.")

              is_nil(row.recovery) ->
                put_flash(socket, :error, "That job does not expose a retry action.")

              row.operation == :delete ->
                assign(socket, :delete_confirmation, row_key(row))

              true ->
                Gating.gate_sensitive_action(socket, :failed_work_retry, fn ->
                  retry_failed_work(socket, row)
                end)
            end
        end
    end
  end

  defp retry_failed_work(socket, row) do
    case FailedWork.recovery_action(row) do
      nil ->
        put_flash(socket, :error, "That job does not expose a retry action.")

      recovery ->
        runtime_opts = ScrypathOps.Schemas.runtime_opts(socket.assigns.scrypath_opts)

        case Scrypath.retry_sync_work(recovery, runtime_opts) do
          {:ok, result} ->
            receipt = accepted_receipt(socket, row, recovery, result, runtime_opts)

            socket
            |> reload_schema(row.schema)
            |> update(:recovery_receipts, &Map.put(&1, row_key(row), receipt))
            |> put_flash(:info, "Retry accepted · queue job #{receipt.replacement_job}")

          {:error, reason} ->
            put_flash(socket, :error, "Retry failed: #{inspect(reason)}")
        end
    end
  end

  defp accepted_receipt(socket, row, recovery, result, runtime_opts) do
    task = result.task
    task_raw = task && task.raw
    task_reference = (task && task.reference) || %{}
    job_id = Map.get(task_reference, :job_id) || Map.get(task_reference, "job_id")
    raw_attempt = if is_map(task_raw), do: Map.get(task_raw, :attempt), else: nil
    expected_attempt = if is_integer(raw_attempt), do: raw_attempt + 1, else: 1
    schema = OperatorSelection.canonical(row.schema)

    index =
      recovery.index || Map.get(result.metadata || %{}, :index) || Map.get(row.metadata, :index)

    config =
      try do
        Scrypath.Config.resolve!(runtime_opts)
      rescue
        _ -> runtime_opts
      end

    receipt = %{
      replacement_job: job_id,
      attempt: expected_attempt,
      operation: recovery.operation,
      schema: Atom.to_string(row.schema),
      index: index,
      backend: Atom.to_string(recovery.backend),
      source_failure: %{
        id: row.id,
        task_uid: Map.get(row.metadata, :task_uid),
        index: Map.get(row.metadata, :index),
        operation: row.operation
      },
      accepted_result: %{job_id: job_id},
      endpoint: Keyword.get(config, :meilisearch_url),
      instance: Keyword.get(config, :oban),
      repo: oban_repo(Keyword.get(config, :oban)) || Keyword.get(config, :repo),
      prefix: oban_prefix(Keyword.get(config, :oban)),
      node: node(),
      generation: socket.assigns.context_generation,
      created_at: DateTime.utc_now()
    }

    handle =
      case ScrypathOps.RecoveryObservation.register(
             recovery_host_context(socket, schema),
             receipt
           ) do
        {:ok, handle} -> handle
        _ -> nil
      end

    Map.merge(receipt, %{handle: handle, state: :accepted, checked_at: DateTime.utc_now()})
  end

  defp recovery_host_context(socket, schema) do
    operator_context = Map.get(socket.assigns, :operator_context)
    current_scope = Map.get(socket.assigns, :current_scope, %{})

    organization =
      field(operator_context, :active_org_id) ||
        get_in(current_scope, [:active_organization, :id])

    host = (socket.host_uri && socket.host_uri.host) || "unknown"

    %{
      host: host,
      org: organization && to_string(organization),
      schema: schema,
      generation: socket.assigns.context_generation
    }
  end

  defp oban_prefix(instance), do: oban_config_field(instance, :prefix)
  defp oban_repo(instance), do: oban_config_field(instance, :repo)

  defp oban_config_field(instance, key) when is_atom(instance) and not is_nil(instance) do
    if Code.ensure_loaded?(Oban) and function_exported?(Oban, :config, 1) do
      case apply(Oban, :config, [instance]) do
        %{^key => value} -> value
        _ -> nil
      end
    end
  rescue
    _ -> nil
  end

  defp oban_config_field(_instance, _key), do: nil

  defp field(map, key) when is_map(map), do: Map.get(map, key)
  defp field(_, _), do: nil

  defp normalize_live_reply({:noreply, %Phoenix.LiveView.Socket{} = socket}), do: socket
  defp normalize_live_reply(%Phoenix.LiveView.Socket{} = socket), do: socket
  defp normalize_live_reply(other), do: other

  # ── Rows ───────────────────────────────────────────────────────────────────

  defp all_rows(assigns) do
    case Map.get(assigns, :loads) do
      loads when is_list(loads) -> for {_mod, {:ok, rows}} <- loads, row <- rows, do: row
      _ -> []
    end
  end

  defp find_row(socket, params) do
    id = to_string(Map.get(params, "id", ""))
    schema = Map.get(params, "schema")
    source = Map.get(params, "source")

    matches =
      socket.assigns
      |> all_rows()
      |> Enum.filter(fn row ->
        to_string(row.id) == id and
          (is_nil(schema) or OperatorSelection.canonical(row.schema) == schema) and
          (is_nil(source) or to_string(row.source) == source)
      end)

    case matches do
      [row] -> row
      _ -> nil
    end
  end

  defp row_by_key(socket, key), do: Enum.find(all_rows(socket.assigns), &(row_key(&1) == key))

  defp row_key(row), do: "#{OperatorSelection.canonical(row.schema)}|#{row.source}|#{row.id}"

  defp row_dom_id(row) do
    "#{OperatorSelection.canonical(row.schema)}-#{row.source}-#{row.id}"
    |> String.replace(~r/[^A-Za-z0-9_-]+/, "-")
  end

  defp in_schema_scope(rows, []), do: rows
  defp in_schema_scope(rows, schemas), do: Enum.filter(rows, &(&1.schema in schemas))

  defp in_cause_scope(rows, []), do: rows
  defp in_cause_scope(rows, causes), do: Enum.filter(rows, &(cause(&1) in causes))

  defp visible_rows(assigns) do
    assigns
    |> all_rows()
    |> in_schema_scope(assigns.schema_filter)
    |> in_cause_scope(assigns.cause_filter)
    |> Enum.sort_by(
      &(&1.last_attempt_at || &1.failed_at || ~U[0001-01-01 00:00:00Z]),
      {:desc, DateTime}
    )
  end

  defp cause(%{reason_class: class}) when class in @causes, do: class
  defp cause(_row), do: :unknown

  # Schema facet counts follow the cause filter; cause facet counts follow the schema filter.
  defp schema_facets(assigns) do
    rows = assigns |> all_rows() |> in_cause_scope(assigns.cause_filter)
    errors = Map.new(load_errors(%{assigns: assigns}))

    Enum.map(assigns.schema_allowlist, fn mod ->
      schema_rows = Enum.filter(rows, &(&1.schema == mod))

      %{
        module: mod,
        name: OperatorSelection.canonical(mod),
        short_name: schema_short_name(mod),
        count: length(schema_rows),
        failed: Enum.count(schema_rows, &(&1.state == :failed)),
        retrying: Enum.count(schema_rows, &(&1.state == :retrying)),
        error?: Map.has_key?(errors, mod),
        selected?: mod in assigns.schema_filter
      }
    end)
  end

  defp cause_facets(assigns) do
    counts =
      assigns
      |> all_rows()
      |> in_schema_scope(assigns.schema_filter)
      |> Enum.frequencies_by(&cause/1)

    @causes
    |> Enum.map(fn cause ->
      %{
        cause: cause,
        value: Atom.to_string(cause),
        label: cause_label(cause),
        count: Map.get(counts, cause, 0),
        selected?: cause in assigns.cause_filter
      }
    end)
    |> Enum.filter(&(&1.count > 0 or &1.selected?))
    |> Enum.with_index()
    |> Enum.sort_by(fn {facet, index} -> {-facet.count, index} end)
    |> Enum.map(&elem(&1, 0))
  end

  defp scoped_errors(assigns) do
    errors = load_errors(%{assigns: assigns})

    case assigns.schema_filter do
      [] -> errors
      schemas -> Enum.filter(errors, fn {mod, _} -> mod in schemas end)
    end
  end

  defp all_scoped_failed?(assigns) do
    scope =
      case assigns.schema_filter do
        [] -> assigns.schema_allowlist
        schemas -> schemas
      end

    scope != [] and length(scoped_errors(assigns)) == length(scope)
  end

  defp filtered?(assigns), do: assigns.schema_filter != [] or assigns.cause_filter != []

  defp schema_short_name(mod),
    do: mod |> OperatorSelection.canonical() |> String.split(".") |> List.last()

  defp single_scope_schema(%{schema_filter: [mod]}), do: mod
  defp single_scope_schema(%{schema_allowlist: [mod]}), do: mod
  defp single_scope_schema(_assigns), do: nil

  defp sync_and_index_path(mount_path, nil),
    do: "#{String.trim_trailing(mount_path, "/")}/sync-and-index"

  defp sync_and_index_path(mount_path, mod),
    do: OperatorSelection.path(mount_path, "sync-and-index", mod)

  # ── Copy ───────────────────────────────────────────────────────────────────

  defp summary_kind(rows, assigns) do
    cond do
      rows != [] -> :warning
      filtered?(assigns) and all_rows(assigns) != [] -> :neutral
      scoped_errors(assigns) != [] -> :partial
      true -> :success
    end
  end

  defp summary_headline(rows, assigns) do
    failed = Enum.count(rows, &(&1.state == :failed))
    retrying = Enum.count(rows, &(&1.state == :retrying))

    cond do
      rows != [] ->
        [failed > 0 && "#{failed} failed", retrying > 0 && "#{retrying} retrying"]
        |> Enum.filter(& &1)
        |> Enum.join(", ")

      filtered?(assigns) and all_rows(assigns) != [] ->
        "No sync work matches these filters"

      scoped_errors(assigns) != [] ->
        "No failed or retrying sync work in the schemas that loaded"

      true ->
        "No failed or retrying sync work"
    end
  end

  defp summary_guidance(rows) do
    failed = Enum.count(rows, &(&1.state == :failed))
    retrying = Enum.count(rows, &(&1.state == :retrying))

    retry_copy =
      if Enum.any?(rows, &(&1.state == :failed and &1.recovery)), do: ", then retry", else: ""

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

  defp cause_label(:validation), do: "Invalid data"
  defp cause_label(:transport), do: "Couldn't reach Meilisearch"
  defp cause_label(:backend_rejected), do: "Meilisearch rejected it"
  defp cause_label(:queue_exhausted), do: "Retries used up"
  defp cause_label(_), do: "Unknown cause"

  defp cause_guidance(%{recovery: nil} = row), do: cause_label(cause(row)) <> "."

  defp cause_guidance(row) do
    case {cause(row), row.state} do
      {:validation, _} -> "Invalid data: fix the record, then retry."
      {:queue_exhausted, _} -> "Retries used up. Fix the cause, then retry."
      {cause, :retrying} -> "#{cause_label(cause)}. This will retry automatically."
      {:transport, _} -> "Couldn't reach Meilisearch. Check that it's running, then retry."
      {:backend_rejected, _} -> "Meilisearch rejected it. Check the index, then retry."
      {_, _} -> "Unknown cause. Read the error, then retry."
    end
  end

  defp retry_eligibility(%{source: :meilisearch}),
    do: "Meilisearch tasks can't be retried here. Resubmit the change from your app."

  defp retry_eligibility(%{operation: :unknown}),
    do: "The operation is unknown, so this can't be retried here."

  defp retry_eligibility(_),
    do: "The job didn't keep its record IDs, so it can't be retried here."

  defp operation_label(:upsert), do: "Add or update"
  defp operation_label(:delete), do: "Delete"
  defp operation_label(_), do: "Unknown operation"

  defp state_label(:retrying), do: "Retrying"
  defp state_label(_), do: "Failed"

  defp source_label(%{source: :meilisearch, id: id}), do: "Meilisearch task ##{id}"

  defp source_label(%{metadata: metadata, id: id}) do
    case Map.get(metadata, :queue) do
      queue when is_binary(queue) and queue != "" -> "Oban #{queue} ##{id}"
      queue when is_atom(queue) and not is_nil(queue) -> "Oban #{queue} ##{id}"
      _ -> "Oban job ##{id}"
    end
  end

  defp record_ids(%{recovery: %{reference: reference}}) do
    case get_in(reference, [:payload, "document_ids"]) do
      ids when is_list(ids) -> ids
      _ -> nil
    end
  end

  defp record_ids(_row), do: nil

  defp record_count_label(row) do
    case record_ids(row) do
      nil -> nil
      [_] -> "1 record"
      ids -> "#{length(ids)} records"
    end
  end

  defp record_id_preview(row) do
    case record_ids(row) do
      nil ->
        nil

      [] ->
        nil

      ids ->
        shown = ids |> Enum.take(@record_id_preview) |> Enum.map_join(", ", &to_string/1)
        extra = length(ids) - @record_id_preview
        {shown, if(extra > 0, do: " and #{extra} more")}
    end
  end

  defp clamp?(reason) when is_binary(reason),
    do: String.length(reason) > @clamp_length or length(String.split(reason, "\n")) > 3

  defp clamp?(_reason), do: false

  defp detail_facts(row) do
    metadata = row.metadata || %{}

    known =
      [
        {"Worker", Map.get(metadata, :worker)},
        {"Meilisearch index", Map.get(metadata, :index) || (row.recovery && row.recovery.index)},
        {"Attempts", attempts_label(row)},
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

  defp attempts_label(%{attempt: attempt, max_attempts: max})
       when is_integer(attempt) and is_integer(max),
       do: "#{attempt} of #{max}"

  defp attempts_label(%{attempt: attempt}) when is_integer(attempt), do: "#{attempt}"
  defp attempts_label(_row), do: nil

  defp humanize_key(key) do
    key |> to_string() |> String.replace("_", " ") |> String.capitalize()
  end

  defp display_value(value) when is_binary(value), do: value
  defp display_value(value) when is_atom(value), do: OperatorSelection.canonical(value)
  defp display_value(value), do: inspect(value)

  defp job_args(%{recovery: %{reference: %{payload: payload}}}) when is_map(payload) do
    case Jason.encode(payload, pretty: true) do
      {:ok, json} -> json
      _ -> inspect(payload, pretty: true)
    end
  end

  defp job_args(_row), do: nil

  defp load_error_text(reason), do: inspect(reason, pretty: true)

  # ── Delete confirmation ────────────────────────────────────────────────────

  defp delete_confirmation_row(assigns) do
    case assigns.delete_confirmation do
      key when is_binary(key) ->
        assigns
        |> all_rows()
        |> Enum.find(&(row_key(&1) == key and &1.operation == :delete and &1.recovery))

      _ ->
        nil
    end
  end

  defp delete_confirmation_ids(row),
    do: get_in(row.recovery.reference, [:payload, "document_ids"]) || []

  defp delete_confirmation_index(row),
    do: row.recovery.index || Map.get(row.metadata, :index) || "unknown"

  defp delete_confirmation_description(row) do
    count = length(delete_confirmation_ids(row))

    "Retry deletion of #{count} documents for #{OperatorSelection.canonical(row.schema)} in #{delete_confirmation_index(row)}."
  end

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

  # ── Render ─────────────────────────────────────────────────────────────────

  @impl true
  def render(assigns) do
    rows = visible_rows(assigns)
    any_rows? = all_rows(assigns) != []
    filtered? = filtered?(assigns)

    assigns =
      assigns
      |> assign(:rows, rows)
      |> assign(:errors, scoped_errors(assigns))
      |> assign(:all_failed?, all_scoped_failed?(assigns))
      |> assign(:filtered?, filtered?)
      |> assign(:filtered_out?, rows == [] and filtered? and any_rows?)
      |> assign(
        :hidden_count,
        if(filtered?, do: length(all_rows(assigns)) - length(rows), else: 0)
      )
      |> assign(:show_filters?, any_rows? or filtered?)
      |> assign(:summary_kind, summary_kind(rows, assigns))
      |> assign(:summary_headline, summary_headline(rows, assigns))
      |> assign(:schema_facets, schema_facets(assigns))
      |> assign(:cause_facets, cause_facets(assigns))
      |> assign(:handoff_schema, single_scope_schema(assigns))
      |> assign(:delete_row, delete_confirmation_row(assigns))

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

      <.ops_empty_state :if={@scope_error == :no_schemas} title="No schemas configured.">
        Add allowlisted schema modules with
        <.ops_inline_code>schema_allowlist</.ops_inline_code>
        in <.ops_inline_code>:scrypath_ops</.ops_inline_code>, then refresh failed sync jobs.
      </.ops_empty_state>

      <.ops_status
        :if={@scope_error == :unavailable}
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

      <.ops_empty_state :if={@loads == :missing_backend} title="Runtime not configured">
        Configure the Scrypath runtime under
        <.ops_inline_code>:scrypath_ops</.ops_inline_code>
        — see <.ops_inline_code>scrypath_ops/README.md</.ops_inline_code>, then refresh.
      </.ops_empty_state>

      <div :if={is_list(@loads)} class="space-y-ops-page-gap">
        <.ops_status
          :for={{mod, reason} <- @errors}
          kind={:error}
          title={"Failed sync work could not load for #{schema_short_name(mod)}"}
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
            label={"Load error for #{schema_short_name(mod)}"}
            text={load_error_text(reason)}
            copy
            inline_copy
            copy_label="Copy error"
            copy_success="Error copied"
          />
        </.ops_status>

        <section
          :if={not @all_failed?}
          aria-labelledby="failed-sync-summary-heading"
          class="space-y-3"
        >
          <.ops_verdict
            kind={@summary_kind}
            headline={@summary_headline}
            headline_id="failed-sync-summary-heading"
            data-testid="failed-sync-summary"
          >
            <span :if={@rows != []}>{summary_guidance(@rows)}</span>
            <span :if={@rows != [] and @hidden_count > 0} data-testid="failed-sync-filter-note">
              {@hidden_count} more hidden by filters.
              <.link
                patch={filter_path(@mount_path, [], [])}
                class="link underline underline-offset-2"
              >
                Clear filters
              </.link>
            </span>
            <span :if={@filtered_out?}>
              <.link
                patch={filter_path(@mount_path, [], [])}
                class="link underline underline-offset-2"
              >
                Clear filters
              </.link>
              to see all failed and retrying work.
            </span>
            <span :if={@rows == [] and not @filtered_out?}>
              No failures were found in the available history. Pending work and document freshness are checked on Sync and index.
            </span>
          </.ops_verdict>

          <.form
            :if={@show_filters?}
            for={%{}}
            id="failed-sync-filters"
            phx-change="filter"
            class="ops-failed-filters"
          >
            <fieldset :if={length(@schema_allowlist) > 1} class="ops-failed-filters__group">
              <legend class="ops-failed-filters__legend">Schema</legend>
              <label
                :for={facet <- @schema_facets}
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
              :if={@cause_facets != []}
              class="ops-failed-filters__group"
            >
              <legend class="ops-failed-filters__legend">Cause</legend>
              <label
                :for={facet <- @cause_facets}
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
        </section>

        <section
          :if={@rows != []}
          aria-labelledby="failed-sync-list-heading"
          class="ops-failed-list"
        >
          <h2 id="failed-sync-list-heading" class="sr-only">Failed and retrying sync work</h2>
          <article
            :for={row <- @rows}
            id={"failed-row-#{row_dom_id(row)}"}
            class="ops-failed-row"
            data-testid="failed-sync-row"
            data-state={row.state}
          >
            <div class="ops-failed-row__facts">
              <.ops_badge kind={if row.state == :retrying, do: :warning, else: :error}>
                {state_label(row.state)}
              </.ops_badge>
              <h3 class="ops-failed-row__title">
                <span title={OperatorSelection.canonical(row.schema)}>
                  {schema_short_name(row.schema)}
                </span>
                <span aria-hidden="true">·</span>
                {operation_label(row.operation)}
              </h3>
              <span class="ops-failed-row__sep" aria-hidden="true">·</span>
              <span>{source_label(row)}</span>
              <span :if={record_count_label(row)} class="ops-failed-row__sep" aria-hidden="true">
                ·
              </span>
              <span :if={record_count_label(row)} data-testid="failed-sync-records">
                {record_count_label(row)}<span :if={preview = record_id_preview(row)}>:
                  <code class="ops-failed-row__ids">{elem(preview, 0)}</code>{elem(preview, 1)}</span>
              </span>
              <span class="ops-failed-row__sep" aria-hidden="true">·</span>
              <span class="ops-failed-row__time">
                <span class="sr-only">Last attempt</span>
                <.ops_time
                  id={"failed-attempt-#{row_dom_id(row)}"}
                  dt={row.last_attempt_at || row.failed_at}
                  state_text="No attempt time recorded"
                  operational
                />
              </span>
            </div>

            <div :if={row.reason} class="ops-failed-row__error">
              <.ops_code_block
                id={"failed-reason-#{row_dom_id(row)}"}
                variant={:compact}
                label="Error"
                text={row.reason}
                copy
                inline_copy
                clamp={clamp?(row.reason)}
                copy_label="Copy error"
                copy_success="Error copied"
                data-testid="failed-sync-reason"
              />
            </div>

            <div
              :if={row.recovery && is_nil(@recovery_receipts[row_key(row)])}
              class="ops-failed-row__actions"
            >
              <.ops_button
                phx-click="retry"
                phx-value-id={row.id}
                phx-value-schema={OperatorSelection.canonical(row.schema)}
                phx-value-source={row.source}
                data-testid="failed-sync-retry"
                variant={:default}
                size={:sm}
              >
                Retry
              </.ops_button>
            </div>

            <.ops_status
              :if={receipt = @recovery_receipts[row_key(row)]}
              class="ops-failed-row__receipt"
              kind={:info}
              title="Retry queued"
              role="status"
              data-testid="recovery-receipt"
            >
              Oban job #{receipt.replacement_job} will {if receipt.operation == :delete,
                do: "delete",
                else: "add or update"} records in <.ops_inline_code>{receipt.index}</.ops_inline_code>.
              Completion has not been confirmed. Original job #{row.id} is retained.
              <.link
                :if={receipt.handle}
                navigate={recovery_handoff_path(@mount_path, row.schema, receipt)}
                class="ml-2 min-h-ops-control link link-primary underline underline-offset-2"
              >
                Check sync status
              </.link>
            </.ops_status>

            <div class="ops-failed-row__foot">
              <p class="ops-failed-row__guidance">
                {cause_guidance(row)}
                <span :if={is_nil(row.recovery)} data-testid="failed-sync-eligibility">
                  {retry_eligibility(row)}
                </span>
              </p>
              <.ops_disclosure
                id={"failed-detail-#{row_dom_id(row)}"}
                summary="More details"
                variant={:compact}
                class="ops-failed-row__details"
              >
                <dl :if={detail_facts(row) != []} class="ops-failed-details">
                  <div :for={{label, value} <- detail_facts(row)}>
                    <dt>{label}</dt>
                    <dd>{value}</dd>
                  </div>
                </dl>
                <.ops_code_block
                  :if={job_args(row)}
                  class="mt-2"
                  variant={:compact}
                  label="Job args"
                  text={job_args(row)}
                  copy
                  inline_copy
                  copy_label="Copy job args"
                  copy_success="Job args copied"
                />
                <p :if={detail_facts(row) == [] and is_nil(job_args(row))}>
                  No further details were recorded.
                </p>
              </.ops_disclosure>
            </div>
          </article>
        </section>

        <p :if={@rows != []} class="ops-search-query-hint">
          <.ops_help_link href={"#{@mount_path}/help#recovery"}>
            Help with sync failures and recovery
          </.ops_help_link>
        </p>
      </div>

      <.ops_handoff :if={is_list(@loads)}>
        <:step
          navigate={sync_and_index_path(@mount_path, @handoff_schema)}
          hint="Check pending work and index settings —"
        >
          Check sync and index
        </:step>
      </.ops_handoff>

      <.ops_modal
        :if={@delete_row}
        id="retry-delete-modal"
        title="Confirm delete sync work"
        description={delete_confirmation_description(@delete_row)}
        action_label="retry delete"
        initial_focus="[data-ops-modal-cancel]"
        cancel_event="cancel_retry_delete"
      >
        <.form for={%{}} phx-submit="confirm_retry_delete" class="space-y-3">
          <div class="rounded-ops-surface border border-base-300 p-ops-3 text-ops-body">
            <p>
              Schema
              <.ops_inline_code>{OperatorSelection.canonical(@delete_row.schema)}</.ops_inline_code>
            </p>
            <p>
              Index
              <.ops_inline_code>{delete_confirmation_index(@delete_row)}</.ops_inline_code>
            </p>
            <p>{length(delete_confirmation_ids(@delete_row))} documents</p>
            <ul class="mt-2 list-inside list-disc break-all font-mono text-ops-sm">
              <li :for={document_id <- delete_confirmation_ids(@delete_row)}>
                {inspect(document_id)}
              </li>
            </ul>
          </div>
          <div class="flex justify-between gap-2">
            <.ops_button
              type="button"
              phx-click="cancel_retry_delete"
              variant={:ghost}
              aria-label="Keep failed work and close"
              data-ops-modal-cancel
            >
              Keep failed work and close
            </.ops_button>
            <.ops_button type="submit" variant={:danger}>Retry delete sync work</.ops_button>
          </div>
        </.form>
      </.ops_modal>
    </Layouts.app>
    """
  end
end
