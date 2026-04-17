defmodule Scrypath.Meilisearch.IndexManagement do
  @moduledoc false

  alias Scrypath.Meilisearch
  alias Scrypath.Meilisearch.Client

  @spec live_index_name(module(), keyword()) :: String.t()
  def live_index_name(schema_module, config) do
    Meilisearch.index_name(schema_module, config)
  end

  @spec target_index_name(module(), keyword()) :: String.t()
  def target_index_name(schema_module, config) do
    Keyword.get(config, :target_index) || "#{live_index_name(schema_module, config)}__reindex"
  end

  @spec create_index(module(), String.t() | atom() | nil, keyword()) ::
          {:ok, map()} | {:error, term()}
  def create_index(schema_module, primary_key, config) do
    live_index = live_index_name(schema_module, config)
    target_index = target_index_name(schema_module, config)

    with {:ok, response} <- client(config).create_index(target_index, primary_key, config),
         {:ok, task} <- Meilisearch.normalize_task(response) do
      {:ok,
       %{
         live_index: live_index,
         target_index: target_index,
         task: task
       }}
    end
  end

  @spec swap_indexes(module(), keyword()) :: {:ok, map()} | {:error, term()}
  def swap_indexes(schema_module, config) do
    live_index = live_index_name(schema_module, config)
    target_index = target_index_name(schema_module, config)

    with {:ok, response} <- client(config).swap_indexes({live_index, target_index}, config),
         {:ok, task} <- Meilisearch.normalize_task(response) do
      {:ok,
       %{
         live_index: live_index,
         target_index: target_index,
         task: task
       }}
    end
  end

  defp client(config) do
    Keyword.get(config, :meilisearch_client) || Client
  end
end
