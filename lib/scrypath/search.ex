defmodule Scrypath.Search do
  @moduledoc false

  alias Scrypath.Config
  alias Scrypath.Query

  @spec search(module(), String.t(), keyword()) :: {:ok, term()} | {:error, term()}
  def search(schema_module, text, opts \\ []) when is_binary(text) and is_list(opts) do
    search_opts = Scrypath.Options.validate_search_options!(schema_module, opts)
    config = Config.resolve!(runtime_opts(opts))
    query = Query.new(text, search_opts)
    backend = Config.fetch_backend!(config)

    backend.search(schema_module, query, config)
  end

  @spec search!(module(), String.t(), keyword()) :: term()
  def search!(schema_module, text, opts \\ []) do
    case search(schema_module, text, opts) do
      {:ok, result} -> result
      {:error, reason} -> raise RuntimeError, "search failed: #{inspect(reason)}"
    end
  end

  defp runtime_opts(opts) do
    Keyword.drop(opts, [:filter, :sort, :page])
  end
end
