defmodule Scrypath.Oban.Payload do
  @moduledoc false

  alias Scrypath.Config
  alias Scrypath.Document

  @spec build_upsert(module(), [Document.t()], keyword()) :: map()
  def build_upsert(schema_module, documents, config) when is_list(documents) do
    payload =
      base_payload("upsert", schema_module, config)
      |> Map.put("document_ids", Enum.map(documents, &serialize_scalar!(&1.id)))
      |> Map.put("document_count", length(documents))
      |> Map.put(
        "documents",
        Enum.map(documents, fn %Document{} = document ->
          %{
            "id" => serialize_scalar!(document.id),
            "data" => serialize_map!(document.data),
            "source" => Atom.to_string(document.source)
          }
        end)
      )

    payload
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
  end

  defp serialize_map!(value) when is_map(value) do
    if Map.has_key?(value, :__struct__) do
      struct_module = Map.fetch!(value, :__struct__)

      raise ArgumentError,
            "oban payloads only support JSON-safe values, got struct #{inspect(struct_module)}"
    end

    Map.new(value, fn
      {key, nested} when is_atom(key) ->
        {Atom.to_string(key), serialize_value!(nested)}

      {key, nested} when is_binary(key) ->
        {key, serialize_value!(nested)}

      {key, _nested} ->
        raise ArgumentError,
              "oban payload maps only support atom or string keys, got #{inspect(key)}"
    end)
  end

  defp serialize_value!(value) when is_map(value), do: serialize_map!(value)
  defp serialize_value!(value) when is_list(value), do: Enum.map(value, &serialize_value!/1)
  defp serialize_value!(value), do: serialize_scalar!(value)

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
