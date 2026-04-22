defmodule Scrypath.Search do
  @moduledoc false

  alias Scrypath.Config
  alias Scrypath.Hydration
  alias Scrypath.Meilisearch.FederatedDecode
  alias Scrypath.MultiSearch.AllExpansion
  alias Scrypath.MultiSearch.Entries
  alias Scrypath.MultiSearchResult
  alias Scrypath.Query
  alias Scrypath.SearchResult
  alias Scrypath.Telemetry

  @doc """
  Hydrated search pipeline used by `Scrypath.search/3`.

  ## Errors vs raises

  * **`ArgumentError`** — reserved for caller misuse that mirrors invalid option shapes
    (for example duplicate facet bucket keys) where validation intentionally raises.
  * **`{:error, reason}`** — operational and validation outcomes you should branch on,
    including backend failures and tagged tuples such as `{:transport_failed, _}`.

  Bang helpers (`search!/3`, `search_many!/2`, `search_within_facet!/4`) raise
  `Scrypath.Search.Error` with the same `reason` instead of returning `{:error, _}`.
  """
  @spec search(module(), String.t(), keyword()) :: {:ok, SearchResult.t()} | {:error, term()}
  def search(schema_module, text, opts \\ []) when is_binary(text) and is_list(opts) do
    case Scrypath.Options.validate_search_options(schema_module, opts) do
      {:error, {:validation, message}} when is_binary(message) ->
        raise ArgumentError, message

      {:error, {:invalid_options, _field, message}} when is_binary(message) ->
        raise ArgumentError, message

      {:error, _} = err ->
        err

      {:ok, search_opts} ->
        do_search(schema_module, text, search_opts, opts, [])
    end
  end

  @doc """
  Facet-scoped search used by `Scrypath.search_within_facet/4`.

  ## Errors vs raises

  * **`ArgumentError`** — structural misuse (bad bucket shape, duplicate facet locks, etc.).
  * **`{:error, reason}`** — same operational `{:error, _}` family as `search/3`, including
    transport failures from the configured backend.

  `search_within_facet!/4` raises `Scrypath.Search.Error` with the underlying `reason`
  when the non-bang call would return `{:error, _}`.
  """
  @spec search_within_facet(module(), String.t(), {atom(), term() | list()}, keyword()) ::
          {:ok, SearchResult.t()} | {:error, term()}
  def search_within_facet(schema_module, text, bucket, opts \\ [])
      when is_binary(text) and is_list(opts) do
    merged_opts = merge_facet_bucket_into_opts!(opts, bucket)

    case Scrypath.Options.validate_search_options(schema_module, merged_opts) do
      {:error, {:validation, message}} when is_binary(message) ->
        raise ArgumentError, message

      {:error, {:invalid_options, _field, message}} when is_binary(message) ->
        raise ArgumentError, message

      {:error, _} = err ->
        err

      {:ok, search_opts} ->
        telemetry_extra = [
          search_scope: :within_facet,
          scoped_facet: elem(bucket, 0)
        ]

        do_search(schema_module, text, search_opts, merged_opts, telemetry_extra)
    end
  end

  @spec search_within_facet!(module(), String.t(), {atom(), term() | list()}, keyword()) ::
          SearchResult.t()
  def search_within_facet!(schema_module, text, bucket, opts \\ []) do
    case search_within_facet(schema_module, text, bucket, opts) do
      {:ok, result} -> result
      {:error, reason} -> raise Scrypath.Search.Error, reason: reason
    end
  end

  defp do_search(schema_module, text, search_opts, caller_opts, telemetry_extra)
       when is_binary(text) and is_list(search_opts) and is_list(caller_opts) and
              is_list(telemetry_extra) do
    config = Config.resolve!(runtime_opts(caller_opts))
    query = Query.new(text, search_opts)

    metadata =
      schema_module
      |> Telemetry.common_metadata(config, telemetry_extra)
      |> maybe_put_ranking_score_details_meta(search_opts)

    Telemetry.span([:scrypath, :search], metadata, fn ->
      backend = Config.fetch_backend!(config)

      result =
        with {:ok, raw_result} <- backend.search(schema_module, query, config) do
          {:ok, decorate_result(schema_module, query, raw_result, config)}
        end

      {result, Telemetry.stop_metadata(result)}
    end)
  end

  defp merge_facet_bucket_into_opts!(opts, {attr, value}) when is_atom(attr) do
    existing = Keyword.get(opts, :facet_filter, [])

    if Keyword.has_key?(existing, attr) do
      raise ArgumentError,
            "search_within_facet: facet_filter already contains #{inspect(attr)}; " <>
              "omit that key from facet_filter: or use Scrypath.search/3 instead of locking the same attribute twice"
    else
      Keyword.put(opts, :facet_filter, Keyword.put(existing, attr, value))
    end
  end

  defp merge_facet_bucket_into_opts!(_opts, {bad, _value}) do
    raise ArgumentError,
          "search_within_facet: facet_bucket attribute must be an atom, got: #{inspect(bad)}"
  end

  defp merge_facet_bucket_into_opts!(_opts, bucket) do
    raise ArgumentError,
          "search_within_facet: facet_bucket must be a two-element tuple {facet_attribute, value}, got: #{inspect(bucket)}"
  end

  defp maybe_put_ranking_score_details_meta(meta, search_opts) do
    pq = Keyword.get(search_opts, :per_query, %{})

    if is_map(pq) and Map.get(pq, :show_ranking_score_details) == true do
      Map.put(meta, :ranking_score_details, true)
    else
      meta
    end
  end

  @spec search!(module(), String.t(), keyword()) :: SearchResult.t()
  def search!(schema_module, text, opts \\ []) do
    case search(schema_module, text, opts) do
      {:ok, result} -> result
      {:error, reason} -> raise Scrypath.Search.Error, reason: reason
    end
  end

  @doc """
  Federated search across multiple schemas.

  ## Entries and `federation_weight:`

  Each entry is `{schema, text}` or `{schema, text, keyword}` as for `search/3`.
  Optional **`federation_weight:`** on an entry sets a **merge weight** for
  Meilisearch federation (higher values surface earlier in the merged hit stream).
  Weights must be finite numbers; invalid values fail with
  `{:error, {:invalid_options, {:federation_weight, _}}}` before any backend call.

  When any entry carries a weight, the configured backend **must** implement
  `search_many/2` (native multi-search). Otherwise the call returns
  `{:error, {:invalid_options, {:federation_merge_requires_native_search_many, %{backend: _}}}}`
  instead of falling back to sequential per-schema searches.

  ## :all expansion

  An entry may be **`{:all, text}`** or **`{:all, text, keyword}`** (same shapes as a
  normal schema entry, but with the literal **`:all`** tag instead of a schema module).
  Those entries expand **before** validation into one concrete **`{schema, text, keyword}`**
  tuple per module in the configured allowlist, preserving declaration order.

  Provide the allowlist either as shared-option **`global_schemas:`** (a list of schema
  modules, in order — when set, it **replaces** the application-env list for that call)
  or by setting **`otp_app:`** and listing modules under **`Application.get_env(otp_app,
  :scrypath_global_search_schemas, [])`**.

  ## Scores vs merge ordering

  Federation returns a merged stream of hits, but **scores are comparable within one index
  only**. Cross-index **`federation_weight:`** values tune **merge ordering** under engine
  policy—they do not normalize per-index scores into a single global relevance number.

  ## Result metadata

  On native federation responses, `%MultiSearchResult{}` may include
  `merge_hit_order` (engine merge sequence) and `Scrypath.MultiSearchResult.merge_projection/1`
  for `{schema, hit_map}` rows. On sequential fallback, `merge_hit_order` is `nil`.

  Returns `{:error, {:validation_failed, schema, reason}}` when any entry fails
  `validate_search_options/2` before dispatch. Partial per-schema transport or
  hydration failures are represented on `failures:` inside `{:ok, %MultiSearchResult{}}`.

  ## Errors vs raises

  * **`{:error, reason}`** — structural preflight failures (`{:invalid_options, _}`,
    `{:validation_failed, _, _}`, `{:all_failed, _}`, `{:transport_failed, _}` on native
    multi-search) and other tagged errors you should branch on.
  * **`search_many!/2`** raises `Scrypath.Search.Error` with the same `reason` instead of
    returning `{:error, _}`.
  """
  @spec search_many(list(), keyword()) :: {:ok, MultiSearchResult.t()} | {:error, term()}
  def search_many(entries, shared_opts \\ []) when is_list(entries) and is_list(shared_opts) do
    raw = length(entries)

    Telemetry.span(
      [:scrypath, :search_many],
      %{schema_count: raw, raw_entry_count: raw},
      fn ->
        {result, count_meta} = run_search_many_inner(entries, shared_opts)
        maybe_emit_search_many_partial(result)

        stop =
          result
          |> Telemetry.stop_metadata()
          |> Map.merge(count_meta)

        {result, stop}
      end
    )
  end

  @spec search_many!(list(), keyword()) :: MultiSearchResult.t()
  def search_many!(entries, shared_opts \\ []) do
    case search_many(entries, shared_opts) do
      {:ok, result} ->
        result

      {:error, reason} ->
        raise Scrypath.Search.Error, reason: reason
    end
  end

  defp run_search_many_inner(entries, shared_opts) do
    case AllExpansion.expand(entries, shared_opts) do
      {:ok, expanded} ->
        meta = %{schema_count: length(expanded), raw_entry_count: length(entries)}

        result =
          with {:ok, quads} <- Entries.normalize(expanded, shared_opts),
               {:ok, prepared} <- validate_search_quads(quads) do
            run_search_many_prepared(prepared, shared_opts)
          end

        {result, meta}

      {:error, _} = err ->
        {err, %{}}
    end
  end

  defp run_search_many_prepared(prepared, shared_opts) do
    config = Config.resolve!(runtime_opts(shared_opts))
    backend = Config.fetch_backend!(config)

    paired_queries =
      Enum.map(prepared, fn {schema, query, fed_opts} ->
        {schema, query, fed_opts}
      end)

    needs_federated_merge? =
      Enum.any?(paired_queries, fn {_, _, fed_opts} -> fed_opts != [] end)

    cond do
      needs_federated_merge? and not function_exported?(backend, :search_many, 2) ->
        {:error,
         {:invalid_options, {:federation_merge_requires_native_search_many, %{backend: backend}}}}

      function_exported?(backend, :search_many, 2) ->
        run_native_search_many(backend, paired_queries, config)

      true ->
        sequential_pairs =
          Enum.map(paired_queries, fn {schema, query, _} -> {schema, query} end)

        run_sequential_search_many(backend, sequential_pairs, config)
    end
  end

  defp validate_search_quads(quads) do
    Enum.reduce_while(quads, {:ok, []}, fn {schema, text, merged, fed_opts}, {:ok, acc} ->
      case Scrypath.Options.validate_search_options(schema, merged) do
        {:ok, search_opts} ->
          q = Query.new(text, search_opts)
          {:cont, {:ok, acc ++ [{schema, q, fed_opts}]}}

        {:error, reason} ->
          {:halt, {:error, {:validation_failed, schema, reason}}}
      end
    end)
  end

  defp run_native_search_many(backend, paired_queries, config) do
    case backend.search_many(paired_queries, config) do
      {:ok, raw} ->
        indexed =
          Enum.map(paired_queries, fn {schema, _, _} ->
            {schema, backend.index_name(schema, config)}
          end)

        with {:ok, raw_pairs} <- FederatedDecode.per_schema_maps(raw, indexed) do
          triples_raw =
            Enum.zip_with(paired_queries, raw_pairs, fn {s, q, _fed}, {s2, raw_map} ->
              true = s == s2
              {s, q, raw_map}
            end)

          build_multi_result(triples_raw, [], config, raw, indexed)
        end

      {:error, reason} ->
        {:error, {:transport_failed, reason}}
    end
  end

  defp run_sequential_search_many(backend, paired_queries, config) do
    {oks, failures} =
      Enum.reduce(paired_queries, {[], []}, fn {schema, query}, {succ, fail} ->
        case backend.search(schema, query, config) do
          {:ok, raw} ->
            {succ ++ [{schema, query, raw}], fail}

          {:error, reason} ->
            {succ, fail ++ [%{schema: schema, reason: reason}]}
        end
      end)

    cond do
      oks == [] and failures != [] ->
        {:error, {:all_failed, failures}}

      true ->
        build_multi_result(oks, failures, config, nil, nil)
    end
  end

  defp build_multi_result(triples_raw, transport_failures, config, raw_response, indexed_schemas)
       when is_list(triples_raw) and is_list(transport_failures) do
    {ordered, hydration_failures} = parallel_decorate(triples_raw, config)
    failures = transport_failures ++ hydration_failures

    cond do
      ordered == [] and failures != [] ->
        {:error, {:all_failed, failures}}

      true ->
        by_schema = Map.new(ordered)
        federation = extract_federation_meta(raw_response)
        merge_hit_order = maybe_merge_hit_order(raw_response, indexed_schemas)

        result =
          MultiSearchResult.new(
            ordered: ordered,
            by_schema: by_schema,
            failures: failures,
            federation: federation,
            merge_hit_order: merge_hit_order
          )

        {:ok, result}
    end
  end

  defp maybe_merge_hit_order(%{} = raw, indexed) when is_list(indexed) do
    case FederatedDecode.merge_hit_order(raw, indexed) do
      {:ok, order} -> order
      {:error, _} -> nil
    end
  end

  defp maybe_merge_hit_order(_, _), do: nil

  defp extract_federation_meta(nil), do: nil

  defp extract_federation_meta(raw) when is_map(raw) do
    case Map.get(raw, "federation") || Map.get(raw, :federation) do
      nil -> nil
      fed when is_map(fed) -> Scrypath.MultiSearchResult.Federation.new(fed)
    end
  end

  defp parallel_decorate(triples_raw, config) do
    timeout = Keyword.fetch!(config, :hydration_timeout)
    max_c = max(1, length(triples_raw))

    stream_results =
      Task.async_stream(
        triples_raw,
        fn {schema, query, raw} ->
          decorate_result(schema, query, raw, config)
        end,
        ordered: true,
        max_concurrency: max_c,
        timeout: timeout,
        on_timeout: :kill_task
      )
      |> Enum.to_list()

    Enum.zip(triples_raw, stream_results)
    |> Enum.reduce({[], []}, fn
      {{schema, _query, _raw}, {:ok, result}}, {succ, fail} ->
        {succ ++ [{schema, result}], fail}

      {{schema, _query, _raw}, {:exit, :timeout}}, {succ, fail} ->
        {succ, fail ++ [%{schema: schema, reason: :hydration_timeout}]}

      {{schema, _query, _raw}, {:exit, reason}}, {succ, fail} ->
        {succ, fail ++ [%{schema: schema, reason: {:hydration_exit, reason}}]}
    end)
  end

  defp maybe_emit_search_many_partial({:ok, %MultiSearchResult{failures: []}}), do: :ok

  defp maybe_emit_search_many_partial({:ok, %MultiSearchResult{failures: fs}}) when fs != [] do
    :telemetry.execute(
      [:scrypath, :search_many, :partial],
      %{count: length(fs)},
      %{failure_count: length(fs)}
    )
  end

  defp maybe_emit_search_many_partial(_), do: :ok

  defp runtime_opts(opts) do
    Keyword.drop(opts, [
      :filter,
      :sort,
      :page,
      :facets,
      :facet_filter,
      :global_schemas,
      :per_query
    ])
  end

  defp decorate_result(schema_module, query, raw_result, config) when is_map(raw_result) do
    hits = Map.get(raw_result, "hits") || Map.get(raw_result, :hits) || []
    {records, missing_ids} = maybe_hydrate(schema_module, hits, config)

    SearchResult.new(query, raw_result, records, missing_ids)
  end

  defp maybe_hydrate(_schema_module, [], _config), do: {[], []}

  defp maybe_hydrate(schema_module, hits, config) do
    case Keyword.get(config, :repo) do
      nil ->
        {[], []}

      repo ->
        Hydration.hydrate(schema_module, hits,
          repo: repo,
          preload: Keyword.get(config, :preload, [])
        )
    end
  end
end
