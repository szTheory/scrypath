defmodule ScrypathFixtures.Meili do
  @moduledoc """
  Builds raw Meilisearch task maps, as `GET /tasks` returns them. The data is fictional and for
  development and tests only.

  The output is the 12-key string-keyed map Meilisearch v1.15 sends. It is never a
  `Scrypath.Operations.Task` or an operator state: the real Scrypath code normalizes it.

  Task `type` and `status` are closed lists. A foreign value raises `FunctionClauseError` at the
  function head instead of producing a state the library cannot read. Meilisearch spells the
  cancelled status `"canceled"` (one l); Oban spells it `"cancelled"`.
  """

  # The five types Scrypath reads (lib/scrypath/meilisearch/tasks.ex).
  @types ~w(documentAdditionOrUpdate documentDeletion indexCreation settingsUpdate indexSwap)
  @statuses ~w(enqueued processing succeeded failed canceled)
  @keys ~w(uid batchUid indexUid status type canceledBy details error duration enqueuedAt startedAt finishedAt)

  @doc "The 12 keys every task map carries."
  @spec keys() :: [String.t()]
  def keys, do: @keys

  @doc "The closed list of task types."
  @spec types() :: [String.t()]
  def types, do: @types

  @doc "The closed list of task statuses."
  @spec statuses() :: [String.t()]
  def statuses, do: @statuses

  @doc """
  Builds one task map.

  Required: `:type`, `:status`, `:uid`, `:index_uid`, `:now`, `:enqueued_ago` (seconds before
  `now`). Optional: `:details`, `:error`, `:canceled_by`, `:batch_uid`.

  `index_uid` is `nil` exactly when the type is `"indexSwap"`: Meilisearch reports swaps with a
  null index and leaves them out of every `indexUids`-filtered list.
  """
  @spec task(map()) :: map()
  def task(%{type: type, status: status, index_uid: index_uid} = attrs)
      when type in @types and status in @statuses and
             ((type == "indexSwap" and is_nil(index_uid)) or
                (type != "indexSwap" and is_binary(index_uid))) do
    now = Map.fetch!(attrs, :now)
    enqueued = Map.fetch!(attrs, :enqueued_ago)
    uid = Map.fetch!(attrs, :uid)
    started? = status != "enqueued"
    finished? = status in ["succeeded", "failed", "canceled"]

    %{
      "uid" => uid,
      "batchUid" => if(started?, do: Map.get(attrs, :batch_uid, uid)),
      "indexUid" => index_uid,
      "status" => status,
      "type" => type,
      "canceledBy" => Map.get(attrs, :canceled_by),
      "details" => Map.get(attrs, :details, %{}),
      "error" => Map.get(attrs, :error),
      "duration" => if(finished?, do: "PT0.1S"),
      "enqueuedAt" => stamp(now, enqueued),
      "startedAt" => if(started?, do: stamp(now, enqueued - 1)),
      "finishedAt" => if(finished?, do: stamp(now, enqueued - 2))
    }
  end

  @doc """
  Renders `now` minus `seconds_ago` the way Meilisearch does: nine fractional digits and a `Z`.

  `DateTime.from_iso8601/1` accepts this form, which is what `Scrypath` uses to read it.
  """
  @spec stamp(DateTime.t(), integer()) :: String.t()
  def stamp(%DateTime{} = now, seconds_ago) when is_integer(seconds_ago) do
    now
    |> DateTime.add(-seconds_ago, :second)
    |> Calendar.strftime("%Y-%m-%dT%H:%M:%S")
    |> Kernel.<>(".123456789Z")
  end
end
