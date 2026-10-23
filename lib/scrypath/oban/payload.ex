defmodule Scrypath.Oban.Payload do
  @moduledoc false

  alias Scrypath.Config

  @spec build_upsert(module(), [term()], keyword()) :: map()
  def build_upsert(schema_module, document_ids, config) when is_list(document_ids) do
    base_payload("upsert", schema_module, config)
    |> Map.put("document_ids", Enum.map(document_ids, &serialize_scalar!/1))
    |> Map.put("document_count", length(document_ids))
  end

  @spec build_delete(module(), [term()], keyword()) :: map()
  def build_delete(schema_module, document_ids, config) when is_list(document_ids) do
    base_payload("delete", schema_module, config)
    |> Map.put("document_ids", Enum.map(document_ids, &serialize_scalar!/1))
    |> Map.put("document_count", length(document_ids))
  end

  defp base_payload(operation, schema_module, config) do
    backend = Config.fetch_backend!(config)

    %{
      "operation" => operation,
      "schema" => Atom.to_string(schema_module),
      "backend" => Atom.to_string(backend),
      "index" => backend.index_name(schema_module, config),
      "sync_mode" => Atom.to_string(Keyword.get(config, :sync_mode, :oban))
    }
    |> Map.merge(runtime_job_fields(config))
  end

  # Persist connection hints so Oban workers can `Config.resolve!/1` without relying
  # solely on Application env (e.g. Phoenix example tests pass `meilisearch_url` at sync time).
  defp runtime_job_fields(config) do
    %{}
    |> put_optional_job_string(config, :meilisearch_url)
    |> put_optional_job_string(config, :index_prefix)
    |> put_optional_job_module(config, :repo)
  end

  defp put_optional_job_module(map, config, key) do
    case Keyword.get(config, key) do
      module when is_atom(module) and not is_nil(module) ->
        Map.put(map, Atom.to_string(key), Atom.to_string(module))

      _ ->
        map
    end
  end

  defp put_optional_job_string(map, config, key) do
    case Keyword.get(config, key) do
      v when is_binary(v) and v != "" -> Map.put(map, Atom.to_string(key), v)
      _ -> map
    end
  end

  defp serialize_scalar!(value) when is_binary(value), do: value
  defp serialize_scalar!(value) when is_integer(value), do: value
  defp serialize_scalar!(value) when is_float(value), do: value
  defp serialize_scalar!(value) when is_boolean(value), do: value
  defp serialize_scalar!(nil), do: nil
  defp serialize_scalar!(value) when is_atom(value), do: Atom.to_string(value)

  defp serialize_scalar!(value) do
    raise ArgumentError,
          "oban payloads only support JSON-safe scalar values, got #{inspect(value)}"
  end
end
