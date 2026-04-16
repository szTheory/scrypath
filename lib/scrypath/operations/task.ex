defmodule Scrypath.Operations.Task do
  @moduledoc false

  @type source :: :meilisearch | :oban | atom()
  @type kind :: :backend_task | :queue_job | atom()
  @type state :: :enqueued | :processing | :queued | :completed | :failed | atom()

  @enforce_keys [:source, :kind, :id, :state]
  defstruct [:source, :kind, :id, :state, reference: %{}, metadata: %{}, raw: nil]

  @type t :: %__MODULE__{
          source: source(),
          kind: kind(),
          id: term(),
          state: state(),
          reference: map(),
          metadata: map(),
          raw: term()
        }

  @spec new(keyword()) :: t()
  def new(attrs) when is_list(attrs) do
    struct!(__MODULE__, attrs)
  end

  @spec to_public_sync(t()) :: map()
  def to_public_sync(%__MODULE__{id: id, state: state}) do
    %{uid: id, status: state}
  end
end
