if Code.ensure_loaded?(Oban.Worker) and Code.ensure_loaded?(Oban.Job) do
  defmodule Scrypath.Oban.UpsertWorker do
    @moduledoc false

    use Oban.Worker, queue: :scrypath, max_attempts: 8

    alias Scrypath.Config
    alias Scrypath.Loader
    alias Scrypath.Oban.IndexingAck
    alias Scrypath.Oban.JobConfig
    alias Scrypath.Projection

    @impl Oban.Worker
    def perform(%Oban.Job{args: args}) do
      with {:ok, schema_module} <- resolve_schema(args),
           {:ok, backend} <- resolve_backend(args),
           {:ok, index_name} <- fetch_index(args),
           {:ok, document_ids} <- load_document_ids(args),
           {:ok, config} <- build_config(backend, index_name, args) do
        # Load the records as they are now; a retried or delayed job must never
        # send an older copy over newer index data.
        case Loader.load(schema_module, document_ids, config) do
          {:ok, records, missing_ids} ->
            documents = Enum.map(records, &Projection.document(schema_module, &1))

            with :ok <- write(backend, :upsert_documents, schema_module, documents, config) do
              write(backend, :delete_documents, schema_module, missing_ids, config)
            end

          {:error, reason} when reason in [:repo_required, :search_records_required] ->
            {:cancel, {:invalid_job, reason}}

          {:error, reason} ->
            {:error, reason}
        end
      else
        {:error, reason} -> {:cancel, {:invalid_job, reason}}
      end
    end

    defp write(_backend, _fun, _schema_module, [], _config), do: :ok

    defp write(backend, fun, schema_module, entries, config) do
      IndexingAck.await(backend, apply(backend, fun, [schema_module, entries, config]), config)
    end

    defp resolve_schema(%{"schema" => name}) when is_binary(name) do
      resolve_existing_module(name, fn module -> function_exported?(module, :__scrypath__, 1) end)
    end

    defp resolve_schema(_args), do: {:error, :invalid_schema}

    defp resolve_backend(%{"backend" => name}) when is_binary(name) do
      resolve_existing_module(name, fn module ->
        function_exported?(module, :upsert_documents, 3) and
          function_exported?(module, :delete_documents, 3) and
          function_exported?(module, :index_name, 2)
      end)
    end

    defp resolve_backend(_args), do: {:error, :invalid_backend}

    defp fetch_index(%{"index" => index_name})
         when is_binary(index_name) and byte_size(index_name) > 0,
         do: {:ok, index_name}

    defp fetch_index(_args), do: {:error, :invalid_index}

    defp load_document_ids(%{"document_ids" => document_ids}) when is_list(document_ids),
      do: {:ok, document_ids}

    defp load_document_ids(_args), do: {:error, :invalid_document_ids}

    defp build_config(backend, index_name, args) do
      config =
        [backend: backend, sync_mode: :manual]
        |> JobConfig.merge_job_runtime_opts(args)
        |> put_repo(args)

      {:ok, Config.resolve!(config) |> Keyword.put(:index_name, index_name)}
    rescue
      error in ArgumentError -> {:error, {:invalid_config, Exception.message(error)}}
    end

    defp put_repo(config, %{"repo" => repo}) when is_binary(repo) and repo != "" do
      case safe_module(repo) do
        {:ok, module} -> Keyword.put(config, :repo, module)
        {:error, _} -> config
      end
    end

    defp put_repo(config, _args), do: config

    defp resolve_existing_module(name, validator) do
      with {:ok, module} <- safe_module(name),
           true <- Code.ensure_loaded?(module),
           true <- validator.(module) do
        {:ok, module}
      else
        _ -> {:error, {:unknown_module, name}}
      end
    end

    defp safe_module(name) do
      parts = name |> String.split(".") |> Enum.map(&String.to_existing_atom/1)
      {:ok, Module.safe_concat(parts)}
    rescue
      ArgumentError -> {:error, {:unknown_module, name}}
    end
  end
end
