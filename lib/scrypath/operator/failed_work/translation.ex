defmodule Scrypath.Operator.FailedWork.Translation do
  @moduledoc false

  alias Scrypath.Config
  alias Scrypath.Operator.RecoveryAction

  @spec backend_attrs(module(), keyword(), map()) :: map()
  def backend_attrs(schema_module, config, task) do
    operation = operation_from_task_type(Map.get(task.metadata, :type))
    failed_at = task_timestamp(task.raw)

    %{
      id: task.id,
      schema: schema_module,
      mode: Keyword.fetch!(config, :sync_mode),
      source: task.source,
      operation: operation,
      state: :failed,
      retryable?: false,
      reason: backend_reason(task.raw),
      failed_at: failed_at,
      reason_class: classify_backend_error(task.raw),
      last_attempt_at: failed_at,
      metadata: %{
        index: Map.get(task.reference, :index_uid),
        task_uid: Map.get(task.reference, :task_uid),
        type: Map.get(task.metadata, :type)
      }
    }
  end

  @spec queue_attrs(module(), keyword(), map()) :: map()
  def queue_attrs(schema_module, config, job) do
    operation = operation_from_job(job)
    retryable? = operation in [:upsert, :delete] and replay_payload_available?(job)
    failed_at = queue_timestamp(job)

    %{
      id: value(job, :id),
      schema: schema_module,
      mode: :oban,
      source: :oban,
      operation: operation,
      state: queue_state(job),
      retryable?: retryable?,
      reason: queue_reason(job),
      failed_at: failed_at,
      attempt: job_attempt_field(job, :attempt),
      max_attempts: job_attempt_field(job, :max_attempts),
      reason_class: classify_queue_job(job),
      last_attempt_at: failed_at,
      recovery: maybe_queue_recovery(schema_module, config, job, operation, retryable?),
      metadata: %{worker: value(job, :worker), queue: value(job, :queue)}
    }
  end

  @spec queue_failed?(map()) :: boolean()
  def queue_failed?(job) do
    value(job, :state) in [
      "retryable",
      :retryable,
      "discarded",
      :discarded,
      "cancelled",
      :cancelled
    ]
  end

  defp maybe_queue_recovery(_schema, _config, _job, _operation, false), do: nil

  defp maybe_queue_recovery(schema, config, job, operation, true) do
    RecoveryAction.new(
      schema: schema,
      backend: Config.fetch_backend!(config),
      mode: :oban,
      operation: operation,
      index: arg(job, "index"),
      reference: %{job_id: value(job, :id), queue: value(job, :queue), payload: args(job)}
    )
  end

  defp queue_state(job) do
    if value(job, :state) in ["retryable", :retryable], do: :retrying, else: :failed
  end

  defp operation_from_task_type("documentAdditionOrUpdate"), do: :upsert
  defp operation_from_task_type("documentDeletion"), do: :delete
  defp operation_from_task_type(_), do: :unknown

  defp operation_from_job(job) do
    case arg(job, "operation") do
      "upsert" -> :upsert
      "delete" -> :delete
      _ -> operation_from_worker(value(job, :worker))
    end
  end

  defp operation_from_worker("Scrypath.Oban.UpsertWorker"), do: :upsert
  defp operation_from_worker("Scrypath.Oban.DeleteWorker"), do: :delete
  defp operation_from_worker(_), do: :unknown

  defp replay_payload_available?(job) do
    case arg(job, "operation") do
      "upsert" -> is_list(Map.get(args(job), "documents"))
      "delete" -> is_list(Map.get(args(job), "document_ids"))
      _ -> false
    end
  end

  defp backend_reason(raw) when is_map(raw) do
    case Map.get(raw, "error") do
      %{"message" => message} when is_binary(message) -> message
      %{"code" => code} when is_binary(code) -> code
      _ -> "backend task failed"
    end
  end

  defp backend_reason(_), do: "backend task failed"

  defp queue_reason(job) do
    case value(job, :errors) do
      [first | _] when is_binary(first) ->
        first

      _ ->
        if(value(job, :state) in ["retryable", :retryable],
          do: "queue job is retryable",
          else: "queue job failed"
        )
    end
  end

  defp task_timestamp(raw) when is_map(raw), do: raw |> Map.get("finishedAt") |> parse_datetime()
  defp task_timestamp(_), do: nil
  defp queue_timestamp(job), do: job |> value(:attempted_at) |> parse_datetime()
  defp parse_datetime(%DateTime{} = datetime), do: datetime
  defp parse_datetime(nil), do: nil

  defp parse_datetime(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _} -> datetime
      _ -> nil
    end
  end

  defp parse_datetime(_), do: nil

  defp job_attempt_field(job, key) do
    key = if key == :attempt, do: :attempt, else: :max_attempts
    to_nonneg_int(value(job, key))
  end

  defp to_nonneg_int(n) when is_integer(n) and n >= 0, do: n

  defp to_nonneg_int(s) when is_binary(s) do
    case Integer.parse(s) do
      {n, _} when n >= 0 -> n
      _ -> nil
    end
  end

  defp to_nonneg_int(_), do: nil

  defp classify_backend_error(raw) do
    case raw |> backend_error_type() do
      "invalid_request" -> :validation
      "internal" -> :backend_rejected
      "auth" -> :transport
      _ -> :unknown
    end
  end

  defp backend_error_type(raw) when is_map(raw) do
    case Map.get(raw, "error") || Map.get(raw, :error) do
      %{"type" => type} when is_binary(type) -> String.downcase(type)
      %{type: type} when is_atom(type) -> type |> Atom.to_string() |> String.downcase()
      %{type: type} when is_binary(type) -> String.downcase(type)
      _ -> nil
    end
  end

  defp backend_error_type(_), do: nil

  defp classify_queue_job(job) do
    signal = queue_error_signal_text(job) |> classify_queue_signal_text()

    if value(job, :state) in [:discarded, "discarded"] and signal == :unknown,
      do: :queue_exhausted,
      else: signal
  end

  defp queue_error_signal_text(job) do
    case value(job, :errors) do
      list when is_list(list) -> list |> List.last() |> error_entry_to_string()
      _ -> nil
    end
  end

  defp error_entry_to_string(nil), do: nil
  defp error_entry_to_string(bin) when is_binary(bin), do: bin

  defp error_entry_to_string(%{} = map) do
    case Map.get(map, "error") || Map.get(map, :error) do
      text when is_binary(text) -> text
      _ -> nil
    end
  end

  defp error_entry_to_string(other), do: inspect(other)

  defp classify_queue_signal_text(nil), do: :unknown

  defp classify_queue_signal_text(text) when is_binary(text) do
    lowered = String.downcase(text)

    cond do
      validation_signal?(lowered) ->
        :validation

      transport_signal?(lowered, text) ->
        :transport

      backend_rejection_signal?(lowered) ->
        :backend_rejected

      true ->
        :unknown
    end
  end

  defp validation_signal?(text) do
    String.contains?(text, "ecto.casterror") or String.contains?(text, "argumenterror")
  end

  defp transport_signal?(lowered, original) do
    String.contains?(lowered, "req.transporterror") or
      String.contains?(lowered, "mint.transporterror") or
      String.contains?(lowered, "timeout") or
      Regex.match?(~r/\b(401|403|408|429|50[0-9])\b/, original)
  end

  defp backend_rejection_signal?(text) do
    String.contains?(text, "invalid_state") or
      String.contains?(text, "database_size_limit") or
      String.contains?(text, "no_space_left_on_device")
  end

  defp args(job), do: value(job, :args) || %{}
  defp arg(job, key), do: Map.get(args(job), key)
  defp value(map, key), do: Map.get(map, key) || Map.get(map, Atom.to_string(key))
end
