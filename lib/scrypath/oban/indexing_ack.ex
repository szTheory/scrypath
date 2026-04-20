defmodule Scrypath.Oban.IndexingAck do
  @moduledoc false

  alias Scrypath.Meilisearch.Tasks

  @doc """
  After a successful Meilisearch write, wait for the returned task (if any) so
  subsequent search/index calls do not race index creation or document
  ingestion.
  """
  @spec await(module(), {:ok, map()} | {:error, term()}, keyword()) :: :ok | {:error, term()}
  def await(Scrypath.Meilisearch, {:ok, result}, config) when is_map(result) do
    case Map.get(result, :task) do
      task when is_map(task) ->
        case Tasks.wait_for_task(task, config) do
          {:ok, _} -> :ok
          {:error, reason} -> {:error, reason}
        end

      _ ->
        :ok
    end
  end

  def await(_backend, {:ok, _result}, _config), do: :ok

  def await(_backend, {:error, reason}, _config), do: {:error, reason}
end
