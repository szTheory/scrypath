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
  alias Scrypath.Meilisearch.IndexManagement
  alias Scrypath.Meilisearch.Naming
  alias Scrypath.Meilisearch.Operations
  alias Scrypath.Meilisearch.Query, as: MeilisearchQuery
  alias Scrypath.Meilisearch.Settings
  alias Scrypath.Meilisearch.TaskPayload
  alias Scrypath.Query

  @impl true
  def name, do: :meilisearch

  @impl true
  def index_name(schema_module, config) do
    Naming.index_name(schema_module, config)
  end

  @impl true
  @spec upsert_documents(module(), [Document.t()], keyword()) :: {:ok, map()} | {:error, term()}
  def upsert_documents(schema_module, documents, config) when is_list(documents) do
    with {:ok, result} <- Operations.upsert_documents(schema_module, documents, config) do
      {:ok, Operations.to_public_result(result)}
    end
  end

  @impl true
  def delete_documents(schema_module, document_ids, config) when is_list(document_ids) do
    with {:ok, result} <- Operations.delete_documents(schema_module, document_ids, config) do
      {:ok, Operations.to_public_result(result)}
    end
  end

  @impl true
  @doc """
  Run a native Meilisearch search request against either the live index or an
  explicit target/index override.
  """
  @spec search(module(), Query.t() | map() | String.t(), keyword()) ::
          {:ok, map()} | {:error, term()}
  def search(schema_module, query, config) do
    index =
      Keyword.get(config, :index_name) ||
        Keyword.get(config, :target_index) ||
        index_name(schema_module, config)

    client(config).search(index, query, config)
  end

  @impl true
  @spec search_facet_values(module(), String.t(), String.t(), keyword(), keyword()) ::
          {:ok, map()} | {:error, term()}
  def search_facet_values(schema_module, facet_name, facet_query, opts, config) do
    index =
      Keyword.get(config, :index_name) ||
        Keyword.get(config, :target_index) ||
        index_name(schema_module, config)

    client(config).facet_search(index, facet_name, facet_query, opts, config)
  end

  @impl true
  @spec search_many([{module(), Query.t(), keyword()}], keyword()) ::
          {:ok, map()} | {:error, term()}
  def search_many(paired_queries, config) when is_list(paired_queries) do
    queries =
      Enum.map(paired_queries, fn {schema_module, %Query{} = query, fed_opts} ->
        index = index_name(schema_module, config)

        base =
          query
          |> MeilisearchQuery.to_payload()
          |> Map.put("indexUid", index)

        case Keyword.get(fed_opts, :federation_weight) do
          w when is_float(w) ->
            Map.put(base, "federationOptions", %{"weight" => w})

          _ ->
            base
        end
      end)

    federation = %{
      "limit" => Keyword.fetch!(config, :federation_limit),
      "offset" => Keyword.fetch!(config, :federation_offset)
    }

    payload = %{"queries" => queries, "federation" => federation}

    client(config).multi_search(payload, config)
  end

  @spec apply_settings(module(), String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def apply_settings(schema_module, index_name, config \\ []) do
    Settings.apply(schema_module, index_name, config)
  end

  @spec create_index(module(), String.t() | atom() | nil, keyword()) ::
          {:ok, map()} | {:error, term()}
  def create_index(schema_module, primary_key, config \\ []) do
    IndexManagement.create_index(schema_module, primary_key, config)
  end

  @spec swap_indexes(module(), keyword()) :: {:ok, map()} | {:error, term()}
  def swap_indexes(schema_module, config \\ []) do
    IndexManagement.swap_indexes(schema_module, config)
  end

  defp client(config) do
    Keyword.get(config, :meilisearch_client) || Client
  end

  @doc false
  def normalize_task(response, stage \\ :initial), do: TaskPayload.normalize(response, stage)
end
