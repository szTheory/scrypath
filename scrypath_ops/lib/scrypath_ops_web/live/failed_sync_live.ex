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

  require Logger

  alias Scrypath.Operator.FailedSyncWorkInspection
  alias Scrypath.Operator.FailedWork
  alias ScrypathOps.FailedSyncView
  alias ScrypathOps.Integrations.Sigra.Gating
  alias ScrypathOps.OperatorSelection
  alias ScrypathOpsWeb.Components.FailedSync

  @cause_params Map.new(FailedSyncView.causes(), &{Atom.to_string(&1), &1})
  @load_concurrency 4
  @load_timeout 15_000

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

    {:noreply,
     push_patch(socket,
       to: FailedSyncView.filter_path(socket.assigns.mount_path, schemas, causes)
     )}
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
    |> assign(:last_refresh_at, ScrypathOps.Clock.utc_now())
  end

  defp reload_schema(socket, mod) do
    case socket.assigns.loads do
      loads when is_list(loads) ->
        opts = Keyword.put(socket.assigns.scrypath_opts, :reason_class_counts, true)
        result = load_schema(mod, opts)

        socket
        |> assign(:loads, List.keyreplace(loads, mod, 0, {mod, result}))
        |> assign(:last_refresh_at, ScrypathOps.Clock.utc_now())

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
                put_flash(socket, :info, "A retry for job #{row.id} is already queued.")

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
            |> put_flash(:info, "Retry queued · queue job #{receipt.replacement_job}")

          {:error, reason} ->
            schema = OperatorSelection.canonical(row.schema)

            # The reason can hold backend or queue detail, so it goes to the log, never to the page.
            Logger.warning(
              "Failed sync retry did not go through for #{schema}: " <>
                inspect(reason, limit: 20, printable_limit: 500)
            )

            put_flash(socket, :error, retry_failed_copy(schema))
        end
    end
  end

  defp retry_failed_copy(schema) do
    "Retry did not go through for #{schema}. The failed work is unchanged and still listed. " <>
      "Check that the queue and Meilisearch are reachable, then retry."
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
      created_at: ScrypathOps.Clock.utc_now()
    }

    handle =
      case ScrypathOps.RecoveryObservation.register(
             recovery_host_context(socket, schema),
             receipt
           ) do
        {:ok, handle} -> handle
        _ -> nil
      end

    Map.merge(receipt, %{
      handle: handle,
      state: :accepted,
      checked_at: ScrypathOps.Clock.utc_now()
    })
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

  defp find_row(socket, params) do
    id = to_string(Map.get(params, "id", ""))
    schema = Map.get(params, "schema")
    source = Map.get(params, "source")

    matches =
      socket.assigns.loads
      |> FailedSyncView.all_rows()
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

  defp row_by_key(socket, key),
    do: Enum.find(FailedSyncView.all_rows(socket.assigns.loads), &(row_key(&1) == key))

  # The receipts map is keyed by the view's own key, so the page can show a receipt on its row.
  defp row_key(row), do: FailedSyncView.row_key(row)

  # ── Render ─────────────────────────────────────────────────────────────────

  @impl true
  def render(assigns) do
    assigns = assign(assigns, :view, view(assigns))

    ~H"""
    <FailedSync.screen
      view={@view}
      mount_path={@mount_path}
      flash={@flash}
      shell={@shell}
      page_title={@page_title}
      last_refresh_at={@last_refresh_at}
    />
    """
  end

  # The one place the clock is read for this page: every time on it is measured against this instant.
  defp view(assigns) do
    scope = %{
      error: assigns.scope_error,
      allowlist: assigns.schema_allowlist,
      schema_filter: assigns.schema_filter,
      cause_filter: assigns.cause_filter,
      delete_confirmation: assigns.delete_confirmation
    }

    FailedSyncView.build(
      assigns.loads,
      scope,
      assigns.recovery_receipts,
      ScrypathOps.Clock.utc_now()
    )
  end
end
