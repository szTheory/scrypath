defmodule ScrypathOpsWeb.SavedSearchLive do
  @moduledoc """
  Operator saved search library at `/ops/playbooks`: import, preview, run, save, rename,
  duplicate and delete saved searches stored with `ScrypathOps.SavedSearches` in the host Repo.

  ## Delete confirmation

  Deleting a saved search requires typing its exact name into the confirmation
  field and submitting **Confirm delete** — see UI-SPEC destructive copy.
  """

  use ScrypathOpsWeb, :live_view

  alias ScrypathOps.SavedSearches
  alias ScrypathOps.SavedSearches.DocResolver
  alias ScrypathOps.SavedSearches.RunFailure
  alias ScrypathOps.SavedSearches.SavedSearch
  alias ScrypathOps.SavedSearches.Runner
  alias ScrypathOps.SavedSearches.V1
  alias ScrypathOps.Integrations.Sigra.Gating
  alias ScrypathOps.Schemas
  alias Scrypath.MultiSearchResult
  alias Scrypath.SearchResult

  @max_import_bytes 256_000
  @saved_search_run_async_key :saved_search_run
  # Named async key keeps run cancellation and result routing explicit.
  @saved_search_run_timeout_ms 60_000

  @impl true
  def mount(_params, _session, socket) do
    saved_search_schema_doc = DocResolver.resolve(:saved_search_schema)

    socket =
      socket
      |> assign(:page_title, "Saved searches")
      |> reload_catalog()
      |> assign(:file_action_error, nil)
      |> assign(:modal_focus_request, 0)
      |> assign(:delete_confirmation, nil)
      |> assign(:rename_modal, nil)
      |> assign(:duplicate_modal, nil)
      |> assign(:schema_allowlist, Schemas.allowlist())
      |> assign(:scrypath_opts, Schemas.scrypath_opts())
      |> assign(:draft_saved_search, nil)
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
      |> assign(:saved_search_schema_doc, saved_search_schema_doc)
      |> assign(:max_import_bytes, @max_import_bytes)
      |> allow_upload(:saved_search_file,
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
    upload = socket.assigns.uploads.saved_search_file

    case saved_search_upload_error_reason(upload) do
      reason when not is_nil(reason) ->
        {:noreply,
         import_failure(
           socket,
           :upload,
           %{kind: :imported, name: "uploaded file"},
           upload_error_text(reason)
         )}

      nil ->
        case Phoenix.LiveView.uploaded_entries(socket, :saved_search_file) do
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
               "Wait for the file to finish uploading, then import it."
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

    with true <- SavedSearches.valid_name?(name),
         {:ok, saved_search} <- SavedSearches.get(repo(socket), name, store_opts(socket)) do
      {:noreply,
       apply_validated(
         socket,
         V1.validate(saved_search.definition),
         :load,
         %{kind: :saved, name: saved_search.name}
       )}
    else
      false ->
        {:noreply, put_flash(socket, :error, "Invalid saved search name.")}

      {:error, :not_found} ->
        {:noreply,
         socket
         |> reload_catalog()
         |> put_flash(:error, "That saved search no longer exists.")}
    end
  end

  def handle_event("run_now", %{"name" => name}, socket) do
    socket = maybe_supersede_running_run(socket)
    name = text_param(name)

    with :ok <- validate_catalog_name(name),
         {:ok, saved_search} <- SavedSearches.get(repo(socket), name, store_opts(socket)),
         {:ok, validated} <- V1.validate(saved_search.definition),
         preview <- Jason.encode!(validated, pretty: true) do
      socket =
        socket
        |> assign(:draft_origin, %{kind: :saved, name: saved_search.name})
        |> assign(:selected_basename, name)
        |> assign(:draft_saved_search, validated)
        |> assign(:preview_json, preview)
        |> assign(:preview_marker, true)
        |> assign(:save_basename, "")
        |> assign(:save_error, nil)
        |> assign(:import_error, nil)
        |> put_flash(:info, flash_for_import(:load))
        |> schedule_saved_search_run()

      {:noreply, socket}
    else
      {:error, :invalid_name} ->
        {:noreply, put_flash(socket, :error, "Invalid saved search name.")}

      {:error, :not_found} ->
        {:noreply,
         socket
         |> reload_catalog()
         |> put_flash(:error, "That saved search no longer exists.")}

      {:error, {:invalid_saved_search, reason}} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "Saved search could not be imported: #{format_validation_reason(reason)}"
         )}
    end
  end

  def handle_event("run", _params, socket) do
    {:noreply, schedule_saved_search_run(socket)}
  end

  def handle_event("cancel_run", _params, socket) do
    {:noreply, cancel_active_run(socket, {:shutdown, :cancel})}
  end

  # Old clients may still send this event. Clipboard success is reported by the
  # browser only; a server reply cannot establish that a copy happened.
  def handle_event("copy_run_diagnostics", _params, socket), do: {:noreply, socket}

  def handle_event("save", %{"basename" => name}, socket) do
    name = name |> text_param() |> String.trim()
    socket = socket |> assign(:save_basename, name) |> assign(:save_error, nil)

    cond do
      not SavedSearches.valid_name?(name) ->
        {:noreply,
         socket
         |> assign(:save_error, name_rule_message())
         |> put_flash(:error, "Enter a valid name.")}

      socket.assigns.draft_saved_search == nil ->
        {:noreply,
         socket
         |> assign(:save_error, "Import or load a valid saved search before saving.")
         |> put_flash(:error, "Preview or import a saved search first.")}

      true ->
        case SavedSearches.save(
               repo(socket),
               name,
               socket.assigns.draft_saved_search,
               store_opts(socket)
             ) do
          {:ok, saved_search} ->
            {:noreply,
             socket
             |> reload_catalog()
             |> assign(:save_basename, "")
             |> assign(:save_error, nil)
             |> assign(:draft_origin, %{kind: :saved, name: saved_search.name})
             |> assign(:selected_basename, saved_search.name)
             |> put_flash(:info, "Saved #{saved_search.name}")}

          {:error, :invalid_name} ->
            {:noreply,
             socket
             |> assign(:save_error, name_rule_message())
             |> put_flash(:error, "Enter a valid name.")}

          {:error, _reason} ->
            {:noreply,
             socket
             |> assign(:save_error, "Could not save this search. Retry saving.")
             |> put_flash(:error, "Could not save this search.")}
        end
    end
  end

  def handle_event("request_delete", %{"name" => name}, socket) do
    name = text_param(name)

    if SavedSearches.valid_name?(name) do
      {:noreply,
       socket
       |> assign(:file_action_error, nil)
       |> assign(:delete_confirmation, nil)
       |> assign(:delete_pending, name)}
    else
      {:noreply, put_flash(socket, :error, "Invalid saved search name.")}
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
      Gating.gate_sensitive_action(socket, :saved_search_delete, fn ->
        confirm_delete(socket, typed)
      end)

    {:noreply, normalize_live_reply(socket)}
  end

  def handle_event("refresh_list", _params, socket) do
    {:noreply, reload_catalog(socket)}
  end

  def handle_event("rename_open", %{"name" => name}, socket) do
    name = text_param(name)

    if SavedSearches.valid_name?(name) do
      {:noreply,
       socket
       |> assign(:file_action_error, nil)
       |> assign(:rename_modal, %{from: name, new_name: ""})}
    else
      {:noreply, put_flash(socket, :error, "Invalid saved search name.")}
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

    if SavedSearches.valid_name?(name) do
      suggested = SavedSearches.suggest_duplicate_name(repo(socket), name, store_opts(socket))

      {:noreply,
       socket
       |> assign(:file_action_error, nil)
       |> assign(:duplicate_modal, %{from: name, to: suggested, new_name: suggested})}
    else
      {:noreply, put_flash(socket, :error, "Invalid saved search name.")}
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
  def handle_async({@saved_search_run_async_key, run_id}, {:ok, {:ok, result}}, socket) do
    if active_run?(socket, run_id) do
      emit_run_stop(socket.assigns.run_ui, run_id, :ok)

      {:noreply,
       socket
       |> assign(:run_result, result)
       |> assign(:run_error, nil)
       |> assign(:run_failure_enriched, nil)
       |> assign(:run_ui, %{phase: :ok, run_id: run_id, started_monotonic: nil})
       |> put_flash(:info, "Search completed.")}
    else
      {:noreply, socket}
    end
  end

  def handle_async({@saved_search_run_async_key, run_id}, {:ok, {:error, reason}}, socket) do
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

  def handle_async({@saved_search_run_async_key, run_id}, {:exit, reason}, socket) do
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
  def handle_info({:saved_search_run_timeout, run_id}, socket) do
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
    apply_validated(socket, decode_and_validate_saved_search(bin), source, origin)
  end

  defp apply_validated(socket, result, source, origin) do
    case result do
      {:ok, validated} ->
        preview = Jason.encode!(validated, pretty: true)

        socket
        |> assign(:draft_saved_search, validated)
        |> assign(:draft_origin, origin)
        |> assign(:preview_json, preview)
        |> assign(:preview_marker, true)
        |> assign(:selected_basename, selected_name(origin))
        |> assign(:save_basename, "")
        |> assign(:save_error, nil)
        |> assign(:import_error, nil)
        |> assign(:run_failure_enriched, nil)
        |> put_flash(:info, flash_for_import(source))

      {:error, {:invalid_saved_search, reason}} ->
        import_failure(
          socket,
          source,
          origin,
          "Saved search could not be imported: #{format_validation_reason(reason)}"
        )

      {:error, :invalid_json} ->
        import_failure(socket, source, origin, "This file is not valid saved search JSON.")
    end
  end

  defp import_failure(socket, source, _origin, detail) when source in [:paste, :upload] do
    message =
      if socket.assigns.draft_saved_search do
        "Could not import saved search JSON. #{detail} The previous valid preview remains selected."
      else
        "Could not import saved search JSON. #{detail} No previous valid preview is available."
      end

    assign(socket, :import_error, message)
  end

  defp import_failure(socket, _source, origin, detail) do
    message =
      "Could not import saved search JSON from #{origin.name}. #{detail} No valid preview is selected."

    socket
    |> assign(:draft_saved_search, nil)
    |> assign(:draft_origin, nil)
    |> assign(:preview_json, nil)
    |> assign(:preview_marker, false)
    |> assign(:selected_basename, nil)
    |> assign(:import_error, message)
    |> assign(:run_failure_enriched, nil)
  end

  defp import_uploaded_entries(socket) do
    case consume_uploaded_entries(socket, :saved_search_file, fn %{path: path}, entry ->
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

  defp saved_search_upload_error_reason(upload) do
    upload.errors
    |> Enum.map(fn {_ref, reason} -> reason end)
    |> List.first()
  end

  defp saved_search_upload_error_messages(upload) do
    upload.errors
    |> Enum.map(fn {_ref, reason} -> reason end)
    |> Enum.uniq()
    |> Enum.map(&upload_error_text/1)
  end

  defp upload_described_by(upload, import_error) do
    upload_errors? = saved_search_upload_error_messages(upload) != []

    [
      "#{upload.ref}-hint",
      if(import_error, do: "saved-search-import-error"),
      if(upload_errors?, do: "saved-search-upload-error")
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" ")
  end

  defp upload_error_text(:too_large), do: "This file exceeds the 256,000-byte import limit."
  defp upload_error_text(:not_accepted), do: "Choose a file ending in .json."
  defp upload_error_text(:too_many_files), do: "Choose one saved search JSON file at a time."
  defp upload_error_text(:external_client_failure), do: "The file upload could not be completed."

  defp upload_error_text({:writer_failure, _reason}),
    do: "The file upload could not be completed."

  defp upload_error_text(_), do: "The selected file could not be accepted."

  defp selected_name(%{kind: :saved, name: name}), do: name
  defp selected_name(_origin), do: nil

  defp text_param(value) when is_binary(value), do: value
  defp text_param(_value), do: ""

  defp flash_for_import(:paste), do: "Imported saved search from paste."
  defp flash_for_import(:upload), do: "Imported saved search from file."
  defp flash_for_import(:load), do: "Loaded saved search."

  defp name_rule_message do
    "Enter a name of up to #{SavedSearch.max_name_length()} characters."
  end

  defp rename_submit_impl(socket, from, new_name) do
    new_name = new_name |> text_param() |> String.trim()

    if SavedSearches.valid_name?(new_name) do
      case SavedSearches.rename(repo(socket), from, new_name, store_opts(socket)) do
        {:ok, saved_search} ->
          socket =
            socket
            |> assign(:rename_modal, nil)
            |> reload_catalog()

          socket =
            if socket.assigns.selected_basename == from do
              socket
              |> assign(:selected_basename, saved_search.name)
              |> assign(:draft_origin, %{kind: :saved, name: saved_search.name})
            else
              socket
            end

          {:noreply, put_flash(socket, :info, "Renamed to #{saved_search.name}")}

        {:error, :name_taken} ->
          {:noreply, file_action_error(socket, "That name is already in use. Choose another.")}

        {:error, :not_found} ->
          {:noreply,
           socket
           |> reload_catalog()
           |> file_action_error("That saved search no longer exists.")}

        {:error, :invalid_name} ->
          {:noreply, file_action_error(socket, name_rule_message())}

        {:error, _reason} ->
          {:noreply, file_action_error(socket, "Rename failed. Retry renaming.")}
      end
    else
      {:noreply, file_action_error(socket, name_rule_message())}
    end
  end

  defp dup_submit_impl(socket, from, to_name) do
    to_name = to_name |> text_param() |> String.trim()

    if SavedSearches.valid_name?(to_name) do
      case SavedSearches.duplicate(repo(socket), from, to_name, store_opts(socket)) do
        {:ok, saved_search} ->
          {:noreply,
           socket
           |> assign(:duplicate_modal, nil)
           |> reload_catalog()
           |> put_flash(:info, "Duplicated to #{saved_search.name}")}

        {:error, :name_taken} ->
          {:noreply, file_action_error(socket, "That name is already in use. Choose another.")}

        {:error, :not_found} ->
          {:noreply,
           socket
           |> reload_catalog()
           |> file_action_error("That saved search no longer exists.")}

        {:error, :invalid_name} ->
          {:noreply, file_action_error(socket, name_rule_message())}

        {:error, _reason} ->
          {:noreply, file_action_error(socket, "Duplicate failed. Retry duplicating.")}
      end
    else
      {:noreply, file_action_error(socket, name_rule_message())}
    end
  end

  defp format_validation_reason({:page_size_out_of_range, n, max}),
    do: "Results per schema must be between 1 and #{max}; received #{n}."

  defp format_validation_reason(reason) do
    reason |> inspect() |> String.slice(0, 240)
  end

  defp format_run_flash({:page_size_out_of_range, n, max}),
    do: "Results per schema must be between 1 and #{max}; received #{n}."

  defp format_run_flash({:config, :missing_backend}),
    do: "Search failed: Scrypath backend is not configured."

  defp format_run_flash({:config, :empty_allowlist}),
    do: "Search failed: schema allowlist is empty."

  defp format_run_flash({:config, :no_schema}),
    do: "Search failed: schema is not on the configured allowlist."

  defp format_run_flash({:config, :invalid_query}),
    do: "Search failed: query field is invalid."

  defp format_run_flash({:config, :invalid_entries}),
    do: "Search failed: entries list is invalid."

  defp format_run_flash({:config, :invalid_entry_shape}),
    do: "Search failed: an entry has an invalid shape."

  defp format_run_flash(:cancelled),
    do: "Search canceled before results were returned."

  defp format_run_flash(:timed_out),
    do: "Search timed out before results were returned."

  defp format_run_flash(other),
    do: "Search failed: #{inspect(other)} — adjust entries or operator config, then run again."

  defp repo(socket), do: socket.assigns.scrypath_repo

  defp store_opts(socket), do: [prefix: socket.assigns[:scrypath_ops_prefix]]

  defp reload_catalog(socket) do
    entries =
      socket
      |> repo()
      |> SavedSearches.list(store_opts(socket))
      |> Enum.map(&catalog_row/1)

    assign(socket, :catalog_entries, entries)
  end

  defp catalog_row(saved_search) do
    case V1.validate(saved_search.definition) do
      {:ok, validated} ->
        %{
          name: saved_search.name,
          display_title: display_title(Map.get(validated, "title")),
          description: description_text(Map.get(validated, "description")),
          readable?: true
        }

      {:error, _reason} ->
        %{
          name: saved_search.name,
          display_title: "Untitled saved search",
          description: "",
          readable?: false
        }
    end
  end

  defp display_title(title) when is_binary(title) do
    case String.trim(title) do
      "" -> "Untitled saved search"
      trimmed -> trimmed
    end
  end

  defp display_title(_title), do: "Untitled saved search"

  defp description_text(description) when is_binary(description), do: description
  defp description_text(_description), do: ""

  defp validate_catalog_name(name) do
    if SavedSearches.valid_name?(name), do: :ok, else: {:error, :invalid_name}
  end

  defp decode_and_validate_saved_search(bin) do
    case Jason.decode(bin) do
      {:ok, %{} = map} -> V1.validate(map)
      {:ok, _} -> {:error, :invalid_json}
      {:error, _} -> {:error, :invalid_json}
    end
  end

  defp schedule_saved_search_run(socket) do
    case socket.assigns do
      %{draft_saved_search: nil} ->
        put_flash(socket, :error, "Preview a saved search or import one before running.")

      %{run_ui: %{phase: :running}} ->
        socket

      assigns ->
        run_id = next_run_id(assigns.run_ui)
        draft = assigns.draft_saved_search
        allowlist = assigns.schema_allowlist
        scrypath_opts = assigns.scrypath_opts
        snapshot = %{run_id: run_id, draft: draft, origin: assigns.draft_origin}

        Process.send_after(
          self(),
          {:saved_search_run_timeout, run_id},
          @saved_search_run_timeout_ms
        )

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

  defp run_async_key(run_id), do: {@saved_search_run_async_key, run_id}

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
  # single-target saved searches and shared-query federated saved searches; omit it when entries
  # have different queries rather than sending the operator to a different search.
  defp search_loopback_path(mount_path, %{"mode" => "search", "schema" => schema} = saved_search) do
    params = %{"mode" => "single", "q" => Map.get(saved_search, "q", ""), "schema" => schema}
    "#{mount_path}/search?" <> URI.encode_query(add_page_size(params, saved_search))
  end

  defp search_loopback_path(
         mount_path,
         %{"mode" => "search_many", "entries" => entries} = saved_search
       )
       when is_list(entries) and entries != [] do
    queries = Enum.map(entries, fn [_schema, query, _opts] -> query end)

    if length(Enum.uniq(queries)) == 1 do
      schemas = Enum.map(entries, fn [schema, _query, _opts] -> schema end)
      params = %{"mode" => "multi", "q" => hd(queries), "schemas" => Enum.join(schemas, ",")}
      "#{mount_path}/search?" <> URI.encode_query(add_page_size(params, saved_search))
    end
  end

  defp search_loopback_path(_mount_path, _saved_search), do: nil

  defp add_page_size(params, saved_search) do
    page_size = get_in(saved_search, ["opts", "page", "size"])
    if is_integer(page_size), do: Map.put(params, "page_size", page_size), else: params
  end

  defp saved_search_summary(nil, _origin), do: []

  defp saved_search_summary(saved_search, origin) when is_map(saved_search) do
    opts = Map.get(saved_search, "opts") || %{}
    page = Map.get(opts, "page") || %{}
    entries = Map.get(saved_search, "entries") || []
    multi? = Map.get(saved_search, "mode") == "search_many"

    [
      {"Search title", Map.get(saved_search, "title")},
      {"Description", Map.get(saved_search, "description")},
      {"Mode", if(multi?, do: "Multiple schemas", else: "One schema")},
      {if(multi?, do: "Targets and queries", else: "Schema"),
       if(multi?, do: entry_target_query_label(entries), else: Map.get(saved_search, "schema"))},
      {"Query", Map.get(saved_search, "q")},
      {"Entries", if(multi?, do: entry_count_label(entries))},
      {"Results per schema", page_summary(saved_search, page)},
      {"Draft source", draft_origin_label(origin)}
    ]
    |> Enum.reject(fn {_label, value} -> value in [nil, "", []] end)
  end

  defp page_summary(saved_search, page) do
    shared = Map.get(page, "size")

    cond do
      is_integer(shared) -> shared
      Map.get(saved_search, "mode") == "search_many" -> multi_page_summary(saved_search)
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

  defp multi_page_summary(_saved_search), do: "Backend default per target"

  defp entry_target_query_label(entries) when is_list(entries) do
    Enum.map_join(entries, "\n", fn
      [schema, query, _opts] -> "#{schema} — #{query}"
      _other -> "Invalid entry"
    end)
  end

  defp entry_target_query_label(_), do: nil

  defp draft_origin_label(%{kind: :saved, name: name}), do: "Saved search · #{name}"

  defp draft_origin_label(%{kind: :imported, name: name}),
    do: "Imported draft · not saved · #{name}"

  defp draft_origin_label(_), do: nil

  defp entry_count_label(entries) when is_list(entries),
    do:
      "#{length(entries)} #{if length(entries) == 1, do: "schema query", else: "schema queries"}"

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
    saved_search = Map.get(snapshot, :draft) || %{}
    origin = Map.get(snapshot, :origin) || %{}
    opts = Map.get(saved_search, "opts") || %{}
    page = Map.get(opts, "page") || %{}

    []
    |> maybe_put_context(:basename, Map.get(origin, :name))
    |> maybe_put_context(:mode, Map.get(saved_search, "mode"))
    |> maybe_put_context(
      :schema,
      Map.get(saved_search, "schema") || snapshot_target_names(saved_search)
    )
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

  defp snapshot_target_names(_saved_search), do: nil

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

  defp result_title(_), do: "Search completed"

  defp maybe_put_context(context, _key, nil), do: context
  defp maybe_put_context(context, key, value), do: Keyword.put(context, key, value)

  defp emit_run_start(run_id) do
    :telemetry.execute(
      [:scrypath_ops, :saved_search_run, :start],
      %{system_time: System.system_time()},
      %{run_id: run_id}
    )
  end

  defp emit_run_stop(%{started_monotonic: started_monotonic}, run_id, result)
       when is_integer(started_monotonic) do
    duration = max(now_ms() - started_monotonic, 0)

    :telemetry.execute(
      [:scrypath_ops, :saved_search_run, :stop],
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
              subtitle="Save queries and options to run again. A saved search can include multiple schemas."
            />
          </div>
        </.ops_toolbar>

        <.ops_trail current={:saved_searches} />

        <p id="saved-search-honesty-panel" class="text-ops-sm text-base-content/70">
          Saved searches contain query inputs, not results. Keep secrets and personal data out of queries.
        </p>

        <div class="space-y-ops-page-gap">
          <.ops_toolbar>
            <.ops_heading level={2} id="saved-search-catalog-heading" tabindex={-1}>
              Your searches
            </.ops_heading>
            <div class="flex flex-wrap gap-2">
              <.ops_link_button href="#saved-search-import" variant={:default}>
                Import JSON
              </.ops_link_button>
              <.ops_button phx-click="refresh_list" variant={:ghost}>
                Refresh list
              </.ops_button>
            </div>
          </.ops_toolbar>

          <.ops_empty_hero
            :if={@catalog_entries == []}
            title="No saved searches yet"
            icon="hero-book-open"
            data-testid="saved-searches-empty-hero"
          >
            Run a query in Search and save it here, or import a saved search JSON file.
            <:actions>
              <.ops_link_button href="#saved-search-import" variant={:primary}>
                Import JSON
              </.ops_link_button>
              <.ops_link_button navigate={"#{@mount_path}/search"} variant={:default}>
                Open Search
              </.ops_link_button>
            </:actions>
          </.ops_empty_hero>

          <.ops_object_list :if={@catalog_entries != []} class="ops-saved-searches">
            <.ops_object_item
              :for={row <- @catalog_entries}
              id={"saved-search-row-#{saved_search_dom_id(row.name)}"}
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
                <span class="ops-saved-search-filename font-mono text-ops-body text-base-content/65">
                  {row.name}
                </span>
              </div>
              <:actions>
                <.ops_action_group>
                  <.ops_button
                    id={"saved-search-primary-#{saved_search_dom_id(row.name)}"}
                    phx-click="load"
                    phx-value-name={row.name}
                    variant={:default}
                    size={:sm}
                  >
                    Preview
                  </.ops_button>
                </.ops_action_group>
                <.ops_action_group :if={
                  @schema_allowlist != [] && Keyword.has_key?(@scrypath_opts, :backend)
                }>
                  <.ops_button
                    :if={@schema_allowlist != [] && Keyword.has_key?(@scrypath_opts, :backend)}
                    phx-click="run_now"
                    phx-value-name={row.name}
                    variant={:ghost}
                    size={:sm}
                    aria-label={"Run #{row.name} without preview"}
                  >
                    Run
                  </.ops_button>
                </.ops_action_group>
                <.ops_disclosure
                  id={"saved-search-manage-#{saved_search_dom_id(row.name)}"}
                  summary_id={"saved-search-manage-summary-#{saved_search_dom_id(row.name)}"}
                  summary="File actions"
                  data-testid="saved-search-manage-actions"
                  data-ops-file-name={row.name}
                  class="ops-saved-search-file-actions"
                >
                  <div class="grid gap-ops-2" role="group" aria-label={"Actions for #{row.name}"}>
                    <div class="flex flex-wrap gap-2">
                      <.ops_button
                        phx-click="dup_open"
                        phx-value-name={row.name}
                        data-ops-modal-trigger="duplicate"
                        data-ops-modal-return={"#saved-search-manage-summary-#{saved_search_dom_id(row.name)}"}
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
                        data-ops-modal-return={"#saved-search-manage-summary-#{saved_search_dom_id(row.name)}"}
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
                        data-ops-modal-return={"#saved-search-manage-summary-#{saved_search_dom_id(row.name)}"}
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
            :if={@draft_saved_search}
            id="saved-search-preview"
            aria-labelledby="saved-search-preview-heading"
            class="space-y-4"
          >
            <.ops_heading level={2} id="saved-search-preview-heading">Preview</.ops_heading>
            <p
              :if={@preview_marker}
              class="text-ops-body text-base-content/70"
              data-testid="saved-search-preview-marker"
            >
              Search inputs ready to run
            </p>
            <.ops_data_card title="Search inputs">
              <dl id="saved-search-summary" class="grid gap-3 text-ops-body sm:grid-cols-2">
                <div
                  :for={{label, value} <- saved_search_summary(@draft_saved_search, @draft_origin)}
                  id={if label == "Draft source", do: "saved-search-draft-origin"}
                  class="min-w-0"
                >
                  <dt class="text-ops-sm font-medium text-base-content/70">
                    {label}
                  </dt>
                  <dd class="mt-1 whitespace-pre-wrap break-words text-ops-body text-base-content">
                    {value}
                  </dd>
                </div>
              </dl>
            </.ops_data_card>
            <.ops_disclosure :if={@preview_json} summary="Saved search JSON" variant={:compact}>
              <.ops_code_block variant={:compact} text={@preview_json} />
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
                Run search
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
              Configure Meilisearch to run saved searches.
            </p>

            <div class="max-w-2xl space-y-2">
              <.ops_heading level={3}>Save search</.ops_heading>
              <p class="text-ops-body text-base-content/75">
                Saving replaces the saved search with the same name. Use a new name to keep both.
              </p>
              <div>
                <.form
                  id="saved-search-save-form"
                  for={%{}}
                  phx-submit="save"
                  class="flex flex-wrap gap-3 items-end"
                >
                  <.ops_field id="save_basename" label="Name" class="w-64">
                    <.ops_text_input
                      id="save_basename"
                      required
                      name="basename"
                      value={@save_basename}
                      class="text-ops-body"
                      placeholder="Daily catalog check"
                      aria-describedby={
                        if @save_error,
                          do: "save_basename-hint save-basename-error",
                          else: "save_basename-hint"
                      }
                    />
                    <p id="save_basename-hint" class="text-ops-body text-base-content/70">
                      Names are unique. Use up to {SavedSearch.max_name_length()} characters.
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
                    Save search
                  </.ops_button>
                </.form>
              </div>
            </div>
          </section>

          <section
            :if={@run_snapshot}
            id="saved-search-run-outcome"
            aria-labelledby="saved-search-run-outcome-heading"
            class="space-y-4"
          >
            <.ops_heading level={2} id="saved-search-run-outcome-heading">
              {run_outcome_heading(
                @run_ui.phase,
                earlier_run?(@run_snapshot, @draft_saved_search, @draft_origin)
              )}
            </.ops_heading>
            <.ops_notice :if={@run_ui.phase == :running} kind={:running} title="Running search">
              Applying results for run <code>{@run_snapshot.run_id}</code> only.
            </.ops_notice>
            <.ops_notice
              :if={@run_ui.phase == :error && @run_failure_enriched}
              kind={:error}
              title="Search could not complete."
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
                <span data-ops-copy-group>
                  <.ops_button
                    variant={:ghost}
                    size={:xs}
                    data-ops-copy-text={Jason.encode!(diagnostics_payload(@run_failure_enriched))}
                  >
                    Copy diagnostics
                  </.ops_button>
                  <span role="status" aria-live="polite" data-ops-copy-feedback></span>
                  <pre data-ops-copy-fallback hidden class="whitespace-pre-wrap break-all text-ops-sm">{Jason.encode!(diagnostics_payload(@run_failure_enriched), pretty: true)}</pre>
                </span>
              </div>
            </.ops_notice>
            <.ops_status
              :if={@run_ui.phase == :ok && @run_result}
              kind={result_kind(@run_result)}
              title={result_title(@run_result)}
            >
              {run_result_summary(@run_result)}
            </.ops_status>
            <.ops_data_card title="Inputs used for these results">
              <dl class="grid gap-3 text-ops-body sm:grid-cols-2">
                <div
                  :for={
                    {label, value} <- saved_search_summary(@run_snapshot.draft, @run_snapshot.origin)
                  }
                  id={if label == "Draft source", do: "saved-search-run-source"}
                  class="min-w-0"
                >
                  <dt class="text-ops-sm font-medium text-base-content/70">
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

          <section
            id="saved-search-import"
            aria-labelledby="saved-search-import-heading"
            class="space-y-4"
          >
            <.ops_heading level={2} id="saved-search-import-heading">
              Import saved search
            </.ops_heading>
            <p
              :if={@import_error}
              id="saved-search-import-error"
              role="alert"
              class="text-ops-body text-error"
            >
              {@import_error}
            </p>
            <.ops_upload_box
              label="Saved search JSON file"
              control_id={@uploads.saved_search_file.ref}
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
                  upload={@uploads.saved_search_file}
                  aria-describedby={upload_described_by(@uploads.saved_search_file, @import_error)}
                  class="file-input file-input-bordered w-full max-w-md"
                />
                <div
                  :if={saved_search_upload_error_messages(@uploads.saved_search_file) != []}
                  id="saved-search-upload-error"
                  role="alert"
                  class="text-ops-body text-error"
                >
                  <p :for={message <- saved_search_upload_error_messages(@uploads.saved_search_file)}>
                    {message}
                  </p>
                </div>
                <.ops_button type="submit" variant={:primary}>Import saved search</.ops_button>
              </.form>
            </.ops_upload_box>

            <details open={@paste_open} class="max-w-xl">
              <summary class="cursor-pointer text-ops-body link link-hover">Or paste JSON</summary>
              <.form for={%{}} phx-submit="import_paste" class="mt-2 space-y-2">
                <.ops_field
                  id="saved-search-paste-json"
                  label="Saved search JSON"
                  hint={"Paste a valid saved search JSON document (max #{@max_import_bytes} bytes)."}
                >
                  <.ops_textarea
                    id="saved-search-paste-json"
                    name="json"
                    required
                    data-ops-json
                    data-ops-max-bytes={@max_import_bytes}
                    value={@paste_json}
                    hint={"Paste a valid saved search JSON document (max #{@max_import_bytes} bytes)."}
                    aria-describedby={
                      if @import_error,
                        do: "saved-search-paste-json-hint saved-search-import-error",
                        else: "saved-search-paste-json-hint"
                    }
                    class="font-mono text-ops-body"
                    placeholder="Paste saved search JSON"
                  />
                </.ops_field>
                <.ops_button type="submit" variant={:ghost}>Import from paste</.ops_button>
              </.form>
            </details>
          </section>

          <.ops_modal
            :if={@delete_pending}
            id="delete-saved-search-modal"
            title="Delete saved search"
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
                label="Type the name to confirm"
                hint="Enter the exact name shown above to confirm this irreversible deletion."
              >
                <.ops_text_input
                  id="delete-confirm-input"
                  error={@file_action_error}
                  name="confirm"
                  value={@delete_confirmation}
                  hint="Enter the exact name shown above to confirm this irreversible deletion."
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
            id="rename-saved-search-modal"
            title="Rename saved search"
            description={"Rename #{@rename_modal.from}."}
            action_label="rename"
            initial_focus="#rename-new-name-input"
            successor={"#saved-search-manage-summary-#{saved_search_dom_id(@rename_modal.new_name)}"}
            successor_name={@rename_modal.new_name}
            fallback_successor="#saved-search-catalog-heading"
            focus_error="#rename-new-name-input"
            focus_request={@modal_focus_request}
            cancel_event="rename_cancel"
          >
            <.form for={%{}} phx-change="rename_change" phx-submit="rename_submit" class="space-y-3">
              <.ops_field
                id="rename-new-name-input"
                error={@file_action_error}
                label="Name"
                hint="Names are unique."
              >
                <.ops_text_input
                  id="rename-new-name-input"
                  required
                  error={@file_action_error}
                  name="new_name"
                  value={@rename_modal.new_name}
                  hint="Names are unique."
                  class="font-mono text-ops-body"
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
            id="duplicate-saved-search-modal"
            title="Duplicate saved search"
            description={"Create a copy of #{@duplicate_modal.from}."}
            action_label="duplicate"
            initial_focus="#dup-to-name-input"
            successor={"#saved-search-manage-summary-#{saved_search_dom_id(@duplicate_modal.from)}"}
            successor_name={@duplicate_modal.from}
            fallback_successor="#saved-search-catalog-heading"
            focus_error="#dup-to-name-input"
            focus_request={@modal_focus_request}
            cancel_event="dup_cancel"
          >
            <.form for={%{}} phx-change="dup_change" phx-submit="dup_submit" class="space-y-3">
              <.ops_field
                id="dup-to-name-input"
                error={@file_action_error}
                label="Name"
                hint="Names are unique."
              >
                <.ops_text_input
                  id="dup-to-name-input"
                  required
                  error={@file_action_error}
                  name="to_name"
                  value={@duplicate_modal.new_name}
                  hint="Names are unique."
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
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp confirm_delete(socket, typed) do
    pending = socket.assigns.delete_pending
    typed = text_param(typed)

    cond do
      pending == nil ->
        socket

      typed != pending ->
        file_action_error(socket, "Confirmation must match the name exactly.")

      true ->
        case SavedSearches.delete(repo(socket), pending, store_opts(socket)) do
          result when result in [:ok, {:error, :not_found}] ->
            socket =
              socket
              |> reload_catalog()
              |> assign(:delete_pending, nil)
              |> assign(:delete_confirmation, nil)

            socket =
              if socket.assigns.selected_basename == pending do
                socket
                |> assign(:selected_basename, nil)
                |> assign(:draft_saved_search, nil)
                |> assign(:draft_origin, nil)
                |> assign(:preview_json, nil)
                |> assign(:preview_marker, false)
                |> assign(:run_result, nil)
                |> assign(:run_error, nil)
              else
                socket
              end

            put_flash(socket, :info, "Deleted #{pending}")
        end
    end
  end

  defp file_action_error(socket, message) do
    socket
    |> assign(:file_action_error, message)
    |> update(:modal_focus_request, &(&1 + 1))
  end

  defp delete_description(name) do
    "This permanently deletes #{name}. This cannot be undone."
  end

  defp saved_search_dom_id(name), do: Base.url_encode64(name, padding: false)

  defp delete_successor(entries, pending) do
    case delete_successor_name(entries, pending) do
      nil -> "#saved-search-catalog-heading"
      name -> "#saved-search-primary-#{saved_search_dom_id(name)}"
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
