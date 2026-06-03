defmodule ScrypathOpsWeb.SearchLive do
  @moduledoc """
  Bounded `/ops/search` playground: single- and multi-index queries with
  federation-honest disclosure. All `Scrypath` calls go through
  `ScrypathOps.SearchPlayground.dispatch_*`.
  """

  use ScrypathOpsWeb, :live_view

  alias Scrypath.MultiSearchResult
  alias ScrypathOps.Playbook.Store
  alias ScrypathOps.Playbook.V1
  alias ScrypathOps.Schemas
  alias ScrypathOps.SearchPlayground

  @guide_href "https://github.com/szTheory/scrypath/blob/main/guides/multi-index-search.md"

  attr(:result, :any, required: true)
  attr(:guide_href, :string, required: true)

  def empty_or_hits_single(assigns) do
    ~H"""
    <%= if @result.hits == [] do %>
      <.ops_data_card title="No hits for this query.">
        <p class="text-ops-body text-base-content/80">
          Widen filters or try another sample; see the honesty panel for merge ceilings and backend limits.
          (<a class="link link-primary" href={@guide_href}>guides/multi-index-search.md</a>).
        </p>
      </.ops_data_card>
    <% else %>
      <div class="grid gap-2">
        <%= for {hit, idx} <- Enum.with_index(@result.hits, 1) do %>
          <.ops_result_row title={"Hit #{idx}"} subtitle={hit_summary(hit)}>
            <.ops_disclosure summary="Raw hit payload" variant={:compact}>
              <.ops_code_block variant={:compact}>{inspect(hit, pretty: true)}</.ops_code_block>
            </.ops_disclosure>
          </.ops_result_row>
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
      |> assign(:guide_href, @guide_href)
      |> assign(:page_title, "Search & federation")
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

  def handle_event("capture_change", %{"capture" => fields}, socket) do
    title = fields |> Map.get("title", "") |> to_string()
    description = fields |> Map.get("description", "") |> to_string()
    basename = fields |> Map.get("basename", "") |> to_string()

    socket =
      socket
      |> assign(:capture_title, title)
      |> assign(:capture_description, description)
      |> assign(:capture_basename, basename)
      |> recompute_capture_preview()

    {:noreply, socket}
  end

  def handle_event("capture_change", _, socket), do: {:noreply, socket}

  def handle_event("save_search_capture", %{"capture" => cap}, socket) do
    root = Application.get_env(:scrypath_ops, :playbook_workspace_dir)
    basename = cap |> Map.get("basename", "") |> to_string() |> String.trim()
    title = cap |> Map.get("title", "") |> to_string()
    description = cap |> Map.get("description", "") |> to_string()

    cond do
      root in [nil, ""] ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "Playbook workspace is not configured — set SCRYPATH_OPS_PLAYBOOK_DIR, reload, then save again."
         )}

      socket.assigns.capture_base == nil ->
        {:noreply, put_flash(socket, :error, "Run a search first — nothing to save yet.")}

      not Store.safe_basename?(basename) ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "Filename must match *.json basename rules (letters, digits, ., -, _)."
         )}

      true ->
        draft =
          socket.assigns.capture_base
          |> merge_capture_metadata(title, description)

        case V1.validate(draft) do
          {:ok, validated} ->
            case V1.encode(validated) do
              {:ok, json} ->
                if workspace_playbook_exists?(root, basename) do
                  {:noreply,
                   put_flash(
                     socket,
                     :error,
                     "That playbook name is already in use — pick another basename."
                   )}
                else
                  case Store.save_workspace_file(root, basename, json <> "\n") do
                    :ok ->
                      {:noreply,
                       socket
                       |> assign(:capture_basename, "")
                       |> put_flash(:info, "Saved playbook #{basename}.")}

                    {:error, _} ->
                      {:noreply,
                       put_flash(socket, :error, "Save failed — check directory permissions.")}
                  end
                end

              {:error, _} ->
                {:noreply, put_flash(socket, :error, "Could not encode playbook for saving.")}
            end

          {:error, _} ->
            {:noreply,
             put_flash(
               socket,
               :error,
               "Playbook preview is not valid — adjust fields and try again."
             )}
        end
    end
  end

  def handle_event("save_search_capture", _, socket) do
    {:noreply, put_flash(socket, :error, "Missing save fields.")}
  end

  def handle_event("search", params, socket) do
    start_ms = System.monotonic_time(:millisecond)

    q = params["q"] |> to_string() |> String.trim()
    page_size = parse_page_size_param(params["page_size"], socket.assigns.page_size)

    allowlist = socket.assigns.schema_allowlist
    scrypath_opts = socket.assigns.scrypath_opts
    mode = socket.assigns.mode

    base_socket =
      socket
      |> assign(:q, q)
      |> assign(:page_size, page_size)
      |> assign(:result_single, nil)
      |> assign(:result_multi, nil)
      |> assign(:run_error, nil)
      |> assign(:show_all_footnote, false)
      |> assign_capture_defaults()

    with :ok <- SearchPlayground.validate_page_size(page_size),
         {:ok, opts} <- build_opts(scrypath_opts, page_size, mode) do
      case mode do
        :single ->
          run_single(base_socket, params, q, opts, allowlist, start_ms)

        :multi ->
          run_multi(base_socket, params, q, opts, allowlist, start_ms)
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

  defp run_single(socket, params, q, opts, allowlist, start_ms) do
    mod =
      case params["schema"] do
        nil -> socket.assigns.selected_schema
        s -> module_in_allowlist(s, allowlist) || socket.assigns.selected_schema
      end

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
                    page_size: socket.assigns.page_size,
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

  defp run_multi(socket, params, q, opts, allowlist, start_ms) do
    selected =
      params
      |> Map.get("schemas", Map.get(params, "schemas[]", []))
      |> List.wrap()
      |> Enum.map(&module_in_allowlist(&1, allowlist))
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()

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
                    page_size: socket.assigns.page_size,
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

  defp put_search_limit(opts, page_size, :multi) do
    Keyword.merge(opts, federation_limit: page_size, federation_offset: 0)
  end

  defp put_search_limit(opts, page_size, _mode) do
    Keyword.merge(opts, page: [size: page_size])
  end

  defp parse_page_size_param(raw, fallback) do
    case Integer.parse(to_string(raw || "")) do
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
      |> Enum.flat_map(fn value -> String.split(to_string(value), ",", trim: true) end)

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

  defp hit_summary(hit) when is_map(hit) do
    hit
    |> Map.take(["id", :id, "title", :title, "name", :name, "sku", :sku])
    |> Enum.map(fn {key, value} -> "#{key}: #{value}" end)
    |> Enum.join(" · ")
    |> case do
      "" -> "Structured result payload"
      summary -> summary
    end
  end

  defp hit_summary(_), do: "Result payload"

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
    |> assign(:capture_preview_json, nil)
    |> assign(:capture_preview_ok?, false)
  end

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

  defp workspace_playbook_exists?(root, name) do
    case Store.list_workspace_json(root) do
      {:ok, names} -> name in names
      {:error, _} -> false
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
      |> maybe_put_json_int("ranking_score_threshold", Keyword.get(v, :ranking_score_threshold))
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

  defp maybe_put_json_bool(m, _k, nil), do: m
  defp maybe_put_json_bool(m, k, b) when is_boolean(b), do: Map.put(m, k, b)
  defp maybe_put_json_bool(m, _, _), do: m

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
          <.ops_page_header
            title={@page_title}
            subtitle="Run bounded read-only probes, inspect federation behavior, then capture useful checks as reusable playbooks."
          />
          <.ops_link_button
            navigate={"#{@mount_path}/playbooks"}
            variant={:ghost}
          >
            Playbooks
          </.ops_link_button>
        </.ops_toolbar>

        <.ops_trail mount_path={@mount_path} current={:search} />

        <.ops_notice
          id="search-honesty-panel"
          kind={:warning}
          title="Non-production search playground"
        >
          Exploratory queries may be logged by Meilisearch or proxies. Do not paste production secrets or PII; keep page size and schema lists bounded.
        </.ops_notice>

        <.ops_panel class="space-y-6" aria-describedby="search-honesty-panel">
          <.ops_empty_state :if={@schema_allowlist == []} title="No schemas configured">
            Add allowlisted schema modules with <code class="text-ops-body">schema_allowlist</code>
            under <code class="text-ops-body">:scrypath_ops</code>
            or <code class="text-ops-body">SCRYPATH_OPS_SCHEMAS</code>
            — see <code class="text-ops-body">scrypath_ops/README.md</code> — then reload this screen.
          </.ops_empty_state>

          <.ops_empty_state
            :if={@schema_allowlist != [] && !Keyword.has_key?(@scrypath_opts, :backend)}
            title="Runtime not configured"
          >
            Scrypath runtime is not configured (missing <code class="text-ops-body">:backend</code>
            and related
            options under <code class="text-ops-body">:scrypath_ops</code>). See <code class="text-ops-body">scrypath_ops/README.md</code>.
          </.ops_empty_state>

          <.ops_status
            :if={@schema_allowlist == [] or !Keyword.has_key?(@scrypath_opts, :backend)}
            kind={:warning}
            title="Search controls are disabled until OPSUI is configured"
          >
            The form remains visible so operators can see the expected workflow, but it will not
            run until schemas and backend runtime options are configured.
          </.ops_status>

          <div class="grid gap-6 xl:grid-cols-[24rem_minmax(0,1fr)]">
            <.form
              for={%{}}
              as={:search}
              phx-submit="search"
              id="ops-search-playground-form"
              class={[
                "space-y-5 xl:sticky xl:top-6 xl:self-start",
                if(@schema_allowlist == [] or !Keyword.has_key?(@scrypath_opts, :backend),
                  do: "opacity-50 pointer-events-none",
                  else: nil
                )
              ]}
            >
              <.ops_fieldset legend="Search mode">
                <.ops_segmented_control
                  label="Mode"
                  event="set_mode"
                  selected={to_string(@mode)}
                  items={[{"Single index", "single"}, {"Multi index", "multi"}]}
                />
                <p :if={@mode == :single} class="text-ops-body text-base-content/80">
                  Run one allowlisted schema through the bounded Scrypath search path.
                </p>
                <p :if={@mode == :multi} class="text-ops-body text-base-content/80">
                  Multi index mode shows merge order as a federation view. Per-schema scores stay local. <a
                    class="link link-hover text-primary"
                    href={@guide_href}
                  >Read semantics</a>.
                </p>
              </.ops_fieldset>

              <.ops_fieldset legend="Query">
                <.ops_field id="search_q" label="Search text">
                  <.ops_text_input
                    id="search_q"
                    name="q"
                    value={@q}
                    placeholder="Try a bounded read-only query"
                    aria-describedby="search-honesty-panel"
                  />
                </.ops_field>
              </.ops_fieldset>

              <.ops_fieldset legend="Limits / safety">
                <p id="search-limits-copy" class="text-ops-sm leading-5 text-base-content/70">
                  Page size is capped at {SearchPlayground.max_page_size_allowed()} hits per request.
                </p>
                <.ops_field id="search_page_size" label="Page size" class="w-full max-w-xs">
                  <.ops_number_input
                    id="search_page_size"
                    name="page_size"
                    value={@page_size}
                    min="1"
                    max={SearchPlayground.max_page_size_allowed()}
                    aria-describedby="search-honesty-panel search-limits-copy"
                  />
                </.ops_field>
              </.ops_fieldset>

              <.ops_fieldset :if={@mode == :single} legend="Federation / merge">
                <.ops_field
                  id="search_schema"
                  label="Schema"
                  hint="Single-index mode runs exactly one allowlisted schema."
                >
                  <.ops_select
                    id="search_schema"
                    name="schema"
                    options={schema_options(@schema_allowlist)}
                    selected={inspect(@selected_schema)}
                    class="font-mono text-ops-sm"
                  />
                </.ops_field>
              </.ops_fieldset>

              <.ops_fieldset
                :if={@mode == :multi}
                legend="Federation / merge"
                hint={"Select up to #{SearchPlayground.max_schemas_allowed()} schema(s) for search_many/2."}
              >
                <.ops_checkbox_list
                  name="schemas[]"
                  options={schema_options(@schema_allowlist)}
                  selected={Enum.map(@selected_multi_schemas, &inspect/1)}
                />
              </.ops_fieldset>

              <.ops_button type="submit" variant={:primary} size={:md}>
                Run bounded search
              </.ops_button>
            </.form>

            <section aria-labelledby="search-results-heading" class="min-w-0 space-y-4">
              <div class="flex flex-wrap items-center justify-between gap-2">
                <h2
                  id="search-results-heading"
                  class="text-ops-h2 font-semibold leading-ops-tight"
                >
                  Results
                </h2>
                <.ops_badge kind={if @result_single || @result_multi, do: :success, else: :neutral}>
                  {if @result_single || @result_multi, do: "Last run loaded", else: "Run a probe"}
                </.ops_badge>
              </div>

              <.ops_status
                :if={@run_error}
                kind={:error}
                title="Search could not run"
                role="alert"
              >
                <p>{format_run_error(@run_error)}</p>
                <p class="mt-2 text-ops-sm">
                  Fix the query options or operator config, then run bounded search again.
                </p>
              </.ops_status>

              <.ops_empty_state
                :if={is_nil(@result_single) && is_nil(@result_multi) && is_nil(@run_error)}
                title="No probe has run yet"
              >
                Choose a mode, set a bounded query, and run search. Results stay read-only and can be captured as a playbook after a successful run.
              </.ops_empty_state>

              <div :if={@result_single} class="space-y-3">
                <.empty_or_hits_single result={@result_single} guide_href={@guide_href} />
              </div>

              <div :if={@result_multi} class="space-y-3">
                <div id="search-federation-status" role="status" class="text-ops-body space-y-2">
                  <p :if={@result_multi.failures == []} class="text-base-content/70">
                    All selected indexes returned results on this run.
                  </p>
                  <div
                    :if={@result_multi.failures != []}
                    id="search-partial-live"
                    class="rounded-ops-control border p-4 ops-tone-warning"
                  >
                    <p class="font-semibold">Some indexes did not return results.</p>
                    <p class="mt-1 text-ops-sm">
                      Failures are per schema and do not cancel the whole response. Next: open failure details, adjust entries or backend, then run bounded search again.
                    </p>
                    <p class="mt-2 text-ops-sm text-base-content/70">
                      <code class="text-ops-sm">:all</code>
                      entries expanded follow declaration order before limits apply when multi-search uses global expansion.
                    </p>
                    <.ops_disclosure
                      summary={"Failure details (#{length(@result_multi.failures)})"}
                      variant={:compact}
                      class="mt-2"
                    >
                      <ul class="list-inside list-disc font-mono text-ops-sm">
                        <%= for %{schema: s, reason: r} <- @result_multi.failures do %>
                          <li>{inspect(s)} — {inspect(r)}</li>
                        <% end %>
                      </ul>
                      <p :if={@show_all_footnote} class="mt-2 text-ops-sm text-base-content/80">
                        <code class="text-ops-sm">:all</code>
                        entries expanded to the configured global schema list in declaration order before limits apply; empty registry and missing
                        <code class="text-ops-sm">otp_app</code>
                        errors match library invalid_options / all_expansion vocabulary.
                      </p>
                    </.ops_disclosure>
                  </div>
                </div>

                <.ops_data_card title="Federation summary">
                  <p class="mt-1 text-base-content/80">
                    <strong>Merged order is a federation view</strong>
                    — per-schema relevance scores stay local; positions in the merge list are not a single-index ranking.
                  </p>
                  <p class="mt-2 text-ops-sm text-base-content/70">
                    Schemas in this response: {length(@result_multi.ordered)} · failures: {length(
                      @result_multi.failures
                    )}
                  </p>
                </.ops_data_card>

                <.ops_disclosure
                  :if={match?([_ | _], MultiSearchResult.merge_projection(@result_multi))}
                  summary={"Merge trace (#{length(MultiSearchResult.merge_projection(@result_multi))} row(s))"}
                  variant={:compact}
                >
                  <ol class="mt-2 list-inside list-decimal font-mono text-ops-sm">
                    <%= for {mod, hit} <- MultiSearchResult.merge_projection(@result_multi) do %>
                      <li>{inspect(mod)} — {inspect(hit)}</li>
                    <% end %>
                  </ol>
                </.ops_disclosure>

                <.ops_disclosure
                  :if={
                    is_list(@result_multi.merge_hit_order) && @result_multi.merge_hit_order != [] &&
                      MultiSearchResult.merge_projection(@result_multi) == []
                  }
                  summary={"Merge trace (#{length(@result_multi.merge_hit_order)} federation position(s))"}
                  variant={:compact}
                >
                  <ol class="mt-2 list-inside list-decimal font-mono text-ops-sm">
                    <%= for pair <- @result_multi.merge_hit_order do %>
                      <li>{inspect(pair)}</li>
                    <% end %>
                  </ol>
                </.ops_disclosure>

                <.ops_disclosure
                  :if={@result_multi.federation}
                  summary="Federation metadata"
                  variant={:compact}
                >
                  <p class="mt-2 text-ops-sm text-base-content/60">
                    Per-entry weights are uniform when the backend does not expose per-entry overrides.
                  </p>
                  <.ops_code_block variant={:compact} class="mt-2">
                    {inspect(@result_multi.federation, pretty: true)}
                  </.ops_code_block>
                </.ops_disclosure>

                <div class="space-y-3">
                  <.ops_heading level={2}>Per-schema panels</.ops_heading>
                  <%= for {mod, sres} <- @result_multi.ordered do %>
                    <.ops_data_card title={inspect(mod)}>
                      <p class="text-ops-sm text-base-content/70">
                        Hits: {length(sres.hits)} · estimatedTotalHits: {Map.get(
                          sres.raw,
                          "estimatedTotalHits"
                        )}
                      </p>
                      <.ops_disclosure summary="Raw per-schema result" variant={:compact} class="mt-2">
                        <.ops_code_block variant={:compact}>
                          {inspect(sres.raw, pretty: true)}
                        </.ops_code_block>
                      </.ops_disclosure>
                    </.ops_data_card>
                  <% end %>
                </div>
              </div>
            </section>
          </div>

          <div class="divider" />

          <section aria-labelledby="search-capture-heading" class="space-y-3">
            <h2
              id="search-capture-heading"
              class="text-ops-h2 font-semibold leading-ops-tight"
            >
              Save a search as a playbook
            </h2>
            <div
              :if={@capture_base == nil}
              class="ops-muted-panel p-4 text-ops-body text-base-content/70"
            >
              Run a search first. This panel captures the last successful single- or multi-search inputs after you have inspected the result.
            </div>

            <.form
              :if={@capture_base != nil}
              for={%{}}
              as={:capture}
              phx-change="capture_change"
              phx-submit="save_search_capture"
              class="max-w-2xl space-y-4"
              id="search-capture-form"
            >
              <div class="grid gap-3 md:grid-cols-2">
                <.ops_field id="capture_title" label="Title">
                  <.ops_text_input
                    id="capture_title"
                    name="capture[title]"
                    value={@capture_title}
                    placeholder="Optional"
                  />
                </.ops_field>
                <.ops_field id="capture_basename" label="Basename (.json)">
                  <.ops_text_input
                    id="capture_basename"
                    name="capture[basename]"
                    value={@capture_basename}
                    class="font-mono text-ops-body"
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

              <p
                :if={@capture_preview_ok?}
                class="text-ops-sm text-base-content/70"
                data-testid="playbook-preview-marker"
              >
                Validated playbook preview
              </p>
              <.ops_code_block :if={@capture_preview_json} data-testid="search-capture-preview-pre">
                {@capture_preview_json}
              </.ops_code_block>

              <.ops_button type="submit" variant={:primary}>
                Save search as playbook
              </.ops_button>
            </.form>
          </section>
        </.ops_panel>

        <.ops_handoff>
          <:step navigate={"#{@mount_path}/playbooks"} hint="Once a probe earns its keep —">
            Save it and open playbooks
          </:step>
        </.ops_handoff>
      </div>
    </Layouts.app>
    """
  end

  defp format_run_error({:page_size_out_of_range, n, max}) do
    "page size #{n} is outside the allowed range (max #{max})."
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
