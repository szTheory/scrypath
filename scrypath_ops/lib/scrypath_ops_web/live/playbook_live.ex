defmodule ScrypathOpsWeb.PlaybookLive do
  @moduledoc """
  Operator playbook library at `/ops/playbooks`: import, preview, run, and (when configured)
  persist JSON playbooks under `:playbook_workspace_dir`.

  ## Delete confirmation

  Deleting a workspace file requires typing the exact basename into the confirmation
  field and submitting **Confirm delete** — see UI-SPEC destructive copy.
  """

  use ScrypathOpsWeb, :live_view

  alias ScrypathOps.Playbook.DocResolver
  alias ScrypathOps.Playbook.RunFailure
  alias ScrypathOps.Playbook.Runner
  alias ScrypathOps.Playbook.Store
  alias ScrypathOps.Playbook.V1
  alias ScrypathOps.Integrations.Sigra.Gating
  alias ScrypathOps.Schemas
  alias Scrypath.MultiSearchResult
  alias Scrypath.SearchResult

  @max_import_bytes 256_000
  @playbook_run_async_key :playbook_run
  # Named async key keeps run cancellation and result routing explicit.
  @playbook_run_timeout_ms 60_000

  @impl true
  def mount(_params, _session, socket) do
    workspace_root = Application.get_env(:scrypath_ops, :playbook_workspace_dir)
    examples_dir = examples_playbooks_dir()
    workspace_writable? = workspace_root != nil
    {files, examples_mode?} = list_workspace_files(workspace_root, examples_dir)
    catalog = build_catalog_entries(workspace_root, examples_dir, files, examples_mode?)
    playbook_schema_doc = DocResolver.resolve(:playbook_schema)

    socket =
      socket
      |> assign(:page_title, "Saved playbooks")
      |> assign(:workspace_root, workspace_root)
      |> assign(:examples_dir, examples_dir)
      |> assign(:workspace_writable?, workspace_writable?)
      |> assign(:examples_mode?, examples_mode?)
      |> assign(:workspace_files, files)
      |> assign(:catalog_entries, catalog)
      |> assign(:rename_modal, nil)
      |> assign(:duplicate_modal, nil)
      |> assign(:schema_allowlist, Schemas.allowlist())
      |> assign(:scrypath_opts, Schemas.scrypath_opts())
      |> assign(:draft_playbook, nil)
      |> assign(:preview_json, nil)
      |> assign(:preview_marker, false)
      |> assign(:selected_basename, nil)
      |> assign(:run_result, nil)
      |> assign(:run_error, nil)
      |> assign(:run_failure_enriched, nil)
      |> assign(:run_ui, %{phase: :idle, run_id: 0, started_monotonic: nil})
      |> assign(:delete_pending, nil)
      |> assign(:save_basename, "")
      |> assign(:playbook_schema_doc, playbook_schema_doc)
      |> assign(:max_import_bytes, @max_import_bytes)
      |> allow_upload(:playbook_file,
        accept: ~w(.json),
        max_entries: 1,
        max_file_size: @max_import_bytes,
        auto_upload: false
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("import_paste", %{"json" => raw}, socket) do
    socket = maybe_supersede_running_run(socket)
    bin = raw |> to_string()

    if byte_size(bin) > @max_import_bytes do
      {:noreply, put_flash(socket, :error, "Paste exceeds the maximum import size.")}
    else
      {:noreply, apply_decoded(socket, bin, :paste)}
    end
  end

  def handle_event("import_upload", _params, socket) do
    socket = maybe_supersede_running_run(socket)

    consume_uploaded_entries(socket, :playbook_file, fn %{path: path}, _entry ->
      case File.read(path) do
        {:ok, bin} -> {:ok, bin}
        {:error, _} -> {:error, :read_failed}
      end
    end)
    |> case do
      {socket, []} ->
        {:noreply, put_flash(socket, :error, "Choose a JSON file first.")}

      {socket, [bin]} when is_binary(bin) ->
        {:noreply, apply_decoded(socket, bin, :upload)}

      {socket, [{:error, _}]} ->
        {:noreply, put_flash(socket, :error, "Could not read the uploaded file.")}

      {socket, _} ->
        {:noreply, put_flash(socket, :error, "Unexpected upload result.")}
    end
  end

  def handle_event("load", %{"name" => name}, socket) do
    socket = maybe_supersede_running_run(socket)
    name = to_string(name)

    cond do
      not Store.safe_basename?(name) ->
        {:noreply, put_flash(socket, :error, "Invalid playbook file name.")}

      socket.assigns.workspace_root ->
        case Store.read_workspace_file(socket.assigns.workspace_root, name) do
          {:ok, bin} ->
            socket =
              socket
              |> assign(:selected_basename, name)
              |> apply_decoded(bin, :load)

            {:noreply, socket}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Could not read that playbook file.")}
        end

      socket.assigns.examples_dir ->
        path = Path.join(socket.assigns.examples_dir, name)

        if Store.safe_basename?(name) and File.exists?(path) do
          {:ok, bin} = File.read(path)

          socket =
            socket
            |> assign(:selected_basename, name)
            |> apply_decoded(bin, :load)

          {:noreply, socket}
        else
          {:noreply, put_flash(socket, :error, "Could not read that example file.")}
        end

      true ->
        {:noreply, put_flash(socket, :error, "No playbook directory is configured.")}
    end
  end

  def handle_event("run_now", %{"name" => name}, socket) do
    socket = maybe_supersede_running_run(socket)
    name = to_string(name)

    with :ok <- validate_catalog_name(name),
         {:ok, bin} <- read_catalog_playbook(socket, name),
         {:ok, validated} <- decode_and_validate_playbook(bin),
         preview <- Jason.encode!(validated, pretty: true) do
      socket =
        socket
        |> assign(:selected_basename, name)
        |> assign(:draft_playbook, validated)
        |> assign(:preview_json, preview)
        |> assign(:preview_marker, true)
        |> put_flash(:info, flash_for_import(:load))
        |> schedule_playbook_run()

      {:noreply, socket}
    else
      {:error, :invalid_name} ->
        {:noreply, put_flash(socket, :error, "Invalid playbook file name.")}

      {:error, :read_failed} ->
        {:noreply, put_flash(socket, :error, "Could not read that playbook file.")}

      {:error, :invalid_json} ->
        {:noreply, put_flash(socket, :error, "This file is not valid playbook JSON.")}

      {:error, {:invalid_playbook, reason}} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "Playbook failed validation: #{format_validation_reason(reason)}"
         )}
    end
  end

  def handle_event("run", _params, socket) do
    {:noreply, schedule_playbook_run(socket)}
  end

  def handle_event("cancel_run", _params, socket) do
    {:noreply, cancel_active_run(socket, {:shutdown, :cancel})}
  end

  def handle_event(
        "copy_run_diagnostics",
        _params,
        %{assigns: %{run_failure_enriched: nil}} = socket
      ) do
    {:noreply, socket}
  end

  def handle_event("copy_run_diagnostics", _params, socket) do
    payload =
      socket.assigns.run_failure_enriched
      |> diagnostics_payload()
      |> Jason.encode!()

    {:noreply,
     socket
     |> push_event("copy_run_diagnostics", %{text: payload})
     |> put_flash(:info, "Copied diagnostics.")}
  end

  def handle_event("save", %{"basename" => basename}, socket) do
    basename = basename |> to_string() |> String.trim()
    root = socket.assigns.workspace_root

    cond do
      not socket.assigns.workspace_writable? ->
        {:noreply,
         put_flash(socket, :error, "Saving requires a configured playbook workspace directory.")}

      not Store.safe_basename?(basename) ->
        {:noreply, put_flash(socket, :error, "Filename must match *.json basename rules.")}

      socket.assigns.draft_playbook == nil ->
        {:noreply,
         put_flash(socket, :error, "Nothing to save — import or load a playbook first.")}

      true ->
        case V1.encode(socket.assigns.draft_playbook) do
          {:ok, json} ->
            case Store.save_workspace_file(root, basename, json <> "\n") do
              :ok ->
                {:noreply,
                 socket
                 |> reload_workspace_catalog()
                 |> assign(:save_basename, "")
                 |> put_flash(:info, "Saved #{basename}")}

              {:error, _} ->
                {:noreply,
                 put_flash(socket, :error, "Save failed — check directory permissions.")}
            end

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Could not encode playbook for saving.")}
        end
    end
  end

  def handle_event("request_delete", %{"name" => name}, socket) do
    name = to_string(name)

    if Store.safe_basename?(name) do
      {:noreply, assign(socket, :delete_pending, name)}
    else
      {:noreply, put_flash(socket, :error, "Invalid playbook file name.")}
    end
  end

  def handle_event("cancel_delete", _params, socket) do
    {:noreply, assign(socket, :delete_pending, nil)}
  end

  def handle_event("confirm_delete", %{"confirm" => typed}, socket) do
    socket =
      Gating.gate_sensitive_action(socket, :playbook_delete, fn ->
        confirm_delete(socket, typed)
      end)

    {:noreply, normalize_live_reply(socket)}
  end

  def handle_event("refresh_list", _params, socket) do
    {:noreply, reload_workspace_catalog(socket)}
  end

  def handle_event("rename_open", %{"name" => name}, socket) do
    name = to_string(name)

    if Store.safe_basename?(name) do
      {:noreply, assign(socket, :rename_modal, %{from: name})}
    else
      {:noreply, put_flash(socket, :error, "Invalid playbook file name.")}
    end
  end

  def handle_event("rename_cancel", _, socket) do
    {:noreply, assign(socket, :rename_modal, nil)}
  end

  def handle_event("rename_submit", %{"new_name" => new_name}, socket) do
    case socket.assigns.rename_modal do
      nil ->
        {:noreply, socket}

      %{from: from} ->
        rename_submit_impl(socket, from, new_name)
    end
  end

  def handle_event("dup_open", %{"name" => name}, socket) do
    name = to_string(name)
    root = socket.assigns.workspace_root

    cond do
      not Store.safe_basename?(name) ->
        {:noreply, put_flash(socket, :error, "Invalid playbook file name.")}

      not socket.assigns.workspace_writable? or root == nil ->
        {:noreply, put_flash(socket, :error, "Duplicate requires a writable workspace.")}

      true ->
        case Store.suggest_duplicate_basename(root, name) do
          {:ok, suggested} ->
            {:noreply, assign(socket, :duplicate_modal, %{from: name, to: suggested})}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Could not suggest a duplicate filename.")}
        end
    end
  end

  def handle_event("dup_cancel", _, socket) do
    {:noreply, assign(socket, :duplicate_modal, nil)}
  end

  def handle_event("dup_submit", %{"to_name" => to_name}, socket) do
    case socket.assigns.duplicate_modal do
      nil ->
        {:noreply, socket}

      %{from: from} ->
        dup_submit_impl(socket, from, to_name)
    end
  end

  @impl true
  def handle_async({@playbook_run_async_key, run_id}, {:ok, {:ok, result}}, socket) do
    if active_run?(socket, run_id) do
      emit_run_stop(socket.assigns.run_ui, run_id, :ok)

      {:noreply,
       socket
       |> assign(:run_result, result)
       |> assign(:run_error, nil)
       |> assign(:run_failure_enriched, nil)
       |> assign(:run_ui, %{phase: :ok, run_id: run_id, started_monotonic: nil})
       |> put_flash(:info, "Playbook run completed.")}
    else
      {:noreply, socket}
    end
  end

  def handle_async({@playbook_run_async_key, run_id}, {:ok, {:error, reason}}, socket) do
    if active_run?(socket, run_id) do
      emit_run_stop(socket.assigns.run_ui, run_id, :error)
      enriched = enrich_run_failure(reason, socket)

      {:noreply,
       socket
       |> assign(:run_result, nil)
       |> assign(:run_error, reason)
       |> assign(:run_failure_enriched, enriched)
       |> assign(:run_ui, %{phase: :error, run_id: run_id, started_monotonic: nil})
       |> put_flash(:error, format_run_flash(reason))}
    else
      {:noreply, socket}
    end
  end

  def handle_async({@playbook_run_async_key, run_id}, {:exit, reason}, socket) do
    if active_run?(socket, run_id) do
      normalized = normalize_async_exit(reason)
      emit_run_stop(socket.assigns.run_ui, run_id, telemetry_result(normalized))
      enriched = enrich_run_failure(normalized, socket)

      {:noreply,
       socket
       |> assign(:run_result, nil)
       |> assign(:run_error, normalized)
       |> assign(:run_failure_enriched, enriched)
       |> assign(:run_ui, %{phase: :error, run_id: run_id, started_monotonic: nil})
       |> maybe_put_run_exit_flash(normalized)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:playbook_run_timeout, run_id}, socket) do
    if active_run?(socket, run_id) do
      socket = cancel_active_run(socket, {:shutdown, :timeout})
      emit_run_stop(socket.assigns.run_ui, run_id, :timeout)
      enriched = enrich_run_failure(:timed_out, socket)

      {:noreply,
       socket
       |> assign(:run_result, nil)
       |> assign(:run_error, :timed_out)
       |> assign(:run_failure_enriched, enriched)
       |> assign(:run_ui, %{phase: :error, run_id: run_id, started_monotonic: nil})
       |> put_flash(:error, format_run_flash(:timed_out))}
    else
      {:noreply, socket}
    end
  end

  defp apply_decoded(socket, bin, source) do
    case decode_and_validate_playbook(bin) do
      {:ok, validated} ->
        preview = Jason.encode!(validated, pretty: true)

        socket
        |> assign(:draft_playbook, validated)
        |> assign(:preview_json, preview)
        |> assign(:preview_marker, true)
        |> assign(:run_failure_enriched, nil)
        |> put_flash(:info, flash_for_import(source))

      {:error, {:invalid_playbook, reason}} ->
        socket
        |> assign(:draft_playbook, nil)
        |> assign(:preview_json, nil)
        |> assign(:preview_marker, false)
        |> assign(:run_failure_enriched, nil)
        |> put_flash(
          :error,
          "Playbook failed validation: #{format_validation_reason(reason)}"
        )

      {:error, :invalid_json} ->
        socket
        |> assign(:run_failure_enriched, nil)
        |> put_flash(:error, "This file is not valid playbook JSON.")
    end
  end

  defp flash_for_import(:paste), do: "Imported playbook from paste."
  defp flash_for_import(:upload), do: "Imported playbook from file."
  defp flash_for_import(:load), do: "Loaded playbook from disk."

  defp rename_submit_impl(socket, from, new_name) do
    new_name = new_name |> to_string() |> String.trim()
    root = socket.assigns.workspace_root

    cond do
      not socket.assigns.workspace_writable? or root == nil ->
        {:noreply, put_flash(socket, :error, "Rename requires a writable workspace.")}

      not Store.safe_basename?(new_name) ->
        {:noreply, put_flash(socket, :error, "Filename must match *.json basename rules.")}

      true ->
        case Store.rename_workspace_file(root, from, new_name) do
          :ok ->
            socket =
              socket
              |> assign(:rename_modal, nil)
              |> reload_workspace_catalog()

            socket =
              if socket.assigns.selected_basename == from do
                assign(socket, :selected_basename, new_name)
              else
                socket
              end

            {:noreply, put_flash(socket, :info, "Renamed to #{new_name}")}

          {:error, :target_exists} ->
            {:noreply,
             put_flash(
               socket,
               :error,
               "That playbook name is already in use — pick another basename."
             )}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Rename failed — check permissions.")}
        end
    end
  end

  defp dup_submit_impl(socket, from, to_name) do
    to_name = to_name |> to_string() |> String.trim()
    root = socket.assigns.workspace_root

    cond do
      not socket.assigns.workspace_writable? or root == nil ->
        {:noreply, put_flash(socket, :error, "Duplicate requires a writable workspace.")}

      not Store.safe_basename?(to_name) ->
        {:noreply, put_flash(socket, :error, "Filename must match *.json basename rules.")}

      true ->
        case Store.duplicate_workspace_file(root, from, to_name) do
          :ok ->
            {:noreply,
             socket
             |> assign(:duplicate_modal, nil)
             |> reload_workspace_catalog()
             |> put_flash(:info, "Duplicated to #{to_name}")}

          {:error, :target_exists} ->
            {:noreply,
             put_flash(
               socket,
               :error,
               "That playbook name is already in use — pick another basename."
             )}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Duplicate failed — check permissions.")}
        end
    end
  end

  defp format_validation_reason(reason) do
    reason |> inspect() |> String.slice(0, 240)
  end

  defp format_run_flash({:page_size_out_of_range, n, max}),
    do: "Playbook run failed: page.size #{n} is outside 1..#{max}."

  defp format_run_flash({:config, :missing_backend}),
    do: "Playbook run failed: Scrypath backend is not configured."

  defp format_run_flash({:config, :empty_allowlist}),
    do: "Playbook run failed: schema allowlist is empty."

  defp format_run_flash({:config, :no_schema}),
    do: "Playbook run failed: schema is not on the configured allowlist."

  defp format_run_flash({:config, :invalid_query}),
    do: "Playbook run failed: query field is invalid."

  defp format_run_flash({:config, :invalid_entries}),
    do: "Playbook run failed: entries list is invalid."

  defp format_run_flash({:config, :invalid_entry_shape}),
    do: "Playbook run failed: an entry has an invalid shape."

  defp format_run_flash(:cancelled),
    do: "Playbook run cancelled before a result was applied."

  defp format_run_flash(:timed_out),
    do: "Playbook run timed out before a result was applied."

  defp format_run_flash(other),
    do:
      "Playbook run failed: #{inspect(other)} — adjust entries or operator config, then run again."

  defp list_workspace_files(nil, examples_dir) do
    files =
      if examples_dir && File.dir?(examples_dir) do
        examples_dir
        |> File.ls!()
        |> Enum.filter(&Store.safe_basename?/1)
        |> Enum.sort()
      else
        []
      end

    {files, true}
  end

  defp list_workspace_files(root, _examples) when is_binary(root) do
    case Store.list_workspace_json(root) do
      {:ok, files} -> {files, false}
      {:error, _} -> {[], false}
    end
  end

  defp reload_workspace_catalog(socket) do
    a = socket.assigns
    {files, examples_mode?} = list_workspace_files(a.workspace_root, a.examples_dir)

    socket
    |> assign(:workspace_files, files)
    |> assign(:examples_mode?, examples_mode?)
    |> assign(
      :catalog_entries,
      build_catalog_entries(a.workspace_root, a.examples_dir, files, examples_mode?)
    )
  end

  defp build_catalog_entries(nil, examples_dir, files, true) when is_binary(examples_dir) do
    Enum.map(files, &catalog_row_for_examples_file(examples_dir, &1))
  end

  defp build_catalog_entries(root, _examples_dir, files, _ex?) when is_binary(root) do
    Enum.map(files, &catalog_row_for_workspace_file(root, &1))
  end

  defp build_catalog_entries(_, _, files, _) do
    Enum.map(files, &default_catalog_row/1)
  end

  defp default_catalog_row(name) do
    %{name: name, display_title: "Untitled playbook", description: "", readable?: false}
  end

  defp catalog_row_for_workspace_file(root, name) do
    case Store.read_workspace_file(root, name) do
      {:ok, bin} -> playbook_row_from_json(bin, name)
      _ -> default_catalog_row(name)
    end
  end

  defp catalog_row_for_examples_file(dir, name) do
    path = Path.join(dir, name)

    case File.read(path) do
      {:ok, bin} -> playbook_row_from_json(bin, name)
      _ -> default_catalog_row(name)
    end
  end

  defp playbook_row_from_json(bin, name) do
    with {:ok, map} <- Jason.decode(bin),
         {:ok, validated} <- V1.validate(map) do
      title = Map.get(validated, "title")

      display_title =
        case title do
          t when is_binary(t) ->
            trimmed = String.trim(t)
            if trimmed != "", do: trimmed, else: "Untitled playbook"

          _ ->
            "Untitled playbook"
        end

      desc =
        case Map.get(validated, "description") do
          d when is_binary(d) -> d
          _ -> ""
        end

      %{name: name, display_title: display_title, description: desc, readable?: true}
    else
      _ ->
        %{name: name, display_title: "Untitled playbook", description: "", readable?: false}
    end
  end

  defp examples_playbooks_dir do
    Application.app_dir(:scrypath_ops, "priv/playbooks")
  end

  defp validate_catalog_name(name) do
    if Store.safe_basename?(name), do: :ok, else: {:error, :invalid_name}
  end

  defp read_catalog_playbook(socket, name) do
    cond do
      socket.assigns.workspace_root ->
        case Store.read_workspace_file(socket.assigns.workspace_root, name) do
          {:ok, bin} -> {:ok, bin}
          {:error, _} -> {:error, :read_failed}
        end

      socket.assigns.examples_dir ->
        path = Path.join(socket.assigns.examples_dir, name)

        if Store.safe_basename?(name) and File.exists?(path) do
          File.read(path)
        else
          {:error, :read_failed}
        end

      true ->
        {:error, :read_failed}
    end
    |> normalize_catalog_read()
  end

  defp normalize_catalog_read({:ok, bin}) when is_binary(bin), do: {:ok, bin}
  defp normalize_catalog_read(_), do: {:error, :read_failed}

  defp decode_and_validate_playbook(bin) do
    case Jason.decode(bin) do
      {:ok, %{} = map} -> V1.validate(map)
      {:ok, _} -> {:error, :invalid_json}
      {:error, _} -> {:error, :invalid_json}
    end
  end

  defp schedule_playbook_run(socket) do
    case socket.assigns do
      %{draft_playbook: nil} ->
        put_flash(socket, :error, "Import or load a playbook before running.")

      %{run_ui: %{phase: :running}} ->
        socket

      assigns ->
        run_id = next_run_id(assigns.run_ui)
        draft = assigns.draft_playbook
        allowlist = assigns.schema_allowlist
        scrypath_opts = assigns.scrypath_opts

        Process.send_after(self(), {:playbook_run_timeout, run_id}, @playbook_run_timeout_ms)

        socket
        |> assign(:run_result, nil)
        |> assign(:run_error, nil)
        |> assign(:run_failure_enriched, nil)
        |> assign(:run_ui, %{phase: :running, run_id: run_id, started_monotonic: now_ms()})
        |> tap(fn _ -> emit_run_start(run_id) end)
        |> start_async(run_async_key(run_id), fn ->
          Runner.run_validated(draft, allowlist, scrypath_opts)
        end)
    end
  end

  defp maybe_supersede_running_run(%{assigns: %{run_ui: %{phase: :running}}} = socket) do
    next_id = next_run_id(socket.assigns.run_ui)
    emit_run_stop(socket.assigns.run_ui, socket.assigns.run_ui.run_id, :cancelled)

    socket
    |> cancel_active_run({:shutdown, :superseded})
    |> assign(:run_result, nil)
    |> assign(:run_error, nil)
    |> assign(:run_failure_enriched, nil)
    |> assign(:run_ui, %{phase: :idle, run_id: next_id, started_monotonic: nil})
  end

  defp maybe_supersede_running_run(socket), do: socket

  defp active_run?(socket, run_id) do
    socket.assigns.run_ui.run_id == run_id and socket.assigns.run_ui.phase == :running
  end

  defp next_run_id(%{run_id: run_id}) when is_integer(run_id), do: run_id + 1
  defp next_run_id(_), do: 1

  defp run_async_key(run_id), do: {@playbook_run_async_key, run_id}

  defp cancel_active_run(
         %{assigns: %{run_ui: %{phase: :running, run_id: run_id}}} = socket,
         reason
       ) do
    cancel_async(socket, run_async_key(run_id), reason)
  end

  defp cancel_active_run(socket, _reason), do: socket

  defp now_ms, do: System.monotonic_time(:millisecond)

  defp normalize_async_exit({:shutdown, :cancel}), do: :cancelled
  defp normalize_async_exit({:shutdown, :timeout}), do: :timed_out
  defp normalize_async_exit(:timeout), do: :timed_out
  defp normalize_async_exit(_), do: :cancelled

  defp telemetry_result(:timed_out), do: :timeout
  defp telemetry_result(:cancelled), do: :cancelled
  defp telemetry_result(_), do: :error

  defp maybe_put_run_exit_flash(socket, :cancelled),
    do: put_flash(socket, :info, format_run_flash(:cancelled))

  defp maybe_put_run_exit_flash(socket, :timed_out),
    do: put_flash(socket, :error, format_run_flash(:timed_out))

  defp maybe_put_run_exit_flash(socket, _), do: socket

  defp run_result_summary(%SearchResult{} = r), do: "Run finished — hits: #{length(r.hits)}"

  defp run_result_summary(%MultiSearchResult{} = r),
    do: "Run finished — #{length(r.ordered)} schema(s)."

  defp run_result_summary(_), do: "Run finished."

  defp diagnostics_payload(enriched) when is_map(enriched) do
    Map.take(enriched, [:failure_class, :reason, :message, :copy, :doc])
  end

  defp enrich_run_failure(reason, socket) do
    enriched = RunFailure.enrich(reason, run_failure_copy_context(socket))
    doc = DocResolver.resolve(RunFailure.doc_ref(reason))
    %{enriched | doc: doc}
  end

  defp run_failure_copy_context(socket) do
    playbook = socket.assigns.draft_playbook || %{}
    opts = Map.get(playbook, "opts") || %{}
    page = Map.get(opts, "page") || %{}

    []
    |> maybe_put_context(:basename, socket.assigns.selected_basename)
    |> maybe_put_context(:mode, Map.get(playbook, "mode"))
    |> maybe_put_context(:schema, Map.get(playbook, "schema"))
    |> maybe_put_context(:page_size, page["size"])
    |> maybe_put_context(:max_page_size, ScrypathOps.SearchPlayground.max_page_size_allowed())
  end

  defp maybe_put_context(context, _key, nil), do: context
  defp maybe_put_context(context, key, value), do: Keyword.put(context, key, value)

  defp emit_run_start(run_id) do
    :telemetry.execute(
      [:scrypath_ops, :playbook_run, :start],
      %{system_time: System.system_time()},
      %{run_id: run_id}
    )
  end

  defp emit_run_stop(%{started_monotonic: started_monotonic}, run_id, result)
       when is_integer(started_monotonic) do
    duration = max(now_ms() - started_monotonic, 0)

    :telemetry.execute(
      [:scrypath_ops, :playbook_run, :stop],
      %{duration: duration},
      %{run_id: run_id, result: result}
    )
  end

  defp emit_run_stop(_, _run_id, _result), do: :ok

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      mount_path={@mount_path}
      flash={@flash}
      shell={@shell}
      page_title={@page_title}
      ops_main_width={:wide}
    >
      <div class="space-y-6">
        <.ops_page_header title={@page_title} />

        <.ops_notice id="playbook-honesty-panel" kind={:warning} title="Non-production playbook workspace">
          Exploratory runs use the same bounded search path as the playground and may be logged by backends or proxies.
          <strong>Do not</strong>
          paste production secrets or PII; keep <code class="text-xs">page.size</code>
          and schema lists within configured caps.
        </.ops_notice>

        <.ops_panel class="space-y-6">
          <div class="flex flex-wrap items-center justify-between gap-3">
            <h2 class="text-lg font-semibold">Workspace files</h2>
            <.ops_button phx-click="refresh_list" variant={:ghost}>
              Reload list
            </.ops_button>
          </div>

          <p :if={@examples_mode?} class="text-sm text-base-content/80">
            Examples (read-only) — set <code class="text-sm">SCRYPATH_OPS_PLAYBOOK_DIR</code>
            to enable saving and deleting under a dedicated directory. See
            <.link class="link link-hover" navigate={"#{@mount_path}/search"}>Search & federation</.link>
            to export a playbook JSON, then use <strong>Import playbook JSON</strong>
            below.
          </p>

          <p :if={@workspace_files == []} class="text-base-content/80">
            <span class="text-base font-semibold">No playbooks in this folder</span>
            — export a playbook from Search or import JSON to add a <code class="text-xs">.json</code>
            file. Schema reference: <a
              class="link link-hover"
              href={@playbook_schema_doc.primary}
            >
              playbook-schema-v1.md
            </a>.
          </p>

          <ul :if={@catalog_entries != []} class="menu menu-sm bg-base-200 rounded-md max-w-xl">
            <li
              :for={row <- @catalog_entries}
              class="flex flex-wrap items-center gap-2 justify-between"
            >
              <div class="flex min-w-0 flex-1 flex-col gap-0.5">
                <span class="text-sm font-semibold">{row.display_title}</span>
                <span
                  :if={row.description != ""}
                  class="line-clamp-2 text-xs text-base-content/70"
                >
                  {row.description}
                </span>
                <span class="font-mono text-xs">{row.name}</span>
              </div>
              <span class="flex flex-wrap gap-1">
                <.ops_button
                  phx-click="load"
                  phx-value-name={row.name}
                  variant={:ghost}
                  size={:xs}
                >
                  Load
                </.ops_button>
                <.ops_button
                  :if={@schema_allowlist != [] && Keyword.has_key?(@scrypath_opts, :backend)}
                  phx-click="run_now"
                  phx-value-name={row.name}
                  variant={:primary}
                  size={:xs}
                >
                  Run now
                </.ops_button>
                <.ops_button
                  :if={@workspace_writable?}
                  phx-click="dup_open"
                  phx-value-name={row.name}
                  variant={:ghost}
                  size={:xs}
                >
                  Duplicate
                </.ops_button>
                <.ops_button
                  :if={@workspace_writable?}
                  phx-click="rename_open"
                  phx-value-name={row.name}
                  variant={:ghost}
                  size={:xs}
                >
                  Rename
                </.ops_button>
                <.ops_button
                  :if={@workspace_writable?}
                  phx-click="request_delete"
                  phx-value-name={row.name}
                  variant={:danger}
                  size={:xs}
                >
                  Delete
                </.ops_button>
              </span>
            </li>
          </ul>

          <div class="divider" />

          <section class="space-y-4">
            <h2 class="text-lg font-semibold">Import playbook JSON</h2>
            <.form for={%{}} phx-submit="import_upload" class="space-y-2 max-w-xl">
              <label class="label">
                <span class="label-text text-sm font-semibold">
                  Upload (.json, max {@max_import_bytes} bytes)
                </span>
              </label>
              <.live_file_input
                upload={@uploads.playbook_file}
                class="file-input file-input-bordered w-full max-w-md"
              />
              <.ops_button type="submit" variant={:primary}>
                Import playbook JSON
              </.ops_button>
            </.form>

            <details class="max-w-xl">
              <summary class="cursor-pointer text-sm link link-hover">Or paste JSON</summary>
              <.form for={%{}} phx-submit="import_paste" class="mt-2 space-y-2">
                <textarea
                  name="json"
                  class="textarea textarea-bordered w-full font-mono text-xs min-h-32"
                  placeholder="Paste playbook JSON"
                ></textarea>
                <.ops_button type="submit" variant={:ghost}>Import from paste</.ops_button>
              </.form>
            </details>
          </section>

          <div :if={@draft_playbook} class="space-y-4">
            <div class="divider" />
            <h2 class="text-lg font-semibold">Preview</h2>
            <p
              :if={@preview_marker}
              class="text-xs text-base-content/70"
              data-testid="playbook-preview-marker"
            >
              Validated playbook preview
            </p>
            <.ops_code_block :if={@preview_json}>{@preview_json}</.ops_code_block>

            <div class="flex flex-wrap gap-2 items-end">
              <.ops_button
                :if={@schema_allowlist != [] && Keyword.has_key?(@scrypath_opts, :backend)}
                phx-click="run"
                variant={:primary}
                size={:md}
                disabled={@run_ui.phase == :running}
              >
                Run saved playbook
              </.ops_button>
              <.ops_button
                :if={@run_ui.phase == :running}
                phx-click="cancel_run"
                variant={:ghost}
                size={:md}
              >
                Cancel run
              </.ops_button>
              <p
                :if={@schema_allowlist == [] or !Keyword.has_key?(@scrypath_opts, :backend)}
                class="text-sm text-base-content/70"
              >
                Configure schema allowlist and Scrypath backend to enable runs (see README).
              </p>
            </div>

            <p :if={@run_ui.phase == :running} class="alert text-sm">
              <strong>Running playbook…</strong>
              applying results for run <code class="text-xs">{@run_ui.run_id}</code>
              only.
            </p>

            <div
              :if={@run_ui.phase == :error && @run_failure_enriched}
              class="alert alert-error items-start text-sm"
              role="alert"
              data-testid="run-failure-panel"
            >
              <div class="space-y-3">
                <p>
                  <strong>{@run_failure_enriched.failure_class}</strong>
                  {": "}
                  {@run_failure_enriched.message}
                </p>
                <div class="flex flex-wrap gap-2">
                  <a
                    class="link link-hover"
                    href={@run_failure_enriched.doc.primary}
                    target="_blank"
                    rel="noreferrer"
                  >
                    Read troubleshooting
                  </a>
                  <a
                    :for={related <- @run_failure_enriched.doc.related}
                    class="link link-hover"
                    href={related}
                    target="_blank"
                    rel="noreferrer"
                  >
                    Related doc
                  </a>
                  <.ops_button phx-click="copy_run_diagnostics" variant={:ghost} size={:xs}>
                    Copy diagnostics
                  </.ops_button>
                </div>
              </div>
            </div>

            <p :if={@run_ui.phase == :ok && @run_result} class="alert alert-success text-sm">
              {run_result_summary(@run_result)}
            </p>

            <div :if={@workspace_writable?} class="space-y-2 max-w-md">
              <h3 class="text-sm font-semibold">Save playbook to workspace</h3>
              <.form for={%{}} phx-submit="save" class="flex flex-wrap gap-2 items-end">
                <div>
                  <label class="label label-text text-xs" for="save_basename">Basename (.json)</label>
                  <input
                    id="save_basename"
                    type="text"
                    name="basename"
                    value={@save_basename}
                    class="input input-bordered input-sm w-64"
                    placeholder="my-playbook.json"
                  />
                </div>
                <.ops_button type="submit" variant={:primary}>
                  Save playbook to workspace
                </.ops_button>
              </.form>
            </div>
          </div>

          <.ops_modal :if={@delete_pending} id="delete-playbook-modal" title="Delete playbook file">
              <p class="py-4 text-sm">
                This permanently deletes <code class="font-mono text-xs">{@delete_pending}</code>
                from the playbook directory. This cannot be undone.
              </p>
              <.form for={%{}} phx-submit="confirm_delete" class="space-y-2">
                <label class="label">
                  <span class="label-text">Type the filename to confirm</span>
                </label>
                <input
                  type="text"
                  name="confirm"
                  class="input input-bordered w-full font-mono text-sm"
                  autocomplete="off"
                />
                <div class="modal-action">
                  <.ops_button phx-click="cancel_delete">Cancel</.ops_button>
                  <.ops_button type="submit" variant={:danger}>Confirm delete</.ops_button>
                </div>
              </.form>
          </.ops_modal>

          <.ops_modal :if={@rename_modal} id="rename-playbook-modal" title="Rename playbook">
              <p class="py-2 text-sm">
                Renaming <code class="font-mono text-xs">{@rename_modal.from}</code>
              </p>
              <.form for={%{}} phx-submit="rename_submit" class="space-y-2">
                <label class="label">
                  <span class="label-text">New basename (.json)</span>
                </label>
                <input
                  type="text"
                  name="new_name"
                  class="input input-bordered w-full font-mono text-sm"
                  placeholder="new-name.json"
                />
                <div class="modal-action">
                  <.ops_button phx-click="rename_cancel">Cancel</.ops_button>
                  <.ops_button type="submit" variant={:primary}>Rename</.ops_button>
                </div>
              </.form>
          </.ops_modal>

          <.ops_modal :if={@duplicate_modal} id="duplicate-playbook-modal" title="Duplicate playbook">
              <p class="py-2 text-sm">
                Copying <code class="font-mono text-xs">{@duplicate_modal.from}</code>
              </p>
              <.form for={%{}} phx-submit="dup_submit" class="space-y-2">
                <label class="label">
                  <span class="label-text">New basename (.json)</span>
                </label>
                <input
                  type="text"
                  name="to_name"
                  value={@duplicate_modal.to}
                  class="input input-bordered w-full font-mono text-sm"
                />
                <div class="modal-action">
                  <.ops_button phx-click="dup_cancel">Cancel</.ops_button>
                  <.ops_button type="submit" variant={:primary}>Duplicate</.ops_button>
                </div>
              </.form>
          </.ops_modal>
        </.ops_panel>
      </div>
    </Layouts.app>
    """
  end

  defp confirm_delete(socket, typed) do
    pending = socket.assigns.delete_pending
    typed = typed |> to_string() |> String.trim()
    root = socket.assigns.workspace_root

    cond do
      pending == nil ->
        socket

      not socket.assigns.workspace_writable? ->
        put_flash(socket, :error, "Delete is disabled for read-only examples.")

      typed != pending ->
        put_flash(socket, :error, "Confirmation must match the filename exactly.")

      true ->
        case Store.delete_workspace_file(root, pending) do
          :ok ->
            socket =
              socket
              |> reload_workspace_catalog()
              |> assign(:delete_pending, nil)

            socket =
              if socket.assigns.selected_basename == pending do
                socket
                |> assign(:selected_basename, nil)
                |> assign(:draft_playbook, nil)
                |> assign(:preview_json, nil)
                |> assign(:preview_marker, false)
                |> assign(:run_result, nil)
                |> assign(:run_error, nil)
              else
                socket
              end

            put_flash(socket, :info, "Deleted #{pending}")

          {:error, _} ->
            put_flash(socket, :error, "Delete failed — check permissions.")
        end
    end
  end

  defp normalize_live_reply({:noreply, %Phoenix.LiveView.Socket{} = socket}), do: socket
  defp normalize_live_reply(%Phoenix.LiveView.Socket{} = socket), do: socket
  defp normalize_live_reply(other), do: other
end
