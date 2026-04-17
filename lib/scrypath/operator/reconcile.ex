defmodule Scrypath.Operator.Reconcile do
  @moduledoc """
  Report-first reconciliation returned by `Scrypath.reconcile_sync/2`.

  A reconcile report combines sync visibility, failed work, drift signals, and
  rebuild visibility before any recovery action is executed. Per-class failed-work
  pileup counts (`failed_work_counts`) use the same taxonomy as `FailedWork` rows
  for triage at a glance.
  """

  alias Scrypath.Config
  alias Scrypath.Meilisearch.Tasks
  alias Scrypath.Operator.FailedWork
  alias Scrypath.Operator.ReasonClassCounts
  alias Scrypath.Operator.RecoveryAction
  alias Scrypath.Operator.Status

  defmodule ReindexVisibility do
    @moduledoc """
    Reindex visibility embedded in a reconcile report.

    This struct reports the live index, the observed target index, whether
    rebuild task history is visible, the current task state, and cutover
    posture where the backend exposes it.
    """

    @enforce_keys [:live_index, :target_index, :observed?]
    defstruct [:live_index, :target_index, :observed?, :task_state, :cutover, :last_task]

    @type t :: %__MODULE__{
            live_index: String.t(),
            target_index: String.t(),
            observed?: boolean(),
            task_state: :pending | :completed | :failed | :idle,
            cutover: :not_started | :pending | :completed,
            last_task: map() | nil
          }
  end

  @enforce_keys [
    :schema,
    :mode,
    :index,
    :status,
    :failed_work,
    :drift_signals,
    :actions,
    :reindex
  ]
  defstruct [
    :schema,
    :mode,
    :index,
    :status,
    :failed_work,
    :drift_signals,
    :actions,
    :reindex,
    :failed_work_counts
  ]

  @type t :: %__MODULE__{
          schema: module(),
          mode: :inline | :manual | :oban | atom(),
          index: String.t(),
          status: Status.t(),
          failed_work: [FailedWork.t()],
          drift_signals: [atom()],
          actions: [RecoveryAction.t()],
          reindex: ReindexVisibility.t(),
          failed_work_counts: ReasonClassCounts.t()
        }

  @spec run(module(), keyword(), keyword()) :: {:ok, t()} | {:error, term()}
  def run(schema_module, config, operator_opts) do
    backend = Config.fetch_backend!(config)
    index = backend.index_name(schema_module, config)
    target_index = Keyword.get(operator_opts, :target_index) || "#{index}__reindex"

    with {:ok, status} <- Status.fetch(schema_module, config, operator_opts),
         {:ok, failed_work} <- FailedWork.list(schema_module, config, operator_opts),
         {:ok, reindex} <- reindex_visibility(config, operator_opts, index, target_index) do
      actions = recommended_actions(schema_module, config, failed_work, reindex)
      failed_work_counts = FailedWork.reason_class_counts(failed_work)

      {:ok,
       %__MODULE__{
         schema: schema_module,
         mode: Keyword.fetch!(config, :sync_mode),
         index: index,
         status: status,
         failed_work: failed_work,
         drift_signals: drift_signals(status, failed_work, reindex),
         actions: actions,
         reindex: reindex,
         failed_work_counts: failed_work_counts
       }}
    end
  end

  @spec apply_action(RecoveryAction.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def apply_action(%RecoveryAction{} = action, opts) do
    RecoveryAction.retry(action, opts)
  end

  defp reindex_visibility(config, operator_opts, live_index, target_index) do
    case Config.fetch_backend!(config) do
      Scrypath.Meilisearch ->
        case Tasks.list_index_tasks(
               target_index,
               Keyword.merge(config, Keyword.take(operator_opts, [:meilisearch_tasks]))
             ) do
          {:ok, tasks} ->
            {:ok, summarize_reindex(tasks, live_index, target_index)}

          {:error, reason} ->
            {:error, reason}
        end

      _other ->
        {:ok,
         %ReindexVisibility{
           live_index: live_index,
           target_index: target_index,
           observed?: false,
           task_state: :idle,
           cutover: :not_started,
           last_task: nil
         }}
    end
  end

  defp summarize_reindex(tasks, live_index, target_index) do
    last_task =
      tasks
      |> Enum.sort_by(& &1.id, :desc)
      |> List.first()

    %ReindexVisibility{
      live_index: live_index,
      target_index: target_index,
      observed?: tasks != [],
      task_state: reindex_task_state(tasks),
      cutover: reindex_cutover_state(tasks),
      last_task:
        if last_task do
          %{id: last_task.id, state: last_task.state, type: Map.get(last_task.metadata, :type)}
        end
    }
  end

  defp reindex_task_state(tasks) do
    cond do
      Enum.any?(tasks, &(&1.state in [:enqueued, :processing])) -> :pending
      Enum.any?(tasks, &(&1.state == :failed)) -> :failed
      tasks == [] -> :idle
      true -> :completed
    end
  end

  defp reindex_cutover_state(tasks) do
    cond do
      Enum.any?(tasks, &(Map.get(&1.metadata, :type) == "indexSwap" and &1.state == :succeeded)) ->
        :completed

      Enum.any?(tasks, &(Map.get(&1.metadata, :type) == "indexSwap")) ->
        :pending

      true ->
        :not_started
    end
  end

  defp drift_signals(status, failed_work, reindex) do
    []
    |> maybe_add_signal(status.backend.pending != [], :pending_backend_work)
    |> maybe_add_signal(
      status.queue.pending != [] or status.queue.retrying != [],
      :pending_queue_work
    )
    |> maybe_add_signal(failed_work != [], :failed_sync_work)
    |> maybe_add_signal(reindex.observed?, :reindex_visibility_available)
    |> maybe_add_signal(reindex.task_state == :pending, :reindex_in_progress)
    |> maybe_add_signal(reindex.cutover == :pending, :reindex_cutover_pending)
  end

  defp recommended_actions(schema_module, config, failed_work, reindex) do
    retry_actions =
      failed_work
      |> Enum.map(&FailedWork.recovery_action/1)
      |> Enum.reject(&is_nil/1)

    repair_action =
      cond do
        reindex.cutover in [:pending, :completed] or reindex.task_state == :pending ->
          RecoveryAction.new(
            kind: :reindex,
            schema: schema_module,
            backend: Config.fetch_backend!(config),
            mode: Keyword.fetch!(config, :sync_mode),
            operation: :unknown,
            index: reindex.target_index
          )

        failed_work != [] ->
          RecoveryAction.new(
            kind: :backfill,
            schema: schema_module,
            backend: Config.fetch_backend!(config),
            mode: Keyword.fetch!(config, :sync_mode),
            operation: :unknown,
            index: reindex.live_index
          )

        true ->
          nil
      end

    retry_actions ++ List.wrap(repair_action)
  end

  defp maybe_add_signal(signals, true, signal), do: signals ++ [signal]
  defp maybe_add_signal(signals, false, _signal), do: signals
end
