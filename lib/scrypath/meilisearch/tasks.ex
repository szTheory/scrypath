defmodule Scrypath.Meilisearch.Tasks do
  @moduledoc false

  alias Scrypath.Config
  alias Scrypath.Meilisearch
  alias Scrypath.Meilisearch.Client
  alias Scrypath.Operations
  alias Scrypath.Operations.Task
  alias Scrypath.Telemetry

  @queued_statuses [:enqueued, :processing]

  @spec wait_for_task(map() | Task.t(), keyword()) :: {:ok, Task.t()} | {:error, term()}
  def wait_for_task(task, config) when is_map(task) do
    started_at = System.monotonic_time(:millisecond)
    poll_interval = Config.inline_poll_interval(config)
    timeout = Config.inline_timeout(config)

    case normalize_initial_task(task) do
      {:ok, normalized_task} ->
        Telemetry.span(
          [:scrypath, :meilisearch, :task_wait],
          %{
            task_uid: normalized_task.id,
            initial_status: normalized_task.state,
            poll_interval_ms: poll_interval,
            timeout_ms: timeout
          },
          fn ->
            {result, polls} =
              do_wait_for_task(normalized_task, config, started_at, poll_interval, timeout, 0)

            {result, task_wait_metadata(result, polls)}
          end
        )

      {:error, {:invalid_task_payload, details}} = error ->
        Telemetry.span(
          [:scrypath, :meilisearch, :task_wait],
          %{
            task_uid: details.task_uid,
            initial_status: nil,
            poll_interval_ms: poll_interval,
            timeout_ms: timeout
          },
          fn ->
            {error, task_wait_metadata(error, 0)}
          end
        )
    end
  end

  defp do_wait_for_task(task, _config, _started_at, _poll_interval, _timeout, polls)
       when task.state == :succeeded do
    {{:ok, task}, polls}
  end

  defp do_wait_for_task(task, _config, _started_at, _poll_interval, _timeout, polls)
       when task.state == :failed do
    {{:error, {:task_failed, task}}, polls}
  end

  defp do_wait_for_task(task, _config, _started_at, _poll_interval, _timeout, polls)
       when task.state == :cancelled do
    {{:error, {:cancelled, task}}, polls}
  end

  defp do_wait_for_task(task, config, started_at, poll_interval, timeout, polls)
       when task.state in @queued_statuses do
    if timed_out?(started_at, timeout) do
      {{:error, {:timeout, task}}, polls}
    else
      Process.sleep(poll_interval)

      case client(config).task(task.id, config) do
        {:ok, response} ->
          case Meilisearch.normalize_task(response, :poll) do
            {:ok, normalized_task} ->
              normalized_task
              |> Operations.task_from_backend(source: :meilisearch)
              |> then(&do_wait_for_task(&1, config, started_at, poll_interval, timeout, polls + 1))

            {:error, reason} ->
              {{:error, reason}, polls + 1}
          end

        {:error, reason} ->
          {{:error, reason}, polls + 1}
      end
    end
  end

  defp do_wait_for_task(task, _config, _started_at, _poll_interval, _timeout, polls) do
    {{:error, {:invalid_task_payload, invalid_task_payload(task, :poll)}}, polls}
  end

  defp task_wait_metadata({:ok, task}, polls) do
    %{poll_count: polls, final_status: task.state}
  end

  defp task_wait_metadata({:error, {_reason, task}}, polls) when is_map(task) do
    %{poll_count: polls, final_status: Map.get(task, :state)}
  end

  defp task_wait_metadata({:error, reason}, polls) do
    %{poll_count: polls, error: inspect(reason)}
  end

  defp timed_out?(started_at, timeout) do
    System.monotonic_time(:millisecond) - started_at >= timeout
  end

  defp client(config) do
    Keyword.get(config, :meilisearch_client) || Client
  end

  defp normalize_initial_task(%Task{} = task), do: {:ok, task}

  defp normalize_initial_task(task) when is_map(task) do
    case Meilisearch.normalize_task(task, :initial) do
      {:ok, normalized_task} ->
        {:ok, Operations.task_from_backend(normalized_task, source: :meilisearch)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp invalid_task_payload(task, stage) do
    task_uid = Map.get(task, :id)

    %{
      stage: stage,
      task_uid: if(is_integer(task_uid), do: task_uid, else: nil),
      problems: [status: :unknown],
      payload: Map.get(task, :raw, task)
    }
  end
end
