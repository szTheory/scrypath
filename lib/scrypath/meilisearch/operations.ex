defmodule Scrypath.Meilisearch.Operations do
  @moduledoc false

  alias Scrypath.Document
  alias Scrypath.Meilisearch
  alias Scrypath.Meilisearch.Client
  alias Scrypath.Operations
  alias Scrypath.Operations.Result
  alias Scrypath.Operations.Task

  @spec upsert_documents(module(), [Document.t()], keyword()) ::
          {:ok, Result.t()} | {:error, term()}
  def upsert_documents(schema_module, documents, config) when is_list(documents) do
    index = Keyword.get(config, :index_name) || Meilisearch.index_name(schema_module, config)
    document_id_field = Scrypath.document_id_field(schema_module)

    with {:ok, response} <-
           client(config).upsert_documents(
             index,
             documents,
             Keyword.put(config, :document_id_field, document_id_field)
           ),
         {:ok, task} <- Meilisearch.normalize_task(response) do
      {:ok,
       Result.new(
         mode: Keyword.get(config, :sync_mode, :manual),
         status: :accepted,
         document_ids: Enum.map(documents, & &1.id),
         document_count: length(documents),
         task: Operations.task_from_backend(task, source: :meilisearch),
         metadata: %{index: index}
       )}
    end
  end

  @spec delete_documents(module(), [term()], keyword()) :: {:ok, Result.t()} | {:error, term()}
  def delete_documents(schema_module, document_ids, config) when is_list(document_ids) do
    index = Keyword.get(config, :index_name) || Meilisearch.index_name(schema_module, config)

    with {:ok, response} <- client(config).delete_documents(index, document_ids, config),
         {:ok, task} <- Meilisearch.normalize_task(response) do
      {:ok,
       Result.new(
         mode: Keyword.get(config, :sync_mode, :manual),
         status: :accepted,
         document_ids: document_ids,
         document_count: length(document_ids),
         task: Operations.task_from_backend(task, source: :meilisearch),
         metadata: %{index: index}
       )}
    end
  end

  @spec to_public_result(Result.t()) :: map()
  def to_public_result(%Result{} = result) do
    %{
      index: Map.get(result.metadata, :index),
      document_ids: result.document_ids,
      task: public_task(result.task)
    }
  end

  defp client(config) do
    Keyword.get(config, :meilisearch_client) || Client
  end

  defp public_task(%Task{} = task) do
    %{
      uid: task.id,
      status: task.state,
      index_uid: Map.get(task.reference, :index_uid),
      type: Map.get(task.metadata, :type),
      raw: task.raw
    }
  end
end
