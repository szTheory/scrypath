# The retry path builds an Oban job changeset, and the Oban package is optional for the ops app,
# so the struct is stubbed here for the whole test environment.
defmodule Oban.Job do
  @moduledoc false
  defstruct [:id, :worker, :queue, :state, :attempt, :max_attempts, :args]

  def new(args, opts) do
    %Ecto.Changeset{
      data: %__MODULE__{
        args: args,
        worker: Keyword.fetch!(opts, :worker),
        queue: Keyword.fetch!(opts, :queue),
        max_attempts: Keyword.fetch!(opts, :max_attempts),
        state: "available",
        attempt: 0
      },
      changes: %{},
      errors: [],
      valid?: true,
      action: nil,
      types: %{},
      params: nil
    }
  end
end
