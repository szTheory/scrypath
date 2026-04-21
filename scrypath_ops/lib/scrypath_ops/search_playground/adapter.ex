defmodule ScrypathOps.SearchPlayground.Adapter do
  @moduledoc false

  @typedoc "Return type of `Scrypath.search/3`."
  @type search_result :: {:ok, Scrypath.SearchResult.t()} | {:error, term()}

  @typedoc "Return type of `Scrypath.search_many/2`."
  @type search_many_result :: {:ok, Scrypath.MultiSearchResult.t()} | {:error, term()}

  @callback search(module(), String.t(), keyword()) :: search_result()
  @callback search_many(list(), keyword()) :: search_many_result()
end

defmodule ScrypathOps.SearchPlayground.Adapter.Scrypath do
  @moduledoc """
  Default adapter delegating to `Scrypath.search/3` and `Scrypath.search_many/2`.

  Hosts may point `:search_playground_adapter` at a test double **only** in test
  configuration — not recommended for production releases.
  """

  @behaviour ScrypathOps.SearchPlayground.Adapter

  @impl true
  def search(schema, text, opts), do: Scrypath.search(schema, text, opts)

  @impl true
  def search_many(entries, opts), do: Scrypath.search_many(entries, opts)
end
