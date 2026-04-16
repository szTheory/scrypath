defmodule Scrypath.Search do
  @moduledoc false

  alias Scrypath.Config
  alias Scrypath.Hydration
  alias Scrypath.Query
  alias Scrypath.SearchResult

  @spec search(module(), String.t(), keyword()) :: {:ok, SearchResult.t()} | {:error, term()}
  def search(schema_module, text, opts \\ []) when is_binary(text) and is_list(opts) do
    search_opts = Scrypath.Options.validate_search_options!(schema_module, opts)
    config = Config.resolve!(runtime_opts(opts))
    query = Query.new(text, search_opts)
    backend = Config.fetch_backend!(config)

    with {:ok, raw_result} <- backend.search(schema_module, query, config) do
      {:ok, decorate_result(schema_module, query, raw_result, config)}
    end
  end

  @spec search!(module(), String.t(), keyword()) :: SearchResult.t()
  def search!(schema_module, text, opts \\ []) do
    case search(schema_module, text, opts) do
      {:ok, result} -> result
      {:error, reason} -> raise RuntimeError, "search failed: #{inspect(reason)}"
    end
  end

  defp runtime_opts(opts) do
    Keyword.drop(opts, [:filter, :sort, :page])
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
