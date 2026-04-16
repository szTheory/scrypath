defmodule Scrypath.Meilisearch do
  @moduledoc """
  Meilisearch-specific runtime entrypoints for Scrypath.

  `Scrypath.*` remains the common path for sync and the stable search happy path.
  This namespace is the explicit escape hatch for Meilisearch-native behavior that
  should stay visible instead of being tunneled through generic options.

  Use `Scrypath.search/3` for text plus validated `filter:`, `sort:`, `page:`,
  and optional explicit hydration through `repo:`. Use `Scrypath.Meilisearch.search/3`
  when you need native Meilisearch payloads that do not belong on the common path.
  """

  @behaviour Scrypath.Backend

  alias Scrypath.Document
  alias Scrypath.Meilisearch.Client
  alias Scrypath.Query

  @impl true
  def name, do: :meilisearch

  @impl true
  def index_name(schema_module, config) do
    prefix =
      Keyword.get(config, :index_prefix) ||
        Scrypath.schema_config(schema_module).index_prefix ||
        "scrypath"

    schema_name = schema_module |> Module.split() |> List.last() |> Macro.underscore()

    "#{prefix}_#{schema_name}"
  end

  @impl true
  @spec upsert_documents(module(), [Document.t()], keyword()) :: {:ok, map()} | {:error, term()}
  def upsert_documents(schema_module, documents, config) when is_list(documents) do
    index = Keyword.get(config, :index_name) || index_name(schema_module, config)

    with {:ok, response} <- client(config).upsert_documents(index, documents, config) do
      {:ok,
       %{
         index: index,
         document_ids: Enum.map(documents, & &1.id),
         task: normalize_task(response)
       }}
    end
  end

  @impl true
  def delete_documents(schema_module, document_ids, config) when is_list(document_ids) do
    index = Keyword.get(config, :index_name) || index_name(schema_module, config)

    with {:ok, response} <- client(config).delete_documents(index, document_ids, config) do
      {:ok,
       %{
         index: index,
         document_ids: document_ids,
         task: normalize_task(response)
       }}
    end
  end

  @impl true
  @spec search(module(), Query.t() | map() | String.t(), keyword()) ::
          {:ok, map()} | {:error, term()}
  def search(schema_module, query, config) do
    index = index_name(schema_module, config)
    client(config).search(index, query, config)
  end

  defp client(config) do
    Keyword.get(config, :meilisearch_client) || Client
  end

  defp normalize_task(response) do
    %{
      uid: response["taskUid"] || response[:taskUid] || response["uid"] || response[:uid],
      status: response["status"] || response[:status],
      type: response["type"] || response[:type],
      index_uid: response["indexUid"] || response[:indexUid],
      raw: response
    }
  end
end
