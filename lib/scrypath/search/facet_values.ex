defmodule Scrypath.Search.FacetValues do
  @moduledoc false

  alias Scrypath.Config
  alias Scrypath.FacetSearchResult
  alias Scrypath.Telemetry

  @spec run(module(), String.t(), String.t(), keyword(), keyword()) ::
          {:ok, FacetSearchResult.t()} | {:error, term()}
  def run(schema_module, facet_name, search_string, search_opts, caller_opts) do
    config = Config.resolve!(runtime_opts(caller_opts))
    metadata = Telemetry.common_metadata(schema_module, config, [])

    Telemetry.span([:scrypath, :search_facet_values], metadata, fn ->
      backend = Config.fetch_backend!(config)

      result =
        with {:ok, raw_result} <-
               backend.search_facet_values(
                 schema_module,
                 facet_name,
                 search_string,
                 search_opts,
                 config
               ) do
          {:ok, FacetSearchResult.new(raw_result)}
        end

      {result, Telemetry.stop_metadata(result)}
    end)
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
