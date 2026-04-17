defmodule Scrypath.Operator.Status do
  @moduledoc """
  Read-only sync visibility returned by `Scrypath.sync_status/2`.

  Status keeps backend-side and queue-side observations distinct so queued or
  retryable work never reads like completed backend visibility.
  """

  alias Scrypath.Config
  alias Scrypath.Meilisearch.Tasks
  alias Scrypath.Oban.Inspect
  alias Scrypath.Operator.State

  @enforce_keys [:schema, :mode, :index]
  defstruct [
    :schema,
    :mode,
    :index,
    backend: %{pending: [], failed: [], last_succeeded: nil},
    queue: %{observed?: false, pending: [], retrying: [], failed: [], last_succeeded: nil}
  ]

  @type section :: %{
          optional(:observed?) => boolean(),
          pending: [State.t()],
          retrying: [State.t()],
          failed: [State.t()],
          last_succeeded: State.t() | nil
        }

  @type backend_section :: %{
          pending: [State.t()],
          failed: [State.t()],
          last_succeeded: State.t() | nil
        }

  @type t :: %__MODULE__{
          schema: module(),
          mode: :inline | :manual | :oban | atom(),
          index: String.t(),
          backend: backend_section(),
          queue: section()
        }

  @spec new(keyword()) :: t()
  def new(attrs) when is_list(attrs) do
    struct!(__MODULE__, attrs)
  end

  @spec fetch(module(), keyword(), keyword()) :: {:ok, t()} | {:error, term()}
  def fetch(schema_module, config, operator_opts) do
    backend = Config.fetch_backend!(config)
    index = backend.index_name(schema_module, config)

    with {:ok, backend_states} <- backend_states(config, operator_opts, index),
         {:ok, queue_states} <- queue_states(schema_module, config, operator_opts) do
      {:ok,
       new(
         schema: schema_module,
         mode: Keyword.fetch!(config, :sync_mode),
         index: index,
         backend: summarize_backend(backend_states),
         queue: summarize_queue(queue_states, Keyword.fetch!(config, :sync_mode))
       )}
    end
  end

  defp backend_states(config, operator_opts, index) do
    case Config.fetch_backend!(config) do
      Scrypath.Meilisearch ->
        config
        |> Keyword.merge(Keyword.take(operator_opts, [:meilisearch_tasks]))
        |> then(&Tasks.list_sync_tasks(index, &1))
        |> case do
          {:ok, tasks} -> {:ok, Enum.map(tasks, &State.from_backend_task/1)}
          {:error, reason} -> {:error, reason}
        end

      backend ->
        {:error, {:unsupported_operator_backend, backend}}
    end
  end

  defp queue_states(schema_module, config, operator_opts) do
    case Keyword.fetch!(config, :sync_mode) do
      :oban ->
        config
        |> Keyword.merge(Keyword.take(operator_opts, [:oban_jobs, :oban_inspector]))
        |> then(&Inspect.list_jobs(schema_module, &1))
        |> case do
          {:ok, jobs} -> {:ok, Enum.map(jobs, &State.from_queue_job/1)}
          {:error, reason} -> {:error, reason}
        end

      _other ->
        {:ok, []}
    end
  end

  defp summarize_backend(states) do
    %{
      pending: Enum.filter(states, &(&1.state == :pending)),
      failed: Enum.filter(states, &(&1.state == :failed)),
      last_succeeded: last_completed(states)
    }
  end

  defp summarize_queue(states, :oban) do
    %{
      observed?: states != [],
      pending: Enum.filter(states, &(&1.state == :queued)),
      retrying: Enum.filter(states, &(&1.state == :retrying)),
      failed: Enum.filter(states, &(&1.state == :failed)),
      last_succeeded: last_completed(states)
    }
  end

  defp summarize_queue(_states, _mode) do
    %{observed?: false, pending: [], retrying: [], failed: [], last_succeeded: nil}
  end

  defp last_completed(states) do
    states
    |> Enum.filter(&(&1.state == :completed))
    |> Enum.sort_by(&completion_sort_key/1, {:desc, DateTime})
    |> List.first()
  end

  defp completion_sort_key(%State{at: %DateTime{} = at}), do: at
  defp completion_sort_key(%State{}), do: ~U[0001-01-01 00:00:00Z]
end
