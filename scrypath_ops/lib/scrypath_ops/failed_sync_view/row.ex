defmodule ScrypathOps.FailedSyncView.Row do
  @moduledoc """
  One failed or retrying sync job as the Failed sync page shows it.

  Built by `ScrypathOps.FailedSyncView.build/4`. The classification is already decided here
  (`cause`, `sync_status`, `action`); the function components only choose words and markup for it.
  `entry` keeps the full `Scrypath.Operator.FailedWork` for the detail disclosure.
  """

  alias Scrypath.Operator.FailedWork

  @typedoc """
  What the row offers the operator. This is eligibility, never authorization: whether the signed-in
  operator may retry is decided by the LiveView's sensitive-action gate when the click arrives.

    * `:retry` - Scrypath exposes a retry action for the job and none was queued yet
    * `:receipt` - a retry for the job was accepted in this session; its receipt is shown instead
    * `:ineligible` - the job cannot be retried here (a Meilisearch task, an unknown operation, or no
      kept record ids)
  """
  @type action :: :retry | :receipt | :ineligible

  @type t :: %__MODULE__{
          entry: FailedWork.t(),
          key: String.t(),
          dom_id: String.t(),
          id: term(),
          schema: module(),
          source: atom(),
          operation: FailedWork.operation(),
          state: FailedWork.state(),
          cause: ScrypathOps.FailedSyncView.cause(),
          sync_status: ScrypathOps.FailedSyncView.sync_status(),
          action: action(),
          receipt: map() | nil,
          reason: String.t() | nil,
          attempts: String.t() | nil,
          last_attempt_at: DateTime.t() | nil,
          next_attempt_at: DateTime.t() | nil,
          record_ids: [term()] | nil,
          recoverable?: boolean()
        }

  @enforce_keys [:entry, :key, :dom_id, :cause, :sync_status, :action]
  defstruct [
    :entry,
    :key,
    :dom_id,
    :id,
    :schema,
    :source,
    :operation,
    :state,
    :cause,
    :sync_status,
    :action,
    :receipt,
    :reason,
    :attempts,
    :last_attempt_at,
    :next_attempt_at,
    :record_ids,
    recoverable?: false
  ]
end
