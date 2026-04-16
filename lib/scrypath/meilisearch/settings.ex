defmodule Scrypath.Meilisearch.Settings do
  @moduledoc false

  alias Scrypath.Meilisearch
  alias Scrypath.Meilisearch.Client

  @spec resolve(module(), keyword()) :: map()
  def resolve(schema_module, config) do
    schema_module
    |> Scrypath.schema_settings()
    |> Map.merge(Keyword.get(config, :settings, %{}))
  end

  @spec apply(module(), String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def apply(schema_module, index_name, config) do
    settings = resolve(schema_module, config)

    with {:ok, response} <- client(config).update_settings(index_name, settings, config) do
      {:ok,
       %{
         index: index_name,
         settings: settings,
         task: Meilisearch.normalize_task(response)
       }}
    end
  end

  defp client(config) do
    Keyword.get(config, :meilisearch_client) || Client
  end
end
