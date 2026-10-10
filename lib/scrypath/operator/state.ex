defmodule Scrypath.Operator.State do
  @moduledoc """
  Stable operator state projected from backend tasks and queue jobs.

  This struct gives the public operator APIs a Scrypath-owned shape for
  identifiers, lifecycle state, timestamps, and stable references without
  exposing raw backend or queue payloads as the public contract.
  """

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

  @doc false
  @spec from_backend_task(map() | Task.t()) :: t()
  def from_backend_task(%Task{} = task) do
    {at, source_iso} = task_time_details(task.raw)

    new(
      source: task.source,
      kind: task.kind,
      id: task.id,
      state: normalize_backend_state(task.state),
      reference: task.reference,
      metadata: task.metadata |> Map.take([:type]) |> maybe_put(:source_iso, source_iso),
      at: at
    )
  end

  def from_backend_task(payload) when is_map(payload) do
    payload
    |> Operations.task_from_backend(source: :meilisearch)
    |> from_backend_task()
  end

  @doc false
  @spec from_queue_job(map()) :: t()
  def from_queue_job(job) when is_map(job) do
    {at, source_iso} = queue_time_details(job)

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
      metadata: queue_metadata(job) |> maybe_put(:source_iso, source_iso),
      at: at
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

  defp task_time_details(raw) when is_map(raw) do
    raw
    |> Map.get("finishedAt", Map.get(raw, :finishedAt))
    |> datetime_and_source_iso()
  end

  defp task_time_details(_raw), do: {nil, nil}

  defp queue_time_details(job) do
    job
    |> Map.get(:completed_at, Map.get(job, "completed_at"))
    |> datetime_and_source_iso()
  end

  defp queue_metadata(job) do
    %{}
    |> maybe_put(:worker, Map.get(job, :worker) || Map.get(job, "worker"))
    |> maybe_put(:queue, Map.get(job, :queue) || Map.get(job, "queue"))
    |> maybe_put(:oban_state, Map.get(job, :state) || Map.get(job, "state"))
  end

  defp datetime_and_source_iso(%DateTime{} = value), do: {value, DateTime.to_iso8601(value)}
  defp datetime_and_source_iso(nil), do: {nil, nil}

  defp datetime_and_source_iso(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} -> {datetime, value}
      _other -> {nil, nil}
    end
  end

  defp datetime_and_source_iso(_value), do: {nil, nil}

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
