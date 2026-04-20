defmodule Scrypath.Operator.FailedWork do
  @moduledoc """
  Failed sync work returned by `Scrypath.failed_sync_work/2`.

  Each entry reports a stable Scrypath-owned identifier, operation kind,
  retryability, and summarized reason. Recovery details are exposed through an
  explicit `Scrypath.Operator.RecoveryAction` when durable replay is possible.

  ## Enriched fields (additive, v1.3)

  - `attempt` / `max_attempts` — set from the Oban job when `source == :oban`;
    `nil` for Meilisearch task rows and any path without queue attempt metadata.
  - `reason_class` — bounded operator-facing classification: `:transport`,
    `:validation`, `:backend_rejected`, `:queue_exhausted`, or `:unknown`
    (default when signals are missing or ambiguous).
  - `last_attempt_at` — mirrors `failed_at` for every constructor path (soft
    alias for “when this failure was last observed”).

  ## Telemetry

  Each constructed row emits **once**:

      :telemetry.execute(
        [:scrypath, :operator, :failed_work, :observed],
        %{count: 1},
        metadata
      )

  **Required** metadata keys: `:reason_class`, `:schema`, `:mode`.

  **Optional** metadata keys (v1.3): `:operation`, `:retryable?` — same meanings as
  the struct fields.

  Treat **`schema` module atoms and other rich metadata as unsafe for
  low-cardinality metric labels** (for example Prometheus or OTel attribute rules)
  unless you aggregate or sample; they are appropriate for logs, traces, and
  structured handlers that filter explicitly.

  ## Rollups

  `reason_class_counts/1` summarizes a row list into per-class pileup counts. If
  you filter rows for a view, compute counts from that same filtered list;
  `total` then matches the filtered length, not an unfiltered source length.
  """

  alias Scrypath.Config
  alias Scrypath.Meilisearch.Tasks
  alias Scrypath.Oban.Inspect
  alias Scrypath.Operator.ReasonClassCounts
  alias Scrypath.Operator.RecoveryAction

  @rollup_classes [:transport, :validation, :backend_rejected, :queue_exhausted, :unknown]

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
    attempt: nil,
    max_attempts: nil,
    reason_class: nil,
    last_attempt_at: nil,
    recovery: nil,
    metadata: %{}
  ]

  @type operation :: :upsert | :delete | :unknown
  @type state :: :failed | :retrying

  @type reason_class ::
          :transport
          | :validation
          | :backend_rejected
          | :queue_exhausted
          | :unknown

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
          attempt: non_neg_integer() | nil,
          max_attempts: non_neg_integer() | nil,
          reason_class: reason_class() | nil,
          last_attempt_at: DateTime.t() | nil,
          recovery: RecoveryAction.t() | nil,
          metadata: map()
        }

  @spec reason_class_counts([t()]) :: ReasonClassCounts.t()
  def reason_class_counts(rows) when is_list(rows) do
    freqs = Enum.frequencies_by(rows, &normalize_reason_class_for_count/1)

    by_class =
      Map.new(@rollup_classes, fn atom ->
        {atom, Map.get(freqs, atom, 0)}
      end)

    %ReasonClassCounts{
      version: 1,
      total: length(rows),
      by_class: by_class
    }
  end

  defp normalize_reason_class_for_count(%{reason_class: nil}), do: :unknown

  defp normalize_reason_class_for_count(%{reason_class: class})
       when class in [:transport, :validation, :backend_rejected, :queue_exhausted, :unknown],
       do: class

  defp normalize_reason_class_for_count(_), do: :unknown

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
    mode = Keyword.fetch!(config, :sync_mode)
    failed_at = task_timestamp(task.raw)
    norm = normalize_backend_error(task.raw)
    reason_class = classify_backend_normalized(norm)

    row = %__MODULE__{
      id: task.id,
      schema: schema_module,
      mode: mode,
      source: task.source,
      operation: operation,
      state: :failed,
      retryable?: false,
      reason: backend_reason(task.raw),
      failed_at: failed_at,
      attempt: nil,
      max_attempts: nil,
      reason_class: reason_class,
      last_attempt_at: failed_at,
      metadata: %{
        index: Map.get(task.reference, :index_uid),
        task_uid: Map.get(task.reference, :task_uid),
        type: Map.get(task.metadata, :type)
      }
    }

    :telemetry.execute(
      [:scrypath, :operator, :failed_work, :observed],
      %{count: 1},
      %{
        reason_class: reason_class,
        schema: schema_module,
        mode: mode,
        operation: operation,
        retryable?: false
      }
    )

    row
  end

  defp from_queue_job(schema_module, config, job) do
    operation = operation_from_job(job)
    retryable? = operation in [:upsert, :delete] and replay_payload_available?(job)
    failed_at = queue_timestamp(job)
    attempt = job_attempt_field(job, :attempt)
    max_attempts = job_attempt_field(job, :max_attempts)
    reason_class = classify_queue_job(job)

    row = %__MODULE__{
      id: Map.get(job, :id) || Map.get(job, "id"),
      schema: schema_module,
      mode: :oban,
      source: :oban,
      operation: operation,
      state: queue_state(job),
      retryable?: retryable?,
      reason: queue_reason(job),
      failed_at: failed_at,
      attempt: attempt,
      max_attempts: max_attempts,
      reason_class: reason_class,
      last_attempt_at: failed_at,
      recovery: maybe_queue_recovery(schema_module, config, job, operation, retryable?),
      metadata: %{
        worker: Map.get(job, :worker) || Map.get(job, "worker"),
        queue: Map.get(job, :queue) || Map.get(job, "queue")
      }
    }

    :telemetry.execute(
      [:scrypath, :operator, :failed_work, :observed],
      %{count: 1},
      %{
        reason_class: reason_class,
        schema: schema_module,
        mode: :oban,
        operation: operation,
        retryable?: retryable?
      }
    )

    row
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
      state
      when state in ["retryable", :retryable, "discarded", :discarded, "cancelled", :cancelled] ->
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

  defp job_attempt_field(job, key) when key in [:attempt, :max_attempts] do
    str_key = if key == :attempt, do: "attempt", else: "max_attempts"
    to_nonneg_int(Map.get(job, key) || Map.get(job, str_key))
  end

  defp to_nonneg_int(nil), do: nil

  defp to_nonneg_int(n) when is_integer(n) and n >= 0, do: n

  defp to_nonneg_int(s) when is_binary(s) do
    case Integer.parse(s) do
      {n, _} when n >= 0 -> n
      _ -> nil
    end
  end

  defp to_nonneg_int(_), do: nil

  defp normalize_backend_error(raw) when is_map(raw) do
    err = Map.get(raw, "error") || Map.get(raw, :error)
    normalize_meilisearch_error_map(err)
  end

  defp normalize_backend_error(_), do: %{error_type: nil, error_code: nil}

  defp normalize_meilisearch_error_map(%{"type" => t} = m) when is_binary(t) do
    code = Map.get(m, "code") || Map.get(m, :code)
    %{error_type: String.downcase(t), error_code: if(is_binary(code), do: code, else: nil)}
  end

  defp normalize_meilisearch_error_map(%{type: t} = m) when is_atom(t) or is_binary(t) do
    type_str = if is_atom(t), do: Atom.to_string(t), else: t
    code = Map.get(m, :code) || Map.get(m, "code")
    %{error_type: String.downcase(type_str), error_code: if(is_binary(code), do: code, else: nil)}
  end

  defp normalize_meilisearch_error_map(_), do: %{error_type: nil, error_code: nil}

  defp classify_backend_normalized(%{error_type: "invalid_request"}), do: :validation
  defp classify_backend_normalized(%{error_type: "internal"}), do: :backend_rejected
  defp classify_backend_normalized(%{error_type: "auth"}), do: :transport
  defp classify_backend_normalized(%{error_type: nil}), do: :unknown
  defp classify_backend_normalized(%{error_type: _}), do: :unknown

  defp classify_queue_job(job) do
    state = oban_state_atom(job)
    signal = classify_queue_signal_text(queue_error_signal_text(job))

    cond do
      state == :discarded and signal != :unknown ->
        signal

      state == :discarded ->
        :queue_exhausted

      true ->
        signal
    end
  end

  defp oban_state_atom(job) do
    case Map.get(job, :state) || Map.get(job, "state") do
      state when state in [:discarded, "discarded"] -> :discarded
      state when state in [:cancelled, "cancelled"] -> :cancelled
      state when state in [:retryable, "retryable"] -> :retryable
      _other -> :other
    end
  end

  defp queue_error_signal_text(job) do
    case Map.get(job, :errors) || Map.get(job, "errors") do
      list when is_list(list) ->
        list |> List.last() |> error_entry_to_string()

      _other ->
        nil
    end
  end

  defp error_entry_to_string(nil), do: nil
  defp error_entry_to_string(bin) when is_binary(bin), do: bin

  defp error_entry_to_string(%{} = m) do
    error_nested_to_string(Map.get(m, "error") || Map.get(m, :error))
  end

  defp error_entry_to_string(other), do: inspect(other)

  defp error_nested_to_string(s) when is_binary(s), do: s
  defp error_nested_to_string(_), do: nil

  defp classify_queue_signal_text(nil), do: :unknown

  defp classify_queue_signal_text(text) when is_binary(text) do
    classify_queue_signal_lowered(String.downcase(text), text)
  end

  defp classify_queue_signal_lowered(lowered, original_text) do
    cond do
      validation_signal?(lowered) -> :validation
      transport_signal?(lowered, original_text) -> :transport
      backend_rejected_signal?(lowered) -> :backend_rejected
      true -> :unknown
    end
  end

  defp validation_signal?(lowered) do
    String.contains?(lowered, "ecto.casterror") or String.contains?(lowered, "argumenterror")
  end

  defp transport_signal?(lowered, original_text) do
    String.contains?(lowered, "req.transporterror") or
      String.contains?(lowered, "mint.transporterror") or
      String.contains?(lowered, "timeout") or
      Regex.match?(~r/\b(401|403|408|429)\b/, original_text) or
      Regex.match?(~r/\b50[0-9]\b/, original_text)
  end

  defp backend_rejected_signal?(lowered) do
    String.contains?(lowered, "invalid_state") or
      String.contains?(lowered, "database_size_limit") or
      String.contains?(lowered, "no_space_left_on_device")
  end
end
