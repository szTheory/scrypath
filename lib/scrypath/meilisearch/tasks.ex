defmodule Scrypath.Meilisearch.Tasks do
  @moduledoc false

  alias Scrypath.Config
  alias Scrypath.Meilisearch.Client
  alias Scrypath.Meilisearch.TaskPayload
  alias Scrypath.Operations
  alias Scrypath.Operations.Task
  alias Scrypath.Telemetry

  @queued_statuses [:enqueued, :processing]
  @default_task_history_limit 1_000

  @spec list_sync_tasks(String.t(), keyword()) :: {:ok, [Task.t()]} | {:error, term()}
  def list_sync_tasks(index_uid, config) when is_binary(index_uid) do
    list_tasks(index_uid, ["documentAdditionOrUpdate", "documentDeletion"], config)
  end

  @spec list_index_tasks(String.t(), keyword()) :: {:ok, [Task.t()]} | {:error, term()}
  def list_index_tasks(index_uid, config) when is_binary(index_uid) do
    list_tasks(
      index_uid,
      ["indexCreation", "settingsUpdate", "indexSwap", "documentAdditionOrUpdate"],
      config
    )
  end

  defp list_tasks(index_uid, types, config) do
    limit = task_history_limit(config)
    list_task_pages(index_uid, types, config, limit, nil, [])
  end

  defp list_task_pages(index_uid, types, config, remaining, from, acc) do
    filters =
      [index_uids: [index_uid], types: types, limit: remaining]
      |> maybe_put_from(from)

    with {:ok, response} <- client(config).tasks(filters, config),
         {:ok, page} <- normalize_task_page(response) do
      continue_task_pages(index_uid, types, config, response, page, acc)
    end
  end

  defp normalize_task_page(response) do
    response
    |> Map.get(:results, Map.get(response, "results", []))
    |> Enum.reduce_while({:ok, []}, fn payload, {:ok, page} ->
      case TaskPayload.normalize(payload, :poll) do
        {:ok, normalized_task} ->
          task = Operations.task_from_backend(normalized_task, source: :meilisearch)
          {:cont, {:ok, [task | page]}}

        {:error, reason} ->
          {:halt, {:error, reason}}
      end
    end)
    |> then(fn
      {:ok, page} -> {:ok, Enum.reverse(page)}
      {:error, _reason} = error -> error
    end)
  end

  defp continue_task_pages(index_uid, types, config, response, page, acc) do
    next = Map.get(response, :next, Map.get(response, "next"))
    all_tasks = acc ++ page
    observed = length(all_tasks)
    limit = task_history_limit(config)

    cond do
      is_nil(next) ->
        {:ok, all_tasks}

      observed >= limit ->
        {:error,
         {:task_history_truncated,
          %{index_uid: index_uid, limit: limit, observed: observed, next: next}}}

      true ->
        list_task_pages(index_uid, types, config, limit - observed, next, all_tasks)
    end
  end

  defp task_history_limit(config) do
    case Keyword.get(config, :task_history_limit, @default_task_history_limit) do
      limit when is_integer(limit) and limit > 0 -> limit
      _ -> @default_task_history_limit
    end
  end

  defp maybe_put_from(filters, nil), do: filters
  defp maybe_put_from(filters, from), do: Keyword.put(filters, :from, from)

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
    if polls > 0 and timed_out?(started_at, timeout) do
      {{:error, {:timeout, task}}, polls}
    else
      Process.sleep(poll_interval)

      case client(config).task(task.id, config) do
        {:ok, response} ->
          case TaskPayload.normalize(response, :poll) do
            {:ok, normalized_task} ->
              normalized_task
              |> Operations.task_from_backend(source: :meilisearch)
              |> then(
                &do_wait_for_task(&1, config, started_at, poll_interval, timeout, polls + 1)
              )

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
    %{poll_count: polls, error_kind: task_wait_error_kind(reason)}
  end

  defp task_wait_error_kind({:timeout, _}), do: :timeout
  defp task_wait_error_kind({:task_failed, _}), do: :task_failed
  defp task_wait_error_kind({:cancelled, _}), do: :cancelled
  defp task_wait_error_kind({:invalid_task_payload, _}), do: :invalid_task_payload
  defp task_wait_error_kind({:transport_error, _}), do: :transport
  defp task_wait_error_kind(_), do: :other

  defp timed_out?(started_at, timeout) do
    System.monotonic_time(:millisecond) - started_at >= timeout
  end

  defp client(config) do
    Keyword.get(config, :meilisearch_client) || Client
  end

  defp normalize_initial_task(%Task{} = task), do: {:ok, task}

  defp normalize_initial_task(task) when is_map(task) do
    case TaskPayload.normalize(task, :initial) do
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
