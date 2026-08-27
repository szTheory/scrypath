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

  alias Scrypath.Operator.FailedWork.Retrieval
  alias Scrypath.Operator.FailedWork.Telemetry
  alias Scrypath.Operator.FailedWork.Translation
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
    with {:ok, %{backend_tasks: backend_tasks, queue_jobs: queue_jobs}} <-
           Retrieval.fetch(schema_module, config, operator_opts) do
      rows =
        backend_tasks
        |> Enum.filter(&(&1.state == :failed))
        |> Enum.map(&build_backend_row(schema_module, config, &1))
        |> Kernel.++(
          queue_jobs
          |> Enum.filter(&Translation.queue_failed?/1)
          |> Enum.map(&build_queue_row(schema_module, config, &1))
        )

      Enum.each(rows, &Telemetry.emit/1)
      {:ok, rows}
    end
  end

  @spec recovery_action(t()) :: RecoveryAction.t() | nil
  def recovery_action(%__MODULE__{recovery: %RecoveryAction{} = recovery}), do: recovery
  def recovery_action(%__MODULE__{}), do: nil

  @spec retry(t(), keyword()) :: {:ok, map()} | {:error, term()}
  def retry(%__MODULE__{retryable?: false}, _opts), do: {:error, :not_retryable}

  def retry(%__MODULE__{recovery: %RecoveryAction{} = recovery}, opts) do
    RecoveryAction.retry(recovery, opts)
  end

  def retry(%__MODULE__{}, _opts), do: {:error, :missing_recovery_action}

  defp build_backend_row(schema_module, config, task) do
    struct!(__MODULE__, Translation.backend_attrs(schema_module, config, task))
  end

  defp build_queue_row(schema_module, config, job) do
    struct!(__MODULE__, Translation.queue_attrs(schema_module, config, job))
  end
end
