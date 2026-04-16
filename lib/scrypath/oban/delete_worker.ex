if Code.ensure_loaded?(Oban.Worker) and Code.ensure_loaded?(Oban.Job) do
  defmodule Scrypath.Oban.DeleteWorker do
    @moduledoc false

    use Oban.Worker, queue: :scrypath, max_attempts: 8

    alias Scrypath.Config

    @impl Oban.Worker
    def perform(%Oban.Job{args: args}) do
      with {:ok, schema_module} <- resolve_schema(args),
           {:ok, backend} <- resolve_backend(args),
           {:ok, index_name} <- fetch_index(args),
           {:ok, document_ids} <- load_document_ids(args),
           :ok <- validate_document_count(args, document_ids),
           {:ok, config} <- build_config(backend, index_name) do
        case backend.delete_documents(schema_module, document_ids, config) do
          {:ok, _result} -> :ok
          {:error, reason} -> {:error, reason}
        end
      else
        {:error, reason} -> {:cancel, {:invalid_job, reason}}
      end
    end

    defp resolve_schema(%{"schema" => name}) when is_binary(name) do
      resolve_existing_module(name, fn module -> function_exported?(module, :__scrypath__, 1) end)
    end

    defp resolve_schema(_args), do: {:error, :invalid_schema}

    defp resolve_backend(%{"backend" => name}) when is_binary(name) do
      resolve_existing_module(name, fn module ->
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

    defp validate_document_count(%{"document_count" => count}, document_ids)
         when is_integer(count) and count == length(document_ids),
         do: :ok

    defp validate_document_count(_args, _document_ids), do: {:error, :invalid_document_count}

    defp build_config(backend, index_name) do
      try do
        config = [
          backend: backend,
          sync_mode: :manual
        ]

        {:ok, Config.resolve!(config) |> Keyword.put(:index_name, index_name)}
      rescue
        error in ArgumentError -> {:error, {:invalid_config, Exception.message(error)}}
      end
    end

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
      try do
        parts = name |> String.split(".") |> Enum.map(&String.to_existing_atom/1)
        {:ok, Module.safe_concat(parts)}
      rescue
        ArgumentError -> {:error, {:unknown_module, name}}
      end
    end
  end
end
