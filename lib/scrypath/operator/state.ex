defmodule Scrypath.Operator.State do
  @moduledoc false

  alias Scrypath.Operations
  alias Scrypath.Operations.Task

  @type state :: :pending | :queued | :retrying | :failed | :completed

  @enforce_keys [:source, :kind, :id, :state]
  defstruct [:source, :kind, :id, :state, reference: %{}, metadata: %{}, at: nil]

  @type t :: %__MODULE__{
          source: :meilisearch | :oban | atom(),
          kind: :backend_task | :queue_job | atom(),
          id: term(),
          state: state(),
          reference: map(),
          metadata: map(),
          at: DateTime.t() | nil
        }

  @spec new(keyword()) :: t()
  def new(attrs) when is_list(attrs) do
    struct!(__MODULE__, attrs)
  end

  @spec from_backend_task(map() | Task.t()) :: t()
  def from_backend_task(%Task{} = task) do
    new(
      source: task.source,
      kind: task.kind,
      id: task.id,
      state: normalize_backend_state(task.state),
      reference: task.reference,
      metadata: Map.take(task.metadata, [:type]),
      at: task_time(task.raw)
    )
  end

  def from_backend_task(payload) when is_map(payload) do
    payload
    |> Operations.task_from_backend(source: :meilisearch)
    |> from_backend_task()
  end

  @spec from_queue_job(map()) :: t()
  def from_queue_job(job) when is_map(job) do
    new(
      source: :oban,
      kind: :queue_job,
      id: Map.get(job, :id) || Map.get(job, "id"),
      state: normalize_queue_state(Map.get(job, :state) || Map.get(job, "state")),
      reference: %{
        job_id: Map.get(job, :id) || Map.get(job, "id"),
        worker: Map.get(job, :worker) || Map.get(job, "worker"),
        queue: Map.get(job, :queue) || Map.get(job, "queue")
      },
      metadata: queue_metadata(job),
      at: queue_time(job)
    )
  end

  defp normalize_backend_state(state) when state in [:enqueued, :processing], do: :pending
  defp normalize_backend_state(:succeeded), do: :completed
  defp normalize_backend_state(:failed), do: :failed
  defp normalize_backend_state(:cancelled), do: :failed
  defp normalize_backend_state(:canceled), do: :failed
  defp normalize_backend_state(:completed), do: :completed
  defp normalize_backend_state(_state), do: :pending

  defp normalize_queue_state(state) when state in ["available", "scheduled", "executing"],
    do: :queued

  defp normalize_queue_state(state) when state in ["retryable", :retryable], do: :retrying

  defp normalize_queue_state(state)
       when state in ["discarded", "cancelled", :discarded, :cancelled], do: :failed

  defp normalize_queue_state(state) when state in ["completed", :completed], do: :completed
  defp normalize_queue_state(:queued), do: :queued
  defp normalize_queue_state(:retrying), do: :retrying
  defp normalize_queue_state(:failed), do: :failed
  defp normalize_queue_state(_state), do: :queued

  defp task_time(raw) when is_map(raw) do
    raw
    |> Map.get("finishedAt")
    |> parse_datetime()
  end

  defp task_time(_raw), do: nil

  defp queue_time(job) do
    job
    |> Map.get(:completed_at, Map.get(job, "completed_at"))
    |> parse_datetime()
  end

  defp queue_metadata(job) do
    %{}
    |> maybe_put(:worker, Map.get(job, :worker) || Map.get(job, "worker"))
    |> maybe_put(:queue, Map.get(job, :queue) || Map.get(job, "queue"))
    |> maybe_put(:oban_state, Map.get(job, :state) || Map.get(job, "state"))
  end

  defp parse_datetime(%DateTime{} = value), do: value
  defp parse_datetime(nil), do: nil

  defp parse_datetime(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} -> datetime
      _other -> nil
    end
  end

  defp parse_datetime(_value), do: nil

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
