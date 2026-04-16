defmodule Scrypath.Operations do
  @moduledoc false

  alias Scrypath.Operations.Result
  alias Scrypath.Operations.Task

  @spec task_from_backend(map(), keyword()) :: Task.t()
  def task_from_backend(payload, opts \\ []) when is_map(payload) do
    source = Keyword.get(opts, :source, :meilisearch)

    Task.new(
      source: source,
      kind: :backend_task,
      id: Map.get(payload, :uid) || Map.get(payload, "uid"),
      state: normalize_backend_state(Map.get(payload, :status) || Map.get(payload, "status")),
      reference: %{
        task_uid: Map.get(payload, :uid) || Map.get(payload, "uid"),
        index_uid: Map.get(payload, :index_uid) || Map.get(payload, "indexUid")
      },
      metadata: %{
        type: Map.get(payload, :type) || Map.get(payload, "type")
      },
      raw: Map.get(payload, :raw, payload)
    )
  end

  @spec result_from_enqueue(map(), keyword()) :: Result.t()
  def result_from_enqueue(payload, opts \\ []) when is_map(payload) do
    job = Map.fetch!(payload, :job)

    Result.new(
      mode: Keyword.get(opts, :mode, :oban),
      status: Keyword.get(opts, :status, :accepted),
      document_ids: Map.get(payload, :document_ids, []),
      document_count: Map.get(payload, :document_count, 0),
      task:
        Task.new(
          source: :oban,
          kind: :queue_job,
          id: Map.get(job, :id),
          state: normalize_queue_state(Map.get(job, :state)),
          reference: %{
            job_id: Map.get(job, :id),
            worker: Map.get(job, :worker),
            queue: Map.get(job, :queue)
          },
          metadata: %{
            oban_state: Map.get(job, :state)
          },
          raw: job
        )
    )
  end

  @spec to_public_sync(Result.t()) :: map()
  def to_public_sync(%Result{} = result) do
    Result.to_public_sync(result)
  end

  defp normalize_backend_state(status) when is_binary(status) do
    case status do
      "enqueued" -> :enqueued
      "processing" -> :processing
      "succeeded" -> :succeeded
      "failed" -> :failed
      "canceled" -> :cancelled
      _other -> :unknown
    end
  end

  defp normalize_backend_state(:canceled), do: :cancelled
  defp normalize_backend_state(status) when is_atom(status), do: status
  defp normalize_backend_state(_status), do: :unknown

  defp normalize_queue_state(state) when state in ["available", "scheduled", "executing"],
    do: :queued

  defp normalize_queue_state(state) when state in ["completed"], do: :completed
  defp normalize_queue_state(state) when state in ["discarded", "cancelled"], do: :failed
  defp normalize_queue_state(state) when is_atom(state), do: state
  defp normalize_queue_state(_state), do: :unknown
end
