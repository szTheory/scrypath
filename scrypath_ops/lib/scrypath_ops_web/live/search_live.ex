defmodule ScrypathOpsWeb.SearchLive do
  @moduledoc """
  Bounded `/ops/search` playground: single- and multi-index queries with
  federation-honest disclosure. All `Scrypath` calls go through
  `ScrypathOps.SearchPlayground.dispatch_*`.

  Saved searches live here too. The toolbar picker loads one into the form and runs it;
  Save and Save as keep the current inputs. The Manage saved searches sheet loads, renames,
  deletes, imports and exports them. `/playbooks` and `?saved=manage` open that sheet.

  Deleting a saved search requires typing its exact name and is gated by Sigra as
  `scrypath.ops.saved_search_delete` when Sigra is configured.
  """

  use ScrypathOpsWeb, :live_view
  import ScrypathOpsWeb.ResultUi

  alias Scrypath.MultiSearchResult
  alias Scrypath.SearchResult
  alias ScrypathOps.Integrations.Sigra.Gating
  alias ScrypathOps.SavedSearches
  alias ScrypathOps.SavedSearches.Runner
  alias ScrypathOps.SavedSearches.SavedSearch
  alias ScrypathOps.SavedSearches.V1
  alias ScrypathOps.Schemas
  alias ScrypathOps.SearchPlayground
  alias ScrypathOpsWeb.SearchLive.SavedSearchForm

  @max_import_bytes 256_000

  @impl true
  def mount(_params, _session, socket) do
    allowlist = Schemas.allowlist()
    scrypath_opts = Schemas.scrypath_opts()

    socket =
      socket
      |> assign(:page_title, "Search")
      |> assign(:mode, :single)
      |> assign(:q, "")
      |> assign(:page_size_error, nil)
      |> assign(:page_size, SearchPlayground.default_page_size())
      |> assign(:schema_allowlist, allowlist)
      |> assign(:scrypath_opts, scrypath_opts)
      |> assign(:selected_schema, List.first(allowlist))
      |> assign(:selected_multi_schemas, Enum.take(allowlist, 2))
      |> assign(:result_single, nil)
      |> assign(:result_multi, nil)
      |> assign(:run_error, nil)
      |> assign(:submitted_search, nil)
      |> assign(:searching, false)
      |> assign(:show_all_footnote, false)
      |> assign(:loaded, nil)
      |> assign(:stored_run, nil)
      |> assign(:name_modal, nil)
      |> assign(:modal_focus_request, 0)
      |> assign(:manage_open, false)
      |> assign(:manage_from_url, false)
      |> assign(:manage_row, nil)
      |> assign(:sheet_focus, nil)
      |> assign(:sheet_focus_request, 0)
      |> assign(:import_error, nil)
      |> assign(:paste_name, "")
      |> assign(:paste_json, "")
      |> assign(:max_import_bytes, @max_import_bytes)
      |> reload_saved_searches()
      |> allow_upload(:saved_search_file,
        accept: ~w(.json),
        max_entries: 1,
        max_file_size: @max_import_bytes,
        auto_upload: true,
        progress: &handle_import_progress/3
      )

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, uri, %{assigns: %{live_action: :legacy_saved_searches}} = socket) do
    mount_path =
      uri
      |> URI.parse()
      |> Map.fetch!(:path)
      |> String.replace_suffix("/playbooks", "")
      |> String.trim_trailing("/")

    {:noreply, push_navigate(socket, to: "#{mount_path}/search?saved=manage", replace: true)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    allowlist = socket.assigns.schema_allowlist

    mode =
      case params["mode"] do
        "multi" -> :multi
        "single" -> :single
        nil -> :single
        _ -> :invalid
      end

    socket =
      case mode do
        :invalid ->
          push_patch(socket, to: search_path(socket, mode: :single))

        m ->
          socket
          |> assign(:mode, m)
          |> assign(:q, params["q"] || socket.assigns.q)
          |> assign(
            :page_size,
            parse_page_size_param(params["page_size"], socket.assigns.page_size)
          )
          |> assign(:selected_schema, selected_schema_from_params(params, allowlist, socket))
          |> assign(
            :selected_multi_schemas,
            selected_multi_from_params(params, allowlist, socket)
          )
          |> maybe_open_manage_from_url(params)
          # Sigra's sudo check returns here, with the Manage sheet open, before a delete.
          |> assign(:return_to, "#{socket.assigns.mount_path}/search?saved=manage")
      end

    {:noreply, socket}
  end

  defp maybe_open_manage_from_url(socket, %{"saved" => "manage"}) do
    if socket.assigns.manage_open,
      do: socket,
      else: socket |> open_manage() |> assign(:manage_from_url, true)
  end

  defp maybe_open_manage_from_url(socket, _params), do: socket

  @impl true
  def handle_event("edit_search", params, socket) do
    draft = capture_search_submission(params, socket)

    socket =
      socket
      |> assign(:q, text_input(params["q"] || ""))
      |> assign(:page_size, draft.page_size)

    # Editing controls does not execute a query or replace its result source.
    socket =
      if socket.assigns.mode == :single,
        do: assign(socket, :selected_schema, draft.schema),
        else: assign(socket, :selected_multi_schemas, draft.schemas)

    {:noreply, socket}
  end

  def handle_event("set_mode", %{"mode" => "multi"}, socket) do
    socket =
      socket
      |> assign(:mode, :multi)
      |> push_patch(to: search_path(socket, mode: :multi))

    {:noreply, socket}
  end

  def handle_event("set_mode", _, socket) do
    socket =
      socket
      |> assign(:mode, :single)
      |> push_patch(to: search_path(socket, mode: :single))

    {:noreply, socket}
  end

  # --- Saved searches: pick, save, save as ---------------------------------------------

  def handle_event("reload_saved_searches", _params, socket),
    do: {:noreply, reload_saved_searches(socket)}

  def handle_event("load_saved_search", %{"name" => name}, socket) when is_binary(name) do
    {:noreply, load_saved_search(socket, name)}
  end

  def handle_event("save_loaded", _params, socket) do
    case socket.assigns.loaded do
      %{exact?: true, name: name, definition: stored} ->
        with {:ok, definition} <- SavedSearchForm.to_definition(current_form(socket.assigns)),
             definition = SavedSearchForm.keep_metadata(definition, stored),
             {:ok, saved} <-
               SavedSearches.save(repo(socket), name, definition, store_opts(socket)) do
          {:noreply,
           socket
           |> assign_loaded(saved.name, saved.definition)
           |> reload_saved_searches()
           |> put_flash(:info, "Saved “#{saved.name}”.")}
        else
          {:error, reason} ->
            {:noreply, put_flash(socket, :error, save_error_text(reason))}
        end

      _other ->
        {:noreply, socket}
    end
  end

  def handle_event("open_save_modal", params, socket) do
    kind = if params["kind"] == "save_as", do: :save_as, else: :new
    {:noreply, assign(socket, :name_modal, %{kind: kind, name: "", error: nil})}
  end

  def handle_event("name_change", %{"name" => name}, socket) do
    case socket.assigns.name_modal do
      %{} = modal -> {:noreply, assign(socket, :name_modal, %{modal | name: text_input(name)})}
      nil -> {:noreply, socket}
    end
  end

  def handle_event("name_change", _params, socket), do: {:noreply, socket}

  def handle_event("cancel_save", _params, socket),
    do: {:noreply, assign(socket, :name_modal, nil)}

  def handle_event("save_named", params, socket) do
    name = params |> Map.get("name") |> text_input() |> String.trim()

    case socket.assigns.name_modal do
      nil ->
        {:noreply, socket}

      modal ->
        modal = %{modal | name: name}

        with true <- SavedSearches.valid_name?(name) || {:error, :invalid_name},
             {:ok, definition} <- SavedSearchForm.to_definition(current_form(socket.assigns)),
             {:ok, saved} <-
               SavedSearches.create(repo(socket), name, definition, store_opts(socket)) do
          {:noreply,
           socket
           |> assign(:name_modal, nil)
           |> assign_loaded(saved.name, saved.definition)
           |> reload_saved_searches()
           |> put_flash(:info, "Saved “#{saved.name}”.")}
        else
          {:error, reason} ->
            {:noreply,
             socket
             |> assign(:name_modal, %{modal | error: save_error_text(reason, name)})
             |> update(:modal_focus_request, &(&1 + 1))}
        end
    end
  end

  # --- Saved searches: Manage sheet ---------------------------------------------------

  def handle_event("open_manage", _params, socket), do: {:noreply, open_manage(socket)}

  def handle_event("close_manage", _params, socket) do
    case socket.assigns.manage_row do
      %{name: name, action: action} ->
        {:noreply,
         socket
         |> assign(:manage_row, nil)
         |> focus_in_sheet("##{row_action_id(action, name)}")}

      nil ->
        {:noreply, close_manage(socket)}
    end
  end

  def handle_event("manage_rename", %{"name" => name}, socket) when is_binary(name) do
    {:noreply,
     socket
     |> assign(:manage_row, %{action: :rename, name: name, value: name, error: nil})
     |> focus_in_sheet("#saved-search-rename-input")}
  end

  def handle_event("manage_delete", %{"name" => name}, socket) when is_binary(name) do
    {:noreply,
     socket
     |> assign(:manage_row, %{action: :delete, name: name, value: "", error: nil})
     |> focus_in_sheet("#saved-search-delete-input")}
  end

  def handle_event("cancel_row", _params, socket), do: handle_event("close_manage", %{}, socket)

  def handle_event("rename_change", %{"new_name" => value}, socket) do
    case socket.assigns.manage_row do
      %{action: :rename} = row ->
        {:noreply, assign(socket, :manage_row, %{row | value: text_input(value)})}

      _other ->
        {:noreply, socket}
    end
  end

  def handle_event("rename_change", _params, socket), do: {:noreply, socket}

  def handle_event("rename_submit", params, socket) do
    case socket.assigns.manage_row do
      %{action: :rename, name: from} = row ->
        to = params |> Map.get("new_name") |> text_input() |> String.trim()
        row = %{row | value: to}

        result =
          cond do
            not SavedSearches.valid_name?(to) -> {:error, :invalid_name}
            to == from -> {:ok, :unchanged}
            true -> SavedSearches.rename(repo(socket), from, to, store_opts(socket))
          end

        case result do
          {:ok, :unchanged} ->
            {:noreply,
             socket
             |> assign(:manage_row, nil)
             |> focus_in_sheet("##{row_action_id(:rename, from)}")}

          {:ok, saved} ->
            {:noreply,
             socket
             |> assign(:manage_row, nil)
             |> rename_loaded(from, saved.name)
             |> reload_saved_searches()
             |> focus_in_sheet("##{row_action_id(:rename, saved.name)}")
             |> put_flash(:info, "Renamed to “#{saved.name}”.")}

          {:error, :not_found} ->
            {:noreply,
             socket
             |> assign(:manage_row, nil)
             |> reload_saved_searches()
             |> focus_in_sheet("#saved-search-manage-title")
             |> put_flash(:error, "“#{from}” no longer exists.")}

          {:error, reason} ->
            {:noreply,
             socket
             |> assign(:manage_row, %{row | error: save_error_text(reason, to)})
             |> focus_in_sheet("#saved-search-rename-input")}
        end

      _other ->
        {:noreply, socket}
    end
  end

  def handle_event("confirm_delete", params, socket) do
    typed = params |> Map.get("confirm") |> text_input()

    socket =
      Gating.gate_sensitive_action(socket, :saved_search_delete, fn ->
        confirm_delete(socket, typed)
      end)

    {:noreply, socket}
  end

  def handle_event("validate_import", _params, socket) do
    upload = socket.assigns.uploads.saved_search_file

    case Enum.find(upload.entries, &(not &1.valid?)) do
      nil ->
        {:noreply, socket}

      entry ->
        message =
          upload
          |> upload_errors(entry)
          |> List.first()
          |> upload_error_text()

        {:noreply,
         socket
         |> cancel_upload(:saved_search_file, entry.ref)
         |> assign(:import_error, "Couldn't import #{entry.client_name}. #{message}")}
    end
  end

  def handle_event("import_upload", _params, socket), do: {:noreply, socket}

  def handle_event("import_paste", params, socket) do
    name = params |> Map.get("name") |> text_input() |> String.trim()
    json = params |> Map.get("json") |> text_input()

    socket = socket |> assign(:paste_name, name) |> assign(:paste_json, json)

    cond do
      byte_size(json) > @max_import_bytes ->
        {:noreply,
         assign(
           socket,
           :import_error,
           "Couldn't import the pasted JSON. It's larger than #{@max_import_bytes} bytes."
         )}

      true ->
        case import_saved_search(socket, name, json) do
          {:ok, socket} ->
            {:noreply, socket |> assign(:paste_name, "") |> assign(:paste_json, "")}

          {:error, message} ->
            {:noreply,
             assign(socket, :import_error, "Couldn't import the pasted JSON. #{message}")}
        end
    end
  end

  def handle_event("search", params, socket) when is_map(params) do
    # Two-step so the loading skeleton paints before the bounded read runs (S2). The
    # Scrypath search dispatch is synchronous; deferring it to handle_info/2 lets LiveView
    # push the `:searching` frame first. Clear prior results immediately so the skeleton
    # isn't drawn over a stale result panel.
    submission = capture_search_submission(params, socket)

    if SearchPlayground.validate_page_size(submission.page_size) == :ok do
      start_search(socket, submission)
    else
      {:noreply,
       socket
       |> assign(:q, submission.query)
       |> assign(:page_size, submission.page_size)
       |> assign(
         :page_size_error,
         "Enter a whole number from 1 to #{SearchPlayground.max_page_size_allowed()}."
       )}
    end
  end

  def handle_event("search_page", %{"direction" => direction}, socket) do
    submission = socket.assigns.submitted_search

    if submission && !socket.assigns.searching && direction in ["next", "previous"] do
      page = max(1, submission.page + if(direction == "next", do: 1, else: -1))

      start_search(socket, %{
        submission
        | id: System.unique_integer([:positive, :monotonic]),
          page: page
      })
    else
      {:noreply, socket}
    end
  end

  def handle_event("search", _params, socket) do
    {:noreply, put_flash(socket, :error, "Search input was invalid. Check the fields and retry.")}
  end

  defp start_search(socket, submission) do
    send(self(), {:run_search, submission})
    {:noreply, socket |> assign(:stored_run, nil) |> assign_running(submission)}
  end

  defp assign_running(socket, submission) do
    socket
    |> assign(:submitted_search, submission)
    |> assign(:mode, submission.mode)
    |> assign(:q, submission.query)
    |> assign(:page_size, submission.page_size)
    |> assign(:selected_schema, submission.schema)
    |> assign(:selected_multi_schemas, submission.schemas)
    |> assign(:result_single, nil)
    |> assign(:result_multi, nil)
    |> assign(:run_error, nil)
    |> assign(:searching, true)
    |> assign(:page_size_error, nil)
  end

  @impl true
  def handle_info({:run_search, submission}, socket) do
    with_saved_run_telemetry(submission, fn -> run_search(submission, socket) end)
  end

  def handle_info({:run_stored, submission, definition}, socket) do
    with_saved_run_telemetry(submission, fn -> run_stored(submission, definition, socket) end)
  end

  defp run_search(submission, socket) do
    start_ms = System.monotonic_time(:millisecond)

    q = submission.query
    page_size = submission.page_size

    allowlist = socket.assigns.schema_allowlist
    scrypath_opts = socket.assigns.scrypath_opts
    mode = submission.mode

    base_socket =
      socket
      |> assign(:q, q)
      |> assign(:page_size, page_size)
      |> assign(:result_single, nil)
      |> assign(:result_multi, nil)
      |> assign(:run_error, nil)
      |> assign(:searching, false)
      |> assign(:show_all_footnote, false)

    with :ok <- SearchPlayground.validate_page_size(page_size),
         {:ok, opts} <- build_opts(scrypath_opts, page_size, mode, submission.page) do
      case mode do
        :single ->
          run_single(base_socket, submission, opts, allowlist, start_ms)

        :multi ->
          run_multi(base_socket, submission, opts, allowlist, start_ms)
      end
    else
      {:error, {:page_size_out_of_range, _, _} = err} ->
        duration_ms = System.monotonic_time(:millisecond) - start_ms
        emit_run(mode, :error, duration_ms)

        {:noreply,
         base_socket
         |> assign(:run_error, err)}

      {:error, :missing_backend} ->
        duration_ms = System.monotonic_time(:millisecond) - start_ms
        emit_run(mode, :error, duration_ms)

        {:noreply,
         base_socket
         |> assign(:run_error, {:config, :missing_backend})}
    end
  end

  defp run_stored(submission, definition, socket) do
    start_ms = System.monotonic_time(:millisecond)
    mode = submission.mode

    socket =
      socket
      |> assign(:result_single, nil)
      |> assign(:result_multi, nil)
      |> assign(:run_error, nil)
      |> assign(:searching, false)
      |> assign(:show_all_footnote, false)

    result =
      Runner.run_validated(
        definition,
        socket.assigns.schema_allowlist,
        socket.assigns.scrypath_opts
      )

    duration_ms = System.monotonic_time(:millisecond) - start_ms

    case result do
      {:ok, %SearchResult{} = res} ->
        emit_run(mode, :ok, duration_ms)
        {:noreply, assign(socket, :result_single, res)}

      {:ok, %MultiSearchResult{failures: failures} = res} ->
        emit_run(mode, if(failures == [], do: :ok, else: :partial), duration_ms)

        footnote? =
          Enum.any?(failures, fn %{reason: r} -> match?({:all_expansion, _}, r) end)

        {:noreply,
         socket
         |> assign(:result_multi, res)
         |> assign(:show_all_footnote, footnote?)}

      {:error, reason} ->
        emit_run(mode, :error, duration_ms)
        {:noreply, assign(socket, :run_error, stored_run_error(reason))}
    end
  end

  # Runs started from a saved search also report `[:scrypath_ops, :saved_search_run, ...]`.
  defp with_saved_run_telemetry(%{saved: name} = submission, fun) when is_binary(name) do
    started = System.monotonic_time(:millisecond)

    :telemetry.execute(
      [:scrypath_ops, :saved_search_run, :start],
      %{system_time: System.system_time()},
      %{run_id: submission.id}
    )

    {:noreply, socket} = fun.()

    :telemetry.execute(
      [:scrypath_ops, :saved_search_run, :stop],
      %{duration: max(System.monotonic_time(:millisecond) - started, 0)},
      %{run_id: submission.id, result: if(socket.assigns.run_error, do: :error, else: :ok)}
    )

    {:noreply, socket}
  end

  defp with_saved_run_telemetry(_submission, fun), do: fun.()

  defp stored_run_error({:config, _} = reason), do: reason
  defp stored_run_error({:page_size_out_of_range, _, _} = reason), do: reason
  defp stored_run_error(reason), do: {:scrypath, reason}

  defp run_single(socket, submission, opts, allowlist, start_ms) do
    mod = submission.schema
    q = submission.query
    page_size = submission.page_size

    socket = assign(socket, :selected_schema, mod)

    cond do
      allowlist == [] ->
        duration_ms = System.monotonic_time(:millisecond) - start_ms
        emit_run(:single, :error, duration_ms)
        {:noreply, assign(socket, :run_error, {:config, :empty_allowlist})}

      mod == nil ->
        duration_ms = System.monotonic_time(:millisecond) - start_ms
        emit_run(:single, :error, duration_ms)
        {:noreply, assign(socket, :run_error, {:config, :no_schema})}

      not Keyword.has_key?(socket.assigns.scrypath_opts, :backend) ->
        duration_ms = System.monotonic_time(:millisecond) - start_ms
        emit_run(:single, :error, duration_ms)
        {:noreply, assign(socket, :run_error, {:config, :missing_backend})}

      true ->
        case SearchPlayground.dispatch_search(mod, q, opts) do
          {:ok, res} ->
            duration_ms = System.monotonic_time(:millisecond) - start_ms
            emit_run(:single, :ok, duration_ms)

            socket =
              socket
              |> assign(:result_single, res)
              |> push_patch(
                to:
                  search_path(socket,
                    mode: :single,
                    q: q,
                    page_size: page_size,
                    schema: mod
                  )
              )

            {:noreply, socket}

          {:error, reason} ->
            duration_ms = System.monotonic_time(:millisecond) - start_ms
            emit_run(:single, :error, duration_ms)
            {:noreply, assign(socket, :run_error, {:scrypath, reason})}
        end
    end
  end

  defp run_multi(socket, submission, opts, allowlist, start_ms) do
    selected = submission.schemas
    q = submission.query
    page_size = submission.page_size

    socket = assign(socket, :selected_multi_schemas, selected)

    max_s = SearchPlayground.max_schemas_allowed()

    cond do
      allowlist == [] ->
        duration_ms = System.monotonic_time(:millisecond) - start_ms
        emit_run(:multi, :error, duration_ms)
        {:noreply, assign(socket, :run_error, {:config, :empty_allowlist})}

      not Keyword.has_key?(socket.assigns.scrypath_opts, :backend) ->
        duration_ms = System.monotonic_time(:millisecond) - start_ms
        emit_run(:multi, :error, duration_ms)
        {:noreply, assign(socket, :run_error, {:config, :missing_backend})}

      length(selected) > max_s ->
        duration_ms = System.monotonic_time(:millisecond) - start_ms
        emit_run(:multi, :error, duration_ms)

        {:noreply, assign(socket, :run_error, {:too_many_schemas, length(selected), max_s})}

      selected == [] ->
        duration_ms = System.monotonic_time(:millisecond) - start_ms
        emit_run(:multi, :error, duration_ms)
        {:noreply, assign(socket, :run_error, {:config, :no_schemas_selected})}

      true ->
        entries = Enum.map(selected, fn mod -> {mod, q, []} end)

        case SearchPlayground.dispatch_search_many(entries, opts) do
          {:ok, %MultiSearchResult{failures: failures} = res} ->
            duration_ms = System.monotonic_time(:millisecond) - start_ms
            outcome = if failures == [], do: :ok, else: :partial
            emit_run(:multi, outcome, duration_ms)

            footnote? =
              Enum.any?(failures, fn %{reason: r} -> match?({:all_expansion, _}, r) end)

            socket =
              socket
              |> assign(:result_multi, res)
              |> assign(:show_all_footnote, footnote?)
              |> push_patch(
                to:
                  search_path(socket,
                    mode: :multi,
                    q: q,
                    page_size: page_size,
                    schemas: selected
                  )
              )

            {:noreply, socket}

          {:error, reason} ->
            duration_ms = System.monotonic_time(:millisecond) - start_ms
            emit_run(:multi, :error, duration_ms)
            {:noreply, assign(socket, :run_error, {:scrypath, reason})}
        end
    end
  end

  # --- Saved search helpers -------------------------------------------------------------

  defp repo(socket), do: socket.assigns.scrypath_repo

  defp store_opts(socket), do: [prefix: socket.assigns[:scrypath_ops_prefix]]

  defp search_configured?(assigns),
    do: assigns.schema_allowlist != [] and Keyword.has_key?(assigns.scrypath_opts, :backend)

  defp reload_saved_searches(socket) do
    rows =
      case repo(socket) do
        nil -> []
        repo -> repo |> SavedSearches.list(store_opts(socket)) |> Enum.map(&saved_search_row/1)
      end

    assign(socket, :saved_searches, rows)
  end

  defp saved_search_row(saved_search) do
    export = SavedSearches.export_json(saved_search)
    description = Map.get(saved_search.definition || %{}, "description")

    %{
      name: saved_search.name,
      dom_id: saved_search_dom_id(saved_search.name),
      description: if(is_binary(description), do: String.trim(description), else: ""),
      readable?: match?({:ok, _}, export),
      export_href: export_href(export),
      export_filename: export_filename(saved_search.name)
    }
  end

  defp export_href({:ok, json}),
    do: "data:application/json;charset=utf-8," <> URI.encode(json, &URI.char_unreserved?/1)

  defp export_href(_error), do: nil

  defp export_filename(name) do
    stem =
      name
      |> String.replace_suffix(".json", "")
      |> String.replace(~r/[^A-Za-z0-9._-]+/u, "-")
      |> String.trim("-")

    if stem == "", do: "saved-search.json", else: stem <> ".json"
  end

  defp saved_search_dom_id(name), do: Base.url_encode64(name, padding: false)

  defp row_action_id(:rename, name), do: "saved-search-rename-#{saved_search_dom_id(name)}"
  defp row_action_id(:delete, name), do: "saved-search-delete-#{saved_search_dom_id(name)}"
  defp row_action_id(:load, name), do: "saved-search-load-#{saved_search_dom_id(name)}"

  defp current_form(assigns) do
    %{
      mode: assigns.mode,
      schema: assigns.selected_schema,
      schemas: assigns.selected_multi_schemas,
      q: assigns.q |> text_input() |> String.trim(),
      page_size: assigns.page_size
    }
  end

  defp assign_loaded(socket, name, definition) do
    projection =
      SavedSearchForm.from_definition(
        definition,
        socket.assigns.schema_allowlist,
        socket.assigns.page_size
      )

    loaded =
      case projection do
        {:exact, form} -> %{name: name, definition: definition, form: form, exact?: true}
        {:stored, form} -> %{name: name, definition: definition, form: form, exact?: false}
        {:error, _} -> %{name: name, definition: definition, form: nil, exact?: false}
      end

    assign(socket, :loaded, loaded)
  end

  defp rename_loaded(socket, from, to) do
    case socket.assigns.loaded do
      %{name: ^from} = loaded -> assign(socket, :loaded, %{loaded | name: to})
      _other -> socket
    end
  end

  # :new (nothing loaded), :clean, :dirty (Save and Save as) or :dirty_stored (Save as only:
  # overwriting would drop options the form can't show).
  defp save_state(%{loaded: nil}), do: :new

  defp save_state(%{loaded: %{form: nil}}), do: :dirty_stored

  defp save_state(%{loaded: loaded} = assigns) do
    cond do
      SavedSearchForm.same?(current_form(assigns), loaded.form) -> :clean
      loaded.exact? -> :dirty
      true -> :dirty_stored
    end
  end

  defp load_saved_search(socket, name) do
    socket = socket |> assign(:manage_open, false) |> assign(:manage_row, nil)

    with {:ok, saved_search} <- SavedSearches.get(repo(socket), name, store_opts(socket)),
         {:ok, definition} <- V1.validate(saved_search.definition),
         {kind, form} when kind in [:exact, :stored] <-
           SavedSearchForm.from_definition(
             definition,
             socket.assigns.schema_allowlist,
             socket.assigns.page_size
           ) do
      submission = %{
        id: System.unique_integer([:positive, :monotonic]),
        mode: form.mode,
        schema: form.schema,
        schemas: form.schemas,
        query: form.q,
        page: 1,
        page_size: form.page_size,
        stored: if(kind == :stored, do: saved_search.name),
        saved: saved_search.name
      }

      socket =
        socket
        |> assign(:loaded, %{
          name: saved_search.name,
          definition: definition,
          form: form,
          exact?: kind == :exact
        })
        |> maybe_close_manage_url()

      if kind == :exact do
        {:noreply, socket} = start_search(socket, submission)
        socket
      else
        send(self(), {:run_stored, submission, definition})

        socket
        |> assign(:stored_run, %{name: saved_search.name, definition: definition})
        |> assign_running(submission)
      end
    else
      {:error, :not_found} ->
        socket
        |> reload_saved_searches()
        |> put_flash(:error, "“#{name}” no longer exists.")

      {:error, reason} ->
        put_flash(
          socket,
          :error,
          "Couldn't load “#{name}”. #{SavedSearchForm.reason_text(reason)}"
        )
    end
  end

  defp open_manage(socket) do
    socket
    |> reload_saved_searches()
    |> assign(:manage_open, true)
    |> assign(:manage_row, nil)
    |> assign(:import_error, nil)
  end

  defp close_manage(socket) do
    socket
    |> assign(:manage_open, false)
    |> assign(:manage_row, nil)
    |> maybe_close_manage_url()
  end

  defp maybe_close_manage_url(%{assigns: %{manage_from_url: true}} = socket) do
    socket
    |> assign(:manage_from_url, false)
    |> push_patch(to: search_path(socket, []), replace: true)
  end

  defp maybe_close_manage_url(socket), do: socket

  defp focus_in_sheet(socket, selector) do
    socket
    |> assign(:sheet_focus, selector)
    |> update(:sheet_focus_request, &(&1 + 1))
  end

  defp confirm_delete(socket, typed) do
    case socket.assigns.manage_row do
      %{action: :delete, name: name} when typed == name ->
        successor = delete_successor(socket.assigns.saved_searches, name)
        _ = SavedSearches.delete(repo(socket), name, store_opts(socket))

        socket =
          case socket.assigns.loaded do
            %{name: ^name} -> assign(socket, :loaded, nil)
            _other -> socket
          end

        socket
        |> assign(:manage_row, nil)
        |> reload_saved_searches()
        |> focus_in_sheet(successor)
        |> put_flash(:info, "Deleted “#{name}”.")

      %{action: :delete} = row ->
        socket
        |> assign(:manage_row, %{
          row
          | value: typed,
            error: "Type the name exactly as shown to confirm."
        })
        |> focus_in_sheet("#saved-search-delete-input")

      _other ->
        socket
    end
  end

  defp delete_successor(rows, name) do
    index = Enum.find_index(rows, &(&1.name == name))
    remaining = Enum.reject(rows, &(&1.name == name))

    case index && (Enum.at(remaining, index) || List.last(remaining)) do
      %{name: next} -> "##{row_action_id(:load, next)}"
      _none -> "#saved-search-manage-title"
    end
  end

  defp handle_import_progress(:saved_search_file, entry, socket) do
    if entry.done? do
      {bin, filename} =
        consume_uploaded_entry(socket, entry, fn %{path: path} ->
          {:ok, {File.read(path), entry.client_name}}
        end)

      name = filename |> Path.basename() |> String.replace_suffix(".json", "")

      socket =
        with {:ok, json} <- bin,
             {:ok, socket} <- import_saved_search(socket, name, json) do
          socket
        else
          {:error, message} when is_binary(message) ->
            assign(socket, :import_error, "Couldn't import #{filename}. #{message}")

          {:error, _reason} ->
            assign(
              socket,
              :import_error,
              "Couldn't import #{filename}. The file couldn't be read."
            )
        end

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  defp import_saved_search(socket, name, json) do
    allowlist = socket.assigns.schema_allowlist

    with true <- SavedSearches.valid_name?(name) || {:error, :invalid_name},
         {:ok, definition} <- SavedSearches.decode_json(json),
         :ok <- known_schemas(definition, allowlist),
         {:ok, saved} <- SavedSearches.create(repo(socket), name, definition, store_opts(socket)) do
      {:ok,
       socket
       |> assign(:import_error, nil)
       |> reload_saved_searches()
       |> focus_in_sheet("##{row_action_id(:load, saved.name)}")
       |> put_flash(:info, "Imported “#{saved.name}”.")}
    else
      {:error, :name_taken} ->
        {:error,
         "A saved search named “#{name}” already exists. Rename or delete it, then import again."}

      {:error, :invalid_name} ->
        {:error, "Give it a name of up to #{SavedSearch.max_name_length()} characters."}

      {:error, reason} ->
        {:error, SavedSearchForm.reason_text(reason)}
    end
  end

  defp known_schemas(definition, allowlist) do
    known = MapSet.new(allowlist, &inspect/1)

    case definition
         |> SavedSearchForm.target_names()
         |> Enum.reject(&MapSet.member?(known, &1)) do
      [] -> :ok
      unknown -> {:error, {:unknown_schemas, Enum.uniq(unknown)}}
    end
  end

  defp upload_error_text(:too_large), do: "It's larger than #{@max_import_bytes} bytes."
  defp upload_error_text(:not_accepted), do: "Choose a .json file."
  defp upload_error_text(:too_many_files), do: "Choose one file at a time."
  defp upload_error_text(_other), do: "The file couldn't be uploaded."

  defp save_error_text(reason, name \\ nil)

  defp save_error_text(:name_taken, name),
    do: "A saved search named “#{name}” already exists. Choose another name."

  defp save_error_text(:invalid_name, _name),
    do: "Enter a name of up to #{SavedSearch.max_name_length()} characters."

  defp save_error_text({:invalid_saved_search, reason}, _name),
    do: "Couldn't save this search. #{SavedSearchForm.reason_text(reason)}"

  defp save_error_text(%Ecto.Changeset{}, _name), do: "Couldn't save this search. Try again."

  defp save_error_text(reason, _name), do: SavedSearchForm.form_error_text(reason)

  defp build_opts(scrypath_opts, page_size, mode, page) do
    if Keyword.has_key?(scrypath_opts, :backend) do
      opts =
        scrypath_opts
        |> ScrypathOps.Schemas.runtime_opts()
        |> put_search_limit(page_size, mode, page)

      {:ok, opts}
    else
      {:error, :missing_backend}
    end
  end

  defp capture_search_submission(params, socket) do
    allowlist = socket.assigns.schema_allowlist

    schema = module_in_allowlist(params["schema"], allowlist)

    schemas = capture_multi_schemas(params, allowlist, socket)

    %{
      id: System.unique_integer([:positive, :monotonic]),
      mode: socket.assigns.mode,
      schema: schema,
      schemas: schemas,
      query: params |> Map.get("q", "") |> text_input() |> String.trim(),
      page: 1,
      page_size: parse_page_size_param(params["page_size"], socket.assigns.page_size),
      stored: nil,
      saved: nil
    }
  end

  defp capture_multi_schemas(params, allowlist, _socket) do
    raw =
      cond do
        Map.has_key?(params, "schemas") -> params["schemas"]
        Map.has_key?(params, "schemas[]") -> params["schemas[]"]
        true -> []
      end

    raw
    |> List.wrap()
    |> Enum.flat_map(fn
      value when is_binary(value) -> String.split(value, ",", trim: true)
      _value -> []
    end)
    |> Enum.map(&module_in_allowlist(&1, allowlist))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp put_search_limit(opts, page_size, :multi, page) do
    Keyword.merge(opts, federation_limit: page_size, federation_offset: (page - 1) * page_size)
  end

  defp put_search_limit(opts, page_size, _mode, page) do
    Keyword.merge(opts, page: [size: page_size, number: page])
  end

  defp parse_page_size_param(raw, fallback) do
    if is_nil(raw) do
      fallback
    else
      case Integer.parse(text_input(raw)) do
        {n, ""} -> n
        _ -> text_input(raw)
      end
    end
  end

  defp selected_schema_from_params(params, allowlist, socket) do
    case params["schema"] do
      nil ->
        socket.assigns.selected_schema || List.first(allowlist)

      raw ->
        module_in_allowlist(raw, allowlist) || socket.assigns.selected_schema ||
          List.first(allowlist)
    end
  end

  defp selected_multi_from_params(params, allowlist, socket) do
    raw =
      params
      |> Map.get("schemas", Map.get(params, "schemas[]", nil))
      |> List.wrap()
      |> Enum.flat_map(fn
        value when is_binary(value) -> String.split(value, ",", trim: true)
        _value -> []
      end)

    selected =
      raw
      |> Enum.map(&module_in_allowlist(&1, allowlist))
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()

    cond do
      selected != [] ->
        selected

      socket.assigns[:selected_multi_schemas] not in [nil, []] ->
        socket.assigns.selected_multi_schemas

      true ->
        Enum.take(allowlist, 2)
    end
  end

  defp search_path(socket, overrides) do
    mode = Keyword.get(overrides, :mode, socket.assigns.mode)
    q = Keyword.get(overrides, :q, socket.assigns.q)
    page_size = Keyword.get(overrides, :page_size, socket.assigns.page_size)
    schema = Keyword.get(overrides, :schema, socket.assigns.selected_schema)
    schemas = Keyword.get(overrides, :schemas, socket.assigns[:selected_multi_schemas] || [])

    params =
      %{"mode" => to_string(mode), "q" => q, "page_size" => page_size}
      |> maybe_put_path_schema(mode, schema, schemas)

    "#{socket.assigns.mount_path}/search?#{URI.encode_query(params)}"
  end

  defp maybe_put_path_schema(params, :single, schema, _schemas) when is_atom(schema) do
    Map.put(params, "schema", inspect(schema))
  end

  defp maybe_put_path_schema(params, :multi, _schema, schemas) do
    Map.put(params, "schemas", schemas |> Enum.map(&inspect/1) |> Enum.join(","))
  end

  defp maybe_put_path_schema(params, _mode, _schema, _schemas), do: params

  defp module_in_allowlist(bin, allowlist) when is_binary(bin) do
    mod =
      try do
        bin |> String.split(".") |> Enum.map(&String.to_existing_atom/1) |> Module.concat()
      rescue
        ArgumentError -> nil
      end

    if mod in allowlist, do: mod, else: nil
  end

  defp module_in_allowlist(_, _), do: nil

  defp search_status_badge_kind(%{searching: true}), do: :running

  defp search_status_badge_kind(%{run_error: error}) when not is_nil(error), do: :error

  defp search_status_badge_kind(%{result_multi: %{failures: [_ | _]}}), do: :warning

  defp search_status_badge_kind(%{result_single: r1, result_multi: r2})
       when not is_nil(r1) or not is_nil(r2), do: :success

  defp search_status_badge_kind(_), do: :neutral

  defp search_status_badge_label(%{searching: true}), do: "Running…"

  defp search_status_badge_label(%{run_error: error}) when not is_nil(error), do: "Failed"

  defp search_status_badge_label(%{result_multi: %{failures: [_ | _]}}), do: "Partial"

  defp search_status_badge_label(%{result_single: r1, result_multi: r2})
       when not is_nil(r1) or not is_nil(r2), do: "Last run loaded"

  defp search_status_badge_label(_), do: "Not run"

  defp search_outcome(%{searching: true}), do: "Search running."
  defp search_outcome(%{run_error: error}) when not is_nil(error), do: nil

  defp search_outcome(%{result_single: %{hits: hits}}),
    do: "#{length(hits)} #{if length(hits) == 1, do: "result", else: "results"} shown"

  defp search_outcome(%{result_multi: %{ordered: ordered}}) do
    count = Enum.reduce(ordered, 0, fn {_, result}, n -> n + length(result.hits) end)
    "#{count} #{if count == 1, do: "result", else: "results"} shown"
  end

  defp search_outcome(_), do: nil

  defp result_count(%{result_single: %{hits: hits}}), do: length(hits)

  defp result_count(%{result_multi: %{ordered: ordered}}),
    do: Enum.reduce(ordered, 0, fn {_, r}, n -> n + length(r.hits) end)

  defp result_count(_), do: 0

  defp successful_empty?(assigns),
    do:
      !assigns.searching && is_nil(assigns.run_error) && result_count(assigns) == 0 &&
        (assigns.result_single != nil || match?(%{failures: []}, assigns.result_multi))

  defp source_data(raw),
    do:
      inspect(raw,
        pretty: true,
        limit: :infinity,
        printable_limit: :infinity,
        charlists: :as_lists
      )

  defp submitted_schemas(%{mode: :single, schema: schema}),
    do: if(schema, do: [inspect(schema)], else: [])

  defp submitted_schemas(%{schemas: schemas}), do: Enum.map(schemas, &inspect/1)

  defp submitted_context(submission) do
    query = if submission.query == "", do: "all documents", else: "“#{submission.query}”"

    sources =
      submission
      |> submitted_schemas()
      |> Enum.map(&(&1 |> String.split(".") |> List.last()))
      |> Enum.join(", ")

    "Showing #{query} in #{sources} (limit #{submission.page_size}). Run search to update these results."
  end

  defp combined_hits(%{merge_hit_order: order} = result) when is_list(order),
    do: MultiSearchResult.merge_projection(result)

  defp combined_hits(result),
    do:
      Enum.flat_map(result.ordered, fn {schema, source} ->
        Enum.map(source.hits, &{schema, &1})
      end)

  defp text_input(value) when is_binary(value), do: value
  defp text_input(_value), do: ""

  defp emit_run(mode, outcome, duration_ms) do
    :telemetry.execute(
      [:scrypath_ops, :search_playground, :run],
      %{duration_ms: duration_ms},
      %{mode: mode, outcome: outcome}
    )
  end

  @impl true
  def render(assigns) do
    assigns = assign(assigns, :guide_href, "#{assigns.mount_path}/help#ranking")

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
          <.ops_page_header
            title={@page_title}
            subtitle="Run queries against your schemas. Save useful searches to run again."
          />
        </.ops_toolbar>

        <.ops_trail current={:search} />

        <div class="space-y-ops-page-gap">
          <.ops_empty_state :if={@schema_allowlist == []} title="No schemas configured">
            Add allowlisted schema modules with <code class="text-ops-body">schema_allowlist</code>
            under <code class="text-ops-body">:scrypath_ops</code>
            or <code class="text-ops-body">SCRYPATH_OPS_SCHEMAS</code>
            — see <code class="text-ops-body">scrypath_ops/README.md</code>
            — then reload this screen.
          </.ops_empty_state>

          <.ops_empty_state
            :if={@schema_allowlist != [] && !Keyword.has_key?(@scrypath_opts, :backend)}
            title="Runtime not configured"
          >
            Scrypath runtime is not configured (missing <code class="text-ops-body">:backend</code>
            and related
            options under <code class="text-ops-body">:scrypath_ops</code>). See <code class="text-ops-body">scrypath_ops/README.md</code>.
          </.ops_empty_state>

          <div class="space-y-6">
            <div class="ops-saved-search-bar" id="saved-search-bar">
              <div
                id="saved-search-picker"
                class="ops-saved-search-picker"
                phx-click-away={close_picker()}
                phx-window-keydown={close_picker()}
                phx-key="Escape"
              >
                <.ops_button
                  id="saved-search-picker-button"
                  variant={:default}
                  size={:sm}
                  class="gap-1.5"
                  aria-haspopup="true"
                  aria-expanded="false"
                  aria-controls="saved-search-menu"
                  phx-click={
                    JS.push("reload_saved_searches")
                    |> JS.toggle(to: "#saved-search-menu")
                    |> JS.toggle_attribute({"aria-expanded", "true", "false"},
                      to: "#saved-search-picker-button"
                    )
                  }
                >
                  Saved searches <.icon name="hero-chevron-down" class="size-4" />
                </.ops_button>
                <div
                  id="saved-search-menu"
                  class="ops-saved-search-menu"
                  style="display: none;"
                >
                  <p :if={@saved_searches == []} class="ops-saved-search-menu__empty">
                    No saved searches yet.
                  </p>
                  <ul :if={@saved_searches != []} aria-label="Saved searches">
                    <li :for={row <- @saved_searches}>
                      <button
                        type="button"
                        id={"saved-search-pick-#{row.dom_id}"}
                        class="ops-saved-search-menu__item"
                        aria-current={if @loaded && @loaded.name == row.name, do: "true"}
                        disabled={!search_configured?(assigns)}
                        phx-click={
                          JS.push("load_saved_search", value: %{name: row.name})
                          |> close_picker()
                        }
                      >
                        <span class="ops-saved-search-menu__name">{row.name}</span>
                        <span
                          :if={row.description != ""}
                          class="ops-saved-search-menu__description"
                        >
                          {row.description}
                        </span>
                      </button>
                    </li>
                  </ul>
                </div>
              </div>
              <p
                id="saved-search-status"
                class={["ops-saved-search-status", !@loaded && "sr-only"]}
                role="status"
              >
                {loaded_status(assigns)}
              </p>
              <button
                type="button"
                id="saved-search-manage-open"
                class="ops-text-action ops-saved-search-manage"
                phx-click="open_manage"
                data-ops-modal-trigger="manage"
              >
                Manage saved searches
              </button>
            </div>

            <.form
              for={%{}}
              as={:search}
              phx-submit="search"
              phx-change="edit_search"
              id="ops-search-playground-form"
              class="ops-form-stack ops-search-form"
              phx-hook="OpsSearchDraft"
              data-search-mode={@mode}
            >
              <fieldset
                class="ops-search-targets"
                disabled={@schema_allowlist == [] or !Keyword.has_key?(@scrypath_opts, :backend)}
              >
                <legend class="sr-only">Search targets</legend>
                <.ops_segmented_control
                  label="Search mode"
                  event="set_mode"
                  selected={to_string(@mode)}
                  disabled={@schema_allowlist == [] or !Keyword.has_key?(@scrypath_opts, :backend)}
                  items={[{"One schema", "single"}, {"Multiple schemas", "multi"}]}
                />
                <.ops_schema_select
                  :if={@schema_allowlist != []}
                  id="search_schema"
                  name={if @mode == :multi, do: "schemas[]", else: "schema"}
                  label={if @mode == :multi, do: "Schemas", else: "Schema"}
                  multiple={@mode == :multi}
                  schemas={@schema_allowlist}
                  selected={if @mode == :multi, do: @selected_multi_schemas, else: @selected_schema}
                  disabled={!Keyword.has_key?(@scrypath_opts, :backend)}
                />
                <p :if={@mode == :multi} class="ops-search-query-hint">
                  One combined result list.
                  <.ops_help_link href={@guide_href}>How ordering works</.ops_help_link>
                </p>
                <p
                  :if={
                    @mode == :multi &&
                      length(@schema_allowlist) > SearchPlayground.max_schemas_allowed()
                  }
                  class="ops-search-query-hint"
                >
                  Choose up to {SearchPlayground.max_schemas_allowed()} schemas.
                </p>
              </fieldset>

              <fieldset
                class="ops-search-query"
                disabled={@schema_allowlist == [] or !Keyword.has_key?(@scrypath_opts, :backend)}
              >
                <legend class="sr-only">Query and result limit</legend>
                <.ops_field id="search_q" label="Search text">
                  <.ops_text_input
                    id="search_q"
                    name="q"
                    value={@q}
                    placeholder="Enter a query, or leave blank to browse"
                    aria-describedby="search-honesty-panel"
                  />
                  <p id="search-honesty-panel" class="ops-search-query-hint">
                    Queries may be logged by Meilisearch. Keep secrets and personal data out of search text.
                  </p>
                </.ops_field>
                <.ops_field
                  id="search_page_size"
                  label="Results per page"
                  error={@page_size_error}
                >
                  <.ops_number_input
                    id="search_page_size"
                    name="page_size"
                    value={@page_size}
                    min="1"
                    max={SearchPlayground.max_page_size_allowed()}
                    error={@page_size_error}
                    required
                    aria-describedby="search-limit-help"
                  />
                  <p id="search-limit-help" class="ops-search-query-hint">
                    Up to {SearchPlayground.max_page_size_allowed()} per page.
                    <.ops_help_link href={"#{@mount_path}/help#limits"}>
                      About this limit
                    </.ops_help_link>
                  </p>
                </.ops_field>
              </fieldset>

              <div class="ops-search-actions">
                <.ops_button
                  type="submit"
                  variant={:primary}
                  size={:md}
                  phx-disable-with="Running…"
                  disabled={@schema_allowlist == [] or !Keyword.has_key?(@scrypath_opts, :backend)}
                >
                  Run search
                </.ops_button>
                <.ops_button
                  :if={save_state(assigns) == :new && @schema_allowlist != []}
                  id="search-save-new"
                  variant={:default}
                  size={:md}
                  phx-click="open_save_modal"
                  phx-value-kind="new"
                  data-ops-modal-trigger="save"
                >
                  Save search
                </.ops_button>
                <.ops_button
                  :if={save_state(assigns) == :dirty}
                  id="search-save-loaded"
                  variant={:default}
                  size={:md}
                  phx-click="save_loaded"
                >
                  Save
                </.ops_button>
                <.ops_button
                  :if={save_state(assigns) in [:dirty, :dirty_stored]}
                  id="search-save-as"
                  variant={:ghost}
                  size={:md}
                  phx-click="open_save_modal"
                  phx-value-kind="save_as"
                  data-ops-modal-trigger="save"
                >
                  Save as…
                </.ops_button>
              </div>
            </.form>

            <section
              :if={@submitted_search || @searching || @run_error}
              aria-labelledby="search-results-heading"
              class="min-w-0 space-y-4"
            >
              <div class="flex flex-wrap items-center justify-between gap-2">
                <h2
                  id="search-results-heading"
                  aria-label="Results"
                  class="text-ops-h2 font-semibold leading-ops-tight"
                >
                  <span :if={!search_outcome(assigns) || successful_empty?(assigns)}>Results</span>
                  <span
                    :if={search_outcome(assigns) && !successful_empty?(assigns)}
                    id="search-outcome"
                    data-testid="search-outcome"
                    role="status"
                    aria-live="polite"
                    aria-atomic="true"
                    class="ops-search-outcome"
                  >
                    {search_outcome(assigns)}
                  </span>
                </h2>
                <div class="flex flex-wrap items-center gap-3">
                  <.ops_badge
                    :if={@searching || @run_error || (@result_multi && @result_multi.failures != [])}
                    kind={search_status_badge_kind(assigns)}
                  >
                    {search_status_badge_label(assigns)}
                  </.ops_badge>
                </div>
              </div>

              <div :if={@stored_run} id="search-stored-inputs">
                <.ops_data_card title="Inputs used for these results">
                  <p class="ops-search-query-hint">
                    “{@stored_run.name}” has options the form doesn't show, so it ran exactly as saved. Run search to use the form instead.
                  </p>
                  <dl class="ops-facts mt-ops-3">
                    <div :for={{label, value} <- SavedSearchForm.summary(@stored_run.definition)}>
                      <dt>{label}</dt>
                      <dd class="whitespace-pre-wrap">{value}</dd>
                    </div>
                  </dl>
                </.ops_data_card>
              </div>

              <p
                :if={@submitted_search && !@stored_run}
                id="search-run-attribution"
                data-run-id={@submitted_search.id}
                data-mode={@submitted_search.mode}
                data-query={@submitted_search.query}
                data-limit={@submitted_search.page_size}
                data-schemas={Jason.encode!(submitted_schemas(@submitted_search))}
                hidden
                role="status"
                class="ops-draft-notice"
              >
                {submitted_context(@submitted_search)}
              </p>

              <div
                :if={@searching}
                class="space-y-3"
                aria-hidden="true"
              >
                <p class="text-ops-body text-base-content/70">
                  Running search...
                </p>
                <.ops_loading lines={4} label="Running search" />
              </div>

              <.ops_status
                :if={@run_error && !@searching}
                kind={:error}
                title="Search could not run"
                role="alert"
              >
                <p>{format_run_error(@run_error)}</p>
                <p class="mt-2 text-ops-body">
                  Fix the query options or operator config, then run search again.
                </p>
              </.ops_status>

              <.ops_empty_hero
                :if={successful_empty?(assigns)}
                role="status"
                aria-live="polite"
                title={
                  if @submitted_search.page > 1, do: "No more results", else: "No matching documents"
                }
                icon="hero-magnifying-glass"
              >
                {if @submitted_search.page > 1,
                  do: "Return to the previous page or try another query.",
                  else: "Try fewer words, check the spelling or leave the query blank to browse."}
              </.ops_empty_hero>

              <div :if={@result_single && @result_single.hits != []} class="ops-search-hits">
                <.result_hit
                  :for={{hit, idx} <- Enum.with_index(@result_single.hits, 1)}
                  hit={hit}
                  position={(@submitted_search.page - 1) * @submitted_search.page_size + idx}
                  schema={@submitted_search.schema}
                />
              </div>

              <div :if={@result_multi} class="space-y-3">
                <.ops_verdict
                  :if={@result_multi.failures != []}
                  kind={:warning}
                  headline="Some schemas could not be searched"
                >
                  Results include only the schemas that responded.
                  <ul class="mt-2 space-y-1">
                    <li :for={failure <- @result_multi.failures} data-index-outcome="failed">
                      <strong>{inspect(failure.schema)}</strong>: {inspect(failure.reason)}
                    </li>
                  </ul>
                </.ops_verdict>
                <p :if={combined_hits(@result_multi) != []} class="ops-search-query-hint">
                  {if is_list(@result_multi.merge_hit_order),
                    do: "Meilisearch's combined order.",
                    else: "Grouped by schema; combined ranking is unavailable for this response."}
                  <.ops_help_link href={@guide_href}>How ordering works</.ops_help_link>
                </p>
                <div class="ops-search-hits" id="search-combined-results">
                  <.result_hit
                    :for={{{schema, hit}, idx} <- Enum.with_index(combined_hits(@result_multi), 1)}
                    hit={hit}
                    schema={schema}
                    position={(@submitted_search.page - 1) * @submitted_search.page_size + idx}
                  />
                </div>
              </div>

              <nav
                :if={
                  @submitted_search && !@stored_run && !@searching && !@run_error &&
                    (@submitted_search.page > 1 ||
                       result_count(assigns) == @submitted_search.page_size)
                }
                aria-label="Result pages"
                class="ops-search-pagination"
              >
                <.ops_button
                  phx-click="search_page"
                  phx-value-direction="previous"
                  disabled={@submitted_search.page == 1}
                >
                  Previous
                </.ops_button>
                <span>Page {@submitted_search.page}</span>
                <.ops_button
                  phx-click="search_page"
                  phx-value-direction="next"
                  disabled={
                    result_count(assigns) < @submitted_search.page_size ||
                      (@result_multi && @result_multi.failures != [])
                  }
                >
                  Next
                </.ops_button>
              </nav>

              <.ops_disclosure
                :if={@result_single || @result_multi}
                summary="Response data"
                variant={:compact}
                class="ops-run-data"
              >
                <p class="ops-search-query-hint">
                  Complete returned data for this page, in Elixir format.
                </p>
                <.ops_code_block
                  :if={@result_single}
                  text={source_data(@result_single.raw)}
                  copy
                  copy_label="Copy response data"
                />
                <div :if={@result_multi} class="space-y-3">
                  <p class="ops-search-query-hint">
                    Per-schema data reconstructed from the combined response; not the original HTTP response. A schema with no hits on this page may still have matches.
                  </p>
                  <section :for={{schema, source} <- @result_multi.ordered}>
                    <h3 class="text-ops-body font-semibold">{inspect(schema)}</h3>
                    <.ops_code_block
                      text={source_data(source.raw)}
                      copy
                      copy_label={"Copy response data for #{inspect(schema)}"}
                    />
                  </section>
                </div>
              </.ops_disclosure>
            </section>
          </div>
        </div>
      </div>

      <.ops_modal
        :if={@name_modal}
        id="saved-search-name-modal"
        title={if @name_modal.kind == :save_as, do: "Save as", else: "Save search"}
        description="Saves the search inputs shown in the form, not the results."
        action_label="save"
        initial_focus="#saved-search-name-input"
        focus_error="#saved-search-name-input"
        focus_request={@modal_focus_request}
        cancel_event="cancel_save"
      >
        <.form
          for={%{}}
          id="saved-search-name-form"
          phx-change="name_change"
          phx-submit="save_named"
          class="space-y-3"
        >
          <.ops_field
            id="saved-search-name-input"
            label="Name"
            hint={"Names are unique. Up to #{SavedSearch.max_name_length()} characters."}
            error={@name_modal.error}
          >
            <.ops_text_input
              id="saved-search-name-input"
              name="name"
              value={@name_modal.name}
              hint={"Names are unique. Up to #{SavedSearch.max_name_length()} characters."}
              error={@name_modal.error}
              placeholder="Daily catalog check"
              autocomplete="off"
              required
            />
          </.ops_field>
          <div class="flex justify-between gap-2">
            <.ops_button phx-click="cancel_save" variant={:ghost} data-ops-modal-cancel>
              Cancel
            </.ops_button>
            <.ops_button type="submit" variant={:primary}>Save</.ops_button>
          </div>
        </.form>
      </.ops_modal>

      <.ops_sheet
        :if={@manage_open}
        id="saved-search-manage"
        title="Manage saved searches"
        cancel_event="close_manage"
        fallback_successor="#saved-search-manage-open"
        focus_target={@sheet_focus}
        focus_request={@sheet_focus_request}
      >
        <p :if={@saved_searches == []} class="ops-search-query-hint">
          No saved searches yet. Save one from Search, or import a JSON file.
        </p>
        <ul
          :if={@saved_searches != []}
          id="saved-search-list"
          class="ops-saved-search-list"
          aria-labelledby="saved-search-manage-title"
        >
          <li
            :for={row <- @saved_searches}
            id={"saved-search-row-#{row.dom_id}"}
            class={[
              "ops-saved-search-row",
              @loaded && @loaded.name == row.name && "ops-saved-search-row--loaded"
            ]}
          >
            <div class="min-w-0">
              <p class="ops-saved-search-row__name">{row.name}</p>
              <p :if={row.description != ""} class="ops-saved-search-row__description">
                {row.description}
              </p>
              <p :if={!row.readable?} class="ops-saved-search-row__description text-error">
                This saved search can't be read. Delete it, or import a corrected file.
              </p>
            </div>

            <div
              :if={is_nil(@manage_row) || @manage_row.name != row.name}
              class="ops-saved-search-row__actions"
            >
              <.ops_button
                id={"saved-search-load-#{row.dom_id}"}
                variant={:default}
                size={:sm}
                phx-click="load_saved_search"
                phx-value-name={row.name}
                aria-label={"Load #{row.name}"}
                disabled={!row.readable? || !search_configured?(assigns)}
              >
                Load
              </.ops_button>
              <.ops_button
                id={"saved-search-rename-#{row.dom_id}"}
                variant={:ghost}
                size={:sm}
                phx-click="manage_rename"
                phx-value-name={row.name}
                aria-label={"Rename #{row.name}"}
              >
                Rename
              </.ops_button>
              <a
                :if={row.export_href}
                id={"saved-search-export-#{row.dom_id}"}
                href={row.export_href}
                download={row.export_filename}
                class="btn ops-btn btn-ghost btn-sm rounded-ops-control text-ops-body font-semibold"
                aria-label={"Export #{row.name}"}
              >
                Export
              </a>
              <.ops_button
                id={"saved-search-delete-#{row.dom_id}"}
                variant={:ghost}
                size={:sm}
                class="ops-saved-search-row__delete"
                phx-click="manage_delete"
                phx-value-name={row.name}
                aria-label={"Delete #{row.name}"}
              >
                Delete
              </.ops_button>
            </div>

            <.form
              :if={@manage_row && @manage_row.name == row.name && @manage_row.action == :rename}
              for={%{}}
              id="saved-search-rename-form"
              phx-change="rename_change"
              phx-submit="rename_submit"
              class="ops-saved-search-row__form"
            >
              <.ops_field
                id="saved-search-rename-input"
                label={"Rename #{row.name}"}
                error={@manage_row.error}
              >
                <.ops_text_input
                  id="saved-search-rename-input"
                  name="new_name"
                  value={@manage_row.value}
                  error={@manage_row.error}
                  autocomplete="off"
                  required
                />
              </.ops_field>
              <div class="flex flex-wrap gap-2">
                <.ops_button type="submit" variant={:primary} size={:sm}>Rename</.ops_button>
                <.ops_button phx-click="cancel_row" variant={:ghost} size={:sm}>
                  Cancel
                </.ops_button>
              </div>
            </.form>

            <.form
              :if={@manage_row && @manage_row.name == row.name && @manage_row.action == :delete}
              for={%{}}
              id="saved-search-delete-form"
              phx-submit="confirm_delete"
              class="ops-saved-search-row__form"
            >
              <p class="text-ops-body">
                This permanently deletes “{row.name}”. It can't be undone.
              </p>
              <.ops_field
                id="saved-search-delete-input"
                label="Type the name to confirm"
                error={@manage_row.error}
              >
                <.ops_text_input
                  id="saved-search-delete-input"
                  name="confirm"
                  value={@manage_row.value}
                  error={@manage_row.error}
                  class="font-mono"
                  autocomplete="off"
                />
              </.ops_field>
              <div class="flex flex-wrap gap-2">
                <.ops_button type="submit" variant={:danger} size={:sm}>Delete</.ops_button>
                <.ops_button phx-click="cancel_row" variant={:ghost} size={:sm}>
                  Cancel
                </.ops_button>
              </div>
            </.form>
          </li>
        </ul>

        <section class="ops-saved-search-import" aria-labelledby="saved-search-import-heading">
          <h3 id="saved-search-import-heading" class="text-ops-body font-semibold">Import</h3>
          <p id="saved-search-import-hint" class="ops-search-query-hint">
            A saved-search JSON file, up to {@max_import_bytes} bytes. It's named after the file.
          </p>
          <p
            :if={@import_error}
            id="saved-search-import-error"
            role="alert"
            class="text-ops-body text-error"
          >
            {@import_error}
          </p>
          <.form
            for={%{}}
            id="saved-search-import-form"
            phx-change="validate_import"
            phx-submit="import_upload"
          >
            <.live_file_input upload={@uploads.saved_search_file} class="hidden" tabindex="-1" />
            <.ops_button
              id="saved-search-import-file"
              variant={:default}
              size={:sm}
              class="gap-1.5"
              phx-click={JS.dispatch("click", to: "##{@uploads.saved_search_file.ref}")}
              aria-describedby="saved-search-import-hint"
            >
              <.icon name="hero-arrow-up-tray" class="size-4" /> Import JSON file
            </.ops_button>
          </.form>

          <.ops_disclosure
            id="saved-search-paste"
            summary="Paste JSON instead"
            variant={:compact}
            open={@paste_json != ""}
          >
            <.form
              for={%{}}
              id="saved-search-paste-form"
              phx-submit="import_paste"
              class="space-y-3"
            >
              <.ops_field id="saved-search-paste-name" label="Name">
                <.ops_text_input
                  id="saved-search-paste-name"
                  name="name"
                  value={@paste_name}
                  autocomplete="off"
                  required
                />
              </.ops_field>
              <.ops_field id="saved-search-paste-json" label="Saved-search JSON">
                <.ops_textarea
                  id="saved-search-paste-json"
                  name="json"
                  value={@paste_json}
                  class="font-mono"
                  required
                />
              </.ops_field>
              <.ops_button type="submit" variant={:default} size={:sm}>Import</.ops_button>
            </.form>
          </.ops_disclosure>
        </section>
      </.ops_sheet>
    </Layouts.app>
    """
  end

  defp loaded_status(%{loaded: %{name: name}} = assigns) do
    edited = if save_state(assigns) in [:dirty, :dirty_stored], do: " · edited", else: ""
    "Loaded “#{name}”#{edited}"
  end

  defp loaded_status(_assigns), do: ""

  defp close_picker(js \\ %JS{}) do
    js
    |> JS.hide(to: "#saved-search-menu")
    |> JS.set_attribute({"aria-expanded", "false"}, to: "#saved-search-picker-button")
  end

  defp format_run_error({:page_size_out_of_range, n, max}) do
    "Result limit #{n} must be between 1 and #{max}."
  end

  defp format_run_error({:too_many_schemas, count, max}) do
    "too many schemas selected (#{count}); maximum is #{max} (too_many_schemas)."
  end

  defp format_run_error({:config, :missing_backend}) do
    "Scrypath backend options are not configured under :scrypath_ops."
  end

  defp format_run_error({:config, :empty_allowlist}) do
    "Schema allowlist is empty — configure schema_allowlist first."
  end

  defp format_run_error({:config, :no_schema}) do
    "No schema selected."
  end

  defp format_run_error({:config, :no_schemas_selected}) do
    "Select at least one schema for multi-search."
  end

  defp format_run_error({:scrypath, reason}) do
    inspect(reason)
  end

  defp format_run_error(other), do: inspect(other)
end
