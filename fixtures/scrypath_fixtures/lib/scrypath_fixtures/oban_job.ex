defmodule ScrypathFixtures.ObanJob do
  @moduledoc """
  Builds raw Oban job maps in the shape the repository's one real inspector returns. The data is
  fictional and for development and tests only.

  The output has 11 atom keys. `state`, `worker` and `queue` are strings, `args` and `errors` are
  string-keyed (they are JSON in Oban), and the three stamps are `DateTime` values or `nil`. It is
  never a `Scrypath.Operator.FailedWork`: the real code normalizes it.

  Worker names are strings. The worker modules exist only when Oban loads and Oban is not in the
  `scrypath_ops` graph, so this module never references them. Oban spells the cancelled state
  `"cancelled"` (two l); Meilisearch spells its status `"canceled"`.
  """

  alias ScrypathFixtures.Failures

  @states ~w(available scheduled executing retryable completed discarded cancelled)
  @workers %{
    upsert: "Scrypath.Oban.UpsertWorker",
    delete: "Scrypath.Oban.DeleteWorker",
    related: "Scrypath.Sync.RelatedWorker"
  }

  @doc "The closed list of Oban job states."
  @spec states() :: [String.t()]
  def states, do: @states

  @doc "The closed map of worker names, keyed by role."
  @spec workers() :: %{atom() => String.t()}
  def workers, do: @workers

  @doc """
  Builds one job map.

  Required: `:id`, `:state`, `:worker` (`:upsert`, `:delete` or `:related`), `:queue`, `:args`,
  `:now`, `:ago` (seconds before `now`), `:max_attempts`. Optional: `:attempt` (default 0),
  `:errors` (default `[]`), `:scheduled_in` (seconds after `now`; default is `ago` before it).

  `:errors` is a list of `{entry_id, attempt, bindings}` tuples. Each is rendered from that entry
  of `ScrypathFixtures.Failures.oban_error/2`; `bindings` are its other options (`:worker` here
  defaults to the job's own worker, and `:at` to the time of the last attempt). A raw error map is
  rejected, so no failure text can be typed into a builder call.

  There is no default for `:queue` or `:max_attempts`: Scrypath has no default queue and takes
  `max_attempts` from its config, so the caller states both.
  """
  @spec job(map()) :: map()
  def job(%{state: state, worker: worker} = attrs)
      when state in @states and is_map_key(@workers, worker) do
    now = Map.fetch!(attrs, :now)
    ago = Map.fetch!(attrs, :ago)
    attempt = Map.get(attrs, :attempt, 0)
    attempted_at = if attempt > 0, do: DateTime.add(now, -ago, :second)

    %{
      id: Map.fetch!(attrs, :id),
      state: state,
      worker: Map.fetch!(@workers, worker),
      queue: Map.fetch!(attrs, :queue),
      args: Map.fetch!(attrs, :args),
      errors: attrs |> Map.get(:errors, []) |> Enum.map(&error_entry(&1, attrs, attempted_at)),
      attempt: attempt,
      max_attempts: Map.fetch!(attrs, :max_attempts),
      attempted_at: attempted_at,
      scheduled_at: DateTime.add(now, Map.get(attrs, :scheduled_in, -ago), :second),
      completed_at: if(state == "completed", do: DateTime.add(now, -ago + 2, :second))
    }
  end

  defp error_entry({entry_id, attempt, bindings}, %{worker: worker}, attempted_at)
       when is_atom(entry_id) and is_integer(attempt) and is_list(bindings) do
    Failures.oban_error(
      entry_id,
      Keyword.merge([attempt: attempt, at: attempted_at, worker: worker], bindings)
    )
  end
end
