defmodule Scrypath.Sync do
  @moduledoc false

  alias Scrypath.Config
  alias Scrypath.Identity
  alias Scrypath.Meilisearch.Tasks
  alias Scrypath.Projection

  @spec sync_record(module(), struct() | map(), keyword()) :: {:ok, term()} | {:error, term()}
  def sync_record(schema_module, record, opts \\ []) do
    sync_records(schema_module, [record], opts)
  end

  @spec sync_records(module(), [struct() | map()], keyword()) :: {:ok, term()} | {:error, term()}
  def sync_records(schema_module, records, opts \\ []) when is_list(records) do
    config = Config.resolve!(opts)
    documents = Enum.map(records, &Projection.document(schema_module, &1))

    dispatch_upsert(schema_module, documents, config)
  end

  @spec delete_record(module(), struct() | map(), keyword()) :: {:ok, term()} | {:error, term()}
  def delete_record(schema_module, record, opts \\ []) do
    schema_module
    |> Identity.document_id(record)
    |> List.wrap()
    |> then(&delete_documents(schema_module, &1, opts))
  end

  @spec delete_document(module(), term(), keyword()) :: {:ok, term()} | {:error, term()}
  def delete_document(schema_module, document_id, opts \\ []) do
    delete_documents(schema_module, [document_id], opts)
  end

  @spec delete_documents(module(), [term()], keyword()) :: {:ok, term()} | {:error, term()}
  def delete_documents(schema_module, document_ids, opts \\ []) when is_list(document_ids) do
    config = Config.resolve!(opts)
    dispatch_delete(schema_module, document_ids, config)
  end

  defp dispatch_upsert(schema_module, documents, config) do
    case Keyword.fetch!(config, :sync_mode) do
      :oban ->
        config
        |> Config.ensure_oban_ready!()
        |> build_oban_upsert_result(documents)
        |> decorate_result(config)

      _other ->
        backend = Config.fetch_backend!(config)

        backend.upsert_documents(schema_module, documents, config)
        |> maybe_wait_for_task(config)
        |> decorate_result(config)
    end
  end

  defp dispatch_delete(schema_module, document_ids, config) do
    case Keyword.fetch!(config, :sync_mode) do
      :oban ->
        config
        |> Config.ensure_oban_ready!()
        |> build_oban_delete_result(document_ids)
        |> decorate_result(config)

      _other ->
        backend = Config.fetch_backend!(config)

        backend.delete_documents(schema_module, document_ids, config)
        |> maybe_wait_for_task(config)
        |> decorate_result(config)
    end
  end

  defp maybe_wait_for_task({:ok, %{task: task} = result}, config) when is_map(task) do
    case Keyword.fetch!(config, :sync_mode) do
      :inline ->
        case Tasks.wait_for_task(task, config) do
          {:ok, waited_task} -> {:ok, %{result | task: waited_task}}
          {:error, reason} -> {:error, reason}
        end

      :manual ->
        {:ok, result}

      :oban ->
        {:ok, result}
    end
  end

  defp maybe_wait_for_task(result, _config), do: result

  defp decorate_result({:ok, result}, config) when is_map(result) do
    {:ok,
     result
     |> Map.put(:mode, Keyword.fetch!(config, :sync_mode))
     |> Map.put(:status, result_status(config))}
  end

  defp decorate_result(result, _config), do: result

  defp result_status(config) do
    case Keyword.fetch!(config, :sync_mode) do
      :inline -> :completed
      :manual -> :accepted
      :oban -> :accepted
    end
  end

  defp build_oban_upsert_result(config, documents) do
    {:ok,
     %{
       document_ids: Enum.map(documents, & &1.id),
       document_count: length(documents),
       oban: %{
         queue: Config.oban_queue(config),
         max_attempts: Config.oban_max_attempts(config),
         name: Config.oban_module(config)
       }
     }}
  end

  defp build_oban_delete_result(config, document_ids) do
    {:ok,
     %{
       document_ids: document_ids,
       document_count: length(document_ids),
       oban: %{
         queue: Config.oban_queue(config),
         max_attempts: Config.oban_max_attempts(config),
         name: Config.oban_module(config)
       }
     }}
  end
end
