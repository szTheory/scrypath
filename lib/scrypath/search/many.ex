defmodule Scrypath.Search.Many do
  @moduledoc false

  alias Scrypath.Config
  alias Scrypath.Meilisearch.FederatedDecode
  alias Scrypath.MultiSearch.AllExpansion
  alias Scrypath.MultiSearch.Entries
  alias Scrypath.MultiSearchResult
  alias Scrypath.Query
  alias Scrypath.Search.Result

  @spec run(list(), keyword()) :: {{:ok, MultiSearchResult.t()} | {:error, term()}, map()}
  def run(entries, shared_opts) do
    case AllExpansion.expand(entries, shared_opts) do
      {:ok, expanded} ->
        meta = %{schema_count: length(expanded), raw_entry_count: length(entries)}

        result =
          with {:ok, quads} <- Entries.normalize(expanded, shared_opts),
               {:ok, prepared} <- validate_search_quads(quads) do
            run_prepared(prepared, shared_opts)
          end

        {result, meta}

      {:error, _} = err ->
        {err, %{}}
    end
  end

  @spec emit_partial({:ok, MultiSearchResult.t()} | {:error, term()}) :: :ok
  def emit_partial({:ok, %MultiSearchResult{failures: []}}), do: :ok

  def emit_partial({:ok, %MultiSearchResult{failures: failures}}) when failures != [] do
    :telemetry.execute(
      [:scrypath, :search_many, :partial],
      %{count: length(failures)},
      %{failure_count: length(failures)}
    )
  end

  def emit_partial(_), do: :ok

  defp run_prepared(prepared, shared_opts) do
    config = Config.resolve!(runtime_opts(shared_opts))
    backend = Config.fetch_backend!(config)

    paired_queries =
      Enum.map(prepared, fn {schema, query, federation_opts} ->
        {schema, query, federation_opts}
      end)

    needs_federated_merge? =
      Enum.any?(paired_queries, fn {_, _, federation_opts} -> federation_opts != [] end)

    cond do
      needs_federated_merge? and not function_exported?(backend, :search_many, 2) ->
        {:error,
         {:invalid_options, {:federation_merge_requires_native_search_many, %{backend: backend}}}}

      function_exported?(backend, :search_many, 2) ->
        run_native(backend, paired_queries, config)

      true ->
        run_sequential(
          backend,
          Enum.map(paired_queries, fn {schema, query, _} -> {schema, query} end),
          config
        )
    end
  end

  defp validate_search_quads(quads) do
    Enum.reduce_while(quads, {:ok, []}, fn {schema, text, merged, federation_opts}, {:ok, acc} ->
      case Scrypath.Options.validate_search_options(schema, merged) do
        {:ok, search_opts} ->
          {:cont, {:ok, acc ++ [{schema, Query.new(text, search_opts), federation_opts}]}}

        {:error, reason} ->
          {:halt, {:error, {:validation_failed, schema, reason}}}
      end
    end)
  end

  defp run_native(backend, paired_queries, config) do
    case backend.search_many(paired_queries, config) do
      {:ok, raw} ->
        indexed =
          Enum.map(paired_queries, fn {schema, _, _} ->
            {schema, backend.index_name(schema, config)}
          end)

        with {:ok, raw_pairs} <- FederatedDecode.per_schema_maps(raw, indexed) do
          triples =
            Enum.zip_with(paired_queries, raw_pairs, fn {schema, query, _},
                                                        {same_schema, raw_map} ->
              true = schema == same_schema
              {schema, query, raw_map}
            end)

          build_result(triples, [], config, raw, indexed)
        end

      {:error, reason} ->
        {:error, {:transport_failed, reason}}
    end
  end

  defp run_sequential(backend, paired_queries, config) do
    {oks, failures} =
      Enum.reduce(paired_queries, {[], []}, fn {schema, query}, {successes, errors} ->
        case backend.search(schema, query, config) do
          {:ok, raw} -> {successes ++ [{schema, query, raw}], errors}
          {:error, reason} -> {successes, errors ++ [%{schema: schema, reason: reason}]}
        end
      end)

    if oks == [] and failures != [] do
      {:error, {:all_failed, failures}}
    else
      build_result(oks, failures, config, nil, nil)
    end
  end

  defp build_result(triples, transport_failures, config, raw_response, indexed_schemas) do
    {ordered, hydration_failures} = parallel_decorate(triples, config)
    failures = transport_failures ++ hydration_failures

    if ordered == [] and failures != [] do
      {:error, {:all_failed, failures}}
    else
      {:ok,
       MultiSearchResult.new(
         ordered: ordered,
         by_schema: Map.new(ordered),
         failures: failures,
         federation: extract_federation_meta(raw_response),
         merge_hit_order: maybe_merge_hit_order(raw_response, indexed_schemas)
       )}
    end
  end

  defp parallel_decorate(triples, config) do
    timeout = Keyword.fetch!(config, :hydration_timeout)

    stream_results =
      Task.async_stream(
        triples,
        fn {schema, query, raw} -> Result.decorate(schema, query, raw, config) end,
        ordered: true,
        max_concurrency: max(1, length(triples)),
        timeout: timeout,
        on_timeout: :kill_task
      )
      |> Enum.to_list()

    Enum.zip(triples, stream_results)
    |> Enum.reduce({[], []}, fn
      {{schema, _, _}, {:ok, result}}, {successes, failures} ->
        {successes ++ [{schema, result}], failures}

      {{schema, _, _}, {:exit, :timeout}}, {successes, failures} ->
        {successes, failures ++ [%{schema: schema, reason: :hydration_timeout}]}

      {{schema, _, _}, {:exit, reason}}, {successes, failures} ->
        {successes, failures ++ [%{schema: schema, reason: {:hydration_exit, reason}}]}
    end)
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
      federation when is_map(federation) -> Scrypath.MultiSearchResult.Federation.new(federation)
    end
  end

  defp runtime_opts(opts),
    do:
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
