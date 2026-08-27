defmodule Scrypath.Search.Result do
  @moduledoc false

  alias Scrypath.Hydration
  alias Scrypath.SearchResult

  @spec decorate(module(), Scrypath.Query.t(), map(), keyword()) :: SearchResult.t()
  def decorate(schema_module, query, raw_result, config) when is_map(raw_result) do
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
