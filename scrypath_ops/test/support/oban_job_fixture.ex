# Minimal stand-in for the optional Oban job contract used by Ops recovery tests.
# Defined once in test support so parallel test compilation cannot redefine it.
# A real Oban dependency, when present, supplies its own job module.
unless Code.ensure_loaded?(Oban.Job) do
  defmodule Oban.Job do
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
end
