defmodule Scrypath.Meilisearch.TaskPayload do
  @moduledoc false

  @spec normalize(term(), :initial | :poll) :: {:ok, map()} | {:error, term()}
  def normalize(response, stage \\ :initial)

  def normalize(response, stage) when is_map(response) and stage in [:initial, :poll] do
    task_uid = extract_task_uid(response)
    {status, status_problem} = normalize_status(response["status"] || response[:status])

    problems =
      []
      |> maybe_problem(:uid, uid_problem(task_uid))
      |> maybe_problem(:status, status_problem)

    if problems == [] do
      {:ok,
       %{
         uid: task_uid,
         status: status,
         type: response["type"] || response[:type],
         index_uid: response["indexUid"] || response[:indexUid],
         raw: response
       }}
    else
      {:error, {:invalid_task_payload, invalid_payload(stage, task_uid, problems, response)}}
    end
  end

  def normalize(response, stage) when stage in [:initial, :poll] do
    {:error,
     {:invalid_task_payload, invalid_payload(stage, nil, [payload: :not_a_map], %{raw: response})}}
  end

  defp extract_task_uid(response) do
    case response["taskUid"] || response[:taskUid] || response["uid"] || response[:uid] do
      task_uid when is_integer(task_uid) -> task_uid
      _other -> nil
    end
  end

  defp uid_problem(nil), do: :missing_or_invalid
  defp uid_problem(_task_uid), do: nil

  defp normalize_status(status) when is_atom(status), do: normalize_status(Atom.to_string(status))
  defp normalize_status("enqueued"), do: {:enqueued, nil}
  defp normalize_status("processing"), do: {:processing, nil}
  defp normalize_status("queued"), do: {:enqueued, nil}
  defp normalize_status("succeeded"), do: {:succeeded, nil}
  defp normalize_status("failed"), do: {:failed, nil}
  defp normalize_status("canceled"), do: {:cancelled, nil}
  defp normalize_status("cancelled"), do: {:cancelled, nil}
  defp normalize_status(nil), do: {nil, :missing}
  defp normalize_status(_status), do: {nil, :unknown}

  defp invalid_payload(stage, task_uid, problems, payload) do
    %{stage: stage, task_uid: task_uid, problems: problems, payload: payload}
  end

  defp maybe_problem(problems, _key, nil), do: problems
  defp maybe_problem(problems, key, value), do: Keyword.put(problems, key, value)
end
