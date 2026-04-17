defmodule Scrypath.Operator.FailedSyncWorkInspection do
  @moduledoc """
  Opt-in enriched result from `Scrypath.failed_sync_work/2` when
  `reason_class_counts: true` is passed in operator options.

  `entries` is the same row list used to compute `counts`, so triage views stay
  consistent with the rollup totals.
  """

  alias Scrypath.Operator.FailedWork
  alias Scrypath.Operator.ReasonClassCounts

  @enforce_keys [:entries, :counts]
  defstruct [:entries, :counts]

  @type t :: %__MODULE__{
          entries: [FailedWork.t()],
          counts: ReasonClassCounts.t()
        }
end
