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
      <div class="rounded-lg bg-base-200 p-lg">
        <h2 class="text-heading font-semibold">No hits for this query.</h2>
        <p class="mt-2 text-sm text-base-content/80">
          Widen filters or try another sample; see the honesty panel for merge ceilings and backend limits.
          (<a class="link link-primary" href={@guide_href}>guides/multi-index-search.md</a>).
        </p>
      </div>
    <% else %>
      <ul class="space-y-sm">
        <%= for hit <- @result.hits do %>
          <li class="rounded border border-base-300 p-sm font-mono text-xs">{inspect(hit)}</li>
        <% end %>
      </ul>
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
          push_patch(socket, to: "#{socket.assigns.mount_path}/search?mode=single")

        m ->
          assign(socket, :mode, m)
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
    {:noreply, push_patch(socket, to: "#{socket.assigns.mount_path}/search?mode=multi")}
  end

  def handle_event("set_mode", _, socket) do
    {:noreply, push_patch(socket, to: "#{socket.assigns.mount_path}/search?mode=single")}
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
         {:ok, opts} <- build_opts(scrypath_opts, page_size) do
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

            {:noreply, socket}

          {:error, reason} ->
            duration_ms = System.monotonic_time(:millisecond) - start_ms
            emit_run(:multi, :error, duration_ms)
            {:noreply, assign(socket, :run_error, {:scrypath, reason})}
        end
    end
  end

  defp build_opts(scrypath_opts, page_size) do
    if Keyword.has_key?(scrypath_opts, :backend) do
      {:ok, Keyword.merge(scrypath_opts, page: [size: page_size])}
    else
      {:error, :missing_backend}
    end
  end

  defp parse_page_size_param(raw, fallback) do
    case Integer.parse(to_string(raw || "")) do
      {n, _} -> n
      :error -> fallback
    end
  end

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
    <Layouts.app mount_path={@mount_path} flash={@flash} shell={@shell} ops_main_width={:wide}>
      <div class="space-y-6">
        <.ops_page_header title={@page_title} />

        <div class="text-sm text-base-content/80 -mt-2">
          <.link navigate={"#{@mount_path}/playbooks"} class="link link-hover">Saved playbooks</.link>
        </div>

        <div
          id="search-honesty-panel"
          class="rounded-md border border-warning/40 bg-warning/10 px-sm py-sm text-sm text-base-content"
        >
          <strong>Non-production search playground</strong>
          — exploratory queries may be logged by Meilisearch or proxies depending on deployment.
          <strong>Do not</strong>
          paste production secrets or PII; keep <code class="text-xs">page.size</code>
          and schema lists bounded.
        </div>

        <div
          class="card bg-base-100 border border-base-300 rounded-lg p-4 md:p-6 space-y-md"
          aria-describedby="search-honesty-panel"
        >
          <h2 class="text-lg font-semibold">Save search as playbook</h2>
          <p :if={@capture_base == nil} class="text-sm text-base-content/80">
            <strong>Run a search first</strong>
            — this panel captures the <strong>last successful</strong>
            single- or multi-search inputs (including honesty caps on page size and schema count). After a successful run, set an optional title and description, review the JSON preview, then save under a
            <code class="text-xs">*.json</code>
            basename. Safety copy: see the honesty panel above.
          </p>

          <.form
            :if={@capture_base != nil}
            for={%{}}
            as={:capture}
            phx-change="capture_change"
            phx-submit="save_search_capture"
            class="space-y-md max-w-2xl"
            id="search-capture-form"
          >
            <div class="grid gap-sm md:grid-cols-2">
              <div>
                <label class="label label-text text-sm font-semibold" for="capture_title">
                  Title
                </label>
                <input
                  id="capture_title"
                  type="text"
                  name="capture[title]"
                  value={@capture_title}
                  class="input input-bordered w-full"
                  placeholder="Optional"
                />
              </div>
              <div>
                <label class="label label-text text-sm font-semibold" for="capture_basename">
                  Basename (.json)
                </label>
                <input
                  id="capture_basename"
                  type="text"
                  name="capture[basename]"
                  value={@capture_basename}
                  class="input input-bordered w-full font-mono text-sm"
                  placeholder="my-search.json"
                  required
                />
              </div>
            </div>
            <div>
              <label class="label label-text text-sm font-semibold" for="capture_description">
                Description
              </label>
              <textarea
                id="capture_description"
                name="capture[description]"
                class="textarea textarea-bordered w-full text-sm min-h-24"
                placeholder="Optional"
              ><%= @capture_description %></textarea>
            </div>

            <p
              :if={@capture_preview_ok?}
              class="text-xs text-base-content/70"
              data-testid="playbook-preview-marker"
            >
              Validated playbook preview
            </p>
            <pre
              :if={@capture_preview_json}
              class="max-h-96 overflow-auto rounded-md bg-base-200 p-sm text-xs font-mono whitespace-pre-wrap break-words"
              data-testid="search-capture-preview-pre"
            ><%= @capture_preview_json %></pre>

            <button type="submit" class="btn btn-primary btn-sm min-h-10">
              Save search as playbook
            </button>
          </.form>
        </div>

        <div class="card bg-base-100 border border-base-300 rounded-lg p-4 md:p-6 space-y-6">
          <p :if={@schema_allowlist == []} class="text-base-content/80">
            No schemas configured for OPSUI. Set <code class="text-sm">schema_allowlist</code>
            under <code class="text-sm">:scrypath_ops</code>
            or use <code class="text-sm">SCRYPATH_OPS_SCHEMAS</code>
            — see <code class="text-sm">scrypath_ops/README.md</code>.
          </p>

          <p
            :if={@schema_allowlist != [] && !Keyword.has_key?(@scrypath_opts, :backend)}
            class="text-base-content/80"
          >
            Scrypath runtime is not configured (missing <code class="text-sm">:backend</code>
            and related
            options under <code class="text-sm">:scrypath_ops</code>). See <code class="text-sm">scrypath_ops/README.md</code>.
          </p>

          <.form
            for={%{}}
            as={:search}
            phx-submit="search"
            id="ops-search-playground-form"
            class={[
              "space-y-md",
              if(@schema_allowlist == [] or !Keyword.has_key?(@scrypath_opts, :backend),
                do: "opacity-50 pointer-events-none",
                else: nil
              )
            ]}
          >
            <fieldset class="space-y-sm border-0 p-0 m-0 min-w-0">
              <legend class="text-sm font-semibold text-base-content mb-sm">Search mode</legend>
              <div class="flex flex-wrap gap-sm">
                <button
                  type="button"
                  phx-click="set_mode"
                  phx-value-mode="single"
                  class={["btn", "btn-sm"] ++ if(@mode == :single, do: ["btn-primary"], else: [])}
                >
                  Single index
                </button>
                <button
                  type="button"
                  phx-click="set_mode"
                  phx-value-mode="multi"
                  data-testid="search-mode-multi"
                  class={["btn", "btn-sm"] ++ if(@mode == :multi, do: ["btn-primary"], else: [])}
                >
                  Multi index
                </button>
              </div>
              <p :if={@mode == :single} class="text-sm text-base-content/80">
                Merge order is a federation view — per-schema scores stay local. Multi index mode shows merge, weights, partial failures, and
                <code class="text-xs">:all</code>
                semantics from
                <a class="link link-hover text-primary" href={@guide_href}>multi-index-search</a>
                (<code class="text-xs">guides/multi-index-search.md</code>).
              </p>
            </fieldset>

            <fieldset class="space-y-sm border-0 p-0 m-0 min-w-0">
              <legend class="text-sm font-semibold text-base-content mb-sm">Query</legend>
              <div>
                <label class="label label-text text-sm font-semibold" for="search_q">
                  Search text
                </label>
                <input
                  id="search_q"
                  type="text"
                  name="q"
                  value={@q}
                  class="input input-bordered w-full min-h-10"
                  placeholder="Try a bounded read-only query"
                  aria-describedby="search-honesty-panel"
                />
              </div>
            </fieldset>

            <fieldset class="space-y-sm border-0 p-0 m-0 min-w-0">
              <legend class="text-sm font-semibold text-base-content mb-sm">Limits / safety</legend>
              <p id="search-limits-copy" class="text-xs text-base-content/70">
                Page size is capped at {SearchPlayground.max_page_size_allowed()} hits per request; keep queries bounded for operator safety.
              </p>
              <div class="w-full max-w-xs">
                <label class="label label-text text-sm font-semibold" for="search_page_size">
                  Page size
                </label>
                <input
                  id="search_page_size"
                  type="number"
                  name="page_size"
                  value={@page_size}
                  min="1"
                  max={SearchPlayground.max_page_size_allowed()}
                  class="input input-bordered w-full"
                  aria-describedby="search-honesty-panel search-limits-copy"
                />
              </div>
            </fieldset>

            <fieldset :if={@mode == :single} class="space-y-sm border-0 p-0 m-0 min-w-0">
              <legend class="text-sm font-semibold text-base-content mb-sm">
                Federation / merge
              </legend>
              <label class="label label-text text-sm font-semibold" for="search_schema">Schema</label>
              <select id="search_schema" name="schema" class="select select-bordered w-full max-w-xl">
                <%= for mod <- @schema_allowlist do %>
                  <option value={inspect(mod)} selected={mod == @selected_schema}>
                    {inspect(mod)}
                  </option>
                <% end %>
              </select>
            </fieldset>

            <fieldset :if={@mode == :multi} class="space-y-sm border-0 p-0 m-0 min-w-0">
              <legend class="text-sm font-semibold text-base-content mb-sm">
                Federation / merge
              </legend>
              <fieldset class="space-y-sm border border-base-300 rounded-md p-sm min-w-0">
                <legend class="text-xs font-semibold text-base-content/80 px-1">
                  Schemas to include (search_many)
                </legend>
                <p class="text-sm text-base-content/80">
                  Select up to {SearchPlayground.max_schemas_allowed()} schema(s) for <code class="text-xs">search_many/2</code>.
                </p>
                <div class="flex flex-col gap-sm">
                  <%= for mod <- @schema_allowlist do %>
                    <label class="flex cursor-pointer items-center gap-sm text-sm">
                      <input
                        type="checkbox"
                        name="schemas"
                        value={inspect(mod)}
                        class="checkbox checkbox-sm"
                      />
                      <span class="font-mono text-xs">{inspect(mod)}</span>
                    </label>
                  <% end %>
                </div>
              </fieldset>
            </fieldset>

            <fieldset class="space-y-sm border-0 p-0 m-0 min-w-0">
              <legend class="text-sm font-semibold text-base-content mb-sm">Actions</legend>
              <button type="submit" class="btn btn-primary min-h-10">
                Run sample searches
              </button>
            </fieldset>
          </.form>

          <div :if={@run_error} class="alert alert-error text-sm">
            <div>
              <h2 class="font-semibold">Search could not run:</h2>
              <p class="mt-1">{format_run_error(@run_error)}</p>
              <p class="mt-2 text-xs">
                Next: fix the query options or operator config, then use
                <strong>Run sample searches</strong>
                again.
                Merge and expansion semantics:
                <a class="link" href={@guide_href}>guides/multi-index-search.md</a>
              </p>
            </div>
          </div>

          <div :if={@result_single} class="space-y-md">
            <h2 class="text-heading font-semibold">Results</h2>
            <.empty_or_hits_single result={@result_single} guide_href={@guide_href} />
          </div>

          <div :if={@result_multi} class="space-y-md">
            <div id="search-federation-status" role="status" class="text-sm space-y-2">
              <p :if={@result_multi.failures == []} class="text-base-content/70">
                All selected indexes returned results on this run.
              </p>
              <div
                :if={@result_multi.failures != []}
                id="search-partial-live"
                class="alert alert-warning"
              >
                <p class="font-semibold">Some indexes did not return results.</p>
                <p class="mt-1 text-xs">
                  Failures are per schema and do not cancel the whole response. Next: open failure details, adjust entries or backend, then re-run <strong>Run sample searches</strong>.
                </p>
                <p class="mt-2 text-xs text-base-content/70">
                  <code class="text-xs">:all</code>
                  entries expanded follow declaration order before limits apply when multi-search uses global expansion.
                </p>
                <details class="mt-2">
                  <summary>
                    Failure details ({length(@result_multi.failures)})
                  </summary>
                  <ul class="mt-2 list-inside list-disc font-mono text-xs">
                    <%= for %{schema: s, reason: r} <- @result_multi.failures do %>
                      <li>{inspect(s)} — {inspect(r)}</li>
                    <% end %>
                  </ul>
                  <p :if={@show_all_footnote} class="mt-2 text-xs text-base-content/80">
                    <code class="text-xs">:all</code>
                    entries expanded to the configured global schema list in declaration order before limits apply; empty registry and missing
                    <code class="text-xs">otp_app</code>
                    errors match library invalid_options / all_expansion vocabulary.
                  </p>
                </details>
              </div>
            </div>

            <div class="rounded-lg bg-base-200 p-lg text-sm">
              <p class="font-semibold">Federation summary</p>
              <p class="mt-1 text-base-content/80">
                <strong>Merged order is a federation view</strong>
                — per-schema relevance scores stay local; positions in the merge list are not a single-index ranking.
              </p>
              <p class="mt-2 text-xs text-base-content/70">
                Schemas in this response: {length(@result_multi.ordered)} · failures: {length(
                  @result_multi.failures
                )}
              </p>
            </div>

            <details
              :if={match?([_ | _], MultiSearchResult.merge_projection(@result_multi))}
              class="rounded-lg bg-base-200 p-md"
            >
              <summary>
                Merge trace ({length(MultiSearchResult.merge_projection(@result_multi))} row(s))
              </summary>
              <ol class="mt-2 list-inside list-decimal font-mono text-xs">
                <%= for {mod, hit} <- MultiSearchResult.merge_projection(@result_multi) do %>
                  <li>{inspect(mod)} — {inspect(hit)}</li>
                <% end %>
              </ol>
            </details>

            <details
              :if={
                is_list(@result_multi.merge_hit_order) && @result_multi.merge_hit_order != [] &&
                  MultiSearchResult.merge_projection(@result_multi) == []
              }
              class="rounded-lg bg-base-200 p-md"
            >
              <summary>
                Merge trace ({length(@result_multi.merge_hit_order)} federation position(s))
              </summary>
              <ol class="mt-2 list-inside list-decimal font-mono text-xs">
                <%= for pair <- @result_multi.merge_hit_order do %>
                  <li>{inspect(pair)}</li>
                <% end %>
              </ol>
            </details>

            <details :if={@result_multi.federation} class="rounded-lg bg-base-200 p-md">
              <summary>Federation metadata</summary>
              <p class="mt-2 text-xs text-base-content/60">
                Per-entry weights are uniform when the backend does not expose per-entry overrides.
              </p>
              <pre class="mt-2 overflow-x-auto font-mono text-xs">{inspect(@result_multi.federation, pretty: true)}</pre>
            </details>

            <div class="space-y-md">
              <h2 class="text-heading font-semibold">Per-schema panels</h2>
              <%= for {mod, sres} <- @result_multi.ordered do %>
                <div class="rounded-lg border border-base-300 p-md">
                  <h3 class="font-mono text-sm font-semibold">{inspect(mod)}</h3>
                  <p class="text-xs text-base-content/70">
                    Hits: {length(sres.hits)} · estimatedTotalHits: {Map.get(
                      sres.raw,
                      "estimatedTotalHits"
                    )}
                  </p>
                </div>
              <% end %>
            </div>
          </div>
        </div>
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
