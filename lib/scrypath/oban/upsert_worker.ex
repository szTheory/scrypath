if Code.ensure_loaded?(Oban.Worker) and Code.ensure_loaded?(Oban.Job) do
  defmodule Scrypath.Oban.UpsertWorker do
    @moduledoc false

    use Oban.Worker, queue: :scrypath, max_attempts: 8

    alias Scrypath.Config
    alias Scrypath.Document
    alias Scrypath.Oban.IndexingAck
    alias Scrypath.Oban.JobConfig

    @impl Oban.Worker
    def perform(%Oban.Job{args: args}) do
      with {:ok, schema_module} <- resolve_schema(args),
           {:ok, backend} <- resolve_backend(args),
           {:ok, index_name} <- fetch_index(args),
           {:ok, _document_ids, documents} <- load_documents(args),
           {:ok, config} <- build_config(backend, index_name, args) do
        case backend.upsert_documents(schema_module, documents, config) do
          {:ok, _} = ok -> IndexingAck.await(backend, ok, config)
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
        function_exported?(module, :upsert_documents, 3) and
          function_exported?(module, :index_name, 2)
      end)
    end

    defp resolve_backend(_args), do: {:error, :invalid_backend}

    defp fetch_index(%{"index" => index_name})
         when is_binary(index_name) and byte_size(index_name) > 0,
         do: {:ok, index_name}

    defp fetch_index(_args), do: {:error, :invalid_index}

    defp load_documents(args) do
      with {:ok, document_ids} <- load_document_ids(args),
           {:ok, documents} <- load_document_list(args),
           :ok <- validate_document_count(args, documents),
           :ok <- validate_document_id_alignment(document_ids, documents) do
        {:ok, document_ids, documents}
      end
    end

    defp load_document_ids(%{"document_ids" => document_ids}) when is_list(document_ids),
      do: {:ok, document_ids}

    defp load_document_ids(_args), do: {:error, :invalid_document_ids}

    defp load_document_list(%{"documents" => documents}) when is_list(documents) do
      documents
      |> Enum.reduce_while({:ok, []}, fn document, {:ok, acc} ->
        case normalize_document(document) do
          {:ok, normalized} -> {:cont, {:ok, [normalized | acc]}}
          {:error, reason} -> {:halt, {:error, reason}}
        end
      end)
      |> case do
        {:ok, documents} -> {:ok, Enum.reverse(documents)}
        error -> error
      end
    end

    defp load_document_list(_args), do: {:error, :invalid_documents}

    defp normalize_document(%{"id" => id, "data" => data, "source" => source})
         when is_map(data) and is_binary(source) do
      with :ok <- validate_json_map(data),
           {:ok, source_atom} <- normalize_source(source) do
        {:ok, %Document{id: id, data: data, source: source_atom}}
      end
    end

    defp normalize_document(_document), do: {:error, :invalid_document}

    defp validate_json_map(map) when is_map(map) do
      if Enum.all?(map, fn {key, value} -> is_binary(key) and json_value?(value) end) do
        :ok
      else
        {:error, :invalid_document_data}
      end
    end

    defp validate_document_count(%{"document_count" => count}, documents)
         when is_integer(count) and count == length(documents),
         do: :ok

    defp validate_document_count(_args, _documents), do: {:error, :invalid_document_count}

    defp validate_document_id_alignment(document_ids, documents) do
      if document_ids == Enum.map(documents, & &1.id) do
        :ok
      else
        {:error, :document_ids_mismatch}
      end
    end

    defp normalize_source("fields"), do: {:ok, :fields}
    defp normalize_source("custom"), do: {:ok, :custom}
    defp normalize_source(_source), do: {:error, :invalid_document_source}

    defp build_config(backend, index_name, args) do
      try do
        config =
          [backend: backend, sync_mode: :manual]
          |> JobConfig.merge_job_runtime_opts(args)

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

    defp json_value?(value) when is_binary(value), do: true
    defp json_value?(value) when is_integer(value), do: true
    defp json_value?(value) when is_float(value), do: true
    defp json_value?(value) when is_boolean(value), do: true
    defp json_value?(nil), do: true
    defp json_value?(value) when is_list(value), do: Enum.all?(value, &json_value?/1)
    defp json_value?(value) when is_map(value), do: validate_json_map(value) == :ok
    defp json_value?(_value), do: false
  end
end
