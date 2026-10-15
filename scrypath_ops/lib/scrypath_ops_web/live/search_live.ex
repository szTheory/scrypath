defmodule ScrypathOpsWeb.SearchLive do
  @moduledoc """
  Bounded `/ops/search` playground: single- and multi-index queries with
  federation-honest disclosure. All `Scrypath` calls go through
  `ScrypathOps.SearchPlayground.dispatch_*`.
  """

  use ScrypathOpsWeb, :live_view
  import ScrypathOpsWeb.ResultUi

  alias Scrypath.MultiSearchResult
  alias ScrypathOps.Playbook.Store
  alias ScrypathOps.Playbook.V1
  alias ScrypathOps.Schemas
  alias ScrypathOps.SearchPlayground

  attr(:result, :any, required: true)
  attr(:guide_href, :string, required: true)

  def empty_or_hits_single(assigns) do
    ~H"""
    <%= if @result.hits == [] do %>
      <.ops_empty_state title="No matching documents">
        Try different search text or another schema.
        <a class="ops-text-action" href={@guide_href}>Search help</a>
      </.ops_empty_state>
    <% else %>
      <div class="grid gap-2">
        <%= for {hit, idx} <- Enum.with_index(@result.hits, 1) do %>
          <.result_hit hit={hit} position={idx} />
        <% end %>
      </div>
    <% end %>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    allowlist = Schemas.allowlist()
    scrypath_opts = Schemas.scrypath_opts()

    socket =
      socket
      |> assign(:page_title, "Search")
      |> assign(:mode, :single)
      |> assign(:q, "")
      |> assign(:page_size, SearchPlayground.default_page_size())
      |> assign(:schema_allowlist, allowlist)
      |> assign(:scrypath_opts, scrypath_opts)
      |> assign(:selected_schema, List.first(allowlist))
      |> assign(:selected_multi_schemas, Enum.take(allowlist, 2))
      |> assign(:result_single, nil)
      |> assign(:result_multi, nil)
      |> assign(:run_error, nil)
      |> assign(:submitted_search, nil)
      |> assign(:saved_basename, nil)
      |> assign(:searching, false)
      |> assign(:show_all_footnote, false)
      |> assign_capture_defaults()

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    prev_mode = socket.assigns.mode
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
      end

    socket =
      if prev_mode != socket.assigns.mode do
        assign_capture_defaults(socket)
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("edit_search", params, socket) do
    draft = capture_search_submission(params, socket)

    socket =
      socket
      |> assign(:q, text_input(params["q"] || ""))
      |> assign(:page_size, draft.page_size)

    # Editing controls does not execute a query or replace its result/capture source.
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
      |> assign_capture_defaults()
      |> push_patch(to: search_path(socket, mode: :multi))

    {:noreply, socket}
  end

  def handle_event("set_mode", _, socket) do
    socket =
      socket
      |> assign(:mode, :single)
      |> assign_capture_defaults()
      |> push_patch(to: search_path(socket, mode: :single))

    {:noreply, socket}
  end

  def handle_event("capture_change", %{"capture" => fields}, socket) when is_map(fields) do
    title = fields |> Map.get("title", "") |> text_input()
    description = fields |> Map.get("description", "") |> text_input()
    basename = fields |> Map.get("basename", "") |> text_input()

    socket =
      socket
      |> assign(:capture_title, title)
      |> assign(:capture_description, description)
      |> assign(:capture_basename, basename)
      |> assign(:capture_error, nil)
      |> recompute_capture_preview()

    {:noreply, socket}
  end

  def handle_event("capture_change", _, socket), do: {:noreply, socket}

  def handle_event("save_search_capture", %{"capture" => cap}, socket) when is_map(cap) do
    root = Application.get_env(:scrypath_ops, :playbook_workspace_dir)
    basename = cap |> Map.get("basename", "") |> text_input() |> String.trim()
    title = cap |> Map.get("title", "") |> text_input()
    description = cap |> Map.get("description", "") |> text_input()

    socket =
      socket
      |> assign(:capture_title, title)
      |> assign(:capture_description, description)
      |> assign(:capture_basename, basename)
      |> assign(:capture_error, nil)
      |> recompute_capture_preview()

    cond do
      root in [nil, ""] ->
        {:noreply,
         put_capture_error(
           socket,
           "Could not save this search.",
           recovery: "Configure a storage folder, then retry saving."
         )}

      socket.assigns.capture_base == nil ->
        {:noreply, put_capture_error(socket, "Run a search first — nothing to save yet.")}

      not Store.safe_basename?(basename) ->
        {:noreply,
         put_capture_error(
           socket,
           "Filename must be a .json basename using letters, digits, periods, hyphens or underscores."
         )}

      true ->
        draft =
          socket.assigns.capture_base
          |> merge_capture_metadata(title, description)

        case V1.validate(draft) do
          {:ok, validated} ->
            case V1.encode(validated) do
              {:ok, json} ->
                case Store.create_workspace_file(root, basename, json <> "\n") do
                  :ok ->
                    {:noreply,
                     socket
                     |> assign(:capture_basename, "")
                     |> assign(:saved_basename, basename)
                     |> assign(:capture_error, nil)
                     |> put_flash(:info, "Saved search #{basename}.")}

                  {:error, :target_exists} ->
                    {:noreply,
                     put_capture_error(
                       socket,
                       "That filename is already in use. Choose another."
                     )}

                  {:error, reason} ->
                    {:noreply,
                     put_capture_error(
                       socket,
                       "Could not save this search.",
                       detail: safe_capture_reason(reason),
                       recovery:
                         "Check the storage folder's permissions and available disk space, then retry saving."
                     )}
                end

              {:error, reason} ->
                {:noreply,
                 put_capture_error(
                   socket,
                   "Could not save this search.",
                   detail: "Saved search encoding failed: #{inspect(reason)}",
                   recovery:
                     "Review the search criteria and optional metadata, then retry saving."
                 )}
            end

          {:error, reason} ->
            {:noreply,
             put_capture_error(
               socket,
               "Could not save this search.",
               detail: "Saved search validation failed: #{inspect(reason)}",
               recovery: "Review the search criteria and optional metadata, then retry saving."
             )}
        end
    end
  end

  def handle_event("save_search_capture", _, socket) do
    {:noreply, put_capture_error(socket, "Enter a filename ending in .json, then retry saving.")}
  end

  def handle_event("search", params, socket) when is_map(params) do
    # Two-step so the loading skeleton paints before the bounded read runs (S2). The
    # Scrypath search dispatch is synchronous; deferring it to handle_info/2 lets LiveView
    # push the `:searching` frame first. Clear prior results immediately so the skeleton
    # isn't drawn over a stale result panel.
    submission = capture_search_submission(params, socket)
    send(self(), {:run_search, submission})

    socket =
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
      |> assign_capture_defaults()

    {:noreply, socket}
  end

  def handle_event("search", _params, socket) do
    {:noreply, put_flash(socket, :error, "Search input was invalid. Check the fields and retry.")}
  end

  @impl true
  def handle_info({:run_search, submission}, socket) do
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
      |> assign_capture_defaults()

    with :ok <- SearchPlayground.validate_page_size(page_size),
         {:ok, opts} <- build_opts(scrypath_opts, page_size, mode) do
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
              |> assign_search_capture_single(mod, q, opts)
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
              |> assign_search_capture_multi(selected, q, opts)
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

  defp build_opts(scrypath_opts, page_size, mode) do
    if Keyword.has_key?(scrypath_opts, :backend) do
      opts =
        scrypath_opts
        |> ScrypathOps.Schemas.runtime_opts()
        |> put_search_limit(page_size, mode)

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
      page_size: parse_page_size_param(params["page_size"], socket.assigns.page_size)
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

  defp put_search_limit(opts, page_size, :multi) do
    Keyword.merge(opts, federation_limit: page_size, federation_offset: 0)
  end

  defp put_search_limit(opts, page_size, _mode) do
    Keyword.merge(opts, page: [size: page_size])
  end

  defp parse_page_size_param(raw, fallback) do
    case Integer.parse(text_input(raw || "")) do
      {n, _} -> n
      :error -> fallback
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

  defp schema_options(allowlist) do
    Enum.map(allowlist, &{inspect(&1), inspect(&1)})
  end

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

  defp search_outcome(%{result_single: %{hits: hits}, submitted_search: submission})
       when not is_nil(submission) do
    if hits == [] do
      "Search completed: no matching documents (0 hits) in #{inspect(submission.schema)}."
    else
      "Search completed: #{length(hits)} #{pluralize(length(hits), "hit")} from #{inspect(submission.schema)}."
    end
  end

  defp search_outcome(%{result_multi: %{ordered: ordered, failures: failures}})
       when is_list(ordered) and is_list(failures) do
    hit_count =
      Enum.reduce(ordered, 0, fn {_schema, result}, count -> count + length(result.hits) end)

    no_hit_count = Enum.count(ordered, fn {_schema, result} -> result.hits == [] end)
    returned_count = length(ordered)

    if failures == [] do
      "Search completed: #{hit_count} #{pluralize(hit_count, "hit")} across #{returned_count} #{pluralize(returned_count, "index")}; #{no_hit_count} #{pluralize(no_hit_count, "index")} returned no matches."
    else
      "Partial search: #{hit_count} #{pluralize(hit_count, "hit")} from #{returned_count} #{pluralize(returned_count, "index")}; #{no_hit_count} #{pluralize(no_hit_count, "index")} returned no matches and #{length(failures)} #{pluralize(length(failures), "index")} failed."
    end
  end

  defp search_outcome(_), do: nil

  defp pluralize(1, "hit"), do: "hit"
  defp pluralize(1, "index"), do: "index"
  defp pluralize(_count, "hit"), do: "hits"
  defp pluralize(_count, "index"), do: "indexes"
  defp pluralize(_count, _singular), do: "s"

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

    "Showing #{query} in #{sources} (limit #{submission.page_size}). Run search to apply your changes."
  end

  defp combined_order_rows(result) do
    hits =
      Enum.reduce(result.by_schema, %{}, fn {schema, source}, acc ->
        id_field = schema |> Scrypath.Schema.Metadata.document_id() |> Atom.to_string()

        Enum.reduce(source.hits, acc, fn hit, acc ->
          id = Map.get(hit, "id") || Map.get(hit, id_field)

          title =
            Enum.find_value(~w(name title sku), fn key ->
              case Map.get(hit, key) do
                value when is_binary(value) and value != "" -> value
                _ -> nil
              end
            end)

          if is_nil(id), do: acc, else: Map.put(acc, {schema, to_string(id)}, title)
        end)
      end)

    Enum.map(result.merge_hit_order, fn {schema, id} ->
      {schema, id, Map.get(hits, {schema, to_string(id)}) || "Document #{id}"}
    end)
  end

  defp text_input(value) when is_binary(value), do: value
  defp text_input(_value), do: ""

  defp emit_run(mode, outcome, duration_ms) do
    :telemetry.execute(
      [:scrypath_ops, :search_playground, :run],
      %{duration_ms: duration_ms},
      %{mode: mode, outcome: outcome}
    )
  end

  defp assign_capture_defaults(socket) do
    socket
    |> assign(:capture_base, nil)
    |> assign(:capture_title, "")
    |> assign(:capture_description, "")
    |> assign(:capture_basename, "")
    |> assign(:capture_error, nil)
    |> assign(:capture_preview_json, nil)
    |> assign(:capture_preview_ok?, false)
  end

  defp put_capture_error(socket, message, opts \\ []) do
    error = %{
      message: message,
      detail: Keyword.get(opts, :detail),
      recovery: Keyword.get(opts, :recovery)
    }

    assign(socket, :capture_error, error)
  end

  defp safe_capture_reason(reason) when is_atom(reason), do: inspect(reason)

  defp safe_capture_reason({category, reason}) when is_atom(category) and is_atom(reason),
    do: inspect({category, reason})

  defp safe_capture_reason(_), do: "unknown filesystem error"

  defp assign_search_capture_single(socket, mod, q, opts_kw) do
    base = %{
      "playbook_format" => 1,
      "mode" => "search",
      "schema" => inspect(mod),
      "q" => q,
      "opts" => keyword_to_playbook_opts_map(opts_kw, :search)
    }

    socket
    |> assign(:capture_base, base)
    |> recompute_capture_preview()
  end

  defp assign_search_capture_multi(socket, selected_mods, q, opts_kw) do
    entries = Enum.map(selected_mods, fn mod -> [inspect(mod), q, %{}] end)

    base = %{
      "playbook_format" => 1,
      "mode" => "search_many",
      "entries" => entries,
      "opts" => keyword_to_playbook_opts_map(opts_kw, :search_many_shared)
    }

    socket
    |> assign(:capture_base, base)
    |> recompute_capture_preview()
  end

  defp merge_capture_metadata(base, title, description) do
    base
    |> maybe_put_trimmed_string("title", title)
    |> maybe_put_trimmed_string("description", description)
  end

  defp maybe_put_trimmed_string(map, key, raw) do
    v = raw |> to_string() |> String.trim()
    if v == "", do: map, else: Map.put(map, key, v)
  end

  defp recompute_capture_preview(socket) do
    case socket.assigns.capture_base do
      nil ->
        assign(socket, capture_preview_json: nil, capture_preview_ok?: false)

      base ->
        draft =
          merge_capture_metadata(
            base,
            socket.assigns.capture_title,
            socket.assigns.capture_description
          )

        case V1.validate(draft) do
          {:ok, validated} ->
            preview = Jason.encode!(validated, pretty: true)

            assign(socket,
              capture_preview_json: preview,
              capture_preview_ok?: true
            )

          {:error, _} ->
            assign(socket, capture_preview_json: nil, capture_preview_ok?: false)
        end
    end
  end

  defp keyword_to_playbook_opts_map(kw, ctx) do
    strings =
      case ctx do
        :search ->
          ~w(facets facet_filter filter sort page per_query)

        :search_many_shared ->
          ~w(facets facet_filter filter sort page per_query federation_limit federation_offset federation_timeout hydration_timeout max_schemas global_schemas otp_app)
      end

    Enum.reduce(strings, %{}, fn str, acc ->
      case opt_field_atom(str) do
        nil ->
          acc

        atom ->
          case Keyword.get(kw, atom) do
            nil ->
              acc

            v ->
              case dispatch_opt_to_json(str, v) do
                :drop -> acc
                encoded -> Map.put(acc, str, encoded)
              end
          end
      end
    end)
  end

  defp opt_field_atom("facets"), do: :facets
  defp opt_field_atom("facet_filter"), do: :facet_filter
  defp opt_field_atom("filter"), do: :filter
  defp opt_field_atom("sort"), do: :sort
  defp opt_field_atom("page"), do: :page
  defp opt_field_atom("per_query"), do: :per_query
  defp opt_field_atom("federation_limit"), do: :federation_limit
  defp opt_field_atom("federation_offset"), do: :federation_offset
  defp opt_field_atom("federation_timeout"), do: :federation_timeout
  defp opt_field_atom("hydration_timeout"), do: :hydration_timeout
  defp opt_field_atom("max_schemas"), do: :max_schemas
  defp opt_field_atom("global_schemas"), do: :global_schemas
  defp opt_field_atom("otp_app"), do: :otp_app
  defp opt_field_atom(_), do: nil

  defp dispatch_opt_to_json("page", v) when is_list(v) do
    m =
      %{}
      |> maybe_put_json_int("size", Keyword.get(v, :size))
      |> maybe_put_json_int("number", Keyword.get(v, :number))

    if m == %{}, do: :drop, else: m
  end

  defp dispatch_opt_to_json("page", _), do: :drop

  defp dispatch_opt_to_json("per_query", v) when is_list(v) do
    m =
      %{}
      |> maybe_put_json_number(
        "ranking_score_threshold",
        Keyword.get(v, :ranking_score_threshold)
      )
      |> maybe_put_json_bool("show_ranking_score", Keyword.get(v, :show_ranking_score))
      |> maybe_put_json_bool(
        "show_ranking_score_details",
        Keyword.get(v, :show_ranking_score_details)
      )

    if m == %{}, do: :drop, else: m
  end

  defp dispatch_opt_to_json("per_query", _), do: :drop

  defp dispatch_opt_to_json("global_schemas", list) when is_list(list), do: list
  defp dispatch_opt_to_json("global_schemas", _), do: :drop

  defp dispatch_opt_to_json(j, n)
       when j in ~w(federation_limit federation_offset federation_timeout hydration_timeout max_schemas) and
              is_integer(n),
       do: n

  defp dispatch_opt_to_json("otp_app", s) when is_binary(s) and s != "", do: s

  defp dispatch_opt_to_json(_, v), do: v

  defp maybe_put_json_int(m, _k, nil), do: m
  defp maybe_put_json_int(m, k, n) when is_integer(n), do: Map.put(m, k, n)
  defp maybe_put_json_int(m, _, _), do: m

  defp maybe_put_json_number(m, _k, nil), do: m
  defp maybe_put_json_number(m, k, n) when is_number(n) and n >= 0, do: Map.put(m, k, n)
  defp maybe_put_json_number(m, _, _), do: m

  defp maybe_put_json_bool(m, _k, nil), do: m
  defp maybe_put_json_bool(m, k, b) when is_boolean(b), do: Map.put(m, k, b)
  defp maybe_put_json_bool(m, _, _), do: m

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
                <p :if={@mode == :multi} class="text-ops-sm text-base-content/70">
                  Results are grouped by schema.
                  <a class="ops-text-action" href={@guide_href}>How ordering works</a>
                </p>

                <.ops_schema_select
                  :if={@mode == :single && @schema_allowlist != []}
                  id="search_schema"
                  name="schema"
                  label="Schema"
                  schemas={@schema_allowlist}
                  selected={@selected_schema}
                  disabled={!Keyword.has_key?(@scrypath_opts, :backend)}
                />

                <div :if={@mode == :multi} class="space-y-2">
                  <p id="search-schemas-hint" class="text-ops-body leading-5 text-base-content/70">
                    Choose up to {SearchPlayground.max_schemas_allowed()} schemas.
                  </p>
                  <.ops_checkbox_list
                    name="schemas[]"
                    options={schema_options(@schema_allowlist)}
                    selected={Enum.map(@selected_multi_schemas, &inspect/1)}
                  />
                </div>
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
                  label="Result limit"
                  hint={"1–#{SearchPlayground.max_page_size_allowed()} results per search"}
                >
                  <.ops_number_input
                    id="search_page_size"
                    name="page_size"
                    value={@page_size}
                    min="1"
                    max={SearchPlayground.max_page_size_allowed()}
                    aria-describedby="search_page_size-hint"
                  />
                </.ops_field>
              </fieldset>

              <.ops_button
                type="submit"
                variant={:primary}
                size={:md}
                phx-disable-with="Running…"
                disabled={@schema_allowlist == [] or !Keyword.has_key?(@scrypath_opts, :backend)}
              >
                Run search
              </.ops_button>
            </.form>

            <section
              :if={@submitted_search || @searching || @run_error}
              aria-labelledby="search-results-heading"
              class="min-w-0 space-y-4"
            >
              <div class="flex flex-wrap items-center justify-between gap-2">
                <h2
                  id="search-results-heading"
                  class="text-ops-h2 font-semibold leading-ops-tight"
                >
                  Results
                </h2>
                <div class="flex flex-wrap items-center gap-3">
                  <.ops_badge
                    :if={@searching || @run_error || (@result_multi && @result_multi.failures != [])}
                    kind={search_status_badge_kind(assigns)}
                  >
                    {search_status_badge_label(assigns)}
                  </.ops_badge>
                  <.link
                    :if={@saved_basename}
                    navigate={"#{@mount_path}/playbooks"}
                    class="ops-text-action"
                    data-testid="search-saved-handoff"
                  >
                    Open Saved searches <span aria-hidden="true">→</span>
                  </.link>
                  <.ops_button
                    :if={@capture_base != nil}
                    id="search-save-toggle"
                    variant={:default}
                    size={:sm}
                    phx-click={
                      JS.toggle(to: "#search-capture-form-panel")
                      |> JS.toggle_attribute({"aria-expanded", "true", "false"},
                        to: "#search-save-toggle"
                      )
                      |> JS.focus(to: "#capture_title")
                    }
                    aria-controls="search-capture-form-panel"
                    aria-expanded="false"
                  >
                    Save search
                  </.ops_button>
                </div>
              </div>
              <section
                :if={@capture_base != nil}
                aria-labelledby="search-capture-heading"
                class="space-y-3"
              >
                <h2 id="search-capture-heading" class="sr-only">
                  Save search
                </h2>
                <div class="ops-save-playbook">
                  <div id="search-capture-form-panel" style="display: none;">
                    <p class="mt-3 max-w-2xl text-ops-body text-base-content/70">
                      Save the last-run query and options to Saved searches on this server. Results are not stored.
                    </p>

                    <.form
                      for={%{}}
                      as={:capture}
                      phx-change="capture_change"
                      phx-submit="save_search_capture"
                      class="ops-save-playbook__form mt-4 max-w-2xl space-y-4"
                      id="search-capture-form"
                    >
                      <div class="grid gap-3 md:grid-cols-2">
                        <.ops_field id="capture_title" label="Search title">
                          <.ops_text_input
                            id="capture_title"
                            name="capture[title]"
                            value={@capture_title}
                            placeholder="Optional"
                          />
                        </.ops_field>
                        <.ops_field
                          id="capture_basename"
                          label="Filename"
                          hint="Choose a new .json filename. Existing files are kept."
                        >
                          <.ops_text_input
                            id="capture_basename"
                            name="capture[basename]"
                            hint="Choose a new .json filename. Existing files are kept."
                            value={@capture_basename}
                            error={@capture_error && @capture_error.message}
                            class="min-w-0 font-mono text-ops-body"
                            placeholder="my-search.json"
                            required
                          />
                        </.ops_field>
                      </div>
                      <.ops_field id="capture_description" label="Description">
                        <.ops_textarea
                          id="capture_description"
                          name="capture[description]"
                          value={@capture_description}
                          placeholder="Optional"
                        />
                      </.ops_field>

                      <div
                        :if={@capture_error}
                        class="min-w-0 space-y-1 text-ops-body leading-6 text-error"
                        data-testid="search-capture-error"
                        role="alert"
                      >
                        <p id="capture_basename-error" class="break-words">
                          {@capture_error.message}
                        </p>
                        <p :if={@capture_error.detail} class="break-words text-base-content/75">
                          Reason: {@capture_error.detail}
                        </p>
                        <p
                          :if={@capture_error.recovery}
                          class="break-words text-base-content/75"
                        >
                          {@capture_error.recovery}
                        </p>
                      </div>

                      <.ops_disclosure
                        :if={@capture_preview_json}
                        id="search-capture-json"
                        summary="Saved search JSON"
                        variant={:compact}
                      >
                        <.ops_code_block
                          data-testid="search-capture-preview-pre"
                          text={@capture_preview_json}
                          copy
                          copy_label="Copy saved search JSON"
                        />
                      </.ops_disclosure>

                      <.ops_button type="submit" variant={:primary}>
                        Save search
                      </.ops_button>
                    </.form>
                  </div>
                </div>
              </section>

              <p
                :if={search_outcome(assigns)}
                id="search-outcome"
                data-testid="search-outcome"
                role="status"
                aria-live="polite"
                aria-atomic="true"
                class="text-ops-body text-base-content/80"
              >
                {search_outcome(assigns)}
              </p>

              <p
                :if={@submitted_search}
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

              <div :if={@result_single} class="space-y-3">
                <.empty_or_hits_single result={@result_single} guide_href={@guide_href} />
              </div>

              <div :if={@result_multi} class="space-y-3">
                <div id="search-federation-status" class="text-ops-body space-y-2">
                  <div
                    :if={@result_multi.failures != []}
                    id="search-partial-live"
                    class="rounded-ops-control border p-4 ops-tone-warning"
                  >
                    <p class="font-semibold">Some schemas could not be searched.</p>
                    <p class="mt-1 text-ops-body">
                      Results below include the schemas that responded. Review the affected schemas in Failure details before running again.
                    </p>
                    <p class="mt-2 text-ops-body text-base-content/70">
                      <code class="text-ops-body">:all</code>
                      entries expanded follow declaration order before limits apply when multi-search uses global expansion.
                    </p>
                    <.ops_disclosure
                      summary={"Failure details (#{length(@result_multi.failures)})"}
                      variant={:compact}
                      class="mt-2"
                    >
                      <ul class="list-inside list-disc font-mono text-ops-body">
                        <%= for %{schema: s, reason: r} <- @result_multi.failures do %>
                          <li>{inspect(s)} — {inspect(r)}</li>
                        <% end %>
                      </ul>
                      <p :if={@show_all_footnote} class="mt-2 text-ops-body text-base-content/80">
                        <code class="text-ops-body">:all</code>
                        entries expanded to the configured global schema list in declaration order before limits apply; empty registry and missing
                        <code class="text-ops-body">otp_app</code>
                        errors match library invalid_options / all_expansion vocabulary.
                      </p>
                    </.ops_disclosure>
                  </div>
                </div>

                <details
                  :if={@result_multi.merge_hit_order && @result_multi.merge_hit_order != []}
                  class="ops-value-details ops-combined-order"
                >
                  <summary>Combined result order ({length(@result_multi.merge_hit_order)})</summary>
                  <p class="ops-search-query-hint">
                    The order returned by Meilisearch across the selected schemas.
                    <a href={@guide_href}>How ordering works</a>
                  </p>
                  <ol>
                    <li :for={{schema, id, title} <- combined_order_rows(@result_multi)}>
                      <strong>{title}</strong>
                      <span>{schema |> Module.split() |> List.last()}</span>
                      <code>{id}</code>
                    </li>
                  </ol>
                </details>

                <section id="search-index-results" aria-label="Per-index results" class="space-y-3">
                  <article
                    :for={{mod, sres} <- @result_multi.ordered}
                    class="min-w-0 rounded-ops-control border border-base-content/10 p-4"
                    data-index-outcome={if sres.hits == [], do: "no-hits", else: "returned"}
                  >
                    <h3 class="break-all font-mono text-ops-body font-semibold">{inspect(mod)}</h3>
                    <p class="mt-1 text-ops-body text-base-content/80">
                      <%= if sres.hits == [] do %>
                        No matching documents returned for this index.
                      <% else %>
                        {length(sres.hits)} {pluralize(length(sres.hits), "hit")} returned.
                      <% end %>
                    </p>
                    <div :if={sres.hits != []} class="mt-3 grid min-w-0">
                      <%= for {hit, idx} <- Enum.with_index(sres.hits, 1) do %>
                        <.result_hit hit={hit} position={idx} schema={mod} />
                      <% end %>
                    </div>
                    <.ops_disclosure
                      summary={"Raw response for #{inspect(mod)}"}
                      variant={:compact}
                      class="mt-2"
                    >
                      <.ops_code_block variant={:compact} text={inspect(sres.raw, pretty: true)} />
                    </.ops_disclosure>
                  </article>

                  <article
                    :for={failure <- @result_multi.failures}
                    class="min-w-0 rounded-ops-control border border-base-content/10 p-4"
                    data-index-outcome="failed"
                  >
                    <h3 class="break-all font-mono text-ops-body font-semibold">
                      Index failed: {inspect(failure.schema)}
                    </h3>
                    <p class="mt-1 break-words text-ops-body text-base-content/80">
                      Reason: <code>{inspect(failure.reason)}</code>. Check this index and its backend configuration, then run search again.
                    </p>
                    <.ops_disclosure summary="Raw failure detail" variant={:compact} class="mt-2">
                      <.ops_code_block variant={:compact} text={inspect(failure, pretty: true)} />
                    </.ops_disclosure>
                  </article>
                </section>
              </div>
            </section>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
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
