defmodule Scrypath.Telemetry do
  @moduledoc false

  alias Scrypath.Config

  @type event_name :: [atom()]
  @type metadata :: map()

  @spec span(event_name(), metadata(), (-> {term(), metadata()})) :: term()
  def span(event_name, metadata, fun) when is_list(event_name) and is_map(metadata) do
    :telemetry.span(event_name, metadata, fn ->
      {result, stop_metadata} = fun.()
      {result, Map.merge(metadata, stop_metadata)}
    end)
  end

  @spec common_metadata(module(), keyword(), keyword()) :: metadata()
  def common_metadata(schema_module, config, extra \\ []) do
    backend = Config.fetch_backend!(config)

    %{
      schema: schema_module,
      backend: backend.name(),
      index: backend.index_name(schema_module, config)
    }
    |> maybe_put(:sync_mode, Keyword.get(config, :sync_mode))
    |> maybe_put(:repo, Keyword.get(config, :repo))
    |> Map.merge(Map.new(extra))
  end

  @spec stop_metadata(term(), keyword()) :: metadata()
  def stop_metadata(result, extra \\ [])

  def stop_metadata({:ok, %_{} = result}, extra),
    do: stop_metadata({:ok, Map.from_struct(result)}, extra)

  def stop_metadata({:ok, %{status: :noop, document_count: 0} = result}, extra) do
    %{}
    |> maybe_put(:status, :noop)
    |> maybe_put(:mode, Map.get(result, :mode))
    |> Map.put(:document_count, 0)
    |> Map.merge(Map.new(extra))
  end

  def stop_metadata({:ok, result}, extra) when is_map(result) do
    result
    |> result_metadata()
    |> Map.merge(Map.new(extra))
  end

  def stop_metadata({:error, reason}, extra) do
    Map.merge(%{error_kind: error_kind(reason)}, Map.new(extra))
  end

  def stop_metadata(result, extra) do
    Map.merge(%{result_kind: result_kind(result)}, Map.new(extra))
  end

  defp result_metadata(result) do
    %{}
    |> maybe_put(:status, Map.get(result, :status))
    |> maybe_put(:mode, Map.get(result, :mode))
    |> maybe_put(
      :document_count,
      Map.get(result, :document_count) || count(Map.get(result, :document_ids))
    )
    |> maybe_put(:record_count, count(Map.get(result, :records)))
    |> maybe_put(:hit_count, count(Map.get(result, :hits)))
    |> maybe_put(:missing_count, count(Map.get(result, :missing_ids)))
  end

  defp count(value) when is_list(value), do: length(value)
  defp count(_value), do: nil

  defp error_kind({:http_error, status, _body}) when is_integer(status), do: :http
  defp error_kind({:transport_error, _}), do: :transport
  defp error_kind({:timeout, _}), do: :timeout
  defp error_kind({:task_failed, _}), do: :task_failed
  defp error_kind({:cancelled, _}), do: :cancelled
  defp error_kind({:invalid_task_payload, _}), do: :invalid_task_payload
  defp error_kind(reason) when is_atom(reason), do: reason
  defp error_kind(_), do: :other

  defp result_kind(result) when is_tuple(result), do: :tuple
  defp result_kind(result) when is_atom(result), do: result
  defp result_kind(_), do: :other

  defp maybe_put(metadata, _key, nil), do: metadata
  defp maybe_put(metadata, _key, ""), do: metadata
  defp maybe_put(metadata, key, value), do: Map.put(metadata, key, value)
end
