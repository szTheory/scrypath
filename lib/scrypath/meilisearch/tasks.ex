defmodule Scrypath.Meilisearch.Tasks do
  @moduledoc false

  alias Scrypath.Config
  alias Scrypath.Meilisearch.Client

  @queued_statuses ~w(enqueued processing queued)a

  @spec wait_for_task(map(), keyword()) :: {:ok, map()} | {:error, term()}
  def wait_for_task(task, config) when is_map(task) do
    started_at = System.monotonic_time(:millisecond)
    poll_interval = Config.inline_poll_interval(config)
    timeout = Config.inline_timeout(config)

    task
    |> normalize_task()
    |> do_wait_for_task(config, started_at, poll_interval, timeout)
  end

  defp do_wait_for_task(task, _config, _started_at, _poll_interval, _timeout)
       when task.status == :succeeded do
    {:ok, task}
  end

  defp do_wait_for_task(task, _config, _started_at, _poll_interval, _timeout)
       when task.status == :failed do
    {:error, {:task_failed, task}}
  end

  defp do_wait_for_task(task, _config, _started_at, _poll_interval, _timeout)
       when task.status == :cancelled do
    {:error, {:cancelled, task}}
  end

  defp do_wait_for_task(task, config, started_at, poll_interval, timeout)
       when task.status in @queued_statuses do
    if timed_out?(started_at, timeout) do
      {:error, {:timeout, task}}
    else
      Process.sleep(poll_interval)

      case client(config).task(task.uid, config) do
        {:ok, response} ->
          response
          |> normalize_task()
          |> do_wait_for_task(config, started_at, poll_interval, timeout)

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  defp do_wait_for_task(task, _config, _started_at, _poll_interval, _timeout) do
    {:ok, task}
  end

  defp timed_out?(started_at, timeout) do
    System.monotonic_time(:millisecond) - started_at >= timeout
  end

  defp client(config) do
    Keyword.get(config, :meilisearch_client) || Client
  end

  defp normalize_task(task) do
    status =
      task
      |> Map.get("status", Map.get(task, :status))
      |> normalize_status()

    %{
      uid:
        Map.get(task, "taskUid") || Map.get(task, :taskUid) || Map.get(task, "uid") ||
          Map.get(task, :uid),
      status: status,
      type: Map.get(task, "type") || Map.get(task, :type),
      index_uid: Map.get(task, "indexUid") || Map.get(task, :indexUid),
      raw: task
    }
  end

  defp normalize_status(status) when is_atom(status), do: status
  defp normalize_status("succeeded"), do: :succeeded
  defp normalize_status("failed"), do: :failed
  defp normalize_status("canceled"), do: :cancelled
  defp normalize_status("cancelled"), do: :cancelled
  defp normalize_status("enqueued"), do: :enqueued
  defp normalize_status("processing"), do: :processing
  defp normalize_status("queued"), do: :queued
  defp normalize_status(status), do: status
end
