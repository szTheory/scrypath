defmodule Scrypath.Operator.FailedWork do
  @moduledoc """
  Failed sync work returned by `Scrypath.failed_sync_work/2`.

  Each entry reports a stable Scrypath-owned identifier, operation kind,
  retryability, and summarized reason. Recovery details are exposed through an
  explicit `Scrypath.Operator.RecoveryAction` when durable replay is possible.
  """

  alias Scrypath.Config
  alias Scrypath.Meilisearch.Tasks
  alias Scrypath.Oban.Inspect
  alias Scrypath.Operator.RecoveryAction

  @enforce_keys [:id, :schema, :mode, :source, :operation, :state, :retryable?]
  defstruct [
    :id,
    :schema,
    :mode,
    :source,
    :operation,
    :state,
    :retryable?,
    :reason,
    :failed_at,
    recovery: nil,
    metadata: %{}
  ]

  @type operation :: :upsert | :delete | :unknown
  @type state :: :failed | :retrying

  @type t :: %__MODULE__{
          id: term(),
          schema: module(),
          mode: :inline | :manual | :oban | atom(),
          source: :meilisearch | :oban | atom(),
          operation: operation(),
          state: state(),
          retryable?: boolean(),
          reason: String.t() | nil,
          failed_at: DateTime.t() | nil,
          recovery: RecoveryAction.t() | nil,
          metadata: map()
        }

  @spec list(module(), keyword(), keyword()) :: {:ok, [t()]} | {:error, term()}
  def list(schema_module, config, operator_opts) do
    backend = Config.fetch_backend!(config)
    index = backend.index_name(schema_module, config)

    with {:ok, backend_failures} <- backend_failures(schema_module, config, operator_opts, index),
         {:ok, queue_failures} <- queue_failures(schema_module, config, operator_opts) do
      {:ok, backend_failures ++ queue_failures}
    end
  end

  @spec recovery_action(t()) :: RecoveryAction.t() | nil
  def recovery_action(%__MODULE__{recovery: %RecoveryAction{} = recovery}), do: recovery
  def recovery_action(%__MODULE__{}), do: nil

  defp backend_failures(schema_module, config, operator_opts, index) do
    case Config.fetch_backend!(config) do
      Scrypath.Meilisearch ->
        config
        |> Keyword.merge(Keyword.take(operator_opts, [:meilisearch_tasks]))
        |> then(&Tasks.list_sync_tasks(index, &1))
        |> case do
          {:ok, tasks} ->
            tasks
            |> Enum.filter(&(&1.state == :failed))
            |> Enum.map(&from_backend_task(schema_module, config, &1))
            |> then(&{:ok, &1})

          {:error, reason} ->
            {:error, reason}
        end

      backend ->
        {:error, {:unsupported_operator_backend, backend}}
    end
  end

  defp queue_failures(schema_module, config, operator_opts) do
    case Keyword.fetch!(config, :sync_mode) do
      :oban ->
        config
        |> Keyword.merge(Keyword.take(operator_opts, [:oban_jobs, :oban_inspector]))
        |> then(&Inspect.list_jobs(schema_module, &1))
        |> case do
          {:ok, jobs} ->
            jobs
            |> Enum.filter(&queue_failed?/1)
            |> Enum.map(&from_queue_job(schema_module, config, &1))
            |> then(&{:ok, &1})

          {:error, reason} ->
            {:error, reason}
        end

      _other ->
        {:ok, []}
    end
  end

  defp from_backend_task(schema_module, config, task) do
    operation = operation_from_task_type(Map.get(task.metadata, :type))

    %__MODULE__{
      id: task.id,
      schema: schema_module,
      mode: Keyword.fetch!(config, :sync_mode),
      source: task.source,
      operation: operation,
      state: :failed,
      retryable?: false,
      reason: backend_reason(task.raw),
      failed_at: task_timestamp(task.raw),
      metadata: %{
        index: Map.get(task.reference, :index_uid),
        task_uid: Map.get(task.reference, :task_uid),
        type: Map.get(task.metadata, :type)
      }
    }
  end

  defp from_queue_job(schema_module, config, job) do
    operation = operation_from_job(job)
    retryable? = operation in [:upsert, :delete] and replay_payload_available?(job)

    %__MODULE__{
      id: Map.get(job, :id) || Map.get(job, "id"),
      schema: schema_module,
      mode: :oban,
      source: :oban,
      operation: operation,
      state: queue_state(job),
      retryable?: retryable?,
      reason: queue_reason(job),
      failed_at: queue_timestamp(job),
      recovery: maybe_queue_recovery(schema_module, config, job, operation, retryable?),
      metadata: %{
        worker: Map.get(job, :worker) || Map.get(job, "worker"),
        queue: Map.get(job, :queue) || Map.get(job, "queue")
      }
    }
  end

  defp maybe_queue_recovery(_schema_module, _config, _job, _operation, false), do: nil

  defp maybe_queue_recovery(schema_module, config, job, operation, true) do
    RecoveryAction.new(
      schema: schema_module,
      backend: Config.fetch_backend!(config),
      mode: :oban,
      operation: operation,
      index: extract_arg(job, "index"),
      reference: %{
        job_id: Map.get(job, :id) || Map.get(job, "id"),
        queue: Map.get(job, :queue) || Map.get(job, "queue"),
        payload: extract_args(job)
      }
    )
  end

  defp queue_failed?(job) do
    case Map.get(job, :state) || Map.get(job, "state") do
      state when state in ["retryable", :retryable, "discarded", :discarded, "cancelled", :cancelled] ->
        true

      _other ->
        false
    end
  end

  defp queue_state(job) do
    case Map.get(job, :state) || Map.get(job, "state") do
      state when state in ["retryable", :retryable] -> :retrying
      _other -> :failed
    end
  end

  defp operation_from_task_type("documentAdditionOrUpdate"), do: :upsert
  defp operation_from_task_type("documentDeletion"), do: :delete
  defp operation_from_task_type(_other), do: :unknown

  defp operation_from_job(job) do
    case extract_arg(job, "operation") do
      "upsert" -> :upsert
      "delete" -> :delete
      _other -> operation_from_worker(Map.get(job, :worker) || Map.get(job, "worker"))
    end
  end

  defp operation_from_worker("Scrypath.Oban.UpsertWorker"), do: :upsert
  defp operation_from_worker("Scrypath.Oban.DeleteWorker"), do: :delete
  defp operation_from_worker(_worker), do: :unknown

  defp replay_payload_available?(job) do
    args = extract_args(job)

    case extract_arg(job, "operation") do
      "upsert" -> is_list(Map.get(args, "documents"))
      "delete" -> is_list(Map.get(args, "document_ids"))
      _other -> false
    end
  end

  defp extract_args(job) do
    Map.get(job, :args) || Map.get(job, "args") || %{}
  end

  defp extract_arg(job, key) do
    job
    |> extract_args()
    |> Map.get(key)
  end

  defp backend_reason(raw) when is_map(raw) do
    case Map.get(raw, "error") do
      %{"message" => message} when is_binary(message) -> message
      %{"code" => code} when is_binary(code) -> code
      _other -> "backend task failed"
    end
  end

  defp backend_reason(_raw), do: "backend task failed"

  defp queue_reason(job) do
    case Map.get(job, :errors) || Map.get(job, "errors") do
      [first | _rest] when is_binary(first) ->
        first

      _other ->
        case Map.get(job, :state) || Map.get(job, "state") do
          state when state in ["retryable", :retryable] -> "queue job is retryable"
          _state -> "queue job failed"
        end
    end
  end

  defp task_timestamp(raw) when is_map(raw) do
    raw
    |> Map.get("finishedAt")
    |> parse_datetime()
  end

  defp task_timestamp(_raw), do: nil

  defp queue_timestamp(job) do
    job
    |> Map.get(:attempted_at, Map.get(job, "attempted_at"))
    |> parse_datetime()
  end

  defp parse_datetime(%DateTime{} = datetime), do: datetime
  defp parse_datetime(nil), do: nil

  defp parse_datetime(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} -> datetime
      _other -> nil
    end
  end

  defp parse_datetime(_value), do: nil
end
