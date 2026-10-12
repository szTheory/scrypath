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
    workspace_configured? = workspace_root != nil
    {files, examples_mode?} = list_workspace_files(workspace_root, examples_dir)
    catalog = build_catalog_entries(workspace_root, examples_dir, files, examples_mode?)
    playbook_schema_doc = DocResolver.resolve(:playbook_schema)

    socket =
      socket
      |> assign(:page_title, "Saved playbooks")
      |> assign(:workspace_root, workspace_root)
      |> assign(:examples_dir, examples_dir)
      |> assign(:workspace_configured?, workspace_configured?)
      |> assign(:examples_mode?, examples_mode?)
      |> assign(:workspace_files, files)
      |> assign(:catalog_entries, catalog)
      |> assign(:file_action_error, nil)
      |> assign(:modal_focus_request, 0)
      |> assign(:delete_confirmation, nil)
      |> assign(:rename_modal, nil)
      |> assign(:duplicate_modal, nil)
      |> assign(:schema_allowlist, Schemas.allowlist())
      |> assign(:scrypath_opts, Schemas.scrypath_opts())
      |> assign(:draft_playbook, nil)
      |> assign(:draft_origin, nil)
      |> assign(:preview_json, nil)
      |> assign(:preview_marker, false)
      |> assign(:selected_basename, nil)
      |> assign(:run_snapshot, nil)
      |> assign(:run_result, nil)
      |> assign(:run_error, nil)
      |> assign(:run_failure_enriched, nil)
      |> assign(:run_ui, %{phase: :idle, run_id: 0, started_monotonic: nil})
      |> assign(:delete_pending, nil)
      |> assign(:save_basename, "")
      |> assign(:save_error, nil)
      |> assign(:import_error, nil)
      |> assign(:paste_json, "")
      |> assign(:paste_open, false)
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
  def handle_event("import_paste", %{"json" => raw}, socket) when is_binary(raw) do
    socket =
      socket
      |> maybe_supersede_running_run()
      |> assign(:paste_open, true)

    bin = raw

    if byte_size(bin) > @max_import_bytes do
      {:noreply,
       socket
       |> assign(:paste_json, bin)
       |> import_failure(
         :paste,
         %{kind: :imported, name: "pasted JSON"},
         "Maximum size is 256,000 bytes."
       )}
    else
      {:noreply,
       socket
       |> assign(:paste_json, bin)
       |> apply_decoded(bin, :paste, %{kind: :imported, name: "pasted JSON"})}
    end
  end

  def handle_event("import_paste", _params, socket) do
    socket =
      socket
      |> maybe_supersede_running_run()
      |> assign(:paste_open, true)
      |> assign(:paste_json, "")

    {:noreply,
     import_failure(
       socket,
       :paste,
       %{kind: :imported, name: "pasted JSON"},
       "Paste content must be text."
     )}
  end

  def handle_event("import_upload", _params, socket) do
    socket = maybe_supersede_running_run(socket)
    upload = socket.assigns.uploads.playbook_file

    case playbook_upload_error_reason(upload) do
      reason when not is_nil(reason) ->
        {:noreply,
         import_failure(
           socket,
           :upload,
           %{kind: :imported, name: "uploaded file"},
           upload_error_text(reason)
         )}

      nil ->
        case Phoenix.LiveView.uploaded_entries(socket, :playbook_file) do
          {[], []} ->
            {:noreply,
             import_failure(
               socket,
               :upload,
               %{kind: :imported, name: "uploaded file"},
               "Choose a JSON file first."
             )}

          {_completed, [_pending | _]} ->
            {:noreply,
             put_flash(
               socket,
               :info,
               "Wait for the selected playbook file to finish uploading, then retry importing."
             )}

          _ ->
            import_uploaded_entries(socket)
        end
    end
  end

  # LiveView tracks selected upload files through the form change binding. This
  # event only completes the upload preflight; bytes are consumed on explicit
  # Import submit below.
  def handle_event("validate_upload", _params, socket), do: {:noreply, socket}

  def handle_event("load", %{"name" => name}, socket) do
    socket = maybe_supersede_running_run(socket)
    name = text_param(name)

    cond do
      not Store.safe_basename?(name) ->
        {:noreply, put_flash(socket, :error, "Invalid playbook file name.")}

      socket.assigns.workspace_root ->
        case Store.read_workspace_file(socket.assigns.workspace_root, name) do
          {:ok, bin} ->
            socket =
              socket
              |> apply_decoded(bin, :load, %{kind: :workspace, name: name})

            {:noreply, socket}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Could not read that playbook file.")}
        end

      socket.assigns.examples_dir ->
        path = Path.join(socket.assigns.examples_dir, name)

        if Store.safe_basename?(name) and File.exists?(path) do
          case File.read(path) do
            {:ok, bin} ->
              socket =
                socket
                |> apply_decoded(bin, :load, %{kind: :example, name: name})

              {:noreply, socket}

            {:error, _} ->
              {:noreply, put_flash(socket, :error, "Could not read that example file.")}
          end
        else
          {:noreply, put_flash(socket, :error, "Could not read that example file.")}
        end

      true ->
        {:noreply, put_flash(socket, :error, "No playbook directory is configured.")}
    end
  end

  def handle_event("run_now", %{"name" => name}, socket) do
    socket = maybe_supersede_running_run(socket)
    name = text_param(name)

    with :ok <- validate_catalog_name(name),
         {:ok, bin} <- read_catalog_playbook(socket, name),
         {:ok, validated} <- decode_and_validate_playbook(bin),
         preview <- Jason.encode!(validated, pretty: true) do
      socket =
        socket
        |> assign(:draft_origin, catalog_origin(socket, name))
        |> assign(:selected_basename, name)
        |> assign(:draft_playbook, validated)
        |> assign(:preview_json, preview)
        |> assign(:preview_marker, true)
        |> assign(:save_basename, "")
        |> assign(:save_error, nil)
        |> assign(:import_error, nil)
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
    basename = basename |> text_param() |> String.trim()
    root = socket.assigns.workspace_root
    socket = socket |> assign(:save_basename, basename) |> assign(:save_error, nil)

    cond do
      root == nil ->
        message = "Configure a playbook workspace directory, then retry saving."

        {:noreply,
         socket
         |> assign(:save_error, "Could not save playbook to workspace. #{message}")
         |> put_flash(:error, "Could not save playbook to workspace.")}

      not Store.safe_basename?(basename) ->
        {:noreply,
         socket
         |> assign(:save_error, "Use a filename ending in .json.")
         |> put_flash(:error, "Filename must match *.json basename rules.")}

      socket.assigns.draft_playbook == nil ->
        {:noreply,
         socket
         |> assign(:save_error, "Import or load a valid playbook before saving.")
         |> put_flash(:error, "Nothing to save — import or load a playbook first.")}

      true ->
        case V1.encode(socket.assigns.draft_playbook) do
          {:ok, json} ->
            case Store.save_workspace_file(root, basename, json <> "\n") do
              :ok ->
                {:noreply,
                 socket
                 |> reload_workspace_catalog()
                 |> assign(:save_basename, "")
                 |> assign(:save_error, nil)
                 |> assign(:draft_origin, %{kind: :workspace, name: basename})
                 |> assign(:selected_basename, basename)
                 |> put_flash(:info, "Saved #{basename}")}

              {:error, reason} ->
                {:noreply,
                 socket
                 |> assign(:save_error, save_failure_message(reason))
                 |> put_flash(:error, "Could not save playbook to workspace.")}
            end

          {:error, _} ->
            {:noreply,
             socket
             |> assign(:save_error, "Could not encode playbook for saving.")
             |> put_flash(:error, "Could not encode playbook for saving.")}
        end
    end
  end

  def handle_event("request_delete", %{"name" => name}, socket) do
    name = text_param(name)

    if Store.safe_basename?(name) do
      {:noreply,
       socket
       |> assign(:file_action_error, nil)
       |> assign(:delete_confirmation, nil)
       |> assign(:delete_pending, name)}
    else
      {:noreply, put_flash(socket, :error, "Invalid playbook file name.")}
    end
  end

  def handle_event("cancel_delete", _params, socket) do
    {:noreply,
     socket
     |> assign(:delete_pending, nil)
     |> assign(:delete_confirmation, nil)}
  end

  def handle_event("confirm_delete", %{"confirm" => typed}, socket) do
    typed = text_param(typed)
    socket = assign(socket, :delete_confirmation, typed)

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
    name = text_param(name)

    if Store.safe_basename?(name) do
      {:noreply,
       socket
       |> assign(:file_action_error, nil)
       |> assign(:rename_modal, %{from: name, new_name: ""})}
    else
      {:noreply, put_flash(socket, :error, "Invalid playbook file name.")}
    end
  end

  def handle_event("rename_change", %{"new_name" => new_name}, socket) do
    case socket.assigns.rename_modal do
      modal when is_map(modal) ->
        {:noreply, assign(socket, :rename_modal, Map.put(modal, :new_name, text_param(new_name)))}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("rename_change", _, socket), do: {:noreply, socket}

  def handle_event("rename_cancel", _, socket) do
    {:noreply, assign(socket, :rename_modal, nil)}
  end

  def handle_event("rename_submit", %{"new_name" => new_name}, socket) do
    case socket.assigns.rename_modal do
      nil ->
        {:noreply, socket}

      %{from: from} ->
        socket =
          update(socket, :rename_modal, fn modal ->
            Map.put(modal, :new_name, text_param(new_name))
          end)

        rename_submit_impl(socket, from, new_name)
    end
  end

  def handle_event("dup_open", %{"name" => name}, socket) do
    name = text_param(name)
    root = socket.assigns.workspace_root

    cond do
      not Store.safe_basename?(name) ->
        {:noreply, put_flash(socket, :error, "Invalid playbook file name.")}

      not socket.assigns.workspace_configured? or root == nil ->
        {:noreply,
         put_flash(socket, :error, "Configure a playbook workspace directory to duplicate files.")}

      true ->
        case Store.suggest_duplicate_basename(root, name) do
          {:ok, suggested} ->
            {:noreply,
             socket
             |> assign(:file_action_error, nil)
             |> assign(:duplicate_modal, %{from: name, to: suggested, new_name: suggested})}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Could not suggest a duplicate filename.")}
        end
    end
  end

  def handle_event("dup_cancel", _, socket) do
    {:noreply, assign(socket, :duplicate_modal, nil)}
  end

  def handle_event("dup_change", %{"to_name" => to_name}, socket) do
    case socket.assigns.duplicate_modal do
      modal when is_map(modal) ->
        {:noreply,
         assign(socket, :duplicate_modal, Map.put(modal, :new_name, text_param(to_name)))}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("dup_change", _, socket), do: {:noreply, socket}

  def handle_event("dup_submit", %{"to_name" => to_name}, socket) do
    case socket.assigns.duplicate_modal do
      nil ->
        {:noreply, socket}

      %{from: from} ->
        socket =
          update(socket, :duplicate_modal, fn modal ->
            Map.put(modal, :new_name, text_param(to_name))
          end)

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

  defp apply_decoded(socket, bin, source, origin) do
    case decode_and_validate_playbook(bin) do
      {:ok, validated} ->
        preview = Jason.encode!(validated, pretty: true)

        socket
        |> assign(:draft_playbook, validated)
        |> assign(:draft_origin, origin)
        |> assign(:preview_json, preview)
        |> assign(:preview_marker, true)
        |> assign(:selected_basename, selected_name(origin))
        |> assign(:save_basename, "")
        |> assign(:save_error, nil)
        |> assign(:import_error, nil)
        |> assign(:run_failure_enriched, nil)
        |> put_flash(:info, flash_for_import(source))

      {:error, {:invalid_playbook, reason}} ->
        import_failure(
          socket,
          source,
          origin,
          "Playbook failed validation: #{format_validation_reason(reason)}"
        )

      {:error, :invalid_json} ->
        import_failure(socket, source, origin, "This file is not valid playbook JSON.")
    end
  end

  defp import_failure(socket, source, _origin, detail) when source in [:paste, :upload] do
    message =
      if socket.assigns.draft_playbook do
        "Could not import playbook JSON. #{detail} The previous valid preview remains selected."
      else
        "Could not import playbook JSON. #{detail} No previous valid preview is available."
      end

    assign(socket, :import_error, message)
  end

  defp import_failure(socket, _source, origin, detail) do
    message =
      "Could not import playbook JSON from #{origin.name}. #{detail} No valid preview is selected."

    socket
    |> assign(:draft_playbook, nil)
    |> assign(:draft_origin, nil)
    |> assign(:preview_json, nil)
    |> assign(:preview_marker, false)
    |> assign(:selected_basename, nil)
    |> assign(:import_error, message)
    |> assign(:run_failure_enriched, nil)
  end

  defp import_uploaded_entries(socket) do
    case consume_uploaded_entries(socket, :playbook_file, fn %{path: path}, entry ->
           case File.read(path) do
             {:ok, bin} -> {:ok, {bin, entry.client_name}}
             {:error, _} -> {:ok, {:error, :read_failed}}
           end
         end) do
      [] ->
        {:noreply, put_flash(socket, :error, "Choose a JSON file first.")}

      [{bin, filename}] when is_binary(bin) and is_binary(filename) ->
        {:noreply,
         apply_decoded(socket, bin, :upload, %{kind: :imported, name: Path.basename(filename)})}

      [{:error, reason}] ->
        {:noreply,
         import_failure(
           socket,
           :upload,
           %{kind: :imported, name: "uploaded file"},
           if(reason == :read_failed,
             do: "Could not read the uploaded file.",
             else: "The uploaded file could not be processed."
           )
         )}

      _ ->
        {:noreply,
         import_failure(
           socket,
           :upload,
           %{kind: :imported, name: "uploaded file"},
           "The uploaded file could not be processed."
         )}
    end
  end

  defp playbook_upload_error_reason(upload) do
    upload.errors
    |> Enum.map(fn {_ref, reason} -> reason end)
    |> List.first()
  end

  defp playbook_upload_error_messages(upload) do
    upload.errors
    |> Enum.map(fn {_ref, reason} -> reason end)
    |> Enum.uniq()
    |> Enum.map(&upload_error_text/1)
  end

  defp upload_described_by(upload, import_error) do
    upload_errors? = playbook_upload_error_messages(upload) != []

    [
      "#{upload.ref}-hint",
      if(import_error, do: "playbook-import-error"),
      if(upload_errors?, do: "playbook-upload-error")
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" ")
  end

  defp upload_error_text(:too_large), do: "This file exceeds the 256,000-byte import limit."
  defp upload_error_text(:not_accepted), do: "Choose a file ending in .json."
  defp upload_error_text(:too_many_files), do: "Choose one playbook JSON file at a time."
  defp upload_error_text(:external_client_failure), do: "The file upload could not be completed."

  defp upload_error_text({:writer_failure, _reason}),
    do: "The file upload could not be completed."

  defp upload_error_text(_), do: "The selected file could not be accepted."

  defp selected_name(%{kind: kind, name: name}) when kind in [:workspace, :example], do: name
  defp selected_name(_origin), do: nil

  defp text_param(value) when is_binary(value), do: value
  defp text_param(_value), do: ""

  defp catalog_origin(socket, name) do
    if socket.assigns.workspace_root,
      do: %{kind: :workspace, name: name},
      else: %{kind: :example, name: name}
  end

  defp flash_for_import(:paste), do: "Imported playbook from paste."
  defp flash_for_import(:upload), do: "Imported playbook from file."
  defp flash_for_import(:load), do: "Loaded playbook from disk."

  defp save_failure_message(reason) when is_atom(reason) do
    "Could not save playbook to workspace. Filesystem reason: #{inspect(reason)}. " <>
      "Check the workspace directory's permissions and available disk space, then retry saving."
  end

  defp save_failure_message(_reason) do
    "Could not save playbook to workspace. The filesystem returned an unclassified write error. " <>
      "Check the workspace directory's permissions and available disk space, then retry saving."
  end

  defp rename_submit_impl(socket, from, new_name) do
    new_name = new_name |> text_param() |> String.trim()
    root = socket.assigns.workspace_root

    cond do
      not socket.assigns.workspace_configured? or root == nil ->
        {:noreply,
         file_action_error(socket, "Configure a playbook workspace directory to rename files.")}

      not Store.safe_basename?(new_name) ->
        {:noreply, file_action_error(socket, "Filename must match *.json basename rules.")}

      true ->
        case Store.rename_workspace_file(root, from, new_name) do
          :ok ->
            socket =
              socket
              |> assign(:rename_modal, nil)
              |> reload_workspace_catalog()

            socket =
              if socket.assigns.selected_basename == from do
                socket
                |> assign(:selected_basename, new_name)
                |> assign(:draft_origin, %{kind: :workspace, name: new_name})
              else
                socket
              end

            {:noreply, put_flash(socket, :info, "Renamed to #{new_name}")}

          {:error, :target_exists} ->
            {:noreply,
             file_action_error(
               socket,
               "That playbook name is already in use — pick another basename."
             )}

          {:error, :unsupported_filesystem} ->
            {:noreply,
             file_action_error(
               socket,
               "This workspace cannot safely rename files. Duplicate the playbook, then delete the original."
             )}

          {:error, _} ->
            {:noreply, file_action_error(socket, "Rename failed — check permissions.")}
        end
    end
  end

  defp dup_submit_impl(socket, from, to_name) do
    to_name = to_name |> text_param() |> String.trim()
    root = socket.assigns.workspace_root

    cond do
      not socket.assigns.workspace_configured? or root == nil ->
        {:noreply,
         file_action_error(socket, "Configure a playbook workspace directory to duplicate files.")}

      not Store.safe_basename?(to_name) ->
        {:noreply, file_action_error(socket, "Filename must match *.json basename rules.")}

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
             file_action_error(
               socket,
               "That playbook name is already in use — pick another basename."
             )}

          {:error, _} ->
            {:noreply, file_action_error(socket, "Duplicate failed — check permissions.")}
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
        snapshot = %{run_id: run_id, draft: draft, origin: assigns.draft_origin}

        Process.send_after(self(), {:playbook_run_timeout, run_id}, @playbook_run_timeout_ms)

        socket
        |> assign(:run_snapshot, snapshot)
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
    |> assign(:run_snapshot, nil)
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

  defp run_result_summary(%MultiSearchResult{failures: failures} = r) when failures != [],
    do: "Partial response — #{length(r.ordered)} schema(s) returned; #{length(failures)} failed."

  defp run_result_summary(%MultiSearchResult{} = r),
    do: "Run finished — #{length(r.ordered)} schema(s)."

  defp run_result_summary(_), do: "Run finished."

  # Search can represent one query for one or more targets. Keep the handoff exact for
  # single-target playbooks and shared-query federated playbooks; omit it when entries
  # have different queries rather than sending the operator to a different search.
  defp search_loopback_path(mount_path, %{"mode" => "search", "schema" => schema} = playbook) do
    params = %{"mode" => "single", "q" => Map.get(playbook, "q", ""), "schema" => schema}
    "#{mount_path}/search?" <> URI.encode_query(add_page_size(params, playbook))
  end

  defp search_loopback_path(
         mount_path,
         %{"mode" => "search_many", "entries" => entries} = playbook
       )
       when is_list(entries) and entries != [] do
    queries = Enum.map(entries, fn [_schema, query, _opts] -> query end)

    if length(Enum.uniq(queries)) == 1 do
      schemas = Enum.map(entries, fn [schema, _query, _opts] -> schema end)
      params = %{"mode" => "multi", "q" => hd(queries), "schemas" => Enum.join(schemas, ",")}
      "#{mount_path}/search?" <> URI.encode_query(add_page_size(params, playbook))
    end
  end

  defp search_loopback_path(_mount_path, _playbook), do: nil

  defp add_page_size(params, playbook) do
    page_size = get_in(playbook, ["opts", "page", "size"])
    if is_integer(page_size), do: Map.put(params, "page_size", page_size), else: params
  end

  defp playbook_summary(nil, _origin), do: []

  defp playbook_summary(playbook, origin) when is_map(playbook) do
    opts = Map.get(playbook, "opts") || %{}
    page = Map.get(opts, "page") || %{}
    entries = Map.get(playbook, "entries") || []
    multi? = Map.get(playbook, "mode") == "search_many"

    [
      {"Search title", Map.get(playbook, "title")},
      {"Description", Map.get(playbook, "description")},
      {"Mode", Map.get(playbook, "mode")},
      {if(multi?, do: "Targets and queries", else: "Index"),
       if(multi?, do: entry_target_query_label(entries), else: Map.get(playbook, "schema"))},
      {"Query", Map.get(playbook, "q")},
      {"Entries", entry_count_label(entries)},
      {"Page size / limit", page_summary(playbook, page)},
      {"Draft source", draft_origin_label(origin)},
      {"Persistence", persistence_label(origin)}
    ]
    |> Enum.reject(fn {_label, value} -> value in [nil, "", []] end)
  end

  defp page_summary(playbook, page) do
    shared = Map.get(page, "size")

    cond do
      is_integer(shared) -> shared
      Map.get(playbook, "mode") == "search_many" -> multi_page_summary(playbook)
      true -> "Backend default"
    end
  end

  defp multi_page_summary(%{"entries" => entries}) when is_list(entries) do
    if Enum.all?(entries, fn [_schema, _query, opts] -> get_in(opts, ["page", "size"]) == nil end) do
      "Backend default per target"
    else
      Enum.map_join(entries, "\n", fn
        [schema, _query, opts] ->
          "#{schema}: #{get_in(opts, ["page", "size"]) || "backend default"}"
      end)
    end
  end

  defp multi_page_summary(_playbook), do: "Backend default per target"

  defp entry_target_query_label(entries) when is_list(entries) do
    Enum.map_join(entries, "\n", fn
      [schema, query, _opts] -> "#{schema} — #{query}"
      _other -> "Invalid entry"
    end)
  end

  defp entry_target_query_label(_), do: nil

  defp draft_origin_label(%{kind: :workspace, name: name}), do: "Workspace file · #{name}"
  defp draft_origin_label(%{kind: :example, name: name}), do: "Read-only example · #{name}"

  defp draft_origin_label(%{kind: :imported, name: name}),
    do: "Imported draft · not saved · #{name}"

  defp draft_origin_label(_), do: nil

  defp persistence_label(%{kind: :workspace, name: name}), do: "Saved in workspace · #{name}"
  defp persistence_label(%{kind: :example, name: name}), do: "Read-only example · #{name}"
  defp persistence_label(%{kind: :imported}), do: "Not saved"
  defp persistence_label(_), do: nil

  defp entry_count_label(entries) when is_list(entries),
    do: "#{length(entries)} schema query entries"

  defp entry_count_label(_), do: nil

  defp diagnostics_payload(enriched) when is_map(enriched) do
    Map.take(enriched, [:failure_class, :reason, :message, :copy, :doc])
  end

  defp enrich_run_failure(reason, socket) do
    enriched = RunFailure.enrich(reason, run_failure_copy_context(socket))
    doc = DocResolver.resolve(RunFailure.doc_ref(reason))
    %{enriched | doc: doc}
  end

  defp run_failure_copy_context(socket) do
    snapshot = socket.assigns.run_snapshot || %{}
    playbook = Map.get(snapshot, :draft) || %{}
    origin = Map.get(snapshot, :origin) || %{}
    opts = Map.get(playbook, "opts") || %{}
    page = Map.get(opts, "page") || %{}

    []
    |> maybe_put_context(:basename, Map.get(origin, :name))
    |> maybe_put_context(:mode, Map.get(playbook, "mode"))
    |> maybe_put_context(:schema, Map.get(playbook, "schema") || snapshot_target_names(playbook))
    |> maybe_put_context(:page_size, page["size"])
    |> maybe_put_context(:max_page_size, ScrypathOps.SearchPlayground.max_page_size_allowed())
  end

  defp snapshot_target_names(%{"entries" => entries}) when is_list(entries) do
    Enum.map(entries, fn
      [schema, _query, _opts] -> schema
      _ -> nil
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp snapshot_target_names(_playbook), do: nil

  defp run_snapshot_current?(nil, _draft, _origin), do: false

  defp run_snapshot_current?(snapshot, draft, origin) do
    snapshot.draft == draft and snapshot.origin == origin
  end

  defp earlier_run?(snapshot, draft, origin),
    do: not run_snapshot_current?(snapshot, draft, origin)

  defp run_outcome_heading(:running, _earlier?), do: "Current run"
  defp run_outcome_heading(:ok, true), do: "Last completed run"
  defp run_outcome_heading(:error, true), do: "Earlier run"
  defp run_outcome_heading(_phase, _earlier?), do: "Run outcome"

  defp run_configuration_available?(allowlist, opts),
    do: allowlist != [] and Keyword.has_key?(opts, :backend)

  defp result_kind(%MultiSearchResult{failures: [_ | _]}), do: :partial
  defp result_kind(_), do: :success

  defp result_title(%MultiSearchResult{failures: [_ | _]}),
    do: "Some indexes did not return results."

  defp result_title(_), do: "Playbook run completed"

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
        <.ops_toolbar class="items-end">
          <div class="min-w-0 flex-1 space-y-1.5">
            <.ops_page_header
              title={@page_title}
              subtitle="Use saved, repeatable search checks: preview, run, import, or save the next one."
            />
            <.ops_workspace_mode_indicator
              mode={if @examples_mode?, do: :examples, else: :workspace}
              path={@workspace_root}
            />
          </div>
        </.ops_toolbar>

        <.ops_trail current={:playbooks} />

        <.ops_notice
          id="playbook-honesty-panel"
          kind={:warning}
          title="Non-production playbook workspace"
        >
          Playbooks repeat saved Search checks. Do not paste production secrets or PII; keep page size and selected indexes within configured caps.
        </.ops_notice>

        <.ops_panel class="space-y-6">
          <.ops_toolbar>
            <.ops_heading level={2} id="playbook-catalog-heading" tabindex={-1}>
              Workspace files
            </.ops_heading>
            <div class="flex flex-wrap gap-2">
              <.ops_link_button href="#playbook-import" variant={:default}>
                Import JSON
              </.ops_link_button>
              <.ops_button phx-click="refresh_list" variant={:ghost}>
                Reload playbooks
              </.ops_button>
            </div>
          </.ops_toolbar>

          <p :if={@examples_mode?} class="text-ops-body text-base-content/80">
            <strong>Examples (read-only)</strong> Examples can be previewed and run. Configure a
            playbook workspace directory to enable saving and file changes.
          </p>

          <.ops_empty_hero
            :if={@workspace_files == []}
            title="No playbooks yet"
            icon="hero-book-open"
            data-testid="playbooks-empty-hero"
          >
            Save a useful search check, or import a playbook JSON file below.
            <:actions>
              <.ops_link_button href="#playbook-import" variant={:primary}>
                Import JSON
              </.ops_link_button>
              <.ops_link_button navigate={"#{@mount_path}/search"} variant={:default}>
                Open Search
              </.ops_link_button>
            </:actions>
          </.ops_empty_hero>

          <.ops_object_list :if={@catalog_entries != []} class="max-w-3xl">
            <.ops_object_item
              :for={row <- @catalog_entries}
              id={"playbook-row-#{playbook_dom_id(row.name)}"}
              active={row.name == @selected_basename}
            >
              <div class="flex min-w-0 flex-col gap-1">
                <span class="text-ops-body font-semibold text-base-content">{row.display_title}</span>
                <span
                  :if={row.description != ""}
                  class="line-clamp-2 text-ops-sm text-base-content/70"
                >
                  {row.description}
                </span>
                <span class="ops-playbook-filename font-mono text-ops-body text-base-content/65">
                  {row.name}
                </span>
              </div>
              <:actions>
                <.ops_action_group>
                  <.ops_button
                    id={"playbook-primary-#{playbook_dom_id(row.name)}"}
                    phx-click="load"
                    phx-value-name={row.name}
                    variant={:default}
                    size={:xs}
                  >
                    Load preview
                  </.ops_button>
                </.ops_action_group>
                <.ops_action_group
                  :if={@schema_allowlist != [] && Keyword.has_key?(@scrypath_opts, :backend)}
                  tone={:advanced}
                >
                  <.ops_button
                    :if={@schema_allowlist != [] && Keyword.has_key?(@scrypath_opts, :backend)}
                    phx-click="run_now"
                    phx-value-name={row.name}
                    variant={:default}
                    size={:xs}
                    aria-label={"Run #{row.name} without preview"}
                  >
                    Run without preview
                  </.ops_button>
                </.ops_action_group>
                <.ops_disclosure
                  :if={@workspace_configured?}
                  id={"playbook-manage-#{playbook_dom_id(row.name)}"}
                  summary_id={"playbook-manage-summary-#{playbook_dom_id(row.name)}"}
                  summary="Manage file actions"
                  data-testid="playbook-manage-actions"
                  data-ops-file-name={row.name}
                  class="ops-playbook-file-actions"
                >
                  <div class="grid gap-ops-2" role="group" aria-label={"Actions for #{row.name}"}>
                    <div class="flex flex-wrap gap-2">
                      <.ops_button
                        phx-click="dup_open"
                        phx-value-name={row.name}
                        data-ops-modal-trigger="duplicate"
                        data-ops-modal-return={"#playbook-manage-summary-#{playbook_dom_id(row.name)}"}
                        variant={:default}
                        size={:xs}
                        aria-label={"Duplicate #{row.name}"}
                      >
                        Duplicate
                      </.ops_button>
                      <.ops_button
                        phx-click="rename_open"
                        phx-value-name={row.name}
                        data-ops-modal-trigger="rename"
                        data-ops-modal-return={"#playbook-manage-summary-#{playbook_dom_id(row.name)}"}
                        variant={:default}
                        size={:xs}
                        aria-label={"Rename #{row.name}"}
                      >
                        Rename
                      </.ops_button>
                    </div>
                    <div class="border-t border-base-content/10 pt-2">
                      <.ops_button
                        phx-click="request_delete"
                        phx-value-name={row.name}
                        data-ops-modal-trigger="delete"
                        data-ops-modal-return={"#playbook-manage-summary-#{playbook_dom_id(row.name)}"}
                        variant={:danger}
                        size={:xs}
                        aria-label={"Delete #{row.name}"}
                      >
                        Delete
                      </.ops_button>
                    </div>
                  </div>
                </.ops_disclosure>
              </:actions>
            </.ops_object_item>
          </.ops_object_list>

          <div class="divider" />

          <section
            :if={@draft_playbook}
            id="playbook-preview"
            aria-labelledby="playbook-preview-heading"
            class="space-y-4"
          >
            <.ops_heading level={2} id="playbook-preview-heading">Preview</.ops_heading>
            <p
              :if={@preview_marker}
              class="text-ops-body text-base-content/70"
              data-testid="playbook-preview-marker"
            >
              Playbook preview is ready
            </p>
            <.ops_data_card title="Playbook summary" subtitle="Check this before running.">
              <dl id="playbook-summary" class="grid gap-3 text-ops-body sm:grid-cols-2">
                <div
                  :for={{label, value} <- playbook_summary(@draft_playbook, @draft_origin)}
                  id={if label == "Draft source", do: "playbook-draft-origin"}
                  class="min-w-0"
                >
                  <dt class="text-ops-sm font-semibold uppercase tracking-wide text-base-content/60">
                    {label}
                  </dt>
                  <dd class="mt-1 whitespace-pre-wrap break-words text-ops-body text-base-content">
                    {value}
                  </dd>
                </div>
              </dl>
            </.ops_data_card>
            <.ops_disclosure :if={@preview_json} summary="Raw playbook JSON" variant={:compact}>
              <.ops_code_block variant={:compact}>{@preview_json}</.ops_code_block>
            </.ops_disclosure>

            <div class="flex flex-wrap gap-2 items-end">
              <.ops_button
                phx-click="run"
                variant={:primary}
                size={:md}
                disabled={
                  @run_ui.phase == :running ||
                    !run_configuration_available?(@schema_allowlist, @scrypath_opts)
                }
              >
                Run playbook
              </.ops_button>
              <.ops_button
                :if={@run_ui.phase == :running}
                phx-click="cancel_run"
                variant={:ghost}
                size={:md}
              >
                Cancel run
              </.ops_button>
            </div>

            <p :if={@schema_allowlist == []} class="text-ops-body text-base-content/75">
              Add allowlisted schema modules with <code>schema_allowlist</code>
              under <code>:scrypath_ops</code>
              or <code>SCRYPATH_OPS_SCHEMAS</code>, then reload this screen.
            </p>
            <p
              :if={!Keyword.has_key?(@scrypath_opts, :backend)}
              class="text-ops-body text-base-content/75"
            >
              Configure the host application's Scrypath backend to enable playbook runs.
            </p>

            <div class="max-w-2xl space-y-2">
              <.ops_heading level={3}>Save playbook to workspace</.ops_heading>
              <p class="text-ops-body text-base-content/75">
                Saving a workspace playbook replaces a file with the same filename. Rename and duplicate require an unused destination.
              </p>
              <div :if={@workspace_configured?}>
                <.form
                  id="playbook-save-form"
                  for={%{}}
                  phx-submit="save"
                  class="flex flex-wrap gap-3 items-end"
                >
                  <.ops_field id="save_basename" label="Filename" class="w-64">
                    <.ops_text_input
                      id="save_basename"
                      name="basename"
                      value={@save_basename}
                      class="font-mono text-ops-body"
                      placeholder="my-playbook.json"
                      aria-describedby={
                        if @save_error,
                          do: "save_basename-hint save-basename-error",
                          else: "save_basename-hint"
                      }
                    />
                    <p id="save_basename-hint" class="text-ops-body text-base-content/70">
                      Use a filename ending in .json.
                    </p>
                    <p
                      :if={@save_error}
                      id="save-basename-error"
                      role="alert"
                      class="text-ops-body text-error"
                    >
                      {@save_error}
                    </p>
                  </.ops_field>
                  <.ops_button type="submit" variant={:secondary}>
                    Save playbook to workspace
                  </.ops_button>
                </.form>
              </div>
              <div
                :if={!@workspace_configured?}
                id="playbook-save-guidance"
                class="flex flex-wrap items-center gap-3"
              >
                <.ops_button type="button" variant={:secondary} disabled>
                  Save playbook to workspace
                </.ops_button>
                <p class="text-ops-body text-base-content/75">
                  <%= if @examples_mode? do %>
                    Examples can be previewed and run. Configure a playbook workspace directory to enable saving and file changes.
                  <% else %>
                    Configure a playbook workspace directory, then retry saving.
                  <% end %>
                </p>
              </div>
            </div>
          </section>

          <section
            :if={@run_snapshot}
            id="playbook-run-outcome"
            aria-labelledby="playbook-run-outcome-heading"
            class="space-y-4"
          >
            <.ops_heading level={2} id="playbook-run-outcome-heading">
              {run_outcome_heading(
                @run_ui.phase,
                earlier_run?(@run_snapshot, @draft_playbook, @draft_origin)
              )}
            </.ops_heading>
            <.ops_notice :if={@run_ui.phase == :running} kind={:running} title="Running playbook">
              Applying results for run <code>{@run_snapshot.run_id}</code> only.
            </.ops_notice>
            <.ops_notice
              :if={@run_ui.phase == :error && @run_failure_enriched}
              kind={:error}
              title="Playbook run could not complete."
              role="alert"
              data-testid="run-failure-panel"
            >
              <p class="text-ops-body">Failure category: {@run_failure_enriched.failure_class}</p>
              <p>{@run_failure_enriched.message}</p>
              <div class="mt-3 flex flex-wrap gap-2">
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
            </.ops_notice>
            <.ops_status
              :if={@run_ui.phase == :ok && @run_result}
              kind={result_kind(@run_result)}
              title={result_title(@run_result)}
            >
              {run_result_summary(@run_result)}
            </.ops_status>
            <.ops_data_card title="Submitted run criteria" subtitle="Captured when this run started.">
              <dl class="grid gap-3 text-ops-body sm:grid-cols-2">
                <div
                  :for={{label, value} <- playbook_summary(@run_snapshot.draft, @run_snapshot.origin)}
                  id={if label == "Draft source", do: "playbook-run-source"}
                  class="min-w-0"
                >
                  <dt class="text-ops-sm font-semibold uppercase tracking-wide text-base-content/60">
                    {label}
                  </dt>
                  <dd class="mt-1 whitespace-pre-wrap break-words text-ops-body text-base-content">
                    {value}
                  </dd>
                </div>
              </dl>
            </.ops_data_card>
            <.ops_link_button
              :if={@run_ui.phase == :ok && search_loopback_path(@mount_path, @run_snapshot.draft)}
              navigate={search_loopback_path(@mount_path, @run_snapshot.draft)}
              variant={:ghost}
              size={:sm}
            >
              Explore this query in Search <span aria-hidden="true">→</span>
            </.ops_link_button>
          </section>

          <div class="divider" />

          <section id="playbook-import" aria-labelledby="playbook-import-heading" class="space-y-4">
            <.ops_heading level={2} id="playbook-import-heading">Import playbook JSON</.ops_heading>
            <p
              :if={@import_error}
              id="playbook-import-error"
              role="alert"
              class="text-ops-body text-error"
            >
              {@import_error}
            </p>
            <.ops_upload_box
              label="Import playbook file"
              control_id={@uploads.playbook_file.ref}
              hint={"JSON only, max #{@max_import_bytes} bytes. Preview before running."}
              class="max-w-xl"
            >
              <.form
                for={%{}}
                phx-change="validate_upload"
                phx-submit="import_upload"
                class="space-y-3"
              >
                <.live_file_input
                  upload={@uploads.playbook_file}
                  aria-describedby={upload_described_by(@uploads.playbook_file, @import_error)}
                  class="file-input file-input-bordered w-full max-w-md"
                />
                <div
                  :if={playbook_upload_error_messages(@uploads.playbook_file) != []}
                  id="playbook-upload-error"
                  role="alert"
                  class="text-ops-body text-error"
                >
                  <p :for={message <- playbook_upload_error_messages(@uploads.playbook_file)}>
                    {message}
                  </p>
                </div>
                <.ops_button type="submit" variant={:primary}>Import playbook JSON</.ops_button>
              </.form>
            </.ops_upload_box>

            <details open={@paste_open} class="max-w-xl">
              <summary class="cursor-pointer text-ops-body link link-hover">Or paste JSON</summary>
              <.form for={%{}} phx-submit="import_paste" class="mt-2 space-y-2">
                <.ops_field
                  id="playbook-paste-json"
                  label="Playbook JSON"
                  hint={"Paste a valid playbook JSON document (max #{@max_import_bytes} bytes)."}
                >
                  <.ops_textarea
                    id="playbook-paste-json"
                    name="json"
                    value={@paste_json}
                    hint={"Paste a valid playbook JSON document (max #{@max_import_bytes} bytes)."}
                    aria-describedby={
                      if @import_error,
                        do: "playbook-paste-json-hint playbook-import-error",
                        else: "playbook-paste-json-hint"
                    }
                    class="font-mono text-ops-body"
                    placeholder="Paste playbook JSON"
                  />
                </.ops_field>
                <.ops_button type="submit" variant={:ghost}>Import from paste</.ops_button>
              </.form>
            </details>
          </section>

          <.ops_modal
            :if={@delete_pending}
            id="delete-playbook-modal"
            title="Delete playbook file"
            description={delete_description(@delete_pending)}
            action_label="delete"
            initial_focus="[data-ops-modal-cancel]"
            successor={delete_successor(@catalog_entries, @delete_pending)}
            successor_name={delete_successor_name(@catalog_entries, @delete_pending)}
            focus_error="#delete-confirm-input"
            focus_request={@modal_focus_request}
            cancel_event="cancel_delete"
          >
            <.form for={%{}} phx-submit="confirm_delete" class="space-y-3">
              <.ops_field
                id="delete-confirm-input"
                error={@file_action_error}
                label="Type Filename to confirm"
                hint="Enter the exact filename shown above to confirm this irreversible deletion."
              >
                <.ops_text_input
                  id="delete-confirm-input"
                  error={@file_action_error}
                  name="confirm"
                  value={@delete_confirmation}
                  hint="Enter the exact filename shown above to confirm this irreversible deletion."
                  class="font-mono text-ops-body"
                  autocomplete="off"
                />
              </.ops_field>
              <div class="flex justify-between gap-2">
                <.ops_button
                  phx-click="cancel_delete"
                  variant={:ghost}
                  aria-label="Cancel delete"
                  data-ops-modal-cancel
                >
                  Cancel
                </.ops_button>
                <.ops_button type="submit" variant={:danger}>Confirm delete</.ops_button>
              </div>
            </.form>
          </.ops_modal>

          <.ops_modal
            :if={@rename_modal}
            id="rename-playbook-modal"
            title="Rename playbook"
            description={"Rename #{@rename_modal.from}."}
            action_label="rename"
            initial_focus="#rename-new-name-input"
            successor={"#playbook-manage-summary-#{playbook_dom_id(@rename_modal.new_name)}"}
            successor_name={@rename_modal.new_name}
            fallback_successor="#playbook-catalog-heading"
            focus_error="#rename-new-name-input"
            focus_request={@modal_focus_request}
            cancel_event="rename_cancel"
          >
            <.form for={%{}} phx-change="rename_change" phx-submit="rename_submit" class="space-y-3">
              <.ops_field
                id="rename-new-name-input"
                error={@file_action_error}
                label="Filename"
                hint="End the filename with .json."
              >
                <.ops_text_input
                  id="rename-new-name-input"
                  error={@file_action_error}
                  name="new_name"
                  value={@rename_modal.new_name}
                  hint="End the filename with .json."
                  class="font-mono text-ops-body"
                  placeholder="new-name.json"
                />
              </.ops_field>
              <div class="flex justify-between gap-2">
                <.ops_button
                  phx-click="rename_cancel"
                  variant={:ghost}
                  aria-label="Cancel rename"
                  data-ops-modal-cancel
                >
                  Cancel
                </.ops_button>
                <.ops_button type="submit" variant={:primary}>Rename</.ops_button>
              </div>
            </.form>
          </.ops_modal>

          <.ops_modal
            :if={@duplicate_modal}
            id="duplicate-playbook-modal"
            title="Duplicate playbook"
            description={"Create a copy of #{@duplicate_modal.from}."}
            action_label="duplicate"
            initial_focus="#dup-to-name-input"
            successor={"#playbook-manage-summary-#{playbook_dom_id(@duplicate_modal.from)}"}
            successor_name={@duplicate_modal.from}
            fallback_successor="#playbook-catalog-heading"
            focus_error="#dup-to-name-input"
            focus_request={@modal_focus_request}
            cancel_event="dup_cancel"
          >
            <.form for={%{}} phx-change="dup_change" phx-submit="dup_submit" class="space-y-3">
              <.ops_field
                id="dup-to-name-input"
                error={@file_action_error}
                label="Filename"
                hint="End the filename with .json."
              >
                <.ops_text_input
                  id="dup-to-name-input"
                  error={@file_action_error}
                  name="to_name"
                  value={@duplicate_modal.new_name}
                  hint="End the filename with .json."
                  class="font-mono text-ops-body"
                />
              </.ops_field>
              <div class="flex justify-between gap-2">
                <.ops_button
                  phx-click="dup_cancel"
                  variant={:ghost}
                  aria-label="Cancel duplicate"
                  data-ops-modal-cancel
                >
                  Cancel
                </.ops_button>
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
    typed = text_param(typed)
    root = socket.assigns.workspace_root

    cond do
      pending == nil ->
        socket

      not socket.assigns.workspace_configured? ->
        file_action_error(socket, "Delete is disabled for read-only examples.")

      typed != pending ->
        file_action_error(socket, "Confirmation must match the filename exactly.")

      true ->
        case Store.delete_workspace_file(root, pending) do
          :ok ->
            socket =
              socket
              |> reload_workspace_catalog()
              |> assign(:delete_pending, nil)
              |> assign(:delete_confirmation, nil)

            socket =
              if socket.assigns.selected_basename == pending do
                socket
                |> assign(:selected_basename, nil)
                |> assign(:draft_playbook, nil)
                |> assign(:draft_origin, nil)
                |> assign(:preview_json, nil)
                |> assign(:preview_marker, false)
                |> assign(:run_result, nil)
                |> assign(:run_error, nil)
              else
                socket
              end

            put_flash(socket, :info, "Deleted #{pending}")

          {:error, _} ->
            file_action_error(socket, "Delete failed — check permissions.")
        end
    end
  end

  defp file_action_error(socket, message) do
    socket
    |> assign(:file_action_error, message)
    |> update(:modal_focus_request, &(&1 + 1))
  end

  defp delete_description(name) do
    "This permanently deletes #{name} from the playbook workspace. This cannot be undone."
  end

  defp playbook_dom_id(name), do: Base.url_encode64(name, padding: false)

  defp delete_successor(entries, pending) do
    case delete_successor_name(entries, pending) do
      nil -> "#playbook-catalog-heading"
      name -> "#playbook-primary-#{playbook_dom_id(name)}"
    end
  end

  defp delete_successor_name(entries, pending) do
    index = Enum.find_index(entries, &(&1.name == pending))

    if is_integer(index) and index < length(entries) - 1 do
      Enum.at(entries, index + 1).name
    else
      nil
    end
  end

  defp normalize_live_reply({:noreply, %Phoenix.LiveView.Socket{} = socket}), do: socket
  defp normalize_live_reply(%Phoenix.LiveView.Socket{} = socket), do: socket
  defp normalize_live_reply(other), do: other
end
