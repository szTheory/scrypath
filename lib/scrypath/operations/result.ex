defmodule Scrypath.Operations.Result do
  @moduledoc false

  alias Scrypath.Operations.Task

  @enforce_keys [:mode, :status]
  defstruct [:mode, :status, document_ids: [], document_count: 0, task: nil, metadata: %{}]

  @type t :: %__MODULE__{
          mode: :inline | :manual | :oban | atom(),
          status: :accepted | :completed | :noop | atom(),
          document_ids: [term()],
          document_count: non_neg_integer(),
          task: Task.t() | nil,
          metadata: map()
        }

  @spec new(keyword()) :: t()
  def new(attrs) when is_list(attrs) do
    struct!(__MODULE__, attrs)
  end

  @spec to_public_sync(t()) :: map()
  def to_public_sync(%__MODULE__{} = result) do
    base = %{
      mode: result.mode,
      status: result.status,
      document_ids: result.document_ids,
      document_count: result.document_count
    }

    case result.task do
      %Task{} = task -> Map.put(base, :task, Task.to_public_sync(task))
      nil -> base
    end
  end
end
