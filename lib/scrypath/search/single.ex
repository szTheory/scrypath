defmodule Scrypath.Search.Single do
  @moduledoc false

  alias Scrypath.Config
  alias Scrypath.Query
  alias Scrypath.Search.Result
  alias Scrypath.Telemetry

  @spec run(module(), String.t(), keyword(), keyword(), keyword()) ::
          {:ok, Scrypath.SearchResult.t()} | {:error, term()}
  def run(schema_module, text, search_opts, caller_opts, telemetry_extra)
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
          {:ok, Result.decorate(schema_module, query, raw_result, config)}
        end

      {result, Telemetry.stop_metadata(result)}
    end)
  end

  defp maybe_put_ranking_score_details_meta(meta, search_opts) do
    pq = Keyword.get(search_opts, :per_query, %{})

    if is_map(pq) and Map.get(pq, :show_ranking_score_details) == true do
      Map.put(meta, :ranking_score_details, true)
    else
      meta
    end
  end

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
end
